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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
                        StringsUpgradeable.toHexString(uint160(account), 20),
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../extensions/ERC20BurnableUpgradeable.sol";
import "../extensions/ERC20PausableUpgradeable.sol";
import "../../../access/AccessControlEnumerableUpgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetMinterPauserUpgradeable is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable {
    function initialize(string memory name, string memory symbol) public virtual initializer {
        __ERC20PresetMinterPauser_init(name, symbol);
    }
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    function __ERC20PresetMinterPauser_init(string memory name, string memory symbol) internal onlyInitializing {
        __ERC20_init_unchained(name, symbol);
        __Pausable_init_unchained();
        __ERC20PresetMinterPauser_init_unchained(name, symbol);
    }

    function __ERC20PresetMinterPauser_init_unchained(string memory, string memory) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
                        Strings.toHexString(uint160(account), 20),
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

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
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Libraries
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { SafeERC20 } from "./external/libraries/SafeERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

// Contracts
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ContractWhitelist } from "./helper/ContractWhitelist.sol";
import { OptionsToken } from "./options-token/OptionsToken.sol";
import { IrVaultState } from "./IrVaultState.sol";

// Interfaces
import { IERC20 } from "./external/interfaces/IERC20.sol";
import { IOptionPricing } from "./pricing/IOptionPricing.sol";
import { IVolatilityOracle } from "./oracle/IVolatilityOracle.sol";
import { IFeeStrategy } from "./fees/IFeeStrategy.sol";

interface IGaugeOracle {
  function getRate(
    uint256,
    uint256,
    address
  ) external view returns (uint256);
}

interface ICrv2Pool is IERC20 {
  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
    external
    returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 min_amount
  ) external returns (uint256);

  function get_virtual_price() external view returns (uint256);

  function coins(uint256) external view returns (address);
}

interface ICrv2PoolGauge {
  function deposit(
    uint256 _value,
    address _addr,
    bool _claim_rewards
  ) external;

  function withdraw(uint256 _value, bool _claim_rewards) external;

  function claim_rewards() external;
}

/*                                                                               
                                                       ▓                        
                       ▓                                 ▓                      
                     ▓▓                                   ▓▓                    
                   ▓▓                                      ▓▓▓                  
                 ▓▓▓                                         ▓▓▓                
               ▓▓▓▓                                           ▓▓▓▓              
             ▓▓▓▓▓                                             ▓▓▓▓▓            
           ▓▓▓▓▓                                                ▓▓▓▓▓▓          
         ▓▓▓▓▓▓                                                   ▓▓▓▓▓▓        
       ▓▓▓▓▓▓▓                                                     ▓▓▓▓▓▓▓      
     ▓▓▓▓▓▓▓                                                        ▓▓▓▓▓▓▓▓    
   ▓▓▓▓▓▓▓▓                                                          ▓▓▓▓▓▓▓▓   
 ▓▓▓▓▓▓▓▓▓                                                             ▓▓▓▓▓▓▓▓ 
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                                                   ▓▓▓▓▓▓▓▓▓▓▓▓▓
 ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                                      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 
      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                                 ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓     
              ▓▓▓▓▓▓▓▓▓▓▓                               ▓▓▓▓▓▓▓▓▓▓▓▓▓           
                ▓▓▓▓▓▓▓▓                               ▓▓▓▓▓▓▓▓                 
               ▓▓▓▓▓▓▓                                 ▓▓▓▓▓▓                   
              ▓▓▓▓▓▓▓                                 ▓▓▓▓▓▓▓                   
             ▓▓▓▓▓▓▓         ▓                        ▓▓▓▓▓▓▓                   
            ▓▓▓▓▓▓▓          ▓▓▓                      ▓▓▓▓▓▓▓                   
            ▓▓▓▓▓▓          ▓▓▓▓▓▓                     ▓▓▓▓▓▓                   
           ▓▓▓▓▓▓▓          ▓▓▓▓▓▓▓▓                   ▓▓▓▓▓▓▓                  
           ▓▓▓▓▓▓▓           ▓▓▓▓▓▓▓▓                   ▓▓▓▓▓▓▓                 
            ▓▓▓▓▓▓▓             ▓▓▓▓▓▓                   ▓▓▓▓▓▓▓                
            ▓▓▓▓▓▓▓▓▓                                     ▓▓▓▓▓▓▓               
              ▓▓▓▓▓▓▓▓▓▓                                   ▓▓▓▓▓▓▓              
               ▓▓▓▓▓▓▓▓▓▓▓▓▓                                ▓▓▓▓▓▓▓             
                  ▓▓▓▓▓▓▓▓▓▓▓▓                               ▓▓▓▓▓▓▓            
                      ▓▓▓▓▓▓▓▓▓▓                              ▓▓▓▓▓▓            
                         ▓▓▓▓▓▓▓▓                             ▓▓▓▓▓▓▓           
                           ▓▓▓▓▓▓▓▓                            ▓▓▓▓▓▓           
                            ▓▓▓▓▓▓▓▓                           ▓▓▓▓▓▓▓          
                              ▓▓▓▓▓▓▓▓                         ▓▓▓▓▓▓           
                               ▓▓▓▓▓▓▓▓▓                     ▓▓▓▓▓▓▓▓           
                                 ▓▓▓▓▓▓▓▓▓                 ▓▓▓▓▓▓▓▓▓            
                                   ▓▓▓▓▓▓▓▓▓▓           ▓▓▓▓▓▓▓▓▓▓              
                                     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓               
                                       ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                  
                                           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
*/

