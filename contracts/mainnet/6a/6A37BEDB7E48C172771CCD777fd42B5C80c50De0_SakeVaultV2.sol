// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/vela-exchange/ISettingManager.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/ITokenBurnable.sol";
import "./interfaces/water/IWater.sol";
import {IVault} from "./interfaces/vela-exchange/IVault.sol";
import {ITokenFarm} from "./interfaces/vela-exchange/ITokenFarm.sol";

interface IHandler {
    function getPositionWithInterestRate(
        address _user,
        uint256 _positionID,
        address _AirPuffVault,
        address _lendingVault,
        uint256 _openTimestamp,
        uint256 _leverageAmount,
        uint256 _snapShotID) external view returns (uint256,uint256);
    function vaultCurrentSnapshotID(address _lendingVault) external view returns (uint256);
}

contract SakeVaultV2 is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, ERC20BurnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;
    using MathUpgradeable for uint128;

    struct UserInfo {
        address user; // user that created the position
        uint256 deposit; // total amount of deposit
        uint256 leverage; // leverage used
        uint256 position; // position size
        uint256 price; // VLP price
        bool liquidated; // true if position was liquidated
        uint256 cooldownPeriodElapse; // epoch when user can withdraw
        uint256 closedPositionValue; // value of position when closed
        address liquidator; //address of the liquidator
        uint256 leverageAmount;
        uint256 positionId;
        bool closed;
    }

    struct FeeConfiguration {
        address feeReceiver;
        uint256 withdrawalFee;
        address waterFeeReceiver;
        uint256 liquidatorsRewardPercentage;
        uint256 DTVLimit;
    }

    struct SwapDescriptionV2 {
        IERC20Upgradeable srcToken;
        IERC20Upgradeable dstToken;
        address[] srcReceivers; // transfer src token to these addresses, default
        uint256[] srcAmounts;
        address[] feeReceivers;
        uint256[] feeAmounts;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    struct SwapExecutionParams {
        address callTarget; // call this address
        address approveTarget; // approve this address if _APPROVE_FUND set
        bytes targetData;
        SwapDescriptionV2 generic;
        bytes clientData;
    }

    struct Datas {
        uint256 withdrawableShares;
        bool inFull;
        bool success;
    }

    struct StrategyAddresses {
        address USDC;
        address water;
        address velaMintBurnVault;
        address velaStakingVault;
        address vlpToken;
        address esVela;
        address VELA;
        address MasterChef;
        address KyberRouter;
        address VaultkaHandler;
    }

    struct PositionTimestamps {
        uint256 openTimestamp;
        uint256 closeTimestamp;
        uint256 vaultSnapshotID;
    }

    struct CloseData {
        uint256 currentDTV;
        uint256 fulldebtValue;
        uint256 returnedValue;
        uint256 userShares;
        uint256 waterShares;
        uint256 toLeverageUser;
        uint256 totalInt;
    }

    FeeConfiguration public feeConfiguration;
    StrategyAddresses public strategyAddresses;
    address[] public allUsers;
    address public keeper;

    uint256 public MCPID;
    uint256 public MAX_BPS;
    uint256 public MAX_LEVERAGE;
    uint256 public MIN_LEVERAGE;

    uint256 private constant DENOMINATOR = 1_000;
    uint256 private constant DECIMAL = 1e18;
    uint256 public mFeePercent;

    mapping(address => UserInfo[]) public userInfo;
    mapping(address => bool) public allowedSenders;
    mapping(address => bool) public allowedClosers;
    mapping(address => bool) public burner;
    mapping(address => bool) public isUser;
    mapping(address => bool) public isWhitelistedAsset;
    mapping(address => mapping(uint256 => bool)) public closePositionRequest;
    mapping(address => mapping(uint256 => uint256)) public closePositionAmount;
    mapping(address => mapping(uint256 => PositionTimestamps)) public positionTimestamps;

    uint256[50] private __gaps;

    modifier InvalidID(uint256 positionId, address user) {
        require(positionId < userInfo[user].length, "Sake: positionID is not valid");
        _;
    }

    modifier zeroAddress(address addr) {
        require(addr != address(0), "Zero address");
        _;
    }

    modifier onlyBurner() {
        require(burner[msg.sender], "Not allowed to burn");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "Only Keeper");
        _;
    }

    /** --------------------- Event --------------------- */
    event VaultContractChanged(address newVault, address newTokenFarm, address newVlpToken, address newWater);
    event Deposit(address indexed depositer, uint256 depositTokenAmount, uint256 createdAt, uint256 vlpAmount);
    event Withdraw(address indexed user, uint256 amount, uint256 time, uint256 vlpAmount, uint256 returnedValue, uint256 totalInt, uint256 waterRepayment, uint256 fee);
    event ProtocolFeeChanged(
        address newFeeReceiver,
        uint256 newWithdrawalFee,
        address newWaterFeeReceiver,
        uint256 liquidatorsRewardPercentage,
        uint256 DTVLimit
    );
    event Liquidation(
        address indexed liquidator,
        address indexed borrower,
        uint256 positionId,
        uint256 liquidatedAmount,
        uint256 outputAmount,
        uint256 time
    );
    event SetAllowedClosers(address indexed closer, bool allowed);
    event SetAllowedSenders(address indexed sender, bool allowed);
    event SetBurner(address indexed burner, bool allowed);
    event UpdateMCAndPID(address indexed newMC, uint256 mcpPid);
    event UpdateMaxAndMinLeverage(uint256 maxLeverage, uint256 minLeverage);
    event UpdateKyberRouter(address newKyberRouter);
    event OpenRequest(address indexed user, uint256 amountAfterFee);
    event RequestFulfilled(address indexed user, uint256 openAmount, uint256 closedAmount);
    event SetAssetWhitelist(address indexed asset, bool isWhitelisted);
    event Harvested(bool vela, bool esVela, bool vlp, bool vesting);
    event Liquidated(
        address indexed user,
        uint256 indexed positionId,
        address liquidator,
        uint256 amount,
        uint256 reward
    );
    event SetKeeper(address indexed keeper);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _usdc,
        address _water,
        address _velaMintBurnVault,
        address _velaStakingVault,
        address _velaToken,
        address _VaultkaHandler
    ) external initializer {
        require(
            _usdc != address(0) &&
                _water != address(0) &&
                _velaMintBurnVault != address(0) &&
                _velaStakingVault != address(0) &&
                _velaToken != address(0),
            "Zero address"
        );

        strategyAddresses.USDC = _usdc;
        strategyAddresses.water = _water;
        strategyAddresses.velaMintBurnVault = _velaMintBurnVault;
        strategyAddresses.vlpToken = _velaToken;
        strategyAddresses.VaultkaHandler = _VaultkaHandler;
        strategyAddresses.velaStakingVault = _velaStakingVault;
        strategyAddresses.esVela = address(ITokenFarm(_velaStakingVault).esVELA());
        strategyAddresses.VELA = address(ITokenFarm(_velaStakingVault).VELA());
        feeConfiguration.DTVLimit = 95e16;

        MAX_BPS = 100_000;
        MAX_LEVERAGE = 10_000;
        MIN_LEVERAGE = 2_000;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC20_init("SakePODV2", "SPODV2");
    }

    /** ----------- Change onlyOwner functions ------------- */

    //MC or any other whitelisted contracts
    function setAllowed(address _sender, bool _allowed) public onlyOwner zeroAddress(_sender) {
        allowedSenders[_sender] = _allowed;
        emit SetAllowedSenders(_sender, _allowed);
    }

    function setAssetWhitelist(address _asset, bool _status) public onlyOwner {
        isWhitelistedAsset[_asset] = _status;
        emit SetAssetWhitelist(_asset, _status);
    }

    function setCloser(address _closer, bool _allowed) public onlyOwner zeroAddress(_closer) {
        allowedClosers[_closer] = _allowed;
        emit SetAllowedClosers(_closer, _allowed);
    }

    function setBurner(address _burner, bool _allowed) public onlyOwner zeroAddress(_burner) {
        burner[_burner] = _allowed;
        emit SetBurner(_burner, _allowed);
    }

    function setMC(address _MasterChef, uint256 _MCPID) public onlyOwner zeroAddress(_MasterChef) {
        strategyAddresses.MasterChef = _MasterChef;
        MCPID = _MCPID;
        emit UpdateMCAndPID(_MasterChef, _MCPID);
    }

    function setUSDCAddress(address _usdc) public onlyOwner zeroAddress(_usdc) {
        strategyAddresses.USDC = _usdc;
    }

    function setKyberRouter(address _KyberRouter) public onlyOwner zeroAddress(_KyberRouter) {
        strategyAddresses.KyberRouter = _KyberRouter;
        emit UpdateKyberRouter(_KyberRouter);
    }

    function setMaxAndMinLeverage(uint256 _maxLeverage, uint256 _minLeverage) public onlyOwner {
        require(_maxLeverage >= _minLeverage, "Max leverage must be greater than min leverage");
        MAX_LEVERAGE = _maxLeverage;
        MIN_LEVERAGE = _minLeverage;
        emit UpdateMaxAndMinLeverage(_maxLeverage, _minLeverage);
    }

    function setKeeper(address _keeper) public onlyOwner zeroAddress(_keeper) {
        keeper = _keeper;
        emit SetKeeper(_keeper);
    }

    function setProtocolFee(
        address _feeReceiver,
        uint256 _withdrawalFee,
        address _waterFeeReceiver,
        uint256 _liquidatorsRewardPercentage,
        uint256 _mFeePercent,
        uint256 _DTVLimit
    ) external onlyOwner zeroAddress(_feeReceiver) zeroAddress(_waterFeeReceiver) {
        require(_withdrawalFee <= MAX_BPS, "Invalid fees");
        require(_mFeePercent <= 10000, "Invalid mFeePercent");

        feeConfiguration.feeReceiver = _feeReceiver;
        feeConfiguration.withdrawalFee = _withdrawalFee;
        feeConfiguration.waterFeeReceiver = _waterFeeReceiver;
        feeConfiguration.liquidatorsRewardPercentage = _liquidatorsRewardPercentage;
        mFeePercent = _mFeePercent;
        feeConfiguration.DTVLimit = _DTVLimit;

        emit ProtocolFeeChanged(
            _feeReceiver,
            _withdrawalFee,
            _waterFeeReceiver,
            _liquidatorsRewardPercentage,
            _DTVLimit
        );
    }

    function setVelaContracts(
        address _velaMintBurnVault,
        address _velaStakingVault,
        address _vlpToken,
        address _water
    )
        external
        onlyOwner
    {
        strategyAddresses.velaMintBurnVault = _velaMintBurnVault;
        strategyAddresses.velaStakingVault = _velaStakingVault;
        strategyAddresses.vlpToken = _vlpToken;
        strategyAddresses.water = _water;
        emit VaultContractChanged(_velaMintBurnVault, _velaStakingVault, _vlpToken, _water);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /** ----------- Admin VELA functions ------------- */

    function harvestMany(bool _vela, bool _esvela, bool _vlp, bool _vesting) external onlyOwner {
        ITokenFarm(strategyAddresses.velaStakingVault).harvestMany(_vela, _esvela, _vlp, _vesting);
        emit Harvested(_vela, _esvela, _vlp, _vesting);
    }

    /**
     * @notice Withdraw vested ESVELA tokens and transfer vested VELA tokens to the fee receiver.
     * @dev The function can only be called by the contract owner (usually the deployer of the contract).
     *      The function first gets the current balance of ESVELA tokens held by the contract before withdrawal.
     *      It then calls the `withdrawVesting` function of the `velaStakingVault` contract to withdraw vested ESVELA tokens.
     *      After withdrawal, the function gets the new balance of ESVELA tokens held by the contract.
     *      It calculates the amount of ESVELA tokens vested by subtracting the balance before withdrawal from the balance after withdrawal.
     *      The vested ESVELA tokens are transferred to the fee receiver specified in the `feeConfiguration`.
     *      The function also transfers any vested VELA tokens held by the contract to the fee receiver.
     */
    function withdrawVesting() external onlyOwner {
        uint256 esVelaBeforeWithdrawal = IERC20Upgradeable(strategyAddresses.esVela).balanceOf(address(this));
        ITokenFarm(strategyAddresses.velaStakingVault).withdrawVesting();
        uint256 esVelaAfterWithdrawal = IERC20Upgradeable(strategyAddresses.esVela).balanceOf(address(this));
        IERC20Upgradeable(strategyAddresses.esVela).safeTransfer(
            feeConfiguration.feeReceiver,
            esVelaAfterWithdrawal - esVelaBeforeWithdrawal
        );
        IERC20Upgradeable(strategyAddresses.VELA).safeTransfer(
            feeConfiguration.feeReceiver,
            IERC20Upgradeable(strategyAddresses.VELA).balanceOf(address(this))
        );
    }

    // deposit vesting
    function depositVesting() external onlyOwner {
        uint256 esVelaContractBalance = IERC20Upgradeable(strategyAddresses.esVela).balanceOf(address(this));
        IERC20Upgradeable(strategyAddresses.esVela).safeIncreaseAllowance(
            strategyAddresses.velaStakingVault,
            esVelaContractBalance
        );
        ITokenFarm(strategyAddresses.velaStakingVault).depositVesting(esVelaContractBalance);
    }

    function claim() external onlyOwner {
        ITokenFarm(strategyAddresses.velaStakingVault).claim();
        IERC20Upgradeable(strategyAddresses.VELA).safeTransfer(
            feeConfiguration.feeReceiver,
            IERC20Upgradeable(strategyAddresses.VELA).balanceOf(address(this))
        );
    }

    // withdraw all vela tokens from the vault
    function withdrawAllVELA() external onlyOwner {
        IERC20Upgradeable(strategyAddresses.VELA).safeTransfer(
            feeConfiguration.feeReceiver,
            IERC20Upgradeable(strategyAddresses.VELA).balanceOf(address(this))
        );
    }

    // withdraw all esvela tokens from the vault
    function withdrawAllESVELA() external onlyKeeper {
        IERC20Upgradeable(strategyAddresses.esVela).safeTransfer(
            feeConfiguration.waterFeeReceiver,
            IERC20Upgradeable(strategyAddresses.esVela).balanceOf(address(this))
        );
    }

    /** ----------- View functions ------------- */

    function getVLPPrice() public view returns (uint256) {
        return IVault(strategyAddresses.velaMintBurnVault).getVLPPrice();
    }

    function getVlpBalance() public view returns (uint256) {
        return IERC20Upgradeable(strategyAddresses.vlpToken).balanceOf(address(this));
    }

    function getStakedVlpBalance() public view returns (uint256) {
        return ITokenFarm(strategyAddresses.velaStakingVault).getStakedVLP(address(this));
    }

    function getAllUsers() public view returns (address[] memory) {
        return allUsers;
    }

    function getClaimable() public view returns (uint256) {
        return ITokenFarm(strategyAddresses.velaStakingVault).claimable(address(this));
    }

    function getTotalNumbersOfOpenPositionBy(address _user) public view returns (uint256) {
        return userInfo[_user].length;
    }

    /**
     * @notice Get the updated debt, current position, and current debt-to-value (DTV) ratio for the given position ID and user address.
     * @param _positionID The ID of the position to get the updated debt and value for.
     * @param _user The address of the user for the position.
     * @return currentDTV The current debt-to-value (DTV) ratio for the position.
     * @return currentPosition The current position value in USDC for the position.
     * @return currentDebt The current debt amount in USDC for the position.
     * @dev The function retrieves user information for the given position.
     *      The function calculates the profit or loss for the position based on the current position and previous value in USDC.
     *      The function calculates the current DTV by dividing the amount owed to water by the current position.
     */
    function getUpdatedDebt(
        uint256 _positionID,
        address _user
    ) public view returns (uint256, uint256, uint256, uint256) {
        UserInfo memory _userInfo = userInfo[_user][_positionID];
        if (_userInfo.closed || _userInfo.liquidated) return (0, 0, 0, 0);
        PositionTimestamps memory pts = positionTimestamps[_user][_positionID];

        //in Borrowed asset
        (uint256 leverageWithInterests,uint256 totalInterests) = IHandler(strategyAddresses.VaultkaHandler).getPositionWithInterestRate(
            _user,
            _positionID,
            address(this),
            address(this),
            pts.openTimestamp,
            _userInfo.leverageAmount,
            pts.vaultSnapshotID
        );

        uint256 currentPosition = _userInfo.position.mulDiv( getVLPPrice() * 10, (10 ** 18));

        // Calculate the current DTV by dividing the amount owed to water by the current position
        uint256 currentDTV = leverageWithInterests.mulDiv(DECIMAL, currentPosition);
        // Return the current DTV, current position, and amount owed to water
        return (currentDTV, currentPosition, leverageWithInterests,totalInterests);
    }

    /** ----------- User functions ------------- */

    /**
     * @notice Opens a new position with the specified amount and leverage.
     * @param _amount The amount of tokens to use for opening the position.
     * @param _leverage The leverage to apply for the position.
     * @param _data The data to be used for swapping tokens if necessary.
     * @param _swapSimple Flag to indicate if simple token swapping is allowed.
     * @param _inputAsset The address of the input asset (token) for the position.
     * @dev The contract must be in a non-paused state and meet the leverage requirements.
     *      If the input asset is not USDC, it must be whitelisted.
     *      The `_amount` must be greater than zero.
     *      If `_inputAsset` is not USDC, the function swaps the input asset to USDC.
     *      The function then lends the leveraged amount of USDC using the `water` contract.
     *      The `xAmount` is calculated by adding the leveraged amount to the initial amount.
     *      The contract increases allowance and stakes the `xAmount` to the `velaMintBurnVault`.
     *      The vela shares are minted to the user and deposited to the `velaStakingVault`.
     */
    function openPosition(
        uint256 _amount,
        uint256 _leverage,
        bytes calldata _data,
        bool _swapSimple,
        address _inputAsset
    ) external whenNotPaused nonReentrant {
        require(_leverage >= MIN_LEVERAGE && _leverage <= MAX_LEVERAGE, "Sake: Invalid leverage");
        require(_amount > 0, "Sake: amount must be greater than zero");
        IERC20Upgradeable(_inputAsset).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 amount;
        // swap to USDC if input is not USDC
        if (_inputAsset != strategyAddresses.USDC) {
            require(isWhitelistedAsset[_inputAsset], "Sake: Invalid assets choosen");
            amount = _swap(_amount, _data, _swapSimple, true, _inputAsset);
        } else {
            amount = _amount;
        }
        // get leverage amount
        uint256 leveragedAmount = amount.mulDiv(_leverage, DENOMINATOR) - amount;
        bool status = IWater(strategyAddresses.water).lend(leveragedAmount);
        require(status, "Water: Lend failed");
        // add leverage amount to amount
        uint256 xAmount = amount + leveragedAmount;

        IERC20Upgradeable(strategyAddresses.USDC).safeIncreaseAllowance(strategyAddresses.velaMintBurnVault, xAmount);
        uint256 balanceBefore = getVlpBalance();
        // stake to vela
        IVault(strategyAddresses.velaMintBurnVault).stake(address(this), strategyAddresses.USDC, xAmount);
        uint256 balanceAfter = getVlpBalance();

        uint256 velaShares = balanceAfter - balanceBefore;
        IERC20Upgradeable(strategyAddresses.vlpToken).safeIncreaseAllowance(
            strategyAddresses.velaStakingVault,
            velaShares
        );
        // deposit to vela staking vault
        ITokenFarm(strategyAddresses.velaStakingVault).depositVlp(velaShares);
        UserInfo memory _userInfo = UserInfo({
            user: msg.sender,
            deposit: amount,
            leverage: _leverage,
            position: velaShares,
            price: getVLPPrice(),
            liquidated: false,
            cooldownPeriodElapse: block.timestamp + 1,
            closedPositionValue: 0,
            liquidator: address(0),
            leverageAmount: leveragedAmount,
            positionId: userInfo[msg.sender].length,
            closed: false
        });

        //frontend helper to fetch all users and then their userInfo
        if (isUser[msg.sender] == false) {
            isUser[msg.sender] = true;
            allUsers.push(msg.sender);
        }

        uint256 posID = userInfo[msg.sender].length;
        PositionTimestamps storage pts = positionTimestamps[msg.sender][posID];
        pts.openTimestamp = block.timestamp;
        pts.vaultSnapshotID = IHandler(strategyAddresses.VaultkaHandler).vaultCurrentSnapshotID(address(this));

        userInfo[msg.sender].push(_userInfo);
        // mint vela shares to user
        _mint(msg.sender, velaShares);

        emit Deposit(msg.sender, amount, block.timestamp, velaShares);
    }

    /**
     * @notice Closes a position with the specified position ID, asset percent, and user address.
     * @param _positionID The ID of the position to close.
     * @param _user The address of the user associated with the product ID.
     * @param _sameSwap Flag to indicate if the same swap is allowed.
     * @dev The function requires that the position is not already liquidated and the cooldown period has expired.
     *      The caller must be allowed to close the position or be the position owner.
     *      The function calculates the withdrawable shares, profits, and if the user is withdrawing in full.
     *      If the user is not withdrawing in full, it calculates the debt value and after loan payment.
     *      The function burns the withdrawable shares from the user.
     *      It then withdraws and unstakes the user's withdrawable shares.
     *      If the user is not withdrawing in full, it repays debt to the `water` contract.
     *      If the withdrawal fee is applicable, it takes a protocol fee.
     *      and if `_sameSwap` is true, it transfers the amount after fee to the user in USDC.
     *      If `_sameSwap` is false, it makes a withdrawal request for the user to withdraw the asset and emits the `OpenRequest` event.
     */
    function closePosition(
        uint256 _positionID,
        address _user,
        bool _sameSwap
    ) external InvalidID(_positionID, _user) nonReentrant {
        // Retrieve user information for the given position
        UserInfo storage _userInfo = userInfo[_user][_positionID];
        // Validate that the position is not liquidated
        require(!_userInfo.liquidated, "Sake: position is liquidated");
        // Validate that the position has enough shares to close
        require(_userInfo.position > 0, "Sake: position is not enough to close");
        require(block.timestamp >= _userInfo.cooldownPeriodElapse, "Sake: user timelock not expired");
        require(allowedClosers[msg.sender] || msg.sender == _userInfo.user, "SAKE: not allowed to close position");

        // Struct to store intermediate data during calculation
        Datas memory data;
        CloseData memory closeData;
        Datas memory closeData2;

        // check for liquidation
        (closeData.currentDTV, ,closeData.fulldebtValue, closeData.totalInt) = getUpdatedDebt(_positionID, _user);

        if (closeData.currentDTV >= (feeConfiguration.DTVLimit)) {
            revert("Wait for liquidation");
        }

        closeData2.withdrawableShares = _userInfo.position;
        _handlePODToken(_userInfo.user, _userInfo.position);
        (closeData.returnedValue, ) = _withdrawAndUnstakeVLP(_userInfo.position);

        uint256 waterRepayment;
        if (closeData.returnedValue < _userInfo.leverageAmount) {
            _userInfo.liquidator = msg.sender;
            _userInfo.liquidated = true;
            waterRepayment = closeData.returnedValue;
        } else if (closeData.returnedValue < closeData.fulldebtValue && closeData.returnedValue >= _userInfo.leverageAmount) {
            waterRepayment = _userInfo.leverageAmount;
            closeData.totalInt = closeData.returnedValue - waterRepayment;
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(feeConfiguration.waterFeeReceiver, closeData.totalInt);
            _userInfo.liquidator = msg.sender;
            _userInfo.liquidated = true;
        } else {
            waterRepayment = _userInfo.leverageAmount;
            closeData.toLeverageUser = (closeData.returnedValue - waterRepayment) - closeData.totalInt;
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(feeConfiguration.waterFeeReceiver, closeData.totalInt);
        }

        IERC20Upgradeable(strategyAddresses.USDC).safeIncreaseAllowance(strategyAddresses.water, waterRepayment);
        data.success = IWater(strategyAddresses.water).repayDebt(_userInfo.leverageAmount, waterRepayment);

        _userInfo.position = 0;
        _userInfo.leverageAmount = 0;
        _userInfo.closed = true;

        if (_userInfo.liquidated) {
            return;
        }

        // take protocol fee
        uint256 amountAfterFee;
        uint256 fee;
        if (feeConfiguration.withdrawalFee > 0 && closeData.toLeverageUser > 0) {
            fee = closeData.toLeverageUser.mulDiv(feeConfiguration.withdrawalFee, MAX_BPS);
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(feeConfiguration.feeReceiver, fee);
            amountAfterFee = closeData.toLeverageUser - fee;
        } else {
            amountAfterFee = closeData.toLeverageUser;
        }

        // if user is withdrawing USDC then transfer amount after fee to user else
        // make a withdrawal request for user to withdraw asset and emmit OpenRequest event
        if (_sameSwap) {
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(_user, amountAfterFee);
        } else {
            closePositionAmount[_user][_positionID] = amountAfterFee;
            closePositionRequest[_user][_positionID] = true;
            emit OpenRequest(_user, amountAfterFee);
        }

        _userInfo.closedPositionValue += closeData.returnedValue;
        PositionTimestamps storage pts = positionTimestamps[_user][_positionID];
        pts.closeTimestamp = block.timestamp;

        emit Withdraw(_user, amountAfterFee, block.timestamp, closeData2.withdrawableShares, closeData.returnedValue, closeData.totalInt, waterRepayment,fee);
    }


    /**
     * @notice Fulfills a swap request for a closed position with the specified position ID, user address, and output asset.
     * @param _positionID The ID of the position to fulfill the swap request for.
     * @param _data The data to be used for swapping tokens.
     * @param _swapSimple Flag to indicate if simple token swapping is allowed.
     * @param _outputAsset The address of the output asset (token) for the swap.
     * @dev The function requires that the output asset is whitelisted and the swap amount is greater than zero.
     *      The function swaps the `amountAfterFee` of USDC to `_outputAsset` using the provided `_data`.
     *      The swapped `_outputAsset` amount is transferred to the user.
     */
    function fulfilledRequestSwap(
        uint256 _positionID,
        bytes calldata _data,
        bool _swapSimple,
        address _outputAsset
    ) external nonReentrant {
        // Retrieve the amount after fee from the `closePositionAmount` mapping
        uint256 amountAfterFee = closePositionAmount[msg.sender][_positionID];
        require(isWhitelistedAsset[_outputAsset], "Sake: Invalid assets choosen");
        require(amountAfterFee > 0, "Sake: position is not enough to close");
        require(closePositionRequest[msg.sender][_positionID], "SAKE: Close only open position");

        closePositionAmount[msg.sender][_positionID] = 0;
        closePositionRequest[msg.sender][_positionID] = false;

        uint256 amountOut = _swap(amountAfterFee, _data, _swapSimple, false, _outputAsset);
        IERC20Upgradeable(_outputAsset).safeTransfer(msg.sender, amountOut);
        emit RequestFulfilled(msg.sender, amountAfterFee, amountOut);
    }

    /**
     * @notice Liquidate the position of a user if the debt-to-value (DTV) ratio reaches the liquidation threshold.
     * @dev The function can only be called once for each position ID and user address and cannot be called for already liquidated positions.
     * @param _positionId The ID of the position to be liquidated.
     * @param _user The address of the user for the position.
     * @dev The function first retrieves the user information for the given position ID and user address from the `userInfo` mapping.
     *      It checks if the position has already been liquidated and if a valid user exists for the liquidation request.
     *      The function calls the `getUpdatedDebt` function to get the current debt-to-value (DTV) ratio for the position.
     *      It checks if the DTV ratio is greater than or equal to the liquidation threshold (95%).
     *      If the MasterChef contract is specified, the function checks the user's amount staked in the MasterChef pool and performs liquidation from the pool if applicable.
     *      If the user has no amount staked in the MasterChef pool or the staked amount is less than the position, the function burns the user's VELA shares corresponding to the position amount.
     *      It then withdraws the VLP (Vela LP) tokens from the velaStakingVault using the `withdrawVlp` function of the `velaStakingVault` contract.
     *      After withdrawing the VLP tokens, the function unstakes the corresponding USDC tokens from the velaMintBurnVault using the `unstake` function of the `velaMintBurnVault` contract.
     *      The function calculates the returned value in USDC after liquidation and deducts the liquidator's reward from it.
     *      It repays the debt using the remaining amount after deducting the liquidator's reward.
     *      The liquidator's reward is transferred to the liquidator's address, and the position is marked as liquidated in the user information.
     */
    function liquidatePosition(uint256 _positionId, address _user) external nonReentrant {
        UserInfo storage _userInfo = userInfo[_user][_positionId];
        CloseData memory closeData;

        require(!_userInfo.liquidated, "Sake: Already liquidated");
        require(_userInfo.user != address(0), "Sake: liquidation request does not exist");
        (closeData.currentDTV , ,closeData.fulldebtValue, closeData.totalInt) = getUpdatedDebt(_positionId, _user);
        require(closeData.currentDTV >= feeConfiguration.DTVLimit, "Liquidation Threshold Has Not Reached");

        uint256 position = _userInfo.position;

        _handlePODToken(_user, position);

        IERC20Upgradeable(strategyAddresses.vlpToken).approve(strategyAddresses.velaStakingVault, _userInfo.position);
        uint256 vlpBalanceBeforeWithdrawal = getVlpBalance();
        ITokenFarm(strategyAddresses.velaStakingVault).withdrawVlp(position);
        uint256 vlpBalanceAfterWithdrawal = getVlpBalance();

        uint256 usdcBalanceBefore = IERC20Upgradeable(strategyAddresses.USDC).balanceOf(address(this));
        IVault(strategyAddresses.velaMintBurnVault).unstake(
            strategyAddresses.USDC,
            (vlpBalanceAfterWithdrawal - vlpBalanceBeforeWithdrawal)
        );
        uint256 usdcBalanceAfter = IERC20Upgradeable(strategyAddresses.USDC).balanceOf(address(this));
        closeData.returnedValue = usdcBalanceAfter - usdcBalanceBefore;

        _userInfo.liquidator = msg.sender;
        _userInfo.liquidated = true;

        uint256 lendingRepayAmount;
        uint256 liquidatorReward; 
        if (closeData.returnedValue < closeData.fulldebtValue) {
            lendingRepayAmount = closeData.returnedValue;
        } else if (closeData.returnedValue < closeData.fulldebtValue && closeData.returnedValue >= _userInfo.leverageAmount) { 
            lendingRepayAmount = _userInfo.leverageAmount;
            closeData.totalInt = closeData.returnedValue - lendingRepayAmount;
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(feeConfiguration.waterFeeReceiver, closeData.totalInt);
        } else {
            lendingRepayAmount = _userInfo.leverageAmount;
            uint256 leftovers = closeData.returnedValue - _userInfo.leverageAmount - closeData.totalInt;
            liquidatorReward = leftovers.mulDiv(feeConfiguration.liquidatorsRewardPercentage, MAX_BPS);
            leftovers = leftovers - liquidatorReward;
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(msg.sender, liquidatorReward);
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(_user, leftovers);
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(feeConfiguration.waterFeeReceiver, closeData.totalInt);
        }

        IERC20Upgradeable(strategyAddresses.USDC).safeIncreaseAllowance(strategyAddresses.water,lendingRepayAmount);
        bool success = IWater(strategyAddresses.water).repayDebt(_userInfo.leverageAmount, lendingRepayAmount);
        require(success, "Water: Repay failed");

        PositionTimestamps storage pts = positionTimestamps[_user][_positionId];
        pts.closeTimestamp = block.timestamp;

        emit Liquidated(_user, _positionId, msg.sender, closeData.returnedValue, liquidatorReward);
    }

    function _handlePODToken(address _user, uint256 position) internal {
        if (strategyAddresses.MasterChef != address(0)) {
            uint256 userBalance = balanceOf(_user);
            if (userBalance >= position) {
                _burn(_user, position);
            } else {
                _burn(_user, userBalance);
                (uint256 depositAmount, , ) = IMasterChef(strategyAddresses.MasterChef).userInfo(
                    MCPID,
                    _user
                );
                if (depositAmount > 0) {
                    uint256 remainingPosition = position - userBalance;
                    IMasterChef(strategyAddresses.MasterChef).unstakeAndLiquidate(
                        MCPID,
                        _user,
                        remainingPosition
                    );
                }
            }
        } else {
            uint256 userBalance = balanceOf(_user);
            if (userBalance >= position) {
                _burn(_user, position);
            } else {
                _burn(_user, userBalance);
            }
        }
    }

    /** ----------- Token functions ------------- */

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        require(allowedSenders[from] || allowedSenders[to] || allowedSenders[spender], "ERC20: transfer not allowed");
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address ownerOf = _msgSender();
        require(allowedSenders[ownerOf] || allowedSenders[to], "ERC20: transfer not allowed");
        _transfer(ownerOf, to, amount);
        return true;
    }

    function burn(uint256 amount) public virtual override onlyBurner {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address from, uint256 amount) public virtual override onlyBurner {}

    /** ----------- Internal functions ------------- */

    /**
     * @notice Internal function to perform a token swap using Kyber Router.
     * @dev The function swaps tokens using Kyber Router, which is an external contract.
     *      It supports both simple mode and generic mode swaps.
     * @param _amount The amount of tokens to be swapped.
     * @param _data The data containing the swap description and parameters. The data is ABI-encoded and can be either in simple mode or generic mode format.
     * @param _swapSimple A boolean indicating whether the swap is in simple mode (true) or generic mode (false).
     * @param _swapToUnderlying A boolean indicating whether the swap is from USDC to the underlying asset (true) or vice versa (false).
     * @param _asset The address of the asset being swapped.
     * @return The amount of tokens received after the swap.
     */
    function _swap(
        uint256 _amount,
        bytes calldata _data,
        bool _swapSimple,
        bool _swapToUnderlying,
        address _asset
    ) internal returns (uint256) {
        SwapDescriptionV2 memory desc;

        if (_swapSimple) {
            // 0x8af033fb -> swapSimpleMode
            // Decode the data for a swap in simple mode
            (, SwapDescriptionV2 memory des, , ) = abi.decode(_data[4:], (address, SwapDescriptionV2, bytes, bytes));
            desc = des;
        } else {
            // 0x59e50fed -> swapGeneric
            // 0xe21fd0e9 -> swap
            // Decode the data for a swap in generic mode
            SwapExecutionParams memory des = abi.decode(_data[4:], (SwapExecutionParams));
            desc = des.generic;
        }

        require(desc.dstReceiver == address(this), "Receiver must be this contract");
        require(desc.amount == _amount, "Swap amounts must match");
        uint256 assetBalBefore;
        uint256 assetBalAfter;
        bool succ;
        // Perform the token swap depending on the `_swapToUnderlying` parameter
        if (_swapToUnderlying) {
            // Swap from Whitelisted token to the underlying asset (USDC)
            require(
                desc.dstToken == IERC20Upgradeable(strategyAddresses.USDC),
                "Output must be the same as _inputAsset"
            );
            require(desc.srcToken == IERC20Upgradeable(_asset), "Input must be the same as _inputAsset");
            assetBalBefore = IERC20Upgradeable(strategyAddresses.USDC).balanceOf(address(this));
            IERC20Upgradeable(_asset).safeIncreaseAllowance(strategyAddresses.KyberRouter, desc.amount);
            (succ, ) = address(strategyAddresses.KyberRouter).call(_data);
            assetBalAfter = IERC20Upgradeable(strategyAddresses.USDC).balanceOf(address(this));
        } else {
            // Swap from the underlying asset (USDC) to output token
            require(desc.dstToken == IERC20Upgradeable(_asset), "Output must be the same as _inputAsset");
            require(
                desc.srcToken == IERC20Upgradeable(strategyAddresses.USDC),
                "Input must be the same as _inputAsset"
            );
            assetBalBefore = IERC20Upgradeable(_asset).balanceOf(address(this));
            IERC20Upgradeable(strategyAddresses.USDC).safeIncreaseAllowance(strategyAddresses.KyberRouter, desc.amount);
            (succ, ) = address(strategyAddresses.KyberRouter).call(_data);
            assetBalAfter = IERC20Upgradeable(_asset).balanceOf(address(this));
        }
        require(succ, "Swap failed");
        // Check that the token balance after the swap increased
        require(assetBalAfter > assetBalBefore, "SAKE: Swap failed");
        // Return the amount of tokens received after the swap
        return (assetBalAfter - assetBalBefore);
    }

    function _withdrawAndUnstakeVLP(uint256 _shares) internal returns (uint256, uint256) {
        IERC20Upgradeable(strategyAddresses.vlpToken).safeIncreaseAllowance(
            strategyAddresses.velaStakingVault,
            _shares
        );
        uint256 vlpBalanceBeforeWithdrawal = getVlpBalance();
        ITokenFarm(strategyAddresses.velaStakingVault).withdrawVlp(_shares);
        uint256 vlpBalanceAfterWithdrawal = getVlpBalance();

        uint256 usdcBalanceBefore = IERC20Upgradeable(strategyAddresses.USDC).balanceOf(address(this));
        uint256 vlpAmount = (vlpBalanceAfterWithdrawal - vlpBalanceBeforeWithdrawal);
        IVault(strategyAddresses.velaMintBurnVault).unstake(strategyAddresses.USDC, vlpAmount);
        uint256 usdcBalanceAfter = IERC20Upgradeable(strategyAddresses.USDC).balanceOf(address(this));

        return (usdcBalanceAfter - usdcBalanceBefore, vlpAmount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewards, uint256 boostMultiplier);
    function unstakeAndLiquidate(uint256 _pid, address user, uint256 amount) external;
}

