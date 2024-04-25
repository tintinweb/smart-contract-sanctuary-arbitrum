// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
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
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 * ```
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
library EnumerableSetUpgradeable {
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
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
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
            set._indexes[value] = set._values.length;
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
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../interfaces/layerZero/ILayerZeroReceiver.sol";
import "../interfaces/layerZero/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/layerZero/ILayerZeroEndpoint.sol";
import "../library/UtilsLibrary.sol";

/**
 * @title Abstract Layer Zero contract
 * @notice  It is extended by the PortfolioBridgeMain contract for Dexalot specific implementation
 * @dev  defaultLzRemoteChainId is the default destination chain. For PortfolioBridgeSub it is avalanche C-Chain
 * For other blockchains it is Dexalot Subnet
 */

abstract contract LzApp is AccessControlEnumerableUpgradeable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint internal lzEndpoint;
    //chainId ==> Remote contract address concatenated with the local contract address, 40 bytes
    mapping(uint16 => bytes) public lzTrustedRemoteLookup;
    mapping(uint16 => Destination) public remoteParams;

    uint16 internal defaultLzRemoteChainId; // Default remote chain id (LayerZero assigned chain id)

    // storage gap for upgradeability
    uint256[50] private __gap;

    event LzSetTrustedRemoteAddress(
        uint16 destinationLzChainId,
        bytes remoteAddress,
        uint32 chainListOrgChainId,
        uint256 gasForDestinationLzReceive,
        bool userPaysFee
    );

    /**
     * @notice  Sets the Layer Zero Endpoint address
     * @dev     Only admin can set the Layer Zero Endpoint address
     * @param   _endpoint  Address of the Layer Zero Endpoint
     */
    function setLzEndPoint(address _endpoint) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_endpoint != address(0), "LA-LIZA-01");
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    /**
     * @notice  Receive message from Layer Zero
     * @dev     Implemented by the real application
     * @param   _srcChainId  Source chain id
     * @param   _srcAddress  Source contract address
     * @param   _nonce  Nonce received
     * @param   _payload  Payload received
     */
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external virtual override;

    /**
     * @notice  send a LayerZero message to the specified address at a LayerZero endpoint.
     * @param   _dstChainId the destination chain identifier
     * @param   _payload  a custom bytes payload to send to the destination contract
     * @param   _refundAddress  if the source transaction is cheaper than the amount of value passed, refund the
     * additional amount to this address
     * @return  uint256  Message fee
     */
    function lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress
    ) internal virtual returns (uint256) {
        bytes memory trustedRemote = lzTrustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LA-DCNT-01");
        (uint256 nativeFee, bytes memory adapterParams) = lzEstimateFees(_dstChainId, _payload);
        if (_refundAddress != address(this)) {
            require(msg.value >= nativeFee, "LA-IUMF-01");
        }
        // solhint-disable-next-line check-send-result
        lzEndpoint.send{value: nativeFee}(
            _dstChainId, // destination LayerZero chainId
            trustedRemote, // trusted remote
            _payload, // bytes payload
            _refundAddress, // refund address
            address(0x0), // _zroPaymentAddress
            adapterParams
        );
        return nativeFee;
    }

    /**
     * @notice  Estimates message fees
     * @param   _dstChainId  Target chain id
     * @param   _payload  Message payload
     * @return  messageFee  Message fee
     * @return  adapterParams  Adapter parameters
     */
    function lzEstimateFees(
        uint16 _dstChainId,
        bytes memory _payload
    ) internal view returns (uint256 messageFee, bytes memory adapterParams) {
        // Dexalot sets a higher gasForDestinationLzReceive value for LayerZero in PortfolioBridgeMain extending LzApp
        // LayerZero needs v1 in adapterParams to specify a higher gas for the destination to receive transaction
        // For more details refer to LayerZero PingPong example at
        // https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/examples/PingPong.sol
        uint16 version = 1;
        adapterParams = abi.encodePacked(version, remoteParams[_dstChainId].gasForDestination);
        (messageFee, ) = lzEndpoint.estimateFees(_dstChainId, address(this), _payload, false, adapterParams);
    }

    //---------------------------UserApplication config----------------------------------------

    /**
     * @dev     parameter for address is ignored as it is defaulted to the address of this contract
     * @param   _version  Version of the config
     * @param   _chainId  Chain id
     * @param   _configType  Config type
     * @return  bytes  Config details
     */
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint256 _configType
    ) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    /**
     * @notice  Sets generic config for LayerZero user Application
     * @param   _version  Version of the config
     * @param   _chainId  Chain id
     * @param   _configType  Config type
     * @param   _config  Config to set
     */
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    /**
     * @notice  Sets send message version
     * @dev     Only admin can set the send message version
     * @param   _version  Version to set
     */
    function setSendVersion(uint16 _version) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        lzEndpoint.setSendVersion(_version);
    }

    /**
     * @notice  Sets receive message version
     * @dev     Only admin can set the receive message version
     * @param   _version  Version to set
     */
    function setReceiveVersion(uint16 _version) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        lzEndpoint.setReceiveVersion(_version);
    }

    /**
     * @notice  Force resumes the stuck bridge by destroying the message blocking it.
     * @dev     This action is destructive! Use this as the last resort!
     * Use this function directly only when portfolioBridge.lzDestroyAndRecoverFunds() fails
     * If this function is used directly, destroyed message's funds are processed in the originating chain
     * properly but they will not be processed in the target chain at all. The funds in storedPayload destroyed
     * have to be manually sent to the originator of the message.
     * For example, if the message is destroyed using this function the end state will be:
     * If sending from mainnet to subnet. Funds deposited/locked in the mainnet but they won't show in the subnet
     * If sending from subnet to mainnet. Funds are withdrawn from the subnet but they won't be deposited into
     * the user's wallet in the mainnet
     * `_srcAddress` is 40 bytes data with the remote contract address concatenated with
     * the local contract address via `abi.encodePacked(sourceAddress, localAddress)`
     * @param   _srcChainId  Source chain id
     * @param   _srcAddress  Remote contract address concatenated with the local contract address
     */
    function forceResumeReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external virtual override(ILayerZeroUserApplicationConfig) onlyRole(DEFAULT_ADMIN_ROLE) {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    /**
     * @notice  Retries the stuck message in the bridge, if any
     * @dev     Only DEFAULT_ADMIN_ROLE can call this function
     * Reverts if there is no storedPayload in the bridge or the supplied payload doesn't match the storedPayload
     * `_srcAddress` is 40 bytes data with the remote contract address concatenated with
     * the local contract address via `abi.encodePacked(sourceAddress, localAddress)`
     * @param   _srcChainId  Source chain id
     * @param   _srcAddress  Remote contract address concatenated with the local contract address
     * @param   _payload  Payload to retry
     */
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lzEndpoint.retryPayload(_srcChainId, _srcAddress, _payload);
    }

    //--------------------------- VIEW FUNCTIONS ----------------------------------------

    /**
     * @return  ILayerZeroEndpoint  Layer Zero Endpoint
     */
    function getLzEndPoint() external view returns (ILayerZeroEndpoint) {
        return lzEndpoint;
    }

    /**
     * @notice  Gets the Trusted Remote Address per given chainId
     * @param   _remoteChainId  Remote chain id
     * @return  bytes  Trusted Source Remote Address
     */
    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = lzTrustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LA-DCNT-01");
        return UtilsLibrary.slice(path, 0, path.length - 20); // the last 20 bytes should be address(this)
    }

    /**
     * @dev     `_srcAddress` is 40 bytes data with the remote contract address concatenated with
     * the local contract address via `abi.encodePacked(sourceAddress, localAddress)`
     * @param   _srcChainId  Source chain id
     * @param   _srcAddress  Remote contract address concatenated with the local contract address
     * @return  bool  True if the bridge has stored payload, means it is stuck
     */
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        return lzEndpoint.hasStoredPayload(_srcChainId, _srcAddress);
    }

    /**
     * @return  bool  True if the bridge has stored payload with its default destination, means it is stuck
     */
    function hasStoredPayload() external view returns (bool) {
        return lzEndpoint.hasStoredPayload(defaultLzRemoteChainId, lzTrustedRemoteLookup[defaultLzRemoteChainId]);
    }

    /**
     * @dev  Get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
     * @param  _srcChainId  the source chain identifier
     * @return  uint64  Inbound nonce
     */
    function getInboundNonce(uint16 _srcChainId) internal view returns (uint64) {
        return lzEndpoint.getInboundNonce(_srcChainId, lzTrustedRemoteLookup[_srcChainId]);
    }

    /**
     * @dev Get the outboundNonce of a lzApp for a destination chain which, consequently, is always an EVM
     * @param _dstChainId The destination chain identifier
     * @return  uint64  Outbound nonce
     */
    function getOutboundNonce(uint16 _dstChainId) internal view returns (uint64) {
        return lzEndpoint.getOutboundNonce(_dstChainId, address(this));
    }

    /**
     * @dev     `_srcAddress` is 40 bytes data with the remote contract address concatenated with
     * the local contract address via `abi.encodePacked(sourceAddress, localAddress)`
     * @param   _srcChainId  Source chain id
     * @param   _srcAddress  Remote contract address concatenated with the local contract address
     * @return  bool  True if the source address is trusted
     */
    function isLZTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = lzTrustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;
import "./IPortfolio.sol";

/**
 * @title Interface of MainnetRFQ
 */

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

interface IMainnetRFQ {
    function processXFerPayload(IPortfolio.XFER calldata _xfer) external;

    function pause() external;

    function unpause() external;

    receive() external payable;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./ITradePairs.sol";
import "./IPortfolioBridge.sol";

/**
 * @title Interface of Portfolio
 */

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

interface IPortfolio {
    function pause() external;

    function unpause() external;

    function pauseDeposit(bool _depositPause) external;

    function removeToken(bytes32 _symbol, uint32 _srcChainId) external;

    function depositNative(address payable _from, IPortfolioBridge.BridgeProvider _bridge) external payable;

    function processXFerPayload(IPortfolio.XFER calldata _xfer) external;

    function getNative() external view returns (bytes32);

    function getChainId() external view returns (uint32);

    function getTokenDetails(bytes32 _symbol) external view returns (TokenDetails memory);

    function getTokenDetailsById(bytes32 _symbolId) external view returns (TokenDetails memory);

    function getTokenList() external view returns (bytes32[] memory);

    function setBridgeParam(bytes32 _symbol, uint256 _fee, uint256 _gasSwapRatio, bool _usedForGasSwap) external;

    event PortfolioUpdated(
        Tx indexed transaction,
        address indexed wallet,
        bytes32 indexed symbol,
        uint256 quantity,
        uint256 feeCharged,
        uint256 total,
        uint256 available,
        address walletOther
    );

    struct BridgeParams {
        uint256 fee; // Bridge Fee
        uint256 gasSwapRatio;
        bool usedForGasSwap; //bool to control the list of tokens that can be used for gas swap. Mostly majors
    }

    struct XFER {
        uint64 nonce;
        IPortfolio.Tx transaction;
        address trader;
        bytes32 symbol;
        uint256 quantity;
        uint256 timestamp;
        bytes28 customdata;
    }

    struct TokenDetails {
        uint8 decimals; //2
        address tokenAddress; //20
        ITradePairs.AuctionMode auctionMode; //2
        uint32 srcChainId; //4
        bytes32 symbol;
        bytes32 symbolId;
        bytes32 sourceChainSymbol;
        bool isVirtual;
    }

    enum Tx {
        WITHDRAW,
        DEPOSIT,
        EXECUTION,
        INCREASEAVAIL,
        DECREASEAVAIL,
        IXFERSENT, // 5  Subnet Sent. I for Internal to Subnet
        IXFERREC, //     Subnet Received. I for Internal to Subnet
        RECOVERFUNDS, // Obsolete as of 2/1/2024 CD
        ADDGAS,
        REMOVEGAS,
        AUTOFILL, // 10
        CCTRADE // Cross Chain Trade.
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./IPortfolio.sol";
import "./ITradePairs.sol";
import "./IMainnetRFQ.sol";

/**
 * @title Interface of PortfolioBridge
 */

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

interface IPortfolioBridge {
    function pause() external;

    function unpause() external;

    function sendXChainMessage(
        uint32 _dstChainListOrgChainId,
        BridgeProvider _bridge,
        IPortfolio.XFER memory _xfer,
        address _userFeePayer
    ) external payable;

    function unpackXFerMessage(bytes calldata _data) external view returns (IPortfolio.XFER memory xfer);

    function enableBridgeProvider(BridgeProvider _bridge, bool _enable) external;

    function isBridgeProviderEnabled(BridgeProvider _bridge) external view returns (bool);

    function getDefaultBridgeProvider() external view returns (BridgeProvider);

    function getDefaultDestinationChain() external view returns (uint32);

    function getPortfolio() external view returns (IPortfolio);

    function getMainnetRfq() external view returns (IMainnetRFQ);

    function getTokenList() external view returns (bytes32[] memory);

    // solhint-disable-next-line func-name-mixedcase
    function VERSION() external returns (bytes32);

    function getBridgeFee(
        BridgeProvider _bridge,
        uint32 _dstChainListOrgChainId,
        bytes32 _symbol,
        uint256 _quantity
    ) external view returns (uint256 bridgeFee);

    enum XChainMsgType {
        XFER
    }
    enum Direction {
        SENT,
        RECEIVED
    }

    event XChainXFerMessage(
        uint8 version,
        BridgeProvider indexed bridge,
        Direction indexed msgDirection,
        uint32 indexed remoteChainId,
        uint256 messageFee,
        IPortfolio.XFER xfer
    );

    // CELER Not used but keeping it to run tests for enabling/disabling bridge providers
    enum BridgeProvider {
        LZ,
        CELER
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

/**
 * @title Interface of TradePairs
 */

import "./IPortfolio.sol";

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

interface ITradePairs {
    /**
     * @notice  Order is the data structure defining an order on Dexalot.
     * @dev     If there are multiple partial fills, the new partial fill `price * quantity`
     * is added to the current value in `totalamount`. Average execution price can be
     * quickly calculated by `totalamount / quantityfilled` regardless of the number of
     * partial fills at different prices \
     * `totalFee` is always in terms of received(incoming) currency. ie. if Buy ALOT/AVAX,
     * fee is paid in ALOT, if Sell ALOT/AVAX, fee is paid in AVAX
     * @param   id  unique order id assigned by the contract (immutable)
     * @param   clientOrderId  client order id given by the sender of the order as a reference (immutable)
     * @param   tradePairId  client order id given by the sender of the order as a reference (immutable)
     * @param   price  price of the order entered by the trader. (0 if market order) (immutable)
     * @param   totalamount  cumulative amount in quote currency: `price* quantityfilled`
     * @param   quantity  order quantity (immutable)
     * @param   quantityfilled  cumulative quantity filled
     * @param   totalfee cumulative fee paid for the order
     * @param   traderaddress`  traders’s wallet (immutable)
     * @param   side  Order side  See #Side (immutable)
     * @param   type1  Order Type1  See #Type1 (immutable)
     * @param   type2  Order Type2  See #Type2 (immutable)
     * @param   status  Order Status  See #Status
     */
    struct Order {
        bytes32 id;
        bytes32 clientOrderId;
        bytes32 tradePairId;
        uint256 price;
        uint256 totalAmount;
        uint256 quantity;
        uint256 quantityFilled;
        uint256 totalFee;
        address traderaddress;
        Side side;
        Type1 type1;
        Type2 type2;
        Status status;
    }

    /**
     * @notice  TradePair is the data structure defining a trading pair on Dexalot.
     * @param   baseSymbol  symbol of the base asset
     * @param   quoteSymbol  symbol of the quote asset
     * @param   buyBookId  buy book id for the trading pair
     * @param   sellBookId  sell book id for the trading pair
     * @param   minTradeAmount  minimum trade amount
     * @param   maxTradeAmount  maximum trade amount
     * @param   auctionPrice  price during an auction
     * @param   auctionMode  current auction mode of the trading pair
     * @param   makerRate fee rate for a maker order for the trading pair
     * @param   takerRate fee rate for taker order for the trading pair
     * @param   baseDecimals  evm decimals of the base asset
     * @param   baseDisplayDecimals  display decimals of the base Asset. Quantity increment
     * @param   quoteDecimals  evm decimals of the quote asset
     * @param   quoteDisplayDecimals  display decimals of the quote Asset. Price increment
     * @param   allowedSlippagePercent allowed slippage percentage for the trading pair
     * @param   addOrderPaused true/false pause state for adding orders on the trading pair
     * @param   pairPaused true/false pause state of the trading pair as a whole
     * @param   postOnly true/false  Post Only orders type2 = PO allowed when true
     */
    struct TradePair {
        bytes32 baseSymbol;
        bytes32 quoteSymbol;
        bytes32 buyBookId;
        bytes32 sellBookId;
        uint256 minTradeAmount;
        uint256 maxTradeAmount;
        uint256 auctionPrice;
        AuctionMode auctionMode;
        uint8 makerRate;
        uint8 takerRate;
        uint8 baseDecimals;
        uint8 baseDisplayDecimals;
        uint8 quoteDecimals;
        uint8 quoteDisplayDecimals;
        uint8 allowedSlippagePercent;
        bool addOrderPaused;
        bool pairPaused;
        bool postOnly;
    }

    function pause() external;

    function unpause() external;

    function pauseTradePair(bytes32 _tradePairId, bool _tradePairPause) external;

    function pauseAddOrder(bytes32 _tradePairId, bool _addOrderPause) external;

    function postOnly(bytes32 _tradePairId, bool _postOnly) external;

    function addTradePair(
        bytes32 _tradePairId,
        IPortfolio.TokenDetails calldata _baseTokenDetails,
        uint8 _baseDisplayDecimals,
        IPortfolio.TokenDetails calldata _quoteTokenDetails,
        uint8 _quoteDisplayDecimals,
        uint256 _minTradeAmount,
        uint256 _maxTradeAmount,
        AuctionMode _mode
    ) external;

    function removeTradePair(bytes32 _tradePairId) external;

    function getTradePairs() external view returns (bytes32[] memory);

    function setMinTradeAmount(bytes32 _tradePairId, uint256 _minTradeAmount) external;

    function setMaxTradeAmount(bytes32 _tradePairId, uint256 _maxTradeAmount) external;

    function addOrderType(bytes32 _tradePairId, Type1 _type) external;

    function removeOrderType(bytes32 _tradePairId, Type1 _type) external;

    function setDisplayDecimals(bytes32 _tradePairId, uint8 _displayDecimals, bool _isBase) external;

    function getTradePair(bytes32 _tradePairId) external view returns (TradePair memory);

    function updateRate(bytes32 _tradePairId, uint8 _rate, RateType _rateType) external;

    function setAllowedSlippagePercent(bytes32 _tradePairId, uint8 _allowedSlippagePercent) external;

    function getNBook(
        bytes32 _tradePairId,
        Side _side,
        uint256 _nPrice,
        uint256 _nOrder,
        uint256 _lastPrice,
        bytes32 _lastOrder
    ) external view returns (uint256[] memory, uint256[] memory, uint256, bytes32);

    function getOrder(bytes32 _orderId) external view returns (Order memory);

    function getOrderByClientOrderId(address _trader, bytes32 _clientOrderId) external view returns (Order memory);

    function addOrder(
        address _trader,
        bytes32 _clientOrderId,
        bytes32 _tradePairId,
        uint256 _price,
        uint256 _quantity,
        Side _side,
        Type1 _type1,
        Type2 _type2
    ) external;

    function cancelOrder(bytes32 _orderId) external;

    function cancelOrderList(bytes32[] memory _orderIds) external;

    function cancelReplaceOrder(bytes32 _orderId, bytes32 _clientOrderId, uint256 _price, uint256 _quantity) external;

    function setAuctionMode(bytes32 _tradePairId, AuctionMode _mode) external;

    function setAuctionPrice(bytes32 _tradePairId, uint256 _price) external;

    function unsolicitedCancel(bytes32 _tradePairId, bool _isBuyBook, uint256 _maxCount) external;

    function getBookId(bytes32 _tradePairId, Side _side) external view returns (bytes32);

    function matchAuctionOrder(bytes32 _takerOrderId, uint256 _maxNbrOfFills) external returns (uint256);

    function getOrderRemainingQuantity(bytes32 _orderId) external view returns (uint256);

    /**
     * @notice  Order Side
     * @dev     0: BUY    – BUY \
     * 1: SELL   – SELL
     */
    enum Side {
        BUY,
        SELL
    }

    /**
     * @notice  Order Type1
     * @dev     Type1 = LIMIT is always allowed. MARKET is enabled pair by pair basis based on liquidity. \
     * 0: MARKET – Order will immediately match with the best Bid/Ask  \
     * 1: LIMIT  – Order that may execute at limit price or better at the order entry. The remaining quantity
     * will be entered in the order book\
     * 2: STOP   –  For future use \
     * 3: STOPLIMIT  –  For future use \
     */
    enum Type1 {
        MARKET,
        LIMIT,
        STOP,
        STOPLIMIT
    }

    /**
     * @notice  Order Status
     * @dev     And order automatically gets the NEW status once it is committed to the blockchain \
     * 0: NEW      – Order is in the orderbook with no trades/executions \
     * 1: REJECTED – Order is rejected. Currently used addLimitOrderList to notify when an order from the list is
     * rejected instead of reverting the entire order list \
     * 2: PARTIAL  – Order filled partially and it remains in the orderbook until FILLED/CANCELED \
     * 3: FILLED   – Order filled fully and removed from the orderbook \
     * 4: CANCELED – Order canceled and removed from the orderbook. PARTIAL before CANCELED is allowed \
     * 5: EXPIRED  – For future use \
     * 6: KILLED   – For future use \
     * 7: CANCEL_REJECT   – Cancel Request Rejected with reason code
     */
    enum Status {
        NEW,
        REJECTED,
        PARTIAL,
        FILLED,
        CANCELED,
        EXPIRED,
        KILLED,
        CANCEL_REJECT
    }
    /**
     * @notice  Rate Type
     * @dev     Maker Rates are typically lower than taker rates \
     * 0: MAKER   – MAKER \
     * 1: TAKER   – TAKER
     */
    enum RateType {
        MAKER,
        TAKER
    }

    /**
     * @notice  Order Type2 to be used in conjunction with when Type1= LIMIT
     * @dev     GTC is the default Type2 \
     * 0: GTC  – Good Till Cancel \
     * 1: FOK  – Fill or Kill. The order will either get an immediate FILLED status or be reverted with *T-FOKF-01*.
     * If reverted, no transaction is committed to the blockchain) \
     * 2: IOC  – Immediate or Cancel. The order will either get a PARTIAL followed by an automatic CANCELED
     * or a FILLED. If PARTIAL, the remaining will not be entered into the orderbook) \
     * 3: PO   – Post Only. The order will either be entered into the orderbook without any fills or be reverted with
     * T-T2PO-01. If reverted, no transaction is committed to the blockchain)
     */
    enum Type2 {
        GTC,
        FOK,
        IOC,
        PO
    }
    /**
     * @notice  Auction Mode of a token
     * @dev     Only the baseToken of a TradePair can be in an auction mode other than OFF
     * When a token is in auction, it can not be withdrawn or transfeered as a Protection againt rogue AMM Pools
     * popping up during auction and distorting the fair auction price. \
     * Auction tokens can only be deposited by the contracts in the addTrustedContracts list. They are currently
     * Avalaunch and Dexalot TokenVesting contracts. These contracts allow the deposits to Dexalot Discovery Auction
     * before TGE
     * ***Transitions ***
     * AUCTION_ADMIN enters the tradepair in PAUSED mode \
     * Changes it to OPEN at pre-announced auction start date/time \
     * Changes it to CLOSING at pre-announced Randomized Auction Closing Sequence date/time
     * ExchangeMain.flipCoin() are called for the randomization \
     * Changes it to MATCHING when the flipCoin condition is satisfied. And proceeds with setting the auction Price
     * and ExchangeSub.matchAuctionOrders until all the crossed orders are matched and removed from the orderbook \
     * Changes it to LIVETRADING if pre-announced token release date/time is NOT reached, so regular trading can start
     * without allowing tokens to be retrieved/transferred  \
     * Changes it to OFF when the pre-announced token release time is reached. Regular trading in effect and tokens
     * can be withdrawn or transferred \
     * 0: OFF  – Used for the Regular Listing of a token. Default \
     * 1: LIVETRADING  – Token is in auction. Live trading in effect but tokens can't be withdrawn or transferred \
     * 2: OPEN  – Ongoing auction. Orders can be entered/cancelled freely. Orders will not match. \
     * 3: CLOSING   – Randomized Auction Closing Sequence before the auction is closed, new orders/cancels allowed
     * but auction can close at any time \
     * 4: PAUSED   – Auction paused, no new orders/cancels allowed \
     * 5: MATCHING   – Auction closed. Final Auction Price is determined and set. No new orders/cancels allowed.
     * orders matching starts \
     * 6: RESTRICTED   – Functionality Reserved for future use \
     */
    enum AuctionMode {
        OFF,
        LIVETRADING,
        OPEN,
        CLOSING,
        PAUSED,
        MATCHING,
        RESTRICTED
    }

    event NewTradePair(
        uint8 version,
        bytes32 pair,
        uint8 basedisplaydecimals,
        uint8 quotedisplaydecimals,
        uint256 mintradeamount,
        uint256 maxtradeamount
    );

    /**
     * @notice  Emits a given order's latest state
     * @dev     If there are multiple partial fills, the new partial fill `price * quantity`
     * is added to the current value in `totalamount`. Average execution price can be
     * quickly calculated by `totalamount / quantityfilled` regardless of the number of
     * partial fills at different prices \
     * `totalfee` is always in terms of received(incoming) currency. ie. if Buy ALOT/AVAX,
     * fee is paid in ALOT, if Sell ALOT/AVAX , fee is paid in AVAX \
     * **Note**: The execution price will always be equal or better than the Order price.
     * @param   version  event version
     * @param   traderaddress  traders’s wallet (immutable)
     * @param   pair  traded pair. ie. ALOT/AVAX in bytes32 (immutable)
     * @param   orderId  unique order id assigned by the contract (immutable)
     * @param   clientOrderId  client order id given by the sender of the order as a reference (immutable)
     * @param   price  price of the order entered by the trader. (0 if market order) (immutable)
     * @param   totalamount  cumulative amount in quote currency: `price * quantityfilled`
     * @param   quantity  order quantity (immutable)
     * @param   side  Order Side  See #Side (immutable)
     * @param   type1  Order Type1  See #Type1 (immutable)
     * @param   type2  Order Type2  See #Type2 (immutable)
     * @param   status Order Status See #Status
     * @param   quantityfilled  cumulative quantity filled
     * @param   totalfee cumulative fee paid for the order
     * @param   code reason when order has REJECT or CANCEL_REJECT status
     */
    event OrderStatusChanged(
        uint8 version,
        address indexed traderaddress,
        bytes32 indexed pair,
        bytes32 orderId,
        bytes32 clientOrderId,
        uint256 price,
        uint256 totalamount,
        uint256 quantity,
        Side side,
        Type1 type1,
        Type2 type2,
        Status status,
        uint256 quantityfilled,
        uint256 totalfee,
        bytes32 code
    );

    /**
     * @notice  Emits the Executed/Trade Event showing
     * @dev     The side of the taker order can be used to identify
     * the fee unit. If takerSide = 1, then the fee is paid by the maker in base
     * currency and the fee paid by the taker in quote currency. If takerSide = 0
     * then the fee is paid by the maker in quote currency and the fee is paid by
     * the taker in base currency
     * @param   version  event version
     * @param   pair  traded pair. ie. ALOT/AVAX in bytes32
     * @param   price  executed price
     * @param   quantity  executed quantity
     * @param   makerOrder  maker Order id
     * @param   takerOrder  taker Order id
     * @param   feeMaker  fee paid by maker
     * @param   feeTaker  fee paid by taker
     * @param   takerSide  Side of the taker order. 0 - BUY, 1- SELL
     * @param   execId  unique trade id (execution id) assigned by the contract
     * @param   addressMaker  maker traderaddress
     * @param   addressTaker  taker traderaddress
     */
    event Executed(
        uint8 version,
        bytes32 indexed pair,
        uint256 price,
        uint256 quantity,
        bytes32 makerOrder,
        bytes32 takerOrder,
        uint256 feeMaker,
        uint256 feeTaker,
        Side takerSide,
        uint256 execId,
        address indexed addressMaker,
        address indexed addressTaker
    );
    event ParameterUpdated(uint8 version, bytes32 indexed pair, string param, uint256 oldValue, uint256 newValue);
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.17;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);

    //Added by Orkun to facilitate tests
    function storedPayload(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    view
    returns (
        uint64,
        address,
        bytes calldata
    );
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.17;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.17;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;

    /**
     * @notice  Destination Chain parameters for layerzero
     * @dev     if gasForDestination is set too low the transaction will revert at the destination and will block the bridge
     * retryPayload needs to be called manually.
     * Not part of original LayerZero interface. Added by Cengiz on 2/1/2024
     * @param   lzRemoteChainId  lz Remote chain id
     * @param   chainListOrgChainId  chainid from https://chainlist.org/
     * @param   gasForDestination  default gas to be used in the destination chain. Also used in fee estimation
     */
    struct Destination {
        uint16 lzRemoteChainId;
        uint32 chainListOrgChainId;
        bool userPaysFee;
        uint256 gasForDestination;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/ITradePairs.sol";

/**
 * @title Common utility functions used across Dexalot's smart contracts.
 * @dev This library provides a set of simple, pure functions to be used in other contracts.
 */

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

library UtilsLibrary {
    /**
     * @notice  Checks the validity of price and quantity given the evm and display decimals.
     * @param   _value  price or quantity
     * @param   _decimals  evm decimals
     * @param   _displayDecimals  base or quote display decimals
     * @return  bool  true if ok
     */
    function decimalsOk(uint256 _value, uint8 _decimals, uint8 _displayDecimals) internal pure returns (bool) {
        return (_value - (_value - ((_value % 10 ** _decimals) % 10 ** (_decimals - _displayDecimals)))) == 0;
    }

    /**
     * @notice  Returns the remaining quantity for an Order struct.
     * @param   _quantity  original order quantity
     * @param   _quantityFilled  filled quantity
     * @return  uint256  remaining quantity
     */
    function getRemainingQuantity(uint256 _quantity, uint256 _quantityFilled) internal pure returns (uint256) {
        return _quantity - _quantityFilled;
    }

    /**
     * @notice  Checks if a tradePair is in auction and if matching is not allowed in the orderbook.
     * @param   _mode  Auction Mode
     * @return  bool  true/false
     */
    function matchingAllowed(ITradePairs.AuctionMode _mode) internal pure returns (bool) {
        return _mode == ITradePairs.AuctionMode.OFF || _mode == ITradePairs.AuctionMode.LIVETRADING;
    }

    /**
     * @notice  Checks if the auction is in a restricted state.
     * @param   _mode  Auction Mode
     * @return  bool  true if Auction is in restricted mode
     */
    function isAuctionRestricted(ITradePairs.AuctionMode _mode) internal pure returns (bool) {
        return _mode == ITradePairs.AuctionMode.RESTRICTED || _mode == ITradePairs.AuctionMode.CLOSING;
    }

    /**
     * @notice  Checks if the order is cancelable.
     * @dev     For an order _quantityFilled < _quantity and its status should be PARTIAL or NEW
                to be eligible for cancelation
     * @param   _quantity  quantity of the order
     * @param   _quantityFilled  quantityFilled of the order
     * @param   _orderStatus  status of the order
     * @return  bool  true if cancelable
     */
    function canCancel(
        uint256 _quantity,
        uint256 _quantityFilled,
        ITradePairs.Status _orderStatus
    ) internal pure returns (bool) {
        return (_quantityFilled < _quantity &&
            (_orderStatus == ITradePairs.Status.PARTIAL || _orderStatus == ITradePairs.Status.NEW));
    }

    /**
     * @notice  Round down a unit256 value.  Used for the fees to avoid dust.
     * @dev     example: a = 1245, m: 2 ==> 1200
     * @param   _a  number to round down
     * @param   _m  number of digits from the right to round down
     * @return  uint256  .
     */
    function floor(uint256 _a, uint256 _m) internal pure returns (uint256) {
        return (_a / 10 ** _m) * 10 ** _m;
    }

    /**
     * @notice  Returns the minimum of the two uint256 arguments
     * @param   _a  A
     * @param   _b  B
     * @return  uint256  Min of a and b
     */
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a <= _b ? _a : _b);
    }

    /**
     * @notice  Converts a bytes32 value to a string
     * @param   _bytes32  bytes32 data to be converted to string
     * @return  string  converted string representation
     */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            ++i;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; ++i) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /**
     * @notice  Converts a string to a bytes32 value
     * @param   _string  a sting to be converted to bytes32
     * @return  result  converted bytes32 representation
     */
    function stringToBytes32(string memory _string) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_string);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(add(_string, 32))
        }
    }

    /**
     * @notice  Returns the symbolId that consists of symbol+chainid
     * @param   _symbol  token symbol of an asset
     * @param   _srcChainId  chain id where the asset exists
     * @return  id  the resulting symbolId
     */
    function getIdForToken(bytes32 _symbol, uint32 _srcChainId) internal pure returns (bytes32 id) {
        id = stringToBytes32(string.concat(bytes32ToString(_symbol), Strings.toString(_srcChainId)));
    }

    // get quote amount
    /**
     * @notice  Returns the quote amount for a given price and quantity
     * @param   _baseDecimals  id of the trading pair
     * @param   _price  price
     * @param   _quantity  quantity
     * @return  quoteAmount quote amount
     */
    function getQuoteAmount(
        uint8 _baseDecimals,
        uint256 _price,
        uint256 _quantity
    ) internal pure returns (uint256 quoteAmount) {
        quoteAmount = (_price * _quantity) / 10 ** _baseDecimals;
    }

    /**
     * @notice  Copied from Layer0 Libs
     * @param   _bytes  Bytes to slice
     * @param   _start  Start
     * @param   _length Length
     * @return  bytes   Bytes returned
     */
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        // solhint-disable-next-line reason-string
        require(_bytes.length + 31 >= _length, "slice_overflow");
        // solhint-disable-next-line reason-string
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/IPortfolio.sol";
import "./interfaces/IPortfolioBridge.sol";
import "./interfaces/IMainnetRFQ.sol";
import "./bridgeApps/LzApp.sol";

