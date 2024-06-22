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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
    /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
    struct PausableStorage {
        bool _paused;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

    function _getPausableStorage() private pure returns (PausableStorage storage $) {
        assembly {
            $.slot := PausableStorageLocation
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
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
        PausableStorage storage $ = _getPausableStorage();
        return $._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = true;
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
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation = 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
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
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        $._status = ENTERED;
    }

    function _nonReentrantAfter() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        return $._status == ENTERED;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';

interface IAggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract ArbitrumPresale is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 public totalTokensSold;
    uint256 public claimStart;
    uint256 public baseScale;
    uint256 public baseDecimals;
    uint256 public maxTokensToBuy;
    uint256 public minTokensToBuy;
    uint256 public currentStep;
    uint256 public checkPoint;
    uint256 public usdRaised;
    uint256 public timeConstant;
    uint256[][3] private rounds;
    uint256[] private remainingTokensTracker;
    address public saleToken;
    address private paymentWallet;
    address public USDTtoken;
    address public USDCtoken;
    address public DAItoken;
    address public aggregatorInterface;
    bool public dynamicTimeFlag;
    mapping(address => uint256) public userDeposits;
    mapping(uint256 => uint256) public usdTokenDecimals;

    event TokensBought(
        address indexed user,
        uint256 indexed tokensBought,
        address indexed purchaseToken,
        uint256 amountPaid,
        uint256 usdEq,
        uint256 timestamp
    );

    event TokensAdded(
        address indexed token,
        uint256 noOfTokens,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event StepIncremented(uint256 newStep, uint256 timestamp);

    constructor() initializer {}

    function initialize(
        address _oracle,
        address _usdt,
        address _usdc,
        address _dai,
        uint256[][3] memory _rounds,
        uint256 _timeConstant,
        uint256 _maxTokensToBuy,
        uint256 _minTokensToBuy,
        address _paymentWallet
    ) external initializer {
        require(_oracle != address(0), 'Zero aggregator address');
        require(_usdt != address(0), 'Zero USDT address');
        require(_usdc != address(0), 'Zero USDC address');
        require(_dai != address(0), 'Zero DAI address');
        __Pausable_init_unchained();
        __Ownable_init_unchained(_msgSender());
        __ReentrancyGuard_init_unchained();
        baseScale = 18;
        baseDecimals = (10 ** baseScale);
        aggregatorInterface = _oracle;
        USDTtoken = _usdt;
        USDCtoken = _usdc;
        DAItoken = _dai;
        rounds = _rounds;
        maxTokensToBuy = _maxTokensToBuy > _rounds[0][0]
            ? _rounds[0][0]
            : _maxTokensToBuy;
        minTokensToBuy = _minTokensToBuy >= _maxTokensToBuy
            ? 0
            : _minTokensToBuy;
        paymentWallet = _paymentWallet;
        dynamicTimeFlag = true;
        timeConstant = _timeConstant;

        usdTokenDecimals[0] = 6; //USDT
        usdTokenDecimals[1] = 6; //USDC
        usdTokenDecimals[2] = 18; //DAI
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function calculatePrice(uint256 _amount) public view returns (uint256) {
        uint256 usdAmount;
        bool isLastRound = currentStep >= rounds[0].length - 1;
        uint256 total = (isLastRound || checkPoint == 0)
            ? totalTokensSold
            : checkPoint;

        if (
            !isLastRound &&
            (_amount + total > rounds[0][currentStep] ||
                block.timestamp >= rounds[2][currentStep])
        ) {
            if (block.timestamp >= rounds[2][currentStep]) {
                require(
                    rounds[0][currentStep] + _amount <=
                        rounds[0][currentStep + 1],
                    'Cant purchase more in one transaction'
                );

                usdAmount = _amount * rounds[1][currentStep + 1];
            } else {
                uint256 tokenAmountForCurrentPrice = rounds[0][currentStep] -
                    total;

                uint256 tokenAmountForNextPrice = _amount -
                    tokenAmountForCurrentPrice;

                usdAmount =
                    tokenAmountForCurrentPrice *
                    rounds[1][currentStep] +
                    tokenAmountForNextPrice *
                    rounds[1][currentStep + 1];
            }
        } else {
            usdAmount = _amount * rounds[1][currentStep];
        }

        return usdAmount;
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = IAggregator(aggregatorInterface)
            .latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    function manageRounds(uint256 amount) private {
        uint256 totalBefore = totalTokensSold > checkPoint
            ? totalTokensSold
            : checkPoint;

        totalTokensSold += amount;
        if (checkPoint != 0) checkPoint += amount;

        uint256 total = totalTokensSold > checkPoint
            ? totalTokensSold
            : checkPoint;

        if (
            currentStep < (rounds[0].length - 1) &&
            (total >= rounds[0][currentStep] ||
                block.timestamp >= rounds[2][currentStep])
        ) {
            uint256 unsoldTokens = total >= rounds[0][currentStep]
                ? 0
                : rounds[0][currentStep] - total;

            if (block.timestamp >= rounds[2][currentStep]) {
                checkPoint = rounds[0][currentStep] + amount;

                unsoldTokens = totalBefore >= rounds[0][currentStep]
                    ? 0
                    : rounds[0][currentStep] - totalBefore;
            }

            if (dynamicTimeFlag) manageTimeDiff();

            remainingTokensTracker.push(unsoldTokens);
            currentStep += 1;
        }
    }

    modifier checkSaleState(uint256 amount) {
        require(
            amount >= minTokensToBuy &&
                amount <= maxTokensToBuy &&
                totalTokensSold + amount <= rounds[0][rounds[0].length - 1],
            'Invalid sale amount'
        );
        _;
    }

    function buyWithUSD(
        uint256 amount,
        uint256 purchaseToken
    ) external checkSaleState(amount) whenNotPaused {
        require(
            usdTokenDecimals[purchaseToken] != 0,
            'Incorrect USD token provided'
        );
        uint256 usdPrice = calculatePrice(amount);
        uint256 price = usdPrice /
            getDecimalsDivider(usdTokenDecimals[purchaseToken]);

        manageRounds(amount);

        userDeposits[_msgSender()] += (amount * baseDecimals);
        usdRaised += usdPrice;

        IERC20 usdInterface;
        if (purchaseToken == 0) usdInterface = IERC20(USDTtoken);
        else if (purchaseToken == 1) usdInterface = IERC20(USDCtoken);
        else if (purchaseToken == 2) usdInterface = IERC20(DAItoken);
        else revert('Incorrect USD token provided');

        uint256 ourAllowance = usdInterface.allowance(
            _msgSender(),
            address(this)
        );

        require(price <= ourAllowance, 'Make sure to add enough allowance');

        (bool success, ) = address(usdInterface).call(
            abi.encodeWithSignature(
                'transferFrom(address,address,uint256)',
                _msgSender(),
                paymentWallet,
                price
            )
        );

        require(success, 'Token payment failed');

        emit TokensBought(
            _msgSender(),
            amount,
            address(usdInterface),
            price,
            usdPrice,
            block.timestamp
        );
    }

    function buyWithETH(
        uint256 amount
    ) external payable checkSaleState(amount) whenNotPaused nonReentrant {
        uint256 usdPrice = calculatePrice(amount);
        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        require(msg.value >= ethAmount, 'Less payment');
        uint256 excess = msg.value - ethAmount;

        manageRounds(amount);

        userDeposits[_msgSender()] += (amount * baseDecimals);
        usdRaised += usdPrice;

        sendValue(payable(paymentWallet), ethAmount);
        if (excess > 0) sendValue(payable(_msgSender()), excess);

        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            ethAmount,
            usdPrice,
            block.timestamp
        );
    }

    function ethBuyHelper(
        uint256 amount
    ) external view returns (uint256 ethAmount) {
        uint256 usdPrice = calculatePrice(amount);
        ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    }

    function usdBuyHelper(
        uint256 amount,
        uint256 purchaseToken
    ) external view returns (uint256 usdPrice) {
        require(
            usdTokenDecimals[purchaseToken] != 0,
            'Incorrect USD token provided'
        );
        usdPrice = calculatePrice(amount);
        usdPrice =
            usdPrice /
            getDecimalsDivider(usdTokenDecimals[purchaseToken]);
    }

    function claim() external whenNotPaused {
        require(saleToken != address(0), 'Sale token not added');
        require(block.timestamp >= claimStart, 'Claim has not started yet');
        uint256 amount = userDeposits[_msgSender()];
        require(amount > 0, 'Nothing to claim');
        delete userDeposits[_msgSender()];
        bool success = IERC20(saleToken).transfer(_msgSender(), amount);
        require(success, 'Token transfer failed');
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    function getDecimalsDivider(
        uint256 decimals
    ) internal view returns (uint256) {
        if (baseDecimals > (10 ** decimals))
            return (10 ** (baseScale - decimals));
        else return 1;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Low balance');
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'ETH Payment failed');
    }

    function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
        require(
            _maxTokensToBuy > 0 && _maxTokensToBuy <= rounds[0][0],
            'Zero max tokens to buy value'
        );
        maxTokensToBuy = _maxTokensToBuy;
    }

    function changeMinTokensToBuy(uint256 _minTokensToBuy) external onlyOwner {
        require(
            _minTokensToBuy >= 0 && _minTokensToBuy < maxTokensToBuy,
            'Invalid min tokens to buy value'
        );
        minTokensToBuy = _minTokensToBuy;
    }

    function startClaim(
        uint256 _claimStart,
        uint256 amountOfTokens,
        address _saleToken
    ) external onlyOwner {
        require(_saleToken != address(0), 'Zero token address');
        require(claimStart == 0, 'Claim already set');
        claimStart = _claimStart;
        saleToken = _saleToken;

        bool success = IERC20(saleToken).transferFrom(
            _msgSender(),
            address(this),
            amountOfTokens
        );

        require(success, 'Token transfer failed');
        emit TokensAdded(saleToken, amountOfTokens, block.timestamp);
    }

    function changeClaimStart(uint256 _claimStart) external onlyOwner {
        require(claimStart > 0, 'Initial claim data not set');
        claimStart = _claimStart;
    }

    function changeRoundsData(uint256[][3] memory _rounds) external onlyOwner {
        rounds = _rounds;
    }

    function changePaymentWallet(address _newPaymentWallet) external onlyOwner {
        require(_newPaymentWallet != address(0), 'Address cannot be zero');
        paymentWallet = _newPaymentWallet;
    }

    function manageTimeDiff() internal {
        for (uint256 i; i < rounds[2].length - currentStep; i++) {
            rounds[2][currentStep + i] = block.timestamp + i * timeConstant;
        }
    }

    function setTimeConstant(uint256 _timeConstant) external onlyOwner {
        timeConstant = _timeConstant;
    }

    function updateUserDeposits(
        address[] calldata _users,
        uint256[] calldata _userDeposits
    ) external onlyOwner {
        require(_users.length == _userDeposits.length, 'Length mismatch');
        for (uint256 i = 0; i < _users.length; i++) {
            userDeposits[_users[i]] += _userDeposits[i];
        }
    }

    function incrementCurrentStep() external onlyOwner {
        require(
            currentStep < (rounds[0].length - 1),
            'Current round is the last one'
        );

        if (dynamicTimeFlag) manageTimeDiff();

        if (checkPoint < rounds[0][currentStep]) {
            uint256 sub = totalTokensSold > checkPoint
                ? totalTokensSold
                : checkPoint;

            remainingTokensTracker.push(rounds[0][currentStep] - sub);
            checkPoint = rounds[0][currentStep];
        }

        currentStep++;

        emit StepIncremented(currentStep, block.timestamp);
    }

    function setDynamicTimeFlag(bool _dynamicTimeFlag) external onlyOwner {
        dynamicTimeFlag = _dynamicTimeFlag;
    }

    function setCurrentStep(
        uint256 _step,
        uint256 _checkpoint
    ) external onlyOwner {
        currentStep = _step;
        checkPoint = _checkpoint;
    }

    function trackRemainingTokens() external view returns (uint256[] memory) {
        return remainingTokensTracker;
    }

    function setRemainingTokensArray(
        uint256[] memory _unsoldTokens
    ) public onlyOwner {
        require(_unsoldTokens.length != 0, 'cannot update invalid values');
        delete remainingTokensTracker;
        for (uint256 i; i < _unsoldTokens.length; i++) {
            remainingTokensTracker.push(_unsoldTokens[i]);
        }
    }

    function roundDetails(
        uint256 _no
    ) external view returns (uint256[] memory) {
        return rounds[_no];
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(paymentWallet, amount);
    }

    function withdrawEthers() external onlyOwner {
        (bool success, ) = paymentWallet.call{value: address(this).balance}('');
        require(success, 'Failed to withdraw');
    }
}