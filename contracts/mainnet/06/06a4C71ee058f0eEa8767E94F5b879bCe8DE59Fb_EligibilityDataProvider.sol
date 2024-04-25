// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ICollateralChecker } from "../interfaces/IIncentive/ICollateralChecker.sol";
import { IPriceProvider } from "../interfaces/IIncentive/IPriceProvider.sol";
import { IChefIncentivesController, IEDPUserDefinedTypes, IEligibilityDataProvider } from "../interfaces/IIncentive/IEligibilityDataProvider.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Eligible Deposit Provider
/// @author 0xKMG
/// based on Radiant's EligibilityDataProvider
contract EligibilityDataProvider is IEligibilityDataProvider, IEDPUserDefinedTypes, OwnableUpgradeable {
    /********************** Common Info ***********************/
    /// @notice RATIO BASE equal to 100%
    uint256 public constant RATIO_DIVISOR = 10000;

    /// @notice Initial required ratio of TVL to get reward; in bips
    uint256 public constant INITIAL_REQUIRED_DEPOSIT_RATIO = 500;

    /// @notice Initial ratio of the required price to still allow without disqualification; in bips
    uint256 public constant INITIAL_PRICE_TOLERANCE_RATIO = 9000;

    /// @notice Minimum required ratio of TVL to get reward; in bips
    uint256 public constant MIN_PRICE_TOLERANCE_RATIO = 8000;

    /// @notice Address of collateralChecker (to be deployed)
    ICollateralChecker public collateralChecker;
    /// @notice Address of CIC
    IChefIncentivesController public chef;

    /// @notice APUFF + LP price provider
    IPriceProvider public priceProvider;

    /// @notice Required ratio of TVL to get reward; in bips
    uint256 public requiredDepositRatio;

    /// @notice Ratio of the required price to still allow without disqualification; in bips
    uint256 public priceToleranceRatio;

    /// @notice veToken
    address public veToken;

    /********************** Eligible info ***********************/

    /// @notice Last eligible status of the user
    mapping(address => bool) public lastEligibleStatus;

    /// @notice Disqualified time of the user
    mapping(address => uint256) public disqualifiedTime;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param _collateralChecker Address of lending pool.
     * @param _priceProvider PriceProvider address.
     */
    function initialize(ICollateralChecker _collateralChecker, IPriceProvider _priceProvider) public initializer {
        if (address(_collateralChecker) == address(0)) revert AddressZero();
        if (address(_priceProvider) == address(0)) revert AddressZero();

        collateralChecker = _collateralChecker;
        priceProvider = _priceProvider;

        requiredDepositRatio = INITIAL_REQUIRED_DEPOSIT_RATIO;
        priceToleranceRatio = INITIAL_PRICE_TOLERANCE_RATIO;
        __Ownable_init(msg.sender);
    }

    /********************** Setters ***********************/
    /**
     * @notice Set CIC
     * @param _chef address.
     */
    function setChefIncentivesController(IChefIncentivesController _chef) external onlyOwner {
        if (address(_chef) == address(0)) revert AddressZero();
        chef = _chef;
        emit ChefIncentivesControllerUpdated(_chef);
    }

    /**
     * @notice Set LP token
     */
    function setVeToken(address _veToken) external onlyOwner {
        if (_veToken == address(0)) revert AddressZero();
        if (veToken != address(0)) revert LPTokenSet(veToken);
        veToken = _veToken;

        emit VeTokenUpdated(_veToken);
    }

    /**
     * @notice Sets required tvl ratio. Can only be called by the owner.
     * @param _requiredDepositRatio Ratio in bips.
     */
    function setRequiredDepositRatio(uint256 _requiredDepositRatio) external onlyOwner {
        if (_requiredDepositRatio > RATIO_DIVISOR) revert InvalidRatio();
        requiredDepositRatio = _requiredDepositRatio;

        emit RequiredDepositRatioUpdated(_requiredDepositRatio);
    }

    /**
     * @notice Sets price tolerance ratio. Can only be called by the owner.
     * @param _priceToleranceRatio Ratio in bips.
     */
    function setPriceToleranceRatio(uint256 _priceToleranceRatio) external onlyOwner {
        if (_priceToleranceRatio < MIN_PRICE_TOLERANCE_RATIO || _priceToleranceRatio > RATIO_DIVISOR) revert InvalidRatio();
        priceToleranceRatio = _priceToleranceRatio;

        emit PriceToleranceRatioUpdated(_priceToleranceRatio);
    }

    /**
     * @notice Sets DQ time of the user
     * @dev Only callable by CIC
     * @param _user's address
     * @param _time for DQ
     */
    //@note use in CIC: stopEmissionsFor
    function setDqTime(address _user, uint256 _time) external {
        if (msg.sender != address(chef)) revert OnlyCIC();
        disqualifiedTime[_user] = _time;

        emit DqTimeUpdated(_user, _time);
    }

    /********************** View functions ***********************/
    /**
     * @notice Returns locked APUFF and LP token value in eth
     * @param user's address
     */
    function lockedVeTokenUsdcValue(address user) public view returns (uint256) {
        //@todo confirm decimal handling
        uint256 price = priceProvider.getTokenPrice();
        uint256 veTokenAmount = IERC20(veToken).balanceOf(user);
        return ((veTokenAmount * price) * 1e6) / 1e18 / 1e18; // 1e6 for 6 decimals of usdc, 1e18 for 18 decimals of veToken and price
    }

    /**
     * @notice Returns USD value required to be locked
     * @param user's address
     * @return required USD value.
     */
    function requiredUsdcValue(address user) public view returns (uint256 required) {
        uint256 totalCollateralUSD = collateralChecker.getTotalCollateralInUsdc(user) / 1e12;
        required = (totalCollateralUSD * requiredDepositRatio) / RATIO_DIVISOR;
    }

    /**
     * @notice Returns if the user is eligible to receive rewards
     * @param _user's address
     */
    function isEligibleForRewards(address _user) public view returns (bool) {
        uint256 lockedValue = lockedVeTokenUsdcValue(_user);
        uint256 requiredValue = (requiredUsdcValue(_user) * priceToleranceRatio) / RATIO_DIVISOR;
        return requiredValue != 0 && lockedValue >= requiredValue;
    }

    /**
     * @notice Returns if the user is eligible to receive rewards, lockedVeToken Value and totalCollateralUSD, saved to backend before execution
     * @param _user's address
     */
    function getEligibilityData(address _user) public view returns (bool isEligible, uint256 lockedValue, uint256 totalCollateralUSD) {
        lockedValue = lockedVeTokenUsdcValue(_user);
        totalCollateralUSD = collateralChecker.getTotalCollateralInUsdc(_user) / 1e12;
        uint256 requiredBeforePT = (totalCollateralUSD * requiredDepositRatio) / RATIO_DIVISOR;
        uint256 requiredValue = (requiredBeforePT * priceToleranceRatio) / RATIO_DIVISOR;
        isEligible = requiredValue != 0 && lockedValue >= requiredValue;
    }

    /**
     * @notice Returns DQ time of the user
     * @param _user's address
     */
    function getDqTime(address _user) public view returns (uint256) {
        return disqualifiedTime[_user];
    }

    /********************** Operate functions ***********************/
    //     /**
    //      * @notice Refresh token amount for eligibility
    //      * @param user The address of the user
    //      * @return currentEligibility the current eligibility status of the user
    //      */
    //     function refresh(address user) external returns (bool currentEligibility) {
    //         if (msg.sender != address(chef)) revert OnlyCIC();
    //         if (user == address(0)) revert AddressZero();
    //
    //         currentEligibility = isEligibleForRewards(user);
    //         if (currentEligibility && disqualifiedTime[user] != 0) {
    //             disqualifiedTime[user] = 0;
    //         }
    //         lastEligibleStatus[user] = currentEligibility;
    //     }

    /**
     * @notice Refresh token amount for eligibility by Keeper
     * @param user The address of the user
     * @return currentEligibility The current eligibility status of the user
     */
    function refreshByKeeper(address user, bool isEligible) external returns (bool currentEligibility) {
        if (msg.sender != address(chef)) revert OnlyCIC();
        if (user == address(0)) revert AddressZero();

        currentEligibility = isEligible;
        if (currentEligibility && disqualifiedTime[user] != 0) {
            disqualifiedTime[user] = 0;
        }
        lastEligibleStatus[user] = currentEligibility;
    }

    /********************** Internal functions ***********************/
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.23;
pragma experimental ABIEncoderV2;

interface ICICUserDefinedTypes {
    // Info of each user.
    // reward = user.`amount` * pool.`accRewardPerShare` - `rewardDebt`
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastClaimTime;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 totalSupply;
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardTime; // Last second that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times ACC_REWARD_PRECISION. See below.
    }
    // Info about token emissions for a given time period.
    struct EmissionPoint {
        uint128 startTimeOffset;
        uint128 rewardsPerSecond;
    }
    // Info about ending time of reward emissions
    struct EndingTime {
        uint256 estimatedTime;
        uint256 lastUpdatedTime;
        uint256 updateCadence;
    }

    enum EligibilityModes {
        // check on all rToken transfers
        FULL,
        // only check on Claim
        LIMITED,
        // 0 eligibility functions run
        DISABLED
    }

    /********************** Events ***********************/
    // Emitted when rewardPerSecond is updated
    event RewardsPerSecondUpdated(uint256 indexed rewardsPerSecond);

    event BalanceUpdated(address indexed token, address indexed user, uint256 balance);

    event EmissionScheduleAppended(uint256[] startTimeOffsets, uint256[] rewardsPerSeconds);

    event Disqualified(address indexed user);

    event EligibilityModeUpdated(EligibilityModes indexed _newVal);

    event BatchAllocPointsUpdated(address[] _tokens, uint256[] _allocPoints);

    event AuthorizedContractUpdated(address _contract, bool _authorized);

    event EndingTimeUpdateCadence(uint256 indexed _lapse);

    event RewardDeposit(uint256 indexed _amount);

    event UpdateRequested(address indexed _user, uint256 feePaid);

    event KeeperConfigSet(address indexed keeper, uint256 executionGasLimit, uint256 internalGasLimit);

    /********************** Errors ***********************/
    error AddressZero();

    error UnknownPool();

    error PoolExists();

    error AlreadyStarted();

    error NotAllowed();

    error ArrayLengthMismatch();

    error InvalidStart();

    error InvalidRToken();

    error InsufficientPermission();

    error AuthorizationAlreadySet();

    error NotVeContract();

    error NotWhitelisted();

    error NotEligible();

    error CadenceTooLong();

    error EligibleRequired();

    error NotValidPool();

    error OutOfRewards();

    error DuplicateSchedule();

    error ValueZero();

    error NotKeeper();

    error InsufficientFee();

    error TransferFailed();

    error UpdateInProgress();

    error ExemptedUser();

    error EthTransferFailed(); 

}

