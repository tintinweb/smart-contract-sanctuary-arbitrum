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

pragma solidity 0.8.17;

import "solmate/src/utils/ReentrancyGuard.sol";
import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./AccessControlBase.sol";
import "../interfaces/core/IVault.sol";
import "../interfaces/core/IFeeCollector.sol";
import "../interfaces/core/IReader.sol";

/**
 * This contract collects wager and swap fees from the vault - for each whitelisted token in the vault.
 * After the fees are collected (and reside in this contract), the contract transfer the collected fees to 3 entities, the amount of the collected fees these enities receive is based on the configured distribution ratio (in distributionConfig).
 * The swap+wager fee distribution function can only be called once per rewardInterval (configurable).
 */
contract FeeCollector is Pausable, ReentrancyGuard, AccessControlBase, IFeeCollector {

    /*==================== Constants *====================*/
    uint256 private constant MAX_INTERVAL = 14 days;
    uint256 private constant BASIS_POINTS_DIVISOR = 1e4;

    /*==================== State Variabes *====================*/

    IVault public vault;

    // *** Destination addresses for the farmed fees *** //
    // note: the 4 addresses below need to be able to receive ERC20 tokens

    // the destination address for the collected fees attributed to WLP holders 
    address public wlpClaimContract;

    // the destination address for the collected fees attributed  to WINR stakers
    address public winrStakingContract;

    // the destination address for the collected fees attributed to core development
    address public coreDevelopment;

    // address of the contract that does the 'buyback and burn'
    address public buybackContract;

    // the fee distribution reward interval
    uint256 public rewardInterval = 7 days;

    // timestamp of the last time fees where distributed
    uint256 public lastDistribution;

    // array with addresses of all tokens fees are collected in
    address[] public allWhitelistedTokens;

    DistributionRation public distributionConfig;

    struct DistributionRation {
        uint64 ratioWLP;
        uint64 ratioStaking;
        uint64 buybackContract;
        uint64 ratioCore;
    }

    constructor(
        address _vaultRegistry,
        address _vault,
        address _wlpClaimContract,
        address _winrStakingContract,
        address _buyburnContract,
        address _coreDevelopment,
        address _timelock
    ) AccessControlBase(_vaultRegistry, _timelock) Pausable() {
        vault = IVault(_vault);
        wlpClaimContract = _wlpClaimContract;
        winrStakingContract = _winrStakingContract;
        coreDevelopment = _coreDevelopment;
        buybackContract = _buyburnContract;
        lastDistribution = block.timestamp;
    }

    /*==================== Configuration functions (onlyGovernance) *====================*/

    function setClaimContract(
        address _wlpClaimContract
    ) external onlyGovernance {
        _checkNotNull(_wlpClaimContract);
        wlpClaimContract = _wlpClaimContract;
    }

    function setBuyBackContract(
        address _buybackContract
    ) external onlyGovernance {
        _checkNotNull(_buybackContract);
        buybackContract = _buybackContract;
    }

    function setStakingContract(
        address _winrStakingContract
    ) external onlyGovernance {
        _checkNotNull(_winrStakingContract);
        winrStakingContract = _winrStakingContract;
    }

    function setCoreDevelopment(
        address _coreDevelopment
    ) external onlyGovernance {
        _checkNotNull(_coreDevelopment);
        coreDevelopment = _coreDevelopment;
    }

    function setRewardInterval(
        uint256 _timeInterval
    ) external onlyGovernance {
        require(_timeInterval <= MAX_INTERVAL, "FeeCollector: invalid interval");
        rewardInterval = _timeInterval;
    }

    /**
     * @notice function that configures the collected fee distribution
     * @dev the ratios together should equal 1e4 (100%)
     * @param _ratioWLP the ratio of the totalRewards going to WLP holders
     * @param _ratioStaking the ratio of the totalRewards going to WINR stakers
     * @param _ratioCore  the ratio of the totalRewars going to core dev
     */
    function setDistribution(
        uint64 _ratioWLP,
        uint64 _ratioStaking,
        uint64 _buybackRatio,
        uint64 _ratioCore
    ) external onlyGovernance {
        // together all the ratios need to be 1e4
        require(
            (_ratioWLP + _ratioStaking + _ratioCore + _buybackRatio) == 1e4,
            "FeeCollector: Ratios together don't sum to 1e4"
        );

        distributionConfig = DistributionRation(
            _ratioWLP,
            _ratioStaking,
            _buybackRatio,
            _ratioCore
        );

        emit DistributionSet(
            _ratioWLP,
            _ratioStaking,
            _buybackRatio,
            _ratioCore
        );
    }

    function deleteWhitelistTokenList() external onlyManager {
        delete allWhitelistedTokens;
    }

    function addTokenToWhitelistList(
        address _tokenToAdd
    ) external onlyManager {
        allWhitelistedTokens.push(_tokenToAdd);
    }

    // note unprotected (but harmless IMO) consider: adding onlyManager
    function syncWhitelistedTokens() public onlyManager {
        delete allWhitelistedTokens;

        uint256 count_ = vault.allWhitelistedTokensLength();

        for (uint256 i = 0; i < count_; i++) {
            address token_ = vault.allWhitelistedTokens(i);
            allWhitelistedTokens.push(token_);
        }
        emit SyncTokens();
    }


    /*==================== Operational functions WINR/JB *====================*/

    /**
     * @notice function that claims/farms the wager+swap fees in vault, and distributes it to wlp holders, stakers and core dev
     * @dev this function can be only called by governance - is used for when something is wrong
     */
    function distributeFeesAllGovernance() external onlyManager {

        // harvest wager fees from vault
        _collectWagerFeesVault();

        // harvest swap fees from vault
        _collectSwapFeesVault();

        // all the swap and wager fees from the vault now sit in this contract

        address[] memory wlTokens_ = allWhitelistedTokens;

        // iterate over all te tokens that now sit in this contract
        for (uint256 i = 0; i < wlTokens_.length; i++) {
            _distribute(wlTokens_[i]);
        }
        lastDistribution = block.timestamp;
    }

    function syncLastDistribution() external onlyManager {
        lastDistribution = block.timestamp;
    }

    /*==================== Public callable operational functions *====================*/    

    /**
     * @notice function that claims/farms the wager+swap fees in vault, and distributes it to wlp holders, stakers and core dev
     * @dev function can only be called once per interval period
     * note KK consider making this a protected function - although i don't see any attack vector 
     */
    function distributeFeesAll() external nonReentrant {
        // collected fees can only be distributed once every rewardIntervval
        require(
            lastDistribution + rewardInterval <= block.timestamp,
            "Fees can only be distributed once per rewardInterval"
        );

        // harvest wager fees from vault
        _collectWagerFeesVault();

        // harvest swap fees from vault
        _collectSwapFeesVault();

        // all the swap and wager fees from the vault now sit in this contract

        address[] memory wlTokens_ = allWhitelistedTokens;

        // iterate over all te tokens that now sit in this contract
        for (uint256 i = 0; i < wlTokens_.length; i++) {
            _distribute(wlTokens_[i]);
        }
        lastDistribution = block.timestamp;
    }

    /**
     * 
     * @param _tokenToCollect xxx
     */
    function farmWagerFeesVault(address _tokenToCollect) external onlyManager returns(uint256 feesFarmed_) {
        feesFarmed_ = vault.withdrawWagerFees(_tokenToCollect);
        // todo emit event
    }

    /**
     * 
     * @param _tokenToCollect xxx
     */
    function farmSwapFeesVault(address _tokenToCollect) external onlyManager returns(uint256 feesFarmed_) {
        feesFarmed_ = vault.withdrawSwapFees(_tokenToCollect);
        // todo emit event
    }

    /*==================== View functions *====================*/

    /**
     * 
     * @param _amountToDistribute xxx
     * @param _ratio xxx
     */
    function calculateDistribution(
        uint256 _amountToDistribute,
        uint64 _ratio
    ) public pure returns(uint256 amount_) {
        amount_ = ((_amountToDistribute * _ratio) / BASIS_POINTS_DIVISOR);
    }

    /*==================== Emergency intervention functions (onlyEmergency or onlyTimelockGovernance) *====================*/
    
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
        SafeTransferLib.safeTransfer(ERC20(_tokenAddress), _recipient, _amount);
        // todo emit event
    }

    /*==================== Internal functions *====================*/

    function _distribute(address _token) internal {
            // fetch how much there is to distribute
            uint256 balance_ = ERC20(_token).balanceOf(address(this));

            // if the amount of token to distributed is less than 100 wei (so this is extremely little, no distribution is done, since it doesn't make sense gas-wise) - also to prevent distributing 0 wei or other weird case
            if (balance_ < 100) {
                emit NothingToDistribute(_token);
                return;
            } 

            // calculate each portion
            (uint256 amountWLP_, uint256 amountStaking_, uint256 amountCore_, uint256 amountBuyBack_) = _returnAmountsToRecipients(balance_);
            
            // transfer collected fees to wlp holder claim contract
            SafeTransferLib.safeTransfer(ERC20(_token), wlpClaimContract, amountWLP_);

            // transfer collected fees to winr staking contract
            SafeTransferLib.safeTransfer(ERC20(_token), winrStakingContract, amountStaking_);

            // transfer collected fees to core development wallet
            SafeTransferLib.safeTransfer(ERC20(_token), coreDevelopment, amountCore_);

            // transfer collected fees to the buyback contract
            SafeTransferLib.safeTransfer(ERC20(_token), buybackContract, amountBuyBack_);

            emit DistributionComplete(
                _token,
                amountWLP_,
                amountStaking_,
                amountBuyBack_,
                amountCore_
            );
    }

    function _returnAmountsToRecipients(uint256 _amount) internal view returns(
        uint256 amountWLP_, 
        uint256 amountStaking_, 
        uint256 amountCore_, 
        uint256 amountBuyBack_) {
        amountWLP_ = calculateDistribution(_amount, distributionConfig.ratioWLP);
        amountStaking_ = calculateDistribution(_amount, distributionConfig.ratioStaking);
        amountCore_ = calculateDistribution(_amount, distributionConfig.buybackContract);
        amountBuyBack_ = calculateDistribution(_amount, distributionConfig.ratioCore);
        return(amountWLP_, amountStaking_, amountCore_, amountBuyBack_);
    }

    function _collectWagerFeesVault() internal {
        address[] memory wlTokens_ = allWhitelistedTokens;

        for (uint256 i = 0; i < wlTokens_.length; i++) {
            uint256 collected_ = vault.withdrawWagerFees(wlTokens_[i]);
            emit CollectedWagerFees(
                wlTokens_[i],
                collected_
            );
        }
    }

    function _collectSwapFeesVault() internal {
        address[] memory wlTokens_ = allWhitelistedTokens;

        for (uint256 i = 0; i < wlTokens_.length; i++) {
            uint256 collected_ = vault.withdrawSwapFees(wlTokens_[i]);
            emit CollectedSwapFees(
                wlTokens_[i],
                collected_
            );
        }
    }

    function _checkNotNull(address _setAddress) internal pure {
        require(
            _setAddress != address(0x0),
            "FeeCollector: Null not allowed"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IFeeCollector {

    /*==================== Public Functions *====================*/
    
    function calculateDistribution(uint256 _amountToDistribute, uint64 _ratio) external pure returns(uint256 amount_);
    function distributeFeesAllGovernance() external;
    function distributeFeesAll() external;
    function syncLastDistribution() external;
    function syncWhitelistedTokens() external;

    /*==================== Events *====================*/

    event CollectedWagerFees(
        address tokenAddress,
        uint256 amountCollected
    );

    event CollectedSwapFees(
        address tokenAddress,
        uint256 amountCollected
    );

    event NothingToDistribute(
        address token
    );

    event DistributionComplete(
        address token,
        uint256 toWLP,
        uint256 toStakers,
        uint256 toBuyBack,
        uint256 toCore
    );

    event DistributionSet(
        uint64 ratioWLP,
        uint64 ratioStaking,
        uint64 buybackRatio,
        uint64 ratioCore
    );

    event SyncTokens();
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IReader {
    // todo adding more interface functions if needed
    function getFees(address _vault, address[] memory _tokens) external view returns (uint256[] memory);
    function getWagerFees(address _vault, address[] memory _tokens) external view returns (uint256[] memory);
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