/// @title Curve pool IR vault
/// @dev Option tokens are in erc20 18 decimals
/// Base token and quote token calculations are done in their respective erc20 precision
/// Strikes are in 1e8 precision
/// Price is in 1e8 precision
contract BaseIRVault is
  ContractWhitelist,
  Pausable,
  ReentrancyGuard,
  IrVaultState,
  AccessControl
{
  using SafeERC20 for IERC20;
  using SafeERC20 for ICrv2Pool;

  /// @dev crvLP (Curve 2Pool LP token)
  ICrv2Pool public immutable crvLP;

  /// @dev OptionsToken implementation address
  address public immutable optionsTokenImplementation;

  /// @dev crvPool
  address public immutable crvPool;

  /// @dev Manager role
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /*==== CONSTRUCTOR ====*/

  constructor(
    Addresses memory _addresses,
    address _crvLP,
    address _crvPool
  ) {
    require(_crvLP != address(0), "E1");
    require(_crvPool != address(0), "E1");

    addresses = _addresses;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);

    crvLP = ICrv2Pool(_crvLP);
    crvPool = _crvPool;

    optionsTokenImplementation = address(new OptionsToken());

    crvLP.safeIncreaseAllowance(_crvPool, type(uint256).max);
  }

  /*==== SETTER METHODS ====*/

  /// @notice Pauses the vault for emergency cases
  /// @dev Can only be called by governance
  /// @return Whether it was successfully paused
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
    _pause();
    _updateFinalEpochBalances();
    return true;
  }

  /// @notice Unpauses the vault
  /// @dev Can only be called by governance
  /// @return Whether it was successfully unpaused
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
    _unpause();
    return true;
  }

  /// @notice Updates the delay tolerance for the expiry epoch function
  /// @dev Can only be called by governance
  /// @return Whether it was successfully updated
  function updateExpireDelayTolerance(uint256 _expireDelayTolerance)
    external
    onlyRole(MANAGER_ROLE)
    returns (bool)
  {
    expireDelayTolerance = _expireDelayTolerance;
    emit ExpireDelayToleranceUpdate(_expireDelayTolerance);
    return true;
  }

  /// @notice Sets (adds) a list of addresses to the address list
  /// @dev Can only be called by the owner
  /// @param _addresses addresses of contracts in the Addresses struct
  function setAddresses(Addresses calldata _addresses)
    external
    onlyRole(MANAGER_ROLE)
  {
    addresses = _addresses;
    emit AddressesSet(_addresses);
  }

  /*==== METHODS ====*/

  /// @notice Transfers all funds to msg.sender
  /// @dev Can only be called by governance
  /// @param tokens The list of erc20 tokens to withdraw
  /// @param transferNative Whether should transfer the native currency
  /// @return Whether emergency withdraw was successful
  function emergencyWithdraw(address[] calldata tokens, bool transferNative)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    whenPaused
    returns (bool)
  {
    if (transferNative) payable(msg.sender).transfer(address(this).balance);

    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20 token = IERC20(tokens[i]);
      token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    emit EmergencyWithdraw(msg.sender);

    return true;
  }

  /// @notice Sets the current epoch as expired.
  /// @return Whether expire was successful
  function expireEpoch()
    external
    whenNotPaused
    isEligibleSender
    nonReentrant
    returns (bool)
  {
    uint256 epoch = currentEpoch;
    require(!totalEpochData[epoch].isEpochExpired, "E3");
    (, uint256 epochExpiry) = getEpochTimes(epoch);
    require((block.timestamp >= epochExpiry), "E4");
    require(block.timestamp <= epochExpiry + expireDelayTolerance, "E21");

    totalEpochData[epoch].rateAtSettlement = getCurrentRate();

    _updateFinalEpochBalances();

    totalEpochData[epoch].isEpochExpired = true;

    emit EpochExpired(msg.sender, totalEpochData[epoch].rateAtSettlement);

    return true;
  }

  /// @notice Sets the current epoch as expired. Only can be called by governance.
  /// @param rateAtSettlement The rate at settlement
  /// @return Whether expire was successful
  function expireEpoch(uint256 rateAtSettlement)
    external
    onlyRole(MANAGER_ROLE)
    whenNotPaused
    returns (bool)
  {
    uint256 epoch = currentEpoch;
    require(!totalEpochData[epoch].isEpochExpired, "E3");
    (, uint256 epochExpiry) = getEpochTimes(epoch);
    require((block.timestamp > epochExpiry + expireDelayTolerance), "E4");

    totalEpochData[epoch].rateAtSettlement = rateAtSettlement;

    _updateFinalEpochBalances();

    totalEpochData[epoch].isEpochExpired = true;

    emit EpochExpired(msg.sender, totalEpochData[epoch].rateAtSettlement);

    return true;
  }

  /// @dev Updates the final epoch crvLP balances per strike of the vault
  function _updateFinalEpochBalances() private {
    IERC20 crv = IERC20(addresses.crv);
    uint256 crvRewards = crv.balanceOf(address(this));
    uint256 epoch = currentEpoch;

    // Withdraw curve LP from the curve gauge and claim rewards
    ICrv2PoolGauge(crvPool).withdraw(
      totalEpochData[epoch].totalTokenDeposits +
        totalEpochData[epoch].epochCallsPremium +
        totalEpochData[epoch].epochPutsPremium,
      true /* _claim_rewards */
    );

    crvRewards = crv.balanceOf(address(this)) - crvRewards;

    totalEpochData[epoch].crvToDistribute = crvRewards;

    if (totalEpochData[epoch].totalTokenDeposits > 0) {
      uint256[] memory strikes = totalEpochData[epoch].epochStrikes;
      uint256[] memory callsLeverages = totalEpochData[epoch].callsLeverages;
      uint256[] memory putsLeverages = totalEpochData[epoch].putsLeverages;

      for (uint256 i = 0; i < strikes.length; i++) {
        // PnL from ssov option settlements

        uint256 callsSettlement = calculatePnl(
          totalEpochData[epoch].rateAtSettlement,
          strikes[i],
          totalStrikeData[epoch][strikes[i]].totalCallsPurchased,
          false
        );

        for (uint256 j = 1; j < callsLeverages.length; j++) {
          if (
            totalStrikeData[epoch][strikes[i]].leveragedCallsDeposits[j] > 0
          ) {
            totalStrikeData[epoch][strikes[i]].totalCallsStrikeBalance[
                j
              ] = calculateFinalBalance(
              false,
              strikes[i],
              i,
              j,
              (callsSettlement *
                totalStrikeData[epoch][strikes[i]].leveragedCallsDeposits[j]) /
                totalStrikeData[epoch][strikes[i]].totalCallsStrikeDeposits
            );
          } else {
            totalStrikeData[epoch][strikes[i]].totalCallsStrikeBalance[j] = 0;
          }
        }

        uint256 putsSettlement = calculatePnl(
          totalEpochData[epoch].rateAtSettlement,
          strikes[i],
          totalStrikeData[epoch][strikes[i]].totalPutsPurchased,
          true
        );
        for (uint256 j = 1; j < putsLeverages.length; j++) {
          if (totalStrikeData[epoch][strikes[i]].leveragedPutsDeposits[j] > 0) {
            totalStrikeData[epoch][strikes[i]].totalPutsStrikeBalance[
                j
              ] = calculateFinalBalance(
              true,
              strikes[i],
              i,
              j,
              (putsSettlement *
                totalStrikeData[epoch][strikes[i]].leveragedPutsDeposits[j]) /
                totalStrikeData[epoch][strikes[i]].totalPutsStrikeDeposits
            );
          } else {
            totalStrikeData[epoch][strikes[i]].totalPutsStrikeBalance[j] = 0;
          }
        }
      }
    }
  }

  /// @notice calculates the final amount for a strike and leverage accounting for settlements and premiums
  /// @param isPut is put
  /// @param strike strike
  /// @param strikeIndex strike index
  /// @param leverageIndex leverage index
  /// @param settlement settlement amount
  /// @return final withdrawable amount for a strike and leverage
  function calculateFinalBalance(
    bool isPut,
    uint256 strike,
    uint256 strikeIndex,
    uint256 leverageIndex,
    uint256 settlement
  ) private returns (uint256) {
    uint256 epoch = currentEpoch;
    if (isPut) {
      if (totalStrikeData[epoch][strike].totalPutsStrikeDeposits == 0) {
        return 0;
      }
      uint256 premium = (totalEpochData[epoch].epochStrikePutsPremium[
        strikeIndex
      ] * totalStrikeData[epoch][strike].leveragedPutsDeposits[leverageIndex]) /
        totalStrikeData[epoch][strike].totalPutsStrikeDeposits;

      uint256 leverageSettlement = ((settlement *
        totalStrikeData[epoch][strike].leveragedPutsDeposits[leverageIndex]) /
        totalStrikeData[epoch][strike].totalPutsStrikeDeposits);
      if (
        leverageSettlement >
        premium +
          (totalStrikeData[epoch][strike].leveragedPutsDeposits[leverageIndex] /
            totalEpochData[epoch].putsLeverages[leverageIndex])
      ) {
        totalStrikeData[epoch][strike].putsSettlement +=
          premium +
          (totalStrikeData[epoch][strike].leveragedPutsDeposits[leverageIndex] /
            totalEpochData[epoch].putsLeverages[leverageIndex]);
        return 0;
      } else {
        totalStrikeData[epoch][strike].putsSettlement += settlement;
        return (premium +
          (totalStrikeData[epoch][strike].leveragedPutsDeposits[leverageIndex] /
            totalEpochData[epoch].putsLeverages[leverageIndex]) -
          settlement);
      }
    } else {
      if (totalStrikeData[epoch][strike].totalCallsStrikeDeposits == 0) {
        return 0;
      }
      uint256 premium = (totalEpochData[epoch].epochStrikeCallsPremium[
        strikeIndex
      ] *
        totalStrikeData[epoch][strike].leveragedCallsDeposits[leverageIndex]) /
        totalStrikeData[epoch][strike].totalCallsStrikeDeposits;

      uint256 leverageSettlement = ((settlement *
        totalStrikeData[epoch][strike].leveragedCallsDeposits[leverageIndex]) /
        totalStrikeData[epoch][strike].totalCallsStrikeDeposits);
      if (
        leverageSettlement >
        premium +
          (totalStrikeData[epoch][strike].leveragedCallsDeposits[
            leverageIndex
          ] / totalEpochData[epoch].callsLeverages[leverageIndex])
      ) {
        totalStrikeData[epoch][strike].callsSettlement +=
          premium +
          (totalStrikeData[epoch][strike].leveragedCallsDeposits[
            leverageIndex
          ] / totalEpochData[epoch].callsLeverages[leverageIndex]);
        return 0;
      } else {
        totalStrikeData[epoch][strike].callsSettlement += settlement;
        return (premium +
          (totalStrikeData[epoch][strike].leveragedCallsDeposits[
            leverageIndex
          ] / totalEpochData[epoch].callsLeverages[leverageIndex]) -
          settlement);
      }
    }
  }

  /**
   * @notice Bootstraps a new epoch and mints option tokens equivalent to user deposits for the epoch
   * @return Whether bootstrap was successful
   */
  function bootstrap()
    external
    onlyRole(MANAGER_ROLE)
    whenNotPaused
    nonReentrant
    returns (bool)
  {
    uint256 nextEpoch = currentEpoch + 1;
    require(!totalEpochData[nextEpoch].isVaultReady, "E5");
    require(totalEpochData[nextEpoch].epochStrikes.length > 0, "E6");
    require(totalEpochData[nextEpoch].callsLeverages.length > 0, "E6");
    require(totalEpochData[nextEpoch].putsLeverages.length > 0, "E6");

    if (nextEpoch - 1 > 0) {
      // Previous epoch must be expired
      require(totalEpochData[nextEpoch - 1].isEpochExpired, "E7");
    }
    (, uint256 expiry) = getEpochTimes(nextEpoch);
    for (
      uint256 i = 0;
      i < totalEpochData[nextEpoch].epochStrikes.length;
      i++
    ) {
      uint256 strike = totalEpochData[nextEpoch].epochStrikes[i];
      // Create options tokens representing puts for selected strike in epoch
      OptionsToken _callOptionsToken = OptionsToken(
        Clones.clone(optionsTokenImplementation)
      );

      OptionsToken _putOptionsToken = OptionsToken(
        Clones.clone(optionsTokenImplementation)
      );

      _callOptionsToken.initialize(
        address(this),
        false,
        strike,
        expiry,
        nextEpoch,
        "IRVault",
        "CRV"
      );

      _putOptionsToken.initialize(
        address(this),
        true,
        strike,
        expiry,
        nextEpoch,
        "IRVault",
        "CRV"
      );

      totalEpochData[nextEpoch].callsToken.push(address(_callOptionsToken));
      totalEpochData[nextEpoch].putsToken.push(address(_putOptionsToken));

      // Mint tokens equivalent to deposits for strike in epoch
      _callOptionsToken.mint(
        address(this),
        (totalStrikeData[nextEpoch][strike].totalCallsStrikeDeposits *
          getLpPrice()) / 1e18
      );
      _putOptionsToken.mint(
        address(this),
        (totalStrikeData[nextEpoch][strike].totalPutsStrikeDeposits *
          getLpPrice()) / 1e18
      );
    }

    // Mark vault as ready for epoch
    totalEpochData[nextEpoch].isVaultReady = true;
    // Increase the current epoch
    currentEpoch = nextEpoch;

    emit Bootstrap(nextEpoch);

    return true;
  }

  /**
   * @notice initializes the arrays for a epoch with 0's array
   * @param nextEpoch expoch to initalize data with
   */

  function initalizeDefault(uint256 nextEpoch) private {
    uint256[] memory _defaultStrikesArray = new uint256[](
      totalEpochData[nextEpoch].epochStrikes.length
    );
    uint256[] memory _defaultCallsLeverageArray = new uint256[](
      totalEpochData[nextEpoch].callsLeverages.length
    );
    uint256[] memory _defaultPutsLeverageArray = new uint256[](
      totalEpochData[nextEpoch].putsLeverages.length
    );

    // initalize default values
    totalEpochData[nextEpoch].epochStrikeCallsPremium = _defaultStrikesArray;
    totalEpochData[nextEpoch].epochStrikePutsPremium = _defaultStrikesArray;

    for (
      uint256 i = 0;
      i < totalEpochData[nextEpoch].epochStrikes.length;
      i++
    ) {
      uint256 strike = totalEpochData[nextEpoch].epochStrikes[i];
      // initalize default values
      totalStrikeData[nextEpoch][strike]
        .leveragedCallsDeposits = _defaultCallsLeverageArray;
      totalStrikeData[nextEpoch][strike]
        .leveragedPutsDeposits = _defaultPutsLeverageArray;
      totalStrikeData[nextEpoch][strike]
        .totalCallsStrikeBalance = _defaultCallsLeverageArray;
      totalStrikeData[nextEpoch][strike]
        .totalPutsStrikeBalance = _defaultPutsLeverageArray;
    }
  }

  /**
   * @notice Sets strikes for next epoch
   * @param strikes Strikes to set for next epoch
   * @return Whether strikes were set
   */
  function setStrikes(uint256[] memory strikes, uint256 _expiry)
    external
    onlyRole(MANAGER_ROLE)
    whenNotPaused
    returns (bool)
  {
    uint256 nextEpoch = currentEpoch + 1;

    require(totalEpochData[nextEpoch].totalTokenDeposits == 0, "E8");
    require(_expiry > totalEpochData[nextEpoch].epochStartTimes, "E25");

    if (currentEpoch > 0) {
      (, uint256 epochExpiry) = getEpochTimes(nextEpoch - 1);
      require((block.timestamp > epochExpiry), "E9");
    }

    // Set the next epoch strikes
    totalEpochData[nextEpoch].epochStrikes = strikes;
    // Set epoch expiry
    totalEpochData[nextEpoch].epochExpiryTime = _expiry;

    for (uint256 i = 0; i < strikes.length; i++)
      emit StrikeSet(nextEpoch, strikes[i]);
    return true;
  }

  /**
   * @notice Sets leverage for next epoch
   * @param callsLeverages Leverage to set for next epoch
   * @param putsLeverages Leverage to set for next epoch
   * @return Whether leverage were set
   */
  function setLeverages(
    uint256[] memory callsLeverages,
    uint256[] memory putsLeverages
  ) external onlyRole(MANAGER_ROLE) whenNotPaused returns (bool) {
    uint256 nextEpoch = currentEpoch + 1;

    require(totalEpochData[nextEpoch].totalTokenDeposits == 0, "E8");
    require(totalEpochData[nextEpoch].epochStrikes.length > 0, "E23");

    if (currentEpoch > 0) {
      (, uint256 epochExpiry) = getEpochTimes(nextEpoch - 1);
      require((block.timestamp > epochExpiry), "E9");
    }

    // Set the next epoch leverages
    totalEpochData[nextEpoch].callsLeverages = callsLeverages;
    totalEpochData[nextEpoch].putsLeverages = putsLeverages;
    // Set the next epoch start time
    totalEpochData[nextEpoch].epochStartTimes = block.timestamp;

    for (uint256 i = 0; i < callsLeverages.length; i++)
      emit CallsLeverageSet(nextEpoch, callsLeverages[i]);

    for (uint256 i = 0; i < putsLeverages.length; i++)
      emit PutsLeverageSet(nextEpoch, putsLeverages[i]);

    initalizeDefault(nextEpoch);

    return true;
  }

  /**
   * @notice Deposit Curve 2Pool LP into the ssov to mint options in the next epoch for selected strikes
   * @param strikeIndex array of strike Indexs
   * @param callLeverageIndex array of call leverage Indexs
   * @param putLeverageIndex array of put leverage Indexs
   * @param amount array of amounts
   * @param user Address of the user to deposit for
   * @return Whether deposit was successful
   */
  function depositMultiple(
    uint256[] memory strikeIndex,
    uint256[] memory callLeverageIndex,
    uint256[] memory putLeverageIndex,
    uint256[] memory amount,
    address user
  ) external whenNotPaused isEligibleSender nonReentrant returns (bool) {
    require(strikeIndex.length == callLeverageIndex.length, "E2");
    require(putLeverageIndex.length == callLeverageIndex.length, "E2");

    for (uint256 i = 0; i < strikeIndex.length; i++) {
      deposit(
        strikeIndex[i],
        callLeverageIndex[i],
        putLeverageIndex[i],
        amount[i],
        user
      );
    }
    return true;
  }

  /**
   * @notice Deposit Curve 2Pool LP into the ssov to mint options in the next epoch for selected strikes
   * @param strikeIndex Index of strike
   * @param callLeverageIndex index of leverage
   * @param putLeverageIndex index of leverage
   * @param amount Amout of crvLP to deposit
   * @param user Address of the user to deposit for
   * @return Whether deposit was successful
   */
  function deposit(
    uint256 strikeIndex,
    uint256 callLeverageIndex,
    uint256 putLeverageIndex,
    uint256 amount,
    address user
  ) private whenNotPaused isEligibleSender returns (bool) {
    uint256 nextEpoch = currentEpoch + 1;

    if (currentEpoch > 0) {
      require(
        totalEpochData[currentEpoch].isEpochExpired &&
          !totalEpochData[nextEpoch].isVaultReady,
        "E18"
      );
    }

    // Must be a valid strikeIndex
    require(strikeIndex < totalEpochData[nextEpoch].epochStrikes.length, "E10");

    // Must be a valid levereageIndex
    require(
      callLeverageIndex < totalEpochData[nextEpoch].callsLeverages.length,
      "E22"
    );
    require(
      putLeverageIndex < totalEpochData[nextEpoch].putsLeverages.length,
      "E22"
    );
    // Both leverages can not be zero
    require(callLeverageIndex > 0 || putLeverageIndex > 0, "E24");
    // Must +ve amount
    require(amount > 0, "E11");

    // Must be a valid strike
    uint256 strike = totalEpochData[nextEpoch].epochStrikes[strikeIndex];

    // Must be a valid leverage
    uint256 callLeverage = totalEpochData[nextEpoch].callsLeverages[
      callLeverageIndex
    ];
    uint256 putLeverage = totalEpochData[nextEpoch].putsLeverages[
      putLeverageIndex
    ];

    bytes32 userStrike = keccak256(
      abi.encodePacked(user, strike, callLeverage, putLeverage)
    );

    // Transfer crvLP from msg.sender (maybe different from user param) to ssov
    crvLP.safeTransferFrom(msg.sender, address(this), amount);

    // Add to user epoch deposits
    userEpochStrikeDeposits[nextEpoch][userStrike].amount += amount;

    // Add to user epoch call leverages
    userEpochStrikeDeposits[nextEpoch][userStrike].callLeverage = callLeverage;

    // Add to user epoch put leverages
    userEpochStrikeDeposits[nextEpoch][userStrike].putLeverage = putLeverage;

    // Add to total epoch strike deposits
    totalStrikeData[nextEpoch][strike].leveragedCallsDeposits[
      callLeverageIndex
    ] += amount * callLeverage;

    totalStrikeData[nextEpoch][strike].leveragedPutsDeposits[
      putLeverageIndex
    ] += amount * putLeverage;

    totalStrikeData[nextEpoch][strike].totalCallsStrikeDeposits +=
      amount *
      callLeverage;
    totalStrikeData[nextEpoch][strike].totalPutsStrikeDeposits +=
      amount *
      putLeverage;

    totalEpochData[nextEpoch].totalCallsDeposits += amount * callLeverage;
    totalEpochData[nextEpoch].totalPutsDeposits += amount * putLeverage;

    totalEpochData[nextEpoch].totalTokenDeposits += amount;
    totalStrikeData[nextEpoch][strike].totalTokensStrikeDeposits += amount;

    // Deposit curve LP to the curve gauge for rewards
    ICrv2PoolGauge(crvPool).deposit(
      amount,
      address(this),
      false /* _claim_rewards */
    );

    emit Deposit(nextEpoch, strike, amount, user, msg.sender);

    return true;
  }

  /**
   * @notice Purchases puts for the current epoch
   * @param strikeIndex Strike index for current epoch
   * @param amount Amount of puts to purchase
   * @param user User to purchase options for
   * @return Whether purchase was successful
   */
  function purchase(
    uint256 strikeIndex,
    bool isPut,
    uint256 amount,
    address user
  )
    external
    whenNotPaused
    isEligibleSender
    nonReentrant
    returns (uint256, uint256)
  {
    uint256 epoch = currentEpoch;
    (, uint256 epochExpiry) = getEpochTimes(epoch);
    require((block.timestamp < epochExpiry), "E3");
    require(totalEpochData[epoch].isVaultReady, "E19");
    require(strikeIndex < totalEpochData[epoch].epochStrikes.length, "E10");
    require(amount > 0, "E11");

    uint256 strike = totalEpochData[epoch].epochStrikes[strikeIndex];
    bytes32 userStrike = keccak256(abi.encodePacked(user, strike));

    // Get total premium for all puts being purchased
    uint256 premium = calculatePremium(strike, amount, isPut);

    // Total fee charged
    uint256 totalFee = calculatePurchaseFees(
      getCurrentRate(),
      strike,
      amount,
      isPut
    );

    // Transfer premium from msg.sender (need not be same as user)
    crvLP.safeTransferFrom(msg.sender, address(this), premium + totalFee);

    // Transfer fee to FeeDistributor
    crvLP.safeTransfer(addresses.feeDistributor, totalFee);

    // Deposit curve LP to the curve gauge for rewards
    ICrv2PoolGauge(crvPool).deposit(
      premium,
      address(this),
      false /* _claim_rewards */
    );

    if (isPut) {
      // Add to total epoch data
      totalEpochData[epoch].totalPutsPurchased += amount;
      // Add to total epoch puts purchased
      totalStrikeData[epoch][strike].totalPutsPurchased += amount;
      // Add to user epoch puts purchased
      userStrikePurchaseData[epoch][userStrike].putsPurchased += amount;
      // Add to epoch premium per strike
      totalEpochData[epoch].epochStrikePutsPremium[strikeIndex] += premium;
      // Add to total epoch premium
      totalEpochData[epoch].epochPutsPremium += premium;
      // Add to user epoch premium
      userStrikePurchaseData[epoch][userStrike].userEpochPutsPremium += premium;
      // Transfer option tokens to user
      IERC20(totalEpochData[epoch].putsToken[strikeIndex]).safeTransfer(
        user,
        amount
      );
    } else {
      // Add tp total epoch data
      totalEpochData[epoch].totalCallsPurchased += amount;
      // Add to total epoch puts purchased
      totalStrikeData[epoch][strike].totalCallsPurchased += amount;
      // Add to user epoch puts purchased
      userStrikePurchaseData[epoch][userStrike].callsPurchased += amount;
      // Add to epoch premium per strike
      totalEpochData[epoch].epochStrikeCallsPremium[strikeIndex] += premium;
      // Add to total epoch premium
      totalEpochData[epoch].epochCallsPremium += premium;
      // Add to user epoch premium
      userStrikePurchaseData[epoch][userStrike]
        .userEpochCallsPremium += premium;
      // Transfer option tokens to user
      IERC20(totalEpochData[epoch].callsToken[strikeIndex]).safeTransfer(
        user,
        amount
      );
    }

    emit Purchase(epoch, strike, amount, premium, totalFee, user);

    return (premium, totalFee);
  }

  /**
   * @notice Settle calculates the PnL for the user and withdraws the PnL in the crvPool to the user. Will also the burn the option tokens from the user.
   * @param strikeIndex Strike index
   * @param isPut Whether the option is a put
   * @param amount Amount of options
   * @return pnl
   */
  function settle(
    uint256 strikeIndex,
    bool isPut,
    uint256 amount,
    uint256 epoch
  ) external whenNotPaused isEligibleSender nonReentrant returns (uint256 pnl) {
    require(strikeIndex < totalEpochData[epoch].epochStrikes.length, "E10");
    require(amount > 0, "E11");
    require(totalEpochData[epoch].isEpochExpired, "E16");

    uint256 strike = totalEpochData[epoch].epochStrikes[strikeIndex];
    require(strike != 0, "E12");

    OptionsToken optionToken = OptionsToken(
      isPut
        ? totalEpochData[epoch].putsToken[strikeIndex]
        : totalEpochData[epoch].callsToken[strikeIndex]
    );

    if (isPut) {
      require(optionToken.balanceOf(msg.sender) >= amount, "E15");
      pnl =
        (totalStrikeData[epoch][strike].putsSettlement * amount) /
        totalStrikeData[epoch][strike].totalPutsPurchased;
    } else {
      require(optionToken.balanceOf(msg.sender) >= amount, "E15");
      pnl =
        (totalStrikeData[epoch][strike].callsSettlement * amount) /
        totalStrikeData[epoch][strike].totalCallsPurchased;
    }
    optionToken.burnFrom(msg.sender, amount);

    // Total fee charged
    uint256 totalFee = calculateSettlementFees(
      totalEpochData[epoch].rateAtSettlement,
      pnl,
      amount,
      isPut
    );

    require(pnl > 0, "E14");

    // Transfer fee to FeeDistributor
    crvLP.safeTransfer(addresses.feeDistributor, totalFee);

    // Transfer PnL to user
    crvLP.safeTransfer(msg.sender, pnl - totalFee);

    emit Settle(epoch, strike, msg.sender, amount, pnl - totalFee, totalFee);
  }

  /**
   * @notice Withdraw function for user to withdraw their deposit for a strike, call and put leverages.
   * @param epoch epoch
   * @param strikeIndex Strike index
   * @param callLeverageIndex Call leverage index
   * @param putLeverageIndex Put leverage index
   * @return userCrvLpWithdrawAmount userCrvLpWithdrawAmount
   * @return rewards crv rewards for the user
   */
  function withdraw(
    uint256 epoch,
    uint256 strikeIndex,
    uint256 callLeverageIndex,
    uint256 putLeverageIndex,
    address user
  )
    private
    whenNotPaused
    isEligibleSender
    returns (uint256 userCrvLpWithdrawAmount, uint256 rewards)
  {
    require(totalEpochData[epoch].isEpochExpired, "E16");
    require(strikeIndex < totalEpochData[epoch].epochStrikes.length, "E10");

    // Must be a valid strike
    uint256 strike = totalEpochData[epoch].epochStrikes[strikeIndex];
    require(strike != 0, "E12");

    // Must be a valid leverage
    uint256 callLeverage = totalEpochData[epoch].callsLeverages[
      callLeverageIndex
    ];
    uint256 putLeverage = totalEpochData[epoch].putsLeverages[putLeverageIndex];

    bytes32 userStrike = keccak256(
      abi.encodePacked(user, strike, callLeverage, putLeverage)
    );

    uint256 userStrikeDeposits = userEpochStrikeDeposits[epoch][userStrike]
      .amount;
    require(userStrikeDeposits > 0, "E17");

    userCrvLpWithdrawAmount = getUserCrvLpWithdrawAmount(
      epoch,
      strike,
      callLeverageIndex,
      putLeverageIndex,
      userStrikeDeposits
    );

    rewards = getUserRewards(epoch, strike, strikeIndex, userStrikeDeposits);

    userEpochStrikeDeposits[epoch][userStrike].amount = 0;

    IERC20(addresses.crv).safeTransfer(user, rewards);

    crvLP.safeTransfer(user, userCrvLpWithdrawAmount);

    emit Withdraw(
      epoch,
      strike,
      user,
      userStrikeDeposits,
      userCrvLpWithdrawAmount,
      rewards
    );
  }

  /**
   * @notice Withdraw function for user to withdraw all their deposits.
   * @param epoch epoch
   * @param strikeIndex Strike index array
   * @param callLeverageIndex Call leverage index array
   * @param putLeverageIndex Put leverage index array
   * @return boolean success
   */
  function withdrawMultiple(
    uint256 epoch,
    uint256[] memory strikeIndex,
    uint256[] memory callLeverageIndex,
    uint256[] memory putLeverageIndex,
    address user
  ) external whenNotPaused isEligibleSender nonReentrant returns (bool) {
    require(strikeIndex.length == callLeverageIndex.length, "E2");
    require(putLeverageIndex.length == callLeverageIndex.length, "E2");
    for (uint256 i = 0; i < strikeIndex.length; i++) {
      withdraw(
        epoch,
        strikeIndex[i],
        callLeverageIndex[i],
        putLeverageIndex[i],
        user
      );
    }
    return true;
  }

  /**
   * @notice calculates user's LP withdraw amount.
   * @param epoch epoch
   * @param strike Strike
   * @param callLeverageIndex Call leverage index
   * @param putLeverageIndex Put leverage index
   * @param userStrikeDeposits user deposit amount without any leverage
   * @return usercrvLPWithdrawAmount userCrvLpWithdrawAmount
   */
  function getUserCrvLpWithdrawAmount(
    uint256 epoch,
    uint256 strike,
    uint256 callLeverageIndex,
    uint256 putLeverageIndex,
    uint256 userStrikeDeposits
  ) private view whenNotPaused returns (uint256 usercrvLPWithdrawAmount) {
    if (callLeverageIndex > 0) {
      usercrvLPWithdrawAmount =
        (totalStrikeData[epoch][strike].totalCallsStrikeBalance[
          callLeverageIndex
        ] * userStrikeDeposits) /
        (totalStrikeData[epoch][strike].leveragedCallsDeposits[
          callLeverageIndex
        ] / totalEpochData[epoch].callsLeverages[callLeverageIndex]);
    }

    if (putLeverageIndex > 0) {
      usercrvLPWithdrawAmount +=
        (totalStrikeData[epoch][strike].totalPutsStrikeBalance[
          putLeverageIndex
        ] * userStrikeDeposits) /
        (totalStrikeData[epoch][strike].leveragedPutsDeposits[
          putLeverageIndex
        ] / totalEpochData[epoch].putsLeverages[putLeverageIndex]);
    }
    if (callLeverageIndex > 0 && putLeverageIndex > 0) {
      usercrvLPWithdrawAmount = usercrvLPWithdrawAmount - userStrikeDeposits;
    }
  }

  /**
   * @notice calculates user's crv rewards amount.
   * @param epoch epoch
   * @param strike Strike
   * @param strikeIndex strike index
   * @param userStrikeDeposits user deposit amount without any leverage
   * @return rewards crv rewards
   */
  function getUserRewards(
    uint256 epoch,
    uint256 strike,
    uint256 strikeIndex,
    uint256 userStrikeDeposits
  ) private view whenNotPaused returns (uint256 rewards) {
    rewards =
      (totalEpochData[epoch].crvToDistribute *
        (totalStrikeData[epoch][strike].totalTokensStrikeDeposits +
          totalEpochData[epoch].epochStrikeCallsPremium[strikeIndex] +
          totalEpochData[epoch].epochStrikePutsPremium[strikeIndex])) /
      (totalEpochData[epoch].totalTokenDeposits +
        totalEpochData[epoch].epochCallsPremium +
        totalEpochData[epoch].epochPutsPremium);

    rewards =
      (rewards * userStrikeDeposits) /
      totalStrikeData[epoch][strike].totalTokensStrikeDeposits;
  }

  /*==== VIEWS ====*/

  /// @notice Returns the volatility from the volatility oracle
  /// @param _strike Strike of the option
  function getVolatility(uint256 _strike) public view returns (uint256) {
    return IVolatilityOracle(addresses.volatilityOracle).getVolatility(_strike);
  }

  /// @notice Calculate premium for an option
  /// @param _strike Strike price of the option
  /// @param _amount Amount of options
  /// @param _isPut is it a put option
  /// @return premium in crvLP
  function calculatePremium(
    uint256 _strike,
    uint256 _amount,
    bool _isPut
  ) public view returns (uint256 premium) {
    uint256 currentPrice = getCurrentRate();
    (, uint256 expiryTimestamp) = getEpochTimes(currentEpoch);
    uint256 expiry = (expiryTimestamp - block.timestamp) / 864;
    uint256 epochDuration = (expiryTimestamp -
      totalEpochData[currentEpoch].epochStartTimes) / 864;

    premium = (
      IOptionPricing(addresses.optionPricing).getOptionPrice(
        int256(currentPrice), // 1e8
        _strike, // 1e8
        int256(getVolatility(_strike) * 10), // 1e1
        int256(_amount), // 1e18
        _isPut, // isPut
        expiry, // 1e2
        epochDuration // 1e2
      )
    );

    premium = ((premium * 1e18) / getLpPrice());
  }

  /// @notice Calculate Pnl
  /// @param price price of crvPool
  /// @param strike strike price of the option
  /// @param amount amount of options
  /// @param isPut is it a put option
  /// Pnl is calculated as the difference between the strike and current intrest rate and the amount of intrest the notional has accured in the duration of the option
  function calculatePnl(
    uint256 price,
    uint256 strike,
    uint256 amount,
    bool isPut
  ) public view returns (uint256) {
    uint256 pnl;
    (uint256 start, uint256 end) = getEpochTimes(currentEpoch);
    uint256 duration = (end - start) / 86400;
    isPut
      ? (
        strike > price
          ? (pnl = (((strike - price) * amount * duration) / 36500) / 1e8) // (Strike - spot) x Notional x duration/365 / 100 for puts
          : (pnl = 0)
      )
      : (
        strike > price
          ? (pnl = 0)
          : (pnl = (((price - strike) * amount * duration) / 36500) / 1e8) // (Spot-Strike) x Notional x duration/365 / 100 for calls
      );
    return pnl;
  }

  /// @notice Calculate Fees for purchase
  /// @param price price of crvPool
  /// @param strike strike price of the crvPool option
  /// @param amount amount of options being bought
  /// @return the purchase fee in crvLP
  function calculatePurchaseFees(
    uint256 price,
    uint256 strike,
    uint256 amount,
    bool isPut
  ) public view returns (uint256) {
    return ((IFeeStrategy(addresses.feeStrategy).calculatePurchaseFees(
      price,
      strike,
      amount,
      isPut
    ) * 1e18) / getLpPrice());
  }

  /// @notice Calculate Fees for settlement of options
  /// @param rateAtSettlement settlement price of crvPool
  /// @param pnl total pnl
  /// @param amount amount of options being settled
  function calculateSettlementFees(
    uint256 rateAtSettlement,
    uint256 pnl,
    uint256 amount,
    bool isPut
  ) public view returns (uint256) {
    return ((IFeeStrategy(addresses.feeStrategy).calculateSettlementFees(
      rateAtSettlement,
      pnl,
      amount,
      isPut
    ) * 1e18) / getLpPrice());
  }

  /**
   * @notice Returns start and end times for an epoch
   * @param epoch Target epoch
   */
  function getEpochTimes(uint256 epoch)
    public
    view
    epochGreaterThanZero(epoch)
    returns (uint256 start, uint256 end)
  {
    return (
      totalEpochData[epoch].epochStartTimes,
      totalEpochData[epoch].epochExpiryTime
    );
  }

  /**
   * Returns epoch strike tokens arrays and strikes set for an epoch
   * @param epoch Target epoch
   */
  function getEpochData(uint256 epoch)
    external
    view
    epochGreaterThanZero(epoch)
    returns (
      uint256[] memory,
      address[] memory,
      address[] memory
    )
  {
    uint256 strikesLength = totalEpochData[epoch].epochStrikes.length;

    uint256[] memory _epochStrikes = new uint256[](strikesLength);
    address[] memory _epochCallsStrikeTokens = new address[](strikesLength);
    address[] memory _epochPutsStrikeTokens = new address[](strikesLength);

    for (uint256 i = 0; i < strikesLength; i++) {
      _epochCallsStrikeTokens[i] = totalEpochData[epoch].callsToken[i];
      _epochPutsStrikeTokens[i] = totalEpochData[epoch].putsToken[i];
      _epochStrikes[i] = totalEpochData[epoch].epochStrikes[i];
    }

    return (_epochStrikes, _epochCallsStrikeTokens, _epochPutsStrikeTokens);
  }

  /**
   * Returns calls and puts strike tokens arrays for an epoch
   * @param epoch Target epoch
   */
  function getEpochTokens(uint256 epoch)
    external
    view
    epochGreaterThanZero(epoch)
    returns (address[] memory, address[] memory)
  {
    uint256 strikesLength = totalEpochData[epoch].epochStrikes.length;

    address[] memory _epochCallsStrikeTokens = new address[](strikesLength);
    address[] memory _epochPutsStrikeTokens = new address[](strikesLength);

    for (uint256 i = 0; i < strikesLength; i++) {
      _epochCallsStrikeTokens[i] = totalEpochData[epoch].callsToken[i];
      _epochPutsStrikeTokens[i] = totalEpochData[epoch].putsToken[i];
    }

    return (_epochCallsStrikeTokens, _epochPutsStrikeTokens);
  }

  /**
   * Returns strikes set for a epoch
   * @param epoch Target epoch
   */
  function getEpochStrikes(uint256 epoch)
    external
    view
    epochGreaterThanZero(epoch)
    returns (uint256[] memory)
  {
    uint256 strikesLength = totalEpochData[epoch].epochStrikes.length;

    uint256[] memory _epochStrikes = new uint256[](strikesLength);

    for (uint256 i = 0; i < strikesLength; i++) {
      _epochStrikes[i] = totalEpochData[epoch].epochStrikes[i];
    }

    return (_epochStrikes);
  }

  /**
   * Returns leverages set for the epoch
   * @param epoch Target epoch
   */
  function getEpochLeverages(uint256 epoch)
    external
    view
    epochGreaterThanZero(epoch)
    returns (uint256[] memory, uint256[] memory)
  {
    uint256 callsLeveragesLength = totalEpochData[epoch].callsLeverages.length;

    uint256 putsLeveragesLength = totalEpochData[epoch].putsLeverages.length;

    uint256[] memory _callsLeverages = new uint256[](callsLeveragesLength);

    uint256[] memory _putsLeverages = new uint256[](putsLeveragesLength);

    for (uint256 i = 0; i < callsLeveragesLength; i++) {
      _callsLeverages[i] = totalEpochData[epoch].callsLeverages[i];
    }
    for (uint256 i = 0; i < putsLeveragesLength; i++) {
      _putsLeverages[i] = totalEpochData[epoch].putsLeverages[i];
    }

    return (_callsLeverages, _putsLeverages);
  }

  /**
   * Returns arrays for calls and puts premiums collected
   * @param epoch Target epoch
   */
  function getEpochPremiums(uint256 epoch)
    external
    view
    epochGreaterThanZero(epoch)
    returns (uint256[] memory, uint256[] memory)
  {
    uint256 strikesLength = totalEpochData[epoch].epochStrikes.length;

    uint256[] memory _callsPremium = new uint256[](strikesLength);

    uint256[] memory _putsPremium = new uint256[](strikesLength);

    for (uint256 i = 0; i < strikesLength; i++) {
      _callsPremium[i] = totalEpochData[epoch].epochStrikeCallsPremium[i];
      _putsPremium[i] = totalEpochData[epoch].epochStrikePutsPremium[i];
    }

    return (_callsPremium, _putsPremium);
  }

  /**
   * Returns epoch strike calls and puts deposits arrays
   * @param epoch Target epoch
   * @param strike Target strike
   */
  function getEpochStrikeData(uint256 epoch, uint256 strike)
    external
    view
    epochGreaterThanZero(epoch)
    returns (uint256[] memory, uint256[] memory)
  {
    uint256 callsLeveragesLength = totalEpochData[epoch].callsLeverages.length;

    uint256 putsLeveragesLength = totalEpochData[epoch].putsLeverages.length;

    uint256[] memory _callsDeposits = new uint256[](callsLeveragesLength);

    uint256[] memory _putsDeposits = new uint256[](putsLeveragesLength);

    for (uint256 i = 0; i < callsLeveragesLength; i++) {
      _callsDeposits[i] = totalStrikeData[epoch][strike].leveragedCallsDeposits[
        i
      ];
    }

    for (uint256 i = 0; i < putsLeveragesLength; i++) {
      _putsDeposits[i] = totalStrikeData[epoch][strike].leveragedPutsDeposits[
        i
      ];
    }

    return (_callsDeposits, _putsDeposits);
  }

  /**
   * @notice Returns the rate of the crvPool in ie8
   */
  function getCurrentRate() public view returns (uint256) {
    (uint256 start, uint256 end) = getEpochTimes(currentEpoch);
    return
      uint256(
        IGaugeOracle(addresses.gaugeOracle).getRate(
          start,
          end,
          addresses.curvePoolGauge
        )
      );
  }

  /**
   * @notice Returns the price of the Curve 2Pool LP token in 1e18
   */
  function getLpPrice() public view returns (uint256) {
    return crvLP.get_virtual_price();
  }

  /*==== MODIFIERS ====*/

  modifier epochGreaterThanZero(uint256 epoch) {
    require(epoch > 0, "E13");
    _;
  }
}

