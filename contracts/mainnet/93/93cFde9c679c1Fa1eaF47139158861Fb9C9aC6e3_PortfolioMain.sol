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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

/**
 * @title Interface of BannedAccounts
 */

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

interface IBannedAccounts {
    // extensible enum to hold reasons for ban
    // OFAC  = address appearing in US GOV OFAC SDN list at https://sanctionssearch.ofac.treas.gov
    // ABUSE = address exhibiting abusive use of Dexalot resources
    // TERMS = address violating Dexalot Terms & Conditions
    enum BanReason {
        NOTBANNED,
        OFAC,
        ABUSE,
        TERMS
    }

    function isBanned(address _account) external view returns (bool);

    function getBanReason(address _account) external view returns (BanReason);
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
        CCTRADE, // Cross Chain Trade.
        CONVERTFROM,
        CONVERTTO
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
 * @title Interface of PortfolioMain
 */

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

interface IPortfolioMain {
    function addToken(
        bytes32 _symbol,
        address _tokenaddress,
        uint32 _srcChainId,
        uint8 _decimals,
        uint256 _fee,
        uint256 _gasSwapRatio,
        bool _isVirtual
    ) external;

    function depositTokenFromContract(address _from, bytes32 _symbol, uint256 _quantity) external;

    function addTrustedContract(address _contract, string calldata _organization) external;

    function isTrustedContract(address _contract) external view returns (bool);

    function removeTrustedContract(address _contract) external;

    function getToken(bytes32 _symbol) external view returns (IERC20Upgradeable);
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
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./library/UtilsLibrary.sol";
import "./interfaces/IPortfolio.sol";
import "./interfaces/ITradePairs.sol";
import "./interfaces/IPortfolioBridge.sol";

/**
 * @title Abstract contract to be inherited in PortfolioMain and PortfolioSub
 * @notice Dexalot lives in a dual chain environment. Avalanche Mainnet C-Chain (mainnet) and Avalanche
 * supported Dexalot Subnet (subnet). Dexalot’s contracts don’t bridge any coins or tokens
 * between these two chains, but rather lock them in the PortfolioMain contract in the
 * mainnet and then communicate the users’ holdings to its smart contracts in the subnet for
 * trading purposes. Dexalot is bridge agnostic. You will be able to deposit with one bridge and
 * withdraw with another. Having said that, LayerZero is the sole bridge provider at the start.
 * More bridges can be added in the future as needed.
 * Because of this novel architecture, a subnet wallet can only house ALOT token and nothing
 * else. That's why the subnet wallet is referred to as the “Gas Tank”. All assets will be
 * handled inside the PortfolioSub smart contract in the subnet.
 * PortfolioBridgeMain and PortfolioBridgeSub are bridge aggregators in charge of sending/receiving messages
 * via generic messaging using active bridge transports.
 * @dev This contract contains shared logic for PortfolioMain and PortfolioSub.
 * It is perfectly sufficient for your trading application to interface with only the Dexalot Subnet
 * and use Dexalot frontend to perform deposit/withdraw operations manually for cross chain bridging.
 * If your trading application has a business need to deposit/withdraw more often, then your app
 * will need to integrate with the PortfolioMain contract in the mainnet as well to fully automate
 * your flow.
 * Exchange needs to have DEFAULT_ADMIN_ROLE on this contract.
 */

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

abstract contract Portfolio is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPortfolio
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    // denominator for rate calculations. Changed it to 100K from 10K on May 2024 Release to support volume rebates
    // only used in PortfolioSub
    uint256 public constant TENK = 100000;
    // boolean to control deposit functionality
    bool public allowDeposit;

    // used to swap gas amount & bridge fees  during bridge operation
    mapping(bytes32 => BridgeParams) public bridgeParams; //Key symbol
    //mapping(bytes32 => uint256) public bridgeFee;
    IPortfolioBridge public portfolioBridge;

    // bytes32 variable to hold native token of the chain it is deployed to. ALOT or AVAX currently
    bytes32 public native;
    //chainid of the blockchain it is deployed to
    uint32 internal chainId;

    // bytes32 array of all ERC20 tokens traded on DEXALOT
    EnumerableSetUpgradeable.Bytes32Set internal tokenList;
    // key is symbol
    mapping(bytes32 => TokenDetails) public tokenDetailsMap;
    // key is symbolId (symbol + srcChainId)
    mapping(bytes32 => bytes32) public tokenDetailsMapById;

    bytes32 public constant PORTFOLIO_BRIDGE_ROLE = keccak256("PORTFOLIO_BRIDGE_ROLE");

