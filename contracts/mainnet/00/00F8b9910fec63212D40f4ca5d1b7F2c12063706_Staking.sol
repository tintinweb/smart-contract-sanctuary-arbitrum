// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {ERC165Upgradeable} from "../utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControl, ERC165Upgradeable {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;


    /// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
    struct AccessControlStorage {
        mapping(bytes32 role => RoleData) _roles;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessControlStorageLocation = 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;

    function _getAccessControlStorage() private pure returns (AccessControlStorage storage $) {
        assembly {
            $.slot := AccessControlStorageLocation
        }
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
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
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].hasRole[account];
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
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].adminRole;
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
        AccessControlStorage storage $ = _getAccessControlStorage();
        bytes32 previousAdminRole = getRoleAdmin(role);
        $._roles[role].adminRole = adminRole;
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
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (!hasRole(role, account)) {
            $._roles[role].hasRole[account] = true;
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
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (hasRole(role, account)) {
            $._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.20;

import {EnumerableSet} from "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code repetition as possible, we write it in
    // terms of a generic Map type with bytes32 keys and values. The Map implementation uses private functions,
    // and user-facing implementations such as `UintToAddressMap` are just wrappers around the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit in bytes32.

    /**
     * @dev Query for a nonexistent map key.
     */
    error EnumerableMapNonexistentKey(bytes32 key);

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 key => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        if (value == 0 && !contains(map, key)) {
            revert EnumerableMapNonexistentKey(key);
        }
        return value;
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToBytes32Map storage map) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToUintMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToAddressMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(AddressToUintMap storage map) internal view returns (address[] memory) {
        bytes32[] memory store = keys(map._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToUintMap storage map, bytes32 key, uint256 value) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToUintMap storage map) internal view returns (bytes32[] memory) {
        bytes32[] memory store = keys(map._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event PoolSet(uint16 indexed poolId, uint48 distributionPercentage);

    event BandLevelSet(
        uint16 indexed bandLevel,
        uint256 price,
        uint16[] accessiblePools
    );

    event SharesInMonthSet(uint48[] totalSharesInMonth);

    event UsdtTokenSet(IERC20 token);

    event UsdcTokenSet(IERC20 token);

    event WowTokenSet(IERC20 token);

    event TotalBandLevelsAmountSet(uint16 newTotalBandsAmount);

    event TotalPoolAmountSet(uint16 newTotalPoolAmount);

    event BandUpgradeStatusSet(bool enabled);

    event DistributionStatusSet(bool inProgress);

    event TokensWithdrawn(IERC20 token, address receiver, uint256 amount);

    event DistributionCreated(
        IERC20 token,
        uint256 amount,
        uint16 totalPools,
        uint16 totalBandLevels,
        uint256 totalStakers,
        uint256 distributionTimestamp
    );

    event RewardsDistributed(IERC20 token);

    event SharesSyncTriggered();

    event Staked(
        address user,
        uint16 bandLevel,
        uint256 bandId,
        uint8 fixedMonths,
        IStaking.StakingTypes stakingType,
        bool areTokensVested
    );

    event Unstaked(address user, uint256 bandId, bool areTokensVested);

    event VestingUserDeleted(address user);

    event BandUpgraded(
        address user,
        uint256 bandId,
        uint16 oldBandLevel,
        uint16 newBandLevel
    );

    event BandDowngraded(
        address user,
        uint256 bandId,
        uint16 oldBandLevel,
        uint16 newBandLevel
    );

    event RewardsClaimed(address user, IERC20 token, uint256 totalRewards);
}

interface IStaking is IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    enum StakingTypes {
        FIX,
        FLEXI
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct StakerBand {
        address owner; // staker who owns the band
        uint32 stakingStartDate; // timestamp for initial band creation
        uint16 bandLevel; // band levels (1-9)
        uint8 fixedMonths; // 0 for flexi, 1-24 for fix
        StakingTypes stakingType; // FLEXI or FIX
        bool areTokensVested; // true if tokens from which the band was created are vested
    }

    struct StakerReward {
        uint256 unclaimedAmount; // amount of tokens that can be claimed
        uint256 claimedAmount; // amount of tokens that have been claimed
    }

    struct BandLevel {
        uint256 price; // price in WOW tokens
        uint16[] accessiblePools; // pool ids (1-9)
    }

    struct Pool {
        uint48 distributionPercentage; // in 10^6 integrals, for divident calculation
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 usdtToken,
        IERC20 usdcToken,
        IERC20 wowToken,
        address vesting,
        address gelato,
        uint16 totalPools,
        uint16 totalBandLevels
    ) external;

    function setPool(uint16 poolId, uint48 distributionPercentage) external;

    function setBandLevel(
        uint16 bandLevel,
        uint256 price,
        uint16[] calldata accessiblePools
    ) external;

    function setSharesInMonth(uint48[] calldata totalSharesInMonth) external;

    function setUsdtToken(IERC20 token) external;

    function setUsdcToken(IERC20 token) external;

    function setWowToken(IERC20 token) external;

    function setTotalBandLevelsAmount(uint16 newTotalBandsAmount) external;

    function setTotalPoolAmount(uint16 newTotalPoolAmount) external;

    function setBandUpgradesEnabled(bool enabled) external;

    function setDistributionInProgress(bool inProgress) external;

    function withdrawTokens(IERC20 token, uint256 amount) external;

    function createDistribution(IERC20 token, uint256 amount) external;

    function distributeRewards(
        IERC20 token,
        address[] memory stakers,
        uint256[] memory rewards
    ) external;

    function triggerSharesSync() external;

    function stake(
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month
    ) external;

    function unstake(uint256 bandId) external;

    function stakeVested(
        address user,
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month
    ) external returns (uint256 bandId);

    function unstakeVested(address user, uint256 bandId) external;

    function deleteVestingUser(address user) external;

    function upgradeBand(uint256 bandId, uint16 newBandLevel) external;

    function downgradeBand(uint256 bandId, uint16 newBandLevel) external;

    function claimRewards(IERC20 token) external;

    function getTokenUSDT() external view returns (IERC20);

    function getTokenUSDC() external view returns (IERC20);

    function getTokenWOW() external view returns (IERC20);

    function getTotalPools() external view returns (uint16);

    function getTotalBandLevels() external view returns (uint16);

    function getNextBandId() external view returns (uint256);

    function getSharesInMonthArray() external view returns (uint48[] memory);

    function getSharesInMonth(
        uint256 index
    ) external view returns (uint48 shares);

    function getPool(
        uint16 poolId
    ) external view returns (uint48 distributionPercentage);

    function getBandLevel(
        uint16 bandLevel
    ) external view returns (uint256 price, uint16[] memory accessiblePools);

    function getStakerBand(
        uint256 bandId
    )
        external
        view
        returns (
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            StakingTypes stakingType,
            bool areTokensVested
        );

    function getStakerReward(
        address staker,
        IERC20 token
    ) external view returns (uint256 unclaimedAmount, uint256 claimedAmount);

    function getStakerBandIds(
        address staker
    ) external view returns (uint256[] memory bandIds);

    function getUser(uint256 index) external view returns (address user);

    function getTotalUsers() external view returns (uint256 usersAmount);

    function areBandUpgradesEnabled() external view returns (bool enabled);

    function isDistributionInProgress() external view returns (bool inProgress);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    STAKING
    //////////////////////////////////////////////////////////////////////////*/

    error Staking__InvalidBandLevel(uint16 bandLevel);
    error Staking__InvalidBandId(uint256 bandId);
    error Staking__NotFlexiTypeBand();
    error Staking__NotBandOwner(uint256 bandId, address owner);
    error Staking__InvalidStakingType();
    error Staking__MaximumLevelExceeded();
    error Staking__NonExistantToken();
    error Staking__InvalidStakingTimespan(uint256 stakingTimespan);
    error Staking__InvalidPoolId(uint16 poolId);
    error Staking__InsufficientContractBalance(
        uint256 contractBalance,
        uint256 requiredAmount
    );
    error Staking__InvalidDistributionPercentage(uint48 percentage);
    error Staking__BandAllocationExceedsMaximum(uint48 percentage);
    error Staking__TotalAllocationExceedsMaximum(uint48 percentage);
    error Staking__InvalidBandsAmount();
    error Staking__UpgradesDisabled();
    error Staking__OnlyFlexiTypeAllowed();
    error Staking__ZeroAmount();
    error Staking__ZeroAddress();
    error Staking__ZeroPoolShares();
    error Staking__MismatchedArrayLengths(
        uint256 stakersLength,
        uint256 rewardsLength
    );
    error Staking__NoRewardsToClaim();
    error Staking__InvalidMonth(uint8 month);
    error Staking__BandFromVestedTokens(bool areTokensVested);
    error Staking__UnlockDateNotReached();
    error Staking__DistributionInProgress();
    error Staking__DistributionNotInProgress();
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {Errors} from "./libraries/Errors.sol";

// solhint-disable-next-line max-states-count
contract Staking is
    IStaking,
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    /*//////////////////////////////////////////////////////////////////////////
                                    LIBRARIES
    //////////////////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20; // Wrappers around ERC20 operations that throw on failure
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /*//////////////////////////////////////////////////////////////////////////
                                PRIVATE CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint32 private constant MONTH = 30 days;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant VESTING_ROLE = keccak256("VESTING_ROLE");
    bytes32 public constant GELATO_EXECUTOR_ROLE =
        keccak256("GELATO_EXECUTOR_ROLE");

    uint48 public constant SHARE = 1e6; // 1 share = 10^6
    uint48 public constant PERCENTAGE_PRECISION = 1e8; // 100% = 10^8

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */

    // Map user => bool (if user is staking)
    // 0 - false (not staking), 1 - true (is staking)
    EnumerableMap.AddressToUintMap internal s_users;

    // Map staker => all the band ids that staker owns
    mapping(address staker => uint256[] bandIds) internal s_stakerBands;

    // Map staker => token => claimed and unclaimed rewards
    mapping(bytes32 stakerAndToken => StakerReward) internal s_stakerRewards;

    // Map single band id => band data
    mapping(uint256 bandId => StakerBand) internal s_bands;

    // Map pool id (1-9) => pool data
    mapping(uint16 poolId => Pool) internal s_poolData;

    // Map band level (1-9) => band data
    mapping(uint16 bandLevel => BandLevel) internal s_bandLevelData;

    // Array of 24 integers, each representing the amount of shares
    // User owns in the pool for each month. Used for FLEXI staking
    // 0 index represents shares after 1 month, 1 index represents shares after 2 months, etc.
    // 10**6 = 1 share
    uint48[] internal s_sharesInMonth;

    // Token to be payed as reward
    IERC20 internal s_usdtToken;

    // Token to be payed as reward
    IERC20 internal s_usdcToken;

    // Token to be staked
    IERC20 internal s_wowToken;

    // Next unique band id to be used
    uint256 internal s_nextBandId;

    // Total amount of pools used for staking (currently, 9)
    uint16 internal s_totalPools;

    // Total amount of bands used for staking (currently, 9)
    uint16 internal s_totalBandLevels;

    // Flag to know if upgrades are enabled or not
    bool internal s_bandUpgradesEnabled;

    // Flag to know if rewards distribution is in progress
    // True if distribution was created but rewards were not yet distributed
    // False if no distribution created or rewards were already distributed
    bool internal s_distributionInProgress;

    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                            STORAGE FOR FUTURE UPGRADES
    //////////////////////////////////////////////////////////////////////////*/

    uint256[50] private __gap;

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mAddressNotZero(address addr) {
        if (addr == address(0)) {
            revert Errors.Staking__ZeroAddress();
        }
        _;
    }

    modifier mAmountNotZero(uint256 amount) {
        if (amount == 0) {
            revert Errors.Staking__ZeroAmount();
        }
        _;
    }

    modifier mBandLevelExists(uint16 bandLevel) {
        if (bandLevel == 0 || bandLevel > s_totalBandLevels) {
            revert Errors.Staking__InvalidBandLevel(bandLevel);
        }
        _;
    }

    modifier mBandOwner(address user, uint256 bandId) {
        if (s_bands[bandId].owner != user) {
            revert Errors.Staking__NotBandOwner(bandId, user);
        }
        _;
    }

    modifier mOnlyFlexiType(uint256 bandId) {
        if (StakingTypes.FIX == s_bands[bandId].stakingType) {
            revert Errors.Staking__NotFlexiTypeBand();
        }
        _;
    }

    modifier mValidMonth(StakingTypes stakingType, uint8 month) {
        // Checks: month must be undefined (0) for flexible staking
        if (StakingTypes.FLEXI == stakingType && month != 0) {
            revert Errors.Staking__InvalidMonth(month);
        }

        // Checks: month must be defined (1-24) for fixed staking
        if (
            StakingTypes.FIX == stakingType &&
            (month == 0 || month > s_sharesInMonth.length)
        ) {
            revert Errors.Staking__InvalidMonth(month);
        }

        _;
    }

    modifier mBandFromVestedTokens(uint256 bandId, bool shouldBeVested) {
        bool areTokensVested = s_bands[bandId].areTokensVested;
        if (areTokensVested != shouldBeVested) {
            revert Errors.Staking__BandFromVestedTokens(areTokensVested);
        }
        _;
    }

    modifier mPoolExists(uint16 poolId) {
        if (poolId == 0 || poolId > s_totalPools) {
            revert Errors.Staking__InvalidPoolId(poolId);
        }
        _;
    }

    modifier mTokenExists(IERC20 token) {
        if (token != s_usdtToken && token != s_usdcToken) {
            revert Errors.Staking__NonExistantToken();
        }
        _;
    }

    modifier mUpgradesEnabled() {
        if (!s_bandUpgradesEnabled) {
            revert Errors.Staking__UpgradesDisabled();
        }
        _;
    }

    modifier mDistributionNotInProgress() {
        if (s_distributionInProgress) {
            revert Errors.Staking__DistributionInProgress();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Initializes the contract with the required data
     * @param   usdtToken  USDT token
     * @param   usdcToken  USDC token
     * @param   wowToken  WOW token
     * @param   vesting  address of the vesting contract (not contract as we don't call any functions from it)
     * @param   gelato  address of the gelato executor which will call the distributeRewards and triggerSharesSync
     * @param   totalPools  total amount of pools used for staking
     * @param   totalBandLevels  total amount of bands levels used for staking
     */
    function initialize(
        IERC20 usdtToken,
        IERC20 usdcToken,
        IERC20 wowToken,
        address vesting,
        address gelato,
        uint16 totalPools,
        uint16 totalBandLevels
    )
        external
        initializer
        mAmountNotZero(totalPools)
        mAmountNotZero(totalBandLevels)
    {
        /// @dev no validation for vesting and gelato is needed,
        /// @dev because if it is zero, the contract will limit some functionality

        // Checks: Address cannot be zero (not using modifers to avoid stack too deep error)
        if (
            address(usdtToken) == address(0) ||
            address(usdcToken) == address(0) ||
            address(wowToken) == address(0)
        ) {
            revert Errors.Staking__ZeroAddress();
        }

        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Effects: set the roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GELATO_EXECUTOR_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(VESTING_ROLE, vesting);
        _grantRole(GELATO_EXECUTOR_ROLE, gelato);

        // Effects: set the storage
        s_usdtToken = usdtToken;
        s_usdcToken = usdcToken;
        s_wowToken = wowToken;
        s_totalPools = totalPools;
        s_totalBandLevels = totalBandLevels;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS FOR DEFAULT ADMIN
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Set data for a pool which will be used for rewards distribution
     * @notice There can be only one pool with the same id
     * @notice When called for the first time, the pool will be created
     * @notice When called for the second time, the pool data will be overwritten
     * @param poolId Id of the pool (1-9)
     * @param distributionPercentage Percentage of the total rewards to be distributed to this pool
     */
    function setPool(
        uint16 poolId,
        uint48 distributionPercentage
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mPoolExists(poolId) {
        // Checks: distribution percentage should not exceed 100%
        if (distributionPercentage > PERCENTAGE_PRECISION) {
            revert Errors.Staking__InvalidDistributionPercentage(
                distributionPercentage
            );
        }
        // Effects: set the storage
        s_poolData[poolId].distributionPercentage = distributionPercentage;

        // Effects: emit event
        emit PoolSet(poolId, distributionPercentage);
    }

    /**
     * @notice  Sets data of the selected band
     * @param   bandLevel  band level number
     * @param   price  band purchase price
     * @param   accessiblePools  list of pools that become
     *          accessible after band purchase
     */
    function setBandLevel(
        uint16 bandLevel,
        uint256 price,
        uint16[] calldata accessiblePools
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mBandLevelExists(bandLevel)
        mAmountNotZero(price)
    {
        // Checks: amount must be in pool bounds
        if (accessiblePools.length > s_totalPools) {
            revert Errors.Staking__MaximumLevelExceeded();
        }

        // Effects: set band storage
        s_bandLevelData[bandLevel] = BandLevel({
            price: price,
            accessiblePools: accessiblePools
        });

        // Effects: emit event
        emit BandLevelSet(bandLevel, price, accessiblePools);
    }

    /**
     * @notice  Sets the total amount of shares that user is going to have
     *          at the end of each month of staking. Used for FLEXI staking
     * @param   totalSharesInMonth  array of shares for each month
     */
    function setSharesInMonth(
        uint48[] calldata totalSharesInMonth
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: set the shares array
        s_sharesInMonth = totalSharesInMonth;

        // Effects: emit event
        emit SharesInMonthSet(totalSharesInMonth);
    }

    /**
     * @notice  Sets the USDC token which is used for rewards distribution
     * @param   token  USDC token
     */
    function setUsdtToken(
        IERC20 token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(address(token)) {
        // Effects: set the token
        s_usdtToken = token;

        // Effects: emit event
        emit UsdtTokenSet(token);
    }

    /**
     * @notice  Sets the USDC token which is used for rewards distribution
     * @param   token  USDC token
     */
    function setUsdcToken(
        IERC20 token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(address(token)) {
        // Effects: set the token
        s_usdcToken = token;

        // Effects: emit event
        emit UsdcTokenSet(token);
    }

    /**
     * @notice  Sets the WOW token which is used for staking by users
     * @param   token  WOW token
     */
    function setWowToken(
        IERC20 token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(address(token)) {
        // Effects: set the token
        s_wowToken = token;

        // Effects: emit event
        emit WowTokenSet(token);
    }

    /**
     * @notice  Sets new total amount of bands used for staking
     * @param   newTotalBandsAmount  total amount of bands used for staking
     */
    function setTotalBandLevelsAmount(
        uint16 newTotalBandsAmount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(newTotalBandsAmount)
    {
        // Effects: set the total bands amount
        s_totalBandLevels = newTotalBandsAmount;

        // Effects: emit event
        emit TotalBandLevelsAmountSet(newTotalBandsAmount);
    }

    /**
     * @notice  Sets new total amount of pools used for staking
     * @param   newTotalPoolAmount  total amount of pools used for staking
     */
    function setTotalPoolAmount(
        uint16 newTotalPoolAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(newTotalPoolAmount) {
        // Effects: set the total pools amount
        s_totalPools = newTotalPoolAmount;

        // Effects: emit event
        emit TotalPoolAmountSet(newTotalPoolAmount);
    }

    /**
     * @notice  Sets new trigger status for upgrades/downgrades
     * @param   enabled  true or false value for upgrades enabling
     */
    function setBandUpgradesEnabled(
        bool enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: set upgrades trigger
        s_bandUpgradesEnabled = enabled;

        // Effects: emit event
        emit BandUpgradeStatusSet(enabled);
    }

    /**
     * @notice  Sets the status of the rewards distribution
     * @param   inProgress  true if distribution is in progress
     *                      false if distribution not started or completed
     */
    function setDistributionInProgress(
        bool inProgress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: set distribution in progress
        s_distributionInProgress = inProgress;

        // Effects: emit event
        emit DistributionStatusSet(inProgress);
    }

    /**
     * @notice  Withdraw the given amount of tokens from the contract
     * @notice  We trust the admin to withdraw the correct amount of tokens
     * @notice  Admin should be careful when calling this function not to
     * @notice  withdraw tokens that are still in use by the contract
     * @param   token Token to withdraw
     * @param   amount Amount to withdraw
     */
    function withdrawTokens(
        IERC20 token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(amount) {
        uint256 balance = token.balanceOf(address(this));

        // Checks: the contract must have enough balance to withdraw
        if (balance < amount) {
            revert Errors.Staking__InsufficientContractBalance(balance, amount);
        }

        // Interaction: transfer the tokens to the sender
        token.safeTransfer(msg.sender, amount);

        emit TokensWithdrawn(token, msg.sender, amount);
    }

    /**
     * @notice  Creates a new distribution of the given amount of tokens
     * @notice  Gelato backend will will monitor this function and call web3 function
     * @notice  to calculate the amount of rewards for each staker and distribute them
     * @notice  by calling distributeRewards function at the end
     * @notice  It might look like this function is missing the actual distribution logic
     * @notice  but this function is only indication for Gelato backend to calculate the rewards
     * @notice  All logic is done on the server side
     * @param   token  USDT/USDC token
     * @param   amount  amount of tokens to distribute
     */
    function createDistribution(
        IERC20 token,
        uint256 amount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mTokenExists(token)
        mAmountNotZero(amount)
        mDistributionNotInProgress
    {
        // Only indication for Gelato backend to calculate the rewards
        // We only need to transfer funds and emit an event here

        // Effects: set distribution in progress
        s_distributionInProgress = true;

        // Interaction: transfer the tokens to the sender
        token.safeTransferFrom(msg.sender, address(this), amount);

        // Effects: emit event
        emit DistributionCreated(
            token,
            amount,
            s_totalPools,
            s_totalBandLevels,
            s_users.length(),
            block.timestamp
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS FOR GELATO EXECUTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Distribute rewards to all stakers
     * @notice  This function is called by the Gelato backend
     * @notice  after the rewards are calculated from the server side
     * @notice  We trust the server side to calculate the rewards correctly
     * @param   token  USDT/USDC token
     * @param   stakers  array of stakers
     * @param   rewards  array of rewards for each staker in the same order
     */
    function distributeRewards(
        IERC20 token,
        address[] memory stakers,
        uint256[] memory rewards
    ) external onlyRole(GELATO_EXECUTOR_ROLE) mTokenExists(token) {
        uint256 stakersLength = stakers.length;
        uint256 rewardsLength = rewards.length;

        // Checks: stakers and rewards arrays must be the same length
        if (stakersLength != rewardsLength) {
            revert Errors.Staking__MismatchedArrayLengths(
                stakersLength,
                rewardsLength
            );
        }

        // Checks: distribution must be in progress
        if (!s_distributionInProgress) {
            revert Errors.Staking__DistributionNotInProgress();
        }

        // Effects: set distribution not in progress
        s_distributionInProgress = false;

        // Loop through all stakers and distribute rewards
        for (uint256 i; i < stakersLength; i++) {
            // Effects: add rewards to the user
            s_stakerRewards[_getStakerAndTokenHash(stakers[i], token)]
                .unclaimedAmount += rewards[i];
        }

        // Effects: emit event
        emit RewardsDistributed(token);
    }

    /**
     * @notice  Trigger the shares sync event
     * @notice  This function is called by the Gelato backend
     * @notice  to trigger the shares sync event in subgraph
     * @notice  We trust the server side to call this function at the right time
     */
    function triggerSharesSync() external onlyRole(GELATO_EXECUTOR_ROLE) {
        // Effects: emit event
        emit SharesSyncTriggered();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS FOR USERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Stake and lock tokens to earn rewards
     * @param   stakingType  enumerable type for flexi or fixed staking
     * @param   bandLevel  band level number
     * @param   month  fixed staking period in months (if not fixed, set to 0)
     */
    function stake(
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month
    )
        external
        mBandLevelExists(bandLevel)
        mValidMonth(stakingType, month)
        mDistributionNotInProgress
    {
        // Effects: Create a new band and add it to the user
        uint256 bandId = _stakeBand(
            msg.sender,
            stakingType,
            bandLevel,
            month,
            false
        );

        uint256 price = s_bandLevelData[bandLevel].price;

        // Interaction: transfer transaction funds to contract
        s_wowToken.safeTransferFrom(msg.sender, address(this), price);

        // Effects: emit event
        emit Staked(msg.sender, bandLevel, bandId, month, stakingType, false);
    }

    /**
     * @notice  Unstake tokens at any time and claim earned rewards
     * @param   bandId  Id of the band (0-max uint)
     */
    function unstake(
        uint256 bandId
    )
        external
        mBandOwner(msg.sender, bandId)
        mBandFromVestedTokens(bandId, false)
        mDistributionNotInProgress
    {
        StakerBand storage band = s_bands[bandId];

        // Checks: if band is FIX, the fixed months period should be passed
        _validateFixedPeriodPassed(band);

        // Get amount before deleting band data
        uint256 stakedAmount = s_bandLevelData[band.bandLevel].price;

        // Effects: delete band data
        _unstakeBand(msg.sender, bandId);

        // Interaction: transfer earned rewards to staker for both tokens
        _claimAllRewards(msg.sender);

        // Interraction: transfer staked tokens
        s_wowToken.safeTransfer(msg.sender, stakedAmount);

        // Effects: emit event
        emit Unstaked(msg.sender, bandId, false);
    }

    /**
     * @notice  Stakes vesting contract tokens to ear rewards
     * @param   user  address of user staking vested tokens
     * @param   stakingType  enumerable type for flexi or fixed staking
     * @param   bandLevel  band level number
     * @param   month  fixed staking period in months (if not fixed, set to 0)
     */
    function stakeVested(
        address user,
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month
    )
        external
        onlyRole(VESTING_ROLE)
        mAddressNotZero(user)
        mBandLevelExists(bandLevel)
        mValidMonth(stakingType, month)
        mDistributionNotInProgress
        returns (uint256 bandId)
    {
        // Checks: only flexi type is allowed for vesting
        if (StakingTypes.FLEXI != stakingType) {
            revert Errors.Staking__OnlyFlexiTypeAllowed();
        }

        // Effects: Create a new band and add it to the user
        bandId = _stakeBand(user, stakingType, bandLevel, month, true);

        // Effects: emit event
        emit Staked(user, bandLevel, bandId, month, stakingType, true);
    }

    /**
     * @notice  Unstake tokens at any time and claim earned rewards
     * @notice  This function can only be called by the vesting contract
     * @param   user  address of user staking vested tokens
     * @param   bandId  Id of the band (0-max uint)
     */
    function unstakeVested(
        address user,
        uint256 bandId
    )
        external
        onlyRole(VESTING_ROLE)
        mBandOwner(user, bandId)
        mBandFromVestedTokens(bandId, true)
        mDistributionNotInProgress
    {
        StakerBand storage band = s_bands[bandId];

        // Checks: if band is FIX, the fixed months period should be passed
        _validateFixedPeriodPassed(band);

        // Effects: delete band data
        _unstakeBand(user, bandId);

        // Interaction: transfer earned rewards to staker for both tokens
        _claimAllRewards(user);

        // Effects: emit event
        emit Unstaked(user, bandId, true);
    }

    /**
     * @notice  Delete all user band data if beneficiary removed from vesting
     * @notice  All unlclaimed USDT/USDC rewards will be transferred to the rewards collector
     * @param   user  staker address
     */
    function deleteVestingUser(
        address user
    ) external onlyRole(VESTING_ROLE) mAddressNotZero(user) {
        uint256[] memory bandIds = s_stakerBands[user];
        uint256 bandsAmount = bandIds.length;

        // Loop through all bands that user owns and delete data
        for (uint256 bandIndex; bandIndex < bandsAmount; bandIndex++) {
            // Effects: delete all band data
            delete s_bands[bandIds[bandIndex]];
        }

        // Effects: delete user from the staker bands map
        delete s_stakerBands[user];

        // Effects: delete users all claimed and unclaimed rewards for USDT
        delete s_stakerRewards[_getStakerAndTokenHash(user, s_usdtToken)];

        // Effects: delete users all claimed and unclaimed rewards for USDC
        delete s_stakerRewards[_getStakerAndTokenHash(user, s_usdcToken)];

        // Effects: delete user from the map
        s_users.remove(user);

        // Effects: emit event
        emit VestingUserDeleted(user);
    }

    /**
     * @notice  Upgradea any owned band to a new level
     * @param   bandId  BandLevel Id being upgraded
     * @param   newBandLevel  New band level being upgraded to
     */
    function upgradeBand(
        uint256 bandId,
        uint16 newBandLevel
    )
        external
        mUpgradesEnabled
        mBandOwner(msg.sender, bandId)
        mBandLevelExists(newBandLevel)
        mOnlyFlexiType(bandId)
        mBandFromVestedTokens(bandId, false)
        mDistributionNotInProgress
    {
        uint16 oldBandLevel = s_bands[bandId].bandLevel;

        // Checks: new band level must be higher than the old one
        if (newBandLevel <= oldBandLevel) {
            revert Errors.Staking__InvalidBandLevel(newBandLevel);
        }

        uint256 oldPrice = s_bandLevelData[oldBandLevel].price;
        uint256 newPrice = s_bandLevelData[newBandLevel].price;
        uint256 priceDifference = newPrice - oldPrice;

        // Effects: update band level
        s_bands[bandId].bandLevel = newBandLevel;

        // Interaction: transfer transaction funds to contract
        s_wowToken.safeTransferFrom(msg.sender, address(this), priceDifference);

        // Effects: emit event
        emit BandUpgraded(msg.sender, bandId, oldBandLevel, newBandLevel);
    }

    /**
     * @notice  Downgrade any owned band to a new level
     * @param   bandId  BandLevel Id being downgraded
     * @param   newBandLevel  New band level being downgraded to
     */
    function downgradeBand(
        uint256 bandId,
        uint16 newBandLevel
    )
        external
        mUpgradesEnabled
        mBandOwner(msg.sender, bandId)
        mBandLevelExists(newBandLevel)
        mOnlyFlexiType(bandId)
        mBandFromVestedTokens(bandId, false)
        mDistributionNotInProgress
    {
        uint16 oldBandLevel = s_bands[bandId].bandLevel;

        // Checks: new band level must be higher than the old one
        if (newBandLevel >= oldBandLevel) {
            revert Errors.Staking__InvalidBandLevel(newBandLevel);
        }

        uint256 oldPrice = s_bandLevelData[oldBandLevel].price;
        uint256 newPrice = s_bandLevelData[newBandLevel].price;
        uint256 priceDifference = oldPrice - newPrice;

        // Effects: update band level
        s_bands[bandId].bandLevel = newBandLevel;

        // Interaction: transfer transaction funds to contract
        s_wowToken.safeTransfer(msg.sender, priceDifference);

        // Effects: emit event
        emit BandDowngraded(msg.sender, bandId, oldBandLevel, newBandLevel);
    }

    /**
     * @notice  Claim rewards for all pools and tokens
     * @notice  This function can be called by anyone
     * @param   token  USDT/USDC token
     */
    function claimRewards(
        IERC20 token
    ) external mTokenExists(token) mDistributionNotInProgress {
        _claimRewards(msg.sender, token, true);
    }

    function claimAllRewards() external mDistributionNotInProgress {
        _claimAllRewards(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the USDT token which is used for rewards distribution
     * @return IERC20 USDT token
     */
    function getTokenUSDT() external view returns (IERC20) {
        return s_usdtToken;
    }

    /**
     * @notice Returns the USDC token which is used for rewards distribution
     * @return IERC20 USDC token
     */
    function getTokenUSDC() external view returns (IERC20) {
        return s_usdcToken;
    }

    /**
     * @notice Returns the WOW token which is used staking by users
     * @return IERC20 WOW token
     */
    function getTokenWOW() external view returns (IERC20) {
        return s_wowToken;
    }

    /**
     * @notice Returns the total amount of pools users can stake in
     * @return uint16 Total amount of pools
     */
    function getTotalPools() external view returns (uint16) {
        return s_totalPools;
    }

    /**
     * @notice Returns the total amount of bands users can buy for staking
     * @return uint16 Total amount of bands
     */
    function getTotalBandLevels() external view returns (uint16) {
        return s_totalBandLevels;
    }

    /**
     * @notice  Returns the next consecutive band Id number to be assigned
     * @return  uint256  Next band Id
     */
    function getNextBandId() external view returns (uint256) {
        return s_nextBandId;
    }

    /**
     * @notice  Returns all shares to be accumulated each month
     * @return  uint256[]  Array of all shares appending each month
     */
    function getSharesInMonthArray() external view returns (uint48[] memory) {
        return s_sharesInMonth;
    }

    /**
     * @notice  Returns the amount of shares to be accumulated in the specified month
     * @param   index  Index of the month (months start from 0)
     * @return  shares  Amount of shares to be accumulated in total
     */
    function getSharesInMonth(
        uint256 index
    ) external view returns (uint48 shares) {
        shares = s_sharesInMonth[index];
    }

    /**
     * @notice  Returns pool data such as distribution percentage and token amounts
     * @param   poolId  Pool Id
     * @return  distributionPercentage  Percentage in 10**6 precision
     */
    function getPool(
        uint16 poolId
    ) external view returns (uint48 distributionPercentage) {
        Pool memory pool = s_poolData[poolId];
        distributionPercentage = pool.distributionPercentage;
    }

    /**
     * @notice  Returns band data such as band price, accessible pools and timespan
     * @param   bandLevel  BandLevel level
     * @return  price  BandLevel price in WOW tokens
     * @return  accessiblePools  List of accessible pools after purchase
     */
    function getBandLevel(
        uint16 bandLevel
    ) external view returns (uint256 price, uint16[] memory accessiblePools) {
        BandLevel memory band = s_bandLevelData[bandLevel];
        price = band.price;
        accessiblePools = band.accessiblePools;
    }

    /**
     * @notice  Returns staker data on each band they purchased
     * @param   bandId  BandLevel Id
     * @return  owner  Staker address
     * @return  stakingStartDate  Timestamp of staking start
     * @return  bandLevel  BandLevel level
     * @return  fixedMonths  Fixed staking period in months (if not fixed, set to 0)
     * @return  stakingType  FIx/FLEXI staking type
     * @return  areTokensVested  If band was bought from vested tokens
     */
    function getStakerBand(
        uint256 bandId
    )
        external
        view
        returns (
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            StakingTypes stakingType,
            bool areTokensVested
        )
    {
        StakerBand memory band = s_bands[bandId];
        owner = band.owner;
        stakingStartDate = band.stakingStartDate;
        bandLevel = band.bandLevel;
        fixedMonths = band.fixedMonths;
        stakingType = band.stakingType;
        areTokensVested = band.areTokensVested;
    }

    /**
     * @notice  Returns staker reward data for the specified token
     * @param   staker  Staker address
     * @param   token  USDT/USDC token
     * @return  unclaimedAmount  Amount of unclaimed rewards
     * @return  claimedAmount  Amount of claimed rewards
     */
    function getStakerReward(
        address staker,
        IERC20 token
    ) external view returns (uint256 unclaimedAmount, uint256 claimedAmount) {
        StakerReward memory reward = s_stakerRewards[
            _getStakerAndTokenHash(staker, token)
        ];
        unclaimedAmount = reward.unclaimedAmount;
        claimedAmount = reward.claimedAmount;
    }

    /**
     * @notice  Returns all band Ids the staker bought
     * @param   staker  Staker address
     * @return  bandIds  Array of all staker owned bands
     */
    function getStakerBandIds(
        address staker
    ) external view returns (uint256[] memory bandIds) {
        bandIds = s_stakerBands[staker];
    }

    /**
     * @notice  Get user address in the users map from index in array
     * @param   index  Index in the users array
     * @return  user  User address
     */
    function getUser(uint256 index) external view returns (address user) {
        (user, ) = s_users.at(index);
    }

    /**
     * @notice  Returns the amount of users in the staking contract
     * @return  usersAmount  Amount of users
     */
    function getTotalUsers() external view returns (uint256 usersAmount) {
        usersAmount = s_users.length();
    }

    /**
     * @notice  Returns status of the upgrades and downgrades
     * @return  enabled  True if upgrades/downgrades are enabled
     *                   False if upgrades/downgrades are disabled
     */
    function areBandUpgradesEnabled() external view returns (bool enabled) {
        return s_bandUpgradesEnabled;
    }

    /**
     * @notice  Returns the status of the rewards distribution
     * @return  inProgress  True if distribution is in progress
     *                      False if distribution not started or completed
     */
    function isDistributionInProgress()
        external
        view
        returns (bool inProgress)
    {
        inProgress = s_distributionInProgress;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _claimAllRewards(address staker) internal {
        // If claiming in unstake function, we don't want to revert if there are no rewards
        _claimRewards(staker, s_usdtToken, false);
        _claimRewards(staker, s_usdcToken, false);
    }

    function _claimRewards(
        address staker,
        IERC20 token,
        bool revertIfZeroAmount
    ) internal {
        StakerReward storage stakerRewards = s_stakerRewards[
            _getStakerAndTokenHash(staker, token)
        ];

        uint256 rewardsToClaim = stakerRewards.unclaimedAmount;

        // Checks: user must have rewards to claim
        if (rewardsToClaim == 0 && revertIfZeroAmount) {
            revert Errors.Staking__NoRewardsToClaim();
        }

        if (rewardsToClaim > 0) {
            // Effects: update rewards data
            stakerRewards.unclaimedAmount = 0;
            stakerRewards.claimedAmount += rewardsToClaim;

            // Interaction: transfer the tokens to the sender
            token.safeTransfer(staker, rewardsToClaim);

            // Effects: emit event
            emit RewardsClaimed(staker, token, rewardsToClaim);
        }
    }

    function _stakeBand(
        address user,
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month,
        bool areTokensVested
    ) internal returns (uint256 bandId) {
        // Effects: increment bandId (variable is set before incrementing to start from 0)
        bandId = s_nextBandId++;

        // Effects: set staker band data
        StakerBand storage band = s_bands[bandId];
        band.owner = user;
        band.stakingStartDate = uint32(block.timestamp);
        band.bandLevel = bandLevel;
        band.stakingType = stakingType;

        if (month > 0) {
            // Effects: set fixed months for the band
            band.fixedMonths = month;
        }

        if (areTokensVested) {
            // Effects: set that band is bought from vested tokens
            band.areTokensVested = true;
        }

        // Effects: add bandId to the user
        s_stakerBands[user].push(bandId);

        // If currently added band is the first one for the user
        if (s_stakerBands[user].length == 1) {
            // Effects: add user to the map
            s_users.set(user, 1);
        }
    }

    function _unstakeBand(address user, uint256 bandId) internal {
        // Effects: delete band data
        delete s_bands[bandId];

        // Effects: loop trough bandIds and remove required Id
        uint256[] storage bandIds = s_stakerBands[user];
        uint256 bandsIdsAmount = bandIds.length;
        for (uint256 i; i < bandsIdsAmount; i++) {
            if (bandIds[i] == bandId) {
                bandIds[i] = bandIds[bandsIdsAmount - 1];
                bandIds.pop();
                break;
            }
        }

        // If user had only one band left
        if (bandsIdsAmount == 1) {
            // Effects: remove user from the map
            s_users.remove(user);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR UPGRADER ROLE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        /// @dev This function is empty but uses a modifier to restrict access
    }

    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _validateFixedPeriodPassed(StakerBand storage band) internal view {
        if (band.stakingType == StakingTypes.FIX) {
            uint32 monthsPassed = (uint32(block.timestamp) -
                band.stakingStartDate) / MONTH;

            // Checks: fixed staking can only be unstaked after the fixed period
            if (monthsPassed < band.fixedMonths) {
                revert Errors.Staking__UnlockDateNotReached();
            }
        }
    }

    function _getStakerAndTokenHash(
        address staker,
        IERC20 token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(staker, token));
    }
}