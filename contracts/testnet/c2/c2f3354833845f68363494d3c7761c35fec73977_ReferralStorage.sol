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

    modifier protocolNotPaused() {
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

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtils.sol";

interface IVault {
    /*==================== Events *====================*/
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
    event DirectPoolDeposit(address token, uint256 amount);
    error TokenBufferViolation(address tokenAddress);
    error PriceZero();

    event PayinWLP(
        // address of the token sent into the vault 
        address tokenInAddress,
        // amount payed in (was in escrow)
        uint256 amountPayin
    );

    event PlayerPayout(
        // address the player receiving the tokens (do we need this? i guess it does not matter to who we send tokens for profit/loss calculations?)
        address recipient,
        // address of the token paid to the player
        address tokenOut,
        // net amount sent to the player (this is NOT the net loss, since it includes the payed in tokens, excludes wagerFee and swapFee!)
        uint256 amountPayoutTotal
    );

    event AmountOutNull();

    event WithdrawAllFees(
        address tokenCollected,
        uint256 swapFeesCollected,
        uint256 wagerFeesCollected,
        uint256 referralFeesCollected
    );

    event RebalancingWithdraw(
        address tokenWithdrawn,
        uint256 amountWithdrawn
    );

    event RebalancingDeposit(
        address tokenDeposit,
        uint256 amountDeposit
    );

    event WagerFeeChanged(
        uint256 newWagerFee
    );

    /*==================== Operational Functions *====================*/
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;
    function router() external view returns (address);
    function usdw() external view returns (address);
    function feeCollector() external returns(address);
    function hasDynamicFees() external view returns (bool);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdwAmount(address _token) external view returns (uint256);
    function inManagerMode() external view returns (bool);
    function isManager(address _account) external view returns (bool);
    function tokenBalances(address _token) external view returns (uint256);
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager, bool _isWLPManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setUsdwAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _minimumBurnMintFee,
        bool _hasDynamicFees
    ) external;
    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _maxUsdwAmount,
        bool _isStable
    ) external;
    function setPriceFeedRouter(address _priceFeed) external;
    function withdrawAllFees(address _token) external returns (uint256,uint256,uint256);
    function directPoolDeposit(address _token) external;
    function deposit(address _tokenIn, address _receiver) external returns (uint256);
    function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function tokenToUsdMin(address _tokenToPrice, uint256 _tokenAmount) external view returns (uint256);
    function priceOracleRouter() external view returns (address);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function minimumBurnMintFee() external view returns (uint256);
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function swapFeeReserves(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function usdwAmounts(address _token) external view returns (uint256);
    function maxUsdwAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);
    function setVaultManagerAddress(address _vaultManagerAddress) external;
    function vaultManagerAddress() external view returns (address);
    function wagerFeeBasisPoints() external view returns (uint256);
    function setWagerFee(uint256 _wagerFee) external;
    function wagerFeeReserves(address _token) external view returns(uint256);
    function referralReserves(address _token) external view returns(uint256);
    function setFeeLessForPayout(bool _setting) external;
    function getReserve() external view returns (uint256);
    function getDollarValue(address _token) external view returns (uint256);
    function getWlpValue() external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToToken(address _token, uint256 _usdAmount, uint256 _price) external view returns(uint256);
    function returnTotalInAndOut(address token_) external view returns(uint256 totalOutAllTime_, uint256 totalInAllTime_);

    function adjustForDecimals(
        uint256 _amount, 
        address _tokenDiv, 
        address _tokenMul) external view returns (uint256 scaledAmount_);

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

    function setAsideReferral(
        address _token,
        uint256 _amount
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
    function changeGovernanceAddress(address _governanceAddress) external;

    /*==================== Events WINR  *====================*/

    event DeadmanSwitchFlipped();
    event GovernanceChange(
        address newGovernanceAddress
    );
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
    function getPriceWlp(bool _maximise) external view returns(uint256);
    function getPriceWLPInUsdw(bool _maximise) external view returns(uint256);

    function maxPercentageOfWagerFee() external view returns(uint256);
    function addLiquidityFeeCollector(
        address _token, 
        uint256 _amount, 
        uint256 _minUsdw, 
        uint256 _minWlp) external returns (uint256 wlpAmount_);


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

    event PrivateModeSet(
        bool inPrivateMode
    );

    event HandlerEnabling(
        bool setting
    );

    event HandlerSet(
        address handlerAddress,
        bool isActive
    );

    event CoolDownDurationSet(
        uint256 cooldownDuration
    );

    event AumAdjustmentSet(
        uint256 aumAddition,
        uint256 aumDeduction
    );

    event MaxPercentageOfWagerFeeSet(
        uint256 maxPercentageOfWagerFee
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IReferralStorage {
    struct Tier {
        uint256 totalRebate; // e.g. 2400 for 24%
        uint256 discountShare; // 5000 for 50%/50%, 7000 for 30% rebates/70% discount
    }

    event SetWithdrawInterval(uint256 timeInterval);
    event SetHandler(address handler, bool isActive);
    event SetPlayerReferralCode(address account, bytes32 code);
    event SetTier(uint256 tierId, uint256 totalRebate, uint256 discountShare);
    event SetReferrerTier(address referrer, uint256 tierId);
    event SetReferrerDiscountShare(address referrer, uint256 discountShare);
    event RegisterCode(address account, bytes32 code);
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    event GovSetCodeOwner(bytes32 code, address newAccount);
    event Claim(address referrer, uint256 wlpAmount);
    event Reward(address referrer, address player, address token, uint256 amount);
    event VaultUpdated(address vault);
    event WLPManagerUpdated(address wlpManager);
    event SyncTokens();

    event TokenTransferredByTimelock(
        address token,
        address recipient,
        uint256 amount
    );
    event DeleteAllWhitelistedTokens();
    event TokenAddedToWhitelist(address addedTokenAddress);

    event AddReferrerToBlacklist(
        address referrer,
        bool setting
    );

    event ReferrerBlacklisted(
        address referrer
    );

    function codeOwners(bytes32 _code) external view returns (address);
    function playerReferralCodes(address _account) external view returns (bytes32);
    function referrerDiscountShares(address _account) external view returns (uint256);
    function referrerTiers(address _account) external view returns (uint256);
    function getPlayerReferralInfo(address _account) external view returns (bytes32, address);
    function setPlayerReferralCode(address _account, bytes32 _code) external;
    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external;
    function setReferrerTier(address _referrer, uint256 _tierId) external;
    function govSetCodeOwner(bytes32 _code, address _newAccount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../core/AccessControlBase.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/core/IVault.sol";
import "../interfaces/core/IWLPManager.sol";
import "../interfaces/referrals/IReferralStorage.sol";

contract ReferralStorage is ReentrancyGuard, Pausable, AccessControlBase, IReferralStorage {

    /*==================== Constants *====================*/
    uint256 private constant MAX_INTERVAL = 7 days;
    uint256 public constant BASIS_POINTS = 10000;

    IVault public vault; // vault contract address
    IWLPManager public wlpManager; // vault contract address
    IERC20 public wlp;

    uint256 public withdrawInterval = 1 days; // the reward withdraw interval
    mapping (address => uint256) public lastWithdrawTime; // to override default value in tier

    mapping (address => mapping (address => uint256)) public withdrawn; // to override default value in tier
    mapping (address => mapping (address => uint256)) public rewards; // to override default value in tier

    // array with addresses of all tokens fees are collected in
    address[] public allWhitelistedTokens;

    mapping(address => bool) public referrerOnBlacklist;

    // GMX STROAGE
    mapping (address => uint256) public override referrerDiscountShares; // to override default value in tier
    mapping (address => uint256) public override referrerTiers; // link between user <> tier
    mapping (uint256 => Tier) public tiers;
    mapping (bytes32 => address) public override codeOwners;
    mapping (address => bytes32) public override playerReferralCodes;
    
    constructor(
        address _vaultRegistry,
        address _vault,
        address _wlpManager,
        address _timelock
    ) AccessControlBase(_vaultRegistry, _timelock) Pausable() {
        vault = IVault(_vault);
        wlpManager = IWLPManager(_wlpManager);
        wlp = IERC20(wlpManager.wlp());
    }

    /********* GMX Functions *********/

    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external override onlyGovernance {
        require(_totalRebate <= BASIS_POINTS, "ReferralStorage: invalid totalRebate");

        // note @berkant do we want this? or is this an opitions?
        require(_totalRebate != 0, "ReferralStorage: totalRebate null");

        require(_discountShare <= BASIS_POINTS, "ReferralStorage: invalid discountShare");

        Tier memory tier = tiers[_tierId];
        tier.totalRebate = _totalRebate;
        tier.discountShare = _discountShare;
        tiers[_tierId] = tier;
        emit SetTier(_tierId, _totalRebate, _discountShare);
    }

    function setReferrerTier(address _referrer, uint256 _tierId) external override onlyGovernance {
        referrerTiers[_referrer] = _tierId;
        emit SetReferrerTier(_referrer, _tierId);
    }

    function setReferrerDiscountShare(uint256 _discountShare) external {
        require(_discountShare <= BASIS_POINTS, "ReferralStorage: invalid discountShare");

        referrerDiscountShares[msg.sender] = _discountShare;
        emit SetReferrerDiscountShare(msg.sender, _discountShare);
    }

    function setPlayerReferralCode(address _account, bytes32 _code) external override onlyManager {
        _setPlayerReferralCode(_account, _code);
    }

    function setPlayerReferralCodeByUser(bytes32 _code) external {
        _setPlayerReferralCode(msg.sender, _code);
    }

    function _setPlayerReferralCode(address _account, bytes32 _code) private {
        playerReferralCodes[_account] = _code;
        emit SetPlayerReferralCode(_account, _code);
    }

    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");
        require(codeOwners[_code] == address(0), "ReferralStorage: code already exists");

        codeOwners[_code] = msg.sender;
        emit RegisterCode(msg.sender, _code);
    }

    function setCodeOwner(bytes32 _code, address _newAccount) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        address account = codeOwners[_code];
        require(msg.sender == account, "ReferralStorage: forbidden");

        codeOwners[_code] = _newAccount;
        emit SetCodeOwner(msg.sender, _newAccount, _code);
    }

    function govSetCodeOwner(bytes32 _code, address _newAccount) external override onlyGovernance {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        codeOwners[_code] = _newAccount;
        emit GovSetCodeOwner(_code, _newAccount);
    }

    // function getPlayerReferralInfo(address _account) public override view returns (bytes32, address) {
    //     bytes32 code = playerReferralCodes[_account];
    //     address referrer;
    //     if (code != bytes32(0)) {
    //         referrer = codeOwners[code];
    //     }
    //     return (code, referrer);
    // }


    /********* Distrubiton Functions *********/ 
    
    /**
     * @notice configuration function for 
     * @dev the configured withdraw interval cannot exceed the MAX_INTERVAL
     * @param _timeInterval uint time interval for withdraw
     */
    function setWithdrawInterval(
        uint256 _timeInterval
    ) external onlyGovernance {
        require(_timeInterval <= MAX_INTERVAL, "ReferralStorage: invalid interval");
        withdrawInterval = _timeInterval;
        emit SetWithdrawInterval(_timeInterval);
    }

    /**
     * @notice function that changes vault address
     * note: todo change onlyGovernance to onlyTimeLockGovernance?
     */
    function setVault(address vault_) public onlyGovernance {
        _checkNotNull(vault_);
        vault = IVault(vault_);
        emit VaultUpdated(vault_);
    }

    /**
     * @notice function that changes vault address
     * note: todo change onlyGovernance to onlyTimeLockGovernance?
     */
    function setWlpManager(address wlpManager_) public onlyGovernance {
        _checkNotNull(wlpManager_);
        wlpManager = IWLPManager(wlpManager_);
        wlp = IERC20(wlpManager.wlp());
        emit WLPManagerUpdated(address(wlpManager_));
    }

    /**
     * @notice manually adds a tokenaddress to the vault
     * @param _tokenToAdd address to manually add to the allWhitelistedTokensFeeCollector array
     */
    function addTokenToWhitelistList(
        address _tokenToAdd
    ) external onlyManager {
        allWhitelistedTokens.push(_tokenToAdd);
        emit TokenAddedToWhitelist(_tokenToAdd);
    }

    /**
     * @notice deletes entire whitelist array
     * @dev this function should be used before syncWhitelistedTokens is called!
     */
    function deleteWhitelistTokenList() external onlyManager {
        delete allWhitelistedTokens;
        emit DeleteAllWhitelistedTokens();
    }


    function addReferrerToBlacklist(address _referrer, bool _setting) external onlyGovernance {
        referrerOnBlacklist[_referrer] = _setting;
        emit AddReferrerToBlacklist(_referrer, _setting);
    }

    function _referrerOnBlacklist(address _referrer) internal view returns (bool) {
        return referrerOnBlacklist[_referrer];
    }

    /**
     * @notice internal function that checks if an address is not 0x0
     */
    function _checkNotNull(address _setAddress) internal pure {
        require(
            _setAddress != address(0x0),
            "FeeCollector: Null not allowed"
        );
    }

    /**
     * @notice calculates what is a percentage portion of a certain input
     * @param _amountToDistribute amount to charge the fee over
     * @param _basisPointsPercentage basis point percentage scaled 1e4
     * @return amount_ amount to distribute
     */
    function calculateRebate(
        uint256 _amountToDistribute,
        uint256 _basisPointsPercentage
    ) public pure returns(uint256 amount_) {
        amount_ = ((_amountToDistribute * _basisPointsPercentage) / BASIS_POINTS);
    }

    /**
     * @notice function that syncs the whitelisted tokens with the vault
     */
    function syncWhitelistedTokens() public onlyManager {
        delete allWhitelistedTokens;
        uint256 count_ = vault.allWhitelistedTokensLength();
        for (uint256 i = 0; i < count_; i++) {
            address token_ = vault.allWhitelistedTokens(i);
            allWhitelistedTokens.push(token_);
        }
        emit SyncTokens();
    }


    function getPlayerReferralInfo(address _account) public override view returns (bytes32, address) {
        bytes32 code = playerReferralCodes[_account];
        address referrer;
        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }
        if(_referrerOnBlacklist(referrer)) {
            // if the referrer is on the blacklist, set it to 0x0
            referrer = address(0);
        }
        return (code, referrer);
    }

    /**
     * @notice function that checks if a player has a referrer
     * @param _player address of the player
     * @return true if the player has a referrer
     */
    function isPlayerReferred(address _player) public view returns (bool) {
        (,address referrer_) = getPlayerReferralInfo(_player);
        return referrer_ != address(0);
    }

    /**
     * @notice function that returns the referrer of a player
     * @param _player address of the player
     * @return address of the referrer
     */
    function returnPlayerRefferalAddress(address _player) public view returns (address) {
        (,address referrer_) = getPlayerReferralInfo(_player);
        return referrer_;
    }

    /**
     * @notice function that sets the reward for a referrer
     * @param _player address of the player
     * @param _token address of the token
     * @param _amount amount of the token to reward the referrer with (max)
     */
    function setReward(
        address _player, 
        address _token, 
        uint256 _amount) external onlyManager {
        address referrer_ = returnPlayerRefferalAddress(_player);

        if (referrer_ != address(0)) { // the player has a referrer
            // get the referrers rank
            // Tier memory tier_ = getReferrerTier(referrer_);

            // calculate the rebate for the referrer tier
            uint256 amountRebate_ = calculateRebate(_amount, tiers[referrerTiers[referrer_]].totalRebate);
            // nothing to rebate, return early but emit event
            if(amountRebate_ == 0) {
                emit Reward(referrer_, _player, _token, 0);
                return;
            }

            // add the rebate to the rewards mapping of the referrer
            rewards[referrer_][_token] += amountRebate_;

            // add the rebate to the referral reserves of the vault (to keep it aside from the wagerFeeReserves)
            IVault(vault).setAsideReferral(_token, amountRebate_);

            emit Reward(referrer_, _player, _token, _amount);
        } else {
            // note this would be waste to emit, so its better that if a player is not referred, this contract isn't called!
            emit Reward(address(0x0), _player, _token, 0);
        }
    }

    // note added whenNotPaused modifier
    function claim() public whenNotPaused nonReentrant {
        address referrer_ = _msgSender();

        if(_referrerOnBlacklist(referrer_)) {
            emit ReferrerBlacklisted(referrer_);
            // if the referrer is on the blacklist, return early
            return;
        }

        // collected fees can only be distributed once every rewardIntervval
        require(
            lastWithdrawTime[referrer_] + withdrawInterval <= block.timestamp,
            "Rewards can only be withdrawn once per withdrawInterval"
        );

        // move this one up (check, effects, interactions pattern)
        lastWithdrawTime[referrer_] = block.timestamp;

        uint256 totalWlpAmount_;
        // all the swap and wager fees from the vault now sit in this contract
        address[] memory wlTokens_ = allWhitelistedTokens;

        // iterate over all te tokens that now sit in this contract
        for (uint256 i = 0; i < wlTokens_.length; i++) {
            address token_ = wlTokens_[i];

            // calculate the amount of tokens that can be distributed to the referrer (in the form of WLP)
            uint256 amount_ = rewards[referrer_][token_] - withdrawn[referrer_][token_];

            // update the amount of tokens that have been distributed to the referrer (before doing an external call)
            withdrawn[referrer_][token_] = rewards[referrer_][token_];

            if (amount_ > 0) {
                totalWlpAmount_ += _convertReferralTokensToWLP(wlTokens_[i], amount_);
                // _convertReferralTokensToWLP is an external call, so according to check-effects-interactions pattern, we should update the state before the call
                // withdrawn[referrer_][token_] = rewards[referrer_][token_];
            }
        }

        // note: i think we can just return here, so that the function doesnt revert if there is nothing to claim
        // require(totalWlpAmount_ > 0, "ReferralStorage: No claimable");
        if(totalWlpAmount_ == 0) {
            // nothing is claimed but we still need to update the lastWithdrawTime
            emit Claim(referrer_, 0);
            return;
        }
        
        wlp.transfer(referrer_, totalWlpAmount_);

        // note we can check if the transfer was successful

        emit Claim(referrer_, totalWlpAmount_);
    }
    
    /**
     * @notice internal function that deposits tokens and returns amount of wlp
     * @param _token token address of amount which wants to deposit
     * @param _amount amount of the token collected (FeeCollector contract)
     * @return wlpAmount_ amount of the token minted to this by depositing
     */
    function _convertReferralTokensToWLP(address _token, uint256 _amount) internal returns (
        uint256 wlpAmount_
    ) {

        uint256 currentWLPBalance_ = wlp.balanceOf(address(this));

        // approve WLPManager to spend the tokens
        IERC20(_token).approve(address(wlpManager), _amount);
        
        // WLPManager returns amount of WLP minted
        wlpAmount_ = wlpManager.addLiquidity(_token, _amount, 0, 0);

        // wlpAmount_ = wlp_.balanceOf(address(this)) - currentWLPBalance_;
        // note: if we want to check if the mint was successful and the WLP actually sits in this contract, we should do it like this:
        require(
            wlp.balanceOf(address(this)) == currentWLPBalance_ + wlpAmount_, 
            "ReferralStorage: WLP mint failed"
        );
    }

    function getReferrerTier(address _referrer) public view returns (Tier memory tier_) {
        // if the referrer is not registered as a referrer, it should return an error
        if(playerReferralCodes[_referrer] == bytes32(0)) {
            revert("ReferralStorage: Referrer not registered");
        }
        tier_ = tiers[referrerTiers[_referrer]];
    }

    /**
     * @notice governance function to rescue or correct any tokens that end up in this contract by accident
     * @dev this is a timelocked funciton 
     * @param _tokenAddress address of the token to be transferred out
     * @param _amount amount of the token to be transferred out
     * @param _recipient address of the receiver of the token
     */
    function removeTokenByGoverance(
        address _tokenAddress,
        uint256 _amount,
        address _recipient
    ) external onlyTimelockGovernance {
        IERC20(_tokenAddress).transfer(_recipient, _amount);
        emit TokenTransferredByTimelock(
            _tokenAddress,
            _recipient,
            _amount
        );
    }

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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