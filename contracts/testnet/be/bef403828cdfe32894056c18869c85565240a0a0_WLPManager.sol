// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/core/IVaultAccessControlRegistry.sol";

pragma solidity 0.8.17;

contract AccessControlBase is Context {
    IVaultAccessControlRegistry public immutable registry;
    address public immutable timelockAddressImmutable;

    constructor(
        address _vaultRegistry,
        address _timelock
    ) {
        registry = IVaultAccessControlRegistry(_vaultRegistry);
        timelockAddressImmutable = _timelock;
    }

    /*==================== Managed in VaultAccessControlRegistry *====================*/

    modifier onlyGovernance() {
        require(
            registry.isCallerGovernance(_msgSender()),
            "Forbidden: Only Governance"
        );
        _;
    }

    modifier onlyManager() {
        require(
            registry.isCallerManager(_msgSender()),
            "Forbidden: Only Manager"
        );
        _;
    }

    modifier onlyEmergency() {
        require(
            registry.isCallerEmergency(_msgSender()),
            "Forbidden: Only Emergency"
        );
        _;
    }

    modifier isGlobalPause() {
        require(
            !registry.isProtocolPaused(),
            "Forbidden: Protocol Paused"
        );
        _;
    }

    /*==================== Managed in WINRTimelock *====================*/

    modifier onlyTimelockGovernance() {
        address timelockActive_;
        if(!registry.timelockActivated()) {
            // the flip is not switched yet, so this means that the governance address can still pass the onlyTimelockGoverance modifier
            timelockActive_ = registry.governanceAddress();
        } else {
            // the flip is switched, the immutable timelock is now locked in as the only adddress that can pass this modifier (and nothing can undo that)
            timelockActive_ = timelockAddressImmutable;
        }
        require(
            _msgSender() == timelockActive_,
            "Forbidden: Only TimelockGovernance"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

import "solmate/src/utils/SafeTransferLib.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/core/IVault.sol";
import "../interfaces/core/IWLPManager.sol";
import "../interfaces/tokens/wlp/IUSDW.sol";
import "../interfaces/tokens/wlp/IMintable.sol";
import "./AccessControlBase.sol";

pragma solidity 0.8.17;

contract WLPManager is ReentrancyGuard, Context, AccessControlBase, IWLPManager {

    /*==================== Constants *====================*/
    uint256 private constant PRICE_PRECISION = 1e30;
    uint256 private constant USDW_DECIMALS = 18;
    uint256 private constant WLP_PRECISION = 1e18;
    uint256 private constant MAX_COOLDOWN_DURATION = 48 hours;
    uint256 private constant BASIS_POINTS_DIVISOR = 1e4;

    /*==================== State Variabes *====================*/

    IVault public immutable override vault;
    address public immutable override usdw;
    address public immutable override wlp;
    uint256 public override cooldownDuration;
    mapping (address => uint256) public override lastAddedAt;
    uint256 public aumAddition;
    uint256 public aumDeduction;
    bool public inPrivateMode;

    // todo add explanation
    mapping (address => bool) public isHandler;

    // todo probably makes more sense set to false???
    bool public handlersEnabled = true;

    constructor(
        address _vault, 
        address _usdw, 
        address _wlp, 
        uint256 _cooldownDuration,
        address _vaultRegistry,
        address _timelock
    ) AccessControlBase(_vaultRegistry, _timelock) {
        vault = IVault(_vault);
        usdw = _usdw;
        wlp = _wlp;
        cooldownDuration = _cooldownDuration;
    }

    /*==================== Configuration functions (onlyGovernance and onlyTimelockGovernance) *====================*/

    // if in private mode, both addLiquidity and removeLiquidity ar disabled
    function setInPrivateMode(bool _inPrivateMode) external onlyGovernance {
        inPrivateMode = _inPrivateMode;
    }

    function setHandlerEnabled(bool _setting) external onlyTimelockGovernance {
        handlersEnabled = _setting;
    }

    /**
     * @dev since this function could 'steal' assets of LPs that do not agree with the action, it has a timelock on it
     * @param _handler address of the handler that will be allowed to handle the WLPs wlp on their behalf
     * @param _isActive xxx
     * note todo before had onlyTimelockGovernance consider adding it again i guess?
     */
    function setHandler(address _handler, bool _isActive) external onlyGovernance {
        isHandler[_handler] = _isActive;
        emit HandlerSet(
            _handler,
            _isActive
        );
    }

    function setCooldownDuration(uint256 _cooldownDuration) external override onlyGovernance {
        require(
            _cooldownDuration <= MAX_COOLDOWN_DURATION, 
            "WLPManager: invalid _cooldownDuration"
        );
        cooldownDuration = _cooldownDuration;
    }

    function setAumAdjustment(uint256 _aumAddition, uint256 _aumDeduction) external onlyGovernance {
        aumAddition = _aumAddition;
        aumDeduction = _aumDeduction;
    }

    /*==================== Operational functions WINR/JB *====================*/

    /**
     * @notice the function that can mint WLP/ add liquidity to the vault
     * @dev this function mints WLP to the msg sender, also this will mint USDW to this contract
     * @param _token the address of the token being deposited as LP
     * @param _amount the amount of the token being deposited
     * @param _minUsdw the minimum USDW the callers wants his deposit to be valued at
     * @param _minWlp the minimum amount of WLP the callers wants to receive
     * @return wlpAmount_ returns the amount of WLP that was minted to the _account
     */
    function addLiquidity(
        address _token, 
        uint256 _amount, 
        uint256 _minUsdw, 
        uint256 _minWlp) external override nonReentrant returns (uint256 wlpAmount_) {
        if (inPrivateMode) { revert("WLPManager: action not enabled"); }
        wlpAmount_ = _addLiquidity(
            _msgSender(), 
            _msgSender(), 
            _token, 
            _amount, 
            _minUsdw, 
            _minWlp
        );
    }

    /**
     * @notice the function that can mint WLP/ add liquidity to the vault (for a handler)
     * @param _fundingAccount the address that will source the tokens to de deposited
     * @param _account the address that will receive the WLP
     * @param _token the address of the token being deposited as LP
     * @param _amount the amount of the token being deposited
     * @param _minUsdw the minimum USDW the callers wants his deposit to be valued at
     * @param _minWlp the minimum amount of WLP the callers wants to receive
     * @return wlpAmount_ returns the amount of WLP that was minted to the _account
     */
    function addLiquidityForAccount(
        address _fundingAccount, 
        address _account, 
        address _token, 
        uint256 _amount, 
        uint256 _minUsdw, 
        uint256 _minWlp) external override nonReentrant returns (uint256 wlpAmount_) {
        _validateHandler();
        wlpAmount_ = _addLiquidity(
            _fundingAccount, 
            _account, 
            _token, 
            _amount, 
            _minUsdw, 
            _minWlp
        );
    }

    /**
     * @param _tokenOut address of the token the redeemer wants to receive
     * @param _wlpAmount  amount of wlp tokens to be redeemed for _tokenOut
     * @param _minOut minimum amount of _tokenOut the redemeer wants to receive
     * @param _receiver  address that will reive the _tokenOut assets
     * @return tokenOutAmount_ uint256 amount of the tokenOut the caller receives (for their burned WLP)
     */
    function removeLiquidity(
        address _tokenOut, 
        uint256 _wlpAmount, 
        uint256 _minOut, 
        address _receiver) external override nonReentrant returns (uint256 tokenOutAmount_) {
        if (inPrivateMode) { revert("WLPManager: action not enabled"); }
        tokenOutAmount_ = _removeLiquidity(
            _msgSender(), 
            _tokenOut, 
            _wlpAmount, 
            _minOut, 
            _receiver
        );
    }

    /**
     * @notice handler remove liquidity function - redeems WLP for selected asset
     * @param _account  the address that will source the WLP  tokens
     * @param _tokenOut address of the token the redeemer wants to receive
     * @param _wlpAmount  amount of wlp tokens to be redeemed for _tokenOut
     * @param _minOut minimum amount of _tokenOut the redemeer wants to receive
     * @param _receiver  address that will reive the _tokenOut assets
     * @return tokenOutAmount_ uint256 amount of the tokenOut the caller receives
     */
    function removeLiquidityForAccount(
        address _account, 
        address _tokenOut, 
        uint256 _wlpAmount, 
        uint256 _minOut, 
        address _receiver) external override nonReentrant returns (uint256 tokenOutAmount_) {
        _validateHandler();
        tokenOutAmount_ = _removeLiquidity(
            _account, 
            _tokenOut, 
            _wlpAmount, 
            _minOut,
            _receiver
        );
    }

    /*==================== View functions WINR/JB *====================*/

    /**
     * @notice returns the value of 1 wlp token in USD (scaled 1e30)
     * @param _maximise  when true, the assets maxPrice will be used (upper bound), when false lower bound will be used
     * @return tokenPrice_ xxx todo
     */
    function getPrice(bool _maximise) external view returns (uint256 tokenPrice_) {
        uint256 aum_ = getAum(_maximise);
        uint256 supply_ = ERC20(wlp).totalSupply();
        if(supply_ == 0) { return 0; }
        tokenPrice_ = ((aum_ * WLP_PRECISION) / supply_);
    }

    /**
     * @param _maximise bool signifying if the maxPrices of the tokens need to be used
     * @return aumUSDW_ the amount of aub denomnated in USDW tokens
     * @dev the USDW tokens are 1e18 scaled, not 1e30 as the USD value is represented
     */
    function getAumInUsdw(bool _maximise) public override view returns (uint256 aumUSDW_) {
        uint256 aum_ = getAum(_maximise);
        aumUSDW_ = (aum_ * (10 ** USDW_DECIMALS)) / PRICE_PRECISION;
    }

    /**
     * @notice returns the total value of all the assets in the WLP/Vault
     * @dev the USD value is scaled in 1e30, not 1e18, so $1 = 1e30
     * @return aumAmountsUSD_ array with minimised and maximised AU<
     */
    function getAums() public view returns (uint256[] memory aumAmountsUSD_) {
        aumAmountsUSD_ = new uint256[](2);
        aumAmountsUSD_[0] = getAum(true /** use upper bound oracle price for assets */);
        aumAmountsUSD_[1] = getAum(false /** use lower bound oracle price for assets */);
    }

    /**
     * @notice returns the total amount of AUM of the vault
     * @dev take note that 1 USD is 1e30, this function returns the AUM in this format
     * @param _maximise bool indicating if the max price need to be used for the aum calculation
     * @return aumUSD_ the total aum (in USD) of all the whtielisted assets in the vault
     */
    function getAum(bool _maximise) public view returns (uint256 aumUSD_) {
        IVault _vault = vault;
        uint256 length_ = _vault.allWhitelistedTokensLength();
        uint256 aum_ = aumAddition;

        for (uint256 i = 0; i < length_; i++) {
            address token_ = _vault.allWhitelistedTokens(i);
            bool isWhitelisted_ = _vault.whitelistedTokens(token_);

            // if token is not whitelisted, don't count it to the AUM
            if (!isWhitelisted_) {
                continue;
            }

            // fetch price of the token
            uint256 price_ = _maximise ? _vault.getMaxPrice(token_) : _vault.getMinPrice(token_);
            // fetch how much realizd/registered pool amounts are in the vault
            uint256 poolAmount_ = _vault.poolAmounts(token_);
            // fetch how much decimals the whitelisted token has
            uint256 decimals_ = _vault.tokenDecimals(token_);

            aum_ += ((poolAmount_ * price_) / (10 ** decimals_));
        }

        uint256 aumD_ = aumDeduction;
        aumUSD_ = aumD_ > aum_ ? 0 : (aum_ - aumD_);
    }

    /*==================== Internal functions WINR/JB *====================*/

    /**
     * @notice internal function that calls the deposit function in the vault
     * @dev calling this function requires an approval by the _funding account
     * @param _fundingAccount address of the account sourcing the 
     * @param _account address that will receive the newly minted WLP tokens
     * @param _tokenDeposit address of the token being deposited into the vault
     * @param _amountDeposit amiunt of _tokenDeposit the caller is adding as liquiditty
     * @param _minUsdw minimum amount of USDW the caller wants their deposited tokens to be worth
     * @param _minWlp minimum amount of WLP the caller wants to receive
     * @return mintAmountWLP_ amount of WLP tokens minted 
     */
    function _addLiquidity(
        address _fundingAccount, 
        address _account, 
        address _tokenDeposit, 
        uint256 _amountDeposit, 
        uint256 _minUsdw, 
        uint256 _minWlp) private returns (uint256 mintAmountWLP_) {
        require(
            _amountDeposit > 0, 
            "WLPManager: invalid _amount"
        );
        // cache address to save on SLOADs
        address wlp_ = wlp;
        // calculate aum before buyUSDW
        uint256 aumInUsdw_ = getAumInUsdw(true /**  get AUM using upper bound prices */);
        uint256 wlpSupply_ = ERC20(wlp_).totalSupply();
        // transfer the tokens to the vault, from the user/source (_fundingAccount). note this requires an approval from the source address
        SafeTransferLib.safeTransferFrom(
            ERC20(_tokenDeposit), 
            _fundingAccount, 
            address(vault),
            _amountDeposit
        );
        // call the deposit function in the vault (external call)
        uint256 usdwAmount_ = vault.deposit(
            _tokenDeposit, // the token that is being deposited into the vault for WLP
            address(this) // the address that will receive the USDW tokens (minted by the vault)
        );
        // the vault has minted USDW to this contract (WLP Manager), the amount of USDW minted is equivalent to the value of the deposited tokens (in USD, scaled 1e18) now this WLP Manager contract has received usdw, 1e18 usdw is 1 USD 'debt'. If the caller has provided tokens worth $10k, then about 1e5 * 1e18 USDW will be minted. This ratio of value deposited vs amount of USDW minted will remain the same.
        
        require(
            usdwAmount_ >= _minUsdw, 
            "WLPManager: insufficient USDW output"
        );

        /**
         * TODO: Check if the withdrawal will not push the asset under the bufferamount!
         */

        /**
         * Initially depositing 1 USD will result in 1 WLP, however as the value of the WLP grows (so historically the WLP LPs are in profit), a 1 USD deposit will result in less WLP, this because new LPs do not have the right to 'cash in' on the WLP profits that where earned bedore the LP entered the vault. The calculation below determines how much WLP will be minted for the amount of USDW deposited.
         */
        mintAmountWLP_ = aumInUsdw_ == 0 ? usdwAmount_ : ((usdwAmount_ * wlpSupply_) / aumInUsdw_);
        
        require(
            mintAmountWLP_ >= _minWlp, 
            "WLPManager: insufficient WLP output"
        );

        // wlp is minted to the _account address, WLP is the 
        IMintable(wlp_).mint(_account, mintAmountWLP_);
        lastAddedAt[_account] = block.timestamp;
        emit AddLiquidity(
            _account, 
            _tokenDeposit, 
            _amountDeposit,
            aumInUsdw_, 
            wlpSupply_, 
            usdwAmount_, 
            mintAmountWLP_
        );
        return mintAmountWLP_;
    }

    /**
     * @notice internal function that withdraws assets from the vault
     * @dev burns WLP, burns usdw
     * @param _account the addresss that wants to redeem its WLP from
     * @param _tokenOut address of the token that the redeemer wants to receive for their wlp
     * @param _wlpAmount the amount of WLP that is being redeemed
     * @param _minOut the minimum amount of tokenOut the redeemer/remover wants to receive
     * @param _receiver address the redeemer wants to receive the tokenOut on
     * @return amountOutToken_ xxx
     */
    function _removeLiquidity(
        address _account, 
        address _tokenOut, 
        uint256 _wlpAmount, 
        uint256 _minOut, 
        address _receiver) private returns (uint256 amountOutToken_) {
        require(
            _wlpAmount > 0, 
            "WLPManager: invalid _wlpAmount"
        );
        require(
            (lastAddedAt[_account] + cooldownDuration) <= block.timestamp,
            "WLPManager: cooldown duration not yet passed"
        );

        // calculate how much the lower bound priced value is of all the assets in the WLP 
        uint256 aumInUsdw_ = getAumInUsdw(false);
        // cache wlp address to save on SLOAD
        address wlp_ = wlp;
        // fetch how much WLP tokens are minted/outstanding
        uint256 wlpSupply_ = ERC20(wlp_).totalSupply();
        uint256 usdwAmountToBurn_ = (_wlpAmount * aumInUsdw_) / wlpSupply_;
        // calculate how much USD debt there is in total
        uint256 usdwBalance_ = ERC20(usdw).balanceOf(address(this));
        // cache address to save on SLOAD
        address usdw_ = usdw;
        // todo: describe what happens here
        if (usdwAmountToBurn_ > usdwBalance_) {
            IUSDW(usdw_).mint(address(this), usdwAmountToBurn_ - usdwBalance_);
        }

        // burn the WLP token in the wallet of the LP remover, will fail if the _account doesn't have the WLP tokens
        IMintable(wlp_).burn(_account, _wlpAmount);
        // usdw is transferred to the vault (where it will be burned)
        ERC20(usdw_).transfer(address(vault), usdwAmountToBurn_);
        amountOutToken_ = vault.withdraw(_tokenOut, _receiver);
        require(
            amountOutToken_ >= _minOut, 
            "WLPManager: insufficient output"
        );
        emit RemoveLiquidity(
            _account, 
            _tokenOut, 
            _wlpAmount, 
            aumInUsdw_, 
            wlpSupply_, 
            usdwAmountToBurn_, 
            amountOutToken_
        );
        return amountOutToken_;
    }

    // todo note implement using this or remove it!
    function _checkIfZero(uint256 _amount) internal pure {
        require(
            _amount > 0,
            "WLPManager: value zero"
        );
    }

    function _validateHandler() private view {
        require(handlersEnabled, "WLPManager: handlers not enabled");
        require(isHandler[_msgSender()], "WLPManager: forbidden");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtils.sol";

interface IVault {
    /*==================================================== EVENTS GMX ===========================================================*/
    event BuyUSDW(
        address account, 
        address token, 
        uint256 tokenAmount, 
        uint256 usdwAmount, 
        uint256 feeBasisPoints
    );
    event SellUSDW(
        address account, 
        address token, 
        uint256 usdwAmount, 
        uint256 tokenAmount, 
        uint256 feeBasisPoints
    );
    event Swap(
        address account, 
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn, 
        uint256 indexed amountOut, 
        uint256 indexed amountOutAfterFees, 
        uint256 indexed feeBasisPoints
    );
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);
    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event DirectPoolDeposit(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseUsdwAmount(address token, uint256 amount);
    event DecreaseUsdwAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);

    /*================================================== Operational Functions GMX =================================================*/
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;
    function router() external view returns (address);
    function usdw() external view returns (address);
    function whitelistedTokenCount() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdwAmount(address _token) external view returns (uint256);
    function inManagerMode() external view returns (bool);
    function isManager(address _account) external view returns (bool);
    function tokenBalances(address _token) external view returns (uint256);
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setUsdwAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        bool _hasDynamicFees
    ) external;
    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _maxUsdwAmount,
        bool _isStable
    ) external;
    function setPriceFeed(address _priceFeed) external;
    function withdrawSwapFees(address _token) external returns (uint256);
    function directPoolDeposit(address _token) external;
    function deposit(address _tokenIn, address _receiver) external returns (uint256);
    function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function tokenToUsdMin(address _tokenToPrice, uint256 _tokenAmount) external view returns (uint256);
    function priceFeed() external view returns (address);
    function getFeeBasisPoints(
        address _token, 
        uint256 _usdwDelta, 
        uint256 _feeBasisPoints, 
        uint256 _taxBasisPoints, 
        bool _increment
    ) external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function usdwAmounts(address _token) external view returns (uint256);
    function maxUsdwAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    /*==================== Events WINR  *====================*/

    event PlayerPayout(
        address recipient,
        uint256 amountPayoutTotal
    );

    event WagerFeesCollected(
        address tokenAddress,
        uint256 usdValueFee,
        uint256 feeInTokenCharged
    );

    event PayinWLP(
        address tokenInAddress,
        uint256 amountPayin,
        uint256 usdValueProfit
    );

    event RebalancingWithdraw(
        address tokenWithdrawn,
        uint256 amountWithdrawn
    );

    event RebalancingDeposit(
        address tokenDeposit,
        uint256 amountDeposit
    );

    /*==================== Operational Functions WINR *====================*/
    function setVaultManagerAddress(address _vaultManagerAddress) external;
    function vaultManagerAddress() external view returns (address);
    function wagerFee() external view returns (uint256);
    function setWagerFee(uint256 _wagerFee) external;
    function wagerFeeReserves(address _token) external view returns(uint256);
    function withdrawWagerFees(address _token) external returns (uint256);
    function setFeeLessForPayout(bool _setting) external;
    function getReserve() external view returns (uint256);
    function getDollarValue(address _token) external view returns (uint256);
    function getWlpValue() external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToToken(address _token, uint256 _usdAmount, uint256 _price) external view returns(uint256);

    function payout(
        address[2] memory _tokens,
        address _escrowAddress,
        uint256 _escrowAmount,
        address _recipient,
        uint256 _totalAmount
    ) external;

    function payin(
        address _inputToken,
        address _escrowAddress,
        uint256 _escrowAmount
    ) external;

    function rebalanceWithdraw(
        address _tokenToRebalanceWith,
        uint256 _amountToRebalanceWith
    ) external;

    function rebalanceDeposit(
        address _tokenInDeposited,
        uint256 _amountDeposited
    ) external;
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/IAccessControl.sol";

pragma solidity >=0.6.0 <0.9.0;

interface IVaultAccessControlRegistry is IAccessControl {
    function timelockActivated() external view returns(bool);
    function governanceAddress() external view returns(address);
    function pauseProtocol() external;
    function unpauseProtocol() external;
    function isCallerGovernance(address _account) external view returns (bool);
    function isCallerManager(address _account) external view returns (bool);
    function isCallerEmergency(address _account) external view returns (bool);
    function isProtocolPaused() external view returns (bool);

    /*==================== Events WINR  *====================*/

    event DeadmanSwitchFlipped();
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVaultUtils {
    function getBuyUsdwFeeBasisPoints(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getSellUsdwFeeBasisPoints(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdwAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdwDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVault.sol";

interface IWLPManager {
    function wlp() external view returns (address);
    function usdw() external view returns (address);
    function vault() external view returns (IVault);
    function cooldownDuration() external returns (uint256);
    function getAumInUsdw(bool maximise) external view returns (uint256);
    function lastAddedAt(address _account) external returns (uint256);
    function addLiquidity(address _token, uint256 _amount, uint256 _minUsdw, uint256 _minWlp) external returns (uint256);
    function addLiquidityForAccount(address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minUsdw, uint256 _minWlp) external returns (uint256);
    function removeLiquidity(address _tokenOut, uint256 _wlpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function removeLiquidityForAccount(address _account, address _tokenOut, uint256 _wlpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function setCooldownDuration(uint256 _cooldownDuration) external;
    function getAum(bool _maximise) external view returns(uint256);
    function getPrice(bool _maximise) external view returns(uint256);

    /*==================== Events *====================*/

    event AddLiquidity(
        address account,
        address token,
        uint256 amount,
        uint256 aumInUsdw,
        uint256 wlpSupply,
        uint256 usdwAmount,
        uint256 mintAmount
    );

    event RemoveLiquidity(
        address account,
        address token,
        uint256 wlpAmount,
        uint256 aumInUsdw,
        uint256 wlpSupply,
        uint256 usdwAmount,
        uint256 amountOut
    );

    event HandlerSet(
        address handlerAddress,
        bool isSet
    );


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUSDW {
    function addVault(address _vault) external;
    function removeVault(address _vault) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}