    event ParameterUpdated(bytes32 indexed pair, string _param, uint256 _oldValue, uint256 _newValue);
    event AddressSet(string indexed name, string actionName, address oldAddress, address newAddress);
    event RoleUpdated(string indexed name, string actionName, bytes32 updatedRole, address updatedAddress);

    /**
     * @notice  initializer function for Upgradeable Portfolio
     * @dev     Grants admin role to msg.sender
     * @param   _native  Native token of the network. AVAX in mainnet, ALOT in subnet.
     */
    function initialize(bytes32 _native, uint32 _chainId) public virtual onlyInitializing {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        // initialize the admins
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // set deployment account to have DEFAULT_ADMIN_ROLE
        allowDeposit = true;
        native = _native;
        chainId = _chainId;
    }

    /**
     * @notice  Sets the portfolio bridge contract address
     * @dev     Only callable by admin
     * @param   _portfolioBridge  New portfolio bridge contract address
     */
    function setPortfolioBridge(address _portfolioBridge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        //Can't have multiple portfolioBridge using the same portfolio
        if (hasRole(PORTFOLIO_BRIDGE_ROLE, address(portfolioBridge)))
            super.revokeRole(PORTFOLIO_BRIDGE_ROLE, address(portfolioBridge));
        portfolioBridge = IPortfolioBridge(_portfolioBridge);
        grantRole(PORTFOLIO_BRIDGE_ROLE, _portfolioBridge);
        emit AddressSet("PORTFOLIO", "SET-PORTFOLIOBRIDGE", _portfolioBridge, _portfolioBridge);
    }

    /**
     * @notice  Enables or disables a bridge provider
     * @dev     Only callable by admin
     * @param   _bridge  Enum value of the bridge provider
     * @param   _enable  True to enable, false to disable
     */
    function enableBridgeProvider(
        IPortfolioBridge.BridgeProvider _bridge,
        bool _enable
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        portfolioBridge.enableBridgeProvider(_bridge, _enable);
        emit ParameterUpdated(bytes32("Portfolio"), "P-BRIDGE-ENABLE", _enable ? 0 : 1, uint256(_bridge));
    }

    /**
     * @notice  Revoke access control role wrapper
     * @dev     Only callable by admin. Can't revoke itself's role, can't remove the only admin.
     * @param   _role  Role to be revoked
     * @param   _address  Address to be revoked
     */
    function revokeRole(
        bytes32 _role,
        address _address
    ) public override(AccessControlUpgradeable, IAccessControlUpgradeable) onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "P-OACC-02");
        // We need to have at least one admin in DEFAULT_ADMIN_ROLE
        if (_role == DEFAULT_ADMIN_ROLE) {
            require(getRoleMemberCount(_role) > 1, "P-ALOA-01");
        } else if (_role == PORTFOLIO_BRIDGE_ROLE) {
            // We need to have at least one  in PORTFOLIO_BRIDGE_ROLE
            require(getRoleMemberCount(_role) > 1, "P-ALOA-02");
        }

