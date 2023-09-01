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
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
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
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

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
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IAdaptor {
    /* Cross-chain functions that is used to initiate a cross-chain message, should be invoked by Pool */
    function bridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 gasLimit
    ) external payable returns (uint256 trackingId);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IAsset is IERC20 {
    function underlyingToken() external view returns (address);

    function pool() external view returns (address);

    function cash() external view returns (uint120);

    function liability() external view returns (uint120);

    function decimals() external view returns (uint8);

    function underlyingTokenDecimals() external view returns (uint8);

    function setPool(address pool_) external;

    function underlyingTokenBalance() external view returns (uint256);

    function transferUnderlyingToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function addCash(uint256 amount) external;

    function removeCash(uint256 amount) external;

    function addLiability(uint256 amount) external;

    function removeLiability(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface ICrossChainPool {
    /**
     * @notice Initiate a cross chain swap to swap tokens from a chain to tokens in another chain
     * @dev Steps:
     * 1. User call `swapTokensForTokensCrossChain` to swap `fromToken` for credit
     * 2. CrossChainPool request wormhole adaptor to relay the message to the designated chain
     * 3. On the designated chain, wormhole relayer invoke `completeSwapCreditForTokens` to swap credit for `toToken` in the `toChain`
     * Note: Amount of `value` attached to this function can be estimated by `WormholeAdaptor.estimateDeliveryFee`
     */
    function swapTokensForTokensCrossChain(
        address fromToken,
        address toToken,
        uint256 toChain, // wormhole chain ID
        uint256 fromAmount,
        uint256 minimumCreditAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue, // gas to receive at the designated contract
        uint256 gasLimit // gas limit for the relayed transaction
    ) external payable returns (uint256 creditAmount, uint256 fromTokenFee, uint256 id);

    /**
     * @notice Swap credit for tokens (same chain)
     * @dev In case user has some credit, he/she can use this function to swap credit to tokens
     */
    function swapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver
    ) external returns (uint256 actualToAmount, uint256 toTokenFee);

    /**
     * @notice Bridge credit and swap it for `toToken` in the `toChain`
     * @dev In case user has some credit, he/she can use this function to swap credit to tokens in another network
     * Note: Amount of `value` attached to this function can be estimated by `WormholeAdaptor.estimateDeliveryFee`
     */
    function swapCreditForTokensCrossChain(
        address toToken,
        uint256 toChain, // wormhole chain ID
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue, // gas to receive at the designated contract
        uint256 gasLimit // gas limit for the relayed transaction
    ) external payable returns (uint256 id);

    /*
     * Permissioned Functions
     */

    /**
     * @notice Swap credit to tokens; should be called by the adaptor
     */
    function completeSwapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver
    ) external returns (uint256 actualToAmount, uint256 toTokenFee);

    function mintCredit(uint256 creditAmount, address receiver) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IPoolV3 {
    function getTokens() external view returns (address[] memory);

    function addressOfAsset(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quotePotentialDeposit(address token, uint256 amount) external view returns (uint256 liquidity);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(address token, uint256 liquidity) external view returns (uint256 amount);

    function quotePotentialWithdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity
    ) external view returns (uint256 finalAmount, uint256 withdrewAmount);

    function quoteAmountIn(
        address fromToken,
        address toToken,
        int256 toAmount
    ) external view returns (uint256 amountIn, uint256 haircut);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IRelativePriceProvider {
    /**
     * @notice get the relative price in WAD
     */
    function getRelativePrice() external view returns (uint256);
}

// copied from https://github.com/wormhole-foundation/wormhole/blob/8d63ab50fb7cc80c54fa25b81f764c3a2ee132dc/ethereum/contracts/interfaces/IWormhole.sol
// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint numGuardians) external pure returns (uint numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// copied from https://github.com/wormhole-foundation/wormhole/blob/8d63ab50fb7cc80c54fa25b81f764c3a2ee132dc/ethereum/contracts/interfaces/relayer/IWormholeReceiver.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

/**
 * @notice Interface for a contract which can receive Wormhole messages.
 */
interface IWormholeReceiver {
    /**
     * @notice When a `send` is performed with this contract as the target, this function will be
     *     invoked by the WormholeRelayer contract
     *
     * NOTE: This function should be restricted such that only the Wormhole Relayer contract can call it.
     *
     * We also recommend that this function:
     *   - Stores all received `deliveryHash`s in a mapping `(bytes32 => bool)`, and
     *       on every call, checks that deliveryHash has not already been stored in the
     *       map (This is to prevent other users maliciously trying to relay the same message)
     *   - Checks that `sourceChain` and `sourceAddress` are indeed who
     *       you expect to have requested the calling of `send` or `forward` on the source chain
     *
     * The invocation of this function corresponding to the `send` request will have msg.value equal
     *   to the receiverValue specified in the send request.
     *
     * If the invocation of this function reverts or exceeds the gas limit
     *   specified by the send requester, this delivery will result in a `ReceiverFailure`.
     *
     * @param payload - an arbitrary message which was included in the delivery by the
     *     requester.
     * @param additionalVaas - Additional VAAs which were requested to be included in this delivery.
     *   They are guaranteed to all be included and in the same order as was specified in the
     *     delivery request.
     * @param sourceAddress - the (wormhole format) address on the sending chain which requested
     *     this delivery.
     * @param sourceChain - the wormhole chain ID where this delivery was requested.
     * @param deliveryHash - the VAA hash of the deliveryVAA.
     *
     * NOTE: These signedVaas are NOT verified by the Wormhole core contract prior to being provided
     *     to this call. Always make sure `parseAndVerify()` is called on the Wormhole core contract
     *     before trusting the content of a raw VAA, otherwise the VAA may be invalid or malicious.
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable;
}

// Copied from https://github.com/wormhole-foundation/wormhole/blob/8d63ab50fb7cc80c54fa25b81f764c3a2ee132dc/ethereum/contracts/interfaces/relayer/IWormholeRelayer.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

/**
 * @title WormholeRelayer
 * @author 
 * @notice This project allows developers to build cross-chain applications powered by Wormhole without needing to 
 * write and run their own relaying infrastructure
 * 
 * We implement the IWormholeRelayer interface that allows users to request a delivery provider to relay a payload (and/or additional VAAs) 
 * to a chain and address of their choice.
 */

/**
 * @notice VaaKey identifies a wormhole message
 *
 * @custom:member chainId Wormhole chain ID of the chain where this VAA was emitted from
 * @custom:member emitterAddress Address of the emitter of the VAA, in Wormhole bytes32 format
 * @custom:member sequence Sequence number of the VAA
 */
struct VaaKey {
    uint16 chainId;
    bytes32 emitterAddress;
    uint64 sequence;
}

interface IWormholeRelayerBase {
    event SendEvent(
        uint64 indexed sequence, uint256 deliveryQuote, uint256 paymentForExtraReceiverValue
    );

    function getRegisteredWormholeRelayerContract(uint16 chainId) external view returns (bytes32);
}

/**
 * @title IWormholeRelayerSend
 * @notice The interface to request deliveries
 */
interface IWormholeRelayerSend is IWormholeRelayerBase {

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload to the address `targetAddress` on chain `targetChain` 
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     * 
     * `targetAddress` must implement the IWormholeReceiver interface
     * 
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     * 
     * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendPayloadToEvm` function 
     * with `refundChain` and `refundAddress` as parameters
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver) 
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload to the address `targetAddress` on chain `targetChain` 
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     * 
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     * 
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver) 
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain` 
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     * 
     * `targetAddress` must implement the IWormholeReceiver interface
     * 
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     * 
     * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendVaasToEvm` function 
     * with `refundChain` and `refundAddress` as parameters
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver) 
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. 
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain` 
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     * 
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     * 
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver) 
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the 
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress` 
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain` 
     * with gas limit `gasLimit` and `msg.value` equal to 
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     * 
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     * 
     * This function must be called with `msg.value` equal to 
     * quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit, deliveryProviderAddress) + paymentForExtraReceiverValue
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver) 
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue 
     *        (in addition to the `receiverValue` specified)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the  
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see 
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);
    
    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress` 
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain` 
     * with `msg.value` equal to 
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     * 
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     * 
     * This function must be called with `msg.value` equal to 
     * quoteDeliveryPrice(targetChain, receiverValue, encodedExecutionParameters, deliveryProviderAddress) + paymentForExtraReceiverValue  
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue 
     *        (in addition to the `receiverValue` specified)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see 
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Performs the same function as a `send`, except:
     * 1)  Can only be used during a delivery (i.e. in execution of `receiveWormholeMessages`)
     * 2)  Is paid for (along with any other calls to forward) by (any msg.value passed in) + (refund leftover from current delivery)
     * 3)  Only executes after `receiveWormholeMessages` is completed (and thus does not return a sequence number)
     * 
     * The refund from the delivery currently in progress will not be sent to the user; it will instead
     * be paid to the delivery provider to perform the instruction specified here
     * 
     * Publishes an instruction for the same delivery provider (or default, if the same one doesn't support the new target chain)
     * to relay a payload to the address `targetAddress` on chain `targetChain` 
     * with gas limit `gasLimit` and with `msg.value` equal to `receiverValue`
     * 
     * The following equation must be satisfied (sum_f indicates summing over all forwards requested in `receiveWormholeMessages`):
     * (refund amount from current execution of receiveWormholeMessages) + sum_f [msg.value_f]
     * >= sum_f [quoteEVMDeliveryPrice(targetChain_f, receiverValue_f, gasLimit_f)]
     * 
     * The difference between the two sides of the above inequality will be added to `paymentForExtraReceiverValue` of the first forward requested
     * 
     * Any refunds (from leftover gas) from this forward will be paid to the same refundChain and refundAddress specified for the current delivery.
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     */
    function forwardPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    ) external payable;

    /**
     * @notice Performs the same function as a `send`, except:
     * 1)  Can only be used during a delivery (i.e. in execution of `receiveWormholeMessages`)
     * 2)  Is paid for (along with any other calls to forward) by (any msg.value passed in) + (refund leftover from current delivery)
     * 3)  Only executes after `receiveWormholeMessages` is completed (and thus does not return a sequence number)
     * 
     * The refund from the delivery currently in progress will not be sent to the user; it will instead
     * be paid to the delivery provider to perform the instruction specified here
     * 
     * Publishes an instruction for the same delivery provider (or default, if the same one doesn't support the new target chain)
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain` 
     * with gas limit `gasLimit` and with `msg.value` equal to `receiverValue`
     * 
     * The following equation must be satisfied (sum_f indicates summing over all forwards requested in `receiveWormholeMessages`):
     * (refund amount from current execution of receiveWormholeMessages) + sum_f [msg.value_f]
     * >= sum_f [quoteEVMDeliveryPrice(targetChain_f, receiverValue_f, gasLimit_f)]
     * 
     * The difference between the two sides of the above inequality will be added to `paymentForExtraReceiverValue` of the first forward requested
     * 
     * Any refunds (from leftover gas) from this forward will be paid to the same refundChain and refundAddress specified for the current delivery.
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. 
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     */
    function forwardVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable;

    /**
     * @notice Performs the same function as a `send`, except:
     * 1)  Can only be used during a delivery (i.e. in execution of `receiveWormholeMessages`)
     * 2)  Is paid for (along with any other calls to forward) by (any msg.value passed in) + (refund leftover from current delivery)
     * 3)  Only executes after `receiveWormholeMessages` is completed (and thus does not return a sequence number)
     * 
     * The refund from the delivery currently in progress will not be sent to the user; it will instead
     * be paid to the delivery provider to perform the instruction specified here
     * 
     * Publishes an instruction for the delivery provider at `deliveryProviderAddress` 
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain` 
     * with gas limit `gasLimit` and with `msg.value` equal to 
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     * 
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     * 
     * The following equation must be satisfied (sum_f indicates summing over all forwards requested in `receiveWormholeMessages`):
     * (refund amount from current execution of receiveWormholeMessages) + sum_f [msg.value_f]
     * >= sum_f [quoteEVMDeliveryPrice(targetChain_f, receiverValue_f, gasLimit_f, deliveryProviderAddress_f) + paymentForExtraReceiverValue_f]
     * 
     * The difference between the two sides of the above inequality will be added to `paymentForExtraReceiverValue` of the first forward requested
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue 
     *        (in addition to the `receiverValue` specified)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the  
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see 
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     */
    function forwardToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable;

    /**
     * @notice Performs the same function as a `send`, except:
     * 1)  Can only be used during a delivery (i.e. in execution of `receiveWormholeMessages`)
     * 2)  Is paid for (along with any other calls to forward) by (any msg.value passed in) + (refund leftover from current delivery)
     * 3)  Only executes after `receiveWormholeMessages` is completed (and thus does not return a sequence number)
     * 
     * The refund from the delivery currently in progress will not be sent to the user; it will instead
     * be paid to the delivery provider to perform the instruction specified here
     * 
     * Publishes an instruction for the delivery provider at `deliveryProviderAddress` 
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain` 
     * with `msg.value` equal to 
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     * 
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     * 
     * The following equation must be satisfied (sum_f indicates summing over all forwards requested in `receiveWormholeMessages`):
     * (refund amount from current execution of receiveWormholeMessages) + sum_f [msg.value_f]
     * >= sum_f [quoteDeliveryPrice(targetChain_f, receiverValue_f, encodedExecutionParameters_f, deliveryProviderAddress_f) + paymentForExtraReceiverValue_f]
     * 
     * The difference between the two sides of the above inequality will be added to `paymentForExtraReceiverValue` of the first forward requested
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue 
     *        (in addition to the `receiverValue` specified)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see 
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     */
    function forward(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable;

    /**
     * @notice Requests a previously published delivery instruction to be redelivered 
     * (e.g. with a different delivery provider)
     *
     * This function must be called with `msg.value` equal to 
     * quoteEVMDeliveryPrice(targetChain, newReceiverValue, newGasLimit, newDeliveryProviderAddress)
     * 
     *  @notice *** This will only be able to succeed if the following is true **
     *         - newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     * 
     * @param deliveryVaaKey VaaKey identifying the wormhole message containing the 
     *        previously published delivery instructions
     * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
     * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param newGasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the  
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider, to the refund chain and address specified in the original request
     * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return sequence sequence number of published VAA containing redelivery instructions
     *
     * @notice *** This will only be able to succeed if the following is true **
     *         - newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function resendToEvm(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        uint256 newGasLimit,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Requests a previously published delivery instruction to be redelivered 
     * 
     *
     * This function must be called with `msg.value` equal to 
     * quoteDeliveryPrice(targetChain, newReceiverValue, newEncodedExecutionParameters, newDeliveryProviderAddress)
     * 
     * @param deliveryVaaKey VaaKey identifying the wormhole message containing the 
     *        previously published delivery instructions
     * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
     * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param newEncodedExecutionParameters new encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return sequence sequence number of published VAA containing redelivery instructions
     * 
     *  @notice *** This will only be able to succeed if the following is true **
     *         - (For EVM_V1) newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - (For EVM_V1) newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function resend(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        bytes memory newEncodedExecutionParameters,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using the default delivery provider
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. 
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return targetChainRefundPerGasUnused amount of target chain currency that will be refunded per unit of gas unused, 
     *         if a refundAddress is specified
     */
    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        uint256 gasLimit
    ) external view returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused);

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using delivery provider `deliveryProviderAddress`
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. 
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return targetChainRefundPerGasUnused amount of target chain currency that will be refunded per unit of gas unused, 
     *         if a refundAddress is specified
     */
    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        uint256 gasLimit,
        address deliveryProviderAddress
    ) external view returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused);

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using delivery provider `deliveryProviderAddress`
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return encodedExecutionInfo encoded information on how the delivery will be executed
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` and `targetChainRefundPerGasUnused`
     *             (which is the amount of target chain currency that will be refunded per unit of gas unused, 
     *              if a refundAddress is specified)
     */
    function quoteDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        bytes memory encodedExecutionParameters,
        address deliveryProviderAddress
    ) external view returns (uint256 nativePriceQuote, bytes memory encodedExecutionInfo);

    /**
     * @notice Returns the (extra) amount of target chain currency that `targetAddress`
     * will be called with, if the `paymentForExtraReceiverValue` field is set to `currentChainAmount`
     * 
     * @param targetChain in Wormhole Chain ID format
     * @param currentChainAmount The value that `paymentForExtraReceiverValue` will be set to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return targetChainAmount The amount such that if `targetAddress` will be called with `msg.value` equal to
     *         receiverValue + targetChainAmount
     */
    function quoteNativeForChain(
        uint16 targetChain,
        uint256 currentChainAmount,
        address deliveryProviderAddress
    ) external view returns (uint256 targetChainAmount);

    /**
     * @notice Returns the address of the current default delivery provider
     * @return deliveryProvider The address of (the default delivery provider)'s contract on this source
     *   chain. This must be a contract that implements IDeliveryProvider.
     */
    function getDefaultDeliveryProvider() external view returns (address deliveryProvider);
}

/**
 * @title IWormholeRelayerDelivery
 * @notice The interface to execute deliveries. Only relevant for Delivery Providers 
 */
interface IWormholeRelayerDelivery is IWormholeRelayerBase {
    enum DeliveryStatus {
        SUCCESS,
        RECEIVER_FAILURE,
        FORWARD_REQUEST_FAILURE,
        FORWARD_REQUEST_SUCCESS
    }

    enum RefundStatus {
        REFUND_SENT,
        REFUND_FAIL,
        CROSS_CHAIN_REFUND_SENT,
        CROSS_CHAIN_REFUND_FAIL_PROVIDER_NOT_SUPPORTED,
        CROSS_CHAIN_REFUND_FAIL_NOT_ENOUGH
    }

    /**
     * @custom:member recipientContract - The target contract address
     * @custom:member sourceChain - The chain which this delivery was requested from (in wormhole
     *     ChainID format)
     * @custom:member sequence - The wormhole sequence number of the delivery VAA on the source chain
     *     corresponding to this delivery request
     * @custom:member deliveryVaaHash - The hash of the delivery VAA corresponding to this delivery
     *     request
     * @custom:member gasUsed - The amount of gas that was used to call your target contract 
     * @custom:member status:
     *   - RECEIVER_FAILURE, if the target contract reverts
     *   - SUCCESS, if the target contract doesn't revert and no forwards were requested
     *   - FORWARD_REQUEST_FAILURE, if the target contract doesn't revert, forwards were requested,
     *       but provided/leftover funds were not sufficient to cover them all
     *   - FORWARD_REQUEST_SUCCESS, if the target contract doesn't revert and all forwards are covered
     * @custom:member additionalStatusInfo:
     *   - If status is SUCCESS or FORWARD_REQUEST_SUCCESS, then this is empty.
     *   - If status is RECEIVER_FAILURE, this is `RETURNDATA_TRUNCATION_THRESHOLD` bytes of the
     *       return data (i.e. potentially truncated revert reason information).
     *   - If status is FORWARD_REQUEST_FAILURE, this is also the revert data - the reason the forward failed.
     *     This will be either an encoded Cancelled, DeliveryProviderReverted, or DeliveryProviderPaymentFailed error
     * @custom:member refundStatus - Result of the refund. REFUND_SUCCESS or REFUND_FAIL are for
     *     refunds where targetChain=refundChain; the others are for targetChain!=refundChain,
     *     where a cross chain refund is necessary
     * @custom:member overridesInfo:
     *   - If not an override: empty bytes array
     *   - Otherwise: An encoded `DeliveryOverride`
     */
    event Delivery(
        address indexed recipientContract,
        uint16 indexed sourceChain,
        uint64 indexed sequence,
        bytes32 deliveryVaaHash,
        DeliveryStatus status,
        uint256 gasUsed,
        RefundStatus refundStatus,
        bytes additionalStatusInfo,
        bytes overridesInfo
    );

    /**
     * @notice The delivery provider calls `deliver` to relay messages as described by one delivery instruction
     * 
     * The delivery provider must pass in the specified (by VaaKeys[]) signed wormhole messages (VAAs) from the source chain
     * as well as the signed wormhole message with the delivery instructions (the delivery VAA)
     *
     * The messages will be relayed to the target address (with the specified gas limit and receiver value) iff the following checks are met:
     * - the delivery VAA has a valid signature
     * - the delivery VAA's emitter is one of these WormholeRelayer contracts
     * - the delivery provider passed in at least enough of this chain's currency as msg.value (enough meaning the maximum possible refund)     
     * - the instruction's target chain is this chain
     * - the relayed signed VAAs match the descriptions in container.messages (the VAA hashes match, or the emitter address, sequence number pair matches, depending on the description given)
     *
     * @param encodedVMs - An array of signed wormhole messages (all from the same source chain
     *     transaction)
     * @param encodedDeliveryVAA - Signed wormhole message from the source chain's WormholeRelayer
     *     contract with payload being the encoded delivery instruction container
     * @param relayerRefundAddress - The address to which any refunds to the delivery provider
     *     should be sent
     * @param deliveryOverrides - Optional overrides field which must be either an empty bytes array or
     *     an encoded DeliveryOverride struct
     */
    function deliver(
        bytes[] memory encodedVMs,
        bytes memory encodedDeliveryVAA,
        address payable relayerRefundAddress,
        bytes memory deliveryOverrides
    ) external payable;
}

interface IWormholeRelayer is IWormholeRelayerDelivery, IWormholeRelayerSend {}

/*
 *  Errors thrown by IWormholeRelayer contract
 */

// Bound chosen by the following formula: `memoryWord * 4 + selectorSize`.
// This means that an error identifier plus four fixed size arguments should be available to developers.
// In the case of a `require` revert with error message, this should provide 2 memory word's worth of data.
uint256 constant RETURNDATA_TRUNCATION_THRESHOLD = 132;

//When msg.value was not equal to `delivery provider's quoted delivery price` + `paymentForExtraReceiverValue`
error InvalidMsgValue(uint256 msgValue, uint256 totalFee);

error RequestedGasLimitTooLow();

error DeliveryProviderDoesNotSupportTargetChain(address relayer, uint16 chainId);
error DeliveryProviderCannotReceivePayment();

//When calling `forward()` on the WormholeRelayer if no delivery is in progress
error NoDeliveryInProgress();
//When calling `delivery()` a second time even though a delivery is already in progress
error ReentrantDelivery(address msgSender, address lockedBy);
//When any other contract but the delivery target calls `forward()` on the WormholeRelayer while a
//  delivery is in progress
error ForwardRequestFromWrongAddress(address msgSender, address deliveryTarget);

error InvalidPayloadId(uint8 parsed, uint8 expected);
error InvalidPayloadLength(uint256 received, uint256 expected);
error InvalidVaaKeyType(uint8 parsed);

error InvalidDeliveryVaa(string reason);
//When the delivery VAA (signed wormhole message with delivery instructions) was not emitted by the
//  registered WormholeRelayer contract
error InvalidEmitter(bytes32 emitter, bytes32 registered, uint16 chainId);
error VaaKeysLengthDoesNotMatchVaasLength(uint256 keys, uint256 vaas);
error VaaKeysDoNotMatchVaas(uint8 index);
//When someone tries to call an external function of the WormholeRelayer that is only intended to be
//  called by the WormholeRelayer itself (to allow retroactive reverts for atomicity)
error RequesterNotWormholeRelayer();

//When trying to relay a `DeliveryInstruction` to any other chain but the one it was specified for
error TargetChainIsNotThisChain(uint16 targetChain);
error ForwardNotSufficientlyFunded(uint256 amountOfFunds, uint256 amountOfFundsNeeded);
//When a `DeliveryOverride` contains a gas limit that's less than the original
error InvalidOverrideGasLimit();
//When a `DeliveryOverride` contains a receiver value that's less than the original
error InvalidOverrideReceiverValue();
//When a `DeliveryOverride` contains a 'refund per unit of gas unused' that's less than the original
error InvalidOverrideRefundPerGasUnused();

//When the delivery provider doesn't pass in sufficient funds (i.e. msg.value does not cover the
// maximum possible refund to the user)
error InsufficientRelayerFunds(uint256 msgValue, uint256 minimum);

//When a bytes32 field can't be converted into a 20 byte EVM address, because the 12 padding bytes
//  are non-zero (duplicated from Utils.sol)
error NotAnEvmAddress(bytes32);

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import '../interfaces/IAdaptor.sol';
import '../interfaces/ICrossChainPool.sol';

abstract contract Adaptor is
    IAdaptor,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    ICrossChainPool public crossChainPool;

    uint256 private _used;

    /// @notice whether the token is valid
    /// @dev wormhole chainId => token address => bool
    /// Instead of a security feature, this is a sanity check in case user uses an invalid token address
    mapping(uint256 => mapping(address => bool)) public validToken;

    uint256[50] private __gap;

    event BridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 sequence
    );
    event LogError(uint256 emitterChainId, address emitterAddress, bytes data);

    error ADAPTOR__CONTRACT_NOT_TRUSTED();
    error ADAPTOR__INVALID_TOKEN();

    function __Adaptor_init(ICrossChainPool _crossChainPool) internal virtual onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        crossChainPool = _crossChainPool;
    }

    /**
     * @dev Nonce must be non-zero, otherwise wormhole will revert the message
     */
    function bridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 deliveryGasLimit
    ) external payable override returns (uint256 sequence) {
        require(msg.sender == address(crossChainPool), 'Adaptor: not authorized');
        _isValidToken(toChain, toToken);

        sequence = _bridgeCreditAndSwapForTokens(
            toToken,
            toChain,
            fromAmount,
            minimumToAmount,
            receiver,
            receiverValue,
            deliveryGasLimit
        );

        // (emitterChainID, emitterAddress, sequence) is used to retrive the generated VAA from the Guardian Network and for tracking
        emit BridgeCreditAndSwapForTokens(toToken, toChain, fromAmount, minimumToAmount, receiver, sequence);
    }

    /**
     * Internal functions
     */

    function _bridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 deliveryGasLimit
    ) internal virtual returns (uint256 sequence);

    function _isValidToken(uint256 chainId, address tokenAddr) internal view {
        if (!validToken[chainId][tokenAddr]) revert ADAPTOR__INVALID_TOKEN();
    }

    function _swapCreditForTokens(
        uint256 emitterChainId,
        address emitterAddress,
        address toToken,
        uint256 creditAmount,
        uint256 minimumToAmount,
        address receiver
    ) internal returns (bool success, uint256 amount) {
        try crossChainPool.completeSwapCreditForTokens(toToken, creditAmount, minimumToAmount, receiver) returns (
            uint256 actualToAmount,
            uint256
        ) {
            return (true, actualToAmount);
        } catch (bytes memory reason) {
            // TODO: Investigate how can we decode error message from logs
            emit LogError(emitterChainId, emitterAddress, reason);
            crossChainPool.mintCredit(creditAmount, receiver);

            return (false, creditAmount);
        }
    }

    function _encode(
        address toToken,
        uint256 creditAmount,
        uint256 minimumToAmount,
        address receiver
    ) internal pure returns (bytes memory) {
        require(toToken != address(0), 'toToken cannot be zero');
        require(receiver != address(0), 'receiver cannot be zero');
        require(creditAmount != uint256(0), 'creditAmount cannot be zero');
        require(toToken != receiver, 'toToken cannot be receiver');

        return abi.encode(toToken, creditAmount, minimumToAmount, receiver);
    }

    function _decode(
        bytes memory encoded
    ) internal pure returns (address toToken, uint256 creditAmount, uint256 minimumToAmount, address receiver) {
        require(encoded.length == 128, 'byte length must be 128');

        (toToken, creditAmount, minimumToAmount, receiver) = abi.decode(encoded, (address, uint256, uint256, address));

        require(toToken != address(0), 'toToken cannot be zero');
        require(receiver != address(0), 'receiver cannot be zero');

        require(creditAmount != uint256(0), 'creditAmount cannot be zero');
        require(toToken != receiver, 'toToken cannot be receiver');
    }

    /**
     * Permisioneed functions
     */

    function approveToken(uint256 wormholeChainId, address tokenAddr) external onlyOwner {
        require(!validToken[wormholeChainId][tokenAddr]);
        validToken[wormholeChainId][tokenAddr] = true;
    }

    function revokeToken(uint256 wormholeChainId, address tokenAddr) external onlyOwner {
        require(validToken[wormholeChainId][tokenAddr]);
        validToken[wormholeChainId][tokenAddr] = false;
    }
}

// SPDX-License-Identifier: GPL-3.0

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.5;

