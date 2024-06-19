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
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.20;

import {IERC1822Proxiable} from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Initializable} from "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822Proxiable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable __self = address(this);

    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgradeTo(address)`
     * and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
     * while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    /**
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC1967-compliant implementation pointing to self.
     * See {_onlyProxy}.
     */
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self || // Must be called through delegatecall
            ERC1967Utils.getImplementation() != __self // Must be called through an active proxy
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Reverts if the execution is performed via delegatecall.
     * See {notDelegated}.
     */
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev Performs an implementation upgrade with a security check for UUPS proxies, and additional setup call.
     *
     * As a security check, {proxiableUUID} is invoked in the new implementation, and the return value
     * is expected to be the implementation slot in ERC1967.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            // The implementation is not UUPS
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.20;

import {IBeacon} from "../beacon/IBeacon.sol";
import {Address} from "../../utils/Address.sol";
import {StorageSlot} from "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeCall(IERC165.supportsInterface, (interfaceId));

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
abstract contract ReentrancyGuard {
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

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IAirdropLocked.sol";
import "./interfaces/IVotingEscrow.sol";
import "./utils/Adminable.sol";

contract AirDropLocked is Adminable, IAirdropLocked, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token; // MVDAO token contract address
    IVotingEscrow public immutable veContract; // Voting Escrow contract address

    address public treasury; // treasury wallet address

    address[] public _walletAddresses; // array of wallets to airdrop to
    mapping(address => LockSummary) private _lockSummaries; // lockup info by wallets

    uint256 public totalAmountToLock; // Total amount of tokens to be locked


    constructor(
        address _token,
        address _treasury,
        address _veContract
    ) {
        require(_token != address(0), "Airdrop: invalid address");
        require(_treasury != address(0), "Airdrop: invalid address");
        require(_veContract != address(0), "Airdrop: invalid address");

        token = IERC20(_token);
        treasury = _treasury;
        veContract = IVotingEscrow(_veContract);
    }

    function startAirdrop() external override onlyAdmin {
        token.safeIncreaseAllowance(address(veContract), totalAmountToLock);
        uint256 n = _walletAddresses.length;
        for (uint256 i = 0; i < n; i++) {
            address account = _walletAddresses[i];
            LockSummary memory lockSummary = _lockSummaries[account];
            veContract.createLockFor(account, address(this), lockSummary.amount, lockSummary.unlockTime);
            delete _lockSummaries[account];
        }

        delete _walletAddresses;
        totalAmountToLock = 0;
    }

    function resetAirdrop() external override onlyAdmin {
        uint256 n = _walletAddresses.length;
        for (uint256 i = 0; i < n; i++) {
            address account = _walletAddresses[i];
            delete _lockSummaries[account];
        }
        
        delete _walletAddresses;
        totalAmountToLock = 0;
    }

    function setAmount(address _account, uint256 _amount, uint256 _unlock_time)
        external
        override
        onlyAdmin
    {
        _setAmount(_account, _amount, _unlock_time);
    }

    function setAmounts(
        address[] calldata _accounts,
        uint256[] calldata _amounts,
        uint256[] calldata _unlock_times
    ) external override onlyAdmin {
        require(
            _accounts.length == _amounts.length && _accounts.length == _unlock_times.length,
            "AirdropLocked: unequal lengths"
        );
        uint256 n = _accounts.length;
        for (uint256 i = 0; i < n; i++) {
            _setAmount(_accounts[i], _amounts[i], _unlock_times[i]);
        }
    }

    function setTreasury(address _treasury) external override onlyAdmin {
        require(_treasury != address(0), "AirdropLocked: invalid address");
        treasury = _treasury;

        emit TreasurySet(treasury);
    }

    function recoverDepositedTokens() external override onlyAdmin {
        uint256 remainingAmount = totalDeposited();
        token.safeTransfer(treasury, remainingAmount);

        emit DepositedTokenRecovered(remainingAmount);
    }

    function totalDeposited() public view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function _setAmount(address account, uint256 amount, uint256 unlockTime) private {
        require(amount > 0, "AirdropLocked: invalid amount");
        LockSummary storage lockSummaries = _lockSummaries[account];
        require(lockSummaries.amount == 0, "AirdropLocked: already set");
        require(
            totalDeposited() >= totalAmountToLock + amount,
            "AirdropLock: insufficient tokens deposited"
        );
        lockSummaries.amount = amount;
        lockSummaries.unlockTime = unlockTime;
        totalAmountToLock += amount;
        _walletAddresses.push(account);

        emit LockSet(account, amount, unlockTime);
    }

    function getLockSummary(address account)
        external
        view
        override
        returns (LockSummary memory)
    {
        return _lockSummaries[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IAllocationManager.sol";
import "./interfaces/IVotingManager.sol";
import "./utils/AdminableUpgradeable.sol";

contract AllocationManager is
    AdminableUpgradeable,
    IAllocationManager,
    ERC165Upgradeable,
    UUPSUpgradeable
{
    using ERC165Checker for address;

    bytes4 public constant IID_IALLOCATIONMANAGER =
        type(IAllocationManager).interfaceId;

    address public votingManager;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _votingManager) external initializer {
        require(
            _votingManager != address(0) &&
                _votingManager.supportsInterface(
                    type(IVotingManager).interfaceId
                ),
            "AllocationM: invalid address"
        );
        __Adminable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        votingManager = _votingManager;
    }

    function setVotingManager(address _votingManager)
        external
        override
        onlyAdmin
    {
        require(
            _votingManager != address(0) &&
                _votingManager.supportsInterface(
                    type(IVotingManager).interfaceId
                ),
            "AllocationM: invalid address"
        );
        votingManager = _votingManager;

        emit VotingManagerSet(votingManager);
    }

    function getAllocationRate(uint256 rate)
        public
        pure
        override
        returns (uint256)
    {
        require(rate <= 100, "AllocationM: invalid rate");
        if (rate == 0) return 1;
        if (rate >= 80) return 100;
        return ((rate + 30)**2 + 1000) / 130;
    }

    function getAllocationRateForEpoch(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        uint256 consumptionRate = _getVotingPowerConsumptionRate(_epochId);
        return _getAllocationRate(consumptionRate);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IAllocationManager).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function _getAllocationRate(uint256 _rate) private view returns (uint256) {
        uint256 scaledRate = (100 * _rate) / _getMultiple();
        return getAllocationRate(scaledRate);
    }

    function _getMultiple() private view returns (uint256) {
        return IVotingManager(votingManager).PERCENTAGES_MULTIPLE();
    }

    // the consumption rate is rounded to 2 decimals.
    function _getVotingPowerConsumptionRate(uint256 _epochId)
        private
        view
        returns (uint256)
    {
        return
            IVotingManager(votingManager).getVotingPowerConsumptionRate(
                _epochId
            );
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal view override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IEpochManager.sol";
import "./interfaces/IVotingManager.sol";
import "./interfaces/IRewardManager.sol";
import "./interfaces/IIdeaManager.sol";
import "./interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract EpochManager is
    AdminableUpgradeable,
    IEpochManager,
    PausableUpgradeable,
    ERC165Upgradeable,
    UUPSUpgradeable
{
    using ERC165Checker for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes4 public constant IID_IEPOCHMANAGER = type(IEpochManager).interfaceId;

    address public registry;
    address public rewardManager;
    address public ideaManager;
    address public votingManager;

    uint256 public minEpochLength;
    uint256 public maxEpochLength;
    uint256 public minDurationFromNow;
    uint256 public maxNumOfIdeasPerEpoch;

    Epoch private _thisEpoch;

    Epoch[] private _epochs; // epochId -> epoch

    CountersUpgradeable.Counter private _epochCounter; // epoch counter
    EnumerableSet.UintSet private _ideaSet; // a set of active ideas in this epoch

    mapping(uint256 => IdeaIdPool) private _ideaIdPools; // epochId -> IdeaPool

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _registry) external initializer {
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );
        __Adminable_init();
        __Pausable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        registry = _registry;
        minEpochLength = 3 * 24 * 3600; // 3 days
        maxEpochLength = 30 * 24 * 3600; // 30 days
        minDurationFromNow = 300; // 5 minutes
        maxNumOfIdeasPerEpoch = 100; // At most 100 ideas per epoch

        Epoch memory zeroEpoch;
        _epochs.push(zeroEpoch); // Skipping epoch 0
    }

    function startNewEpoch(uint256[] calldata _ideaIds, uint256 _duration)
        external
        override
        onlyAdmin
        whenNotPaused
    {
        uint256 nIdeas = _ideaIds.length;
        require(
            nIdeas > 0 && nIdeas <= maxNumOfIdeasPerEpoch,
            "EpochM: invalid ideas"
        );
        require(
            _duration >= minEpochLength && _duration <= maxEpochLength,
            "EpochM: invalid duration"
        );
        require(isThisEpochEnded(), "EpochM: last epoch has not ended");
        require(_validateIdeaIds(_ideaIds), "EpochM: invalid ideas");

        if (_thisEpoch.epochId != 0) {
            _emptyIdeaSet(_thisEpoch.epochId);
        }

        _epochIdIncrement();

        _addToIdeaSet(_ideaIds);

        require(_ideaSet.length() == nIdeas, "EpochM: duplicated ideaIds");

        uint256 _epochId = getCurEpochId();

        _addIdeas(_epochId, _ideaIds);

        _thisEpoch = Epoch({
            startingTime: block.timestamp,
            endingTime: block.timestamp + _duration,
            epochId: _epochId
        });

        _onEpochStarted();

        emit EpochStarted(_epochId, nIdeas, _duration);
    }

    function updateEpoch(uint256[] calldata _ideaIds, uint256 _durationFromNow)
        external
        override
        onlyAdmin
    {
        uint256 nIdeas = _ideaIds.length;
        require(
            nIdeas > 0 && nIdeas <= maxNumOfIdeasPerEpoch,
            "EpochM: invalid ideas"
        );
        require(
            _durationFromNow >= minDurationFromNow,
            "EpochM: duration is less than minimum"
        );
        require(!isThisEpochEnded(), "EpochM: epoch already ended");
        require(_validateIdeaIds(_ideaIds), "EpochM: invalid ideas");

        uint256 _epochId = getCurEpochId();

        assert(_thisEpoch.epochId == _epochId); // note: this should never fail

        _emptyIdeaSet(_epochId);
        _addToIdeaSet(_ideaIds);

        require(
            _ideaSet.length() == _ideaIds.length,
            "EpochM: duplicated ideaIds"
        );

        delete _ideaIdPools[_epochId];
        _addIdeas(_epochId, _ideaIds);

        _thisEpoch.endingTime = block.timestamp + _durationFromNow;

        _epochs[_epochs.length - 1] = _thisEpoch;

        emit EpochUpdated(_epochId, nIdeas, _durationFromNow);
    }

    function setMinEpochLength(uint256 _minEpochLength)
        external
        override
        onlyAdmin
    {
        require(_minEpochLength > 0, "EpochM: invalid parameter");
        uint256 oldMinEpochLength = minEpochLength;
        minEpochLength = _minEpochLength;

        emit MinEpochLengthSet(oldMinEpochLength, minEpochLength);
    }

    function setMaxEpochLength(uint256 _maxEpochLength)
        external
        override
        onlyAdmin
    {
        require(_maxEpochLength > 0, "EpochM: invalid parameter");
        uint256 oldMaxEpochLength = maxEpochLength;
        maxEpochLength = _maxEpochLength;

        emit MaxEpochLengthSet(oldMaxEpochLength, maxEpochLength);
    }

    function setMaxNumOfIdeasPerEpoch(uint256 _maxNumOfIdeasPerEpoch)
        external
        override
        onlyAdmin
    {
        require(_maxNumOfIdeasPerEpoch > 0, "EpochM: invalid parameter");
        uint256 oldMaxNumOfIdeasPerEpoch = maxNumOfIdeasPerEpoch;
        maxNumOfIdeasPerEpoch = _maxNumOfIdeasPerEpoch;

        emit MaxNumOfIdeasPerEpochSet(
            oldMaxNumOfIdeasPerEpoch,
            maxNumOfIdeasPerEpoch
        );
    }

    function setMinDurationFromNow(uint256 _minDurationFromNow)
        external
        override
        onlyAdmin
    {
        require(_minDurationFromNow > 0, "EpochM: invalid parameter");
        uint256 oldMinDurationFromNow = minDurationFromNow;
        minDurationFromNow = _minDurationFromNow;

        emit MinDurationFromNowSet(oldMinDurationFromNow, minDurationFromNow);
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "EpochM: invalid Registry");
        ideaManager = IRegistry(registry).ideaManager();
        votingManager = IRegistry(registry).votingManager();
        rewardManager = IRegistry(registry).rewardManager();
        require(ideaManager != address(0), "EpochM: invalid IdeaManager");
        require(votingManager != address(0), "EpochM: invalid VotingManager");
        require(rewardManager != address(0), "EpochM: invalid RewardManager");

        emit ContractsSet(ideaManager, votingManager, rewardManager);
    }

    function pause() external override onlyAdmin {
        require(!isThisEpochEnded(), "EpochM: epoch already ended");
        _thisEpoch.endingTime = block.timestamp + 30 * 24 * 3600;
        _epochs.pop();
        _epochs.push(_thisEpoch);
        _pause();
    }

    function unpause(uint256 _duration) external override onlyAdmin {
        require(_duration > 0, "EpochM: invalid duration");
        _thisEpoch.endingTime = block.timestamp + _duration;
        _epochs.pop();
        _epochs.push(_thisEpoch);
        _unpause();
    }

    function paused()
        public
        view
        override(IEpochManager, PausableUpgradeable)
        returns (bool)
    {
        return PausableUpgradeable.paused();
    }

    function getThisEpoch() external view override returns (Epoch memory) {
        return _thisEpoch;
    }

    function epoch(uint256 _epochId)
        external
        view
        override
        returns (Epoch memory)
    {
        if (_epochId < _epochs.length) {
            return _epochs[_epochId];
        } else {
            return Epoch({startingTime: 0, endingTime: 0, epochId: _epochId});
        }
    }

    function getIdeaIds(uint256 _epochId)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _ideaIdPools[_epochId].ideaIds;
    }

    function isIdeaActive(uint256 _ideaId)
        external
        view
        override
        returns (bool)
    {
        if (_ideaId == 0) return false;
        if (_ideaId == 1) return true;
        return _ideaSet.contains(_ideaId);
    }

    function isThisEpochEnded() public view override returns (bool) {
        return _thisEpoch.endingTime < block.timestamp;
    }

    function getNumOfIdeas(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _ideaIdPools[_epochId].ideaIds.length;
    }

    function getCurEpochId() public view override returns (uint256) {
        return _epochCounter.current();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IEpochManager).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function _validateIdeaIds(uint256[] memory _ideaIds)
        private
        view
        returns (bool)
    {
        uint256 nIdeas = _ideaIds.length;
        for (uint256 i = 0; i < nIdeas; i++) {
            if (!_exists(_ideaIds[i])) {
                return false;
            } else if (_ideaIds[i] == 1) {
                return false;
            }
        }
        return true;
    }

    function _exists(uint256 _ideaId) private view returns (bool) {
        return IIdeaManager(ideaManager).exists(_ideaId);
    }

    function _emptyIdeaSet(uint256 _epochId) private {
        uint256[] memory _ideaIds = _ideaIdPools[_epochId].ideaIds;
        uint256 nIdeas = _ideaIds.length;

        for (uint256 i = 0; i < nIdeas; i++) {
            _ideaSet.remove(_ideaIds[i]);
        }

        assert(_ideaSet.length() == 0);
    }

    function _addToIdeaSet(uint256[] memory _ideaIds) private {
        uint256 nIdeas = _ideaIds.length;
        for (uint256 i = 0; i < nIdeas; i++) {
            _ideaSet.add(_ideaIds[i]);
        }
    }

    function _addIdeas(uint256 _epochId, uint256[] memory _ideaIds) private {
        uint256 nIdeas = _ideaIds.length;
        for (uint256 i = 0; i < nIdeas; i++) {
            _ideaIdPools[_epochId].ideaIds.push(_ideaIds[i]);
        }
    }

    function _onEpochStarted() private {
        IRewardManager(rewardManager).reload();
        IVotingManager(votingManager).onEpochStarted();
        _epochs.push(_thisEpoch);
    }

    function _epochIdIncrement() private {
        _epochCounter.increment();
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal view override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../../interfaces/IEpochManager.sol";
import "../../interfaces/IVeContractListener.sol";

interface IVotingManagerV2 is IVeContractListener {
    struct EpochInfo {
        uint256[] epochIds; // epochs that a voter has participated in
    }

    struct Vote {
        uint256 ideaId; // Vote for ideaId
        uint256 percentage; // % of voting power in basis points in this vote
    }

    struct Ballot {
        uint256 total; // The total amount of voting power for a ballot
        Vote[] votes; // The array of votes
    }

    /**
     * @dev Emitted when contract addresses are set.
     */
    event ContractsSet(
        address ideaManager,
        address epochManager,
        address rewardManager
    );

    /**
     * @dev Emitted when the voting power is updated for `account` to a new
     * total amount `votingPower`. This can happen when tokens are being
     * locked in the voting escrow contract.
     */
    event VotingPowerUpdated(address account, uint256 votingPower);

    /**
     * @dev Emitted when `oldVotingPowerThreshold` is replaced by a
     * new `votingPowerThreshold`.
     */
    event VotingPowerThresholdSet(
        uint256 oldVotingPowerThreshold,
        uint256 votingPowerThreshold
    );

    /**
     * @dev Emitted when `oldMaxNumOfVotesPerBallot` is replaced by a
     * new `maxNumOfVotesPerBallot`.
     */
    event MaxNumOfVotesPerBallotSet(
        uint256 oldMaxNumOfVotesPerBallot,
        uint256 maxNumOfVotesPerBallot
    );

    /**
     * @dev Emitted when `account` submits a ballot in `epochId` with
     * `nVotes` votes and a total amount of `votingPower`.
     */
    event BallotSubmitted(
        address account,
        uint256 epochId,
        Vote[] votes,
        uint256 votingPower
    );

    /**
     * @dev Emitted when the denied status for `account` is toggled.
     */
    event AccountDeniedStatusToggled(address account);

    /**
     * @dev Emitted when the total voting power is updated in `epochId`
     * to a new total amount `totalVotingPower`.
     */
    event TotalVotingPowerUpdated(uint256 epochId, uint256 totalVotingPower);

    /**
     * @dev Submits a ballot with ideas in `votes`.
     */
    function submitBallot(Vote[] memory votes) external;

    function getVoteCount(address account) external view returns (uint256);

    /**
     * @dev Calls this function when a new epoch is started to record the
     * total voting power.
     *
     * Requirements: only the EpochManager contract can call this function.
     */
    function onEpochStarted() external;

    /**
     * @dev Ends this epoch and updates the metrics for the previous epoch.
     */
    function endThisEpoch() external;

    /**
     * @dev Sets new contract addresses.
     *
     * Requirements: only the admin can call this function.
     */
    function setContracts() external;

    /**
     * @dev Sets `newThreshold` for the voting power threshold.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingPowerThreshold(uint256 newThreshold) external;

    /**
     * @dev Sets `newNumber` for the maximum number of votes permited
     * per ballot.
     *
     * Requirements: only the admin can call this function.
     */
    function setMaxNumOfVotesPerBallot(uint256 newNumber) external;

    /**
     * @dev Toggles the denied status for an `account`.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleDenied(address account) external;

    /**
     * @dev Returns the Epoch information for this epoch by reading from
     * EpochManager.
     */
    function getThisEpoch() external view returns (IEpochManager.Epoch memory);

    /**
     * @dev Returns the Ballot information for `account` in epoch with
     * `epochId`.
     */
    function getBallot(address account, uint256 epochId)
        external
        view
        returns (Ballot memory);

    /**
     * @dev Returns the array of epochIds that `account` has participated in.
     */
    function getEpochsParticipated(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the total amount of voting power that
     * `account` has allocated for the current active epoch.
     */
    function getVotingPowerForCurrentEpoch(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the system parameter `PERCENTAGES_MULTIPLE`.
     */
    function PERCENTAGES_MULTIPLE() external view returns (uint256);

    /**
     * @dev Returns the `percentage` in basis points of voting power
     * `account` has allocated in `epochId`.
     */
    function getWeightInVotingPower(address account, uint256 epochId)
        external
        view
        returns (uint256 percentage);

    /**
     * @dev Returns the amount of consumed voting power in `epochId`.
     */
    function getEpochVotingPower(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total amount of voting power available for `epochId`,
     * including the amount that has not been consumed in `epochId`.
     */
    function getTotalVotingPowerForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the voting power consumption rate for `epochId`.
     * It is calculated by comparing the consumed amount with the
     * total available amount of voting power.
     */
    function getVotingPowerConsumptionRate(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `ideaId`
     * in epoch `epochId`.
     */
    function getIdeaVotingPower(uint256 ideaId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `metaverseId`
     * in epoch `epochId`.
     */
    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns if an array of `votes` is a valid ballot.
     */
    function isValidBallot(Vote[] memory votes) external returns (bool);

    /**
     * @dev Returns if `voter` is denied from voting.
     */
    function isDenied(address voter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../../interfaces/IEpochManager.sol";
import "../../interfaces/IVeContractListener.sol";

interface IVotingManagerV3 is IVeContractListener {
    struct EpochInfo {
        uint256[] epochIds; // epochs that a voter has participated in
    }

    struct Vote {
        uint256 ideaId; // Vote for ideaId
        uint256 percentage; // % of voting power in basis points in this vote
    }

    struct Ballot {
        uint256 total; // The total amount of voting power for a ballot
        Vote[] votes; // The array of votes
    }

    /**
     * @dev Emitted when contract addresses are set.
     */
    event ContractsSet(
        address ideaManager,
        address epochManager,
        address rewardManager
    );

    /**
     * @dev Emitted when the voting power is updated for `account` to a new
     * total amount `votingPower`. This can happen when tokens are being
     * locked in the voting escrow contract.
     */
    event VotingPowerUpdated(address account, uint256 votingPower);

    /**
     * @dev Emitted when `oldVotingPowerThreshold` is replaced by a
     * new `votingPowerThreshold`.
     */
    event VotingPowerThresholdSet(
        uint256 oldVotingPowerThreshold,
        uint256 votingPowerThreshold
    );

    /**
     * @dev Emitted when `oldMaxNumOfVotesPerBallot` is replaced by a
     * new `maxNumOfVotesPerBallot`.
     */
    event MaxNumOfVotesPerBallotSet(
        uint256 oldMaxNumOfVotesPerBallot,
        uint256 maxNumOfVotesPerBallot
    );

    /**
     * @dev Emitted when `account` submits a ballot in `epochId` with
     * `nVotes` votes and a total amount of `votingPower`.
     */
    event BallotSubmitted(
        address account,
        uint256 epochId,
        Vote[] votes,
        uint256 votingPower
    );

    /**
     * @dev Emitted when the denied status for `account` is toggled.
     */
    event AccountDeniedStatusToggled(address account);

    /**
     * @dev Emitted when the total voting power is updated in `epochId`
     * to a new total amount `totalVotingPower`.
     */
    event TotalVotingPowerUpdated(uint256 epochId, uint256 totalVotingPower);

    /**
     * @dev Submits a ballot with ideas in `votes`.
     */
    function submitBallot(Vote[] memory votes) external;

    /**
     * @dev Calls this function when a new epoch is started to record the
     * total voting power.
     *
     * Requirements: only the EpochManager contract can call this function.
     */
    function onEpochStarted() external;

    /**
     * @dev Ends this epoch and updates the metrics for the previous epoch.
     */
    function endThisEpoch() external;

    /**
     * @dev Sets new contract addresses.
     *
     * Requirements: only the admin can call this function.
     */
    function setContracts() external;

    /**
     * @dev Sets `newThreshold` for the voting power threshold.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingPowerThreshold(uint256 newThreshold) external;

    /**
     * @dev Sets `newNumber` for the maximum number of votes permited
     * per ballot.
     *
     * Requirements: only the admin can call this function.
     */
    function setMaxNumOfVotesPerBallot(uint256 newNumber) external;

    /**
     * @dev Toggles the denied status for an `account`.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleDenied(address account) external;

    /**
     * @dev Returns the Epoch information for this epoch by reading from
     * EpochManager.
     */
    function getThisEpoch() external view returns (IEpochManager.Epoch memory);

    /**
     * @dev Returns the Ballot information for `account` in epoch with
     * `epochId`.
     */
    function getBallot(address account, uint256 epochId)
        external
        view
        returns (Ballot memory);

    /**
     * @dev Returns the array of epochIds that `account` has participated in.
     */
    function getEpochsParticipated(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the total amount of voting power that
     * `account` has allocated for the current active epoch.
     */
    function getVotingPowerForCurrentEpoch(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the system parameter `PERCENTAGES_MULTIPLE`.
     */
    function PERCENTAGES_MULTIPLE() external view returns (uint256);

    /**
     * @dev Returns the `percentage` in basis points of voting power
     * `account` has allocated in `epochId`.
     */
    function getWeightInVotingPower(address account, uint256 epochId)
        external
        view
        returns (uint256 percentage);

    /**
     * @dev Returns the amount of consumed voting power in `epochId`.
     */
    function getEpochVotingPower(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total amount of voting power available for `epochId`,
     * including the amount that has not been consumed in `epochId`.
     */
    function getTotalVotingPowerForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the voting power consumption rate for `epochId`.
     * It is calculated by comparing the consumed amount with the
     * total available amount of voting power.
     */
    function getVotingPowerConsumptionRate(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `ideaId`
     * in epoch `epochId`.
     */
    function getIdeaVotingPower(uint256 ideaId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `metaverseId`
     * in epoch `epochId`.
     */
    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns if an array of `votes` is a valid ballot.
     */
    function isValidBallot(Vote[] memory votes) external returns (bool);

    /**
     * @dev Returns if `voter` is denied from voting.
     */
    function isDenied(address voter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../../interfaces/IEpochManager.sol";
import "../../interfaces/IVeContractListener.sol";

interface IVotingManagerV5 is IVeContractListener {
    struct EpochInfo {
        uint256[] epochIds; // epochs that a voter has participated in
    }

    struct Vote {
        uint256 ideaId; // Vote for ideaId
        uint256 percentage; // % of voting power in basis points in this vote
    }

    struct Ballot {
        uint256 total; // The total amount of voting power for a ballot
        Vote[] votes; // The array of votes
    }

    /**
     * @dev Emitted when contract addresses are set.
     */
    event ContractsSet(
        address ideaManager,
        address epochManager,
        address rewardManager
    );

    /**
     * @dev Emitted when the voting power is updated for `account` to a new
     * total amount `votingPower`. This can happen when tokens are being
     * locked in the voting escrow contract.
     */
    event VotingPowerUpdated(address account, uint256 votingPower);

    /**
     * @dev Emitted when `oldVotingPowerThreshold` is replaced by a
     * new `votingPowerThreshold`.
     */
    event VotingPowerThresholdSet(
        uint256 oldVotingPowerThreshold,
        uint256 votingPowerThreshold
    );

    /**
     * @dev Emitted when `oldMaxNumOfVotesPerBallot` is replaced by a
     * new `maxNumOfVotesPerBallot`.
     */
    event MaxNumOfVotesPerBallotSet(
        uint256 oldMaxNumOfVotesPerBallot,
        uint256 maxNumOfVotesPerBallot
    );

    /**
     * @dev Emitted when `account` submits a ballot in `epochId` with
     * `nVotes` votes and a total amount of `votingPower`.
     */
    event BallotSubmitted(
        address account,
        uint256 epochId,
        Vote[] votes,
        uint256 votingPower
    );

    /**
     * @dev Emitted when the denied status for `account` is toggled.
     */
    event AccountDeniedStatusToggled(address account);

    /**
     * @dev Emitted when the total voting power is updated in `epochId`
     * to a new total amount `totalVotingPower`.
     */
    event TotalVotingPowerUpdated(uint256 epochId, uint256 totalVotingPower);

    /**
     * @dev Emitted when upgradeability status is toggled.
     */
    event UpgradeabilityStatusToggled(bool upgradeabilityStatus);

    /**
     * @dev Submits a ballot with ideas in `votes`.
     */
    function submitBallot(Vote[] memory votes) external;

    /**
     * @dev Calls this function when a new epoch is started to record the
     * total voting power.
     *
     * Requirements: only the EpochManager contract can call this function.
     */
    function onEpochStarted() external;

    /**
     * @dev Ends this epoch and updates the metrics for the previous epoch.
     */
    function endThisEpoch() external;

    /**
     * @dev Sets new contract addresses.
     *
     * Requirements: only the admin can call this function.
     */
    function setContracts() external;

    /**
     * @dev Sets `newThreshold` for the voting power threshold.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingPowerThreshold(uint256 newThreshold) external;

    /**
     * @dev Sets `newNumber` for the maximum number of votes permited
     * per ballot.
     *
     * Requirements: only the admin can call this function.
     */
    function setMaxNumOfVotesPerBallot(uint256 newNumber) external;

    /**
     * @dev Toggles the denied status for an `account`.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleDenied(address account) external;

    /**
     * @dev Toggles the upgradeability.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleUpgradeability() external;

    /**
     * @dev Returns the Epoch information for this epoch by reading from
     * EpochManager.
     */
    function getThisEpoch() external view returns (IEpochManager.Epoch memory);

    /**
     * @dev Returns the Ballot information for `account` in epoch with
     * `epochId`.
     */
    function getBallot(address account, uint256 epochId)
        external
        view
        returns (Ballot memory);

    /**
     * @dev Returns the array of epochIds that `account` has participated in.
     */
    function getEpochsParticipated(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the total amount of voting power that
     * `account` has allocated for the current active epoch.
     */
    function getVotingPowerForCurrentEpoch(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the system parameter `PERCENTAGES_MULTIPLE`.
     */
    function PERCENTAGES_MULTIPLE() external view returns (uint256);

    /**
     * @dev Returns the `percentage` in basis points of voting power
     * `account` has allocated in `epochId`.
     */
    function getWeightInVotingPower(address account, uint256 epochId)
        external
        view
        returns (uint256 percentage);

    /**
     * @dev Returns the amount of consumed voting power in `epochId`.
     */
    function getEpochVotingPower(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total amount of voting power available for `epochId`,
     * including the amount that has not been consumed in `epochId`.
     */
    function getTotalVotingPowerForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the voting power consumption rate for `epochId`.
     * It is calculated by comparing the consumed amount with the
     * total available amount of voting power.
     */
    function getVotingPowerConsumptionRate(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `ideaId`
     * in epoch `epochId`.
     */
    function getIdeaVotingPower(uint256 ideaId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `metaverseId`
     * in epoch `epochId`.
     */
    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns if an array of `votes` is a valid ballot.
     */
    function isValidBallot(Vote[] memory votes) external returns (bool);

    /**
     * @dev Returns if `voter` is denied from voting.
     */
    function isDenied(address voter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./interfaces/IVotingManagerV3.sol";
import "../interfaces/IIdeaManager.sol";
import "../interfaces/IRewardManager.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract ToyVotingManagerV2 is
    AdminableUpgradeable,
    IVotingManagerV3,
    ERC165Upgradeable
{
    using ERC165Checker for address;

    bytes4 public constant IID_IVOTINGMANAGERV2 =
        type(IVotingManagerV3).interfaceId;

    address public registry;
    address public veContract; // voting escrow contract
    address public epochManager;
    address public ideaManager;
    address public rewardManager;

    uint256 public constant PERCENTAGES_DECIMALS = 9;
    uint256 public constant PERCENTAGES_MULTIPLE = 1e9; // max decimals the protocol can do
    uint256 public votingPowerThreshold; // minimum amount of voting power needed to submit a ballot
    uint256 public maxNumOfVotesPerBallot; // maximum number of votes in a ballot

    mapping(address => mapping(uint256 => Ballot)) private _epochBallots; // votes over epochs
    mapping(address => EpochInfo) private _epochParticipated; // epochs a voter has participated in
    mapping(uint256 => uint256) private _epochVotingPower; // epochId => consumed voting power
    mapping(uint256 => uint256) private _epochTotalVotingPower; // epochId => consumed voting power
    mapping(uint256 => mapping(uint256 => uint256)) private _ideaVotingPower; // ideaId => epochId => voting power
    mapping(uint256 => mapping(uint256 => uint256))
        private _metaverseVotingPower; // metaverseId => epochId => voting power
    mapping(address => bool) private _deniedList; // Denied list of voters

    function initialize(address _veContract, address _registry)
        external
        initializer
    {
        require(_veContract != address(0), "VotingM: invalid address");
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );

        __Adminable_init();
        __ERC165_init();

        veContract = _veContract;
        registry = _registry;
        votingPowerThreshold = 5e14;
        maxNumOfVotesPerBallot = 20;
    }

    modifier onlyVeContract() {
        require(_msgSender() == veContract, "VotingM: only VeContract");
        _;
    }

    modifier onlyEpochManager() {
        require(_msgSender() == epochManager, "VotingM: only EpochManager");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused(), "VotingM: paused");
        _;
    }

    function submitBallot(Vote[] memory _votes)
        external
        override
        whenNotPaused
    {
        require(!_isThisEpochEnded(), "VotingM: epoch already over");
        require(_isValidBallot(_votes), "VotingM: invalid ballot");
        address _voter = _msgSender();
        require(!isDenied(_voter), "VotingM: voter is denied");
        uint256 _total = getVotingPowerForCurrentEpoch(_voter);
        require(
            _total > votingPowerThreshold,
            "VotingM: not reaching threshold"
        );

        uint256 _epochId = getThisEpoch().epochId;
        // If user has already voted in this epoch, we need to "rewind" their
        // previous ballot before submitting the new one
        if (_epochBallots[_voter][_epochId].total > 0) {
            _rewind(_voter);
        }

        _epochBallots[_voter][_epochId].total = _total;
        _epochVotingPower[_epochId] += _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        for (uint256 i = 0; i < _votes.length; i++) {
            _ideaId = _votes[i].ideaId;
            _ideaPercentage = _votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _epochBallots[_voter][_epochId].votes.push(_votes[i]);
            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] += _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] += _powerAllocatedToThisProposal;
        }

        uint256 nEpochs = _epochParticipated[_voter].epochIds.length;
        if (nEpochs == 0) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        } else if (
            _epochParticipated[_voter].epochIds[nEpochs - 1] < _epochId
        ) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        }

        emit BallotSubmitted(_voter, _epochId, _votes, _total);
    }

    function onVotingPowerUpdated(address account)
        external
        override
        onlyVeContract
    {
        _onVotingPowerUpdated(account);
    }

    function onEpochStarted() external override onlyEpochManager {
        uint256 _epochId = IEpochManager(epochManager).getCurEpochId();
        uint256 totalVotingPower = IVotingEscrow(veContract).totalSupply();
        _epochTotalVotingPower[_epochId] = totalVotingPower;

        emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
    }

    function endThisEpoch() external override {
        uint256 _epochId = getThisEpoch().epochId;
        if (_epochId > 0) {
            if (_isThisEpochEnded()) {
                IRewardManager(rewardManager).onEpochEnded();
            }
        }
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "VotingM: invalid Registry");
        ideaManager = IRegistry(registry).ideaManager();
        epochManager = IRegistry(registry).epochManager();
        rewardManager = IRegistry(registry).rewardManager();
        require(ideaManager != address(0), "VotingM: invalid IdeaManager");
        require(epochManager != address(0), "VotingM: invalid EpochManager");
        require(rewardManager != address(0), "VotingM: invalid RewardManager");

        emit ContractsSet(ideaManager, epochManager, rewardManager);
    }

    function setVotingPowerThreshold(uint256 _newThreshold)
        external
        override
        onlyAdmin
    {
        require(_newThreshold > 0, "VotingM: invalid threshold");
        uint256 oldThreshold = votingPowerThreshold;
        votingPowerThreshold = _newThreshold;

        emit VotingPowerThresholdSet(oldThreshold, votingPowerThreshold);
    }

    function setMaxNumOfVotesPerBallot(uint256 _newNumber)
        external
        override
        onlyAdmin
    {
        require(_newNumber > 0, "VotingM: invalid number");
        uint256 oldNumber = maxNumOfVotesPerBallot;
        maxNumOfVotesPerBallot = _newNumber;

        emit MaxNumOfVotesPerBallotSet(oldNumber, maxNumOfVotesPerBallot);
    }

    function toggleDenied(address account) external override onlyAdmin {
        require(account != address(0), "VotingM: invalid address");
        _deniedList[account] = !_deniedList[account];

        emit AccountDeniedStatusToggled(account);
    }

    function getThisEpoch()
        public
        view
        override
        returns (IEpochManager.Epoch memory)
    {
        return IEpochManager(epochManager).getThisEpoch();
    }

    function getBallot(address account, uint256 _epochId)
        external
        view
        override
        returns (Ballot memory)
    {
        return _epochBallots[account][_epochId];
    }

    function getEpochsParticipated(address account)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _epochParticipated[account].epochIds;
    }

    function getWeightInVotingPower(address account, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        uint256 accountVotingPower = _epochBallots[account][_epochId].total;
        uint256 epochTotalVotingPower = _epochVotingPower[_epochId];

        if (epochTotalVotingPower != 0) {
            return
                (PERCENTAGES_MULTIPLE * accountVotingPower) /
                epochTotalVotingPower;
        } else {
            return 0;
        }
    }

    function getIdeaVotingPower(uint256 _ideaId, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _ideaVotingPower[_ideaId][_epochId];
    }

    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        override
        returns (uint256)
    {
        return _metaverseVotingPower[metaverseId][epochId];
    }

    function getEpochVotingPower(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _epochVotingPower[_epochId];
    }

    function getVotingPowerForCurrentEpoch(address account)
        public
        view
        override
        returns (uint256)
    {
        return
            IVotingEscrow(veContract).balanceOf(
                account,
                getThisEpoch().startingTime
            );
    }

    function getTotalVotingPowerForEpoch(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        return _epochTotalVotingPower[_epochId];
    }

    function getVotingPowerConsumptionRate(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        uint256 consumedVotingPower = _epochVotingPower[_epochId];
        uint256 totalVotingPower = _epochTotalVotingPower[_epochId];

        if (totalVotingPower > 0) {
            return
                (PERCENTAGES_MULTIPLE * consumedVotingPower) / totalVotingPower;
        } else {
            return 0;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == this.onVotingPowerUpdated.selector ||
            interfaceId == type(IVotingManagerV3).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function isValidBallot(Vote[] memory _votes)
        external
        view
        override
        returns (bool)
    {
        return _isValidBallot(_votes);
    }

    function isDenied(address voter) public view override returns (bool) {
        return _deniedList[voter];
    }

    function _onVotingPowerUpdated(address account) private {
        uint256 _epochId = getThisEpoch().epochId;

        if (!_isThisEpochEnded()) {
            if (_epochBallots[account][_epochId].total > 0) {
                uint256 _total = getVotingPowerForCurrentEpoch(account);
                _update(account);
                _epochBallots[account][_epochId].total = _total;

                emit VotingPowerUpdated(account, _total);
            }

            uint256 totalVotingPower = _getTotalVotingPowerFromVotingEscrowForThisEpoch();
            _epochTotalVotingPower[_epochId] = totalVotingPower;

            emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
        }
    }

    function _isValidBallot(Vote[] memory _votes) private view returns (bool) {
        uint256 nVotes = _votes.length;
        // If a user chooses to abstain, that is still represented as
        // a single vote for voteID `1` ("no proposal")
        if (nVotes == 0) return false;
        if (nVotes > maxNumOfVotesPerBallot) return false;

        uint256 totalPercentage;
        uint256 _ideaId;

        for (uint256 i = 0; i < nVotes; i++) {
            if (i == 0) {
                _ideaId = _votes[i].ideaId;
                if (!_isValidIdea(_ideaId)) {
                    return false;
                }
                totalPercentage = _votes[i].percentage;
            } else {
                uint256 _nextIdeaId = _votes[i].ideaId;
                if (_nextIdeaId <= _ideaId) {
                    return false;
                }
                if (!_isValidIdea(_nextIdeaId)) {
                    return false;
                }
                _ideaId = _nextIdeaId;
                totalPercentage += _votes[i].percentage;
            }
        }

        if (totalPercentage != PERCENTAGES_MULTIPLE) return false; // A valid ballot has 100%

        return true;
    }

    // precondition: caller has verified that _voter has previously cast a
    // ballot in this epoch
    function _rewind(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        _epochVotingPower[_epochId] -= _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
        }

        delete _epochBallots[_voter][_epochId];
    }

    function _update(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        uint256 _newTotal = getVotingPowerForCurrentEpoch(_voter);
        bool _isLarger = _newTotal > _total;
        uint256 _diff = _isLarger ? _newTotal - _total : _total - _newTotal;
        if (_isLarger) {
            _epochVotingPower[_epochId] += _diff;
        } else {
            _epochVotingPower[_epochId] -= _diff;
        }

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _metaverseId;
        uint256 _diffPower;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);
            _diffPower = (_diff * _ideaPercentage) / PERCENTAGES_MULTIPLE;

            if (_isLarger) {
                _ideaVotingPower[_ideaId][_epochId] += _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] += _diffPower;
            } else {
                _ideaVotingPower[_ideaId][_epochId] -= _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] -= _diffPower;
            }
        }
    }

    function _getTotalVotingPowerFromVotingEscrowForThisEpoch()
        private
        view
        returns (uint256)
    {
        uint256 startingTime = getThisEpoch().startingTime;
        return IVotingEscrow(veContract).totalSupply(startingTime);
    }

    function _isValidIdea(uint256 _ideaId) private view returns (bool) {
        if (_ideaId == 0) return false; // ideaId 0 always returns false.
        if (_ideaId == 1) return true; // ideaId 1 always returns true.
        bool cond1 = _exists(_ideaId);
        bool cond2 = _isIdeaActive(_ideaId);
        return cond1 && cond2;
    }

    function _isThisEpochEnded() private view returns (bool) {
        return IEpochManager(epochManager).isThisEpochEnded();
    }

    function _exists(uint256 ideaId) private view returns (bool) {
        return IIdeaManager(ideaManager).exists(ideaId);
    }

    function _isIdeaActive(uint256 _ideaId) private view returns (bool) {
        return IEpochManager(epochManager).isIdeaActive(_ideaId);
    }

    function _getMetaverseId(uint256 _ideaId) private view returns (uint256) {
        return IIdeaManager(ideaManager).getIdeaInfo(_ideaId).idea.metaverseId;
    }

    function _paused() private view returns (bool) {
        return IEpochManager(epochManager).paused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IVotingManagerV3.sol";
import "../interfaces/IIdeaManager.sol";
import "../interfaces/IRewardManager.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract ToyVotingManagerV3 is
    AdminableUpgradeable,
    IVotingManagerV3,
    ERC165Upgradeable,
    UUPSUpgradeable
{
    using ERC165Checker for address;

    bytes4 public constant IID_IVOTINGMANAGERV2 =
        type(IVotingManagerV3).interfaceId;

    address public registry;
    address public veContract; // voting escrow contract
    address public epochManager;
    address public ideaManager;
    address public dummyManager;
    address public rewardManager;

    uint256 public constant PERCENTAGES_DECIMALS = 9;
    uint256 public constant PERCENTAGES_MULTIPLE = 1e9; // max decimals the protocol can do
    uint256 public votingPowerThreshold; // minimum amount of voting power needed to submit a ballot
    uint256 public maxNumOfVotesPerBallot; // maximum number of votes in a ballot

    mapping(address => mapping(uint256 => Ballot)) private _epochBallots; // votes over epochs
    mapping(address => EpochInfo) private _epochParticipated; // epochs a voter has participated in
    mapping(uint256 => uint256) private _epochVotingPower; // epochId => consumed voting power
    mapping(uint256 => uint256) private _epochTotalVotingPower; // epochId => consumed voting power
    mapping(uint256 => mapping(uint256 => uint256)) private _ideaVotingPower; // ideaId => epochId => voting power
    mapping(uint256 => mapping(uint256 => uint256))
        private _metaverseVotingPower; // metaverseId => epochId => voting power
    mapping(address => bool) private _deniedList; // Denied list of voters

    function initialize(address _veContract, address _registry)
        external
        initializer
    {
        require(_veContract != address(0), "VotingM: invalid address");
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );

        __Adminable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        veContract = _veContract;
        registry = _registry;
        votingPowerThreshold = 5e14;
        maxNumOfVotesPerBallot = 20;
    }

    modifier onlyVeContract() {
        require(_msgSender() == veContract, "VotingM: only VeContract");
        _;
    }

    modifier onlyEpochManager() {
        require(_msgSender() == epochManager, "VotingM: only EpochManager");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused(), "VotingM: paused");
        _;
    }

    function submitBallot(Vote[] memory _votes)
        external
        override
        whenNotPaused
    {
        require(!_isThisEpochEnded(), "VotingM: epoch already over");
        require(_isValidBallot(_votes), "VotingM: invalid ballot");
        address _voter = _msgSender();
        require(!isDenied(_voter), "VotingM: voter is denied");
        uint256 _total = getVotingPowerForCurrentEpoch(_voter);
        require(
            _total > votingPowerThreshold,
            "VotingM: not reaching threshold"
        );

        uint256 _epochId = getThisEpoch().epochId;
        // If user has already voted in this epoch, we need to "rewind" their
        // previous ballot before submitting the new one
        if (_epochBallots[_voter][_epochId].total > 0) {
            _rewind(_voter);
        }

        _epochBallots[_voter][_epochId].total = _total;
        _epochVotingPower[_epochId] += _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        for (uint256 i = 0; i < _votes.length; i++) {
            _ideaId = _votes[i].ideaId;
            _ideaPercentage = _votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _epochBallots[_voter][_epochId].votes.push(_votes[i]);
            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] += _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] += _powerAllocatedToThisProposal;
        }

        uint256 nEpochs = _epochParticipated[_voter].epochIds.length;
        if (nEpochs == 0) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        } else if (
            _epochParticipated[_voter].epochIds[nEpochs - 1] < _epochId
        ) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        }

        emit BallotSubmitted(_voter, _epochId, _votes, _total);
    }

    function onVotingPowerUpdated(address account)
        external
        override
        onlyVeContract
    {
        _onVotingPowerUpdated(account);
    }

    function onEpochStarted() external override onlyEpochManager {
        uint256 _epochId = IEpochManager(epochManager).getCurEpochId();
        uint256 totalVotingPower = IVotingEscrow(veContract).totalSupply();
        _epochTotalVotingPower[_epochId] = totalVotingPower;

        emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
    }

    function endThisEpoch() external override {
        uint256 _epochId = getThisEpoch().epochId;
        if (_epochId > 0) {
            if (_isThisEpochEnded()) {
                IRewardManager(rewardManager).onEpochEnded();
            }
        }
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "VotingM: invalid Registry");
        ideaManager = IRegistry(registry).ideaManager();
        epochManager = IRegistry(registry).epochManager();
        rewardManager = IRegistry(registry).rewardManager();
        require(ideaManager != address(0), "VotingM: invalid IdeaManager");
        require(epochManager != address(0), "VotingM: invalid EpochManager");
        require(rewardManager != address(0), "VotingM: invalid RewardManager");

        emit ContractsSet(ideaManager, epochManager, rewardManager);
    }

    function setVotingPowerThreshold(uint256 _newThreshold)
        external
        override
        onlyAdmin
    {
        require(_newThreshold > 0, "VotingM: invalid threshold");
        uint256 oldThreshold = votingPowerThreshold;
        votingPowerThreshold = _newThreshold;

        emit VotingPowerThresholdSet(oldThreshold, votingPowerThreshold);
    }

    function setMaxNumOfVotesPerBallot(uint256 _newNumber)
        external
        override
        onlyAdmin
    {
        require(_newNumber > 0, "VotingM: invalid number");
        uint256 oldNumber = maxNumOfVotesPerBallot;
        maxNumOfVotesPerBallot = _newNumber;

        emit MaxNumOfVotesPerBallotSet(oldNumber, maxNumOfVotesPerBallot);
    }

    function toggleDenied(address account) external override onlyAdmin {
        require(account != address(0), "VotingM: invalid address");
        _deniedList[account] = !_deniedList[account];

        emit AccountDeniedStatusToggled(account);
    }

    function getThisEpoch()
        public
        view
        override
        returns (IEpochManager.Epoch memory)
    {
        return IEpochManager(epochManager).getThisEpoch();
    }

    function getBallot(address account, uint256 _epochId)
        external
        view
        override
        returns (Ballot memory)
    {
        return _epochBallots[account][_epochId];
    }

    function getEpochsParticipated(address account)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _epochParticipated[account].epochIds;
    }

    function getWeightInVotingPower(address account, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        uint256 accountVotingPower = _epochBallots[account][_epochId].total;
        uint256 epochTotalVotingPower = _epochVotingPower[_epochId];

        if (epochTotalVotingPower != 0) {
            return
                (PERCENTAGES_MULTIPLE * accountVotingPower) /
                epochTotalVotingPower;
        } else {
            return 0;
        }
    }

    function getIdeaVotingPower(uint256 _ideaId, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _ideaVotingPower[_ideaId][_epochId];
    }

    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        override
        returns (uint256)
    {
        return _metaverseVotingPower[metaverseId][epochId];
    }

    function getEpochVotingPower(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _epochVotingPower[_epochId];
    }

    function getVotingPowerForCurrentEpoch(address account)
        public
        view
        override
        returns (uint256)
    {
        return
            IVotingEscrow(veContract).balanceOf(
                account,
                getThisEpoch().startingTime
            );
    }

    function getTotalVotingPowerForEpoch(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        return _epochTotalVotingPower[_epochId];
    }

    function getVotingPowerConsumptionRate(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        uint256 consumedVotingPower = _epochVotingPower[_epochId];
        uint256 totalVotingPower = _epochTotalVotingPower[_epochId];

        if (totalVotingPower > 0) {
            return
                (PERCENTAGES_MULTIPLE * consumedVotingPower) / totalVotingPower;
        } else {
            return 0;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == this.onVotingPowerUpdated.selector ||
            interfaceId == type(IVotingManagerV3).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function isValidBallot(Vote[] memory _votes)
        external
        view
        override
        returns (bool)
    {
        return _isValidBallot(_votes);
    }

    function isDenied(address voter) public view override returns (bool) {
        return _deniedList[voter];
    }

    function _onVotingPowerUpdated(address account) private {
        uint256 _epochId = getThisEpoch().epochId;

        if (!_isThisEpochEnded()) {
            if (_epochBallots[account][_epochId].total > 0) {
                uint256 _total = getVotingPowerForCurrentEpoch(account);
                _update(account);
                _epochBallots[account][_epochId].total = _total;

                emit VotingPowerUpdated(account, _total);
            }

            uint256 totalVotingPower = _getTotalVotingPowerFromVotingEscrowForThisEpoch();
            _epochTotalVotingPower[_epochId] = totalVotingPower;

            emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
        }
    }

    function _isValidBallot(Vote[] memory _votes) private view returns (bool) {
        uint256 nVotes = _votes.length;
        // If a user chooses to abstain, that is still represented as
        // a single vote for voteID `1` ("no proposal")
        if (nVotes == 0) return false;
        if (nVotes > maxNumOfVotesPerBallot) return false;

        uint256 totalPercentage;
        uint256 _ideaId;

        for (uint256 i = 0; i < nVotes; i++) {
            if (i == 0) {
                _ideaId = _votes[i].ideaId;
                if (!_isValidIdea(_ideaId)) {
                    return false;
                }
                totalPercentage = _votes[i].percentage;
            } else {
                uint256 _nextIdeaId = _votes[i].ideaId;
                if (_nextIdeaId <= _ideaId) {
                    return false;
                }
                if (!_isValidIdea(_nextIdeaId)) {
                    return false;
                }
                _ideaId = _nextIdeaId;
                totalPercentage += _votes[i].percentage;
            }
        }

        if (totalPercentage != PERCENTAGES_MULTIPLE) return false; // A valid ballot has 100%

        return true;
    }

    // precondition: caller has verified that _voter has previously cast a
    // ballot in this epoch
    function _rewind(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        _epochVotingPower[_epochId] -= _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
        }

        delete _epochBallots[_voter][_epochId];
    }

    function _update(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        uint256 _newTotal = getVotingPowerForCurrentEpoch(_voter);
        bool _isLarger = _newTotal > _total;
        uint256 _diff = _isLarger ? _newTotal - _total : _total - _newTotal;
        if (_isLarger) {
            _epochVotingPower[_epochId] += _diff;
        } else {
            _epochVotingPower[_epochId] -= _diff;
        }

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _metaverseId;
        uint256 _diffPower;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);
            _diffPower = (_diff * _ideaPercentage) / PERCENTAGES_MULTIPLE;

            if (_isLarger) {
                _ideaVotingPower[_ideaId][_epochId] += _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] += _diffPower;
            } else {
                _ideaVotingPower[_ideaId][_epochId] -= _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] -= _diffPower;
            }
        }
    }

    function _getTotalVotingPowerFromVotingEscrowForThisEpoch()
        private
        view
        returns (uint256)
    {
        uint256 startingTime = getThisEpoch().startingTime;
        return IVotingEscrow(veContract).totalSupply(startingTime);
    }

    function _isValidIdea(uint256 _ideaId) private view returns (bool) {
        if (_ideaId == 0) return false; // ideaId 0 always returns false.
        if (_ideaId == 1) return true; // ideaId 1 always returns true.
        bool cond1 = _exists(_ideaId);
        bool cond2 = _isIdeaActive(_ideaId);
        return cond1 && cond2;
    }

    function _isThisEpochEnded() private view returns (bool) {
        return IEpochManager(epochManager).isThisEpochEnded();
    }

    function _exists(uint256 ideaId) private view returns (bool) {
        return IIdeaManager(ideaManager).exists(ideaId);
    }

    function _isIdeaActive(uint256 _ideaId) private view returns (bool) {
        return IEpochManager(epochManager).isIdeaActive(_ideaId);
    }

    function _getMetaverseId(uint256 _ideaId) private view returns (uint256) {
        return IIdeaManager(ideaManager).getIdeaInfo(_ideaId).idea.metaverseId;
    }

    function _paused() private view returns (bool) {
        return IEpochManager(epochManager).paused();
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IVotingManagerV3.sol";
import "../interfaces/IIdeaManager.sol";
import "../interfaces/IRewardManager.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract ToyVotingManagerV4 is
    AdminableUpgradeable,
    IVotingManagerV3,
    ERC165Upgradeable,
    UUPSUpgradeable
{
    using ERC165Checker for address;

    bytes4 public constant IID_IVOTINGMANAGERV3 =
        type(IVotingManagerV3).interfaceId;

    function doNothing() external view {
        require(_msgSender() != address(0), "This function does nothing");
    }

    address public registry;
    address public veContract; // voting escrow contract
    address public epochManager;
    address public ideaManager;
    address public rewardManager;

    uint256 public constant PERCENTAGES_DECIMALS = 9;
    uint256 public constant PERCENTAGES_MULTIPLE = 1e9; // max decimals the protocol can do
    uint128 public votingPowerThreshold; // minimum amount of voting power needed to submit a ballot
    uint128 public maxNumOfVotesPerBallot; // maximum number of votes in a ballot

    mapping(address => mapping(uint256 => Ballot)) private _epochBallots; // votes over epochs
    mapping(address => EpochInfo) private _epochParticipated; // epochs a voter has participated in
    mapping(uint256 => uint256) private _epochVotingPower; // epochId => consumed voting power
    mapping(uint256 => uint256) private _epochTotalVotingPower; // epochId => consumed voting power
    mapping(uint256 => mapping(uint256 => uint256)) private _ideaVotingPower; // ideaId => epochId => voting power
    mapping(uint256 => mapping(uint256 => uint256))
        private _metaverseVotingPower; // metaverseId => epochId => voting power
    mapping(address => bool) private _deniedList; // Denied list of voters

    function initialize(address _veContract, address _registry)
        external
        initializer
    {
        require(_veContract != address(0), "VotingM: invalid address");
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );

        __Adminable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        veContract = _veContract;
        registry = _registry;
        votingPowerThreshold = 5e14;
        maxNumOfVotesPerBallot = 20;
    }

    modifier onlyVeContract() {
        require(_msgSender() == veContract, "VotingM: only VeContract");
        _;
    }

    modifier onlyEpochManager() {
        require(_msgSender() == epochManager, "VotingM: only EpochManager");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused(), "VotingM: paused");
        _;
    }

    function submitBallot(Vote[] memory _votes)
        external
        override
        whenNotPaused
    {
        require(!_isThisEpochEnded(), "VotingM: epoch already over");
        require(_isValidBallot(_votes), "VotingM: invalid ballot");
        address _voter = _msgSender();
        require(!isDenied(_voter), "VotingM: voter is denied");
        uint256 _total = getVotingPowerForCurrentEpoch(_voter);
        require(
            _total > votingPowerThreshold,
            "VotingM: not reaching threshold"
        );

        uint256 _epochId = getThisEpoch().epochId;
        // If user has already voted in this epoch, we need to "rewind" their
        // previous ballot before submitting the new one
        if (_epochBallots[_voter][_epochId].total > 0) {
            _rewind(_voter);
        }

        _epochBallots[_voter][_epochId].total = _total;
        _epochVotingPower[_epochId] += _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        for (uint256 i = 0; i < _votes.length; i++) {
            _ideaId = _votes[i].ideaId;
            _ideaPercentage = _votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _epochBallots[_voter][_epochId].votes.push(_votes[i]);
            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] += _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] += _powerAllocatedToThisProposal;
        }

        uint256 nEpochs = _epochParticipated[_voter].epochIds.length;
        if (nEpochs == 0) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        } else if (
            _epochParticipated[_voter].epochIds[nEpochs - 1] < _epochId
        ) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        }

        emit BallotSubmitted(_voter, _epochId, _votes, _total);
    }

    function onVotingPowerUpdated(address account)
        external
        override
        onlyVeContract
    {
        _onVotingPowerUpdated(account);
    }

    function onEpochStarted() external override onlyEpochManager {
        uint256 _epochId = IEpochManager(epochManager).getCurEpochId();
        uint256 totalVotingPower = IVotingEscrow(veContract).totalSupply();
        _epochTotalVotingPower[_epochId] = totalVotingPower;

        emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
    }

    function endThisEpoch() external override {
        uint256 _epochId = getThisEpoch().epochId;
        if (_epochId > 0) {
            if (_isThisEpochEnded()) {
                IRewardManager(rewardManager).onEpochEnded();
            }
        }
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "VotingM: invalid Registry");
        ideaManager = IRegistry(registry).ideaManager();
        epochManager = IRegistry(registry).epochManager();
        rewardManager = IRegistry(registry).rewardManager();
        require(ideaManager != address(0), "VotingM: invalid IdeaManager");
        require(epochManager != address(0), "VotingM: invalid EpochManager");
        require(rewardManager != address(0), "VotingM: invalid RewardManager");

        emit ContractsSet(ideaManager, epochManager, rewardManager);
    }

    function setVotingPowerThreshold(uint256 _newThreshold)
        external
        override
        onlyAdmin
    {
        require(_newThreshold > 0, "VotingM: invalid threshold");
        uint256 oldThreshold = votingPowerThreshold;
        votingPowerThreshold = uint128(_newThreshold);

        emit VotingPowerThresholdSet(oldThreshold, votingPowerThreshold);
    }

    function setMaxNumOfVotesPerBallot(uint256 _newNumber)
        external
        override
        onlyAdmin
    {
        require(_newNumber > 0, "VotingM: invalid number");
        uint256 oldNumber = maxNumOfVotesPerBallot;
        maxNumOfVotesPerBallot = uint128(_newNumber);

        emit MaxNumOfVotesPerBallotSet(oldNumber, maxNumOfVotesPerBallot);
    }

    function toggleDenied(address account) external override onlyAdmin {
        require(account != address(0), "VotingM: invalid address");
        _deniedList[account] = !_deniedList[account];

        emit AccountDeniedStatusToggled(account);
    }

    function getThisEpoch()
        public
        view
        override
        returns (IEpochManager.Epoch memory)
    {
        return IEpochManager(epochManager).getThisEpoch();
    }

    function getBallot(address account, uint256 _epochId)
        external
        view
        override
        returns (Ballot memory)
    {
        return _epochBallots[account][_epochId];
    }

    function getEpochsParticipated(address account)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _epochParticipated[account].epochIds;
    }

    function getWeightInVotingPower(address account, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        uint256 accountVotingPower = _epochBallots[account][_epochId].total;
        uint256 epochTotalVotingPower = _epochVotingPower[_epochId];

        if (epochTotalVotingPower != 0) {
            return
                (PERCENTAGES_MULTIPLE * accountVotingPower) /
                epochTotalVotingPower;
        } else {
            return 0;
        }
    }

    function getIdeaVotingPower(uint256 _ideaId, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _ideaVotingPower[_ideaId][_epochId];
    }

    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        override
        returns (uint256)
    {
        return _metaverseVotingPower[metaverseId][epochId];
    }

    function getEpochVotingPower(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _epochVotingPower[_epochId];
    }

    function getVotingPowerForCurrentEpoch(address account)
        public
        view
        override
        returns (uint256)
    {
        return
            IVotingEscrow(veContract).balanceOf(
                account,
                getThisEpoch().startingTime
            );
    }

    function getTotalVotingPowerForEpoch(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        return _epochTotalVotingPower[_epochId];
    }

    function getVotingPowerConsumptionRate(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        uint256 consumedVotingPower = _epochVotingPower[_epochId];
        uint256 totalVotingPower = _epochTotalVotingPower[_epochId];

        if (totalVotingPower > 0) {
            return
                (PERCENTAGES_MULTIPLE * consumedVotingPower) / totalVotingPower;
        } else {
            return 0;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == this.onVotingPowerUpdated.selector ||
            interfaceId == type(IVotingManagerV3).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function isValidBallot(Vote[] memory _votes)
        external
        view
        override
        returns (bool)
    {
        return _isValidBallot(_votes);
    }

    function isDenied(address voter) public view override returns (bool) {
        return _deniedList[voter];
    }

    function _onVotingPowerUpdated(address account) private {
        uint256 _epochId = getThisEpoch().epochId;

        if (!_isThisEpochEnded()) {
            if (_epochBallots[account][_epochId].total > 0) {
                uint256 _total = getVotingPowerForCurrentEpoch(account);
                _update(account);
                _epochBallots[account][_epochId].total = _total;

                emit VotingPowerUpdated(account, _total);
            }

            uint256 totalVotingPower = _getTotalVotingPowerFromVotingEscrowForThisEpoch();
            _epochTotalVotingPower[_epochId] = totalVotingPower;

            emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
        }
    }

    function _isValidBallot(Vote[] memory _votes) private view returns (bool) {
        uint256 nVotes = _votes.length;
        // If a user chooses to abstain, that is still represented as
        // a single vote for voteID `1` ("no proposal")
        if (nVotes == 0) return false;
        if (nVotes > maxNumOfVotesPerBallot) return false;

        uint256 totalPercentage;
        uint256 _ideaId;

        for (uint256 i = 0; i < nVotes; i++) {
            if (i == 0) {
                _ideaId = _votes[i].ideaId;
                if (!_isValidIdea(_ideaId)) {
                    return false;
                }
                totalPercentage = _votes[i].percentage;
            } else {
                uint256 _nextIdeaId = _votes[i].ideaId;
                if (_nextIdeaId <= _ideaId) {
                    return false;
                }
                if (!_isValidIdea(_nextIdeaId)) {
                    return false;
                }
                _ideaId = _nextIdeaId;
                totalPercentage += _votes[i].percentage;
            }
        }

        if (totalPercentage != PERCENTAGES_MULTIPLE) return false; // A valid ballot has 100%

        return true;
    }

    // precondition: caller has verified that _voter has previously cast a
    // ballot in this epoch
    function _rewind(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        _epochVotingPower[_epochId] -= _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
        }

        delete _epochBallots[_voter][_epochId];
    }

    function _update(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        uint256 _newTotal = getVotingPowerForCurrentEpoch(_voter);
        bool _isLarger = _newTotal > _total;
        uint256 _diff = _isLarger ? _newTotal - _total : _total - _newTotal;
        if (_isLarger) {
            _epochVotingPower[_epochId] += _diff;
        } else {
            _epochVotingPower[_epochId] -= _diff;
        }

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _metaverseId;
        uint256 _diffPower;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);
            _diffPower = (_diff * _ideaPercentage) / PERCENTAGES_MULTIPLE;

            if (_isLarger) {
                _ideaVotingPower[_ideaId][_epochId] += _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] += _diffPower;
            } else {
                _ideaVotingPower[_ideaId][_epochId] -= _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] -= _diffPower;
            }
        }
    }

    function _getTotalVotingPowerFromVotingEscrowForThisEpoch()
        private
        view
        returns (uint256)
    {
        uint256 startingTime = getThisEpoch().startingTime;
        return IVotingEscrow(veContract).totalSupply(startingTime);
    }

    function _isValidIdea(uint256 _ideaId) private view returns (bool) {
        if (_ideaId == 0) return false; // ideaId 0 always returns false.
        if (_ideaId == 1) return true; // ideaId 1 always returns true.
        bool cond1 = _exists(_ideaId);
        bool cond2 = _isIdeaActive(_ideaId);
        return cond1 && cond2;
    }

    function _isThisEpochEnded() private view returns (bool) {
        return IEpochManager(epochManager).isThisEpochEnded();
    }

    function _exists(uint256 ideaId) private view returns (bool) {
        return IIdeaManager(ideaManager).exists(ideaId);
    }

    function _isIdeaActive(uint256 _ideaId) private view returns (bool) {
        return IEpochManager(epochManager).isIdeaActive(_ideaId);
    }

    function _getMetaverseId(uint256 _ideaId) private view returns (uint256) {
        return IIdeaManager(ideaManager).getIdeaInfo(_ideaId).idea.metaverseId;
    }

    function _paused() private view returns (bool) {
        return IEpochManager(epochManager).paused();
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IVotingManagerV5.sol";
import "../interfaces/IIdeaManager.sol";
import "../interfaces/IRewardManager.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract ToyVotingManagerV5 is
    AdminableUpgradeable,
    IVotingManagerV5,
    ERC165Upgradeable,
    UUPSUpgradeable
{
    using ERC165Checker for address;

    bytes4 public constant IID_IVOTINGMANAGERV5 =
        type(IVotingManagerV5).interfaceId;

    address public registry;
    address public veContract; // voting escrow contract
    address public epochManager;
    address public ideaManager;
    address public rewardManager;

    uint256 public constant PERCENTAGES_DECIMALS = 9;
    uint256 public constant PERCENTAGES_MULTIPLE = 1e9; // max decimals the protocol can do
    uint128 public votingPowerThreshold; // minimum amount of voting power needed to submit a ballot
    uint128 public maxNumOfVotesPerBallot; // maximum number of votes in a ballot

    mapping(address => mapping(uint256 => Ballot)) private _epochBallots; // votes over epochs
    mapping(address => EpochInfo) private _epochParticipated; // epochs a voter has participated in
    mapping(uint256 => uint256) private _epochVotingPower; // epochId => consumed voting power
    mapping(uint256 => uint256) private _epochTotalVotingPower; // epochId => consumed voting power
    mapping(uint256 => mapping(uint256 => uint256)) private _ideaVotingPower; // ideaId => epochId => voting power
    mapping(uint256 => mapping(uint256 => uint256))
        private _metaverseVotingPower; // metaverseId => epochId => voting power
    mapping(address => bool) private _deniedList; // Denied list of voters

    bool public upgradeabilityStatus; // upgradeability is turned off

    function initialize(address _veContract, address _registry)
        external
        initializer
    {
        require(_veContract != address(0), "VotingM: invalid address");
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );

        __Adminable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        veContract = _veContract;
        registry = _registry;
        votingPowerThreshold = 5e14;
        maxNumOfVotesPerBallot = 20;
    }

    modifier onlyVeContract() {
        require(_msgSender() == veContract, "VotingM: only VeContract");
        _;
    }

    modifier onlyEpochManager() {
        require(_msgSender() == epochManager, "VotingM: only EpochManager");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused(), "VotingM: paused");
        _;
    }

    function submitBallot(Vote[] memory _votes)
        external
        override
        whenNotPaused
    {
        require(!_isThisEpochEnded(), "VotingM: epoch already over");
        require(_isValidBallot(_votes), "VotingM: invalid ballot");
        address _voter = _msgSender();
        require(!isDenied(_voter), "VotingM: voter is denied");
        uint256 _total = getVotingPowerForCurrentEpoch(_voter);
        require(
            _total > votingPowerThreshold,
            "VotingM: not reaching threshold"
        );

        uint256 _epochId = getThisEpoch().epochId;
        // If user has already voted in this epoch, we need to "rewind" their
        // previous ballot before submitting the new one
        if (_epochBallots[_voter][_epochId].total > 0) {
            _rewind(_voter);
        }

        _epochBallots[_voter][_epochId].total = _total;
        _epochVotingPower[_epochId] += _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        for (uint256 i = 0; i < _votes.length; i++) {
            _ideaId = _votes[i].ideaId;
            _ideaPercentage = _votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _epochBallots[_voter][_epochId].votes.push(_votes[i]);
            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] += _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] += _powerAllocatedToThisProposal;
        }

        uint256 nEpochs = _epochParticipated[_voter].epochIds.length;
        if (nEpochs == 0) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        } else if (
            _epochParticipated[_voter].epochIds[nEpochs - 1] < _epochId
        ) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        }

        emit BallotSubmitted(_voter, _epochId, _votes, _total);
    }

    function onVotingPowerUpdated(address account)
        external
        override
        onlyVeContract
    {
        _onVotingPowerUpdated(account);
    }

    function onEpochStarted() external override onlyEpochManager {
        uint256 _epochId = IEpochManager(epochManager).getCurEpochId();
        uint256 totalVotingPower = IVotingEscrow(veContract).totalSupply();
        _epochTotalVotingPower[_epochId] = totalVotingPower;

        emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
    }

    function endThisEpoch() external override {
        uint256 _epochId = getThisEpoch().epochId;
        if (_epochId > 0) {
            if (_isThisEpochEnded()) {
                IRewardManager(rewardManager).onEpochEnded();
            }
        }
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "VotingM: invalid Registry");
        ideaManager = IRegistry(registry).ideaManager();
        epochManager = IRegistry(registry).epochManager();
        rewardManager = IRegistry(registry).rewardManager();
        require(ideaManager != address(0), "VotingM: invalid IdeaManager");
        require(epochManager != address(0), "VotingM: invalid EpochManager");
        require(rewardManager != address(0), "VotingM: invalid RewardManager");

        emit ContractsSet(ideaManager, epochManager, rewardManager);
    }

    function setVotingPowerThreshold(uint256 _newThreshold)
        external
        override
        onlyAdmin
    {
        require(_newThreshold > 0, "VotingM: invalid threshold");
        uint256 oldThreshold = votingPowerThreshold;
        votingPowerThreshold = uint128(_newThreshold);

        emit VotingPowerThresholdSet(oldThreshold, votingPowerThreshold);
    }

    function setMaxNumOfVotesPerBallot(uint256 _newNumber)
        external
        override
        onlyAdmin
    {
        require(_newNumber > 0, "VotingM: invalid number");
        uint256 oldNumber = maxNumOfVotesPerBallot;
        maxNumOfVotesPerBallot = uint128(_newNumber);

        emit MaxNumOfVotesPerBallotSet(oldNumber, maxNumOfVotesPerBallot);
    }

    function toggleDenied(address account) external override onlyAdmin {
        require(account != address(0), "VotingM: invalid address");
        _deniedList[account] = !_deniedList[account];

        emit AccountDeniedStatusToggled(account);
    }

    function toggleUpgradeability() external override onlyAdmin {
        upgradeabilityStatus = !upgradeabilityStatus;

        emit UpgradeabilityStatusToggled(upgradeabilityStatus);
    }

    function getThisEpoch()
        public
        view
        override
        returns (IEpochManager.Epoch memory)
    {
        return IEpochManager(epochManager).getThisEpoch();
    }

    function getBallot(address account, uint256 _epochId)
        external
        view
        override
        returns (Ballot memory)
    {
        return _epochBallots[account][_epochId];
    }

    function getEpochsParticipated(address account)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _epochParticipated[account].epochIds;
    }

    function getWeightInVotingPower(address account, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        uint256 accountVotingPower = _epochBallots[account][_epochId].total;
        uint256 epochTotalVotingPower = _epochVotingPower[_epochId];

        if (epochTotalVotingPower != 0) {
            return
                (PERCENTAGES_MULTIPLE * accountVotingPower) /
                epochTotalVotingPower;
        } else {
            return 0;
        }
    }

    function getIdeaVotingPower(uint256 _ideaId, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _ideaVotingPower[_ideaId][_epochId];
    }

    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        override
        returns (uint256)
    {
        return _metaverseVotingPower[metaverseId][epochId];
    }

    function getEpochVotingPower(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _epochVotingPower[_epochId];
    }

    function getVotingPowerForCurrentEpoch(address account)
        public
        view
        override
        returns (uint256)
    {
        return
            IVotingEscrow(veContract).balanceOf(
                account,
                getThisEpoch().startingTime
            );
    }

    function getTotalVotingPowerForEpoch(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        return _epochTotalVotingPower[_epochId];
    }

    function getVotingPowerConsumptionRate(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        uint256 consumedVotingPower = _epochVotingPower[_epochId];
        uint256 totalVotingPower = _epochTotalVotingPower[_epochId];

        if (totalVotingPower > 0) {
            return
                (PERCENTAGES_MULTIPLE * consumedVotingPower) / totalVotingPower;
        } else {
            return 0;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == this.onVotingPowerUpdated.selector ||
            interfaceId == type(IVotingManagerV5).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function isValidBallot(Vote[] memory _votes)
        external
        view
        override
        returns (bool)
    {
        return _isValidBallot(_votes);
    }

    function isDenied(address voter) public view override returns (bool) {
        return _deniedList[voter];
    }

    function _onVotingPowerUpdated(address account) private {
        uint256 _epochId = getThisEpoch().epochId;

        if (!_isThisEpochEnded()) {
            if (_epochBallots[account][_epochId].total > 0) {
                uint256 _total = getVotingPowerForCurrentEpoch(account);
                _update(account);
                _epochBallots[account][_epochId].total = _total;

                emit VotingPowerUpdated(account, _total);
            }

            uint256 totalVotingPower = _getTotalVotingPowerFromVotingEscrowForThisEpoch();
            _epochTotalVotingPower[_epochId] = totalVotingPower;

            emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
        }
    }

    function _isValidBallot(Vote[] memory _votes) private view returns (bool) {
        uint256 nVotes = _votes.length;
        // If a user chooses to abstain, that is still represented as
        // a single vote for voteID `1` ("no proposal")
        if (nVotes == 0) return false;
        if (nVotes > maxNumOfVotesPerBallot) return false;

        uint256 totalPercentage;
        uint256 _ideaId;

        for (uint256 i = 0; i < nVotes; i++) {
            if (i == 0) {
                _ideaId = _votes[i].ideaId;
                if (!_isValidIdea(_ideaId)) {
                    return false;
                }
                totalPercentage = _votes[i].percentage;
            } else {
                uint256 _nextIdeaId = _votes[i].ideaId;
                if (_nextIdeaId <= _ideaId) {
                    return false;
                }
                if (!_isValidIdea(_nextIdeaId)) {
                    return false;
                }
                _ideaId = _nextIdeaId;
                totalPercentage += _votes[i].percentage;
            }
        }

        if (totalPercentage != PERCENTAGES_MULTIPLE) return false; // A valid ballot has 100%

        return true;
    }

    // precondition: caller has verified that _voter has previously cast a
    // ballot in this epoch
    function _rewind(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        _epochVotingPower[_epochId] -= _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
        }

        delete _epochBallots[_voter][_epochId];
    }

    function _update(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        uint256 _newTotal = getVotingPowerForCurrentEpoch(_voter);
        bool _isLarger = _newTotal > _total;
        uint256 _diff = _isLarger ? _newTotal - _total : _total - _newTotal;
        if (_isLarger) {
            _epochVotingPower[_epochId] += _diff;
        } else {
            _epochVotingPower[_epochId] -= _diff;
        }

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _metaverseId;
        uint256 _diffPower;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);
            _diffPower = (_diff * _ideaPercentage) / PERCENTAGES_MULTIPLE;

            if (_isLarger) {
                _ideaVotingPower[_ideaId][_epochId] += _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] += _diffPower;
            } else {
                _ideaVotingPower[_ideaId][_epochId] -= _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] -= _diffPower;
            }
        }
    }

    function _getTotalVotingPowerFromVotingEscrowForThisEpoch()
        private
        view
        returns (uint256)
    {
        uint256 startingTime = getThisEpoch().startingTime;
        return IVotingEscrow(veContract).totalSupply(startingTime);
    }

    function _isValidIdea(uint256 _ideaId) private view returns (bool) {
        if (_ideaId == 0) return false; // ideaId 0 always returns false.
        if (_ideaId == 1) return true; // ideaId 1 always returns true.
        bool cond1 = _exists(_ideaId);
        bool cond2 = _isIdeaActive(_ideaId);
        return cond1 && cond2;
    }

    function _isThisEpochEnded() private view returns (bool) {
        return IEpochManager(epochManager).isThisEpochEnded();
    }

    function _exists(uint256 ideaId) private view returns (bool) {
        return IIdeaManager(ideaManager).exists(ideaId);
    }

    function _isIdeaActive(uint256 _ideaId) private view returns (bool) {
        return IEpochManager(epochManager).isIdeaActive(_ideaId);
    }

    function _getMetaverseId(uint256 _ideaId) private view returns (uint256) {
        return IIdeaManager(ideaManager).getIdeaInfo(_ideaId).idea.metaverseId;
    }

    function _paused() private view returns (bool) {
        return IEpochManager(epochManager).paused();
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal view override onlyAdmin {
        require(!upgradeabilityStatus, "Upgradeability status is true");
        require(_msgSender() != admin(), "Upgradeability is turned off.");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This
 * can later be changed with {transferAdminship}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 *
 * This contract is only required for intermediate, library-like contracts.
 *
 * This is a direct copy of OpenZeppelin's Ownable at:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */

abstract contract AdminableUpgradeable is Initializable, ContextUpgradeable {
    address private _admin;

    event AdminshipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    function __Adminable_init() internal onlyInitializing {
        __Adminable_init_unchained();
    }

    function __Adminable_init_unchained() internal onlyInitializing {
        _transferAdminship(_msgSender());
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        // solhint-disable-next-line reason-string
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
        _;
    }

    /**
     * @dev Leaves the contract without admin. It will not be possible to call
     * `onlyAdmin` functions anymore. Can only be called by the current admin.
     *
     * NOTE: Renouncing adminship will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function renounceAdminship() public virtual onlyAdmin {
        _transferAdminship(address(0));
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function transferAdminship(address newAdmin) public virtual onlyAdmin {
        // solhint-disable-next-line reason-string
        require(
            newAdmin != address(0),
            "Adminable: new admin is the zero address"
        );
        _transferAdminship(newAdmin);
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Internal function without access restriction.
     */
    function _transferAdminship(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminshipTransferred(oldAdmin, newAdmin);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IVotingManagerV2.sol";
import "../interfaces/IIdeaManager.sol";
import "../interfaces/IRewardManager.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract VotingManagerV2 is
    AdminableUpgradeable,
    IVotingManagerV2,
    ERC165Upgradeable,
    UUPSUpgradeable
{
    using ERC165Checker for address;

    bytes4 public constant IID_IVOTINGMANAGERV2 =
        type(IVotingManagerV2).interfaceId;

    address public registry;
    address public veContract; // voting escrow contract
    address public epochManager;
    address public ideaManager;
    address public rewardManager;

    uint256 public constant PERCENTAGES_DECIMALS = 9;
    uint256 public constant PERCENTAGES_MULTIPLE = 1e9; // max decimals the protocol can do
    uint256 public votingPowerThreshold; // minimum amount of voting power needed to submit a ballot
    uint256 public maxNumOfVotesPerBallot; // maximum number of votes in a ballot

    mapping(address => mapping(uint256 => Ballot)) private _epochBallots; // votes over epochs
    mapping(address => EpochInfo) private _epochParticipated; // epochs a voter has participated in
    mapping(uint256 => uint256) private _epochVotingPower; // epochId => consumed voting power
    mapping(uint256 => uint256) private _epochTotalVotingPower; // epochId => consumed voting power
    mapping(uint256 => mapping(uint256 => uint256)) private _ideaVotingPower; // ideaId => epochId => voting power
    mapping(uint256 => mapping(uint256 => uint256))
        private _metaverseVotingPower; // metaverseId => epochId => voting power
    mapping(address => bool) private _deniedList; // Denied list of voters
    mapping(address => uint256) private _voteCounts; // Counts of votes

    function initialize(address _veContract, address _registry)
        external
        initializer
    {
        require(_veContract != address(0), "VotingM: invalid address");
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );

        __Adminable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        veContract = _veContract;
        registry = _registry;
        votingPowerThreshold = 5e14;
        maxNumOfVotesPerBallot = 20;
    }

    modifier onlyVeContract() {
        require(_msgSender() == veContract, "VotingM: only VeContract");
        _;
    }

    modifier onlyEpochManager() {
        require(_msgSender() == epochManager, "VotingM: only EpochManager");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused(), "VotingM: paused");
        _;
    }

    function submitBallot(Vote[] memory _votes)
        external
        override
        whenNotPaused
    {
        require(!_isThisEpochEnded(), "VotingM: epoch already over");
        require(_isValidBallot(_votes), "VotingM: invalid ballot");
        address _voter = _msgSender();
        require(!isDenied(_voter), "VotingM: voter is denied");
        uint256 _total = getVotingPowerForCurrentEpoch(_voter);
        require(
            _total > votingPowerThreshold,
            "VotingM: not reaching threshold"
        );

        uint256 _epochId = getThisEpoch().epochId;
        // If user has already voted in this epoch, we need to "rewind" their
        // previous ballot before submitting the new one
        if (_epochBallots[_voter][_epochId].total > 0) {
            _rewind(_voter);
        }

        _epochBallots[_voter][_epochId].total = _total;
        _epochVotingPower[_epochId] += _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        for (uint256 i = 0; i < _votes.length; i++) {
            _ideaId = _votes[i].ideaId;
            _ideaPercentage = _votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _epochBallots[_voter][_epochId].votes.push(_votes[i]);
            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] += _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] += _powerAllocatedToThisProposal;
        }

        uint256 nEpochs = _epochParticipated[_voter].epochIds.length;
        if (nEpochs == 0) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        } else if (
            _epochParticipated[_voter].epochIds[nEpochs - 1] < _epochId
        ) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        }

        _voteCounts[_voter]++;

        emit BallotSubmitted(_voter, _epochId, _votes, _total);
    }

    function getVoteCount(address account)
        external
        view
        override
        returns (uint256)
    {
        return _voteCounts[account];
    }

    function onVotingPowerUpdated(address account)
        external
        override
        onlyVeContract
    {
        _onVotingPowerUpdated(account);
    }

    function onEpochStarted() external override onlyEpochManager {
        uint256 _epochId = IEpochManager(epochManager).getCurEpochId();
        uint256 totalVotingPower = IVotingEscrow(veContract).totalSupply();
        _epochTotalVotingPower[_epochId] = totalVotingPower;

        emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
    }

    function endThisEpoch() external override {
        uint256 _epochId = getThisEpoch().epochId;
        if (_epochId > 0) {
            if (_isThisEpochEnded()) {
                IRewardManager(rewardManager).onEpochEnded();
            }
        }
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "VotingM: invalid Registry");
        ideaManager = IRegistry(registry).ideaManager();
        epochManager = IRegistry(registry).epochManager();
        rewardManager = IRegistry(registry).rewardManager();
        require(ideaManager != address(0), "VotingM: invalid IdeaManager");
        require(epochManager != address(0), "VotingM: invalid EpochManager");
        require(rewardManager != address(0), "VotingM: invalid RewardManager");

        emit ContractsSet(ideaManager, epochManager, rewardManager);
    }

    function setVotingPowerThreshold(uint256 _newThreshold)
        external
        override
        onlyAdmin
    {
        require(_newThreshold > 0, "VotingM: invalid threshold");
        uint256 oldThreshold = votingPowerThreshold;
        votingPowerThreshold = _newThreshold;

        emit VotingPowerThresholdSet(oldThreshold, votingPowerThreshold);
    }

    function setMaxNumOfVotesPerBallot(uint256 _newNumber)
        external
        override
        onlyAdmin
    {
        require(_newNumber > 0, "VotingM: invalid number");
        uint256 oldNumber = maxNumOfVotesPerBallot;
        maxNumOfVotesPerBallot = _newNumber;

        emit MaxNumOfVotesPerBallotSet(oldNumber, maxNumOfVotesPerBallot);
    }

    function toggleDenied(address account) external override onlyAdmin {
        require(account != address(0), "VotingM: invalid address");
        _deniedList[account] = !_deniedList[account];

        emit AccountDeniedStatusToggled(account);
    }

    function getThisEpoch()
        public
        view
        override
        returns (IEpochManager.Epoch memory)
    {
        return IEpochManager(epochManager).getThisEpoch();
    }

    function getBallot(address account, uint256 _epochId)
        external
        view
        override
        returns (Ballot memory)
    {
        return _epochBallots[account][_epochId];
    }

    function getEpochsParticipated(address account)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _epochParticipated[account].epochIds;
    }

    function getWeightInVotingPower(address account, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        uint256 accountVotingPower = _epochBallots[account][_epochId].total;
        uint256 epochTotalVotingPower = _epochVotingPower[_epochId];

        if (epochTotalVotingPower != 0) {
            return
                (PERCENTAGES_MULTIPLE * accountVotingPower) /
                epochTotalVotingPower;
        } else {
            return 0;
        }
    }

    function getIdeaVotingPower(uint256 _ideaId, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _ideaVotingPower[_ideaId][_epochId];
    }

    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        override
        returns (uint256)
    {
        return _metaverseVotingPower[metaverseId][epochId];
    }

    function getEpochVotingPower(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _epochVotingPower[_epochId];
    }

    function getVotingPowerForCurrentEpoch(address account)
        public
        view
        override
        returns (uint256)
    {
        return
            IVotingEscrow(veContract).balanceOf(
                account,
                getThisEpoch().startingTime
            );
    }

    function getTotalVotingPowerForEpoch(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        return _epochTotalVotingPower[_epochId];
    }

    function getVotingPowerConsumptionRate(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        uint256 consumedVotingPower = _epochVotingPower[_epochId];
        uint256 totalVotingPower = _epochTotalVotingPower[_epochId];

        if (totalVotingPower > 0) {
            return
                (PERCENTAGES_MULTIPLE * consumedVotingPower) / totalVotingPower;
        } else {
            return 0;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == this.onVotingPowerUpdated.selector ||
            interfaceId == type(IVotingManagerV2).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function isValidBallot(Vote[] memory _votes)
        external
        view
        override
        returns (bool)
    {
        return _isValidBallot(_votes);
    }

    function isDenied(address voter) public view override returns (bool) {
        return _deniedList[voter];
    }

    function _onVotingPowerUpdated(address account) private {
        uint256 _epochId = getThisEpoch().epochId;

        if (!_isThisEpochEnded()) {
            if (_epochBallots[account][_epochId].total > 0) {
                uint256 _total = getVotingPowerForCurrentEpoch(account);
                _update(account);
                _epochBallots[account][_epochId].total = _total;

                emit VotingPowerUpdated(account, _total);
            }

            uint256 totalVotingPower = _getTotalVotingPowerFromVotingEscrowForThisEpoch();
            _epochTotalVotingPower[_epochId] = totalVotingPower;

            emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
        }
    }

    function _isValidBallot(Vote[] memory _votes) private view returns (bool) {
        uint256 nVotes = _votes.length;
        // If a user chooses to abstain, that is still represented as
        // a single vote for voteID `1` ("no proposal")
        if (nVotes == 0) return false;
        if (nVotes > maxNumOfVotesPerBallot) return false;

        uint256 totalPercentage;
        uint256 _ideaId;

        for (uint256 i = 0; i < nVotes; i++) {
            if (i == 0) {
                _ideaId = _votes[i].ideaId;
                if (!_isValidIdea(_ideaId)) {
                    return false;
                }
                totalPercentage = _votes[i].percentage;
            } else {
                uint256 _nextIdeaId = _votes[i].ideaId;
                if (_nextIdeaId <= _ideaId) {
                    return false;
                }
                if (!_isValidIdea(_nextIdeaId)) {
                    return false;
                }
                _ideaId = _nextIdeaId;
                totalPercentage += _votes[i].percentage;
            }
        }

        if (totalPercentage != PERCENTAGES_MULTIPLE) return false; // A valid ballot has 100%

        return true;
    }

    // precondition: caller has verified that _voter has previously cast a
    // ballot in this epoch
    function _rewind(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        _epochVotingPower[_epochId] -= _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
        }

        delete _epochBallots[_voter][_epochId];
    }

    function _update(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        uint256 _newTotal = getVotingPowerForCurrentEpoch(_voter);
        bool _isLarger = _newTotal > _total;
        uint256 _diff = _isLarger ? _newTotal - _total : _total - _newTotal;
        if (_isLarger) {
            _epochVotingPower[_epochId] += _diff;
        } else {
            _epochVotingPower[_epochId] -= _diff;
        }

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _metaverseId;
        uint256 _diffPower;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);
            _diffPower = (_diff * _ideaPercentage) / PERCENTAGES_MULTIPLE;

            if (_isLarger) {
                _ideaVotingPower[_ideaId][_epochId] += _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] += _diffPower;
            } else {
                _ideaVotingPower[_ideaId][_epochId] -= _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] -= _diffPower;
            }
        }
    }

    function _getTotalVotingPowerFromVotingEscrowForThisEpoch()
        private
        view
        returns (uint256)
    {
        uint256 startingTime = getThisEpoch().startingTime;
        return IVotingEscrow(veContract).totalSupply(startingTime);
    }

    function _isValidIdea(uint256 _ideaId) private view returns (bool) {
        if (_ideaId == 0) return false; // ideaId 0 always returns false.
        if (_ideaId == 1) return true; // ideaId 1 always returns true.
        bool cond1 = _exists(_ideaId);
        bool cond2 = _isIdeaActive(_ideaId);
        return cond1 && cond2;
    }

    function _isThisEpochEnded() private view returns (bool) {
        return IEpochManager(epochManager).isThisEpochEnded();
    }

    function _exists(uint256 ideaId) private view returns (bool) {
        return IIdeaManager(ideaManager).exists(ideaId);
    }

    function _isIdeaActive(uint256 _ideaId) private view returns (bool) {
        return IEpochManager(epochManager).isIdeaActive(_ideaId);
    }

    function _getMetaverseId(uint256 _ideaId) private view returns (uint256) {
        return IIdeaManager(ideaManager).getIdeaInfo(_ideaId).idea.metaverseId;
    }

    function _paused() private view returns (bool) {
        return IEpochManager(epochManager).paused();
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IIdeaManager.sol";
import "./interfaces/IMetaverseManager.sol";
import "./interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract IdeaManager is
    AdminableUpgradeable,
    IIdeaManager,
    ERC165Upgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;
    using ERC165Checker for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _ideaCounter; // to create monotonically increasing ideaIds

    bytes4 public constant IID_IIDEAMANAGER = type(IIdeaManager).interfaceId;

    IERC20 public feeToken; // The token address for paying proposal fees
    address public registry;
    address public wallet; // wallet for burning tokens
    address public metaverseManager; // MetaverseManager contract

    uint256 public fee; // Proposal fee
    uint256 public constant MAX_FEE = 10_000 * 10**18; // The max amount for idea submission fee

    mapping(uint256 => IdeaInfo) private _ideaInfo; // ideaId to Idea struct

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _feeToken, address _registry)
        external
        initializer
    {
        require(_feeToken != address(0), "IdeaM: invalid address");
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "IdeaM: invalid address"
        );
        __Adminable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        feeToken = IERC20(_feeToken);
        registry = _registry;
        _ideaIdIncrement(); // Skip 0
        fee = 0;
        _ideaInfo[1] = IdeaInfo({
            idea: Idea({contentHash: bytes32(0), metaverseId: 0}),
            ideator: address(0)
        });
    }

    function publishIdea(Idea calldata _idea) external override {
        require(_isValidIdea(_idea), "IdeaM: invalid idea");
        _ideaIdIncrement();
        uint256 _ideaId = getCurIdeaId();
        _ideaInfo[_ideaId] = IdeaInfo({idea: _idea, ideator: _msgSender()});
        if (fee > 0) {
            feeToken.safeTransferFrom(_msgSender(), wallet, fee);
        }

        emit IdeaPublished(
            _ideaId,
            _idea.contentHash,
            _idea.metaverseId,
            _msgSender()
        );
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "IdeaM: invalid Registry");
        metaverseManager = IRegistry(registry).metaverseManager();
        require(
            metaverseManager != address(0),
            "IdeaM: invalid MetaverseManager"
        );

        emit ContractsSet(metaverseManager);
    }

    function setWallet(address _wallet) external override onlyAdmin {
        require(_wallet != address(0), "IdeaM: invalid wallet address");
        wallet = _wallet;

        emit WalletSet(wallet);
    }

    function setProposalFee(uint256 _fee) external override onlyAdmin {
        require(_fee >= 0, "IdeaM: invalid fee");
        require(_fee < MAX_FEE, "IdeaM: invalid fee");
        uint256 oldFee = fee;
        fee = _fee;

        emit ProposalFeeSet(oldFee, fee);
    }

    function exists(uint256 _ideaId) external view override returns (bool) {
        // IdeaID 0 does not exist. IdeaID 1 is used to represent "no proposal."
        // Said another way, voting for IdeaID 1 is akin to explicitly abstaining from voting
        if (_ideaId == 1) return true;
        return _ideaInfo[_ideaId].idea.metaverseId != 0;
    }

    function getIdeaInfo(uint256 _ideaId)
        external
        view
        override
        returns (IdeaInfo memory)
    {
        return _ideaInfo[_ideaId];
    }

    function getCurIdeaId() public view override returns (uint256) {
        return _ideaCounter.current();
    }

    function getProposalFee() external view override returns (uint256) {
        return fee;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IIdeaManager).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function _ideaIdIncrement() private {
        _ideaCounter.increment();
    }

    function _isValidIdea(Idea memory _idea) private view returns (bool) {
        bytes32 _contentHash = _idea.contentHash;
        uint256 _metaverseId = _idea.metaverseId;
        bool cond1 = _contentHash != bytes32(0);
        bool cond2 = _isValidMetaverseId(_metaverseId);
        return cond1 && cond2;
    }

    function _isValidMetaverseId(uint256 _metaverseId)
        private
        view
        returns (bool)
    {
        return IMetaverseManager(metaverseManager).exists(_metaverseId);
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface IAirdrop {
    struct LockupSummary {
        uint256 amount; // Amount airdropped to an account
        bool claimed; // If the airdropped tokens have been claimed
    }

    /**
     * @dev Emitted when `amount` of tokens are set to `account` for
     * airdropping.
     */
    event AmountSet(address account, uint256 amount);

    /**
     * @dev Emitted when this airdrop is started with
     * `globalLockupDuration` and `airdropExpiryTime` with the total amount
     * in this airdrop being `totalAmountToAirdrop`.
     */
    event AirdropStarted(
        uint256 globalLockupDuration,
        uint256 airdropExpiryTime,
        uint256 totalAmountToAirdrop
    );

    /**
     * @dev Emitted when `account` locked their tokens for gaining voting
     * power.
     */
    event Locked(address account);

    /**
     * @dev Emitted when `amount` of unclaimed tokens are recovered.
     */
    event UnclaimedTokenRecovered(uint256 amount);

    /**
     * @dev Emitted when a new `treasury` address is set.
     */
    event TreasurySet(address treasury);

    /**
     * @dev Starts the airdrop officially.
     * @param globalLockupDuration the duration sets the end timestamp after
     * which airdropped tokens are eligible to be withdrawn directly to
     * users' accounts.
     * @param airdropExpiryTime the timestamp after which unclaimed airdrop
     * tokens are eligible to be reclaimed back to the treasury
     */
    function startAirdrop(
        uint256 globalLockupDuration,
        uint256 airdropExpiryTime
    ) external;

    /**
     * @dev Sets `amount` of tokens for `account` in airdropping.
     */
    function setAmount(address account, uint256 amount) external;

    /**
     * @dev Sets `amounts` of tokens for a list of `accounts` in airdropping.
     */
    function setAmounts(address[] calldata accounts, uint256[] calldata amounts)
        external;

    /**
     * @dev Locks airdropped tokens directly to Voting Escrow to gain voting
     * power.
     */
    function lock() external;

    /**
     * @dev Withdraws to the treasury any unclaimed/unlocked tokens after the
     * airdrop has expired.
     */
    function recoverUnclaimedTokens() external;

    /**
     * @dev Sets a new `treasury` address.
     */
    function setTreasury(address treasury) external;

    /**
     * @dev Returns the total amount of unclaimed/unlocked airdropped tokens.
     */
    function totalUnclaimed() external view returns (uint256);

    /**
     * @dev Returns if `account` is eligible for claiming airdropped tokens.
     */
    function isEligibleToClaim(address account) external view returns (bool);

    /**
     * @dev Returns if the airdrop is ended.
     */
    function isAirdropEnded() external view returns (bool);

    /**
     * @dev Returns the LockupSummary info for a given `account`.
     */
    function getLockupInfo(address account)
        external
        view
        returns (LockupSummary memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface IAirdropLocked {
    struct LockSummary {
        uint256 amount; // Amount locked to an account
        uint256 unlockTime; // Unlock time for the account
    }

    /**
     * @dev Emitted when `amount` of tokens are set to `account` for
     * airdropping.
     */
    event LockSet(address account, uint256 amount, uint256 unlockTime);

    /**
     * @dev Emitted when `account` locked their tokens for gaining voting
     * power.
     */
    event Locked(address account);

    /**
     * @dev Emitted when `amount` of unclaimed tokens are recovered.
     */
    event DepositedTokenRecovered(uint256 amount);

    /**
     * @dev Emitted when a new `treasury` address is set.
     */
    event TreasurySet(address treasury);

    /**
     * @dev Lock the tokens to the accounts on the votingEscrow contract
     */
    function startAirdrop() external;

    /**
     * @dev Reset the Airdrop data
     */
    function resetAirdrop() external;

    /**
     * @dev Sets `amount` of tokens for `account` in airdropping.
     */
    function setAmount(address account, uint256 amount, uint256 unlockTime) external;

    /**
     * @dev Sets `amounts` of tokens for a list of `accounts` in airdropping.
     */
    function setAmounts(address[] calldata accounts, uint256[] calldata amounts,
        uint256[] calldata unlock_times)
        external;

    /**
     * @dev Withdraws to the treasury any unclaimed/unlocked tokens after the
     * airdrop has expired.
     */
    function recoverDepositedTokens() external;

    /**
     * @dev Sets a new `treasury` address.
     */
    function setTreasury(address treasury) external;

    /**
     * @dev Returns the total amount of unclaimed/unlocked airdropped tokens.
     */
    function totalDeposited() external view returns (uint256);

    /**
     * @dev Returns the LockSummary info for a given `account`.
     */
    function getLockSummary(address account)
        external
        view
        returns (LockSummary memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import  "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IAllocationManager is IERC165 {
    /**
     * @dev Emitted when a new voting manager contract address
     * 'votingManager' is set.
     */
    event VotingManagerSet(address votingManager);

    /**
     * @dev Sets a new `votingManager` contract address.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingManager(address votingManager) external;

    /**
     * @dev Returns the allocation rate of total rewards for a given
     * consumption `rate`.
     */
    function getAllocationRate(uint256 rate) external pure returns (uint256);

    /**
     * @dev Returns the allocation rate for a given `epochId`.
     */
    function getAllocationRateForEpoch(uint256 epochId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IEpochManager is IERC165 {
    struct Epoch {
        uint256 startingTime; // starting timestamp of an epoch
        uint256 endingTime; // ending timestamp of an epoch
        uint256 epochId; // epochId
    }

    struct IdeaIdPool {
        uint256[] ideaIds; // an array of ideaIds
    }

    /**
     * @dev Emitted when `ideaManger`, `votingManager` and `
     * rewardManager` contracts are set.
     */
    event ContractsSet(
        address ideaManger,
        address votingManager,
        address rewardManager
    );

    /**
     * @dev Emitted when the epoch with `epochId` is started with
     * `nIdeas` and `duration`.
     */
    event EpochStarted(uint256 epochId, uint256 nIdeas, uint256 duration);

    /**
     * @dev Emitted when the epoch with `epochId` is updated with
     * `nIdeas` and `duration`.
     */
    event EpochUpdated(uint256 epochId, uint256 nIdeas, uint256 duration);

    /**
     * @dev Emitted when the minEpochLength `oldLength` is updated with
     * a new length `newLength`.
     */
    event MinEpochLengthSet(uint256 oldLength, uint256 newLength);

    /**
     * @dev Emitted when the old maxEpochLength `oldLength` is updated with
     * a new length `newLength`.
     */
    event MaxEpochLengthSet(uint256 oldLength, uint256 newLength);

    /**
     * @dev Emitted when the old minDurationFromNow `oldMinDurationFromNow`
     * is updated with a new length `minDurationFromNow`.
     */
    event MinDurationFromNowSet(
        uint256 oldMinDurationFromNow,
        uint256 minDurationFromNow
    );

    /**
     * @dev Emitted when the maxNumOfIdeasPerEpoch `oldNumber` is updated
     * with a new number `newNumber`.
     */
    event MaxNumOfIdeasPerEpochSet(uint256 oldNumber, uint256 newNumber);

    /**
     * @dev Starts a new epoch if the refresh condition is met with an
     * array of `ideaIds` and the epoch `endTimestamp`.
     *
     * Conditions:
     * - An array of qualified ideas with valid `ideaIds` are provided.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function startNewEpoch(uint256[] calldata ideaIds, uint256 endTimestamp)
        external;

    /**
     * @dev Modifies the parameters of the current epoch with an
     * array of `ideaIds` and `endTimestamp`.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function updateEpoch(uint256[] calldata ideaIds, uint256 endTimestamp)
        external;

    /**
     * @dev Sets `minEpochLength` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMinEpochLength(uint256 minEpochLength) external;

    /**
     * @dev Sets `maxEpochLength` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMaxEpochLength(uint256 maxEpochLength) external;

    /**
     * @dev Sets `minDurationFromNow` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMinDurationFromNow(uint256 minDurationFromNow) external;

    /**
     * @dev Sets `maxNumOfIdeasPerEpoch` for epochs.
     *
     * Requirements:
     * - only the admin can call this function.
     */
    function setMaxNumOfIdeasPerEpoch(uint256 maxNumOfIdeasPerEpoch) external;

    /**
     * @dev Sets contracts by retrieving addresses from the
     * registry contract.
     */
    function setContracts() external;

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external;

    /**
     * @dev Returns to normal state provided a new `duration`.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause(uint256 duration) external;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
     * @dev Returns the `Epoch` information given the lookup `epochId`.
     */
    function epoch(uint256 epochId) external view returns (Epoch memory);

    /**
     * @dev Returns the `Epoch` information for the current active epoch.
     */
    function getThisEpoch() external view returns (Epoch memory);

    /**
     * @dev Returns the array of ideaIds for a given `epochId`.
     */
    function getIdeaIds(uint256 epochId)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the total number of ideas for a given `epochId`.
     */
    function getNumOfIdeas(uint256 epochId) external view returns (uint256);

    /**
     * @dev Returns if a given `ideaId` is active in the current epoch.
     */
    function isIdeaActive(uint256 ideaId) external view returns (bool);

    /**
     * @dev Returns if this epoch is already ended.
     */
    function isThisEpochEnded() external view returns (bool);

    /**
     * @dev Returns the current value of epochCounter as the next
     * possible `epochId`.
     */
    function getCurEpochId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IIdeaManager is IERC165 {
    struct Idea {
        bytes32 contentHash; // the hash of content metadata
        uint256 metaverseId; // metaverse id
    }

    struct IdeaInfo {
        Idea idea;
        address ideator; // ideator's address
    }

    /**
     * @dev Emitted when an idea `ideaId` with transaction hash `contentHash`,
     * for the metaverse `metaverseId` is published.
     */
    event IdeaPublished(
        uint256 ideaId,
        bytes32 contentHash,
        uint256 metaverseId,
        address ideator
    );

    /**
     * @dev Emitted when a new `metaverseManger` contract address is set.
     */
    event ContractsSet(address metaverseManger);

    /**
     * @dev Emitted when a new `wallet` address is set.
     */
    event WalletSet(address wallet);

    /**
     * @dev Emitted when a new proposal fee `newFee` is set to replace an
     * old proposal fee `oldFee`.
     */
    event ProposalFeeSet(uint256 oldFee, uint256 newFee);

    /**
     * @dev Sets a new proposal `fee` for submitting an idea. The fee is
     * denominated by the DAO token specified by `feeToken` state variable.
     */
    function setProposalFee(uint256 fee) external;

    /**
     * @dev Sets a new `wallet` address.
     */
    function setWallet(address wallet) external;

    /**
     * @dev Sets contracts by retrieving addresses from the
     * registry contract.
     */
    function setContracts() external;

    /**
     * @dev Publishes an `_idea`.
     *
     * Requirements:
     * - anyone who has a valid idea and pays a submission fee.
     */
    function publishIdea(Idea calldata _idea) external;

    /**
     * @dev Returns if an idea with `ideaId` exists.
     */
    function exists(uint256 ideaId) external view returns (bool);

    /**
     * @dev Returns the Idea struct object for an idea with `ideaId`.
     */
    function getIdeaInfo(uint256 ideaId)
        external
        view
        returns (IdeaInfo memory);

    /**
     * @dev Returns the protocol-level idea proposal fee.
     */
    function getProposalFee() external view returns (uint256);

    /**
     * @dev Returns the current ideaId.
     */
    function getCurIdeaId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMetaverseManager is IERC165 {
    struct Metaverse {
        string name;
    }

    /**
     * @dev Emitted when a new metaverse with `metaverseId` and `name`
     * is added.
     */
    event MetaverseAdded(uint256 metaverseId, string name);

    /**
     * @dev Emitted when an existing metaverse with `metaverseId` and
     * `oldname` is updated with `newName`.
     */
    event MetaverseUpdated(uint256 metaverseId, string oldName, string newName);

    /**
     * @dev Emitted when an existing metaverse with `metaverseId` and
     * `name` is removed.
     */
    event MetaverseRemoved(uint256 metaverseId, string name);

    /**
     * @dev Adds a `metaverse` struct object to the protocol.
     *
     * Requirements:
     *
     * - the caller must be the owner of the smart contract.
     */
    function addMetaverse(Metaverse calldata metaverse) external;

    /**
     * @dev Removes a metaverse with `metaverseId` from the protocol.
     *
     * Requirements:
     *
     * - the caller must be the owner of the smart contract.
     */
    function removeMetaverse(uint256 metaverseId) external;

    /**
     * @dev Updates the metaverse with `metaverseId` with a new
     * `metaverse` object.
     *
     * Requirements:
     *
     * - the caller must be the owner of the smart contract.
     */
    function updateMetaverse(uint256 metaverseId, Metaverse calldata metaverse)
        external;

    /**
     * @dev Returns if a metaverse with `metaverseId` exists.
     */
    function exists(uint256 metaverseId) external view returns (bool);

    /**
     * @dev Returns the metaverse object for a provided `metaverseId`.
     */
    function getMetaverse(uint256 metaverseId)
        external
        view
        returns (Metaverse memory);

    /**
     * @dev Returns the metaverseId for a provided `name`.
     */
    function getMetaverseIdByName(string calldata name)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the next metaverseId.
     */
    function getMetaverseId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRegistry is IERC165 {
    /**
     * @dev Emitted when a new `ideaManger` contract address is set.
     */
    event IdeaManagerSet(address ideaManger);

    /**
     * @dev Emitted when a new `metaverseManager` contract address is set.
     */
    event MetaverseManagerSet(address metaverseManager);

    /**
     * @dev Emitted when a new epoch manager contract `epochManager`
     * is set.
     */
    event EpochManagerSet(address epochManager);

    /**
     * @dev Emitted when a new voting manager contract `votingManager`
     * is set.
     */
    event VotingManagerSet(address votingManager);

    /**
     * @dev Emitted when a new reward pool `rewardPool` is set.
     */
    event RewardPoolSet(address rewardPool);

    /**
     * @dev Emitted when a new `rewardManger` contract address is set.
     */
    event RewardManagerSet(address rewardManger);

    /**
     * @dev Emitted when a new reward vesting manager constract
     * `rewardVestingManager` is set.
     */
    event RewardVestingManagerSet(address rewardVestingManager);

    /**
     * @dev Emitted when a new allocation manager contract
     * `allocationManager` is set.
     */
    event AllocationManagerSet(address allocationManager);

    /**
     * @dev Sets a new `ideaManager` contract address.
     */
    function setIdeaManager(address ideaManager) external;

    /**
     * @dev Sets a new `metaverseManager` address.
     */
    function setMetaverseManager(address metaverseManager) external;

    /**
     * @dev Sets a new `epochManager` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setEpochManager(address epochManager) external;

    /**
     * @dev Sets a new `votingManager` contract address.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingManager(address votingManager) external;

    /**
     * @dev Sets a new `rewardPool` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setRewardPool(address rewardPool) external;

    /**
     * @dev Sets a new `rewardManager` contract address.
     */
    function setRewardManager(address rewardManager) external;

    /**
     * @dev Sets a new `rewardVestingManager` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setRewardVestingManager(address rewardVestingManager) external;

    /**
     * @dev Sets a new `allocationManager` contract address.
     *
     * Requirements: only the admin can make this update.
     */
    function setAllocationManager(address allocationManager) external;

    /**
     * @dev Returns the idea manager contract address.
     */
    function ideaManager() external view returns (address);

    /**
     * @dev Returns the metaverse manager contract address.
     */
    function metaverseManager() external view returns (address);

    /**
     * @dev Returns the epoch manager contract address.
     */
    function epochManager() external view returns (address);

    /**
     * @dev Returns the voting manager contract address.
     */
    function votingManager() external view returns (address);

    /**
     * @dev Returns the reward pool contract address.
     */
    function rewardPool() external view returns (address);

    /**
     * @dev Returns the reward manager contract address.
     */
    function rewardManager() external view returns (address);

    /**
     * @dev Returns the reward vesting manager contract address.
     */
    function rewardVestingManager() external view returns (address);

    /**
     * @dev Returns the allocation manager contract address.
     */
    function allocationManager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRewardManager is IERC165 {
    struct RewardAmount {
        uint256 total; // Total amount of reward for an epoch
        uint256 unallocated; // Unallocated amount of reward for the same epoch
    }

    /**
     * @dev Emitted when contract addressses are set.
     */
    event ContractsSet(
        address rewardPool,
        address votingManager,
        address epochManager,
        address allocationManager,
        address rewardVestingManager
    );

    /**
     * @dev Emitted when the reward manager gets reloaded with a
     * new supply of tokens of this `amount` from the reward pool
     * for `epochId`.
     */
    event Reloaded(uint256 epochId, uint256 amount);

    /**
     * @dev Emitted when `account` claims `amount` of reward
     * for `epochId`.
     */
    event Claimed(address account, uint256 epochId, uint256 amount);

    /**
     * @dev Emitted when a new `amount` of reward per epoch is updated.
     */
    event RewardAmountPerEpochUpdated(uint256 amount);

    /**
     * @dev Emitted when a new `amount` for the next epoch with
     * `nextEpochId` is (manually) updated.
     */
    event RewardAmountForNextEpochSet(uint256 amount, uint256 nextEpochId);

    /**
     * @dev Emitted when a new `rewardAmount` for the epoch with `epochId`
     * is (algorithmically) updated.
     */
    event RewardAmountUpdated(uint256 epochId, uint256 rewardAmount);

    /**
     * @dev Emitted when the status of algo rewarding is toggled to
     * be `isAlgoRewardingOn`.
     */
    event AlgoRewardingToggled(bool isAlgoRewardingOn);

    /**
     * @dev Emitted when the epoch ended locker is toggled to
     * be `isEpochEndedLockerOn`.
     */
    event EpochEndedLockerToggled(bool isEpochEndedLockerOn);

    /**
     * @dev Reloads the reward amount for the next epoch by retrieving
     * tokens from the reward pool.
     *
     * Requirements: only EpochManager can call this function.
     */
    function reload() external;

    /**
     * @dev Updates the reward amount for the next epoch manually.
     *
     * Requirements: only admin can call this function.
     */
    function updateRewardAmount() external;

    /**
     * @dev Claims the reward for `account` in `epochId` to the
     * reward vesting manager contract.
     */
    function claimRewardForEpoch(address account, uint256 epochId) external;

    /**
     * @dev Claims the rewards for `account` in an array of `epochIds`
     * to the reward vesting manager contract.
     */
    function claimRewardsForEpochs(address account, uint256[] calldata epochIds)
        external;

    /**
     * @dev Updates metrics when the current epoch is ended.
     *
     * Requirements: only the voting manager can call this function.
     */
    function onEpochEnded() external;

    /**
     * @dev Updates the reward amount per epoch with a new `amount`.
     *
     * Requirements: only the admin can make this update.
     */
    function setRewardAmountPerEpoch(uint256 amount) external;

    /**
     * @dev Sets contracts by retrieving contracts from the
     * registry contract.
     */
    function setContracts() external;

    /**
     * @dev Toggles the status of algo rewarding from true to false or
     * from false to true.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleAlgoRewarding() external;

    /**
     * @dev Toggles the epoch ended locker from true to false or
     * from false to true. This is only used in emergency.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleEpochEndedLocker() external;

    /**
     * @dev Returns the system paramter reward amount per epoch.
     */
    function rewardAmountPerEpoch() external view returns (uint256);

    /**
     * @dev Returns if `account` has claimed reward for `epochId`.
     */
    function hasClaimedRewardForEpoch(address account, uint256 epochId)
        external
        view
        returns (bool);

    /**
     * @dev Returns the eligible amount for `account` to claim given
     * `epochId`.
     */
    function amountEligibleForEpoch(address account, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the unclaimed amount of tokens in this contract.
     */
    function amountUnclaimed() external view returns (uint256);

    /**
     * @dev Returns the reward amount for `account`.
     */
    function getClaimedRewardAmount(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the reward amount for `epochId`.
     */
    function getRewardAmountForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the unallocated reward amount for `epochId`.
     */
    function getUnallocatedRewardAmountForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the allocated reward amount for `epochId`.
     */
    function getAmountOfAllocatedReward(uint256 epochId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRewardPool is IERC165 {
    /**
     * @dev Emitted when a new `rewardManager` contract address is set.
     */
    event ContractsSet(address rewardManager);

    /**
     * @dev Emitted when `amount` of tokens are withdrawn.
     */
    event Withdrawn(uint256 amount);

    /**
     * @dev Emitted when `amount` of tokens are approved by rewardPool to
     * rewardManager.
     */
    event RewardManagerApproved(uint256 amount);

    /**
     * @dev Approves the reward manager for 10 times of the
     * rewardAmountPerEpoch returned from reward manager as the new
     * allowance.
     */
    function approveRewardManager() external;

    /**
     * @dev Returns the total amount of reward available in this
     * contract that is able to be retrieved by the reward manager
     * contract.
     */
    function totalAmount() external view returns (uint256);

    /**
     * @dev Sets new contracts by retrieving addresses from the registry
     * contract.
     */
    function setContracts() external;

    /**
     * @dev Withdraws the remaining tokens to the admin's wallet.
     */
    function withdraw() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRewardVestingManager is IERC165 {
    /**
     * @dev Emitted when `amount` of tokens are claimed by `account`.
     */
    event Claimed(address account, uint256 amount);

    /**
     * @dev Emitted when `epochManager`, `votingManager` and `rewardManager`
     * contracts are set.
     */
    event ContractsSet(
        address epochManager,
        address votingManager,
        address rewardManager
    );

    /**
     * @dev Claims the reward for the caller if there is any.
     */
    function claim() external;

    /**
     * @dev Sets new contract addresses.
     *
     * Requirements: only the admin can call this function.
     */
    function setContracts() external;

    /**
     * @dev Returns the total amount of unclaimed reward in this contract.
     *
     */
    function amountUnclaimed() external view returns (uint256);

    /**
     * @dev Returns the total amount of vested reward for `account`.
     */
    function getTotalAmountOfVestedReward(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the current total amount of reward eligible for `account`
     * to claim.
     */
    function getEligibleAmountOfRewardToClaim(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total amount of reward that has been claimed by
     * `account`.
     */
    function getAmountOfRewardClaimed(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the array of epochIds for `account` and `nEpochs`.
     * @param account the account wallet to look up epochIds for
     * @param nEpochs the number of epochIds to retrieve
     */
    function getEpochIdsEligibleForClaimingRewards(
        address account,
        uint256 nEpochs
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ISlingshot is IERC20, IERC165 {
    /**
     * @dev Burns `amount` of tokens in the MVDAO contract.
     */
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface ISmartWalletChecker {
    /**
     * @dev Returns if an `account` is a whitelisted smart contract account.
     * When new types are added - the whole contract is changed
     * The check() method is modifying to be able to use caching
     * for individual wallet addresses
     *
     * Requirements:
     *
     * - only the voting escrow contract can call this contract.
     */
    function check(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ISmartWalletWhitelist is IERC165 {
    /**
     * @dev Emitted when a `wallet` is added whitelisted.
     */
    event WalletApproved(address wallet);

    /**
     * @dev Emitted when a `wallet` is removed from the whitelist.
     */
    event WalletRevoked(address wallet);

    /**
     * @dev Approves a `wallet` as a whitelisted address.
     */
    function approveWallet(address wallet) external;

    /**
     * @dev Revokes a `wallet` from being a whitelisted address.
     */
    function revokeWallet(address wallet) external;

    /**
     * @dev Returns if a `wallet` is a whitelisted address.
     */
    function check(address wallet) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IVeContractListener is IERC165 {
    /**
     * @dev Updates the voting power for `account` when voting power is
     * added or changed on the voting escrow contract directly.
     *
     * Requirements:
     *
     * - only the voting escrow contract can call this contract.
     */
    function onVotingPowerUpdated(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface IVotingEscrow {
    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        RELOCK
    }

    struct Point {
        int128 bias;
        int128 slope; // dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    /**
     * @dev Emitted `provider` withdraws previously deposited `value`
     * amount of tokens at timestamp `ts`.
     */
    event Withdraw(address indexed provider, uint256 value, uint256 ts);

    /**
     * @dev Emitted when tokens of `value` amount are deposited by
     * `provider` at `locktime` of `_type` at the transaction time `ts`.
     */
    event Deposit(
        address indexed provider,
        address indexed payer,
        uint256 value,
        uint256 indexed locktime,
        DepositType _type,
        uint256 ts
    );

    /**
     * @dev Emitted `amount` of `token` is recovered from this contract to
     * the owner.
     */
    event Recovered(address token, uint256 amount);

    /**
     * @dev Emitted when the total supply is updated from `prevSupply`
     * to `supply`.
     */
    event Supply(uint256 prevSupply, uint256 supply);

    /**
     * @dev Emitted when a new `listener` is added.
     */
    event ListenerAdded(address listner);

    /**
     * @dev Emitted when an existing `listener` is removed.
     */
    event ListenerRemoved(address listner);

    /**
     * @dev Emitted when the smart wallet check status is toggled.
     */
    event SmartWalletCheckerStatusToggled(bool isSmartWalletCheckerOn);

    /**
     * @dev Emitted when the smart wallet check address is set.
     */
    event SmartWalletCheckerSet(address checker);

    /**
     * @dev Emitted when a create lock helper is set.
     */
    event CreateLockHelperSet(address helper);

    /**
     * @dev Deposits and locks `_value` amount of tokens for a user `_addr`.
     */
    function deposit_for(address _addr, uint256 _value) external;

    /**
     * @dev Creates a lock of `_value` amount of tokens ended at
     * `_unlock_time`.
     */
    function create_lock(uint256 _value, uint256 _unlock_time) external;

    /**
     * @dev Creates a lock of `_value` amount of tokens for `_beneficiary`
     * with lock ending time at `_unlock_time`. The tokens are paid by
     * `_payer`, which may or may not be the same with `_beneficiary`.
     */
    function createLockFor(
        address _beneficiary,
        address _payer,
        uint256 _value,
        uint256 _unlock_time
    ) external;

    /**
     * @dev Increases the locked amount by `_value` amount of tokens the
     * caller.
     */
    function increase_amount(uint256 _value) external;

    /**
     * @dev Increases the locked amount to a new unlock time at
     * `_unlock_time` by the caller.
     */
    function increase_unlock_time(uint256 _unlock_time) external;

    /**
     * @dev Increases the locked amount by `_value` amount and to a
     * new unlock time at `_unlock_time` by the caller.
     */
    function increaseAmountAndUnlockTime(uint256 _value, uint256 _unlock_time)
        external;

    /**
     * @dev Withdraws unlocked tokens to the caller's wallet.
     */
    function withdraw() external;

    /**
     * @dev Relocks caller's expired tokens for `_unlock_time`
     * amount of time.
     */
    function relock(uint256 _unlock_time) external;

    /**
     * @dev Toggles the smart contract checker status.
     */
    function toggleSmartWalletCheckerStatus() external;

    /**
     * @dev Adds a `listener` contract that needs to be notified when
     * voting power is updated for any token holder.
     */
    function addListener(address listener) external;

    /**
     * @dev Removes a listener at `listenerIdx` that is no longer in use.
     */
    function removeListenerAt(uint256 listenerIdx) external;

    /**
     * @dev Returns the listerner at the `listenerIdx`-th location.
     */
    function getListenerAt(uint256 listenerIdx) external view returns (address);

    /**
     * @dev Returns the number of listeners available.
     */
    function getNumOfListeners() external view returns (uint256);

    /**
     * @dev Returns the last user slope for the account `addr`.
     */
    function get_last_user_slope(address addr) external view returns (int128);

    /**
     * @dev Returns the last user bias for the account `addr`.
     */
    function get_last_user_bias(address addr) external view returns (int128);

    /**
     * @dev Returns the vesting time in seconds since last check point
     * for a given `addr`.
     */
    function get_last_user_vestingTime(address addr)
        external
        view
        returns (int128);

    /**
     * @dev Returns the timestamp for checkpoint `_idx` for `_addr`
     */
    function user_point_history__ts(address _addr, uint256 _idx)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the timestamp when `_addr`'s lock finishes.
     */
    function locked__end(address _addr) external view returns (uint256);

    /**
     * @dev Returns the current voting power for `_msgSender()` at the
     * specified timestamp `_t`.
     */
    function balanceOf(address addr, uint256 _t)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the current voting power for `_msgSender()` at the
     * moment when this function is called.
     */
    function balanceOf(address addr) external view returns (uint256);

    /**
     * @dev Returns the voting power of `addr` at block height `_block`.
     */
    function balanceOfAt(address addr, uint256 _block)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total voting power of the caller at the specified
     * timestamp `t`.
     */
    function totalSupply(uint256 t) external view returns (uint256);

    /**
     * @dev Returns the total voting power of the caller at the
     * current timestamp.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the total voting power of the caller at `_block` usually
     * in the past.
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256);

    /**
     * @dev Recovers `tokenAmount` of ERC20 tokens at `tokenAddress` in this
     * contract to be distributed to the contract admin.
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./IEpochManager.sol";
import "./IVeContractListener.sol";

interface IVotingManager is IVeContractListener {
    struct EpochInfo {
        uint256[] epochIds; // epochs that a voter has participated in
    }

    struct Vote {
        uint256 ideaId; // Vote for ideaId
        uint256 percentage; // % of voting power allocated to this vote
    }

    struct Ballot {
        uint256 total; // Total amount of voting power for a ballot
        Vote[] votes; // Array of votes
    }

    /**
     * @dev Emitted when contract addresses are set.
     */
    event ContractsSet(
        address ideaManager,
        address epochManager,
        address rewardManager
    );

    /**
     * @dev Emitted when the voting power is updated for `account` to a new
     * total amount `votingPower`. This can happen when tokens are being
     * locked in the voting escrow contract.
     */
    event VotingPowerUpdated(address account, uint256 votingPower);

    /**
     * @dev Emitted when `oldVotingPowerThreshold` is replaced by a
     * new `votingPowerThreshold`.
     */
    event VotingPowerThresholdSet(
        uint256 oldVotingPowerThreshold,
        uint256 votingPowerThreshold
    );

    /**
     * @dev Emitted when `oldMaxNumOfVotesPerBallot` is replaced by a
     * new `maxNumOfVotesPerBallot`.
     */
    event MaxNumOfVotesPerBallotSet(
        uint256 oldMaxNumOfVotesPerBallot,
        uint256 maxNumOfVotesPerBallot
    );

    /**
     * @dev Emitted when `account` submits a ballot in `epochId` with
     * `votes` and a total amount of `votingPower`.
     */
    event BallotSubmitted(
        address account,
        uint256 epochId,
        Vote[] votes,
        uint256 votingPower
    );

    /**
     * @dev Emitted when the denied status for `account` is toggled.
     */
    event AccountDeniedStatusToggled(address account);

    /**
     * @dev Emitted when the total voting power is updated in `epochId`
     * to a new total amount `totalVotingPower`.
     */
    event TotalVotingPowerUpdated(uint256 epochId, uint256 totalVotingPower);

    /**
     * @dev Submits a ballot with ideas in `votes`.
     */
    function submitBallot(Vote[] calldata votes) external;

    /**
     * @dev Calls this function when a new epoch is started to record the
     * total voting power.
     *
     * Requirements: only the EpochManager contract can call this function.
     */
    function onEpochStarted() external;

    /**
     * @dev Ends this epoch and updates the metrics for the previous epoch.
     */
    function endThisEpoch() external;

    /**
     * @dev Sets new contract addresses.
     *
     * Requirements: only the admin can call this function.
     */
    function setContracts() external;

    /**
     * @dev Sets `newThreshold` for the voting power threshold.
     *
     * Requirements: only the admin can call this function.
     */
    function setVotingPowerThreshold(uint256 newThreshold) external;

    /**
     * @dev Sets `newNumber` for the maximum number of votes permited
     * per ballot.
     *
     * Requirements: only the admin can call this function.
     */
    function setMaxNumOfVotesPerBallot(uint256 newNumber) external;

    /**
     * @dev Toggles the denied status for an `account`.
     *
     * Requirements: only the admin can call this function.
     */
    function toggleDenied(address account) external;

    /**
     * @dev Returns the Epoch information for this epoch by reading from
     * EpochManager.
     */
    function getThisEpoch() external view returns (IEpochManager.Epoch memory);

    /**
     * @dev Returns the Ballot information for `account` in epoch with
     * `epochId`.
     */
    function getBallot(address account, uint256 epochId)
        external
        view
        returns (Ballot memory);

    /**
     * @dev Returns the array of epochIds that `account` has participated in.
     */
    function getEpochsParticipated(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the total amount of voting power that
     * `account` has allocated for the current active epoch.
     */
    function getVotingPowerForCurrentEpoch(address account)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the system parameter `PERCENTAGES_MULTIPLE`.
     */
    function PERCENTAGES_MULTIPLE() external view returns (uint256);

    /**
     * @dev Returns the weight of voting power `account` has gained
     * in `epochId` among all voters.
     */
    function getWeightInVotingPower(address account, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of consumed voting power in `epochId`.
     */
    function getEpochVotingPower(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total amount of voting power available for `epochId`,
     * including the amount that has not been consumed in `epochId`.
     */
    function getTotalVotingPowerForEpoch(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the voting power consumption rate for `epochId`.
     * It is calculated by comparing the consumed amount with the
     * total available amount of voting power.
     */
    function getVotingPowerConsumptionRate(uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `ideaId`
     * in epoch `epochId`.
     */
    function getIdeaVotingPower(uint256 ideaId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the absolute amount of voting power for `metaverseId`
     * in epoch `epochId`.
     */
    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns if an array of `votes` is a valid ballot.
     */
    function isValidBallot(Vote[] calldata votes) external view returns (bool);

    /**
     * @dev Returns if `voter` is denied from voting.
     */
    function isDenied(address voter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IMetaverseManager.sol";
import "./utils/AdminableUpgradeable.sol";

contract MetaverseManager is
    AdminableUpgradeable,
    IMetaverseManager,
    ERC165Upgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _metaverseCounter; // metaverse counter

    bytes4 public constant IID_IMETAVERSEMANAGER =
        type(IMetaverseManager).interfaceId;

    uint256 public numOfMetaverses;
    mapping(uint256 => Metaverse) private _metaverses; // id => Metaverse
    mapping(string => uint256) private _metaverseNames; // name => id

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Adminable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();
    }

    function addMetaverse(Metaverse calldata _metaverse)
        external
        override
        onlyAdmin
    {
        string memory _name = _metaverse.name;
        require(bytes(_name).length != 0, "MetaverseM: invalid name");
        require(_metaverseNames[_name] == 0, "MetaverseM: already exists");
        _metaverseIdIncrement();
        uint256 _metaverseId = getMetaverseId();
        _metaverses[_metaverseId] = _metaverse;
        _metaverseNames[_name] = _metaverseId;
        numOfMetaverses++;

        emit MetaverseAdded(_metaverseId, _name);
    }

    function updateMetaverse(
        uint256 _metaverseId,
        Metaverse calldata _metaverse
    ) external override onlyAdmin {
        require(
            _metaverseId <= getMetaverseId(),
            "MetaverseM: invalid metaverseId"
        );
        string memory name = _metaverses[_metaverseId].name;
        require(bytes(name).length != 0, "MetaverseM: non-existent metaverse");
        require(
            !_identicalStrings(_metaverse.name, name),
            "MetaverseM: duplicated names"
        );
        require(
            _metaverseNames[_metaverse.name] == 0,
            "MetaverseM: already exist"
        );
        require(
            bytes(_metaverse.name).length != 0,
            "MetaverseM: invalid metaverse name"
        );

        _metaverses[_metaverseId] = _metaverse;
        delete _metaverseNames[name];
        _metaverseNames[_metaverse.name] = _metaverseId;

        emit MetaverseUpdated(_metaverseId, name, _metaverse.name);
    }

    function removeMetaverse(uint256 _metaverseId) external override onlyAdmin {
        require(
            _metaverseId <= getMetaverseId(),
            "MetaverseM: invalid metaverseId"
        );
        string memory name = _metaverses[_metaverseId].name;
        require(bytes(name).length != 0, "MetaverseM: non-existent metaverse");
        delete _metaverses[_metaverseId];
        delete _metaverseNames[name];
        numOfMetaverses--;

        emit MetaverseRemoved(_metaverseId, name);
    }

    function exists(uint256 _metaverseId)
        external
        view
        override
        returns (bool)
    {
        return bytes(_metaverses[_metaverseId].name).length != 0;
    }

    function getMetaverse(uint256 _metaverseId)
        external
        view
        override
        returns (Metaverse memory)
    {
        return _metaverses[_metaverseId];
    }

    function getMetaverseIdByName(string memory name)
        external
        view
        override
        returns (uint256)
    {
        return _metaverseNames[name];
    }

    function getMetaverseId() public view override returns (uint256) {
        return _metaverseCounter.current();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IMetaverseManager).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function _metaverseIdIncrement() private {
        _metaverseCounter.increment();
    }

    function _identicalStrings(string memory str1, string memory str2)
        private
        pure
        returns (bool)
    {
        bytes32 data1 = keccak256(abi.encodePacked((str1)));
        bytes32 data2 = keccak256(abi.encodePacked((str2)));
        return data1 == data2;
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./interfaces/IIdeaManager.sol";
import "./interfaces/IMetaverseManager.sol";
import "./interfaces/IEpochManager.sol";
import "./interfaces/IVotingManager.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IRewardManager.sol";
import "./interfaces/IRewardVestingManager.sol";
import "./interfaces/IAllocationManager.sol";
import "./interfaces/IRegistry.sol";
import "./utils/Adminable.sol";

contract Registry is Adminable, IRegistry, ERC165 {
    using ERC165Checker for address;

    bytes4 public constant IID_IREGISTRY = type(IRegistry).interfaceId;

    address public override ideaManager;
    address public override metaverseManager;
    address public override epochManager;
    address public override votingManager;
    address public override rewardPool;
    address public override rewardManager;
    address public override rewardVestingManager;
    address public override allocationManager;

    function setIdeaManager(address _ideaManager) external override onlyAdmin {
        require(
            _ideaManager != address(0) &&
                _ideaManager.supportsInterface(type(IIdeaManager).interfaceId),
            "Registry: invalid address"
        );
        ideaManager = _ideaManager;

        emit IdeaManagerSet(ideaManager);
    }

    function setMetaverseManager(address _metaverseManager)
        external
        override
        onlyAdmin
    {
        require(
            _metaverseManager != address(0) &&
                _metaverseManager.supportsInterface(
                    type(IMetaverseManager).interfaceId
                ),
            "Registry: invalid address"
        );
        metaverseManager = _metaverseManager;

        emit MetaverseManagerSet(metaverseManager);
    }

    function setEpochManager(address _epochManager)
        external
        override
        onlyAdmin
    {
        require(
            _epochManager != address(0) &&
                _epochManager.supportsInterface(
                    type(IEpochManager).interfaceId
                ),
            "Registry: invalid address"
        );
        epochManager = _epochManager;

        emit EpochManagerSet(epochManager);
    }

    function setVotingManager(address _votingManager)
        external
        override
        onlyAdmin
    {
        require(
            _votingManager != address(0) &&
                _votingManager.supportsInterface(
                    type(IVotingManager).interfaceId
                ),
            "Registry: invalid address"
        );
        votingManager = _votingManager;

        emit VotingManagerSet(votingManager);
    }

    function setRewardPool(address _rewardPool) external override onlyAdmin {
        require(
            _rewardPool != address(0) &&
                _rewardPool.supportsInterface(type(IRewardPool).interfaceId),
            "Registry: invalid address"
        );
        rewardPool = _rewardPool;

        emit RewardPoolSet(rewardPool);
    }

    function setRewardManager(address _rewardManager)
        external
        override
        onlyAdmin
    {
        require(
            _rewardManager != address(0) &&
                _rewardManager.supportsInterface(
                    type(IRewardManager).interfaceId
                ),
            "Registry: invalid address"
        );
        rewardManager = _rewardManager;

        emit RewardManagerSet(rewardManager);
    }

    function setRewardVestingManager(address _rewardVestingManager)
        external
        override
        onlyAdmin
    {
        require(
            _rewardVestingManager != address(0) &&
                _rewardVestingManager.supportsInterface(
                    type(IRewardVestingManager).interfaceId
                ),
            "Registry: invalid address"
        );
        rewardVestingManager = _rewardVestingManager;

        emit RewardVestingManagerSet(rewardVestingManager);
    }

    function setAllocationManager(address _allocationManager)
        external
        override
        onlyAdmin
    {
        require(
            _allocationManager != address(0) &&
                _allocationManager.supportsInterface(
                    type(IAllocationManager).interfaceId
                ),
            "Registry: invalid address"
        );
        allocationManager = _allocationManager;

        emit AllocationManagerSet(allocationManager);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IRegistry).interfaceId ||
            ERC165.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IRewardManager.sol";
import "./interfaces/IRewardVestingManager.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IEpochManager.sol";
import "./interfaces/IVotingManager.sol";
import "./interfaces/IAllocationManager.sol";
import "./interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract RewardManager is
    AdminableUpgradeable,
    IRewardManager,
    ERC165Upgradeable,
    UUPSUpgradeable
{
     using SafeERC20 for IERC20;
     using ERC165Checker for address;

    bytes4 public constant IID_IREWARDMANAGER =
        type(IRewardManager).interfaceId;

    IERC20 public token;
    address public registry;
    address public rewardPool;
    address public votingManager;
    address public epochManager;
    address public allocationManager;
    address public rewardVestingManager;

    uint256 public override rewardAmountPerEpoch;
    uint256 public thisEpochId;
    uint256 public constant RUNWAY_LENGTH = 52; // 52 epochs
    uint256 public constant MAX_AMOUNT_PER_EPOCH = 1e8 * 1e18; // 1e8 tokens, 10% of the total supply

    bool public isAlgoRewardingOn; // is algo rewarding on?
    bool public isEpochEndedLockerOn; // is unallocated amount updated?

    mapping(address => mapping(uint256 => bool)) private _hasClaimed;
    mapping(address => uint256) private _claimedAmounts; // total amount of reward that has been claimed
    mapping(uint256 => RewardAmount) private _rewardAmounts; // reward amounts over epochs

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _token, address _registry)
        external
        initializer
    {
        require(_token != address(0), "RewardM: invalid address");
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );
        __Adminable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        token = IERC20(_token);
        registry = _registry;
        isEpochEndedLockerOn = true;
    }

    modifier onlyEpochManager() {
        require(_msgSender() == epochManager, "RewardM: only EpochManager");
        _;
    }

    modifier onlyVotingManager() {
        require(_msgSender() == votingManager, "RewardM: only VotingManager");
        _;
    }

    modifier onlyRewardVestingManager() {
        require(
            _msgSender() == rewardVestingManager,
            "RewardM: only RewardVestingManager"
        );
        _;
    }

    modifier onlyAlgoRewardingOn() {
        require(isAlgoRewardingOn, "RewardM: algo rewarding is off");
        _;
    }

    modifier onlyAlgoRewardingOff() {
        require(!isAlgoRewardingOn, "RewardM: algo rewarding is on");
        _;
    }

    function reload() external override onlyEpochManager {
        require(
            isEpochEndedLockerOn,
            "RewardM: reward calculation not finalized from last epoch"
        );
        require(
            rewardAmountPerEpoch > 0,
            "RewardM: invalid reward amount per epoch"
        );
        thisEpochId = IEpochManager(epochManager).getCurEpochId();
        isEpochEndedLockerOn = false; // turn the locker off

        _updateRewardAmount(thisEpochId); // This function updates the reward amount

        uint256 amount = _rewardAmounts[thisEpochId].total;

        require(
            amount >= rewardAmountPerEpoch,
            "RewardM: invalid reward amount"
        );
        token.safeTransferFrom(rewardPool, address(this), rewardAmountPerEpoch);

        emit Reloaded(thisEpochId, rewardAmountPerEpoch);
    }

    function updateRewardAmount()
        external
        override
        onlyAlgoRewardingOn
        onlyAdmin
    {
        if (_isThisEpochEnded()) {
            _updateRewardAmount(thisEpochId + 1);
        }
    }

    // Here, if a reward has been claimed refers to if it has been claimed by
    // the reward vesting manager.
    function hasClaimedRewardForEpoch(address account, uint256 epochId)
        public
        view
        override
        returns (bool)
    {
        return _hasClaimed[account][epochId];
    }

    // Here, for a certain epochId, although the amount has been claimed,
    // the original value is still returned, i.e., whether the amount
    // has been claimed does not affect the returned value.
    function amountEligibleForEpoch(address account, uint256 epochId)
        public
        view
        override
        returns (uint256 amount)
    {
        if (epochId > thisEpochId) {
            amount = 0;
        } else if (epochId == thisEpochId && !_isThisEpochEnded()) {
            amount = 0;
        } else {
            // epochId < thisEpochId ||
            // (epochId == thisEpochId && _isThisEpochEnded())
            uint256 weight = _getWeightInVotingPower(account, epochId);
            uint256 allocatedAmount = _getAmountOfAllocatedReward(epochId);
            // allocatedAmount is guaranteed to be non-zero valued.
            if (allocatedAmount == 0) {
                allocatedAmount = _rewardAmounts[epochId].total / 100;
            }
            amount = (weight * allocatedAmount) / _getMultiples();
        }
    }

    function claimRewardForEpoch(address account, uint256 epochId)
        external
        override
        onlyRewardVestingManager
    {
        _claimRewardForEpoch(account, epochId);
    }

    function claimRewardsForEpochs(address account, uint256[] calldata epochIds)
        external
        override
        onlyRewardVestingManager
    {
        uint256 nEpochIds = epochIds.length;
        require(nEpochIds > 1, "RewardM: invalid epochIds");
        for (uint256 i = 0; i < nEpochIds; i++) {
            _claimRewardForEpoch(account, epochIds[i]);
        }
    }

    function onEpochEnded() external override onlyVotingManager {
        if (!isEpochEndedLockerOn) {
            uint256 totalAmount = _rewardAmounts[thisEpochId].total;
            uint256 allocatedAmount = _getAmountOfAllocatedReward(thisEpochId);

            _rewardAmounts[thisEpochId].unallocated =
                totalAmount -
                allocatedAmount;

            isEpochEndedLockerOn = true;
        }
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "RewardM: invalid Registry");
        rewardPool = IRegistry(registry).rewardPool();
        votingManager = IRegistry(registry).votingManager();
        epochManager = IRegistry(registry).epochManager();
        allocationManager = IRegistry(registry).allocationManager();
        rewardVestingManager = IRegistry(registry).rewardVestingManager();

        require(rewardPool != address(0), "RewardM: invalid RewardPool");
        require(votingManager != address(0), "RewardM: invalid VotingManager");
        require(epochManager != address(0), "RewardM: invalid EpochManager");
        require(
            allocationManager != address(0),
            "RewardM: invalid AllocationManager"
        );
        require(
            rewardVestingManager != address(0),
            "RewardM: invalid RewardVestingManager"
        );

        emit ContractsSet(
            rewardPool,
            votingManager,
            epochManager,
            allocationManager,
            rewardVestingManager
        );
    }

    function setRewardAmountPerEpoch(uint256 amount)
        external
        override
        onlyAdmin
    {
        require(amount > 0, "RewardM: invalid amount");
        require(amount < MAX_AMOUNT_PER_EPOCH, "RewardM: invalid amount");
        rewardAmountPerEpoch = amount;

        emit RewardAmountPerEpochUpdated(rewardAmountPerEpoch);
    }

    function toggleAlgoRewarding() external override onlyAdmin {
        isAlgoRewardingOn = !isAlgoRewardingOn;

        emit AlgoRewardingToggled(isAlgoRewardingOn);
    }

    function toggleEpochEndedLocker() external override onlyAdmin {
        isEpochEndedLockerOn = !isEpochEndedLockerOn;

        emit EpochEndedLockerToggled(isEpochEndedLockerOn);
    }

    function amountUnclaimed() external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getClaimedRewardAmount(address account)
        external
        view
        override
        returns (uint256)
    {
        return _claimedAmounts[account];
    }

    function getRewardAmountForEpoch(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _rewardAmounts[_epochId].total;
    }

    function getUnallocatedRewardAmountForEpoch(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _rewardAmounts[_epochId].unallocated;
    }

    function getAmountOfAllocatedReward(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _getAmountOfAllocatedReward(_epochId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IRewardManager).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function _claimRewardForEpoch(address account, uint256 epochId) private {
        uint256 amount = amountEligibleForEpoch(account, epochId);
        require(amount > 0, "RewardM: invalid amount");
        require(!_hasClaimed[account][epochId], "RewardM: has already claimed");
        _hasClaimed[account][epochId] = true;
        _claimedAmounts[account] += amount;
        token.safeTransfer(rewardVestingManager, amount);

        emit Claimed(account, epochId, amount);
    }

    function _updateRewardAmount(uint256 _epochId) private {
        // In this case, the reward amount has been manually set.
        if (_rewardAmounts[_epochId].total > 0) {
            return;
        }

        if (_epochId == 1) {
            _rewardAmounts[_epochId].total = rewardAmountPerEpoch;
        } else if (_epochId == 2) {
            uint256 unallocatedAmount = _rewardAmounts[_epochId - 1]
                .unallocated;
            _rewardAmounts[_epochId].total =
                rewardAmountPerEpoch +
                unallocatedAmount /
                2;
        } else if (_epochId <= RUNWAY_LENGTH) {
            uint256 unallocatedAmount;
            uint256 totalRewardRollover;
            for (uint256 i = 1; i < _epochId; i++) {
                unallocatedAmount = _rewardAmounts[i].unallocated;
                if (i != _epochId - 1) {
                    totalRewardRollover +=
                        unallocatedAmount /
                        2 /
                        (RUNWAY_LENGTH - i - 1);
                } else {
                    totalRewardRollover += unallocatedAmount / 2;
                }
            }
            _rewardAmounts[_epochId].total =
                rewardAmountPerEpoch +
                totalRewardRollover;
        } else {
            uint256 unallocatedAmount = _rewardAmounts[_epochId - 1]
                .unallocated;
            _rewardAmounts[_epochId].total =
                rewardAmountPerEpoch +
                unallocatedAmount;
        }

        emit RewardAmountUpdated(_epochId, _rewardAmounts[_epochId].total);
    }

    function _getMultiples() private view returns (uint256) {
        return IVotingManager(votingManager).PERCENTAGES_MULTIPLE();
    }

    function _isThisEpochEnded() private view returns (bool) {
        return IEpochManager(epochManager).isThisEpochEnded();
    }

    function _getAmountOfAllocatedReward(uint256 _epochId)
        private
        view
        returns (uint256)
    {
        uint256 allocationRate = _getAllocationRateForEpoch(_epochId);
        return (_rewardAmounts[_epochId].total * allocationRate) / 100;
    }

    function _getAllocationRateForEpoch(uint256 _epochId)
        private
        view
        returns (uint256)
    {
        return
            IAllocationManager(allocationManager).getAllocationRateForEpoch(
                _epochId
            );
    }

    function _getWeightInVotingPower(address account, uint256 epochId)
        private
        view
        returns (uint256)
    {
        return
            IVotingManager(votingManager).getWeightInVotingPower(
                account,
                epochId
            );
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IRewardManager.sol";
import "./interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract RewardPool is
    AdminableUpgradeable,
    IRewardPool,
    ERC165Upgradeable,
    UUPSUpgradeable
{
     using SafeERC20 for IERC20;    using ERC165Checker for address;

    bytes4 public constant IID_IREWARDPOOL = type(IRewardPool).interfaceId;

    IERC20 public token;
    address public registry;
    address public rewardManager;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _token, address _registry)
        external
        initializer
    {
        require(_token != address(0), "RewardP: invalid address");
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );
        __Adminable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        token = IERC20(_token);
        registry = _registry;
    }

    function approveRewardManager() external override onlyAdmin {
        uint256 amount = IRewardManager(rewardManager).rewardAmountPerEpoch();
        require(amount > 0, "Invalid amount for approval");
        require(rewardManager != address(0), "Invalid reward manager address");
        token.approve(rewardManager, 10 * amount);

        emit RewardManagerApproved(10 * amount);
    }

    function withdraw() external override onlyAdmin {
        uint256 balance = totalAmount();
        require(balance > 0, "RewardP: insufficient balance");
        token.safeTransfer(admin(), balance);

        emit Withdrawn(balance);
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "RewardP: invalid Registry");
        rewardManager = IRegistry(registry).rewardManager();
        require(rewardManager != address(0), "RewardP: invalid RewardManager");

        emit ContractsSet(rewardManager);
    }

    function totalAmount() public view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IRewardPool).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IRewardManager.sol";
import "./interfaces/IEpochManager.sol";
import "./interfaces/IVotingManager.sol";
import "./interfaces/IRewardVestingManager.sol";
import "./interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract RewardVestingManager is
    AdminableUpgradeable,
    IRewardVestingManager,
    ReentrancyGuardUpgradeable,
    ERC165Upgradeable,
    UUPSUpgradeable
{
     using SafeERC20 for IERC20;    
     using ERC165Checker for address;

    bytes4 public constant IID_IREWARDVESTINGMANAGER =
        type(IRewardVestingManager).interfaceId;

    IERC20 public token;
    address public registry;
    address public rewardManager;
    address public votingManager;
    address public epochManager;

    uint256 public constant VESTING_PERIOD = 30 * 24 * 3600;

    mapping(address => uint256) private _claimedAmounts;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _token, address _registry)
        external
        initializer
    {
        require(_token != address(0), "RewardVM: invalid address");
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );

        __Adminable_init();
        __ReentrancyGuard_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        token = IERC20(_token);
        registry = _registry;
    }

    function claim() external override nonReentrant {
        address account = _msgSender();

        uint256 nEpochs = _getNumOfEpochsEligibleForClaimingRewards(account);

        if (nEpochs > 0) {
            uint256[] memory epochIds = _getEpochIdsEligibleForClaimingRewards(
                account,
                nEpochs
            );

            assert(nEpochs == epochIds.length); // Must be equal.

            if (epochIds.length == 1) {
                IRewardManager(rewardManager).claimRewardForEpoch(
                    account,
                    epochIds[0]
                );
            } else {
                IRewardManager(rewardManager).claimRewardsForEpochs(
                    account,
                    epochIds
                );
            }
        }

        _update();

        uint256 amount = getEligibleAmountOfRewardToClaim(account);
        require(amount > 0, "RewardVM: invalid amount");

        _claimedAmounts[account] += amount;
        token.safeTransfer(account, amount);

        emit Claimed(account, amount);
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "RewardVM: invalid Registry");
        epochManager = IRegistry(registry).epochManager();
        votingManager = IRegistry(registry).votingManager();
        rewardManager = IRegistry(registry).rewardManager();
        require(epochManager != address(0), "RewardVM: invalid EpochManager");
        require(votingManager != address(0), "RewardVM: invalid VotingManager");
        require(rewardManager != address(0), "RewardVM: invalid RewardManager");

        emit ContractsSet(epochManager, votingManager, rewardManager);
    }

    function amountUnclaimed() external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IRewardVestingManager).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function getTotalAmountOfVestedReward(address account)
        public
        view
        override
        returns (uint256 totalAmount)
    {
        uint256[] memory epochIds = _getParticipatedEpochIds(account);
        uint256 nEpochs = epochIds.length;
        if (nEpochs == 0) {
            return 0;
        } else if (nEpochs == 1) {
            if (_isEpochEnded(epochIds[0])) {
                totalAmount += _getVestedAmountOfReward(account, epochIds[0]);
            }
        } else {
            bool flag = _isEpochEnded(epochIds[nEpochs - 1]);
            uint256 n = flag ? nEpochs : (nEpochs - 1);
            for (uint256 i = 0; i < n; i++) {
                totalAmount += _getVestedAmountOfReward(account, epochIds[i]);
            }
        }
    }

    function getEligibleAmountOfRewardToClaim(address account)
        public
        view
        override
        returns (uint256)
    {
        uint256 total = getTotalAmountOfVestedReward(account);
        uint256 claimed = _claimedAmounts[account];

        if (total >= claimed) {
            return total - claimed;
        } else {
            // Should never happen
            // Guarding against numerical rounding
            return 0;
        }
    }

    function getAmountOfRewardClaimed(address account)
        external
        view
        override
        returns (uint256)
    {
        return _claimedAmounts[account];
    }

    function getEpochIdsEligibleForClaimingRewards(
        address account,
        uint256 nEpochs
    ) external view override returns (uint256[] memory) {
        return _getEpochIdsEligibleForClaimingRewards(account, nEpochs);
    }

    function _update() private {
        IVotingManager(votingManager).endThisEpoch();
    }

    function _isEpochEnded(uint256 _epochId) private view returns (bool) {
        uint256 time = IEpochManager(epochManager).epoch(_epochId).endingTime;
        return time < block.timestamp;
    }

    function _isThisEpochEnded() private view returns (bool) {
        return IEpochManager(epochManager).isThisEpochEnded();
    }

    function _getParticipatedEpochIds(address account)
        private
        view
        returns (uint256[] memory)
    {
        return IVotingManager(votingManager).getEpochsParticipated(account);
    }

    function _getNumOfEpochsEligibleForClaimingRewards(address account)
        private
        view
        returns (uint256 nEpochs)
    {
        uint256[] memory epochIds = _getParticipatedEpochIds(account);
        for (uint256 i = 0; i < epochIds.length; i++) {
            if (_hasRewardToClaim(account, epochIds[i])) {
                nEpochs++;
            }
        }
    }

    function _hasRewardToClaim(address account, uint256 epochId)
        private
        view
        returns (bool)
    {
        bool cond1 = !_hasClaimedRewardForEpoch(account, epochId);
        bool cond2 = _hasPositiveWeightForEpoch(account, epochId);
        bool cond3 = _isEpochEnded(epochId);
        return cond1 && cond2 && cond3;
    }

    function _getEpochIdsEligibleForClaimingRewards(address account, uint256 n)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory epochIds = _getParticipatedEpochIds(account);
        uint256[] memory eligibleEpochIds = new uint256[](n);
        uint256 counter;
        for (uint256 i = 0; i < epochIds.length; i++) {
            if (_hasRewardToClaim(account, epochIds[i])) {
                eligibleEpochIds[counter] = epochIds[i];
                counter++;
            }
        }

        return eligibleEpochIds;
    }

    function _getVestedAmountOfReward(address account, uint256 _epochId)
        private
        view
        returns (uint256)
    {
        uint256 epochEndTime = _getEpochEndingTime(_epochId);
        uint256 elapsedTime = block.timestamp - epochEndTime;
        uint256 totalAmount = _getAmountEligibleForEpoch(account, _epochId);

        if (elapsedTime >= VESTING_PERIOD) {
            return totalAmount;
        } else {
            // Assuming vestingPeriod does not change
            return (elapsedTime * totalAmount) / VESTING_PERIOD;
        }
    }

    function _hasClaimedRewardForEpoch(address account, uint256 _epochId)
        private
        view
        returns (bool)
    {
        return
            IRewardManager(rewardManager).hasClaimedRewardForEpoch(
                account,
                _epochId
            );
    }

    function _hasPositiveWeightForEpoch(address account, uint256 _epochId)
        private
        view
        returns (bool)
    {
        return
            IVotingManager(votingManager).getWeightInVotingPower(
                account,
                _epochId
            ) > 0;
    }

    function _getEpochEndingTime(uint256 _epochId)
        private
        view
        returns (uint256)
    {
        return IEpochManager(epochManager).epoch(_epochId).endingTime;
    }

    function _getAmountEligibleForEpoch(address account, uint256 _epochId)
        private
        view
        returns (uint256)
    {
        return
            IRewardManager(rewardManager).amountEligibleForEpoch(
                account,
                _epochId
            );
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/ISlingshot.sol";

contract Slingshot is ERC20, ISlingshot, ERC165 {
    address public immutable treasury;

    constructor(string memory name_, string memory symbol_, address treasury_, uint256 amount_) ERC20(name_, symbol_) {
        require(treasury_ != address(0), "Slingshot: invalid treasury address.");
        treasury = treasury_;
        _mint(treasury_, amount_);
    }

    function burn(uint256 amount) external override {
        _burn(address(this), amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(ISlingshot).interfaceId ||
            ERC165.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract SlingTokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_
    ) {
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    /**
     * @dev Returns the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @dev Returns the beneficiary that will receive the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Returns the time when the tokens are released in seconds since Unix epoch (i.e. Unix timestamp).
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual {
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(beneficiary(), amount);
    }

    function changeBeneficiary(address newBeneficiary) external {
        require(msg.sender == _beneficiary, "Only current beneficiary can call this function.");
        _beneficiary = newBeneficiary;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (finance/VestingWallet.sol)

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title VestingWallet
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract SlingVestingWallet is Context {
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _released;
    mapping(address => uint256) private _erc20Released;
    address private _beneficiary;
    uint64 private immutable _start;
    uint64 private immutable _duration;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) payable {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        _beneficiary = beneficiaryAddress;
        _start = startTimestamp;
        _duration = durationSeconds;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of eth already released
     */
    function released() public view virtual returns (uint256) {
        return _released;
    }

    /**
     * @dev Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    /**
     * @dev Getter for the amount of releasable eth.
     */
    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    /**
     * @dev Getter for the amount of releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(address token) public view virtual returns (uint256) {
        return vestedAmount(token, uint64(block.timestamp)) - released(token);
    }

    /**
     * @dev Release the native token (ether) that have already vested.
     *
     * Emits a {EtherReleased} event.
     */
    function release() public virtual {
        uint256 amount = releasable();
        _released += amount;
        emit EtherReleased(amount);
        Address.sendValue(payable(beneficiary()), amount);
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release(address token) public virtual {
        uint256 amount = releasable(token);
        _erc20Released[token] += amount;
        emit ERC20Released(token, amount);
        SafeERC20.safeTransfer(IERC20(token), beneficiary(), amount);
    }

    /**
     * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(address(this).balance + released(), timestamp);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address token, uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(token).balanceOf(address(this)) + released(token), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }

    function changeBeneficiary(address newBeneficiary) external {
        require(msg.sender == _beneficiary, "Only current beneficiary can call this function.");
        _beneficiary = newBeneficiary;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_
    ) {
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    /**
     * @dev Returns the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @dev Returns the beneficiary that will receive the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Returns the time when the tokens are released in seconds since Unix epoch (i.e. Unix timestamp).
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual {
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(beneficiary(), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This
 * can later be changed with {transferAdminship}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 *
 * This contract is only required for intermediate, library-like contracts.
 *
 * This is a direct copy of OpenZeppelin's Ownable at:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */

abstract contract Adminable is Context {
    address private _admin;

    event AdminshipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor() {
        _transferAdminship(_msgSender());
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        // solhint-disable-next-line reason-string
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
        _;
    }

    /**
     * @dev Leaves the contract without admin. It will not be possible to call
     * `onlyAdmin` functions anymore. Can only be called by the current admin.
     *
     * NOTE: Renouncing adminship will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function renounceAdminship() public virtual onlyAdmin {
        _transferAdminship(address(0));
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function transferAdminship(address newAdmin) public virtual onlyAdmin {
        // solhint-disable-next-line reason-string
        require(
            newAdmin != address(0),
            "Adminable: new admin is the zero address"
        );
        _transferAdminship(newAdmin);
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Internal function without access restriction.
     */
    function _transferAdminship(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminshipTransferred(oldAdmin, newAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This
 * can later be changed with {transferAdminship}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 *
 * This contract is only required for intermediate, library-like contracts.
 *
 * This is a direct copy of OpenZeppelin's Ownable at:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */

abstract contract AdminableUpgradeable is Initializable, ContextUpgradeable {
    address private _admin;

    event AdminshipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    function __Adminable_init() internal onlyInitializing {
        __Adminable_init_unchained();
    }

    function __Adminable_init_unchained() internal onlyInitializing {
        _transferAdminship(_msgSender());
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        // solhint-disable-next-line reason-string
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
        _;
    }

    /**
     * @dev Leaves the contract without admin. It will not be possible to call
     * `onlyAdmin` functions anymore. Can only be called by the current admin.
     *
     * NOTE: Renouncing adminship will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function renounceAdminship() public virtual onlyAdmin {
        _transferAdminship(address(0));
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function transferAdminship(address newAdmin) public virtual onlyAdmin {
        // solhint-disable-next-line reason-string
        require(
            newAdmin != address(0),
            "Adminable: new admin is the zero address"
        );
        _transferAdminship(newAdmin);
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Internal function without access restriction.
     */
    function _transferAdminship(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminshipTransferred(oldAdmin, newAdmin);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../interfaces/ISmartWalletChecker.sol";
import "../interfaces/ISmartWalletWhitelist.sol";
import "./Adminable.sol";

contract SmartWalletWhitelist is Adminable, ISmartWalletWhitelist, ERC165 {
    using ERC165Checker for address;

    mapping(address => bool) private _wallets;

    function approveWallet(address _wallet) external override onlyAdmin {
        require(_wallet != address(0), "SWChecker: invalid address");
        require(_isSmartContract(_wallet), "SWChecker: invalid address");
        _wallets[_wallet] = true;

        emit WalletApproved(_wallet);
    }

    function revokeWallet(address _wallet) external override onlyAdmin {
        require(_wallet != address(0), "SWChecker: invalid address");
        require(_wallets[_wallet], "SWChecker: invalid address");

        _wallets[_wallet] = false;

        emit WalletRevoked(_wallet);
    }

    function check(address _wallet) external view override returns (bool) {
        return _wallets[_wallet];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ISmartWalletWhitelist).interfaceId ||
            ERC165.supportsInterface(interfaceId);
    }

    function _isSmartContract(address _wallet) private view returns (bool) {
        return _wallet.code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (finance/VestingWallet.sol)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title VestingWallet
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract VestingWallet is Context {
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _released;
    mapping(address => uint256) private _erc20Released;
    address private immutable _beneficiary;
    uint64 private immutable _start;
    uint64 private immutable _duration;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) payable {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        _beneficiary = beneficiaryAddress;
        _start = startTimestamp;
        _duration = durationSeconds;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of eth already released
     */
    function released() public view virtual returns (uint256) {
        return _released;
    }

    /**
     * @dev Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    /**
     * @dev Getter for the amount of releasable eth.
     */
    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    /**
     * @dev Getter for the amount of releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(address token) public view virtual returns (uint256) {
        return vestedAmount(token, uint64(block.timestamp)) - released(token);
    }

    /**
     * @dev Release the native token (ether) that have already vested.
     *
     * Emits a {EtherReleased} event.
     */
    function release() public virtual {
        uint256 amount = releasable();
        _released += amount;
        emit EtherReleased(amount);
        Address.sendValue(payable(beneficiary()), amount);
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release(address token) public virtual {
        uint256 amount = releasable(token);
        _erc20Released[token] += amount;
        emit ERC20Released(token, amount);
        SafeERC20.safeTransfer(IERC20(token), beneficiary(), amount);
    }

    /**
     * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(address(this).balance + released(), timestamp);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address token, uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(token).balanceOf(address(this)) + released(token), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IVeContractListener.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/ISmartWalletChecker.sol";
import "./interfaces/ISmartWalletWhitelist.sol";
import "./utils/Adminable.sol";

contract VotingEscrow is ReentrancyGuard, Adminable, IVotingEscrow {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---
    // Address of the token being locked
    IERC20 public immutable token;

    // Address of listeners that need to be updated
    EnumerableSet.AddressSet private listeners;

    // Current supply of vote locked tokens
    uint256 public supply;

    // Current vote lock epoch
    uint256 public epoch;

    // veContract token name
    string public name;

    // veContract token symbol
    string public symbol;

    // veToken decimals
    uint256 public decimals;

    // num of listeners
    uint256 public numOfListeners;

    // Current smart wallet checker
    address public smart_wallet_checker;

    // One-time create lock helper: airdrop, or others.
    address public create_lock_helper;

    // Helper already set or not status
    bool public helperSet;

    // Smart wallet checker on/off status
    bool public isSmartWalletCheckerOn;

    address public constant ZERO_ADDRESS = address(0);

    uint256 public constant WEEK = 7 * 86400; // all future times are rounded by week
    uint256 public constant MINTIME = 30 * 86400; // 30 days
    uint256 public constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 public constant MULTIPLIER = 10**18;

    // Locked balances and end date for each lock
    mapping(address => LockedBalance) public locked;
    // History of vote weights for each user
    mapping(address => mapping(uint256 => Point)) public user_point_history;
    // Vote epochs for each user vote weight
    mapping(address => uint256) public user_point_epoch;
    // Decay slope changes
    mapping(uint256 => int128) public slope_changes; // time -> signed slope change

    // Global vote weight history for each epoch
    mapping(uint256 => Point) public point_history; // epoch -> unsigned point

    /**
     * @notice Contract constructor
     * @param _token `MVDAO` token address
     * @param _name Token name
     * @param _symbol Token symbol
     */
    constructor(
        address _token,
        string memory _name,
        string memory _symbol
    ) {
        require(_token != address(0), "VotingEscrow: invalid address");

        name = _name;
        symbol = _symbol;
        token = IERC20(_token);
        decimals = IERC20Metadata(_token).decimals(); // snapshot strategies

        point_history[0].blk = block.number;
        point_history[0].ts = block.timestamp;
    }

    modifier onlyCreateLockHelper() {
        require(
            _msgSender() == create_lock_helper,
            "VotingEscrow: only helper"
        );
        _;
    }

    /**
     * @notice Deposit and lock tokens for a user
     * @dev Anyone (even a smart contract) can deposit for someone else, but
            cannot extend their locktime and deposit for a brand new user
     * @param _addr User's wallet address
     * @param _value Amount to add to user's lock
     */
    function deposit_for(address _addr, uint256 _value)
        external
        override
        nonReentrant
    {
        LockedBalance memory _locked = locked[_addr];

        require(_value > 0, "veC/need-non-zero-value");
        require(_locked.amount > 0, "veC/no-existing-lock-found");
        require(
            _locked.end > block.timestamp,
            "veC/cannot-add-to-expired-lock-withdraw"
        );

        _deposit_for(
            _addr,
            _addr,
            _value,
            0,
            _locked,
            DepositType.DEPOSIT_FOR_TYPE
        );
    }

    /**
     * @notice Deposit `_value` tokens for `_msgSender()` and lock until `_unlock_time`
     * @param _value Amount to deposit
     * @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
     */
    function create_lock(uint256 _value, uint256 _unlock_time)
        external
        override
        nonReentrant
    {
        _createLockFor(_msgSender(), _msgSender(), _value, _unlock_time);
    }

    /**
     * @notice Deposit `_value` tokens for `_beneficiary` by `_payer` and lock until `_unlock_time`
     * @param _beneficiary Account that receives voting power
     * @param _payer Account that pays the tokens for the beneficiary
     * @param _value Amount to deposit
     * @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
     */
    function createLockFor(
        address _beneficiary,
        address _payer,
        uint256 _value,
        uint256 _unlock_time
    ) external override onlyCreateLockHelper nonReentrant {
        _createLockFor(_beneficiary, _payer, _value, _unlock_time);
    }

    /**
     * @notice Deposit `_value` additional tokens for `_msgSender()`
               without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increase_amount(uint256 _value) external override nonReentrant {
        _increase_amount(_value);
    }

    /**
     * @notice Extend the unlock time for `_msgSender()` to `_unlock_time`
     * @param _unlock_time New epoch time for unlocking
     */
    function increase_unlock_time(uint256 _unlock_time)
        external
        override
        nonReentrant
    {
        _increase_unlock_time(_unlock_time);
    }

    function increaseAmountAndUnlockTime(uint256 _value, uint256 _unlock_time)
        external
        override
        nonReentrant
    {
        _increase_amount(_value);
        _increase_unlock_time(_unlock_time);
    }

    /**
     * @notice Withdraw all tokens for `_msgSender()`ime`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external override nonReentrant {
        LockedBalance memory _locked = locked[_msgSender()];
        require(block.timestamp >= _locked.end, "veC/the-lock-did-not-expire");
        uint256 value = uint256(int256(_locked.amount));

        LockedBalance memory old_locked = LockedBalance({
            amount: _locked.amount,
            end: _locked.end
        });

        _locked.end = 0;
        _locked.amount = 0;
        locked[_msgSender()] = _locked;
        uint256 supply_before = supply;
        supply = supply_before - value;

        // old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_msgSender(), old_locked, _locked);

        token.safeTransfer(_msgSender(), value);

        for (uint256 i = 0; i < numOfListeners; i++) {
            address listener = listeners.at(i);
            IVeContractListener(listener).onVotingPowerUpdated(_msgSender());
        }

        emit Withdraw(_msgSender(), value, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }

    function relock(uint256 _unlock_time) external override nonReentrant {
        _relock(_unlock_time);
    }

    function toggleSmartWalletCheckerStatus() external override onlyAdmin {
        isSmartWalletCheckerOn = !isSmartWalletCheckerOn;

        emit SmartWalletCheckerStatusToggled(isSmartWalletCheckerOn);
    }

    function addListener(address listener) external override onlyAdmin {
        require(
            listener != address(0) &&
                listener.supportsInterface(
                    type(IVeContractListener).interfaceId
                ),
            "veC/invalid-listener"
        );
        listeners.add(listener);
        if (listeners.length() > numOfListeners) {
            numOfListeners++;
        }

        emit ListenerAdded(listener);
    }

    function removeListenerAt(uint256 listenerIdx) external override onlyAdmin {
        require(listeners.length() > 0, "veC/no-listener-to-remove");
        require(listenerIdx < listeners.length(), "veC/invalid-listener-index");
        address listenerToRemove = listeners.at(listenerIdx);
        listeners.remove(listenerToRemove);

        if (listeners.length() < numOfListeners) {
            numOfListeners--;
        }

        emit ListenerRemoved(listenerToRemove);
    }

    function getListenerAt(uint256 listenerIdx)
        external
        view
        override
        returns (address)
    {
        if (listeners.length() > 0) {
            return listeners.at(listenerIdx);
        } else {
            return address(0);
        }
    }

    function getNumOfListeners() external view override returns (uint256) {
        return listeners.length();
    }

    /**
     * @notice Get the most recently recorded rate of voting power decrease for `addr`
     * @param addr Address of the user wallet
     * @return Value of the slope
     */
    function get_last_user_slope(address addr)
        external
        view
        override
        returns (int128)
    {
        uint256 uepoch = user_point_epoch[addr];
        return user_point_history[addr][uepoch].slope;
    }

    /**
     * @notice Get the most recently recorded rate of voting power decrease for `addr`
     * @param addr Address of the user wallet
     * @return Value of the bias
     */
    function get_last_user_bias(address addr)
        external
        view
        override
        returns (int128)
    {
        uint256 uepoch = user_point_epoch[addr];
        return user_point_history[addr][uepoch].bias;
    }

    /**
     * @notice Get the vesting time for `addr`
     * @param addr Address of the user wallet
     * @return the vesting time in seconds since last check point
     */
    function get_last_user_vestingTime(address addr)
        external
        view
        override
        returns (int128)
    {
        uint256 uepoch = user_point_epoch[addr];
        int128 bias = user_point_history[addr][uepoch].bias;
        int128 slope = user_point_history[addr][uepoch].slope;
        return bias / slope;
    }

    /**
     * @notice Get the timestamp for checkpoint `_idx` for `_addr`
     * @param _addr User wallet address
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function user_point_history__ts(address _addr, uint256 _idx)
        external
        view
        override
        returns (uint256)
    {
        return user_point_history[_addr][_idx].ts;
    }

    /**
     * @notice Get timestamp when `_addr`'s lock finishes
     * @param _addr User wallet
     * @return Epoch time of the lock end
     */
    function locked__end(address _addr)
        external
        view
        override
        returns (uint256)
    {
        return locked[_addr].end;
    }

    /**
     * @notice Get the current voting power for `addr` at the specified timestamp
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param addr User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     */
    function balanceOf(address addr, uint256 _t)
        public
        view
        override
        returns (uint256)
    {
        uint256 _epoch = user_point_epoch[addr];
        if (_epoch == 0) {
            return 0;
        } else {
        Point memory last_point = user_point_history[addr][_epoch];
            last_point.bias -=
                last_point.slope *
                (int128(int256(_t)) - int128(int256(last_point.ts)));
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
            return uint256(int256(last_point.bias));
        }
    }

    /**
     * @notice Get the current voting power for `addr` at the current timestamp
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param addr User wallet address
     * @return User voting power
     */
    function balanceOf(address addr) public view override returns (uint256) {
        return balanceOf(addr, block.timestamp);
    }

    /**
     * @notice Measure voting power of `addr` at block height `_block`
     * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
     * @param addr User's wallet address
     * @param _block Block to calculate the voting power at
     * @return Voting power
     */
    function balanceOfAt(address addr, uint256 _block)
        public
        view
        override
        returns (uint256)
    {
        require(_block <= block.number);

        // Binary search
        uint256 _min = 0;
        uint256 _max = user_point_epoch[addr];

        // Will be always enough for 128-bit numbers
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (user_point_history[addr][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = user_point_history[addr][_min];

        uint256 max_epoch = epoch;
        uint256 _epoch = find_block_epoch(_block, max_epoch);

        Point memory point_0 = point_history[_epoch];
        uint256 d_block = 0;
        uint256 d_t = 0;

        if (_epoch < max_epoch) {
            Point memory point_1 = point_history[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }

        uint256 block_time = point_0.ts;
        if (d_block != 0) {
            block_time += (d_t * (_block - point_0.blk)) / d_block;
        }

        if (block_time < upoint.ts) {
            return 0;
        }

        upoint.bias -= upoint.slope * (int128(int256(block_time - upoint.ts)));
        if (upoint.bias >= 0) {
            return uint256(int256(upoint.bias));
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculate total voting power at the specified timestamp
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupply(uint256 t) public view override returns (uint256) {
        uint256 _epoch = epoch;
        Point memory last_point = point_history[_epoch];
        return supply_at(last_point, t);
    }

    /**
     * @notice Calculate total voting power at the current timestamp
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupply() public view override returns (uint256) {
        return totalSupply(block.timestamp);
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block)
        external
        view
        override
        returns (uint256)
    {
        require(_block <= block.number, "veC/invalid-input-block-number");
        uint256 _epoch = epoch;
        uint256 target_epoch = find_block_epoch(_block, _epoch);

        Point memory point = point_history[target_epoch];
        uint256 dt = 0;

        if (target_epoch < _epoch) {
            Point memory point_next = point_history[target_epoch + 1];
            if (point.blk != point_next.blk) {
                dt =
                    ((_block - point.blk) * (point_next.ts - point.ts)) /
                    (point_next.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt =
                    ((_block - point.blk) * (block.timestamp - point.ts)) /
                    (block.number - point.blk);
            }
        }

        // Now dt contains info on how far are we beyond point
        return supply_at(point, point.ts + dt);
    }

    /**
     * @notice Check if the call is from a whitelisted smart contract, revert if not
     * @param _addr Address to be checked
     */
    function assert_not_contract(address _addr) internal view {
        if (isSmartWalletCheckerOn) {
            if (_addr != tx.origin) {
                address checker = smart_wallet_checker;
                if (checker != ZERO_ADDRESS) {
                    if (ISmartWalletChecker(checker).check(_addr)) {
                        return;
                    }
                }
                revert("veC/smart-contract-depositors-not-allowed");
            }
        }
    }

    // Constant structs not allowed yet, so this will have to do
    function EMPTY_POINT_FACTORY() internal pure returns (Point memory) {
        return Point({bias: 0, slope: 0, ts: 0, blk: 0});
    }

    // Constant structs not allowed yet, so this will have to do
    function EMPTY_LOCKED_BALANCE_FACTORY()
        internal
        pure
        returns (LockedBalance memory)
    {
        return LockedBalance({amount: 0, end: 0});
    }

    function _createLockFor(
        address _beneficiary,
        address _payer,
        uint256 _value,
        uint256 _unlock_time
    ) private {
        assert_not_contract(_beneficiary);
        require(
            _unlock_time >= block.timestamp + MINTIME,
            "veC/voting-lock-can-be-30-days-min"
        );

        uint256 unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[_beneficiary];

        require(_value > 0, "veC/need-non-zero-value");
        require(_locked.amount == 0, "veC/withdraw-old-tokens-first");
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "veC/voting-lock-can-be-4-years-max"
        );

        _deposit_for(
            _beneficiary,
            _payer,
            _value,
            unlock_time,
            _locked,
            DepositType.CREATE_LOCK_TYPE
        );
    }

    function _increase_amount(uint256 _value) private {
        assert_not_contract(_msgSender());
        LockedBalance memory _locked = locked[_msgSender()];

        require(_value > 0, "veC/need-non-zero-value");
        require(_locked.amount > 0, "veC/no-existing-lock-found");
        require(
            _locked.end > block.timestamp,
            "veC/cannot-add-to-expired-lock-withdraw"
        );

        _deposit_for(
            _msgSender(),
            _msgSender(),
            _value,
            0,
            _locked,
            DepositType.INCREASE_LOCK_AMOUNT
        );
    }

    function _increase_unlock_time(uint256 _unlock_time) private {
        assert_not_contract(_msgSender());
        require(
            _unlock_time >= block.timestamp + MINTIME,
            "veC/voting-lock-can-be-30-days-min"
        );

        LockedBalance memory _locked = locked[_msgSender()];
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, "veC/lock-expired");
        require(_locked.amount > 0, "veC/nothing-is-locked");
        require(
            unlock_time > _locked.end,
            "veC/can-only-increase-lock-duration"
        );
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "veC/voting-lock-can-be-4-years-max"
        );

        _deposit_for(
            _msgSender(),
            _msgSender(),
            0,
            unlock_time,
            _locked,
            DepositType.INCREASE_UNLOCK_TIME
        );
    }

    function _relock(uint256 _unlock_time) private {
        assert_not_contract(_msgSender());
        require(
            _unlock_time >= block.timestamp + MINTIME,
            "veC/voting-lock-can-be-30-days-min"
        );

        LockedBalance memory _locked = locked[_msgSender()];
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(block.timestamp >= _locked.end, "veC/the-lock-did-not-expire");
        require(_locked.amount > 0, "veC/nothing-is-locked");
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "veC/voting-lock-can-be-4-years-max"
        );

        _deposit_for(
            _msgSender(),
            _msgSender(),
            0,
            unlock_time,
            _locked,
            DepositType.RELOCK
        );
    }

    /**
     * @notice Record global and per-user data to checkpoint
     * @param addr User's wallet address. No user checkpoint if 0x0
     * @param old_locked Previous locked amount / end lock time for the user
     * @param new_locked New locked amount / end lock time for the user
     */
    function _checkpoint(
        address addr,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old = EMPTY_POINT_FACTORY();
        Point memory u_new = EMPTY_POINT_FACTORY();

        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint256 _epoch = epoch;

        if (addr != ZERO_ADDRESS) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if ((old_locked.end > block.timestamp) && (old_locked.amount > 0)) {
                u_old.slope = old_locked.amount / int128(int256(MAXTIME));
                u_old.bias =
                    u_old.slope *
                    (int128(int256(old_locked.end)) -
                        int128(int256(block.timestamp)));
            }

            if ((new_locked.end > block.timestamp) && (new_locked.amount > 0)) {
                u_new.slope = new_locked.amount / int128(int256(MAXTIME));
                u_new.bias =
                    u_new.slope *
                    (int128(int256(new_locked.end)) -
                        int128(int256(block.timestamp)));
            }

            // Read values of scheduled changes in the slope
            // old_locked.end can be in the past and in the future
            // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
            old_dslope = slope_changes[old_locked.end];
            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slope_changes[new_locked.end];
                }
            }
        }

        Point memory last_point = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });
        if (_epoch > 0) {
            last_point = point_history[_epoch];
        }
        uint256 last_checkpoint = last_point.ts;

        // initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initial_last_point = last_point;
        uint256 block_slope = 0; // dblock/dt
        if (block.timestamp > last_point.ts) {
            block_slope =
                (MULTIPLIER * (block.number - last_point.blk)) /
                (block.timestamp - last_point.ts);
        }

        //////////////////////////////////////////////////////////////
        // If last point is already recorded in this block, slope=0 //
        // But that's ok b/c we know the block in such case         //
        //////////////////////////////////////////////////////////////

        // Go over weeks to fill history and calculate what the current point is
        uint256 t_i = (last_checkpoint / WEEK) * WEEK;
        for (uint256 i = 0; i < 255; i++) {
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            t_i += WEEK;
            int128 d_slope = 0;
            if (t_i > block.timestamp) {
                t_i = block.timestamp;
            } else {
                d_slope = slope_changes[t_i];
            }
            last_point.bias -=
                last_point.slope *
                (int128(int256(t_i)) - int128(int256(last_checkpoint)));
            last_point.slope += d_slope;
            if (last_point.bias < 0) {
                last_point.bias = 0; // This can happen
            }
            if (last_point.slope < 0) {
                last_point.slope = 0; // This cannot happen - just in case
            }
            last_checkpoint = t_i;
            last_point.ts = t_i;
            last_point.blk =
                initial_last_point.blk +
                (block_slope * (t_i - initial_last_point.ts)) /
                MULTIPLIER;
            _epoch += 1;
            if (t_i == block.timestamp) {
                last_point.blk = block.number;
                break;
            } else {
                point_history[_epoch] = last_point;
            }
        }

        epoch = _epoch;
        // Now point_history is filled until t=now

        if (addr != ZERO_ADDRESS) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);
            if (last_point.slope < 0) {
                last_point.slope = 0;
            }
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        // Record the changed point into history
        point_history[_epoch] = last_point;

        if (addr != ZERO_ADDRESS) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;
                if (new_locked.end == old_locked.end) {
                    old_dslope -= u_new.slope; // It was a new deposit, not extension
                }
                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    slope_changes[new_locked.end] = new_dslope;
                }
                // else: we recorded it already in old_dslope
            }

            // Now handle user history
            // Second function needed for 'stack too deep' issues
            _checkpoint_part_two(addr, u_new.bias, u_new.slope);
        }
    }

    /**
     * @notice Needed for 'stack too deep' issues in _checkpoint()
     * @param addr User's wallet address. No user checkpoint if 0x0
     * @param _bias from unew
     * @param _slope from unew
     */
    function _checkpoint_part_two(
        address addr,
        int128 _bias,
        int128 _slope
    ) internal {
        uint256 user_epoch = user_point_epoch[addr] + 1;

        user_point_epoch[addr] = user_epoch;
        user_point_history[addr][user_epoch] = Point({
            bias: _bias,
            slope: _slope,
            ts: block.timestamp,
            blk: block.number
        });
    }

    /**
     * @notice Deposit and lock tokens for a user
     * @param _beneficiary User's wallet address
     * @param _payer Address that provides the tokens to be locked
     * @param _value Amount to deposit
     * @param unlock_time New time when to unlock the tokens, or 0 if unchanged
     * @param locked_balance Previous locked amount / timestamp
     */
    function _deposit_for(
        address _beneficiary,
        address _payer,
        uint256 _value,
        uint256 unlock_time,
        LockedBalance memory locked_balance,
        DepositType _type
    ) internal {
        LockedBalance memory _locked = locked_balance;
        uint256 supply_before = supply;

        supply = supply_before + _value;
        LockedBalance memory old_locked = LockedBalance({
            amount: _locked.amount,
            end: _locked.end
        });

        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += int128(int256(_value));
        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }
        locked[_beneficiary] = _locked;

        // Possibilities:
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_beneficiary, old_locked, _locked);

        if (_value != 0) {
            token.safeTransferFrom(_payer, address(this), _value);
        }

        for (uint256 i = 0; i < numOfListeners; i++) {
            address listener = listeners.at(i);
            IVeContractListener(listener).onVotingPowerUpdated(_beneficiary);
        }

        emit Deposit(
            _beneficiary,
            _payer,
            _value,
            _locked.end,
            _type,
            block.timestamp
        );
        emit Supply(supply_before, supply_before + _value);
    }

    //////////////////////////////////////////////////////////////////////////////////////
    // The following ERC20/minime-compatible methods are not real balanceOf and supply! //
    // They measure the weights for the purpose of voting, so they don't represent      //
    // real coins.                                                                      //
    //////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Binary search to estimate timestamp for block number
     * @param _block Block to find
     * @param max_epoch Don't go beyond this epoch
     * @return Approximate timestamp for block
     */
    function find_block_epoch(uint256 _block, uint256 max_epoch)
        internal
        view
        returns (uint256)
    {
        // Binary search
        uint256 _min = 0;
        uint256 _max = max_epoch;

        // Will be always enough for 128-bit numbers
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        return _min;
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param point The point (bias/slope) to start search from
     * @param t Time to calculate the total voting power at
     * @return Total voting power at that time
     */
    function supply_at(Point memory point, uint256 t)
        internal
        view
        returns (uint256)
    {
        Point memory last_point = Point({
            bias: point.bias,
            slope: point.slope,
            ts: point.ts,
            blk: point.blk
        });
        uint256 t_i = (last_point.ts / WEEK) * WEEK;

        for (uint256 i = 0; i < 255; i++) {
            t_i += WEEK;
            int128 d_slope = 0;
            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }

            last_point.bias -=
                last_point.slope *
                (int128(int256(t_i)) - int128(int256(last_point.ts)));

            if (t_i == t) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }

        return uint256(int256(last_point.bias));
    }

    /**
     * @notice Record global data to checkpoint
     */
    function checkpoint() external nonReentrant {
        _checkpoint(
            ZERO_ADDRESS,
            EMPTY_LOCKED_BALANCE_FACTORY(),
            EMPTY_LOCKED_BALANCE_FACTORY()
        );
    }

    // --- Restricted Functions ---
    /**
     * @notice Set an external contract to check for approved smart contract wallets
     * @param _addr Address of Smart contract checker
     */
    function set_smart_wallet_checker(address _addr) external onlyAdmin {
        require(
            _addr != address(0) &&
                _addr.supportsInterface(
                    type(ISmartWalletWhitelist).interfaceId
                ),
            "veC/invalid-address"
        );

        smart_wallet_checker = _addr;

        emit SmartWalletCheckerSet(_addr);
    }

    /**
     * @notice Set an external contract to help create locks
     * @param _addr Address of smart contract helper.
     */
    function set_create_lock_helper(address _addr) external onlyAdmin {
        require(_addr != address(0), "veC/invalid-address");
        require(!helperSet, "veC/helper-set");

        create_lock_helper = _addr;
        helperSet = true;

        emit CreateLockHelperSet(_addr);
    }

    /**
     * @notice Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
     * @param tokenAddress Address of the token to recover
     * @param tokenAmount The amount of tokens to transfer
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        override
        onlyAdmin
    {
        // Admin cannot withdraw the staking token
        require(
            tokenAddress != address(token),
            "veC/cannot-withdraw-vested-token"
        );
        // Only the owner address can ever receive the recovery withdrawal
        IERC20 erc20Token = IERC20(tokenAddress);
        erc20Token.safeTransfer(_msgSender(), tokenAmount);

        emit Recovered(tokenAddress, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IVotingManager.sol";
import "./interfaces/IIdeaManager.sol";
import "./interfaces/IRewardManager.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IRegistry.sol";
import "./utils/AdminableUpgradeable.sol";

contract VotingManager is
    AdminableUpgradeable,
    IVotingManager,
    ERC165Upgradeable,
    UUPSUpgradeable
{
    using ERC165Checker for address;

    bytes4 public constant IID_IVOTINGMANAGER =
        type(IVotingManager).interfaceId;

    IVotingEscrow public votingEscrow;
    address public registry;
    address public epochManager;
    address public ideaManager;
    address public rewardManager;

    uint256 public constant PERCENTAGES_DECIMALS = 7;
    uint256 public constant PERCENTAGES_MULTIPLE = 1e7; // max decimals the protocol can do
    uint256 public votingPowerThreshold; // minimum amount of voting power needed to submit a ballot
    uint256 public maxVotingPowerThreshold; // maximum value for voting power threshold
    uint256 public maxNumOfVotesPerBallot; // maximum number of votes in a ballot

    mapping(address => mapping(uint256 => Ballot)) private _epochBallots; // votes over epochs
    mapping(address => EpochInfo) private _epochParticipated; // epochs a voter has participated in
    mapping(uint256 => uint256) private _epochVotingPower; // epochId => consumed voting power
    mapping(uint256 => uint256) private _epochTotalVotingPower; // epochId => total voting power including unconsumed
    mapping(uint256 => mapping(uint256 => uint256)) private _ideaVotingPower; // ideaId => epochId => voting power
    mapping(uint256 => mapping(uint256 => uint256))
        private _metaverseVotingPower; // metaverseId => epochId => voting power
    mapping(address => bool) private _deniedList; // Denied list of voters

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _veContract, address _registry)
        external
        initializer
    {
        require(_veContract != address(0), "VotingM: invalid address");
        require(
            _registry != address(0) &&
                _registry.supportsInterface(type(IRegistry).interfaceId),
            "EpochM: invalid address"
        );

        __Adminable_init();
        __ERC165_init();
        __UUPSUpgradeable_init();

        votingEscrow = IVotingEscrow(_veContract);
        registry = _registry;
        votingPowerThreshold = 5e14;
        maxNumOfVotesPerBallot = 20;
        maxVotingPowerThreshold = 1e20; // 100 tokens locked for 4 years
    }

    modifier onlyVeContract() {
        require(
            _msgSender() == address(votingEscrow),
            "VotingM: only VeContract"
        );
        _;
    }

    modifier onlyEpochManager() {
        require(_msgSender() == epochManager, "VotingM: only EpochManager");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused(), "VotingM: paused");
        _;
    }

    function submitBallot(Vote[] calldata _votes)
        external
        override
        whenNotPaused
    {
        require(!_isThisEpochEnded(), "VotingM: epoch already over");
        require(_isValidBallot(_votes), "VotingM: invalid ballot");
        address _voter = _msgSender();
        require(!isDenied(_voter), "VotingM: voter is denied");
        uint256 _total = getVotingPowerForCurrentEpoch(_voter);
        require(
            _total > votingPowerThreshold,
            "VotingM: not reaching threshold"
        );

        uint256 _epochId = getThisEpoch().epochId;
        // If user has already voted in this epoch, we need to "rewind" their
        // previous ballot before submitting the new one
        if (_epochBallots[_voter][_epochId].total > 0) {
            _rewind(_voter);
        }

        _epochBallots[_voter][_epochId].total = _total;
        _epochVotingPower[_epochId] += _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        for (uint256 i = 0; i < _votes.length; i++) {
            _ideaId = _votes[i].ideaId;
            _ideaPercentage = _votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _epochBallots[_voter][_epochId].votes.push(_votes[i]);
            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] += _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] += _powerAllocatedToThisProposal;
        }

        uint256 nEpochs = _epochParticipated[_voter].epochIds.length;
        if (nEpochs == 0) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        } else if (
            _epochParticipated[_voter].epochIds[nEpochs - 1] < _epochId
        ) {
            _epochParticipated[_voter].epochIds.push(_epochId);
        }

        emit BallotSubmitted(_voter, _epochId, _votes, _total);
    }

    function onVotingPowerUpdated(address account)
        external
        override
        onlyVeContract
    {
        _onVotingPowerUpdated(account);
    }

    function onEpochStarted() external override onlyEpochManager {
        uint256 _epochId = IEpochManager(epochManager).getCurEpochId();
        uint256 totalVotingPower = votingEscrow.totalSupply();
        _epochTotalVotingPower[_epochId] = totalVotingPower;

        emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
    }

    function endThisEpoch() external override {
        uint256 _epochId = getThisEpoch().epochId;
        if (_epochId > 0) {
            if (_isThisEpochEnded()) {
                IRewardManager(rewardManager).onEpochEnded();
            }
        }
    }

    function setContracts() external override onlyAdmin {
        require(registry != address(0), "VotingM: invalid Registry");
        ideaManager = IRegistry(registry).ideaManager();
        epochManager = IRegistry(registry).epochManager();
        rewardManager = IRegistry(registry).rewardManager();
        require(ideaManager != address(0), "VotingM: invalid IdeaManager");
        require(epochManager != address(0), "VotingM: invalid EpochManager");
        require(rewardManager != address(0), "VotingM: invalid RewardManager");

        emit ContractsSet(ideaManager, epochManager, rewardManager);
    }

    function setVotingPowerThreshold(uint256 _newThreshold)
        external
        override
        onlyAdmin
    {
        require(_newThreshold > 0, "VotingM: invalid threshold");
        require(
            _newThreshold <= maxVotingPowerThreshold,
            "VotingM: invalid threshold"
        );
        uint256 oldThreshold = votingPowerThreshold;
        votingPowerThreshold = _newThreshold;

        emit VotingPowerThresholdSet(oldThreshold, votingPowerThreshold);
    }

    function setMaxNumOfVotesPerBallot(uint256 _newNumber)
        external
        override
        onlyAdmin
    {
        require(_newNumber > 0, "VotingM: invalid number");
        uint256 oldNumber = maxNumOfVotesPerBallot;
        maxNumOfVotesPerBallot = _newNumber;

        emit MaxNumOfVotesPerBallotSet(oldNumber, maxNumOfVotesPerBallot);
    }

    function toggleDenied(address account) external override onlyAdmin {
        require(account != address(0), "VotingM: invalid address");
        _deniedList[account] = !_deniedList[account];

        emit AccountDeniedStatusToggled(account);
    }

    function getThisEpoch()
        public
        view
        override
        returns (IEpochManager.Epoch memory)
    {
        return IEpochManager(epochManager).getThisEpoch();
    }

    function getBallot(address account, uint256 _epochId)
        external
        view
        override
        returns (Ballot memory)
    {
        return _epochBallots[account][_epochId];
    }

    function getEpochsParticipated(address account)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _epochParticipated[account].epochIds;
    }

    function getWeightInVotingPower(address account, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        uint256 accountVotingPower = _epochBallots[account][_epochId].total;
        uint256 epochTotalVotingPower = _epochVotingPower[_epochId];

        if (epochTotalVotingPower != 0) {
            return
                (PERCENTAGES_MULTIPLE * accountVotingPower) /
                epochTotalVotingPower;
        } else {
            return 0;
        }
    }

    function getIdeaVotingPower(uint256 _ideaId, uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _ideaVotingPower[_ideaId][_epochId];
    }

    function getMetaverseVotingPower(uint256 metaverseId, uint256 epochId)
        external
        view
        override
        returns (uint256)
    {
        return _metaverseVotingPower[metaverseId][epochId];
    }

    function getEpochVotingPower(uint256 _epochId)
        external
        view
        override
        returns (uint256)
    {
        return _epochVotingPower[_epochId];
    }

    function getVotingPowerForCurrentEpoch(address account)
        public
        view
        override
        returns (uint256)
    {
        return votingEscrow.balanceOf(account, getThisEpoch().startingTime);
    }

    function getTotalVotingPowerForEpoch(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        return _epochTotalVotingPower[_epochId];
    }

    function getVotingPowerConsumptionRate(uint256 _epochId)
        public
        view
        override
        returns (uint256)
    {
        uint256 consumedVotingPower = _epochVotingPower[_epochId];
        uint256 totalVotingPower = _epochTotalVotingPower[_epochId];

        if (totalVotingPower > 0) {
            return
                (PERCENTAGES_MULTIPLE * consumedVotingPower) / totalVotingPower;
        } else {
            return 0;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == this.onVotingPowerUpdated.selector ||
            interfaceId == type(IVotingManager).interfaceId ||
            ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function isValidBallot(Vote[] calldata _votes)
        external
        view
        override
        returns (bool)
    {
        return _isValidBallot(_votes);
    }

    function isDenied(address voter) public view override returns (bool) {
        return _deniedList[voter];
    }

    function _onVotingPowerUpdated(address account) private {
        uint256 _epochId = getThisEpoch().epochId;

        if (!_isThisEpochEnded()) {
            if (_epochBallots[account][_epochId].total > 0) {
                uint256 _total = getVotingPowerForCurrentEpoch(account);
                _update(account);
                _epochBallots[account][_epochId].total = _total;

                emit VotingPowerUpdated(account, _total);
            }

            uint256 totalVotingPower = _getTotalVotingPowerFromVotingEscrowForThisEpoch();
            _epochTotalVotingPower[_epochId] = totalVotingPower;

            emit TotalVotingPowerUpdated(_epochId, totalVotingPower);
        }
    }

    function _isValidBallot(Vote[] memory _votes) private view returns (bool) {
        uint256 nVotes = _votes.length;
        // If a user chooses to abstain, that is still represented as
        // a single vote for voteID `1` ("no proposal")
        if (nVotes == 0) return false;
        if (nVotes > maxNumOfVotesPerBallot) return false;

        uint256 totalPercentage;
        uint256 _ideaId;

        for (uint256 i = 0; i < nVotes; i++) {
            if (i == 0) {
                _ideaId = _votes[i].ideaId;
                if (!_isValidIdea(_ideaId)) {
                    return false;
                }
                totalPercentage = _votes[i].percentage;
            } else {
                uint256 _nextIdeaId = _votes[i].ideaId;
                if (_nextIdeaId <= _ideaId) {
                    return false;
                }
                if (!_isValidIdea(_nextIdeaId)) {
                    return false;
                }
                _ideaId = _nextIdeaId;
                totalPercentage += _votes[i].percentage;
            }
        }

        if (totalPercentage != PERCENTAGES_MULTIPLE) return false; // A valid ballot has 100%

        return true;
    }

    // precondition: caller has verified that _voter has previously cast a
    // ballot in this epoch
    function _rewind(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        _epochVotingPower[_epochId] -= _total;

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _powerAllocatedToThisProposal;
        uint256 _metaverseId;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);

            _powerAllocatedToThisProposal =
                (_total * _ideaPercentage) /
                PERCENTAGES_MULTIPLE;
            _ideaVotingPower[_ideaId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
            _metaverseVotingPower[_metaverseId][
                _epochId
            ] -= _powerAllocatedToThisProposal;
        }

        delete _epochBallots[_voter][_epochId];
    }

    function _update(address _voter) private {
        uint256 _epochId = getThisEpoch().epochId;
        Ballot memory _lastBallot = _epochBallots[_voter][_epochId];
        uint256 _total = _lastBallot.total;
        uint256 _newTotal = getVotingPowerForCurrentEpoch(_voter);
        bool _isLarger = _newTotal > _total;
        uint256 _diff = _isLarger ? _newTotal - _total : _total - _newTotal;
        if (_isLarger) {
            _epochVotingPower[_epochId] += _diff;
        } else {
            _epochVotingPower[_epochId] -= _diff;
        }

        uint256 _ideaId;
        uint256 _ideaPercentage;
        uint256 _metaverseId;
        uint256 _diffPower;
        uint256 nVotes = _lastBallot.votes.length;
        for (uint256 i = 0; i < nVotes; i++) {
            _ideaId = _lastBallot.votes[i].ideaId;
            _ideaPercentage = _lastBallot.votes[i].percentage;
            _metaverseId = _getMetaverseId(_ideaId);
            _diffPower = (_diff * _ideaPercentage) / PERCENTAGES_MULTIPLE;

            if (_isLarger) {
                _ideaVotingPower[_ideaId][_epochId] += _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] += _diffPower;
            } else {
                _ideaVotingPower[_ideaId][_epochId] -= _diffPower;
                _metaverseVotingPower[_metaverseId][_epochId] -= _diffPower;
            }
        }
    }

    function _getTotalVotingPowerFromVotingEscrowForThisEpoch()
        private
        view
        returns (uint256)
    {
        uint256 startingTime = getThisEpoch().startingTime;
        return votingEscrow.totalSupply(startingTime);
    }

    function _isValidIdea(uint256 _ideaId) private view returns (bool) {
        if (_ideaId == 0) return false; // ideaId 0 always returns false.
        if (_ideaId == 1) return true; // ideaId 1 always returns true.
        bool cond1 = _exists(_ideaId);
        bool cond2 = _isIdeaActive(_ideaId);
        return cond1 && cond2;
    }

    function _isThisEpochEnded() private view returns (bool) {
        return IEpochManager(epochManager).isThisEpochEnded();
    }

    function _exists(uint256 ideaId) private view returns (bool) {
        return IIdeaManager(ideaManager).exists(ideaId);
    }

    function _isIdeaActive(uint256 _ideaId) private view returns (bool) {
        return IEpochManager(epochManager).isIdeaActive(_ideaId);
    }

    function _getMetaverseId(uint256 _ideaId) private view returns (uint256) {
        return IIdeaManager(ideaManager).getIdeaInfo(_ideaId).idea.metaverseId;
    }

    function _paused() private view returns (bool) {
        return IEpochManager(epochManager).paused();
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract WrappedSLN is ERC20 {
    constructor() ERC20("Wrapped SLN", "WSLN") {}

    function mint() external payable {
        _mint(msg.sender, msg.value);
    }

    function burn(uint amount) external {
        payable(msg.sender).transfer(amount);
        _burn(msg.sender, amount);
    }
}