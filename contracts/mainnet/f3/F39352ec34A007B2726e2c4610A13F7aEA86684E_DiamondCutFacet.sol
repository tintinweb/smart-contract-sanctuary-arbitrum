// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
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

    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";

contract Diamond {
    receive() external payable {}

    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../utils/Accessibility.sol";
import "../../utils/Pausable.sol";
import "./IAccountEvents.sol";
import "./AccountFacetImpl.sol";
import "../../storages/GlobalAppStorage.sol";

contract AccountFacet is Accessibility, Pausable, IAccountEvents {
    
    //Party A
    function deposit(uint256 amount) external whenNotAccountingPaused {
        AccountFacetImpl.deposit(msg.sender, amount);
        emit Deposit(msg.sender, msg.sender, amount);
    }

    function depositFor(address user, uint256 amount) external whenNotAccountingPaused {
        AccountFacetImpl.deposit(user, amount);
        emit Deposit(msg.sender, user, amount);
    }

    function withdraw(uint256 amount) external whenNotAccountingPaused notSuspended(msg.sender) {
        AccountFacetImpl.withdraw(msg.sender, amount);
        emit Withdraw(msg.sender, msg.sender, amount);
    }

    function withdrawTo(
        address user,
        uint256 amount
    ) external whenNotAccountingPaused notSuspended(msg.sender) {
        AccountFacetImpl.withdraw(user, amount);
        emit Withdraw(msg.sender, user, amount);
    }

    function allocate(
        uint256 amount
    ) external whenNotAccountingPaused notLiquidatedPartyA(msg.sender) {
        AccountFacetImpl.allocate(amount);
        emit AllocatePartyA(msg.sender, amount);
    }

    function depositAndAllocate(
        uint256 amount
    ) external whenNotAccountingPaused notLiquidatedPartyA(msg.sender) {
        AccountFacetImpl.deposit(msg.sender, amount);
        uint256 amountWith18Decimals = (amount * 1e18) /
            (10 ** IERC20Metadata(GlobalAppStorage.layout().collateral).decimals());
        AccountFacetImpl.allocate(amountWith18Decimals);
        emit Deposit(msg.sender, msg.sender, amount);
        emit AllocatePartyA(msg.sender, amountWith18Decimals);
    }

    function deallocate(
        uint256 amount,
        SingleUpnlSig memory upnlSig
    ) external whenNotAccountingPaused notLiquidatedPartyA(msg.sender) {
        AccountFacetImpl.deallocate(amount, upnlSig);
        emit DeallocatePartyA(msg.sender, amount);
    }

    // PartyB
    function allocateForPartyB(
        uint256 amount,
        address partyA
    ) public whenNotPartyBActionsPaused notLiquidatedPartyB(msg.sender, partyA) onlyPartyB {
        AccountFacetImpl.allocateForPartyB(amount, partyA);
        emit AllocateForPartyB(msg.sender, partyA, amount);
    }

    function deallocateForPartyB(
        uint256 amount,
        address partyA,
        SingleUpnlSig memory upnlSig
    ) external whenNotPartyBActionsPaused notLiquidatedPartyB(msg.sender, partyA) notLiquidatedPartyA(partyA) onlyPartyB {
        AccountFacetImpl.deallocateForPartyB(amount, partyA, upnlSig);
        emit DeallocateForPartyB(msg.sender, partyA, amount);
    }

    function transferAllocation(
        uint256 amount,
        address origin,
        address recipient,
        SingleUpnlSig memory upnlSig
    ) external whenNotPartyBActionsPaused {
        AccountFacetImpl.transferAllocation(amount, origin, recipient, upnlSig);
        emit TransferAllocation(amount, origin, recipient);
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../storages/AccountStorage.sol";
import "../../storages/GlobalAppStorage.sol";
import "../../storages/MAStorage.sol";
import "../../storages/MuonStorage.sol";
import "../../libraries/LibMuon.sol";
import "../../libraries/LibAccount.sol";

library AccountFacetImpl {
    using SafeERC20 for IERC20;

    function deposit(address user, uint256 amount) internal {
        GlobalAppStorage.Layout storage appLayout = GlobalAppStorage.layout();
        IERC20(appLayout.collateral).safeTransferFrom(msg.sender, address(this), amount);
        uint256 amountWith18Decimals = (amount * 1e18) /
        (10 ** IERC20Metadata(appLayout.collateral).decimals());
        AccountStorage.layout().balances[user] += amountWith18Decimals;
    }

    function withdraw(address user, uint256 amount) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        GlobalAppStorage.Layout storage appLayout = GlobalAppStorage.layout();
        require(
            block.timestamp >=
            accountLayout.withdrawCooldown[msg.sender] + MAStorage.layout().deallocateCooldown,
            "AccountFacet: Cooldown hasn't reached"
        );
        uint256 amountWith18Decimals = (amount * 1e18) /
        (10 ** IERC20Metadata(appLayout.collateral).decimals());
        accountLayout.balances[msg.sender] -= amountWith18Decimals;
        IERC20(appLayout.collateral).safeTransfer(user, amount);
    }

    function allocate(uint256 amount) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        require(
            accountLayout.allocatedBalances[msg.sender] + amount <=
            GlobalAppStorage.layout().balanceLimitPerUser,
            "AccountFacet: Allocated balance limit reached"
        );
        require(accountLayout.balances[msg.sender] >= amount, "AccountFacet: Insufficient balance");
        accountLayout.balances[msg.sender] -= amount;
        accountLayout.allocatedBalances[msg.sender] += amount;
    }

    function deallocate(uint256 amount, SingleUpnlSig memory upnlSig) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        require(
            accountLayout.allocatedBalances[msg.sender] >= amount,
            "AccountFacet: Insufficient allocated Balance"
        );
        LibMuon.verifyPartyAUpnl(upnlSig, msg.sender);
        int256 availableBalance = LibAccount.partyAAvailableForQuote(upnlSig.upnl, msg.sender);
        require(availableBalance >= 0, "AccountFacet: Available balance is lower than zero");
        require(uint256(availableBalance) >= amount, "AccountFacet: partyA will be liquidatable");

        accountLayout.partyANonces[msg.sender] += 1;
        accountLayout.allocatedBalances[msg.sender] -= amount;
        accountLayout.balances[msg.sender] += amount;
        accountLayout.withdrawCooldown[msg.sender] = block.timestamp;
    }

    function transferAllocation(
        uint256 amount,
        address origin,
        address recipient,
        SingleUpnlSig memory upnlSig
    ) internal {
        MAStorage.Layout storage maLayout = MAStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        require(
            !maLayout.partyBLiquidationStatus[msg.sender][origin],
            "PartyBFacet: PartyB isn't solvent"
        );
        require(
            !maLayout.partyBLiquidationStatus[msg.sender][recipient],
            "PartyBFacet: PartyB isn't solvent"
        );
        require(
            !MAStorage.layout().liquidationStatus[origin],
            "PartyBFacet: Origin isn't solvent"
        );
        require(
            !MAStorage.layout().liquidationStatus[recipient],
            "PartyBFacet: Recipient isn't solvent"
        );
        // deallocate from origin
        require(
            accountLayout.partyBAllocatedBalances[msg.sender][origin] >= amount,
            "PartyBFacet: Insufficient locked balance"
        );
        LibMuon.verifyPartyBUpnl(upnlSig, msg.sender, origin);
        int256 availableBalance = LibAccount.partyBAvailableForQuote(
            upnlSig.upnl,
            msg.sender,
            origin
        );
        require(availableBalance >= 0, "PartyBFacet: Available balance is lower than zero");
        require(uint256(availableBalance) >= amount, "PartyBFacet: Will be liquidatable");

        accountLayout.partyBNonces[msg.sender][origin] += 1;
        accountLayout.partyBAllocatedBalances[msg.sender][origin] -= amount;
        // allocate for recipient
        accountLayout.partyBAllocatedBalances[msg.sender][recipient] += amount;
    }

    function allocateForPartyB(uint256 amount, address partyA) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();

        require(accountLayout.balances[msg.sender] >= amount, "PartyBFacet: Insufficient balance");
        require(
            !MAStorage.layout().partyBLiquidationStatus[msg.sender][partyA],
            "PartyBFacet: PartyB isn't solvent"
        );
        accountLayout.balances[msg.sender] -= amount;
        accountLayout.partyBAllocatedBalances[msg.sender][partyA] += amount;
    }

    function deallocateForPartyB(
        uint256 amount,
        address partyA,
        SingleUpnlSig memory upnlSig
    ) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        require(
            accountLayout.partyBAllocatedBalances[msg.sender][partyA] >= amount,
            "PartyBFacet: Insufficient allocated balance"
        );
        LibMuon.verifyPartyBUpnl(upnlSig, msg.sender, partyA);
        int256 availableBalance = LibAccount.partyBAvailableForQuote(
            upnlSig.upnl,
            msg.sender,
            partyA
        );
        require(availableBalance >= 0, "PartyBFacet: Available balance is lower than zero");
        require(uint256(availableBalance) >= amount, "PartyBFacet: Will be liquidatable");

        accountLayout.partyBNonces[msg.sender][partyA] += 1;
        accountLayout.partyBAllocatedBalances[msg.sender][partyA] -= amount;
        accountLayout.balances[msg.sender] += amount;
        accountLayout.withdrawCooldown[msg.sender] = block.timestamp;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface IAccountEvents {
    event Deposit(address sender, address user, uint256 amount);
    event Withdraw(address sender, address user, uint256 amount);
    event AllocatePartyA(address user, uint256 amount);
    event DeallocatePartyA(address user, uint256 amount);

    event AllocateForPartyB(address partyB, address partyA, uint256 amount);
    event DeallocateForPartyB(address partyB, address partyA, uint256 amount);
    event TransferAllocation(uint256 amount, address origin, address recipient);
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../utils/Ownable.sol";
import "../../utils/Accessibility.sol";
import "../../storages/MAStorage.sol";
import "../../storages/MuonStorage.sol";
import "../../storages/GlobalAppStorage.sol";
import "../../storages/SymbolStorage.sol";
import "./IControlEvents.sol";
import "../../libraries/LibDiamond.sol";

contract ControlFacet is Accessibility, Ownable, IControlEvents {
    
    function transferOwnership(address owner) external onlyOwner{
        require(owner != address(0),"ControlFacet: Zero address");
        LibDiamond.setContractOwner(owner); 
    }

    function setAdmin(address user) external onlyOwner {
        require(user != address(0),"ControlFacet: Zero address");
        GlobalAppStorage.layout().hasRole[user][LibAccessibility.DEFAULT_ADMIN_ROLE] = true;
        emit RoleGranted(LibAccessibility.DEFAULT_ADMIN_ROLE, user);
    }

    function grantRole(
        address user,
        bytes32 role
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        require(user != address(0),"ControlFacet: Zero address");
        GlobalAppStorage.layout().hasRole[user][role] = true;
        emit RoleGranted(role, user);
    }

    function revokeRole(
        address user,
        bytes32 role
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        GlobalAppStorage.layout().hasRole[user][role] = false;
        emit RoleRevoked(role, user);
    }

    function registerPartyB(
        address partyB
    ) external onlyRole(LibAccessibility.PARTY_B_MANAGER_ROLE) {
        require(partyB != address(0), "ControlFacet: Zero address");
        require(
            !MAStorage.layout().partyBStatus[partyB],
            "ControlFacet: Address is already registered"
        );
        MAStorage.layout().partyBStatus[partyB] = true;
        MAStorage.layout().partyBList.push(partyB);
        emit RegisterPartyB(partyB);
    }

    function deregisterPartyB(
        address partyB,
        uint256 index
    ) external onlyRole(LibAccessibility.PARTY_B_MANAGER_ROLE) {
        require(partyB != address(0), "ControlFacet: Zero address");
        require(MAStorage.layout().partyBStatus[partyB], "ControlFacet: Address is not registered");
        require(MAStorage.layout().partyBList[index] == partyB, "ControlFacet: Invalid index");
        uint256 lastIndex = MAStorage.layout().partyBList.length - 1;
        require(index <= lastIndex, "ControlFacet: Invalid index");
        MAStorage.layout().partyBStatus[partyB] = false;
        MAStorage.layout().partyBList[index] = MAStorage.layout().partyBList[lastIndex];
        MAStorage.layout().partyBList.pop();
        emit DeregisterPartyB(partyB, index);
    }

    function setMuonConfig(
        uint256 upnlValidTime,
        uint256 priceValidTime,
        uint256 priceQuantityValidTime
    ) external onlyRole(LibAccessibility.MUON_SETTER_ROLE) {
        emit SetMuonConfig(upnlValidTime, priceValidTime, priceQuantityValidTime);
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        muonLayout.upnlValidTime = upnlValidTime;
        muonLayout.priceValidTime = priceValidTime;
        muonLayout.priceQuantityValidTime = priceQuantityValidTime;
    }

    function setMuonIds(
        uint256 muonAppId,
        address validGateway,
        PublicKey memory publicKey
    ) external onlyRole(LibAccessibility.MUON_SETTER_ROLE) {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        muonLayout.muonAppId = muonAppId;
        muonLayout.validGateway = validGateway;
        muonLayout.muonPublicKey = publicKey;
        emit SetMuonIds(muonAppId, validGateway, publicKey.x, publicKey.parity);
    }

    function setCollateral(
        address collateral
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        require(collateral != address(0),"ControlFacet: Zero address");
        require(
            IERC20Metadata(collateral).decimals() <= 18,
            "ControlFacet: Token with more than 18 decimals not allowed"
        );
        if (GlobalAppStorage.layout().collateral != address(0)) {
            require(
                IERC20Metadata(GlobalAppStorage.layout().collateral).balanceOf(address(this)) == 0,
                "ControlFacet: There is still collateral in the contract"
            );
        }
        GlobalAppStorage.layout().collateral = collateral;
        emit SetCollateral(collateral);
    }

    // Symbol State

    function addSymbol(
        string memory name,
        uint256 minAcceptableQuoteValue,
        uint256 minAcceptablePortionLF,
        uint256 tradingFee,
        uint256 maxLeverage,
        uint256 fundingRateEpochDuration,
        uint256 fundingRateWindowTime
    ) public onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        require(
            fundingRateWindowTime < fundingRateEpochDuration / 2,
            "ControlFacet: High window time"
        );
        require(tradingFee <= 1e18, "ControlFacet: High trading fee");
        uint256 lastId = ++SymbolStorage.layout().lastId;
        Symbol memory symbol = Symbol(
            lastId,
            name,
            true,
            minAcceptableQuoteValue,
            minAcceptablePortionLF,
            tradingFee,
            maxLeverage,
            fundingRateEpochDuration,
            fundingRateWindowTime
        );
        SymbolStorage.layout().symbols[lastId] = symbol;
        emit AddSymbol(
            lastId,
            name,
            minAcceptableQuoteValue,
            minAcceptablePortionLF,
            tradingFee, 
            maxLeverage,
            fundingRateEpochDuration,
            fundingRateWindowTime
        );
    }

    function addSymbols(
        Symbol[] memory symbols
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        for (uint8 i; i < symbols.length; i++) {
            addSymbol(
                symbols[i].name,
                symbols[i].minAcceptableQuoteValue,
                symbols[i].minAcceptablePortionLF,
                symbols[i].tradingFee,
                symbols[i].maxLeverage,
                symbols[i].fundingRateEpochDuration,
                symbols[i].fundingRateWindowTime
            );
        }
    }

    function setSymbolFundingState(
        uint256 symbolId,
        uint256 fundingRateEpochDuration,
        uint256 fundingRateWindowTime
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        require(symbolId >= 1 && symbolId <= symbolLayout.lastId, "ControlFacet: Invalid id");
        require(
            fundingRateWindowTime < fundingRateEpochDuration / 2,
            "ControlFacet: High window time"
        );
        symbolLayout.symbols[symbolId].fundingRateEpochDuration = fundingRateEpochDuration;
        symbolLayout.symbols[symbolId].fundingRateWindowTime = fundingRateWindowTime;
        emit SetSymbolFundingState(symbolId, fundingRateEpochDuration, fundingRateWindowTime);
    }

    function setSymbolValidationState(
        uint256 symbolId,
        bool isValid
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        require(symbolId >= 1 && symbolId <= symbolLayout.lastId, "ControlFacet: Invalid id");
        emit SetSymbolValidationState(symbolId, symbolLayout.symbols[symbolId].isValid, isValid);
        symbolLayout.symbols[symbolId].isValid = isValid;
    }

    function setSymbolMaxLeverage(
        uint256 symbolId,
        uint256 maxLeverage
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        require(symbolId >= 1 && symbolId <= symbolLayout.lastId, "ControlFacet: Invalid id");
        emit SetSymbolMaxLeverage(symbolId, symbolLayout.symbols[symbolId].maxLeverage, maxLeverage);
        symbolLayout.symbols[symbolId].maxLeverage = maxLeverage;
    }

    function setSymbolAcceptableValues(
        uint256 symbolId,
        uint256 minAcceptableQuoteValue,
        uint256 minAcceptablePortionLF
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        require(symbolId >= 1 && symbolId <= symbolLayout.lastId, "ControlFacet: Invalid id");
        emit SetSymbolAcceptableValues(
            symbolId,
            symbolLayout.symbols[symbolId].minAcceptableQuoteValue,
            symbolLayout.symbols[symbolId].minAcceptablePortionLF,
            minAcceptableQuoteValue,
            minAcceptablePortionLF
        );
        symbolLayout.symbols[symbolId].minAcceptableQuoteValue = minAcceptableQuoteValue;
        symbolLayout.symbols[symbolId].minAcceptablePortionLF = minAcceptablePortionLF;
    }

    function setSymbolTradingFee(
        uint256 symbolId,
        uint256 tradingFee
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        require(symbolId >= 1 && symbolId <= symbolLayout.lastId, "ControlFacet: Invalid id");
        emit SetSymbolTradingFee(symbolId, symbolLayout.symbols[symbolId].tradingFee, tradingFee);
        symbolLayout.symbols[symbolId].tradingFee = tradingFee;
    }

    /////////////////////////////////////

    // CoolDowns

    function setDeallocateCooldown(
        uint256 deallocateCooldown
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetDeallocateCooldown(MAStorage.layout().deallocateCooldown, deallocateCooldown);
        MAStorage.layout().deallocateCooldown = deallocateCooldown;
    }

    function setForceCancelCooldown(
        uint256 forceCancelCooldown
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetForceCancelCooldown(MAStorage.layout().forceCancelCooldown, forceCancelCooldown);
        MAStorage.layout().forceCancelCooldown = forceCancelCooldown;
    }

    function setForceCloseCooldown(
        uint256 forceCloseCooldown
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetForceCloseCooldown(MAStorage.layout().forceCloseCooldown, forceCloseCooldown);
        MAStorage.layout().forceCloseCooldown = forceCloseCooldown;
    }

    function setForceCancelCloseCooldown(
        uint256 forceCancelCloseCooldown
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetForceCancelCloseCooldown(
            MAStorage.layout().forceCancelCloseCooldown,
            forceCancelCloseCooldown
        );
        MAStorage.layout().forceCancelCloseCooldown = forceCancelCloseCooldown;
    }

    function setLiquidatorShare(
        uint256 liquidatorShare
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetLiquidatorShare(MAStorage.layout().liquidatorShare, liquidatorShare);
        MAStorage.layout().liquidatorShare = liquidatorShare;
    }

    function setForceCloseGapRatio(
        uint256 forceCloseGapRatio
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetForceCloseGapRatio(MAStorage.layout().forceCloseGapRatio, forceCloseGapRatio);
        MAStorage.layout().forceCloseGapRatio = forceCloseGapRatio;
    }

    function setPendingQuotesValidLength(
        uint256 pendingQuotesValidLength
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetPendingQuotesValidLength(
            MAStorage.layout().pendingQuotesValidLength,
            pendingQuotesValidLength
        );
        MAStorage.layout().pendingQuotesValidLength = pendingQuotesValidLength;
    }

    // Pause State

    function setFeeCollector(
        address feeCollector
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        require(feeCollector != address(0),"ControlFacet: Zero address");
        emit SetFeeCollector(GlobalAppStorage.layout().feeCollector, feeCollector);
        GlobalAppStorage.layout().feeCollector = feeCollector;
    }

    function pauseGlobal() external onlyRole(LibAccessibility.PAUSER_ROLE) {
        GlobalAppStorage.layout().globalPaused = true;
        emit PauseGlobal();
    }

    function pauseLiquidation() external onlyRole(LibAccessibility.PAUSER_ROLE) {
        GlobalAppStorage.layout().liquidationPaused = true;
        emit PauseLiquidation();
    }

    function pauseAccounting() external onlyRole(LibAccessibility.PAUSER_ROLE) {
        GlobalAppStorage.layout().accountingPaused = true;
        emit PauseAccounting();
    }

    function pausePartyAActions() external onlyRole(LibAccessibility.PAUSER_ROLE) {
        GlobalAppStorage.layout().partyAActionsPaused = true;
        emit PausePartyAActions();
    }

    function pausePartyBActions() external onlyRole(LibAccessibility.PAUSER_ROLE) {
        GlobalAppStorage.layout().partyBActionsPaused = true;
        emit PausePartyBActions();
    }

    function activeEmergencyMode() external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        GlobalAppStorage.layout().emergencyMode = true;
        emit ActiveEmergencyMode();
    }

    function unpauseGlobal() external onlyRole(LibAccessibility.UNPAUSER_ROLE) {
        GlobalAppStorage.layout().globalPaused = false;
        emit UnpauseGlobal();
    }

    function unpauseLiquidation() external onlyRole(LibAccessibility.UNPAUSER_ROLE) {
        GlobalAppStorage.layout().liquidationPaused = false;
        emit UnpauseLiquidation();
    }

    function unpauseAccounting() external onlyRole(LibAccessibility.UNPAUSER_ROLE) {
        GlobalAppStorage.layout().accountingPaused = false;
        emit UnpauseAccounting();
    }

    function unpausePartyAActions() external onlyRole(LibAccessibility.UNPAUSER_ROLE) {
        GlobalAppStorage.layout().partyAActionsPaused = false;
        emit UnpausePartyAActions();
    }

    function unpausePartyBActions() external onlyRole(LibAccessibility.UNPAUSER_ROLE) {
        GlobalAppStorage.layout().partyBActionsPaused = false;
        emit UnpausePartyBActions();
    }

    function setLiquidationTimeout(
        uint256 liquidationTimeout
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetLiquidationTimeout(MAStorage.layout().liquidationTimeout, liquidationTimeout);
        MAStorage.layout().liquidationTimeout = liquidationTimeout;
    }

    function suspendedAddress(
        address user
    ) external onlyRole(LibAccessibility.SUSPENDER_ROLE) {
        require(user != address(0),"ControlFacet: Zero address");
        emit SetSuspendedAddress(user, true);
        AccountStorage.layout().suspendedAddresses[user] = true;
    }

    function unsuspendedAddress(
        address user
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        require(user != address(0),"ControlFacet: Zero address");
        emit SetSuspendedAddress(user, false);
        AccountStorage.layout().suspendedAddresses[user] = false;
    }

    function deactiveEmergencyMode() external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        GlobalAppStorage.layout().emergencyMode = false;
        emit DeactiveEmergencyMode();
    }

    function setBalanceLimitPerUser(
        uint256 balanceLimitPerUser
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        emit SetBalanceLimitPerUser(balanceLimitPerUser);
        GlobalAppStorage.layout().balanceLimitPerUser = balanceLimitPerUser;
    }

    function setPartyBEmergencyStatus(
        address[] memory partyBs,
        bool status
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        for (uint8 i; i < partyBs.length; i++) {
            require(partyBs[i] != address(0),"ControlFacet: Zero address");
            GlobalAppStorage.layout().partyBEmergencyStatus[partyBs[i]] = status;
            emit SetPartyBEmergencyStatus(partyBs[i], status);
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface IControlEvents {
    event RoleGranted(bytes32 role, address user);
    event RoleRevoked(bytes32 role, address user);
    event SetMuonConfig(
        uint256 upnlValidTime,
        uint256 priceValidTime,
        uint256 priceQuantityValidTime
    );
    event SetMuonIds(uint256 muonAppId, address gateway, uint256 x, uint8 parity);
    event SetCollateral(address collateral);
    event AddSymbol(
        uint256 id,
        string name,
        uint256 minAcceptableQuoteValue,
        uint256 minAcceptablePortionLF,
        uint256 tradingFee,
        uint256 maxLeverage,
        uint256 fundingRateEpochDuration,
        uint256 fundingRateWindowTime
    );
    event SetFeeCollector(address oldFeeCollector, address newFeeCollector);
    event SetSymbolValidationState(uint256 id, bool oldState, bool isValid);
    event SetSymbolFundingState(uint256 id, uint256 fundingRateEpochDuration, uint256 fundingRateWindowTime);
    event SetSymbolAcceptableValues(
        uint256 symbolId,
        uint256 oldMinAcceptableQuoteValue,
        uint256 oldMinAcceptablePortionLF,
        uint256 minAcceptableQuoteValue,
        uint256 minAcceptablePortionLF
    );
    event SetSymbolTradingFee(uint256 symbolId, uint256 oldTradingFee, uint256 tradingFee);
    event SetSymbolMaxSlippage(uint256 symbolId, uint256 oldMaxSlippage, uint256 maxSlippage);
    event SetSymbolMaxLeverage(uint256 symbolId, uint256 oldMaxLeverage, uint256 maxLeverage);
    event SetDeallocateCooldown(uint256 oldDeallocateCooldown, uint256 newDeallocateCooldown);
    event SetForceCancelCooldown(uint256 oldForceCancelCooldown, uint256 newForceCancelCooldown);
    event SetForceCloseCooldown(uint256 oldForceCloseCooldown, uint256 newForceCloseCooldown);
    event SetForceCancelCloseCooldown(
        uint256 oldForceCancelCloseCooldown,
        uint256 newForceCancelCloseCooldown
    );
    event SetLiquidatorShare(uint256 oldLiquidatorShare, uint256 newLiquidatorShare);
    event SetForceCloseGapRatio(uint256 oldForceCloseGapRatio, uint256 newForceCloseGapRatio);
    event SetPendingQuotesValidLength(
        uint256 oldPendingQuotesValidLength,
        uint256 newPendingQuotesValidLength
    );
    event PauseGlobal();
    event PauseLiquidation();
    event PauseAccounting();
    event PausePartyAActions();
    event PausePartyBActions();
    event ActiveEmergencyMode();
    event UnpauseGlobal();
    event UnpauseLiquidation();
    event UnpauseAccounting();
    event UnpausePartyAActions();
    event UnpausePartyBActions();
    event DeactiveEmergencyMode();
    event SetLiquidationTimeout(uint256 oldLiquidationTimeout, uint256 newLiquidationTimeout);
    event SetSuspendedAddress(address user, bool isSuspended);
    event SetPartyBEmergencyStatus(address partyB, bool status);
    event SetBalanceLimitPerUser(uint256 balanceLimitPerUser);
    event RegisterPartyB(address partyB);
    event DeregisterPartyB(address partyB, uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/// @title Multicall3
/// @notice Aggregate results from multiple function calls
/// @dev Multicall & Multicall2 backwards-compatible
/// @dev Aggregate methods are marked `payable` to save 24 gas per call
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>
/// @author Andreas Bigger <[email protected]>
/// @author Matt Solomon <[email protected]>
contract Multicall3 {
    struct Call {
        address target;
        bytes callData;
    }

    struct Call3 {
        address target;
        bool allowFailure;
        bytes callData;
    }

    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice Backwards-compatible call aggregation with Multicall
    /// @param calls An array of Call structs
    /// @return blockNumber The block number where the calls were executed
    /// @return returnData An array of bytes containing the responses
    function aggregate(
        Call[] calldata calls
    ) public payable returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        uint256 length = calls.length;
        returnData = new bytes[](length);
        Call calldata call;
        for (uint256 i = 0; i < length; ) {
            bool success;
            call = calls[i];
            (success, returnData[i]) = call.target.call(call.callData);
            require(success, "Multicall3: call failed");
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Backwards-compatible with Multicall2
    /// @notice Aggregate calls without requiring success
    /// @param requireSuccess If true, require all calls to succeed
    /// @param calls An array of Call structs
    /// @return returnData An array of Result structs
    function tryAggregate(
        bool requireSuccess,
        Call[] calldata calls
    ) public payable returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata call;
        for (uint256 i = 0; i < length; ) {
            Result memory result = returnData[i];
            call = calls[i];
            (result.success, result.returnData) = call.target.call(call.callData);
            if (requireSuccess) require(result.success, "Multicall3: call failed");
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Backwards-compatible with Multicall2
    /// @notice Aggregate calls and allow failures using tryAggregate
    /// @param calls An array of Call structs
    /// @return blockNumber The block number where the calls were executed
    /// @return blockHash The hash of the block where the calls were executed
    /// @return returnData An array of Result structs
    function tryBlockAndAggregate(
        bool requireSuccess,
        Call[] calldata calls
    ) public payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
        blockNumber = block.number;
        blockHash = blockhash(block.number);
        returnData = tryAggregate(requireSuccess, calls);
    }

    /// @notice Backwards-compatible with Multicall2
    /// @notice Aggregate calls and allow failures using tryAggregate
    /// @param calls An array of Call structs
    /// @return blockNumber The block number where the calls were executed
    /// @return blockHash The hash of the block where the calls were executed
    /// @return returnData An array of Result structs
    function blockAndAggregate(
        Call[] calldata calls
    ) public payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
        (blockNumber, blockHash, returnData) = tryBlockAndAggregate(true, calls);
    }

    /// @notice Aggregate calls, ensuring each returns success if required
    /// @param calls An array of Call3 structs
    /// @return returnData An array of Result structs
    function aggregate3(
        Call3[] calldata calls
    ) public payable returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call3 calldata calli;
        for (uint256 i = 0; i < length; ) {
            Result memory result = returnData[i];
            calli = calls[i];
            (result.success, result.returnData) = calli.target.call(calli.callData);
            assembly {
                // Revert if the call fails and failure is not allowed
                // `allowFailure := calldataload(add(calli, 0x20))` and `success := mload(result)`
                if iszero(or(calldataload(add(calli, 0x20)), mload(result))) {
                    // set "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    // set data offset
                    mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
                    // set length of revert string
                    mstore(0x24, 0x0000000000000000000000000000000000000000000000000000000000000017)
                    // set revert string: bytes32(abi.encodePacked("Multicall3: call failed"))
                    mstore(0x44, 0x4d756c746963616c6c333a2063616c6c206661696c6564000000000000000000)
                    revert(0x00, 0x64)
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Aggregate calls with a msg value
    /// @notice Reverts if msg.value is less than the sum of the call values
    /// @param calls An array of Call3Value structs
    /// @return returnData An array of Result structs
    function aggregate3Value(
        Call3Value[] calldata calls
    ) public payable returns (Result[] memory returnData) {
        uint256 valAccumulator;
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call3Value calldata calli;
        for (uint256 i = 0; i < length; ) {
            Result memory result = returnData[i];
            calli = calls[i];
            uint256 val = calli.value;
            // Humanity will be a Type V Kardashev Civilization before this overflows - andreas
            // ~ 10^25 Wei in existence << ~ 10^76 size uint fits in a uint256
            unchecked {
                valAccumulator += val;
            }
            (result.success, result.returnData) = calli.target.call{ value: val }(calli.callData);
            assembly {
                // Revert if the call fails and failure is not allowed
                // `allowFailure := calldataload(add(calli, 0x20))` and `success := mload(result)`
                if iszero(or(calldataload(add(calli, 0x20)), mload(result))) {
                    // set "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    // set data offset
                    mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
                    // set length of revert string
                    mstore(0x24, 0x0000000000000000000000000000000000000000000000000000000000000017)
                    // set revert string: bytes32(abi.encodePacked("Multicall3: call failed"))
                    mstore(0x44, 0x4d756c746963616c6c333a2063616c6c206661696c6564000000000000000000)
                    revert(0x00, 0x84)
                }
            }
            unchecked {
                ++i;
            }
        }
        // Finally, make sure the msg.value = SUM(call[0...i].value)
        require(msg.value == valAccumulator, "Multicall3: value mismatch");
    }

    /// @notice Returns the block hash for the given block number
    /// @param blockNumber The block number
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    /// @notice Returns the block number
    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    /// @notice Returns the block coinbase
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    /// @notice Returns the block difficulty
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }

    /// @notice Returns the block gas limit
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    /// @notice Returns the block timestamp
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    /// @notice Returns the (ETH) balance of a given address
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    /// @notice Returns the block hash of the last block
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        unchecked {
            blockHash = blockhash(block.number - 1);
        }
    }

    /// @notice Gets the base fee of the given block
    /// @notice Can revert if the BASEFEE opcode is not implemented by the given chain
    function getBasefee() public view returns (uint256 basefee) {
        basefee = block.basefee;
    }

    /// @notice Returns the chain id
    function getChainId() public view returns (uint256 chainid) {
        chainid = block.chainid;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facets_ = new Facet[](selectorCount);
        // create an array for counting the number of selectors for each facet
        uint8[] memory numFacetSelectors = new uint8[](selectorCount);
        // total number of facets
        uint256 numFacets;
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            bool continueLoop = false;
            // find the functionSelectors array for selector and add selector to it
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facets_[facetIndex].facetAddress == facetAddress_) {
                    facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                    // probably will never have more than 256 functions from one facet contract
                    require(numFacetSelectors[facetIndex] < 255);
                    numFacetSelectors[facetIndex]++;
                    continueLoop = true;
                    break;
                }
            }
            // if functionSelectors array exists for selector then continue loop
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // create a new functionSelectors array for selector
            facets_[numFacets].facetAddress = facetAddress_;
            facets_[numFacets].functionSelectors = new bytes4[](selectorCount);
            facets_[numFacets].functionSelectors[0] = selector;
            numFacetSelectors[numFacets] = 1;
            numFacets++;
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory _facetFunctionSelectors)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](selectorCount);
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (_facet == facetAddress_) {
                _facetFunctionSelectors[numSelectors] = selector;
                numSelectors++;
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facetAddresses_ = new address[](selectorCount);
        uint256 numFacets;
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            bool continueLoop = false;
            // see if we have collected the address already and break out of loop if we have
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facetAddress_ == facetAddresses_[facetIndex]) {
                    continueLoop = true;
                    break;
                }
            }
            // continue loop if we already have the address
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // include address
            facetAddresses_[numFacets] = facetAddress_;
            numFacets++;
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet address that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.facetAddressAndSelectorPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;
import "./FundingRateFacetImpl.sol";
import "../../utils/Pausable.sol";
import "./IFundingRateEvents.sol";

contract FundingRateFacet is Pausable, IFundingRateEvents {
    
    function chargeFundingRate(
        address partyA,
        uint256[] memory quoteIds,
        int256[] memory rates,
        PairUpnlSig memory upnlSig
    ) external whenNotPartyBActionsPaused {
        FundingRateFacetImpl.chargeFundingRate(partyA, quoteIds, rates, upnlSig);
        emit ChargeFundingRate(msg.sender, partyA, quoteIds, rates);
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../libraries/LibMuon.sol";
import "../../libraries/LibAccount.sol";
import "../../libraries/LibQuote.sol";
import "../../storages/QuoteStorage.sol";
import "../../storages/AccountStorage.sol";
import "../../storages/SymbolStorage.sol";

library FundingRateFacetImpl {
    
    function chargeFundingRate(
        address partyA,
        uint256[] memory quoteIds,
        int256[] memory rates,
        PairUpnlSig memory upnlSig
    ) internal {
        LibMuon.verifyPairUpnl(upnlSig, msg.sender, partyA);
        require(quoteIds.length == rates.length && quoteIds.length > 0, "PartyBFacet: Length not match");
        int256 partyBAvailableBalance = LibAccount.partyBAvailableBalanceForLiquidation(
            upnlSig.upnlPartyB,
            msg.sender,
            partyA
        );
        int256 partyAAvailableBalance = LibAccount.partyAAvailableBalanceForLiquidation(
            upnlSig.upnlPartyA,
            partyA
        );
        uint256 epochDuration;
        uint256 windowTime;
        for (uint256 i = 0; i < quoteIds.length; i++) {
            Quote storage quote = QuoteStorage.layout().quotes[quoteIds[i]];
            require(quote.partyA == partyA, "PartyBFacet: Invalid quote");
            require(quote.partyB == msg.sender, "PartyBFacet: Sender isn't partyB of quote");
            require(
                quote.quoteStatus == QuoteStatus.OPENED ||
                    quote.quoteStatus == QuoteStatus.CLOSE_PENDING ||
                    quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING,
                "PartyBFacet: Invalid state"
            );
            epochDuration = SymbolStorage.layout().symbols[quote.symbolId].fundingRateEpochDuration;
            require(epochDuration > 0, "PartyBFacet: Zero funding epoch duration");
            windowTime = SymbolStorage.layout().symbols[quote.symbolId].fundingRateWindowTime;
            uint256 latestEpochTimestamp = (block.timestamp / epochDuration) * epochDuration;
            uint256 paidTimestamp;
            if (block.timestamp <= latestEpochTimestamp + windowTime) {
                require(
                    latestEpochTimestamp > quote.lastFundingPaymentTimestamp,
                    "PartyBFacet: Funding already paid for this window"
                );
                paidTimestamp = latestEpochTimestamp;
            } else {
                uint256 nextEpochTimestamp = latestEpochTimestamp + epochDuration;
                require(
                    block.timestamp >= nextEpochTimestamp - windowTime,
                    "PartyBFacet: Current timestamp is out of window"
                );
                require(
                    nextEpochTimestamp > quote.lastFundingPaymentTimestamp,
                    "PartyBFacet: Funding already paid for this window"
                );
                paidTimestamp = nextEpochTimestamp;
            }
            if (rates[i] >= 0) {
                require(
                    uint256(rates[i]) <= quote.maxFundingRate,
                    "PartyBFacet: High funding rate"
                );
                uint256 priceDiff = (quote.openedPrice * uint256(rates[i])) / 1e18;
                if (quote.positionType == PositionType.LONG) {
                    quote.openedPrice += priceDiff;
                } else {
                    quote.openedPrice -= priceDiff;
                }
                partyAAvailableBalance -= int256(LibQuote.quoteOpenAmount(quote) * priceDiff / 1e18);
                partyBAvailableBalance += int256(LibQuote.quoteOpenAmount(quote) * priceDiff / 1e18);
            } else {
                require(
                    uint256(-rates[i]) <= quote.maxFundingRate,
                    "PartyBFacet: High funding rate"
                );
                uint256 priceDiff = (quote.openedPrice * uint256(-rates[i])) / 1e18;
                if (quote.positionType == PositionType.LONG) {
                    quote.openedPrice -= priceDiff;
                } else {
                    quote.openedPrice += priceDiff;
                }
                partyAAvailableBalance += int256(LibQuote.quoteOpenAmount(quote) * priceDiff / 1e18);
                partyBAvailableBalance -= int256(LibQuote.quoteOpenAmount(quote) * priceDiff / 1e18);
            }
            quote.lastFundingPaymentTimestamp = paidTimestamp;
        }
        require(partyAAvailableBalance >= 0, "PartyBFacet: PartyA will be insolvent");
        require(partyBAvailableBalance >= 0, "PartyBFacet: PartyB will be insolvent");
        AccountStorage.layout().partyBNonces[msg.sender][partyA] += 1;
        AccountStorage.layout().partyANonces[partyA] += 1;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface IFundingRateEvents {
    event ChargeFundingRate(address partyB, address partyA, uint256[] quoteIds, int256[] rates);
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface ILiquidationEvents {
    event LiquidatePartyA(
        address liquidator,
        address partyA,
        uint256 allocatedBalance,
        int256 upnl,
        int256 totalUnrealizedLoss
    );
    event LiquidatePositionsPartyA(address liquidator, address partyA, uint256[] quoteIds);
    event LiquidatePendingPositionsPartyA(address liquidator, address partyA);
    event SettlePartyALiquidation(address partyA, address[] partyBs, int256[] amounts);
    event LiquidationDisputed(address partyA);
    event ResolveLiquidationDispute(
        address partyA,
        address[] partyBs,
        int256[] amounts,
        bool disputed
    );
    event FullyLiquidatedPartyA(address partyA);
    event LiquidatePartyB(
        address liquidator,
        address partyB,
        address partyA,
        uint256 partyBAllocatedBalance,
        int256 upnl
    );
    event LiquidatePositionsPartyB(
        address liquidator,
        address partyB,
        address partyA,
        uint256[] quoteIds
    );
    event FullyLiquidatedPartyB(address partyB, address partyA);
    event SetSymbolsPrices(
        address liquidator,
        address partyA,
        uint256[] symbolIds,
        uint256[] prices
    );
    event DisputeForLiquidation(address liquidator, address partyA);
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../utils/Pausable.sol";
import "../../utils/Accessibility.sol";
import "./ILiquidationEvents.sol";
import "./LiquidationFacetImpl.sol";
import "../../storages/AccountStorage.sol";

contract LiquidationFacet is Pausable, Accessibility, ILiquidationEvents {
    function liquidatePartyA(
        address partyA,
        LiquidationSig memory liquidationSig
    )
        external
        whenNotLiquidationPaused
        notLiquidatedPartyA(partyA)
        onlyRole(LibAccessibility.LIQUIDATOR_ROLE)
    {
        LiquidationFacetImpl.liquidatePartyA(partyA, liquidationSig);
        emit LiquidatePartyA(
            msg.sender,
            partyA,
            AccountStorage.layout().allocatedBalances[partyA],
            liquidationSig.upnl,
            liquidationSig.totalUnrealizedLoss
        );
    }

    function setSymbolsPrice(
        address partyA,
        LiquidationSig memory liquidationSig
    ) external whenNotLiquidationPaused onlyRole(LibAccessibility.LIQUIDATOR_ROLE) {
        LiquidationFacetImpl.setSymbolsPrice(partyA, liquidationSig);
        emit SetSymbolsPrices(msg.sender, partyA, liquidationSig.symbolIds, liquidationSig.prices);
    }

    function liquidatePendingPositionsPartyA(
        address partyA
    ) external whenNotLiquidationPaused onlyRole(LibAccessibility.LIQUIDATOR_ROLE) {
        LiquidationFacetImpl.liquidatePendingPositionsPartyA(partyA);
        emit LiquidatePendingPositionsPartyA(msg.sender, partyA);
    }

    function liquidatePositionsPartyA(
        address partyA,
        uint256[] memory quoteIds
    ) external whenNotLiquidationPaused onlyRole(LibAccessibility.LIQUIDATOR_ROLE) {
        bool disputed = LiquidationFacetImpl.liquidatePositionsPartyA(partyA, quoteIds);
        emit LiquidatePositionsPartyA(msg.sender, partyA, quoteIds);
        if (disputed) {
            emit LiquidationDisputed(partyA);
        }
    }

    function settlePartyALiquidation(
        address partyA,
        address[] memory partyBs
    ) external whenNotLiquidationPaused {
        int256[] memory settleAmounts = LiquidationFacetImpl.settlePartyALiquidation(
            partyA,
            partyBs
        );
        emit SettlePartyALiquidation(partyA, partyBs, settleAmounts);
        if (MAStorage.layout().liquidationStatus[partyA] == false) {
            emit FullyLiquidatedPartyA(partyA);
        }
    }

    function resolveLiquidationDispute(
        address partyA,
        address[] memory partyBs,
        int256[] memory amounts,
        bool disputed
    ) external onlyRole(LibAccessibility.DISPUTE_ROLE) {
        LiquidationFacetImpl.resolveLiquidationDispute(partyA, partyBs, amounts, disputed);
        emit ResolveLiquidationDispute(partyA, partyBs, amounts, disputed);
    }

    function liquidatePartyB(
        address partyB,
        address partyA,
        SingleUpnlSig memory upnlSig
    )
        external
        whenNotLiquidationPaused
        notLiquidatedPartyB(partyB, partyA)
        notLiquidatedPartyA(partyA)
        onlyRole(LibAccessibility.LIQUIDATOR_ROLE)
    {
        LiquidationFacetImpl.liquidatePartyB(partyB, partyA, upnlSig);
        emit LiquidatePartyB(
            msg.sender,
            partyB,
            partyA,
            AccountStorage.layout().partyBAllocatedBalances[partyB][partyA],
            upnlSig.upnl
        );
    }

    function liquidatePositionsPartyB(
        address partyB,
        address partyA,
        QuotePriceSig memory priceSig
    ) external whenNotLiquidationPaused onlyRole(LibAccessibility.LIQUIDATOR_ROLE) {
        LiquidationFacetImpl.liquidatePositionsPartyB(partyB, partyA, priceSig);
        emit LiquidatePositionsPartyB(msg.sender, partyB, partyA, priceSig.quoteIds);
        if (QuoteStorage.layout().partyBPositionsCount[partyB][partyA] == 0) {
            emit FullyLiquidatedPartyB(partyB, partyA);
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../libraries/LibLockedValues.sol";
import "../../libraries/LibMuon.sol";
import "../../libraries/LibAccount.sol";
import "../../libraries/LibQuote.sol";
import "../../storages/MAStorage.sol";
import "../../storages/QuoteStorage.sol";
import "../../storages/MuonStorage.sol";
import "../../storages/AccountStorage.sol";
import "../../storages/SymbolStorage.sol";

library LiquidationFacetImpl {
    using LockedValuesOps for LockedValues;

    function liquidatePartyA(address partyA, LiquidationSig memory liquidationSig) internal {
        MAStorage.Layout storage maLayout = MAStorage.layout();

        LibMuon.verifyLiquidationSig(liquidationSig, partyA);
        require(
            block.timestamp <= liquidationSig.timestamp + MuonStorage.layout().upnlValidTime,
            "LiquidationFacet: Expired signature"
        );
        int256 availableBalance = LibAccount.partyAAvailableBalanceForLiquidation(
            liquidationSig.upnl,
            partyA
        );
        require(availableBalance < 0, "LiquidationFacet: PartyA is solvent");
        maLayout.liquidationStatus[partyA] = true;
        AccountStorage.layout().liquidationDetails[partyA] = LiquidationDetail({
            liquidationId: liquidationSig.liquidationId,
            liquidationType: LiquidationType.NONE,
            upnl: liquidationSig.upnl,
            totalUnrealizedLoss: liquidationSig.totalUnrealizedLoss,
            deficit: 0,
            liquidationFee: 0,
            timestamp: liquidationSig.timestamp,
            involvedPartyBCounts: 0,
            partyAAccumulatedUpnl: 0,
            disputed: false
        });
        AccountStorage.layout().liquidators[partyA].push(msg.sender);
    }

    function setSymbolsPrice(address partyA, LiquidationSig memory liquidationSig) internal {
        MAStorage.Layout storage maLayout = MAStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();

        LibMuon.verifyLiquidationSig(liquidationSig, partyA);
        require(maLayout.liquidationStatus[partyA], "LiquidationFacet: PartyA is solvent");
        require(
            keccak256(accountLayout.liquidationDetails[partyA].liquidationId) ==
            keccak256(liquidationSig.liquidationId),
            "LiquidationFacet: Invalid liqiudationId"
        );
        for (uint256 index = 0; index < liquidationSig.symbolIds.length; index++) {
            accountLayout.symbolsPrices[partyA][liquidationSig.symbolIds[index]] = Price(
                liquidationSig.prices[index],
                accountLayout.liquidationDetails[partyA].timestamp
            );
        }

        int256 availableBalance = LibAccount.partyAAvailableBalanceForLiquidation(
            liquidationSig.upnl,
            partyA
        );
        if (accountLayout.liquidationDetails[partyA].liquidationType == LiquidationType.NONE) {
            if (uint256(- availableBalance) < accountLayout.lockedBalances[partyA].lf) {
                uint256 remainingLf = accountLayout.lockedBalances[partyA].lf -
                                    uint256(- availableBalance);
                accountLayout.liquidationDetails[partyA].liquidationType = LiquidationType.NORMAL;
                accountLayout.liquidationDetails[partyA].liquidationFee = remainingLf;
            } else if (
                uint256(- availableBalance) <=
                accountLayout.lockedBalances[partyA].lf + accountLayout.lockedBalances[partyA].cva
            ) {
                uint256 deficit = uint256(- availableBalance) -
                                        accountLayout.lockedBalances[partyA].lf;
                accountLayout.liquidationDetails[partyA].liquidationType = LiquidationType.LATE;
                accountLayout.liquidationDetails[partyA].deficit = deficit;
            } else {
                uint256 deficit = uint256(- availableBalance) -
                                        accountLayout.lockedBalances[partyA].lf -
                                        accountLayout.lockedBalances[partyA].cva;
                accountLayout.liquidationDetails[partyA].liquidationType = LiquidationType.OVERDUE;
                accountLayout.liquidationDetails[partyA].deficit = deficit;
            }
            AccountStorage.layout().liquidators[partyA].push(msg.sender);
        }
    }

    function liquidatePendingPositionsPartyA(address partyA) internal {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        require(
            MAStorage.layout().liquidationStatus[partyA],
            "LiquidationFacet: PartyA is solvent"
        );
        for (uint256 index = 0; index < quoteLayout.partyAPendingQuotes[partyA].length; index++) {
            Quote storage quote = quoteLayout.quotes[
                                    quoteLayout.partyAPendingQuotes[partyA][index]
                ];
            if (
                (quote.quoteStatus == QuoteStatus.LOCKED ||
                    quote.quoteStatus == QuoteStatus.CANCEL_PENDING) &&
                quoteLayout.partyBPendingQuotes[quote.partyB][partyA].length > 0
            ) {
                delete quoteLayout.partyBPendingQuotes[quote.partyB][partyA];
                AccountStorage
                .layout()
                .partyBPendingLockedBalances[quote.partyB][partyA].makeZero();
            }
            AccountStorage.layout().partyAReimbursement[partyA] += LibQuote.getTradingFee(quote.id);
            quote.quoteStatus = QuoteStatus.CANCELED;
            quote.statusModifyTimestamp = block.timestamp;
        }
        AccountStorage.layout().pendingLockedBalances[partyA].makeZero();
        delete quoteLayout.partyAPendingQuotes[partyA];
    }

    function liquidatePositionsPartyA(address partyA, uint256[] memory quoteIds) internal returns (bool){
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();

        require(maLayout.liquidationStatus[partyA], "LiquidationFacet: PartyA is solvent");
        for (uint256 index = 0; index < quoteIds.length; index++) {
            Quote storage quote = quoteLayout.quotes[quoteIds[index]];
            require(
                quote.quoteStatus == QuoteStatus.OPENED ||
                quote.quoteStatus == QuoteStatus.CLOSE_PENDING ||
                quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING,
                "LiquidationFacet: Invalid state"
            );
            require(
                !maLayout.partyBLiquidationStatus[quote.partyB][partyA],
                "LiquidationFacet: PartyB is in liquidation process"
            );
            require(quote.partyA == partyA, "LiquidationFacet: Invalid party");
            require(
                accountLayout.symbolsPrices[partyA][quote.symbolId].timestamp ==
                accountLayout.liquidationDetails[partyA].timestamp,
                "LiquidationFacet: Price should be set"
            );
            quote.quoteStatus = QuoteStatus.LIQUIDATED;
            quote.statusModifyTimestamp = block.timestamp;

            accountLayout.partyBNonces[quote.partyB][quote.partyA] += 1;

            (bool hasMadeProfit, uint256 amount) = LibQuote.getValueOfQuoteForPartyA(
                accountLayout.symbolsPrices[partyA][quote.symbolId].price,
                LibQuote.quoteOpenAmount(quote),
                quote
            );

            if (!accountLayout.settlementStates[partyA][quote.partyB].pending) {
                accountLayout.settlementStates[partyA][quote.partyB].pending = true;
                accountLayout.liquidationDetails[partyA].involvedPartyBCounts += 1;
            }
            if (
                accountLayout.liquidationDetails[partyA].liquidationType == LiquidationType.NORMAL
            ) {
                accountLayout.settlementStates[partyA][quote.partyB].cva += quote.lockedValues.cva;

                if (hasMadeProfit) {
                    accountLayout.settlementStates[partyA][quote.partyB].actualAmount += int256(amount);
                } else {
                    accountLayout.settlementStates[partyA][quote.partyB].actualAmount -= int256(amount);
                }
                accountLayout.settlementStates[partyA][quote.partyB].expectedAmount = accountLayout.settlementStates[partyA][quote.partyB].actualAmount;
            } else if (
                accountLayout.liquidationDetails[partyA].liquidationType == LiquidationType.LATE
            ) {
                accountLayout.settlementStates[partyA][quote.partyB].cva +=
                    quote.lockedValues.cva -
                    ((quote.lockedValues.cva * accountLayout.liquidationDetails[partyA].deficit) /
                        accountLayout.lockedBalances[partyA].cva);
                if (hasMadeProfit) {
                    accountLayout.settlementStates[partyA][quote.partyB].actualAmount += int256(amount);
                } else {
                    accountLayout.settlementStates[partyA][quote.partyB].actualAmount -= int256(amount);
                }
                accountLayout.settlementStates[partyA][quote.partyB].expectedAmount = accountLayout.settlementStates[partyA][quote.partyB].actualAmount;
            } else if (
                accountLayout.liquidationDetails[partyA].liquidationType == LiquidationType.OVERDUE
            ) {
                if (hasMadeProfit) {
                    accountLayout.settlementStates[partyA][quote.partyB].actualAmount += int256(amount);
                    accountLayout.settlementStates[partyA][quote.partyB].expectedAmount += int256(amount);
                } else {
                    accountLayout.settlementStates[partyA][quote.partyB].actualAmount -= int256(
                        amount -
                        ((amount * accountLayout.liquidationDetails[partyA].deficit) /
                            uint256(
                                - accountLayout.liquidationDetails[partyA].totalUnrealizedLoss
                            ))
                    );
                    accountLayout.settlementStates[partyA][quote.partyB].expectedAmount -= int256(amount);
                }
            }
            accountLayout.partyBLockedBalances[quote.partyB][partyA].subQuote(quote);
            quote.avgClosedPrice =
                (quote.avgClosedPrice *
                quote.closedAmount +
                    LibQuote.quoteOpenAmount(quote) *
                    accountLayout.symbolsPrices[partyA][quote.symbolId].price) /
                (quote.closedAmount + LibQuote.quoteOpenAmount(quote));
            quote.closedAmount = quote.quantity;

            LibQuote.removeFromOpenPositions(quote.id);
            quoteLayout.partyAPositionsCount[partyA] -= 1;
            quoteLayout.partyBPositionsCount[quote.partyB][partyA] -= 1;

            if (quoteLayout.partyBPositionsCount[quote.partyB][partyA] == 0) {
                int256 settleAmount = accountLayout.settlementStates[partyA][quote.partyB].expectedAmount;
                if (settleAmount < 0) {
                    accountLayout.liquidationDetails[partyA].partyAAccumulatedUpnl += settleAmount;
                } else {
                    if (
                        accountLayout.partyBAllocatedBalances[quote.partyB][partyA] >=
                        uint256(settleAmount)
                    ) {
                        accountLayout
                        .liquidationDetails[partyA]
                        .partyAAccumulatedUpnl += settleAmount;
                    } else {
                        accountLayout.liquidationDetails[partyA].partyAAccumulatedUpnl += int256(
                            accountLayout.partyBAllocatedBalances[quote.partyB][partyA]
                        );
                    }
                }
            }
        }
        if (
            quoteLayout.partyAPositionsCount[partyA] == 0 &&
            accountLayout.liquidationDetails[partyA].partyAAccumulatedUpnl !=
            accountLayout.liquidationDetails[partyA].upnl
        ) {
            accountLayout.liquidationDetails[partyA].disputed = true;
            return true;
        }
        return false;
    }

    function resolveLiquidationDispute(
        address partyA,
        address[] memory partyBs,
        int256[] memory amounts,
        bool disputed
    ) internal {
        AccountStorage.layout().liquidationDetails[partyA].disputed = disputed;
        require(partyBs.length == amounts.length, "LiquidationFacet: Invalid length");
        for (uint256 i = 0; i < partyBs.length; i++) {
            AccountStorage.layout().settlementStates[partyA][partyBs[i]].actualAmount = amounts[i];
        }
    }

    function settlePartyALiquidation(address partyA, address[] memory partyBs) internal returns (int256[] memory settleAmounts){
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        require(
            quoteLayout.partyAPositionsCount[partyA] == 0 &&
            quoteLayout.partyAPendingQuotes[partyA].length == 0,
            "LiquidationFacet: PartyA has still open positions"
        );
        require(
            MAStorage.layout().liquidationStatus[partyA],
            "LiquidationFacet: PartyA is solvent"
        );
        require(
            !accountLayout.liquidationDetails[partyA].disputed,
            "LiquidationFacet: PartyA liquidation process get disputed"
        );
        settleAmounts = new int256[](partyBs.length);
        for (uint256 i = 0; i < partyBs.length; i++) {
            address partyB = partyBs[i];
            require(
                accountLayout.settlementStates[partyA][partyB].pending,
                "LiquidationFacet: PartyB is not in settlement"
            );
            accountLayout.settlementStates[partyA][partyB].pending = false;
            accountLayout.liquidationDetails[partyA].involvedPartyBCounts -= 1;

            int256 settleAmount = accountLayout.settlementStates[partyA][partyB].actualAmount;
            accountLayout.partyBAllocatedBalances[partyB][partyA] += accountLayout
                .settlementStates[partyA][partyB].cva;
            if (settleAmount < 0) {
                accountLayout.partyBAllocatedBalances[partyB][partyA] += uint256(- settleAmount);
                settleAmounts[i] = settleAmount;
            } else {
                if (
                    accountLayout.partyBAllocatedBalances[partyB][partyA] >= uint256(settleAmount)
                ) {
                    accountLayout.partyBAllocatedBalances[partyB][partyA] -= uint256(settleAmount);
                    settleAmounts[i] = settleAmount;
                } else {
                    settleAmounts[i] = int256(accountLayout.partyBAllocatedBalances[partyB][partyA]);
                    accountLayout.partyBAllocatedBalances[partyB][partyA] = 0;
                }
            }
            delete accountLayout.settlementStates[partyA][partyB];
        }
        if (accountLayout.liquidationDetails[partyA].involvedPartyBCounts == 0) {
            accountLayout.allocatedBalances[partyA] = accountLayout.partyAReimbursement[partyA];
            accountLayout.partyAReimbursement[partyA] = 0;
            accountLayout.lockedBalances[partyA].makeZero();

            uint256 lf = accountLayout.liquidationDetails[partyA].liquidationFee;
            if (lf > 0) {
                accountLayout.allocatedBalances[accountLayout.liquidators[partyA][0]] += lf / 2;
                accountLayout.allocatedBalances[accountLayout.liquidators[partyA][1]] += lf / 2;
            }
            delete accountLayout.liquidators[partyA];
            delete accountLayout.liquidationDetails[partyA].liquidationType;
            MAStorage.layout().liquidationStatus[partyA] = false;
            accountLayout.partyANonces[partyA] += 1;
        }
    }

    function liquidatePartyB(
        address partyB,
        address partyA,
        SingleUpnlSig memory upnlSig
    ) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();

        LibMuon.verifyPartyBUpnl(upnlSig, partyB, partyA);
        int256 availableBalance = LibAccount.partyBAvailableBalanceForLiquidation(
            upnlSig.upnl,
            partyB,
            partyA
        );

        require(availableBalance < 0, "LiquidationFacet: partyB is solvent");
        uint256 liquidatorShare;
        uint256 remainingLf;
        if (uint256(- availableBalance) < accountLayout.partyBLockedBalances[partyB][partyA].lf) {
            remainingLf =
                accountLayout.partyBLockedBalances[partyB][partyA].lf -
                uint256(- availableBalance);
            liquidatorShare = (remainingLf * maLayout.liquidatorShare) / 1e18;

            maLayout.partyBPositionLiquidatorsShare[partyB][partyA] =
                (remainingLf - liquidatorShare) /
                quoteLayout.partyBPositionsCount[partyB][partyA];
        } else {
            maLayout.partyBPositionLiquidatorsShare[partyB][partyA] = 0;
        }

        maLayout.partyBLiquidationStatus[partyB][partyA] = true;
        maLayout.partyBLiquidationTimestamp[partyB][partyA] = upnlSig.timestamp;

        uint256[] storage pendingQuotes = quoteLayout.partyAPendingQuotes[partyA];

        for (uint256 index = 0; index < pendingQuotes.length;) {
            Quote storage quote = quoteLayout.quotes[pendingQuotes[index]];
            if (
                quote.partyB == partyB &&
                (quote.quoteStatus == QuoteStatus.LOCKED ||
                    quote.quoteStatus == QuoteStatus.CANCEL_PENDING)
            ) {
                accountLayout.pendingLockedBalances[partyA].subQuote(quote);
                accountLayout.allocatedBalances[partyA] += LibQuote.getTradingFee(quote.id);
                pendingQuotes[index] = pendingQuotes[pendingQuotes.length - 1];
                pendingQuotes.pop();
                quote.quoteStatus = QuoteStatus.CANCELED;
                quote.statusModifyTimestamp = block.timestamp;
            } else {
                index++;
            }
        }
        accountLayout.allocatedBalances[partyA] +=
            accountLayout.partyBAllocatedBalances[partyB][partyA] -
            remainingLf;

        delete quoteLayout.partyBPendingQuotes[partyB][partyA];
        accountLayout.partyBAllocatedBalances[partyB][partyA] = 0;
        accountLayout.partyBLockedBalances[partyB][partyA].makeZero();
        accountLayout.partyBPendingLockedBalances[partyB][partyA].makeZero();
        accountLayout.partyANonces[partyA] += 1;

        if (liquidatorShare > 0) {
            accountLayout.allocatedBalances[msg.sender] += liquidatorShare;
        }
    }

    function liquidatePositionsPartyB(
        address partyB,
        address partyA,
        QuotePriceSig memory priceSig
    ) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();

        LibMuon.verifyQuotePrices(priceSig);
        require(
            priceSig.timestamp <=
            maLayout.partyBLiquidationTimestamp[partyB][partyA] + maLayout.liquidationTimeout,
            "LiquidationFacet: Invalid signature"
        );
        require(
            maLayout.partyBLiquidationStatus[partyB][partyA],
            "LiquidationFacet: PartyB is solvent"
        );
        require(
            maLayout.partyBLiquidationTimestamp[partyB][partyA] <= priceSig.timestamp,
            "LiquidationFacet: Expired signature"
        );
        for (uint256 index = 0; index < priceSig.quoteIds.length; index++) {
            Quote storage quote = quoteLayout.quotes[priceSig.quoteIds[index]];
            require(
                quote.quoteStatus == QuoteStatus.OPENED ||
                quote.quoteStatus == QuoteStatus.CLOSE_PENDING ||
                quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING,
                "LiquidationFacet: Invalid state"
            );
            require(
                quote.partyA == partyA && quote.partyB == partyB,
                "LiquidationFacet: Invalid party"
            );

            quote.quoteStatus = QuoteStatus.LIQUIDATED;
            quote.statusModifyTimestamp = block.timestamp;

            accountLayout.lockedBalances[partyA].subQuote(quote);

            quote.avgClosedPrice =
                (quote.avgClosedPrice *
                quote.closedAmount +
                    LibQuote.quoteOpenAmount(quote) *
                    priceSig.prices[index]) /
                (quote.closedAmount + LibQuote.quoteOpenAmount(quote));
            quote.closedAmount = quote.quantity;

            LibQuote.removeFromOpenPositions(quote.id);
            quoteLayout.partyAPositionsCount[partyA] -= 1;
            quoteLayout.partyBPositionsCount[partyB][partyA] -= 1;
        }
        if (maLayout.partyBPositionLiquidatorsShare[partyB][partyA] > 0) {
            accountLayout.allocatedBalances[msg.sender] +=
                maLayout.partyBPositionLiquidatorsShare[partyB][partyA] *
                priceSig.quoteIds.length;
        }

        if (quoteLayout.partyBPositionsCount[partyB][partyA] == 0) {
            maLayout.partyBLiquidationStatus[partyB][partyA] = false;
            maLayout.partyBLiquidationTimestamp[partyB][partyA] = 0;
            accountLayout.partyBNonces[partyB][partyA] += 1;
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../storages/QuoteStorage.sol";

interface IPartyAEvents {
    event SendQuote(
        address partyA,
        uint256 quoteId,
        address[] partyBsWhiteList,
        uint256 symbolId,
        PositionType positionType,
        OrderType orderType,
        uint256 price,
        uint256 marketPrice,
        uint256 quantity,
        uint256 cva,
        uint256 lf,
        uint256 partyAmm,
        uint256 partyBmm,
        uint256 tradingFee,
        uint256 deadline
    );

    event ExpireQuote(QuoteStatus quoteStatus, uint256 quoteId);
    event RequestToCancelQuote(
        address partyA,
        address partyB,
        QuoteStatus quoteStatus,
        uint256 quoteId
    );

    event RequestToClosePosition(
        address partyA,
        address partyB,
        uint256 quoteId,
        uint256 closePrice,
        uint256 quantityToClose,
        OrderType orderType,
        uint256 deadline,
        QuoteStatus quoteStatus
    );

    event RequestToCancelCloseRequest(
        address partyA,
        address partyB,
        uint256 quoteId,
        QuoteStatus quoteStatus
    );

    event ForceCancelQuote(uint256 quoteId, QuoteStatus quoteStatus);

    event ForceCancelCloseRequest(uint256 quoteId, QuoteStatus quoteStatus);

    event ForceClosePosition(
        uint256 quoteId,
        address partyA,
        address partyB,
        uint256 filledAmount,
        uint256 closedPrice,
        QuoteStatus quoteStatus
    );
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./PartyAFacetImpl.sol";
import "../../utils/Accessibility.sol";
import "../../utils/Pausable.sol";
import "./IPartyAEvents.sol";

contract PartyAFacet is Accessibility, Pausable, IPartyAEvents {
    function sendQuote(
        address[] memory partyBsWhiteList,
        uint256 symbolId,
        PositionType positionType,
        OrderType orderType,
        uint256 price,
        uint256 quantity,
        uint256 cva,
        uint256 lf,
        uint256 partyAmm,
        uint256 partyBmm,
        uint256 maxFundingRate,
        uint256 deadline,
        SingleUpnlAndPriceSig memory upnlSig
    ) external whenNotPartyAActionsPaused notLiquidatedPartyA(msg.sender) notSuspended(msg.sender) {
        uint256 quoteId = PartyAFacetImpl.sendQuote(
            partyBsWhiteList,
            symbolId,
            positionType,
            orderType,
            price,
            quantity,
            cva,
            lf,
            partyAmm,
            partyBmm,
            maxFundingRate,
            deadline,
            upnlSig
        );
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        emit SendQuote(
            msg.sender,
            quoteId,
            partyBsWhiteList,
            symbolId,
            positionType,
            orderType,
            price,
            upnlSig.price,
            quantity,
            quote.lockedValues.cva,
            quote.lockedValues.lf,
            quote.lockedValues.partyAmm,
            quote.lockedValues.partyBmm,
            quote.tradingFee,
            deadline
        );
    }

    function expireQuote(uint256[] memory expiredQuoteIds) external whenNotPartyAActionsPaused {
        QuoteStatus result;
        for (uint8 i; i < expiredQuoteIds.length; i++) {
            result = LibQuote.expireQuote(expiredQuoteIds[i]);
            emit ExpireQuote(result, expiredQuoteIds[i]);
        }
    }

    function requestToCancelQuote(uint256 quoteId)
        external
        whenNotPartyAActionsPaused
        onlyPartyAOfQuote(quoteId)
        notLiquidated(quoteId)
    {
        QuoteStatus result = PartyAFacetImpl.requestToCancelQuote(quoteId);
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        if (result == QuoteStatus.EXPIRED) {
            emit ExpireQuote(result, quoteId);
        } else if (result == QuoteStatus.CANCELED || result == QuoteStatus.CANCEL_PENDING) {
            emit RequestToCancelQuote(quote.partyA, quote.partyB, result, quoteId);
        }
    }

    function requestToClosePosition(
        uint256 quoteId,
        uint256 closePrice,
        uint256 quantityToClose,
        OrderType orderType,
        uint256 deadline
    ) external whenNotPartyAActionsPaused onlyPartyAOfQuote(quoteId) notLiquidated(quoteId) {
        PartyAFacetImpl.requestToClosePosition(
            quoteId,
            closePrice,
            quantityToClose,
            orderType,
            deadline
        );
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        emit RequestToClosePosition(
            quote.partyA,
            quote.partyB,
            quoteId,
            closePrice,
            quantityToClose,
            orderType,
            deadline,
            QuoteStatus.CLOSE_PENDING
        );
    }

    function requestToCancelCloseRequest(uint256 quoteId)
        external
        whenNotPartyAActionsPaused
        onlyPartyAOfQuote(quoteId)
        notLiquidated(quoteId)
    {
        QuoteStatus result = PartyAFacetImpl.requestToCancelCloseRequest(quoteId);
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        if (result == QuoteStatus.OPENED) {
            emit ExpireQuote(QuoteStatus.OPENED, quoteId);
        } else if (result == QuoteStatus.CANCEL_CLOSE_PENDING) {
            emit RequestToCancelCloseRequest(
                quote.partyA,
                quote.partyB,
                quoteId,
                QuoteStatus.CANCEL_CLOSE_PENDING
            );
        }
    }

    function forceCancelQuote(uint256 quoteId)
        external
        notLiquidated(quoteId)
        whenNotPartyAActionsPaused
    {
        PartyAFacetImpl.forceCancelQuote(quoteId);
        emit ForceCancelQuote(quoteId, QuoteStatus.CANCELED);
    }

    function forceCancelCloseRequest(uint256 quoteId)
        external
        notLiquidated(quoteId)
        whenNotPartyAActionsPaused
    {
        PartyAFacetImpl.forceCancelCloseRequest(quoteId);
        emit ForceCancelCloseRequest(quoteId, QuoteStatus.OPENED);
    }

    function forceClosePosition(uint256 quoteId, PairUpnlAndPriceSig memory upnlSig)
        external
        notLiquidated(quoteId)
        whenNotPartyAActionsPaused
    {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        uint256 filledAmount = quote.quantityToClose;
        uint256 requestedClosePrice = quote.requestedClosePrice;
        PartyAFacetImpl.forceClosePosition(quoteId, upnlSig);
        emit ForceClosePosition(
            quoteId,
            quote.partyA,
            quote.partyB,
            filledAmount,
            requestedClosePrice,
            quote.quoteStatus
        );
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../libraries/LibLockedValues.sol";
import "../../libraries/LibMuon.sol";
import "../../libraries/LibAccount.sol";
import "../../libraries/LibSolvency.sol";
import "../../libraries/LibQuote.sol";
import "../../storages/MAStorage.sol";
import "../../storages/QuoteStorage.sol";
import "../../storages/MuonStorage.sol";
import "../../storages/AccountStorage.sol";
import "../../storages/SymbolStorage.sol";

library PartyAFacetImpl {
    using LockedValuesOps for LockedValues;

    function sendQuote(
        address[] memory partyBsWhiteList,
        uint256 symbolId,
        PositionType positionType,
        OrderType orderType,
        uint256 price,
        uint256 quantity,
        uint256 cva,
        uint256 lf,
        uint256 partyAmm,
        uint256 partyBmm,
        uint256 maxFundingRate,
        uint256 deadline,
        SingleUpnlAndPriceSig memory upnlSig
    ) internal returns (uint256 currentId) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();

        require(
            quoteLayout.partyAPendingQuotes[msg.sender].length < maLayout.pendingQuotesValidLength,
            "PartyAFacet: Number of pending quotes out of range"
        );
        require(symbolLayout.symbols[symbolId].isValid, "PartyAFacet: Symbol is not valid");
        require(deadline >= block.timestamp, "PartyAFacet: Low deadline");

        LockedValues memory lockedValues = LockedValues(cva, lf, partyAmm, partyBmm);
        uint256 tradingPrice = orderType == OrderType.LIMIT ? price : upnlSig.price;
        require(
            lockedValues.lf >=
                (symbolLayout.symbols[symbolId].minAcceptablePortionLF * lockedValues.totalForPartyA()) /
                    1e18,
            "PartyAFacet: LF is not enough"
        );

        require(
            lockedValues.totalForPartyA() >= symbolLayout.symbols[symbolId].minAcceptableQuoteValue,
            "PartyAFacet: Quote value is low"
        );
        for (uint8 i = 0; i < partyBsWhiteList.length; i++) {
            require(
                partyBsWhiteList[i] != msg.sender,
                "PartyAFacet: Sender isn't allowed in partyBWhiteList"
            );
        }

        LibMuon.verifyPartyAUpnlAndPrice(upnlSig, msg.sender, symbolId);

        int256 availableBalance = LibAccount.partyAAvailableForQuote(upnlSig.upnl, msg.sender);
        require(availableBalance > 0, "PartyAFacet: Available balance is lower than zero");
        require(
            uint256(availableBalance) >=
                lockedValues.totalForPartyA() +
                    ((quantity * tradingPrice * symbolLayout.symbols[symbolId].tradingFee) / 1e36),
            "PartyAFacet: insufficient available balance"
        );

        // lock funds the in middle of way
        accountLayout.pendingLockedBalances[msg.sender].add(lockedValues);
        currentId = ++quoteLayout.lastId;

        // create quote.
        Quote memory quote = Quote({
            id: currentId,
            partyBsWhiteList: partyBsWhiteList,
            symbolId: symbolId,
            positionType: positionType,
            orderType: orderType,
            openedPrice: 0,
            initialOpenedPrice: 0,
            requestedOpenPrice: price,
            marketPrice: upnlSig.price,
            quantity: quantity,
            closedAmount: 0,
            lockedValues: lockedValues,
            initialLockedValues: lockedValues,
            maxFundingRate: maxFundingRate,
            partyA: msg.sender,
            partyB: address(0),
            quoteStatus: QuoteStatus.PENDING,
            avgClosedPrice: 0,
            requestedClosePrice: 0,
            parentId: 0,
            createTimestamp: block.timestamp,
            statusModifyTimestamp: block.timestamp,
            quantityToClose: 0,
            lastFundingPaymentTimestamp: 0,
            deadline: deadline,
            tradingFee: symbolLayout.symbols[symbolId].tradingFee
        });
        quoteLayout.quoteIdsOf[msg.sender].push(currentId);
        quoteLayout.partyAPendingQuotes[msg.sender].push(currentId);
        quoteLayout.quotes[currentId] = quote;
        
        accountLayout.allocatedBalances[msg.sender] -= LibQuote.getTradingFee(currentId);
    }

    function requestToCancelQuote(uint256 quoteId) internal returns (QuoteStatus result) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(
            quote.quoteStatus == QuoteStatus.PENDING || quote.quoteStatus == QuoteStatus.LOCKED,
            "PartyAFacet: Invalid state"
        );

        if (block.timestamp > quote.deadline) {
            result = LibQuote.expireQuote(quoteId);
        } else if (quote.quoteStatus == QuoteStatus.PENDING) {
            quote.quoteStatus = QuoteStatus.CANCELED;
            accountLayout.allocatedBalances[quote.partyA] += LibQuote.getTradingFee(quote.id);
            accountLayout.pendingLockedBalances[quote.partyA].subQuote(quote);
            LibQuote.removeFromPartyAPendingQuotes(quote);
            result = QuoteStatus.CANCELED;
        } else {
            // Quote is locked
            quote.quoteStatus = QuoteStatus.CANCEL_PENDING;
            result = QuoteStatus.CANCEL_PENDING;
        }
        quote.statusModifyTimestamp = block.timestamp;
    }

    function requestToClosePosition(
        uint256 quoteId,
        uint256 closePrice,
        uint256 quantityToClose,
        OrderType orderType,
        uint256 deadline
    ) internal {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(quote.quoteStatus == QuoteStatus.OPENED, "PartyAFacet: Invalid state");
        require(deadline >= block.timestamp, "PartyAFacet: Low deadline");
        require(
            LibQuote.quoteOpenAmount(quote) >= quantityToClose,
            "PartyAFacet: Invalid quantityToClose"
        );

        // check that remaining position is not too small
        if (LibQuote.quoteOpenAmount(quote) > quantityToClose) {
            require(
                ((LibQuote.quoteOpenAmount(quote) - quantityToClose) * quote.lockedValues.totalForPartyA()) /
                    LibQuote.quoteOpenAmount(quote) >=
                    symbolLayout.symbols[quote.symbolId].minAcceptableQuoteValue,
                "PartyAFacet: Remaining quote value is low"
            );
        }

        quote.statusModifyTimestamp = block.timestamp;
        quote.quoteStatus = QuoteStatus.CLOSE_PENDING;
        quote.requestedClosePrice = closePrice;
        quote.quantityToClose = quantityToClose;
        quote.orderType = orderType;
        quote.deadline = deadline;
    }

    function requestToCancelCloseRequest(uint256 quoteId) internal returns (QuoteStatus) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(quote.quoteStatus == QuoteStatus.CLOSE_PENDING, "PartyAFacet: Invalid state");
        if (block.timestamp > quote.deadline) {
            LibQuote.expireQuote(quoteId);
            return QuoteStatus.OPENED;
        } else {
            quote.statusModifyTimestamp = block.timestamp;
            quote.quoteStatus = QuoteStatus.CANCEL_CLOSE_PENDING;
            return QuoteStatus.CANCEL_CLOSE_PENDING;
        }
    }

    function forceCancelQuote(uint256 quoteId) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(quote.quoteStatus == QuoteStatus.CANCEL_PENDING, "PartyAFacet: Invalid state");
        require(
            block.timestamp > quote.statusModifyTimestamp + maLayout.forceCancelCooldown,
            "PartyAFacet: Cooldown not reached"
        );
        quote.statusModifyTimestamp = block.timestamp;
        quote.quoteStatus = QuoteStatus.CANCELED;
        accountLayout.pendingLockedBalances[quote.partyA].subQuote(quote);
        accountLayout.partyBPendingLockedBalances[quote.partyB][quote.partyA].subQuote(quote);

        // send trading Fee back to partyA
        accountLayout.allocatedBalances[quote.partyA] += LibQuote.getTradingFee(quote.id);

        LibQuote.removeFromPendingQuotes(quote);
    }

    function forceCancelCloseRequest(uint256 quoteId) internal {
        MAStorage.Layout storage maLayout = MAStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(
            quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING,
            "PartyAFacet: Invalid state"
        );
        require(
            block.timestamp > quote.statusModifyTimestamp + maLayout.forceCancelCloseCooldown,
            "PartyAFacet: Cooldown not reached"
        );

        quote.statusModifyTimestamp = block.timestamp;
        quote.quoteStatus = QuoteStatus.OPENED;
        quote.requestedClosePrice = 0;
        quote.quantityToClose = 0;
    }

    function forceClosePosition(uint256 quoteId, PairUpnlAndPriceSig memory upnlSig) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        uint256 filledAmount = quote.quantityToClose;
        require(quote.quoteStatus == QuoteStatus.CLOSE_PENDING, "PartyAFacet: Invalid state");
        require(
            block.timestamp > quote.statusModifyTimestamp + maLayout.forceCloseCooldown,
            "PartyAFacet: Cooldown not reached"
        );
        require(block.timestamp <= quote.deadline, "PartyBFacet: Quote is expired");
        require(
            quote.orderType == OrderType.LIMIT,
            "PartyBFacet: Quote's order type should be LIMIT"
        );
        if (quote.positionType == PositionType.LONG) {
            require(
                upnlSig.price >=
                    quote.requestedClosePrice +
                        (quote.requestedClosePrice * maLayout.forceCloseGapRatio) /
                        1e18,
                "PartyAFacet: Requested close price not reached"
            );
        } else {
            require(
                upnlSig.price <=
                    quote.requestedClosePrice -
                        (quote.requestedClosePrice * maLayout.forceCloseGapRatio) /
                        1e18,
                "PartyAFacet: Requested close price not reached"
            );
        }

        LibMuon.verifyPairUpnlAndPrice(upnlSig, quote.partyB, quote.partyA, quote.symbolId);
        LibSolvency.isSolventAfterClosePosition(
            quoteId,
            filledAmount,
            upnlSig.price,
            upnlSig
        );
        accountLayout.partyANonces[quote.partyA] += 1;
        accountLayout.partyBNonces[quote.partyB][quote.partyA] += 1;
        LibQuote.closeQuote(quote, filledAmount, upnlSig.price);
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../storages/QuoteStorage.sol";

interface IPartyBEvents {
    event LockQuote(address partyB, uint256 quoteId);
    event AllocatePartyB(address partyB, address partyA, uint256 amount);
    event UnlockQuote(address partyB, uint256 quoteId, QuoteStatus quoteStatus);
    event AcceptCancelRequest(uint256 quoteId, QuoteStatus quoteStatus);
    event OpenPosition(
        uint256 quoteId,
        address partyA,
        address partyB,
        uint256 filledAmount,
        uint256 openedPrice
    );
    event FillCloseRequest(
        uint256 quoteId,
        address partyA,
        address partyB,
        uint256 filledAmount,
        uint256 closedPrice,
        QuoteStatus quoteStatus
    );
    event SendQuote(
        address partyA,
        uint256 quoteId,
        address[] partyBsWhiteList,
        uint256 symbolId,
        PositionType positionType,
        OrderType orderType,
        uint256 price,
        uint256 marketPrice,
        uint256 quantity,
        uint256 cva,
        uint256 lf,
        uint256 partyAmm,
        uint256 partyBmm,
        uint256 tradingFee,
        uint256 deadline
    );

    event ExpireQuote(QuoteStatus quoteStatus, uint256 quoteId);

    event AcceptCancelCloseRequest(uint256 quoteId, QuoteStatus quoteStatus);

    event EmergencyClosePosition(
        uint256 quoteId,
        address partyA,
        address partyB,
        uint256 filledAmount,
        uint256 closedPrice,
        QuoteStatus quoteStatus
    );
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;
import "./PartyBFacetImpl.sol";
import "../../utils/Accessibility.sol";
import "../../utils/Pausable.sol";
import "./IPartyBEvents.sol";
import "../../storages/MuonStorage.sol";
import "../Account/AccountFacetImpl.sol";

contract PartyBFacet is Accessibility, Pausable, IPartyBEvents {
    using LockedValuesOps for LockedValues;

    function lockQuote(
        uint256 quoteId,
        SingleUpnlSig memory upnlSig
    ) external whenNotPartyBActionsPaused onlyPartyB notLiquidated(quoteId) {
        PartyBFacetImpl.lockQuote(quoteId, upnlSig, true);
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        emit LockQuote(quote.partyB, quoteId);
    }

    function lockAndOpenQuote(
        uint256 quoteId,
        uint256 filledAmount,
        uint256 openedPrice,
        SingleUpnlSig memory upnlSig,
        PairUpnlAndPriceSig memory pairUpnlSig
    ) external whenNotPartyBActionsPaused onlyPartyB notLiquidated(quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        PartyBFacetImpl.lockQuote(quoteId, upnlSig, false);
        emit LockQuote(quote.partyB, quoteId);
        uint256 newId = PartyBFacetImpl.openPosition(
            quoteId,
            filledAmount,
            openedPrice,
            pairUpnlSig
        );
        emit OpenPosition(
            quoteId,
            quote.partyA,
            quote.partyB,
            filledAmount,
            openedPrice
        );
        if (newId != 0) {
            Quote storage newQuote = QuoteStorage.layout().quotes[newId];
            if (newQuote.quoteStatus == QuoteStatus.PENDING) {
                emit SendQuote(
                    newQuote.partyA,
                    newQuote.id,
                    newQuote.partyBsWhiteList,
                    newQuote.symbolId,
                    newQuote.positionType,
                    newQuote.orderType,
                    newQuote.requestedOpenPrice,
                    newQuote.marketPrice,
                    newQuote.quantity,
                    newQuote.lockedValues.cva,
                    newQuote.lockedValues.lf,
                    newQuote.lockedValues.partyAmm,
                    newQuote.lockedValues.partyBmm,
                    newQuote.tradingFee,
                    newQuote.deadline
                );
            } else if (newQuote.quoteStatus == QuoteStatus.CANCELED) {
                emit AcceptCancelRequest(newQuote.id, QuoteStatus.CANCELED);
            }
        }
    }

    function unlockQuote(
        uint256 quoteId
    ) external whenNotPartyBActionsPaused onlyPartyBOfQuote(quoteId) notLiquidated(quoteId) {
        QuoteStatus res = PartyBFacetImpl.unlockQuote(quoteId);
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        if (res == QuoteStatus.EXPIRED) {
            emit ExpireQuote(res, quoteId);
        } else if (res == QuoteStatus.PENDING) {
            emit UnlockQuote(quote.partyB, quoteId, QuoteStatus.PENDING);
        }
    }

    function acceptCancelRequest(
        uint256 quoteId
    ) external whenNotPartyBActionsPaused onlyPartyBOfQuote(quoteId) notLiquidated(quoteId) {
        PartyBFacetImpl.acceptCancelRequest(quoteId);
        emit AcceptCancelRequest(quoteId, QuoteStatus.CANCELED);
    }

    function openPosition(
        uint256 quoteId,
        uint256 filledAmount,
        uint256 openedPrice,
        PairUpnlAndPriceSig memory upnlSig
    ) external whenNotPartyBActionsPaused onlyPartyBOfQuote(quoteId) notLiquidated(quoteId) {
        uint256 newId = PartyBFacetImpl.openPosition(quoteId, filledAmount, openedPrice, upnlSig);
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        emit OpenPosition(
            quoteId,
            quote.partyA,
            quote.partyB,
            filledAmount,
            openedPrice
        );
        if (newId != 0) {
            Quote storage newQuote = QuoteStorage.layout().quotes[newId];
            if (newQuote.quoteStatus == QuoteStatus.PENDING) {
                emit SendQuote(
                    newQuote.partyA,
                    newQuote.id,
                    newQuote.partyBsWhiteList,
                    newQuote.symbolId,
                    newQuote.positionType,
                    newQuote.orderType,
                    newQuote.requestedOpenPrice,
                    newQuote.marketPrice,
                    newQuote.quantity,
                    newQuote.lockedValues.cva,
                    newQuote.lockedValues.lf,
                    newQuote.lockedValues.partyAmm,
                    newQuote.lockedValues.partyBmm,
                    newQuote.tradingFee,
                    newQuote.deadline
                );
            } else if (newQuote.quoteStatus == QuoteStatus.CANCELED) {
                emit AcceptCancelRequest(newQuote.id, QuoteStatus.CANCELED);
            }
        }
    }

    function fillCloseRequest(
        uint256 quoteId,
        uint256 filledAmount,
        uint256 closedPrice,
        PairUpnlAndPriceSig memory upnlSig
    ) external whenNotPartyBActionsPaused onlyPartyBOfQuote(quoteId) notLiquidated(quoteId) {
        PartyBFacetImpl.fillCloseRequest(quoteId, filledAmount, closedPrice, upnlSig);
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        emit FillCloseRequest(
            quoteId,
            quote.partyA,
            quote.partyB,
            filledAmount,
            closedPrice,
            quote.quoteStatus
        );
    }

    function acceptCancelCloseRequest(
        uint256 quoteId
    ) external whenNotPartyBActionsPaused onlyPartyBOfQuote(quoteId) notLiquidated(quoteId) {
        PartyBFacetImpl.acceptCancelCloseRequest(quoteId);
        emit AcceptCancelCloseRequest(quoteId, QuoteStatus.OPENED);
    }

    function emergencyClosePosition(
        uint256 quoteId,
        PairUpnlAndPriceSig memory upnlSig
    )
        external
        whenNotPartyBActionsPaused
        onlyPartyBOfQuote(quoteId)
        whenEmergencyMode(msg.sender)
        notLiquidated(quoteId)
    {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        uint256 filledAmount = LibQuote.quoteOpenAmount(quote);
        PartyBFacetImpl.emergencyClosePosition(quoteId, upnlSig);
        emit EmergencyClosePosition(
            quoteId,
            quote.partyA,
            quote.partyB,
            filledAmount,
            upnlSig.price,
            quote.quoteStatus
        );
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../../libraries/LibLockedValues.sol";
import "../../libraries/LibMuon.sol";
import "../../libraries/LibAccount.sol";
import "../../libraries/LibSolvency.sol";
import "../../libraries/LibQuote.sol";
import "../../libraries/LibPartyB.sol";
import "../../storages/MAStorage.sol";
import "../../storages/QuoteStorage.sol";
import "../../storages/MuonStorage.sol";
import "../../storages/GlobalAppStorage.sol";
import "../../storages/AccountStorage.sol";
import "../../storages/SymbolStorage.sol";

library PartyBFacetImpl {
    using LockedValuesOps for LockedValues;

    function lockQuote(uint256 quoteId, SingleUpnlSig memory upnlSig, bool increaseNonce) internal {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();

        Quote storage quote = quoteLayout.quotes[quoteId];
        LibMuon.verifyPartyBUpnl(upnlSig, msg.sender, quote.partyA);
        LibPartyB.checkPartyBValidationToLockQuote(quoteId, upnlSig.upnl);
        if (increaseNonce) {
            accountLayout.partyBNonces[msg.sender][quote.partyA] += 1;
        }
        quote.statusModifyTimestamp = block.timestamp;
        quote.quoteStatus = QuoteStatus.LOCKED;
        quote.partyB = msg.sender;
        // lock funds for partyB
        accountLayout.partyBPendingLockedBalances[msg.sender][quote.partyA].addQuote(quote);
        quoteLayout.partyBPendingQuotes[msg.sender][quote.partyA].push(quote.id);
    }

    function unlockQuote(uint256 quoteId) internal returns (QuoteStatus) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();

        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.quoteStatus == QuoteStatus.LOCKED, "PartyBFacet: Invalid state");
        if (block.timestamp > quote.deadline) {
            QuoteStatus result = LibQuote.expireQuote(quoteId);
            return result;
        } else {
            quote.statusModifyTimestamp = block.timestamp;
            quote.quoteStatus = QuoteStatus.PENDING;
            accountLayout.partyBPendingLockedBalances[quote.partyB][quote.partyA].subQuote(quote);
            LibQuote.removeFromPartyBPendingQuotes(quote);
            quote.partyB = address(0);
            return QuoteStatus.PENDING;
        }
    }

    function acceptCancelRequest(uint256 quoteId) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();

        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.quoteStatus == QuoteStatus.CANCEL_PENDING, "PartyBFacet: Invalid state");
        quote.statusModifyTimestamp = block.timestamp;
        quote.quoteStatus = QuoteStatus.CANCELED;
        accountLayout.pendingLockedBalances[quote.partyA].subQuote(quote);
        accountLayout.partyBPendingLockedBalances[quote.partyB][quote.partyA].subQuote(quote);
        // send trading Fee back to partyA
        accountLayout.allocatedBalances[quote.partyA] += LibQuote.getTradingFee(quoteId);

        LibQuote.removeFromPendingQuotes(quote);
    }

    function openPosition(
        uint256 quoteId,
        uint256 filledAmount,
        uint256 openedPrice,
        PairUpnlAndPriceSig memory upnlSig
    ) internal returns (uint256 currentId) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();

        Quote storage quote = quoteLayout.quotes[quoteId];
        require(accountLayout.suspendedAddresses[quote.partyA] == false, "PartyBFacet: PartyA is suspended");
        require(
            SymbolStorage.layout().symbols[quote.symbolId].isValid,
            "PartyBFacet: Symbol is not valid"
        );
        require(
            !AccountStorage.layout().suspendedAddresses[msg.sender],
            "PartyBFacet: Sender is Suspended"
        );

        require(!GlobalAppStorage.layout().partyBEmergencyStatus[quote.partyB], "PartyBFacet: PartyB is in emergency mode");
        require(!GlobalAppStorage.layout().emergencyMode, "PartyBFacet: System is in emergency mode");

        require(
            quote.quoteStatus == QuoteStatus.LOCKED ||
                quote.quoteStatus == QuoteStatus.CANCEL_PENDING,
            "PartyBFacet: Invalid state"
        );
        require(block.timestamp <= quote.deadline, "PartyBFacet: Quote is expired");
        if (quote.orderType == OrderType.LIMIT) {
            require(
                quote.quantity >= filledAmount && filledAmount > 0,
                "PartyBFacet: Invalid filledAmount"
            );
            accountLayout.balances[GlobalAppStorage.layout().feeCollector] +=
                (filledAmount * quote.requestedOpenPrice * quote.tradingFee) / 1e36;
        } else {
            require(quote.quantity == filledAmount, "PartyBFacet: Invalid filledAmount");
            accountLayout.balances[GlobalAppStorage.layout().feeCollector] +=
                (filledAmount * quote.marketPrice * quote.tradingFee) / 1e36;
        }
        if (quote.positionType == PositionType.LONG) {
            require(
                openedPrice <= quote.requestedOpenPrice,
                "PartyBFacet: Opened price isn't valid"
            );
        } else {
            require(
                openedPrice >= quote.requestedOpenPrice,
                "PartyBFacet: Opened price isn't valid"
            );
        }
        LibMuon.verifyPairUpnlAndPrice(upnlSig, quote.partyB, quote.partyA, quote.symbolId);

        quote.openedPrice = openedPrice;
        quote.initialOpenedPrice = openedPrice;


        accountLayout.partyANonces[quote.partyA] += 1;
        accountLayout.partyBNonces[quote.partyB][quote.partyA] += 1;
        quote.statusModifyTimestamp = block.timestamp;

        LibQuote.removeFromPendingQuotes(quote);

        if (quote.quantity == filledAmount) {
            accountLayout.pendingLockedBalances[quote.partyA].subQuote(quote);
            accountLayout.partyBPendingLockedBalances[quote.partyB][quote.partyA].subQuote(quote);
            quote.lockedValues.mul(openedPrice).div(quote.requestedOpenPrice);

            // check locked values
            require(
                quote.lockedValues.totalForPartyA() >=
                SymbolStorage.layout().symbols[quote.symbolId].minAcceptableQuoteValue,
                "PartyBFacet: Quote value is low"
            );
        }
            // partially fill
        else {
            currentId = ++quoteLayout.lastId;
            QuoteStatus newStatus;
            if (quote.quoteStatus == QuoteStatus.CANCEL_PENDING) {
                newStatus = QuoteStatus.CANCELED;
            } else {
                newStatus = QuoteStatus.PENDING;
                quoteLayout.partyAPendingQuotes[quote.partyA].push(currentId);
            }
            LockedValues memory filledLockedValues = LockedValues(
                (quote.lockedValues.cva * filledAmount) / quote.quantity,
                (quote.lockedValues.lf * filledAmount) / quote.quantity,
                (quote.lockedValues.partyAmm * filledAmount) / quote.quantity,
                (quote.lockedValues.partyBmm * filledAmount) / quote.quantity
            );
            LockedValues memory appliedFilledLockedValues = filledLockedValues;
            appliedFilledLockedValues = appliedFilledLockedValues.mulMem(openedPrice);
            appliedFilledLockedValues = appliedFilledLockedValues.divMem(quote.requestedOpenPrice);
            // check that opened position is not minor position
            require(
                appliedFilledLockedValues.totalForPartyA() >=
                    SymbolStorage.layout().symbols[quote.symbolId].minAcceptableQuoteValue,
                "PartyBFacet: Quote value is low"
            );
            // check that new pending position is not minor position
            require(
                (quote.lockedValues.totalForPartyA() - filledLockedValues.totalForPartyA()) >=
                    SymbolStorage.layout().symbols[quote.symbolId].minAcceptableQuoteValue,
                "PartyBFacet: Quote value is low"
            );

            Quote memory q = Quote({
                id: currentId,
                partyBsWhiteList: quote.partyBsWhiteList,
                symbolId: quote.symbolId,
                positionType: quote.positionType,
                orderType: quote.orderType,
                openedPrice: 0,
                initialOpenedPrice: 0,
                requestedOpenPrice: quote.requestedOpenPrice,
                marketPrice: quote.marketPrice,
                quantity: quote.quantity - filledAmount,
                closedAmount: 0,
                lockedValues: LockedValues(0, 0, 0, 0),
                initialLockedValues: LockedValues(0, 0, 0, 0),
                maxFundingRate: quote.maxFundingRate,
                partyA: quote.partyA,
                partyB: address(0),
                quoteStatus: newStatus,
                avgClosedPrice: 0,
                requestedClosePrice: 0,
                parentId: quote.id,
                createTimestamp: quote.createTimestamp,
                statusModifyTimestamp: block.timestamp,
                quantityToClose: 0,
                lastFundingPaymentTimestamp: 0,
                deadline: quote.deadline,
                tradingFee: quote.tradingFee
            });

            quoteLayout.quoteIdsOf[quote.partyA].push(currentId);
            quoteLayout.quotes[currentId] = q;
            Quote storage newQuote = quoteLayout.quotes[currentId];

            if (newStatus == QuoteStatus.CANCELED) {
                // send trading Fee back to partyA
                accountLayout.allocatedBalances[newQuote.partyA] += LibQuote.getTradingFee(newQuote.id);
                // part of quote has been filled and part of it has been canceled
                accountLayout.pendingLockedBalances[quote.partyA].subQuote(quote);
                accountLayout.partyBPendingLockedBalances[quote.partyB][quote.partyA].subQuote(
                    quote
                );
            } else {
                accountLayout.pendingLockedBalances[quote.partyA].sub(filledLockedValues);
                accountLayout.partyBPendingLockedBalances[quote.partyB][quote.partyA].subQuote(
                    quote
                );
            }
            newQuote.lockedValues = quote.lockedValues.sub(filledLockedValues);
            newQuote.initialLockedValues = newQuote.lockedValues;
            quote.quantity = filledAmount;
            quote.lockedValues = appliedFilledLockedValues;
        }
        // lock with amount of filledAmount
        accountLayout.lockedBalances[quote.partyA].addQuote(quote);
        accountLayout.partyBLockedBalances[quote.partyB][quote.partyA].addQuote(quote);

        LibSolvency.isSolventAfterOpenPosition(quoteId, filledAmount, upnlSig);
        // check leverage (is in 18 decimals)
        require(
            quote.quantity * quote.openedPrice / quote.lockedValues.totalForPartyA() <= SymbolStorage.layout().symbols[quote.symbolId].maxLeverage,
            "PartyBFacet: Leverage is high"
        );

        quote.quoteStatus = QuoteStatus.OPENED;
        LibQuote.addToOpenPositions(quoteId);
    }

    function fillCloseRequest(
        uint256 quoteId,
        uint256 filledAmount,
        uint256 closedPrice,
        PairUpnlAndPriceSig memory upnlSig
    ) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(
            quote.quoteStatus == QuoteStatus.CLOSE_PENDING ||
                quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING,
            "PartyBFacet: Invalid state"
        );
        require(block.timestamp <= quote.deadline, "PartyBFacet: Quote is expired");
        if (quote.positionType == PositionType.LONG) {
            require(
                closedPrice >= quote.requestedClosePrice,
                "PartyBFacet: Closed price isn't valid"
            );
        } else {
            require(
                closedPrice <= quote.requestedClosePrice,
                "PartyBFacet: Closed price isn't valid"
            );
        }
        if (quote.orderType == OrderType.LIMIT) {
            require(quote.quantityToClose >= filledAmount, "PartyBFacet: Invalid filledAmount");
        } else {
            require(quote.quantityToClose == filledAmount, "PartyBFacet: Invalid filledAmount");
        }

        LibMuon.verifyPairUpnlAndPrice(upnlSig, quote.partyB, quote.partyA, quote.symbolId);
        LibSolvency.isSolventAfterClosePosition(quoteId, filledAmount, closedPrice, upnlSig);

        accountLayout.partyBNonces[quote.partyB][quote.partyA] += 1;
        accountLayout.partyANonces[quote.partyA] += 1;
        LibQuote.closeQuote(quote, filledAmount, closedPrice);
    }

    function acceptCancelCloseRequest(uint256 quoteId) internal {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];

        require(
            quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING,
            "PartyBFacet: Invalid state"
        );
        quote.statusModifyTimestamp = block.timestamp;
        quote.quoteStatus = QuoteStatus.OPENED;
        quote.requestedClosePrice = 0;
        quote.quantityToClose = 0;
    }

    function emergencyClosePosition(uint256 quoteId, PairUpnlAndPriceSig memory upnlSig) internal {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.quoteStatus == QuoteStatus.OPENED || quote.quoteStatus == QuoteStatus.CLOSE_PENDING, "PartyBFacet: Invalid state");
        LibMuon.verifyPairUpnlAndPrice(upnlSig, quote.partyB, quote.partyA, quote.symbolId);
        uint256 filledAmount = LibQuote.quoteOpenAmount(quote);
        quote.quantityToClose = filledAmount;
        quote.requestedClosePrice = upnlSig.price;
        LibSolvency.isSolventAfterClosePosition(quoteId, filledAmount, upnlSig.price, upnlSig);
        accountLayout.partyBNonces[quote.partyB][quote.partyA] += 1;
        accountLayout.partyANonces[quote.partyA] += 1;
        LibQuote.closeQuote(quote, filledAmount, upnlSig.price);
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";
import "../libraries/LibQuote.sol";
import "../libraries/LibMuon.sol";
import "../storages/AccountStorage.sol";
import "../storages/MAStorage.sol";
import "../storages/QuoteStorage.sol";
import "../storages/GlobalAppStorage.sol";
import "../storages/SymbolStorage.sol";
import "../storages/MuonStorage.sol";
import "../libraries/LibLockedValues.sol";

contract ViewFacet {
    using LockedValuesOps for LockedValues;

    struct Bitmap {
        uint256 size;
        BitmapElement[] elements;
    }

    struct BitmapElement {
        uint256 offset;
        uint256 bitmap;
    }

    // Account
    function balanceOf(address user) external view returns (uint256) {
        return AccountStorage.layout().balances[user];
    }

    function partyAStats(
        address partyA
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        return (
            maLayout.liquidationStatus[partyA],
            accountLayout.allocatedBalances[partyA],
            accountLayout.lockedBalances[partyA].cva,
            accountLayout.lockedBalances[partyA].lf,
            accountLayout.lockedBalances[partyA].partyAmm,
            accountLayout.lockedBalances[partyA].partyBmm,
            accountLayout.pendingLockedBalances[partyA].cva,
            accountLayout.pendingLockedBalances[partyA].lf,
            accountLayout.pendingLockedBalances[partyA].partyAmm,
            accountLayout.pendingLockedBalances[partyA].partyBmm,
            quoteLayout.partyAPositionsCount[partyA],
            quoteLayout.partyAPendingQuotes[partyA].length,
            accountLayout.partyANonces[partyA],
            quoteLayout.quoteIdsOf[partyA].length
        );
    }

    function balanceInfoOfPartyA(
        address partyA
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        return (
            accountLayout.allocatedBalances[partyA],
            accountLayout.lockedBalances[partyA].cva,
            accountLayout.lockedBalances[partyA].lf,
            accountLayout.lockedBalances[partyA].partyAmm,
            accountLayout.lockedBalances[partyA].partyBmm,
            accountLayout.pendingLockedBalances[partyA].cva,
            accountLayout.pendingLockedBalances[partyA].lf,
            accountLayout.pendingLockedBalances[partyA].partyAmm,
            accountLayout.pendingLockedBalances[partyA].partyBmm
        );
    }

    function balanceInfoOfPartyB(
        address partyB,
        address partyA
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        return (
            accountLayout.partyBAllocatedBalances[partyB][partyA],
            accountLayout.partyBLockedBalances[partyB][partyA].cva,
            accountLayout.partyBLockedBalances[partyB][partyA].lf,
            accountLayout.partyBLockedBalances[partyB][partyA].partyAmm,
            accountLayout.partyBLockedBalances[partyB][partyA].partyBmm,
            accountLayout.partyBPendingLockedBalances[partyB][partyA].cva,
            accountLayout.partyBPendingLockedBalances[partyB][partyA].lf,
            accountLayout.partyBPendingLockedBalances[partyB][partyA].partyAmm,
            accountLayout.partyBPendingLockedBalances[partyB][partyA].partyBmm
        );
    }

    function allocatedBalanceOfPartyA(address partyA) external view returns (uint256) {
        return AccountStorage.layout().allocatedBalances[partyA];
    }

    function allocatedBalanceOfPartyB(
        address partyB,
        address partyA
    ) external view returns (uint256) {
        return AccountStorage.layout().partyBAllocatedBalances[partyB][partyA];
    }

    function allocatedBalanceOfPartyBs(
        address partyA,
        address[] memory partyBs
    ) external view returns (uint256[] memory) {
        uint256[] memory allocatedBalances = new uint256[](partyBs.length);
        for (uint256 i = 0; i < partyBs.length; i++) {
            allocatedBalances[i] = AccountStorage.layout().partyBAllocatedBalances[partyBs[i]][
                partyA
            ];
        }
        return allocatedBalances;
    }

    function withdrawCooldownOf(address user) external view returns (uint256) {
        return AccountStorage.layout().withdrawCooldown[user];
    }

    function nonceOfPartyA(address partyA) external view returns (uint256) {
        return AccountStorage.layout().partyANonces[partyA];
    }

    function nonceOfPartyB(address partyB, address partyA) external view returns (uint256) {
        return AccountStorage.layout().partyBNonces[partyB][partyA];
    }

    function isSuspended(address user) external view returns (bool) {
        return AccountStorage.layout().suspendedAddresses[user];
    }

    function getLiquidatedStateOfPartyA(
        address partyA
    ) external view returns (LiquidationDetail memory) {
        return AccountStorage.layout().liquidationDetails[partyA];
    }

    function getSettlementStates(
        address partyA,
        address[] memory partyBs
    ) external view returns (SettlementState[] memory) {
        SettlementState[] memory states = new SettlementState[](partyBs.length);
        for (uint256 i = 0; i < partyBs.length; i++) {
            states[i] = AccountStorage.layout().settlementStates[partyA][partyBs[i]];
        }
        return states;
    }

    ///////////////////////////////////////////

    // Symbols
    function getSymbol(uint256 symbolId) external view returns (Symbol memory) {
        return SymbolStorage.layout().symbols[symbolId];
    }

    function getSymbols(uint256 start, uint256 size) external view returns (Symbol[] memory) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        if (symbolLayout.lastId < start + size) {
            size = symbolLayout.lastId - start;
        }
        Symbol[] memory symbols = new Symbol[](size);
        for (uint256 i = start; i < start + size; i++) {
            symbols[i - start] = symbolLayout.symbols[i + 1];
        }
        return symbols;
    }

    function symbolsByQuoteId(uint256[] memory quoteIds) external view returns (Symbol[] memory) {
        Symbol[] memory symbols = new Symbol[](quoteIds.length);
        for (uint256 i = 0; i < quoteIds.length; i++) {
            symbols[i] = SymbolStorage.layout().symbols[
                QuoteStorage.layout().quotes[quoteIds[i]].symbolId
            ];
        }
        return symbols;
    }

    function symbolNameByQuoteId(
        uint256[] memory quoteIds
    ) external view returns (string[] memory) {
        string[] memory symbols = new string[](quoteIds.length);
        for (uint256 i = 0; i < quoteIds.length; i++) {
            symbols[i] = SymbolStorage
                .layout()
                .symbols[QuoteStorage.layout().quotes[quoteIds[i]].symbolId]
                .name;
        }
        return symbols;
    }

    function symbolNameById(uint256[] memory symbolIds) external view returns (string[] memory) {
        string[] memory symbols = new string[](symbolIds.length);
        for (uint256 i = 0; i < symbolIds.length; i++) {
            symbols[i] = SymbolStorage.layout().symbols[symbolIds[i]].name;
        }
        return symbols;
    }

    ////////////////////////////////////

    // Quotes
    function getQuote(uint256 quoteId) external view returns (Quote memory) {
        return QuoteStorage.layout().quotes[quoteId];
    }

    function getQuotesByParent(
        uint256 quoteId,
        uint256 size
    ) external view returns (Quote[] memory) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        Quote[] memory quotes = new Quote[](size);
        Quote memory quote = quoteLayout.quotes[quoteId];
        quotes[0] = quote;
        for (uint256 i = 1; i < size; i++) {
            if (quote.parentId == 0) {
                break;
            }
            quote = quoteLayout.quotes[quote.parentId];
            quotes[i] = quote;
        }
        return quotes;
    }

    function quoteIdsOf(
        address partyA,
        uint256 start,
        uint256 size
    ) external view returns (uint256[] memory) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        if (quoteLayout.quoteIdsOf[partyA].length < start + size) {
            size = quoteLayout.quoteIdsOf[partyA].length - start;
        }
        uint256[] memory quoteIds = new uint256[](size);
        for (uint256 i = start; i < start + size; i++) {
            quoteIds[i - start] = quoteLayout.quoteIdsOf[partyA][i];
        }
        return quoteIds;
    }

    function getQuotes(
        address partyA,
        uint256 start,
        uint256 size
    ) external view returns (Quote[] memory) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        if (quoteLayout.quoteIdsOf[partyA].length < start + size) {
            size = quoteLayout.quoteIdsOf[partyA].length - start;
        }
        Quote[] memory quotes = new Quote[](size);
        for (uint256 i = start; i < start + size; i++) {
            quotes[i - start] = quoteLayout.quotes[quoteLayout.quoteIdsOf[partyA][i]];
        }
        return quotes;
    }

    function quotesLength(address user) external view returns (uint256) {
        return QuoteStorage.layout().quoteIdsOf[user].length;
    }

    function partyAPositionsCount(address partyA) external view returns (uint256) {
        return QuoteStorage.layout().partyAPositionsCount[partyA];
    }

    function getPartyAOpenPositions(
        address partyA,
        uint256 start,
        uint256 size
    ) external view returns (Quote[] memory) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        if (quoteLayout.partyAOpenPositions[partyA].length < start + size) {
            size = quoteLayout.partyAOpenPositions[partyA].length - start;
        }
        Quote[] memory quotes = new Quote[](size);
        for (uint256 i = start; i < start + size; i++) {
            quotes[i - start] = quoteLayout.quotes[quoteLayout.partyAOpenPositions[partyA][i]];
        }
        return quotes;
    }

    function getPartyBOpenPositions(
        address partyB,
        address partyA,
        uint256 start,
        uint256 size
    ) external view returns (Quote[] memory) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        if (quoteLayout.partyBOpenPositions[partyB][partyA].length < start + size) {
            size = quoteLayout.partyBOpenPositions[partyB][partyA].length - start;
        }
        Quote[] memory quotes = new Quote[](size);
        for (uint256 i = start; i < start + size; i++) {
            quotes[i - start] = quoteLayout.quotes[
                quoteLayout.partyBOpenPositions[partyB][partyA][i]
            ];
        }
        return quotes;
    }

    function partyBPositionsCount(address partyB, address partyA) external view returns (uint256) {
        return QuoteStorage.layout().partyBPositionsCount[partyB][partyA];
    }

    function getPartyAPendingQuotes(address partyA) external view returns (uint256[] memory) {
        return QuoteStorage.layout().partyAPendingQuotes[partyA];
    }

    function getPartyBPendingQuotes(
        address partyB,
        address partyA
    ) external view returns (uint256[] memory) {
        return QuoteStorage.layout().partyBPendingQuotes[partyB][partyA];
    }

    /////////////////////////////////////

    // Role
    function hasRole(address user, bytes32 role) external view returns (bool) {
        return GlobalAppStorage.layout().hasRole[user][role];
    }

    function getRoleHash(string memory str) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }

    //////////////////////////////////////

    // MA
    function getCollateral() external view returns (address) {
        return GlobalAppStorage.layout().collateral;
    }

    function getFeeCollector() external view returns (address) {
        return GlobalAppStorage.layout().feeCollector;
    }

    function isPartyALiquidated(address partyA) external view returns (bool) {
        return MAStorage.layout().liquidationStatus[partyA];
    }

    function isPartyBLiquidated(address partyB, address partyA) external view returns (bool) {
        return MAStorage.layout().partyBLiquidationStatus[partyB][partyA];
    }

    function isPartyB(address user) external view returns (bool) {
        return MAStorage.layout().partyBStatus[user];
    }

    function pendingQuotesValidLength() external view returns (uint256) {
        return MAStorage.layout().pendingQuotesValidLength;
    }

    function forceCloseGapRatio() external view returns (uint256) {
        return MAStorage.layout().forceCloseGapRatio;
    }

    function liquidatorShare() external view returns (uint256) {
        return MAStorage.layout().liquidatorShare;
    }

    function liquidationTimeout() external view returns (uint256) {
        return MAStorage.layout().liquidationTimeout;
    }

    function partyBLiquidationTimestamp(
        address partyB,
        address partyA
    ) external view returns (uint256) {
        return MAStorage.layout().partyBLiquidationTimestamp[partyB][partyA];
    }

    function coolDownsOfMA() external view returns (uint256, uint256, uint256, uint256) {
        return (
            MAStorage.layout().deallocateCooldown,
            MAStorage.layout().forceCancelCooldown,
            MAStorage.layout().forceCancelCloseCooldown,
            MAStorage.layout().forceCloseCooldown
        );
    }

    ///////////////////////////////////////////

    function getMuonConfig()
        external
        view
        returns (uint256 upnlValidTime, uint256 priceValidTime, uint256 priceQuantityValidTime)
    {
        upnlValidTime = MuonStorage.layout().upnlValidTime;
        priceValidTime = MuonStorage.layout().priceValidTime;
        priceQuantityValidTime = MuonStorage.layout().priceQuantityValidTime;
    }

    function getMuonIds()
        external
        view
        returns (uint256 muonAppId, PublicKey memory muonPublicKey, address validGateway)
    {
        muonAppId = MuonStorage.layout().muonAppId;
        muonPublicKey = MuonStorage.layout().muonPublicKey;
        validGateway = MuonStorage.layout().validGateway;
    }

    function pauseState()
        external
        view
        returns (
            bool globalPaused,
            bool liquidationPaused,
            bool accountingPaused,
            bool partyBActionsPaused,
            bool partyAActionsPaused,
            bool emergencyMode
        )
    {
        GlobalAppStorage.Layout storage appLayout = GlobalAppStorage.layout();
        return (
            appLayout.globalPaused,
            appLayout.liquidationPaused,
            appLayout.accountingPaused,
            appLayout.partyBActionsPaused,
            appLayout.partyAActionsPaused,
            appLayout.emergencyMode
        );
    }

    function getPartyBEmergencyStatus(address partyB) external view returns (bool isEmergency) {
        return GlobalAppStorage.layout().partyBEmergencyStatus[partyB];
    }

    function getBalanceLimitPerUser() external view returns (uint256) {
        return GlobalAppStorage.layout().balanceLimitPerUser;
    }

    function verifyMuonTSSAndGateway(
        bytes32 hash,
        SchnorrSign memory sign,
        bytes memory gatewaySignature
    ) external view {
        LibMuon.verifyTSSAndGateway(hash, sign, gatewaySignature);
    }

    function getNextQuoteId() external view returns (uint256){
        return QuoteStorage.layout().lastId;
    }

    function getQuotesWithBitmap(
        Bitmap calldata bitmap,
        uint256 gasNeededForReturn
    ) external view returns (Quote[] memory quotes) {
        QuoteStorage.Layout storage qL = QuoteStorage.layout();

        quotes = new Quote[](bitmap.size);
        uint256 quoteIndex = 0;

        for (uint256 i = 0; i < bitmap.elements.length; ++i) {
            uint256 bits = bitmap.elements[i].bitmap;
            uint256 offset = bitmap.elements[i].offset;
            while (bits > 0 && gasleft() > gasNeededForReturn) {
                if ((bits & 1) > 0) {
                    quotes[quoteIndex] = qL.quotes[offset];
                    ++quoteIndex;
                }
                ++offset;
                bits >>= 1;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeStablecoin is ERC20 {
    constructor() ERC20("FakeStablecoin", "FUSD") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// import "../interfaces/ISymmio.sol";

interface ISymmio {
    function withdraw(uint256 amount) external;

    function getCollateral() external view returns (address);
}

contract FeeCollector is Initializable, PausableUpgradeable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct SymmioFrontendShare {
        address receiver;
        uint256 share; // decimals 6
    }

    // Defining roles for access control
    bytes32 public constant COLLECTOR_ROLE = keccak256("COLLECTOR_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    // State variables
    address public symmioAddress;
    SymmioFrontendShare[] public frontends;
    uint256 public totalShare;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        address symmioAddress_,
        address symmioReceiver,
        uint256 symmioShare
    ) public initializer {
        require(admin != address(0), "FeeCollector: Zero address");
        require(symmioAddress != address(0), "FeeCollector: Zero address");
        require(symmioReceiver != address(0), "FeeCollector: Zero address");

        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        symmioAddress = symmioAddress_;
        SymmioFrontendShare memory fe = SymmioFrontendShare(symmioReceiver, symmioShare);
        frontends.push(fe);
        totalShare = symmioShare;
    }

    function setSymmioAddress(address symmioAddress_) external onlyRole(SETTER_ROLE) {
        require(symmioAddress_ != address(0), "FeeCollector: Zero address");
        symmioAddress = symmioAddress_;
    }

    function addFrontend(address receiver, uint256 share) external onlyRole(SETTER_ROLE) {
        require(receiver != address(0), "FeeCollector: Zero address");
        SymmioFrontendShare memory fe = SymmioFrontendShare(receiver, share);
        frontends.push(fe);
        totalShare += share;
    }

    function removeFrontend(uint256 id, address receiver) external onlyRole(SETTER_ROLE) {
        require(frontends[id].receiver == receiver, "FeeCollector: Invalid address");
        totalShare -= frontends[id].share;
        frontends[id] = frontends[frontends.length - 1];
        frontends.pop();
    }

    function claimFee(uint256 amount) external onlyRole(COLLECTOR_ROLE) whenNotPaused {
        address collateral = ISymmio(symmioAddress).getCollateral();
        ISymmio(symmioAddress).withdraw(amount);
        for (uint256 i = 0; i < frontends.length; i++) {
            IERC20Upgradeable(collateral).safeTransfer(
                frontends[i].receiver,
                (frontends[i].share * amount) / totalShare
            );
        }
    }

    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() external onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface IMultiAccount {
    struct Account {
        address accountAddress;
        string name;
    }

    event SetAccountImplementation(bytes oldAddress, bytes newAddress);
    event SetSymmioAddress(address oldAddress, address newAddress);
    event DeployContract(address sender, address contractAddress);
    event AddAccount(address user, address account, string name);
    event EditAccountName(address user, address account, string newName);
    event DepositForAccount(address user, address account, uint256 amount);
    event AllocateForAccount(address user, address account, uint256 amount);
    event WithdrawFromAccount(address user, address account, uint256 amount);
    event Call(
        address user,
        address account,
        bytes _callData,
        bool _success,
        bytes _resultData
    );
    event DelegateAccess(address account, address target, bytes4 selector, bool state);
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface ISymmio {
    function depositFor(address account, uint256 amount) external;

    function withdrawTo(address account, uint256 amount) external;

    function getCollateral() external view returns (address);
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface ISymmioPartyA {
    function _approve(address token, uint256 amount) external;

    function _call(bytes calldata _callData) external returns (bool _success, bytes memory _resultData);

    function withdrawERC20(address token, uint256 amount) external;
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

library DevLogging {
    event LogUint(uint256 value);
    event LogInt(int256 value);
    event LogAddress(address value);
    event LogString(string value);
}

interface DevLoggingInterface {
    event LogUint(uint256 value);
    event LogInt(int256 value);
    event LogAddress(address value);
    event LogString(string value);
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/GlobalAppStorage.sol";

library LibAccessibility {
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant MUON_SETTER_ROLE = keccak256("MUON_SETTER_ROLE");
    bytes32 public constant SYMBOL_MANAGER_ROLE = keccak256("SYMBOL_MANAGER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant PARTY_B_MANAGER_ROLE = keccak256("PARTY_B_MANAGER_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    bytes32 public constant SUSPENDER_ROLE = keccak256("SUSPENDER_ROLE");
    bytes32 public constant DISPUTE_ROLE = keccak256("DISPUTE_ROLE");

    function hasRole(address user, bytes32 role) internal view returns (bool) {
        GlobalAppStorage.Layout storage layout = GlobalAppStorage.layout();
        return layout.hasRole[user][role];
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./LibLockedValues.sol";
import "../storages/AccountStorage.sol";

library LibAccount {
    using LockedValuesOps for LockedValues;

    function partyATotalLockedBalances(address partyA) internal view returns (uint256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        return
            accountLayout.pendingLockedBalances[partyA].totalForPartyA() +
            accountLayout.lockedBalances[partyA].totalForPartyA();
    }

    function partyBTotalLockedBalances(
        address partyB,
        address partyA
    ) internal view returns (uint256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        return
            accountLayout.partyBPendingLockedBalances[partyB][partyA].totalForPartyB() +
            accountLayout.partyBLockedBalances[partyB][partyA].totalForPartyB();
    }

    function partyAAvailableForQuote(int256 upnl, address partyA) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.allocatedBalances[partyA]) +
                upnl -
                int256(
                    (accountLayout.lockedBalances[partyA].totalForPartyA() +
                        accountLayout.pendingLockedBalances[partyA].totalForPartyA())
                );
        } else {
            int256 mm = int256(accountLayout.lockedBalances[partyA].partyAmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.allocatedBalances[partyA]) -
                int256(
                    (accountLayout.lockedBalances[partyA].cva +
                        accountLayout.lockedBalances[partyA].lf +
                        accountLayout.pendingLockedBalances[partyA].totalForPartyA())
                ) -
                considering_mm;
        }
        return available;
    }

    function partyAAvailableBalance(int256 upnl, address partyA) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.allocatedBalances[partyA]) +
                upnl -
                int256(accountLayout.lockedBalances[partyA].totalForPartyA());
        } else {
            int256 mm = int256(accountLayout.lockedBalances[partyA].partyAmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.allocatedBalances[partyA]) -
                int256(
                    accountLayout.lockedBalances[partyA].cva +
                        accountLayout.lockedBalances[partyA].lf
                ) -
                considering_mm;
        }
        return available;
    }

    function partyAAvailableBalanceForLiquidation(
        int256 upnl,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 freeBalance = int256(accountLayout.allocatedBalances[partyA]) -
            int256(accountLayout.lockedBalances[partyA].cva + accountLayout.lockedBalances[partyA].lf);
        return freeBalance + upnl;
    }

    function partyBAvailableForQuote(
        int256 upnl,
        address partyB,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) +
                upnl -
                int256(
                    (accountLayout.partyBLockedBalances[partyB][partyA].totalForPartyB() +
                        accountLayout.partyBPendingLockedBalances[partyB][partyA].totalForPartyB())
                );
        } else {
            int256 mm = int256(accountLayout.partyBLockedBalances[partyB][partyA].partyBmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) -
                int256(
                    (accountLayout.partyBLockedBalances[partyB][partyA].cva +
                        accountLayout.partyBLockedBalances[partyB][partyA].lf +
                        accountLayout.partyBPendingLockedBalances[partyB][partyA].totalForPartyB())
                ) -
                considering_mm;
        }
        return available;
    }

    function partyBAvailableBalance(
        int256 upnl,
        address partyB,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 available;
        if (upnl >= 0) {
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) +
                upnl -
                int256(accountLayout.partyBLockedBalances[partyB][partyA].totalForPartyB());
        } else {
            int256 mm = int256(accountLayout.partyBLockedBalances[partyB][partyA].partyBmm);
            int256 considering_mm = -upnl > mm ? -upnl : mm;
            available =
                int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) -
                int256(
                    accountLayout.partyBLockedBalances[partyB][partyA].cva +
                        accountLayout.partyBLockedBalances[partyB][partyA].lf
                ) -
                considering_mm;
        }
        return available;
    }

    function partyBAvailableBalanceForLiquidation(
        int256 upnl,
        address partyB,
        address partyA
    ) internal view returns (int256) {
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        int256 a = int256(accountLayout.partyBAllocatedBalances[partyB][partyA]) -
            int256(accountLayout.partyBLockedBalances[partyB][partyA].cva +
                accountLayout.partyBLockedBalances[partyB][partyA].lf);
        return a + upnl;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

library LibDiamond {
    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsOwnerOrContract() internal view {
        require(
            msg.sender == diamondStorage().contractOwner || msg.sender == address(this),
            "LibDiamond: Must be contract or owner"
        );
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorCount
            );
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddress != address(this),
                "LibDiamondCut: Can't replace immutable function"
            );
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            require(
                oldFacetAddress != address(0),
                "LibDiamondCut: Can't replace function that doesn't exist"
            );
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds
                .facetAddressAndSelectorPosition[selector];
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(0),
                "LibDiamondCut: Can't remove function that doesn't exist"
            );
            // can't remove immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(this),
                "LibDiamondCut: Can't remove immutable function."
            );
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds
                    .facetAddressAndSelectorPosition[lastSelector]
                    .selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../storages/QuoteStorage.sol";

struct LockedValues {
    uint256 cva;
    uint256 lf;
    uint256 partyAmm;
    uint256 partyBmm;
}

library LockedValuesOps {
    using SafeMath for uint256;

    function add(LockedValues storage self, LockedValues memory a)
        internal
        returns (LockedValues storage)
    {
        self.cva = self.cva.add(a.cva);
        self.partyAmm = self.partyAmm.add(a.partyAmm);
        self.partyBmm = self.partyBmm.add(a.partyBmm);
        self.lf = self.lf.add(a.lf);
        return self;
    }

    function addQuote(LockedValues storage self, Quote storage quote)
        internal
        returns (LockedValues storage)
    {
        return add(self, quote.lockedValues);
    }

    function sub(LockedValues storage self, LockedValues memory a)
        internal
        returns (LockedValues storage)
    {
        self.cva = self.cva.sub(a.cva);
        self.partyAmm = self.partyAmm.sub(a.partyAmm);
        self.partyBmm = self.partyBmm.sub(a.partyBmm);
        self.lf = self.lf.sub(a.lf);
        return self;
    }

    function subQuote(LockedValues storage self, Quote storage quote)
        internal
        returns (LockedValues storage)
    {
        return sub(self, quote.lockedValues);
    }

    function makeZero(LockedValues storage self) internal returns (LockedValues storage) {
        self.cva = 0;
        self.partyAmm = 0;
        self.partyBmm = 0;
        self.lf = 0;
        return self;
    }

    function totalForPartyA(LockedValues memory self) internal pure returns (uint256) {
        return self.cva + self.partyAmm + self.lf;
    }

    function totalForPartyB(LockedValues memory self) internal pure returns (uint256) {
        return self.cva + self.partyBmm + self.lf;
    }

    function mul(LockedValues storage self, uint256 a) internal returns (LockedValues storage) {
        self.cva = self.cva.mul(a);
        self.partyAmm = self.partyAmm.mul(a);
        self.partyBmm = self.partyBmm.mul(a);
        self.lf = self.lf.mul(a);
        return self;
    }

    function mulMem(LockedValues memory self, uint256 a)
        internal
        pure
        returns (LockedValues memory)
    {
        LockedValues memory lockedValues = LockedValues(
            self.cva.mul(a),
            self.lf.mul(a),
            self.partyAmm.mul(a),
            self.partyBmm.mul(a)
        );
        return lockedValues;
    }

    function div(LockedValues storage self, uint256 a) internal returns (LockedValues storage) {
        self.cva = self.cva.div(a);
        self.partyAmm = self.partyAmm.div(a);
        self.partyBmm = self.partyBmm.div(a);
        self.lf = self.lf.div(a);
        return self;
    }

    function divMem(LockedValues memory self, uint256 a)
        internal
        pure
        returns (LockedValues memory)
    {
        LockedValues memory lockedValues = LockedValues(
            self.cva.div(a),
            self.lf.div(a),
            self.partyAmm.div(a),
            self.partyBmm.div(a)
        );
        return lockedValues;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../libraries/LibMuonV04ClientBase.sol";
import "../storages/MuonStorage.sol";
import "../storages/AccountStorage.sol";

library LibMuon {
    using ECDSA for bytes32;

    function getChainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    // CONTEXT for commented out lines
    // We're utilizing muon signatures for asset pricing and user uPNLs calculations. 
    // Even though these signatures are necessary for full testing of the system, particularly when invoking various methods.
    // The process of creating automated functional signature for tests has proven to be either impractical or excessively time-consuming. therefore, we've established commenting out the necessary code as a workaround specifically for testing.
    // Essentially, during testing, we temporarily disable the code sections responsible for validating these signatures. The sections I'm referring to are located within the LibMuon file. Specifically, the body of the 'verifyTSSAndGateway' method is a prime candidate for temporary disablement. In addition, several 'require' statements within other functions of this file, which examine the signatures' expiration status, also need to be temporarily disabled.
    // However, it is crucial to note that these lines should not be disabled in the production deployed version. 
    // We emphasize this because they are only disabled for testing purposes.

    function verifyTSSAndGateway(
        bytes32 hash,
        SchnorrSign memory sign,
        bytes memory gatewaySignature
    ) internal view {
        // == SignatureCheck( ==
        bool verified = LibMuonV04ClientBase.muonVerify(
            uint256(hash),
            sign,
            MuonStorage.layout().muonPublicKey
        );
        require(verified, "LibMuon: TSS not verified");

        hash = hash.toEthSignedMessageHash();
        address gatewaySignatureSigner = hash.recover(gatewaySignature);

        require(
            gatewaySignatureSigner == MuonStorage.layout().validGateway,
            "LibMuon: Gateway is not valid"
        );
        // == ) ==
    }

    function verifyLiquidationSig(LiquidationSig memory liquidationSig, address partyA) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        require(liquidationSig.prices.length == liquidationSig.symbolIds.length, "LibMuon: Invalid length");
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                liquidationSig.reqId,
                liquidationSig.liquidationId,
                address(this),
                "verifyLiquidationSig",
                partyA,
                AccountStorage.layout().partyANonces[partyA],
                liquidationSig.upnl,
                liquidationSig.totalUnrealizedLoss,
                liquidationSig.symbolIds,
                liquidationSig.prices,
                liquidationSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, liquidationSig.sigs, liquidationSig.gatewaySignature);
    }

    function verifyQuotePrices(QuotePriceSig memory priceSig) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        require(priceSig.prices.length == priceSig.quoteIds.length, "LibMuon: Invalid length");
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                priceSig.reqId,
                address(this),
                priceSig.quoteIds,
                priceSig.prices,
                priceSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, priceSig.sigs, priceSig.gatewaySignature);
    }

    function verifyPartyAUpnl(SingleUpnlSig memory upnlSig, address partyA) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyA,
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnl,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPartyAUpnlAndPrice(
        SingleUpnlAndPriceSig memory upnlSig,
        address partyA,
        uint256 symbolId
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyA,
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnl,
                symbolId,
                upnlSig.price,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPartyBUpnl(
        SingleUpnlSig memory upnlSig,
        address partyB,
        address partyA
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyB,
                partyA,
                AccountStorage.layout().partyBNonces[partyB][partyA],
                upnlSig.upnl,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPairUpnlAndPrice(
        PairUpnlAndPriceSig memory upnlSig,
        address partyB,
        address partyA,
        uint256 symbolId
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyB,
                partyA,
                AccountStorage.layout().partyBNonces[partyB][partyA],
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnlPartyB,
                upnlSig.upnlPartyA,
                symbolId,
                upnlSig.price,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }

    function verifyPairUpnl(
        PairUpnlSig memory upnlSig,
        address partyB,
        address partyA
    ) internal view {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        // == SignatureCheck( ==
        require(
            block.timestamp <= upnlSig.timestamp + muonLayout.upnlValidTime,
            "LibMuon: Expired signature"
        );
        // == ) ==
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonLayout.muonAppId,
                upnlSig.reqId,
                address(this),
                partyB,
                partyA,
                AccountStorage.layout().partyBNonces[partyB][partyA],
                AccountStorage.layout().partyANonces[partyA],
                upnlSig.upnlPartyB,
                upnlSig.upnlPartyA,
                upnlSig.timestamp,
                getChainId()
            )
        );
        verifyTSSAndGateway(hash, upnlSig.sigs, upnlSig.gatewaySignature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "../storages/MuonStorage.sol";

library LibMuonV04ClientBase {
    // See https://en.bitcoin.it/wiki/Secp256k1 for this constant.
    uint256 constant public Q = // Group order of secp256k1
    // solium-disable-next-line indentation
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    // solium-disable-next-line zeppelin/no-arithmetic-operations
    uint256 constant public HALF_Q = (Q >> 1) + 1;

    /** **************************************************************************
@notice verifySignature returns true iff passed a valid Schnorr signature.

      @dev See https://en.wikipedia.org/wiki/Schnorr_signature for reference.

      @dev In what follows, let d be your secret key, PK be your public key,
      PKx be the x ordinate of your public key, and PKyp be the parity bit for
      the y ordinate (i.e., 0 if PKy is even, 1 if odd.)
      **************************************************************************
      @dev TO CREATE A VALID SIGNATURE FOR THIS METHOD

      @dev First PKx must be less than HALF_Q. Then follow these instructions
           (see evm/test/schnorr_test.js, for an example of carrying them out):
      @dev 1. Hash the target message to a uint256, called msgHash here, using
              keccak256

      @dev 2. Pick k uniformly and cryptographically securely randomly from
              {0,...,Q-1}. It is critical that k remains confidential, as your
              private key can be reconstructed from k and the signature.

      @dev 3. Compute k*g in the secp256k1 group, where g is the group
              generator. (This is the same as computing the public key from the
              secret key k. But it's OK if k*g's x ordinate is greater than
              HALF_Q.)

      @dev 4. Compute the ethereum address for k*g. This is the lower 160 bits
              of the keccak hash of the concatenated affine coordinates of k*g,
              as 32-byte big-endians. (For instance, you could pass k to
              ethereumjs-utils's privateToAddress to compute this, though that
              should be strictly a development convenience, not for handling
              live secrets, unless you've locked your javascript environment
              down very carefully.) Call this address
              nonceTimesGeneratorAddress.

      @dev 5. Compute e=uint256(keccak256(PKx as a 32-byte big-endian
                                        ‖ PKyp as a single byte
                                        ‖ msgHash
                                        ‖ nonceTimesGeneratorAddress))
              This value e is called "msgChallenge" in verifySignature's source
              code below. Here "‖" means concatenation of the listed byte
              arrays.

      @dev 6. Let x be your secret key. Compute s = (k - d * e) % Q. Add Q to
              it, if it's negative. This is your signature. (d is your secret
              key.)
      **************************************************************************
      @dev TO VERIFY A SIGNATURE

      @dev Given a signature (s, e) of msgHash, constructed as above, compute
      S=e*PK+s*generator in the secp256k1 group law, and then the ethereum
      address of S, as described in step 4. Call that
      nonceTimesGeneratorAddress. Then call the verifySignature method as:

      @dev    verifySignature(PKx, PKyp, s, msgHash,
                              nonceTimesGeneratorAddress)
      **************************************************************************
      @dev This signging scheme deviates slightly from the classical Schnorr
      signature, in that the address of k*g is used in place of k*g itself,
      both when calculating e and when verifying sum S as described in the
      verification paragraph above. This reduces the difficulty of
      brute-forcing a signature by trying random secp256k1 points in place of
      k*g in the signature verification process from 256 bits to 160 bits.
      However, the difficulty of cracking the public key using "baby-step,
      giant-step" is only 128 bits, so this weakening constitutes no compromise
      in the security of the signatures or the key.

      @dev The constraint signingPubKeyX < HALF_Q comes from Eq. (281), p. 24
      of Yellow Paper version 78d7b9a. ecrecover only accepts "s" inputs less
      than HALF_Q, to protect against a signature- malleability vulnerability in
      ECDSA. Schnorr does not have this vulnerability, but we must account for
      ecrecover's defense anyway. And since we are abusing ecrecover by putting
      signingPubKeyX in ecrecover's "s" argument the constraint applies to
      signingPubKeyX, even though it represents a value in the base field, and
      has no natural relationship to the order of the curve's cyclic group.
      **************************************************************************
      @param signingPubKeyX is the x ordinate of the public key. This must be
             less than HALF_Q.
      @param pubKeyYParity is 0 if the y ordinate of the public key is even, 1
             if it's odd.
      @param signature is the actual signature, described as s in the above
             instructions.
      @param msgHash is a 256-bit hash of the message being signed.
      @param nonceTimesGeneratorAddress is the ethereum address of k*g in the
             above instructions
      **************************************************************************
      @return True if passed a valid signature, false otherwise. */
    function verifySignature(
        uint256 signingPubKeyX,
        uint8 pubKeyYParity,
        uint256 signature,
        uint256 msgHash,
        address nonceTimesGeneratorAddress) public pure returns (bool) {
        require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
        // Avoid signature malleability from multiple representations for ℤ/Qℤ elts
        require(signature < Q, "signature must be reduced modulo Q");

        // Forbid trivial inputs, to avoid ecrecover edge cases. The main thing to
        // avoid is something which causes ecrecover to return 0x0: then trivial
        // signatures could be constructed with the nonceTimesGeneratorAddress input
        // set to 0x0.
        //
        // solium-disable-next-line indentation
        require(nonceTimesGeneratorAddress != address(0) && signingPubKeyX > 0 &&
        signature > 0 && msgHash > 0, "no zero inputs allowed");

        // solium-disable-next-line indentation
        uint256 msgChallenge = // "e"
        // solium-disable-next-line indentation
                            uint256(keccak256(abi.encodePacked(signingPubKeyX, pubKeyYParity,
                msgHash, nonceTimesGeneratorAddress))
            );

        // Verify msgChallenge * signingPubKey + signature * generator ==
        //        nonce * generator
        //
        // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
        // The point corresponding to the address returned by
        // ecrecover(-s*r,v,r,e*r) is (r⁻¹ mod Q)*(e*r*R-(-s)*r*g)=e*R+s*g, where R
        // is the (v,r) point. See https://crypto.stackexchange.com/a/18106
        //
        // solium-disable-next-line indentation
        address recoveredAddress = ecrecover(
        // solium-disable-next-line zeppelin/no-arithmetic-operations
            bytes32(Q - mulmod(signingPubKeyX, signature, Q)),
            // https://ethereum.github.io/yellowpaper/paper.pdf p. 24, "The
            // value 27 represents an even y value and 28 represents an odd
            // y value."
            (pubKeyYParity == 0) ? 27 : 28,
            bytes32(signingPubKeyX),
            bytes32(mulmod(msgChallenge, signingPubKeyX, Q)));
        return nonceTimesGeneratorAddress == recoveredAddress;
    }

    function validatePubKey(uint256 signingPubKeyX) public pure {
        require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
    }

    function muonVerify(
        uint256 hash,
        SchnorrSign memory signature,
        PublicKey memory pubKey
    ) internal pure returns (bool) {
        if (!verifySignature(pubKey.x, pubKey.parity,
            signature.signature,
            hash, signature.nonce)) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/QuoteStorage.sol";
import "../storages/MAStorage.sol";
import "../storages/QuoteStorage.sol";
import "./LibAccount.sol";
import "./LibLockedValues.sol";

library LibPartyB {
    using LockedValuesOps for LockedValues;

    function checkPartyBValidationToLockQuote(uint256 quoteId, int256 upnl) internal view {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        MAStorage.Layout storage maLayout = MAStorage.layout();

        Quote storage quote = quoteLayout.quotes[quoteId];
        require(quote.quoteStatus == QuoteStatus.PENDING, "PartyBFacet: Invalid state");
        require(block.timestamp <= quote.deadline, "PartyBFacet: Quote is expired");
        require(quoteId <= quoteLayout.lastId, "PartyBFacet: Invalid quoteId");
        int256 availableBalance = LibAccount.partyBAvailableForQuote(
            upnl,
            msg.sender,
            quote.partyA
        );
        require(availableBalance >= 0, "PartyBFacet: Available balance is lower than zero");
        require(
            uint256(availableBalance) >= quote.lockedValues.totalForPartyB(),
            "PartyBFacet: insufficient available balance"
        );
        require(
            !maLayout.partyBLiquidationStatus[msg.sender][quote.partyA],
            "PartyBFacet: PartyB isn't solvent"
        );
        bool isValidPartyB;
        if (quote.partyBsWhiteList.length == 0) {
            require(msg.sender != quote.partyA, "PartyBFacet: PartyA can't be partyB too");
            isValidPartyB = true;
        } else {
            for (uint8 index = 0; index < quote.partyBsWhiteList.length; index++) {
                if (msg.sender == quote.partyBsWhiteList[index]) {
                    isValidPartyB = true;
                    break;
                }
            }
        }
        require(isValidPartyB, "PartyBFacet: Sender isn't whitelisted");
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./LibLockedValues.sol";
import "../storages/QuoteStorage.sol";
import "../storages/AccountStorage.sol";
import "../storages/GlobalAppStorage.sol";
import "../storages/SymbolStorage.sol";
import "../storages/MAStorage.sol";

library LibQuote {
    using LockedValuesOps for LockedValues;

    function quoteOpenAmount(Quote storage quote) internal view returns (uint256) {
        return quote.quantity - quote.closedAmount;
    }

    function getIndexOfItem(
        uint256[] storage array_,
        uint256 item
    ) internal view returns (uint256) {
        for (uint256 index = 0; index < array_.length; index++) {
            if (array_[index] == item) return index;
        }
        return type(uint256).max;
    }

    function removeFromArray(uint256[] storage array_, uint256 item) internal {
        uint256 index = getIndexOfItem(array_, item);
        require(index != type(uint256).max, "LibQuote: Item not Found");
        array_[index] = array_[array_.length - 1];
        array_.pop();
    }

    function removeFromPartyAPendingQuotes(Quote storage quote) internal {
        removeFromArray(QuoteStorage.layout().partyAPendingQuotes[quote.partyA], quote.id);
    }

    function removeFromPartyBPendingQuotes(Quote storage quote) internal {
        removeFromArray(
            QuoteStorage.layout().partyBPendingQuotes[quote.partyB][quote.partyA],
            quote.id
        );
    }

    function removeFromPendingQuotes(Quote storage quote) internal {
        removeFromPartyAPendingQuotes(quote);
        removeFromPartyBPendingQuotes(quote);
    }

    function addToOpenPositions(uint256 quoteId) internal {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        Quote storage quote = quoteLayout.quotes[quoteId];

        quoteLayout.partyAOpenPositions[quote.partyA].push(quote.id);
        quoteLayout.partyBOpenPositions[quote.partyB][quote.partyA].push(quote.id);

        quoteLayout.partyAPositionsIndex[quote.id] = quoteLayout.partyAPositionsCount[quote.partyA];
        quoteLayout.partyBPositionsIndex[quote.id] = quoteLayout.partyBPositionsCount[quote.partyB][
                        quote.partyA
            ];

        quoteLayout.partyAPositionsCount[quote.partyA] += 1;
        quoteLayout.partyBPositionsCount[quote.partyB][quote.partyA] += 1;
    }

    function removeFromOpenPositions(uint256 quoteId) internal {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        Quote storage quote = quoteLayout.quotes[quoteId];
        uint256 indexOfPartyAPosition = quoteLayout.partyAPositionsIndex[quote.id];
        uint256 indexOfPartyBPosition = quoteLayout.partyBPositionsIndex[quote.id];
        uint256 lastOpenPositionIndex = quoteLayout.partyAPositionsCount[quote.partyA] - 1;
        quoteLayout.partyAOpenPositions[quote.partyA][indexOfPartyAPosition] = quoteLayout
            .partyAOpenPositions[quote.partyA][lastOpenPositionIndex];
        quoteLayout.partyAPositionsIndex[
        quoteLayout.partyAOpenPositions[quote.partyA][lastOpenPositionIndex]
        ] = indexOfPartyAPosition;
        quoteLayout.partyAOpenPositions[quote.partyA].pop();

        lastOpenPositionIndex = quoteLayout.partyBPositionsCount[quote.partyB][quote.partyA] - 1;
        quoteLayout.partyBOpenPositions[quote.partyB][quote.partyA][
        indexOfPartyBPosition
        ] = quoteLayout.partyBOpenPositions[quote.partyB][quote.partyA][lastOpenPositionIndex];
        quoteLayout.partyBPositionsIndex[
        quoteLayout.partyBOpenPositions[quote.partyB][quote.partyA][lastOpenPositionIndex]
        ] = indexOfPartyBPosition;
        quoteLayout.partyBOpenPositions[quote.partyB][quote.partyA].pop();

        quoteLayout.partyAPositionsIndex[quote.id] = 0;
        quoteLayout.partyBPositionsIndex[quote.id] = 0;
    }

    function getValueOfQuoteForPartyA(
        uint256 currentPrice,
        uint256 filledAmount,
        Quote storage quote
    ) internal view returns (bool hasMadeProfit, uint256 pnl) {
        if (currentPrice > quote.openedPrice) {
            if (quote.positionType == PositionType.LONG) {
                hasMadeProfit = true;
            } else {
                hasMadeProfit = false;
            }
            pnl = ((currentPrice - quote.openedPrice) * filledAmount) / 1e18;
        } else {
            if (quote.positionType == PositionType.LONG) {
                hasMadeProfit = false;
            } else {
                hasMadeProfit = true;
            }
            pnl = ((quote.openedPrice - currentPrice) * filledAmount) / 1e18;
        }
    }

    function getTradingFee(uint256 quoteId) internal view returns (uint256 fee) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        Quote storage quote = quoteLayout.quotes[quoteId];
        if (quote.orderType == OrderType.LIMIT) {
            fee =
                (LibQuote.quoteOpenAmount(quote) * quote.requestedOpenPrice * quote.tradingFee) /
                1e36;
        } else {
            fee = (LibQuote.quoteOpenAmount(quote) * quote.marketPrice * quote.tradingFee) / 1e36;
        }
    }

    function closeQuote(Quote storage quote, uint256 filledAmount, uint256 closedPrice) internal {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();

        require(quote.lockedValues.cva == 0 || quote.lockedValues.cva * filledAmount / LibQuote.quoteOpenAmount(quote) > 0, "LibQuote: Low filled amount");
        require(quote.lockedValues.partyAmm == 0 || quote.lockedValues.partyAmm * filledAmount / LibQuote.quoteOpenAmount(quote) > 0, "LibQuote: Low filled amount");
        require(quote.lockedValues.partyBmm == 0 || quote.lockedValues.partyBmm * filledAmount / LibQuote.quoteOpenAmount(quote) > 0, "LibQuote: Low filled amount");
        require(quote.lockedValues.lf * filledAmount / LibQuote.quoteOpenAmount(quote) > 0, "LibQuote: Low filled amount");
        LockedValues memory lockedValues = LockedValues(
            quote.lockedValues.cva -
            ((quote.lockedValues.cva * filledAmount) / (LibQuote.quoteOpenAmount(quote))),
            quote.lockedValues.lf -
            ((quote.lockedValues.lf * filledAmount) / (LibQuote.quoteOpenAmount(quote))),
            quote.lockedValues.partyAmm -
            ((quote.lockedValues.partyAmm * filledAmount) / (LibQuote.quoteOpenAmount(quote))),
            quote.lockedValues.partyBmm -
            ((quote.lockedValues.partyBmm * filledAmount) / (LibQuote.quoteOpenAmount(quote)))
        );
        accountLayout.lockedBalances[quote.partyA].subQuote(quote).add(lockedValues);
        accountLayout.partyBLockedBalances[quote.partyB][quote.partyA].subQuote(quote).add(
            lockedValues
        );
        quote.lockedValues = lockedValues;

        if (LibQuote.quoteOpenAmount(quote) == quote.quantityToClose) {
            require(
                quote.lockedValues.totalForPartyA() == 0 ||
                    quote.lockedValues.totalForPartyA() >=
                    symbolLayout.symbols[quote.symbolId].minAcceptableQuoteValue,
                "LibQuote: Remaining quote value is low"
            );
        }

        (bool hasMadeProfit, uint256 pnl) = LibQuote.getValueOfQuoteForPartyA(
            closedPrice,
            filledAmount,
            quote
        );
        if (hasMadeProfit) {
            accountLayout.allocatedBalances[quote.partyA] += pnl;
            accountLayout.partyBAllocatedBalances[quote.partyB][quote.partyA] -= pnl;
        } else {
            accountLayout.allocatedBalances[quote.partyA] -= pnl;
            accountLayout.partyBAllocatedBalances[quote.partyB][quote.partyA] += pnl;
        }

        quote.avgClosedPrice =
            (quote.avgClosedPrice * quote.closedAmount + filledAmount * closedPrice) /
            (quote.closedAmount + filledAmount);

        quote.closedAmount += filledAmount;
        quote.quantityToClose -= filledAmount;

        if (quote.closedAmount == quote.quantity) {
            quote.statusModifyTimestamp = block.timestamp;
            quote.quoteStatus = QuoteStatus.CLOSED;
            quote.requestedClosePrice = 0;
            removeFromOpenPositions(quote.id);
            quoteLayout.partyAPositionsCount[quote.partyA] -= 1;
            quoteLayout.partyBPositionsCount[quote.partyB][quote.partyA] -= 1;
        } else if (
            quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING || quote.quantityToClose == 0
        ) {
            quote.quoteStatus = QuoteStatus.OPENED;
            quote.statusModifyTimestamp = block.timestamp;
            quote.requestedClosePrice = 0;
            quote.quantityToClose = 0; // for CANCEL_CLOSE_PENDING status
        }
    }

    function expireQuote(uint256 quoteId) internal returns (QuoteStatus result) {
        QuoteStorage.Layout storage quoteLayout = QuoteStorage.layout();
        AccountStorage.Layout storage accountLayout = AccountStorage.layout();

        Quote storage quote = quoteLayout.quotes[quoteId];
        require(block.timestamp > quote.deadline, "LibQuote: Quote isn't expired");
        require(
            quote.quoteStatus == QuoteStatus.PENDING ||
            quote.quoteStatus == QuoteStatus.CANCEL_PENDING ||
            quote.quoteStatus == QuoteStatus.LOCKED ||
            quote.quoteStatus == QuoteStatus.CLOSE_PENDING ||
            quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING,
            "LibQuote: Invalid state"
        );
        require(
            !MAStorage.layout().liquidationStatus[quote.partyA],
            "LibQuote: PartyA isn't solvent"
        );
        require(
            !MAStorage.layout().partyBLiquidationStatus[quote.partyB][quote.partyA],
            "LibQuote: PartyB isn't solvent"
        );
        if (
            quote.quoteStatus == QuoteStatus.PENDING ||
            quote.quoteStatus == QuoteStatus.LOCKED ||
            quote.quoteStatus == QuoteStatus.CANCEL_PENDING
        ) {
            quote.statusModifyTimestamp = block.timestamp;
            accountLayout.pendingLockedBalances[quote.partyA].subQuote(quote);
            // send trading Fee back to partyA
            accountLayout.allocatedBalances[quote.partyA] += LibQuote.getTradingFee(quote.id);
            removeFromPartyAPendingQuotes(quote);
            if (
                quote.quoteStatus == QuoteStatus.LOCKED ||
                quote.quoteStatus == QuoteStatus.CANCEL_PENDING
            ) {
                accountLayout.partyBPendingLockedBalances[quote.partyB][quote.partyA].subQuote(
                    quote
                );
                removeFromPartyBPendingQuotes(quote);
            }
            quote.quoteStatus = QuoteStatus.EXPIRED;
            result = QuoteStatus.EXPIRED;
        } else if (
            quote.quoteStatus == QuoteStatus.CLOSE_PENDING ||
            quote.quoteStatus == QuoteStatus.CANCEL_CLOSE_PENDING
        ) {
            quote.statusModifyTimestamp = block.timestamp;
            quote.requestedClosePrice = 0;
            quote.quantityToClose = 0;
            quote.quoteStatus = QuoteStatus.OPENED;
            result = QuoteStatus.OPENED;
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/MuonStorage.sol";
import "../storages/QuoteStorage.sol";
import "./LibAccount.sol";
import "./LibQuote.sol";

library LibSolvency {
    using LockedValuesOps for LockedValues;

    function isSolventAfterOpenPosition(
        uint256 quoteId,
        uint256 filledAmount,
        PairUpnlAndPriceSig memory upnlSig
    ) internal view returns (bool) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        int256 partyBAvailableBalance = LibAccount.partyBAvailableBalanceForLiquidation(
            upnlSig.upnlPartyB,
            quote.partyB,
            quote.partyA
        );
        int256 partyAAvailableBalance = LibAccount.partyAAvailableBalanceForLiquidation(
            upnlSig.upnlPartyA,
            quote.partyA
        );

        if (quote.positionType == PositionType.LONG) {
            if (quote.openedPrice >= upnlSig.price) {
                uint256 diff = (filledAmount * (quote.openedPrice - upnlSig.price)) / 1e18;
                require(
                    partyAAvailableBalance - int256(diff) >= 0,
                    "LibSolvency: PartyA will be liquidatable"
                );
                require(
                    partyBAvailableBalance + int256(diff) >= 0,
                    "LibSolvency: PartyB will be liquidatable"
                );
            } else {
                uint256 diff = (filledAmount * (upnlSig.price - quote.openedPrice)) / 1e18;
                require(
                    partyBAvailableBalance - int256(diff) >= 0,
                    "LibSolvency: PartyB will be liquidatable"
                );
                require(
                    partyAAvailableBalance + int256(diff) >= 0,
                    "LibSolvency: PartyA will be liquidatable"
                );
            }
        } else if (quote.positionType == PositionType.SHORT) {
            if (quote.openedPrice >= upnlSig.price) {
                uint256 diff = (filledAmount * (quote.openedPrice - upnlSig.price)) / 1e18;
                require(
                    partyBAvailableBalance - int256(diff) >= 0,
                    "LibSolvency: PartyB will be liquidatable"
                );
                require(
                    partyAAvailableBalance + int256(diff) >= 0,
                    "LibSolvency: PartyA will be liquidatable"
                );
            } else {
                uint256 diff = (filledAmount * (upnlSig.price - quote.openedPrice)) / 1e18;
                require(
                    partyAAvailableBalance - int256(diff) >= 0,
                    "LibSolvency: PartyA will be liquidatable"
                );
                require(
                    partyBAvailableBalance + int256(diff) >= 0,
                    "LibSolvency: PartyB will be liquidatable"
                );
            }
        }

        return true;
    }

    function isSolventAfterClosePosition(
        uint256 quoteId,
        uint256 filledAmount,
        uint256 closedPrice,
        PairUpnlAndPriceSig memory upnlSig
    ) internal view returns (bool) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        uint256 unlockedAmount = (filledAmount * (quote.lockedValues.cva + quote.lockedValues.lf)) /
            LibQuote.quoteOpenAmount(quote);

        int256 partyBAvailableBalance = LibAccount.partyBAvailableBalanceForLiquidation(
            upnlSig.upnlPartyB,
            quote.partyB,
            quote.partyA
        ) + int256(unlockedAmount);

        int256 partyAAvailableBalance = LibAccount.partyAAvailableBalanceForLiquidation(
            upnlSig.upnlPartyA,
            quote.partyA
        ) + int256(unlockedAmount);

        if (quote.positionType == PositionType.LONG) {
            if (closedPrice >= upnlSig.price) {
                uint256 diff = (filledAmount * (closedPrice - upnlSig.price)) / 1e18;
                partyBAvailableBalance -= int256(diff);
                partyAAvailableBalance += int256(diff);
            } else {
                uint256 diff = (filledAmount * (upnlSig.price - closedPrice)) / 1e18;
                partyBAvailableBalance += int256(diff);
                partyAAvailableBalance -= int256(diff);
            }
        } else if (quote.positionType == PositionType.SHORT) {
            if (closedPrice <= upnlSig.price) {
                uint256 diff = (filledAmount * (upnlSig.price - closedPrice)) / 1e18;
                partyBAvailableBalance -= int256(diff);
                partyAAvailableBalance += int256(diff);
            } else {
                uint256 diff = (filledAmount * (closedPrice - upnlSig.price)) / 1e18;
                partyBAvailableBalance += int256(diff);
                partyAAvailableBalance -= int256(diff);
            }
        }
        require(
            partyBAvailableBalance >= 0 && partyAAvailableBalance >= 0,
            "LibSolvency: Available balance is lower than zero"
        );
        return true;
    }

    function isSolventAfterRequestToClosePosition(
        uint256 quoteId,
        uint256 closePrice,
        uint256 quantityToClose,
        SingleUpnlAndPriceSig memory upnlSig
    ) internal view returns (bool) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        uint256 unlockedAmount = (quantityToClose *
            (quote.lockedValues.cva + quote.lockedValues.lf)) / LibQuote.quoteOpenAmount(quote);

        int256 availableBalance = LibAccount.partyAAvailableBalanceForLiquidation(
            upnlSig.upnl,
            msg.sender
        ) + int256(unlockedAmount);

        require(availableBalance >= 0, "LibSolvency: Available balance is lower than zero");
        if (quote.positionType == PositionType.LONG && closePrice <= upnlSig.price) {
            require(
                uint256(availableBalance) >=
                    ((quantityToClose * (upnlSig.price - closePrice)) / 1e18),
                "LibSolvency: partyA will be liquidatable"
            );
        } else if (quote.positionType == PositionType.SHORT && closePrice >= upnlSig.price) {
            require(
                uint256(availableBalance) >=
                    ((quantityToClose * (closePrice - upnlSig.price)) / 1e18),
                "LibSolvency: partyA will be liquidatable"
            );
        }
        return true;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/ISymmio.sol";
import "../interfaces/ISymmioPartyA.sol";
import "../interfaces/IMultiAccount.sol";

contract MultiAccount is IMultiAccount, Initializable, PausableUpgradeable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Defining roles for access control
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    // State variables
    mapping(address => Account[]) public accounts; // User to their accounts mapping
    mapping(address => uint256) public indexOfAccount; // Account to its index mapping
    mapping(address => address) public owners; // Account to its owner mapping

    address public accountsAdmin; // Admin address for the contract
    address public symmioAddress; // Address of the Symmio platform
    uint256 public saltCounter; // Counter for generating unique addresses with create2
    bytes public accountImplementation;

    mapping(address => mapping(address => mapping(bytes4 => bool))) public delegatedAccesses; // account -> target -> selector -> state

    modifier onlyOwner(address account, address sender) {
        require(owners[account] == sender, "MultiAccount: Sender isn't owner of account");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address symmioAddress_, bytes memory accountImplementation_) public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UNPAUSER_ROLE, admin);
        _grantRole(SETTER_ROLE, admin);
        accountsAdmin = admin;
        symmioAddress = symmioAddress_;
        accountImplementation = accountImplementation_;
    }

    function delegateAccess(address account, address target, bytes4 selector, bool state) external onlyOwner(account, msg.sender) {
        require(target != msg.sender && target != account, "MultiAccount: invalid target");
        emit DelegateAccess(account, target, selector, state);
        delegatedAccesses[account][target][selector] = state;
    }

    function delegateAccesses(address account, address target, bytes4[] memory selector, bool state) external onlyOwner(account, msg.sender) {
        require(target != msg.sender && target != account, "MultiAccount: invalid target");
        for (uint256 i = selector.length; i != 0; i--) {
            delegatedAccesses[account][target][selector[i - 1]] = state;
            emit DelegateAccess(account, target, selector[i - 1], state);
        }
    }

    function setAccountImplementation(bytes memory accountImplementation_) external onlyRole(SETTER_ROLE) {
        emit SetAccountImplementation(accountImplementation, accountImplementation_);
        accountImplementation = accountImplementation_;
    }

    function setSymmioAddress(address addr) external onlyRole(SETTER_ROLE) {
        emit SetSymmioAddress(symmioAddress, addr);
        symmioAddress = addr;
    }

    function _deployPartyA() internal returns (address account) {
        bytes32 salt = keccak256(abi.encodePacked("MultiAccount_", saltCounter));
        saltCounter += 1;

        bytes memory bytecode = abi.encodePacked(accountImplementation, abi.encode(accountsAdmin, address(this), symmioAddress));
        account = _deployContract(bytecode, salt);
        return account;
    }

    function _deployContract(bytes memory bytecode, bytes32 salt) internal returns (address contractAddress) {
        assembly {
            contractAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(contractAddress != address(0), "MultiAccount: create2 failed");
        emit DeployContract(msg.sender, contractAddress);
        return contractAddress;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    //////////////////////////////// Account Management ////////////////////////////////////

    function addAccount(string memory name) external whenNotPaused {
        address account = _deployPartyA();
        indexOfAccount[account] = accounts[msg.sender].length;
        accounts[msg.sender].push(Account(account, name));
        owners[account] = msg.sender;
        emit AddAccount(msg.sender, account, name);
    }

    function editAccountName(address accountAddress, string memory name) external whenNotPaused {
        uint256 index = indexOfAccount[accountAddress];
        accounts[msg.sender][index].name = name;
        emit EditAccountName(msg.sender, accountAddress, name);
    }

    function depositForAccount(address account, uint256 amount) external onlyOwner(account, msg.sender) whenNotPaused {
        address collateral = ISymmio(symmioAddress).getCollateral();
        IERC20Upgradeable(collateral).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Upgradeable(collateral).safeApprove(symmioAddress, amount);
        ISymmio(symmioAddress).depositFor(account, amount);
        emit DepositForAccount(msg.sender, account, amount);
    }

    function depositAndAllocateForAccount(address account, uint256 amount) external onlyOwner(account, msg.sender) whenNotPaused {
        address collateral = ISymmio(symmioAddress).getCollateral();
        IERC20Upgradeable(collateral).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Upgradeable(collateral).safeApprove(symmioAddress, amount);
        ISymmio(symmioAddress).depositFor(account, amount);
        uint256 amountWith18Decimals = (amount * 1e18) / (10 ** IERC20Metadata(collateral).decimals());
        bytes memory _callData = abi.encodeWithSignature("allocate(uint256)", amountWith18Decimals);
        innerCall(account, _callData);
        emit DepositForAccount(msg.sender, account, amount);
        emit AllocateForAccount(msg.sender, account, amountWith18Decimals);
    }

    function withdrawFromAccount(address account, uint256 amount) external onlyOwner(account, msg.sender) whenNotPaused {
        bytes memory _callData = abi.encodeWithSignature("withdrawTo(address,uint256)", owners[account], amount);
        emit WithdrawFromAccount(msg.sender, account, amount);
        innerCall(account, _callData);
    }

    function innerCall(address account, bytes memory _callData) internal {
        (bool _success, bytes memory _resultData) = ISymmioPartyA(account)._call(_callData);
        emit Call(msg.sender, account, _callData, _success, _resultData);
        require(_success, "MultiAccount: Error occurred");
    }

    function _call(address account, bytes[] memory _callDatas) public whenNotPaused {
        bool isOwner = owners[account] == msg.sender;
        for (uint8 i; i < _callDatas.length; i++) {
            bytes memory _callData = _callDatas[i];
            if (!isOwner) {
                require(_callData.length >= 4, "MultiAccount: Invalid call data");
                bytes4 functionSelector;
                assembly {
                    functionSelector := mload(add(_callData, 0x20))
                }
                require(delegatedAccesses[account][msg.sender][functionSelector], "MultiAccount: Unauthorized access");
            }
            innerCall(account, _callData);
        }
    }

    //////////////////////////////// VIEWS ////////////////////////////////////

    function getAccountsLength(address user) external view returns (uint256) {
        return accounts[user].length;
    }

    function getAccounts(address user, uint256 start, uint256 size) external view returns (Account[] memory) {
        uint256 len = size > accounts[user].length - start ? accounts[user].length - start : size;
        Account[] memory userAccounts = new Account[](len);
        for (uint256 i = start; i < start + len; i++) {
            userAccounts[i - start] = accounts[user][i];
        }
        return userAccounts;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SymmioPartyA is AccessControl {
    bytes32 public constant MULTIACCOUNT_ROLE = keccak256("MULTIACCOUNT_ROLE");
    address public symmioAddress;

    constructor(address admin, address multiAccountAddress, address symmioAddress_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MULTIACCOUNT_ROLE, multiAccountAddress);
        symmioAddress = symmioAddress_;
    }

    event SetSymmioAddress(address oldV3ContractAddress, address newV3ContractAddress);

    function setSymmioAddress(address symmioAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit SetSymmioAddress(symmioAddress, symmioAddress_);
        symmioAddress = symmioAddress_;
    }

    function _call(bytes memory _callData) external onlyRole(MULTIACCOUNT_ROLE) returns (bool _success, bytes memory _resultData) {
        return symmioAddress.call{ value: 0 }(_callData);
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

contract SymmioPartyB is Initializable, PausableUpgradeable, AccessControlEnumerableUpgradeable {
    bytes32 public constant TRUSTED_ROLE = keccak256("TRUSTED_ROLE");
    address public symmioAddress;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    mapping(bytes4 => bool) public restrictedSelectors;
    mapping(address => bool) public multicastWhitelist;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address symmioAddress_) public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(TRUSTED_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        symmioAddress = symmioAddress_;
    }

    event SetSymmioAddress(address oldSymmioAddress, address newSymmioAddress);

    event SetRestrictedSelector(bytes4 selector, bool state);

    event SetMulticastWhitelist(address addr, bool state);

    function setSymmioAddress(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit SetSymmioAddress(symmioAddress, addr);
        symmioAddress = addr;
    }

    function setRestrictedSelector(bytes4 selector, bool state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        restrictedSelectors[selector] = state;
        emit SetRestrictedSelector(selector, state);
    }

    function setMulticastWhitelist(address addr, bool state) external onlyRole(MANAGER_ROLE) {
        require(addr != address(this), "SymmioPartyB: Invalid address");
        multicastWhitelist[addr] = state;
        emit SetMulticastWhitelist(addr, state);
    }

    function _approve(address token, uint256 amount) external onlyRole(TRUSTED_ROLE) whenNotPaused {
        require(IERC20Upgradeable(token).approve(symmioAddress, amount), "SymmioPartyB: Not approved");
    }

    function _executeCall(address destAddress, bytes memory callData) internal {
        require(destAddress != address(0), "SymmioPartyB: Invalid address");
        require(callData.length >= 4, "SymmioPartyB: Invalid call data");

        if (destAddress == symmioAddress) {
            bytes4 functionSelector;
            assembly {
                functionSelector := mload(add(callData, 0x20))
            }
            if (restrictedSelectors[functionSelector]) {
                _checkRole(MANAGER_ROLE, msg.sender);
            } else {
                require(hasRole(MANAGER_ROLE, msg.sender) || hasRole(TRUSTED_ROLE, msg.sender), "SymmioPartyB: Invalid access");
            }
        } else {
            require(multicastWhitelist[destAddress], "SymmioPartyB: Destination address is not whitelisted");
            _checkRole(TRUSTED_ROLE, msg.sender);
        }

        (bool success, ) = destAddress.call{ value: 0 }(callData);
        require(success, "SymmioPartyB: Execution reverted");
    }

    function _call(bytes[] calldata _callDatas) external whenNotPaused {
        for (uint8 i; i < _callDatas.length; i++) _executeCall(symmioAddress, _callDatas[i]);
    }

    function _multicastCall(address[] calldata destAddresses, bytes[] calldata _callDatas) external whenNotPaused {
        require(destAddresses.length == _callDatas.length, "SymmioPartyB: Array length mismatch");

        for (uint8 i; i < _callDatas.length; i++) _executeCall(destAddresses[i], _callDatas[i]);
    }

    function withdrawERC20(address token, uint256 amount) external onlyRole(MANAGER_ROLE) {
        require(IERC20Upgradeable(token).transfer(msg.sender, amount), "SymmioPartyB: Not transferred");
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

enum LiquidationType {
    NONE,
    NORMAL,
    LATE,
    OVERDUE
}

struct SettlementState {
    int256 actualAmount; 
    int256 expectedAmount; 
    uint256 cva;
    bool pending;
}

struct LiquidationDetail {
    bytes liquidationId;
    LiquidationType liquidationType;
    int256 upnl;
    int256 totalUnrealizedLoss;
    uint256 deficit;
    uint256 liquidationFee;
    uint256 timestamp;
    uint256 involvedPartyBCounts;
    int256 partyAAccumulatedUpnl;
    bool disputed;
}

struct Price {
    uint256 price;
    uint256 timestamp;
}

library AccountStorage {
    bytes32 internal constant ACCOUNT_STORAGE_SLOT = keccak256("diamond.standard.storage.account");

    struct Layout {
        // Users deposited amounts
        mapping(address => uint256) balances;
        mapping(address => uint256) allocatedBalances;
        // position value will become pending locked before openPosition and will be locked after that
        mapping(address => LockedValues) pendingLockedBalances;
        mapping(address => LockedValues) lockedBalances;
        mapping(address => mapping(address => uint256)) partyBAllocatedBalances;
        mapping(address => mapping(address => LockedValues)) partyBPendingLockedBalances;
        mapping(address => mapping(address => LockedValues)) partyBLockedBalances;
        mapping(address => uint256) withdrawCooldown;
        mapping(address => uint256) partyANonces;
        mapping(address => mapping(address => uint256)) partyBNonces;
        mapping(address => bool) suspendedAddresses;
        mapping(address => LiquidationDetail) liquidationDetails;
        mapping(address => mapping(uint256 => Price)) symbolsPrices;
        mapping(address => address[]) liquidators;
        mapping(address => uint256) partyAReimbursement;
        // partyA => partyB => SettlementState
        mapping(address => mapping(address => SettlementState)) settlementStates;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = ACCOUNT_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

library GlobalAppStorage {
    bytes32 internal constant GLOBAL_APP_STORAGE_SLOT =
        keccak256("diamond.standard.storage.global");

    struct Layout {
        address collateral;
        address feeCollector;
        bool globalPaused;
        bool liquidationPaused;
        bool accountingPaused;
        bool partyBActionsPaused;
        bool partyAActionsPaused;
        bool emergencyMode;
        uint256 balanceLimitPerUser;
        mapping(address => bool) partyBEmergencyStatus;
        mapping(address => mapping(bytes32 => bool)) hasRole;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = GLOBAL_APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

library MAStorage {
    bytes32 internal constant MA_STORAGE_SLOT =
        keccak256("diamond.standard.storage.masteragreement");

    struct Layout {
        uint256 deallocateCooldown;
        uint256 forceCancelCooldown;
        uint256 forceCancelCloseCooldown;
        uint256 forceCloseCooldown;
        uint256 liquidationTimeout;
        uint256 liquidatorShare; // in 18 decimals
        uint256 pendingQuotesValidLength;
        uint256 forceCloseGapRatio;
        mapping(address => bool) partyBStatus;
        mapping(address => bool) liquidationStatus;
        mapping(address => mapping(address => bool)) partyBLiquidationStatus;
        mapping(address => mapping(address => uint256)) partyBLiquidationTimestamp;
        mapping(address => mapping(address => uint256)) partyBPositionLiquidatorsShare;
        address[] partyBList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = MA_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

struct PublicKey {
    uint256 x;
    uint8 parity;
}

struct SingleUpnlSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnl;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct SingleUpnlAndPriceSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnl;
    uint256 price;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct PairUpnlSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnlPartyA;
    int256 upnlPartyB;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct PairUpnlAndPriceSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnlPartyA;
    int256 upnlPartyB;
    uint256 price;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct LiquidationSig {
    bytes reqId;
    uint256 timestamp;
    bytes liquidationId;
    int256 upnl;
    int256 totalUnrealizedLoss; 
    uint256[] symbolIds;
    uint256[] prices;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct QuotePriceSig {
    bytes reqId;
    uint256 timestamp;
    uint256[] quoteIds;
    uint256[] prices;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

library MuonStorage {
    bytes32 internal constant MUON_STORAGE_SLOT = keccak256("diamond.standard.storage.muon");

    struct Layout {
        uint256 upnlValidTime;
        uint256 priceValidTime;
        uint256 priceQuantityValidTime;
        uint256 muonAppId;
        PublicKey muonPublicKey;
        address validGateway;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = MUON_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

enum PositionType {
    LONG,
    SHORT
}

enum OrderType {
    LIMIT,
    MARKET
}

enum QuoteStatus {
    PENDING, //0
    LOCKED, //1
    CANCEL_PENDING, //2
    CANCELED, //3
    OPENED, //4
    CLOSE_PENDING, //5
    CANCEL_CLOSE_PENDING, //6
    CLOSED, //7
    LIQUIDATED, //8
    EXPIRED //9
}

struct Quote {
    uint256 id;
    address[] partyBsWhiteList;
    uint256 symbolId;
    PositionType positionType;
    OrderType orderType;
    // Price of quote which PartyB opened in 18 decimals
    uint256 openedPrice;
    uint256 initialOpenedPrice;
    // Price of quote which PartyA requested in 18 decimals
    uint256 requestedOpenPrice;
    uint256 marketPrice;
    // Quantity of quote which PartyA requested in 18 decimals
    uint256 quantity;
    // Quantity of quote which PartyB has closed until now in 18 decimals
    uint256 closedAmount;
    LockedValues initialLockedValues;
    LockedValues lockedValues;
    uint256 maxFundingRate;
    address partyA;
    address partyB;
    QuoteStatus quoteStatus;
    uint256 avgClosedPrice;
    uint256 requestedClosePrice;
    uint256 quantityToClose;
    // handle partially open position
    uint256 parentId;
    uint256 createTimestamp;
    uint256 statusModifyTimestamp;
    uint256 lastFundingPaymentTimestamp;
    uint256 deadline;
    uint256 tradingFee;
}

library QuoteStorage {
    bytes32 internal constant QUOTE_STORAGE_SLOT = keccak256("diamond.standard.storage.quote");

    struct Layout {
        mapping(address => uint256[]) quoteIdsOf;
        mapping(uint256 => Quote) quotes;
        mapping(address => uint256) partyAPositionsCount;
        mapping(address => mapping(address => uint256)) partyBPositionsCount;
        mapping(address => uint256[]) partyAPendingQuotes;
        mapping(address => mapping(address => uint256[])) partyBPendingQuotes;
        mapping(address => uint256[]) partyAOpenPositions;
        mapping(uint256 => uint256) partyAPositionsIndex;
        mapping(address => mapping(address => uint256[])) partyBOpenPositions;
        mapping(uint256 => uint256) partyBPositionsIndex;
        uint256 lastId;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = QUOTE_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

struct Symbol {
    uint256 symbolId;
    string name;
    bool isValid;
    uint256 minAcceptableQuoteValue;
    uint256 minAcceptablePortionLF;
    uint256 tradingFee;
    uint256 maxLeverage;
    uint256 fundingRateEpochDuration;
    uint256 fundingRateWindowTime;
}

library SymbolStorage {
    bytes32 internal constant SYMBOL_STORAGE_SLOT = keccak256("diamond.standard.storage.symbol");

    struct Layout {
        mapping(uint256 => Symbol) symbols;
        uint256 lastId;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SYMBOL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC165} from "../interfaces/IERC165.sol";

contract DiamondInit {
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/MAStorage.sol";
import "../storages/AccountStorage.sol";
import "../storages/QuoteStorage.sol";
import "../libraries/LibAccessibility.sol";

abstract contract Accessibility {
    modifier onlyPartyB() {
        require(MAStorage.layout().partyBStatus[msg.sender], "Accessibility: Should be partyB");
        _;
    }

    modifier notPartyB() {
        require(!MAStorage.layout().partyBStatus[msg.sender], "Accessibility: Shouldn't be partyB");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(LibAccessibility.hasRole(msg.sender, role), "Accessibility: Must has role");
        _;
    }

    modifier notLiquidatedPartyA(address partyA) {
        require(
            !MAStorage.layout().liquidationStatus[partyA],
            "Accessibility: PartyA isn't solvent"
        );
        _;
    }

    modifier notLiquidatedPartyB(address partyB, address partyA) {
        require(
            !MAStorage.layout().partyBLiquidationStatus[partyB][partyA],
            "Accessibility: PartyB isn't solvent"
        );
        _;
    }

    modifier notLiquidated(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(
            !MAStorage.layout().liquidationStatus[quote.partyA],
            "Accessibility: PartyA isn't solvent"
        );
        require(
            !MAStorage.layout().partyBLiquidationStatus[quote.partyB][quote.partyA],
            "Accessibility: PartyB isn't solvent"
        );
        require(
            quote.quoteStatus != QuoteStatus.LIQUIDATED && quote.quoteStatus != QuoteStatus.CLOSED,
            "Accessibility: Invalid state"
        );
        _;
    }

    modifier onlyPartyAOfQuote(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.partyA == msg.sender, "Accessibility: Should be partyA of quote");
        _;
    }

    modifier onlyPartyBOfQuote(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.partyB == msg.sender, "Accessibility: Should be partyB of quote");
        _;
    }

    modifier notSuspended(address user) {
        require(
            !AccountStorage.layout().suspendedAddresses[user],
            "Accessibility: Sender is Suspended"
        );
        _;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibDiamond.sol";

abstract contract Ownable {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyOwnerOrContract() {
        LibDiamond.enforceIsOwnerOrContract();
        _;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/GlobalAppStorage.sol";

abstract contract Pausable {
    modifier whenNotGlobalPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        _;
    }

    modifier whenNotLiquidationPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().liquidationPaused, "Pausable: Liquidation paused");
        _;
    }

    modifier whenNotAccountingPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().accountingPaused, "Pausable: Accounting paused");
        _;
    }

    modifier whenNotPartyAActionsPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().partyAActionsPaused, "Pausable: PartyA actions paused");
        _;
    }

    modifier whenNotPartyBActionsPaused() {
        require(!GlobalAppStorage.layout().globalPaused, "Pausable: Global paused");
        require(!GlobalAppStorage.layout().partyBActionsPaused, "Pausable: PartyB actions paused");
        _;
    }

    modifier whenEmergencyMode(address partyB) {
        require(
            GlobalAppStorage.layout().emergencyMode ||
                GlobalAppStorage.layout().partyBEmergencyStatus[partyB],
            "Pausable: It isn't emergency mode"
        );
        _;
    }
}