library DSMath {
    uint256 public constant WAD = 10 ** 18;

    // Babylonian Method
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * WAD) + (y / 2)) / y;
    }

    // Convert x to WAD (18 decimals) from d decimals.
    function toWad(uint256 x, uint8 d) internal pure returns (uint256) {
        if (d < 18) {
            return x * 10 ** (18 - d);
        } else if (d > 18) {
            return (x / (10 ** (d - 18)));
        }
        return x;
    }

    // Convert x from WAD (18 decimals) to d decimals.
    function fromWad(uint256 x, uint8 d) internal pure returns (uint256) {
        if (d < 18) {
            return (x / (10 ** (18 - d)));
        } else if (d > 18) {
            return x * 10 ** (d - 18);
        }
        return x;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.5;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    int256 public constant WAD = 10 ** 18;

    //rounds to zero if x*y < WAD / 2
    function wdiv(int256 x, int256 y) internal pure returns (int256) {
        return ((x * WAD) + (y / 2)) / y;
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(int256 x, int256 y) internal pure returns (int256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    // Babylonian Method (typecast as int)
    function sqrt(int256 y) internal pure returns (int256 z) {
        if (y > 3) {
            z = y;
            int256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Babylonian Method with initial guess (typecast as int)
    function sqrt(int256 y, int256 guess) internal pure returns (int256 z) {
        if (y > 3) {
            if (guess > 0 && guess <= y) {
                z = guess;
            } else if (guess < 0 && -guess <= y) {
                z = -guess;
            } else {
                z = y;
            }
            int256 x = (y / z + z) / 2;
            while (x != z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Convert x to WAD (18 decimals) from d decimals.
    function toWad(int256 x, uint8 d) internal pure returns (int256) {
        if (d < 18) {
            return x * int256(10 ** (18 - d));
        } else if (d > 18) {
            return (x / int256(10 ** (d - 18)));
        }
        return x;
    }

    // Convert x from WAD (18 decimals) to d decimals.
    function fromWad(int256 x, uint8 d) internal pure returns (int256) {
        if (d < 18) {
            return (x / int256(10 ** (18 - d)));
        } else if (d > 18) {
            return x * int256(10 ** (d - 18));
        }
        return x;
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, 'value must be positive');
        return uint256(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), 'value must be positive');
        return int256(value);
    }

    function abs(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            return uint256(-value);
        } else {
            return uint256(value);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '../interfaces/IAsset.sol';
import '../libraries/DSMath.sol';
import '../libraries/SignedSafeMath.sol';

/**
 * @title CoreV3
 * @notice Handles math operations of Wombat protocol. Assume all params are signed integer with 18 decimals
 * @dev Uses OpenZeppelin's SignedSafeMath and DSMath's WAD for calculations.
 * Change log:
 * - Move view functinos (quotes, high cov ratio fee) from the Pool contract to this contract
 * - Add quote functions for cross chain swaps
 */
library CoreV3 {
    using DSMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeMath for uint256;

    int256 internal constant WAD_I = 10 ** 18;
    uint256 internal constant WAD = 10 ** 18;

    error CORE_UNDERFLOW();
    error CORE_INVALID_VALUE();
    error CORE_INVALID_HIGH_COV_RATIO_FEE();
    error CORE_ZERO_LIQUIDITY();
    error CORE_CASH_NOT_ENOUGH();
    error CORE_COV_RATIO_LIMIT_EXCEEDED();

    /*
     * Public view functions
     */

    /**
     * This function calculate the exactly amount of liquidity of the deposit. Assumes r* = 1
     */
    function quoteDepositLiquidity(
        IAsset asset,
        uint256 amount,
        uint256 ampFactor,
        int256 _equilCovRatio
    ) external view returns (uint256 lpTokenToMint, uint256 liabilityToMint) {
        liabilityToMint = _equilCovRatio == WAD_I
            ? exactDepositLiquidityInEquilImpl(
                amount.toInt256(),
                int256(uint256(asset.cash())),
                int256(uint256(asset.liability())),
                ampFactor.toInt256()
            ).toUint256()
            : exactDepositLiquidityImpl(
                amount.toInt256(),
                int256(uint256(asset.cash())),
                int256(uint256(asset.liability())),
                ampFactor.toInt256(),
                _equilCovRatio
            ).toUint256();

        // Calculate amount of LP to mint : ( deposit + reward ) * TotalAssetSupply / Liability
        uint256 liability = asset.liability();
        lpTokenToMint = (liability == 0 ? liabilityToMint : (liabilityToMint * asset.totalSupply()) / liability);
    }

    /**
     * @notice Calculates fee and liability to burn in case of withdrawal
     * @param asset The asset willing to be withdrawn
     * @param liquidity The liquidity willing to be withdrawn
     * @param _equilCovRatio global equilibrium coverage ratio
     * @param withdrawalHaircutRate withdraw haircut rate
     * @return amount Total amount to be withdrawn from Pool
     * @return liabilityToBurn Total liability to be burned by Pool
     * @return withdrawalHaircut Total withdrawal haircut
     */
    function quoteWithdrawAmount(
        IAsset asset,
        uint256 liquidity,
        uint256 ampFactor,
        int256 _equilCovRatio,
        uint256 withdrawalHaircutRate
    ) public view returns (uint256 amount, uint256 liabilityToBurn, uint256 withdrawalHaircut) {
        liabilityToBurn = (asset.liability() * liquidity) / asset.totalSupply();
        if (liabilityToBurn == 0) revert CORE_ZERO_LIQUIDITY();

        amount = _equilCovRatio == WAD_I
            ? withdrawalAmountInEquilImpl(
                -liabilityToBurn.toInt256(),
                int256(uint256(asset.cash())),
                int256(uint256(asset.liability())),
                ampFactor.toInt256()
            ).toUint256()
            : withdrawalAmountImpl(
                -liabilityToBurn.toInt256(),
                int256(uint256(asset.cash())),
                int256(uint256(asset.liability())),
                ampFactor.toInt256(),
                _equilCovRatio
            ).toUint256();

        // charge withdrawal haircut
        if (withdrawalHaircutRate > 0) {
            withdrawalHaircut = amount.wmul(withdrawalHaircutRate);
            amount -= withdrawalHaircut;
        }
    }

    function quoteWithdrawAmountFromOtherAsset(
        IAsset fromAsset,
        IAsset toAsset,
        uint256 liquidity,
        uint256 ampFactor,
        uint256 scaleFactor,
        uint256 haircutRate,
        uint256 startCovRatio,
        uint256 endCovRatio,
        int256 _equilCovRatio,
        uint256 withdrawalHaircutRate
    ) external view returns (uint256 finalAmount, uint256 withdrewAmount) {
        // quote withdraw
        uint256 withdrawalHaircut;
        uint256 liabilityToBurn;
        (withdrewAmount, liabilityToBurn, withdrawalHaircut) = quoteWithdrawAmount(
            fromAsset,
            liquidity,
            ampFactor,
            _equilCovRatio,
            withdrawalHaircutRate
        );

        // quote swap
        uint256 fromCash = fromAsset.cash() - withdrewAmount - withdrawalHaircut;
        uint256 fromLiability = fromAsset.liability() - liabilityToBurn;

        if (scaleFactor != WAD) {
            // apply scale factor on from-amounts
            fromCash = (fromCash * scaleFactor) / 1e18;
            fromLiability = (fromLiability * scaleFactor) / 1e18;
            withdrewAmount = (withdrewAmount * scaleFactor) / 1e18;
        }

        uint256 idealToAmount = swapQuoteFunc(
            fromCash.toInt256(),
            int256(uint256(toAsset.cash())),
            fromLiability.toInt256(),
            int256(uint256(toAsset.liability())),
            withdrewAmount.toInt256(),
            ampFactor.toInt256()
        );

        // remove haircut
        finalAmount = idealToAmount - idealToAmount.wmul(haircutRate);

        if (startCovRatio > 0 || endCovRatio > 0) {
            // charge high cov ratio fee
            uint256 fee = highCovRatioFee(
                fromCash,
                fromLiability,
                withdrewAmount,
                finalAmount,
                startCovRatio,
                endCovRatio
            );

            finalAmount -= fee;
        }
    }

    /**
     * @notice Quotes the actual amount user would receive in a swap, taking in account slippage and haircut
     * @param fromAsset The initial asset
     * @param toAsset The asset wanted by user
     * @param fromAmount The amount to quote
     * @return actualToAmount The actual amount user would receive
     * @return haircut The haircut that will be applied
     */
    function quoteSwap(
        IAsset fromAsset,
        IAsset toAsset,
        int256 fromAmount,
        uint256 ampFactor,
        uint256 scaleFactor,
        uint256 haircutRate
    ) external view returns (uint256 actualToAmount, uint256 haircut) {
        // exact output swap quote should count haircut before swap
        if (fromAmount < 0) {
            fromAmount = fromAmount.wdiv(WAD_I - int256(haircutRate));
        }

        uint256 fromCash = uint256(fromAsset.cash());
        uint256 fromLiability = uint256(fromAsset.liability());
        uint256 toCash = uint256(toAsset.cash());

        if (scaleFactor != WAD) {
            // apply scale factor on from-amounts
            fromCash = (fromCash * scaleFactor) / 1e18;
            fromLiability = (fromLiability * scaleFactor) / 1e18;
            fromAmount = (fromAmount * scaleFactor.toInt256()) / 1e18;
        }

        uint256 idealToAmount = swapQuoteFunc(
            fromCash.toInt256(),
            toCash.toInt256(),
            fromLiability.toInt256(),
            int256(uint256(toAsset.liability())),
            fromAmount,
            ampFactor.toInt256()
        );
        if ((fromAmount > 0 && toCash < idealToAmount) || (fromAmount < 0 && fromAsset.cash() < uint256(-fromAmount))) {
            revert CORE_CASH_NOT_ENOUGH();
        }

        if (fromAmount > 0) {
            // normal quote
            haircut = idealToAmount.wmul(haircutRate);
            actualToAmount = idealToAmount - haircut;
        } else {
            // exact output swap quote count haircut in the fromAmount
            actualToAmount = idealToAmount;
            haircut = uint256(-fromAmount).wmul(haircutRate);
        }
    }

    /// @dev reverse quote is not supported
    /// haircut is calculated in the fromToken when swapping tokens for credit
    function quoteSwapTokensForCredit(
        IAsset fromAsset,
        uint256 fromAmount,
        uint256 ampFactor,
        uint256 scaleFactor,
        uint256 haircutRate,
        uint256 startCovRatio,
        uint256 endCovRatio
    ) external view returns (uint256 creditAmount, uint256 fromTokenFee) {
        if (fromAmount == 0) return (0, 0);
        // haircut
        fromTokenFee = fromAmount.wmul(haircutRate);

        // high coverage ratio fee

        uint256 fromCash = fromAsset.cash();
        uint256 fromLiability = fromAsset.liability();
        fromTokenFee += highCovRatioFee(
            fromCash,
            fromLiability,
            fromAmount,
            fromAmount - fromTokenFee, // calculate haircut in the fromAmount (exclude haircut)
            startCovRatio,
            endCovRatio
        );

        fromAmount -= fromTokenFee;

        if (scaleFactor != WAD) {
            // apply scale factor on from-amounts
            fromCash = (fromCash * scaleFactor) / 1e18;
            fromLiability = (fromLiability * scaleFactor) / 1e18;
            fromAmount = (fromAmount * scaleFactor) / 1e18;
        }

        creditAmount = swapToCreditQuote(
            fromCash.toInt256(),
            fromLiability.toInt256(),
            fromAmount.toInt256(),
            ampFactor.toInt256()
        );
    }

    /// @dev reverse quote is not supported
    function quoteSwapCreditForTokens(
        uint256 fromAmount,
        IAsset toAsset,
        uint256 ampFactor,
        uint256 scaleFactor,
        uint256 haircutRate
    ) external view returns (uint256 actualToAmount, uint256 toTokenFee) {
        if (fromAmount == 0) return (0, 0);
        uint256 toCash = toAsset.cash();
        uint256 toLiability = toAsset.liability();

        if (scaleFactor != WAD) {
            // apply scale factor on from-amounts
            fromAmount = (fromAmount * scaleFactor) / 1e18;
        }

        uint256 idealToAmount = swapFromCreditQuote(
            toCash.toInt256(),
            toLiability.toInt256(),
            fromAmount.toInt256(),
            ampFactor.toInt256()
        );
        if (fromAmount > 0 && toCash < idealToAmount) {
            revert CORE_CASH_NOT_ENOUGH();
        }

        // normal quote
        toTokenFee = idealToAmount.wmul(haircutRate);
        actualToAmount = idealToAmount - toTokenFee;
    }

    function equilCovRatio(int256 D, int256 SL, int256 A) public pure returns (int256 er) {
        int256 b = -(D.wdiv(SL));
        er = _solveQuad(b, A);
    }

    /*
     * Pure calculating functions
     */

    /**
     * @notice Core Wombat stableswap equation
     * @dev This function always returns >= 0
     * @param Ax asset of token x
     * @param Ay asset of token y
     * @param Lx liability of token x
     * @param Ly liability of token y
     * @param Dx delta x, i.e. token x amount inputted
     * @param A amplification factor
     * @return quote The quote for amount of token y swapped for token x amount inputted
     */
    function swapQuoteFunc(
        int256 Ax,
        int256 Ay,
        int256 Lx,
        int256 Ly,
        int256 Dx,
        int256 A
    ) public pure returns (uint256 quote) {
        if (Lx == 0 || Ly == 0) {
            // in case div of 0
            revert CORE_UNDERFLOW();
        }
        int256 D = Ax + Ay - A.wmul((Lx * Lx) / Ax + (Ly * Ly) / Ay); // flattened _invariantFunc
        int256 rx_ = (Ax + Dx).wdiv(Lx);
        int256 b = (Lx * (rx_ - A.wdiv(rx_))) / Ly - D.wdiv(Ly); // flattened _coefficientFunc
        int256 ry_ = _solveQuad(b, A);
        int256 Dy = Ly.wmul(ry_) - Ay;
        return Dy.abs();
    }

    /**
     * @dev Calculate the withdrawal amount for any r*
     */
    function withdrawalAmountImpl(
        int256 delta_i,
        int256 A_i,
        int256 L_i,
        int256 A,
        int256 _equilCovRatio
    ) public pure returns (int256 amount) {
        int256 L_i_ = L_i + delta_i;
        int256 r_i = A_i.wdiv(L_i);
        int256 delta_D = delta_i.wmul(_equilCovRatio) - (delta_i * A) / _equilCovRatio; // The only line that is different
        int256 b = -(L_i.wmul(r_i - A.wdiv(r_i)) + delta_D);
        int256 c = A.wmul(L_i_.wmul(L_i_));
        int256 A_i_ = _solveQuad(b, c);
        amount = A_i - A_i_;
    }

    /**
     * @dev should be used only when r* = 1
     */
    function withdrawalAmountInEquilImpl(
        int256 delta_i,
        int256 A_i,
        int256 L_i,
        int256 A
    ) public pure returns (int256 amount) {
        int256 L_i_ = L_i + delta_i;
        int256 r_i = A_i.wdiv(L_i);

        int256 rho = L_i.wmul(r_i - A.wdiv(r_i));
        int256 beta = (rho + delta_i.wmul(WAD_I - A)) / 2;
        int256 A_i_ = beta + (beta * beta + A.wmul(L_i_ * L_i_)).sqrt(beta);
        // equilvalent to:
        // int256 delta_D = delta_i.wmul(WAD_I - A);
        // int256 b = -(L_i.wmul(r_i - A.wdiv(r_i)) + delta_D);
        // int256 c = A.wmul(L_i_.wmul(L_i_));
        // int256 A_i_ = _solveQuad(b, c);

        amount = A_i - A_i_;
    }

    /**
     * @notice return the deposit reward in token amount when target liquidity (LP amount) is known
     */
    function exactDepositLiquidityImpl(
        int256 D_i,
        int256 A_i,
        int256 L_i,
        int256 A,
        int256 _equilCovRatio
    ) public pure returns (int256 liquidity) {
        if (L_i == 0) {
            // if this is a deposit, there is no reward/fee
            // if this is a withdrawal, it should have been reverted
            return D_i;
        }
        if (A_i + D_i < 0) {
            // impossible
            revert CORE_UNDERFLOW();
        }

        int256 r_i = A_i.wdiv(L_i);
        int256 k = D_i + A_i;
        int256 b = k.wmul(_equilCovRatio) - (k * A) / _equilCovRatio + 2 * A.wmul(L_i); // The only line that is different
        int256 c = k.wmul(A_i - (A * L_i) / r_i) - k.wmul(k) + A.wmul(L_i).wmul(L_i);
        int256 l = b * b - 4 * A * c;
        return (-b + l.sqrt(b)).wdiv(A) / 2;
    }

    /**
     * @notice return the deposit reward in token amount when target liquidity (LP amount) is known
     */
    function exactDepositLiquidityInEquilImpl(
        int256 D_i,
        int256 A_i,
        int256 L_i,
        int256 A
    ) public pure returns (int256 liquidity) {
        if (L_i == 0) {
            // if this is a deposit, there is no reward/fee
            // if this is a withdrawal, it should have been reverted
            return D_i;
        }
        if (A_i + D_i < 0) {
            // impossible
            revert CORE_UNDERFLOW();
        }

        int256 r_i = A_i.wdiv(L_i);
        int256 k = D_i + A_i;
        int256 b = k.wmul(WAD_I - A) + 2 * A.wmul(L_i);
        int256 c = k.wmul(A_i - (A * L_i) / r_i) - k.wmul(k) + A.wmul(L_i).wmul(L_i);
        int256 l = b * b - 4 * A * c;
        return (-b + l.sqrt(b)).wdiv(A) / 2;
    }

    /**
     * @notice quote swapping from tokens for credit
     * @dev This function always returns >= 0
     */
    function swapToCreditQuote(int256 Ax, int256 Lx, int256 Dx, int256 A) public pure returns (uint256 quote) {
        int256 rx = Ax.wdiv(Lx);
        int256 rx_ = (Ax + Dx).wdiv(Lx);
        int256 x = rx_ - A.wdiv(rx_);
        int256 y = rx - A.wdiv(rx);

        // adjsut credit by 1 / (1 + A)
        return ((Lx * (x - y)) / (WAD_I + A)).abs();
    }

    /**
     * @notice quote swapping from credit for tokens
     * @dev This function always returns >= 0
     */
    function swapFromCreditQuote(
        int256 Ax,
        int256 Lx,
        int256 delta_credit,
        int256 A
    ) public pure returns (uint256 quote) {
        int256 rx = Ax.wdiv(Lx);
        // adjsut credit by 1 + A
        int256 b = (delta_credit * (WAD_I + A)) / Lx - rx + A.wdiv(rx); // flattened _coefficientFunc
        int256 rx_ = _solveQuad(b, A);
        int256 Dx = Ax - Lx.wmul(rx_);

        return Dx.abs();
    }

    function highCovRatioFee(
        uint256 fromAssetCash,
        uint256 fromAssetLiability,
        uint256 fromAmount,
        uint256 quotedToAmount,
        uint256 startCovRatio,
        uint256 endCovRatio
    ) public pure returns (uint256 fee) {
        uint256 finalFromAssetCovRatio = (fromAssetCash + fromAmount).wdiv(fromAssetLiability);

        if (finalFromAssetCovRatio > startCovRatio) {
            // charge high cov ratio fee
            uint256 feeRatio = _highCovRatioFee(
                fromAssetCash.wdiv(fromAssetLiability),
                finalFromAssetCovRatio,
                startCovRatio,
                endCovRatio
            );

            if (feeRatio > WAD) revert CORE_INVALID_HIGH_COV_RATIO_FEE();
            fee = feeRatio.wmul(quotedToAmount);
        }
    }

    /*
     * Internal functions
     */

    /**
     * @notice Solve quadratic equation
     * @dev This function always returns >= 0
     * @param b quadratic equation b coefficient
     * @param c quadratic equation c coefficient
     * @return x
     */
    function _solveQuad(int256 b, int256 c) internal pure returns (int256) {
        return (((b * b) + (c * 4 * WAD_I)).sqrt(b) - b) / 2;
    }

    /**
     * @notice Equation to get invariant constant between token x and token y
     * @dev This function always returns >= 0
     * @param Lx liability of token x
     * @param rx cov ratio of token x
     * @param Ly liability of token x
     * @param ry cov ratio of token y
     * @param A amplification factor
     * @return The invariant constant between token x and token y ("D")
     */
    function _invariantFunc(int256 Lx, int256 rx, int256 Ly, int256 ry, int256 A) internal pure returns (int256) {
        int256 a = Lx.wmul(rx) + Ly.wmul(ry);
        int256 b = A.wmul(Lx.wdiv(rx) + Ly.wdiv(ry));
        return a - b;
    }

    /**
     * @notice Equation to get quadratic equation b coefficient
     * @dev This function can return >= 0 or <= 0
     * @param Lx liability of token x
     * @param Ly liability of token y
     * @param rx_ new asset coverage ratio of token x
     * @param D invariant constant
     * @param A amplification factor
     * @return The quadratic equation b coefficient ("b")
     */
    function _coefficientFunc(int256 Lx, int256 Ly, int256 rx_, int256 D, int256 A) internal pure returns (int256) {
        return (Lx * (rx_ - A.wdiv(rx_))) / Ly - D.wdiv(Ly);
    }

    function _targetedCovRatio(
        int256 SL,
        int256 delta_i,
        int256 A_i,
        int256 L_i,
        int256 D,
        int256 A
    ) internal pure returns (int256 r_i_) {
        int256 r_i = A_i.wdiv(L_i);
        int256 er = equilCovRatio(D, SL, A);
        int256 er_ = _newEquilCovRatio(er, SL, delta_i);
        int256 D_ = _newInvariantFunc(er_, A, SL, delta_i);

        // Summation of k∈T\{i} is D - L_i.wmul(r_i - A.wdiv(r_i))
        int256 b_ = (D - A_i + (L_i * A) / r_i - D_).wdiv(L_i + delta_i);
        r_i_ = _solveQuad(b_, A);
    }

    function _newEquilCovRatio(int256 er, int256 SL, int256 delta_i) internal pure returns (int256 er_) {
        er_ = (delta_i + SL.wmul(er)).wdiv(delta_i + SL);
    }

    function _newInvariantFunc(int256 er_, int256 A, int256 SL, int256 delta_i) internal pure returns (int256 D_) {
        D_ = (SL + delta_i).wmul(er_ - A.wdiv(er_));
    }

    /**
     * @notice Calculate the high cov ratio fee in the to-asset in a swap.
     * @dev When cov ratio is in the range [startCovRatio, endCovRatio], the marginal cov ratio is
     * (r - startCovRatio) / (endCovRatio - startCovRatio). Here we approximate the high cov ratio cut
     * by calculating the "average" fee.
     * Note: `finalCovRatio` should be greater than `initCovRatio`
     */
    function _highCovRatioFee(
        uint256 initCovRatio,
        uint256 finalCovRatio,
        uint256 startCovRatio,
        uint256 endCovRatio
    ) internal pure returns (uint256 fee) {
        if (finalCovRatio > endCovRatio) {
            // invalid swap
            revert CORE_COV_RATIO_LIMIT_EXCEEDED();
        } else if (finalCovRatio <= startCovRatio || finalCovRatio <= initCovRatio) {
            return 0;
        }

        // 1. Calculate the area of fee(r) = (r - startCovRatio) / (endCovRatio - startCovRatio)
        // when r increase from initCovRatio to finalCovRatio
        // 2. Then multiply it by (endCovRatio - startCovRatio) / (finalCovRatio - initCovRatio)
        // to get the average fee over the range
        uint256 a = initCovRatio <= startCovRatio ? 0 : (initCovRatio - startCovRatio) * (initCovRatio - startCovRatio);
        uint256 b = (finalCovRatio - startCovRatio) * (finalCovRatio - startCovRatio);
        fee = ((b - a) / (finalCovRatio - initCovRatio) / 2).wdiv(endCovRatio - startCovRatio);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import './HighCovRatioFeePoolV3.sol';
import '../interfaces/IAdaptor.sol';
import '../interfaces/ICrossChainPool.sol';

/**
 * @title Mega Pool
 * @notice Mega Pool is able to handle cross-chain swaps in addition to ordinary swap within its own chain
 * @dev Refer to note of `swapTokensForTokensCrossChain` for procedure of a cross-chain swap
 * Note: All variables are 18 decimals, except from that of parameters of external functions and underlying tokens
 */
contract CrossChainPool is HighCovRatioFeePoolV3, ICrossChainPool {
    using DSMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;
    using SignedSafeMath for uint256;

    /**
     * Storage
     */

    IAdaptor public adaptor;
    bool public swapCreditForTokensEnabled;
    bool public swapTokensForCreditEnabled;

    uint128 public creditForTokensHaircut;
    uint128 public tokensForCreditHaircut;

    uint128 public totalCreditMinted;
    uint128 public totalCreditBurned;

    /// @notice the maximum allowed amount of net mint credit. `totalCreditMinted - totalCreditBurned` should be smaller than this value
    uint128 public maximumOutboundCredit; // Upper limit of net minted credit
    uint128 public maximumInboundCredit; // Upper limit of net burned credit

    mapping(address => uint256) public creditBalance;

    uint256[50] private __gap;

    /**
     * Errors
     */

    error WOMBAT_ZERO_CREDIT_AMOUNT();

    /**
     * Events
     */

    /**
     * @notice Event that is emitted when token is swapped into credit
     */
    event SwapTokensForCredit(
        address indexed sender,
        address indexed fromToken,
        uint256 fromAmount,
        uint256 fromTokenFee,
        uint256 creditAmount
    );

    /**
     * @notice Event that is emitted when credit is swapped into token
     */
    event SwapCreditForTokens(
        uint256 creditAmount,
        address indexed toToken,
        uint256 toAmount,
        uint256 toTokenFee,
        address indexed receiver
    );

    event MintCredit(address indexed receiver, uint256 creditAmount);

    /**
     * Errors
     */

    error POOL__CREDIT_NOT_ENOUGH();
    error POOL__REACH_MAXIMUM_MINTED_CREDIT();
    error POOL__REACH_MAXIMUM_BURNED_CREDIT();
    error POOL__SWAP_TOKENS_FOR_CREDIT_DISABLED();
    error POOL__SWAP_CREDIT_FOR_TOKENS_DISABLED();

    /**
     * External/public functions
     */

    /**
     * @dev refer to documentation in the interface
     */
    function swapTokensForTokensCrossChain(
        address fromToken,
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumCreditAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 deliveryGasLimit
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (uint256 creditAmount, uint256 fromTokenFee, uint256 sequence)
    {
        // Assumption: the adaptor should check `toChain` and `toToken`
        if (fromAmount == 0) revert WOMBAT_ZERO_AMOUNT();
        requireAssetNotPaused(fromToken);
        _checkAddress(receiver);

        IAsset fromAsset = _assetOf(fromToken);
        IERC20(fromToken).safeTransferFrom(msg.sender, address(fromAsset), fromAmount);

        (creditAmount, fromTokenFee) = _swapTokensForCredit(
            fromAsset,
            fromAmount.toWad(fromAsset.underlyingTokenDecimals()),
            minimumCreditAmount
        );
        if (creditAmount == 0) revert WOMBAT_ZERO_CREDIT_AMOUNT();

        fromTokenFee = fromTokenFee.fromWad(fromAsset.underlyingTokenDecimals());
        emit SwapTokensForCredit(msg.sender, fromToken, fromAmount, fromTokenFee, creditAmount);

        // Wormhole: computeBudget + applicationBudget + wormholeFee should equal the msg.value
        sequence = adaptor.bridgeCreditAndSwapForTokens{value: msg.value}(
            toToken,
            toChain,
            creditAmount,
            minimumToAmount,
            receiver,
            receiverValue,
            deliveryGasLimit
        );
    }

    /**
     * @dev refer to documentation in the interface
     */
    function swapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver
    ) external override nonReentrant whenNotPaused returns (uint256 actualToAmount, uint256 toTokenFee) {
        _beforeSwapCreditForTokens(fromAmount, receiver);
        (actualToAmount, toTokenFee) = _doSwapCreditForTokens(toToken, fromAmount, minimumToAmount, receiver);
    }

    /**
     * @dev refer to documentation in the interface
     */
    function swapCreditForTokensCrossChain(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 deliveryGasLimit
    ) external payable override nonReentrant whenNotPaused returns (uint256 trackingId) {
        _beforeSwapCreditForTokens(fromAmount, receiver);

        // Wormhole: computeBudget + applicationBudget + wormholeFee should equal the msg.value
        trackingId = adaptor.bridgeCreditAndSwapForTokens{value: msg.value}(
            toToken,
            toChain,
            fromAmount,
            minimumToAmount,
            receiver,
            receiverValue,
            deliveryGasLimit
        );
    }

    /**
     * Internal functions
     */

    function _onlyAdaptor() internal view {
        if (msg.sender != address(adaptor)) revert WOMBAT_FORBIDDEN();
    }

    function _swapTokensForCredit(
        IAsset fromAsset,
        uint256 fromAmount,
        uint256 minimumCreditAmount
    ) internal returns (uint256 creditAmount, uint256 fromTokenFee) {
        // Assume credit has 18 decimals
        if (!swapTokensForCreditEnabled) revert POOL__SWAP_TOKENS_FOR_CREDIT_DISABLED();
        // TODO: implement _quoteFactor for credit if we would like to support dynamic asset (aka volatile / rather-volatile pools)
        // uint256 quoteFactor = IRelativePriceProvider(address(fromAsset)).getRelativePrice();
        (creditAmount, fromTokenFee) = CoreV3.quoteSwapTokensForCredit(
            fromAsset,
            fromAmount,
            ampFactor,
            WAD,
            tokensForCreditHaircut,
            startCovRatio,
            endCovRatio
        );

        _checkAmount(minimumCreditAmount, creditAmount);

        fromAsset.addCash(fromAmount - fromTokenFee);
        totalCreditMinted += _to128(creditAmount);
        _feeCollected[fromAsset] += fromTokenFee; // unlike other swaps, fee is collected in from token

        // Check it doesn't exceed maximum out-going credits
        if (totalCreditMinted > maximumOutboundCredit + totalCreditBurned) revert POOL__REACH_MAXIMUM_MINTED_CREDIT();
    }

    function _beforeSwapCreditForTokens(uint256 fromAmount, address receiver) internal {
        _checkAddress(receiver);
        if (fromAmount == 0) revert WOMBAT_ZERO_AMOUNT();

        if (creditBalance[msg.sender] < fromAmount) revert POOL__CREDIT_NOT_ENOUGH();
        unchecked {
            creditBalance[msg.sender] -= fromAmount;
        }
    }

    function _doSwapCreditForTokens(
        address toToken,
        uint256 fromCreditAmount,
        uint256 minimumToAmount,
        address receiver
    ) internal returns (uint256 actualToAmount, uint256 toTokenFee) {
        if (fromCreditAmount == 0) revert WOMBAT_ZERO_CREDIT_AMOUNT();

        IAsset toAsset = _assetOf(toToken);
        uint8 toDecimal = toAsset.underlyingTokenDecimals();
        (actualToAmount, toTokenFee) = _swapCreditForTokens(
            toAsset,
            fromCreditAmount,
            minimumToAmount.toWad(toDecimal)
        );
        actualToAmount = actualToAmount.fromWad(toDecimal);
        toTokenFee = toTokenFee.fromWad(toDecimal);

        toAsset.transferUnderlyingToken(receiver, actualToAmount);
        totalCreditBurned += _to128(fromCreditAmount);

        // Check it doesn't exceed maximum in-coming credits
        if (totalCreditBurned > maximumInboundCredit + totalCreditMinted) revert POOL__REACH_MAXIMUM_BURNED_CREDIT();

        emit SwapCreditForTokens(fromCreditAmount, toToken, actualToAmount, toTokenFee, receiver);
    }

    function _swapCreditForTokens(
        IAsset toAsset,
        uint256 fromCreditAmount,
        uint256 minimumToAmount
    ) internal returns (uint256 actualToAmount, uint256 toTokenFee) {
        if (!swapCreditForTokensEnabled) revert POOL__SWAP_CREDIT_FOR_TOKENS_DISABLED();
        // TODO: If we want to support dynamic asset (aka volatile / rather-volatile pools), implement `_quoteFactor` for credit
        (actualToAmount, toTokenFee) = CoreV3.quoteSwapCreditForTokens(
            fromCreditAmount,
            toAsset,
            ampFactor,
            WAD,
            creditForTokensHaircut
        );

        _checkAmount(minimumToAmount, actualToAmount);
        _feeCollected[toAsset] += toTokenFee;

        // fee is removed from cash to maintain r* = 1. It is distributed during _mintFee()
        toAsset.removeCash(actualToAmount + toTokenFee);

        // revert if cov ratio < 1% to avoid precision error
        if (DSMath.wdiv(toAsset.cash(), toAsset.liability()) < WAD / 100) revert WOMBAT_FORBIDDEN();
    }

    /**
     * Read-only functions
     */

    function quoteSwapCreditForTokens(
        address toToken,
        uint256 fromCreditAmount
    ) external view returns (uint256 actualToAmount, uint256 toTokenFee) {
        IAsset toAsset = _assetOf(toToken);
        if (!swapCreditForTokensEnabled) revert POOL__SWAP_CREDIT_FOR_TOKENS_DISABLED();
        // TODO: implement _quoteFactor for credit if we would like to support dynamic asset (aka volatile / rather-volatile pools)
        (actualToAmount, toTokenFee) = CoreV3.quoteSwapCreditForTokens(
            fromCreditAmount,
            toAsset,
            ampFactor,
            WAD,
            creditForTokensHaircut
        );

        uint8 toDecimal = toAsset.underlyingTokenDecimals();
        actualToAmount = actualToAmount.fromWad(toDecimal);
        toTokenFee = toTokenFee.fromWad(toDecimal);

        // Check it doesn't exceed maximum in-coming credits
        if (totalCreditBurned + fromCreditAmount > maximumInboundCredit + totalCreditMinted)
            revert POOL__REACH_MAXIMUM_BURNED_CREDIT();
    }

    function quoteSwapTokensForCredit(
        address fromToken,
        uint256 fromAmount
    ) external view returns (uint256 creditAmount, uint256 fromTokenFee) {
        IAsset fromAsset = _assetOf(fromToken);

        // Assume credit has 18 decimals
        if (!swapTokensForCreditEnabled) revert POOL__SWAP_TOKENS_FOR_CREDIT_DISABLED();
        // TODO: implement _quoteFactor for credit if we would like to support dynamic asset (aka volatile / rather-volatile pools)
        // uint256 quoteFactor = IRelativePriceProvider(address(fromAsset)).getRelativePrice();
        (creditAmount, fromTokenFee) = CoreV3.quoteSwapTokensForCredit(
            fromAsset,
            fromAmount.toWad(fromAsset.underlyingTokenDecimals()),
            ampFactor,
            WAD,
            tokensForCreditHaircut,
            startCovRatio,
            endCovRatio
        );

        fromTokenFee = fromTokenFee.fromWad(fromAsset.underlyingTokenDecimals());

        // Check it doesn't exceed maximum out-going credits
        if (totalCreditMinted + creditAmount > maximumOutboundCredit + totalCreditBurned)
            revert POOL__REACH_MAXIMUM_MINTED_CREDIT();
    }

    /**
     * @notice Calculate the r* and invariant when all credits are settled
     */
    function globalEquilCovRatioWithCredit() external view returns (uint256 equilCovRatio, uint256 invariantInUint) {
        int256 invariant;
        int256 SL;
        (invariant, SL) = _globalInvariantFunc();
        // oustanding credit = totalCreditBurned - totalCreditMinted
        int256 creditOffset = (int256(uint256(totalCreditBurned)) - int256(uint256(totalCreditMinted))).wmul(
            (WAD + ampFactor).toInt256()
        );
        invariant += creditOffset;
        equilCovRatio = uint256(CoreV3.equilCovRatio(invariant, SL, ampFactor.toInt256()));
        invariantInUint = uint256(invariant);
    }

    function _to128(uint256 val) internal pure returns (uint128) {
        require(val <= type(uint128).max, 'uint128 overflow');
        return uint128(val);
    }

    /**
     * Permisioneed functions
     */

    /**
     * @dev refer to documentation in the interface
     */
    function completeSwapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver
    ) external override whenNotPaused returns (uint256 actualToAmount, uint256 toTokenFee) {
        _onlyAdaptor();
        // Note: `_checkAddress(receiver)` could be skipped at it is called at the `fromChain`
        (actualToAmount, toTokenFee) = _doSwapCreditForTokens(toToken, fromAmount, minimumToAmount, receiver);
    }

    /**
     * @notice In case `completeSwapCreditForTokens` fails, adaptor should mint credit to the respective user
     * @dev This function is only for the case when `completeSwapCreditForTokens` fails, and should not be called otherwise
     * Also, this function should work even if the pool is paused
     */
    function mintCredit(uint256 creditAmount, address receiver) external override {
        _onlyAdaptor();
        creditBalance[receiver] += creditAmount;
        emit MintCredit(receiver, creditAmount);
    }

    function setSwapTokensForCreditEnabled(bool enable) external onlyOwner {
        swapTokensForCreditEnabled = enable;
    }

    function setSwapCreditForTokensEnabled(bool enable) external onlyOwner {
        swapCreditForTokensEnabled = enable;
    }

    function setMaximumOutboundCredit(uint128 _maximumOutboundCredit) external onlyOwner {
        maximumOutboundCredit = _maximumOutboundCredit;
    }

    function setMaximumInboundCredit(uint128 _maximumInboundCredit) external onlyOwner {
        maximumInboundCredit = _maximumInboundCredit;
    }

    function setAdaptorAddr(IAdaptor _adaptor) external onlyOwner {
        adaptor = _adaptor;
    }

    function setCrossChainHaircut(uint128 _tokensForCreditHaircut, uint128 _creditForTokensHaircut) external onlyOwner {
        require(_creditForTokensHaircut < 1e18 && _tokensForCreditHaircut < 1e18);
        creditForTokensHaircut = _creditForTokensHaircut;
        tokensForCreditHaircut = _tokensForCreditHaircut;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

import '../libraries/DSMath.sol';
import '../interfaces/IRelativePriceProvider.sol';
import './HighCovRatioFeePoolV3.sol';

/**
 * @title Dynamic Pool V3
 * @notice Manages deposits, withdrawals and swaps. Holds a mapping of assets and parameters.
 * @dev Supports dynamic assets. Assume r* to be close to 1.
 * Be aware that r* changes when the relative price of the asset updates
 * Change log:
 * - V2: add `gap` to prevent storage collision for future upgrades
 * - V2: Inherite from `HighCovRatioFeePoolV2` instead of `Pool`
 */
contract DynamicPoolV3 is HighCovRatioFeePoolV3 {
    using DSMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeMath for uint256;

    uint256[50] private gap;

    /**
     * @notice multiply / divide the cash, liability and amount of a swap by relative price
     * Invariant: D = Sum of P_i * L_i * (r_i - A / r_i)
     */
    function _quoteFactor(IAsset fromAsset, IAsset toAsset) internal view override returns (uint256) {
        uint256 fromAssetRelativePrice = IRelativePriceProvider(address(fromAsset)).getRelativePrice();
        // theoretically we should multiply toCash, toLiability and idealToAmount by toAssetRelativePrice
        // however we simplify the calculation by dividing "from amounts" by toAssetRelativePrice
        uint256 toAssetRelativePrice = IRelativePriceProvider(address(toAsset)).getRelativePrice();

        return (1e18 * fromAssetRelativePrice) / toAssetRelativePrice;
    }

    /**
     * @dev Invariant: D = Sum of P_i * L_i * (r_i - A / r_i)
     */
    function _globalInvariantFunc() internal view override returns (int256 D, int256 SL) {
        int256 A = ampFactor.toInt256();

        for (uint256 i; i < _sizeOfAssetList(); ++i) {
            IAsset asset = _getAsset(_getKeyAtIndex(i));

            // overflow is unrealistic
            int256 A_i = int256(uint256(asset.cash()));
            int256 L_i = int256(uint256(asset.liability()));
            int256 P_i = IRelativePriceProvider(address(asset)).getRelativePrice().toInt256();

            // Assume when L_i == 0, A_i always == 0
            if (L_i == 0) {
                // avoid division of 0
                continue;
            }

            int256 r_i = A_i.wdiv(L_i);
            SL += P_i.wmul(L_i);
            D += P_i.wmul(L_i).wmul(r_i - A.wdiv(r_i));
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '../libraries/DSMath.sol';
import './PoolV3.sol';

/**
 * @title HighCovRatioFeePoolV3
 * @dev Pool with high cov ratio fee protection
 * Change log:
 * - V2: Add `gap` to prevent storage collision for future upgrades
 * - V3: Contract size compression
 */
contract HighCovRatioFeePoolV3 is PoolV3 {
    using DSMath for uint256;
    using SignedSafeMath for uint256;

    uint128 public startCovRatio; // 1.5
    uint128 public endCovRatio; // 1.8

    uint256[50] private gap;

    error WOMBAT_COV_RATIO_LIMIT_EXCEEDED();

    function initialize(uint256 ampFactor_, uint256 haircutRate_) public virtual override {
        super.initialize(ampFactor_, haircutRate_);
        startCovRatio = 15e17;
        endCovRatio = 18e17;
    }

    function setCovRatioFeeParam(uint128 startCovRatio_, uint128 endCovRatio_) external onlyOwner {
        if (startCovRatio_ < 1e18 || startCovRatio_ > endCovRatio_) revert WOMBAT_INVALID_VALUE();

        startCovRatio = startCovRatio_;
        endCovRatio = endCovRatio_;
    }

    /**
     * @dev Exact output swap (fromAmount < 0) should be only used by off-chain quoting function as it is a gas monster
     */
    function _quoteFrom(
        IAsset fromAsset,
        IAsset toAsset,
        int256 fromAmount
    ) internal view override returns (uint256 actualToAmount, uint256 toTokenFee) {
        (actualToAmount, toTokenFee) = super._quoteFrom(fromAsset, toAsset, fromAmount);

        if (fromAmount >= 0) {
            uint256 highCovRatioFee = CoreV3.highCovRatioFee(
                fromAsset.cash(),
                fromAsset.liability(),
                uint256(fromAmount),
                actualToAmount,
                startCovRatio,
                endCovRatio
            );

            actualToAmount -= highCovRatioFee;
            toTokenFee += highCovRatioFee;
        } else {
            // reverse quote
            uint256 toAssetCash = toAsset.cash();
            uint256 toAssetLiability = toAsset.liability();
            uint256 finalToAssetCovRatio = (toAssetCash + actualToAmount).wdiv(toAssetLiability);
            if (finalToAssetCovRatio <= startCovRatio) {
                // happy path: no high cov ratio fee is charged
                return (actualToAmount, toTokenFee);
            } else if (toAssetCash.wdiv(toAssetLiability) >= endCovRatio) {
                // the to-asset exceeds it's cov ratio limit, further swap to increase cov ratio is impossible
                revert WOMBAT_COV_RATIO_LIMIT_EXCEEDED();
            }

            // reverse quote: cov ratio of the to-asset exceed endCovRatio. direct reverse quote is not supported
            // we binary search for a upper bound
            actualToAmount = _findUpperBound(toAsset, fromAsset, uint256(-fromAmount));
            (, toTokenFee) = _quoteFrom(toAsset, fromAsset, actualToAmount.toInt256());
        }
    }

    /**
     * @notice Binary search to find the upper bound of `fromAmount` required to swap `fromAsset` to `toAmount` of `toAsset`
     * @dev This function should only used as off-chain view function as it is a gas monster
     */
    function _findUpperBound(
        IAsset fromAsset,
        IAsset toAsset,
        uint256 toAmount
    ) internal view returns (uint256 upperBound) {
        uint8 decimals = fromAsset.underlyingTokenDecimals();
        uint256 toWadFactor = DSMath.toWad(1, decimals);
        // the search value uses the same number of digits as the token
        uint256 high = (uint256(fromAsset.liability()).wmul(endCovRatio) - fromAsset.cash()).fromWad(decimals);
        uint256 low = 1;

        // verify `high` is a valid upper bound
        uint256 quote;
        (quote, ) = _quoteFrom(fromAsset, toAsset, (high * toWadFactor).toInt256());
        if (quote < toAmount) revert WOMBAT_COV_RATIO_LIMIT_EXCEEDED();

        // Note: we might limit the maximum number of rounds if the request is always rejected by the RPC server
        while (low < high) {
            uint256 mid = (low + high) / 2;
            (quote, ) = _quoteFrom(fromAsset, toAsset, (mid * toWadFactor).toInt256());
            if (quote >= toAmount) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high * toWadFactor;
    }

    /**
     * @dev take into account high cov ratio fee
     */
    function quotePotentialWithdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity
    ) external view virtual override returns (uint256 finalAmount, uint256 withdrewAmount) {
        _checkLiquidity(liquidity);
        _checkSameAddress(fromToken, toToken);

        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);
        uint256 scaleFactor = _quoteFactor(fromAsset, toAsset);
        (finalAmount, withdrewAmount) = CoreV3.quoteWithdrawAmountFromOtherAsset(
            fromAsset,
            toAsset,
            liquidity,
            ampFactor,
            scaleFactor,
            haircutRate,
            startCovRatio,
            endCovRatio,
            _getGlobalEquilCovRatioForDepositWithdrawal(),
            withdrawalHaircutRate
        );

        withdrewAmount = withdrewAmount.fromWad(fromAsset.underlyingTokenDecimals());
        finalAmount = finalAmount.fromWad(toAsset.underlyingTokenDecimals());
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

/**
 * @title PausableAssets
 * @notice Handles assets pause and unpause of Wombat protocol.
 * @dev Allows pausing and unpausing of deposit and swap operations
 */
contract PausableAssets {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event PausedAsset(address token, address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event UnpausedAsset(address token, address account);

    // We use the asset's underlying token as the key to check whether an asset is paused.
    // A pool will never have two assets with the same underlying token.
    mapping(address => bool) private _pausedAssets;

    error WOMBAT_ASSET_ALREADY_PAUSED();
    error WOMBAT_ASSET_NOT_PAUSED();

    /**
     * @dev Function to return if the asset is paused.
     * The return value is only useful when true.
     * When the return value is false, the asset can be either not paused or not exist.
     */
    function isPaused(address token) public view returns (bool) {
        return _pausedAssets[token];
    }

    /**
     * @dev Function to make a function callable only when the asset is not paused.
     *
     * Requirements:
     *
     * - The asset must not be paused.
     */
    function requireAssetNotPaused(address token) internal view {
        if (_pausedAssets[token]) revert WOMBAT_ASSET_ALREADY_PAUSED();
    }

    /**
     * @dev Function to make a function callable only when the asset is paused.
     *
     * Requirements:
     *
     * - The asset must be paused.
     */
    function requireAssetPaused(address token) internal view {
        if (!_pausedAssets[token]) revert WOMBAT_ASSET_NOT_PAUSED();
    }

    /**
     * @dev Triggers paused state.
     *
     * Requirements:
     *
     * - The asset must not be paused.
     */
    function _pauseAsset(address token) internal {
        requireAssetNotPaused(token);
        _pausedAssets[token] = true;
        emit PausedAsset(token, msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The asset must be paused.
     */
    function _unpauseAsset(address token) internal {
        requireAssetPaused(token);
        _pausedAssets[token] = false;
        emit UnpausedAsset(token, msg.sender);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './CoreV3.sol';
import '../interfaces/IAsset.sol';
import './PausableAssets.sol';
import '../../wombat-governance/interfaces/IMasterWombat.sol';
import '../interfaces/IPoolV3.sol';

/**
 * @title Pool V3
 * @notice Manages deposits, withdrawals and swaps. Holds a mapping of assets and parameters.
 * @dev The main entry-point of Wombat protocol
 * Note: All variables are 18 decimals, except from that of underlying tokens
 * Change log:
 * - V2: Add `gap` to prevent storage collision for future upgrades
 * - V3:
 *   - *Breaking change*: interface change for quotePotentialDeposit, quotePotentialWithdraw
 *     and quotePotentialWithdrawFromOtherAsset, the reward/fee parameter is removed as it is
 *     ambiguous in the context of volatile pools.
 *   - Contract size compression
 *   - `mintFee` ignores `mintFeeThreshold`
 *   - `globalEquilCovRatio` returns int256 `instead` of `uint256`
 *   - Emit event `SwapV2` with `toTokenFee` instead of `Swap`
 * - TODOs for V4:
 *   - Consider renaming returned value `uint256 haircut` to `toTokenFee / haircutInToToken`
 */
contract PoolV3 is
    Initializable,
    IPoolV3,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    PausableAssets
{
    using DSMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;
    using SignedSafeMath for uint256;

    /// @notice Asset Map struct holds assets
    struct AssetMap {
        address[] keys;
        mapping(address => IAsset) values;
        mapping(address => uint256) indexOf;
    }

    int256 internal constant WAD_I = 10 ** 18;
    uint256 internal constant WAD = 10 ** 18;

    /* Storage */

    /// @notice Amplification factor
    uint256 public ampFactor;

    /// @notice Haircut rate
    uint256 public haircutRate;

    /// @notice Retention ratio: the ratio of haircut that should stay in the pool
    uint256 public retentionRatio;

    /// @notice LP dividend ratio : the ratio of haircut that should distribute to LP
    uint256 public lpDividendRatio;

    /// @notice The threshold to mint fee (unit: WAD)
    uint256 public mintFeeThreshold;

    /// @notice Dev address
    address public dev;

    address public feeTo;

    address public masterWombat;

    /// @notice Dividend collected by each asset (unit: WAD)
    mapping(IAsset => uint256) internal _feeCollected;

    /// @notice A record of assets inside Pool
    AssetMap internal _assets;

    // Slots reserved for future use
    uint128 internal _used1; // Remember to initialize before use.
    uint128 internal _used2; // Remember to initialize before use.

    /// @notice Withdrawal haircut rate charged at the time of withdrawal
    uint256 public withdrawalHaircutRate;
    uint256[48] private gap;

    /* Events */

    /// @notice An event thats emitted when an asset is added to Pool
    event AssetAdded(address indexed token, address indexed asset);

    /// @notice An event thats emitted when asset is removed from Pool
    event AssetRemoved(address indexed token, address indexed asset);

    /// @notice An event thats emitted when a deposit is made to Pool
    event Deposit(address indexed sender, address token, uint256 amount, uint256 liquidity, address indexed to);

    /// @notice An event thats emitted when a withdrawal is made from Pool
    event Withdraw(address indexed sender, address token, uint256 amount, uint256 liquidity, address indexed to);

    event SwapV2(
        address indexed sender,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 toTokenFee,
        address indexed to
    );

    event SetDev(address addr);
    event SetMasterWombat(address addr);
    event SetFeeTo(address addr);

    event SetMintFeeThreshold(uint256 value);
    event SetFee(uint256 lpDividendRatio, uint256 retentionRatio);
    event SetAmpFactor(uint256 value);
    event SetHaircutRate(uint256 value);
    event SetWithdrawalHaircutRate(uint256 value);

    event FillPool(address token, uint256 amount);
    event TransferTipBucket(address token, uint256 amount, address to);

    /* Errors */

    error WOMBAT_FORBIDDEN();
    error WOMBAT_EXPIRED();

    error WOMBAT_ASSET_NOT_EXISTS();
    error WOMBAT_ASSET_ALREADY_EXIST();

    error WOMBAT_ZERO_ADDRESS();
    error WOMBAT_ZERO_AMOUNT();
    error WOMBAT_ZERO_LIQUIDITY();
    error WOMBAT_INVALID_VALUE();
    error WOMBAT_SAME_ADDRESS();
    error WOMBAT_AMOUNT_TOO_LOW();
    error WOMBAT_CASH_NOT_ENOUGH();

    /* Pesudo modifiers to safe gas */

    function _checkLiquidity(uint256 liquidity) internal pure {
        if (liquidity == 0) revert WOMBAT_ZERO_LIQUIDITY();
    }

    function _checkAddress(address to) internal pure {
        if (to == address(0)) revert WOMBAT_ZERO_ADDRESS();
    }

    function _checkSameAddress(address from, address to) internal pure {
        if (from == to) revert WOMBAT_SAME_ADDRESS();
    }

    function _checkAmount(uint256 minAmt, uint256 amt) internal pure {
        if (minAmt > amt) revert WOMBAT_AMOUNT_TOO_LOW();
    }

    function _ensure(uint256 deadline) internal view {
        if (deadline < block.timestamp) revert WOMBAT_EXPIRED();
    }

    function _onlyDev() internal view {
        if (dev != msg.sender) revert WOMBAT_FORBIDDEN();
    }

    /* Construtor and setters */

    /**
     * @notice Initializes pool. Dev is set to be the account calling this function.
     */
    function initialize(uint256 ampFactor_, uint256 haircutRate_) public virtual initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        if (ampFactor_ > WAD || haircutRate_ > WAD) revert WOMBAT_INVALID_VALUE();
        ampFactor = ampFactor_;
        haircutRate = haircutRate_;

        lpDividendRatio = WAD;

        dev = msg.sender;
    }

    /**
     * Permisioneed functions
     */

    /**
     * @notice Adds asset to pool, reverts if asset already exists in pool
     * @param token The address of token
     * @param asset The address of the Wombat Asset contract
     */
    function addAsset(address token, address asset) external onlyOwner {
        _checkAddress(asset);
        _checkAddress(token);
        _checkSameAddress(token, asset);

        if (_containsAsset(token)) revert WOMBAT_ASSET_ALREADY_EXIST();
        _assets.values[token] = IAsset(asset);
        _assets.indexOf[token] = _assets.keys.length;
        _assets.keys.push(token);

        emit AssetAdded(token, asset);
    }

    /**
     * @notice Removes asset from asset struct
     * @dev Can only be called by owner
     * @param token The address of token to remove
     */
    function removeAsset(address token) external onlyOwner {
        if (!_containsAsset(token)) revert WOMBAT_ASSET_NOT_EXISTS();

        address asset = address(_getAsset(token));
        delete _assets.values[token];

        uint256 index = _assets.indexOf[token];
        uint256 lastIndex = _assets.keys.length - 1;
        address lastKey = _assets.keys[lastIndex];

        _assets.indexOf[lastKey] = index;
        delete _assets.indexOf[token];

        _assets.keys[index] = lastKey;
        _assets.keys.pop();

        emit AssetRemoved(token, asset);
    }

    /**
     * @notice Changes the contract dev. Can only be set by the contract owner.
     * @param dev_ new contract dev address
     */
    function setDev(address dev_) external onlyOwner {
        _checkAddress(dev_);
        dev = dev_;
        emit SetDev(dev_);
    }

    function setMasterWombat(address masterWombat_) external onlyOwner {
        _checkAddress(masterWombat_);
        masterWombat = masterWombat_;
        emit SetMasterWombat(masterWombat_);
    }

    /**
     * @notice Changes the pools amplification factor. Can only be set by the contract owner.
     * @param ampFactor_ new pool's amplification factor
     */
    function setAmpFactor(uint256 ampFactor_) external onlyOwner {
        if (ampFactor_ > WAD) revert WOMBAT_INVALID_VALUE(); // ampFactor_ should not be set bigger than 1
        ampFactor = ampFactor_;
        emit SetAmpFactor(ampFactor_);
    }

    /**
     * @notice Changes the pools haircutRate. Can only be set by the contract owner.
     * @param haircutRate_ new pool's haircutRate_
     */
    function setHaircutRate(uint256 haircutRate_) external onlyOwner {
        if (haircutRate_ > WAD) revert WOMBAT_INVALID_VALUE(); // haircutRate_ should not be set bigger than 1
        haircutRate = haircutRate_;
        emit SetHaircutRate(haircutRate_);
    }

    function setWithdrawalHaircutRate(uint256 withdrawalHaircutRate_) external onlyOwner {
        if (withdrawalHaircutRate_ > WAD) revert WOMBAT_INVALID_VALUE();
        withdrawalHaircutRate = withdrawalHaircutRate_;
        emit SetWithdrawalHaircutRate(withdrawalHaircutRate_);
    }

    function setFee(uint256 lpDividendRatio_, uint256 retentionRatio_) external onlyOwner {
        if (retentionRatio_ + lpDividendRatio_ > WAD) revert WOMBAT_INVALID_VALUE();

        _mintAllFees();
        retentionRatio = retentionRatio_;
        lpDividendRatio = lpDividendRatio_;
        emit SetFee(lpDividendRatio_, retentionRatio_);
    }

    /**
     * @dev unit of amount should be in WAD
     */
    function transferTipBucket(address token, uint256 amount, address to) external onlyOwner {
        IAsset asset = _assetOf(token);
        uint256 tipBucketBal = tipBucketBalance(token);

        if (amount > tipBucketBal) {
            // revert if there's not enough amount in the tip bucket
            revert WOMBAT_INVALID_VALUE();
        }

        asset.transferUnderlyingToken(to, amount.fromWad(asset.underlyingTokenDecimals()));
        emit TransferTipBucket(token, amount, to);
    }

    /**
     * @notice Changes the fee beneficiary. Can only be set by the contract owner.
     * This value cannot be set to 0 to avoid unsettled fee.
     * @param feeTo_ new fee beneficiary
     */
    function setFeeTo(address feeTo_) external onlyOwner {
        _checkAddress(feeTo_);
        feeTo = feeTo_;
        emit SetFeeTo(feeTo_);
    }

    /**
     * @notice Set min fee to mint
     */
    function setMintFeeThreshold(uint256 mintFeeThreshold_) external onlyOwner {
        mintFeeThreshold = mintFeeThreshold_;
        emit SetMintFeeThreshold(mintFeeThreshold_);
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external {
        _onlyDev();
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external {
        _onlyDev();
        _unpause();
    }

    /**
     * @dev pause asset, restricting deposit and swap operations
     */
    function pauseAsset(address token) external {
        _onlyDev();
        if (!_containsAsset(token)) revert WOMBAT_ASSET_NOT_EXISTS();
        _pauseAsset(token);
    }

    /**
     * @dev unpause asset, enabling deposit and swap operations
     */
    function unpauseAsset(address token) external {
        _onlyDev();
        _unpauseAsset(token);
    }

    /**
     * @notice Move fund from tip bucket to the pool to keep r* = 1 as error accumulates
     * unit of amount should be in WAD
     */
    function fillPool(address token, uint256 amount) external {
        _onlyDev();
        IAsset asset = _assetOf(token);
        uint256 tipBucketBal = tipBucketBalance(token);

        if (amount > tipBucketBal) {
            // revert if there's not enough amount in the tip bucket
            revert WOMBAT_INVALID_VALUE();
        }

        asset.addCash(amount);
        emit FillPool(token, amount);
    }

    /* Assets */

    /**
     * @notice Return list of tokens in the pool
     */
    function getTokens() external view override returns (address[] memory) {
        return _assets.keys;
    }

    /**
     * @notice get length of asset list
     * @return the size of the asset list
     */
    function _sizeOfAssetList() internal view returns (uint256) {
        return _assets.keys.length;
    }

    /**
     * @notice Gets asset with token address key
     * @param key The address of token
     * @return the corresponding asset in state
     */
    function _getAsset(address key) internal view returns (IAsset) {
        return _assets.values[key];
    }

    /**
     * @notice Gets key (address) at index
     * @param index the index
     * @return the key of index
     */
    function _getKeyAtIndex(uint256 index) internal view returns (address) {
        return _assets.keys[index];
    }

    /**
     * @notice Looks if the asset is contained by the list
     * @param token The address of token to look for
     * @return bool true if the asset is in asset list, false otherwise
     */
    function _containsAsset(address token) internal view returns (bool) {
        return _assets.values[token] != IAsset(address(0));
    }

    /**
     * @notice Gets Asset corresponding to ERC20 token. Reverts if asset does not exists in Pool.
     * @param token The address of ERC20 token
     */
    function _assetOf(address token) internal view returns (IAsset) {
        if (!_containsAsset(token)) revert WOMBAT_ASSET_NOT_EXISTS();
        return _assets.values[token];
    }

    /**
     * @notice Gets Asset corresponding to ERC20 token. Reverts if asset does not exists in Pool.
     * @dev to be used externally
     * @param token The address of ERC20 token
     */
    function addressOfAsset(address token) external view override returns (address) {
        return address(_assetOf(token));
    }

    /* Deposit */

    /**
     * @notice Deposits asset in Pool
     * @param asset The asset to be deposited
     * @param amount The amount to be deposited
     * @param minimumLiquidity The minimum amount of liquidity to receive
     * @param to The user accountable for deposit, receiving the Wombat assets (lp)
     * @return liquidity Total asset liquidity minted
     */
    function _deposit(
        IAsset asset,
        uint256 amount,
        uint256 minimumLiquidity,
        address to
    ) internal returns (uint256 liquidity) {
        // collect fee before deposit
        _mintFeeIfNeeded(asset);

        uint256 liabilityToMint;
        (liquidity, liabilityToMint) = CoreV3.quoteDepositLiquidity(
            asset,
            amount,
            ampFactor,
            _getGlobalEquilCovRatioForDepositWithdrawal()
        );

        _checkLiquidity(liquidity);
        _checkAmount(minimumLiquidity, liquidity);

        asset.addCash(amount);
        asset.addLiability(liabilityToMint);
        asset.mint(to, liquidity);
    }

    /**
     * @notice Deposits amount of tokens into pool ensuring deadline
     * @dev Asset needs to be created and added to pool before any operation. This function assumes tax free token.
     * @param token The token address to be deposited
     * @param amount The amount to be deposited
     * @param minimumLiquidity The minimum amount of liquidity to receive
     * @param to The user accountable for deposit, receiving the Wombat assets (lp)
     * @param deadline The deadline to be respected
     * @param shouldStake Whether to stake LP tokens automatically after deposit
     * @return liquidity Total asset liquidity minted
     */
    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external override nonReentrant whenNotPaused returns (uint256 liquidity) {
        if (amount == 0) revert WOMBAT_ZERO_AMOUNT();
        _checkAddress(to);
        _ensure(deadline);
        requireAssetNotPaused(token);

        IAsset asset = _assetOf(token);
        IERC20(token).safeTransferFrom(address(msg.sender), address(asset), amount);

        if (!shouldStake) {
            liquidity = _deposit(asset, amount.toWad(asset.underlyingTokenDecimals()), minimumLiquidity, to);
        } else {
            _checkAddress(masterWombat);
            // deposit and stake on behalf of the user
            liquidity = _deposit(asset, amount.toWad(asset.underlyingTokenDecimals()), minimumLiquidity, address(this));

            asset.approve(masterWombat, liquidity);

            uint256 pid = IMasterWombat(masterWombat).getAssetPid(address(asset));
            IMasterWombat(masterWombat).depositFor(pid, liquidity, to);
        }

        emit Deposit(msg.sender, token, amount, liquidity, to);
    }

    /**
     * @notice Quotes potential deposit from pool
     * @dev To be used by frontend
     * @param token The token to deposit by user
     * @param amount The amount to deposit
     * @return liquidity The potential liquidity user would receive
     */
    function quotePotentialDeposit(address token, uint256 amount) external view override returns (uint256 liquidity) {
        IAsset asset = _assetOf(token);
        uint8 decimals = asset.underlyingTokenDecimals();
        (liquidity, ) = CoreV3.quoteDepositLiquidity(
            asset,
            amount.toWad(decimals),
            ampFactor,
            _getGlobalEquilCovRatioForDepositWithdrawal()
        );
    }

    /* Withdraw */

    /**
     * @notice Withdraws liquidity amount of asset to `to` address ensuring minimum amount required
     * @param asset The asset to be withdrawn
     * @param liquidity The liquidity to be withdrawn
     * @param minimumAmount The minimum amount that will be accepted by user
     * @return amount The total amount withdrawn
     * @return withdrawalHaircut The amount of withdrawn haircut
     */
    function _withdraw(
        IAsset asset,
        uint256 liquidity,
        uint256 minimumAmount
    ) internal returns (uint256 amount, uint256 withdrawalHaircut) {
        // collect fee before withdraw
        _mintFeeIfNeeded(asset);

        // calculate liabilityToBurn and Fee
        uint256 liabilityToBurn;
        (amount, liabilityToBurn, withdrawalHaircut) = CoreV3.quoteWithdrawAmount(
            asset,
            liquidity,
            ampFactor,
            _getGlobalEquilCovRatioForDepositWithdrawal(),
            withdrawalHaircutRate
        );
        _checkAmount(minimumAmount, amount);

        asset.burn(address(asset), liquidity);
        asset.removeCash(amount + withdrawalHaircut);
        asset.removeLiability(liabilityToBurn);

        // revert if cov ratio < 1% to avoid precision error
        if (asset.liability() > 0 && uint256(asset.cash()).wdiv(asset.liability()) < WAD / 100)
            revert WOMBAT_FORBIDDEN();

        if (withdrawalHaircut > 0) {
            _feeCollected[asset] += withdrawalHaircut;
        }
    }

    /**
     * @notice Withdraws liquidity amount of asset to `to` address ensuring minimum amount required
     * @param token The token to be withdrawn
     * @param liquidity The liquidity to be withdrawn
     * @param minimumAmount The minimum amount that will be accepted by user
     * @param to The user receiving the withdrawal
     * @param deadline The deadline to be respected
     * @return amount The total amount withdrawn
     */
    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external override nonReentrant whenNotPaused returns (uint256 amount) {
        _checkLiquidity(liquidity);
        _checkAddress(to);
        _ensure(deadline);

        IAsset asset = _assetOf(token);
        // request lp token from user
        IERC20(asset).safeTransferFrom(address(msg.sender), address(asset), liquidity);
        uint8 decimals = asset.underlyingTokenDecimals();
        (amount, ) = _withdraw(asset, liquidity, minimumAmount.toWad(decimals));
        amount = amount.fromWad(decimals);
        asset.transferUnderlyingToken(to, amount);

        emit Withdraw(msg.sender, token, amount, liquidity, to);
    }

    /**
     * @notice Enables withdrawing liquidity from an asset using LP from a different asset
     * @param fromToken The corresponding token user holds the LP (Asset) from
     * @param toToken The token wanting to be withdrawn (needs to be well covered)
     * @param liquidity The liquidity to be withdrawn (in fromToken decimal)
     * @param minimumAmount The minimum amount that will be accepted by user
     * @param to The user receiving the withdrawal
     * @param deadline The deadline to be respected
     * @return toAmount The total amount withdrawn
     */
    function withdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external override nonReentrant whenNotPaused returns (uint256 toAmount) {
        _checkAddress(to);
        _checkLiquidity(liquidity);
        _checkSameAddress(fromToken, toToken);
        _ensure(deadline);
        requireAssetNotPaused(fromToken);

        // Withdraw and swap
        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);

        IERC20(fromAsset).safeTransferFrom(address(msg.sender), address(fromAsset), liquidity);
        (uint256 fromAmountInWad, ) = _withdraw(fromAsset, liquidity, 0);
        uint8 toDecimal = toAsset.underlyingTokenDecimals();

        uint256 toTokenFee;
        (toAmount, toTokenFee) = _swap(fromAsset, toAsset, fromAmountInWad, minimumAmount.toWad(toDecimal));

        toAmount = toAmount.fromWad(toDecimal);
        toTokenFee = toTokenFee.fromWad(toDecimal);
        toAsset.transferUnderlyingToken(to, toAmount);

        uint256 fromAmount = fromAmountInWad.fromWad(fromAsset.underlyingTokenDecimals());
        emit Withdraw(msg.sender, fromToken, fromAmount, liquidity, to);
        emit SwapV2(msg.sender, fromToken, toToken, fromAmount, toAmount, toTokenFee, to);
    }

    /**
     * @notice Quotes potential withdrawal from pool
     * @dev To be used by frontend
     * @param token The token to be withdrawn by user
     * @param liquidity The liquidity (amount of lp assets) to be withdrawn
     * @return amount The potential amount user would receive
     */
    function quotePotentialWithdraw(address token, uint256 liquidity) external view override returns (uint256 amount) {
        _checkLiquidity(liquidity);
        IAsset asset = _assetOf(token);
        (amount, , ) = CoreV3.quoteWithdrawAmount(
            asset,
            liquidity,
            ampFactor,
            _getGlobalEquilCovRatioForDepositWithdrawal(),
            withdrawalHaircutRate
        );

        uint8 decimals = asset.underlyingTokenDecimals();
        amount = amount.fromWad(decimals);
    }

    /**
     * @notice Quotes potential withdrawal from other asset from the pool
     * @dev To be used by frontend
     * The startCovRatio and endCovRatio is set to 0, so no high cov ratio fee is charged
     * This is to be overriden by the HighCovRatioFeePool
     * @param fromToken The corresponding token user holds the LP (Asset) from
     * @param toToken The token wanting to be withdrawn (needs to be well covered)
     * @param liquidity The liquidity (amount of the lp assets) to be withdrawn
     * @return finalAmount The potential amount user would receive
     * @return withdrewAmount The amount of the from-token that is withdrew
     */
    function quotePotentialWithdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity
    ) external view virtual override returns (uint256 finalAmount, uint256 withdrewAmount) {
        _checkLiquidity(liquidity);
        _checkSameAddress(fromToken, toToken);

        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);
        uint256 scaleFactor = _quoteFactor(fromAsset, toAsset);
        (finalAmount, withdrewAmount) = CoreV3.quoteWithdrawAmountFromOtherAsset(
            fromAsset,
            toAsset,
            liquidity,
            ampFactor,
            scaleFactor,
            haircutRate,
            0,
            0,
            _getGlobalEquilCovRatioForDepositWithdrawal(),
            withdrawalHaircutRate
        );

        withdrewAmount = withdrewAmount.fromWad(fromAsset.underlyingTokenDecimals());
        finalAmount = finalAmount.fromWad(toAsset.underlyingTokenDecimals());
    }

    /* Swap */

    /**
     * @notice Return the scale factor that should applied on from-amounts in a swap given
     * the from-asset and the to-asset.
     * @dev not applicable to a plain pool
     * All tokens are assumed to have the same intrinsic value
     * To be overriden by DynamicPool
     */
    function _quoteFactor(
        IAsset, // fromAsset
        IAsset // toAsset
    ) internal view virtual returns (uint256) {
        return 1e18;
    }

    /**
     * @notice Quotes the actual amount user would receive in a swap, taking in account slippage and haircut
     * @param fromAsset The initial asset
     * @param toAsset The asset wanted by user
     * @param fromAmount The amount to quote
     * @return actualToAmount The actual amount user would receive
     * @return toTokenFee The haircut that will be applied
     * To be overriden by HighCovRatioFeePool for reverse-quote
     */
    function _quoteFrom(
        IAsset fromAsset,
        IAsset toAsset,
        int256 fromAmount
    ) internal view virtual returns (uint256 actualToAmount, uint256 toTokenFee) {
        uint256 scaleFactor = _quoteFactor(fromAsset, toAsset);
        return CoreV3.quoteSwap(fromAsset, toAsset, fromAmount, ampFactor, scaleFactor, haircutRate);
    }

    /**
     * expect fromAmount and minimumToAmount to be in WAD
     */
    function _swap(
        IAsset fromAsset,
        IAsset toAsset,
        uint256 fromAmount,
        uint256 minimumToAmount
    ) internal returns (uint256 actualToAmount, uint256 toTokenFee) {
        (actualToAmount, toTokenFee) = _quoteFrom(fromAsset, toAsset, fromAmount.toInt256());
        _checkAmount(minimumToAmount, actualToAmount);

        _feeCollected[toAsset] += toTokenFee;

        fromAsset.addCash(fromAmount);

        // haircut is removed from cash to maintain r* = 1. It is distributed during _mintFee()

        toAsset.removeCash(actualToAmount + toTokenFee);

        // mint fee is skipped for swap to save gas,

        // revert if cov ratio < 1% to avoid precision error
        if (uint256(toAsset.cash()).wdiv(toAsset.liability()) < WAD / 100) revert WOMBAT_FORBIDDEN();
    }

    /**
     * @notice Swap fromToken for toToken, ensures deadline and minimumToAmount and sends quoted amount to `to` address
     * @dev This function assumes tax free token.
     * @param fromToken The token being inserted into Pool by user for swap
     * @param toToken The token wanted by user, leaving the Pool
     * @param fromAmount The amount of from token inserted
     * @param minimumToAmount The minimum amount that will be accepted by user as result
     * @param to The user receiving the result of swap
     * @param deadline The deadline to be respected
     */
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external virtual override nonReentrant whenNotPaused returns (uint256 actualToAmount, uint256 haircut) {
        _checkSameAddress(fromToken, toToken);
        if (fromAmount == 0) revert WOMBAT_ZERO_AMOUNT();
        _checkAddress(to);
        _ensure(deadline);
        requireAssetNotPaused(fromToken);

        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);

        uint8 toDecimal = toAsset.underlyingTokenDecimals();

        (actualToAmount, haircut) = _swap(
            fromAsset,
            toAsset,
            fromAmount.toWad(fromAsset.underlyingTokenDecimals()),
            minimumToAmount.toWad(toDecimal)
        );

        actualToAmount = actualToAmount.fromWad(toDecimal);
        haircut = haircut.fromWad(toDecimal);

        IERC20(fromToken).safeTransferFrom(msg.sender, address(fromAsset), fromAmount);
        toAsset.transferUnderlyingToken(to, actualToAmount);

        emit SwapV2(msg.sender, fromToken, toToken, fromAmount, actualToAmount, haircut, to);
    }

    /**
     * @notice Given an input asset amount and token addresses, calculates the
     * maximum output token amount (accounting for fees and slippage).
     * @dev In reverse quote, the haircut is in the `fromAsset`
     * @param fromToken The initial ERC20 token
     * @param toToken The token wanted by user
     * @param fromAmount The given input amount
     * @return potentialOutcome The potential amount user would receive
     * @return haircut The haircut that would be applied
     */
    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) public view override returns (uint256 potentialOutcome, uint256 haircut) {
        _checkSameAddress(fromToken, toToken);
        if (fromAmount == 0) revert WOMBAT_ZERO_AMOUNT();

        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);

        fromAmount = fromAmount.toWad(fromAsset.underlyingTokenDecimals());
        (potentialOutcome, haircut) = _quoteFrom(fromAsset, toAsset, fromAmount);
        potentialOutcome = potentialOutcome.fromWad(toAsset.underlyingTokenDecimals());
        if (fromAmount >= 0) {
            haircut = haircut.fromWad(toAsset.underlyingTokenDecimals());
        } else {
            haircut = haircut.fromWad(fromAsset.underlyingTokenDecimals());
        }
    }

    /**
     * @notice Returns the minimum input asset amount required to buy the given output asset amount
     * (accounting for fees and slippage)
     * @dev To be used by frontend
     * @param fromToken The initial ERC20 token
     * @param toToken The token wanted by user
     * @param toAmount The given output amount
     * @return amountIn The input amount required
     * @return haircut The haircut that would be applied
     */
    function quoteAmountIn(
        address fromToken,
        address toToken,
        int256 toAmount
    ) external view override returns (uint256 amountIn, uint256 haircut) {
        return quotePotentialSwap(toToken, fromToken, -toAmount);
    }

    /* Queries */

    /**
     * @notice Returns the exchange rate of the LP token
     * @param token The address of the token
     * @return xr The exchange rate of LP token
     */
    function exchangeRate(address token) external view returns (uint256 xr) {
        IAsset asset = _assetOf(token);
        if (asset.totalSupply() == 0) return WAD;
        return xr = uint256(asset.liability()).wdiv(uint256(asset.totalSupply()));
    }

    function globalEquilCovRatio() public view returns (int256 equilCovRatio, int256 invariant) {
        int256 SL;
        (invariant, SL) = _globalInvariantFunc();
        equilCovRatio = CoreV3.equilCovRatio(invariant, SL, ampFactor.toInt256());
    }

    function tipBucketBalance(address token) public view returns (uint256 balance) {
        IAsset asset = _assetOf(token);
        return
            asset.underlyingTokenBalance().toWad(asset.underlyingTokenDecimals()) - asset.cash() - _feeCollected[asset];
    }

    /* Utils */

    /**
     * @dev to be overriden by DynamicPool to weight assets by the price of underlying token
     */
    function _globalInvariantFunc() internal view virtual returns (int256 D, int256 SL) {
        int256 A = ampFactor.toInt256();

        for (uint256 i; i < _sizeOfAssetList(); ++i) {
            IAsset asset = _getAsset(_getKeyAtIndex(i));

            // overflow is unrealistic
            int256 A_i = int256(uint256(asset.cash()));
            int256 L_i = int256(uint256(asset.liability()));

            // Assume when L_i == 0, A_i always == 0
            if (L_i == 0) {
                // avoid division of 0
                continue;
            }

            int256 r_i = A_i.wdiv(L_i);
            SL += L_i;
            D += L_i.wmul(r_i - A.wdiv(r_i));
        }
    }

    /**
     * For stable pools and rather-stable pools, r* is assumed to be 1 to simplify calculation
     */
    function _getGlobalEquilCovRatioForDepositWithdrawal() internal view virtual returns (int256 equilCovRatio) {
        return WAD_I;
    }

    function _mintFeeIfNeeded(IAsset asset) internal {
        uint256 feeCollected = _feeCollected[asset];
        if (feeCollected == 0 || feeCollected < mintFeeThreshold) {
            return;
        } else {
            _mintFee(asset);
        }
    }

    /**
     * @notice Private function to send fee collected to the fee beneficiary
     * @param asset The address of the asset to collect fee
     */
    function _mintFee(IAsset asset) internal returns (uint256 feeCollected) {
        feeCollected = _feeCollected[asset];
        if (feeCollected == 0) {
            // early return
            return 0;
        }
        {
            // dividend to veWOM
            uint256 dividend = feeCollected.wmul(WAD - lpDividendRatio - retentionRatio);

            if (dividend > 0) {
                asset.transferUnderlyingToken(feeTo, dividend.fromWad(asset.underlyingTokenDecimals()));
            }
        }
        {
            // dividend to LP
            uint256 lpDividend = feeCollected.wmul(lpDividendRatio);
            if (lpDividend > 0) {
                // exact deposit to maintain r* = 1
                // increase the value of the LP token, i.e. assetsPerShare
                (, uint256 liabilityToMint) = CoreV3.quoteDepositLiquidity(
                    asset,
                    lpDividend,
                    ampFactor,
                    _getGlobalEquilCovRatioForDepositWithdrawal()
                );
                asset.addLiability(liabilityToMint);
                asset.addCash(lpDividend);
            }
        }
        // remainings are sent to the tipbucket

        _feeCollected[asset] = 0;
    }

    function _mintAllFees() internal {
        for (uint256 i; i < _sizeOfAssetList(); ++i) {
            IAsset asset = _getAsset(_getKeyAtIndex(i));
            _mintFee(asset);
        }
    }

    /**
     * @notice Send fee collected to the fee beneficiary
     * @param token The address of the token to collect fee
     */
    function mintFee(address token) external returns (uint256 feeCollected) {
        return _mintFee(_assetOf(token));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

import './DynamicPoolV3.sol';

/**
 * @title Volatile Pool
 * @notice Manages deposits, withdrawals and swaps for volatile pool with external oracle
 */
contract VolatilePool is DynamicPoolV3 {
    /// @notice Whether to cap the global equilibrium coverage ratio at 1 for deposit and withdrawal
    bool public shouldCapEquilCovRatio;

    uint256[50] private __gap;

    function initialize(uint256 ampFactor_, uint256 haircutRate_) public override {
        super.initialize(ampFactor_, haircutRate_);
        shouldCapEquilCovRatio = true;
    }

    function setShouldCapEquilCovRatio(bool shouldCapEquilCovRatio_) external onlyOwner {
        shouldCapEquilCovRatio = shouldCapEquilCovRatio_;
    }

    /// @dev enable floating r*, deposit and withdrawal amount should be adjusted by r*
    function _getGlobalEquilCovRatioForDepositWithdrawal() internal view override returns (int256 equilCovRatio) {
        (equilCovRatio, ) = globalEquilCovRatio();
        if (equilCovRatio > WAD_I && shouldCapEquilCovRatio) {
            // Cap r* at 1 for deposit and withdrawal
            equilCovRatio = WAD_I;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '../libraries/Adaptor.sol';
import '../interfaces/IWormholeReceiver.sol';
import '../interfaces/IWormholeRelayer.sol';
import '../interfaces/IWormhole.sol';

/// @title WormholeAdaptor
/// @notice `WormholeAdaptor` uses the generic relayer of wormhole to send message across different networks
contract WormholeAdaptor is IWormholeReceiver, Adaptor {
    struct CrossChainPoolData {
        uint256 creditAmount;
        address toToken;
        uint256 minimumToAmount;
        address receiver;
    }

    IWormholeRelayer public relayer;
    IWormhole public wormhole;

    /// @dev wormhole chainId => adaptor address
    mapping(uint16 => address) public adaptorAddress;

    /// @dev hash => is message delivered
    mapping(bytes32 => bool) public deliveredMessage;

    event UnknownEmitter(address emitterAddress, uint16 sourceChain);
    event SetAdaptorAddress(uint16 wormholeChainId, address adaptorAddress);

    error ADAPTOR__MESSAGE_ALREADY_DELIVERED(bytes32 _hash);

    function initialize(
        IWormholeRelayer _relayer,
        IWormhole _wormhole,
        ICrossChainPool _crossChainPool
    ) public virtual initializer {
        relayer = _relayer;
        wormhole = _wormhole;

        __Adaptor_init(_crossChainPool);
    }

    /**
     * External/public functions
     */

    /**
     * @notice A convinience function to redeliver
     * @dev Redeliver could actually be invoked permisionless on any of the chain that wormhole supports
     * Delivery fee attached to the txn should be done off-chain via `WormholeAdaptor.estimateRedeliveryFee` to reduce gas cost
     *
     * *** This will only be able to succeed if the following is true **
     *         - (For EVM_V1) newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - (For EVM_V1) newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function requestResend(
        uint16 sourceChain, // wormhole chain ID
        uint64 sequence, // wormhole message sequence
        uint16 targetChain, // wormhole chain ID
        uint256 newReceiverValue,
        uint256 newGasLimit
    ) external payable {
        VaaKey memory deliveryVaaKey = VaaKey(
            sourceChain,
            _ethAddrToWormholeAddr(address(relayer)), // use the relayer address
            sequence
        );
        relayer.resendToEvm{value: msg.value}(
            deliveryVaaKey, // VaaKey memory deliveryVaaKey
            targetChain, // uint16 targetChain
            newReceiverValue, // uint256 newReceiverValue
            newGasLimit, // uint256 newGasLimit
            relayer.getDefaultDeliveryProvider() // address newDeliveryProviderAddress
        );
    }

    /**
     * Permisioneed functions
     */

    /**
     * @dev core relayer is assumed to be trusted so re-entrancy protection is not required
     * Note: This function should NOT throw; Otherwise it will result in a delivery failure
     * Assumptions to the wormhole relayer:
     *   - The message should deliver typically within 5 minutes
     *   - Unused gas should be refunded to the refundAddress
     *   - The target chain id and target contract address is verified
     * Things to be aware of:
     *   - VAA are not verified, order of message can be changed
     *   - deliveries can potentially performed multiple times
     * (ref: https://book.wormhole.com/technical/evm/relayer.html#delivery-failures)
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory /* additionalVaas */,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable override {
        // Only the core relayer can invoke this function
        // Verify the sender as there are trust assumptions to the generic relayer
        require(msg.sender == address(relayer), 'not authorized');

        // only accept messages from a trusted chain & contract
        // Assumption: the core relayer must verify the target chain ID and target contract address
        address sourAddr = _wormholeAddrToEthAddr(sourceAddress);
        if (adaptorAddress[sourceChain] != sourAddr) {
            emit UnknownEmitter(sourAddr, sourceChain);
            return;
        }

        // Important note: While Wormhole is in beta, the selected RelayProvider can potentially
        // reorder, omit, or mix-and-match VAAs if they were to behave maliciously
        _recordMessageHash(deliveryHash);

        (address toToken, uint256 creditAmount, uint256 minimumToAmount, address receiver) = _decode(payload);

        // transfer receiver value to the `receiver`
        (bool success, ) = receiver.call{value: msg.value}(new bytes(0));
        require(success, 'WormholeAdaptor: failed to send receiver value');

        _swapCreditForTokens(sourceChain, sourAddr, toToken, creditAmount, minimumToAmount, receiver);
    }

    function setAdaptorAddress(uint16 wormholeChainId, address addr) external onlyOwner {
        adaptorAddress[wormholeChainId] = addr;
        emit SetAdaptorAddress(wormholeChainId, addr);
    }

    /**
     * Internal functions
     */

    function _recordMessageHash(bytes32 _hash) internal {
        // revert if the message is already delivered
        if (deliveredMessage[_hash]) revert ADAPTOR__MESSAGE_ALREADY_DELIVERED(_hash);
        deliveredMessage[_hash] = true;
    }

    function _bridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain, // wormhole chain ID
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 deliveryGasLimit
    ) internal override returns (uint256 sequence) {
        // Delivery fee attached to the txn is done off-chain via `estimateDeliveryFee` to reduce gas cost
        // Unused `deliveryGasLimit` is sent to the `refundAddress` (`receiver`).

        require(toChain <= type(uint16).max, 'invalid chain ID');

        // (emitterChainID, emitterAddress, sequence) is used to retrive the generated VAA from the Guardian Network and for tracking
        sequence = relayer.sendPayloadToEvm{value: msg.value}(
            uint16(toChain), // uint16 targetChain
            adaptorAddress[uint16(toChain)], // address targetAddress
            _encode(toToken, fromAmount, minimumToAmount, receiver), // bytes memory payload
            receiverValue, // uint256 receiverValue
            deliveryGasLimit, // uint256 gasLimit
            uint16(toChain), // uint16 refundChain
            receiver // address refundAddress
        );
    }

    /**
     * Read-only functions
     */

    /**
     * @notice Estimate the amount of message value required to deliver a message with given `deliveryGasLimit` and `receiveValue`
     * A buffer should be added to `deliveryGasLimit` in case the amount of gas required is higher than the expectation
     * @param toChain wormhole chain ID
     * @param deliveryGasLimit gas limit of the callback function on the designated network
     * @param receiverValue target amount of gas token to receive
     * @dev Note that this function may fail if the value requested is too large. Using deliveryGasLimit 200000 is typically enough
     */
    function estimateDeliveryFee(
        uint16 toChain,
        uint256 receiverValue,
        uint32 deliveryGasLimit
    ) external view returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused) {
        return relayer.quoteEVMDeliveryPrice(toChain, receiverValue, deliveryGasLimit);
    }

    function estimateRedeliveryFee(
        uint16 toChain,
        uint256 receiverValue,
        uint32 deliveryGasLimit
    ) external view returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused) {
        return relayer.quoteEVMDeliveryPrice(toChain, receiverValue, deliveryGasLimit);
    }

    function _wormholeAddrToEthAddr(bytes32 addr) internal pure returns (address) {
        require(address(uint160(uint256(addr))) != address(0), 'addr bytes cannot be zero');
        return address(uint160(uint256(addr)));
    }

    function _ethAddrToWormholeAddr(address addr) internal pure returns (bytes32) {
        require(addr != address(0), 'addr cannot be zero');
        return bytes32(uint256(uint160(addr)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import '../../pool/CrossChainPool.sol';
import '../../pool/HighCovRatioFeePoolV3.sol';
import '../../interfaces/IAdaptor.sol';
import '../../interfaces/ICrossChainPool.sol';

/**
 * This is a fake Pool that implements swap with swapTokensForCredit and swapCreditForTokens.
 * This lets us verify the behaviour of quoteSwap and swap has not changed in our cross-chain implementation.
 */
contract FakeCrossChainPool is CrossChainPool {
    using DSMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 /*deadline*/
    ) external override nonReentrant whenNotPaused returns (uint256 actualToAmount, uint256 haircut) {
        IAsset fromAsset = _assetOf(fromToken);

        (uint256 creditAmount, uint256 haircut1) = _swapTokensForCredit(
            fromAsset,
            fromAmount.toWad(fromAsset.underlyingTokenDecimals()),
            0
        );

        uint256 haircut2;
        (actualToAmount, haircut2) = _doSwapCreditForTokens(toToken, creditAmount, minimumToAmount, to);

        haircut = haircut1 + haircut2;
        IERC20(fromToken).safeTransferFrom(msg.sender, address(fromAsset), fromAmount);
    }

    // Override and pass, to reduce contract size
    function quotePotentialWithdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity
    ) external view override returns (uint256 finalAmount, uint256 withdrewAmount) {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/math/SignedMath.sol';
import '../../pool/CoreV3.sol';

contract CoreV3Invariant {
    // Check that exactDepositLiquidityImpl return the same value as exactDepositLiquidityInEquilImpl when r* = 1.
    function testGeneralDeposit(
        uint256 margin,
        int256 amount,
        int256 cash,
        int256 liability,
        int256 ampFactor
    ) public pure {
        int256 expected = CoreV3.exactDepositLiquidityInEquilImpl(amount, cash, liability, ampFactor);
        int256 actual = CoreV3.exactDepositLiquidityImpl(amount, cash, liability, ampFactor, 1 ether);
        require(
            SignedMath.abs(expected - actual) <= margin,
            string(
                abi.encodePacked(
                    'expected: ',
                    Strings.toString(uint256(expected)),
                    ' but got: ',
                    Strings.toString(uint256(actual))
                )
            )
        );
    }

    // This verifies the following invariant:
    //   OldDeposit = NewDeposit * r
    // where OldDeposit is calculated at r* = 1 and NewDeposit is calculated at r* = r.
    function testGeneralDepositWithCoverageRatio(
        uint256 margin,
        int256 amount,
        int256 cash,
        int256 liability,
        int256 ampFactor
    ) public pure {
        int256 coverageRatio = (1 ether * cash) / liability;
        int256 expected = CoreV3.exactDepositLiquidityInEquilImpl(amount, liability, liability, ampFactor);
        int256 actual = (CoreV3.exactDepositLiquidityImpl(amount, cash, liability, ampFactor, coverageRatio) *
            coverageRatio) / 1 ether;
        require(
            SignedMath.abs(expected - actual) <= margin,
            string(
                abi.encodePacked(
                    'expected: ',
                    Strings.toString(uint256(expected)),
                    ' but got: ',
                    Strings.toString(uint256(actual)),
                    ' at coverage ratio: ',
                    Strings.toString(uint256(coverageRatio))
                )
            )
        );
    }

    // Check that withdrawalAmountImpl return the same value as withdrawalAmountInEquilImpl when r* = 1.
    function testGeneralWithdraw(
        uint256 margin,
        int256 amount,
        int256 cash,
        int256 liability,
        int256 ampFactor
    ) public pure {
        int256 expected = CoreV3.withdrawalAmountInEquilImpl(amount, cash, liability, ampFactor);
        int256 actual = CoreV3.withdrawalAmountImpl(amount, cash, liability, ampFactor, 1 ether);
        require(
            SignedMath.abs(expected - actual) <= margin,
            string(
                abi.encodePacked(
                    'expected: ',
                    Strings.toString(uint256(expected)),
                    ' but got: ',
                    Strings.toString(uint256(actual))
                )
            )
        );
    }

    // This verifies the following invariant:
    //   OldWithdrawals = NewWithdrawals / r
    // where OldWithdrawals is calculated at r* = 1 and NewWithdrawals is calculated at r* = r.
    function testGeneralWithdrawWithCoverageRatio(
        uint256 margin,
        int256 amount,
        int256 cash,
        int256 liability,
        int256 ampFactor
    ) public pure {
        int256 coverageRatio = (1 ether * cash) / liability;
        int256 expected = CoreV3.withdrawalAmountInEquilImpl(amount, liability, liability, ampFactor);
        int256 actual = (CoreV3.withdrawalAmountImpl(amount, cash, liability, ampFactor, coverageRatio) * 1 ether) /
            coverageRatio;
        require(
            SignedMath.abs(expected - actual) <= margin,
            string(
                abi.encodePacked(
                    'expected: ',
                    Strings.toString(uint256(expected)),
                    ' but got: ',
                    Strings.toString(uint256(actual)),
                    ' at coverage ratio: ',
                    Strings.toString(uint256(coverageRatio))
                )
            )
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import '../libraries/Adaptor.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract MockAdaptor is Adaptor {
    struct CrossChainPoolData {
        uint256 creditAmount;
        address toToken;
        uint256 minimumToAmount;
        address receiver;
    }

    struct DeliverData {
        address deliverAddr;
        bytes data;
    }

    struct DeliveryRequest {
        uint256 id;
        uint16 sourceChain;
        address sourceAddress;
        uint16 targetChain;
        address targetAddress;
        DeliverData deliverData; //Has the gas limit to execute with
    }

    uint16 public chainId;
    uint256 public nonceCounter;

    // nonce => message
    mapping(uint256 => DeliveryRequest) public messages;

    // fromChain => nonce => processed
    mapping(uint256 => mapping(uint256 => bool)) public messageDelivered;

    function initialize(uint16 _mockChainId, ICrossChainPool _crossChainPool) external virtual initializer {
        __Adaptor_init(_crossChainPool);

        chainId = _mockChainId;
        nonceCounter = 1; // use non-zero value
    }

    function _bridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 receiverValue,
        uint256 gasLimit
    ) internal override returns (uint256 trackingId) {
        CrossChainPoolData memory crossChainPoolData = CrossChainPoolData({
            creditAmount: fromAmount,
            toToken: toToken,
            minimumToAmount: minimumToAmount,
            receiver: receiver
        });

        bytes memory data = abi.encode(crossChainPoolData);
        DeliverData memory deliverData = DeliverData({deliverAddr: address(0), data: data});
        uint256 nonce = nonceCounter++;
        messages[nonce] = DeliveryRequest({
            id: nonce,
            sourceChain: chainId,
            sourceAddress: address(this),
            targetChain: uint16(toChain),
            targetAddress: address(0),
            deliverData: deliverData
        });
        return (trackingId << 16) + nonce;
    }

    /* Message receiver, should be invoked by the bridge */

    function deliver(
        uint256 id,
        uint16 fromChain,
        address fromAddr,
        uint16 targetChain,
        address targetAddress,
        DeliverData calldata deliverData
    ) external returns (bool success, uint256 amount) {
        require(targetChain == chainId, 'targetChain invalid');
        require(!messageDelivered[fromChain][id], 'message delivered');

        messageDelivered[fromChain][id] = true;

        CrossChainPoolData memory data = abi.decode(deliverData.data, (CrossChainPoolData));
        return
            _swapCreditForTokens(
                fromChain,
                fromAddr,
                data.toToken,
                data.creditAmount,
                data.minimumToAmount,
                data.receiver
            );
    }

    function faucetCredit(uint256 creditAmount) external {
        crossChainPool.mintCredit(creditAmount, msg.sender);
    }

    function encode(
        address toToken,
        uint256 creditAmount,
        uint256 minimumToAmount,
        address receiver
    ) external pure returns (bytes memory) {
        return _encode(toToken, creditAmount, minimumToAmount, receiver);
    }

    function decode(
        bytes memory encoded
    ) external pure returns (address toToken, uint256 creditAmount, uint256 minimumToAmount, address receiver) {
        return _decode(encoded);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import '../libraries/Adaptor.sol';
import '../interfaces/IWormholeRelayer.sol';
import '../interfaces/IWormholeReceiver.sol';

/// @notice A mock Wormhole Relayer that implements the `IWormholeRelayer` interface
/// @dev This is a fake WormholeRelayer that delivers messages to the CrossChainPool. It receives messages from the fake Wormhole.
/// The main usage is the `deliver` method.
contract MockRelayer {
    uint256 constant gasMultiplier = 1e10;
    uint256 constant sendGasOverhead = 0.01 ether;

    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence) {
        require(msg.value == 0.001 ether + gasLimit + receiverValue, 'Invalid funds');
    }

    function deliver(
        IWormholeReceiver target,
        bytes calldata payload,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external {
        target.receiveWormholeMessages(payload, new bytes[](0), sourceAddress, sourceChain, deliveryHash);
    }

    function resend(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        uint256 newGasLimit,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence) {}

    function quoteGas(
        uint16 targetChain,
        uint32 gasLimit,
        address relayProvider
    ) external pure returns (uint256 maxTransactionFee) {
        return gasLimit * gasMultiplier + sendGasOverhead;
    }

    function quoteGasResend(
        uint16 targetChain,
        uint32 gasLimit,
        address relayProvider
    ) external pure returns (uint256 maxTransactionFee) {
        return gasLimit * gasMultiplier;
    }

    function quoteReceiverValue(
        uint16 targetChain,
        uint256 targetAmount,
        address relayProvider
    ) external pure returns (uint256 receiverValue) {
        return targetAmount * gasMultiplier;
    }

    function toWormholeFormat(address addr) external pure returns (bytes32 whFormat) {}

    function fromWormholeFormat(bytes32 whFormatAddress) external pure returns (address addr) {}

    function getDefaultRelayProvider() external view returns (address relayProvider) {}

    function getDefaultRelayParams() external pure returns (bytes memory relayParams) {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import './libraries/DSMath.sol';
import './interfaces/IVeWom.sol';
import './interfaces/IVoter.sol';
import './interfaces/IBribeRewarderFactory.sol';
import './interfaces/IBoostedMasterWombat.sol';
import './interfaces/IBoostedMultiRewarder.sol';
import './interfaces/IMultiRewarder.sol';

/// @title BoostedMasterWombat
/// @notice MasterWombat is a boss. He is not afraid of any snakes. In fact, he drinks their venoms. So, veWom holders boost
/// their (boosted) emissions. This contract rewards users in function of their amount of lp staked (base pool) factor (boosted pool)
/// Factor and sumOfFactors are updated by contract VeWom.sol after any veWom minting/burning (veERC20Upgradeable hook).
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Wombat is sufficiently
/// distributed and the community can show to govern itself.
/// @dev Updates:
/// - Compatible with gauge voting
/// - Add support for BoostedMultiRewarder
contract BoostedMasterWombat is
    IBoostedMasterWombat,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // Use `Native` for generic purpose
    string internal constant NATIVE_TOKEN_SYMBOL = 'Native';

    // Info of each user.
    struct UserInfo {
        // storage slot 1
        uint128 amount; // 20.18 fixed point. How many LP tokens the user has provided.
        uint128 factor; // 20.18 fixed point. boosted factor = sqrt (lpAmount * veWom.balanceOf())
        // storage slot 2
        uint128 rewardDebt; // 20.18 fixed point. Reward debt. See explanation below.
        uint128 pendingWom; // 20.18 fixed point. Amount of pending wom
        //
        // We do some fancy math here. Basically, any point in time, the amount of WOMs
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accWomPerShare + user.factor * pool.accWomPerFactorShare) / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accWomPerShare`, `accWomPerFactorShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfoV3 {
        IERC20 lpToken; // Address of LP token contract.
        ////
        IMultiRewarder rewarder; // This rewarder will be deprecated, please also refer to the mapping of boostedRewarders
        uint40 periodFinish;
        ////
        uint128 sumOfFactors; // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
        uint128 rewardRate; // 20.18 fixed point.
        ////
        uint104 accWomPerShare; // 19.12 fixed point. Accumulated WOM per share, times 1e12.
        uint104 accWomPerFactorShare; // 19.12 fixed point. Accumulated WOM per factor share
        uint40 lastRewardTimestamp;
    }

    uint256 public constant REWARD_DURATION = 7 days;
    uint256 public constant ACC_TOKEN_PRECISION = 1e12;
    uint256 public constant TOTAL_PARTITION = 1000;

    // Wom token
    IERC20 public wom;
    // Venom does not seem to hurt the Wombat, it only makes it stronger.
    IVeWom public veWom;
    // New Master Wombat address for future migrations
    IMasterWombatV3 newMasterWombat;
    // Address of Voter
    address public voter;
    // Base partition emissions (e.g. 300 for 30%).
    // BasePartition and boostedPartition add up to TOTAL_PARTITION (1000) for 100%
    uint16 public basePartition;
    // Set of all LP tokens that have been added as pools
    EnumerableSet.AddressSet internal lpTokens;
    /// @notice Info of each pool.
    /// @dev Note that `poolInfoV3[pid].rewarder` will be deprecated and it may co-exist with boostedRewarders[pid]
    PoolInfoV3[] public poolInfoV3;
    // userInfo[pid][user], Info of each user that stakes LP tokens
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Mapping of asset to pid. Offset by +1 to distinguish with default value
    mapping(address => uint256) internal assetPid;
    // pid => address of boostedRewarder
    mapping(uint256 => IBoostedMultiRewarder) public override boostedRewarders;

    IBribeRewarderFactory public bribeRewarderFactory;

    event Add(uint256 indexed pid, IERC20 indexed lpToken, IBoostedMultiRewarder boostedRewarder);
    event SetNewMasterWombat(IMasterWombatV3 masterWormbat);
    event SetBribeRewarderFactory(IBribeRewarderFactory bribeRewarderFactory);
    event SetRewarder(uint256 indexed pid, IMultiRewarder rewarder);
    event SetBoostedRewarder(uint256 indexed pid, IBoostedMultiRewarder boostedRewarder);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositFor(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionPartition(address indexed user, uint256 basePartition, uint256 boostedPartition);
    event UpdateVeWOM(address indexed user, address oldVeWOM, address newVeWOM);
    event UpdateVoter(address indexed user, address oldVoter, address newVoter);
    event EmergencyWomWithdraw(address owner, uint256 balance);

    /// @dev Modifier ensuring that certain function can only be called by VeWom
    modifier onlyVeWom() {
        require(address(veWom) == msg.sender, 'MasterWombat: caller is not VeWom');
        _;
    }

    /// @dev Modifier ensuring that certain function can only be called by Voter
    modifier onlyVoter() {
        require(address(voter) == msg.sender, 'MasterWombat: caller is not Voter');
        _;
    }

    function initialize(IERC20 _wom, IVeWom _veWom, address _voter, uint16 _basePartition) external initializer {
        require(address(_wom) != address(0), 'wom address cannot be zero');
        require(_basePartition <= TOTAL_PARTITION, 'base partition must be in range 0, 1000');

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        wom = _wom;
        veWom = _veWom;
        voter = _voter;
        basePartition = _basePartition;
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setNewMasterWombat(IMasterWombatV3 _newMasterWombat) external onlyOwner {
        newMasterWombat = _newMasterWombat;
        emit SetNewMasterWombat(_newMasterWombat);
    }

    function setBribeRewarderFactory(IBribeRewarderFactory _bribeRewarderFactory) external onlyOwner {
        bribeRewarderFactory = _bribeRewarderFactory;
        emit SetBribeRewarderFactory(_bribeRewarderFactory);
    }

    /// @notice Add a new lp to the pool. Can only be called by the owner.
    /// @dev Reverts if the same LP token is added more than once.
    /// @param _lpToken the corresponding lp token
    /// @param _boostedRewarder the rewarder
    function add(IERC20 _lpToken, IBoostedMultiRewarder _boostedRewarder) external onlyOwner {
        require(Address.isContract(address(_lpToken)), 'add: LP token must be a valid contract');
        require(
            Address.isContract(address(_boostedRewarder)) || address(_boostedRewarder) == address(0),
            'add: boostedRewarder must be contract or zero'
        );
        require(!lpTokens.contains(address(_lpToken)), 'add: LP already added');

        // update PoolInfoV3 with the new LP
        poolInfoV3.push(
            PoolInfoV3({
                lpToken: _lpToken,
                lastRewardTimestamp: uint40(block.timestamp),
                accWomPerShare: 0,
                rewarder: IMultiRewarder(address(0)),
                accWomPerFactorShare: 0,
                sumOfFactors: 0,
                periodFinish: uint40(block.timestamp),
                rewardRate: 0
            })
        );
        uint256 pid = poolInfoV3.length - 1;
        assetPid[address(_lpToken)] = pid + 1; // offset by +1
        boostedRewarders[pid] = _boostedRewarder;

        // add lpToken to the lpTokens enumerable set
        lpTokens.add(address(_lpToken));
        emit Add(pid, _lpToken, _boostedRewarder);
    }

    /// @notice Update the given pool's boostedRewarder
    /// @param _pid the pool id
    /// @param _boostedRewarder the boostedRewarder
    function setBoostedRewarder(uint256 _pid, IBoostedMultiRewarder _boostedRewarder) external override {
        require(msg.sender == address(bribeRewarderFactory) || msg.sender == owner(), 'not authorized');
        require(
            Address.isContract(address(_boostedRewarder)) || address(_boostedRewarder) == address(0),
            'set: boostedRewarder must be contract or zero'
        );

        boostedRewarders[_pid] = _boostedRewarder;
        emit SetBoostedRewarder(_pid, _boostedRewarder);
    }

    /// @notice Update the given pool's rewarder
    /// @param _pid the pool id
    /// @param _rewarder the rewarder
    function setRewarder(uint256 _pid, IMultiRewarder _rewarder) external onlyOwner {
        require(
            Address.isContract(address(_rewarder)) || address(_rewarder) == address(0),
            'set: rewarder must be contract or zero'
        );

        PoolInfoV3 storage pool = poolInfoV3[_pid];

        pool.rewarder = _rewarder;
        emit SetRewarder(_pid, _rewarder);
    }

    /// @notice Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() public override {
        uint256 length = poolInfoV3.length;
        for (uint256 pid; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool
    /// @param _pid the pool id
    function updatePool(uint256 _pid) external override {
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) private {
        PoolInfoV3 storage pool = poolInfoV3[_pid];

        if (block.timestamp > pool.lastRewardTimestamp) {
            (uint256 accWomPerShare, uint256 accWomPerFactorShare) = calRewardPerUnit(_pid);
            pool.accWomPerShare = to104(accWomPerShare);
            pool.accWomPerFactorShare = to104(accWomPerFactorShare);
            pool.lastRewardTimestamp = uint40(lastTimeRewardApplicable(pool.periodFinish));

            // We can consider to skip this function to minimize gas
            // voter address can be zero during a migration. See comment in setVoter.
            if (voter != address(0)) {
                IVoter(voter).distribute(pool.lpToken);
            }
        }
    }

    /// @notice Distribute WOM over a period of 7 days
    /// @dev Refer to synthetix/StakingRewards.sol notifyRewardAmount
    /// Note: This looks safe from reentrancy.
    function notifyRewardAmount(address _lpToken, uint256 _amount) external override onlyVoter {
        require(_amount > 0, 'notifyRewardAmount: zero amount');

        // this line reverts if asset is not in the list
        uint256 pid = assetPid[_lpToken] - 1;
        PoolInfoV3 storage pool = poolInfoV3[pid];
        if (pool.lastRewardTimestamp >= pool.periodFinish) {
            pool.rewardRate = to128(_amount / REWARD_DURATION);
        } else {
            uint256 remainingTime = pool.periodFinish - pool.lastRewardTimestamp;
            uint256 leftoverReward = remainingTime * pool.rewardRate;
            pool.rewardRate = to128((_amount + leftoverReward) / REWARD_DURATION);
        }

        pool.lastRewardTimestamp = uint40(block.timestamp);
        pool.periodFinish = uint40(block.timestamp + REWARD_DURATION);

        // Event is not emitted as Voter should have already emitted it
    }

    /// @notice Helper function to migrate fund from multiple pools to the new MasterWombat.
    /// @notice user must initiate transaction from masterchef
    /// @dev Assume the orginal MasterWombat has stopped emisions
    /// hence we skip IVoter(voter).distribute() to save gas cost
    function migrate(uint256[] calldata _pids) external override nonReentrant {
        require(address(newMasterWombat) != (address(0)), 'to where?');

        _multiClaim(_pids);
        for (uint256 i; i < _pids.length; ++i) {
            uint256 pid = _pids[i];
            UserInfo storage user = userInfo[pid][msg.sender];

            if (user.amount > 0) {
                PoolInfoV3 storage pool = poolInfoV3[pid];
                pool.lpToken.approve(address(newMasterWombat), user.amount);
                uint256 newPid = newMasterWombat.getAssetPid(address(pool.lpToken));
                newMasterWombat.depositFor(newPid, user.amount, msg.sender);

                pool.sumOfFactors -= user.factor;
                // remove user
                delete userInfo[pid][msg.sender];
            }
        }
    }

    /// @notice Deposit LP tokens to MasterChef for WOM allocation on behalf of user
    /// @dev user must initiate transaction from masterchef
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    /// @param _user the user being represented
    function depositFor(uint256 _pid, uint256 _amount, address _user) external override nonReentrant whenNotPaused {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // update pool in case user has deposited
        _updatePool(_pid);

        // update rewarders before we update lpSupply and sumOfFactors
        _updateUserAmount(_pid, _user, user.amount + _amount);

        // safe transfer is not needed for Asset
        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        emit DepositFor(_user, _pid, _amount);
    }

    /// @notice Deposit LP tokens to MasterChef for WOM allocation.
    /// @dev it is possible to call this function with _amount == 0 to claim current rewards
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    function deposit(
        uint256 _pid,
        uint256 _amount
    ) external override nonReentrant whenNotPaused returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // update pool in case user has deposited
        _updatePool(_pid);

        // update rewarders before we update lpSupply and sumOfFactors
        (reward, additionalRewards) = _updateUserAmount(_pid, msg.sender, user.amount + _amount);

        // safe transfer is not needed for Asset
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice claims rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function multiClaim(
        uint256[] calldata _pids
    )
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 reward, uint256[] memory amounts, uint256[][] memory additionalRewards)
    {
        return _multiClaim(_pids);
    }

    /// @notice private function to claim rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function _multiClaim(
        uint256[] memory _pids
    ) private returns (uint256 reward, uint256[] memory amounts, uint256[][] memory additionalRewards) {
        // accumulate rewards for each one of the pids in pending
        amounts = new uint256[](_pids.length);
        additionalRewards = new uint256[][](_pids.length);
        for (uint256 i; i < _pids.length; ++i) {
            UserInfo storage user = userInfo[_pids[i]][msg.sender];
            _updatePool(_pids[i]);

            if (user.amount > 0) {
                PoolInfoV3 storage pool = poolInfoV3[_pids[i]];
                // increase pending to send all rewards once
                uint128 newRewardDebt = _getRewardDebt(
                    user.amount,
                    pool.accWomPerShare,
                    user.factor,
                    pool.accWomPerFactorShare
                );
                uint256 poolRewards = newRewardDebt + user.pendingWom - user.rewardDebt;

                user.pendingWom = 0;

                // update reward debt
                user.rewardDebt = newRewardDebt;

                // increase reward
                reward += poolRewards;

                amounts[i] = poolRewards;
                emit Harvest(msg.sender, _pids[i], amounts[i]);

                // if exist, update external rewarder
                IMultiRewarder rewarder = pool.rewarder;
                if (address(rewarder) != address(0)) {
                    additionalRewards[i] = rewarder.onReward(msg.sender, user.amount);
                }
                IBoostedMultiRewarder boostedRewarder = boostedRewarders[_pids[i]];
                if (address(boostedRewarder) != address(0)) {
                    // update rewarders before we update lpSupply and sumOfFactors
                    additionalRewards[i] = boostedRewarder.onReward(msg.sender, user.amount, user.factor);
                }
            }
        }

        // transfer all rewards
        // SafeERC20 is not needed as WOM will revert if transfer fails
        wom.transfer(payable(msg.sender), reward);
    }

    /// @notice Withdraw LP tokens from MasterWombat.
    /// @notice Automatically harvest pending rewards and sends to user
    /// @param _pid the pool id
    /// @param _amount the amount to withdraw
    function withdraw(
        uint256 _pid,
        uint256 _amount
    ) external override nonReentrant whenNotPaused returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, 'withdraw: not enough balance');

        _updatePool(_pid);

        // update rewarders before we update lpSupply and sumOfFactors
        (reward, additionalRewards) = _updateUserAmount(_pid, msg.sender, user.amount - _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Update user balance and distribute WOM rewards
    function _updateUserAmount(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) internal returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // Harvest WOM
        if (user.amount > 0 || user.pendingWom > 0) {
            reward =
                _getRewardDebt(user.amount, pool.accWomPerShare, user.factor, pool.accWomPerFactorShare) +
                user.pendingWom -
                user.rewardDebt;
            user.pendingWom = 0;

            // SafeERC20 is not needed as WOM will revert if transfer fails
            wom.transfer(payable(_user), reward);
            emit Harvest(_user, _pid, reward);
        }

        // update amount of lp staked
        uint256 oldUserAmount = user.amount;
        user.amount = to128(_amount);

        // update sumOfFactors
        uint256 oldFactor = user.factor;
        user.factor = to128(DSMath.sqrt(user.amount * veWom.balanceOf(_user), user.amount));

        // update reward debt
        user.rewardDebt = _getRewardDebt(_amount, pool.accWomPerShare, user.factor, pool.accWomPerFactorShare);

        // update rewarder before we update lpSupply and sumOfFactors
        // aggregate result from both rewardewrs
        IMultiRewarder rewarder = pool.rewarder;
        IBoostedMultiRewarder boostedRewarder = boostedRewarders[_pid];
        if (address(rewarder) != address(0) || address(boostedRewarder) != address(0)) {
            if (address(rewarder) == address(0)) {
                additionalRewards = boostedRewarder.onReward(_user, _amount, user.factor);
            } else if (address(boostedRewarder) == address(0)) {
                additionalRewards = rewarder.onReward(_user, _amount);
            } else {
                uint256[] memory temp1 = rewarder.onReward(_user, _amount);
                uint256[] memory temp2 = boostedRewarder.onReward(_user, _amount, user.factor);

                additionalRewards = concatArrays(temp1, temp2);
            }
        }

        pool.sumOfFactors = to128(pool.sumOfFactors + user.factor - oldFactor);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid the pool id
    function emergencyWithdraw(uint256 _pid) external override nonReentrant {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // update rewarders before we update lpSupply and sumOfFactors
        IMultiRewarder rewarder = poolInfoV3[_pid].rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(msg.sender, 0);
        }
        IBoostedMultiRewarder boostedRewarder = boostedRewarders[_pid];
        if (address(boostedRewarder) != address(0)) {
            boostedRewarder.onReward(msg.sender, 0, 0);
        }

        // safe transfer is not needed for Asset
        uint256 oldUserAmount = user.amount;
        pool.lpToken.transfer(address(msg.sender), oldUserAmount);

        pool.sumOfFactors = pool.sumOfFactors - user.factor;

        user.amount = 0;
        user.factor = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, _pid, oldUserAmount);
    }

    /// @notice updates emission partition
    /// @param _basePartition the future base partition
    function updateEmissionPartition(uint16 _basePartition) external onlyOwner {
        require(_basePartition <= TOTAL_PARTITION);
        massUpdatePools();
        basePartition = _basePartition;
        emit UpdateEmissionPartition(msg.sender, _basePartition, TOTAL_PARTITION - _basePartition);
    }

    /// @notice updates veWom address
    /// @param _newVeWom the new VeWom address
    function setVeWom(IVeWom _newVeWom) external onlyOwner {
        require(address(_newVeWom) != address(0));
        IVeWom oldVeWom = veWom;
        veWom = _newVeWom;
        emit UpdateVeWOM(msg.sender, address(oldVeWom), address(_newVeWom));
    }

    /// @notice updates voter address
    /// @param _newVoter the new Voter address
    function setVoter(address _newVoter) external onlyOwner {
        // voter address can be zero during a migration. This is done to avoid
        // the scenario where both old and new MasterWombat claims in migrate,
        // which calls voter.distribute. But only one can succeed as voter.distribute
        // is only callable from gauge manager.
        address oldVoter = voter;
        voter = _newVoter;
        emit UpdateVoter(msg.sender, oldVoter, _newVoter);
    }

    /// @notice updates factor after any veWom token operation (minting/burning)
    /// @param _user the user to update
    /// @param _newVeWomBalance the amount of veWOM
    /// @dev can only be called by veWom
    function updateFactor(address _user, uint256 _newVeWomBalance) external override onlyVeWom {
        // loop over each pool : beware gas cost!
        uint256 length = poolInfoV3.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            UserInfo storage user = userInfo[pid][_user];

            // skip if user doesn't have any deposit in the pool
            if (user.amount == 0) {
                continue;
            }

            // first, update pool
            _updatePool(pid);
            PoolInfoV3 storage pool = poolInfoV3[pid];

            // calculate pending
            uint256 pending = _getRewardDebt(user.amount, pool.accWomPerShare, user.factor, pool.accWomPerFactorShare) -
                user.rewardDebt;
            // increase pendingWom
            user.pendingWom += to128(pending);

            // update boosted partition factor
            uint256 oldFactor = user.factor;
            uint256 newFactor = DSMath.sqrt(user.amount * _newVeWomBalance, user.amount);
            user.factor = to128(newFactor);
            // update reward debt, take into account newFactor
            user.rewardDebt = _getRewardDebt(user.amount, pool.accWomPerShare, newFactor, pool.accWomPerFactorShare);

            // update boostedRewarder before we update sumOfFactors
            IBoostedMultiRewarder boostedRewarder = boostedRewarders[pid];
            if (address(boostedRewarder) != address(0)) {
                boostedRewarder.onUpdateFactor(_user, user.factor);
            }

            // also, update sumOfFactors
            pool.sumOfFactors = to128(pool.sumOfFactors + newFactor - oldFactor);
        }
    }

    /// @notice In case we need to manually migrate WOM funds from MasterChef
    /// Sends all remaining wom from the contract to the owner
    function emergencyWomWithdraw() external onlyOwner {
        // safe transfer is not needed for WOM
        wom.transfer(address(msg.sender), wom.balanceOf(address(this)));
        emit EmergencyWomWithdraw(address(msg.sender), wom.balanceOf(address(this)));
    }

    /**
     * Read-only functions
     */

    /// @notice Get bonus token info from the rewarder contract for a given pool, if it is a double reward farm
    /// @param _pid the pool id
    function rewarderBonusTokenInfo(
        uint256 _pid
    ) public view override returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols) {
        // aggregate result from both rewardewrs
        IMultiRewarder rewarder = poolInfoV3[_pid].rewarder;
        IBoostedMultiRewarder boostedRewarder = boostedRewarders[_pid];
        if (address(rewarder) != address(0) || address(boostedRewarder) != address(0)) {
            if (address(rewarder) == address(0)) {
                bonusTokenAddresses = boostedRewarder.rewardTokens();
            } else if (address(boostedRewarder) == address(0)) {
                bonusTokenAddresses = rewarder.rewardTokens();
            } else {
                IERC20[] memory temp1 = rewarder.rewardTokens();
                IERC20[] memory temp2 = boostedRewarder.rewardTokens();

                bonusTokenAddresses = concatArrays(temp1, temp2);
            }
        }

        uint256 len = bonusTokenAddresses.length;
        bonusTokenSymbols = new string[](len);
        for (uint256 i; i < len; ++i) {
            if (address(bonusTokenAddresses[i]) == address(0)) {
                bonusTokenSymbols[i] = NATIVE_TOKEN_SYMBOL;
            } else {
                bonusTokenSymbols[i] = IERC20Metadata(address(bonusTokenAddresses[i])).symbol();
            }
        }
    }

    function boostedPartition() external view returns (uint256) {
        return TOTAL_PARTITION - basePartition;
    }

    /// @notice returns pool length
    function poolLength() external view override returns (uint256) {
        return poolInfoV3.length;
    }

    function getAssetPid(address asset) external view override returns (uint256) {
        uint256 pidBeforeOffset = assetPid[asset];
        if (pidBeforeOffset == 0) revert('invalid pid');
        // revert if asset not exist
        return pidBeforeOffset - 1;
    }

    function lastTimeRewardApplicable(uint256 _periodFinish) public view returns (uint256) {
        return block.timestamp < _periodFinish ? block.timestamp : _periodFinish;
    }

    function calRewardPerUnit(uint256 _pid) public view returns (uint256 accWomPerShare, uint256 accWomPerFactorShare) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        accWomPerShare = pool.accWomPerShare;
        accWomPerFactorShare = pool.accWomPerFactorShare;

        if (lpSupply == 0 || block.timestamp <= pool.lastRewardTimestamp) {
            // update only if now > lastRewardTimestamp
            return (accWomPerShare, accWomPerFactorShare);
        }

        uint256 secondsElapsed = lastTimeRewardApplicable(pool.periodFinish) - pool.lastRewardTimestamp;
        uint256 womReward = secondsElapsed * pool.rewardRate;
        accWomPerShare += (womReward * ACC_TOKEN_PRECISION * basePartition) / (lpSupply * TOTAL_PARTITION);

        if (pool.sumOfFactors != 0) {
            accWomPerFactorShare +=
                (womReward * ACC_TOKEN_PRECISION * (TOTAL_PARTITION - basePartition)) /
                (pool.sumOfFactors * TOTAL_PARTITION);
        }
    }

    /// @notice View function to see pending WOMs on frontend.
    /// @param _pid the pool id
    /// @param _user the user address
    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        override
        returns (
            uint256 pendingRewards,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        )
    {
        // calculate accWomPerShare and accWomPerFactorShare
        (uint256 accWomPerShare, uint256 accWomPerFactorShare) = calRewardPerUnit(_pid);

        UserInfo storage user = userInfo[_pid][_user];
        pendingRewards =
            ((user.amount * accWomPerShare + user.factor * accWomPerFactorShare) / ACC_TOKEN_PRECISION) +
            user.pendingWom -
            user.rewardDebt;

        // If it's a double reward farm, return info about the bonus token
        (bonusTokenAddresses, bonusTokenSymbols) = rewarderBonusTokenInfo(_pid);

        // aggregate result from both rewardewrs
        IMultiRewarder rewarder = poolInfoV3[_pid].rewarder;
        IBoostedMultiRewarder boostedRewarder = boostedRewarders[_pid];
        if (address(rewarder) != address(0) || address(boostedRewarder) != address(0)) {
            if (address(rewarder) == address(0)) {
                pendingBonusRewards = boostedRewarder.pendingTokens(_user);
            } else if (address(boostedRewarder) == address(0)) {
                pendingBonusRewards = rewarder.pendingTokens(_user);
            } else {
                uint256[] memory temp1 = rewarder.pendingTokens(_user);
                uint256[] memory temp2 = boostedRewarder.pendingTokens(_user);

                pendingBonusRewards = concatArrays(temp1, temp2);
            }
        }
    }

    /// @notice [Deprecated] A backward compatible function to return the PoolInfo struct in MasterWombatV2
    function poolInfo(
        uint256 _pid
    )
        external
        view
        returns (
            IERC20 lpToken,
            uint96 allocPoint,
            IMultiRewarder rewarder,
            uint256 sumOfFactors,
            uint104 accWomPerShare,
            uint104 accWomPerFactorShare,
            uint40 lastRewardTimestamp
        )
    {
        PoolInfoV3 memory pool = poolInfoV3[_pid];

        return (
            pool.lpToken,
            0,
            pool.rewarder,
            pool.sumOfFactors,
            pool.accWomPerShare,
            pool.accWomPerFactorShare,
            pool.lastRewardTimestamp
        );
    }

    function getSumOfFactors(uint256 _pid) external view override returns (uint256) {
        return poolInfoV3[_pid].sumOfFactors;
    }

    function _getRewardDebt(
        uint256 amount,
        uint256 accWomPerShare,
        uint256 factor,
        uint256 accWomPerFactorShare
    ) internal pure returns (uint128) {
        return to128((amount * accWomPerShare + factor * accWomPerFactorShare) / ACC_TOKEN_PRECISION);
    }

    function concatArrays(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory returnArr) {
        returnArr = new uint256[](A.length + B.length);

        uint256 i;
        for (; i < A.length; i++) {
            returnArr[i] = A[i];
        }

        for (uint256 j; j < B.length; ) {
            returnArr[i++] = B[j++];
        }
    }

    function concatArrays(IERC20[] memory A, IERC20[] memory B) internal pure returns (IERC20[] memory returnArr) {
        returnArr = new IERC20[](A.length + B.length);

        uint256 i;
        for (; i < A.length; i++) {
            returnArr[i] = A[i];
        }

        for (uint256 j; j < B.length; ) {
            returnArr[i++] = B[j++];
        }
    }

    function to128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }

    function to104(uint256 val) internal pure returns (uint104) {
        if (val > type(uint104).max) revert('uint104 overflow');
        return uint104(val);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/proxy/beacon/IBeacon.sol';
import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '../../wombat-core/interfaces/IAsset.sol';
import '../interfaces/IBribeRewarderFactory.sol';
import '../interfaces/IBoostedMasterWombat.sol';
import '../interfaces/IVoter.sol';
import '../rewarders/BoostedMultiRewarder.sol';
import './BribeV2.sol';

contract BribeRewarderFactory is IBribeRewarderFactory, Initializable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IBoostedMasterWombat public masterWombat;
    IBeacon public rewarderBeacon;

    IVoter public voter;
    IBeacon public bribeBeacon;

    /// @notice Rewarder deployer is able to deploy rewarders, and it will become the rewarder operator
    mapping(IAsset => address) public rewarderDeployers;
    /// @notice Bribe deployer is able to deploy bribe, and it will become the bribe operator
    mapping(IAsset => address) public bribeDeployers;
    /// @notice whitelisted reward tokens can be added to rewarders and bribes
    EnumerableSet.AddressSet internal whitelistedRewardTokens;

    event DeployRewarderContract(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec,
        address rewarder
    );
    event SetRewarderContract(IAsset _lpToken, address rewarder);
    event SetRewarderBeacon(IBeacon beacon);
    event SetRewarderDeployer(IAsset token, address deployer);
    event DeployBribeContract(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec,
        address bribe
    );
    event SetBribeContract(IAsset _lpToken, address bribe);
    event SetBribeBeacon(IBeacon beacon);
    event SetBribeDeployer(IAsset token, address deployer);
    event WhitelistRewardTokenUpdated(IERC20 token, bool isAdded);

    function initialize(
        IBeacon _rewarderBeacon,
        IBeacon _bribeBeacon,
        IBoostedMasterWombat _masterWombat,
        IVoter _voter
    ) public initializer {
        require(Address.isContract(address(_rewarderBeacon)), 'initialize: _rewarderBeacon must be a valid contract');
        require(Address.isContract(address(_bribeBeacon)), 'initialize: _bribeBeacon must be a valid contract');
        require(Address.isContract(address(_masterWombat)), 'initialize: mw must be a valid contract');
        require(Address.isContract(address(_voter)), 'initialize: voter must be a valid contract');

        rewarderBeacon = _rewarderBeacon;
        bribeBeacon = _bribeBeacon;
        masterWombat = _masterWombat;
        voter = _voter;

        __Ownable_init();
    }

    function isRewardTokenWhitelisted(IERC20 _token) public view returns (bool) {
        return whitelistedRewardTokens.contains(address(_token));
    }

    function getWhitelistedRewardTokens() external view returns (address[] memory) {
        return whitelistedRewardTokens.values();
    }

    /// @notice Deploy bribe contract behind a beacon proxy, and add it to the voter
    function deployRewarderContractAndSetRewarder(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) external returns (address rewarder) {
        uint256 pid = masterWombat.getAssetPid(address(_lpToken));
        require(address(masterWombat.boostedRewarders(pid)) == address(0), 'rewarder contract alrealdy exists');

        rewarder = address(_deployRewarderContract(_lpToken, pid, _startTimestamp, _rewardToken, _tokenPerSec));
        masterWombat.setBoostedRewarder(pid, BoostedMultiRewarder(payable(rewarder)));
        emit SetRewarderContract(_lpToken, rewarder);
    }

    /// @notice Deploy bribe contract behind a beacon proxy, and add it to the voter
    function deployRewarderContract(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) external returns (address rewarder) {
        uint256 pid = masterWombat.getAssetPid(address(_lpToken));
        rewarder = address(_deployRewarderContract(_lpToken, pid, _startTimestamp, _rewardToken, _tokenPerSec));
    }

    function _deployRewarderContract(
        IAsset _lpToken,
        uint256 _pid,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) internal returns (BoostedMultiRewarder rewarder) {
        (, , , , , IGauge gaugeManager, ) = voter.infos(_lpToken);
        require(address(gaugeManager) != address(0), 'gauge does not exist');
        require(address(masterWombat.boostedRewarders(_pid)) == address(0), 'rewarder contract alrealdy exists');

        require(rewarderDeployers[_lpToken] == msg.sender, 'Not authurized.');
        require(isRewardTokenWhitelisted(_rewardToken), 'reward token is not whitelisted');

        // deploy a rewarder contract behind a proxy
        // BoostedMultiRewarder rewarder = new BoostedMultiRewarder()
        rewarder = BoostedMultiRewarder(payable(new BeaconProxy(address(rewarderBeacon), bytes(''))));

        rewarder.initialize(this, masterWombat, _lpToken, _startTimestamp, _rewardToken, _tokenPerSec);
        rewarder.addOperator(msg.sender);
        rewarder.transferOwnership(owner());

        emit DeployRewarderContract(_lpToken, _startTimestamp, _rewardToken, _tokenPerSec, address(rewarder));
    }

    /// @notice Deploy bribe contract behind a beacon proxy, and add it to the voter
    function deployBribeContractAndSetBribe(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) external returns (address bribe) {
        (, , , , bool whitelist, IGauge gaugeManager, IBribe currentBribe) = voter.infos(_lpToken);
        require(address(currentBribe) == address(0), 'bribe contract already exists for gauge');
        require(address(gaugeManager) != address(0), 'gauge does not exist');
        require(whitelist, 'bribe contract is paused');

        bribe = address(_deployBribeContract(_lpToken, _startTimestamp, _rewardToken, _tokenPerSec));
        voter.setBribe(_lpToken, IBribe(address(bribe)));
        emit SetBribeContract(_lpToken, bribe);
    }

    /// @notice Deploy bribe contract behind a beacon proxy, and add it to the voter
    function deployBribeContract(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) external returns (address bribe) {
        bribe = address(_deployBribeContract(_lpToken, _startTimestamp, _rewardToken, _tokenPerSec));
    }

    function _deployBribeContract(
        IAsset _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) internal returns (BribeV2 bribe) {
        (, , , , , IGauge gaugeManager, ) = voter.infos(_lpToken);
        require(address(gaugeManager) != address(0), 'gauge does not exist');

        require(bribeDeployers[_lpToken] == msg.sender, 'Not authurized.');
        require(isRewardTokenWhitelisted(_rewardToken), 'reward token is not whitelisted');

        // deploy a bribe contract behind a proxy
        // BribeV2 bribe = new BribeV2();
        bribe = BribeV2(payable(new BeaconProxy(address(bribeBeacon), bytes(''))));

        bribe.initialize(this, address(voter), _lpToken, _startTimestamp, _rewardToken, _tokenPerSec);
        bribe.addOperator(msg.sender);
        bribe.transferOwnership(owner());

        emit DeployBribeContract(_lpToken, _startTimestamp, _rewardToken, _tokenPerSec, address(bribe));
    }

    function setRewarderBeacon(IBeacon _rewarderBeacon) external onlyOwner {
        require(Address.isContract(address(_rewarderBeacon)), 'invalid address');
        rewarderBeacon = _rewarderBeacon;

        emit SetRewarderBeacon(_rewarderBeacon);
    }

    function setBribeBeacon(IBeacon _bribeBeacon) external onlyOwner {
        require(Address.isContract(address(_bribeBeacon)), 'invalid address');
        bribeBeacon = _bribeBeacon;

        emit SetBribeBeacon(_bribeBeacon);
    }

    function setRewarderDeployer(IAsset _token, address _deployer) external onlyOwner {
        require(rewarderDeployers[_token] != _deployer, 'already set as deployer');
        rewarderDeployers[_token] = _deployer;
        emit SetRewarderDeployer(_token, _deployer);
    }

    function setBribeDeployer(IAsset _token, address _deployer) external onlyOwner {
        require(bribeDeployers[_token] != _deployer, 'already set as deployer');
        bribeDeployers[_token] = _deployer;
        emit SetBribeDeployer(_token, _deployer);
    }

    function whitelistRewardToken(IERC20 _token) external onlyOwner {
        require(!isRewardTokenWhitelisted(_token), 'already whitelisted');
        whitelistedRewardTokens.add(address(_token));
        emit WhitelistRewardTokenUpdated(_token, true);
    }

    function revokeRewardToken(IERC20 _token) external onlyOwner {
        require(isRewardTokenWhitelisted(_token), 'reward token is not whitelisted');
        whitelistedRewardTokens.remove(address(_token));
        emit WhitelistRewardTokenUpdated(_token, false);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../interfaces/IBribeRewarderFactory.sol';
import '../interfaces/IBribe.sol';
import '../interfaces/IVoter.sol';
import '../rewarders/MultiRewarderPerSecV2.sol';

/**
 * Simple bribe per sec. Distribute bribe rewards to voters
 * Bribe.onVote->updateReward() is a bit different from SimpleRewarder.
 * Here we reduce the original total amount of share
 */
contract BribeV2 is IBribe, MultiRewarderPerSecV2 {
    using SafeERC20 for IERC20;

    function onVote(
        address _user,
        uint256 _newVote,
        uint256 _originalTotalVotes
    ) external override onlyMaster nonReentrant returns (uint256[] memory rewards) {
        _updateReward(_originalTotalVotes);
        return _onReward(_user, _newVote);
    }

    function onReward(address, uint256) external override onlyMaster nonReentrant returns (uint256[] memory) {
        revert('Call BribeV2.onVote instead');
    }

    function _getTotalShare() internal view override returns (uint256 voteWeight) {
        (, voteWeight) = IVoter(master).weights(lpToken);
    }

    function rewardLength() public view override(IBribe, MultiRewarderPerSecV2) returns (uint256) {
        return MultiRewarderPerSecV2.rewardLength();
    }

    function rewardTokens() public view override(IBribe, MultiRewarderPerSecV2) returns (IERC20[] memory tokens) {
        return MultiRewarderPerSecV2.rewardTokens();
    }

    function pendingTokens(
        address _user
    ) public view override(IBribe, MultiRewarderPerSecV2) returns (uint256[] memory tokens) {
        return MultiRewarderPerSecV2.pendingTokens(_user);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './IMasterWombatV3.sol';
import './IBoostedMultiRewarder.sol';

/**
 * @dev Interface of BoostedMasterWombat
 */
interface IBoostedMasterWombat is IMasterWombatV3 {
    function getSumOfFactors(uint256 pid) external view returns (uint256 sum);

    function basePartition() external view returns (uint16);

    function add(IERC20 _lpToken, IBoostedMultiRewarder _boostedRewarder) external;

    function boostedRewarders(uint256 _pid) external view returns (IBoostedMultiRewarder);

    function setBoostedRewarder(uint256 _pid, IBoostedMultiRewarder _boostedRewarder) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IBoostedMultiRewarder {
    function lpToken() external view returns (IERC20 lpToken);

    function onReward(
        address _user,
        uint256 _newLpAmount,
        uint256 _newFactor
    ) external returns (uint256[] memory rewards);

    function addRewardToken(IERC20 _rewardToken, uint40 _startTimestamp, uint96 _tokenPerSec) external;

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);

    function onUpdateFactor(address _user, uint256 _newFactor) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IBribe {
    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external returns (uint256[] memory rewards);

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IBribeRewarderFactory {
    function isRewardTokenWhitelisted(IERC20 _token) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

/**
 * @dev Interface of the MasterWombat
 */
interface IMasterWombat {
    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        returns (
            uint256 pendingRewards,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function rewarderBonusTokenInfo(
        uint256 _pid
    ) external view returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function multiClaim(
        uint256[] memory _pids
    ) external returns (uint256 transfered, uint256[] memory rewards, uint256[] memory additionalRewards);

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(uint256 _pid, uint256 _amount, address _user) external;

    function updateFactor(address _user, uint256 _newVeWomBalance) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Interface of the MasterWombatV3
 */
interface IMasterWombatV3 {
    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        returns (
            uint256 pendingRewards,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );

    function rewarderBonusTokenInfo(
        uint256 _pid
    ) external view returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function multiClaim(
        uint256[] memory _pids
    ) external returns (uint256 transfered, uint256[] memory rewards, uint256[][] memory additionalRewards);

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(uint256 _pid, uint256 _amount, address _user) external;

    function updateFactor(address _user, uint256 _newVeWomBalance) external;

    function notifyRewardAmount(address _lpToken, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMultiRewarder {
    function lpToken() external view returns (IERC20 lpToken);

    function onReward(address _user, uint256 _lpAmount) external returns (uint256[] memory rewards);

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMultiRewarderV2 {
    function lpToken() external view returns (IERC20 lpToken);

    function onReward(address _user, uint256 _lpAmount) external returns (uint256[] memory rewards);

    function addRewardToken(IERC20 _rewardToken, uint40 _startTimestamp, uint96 _tokenPerSec) external;

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

/**
 * @dev Interface of the VeWom
 */
interface IVeWom {
    struct Breeding {
        uint48 unlockTime;
        uint104 womAmount;
        uint104 veWomAmount;
    }

    struct UserInfo {
        // reserve usage for future upgrades
        uint256[10] reserved;
        Breeding[] breedings;
    }

    function totalSupply() external view returns (uint256);

    function balanceOf(address _addr) external view returns (uint256);

    function isUser(address _addr) external view returns (bool);

    function getUserOverview(address _addr) external view returns (uint256 womLocked, uint256 veWomBalance);

    function getUserInfo(address addr) external view returns (UserInfo memory);

    function mint(uint256 amount, uint256 lockDays) external returns (uint256 veWomAmount);

    function burn(uint256 slot) external;

    function update(uint256 slot, uint256 lockDays) external returns (uint256 newVeWomAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './IBribe.sol';

interface IGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IVoter {
    struct GaugeWeight {
        uint128 allocPoint;
        uint128 voteWeight; // total amount of votes for an LP-token
    }

    function infos(
        IERC20 _lpToken
    )
        external
        view
        returns (
            uint104 supplyBaseIndex,
            uint104 supplyVoteIndex,
            uint40 nextEpochStartTime,
            uint128 claimable,
            bool whitelist,
            IGauge gaugeManager,
            IBribe bribe
        );

    // lpToken => weight, equals to sum of votes for a LP token
    function weights(IERC20 _lpToken) external view returns (uint128 allocPoint, uint128 voteWeight);

    // user address => lpToken => votes
    function votes(address _user, IERC20 _lpToken) external view returns (uint256);

    function setBribe(IERC20 _lpToken, IBribe _bribe) external;

    function distribute(IERC20 _lpToken) external;
}

// SPDX-License-Identifier: GPL-3.0

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.5;

library DSMath {
    uint256 public constant WAD = 10 ** 18;

    // Babylonian Method
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Babylonian Method with initial guess
    function sqrt(uint256 y, uint256 guess) internal pure returns (uint256 z) {
        if (y > 3) {
            if (guess > y || guess == 0) {
                z = y;
            } else {
                z = guess;
            }
            uint256 x = (y / z + z) / 2;
            while (x != z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * WAD) + (y / 2)) / y;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import '../interfaces/IMultiRewarder.sol';
import '../rewarders/MultiRewarderPerSec.sol';
import '../rewarders/MultiRewarderPerSecV2.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * This contract simulates MasterWombat for MultiRewarderPerSec.
 */
contract RewarderCaller {
    using SafeERC20 for IERC20;

    // Proxy onReward calls to rewarder.
    function onReward(address rewarder, address user, uint256 lpAmount) public returns (uint256[] memory rewards) {
        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        // Rewarder use master's lpToken balance as totalShare. Make sure we have enough.
        require(lpToken.balanceOf(address(this)) >= lpAmount, 'RewarderCaller must have sufficient lpToken balance');

        return IMultiRewarder(rewarder).onReward(user, lpAmount);
    }

    // Simulate a deposit to MasterWombatV3
    // Note: MasterWombatV3 calls onRewarder before transfer
    function depositFor(address rewarder, address user, uint256 amount) public {
        (uint128 userAmount, , ) = MultiRewarderPerSec(payable(rewarder)).userInfo(0, user);
        IMultiRewarder(rewarder).onReward(user, userAmount + amount);

        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Simulate a withdrawal from MasterWombatV3
    // Note: MasterWombatV3 calls onRewarder before transfer
    function withdrawFor(address rewarder, address user, uint256 amount) public {
        (uint128 userAmount, , ) = MultiRewarderPerSec(payable(rewarder)).userInfo(0, user);
        IMultiRewarder(rewarder).onReward(user, userAmount - amount);

        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        lpToken.safeTransfer(msg.sender, amount);
    }
}

/**
 * This contract simulates MasterWombat for MultiRewarderPerSecV2.
 */
contract RewarderCallerV2 {
    using SafeERC20 for IERC20;

    // Proxy onReward calls to rewarder.
    function onReward(address rewarder, address user, uint256 lpAmount) public returns (uint256[] memory rewards) {
        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        // Rewarder use master's lpToken balance as totalShare. Make sure we have enough.
        require(lpToken.balanceOf(address(this)) >= lpAmount, 'RewarderCaller must have sufficient lpToken balance');

        return IMultiRewarder(rewarder).onReward(user, lpAmount);
    }

    // Simulate a deposit to MasterWombatV3
    // Note: MasterWombatV3 calls onRewarder before transfer
    function depositFor(address rewarder, address user, uint256 amount) public {
        uint256 userAmount = MultiRewarderPerSecV2(payable(rewarder)).userBalanceInfo(user);
        IMultiRewarder(rewarder).onReward(user, userAmount + amount);

        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Simulate a withdrawal from MasterWombatV3
    // Note: MasterWombatV3 calls onRewarder before transfer
    function withdrawFor(address rewarder, address user, uint256 amount) public {
        uint256 userAmount = MultiRewarderPerSecV2(payable(rewarder)).userBalanceInfo(user);
        IMultiRewarder(rewarder).onReward(user, userAmount - amount);

        IERC20 lpToken = IMultiRewarder(rewarder).lpToken();
        lpToken.safeTransfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../interfaces/IBribeRewarderFactory.sol';
import '../interfaces/IBoostedMultiRewarder.sol';
import '../interfaces/IBoostedMasterWombat.sol';

/**
 * This is a sample contract to be used in the Master Wombat contract for partners to reward
 * stakers with their native token alongside WOM.
 *
 * It assumes no minting rights, so requires a set amount of reward tokens to be transferred to this contract prior.
 * E.g. say you've allocated 100,000 XYZ to the WOM-XYZ farm over 30 days. Then you would need to transfer
 * 100,000 XYZ and set the block reward accordingly so it's fully distributed after 30 days.
 *
 * This contract has no knowledge on the LP amount and factor. Master Wombat is responsible to pass these values to this contract
 * Change log (since MultiRewarderPerSecV2):
 * - Rewarders are now boosted by veWom balance!
 */
contract BoostedMultiRewarder is
    IBoostedMultiRewarder,
    Initializable,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant ROLE_OPERATOR = keccak256('operator');
    uint256 public constant ACC_TOKEN_PRECISION = 1e18;
    uint256 public constant TOTAL_PARTITION = 1000;
    uint256 public constant MAX_TOKEN_RATE = 10000e18;

    struct UserBalanceInfo {
        uint128 amount; // 20.18 fixed point.
        uint128 factor; // 20.18 fixed point.
    }

    struct UserRewardInfo {
        uint128 rewardDebt; // 20.18 fixed point. distributed reward per weight
        // if the pool is activated, rewardDebt must be > 0
        uint128 unpaidRewards; // 20.18 fixed point.
    }

    /// @notice Info of each reward token.
    struct RewardInfo {
        /// slot
        IERC20 rewardToken; // if rewardToken is 0, native token is used as reward token
        uint96 tokenPerSec; // 10.18 fixed point. The emission rate in tokens per second.
        // This rate may not reflect the current rate in cases where emission has not started or has stopped due to surplus <= 0.
        /// slot
        uint128 accTokenPerShare; // 20.18 fixed point. Amount of reward token each LP token is worth.
        // This value increases when rewards are being distributed.
        uint128 accTokenPerFactorShare; // 20.18 fixed point. Accumulated WOM per factor share
        /// slot
        uint128 distributedAmount; // 20.18 fixed point, depending on the decimals of the reward token. This value is used to
        // track the amount of distributed tokens. If `distributedAmount` is closed to the amount of total received
        // tokens, we should refill reward or prepare to stop distributing reward.
        uint128 claimedAmount; // 20.18 fixed point. Total amount claimed by all users.
        // We can derive the unclaimed amount: distributedAmount - claimedAmount

        /// slot
        uint40 lastRewardTimestamp; // The timestamp up to which rewards have already been distributed.
        // If set to a future value, it indicates that the emission has not started yet.
    }

    /**
     * Visualization of the relationship between distributedAmount, claimedAmount, rewardToDistribute, availableReward, surplus and balance:
     *
     * Case: emission is active. rewardToDistribute is growing at the rate of tokenPerSec.
     * |<--------------distributedAmount------------->|<--rewardToDistribute*-->|
     * |<-----claimedAmount----->|<-------------------------balance------------------------->|
     *                                                |<-----------availableReward*--------->|
     *                           |<-unclaimedAmount*->|                         |<-surplus*->|
     *
     * Case: reward running out. rewardToDistribute stopped growing. it is capped at availableReward.
     * |<--------------distributedAmount------------->|<---------rewardToDistribute*-------->|
     * |<-----claimedAmount----->|<-------------------------balance------------------------->|
     *                                                |<-----------availableReward*--------->|
     *                           |<-unclaimedAmount*->|                                       surplus* = 0
     *
     * Case: balance emptied after emergencyWithdraw.
     * |<--------------distributedAmount------------->| rewardToDistribute* = 0
     * |<-----claimedAmount----->|                      balance = 0, availableReward* = 0
     *                           |<-unclaimedAmount*->| surplus* = - unclaimedAmount* (negative to indicate deficit)
     *
     * (Variables with * are not in the RewardInfo state, but can be derived from it.)
     *
     * balance, is the amount of reward token in this contract. Not all of them are available for distribution as some are reserved for
     * unclaimed rewards.
     * distributedAmount, is the amount of reward token that has been distributed up to lastRewardTimestamp.
     * claimedAmount, is the amount of reward token that has been claimed by users. claimedAmount always <= distributedAmount.
     * unclaimedAmount = distributedAmount - claimedAmount, is the amount of reward token in balance that is reserved to be claimed by users.
     * availableReward = balance - unclaimedAmount, is the amount inside balance that is available for distribution (not reserved for
     * unclaimed rewards).
     * rewardToDistribute is the accumulated reward from [lastRewardTimestamp, now] that is yet to be distributed. as distributedAmount only
     * accounts for the distributed amount up to lastRewardTimestamp. it is used in _updateReward(), and to be added to distributedAmount.
     * to prevent bad debt, rewardToDistribute is capped at availableReward. as we cannot distribute more than the availableReward.
     * rewardToDistribute = min(tokenPerSec * (now - lastRewardTimestamp), availableReward)
     * surplus = availableReward - rewardToDistribute, is the amount inside balance that is available for future distribution.
     */

    IERC20 public lpToken;
    IBoostedMasterWombat public masterWombat;

    /// @notice Info of the reward tokens.
    RewardInfo[] public rewardInfos;
    /// @notice userAddr => UserBalanceInfo
    mapping(address => UserBalanceInfo) public userBalanceInfo;
    /// @notice tokenId => userAddr => UserRewardInfo
    mapping(uint256 => mapping(address => UserRewardInfo)) public userRewardInfo;

    IBribeRewarderFactory public bribeFactory;
    bool public isDeprecated;

    event OnReward(address indexed rewardToken, address indexed user, uint256 amount);
    event RewardRateUpdated(address indexed rewardToken, uint256 oldRate, uint256 newRate);
    event StartTimeUpdated(address indexed rewardToken, uint40 newStartTime);
    event IsDeprecatedUpdated(bool isDeprecated);

    modifier onlyMasterWombat() {
        require(
            msg.sender == address(masterWombat),
            'BoostedMultiRewarderPerSec: only Master Wombat can call this function'
        );
        _;
    }

    /// @notice payable function needed to receive BNB
    receive() external payable {}

    /**
     * @notice Initializes pool. Dev is set to be the account calling this function.
     */
    function initialize(
        IBribeRewarderFactory _bribeFactory,
        IBoostedMasterWombat _masterWombat,
        IERC20 _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) public virtual initializer {
        require(
            Address.isContract(address(_rewardToken)) || address(_rewardToken) == address(0),
            'constructor: reward token must be a valid contract'
        );
        require(Address.isContract(address(_lpToken)), 'constructor: LP token must be a valid contract');
        require(Address.isContract(address(_masterWombat)), 'constructor: Master Wombat must be a valid contract');
        require(_startTimestamp >= block.timestamp, 'constructor: invalid _startTimestamp');

        __Ownable_init();
        __AccessControlEnumerable_init_unchained();
        __ReentrancyGuard_init_unchained();

        bribeFactory = _bribeFactory; // bribeFactory can be 0 address
        masterWombat = _masterWombat;
        lpToken = _lpToken;

        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        RewardInfo memory reward = RewardInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18,
            accTokenPerFactorShare: 0,
            distributedAmount: 0,
            claimedAmount: 0,
            lastRewardTimestamp: uint40(_startTimestamp)
        });
        emit RewardRateUpdated(address(reward.rewardToken), 0, _tokenPerSec);
        emit StartTimeUpdated(address(reward.rewardToken), uint40(_startTimestamp));
        rewardInfos.push(reward);
    }

    function addOperator(address _operator) external onlyOwner {
        _grantRole(ROLE_OPERATOR, _operator);
    }

    function removeOperator(address _operator) external onlyOwner {
        _revokeRole(ROLE_OPERATOR, _operator);
    }

    function setIsDeprecated(bool _isDeprecated) external onlyOwner {
        isDeprecated = _isDeprecated;
        emit IsDeprecatedUpdated(_isDeprecated);
    }

    function addRewardToken(IERC20 _rewardToken, uint40 _startTimestampOrNow, uint96 _tokenPerSec) external override {
        require(hasRole(ROLE_OPERATOR, msg.sender) || msg.sender == owner(), 'not authorized');
        // Check `bribeFactory.isRewardTokenWhitelisted` if needed
        require(
            address(bribeFactory) == address(0) || bribeFactory.isRewardTokenWhitelisted(_rewardToken),
            'reward token must be whitelisted by bribe factory'
        );

        _addRewardToken(_rewardToken, _startTimestampOrNow, _tokenPerSec);
    }

    function _addRewardToken(IERC20 _rewardToken, uint40 _startTimestampOrNow, uint96 _tokenPerSec) internal {
        require(
            Address.isContract(address(_rewardToken)) || address(_rewardToken) == address(0),
            'reward token must be a valid contract'
        );
        require(_startTimestampOrNow == 0 || _startTimestampOrNow >= block.timestamp, 'invalid _startTimestamp');
        uint256 length = rewardInfos.length;
        for (uint256 i; i < length; ++i) {
            require(rewardInfos[i].rewardToken != _rewardToken, 'token has already been added');
        }
        _updateReward();
        uint40 startTimestamp = _startTimestampOrNow == 0 ? uint40(block.timestamp) : _startTimestampOrNow;
        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        RewardInfo memory reward = RewardInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18,
            accTokenPerFactorShare: 0,
            distributedAmount: 0,
            claimedAmount: 0,
            lastRewardTimestamp: startTimestamp
        });
        rewardInfos.push(reward);
        emit StartTimeUpdated(address(reward.rewardToken), startTimestamp);
        emit RewardRateUpdated(address(reward.rewardToken), 0, _tokenPerSec);
    }

    function updateReward() public {
        _updateReward();
    }

    /// @dev This function should be called before lpSupply and sumOfFactors update
    function _updateReward() internal {
        uint256 lpSupply = _getTotalShare();
        uint256 pid = masterWombat.getAssetPid(address(lpToken));
        uint256 sumOfFactors = masterWombat.getSumOfFactors(pid);
        uint256[] memory toDistribute = _rewardsToDistribute();

        uint256 length = rewardInfos.length;

        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            uint256 rewardToDistribute = toDistribute[i];
            if (rewardToDistribute > 0) {
                (uint256 tokenPerShare, uint256 tokenPerFactorShare) = _getRewardsToDistributeFor(
                    rewardToDistribute,
                    lpSupply,
                    sumOfFactors
                );
                info.accTokenPerShare += toUint128(tokenPerShare);
                info.accTokenPerFactorShare += toUint128(tokenPerFactorShare);
                info.distributedAmount += toUint128(rewardToDistribute);
            }
            // update lastRewardTimestamp even if no reward is distributed.
            if (info.lastRewardTimestamp < block.timestamp) {
                // but don't update if info.lastRewardTimestamp is set in the future,
                // otherwise we would be starting the emission earlier than it's supposed to.
                info.lastRewardTimestamp = uint40(block.timestamp);
            }
        }
    }

    /// @notice Sets the distribution reward rate, and updates the emission start time if specified.
    /// @param _tokenId The token id
    /// @param _tokenPerSec The number of tokens to distribute per second
    /// @param _startTimestampToOverride the start time for the token emission. A value of 0 indicates no changes, while a future
    ///        timestamp starts the emission at the specified time.
    function setRewardRate(uint256 _tokenId, uint96 _tokenPerSec, uint40 _startTimestampToOverride) external {
        require(hasRole(ROLE_OPERATOR, msg.sender) || msg.sender == owner(), 'not authorized');
        require(_tokenId < rewardInfos.length, 'invalid _tokenId');
        require(
            _startTimestampToOverride == 0 || _startTimestampToOverride >= block.timestamp,
            'invalid _startTimestampToOverride'
        );
        require(_tokenPerSec <= MAX_TOKEN_RATE, 'reward rate too high'); // in case of accTokenPerShare overflow
        _updateReward();
        RewardInfo storage info = rewardInfos[_tokenId];
        uint256 oldRate = info.tokenPerSec;
        info.tokenPerSec = _tokenPerSec;
        if (_startTimestampToOverride > 0) {
            info.lastRewardTimestamp = _startTimestampToOverride;
            emit StartTimeUpdated(address(info.rewardToken), _startTimestampToOverride);
        }
        emit RewardRateUpdated(address(rewardInfos[_tokenId].rewardToken), oldRate, _tokenPerSec);
    }

    /// @notice Function called by Master Wombat whenever staker claims WOM harvest.
    /// @notice Allows staker to also receive a 2nd reward token.
    /// @dev Assume `_getTotalShare` isn't updated yet when this function is called
    /// @param _user Address of user
    /// @param _newLpAmount The new amount of LP
    /// @param _newFactor The new factor of LP
    function onReward(
        address _user,
        uint256 _newLpAmount,
        uint256 _newFactor
    ) external virtual override onlyMasterWombat nonReentrant returns (uint256[] memory rewards) {
        _updateReward();
        return _onReward(_user, _newLpAmount, _newFactor);
    }

    /// @notice Function called by Master Wombat when factor is updated
    /// @dev Assume lpSupply and sumOfFactors isn't updated yet when this function is called
    /// @notice user.unpaidRewards will be updated
    function onUpdateFactor(address _user, uint256 _newFactor) external override onlyMasterWombat {
        if (basePartition() == TOTAL_PARTITION) {
            // base partition only
            return;
        }

        updateReward();
        uint256 length = rewardInfos.length;

        for (uint256 i; i < length; ++i) {
            RewardInfo storage pool = rewardInfos[i];
            UserRewardInfo storage user = userRewardInfo[i][_user];

            if (user.rewardDebt > 0) {
                // rewardDebt > 0 indicates the user has activated the pool and we should calculate rewards
                user.unpaidRewards += toUint128(
                    _getRewardDebt(
                        userBalanceInfo[_user].amount,
                        pool.accTokenPerShare,
                        userBalanceInfo[_user].factor,
                        pool.accTokenPerFactorShare
                    ) - user.rewardDebt
                );
            }

            user.rewardDebt = toUint128(
                _getRewardDebt(
                    userBalanceInfo[_user].amount,
                    pool.accTokenPerShare,
                    _newFactor,
                    pool.accTokenPerFactorShare
                )
            );
        }

        userBalanceInfo[_user].factor = toUint128(_newFactor);
    }

    function basePartition() public view returns (uint256) {
        return masterWombat.basePartition();
    }

    function _onReward(
        address _user,
        uint256 _newLpAmount,
        uint256 _newFactor
    ) internal virtual returns (uint256[] memory rewards) {
        uint256 length = rewardInfos.length;
        rewards = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            UserRewardInfo storage user = userRewardInfo[i][_user];
            IERC20 rewardToken = info.rewardToken;

            if (user.rewardDebt > 0 || user.unpaidRewards > 0) {
                // rewardDebt > 0 indicates the user has activated the pool and we should distribute rewards
                uint256 pending = _getRewardDebt(
                    userBalanceInfo[_user].amount,
                    info.accTokenPerShare,
                    userBalanceInfo[_user].factor,
                    info.accTokenPerFactorShare
                ) +
                    user.unpaidRewards -
                    user.rewardDebt;

                if (address(rewardToken) == address(0)) {
                    // is native token
                    uint256 tokenBalance = address(this).balance;
                    if (pending > tokenBalance) {
                        // Note: this line may fail if the receiver is a contract and refuse to receive BNB
                        (bool success, ) = _user.call{value: tokenBalance}('');
                        require(success, 'Transfer failed');
                        rewards[i] = tokenBalance;
                        info.claimedAmount += toUint128(tokenBalance);
                        user.unpaidRewards = toUint128(pending - tokenBalance);
                    } else {
                        (bool success, ) = _user.call{value: pending}('');
                        require(success, 'Transfer failed');
                        rewards[i] = pending;
                        info.claimedAmount += toUint128(pending);
                        user.unpaidRewards = 0;
                    }
                } else {
                    // ERC20 token
                    uint256 tokenBalance = rewardToken.balanceOf(address(this));
                    if (pending > tokenBalance) {
                        rewardToken.safeTransfer(_user, tokenBalance);
                        rewards[i] = tokenBalance;
                        info.claimedAmount += toUint128(tokenBalance);
                        user.unpaidRewards = toUint128(pending - tokenBalance);
                    } else {
                        rewardToken.safeTransfer(_user, pending);
                        rewards[i] = pending;
                        info.claimedAmount += toUint128(pending);
                        user.unpaidRewards = 0;
                    }
                }
            }

            user.rewardDebt = toUint128(
                _getRewardDebt(_newLpAmount, info.accTokenPerShare, _newFactor, info.accTokenPerFactorShare)
            );
            emit OnReward(address(rewardToken), _user, rewards[i]);
        }

        userBalanceInfo[_user].amount = toUint128(_newLpAmount);
        userBalanceInfo[_user].factor = toUint128(_newFactor);
    }

    function emergencyClaimReward() external nonReentrant returns (uint256[] memory rewards) {
        _updateReward();
        require(isDeprecated, 'rewarder / bribe is not deprecated');
        return _onReward(msg.sender, 0, 0);
    }

    /// @notice returns reward length
    function rewardLength() external view virtual override returns (uint256) {
        return rewardInfos.length;
    }

    /// @notice View function to see pending tokens that have been distributed but not claimed by the user yet.
    /// @param _user Address of user.
    /// @return rewards_ reward for a given user.
    function pendingTokens(address _user) external view virtual override returns (uint256[] memory rewards_) {
        return _pendingTokens(_user, userBalanceInfo[_user].amount, userBalanceInfo[_user].factor);
    }

    function _pendingTokens(
        address _user,
        uint256 _lpAmount,
        uint256 _factor
    ) internal view returns (uint256[] memory rewards_) {
        uint256 pid = masterWombat.getAssetPid(address(lpToken));
        uint256 sumOfFactors = masterWombat.getSumOfFactors(pid);

        uint256 length = rewardInfos.length;
        rewards_ = new uint256[](length);

        uint256[] memory toDistribute = _rewardsToDistribute();
        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];
            UserRewardInfo storage user = userRewardInfo[i][_user];

            uint256 accTokenPerShare = info.accTokenPerShare;
            uint256 accTokenPerFactorShare = info.accTokenPerFactorShare;

            uint256 lpSupply = _getTotalShare();
            if (lpSupply > 0) {
                (uint256 tokenPerShare, uint256 tokenPerFactorShare) = _getRewardsToDistributeFor(
                    toDistribute[i],
                    lpSupply,
                    sumOfFactors
                );
                accTokenPerShare += tokenPerShare;
                accTokenPerFactorShare += tokenPerFactorShare;
            }

            rewards_[i] =
                _getRewardDebt(_lpAmount, accTokenPerShare, _factor, accTokenPerFactorShare) +
                user.unpaidRewards -
                user.rewardDebt;
        }
    }

    function _getRewardsToDistributeFor(
        uint256 rewardToDistribute,
        uint256 lpSupply,
        uint256 sumOfFactors
    ) internal view returns (uint256 tokenPerShare, uint256 tokenPerFactorShare) {
        // use `max(totalShare, 1e18)` in case of overflow
        uint256 _basePartition = basePartition();
        tokenPerShare =
            (rewardToDistribute * ACC_TOKEN_PRECISION * _basePartition) /
            max(lpSupply, 1e18) /
            TOTAL_PARTITION;

        if (sumOfFactors > 0) {
            tokenPerFactorShare =
                (rewardToDistribute * ACC_TOKEN_PRECISION * (TOTAL_PARTITION - _basePartition)) /
                sumOfFactors /
                TOTAL_PARTITION;
        }
    }

    function _getRewardDebt(
        uint256 userAmount,
        uint256 accTokenPerShare,
        uint256 userFactor,
        uint256 accTokenPerFactorShare
    ) internal pure returns (uint256) {
        return (userAmount * accTokenPerShare + userFactor * accTokenPerFactorShare) / ACC_TOKEN_PRECISION;
    }

    /// @notice the amount of reward accumulated since the lastRewardTimestamp and is to be distributed.
    function rewardsToDistribute() public view returns (uint256[] memory rewards_) {
        return _rewardsToDistribute();
    }

    /// @notice the amount of reward accumulated since the lastRewardTimestamp and is to be distributed.
    /// the case that lastRewardTimestamp is in the future is also handled
    function _rewardsToDistribute() internal view returns (uint256[] memory rewards_) {
        uint256 length = rewardInfos.length;
        rewards_ = new uint256[](length);

        uint256[] memory rewardBalances = _balances();

        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];
            // if (block.timestamp < info.lastRewardTimestamp), then emission has not started yet.
            if (block.timestamp < info.lastRewardTimestamp) continue;

            uint40 timeElapsed = uint40(block.timestamp) - info.lastRewardTimestamp;
            uint256 accumulatedReward = uint256(info.tokenPerSec) * timeElapsed;

            // To prevent bad debt, need to cap at availableReward
            uint256 availableReward;
            // this is to handle the underflow case if claimedAmount + balance < distributedAmount,
            // which happens only if balance was emergencyWithdrawn.
            if (info.claimedAmount + rewardBalances[i] > info.distributedAmount) {
                availableReward = info.claimedAmount + rewardBalances[i] - info.distributedAmount;
            }
            rewards_[i] = min(accumulatedReward, availableReward);
        }
    }

    function _getTotalShare() internal view virtual returns (uint256) {
        return lpToken.balanceOf(address(masterWombat));
    }

    /// @notice return an array of reward tokens
    function _rewardTokens() internal view returns (IERC20[] memory tokens_) {
        uint256 length = rewardInfos.length;
        tokens_ = new IERC20[](length);
        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];
            tokens_[i] = info.rewardToken;
        }
    }

    function rewardTokens() external view virtual override returns (IERC20[] memory tokens) {
        return _rewardTokens();
    }

    /// @notice View function to see surplus of each reward, i.e. reward balance - unclaimed amount
    /// it would be negative if there's bad debt/deficit, which would happend only if some token was emergencyWithdrawn.
    /// @return surpluses_ surpluses of the reward tokens.
    // override.
    function rewardTokenSurpluses() external view virtual returns (int256[] memory surpluses_) {
        return _rewardTokenSurpluses();
    }

    /// @notice View function to see surplus of each reward, i.e. reward balance - unclaimed amount
    /// surplus = claimed amount + balance - distributed amount - rewardToDistribute
    /// @return surpluses_ surpluses of the reward tokens.
    function _rewardTokenSurpluses() internal view returns (int256[] memory surpluses_) {
        uint256 length = rewardInfos.length;
        surpluses_ = new int256[](length);
        uint256[] memory toDistribute = _rewardsToDistribute();
        uint256[] memory rewardBalances = _balances();

        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];

            surpluses_[i] =
                int256(uint256(info.claimedAmount)) +
                int256(rewardBalances[i]) -
                int256(uint256(info.distributedAmount)) -
                int256(toDistribute[i]);
        }
    }

    function isEmissionActive() external view returns (bool[] memory isActive_) {
        return _isEmissionActive();
    }

    function _isEmissionActive() internal view returns (bool[] memory isActive_) {
        uint256 length = rewardInfos.length;
        isActive_ = new bool[](length);
        int256[] memory surpluses = _rewardTokenSurpluses();
        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];

            // conditions for emission to be active:
            // 1. surplus > 0
            // 2. tokenPerSec > 0
            // 3. lastRewardTimestamp <= block.timestamp
            isActive_[i] = surpluses[i] > 0 && info.tokenPerSec > 0 && info.lastRewardTimestamp <= block.timestamp;
        }
    }

    /// @notice In case rewarder is stopped before emissions finished, this function allows
    /// withdrawal of remaining tokens.
    /// there will be deficit which is equal to the unclaimed amount
    function emergencyWithdraw() external onlyOwner {
        uint256 length = rewardInfos.length;
        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            info.tokenPerSec = 0;
            info.lastRewardTimestamp = uint40(block.timestamp);
            emergencyTokenWithdraw(address(info.rewardToken));
        }
    }

    /// @notice avoids loosing funds in case there is any tokens sent to this contract
    /// the reward token will not be stopped and keep accumulating debts
    /// @dev only to be called by owner
    function emergencyTokenWithdraw(address token) public onlyOwner {
        // send that balance back to owner
        if (token == address(0)) {
            // is native token
            (bool success, ) = msg.sender.call{value: address(this).balance}('');
            require(success, 'Transfer failed');
        } else {
            IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    /// @notice View function to see the timestamp when the reward will runout based on current emission rate and balance left.
    /// a timestamp of 0 indicates that the token is not emitting or already run out.
    /// also works for the case that emission start time (lastRewardTimestamp) is in the future.
    function runoutTimestamps() external view returns (uint40[] memory timestamps_) {
        uint256 length = rewardInfos.length;
        timestamps_ = new uint40[](length);
        uint256[] memory rewardBalances = _balances();
        int256[] memory surpluses = _rewardTokenSurpluses();

        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];

            if (surpluses[i] > 0 && info.tokenPerSec > 0) {
                // we have: surplus = claimedAmount + balance - distributedAmount - tokenPerSec * (block.timestamp - lastRewardTimestamp)
                // surplus would reach 0 at runoutTimestamp. therefore, we have the formula:
                // 0 = claimedAmount + balance - distributedAmount - tokenPerSec * (runoutTimestamp - lastRewardTimestamp)
                // Solving for runoutTimestamp:
                // runoutTimestamp = (claimedAmount + balance - distributedAmount + tokenPerSec * lastRewardTimestamp) / tokenPerSec

                timestamps_[i] = uint40(
                    (info.claimedAmount +
                        rewardBalances[i] -
                        info.distributedAmount +
                        info.tokenPerSec *
                        info.lastRewardTimestamp) / info.tokenPerSec
                );
            }
        }
    }

    /// @notice View function to preserve backward compatibility, as the previous version uses rewardInfo instead of rewardInfos
    function rewardInfo(uint256 i) external view returns (RewardInfo memory info) {
        return rewardInfos[i];
    }

    /// @notice View function to see balances of reward token.
    function balances() external view returns (uint256[] memory balances_) {
        return _balances();
    }

    function _balances() internal view returns (uint256[] memory balances_) {
        uint256 length = rewardInfos.length;
        balances_ = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            if (address(info.rewardToken) == address(0)) {
                // is native token
                balances_[i] = address(this).balance;
            } else {
                balances_[i] = info.rewardToken.balanceOf(address(this));
            }
        }
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/IMultiRewarder.sol';

/**
 * This is a sample contract to be used in the Master contract for partners to reward
 * stakers with their native token alongside WOM.
 *
 * It assumes no minting rights, so requires a set amount of reward tokens to be transferred to this contract prior.
 * E.g. say you've allocated 100,000 XYZ to the WOM-XYZ farm over 30 days. Then you would need to transfer
 * 100,000 XYZ and set the block reward accordingly so it's fully distributed after 30 days.
 *
 * - This contract has no knowledge on the LP amount and Master is
 *   responsible to pass the amount into this contract
 * - Supports multiple reward tokens
 */
contract MultiRewarderPerSec is IMultiRewarder, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant ACC_TOKEN_PRECISION = 1e18;
    IERC20 public immutable lpToken;
    address public immutable master;

    struct UserInfo {
        uint128 amount; // 20.18 fixed point.
        // if the pool is activated, rewardDebt should be > 0
        uint128 rewardDebt; // 20.18 fixed point. distributed reward per weight
        uint256 unpaidRewards; // 20.18 fixed point.
    }

    /// @notice Info of each rewardInfo.
    struct RewardInfo {
        IERC20 rewardToken; // if rewardToken is 0, native token is used as reward token
        uint96 tokenPerSec; // 10.18 fixed point
        uint128 accTokenPerShare; // 26.12 fixed point. Amount of reward token each LP token is worth.
        uint128 distributedAmount; // 20.18 fixed point, depending on the decimals of the reward token. This value is used to
        // track the amount of distributed tokens. If `distributedAmount` is closed to the amount of total received
        // tokens, we should refill reward or prepare to stop distributing reward.
    }

    /// @notice address of the operator
    /// @dev operator is able to set emission rate
    address public operator;

    uint256 public lastRewardTimestamp;

    /// @notice Info of the rewardInfo.
    RewardInfo[] public rewardInfo;
    /// @notice tokenId => userId => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event OnReward(address indexed rewardToken, address indexed user, uint256 amount);
    event RewardRateUpdated(address indexed rewardToken, uint256 oldRate, uint256 newRate);

    modifier onlyMaster() {
        require(msg.sender == address(master), 'onlyMaster: only Master can call this function');
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(msg.sender == owner() || msg.sender == operator, 'onlyOperatorOrOwner');
        _;
    }

    /// @notice payable function needed to receive BNB
    receive() external payable {}

    constructor(address _master, IERC20 _lpToken, uint256 _startTimestamp, IERC20 _rewardToken, uint96 _tokenPerSec) {
        require(
            Address.isContract(address(_rewardToken)) || address(_rewardToken) == address(0),
            'constructor: reward token must be a valid contract'
        );
        require(Address.isContract(address(_lpToken)), 'constructor: LP token must be a valid contract');
        require(Address.isContract(address(_master)), 'constructor: Master must be a valid contract');
        require(_startTimestamp >= block.timestamp);

        master = _master;
        lpToken = _lpToken;

        lastRewardTimestamp = _startTimestamp;

        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        RewardInfo memory reward = RewardInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18,
            distributedAmount: 0
        });
        rewardInfo.push(reward);
        emit RewardRateUpdated(address(_rewardToken), 0, _tokenPerSec);
    }

    /// @notice Set operator address
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function addRewardToken(IERC20 _rewardToken, uint96 _tokenPerSec) external onlyOwner {
        _updateReward();
        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        RewardInfo memory reward = RewardInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18,
            distributedAmount: 0
        });
        rewardInfo.push(reward);
        emit RewardRateUpdated(address(_rewardToken), 0, _tokenPerSec);
    }

    function updateReward() public {
        _updateReward();
    }

    /// @dev This function should be called before lpSupply and sumOfFactors update
    function _updateReward() internal {
        _updateReward(_getTotalShare());
    }

    function _updateReward(uint256 totalShare) internal {
        if (block.timestamp > lastRewardTimestamp) {
            uint256 length = rewardInfo.length;
            for (uint256 i; i < length; ++i) {
                RewardInfo storage reward = rewardInfo[i];
                uint256 timeElapsed = block.timestamp - lastRewardTimestamp;
                uint256 tokenReward = timeElapsed * reward.tokenPerSec;
                // use `max(totalShare, 1e18)` in case of overflow
                reward.accTokenPerShare += toUint128((tokenReward * ACC_TOKEN_PRECISION) / max(totalShare, 1e18));
                reward.distributedAmount += toUint128(tokenReward);
            }
            lastRewardTimestamp = block.timestamp;
        }
    }

    /// @notice Sets the distribution reward rate. This will also update the rewardInfo.
    /// @param _tokenPerSec The number of tokens to distribute per second
    function setRewardRate(uint256 _tokenId, uint96 _tokenPerSec) external onlyOperatorOrOwner {
        require(_tokenPerSec <= 10000e18, 'reward rate too high'); // in case of accTokenPerShare overflow
        _updateReward();

        uint256 oldRate = rewardInfo[_tokenId].tokenPerSec;
        rewardInfo[_tokenId].tokenPerSec = _tokenPerSec;

        emit RewardRateUpdated(address(rewardInfo[_tokenId].rewardToken), oldRate, _tokenPerSec);
    }

    /// @notice Function called by Master whenever staker claims WOM harvest.
    /// @notice Allows staker to also receive a 2nd reward token.
    /// @dev Assume `_getTotalShare` isn't updated yet when this function is called
    /// @param _user Address of user
    /// @param _lpAmount The new amount of LP
    function onReward(
        address _user,
        uint256 _lpAmount
    ) external virtual override onlyMaster nonReentrant returns (uint256[] memory rewards) {
        _updateReward();
        return _onReward(_user, _lpAmount);
    }

    function _onReward(address _user, uint256 _lpAmount) internal virtual returns (uint256[] memory rewards) {
        uint256 length = rewardInfo.length;
        rewards = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            RewardInfo storage reward = rewardInfo[i];
            UserInfo storage user = userInfo[i][_user];
            IERC20 rewardToken = reward.rewardToken;

            if (user.rewardDebt > 0) {
                // rewardDebt > 0 indicates the user has activated the pool and we should distribute rewards
                uint256 pending = ((user.amount * uint256(reward.accTokenPerShare)) / ACC_TOKEN_PRECISION) +
                    user.unpaidRewards -
                    user.rewardDebt;

                if (address(rewardToken) == address(0)) {
                    // is native token
                    uint256 tokenBalance = address(this).balance;
                    if (pending > tokenBalance) {
                        // Note: this line may fail if the receiver is a contract and refuse to receive BNB
                        (bool success, ) = _user.call{value: tokenBalance}('');
                        require(success, 'Transfer failed');
                        rewards[i] = tokenBalance;
                        user.unpaidRewards = pending - tokenBalance;
                    } else {
                        (bool success, ) = _user.call{value: pending}('');
                        require(success, 'Transfer failed');
                        rewards[i] = pending;
                        user.unpaidRewards = 0;
                    }
                } else {
                    // ERC20 token
                    uint256 tokenBalance = rewardToken.balanceOf(address(this));
                    if (pending > tokenBalance) {
                        rewardToken.safeTransfer(_user, tokenBalance);
                        rewards[i] = tokenBalance;
                        user.unpaidRewards = pending - tokenBalance;
                    } else {
                        rewardToken.safeTransfer(_user, pending);
                        rewards[i] = pending;
                        user.unpaidRewards = 0;
                    }
                }
            }

            user.amount = toUint128(_lpAmount);
            user.rewardDebt = toUint128((_lpAmount * reward.accTokenPerShare) / ACC_TOKEN_PRECISION);
            emit OnReward(address(rewardToken), _user, rewards[i]);
        }
    }

    /// @notice returns reward length
    function rewardLength() external view virtual override returns (uint256) {
        return _rewardLength();
    }

    function _rewardLength() internal view returns (uint256) {
        return rewardInfo.length;
    }

    /// @notice View function to see pending tokens
    /// @param _user Address of user.
    /// @return rewards reward for a given user.
    function pendingTokens(address _user) external view virtual override returns (uint256[] memory rewards) {
        return _pendingTokens(_user);
    }

    function _pendingTokens(address _user) internal view returns (uint256[] memory rewards) {
        uint256 length = rewardInfo.length;
        rewards = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            RewardInfo memory pool = rewardInfo[i];
            UserInfo storage user = userInfo[i][_user];

            uint256 accTokenPerShare = pool.accTokenPerShare;
            uint256 totalShare = _getTotalShare();

            if (block.timestamp > lastRewardTimestamp && totalShare > 0) {
                uint256 timeElapsed = block.timestamp - lastRewardTimestamp;
                uint256 tokenReward = timeElapsed * pool.tokenPerSec;
                // use `max(totalShare, 1e18)` in case of overflow
                accTokenPerShare += (tokenReward * ACC_TOKEN_PRECISION) / max(totalShare, 1e18);
            }

            rewards[i] =
                ((user.amount * uint256(accTokenPerShare)) / ACC_TOKEN_PRECISION) -
                user.rewardDebt +
                user.unpaidRewards;
        }
    }

    function _getTotalShare() internal view virtual returns (uint256) {
        return lpToken.balanceOf(address(master));
    }

    /// @notice return an array of reward tokens
    function _rewardTokens() internal view returns (IERC20[] memory tokens) {
        uint256 length = rewardInfo.length;
        tokens = new IERC20[](length);
        for (uint256 i; i < length; ++i) {
            RewardInfo memory pool = rewardInfo[i];
            tokens[i] = pool.rewardToken;
        }
    }

    function rewardTokens() external view virtual override returns (IERC20[] memory tokens) {
        return _rewardTokens();
    }

    /// @notice In case rewarder is stopped before emissions finished, this function allows
    /// withdrawal of remaining tokens.
    function emergencyWithdraw() external onlyOwner {
        uint256 length = rewardInfo.length;

        for (uint256 i; i < length; ++i) {
            RewardInfo storage pool = rewardInfo[i];
            emergencyTokenWithdraw(address(pool.rewardToken));
        }
    }

    /// @notice avoids loosing funds in case there is any tokens sent to this contract
    /// @dev only to be called by owner
    function emergencyTokenWithdraw(address token) public onlyOwner {
        // send that balance back to owner
        if (token == address(0)) {
            // is native token
            (bool success, ) = msg.sender.call{value: address(this).balance}('');
            require(success, 'Transfer failed');
        } else {
            IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    /// @notice View function to see balances of reward token.
    function balances() external view returns (uint256[] memory balances_) {
        uint256 length = rewardInfo.length;
        balances_ = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            RewardInfo storage pool = rewardInfo[i];
            if (address(pool.rewardToken) == address(0)) {
                // is native token
                balances_[i] = address(this).balance;
            } else {
                balances_[i] = pool.rewardToken.balanceOf(address(this));
            }
        }
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../interfaces/IBribeRewarderFactory.sol';
import '../interfaces/IMultiRewarderV2.sol';

/**
 * This is a sample contract to be used in the Master contract for partners to reward
 * stakers with their native token alongside WOM.
 *
 * It assumes no minting rights, so requires a set amount of reward tokens to be transferred to this contract prior.
 * E.g. say you've allocated 100,000 XYZ to the WOM-XYZ farm over 30 days. Then you would need to transfer
 * 100,000 XYZ and set the block reward accordingly so it's fully distributed after 30 days.
 *
 * - This contract has no knowledge on the LP amount and Master is
 *   responsible to pass the amount into this contract
 * - Supports multiple reward tokens
 * - Supports bribe rewarder factory
 */
contract MultiRewarderPerSecV2 is
    IMultiRewarderV2,
    Initializable,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant ROLE_OPERATOR = keccak256('operator');
    uint256 public constant ACC_TOKEN_PRECISION = 1e18;

    struct UserBalanceInfo {
        uint256 amount;
    }

    struct UserRewardInfo {
        // if the pool is activated, rewardDebt should be > 0
        uint128 rewardDebt; // 20.18 fixed point. distributed reward per weight
        uint128 unpaidRewards; // 20.18 fixed point.
    }

    /// @notice Info of each reward token.
    struct RewardInfo {
        /// slot
        IERC20 rewardToken; // if rewardToken is 0, native token is used as reward token
        uint96 tokenPerSec; // 10.18 fixed point. The emission rate in tokens per second.
        // This rate may not reflect the current rate in cases where emission has not started or has stopped due to surplus <= 0.

        /// slot
        uint128 accTokenPerShare; // 26.12 fixed point. Amount of reward token each LP token is worth.
        // This value increases when rewards are being distributed.
        uint128 distributedAmount; // 20.18 fixed point, depending on the decimals of the reward token. This value is used to
        // track the amount of distributed tokens. If `distributedAmount` is closed to the amount of total received
        // tokens, we should refill reward or prepare to stop distributing reward.

        /// slot
        uint128 claimedAmount; // 20.18 fixed point. Total amount claimed by all users.
        // We can derive the unclaimed amount: distributedAmount - claimedAmount
        uint40 lastRewardTimestamp; // The timestamp up to which rewards have already been distributed.
        // If set to a future value, it indicates that the emission has not started yet.
    }

    /**
     * Visualization of the relationship between distributedAmount, claimedAmount, rewardToDistribute, availableReward, surplus and balance:
     *
     * Case: emission is active. rewardToDistribute is growing at the rate of tokenPerSec.
     * |<--------------distributedAmount------------->|<--rewardToDistribute*-->|
     * |<-----claimedAmount----->|<-------------------------balance------------------------->|
     *                                                |<-----------availableReward*--------->|
     *                           |<-unclaimedAmount*->|                         |<-surplus*->|
     *
     * Case: reward running out. rewardToDistribute stopped growing. it is capped at availableReward.
     * |<--------------distributedAmount------------->|<---------rewardToDistribute*-------->|
     * |<-----claimedAmount----->|<-------------------------balance------------------------->|
     *                                                |<-----------availableReward*--------->|
     *                           |<-unclaimedAmount*->|                                       surplus* = 0
     *
     * Case: balance emptied after emergencyWithdraw.
     * |<--------------distributedAmount------------->| rewardToDistribute* = 0
     * |<-----claimedAmount----->|                      balance = 0, availableReward* = 0
     *                           |<-unclaimedAmount*->| surplus* = - unclaimedAmount* (negative to indicate deficit)
     *
     * (Variables with * are not in the RewardInfo state, but can be derived from it.)
     *
     * balance, is the amount of reward token in this contract. Not all of them are available for distribution as some are reserved
     * for unclaimed rewards.
     * distributedAmount, is the amount of reward token that has been distributed up to lastRewardTimestamp.
     * claimedAmount, is the amount of reward token that has been claimed by users. claimedAmount always <= distributedAmount.
     * unclaimedAmount = distributedAmount - claimedAmount, is the amount of reward token in balance that is reserved to be claimed by users.
     * availableReward = balance - unclaimedAmount, is the amount inside balance that is available for distribution (not reserved for
     * unclaimed rewards).
     * rewardToDistribute is the accumulated reward from [lastRewardTimestamp, now] that is yet to be distributed. as distributedAmount only
     * accounts for the distributed amount up to lastRewardTimestamp. it is used in _updateReward(), and to be added to distributedAmount.
     * to prevent bad debt, rewardToDistribute is capped at availableReward. as we cannot distribute more than the availableReward.
     * rewardToDistribute = min(tokenPerSec * (now - lastRewardTimestamp), availableReward)
     * surplus = availableReward - rewardToDistribute, is the amount inside balance that is available for future distribution.
     */

    IERC20 public lpToken;
    address public master;

    /// @notice Info of the reward tokens.
    RewardInfo[] public rewardInfos;
    /// @notice userAddr => UserBalanceInfo
    mapping(address => UserBalanceInfo) public userBalanceInfo;
    /// @notice tokenId => userId => UserRewardInfo
    mapping(uint256 => mapping(address => UserRewardInfo)) public userRewardInfo;

    IBribeRewarderFactory public bribeFactory;
    bool public isDeprecated;

    event OnReward(address indexed rewardToken, address indexed user, uint256 amount);
    event RewardRateUpdated(address indexed rewardToken, uint256 oldRate, uint256 newRate);
    event StartTimeUpdated(address indexed rewardToken, uint40 newStartTime);
    event IsDeprecatedUpdated(bool isDeprecated);

    modifier onlyMaster() {
        require(msg.sender == address(master), 'onlyMaster: only Master can call this function');
        _;
    }

    /// @notice payable function needed to receive BNB
    receive() external payable {}

    /**
     * @notice Initializes pool. Dev is set to be the account calling this function.
     */
    function initialize(
        IBribeRewarderFactory _bribeFactory,
        address _master,
        IERC20 _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) public virtual initializer {
        require(
            Address.isContract(address(_rewardToken)) || address(_rewardToken) == address(0),
            'constructor: reward token must be a valid contract'
        );
        require(Address.isContract(address(_lpToken)), 'constructor: LP token must be a valid contract');
        require(Address.isContract(address(_master)), 'constructor: Master must be a valid contract');
        require(_startTimestamp >= block.timestamp, 'constructor: invalid _startTimestamp');

        __Ownable_init();
        __AccessControlEnumerable_init_unchained();
        __ReentrancyGuard_init_unchained();

        bribeFactory = _bribeFactory; // bribeFactory can be 0 address
        master = _master;
        lpToken = _lpToken;

        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        RewardInfo memory reward = RewardInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18,
            distributedAmount: 0,
            claimedAmount: 0,
            lastRewardTimestamp: uint40(_startTimestamp)
        });
        emit RewardRateUpdated(address(reward.rewardToken), 0, _tokenPerSec);
        emit StartTimeUpdated(address(reward.rewardToken), uint40(_startTimestamp));
        rewardInfos.push(reward);
    }

    function addOperator(address _operator) external onlyOwner {
        _grantRole(ROLE_OPERATOR, _operator);
    }

    function removeOperator(address _operator) external onlyOwner {
        _revokeRole(ROLE_OPERATOR, _operator);
    }

    function setIsDeprecated(bool _isDeprecated) external onlyOwner {
        isDeprecated = _isDeprecated;
        emit IsDeprecatedUpdated(_isDeprecated);
    }

    function addRewardToken(IERC20 _rewardToken, uint40 _startTimestampOrNow, uint96 _tokenPerSec) external virtual {
        require(hasRole(ROLE_OPERATOR, msg.sender) || msg.sender == owner(), 'not authorized');
        // Check `bribeFactory.isRewardTokenWhitelisted` if needed
        require(
            address(bribeFactory) == address(0) || bribeFactory.isRewardTokenWhitelisted(_rewardToken),
            'reward token must be whitelisted by bribe factory'
        );

        _addRewardToken(_rewardToken, _startTimestampOrNow, _tokenPerSec);
    }

    function _addRewardToken(IERC20 _rewardToken, uint40 _startTimestampOrNow, uint96 _tokenPerSec) internal {
        require(
            Address.isContract(address(_rewardToken)) || address(_rewardToken) == address(0),
            'reward token must be a valid contract'
        );
        require(_startTimestampOrNow == 0 || _startTimestampOrNow >= block.timestamp, 'invalid _startTimestamp');
        uint256 length = rewardInfos.length;
        for (uint256 i; i < length; ++i) {
            require(rewardInfos[i].rewardToken != _rewardToken, 'token has already been added');
        }
        _updateReward();
        uint40 startTimestamp = _startTimestampOrNow == 0 ? uint40(block.timestamp) : _startTimestampOrNow;
        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        RewardInfo memory reward = RewardInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18,
            distributedAmount: 0,
            claimedAmount: 0,
            lastRewardTimestamp: startTimestamp
        });
        rewardInfos.push(reward);
        emit StartTimeUpdated(address(reward.rewardToken), startTimestamp);
        emit RewardRateUpdated(address(reward.rewardToken), 0, _tokenPerSec);
    }

    function updateReward() public {
        _updateReward();
    }

    /// @dev This function should be called before lpSupply and sumOfFactors update
    function _updateReward() internal {
        _updateReward(_getTotalShare());
    }

    function _updateReward(uint256 totalShare) internal {
        uint256 length = rewardInfos.length;
        uint256[] memory toDistribute = rewardsToDistribute();
        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            uint256 rewardToDistribute = toDistribute[i];
            if (rewardToDistribute > 0) {
                // use `max(totalShare, 1e18)` in case of overflow
                info.accTokenPerShare += toUint128((rewardToDistribute * ACC_TOKEN_PRECISION) / max(totalShare, 1e18));
                info.distributedAmount += toUint128(rewardToDistribute);
            }
            // update lastRewardTimestamp even if no reward is distributed.
            if (info.lastRewardTimestamp < block.timestamp) {
                // but don't update if info.lastRewardTimestamp is set in the future,
                // otherwise we would be starting the emission earlier than it's supposed to.
                info.lastRewardTimestamp = uint40(block.timestamp);
            }
        }
    }

    /// @notice Sets the distribution reward rate, and updates the emission start time if specified.
    /// @param _tokenId The token id
    /// @param _tokenPerSec The number of tokens to distribute per second
    /// @param _startTimestampToOverride the start time for the token emission.
    ///        A value of 0 indicates no changes, while a future timestamp starts the emission at the specified time.
    function setRewardRate(uint256 _tokenId, uint96 _tokenPerSec, uint40 _startTimestampToOverride) external {
        require(hasRole(ROLE_OPERATOR, msg.sender) || msg.sender == owner(), 'not authorized');
        require(_tokenId < rewardInfos.length, 'invalid _tokenId');
        require(
            _startTimestampToOverride == 0 || _startTimestampToOverride >= block.timestamp,
            'invalid _startTimestampToOverride'
        );
        require(_tokenPerSec <= 10000e18, 'reward rate too high'); // in case of accTokenPerShare overflow
        _updateReward();
        RewardInfo storage info = rewardInfos[_tokenId];
        uint256 oldRate = info.tokenPerSec;
        info.tokenPerSec = _tokenPerSec;
        if (_startTimestampToOverride > 0) {
            info.lastRewardTimestamp = _startTimestampToOverride;
            emit StartTimeUpdated(address(info.rewardToken), _startTimestampToOverride);
        }
        emit RewardRateUpdated(address(rewardInfos[_tokenId].rewardToken), oldRate, _tokenPerSec);
    }

    /// @notice Function called by Master whenever staker claims WOM harvest.
    /// @notice Allows staker to also receive a 2nd reward token.
    /// @dev Assume `_getTotalShare` isn't updated yet when this function is called
    /// @param _user Address of user
    /// @param _lpAmount The new amount of LP
    function onReward(
        address _user,
        uint256 _lpAmount
    ) external virtual override onlyMaster nonReentrant returns (uint256[] memory rewards) {
        _updateReward();
        return _onReward(_user, _lpAmount);
    }

    function _onReward(address _user, uint256 _lpAmount) internal virtual returns (uint256[] memory rewards) {
        uint256 length = rewardInfos.length;
        rewards = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            UserRewardInfo storage user = userRewardInfo[i][_user];
            IERC20 rewardToken = info.rewardToken;

            if (user.rewardDebt > 0 || user.unpaidRewards > 0) {
                // rewardDebt > 0 indicates the user has activated the pool and we should distribute rewards
                uint256 pending = ((userBalanceInfo[_user].amount * uint256(info.accTokenPerShare)) /
                    ACC_TOKEN_PRECISION) +
                    user.unpaidRewards -
                    user.rewardDebt;

                if (address(rewardToken) == address(0)) {
                    // is native token
                    uint256 tokenBalance = address(this).balance;
                    if (pending > tokenBalance) {
                        // Note: this line may fail if the receiver is a contract and refuse to receive BNB
                        (bool success, ) = _user.call{value: tokenBalance}('');
                        require(success, 'Transfer failed');
                        rewards[i] = tokenBalance;
                        info.claimedAmount += toUint128(tokenBalance);
                        user.unpaidRewards = toUint128(pending - tokenBalance);
                    } else {
                        (bool success, ) = _user.call{value: pending}('');
                        require(success, 'Transfer failed');
                        rewards[i] = pending;
                        info.claimedAmount += toUint128(pending);
                        user.unpaidRewards = 0;
                    }
                } else {
                    // ERC20 token
                    uint256 tokenBalance = rewardToken.balanceOf(address(this));
                    if (pending > tokenBalance) {
                        rewardToken.safeTransfer(_user, tokenBalance);
                        rewards[i] = tokenBalance;
                        info.claimedAmount += toUint128(tokenBalance);
                        user.unpaidRewards = toUint128(pending - tokenBalance);
                    } else {
                        rewardToken.safeTransfer(_user, pending);
                        rewards[i] = pending;
                        info.claimedAmount += toUint128(pending);
                        user.unpaidRewards = 0;
                    }
                }
            }

            user.rewardDebt = toUint128((_lpAmount * info.accTokenPerShare) / ACC_TOKEN_PRECISION);
            emit OnReward(address(rewardToken), _user, rewards[i]);
        }
        userBalanceInfo[_user].amount = toUint128(_lpAmount);
    }

    function emergencyClaimReward() external nonReentrant returns (uint256[] memory rewards) {
        _updateReward();
        require(isDeprecated, 'rewarder / bribe is not deprecated');
        return _onReward(msg.sender, 0);
    }

    /// @notice returns reward length
    function rewardLength() public view virtual override returns (uint256) {
        return rewardInfos.length;
    }

    /// @notice View function to see pending tokens that have been distributed but not claimed by the user yet.
    /// @param _user Address of user.
    /// @return rewards_ reward for a given user.
    function pendingTokens(address _user) public view virtual override returns (uint256[] memory rewards_) {
        uint256 length = rewardInfos.length;
        rewards_ = new uint256[](length);

        uint256[] memory toDistribute = rewardsToDistribute();
        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];
            UserRewardInfo storage user = userRewardInfo[i][_user];

            uint256 accTokenPerShare = info.accTokenPerShare;
            uint256 totalShare = _getTotalShare();
            if (totalShare > 0) {
                uint256 rewardToDistribute = toDistribute[i];
                // use `max(totalShare, 1e18)` in case of overflow
                accTokenPerShare += (rewardToDistribute * ACC_TOKEN_PRECISION) / max(totalShare, 1e18);
            }

            rewards_[i] =
                ((userBalanceInfo[_user].amount * uint256(accTokenPerShare)) / ACC_TOKEN_PRECISION) -
                user.rewardDebt +
                user.unpaidRewards;
        }
    }

    /// @notice the amount of reward accumulated since the lastRewardTimestamp and is to be distributed.
    /// the case that lastRewardTimestamp is in the future is also handled
    function rewardsToDistribute() public view returns (uint256[] memory rewards_) {
        uint256 length = rewardInfos.length;
        rewards_ = new uint256[](length);

        uint256[] memory rewardBalances = balances();

        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];
            // if (block.timestamp < info.lastRewardTimestamp), then emission has not started yet.
            if (block.timestamp < info.lastRewardTimestamp) continue;

            uint40 timeElapsed = uint40(block.timestamp) - info.lastRewardTimestamp;
            uint256 accumulatedReward = uint256(info.tokenPerSec) * timeElapsed;

            // To prevent bad debt, need to cap at availableReward
            uint256 availableReward;
            // this is to handle the underflow case if claimedAmount + balance < distributedAmount,
            // which could happend only if balance was emergencyWithdrawn.
            if (info.claimedAmount + rewardBalances[i] > info.distributedAmount) {
                availableReward = info.claimedAmount + rewardBalances[i] - info.distributedAmount;
            }
            rewards_[i] = min(accumulatedReward, availableReward);
        }
    }

    function _getTotalShare() internal view virtual returns (uint256) {
        return lpToken.balanceOf(address(master));
    }

    /// @notice return an array of reward tokens
    function rewardTokens() public view virtual override returns (IERC20[] memory tokens_) {
        uint256 length = rewardInfos.length;
        tokens_ = new IERC20[](length);
        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];
            tokens_[i] = info.rewardToken;
        }
    }

    /// @notice View function to see surplus of each reward, i.e. reward balance - unclaimed amount
    /// it would be negative if there's bad debt/deficit, which would happend only if some token was emergencyWithdrawn.
    /// @return surpluses_ surpluses of the reward tokens.
    // override.
    function rewardTokenSurpluses() external view virtual returns (int256[] memory surpluses_) {
        return _rewardTokenSurpluses();
    }

    /// @notice View function to see surplus of each reward, i.e. reward balance - unclaimed amount
    /// surplus = claimed amount + balance - distributed amount - rewardToDistribute
    /// @return surpluses_ surpluses of the reward tokens.
    function _rewardTokenSurpluses() internal view returns (int256[] memory surpluses_) {
        uint256 length = rewardInfos.length;
        surpluses_ = new int256[](length);
        uint256[] memory toDistribute = rewardsToDistribute();
        uint256[] memory rewardBalances = balances();

        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];

            surpluses_[i] =
                int256(uint256(info.claimedAmount)) +
                int256(rewardBalances[i]) -
                int256(uint256(info.distributedAmount)) -
                int256(toDistribute[i]);
        }
    }

    function isEmissionActive() external view returns (bool[] memory isActive_) {
        return _isEmissionActive();
    }

    function _isEmissionActive() internal view returns (bool[] memory isActive_) {
        uint256 length = rewardInfos.length;
        isActive_ = new bool[](length);
        int256[] memory surpluses = _rewardTokenSurpluses();
        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];

            // conditions for emission to be active:
            // 1. surplus > 0
            // 2. tokenPerSec > 0
            // 3. lastRewardTimestamp <= block.timestamp
            isActive_[i] = surpluses[i] > 0 && info.tokenPerSec > 0 && info.lastRewardTimestamp <= block.timestamp;
        }
    }

    /// @notice In case rewarder is stopped before emissions finished, this function allows
    /// withdrawal of remaining tokens.
    /// there will be deficit which is equal to the unclaimed amount
    function emergencyWithdraw() external onlyOwner {
        uint256 length = rewardInfos.length;
        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            info.tokenPerSec = 0;
            info.lastRewardTimestamp = uint40(block.timestamp);
            emergencyTokenWithdraw(address(info.rewardToken));
        }
    }

    /// @notice avoids loosing funds in case there is any tokens sent to this contract
    /// the reward token will not be stopped and keep accumulating debts
    /// @dev only to be called by owner
    function emergencyTokenWithdraw(address token) public onlyOwner {
        // send that balance back to owner
        if (token == address(0)) {
            // is native token
            (bool success, ) = msg.sender.call{value: address(this).balance}('');
            require(success, 'Transfer failed');
        } else {
            IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    /// @notice View function to see the timestamp when the reward will runout based on current emission rate and balance left.
    /// a timestamp of 0 indicates that the token is not emitting or already run out.
    /// also works for the case that emission start time (lastRewardTimestamp) is in the future.
    function runoutTimestamps() external view returns (uint40[] memory timestamps_) {
        uint256 length = rewardInfos.length;
        timestamps_ = new uint40[](length);
        uint256[] memory rewardBalances = balances();
        int256[] memory surpluses = _rewardTokenSurpluses();

        for (uint256 i; i < length; ++i) {
            RewardInfo memory info = rewardInfos[i];

            if (surpluses[i] > 0 && info.tokenPerSec > 0) {
                // we have: surplus = claimedAmount + balance - distributedAmount - tokenPerSec * (block.timestamp - lastRewardTimestamp)
                // surplus would reach 0 at runoutTimestamp. therefore, we have the formula:
                // 0 = claimedAmount + balance - distributedAmount - tokenPerSec * (runoutTimestamp - lastRewardTimestamp)
                // Solving for runoutTimestamp:
                // runoutTimestamp = (claimedAmount + balance - distributedAmount + tokenPerSec * lastRewardTimestamp) / tokenPerSec

                timestamps_[i] = uint40(
                    (info.claimedAmount +
                        rewardBalances[i] -
                        info.distributedAmount +
                        info.tokenPerSec *
                        info.lastRewardTimestamp) / info.tokenPerSec
                );
            }
        }
    }

    /// @notice View function to preserve backward compatibility, as the previous version uses rewardInfo instead of rewardInfos
    function rewardInfo(uint256 i) external view returns (RewardInfo memory info) {
        return rewardInfos[i];
    }

    /// @notice View function to see balances of reward token.
    function balances() public view returns (uint256[] memory balances_) {
        uint256 length = rewardInfos.length;
        balances_ = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            RewardInfo storage info = rewardInfos[i];
            if (address(info.rewardToken) == address(0)) {
                // is native token
                balances_[i] = address(this).balance;
            } else {
                balances_[i] = info.rewardToken.balanceOf(address(this));
            }
        }
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    uint256[50] private __gap;
}