/**
 * @title PortfolioBridgeMain. Bridge aggregator and message relayer for mainnet using multiple different bridges
 * @notice The default bridge provider is LayerZero and it can't be disabled. Additional bridge providers
 * will be added as needed. This contract encapsulates all bridge provider implementations that Portfolio
 * doesn't need to know about. \
 * This contract does not hold any users funds. it is responsible for paying the bridge fees in form of
 * the chain’s gas token to 3rd party bridge providers whenever a new cross chain message is sent out by
 * the user. Hence the project deposit gas tokens to this contract. And the project can withdraw
 * the gas tokens from this contract whenever it finds it necessary.
 * @dev PortfolioBridgeSub & PortfolioSub are Dexalot Subnet contracts and they can't be deployed anywhere else.
 * Contracts with *Main* in their name can be deployed to any evm compatible blockchain.
 * Here are the potential flows:
 * DEPOSITS: \
 * PortfolioMain(Avax) => PortfolioBridgeMain(Avax) => BridgeProviderA/B/n => PortfolioBridgeSub => PortfolioSub \
 * PortfolioMain(Arb) => PortfolioBridgeMain(Arb) => BridgeProviderA/B/n => PortfolioBridgeSub => PortfolioSub \
 * PortfolioMain(Gun) => PortfolioBridgeMain(Gun) => BridgeProviderA/B/n => PortfolioBridgeSub => PortfolioSub \
 * WITHDRAWALS (reverse flows): \
 * PortfolioSub => PortfolioBridgeSub => BridgeProviderA/B/n => PortfolioBridgeMain(Avax) => PortfolioMain(Avax) \
 * PortfolioSub => PortfolioBridgeSub => BridgeProviderA/B/n => PortfolioBridgeMain(Arb) => PortfolioMain(Arb) \
 * PortfolioSub => PortfolioBridgeSub => BridgeProviderA/B/n => PortfolioBridgeMain(Gun) => PortfolioMain(Gun) \
 *
 * In addition, to be able to support cross chain trades for subnets like Gunzilla that only has their gas token
 * and no ERC20 available, we introduced a new flow where you provide the counter token in an L1 and receive your GUN
 * in Gunzilla network. Similarly you can sell your GUN in Gunzilla network and receive your counter token in any L1.
 * When Buying GUN from Avalanche with counter token USDC, USDC is kept in MainnetRFQ(Avax) and GUN is deposited
 * to the buyer's wallet via MainnetRFQ(Gun). The flow is : \
 * MainnetRFQ(Avax) => PortfolioBridgeMain(Avax) => BridgeProviderA/B/n => PortfolioBridgeMain(Gun) => MainnetRFQ(Gun) \
 * When Selling GUN from Gunzilla with counter token USDC. GUN is kept in MainnetRFQ(Gun) and USDC is deposited
 * to the buyer's wallet via MainnetRFQ(Avax) The flow is : \
 * MainnetRFQ(Gun) => PortfolioBridgeMain(Gun) => BridgeProviderA/B/n => PortfolioBridgeMain(Avax) => MainnetRFQ(Avax) \
 * The same flow can be replicated with any other L1 like Arb as well. \
 * PortfolioBridgeMain always sends the ERC20 Symbol from its own network and expects the same back
 * i.e USDt sent & received in Avalanche Mainnet whereas USDT is sent & received in Arbitrum.
 * Use multiple inheritance to add additional bridge implementations in the future. Currently LzApp only.
 */

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

