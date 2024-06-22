// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "./OwnableUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable2Step
    struct Ownable2StepStorage {
        address _pendingOwner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable2Step")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant Ownable2StepStorageLocation = 0x237e158222e3e6968b72b9db0d8043aacf074ad9f650f0d1606b4d82ee432c00;

    function _getOwnable2StepStorage() private pure returns (Ownable2StepStorage storage $) {
        assembly {
            $.slot := Ownable2StepStorageLocation
        }
    }

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    function __Ownable2Step_init() internal onlyInitializing {
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        return $._pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        $._pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        delete $._pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165Upgradeable} from "../../../utils/introspection/ERC165Upgradeable.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {Initializable} from "../../../proxy/utils/Initializable.sol";

/**
 * @dev Simple implementation of `IERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 */
abstract contract ERC1155HolderUpgradeable is Initializable, ERC165Upgradeable, IERC1155Receiver {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v5.0.1) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits either a {TransferSingle} or a {TransferBatch} event, depending on the length of the array arguments.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title MinerStakingContract
 * @dev This contract handles the staking of tokens by miners.
 * It inherits from Initializable, Ownable2StepUpgradeable, ERC1155HolderUpgradeable,
 * PausableUpgradeable, and ReentrancyGuardUpgradeable contracts.
 */
contract MinerStakingContract is Initializable, Ownable2StepUpgradeable, ERC1155HolderUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    /**
     * @dev Maximum mining time allowed for staking.
     */
    uint256 public constant MAX_MINING_TIME = 180 days;


    /**
     * @dev Interface for the ERC1155 miner contract.
     */
    IERC1155 public minerContract;


    /**
     * @dev A variable to store the interface of the IPool contract.
     */
    IPool public rewordsPool;


    /**
     * @dev The start time of the staking period.
     */
    uint256 public startTime;

    /**
     * @dev The end time of the staking period.
     */
    uint256 public endTime;

    /**
     * @dev A mapping that stores the hash rates for each MinerType.
     * The key is the MinerType enum and the value is the corresponding hash rate.
     */
    mapping(MinerType => uint256) public hashRates;

    /**
     * @dev A mapping that stores the mining statuses of addresses.
     * Each address can have multiple mining statuses.
     * The mining statuses are stored in an array.
     * The mapping is private, allowing external contracts to access the mining statuses.
     */
    mapping(address => MiningStatus[]) private miningStatuses;

    /**
     * @dev An array of `AdjustRecord` structs that stores adjustment records.
     * This array is private and can only be accessed within the `MinerStakingContract` contract.
     */
    AdjustRecord[] private adjustRecords;

    /**
     * @dev The amount of fee required to claim for each miner.
     */
    uint256 public claimFeeForEachMiner;

    /**
     * @dev The address where the claim fee will be sent to.
     */
    address public claimFee2Address;

    /**
    * @dev Represents a staking contract for miners.
    * 
    * - `minerType`: The type of miner.
    * - `startTime`: The start time of the staking period.
    * - `endTime`: The end time of the staking period.
    * - `recentAdjustIndex`: The recent adjustment index.
    * - `latestClaimedTime`: The latest time when rewards were claimed.
    * - `rewardsClaimed`: The total rewards claimed by the miner.
    */
    struct MiningStatus {
        MinerType minerType;
        uint256 startTime;
        uint256 endTime;
        uint256 recentAdjustIndex;
        uint256 latestClaimedTime;
        uint256 rewardsClaimed;
    }

    /**
     * @dev Enum representing the different types of miners.
     * - Mini: Represents the Mini miner type.
     * - Bronze: Represents the Bronze miner type.
     * - Silver: Represents the Silver miner type.
     * - Gold: Represents the Gold miner type.
     */
    enum MinerType {
        Mini,
        Bronze,
        Silver,
        Gold
    }

    /**
     * @dev Struct representing an adjustment record for a miner's staking contract.
     * It contains the outputFactor and time of the adjustment.
     */
    struct AdjustRecord {
        uint256 timestamp;
        uint256 outputFactor;
    }
  
    /**
     * @dev Struct representing the configuration for the staking contract.
     * It contains the output factor, miner contract address, rewards pool address, owner address, start time, and end time.
     */
    struct LaunchConfig {
        uint256 outputFactor;
        address minerContract;
        address rewardsPool;
        address owner;
        uint256 startTime;
        uint256 endTime;
    }

    /**
     * @dev Emitted when a miner starts staking.
     * @param account The address of the account that started staking.
     * @param index The index of the miner.
     * @param minerType The type of the miner.
     */
    event MinerStarted(address indexed account, uint256 index, MinerType indexed minerType);

    /**
     * @dev Emitted when a miner claims rewards.
     * @param account The address of the user.
     * @param index The index of the rewards.
     * @param rewards The amount of rewards claimed.
     * @param targetTimestamp The target timestamp for claiming rewards.
     */
    event RewardsClaimed(address indexed account, uint256 index, uint256 rewards, uint256 targetTimestamp);

    /**
     * @dev Emitted when the output factor is dropped.
     * @param timestamp The timestamp when the factor is dropped.
     * @param factor The dropped factor value.
     */
    event OutputFactorDropped(uint256 timestamp, uint256 factor);

    /**
     * @dev Emitted when a new output factor is added.
     * @param timestamp The timestamp when the output factor is added.
     * @param factor The value of the output factor.
     */
    event OutputFactorAdded(uint256 timestamp, uint256 factor);

    /**
     * @dev Emitted when the end time is updated.
     * @param newEndTime The new end time value.
     */
    event EndTimeUpdated(uint256 newEndTime);


    // /**
    //  * @dev Constructor function for the MinerStakingContract.
    //  * It disables the initializers to prevent any further initialization.
    //  */
    // constructor() {
    //     _disableInitializers();
    // }

    /**
     * @dev Initializes the staking contract with the specified configuration.
     * It sets the owner, miner contract, rewards pool, start time, and end time.
     * @param config The configuration for the staking contract.
     */
    function initialize(LaunchConfig calldata config) public initializer {
        __Ownable_init(config.owner);
        __Pausable_init();
        __ReentrancyGuard_init();

        minerContract = IERC1155(config.minerContract);
        rewordsPool = IPool(config.rewardsPool);
        startTime  = config.startTime;
        endTime = config.endTime;
        _addOutputFactorNoCheck(block.timestamp, config.outputFactor);
        hashRates[MinerType.Mini] = 10_000;
        hashRates[MinerType.Bronze] = 100_000;
        hashRates[MinerType.Silver] = 1_005_000;
        hashRates[MinerType.Gold] = 10_100_000;
    }

    /**
     * @dev Executes batch mining for multiple miner types and quantities.
     * @param _types An array of MinerType values representing the types of miners to be mined.
     * @param _quantities An array of uint256 values representing the quantities of miners to be mined.
     * @notice This function can only be called during valid time periods and when the contract is not paused.
     * @notice The length of `_types` and `_quantities` arrays must be the same.
     * @notice Each element in `_types` and `_quantities` arrays corresponds to a single mining operation.
     * @notice Throws an error if the input length is invalid.
     */
    function batchMining(MinerType[] calldata _types, uint256[] calldata _quantities) external onlyValidTime nonReentrant whenNotPaused {
        require(_types.length == _quantities.length, "MinerStakingContract: Invalid input length");
        for (uint256 i = 0; i < _types.length; i++) {
            _mining(_types[i], _quantities[i]);
        }
    }

    /**
     * @dev Initiates the mining process by staking a certain quantity of tokens with a specified miner type.
     * @param _type The type of miner to stake tokens with.
     * @param _quantity The quantity of tokens to stake.
     * Requirements:
     * - The function can only be called during a valid time period.
     * - The function can only be called when the contract is not paused.
     */
    function mining(MinerType _type, uint256 _quantity) external onlyValidTime nonReentrant whenNotPaused {
        _mining(_type, _quantity);
    }

    /**
     * @dev Allows a user to claim rewards for a given set of miner indexes and target timestamp.
     * @param _minerIndexes The array of miner indexes for which the rewards are to be claimed.
     * @param _targetTimestamp The target timestamp until which the rewards can be claimed.
     * @notice The target timestamp must be less than the current block timestamp.
     * @notice This function can only be called when the contract is not paused.
     */
    function claim(uint256[] calldata _minerIndexes, uint256[] calldata _targetTimestamp) external payable nonReentrant whenNotPaused {
        require(_minerIndexes.length == _targetTimestamp.length && _minerIndexes.length > 0, "MinerStakingContract: Invalid input length");
        if (claimFeeForEachMiner > 0) {
            require(msg.value == claimFeeForEachMiner * _minerIndexes.length, "MinerStakingContract: Invalid claim fee");
            require(claimFee2Address != address(0), "MinerStakingContract: Invalid claim fee address");
            payable(claimFee2Address).transfer(msg.value);
        }
        for (uint256 i = 0; i < _minerIndexes.length; i++) {
            require(_targetTimestamp[i] < block.timestamp, "MinerStakingContract: Invalid target timestamp");
            _claimRewards(msg.sender, _minerIndexes[i], _targetTimestamp[i]);
        }
    }

    /**
     * @dev Adds a future output factor to the adjustment records.
     * Only the contract owner can call this function.
     * @param _timeline The timeline for the adjustment.
     * @param _miningOutputFactor The output factor to be added.
     * Emits an `OutputFactorAdded` event with the timeline and output factor.
     */
    function addFutureOutputFactor(uint256 _timeline, uint256 _miningOutputFactor) external onlyOwner {
        _addOutputFactor(_timeline, _miningOutputFactor);
    }

    /**
     * @dev Adds a real-time output factor to the adjustment records.
     * Only the contract owner can call this function.
     * @param _miningOutputFactor The output factor to be added.
     * Emits an `OutputFactorAdded` event with the timestamp and output factor.
     */
    function addRealTimeOutputFactor(uint256 _miningOutputFactor) external onlyOwner {
        _addOutputFactor(block.timestamp, _miningOutputFactor);
    }

    /**
     * @dev Drops the future output factor from the adjustment records.
     * Only the contract owner can call this function.
     * 
     * Requirements:
     * - The future output factor must exist.
     * 
     * Emits an `OutputFactorDropped` event with the timestamp and output factor.
     */
    function dropFutureOutputFactor() public onlyOwner {
        (uint256 latestTimestamp, uint256 latestOutputFactor) = getLatestAdjustRecord();
        require(latestTimestamp > block.timestamp, "MinerStakingContract: The future output factor does not exist");
        adjustRecords.pop();
        emit OutputFactorDropped(latestTimestamp, latestOutputFactor);
    }

    /**
     * @dev Sets the end time for the staking contract.
     * @param _endTime The new end time to be set.
     * Emits an `EndTimeUpdated` event with the updated end time.
     * Only the contract owner can call this function.
     */
    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
        emit EndTimeUpdated(_endTime);
    }

    /**
     * @dev Sets the claim fee for each miner and the address to receive the claim fee.
     * @param _claimFeeForEachMiner The amount of claim fee for each miner.
     * @param _claimFee2Address The address to receive the claim fee.
     * @notice Only the contract owner can call this function.
     * @notice The claim fee address must not be the zero address.
     */
    function setClaimFee(uint256 _claimFeeForEachMiner, address _claimFee2Address) public onlyOwner {
        require(_claimFee2Address != address(0), "MinerStakingContract: Invalid claim fee address");
        claimFeeForEachMiner = _claimFeeForEachMiner;
        claimFee2Address = _claimFee2Address;
    }

    /**
     * @dev Pauses the staking contract.
     * Requirements:
     * - Only the contract owner can call this function.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the staking contract.
     * Requirements:
     * - Only the contract owner can call this function.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Returns the rewards for a given hash rate, output factor, and duration.
     * @param _hashRate The hash rate of the miner.
     * @param _outputFactor The output factor of the miner.
     * @param _duration The duration for which the rewards are to be calculated.
     * @return The rewards calculated based on the hash rate, output factor, and duration.
     */
    function rewardByHashRate(uint256 _hashRate, uint256 _outputFactor, uint256 _duration) public pure returns (uint256) {
        uint256 rewards = _hashRate * _outputFactor * _duration;
        return rewards;
    }

    /**
     * @dev Returns the length of the mining status array for a given account.
     * @param _account The address of the account.
     * @return The length of the mining status array.
     */
    function getMiningStatusLength(address _account) external view returns (uint256) {
        return miningStatuses[_account].length;
    }

    /**
     * @dev Retrieves the unclaimed rewards for a given account within a specified range of mining statuses.
     * @param _account The address of the account for which to retrieve the rewards.
     * @param _from The starting index of the mining statuses range.
     * @param _to The ending index of the mining statuses range.
     * @param _targetTimestamp The target timestamp used for calculating rewards.
     * @return rewards An array of unclaimed rewards for each mining status within the specified range.
     */
    function getUnclaimedRewards(address _account, uint256 _from, uint256 _to, uint256 _targetTimestamp) external view returns (uint256[] memory) {
        require(_from <= _to, "MinerStakingContract: Invalid range");
        uint256 length = miningStatuses[_account].length;
        require(_to < length, "MinerStakingContract: Invalid range");
        uint256[] memory rewards = new uint256[](_to - _from + 1);
        for (uint256 i = _from; i <= _to; i++) {
            (, rewards[i - _from]) = _calculateRewards(_account, i, _targetTimestamp);
        }
        return rewards;
    }
    
    /**
     * @dev Retrieves the mining status for a given account and index.
     * @param _account The address of the account.
     * @param _from The starting index of the range.
     * @param _to The ending index of the range.
     * @return An array of `MiningStatus` within the specified range.
     * @notice This function is view-only and does not modify the contract state.
     * @notice The range is inclusive of both the starting and ending indices.
     * @notice Throws an error if the range is invalid or if the ending index is out of bounds.
     */
    function getMiningStatus(address _account, uint256 _from, uint256 _to) external view returns (MiningStatus[] memory) {
        require(_from <= _to, "MinerStakingContract: Invalid range");
        uint256 length = miningStatuses[_account].length;
        require(_to < length, "MinerStakingContract: Invalid range");
        MiningStatus[] memory statuses = new MiningStatus[](_to - _from + 1);
        for (uint256 i = _from; i <= _to; i++) {
            statuses[i - _from] = miningStatuses[_account][i];
        }
        return statuses;
    }

    /**
     * @dev Retrieves the latest adjustment record.
     * @return The timestamp and output factor of the latest adjustment record.
     */
    function getLatestAdjustRecord() public view returns (uint256, uint256) {
        AdjustRecord memory record = adjustRecords[adjustRecords.length - 1];
        return (record.timestamp, record.outputFactor);
    }

    /**
     * @dev Retrieves an array of `AdjustRecord` within a specified range.
     * @param _from The starting index of the range.
     * @param _to The ending index of the range.
     * @return An array of `AdjustRecord` within the specified range.
     * @notice This function is view-only and does not modify the contract state.
     * @notice The range is inclusive of both the starting and ending indices.
     * @notice Throws an error if the range is invalid or if the ending index is out of bounds.
     */
    function getAdjustRecords(uint256 _from, uint256 _to) external view returns (AdjustRecord[] memory) {
        require(_from <= _to, "MinerStakingContract: Invalid range");
        uint256 length = adjustRecords.length;
        require(_to < length, "MinerStakingContract: Invalid range");
        AdjustRecord[] memory records = new AdjustRecord[](_to - _from + 1);
        for (uint256 i = _from; i <= _to; i++) {
            records[i - _from] = adjustRecords[i];
        }
        return records;
    }

    /**
     * @dev Retrieves the length of the occurred output factors array.
     * @return The length of the occurred output factors array.
     */
    function getOccurredOutputFactorsLength() public view returns (uint256) {
        (uint256 latestTimestamp, ) = getLatestAdjustRecord();
        if (block.timestamp >= latestTimestamp) {
            return adjustRecords.length;
        }
        return adjustRecords.length - 1;
    }

    /**
     * @dev Internal function for initiating mining.
     * @param _type The type of miner.
     * @param _quantity The quantity of miners to be initiated.
     * Requirements:
     * - `_quantity` must be greater than 0.
     * - `_type` must be a valid miner type.
     * - The caller must have approved the transfer of miners to this contract.
     * Emits a {Transfer} event.
     */
    function _mining(MinerType _type, uint256 _quantity) internal {
        require(_quantity > 0, "MinerStakingContract: Invalid quantity");
        require(_type >= MinerType.Mini && _type <= MinerType.Gold, "MinerStakingContract: Invalid type");
        minerContract.safeTransferFrom(msg.sender, address(this), uint256(_type), _quantity, "");
        /**
         * @dev Subtracting 1 from the length of the occurred output factors array to get the adjustIndex.
         * This is because the miner's initial state requires the index of the last occurred output factors.
         */
        uint256 adjustIndex = getOccurredOutputFactorsLength() - 1;
        for (uint256 i = 0; i < _quantity; i++) {
            _engineStart(msg.sender, _type, adjustIndex);
        }
    }

    /**
     * @dev Internal function to start the mining process for a specific miner.
     * @param account The address of the account.
     * @param _type The type of miner.
     * @param _adjustIndex The adjustment index.
     */
    function _engineStart(address account, MinerType _type, uint256 _adjustIndex) internal {
        miningStatuses[account].push(MiningStatus({
            minerType: _type,
            startTime: block.timestamp,
            endTime: block.timestamp + MAX_MINING_TIME,
            recentAdjustIndex: _adjustIndex,
            latestClaimedTime: block.timestamp,
            rewardsClaimed: 0
        }));
        emit MinerStarted(msg.sender, miningStatuses[account].length - 1, _type);
    }

    /**
     * @dev Internal function to claim rewards for a specific miner.
     * @param _account The address of the account.
     * @param _minerIndex The index of the miner in the miningStatuses mapping.
     * @param _targetTimestamp The target timestamp for calculating rewards.
     */
    function _claimRewards(address _account, uint256 _minerIndex, uint256 _targetTimestamp) internal {
        MiningStatus storage status = miningStatuses[_account][_minerIndex];
        (uint256 recentAdjustIndex, uint256 rewards) = _calculateRewards(_account, _minerIndex, _targetTimestamp);
        status.rewardsClaimed += rewards;
        status.recentAdjustIndex = recentAdjustIndex;
        status.latestClaimedTime = _targetTimestamp;
        rewordsPool.claim(_account, rewards);
        emit RewardsClaimed(_account, _minerIndex, rewards, _targetTimestamp);
    }

    /**
     * @dev Internal function to calculate rewards for a specific miner.
     * @param _account The address of the account.
     * @param _minerIndex The index of the miner in the miningStatuses mapping.
     * @param _targetTimestamp The target timestamp for calculating rewards.
     * @return The recent adjustment index and the rewards calculated.
     */
    function _calculateRewards(address _account, uint256 _minerIndex, uint256 _targetTimestamp) internal view returns (uint256, uint256) {
        MiningStatus memory status = miningStatuses[_account][_minerIndex];
        require(_targetTimestamp <= status.endTime && _targetTimestamp > status.latestClaimedTime, "MinerStakingContract: Invalid target timestamp");
        uint256 latestClaimedTime = status.latestClaimedTime;
        uint256 hashRate = hashRates[status.minerType];
        return caculateRewards(hashRate, status.recentAdjustIndex, latestClaimedTime, _targetTimestamp);
    }

    /**
     * @dev Calculates the rewards based on the given parameters.
     * @param _hashRate The hash rate of the miner.
     * @param _recentAdjustIndex The index of the most recent adjustment record.
     * @param _latestClaimedTime The timestamp of user claimed.
     * @param _targetTimestamp The target timestamp to calculate rewards until.
     * @return The index of the last adjustment record processed and the total rewards earned.
     */
    function caculateRewards(uint256 _hashRate, uint256 _recentAdjustIndex, uint256 _latestClaimedTime, uint256 _targetTimestamp) public view returns (uint256, uint256) {
        uint256 rewards = 0;
        uint256 occurredLatestIndex = getOccurredOutputFactorsLength() - 1;
        for (uint256 i = _recentAdjustIndex; i <= occurredLatestIndex; i++) {
            AdjustRecord memory record = adjustRecords[i];
            if (i < occurredLatestIndex) {
                AdjustRecord memory nextRecord = adjustRecords[i + 1];
                if (nextRecord.timestamp > _targetTimestamp) {
                    rewards += rewardByHashRate(_hashRate, record.outputFactor, _targetTimestamp - _latestClaimedTime);
                    return (i, rewards);
                }
                rewards += rewardByHashRate(_hashRate, record.outputFactor, nextRecord.timestamp - _latestClaimedTime);
                _latestClaimedTime = nextRecord.timestamp;
            }
            if (i == occurredLatestIndex) {
                rewards += rewardByHashRate(_hashRate, record.outputFactor, _targetTimestamp - _latestClaimedTime);
            }
        }
        return (occurredLatestIndex, rewards);
    }

    /**
     * @dev Adds a new output factor to the adjustment records.
     * Only the contract owner can call this function.
     * 
     * Requirements:
     * - The timeline must be greater than the current block timestamp.
     * 
     * Emits an `OutputFactorAdded` event with the timeline and output factor.
     */
    function _addOutputFactor(uint256 _timeline, uint256 _miningOutputFactor) internal {
        require(_timeline >= block.timestamp, "MinerStakingContract: Invalid timeline");
        (uint256 latestTimestamp, uint256 latestOutputFactor) = getLatestAdjustRecord();
        require(latestTimestamp < block.timestamp, "MinerStakingContract: The future output factor exists");
        require(latestOutputFactor != _miningOutputFactor, "MinerStakingContract: The output factor is the same");
        _addOutputFactorNoCheck(_timeline, _miningOutputFactor);
    }

    /**
     * @dev Adds a new output factor to the adjustment records without checking the timeline.
     * @param _timeline The timeline for the adjustment.
     * @param _miningOutputFactor The output factor to be added.
     * Emits an `OutputFactorAdded` event with the timeline and output factor.
     */
    function _addOutputFactorNoCheck(uint256 _timeline, uint256 _miningOutputFactor) internal {
        adjustRecords.push(AdjustRecord(_timeline, _miningOutputFactor));
        emit OutputFactorAdded(_timeline, _miningOutputFactor);
    }
    
    /**
     * @dev Modifier to check if the current time is within the valid time range.
     * The function requires that the current block timestamp is greater than or equal to the `startTime`
     * and less than the `endTime`, or `endTime` is set to 0 (indicating no end time).
     * If the condition is not met, it reverts with an error message.
     */
    modifier onlyValidTime() {
        require(startTime <= block.timestamp && (block.timestamp < endTime || endTime == 0), "MinerStakingContract: Invalid time");
        _;
    }
}

/**
 * @title IPool
 * @dev Interface for the haya Pool contract.
 */
interface IPool {
    /**
     * @dev Claims the specified amount of tokens for the given recipient.
     * @param _recipient The address of the recipient.
     * @param _amount The amount of tokens to claim.
     */
    function claim(address _recipient, uint256 _amount) external;
}