pragma solidity 0.8.18;
// SPDX-License-Identifier: MIT

interface ITokenBurnable {
    function burn(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @dev Interface of the SettingManager
 */
interface ISettingManager {
    function cooldownDuration() external view returns (uint256);
    function isWhitelistedFromCooldown(address _user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @dev Interface of the VeDxp
 */
interface ITokenFarm {
    function depositVlp(uint256 _amount) external;

    function withdrawVlp(uint256 _amount) external;

    function harvestMany(bool _vela, bool _esvela, bool _vlp, bool _vesting) external;

    function claimable(address _account) external view returns (uint256);

    function esVELA() external view returns (address);

    function VELA() external view returns (address);

    function withdrawVesting() external;

    function depositVesting(uint256 _amount) external;

    function claim() external;

    function getStakedVLP(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

//@note this interface is actually for minting and burning, the function name is confusing
interface IVault {
    function stake(address _account, address _token, uint256 _amount) external;

    function unstake(address _tokenOut, uint256 _vlpAmount) external;

    function getVLPPrice() external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/**
 * @author Chef Photons, Vaultka Team serving high quality drinks; drink responsibly.
 * Responsible for our customers not getting intoxicated
 * @notice provided interface for `Water.sol`
 */
// interface IWater {
//     /// @notice supply USDC to the vault
//     /// @param _amount to be leveraged to Bartender (6 decimals)
//     function leverageVault(uint256 _amount) external;

//     /// @notice collect debt from Bartender
//     /// @param _amount to be collected from Bartender (6 decimals)
//     function repayDebt(uint256 _amount) external;

//     function getTotalDebt() external view returns (uint256);

//     function updateTotalDebt(uint256 profit) external returns (uint256);
// }

interface IWater {
    function lend(uint256 _amount) external returns (bool);

    function repayDebt(uint256 leverage, uint256 debtValue) external returns (bool);

    function getTotalDebt() external view returns (uint256);

    function updateTotalDebt(uint256 profit) external returns (uint256);

    function totalAssets() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function balanceOfUSDC() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}