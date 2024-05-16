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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import {Initializable} from "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import {Initializable} from "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.9.6) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64Upgradeable {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 0x20)
            let dataPtr := data
            let endPtr := add(data, mload(data))

            // In some cases, the last iteration will read bytes after the end of the data. We cache the value, and
            // set it to zero to make sure no dirty bytes are read in that section.
            let afterPtr := add(endPtr, 0x20)
            let afterCache := mload(afterPtr)
            mstore(afterPtr, 0x00)

            // Run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 byte (24 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F to bitmask the least significant 6 bits.
                // Use this as an index into the lookup table, mload an entire word
                // so the desired character is in the least significant byte, and
                // mstore8 this least significant byte into the result and continue.

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // Reset the value that was cached
            mstore(afterPtr, afterCache)

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./Xai.sol";

/**
 * @title esXai
 * @dev Implementation of the esXai
 */
contract esXai is ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _whitelist;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public xai;
    bool private _redemptionActive;
    mapping(address => RedemptionRequest[]) private _redemptionRequests;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[500] private __gap;


    struct RedemptionRequest {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        bool completed;
    }

    event WhitelistUpdated(address account, bool isAdded);
    event RedemptionStarted(address indexed user, uint256 indexed index);
    event RedemptionCancelled(address indexed user, uint256 indexed index);
    event RedemptionCompleted(address indexed user, uint256 indexed index);
    event RedemptionStatusChanged(bool isActive);
    event XaiAddressChanged(address indexed newXaiAddress);

    function initialize (address _xai) public initializer {
        __ERC20_init("esXai", "esXAI");
        __ERC20Burnable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        xai = _xai;
        _redemptionActive = false;
    }

    /**
     * @dev Function to change the redemption status
     * @param isActive The new redemption status.
     */
    function changeRedemptionStatus(bool isActive) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _redemptionActive = isActive;
        emit RedemptionStatusChanged(isActive);
    }

    /**
     * @dev Function to mint esXai tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Function to change the Xai contract address
     * @param _newXai The new Xai contract address.
     */
    function changeXaiAddress(address _newXai) public onlyRole(DEFAULT_ADMIN_ROLE) {
        xai = _newXai;
        emit XaiAddressChanged(_newXai); // Emit event when xai address is changed
    }

    /**
     * @dev Function to add an address to the whitelist
     * @param account The address to add to the whitelist.
     */
    function addToWhitelist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelist.add(account);
        emit WhitelistUpdated(account, true);
    }

    /**
     * @dev Function to remove an address from the whitelist
     * @param account The address to remove from the whitelist.
     */
    function removeFromWhitelist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelist.remove(account);
        emit WhitelistUpdated(account, false);
    }

    /**
     * @dev Function to check if an address is in the whitelist
     * @param account The address to check.
     * @return A boolean indicating if the address is in the whitelist.
     */
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist.contains(account);
    }

    /**
     * @dev Function to get the whitelisted address at a given index.
     * @param index The index of the address to query.
     * @return The address of the whitelisted account.
     */
    function getWhitelistedAddressAtIndex(uint256 index) public view returns (address) {
        require(index < getWhitelistCount(), "Index out of bounds");
        return _whitelist.at(index);
    }

    /**
     * @dev Function to get the count of whitelisted addresses.
     * @return The count of whitelisted addresses.
     */
    function getWhitelistCount() public view returns (uint256) {
        return _whitelist.length();
    }

    /**
     * @dev Override the transfer function to only allow addresses that are in the white list in the to or from field to go through
     * @param to The address to transfer to.
     * @param amount The amount to transfer.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(_whitelist.contains(msg.sender) || _whitelist.contains(to), "Transfer not allowed: address not in whitelist");
        return super.transfer(to, amount);
    }

    /**
     * @dev Override the transferFrom function to only allow addresses that are in the white list in the to or from field to go through
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param amount The amount to transfer.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(_whitelist.contains(from) || _whitelist.contains(to), "Transfer not allowed: address not in whitelist");
        return super.transferFrom(from, to, amount);
    }

    /**
     * @dev Function to start the redemption process
     * @param amount The amount of esXai to redeem.
     * @param duration The duration of the redemption process in seconds.
     */
    function startRedemption(uint256 amount, uint256 duration) public {
        require(_redemptionActive, "Redemption is currently inactive");
        require(balanceOf(msg.sender) >= amount, "Insufficient esXai balance");
        require(duration == 15 days || duration == 90 days || duration == 180 days, "Invalid duration");

        // Transfer the esXai tokens from the sender's account to this contract
        _transfer(msg.sender, address(this), amount);

        // Store the redemption request
        _redemptionRequests[msg.sender].push(RedemptionRequest(amount, block.timestamp, duration, false));
        emit RedemptionStarted(msg.sender, _redemptionRequests[msg.sender].length - 1);
    }

    /**
     * @dev Function to cancel the redemption process
     * @param index The index of the redemption request to cancel.
     */
    function cancelRedemption(uint256 index) public {
        require(_redemptionActive, "Redemption is currently inactive");
        RedemptionRequest storage request = _redemptionRequests[msg.sender][index];
        require(!request.completed, "Redemption already completed");

        // Transfer back the esXai tokens to the sender's account
        _transfer(address(this), msg.sender, request.amount);

        // Mark the redemption request as completed
        request.completed = true;
        emit RedemptionCancelled(msg.sender, index);
    }

    /**
     * @dev Function to complete the redemption process
     * @param index The index of the redemption request to complete.
     */
    function completeRedemption(uint256 index) public {
        require(_redemptionActive, "Redemption is currently inactive");
        RedemptionRequest storage request = _redemptionRequests[msg.sender][index];
        require(!request.completed, "Redemption already completed");
        require(block.timestamp >= request.startTime + request.duration, "Redemption period not yet over");

        // Calculate the conversion ratio based on the duration
        uint256 ratio;
        if (request.duration == 15 days) {
            ratio = 250;
        } else if (request.duration == 90 days) {
            ratio = 625;
        } else {
            ratio = 1000;
        }

        // Calculate the amount of Xai to mint
        uint256 xaiAmount = request.amount * ratio / 1000;

        // Burn the esXai tokens
        _burn(address(this), request.amount);

        // Mint the Xai tokens
        Xai(xai).mint(msg.sender, xaiAmount);

        // Mark the redemption request as completed
        request.completed = true;
        emit RedemptionCompleted(msg.sender, index);
    }

    /**
     * @dev Function to get the redemption request at a given index.
     * @param account The address to query.
     * @param index The index of the redemption request.
     * @return The redemption request.
     */
    function getRedemptionRequest(address account, uint256 index) public view returns (RedemptionRequest memory) {
        return _redemptionRequests[account][index];
    }

    /**
     * @dev Function to get the count of redemption requests for a given address.
     * @param account The address to query.
     * @return The count of redemption requests.
     */
    function getRedemptionRequestCount(address account) public view returns (uint256) {
        return _redemptionRequests[account].length;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IOwnable.sol";

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash,
        uint256 baseFeeL1,
        uint64 timestamp
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed to,
        uint256 value,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    event SequencerInboxUpdated(address newSequencerInbox);

    function allowedDelayedInboxList(uint256) external returns (address);

    function allowedOutboxList(uint256) external returns (address);

    /// @dev Accumulator for delayed inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function delayedInboxAccs(uint256) external view returns (bytes32);

    /// @dev Accumulator for sequencer inbox messages; tail represents hash of the current state; each element represents the inclusion of a new message.
    function sequencerInboxAccs(uint256) external view returns (bytes32);

    function rollup() external view returns (IOwnable);

    function sequencerInbox() external view returns (address);

    function activeOutbox() external view returns (address);

    function allowedDelayedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function sequencerReportedSubMessageCount() external view returns (uint256);

    /**
     * @dev Enqueue a message in the delayed inbox accumulator.
     *      These messages are later sequenced in the SequencerInbox, either
     *      by the sequencer as part of a normal batch, or by force inclusion.
     */
    function enqueueDelayedMessage(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    function delayedMessageCount() external view returns (uint256);

    function sequencerMessageCount() external view returns (uint256);

    // ---------- onlySequencerInbox functions ----------

    function enqueueSequencerMessage(
        bytes32 dataHash,
        uint256 afterDelayedMessagesRead,
        uint256 prevMessageCount,
        uint256 newMessageCount
    )
        external
        returns (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 acc
        );

    /**
     * @dev Allows the sequencer inbox to submit a delayed message of the batchPostingReport type
     *      This is done through a separate function entrypoint instead of allowing the sequencer inbox
     *      to call `enqueueDelayedMessage` to avoid the gas overhead of an extra SLOAD in either
     *      every delayed inbox or every sequencer inbox call.
     */
    function submitBatchSpendingReport(address batchPoster, bytes32 dataHash)
        external
        returns (uint256 msgNum);

    // ---------- onlyRollupOrOwner functions ----------

    function setSequencerInbox(address _sequencerInbox) external;

    function setDelayedInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // ---------- initializer ----------

    function initialize(IOwnable rollup_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IDelayedMessageProvider {
    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    /// same as InboxMessageDelivered but the batch data is available in tx.input
    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";
import "./IDelayedMessageProvider.sol";
import "./ISequencerInbox.sol";

interface IInbox is IDelayedMessageProvider {
    function bridge() external view returns (IBridge);

    function sequencerInbox() external view returns (ISequencerInbox);

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method is an optimization to avoid having to emit the entirety of the messageData in a log. Instead validators are expected to be able to parse the data from the transaction's input
     *      This method will be disabled upon L1 fork to prevent replay attacks on L2
     * @param messageData Data of the message being sent
     */
    function sendL2MessageFromOrigin(bytes calldata messageData) external returns (uint256);

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method can be used to send any type of message that doesn't require L1 validation
     *      This method will be disabled upon L1 fork to prevent replay attacks on L2
     * @param messageData Data of the message being sent
     */
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    function sendUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendL1FundedUnsignedTransactionToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendUnsignedTransactionToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @notice Send a message to initiate L2 withdrawal
     * @dev This method can only be called upon L1 fork and will not alias the caller
     *      This method will revert if not called from origin
     */
    function sendWithdrawEthToFork(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        uint256 value,
        address withdrawTo
    ) external returns (uint256);

    /**
     * @notice Get the L1 fee for submitting a retryable
     * @dev This fee can be paid by funds already in the L2 aliased address or by the current message value
     * @dev This formula may change in the future, to future proof your code query this method instead of inlining!!
     * @param dataLength The length of the retryable's calldata, in bytes
     * @param baseFee The block basefee when the retryable is included in the chain, if 0 current block.basefee will be used
     */
    function calculateRetryableSubmissionFee(uint256 dataLength, uint256 baseFee)
        external
        view
        returns (uint256);

    /**
     * @notice Deposit eth from L1 to L2 to address of the sender if sender is an EOA, and to its aliased address if the sender is a contract
     * @dev This does not trigger the fallback function when receiving in the L2 side.
     *      Look into retryable tickets if you are interested in this functionality.
     * @dev This function should not be called inside contract constructors
     */
    function depositEth() external payable returns (uint256);

    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev all msg.value will deposited to callValueRefundAddress on L2
     * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
     * @param to destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev Same as createRetryableTicket, but does not guarantee that submission will succeed by requiring the needed funds
     * come from the deposit alone, rather than falling back on the user's L2 balance
     * @dev Advanced usage only (does not rewrite aliases for excessFeeRefundAddress and callValueRefundAddress).
     * createRetryableTicket method is the recommended standard.
     * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
     * @param to destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function unsafeCreateRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    // ---------- onlyRollupOrOwner functions ----------

    /// @notice pauses all inbox functionality
    function pause() external;

    /// @notice unpauses all inbox functionality
    function unpause() external;

    // ---------- initializer ----------

    /**
     * @dev function to be called one time during the inbox upgrade process
     *      this is used to fix the storage slots
     */
    function postUpgradeInit(IBridge _bridge) external;

    function initialize(IBridge _bridge, ISequencerInbox _sequencerInbox) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";

interface IOutbox {
    event SendRootUpdated(bytes32 indexed outputRoot, bytes32 indexed l2BlockHash);
    event OutBoxTransactionExecuted(
        address indexed to,
        address indexed l2Sender,
        uint256 indexed zero,
        uint256 transactionIndex
    );

    function rollup() external view returns (address); // the rollup contract

    function bridge() external view returns (IBridge); // the bridge contract

    function spent(uint256) external view returns (bytes32); // packed spent bitmap

    function roots(bytes32) external view returns (bytes32); // maps root hashes => L2 block hash

    // solhint-disable-next-line func-name-mixedcase
    function OUTBOX_VERSION() external view returns (uint128); // the outbox version

    function updateSendRoot(bytes32 sendRoot, bytes32 l2BlockHash) external;

    /// @notice When l2ToL1Sender returns a nonzero address, the message was originated by an L2 account
    ///         When the return value is zero, that means this is a system message
    /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
    function l2ToL1Sender() external view returns (address);

    /// @return l2Block return L2 block when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1Block() external view returns (uint256);

    /// @return l1Block return L1 block when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1EthBlock() external view returns (uint256);

    /// @return timestamp return L2 timestamp when the L2 tx was initiated or 0 if no L2 to L1 transaction is active
    function l2ToL1Timestamp() external view returns (uint256);

    /// @return outputId returns the unique output identifier of the L2 to L1 tx or 0 if no L2 to L1 transaction is active
    function l2ToL1OutputId() external view returns (bytes32);

    /**
     * @notice Executes a messages in an Outbox entry.
     * @dev Reverts if dispute period hasn't expired, since the outbox entry
     *      is only created once the rollup confirms the respective assertion.
     * @dev it is not possible to execute any L2-to-L1 transaction which contains data
     *      to a contract address without any code (as enforced by the Bridge contract).
     * @param proof Merkle proof of message inclusion in send root
     * @param index Merkle path to message
     * @param l2Sender sender if original message (i.e., caller of ArbSys.sendTxToL1)
     * @param to destination address for L1 contract call
     * @param l2Block l2 block number at which sendTxToL1 call was made
     * @param l1Block l1 block number at which sendTxToL1 call was made
     * @param l2Timestamp l2 Timestamp at which sendTxToL1 call was made
     * @param value wei in L1 message
     * @param data abi-encoded L1 message data
     */
    function executeTransaction(
        bytes32[] calldata proof,
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     *  @dev function used to simulate the result of a particular function call from the outbox
     *       it is useful for things such as gas estimates. This function includes all costs except for
     *       proof validation (which can be considered offchain as a somewhat of a fixed cost - it's
     *       not really a fixed cost, but can be treated as so with a fixed overhead for gas estimation).
     *       We can't include the cost of proof validation since this is intended to be used to simulate txs
     *       that are included in yet-to-be confirmed merkle roots. The simulation entrypoint could instead pretend
     *       to confirm a pending merkle root, but that would be less practical for integrating with tooling.
     *       It is only possible to trigger it when the msg sender is address zero, which should be impossible
     *       unless under simulation in an eth_call or eth_estimateGas
     */
    function executeTransactionSimulation(
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * @param index Merkle path to message
     * @return true if the message has been spent
     */
    function isSpent(uint256 index) external view returns (bool);

    function calculateItemHash(
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes32);

    function calculateMerkleRoot(
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) external pure returns (bytes32);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.21 <0.9.0;

interface IOwnable {
    function owner() external view returns (address);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libraries/IGasRefunder.sol";
import "./IDelayedMessageProvider.sol";
import "./IBridge.sol";

interface ISequencerInbox is IDelayedMessageProvider {
    struct MaxTimeVariation {
        uint256 delayBlocks;
        uint256 futureBlocks;
        uint256 delaySeconds;
        uint256 futureSeconds;
    }

    struct TimeBounds {
        uint64 minTimestamp;
        uint64 maxTimestamp;
        uint64 minBlockNumber;
        uint64 maxBlockNumber;
    }

    enum BatchDataLocation {
        TxInput,
        SeparateBatchEvent,
        NoData
    }

    event SequencerBatchDelivered(
        uint256 indexed batchSequenceNumber,
        bytes32 indexed beforeAcc,
        bytes32 indexed afterAcc,
        bytes32 delayedAcc,
        uint256 afterDelayedMessagesRead,
        TimeBounds timeBounds,
        BatchDataLocation dataLocation
    );

    event OwnerFunctionCalled(uint256 indexed id);

    /// @dev a separate event that emits batch data when this isn't easily accessible in the tx.input
    event SequencerBatchData(uint256 indexed batchSequenceNumber, bytes data);

    /// @dev a valid keyset was added
    event SetValidKeyset(bytes32 indexed keysetHash, bytes keysetBytes);

    /// @dev a keyset was invalidated
    event InvalidateKeyset(bytes32 indexed keysetHash);

    function totalDelayedMessagesRead() external view returns (uint256);

    function bridge() external view returns (IBridge);

    /// @dev The size of the batch header
    // solhint-disable-next-line func-name-mixedcase
    function HEADER_LENGTH() external view returns (uint256);

    /// @dev If the first batch data byte after the header has this bit set,
    ///      the sequencer inbox has authenticated the data. Currently not used.
    // solhint-disable-next-line func-name-mixedcase
    function DATA_AUTHENTICATED_FLAG() external view returns (bytes1);

    function rollup() external view returns (IOwnable);

    function isBatchPoster(address) external view returns (bool);

    function isSequencer(address) external view returns (bool);

    struct DasKeySetInfo {
        bool isValidKeyset;
        uint64 creationBlock;
    }

    function maxTimeVariation()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dasKeySetInfo(bytes32) external view returns (bool, uint64);

    /// @notice Remove force inclusion delay after a L1 chainId fork
    function removeDelayAfterFork() external;

    /// @notice Force messages from the delayed inbox to be included in the chain
    ///         Callable by any address, but message can only be force-included after maxTimeVariation.delayBlocks and
    ///         maxTimeVariation.delaySeconds has elapsed. As part of normal behaviour the sequencer will include these
    ///         messages so it's only necessary to call this if the sequencer is down, or not including any delayed messages.
    /// @param _totalDelayedMessagesRead The total number of messages to read up to
    /// @param kind The kind of the last message to be included
    /// @param l1BlockAndTime The l1 block and the l1 timestamp of the last message to be included
    /// @param baseFeeL1 The l1 gas price of the last message to be included
    /// @param sender The sender of the last message to be included
    /// @param messageDataHash The messageDataHash of the last message to be included
    function forceInclusion(
        uint256 _totalDelayedMessagesRead,
        uint8 kind,
        uint64[2] calldata l1BlockAndTime,
        uint256 baseFeeL1,
        address sender,
        bytes32 messageDataHash
    ) external;

    function inboxAccs(uint256 index) external view returns (bytes32);

    function batchCount() external view returns (uint256);

    function isValidKeysetHash(bytes32 ksHash) external view returns (bool);

    /// @notice the creation block is intended to still be available after a keyset is deleted
    function getKeysetCreationBlock(bytes32 ksHash) external view returns (uint256);

    // ---------- BatchPoster functions ----------

    function addSequencerL2BatchFromOrigin(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder
    ) external;

    function addSequencerL2Batch(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder,
        uint256 prevMessageCount,
        uint256 newMessageCount
    ) external;

    // ---------- onlyRollupOrOwner functions ----------

    /**
     * @notice Set max delay for sequencer inbox
     * @param maxTimeVariation_ the maximum time variation parameters
     */
    function setMaxTimeVariation(MaxTimeVariation memory maxTimeVariation_) external;

    /**
     * @notice Updates whether an address is authorized to be a batch poster at the sequencer inbox
     * @param addr the address
     * @param isBatchPoster_ if the specified address should be authorized as a batch poster
     */
    function setIsBatchPoster(address addr, bool isBatchPoster_) external;

    /**
     * @notice Makes Data Availability Service keyset valid
     * @param keysetBytes bytes of the serialized keyset
     */
    function setValidKeyset(bytes calldata keysetBytes) external;

    /**
     * @notice Invalidates a Data Availability Service keyset
     * @param ksHash hash of the keyset
     */
    function invalidateKeysetHash(bytes32 ksHash) external;

    /**
     * @notice Updates whether an address is authorized to be a sequencer.
     * @dev The IsSequencer information is used only off-chain by the nitro node to validate sequencer feed signer.
     * @param addr the address
     * @param isSequencer_ if the specified address should be authorized as a sequencer
     */
    function setIsSequencer(address addr, bool isSequencer_) external;

    // ---------- initializer ----------

    function initialize(IBridge bridge_, MaxTimeVariation calldata maxTimeVariation_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Machine.sol";
import "../state/GlobalState.sol";

library ChallengeLib {
    using MachineLib for Machine;
    using ChallengeLib for Challenge;

    /// @dev It's assumed that that uninitialzed challenges have mode NONE
    enum ChallengeMode {
        NONE,
        BLOCK,
        EXECUTION
    }

    struct Participant {
        address addr;
        uint256 timeLeft;
    }

    struct Challenge {
        Participant current;
        Participant next;
        uint256 lastMoveTimestamp;
        bytes32 wasmModuleRoot;
        bytes32 challengeStateHash;
        uint64 maxInboxMessages;
        ChallengeMode mode;
    }

    struct SegmentSelection {
        uint256 oldSegmentsStart;
        uint256 oldSegmentsLength;
        bytes32[] oldSegments;
        uint256 challengePosition;
    }

    function timeUsedSinceLastMove(Challenge storage challenge) internal view returns (uint256) {
        return block.timestamp - challenge.lastMoveTimestamp;
    }

    function isTimedOut(Challenge storage challenge) internal view returns (bool) {
        return challenge.timeUsedSinceLastMove() > challenge.current.timeLeft;
    }

    function getStartMachineHash(bytes32 globalStateHash, bytes32 wasmModuleRoot)
        internal
        pure
        returns (bytes32)
    {
        // Start the value stack with the function call ABI for the entrypoint
        Value[] memory startingValues = new Value[](3);
        startingValues[0] = ValueLib.newRefNull();
        startingValues[1] = ValueLib.newI32(0);
        startingValues[2] = ValueLib.newI32(0);
        ValueArray memory valuesArray = ValueArray({inner: startingValues});
        ValueStack memory values = ValueStack({proved: valuesArray, remainingHash: 0});
        ValueStack memory internalStack;
        StackFrameWindow memory frameStack;

        Machine memory mach = Machine({
            status: MachineStatus.RUNNING,
            valueStack: values,
            internalStack: internalStack,
            frameStack: frameStack,
            globalStateHash: globalStateHash,
            moduleIdx: 0,
            functionIdx: 0,
            functionPc: 0,
            modulesRoot: wasmModuleRoot
        });
        return mach.hash();
    }

    function getEndMachineHash(MachineStatus status, bytes32 globalStateHash)
        internal
        pure
        returns (bytes32)
    {
        if (status == MachineStatus.FINISHED) {
            return keccak256(abi.encodePacked("Machine finished:", globalStateHash));
        } else if (status == MachineStatus.ERRORED) {
            return keccak256(abi.encodePacked("Machine errored:"));
        } else if (status == MachineStatus.TOO_FAR) {
            return keccak256(abi.encodePacked("Machine too far:"));
        } else {
            revert("BAD_BLOCK_STATUS");
        }
    }

    function extractChallengeSegment(SegmentSelection calldata selection)
        internal
        pure
        returns (uint256 segmentStart, uint256 segmentLength)
    {
        uint256 oldChallengeDegree = selection.oldSegments.length - 1;
        segmentLength = selection.oldSegmentsLength / oldChallengeDegree;
        // Intentionally done before challengeLength is potentially added to for the final segment
        segmentStart = selection.oldSegmentsStart + segmentLength * selection.challengePosition;
        if (selection.challengePosition == selection.oldSegments.length - 2) {
            segmentLength += selection.oldSegmentsLength % oldChallengeDegree;
        }
    }

    function hashChallengeState(
        uint256 segmentsStart,
        uint256 segmentsLength,
        bytes32[] memory segments
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(segmentsStart, segmentsLength, segments));
    }

    function blockStateHash(MachineStatus status, bytes32 globalStateHash)
        internal
        pure
        returns (bytes32)
    {
        if (status == MachineStatus.FINISHED) {
            return keccak256(abi.encodePacked("Block state:", globalStateHash));
        } else if (status == MachineStatus.ERRORED) {
            return keccak256(abi.encodePacked("Block state, errored:", globalStateHash));
        } else if (status == MachineStatus.TOO_FAR) {
            return keccak256(abi.encodePacked("Block state, too far:"));
        } else {
            revert("BAD_BLOCK_STATUS");
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Machine.sol";
import "../bridge/IBridge.sol";
import "../bridge/ISequencerInbox.sol";
import "../osp/IOneStepProofEntry.sol";

import "./IChallengeResultReceiver.sol";

import "./ChallengeLib.sol";

interface IChallengeManager {
    enum ChallengeTerminationType {
        TIMEOUT,
        BLOCK_PROOF,
        EXECUTION_PROOF,
        CLEARED
    }

    event InitiatedChallenge(
        uint64 indexed challengeIndex,
        GlobalState startState,
        GlobalState endState
    );

    event Bisected(
        uint64 indexed challengeIndex,
        bytes32 indexed challengeRoot,
        uint256 challengedSegmentStart,
        uint256 challengedSegmentLength,
        bytes32[] chainHashes
    );

    event ExecutionChallengeBegun(uint64 indexed challengeIndex, uint256 blockSteps);
    event OneStepProofCompleted(uint64 indexed challengeIndex);

    event ChallengeEnded(uint64 indexed challengeIndex, ChallengeTerminationType kind);

    function initialize(
        IChallengeResultReceiver resultReceiver_,
        ISequencerInbox sequencerInbox_,
        IBridge bridge_,
        IOneStepProofEntry osp_
    ) external;

    function createChallenge(
        bytes32 wasmModuleRoot_,
        MachineStatus[2] calldata startAndEndMachineStatuses_,
        GlobalState[2] calldata startAndEndGlobalStates_,
        uint64 numBlocks,
        address asserter_,
        address challenger_,
        uint256 asserterTimeLeft_,
        uint256 challengerTimeLeft_
    ) external returns (uint64);

    function challengeInfo(uint64 challengeIndex_)
        external
        view
        returns (ChallengeLib.Challenge memory);

    function currentResponder(uint64 challengeIndex) external view returns (address);

    function isTimedOut(uint64 challengeIndex) external view returns (bool);

    function clearChallenge(uint64 challengeIndex_) external;

    function timeout(uint64 challengeIndex_) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IChallengeResultReceiver {
    function completeChallenge(
        uint256 challengeIndex,
        address winner,
        address loser
    ) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IGasRefunder {
    function onGasSpent(
        address payable spender,
        uint256 gasUsed,
        uint256 calldataSize
    ) external returns (bool success);
}

abstract contract GasRefundEnabled {
    /// @dev this refunds the sender for execution costs of the tx
    /// calldata costs are only refunded if `msg.sender == tx.origin` to guarantee the value refunded relates to charging
    /// for the `tx.input`. this avoids a possible attack where you generate large calldata from a contract and get over-refunded
    modifier refundsGas(IGasRefunder gasRefunder) {
        uint256 startGasLeft = gasleft();
        _;
        if (address(gasRefunder) != address(0)) {
            uint256 calldataSize = msg.data.length;
            uint256 calldataWords = (calldataSize + 31) / 32;
            // account for the CALLDATACOPY cost of the proxy contract, including the memory expansion cost
            startGasLeft += calldataWords * 6 + (calldataWords**2) / 512;
            // if triggered in a contract call, the spender may be overrefunded by appending dummy data to the call
            // so we check if it is a top level call, which would mean the sender paid calldata as part of tx.input
            // solhint-disable-next-line avoid-tx-origin
            if (msg.sender != tx.origin) {
                // We can't be sure if this calldata came from the top level tx,
                // so to be safe we tell the gas refunder there was no calldata.
                calldataSize = 0;
            }
            gasRefunder.onGasSpent(payable(msg.sender), startGasLeft - gasleft(), calldataSize);
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IOneStepProver.sol";

library OneStepProofEntryLib {
    uint256 internal constant MAX_STEPS = 1 << 43;
}

interface IOneStepProofEntry {
    function proveOneStep(
        ExecutionContext calldata execCtx,
        uint256 machineStep,
        bytes32 beforeHash,
        bytes calldata proof
    ) external view returns (bytes32 afterHash);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Machine.sol";
import "../state/Module.sol";
import "../state/Instructions.sol";
import "../state/GlobalState.sol";
import "../bridge/ISequencerInbox.sol";
import "../bridge/IBridge.sol";

struct ExecutionContext {
    uint256 maxInboxMessagesRead;
    IBridge bridge;
}

abstract contract IOneStepProver {
    function executeOneStep(
        ExecutionContext memory execCtx,
        Machine calldata mach,
        Module calldata mod,
        Instruction calldata instruction,
        bytes calldata proof
    ) external view virtual returns (Machine memory result, Module memory resultMod);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Node.sol";
import "../bridge/IBridge.sol";
import "../bridge/IOutbox.sol";
import "../bridge/IInbox.sol";
import "./IRollupEventInbox.sol";
import "../challenge/IChallengeManager.sol";

interface IRollupCore {
    struct Staker {
        uint256 amountStaked;
        uint64 index;
        uint64 latestStakedNode;
        // currentChallenge is 0 if staker is not in a challenge
        uint64 currentChallenge;
        bool isStaked;
    }

    event RollupInitialized(bytes32 machineHash, uint256 chainId);

    event NodeCreated(
        uint64 indexed nodeNum,
        bytes32 indexed parentNodeHash,
        bytes32 indexed nodeHash,
        bytes32 executionHash,
        Assertion assertion,
        bytes32 afterInboxBatchAcc,
        bytes32 wasmModuleRoot,
        uint256 inboxMaxCount
    );

    event NodeConfirmed(uint64 indexed nodeNum, bytes32 blockHash, bytes32 sendRoot);

    event NodeRejected(uint64 indexed nodeNum);

    event RollupChallengeStarted(
        uint64 indexed challengeIndex,
        address asserter,
        address challenger,
        uint64 challengedNode
    );

    event UserStakeUpdated(address indexed user, uint256 initialBalance, uint256 finalBalance);

    event UserWithdrawableFundsUpdated(
        address indexed user,
        uint256 initialBalance,
        uint256 finalBalance
    );

    function confirmPeriodBlocks() external view returns (uint64);

    function extraChallengeTimeBlocks() external view returns (uint64);

    function chainId() external view returns (uint256);

    function baseStake() external view returns (uint256);

    function wasmModuleRoot() external view returns (bytes32);

    function bridge() external view returns (IBridge);

    function sequencerInbox() external view returns (ISequencerInbox);

    function outbox() external view returns (IOutbox);

    function rollupEventInbox() external view returns (IRollupEventInbox);

    function challengeManager() external view returns (IChallengeManager);

    function loserStakeEscrow() external view returns (address);

    function stakeToken() external view returns (address);

    function minimumAssertionPeriod() external view returns (uint256);

    function isValidator(address) external view returns (bool);

    function validatorWhitelistDisabled() external view returns (bool);

    /**
     * @notice Get the Node for the given index.
     */
    function getNode(uint64 nodeNum) external view returns (Node memory);

    /**
     * @notice Returns the block in which the given node was created for looking up its creation event.
     * Unlike the Node's createdAtBlock field, this will be the ArbSys blockNumber if the host chain is an Arbitrum chain.
     * That means that the block number returned for this is usable for event queries.
     * This function will revert if the given node number does not exist.
     * @dev This function is meant for internal use only and has no stability guarantees.
     */
    function getNodeCreationBlockForLogLookup(uint64 nodeNum) external view returns (uint256);

    /**
     * @notice Check if the specified node has been staked on by the provided staker.
     * Only accurate at the latest confirmed node and afterwards.
     */
    function nodeHasStaker(uint64 nodeNum, address staker) external view returns (bool);

    /**
     * @notice Get the address of the staker at the given index
     * @param stakerNum Index of the staker
     * @return Address of the staker
     */
    function getStakerAddress(uint64 stakerNum) external view returns (address);

    /**
     * @notice Check whether the given staker is staked
     * @param staker Staker address to check
     * @return True or False for whether the staker was staked
     */
    function isStaked(address staker) external view returns (bool);

    /**
     * @notice Get the latest staked node of the given staker
     * @param staker Staker address to lookup
     * @return Latest node staked of the staker
     */
    function latestStakedNode(address staker) external view returns (uint64);

    /**
     * @notice Get the current challenge of the given staker
     * @param staker Staker address to lookup
     * @return Current challenge of the staker
     */
    function currentChallenge(address staker) external view returns (uint64);

    /**
     * @notice Get the amount staked of the given staker
     * @param staker Staker address to lookup
     * @return Amount staked of the staker
     */
    function amountStaked(address staker) external view returns (uint256);

    /**
     * @notice Retrieves stored information about a requested staker
     * @param staker Staker address to retrieve
     * @return A structure with information about the requested staker
     */
    function getStaker(address staker) external view returns (Staker memory);

    /**
     * @notice Get the original staker address of the zombie at the given index
     * @param zombieNum Index of the zombie to lookup
     * @return Original staker address of the zombie
     */
    function zombieAddress(uint256 zombieNum) external view returns (address);

    /**
     * @notice Get Latest node that the given zombie at the given index is staked on
     * @param zombieNum Index of the zombie to lookup
     * @return Latest node that the given zombie is staked on
     */
    function zombieLatestStakedNode(uint256 zombieNum) external view returns (uint64);

    /// @return Current number of un-removed zombies
    function zombieCount() external view returns (uint256);

    function isZombie(address staker) external view returns (bool);

    /**
     * @notice Get the amount of funds withdrawable by the given address
     * @param owner Address to check the funds of
     * @return Amount of funds withdrawable by owner
     */
    function withdrawableFunds(address owner) external view returns (uint256);

    /**
     * @return Index of the first unresolved node
     * @dev If all nodes have been resolved, this will be latestNodeCreated + 1
     */
    function firstUnresolvedNode() external view returns (uint64);

    /// @return Index of the latest confirmed node
    function latestConfirmed() external view returns (uint64);

    /// @return Index of the latest rollup node created
    function latestNodeCreated() external view returns (uint64);

    /// @return Ethereum block that the most recent stake was created
    function lastStakeBlock() external view returns (uint64);

    /// @return Number of active stakers currently staked
    function stakerCount() external view returns (uint64);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../bridge/IBridge.sol";

interface IRollupEventInbox {
    function bridge() external view returns (IBridge);

    function initialize(IBridge _bridge) external;

    function rollup() external view returns (address);

    function rollupInitialized(uint256 chainId, string calldata chainConfig) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/GlobalState.sol";
import "../state/Machine.sol";

struct ExecutionState {
    GlobalState globalState;
    MachineStatus machineStatus;
}

struct Assertion {
    ExecutionState beforeState;
    ExecutionState afterState;
    uint64 numBlocks;
}

struct Node {
    // Hash of the state of the chain as of this node
    bytes32 stateHash;
    // Hash of the data that can be challenged
    bytes32 challengeHash;
    // Hash of the data that will be committed if this node is confirmed
    bytes32 confirmData;
    // Index of the node previous to this one
    uint64 prevNum;
    // Deadline at which this node can be confirmed
    uint64 deadlineBlock;
    // Deadline at which a child of this node can be confirmed
    uint64 noChildConfirmedBeforeBlock;
    // Number of stakers staked on this node. This includes real stakers and zombies
    uint64 stakerCount;
    // Number of stakers staked on a child node. This includes real stakers and zombies
    uint64 childStakerCount;
    // This value starts at zero and is set to a value when the first child is created. After that it is constant until the node is destroyed or the owner destroys pending nodes
    uint64 firstChildBlock;
    // The number of the latest child of this node to be created
    uint64 latestChildNumber;
    // The block number when this node was created
    uint64 createdAtBlock;
    // A hash of all the data needed to determine this node's validity, to protect against reorgs
    bytes32 nodeHash;
}

/**
 * @notice Utility functions for Node
 */
library NodeLib {
    /**
     * @notice Initialize a Node
     * @param _stateHash Initial value of stateHash
     * @param _challengeHash Initial value of challengeHash
     * @param _confirmData Initial value of confirmData
     * @param _prevNum Initial value of prevNum
     * @param _deadlineBlock Initial value of deadlineBlock
     * @param _nodeHash Initial value of nodeHash
     */
    function createNode(
        bytes32 _stateHash,
        bytes32 _challengeHash,
        bytes32 _confirmData,
        uint64 _prevNum,
        uint64 _deadlineBlock,
        bytes32 _nodeHash
    ) internal view returns (Node memory) {
        Node memory node;
        node.stateHash = _stateHash;
        node.challengeHash = _challengeHash;
        node.confirmData = _confirmData;
        node.prevNum = _prevNum;
        node.deadlineBlock = _deadlineBlock;
        node.noChildConfirmedBeforeBlock = _deadlineBlock;
        node.createdAtBlock = uint64(block.number);
        node.nodeHash = _nodeHash;
        return node;
    }

    /**
     * @notice Update child properties
     * @param number The child number to set
     */
    function childCreated(Node storage self, uint64 number) internal {
        if (self.firstChildBlock == 0) {
            self.firstChildBlock = uint64(block.number);
        }
        self.latestChildNumber = number;
    }

    /**
     * @notice Update the child confirmed deadline
     * @param deadline The new deadline to set
     */
    function newChildConfirmDeadline(Node storage self, uint64 deadline) internal {
        self.noChildConfirmedBeforeBlock = deadline;
    }

    /**
     * @notice Check whether the current block number has met or passed the node's deadline
     */
    function requirePastDeadline(Node memory self) internal view {
        require(block.number >= self.deadlineBlock, "BEFORE_DEADLINE");
    }

    /**
     * @notice Check whether the current block number has met or passed deadline for children of this node to be confirmed
     */
    function requirePastChildConfirmDeadline(Node memory self) internal view {
        require(block.number >= self.noChildConfirmedBeforeBlock, "CHILD_TOO_RECENT");
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct GlobalState {
    bytes32[2] bytes32Vals;
    uint64[2] u64Vals;
}

library GlobalStateLib {
    uint16 internal constant BYTES32_VALS_NUM = 2;
    uint16 internal constant U64_VALS_NUM = 2;

    function hash(GlobalState memory state) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "Global state:",
                    state.bytes32Vals[0],
                    state.bytes32Vals[1],
                    state.u64Vals[0],
                    state.u64Vals[1]
                )
            );
    }

    function getBlockHash(GlobalState memory state) internal pure returns (bytes32) {
        return state.bytes32Vals[0];
    }

    function getSendRoot(GlobalState memory state) internal pure returns (bytes32) {
        return state.bytes32Vals[1];
    }

    function getInboxPosition(GlobalState memory state) internal pure returns (uint64) {
        return state.u64Vals[0];
    }

    function getPositionInMessage(GlobalState memory state) internal pure returns (uint64) {
        return state.u64Vals[1];
    }

    function isEmpty(GlobalState calldata state) internal pure returns (bool) {
        return (state.bytes32Vals[0] == bytes32(0) &&
            state.bytes32Vals[1] == bytes32(0) &&
            state.u64Vals[0] == 0 &&
            state.u64Vals[1] == 0);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct Instruction {
    uint16 opcode;
    uint256 argumentData;
}

library Instructions {
    uint16 internal constant UNREACHABLE = 0x00;
    uint16 internal constant NOP = 0x01;
    uint16 internal constant RETURN = 0x0F;
    uint16 internal constant CALL = 0x10;
    uint16 internal constant CALL_INDIRECT = 0x11;
    uint16 internal constant LOCAL_GET = 0x20;
    uint16 internal constant LOCAL_SET = 0x21;
    uint16 internal constant GLOBAL_GET = 0x23;
    uint16 internal constant GLOBAL_SET = 0x24;

    uint16 internal constant I32_LOAD = 0x28;
    uint16 internal constant I64_LOAD = 0x29;
    uint16 internal constant F32_LOAD = 0x2A;
    uint16 internal constant F64_LOAD = 0x2B;
    uint16 internal constant I32_LOAD8_S = 0x2C;
    uint16 internal constant I32_LOAD8_U = 0x2D;
    uint16 internal constant I32_LOAD16_S = 0x2E;
    uint16 internal constant I32_LOAD16_U = 0x2F;
    uint16 internal constant I64_LOAD8_S = 0x30;
    uint16 internal constant I64_LOAD8_U = 0x31;
    uint16 internal constant I64_LOAD16_S = 0x32;
    uint16 internal constant I64_LOAD16_U = 0x33;
    uint16 internal constant I64_LOAD32_S = 0x34;
    uint16 internal constant I64_LOAD32_U = 0x35;

    uint16 internal constant I32_STORE = 0x36;
    uint16 internal constant I64_STORE = 0x37;
    uint16 internal constant F32_STORE = 0x38;
    uint16 internal constant F64_STORE = 0x39;
    uint16 internal constant I32_STORE8 = 0x3A;
    uint16 internal constant I32_STORE16 = 0x3B;
    uint16 internal constant I64_STORE8 = 0x3C;
    uint16 internal constant I64_STORE16 = 0x3D;
    uint16 internal constant I64_STORE32 = 0x3E;

    uint16 internal constant MEMORY_SIZE = 0x3F;
    uint16 internal constant MEMORY_GROW = 0x40;

    uint16 internal constant DROP = 0x1A;
    uint16 internal constant SELECT = 0x1B;
    uint16 internal constant I32_CONST = 0x41;
    uint16 internal constant I64_CONST = 0x42;
    uint16 internal constant F32_CONST = 0x43;
    uint16 internal constant F64_CONST = 0x44;
    uint16 internal constant I32_EQZ = 0x45;
    uint16 internal constant I32_RELOP_BASE = 0x46;
    uint16 internal constant IRELOP_EQ = 0;
    uint16 internal constant IRELOP_NE = 1;
    uint16 internal constant IRELOP_LT_S = 2;
    uint16 internal constant IRELOP_LT_U = 3;
    uint16 internal constant IRELOP_GT_S = 4;
    uint16 internal constant IRELOP_GT_U = 5;
    uint16 internal constant IRELOP_LE_S = 6;
    uint16 internal constant IRELOP_LE_U = 7;
    uint16 internal constant IRELOP_GE_S = 8;
    uint16 internal constant IRELOP_GE_U = 9;
    uint16 internal constant IRELOP_LAST = IRELOP_GE_U;

    uint16 internal constant I64_EQZ = 0x50;
    uint16 internal constant I64_RELOP_BASE = 0x51;

    uint16 internal constant I32_UNOP_BASE = 0x67;
    uint16 internal constant IUNOP_CLZ = 0;
    uint16 internal constant IUNOP_CTZ = 1;
    uint16 internal constant IUNOP_POPCNT = 2;
    uint16 internal constant IUNOP_LAST = IUNOP_POPCNT;

    uint16 internal constant I32_ADD = 0x6A;
    uint16 internal constant I32_SUB = 0x6B;
    uint16 internal constant I32_MUL = 0x6C;
    uint16 internal constant I32_DIV_S = 0x6D;
    uint16 internal constant I32_DIV_U = 0x6E;
    uint16 internal constant I32_REM_S = 0x6F;
    uint16 internal constant I32_REM_U = 0x70;
    uint16 internal constant I32_AND = 0x71;
    uint16 internal constant I32_OR = 0x72;
    uint16 internal constant I32_XOR = 0x73;
    uint16 internal constant I32_SHL = 0x74;
    uint16 internal constant I32_SHR_S = 0x75;
    uint16 internal constant I32_SHR_U = 0x76;
    uint16 internal constant I32_ROTL = 0x77;
    uint16 internal constant I32_ROTR = 0x78;

    uint16 internal constant I64_UNOP_BASE = 0x79;

    uint16 internal constant I64_ADD = 0x7C;
    uint16 internal constant I64_SUB = 0x7D;
    uint16 internal constant I64_MUL = 0x7E;
    uint16 internal constant I64_DIV_S = 0x7F;
    uint16 internal constant I64_DIV_U = 0x80;
    uint16 internal constant I64_REM_S = 0x81;
    uint16 internal constant I64_REM_U = 0x82;
    uint16 internal constant I64_AND = 0x83;
    uint16 internal constant I64_OR = 0x84;
    uint16 internal constant I64_XOR = 0x85;
    uint16 internal constant I64_SHL = 0x86;
    uint16 internal constant I64_SHR_S = 0x87;
    uint16 internal constant I64_SHR_U = 0x88;
    uint16 internal constant I64_ROTL = 0x89;
    uint16 internal constant I64_ROTR = 0x8A;

    uint16 internal constant I32_WRAP_I64 = 0xA7;
    uint16 internal constant I64_EXTEND_I32_S = 0xAC;
    uint16 internal constant I64_EXTEND_I32_U = 0xAD;

    uint16 internal constant I32_REINTERPRET_F32 = 0xBC;
    uint16 internal constant I64_REINTERPRET_F64 = 0xBD;
    uint16 internal constant F32_REINTERPRET_I32 = 0xBE;
    uint16 internal constant F64_REINTERPRET_I64 = 0xBF;

    uint16 internal constant I32_EXTEND_8S = 0xC0;
    uint16 internal constant I32_EXTEND_16S = 0xC1;
    uint16 internal constant I64_EXTEND_8S = 0xC2;
    uint16 internal constant I64_EXTEND_16S = 0xC3;
    uint16 internal constant I64_EXTEND_32S = 0xC4;

    uint16 internal constant INIT_FRAME = 0x8002;
    uint16 internal constant ARBITRARY_JUMP = 0x8003;
    uint16 internal constant ARBITRARY_JUMP_IF = 0x8004;
    uint16 internal constant MOVE_FROM_STACK_TO_INTERNAL = 0x8005;
    uint16 internal constant MOVE_FROM_INTERNAL_TO_STACK = 0x8006;
    uint16 internal constant DUP = 0x8008;
    uint16 internal constant CROSS_MODULE_CALL = 0x8009;
    uint16 internal constant CALLER_MODULE_INTERNAL_CALL = 0x800A;

    uint16 internal constant GET_GLOBAL_STATE_BYTES32 = 0x8010;
    uint16 internal constant SET_GLOBAL_STATE_BYTES32 = 0x8011;
    uint16 internal constant GET_GLOBAL_STATE_U64 = 0x8012;
    uint16 internal constant SET_GLOBAL_STATE_U64 = 0x8013;

    uint16 internal constant READ_PRE_IMAGE = 0x8020;
    uint16 internal constant READ_INBOX_MESSAGE = 0x8021;
    uint16 internal constant HALT_AND_SET_FINISHED = 0x8022;

    uint256 internal constant INBOX_INDEX_SEQUENCER = 0;
    uint256 internal constant INBOX_INDEX_DELAYED = 1;

    function hash(Instruction memory inst) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("Instruction:", inst.opcode, inst.argumentData));
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ValueStack.sol";
import "./Instructions.sol";
import "./StackFrame.sol";

enum MachineStatus {
    RUNNING,
    FINISHED,
    ERRORED,
    TOO_FAR
}

struct Machine {
    MachineStatus status;
    ValueStack valueStack;
    ValueStack internalStack;
    StackFrameWindow frameStack;
    bytes32 globalStateHash;
    uint32 moduleIdx;
    uint32 functionIdx;
    uint32 functionPc;
    bytes32 modulesRoot;
}

library MachineLib {
    using StackFrameLib for StackFrameWindow;
    using ValueStackLib for ValueStack;

    function hash(Machine memory mach) internal pure returns (bytes32) {
        // Warning: the non-running hashes are replicated in Challenge
        if (mach.status == MachineStatus.RUNNING) {
            return
                keccak256(
                    abi.encodePacked(
                        "Machine running:",
                        mach.valueStack.hash(),
                        mach.internalStack.hash(),
                        mach.frameStack.hash(),
                        mach.globalStateHash,
                        mach.moduleIdx,
                        mach.functionIdx,
                        mach.functionPc,
                        mach.modulesRoot
                    )
                );
        } else if (mach.status == MachineStatus.FINISHED) {
            return keccak256(abi.encodePacked("Machine finished:", mach.globalStateHash));
        } else if (mach.status == MachineStatus.ERRORED) {
            return keccak256(abi.encodePacked("Machine errored:"));
        } else if (mach.status == MachineStatus.TOO_FAR) {
            return keccak256(abi.encodePacked("Machine too far:"));
        } else {
            revert("BAD_MACH_STATUS");
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ModuleMemoryCompact.sol";

struct Module {
    bytes32 globalsMerkleRoot;
    ModuleMemory moduleMemory;
    bytes32 tablesMerkleRoot;
    bytes32 functionsMerkleRoot;
    uint32 internalsOffset;
}

library ModuleLib {
    using ModuleMemoryCompactLib for ModuleMemory;

    function hash(Module memory mod) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "Module:",
                    mod.globalsMerkleRoot,
                    mod.moduleMemory.hash(),
                    mod.tablesMerkleRoot,
                    mod.functionsMerkleRoot,
                    mod.internalsOffset
                )
            );
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct ModuleMemory {
    uint64 size;
    uint64 maxSize;
    bytes32 merkleRoot;
}

library ModuleMemoryCompactLib {
    function hash(ModuleMemory memory mem) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("Memory:", mem.size, mem.maxSize, mem.merkleRoot));
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";

struct StackFrame {
    Value returnPc;
    bytes32 localsMerkleRoot;
    uint32 callerModule;
    uint32 callerModuleInternals;
}

struct StackFrameWindow {
    StackFrame[] proved;
    bytes32 remainingHash;
}

library StackFrameLib {
    using ValueLib for Value;

    function hash(StackFrame memory frame) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "Stack frame:",
                    frame.returnPc.hash(),
                    frame.localsMerkleRoot,
                    frame.callerModule,
                    frame.callerModuleInternals
                )
            );
    }

    function hash(StackFrameWindow memory window) internal pure returns (bytes32 h) {
        h = window.remainingHash;
        for (uint256 i = 0; i < window.proved.length; i++) {
            h = keccak256(abi.encodePacked("Stack frame stack:", hash(window.proved[i]), h));
        }
    }

    function peek(StackFrameWindow memory window) internal pure returns (StackFrame memory) {
        require(window.proved.length == 1, "BAD_WINDOW_LENGTH");
        return window.proved[0];
    }

    function pop(StackFrameWindow memory window) internal pure returns (StackFrame memory frame) {
        require(window.proved.length == 1, "BAD_WINDOW_LENGTH");
        frame = window.proved[0];
        window.proved = new StackFrame[](0);
    }

    function push(StackFrameWindow memory window, StackFrame memory frame) internal pure {
        StackFrame[] memory newProved = new StackFrame[](window.proved.length + 1);
        for (uint256 i = 0; i < window.proved.length; i++) {
            newProved[i] = window.proved[i];
        }
        newProved[window.proved.length] = frame;
        window.proved = newProved;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

enum ValueType {
    I32,
    I64,
    F32,
    F64,
    REF_NULL,
    FUNC_REF,
    INTERNAL_REF
}

struct Value {
    ValueType valueType;
    uint256 contents;
}

library ValueLib {
    function hash(Value memory val) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("Value:", val.valueType, val.contents));
    }

    function maxValueType() internal pure returns (ValueType) {
        return ValueType.INTERNAL_REF;
    }

    function assumeI32(Value memory val) internal pure returns (uint32) {
        uint256 uintval = uint256(val.contents);
        require(val.valueType == ValueType.I32, "NOT_I32");
        require(uintval < (1 << 32), "BAD_I32");
        return uint32(uintval);
    }

    function assumeI64(Value memory val) internal pure returns (uint64) {
        uint256 uintval = uint256(val.contents);
        require(val.valueType == ValueType.I64, "NOT_I64");
        require(uintval < (1 << 64), "BAD_I64");
        return uint64(uintval);
    }

    function newRefNull() internal pure returns (Value memory) {
        return Value({valueType: ValueType.REF_NULL, contents: 0});
    }

    function newI32(uint32 x) internal pure returns (Value memory) {
        return Value({valueType: ValueType.I32, contents: uint256(x)});
    }

    function newI64(uint64 x) internal pure returns (Value memory) {
        return Value({valueType: ValueType.I64, contents: uint256(x)});
    }

    function newBoolean(bool x) internal pure returns (Value memory) {
        if (x) {
            return newI32(uint32(1));
        } else {
            return newI32(uint32(0));
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";

struct ValueArray {
    Value[] inner;
}

library ValueArrayLib {
    function get(ValueArray memory arr, uint256 index) internal pure returns (Value memory) {
        return arr.inner[index];
    }

    function set(
        ValueArray memory arr,
        uint256 index,
        Value memory val
    ) internal pure {
        arr.inner[index] = val;
    }

    function length(ValueArray memory arr) internal pure returns (uint256) {
        return arr.inner.length;
    }

    function push(ValueArray memory arr, Value memory val) internal pure {
        Value[] memory newInner = new Value[](arr.inner.length + 1);
        for (uint256 i = 0; i < arr.inner.length; i++) {
            newInner[i] = arr.inner[i];
        }
        newInner[arr.inner.length] = val;
        arr.inner = newInner;
    }

    function pop(ValueArray memory arr) internal pure returns (Value memory popped) {
        popped = arr.inner[arr.inner.length - 1];
        Value[] memory newInner = new Value[](arr.inner.length - 1);
        for (uint256 i = 0; i < newInner.length; i++) {
            newInner[i] = arr.inner[i];
        }
        arr.inner = newInner;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";
import "./ValueArray.sol";

struct ValueStack {
    ValueArray proved;
    bytes32 remainingHash;
}

library ValueStackLib {
    using ValueLib for Value;
    using ValueArrayLib for ValueArray;

    function hash(ValueStack memory stack) internal pure returns (bytes32 h) {
        h = stack.remainingHash;
        uint256 len = stack.proved.length();
        for (uint256 i = 0; i < len; i++) {
            h = keccak256(abi.encodePacked("Value stack:", stack.proved.get(i).hash(), h));
        }
    }

    function peek(ValueStack memory stack) internal pure returns (Value memory) {
        uint256 len = stack.proved.length();
        return stack.proved.get(len - 1);
    }

    function pop(ValueStack memory stack) internal pure returns (Value memory) {
        return stack.proved.pop();
    }

    function push(ValueStack memory stack, Value memory val) internal pure {
        return stack.proved.push(val);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract NodeLicense is ERC721EnumerableUpgradeable, AccessControlUpgradeable {
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    address payable public fundsReceiver;

    uint256 public maxSupply; // Maximum number of licenses that can be minted

    // Define the pricing table
    Tier[] private pricingTiers;

    uint256 public referralDiscountPercentage;
    uint256 public referralRewardPercentage;

    // Boolean to control whether referral rewards can be claimed
    bool public claimable;

    // Mapping from token ID to minting timestamp
    mapping (uint256 => uint256) private _mintTimestamps;

    // Mapping from promo code to PromoCode struct
    mapping (string => PromoCode) private _promoCodes;

    // Mapping from referral address to referral reward
    mapping (address => uint256) private _referralRewards;

    // Mapping from token ID to average cost, this is used for refunds over multiple tiers
    mapping (uint256 => uint256) private _averageCost;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[500] private __gap;

    // Define the pricing tiers
    struct Tier {
        uint256 price;
        uint256 quantity;
    }

    // Define the PromoCode struct
    struct PromoCode {
        address recipient;
        bool active;
        uint256 receivedLifetime;
    }

    event PromoCodeCreated(string promoCode, address recipient);
    event PromoCodeRemoved(string promoCode);
    event RewardClaimed(address indexed claimer, uint256 amount);
    event PricingTierSetOrAdded(uint256 index, uint256 price, uint256 quantity);
    event ReferralRewardPercentagesChanged(uint256 referralDiscountPercentage, uint256 referralRewardPercentage);
    event RefundOccurred(address indexed refundee, uint256 amount);
    event ReferralReward(address indexed buyer, address indexed referralAddress, uint256 amount);
    event FundsWithdrawn(address indexed admin, uint256 amount);
    event FundsReceiverChanged(address indexed admin, address newFundsReceiver);
    event ClaimableChanged(address indexed admin, bool newClaimableState);

    function initialize(
        address payable _fundsReceiver,
        uint256 _referralDiscountPercentage,
        uint256 _referralRewardPercentage
    ) public initializer {
        __ERC721_init("Sentry Node License", "SNL");
        __AccessControl_init();
        fundsReceiver = _fundsReceiver;
        referralDiscountPercentage = _referralDiscountPercentage;
        referralRewardPercentage = _referralRewardPercentage;
        claimable = false;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Creates a new promo code.
     * @param _promoCode The promo code.
     * @param _recipient The recipient address.
     */
    function createPromoCode(string calldata _promoCode, address _recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_recipient != address(0), "Recipient address cannot be zero");
        _promoCodes[_promoCode] = PromoCode(_recipient, true, 0);
        emit PromoCodeCreated(_promoCode, _recipient);
    }

    /**
     * @notice Disables a promo code.
     * @param _promoCode The promo code to disable.
     */
    function removePromoCode(string calldata _promoCode) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_promoCodes[_promoCode].recipient != address(0), "Promo code does not exist");
        _promoCodes[_promoCode].active = false; // 'active' is set to false
        emit PromoCodeRemoved(_promoCode);
    }

    /**
     * @notice Returns the promo code details.
     * @param _promoCode The promo code to get.
     * @return The promo code details.
     */
    function getPromoCode(string calldata _promoCode) external view returns (PromoCode memory) {
        return _promoCodes[_promoCode];
    }

    /**
     * @notice Returns the length of the pricing tiers array.
     * @return The length of the pricing tiers array.
     */
    function getPricingTiersLength() external view returns (uint256) {
        return pricingTiers.length;
    }

    /**
     * @notice Mints new NodeLicense tokens.
     * @param _amount The amount of tokens to mint.
     * @param _promoCode The promo code.
     */
    function mint(uint256 _amount, string calldata _promoCode) public payable {
        require(
            _tokenIds.current() + _amount <= maxSupply,
            "Exceeds maxSupply"
        );
        PromoCode memory promoCode = _promoCodes[_promoCode];
        require(
            (promoCode.recipient != address(0) && promoCode.active) || bytes(_promoCode).length == 0,
            "Invalid or inactive promo code"
        );
        require(
            promoCode.recipient != msg.sender,
            "Referral address cannot be the sender's address"
        );

        uint256 finalPrice = price(_amount, _promoCode);
        uint256 averageCost = msg.value / _amount;

        require(msg.value >= finalPrice, "Ether value sent is not correct");

        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);

            // Record the minting timestamp
            _mintTimestamps[newItemId] = block.timestamp;

            // Record the average cost
            _averageCost[newItemId] = averageCost;
        }

        // Calculate the referral reward
        uint256 referralReward = 0;
        if (promoCode.recipient != address(0)) {
            referralReward = finalPrice * referralRewardPercentage / 100;
            _referralRewards[promoCode.recipient] += referralReward;
            _promoCodes[_promoCode].receivedLifetime += referralReward;
            emit ReferralReward(msg.sender, promoCode.recipient, referralReward);
        }

        uint256 remainder = msg.value - finalPrice;
        (bool sent, bytes memory data) = fundsReceiver.call{value: finalPrice - referralReward}("");
        require(sent, "Failed to send Ether");

        // Send back the remainder amount
        if (remainder > 0) {
            (bool sentRemainder, bytes memory dataRemainder) = msg.sender.call{value: remainder}("");
            require(sentRemainder, "Failed to send back the remainder Ether");
        }
    }

    /**
     * @notice Calculates the price for minting NodeLicense tokens.
     * @param _amount The amount of tokens to mint.
     * @param _promoCode The promo code to use address.
     * @return The price in wei.
     */
    function price(uint256 _amount, string calldata _promoCode) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 totalCost = 0;
        uint256 remaining = _amount;
        uint256 tierSum = 0;

        for (uint256 i = 0; i < pricingTiers.length; i++) {
            tierSum += pricingTiers[i].quantity;
            uint256 availableInThisTier = tierSum > totalSupply
                ? tierSum - totalSupply
                : 0;

            if (remaining <= availableInThisTier) {
                totalCost += remaining * pricingTiers[i].price;
                remaining = 0;
                break;
            } else {
                totalCost += availableInThisTier * pricingTiers[i].price;
                remaining -= availableInThisTier;
                totalSupply += availableInThisTier;
            }
        }

        require(remaining == 0, "Not enough licenses available for sale");

        // Apply discount if promo code is active
        if (_promoCodes[_promoCode].active) {
            totalCost = totalCost * (100 - referralDiscountPercentage) / 100;
        }

        return totalCost;
    }

    /**
     * @notice Allows a user to claim their referral reward.
     * @dev The function checks if claiming is enabled and if the caller has a reward to claim.
     * If both conditions are met, the reward is transferred to the caller and their reward balance is reset.
     */
    function claimReferralReward() external {
        require(claimable, "Claiming of referral rewards is currently disabled");
        uint256 reward = _referralRewards[msg.sender];
        require(reward > 0, "No referral reward to claim");
        _referralRewards[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Transfer failed.");
        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @notice Allows the admin to withdraw all funds from the contract.
     * @dev Only callable by the admin.
     */
    function withdrawFunds() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = address(this).balance;
        fundsReceiver.transfer(amount);
        emit FundsWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Allows the admin to toggle the claimable state of referral rewards.
     * @param _claimable The new state of the claimable variable.
     * @dev Only callable by the admin.
     */
    function setClaimable(bool _claimable) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimable = _claimable;
        emit ClaimableChanged(msg.sender, _claimable);
    }

    /**
     * @notice Sets the fundsReceiver address.
     * @param _newFundsReceiver The new fundsReceiver address.
     * @dev The new fundsReceiver address cannot be the zero address.
     */
    function setFundsReceiver(
        address payable _newFundsReceiver
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newFundsReceiver != address(0), "New fundsReceiver cannot be the zero address");
        fundsReceiver = _newFundsReceiver;
        emit FundsReceiverChanged(msg.sender, _newFundsReceiver);
    }

    /**
     * @notice Sets the referral discount and reward percentages.
     * @param _referralDiscountPercentage The referral discount percentage.
     * @param _referralRewardPercentage The referral reward percentage.
     * @dev The referral discount and reward percentages cannot be greater than 99.
     */
    function setReferralPercentages(
        uint256 _referralDiscountPercentage,
        uint256 _referralRewardPercentage
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_referralDiscountPercentage <= 99, "Referral discount percentage cannot be greater than 99");
        require(_referralRewardPercentage <= 99, "Referral reward percentage cannot be greater than 99");
        referralDiscountPercentage = _referralDiscountPercentage;
        referralRewardPercentage = _referralRewardPercentage;
        emit ReferralRewardPercentagesChanged(_referralDiscountPercentage, _referralRewardPercentage);
    }

    /**
     * @notice Sets or adds a pricing tier.
     * @param _index The index of the tier to set or add.
     * @param _price The price of the tier.
     * @param _quantity The quantity of the tier.
     */
    function setOrAddPricingTier(uint256 _index, uint256 _price, uint256 _quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_index < pricingTiers.length) {
            // Subtract the quantity of the old tier from maxSupply
            maxSupply -= pricingTiers[_index].quantity;
            pricingTiers[_index] = Tier(_price, _quantity);
        } else if (_index == pricingTiers.length) {
            pricingTiers.push(Tier(_price, _quantity));
        } else {
            revert("Index out of bounds");
        }

        // Add the quantity of the new or updated tier to maxSupply
        maxSupply += _quantity;
        emit PricingTierSetOrAdded(_index, _price, _quantity);
    }

    /**
     * @notice Returns the pricing tier at the given index.
     * @param _index The index of the tier.
     * @return The Tier at the given index.
     */
    function getPricingTier(uint256 _index) public view returns (Tier memory) {
        require(_index < pricingTiers.length, "Index out of bounds");
        return pricingTiers[_index];
    }

    /**
     * @notice Returns the metadata of a NodeLicense token.
     * @param _tokenId The ID of the token.
     * @return The token metadata.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        address ownerAddress = ownerOf(_tokenId);
        string memory svg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100' style='background-color:black;'><text x='10' y='50' font-size='20' fill='white'>",
                _tokenId.toString(),
                "</text><text x='10' y='90' font-size='8' textLength='100' lengthAdjust='spacingAndGlyphs' fill='white'>",
                StringsUpgradeable.toHexString(uint160(ownerAddress)),
                "</text></svg>"
            )
        );
        string memory image = Base64Upgradeable.encode(bytes(svg));
        string memory json = Base64Upgradeable.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Token #',
                        _tokenId.toString(),
                        '", "description": "A NodeLicense token", "image": "data:image/svg+xml;base64,',
                        image,
                        '", "owner": "',
                        StringsUpgradeable.toHexString(uint160(ownerAddress)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @notice Allows the admin to refund a NodeLicense.
     * @param _tokenId The ID of the token to refund.
     * @dev Only callable by the admin.
     */
    function refundNodeLicense(uint256 _tokenId) external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_exists(_tokenId), "ERC721Metadata: Refund for nonexistent token");
        uint256 refundAmount = _averageCost[_tokenId];
        require(refundAmount > 0, "No funds to refund");
        _averageCost[_tokenId] = 0;
        (bool success, ) = payable(ownerOf(_tokenId)).call{value: refundAmount}("");
        require(success, "Transfer failed.");
        emit RefundOccurred(ownerOf(_tokenId), refundAmount);
        _burn(_tokenId);
    }

    /**
     * @notice Returns the average cost of a NodeLicense token. This is primarily used for refunds.
     * @param _tokenId The ID of the token.
     * @return The average cost.
     */
    function getAverageCost(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ERC721Metadata: Query for nonexistent token");
        return _averageCost[_tokenId];
    }

    /**
     * @notice Returns the minting timestamp of a NodeLicense token.
     * @param _tokenId The ID of the token.
     * @return The minting timestamp.
     */
    function getMintTimestamp(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ERC721Metadata: Query for nonexistent token");
        return _mintTimestamps[_tokenId];
    }

    /**
     * @notice Overrides the supportsInterface function of the AccessControl contract.
     * @param interfaceId The interface id.
     * @return A boolean value indicating whether the contract supports the given interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId) || ERC721EnumerableUpgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Overrides the transfer function of the ERC721 contract to make the token non-transferable.
     * @param from The current owner of the token.
     * @param to The address to receive the token.
     * @param tokenId The token id.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        revert("NodeLicense: transfer is not allowed");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

/*
 * MIT License
 *
 * Copyright (c) 2018 requestnetwork
 * Copyright (c) 2018 Fragments, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

contract BucketTracker {
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private tokenHoldersMap;

    mapping(address => uint256) public lastClaimTimes;
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;
    address public trackerOwner;
    address public esXaiAddress;
    string _name;
    string _symbol;
    uint256 _decimals;

    uint256 internal constant magnitude = 2 ** 128;
    uint256 internal magnifiedDividendPerShare;
    uint256 public _totalDividendsDistributed;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256[500] __gap;

    event Transfer(address indexed from, address indexed to, uint value);
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
    event Claim(address indexed account, uint256 amount);

    function initialize(
        address _trackerOwner,
        address _esXaiAddress,
        string memory __name,
        string memory __symbol,
        uint256 __decimals
    ) external {
        require(trackerOwner == address(0), "Invalid init");
        require(_trackerOwner != address(0), "Owner cannot be 0 address");
        require(_esXaiAddress != address(0), "EsXai cannot be 0 address");
        trackerOwner = _trackerOwner;
        esXaiAddress = _esXaiAddress;
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
    }

    modifier onlyAdmin() {
        require(trackerOwner == msg.sender, "Unauthorized");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalDividendsDistributed() external view returns (uint256) {
        return _totalDividendsDistributed;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function owner() public view returns (address) {
        return trackerOwner;
    }

    function transferToken(address to, uint256 value) internal returns (bool) {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = esXaiAddress.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }

    function distributeDividends(uint256 amount) public onlyAdmin {
        require(totalSupply() > 0);

        if (amount > 0) {
            magnifiedDividendPerShare += ((amount * magnitude) / totalSupply());

            emit DividendsDistributed(msg.sender, amount);

            _totalDividendsDistributed += amount;
        }
    }

    function _withdrawDividendOfUser(address user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] += _withdrawableDividend;

            emit DividendWithdrawn(user, _withdrawableDividend);

            bool success = transferToken(user, _withdrawableDividend);

            if (!success) {
                withdrawnDividends[user] -= _withdrawableDividend;
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function withdrawableDividendOf(
        address _owner
    ) public view returns (uint256) {
        return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
    }

    function withdrawnDividendOf(address _owner) public view returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(
        address _owner
    ) public view returns (uint256) {
        return
            (magnifiedDividendPerShare * _balances[_owner])
                .toInt256Safe()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256Safe() / magnitude;
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _balances[account] += value;
        _totalSupply += value;

        magnifiedDividendCorrections[account] -= (magnifiedDividendPerShare *
            value).toInt256Safe();

        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] -= value;
        _totalSupply -= value;

        magnifiedDividendCorrections[account] += (magnifiedDividendPerShare *
            value).toInt256Safe();

        emit Transfer(account, address(0), value);
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = _balances[account];

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance - currentBalance;
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance - newBalance;
            _burn(account, burnAmount);
        }
    }

    function getAccount(
        address _account
    )
        public
        view
        returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime
        )
    {
        account = _account;

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
    }

    function setBalance(
        address account,
        uint256 newBalance
    ) external onlyAdmin {
        _setBalance(account, newBalance);
        processAccount(account);
    }

    function processAccount(address account) public onlyAdmin returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract PoolBeacon is Ownable {
	UpgradeableBeacon immutable beacon;

	constructor(address _implementation) {
		beacon = new UpgradeableBeacon(_implementation);
	}

	function update(address _implementation) public onlyOwner {
		beacon.upgradeTo(_implementation);
	}

	function implementation() public view returns (address) {
		return beacon.implementation();
	}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "../upgrades/referee/Referee5.sol";
import "../Xai.sol";
import "../esXai.sol";
import "./StakingPool.sol";
import "./PoolProxyDeployer.sol";
import "./PoolBeacon.sol";

// Error Codes
// 1: Staking must be enabled before creating pool
// 2: At least 1 key needed to create a pool
// 3: Share configuration is invalid; _ownerShare, _keyBucketShare, and _stakedBucketShare must be less than or equal to the set bucketshareMaxValues[0], [1], and [2] values respectively. All 3 must also add up 10,000
// 4: Delegate cannot be pool creator
// 5: Invalid auth: msg.sender must be pool owner
// 6: Invalid auth: msg.sender must be pool owner
// 7: Share configuration is invalid; _ownerShare, _keyBucketShare, and _stakedBucketShare must be less than or equal to the set bucketshareMaxValues[0], [1], and [2] values respectively. All 3 must also add up 10,000
// 8: Invalid auth: msg.sender must be pool owner
// 9: New delegate cannot be pool owner
// 10: Invalid pool; cannot be 0 address
// 11: Invalid key stake; must at least stake 1 key
// 12: Invalid pool for key stake; pool needs to have been created via the PoolFactory
// 13: Invalid key un-stake; must un-stake at least 1 key
// 14: Invalid pool for key un-stake request; pool needs to have been created via the PoolFactory
// 15: Invalid un-stake; not enough keys for owner to un-stake this many - to un-stake all keys, first un-stake all buy 1, then use createUnstakeOwnerLastKeyRequest
// 16: Invalid un-stake; not enough keys for you to un-stake this many - your staked key amount must be greater than or equal to the combined total of any pending un-stake requests with this pool & the current un-stake request
// 17: This can only be called by the pool owner
// 18: Invalid pool for owner last key un-stake request; pool needs to have been created via the PoolFactory
// 19: Owner must have one more key stakes than any pending un-stake requests from the same pool; if you have no un-stake requests waiting, you must have 1 key staked
// 20: Invalid esXai un-stake request; amount must be greater than 0
// 21: Invalid esXai un-stake request; your requested esXai amount must be greater than equal to the combined total of any pending un-stake requests with this pool & the current un-stake request
// 22: Invalid pool for esXai un-stake request; pool needs to have been created via the PoolFactory
// 23: Invalid pool for key un-stake; pool needs to have been created via the PoolFactory
// 24: Request must be open & a key request
// 25: Wait period for this key un-stake request is not yet over
// 26: You must un-stake at least 1 key, and the amount must match the un-stake request
// 27: Invalid pool for esXai stake; pool needs to have been created via the PoolFactory
// 28: Invalid pool for esXai un-stake; pool needs to have been created via the PoolFactory
// 29: Request must be open & an esXai request
// 30: Wait period for this esXai un-stake request is not yet over
// 31: You must un-stake at least 1 esXai, and the amount must match the un-stake request
// 32: You must have at least the desired un-stake amount staked in order to un-stake
// 33: Invalid pool for claim; pool needs to have been created via the PoolFactory
// 34: Invalid delegate update; pool needs to have been created via the PoolFactory

contract PoolFactory is Initializable, AccessControlEnumerableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // the address of the NodeLicense NFT
    address public nodeLicenseAddress;

    // contract addresses for esXai and xai
    address public esXaiAddress;

    address public refereeAddress;

    // Enabling staking on the Referee
    bool public stakingEnabled;

    // Staking pool contract addresses
    address[] public stakingPools;

    // Staking Pool share max values owner, keys, stakedEsXai in basepoints (5% => 50_000)
    uint32[3] public bucketshareMaxValues;

    // Mapping all pool addresses of a specific user
    mapping(address => address[]) public interactedPoolsOfUser;

    // mapping user address to pool address to index in user array, used for removing from user array without iteration
    mapping(address => mapping(address => uint256))
        public userToInteractedPoolIds;

    // mapping delegates to pools they are delegates of
    mapping(address => address[]) public poolsOfDelegate;

    // mapping of pool address to indices in the poolsOfDelegate[delegate] array
    mapping(address => uint256) public poolsOfDelegateIndices;

    // mapping of pool address => true if create via this factory
    mapping(address => bool) public poolsCreatedViaFactory;

	// address of the contract that handles deploying staking pool & bucket proxies
    address public deployerAddress;

	// periods (in seconds) to lock keys/esXai for when user creates an unstake request
	uint256 public unstakeKeysDelayPeriod;
	uint256 public unstakeGenesisKeyDelayPeriod;
	uint256 public unstakeEsXaiDelayPeriod;
    
    // period (in seconds) to update reward breakdown changes
	uint256 public updateRewardBreakdownDelayPeriod;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[500] private __gap;

    event StakingEnabled();
    event PoolProxyDeployerUpdated(address oldDeployer, address newDeployer);
    event UpdateDelayPeriods();

    event PoolCreated(
        uint256 indexed poolIndex,
        address indexed poolAddress,
        address indexed poolOwner,
        uint256 stakedKeyCount
    );
    event StakeEsXai(
        address indexed user,
        address indexed pool,
        uint256 amount,
        uint256 totalUserEsXaiStaked,
        uint256 totalEsXaiStaked
    );
    event UnstakeEsXai(
        address indexed user,
        address indexed pool,
        uint256 amount,
        uint256 totalUserEsXaiStaked,
        uint256 totalEsXaiStaked
    );
    event StakeKeys(
        address indexed user,
        address indexed pool,
        uint256 amount,
        uint256 totalUserKeysStaked,
        uint256 totalKeysStaked
    );
    event UnstakeKeys(
        address indexed user,
        address indexed pool,
        uint256 amount,
        uint256 totalUserKeysStaked,
        uint256 totalKeysStaked
    );

    event ClaimFromPool(address indexed user, address indexed pool);
    event UpdatePoolDelegate(address indexed delegate, address indexed pool);
    event UpdateShares(address indexed pool);
    event UpdateMetadata(address indexed pool);

    event UnstakeRequestStarted(
        address indexed user,
        address indexed pool,
        uint256 indexed index,
        uint256 amount,
        bool isKey
    );

    function initialize(
        address _refereeAddress,
        address _esXaiAddress,
        address _nodeLicenseAddress
    ) public initializer {
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        bucketshareMaxValues[0] = 100_000; // => 10%
        bucketshareMaxValues[1] = 950_000; // => 95%
        bucketshareMaxValues[2] = 850_000; // => 85%

        refereeAddress = _refereeAddress;
        nodeLicenseAddress = _nodeLicenseAddress;
        esXaiAddress = _esXaiAddress;

		unstakeKeysDelayPeriod = 7 days;
		unstakeGenesisKeyDelayPeriod = 60 days;
		unstakeEsXaiDelayPeriod = 7 days;
        updateRewardBreakdownDelayPeriod = 14 days;
    }

    /**
     * @notice Enables staking on the Factory.
     */
    function enableStaking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingEnabled = true;
        emit StakingEnabled();
    }

    function updatePoolProxyDeployer(address newDeployer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address prevDeployer = deployerAddress;
        deployerAddress = newDeployer;
        emit PoolProxyDeployerUpdated(prevDeployer, deployerAddress);
    }

	function updateDelayPeriods(
		uint256 _unstakeKeysDelayPeriod,
		uint256 _unstakeGenesisKeyDelayPeriod,
		uint256 _unstakeEsXaiDelayPeriod,
		uint256 _updateRewardBreakdownDelayPeriod
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		unstakeKeysDelayPeriod = _unstakeKeysDelayPeriod;
		unstakeGenesisKeyDelayPeriod = _unstakeGenesisKeyDelayPeriod;
		unstakeEsXaiDelayPeriod = _unstakeEsXaiDelayPeriod;
        updateRewardBreakdownDelayPeriod = _updateRewardBreakdownDelayPeriod;
        emit UpdateDelayPeriods();
	}

    function createPool(
        address _delegateOwner,
        uint256[] memory _keyIds,
        uint32[3] memory _shareConfig,
        string[3] memory _poolMetadata,
        string[] memory _poolSocials,
        string[2][2] memory trackerDetails
    ) external {
        require(stakingEnabled, "1");
        require(_keyIds.length > 0, "2");
        require(validateShareValues(_shareConfig), "3");
        require(msg.sender != _delegateOwner, "4");

        (
            address poolProxy,
            address keyBucketProxy,
            address esXaiBucketProxy
        ) = PoolProxyDeployer(deployerAddress).createPool();

        StakingPool(poolProxy).initialize(
            refereeAddress,
            esXaiAddress,
            msg.sender,
            _delegateOwner,
            keyBucketProxy,
            esXaiBucketProxy
        );

        StakingPool(poolProxy).initShares(
            _shareConfig[0],
            _shareConfig[1],
            _shareConfig[2]
        );

        StakingPool(poolProxy).updateMetadata(_poolMetadata, _poolSocials);

        BucketTracker(keyBucketProxy).initialize(
            poolProxy,
            esXaiAddress,
            trackerDetails[0][0],
            trackerDetails[0][1],
            0
        );

        BucketTracker(esXaiBucketProxy).initialize(
            poolProxy,
            esXaiAddress,
            trackerDetails[1][0],
            trackerDetails[1][1],
            18
        );

        // Add pool to delegate's list
        if (_delegateOwner != address(0)) {
            poolsOfDelegateIndices[poolProxy] = poolsOfDelegate[_delegateOwner]
                .length;
            poolsOfDelegate[_delegateOwner].push(poolProxy);
        }

        stakingPools.push(poolProxy);
        poolsCreatedViaFactory[poolProxy] = true;

        esXai(esXaiAddress).addToWhitelist(poolProxy);
        esXai(esXaiAddress).addToWhitelist(keyBucketProxy);
        esXai(esXaiAddress).addToWhitelist(esXaiBucketProxy);

        _stakeKeys(poolProxy, _keyIds);
        emit PoolCreated(
            stakingPools.length - 1,
            poolProxy,
            msg.sender,
            _keyIds.length
        );
    }

    function updatePoolMetadata(
        address pool,
        string[3] memory _poolMetadata,
        string[] memory _poolSocials
    ) external {
        StakingPool stakingPool = StakingPool(pool);
        require(stakingPool.getPoolOwner() == msg.sender, "5");
        stakingPool.updateMetadata(_poolMetadata, _poolSocials);
        emit UpdateMetadata(pool);
    }

    function updateShares(
        address pool,
        uint32[3] memory _shareConfig
    ) external {
        StakingPool stakingPool = StakingPool(pool);
        require(stakingPool.getPoolOwner() == msg.sender, "6");
        require(validateShareValues(_shareConfig), "7");
        stakingPool.updateShares(
            _shareConfig[0],
            _shareConfig[1],
            _shareConfig[2],
            updateRewardBreakdownDelayPeriod
        );
        emit UpdateShares(pool);
    }

    function validateShareValues(
        uint32[3] memory _shareConfig
    ) internal view returns (bool) {
        return
            _shareConfig[0] <= bucketshareMaxValues[0] &&
            _shareConfig[1] <= bucketshareMaxValues[1] &&
            _shareConfig[2] <= bucketshareMaxValues[2] &&
            _shareConfig[0] + _shareConfig[1] + _shareConfig[2] == 1_000_000;
    }

	function updateDelegateOwner(address pool, address delegate) external {
		StakingPool stakingPool = StakingPool(pool);
        require(poolsCreatedViaFactory[pool], "34");
		require(stakingPool.getPoolOwner() == msg.sender, "8");
		require(msg.sender != delegate, "9");

		// If staking pool already has delegate, remove pool from old delegate's list
        address oldDelegate = stakingPool.getDelegateOwner();
		if (oldDelegate != address(0)) {
			uint256 indexOfPoolToRemove = poolsOfDelegateIndices[pool]; // index of pool in question in delegate's list
			address lastDelegatePoolId = poolsOfDelegate[oldDelegate][poolsOfDelegate[oldDelegate].length - 1];

			poolsOfDelegateIndices[lastDelegatePoolId] = indexOfPoolToRemove;
			poolsOfDelegate[oldDelegate][indexOfPoolToRemove] = lastDelegatePoolId;
			poolsOfDelegate[oldDelegate].pop();
		}

		// Add pool to delegate's list
		if (delegate != address(0)) {
			poolsOfDelegateIndices[pool] = poolsOfDelegate[delegate].length;
			poolsOfDelegate[delegate].push(pool);
		}
        
		stakingPool.updateDelegateOwner(delegate);

		emit UpdatePoolDelegate(delegate, pool);
	}

    function _stakeKeys(address pool, uint256[] memory keyIds) internal {
        Referee5(refereeAddress).stakeKeys(pool, msg.sender, keyIds);
        StakingPool stakingPool = StakingPool(pool);
        stakingPool.stakeKeys(msg.sender, keyIds);

        associateUserWithPool(msg.sender, pool);

        emit StakeKeys(
            msg.sender,
            pool,
            keyIds.length,
            stakingPool.getStakedKeysCountForUser(msg.sender),
            stakingPool.getStakedKeysCount()
        );
    }

    function stakeKeys(address pool, uint256[] memory keyIds) external {
        require(pool != address(0), "10");
        require(keyIds.length > 0, "11");
        require(poolsCreatedViaFactory[pool], "12");

        _stakeKeys(pool, keyIds);
    }

    function createUnstakeKeyRequest(address pool, uint256 keyAmount) external {
        require(keyAmount > 0, "13");
        require(poolsCreatedViaFactory[pool], "14");
        StakingPool(pool).createUnstakeKeyRequest(msg.sender, keyAmount, unstakeKeysDelayPeriod);

        emit UnstakeRequestStarted(
            msg.sender,
            pool,
            StakingPool(pool).getUnstakeRequestCount(msg.sender) - 1,
            keyAmount,
            true
        );
    }

    function createUnstakeOwnerLastKeyRequest(address pool) external {
        require(poolsCreatedViaFactory[pool], "18");
        StakingPool(pool).createUnstakeOwnerLastKeyRequest(msg.sender, unstakeGenesisKeyDelayPeriod);

        emit UnstakeRequestStarted(
            msg.sender,
            pool,
            StakingPool(pool).getUnstakeRequestCount(msg.sender) - 1,
            1,
            true
        );
    }

    function createUnstakeEsXaiRequest(address pool, uint256 amount) external {
        require(amount > 0, "20");
        require(poolsCreatedViaFactory[pool], "22");
        StakingPool(pool).createUnstakeEsXaiRequest(msg.sender, amount, unstakeEsXaiDelayPeriod);

        emit UnstakeRequestStarted(
            msg.sender,
            pool,
            StakingPool(pool).getUnstakeRequestCount(msg.sender) - 1,
            amount,
            false
        );
    }

    function unstakeKeys(
        address pool,
        uint256 unstakeRequestIndex,
        uint256[] memory keyIds
    ) external {
        require(poolsCreatedViaFactory[pool], "23");

        Referee5(refereeAddress).unstakeKeys(pool, msg.sender, keyIds);
        StakingPool stakingPool = StakingPool(pool);
        stakingPool.unstakeKeys(msg.sender, unstakeRequestIndex, keyIds);

        if (!stakingPool.isUserEngagedWithPool(msg.sender)) {
            removeUserFromPool(msg.sender, pool);
        }

        emit UnstakeKeys(
            msg.sender,
            pool,
            keyIds.length,
            stakingPool.getStakedKeysCountForUser(msg.sender),
            stakingPool.getStakedKeysCount()
        );
    }

    function stakeEsXai(address pool, uint256 amount) external {
        require(poolsCreatedViaFactory[pool], "27");

        Referee5(refereeAddress).stakeEsXai(pool, amount);
        esXai(esXaiAddress).transferFrom(msg.sender, address(this), amount);
        StakingPool stakingPool = StakingPool(pool);
        stakingPool.stakeEsXai(msg.sender, amount);

        associateUserWithPool(msg.sender, pool);

        emit StakeEsXai(
            msg.sender,
            pool,
            amount,
            stakingPool.getStakedAmounts(msg.sender),
            Referee5(refereeAddress).stakedAmounts(pool)
        );
    }

    function unstakeEsXai(
        address pool,
        uint256 unstakeRequestIndex,
        uint256 amount
    ) external {
        require(poolsCreatedViaFactory[pool], "28");

        esXai(esXaiAddress).transfer(msg.sender, amount);
        Referee5(refereeAddress).unstakeEsXai(pool, amount);
        StakingPool stakingPool = StakingPool(pool);
        stakingPool.unstakeEsXai(msg.sender, unstakeRequestIndex, amount);

        if (!stakingPool.isUserEngagedWithPool(msg.sender)) {
            removeUserFromPool(msg.sender, pool);
        }

        emit UnstakeEsXai(
            msg.sender,
            pool,
            amount,
            stakingPool.getStakedAmounts(msg.sender),
            Referee5(refereeAddress).stakedAmounts(pool)
        );
    }

    function associateUserWithPool(address user, address pool) internal {
        address[] storage userPools = interactedPoolsOfUser[user];
        if (
            userPools.length < 1 ||
            pool != userPools[userToInteractedPoolIds[user][pool]]
        ) {
            userToInteractedPoolIds[user][pool] = userPools.length;
            userPools.push(pool);
        }
    }

    function removeUserFromPool(address user, address pool) internal {
        uint256 indexOfPool = userToInteractedPoolIds[user][pool];
        uint256 userLength = interactedPoolsOfUser[user].length;
        address lastPool = interactedPoolsOfUser[user][
            userLength - 1
        ];
        
        interactedPoolsOfUser[user][indexOfPool] = lastPool;
        userToInteractedPoolIds[user][lastPool] = indexOfPool;

        interactedPoolsOfUser[user].pop();
    }

    function claimFromPools(address[] memory pools) external {
        uint256 poolsLength = pools.length;

        for (uint i = 0; i < poolsLength; i++) {
            address stakingPool = pools[i];
            require(poolsCreatedViaFactory[stakingPool], "33");
            StakingPool(stakingPool).claimRewards(msg.sender);
            emit ClaimFromPool(msg.sender, stakingPool);
        }
    }

    function getDelegatePools(
        address delegate
    ) external view returns (address[] memory) {
        return poolsOfDelegate[delegate];
    }

    function isDelegateOfPoolOrOwner(
        address delegate,
        address pool
    ) external view returns (bool) {
        return (
			poolsOfDelegate[delegate].length > poolsOfDelegateIndices[pool] &&
			poolsOfDelegate[delegate][poolsOfDelegateIndices[pool]] == pool
		) ||
		StakingPool(pool).getPoolOwner() == delegate;
    }

    function getPoolsCount() external view returns (uint256) {
        return stakingPools.length;
    }

    function getPoolIndicesOfUser(
        address user
    ) external view returns (address[] memory) {
        return interactedPoolsOfUser[user];
    }

    function getPoolsOfUserCount(address user) external view returns (uint256) {
        return interactedPoolsOfUser[user].length;
    }

    function getPoolAddress(uint256 poolIndex) external view returns (address) {
        return stakingPools[poolIndex];
    }

    function getPoolAddressOfUser(
        address user,
        uint256 index
    ) external view returns (address) {
        return interactedPoolsOfUser[user][index];
    }

    function getUnstakedKeyIdsFromUser(
        address user,
        uint16 offset,
        uint16 pageLimit
    ) external view returns (uint256[] memory unstakedKeyIds) {
        uint256 userKeyBalance = NodeLicense(nodeLicenseAddress).balanceOf(
            user
        );
        unstakedKeyIds = new uint256[](pageLimit);
        uint256 currentIndexUnstaked = 0;
        uint256 limit = offset + pageLimit;

        for (uint256 i = offset; i < userKeyBalance && i < limit; i++) {
            uint256 keyId = NodeLicense(nodeLicenseAddress).tokenOfOwnerByIndex(
                user,
                i
            );
            if (
                Referee5(refereeAddress).assignedKeyToPool(keyId) == address(0)
            ) {
                unstakedKeyIds[currentIndexUnstaked] = keyId;
                currentIndexUnstaked++;
            }
        }
    }

    function checkKeysAreStaked(
        uint256[] memory keyIds
    ) external view returns (bool[] memory isStaked) {
        isStaked = new bool[](keyIds.length);
        for (uint256 i; i < keyIds.length; i++) {
            isStaked[i] =
                Referee5(refereeAddress).assignedKeyToPool(keyIds[i]) !=
                address(0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./PoolBeacon.sol";

contract PoolProxyDeployer is
    Initializable,
    AccessControlEnumerableUpgradeable
{
    address public poolBeacon;
    address public keyBucketBeacon;
    address public esXaiBeacon;

    function initialize(
        address poolFactoryAddress,
        address _poolBeacon,
        address _keyBucketBeacon,
        address _esXaiBeacon
    ) public initializer {
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, poolFactoryAddress);
        poolBeacon = _poolBeacon;
        keyBucketBeacon = _keyBucketBeacon;
		esXaiBeacon = _esXaiBeacon;
    }

    function createPool()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (
            address poolProxy,
            address keyBucketProxy,
            address esXaiBucketProxy
        )
    {
        poolProxy = address(new BeaconProxy(poolBeacon, ""));

        keyBucketProxy = address(new BeaconProxy(keyBucketBeacon, ""));

        esXaiBucketProxy = address(new BeaconProxy(esXaiBeacon, ""));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../upgrades/referee/Referee5.sol";
import "./BucketTracker.sol";
import "../esXai.sol";

contract StakingPool is AccessControlUpgradeable {
    bytes32 public constant POOL_ADMIN = keccak256("POOL_ADMIN");

    address public refereeAddress;
    address public esXaiAddress;

    address public poolOwner;
	address public delegateOwner;

    //Pool Metadata
    string public name;
    string public description;
    string public logo;
    string[] public socials;

	uint32 public ownerShare;
	uint32 public keyBucketShare;
	uint32 public stakedBucketShare;

    uint256 public poolOwnerClaimableRewards;
    BucketTracker public keyBucket;
    BucketTracker public esXaiStakeBucket;

    mapping(address => uint256[]) public stakedKeysOfOwner;
    mapping(uint256 => uint256) public keyIdIndex;
    mapping(address => uint256) public stakedAmounts;

	uint256[] public stakedKeys;
	mapping(uint256 => uint256) public stakedKeysIndices;

	uint32[3] pendingShares;
    uint256 updateSharesTimestamp;

	// mapping userAddress to unstake requests, currently unstaking requires a waiting period set in the PoolFactory
	mapping(address => UnstakeRequest[]) private unstakeRequests;

	// mapping userAddress to requested unstake key amount
	mapping(address => uint256) private userRequestedUnstakeKeyAmount;

	// mapping userAddress to requested unstake esXai amount
	mapping(address => uint256) private userRequestedUnstakeEsXaiAmount;

    uint256[500] __gap;

	struct PoolBaseInfo {
		address poolAddress;
		address owner;
		address keyBucketTracker;
		address esXaiBucketTracker;
		uint256 keyCount;
		uint256 totalStakedAmount;
		uint256 updateSharesTimestamp;
		uint32 ownerShare;
		uint32 keyBucketShare;
		uint32 stakedBucketShare;
	}

	struct UnstakeRequest {
		bool open;
		bool isKeyRequest;
		uint256 amount;
		uint256 lockTime;
		uint256 completeTime;
		uint256[5] __gap;
	}

    function initialize(
        address _refereeAddress,
        address _esXaiAddress,
        address _owner,
        address _delegateOwner,
        address _keyBucket,
        address _esXaiStakeBucket
    ) public initializer {
        require(poolOwner == address(0), "Invalid init");
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        esXaiAddress = _esXaiAddress;
        refereeAddress = _refereeAddress;

        keyBucket = BucketTracker(_keyBucket);
        esXaiStakeBucket = BucketTracker(_esXaiStakeBucket);

        poolOwner = _owner;
		delegateOwner = _delegateOwner;
    }

    function getPoolOwner() external view returns (address) {
        return poolOwner;
    }

	function getDelegateOwner() external view returns (address) {
		return delegateOwner;
	}

    function getStakedKeysCount() external view returns (uint256) {
        return keyBucket.totalSupply();
    }

    function getStakedKeysCountForUser(
        address user
    ) external view returns (uint256) {
        return stakedKeysOfOwner[user].length;
    }

    function getStakedAmounts(address user) external view returns (uint256) {
        return stakedAmounts[user];
    }

	function getStakedKeys() external view returns (uint256[] memory) {
		return stakedKeys;
	}

	function updateDelegateOwner(address delegate) external onlyRole(DEFAULT_ADMIN_ROLE) {
		delegateOwner = delegate;
	}

    function distributeRewards() internal {
        if (
            updateSharesTimestamp > 0 && block.timestamp > updateSharesTimestamp
        ) {
            ownerShare = pendingShares[0];
            keyBucketShare = pendingShares[1];
            stakedBucketShare = pendingShares[2];
            updateSharesTimestamp = 0;
            pendingShares[0] = 0;
            pendingShares[1] = 0;
            pendingShares[2] = 0;
        }

        uint256 amountToDistribute = esXai(esXaiAddress).balanceOf(
            address(this)
        ) - poolOwnerClaimableRewards;

        if (amountToDistribute == 0) {
            return;
        }

        uint256 amountForKeys = (amountToDistribute * keyBucketShare) / 1_000_000;
        uint256 amountForStaked = (amountToDistribute * stakedBucketShare) / 1_000_000;

        if (amountForStaked > 0) {
            //If there are no esXai stakers we will distribute to keys and owner proportional to their shares
            if (esXaiStakeBucket.totalSupply() == 0) {
                amountForKeys +=
                    (amountForStaked * keyBucketShare) /
                    (keyBucketShare + ownerShare);

                amountForStaked = 0;
            } else {
                esXai(esXaiAddress).transfer(
                    address(esXaiStakeBucket),
                    amountForStaked
                );
                esXaiStakeBucket.distributeDividends(amountForStaked);
            }
        }

        esXai(esXaiAddress).transfer(address(keyBucket), amountForKeys);
        keyBucket.distributeDividends(amountForKeys);

        poolOwnerClaimableRewards +=
            amountToDistribute -
            amountForKeys -
            amountForStaked;
    }

    function initShares(
        uint32 _ownerShare,
		uint32 _keyBucketShare,
		uint32 _stakedBucketShare
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ownerShare = _ownerShare;
        keyBucketShare = _keyBucketShare;
        stakedBucketShare = _stakedBucketShare;
    }

    function updateShares(
		uint32 _ownerShare,
		uint32 _keyBucketShare,
		uint32 _stakedBucketShare,
        uint256 period 
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pendingShares[0] = _ownerShare;
        pendingShares[1] = _keyBucketShare;
        pendingShares[2] = _stakedBucketShare;
        updateSharesTimestamp = block.timestamp + period;
    }

    function updateMetadata(
		string[3] memory _metaData,
        string[] memory _socials
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        name = _metaData[0];
        description = _metaData[1];
        logo = _metaData[2];
        socials = _socials;
    }

    function stakeKeys(
        address owner,
        uint256[] memory keyIds
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 keyLength = keyIds.length;
        for (uint i = 0; i < keyLength; i++) {
			// Update indexes of this user's staked keys
            keyIdIndex[keyIds[i]] = stakedKeysOfOwner[owner].length;
            stakedKeysOfOwner[owner].push(keyIds[i]);

			// Update indexes of the pool's staked keys
			stakedKeysIndices[keyIds[i]] = stakedKeys.length;
			stakedKeys.push(keyIds[i]);
        }

        distributeRewards();
        keyBucket.processAccount(owner);
        keyBucket.setBalance(owner, stakedKeysOfOwner[owner].length);
    }

	function createUnstakeKeyRequest(address user, uint256 keyAmount, uint256 period) external onlyRole(DEFAULT_ADMIN_ROLE) {
		uint256 stakedKeysCount = stakedKeysOfOwner[user].length;
		uint256 requestKeys = userRequestedUnstakeKeyAmount[user];

		if (poolOwner == user) {
			require(
				stakedKeysCount >
				keyAmount + requestKeys,
				"15"
			);
		} else {
			require(
				stakedKeysCount >=
				keyAmount + requestKeys,
				"16"
			);
		}

		UnstakeRequest[] storage userRequests = unstakeRequests[user];

		userRequests.push(
			UnstakeRequest(
				true,
				true,
				keyAmount,
				block.timestamp + period,
				0,
				[uint256(0), 0, 0, 0, 0]
			)
		);

		userRequestedUnstakeKeyAmount[user] += keyAmount;
	}

	function createUnstakeOwnerLastKeyRequest(address owner, uint256 period) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(owner == poolOwner, "17");
		uint256 stakedKeysCount = stakedKeysOfOwner[owner].length;

		require(
			stakedKeysCount == userRequestedUnstakeKeyAmount[owner] + 1,
			"19"
		);

		UnstakeRequest[] storage userRequests = unstakeRequests[owner];

		userRequests.push(
			UnstakeRequest(
				true,
				true,
				1,
				block.timestamp + period,
				0,
				[uint256(0), 0, 0, 0, 0]
			)
		);

		userRequestedUnstakeKeyAmount[owner] += 1;
	}

	function createUnstakeEsXaiRequest(address user, uint256 amount, uint256 period) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(stakedAmounts[user] >= amount + userRequestedUnstakeEsXaiAmount[user], "21");
		UnstakeRequest[] storage userRequests = unstakeRequests[user];

		userRequests.push(
			UnstakeRequest(
				true,
				false,
				amount,
				block.timestamp + period,
				0,
				[uint256(0), 0, 0, 0, 0]
			)
		);

		userRequestedUnstakeEsXaiAmount[user] += amount;
	}

	function isUserEngagedWithPool(address user) external view returns (bool) {
		return user == poolOwner ||
			stakedAmounts[user] > 0 ||
			stakedKeysOfOwner[user].length > 0;
	}

    function unstakeKeys(
        address owner,
		uint256 unstakeRequestIndex,
        uint256[] memory keyIds
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
		UnstakeRequest storage request = unstakeRequests[owner][unstakeRequestIndex];
        uint256 keysLength = keyIds.length;

		require(request.open && request.isKeyRequest, "24");
		require(block.timestamp >= request.lockTime, "25");
		require(keysLength > 0 && request.amount == keysLength, "26");

        for (uint i = 0; i < keysLength; i++) {
			// Update indexes of this owner's staked keys
            uint256 indexOfOwnerKeyToRemove = keyIdIndex[keyIds[i]];
            uint256 lastOwnerKeyId = stakedKeysOfOwner[owner][
                stakedKeysOfOwner[owner].length - 1
            ];

            keyIdIndex[lastOwnerKeyId] = indexOfOwnerKeyToRemove;
            stakedKeysOfOwner[owner][indexOfOwnerKeyToRemove] = lastOwnerKeyId;
            stakedKeysOfOwner[owner].pop();

			// Update indexes of the pool's staked keys
			uint256 indexOfStakedKeyToRemove = stakedKeysIndices[keyIds[i]];
			uint256 lastStakedKeyId = stakedKeys[stakedKeys.length - 1];

			stakedKeysIndices[lastStakedKeyId] = indexOfStakedKeyToRemove;
			stakedKeys[indexOfStakedKeyToRemove] = lastStakedKeyId;
			stakedKeys.pop();
        }

        distributeRewards();
        keyBucket.processAccount(owner);
        keyBucket.setBalance(owner, stakedKeysOfOwner[owner].length);

		userRequestedUnstakeKeyAmount[owner] -= keysLength;
		request.open = false;
		request.completeTime = block.timestamp;
    }

    function stakeEsXai(
        address owner,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakedAmounts[owner] += amount;
        distributeRewards();
        esXaiStakeBucket.processAccount(owner);
        esXaiStakeBucket.setBalance(owner, stakedAmounts[owner]);
    }

    function unstakeEsXai(
        address owner,
		uint256 unstakeRequestIndex,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
		UnstakeRequest storage request = unstakeRequests[owner][unstakeRequestIndex];

		require(request.open && !request.isKeyRequest, "29");
		require(block.timestamp >= request.lockTime, "30");
		require(amount > 0 && request.amount == amount, "31");
		require(stakedAmounts[owner] >= amount, "32");

        stakedAmounts[owner] -= amount;
        distributeRewards();
        esXaiStakeBucket.processAccount(owner);
        esXaiStakeBucket.setBalance(owner, stakedAmounts[owner]);

		userRequestedUnstakeEsXaiAmount[owner] -= amount;
		request.open = false;
		request.completeTime = block.timestamp;
    }

    function claimRewards(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        distributeRewards();

        if (user == poolOwner && poolOwnerClaimableRewards > 0) {
            esXai(esXaiAddress).transfer(user, poolOwnerClaimableRewards);
            poolOwnerClaimableRewards = 0;
        }

        keyBucket.processAccount(user);
        esXaiStakeBucket.processAccount(user);
    }

    function _getUndistributedClaimAmount(
        address user
    ) internal view returns (
		uint256 claimAmountFromKeys,
		uint256 claimAmountFromEsXai,
		uint256 claimAmount,
		uint256 ownerAmount
	) {
        uint256 poolAmount = esXai(esXaiAddress).balanceOf(address(this)) - poolOwnerClaimableRewards;

        uint256 amountForKeyBucket = (poolAmount * keyBucketShare) / 1_000_000;
        uint256 amountForEsXaiBucket = (poolAmount * stakedBucketShare) / 1_000_000;

        ownerAmount = poolAmount - amountForKeyBucket - amountForEsXaiBucket;

        uint256 userBalanceInKeyBucket = keyBucket.balanceOf(user);
        uint256 userBalanceInEsXaiBucket = esXaiStakeBucket.balanceOf(user);

        if (userBalanceInKeyBucket != 0) {
            uint256 amountPerKey = amountForKeyBucket * 1_000_000 / keyBucket.totalSupply();
			claimAmountFromKeys = amountPerKey * userBalanceInKeyBucket / 1_000_000;
            claimAmount += claimAmountFromKeys;
        }

        if (userBalanceInEsXaiBucket != 0) {
            uint256 amountPerStakedEsXai = amountForEsXaiBucket * 1_000_000 / esXaiStakeBucket.totalSupply();
			claimAmountFromEsXai = amountPerStakedEsXai * userBalanceInEsXaiBucket / 1_000_000;
            claimAmount += claimAmountFromEsXai;
        }
    }

    function getUndistributedClaimAmount(
        address user
    ) external view returns (
		uint256 claimAmountFromKeys,
		uint256 claimAmountFromEsXai,
		uint256 claimAmount,
		uint256 ownerAmount
	) {
        return _getUndistributedClaimAmount(user);
    }

    function getPoolInfo()
        external
        view
        returns (
            PoolBaseInfo memory baseInfo,
            string memory _name,
            string memory _description,
            string memory _logo,
            string[] memory _socials,
			uint32[] memory _pendingShares,
			uint256 _ownerStakedKeys,
			uint256 _ownerRequestedUnstakeKeyAmount,
			uint256 _ownerLatestUnstakeRequestLockTime
        )
    {
        baseInfo.poolAddress = address(this);
        baseInfo.owner = poolOwner;
        baseInfo.keyBucketTracker = address(keyBucket);
        baseInfo.esXaiBucketTracker = address(esXaiStakeBucket);
        baseInfo.keyCount = keyBucket.totalSupply();
        baseInfo.totalStakedAmount = esXaiStakeBucket.totalSupply();
        baseInfo.ownerShare = ownerShare;
        baseInfo.keyBucketShare = keyBucketShare;
        baseInfo.stakedBucketShare = stakedBucketShare;
        baseInfo.updateSharesTimestamp = updateSharesTimestamp;

        _name = name;
        _description = description;
        _logo = logo;
        _socials = socials;

        _pendingShares = new uint32[](3);
        _pendingShares[0] = pendingShares[0];
        _pendingShares[1] = pendingShares[1];
        _pendingShares[2] = pendingShares[2];

		_ownerStakedKeys = stakedKeysOfOwner[poolOwner].length;
		_ownerRequestedUnstakeKeyAmount = userRequestedUnstakeKeyAmount[poolOwner];

		if (_ownerStakedKeys == _ownerRequestedUnstakeKeyAmount && _ownerRequestedUnstakeKeyAmount > 0) {
			_ownerLatestUnstakeRequestLockTime = unstakeRequests[poolOwner][unstakeRequests[poolOwner].length - 1].lockTime;
		}
    }

    function getUserPoolData(
        address user
    )
        external
        view
        returns (
            uint256 userStakedEsXaiAmount,
            uint256 userClaimAmount,
            uint256[] memory userStakedKeyIds,
            uint256 unstakeRequestkeyAmount, 
            uint256 unstakeRequestesXaiAmount
        )
    {
        userStakedEsXaiAmount = stakedAmounts[user];

        uint256 claimAmountKeyBucket = keyBucket.withdrawableDividendOf(user);
        uint256 claimAmountStakedBucket = esXaiStakeBucket
            .withdrawableDividendOf(user);

        (, , uint256 claimAmount, uint256 ownerAmount) = _getUndistributedClaimAmount(user);

        userClaimAmount =
            claimAmountKeyBucket +
            claimAmountStakedBucket +
            claimAmount;
        if (user == poolOwner) {
            userClaimAmount += poolOwnerClaimableRewards + ownerAmount;
        }

        userStakedKeyIds = stakedKeysOfOwner[user];
        
		unstakeRequestkeyAmount = userRequestedUnstakeKeyAmount[user];
		unstakeRequestesXaiAmount = userRequestedUnstakeEsXaiAmount[user];
    }

	function getUnstakeRequest(
		address account,
		uint256 index
	) public view returns (UnstakeRequest memory) {
		return unstakeRequests[account][index];
	}

	function getUnstakeRequestCount(address account) public view returns (uint256) {
		return unstakeRequests[account].length;
	}

	function getUserRequestedUnstakeAmounts(
		address user
	) external view returns (uint256 keyAmount, uint256 esXaiAmount) {
		keyAmount = userRequestedUnstakeKeyAmount[user];
		esXaiAmount = userRequestedUnstakeEsXaiAmount[user];
	}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../nitro-contracts/rollup/IRollupCore.sol";
import "../../NodeLicense.sol";
import "../../Xai.sol";
import "../../esXai.sol";
import "../../staking-v2/PoolFactory.sol";

// Error Codes
// 1: Only PoolFactory can call this function.
// 2: Index out of bounds.
// 3: Index out of bounds.
// 4: Index out of bounds.
// 5: There are no more tiers, we are too close to the end.
// 6: There are no more accurate tiers.
// 7: Rollup address must be set before submitting a challenge.
// 8: Challenger public key must be set before submitting a challenge.
// 9: This assertionId and rollupAddress combo has already been submitted.
// 10: The _predecessorAssertionId is incorrect.
// 11: The _confirmData is incorrect.
// 12: The _assertionTimestamp did not match the block this assertion was created at.
// 13: Challenge with this id has not been created.
// 14: Challenge is not open for submissions.
// 15: _nodeLicenseId has already been submitted for this challenge.
// 16: Challenge is not open for submissions.
// 17: Caller must be the owner of the NodeLicense, an approved operator, or the delegator owner of the pool.
// 18: The Challenge does not exist for this id.
// 19: Challenge is still open for submissions.
// 20: Challenge rewards have expired.
// 21: NodeLicense is not eligible for a payout on this challenge, it was minted after it started.
// 22: Owner of the NodeLicense is not KYC'd.
// 23: This submission has already been claimed.
// 24: Not valid for a payout.
// 25: The Challenge does not exist for this id.
// 26: Challenge is still open for submissions.
// 27: Challenge rewards have expired.
// 28: The Challenge does not exist for this id.
// 29: Challenge is not old enough to expire rewards.
// 30: The challenge is already expired.
// 31: Invalid max amount.
// 32: Invalid max amount.
// 33: Invalid boost factor.
// 34: Threshold needs to be monotonically increasing.
// 35: Threshold needs to be monotonically increasing.
// 36: Threshold needs to be monotonically increasing.
// 37: Invalid boost factor.
// 38: Threshold needs to be monotonically increasing.
// 39: Cannot remove last tier.
// 40: Index out of bounds.
// 41: Insufficient amount staked.
// 42: Must complete KYC.
// 43: Maximum staking amount exceeded.
// 44: Key already assigned.
// 45: Not owner of key.
// 46: Pool owner needs at least 1 staked key.
// 47: Key not assigned to pool.
// 48: Not owner of key.
// 49: Maximum staking amount exceeded.
// 50: Invalid amount.

contract Referee5 is Initializable, AccessControlEnumerableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // Define roles
    bytes32 public constant CHALLENGER_ROLE = keccak256("CHALLENGER_ROLE");
    bytes32 public constant KYC_ADMIN_ROLE = keccak256("KYC_ADMIN_ROLE");

    // The Challenger's public key of their registered BLS-Pair
    bytes public challengerPublicKey;

    // the address of the rollup, so we can get assertions
    address public rollupAddress;

    // the address of the NodeLicense NFT
    address public nodeLicenseAddress;

    // contract addresses for esXai and xai
    address public esXaiAddress;
    address public xaiAddress;

    // Counter for the challenges
    uint256 public challengeCounter;

    // This is the address where we sent the Xai emission to for the gas subsidy
    address public gasSubsidyRecipient;

    // mapping to store all of the challenges
    mapping(uint256 => Challenge) public challenges;

    // Mapping to store all of the submissions
    mapping(uint256 => mapping(uint256 => Submission)) public submissions;

    // Toggle for assertion checking
    bool public isCheckingAssertions;

    // Mapping from owner to operator approvals
    mapping (address => EnumerableSetUpgradeable.AddressSet) private _operatorApprovals;

    // Mapping from operator to owners
    mapping (address => EnumerableSetUpgradeable.AddressSet) private _ownersForOperator;

    // Mappings to keep track of all claims
    mapping (address => uint256) private _lifetimeClaims;

    // Mapping to track rollup assertions (combination of the assertionId and the rollupAddress used, because we allow switching the rollupAddress, and can't assume assertionIds are unique.)
    mapping (bytes32 => bool) public rollupAssertionTracker;

    // Mapping to track KYC'd wallets
    EnumerableSetUpgradeable.AddressSet private kycWallets;

    // This value keeps track of how many token are not yet minted but are allocated by the referee. This should be used in calculating the total supply for emissions
    uint256 private _allocatedTokens;

    // This is the percentage of each challenge emission to be given to the gas subsidy. Should be a whole number like 15% = 15
    uint256 private _gasSubsidyPercentage;

    // Mapping for users staked amount in V1 staking
    mapping(address => uint256) public stakedAmounts;

    // Minimum amounts of staked esXai to be in the tier of the respective index
    uint256[] public stakeAmountTierThresholds;

    // Reward chance boost factor based on tier of the respective index
    uint256[] public stakeAmountBoostFactors;

    // The maximum amount of esXai (in wei) that can be staked per NodeLicense
    uint256 public maxStakeAmountPerLicense;
    
    // Enabling staking on the Referee
    bool public stakingEnabled;

    // Mapping for a key id assigned to a staking pool
    mapping(uint256 => address) public assignedKeyToPool;

    // Mapping for pool to assigned key count for calculating max stake amount
    mapping(address => uint256) public assignedKeysToPoolCount;

    // The maximum number of NodeLicenses that can be staked to a pool
    uint256 public maxKeysPerPool;

    // The pool factory contract that is allowed to update the stake state of the Referee
    address public poolFactoryAddress;
    
    // Mapping for amount of assigned keys of a user
    mapping(address => uint256) public assignedKeysOfUserCount;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[490] private __gap;

    // Struct for the submissions
    struct Submission {
        bool submitted;
        bool claimed;
        bool eligibleForPayout;
        uint256 nodeLicenseId;
        bytes assertionStateRootOrConfirmData;
    }

    // Struct for the challenges
    struct Challenge {
        bool openForSubmissions; // when the next challenge is submitted for the following assertion, this will be closed.
        bool expiredForRewarding; // when this is true, this challenge is no longer eligible for claiming
        uint64 assertionId;
        bytes32 assertionStateRootOrConfirmData; // Depending on the BOLD 2 deployment, this will either be the assertionStateRoot or ConfirmData
        uint64 assertionTimestamp; // equal to the block number the assertion was made on in the rollup protocol
        bytes challengerSignedHash;
        bytes activeChallengerPublicKey; // The challengerPublicKey that was active at the time of challenge submission
        address rollupUsed; // The rollup address used for this challenge
        uint256 createdTimestamp; // used to determine if a node license is eligible to submit
        uint256 totalSupplyOfNodesAtChallengeStart; // keep track of what the total supply opf nodes is when the challenge starts
        uint256 rewardAmountForClaimers; // this is how much esXai should be allocated to the claimers
        uint256 amountForGasSubsidy; // this is how much Xai was minted for the gas subsidy
        uint256 numberOfEligibleClaimers; // how many submitters are eligible for claiming, used to determine the reward amount
        uint256 amountClaimedByClaimers; // keep track of how much Xai has been claimed by the claimers, primarily used to expire unclaimed rewards 
    }

    // Define events
    event ChallengeSubmitted(uint256 indexed challengeNumber);
    event ChallengeClosed(uint256 indexed challengeNumber);
    event AssertionSubmitted(uint256 indexed challengeId, uint256 indexed nodeLicenseId);
    event RollupAddressChanged(address newRollupAddress);
    event ChallengerPublicKeyChanged(bytes newChallengerPublicKey);
    event NodeLicenseAddressChanged(address newNodeLicenseAddress);
    event AssertionCheckingToggled(bool newState);
    event Approval(address indexed owner, address indexed operator, bool approved);
    event KycStatusChanged(address indexed wallet, bool isKycApproved);
    event InvalidSubmission(uint256 indexed challengeId, uint256 nodeLicenseId);
    event InvalidBatchSubmission(uint256 indexed challengeId, address operator, uint256 keysLength);
    event RewardsClaimed(uint256 indexed challengeId, uint256 amount);
    event BatchRewardsClaimed(uint256 indexed challengeId, uint256 totalReward, uint256 keysLength);
    event ChallengeExpired(uint256 indexed challengeId);
    event StakingEnabled();
    event UpdateMaxStakeAmount(uint256 prevAmount, uint256 newAmount);
    event UpdateMaxKeysPerPool(uint256 prevAmount, uint256 newAmount);
    event StakedV1(address indexed user, uint256 amount, uint256 totalStaked);
    event UnstakeV1(address indexed user, uint256 amount, uint256 totalStaked);

    modifier onlyPoolFactory() {
        require(msg.sender == poolFactoryAddress, "1");
        _;
    }

    function initialize(
        address _poolFactoryAddress
    ) public reinitializer(4) {
        poolFactoryAddress = _poolFactoryAddress;
        maxKeysPerPool = 600;
    }

    /**
     * @notice Returns the combined total supply of esXai Xai, and the unminted allocated tokens.
     * @dev This function fetches the total supply of esXai, Xai, and unminted allocated tokens and returns their sum.
     * @return uint256 The combined total supply of esXai, Xai, and the unminted allocated tokens.
     */
    function getCombinedTotalSupply() public view returns (uint256) {
        return esXai(esXaiAddress).totalSupply() + Xai(xaiAddress).totalSupply() + _allocatedTokens;
    }

    /**
     * @notice Toggles the assertion checking.
     */
    function toggleAssertionChecking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isCheckingAssertions = !isCheckingAssertions;
        emit AssertionCheckingToggled(isCheckingAssertions);
    }
	
    /**
     * @notice Sets the challengerPublicKey.
     * @param _challengerPublicKey The public key of the challenger.
     */
    function setChallengerPublicKey(bytes memory _challengerPublicKey) external onlyRole(DEFAULT_ADMIN_ROLE) {
        challengerPublicKey = _challengerPublicKey;
        emit ChallengerPublicKeyChanged(_challengerPublicKey);
    }

    /**
     * @notice Sets the rollupAddress.
     * @param _rollupAddress The address of the rollup.
     */
    function setRollupAddress(address _rollupAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rollupAddress = _rollupAddress;
        emit RollupAddressChanged(_rollupAddress);
    }

    /**
     * @notice Sets the nodeLicenseAddress.
     * @param _nodeLicenseAddress The address of the NodeLicense NFT.
     */
    function setNodeLicenseAddress(address _nodeLicenseAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nodeLicenseAddress = _nodeLicenseAddress;
        emit NodeLicenseAddressChanged(_nodeLicenseAddress);
    }

    /**
     * @notice Approve or remove `operator` to submit assertions on behalf of `msg.sender`.
     * @param operator The operator to be approved or removed.
     * @param approved Represents the status of the approval to be set.
     */
    function setApprovalForOperator(address operator, bool approved) external {
        if (approved) {
            _operatorApprovals[msg.sender].add(operator);
            _ownersForOperator[operator].add(msg.sender);
        } else {
            _operatorApprovals[msg.sender].remove(operator);
            _ownersForOperator[operator].remove(msg.sender);
        }
        emit Approval(msg.sender, operator, approved);
    }

    /**
     * @notice Check if `operator` is approved to submit assertions on behalf of `owner`.
     * @param owner The address of the owner.
     * @param operator The address of the operator to query.
     * @return Whether the operator is approved.
     */
    function isApprovedForOperator(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner].contains(operator);
    }

    /**
     * @notice Get the approved operator at a given index of the owner.
     * @param owner The address of the owner.
     * @param index The index of the operator to query.
     * @return The address of the operator.
     */
    function getOperatorAtIndex(address owner, uint256 index) public view returns (address) {
        require(index < getOperatorCount(owner), "2");
        return _operatorApprovals[owner].at(index);
    }

    /**
     * @notice Get the count of operators for a particular address.
     * @param owner The address of the owner.
     * @return The count of operators.
     */
    function getOperatorCount(address owner) public view returns (uint256) {
        return _operatorApprovals[owner].length();
    }

    /**
     * @notice Get the owner who has approved a specific operator at a given index.
     * @param operator The operator to query.
     * @param index The index of the owner to query.
     * @return The address of the owner.
     */
    function getOwnerForOperatorAtIndex(address operator, uint256 index) public view returns (address) {
        require(index < _ownersForOperator[operator].length(), "3");
        return _ownersForOperator[operator].at(index);
    }

    /**
     * @notice Get the count of owners for a particular operator.
     * @param operator The operator to query.
     * @return The count of owners.
     */
    function getOwnerCountForOperator(address operator) public view returns (uint256) {
        return _ownersForOperator[operator].length();
    }

    /**
     * @notice Add a wallet to the KYC'd list.
     * @param wallet The wallet to be added.
     */
    function addKycWallet(address wallet) external onlyRole(KYC_ADMIN_ROLE) {
        kycWallets.add(wallet);
        emit KycStatusChanged(wallet, true);
    }

    /**
     * @notice Remove a wallet from the KYC'd list.
     * @param wallet The wallet to be removed.
     */
    function removeKycWallet(address wallet) external onlyRole(KYC_ADMIN_ROLE) {
        kycWallets.remove(wallet);
        emit KycStatusChanged(wallet, false);
    }

    /**
     * @notice Check the KYC status of a wallet.
     * @param wallet The wallet to check.
     * @return Whether the wallet is KYC'd.
     */
    function isKycApproved(address wallet) public view returns (bool) {
        return kycWallets.contains(wallet);
    }

    /**
     * @notice Get the KYC'd wallet at a given index.
     * @param index The index of the wallet to query.
     * @return The address of the wallet.
     */
    function getKycWalletAtIndex(uint256 index) public view returns (address) {
        require(index < getKycWalletCount(), "4");
        return kycWallets.at(index);
    }

    /**
     * @notice Get the count of KYC'd wallets.
     * @return The count of KYC'd wallets.
     */
    function getKycWalletCount() public view returns (uint256) {
        return kycWallets.length();
    }

    /**
     * @notice Calculate the emission and tier for a challenge.
     * @dev This function uses a halving formula to determine the emission tier and challenge emission.
     * The formula is as follows: 
     * 1. Start with the max supply divided by 2 as the initial emission tier.
     * 2. The challenge emission is the emission tier divided by 17520.
     * 3. While the total supply is less than the emission tier, halve the emission tier and challenge emission.
     * 4. The function returns the challenge emission and the emission tier.
     * 
     * For example, if the max supply is 2,500,000,000:
     * - Tier 1: 1,250,000,000 (max supply / 2), Challenge Emission: 71,428 (emission tier / 17520)
     * - Tier 2: 625,000,000 (emission tier / 2), Challenge Emission: 35,714 (challenge emission / 2)
     * - Tier 3: 312,500,000 (emission tier / 2), Challenge Emission: 17,857 (challenge emission / 2)
     * - Tier 4: 156,250,000 (emission tier / 2), Challenge Emission: 8,928 (challenge emission / 2)
     * - Tier 5: 78,125,000 (emission tier / 2), Challenge Emission: 4,464 (challenge emission / 2)
     * 
     * @return uint256 The challenge emission.
     * @return uint256 The emission tier.
     */
    function calculateChallengeEmissionAndTier() public view returns (uint256, uint256) {

        uint256 totalSupply = getCombinedTotalSupply();
        uint256 maxSupply = Xai(xaiAddress).MAX_SUPPLY();
        require(maxSupply > totalSupply, "5");

        uint256 tier = Math.log2(maxSupply / (maxSupply - totalSupply)); // calculate which tier we are in starting from 0
        require(tier < 23, "6");

        uint256 emissionTier = maxSupply / (2**(tier + 1)); // equal to the amount of tokens that are emitted during this tier

        // determine what the size of the emission is based on each challenge having an estimated static length
        return (emissionTier / 17520, emissionTier);
    }

    /**
     * @notice Submits a challenge to the contract.
     * @dev This function verifies the caller is the challenger, checks if an assertion hasn't already been submitted for this ID,
     * gets the node information from the rollup, verifies the data inside the hash matched the data pulled from the rollup contract,
     * adds the challenge to the mapping, and emits the ChallengeSubmitted event.
     * @param _assertionId The ID of the assertion.
     * @param _predecessorAssertionId The ID of the predecessor assertion.
     * @param _confirmData The confirm data of the assertion. This will change with implementation of BOLD 2
     * @param _assertionTimestamp The timestamp of the assertion.
     * @param _challengerSignedHash The signed hash from the challenger.
     */
    function submitChallenge(
        uint64 _assertionId,
        uint64 _predecessorAssertionId,
        bytes32 _confirmData,
        uint64 _assertionTimestamp,
        bytes memory _challengerSignedHash
    ) public onlyRole(CHALLENGER_ROLE) {

        // check the rollupAddress is set
        require(rollupAddress != address(0), "7");

        // check the challengerPublicKey is set
        require(challengerPublicKey.length != 0, "8");

        // check the assertionId and rollupAddress combo haven't been submitted yet
        bytes32 comboHash = keccak256(abi.encodePacked(_assertionId, rollupAddress));
        require(!rollupAssertionTracker[comboHash], "9");
        rollupAssertionTracker[comboHash] = true;

        // verify the data inside the hash matched the data pulled from the rollup contract
        if (isCheckingAssertions) {

            // get the node information from the rollup.
            Node memory node = IRollupCore(rollupAddress).getNode(_assertionId);

            require(node.prevNum == _predecessorAssertionId, "10");
            require(node.confirmData == _confirmData, "11");
            require(node.createdAtBlock == _assertionTimestamp, "12");
        }

        // we need to determine how much token will be emitted
        (uint256 challengeEmission,) = calculateChallengeEmissionAndTier();

        // mint part of this for the gas subsidy contract
        uint256 amountForGasSubsidy = (challengeEmission * _gasSubsidyPercentage) / 100;

        // mint xai for the gas subsidy
        Xai(xaiAddress).mint(gasSubsidyRecipient, amountForGasSubsidy);

        // the remaining part of the emission should be tracked and later allocated when claimed
        uint256 rewardAmountForClaimers = challengeEmission - amountForGasSubsidy;

        // add the amount that will be given to claimers to the allocated field variable amount, so we can track how much esXai is owed
        _allocatedTokens += rewardAmountForClaimers;

        // close the previous challenge with the start of the next challenge
        if (challengeCounter > 0) {
            challenges[challengeCounter - 1].openForSubmissions = false;
            emit ChallengeClosed(challengeCounter - 1);
        }

        // add challenge to the mapping
        challenges[challengeCounter] = Challenge({
            openForSubmissions: true,
            expiredForRewarding: false,
            assertionId: _assertionId,
            assertionStateRootOrConfirmData: _confirmData,
            assertionTimestamp: _assertionTimestamp,
            challengerSignedHash: _challengerSignedHash,
            activeChallengerPublicKey: challengerPublicKey, // Store the active challengerPublicKey at the time of challenge submission
            rollupUsed: rollupAddress, // Store the rollup address used for this challenge
            createdTimestamp: block.timestamp,
            totalSupplyOfNodesAtChallengeStart: NodeLicense(nodeLicenseAddress).totalSupply(), // we need to store how many nodes were created for the 1% odds
            rewardAmountForClaimers: rewardAmountForClaimers,
            amountForGasSubsidy: amountForGasSubsidy,
            numberOfEligibleClaimers: 0,
            amountClaimedByClaimers: 0
        });

        // emit the events
        emit ChallengeSubmitted(challengeCounter);   

        // increment the challenge counter
        challengeCounter++;
    }

    /**
     * @notice A public view function to look up challenges.
     * @param _challengeId The ID of the challenge to look up.
     * @return The challenge corresponding to the given ID.
     */
    function getChallenge(uint256 _challengeId) public view returns (Challenge memory) {
        require(_challengeId < challengeCounter, "13");
        return challenges[_challengeId];
    }

    /**
     * @notice Submits an assertion to a challenge.
     * @dev This function can only be called by the owner of a NodeLicense or addresses they have approved on this contract.
     * @param _nodeLicenseId The ID of the NodeLicense.
     */
    function submitAssertionToChallenge(
        uint256 _nodeLicenseId,
        uint256 _challengeId,
        bytes memory _confirmData
    ) public {

        // Check the challenge is open for submissions
        require(challenges[_challengeId].openForSubmissions, "14");
        
        // Check that _nodeLicenseId hasn't already been submitted for this challenge
        require(!submissions[_challengeId][_nodeLicenseId].submitted, "15");

        // If the submission successor hash, doesn't match the one submitted by the challenger, then end early and emit an event
        if (keccak256(abi.encodePacked(_confirmData)) != keccak256(abi.encodePacked(challenges[_challengeId].assertionStateRootOrConfirmData))) {
            emit InvalidSubmission(_challengeId, _nodeLicenseId);
            return;
        }

        address licenseOwner = NodeLicense(nodeLicenseAddress).ownerOf(_nodeLicenseId);
        address assignedPool = assignedKeyToPool[_nodeLicenseId];
        
        require(isValidOperator(licenseOwner, assignedPool), "17");

        _submitAssertion(_nodeLicenseId, _challengeId, _confirmData, licenseOwner, assignedPool);
    }

	function submitMultipleAssertions(
		uint256[] memory _nodeLicenseIds,
		uint256 _challengeId,
		bytes memory _confirmData
	) external {
        
		require(challenges[_challengeId].openForSubmissions, "16");
        
        uint256 keyLength = _nodeLicenseIds.length;

		if (keccak256(abi.encodePacked(_confirmData)) != keccak256(abi.encodePacked(challenges[_challengeId].assertionStateRootOrConfirmData))) {
            emit InvalidBatchSubmission(_challengeId, msg.sender, keyLength);
			return;
		}

		for (uint256 i = 0; i < keyLength; i++) {
            uint256 _nodeLicenseId = _nodeLicenseIds[i];
            if (!submissions[_challengeId][_nodeLicenseId].submitted) {
                
                address licenseOwner = NodeLicense(nodeLicenseAddress).ownerOf(_nodeLicenseId);
                address assignedPool = assignedKeyToPool[_nodeLicenseId];

                if(isValidOperator(licenseOwner, assignedPool)){
                    _submitAssertion(_nodeLicenseId, _challengeId, _confirmData, licenseOwner, assignedPool);
                }
            }
		}
	}

    function isValidOperator(address licenseOwner, address assignedPool) internal view returns (bool) {
        return licenseOwner == msg.sender ||
            isApprovedForOperator(licenseOwner, msg.sender) ||
            (
                assignedPool != address(0) &&
                PoolFactory(poolFactoryAddress).isDelegateOfPoolOrOwner(msg.sender, assignedPool)
            );
    }
    
    function _submitAssertion(uint256 _nodeLicenseId, uint256 _challengeId, bytes memory _confirmData, address licenseOwner, address assignedPool) internal {
        
        // Support v1 (no pools) & v2 (pools)
		uint256 stakedAmount = stakedAmounts[assignedPool];
		if (assignedPool == address(0)) {
			stakedAmount = stakedAmounts[licenseOwner];
			uint256 ownerUnstakedAmount = NodeLicense(nodeLicenseAddress).balanceOf(licenseOwner) - assignedKeysOfUserCount[licenseOwner];
			if (ownerUnstakedAmount * maxStakeAmountPerLicense < stakedAmount) {
				stakedAmount = ownerUnstakedAmount * maxStakeAmountPerLicense;
			}
		} else {
			if (assignedKeysToPoolCount[assignedPool] * maxStakeAmountPerLicense < stakedAmount) {
				stakedAmount = assignedKeysToPoolCount[assignedPool] * maxStakeAmountPerLicense;
			}
		}

        // Check the user is actually eligible for receiving a reward, do not count them in numberOfEligibleClaimers if they are not able to receive a reward
        (bool hashEligible, ) = createAssertionHashAndCheckPayout(_nodeLicenseId, _challengeId, _getBoostFactor(stakedAmount), _confirmData, challenges[_challengeId].challengerSignedHash);

        // Store the assertionSubmission to a map
        submissions[_challengeId][_nodeLicenseId] = Submission({
            submitted: true,
            claimed: false,
            eligibleForPayout: hashEligible,
            nodeLicenseId: _nodeLicenseId,
            assertionStateRootOrConfirmData: _confirmData
        });

        // Keep track of how many submissions submitted were eligible for the reward
        if (hashEligible) {
            challenges[_challengeId].numberOfEligibleClaimers++;
        }

        // Emit the AssertionSubmitted event
        emit AssertionSubmitted(_challengeId, _nodeLicenseId);
    }

    /**
     * @notice Claims a reward for a successful assertion.
     * @dev This function looks up the submission, checks if the challenge is closed for submissions, and if valid for a payout, sends a reward.
     * @param _nodeLicenseId The ID of the NodeLicense.
     * @param _challengeId The ID of the challenge.
     */
    function claimReward(
        uint256 _nodeLicenseId,
        uint256 _challengeId
    ) public {
        Challenge memory challengeToClaimFor  = challenges[_challengeId];
        // check the challenge exists by checking the timestamp is not 0
        require(challengeToClaimFor.createdTimestamp != 0, "18");
        // Check if the challenge is closed for submissions
        require(!challengeToClaimFor.openForSubmissions, "19");
        // expire the challenge if 180 days old
        if (block.timestamp >= challengeToClaimFor.createdTimestamp + 180 days) {
            expireChallengeRewards(_challengeId);
            return;
        }
        // Check if the challenge rewards have expired
        require(!challengeToClaimFor.expiredForRewarding, "20");

        // Get the minting timestamp of the nodeLicenseId
        uint256 mintTimestamp = NodeLicense(nodeLicenseAddress).getMintTimestamp(_nodeLicenseId);

        // Check if the nodeLicenseId is eligible for a payout
        require(mintTimestamp < challengeToClaimFor.createdTimestamp, "21");

        // Look up the submission
        Submission memory submission = submissions[_challengeId][_nodeLicenseId];

        // Check if the owner of the NodeLicense is KYC'd
        address owner = NodeLicense(nodeLicenseAddress).ownerOf(_nodeLicenseId);
        require(isKycApproved(owner), "22");

        // Check if the submission has already been claimed
        require(!submission.claimed, "23");

        require(submission.eligibleForPayout, "24");

        // Take the amount that was allocated for the rewards and divide it by the number of claimers
        uint256 reward = challengeToClaimFor.rewardAmountForClaimers / challengeToClaimFor.numberOfEligibleClaimers;

        // mark the submission as claimed
        submissions[_challengeId][_nodeLicenseId].claimed = true;

        // increment the amount claimed on the challenge
        challenges[_challengeId].amountClaimedByClaimers += reward;

        address rewardReceiver = assignedKeyToPool[_nodeLicenseId];
        if (rewardReceiver == address(0)) {
            rewardReceiver = owner;
        }

        // Mint the reward to the owner of the nodeLicense
        esXai(esXaiAddress).mint(rewardReceiver, reward);

        // Emit the RewardsClaimed event
        emit RewardsClaimed(_challengeId, reward);

        // Increment the total claims of this address
        _lifetimeClaims[rewardReceiver] += reward;

        // unallocate the tokens that have now been converted to esXai
        _allocatedTokens -= reward;
    }

	function claimMultipleRewards(
		uint256[] memory _nodeLicenseIds,
		uint256 _challengeId,
        address claimForAddressInBatch
	) external {
        
        Challenge memory challengeToClaimFor  = challenges[_challengeId];
        // check the challenge exists by checking the timestamp is not 0
        require(challengeToClaimFor.createdTimestamp != 0, "25");
        // Check if the challenge is closed for submissions
        require(!challengeToClaimFor.openForSubmissions, "26");
        // expire the challenge if 180 days old
        if (block.timestamp >= challengeToClaimFor.createdTimestamp + 180 days) {
            expireChallengeRewards(_challengeId);
            return;
        }

        // Check if the challenge rewards have expired
        require(!challengeToClaimFor.expiredForRewarding, "27");

        uint256 reward = challengeToClaimFor.rewardAmountForClaimers / challengeToClaimFor.numberOfEligibleClaimers;
        uint256 keyLength = _nodeLicenseIds.length;
        uint256 claimCount = 0;
        uint256 poolMintAmount = 0;

		for (uint256 i = 0; i < keyLength; i++) {
            uint256 _nodeLicenseId = _nodeLicenseIds[i];

            uint256 mintTimestamp = NodeLicense(nodeLicenseAddress).getMintTimestamp(_nodeLicenseId);
            address owner = NodeLicense(nodeLicenseAddress).ownerOf(_nodeLicenseId);
            Submission memory submission = submissions[_challengeId][_nodeLicenseId];

            // Check if the nodeLicenseId is eligible for a payout
            if (
                isKycApproved(owner) &&
                mintTimestamp < challengeToClaimFor.createdTimestamp && 
                !submission.claimed &&
                submission.eligibleForPayout
            ) {
                // mark the submission as claimed
                submissions[_challengeId][_nodeLicenseId].claimed = true;

                // increment the amount claimed on the challenge
                challenges[_challengeId].amountClaimedByClaimers += reward;
                
                address rewardReceiver = assignedKeyToPool[_nodeLicenseId];
                if (rewardReceiver == address(0)) {
                    rewardReceiver = owner;
                }

                //If we have set the poolAddress we will only claim if the license is staked to that pool
                if (claimForAddressInBatch != address(0) && rewardReceiver == claimForAddressInBatch) {
                    poolMintAmount += reward;
                } else {
                    // Mint the reward to the owner of the nodeLicense
                    esXai(esXaiAddress).mint(rewardReceiver, reward);
                    _lifetimeClaims[rewardReceiver] += reward;
                }

                claimCount++;
            }
		}

        if (poolMintAmount > 0) {
            esXai(esXaiAddress).mint(claimForAddressInBatch, poolMintAmount);
            _lifetimeClaims[claimForAddressInBatch] += poolMintAmount;
        }
        
        _allocatedTokens -= claimCount * reward;
        emit BatchRewardsClaimed(_challengeId, claimCount * reward, claimCount);
	}

    /**
     * @notice Creates an assertion hash and determines if the hash payout is below the threshold.
     * @dev This function creates a hash of the _nodeLicenseId, _challengeId, challengerSignedHash from the challenge, and _newStateRoot.
     * It then converts the hash to a number and checks if it is below the threshold.
     * The threshold is calculated as the maximum uint256 value divided by 100 and then multiplied by the total supply of NodeLicenses.
     * @param _nodeLicenseId The ID of the NodeLicense.
     * @param _challengeId The ID of the challenge.
     * @param _boostFactor The factor controlling the chance of eligibility for payout as a multiplicator (base chance is 1/100 - Example: _boostFactor 200 will double the payout chance to 1/50, _boostFactor 16 maps to 1/6.25).
     * @param _confirmData The confirm hash, will change to assertionState after BOLD.
     * @param _challengerSignedHash The signed hash for the challenge
     * @return a boolean indicating if the hash is eligible, and the assertionHash.
     */
    function createAssertionHashAndCheckPayout(
        uint256 _nodeLicenseId,
        uint256 _challengeId,
        uint256 _boostFactor,
        bytes memory _confirmData,
        bytes memory _challengerSignedHash
    ) public pure returns (bool, bytes32) {

        bytes32 assertionHash = keccak256(abi.encodePacked(_nodeLicenseId, _challengeId, _confirmData, _challengerSignedHash));
        uint256 hashNumber = uint256(assertionHash);
        // hashNumber % 10_000 equals {0...9999}
        // hashNumber % 10_000 < 100 means a 100 / 10000 = 1 /100
        return (hashNumber % 10_000 < _boostFactor, assertionHash);
    }

    /**
     * @notice Returns the submissions for a given array of challenges and a NodeLicense.
     * @param _challengeIds An array of challenge IDs.
     * @param _nodeLicenseId The ID of the NodeLicense.
     * @return An array of submissions for the given challenges and NodeLicense.
     */
    function getSubmissionsForChallenges(uint256[] memory _challengeIds, uint256 _nodeLicenseId) public view returns (Submission[] memory) {
        Submission[] memory submissionsArray = new Submission[](_challengeIds.length);
        for (uint i = 0; i < _challengeIds.length; i++) {
            submissionsArray[i] = submissions[_challengeIds[i]][_nodeLicenseId];
        }
        return submissionsArray;
    }

    /**
     * @notice Expires the rewards for a challenge if it is at least 180 days old.
     * @param _challengeId The ID of the challenge.
     */
    function expireChallengeRewards(uint256 _challengeId) public {
        // check the challenge exists by checking the timestamp is not 0
        require(challenges[_challengeId].createdTimestamp != 0, "28");

        // Check if the challenge is at least 180 days old
        require(block.timestamp >= challenges[_challengeId].createdTimestamp + 180 days, "29");

        // Check the challenge isn't already expired
        require(challenges[_challengeId].expiredForRewarding == false, "30");

        // Remove the unclaimed tokens from the allocation
        _allocatedTokens -= challenges[_challengeId].rewardAmountForClaimers - challenges[_challengeId].amountClaimedByClaimers;

        // Set expiredForRewarding to true
        challenges[_challengeId].expiredForRewarding = true;

        // Emit the ChallengeExpired event
        emit ChallengeExpired(_challengeId);
    }

    /**
     * @notice Get the total claims for a specific address.
     * @param owner The address to query.
     * @return The total claims for the address.
     */
    function getTotalClaims(address owner) public view returns (uint256) {
        return _lifetimeClaims[owner];
    }

    /**
     * @dev Looks up payout boostFactor based on the staking tier.
     * @param stakedAmount The staked amount.
     * @return The payout chance boostFactor. 200 for double the chance.
     */
    function _getBoostFactor(uint256 stakedAmount) internal view returns (uint256) {
        if (stakedAmount < stakeAmountTierThresholds[0]) {
            return 100;
        }

        uint256 length = stakeAmountTierThresholds.length;
        for (uint256 tier = 1; tier < length; tier++) {
            if (stakedAmount < stakeAmountTierThresholds[tier]) {
                return stakeAmountBoostFactors[tier - 1];
            }
        }
        return stakeAmountBoostFactors[length - 1];
    }
    
    /**
     * @notice Enables staking on the Referee.
     */
    function enableStaking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingEnabled = true;
        emit StakingEnabled();
    }
    
    /**
     * @dev Admin update the maximum staking amount per NodeLicense
     * @param newAmount The new maximum amount per NodeLicense
     */
    function updateMaxStakePerLicense(uint256 newAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAmount != 0, "31");
        uint256 prevAmount = maxStakeAmountPerLicense;
        maxStakeAmountPerLicense = newAmount;
        emit UpdateMaxStakeAmount(prevAmount, newAmount);
    }
    
    /**
     * @dev Admin update the maximum number of NodeLicense staked in a pool
     * @param newAmount The new maximum amount per NodeLicense
     */
    function updateMaxKeysPerPool(uint256 newAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAmount != 0, "32");
        uint256 prevAmount = maxKeysPerPool;
        maxKeysPerPool = newAmount;
        emit UpdateMaxKeysPerPool(prevAmount, newAmount);
    }

    /**
     * @dev Admin update the tier thresholds and the corresponding reward chance boost
     * @param index The index if the tier to update
     * @param newThreshold The new threshold of the tier
     * @param newBoostFactor The new boost factor for the tier
     */
    function updateStakingTier(uint256 index, uint256 newThreshold, uint256 newBoostFactor) external onlyRole(DEFAULT_ADMIN_ROLE) {

        require(newBoostFactor > 0 && newBoostFactor <= 100, "33");

        uint256 lastIndex = stakeAmountTierThresholds.length - 1;
        if (index == 0) {
            require(stakeAmountTierThresholds[1] > newThreshold, "34");
        } else if (index == lastIndex) {
            require(stakeAmountTierThresholds[lastIndex - 1] < newThreshold, "35");
        } else {
            require(stakeAmountTierThresholds[index + 1] > newThreshold && stakeAmountTierThresholds[index - 1] < newThreshold, "36");
        }

        stakeAmountTierThresholds[index] = newThreshold;
        stakeAmountBoostFactors[index] = newBoostFactor;
    }

    /**
     * @dev Admin add a new staking tier to the end of the tier array
     * @param newThreshold The new threshold of the tier
     * @param newBoostFactor The new boost factor for the tier
     */
    function addStakingTier(uint256 newThreshold, uint256 newBoostFactor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newBoostFactor > 0 && newBoostFactor <= 100, "37");

        uint256 lastIndex = stakeAmountTierThresholds.length - 1;
        require(stakeAmountTierThresholds[lastIndex] < newThreshold, "38");

        stakeAmountTierThresholds.push(newThreshold);
        stakeAmountBoostFactors.push(newBoostFactor);
    }

    /**
     * @dev Admin remove a staking tier
     * @param index The index if the tier to remove
     */
    function removeStakingTier(uint256 index) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(stakeAmountTierThresholds.length > 1, "39");
        require(index < stakeAmountTierThresholds.length, "40");
        for (uint i = index; i < stakeAmountTierThresholds.length - 1; i++) {
            stakeAmountTierThresholds[i] = stakeAmountTierThresholds[i + 1];
            stakeAmountBoostFactors[i] = stakeAmountBoostFactors[i + 1];
        }
        stakeAmountTierThresholds.pop();
        stakeAmountBoostFactors.pop();
    }

    /**
     * @dev Looks up payout boostFactor based on the staking tier for a staker wallet.
     * @param staker The address of the staker or pool.
     * @return The payout chance boostFactor based on max stake capacity or staked amount.
     */
    function getBoostFactorForStaker(address staker) external view returns (uint256) {

        uint256 stakedAmount = stakedAmounts[staker];

        if(PoolFactory(poolFactoryAddress).poolsCreatedViaFactory(staker)){
			if (assignedKeysToPoolCount[staker] * maxStakeAmountPerLicense < stakedAmount) {
				stakedAmount = assignedKeysToPoolCount[staker] * maxStakeAmountPerLicense;
			}
        }else{			
			uint256 ownerUnstakedAmount = NodeLicense(nodeLicenseAddress).balanceOf(staker) - assignedKeysOfUserCount[staker];
			if (ownerUnstakedAmount * maxStakeAmountPerLicense < stakedAmount) {
				stakedAmount = ownerUnstakedAmount * maxStakeAmountPerLicense;
			}
        }

        return _getBoostFactor(stakedAmount);
    }

    /**
     * @dev Function that lets a user unstake V1 esXai that have previously been staked.
     * @param amount The amount of esXai to unstake.
     */
    function unstake(uint256 amount) external {
        require(stakedAmounts[msg.sender] >= amount, "41");
        esXai(esXaiAddress).transfer(msg.sender, amount);
        stakedAmounts[msg.sender] -= amount;
        emit UnstakeV1(msg.sender, amount, stakedAmounts[msg.sender]);
    }

    function stakeKeys(address pool, address staker, uint256[] memory keyIds) external onlyPoolFactory {
		require(isKycApproved(staker), "42");
        uint256 keysLength = keyIds.length;
        require(assignedKeysToPoolCount[pool] + keysLength <= maxKeysPerPool, "43");

        NodeLicense nodeLicenseContract = NodeLicense(nodeLicenseAddress);
        for (uint256 i = 0; i < keysLength; i++) {
            uint256 keyId = keyIds[i];
            require(assignedKeyToPool[keyId] == address(0), "44");
            require(nodeLicenseContract.ownerOf(keyId) == staker, "45");
            assignedKeyToPool[keyId] = pool;
        }

        assignedKeysToPoolCount[pool] += keysLength;
        assignedKeysOfUserCount[staker] += keysLength;
    }

    function unstakeKeys(address pool, address staker, uint256[] memory keyIds) external onlyPoolFactory {
        uint256 keysLength = keyIds.length;
        NodeLicense nodeLicenseContract = NodeLicense(nodeLicenseAddress);

        for (uint256 i = 0; i < keysLength; i++) {
            uint256 keyId = keyIds[i];
            require(assignedKeyToPool[keyId] == pool, "47");
            require(nodeLicenseContract.ownerOf(keyId) == staker, "48");
            assignedKeyToPool[keyId] = address(0);
        }
        assignedKeysToPoolCount[pool] -= keysLength;
        assignedKeysOfUserCount[staker] -= keysLength;
    }

    function stakeEsXai(address pool, uint256 amount) external onlyPoolFactory {
        uint256 maxStakedAmount = maxStakeAmountPerLicense * assignedKeysToPoolCount[pool];
        require(stakedAmounts[pool] + amount <= maxStakedAmount, "49");
        stakedAmounts[pool] += amount;
    }

    function unstakeEsXai(address pool, uint256 amount) external onlyPoolFactory {
        require(stakedAmounts[pool] >= amount, "50");
        stakedAmounts[pool] -= amount;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../nitro-contracts/rollup/IRollupCore.sol";
import "../../NodeLicense.sol";
import "../../Xai.sol";
import "../../esXai.sol";
import "../../staking-v2/PoolFactory.sol";

// Error Codes
// 1: Only PoolFactory can call this function.
// 2: Index out of bounds.
// 3: Index out of bounds.
// 4: Index out of bounds.
// 5: There are no more tiers, we are too close to the end.
// 6: There are no more accurate tiers.
// 7: Rollup address must be set before submitting a challenge.
// 8: Challenger public key must be set before submitting a challenge.
// 9: This assertionId and rollupAddress combo has already been submitted.
// 10: The _predecessorAssertionId is incorrect.
// 11: The _confirmData is incorrect.
// 12: The _assertionTimestamp did not match the block this assertion was created at.
// 13: Challenge with this id has not been created.
// 14: Challenge is not open for submissions.
// 15: _nodeLicenseId has already been submitted for this challenge.
// 16: Challenge is not open for submissions.
// 17: Caller must be the owner of the NodeLicense, an approved operator, or the delegator owner of the pool.
// 18: The Challenge does not exist for this id.
// 19: Challenge is still open for submissions.
// 20: Challenge rewards have expired.
// 21: NodeLicense is not eligible for a payout on this challenge, it was minted after it started.
// 22: Owner of the NodeLicense is not KYC'd.
// 23: This submission has already been claimed.
// 24: Not valid for a payout.
// 25: The Challenge does not exist for this id.
// 26: Challenge is still open for submissions.
// 27: Challenge rewards have expired.
// 28: The Challenge does not exist for this id.
// 29: Challenge is not old enough to expire rewards.
// 30: The challenge is already expired.
// 31: Invalid max amount.
// 32: Invalid max amount.
// 33: Invalid boost factor.
// 34: Threshold needs to be monotonically increasing.
// 35: Threshold needs to be monotonically increasing.
// 36: Threshold needs to be monotonically increasing.
// 37: Invalid boost factor.
// 38: Threshold needs to be monotonically increasing.
// 39: Cannot remove last tier.
// 40: Index out of bounds.
// 41: Insufficient amount staked.
// 42: Must complete KYC.
// 43: Maximum staking amount exceeded.
// 44: Key already assigned.
// 45: Not owner of key.
// 46: Pool owner needs at least 1 staked key.
// 47: Key not assigned to pool.
// 48: Not owner of key.
// 49: Maximum staking amount exceeded.
// 50: Invalid amount.

contract Referee7 is Initializable, AccessControlEnumerableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // Define roles
    bytes32 public constant CHALLENGER_ROLE = keccak256("CHALLENGER_ROLE");
    bytes32 public constant KYC_ADMIN_ROLE = keccak256("KYC_ADMIN_ROLE");

    // The Challenger's public key of their registered BLS-Pair
    bytes public challengerPublicKey;

    // the address of the rollup, so we can get assertions
    address public rollupAddress;

    // the address of the NodeLicense NFT
    address public nodeLicenseAddress;

    // contract addresses for esXai and xai
    address public esXaiAddress;
    address public xaiAddress;

    // Counter for the challenges
    uint256 public challengeCounter;

    // This is the address where we sent the Xai emission to for the gas subsidy
    address public gasSubsidyRecipient;

    // mapping to store all of the challenges
    mapping(uint256 => Challenge) public challenges;

    // Mapping to store all of the submissions
    mapping(uint256 => mapping(uint256 => Submission)) public submissions;

    // Toggle for assertion checking
    bool public isCheckingAssertions;

    // Mapping from owner to operator approvals
    mapping (address => EnumerableSetUpgradeable.AddressSet) private _operatorApprovals;

    // Mapping from operator to owners
    mapping (address => EnumerableSetUpgradeable.AddressSet) private _ownersForOperator;

    // Mappings to keep track of all claims
    mapping (address => uint256) private _lifetimeClaims;

    // Mapping to track rollup assertions (combination of the assertionId and the rollupAddress used, because we allow switching the rollupAddress, and can't assume assertionIds are unique.)
    mapping (bytes32 => bool) public rollupAssertionTracker;

    // Mapping to track KYC'd wallets
    EnumerableSetUpgradeable.AddressSet private kycWallets;

    // This value keeps track of how many token are not yet minted but are allocated by the referee. This should be used in calculating the total supply for emissions
    uint256 private _allocatedTokens;

    // This is the percentage of each challenge emission to be given to the gas subsidy. Should be a whole number like 15% = 15
    uint256 private _gasSubsidyPercentage;

    // Mapping for users staked amount in V1 staking
    mapping(address => uint256) public stakedAmounts;

    // Minimum amounts of staked esXai to be in the tier of the respective index
    uint256[] public stakeAmountTierThresholds;

    // Reward chance boost factor based on tier of the respective index
    uint256[] public stakeAmountBoostFactors;

    // The maximum amount of esXai (in wei) that can be staked per NodeLicense
    uint256 public maxStakeAmountPerLicense;
    
    // Enabling staking on the Referee
    bool public stakingEnabled;

    // Mapping for a key id assigned to a staking pool
    mapping(uint256 => address) public assignedKeyToPool;

    // Mapping for pool to assigned key count for calculating max stake amount
    mapping(address => uint256) public assignedKeysToPoolCount;

    // The maximum number of NodeLicenses that can be staked to a pool
    uint256 public maxKeysPerPool;

    // The pool factory contract that is allowed to update the stake state of the Referee
    address public poolFactoryAddress;
    
    // Mapping for amount of assigned keys of a user
    mapping(address => uint256) public assignedKeysOfUserCount;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[490] private __gap;

    // Struct for the submissions
    struct Submission {
        bool submitted;
        bool claimed;
        bool eligibleForPayout;
        uint256 nodeLicenseId;
        bytes assertionStateRootOrConfirmData;
    }

    // Struct for the challenges
    struct Challenge {
        bool openForSubmissions; // when the next challenge is submitted for the following assertion, this will be closed.
        bool expiredForRewarding; // when this is true, this challenge is no longer eligible for claiming
        uint64 assertionId;
        bytes32 assertionStateRootOrConfirmData; // Depending on the BOLD 2 deployment, this will either be the assertionStateRoot or ConfirmData
        uint64 assertionTimestamp; // equal to the block number the assertion was made on in the rollup protocol
        bytes challengerSignedHash;
        bytes activeChallengerPublicKey; // The challengerPublicKey that was active at the time of challenge submission
        address rollupUsed; // The rollup address used for this challenge
        uint256 createdTimestamp; // used to determine if a node license is eligible to submit
        uint256 totalSupplyOfNodesAtChallengeStart; // keep track of what the total supply opf nodes is when the challenge starts
        uint256 rewardAmountForClaimers; // this is how much esXai should be allocated to the claimers
        uint256 amountForGasSubsidy; // this is how much Xai was minted for the gas subsidy
        uint256 numberOfEligibleClaimers; // how many submitters are eligible for claiming, used to determine the reward amount
        uint256 amountClaimedByClaimers; // keep track of how much Xai has been claimed by the claimers, primarily used to expire unclaimed rewards 
    }

    // Define events
    event ChallengeSubmitted(uint256 indexed challengeNumber);
    event ChallengeClosed(uint256 indexed challengeNumber);
    event AssertionSubmitted(uint256 indexed challengeId, uint256 indexed nodeLicenseId);
    event RollupAddressChanged(address newRollupAddress);
    event ChallengerPublicKeyChanged(bytes newChallengerPublicKey);
    event NodeLicenseAddressChanged(address newNodeLicenseAddress);
    event AssertionCheckingToggled(bool newState);
    event Approval(address indexed owner, address indexed operator, bool approved);
    event KycStatusChanged(address indexed wallet, bool isKycApproved);
    event InvalidSubmission(uint256 indexed challengeId, uint256 nodeLicenseId);
    event InvalidBatchSubmission(uint256 indexed challengeId, address operator, uint256 keysLength);
    event RewardsClaimed(uint256 indexed challengeId, uint256 amount);
    event BatchRewardsClaimed(uint256 indexed challengeId, uint256 totalReward, uint256 keysLength);
    event ChallengeExpired(uint256 indexed challengeId);
    event StakingEnabled();
    event UpdateMaxStakeAmount(uint256 prevAmount, uint256 newAmount);
    event UpdateMaxKeysPerPool(uint256 prevAmount, uint256 newAmount);
    event StakedV1(address indexed user, uint256 amount, uint256 totalStaked);
    event UnstakeV1(address indexed user, uint256 amount, uint256 totalStaked);

    modifier onlyPoolFactory() {
        require(msg.sender == poolFactoryAddress, "1");
        _;
    }

    /**
     * @notice Returns the combined total supply of esXai Xai, and the unminted allocated tokens.
     * @dev This function fetches the total supply of esXai, Xai, and unminted allocated tokens and returns their sum.
     * @return uint256 The combined total supply of esXai, Xai, and the unminted allocated tokens.
     */
    function getCombinedTotalSupply() public view returns (uint256) {
        return esXai(esXaiAddress).totalSupply() + Xai(xaiAddress).totalSupply() + _allocatedTokens;
    }

    /**
     * @notice Toggles the assertion checking.
     */
    function toggleAssertionChecking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isCheckingAssertions = !isCheckingAssertions;
        emit AssertionCheckingToggled(isCheckingAssertions);
    }
	
    /**
     * @notice Sets the challengerPublicKey.
     * @param _challengerPublicKey The public key of the challenger.
     */
    function setChallengerPublicKey(bytes memory _challengerPublicKey) external onlyRole(DEFAULT_ADMIN_ROLE) {
        challengerPublicKey = _challengerPublicKey;
        emit ChallengerPublicKeyChanged(_challengerPublicKey);
    }

    /**
     * @notice Sets the rollupAddress.
     * @param _rollupAddress The address of the rollup.
     */
    function setRollupAddress(address _rollupAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rollupAddress = _rollupAddress;
        emit RollupAddressChanged(_rollupAddress);
    }

    /**
     * @notice Sets the nodeLicenseAddress.
     * @param _nodeLicenseAddress The address of the NodeLicense NFT.
     */
    function setNodeLicenseAddress(address _nodeLicenseAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nodeLicenseAddress = _nodeLicenseAddress;
        emit NodeLicenseAddressChanged(_nodeLicenseAddress);
    }

    /**
     * @notice Approve or remove `operator` to submit assertions on behalf of `msg.sender`.
     * @param operator The operator to be approved or removed.
     * @param approved Represents the status of the approval to be set.
     */
    function setApprovalForOperator(address operator, bool approved) external {
        if (approved) {
            _operatorApprovals[msg.sender].add(operator);
            _ownersForOperator[operator].add(msg.sender);
        } else {
            _operatorApprovals[msg.sender].remove(operator);
            _ownersForOperator[operator].remove(msg.sender);
        }
        emit Approval(msg.sender, operator, approved);
    }

    /**
     * @notice Check if `operator` is approved to submit assertions on behalf of `owner`.
     * @param owner The address of the owner.
     * @param operator The address of the operator to query.
     * @return Whether the operator is approved.
     */
    function isApprovedForOperator(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner].contains(operator);
    }

    /**
     * @notice Get the approved operator at a given index of the owner.
     * @param owner The address of the owner.
     * @param index The index of the operator to query.
     * @return The address of the operator.
     */
    function getOperatorAtIndex(address owner, uint256 index) public view returns (address) {
        require(index < getOperatorCount(owner), "2");
        return _operatorApprovals[owner].at(index);
    }

    /**
     * @notice Get the count of operators for a particular address.
     * @param owner The address of the owner.
     * @return The count of operators.
     */
    function getOperatorCount(address owner) public view returns (uint256) {
        return _operatorApprovals[owner].length();
    }

    /**
     * @notice Get the owner who has approved a specific operator at a given index.
     * @param operator The operator to query.
     * @param index The index of the owner to query.
     * @return The address of the owner.
     */
    function getOwnerForOperatorAtIndex(address operator, uint256 index) public view returns (address) {
        require(index < _ownersForOperator[operator].length(), "3");
        return _ownersForOperator[operator].at(index);
    }

    /**
     * @notice Get the count of owners for a particular operator.
     * @param operator The operator to query.
     * @return The count of owners.
     */
    function getOwnerCountForOperator(address operator) public view returns (uint256) {
        return _ownersForOperator[operator].length();
    }

    /**
     * @notice Add a wallet to the KYC'd list.
     * @param wallet The wallet to be added.
     */
    function addKycWallet(address wallet) external onlyRole(KYC_ADMIN_ROLE) {
        kycWallets.add(wallet);
        emit KycStatusChanged(wallet, true);
    }

    /**
     * @notice Remove a wallet from the KYC'd list.
     * @param wallet The wallet to be removed.
     */
    function removeKycWallet(address wallet) external onlyRole(KYC_ADMIN_ROLE) {
        kycWallets.remove(wallet);
        emit KycStatusChanged(wallet, false);
    }

    /**
     * @notice Check the KYC status of a wallet.
     * @param wallet The wallet to check.
     * @return Whether the wallet is KYC'd.
     */
    function isKycApproved(address wallet) public view returns (bool) {
        return kycWallets.contains(wallet);
    }

    /**
     * @notice Get the KYC'd wallet at a given index.
     * @param index The index of the wallet to query.
     * @return The address of the wallet.
     */
    function getKycWalletAtIndex(uint256 index) public view returns (address) {
        require(index < getKycWalletCount(), "4");
        return kycWallets.at(index);
    }

    /**
     * @notice Get the count of KYC'd wallets.
     * @return The count of KYC'd wallets.
     */
    function getKycWalletCount() public view returns (uint256) {
        return kycWallets.length();
    }

    /**
     * @notice Calculate the emission and tier for a challenge.
     * @dev This function uses a halving formula to determine the emission tier and challenge emission.
     * The formula is as follows: 
     * 1. Start with the max supply divided by 2 as the initial emission tier.
     * 2. The challenge emission is the emission tier divided by 17520.
     * 3. While the total supply is less than the emission tier, halve the emission tier and challenge emission.
     * 4. The function returns the challenge emission and the emission tier.
     * 
     * For example, if the max supply is 2,500,000,000:
     * - Tier 1: 1,250,000,000 (max supply / 2), Challenge Emission: 71,428 (emission tier / 17520)
     * - Tier 2: 625,000,000 (emission tier / 2), Challenge Emission: 35,714 (challenge emission / 2)
     * - Tier 3: 312,500,000 (emission tier / 2), Challenge Emission: 17,857 (challenge emission / 2)
     * - Tier 4: 156,250,000 (emission tier / 2), Challenge Emission: 8,928 (challenge emission / 2)
     * - Tier 5: 78,125,000 (emission tier / 2), Challenge Emission: 4,464 (challenge emission / 2)
     * 
     * @return uint256 The challenge emission.
     * @return uint256 The emission tier.
     */
    function calculateChallengeEmissionAndTier() public view returns (uint256, uint256) {

        uint256 totalSupply = getCombinedTotalSupply();
        uint256 maxSupply = Xai(xaiAddress).MAX_SUPPLY();
        require(maxSupply > totalSupply, "5");

        uint256 tier = Math.log2(maxSupply / (maxSupply - totalSupply)); // calculate which tier we are in starting from 0
        require(tier < 23, "6");

        uint256 emissionTier = maxSupply / (2**(tier + 1)); // equal to the amount of tokens that are emitted during this tier

        // determine what the size of the emission is based on each challenge having an estimated static length
        return (emissionTier / 17520, emissionTier);
    }

    /**
     * @notice Submits a challenge to the contract.
     * @dev This function verifies the caller is the challenger, checks if an assertion hasn't already been submitted for this ID,
     * gets the node information from the rollup, verifies the data inside the hash matched the data pulled from the rollup contract,
     * adds the challenge to the mapping, and emits the ChallengeSubmitted event.
     * @param _assertionId The ID of the assertion.
     * @param _predecessorAssertionId The ID of the predecessor assertion.
     * @param _confirmData The confirm data of the assertion. This will change with implementation of BOLD 2
     * @param _assertionTimestamp The timestamp of the assertion.
     * @param _challengerSignedHash The signed hash from the challenger.
     */
    function submitChallenge(
        uint64 _assertionId,
        uint64 _predecessorAssertionId,
        bytes32 _confirmData,
        uint64 _assertionTimestamp,
        bytes memory _challengerSignedHash
    ) public onlyRole(CHALLENGER_ROLE) {

        // check the rollupAddress is set
        require(rollupAddress != address(0), "7");

        // check the challengerPublicKey is set
        require(challengerPublicKey.length != 0, "8");

        // check the assertionId and rollupAddress combo haven't been submitted yet
        bytes32 comboHash = keccak256(abi.encodePacked(_assertionId, rollupAddress));
        require(!rollupAssertionTracker[comboHash], "9");
        rollupAssertionTracker[comboHash] = true;

        // verify the data inside the hash matched the data pulled from the rollup contract
        if (isCheckingAssertions) {

            // get the node information from the rollup.
            Node memory node = IRollupCore(rollupAddress).getNode(_assertionId);

            require(node.prevNum == _predecessorAssertionId, "10");
            require(node.confirmData == _confirmData, "11");
            require(node.createdAtBlock == _assertionTimestamp, "12");
        }

        // we need to determine how much token will be emitted
        (uint256 challengeEmission,) = calculateChallengeEmissionAndTier();

        // mint part of this for the gas subsidy contract
        uint256 amountForGasSubsidy = (challengeEmission * _gasSubsidyPercentage) / 100;

        // mint xai for the gas subsidy
        Xai(xaiAddress).mint(gasSubsidyRecipient, amountForGasSubsidy);

        // the remaining part of the emission should be tracked and later allocated when claimed
        uint256 rewardAmountForClaimers = challengeEmission - amountForGasSubsidy;

        // add the amount that will be given to claimers to the allocated field variable amount, so we can track how much esXai is owed
        _allocatedTokens += rewardAmountForClaimers;

        // close the previous challenge with the start of the next challenge
        if (challengeCounter > 0) {
            challenges[challengeCounter - 1].openForSubmissions = false;
            emit ChallengeClosed(challengeCounter - 1);
        }

        // add challenge to the mapping
        challenges[challengeCounter] = Challenge({
            openForSubmissions: true,
            expiredForRewarding: false,
            assertionId: _assertionId,
            assertionStateRootOrConfirmData: _confirmData,
            assertionTimestamp: _assertionTimestamp,
            challengerSignedHash: _challengerSignedHash,
            activeChallengerPublicKey: challengerPublicKey, // Store the active challengerPublicKey at the time of challenge submission
            rollupUsed: rollupAddress, // Store the rollup address used for this challenge
            createdTimestamp: block.timestamp,
            totalSupplyOfNodesAtChallengeStart: NodeLicense(nodeLicenseAddress).totalSupply(), // we need to store how many nodes were created for the 1% odds
            rewardAmountForClaimers: rewardAmountForClaimers,
            amountForGasSubsidy: amountForGasSubsidy,
            numberOfEligibleClaimers: 0,
            amountClaimedByClaimers: 0
        });

        // emit the events
        emit ChallengeSubmitted(challengeCounter);   

        // increment the challenge counter
        challengeCounter++;
    }

    /**
     * @notice A public view function to look up challenges.
     * @param _challengeId The ID of the challenge to look up.
     * @return The challenge corresponding to the given ID.
     */
    function getChallenge(uint256 _challengeId) public view returns (Challenge memory) {
        require(_challengeId < challengeCounter, "13");
        return challenges[_challengeId];
    }

    /**
     * @notice Submits an assertion to a challenge.
     * @dev This function can only be called by the owner of a NodeLicense or addresses they have approved on this contract.
     * @param _nodeLicenseId The ID of the NodeLicense.
     */
    function submitAssertionToChallenge(
        uint256 _nodeLicenseId,
        uint256 _challengeId,
        bytes memory _confirmData
    ) public {

        // Check the challenge is open for submissions
        require(challenges[_challengeId].openForSubmissions, "14");
        
        // Check that _nodeLicenseId hasn't already been submitted for this challenge
        require(!submissions[_challengeId][_nodeLicenseId].submitted, "15");

        // If the submission successor hash, doesn't match the one submitted by the challenger, then end early and emit an event
        if (keccak256(abi.encodePacked(_confirmData)) != keccak256(abi.encodePacked(challenges[_challengeId].assertionStateRootOrConfirmData))) {
            emit InvalidSubmission(_challengeId, _nodeLicenseId);
            return;
        }

        address licenseOwner = NodeLicense(nodeLicenseAddress).ownerOf(_nodeLicenseId);
        address assignedPool = assignedKeyToPool[_nodeLicenseId];
        
        require(isValidOperator(licenseOwner, assignedPool), "17");

        _submitAssertion(_nodeLicenseId, _challengeId, _confirmData, licenseOwner, assignedPool);
    }

	function submitMultipleAssertions(
		uint256[] memory _nodeLicenseIds,
		uint256 _challengeId,
		bytes memory _confirmData
	) external {
        
		require(challenges[_challengeId].openForSubmissions, "16");
        
        uint256 keyLength = _nodeLicenseIds.length;

		if (keccak256(abi.encodePacked(_confirmData)) != keccak256(abi.encodePacked(challenges[_challengeId].assertionStateRootOrConfirmData))) {
            emit InvalidBatchSubmission(_challengeId, msg.sender, keyLength);
			return;
		}

		for (uint256 i = 0; i < keyLength; i++) {
            uint256 _nodeLicenseId = _nodeLicenseIds[i];
            if (!submissions[_challengeId][_nodeLicenseId].submitted) {
                
                address licenseOwner = NodeLicense(nodeLicenseAddress).ownerOf(_nodeLicenseId);
                address assignedPool = assignedKeyToPool[_nodeLicenseId];

                if(isValidOperator(licenseOwner, assignedPool)){
                    _submitAssertion(_nodeLicenseId, _challengeId, _confirmData, licenseOwner, assignedPool);
                }
            }
		}
	}

    function isValidOperator(address licenseOwner, address assignedPool) internal view returns (bool) {
        return licenseOwner == msg.sender ||
            isApprovedForOperator(licenseOwner, msg.sender) ||
            (
                assignedPool != address(0) &&
                PoolFactory(poolFactoryAddress).isDelegateOfPoolOrOwner(msg.sender, assignedPool)
            );
    }
    
    function _submitAssertion(uint256 _nodeLicenseId, uint256 _challengeId, bytes memory _confirmData, address licenseOwner, address assignedPool) internal {
        
        // Support v1 (no pools) & v2 (pools)
		uint256 stakedAmount = stakedAmounts[assignedPool];
		if (assignedPool == address(0)) {
			stakedAmount = stakedAmounts[licenseOwner];
			uint256 ownerUnstakedAmount = NodeLicense(nodeLicenseAddress).balanceOf(licenseOwner) - assignedKeysOfUserCount[licenseOwner];
			if (ownerUnstakedAmount * maxStakeAmountPerLicense < stakedAmount) {
				stakedAmount = ownerUnstakedAmount * maxStakeAmountPerLicense;
			}
		} else {
			if (assignedKeysToPoolCount[assignedPool] * maxStakeAmountPerLicense < stakedAmount) {
				stakedAmount = assignedKeysToPoolCount[assignedPool] * maxStakeAmountPerLicense;
			}
		}

        // Check the user is actually eligible for receiving a reward, do not count them in numberOfEligibleClaimers if they are not able to receive a reward
        (bool hashEligible, ) = createAssertionHashAndCheckPayout(_nodeLicenseId, _challengeId, _getBoostFactor(stakedAmount), _confirmData, challenges[_challengeId].challengerSignedHash);

        // Store the assertionSubmission to a map
        submissions[_challengeId][_nodeLicenseId] = Submission({
            submitted: true,
            claimed: false,
            eligibleForPayout: hashEligible,
            nodeLicenseId: _nodeLicenseId,
            assertionStateRootOrConfirmData: _confirmData
        });

        // Keep track of how many submissions submitted were eligible for the reward
        if (hashEligible) {
            challenges[_challengeId].numberOfEligibleClaimers++;
        }

        // Emit the AssertionSubmitted event
        emit AssertionSubmitted(_challengeId, _nodeLicenseId);
    }

    /**
     * @notice Claims a reward for a successful assertion.
     * @dev This function looks up the submission, checks if the challenge is closed for submissions, and if valid for a payout, sends a reward.
     * @param _nodeLicenseId The ID of the NodeLicense.
     * @param _challengeId The ID of the challenge.
     */
    function claimReward(
        uint256 _nodeLicenseId,
        uint256 _challengeId
    ) public {
        Challenge memory challengeToClaimFor  = challenges[_challengeId];
        // check the challenge exists by checking the timestamp is not 0
        require(challengeToClaimFor.createdTimestamp != 0, "18");
        // Check if the challenge is closed for submissions
        require(!challengeToClaimFor.openForSubmissions, "19");
        // expire the challenge if 270 days old
        if (block.timestamp >= challengeToClaimFor.createdTimestamp + 270 days) {
            expireChallengeRewards(_challengeId);
            return;
        }
        // Check if the challenge rewards have expired
        require(!challengeToClaimFor.expiredForRewarding, "20");

        // Get the minting timestamp of the nodeLicenseId
        uint256 mintTimestamp = NodeLicense(nodeLicenseAddress).getMintTimestamp(_nodeLicenseId);

        // Check if the nodeLicenseId is eligible for a payout
        require(mintTimestamp < challengeToClaimFor.createdTimestamp, "21");

        // Look up the submission
        Submission memory submission = submissions[_challengeId][_nodeLicenseId];

        // Check if the owner of the NodeLicense is KYC'd
        address owner = NodeLicense(nodeLicenseAddress).ownerOf(_nodeLicenseId);
        require(isKycApproved(owner), "22");

        // Check if the submission has already been claimed
        require(!submission.claimed, "23");

        require(submission.eligibleForPayout, "24");

        // Take the amount that was allocated for the rewards and divide it by the number of claimers
        uint256 reward = challengeToClaimFor.rewardAmountForClaimers / challengeToClaimFor.numberOfEligibleClaimers;

        // mark the submission as claimed
        submissions[_challengeId][_nodeLicenseId].claimed = true;

        // increment the amount claimed on the challenge
        challenges[_challengeId].amountClaimedByClaimers += reward;

        address rewardReceiver = assignedKeyToPool[_nodeLicenseId];
        if (rewardReceiver == address(0)) {
            rewardReceiver = owner;
        }

        // Mint the reward to the owner of the nodeLicense
        esXai(esXaiAddress).mint(rewardReceiver, reward);

        // Emit the RewardsClaimed event
        emit RewardsClaimed(_challengeId, reward);

        // Increment the total claims of this address
        _lifetimeClaims[rewardReceiver] += reward;

        // unallocate the tokens that have now been converted to esXai
        _allocatedTokens -= reward;
    }

	function claimMultipleRewards(
		uint256[] memory _nodeLicenseIds,
		uint256 _challengeId,
        address claimForAddressInBatch
	) external {
        
        Challenge memory challengeToClaimFor  = challenges[_challengeId];
        // check the challenge exists by checking the timestamp is not 0
        require(challengeToClaimFor.createdTimestamp != 0, "25");
        // Check if the challenge is closed for submissions
        require(!challengeToClaimFor.openForSubmissions, "26");
        // expire the challenge if 270 days old
        if (block.timestamp >= challengeToClaimFor.createdTimestamp + 270 days) {
            expireChallengeRewards(_challengeId);
            return;
        }

        // Check if the challenge rewards have expired
        require(!challengeToClaimFor.expiredForRewarding, "27");

        uint256 reward = challengeToClaimFor.rewardAmountForClaimers / challengeToClaimFor.numberOfEligibleClaimers;
        uint256 keyLength = _nodeLicenseIds.length;
        uint256 claimCount = 0;
        uint256 poolMintAmount = 0;

		for (uint256 i = 0; i < keyLength; i++) {
            uint256 _nodeLicenseId = _nodeLicenseIds[i];

            uint256 mintTimestamp = NodeLicense(nodeLicenseAddress).getMintTimestamp(_nodeLicenseId);
            address owner = NodeLicense(nodeLicenseAddress).ownerOf(_nodeLicenseId);
            Submission memory submission = submissions[_challengeId][_nodeLicenseId];

            // Check if the nodeLicenseId is eligible for a payout
            if (
                isKycApproved(owner) &&
                mintTimestamp < challengeToClaimFor.createdTimestamp && 
                !submission.claimed &&
                submission.eligibleForPayout
            ) {
                // mark the submission as claimed
                submissions[_challengeId][_nodeLicenseId].claimed = true;

                // increment the amount claimed on the challenge
                challenges[_challengeId].amountClaimedByClaimers += reward;
                
                address rewardReceiver = assignedKeyToPool[_nodeLicenseId];
                if (rewardReceiver == address(0)) {
                    rewardReceiver = owner;
                }

                //If we have set the poolAddress we will only claim if the license is staked to that pool
                if (claimForAddressInBatch != address(0) && rewardReceiver == claimForAddressInBatch) {
                    poolMintAmount += reward;
                } else {
                    // Mint the reward to the owner of the nodeLicense
                    esXai(esXaiAddress).mint(rewardReceiver, reward);
                    _lifetimeClaims[rewardReceiver] += reward;
                }

                claimCount++;
            }
		}

        if (poolMintAmount > 0) {
            esXai(esXaiAddress).mint(claimForAddressInBatch, poolMintAmount);
            _lifetimeClaims[claimForAddressInBatch] += poolMintAmount;
        }
        
        _allocatedTokens -= claimCount * reward;
        emit BatchRewardsClaimed(_challengeId, claimCount * reward, claimCount);
	}

    /**
     * @notice Creates an assertion hash and determines if the hash payout is below the threshold.
     * @dev This function creates a hash of the _nodeLicenseId, _challengeId, challengerSignedHash from the challenge, and _newStateRoot.
     * It then converts the hash to a number and checks if it is below the threshold.
     * The threshold is calculated as the maximum uint256 value divided by 100 and then multiplied by the total supply of NodeLicenses.
     * @param _nodeLicenseId The ID of the NodeLicense.
     * @param _challengeId The ID of the challenge.
     * @param _boostFactor The factor controlling the chance of eligibility for payout as a multiplicator (base chance is 1/100 - Example: _boostFactor 200 will double the payout chance to 1/50, _boostFactor 16 maps to 1/6.25).
     * @param _confirmData The confirm hash, will change to assertionState after BOLD.
     * @param _challengerSignedHash The signed hash for the challenge
     * @return a boolean indicating if the hash is eligible, and the assertionHash.
     */
    function createAssertionHashAndCheckPayout(
        uint256 _nodeLicenseId,
        uint256 _challengeId,
        uint256 _boostFactor,
        bytes memory _confirmData,
        bytes memory _challengerSignedHash
    ) public pure returns (bool, bytes32) {

        bytes32 assertionHash = keccak256(abi.encodePacked(_nodeLicenseId, _challengeId, _confirmData, _challengerSignedHash));
        uint256 hashNumber = uint256(assertionHash);
        // hashNumber % 10_000 equals {0...9999}
        // hashNumber % 10_000 < 100 means a 100 / 10000 = 1 /100
        return (hashNumber % 10_000 < _boostFactor, assertionHash);
    }

    /**
     * @notice Returns the submissions for a given array of challenges and a NodeLicense.
     * @param _challengeIds An array of challenge IDs.
     * @param _nodeLicenseId The ID of the NodeLicense.
     * @return An array of submissions for the given challenges and NodeLicense.
     */
    function getSubmissionsForChallenges(uint256[] memory _challengeIds, uint256 _nodeLicenseId) public view returns (Submission[] memory) {
        Submission[] memory submissionsArray = new Submission[](_challengeIds.length);
        for (uint i = 0; i < _challengeIds.length; i++) {
            submissionsArray[i] = submissions[_challengeIds[i]][_nodeLicenseId];
        }
        return submissionsArray;
    }

    /**
     * @notice Expires the rewards for a challenge if it is at least 270 days old.
     * @param _challengeId The ID of the challenge.
     */
    function expireChallengeRewards(uint256 _challengeId) public {
        // check the challenge exists by checking the timestamp is not 0
        require(challenges[_challengeId].createdTimestamp != 0, "28");

        // Check if the challenge is at least 270 days old
        require(block.timestamp >= challenges[_challengeId].createdTimestamp + 270 days, "29");

        // Check the challenge isn't already expired
        require(challenges[_challengeId].expiredForRewarding == false, "30");

        // Remove the unclaimed tokens from the allocation
        _allocatedTokens -= challenges[_challengeId].rewardAmountForClaimers - challenges[_challengeId].amountClaimedByClaimers;

        // Set expiredForRewarding to true
        challenges[_challengeId].expiredForRewarding = true;

        // Emit the ChallengeExpired event
        emit ChallengeExpired(_challengeId);
    }

    /**
     * @notice Get the total claims for a specific address.
     * @param owner The address to query.
     * @return The total claims for the address.
     */
    function getTotalClaims(address owner) public view returns (uint256) {
        return _lifetimeClaims[owner];
    }

    /**
     * @dev Looks up payout boostFactor based on the staking tier.
     * @param stakedAmount The staked amount.
     * @return The payout chance boostFactor. 200 for double the chance.
     */
    function _getBoostFactor(uint256 stakedAmount) internal view returns (uint256) {
        if (stakedAmount < stakeAmountTierThresholds[0]) {
            return 100;
        }

        uint256 length = stakeAmountTierThresholds.length;
        for (uint256 tier = 1; tier < length; tier++) {
            if (stakedAmount < stakeAmountTierThresholds[tier]) {
                return stakeAmountBoostFactors[tier - 1];
            }
        }
        return stakeAmountBoostFactors[length - 1];
    }
    
    /**
     * @dev Admin update the maximum staking amount per NodeLicense
     * @param newAmount The new maximum amount per NodeLicense
     */
    function updateMaxStakePerLicense(uint256 newAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAmount != 0, "31");
        uint256 prevAmount = maxStakeAmountPerLicense;
        maxStakeAmountPerLicense = newAmount;
        emit UpdateMaxStakeAmount(prevAmount, newAmount);
    }
    
    /**
     * @dev Admin update the maximum number of NodeLicense staked in a pool
     * @param newAmount The new maximum amount per NodeLicense
     */
    function updateMaxKeysPerPool(uint256 newAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAmount != 0, "32");
        uint256 prevAmount = maxKeysPerPool;
        maxKeysPerPool = newAmount;
        emit UpdateMaxKeysPerPool(prevAmount, newAmount);
    }

    /**
     * @dev Admin update the tier thresholds and the corresponding reward chance boost
     * @param index The index if the tier to update
     * @param newThreshold The new threshold of the tier
     * @param newBoostFactor The new boost factor for the tier
     */
    function updateStakingTier(uint256 index, uint256 newThreshold, uint256 newBoostFactor) external onlyRole(DEFAULT_ADMIN_ROLE) {

        require(newBoostFactor > 0 && newBoostFactor <= 10000, "33");

        uint256 lastIndex = stakeAmountTierThresholds.length - 1;
        if (index == 0) {
            require(stakeAmountTierThresholds[1] > newThreshold, "34");
        } else if (index == lastIndex) {
            require(stakeAmountTierThresholds[lastIndex - 1] < newThreshold, "35");
        } else {
            require(stakeAmountTierThresholds[index + 1] > newThreshold && stakeAmountTierThresholds[index - 1] < newThreshold, "36");
        }

        stakeAmountTierThresholds[index] = newThreshold;
        stakeAmountBoostFactors[index] = newBoostFactor;
    }

    /**
     * @dev Admin add a new staking tier to the end of the tier array
     * @param newThreshold The new threshold of the tier
     * @param newBoostFactor The new boost factor for the tier
     */
    function addStakingTier(uint256 newThreshold, uint256 newBoostFactor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newBoostFactor > 0 && newBoostFactor <= 10000, "37");

        uint256 lastIndex = stakeAmountTierThresholds.length - 1;
        require(stakeAmountTierThresholds[lastIndex] < newThreshold, "38");

        stakeAmountTierThresholds.push(newThreshold);
        stakeAmountBoostFactors.push(newBoostFactor);
    }

    /**
     * @dev Admin remove a staking tier
     * @param index The index if the tier to remove
     */
    function removeStakingTier(uint256 index) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(stakeAmountTierThresholds.length > 1, "39");
        require(index < stakeAmountTierThresholds.length, "40");
        for (uint i = index; i < stakeAmountTierThresholds.length - 1; i++) {
            stakeAmountTierThresholds[i] = stakeAmountTierThresholds[i + 1];
            stakeAmountBoostFactors[i] = stakeAmountBoostFactors[i + 1];
        }
        stakeAmountTierThresholds.pop();
        stakeAmountBoostFactors.pop();
    }

    /**
     * @dev Looks up payout boostFactor based on the staking tier for a staker wallet.
     * @param staker The address of the staker or pool.
     * @return The payout chance boostFactor based on max stake capacity or staked amount.
     */
    function getBoostFactorForStaker(address staker) external view returns (uint256) {

        uint256 stakedAmount = stakedAmounts[staker];

        if(PoolFactory(poolFactoryAddress).poolsCreatedViaFactory(staker)){
			if (assignedKeysToPoolCount[staker] * maxStakeAmountPerLicense < stakedAmount) {
				stakedAmount = assignedKeysToPoolCount[staker] * maxStakeAmountPerLicense;
			}
        }else{			
			uint256 ownerUnstakedAmount = NodeLicense(nodeLicenseAddress).balanceOf(staker) - assignedKeysOfUserCount[staker];
			if (ownerUnstakedAmount * maxStakeAmountPerLicense < stakedAmount) {
				stakedAmount = ownerUnstakedAmount * maxStakeAmountPerLicense;
			}
        }

        return _getBoostFactor(stakedAmount);
    }

    /**
     * @dev Function that lets a user unstake V1 esXai that have previously been staked.
     * @param amount The amount of esXai to unstake.
     */
    function unstake(uint256 amount) external {
        require(stakedAmounts[msg.sender] >= amount, "41");
        esXai(esXaiAddress).transfer(msg.sender, amount);
        stakedAmounts[msg.sender] -= amount;
        emit UnstakeV1(msg.sender, amount, stakedAmounts[msg.sender]);
    }

    function stakeKeys(address pool, address staker, uint256[] memory keyIds) external onlyPoolFactory {
		require(isKycApproved(staker), "42");
        uint256 keysLength = keyIds.length;
        require(assignedKeysToPoolCount[pool] + keysLength <= maxKeysPerPool, "43");

        NodeLicense nodeLicenseContract = NodeLicense(nodeLicenseAddress);
        for (uint256 i = 0; i < keysLength; i++) {
            uint256 keyId = keyIds[i];
            require(assignedKeyToPool[keyId] == address(0), "44");
            require(nodeLicenseContract.ownerOf(keyId) == staker, "45");
            assignedKeyToPool[keyId] = pool;
        }

        assignedKeysToPoolCount[pool] += keysLength;
        assignedKeysOfUserCount[staker] += keysLength;
    }

    function unstakeKeys(address pool, address staker, uint256[] memory keyIds) external onlyPoolFactory {
        uint256 keysLength = keyIds.length;
        NodeLicense nodeLicenseContract = NodeLicense(nodeLicenseAddress);

        for (uint256 i = 0; i < keysLength; i++) {
            uint256 keyId = keyIds[i];
            require(assignedKeyToPool[keyId] == pool, "47");
            require(nodeLicenseContract.ownerOf(keyId) == staker, "48");
            assignedKeyToPool[keyId] = address(0);
        }
        assignedKeysToPoolCount[pool] -= keysLength;
        assignedKeysOfUserCount[staker] -= keysLength;
    }

    function stakeEsXai(address pool, uint256 amount) external onlyPoolFactory {
        uint256 maxStakedAmount = maxStakeAmountPerLicense * assignedKeysToPoolCount[pool];
        require(stakedAmounts[pool] + amount <= maxStakedAmount, "49");
        stakedAmounts[pool] += amount;
    }

    function unstakeEsXai(address pool, uint256 amount) external onlyPoolFactory {
        require(stakedAmounts[pool] >= amount, "50");
        stakedAmounts[pool] -= amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./esXai.sol";

/**
 * @title Xai
 * @dev Implementation of the Xai
 */
contract Xai is ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant MAX_SUPPLY = 2500000000 * 10**18; // Max supply of 2,500,000,000 tokens
    address public esXaiAddress;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[500] private __gap;

    event EsXaiAddressSet(address indexed newEsXaiAddress);
    event ConvertedToEsXai(address indexed user, uint256 amount);

    function initialize() public initializer {
        __ERC20_init("Xai", "XAI");
        __ERC20Burnable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /**
     * @dev Function to set esXai address
     * @param newEsXaiAddress The new esXai address.
     */
    function setEsXaiAddress(address newEsXaiAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        esXaiAddress = newEsXaiAddress;
        emit EsXaiAddressSet(newEsXaiAddress);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) returns (bool) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Cannot mint beyond max supply"); // not needed for testnet
        _mint(to, amount);
        return true;
    }

    /**
     * @dev Function to convert Xai to esXai
     * @param amount The amount of Xai to convert.
     */
    function convertToEsXai(uint256 amount) public {
        require(esXaiAddress != address(0), "esXai contract address not set");
        _burn(msg.sender, amount);
        esXai(esXaiAddress).mint(msg.sender, amount);
        emit ConvertedToEsXai(msg.sender, amount);
    }
}