contract PortfolioBridgeMain is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPortfolioBridge,
    LzApp
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    IPortfolio internal portfolio;
    IMainnetRFQ internal mainnetRfq;
    mapping(BridgeProvider => bool) public bridgeEnabled;
    mapping(uint32 => uint16) internal lzDestinationMap; // chainListOrgChainId ==> lzChainId

    BridgeProvider internal defaultBridgeProvider; //Layer0
    uint8 private constant XCHAIN_XFER_MESSAGE_VERSION = 2;

    // Controls actions that can be executed on the contract. PortfolioM or MainnetRFQ are the current users.
    bytes32 public constant BRIDGE_USER_ROLE = keccak256("BRIDGE_USER_ROLE");
    // Controls all bridge implementations access. Currently only LZ
    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");
    // 128 bytes payload used for XFER Messages
    bytes private constant DEFAULT_PAYLOAD =
        "0x90f79bf6eb2c4f870365e785982e1f101e93b906000000000000000100000000414c4f543433313133000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029a2241af62c00000000000000000000000000000000000000000000000000000000000065c5098c";
    // storage gap for upgradeability
    uint256[50] __gap;
    event RoleUpdated(string indexed name, string actionName, bytes32 updatedRole, address updatedAddress);
    event DefaultChainIdUpdated(BridgeProvider bridge, uint32 destinationLzChainId);
    event GasForDestinationLzReceiveUpdated(
        BridgeProvider bridge,
        uint32 destinationChainId,
        uint256 gasForDestination
    );
    event UserPaysFeeForDestinationUpdated(BridgeProvider bridge, uint32 destinationChainId, bool userPaysFee);

    // solhint-disable-next-line func-name-mixedcase
    function VERSION() public pure virtual override returns (bytes32) {
        return bytes32("3.2.0");
    }

    /**
     * @notice  Initializer for upgradeable contract.
     * @dev     Grant admin, pauser and msg_sender role to the sender. Set gas for lz. Set endpoint and enable bridge
     * @param   _endpoint  Endpoint of the LZ bridge
     */
    function initialize(address _endpoint) external initializer {
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        lzEndpoint = ILayerZeroEndpoint(_endpoint);
        defaultBridgeProvider = BridgeProvider.LZ;
        bridgeEnabled[BridgeProvider.LZ] = true;
    }

    /**
     * @notice  Pauses bridge operations
     * @dev     Only pauser can pause
     */
    function pause() external onlyRole(BRIDGE_USER_ROLE) {
        _pause();
    }

    /**
     * @notice  Unpauses bridge operations
     * @dev     Only pauser can unpause
     */
    function unpause() external onlyRole(BRIDGE_USER_ROLE) {
        _unpause();
    }

    /**
     * @notice  Enables/disables given bridge. Default bridge's state can't be modified
     * @dev     Only admin can enable/disable bridge
     * @param   _bridge  Bridge to enable/disable
     * @param   _enable  True to enable, false to disable
     */
    function enableBridgeProvider(BridgeProvider _bridge, bool _enable) external override onlyRole(BRIDGE_USER_ROLE) {
        require(_bridge != defaultBridgeProvider, "PB-DBCD-01");
        bridgeEnabled[_bridge] = _enable;
    }

    /**
     * @param   _bridge  Bridge to check
     * @return  bool  True if bridge is enabled, false otherwise
     */
    function isBridgeProviderEnabled(BridgeProvider _bridge) external view override returns (bool) {
        return bridgeEnabled[_bridge];
    }

    /**
     * @notice Returns default bridge Provider
     * @return  BridgeProvider
     */
    function getDefaultBridgeProvider() external view override returns (BridgeProvider) {
        return defaultBridgeProvider;
    }

    /**
     * @notice Sets the default bridge Provider
     * @param   _bridge  Bridge
     */
    function setDefaultBridgeProvider(BridgeProvider _bridge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_bridge != defaultBridgeProvider, "PB-DBCD-01");
        defaultBridgeProvider = _bridge;
    }

    /**
     * @notice Returns Default Lz Destination chain
     * @return chainListOrgChainId Default Destination Chainlist.org Chain Id
     */
    function getDefaultDestinationChain() external view returns (uint32 chainListOrgChainId) {
        if (defaultBridgeProvider == BridgeProvider.LZ) {
            chainListOrgChainId = remoteParams[defaultLzRemoteChainId].chainListOrgChainId;
        }
    }

    /**
     * @notice  Sets trusted remote address for the cross-chain communication. It also sets the defaultLzDestination
     * if it is not setup yet.
     * @dev     Allow DEFAULT_ADMIN to set it multiple times.
     * @param   _bridge  Bridge
     * @param   _dstChainIdBridgeAssigned  Remote chain id
     * @param   _remoteAddress  Remote contract address
     * @param   _chainListOrgChainId  Remote Chainlist.org chainid
     * @param   _gasForDestination  max gas that can be used at the destination chain after message delivery
     */
    function setTrustedRemoteAddress(
        BridgeProvider _bridge,
        uint32 _dstChainIdBridgeAssigned,
        bytes calldata _remoteAddress,
        uint32 _chainListOrgChainId,
        uint256 _gasForDestination,
        bool _userPaysFee
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_bridge == BridgeProvider.LZ) {
            uint16 _dstChainId = uint16(_dstChainIdBridgeAssigned);
            lzTrustedRemoteLookup[_dstChainId] = abi.encodePacked(_remoteAddress, address(this));
            lzDestinationMap[_chainListOrgChainId] = _dstChainId;
            Destination storage destination = remoteParams[_dstChainId];
            destination.lzRemoteChainId = _dstChainId;
            destination.chainListOrgChainId = _chainListOrgChainId;
            destination.gasForDestination = _gasForDestination;
            destination.userPaysFee = _userPaysFee;
            if (defaultLzRemoteChainId == 0) {
                defaultLzRemoteChainId = _dstChainId;
                emit DefaultChainIdUpdated(BridgeProvider.LZ, _dstChainId);
            }
            emit LzSetTrustedRemoteAddress(
                _dstChainId,
                _remoteAddress,
                _chainListOrgChainId,
                _gasForDestination,
                _userPaysFee
            );
        }
    }

    /**
     * @notice  Sets default destination (remote) address for the cross-chain communication
     * @dev     Allow DEFAULT_ADMIN to set it multiple times. For PortfolioBridgeSub it is avalanche C-Chain
     * For other blockchains it is Dexalot Subnet
     * @param   _bridge  Bridge
     * @param   _dstChainIdBridgeAssigned Remote chain id assigned by the Bridge (lz)
     */

    function setDefaultDestinationChain(
        BridgeProvider _bridge,
        uint32 _dstChainIdBridgeAssigned
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_bridge == BridgeProvider.LZ) {
            uint16 _dstChainId = uint16(_dstChainIdBridgeAssigned);
            require(remoteParams[_dstChainId].lzRemoteChainId > 0, "PB-DDCS-01");
            defaultLzRemoteChainId = _dstChainId;
            emit DefaultChainIdUpdated(BridgeProvider.LZ, _dstChainIdBridgeAssigned);
        }
    }

    /**
     * @notice  Set max gas that can be used at the destination chain after message delivery
     * @dev     Only admin can set gas for destination chain
     * @param   _bridge  Bridge
     * @param   _dstChainIdBridgeAssigned Remote chain id assigned by the Bridge (lz)
     * @param   _gas  Gas for destination chain
     */
    function setGasForDestination(
        BridgeProvider _bridge,
        uint32 _dstChainIdBridgeAssigned,
        uint256 _gas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_gas >= 50000, "PB-MING-01");
        if (_bridge == BridgeProvider.LZ) {
            remoteParams[uint16(_dstChainIdBridgeAssigned)].gasForDestination = _gas;
            emit GasForDestinationLzReceiveUpdated(BridgeProvider.LZ, _dstChainIdBridgeAssigned, _gas);
        }
    }

    /**
     * @notice  Set whether a user must pay the bridge fee for message delivery at the destination chain
     * @dev     Only admin can set user pays fee for destination chain
     * @param   _bridge  Bridge
     * @param   _dstChainIdBridgeAssigned Remote chain id assigned by the Bridge (lz)
     * @param   _userPaysFee  True if user must pay the bridge fee, false otherwise
     */
    function setUserPaysFeeForDestination(
        BridgeProvider _bridge,
        uint32 _dstChainIdBridgeAssigned,
        bool _userPaysFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_bridge == BridgeProvider.LZ) {
            remoteParams[uint16(_dstChainIdBridgeAssigned)].userPaysFee = _userPaysFee;
            emit UserPaysFeeForDestinationUpdated(BridgeProvider.LZ, _dstChainIdBridgeAssigned, _userPaysFee);
        }
    }

    /**
     * @notice  Wrapper for revoking roles
     * @dev     Only admin can revoke role. BRIDGE_ADMIN_ROLE will remove additional roles to the parent contract(s)
     * Currently LZ_BRIDGE_ADMIN_ROLE is removed from the LzApp
     * @param   _role  Role to revoke
     * @param   _address  Address to revoke role from
     */
    function revokeRole(
        bytes32 _role,
        address _address
    ) public override(AccessControlUpgradeable, IAccessControlUpgradeable) onlyRole(DEFAULT_ADMIN_ROLE) {
        // We need to have at least one admin in DEFAULT_ADMIN_ROLE
        if (_role == DEFAULT_ADMIN_ROLE) {
            require(getRoleMemberCount(_role) > 1, "PB-ALOA-01");
        } else if (_role == BRIDGE_USER_ROLE) {
            //Can't remove Portfolio from BRIDGE_USER_ROLE. Need to use setPortfolio
            require(getRoleMemberCount(_role) > 1, "PB-ALOA-02");
        }

        super.revokeRole(_role, _address);
        emit RoleUpdated("PORTFOLIOBRIDGE", "REMOVE-ROLE", _role, _address);
    }

    /**
     * @notice  Set portfolio address to grant role
     * @dev     Only admin can set portfolio address.
     * There is a one to one relationship between Portfolio and PortfolioBridgeMain.
     * @param   _portfolio  Portfolio address
     */
    function setPortfolio(address _portfolio) external onlyRole(DEFAULT_ADMIN_ROLE) {
        //Can't have multiple portfolio's using the same bridge
        if (hasRole(BRIDGE_USER_ROLE, address(portfolio))) super.revokeRole(BRIDGE_USER_ROLE, address(portfolio));
        portfolio = IPortfolio(_portfolio);
        grantRole(BRIDGE_USER_ROLE, _portfolio);
        addNativeToken();
    }

    /**
     * @notice  Set MainnetRFQ address and grant role
     * @dev     Only admin can set MainnetRFQ address.
     * There is a one to one relationship between MainnetRFQ and PortfolioBridgeMain.
     * @param   _mainnetRfq  MainnetRFQ address
     */
    function setMainnetRFQ(address payable _mainnetRfq) external onlyRole(DEFAULT_ADMIN_ROLE) {
        //Can't have multiple mainnetRfq's using the same bridge
        if (hasRole(BRIDGE_USER_ROLE, address(mainnetRfq))) super.revokeRole(BRIDGE_USER_ROLE, address(mainnetRfq));
        mainnetRfq = IMainnetRFQ(_mainnetRfq);
        grantRole(BRIDGE_USER_ROLE, _mainnetRfq);
    }

    /**
     * @notice  Sets the bridge provider fee & gasSwapRatio per ALOT for the given token and usedForGasSwap flag
     * @dev     External function to be called by BRIDGE_ADMIN_ROLE
     * @param   _symbol  Symbol of the token
     * @param   _fee  Fee to be set
     * @param   _gasSwapRatio  Amount of token to swap per ALOT. Always set it to equivalent of 1 ALOT.
     * @param   _usedForGasSwap  bool to control the list of tokens that can be used for gas swap. Mostly majors
     */
    function setBridgeParam(
        bytes32 _symbol,
        uint256 _fee,
        uint256 _gasSwapRatio,
        bool _usedForGasSwap
    ) external onlyRole(BRIDGE_ADMIN_ROLE) {
        portfolio.setBridgeParam(_symbol, _fee, _gasSwapRatio, _usedForGasSwap);
    }

    /**
     * @return  IPortfolio  Portfolio contract
     */
    function getPortfolio() external view override returns (IPortfolio) {
        return portfolio;
    }

    /**
     * @return  IMainnetRFQ  MainnetRFQ contract
     */
    function getMainnetRfq() external view override returns (IMainnetRFQ) {
        return mainnetRfq;
    }

    /**
     * @notice  Increments bridge nonce
     * @dev     Only portfolio can call
     * @param   _bridge  Bridge to increment nonce for. Placeholder for multiple bridge implementation
     * @param   _dstChainIdBridgeAssigned the destination chain identifier
     * @return  nonce  New nonce
     */
    function incrementOutNonce(
        BridgeProvider _bridge,
        uint32 _dstChainIdBridgeAssigned
    ) private view returns (uint64 nonce) {
        // Not possible to send any messages from a bridge other than LZ
        // because no other is implemented. Add other bridge nonce functions here.
        if (_bridge == BridgeProvider.LZ) {
            nonce = getOutboundNonce(uint16(_dstChainIdBridgeAssigned)) + 1; // LZ generated nonce
        }
    }

    /**
     * @notice   List of the tokens in the PortfolioBridgeMain
     * @return  bytes32[]  Array of symbols of the tokens
     */
    function getTokenList() external view virtual override returns (bytes32[] memory) {
        return portfolio.getTokenList();
    }

    /**
     * @notice  Validates the symbol from portfolio and transaction type
     * @dev     This function is called both when sending & receiving a message.
     * Deposit/ Withdraw Tx can only be done with non-virtual tokens.
     * You can only send Virtual Tokens to a destination chain using CCTRADE.
     * But at the destination, received token has to be non-virtual token.
     * @param   _symbol  symbol of the token
     * @param   _transaction transaction type
     * @param   _direction direction of the message (SENT-0 || RECEIVED-1)
     */

    function validateSymbol(bytes32 _symbol, IPortfolio.Tx _transaction, Direction _direction) private view {
        //Validate the symbol
        IPortfolio.TokenDetails memory details = portfolio.getTokenDetails(_symbol);
        require(details.symbol != bytes32(0), "PB-ETNS-02");
        //Validate symbol & transaction type;
        if (_transaction == IPortfolio.Tx.CCTRADE) {
            _direction == Direction.SENT
                ? require(details.isVirtual, "PB-CCTR-02")
                : require(!details.isVirtual, "PB-CCTR-03");
        } else if (_transaction == IPortfolio.Tx.WITHDRAW) {
            //Withdraw check only. Deposit check in Portfolio.depositToken
            require(!details.isVirtual, "PB-VTNS-02"); // Virtual tokens can't be withdrawn
        }
    }

    /**
     * @notice  Returns the bridgeFee charged by the bridge for the targetChainId.
     * @dev     The fee is in terms of current chain's gas token.
     * LZ charges based on the payload size and gas px at
     * @param   _bridge  Bridge
     * @param   _dstChainListOrgChainId  destination chain id
     *           _symbol  symbol of the token, not relevant in for this function
     *           _quantity quantity of the token, not relevant in for this function
     * @return  bridgeFee  bridge fee for the destination
     */

    function getBridgeFee(
        BridgeProvider _bridge,
        uint32 _dstChainListOrgChainId,
        bytes32,
        uint256
    ) external view virtual override returns (uint256 bridgeFee) {
        if (_bridge == BridgeProvider.LZ) {
            uint16 dstChainId = lzDestinationMap[_dstChainListOrgChainId];
            (bridgeFee, ) = lzEstimateFees(dstChainId, DEFAULT_PAYLOAD);
        }
    }

    /**
     * @notice  Send message to destination chain via LayerZero
     * @dev     Only called by sendXChainMessageInternal that can be called by Portfolio
     * @param   _dstLzChainId Lz destination chain identifier
     * @param   _payload  Payload to send
     * @param   _userFeePayer  Address of the user who pays the bridge fee, zero address for PortfolioBridge
     * @return  uint256  Message Fee
     */
    function _lzSend(uint16 _dstLzChainId, bytes memory _payload, address _userFeePayer) private returns (uint256) {
        require(address(this).balance > 0, "PB-CBIZ-01");
        address payable _refundAddress = payable(this);
        if (remoteParams[_dstLzChainId].userPaysFee) {
            require(_userFeePayer != address(0), "PB-UFPE-01");
            _refundAddress = payable(_userFeePayer);
        } else if (_userFeePayer != address(0)) {
            // if user fee payer is set but no fee is required then refund the user
            (bool success, ) = _userFeePayer.call{value: msg.value}("");
            require(success, "PB-UFPR-01");
        }
        return
            lzSend(
                _dstLzChainId,
                _payload, // bytes payload
                _refundAddress
            );
    }

    /**
     * @notice  Unpacks XChainMsgType & XFER message from the payload and returns the local symbol and symbolId
     * @dev     Currently only XChainMsgType.XFER possible. For more details on payload packing see packXferMessage
     * @param   _payload  Payload passed from the bridge
     * @return  xfer IPortfolio.XFER  Xfer Message
     */
    function unpackXFerMessage(bytes calldata _payload) external pure returns (IPortfolio.XFER memory xfer) {
        // There is only a single type in the XChainMsgType enum.
        bytes32[4] memory msgData = abi.decode(_payload, (bytes32[4]));
        uint256 slot0 = uint256(msgData[0]);
        // will revert if anything else other than XChainMsgType.XFER is passed
        XChainMsgType(uint16(slot0));
        slot0 >>= 16;
        xfer.transaction = IPortfolio.Tx(uint16(slot0));
        slot0 >>= 16;
        xfer.nonce = uint64(slot0);
        xfer.trader = address(uint160(slot0 >> 64));
        xfer.symbol = msgData[1];
        xfer.quantity = uint256(msgData[2]);
        xfer.timestamp = uint32(bytes4(msgData[3]));
        xfer.customdata = bytes28(uint224(uint256(msgData[3]) >> 32));
    }

    /**
     * @notice  Maps symbol to symbolId and encodes XFER message
     * @dev     It is packed as follows:
     * slot0: trader(20), nonce(8), transaction(2), XChainMsgType(2)
     * slot1: symbol(32)
     * slot2: quantity(32)
     * slot3: customdata(28), timestamp(4)
     * @param   _xfer  XFER message to encode
     * @return  message  Encoded XFER message
     */
    function packXferMessage(IPortfolio.XFER memory _xfer) private pure returns (bytes memory message) {
        bytes32 slot0 = bytes32(
            (uint256(uint160(_xfer.trader)) << 96) |
                (uint256(_xfer.nonce) << 32) |
                (uint256(uint16(_xfer.transaction)) << 16) |
                uint16(XChainMsgType.XFER)
        );
        bytes32 slot1 = bytes32(_xfer.symbol);
        bytes32 slot2 = bytes32(_xfer.quantity);
        bytes32 slot3 = bytes32((uint256(uint224(_xfer.customdata)) << 32) | uint32(_xfer.timestamp));
        message = bytes.concat(slot0, slot1, slot2, slot3);
    }

    /**
     * @notice  Wrapper function to send message to destination chain via bridge
     * @dev     Only BRIDGE_USER_ROLE can call (PortfolioMain or MainnetRFQ)
     * @param   _dstChainListOrgChainId the destination chain identifier
     * @param   _bridge  Bridge to send message to
     * @param   _xfer XFER message to send
     * @param   _userFeePayer  Address of the user who pays the bridge fee
     */
    function sendXChainMessage(
        uint32 _dstChainListOrgChainId,
        BridgeProvider _bridge,
        IPortfolio.XFER memory _xfer,
        address _userFeePayer
    ) external payable virtual override nonReentrant whenNotPaused onlyRole(BRIDGE_USER_ROLE) {
        validateSymbol(_xfer.symbol, _xfer.transaction, Direction.SENT);
        sendXChainMessageInternal(_dstChainListOrgChainId, _bridge, _xfer, _userFeePayer);
    }

    /**
     * @notice  Actual internal function that implements the message sending.
     * @param   _dstChainListOrgChainId the destination chain identifier
     * @param   _bridge  Bridge to send message to
     * @param   _xfer XFER message to send
     * @param   _userFeePayer  Address of the user who pays the bridge fee, zero address for PortfolioBridge
     */
    function sendXChainMessageInternal(
        uint32 _dstChainListOrgChainId,
        BridgeProvider _bridge,
        IPortfolio.XFER memory _xfer,
        address _userFeePayer
    ) internal virtual {
        require(bridgeEnabled[_bridge], "PB-RBNE-01");
        uint16 dstChainId = lzDestinationMap[_dstChainListOrgChainId];
        require(dstChainId != 0, "PB-DDNS-02");
        if (_xfer.nonce == 0) {
            _xfer.nonce = incrementOutNonce(_bridge, dstChainId);
        }
        bytes memory _payload = packXferMessage(_xfer);
        if (_bridge == BridgeProvider.LZ) {
            uint256 messageFee = _lzSend(dstChainId, _payload, _userFeePayer);
            emit XChainXFerMessage(
                XCHAIN_XFER_MESSAGE_VERSION,
                _bridge,
                Direction.SENT,
                _dstChainListOrgChainId,
                messageFee,
                _xfer
            );
        } else {
            // Just in case a bridge other than LZ is enabled accidentally
            revert("PB-RBNE-02");
        }
    }

    /**
     * @notice  Retries the stuck message in the bridge, if any
     * @dev     Only BRIDGE_ADMIN_ROLE can call this function
     * Reverts if there is no storedPayload in the bridge or the supplied payload doesn't match the storedPayload
     * @param   _srcChainId  Source chain id
     * @param   _payload  Payload to retry
     */
    function lzRetryPayload(uint16 _srcChainId, bytes calldata _payload) external onlyRole(BRIDGE_ADMIN_ROLE) {
        lzEndpoint.retryPayload(_srcChainId, lzTrustedRemoteLookup[_srcChainId], _payload);
    }

    /**
     * @notice  This is a destructive, secondary option. Always try lzRetryPayload first.
     * if this function still fails call LzApp.forceResumeReceive directly with DEFAULT_ADMIN_ROLE as the last resort
     * Destroys the message that is blocking the bridge and calls processPayload
     * Effectively completing the message trajectory from originating chain to the target chain.
     * if successful, the funds are processed at the target chain. If not, no funds are recovered and
     * the bridge is still in blocked status and additional messages are queued behind.
     * @dev     Only recover/process message if forceResumeReceive() successfully completes.
     * Only the BRIDGE_ADMIN_ROLE can call this function.
     * If there is no storedpayload (stuck message), this function will revert, _payload parameter will be ignored and
     * will not be processed. If this function keeps failing due to an error condition after the forceResumeReceive call
     * then forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) has to be called directly with
     * DEFAULT_ADMIN_ROLE and the funds will have to be recovered manually
     * @param   _srcChainId  Source chain id
     * @param   _payload  Payload of the message
     */
    function lzDestroyAndRecoverFunds(
        uint16 _srcChainId,
        bytes calldata _payload
    ) external nonReentrant onlyRole(BRIDGE_ADMIN_ROLE) {
        // Destroys the message. This will revert if no message is blocking the bridge
        lzEndpoint.forceResumeReceive(_srcChainId, lzTrustedRemoteLookup[_srcChainId]);
        processPayload(BridgeProvider.LZ, remoteParams[_srcChainId].chainListOrgChainId, _payload);
    }

    /**
     * @notice  Processes message received from source chain via bridge
     * @dev     Unpacks the message and updates the receival timestamp
     * @param   _bridge  Bridge to receive message from
     * @param   _srcChainListOrgChainId  Source chain ID
     * @param   _payload  Payload received
     */
    function processPayloadShared(
        BridgeProvider _bridge,
        uint32 _srcChainListOrgChainId,
        bytes calldata _payload
    ) internal returns (IPortfolio.XFER memory xfer) {
        xfer = this.unpackXFerMessage(_payload);
        xfer.timestamp = block.timestamp; // log receival/process timestamp
        emit XChainXFerMessage(
            XCHAIN_XFER_MESSAGE_VERSION,
            _bridge,
            Direction.RECEIVED,
            _srcChainListOrgChainId,
            0,
            xfer
        );
    }

    /**
     * @notice  Processes message received from source chain via bridge in the host chain.
     * @dev     if bridge is disabled or PAUSED and there are messages in flight, we still need to
                process them when received at the destination.
                Overrides in the subnet
     * @param   _bridge  Bridge to receive message from
     * @param   _srcChainListOrgChainId  Source chain ID
     * @param   _payload  Payload received
     */
    function processPayload(
        BridgeProvider _bridge,
        uint32 _srcChainListOrgChainId,
        bytes calldata _payload
    ) internal virtual {
        IPortfolio.XFER memory xfer = processPayloadShared(_bridge, _srcChainListOrgChainId, _payload);
        // check the validity of the symbol
        validateSymbol(xfer.symbol, xfer.transaction, Direction.RECEIVED);
        xfer.transaction == IPortfolio.Tx.CCTRADE
            ? mainnetRfq.processXFerPayload(xfer)
            : portfolio.processXFerPayload(xfer);
    }

    /**
     * @notice  Receive message from source chain via LayerZero
     * @dev     Only trusted LZ endpoint can call
     * @param   _srcChainId  Source chain ID
     * @param   _srcAddress  Source address
     * @param   _payload  Payload received
     */
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64,
        bytes calldata _payload
    ) external virtual override nonReentrant {
        bytes memory trustedRemote = lzTrustedRemoteLookup[_srcChainId];
        require(_msgSender() == address(lzEndpoint), "PB-IVEC-01");
        require(trustedRemote.length != 0 && keccak256(_srcAddress) == keccak256(trustedRemote), "PB-SINA-01");
        processPayload(BridgeProvider.LZ, remoteParams[_srcChainId].chainListOrgChainId, _payload);
    }

    /**
     * @notice  Refunds the native balance inside contract
     * @dev     Only admin can call
     */
    function refundNative() external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = (msg.sender).call{value: address(this).balance}("");
        require(sent, "PB-FRFD-01");
    }

    /**
     * @notice  private function that handles the addition of native token
     * @dev     gets the native token details from portfolio
     */
    function addNativeToken() internal virtual {}

    // solhint-enable no-empty-blocks

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // we revert transaction if a non-existing function is called
    fallback() external payable {
        revert("PB-NFUN-01");
    }
}