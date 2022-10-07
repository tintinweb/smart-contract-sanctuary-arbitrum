// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/IBorrowerPools.sol";

import "./extensions/AaveILendingPool.sol";
import "./lib/Errors.sol";
import "./lib/PoolLogic.sol";
import "./lib/Scaling.sol";
import "./lib/Types.sol";
import "./lib/Uint128WadRayMath.sol";

import "./PoolsController.sol";

contract BorrowerPools is PoolsController, IBorrowerPools {
  using PoolLogic for Types.Pool;
  using Scaling for uint128;
  using Uint128WadRayMath for uint128;

  function initialize(address governance) public initializer {
    _initialize();
    if (governance == address(0)) {
      // Prevent setting governance to null account
      governance = _msgSender();
    }
    _grantRole(DEFAULT_ADMIN_ROLE, governance);
    _grantRole(Roles.GOVERNANCE_ROLE, governance);
    _setRoleAdmin(Roles.BORROWER_ROLE, Roles.GOVERNANCE_ROLE);
    _setRoleAdmin(Roles.POSITION_ROLE, Roles.GOVERNANCE_ROLE);
  }

  // VIEW METHODS

  /**
   * @notice Returns the liquidity ratio of a given tick in a pool's order book.
   * The liquidity ratio is an accounting construct to deduce the accrued interest over time.
   * @param poolHash The identifier of the pool
   * @param rate The tick rate from which to extract the liquidity ratio
   * @return liquidityRatio The liquidity ratio of the given tick
   **/
  function getTickLiquidityRatio(bytes32 poolHash, uint128 rate) public view override returns (uint128 liquidityRatio) {
    liquidityRatio = pools[poolHash].ticks[rate].atlendisLiquidityRatio;
    if (liquidityRatio == 0) {
      liquidityRatio = uint128(PoolLogic.RAY);
    }
  }

  /**
   * @notice Returns the repartition between bonds and deposits of the given tick.
   * @param poolHash The identifier of the pool
   * @param rate The tick rate from which to get data
   * @return adjustedTotalAmount Total amount of deposit in the tick, excluding
   * the pending amounts
   * @return adjustedRemainingAmount Amount of tokens in tick deposited with the
   * underlying yield provider that were deposited before bond issuance
   * @return bondsQuantity The quantity of bonds within the tick
   * @return adjustedPendingAmount Amount of deposit in tick deposited with the
   * underlying yield provider that were deposited after bond issuance
   * @return atlendisLiquidityRatio The liquidity ratio of the given tick
   * @return accruedFees The total fees claimable in the current tick, either from
   * yield provider interests or liquidity rewards accrual
   **/
  function getTickAmounts(bytes32 poolHash, uint128 rate)
    public
    view
    override
    returns (
      uint128 adjustedTotalAmount,
      uint128 adjustedRemainingAmount,
      uint128 bondsQuantity,
      uint128 adjustedPendingAmount,
      uint128 atlendisLiquidityRatio,
      uint128 accruedFees
    )
  {
    Types.Tick storage tick = pools[poolHash].ticks[rate];
    return (
      tick.adjustedTotalAmount,
      tick.adjustedRemainingAmount,
      tick.bondsQuantity,
      tick.adjustedPendingAmount,
      tick.atlendisLiquidityRatio,
      tick.accruedFees
    );
  }

  /**
   * @notice Returns the timestamp of the last fee distribution to the tick
   * @param pool The identifier of the pool pool
   * @param rate The tick rate from which to get data
   * @return lastFeeDistributionTimestamp Timestamp of the last fee's distribution to the tick
   **/
  function getTickLastUpdate(string calldata pool, uint128 rate)
    public
    view
    override
    returns (uint128 lastFeeDistributionTimestamp)
  {
    Types.Tick storage tick = pools[keccak256(abi.encode(pool))].ticks[rate];
    return tick.lastFeeDistributionTimestamp;
  }

  /**
   * @notice Returns the current state of the pool's parameters
   * @param poolHash The identifier of the pool
   * @return weightedAverageLendingRate The average deposit bidding rate in the order book
   * @return adjustedPendingDeposits Amount of tokens deposited after bond
   * issuance and currently on third party yield provider
   **/
  function getPoolAggregates(bytes32 poolHash)
    external
    view
    override
    returns (uint128 weightedAverageLendingRate, uint128 adjustedPendingDeposits)
  {
    Types.Pool storage pool = pools[poolHash];
    Types.PoolParameters storage parameters = pools[poolHash].parameters;

    adjustedPendingDeposits = 0;

    if (pool.state.currentMaturity == 0) {
      weightedAverageLendingRate = estimateLoanRate(pool.parameters.MAX_BORROWABLE_AMOUNT, poolHash);
    } else {
      uint128 amountWeightedRate = 0;
      uint128 totalAmount = 0;
      uint128 rate = parameters.MIN_RATE;
      for (rate; rate != parameters.MAX_RATE + parameters.RATE_SPACING; rate += parameters.RATE_SPACING) {
        amountWeightedRate += pool.ticks[rate].normalizedLoanedAmount.wadMul(rate);
        totalAmount += pool.ticks[rate].normalizedLoanedAmount;
        adjustedPendingDeposits += pool.ticks[rate].adjustedPendingAmount;
      }
      weightedAverageLendingRate = amountWeightedRate.wadDiv(totalAmount);
    }
  }

  /**
   * @notice Returns the current maturity of the pool
   * @param poolHash The identifier of the pool
   * @return poolCurrentMaturity The pool's current maturity
   **/
  function getPoolMaturity(bytes32 poolHash) public view override returns (uint128 poolCurrentMaturity) {
    return pools[poolHash].state.currentMaturity;
  }

  /**
   * @notice Estimates the lending rate corresponding to the input amount,
   * depending on the current state of the pool
   * @param normalizedBorrowedAmount The amount to be borrowed from the pool
   * @param poolHash The identifier of the pool
   * @return estimatedRate The estimated loan rate for the current state of the pool
   **/
  function estimateLoanRate(uint128 normalizedBorrowedAmount, bytes32 poolHash)
    public
    view
    override
    returns (uint128 estimatedRate)
  {
    Types.Pool storage pool = pools[poolHash];
    Types.PoolParameters storage parameters = pool.parameters;

    if (pool.state.currentMaturity > 0 || pool.state.defaulted || pool.state.closed || !pool.state.active) {
      return 0;
    }

    if (normalizedBorrowedAmount > pool.parameters.MAX_BORROWABLE_AMOUNT) {
      normalizedBorrowedAmount = pool.parameters.MAX_BORROWABLE_AMOUNT;
    }

    uint128 yieldProviderLiquidityRatio = uint128(
      parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(parameters.UNDERLYING_TOKEN))
    );
    uint128 rate = pool.parameters.MIN_RATE;
    uint128 normalizedRemainingAmount = normalizedBorrowedAmount;
    uint128 amountWeightedRate = 0;
    for (rate; rate != parameters.MAX_RATE + parameters.RATE_SPACING; rate += parameters.RATE_SPACING) {
      (uint128 atlendisLiquidityRatio, , , ) = pool.peekFeesForTick(rate, yieldProviderLiquidityRatio);
      uint128 tickAmount = pool.ticks[rate].adjustedRemainingAmount.wadRayMul(atlendisLiquidityRatio);
      if (tickAmount < normalizedRemainingAmount) {
        normalizedRemainingAmount -= tickAmount;
        amountWeightedRate += tickAmount.wadMul(rate);
      } else {
        amountWeightedRate += normalizedRemainingAmount.wadMul(rate);
        normalizedRemainingAmount = 0;
        break;
      }
    }
    if (normalizedBorrowedAmount == normalizedRemainingAmount) {
      return 0;
    }
    estimatedRate = amountWeightedRate.wadDiv(normalizedBorrowedAmount - normalizedRemainingAmount);
  }

  /**
   * @notice Returns the token amount's repartition between bond quantity and normalized
   * deposited amount currently placed on third party yield provider
   * @param poolHash The identifier of the pool
   * @param rate Tick's rate
   * @param adjustedAmount Adjusted amount of tokens currently on third party yield provider
   * @param bondsIssuanceIndex The identifier of the borrow group
   * @return bondsQuantity Quantity of bonds held
   * @return normalizedDepositedAmount Amount of deposit currently on third party yield provider
   **/
  function getAmountRepartition(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmount,
    uint128 bondsIssuanceIndex
  ) public view override returns (uint128 bondsQuantity, uint128 normalizedDepositedAmount) {
    Types.Pool storage pool = pools[poolHash];
    uint128 yieldProviderLiquidityRatio = uint128(
      pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(pool.parameters.UNDERLYING_TOKEN))
    );

    if (bondsIssuanceIndex > pool.state.currentBondsIssuanceIndex) {
      return (0, adjustedAmount.wadRayMul(yieldProviderLiquidityRatio));
    }

    uint128 adjustedDepositedAmount;
    (bondsQuantity, adjustedDepositedAmount) = pool.computeAmountRepartitionForTick(
      rate,
      adjustedAmount,
      bondsIssuanceIndex
    );

    (uint128 atlendisLiquidityRatio, uint128 accruedFees, , ) = pool.peekFeesForTick(rate, yieldProviderLiquidityRatio);
    uint128 accruedFeesShare = pool.peekAccruedFeesShare(rate, adjustedDepositedAmount, accruedFees);
    normalizedDepositedAmount = adjustedDepositedAmount.wadRayMul(atlendisLiquidityRatio) + accruedFeesShare;
  }

  /**
   * @notice Returns the total amount a borrower has to repay to a pool. Includes borrowed
   * amount, late repay fees and protocol fees
   * @param poolHash The identifier of the pool
   * @return normalizedRepayAmount Total repay amount
   **/
  function getRepayAmounts(bytes32 poolHash, bool earlyRepay)
    public
    view
    override
    returns (
      uint128 normalizedRepayAmount,
      uint128 lateRepayFee,
      uint128 repaymentFees
    )
  {
    uint128 preFeeRepayAmount = pools[poolHash].getRepayValue(earlyRepay);
    lateRepayFee = pools[poolHash].getLateRepayFeePerBond().wadMul(preFeeRepayAmount);
    repaymentFees = pools[poolHash].getRepaymentFees(preFeeRepayAmount + lateRepayFee);
    normalizedRepayAmount = preFeeRepayAmount + repaymentFees + lateRepayFee;
  }

  // LENDER METHODS

  /**
   * @notice Gets called within the Position.deposit() function and enables a lender to deposit assets
   * into a given pool's order book. The lender specifies a rate (price) at which it is willing to
   * lend out its assets (bid on the zero coupon bond). The full amount will initially be deposited
   * on the underlying yield provider until the borrower sells bonds at the specified rate.
   * @param normalizedAmount The amount of the given asset to deposit
   * @param rate The rate at which to bid for a bond
   * @param poolHash The identifier of the pool
   * @param underlyingToken Contract' address of the token to be deposited
   * @param sender The lender address who calls the deposit function on the Position
   * @return adjustedAmount Deposited amount adjusted with current liquidity index
   * @return bondsIssuanceIndex The identifier of the borrow group to which the deposit has been allocated
   **/
  function deposit(
    uint128 rate,
    bytes32 poolHash,
    address underlyingToken,
    address sender,
    uint128 normalizedAmount
  )
    public
    override
    whenNotPaused
    onlyRole(Roles.POSITION_ROLE)
    returns (uint128 adjustedAmount, uint128 bondsIssuanceIndex)
  {
    Types.Pool storage pool = pools[poolHash];
    if (pool.state.defaulted) {
      revert Errors.BP_POOL_DEFAULTED();
    }
    if (!pool.state.active) {
      revert Errors.BP_POOL_NOT_ACTIVE();
    }
    if (pool.state.closed) {
      revert Errors.BP_POOL_CLOSED();
    }
    if (underlyingToken != pool.parameters.UNDERLYING_TOKEN) {
      revert Errors.BP_UNMATCHED_TOKEN();
    }
    if (rate < pool.parameters.MIN_RATE) {
      revert Errors.BP_OUT_OF_BOUND_MIN_RATE();
    }
    if (rate > pool.parameters.MAX_RATE) {
      revert Errors.BP_OUT_OF_BOUND_MAX_RATE();
    }
    if ((rate - pool.parameters.MIN_RATE) % pool.parameters.RATE_SPACING != 0) {
      revert Errors.BP_RATE_SPACING();
    }
    adjustedAmount = 0;
    bondsIssuanceIndex = 0;
    (adjustedAmount, bondsIssuanceIndex) = pool.depositToTick(rate, normalizedAmount);
    pool.depositToYieldProvider(sender, normalizedAmount);
  }

  /**
   * @notice Gets called within the Position.withdraw() function and enables a lender to
   * evaluate the exact amount of tokens it is allowed to withdraw
   * @dev This method is meant to be used exclusively with the withdraw() method
   * Under certain circumstances, this method can return incorrect values, that would otherwise
   * be rejected by the checks made in the withdraw() method
   * @param poolHash The identifier of the pool
   * @param rate The rate the position is bidding for
   * @param adjustedAmount The amount of tokens in the position, adjusted to the deposit liquidity ratio
   * @param bondsIssuanceIndex An index determining deposit timing
   * @return adjustedAmountToWithdraw The amount of tokens to withdraw, adjuste for borrow pool use
   * @return depositedAmountToWithdraw The amount of tokens to withdraw, adjuste for position use
   * @return remainingBondsQuantity The quantity of bonds remaining within the position
   * @return bondsMaturity The maturity of bonds remaining within the position after withdraw
   **/
  function getWithdrawAmounts(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmount,
    uint128 bondsIssuanceIndex
  )
    public
    view
    override
    returns (
      uint128 adjustedAmountToWithdraw,
      uint128 depositedAmountToWithdraw,
      uint128 remainingBondsQuantity,
      uint128 bondsMaturity
    )
  {
    Types.Pool storage pool = pools[poolHash];
    if (!pool.state.active) {
      revert Errors.BP_POOL_NOT_ACTIVE();
    }

    (remainingBondsQuantity, adjustedAmountToWithdraw) = pool.computeAmountRepartitionForTick(
      rate,
      adjustedAmount,
      bondsIssuanceIndex
    );

    // return amount adapted to bond index
    depositedAmountToWithdraw = adjustedAmountToWithdraw.wadRayDiv(
      pool.getBondIssuanceMultiplierForTick(rate, bondsIssuanceIndex)
    );
    bondsMaturity = pool.state.currentMaturity;
  }

  /**
   * @notice Gets called within the Position.withdraw() function and enables a lender to
   * withdraw assets that are deposited with the underlying yield provider
   * @param poolHash The identifier of the pool
   * @param rate The rate the position is bidding for
   * @param adjustedAmountToWithdraw The actual amount of tokens to withdraw from the position
   * @param bondsIssuanceIndex An index determining deposit timing
   * @param owner The address to which the withdrawns funds are sent
   * @return normalizedDepositedAmountToWithdraw Actual amount of tokens withdrawn and sent to the lender
   **/
  function withdraw(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmountToWithdraw,
    uint128 bondsIssuanceIndex,
    address owner
  ) public override whenNotPaused onlyRole(Roles.POSITION_ROLE) returns (uint128 normalizedDepositedAmountToWithdraw) {
    Types.Pool storage pool = pools[poolHash];

    if (bondsIssuanceIndex > (pool.state.currentBondsIssuanceIndex + 1)) {
      revert Errors.BP_BOND_ISSUANCE_ID_TOO_HIGH();
    }
    bool isPendingDeposit = bondsIssuanceIndex > pool.state.currentBondsIssuanceIndex;

    if (
      !((!(isPendingDeposit) && pool.ticks[rate].adjustedRemainingAmount > 0) ||
        (isPendingDeposit && pool.ticks[rate].adjustedPendingAmount > 0))
    ) {
      revert Errors.BP_TARGET_BOND_ISSUANCE_INDEX_EMPTY();
    }
    if (adjustedAmountToWithdraw <= 0) {
      revert Errors.BP_NO_DEPOSIT_TO_WITHDRAW();
    }

    normalizedDepositedAmountToWithdraw = pool.withdrawDepositedAmountForTick(
      rate,
      adjustedAmountToWithdraw,
      bondsIssuanceIndex
    );

    pool.parameters.YIELD_PROVIDER.withdraw(
      pool.parameters.UNDERLYING_TOKEN,
      normalizedDepositedAmountToWithdraw.scaleFromWad(pool.parameters.TOKEN_DECIMALS),
      owner
    );
  }

  /**
   * @notice Gets called within Position.updateRate() and updates the order book ticks affected by the position
   * updating its rate. This is only possible as long as there are no bonds in the position, i.e the full
   * position currently lies with the yield provider
   * @param adjustedAmount The adjusted balance of tokens of the given position
   * @param poolHash The identifier of the pool
   * @param oldRate The current rate of the position
   * @param newRate The new rate of the position
   * @param oldBondsIssuanceIndex The identifier of the borrow group from the given position
   * @return newAdjustedAmount The updated amount of tokens of the position adjusted by the
   * new tick's global liquidity ratio
   * @return newBondsIssuanceIndex The new borrow group id to which the updated position is linked
   **/
  function updateRate(
    uint128 adjustedAmount,
    bytes32 poolHash,
    uint128 oldRate,
    uint128 newRate,
    uint128 oldBondsIssuanceIndex
  )
    public
    override
    whenNotPaused
    onlyRole(Roles.POSITION_ROLE)
    returns (
      uint128 newAdjustedAmount,
      uint128 newBondsIssuanceIndex,
      uint128 normalizedAmount
    )
  {
    Types.Pool storage pool = pools[poolHash];

    if (pool.state.closed) {
      revert Errors.BP_POOL_CLOSED();
    }
    // cannot update rate when being borrowed
    (uint128 bondsQuantity, ) = getAmountRepartition(poolHash, oldRate, adjustedAmount, oldBondsIssuanceIndex);
    if (bondsQuantity != 0) {
      revert Errors.BP_LOAN_ONGOING();
    }
    if (newRate < pool.parameters.MIN_RATE) {
      revert Errors.BP_OUT_OF_BOUND_MIN_RATE();
    }
    if (newRate > pool.parameters.MAX_RATE) {
      revert Errors.BP_OUT_OF_BOUND_MAX_RATE();
    }
    if ((newRate - pool.parameters.MIN_RATE) % pool.parameters.RATE_SPACING != 0) {
      revert Errors.BP_RATE_SPACING();
    }

    // input amount adapted to bond index
    uint128 adjustedBondIndexAmount = adjustedAmount.wadRayMul(
      pool.getBondIssuanceMultiplierForTick(oldRate, oldBondsIssuanceIndex)
    );
    normalizedAmount = pool.withdrawDepositedAmountForTick(oldRate, adjustedBondIndexAmount, oldBondsIssuanceIndex);
    (newAdjustedAmount, newBondsIssuanceIndex) = pool.depositToTick(newRate, normalizedAmount);
  }

  // BORROWER METHODS

  /**
   * @notice Called by the borrower to sell bonds to the order book.
   * The affected ticks get updated according the amount of bonds sold.
   * @param to The address to which the borrowed funds should be sent.
   * @param loanAmount The total amount of the loan
   **/
  function borrow(address to, uint128 loanAmount) external override whenNotPaused onlyRole(Roles.BORROWER_ROLE) {
    bytes32 poolHash = borrowerAuthorizedPools[_msgSender()];
    Types.Pool storage pool = pools[poolHash];
    if (pool.state.closed) {
      revert Errors.BP_POOL_CLOSED();
    }
    if (pool.state.defaulted) {
      revert Errors.BP_POOL_DEFAULTED();
    }
    if (pool.state.currentMaturity > 0 && (block.timestamp > pool.state.currentMaturity)) {
      revert Errors.BP_MULTIPLE_BORROW_AFTER_MATURITY();
    }

    uint128 normalizedLoanAmount = loanAmount.scaleToWad(pool.parameters.TOKEN_DECIMALS);
    uint128 normalizedEstablishmentFee = normalizedLoanAmount.wadMul(pool.parameters.ESTABLISHMENT_FEE_RATE);
    uint128 normalizedBorrowedAmount = normalizedLoanAmount - normalizedEstablishmentFee;
    if (pool.state.normalizedBorrowedAmount + normalizedLoanAmount > pool.parameters.MAX_BORROWABLE_AMOUNT) {
      revert Errors.BP_BORROW_MAX_BORROWABLE_AMOUNT_EXCEEDED();
    }

    if (block.timestamp < pool.state.nextLoanMinStart) {
      revert Errors.BP_BORROW_COOLDOWN_PERIOD_NOT_OVER();
    }
    // collectFees should be called before changing pool global state as fee collection depends on it
    pool.collectFees();

    if (normalizedLoanAmount > pool.state.normalizedAvailableDeposits) {
      revert Errors.BP_BORROW_OUT_OF_BOUND_AMOUNT();
    }

    uint128 remainingAmount = normalizedLoanAmount;
    uint128 currentInterestRate = pool.state.lowerInterestRate - pool.parameters.RATE_SPACING;
    while (remainingAmount > 0 && currentInterestRate < pool.parameters.MAX_RATE) {
      currentInterestRate += pool.parameters.RATE_SPACING;
      if (pool.ticks[currentInterestRate].adjustedRemainingAmount > 0) {
        (uint128 bondsPurchasedQuantity, uint128 normalizedUsedAmountForPurchase) = pool
          .getBondsIssuanceParametersForTick(currentInterestRate, remainingAmount);
        pool.addBondsToTick(currentInterestRate, bondsPurchasedQuantity, normalizedUsedAmountForPurchase);
        remainingAmount -= normalizedUsedAmountForPurchase;
      }
    }
    if (remainingAmount != 0) {
      revert Errors.BP_BORROW_UNSUFFICIENT_BORROWABLE_AMOUNT_WITHIN_BRACKETS();
    }
    if (pool.state.currentMaturity == 0) {
      pool.state.currentMaturity = uint128(block.timestamp + pool.parameters.LOAN_DURATION);
      emit Borrow(poolHash, normalizedBorrowedAmount, normalizedEstablishmentFee);
    } else {
      emit FurtherBorrow(poolHash, normalizedBorrowedAmount, normalizedEstablishmentFee);
    }

    protocolFees[poolHash] += normalizedEstablishmentFee;
    pool.state.normalizedBorrowedAmount += normalizedLoanAmount;
    pool.parameters.YIELD_PROVIDER.withdraw(
      pool.parameters.UNDERLYING_TOKEN,
      normalizedBorrowedAmount.scaleFromWad(pool.parameters.TOKEN_DECIMALS),
      to
    );
  }

  /**
   * @notice Repays a currently outstanding bonds of the given pool.
   **/
  function repay() external override whenNotPaused onlyRole(Roles.BORROWER_ROLE) {
    bytes32 poolHash = borrowerAuthorizedPools[_msgSender()];
    Types.Pool storage pool = pools[poolHash];
    if (pool.state.defaulted) {
      revert Errors.BP_POOL_DEFAULTED();
    }
    if (pool.state.currentMaturity == 0) {
      revert Errors.BP_REPAY_NO_ACTIVE_LOAN();
    }
    bool earlyRepay = pool.state.currentMaturity > block.timestamp;
    if (earlyRepay && !pool.parameters.EARLY_REPAY) {
      revert Errors.BP_EARLY_REPAY_NOT_ACTIVATED();
    }

    // collectFees should be called before changing pool global state as fee collection depends on it
    pool.collectFees();

    uint128 lateRepayFee;
    bool bondsIssuanceIndexAlreadyIncremented = false;
    uint128 normalizedRepayAmount;
    uint128 lateRepayFeePerBond = pool.getLateRepayFeePerBond();

    for (
      uint128 rate = pool.state.lowerInterestRate;
      rate <= pool.parameters.MAX_RATE;
      rate += pool.parameters.RATE_SPACING
    ) {
      (uint128 normalizedRepayAmountForTick, uint128 lateRepayFeeForTick) = pool.repayForTick(
        rate,
        lateRepayFeePerBond
      );
      normalizedRepayAmount += normalizedRepayAmountForTick + lateRepayFeeForTick;
      lateRepayFee += lateRepayFeeForTick;
      bool indexIncremented = pool.includePendingDepositsForTick(rate, bondsIssuanceIndexAlreadyIncremented);
      bondsIssuanceIndexAlreadyIncremented = indexIncremented || bondsIssuanceIndexAlreadyIncremented;
    }

    uint128 repaymentFees = pool.getRepaymentFees(normalizedRepayAmount);
    normalizedRepayAmount += repaymentFees;

    pool.depositToYieldProvider(_msgSender(), normalizedRepayAmount);
    pool.state.nextLoanMinStart = uint128(block.timestamp) + pool.parameters.COOLDOWN_PERIOD;

    pool.state.bondsIssuedQuantity = 0;
    protocolFees[poolHash] += repaymentFees;
    pool.state.normalizedAvailableDeposits += normalizedRepayAmount;

    if (block.timestamp > (pool.state.currentMaturity + pool.parameters.REPAYMENT_PERIOD)) {
      emit LateRepay(
        poolHash,
        normalizedRepayAmount,
        lateRepayFee,
        repaymentFees,
        pool.state.normalizedAvailableDeposits,
        pool.state.nextLoanMinStart
      );
    } else if (pool.state.currentMaturity > block.timestamp) {
      emit EarlyRepay(
        poolHash,
        normalizedRepayAmount,
        repaymentFees,
        pool.state.normalizedAvailableDeposits,
        pool.state.nextLoanMinStart
      );
    } else {
      emit Repay(
        poolHash,
        normalizedRepayAmount,
        repaymentFees,
        pool.state.normalizedAvailableDeposits,
        pool.state.nextLoanMinStart
      );
    }

    // set global data for next loan
    pool.state.currentMaturity = 0;
    pool.state.normalizedBorrowedAmount = 0;
  }

  /**
   * @notice Called by the borrower to top up liquidity rewards' reserve that
   * is distributed to liquidity providers at the pre-defined distribution rate.
   * @param amount Amount of tokens that will be add up to the pool's liquidity rewards reserve
   **/
  function topUpLiquidityRewards(uint128 amount) external override whenNotPaused onlyRole(Roles.BORROWER_ROLE) {
    Types.Pool storage pool = pools[borrowerAuthorizedPools[_msgSender()]];
    uint128 normalizedAmount = amount.scaleToWad(pool.parameters.TOKEN_DECIMALS);

    pool.depositToYieldProvider(_msgSender(), normalizedAmount);
    uint128 yieldProviderLiquidityRatio = pool.topUpLiquidityRewards(normalizedAmount);

    if (
      !pool.state.active &&
      pool.state.remainingAdjustedLiquidityRewardsReserve.wadRayMul(yieldProviderLiquidityRatio) >=
      pool.parameters.LIQUIDITY_REWARDS_ACTIVATION_THRESHOLD
    ) {
      pool.state.active = true;
      emit PoolActivated(pool.parameters.POOL_HASH);
    }

    emit TopUpLiquidityRewards(borrowerAuthorizedPools[_msgSender()], normalizedAmount);
  }

  // PUBLIC METHODS

  /**
   * @notice Collect yield provider fees as well as liquidity rewards for the target tick
   * @param poolHash The identifier of the pool
   **/
  function collectFeesForTick(bytes32 poolHash, uint128 rate) external override whenNotPaused {
    Types.Pool storage pool = pools[poolHash];
    pool.collectFees(rate);
  }

  /**
   * @notice Collect yield provider fees as well as liquidity rewards for the whole pool
   * Iterates over all pool initialized ticks
   * @param poolHash The identifier of the pool
   **/
  function collectFees(bytes32 poolHash) external override whenNotPaused {
    Types.Pool storage pool = pools[poolHash];
    pool.collectFees();
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {PoolLogic} from "./lib/PoolLogic.sol";
import {Scaling} from "./lib/Scaling.sol";
import {Uint128WadRayMath} from "./lib/Uint128WadRayMath.sol";

import "./extensions/AaveILendingPool.sol";
import "./extensions/IERC20PartialDecimals.sol";
import "./lib/Errors.sol";
import "./lib/Roles.sol";
import "./lib/Types.sol";

import "./interfaces/IPoolsController.sol";

abstract contract PoolsController is AccessControlUpgradeable, PausableUpgradeable, IPoolsController {
  using PoolLogic for Types.Pool;
  using Scaling for uint128;
  using Uint128WadRayMath for uint128;

  // borrower address to pool hash
  mapping(address => bytes32) public borrowerAuthorizedPools;

  // interest rate pool
  mapping(bytes32 => Types.Pool) internal pools;

  // protocol fees per pool
  mapping(bytes32 => uint128) internal protocolFees;

  function _initialize() internal onlyInitializing {
    // both initializers below are called to comply with OpenZeppelin's
    // recommendations even if in practice they don't do anything
    __AccessControl_init();
    __Pausable_init_unchained();
  }

  // VIEW FUNCTIONS

  /**
   * @notice Returns the parameters of a pool
   * @param poolHash The identifier of the pool
   * @return underlyingToken Address of the underlying token of the pool
   * @return minRate Minimum rate of deposits accepted in the pool
   * @return maxRate Maximum rate of deposits accepted in the pool
   * @return rateSpacing Difference between two rates in the pool
   * @return maxBorrowableAmount Maximum amount of tokens that can be borrowed from the pool
   * @return loanDuration Duration of a loan in the pool
   * @return liquidityRewardsDistributionRate Rate at which liquidity rewards are distributed to lenders
   * @return cooldownPeriod Period after a loan during which a borrower cannot take another loan
   * @return repaymentPeriod Period after a loan end during which a borrower can repay without penalty
   * @return lateRepayFeePerBondRate Penalty a borrower has to pay when it repays late
   * @return liquidityRewardsActivationThreshold Minimum amount of liqudity rewards a borrower has to
   * deposit to active the pool
   **/
  function getPoolParameters(bytes32 poolHash)
    external
    view
    override
    returns (
      address underlyingToken,
      uint128 minRate,
      uint128 maxRate,
      uint128 rateSpacing,
      uint128 maxBorrowableAmount,
      uint128 loanDuration,
      uint128 liquidityRewardsDistributionRate,
      uint128 cooldownPeriod,
      uint128 repaymentPeriod,
      uint128 lateRepayFeePerBondRate,
      uint128 liquidityRewardsActivationThreshold
    )
  {
    Types.PoolParameters storage poolParameters = pools[poolHash].parameters;
    return (
      poolParameters.UNDERLYING_TOKEN,
      poolParameters.MIN_RATE,
      poolParameters.MAX_RATE,
      poolParameters.RATE_SPACING,
      poolParameters.MAX_BORROWABLE_AMOUNT,
      poolParameters.LOAN_DURATION,
      poolParameters.LIQUIDITY_REWARDS_DISTRIBUTION_RATE,
      poolParameters.COOLDOWN_PERIOD,
      poolParameters.REPAYMENT_PERIOD,
      poolParameters.LATE_REPAY_FEE_PER_BOND_RATE,
      poolParameters.LIQUIDITY_REWARDS_ACTIVATION_THRESHOLD
    );
  }

  /**
   * @notice Returns the fee rates of a pool
   * @return establishmentFeeRate Amount of fees paid to the protocol at borrow time
   * @return repaymentFeeRate Amount of fees paid to the protocol at repay time
   **/
  function getPoolFeeRates(bytes32 poolHash)
    external
    view
    override
    returns (uint128 establishmentFeeRate, uint128 repaymentFeeRate)
  {
    Types.PoolParameters storage poolParameters = pools[poolHash].parameters;
    return (poolParameters.ESTABLISHMENT_FEE_RATE, poolParameters.REPAYMENT_FEE_RATE);
  }

  /**
   * @notice Returns the state of a pool
   * @param poolHash The identifier of the pool
   * @return active Signals if a pool is active and ready to accept deposits
   * @return defaulted Signals if a pool was defaulted
   * @return closed Signals if a pool was closed
   * @return currentMaturity End timestamp of current loan
   * @return bondsIssuedQuantity Amount of bonds issued, to be repaid at maturity
   * @return normalizedBorrowedAmount Actual amount of tokens that were borrowed
   * @return normalizedAvailableDeposits Actual amount of tokens available to be borrowed
   * @return lowerInterestRate Minimum rate at which a deposit was made
   * @return nextLoanMinStart Cool down period, minimum timestamp after which a new loan can be taken
   * @return remainingAdjustedLiquidityRewardsReserve Remaining liquidity rewards to be distributed to lenders
   * @return yieldProviderLiquidityRatio Last recorded yield provider liquidity ratio
   * @return currentBondsIssuanceIndex Current borrow period identifier of the pool
   **/
  function getPoolState(bytes32 poolHash)
    external
    view
    override
    returns (
      bool active,
      bool defaulted,
      bool closed,
      uint128 currentMaturity,
      uint128 bondsIssuedQuantity,
      uint128 normalizedBorrowedAmount,
      uint128 normalizedAvailableDeposits,
      uint128 lowerInterestRate,
      uint128 nextLoanMinStart,
      uint128 remainingAdjustedLiquidityRewardsReserve,
      uint128 yieldProviderLiquidityRatio,
      uint128 currentBondsIssuanceIndex
    )
  {
    Types.PoolState storage poolState = pools[poolHash].state;
    return (
      poolState.active,
      poolState.defaulted,
      poolState.closed,
      poolState.currentMaturity,
      poolState.bondsIssuedQuantity,
      poolState.normalizedBorrowedAmount,
      poolState.normalizedAvailableDeposits,
      poolState.lowerInterestRate,
      poolState.nextLoanMinStart,
      poolState.remainingAdjustedLiquidityRewardsReserve,
      poolState.yieldProviderLiquidityRatio,
      poolState.currentBondsIssuanceIndex
    );
  }

  /**
   * @notice Returns the state of a pool
   * @return earlyRepay Flag that signifies whether the early repay feature is activated or not
   **/
  function isEarlyRepay(bytes32 poolHash) external view override returns (bool earlyRepay) {
    return pools[poolHash].parameters.EARLY_REPAY;
  }

  /**
   * @notice Returns the state of a pool
   * @return defaultTimestamp The timestamp at which the pool was defaulted
   **/
  function getDefaultTimestamp(bytes32 poolHash) external view override returns (uint128 defaultTimestamp) {
    return pools[poolHash].state.defaultTimestamp;
  }

  // PROTOCOL MANAGEMENT

  function getProtocolFees(bytes32 poolHash) public view returns (uint128) {
    return protocolFees[poolHash].scaleFromWad(pools[poolHash].parameters.TOKEN_DECIMALS);
  }

  /**
   * @notice Withdraws protocol fees to a target address
   * @param poolHash The identifier of the pool
   * @param amount The amount of tokens claimed
   * @param to The address receiving the fees
   **/
  function claimProtocolFees(
    bytes32 poolHash,
    uint128 amount,
    address to
  ) external override onlyRole(Roles.GOVERNANCE_ROLE) {
    uint128 normalizedAmount = amount.scaleToWad(pools[poolHash].parameters.TOKEN_DECIMALS);
    if (pools[poolHash].parameters.POOL_HASH != poolHash) {
      revert Errors.PC_POOL_NOT_ACTIVE();
    }

    if (normalizedAmount > protocolFees[poolHash]) {
      revert Errors.PC_NOT_ENOUGH_PROTOCOL_FEES();
    }

    protocolFees[poolHash] -= normalizedAmount;
    pools[poolHash].parameters.YIELD_PROVIDER.withdraw(pools[poolHash].parameters.UNDERLYING_TOKEN, amount, to);

    emit ClaimProtocolFees(poolHash, normalizedAmount, to);
  }

  /**
   * @notice Stops all actions on all pools
   **/
  function freezePool() external override onlyRole(Roles.GOVERNANCE_ROLE) {
    _pause();
  }

  /**
   * @notice Cancel a freeze, makes actions available again on all pools
   **/
  function unfreezePool() external override onlyRole(Roles.GOVERNANCE_ROLE) {
    _unpause();
  }

  // BORROWER MANAGEMENT
  /**
   * @notice Creates a new pool
   * @param params The parameters of the new pool
   **/
  function createNewPool(PoolCreationParams calldata params) external override onlyRole(Roles.GOVERNANCE_ROLE) {
    // run verifications on parameters value
    verifyPoolCreationParameters(params);

    // initialize pool state and parameters
    pools[params.poolHash].parameters = Types.PoolParameters({
      POOL_HASH: params.poolHash,
      UNDERLYING_TOKEN: params.underlyingToken,
      TOKEN_DECIMALS: IERC20PartialDecimals(params.underlyingToken).decimals(),
      YIELD_PROVIDER: params.yieldProvider,
      MIN_RATE: params.minRate,
      MAX_RATE: params.maxRate,
      RATE_SPACING: params.rateSpacing,
      MAX_BORROWABLE_AMOUNT: params.maxBorrowableAmount,
      LOAN_DURATION: params.loanDuration,
      LIQUIDITY_REWARDS_DISTRIBUTION_RATE: params.distributionRate,
      COOLDOWN_PERIOD: params.cooldownPeriod,
      REPAYMENT_PERIOD: params.repaymentPeriod,
      LATE_REPAY_FEE_PER_BOND_RATE: params.lateRepayFeePerBondRate,
      ESTABLISHMENT_FEE_RATE: params.establishmentFeeRate,
      REPAYMENT_FEE_RATE: params.repaymentFeeRate,
      LIQUIDITY_REWARDS_ACTIVATION_THRESHOLD: params.liquidityRewardsActivationThreshold,
      EARLY_REPAY: params.earlyRepay
    });

    pools[params.poolHash].state.yieldProviderLiquidityRatio = uint128(
      params.yieldProvider.getReserveNormalizedIncome(address(params.underlyingToken))
    );

    emit PoolCreated(params);

    if (pools[params.poolHash].parameters.LIQUIDITY_REWARDS_ACTIVATION_THRESHOLD == 0) {
      pools[params.poolHash].state.active = true;
      emit PoolActivated(pools[params.poolHash].parameters.POOL_HASH);
    }
  }

  /**
   * @notice Verifies that conditions to create a new pool are met
   * @param params The parameters of the new pool
   **/
  function verifyPoolCreationParameters(PoolCreationParams calldata params) internal view {
    if ((params.maxRate - params.minRate) % params.rateSpacing != 0) {
      revert Errors.PC_RATE_SPACING_COMPLIANCE();
    }
    if (params.poolHash == bytes32(0)) {
      revert Errors.PC_ZERO_POOL();
    }
    if (pools[params.poolHash].parameters.POOL_HASH != bytes32(0)) {
      revert Errors.PC_POOL_ALREADY_SET_FOR_BORROWER();
    }
    uint256 yieldProviderLiquidityRatio = params.yieldProvider.getReserveNormalizedIncome(params.underlyingToken);
    if (yieldProviderLiquidityRatio < PoolLogic.RAY) {
      revert Errors.PC_POOL_TOKEN_NOT_SUPPORTED();
    }
    if (params.establishmentFeeRate > PoolLogic.WAD) {
      revert Errors.PC_ESTABLISHMENT_FEES_TOO_HIGH();
    }
  }

  /**
   * @notice Allow an address to interact with a borrower pool
   * @param borrowerAddress The address to allow
   * @param poolHash The identifier of the pool
   **/
  function allow(address borrowerAddress, bytes32 poolHash) external override onlyRole(Roles.GOVERNANCE_ROLE) {
    if (poolHash == bytes32(0)) {
      revert Errors.PC_ZERO_POOL();
    }
    if (borrowerAddress == address(0)) {
      revert Errors.PC_ZERO_ADDRESS();
    }
    if (pools[poolHash].parameters.POOL_HASH != poolHash) {
      revert Errors.PC_POOL_NOT_ACTIVE();
    }
    if (borrowerAuthorizedPools[borrowerAddress] != bytes32(0)) {
      revert Errors.PC_BORROWER_ALREADY_AUTHORIZED();
    }
    grantRole(Roles.BORROWER_ROLE, borrowerAddress);
    borrowerAuthorizedPools[borrowerAddress] = poolHash;
    emit BorrowerAllowed(borrowerAddress, poolHash);
  }

  /**
   * @notice Remove borrower pool interaction rights from an address
   * @param borrowerAddress The address to disallow
   * @param poolHash The identifier of the pool
   **/
  function disallow(address borrowerAddress, bytes32 poolHash) external override onlyRole(Roles.GOVERNANCE_ROLE) {
    if (poolHash == bytes32(0)) {
      revert Errors.PC_ZERO_POOL();
    }
    if (borrowerAddress == address(0)) {
      revert Errors.PC_ZERO_ADDRESS();
    }
    if (pools[poolHash].parameters.POOL_HASH != poolHash) {
      revert Errors.PC_POOL_NOT_ACTIVE();
    }
    if (borrowerAuthorizedPools[borrowerAddress] != poolHash) {
      revert Errors.PC_DISALLOW_UNMATCHED_BORROWER();
    }
    revokeRole(Roles.BORROWER_ROLE, borrowerAddress);
    delete borrowerAuthorizedPools[borrowerAddress];
    emit BorrowerDisallowed(borrowerAddress, poolHash);
  }

  /**
   * @notice Flags the pool as closed
   * @param poolHash The identifier of the pool
   **/
  function closePool(bytes32 poolHash, address to) external override onlyRole(Roles.GOVERNANCE_ROLE) {
    if (poolHash == bytes32(0)) {
      revert Errors.PC_ZERO_POOL();
    }
    if (to == address(0)) {
      revert Errors.PC_ZERO_ADDRESS();
    }
    Types.Pool storage pool = pools[poolHash];
    if (pool.parameters.POOL_HASH != poolHash) {
      revert Errors.PC_POOL_NOT_ACTIVE();
    }
    if (pool.state.closed) {
      revert Errors.PC_POOL_ALREADY_CLOSED();
    }
    pool.state.closed = true;

    uint128 remainingNormalizedLiquidityRewardsReserve = 0;
    if (pool.state.remainingAdjustedLiquidityRewardsReserve > 0) {
      uint128 yieldProviderLiquidityRatio = uint128(
        pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(pool.parameters.UNDERLYING_TOKEN))
      );
      remainingNormalizedLiquidityRewardsReserve = pool.state.remainingAdjustedLiquidityRewardsReserve.wadRayMul(
        yieldProviderLiquidityRatio
      );

      pool.state.remainingAdjustedLiquidityRewardsReserve = 0;
      pool.parameters.YIELD_PROVIDER.withdraw(
        pools[poolHash].parameters.UNDERLYING_TOKEN,
        remainingNormalizedLiquidityRewardsReserve.scaleFromWad(pool.parameters.TOKEN_DECIMALS),
        to
      );
    }
    emit PoolClosed(poolHash, remainingNormalizedLiquidityRewardsReserve);
  }

  /**
   * @notice Flags the pool as defaulted
   * @param poolHash The identifier of the pool to default
   **/
  function setDefault(bytes32 poolHash) external override onlyRole(Roles.GOVERNANCE_ROLE) {
    Types.Pool storage pool = pools[poolHash];
    if (pool.state.defaulted) {
      revert Errors.PC_POOL_DEFAULTED();
    }
    if (pool.state.currentMaturity == 0) {
      revert Errors.PC_NO_ONGOING_LOAN();
    }
    if (block.timestamp < pool.state.currentMaturity + pool.parameters.REPAYMENT_PERIOD) {
      revert Errors.PC_REPAYMENT_PERIOD_ONGOING();
    }

    pool.state.defaulted = true;
    pool.state.defaultTimestamp = uint128(block.timestamp);
    uint128 distributedLiquidityRewards = pool.distributeLiquidityRewards();

    emit Default(poolHash, distributedLiquidityRewards);
  }

  // POOL PARAMETERS MANAGEMENT
  /**
   * @notice Set the maximum amount of tokens that can be borrowed in the target pool
   **/
  function setMaxBorrowableAmount(uint128 maxBorrowableAmount, bytes32 poolHash)
    external
    override
    onlyRole(Roles.GOVERNANCE_ROLE)
  {
    if (pools[poolHash].parameters.POOL_HASH != poolHash) {
      revert Errors.PC_POOL_NOT_ACTIVE();
    }
    pools[poolHash].parameters.MAX_BORROWABLE_AMOUNT = maxBorrowableAmount;

    emit SetMaxBorrowableAmount(maxBorrowableAmount, poolHash);
  }

  /**
   * @notice Set the pool liquidity rewards distribution rate
   **/
  function setLiquidityRewardsDistributionRate(uint128 distributionRate, bytes32 poolHash)
    external
    override
    onlyRole(Roles.GOVERNANCE_ROLE)
  {
    if (pools[poolHash].parameters.POOL_HASH != poolHash) {
      revert Errors.PC_POOL_NOT_ACTIVE();
    }
    pools[poolHash].parameters.LIQUIDITY_REWARDS_DISTRIBUTION_RATE = distributionRate;

    emit SetLiquidityRewardsDistributionRate(distributionRate, poolHash);
  }

  /**
   * @notice Set the pool establishment protocol fee rate
   **/
  function setEstablishmentFeeRate(uint128 establishmentFeeRate, bytes32 poolHash)
    external
    override
    onlyRole(Roles.GOVERNANCE_ROLE)
  {
    if (!pools[poolHash].state.active) {
      revert Errors.PC_POOL_NOT_ACTIVE();
    }
    if (establishmentFeeRate > PoolLogic.WAD) {
      revert Errors.PC_ESTABLISHMENT_FEES_TOO_HIGH();
    }

    pools[poolHash].parameters.ESTABLISHMENT_FEE_RATE = establishmentFeeRate;

    emit SetEstablishmentFeeRate(establishmentFeeRate, poolHash);
  }

  /**
   * @notice Set the pool repayment protocol fee rate
   **/
  function setRepaymentFeeRate(uint128 repaymentFeeRate, bytes32 poolHash)
    external
    override
    onlyRole(Roles.GOVERNANCE_ROLE)
  {
    if (!pools[poolHash].state.active) {
      revert Errors.PC_POOL_NOT_ACTIVE();
    }

    pools[poolHash].parameters.REPAYMENT_FEE_RATE = repaymentFeeRate;

    emit SetRepaymentFeeRate(repaymentFeeRate, poolHash);
  }

  /**
   * @notice Set the pool early repay option
   **/
  function setEarlyRepay(bool earlyRepay, bytes32 poolHash) external override onlyRole(Roles.GOVERNANCE_ROLE) {
    if (!pools[poolHash].state.active) {
      revert Errors.PC_POOL_NOT_ACTIVE();
    }

    pools[poolHash].parameters.EARLY_REPAY = earlyRepay;

    emit SetEarlyRepay(earlyRepay, poolHash);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "base64-sol/base64.sol";

import "./BorrowerPools.sol";
import "./interfaces/IPositionManager.sol";
import "./interfaces/IPositionManager.sol";
import "./interfaces/IPositionDescriptor.sol";
import "./lib/Errors.sol";
import "./lib/Roles.sol";

contract PositionDescriptor is IPositionDescriptor {
  BorrowerPools public pools;
  mapping(bytes32 => string) internal _poolIdentifiers;
  mapping(string => bytes32) internal _poolHashes;

  constructor(BorrowerPools _pools) {
    pools = _pools;
  }

  /**
   * @notice Get the pool hash corresponding to the input pool identifier
   * @param poolIdentifier The identifier of the pool
   **/
  function getPoolHash(string calldata poolIdentifier) public view override returns (bytes32) {
    return _poolHashes[poolIdentifier];
  }

  /**
   * @notice Get the pool identifier corresponding to the input pool hash
   * @param poolHash The hash of the pool
   **/
  function getPoolIdentifier(bytes32 poolHash) public view override returns (string memory) {
    return _poolIdentifiers[poolHash];
  }

  /**
   * @notice Set the pool string identifier corresponding to the input pool hash
   * Pool identifiers can be updated several times, old pool names can be reused
   * @param poolIdentifier The string identifier to associate with the corresponding pool hash
   * @param poolHash The identifier of the pool
   **/
  function setPoolIdentifier(string calldata poolIdentifier, bytes32 poolHash) public override {
    if (!pools.hasRole(Roles.GOVERNANCE_ROLE, msg.sender)) {
      revert Errors.POD_NOT_ALLOWED();
    }
    if (_poolHashes[poolIdentifier] != 0) {
      revert Errors.POD_BAD_INPUT();
    }
    // release old identifier
    _poolHashes[_poolIdentifiers[poolHash]] = 0;
    _poolIdentifiers[poolHash] = poolIdentifier;
    _poolHashes[poolIdentifier] = poolHash;
    emit SetPoolIdentifier(poolIdentifier, poolHash);
  }

  /**
   * @notice Returns the encoded svg for positions artwork
   * @param position The address of the position manager contract
   * @param tokenId The tokenId of the position
   **/
  function tokenURI(IPositionManager position, uint128 tokenId) public view override returns (string memory) {
    (bytes32 poolHash, , uint128 rate, address underlyingToken, , , ) = position.position(tokenId);
    (uint128 bondsQuantity, uint128 normalizedDepositedAmount) = position.getPositionRepartition(tokenId);
    string memory symbol = ERC20Upgradeable(underlyingToken).symbol();

    string memory image = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" '
            'xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 532 754.5" '
            'style="enable-background:new 0 0 532 754.5;" xml:space="preserve">',
            generateBackground(),
            generateArt(),
            generateAtlendisName(),
            generatePositionMetadata(tokenId, poolHash, symbol, rate, normalizedDepositedAmount, bondsQuantity),
            "</svg>"
          )
        )
      )
    );
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              '{"name":"Position #',
              uint2str(tokenId),
              '",'
              '"description":"A Position on the Atlendis protocol for pool ',
              _poolIdentifiers[poolHash],
              ". This NFT represents your share of the pool, its theoritical price depends on the status of the pool, "
              "when you deposited, the amount of tokens you originally deposited and the different rewards allocated to it."
              '", "external_url":"https://app.atlendis.io/",'
              '"image": "data:image/svg+xml;base64,',
              image,
              '"}'
            )
          )
        )
      );
  }

  function uint2str(uint128 _i) internal pure returns (string memory str) {
    if (_i == 0) {
      return "0";
    }
    uint128 j = _i;
    uint128 length;
    while (j != 0) {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint128 k = length;
    j = _i;
    while (j != 0) {
      bstr[--k] = bytes1(uint8(48 + (j % 10)));
      j /= 10;
    }
    str = string(bstr);
  }

  function generateBackground() internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<style type="text/css">.st1{fill:none;stroke:#777188;stroke-width:0.5;stroke-miterlimit:10;}'
          ".st2{fill:#777188;}"
          ".st3{fill:#FFFFFF;}"
          ".st4{fill:#FCB4E0;}"
          ".st5{font-family:'Roboto-bold';font-size:16px;}"
          "</style>"
          '<radialGradient id="SVGID_1_" cx="253.4884" cy="417.4284" r="373.2191" '
          'gradientTransform="matrix(0.8986 0 0 0.8633 38.203 16.8953)" gradientUnits="userSpaceOnUse">'
          '<stop  offset="0" style="stop-color:#3A003F"/><stop  offset="1" style="stop-color:#0A002A"/></radialGradient>'
          '<path style="fill:url(#SVGID_1_);stroke:#FFFFFF;stroke-width:0.4404;stroke-miterlimit:10;" '
          'd="M0,749.9V4.6C0,2.1,2.1,0,4.6,0h522.8c2.5,0,4.6,2.1,4.6,4.6v745.3c0,2.5-2.1,4.6-4.6,4.6H4.6C2.1,754.5,0,752.4,0,749.9z"/>'
          '<rect x="27.3" y="61.4" class="st1" width="477.8" height="572.9"/>'
          '<line class="st1" x1="27.3" y1="538.7" x2="505.1" y2="538.7"/>'
          '<line class="st1" x1="27.3" y1="443.6" x2="505.1" y2="443.6"/>'
          '<line class="st1" x1="27.3" y1="348.1" x2="505.1" y2="348.1"/>'
          '<line class="st1" x1="27.3" y1="252.5" x2="505.1" y2="252.5"/>'
          '<line class="st1" x1="27.3" y1="157" x2="505.1" y2="157"/>'
          '<line class="st1" x1="122.8" y1="61.4" x2="122.8" y2="634.3"/>'
          '<line class="st1" x1="218.4" y1="61.4" x2="218.4" y2="634.3"/>'
          '<line class="st1" x1="314" y1="61.4" x2="314" y2="634.3"/>'
          '<line class="st1" x1="409.5" y1="61.4" x2="409.5" y2="634.3"/>'
          '<circle class="st2" cx="409.5" cy="157" r="5.4"/>'
          '<circle class="st2" cx="505.1" cy="347.8" r="5.4"/>'
          '<circle class="st2" cx="27.3" cy="538.7" r="5.4"/>'
          '<circle class="st2" cx="27.3" cy="156.4" r="5.4"/>'
        )
      );
  }

  function generateArt() internal pure returns (string memory) {
    return string(abi.encodePacked(generateTopPlanets(), generateCenterPlanets(), generateDownPlanets()));
  }

  function generateTopPlanets() internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<linearGradient id="1" gradientUnits="userSpaceOnUse" x1="502.8664" y1="485.6057" x2="587.8019" '
          'y2="485.6057" gradientTransform="matrix(-0.7096 -0.7046 0.7046 -0.7096 147.9199 858.1921)">'
          '<stop  offset="0" style="stop-color:#FAB2DE"/><stop  offset="1" style="stop-color:#0000FF"/>'
          '</linearGradient><circle style="fill:url(#1);" cx="103.1" cy="129.4" r="42.5"/>'
          '<linearGradient id="2" gradientUnits="userSpaceOnUse" x1="4853.835" y1="984.5833" x2="4854.8218" '
          'y2="1023.5588" gradientTransform="matrix(-0.9772 -0.2123 0.2123 -0.9772 4667.0605 2228.1553)">'
          '<stop  offset="0" style="stop-color:#00FFFF"/><stop  offset="1" style="stop-color:#FFFF00"/>'
          '</linearGradient><circle style="fill:url(#2);" cx="136.7" cy="215.3" r="19"/>'
          '<linearGradient id="3" gradientUnits="userSpaceOnUse" x1="697.1088" y1="685.6257" x2="784.6827" '
          'y2="685.6257" gradientTransform="matrix(-2.0426 0.6767 -0.7431 -0.8353 2272.0312 264.6844)">'
          '<stop offset="0" style="stop-color:#00FFFF"/><stop  offset="1" style="stop-color:#9DFC92"/></linearGradient>'
          '<line style="fill:none;stroke:url(#3);stroke-width:4.142;stroke-linecap:round;stroke-linejoin:round;'
          'stroke-miterlimit:10;" x1="342.6" y1="174.2" x2="155.9" y2="212.4"/><linearGradient id="4" '
          'gradientUnits="userSpaceOnUse" x1="348.7628" y1="119.7764" x2="350.8899" y2="203.7983">'
          '<stop  offset="0" style="stop-color:#00FFFF"/><stop  offset="1" style="stop-color:#0000FF"/>'
          '</linearGradient><circle style="fill:url(#4);" cx="350" cy="166.8" r="41"/><circle style="fill:#FFFF00;" '
          'cx="354.8" cy="70" r="5.9"/>'
          '<linearGradient id="5" gradientUnits="userSpaceOnUse" x1="140.7756" y1="230.1122" x2="228.9412" y2="230.1122">'
          '<stop  offset="0" style="stop-color:#9DFC92"/><stop  offset="1" style="stop-color:#FF7BAC"/></linearGradient>'
          '<line style="fill:none;stroke:url(#5);stroke-width:4.7337;stroke-linecap:round;stroke-linejoin:round;'
          'stroke-miterlimit:10;" x1="143.1" y1="219.2" x2="226.6" y2="241.1"/>'
          '<linearGradient id="6" gradientUnits="userSpaceOnUse" x1="695.0284" y1="812.7755" x2="783.7858" '
          'y2="812.7755" gradientTransform="matrix(-1.1737 0.9697 -0.8244 -0.6412 1822.474 11.7986)">',
          '<stop  offset="0" style="stop-color:#353DF7"/><stop  offset="1" style="stop-color:#FF7BAC"/></linearGradient>'
          '<line style="fill:none;stroke:url(#6);stroke-width:5.3254;stroke-linecap:round;stroke-linejoin:'
          'round;stroke-miterlimit:10;" x1="342.6" y1="174.2" x2="226.6" y2="241.1"/>'
        )
      );
  }

  function generateCenterPlanets() internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<circle style="fill:#0000FF" cx="114" cy="320" r="38"/>'
          '<linearGradient id="7" gradientUnits="userSpaceOnUse" x1="279.8008" y1="1203.038" x2="578.9129" '
          'y2="1203.038" gradientTransform="matrix(0 1 -1 0 1444.4052 -54.4462)">'
          '<stop  offset="0" style="stop-color:#FAB2DE"/><stop  offset="1" style="stop-color:#0000FF"/>'
          '</linearGradient><circle style="fill:url(#7);" cx="241.4" cy="374.9" r="149.6"/>'
          '<linearGradient id="8" gradientUnits="userSpaceOnUse" x1="202.9501" y1="390.4209" x2="109.6353" y2="483.7357">'
          '<stop  offset="0" style="stop-color:#0B0443"/><stop  offset="0.5173" style="stop-color:#1B1464"/>'
          '<stop  offset="1" style="stop-color:#2E3190"/></linearGradient>'
          '<path style="fill:url(#8);" d="M207.8,399.6c27.7,41.8,31.5,88,8.6,103.2c-23,'
          '15.2-64-6.3-91.7-48.1s-31.5-88-8.6-103.2C139,336.3,180.1,357.9,207.8,399.6z"/>'
          '<linearGradient id="9" gradientUnits="userSpaceOnUse" x1="705.8905" y1="841.9223" x2="797.4905" '
          'y2="841.9223" gradientTransform="matrix(-0.7071 0.7071 -0.7071 -0.7071 1263.1495 522.8206)">'
          '<stop  offset="0.2165" style="stop-color:#FAB2DE"/><stop  offset="1" style="stop-color:#00FFFF"/>'
          '</linearGradient><circle style="fill:url(#9);" cx="136.3" cy="459" r="45.8"/>'
          '<linearGradient id="10" gradientUnits="userSpaceOnUse" x1="1589.9778" y1="817.77" x2="1605.3485" '
          'y2="860.5405" gradientTransform="matrix(-0.9832 -0.1825 0.1825 -0.9832 1799.8251 1471.0231)">'
          '<stop  offset="0" style="stop-color:#0B0443"/><stop  offset="0.5173" style="stop-color:#1B1464"/>'
          '<stop  offset="1" style="stop-color:#2E3190"/></linearGradient><circle style="fill:url(#10);" cx="381.4" cy="349.8" r="22.1"/>'
          '<linearGradient id="11" gradientUnits="userSpaceOnUse" x1="225.6964" y1="201.0739" x2="227.4934" y2="272.0549">'
          '<stop  offset="0" style="stop-color:#FC6EC0"/><stop  offset="1" style="stop-color:#9C005D"/>'
          '</linearGradient><circle style="fill:url(#11);" cx="226.7" cy="240.8" r="34.7"/>'
        )
      );
  }

  function generateDownPlanets() internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<linearGradient id="12" gradientUnits="userSpaceOnUse" x1="484.1273" y1="295.5512" x2="485.3994" '
          'y2="345.7959" gradientTransform="matrix(0.9045 0.4266 -0.4266 0.9045 193.3309 -47.055)">'
          '<stop  offset="0" style="stop-color:#FC6EC0"/><stop  offset="1" style="stop-color:#9C005D"/>'
          '</linearGradient><circle style="fill:url(#12);" cx="493.8" cy="452.5" r="24.5"/>'
          '<linearGradient id="13" gradientUnits="userSpaceOnUse" x1="528.0872" y1="444.3404" x2="529.0894" '
          'y2="483.9227" gradientTransform="matrix(0.9045 0.4266 -0.4266 0.9045 193.3309 -47.055)">'
          '<stop  offset="0" style="stop-color:#00FFFF"/><stop  offset="1" style="stop-color:#0000FF"/>'
          '</linearGradient><circle style="fill:url(#13);" cx="472.5" cy="600.4" r="19.3"/>'
          '<linearGradient id="14" gradientUnits="userSpaceOnUse" x1="1017.4314" y1="453.2621" x2="1106.1887" '
          'y2="453.2621" gradientTransform="matrix(-0.8497 0.1398 -8.259396e-02 -0.9876 1369.6598 893.7979)">'
          '<stop  offset="0" style="stop-color:#4C6FF5"/><stop  offset="0.3634" style="stop-color:#4A4FD1"/>'
          '<stop  offset="1" style="stop-color:#45108A"/></linearGradient>'
          '<line style="fill:none;stroke:url(#14);stroke-width:5.3254;stroke-linecap:round;stroke-linejoin:round;'
          'stroke-miterlimit:10;" x1="466.4" y1="599.5" x2="393.7" y2="589.6"/>'
          '<linearGradient id="15" gradientUnits="userSpaceOnUse" x1="545.4843" y1="617.3547" x2="634.2416" '
          'y2="617.3547" gradientTransform="matrix(-1.1943 1.5673 -1.0482 -0.316 1778.2054 -209.5829)">'
          '<stop  offset="0" style="stop-color:#AA4688"/><stop  offset="1" style="stop-color:#353DF7"/></linearGradient>'
          '<line style="fill:none;stroke:url(#15);stroke-width:5.3254;stroke-linecap:round;stroke-linejoin:round;'
          'stroke-miterlimit:10;" x1="487.9" y1="457.9" x2="365.3" y2="581.7"/>'
          '<linearGradient id="16" gradientUnits="userSpaceOnUse" x1="423.5873" y1="549.3148" x2="424.7167" '
          'y2="443.1502" gradientTransform="matrix(0.9045 0.4266 -0.4266 0.9045 193.3309 -47.055)">',
          '<stop  offset="9.595960e-02" style="stop-color:#381077"/><stop  offset="1" style="stop-color:#7C1DC9"/>'
          '</linearGradient><circle style="fill:url(#16);" cx="365.8" cy="581.6" r="39.3"/>'
        )
      );
  }

  function generateAtlendisName() internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<path class="st3" d="M378.2,30.5l5.4,19.1h-2.3l-0.8-3.1H376l-0.8,3.1h-2.3L378.2,'
          '30.5z M380,44.5l-1.2-4.8l-0.5-2.2l-0.5,2.2l-1.3,4.8H380z"/>'
          '<path class="st3" d="M395.2,33.1h-2.9V31h8v2.1h-2.9v16.5h-2.2V33.1z"/>'
          '<path class="st3" d="M410.6,31h2.2v16.5h4.8v2h-7V31z"/>'
          '<path class="st3" d="M427.5,31h6.2v2.1h-4.1v7.1h3.5v2.1h-3.5v5.3h4.1v2.1h-6.2V31z"/>'
          '<path class="st3" d="M444.6,30.3l5.8,9.7l1.3,2.3l-0.1-2.2V31h2.2v19l-5.9-9.7l-1.3-2l0.1,2v9.3h-2.2V30.3z"/>'
          '<path class="st3" d="M465.3,30.8c1.3,0.1,2.4,0.3,3.5,0.8c1,0.5,1.9,1.1,2.7,1.9c0.7,0.8,1.3,1.8,1.7,'
          "2.9c0.4,1.1,0.6,2.4,0.6,3.9c0,1.4-0.2,2.7-0.6,3.9c-0.4,1.1-1,2.1-1.7,2.9c-0.7,0.8-1.6,1.4-2.7,1.9c-1,0.5-2.2,"
          "0.7-3.5,0.8V30.8z M467.5,47.3c0.5-0.2,1-0.4,1.5-0.7c0.5-0.3,0.9-0.8,1.3-1.4c0.4-0.6,0.7-1.2,0.9-2c0.2-0.8,0.4-1.8,"
          '0.4-2.8c0-1.1-0.1-2-0.4-2.8c-0.2-0.8-0.5-1.5-0.9-2c-0.4-0.6-0.8-1-1.3-1.4c-0.5-0.3-1-0.6-1.5-0.7V47.3z"/>'
          '<path class="st3" d="M484.4,31h2.2v18.6h-2.2V31z"/>'
          '<path class="st3" d="M498,46.8c0.4,0.2,0.8,0.4,1.2,0.6c0.4,0.2,0.9,0.3,1.4,0.3c0.3,0,0.6,0,0.9-0.1s0.5-0.2,0.7-0.4'
          "c0.2-0.2,0.4-0.4,0.5-0.7c0.1-0.3,0.2-0.6,0.2-1c0-0.3,0-0.5-0.1-0.8c-0.1-0.3-0.2-0.6-0.3-0.9c-0.2-0.3-0.3-0.7-0.6-1"
          "c-0.2-0.4-0.5-0.8-0.9-1.2l-1.5-1.9c-0.4-0.5-0.7-0.9-1-1.4c-0.3-0.4-0.5-0.8-0.6-1.2c-0.2-0.4-0.3-0.8-0.4-1.1"
          "c-0.1-0.4-0.1-0.7-0.1-1.1c0-0.6,0.1-1.1,0.3-1.6c0.2-0.5,0.5-0.9,0.8-1.3c0.4-0.4,0.8-0.6,1.3-0.8c0.5-0.2,1.1-0.3,1.7-0.3"
          "c0.5,0,1,0.1,1.6,0.2c0.5,0.1,1,0.4,1.5,0.6l-0.9,1.8c-0.3-0.2-0.6-0.3-0.9-0.4c-0.3-0.1-0.7-0.2-1-0.2c-0.6,0-1.1,0.2-1.5,0.5"
          "c-0.4,0.4-0.6,0.9-0.6,1.5c0,0.2,0,0.4,0.1,0.6c0,0.2,0.1,0.4,0.2,0.6c0.1,0.2,0.2,0.5,0.4,0.7c0.2,0.3,0.4,0.6,0.6,0.9l2.2,2.9"
          "c0.3,0.4,0.5,0.7,0.8,1.1c0.2,0.4,0.5,0.7,0.6,1.1c0.2,0.4,0.3,0.8,0.4,1.2c0.1,0.4,0.2,0.8,0.2,1.3c0,0.7-0.1,1.3-0.3,1.9"
          "c-0.2,0.6-0.5,1-0.9,1.4c-0.4,0.4-0.9,0.7-1.4,0.9c-0.6,0.2-1.2,0.3-1.8,0.3c-0.7,0-1.3-0.1-2-0.3c-0.6-0.2-1.2-0.5-1.6-0.8"
          'L498,46.8z"/>'
        )
      );
  }

  function generatePositionMetadata(
    uint128 tokenId,
    bytes32 poolHash,
    string memory symbol,
    uint128 rate,
    uint128 normalizedDepositedAmount,
    uint128 bondsQuantity
  ) internal view returns (string memory) {
    return
      string(
        abi.encodePacked(
          generatePositionId(tokenId),
          generatePoolName(poolHash),
          generatePoolRate(rate),
          generatePoolAmounts(symbol, normalizedDepositedAmount, bondsQuantity)
        )
      );
  }

  function generatePositionId(uint128 tokenId) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<linearGradient id="17" gradientUnits="userSpaceOnUse" x1="38.7172" y1="2.7463" x2="102.529" y2="66.5581">'
          '<stop  offset="0.2165" style="stop-color:#FAB2DE"/><stop  offset="1" style="stop-color:#00FFFF"/></linearGradient>'
          '<path style="fill:url(#17);" d="M121.2,54.1H28.8c-0.9,0-1.7-0.7-1.7-1.7V25.5c0-0.9,'
          '0.7-1.7,1.7-1.7h92.4c0.9,0,1.7,0.7,1.7,1.7v26.9C122.8,53.4,122.1,54.1,121.2,54.1z"/>'
          '<text transform="matrix(1 0 0 1 41.9943 43.7106)" class="st5">ID: ',
          uint2str(tokenId),
          "</text>"
        )
      );
  }

  function generatePoolName(bytes32 poolHash) internal view returns (string memory) {
    string memory poolIdentifier = _poolIdentifiers[poolHash];
    return
      string(
        abi.encodePacked(
          '<path class="st1" d="M29.2,642.7h356.7c1.1,0,2.1,1.3,2.1,2.8v24.7c0,1.5-1,2.8-2.1,'
          '2.8H29.2c-1.1,0-2.1-1.3-2.1-2.8v-24.7C27.1,643.9,28,642.7,29.2,642.7z"/>'
          '<text transform="matrix(1 0 0 1 37.5065 663.5427)" class="st3 st5">Pool: ',
          poolIdentifier,
          "</text>"
        )
      );
  }

  function generatePoolRate(uint128 rate) internal pure returns (string memory) {
    uint128 firstSignificantNumberPrecision = 1e16;
    uint128 secondSignificantNumberPrecision = 1e14;
    return
      string(
        abi.encodePacked(
          '<path class="st1" d="M398.1,642.8h104.5c1.1,0,1.9,0.9,1.9,1.9v26.4c0,1.1-0.9,1.9-1.9,'
          '1.9H398.1c-1.1,0-1.9-0.9-1.9-1.9v-26.4C396.2,643.7,397.1,642.8,398.1,642.8z"/>'
          '<text transform="matrix(1 0 0 1 420.3261 662.4679)" class="st3 st5">I.R. ',
          uint2str(rate / firstSignificantNumberPrecision),
          ".",
          uint2str((rate % firstSignificantNumberPrecision) / secondSignificantNumberPrecision),
          "%</text>"
        )
      );
  }

  function generatePoolAmounts(
    string memory symbol,
    uint128 normalizedDepositedAmount,
    uint128 bondsQuantity
  ) internal pure returns (string memory) {
    uint128 firstSignificantNumberPrecision = 1e18;
    uint128 secondSignificantNumberPrecision = 1e16;
    return
      string(
        abi.encodePacked(
          '<path class="st1" d="M259.8,711.6H29.9c-1.3,0-2.3-1.6-2.3-3.5v-23.2c0-2,1-3.5,'
          '2.3-3.5h229.9c1.3,0,2.3,1.6,2.3,3.5v23.2C262.1,710,261,711.6,259.8,711.6z"/>'
          '<text transform="matrix(1 0 0 1 38.0304 702.1925)" class="st3 st5">',
          uint2str(normalizedDepositedAmount / firstSignificantNumberPrecision),
          ".",
          uint2str((normalizedDepositedAmount % firstSignificantNumberPrecision) / secondSignificantNumberPrecision),
          symbol,
          ' Deposited </text><path class="st1" d="M501.8,711.6H271.2c-1.3,0-2.3-1.6-2.3-3.5v-23.2c0-2,'
          '1-3.5,2.3-3.5h230.7c1.3,0,2.3,1.6,2.3,3.5v23.2C504.1,710,503.1,711.6,501.8,711.6z"/>'
          '<text transform="matrix(1 0 0 1 278.8931 702.1919)" class="st3 st5">',
          uint2str(bondsQuantity / firstSignificantNumberPrecision),
          ".",
          uint2str((bondsQuantity % firstSignificantNumberPrecision) / secondSignificantNumberPrecision),
          symbol,
          " Borrowed </text>"
        )
      );
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Partial interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20PartialDecimals {
  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../extensions/AaveILendingPool.sol";
import "../lib/Types.sol";

/**
 * @title IBorrowerPools
 * @notice Used by the Position contract to pool lender positions in the borrowers order books
 *         Used by the borrowers to manage their loans on their pools
 **/
interface IBorrowerPools {
  // EVENTS

  /**
   * @notice Emitted after a successful borrow
   * @param poolHash The identifier of the pool
   * @param normalizedBorrowedAmount The actual amount of tokens borrowed
   * @param establishmentFees Fees paid to the protocol at borrow time
   **/
  event Borrow(bytes32 indexed poolHash, uint128 normalizedBorrowedAmount, uint128 establishmentFees);

  /**
   * @notice Emitted after a successful further borrow
   * @param poolHash The identifier of the pool
   * @param normalizedBorrowedAmount The actual amount of tokens borrowed
   * @param establishmentFees Fees paid to the protocol at borrow time
   **/
  event FurtherBorrow(bytes32 indexed poolHash, uint128 normalizedBorrowedAmount, uint128 establishmentFees);

  /**
   * @notice Emitted after a successful repay
   * @param poolHash The identifier of the pool
   * @param normalizedRepayAmount The actual amount of tokens repaid
   * @param repaymentFee The amount of fee paid to the protocol at repay time
   * @param normalizedDepositsAfterRepay The actual amount of tokens deposited and available for next loan after repay
   * @param nextLoanMinStart The timestamp after which a new loan can be taken
   **/
  event Repay(
    bytes32 indexed poolHash,
    uint128 normalizedRepayAmount,
    uint128 repaymentFee,
    uint128 normalizedDepositsAfterRepay,
    uint128 nextLoanMinStart
  );

  /**
   * @notice Emitted after a successful early repay
   * @param poolHash The identifier of the pool
   * @param normalizedRepayAmount The actual amount of tokens repaid
   * @param repaymentFee The amount of fee paid to the protocol at repay time
   * @param normalizedDepositsAfterRepay The actual amount of tokens deposited and available for next loan after repay
   * @param nextLoanMinStart The timestamp after which a new loan can be taken
   **/
  event EarlyRepay(
    bytes32 indexed poolHash,
    uint128 normalizedRepayAmount,
    uint128 repaymentFee,
    uint128 normalizedDepositsAfterRepay,
    uint128 nextLoanMinStart
  );

  /**
   * @notice Emitted after a successful repay, made after the repayment period
   * Includes a late repay fee
   * @param poolHash The identifier of the pool
   * @param normalizedRepayAmount The actual amount of tokens repaid
   * @param lateRepayFee The amount of fee paid due to a late repayment
   * @param repaymentFee The amount of fee paid to the protocol at repay time
   * @param normalizedDepositsAfterRepay The actual amount of tokens deposited and available for next loan after repay
   * @param nextLoanMinStart The timestamp after which a new loan can be taken
   **/
  event LateRepay(
    bytes32 indexed poolHash,
    uint128 normalizedRepayAmount,
    uint128 lateRepayFee,
    uint128 repaymentFee,
    uint128 normalizedDepositsAfterRepay,
    uint128 nextLoanMinStart
  );

  /**
   * @notice Emitted after a borrower successfully deposits tokens in its pool liquidity rewards reserve
   * @param poolHash The identifier of the pool
   * @param normalizedAmount The actual amount of tokens deposited into the reserve
   **/
  event TopUpLiquidityRewards(bytes32 poolHash, uint128 normalizedAmount);

  // The below events and enums are being used in the PoolLogic library
  // The same way that libraries don't have storage, they don't have an event log
  // Hence event logs will be saved in the calling contract
  // For the contract abi to reflect this and be used by offchain libraries,
  // we define these events and enums in the contract itself as well

  /**
   * @notice Emitted when a tick is initialized, i.e. when its first deposited in
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param atlendisLiquidityRatio The tick current liquidity index
   **/
  event TickInitialized(bytes32 poolHash, uint128 rate, uint128 atlendisLiquidityRatio);

  /**
   * @notice Emitted after a deposit on a tick that was done during a loan
   * @param poolHash The identifier of the pool
   * @param rate The position bidding rate
   * @param adjustedPendingDeposit The amount of tokens deposited during a loan, adjusted to the current liquidity index
   **/
  event TickLoanDeposit(bytes32 poolHash, uint128 rate, uint128 adjustedPendingDeposit);

  /**
   * @notice Emitted after a deposit on a tick that was done without an active loan
   * @param poolHash The identifier of the pool
   * @param rate The position bidding rate
   * @param adjustedAvailableDeposit The amount of tokens available to the borrower for its next loan
   * @param atlendisLiquidityRatio The tick current liquidity index
   **/
  event TickNoLoanDeposit(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAvailableDeposit,
    uint128 atlendisLiquidityRatio
  );

  /**
   * @notice Emitted when a borrow successfully impacts a tick
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param adjustedRemainingAmountReduction The amount of tokens left to borrow from other ticks
   * @param loanedAmount The amount borrowed from the tick
   * @param atlendisLiquidityRatio The tick current liquidity index
   * @param unborrowedRatio Proportion of ticks funds that were not borrowed
   **/
  event TickBorrow(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedRemainingAmountReduction,
    uint128 loanedAmount,
    uint128 atlendisLiquidityRatio,
    uint128 unborrowedRatio
  );

  /**
   * @notice Emitted when a withdraw is done outside of a loan on the tick
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param adjustedAmountToWithdraw The amount of tokens to withdraw, adjusted to the tick liquidity index
   **/
  event TickWithdrawPending(bytes32 poolHash, uint128 rate, uint128 adjustedAmountToWithdraw);

  /**
   * @notice Emitted when a withdraw is done during a loan on the tick
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param adjustedAmountToWithdraw The amount of tokens to withdraw, adjusted to the tick liquidity index
   * @param atlendisLiquidityRatio The tick current liquidity index
   * @param accruedFeesToWithdraw The amount of fees the position has a right to claim
   **/
  event TickWithdrawRemaining(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmountToWithdraw,
    uint128 atlendisLiquidityRatio,
    uint128 accruedFeesToWithdraw
  );

  /**
   * @notice Emitted when pending amounts are merged with the rest of the pool during a repay
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param adjustedPendingAmount The amount of pending funds deposited with available funds
   **/
  event TickPendingDeposit(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedPendingAmount,
    bool poolBondIssuanceIndexIncremented
  );

  /**
   * @notice Emitted when funds from a tick are repaid by the borrower
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param adjustedRemainingAmount The total amount of tokens available to the borrower for
   * its next loan, adjusted to the tick current liquidity index
   * @param atlendisLiquidityRatio The tick current liquidity index
   **/
  event TickRepay(bytes32 poolHash, uint128 rate, uint128 adjustedRemainingAmount, uint128 atlendisLiquidityRatio);

  /**
   * @notice Emitted when liquidity rewards are distributed to a tick
   * @param poolHash The identifier of the pool
   * @param rate The tick's bidding rate
   * @param remainingLiquidityRewards the amount of liquidityRewards added to the tick
   * @param addedAccruedFees Increase in accrued fees for that tick
   **/
  event CollectFeesForTick(bytes32 poolHash, uint128 rate, uint128 remainingLiquidityRewards, uint128 addedAccruedFees);

  // VIEW METHODS

  /**
   * @notice Returns the liquidity ratio of a given tick in a pool's order book.
   * The liquidity ratio is an accounting construct to deduce the accrued interest over time.
   * @param poolHash The identifier of the pool
   * @param rate The tick rate from which to extract the liquidity ratio
   * @return liquidityRatio The liquidity ratio of the given tick
   **/
  function getTickLiquidityRatio(bytes32 poolHash, uint128 rate) external view returns (uint128 liquidityRatio);

  /**
   * @notice Returns the repartition between bonds and deposits of the given tick.
   * @param poolHash The identifier of the pool
   * @param rate The tick rate from which to get data
   * @return adjustedTotalAmount Total amount of deposit in the tick
   * @return adjustedRemainingAmount Amount of tokens in tick deposited with the
   * underlying yield provider that were deposited before bond issuance
   * @return bondsQuantity The quantity of bonds within the tick
   * @return adjustedPendingAmount Amount of deposit in tick deposited with the
   * underlying yield provider that were deposited after bond issuance
   * @return atlendisLiquidityRatio The liquidity ratio of the given tick
   * @return accruedFees The total fees claimable in the current tick, either from
   * yield provider interests or liquidity rewards accrual
   **/
  function getTickAmounts(bytes32 poolHash, uint128 rate)
    external
    view
    returns (
      uint128 adjustedTotalAmount,
      uint128 adjustedRemainingAmount,
      uint128 bondsQuantity,
      uint128 adjustedPendingAmount,
      uint128 atlendisLiquidityRatio,
      uint128 accruedFees
    );

  /**
   * @notice Returns the timestamp of the last fee distribution to the tick
   * @param poolHash The identifier of the pool
   * @param rate The tick rate from which to get data
   * @return lastFeeDistributionTimestamp Timestamp of the last fee's distribution to the tick
   **/
  function getTickLastUpdate(string calldata poolHash, uint128 rate)
    external
    view
    returns (uint128 lastFeeDistributionTimestamp);

  /**
   * @notice Returns the current state of the pool's parameters
   * @param poolHash The identifier of the pool
   * @return weightedAverageLendingRate The average deposit bidding rate in the order book
   * @return adjustedPendingDeposits Amount of tokens deposited after bond
   * issuance and currently on third party yield provider
   **/
  function getPoolAggregates(bytes32 poolHash)
    external
    view
    returns (uint128 weightedAverageLendingRate, uint128 adjustedPendingDeposits);

  /**
   * @notice Returns the current maturity of the pool
   * @param poolHash The identifier of the pool
   * @return poolCurrentMaturity The pool's current maturity
   **/
  function getPoolMaturity(bytes32 poolHash) external view returns (uint128 poolCurrentMaturity);

  /**
   * @notice Estimates the lending rate corresponding to the input amount,
   * depending on the current state of the pool
   * @param normalizedBorrowedAmount The amount to be borrowed from the pool
   * @param poolHash The identifier of the pool
   * @return estimatedRate The estimated loan rate for the current state of the pool
   **/
  function estimateLoanRate(uint128 normalizedBorrowedAmount, bytes32 poolHash)
    external
    view
    returns (uint128 estimatedRate);

  /**
   * @notice Returns the token amount's repartition between bond quantity and normalized
   * deposited amount currently placed on third party yield provider
   * @param poolHash The identifier of the pool
   * @param rate Tick's rate
   * @param adjustedAmount Adjusted amount of tokens currently on third party yield provider
   * @param bondsIssuanceIndex The identifier of the borrow group
   * @return bondsQuantity Quantity of bonds held
   * @return normalizedDepositedAmount Amount of deposit currently on third party yield provider
   **/
  function getAmountRepartition(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmount,
    uint128 bondsIssuanceIndex
  ) external view returns (uint128 bondsQuantity, uint128 normalizedDepositedAmount);

  /**
   * @notice Returns the total amount a borrower has to repay to a pool. Includes borrowed
   * amount, late repay fees and protocol fees
   * @param poolHash The identifier of the pool
   * @param earlyRepay indicates if this is an early repay
   * @return normalizedRepayAmount Total repay amount
   * @return lateRepayFee Normalized amount to be paid to each bond in case of late repayment
   * @return repaymentFee Normalized fee amount paid to the protocol
   **/
  function getRepayAmounts(bytes32 poolHash, bool earlyRepay)
    external
    view
    returns (
      uint128 normalizedRepayAmount,
      uint128 lateRepayFee,
      uint128 repaymentFee
    );

  // LENDER METHODS

  /**
   * @notice Gets called within the Position.deposit() function and enables a lender to deposit assets
   * into a given borrower's order book. The lender specifies a rate (price) at which it is willing to
   * lend out its assets (bid on the zero coupon bond). The full amount will initially be deposited
   * on the underlying yield provider until the borrower sells bonds at the specified rate.
   * @param normalizedAmount The amount of the given asset to deposit
   * @param rate The rate at which to bid for a bond
   * @param poolHash The identifier of the pool
   * @param underlyingToken Contract' address of the token to be deposited
   * @param sender The lender address who calls the deposit function on the Position
   * @return adjustedAmount Deposited amount adjusted with current liquidity index
   * @return bondsIssuanceIndex The identifier of the borrow group to which the deposit has been allocated
   **/
  function deposit(
    uint128 rate,
    bytes32 poolHash,
    address underlyingToken,
    address sender,
    uint128 normalizedAmount
  ) external returns (uint128 adjustedAmount, uint128 bondsIssuanceIndex);

  /**
   * @notice Gets called within the Position.withdraw() function and enables a lender to
   * evaluate the exact amount of tokens it is allowed to withdraw
   * @dev This method is meant to be used exclusively with the withdraw() method
   * Under certain circumstances, this method can return incorrect values, that would otherwise
   * be rejected by the checks made in the withdraw() method
   * @param poolHash The identifier of the pool
   * @param rate The rate the position is bidding for
   * @param adjustedAmount The amount of tokens in the position, adjusted to the deposit liquidity ratio
   * @param bondsIssuanceIndex An index determining deposit timing
   * @return adjustedAmountToWithdraw The amount of tokens to withdraw, adjuste for borrow pool use
   * @return depositedAmountToWithdraw The amount of tokens to withdraw, adjuste for position use
   * @return remainingBondsQuantity The quantity of bonds remaining within the position
   * @return bondsMaturity The maturity of bonds remaining within the position after withdraw
   **/
  function getWithdrawAmounts(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmount,
    uint128 bondsIssuanceIndex
  )
    external
    view
    returns (
      uint128 adjustedAmountToWithdraw,
      uint128 depositedAmountToWithdraw,
      uint128 remainingBondsQuantity,
      uint128 bondsMaturity
    );

  /**
   * @notice Gets called within the Position.withdraw() function and enables a lender to
   * withdraw assets that are deposited with the underlying yield provider
   * @param poolHash The identifier of the pool
   * @param rate The rate the position is bidding for
   * @param adjustedAmountToWithdraw The actual amount of tokens to withdraw from the position
   * @param bondsIssuanceIndex An index determining deposit timing
   * @param owner The address to which the withdrawns funds are sent
   * @return normalizedDepositedAmountToWithdraw Actual amount of tokens withdrawn and sent to the lender
   **/
  function withdraw(
    bytes32 poolHash,
    uint128 rate,
    uint128 adjustedAmountToWithdraw,
    uint128 bondsIssuanceIndex,
    address owner
  ) external returns (uint128 normalizedDepositedAmountToWithdraw);

  /**
   * @notice Gets called within Position.updateRate() and updates the order book ticks affected by the position
   * updating its rate. This is only possible as long as there are no bonds in the position, i.e the full
   * position currently lies with the yield provider
   * @param adjustedAmount The adjusted balance of tokens of the given position
   * @param poolHash The identifier of the pool
   * @param oldRate The current rate of the position
   * @param newRate The new rate of the position
   * @param oldBondsIssuanceIndex The identifier of the borrow group from the given position
   * @return newAdjustedAmount The updated amount of tokens of the position adjusted by the
   * new tick's global liquidity ratio
   * @return newBondsIssuanceIndex The new borrow group id to which the updated position is linked
   **/
  function updateRate(
    uint128 adjustedAmount,
    bytes32 poolHash,
    uint128 oldRate,
    uint128 newRate,
    uint128 oldBondsIssuanceIndex
  )
    external
    returns (
      uint128 newAdjustedAmount,
      uint128 newBondsIssuanceIndex,
      uint128 normalizedAmount
    );

  // BORROWER METHODS

  /**
   * @notice Called by the borrower to sell bonds to the order book.
   * The affected ticks get updated according the amount of bonds sold.
   * @param to The address to which the borrowed funds should be sent.
   * @param loanAmount The total amount of the loan
   **/
  function borrow(address to, uint128 loanAmount) external;

  /**
   * @notice Repays a currently outstanding bonds of the given borrower.
   **/
  function repay() external;

  /**
   * @notice Called by the borrower to top up liquidity rewards' reserve that
   * is distributed to liquidity providers at the pre-defined distribution rate.
   * @param normalizedAmount Amount of tokens  that will be add up to the borrower's liquidity rewards reserve
   **/
  function topUpLiquidityRewards(uint128 normalizedAmount) external;

  // FEE COLLECTION

  /**
   * @notice Collect yield provider fees as well as liquidity rewards for the target tick
   * @param poolHash The identifier of the pool
   **/
  function collectFeesForTick(bytes32 poolHash, uint128 rate) external;

  /**
   * @notice Collect yield provider fees as well as liquidity rewards for the whole pool
   * Iterates over all pool initialized ticks
   * @param poolHash The identifier of the pool
   **/
  function collectFees(bytes32 poolHash) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../lib/Types.sol";

/**
 * @title IPoolsController
 * @notice Management of the pools
 **/
interface IPoolsController {
  // EVENTS

  /**
   * @notice Emitted after a pool was creted
   **/
  event PoolCreated(PoolCreationParams params);

  /**
   * @notice Emitted after a borrower address was allowed to borrow from a pool
   * @param borrowerAddress The address to allow
   * @param poolHash The identifier of the pool
   **/
  event BorrowerAllowed(address borrowerAddress, bytes32 poolHash);

  /**
   * @notice Emitted after a borrower address was disallowed to borrow from a pool
   * @param borrowerAddress The address to disallow
   * @param poolHash The identifier of the pool
   **/
  event BorrowerDisallowed(address borrowerAddress, bytes32 poolHash);

  /**
   * @notice Emitted when a pool is active, i.e. after the borrower deposits enough tokens
   * in its pool liquidity rewards reserve as agreed before the pool creation
   * @param poolHash The identifier of the pool
   **/
  event PoolActivated(bytes32 poolHash);

  /**
   * @notice Emitted after pool is closed
   * @param poolHash The identifier of the pool
   * @param collectedLiquidityRewards The amount of liquidity rewards to have been collected at closing time
   **/
  event PoolClosed(bytes32 poolHash, uint128 collectedLiquidityRewards);

  /**
   * @notice Emitted when a pool defaults on its loan repayment
   * @param poolHash The identifier of the pool
   * @param distributedLiquidityRewards The remaining liquidity rewards distributed to
   * bond holders
   **/
  event Default(bytes32 poolHash, uint128 distributedLiquidityRewards);

  /**
   * @notice Emitted after governance sets the maximum borrowable amount for a pool
   **/
  event SetMaxBorrowableAmount(uint128 maxTokenDeposit, bytes32 poolHash);

  /**
   * @notice Emitted after governance sets the liquidity rewards distribution rate for a pool
   **/
  event SetLiquidityRewardsDistributionRate(uint128 distributionRate, bytes32 poolHash);

  /**
   * @notice Emitted after governance sets the establishment fee for a pool
   **/
  event SetEstablishmentFeeRate(uint128 establishmentRate, bytes32 poolHash);

  /**
   * @notice Emitted after governance sets the repayment fee for a pool
   **/
  event SetRepaymentFeeRate(uint128 repaymentFeeRate, bytes32 poolHash);

  /**
   * @notice Set the pool early repay option
   **/
  event SetEarlyRepay(bool earlyRepay, bytes32 poolHash);

  /**
   * @notice Emitted after governance claims the fees associated with a pool
   * @param poolHash The identifier of the pool
   * @param normalizedAmount The amount of tokens claimed
   * @param to The address receiving the fees
   **/
  event ClaimProtocolFees(bytes32 poolHash, uint128 normalizedAmount, address to);

  // VIEW METHODS

  /**
   * @notice Returns the parameters of a pool
   * @param poolHash The identifier of the pool
   * @return underlyingToken Address of the underlying token of the pool
   * @return minRate Minimum rate of deposits accepted in the pool
   * @return maxRate Maximum rate of deposits accepted in the pool
   * @return rateSpacing Difference between two rates in the pool
   * @return maxBorrowableAmount Maximum amount of tokens that can be borrowed from the pool
   * @return loanDuration Duration of a loan in the pool
   * @return liquidityRewardsDistributionRate Rate at which liquidity rewards are distributed to lenders
   * @return cooldownPeriod Period after a loan during which a borrower cannot take another loan
   * @return repaymentPeriod Period after a loan end during which a borrower can repay without penalty
   * @return lateRepayFeePerBondRate Penalty a borrower has to pay when it repays late
   * @return liquidityRewardsActivationThreshold Minimum amount of liqudity rewards a borrower has to
   * deposit to active the pool
   **/
  function getPoolParameters(bytes32 poolHash)
    external
    view
    returns (
      address underlyingToken,
      uint128 minRate,
      uint128 maxRate,
      uint128 rateSpacing,
      uint128 maxBorrowableAmount,
      uint128 loanDuration,
      uint128 liquidityRewardsDistributionRate,
      uint128 cooldownPeriod,
      uint128 repaymentPeriod,
      uint128 lateRepayFeePerBondRate,
      uint128 liquidityRewardsActivationThreshold
    );

  /**
   * @notice Returns the fee rates of a pool
   * @return establishmentFeeRate Amount of fees paid to the protocol at borrow time
   * @return repaymentFeeRate Amount of fees paid to the protocol at repay time
   **/
  function getPoolFeeRates(bytes32 poolHash)
    external
    view
    returns (uint128 establishmentFeeRate, uint128 repaymentFeeRate);

  /**
   * @notice Returns the state of a pool
   * @param poolHash The identifier of the pool
   * @return active Signals if a pool is active and ready to accept deposits
   * @return defaulted Signals if a pool was defaulted
   * @return closed Signals if a pool was closed
   * @return currentMaturity End timestamp of current loan
   * @return bondsIssuedQuantity Amount of bonds issued, to be repaid at maturity
   * @return normalizedBorrowedAmount Actual amount of tokens that were borrowed
   * @return normalizedAvailableDeposits Actual amount of tokens available to be borrowed
   * @return lowerInterestRate Minimum rate at which a deposit was made
   * @return nextLoanMinStart Cool down period, minimum timestamp after which a new loan can be taken
   * @return remainingAdjustedLiquidityRewardsReserve Remaining liquidity rewards to be distributed to lenders
   * @return yieldProviderLiquidityRatio Last recorded yield provider liquidity ratio
   * @return currentBondsIssuanceIndex Current borrow period identifier of the pool
   **/
  function getPoolState(bytes32 poolHash)
    external
    view
    returns (
      bool active,
      bool defaulted,
      bool closed,
      uint128 currentMaturity,
      uint128 bondsIssuedQuantity,
      uint128 normalizedBorrowedAmount,
      uint128 normalizedAvailableDeposits,
      uint128 lowerInterestRate,
      uint128 nextLoanMinStart,
      uint128 remainingAdjustedLiquidityRewardsReserve,
      uint128 yieldProviderLiquidityRatio,
      uint128 currentBondsIssuanceIndex
    );

  /**
   * @notice Signals whether the early repay feature is activated or not
   * @return earlyRepay Flag that signifies whether the early repay feature is activated or not
   **/
  function isEarlyRepay(bytes32 poolHash) external view returns (bool earlyRepay);

  /**
   * @notice Returns the state of a pool
   * @return defaultTimestamp The timestamp at which the pool was defaulted
   **/
  function getDefaultTimestamp(bytes32 poolHash) external view returns (uint128 defaultTimestamp);

  // GOVERNANCE METHODS

  /**
   * @notice Parameters used for a pool creation
   * @param poolHash The identifier of the pool
   * @param underlyingToken Address of the pool underlying token
   * @param yieldProvider Yield provider of the pool
   * @param minRate Minimum bidding rate for the pool
   * @param maxRate Maximum bidding rate for the pool
   * @param rateSpacing Difference between two tick rates in the pool
   * @param maxBorrowableAmount Maximum amount of tokens a borrower can get from a pool
   * @param loanDuration Duration of a loan i.e. maturity of the issued bonds
   * @param distributionRate Rate at which the liquidity rewards are distributed to unmatched positions
   * @param cooldownPeriod Period of time after a repay during which the borrow cannot take a loan
   * @param repaymentPeriod Period after the end of a loan during which the borrower can repay without penalty
   * @param lateRepayFeePerBondRate Additional fees applied when a borrower repays its loan after the repayment period ends
   * @param establishmentFeeRate Fees paid to Atlendis at borrow time
   * @param repaymentFeeRate Fees paid to Atlendis at repay time
   * @param liquidityRewardsActivationThreshold Amount of tokens the borrower has to lock into the liquidity
   * @param earlyRepay Is early repay activated
   * rewards reserve to activate the pool
   **/
  struct PoolCreationParams {
    bytes32 poolHash;
    address underlyingToken;
    ILendingPool yieldProvider;
    uint128 minRate;
    uint128 maxRate;
    uint128 rateSpacing;
    uint128 maxBorrowableAmount;
    uint128 loanDuration;
    uint128 distributionRate;
    uint128 cooldownPeriod;
    uint128 repaymentPeriod;
    uint128 lateRepayFeePerBondRate;
    uint128 establishmentFeeRate;
    uint128 repaymentFeeRate;
    uint128 liquidityRewardsActivationThreshold;
    bool earlyRepay;
  }

  /**
   * @notice Creates a new pool
   * @param params A struct defining the pool creation parameters
   **/
  function createNewPool(PoolCreationParams calldata params) external;

  /**
   * @notice Allow an address to interact with a borrower pool
   * @param borrowerAddress The address to allow
   * @param poolHash The identifier of the pool
   **/
  function allow(address borrowerAddress, bytes32 poolHash) external;

  /**
   * @notice Remove pool interaction rights from an address
   * @param borrowerAddress The address to disallow
   * @param poolHash The identifier of the borrower pool
   **/
  function disallow(address borrowerAddress, bytes32 poolHash) external;

  /**
   * @notice Flags the pool as closed
   * @param poolHash The identifier of the pool to be closed
   * @param to An address to which the remaining liquidity rewards will be sent
   **/
  function closePool(bytes32 poolHash, address to) external;

  /**
   * @notice Flags the pool as defaulted
   * @param poolHash The identifier of the pool to default
   **/
  function setDefault(bytes32 poolHash) external;

  /**
   * @notice Set the maximum amount of tokens that can be borrowed in the target pool
   **/
  function setMaxBorrowableAmount(uint128 maxTokenDeposit, bytes32 poolHash) external;

  /**
   * @notice Set the pool liquidity rewards distribution rate
   **/
  function setLiquidityRewardsDistributionRate(uint128 distributionRate, bytes32 poolHash) external;

  /**
   * @notice Set the pool establishment protocol fee rate
   **/
  function setEstablishmentFeeRate(uint128 establishmentFeeRate, bytes32 poolHash) external;

  /**
   * @notice Set the pool repayment protocol fee rate
   **/
  function setRepaymentFeeRate(uint128 repaymentFeeRate, bytes32 poolHash) external;

  /**
   * @notice Set the pool early repay option
   **/
  function setEarlyRepay(bool earlyRepay, bytes32 poolHash) external;

  /**
   * @notice Withdraws protocol fees to a target address
   * @param poolHash The identifier of the pool
   * @param normalizedAmount The amount of tokens claimed
   * @param to The address receiving the fees
   **/
  function claimProtocolFees(
    bytes32 poolHash,
    uint128 normalizedAmount,
    address to
  ) external;

  /**
   * @notice Stops all actions on all pools
   **/
  function freezePool() external;

  /**
   * @notice Cancel a freeze, makes actions available again on all pools
   **/
  function unfreezePool() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IPositionManager.sol";

/**
 * @title IPositionDescriptor
 * @notice Generates the SVG artwork for lenders positions
 **/
interface IPositionDescriptor {
  /**
   * @notice Emitted after the string identifier of a pool has been set
   * @param poolIdentifier The string identifier of the pool
   * @param poolHash The hash identifier of the pool
   **/
  event SetPoolIdentifier(string poolIdentifier, bytes32 poolHash);

  /**
   * @notice Get the pool hash corresponding to the input pool identifier
   * @param poolIdentifier The identifier of the pool
   **/
  function getPoolHash(string calldata poolIdentifier) external view returns (bytes32);

  /**
   * @notice Get the pool identifier corresponding to the input pool hash
   * @param poolHash The identifier of the pool
   **/
  function getPoolIdentifier(bytes32 poolHash) external view returns (string memory);

  /**
   * @notice Set the pool string identifier corresponding to the input pool hash
   * @param poolIdentifier The string identifier to associate with the corresponding pool hash
   * @param poolHash The identifier of the pool
   **/
  function setPoolIdentifier(string calldata poolIdentifier, bytes32 poolHash) external;

  /**
   * @notice Returns the encoded svg for positions artwork
   * @param position The address of the position manager contract
   * @param tokenId The tokenId of the position
   **/
  function tokenURI(IPositionManager position, uint128 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IBorrowerPools.sol";

/**
 * @title IPositionManager
 * @notice Contains methods that can be called by lenders to create and manage their position
 **/
interface IPositionManager {
  /**
   * @notice Emitted when #deposit is called and is a success
   * @param lender The address of the lender depositing token on the protocol
   * @param tokenId The tokenId of the position
   * @param amount The amount of deposited token
   * @param rate The position bidding rate
   * @param poolHash The identifier of the pool
   * @param bondsIssuanceIndex The borrow period assigned to the position
   **/
  event Deposit(
    address indexed lender,
    uint128 tokenId,
    uint128 amount,
    uint128 rate,
    bytes32 poolHash,
    uint128 bondsIssuanceIndex
  );

  /**
   * @notice Emitted when #updateRate is called and is a success
   * @param lender The address of the lender updating their position
   * @param tokenId The tokenId of the position
   * @param amount The amount of deposited token plus their accrued interests
   * @param rate The new rate required by lender to lend their deposited token
   * @param poolHash The identifier of the pool
   **/
  event UpdateRate(address indexed lender, uint128 tokenId, uint128 amount, uint128 rate, bytes32 poolHash);

  /**
   * @notice Emitted when #withdraw is called and is a success
   * @param lender The address of the withdrawing lender
   * @param tokenId The tokenId of the position
   * @param amount The amount of tokens withdrawn
   * @param rate The position bidding rate
   * @param poolHash The identifier of the pool
   **/
  event Withdraw(
    address indexed lender,
    uint128 tokenId,
    uint128 amount,
    uint128 remainingBonds,
    uint128 rate,
    bytes32 poolHash
  );

  /**
   * @notice Set the position descriptor address
   * @param positionDescriptor The address of the new position descriptor
   **/
  event SetPositionDescriptor(address positionDescriptor);

  /**
   * @notice Emitted when #withdraw is called and is a success
   * @param tokenId The tokenId of the position
   * @return poolHash The identifier of the pool
   * @return adjustedBalance Adjusted balance of the position original deposit
   * @return rate Position bidding rate
   * @return underlyingToken Address of the tokens the position contains
   * @return remainingBonds Quantity of bonds remaining in the position after a partial withdraw
   * @return bondsMaturity Maturity of the position's remaining bonds
   * @return bondsIssuanceIndex Borrow period the deposit was made in
   **/
  function position(uint128 tokenId)
    external
    view
    returns (
      bytes32 poolHash,
      uint128 adjustedBalance,
      uint128 rate,
      address underlyingToken,
      uint128 remainingBonds,
      uint128 bondsMaturity,
      uint128 bondsIssuanceIndex
    );

  /**
   * @notice Returns the balance on yield provider and the quantity of bond held
   * @param tokenId The tokenId of the position
   * @return bondsQuantity Quantity of bond held, represents funds borrowed
   * @return normalizedDepositedAmount Amount of deposit placed on yield provider
   **/
  function getPositionRepartition(uint128 tokenId)
    external
    view
    returns (uint128 bondsQuantity, uint128 normalizedDepositedAmount);

  /**
   * @notice Deposits tokens into the yield provider and places a bid at the indicated rate within the
   * respective borrower's order book. A new position is created within the positions map that keeps
   * track of this position's composition. An ERC721 NFT is minted for the user as a representation
   * of the position.
   * @param to The address for which the position is created
   * @param amount The amount of tokens to be deposited
   * @param rate The rate at which to bid for a bonds
   * @param poolHash The identifier of the pool
   * @param underlyingToken The contract address of the token to be deposited
   **/
  function deposit(
    address to,
    uint128 amount,
    uint128 rate,
    bytes32 poolHash,
    address underlyingToken
  ) external returns (uint128 tokenId);

  /**
   * @notice Allows a user to update the rate at which to bid for bonds. A rate is only
   * upgradable as long as the full amount of deposits are currently allocated with the
   * yield provider i.e the position does not hold any bonds.
   * @param tokenId The tokenId of the position
   * @param newRate The new rate at which to bid for bonds
   **/
  function updateRate(uint128 tokenId, uint128 newRate) external;

  /**
   * @notice Withdraws the amount of tokens that are deposited with the yield provider.
   * The bonds portion of the position is not affected.
   * @param tokenId The tokenId of the position
   **/
  function withdraw(uint128 tokenId) external;

  /**
   * @notice Set the address of the position descriptor.
   * Only accessible to governance.
   * @param positionDescriptor The address of the position descriptor
   **/
  function setPositionDescriptor(address positionDescriptor) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

library Errors {
  // *** Contract Specific Errors ***
  // BorrowerPools
  error BP_BORROW_MAX_BORROWABLE_AMOUNT_EXCEEDED(); // "Amount borrowed is too big, exceeding borrowable capacity";
  error BP_REPAY_NO_ACTIVE_LOAN(); // "No active loan to be repaid, action cannot be performed";
  error BP_BORROW_UNSUFFICIENT_BORROWABLE_AMOUNT_WITHIN_BRACKETS(); // "Amount provided is greater than available amount within min rate and max rate brackets";
  error BP_REPAY_AT_MATURITY_ONLY(); // "Maturity has not been reached yet, action cannot be performed";
  error BP_BORROW_COOLDOWN_PERIOD_NOT_OVER(); // "Cooldown period after a repayment is not over";
  error BP_MULTIPLE_BORROW_AFTER_MATURITY(); // "Cannot borrow again from pool after loan maturity";
  error BP_POOL_NOT_ACTIVE(); // "Pool not active"
  error BP_POOL_DEFAULTED(); // "Pool defaulted"
  error BP_LOAN_ONGOING(); // "There's a loan ongoing, cannot update rate"
  error BP_BORROW_OUT_OF_BOUND_AMOUNT(); // "Amount provided is greater than available amount, action cannot be performed";
  error BP_POOL_CLOSED(); // "Pool closed";
  error BP_OUT_OF_BOUND_MIN_RATE(); // "Rate provided is lower than minimum rate of the pool";
  error BP_OUT_OF_BOUND_MAX_RATE(); // "Rate provided is greater than maximum rate of the pool";
  error BP_UNMATCHED_TOKEN(); // "Token/Asset provided does not match the underlying token of the pool";
  error BP_RATE_SPACING(); // "Decimals of rate provided do not comply with rate spacing of the pool";
  error BP_BOND_ISSUANCE_ID_TOO_HIGH(); // "Bond issuance id is too high";
  error BP_NO_DEPOSIT_TO_WITHDRAW(); // "Deposited amount non-borrowed equals to zero";
  error BP_TARGET_BOND_ISSUANCE_INDEX_EMPTY(); // "Target bond issuance index has no amount to withdraw";
  error BP_EARLY_REPAY_NOT_ACTIVATED(); // "The early repay feature is not activated for this pool";

  // PoolController
  error PC_POOL_NOT_ACTIVE(); // "Pool not active"
  error PC_POOL_DEFAULTED(); // "Pool defaulted"
  error PC_POOL_ALREADY_SET_FOR_BORROWER(); // "Targeted borrower is already set for another pool";
  error PC_POOL_TOKEN_NOT_SUPPORTED(); // "Underlying token is not supported by the yield provider";
  error PC_DISALLOW_UNMATCHED_BORROWER(); // "Revoking the wrong borrower as the provided borrower does not match the provided address";
  error PC_RATE_SPACING_COMPLIANCE(); // "Provided rate must be compliant with rate spacing";
  error PC_NO_ONGOING_LOAN(); // "Cannot default a pool that has no ongoing loan";
  error PC_NOT_ENOUGH_PROTOCOL_FEES(); // "Not enough registered protocol fees to withdraw";
  error PC_POOL_ALREADY_CLOSED(); // "Pool already closed";
  error PC_ZERO_POOL(); // "Cannot make actions on the zero pool";
  error PC_ZERO_ADDRESS(); // "Cannot make actions on the zero address";
  error PC_REPAYMENT_PERIOD_ONGOING(); // "Cannot default pool while repayment period in ongoing"
  error PC_ESTABLISHMENT_FEES_TOO_HIGH(); // "Cannot set establishment fee over 100% of loan amount"
  error PC_BORROWER_ALREADY_AUTHORIZED(); // "Borrower already authorized on another pool"

  // PositionManager
  error POS_MGMT_ONLY_OWNER(); // "Only the owner of the position token can manage it (update rate, withdraw)";
  error POS_POSITION_ONLY_IN_BONDS(); // "Cannot withdraw a position that's only in bonds";
  error POS_ZERO_AMOUNT(); // "Cannot deposit zero amount";
  error POS_TIMELOCK(); // "Cannot withdraw or update rate in the same block as deposit";
  error POS_POSITION_DOES_NOT_EXIST(); // "Position does not exist";
  error POS_POOL_DEFAULTED(); // "Pool defaulted";
  error POS_ZERO_ADDRESS(); // "Cannot make actions on the zero address";
  error POS_NOT_ALLOWED(); // "Transaction sender is not allowed to perform the target action";

  // PositionDescriptor
  error POD_BAD_INPUT(); // "Pool identifier already taken";
  error POD_NOT_ALLOWED(); // "Only governance can change pool name";

  //*** Library Specific Errors ***
  // WadRayMath
  error MATH_MULTIPLICATION_OVERFLOW(); // "The multiplication would result in a overflow";
  error MATH_ADDITION_OVERFLOW(); // "The addition would result in a overflow";
  error MATH_DIVISION_BY_ZERO(); // "The division would result in a divzion by zero";
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Rounding} from "./Rounding.sol";
import {Scaling} from "./Scaling.sol";
import {Uint128WadRayMath} from "./Uint128WadRayMath.sol";
import "./Types.sol";
import "./Errors.sol";
import "../extensions/AaveILendingPool.sol";

library PoolLogic {
  event PoolActivated(bytes32 poolHash);
  enum BalanceUpdateType {
    INCREASE,
    DECREASE
  }
  event TickInitialized(bytes32 borrower, uint128 rate, uint128 atlendisLiquidityRatio);
  event TickLoanDeposit(bytes32 borrower, uint128 rate, uint128 adjustedPendingDeposit);
  event TickNoLoanDeposit(
    bytes32 borrower,
    uint128 rate,
    uint128 adjustedPendingDeposit,
    uint128 atlendisLiquidityRatio
  );
  event TickBorrow(
    bytes32 borrower,
    uint128 rate,
    uint128 adjustedRemainingAmountReduction,
    uint128 loanedAmount,
    uint128 atlendisLiquidityRatio,
    uint128 unborrowedRatio
  );
  event TickWithdrawPending(bytes32 borrower, uint128 rate, uint128 adjustedAmountToWithdraw);
  event TickWithdrawRemaining(
    bytes32 borrower,
    uint128 rate,
    uint128 adjustedAmountToWithdraw,
    uint128 atlendisLiquidityRatio,
    uint128 accruedFeesToWithdraw
  );
  event TickPendingDeposit(
    bytes32 borrower,
    uint128 rate,
    uint128 adjustedPendingAmount,
    bool poolBondIssuanceIndexIncremented
  );
  event TopUpLiquidityRewards(bytes32 borrower, uint128 addedLiquidityRewards);
  event TickRepay(bytes32 borrower, uint128 rate, uint128 newAdjustedRemainingAmount, uint128 atlendisLiquidityRatio);
  event CollectFeesForTick(bytes32 borrower, uint128 rate, uint128 remainingLiquidityRewards, uint128 addedAccruedFees);

  using PoolLogic for Types.Pool;
  using Uint128WadRayMath for uint128;
  using Rounding for uint128;
  using Scaling for uint128;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint256 public constant SECONDS_PER_YEAR = 365 days;
  uint256 public constant WAD = 1e18;
  uint256 public constant RAY = 1e27;

  /**
   * @dev Getter for the multiplier allowing a conversion between pending and deposited
   * amounts for the target bonds issuance index
   **/
  function getBondIssuanceMultiplierForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 bondsIssuanceIndex
  ) internal view returns (uint128 returnBondsIssuanceMultiplier) {
    Types.Tick storage tick = pool.ticks[rate];
    returnBondsIssuanceMultiplier = tick.bondsIssuanceIndexMultiplier[bondsIssuanceIndex];
    if (returnBondsIssuanceMultiplier == 0) {
      returnBondsIssuanceMultiplier = uint128(RAY);
    }
  }

  /**
   * @dev Get share of accumulated fees from stored current tick state
   **/
  function getAccruedFeesShare(
    Types.Pool storage pool,
    uint128 rate,
    uint128 adjustedAmount
  ) internal view returns (uint128 accruedFeesShare) {
    Types.Tick storage tick = pool.ticks[rate];
    accruedFeesShare = tick.accruedFees.wadMul(adjustedAmount).wadDiv(tick.adjustedRemainingAmount);
  }

  /**
   * @dev Get share of accumulated fees from estimated current tick state
   **/
  function peekAccruedFeesShare(
    Types.Pool storage pool,
    uint128 rate,
    uint128 adjustedAmount,
    uint128 accruedFees
  ) public view returns (uint128 accruedFeesShare) {
    Types.Tick storage tick = pool.ticks[rate];
    if (tick.adjustedRemainingAmount == 0) {
      return 0;
    }
    accruedFeesShare = accruedFees.wadMul(adjustedAmount).wadDiv(tick.adjustedRemainingAmount);
  }

  function getLateRepayFeePerBond(Types.Pool storage pool) public view returns (uint128 lateRepayFeePerBond) {
    uint256 lateRepaymentTimestamp = pool.state.currentMaturity + pool.parameters.REPAYMENT_PERIOD;
    if (block.timestamp > lateRepaymentTimestamp) {
      uint256 referenceTimestamp = pool.state.defaultTimestamp > 0 ? pool.state.defaultTimestamp : block.timestamp;
      lateRepayFeePerBond = uint128(
        uint256(referenceTimestamp - lateRepaymentTimestamp) * uint256(pool.parameters.LATE_REPAY_FEE_PER_BOND_RATE)
      );
    }
  }

  function getRepaymentFees(Types.Pool storage pool, uint128 normalizedRepayAmount)
    public
    view
    returns (uint128 repaymentFees)
  {
    repaymentFees = (normalizedRepayAmount - pool.state.normalizedBorrowedAmount).wadMul(
      pool.parameters.REPAYMENT_FEE_RATE
    );
  }

  /**
   * @dev The return value includes only notional and accrued interest,
   * it does not include any fees due for repay by the borrrower
   **/
  function getRepayValue(Types.Pool storage pool, bool earlyRepay) public view returns (uint128 repayValue) {
    if (pool.state.currentMaturity == 0) {
      return 0;
    }
    if (!earlyRepay) {
      // Note: Despite being in the context of a none early repay we prevent underflow in case of wrong user input
      // and allow querying expected bonds quantity if loan is repaid at maturity
      if (block.timestamp <= pool.state.currentMaturity) {
        return pool.state.bondsIssuedQuantity;
      }
    }
    for (
      uint128 rate = pool.state.lowerInterestRate;
      rate <= pool.parameters.MAX_RATE;
      rate += pool.parameters.RATE_SPACING
    ) {
      Types.Tick storage tick = pool.ticks[rate];
      repayValue += getTimeValue(pool, tick.bondsQuantity, rate);
    }
  }

  function getTimeValue(
    Types.Pool storage pool,
    uint128 bondsQuantity,
    uint128 rate
  ) public view returns (uint128) {
    if (block.timestamp <= pool.state.currentMaturity) {
      return bondsQuantity.wadMul(getTickBondPrice(rate, uint128(pool.state.currentMaturity - block.timestamp)));
    }
    uint256 referenceTimestamp = uint128(block.timestamp);
    if (pool.state.defaultTimestamp > 0) {
      referenceTimestamp = pool.state.defaultTimestamp;
    }
    return bondsQuantity.wadDiv(getTickBondPrice(rate, uint128(referenceTimestamp - pool.state.currentMaturity)));
  }

  /**
   * @dev Deposit to a target tick
   * Updates tick data
   **/
  function depositToTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 normalizedAmount
  ) public returns (uint128 adjustedAmount, uint128 returnBondsIssuanceIndex) {
    Types.Tick storage tick = pool.ticks[rate];

    pool.collectFees(rate);

    // if there is an ongoing loan, the deposited amount goes to the pending
    // quantity and will be considered for next loan
    if (pool.state.currentMaturity > 0) {
      adjustedAmount = normalizedAmount.wadRayDiv(tick.yieldProviderLiquidityRatio);
      tick.adjustedPendingAmount += adjustedAmount;
      returnBondsIssuanceIndex = pool.state.currentBondsIssuanceIndex + 1;
      emit TickLoanDeposit(pool.parameters.POOL_HASH, rate, adjustedAmount);
    }
    // if there is no ongoing loan, the deposited amount goes to total and remaining
    // amount and can be borrowed instantaneously
    else {
      adjustedAmount = normalizedAmount.wadRayDiv(tick.atlendisLiquidityRatio);
      tick.adjustedTotalAmount += adjustedAmount;
      tick.adjustedRemainingAmount += adjustedAmount;
      returnBondsIssuanceIndex = pool.state.currentBondsIssuanceIndex;
      pool.state.normalizedAvailableDeposits += normalizedAmount;

      // return amount adapted to bond index
      adjustedAmount = adjustedAmount.wadRayDiv(
        pool.getBondIssuanceMultiplierForTick(rate, pool.state.currentBondsIssuanceIndex)
      );
      emit TickNoLoanDeposit(pool.parameters.POOL_HASH, rate, adjustedAmount, tick.atlendisLiquidityRatio);
    }
    if ((pool.state.lowerInterestRate == 0) || (rate < pool.state.lowerInterestRate)) {
      pool.state.lowerInterestRate = rate;
    }
  }

  /**
   * @dev Computes the quantity of bonds purchased, and the equivalent adjusted deposit amount used for the issuance
   **/
  function getBondsIssuanceParametersForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 normalizedRemainingAmount
  ) public returns (uint128 bondsPurchasedQuantity, uint128 normalizedUsedAmount) {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.adjustedRemainingAmount.wadRayMul(tick.atlendisLiquidityRatio) >= normalizedRemainingAmount) {
      normalizedUsedAmount = normalizedRemainingAmount;
    } else if (
      tick.adjustedRemainingAmount.wadRayMul(tick.atlendisLiquidityRatio) + tick.accruedFees >=
      normalizedRemainingAmount
    ) {
      normalizedUsedAmount = normalizedRemainingAmount;
      tick.accruedFees -=
        normalizedRemainingAmount -
        tick.adjustedRemainingAmount.wadRayMul(tick.atlendisLiquidityRatio);
    } else {
      normalizedUsedAmount = tick.adjustedRemainingAmount.wadRayMul(tick.atlendisLiquidityRatio) + tick.accruedFees;
      tick.accruedFees = 0;
    }
    uint128 bondsPurchasePrice = getTickBondPrice(
      rate,
      pool.state.currentMaturity == 0
        ? pool.parameters.LOAN_DURATION
        : pool.state.currentMaturity - uint128(block.timestamp)
    );
    bondsPurchasedQuantity = normalizedUsedAmount.wadDiv(bondsPurchasePrice);
  }

  /**
   * @dev Makes all the state changes necessary to add bonds to a tick
   * Updates tick data and conversion data
   **/
  function addBondsToTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 bondsIssuedQuantity,
    uint128 normalizedUsedAmountForPurchase
  ) public {
    Types.Tick storage tick = pool.ticks[rate];

    // update global state for tick and pool
    tick.bondsQuantity += bondsIssuedQuantity;
    uint128 adjustedAmountForPurchase = normalizedUsedAmountForPurchase.wadRayDiv(tick.atlendisLiquidityRatio);
    if (adjustedAmountForPurchase > tick.adjustedRemainingAmount) {
      adjustedAmountForPurchase = tick.adjustedRemainingAmount;
    }
    tick.adjustedRemainingAmount -= adjustedAmountForPurchase;
    tick.normalizedLoanedAmount += normalizedUsedAmountForPurchase;
    // emit event with tick updates
    uint128 unborrowedRatio = tick.adjustedRemainingAmount.wadDiv(tick.adjustedTotalAmount);
    emit TickBorrow(
      pool.parameters.POOL_HASH,
      rate,
      adjustedAmountForPurchase,
      normalizedUsedAmountForPurchase,
      tick.atlendisLiquidityRatio,
      unborrowedRatio
    );
    pool.state.bondsIssuedQuantity += bondsIssuedQuantity;
    pool.state.normalizedAvailableDeposits -= normalizedUsedAmountForPurchase;
  }

  /**
   * @dev Computes how the position is split between deposit and bonds
   **/
  function computeAmountRepartitionForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 adjustedAmount,
    uint128 bondsIssuanceIndex
  ) public view returns (uint128 bondsQuantity, uint128 adjustedDepositedAmount) {
    Types.Tick storage tick = pool.ticks[rate];

    if (bondsIssuanceIndex > pool.state.currentBondsIssuanceIndex) {
      return (0, adjustedAmount);
    }

    adjustedAmount = adjustedAmount.wadRayMul(pool.getBondIssuanceMultiplierForTick(rate, bondsIssuanceIndex));
    uint128 adjustedAmountUsedForBondsIssuance;
    if (tick.adjustedTotalAmount > 0) {
      adjustedAmountUsedForBondsIssuance = adjustedAmount
        .wadMul(tick.adjustedTotalAmount - tick.adjustedRemainingAmount)
        .wadDiv(tick.adjustedTotalAmount + tick.adjustedWithdrawnAmount);
    }

    if (adjustedAmount >= adjustedAmountUsedForBondsIssuance) {
      if (tick.adjustedTotalAmount > tick.adjustedRemainingAmount) {
        bondsQuantity = tick.bondsQuantity.wadMul(adjustedAmountUsedForBondsIssuance).wadDiv(
          tick.adjustedTotalAmount - tick.adjustedRemainingAmount
        );
      }
      adjustedDepositedAmount = (adjustedAmount - adjustedAmountUsedForBondsIssuance);
    } else {
      /**
       * This condition is obtained when precision problems occur in the computation of `adjustedAmountUsedForBondsIssuance`.
       * Such problems have been observed when dealing with amounts way lower than a WAD.
       * In this case, the remaining and withdrawn amounts are assumed at 0.
       * Therefore, the deposited amount is returned as 0 and the bonds quantity is computed using only the adjusted total amount.
       */
      bondsQuantity = tick.bondsQuantity.wadMul(adjustedAmount).wadDiv(tick.adjustedTotalAmount);
      adjustedDepositedAmount = 0;
    }
  }

  /**
   * @dev Updates tick data after a withdrawal consisting of only amount deposited to yield provider
   **/
  function withdrawDepositedAmountForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 adjustedAmountToWithdraw,
    uint128 bondsIssuanceIndex
  ) public returns (uint128 normalizedAmountToWithdraw) {
    Types.Tick storage tick = pool.ticks[rate];

    pool.collectFees(rate);

    if (bondsIssuanceIndex <= pool.state.currentBondsIssuanceIndex) {
      uint128 feesShareToWithdraw = pool.getAccruedFeesShare(rate, adjustedAmountToWithdraw);
      tick.accruedFees -= feesShareToWithdraw;
      tick.adjustedTotalAmount -= adjustedAmountToWithdraw;
      tick.adjustedRemainingAmount -= adjustedAmountToWithdraw;

      normalizedAmountToWithdraw =
        adjustedAmountToWithdraw.wadRayMul(tick.atlendisLiquidityRatio) +
        feesShareToWithdraw;
      pool.state.normalizedAvailableDeposits -= normalizedAmountToWithdraw.round();

      // register withdrawn amount from partially matched positions
      // to maintain the proportion of bonds in each subsequent position the same
      if (tick.bondsQuantity > 0) {
        tick.adjustedWithdrawnAmount += adjustedAmountToWithdraw;
      }
      emit TickWithdrawRemaining(
        pool.parameters.POOL_HASH,
        rate,
        adjustedAmountToWithdraw,
        tick.atlendisLiquidityRatio,
        feesShareToWithdraw
      );
    } else {
      tick.adjustedPendingAmount -= adjustedAmountToWithdraw;
      normalizedAmountToWithdraw = adjustedAmountToWithdraw.wadRayMul(tick.yieldProviderLiquidityRatio);
      emit TickWithdrawPending(pool.parameters.POOL_HASH, rate, adjustedAmountToWithdraw);
    }

    // update lowerInterestRate if necessary
    if ((rate == pool.state.lowerInterestRate) && tick.adjustedTotalAmount == 0) {
      uint128 nextRate = rate + pool.parameters.RATE_SPACING;
      while (nextRate <= pool.parameters.MAX_RATE && pool.ticks[nextRate].adjustedTotalAmount == 0) {
        nextRate += pool.parameters.RATE_SPACING;
      }
      if (nextRate >= pool.parameters.MAX_RATE) {
        pool.state.lowerInterestRate = 0;
      } else {
        pool.state.lowerInterestRate = nextRate;
      }
    }
  }

  /**
   * @dev Updates tick data after a repayment
   **/
  function repayForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 lateRepayFeePerBond
  ) public returns (uint128 normalizedRepayAmountForTick, uint128 lateRepayFeeForTick) {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.bondsQuantity > 0) {
      normalizedRepayAmountForTick = getTimeValue(pool, tick.bondsQuantity, rate);
      lateRepayFeeForTick = lateRepayFeePerBond.wadMul(normalizedRepayAmountForTick);
      uint128 bondPaidInterests = normalizedRepayAmountForTick - tick.normalizedLoanedAmount;
      // update liquidity ratio with interests from bonds, yield provider and liquidity rewards
      tick.atlendisLiquidityRatio += (tick.accruedFees + bondPaidInterests + lateRepayFeeForTick)
        .wadDiv(tick.adjustedTotalAmount)
        .wadToRay();

      // update tick amounts
      tick.bondsQuantity = 0;
      tick.adjustedWithdrawnAmount = 0;
      tick.normalizedLoanedAmount = 0;
      tick.accruedFees = 0;
      tick.adjustedRemainingAmount = tick.adjustedTotalAmount;
      emit TickRepay(pool.parameters.POOL_HASH, rate, tick.adjustedTotalAmount, tick.atlendisLiquidityRatio);
    }
  }

  /**
   * @dev Updates tick data after a repayment
   **/
  function includePendingDepositsForTick(
    Types.Pool storage pool,
    uint128 rate,
    bool bondsIssuanceIndexAlreadyIncremented
  ) internal returns (bool pendingDepositsExist) {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.adjustedPendingAmount > 0) {
      if (!bondsIssuanceIndexAlreadyIncremented) {
        pool.state.currentBondsIssuanceIndex += 1;
      }
      // include pending deposit amount into tick excluding them from bonds interest from current issuance
      tick.bondsIssuanceIndexMultiplier[pool.state.currentBondsIssuanceIndex] = pool
        .state
        .yieldProviderLiquidityRatio
        .rayDiv(tick.atlendisLiquidityRatio);
      uint128 adjustedPendingAmount = tick.adjustedPendingAmount.wadRayMul(
        tick.bondsIssuanceIndexMultiplier[pool.state.currentBondsIssuanceIndex]
      );

      // update global pool state
      pool.state.normalizedAvailableDeposits += tick.adjustedPendingAmount.wadRayMul(
        pool.state.yieldProviderLiquidityRatio
      );

      // update tick amounts
      tick.adjustedTotalAmount += adjustedPendingAmount;
      tick.adjustedRemainingAmount = tick.adjustedTotalAmount;
      tick.adjustedPendingAmount = 0;
      emit TickPendingDeposit(
        pool.parameters.POOL_HASH,
        rate,
        adjustedPendingAmount,
        !bondsIssuanceIndexAlreadyIncremented
      );
      return true;
    }
    return false;
  }

  /**
   * @dev Top up liquidity rewards for later distribution
   **/
  function topUpLiquidityRewards(Types.Pool storage pool, uint128 normalizedAmount)
    public
    returns (uint128 yieldProviderLiquidityRatio)
  {
    yieldProviderLiquidityRatio = uint128(
      pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(pool.parameters.UNDERLYING_TOKEN))
    );
    pool.state.remainingAdjustedLiquidityRewardsReserve += normalizedAmount.wadRayDiv(yieldProviderLiquidityRatio);
  }

  /**
   * @dev Distributes remaining liquidity rewards reserve to lenders
   * Called in case of pool default
   **/
  function distributeLiquidityRewards(Types.Pool storage pool) public returns (uint128 distributedLiquidityRewards) {
    uint128 currentInterestRate = pool.state.lowerInterestRate;

    uint128 yieldProviderLiquidityRatio = uint128(
      pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(pool.parameters.UNDERLYING_TOKEN))
    );

    distributedLiquidityRewards = pool.state.remainingAdjustedLiquidityRewardsReserve.wadRayMul(
      yieldProviderLiquidityRatio
    );
    pool.state.normalizedAvailableDeposits += distributedLiquidityRewards;
    pool.state.remainingAdjustedLiquidityRewardsReserve = 0;

    while (pool.ticks[currentInterestRate].bondsQuantity > 0 && currentInterestRate <= pool.parameters.MAX_RATE) {
      pool.ticks[currentInterestRate].accruedFees += distributedLiquidityRewards
        .wadMul(pool.ticks[currentInterestRate].bondsQuantity)
        .wadDiv(pool.state.bondsIssuedQuantity);
      currentInterestRate += pool.parameters.RATE_SPACING;
    }
  }

  /**
   * @dev Updates tick data to reflect all fees accrued since last call
   * Accrued fees are composed of the yield provider liquidity ratio increase
   * and liquidity rewards paid by the borrower
   **/
  function collectFeesForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 yieldProviderLiquidityRatio
  ) internal {
    Types.Tick storage tick = pool.ticks[rate];
    if (tick.lastFeeDistributionTimestamp < block.timestamp) {
      (
        uint128 updatedAtlendisLiquidityRatio,
        uint128 updatedAccruedFees,
        uint128 liquidityRewardsIncrease,
        uint128 yieldProviderLiquidityRatioIncrease
      ) = pool.peekFeesForTick(rate, yieldProviderLiquidityRatio);

      // update global deposited amount
      pool.state.remainingAdjustedLiquidityRewardsReserve -= liquidityRewardsIncrease.wadRayDiv(
        yieldProviderLiquidityRatio
      );
      pool.state.normalizedAvailableDeposits +=
        liquidityRewardsIncrease +
        tick.adjustedRemainingAmount.wadRayMul(yieldProviderLiquidityRatioIncrease);

      // update tick data
      uint128 accruedFeesIncrease = updatedAccruedFees - tick.accruedFees;
      if (tick.atlendisLiquidityRatio == 0) {
        tick.yieldProviderLiquidityRatio = yieldProviderLiquidityRatio;
        emit TickInitialized(pool.parameters.POOL_HASH, rate, yieldProviderLiquidityRatio);
      }
      tick.atlendisLiquidityRatio = updatedAtlendisLiquidityRatio;
      tick.accruedFees = updatedAccruedFees;

      // update checkpoint data
      tick.lastFeeDistributionTimestamp = uint128(block.timestamp);

      emit CollectFeesForTick(
        pool.parameters.POOL_HASH,
        rate,
        pool.state.remainingAdjustedLiquidityRewardsReserve.wadRayMul(yieldProviderLiquidityRatio),
        accruedFeesIncrease
      );
    }
  }

  function collectFees(Types.Pool storage pool, uint128 rate) internal {
    uint128 yieldProviderLiquidityRatio = uint128(
      pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(pool.parameters.UNDERLYING_TOKEN))
    );
    pool.collectFeesForTick(rate, yieldProviderLiquidityRatio);
    pool.ticks[rate].yieldProviderLiquidityRatio = yieldProviderLiquidityRatio;
  }

  function collectFees(Types.Pool storage pool) internal {
    uint128 yieldProviderLiquidityRatio = uint128(
      pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(pool.parameters.UNDERLYING_TOKEN))
    );
    for (
      uint128 currentInterestRate = pool.state.lowerInterestRate;
      currentInterestRate <= pool.parameters.MAX_RATE;
      currentInterestRate += pool.parameters.RATE_SPACING
    ) {
      pool.collectFeesForTick(currentInterestRate, yieldProviderLiquidityRatio);
    }
    pool.state.yieldProviderLiquidityRatio = yieldProviderLiquidityRatio;
  }

  /**
   * @dev Peek updated liquidity ratio and accrued fess for the target tick
   * Used to compute a position balance without updating storage
   **/
  function peekFeesForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 yieldProviderLiquidityRatio
  )
    internal
    view
    returns (
      uint128 updatedAtlendisLiquidityRatio,
      uint128 updatedAccruedFees,
      uint128 liquidityRewardsIncrease,
      uint128 yieldProviderLiquidityRatioIncrease
    )
  {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.atlendisLiquidityRatio == 0) {
      return (yieldProviderLiquidityRatio, 0, 0, 0);
    }

    updatedAtlendisLiquidityRatio = tick.atlendisLiquidityRatio;
    updatedAccruedFees = tick.accruedFees;

    uint128 referenceLiquidityRatio;
    if (pool.state.yieldProviderLiquidityRatio > tick.yieldProviderLiquidityRatio) {
      referenceLiquidityRatio = pool.state.yieldProviderLiquidityRatio;
    } else {
      referenceLiquidityRatio = tick.yieldProviderLiquidityRatio;
    }
    yieldProviderLiquidityRatioIncrease = yieldProviderLiquidityRatio - referenceLiquidityRatio;

    // get additional fees from liquidity rewards
    liquidityRewardsIncrease = pool.getLiquidityRewardsIncrease(rate);
    uint128 currentNormalizedRemainingLiquidityRewards = pool.state.remainingAdjustedLiquidityRewardsReserve.wadRayMul(
      yieldProviderLiquidityRatio
    );
    if (liquidityRewardsIncrease > currentNormalizedRemainingLiquidityRewards) {
      liquidityRewardsIncrease = currentNormalizedRemainingLiquidityRewards;
    }
    // if no ongoing loan, all deposited amount gets the yield provider
    // and liquidity rewards so the global liquidity ratio is updated
    if (pool.state.currentMaturity == 0) {
      updatedAtlendisLiquidityRatio += yieldProviderLiquidityRatioIncrease;
      if (tick.adjustedRemainingAmount > 0) {
        updatedAtlendisLiquidityRatio += liquidityRewardsIncrease.wadToRay().wadDiv(tick.adjustedRemainingAmount);
      }
    }
    // if ongoing loan, accruing fees components are added, liquidity ratio will be updated at repay time
    else {
      updatedAccruedFees +=
        tick.adjustedRemainingAmount.wadRayMul(yieldProviderLiquidityRatioIncrease) +
        liquidityRewardsIncrease;
    }
  }

  /**
   * @dev Computes liquidity rewards amount to be paid to lenders since last fee collection
   * Liquidity rewards are paid to the unborrowed amount, and distributed to all ticks depending
   * on their normalized amounts
   **/
  function getLiquidityRewardsIncrease(Types.Pool storage pool, uint128 rate)
    internal
    view
    returns (uint128 liquidityRewardsIncrease)
  {
    Types.Tick storage tick = pool.ticks[rate];
    if (pool.state.normalizedAvailableDeposits > 0) {
      liquidityRewardsIncrease = (pool.parameters.LIQUIDITY_REWARDS_DISTRIBUTION_RATE *
        (uint128(block.timestamp) - tick.lastFeeDistributionTimestamp))
        .wadMul(pool.parameters.MAX_BORROWABLE_AMOUNT - pool.state.normalizedBorrowedAmount)
        .wadDiv(pool.parameters.MAX_BORROWABLE_AMOUNT)
        .wadMul(tick.adjustedRemainingAmount.wadRayMul(tick.atlendisLiquidityRatio))
        .wadDiv(pool.state.normalizedAvailableDeposits);
    }
  }

  function getTickBondPrice(uint128 rate, uint128 loanDuration) internal pure returns (uint128 price) {
    price = uint128(WAD).wadDiv(uint128(WAD + (uint256(rate) * uint256(loanDuration)) / uint256(SECONDS_PER_YEAR)));
  }

  function depositToYieldProvider(
    Types.Pool storage pool,
    address from,
    uint128 normalizedAmount
  ) public {
    IERC20Upgradeable underlyingToken = IERC20Upgradeable(pool.parameters.UNDERLYING_TOKEN);
    uint128 scaledAmount = normalizedAmount.scaleFromWad(pool.parameters.TOKEN_DECIMALS);
    ILendingPool yieldProvider = pool.parameters.YIELD_PROVIDER;
    underlyingToken.safeIncreaseAllowance(address(yieldProvider), scaledAmount);
    underlyingToken.safeTransferFrom(from, address(this), scaledAmount);
    yieldProvider.deposit(pool.parameters.UNDERLYING_TOKEN, scaledAmount, address(this), 0);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

library Roles {
  bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant POSITION_ROLE = keccak256("POSITION_ROLE");
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Rounding library
 * @author Atlendis
 * @dev Rounding utilities to mitigate precision loss when doing wad ray math operations
 **/
library Rounding {
  using Rounding for uint128;

  uint128 internal constant PRECISION = 1e3;

  /**
   * @notice rounds the input number with the default precision
   **/
  function round(uint128 amount) internal pure returns (uint128) {
    return (amount / PRECISION) * PRECISION;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Scaling library
 * @author Atlendis
 * @dev Scale an arbitrary number to or from WAD precision
 **/
library Scaling {
  uint256 internal constant WAD = 1e18;

  /**
   * @notice Scales an input amount to wad precision
   **/
  function scaleToWad(uint128 a, uint256 precision) internal pure returns (uint128) {
    return uint128((uint256(a) * WAD) / 10**precision);
  }

  /**
   * @notice Scales an input amount from wad to target precision
   **/
  function scaleFromWad(uint128 a, uint256 precision) internal pure returns (uint128) {
    return uint128((uint256(a) * 10**precision) / WAD);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../extensions/AaveILendingPool.sol";

library Types {
  struct PositionDetails {
    uint128 adjustedBalance;
    uint128 rate;
    bytes32 poolHash;
    address underlyingToken;
    uint128 bondsIssuanceIndex;
    uint128 remainingBonds;
    uint128 bondsMaturity;
    uint128 creationTimestamp;
  }

  struct Tick {
    mapping(uint128 => uint128) bondsIssuanceIndexMultiplier;
    uint128 bondsQuantity;
    uint128 adjustedTotalAmount;
    uint128 adjustedRemainingAmount;
    uint128 adjustedWithdrawnAmount;
    uint128 adjustedPendingAmount;
    uint128 normalizedLoanedAmount;
    uint128 lastFeeDistributionTimestamp;
    uint128 atlendisLiquidityRatio;
    uint128 yieldProviderLiquidityRatio;
    uint128 accruedFees;
  }

  struct PoolParameters {
    bytes32 POOL_HASH;
    address UNDERLYING_TOKEN;
    uint8 TOKEN_DECIMALS;
    ILendingPool YIELD_PROVIDER;
    uint128 MIN_RATE;
    uint128 MAX_RATE;
    uint128 RATE_SPACING;
    uint128 MAX_BORROWABLE_AMOUNT;
    uint128 LOAN_DURATION;
    uint128 LIQUIDITY_REWARDS_DISTRIBUTION_RATE;
    uint128 COOLDOWN_PERIOD;
    uint128 REPAYMENT_PERIOD;
    uint128 LATE_REPAY_FEE_PER_BOND_RATE;
    uint128 ESTABLISHMENT_FEE_RATE;
    uint128 REPAYMENT_FEE_RATE;
    uint128 LIQUIDITY_REWARDS_ACTIVATION_THRESHOLD;
    bool EARLY_REPAY;
  }

  struct PoolState {
    bool active;
    bool defaulted;
    bool closed;
    uint128 currentMaturity;
    uint128 bondsIssuedQuantity;
    uint128 normalizedBorrowedAmount;
    uint128 normalizedAvailableDeposits;
    uint128 lowerInterestRate;
    uint128 nextLoanMinStart;
    uint128 remainingAdjustedLiquidityRewardsReserve;
    uint128 yieldProviderLiquidityRatio;
    uint128 currentBondsIssuanceIndex;
    uint128 defaultTimestamp;
  }

  struct Pool {
    PoolParameters parameters;
    PoolState state;
    mapping(uint256 => Tick) ticks;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./WadRayMath.sol";

/**
 * @title Uint128WadRayMath library
 **/
library Uint128WadRayMath {
  using WadRayMath for uint256;

  /**
   * @dev Multiplies a wad to a ray, making back and forth conversions
   * @param a Wad
   * @param b Ray
   * @return The result of a*b, in wad
   **/
  function wadRayMul(uint128 a, uint128 b) internal pure returns (uint128) {
    return uint128(uint256(a).wadToRay().rayMul(uint256(b)).rayToWad());
  }

  /**
   * @dev Divides a wad to a ray, making back and forth conversions
   * @param a Wad
   * @param b Ray
   * @return The result of a/b, in wad
   **/
  function wadRayDiv(uint128 a, uint128 b) internal pure returns (uint128) {
    return uint128(uint256(a).wadToRay().rayDiv(uint256(b)).rayToWad());
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint128 a, uint128 b) internal pure returns (uint128) {
    return uint128(uint256(a).rayDiv(uint256(b)));
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint128 a, uint128 b) internal pure returns (uint128) {
    return uint128(uint256(a).wadMul(uint256(b)));
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint128 a, uint128 b) internal pure returns (uint128) {
    return uint128(uint256(a).wadDiv(uint256(b)));
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint128 a) internal pure returns (uint128) {
    return uint128(uint256(a).wadToRay());
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Errors.sol";

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/
  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    if (a > (type(uint256).max - halfWAD) / b) {
      revert Errors.MATH_MULTIPLICATION_OVERFLOW();
    }

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b == 0) {
      revert Errors.MATH_DIVISION_BY_ZERO();
    }
    uint256 halfB = b / 2;

    if (a > (type(uint256).max - halfB) / WAD) {
      revert Errors.MATH_MULTIPLICATION_OVERFLOW();
    }

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    if (a > (type(uint256).max - halfRAY) / b) {
      revert Errors.MATH_MULTIPLICATION_OVERFLOW();
    }

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b == 0) {
      revert Errors.MATH_DIVISION_BY_ZERO();
    }
    uint256 halfB = b / 2;

    if (a > (type(uint256).max - halfB) / RAY) {
      revert Errors.MATH_MULTIPLICATION_OVERFLOW();
    }

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    if (result < halfRatio) {
      revert Errors.MATH_ADDITION_OVERFLOW();
    }

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    if (result / WAD_RAY_RATIO != a) {
      revert Errors.MATH_MULTIPLICATION_OVERFLOW();
    }
    return result;
  }
}