interface IChefIncentivesController {
    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     **/
    function handleActionBefore(address user) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     **/
    function handleWithdrawAfter(address user, uint256 userBalance) external;

    /**
     * @dev Called by the locking contracts after locking or unlocking happens
     * @param user The address of the user
     **/
    function beforeLockUpdate(address user) external;

    /**
     * @notice Hook for lock update.
     * @dev Called by the locking contracts after locking or unlocking happens
     */
    function afterLockUpdate(address _user) external;

    function addPool(address _token, uint256 _allocPoint) external;

    function claim(address _user, address[] calldata _tokens) external;

    // function disqualifyUser(address _user, address _hunter) external returns (uint256 bounty);

    // function bountyForUser(address _user) external view returns (uint256 bounty);

    function allPendingRewards(address _user) external view returns (uint256 pending);

    function claimAll(address _user) external;

    // function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

    function setEligibilityExempt(address _address, bool _value) external;

    function manualStopEmissionsFor(address _user, address[] memory _tokens) external;

    function manualStopAllEmissionsFor(address _user) external;

    function setAddressWLstatus(address user, bool status) external;

    function toggleWhitelist() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface ICollateralChecker {
    //@dev total collatral Amount deposited in our system on a certain chain
    function getTotalCollateralInUsdc(address _user) external view returns (uint256 totalCollateralInUSD);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.23;

import { IChefIncentivesController } from "./IChefIncentivesController.sol";

interface IEDPUserDefinedTypes {
    /********************** Events ***********************/
    /// @notice Emitted when CIC is set
    event ChefIncentivesControllerUpdated(IChefIncentivesController indexed _chef);

    /// @notice Emitted when LP token is set
    event VeTokenUpdated(address indexed _lpToken);

    /// @notice Emitted when required TVL ratio is updated
    event RequiredDepositRatioUpdated(uint256 indexed requiredDepositRatio);

    /// @notice Emitted when price tolerance ratio is updated
    event PriceToleranceRatioUpdated(uint256 indexed priceToleranceRatio);

    /// @notice Emitted when DQ time is set
    event DqTimeUpdated(address indexed _user, uint256 _time);

    /********************** Errors ***********************/
    error AddressZero();

    error LPTokenSet(address currentVeToken);

    error InvalidRatio();

    error OnlyCIC();
}

interface IEligibilityDataProvider {
    function refreshByKeeper(address user, bool isEligible) external returns (bool currentEligibility);

    function isEligibleForRewards(address _user) external view returns (bool isEligible);

    function lockedVeTokenUsdcValue(address user) external view returns (uint256);

    function requiredUsdcValue(address user) external view returns (uint256 required);

    function lastEligibleStatus(address user) external view returns (bool);

    function setDqTime(address _user, uint256 _time) external;

    function getDqTime(address _user) external view returns (uint256);

    function requiredDepositRatio() external view returns (uint256);

    function RATIO_DIVISOR() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

interface IPriceProvider {
    /********************** Events ***********************/

    event ChainlinkOracleSet(address ethOracle);
    event TimeIntervalSet(uint256 indexed timeInterval, uint32 indexed twapInterval, uint8 indexed timePoints);
    event PriceUpdated(uint256 indexed price);
    event PriceBroadcasted(uint256 chainId, uint256 indexed price);
    event ApuffTokenPoolSet(address indexed apuffTokenPoolAddress);
    event EthWithdrawn(uint256 indexed amount);
    event KeeperSet(address keeper, bool isKeeper);
    /********************** Errors ***********************/
    error AddressZero();
    error InvalidTimeInterval();
    error InvalidTimePoints();
    error NotKeeper();

    function getTokenPrice() external view returns (uint256);

    function decimals() external view returns (uint8);
}