        super.revokeRole(_role, _address);
        emit RoleUpdated("PORTFOLIO", "REMOVE-ROLE", _role, _address);
    }

    /**
     * @notice  Returns the native token of the chain
     * @return  bytes32  Symbol of the native token
     */
    function getNative() external view override returns (bytes32) {
        return native;
    }

    /**
     * @notice  Returns the native token of the chain
     * @return  bytes32  Symbol of the native token
     */
    function getChainId() external view override returns (uint32) {
        return chainId;
    }

    /**
     * @notice  Pauses the portfolioBridge AND the contract
     * @dev     Only callable by admin
     */
    function pause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
        if (!PausableUpgradeable(address(portfolioBridge)).paused()) {
            portfolioBridge.pause();
        }
    }

    /**
     * @notice  Unpauses portfolioBridge AND the contract
     * @dev     Only callable by admin
     */
    function unpause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
        if (PausableUpgradeable(address(portfolioBridge)).paused()) {
            portfolioBridge.unpause();
        }
    }

    /**
     * @notice  (Dis)allows the deposit functionality only
     * @dev     Only callable by admin
     * @param   _depositPause  True to allow, false to disallow
     */
    function pauseDeposit(bool _depositPause) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        allowDeposit = !_depositPause;
    }

    /**
     * @notice  Sets the bridge provider fee & gasSwapRatio per ALOT for the given token and usedForGasSwap flag
     * @dev     External function to be called by DEFAULT_ADMIN_ROLE or PORTFOLIO_BRIDGE_ROLE
     * @param   _symbol  Symbol of the token
     * @param   _fee  Fee to be set
     * @param   _gasSwapRatio  Amount of token to swap per ALOT. Always set it to equivalent of 1 ALOT.
     * @param   _usedForGasSwap  bool to control the list of tokens that can be used for gas swap. Mostly majors
     */
    function setBridgeParam(bytes32 _symbol, uint256 _fee, uint256 _gasSwapRatio, bool _usedForGasSwap) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(PORTFOLIO_BRIDGE_ROLE, msg.sender), "P-OACC-01");
        setBridgeParamInternal(_symbol, _fee, _gasSwapRatio, _usedForGasSwap);
    }

    /**
     * @notice  Sets the bridge provider fee & gasSwapRatio per ALOT for the given token
     * @dev     Called by Portfolio.initialize() addTokenInternal
     * @param   _symbol  Symbol of the token
     * @param   _fee  Fee to be set
     * @param   _gasSwapRatio  Amount of token to swap per ALOT. Always set it to equivalent of 1 ALOT.
     * @param   _usedForGasSwap  bool to control the list of tokens that can be used for gas swap. Mostly majors
     */
    function setBridgeParamInternal(
        bytes32 _symbol,
        uint256 _fee,
        uint256 _gasSwapRatio,
        bool _usedForGasSwap
    ) internal virtual {
        emit ParameterUpdated(_symbol, "P-SET-BRIDGEPARAM", bridgeParams[_symbol].gasSwapRatio, _gasSwapRatio);
        BridgeParams storage bridgeParam = bridgeParams[_symbol];
        bridgeParam.fee = _fee;

        if (_symbol != bytes32("ALOT")) {
            bridgeParam.gasSwapRatio = _gasSwapRatio;
            bridgeParam.usedForGasSwap = _usedForGasSwap;
        } else if (_symbol == bytes32("ALOT") && bridgeParam.gasSwapRatio == 0) {
            // For ALOT gasSwapFee can only be set to 1 ( 1 to 1 ratio at all times) and can't be changed
            bridgeParam.gasSwapRatio = 1 * 10 ** 18;
            bridgeParam.usedForGasSwap = true;
        }
    }

    /**
     * @notice  Actual private function that implements the token addition
     * @param   _details  Token Details
     *  _fee  Bridge Fee (child implementation)
     *  _gasSwapRatio  Amount of token to swap per ALOT (child implementation)
     */
    function addTokenInternal(TokenDetails memory _details, uint256, uint256) internal virtual {
        require(!tokenList.contains(_details.symbol), "P-TAEX-01");
        require(_details.decimals > 0, "P-CNAT-01");

        TokenDetails storage tokenDetails = tokenDetailsMap[_details.symbol];
        tokenDetails.auctionMode = _details.auctionMode;
        tokenDetails.decimals = _details.decimals;
        tokenDetails.tokenAddress = _details.tokenAddress;
        tokenDetails.srcChainId = _details.srcChainId;
        tokenDetails.symbol = _details.symbol;
        bytes32 symbolId = UtilsLibrary.getIdForToken(_details.symbol, tokenDetails.srcChainId);
        tokenDetails.symbolId = symbolId;
        tokenDetails.isVirtual = _details.isVirtual;
        //sourceChainSymbol is always equal to symbol for Portfolios
        //It is needed specifically in PortfolioBridgeSub and can be different
        tokenDetails.sourceChainSymbol = _details.symbol;
        //add to the list by symbol
        tokenList.add(_details.symbol);
        //add to the list by symbolId
        tokenDetailsMapById[symbolId] = _details.symbol;
        emit ParameterUpdated(_details.symbol, "P-ADDTOKEN", _details.decimals, uint256(_details.auctionMode));
    }

    /**
     * @notice  Removes the given token from the portfolio
     * @dev     Only callable by admin and portfolio should be paused. Make sure there are no
     * in-flight deposit/withdraw messages.
     * @param   _symbol  Symbol of the token
     * @param   _srcChainId  Source Chain id. It is always the mainnet chainid for PortfolioMain
     */
    function removeToken(
        bytes32 _symbol,
        uint32 _srcChainId
    ) public virtual override whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenList.remove(_symbol);
        delete (tokenDetailsMap[_symbol]);
        bytes32 symbolId = UtilsLibrary.getIdForToken(_symbol, _srcChainId);
        delete (tokenDetailsMapById[symbolId]);
        delete (bridgeParams[_symbol]);
        emit ParameterUpdated(_symbol, "P-REMOVETOKEN", 0, 0);
    }

    /**
     * @notice  Frontend function to get all the tokens in the portfolio
     * @return  bytes32[]  Array of symbols of the tokens
     */
    function getTokenList() external view override returns (bytes32[] memory) {
        bytes32[] memory tokens = new bytes32[](tokenList.length());
        for (uint256 i = 0; i < tokenList.length(); ++i) {
            tokens[i] = tokenList.at(i);
        }
        return tokens;
    }

    /**
     * @notice  Returns the token details.
     * @dev     Subnet does not have any ERC20s, hence the tokenAddress is token's mainnet address.
     * See the TokenDetails struct in IPortfolio for the full type information of the return variable.
     * @param   _symbol  Symbol of the token. Identical to mainnet
     * @return  TokenDetails decimals : Identical both in the mainnet and the subnet
     * tokenAddress : Token address at the mainnet , zeroaddress at the subnet
     * symbolId : symbol + chainId
     * native coin : it will always have zeroaddress both in the mainnet and the subnet
     */
    function getTokenDetails(bytes32 _symbol) external view override returns (TokenDetails memory) {
        return tokenDetailsMap[_symbol];
    }

    /**
     * @notice  Returns the token details.
     * @param   _symbolId  symbolId of the token.
     * @return  TokenDetails  see getTokenDetails
     */
    function getTokenDetailsById(bytes32 _symbolId) external view override returns (TokenDetails memory) {
        return tokenDetailsMap[tokenDetailsMapById[_symbolId]];
    }

    /**
     * @notice  Returns the bridge fee for the given bridge provider, token,
     * destination chain and quantity
     * @dev    Calls the portfolioBridge contract to get the bridge fee which
     * in addition includes withdrawal fee for PortfolioSub but only bridge fee for PortfolioMain
     * @param   _bridge  Enum value of the bridge provider
     * @param   _dstChainListOrgChainId  Chain id of the destination chain
     * @param   _symbol  Symbol of the token
     * @param   _quantity  Quantity of the token
     * @return  bridgeFee  Bridge fee
     */
    function getBridgeFee(
        IPortfolioBridge.BridgeProvider _bridge,
        uint32 _dstChainListOrgChainId,
        bytes32 _symbol,
        uint256 _quantity
    ) external view returns (uint256 bridgeFee) {
        return portfolioBridge.getBridgeFee(_bridge, _dstChainListOrgChainId, _symbol, _quantity);
    }

    /**
     * @dev we revert transaction if a non-existing function is called
     */
    fallback() external payable {
        revert("P-NFUN-01");
    }

    /**
     * @notice Receive function for direct send of native tokens
     * @dev we process it as a deposit with the default bridge
     */
    receive() external payable {
        this.depositNative{value: msg.value}(payable(msg.sender), portfolioBridge.getDefaultBridgeProvider());
    }

    /**
     * @notice  Processes the XFER message coming from the bridge
     * @dev     Overridden in the child contracts, as the logic differs.
     * @param   _xfer  Transfer message
     */
    function processXFerPayload(IPortfolio.XFER calldata _xfer) external virtual override;

    /**
     * @dev     Overridden in the child contracts, as the logic differs.
     * @param   _from  Address of the depositor
     * @param   _bridge  Enum for bridge type
     */
    function depositNative(
        address payable _from,
        IPortfolioBridge.BridgeProvider _bridge
    ) external payable virtual override;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "./Portfolio.sol";
