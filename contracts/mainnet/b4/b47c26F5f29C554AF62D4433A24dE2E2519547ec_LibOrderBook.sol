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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface IAccount {
    event DepositCollateral(
        bytes32 indexed subAccountId,
        address indexed trader,
        uint8 collateralId,
        uint256 rawAmount,
        uint96 wadAmount
    );

    event WithdrawCollateral(
        bytes32 indexed subAccountId,
        address indexed trader,
        uint8 collateralId,
        uint256 rawAmount,
        uint96 wadAmount
    );

    function depositCollateral(
        bytes32 subAccountId,
        uint256 rawAmount // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
    ) external;

    function withdrawCollateral(
        bytes32 subAccountId,
        uint256 rawAmount,
        uint96 collateralPrice,
        uint96 assetPrice
    ) external;

    function withdrawAllCollateral(bytes32 subAccountId) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/**
 * @title IAdmin
 * @dev Interface for the Admin contract.
 */
interface IAdmin {
    event SetMaintainer(address indexed newMaintainer, bool enable);
    event SetMaintenanceParameters(address indexed operator, bytes32 keys, bool enable);
    event AddAsset(uint8 indexed id);
    event SetPoolParameters(address indexed operator, bytes32[] keys, bytes32[] values);
    event SetAssetParameters(address indexed operator, uint8 indexed assetId, bytes32[] keys, bytes32[] values);
    event SetAssetFlags(address indexed operator, uint8 indexed assetId, uint56 newFlags);

    function setMaintainer(address newMaintainer, bool enable) external;

    function setMaintenanceParameters(bytes32 key, bool enable) external;

    function addAsset(uint8 assetId, bytes32[] calldata keys, bytes32[] calldata values) external;

    function setPoolParameters(
        bytes32[] calldata keys,
        bytes32[] calldata values,
        bytes32[] calldata currentValues
    ) external;

    function setAssetParameters(
        uint8 assetId,
        bytes32[] calldata keys,
        bytes32[] calldata values,
        bytes32[] calldata currentValues
    ) external;

    function setAssetFlags(
        uint8 assetId,
        bool isTradable,
        bool isOpenable,
        bool isShortable,
        bool isEnabled,
        bool isStable,
        bool isStrictStable,
        bool canAddRemoveLiquidity
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./IDegenPoolStorage.sol";
import "./IAccount.sol";
import "./IAdmin.sol";
import "./IGetter.sol";
import "./ILiquidity.sol";
import "./ITrade.sol";

import "../Types.sol";

interface IDegenPool is IDegenPoolStorage, IAccount, IAdmin, IGetter, ILiquidity, ITrade {}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface IDegenPoolStorage {
    event UpdateSequence(uint256 sequence);
    event CollectedFee(uint8 tokenId, uint96 wadFeeCollateral);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.19;

interface IGetter {
    function diamondOwner() external view returns (address);

    function getPoolParameter(bytes32 key) external view returns (bytes32);

    function isMaintainer(address maintainer) external view returns (bool);

    function getMaintenanceParameter(bytes32 key) external view returns (bool);

    function getPoolStorage()
        external
        view
        returns (uint8 assetsCount, uint32 sequence, uint32 lastFundingTime, uint32 brokerTransactions);

    function getAssetParameter(uint8 assetId, bytes32 key) external view returns (bytes32);

    function getAssetFlags(uint8 assetId) external view returns (uint56);

    function getAssetStorageV2(
        uint8 assetId
    )
        external
        view
        returns (
            uint56 flags,
            uint96 spotLiquidity,
            uint96 totalLongPosition,
            uint96 averageLongPrice,
            uint96 totalShortPosition,
            uint96 averageShortPrice,
            uint128 longCumulativeFunding,
            uint128 shortCumulativeFunding
        );

    function getSubAccount(
        bytes32 subAccountId
    )
        external
        view
        returns (uint96 collateral, uint96 size, uint32 lastIncreasedTime, uint96 entryPrice, uint128 entryFunding);

    function traderPnl(
        bytes32 subAccountId,
        uint96 price
    ) external returns (bool hasProfit, uint96 positionPnlUsd, uint96 cappedPnlUsd);

    function isDeleverageAllowed(bytes32 subAccountId, uint96 markPrice) external returns (bool);

    function getSubAccountIds(
        uint256 begin,
        uint256 end
    ) external view returns (bytes32[] memory subAccountIds, uint256 totalCount);

    function getSubAccountIdsOf(
        address trader,
        uint256 begin,
        uint256 end
    ) external view returns (bytes32[] memory subAccountIds, uint256 totalCount);

    function getMlpPrice(uint96[] memory markPrices) external returns (uint96 mlpPrice);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface ILiquidity {
    event AddLiquidity(
        address indexed trader,
        uint8 indexed tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 mlpAmount,
        uint96 fee
    );

    event DonateLiquidity(address indexed who, uint8 indexed tokenId, uint96 wadAmount);

    event RemoveLiquidity(
        address indexed trader,
        uint8 indexed tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 mlpAmount,
        uint96 fee
    );

    event ClaimBrokerGasRebate(address indexed receiver, uint32 transactions, uint256 rawAmount);

    event UpdateFundingRate(
        uint8 indexed tokenId,
        bool isPositiveFundingRate,
        uint32 newFundingRateApy, // 1e5
        uint32 newBorrowingRateApy, // 1e5
        uint128 longCumulativeFunding, // 1e18
        uint128 shortCumulativeFunding // 1e18
    );

    /**
     * @dev   Add liquidity.
     *
     * @param trader            liquidity provider address.
     * @param tokenId           asset.id that added.
     * @param rawAmount         asset token amount. decimals = erc20.decimals.
     * @param markPrices        markPrices prices of all supported assets.
     */
    function addLiquidity(
        address trader,
        uint8 tokenId,
        uint256 rawAmount, // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
        uint96[] memory markPrices
    ) external returns (uint96 mlpAmount);

    /**
     * @dev Add liquidity but ignore MLP
     */
    function donateLiquidity(
        address who,
        uint8 tokenId,
        uint256 rawAmount // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
    ) external;

    /**
     * @dev   Remove liquidity.
     *
     * @param trader            liquidity provider address.
     * @param mlpAmount         mlp amount.
     * @param tokenId           asset.id that removed to.
     * @param markPrices        asset prices of all supported assets.
     */
    function removeLiquidity(
        address trader,
        uint96 mlpAmount,
        uint8 tokenId,
        uint96[] memory markPrices
    ) external returns (uint256 rawAmount);

    /**
     * @notice Broker can update funding each [fundingInterval] seconds by specifying utilizations.
     *
     *         Check _updateFundingState in Liquidity.sol and _getBorrowing in Trade.sol
     *         on how to calculate funding and borrowing.
     */
    function updateFundingState() external;

    /**
     * @dev Broker can withdraw brokerGasRebate.
     */
    function claimBrokerGasRebate(address receiver) external returns (uint256 rawAmount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface IReferralManager {
    struct TierSetting {
        uint8 tier;
        uint64 stakeThreshold;
        uint64 discountRate;
        uint64 rebateRate;
    }

    event RegisterReferralCode(address referralCodeOwner, bytes32 referralCode);
    event SetReferralCode(address trader, bytes32 referralCode);
    event SetHandler(address handler, bool enable);
    event SetTiers(TierSetting[] newTierSettings);
    event SetMaintainer(address previousMaintainer, address newMaintainer);
    event SetRebateRecipient(bytes32 referralCode, address referralCodeOwner, address rebateRecipient);
    event TransferReferralCode(bytes32 referralCode, address previousOwner, address newOwner);

    function isHandler(address handler) external view returns (bool);

    function rebateRecipients(bytes32 referralCode) external view returns (address);

    // management methods
    function setHandler(address handler, bool enable) external;

    function setTiers(TierSetting[] memory newTierSettings) external;

    // methods only available on primary network
    function isValidReferralCode(bytes32 referralCode) external view returns (bool);

    function registerReferralCode(bytes32 referralCode, address rebateRecipient) external;

    function setRebateRecipient(bytes32 referralCode, address rebateRecipient) external;

    function transferReferralCode(bytes32 referralCode, address newOwner) external;

    // methods available on secondary network
    function getReferralCodeOf(address trader) external view returns (bytes32, uint256);

    function setReferrerCode(bytes32 referralCode) external;

    function setReferrerCodeFor(address trader, bytes32 referralCode) external;

    function tierSettings(
        uint256 tier
    ) external view returns (uint8 retTier, uint64 stakeThreshold, uint64 discountRate, uint64 rebateRate);
}

// SPDX-License-Identifier: GPL-2.0-or-later

/**
 * @title ITrade
 * @dev Interface for the Trade contract, which handles opening, closing, and liquidating positions, as well as withdrawing profits.
 */
pragma solidity 0.8.19;

interface ITrade {
    struct OpenPositionArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        bool isLong;
        uint96 amount;
        uint96 tradingPrice;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 newEntryPrice;
        uint96 feeUsd;
        uint96 remainPosition;
        uint96 remainCollateral;
    }
    struct ClosePositionArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        uint8 profitAssetId;
        bool isLong;
        uint96 amount;
        uint96 tradingPrice;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 profitAssetPrice;
        uint96 feeUsd;
        bool hasProfit;
        uint96 pnlUsd;
        uint96 remainPosition;
        uint96 remainCollateral;
    }
    struct LiquidateArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        uint8 profitAssetId;
        bool isLong;
        uint96 amount;
        uint96 tradingPrice;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 profitAssetPrice;
        uint96 feeUsd;
        bool hasProfit;
        uint96 pnlUsd;
        uint96 remainCollateral;
    }

    event OpenPosition(address indexed trader, uint8 indexed assetId, OpenPositionArgs args);
    event ClosePosition(address indexed trader, uint8 indexed assetId, ClosePositionArgs args);
    event Liquidate(address indexed trader, uint8 indexed assetId, LiquidateArgs args);

    /**
     * @notice Open a position.
     *
     * @param  subAccountId     check LibSubAccount.decodeSubAccountId for detail.
     * @param  amount           filled position size. decimals = 18.
     * @param  tradingPrice     price of subAccount.asset. decimals = 18.
     * @param  markPrices       mark prices of all assets. decimals = 18.
     */
    function openPosition(
        bytes32 subAccountId,
        uint96 amount,
        uint96 tradingPrice,
        uint96[] memory markPrices
    ) external returns (uint96);

    /**
     * @notice Close a position.
     *
     * @param  subAccountId     check LibSubAccount.decodeSubAccountId for detail.
     * @param  amount           filled position size. decimals = 18.
     * @param  tradingPrice     price of subAccount.asset. decimals = 18.
     * @param  profitAssetId    for long position (unless asset.useStable is true), ignore this argument;
     *                          for short position, the profit asset should be one of the stable coin.
     * @param  markPrices      mark prices of all assets. decimals = 18.
     */
    function closePosition(
        bytes32 subAccountId,
        uint96 amount,
        uint96 tradingPrice,
        uint8 profitAssetId,
        uint96[] memory markPrices
    ) external returns (uint96);

    function liquidate(
        bytes32 subAccountId,
        uint8 profitAssetId,
        uint96 tradingPrice,
        uint96[] memory markPrices
    ) external returns (uint96);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

library LibConfigKeys {
    // POOL
    bytes32 constant MLP_TOKEN = keccak256("MLP_TOKEN");
    bytes32 constant ORDER_BOOK = keccak256("ORDER_BOOK");
    bytes32 constant FEE_DISTRIBUTOR = keccak256("FEE_DISTRIBUTOR");

    bytes32 constant FUNDING_INTERVAL = keccak256("FUNDING_INTERVAL");
    bytes32 constant BORROWING_RATE_APY = keccak256("BORROWING_RATE_APY");

    bytes32 constant LIQUIDITY_FEE_RATE = keccak256("LIQUIDITY_FEE_RATE");

    bytes32 constant STRICT_STABLE_DEVIATION = keccak256("STRICT_STABLE_DEVIATION");
    bytes32 constant BROKER_GAS_REBATE = keccak256("BROKER_GAS_REBATE");

    // POOL - ASSET
    bytes32 constant SYMBOL = keccak256("SYMBOL");
    bytes32 constant DECIMALS = keccak256("DECIMALS");
    bytes32 constant TOKEN_ADDRESS = keccak256("TOKEN_ADDRESS");
    bytes32 constant LOT_SIZE = keccak256("LOT_SIZE");

    bytes32 constant INITIAL_MARGIN_RATE = keccak256("INITIAL_MARGIN_RATE");
    bytes32 constant MAINTENANCE_MARGIN_RATE = keccak256("MAINTENANCE_MARGIN_RATE");
    bytes32 constant MIN_PROFIT_RATE = keccak256("MIN_PROFIT_RATE");
    bytes32 constant MIN_PROFIT_TIME = keccak256("MIN_PROFIT_TIME");
    bytes32 constant POSITION_FEE_RATE = keccak256("POSITION_FEE_RATE");
    bytes32 constant LIQUIDATION_FEE_RATE = keccak256("LIQUIDATION_FEE_RATE");

    bytes32 constant REFERENCE_ORACLE = keccak256("REFERENCE_ORACLE");
    bytes32 constant REFERENCE_DEVIATION = keccak256("REFERENCE_DEVIATION");
    bytes32 constant REFERENCE_ORACLE_TYPE = keccak256("REFERENCE_ORACLE_TYPE");

    bytes32 constant MAX_LONG_POSITION_SIZE = keccak256("MAX_LONG_POSITION_SIZE");
    bytes32 constant MAX_SHORT_POSITION_SIZE = keccak256("MAX_SHORT_POSITION_SIZE");
    bytes32 constant FUNDING_ALPHA = keccak256("FUNDING_ALPHA");
    bytes32 constant FUNDING_BETA_APY = keccak256("FUNDING_BETA_APY");

    bytes32 constant LIQUIDITY_CAP_USD = keccak256("LIQUIDITY_CAP_USD");

    // ADL
    bytes32 constant ADL_RESERVE_RATE = keccak256("ADL_RESERVE_RATE");
    bytes32 constant ADL_MAX_PNL_RATE = keccak256("ADL_MAX_PNL_RATE");
    bytes32 constant ADL_TRIGGER_RATE = keccak256("ADL_TRIGGER_RATE");

    // ORDERBOOK
    bytes32 constant OB_LIQUIDITY_LOCK_PERIOD = keccak256("OB_LIQUIDITY_LOCK_PERIOD");
    bytes32 constant OB_REFERRAL_MANAGER = keccak256("OB_REFERRAL_MANAGER");
    bytes32 constant OB_MARKET_ORDER_TIMEOUT = keccak256("OB_MARKET_ORDER_TIMEOUT");
    bytes32 constant OB_LIMIT_ORDER_TIMEOUT = keccak256("OB_LIMIT_ORDER_TIMEOUT");
    bytes32 constant OB_CALLBACK_GAS_LIMIT = keccak256("OB_CALLBACK_GAS_LIMIT");
    bytes32 constant OB_CANCEL_COOL_DOWN = keccak256("OB_CANCEL_COOL_DOWN");
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

library LibMath {
    function min(uint96 a, uint96 b) internal pure returns (uint96) {
        return a <= b ? a : b;
    }

    function min32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a <= b ? a : b;
    }

    function max32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a >= b ? a : b;
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 1e18;
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 1e5;
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * 1e18) / b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./LibSubAccount.sol";
import "../orderbook/Types.sol";

library LibOrder {
    using LibSubAccount for bytes32;
    // position order flags
    uint8 constant POSITION_OPEN = 0x80; // this flag means openPosition; otherwise closePosition
    uint8 constant POSITION_MARKET_ORDER = 0x40; // this flag do nothing, just for compatibility
    uint8 constant POSITION_WITHDRAW_ALL_IF_EMPTY = 0x20; // this flag means auto withdraw all collateral if position.size == 0
    uint8 constant POSITION_TRIGGER_ORDER = 0x10; // this flag means this is a trigger order (ex: stop-loss order). otherwise this is a limit order (ex: take-profit order)
    uint8 constant POSITION_TPSL_STRATEGY = 0x08; // for open-position-order, this flag auto place take-profit and stop-loss orders when open-position-order fills.
    //                                               for close-position-order, this flag means ignore limitPrice and profitTokenId, and use extra.tpPrice, extra.slPrice, extra.tpslProfitTokenId instead.
    uint8 constant POSITION_SHOULD_REACH_MIN_PROFIT = 0x04; // this flag is used to ensure that either the minProfitTime is met or the minProfitRate ratio is reached when close a position. only available when minProfitTime > 0.
    uint8 constant POSITION_AUTO_DELEVERAGE = 0x02; // denotes that this order is an auto-deleverage order
    // order data[1] SHOULD reserve lower 64bits for enumIndex
    bytes32 constant ENUM_INDEX_BITS = bytes32(uint256(0xffffffffffffffff));

    // check Types.PositionOrder for schema
    function encodePositionOrder(
        PositionOrderParams memory orderParams,
        uint64 orderId,
        uint32 blockTimestamp
    ) internal pure returns (OrderData memory orderData) {
        orderData.orderType = OrderType.PositionOrder;
        orderData.id = orderId;
        orderData.version = 1;
        orderData.account = orderParams.subAccountId.owner();
        orderData.placeOrderTime = blockTimestamp;
        orderData.payload = abi.encode(orderParams);
    }

    // check Types.PositionOrder for schema
    function decodePositionOrder(
        OrderData memory orderData
    ) internal pure returns (PositionOrderParams memory orderParams) {
        require(orderData.orderType == OrderType.PositionOrder, "ODT"); // OrDer Type
        require(orderData.version == 1, "ODV"); // OrDer Version
        require(orderData.payload.length == 11 * 32, "ODP"); // OrDer Payload
        orderParams = abi.decode(orderData.payload, (PositionOrderParams));
    }

    // check Types.LiquidityOrder for schema
    function encodeLiquidityOrder(
        LiquidityOrderParams memory orderParams,
        uint64 orderId,
        address account,
        uint32 blockTimestamp
    ) internal pure returns (OrderData memory orderData) {
        orderData.orderType = OrderType.LiquidityOrder;
        orderData.id = orderId;
        orderData.version = 1;
        orderData.account = account;
        orderData.placeOrderTime = blockTimestamp;
        orderData.payload = abi.encode(orderParams);
    }

    // check Types.LiquidityOrder for schema
    function decodeLiquidityOrder(
        OrderData memory orderData
    ) internal pure returns (LiquidityOrderParams memory orderParams) {
        require(orderData.orderType == OrderType.LiquidityOrder, "ODT"); // OrDer Type
        require(orderData.version == 1, "ODV"); // OrDer Version
        require(orderData.payload.length == 3 * 32, "ODP"); // OrDer Payload
        orderParams = abi.decode(orderData.payload, (LiquidityOrderParams));
    }

    // check Types.WithdrawalOrder for schema
    function encodeWithdrawalOrder(
        WithdrawalOrderParams memory orderParams,
        uint64 orderId,
        uint32 blockTimestamp
    ) internal pure returns (OrderData memory orderData) {
        orderData.orderType = OrderType.WithdrawalOrder;
        orderData.id = orderId;
        orderData.version = 1;
        orderData.account = orderParams.subAccountId.owner();
        orderData.placeOrderTime = blockTimestamp;
        orderData.payload = abi.encode(orderParams);
    }

    // check Types.WithdrawalOrder for schema
    function decodeWithdrawalOrder(
        OrderData memory orderData
    ) internal pure returns (WithdrawalOrderParams memory orderParams) {
        require(orderData.orderType == OrderType.WithdrawalOrder, "ODT"); // OrDer Type
        require(orderData.version == 1, "ODV"); // OrDer Version
        require(orderData.payload.length == 4 * 32, "ODP"); // OrDer Payload
        orderParams = abi.decode(orderData.payload, (WithdrawalOrderParams));
    }

    function isOpenPosition(PositionOrderParams memory orderParams) internal pure returns (bool) {
        return (orderParams.flags & POSITION_OPEN) != 0;
    }

    function isMarketOrder(PositionOrderParams memory orderParams) internal pure returns (bool) {
        return (orderParams.flags & POSITION_MARKET_ORDER) != 0;
    }

    function isWithdrawIfEmpty(PositionOrderParams memory orderParams) internal pure returns (bool) {
        return (orderParams.flags & POSITION_WITHDRAW_ALL_IF_EMPTY) != 0;
    }

    function isTriggerOrder(PositionOrderParams memory orderParams) internal pure returns (bool) {
        return (orderParams.flags & POSITION_TRIGGER_ORDER) != 0;
    }

    function isTpslStrategy(PositionOrderParams memory orderParams) internal pure returns (bool) {
        return (orderParams.flags & POSITION_TPSL_STRATEGY) != 0;
    }

    function shouldReachMinProfit(PositionOrderParams memory orderParams) internal pure returns (bool) {
        return (orderParams.flags & POSITION_SHOULD_REACH_MIN_PROFIT) != 0;
    }

    function isAdl(PositionOrderParams memory orderParams) internal pure returns (bool) {
        return (orderParams.flags & POSITION_AUTO_DELEVERAGE) != 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IReferralManager.sol";
import "../libraries/LibSubAccount.sol";
import "../libraries/LibMath.sol";
import "../orderbook/Types.sol";
import "../orderbook/Storage.sol";

library LibOrderBook {
    using LibSubAccount for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibTypeCast for bytes32;
    using LibTypeCast for uint256;
    using LibOrder for PositionOrderParams;
    using LibOrder for LiquidityOrderParams;
    using LibOrder for WithdrawalOrderParams;
    using LibOrder for OrderData;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using LibMath for uint256;

    // do not forget to update OrderBook if this line updates
    event CancelOrder(address indexed account, uint64 indexed orderId, OrderData orderData);
    // do not forget to update OrderBook if this line updates
    event NewLiquidityOrder(address indexed account, uint64 indexed orderId, LiquidityOrderParams params);
    // do not forget to update OrderBook if this line updates
    event NewPositionOrder(address indexed account, uint64 indexed orderId, PositionOrderParams params);
    // do not forget to update OrderBook if this line updates
    event NewWithdrawalOrder(address indexed account, uint64 indexed orderId, WithdrawalOrderParams params);
    // do not forget to update OrderBook if this line updates
    event FillOrder(address indexed account, uint64 indexed orderId, OrderData orderData);
    // do not forget to update OrderBook if this line updates
    event FillAdlOrder(address indexed account, AdlOrderParams params);

    uint256 public constant MAX_TP_SL_ORDERS = 32;

    function liquidityLockPeriod(OrderBookStorage storage orderBook) internal view returns (uint32) {
        return orderBook.parameters[LibConfigKeys.OB_LIQUIDITY_LOCK_PERIOD].toUint32();
    }

    function appendOrder(OrderBookStorage storage orderBook, OrderData memory orderData) internal {
        orderBook.orderData[orderData.id] = orderData;
        orderBook.orders.add(orderData.id);
        orderBook.userOrders[orderData.account].add(orderData.id);
    }

    function removeOrder(OrderBookStorage storage orderBook, OrderData memory orderData) internal {
        orderBook.userOrders[orderData.account].remove(orderData.id);
        orderBook.orders.remove(orderData.id);
        delete orderBook.orderData[orderData.id];
    }

    function placeLiquidityOrder(
        OrderBookStorage storage orderBook,
        LiquidityOrderParams memory orderParams,
        address account,
        uint32 blockTimestamp
    ) external {
        require(orderParams.rawAmount != 0, "A=0"); // Amount Is Zero
        _validateAssets(
            orderBook,
            orderParams.assetId,
            ASSET_IS_ENABLED | ASSET_CAN_ADD_REMOVE_LIQUIDITY | ASSET_IS_STABLE,
            0
        );
        if (orderParams.isAdding) {
            address collateralAddress = IDegenPool(orderBook.pool)
                .getAssetParameter(orderParams.assetId, LibConfigKeys.TOKEN_ADDRESS)
                .toAddress();
            _transferIn(account, collateralAddress, address(this), orderParams.rawAmount);
        } else {
            IERC20Upgradeable(orderBook.mlpToken).safeTransferFrom(account, address(this), orderParams.rawAmount);
        }
        uint64 orderId = orderBook.nextOrderId++;
        OrderData memory orderData = orderParams.encodeLiquidityOrder(orderId, account, blockTimestamp);
        appendOrder(orderBook, orderData);
        emit NewLiquidityOrder(account, orderId, orderParams);
    }

    function fillLiquidityOrder(
        OrderBookStorage storage orderBook,
        OrderData memory orderData,
        uint96[] memory markPrices,
        uint32 blockTimestamp
    ) external returns (uint256 outAmount) {
        LiquidityOrderParams memory orderParams = orderData.decodeLiquidityOrder();
        require(blockTimestamp >= orderData.placeOrderTime + liquidityLockPeriod(orderBook), "LCK"); // mlp token is LoCKed
        uint96 rawAmount = orderParams.rawAmount;
        if (orderParams.isAdding) {
            IERC20Upgradeable collateral = IERC20Upgradeable(
                IDegenPool(orderBook.pool)
                    .getAssetParameter(orderParams.assetId, LibConfigKeys.TOKEN_ADDRESS)
                    .toAddress()
            );
            collateral.safeTransfer(orderBook.pool, rawAmount);
            outAmount = IDegenPool(orderBook.pool).addLiquidity(
                orderData.account,
                orderParams.assetId,
                rawAmount,
                markPrices
            );
        } else {
            outAmount = IDegenPool(orderBook.pool).removeLiquidity(
                orderData.account,
                rawAmount,
                orderParams.assetId,
                markPrices
            );
        }
    }

    function donateLiquidity(
        OrderBookStorage storage orderBook,
        address account,
        uint8 assetId,
        uint96 rawAmount // erc20.decimals
    ) external {
        require(rawAmount != 0, "A=0"); // Amount Is Zero
        address collateralAddress = IDegenPool(orderBook.pool)
            .getAssetParameter(assetId, LibConfigKeys.TOKEN_ADDRESS)
            .toAddress();
        _transferIn(account, collateralAddress, address(orderBook.pool), rawAmount);
        IDegenPool(orderBook.pool).donateLiquidity(account, assetId, rawAmount);
    }

    function placePositionOrder(
        OrderBookStorage storage orderBook,
        PositionOrderParams memory orderParams,
        uint32 blockTimestamp
    ) external {
        require(orderParams.size != 0, "S=0"); // order Size Is Zero
        require(orderParams.expiration > blockTimestamp, "D<0"); // Deadline is earlier than now
        require(orderParams.price > 0, "P=0"); // must have Price
        // TODO: min expire?
        if (orderParams.profitTokenId > 0) {
            // note: profitTokenId == 0 is also valid, this only partially protects the function from misuse
            require(!orderParams.isOpenPosition(), "T!0"); // opening position does not need a profit Token id
        }
        // verify asset
        _validateAssets(
            orderBook,
            orderParams.subAccountId.assetId(),
            ASSET_IS_TRADABLE | ASSET_IS_ENABLED,
            ASSET_IS_STABLE
        );
        _validateAssets(orderBook, orderParams.subAccountId.collateralId(), ASSET_IS_STABLE | ASSET_IS_ENABLED, 0);
        {
            uint96 lotSize = IDegenPool(orderBook.pool)
                .getAssetParameter(orderParams.subAccountId.assetId(), LibConfigKeys.LOT_SIZE)
                .toUint96();
            require(orderParams.size % lotSize == 0, "LOT"); // LOT size mismatch
        }
        require(!orderParams.isAdl(), "ADL"); // Auto DeLeverage is not allowed
        if (orderParams.isOpenPosition()) {
            _placeOpenPositionOrder(orderBook, orderParams, blockTimestamp);
        } else {
            _placeClosePositionOrder(orderBook, orderParams, blockTimestamp);
        }
    }

    function _placeOpenPositionOrder(
        OrderBookStorage storage orderBook,
        PositionOrderParams memory orderParams,
        uint32 blockTimestamp
    ) private {
        // fetch collateral
        if (orderParams.collateral > 0) {
            address accountOwner = orderParams.subAccountId.owner();
            uint8 collateralId = orderParams.subAccountId.collateralId();
            address collateralAddress = IDegenPool(orderBook.pool)
                .getAssetParameter(collateralId, LibConfigKeys.TOKEN_ADDRESS)
                .toAddress();
            _transferIn(accountOwner, collateralAddress, address(this), orderParams.collateral);
        }
        if (orderParams.isTpslStrategy()) {
            // tp/sl strategy
            require((orderParams.tpPrice > 0 || orderParams.slPrice > 0), "TPSL"); // TP/SL strategy need tpPrice and/or slPrice
            require(orderParams.tpslExpiration > blockTimestamp, "D<0"); // Deadline is earlier than now
        }
        // add order
        _placePositionOrder(orderBook, orderParams, blockTimestamp);
    }

    function _placeClosePositionOrder(
        OrderBookStorage storage orderBook,
        PositionOrderParams memory orderParams,
        uint32 blockTimestamp
    ) private {
        if (orderParams.isTpslStrategy()) {
            // tp/sl strategy
            require(orderParams.collateral == 0, "C!0"); // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
            require(orderParams.profitTokenId == 0, "T!0"); // use extra.tpProfitTokenId instead
            require(!orderParams.isMarketOrder(), "MKT"); // tp/sl strategy does not support MarKeT order
            require(orderParams.tpPrice > 0 && orderParams.slPrice > 0, "TPSL"); // tp/sl strategy need tpPrice and slPrice. otherwise use POSITION_TRIGGER_ORDER instead
            require(orderParams.tpslExpiration > blockTimestamp, "D<0"); // Deadline is earlier than now
            _validateAssets(orderBook, orderParams.tpslProfitTokenId, ASSET_IS_STABLE | ASSET_IS_ENABLED, 0);
            _placeTpslOrders(orderBook, orderParams, blockTimestamp);
        } else {
            // normal close-position-order
            _validateAssets(orderBook, orderParams.profitTokenId, ASSET_IS_STABLE | ASSET_IS_ENABLED, 0);
            if (orderParams.shouldReachMinProfit()) {
                // POSITION_MUST_PROFIT is only available if asset.minProfitTime > 0
                uint8 assetId = orderParams.subAccountId.assetId();
                uint32 minProfitTime = IDegenPool(orderBook.pool)
                    .getAssetParameter(assetId, LibConfigKeys.MIN_PROFIT_TIME)
                    .toUint32();
                require(minProfitTime > 0, "MPT"); // asset MinProfitTime is 0
            }
            _validateAssets(orderBook, orderParams.profitTokenId, ASSET_IS_STABLE | ASSET_IS_ENABLED, 0);
            _placePositionOrder(orderBook, orderParams, blockTimestamp);
        }
    }

    function cancelActivatedTpslOrders(OrderBookStorage storage orderBook, bytes32 subAccountId) public {
        EnumerableSetUpgradeable.UintSet storage orderIds = orderBook.tpslOrders[subAccountId];
        uint256 length = orderIds.length();
        for (uint256 i = 0; i < length; i++) {
            uint64 orderId = uint64(orderIds.at(i));
            require(orderBook.orders.contains(orderId), "OID"); // can not find this OrderID

            OrderData memory orderData = orderBook.orderData[orderId];
            OrderType orderType = OrderType(orderData.orderType);
            require(orderType == OrderType.PositionOrder, "TYP"); // order TYPe mismatch
            PositionOrderParams memory orderParams = orderData.decodePositionOrder();
            require(!orderParams.isOpenPosition() && orderParams.collateral == 0, "CLS"); // should be CLoSe position order and no withdraw
            removeOrder(orderBook, orderData);

            emit CancelOrder(orderData.account, orderId, orderData);
        }
        delete orderBook.tpslOrders[subAccountId]; // tp/sl strategy
    }

    function placeWithdrawalOrder(
        OrderBookStorage storage orderBook,
        WithdrawalOrderParams memory orderParams,
        uint32 blockTimestamp
    ) external {
        require(orderParams.rawAmount != 0, "A=0"); // Amount Is Zero
        uint64 newOrderId = orderBook.nextOrderId++;
        OrderData memory orderData = orderParams.encodeWithdrawalOrder(newOrderId, blockTimestamp);
        appendOrder(orderBook, orderData);
        emit NewWithdrawalOrder(orderData.account, newOrderId, orderParams);
    }

    function fillOpenPositionOrder(
        OrderBookStorage storage orderBook,
        PositionOrderParams memory orderParams,
        uint64 orderId,
        uint96 fillAmount,
        uint96 tradingPrice,
        uint96[] memory markPrices,
        uint32 blockTimestamp
    ) external returns (uint96 retTradingPrice) {
        // auto deposit
        if (orderParams.collateral > 0) {
            uint8 collateralId = orderParams.subAccountId.collateralId();
            address collateralAddress = IDegenPool(orderBook.pool)
                .getAssetParameter(collateralId, LibConfigKeys.TOKEN_ADDRESS)
                .toAddress();
            IERC20Upgradeable(collateralAddress).safeTransfer(address(orderBook.pool), orderParams.collateral);
            IDegenPool(orderBook.pool).depositCollateral(orderParams.subAccountId, orderParams.collateral);
        }
        // open
        tradingPrice = IDegenPool(orderBook.pool).openPosition(
            orderParams.subAccountId,
            fillAmount,
            tradingPrice,
            markPrices
        );
        // tp/sl strategy
        if (orderParams.isTpslStrategy()) {
            _placeTpslOrders(orderBook, orderParams, blockTimestamp);
        }
        return tradingPrice;
    }

    function fillClosePositionOrder(
        OrderBookStorage storage orderBook,
        PositionOrderParams memory orderParams,
        uint64 orderId,
        uint96 fillAmount,
        uint96 tradingPrice,
        uint96[] memory markPrices,
        uint32 blockTimestamp
    ) external returns (uint96 retTradingPrice) {
        // check min profit
        SubAccount memory oldSubAccount;
        if (orderParams.shouldReachMinProfit()) {
            (
                oldSubAccount.collateral,
                oldSubAccount.size,
                oldSubAccount.lastIncreasedTime,
                oldSubAccount.entryPrice,
                oldSubAccount.entryFunding
            ) = IDegenPool(orderBook.pool).getSubAccount(orderParams.subAccountId);
        }
        // close
        tradingPrice = IDegenPool(orderBook.pool).closePosition(
            orderParams.subAccountId,
            fillAmount,
            tradingPrice,
            orderParams.profitTokenId,
            markPrices
        );
        // check min profit
        if (orderParams.shouldReachMinProfit()) {
            require(_hasPassMinProfit(orderBook, orderParams, oldSubAccount, blockTimestamp, tradingPrice), "PFT"); // order must have ProFiT
        }
        // auto withdraw
        uint96 collateralAmount = orderParams.collateral;
        if (collateralAmount > 0) {
            uint96 collateralPrice = markPrices[orderParams.subAccountId.collateralId()];
            uint96 assetPrice = markPrices[orderParams.subAccountId.assetId()];
            IDegenPool(orderBook.pool).withdrawCollateral(
                orderParams.subAccountId,
                collateralAmount,
                collateralPrice,
                assetPrice
            );
        }
        // tp/sl strategy
        orderBook.tpslOrders[orderParams.subAccountId].remove(uint256(orderId));
        // is the position completely closed
        (uint96 collateral, uint96 size, , , ) = IDegenPool(orderBook.pool).getSubAccount(orderParams.subAccountId);
        if (size == 0) {
            // auto withdraw
            if (orderParams.isWithdrawIfEmpty() && collateral > 0) {
                IDegenPool(orderBook.pool).withdrawAllCollateral(orderParams.subAccountId);
            }

            // cancel activated tp/sl orders
            cancelActivatedTpslOrders(orderBook, orderParams.subAccountId);
        }
        return tradingPrice;
    }

    function fillAdlOrder(
        OrderBookStorage storage orderBook,
        AdlOrderParams memory orderParams,
        uint96 tradingPrice,
        uint96[] memory markPrices
    ) external returns (uint96 retTradingPrice) {
        // pre-check
        {
            uint96 markPrice = markPrices[orderParams.subAccountId.assetId()];
            require(IDegenPool(orderBook.pool).isDeleverageAllowed(orderParams.subAccountId, markPrice), "DLA"); // DeLeverage is not Allowed
        }
        // fill
        {
            uint96 fillAmount = orderParams.size;
            tradingPrice = IDegenPool(orderBook.pool).closePosition(
                orderParams.subAccountId,
                fillAmount,
                tradingPrice,
                orderParams.profitTokenId,
                markPrices
            );
        }
        // price check
        {
            bool isLess = !orderParams.subAccountId.isLong();
            if (isLess) {
                require(tradingPrice <= orderParams.price, "LMT"); // LiMiTed by limitPrice
            } else {
                require(tradingPrice >= orderParams.price, "LMT"); // LiMiTed by limitPrice
            }
        }
        // is the position completely closed
        (uint96 collateral, uint96 size, , , ) = IDegenPool(orderBook.pool).getSubAccount(orderParams.subAccountId);
        if (size == 0) {
            // auto withdraw
            if (collateral > 0) {
                IDegenPool(orderBook.pool).withdrawAllCollateral(orderParams.subAccountId);
            }
            // cancel activated tp/sl orders
            cancelActivatedTpslOrders(orderBook, orderParams.subAccountId);
        }
        emit FillAdlOrder(orderParams.subAccountId.owner(), orderParams);
        return tradingPrice;
    }

    function _placeTpslOrders(
        OrderBookStorage storage orderBook,
        PositionOrderParams memory orderParams,
        uint32 blockTimestamp
    ) private {
        if (orderParams.tpPrice > 0 || orderParams.slPrice > 0) {
            _validateAssets(orderBook, orderParams.tpslProfitTokenId, ASSET_IS_STABLE | ASSET_IS_ENABLED, 0);
        }
        if (orderParams.tpPrice > 0) {
            uint8 flags = LibOrder.POSITION_WITHDRAW_ALL_IF_EMPTY;
            uint8 assetId = orderParams.subAccountId.assetId();
            uint32 minProfitTime = IDegenPool(orderBook.pool)
                .getAssetParameter(assetId, LibConfigKeys.MIN_PROFIT_TIME)
                .toUint32();
            if (minProfitTime > 0) {
                flags |= LibOrder.POSITION_SHOULD_REACH_MIN_PROFIT;
            }
            uint64 orderId = _placePositionOrder(
                orderBook,
                PositionOrderParams({
                    subAccountId: orderParams.subAccountId,
                    collateral: 0, // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
                    size: orderParams.size,
                    price: orderParams.tpPrice,
                    tpPrice: 0,
                    slPrice: 0,
                    expiration: orderParams.tpslExpiration,
                    tpslExpiration: 0,
                    profitTokenId: orderParams.tpslProfitTokenId,
                    tpslProfitTokenId: 0,
                    flags: flags
                }),
                blockTimestamp
            );
            orderBook.tpslOrders[orderParams.subAccountId].add(uint256(orderId));
            require(orderBook.tpslOrders[orderParams.subAccountId].length() <= MAX_TP_SL_ORDERS, "TMO"); // Too Many TP/SL Orders
        }
        if (orderParams.slPrice > 0) {
            uint64 orderId = _placePositionOrder(
                orderBook,
                PositionOrderParams({
                    subAccountId: orderParams.subAccountId,
                    collateral: 0, // tp/sl strategy only supports POSITION_WITHDRAW_ALL_IF_EMPTY
                    size: orderParams.size,
                    price: orderParams.slPrice,
                    tpPrice: 0,
                    slPrice: 0,
                    expiration: orderParams.tpslExpiration,
                    tpslExpiration: 0,
                    profitTokenId: orderParams.tpslProfitTokenId,
                    tpslProfitTokenId: 0,
                    flags: LibOrder.POSITION_WITHDRAW_ALL_IF_EMPTY | LibOrder.POSITION_TRIGGER_ORDER
                }),
                blockTimestamp
            );
            orderBook.tpslOrders[orderParams.subAccountId].add(uint256(orderId));
            require(orderBook.tpslOrders[orderParams.subAccountId].length() <= MAX_TP_SL_ORDERS, "TMO"); // Too Many TP/SL Orders
        }
    }

    function _placePositionOrder(
        OrderBookStorage storage orderBook,
        PositionOrderParams memory orderParams, // NOTE: id, placeOrderTime, expire10s will be ignored
        uint32 blockTimestamp
    ) private returns (uint64 newOrderId) {
        newOrderId = orderBook.nextOrderId++;
        OrderData memory orderData = orderParams.encodePositionOrder(newOrderId, blockTimestamp);
        appendOrder(orderBook, orderData);
        emit NewPositionOrder(orderParams.subAccountId.owner(), newOrderId, orderParams);
    }

    function _hasPassMinProfit(
        OrderBookStorage storage orderBook,
        PositionOrderParams memory orderParams,
        SubAccount memory oldSubAccount,
        uint32 blockTimestamp,
        uint96 tradingPrice
    ) private view returns (bool) {
        if (oldSubAccount.size == 0) {
            return true;
        }
        require(tradingPrice > 0, "P=0"); // Price Is Zero
        bool hasProfit = orderParams.subAccountId.isLong()
            ? tradingPrice > oldSubAccount.entryPrice
            : tradingPrice < oldSubAccount.entryPrice;
        if (!hasProfit) {
            return true;
        }
        uint8 assetId = orderParams.subAccountId.assetId();
        uint32 minProfitTime = IDegenPool(orderBook.pool)
            .getAssetParameter(assetId, LibConfigKeys.MIN_PROFIT_TIME)
            .toUint32();
        uint32 minProfitRate = IDegenPool(orderBook.pool)
            .getAssetParameter(assetId, LibConfigKeys.MIN_PROFIT_RATE)
            .toUint32();
        if (blockTimestamp >= oldSubAccount.lastIncreasedTime + minProfitTime) {
            return true;
        }
        uint96 priceDelta = tradingPrice >= oldSubAccount.entryPrice
            ? tradingPrice - oldSubAccount.entryPrice
            : oldSubAccount.entryPrice - tradingPrice;
        if (priceDelta >= uint256(oldSubAccount.entryPrice).rmul(minProfitRate).toUint96()) {
            return true;
        }
        return false;
    }

    function _transferIn(
        // OrderBookStorage storage orderBook,
        address trader,
        address tokenAddress,
        address recipient,
        uint256 rawAmount
    ) internal {
        // commented: if tokenAddress == orderBook.wethToken
        require(msg.value == 0, "VAL"); // transaction VALue SHOULD be 0
        IERC20Upgradeable(tokenAddress).safeTransferFrom(trader, recipient, rawAmount);
    }

    function _transferOut(
        // OrderBookStorage storage orderBook,
        address tokenAddress,
        address recipient,
        uint256 rawAmount
    ) internal {
        // commented: if tokenAddress == orderBook.wethToken
        IERC20Upgradeable(tokenAddress).safeTransfer(recipient, rawAmount);
    }

    function _validateAssets(
        OrderBookStorage storage orderBook,
        uint8 assetId,
        uint56 includes,
        uint56 excludes
    ) internal view {
        uint56 flags = IDegenPool(orderBook.pool).getAssetFlags(assetId);
        require((flags & includes == includes) && (flags & excludes == 0), "FLG");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "../Types.sol";
/**
 * SubAccountId
 *         96             88        80       72        0
 * +---------+--------------+---------+--------+--------+
 * | Account | collateralId | assetId | isLong | unused |
 * +---------+--------------+---------+--------+--------+
 */

struct SubAccountId {
    address account;
    uint8 collateralId;
    uint8 assetId;
    bool isLong;
}

library LibSubAccount {
    bytes32 constant SUB_ACCOUNT_ID_FORBIDDEN_BITS = bytes32(uint256(0xffffffffffffffffff));

    function owner(bytes32 subAccountId) internal pure returns (address account) {
        account = address(uint160(uint256(subAccountId) >> 96));
    }

    function collateralId(bytes32 subAccountId) internal pure returns (uint8) {
        return uint8(uint256(subAccountId) >> 88);
    }

    function assetId(bytes32 subAccountId) internal pure returns (uint8) {
        return uint8(uint256(subAccountId) >> 80);
    }

    function isLong(bytes32 subAccountId) internal pure returns (bool) {
        return uint8((uint256(subAccountId) >> 72)) > 0;
    }

    function decode(bytes32 subAccountId) internal pure returns (SubAccountId memory decoded) {
        require((subAccountId & SUB_ACCOUNT_ID_FORBIDDEN_BITS) == 0, "AID"); // bad subAccount ID
        decoded.account = address(uint160(uint256(subAccountId) >> 96));
        decoded.collateralId = uint8(uint256(subAccountId) >> 88);
        decoded.assetId = uint8(uint256(subAccountId) >> 80);
        decoded.isLong = uint8((uint256(subAccountId) >> 72)) > 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

library LibTypeCast {
    bytes32 private constant ADDRESS_GUARD_MASK = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;

    function isAddress(bytes32 v) internal pure returns (bool) {
        return v & ADDRESS_GUARD_MASK == 0;
    }

    function toAddress(bytes32 v) internal pure returns (address) {
        require(v & ADDRESS_GUARD_MASK == 0, "ADR"); // invalid ADdRess
        return address(uint160(uint256(v)));
    }

    function toBytes32(address v) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(v)));
    }

    function toUint32(bytes32 v) internal pure returns (uint32) {
        return toUint32(uint256(v));
    }

    function toUint56(bytes32 v) internal pure returns (uint56) {
        return toUint56(uint256(v));
    }

    function toUint96(bytes32 v) internal pure returns (uint96) {
        return toUint96(uint256(v));
    }

    function toUint256(bytes32 v) internal pure returns (uint256) {
        return uint256(v);
    }

    function toBytes32(uint256 v) internal pure returns (bytes32) {
        return bytes32(v);
    }

    function toBoolean(bytes32 v) internal pure returns (bool) {
        uint256 n = toUint256(v);
        require(n == 0 || n == 1, "O1");
        return n == 1;
    }

    function toBytes32(bool v) internal pure returns (bytes32) {
        return toBytes32(v ? 1 : 0);
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, "O32");
        return uint32(n);
    }

    function toUint56(uint256 n) internal pure returns (uint56) {
        require(n <= type(uint56).max, "O56");
        return uint56(n);
    }

    function toUint96(uint256 n) internal pure returns (uint96) {
        require(n <= type(uint96).max, "O96");
        return uint96(n);
    }

    function toUint128(uint256 n) internal pure returns (uint128) {
        require(n <= type(uint128).max, "O12");
        return uint128(n);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../libraries/LibTypeCast.sol";
import "../libraries/LibConfigKeys.sol";
import "./Types.sol";

contract Storage is Initializable, AccessControlEnumerableUpgradeable {
    using LibTypeCast for bytes32;

    OrderBookStorage internal _storage;
    bytes32[50] __gap;

    // seconds 1e0
    function _liquidityLockPeriod() internal view returns (uint32) {
        return _storage.parameters[LibConfigKeys.OB_LIQUIDITY_LOCK_PERIOD].toUint32();
    }

    function _marketOrderTimeout() internal view returns (uint32) {
        return _storage.parameters[LibConfigKeys.OB_MARKET_ORDER_TIMEOUT].toUint32();
    }

    function _maxLimitOrderTimeout() internal view returns (uint32) {
        return _storage.parameters[LibConfigKeys.OB_LIMIT_ORDER_TIMEOUT].toUint32();
    }

    function _referralManager() internal view returns (address) {
        return _storage.parameters[LibConfigKeys.OB_REFERRAL_MANAGER].toAddress();
    }

    function _callbackGasLimit() internal view returns (uint256) {
        return _storage.parameters[LibConfigKeys.OB_CALLBACK_GAS_LIMIT].toUint256();
    }

    function _cancelCoolDown() internal view returns (uint32) {
        return _storage.parameters[LibConfigKeys.OB_CANCEL_COOL_DOWN].toUint32();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../interfaces/IDegenPool.sol";
import "../libraries/LibOrder.sol";

enum OrderType {
    None, // 0
    PositionOrder, // 1
    LiquidityOrder, // 2
    WithdrawalOrder // 3
}

bytes32 constant BROKER_ROLE = keccak256("BROKER_ROLE");
bytes32 constant CALLBACKER_ROLE = keccak256("CALLBACKER_ROLE");
bytes32 constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

struct OrderData {
    address account;
    uint64 id;
    OrderType orderType;
    uint8 version;
    uint32 placeOrderTime;
    bytes payload;
}

struct OrderBookStorage {
    address mlpToken;
    address pool;
    uint64 nextOrderId;
    mapping(OrderType => bool) isPaused;
    mapping(bytes32 => bytes32) parameters;
    // orders
    bytes32 _reserved1;
    bytes32 _reserved2;
    bytes32 _reserved3;
    bytes32 _reserved4;
    mapping(uint64 => OrderData) orderData;
    EnumerableSetUpgradeable.UintSet orders;
    mapping(bytes32 => EnumerableSetUpgradeable.UintSet) tpslOrders;
    mapping(address => EnumerableSetUpgradeable.UintSet) userOrders;
}

struct PositionOrderParams {
    bytes32 subAccountId; // 160 + 8 + 8 + 8 = 184
    uint96 collateral; // erc20.decimals
    uint96 size; // 1e18
    uint96 price; // 1e18
    uint96 tpPrice; // take-profit price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
    uint96 slPrice; // stop-loss price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
    uint32 expiration; // 1e0 seconds
    uint32 tpslExpiration; // 1e0 seconds
    uint8 profitTokenId;
    uint8 tpslProfitTokenId; // only valid when flags.POSITION_TPSL_STRATEGY.
    uint8 flags;
}

struct LiquidityOrderParams {
    uint96 rawAmount; // erc20.decimals
    uint8 assetId;
    bool isAdding;
}

struct WithdrawalOrderParams {
    bytes32 subAccountId; // 160 + 8 + 8 + 8 = 184
    uint96 rawAmount; // erc20.decimals
    uint8 profitTokenId;
    bool isProfit;
}

struct AdlOrderParams {
    bytes32 subAccountId; // 160 + 8 + 8 + 8 = 184
    uint96 size; // 1e18
    uint96 price; // 1e18
    uint8 profitTokenId;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

// funding period
uint32 constant APY_PERIOD = 86400 * 365;

// flags
uint56 constant ASSET_IS_STABLE = 0x00000000000001; // is a usdt, usdc, ...
uint56 constant ASSET_CAN_ADD_REMOVE_LIQUIDITY = 0x00000000000002; // can call addLiquidity and removeLiquidity with this token
uint56 constant ASSET_IS_TRADABLE = 0x00000000000100; // allowed to be assetId
uint56 constant ASSET_IS_OPENABLE = 0x00000000010000; // can open position
uint56 constant ASSET_IS_SHORTABLE = 0x00000001000000; // allow shorting this asset
uint56 constant ASSET_IS_ENABLED = 0x00010000000000; // allowed to be assetId and collateralId
uint56 constant ASSET_IS_STRICT_STABLE = 0x01000000000000; // assetPrice is always 1 unless volatility exceeds strictStableDeviation

enum ReferenceOracleType {
    None,
    Chainlink
}

struct PoolStorage {
    // configs
    mapping(uint256 => Asset) assets;
    mapping(bytes32 => SubAccount) accounts;
    mapping(address => bool) maintainers;
    mapping(bytes32 => bytes32) parameters;
    // status
    mapping(address => EnumerableSetUpgradeable.Bytes32Set) userSubAccountIds;
    EnumerableSetUpgradeable.Bytes32Set isMaintenanceParameters;
    uint8 assetsCount;
    uint32 sequence;
    uint32 lastFundingTime;
    uint32 brokerTransactions;
    EnumerableSetUpgradeable.Bytes32Set subAccountIds;
    bytes32[20] __gaps;
}

struct Asset {
    // configs
    uint8 id;
    mapping(bytes32 => bytes32) parameters;
    EnumerableSetUpgradeable.Bytes32Set isMaintenanceParameters;
    // status
    uint56 flags;
    uint96 spotLiquidity;
    uint96 __deleted0;
    uint96 totalLongPosition;
    uint96 averageLongPrice;
    uint96 totalShortPosition;
    uint96 averageShortPrice;
    uint128 longCumulativeFunding; // Σ_t fundingRate_t + borrowingRate_t. 1e18. payment = (cumulative - entry) * positionSize * entryPrice
    uint128 shortCumulativeFunding; // Σ_t fundingRate_t + borrowingRate_t. 1e18. payment = (cumulative - entry) * positionSize * entryPrice
}

struct SubAccount {
    uint96 collateral;
    uint96 size;
    uint32 lastIncreasedTime;
    uint96 entryPrice;
    uint128 entryFunding; // entry longCumulativeFunding for long position. entry shortCumulativeFunding for short position
}