// ERROR MAPPING:
// {
//   "E1": "SSOV: Address cannot be a zero address",
//   "E2": "SSOV: Input lengths must match",
//   "E3": "SSOV: Epoch must not be expired",
//   "E4": "SSOV: Cannot expire epoch before epoch's expiry",
//   "E5": "SSOV: Already bootstrapped",
//   "E6": "SSOV: Strikes have not been set for next epoch",
//   "E7": "SSOV: Previous epoch has not expired",
//   "E8": "SSOV: Deposit already started",
//   "E9": "SSOV: Cannot set next strikes before current epoch's expiry",
//   "E10": "SSOV: Invalid strike index",
//   "E11": "SSOV: Invalid amount",
//   "E12": "SSOV: Invalid strike",
//   "E13": "SSOV: Epoch passed must be greater than 0",
//   "E14": "SSOV: Strike is higher than current price",
//   "E15": "SSOV: Option token balance is not enough",
//   "E16": "SSOV: Epoch must be expired",
//   "E17": "SSOV: User strike deposit amount must be greater than zero",
//   "E18": "SSOV: Deposit is only available between epochs",
//   "E19": "SSOV: Not bootstrapped",
//   "E21": "SSOV: Expire delay tolerance exceeded",
//   "E22": "SSOV: Invalid leverage Index",
//   "E23": "SSOV: Strikes not set for the epoch",
//   "E24": "SSOV: Can not deposit with both leverages set to 0",
//   "E25": "SSOV: Epoch expiry must be greater than epoch start time",
// }

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC20 } from "./external/interfaces/IERC20.sol";