import "./interfaces/ITradePairs.sol";
import "./interfaces/IPortfolioMain.sol";
import "./interfaces/IBannedAccounts.sol";

/**
 * @title Mainnet Portfolio
 * @dev This contract prevalidates the PortfolioSub checks and allows deposits to be sent to the subnet.
 * ExchangeMain needs to have DEFAULT_ADMIN_ROLE on PortfolioMain.
 */

// The code in this file is part of Dexalot project.
// Please see the LICENSE.txt file for licensing info.
// Copyright 2022 Dexalot.

contract PortfolioMain is Portfolio, IPortfolioMain {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // version
    bytes32 public constant VERSION = bytes32("2.5.5");

    // bytes32 symbols to ERC20 token map
    mapping(bytes32 => IERC20Upgradeable) public tokenMap;

    // bytes32 symbols to amount of bridge fee collected
    mapping(bytes32 => uint256) public bridgeFeeCollected;
    // contract address that we trust to perform limited functions like deposit DD symbol
    mapping(address => bool) public trustedContracts;
    // contract address to integrator organization name
    mapping(address => string) public trustedContractToIntegrator;

    // banned accounts contract address set externally with setBannedAccounts as part of deployment
    IBannedAccounts internal bannedAccounts;
    uint8 public minDepositMultiplier;
    bool public nativeDepositsRestricted;

    /**
     * @notice  Initializes the PortfolioMain contract
     * @param   _native  Symbol of the native token
     * @param   _chainId  Current chainId of the Portfolio
     */
    function initialize(bytes32 _native, uint32 _chainId) public override initializer {
        Portfolio.initialize(_native, _chainId);
        minDepositMultiplier = 19; // 19/10 1.9 times
        // Always Add native with 0 Bridge Fee and 0.01 gasSwapRatio (1 AVAX for 1 ALOT)
        // This value will be adjusted periodically
        TokenDetails memory details = TokenDetails(
            18,
            address(0),
            ITradePairs.AuctionMode.OFF, // Auction Mode is ignored as it is irrelevant in the Mainnet
            _chainId,
            native,
            bytes32(0),
            native,
            false
        );
        addTokenInternal(details, 0, 1 * 10 ** 16);
    }

    /**
     * @notice  Adds the given token to the portfolio
     * @dev     Only callable by admin.
     * We don't allow tokens with the same symbols but different addresses.
     * Native symbol is also added by default with 0 address.
     * @param   _symbol  Symbol of the token
     * @param   _tokenAddress  Address of the token
     * @param   _srcChainId  Source Chain Symbol of the virtual token only. Otherwise it is overridden by the
     * current chainid
     * @param   _decimals  Decimals of the token
     * @param   _fee  Bridge Fee
     * @param   _gasSwapRatio  Amount of token to swap per ALOT
     * @param   _isVirtual  Not an ERC20 or native. It is only used to facilitate Cross Chain Trades where the
     * token doesn't exist
     */
    function addToken(
        bytes32 _symbol,
        address _tokenAddress,
        uint32 _srcChainId,
        uint8 _decimals,
        uint256 _fee,
        uint256 _gasSwapRatio,
        bool _isVirtual
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        TokenDetails memory details = TokenDetails(
            _decimals,
            _tokenAddress,
            // Auction Mode is ignored as it is irrelevant in the Mainnet
            ITradePairs.AuctionMode.OFF,
            //always add with the chain id of the Portfolio unless virtual
            _isVirtual ? _srcChainId : chainId, // srcChainId.
            _symbol, //symbol
            bytes32(0), //symbolId
            _symbol, //sourceChainSymbol, it is always equal to symbol for PortfolioMain
            _isVirtual
        );

        addTokenInternal(details, _fee, _gasSwapRatio);
        if (_symbol == native) {
            nativeDepositsRestricted = false;
        }
    }

    /**
     * @notice  Internal function that implements the token addition
     * @dev     Unlike in the subnet it doesn't add the token to the PortfolioBridgeMain as it is redundant
     * Sample Token List in PortfolioMain: \
     * Symbol, SymbolId, Decimals, address, auction mode (43114: Avalanche C-ChainId) \
     * ALOT ALOT43114 18 0x5FbDB2315678afecb367f032d93F642f64180aa3 0 (Avalanche ALOT) \
     * AVAX AVAX43114 18 0x0000000000000000000000000000000000000000 0 (Avalanche Native AVAX) \
     * BTC.b BTC.b43114 8 0x59b670e9fA9D0A427751Af201D676719a970857b 0 \
     * DEG DEG43114 18 0x99bbA657f2BbC93c02D617f8bA121cB8Fc104Acf 2 \
     * LOST LOST43114 18 0x162A433068F51e18b7d13932F27e66a3f99E6890 0 \
     * SLIME SLIME43114 18 0x2B0d36FACD61B71CC05ab8F3D2355ec3631C0dd5 0 \
     * USDC USDC43114 6 0xD5ac451B0c50B9476107823Af206eD814a2e2580 0 \
     * USDt USDt43114 6 0x38a024C0b412B9d1db8BC398140D00F5Af3093D4 0 \
     * @param   _details  Token Details
     * @param   _fee  Bridge Fee
     * @param   _gasSwapRatio  Amount of token to swap per ALOT
     */
    function addTokenInternal(TokenDetails memory _details, uint256 _fee, uint256 _gasSwapRatio) internal override {
        super.addTokenInternal(_details, _fee, _gasSwapRatio);
        // Tokens can't be used to swap gas by default
        setBridgeParamInternal(_details.symbol, _fee, _gasSwapRatio, _details.symbol == bytes32("ALOT") ? true : false);
        if (_details.symbol != native && !_details.isVirtual) {
            require(_details.tokenAddress != address(0), "P-ZADDR-01");
            IERC20MetadataUpgradeable assetIERC20 = IERC20MetadataUpgradeable(_details.tokenAddress);
            require(UtilsLibrary.stringToBytes32(assetIERC20.symbol()) == _details.symbol, "P-TSDM-01");
            require(assetIERC20.decimals() == _details.decimals, "P-TDDM-01");
            tokenMap[_details.symbol] = IERC20MetadataUpgradeable(_details.tokenAddress);
        }
    }

    /**
     * @notice  Removes the given token from the portfolio. Native token removal is allowed if only the wrapped
     * version of the token needs to be supported.
     * @dev     Only callable by admin and portfolio should be paused. Makes sure there are no
     * in-flight deposit/withdraw messages
     * @param   _symbol  Symbol of the token
     */
    function removeToken(bytes32 _symbol, uint32) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        TokenDetails memory tokenDetails = tokenDetailsMap[_symbol];
        if (tokenDetails.symbol != bytes32(0) && !tokenDetails.isVirtual) {
            require(
                _symbol == native ? address(this).balance == 0 : tokenMap[_symbol].balanceOf(address(this)) == 0,
                "P-NZBL-01"
            );
            // If native is removed, native deposits gets restricted by default
            if (_symbol == native) {
                nativeDepositsRestricted = true;
            } else {
                // Native doesn't exist in tokenMap as it is not an ERC20
                delete (tokenMap[_symbol]);
            }
        }
        super.removeToken(_symbol, chainId); // Can only remove the local chain's tokens in the mainnet
    }

    /**
     * @notice  Changes the mapping from one symbol to the other symbol
     * @dev     Only admin can call this function. This is specifically to rename
     * EUROC on avalanche. This ERC20 symbol was later on was changed to EURC by Circle.
     * Can be removed after the rename but also can be kept to support any future ERC20 symbol changes.
     * Low impact as It doesn't touch the balances nor the renamed ERC20's address.
     * @param   _fromSymbol  Original mainnet token symbol
     * @param   _toSymbol  New mainnet token symbol
     */
    function renameToken(bytes32 _fromSymbol, bytes32 _toSymbol) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_fromSymbol != _toSymbol, "P-LENM-01");
        TokenDetails storage tokenDetails = tokenDetailsMap[_fromSymbol];
        // Make sure the ERC20 changed its symbol
        require(
            UtilsLibrary.stringToBytes32(IERC20MetadataUpgradeable(address(tokenMap[_fromSymbol])).symbol()) ==
                _toSymbol,
            "P-TSDM-01"
        );
        //Copy over the references to the new symbol
        tokenMap[_toSymbol] = tokenMap[_fromSymbol];
        tokenDetails.symbol = _toSymbol;
        tokenDetails.symbolId = UtilsLibrary.getIdForToken(_toSymbol, tokenDetails.srcChainId);
        tokenDetails.sourceChainSymbol = _toSymbol;
        tokenDetailsMap[_toSymbol] = tokenDetails;
        tokenDetailsMapById[tokenDetails.symbolId] = _toSymbol;
        tokenList.add(tokenDetails.symbol);
        bridgeParams[_toSymbol] = bridgeParams[_fromSymbol];
        //Remove the old token references
        super.removeToken(_fromSymbol, tokenDetails.srcChainId);
    }

    /**
     * @notice  Frontend function to get the ERC20 token
     * @param   _symbol  symbol of the token
     * @return  IERC20Upgradeable  ERC20 token
     */
    function getToken(bytes32 _symbol) external view override returns (IERC20Upgradeable) {
        return tokenMap[_symbol];
    }

    /**
     * @param   _from  Address of the depositor
     * @param   _bridge  Enum for bridge type
     */
    function depositNative(
        address payable _from,
        IPortfolioBridge.BridgeProvider _bridge
    ) external payable override whenNotPaused nonReentrant {
        require(_from == msg.sender || msg.sender == address(this), "P-OOWN-02"); // calls made by super.receive()
        if (nativeDepositsRestricted) {
            revert("P-NDNS-01");
            //TODO Wrap native to its Wrapped equivalent in the future
        } else {
            deposit(_from, native, msg.value, _bridge);
        }
    }

    /**
     * @param   _from  Address of the depositor
     * @param   _symbol  Symbol of the token
     * @param   _quantity  Amount of token to deposit
     * @param   _bridge  Enum for bridge type
     */
    function depositToken(
        address _from,
        bytes32 _symbol,
        uint256 _quantity,
        IPortfolioBridge.BridgeProvider _bridge
    ) external whenNotPaused nonReentrant {
        require(
            _from == msg.sender ||
                msg.sender == address(this) || // allow calls made by depositTokenFromContract
                trustedContracts[msg.sender], // keeping it for backward compatibility
            "P-OODT-01"
        );
        require(tokenList.contains(_symbol), "P-ETNS-01");
        require(tokenDetailsMap[_symbol].isVirtual == false, "P-VTNS-01"); // Virtual tokens can't be deposited
        require(_quantity <= tokenMap[_symbol].balanceOf(_from), "P-NETD-01");

        tokenMap[_symbol].safeTransferFrom(_from, address(this), _quantity);
        deposit(_from, _symbol, _quantity, _bridge);
    }

    function deposit(
        address _from,
        bytes32 _symbol,
        uint256 _quantity,
        IPortfolioBridge.BridgeProvider _bridge
    ) private {
        require(allowDeposit, "P-NTDP-01");
        require(_quantity > this.getMinDepositAmount(_symbol), "P-DUTH-01");
        require(!bannedAccounts.isBanned(_from), "P-BANA-01");
        BridgeParams storage bridgeParam = bridgeParams[_symbol];
        if (bridgeParam.fee > 0) {
            bridgeFeeCollected[_symbol] = bridgeFeeCollected[_symbol] + bridgeParam.fee;
        }
        emitPortfolioEvent(_from, _symbol, _quantity, bridgeParam.fee, Tx.DEPOSIT);
        // Nonce to be assigned in PBridge
        portfolioBridge.sendXChainMessage(
            portfolioBridge.getDefaultDestinationChain(),
            _bridge,
            XFER(0, Tx.DEPOSIT, _from, _symbol, _quantity - bridgeParam.fee, block.timestamp, bytes28(0)),
            _from
        );
    }

    /**
     * @notice  Sets the bridge provider fee & gasSwapRatio per ALOT for the given token and usedForGasSwap flag
     * @dev     Called by PortfolioSub.initialize() as well as setBridgeParam()
     * We can never set a token gasSwapRatio to 0 in the mainnet
     * @param   _symbol  Symbol of the token
     * @param   _fee  Fee to be set
     * @param   _gasSwapRatio  Amount of token to swap per ALOT. Used to control min deposit amount in the mainnet
     * Because we want users to deposit more than whats going to be swapped out for them to end up a portion of their
     * token in their subnet portfolio after the swap. gasSwapRatio will be updated daily with an offchain app with
     * the current market pricesexcept for ALOT which is always 1 to 1. Daily update is sufficient as it is multiplied
     * by 1.9 to calculate the min deposit Amount.
     * _usedForGasSwap  not used in the mainnet
     */
    function setBridgeParamInternal(bytes32 _symbol, uint256 _fee, uint256 _gasSwapRatio, bool) internal override {
        require(_gasSwapRatio > 0, "P-GSRO-01");
        super.setBridgeParamInternal(_symbol, _fee, _gasSwapRatio, false);
    }

    /**
     * @notice  Minimum Transaction Amount in deposits
     * @dev     The user has to have at least 1.9 as much for bridge fee (if set) + any potential gas token swap
     * For ALOT this will be 1.9 by default, so we are allowing 2 ALOT to be deposited easily
     * @param   _symbol  Symbol of the token
     * @return  uint256  Minimum DepositAmount
     */
    function getMinDepositAmount(bytes32 _symbol) external view returns (uint256) {
        BridgeParams storage bridgeParam = bridgeParams[_symbol];
        return ((bridgeParam.fee + bridgeParam.gasSwapRatio) * minDepositMultiplier) / 10;
    }

    /**
     * @notice  Sets the minimum deposit multiplier
     * @dev     The multiplier entered will always be divided by 10
     * @param   _minDepositMultiplier  multiplier for minimum deposits
     */
    function setMinDepositMultiplier(uint8 _minDepositMultiplier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minDepositMultiplier >= 10, "P-MDML-01"); // min 10 ==> 10/10
        emit ParameterUpdated(bytes32("PortfolioMain"), "P-MINDEP-MULT", minDepositMultiplier, _minDepositMultiplier);
        minDepositMultiplier = _minDepositMultiplier;
    }

    /**
     * @notice  List of Minimum Deposit Amounts
     * @dev     The user has to have at least 1.9 as much for bridge fee (if set) + any potential gas token swap
     * @return  bytes32[]  tokens uint256[] amounts  .
     */
    function getMinDepositAmounts() external view returns (bytes32[] memory, uint256[] memory) {
        bytes32[] memory tokens = new bytes32[](tokenList.length());
        uint256[] memory amounts = new uint256[](tokenList.length());

        for (uint256 i = 0; i < tokenList.length(); ++i) {
            BridgeParams storage bridgeParam = bridgeParams[tokenList.at(i)];
            tokens[i] = tokenList.at(i);
            amounts[i] = ((bridgeParam.fee + bridgeParam.gasSwapRatio) * minDepositMultiplier) / 10;
        }
        return (tokens, amounts);
    }

    /**
     * @notice  Adds the given contract to trusted contracts in order to provide excluded functionality
     * @dev     Only callable by admin
     * @param   _contract  Address of the contract to be added
     * @param   _organization  Organization of the contract to be added
     */
    function addTrustedContract(
        address _contract,
        string calldata _organization
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        trustedContracts[_contract] = true;
        trustedContractToIntegrator[_contract] = _organization;
        emit AddressSet(_organization, "P-ADD-TRUSTEDCONTRACT", _contract, _contract);
    }

    /**
     * @param   _contract  Address of the contract
     * @return  bool  True if the contract is trusted
     */
    function isTrustedContract(address _contract) external view override returns (bool) {
        return trustedContracts[_contract];
    }

    /**
     * @notice  Removes the given contract from trusted contracts
     * @dev     Only callable by admin
     * @param   _contract  Address of the contract to be removed
     */
    function removeTrustedContract(address _contract) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        trustedContracts[_contract] = false;
        emit AddressSet(trustedContractToIntegrator[_contract], "P-REMOVE-TRUSTED-CONTRACT", _contract, _contract);
    }

    /**
     * @notice  Allows deposits from trusted contracts
     * @dev     Used by Avalaunch for DD deposits and Vesting Contracts.
     * Keeping for backward compatibility instead of using ON_BEHALF_ROLE.
     * @param   _from  Address of the depositor
     * @param   _symbol  Symbol of the token
     * @param   _quantity  Amount of token to deposit
     */
    function depositTokenFromContract(address _from, bytes32 _symbol, uint256 _quantity) external override {
        require(trustedContracts[msg.sender], "P-AOTC-01"); // keeping it for backward compatibility
        this.depositToken(_from, _symbol, _quantity, portfolioBridge.getDefaultBridgeProvider());
    }

    /**
     * @notice  Sets banned accounts contract address
     * @param  _address  address of the banned accounts contract
     */
    function setBannedAccounts(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bannedAccounts = IBannedAccounts(_address);
    }

    /**
     * @return  IBannedAccounts  banned accounts contract
     */
    function getBannedAccounts() external view returns (IBannedAccounts) {
        return bannedAccounts;
    }

    /**
     * @notice  Processes the message coming from the bridge
     * @dev     WITHDRAW message is the only message that can be sent to portfolioMain.
     * Even when the contract is paused, this method is allowed for the messages that
     * are in flight to complete properly. Pause for upgrade, then wait to make sure no messages are in
     * flight then upgrade
     * @param   _xfer  Transfer message
     */
    function processXFerPayload(
        IPortfolio.XFER calldata _xfer
    ) external override nonReentrant onlyRole(PORTFOLIO_BRIDGE_ROLE) {
        if (_xfer.transaction == Tx.WITHDRAW) {
            require(_xfer.trader != address(0), "P-ZADDR-02");
            require(_xfer.quantity > 0, "P-ZETD-01");
            if (_xfer.symbol == native) {
                //Withdraw native
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = _xfer.trader.call{value: _xfer.quantity}("");
                require(success, "P-WNFA-01");
            } else {
                //Withdraw Token
                //We don't check the AuctionMode of the token in the mainnet. If Subnet allows the message to be sent
                //Then the token is no longer is auction
                tokenMap[_xfer.symbol].safeTransfer(_xfer.trader, _xfer.quantity);
            }
            emitPortfolioEvent(_xfer.trader, _xfer.symbol, _xfer.quantity, 0, _xfer.transaction);
        } else {
            revert("P-PTNS-02");
        }
    }

    /**
     * @notice  Allows the owner to withdraw the fees collected from the bridge
     * @dev     Collect fees to pay for the bridge as native token
     * @dev     Only the owner can call this function
     * @param   _symbols  Array of symbols of tokens to withdraw
     */
    function collectBridgeFees(bytes32[] calldata _symbols) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _symbols.length; ++i) {
            require(tokenList.contains(_symbols[i]), "P-ETNS-02");
            uint256 bcf = bridgeFeeCollected[_symbols[i]];
            if (bcf > 0) {
                bridgeFeeCollected[_symbols[i]] = 0;
                tokenMap[_symbols[i]].safeTransfer(msg.sender, bcf);
            }
        }
    }

    /**
     * @notice  Allows the owner to withdraw the fees collected in AVAX from the bridge
     * @dev     Collect fees to pay for the bridge as native token
     * @dev     Only the owner can call this function
     */
    function collectNativeBridgeFees() external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 bcf = bridgeFeeCollected[native];
        bridgeFeeCollected[native] = 0;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: bcf}("");
        require(success, "P-CNFF-01");
    }

    /**
     * @notice  Wrapper for emit event
     * @param   _trader  Address of the trader
     * @param   _symbol  Symbol of the token
     * @param   _quantity  Amount of token used in the transaction
     * @param   _feeCharged  Fee charged for the transaction
     * @param   transaction  Transaction type
     */
    function emitPortfolioEvent(
        address _trader,
        bytes32 _symbol,
        uint256 _quantity,
        uint256 _feeCharged,
        Tx transaction
    ) private {
        emit PortfolioUpdated(transaction, _trader, _symbol, _quantity, _feeCharged, 0, 0, _trader);
    }
}