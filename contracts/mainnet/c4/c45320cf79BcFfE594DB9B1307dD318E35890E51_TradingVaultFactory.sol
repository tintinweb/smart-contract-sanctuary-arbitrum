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
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "./IAccessControl.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
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
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
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
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Clones.sol)

pragma solidity ^0.8.20;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 */
library Clones {
    /**
     * @dev A clone instance deployment failed.
     */
    error ERC1167FailedCreateClone();

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import {
    CoreAccessControlInitiable,
    CoreAccessControlConfig
} from "../core/CoreAccessControl/v1/CoreAccessControlInitiable.sol";
import { CoreStopGuardian } from "../core/CoreStopGuardian/v1/CoreStopGuardian.sol";

import { CoreStopGuardianTrading } from "../core/CoreStopGuardianTrading/v1/CoreStopGuardianTrading.sol";

abstract contract BaseAccessControlInitiable is CoreAccessControlInitiable, CoreStopGuardian, CoreStopGuardianTrading {
    /**
     * @dev
     * Modifiers inherited from CoreAccessControl:
     * onlyDefinitive
     * onlyClients
     * onlyWhitelisted
     * onlyClientAdmin
     * onlyDefinitiveAdmin
     *
     * Modifiers inherited from CoreStopGuardian:
     * stopGuarded
     */

    function __BaseAccessControlInitiable__init(
        CoreAccessControlConfig calldata coreAccessControlConfig
    ) internal onlyInitializing {
        __CoreAccessControlInitiable__init(coreAccessControlConfig);
        GLOBAL_TRADE_GUARDIAN = 0xE3F35754954B0B77958C72b83EC5205971463064;
    }

    /**
     * @dev Inherited from CoreStopGuardianTrading
     */
    function updateGlobalTradeGuardian(address _globalTradeGuardian) external override onlyAdmins {
        return _updateGlobalTradeGuardian(_globalTradeGuardian);
    }

    /**
     * @dev Inherited from CoreStopGuardian
     */
    function enableStopGuardian() public override onlyAdmins {
        return _enableStopGuardian();
    }

    /**
     * @dev Inherited from CoreStopGuardian
     */
    function disableStopGuardian() public override onlyClientAdmin {
        return _disableStopGuardian();
    }

    /**
     * @dev Inherited from CoreStopGuardianTrading
     */

    function disableTrading() public override onlyAdmins {
        return _disableTrading();
    }

    /**
     * @dev Inherited from CoreStopGuardianTrading
     */
    function enableTrading() public override onlyAdmins {
        return _enableTrading();
    }

    /**
     * @dev Inherited from CoreStopGuardianTrading
     */
    function disableWithdrawals() public override onlyClientAdmin {
        return _disableWithdrawals();
    }

    /**
     * @dev Inherited from CoreStopGuardianTrading
     */
    function enableWithdrawals() public override onlyClientAdmin {
        return _enableWithdrawals();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { BaseAccessControlInitiable } from "./BaseAccessControlInitiable.sol";
import { CoreFeesInitiable, CoreFeesConfig } from "../core/CoreFees/v1/CoreFeesInitiable.sol";
import { DefinitiveAssets, IERC20 } from "../core/libraries/DefinitiveAssets.sol";
import { DefinitiveConstants } from "../core/libraries/DefinitiveConstants.sol";
import { InvalidFeePercent } from "../core/libraries/DefinitiveErrors.sol";

abstract contract BaseFeesInitiable is BaseAccessControlInitiable, CoreFeesInitiable {
    using DefinitiveAssets for IERC20;

    function __BaseFeesInitiable__init(CoreFeesConfig calldata coreFeesConfig) internal onlyInitializing {
        __CoreFeesInitiable__init(coreFeesConfig);
    }

    function updateFeeAccount(address payable _feeAccount) public override onlyDefinitiveAdmin {
        _updateFeeAccount(_feeAccount);
    }

    function _handleFeesOnAmount(address token, uint256 amount, uint256 feePct) internal returns (uint256 feeAmount) {
        uint256 mMaxFeePCT = DefinitiveConstants.MAX_FEE_PCT;
        if (feePct > mMaxFeePCT) {
            revert InvalidFeePercent();
        }

        feeAmount = (amount * feePct) / mMaxFeePCT;
        if (feeAmount == 0) {
            return feeAmount;
        }

        if (token == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            DefinitiveAssets.safeTransferETH(FEE_ACCOUNT, feeAmount);
        } else {
            IERC20(token).safeTransfer(FEE_ACCOUNT, feeAmount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { BaseAccessControlInitiable } from "../../BaseAccessControlInitiable.sol";
import { IBaseNativeWrapperV1 } from "./IBaseNativeWrapperV1.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { DefinitiveAssets, IERC20 } from "../../../core/libraries/DefinitiveAssets.sol";

struct BaseNativeWrapperConfig {
    address payable wrappedNativeAssetAddress;
}

abstract contract BaseNativeWrapperInitiable is IBaseNativeWrapperV1, BaseAccessControlInitiable, ReentrancyGuard {
    using DefinitiveAssets for IERC20;

    address payable public WRAPPED_NATIVE_ASSET_ADDRESS;

    function __BaseNativeWrapperInitiable__init(
        BaseNativeWrapperConfig calldata baseNativeWrapperConfig
    ) internal onlyInitializing {
        WRAPPED_NATIVE_ASSET_ADDRESS = baseNativeWrapperConfig.wrappedNativeAssetAddress;
    }

    /**
     * @notice Publicly accessible method to wrap native assets
     * @param amount Amount of native assets to wrap
     */
    function wrap(uint256 amount) public onlyWhitelisted nonReentrant {
        _wrap(amount);
        emit NativeAssetWrap(_msgSender(), amount, true /* wrappingToNative */);
    }

    /**
     * @notice Publicly accessible method to unwrap native assets
     * @param amount Amount of tokenized assets to unwrap
     */
    function unwrap(uint256 amount) public onlyWhitelisted nonReentrant {
        _unwrap(amount);
        emit NativeAssetWrap(_msgSender(), amount, false /* wrappingToNative */);
    }

    /**
     * @notice Publicly accessible method to unwrap full balance of native assets
     * @dev Method is not marked as `nonReentrant` since it is a wrapper around `unwrap`
     */
    function unwrapAll() external onlyWhitelisted {
        return unwrap(DefinitiveAssets.getBalance(WRAPPED_NATIVE_ASSET_ADDRESS));
    }

    /**
     * @notice Internal method to wrap native assets
     * @dev Override this method with native asset wrapping implementation
     */
    function _wrap(uint256 amount) internal virtual;

    /**
     * @notice Internal method to unwrap native assets
     * @dev Override this method with native asset unwrapping implementation
     */
    function _unwrap(uint256 amount) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface IBaseNativeWrapperV1 {
    event NativeAssetWrap(address actor, uint256 amount, bool indexed wrappingToNative);

    function wrap(uint256 amount) external;

    function unwrap(uint256 amount) external;

    function unwrapAll() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { BaseFeesInitiable } from "./BaseFeesInitiable.sol";
import {
    CoreSimpleSwapInitiable,
    CoreSimpleSwapConfig,
    SwapPayload
} from "../core/CoreSimpleSwap/v1/CoreSimpleSwapInitiable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { DefinitiveConstants } from "../core/libraries/DefinitiveConstants.sol";
import { InvalidFeePercent, SlippageExceeded } from "../core/libraries/DefinitiveErrors.sol";
import { ICoreSwapHandlerV1 } from "../core/CoreSwapHandler/ICoreSwapHandlerV1.sol";

abstract contract BaseSimpleSwapInitiable is BaseFeesInitiable, CoreSimpleSwapInitiable, ReentrancyGuard {
    function __BaseSimpleSwapInitiable__init(
        CoreSimpleSwapConfig calldata coreSimpleSwapConfig
    ) internal onlyInitializing {
        __CoreSimpleSwapInitiable__init(coreSimpleSwapConfig);
    }

    function enableSwapHandlers(address[] memory swapHandlers) public override onlyHandlerManager stopGuarded {
        _updateSwapHandlers(swapHandlers, true);
    }

    function disableSwapHandlers(address[] memory swapHandlers) public override onlyAdmins {
        _updateSwapHandlers(swapHandlers, false);
    }

    function swap(
        SwapPayload[] memory payloads,
        address outputToken,
        uint256 amountOutMin,
        uint256 feePct
    ) external override onlyDefinitive nonReentrant stopGuarded tradingEnabled returns (uint256) {
        if (feePct > DefinitiveConstants.MAX_FEE_PCT) {
            revert InvalidFeePercent();
        }

        (uint256[] memory inputAmounts, uint256 outputAmount) = _swap(payloads, outputToken);
        if (outputAmount < amountOutMin) {
            revert SlippageExceeded(outputAmount, amountOutMin);
        }

        address[] memory swapTokens = new address[](payloads.length);
        uint256 swapTokensLength = swapTokens.length;
        for (uint256 i; i < swapTokensLength; ) {
            swapTokens[i] = payloads[i].swapToken;
            unchecked {
                ++i;
            }
        }

        uint256 feeAmount;
        if (FEE_ACCOUNT != address(0) && outputAmount > 0 && feePct > 0) {
            feeAmount = _handleFeesOnAmount(outputToken, outputAmount, feePct);
        }
        emit SwapHandled(swapTokens, inputAmounts, outputToken, outputAmount, feeAmount);

        return outputAmount;
    }

    function _getEncodedSwapHandlerCalldata(
        SwapPayload memory payload,
        address expectedOutputToken,
        bool isDelegateCall
    ) internal pure override returns (bytes memory) {
        bytes4 selector = isDelegateCall
            ? ICoreSwapHandlerV1.swapDelegate.selector
            : ICoreSwapHandlerV1.swapCall.selector;
        ICoreSwapHandlerV1.SwapParams memory _params = ICoreSwapHandlerV1.SwapParams({
            inputAssetAddress: payload.swapToken,
            inputAmount: payload.amount,
            outputAssetAddress: expectedOutputToken,
            minOutputAmount: payload.amountOutMin,
            data: payload.handlerCalldata,
            signature: payload.signature
        });
        return abi.encodeWithSelector(selector, _params);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { AccessControl as OZAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ICoreAccessControlV1 } from "./ICoreAccessControlV1.sol";
import { AccountNotAdmin, AccountNotWhitelisted, AccountMissingRole } from "../../libraries/DefinitiveErrors.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

struct CoreAccessControlConfig {
    address admin;
    address definitiveAdmin;
    address[] definitive;
    address[] client;
}

abstract contract CoreAccessControlInitiable is ICoreAccessControlV1, OZAccessControl, Initializable {
    // roles
    bytes32 public constant ROLE_DEFINITIVE = keccak256("DEFINITIVE");
    bytes32 public constant ROLE_DEFINITIVE_ADMIN = keccak256("DEFINITIVE_ADMIN");
    bytes32 public constant ROLE_CLIENT = keccak256("CLIENT");

    // keccak256("HANDLER_MANAGER")
    bytes32 internal constant ROLE_HANDLER_MANAGER = 0xb2b11089d67559292849a1467a255e145c674dd358427860d2c8f589cfbd7aa2;

    modifier onlyDefinitive() {
        _checkRole(ROLE_DEFINITIVE);
        _;
    }
    modifier onlyDefinitiveAdmin() {
        _checkRole(ROLE_DEFINITIVE_ADMIN);
        _;
    }
    modifier onlyClients() {
        _checkRole(ROLE_CLIENT);
        _;
    }
    modifier onlyClientAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyHandlerManager() {
        _checkRole(ROLE_HANDLER_MANAGER);
        _;
    }
    // default admin + definitive admin
    modifier onlyAdmins() {
        bool isAdmins = (hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(ROLE_DEFINITIVE_ADMIN, _msgSender()));

        if (!isAdmins) {
            revert AccountNotAdmin(_msgSender());
        }
        _;
    }
    // client + definitive
    modifier onlyWhitelisted() {
        bool isWhitelisted = (hasRole(ROLE_CLIENT, _msgSender()) || hasRole(ROLE_DEFINITIVE, _msgSender()));

        if (!isWhitelisted) {
            revert AccountNotWhitelisted(_msgSender());
        }
        _;
    }

    function __CoreAccessControlInitiable__init(CoreAccessControlConfig calldata cfg) internal onlyInitializing {
        // admin
        _grantRole(DEFAULT_ADMIN_ROLE, cfg.admin);
        _grantRole(ROLE_HANDLER_MANAGER, cfg.definitiveAdmin);
        _grantRole(ROLE_HANDLER_MANAGER, cfg.admin);

        // definitive admin
        _grantRole(ROLE_DEFINITIVE_ADMIN, cfg.definitiveAdmin);
        _setRoleAdmin(ROLE_DEFINITIVE_ADMIN, ROLE_DEFINITIVE_ADMIN);

        // definitive
        uint256 cfgDefinitiveLength = cfg.definitive.length;
        for (uint256 i; i < cfgDefinitiveLength; ) {
            _grantRole(ROLE_DEFINITIVE, cfg.definitive[i]);
            unchecked {
                ++i;
            }
        }
        _setRoleAdmin(ROLE_DEFINITIVE, ROLE_DEFINITIVE_ADMIN);

        // clients - implicit role admin is DEFAULT_ADMIN_ROLE
        uint256 cfgClientLength = cfg.client.length;
        for (uint256 i; i < cfgClientLength; ) {
            _grantRole(ROLE_CLIENT, cfg.client[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _checkRole(bytes32 role, address account) internal view virtual override {
        if (!hasRole(role, account)) {
            revert AccountMissingRole(account, role);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

interface ICoreAccessControlV1 is IAccessControl {
    function ROLE_CLIENT() external returns (bytes32);

    function ROLE_DEFINITIVE() external returns (bytes32);

    function ROLE_DEFINITIVE_ADMIN() external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { ICoreFeesV1 } from "./ICoreFeesV1.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

struct CoreFeesConfig {
    address payable feeAccount;
}

abstract contract CoreFeesInitiable is ICoreFeesV1, Context, Initializable {
    address payable public FEE_ACCOUNT;

    function __CoreFeesInitiable__init(CoreFeesConfig calldata coreFeesConfig) internal onlyInitializing {
        FEE_ACCOUNT = coreFeesConfig.feeAccount;
    }

    function _updateFeeAccount(address payable feeAccount) internal {
        FEE_ACCOUNT = feeAccount;
        emit FeeAccountUpdated(_msgSender(), feeAccount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface ICoreFeesV1 {
    event FeeAccountUpdated(address actor, address feeAccount);

    function FEE_ACCOUNT() external returns (address payable);

    function updateFeeAccount(address payable feeAccount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { ICoreSimpleSwapV1 } from "./ICoreSimpleSwapV1.sol";
import { DefinitiveAssets, IERC20 } from "../../libraries/DefinitiveAssets.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { CallUtils } from "../../../tools/BubbleReverts/BubbleReverts.sol";
import { DefinitiveConstants } from "../../libraries/DefinitiveConstants.sol";
import {
    InvalidSwapHandler,
    InsufficientSwapTokenBalance,
    SwapTokenIsOutputToken,
    InvalidOutputToken,
    InvalidReportedOutputAmount,
    InvalidExecutedOutputAmount
} from "../../libraries/DefinitiveErrors.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { SwapPayload } from "./ICoreSimpleSwapV1.sol";

struct CoreSimpleSwapConfig {
    address[] swapHandlers;
}

abstract contract CoreSimpleSwapInitiable is ICoreSimpleSwapV1, Context, Initializable {
    using DefinitiveAssets for IERC20;

    /// @dev handler contract => enabled
    mapping(address => bool) public _swapHandlers;

    function __CoreSimpleSwapInitiable__init(
        CoreSimpleSwapConfig calldata coreSimpleSwapConfig
    ) internal onlyInitializing {
        uint256 handlersLength = coreSimpleSwapConfig.swapHandlers.length;
        for (uint256 i; i < handlersLength; ) {
            _swapHandlers[coreSimpleSwapConfig.swapHandlers[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function enableSwapHandlers(address[] memory swapHandlers) public virtual;

    function disableSwapHandlers(address[] memory swapHandlers) public virtual;

    function _updateSwapHandlers(address[] memory swapHandlers, bool enabled) internal {
        uint256 swapHandlersLength = swapHandlers.length;
        for (uint256 i; i < swapHandlersLength; ) {
            _swapHandlers[swapHandlers[i]] = enabled;
            emit SwapHandlerUpdate(_msgSender(), swapHandlers[i], enabled);
            unchecked {
                ++i;
            }
        }
    }

    function swap(
        SwapPayload[] memory payloads,
        address outputToken,
        uint256 amountOutMin,
        uint256 feePct
    ) external virtual returns (uint256 outputAmount);

    function _swap(
        SwapPayload[] memory payloads,
        address expectedOutputToken
    ) internal returns (uint256[] memory inputTokenAmounts, uint256 outputTokenAmount) {
        uint256 payloadsLength = payloads.length;
        inputTokenAmounts = new uint256[](payloadsLength);
        uint256 outputTokenBalanceStart = DefinitiveAssets.getBalance(expectedOutputToken);

        for (uint256 i; i < payloadsLength; ) {
            SwapPayload memory payload = payloads[i];

            if (!_swapHandlers[payload.handler]) {
                revert InvalidSwapHandler();
            }

            if (expectedOutputToken == payload.swapToken) {
                revert SwapTokenIsOutputToken();
            }

            uint256 outputTokenBalanceBefore = DefinitiveAssets.getBalance(expectedOutputToken);
            inputTokenAmounts[i] = DefinitiveAssets.getBalance(payload.swapToken);

            (uint256 _outputAmount, address _outputToken) = _processSwap(payload, expectedOutputToken);

            if (_outputToken != expectedOutputToken) {
                revert InvalidOutputToken();
            }
            if (_outputAmount < payload.amountOutMin) {
                revert InvalidReportedOutputAmount();
            }
            uint256 outputTokenBalanceAfter = DefinitiveAssets.getBalance(expectedOutputToken);

            if ((outputTokenBalanceAfter - outputTokenBalanceBefore) < payload.amountOutMin) {
                revert InvalidExecutedOutputAmount();
            }

            // Update `inputTokenAmounts` to reflect the amount of tokens actually swapped
            inputTokenAmounts[i] -= DefinitiveAssets.getBalance(payload.swapToken);
            unchecked {
                ++i;
            }
        }

        outputTokenAmount = DefinitiveAssets.getBalance(expectedOutputToken) - outputTokenBalanceStart;
    }

    function _processSwap(SwapPayload memory payload, address expectedOutputToken) private returns (uint256, address) {
        // Override payload.amount with validated amount
        payload.amount = _getValidatedPayloadAmount(payload);

        bytes memory _calldata = _getEncodedSwapHandlerCalldata(payload, expectedOutputToken, payload.isDelegate);

        bool _success;
        bytes memory _returnBytes;
        if (payload.isDelegate) {
            // slither-disable-next-line controlled-delegatecall
            (_success, _returnBytes) = payload.handler.delegatecall(_calldata);
        } else {
            uint256 msgValue = _prepareAssetsForNonDelegateHandlerCall(payload, payload.amount);
            (_success, _returnBytes) = payload.handler.call{ value: msgValue }(_calldata);
        }

        if (!_success) {
            CallUtils.revertFromReturnedData(_returnBytes);
        }

        return abi.decode(_returnBytes, (uint256, address));
    }

    function _getEncodedSwapHandlerCalldata(
        SwapPayload memory payload,
        address expectedOutputToken,
        bool isDelegateCall
    ) internal pure virtual returns (bytes memory);

    function _getValidatedPayloadAmount(SwapPayload memory payload) private view returns (uint256 amount) {
        uint256 balance = DefinitiveAssets.getBalance(payload.swapToken);

        // Ensure balance > 0
        DefinitiveAssets.validateAmount(balance);

        amount = payload.amount;

        if (amount != 0 && balance < amount) {
            revert InsufficientSwapTokenBalance();
        }

        // maximum available balance if amount == 0
        if (amount == 0) {
            return balance;
        }
    }

    function _prepareAssetsForNonDelegateHandlerCall(
        SwapPayload memory payload,
        uint256 amount
    ) private returns (uint256 msgValue) {
        if (payload.swapToken == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            return amount;
        } else {
            IERC20(payload.swapToken).resetAndSafeIncreaseAllowance(address(this), payload.handler, amount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

struct SwapPayload {
    address handler;
    uint256 amount; // set 0 for maximum available balance
    address swapToken;
    uint256 amountOutMin;
    bool isDelegate;
    bytes handlerCalldata;
    bytes signature;
}

interface ICoreSimpleSwapV1 {
    event SwapHandlerUpdate(address actor, address swapHandler, bool isEnabled);
    event SwapHandled(
        address[] swapTokens,
        uint256[] swapAmounts,
        address outputToken,
        uint256 outputAmount,
        uint256 feeAmount
    );

    function enableSwapHandlers(address[] memory swapHandlers) external;

    function disableSwapHandlers(address[] memory swapHandlers) external;

    function swap(
        SwapPayload[] memory payloads,
        address outputToken,
        uint256 amountOutMin,
        uint256 feePct
    ) external returns (uint256 outputAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { ICoreStopGuardianV1 } from "./ICoreStopGuardianV1.sol";

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { StopGuardianEnabled } from "../../libraries/DefinitiveErrors.sol";

abstract contract CoreStopGuardian is ICoreStopGuardianV1, Context {
    bool public STOP_GUARDIAN_ENABLED;

    // recommended for every public/external function
    modifier stopGuarded() {
        if (STOP_GUARDIAN_ENABLED) {
            revert StopGuardianEnabled();
        }

        _;
    }

    function enableStopGuardian() public virtual;

    function disableStopGuardian() public virtual;

    function _enableStopGuardian() internal {
        STOP_GUARDIAN_ENABLED = true;
        emit StopGuardianUpdate(_msgSender(), true);
    }

    function _disableStopGuardian() internal {
        STOP_GUARDIAN_ENABLED = false;
        emit StopGuardianUpdate(_msgSender(), false);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface ICoreStopGuardianV1 {
    event StopGuardianUpdate(address indexed actor, bool indexed isEnabled);

    function STOP_GUARDIAN_ENABLED() external view returns (bool);

    function enableStopGuardian() external;

    function disableStopGuardian() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { ICoreStopGuardianTradingV1 } from "./ICoreStopGuardianTradingV1.sol";

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { WithdrawalsDisabled, TradingDisabled, GlobalStopGuardianEnabled } from "../../libraries/DefinitiveErrors.sol";
import { IGlobalGuardian } from "../../../tools/GlobalGuardian/IGlobalGuardian.sol";

abstract contract CoreStopGuardianTrading is ICoreStopGuardianTradingV1, Context {
    event GlobalTradeGuardianUpdate(address indexed globalTradeGuardian);

    /// @notice For minimal clone strategies, this will be initialized as address(0)
    /// It is expected that this value will be reinitialized in the `initialize` function
    address public GLOBAL_TRADE_GUARDIAN = 0xE3F35754954B0B77958C72b83EC5205971463064;

    bool public TRADING_GUARDIAN_TRADING_DISABLED;
    bool public TRADING_GUARDIAN_WITHDRAWALS_DISABLED;

    /// 0x49feb0371fc9661748a3d1bc01dbf9f5cdeb4102767351e1c6dd1f5d331acd6d
    bytes32 internal constant GLOBAL_TRADING_HASH = keccak256("TRADING");

    modifier tradingEnabled() {
        if (IGlobalGuardian(GLOBAL_TRADE_GUARDIAN).functionalityIsDisabled(GLOBAL_TRADING_HASH)) {
            revert GlobalStopGuardianEnabled();
        }

        if (TRADING_GUARDIAN_TRADING_DISABLED) {
            revert TradingDisabled();
        }
        _;
    }

    modifier withdrawalsEnabled() {
        if (TRADING_GUARDIAN_WITHDRAWALS_DISABLED) {
            revert WithdrawalsDisabled();
        }
        _;
    }

    function updateGlobalTradeGuardian(address _globalTradeGuardian) external virtual;

    function disableTrading() public virtual;

    function enableTrading() public virtual;

    function disableWithdrawals() public virtual;

    function enableWithdrawals() public virtual;

    function _updateGlobalTradeGuardian(address _globalTradeGuardian) internal {
        GLOBAL_TRADE_GUARDIAN = _globalTradeGuardian;
        emit GlobalTradeGuardianUpdate(_globalTradeGuardian);
    }

    function _disableTrading() internal {
        TRADING_GUARDIAN_TRADING_DISABLED = true;
        emit TradingDisabledUpdate(_msgSender(), true);
    }

    function _enableTrading() internal {
        delete TRADING_GUARDIAN_TRADING_DISABLED;
        emit TradingDisabledUpdate(_msgSender(), false);
    }

    function _disableWithdrawals() internal {
        TRADING_GUARDIAN_WITHDRAWALS_DISABLED = true;
        emit WithdrawalsDisabledUpdate(_msgSender(), true);
    }

    function _enableWithdrawals() internal {
        delete TRADING_GUARDIAN_WITHDRAWALS_DISABLED;
        emit WithdrawalsDisabledUpdate(_msgSender(), false);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface ICoreStopGuardianTradingV1 {
    event TradingDisabledUpdate(address indexed actor, bool indexed isEnabled);
    event WithdrawalsDisabledUpdate(address indexed actor, bool indexed isEnabled);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface ICoreSwapHandlerV1 {
    event Swap(
        address indexed actor,
        address indexed inputToken,
        uint256 inputAmount,
        address indexed outputToken,
        uint256 outputAmount
    );

    struct SwapParams {
        address inputAssetAddress;
        uint256 inputAmount;
        address outputAssetAddress;
        uint256 minOutputAmount;
        bytes data;
        bytes signature;
    }

    function swapCall(SwapParams calldata params) external payable returns (uint256 amountOut, address outputAsset);

    function swapDelegate(SwapParams calldata params) external payable returns (uint256 amountOut, address outputAsset);

    function swapUsingValidatedPathCall(
        SwapParams calldata params
    ) external payable returns (uint256 amountOut, address outputAsset);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { DefinitiveConstants } from "./DefinitiveConstants.sol";

import { InsufficientBalance, InvalidAmount, InvalidAmounts, InvalidERC20Address } from "./DefinitiveErrors.sol";

/**
 * @notice Contains methods used throughout the Definitive contracts
 * @dev This file should only be used as an internal library.
 */
library DefinitiveAssets {
    /**
     * @dev Checks if an address is a valid ERC20 token
     */
    modifier onlyValidERC20(address erc20Token) {
        if (address(erc20Token) == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            revert InvalidERC20Address();
        }
        _;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    // ↓ ERC20 and Native Asset Methods ↓
    //////////////////////////////////////////////////

    /**
     * @dev Gets the balance of an ERC20 token or native asset
     */
    function getBalance(address assetAddress) internal view returns (uint256) {
        if (assetAddress == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            return address(this).balance;
        } else {
            return IERC20(assetAddress).balanceOf(address(this));
        }
    }

    /**
     * @dev internal function to validate balance is higher than a given amount for ERC20 and native assets
     */
    function validateBalance(address token, uint256 amount) internal view {
        if (token == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            validateNativeBalance(amount);
        } else {
            validateERC20Balance(token, amount);
        }
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    // ↓ Native Asset Methods ↓
    //////////////////////////////////////////////////

    /**
     * @dev validates amount and balance, then uses SafeTransferLib to transfer native asset
     */
    function safeTransferETH(address recipient, uint256 amount) internal {
        if (amount > 0) {
            SafeTransferLib.safeTransferETH(payable(recipient), amount);
        }
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    // ↓ ERC20 Methods ↓
    //////////////////////////////////////////////////

    /**
     * @dev Resets and increases the allowance of a spender for an ERC20 token
     */
    function resetAndSafeIncreaseAllowance(
        IERC20 token,
        address owner,
        address spender,
        uint256 amount
    ) internal onlyValidERC20(address(token)) {
        return SafeERC20.forceApprove(token, spender, amount);
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal onlyValidERC20(address(token)) {
        if (amount > 0) {
            SafeERC20.safeTransfer(token, to, amount);
        }
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal onlyValidERC20(address(token)) {
        if (amount > 0) {
            //slither-disable-next-line arbitrary-send-erc20
            SafeERC20.safeTransferFrom(token, from, to, amount);
        }
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    // ↓ Asset Amount Helper Methods ↓
    //////////////////////////////////////////////////

    /**
     * @dev internal function to validate that amounts contains a value greater than zero
     */
    function validateAmounts(uint256[] calldata amounts) internal pure {
        bool hasValidAmounts;
        uint256 amountsLength = amounts.length;
        for (uint256 i; i < amountsLength; ) {
            if (amounts[i] > 0) {
                hasValidAmounts = true;
                break;
            }
            unchecked {
                ++i;
            }
        }

        if (!hasValidAmounts) {
            revert InvalidAmounts();
        }
    }

    /**
     * @dev internal function to validate if native asset balance is higher than the amount requested
     */
    function validateNativeBalance(uint256 amount) internal view {
        if (getBalance(DefinitiveConstants.NATIVE_ASSET_ADDRESS) < amount) {
            revert InsufficientBalance();
        }
    }

    /**
     * @dev internal function to validate balance is higher than the amount requested for a token
     */
    function validateERC20Balance(address token, uint256 amount) internal view onlyValidERC20(token) {
        if (getBalance(token) < amount) {
            revert InsufficientBalance();
        }
    }

    function validateAmount(uint256 _amount) internal pure {
        if (_amount == 0) {
            revert InvalidAmount();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

/**
 * @notice Contains constants used throughout the Definitive contracts
 * @dev This file should only be used as an internal library.
 */
library DefinitiveConstants {
    /**
     * @notice Maximum fee percentage
     */
    uint256 internal constant MAX_FEE_PCT = 10000;

    /**
     * @notice Address to signify native assets
     */
    address internal constant NATIVE_ASSET_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice Maximum number of swaps allowed per block
     */
    uint8 internal constant MAX_SWAPS_PER_BLOCK = 25;

    struct Assets {
        uint256[] amounts;
        address[] addresses;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

/**
 * @notice Contains all errors used throughout the Definitive contracts
 * @dev This file should only be used as an internal library.
 * @dev When adding a new error, add alphabetically
 */

error AccountMissingRole(address _account, bytes32 _role);
error AccountNotAdmin(address);
error AccountNotWhitelisted(address);
error AddLiquidityFailed();
error AlreadyDeployed();
error AlreadyInitialized();
error BytecodeEmpty();
error DeadlineExceeded();
error DeployInitFailed();
error DeployFailed();
error BorrowFailed(uint256 errorCode);
error DecollateralizeFailed(uint256 errorCode);
error DepositMoreThanMax();
error EmptyBytecode();
error EnterAllFailed();
error EnforcedSafeLTV(uint256 invalidLTV);
error ExceededMaxDelta();
error ExceededMaxLTV();
error ExceededShareToAssetRatioDeltaThreshold();
error ExitAllFailed();
error ExitOneCoinFailed();
error GlobalStopGuardianEnabled();
error InitializeMarketsFailed();
error InputGreaterThanStaked();
error InsufficientBalance();
error InsufficientSwapTokenBalance();
error InvalidAddress();
error InvalidAmount();
error InvalidAmounts();
error InvalidCalldata();
error InvalidDestinationSwapper();
error InvalidERC20Address();
error InvalidExecutedOutputAmount();
error InvalidFeePercent();
error InvalidHandler();
error InvalidInputs();
error InvalidMsgValue();
error InvalidSingleHopSwap();
error InvalidMultiHopSwap();
error InvalidOutputToken();
error InvalidRedemptionRecipient(); // Used in cross-chain redeptions
error InvalidReportedOutputAmount();
error InvalidRewardsClaim();
error InvalidSignature();
error InvalidSignatureLength();
error InvalidSwapHandler();
error InvalidSwapInputAmount();
error InvalidSwapOutputToken();
error InvalidSwapPath();
error InvalidSwapPayload();
error InvalidSwapToken();
error MintMoreThanMax();
error MismatchedChainId();
error NativeAssetWrapFailed(bool wrappingToNative);
error NoSignatureVerificationSignerSet();
error RedeemMoreThanMax();
error RemoveLiquidityFailed();
error RepayDebtFailed();
error SafeHarborModeEnabled();
error SafeHarborRedemptionDisabled();
error SlippageExceeded(uint256 _outputAmount, uint256 _outputAmountMin);
error StakeFailed();
error SupplyFailed();
error StopGuardianEnabled();
error TradingDisabled();
error SwapDeadlineExceeded();
error SwapLimitExceeded();
error SwapTokenIsOutputToken();
error TransfersLimitExceeded();
error UnstakeFailed();
error UnauthenticatedFlashloan();
error UntrustedFlashLoanSender(address);
error WithdrawMoreThanMax();
error WithdrawalsDisabled();
error ZeroShares();

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { InvalidSignature, InvalidSignatureLength } from "./DefinitiveErrors.sol";

library SignatureVerifier {
    function verifySignature(
        mapping(address => bool) storage validSigners,
        bytes32 messageHash,
        bytes memory signature
    ) internal view {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        address signer = recoverSigner(ethSignedMessageHash, signature);

        if (!validSigners[signer]) {
            revert InvalidSignature();
        }
    }

    /* cSpell:disable */
    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        /*
            Signature is produced by signing a keccak256 hash with the following format:
            "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    /* cSpell:enable */

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) private pure returns (address signer) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    // https://solidity-by-example.org/signature
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (sig.length != 65) {
            revert InvalidSignatureLength();
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import {
    BaseNativeWrapperInitiable,
    BaseNativeWrapperConfig
} from "../../base/BaseNativeWrapper/v1/BaseNativeWrapperInitiable.sol";
import { IWETH9 } from "../../vendor/interfaces/IWETH9.sol";

abstract contract WETH9NativeWrapperInitiable is BaseNativeWrapperInitiable {
    function __WETH9NativeWrapperInitiable__init(BaseNativeWrapperConfig calldata config) internal onlyInitializing {
        __BaseNativeWrapperInitiable__init(config);
    }

    function _wrap(uint256 amount) internal override {
        // slither-disable-next-line arbitrary-send-eth
        IWETH9(WRAPPED_NATIVE_ASSET_ADDRESS).deposit{ value: amount }();
    }

    function _unwrap(uint256 amount) internal override {
        IWETH9(WRAPPED_NATIVE_ASSET_ADDRESS).withdraw(amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { CoreSimpleSwapConfig } from "../../../base/BaseSimpleSwapInitiable.sol";
import { CoreAccessControlConfig } from "../../../base/BaseAccessControlInitiable.sol";
import { CoreFeesConfig } from "../../../base/BaseFeesInitiable.sol";
import { BaseNativeWrapperConfig } from "../../../modules/native-asset-wrappers/WETH9NativeWrapperInitiable.sol";

interface ITradingVaultImplementation {
    function initialize(
        BaseNativeWrapperConfig calldata baseNativeWrapperConfig,
        CoreAccessControlConfig calldata coreAccessControlConfig,
        CoreSimpleSwapConfig calldata coreSimpleSwapConfig,
        CoreFeesConfig calldata coreFeesConfig
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import {
    ITradingVaultImplementation,
    BaseNativeWrapperConfig,
    CoreAccessControlConfig,
    CoreSimpleSwapConfig,
    CoreFeesConfig
} from "./ITradingVaultImplementation.sol";
import { SignatureVerifier } from "../../../core/libraries/SignatureVerifier.sol";

import { DeadlineExceeded, MismatchedChainId, InvalidAddress } from "../../../core/libraries/DefinitiveErrors.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

struct DeployParams {
    address tradingVaultImplementation;
    uint256 chainId;
    uint256 deadline;
    bytes32 deploySalt;
    BaseNativeWrapperConfig baseNativeWrapperConfig;
    CoreAccessControlConfig coreAccessControlConfig;
    CoreSimpleSwapConfig coreSimpleSwapConfig;
    CoreFeesConfig coreFeesConfig;
}

contract TradingVaultFactory is OwnableUpgradeable, UUPSUpgradeable {
    using Clones for address;

    event NewVaultDeploy(address sender, address vault, bytes32 salt);

    event SignatureVerifierAdded(address signatureVerifier);

    event SignatureVerifierRemoved(address signatureVerifier);

    /// @custom:storage-location erc7201:openzeppelin.storage.TradingVaultFactory
    struct TradingVaultFactoryStorage {
        mapping(address => bool) isSignatureVerifier;
    }

    /* solhint-disable max-line-length */
    /* keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.TradingVaultFactory")) - 1)) & ~bytes32(uint256(0xff)) */
    bytes32 private constant TradingVaultFactoryStorageLocation =
        0x1e05315c660d2d2e3b92cca2a3c5f6e530c7e4414b0a08bd1d920d985b0e0300;

    /* solhint-enable max-line-length */

    function _getTradingVaultFactoryStorage() private pure returns (TradingVaultFactoryStorage storage $) {
        assembly {
            $.slot := TradingVaultFactoryStorageLocation
        }
    }

    /// @notice Constructor on the implementation contract should call _disableInitializers()
    /// @dev https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/2
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address[] memory _initialVerifiers) external initializer {
        __Ownable_init(_owner);
        uint256 length = _initialVerifiers.length;
        for (uint256 i = 0; i < length; ) {
            _addSignatureVerifier(_initialVerifiers[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function createVault(
        address tradingVaultImplementation,
        bytes32 salt,
        BaseNativeWrapperConfig calldata baseNativeWrapperConfig,
        CoreAccessControlConfig calldata coreAccessControlConfig,
        CoreSimpleSwapConfig calldata coreSimpleSwapConfig,
        CoreFeesConfig calldata coreFeesConfig
    ) external payable {
        bytes32 deploymentSalt = encodeSalt(msg.sender, salt);

        address vault = tradingVaultImplementation.cloneDeterministic(deploymentSalt);

        ITradingVaultImplementation(vault).initialize(
            baseNativeWrapperConfig,
            coreAccessControlConfig,
            coreSimpleSwapConfig,
            coreFeesConfig
        );

        emit NewVaultDeploy(msg.sender, vault, deploymentSalt);
    }

    function createVaultWithPermission(
        DeployParams calldata deployParams,
        bytes calldata authorizedSignature
    ) external payable {
        _verifyDeploymentParams(deployParams, authorizedSignature);

        address vault = deployParams.tradingVaultImplementation.cloneDeterministic(deployParams.deploySalt);

        ITradingVaultImplementation(vault).initialize(
            deployParams.baseNativeWrapperConfig,
            deployParams.coreAccessControlConfig,
            deployParams.coreSimpleSwapConfig,
            deployParams.coreFeesConfig
        );

        emit NewVaultDeploy(msg.sender, vault, deployParams.deploySalt);
    }

    function getVaultAddress(
        address tradingVaultImplementation,
        bytes32 deploymentSalt
    ) external view returns (address) {
        if (tradingVaultImplementation == address(0)) {
            revert InvalidAddress();
        }

        return tradingVaultImplementation.predictDeterministicAddress(deploymentSalt);
    }

    function isSignatureVerifier(address account) external view returns (bool) {
        TradingVaultFactoryStorage storage $ = _getTradingVaultFactoryStorage();

        return $.isSignatureVerifier[account];
    }

    function addSignatureVerifier(address _signatureVerifier) public onlyOwner {
        _addSignatureVerifier(_signatureVerifier);
    }

    function removeSignatureVerifier(address _signatureVerifier) public onlyOwner {
        _removeSignatureVerifier(_signatureVerifier);
    }

    function _addSignatureVerifier(address _signatureVerifier) private {
        if (_signatureVerifier == address(0)) {
            revert InvalidAddress();
        }
        TradingVaultFactoryStorage storage $ = _getTradingVaultFactoryStorage();
        $.isSignatureVerifier[_signatureVerifier] = true;
        emit SignatureVerifierAdded(_signatureVerifier);
    }

    function _removeSignatureVerifier(address _signatureVerifier) private {
        if (_signatureVerifier == address(0)) {
            revert InvalidAddress();
        }
        TradingVaultFactoryStorage storage $ = _getTradingVaultFactoryStorage();
        $.isSignatureVerifier[_signatureVerifier] = false;
        emit SignatureVerifierRemoved(_signatureVerifier);
    }

    function _verifyDeploymentParams(DeployParams calldata deployParams, bytes calldata signature) private view {
        if (deployParams.tradingVaultImplementation == address(0)) {
            revert InvalidAddress();
        }

        if (deployParams.deadline < block.timestamp) {
            revert DeadlineExceeded();
        }

        if (deployParams.chainId != block.chainid && deployParams.chainId != type(uint256).max) {
            revert MismatchedChainId();
        }
        TradingVaultFactoryStorage storage $ = _getTradingVaultFactoryStorage();

        SignatureVerifier.verifySignature($.isSignatureVerifier, encodeDeploymentParams(deployParams), signature);
    }

    function encodeSalt(address sender, bytes32 deploymentSalt) public pure returns (bytes32) {
        return keccak256(abi.encode(deploymentSalt, sender));
    }

    function encodeDeploymentParams(DeployParams calldata deployParams) public pure returns (bytes32) {
        return keccak256(abi.encode(deployParams));
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.20;

import { InvalidCalldata } from "../../core/libraries/DefinitiveErrors.sol";

/**
 * @title Call utilities library that is absent from the OpenZeppelin
 * @author Superfluid
 * Forked from
 * https://github.com/superfluid-finance/protocol-monorepo/blob
 * /d473b4876a689efb3bbb05552040bafde364a8b2/packages/ethereum-contracts/contracts/libs/CallUtils.sol
 * (Separated by 2 lines to prevent going over 120 character per line limit)
 */
library CallUtils {
    /// @dev Bubble up the revert from the returnedData (supports Panic, Error & Custom Errors)
    /// @notice This is needed in order to provide some human-readable revert message from a call
    /// @param returnedData Response of the call
    function revertFromReturnedData(bytes memory returnedData) internal pure {
        if (returnedData.length < 4) {
            // case 1: catch all
            revert("CallUtils: target revert()"); // solhint-disable-line custom-errors
        } else {
            bytes4 errorSelector;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                errorSelector := mload(add(returnedData, 0x20))
            }
            if (errorSelector == bytes4(0x4e487b71) /* `seth sig "Panic(uint256)"` */) {
                // case 2: Panic(uint256) (Defined since 0.8.0)
                // solhint-disable-next-line max-line-length
                // ref: https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require)
                string memory reason = "CallUtils: target panicked: 0x__";
                uint256 errorCode;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    errorCode := mload(add(returnedData, 0x24))
                    let reasonWord := mload(add(reason, 0x20))
                    // [0..9] is converted to ['0'..'9']
                    // [0xa..0xf] is not correctly converted to ['a'..'f']
                    // but since panic code doesn't have those cases, we will ignore them for now!
                    let e1 := add(and(errorCode, 0xf), 0x30)
                    let e2 := shl(8, add(shr(4, and(errorCode, 0xf0)), 0x30))
                    reasonWord := or(
                        and(reasonWord, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000),
                        or(e2, e1)
                    )
                    mstore(add(reason, 0x20), reasonWord)
                }
                revert(reason);
            } else {
                // case 3: Error(string) (Defined at least since 0.7.0)
                // case 4: Custom errors (Defined since 0.8.0)
                uint256 len = returnedData.length;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(returnedData, 32), len)
                }
            }
        }
    }

    /**
     * @dev Helper method to parse data and extract the method signature (selector).
     *
     * Copied from: https://github.com/argentlabs/argent-contracts/
     * blob/master/contracts/modules/common/Utils.sol#L54-L60
     */
    function parseSelector(bytes memory callData) internal pure returns (bytes4 selector) {
        if (callData.length < 4) {
            revert InvalidCalldata();
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            selector := mload(add(callData, 0x20))
        }
    }

    /**
     * @dev Pad length to 32 bytes word boundary
     */
    function padLength32(uint256 len) internal pure returns (uint256 paddedLen) {
        return ((len / 32) + (((len & 31) > 0) /* rounding? */ ? 1 : 0)) * 32;
    }

    /**
     * @dev Validate if the data is encoded correctly with abi.encode(bytesData)
     *
     * Expected ABI Encode Layout:
     * | word 1      | word 2           | word 3           | the rest...
     * | data length | bytesData offset | bytesData length | bytesData + padLength32 zeros |
     */
    function isValidAbiEncodedBytes(bytes memory data) internal pure returns (bool) {
        if (data.length < 64) return false;
        uint256 bytesOffset;
        uint256 bytesLen;
        // bytes offset is always expected to be 32
        // solhint-disable-next-line no-inline-assembly
        assembly {
            bytesOffset := mload(add(data, 32))
        }
        if (bytesOffset != 32) return false;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            bytesLen := mload(add(data, 64))
        }
        // the data length should be bytesData.length + 64 + padded bytes length
        return data.length == 64 + padLength32(bytesLen);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface IGlobalGuardian {
    function disable(bytes32 keyHash) external;

    function enable(bytes32 keyHash) external;

    function functionalityIsDisabled(bytes32 keyHash) external view returns (bool);

    function accountIsPerformer(address _account) external view returns (bool);

    function accountIsSwapHandler(address _account) external view returns (bool);

    function isDefinitiveAdmin() external view returns (bool);

    function isHandlerManager() external view returns (bool);

    function feeAccount() external view returns (address);

    function accountIsDefinitiveAdmin(address _account) external view returns (bool);

    function accountIsHandlerManager(address _account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

interface IWETH9 {
    function balanceOf(address) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
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