contract IrVaultState {
  struct Addresses {
    address optionPricing;
    address gaugeOracle;
    address volatilityOracle;
    address crv;
    address curvePoolGauge;
    address feeStrategy;
    address feeDistributor;
  }

  struct UserStrikeDeposits {
    uint256 amount;
    uint256 callLeverage;
    uint256 putLeverage;
  }

  struct UserStrikePurchaseData {
    uint256 putsPurchased;
    uint256 callsPurchased;
    uint256 userEpochCallsPremium;
    uint256 userEpochPutsPremium;
  }

  struct StrikeData {
    uint256 totalTokensStrikeDeposits;
    uint256 totalCallsStrikeDeposits;
    uint256 totalPutsStrikeDeposits;
    uint256 totalCallsPurchased;
    uint256 totalPutsPurchased;
    uint256 callsSettlement;
    uint256 putsSettlement;
    uint256[] leveragedCallsDeposits;
    uint256[] leveragedPutsDeposits;
    uint256[] totalCallsStrikeBalance;
    uint256[] totalPutsStrikeBalance;
  }

  struct EpochData {
    uint256 totalCallsDeposits;
    uint256 totalPutsDeposits;
    uint256 totalTokenDeposits;
    uint256 epochCallsPremium;
    uint256 epochPutsPremium;
    uint256 totalCallsPurchased;
    uint256 totalPutsPurchased;
    uint256 epochStartTimes;
    uint256 epochExpiryTime;
    bool isEpochExpired;
    bool isVaultReady;
    uint256 epochBalanceAfterUnstaking;
    uint256 crvToDistribute;
    uint256 rateAtSettlement;
    uint256[] epochStrikes;
    uint256[] callsLeverages;
    uint256[] putsLeverages;
    address[] callsToken;
    address[] putsToken;
    uint256[] epochStrikeCallsPremium;
    uint256[] epochStrikePutsPremium;
  }

  /// @dev Current epoch for ssov
  uint256 public currentEpoch;

  /// @dev Contract addresses
  Addresses public addresses;

  /// @dev Expire delay tolerance
  uint256 public expireDelayTolerance = 5 minutes;

  /// @notice Epoch deposits by user for each strike
  /// @dev mapping (epoch => (abi.encodePacked(user, strike, callLeverage, putLeverage) => user deposits))
  mapping(uint256 => mapping(bytes32 => UserStrikeDeposits))
    public userEpochStrikeDeposits;

  /// @notice Puts purchased by user for each strike
  /// @dev mapping (epoch => (abi.encodePacked(user, strike) => user puts purchased))
  mapping(uint256 => mapping(bytes32 => UserStrikePurchaseData))
    public userStrikePurchaseData;

  /// @notice Total epoch deposits for specific strikes
  /// @dev mapping (epoch =>  StrikeDeposits))
  mapping(uint256 => EpochData) public totalEpochData;

  /// @notice Total epoch deposits for specific strikes
  /// @dev mapping (epoch => (strike => StrikeDeposits))
  mapping(uint256 => mapping(uint256 => StrikeData)) public totalStrikeData;

  /*==== ERRORS & EVENTS ====*/

  event ExpireDelayToleranceUpdate(uint256 expireDelayTolerance);

  event WindowSizeUpdate(uint256 windowSizeInHours);

  event AddressesSet(Addresses addresses);

  event EmergencyWithdraw(address sender);

  event EpochExpired(address sender, uint256 rateAtSettlement);

  event StrikeSet(uint256 epoch, uint256 strike);

  event CallsLeverageSet(uint256 epoch, uint256 leverage);

  event PutsLeverageSet(uint256 epoch, uint256 leverage);

  event Bootstrap(uint256 epoch);

  event Deposit(
    uint256 epoch,
    uint256 strike,
    uint256 amount,
    address user,
    address sender
  );

  event Purchase(
    uint256 epoch,
    uint256 strike,
    uint256 amount,
    uint256 premium,
    uint256 fee,
    address user
  );

  event Settle(
    uint256 epoch,
    uint256 strike,
    address user,
    uint256 amount,
    uint256 pnl, // pnl transfered to the user
    uint256 fee // fee sent to fee distributor
  );

  event Compound(
    uint256 epoch,
    uint256 rewards,
    uint256 oldBalance,
    uint256 newBalance
  );

  event Withdraw(
    uint256 epoch,
    uint256 strike,
    address user,
    uint256 userDeposits,
    uint256 crvLPWithdrawn,
    uint256 crvRewards
  );

  error ZeroAddress(bytes32 source, address destination);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from '../interfaces/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeERC20: decreased allowance below zero'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFeeStrategy {
  function calculatePurchaseFees(
    uint256,
    uint256,
    uint256,
    bool
  ) external view returns (uint256);

  function calculateSettlementFees(
    uint256,
    uint256,
    uint256,
    bool
  ) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/// @title ContractWhitelist
/// @author witherblock
/// @notice A helper contract that lets you add a list of whitelisted contracts that should be able to interact with restricited functions
abstract contract ContractWhitelist is Ownable {
    /// @dev contract => whitelisted or not
    mapping(address => bool) public whitelistedContracts;

    /*==== SETTERS ====*/

    /// @dev add to the contract whitelist
    /// @param _contract the address of the contract to add to the contract whitelist
    /// @return whether the contract was successfully added to the whitelist
    function addToContractWhitelist(address _contract)
        external
        onlyOwner
        returns (bool)
    {
        require(
            isContract(_contract),
            'ContractWhitelist: Address must be a contract address'
        );
        require(
            !whitelistedContracts[_contract],
            'ContractWhitelist: Contract already whitelisted'
        );

        whitelistedContracts[_contract] = true;

        emit AddToContractWhitelist(_contract);

        return true;
    }

    /// @dev remove from  the contract whitelist
    /// @param _contract the address of the contract to remove from the contract whitelist
    /// @return whether the contract was successfully removed from the whitelist
    function removeFromContractWhitelist(address _contract)
        external
        returns (bool)
    {
        require(
            whitelistedContracts[_contract],
            'ContractWhitelist: Contract not whitelisted'
        );

        whitelistedContracts[_contract] = false;

        emit RemoveFromContractWhitelist(_contract);

        return true;
    }

    /* ========== MODIFIERS ========== */

    // Modifier is eligible sender modifier
    modifier isEligibleSender() {
        if (isContract(msg.sender))
            require(
                whitelistedContracts[msg.sender],
                'ContractWhitelist: Contract must be whitelisted'
            );
        _;
    }

    /*==== VIEWS ====*/

    /// @dev checks for contract or eoa addresses
    /// @param addr the address to check
    /// @return whether the passed address is a contract address
    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /*==== EVENTS ====*/

    event AddToContractWhitelist(address indexed _contract);

    event RemoveFromContractWhitelist(address indexed _contract);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Contracts
import { ERC20PresetMinterPauserUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";

// Libraries
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Dopex SSOV V3 ERC20 Options Token
 */
contract OptionsToken is ERC20PresetMinterPauserUpgradeable {
  using Strings for uint256;

  /// @dev Is this a PUT or CALL options contract
  bool public isPut;

  /// @dev The strike of the options contract
  uint256 public strike;

  /// @dev The time of expiry of the options contract
  uint256 public expiry;

  /// @dev The address of the irVault creating the options contract
  address public irVault;

  /// @dev The symbol reperesenting the underlying asset of the option
  string public underlyingSymbol;

  /// @dev The symbol representing the collateral token of the option
  string public collateralSymbol;

  /*==== INITIALIZE FUNCTION ====*/

  /**
   * @notice Initialize function, equivalent of a constructor for upgradeable contracts
   * @param _irVault The address of the irVault creating the options contract
   * @param _isPut Whether the options is a put option
   * @param _strike The amount of strike asset that will be paid out per doToken
   * @param _expiry The time at which the insurance expires
   * @param _epoch The epoch of the irVault
   * @param _underlyingSymbol The symbol of the underlying asset token
   * @param _collateralSymbol The symbol of the collateral token
   */
  function initialize(
    address _irVault,
    bool _isPut,
    uint256 _strike,
    uint256 _expiry,
    uint256 _epoch,
    string memory _underlyingSymbol,
    string memory _collateralSymbol
  ) public {
    require(block.timestamp < _expiry, "Can't deploy an expired contract");

    irVault = _irVault;
    underlyingSymbol = _underlyingSymbol;
    collateralSymbol = _collateralSymbol;
    isPut = _isPut;
    strike = _strike;
    expiry = _expiry;

    string memory symbol = concatenate(_underlyingSymbol, "-EPOCH");
    symbol = concatenate(symbol, _epoch.toString());
    symbol = concatenate(symbol, "-");
    symbol = concatenate(symbol, (strike / 1e8).toString());
    symbol = concatenate(symbol, isPut ? "-P" : "-C");

    super.initialize("Dopex IR Vault Options Token", symbol);
  }

  /*==== VIEWS ====*/

  /**
   * @notice Returns true if the doToken contract has expired
   */
  function hasExpired() public view returns (bool) {
    return (block.timestamp >= expiry);
  }

  /*==== PURE FUNCTIONS ====*/

  /**
   * @notice Returns a concatenated string of a and b
   * @param a string a
   * @param b string b
   */
  function concatenate(string memory a, string memory b)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked(a, b));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVolatilityOracle {
  function getVolatility(uint256) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOptionPricing {
  function getOptionPrice(
    int256 currentPrice,
    uint256 strike,
    int256 volatility,
    int256 amount,
    bool isPut,
    uint256 expiry,
    uint256 epochDuration
  ) external view returns (uint256);
}