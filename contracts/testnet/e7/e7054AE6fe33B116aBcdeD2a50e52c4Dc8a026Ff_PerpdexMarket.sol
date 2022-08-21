// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

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
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
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
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract TestERC20 is ERC20PresetMinterPauser {
    uint256 _transferFeeRatio;

    uint8 private immutable _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimalsArg
    ) ERC20PresetMinterPauser(name, symbol) {
        _decimals = decimalsArg;
        _transferFeeRatio = 0;
    }

    function setMinter(address minter) external {
        grantRole(MINTER_ROLE, minter);
    }

    function burnWithoutApproval(address user, uint256 amount) external {
        _burn(user, amount);
    }

    function setTransferFeeRatio(uint256 ratio) external {
        _transferFeeRatio = ratio;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool success) {
        if (_transferFeeRatio != 0) {
            uint256 fee = (amount * _transferFeeRatio) / 100;
            _burn(sender, fee);
            amount = amount - fee;
        }
        return super.transferFrom(sender, recipient, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { IPerpdexMarket } from "./interfaces/IPerpdexMarket.sol";
import { MarketStructs } from "./lib/MarketStructs.sol";
import { FundingLibrary } from "./lib/FundingLibrary.sol";
import { PoolLibrary } from "./lib/PoolLibrary.sol";
import { PriceLimitLibrary } from "./lib/PriceLimitLibrary.sol";
import { OrderBookLibrary } from "./lib/OrderBookLibrary.sol";
import { PoolFeeLibrary } from "./lib/PoolFeeLibrary.sol";

contract PerpdexMarket is IPerpdexMarket, ReentrancyGuard, Ownable, Multicall {
    using Address for address;
    using SafeCast for uint256;
    using SafeMath for uint256;

    event PoolFeeConfigChanged(uint24 fixedFeeRatio, uint24 atrFeeRatio, uint32 atrEmaBlocks);
    event FundingMaxPremiumRatioChanged(uint24 value);
    event FundingMaxElapsedSecChanged(uint32 value);
    event FundingRolloverSecChanged(uint32 value);
    event PriceLimitConfigChanged(
        uint24 normalOrderRatio,
        uint24 liquidationRatio,
        uint24 emaNormalOrderRatio,
        uint24 emaLiquidationRatio,
        uint32 emaSec
    );

    string public symbol;
    address public immutable exchange;
    address public immutable priceFeedBase;
    address public immutable priceFeedQuote;

    MarketStructs.PoolInfo public poolInfo;
    MarketStructs.FundingInfo public fundingInfo;
    MarketStructs.PriceLimitInfo public priceLimitInfo;
    MarketStructs.OrderBookInfo internal _orderBookInfo;
    MarketStructs.PoolFeeInfo public poolFeeInfo;

    uint24 public fundingMaxPremiumRatio = 1e4;
    uint32 public fundingMaxElapsedSec = 1 days;
    uint32 public fundingRolloverSec = 1 days;
    MarketStructs.PriceLimitConfig public priceLimitConfig =
        MarketStructs.PriceLimitConfig({
            normalOrderRatio: 5e4,
            liquidationRatio: 10e4,
            emaNormalOrderRatio: 20e4,
            emaLiquidationRatio: 25e4,
            emaSec: 5 minutes
        });
    MarketStructs.PoolFeeConfig public poolFeeConfig =
        MarketStructs.PoolFeeConfig({ fixedFeeRatio: 0, atrFeeRatio: 4e6, atrEmaBlocks: 16 });

    modifier onlyExchange() {
        _onlyExchange();
        _;
    }

    constructor(
        address ownerArg,
        string memory symbolArg,
        address exchangeArg,
        address priceFeedBaseArg,
        address priceFeedQuoteArg
    ) {
        _transferOwnership(ownerArg);
        require(priceFeedBaseArg == address(0) || priceFeedBaseArg.isContract(), "PM_C: base price feed invalid");
        require(priceFeedQuoteArg == address(0) || priceFeedQuoteArg.isContract(), "PM_C: quote price feed invalid");

        symbol = symbolArg;
        exchange = exchangeArg;
        priceFeedBase = priceFeedBaseArg;
        priceFeedQuote = priceFeedQuoteArg;

        FundingLibrary.initializeFunding(fundingInfo);
        PoolLibrary.initializePool(poolInfo);
    }

    function swap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external onlyExchange nonReentrant returns (SwapResponse memory response) {
        (uint256 maxAmount, MarketStructs.PriceLimitInfo memory updated) =
            _doMaxSwap(isBaseToQuote, isExactInput, isLiquidation, 0);
        require(amount <= maxAmount, "PM_S: too large amount");

        uint256 sharePriceBeforeX96 = getShareMarkPriceX96();

        OrderBookLibrary.SwapResponse memory swapResponse =
            OrderBookLibrary.swap(
                _orderBookInfo,
                OrderBookLibrary.PreviewSwapParams({
                    isBaseToQuote: isBaseToQuote,
                    isExactInput: isExactInput,
                    amount: amount,
                    baseBalancePerShareX96: poolInfo.baseBalancePerShareX96
                }),
                _poolMaxSwap,
                _poolSwap
            );
        response = SwapResponse({
            oppositeAmount: swapResponse.oppositeAmount,
            basePartial: swapResponse.basePartial,
            quotePartial: swapResponse.quotePartial,
            partialOrderId: swapResponse.partialKey
        });

        PoolFeeLibrary.update(poolFeeInfo, poolFeeConfig.atrEmaBlocks, sharePriceBeforeX96, getShareMarkPriceX96());
        PriceLimitLibrary.update(priceLimitInfo, updated);

        emit Swapped(
            isBaseToQuote,
            isExactInput,
            amount,
            response.oppositeAmount,
            swapResponse.fullLastKey,
            response.partialOrderId,
            response.basePartial,
            response.quotePartial
        );

        _processFunding();
    }

    function _poolSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount
    ) private returns (uint256) {
        return
            PoolLibrary.swap(
                poolInfo,
                PoolLibrary.SwapParams({
                    isBaseToQuote: isBaseToQuote,
                    isExactInput: isExactInput,
                    amount: amount,
                    feeRatio: feeRatio()
                })
            );
    }

    function addLiquidity(uint256 baseShare, uint256 quoteBalance)
        external
        onlyExchange
        nonReentrant
        returns (
            uint256 base,
            uint256 quote,
            uint256 liquidity
        )
    {
        if (poolInfo.totalLiquidity == 0) {
            FundingLibrary.validateInitialLiquidityPrice(priceFeedBase, priceFeedQuote, baseShare, quoteBalance);
        }

        (base, quote, liquidity) = PoolLibrary.addLiquidity(
            poolInfo,
            PoolLibrary.AddLiquidityParams({ base: baseShare, quote: quoteBalance })
        );
        emit LiquidityAdded(base, quote, liquidity);
    }

    function removeLiquidity(uint256 liquidity)
        external
        onlyExchange
        nonReentrant
        returns (uint256 base, uint256 quote)
    {
        (base, quote) = PoolLibrary.removeLiquidity(
            poolInfo,
            PoolLibrary.RemoveLiquidityParams({ liquidity: liquidity })
        );
        emit LiquidityRemoved(base, quote, liquidity);
    }

    function createLimitOrder(
        bool isBid,
        uint256 base,
        uint256 priceX96
    ) external onlyExchange nonReentrant returns (uint40 orderId) {
        if (isBid) {
            require(priceX96 <= getAskPriceX96(), "PM_CLO: post only bid");
        } else {
            require(priceX96 >= getBidPriceX96(), "PM_CLO: post only ask");
        }
        orderId = OrderBookLibrary.createOrder(_orderBookInfo, isBid, base, priceX96);
        emit LimitOrderCreated(isBid, base, priceX96, orderId);
    }

    function cancelLimitOrder(bool isBid, uint40 orderId) external onlyExchange nonReentrant {
        OrderBookLibrary.cancelOrder(_orderBookInfo, isBid, orderId);
        emit LimitOrderCanceled(isBid, orderId);
    }

    function setFundingMaxPremiumRatio(uint24 value) external onlyOwner nonReentrant {
        require(value <= 1e5, "PM_SFMPR: too large");
        fundingMaxPremiumRatio = value;
        emit FundingMaxPremiumRatioChanged(value);
    }

    function setFundingMaxElapsedSec(uint32 value) external onlyOwner nonReentrant {
        require(value <= 7 days, "PM_SFMES: too large");
        fundingMaxElapsedSec = value;
        emit FundingMaxElapsedSecChanged(value);
    }

    function setFundingRolloverSec(uint32 value) external onlyOwner nonReentrant {
        require(value <= 7 days, "PM_SFRS: too large");
        require(value >= 1 hours, "PM_SFRS: too small");
        fundingRolloverSec = value;
        emit FundingRolloverSecChanged(value);
    }

    function setPriceLimitConfig(MarketStructs.PriceLimitConfig calldata value) external onlyOwner nonReentrant {
        require(value.liquidationRatio <= 5e5, "PE_SPLC: too large liquidation");
        require(value.normalOrderRatio <= value.liquidationRatio, "PE_SPLC: invalid");
        require(value.emaLiquidationRatio < 1e6, "PE_SPLC: ema too large liq");
        require(value.emaNormalOrderRatio <= value.emaLiquidationRatio, "PE_SPLC: ema invalid");
        priceLimitConfig = value;
        emit PriceLimitConfigChanged(
            value.normalOrderRatio,
            value.liquidationRatio,
            value.emaNormalOrderRatio,
            value.emaLiquidationRatio,
            value.emaSec
        );
    }

    function setPoolFeeConfig(MarketStructs.PoolFeeConfig calldata value) external onlyOwner nonReentrant {
        require(value.fixedFeeRatio <= 5e4, "PM_SPFC: fixed fee too large");
        require(value.atrEmaBlocks <= 1e4, "PM_SPFC: atr ema blocks too big");
        poolFeeConfig = value;
        emit PoolFeeConfigChanged(value.fixedFeeRatio, value.atrFeeRatio, value.atrEmaBlocks);
    }

    function previewSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external view returns (uint256 oppositeAmount) {
        (uint256 maxAmount, ) = _doMaxSwap(isBaseToQuote, isExactInput, isLiquidation, 0);
        require(amount <= maxAmount, "PM_PS: too large amount");

        OrderBookLibrary.PreviewSwapResponse memory response =
            OrderBookLibrary.previewSwap(
                isBaseToQuote ? _orderBookInfo.bid : _orderBookInfo.ask,
                OrderBookLibrary.PreviewSwapParams({
                    isBaseToQuote: isBaseToQuote,
                    isExactInput: isExactInput,
                    amount: amount,
                    baseBalancePerShareX96: poolInfo.baseBalancePerShareX96
                }),
                _poolMaxSwap
            );

        oppositeAmount = PoolLibrary.previewSwap(
            poolInfo.base,
            poolInfo.quote,
            PoolLibrary.SwapParams({
                isBaseToQuote: isBaseToQuote,
                isExactInput: isExactInput,
                amount: response.amountPool,
                feeRatio: feeRatio()
            })
        );
        bool isOppositeBase = isBaseToQuote != isExactInput;
        if (isOppositeBase) {
            oppositeAmount += response.baseFull + response.basePartial;
        } else {
            oppositeAmount += response.quoteFull + response.quotePartial;
        }
    }

    function _poolMaxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 sharePriceX96
    ) private view returns (uint256) {
        return
            PoolLibrary.maxSwap(poolInfo.base, poolInfo.quote, isBaseToQuote, isExactInput, feeRatio(), sharePriceX96);
    }

    function maxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation
    ) external view returns (uint256 amount) {
        (amount, ) = _doMaxSwap(isBaseToQuote, isExactInput, isLiquidation, 0);
    }

    function maxSwapByPrice(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 sharePriceX96
    ) external view returns (uint256 amount) {
        (amount, ) = _doMaxSwap(isBaseToQuote, isExactInput, false, sharePriceX96);
    }

    function getShareMarkPriceX96() public view returns (uint256) {
        if (poolInfo.base == 0) return 0;
        return PoolLibrary.getShareMarkPriceX96(poolInfo.base, poolInfo.quote);
    }

    function getLiquidityValue(uint256 liquidity) external view returns (uint256, uint256) {
        return PoolLibrary.getLiquidityValue(poolInfo, liquidity);
    }

    function getLiquidityDeleveraged(
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) external view returns (int256, int256) {
        return
            PoolLibrary.getLiquidityDeleveraged(
                poolInfo.cumBasePerLiquidityX96,
                poolInfo.cumQuotePerLiquidityX96,
                liquidity,
                cumBasePerLiquidityX96,
                cumQuotePerLiquidityX96
            );
    }

    function getCumDeleveragedPerLiquidityX96() external view returns (uint256, uint256) {
        return (poolInfo.cumBasePerLiquidityX96, poolInfo.cumQuotePerLiquidityX96);
    }

    function baseBalancePerShareX96() external view returns (uint256) {
        return poolInfo.baseBalancePerShareX96;
    }

    function getMarkPriceX96() public view returns (uint256) {
        if (poolInfo.base == 0) return 0;
        return PoolLibrary.getMarkPriceX96(poolInfo.base, poolInfo.quote, poolInfo.baseBalancePerShareX96);
    }

    function getAskPriceX96() public view returns (uint256 result) {
        result = PoolLibrary.getAskPriceX96(getMarkPriceX96(), feeRatio());
        uint256 obPrice = OrderBookLibrary.getBestPriceX96(_orderBookInfo.ask);
        if (obPrice != 0 && obPrice < result) {
            result = obPrice;
        }
    }

    function getBidPriceX96() public view returns (uint256 result) {
        result = PoolLibrary.getBidPriceX96(getMarkPriceX96(), feeRatio());
        uint256 obPrice = OrderBookLibrary.getBestPriceX96(_orderBookInfo.bid);
        if (obPrice != 0 && obPrice > result) {
            result = obPrice;
        }
    }

    function getLimitOrderInfo(bool isBid, uint40 orderId) external view returns (uint256 base, uint256 priceX96) {
        return OrderBookLibrary.getOrderInfo(_orderBookInfo, isBid, orderId);
    }

    function getLimitOrderExecution(bool isBid, uint40 orderId)
        external
        view
        returns (
            uint48 executionId,
            uint256 executedBase,
            uint256 executedQuote
        )
    {
        return OrderBookLibrary.getOrderExecution(_orderBookInfo, isBid, orderId);
    }

    function _processFunding() internal {
        uint256 markPriceX96 = getMarkPriceX96();
        (int256 fundingRateX96, uint32 elapsedSec, int256 premiumX96) =
            FundingLibrary.processFunding(
                fundingInfo,
                FundingLibrary.ProcessFundingParams({
                    priceFeedBase: priceFeedBase,
                    priceFeedQuote: priceFeedQuote,
                    markPriceX96: markPriceX96,
                    maxPremiumRatio: fundingMaxPremiumRatio,
                    maxElapsedSec: fundingMaxElapsedSec,
                    rolloverSec: fundingRolloverSec
                })
            );
        if (fundingRateX96 == 0) return;

        PoolLibrary.applyFunding(poolInfo, fundingRateX96);
        emit FundingPaid(
            fundingRateX96,
            elapsedSec,
            premiumX96,
            markPriceX96,
            poolInfo.cumBasePerLiquidityX96,
            poolInfo.cumQuotePerLiquidityX96
        );
    }

    function _doMaxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation,
        uint256 sharePriceX96
    ) private view returns (uint256 amount, MarketStructs.PriceLimitInfo memory updated) {
        if (poolInfo.totalLiquidity == 0) return (0, updated);

        if (sharePriceX96 == 0) {
            uint256 sharePriceBeforeX96 = getShareMarkPriceX96();
            updated = PriceLimitLibrary.updateDry(priceLimitInfo, priceLimitConfig, sharePriceBeforeX96);

            sharePriceX96 = PriceLimitLibrary.priceBound(
                updated.referencePrice,
                updated.emaPrice,
                priceLimitConfig,
                isLiquidation,
                !isBaseToQuote
            );
        }

        amount = PoolLibrary.maxSwap(
            poolInfo.base,
            poolInfo.quote,
            isBaseToQuote,
            isExactInput,
            feeRatio(),
            sharePriceX96
        );

        amount += OrderBookLibrary.maxSwap(
            isBaseToQuote ? _orderBookInfo.bid : _orderBookInfo.ask,
            isBaseToQuote,
            isExactInput,
            sharePriceX96,
            poolInfo.baseBalancePerShareX96
        );
    }

    function feeRatio() public view returns (uint24) {
        return
            Math
                .min(priceLimitConfig.normalOrderRatio / 2, PoolFeeLibrary.feeRatio(poolFeeInfo, poolFeeConfig))
                .toUint24();
    }

    // to reduce contract size
    function _onlyExchange() private view {
        require(exchange == msg.sender, "PM_OE: caller is not exchange");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { IPerpdexMarketMinimum } from "./IPerpdexMarketMinimum.sol";

interface IPerpdexMarket is IPerpdexMarketMinimum {
    event FundingPaid(
        int256 fundingRateX96,
        uint32 elapsedSec,
        int256 premiumX96,
        uint256 markPriceX96,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    );
    event LiquidityAdded(uint256 base, uint256 quote, uint256 liquidity);
    event LiquidityRemoved(uint256 base, uint256 quote, uint256 liquidity);
    event Swapped(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint256 oppositeAmount,
        uint40 fullLastOrderId,
        uint40 partialOrderId,
        uint256 basePartial,
        uint256 quotePartial
    );
    event LimitOrderCreated(bool isBid, uint256 base, uint256 priceX96, uint256 orderId);
    event LimitOrderCanceled(bool isBid, uint256 orderId);

    // getters

    function symbol() external view returns (string memory);

    function getMarkPriceX96() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import {
    BokkyPooBahsRedBlackTreeLibrary as RBTreeLibrary
} from "../../deps/BokkyPooBahsRedBlackTreeLibrary/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

library MarketStructs {
    struct FundingInfo {
        uint256 prevIndexPriceBase;
        uint256 prevIndexPriceQuote;
        uint256 prevIndexPriceTimestamp;
    }

    struct PoolInfo {
        uint256 base;
        uint256 quote;
        uint256 totalLiquidity;
        uint256 cumBasePerLiquidityX96;
        uint256 cumQuotePerLiquidityX96;
        uint256 baseBalancePerShareX96;
    }

    struct PriceLimitInfo {
        uint256 referencePrice;
        uint256 referenceTimestamp;
        uint256 emaPrice;
    }

    struct PriceLimitConfig {
        uint24 normalOrderRatio;
        uint24 liquidationRatio;
        uint24 emaNormalOrderRatio;
        uint24 emaLiquidationRatio;
        uint32 emaSec;
    }

    struct OrderInfo {
        uint256 base;
        uint256 baseSum;
        uint256 quoteSum;
        uint48 executionId;
    }

    struct OrderBookSideInfo {
        RBTreeLibrary.Tree tree;
        mapping(uint40 => OrderInfo) orderInfos;
        uint40 seqKey;
    }

    struct ExecutionInfo {
        uint256 baseBalancePerShareX96;
    }

    struct OrderBookInfo {
        OrderBookSideInfo ask;
        OrderBookSideInfo bid;
        uint48 seqExecutionId;
        mapping(uint48 => ExecutionInfo) executionInfos;
    }

    struct PoolFeeInfo {
        uint256 atrX96;
        uint256 referenceTimestamp;
        uint256 currentHighX96;
        uint256 currentLowX96;
    }

    struct PoolFeeConfig {
        uint24 fixedFeeRatio;
        uint24 atrFeeRatio;
        uint32 atrEmaBlocks;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { MarketStructs } from "./MarketStructs.sol";
import { IPerpdexPriceFeed } from "../interfaces/IPerpdexPriceFeed.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

library FundingLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct ProcessFundingParams {
        address priceFeedBase;
        address priceFeedQuote;
        uint256 markPriceX96;
        uint24 maxPremiumRatio;
        uint32 maxElapsedSec;
        uint32 rolloverSec;
    }

    uint8 public constant MAX_DECIMALS = 77; // 10^MAX_DECIMALS < 2^256

    function initializeFunding(MarketStructs.FundingInfo storage fundingInfo) internal {
        fundingInfo.prevIndexPriceTimestamp = block.timestamp;
    }

    // must not revert even if priceFeed is malicious
    function processFunding(MarketStructs.FundingInfo storage fundingInfo, ProcessFundingParams memory params)
        internal
        returns (
            int256 fundingRateX96,
            uint32 elapsedSec,
            int256 premiumX96
        )
    {
        uint256 currentTimestamp = block.timestamp;
        uint256 elapsedSec256 = currentTimestamp.sub(fundingInfo.prevIndexPriceTimestamp);
        if (elapsedSec256 == 0) return (0, 0, 0);

        uint256 indexPriceBase = _getIndexPriceSafe(params.priceFeedBase);
        uint256 indexPriceQuote = _getIndexPriceSafe(params.priceFeedQuote);
        uint8 decimalsBase = _getDecimalsSafe(params.priceFeedBase);
        uint8 decimalsQuote = _getDecimalsSafe(params.priceFeedQuote);
        if (
            (fundingInfo.prevIndexPriceBase == indexPriceBase && fundingInfo.prevIndexPriceQuote == indexPriceQuote) ||
            indexPriceBase == 0 ||
            indexPriceQuote == 0 ||
            decimalsBase > MAX_DECIMALS ||
            decimalsQuote > MAX_DECIMALS
        ) {
            return (0, 0, 0);
        }

        elapsedSec256 = Math.min(elapsedSec256, params.maxElapsedSec);
        elapsedSec = elapsedSec256.toUint32();

        premiumX96 = _calcPremiumX96(decimalsBase, decimalsQuote, indexPriceBase, indexPriceQuote, params.markPriceX96);

        int256 maxPremiumX96 = FixedPoint96.Q96.mulRatio(params.maxPremiumRatio).toInt256();
        premiumX96 = (-maxPremiumX96).max(maxPremiumX96.min(premiumX96));
        fundingRateX96 = premiumX96.mulDiv(elapsedSec256.toInt256(), params.rolloverSec);

        fundingInfo.prevIndexPriceBase = indexPriceBase;
        fundingInfo.prevIndexPriceQuote = indexPriceQuote;
        fundingInfo.prevIndexPriceTimestamp = currentTimestamp;
    }

    function validateInitialLiquidityPrice(
        address priceFeedBase,
        address priceFeedQuote,
        uint256 base,
        uint256 quote
    ) internal view {
        uint256 indexPriceBase = _getIndexPriceSafe(priceFeedBase);
        uint256 indexPriceQuote = _getIndexPriceSafe(priceFeedQuote);
        require(indexPriceBase > 0, "FL_VILP: invalid base price");
        require(indexPriceQuote > 0, "FL_VILP: invalid quote price");
        uint8 decimalsBase = _getDecimalsSafe(priceFeedBase);
        uint8 decimalsQuote = _getDecimalsSafe(priceFeedQuote);
        require(decimalsBase <= MAX_DECIMALS, "FL_VILP: invalid base decimals");
        require(decimalsQuote <= MAX_DECIMALS, "FL_VILP: invalid quote decimals");

        uint256 markPriceX96 = Math.mulDiv(quote, FixedPoint96.Q96, base);
        int256 premiumX96 = _calcPremiumX96(decimalsBase, decimalsQuote, indexPriceBase, indexPriceQuote, markPriceX96);

        require(premiumX96.abs() <= FixedPoint96.Q96.mulRatio(1e5), "FL_VILP: too far from index");
    }

    function _getIndexPriceSafe(address priceFeed) private view returns (uint256) {
        if (priceFeed == address(0)) return 1; // indicate valid

        bytes memory payload = abi.encodeWithSignature("getPrice()");
        (bool success, bytes memory data) = address(priceFeed).staticcall(payload);
        if (!success) return 0; // invalid

        return abi.decode(data, (uint256));
    }

    function _getDecimalsSafe(address priceFeed) private view returns (uint8) {
        if (priceFeed == address(0)) return 0; // indicate valid

        bytes memory payload = abi.encodeWithSignature("decimals()");
        (bool success, bytes memory data) = address(priceFeed).staticcall(payload);
        if (!success) return 255; // invalid

        return abi.decode(data, (uint8));
    }

    // TODO: must not revert
    function _calcPremiumX96(
        uint8 decimalsBase,
        uint8 decimalsQuote,
        uint256 indexPriceBase,
        uint256 indexPriceQuote,
        uint256 markPriceX96
    ) private pure returns (int256 premiumX96) {
        uint256 priceRatioX96 = markPriceX96;

        if (decimalsBase != 0 || indexPriceBase != 1) {
            priceRatioX96 = Math.mulDiv(priceRatioX96, 10**decimalsBase, indexPriceBase);
        }
        if (decimalsQuote != 0 || indexPriceQuote != 1) {
            priceRatioX96 = Math.mulDiv(priceRatioX96, indexPriceQuote, 10**decimalsQuote);
        }

        premiumX96 = priceRatioX96.toInt256().sub(FixedPoint96.Q96.toInt256());
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { MarketStructs } from "./MarketStructs.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

library PoolLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct SwapParams {
        bool isBaseToQuote;
        bool isExactInput;
        uint24 feeRatio;
        uint256 amount;
    }

    struct AddLiquidityParams {
        uint256 base;
        uint256 quote;
    }

    struct RemoveLiquidityParams {
        uint256 liquidity;
    }

    uint256 public constant MINIMUM_LIQUIDITY = 1e3;

    function initializePool(MarketStructs.PoolInfo storage poolInfo) internal {
        poolInfo.baseBalancePerShareX96 = FixedPoint96.Q96;
    }

    // underestimate deleveraged tokens
    function applyFunding(MarketStructs.PoolInfo storage poolInfo, int256 fundingRateX96) internal {
        if (fundingRateX96 == 0) return;

        uint256 frAbs = fundingRateX96.abs();

        if (fundingRateX96 > 0) {
            uint256 poolQuote = poolInfo.quote;
            uint256 deleveratedQuote = Math.mulDiv(poolQuote, frAbs, FixedPoint96.Q96);
            poolInfo.quote = poolQuote.sub(deleveratedQuote);
            poolInfo.cumQuotePerLiquidityX96 = poolInfo.cumQuotePerLiquidityX96.add(
                Math.mulDiv(deleveratedQuote, FixedPoint96.Q96, poolInfo.totalLiquidity)
            );
        } else {
            uint256 poolBase = poolInfo.base;
            uint256 deleveratedBase = Math.mulDiv(poolBase, frAbs, FixedPoint96.Q96.add(frAbs));
            poolInfo.base = poolBase.sub(deleveratedBase);
            poolInfo.cumBasePerLiquidityX96 = poolInfo.cumBasePerLiquidityX96.add(
                Math.mulDiv(deleveratedBase, FixedPoint96.Q96, poolInfo.totalLiquidity)
            );
        }

        poolInfo.baseBalancePerShareX96 = Math.mulDiv(
            poolInfo.baseBalancePerShareX96,
            FixedPoint96.Q96.toInt256().sub(fundingRateX96).toUint256(),
            FixedPoint96.Q96
        );
    }

    function swap(MarketStructs.PoolInfo storage poolInfo, SwapParams memory params)
        internal
        returns (uint256 oppositeAmount)
    {
        oppositeAmount = previewSwap(poolInfo.base, poolInfo.quote, params);
        (poolInfo.base, poolInfo.quote) = calcPoolAfter(
            params.isBaseToQuote,
            params.isExactInput,
            poolInfo.base,
            poolInfo.quote,
            params.amount,
            oppositeAmount
        );
    }

    function calcPoolAfter(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 base,
        uint256 quote,
        uint256 amount,
        uint256 oppositeAmount
    ) internal pure returns (uint256 baseAfter, uint256 quoteAfter) {
        if (isExactInput) {
            if (isBaseToQuote) {
                baseAfter = base.add(amount);
                quoteAfter = quote.sub(oppositeAmount);
            } else {
                baseAfter = base.sub(oppositeAmount);
                quoteAfter = quote.add(amount);
            }
        } else {
            if (isBaseToQuote) {
                baseAfter = base.add(oppositeAmount);
                quoteAfter = quote.sub(amount);
            } else {
                baseAfter = base.sub(amount);
                quoteAfter = quote.add(oppositeAmount);
            }
        }
    }

    function addLiquidity(MarketStructs.PoolInfo storage poolInfo, AddLiquidityParams memory params)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 poolTotalLiquidity = poolInfo.totalLiquidity;
        uint256 liquidity;

        if (poolTotalLiquidity == 0) {
            uint256 totalLiquidity = Math.sqrt(params.base.mul(params.quote));
            liquidity = totalLiquidity.sub(MINIMUM_LIQUIDITY);
            require(params.base > 0 && params.quote > 0 && liquidity > 0, "PL_AL: initial liquidity zero");

            poolInfo.base = params.base;
            poolInfo.quote = params.quote;
            poolInfo.totalLiquidity = totalLiquidity;
            return (params.base, params.quote, liquidity);
        }

        uint256 poolBase = poolInfo.base;
        uint256 poolQuote = poolInfo.quote;

        uint256 base = Math.min(params.base, Math.mulDiv(params.quote, poolBase, poolQuote));
        uint256 quote = Math.min(params.quote, Math.mulDiv(params.base, poolQuote, poolBase));
        liquidity = Math.min(
            Math.mulDiv(base, poolTotalLiquidity, poolBase),
            Math.mulDiv(quote, poolTotalLiquidity, poolQuote)
        );
        require(base > 0 && quote > 0 && liquidity > 0, "PL_AL: liquidity zero");

        poolInfo.base = poolBase.add(base);
        poolInfo.quote = poolQuote.add(quote);
        poolInfo.totalLiquidity = poolTotalLiquidity.add(liquidity);

        return (base, quote, liquidity);
    }

    function removeLiquidity(MarketStructs.PoolInfo storage poolInfo, RemoveLiquidityParams memory params)
        internal
        returns (uint256, uint256)
    {
        uint256 poolBase = poolInfo.base;
        uint256 poolQuote = poolInfo.quote;
        uint256 poolTotalLiquidity = poolInfo.totalLiquidity;
        uint256 base = Math.mulDiv(params.liquidity, poolBase, poolTotalLiquidity);
        uint256 quote = Math.mulDiv(params.liquidity, poolQuote, poolTotalLiquidity);
        require(base > 0 && quote > 0, "PL_RL: output is zero");
        poolInfo.base = poolBase.sub(base);
        poolInfo.quote = poolQuote.sub(quote);
        uint256 totalLiquidity = poolTotalLiquidity.sub(params.liquidity);
        require(totalLiquidity >= MINIMUM_LIQUIDITY, "PL_RL: min liquidity");
        poolInfo.totalLiquidity = totalLiquidity;
        return (base, quote);
    }

    function getLiquidityValue(MarketStructs.PoolInfo storage poolInfo, uint256 liquidity)
        internal
        view
        returns (uint256, uint256)
    {
        return (
            Math.mulDiv(liquidity, poolInfo.base, poolInfo.totalLiquidity),
            Math.mulDiv(liquidity, poolInfo.quote, poolInfo.totalLiquidity)
        );
    }

    // subtract fee from input before swap
    function previewSwap(
        uint256 base,
        uint256 quote,
        SwapParams memory params
    ) internal pure returns (uint256 output) {
        uint24 oneSubFeeRatio = PerpMath.subRatio(1e6, params.feeRatio);

        if (params.isExactInput) {
            uint256 amountSubFee = params.amount.mulRatio(oneSubFeeRatio);
            if (params.isBaseToQuote) {
                // output = quote.sub(FullMath.mulDivRoundingUp(base, quote, base.add(amountSubFee)));
                output = Math.mulDiv(quote, amountSubFee, base.add(amountSubFee));
            } else {
                // output = base.sub(FullMath.mulDivRoundingUp(base, quote, quote.add(amountSubFee)));
                output = Math.mulDiv(base, amountSubFee, quote.add(amountSubFee));
            }
        } else {
            if (params.isBaseToQuote) {
                // output = FullMath.mulDivRoundingUp(base, quote, quote.sub(params.amount)).sub(base);
                output = Math.mulDiv(base, params.amount, quote.sub(params.amount), Math.Rounding.Up);
            } else {
                // output = FullMath.mulDivRoundingUp(base, quote, base.sub(params.amount)).sub(quote);
                output = Math.mulDiv(quote, params.amount, base.sub(params.amount), Math.Rounding.Up);
            }
            output = output.divRatioRoundingUp(oneSubFeeRatio);
        }
    }

    function _solveQuadratic(uint256 b, uint256 cNeg) private pure returns (uint256) {
        return Math.sqrt(b.mul(b).add(cNeg.mul(4))).sub(b).div(2);
    }

    function getAskPriceX96(uint256 priceX96, uint24 feeRatio) internal pure returns (uint256) {
        uint24 oneSubFeeRatio = PerpMath.subRatio(1e6, feeRatio);
        return priceX96.divRatio(oneSubFeeRatio);
    }

    function getBidPriceX96(uint256 priceX96, uint24 feeRatio) internal pure returns (uint256) {
        uint24 oneSubFeeRatio = PerpMath.subRatio(1e6, feeRatio);
        return priceX96.mulRatioRoundingUp(oneSubFeeRatio);
    }

    // must not revert
    // Trade until the trade price including fee (dy/dx) reaches priceBoundX96
    // not pool price (y/x)
    // long: trade_price = pool_price / (1 - fee)
    // short: trade_price = pool_price * (1 - fee)
    function maxSwap(
        uint256 base,
        uint256 quote,
        bool isBaseToQuote,
        bool isExactInput,
        uint24 feeRatio,
        uint256 priceBoundX96
    ) internal pure returns (uint256 output) {
        uint24 oneSubFeeRatio = PerpMath.subRatio(1e6, feeRatio);
        uint256 k = base.mul(quote);

        if (isBaseToQuote) {
            uint256 kDivP = Math.mulDiv(k, FixedPoint96.Q96, priceBoundX96).mulRatio(oneSubFeeRatio);
            uint256 baseSqr = base.mul(base);
            if (kDivP <= baseSqr) return 0;
            uint256 cNeg = kDivP.sub(baseSqr);
            uint256 b = base.add(base.mulRatio(oneSubFeeRatio));
            output = _solveQuadratic(b.divRatio(oneSubFeeRatio), cNeg.divRatio(oneSubFeeRatio));
        } else {
            // https://www.wolframalpha.com/input?i=%28x+%2B+a%29+*+%28x+%2B+a+*+%281+-+f%29%29+%3D+kp+solve+a
            uint256 kp = Math.mulDiv(k, priceBoundX96, FixedPoint96.Q96).mulRatio(oneSubFeeRatio);
            uint256 quoteSqr = quote.mul(quote);
            if (kp <= quoteSqr) return 0;
            uint256 cNeg = kp.sub(quoteSqr);
            uint256 b = quote.add(quote.mulRatio(oneSubFeeRatio));
            output = _solveQuadratic(b.divRatio(oneSubFeeRatio), cNeg.divRatio(oneSubFeeRatio));
        }
        if (!isExactInput) {
            output = previewSwap(
                base,
                quote,
                SwapParams({ isBaseToQuote: isBaseToQuote, isExactInput: true, feeRatio: feeRatio, amount: output })
            );
        }
    }

    function getMarkPriceX96(
        uint256 base,
        uint256 quote,
        uint256 baseBalancePerShareX96
    ) internal pure returns (uint256) {
        return Math.mulDiv(getShareMarkPriceX96(base, quote), FixedPoint96.Q96, baseBalancePerShareX96);
    }

    function getShareMarkPriceX96(uint256 base, uint256 quote) internal pure returns (uint256) {
        return Math.mulDiv(quote, FixedPoint96.Q96, base);
    }

    function getLiquidityDeleveraged(
        uint256 poolCumBasePerLiquidityX96,
        uint256 poolCumQuotePerLiquidityX96,
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) internal pure returns (int256, int256) {
        int256 basePerLiquidityX96 = poolCumBasePerLiquidityX96.toInt256().sub(cumBasePerLiquidityX96.toInt256());
        int256 quotePerLiquidityX96 = poolCumQuotePerLiquidityX96.toInt256().sub(cumQuotePerLiquidityX96.toInt256());

        return (
            liquidity.toInt256().mulDiv(basePerLiquidityX96, FixedPoint96.Q96),
            liquidity.toInt256().mulDiv(quotePerLiquidityX96, FixedPoint96.Q96)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { MarketStructs } from "./MarketStructs.sol";

library PriceLimitLibrary {
    using PerpMath for uint256;
    using SafeMath for uint256;

    function update(MarketStructs.PriceLimitInfo storage priceLimitInfo, MarketStructs.PriceLimitInfo memory value)
        internal
    {
        if (value.referenceTimestamp == 0) return;
        priceLimitInfo.referencePrice = value.referencePrice;
        priceLimitInfo.referenceTimestamp = value.referenceTimestamp;
        priceLimitInfo.emaPrice = value.emaPrice;
    }

    // referenceTimestamp == 0 indicates not updated
    function updateDry(
        MarketStructs.PriceLimitInfo storage priceLimitInfo,
        MarketStructs.PriceLimitConfig storage config,
        uint256 price
    ) internal view returns (MarketStructs.PriceLimitInfo memory updated) {
        uint256 currentTimestamp = block.timestamp;
        uint256 refTimestamp = priceLimitInfo.referenceTimestamp;
        if (currentTimestamp <= refTimestamp) {
            updated.referencePrice = priceLimitInfo.referencePrice;
            updated.emaPrice = priceLimitInfo.emaPrice;
            return updated;
        }

        uint256 elapsed = currentTimestamp.sub(refTimestamp);

        if (priceLimitInfo.referencePrice == 0) {
            updated.emaPrice = price;
        } else {
            uint32 emaSec = config.emaSec;
            uint256 denominator = elapsed.add(emaSec);
            updated.emaPrice = Math.mulDiv(priceLimitInfo.emaPrice, emaSec, denominator).add(
                Math.mulDiv(price, elapsed, denominator)
            );
        }

        updated.referencePrice = price;
        updated.referenceTimestamp = currentTimestamp;
    }

    function priceBound(
        uint256 referencePrice,
        uint256 emaPrice,
        MarketStructs.PriceLimitConfig storage config,
        bool isLiquidation,
        bool isUpperBound
    ) internal view returns (uint256 price) {
        uint256 referenceRange =
            referencePrice.mulRatio(isLiquidation ? config.liquidationRatio : config.normalOrderRatio);
        uint256 emaRange = emaPrice.mulRatio(isLiquidation ? config.emaLiquidationRatio : config.emaNormalOrderRatio);

        if (isUpperBound) {
            return Math.min(referencePrice.add(referenceRange), emaPrice.add(emaRange));
        } else {
            return Math.max(referencePrice.sub(referenceRange), emaPrice.sub(emaRange));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { MarketStructs } from "./MarketStructs.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import {
    BokkyPooBahsRedBlackTreeLibrary as RBTreeLibrary
} from "../../deps/BokkyPooBahsRedBlackTreeLibrary/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

library OrderBookLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using RBTreeLibrary for RBTreeLibrary.Tree;

    struct SwapResponse {
        uint256 oppositeAmount;
        uint256 basePartial;
        uint256 quotePartial;
        uint40 partialKey;
        uint40 fullLastKey;
    }

    // to avoid stack too deep
    struct PreviewSwapParams {
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 baseBalancePerShareX96;
    }

    // to avoid stack too deep
    struct PreviewSwapLocalVars {
        uint128 priceX96;
        uint256 sharePriceX96;
        uint256 amountPool;
        uint40 left;
        uint40 right;
        uint256 leftBaseSum;
        uint256 leftQuoteSum;
        uint256 rightBaseSum;
        uint256 rightQuoteSum;
    }

    struct PreviewSwapResponse {
        uint256 amountPool;
        uint256 baseFull;
        uint256 quoteFull;
        uint256 basePartial;
        uint256 quotePartial;
        uint40 fullLastKey;
        uint40 partialKey;
    }

    function createOrder(
        MarketStructs.OrderBookInfo storage orderBookInfo,
        bool isBid,
        uint256 base,
        uint256 priceX96
    ) public returns (uint40) {
        require(base > 0, "OBL_CO: base is zero");
        require(priceX96 > 0, "OBL_CO: price is zero");
        MarketStructs.OrderBookSideInfo storage info = isBid ? orderBookInfo.bid : orderBookInfo.ask;
        uint40 key = info.seqKey + 1;
        info.seqKey = key;
        info.orderInfos[key].base = base; // before insert for aggregation
        uint128 userData = _makeUserData(priceX96);
        uint256 slot = _getSlot(orderBookInfo);
        if (isBid) {
            info.tree.insert(key, userData, _lessThanBid, _aggregateBid, slot);
        } else {
            info.tree.insert(key, userData, _lessThanAsk, _aggregateAsk, slot);
        }
        return key;
    }

    function cancelOrder(
        MarketStructs.OrderBookInfo storage orderBookInfo,
        bool isBid,
        uint40 key
    ) public {
        MarketStructs.OrderBookSideInfo storage info = isBid ? orderBookInfo.bid : orderBookInfo.ask;
        require(_isFullyExecuted(info, key) == 0, "OBL_CO: already fully executed");
        uint256 slot = _getSlot(orderBookInfo);
        if (isBid) {
            info.tree.remove(key, _aggregateBid, slot);
        } else {
            info.tree.remove(key, _aggregateAsk, slot);
        }
        delete info.orderInfos[key];
    }

    function getOrderInfo(
        MarketStructs.OrderBookInfo storage orderBookInfo,
        bool isBid,
        uint40 key
    ) public view returns (uint256 base, uint256 priceX96) {
        MarketStructs.OrderBookSideInfo storage info = isBid ? orderBookInfo.bid : orderBookInfo.ask;
        base = info.orderInfos[key].base;
        priceX96 = _userDataToPriceX96(info.tree.nodes[key].userData);
    }

    function getOrderExecution(
        MarketStructs.OrderBookInfo storage orderBookInfo,
        bool isBid,
        uint40 key
    )
        public
        view
        returns (
            uint48 executionId,
            uint256 executedBase,
            uint256 executedQuote
        )
    {
        MarketStructs.OrderBookSideInfo storage info = isBid ? orderBookInfo.bid : orderBookInfo.ask;
        executionId = _isFullyExecuted(info, key);
        if (executionId == 0) return (0, 0, 0);

        executedBase = info.orderInfos[key].base;
        // rounding error occurs, but it is negligible.

        executedQuote = _quoteToBalance(
            _getQuote(info, key),
            orderBookInfo.executionInfos[executionId].baseBalancePerShareX96
        );
    }

    function getBestPriceX96(MarketStructs.OrderBookSideInfo storage info) external view returns (uint256) {
        if (info.tree.root == 0) return 0;
        uint40 key = info.tree.first();
        return _userDataToPriceX96(info.tree.nodes[key].userData);
    }

    function swap(
        MarketStructs.OrderBookInfo storage orderBookInfo,
        PreviewSwapParams memory params,
        function(bool, bool, uint256) view returns (uint256) maxSwapArg,
        function(bool, bool, uint256) returns (uint256) swapArg
    ) internal returns (SwapResponse memory swapResponse) {
        MarketStructs.OrderBookSideInfo storage info = params.isBaseToQuote ? orderBookInfo.bid : orderBookInfo.ask;
        PreviewSwapResponse memory response = previewSwap(info, params, maxSwapArg);

        if (response.amountPool > 0) {
            swapResponse.oppositeAmount += swapArg(params.isBaseToQuote, params.isExactInput, response.amountPool);
        }

        bool isBase = params.isBaseToQuote == params.isExactInput;
        uint256 slot = _getSlot(orderBookInfo);

        if (response.fullLastKey != 0) {
            orderBookInfo.seqExecutionId += 1;
            orderBookInfo.executionInfos[orderBookInfo.seqExecutionId] = MarketStructs.ExecutionInfo({
                baseBalancePerShareX96: params.baseBalancePerShareX96
            });
            if (params.isBaseToQuote) {
                info.tree.removeLeft(response.fullLastKey, _lessThanBid, _aggregateBid, _subtreeRemovedBid, slot);
            } else {
                info.tree.removeLeft(response.fullLastKey, _lessThanAsk, _aggregateAsk, _subtreeRemovedAsk, slot);
            }

            swapResponse.oppositeAmount += isBase ? response.quoteFull : response.baseFull;
            swapResponse.fullLastKey = response.fullLastKey;
        } else {
            require(response.baseFull == 0, "never occur");
            require(response.quoteFull == 0, "never occur");
        }

        if (response.partialKey != 0) {
            info.orderInfos[response.partialKey].base -= response.basePartial;
            require(info.orderInfos[response.partialKey].base > 0, "never occur");

            info.tree.aggregateRecursively(
                response.partialKey,
                params.isBaseToQuote ? _aggregateBid : _aggregateAsk,
                slot
            );

            swapResponse.oppositeAmount += isBase ? response.quotePartial : response.basePartial;
            swapResponse.basePartial = response.basePartial;
            swapResponse.quotePartial = response.quotePartial;
            swapResponse.partialKey = response.partialKey;
        } else {
            require(response.basePartial == 0, "never occur");
            require(response.quotePartial == 0, "never occur");
        }
    }

    function previewSwap(
        MarketStructs.OrderBookSideInfo storage info,
        PreviewSwapParams memory params,
        function(bool, bool, uint256) view returns (uint256) maxSwapArg
    ) internal view returns (PreviewSwapResponse memory response) {
        bool isBase = params.isBaseToQuote == params.isExactInput;
        uint40 key = info.tree.root;
        uint256 baseSum;
        uint256 quoteSum;

        while (key != 0) {
            PreviewSwapLocalVars memory vars;
            vars.priceX96 = _userDataToPriceX96(info.tree.nodes[key].userData);
            vars.sharePriceX96 = Math.mulDiv(vars.priceX96, params.baseBalancePerShareX96, FixedPoint96.Q96);
            vars.amountPool = maxSwapArg(params.isBaseToQuote, params.isExactInput, vars.sharePriceX96);

            // key - right is more gas efficient than left + key
            vars.left = info.tree.nodes[key].left;
            vars.right = info.tree.nodes[key].right;
            vars.leftBaseSum = baseSum + info.orderInfos[vars.left].baseSum;
            vars.leftQuoteSum = quoteSum + info.orderInfos[vars.left].quoteSum;

            uint256 rangeLeft =
                (isBase ? vars.leftBaseSum : _quoteToBalance(vars.leftQuoteSum, params.baseBalancePerShareX96)) +
                    vars.amountPool;
            if (params.amount <= rangeLeft) {
                if (vars.left == 0) {
                    response.fullLastKey = info.tree.prev(key);
                }
                key = vars.left;
                continue;
            }

            vars.rightBaseSum = baseSum + (info.orderInfos[key].baseSum - info.orderInfos[vars.right].baseSum);
            vars.rightQuoteSum = quoteSum + (info.orderInfos[key].quoteSum - info.orderInfos[vars.right].quoteSum);

            uint256 rangeRight =
                (isBase ? vars.rightBaseSum : _quoteToBalance(vars.rightQuoteSum, params.baseBalancePerShareX96)) +
                    vars.amountPool;
            if (params.amount < rangeRight) {
                response.amountPool = vars.amountPool;
                response.baseFull = vars.leftBaseSum;
                response.quoteFull = _quoteToBalance(vars.leftQuoteSum, params.baseBalancePerShareX96);
                if (isBase) {
                    response.basePartial = params.amount - rangeLeft; // < info.orderInfos[key].base
                    response.quotePartial = Math.mulDiv(response.basePartial, vars.sharePriceX96, FixedPoint96.Q96);
                } else {
                    response.quotePartial = params.amount - rangeLeft;
                    response.basePartial = Math.mulDiv(response.quotePartial, FixedPoint96.Q96, vars.sharePriceX96);
                    // round to fit order size
                    response.basePartial = Math.min(response.basePartial, info.orderInfos[key].base - 1);
                }
                response.fullLastKey = info.tree.prev(key);
                response.partialKey = key;
                return response;
            }

            {
                baseSum = vars.rightBaseSum;
                quoteSum = vars.rightQuoteSum;
                if (vars.right == 0) {
                    response.fullLastKey = key;
                }
                key = vars.right;
            }
        }

        response.baseFull = baseSum;
        response.quoteFull = _quoteToBalance(quoteSum, params.baseBalancePerShareX96);
        response.amountPool = params.amount - (isBase ? response.baseFull : response.quoteFull);
    }

    function maxSwap(
        MarketStructs.OrderBookSideInfo storage info,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 sharePriceBoundX96,
        uint256 baseBalancePerShareX96
    ) public view returns (uint256 amount) {
        uint256 priceBoundX96 = Math.mulDiv(sharePriceBoundX96, FixedPoint96.Q96, baseBalancePerShareX96);
        bool isBid = isBaseToQuote;
        bool isBase = isBaseToQuote == isExactInput;
        uint40 key = info.tree.root;

        while (key != 0) {
            uint128 price = _userDataToPriceX96(info.tree.nodes[key].userData);
            uint40 left = info.tree.nodes[key].left;
            if (isBid ? price >= priceBoundX96 : price <= priceBoundX96) {
                // key - right is more gas efficient than left + key
                uint40 right = info.tree.nodes[key].right;
                amount += isBase
                    ? info.orderInfos[key].baseSum - info.orderInfos[right].baseSum
                    : info.orderInfos[key].quoteSum - info.orderInfos[right].quoteSum;
                key = right;
            } else {
                key = left;
            }
        }

        if (!isBase) {
            amount = _quoteToBalance(amount, baseBalancePerShareX96);
        }
    }

    function _isFullyExecuted(MarketStructs.OrderBookSideInfo storage info, uint40 key) private view returns (uint48) {
        uint40 root = info.tree.root;
        while (key != 0 && key != root) {
            if (info.orderInfos[key].executionId != 0) {
                return info.orderInfos[key].executionId;
            }
            key = info.tree.nodes[key].parent;
        }
        return 0;
    }

    function _makeUserData(uint256 priceX96) private pure returns (uint128) {
        return priceX96.toUint128();
    }

    function _userDataToPriceX96(uint128 userData) private pure returns (uint128) {
        return userData;
    }

    function _lessThan(
        RBTreeLibrary.Tree storage tree,
        bool isBid,
        uint40 key0,
        uint40 key1
    ) private view returns (bool) {
        uint128 price0 = _userDataToPriceX96(tree.nodes[key0].userData);
        uint128 price1 = _userDataToPriceX96(tree.nodes[key1].userData);
        if (price0 == price1) {
            return key0 < key1; // time priority
        }
        // price priority
        return isBid ? price0 > price1 : price0 < price1;
    }

    function _lessThanAsk(
        uint40 key0,
        uint40 key1,
        uint256 slot
    ) private view returns (bool) {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _lessThan(info.ask.tree, false, key0, key1);
    }

    function _lessThanBid(
        uint40 key0,
        uint40 key1,
        uint256 slot
    ) private view returns (bool) {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _lessThan(info.bid.tree, true, key0, key1);
    }

    function _aggregate(MarketStructs.OrderBookSideInfo storage info, uint40 key) private returns (bool stop) {
        uint256 prevBaseSum = info.orderInfos[key].baseSum;
        uint256 prevQuoteSum = info.orderInfos[key].quoteSum;
        uint40 left = info.tree.nodes[key].left;
        uint40 right = info.tree.nodes[key].right;

        uint256 baseSum = info.orderInfos[left].baseSum + info.orderInfos[right].baseSum + info.orderInfos[key].base;
        uint256 quoteSum = info.orderInfos[left].quoteSum + info.orderInfos[right].quoteSum + _getQuote(info, key);

        stop = baseSum == prevBaseSum && quoteSum == prevQuoteSum;
        if (!stop) {
            info.orderInfos[key].baseSum = baseSum;
            info.orderInfos[key].quoteSum = quoteSum;
        }
    }

    function _aggregateAsk(uint40 key, uint256 slot) private returns (bool stop) {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _aggregate(info.ask, key);
    }

    function _aggregateBid(uint40 key, uint256 slot) private returns (bool stop) {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _aggregate(info.bid, key);
    }

    function _subtreeRemoved(
        MarketStructs.OrderBookSideInfo storage info,
        MarketStructs.OrderBookInfo storage orderBookInfo,
        uint40 key
    ) private {
        info.orderInfos[key].executionId = orderBookInfo.seqExecutionId;
    }

    function _subtreeRemovedAsk(uint40 key, uint256 slot) private {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _subtreeRemoved(info.ask, info, key);
    }

    function _subtreeRemovedBid(uint40 key, uint256 slot) private {
        MarketStructs.OrderBookInfo storage info = _getOrderBookInfoFromSlot(slot);
        return _subtreeRemoved(info.bid, info, key);
    }

    // returns quoteBalance / baseBalancePerShare
    function _getQuote(MarketStructs.OrderBookSideInfo storage info, uint40 key) private view returns (uint256) {
        uint128 priceX96 = _userDataToPriceX96(info.tree.nodes[key].userData);
        return Math.mulDiv(info.orderInfos[key].base, priceX96, FixedPoint96.Q96);
    }

    function _quoteToBalance(uint256 quote, uint256 baseBalancePerShareX96) private pure returns (uint256) {
        return Math.mulDiv(quote, baseBalancePerShareX96, FixedPoint96.Q96);
    }

    function _getSlot(MarketStructs.OrderBookInfo storage d) private pure returns (uint256 slot) {
        assembly {
            slot := d.slot
        }
    }

    function _getOrderBookInfoFromSlot(uint256 slot) private pure returns (MarketStructs.OrderBookInfo storage d) {
        assembly {
            d.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { PerpMath } from "./PerpMath.sol";
import { MarketStructs } from "./MarketStructs.sol";

library PoolFeeLibrary {
    using PerpMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;

    function update(
        MarketStructs.PoolFeeInfo storage poolFeeInfo,
        uint32 atrEmaBlocks,
        uint256 prevPriceX96,
        uint256 currentPriceX96
    ) internal {
        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp <= poolFeeInfo.referenceTimestamp) {
            poolFeeInfo.currentHighX96 = Math.max(poolFeeInfo.currentHighX96, currentPriceX96);
            poolFeeInfo.currentLowX96 = Math.min(poolFeeInfo.currentLowX96, currentPriceX96);
        } else {
            poolFeeInfo.referenceTimestamp = currentTimestamp;
            poolFeeInfo.atrX96 = _calculateAtrX96(poolFeeInfo, atrEmaBlocks);
            poolFeeInfo.currentHighX96 = Math.max(prevPriceX96, currentPriceX96);
            poolFeeInfo.currentLowX96 = Math.min(prevPriceX96, currentPriceX96);
        }
    }

    function feeRatio(MarketStructs.PoolFeeInfo storage poolFeeInfo, MarketStructs.PoolFeeConfig memory config)
        internal
        view
        returns (uint256)
    {
        uint256 atrX96 = _calculateAtrX96(poolFeeInfo, config.atrEmaBlocks);
        return Math.mulDiv(config.atrFeeRatio, atrX96, FixedPoint96.Q96).add(config.fixedFeeRatio);
    }

    function _calculateAtrX96(MarketStructs.PoolFeeInfo storage poolFeeInfo, uint32 atrEmaBlocks)
        private
        view
        returns (uint256)
    {
        if (poolFeeInfo.currentLowX96 == 0) return 0;
        uint256 trX96 =
            Math.mulDiv(poolFeeInfo.currentHighX96, FixedPoint96.Q96, poolFeeInfo.currentLowX96).sub(FixedPoint96.Q96);
        uint256 denominator = atrEmaBlocks + 1;
        return Math.mulDiv(poolFeeInfo.atrX96, atrEmaBlocks, denominator).add(trX96.div(denominator));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IPerpdexMarketMinimum {
    struct SwapResponse {
        uint256 oppositeAmount;
        uint256 basePartial;
        uint256 quotePartial;
        uint40 partialOrderId;
    }

    function swap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external returns (SwapResponse memory response);

    function addLiquidity(uint256 baseShare, uint256 quoteBalance)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(uint256 liquidity) external returns (uint256 baseShare, uint256 quoteBalance);

    function createLimitOrder(
        bool isBid,
        uint256 baseShare,
        uint256 priceX96
    ) external returns (uint40 orderId);

    function cancelLimitOrder(bool isBid, uint40 orderId) external;

    // getters

    function previewSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external view returns (uint256);

    function maxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation
    ) external view returns (uint256 amount);

    function exchange() external view returns (address);

    function getShareMarkPriceX96() external view returns (uint256);

    function getLiquidityValue(uint256 liquidity) external view returns (uint256 baseShare, uint256 quoteBalance);

    function getLiquidityDeleveraged(
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) external view returns (int256, int256);

    function getCumDeleveragedPerLiquidityX96() external view returns (uint256, uint256);

    function baseBalancePerShareX96() external view returns (uint256);

    function getLimitOrderInfo(bool isBid, uint40 orderId) external view returns (uint256 base, uint256 priceX96);

    function getLimitOrderExecution(bool isBid, uint40 orderId)
        external
        view
        returns (
            uint48 executionId,
            uint256 executedBase,
            uint256 executedQuote
        );
}

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsRedBlackTreeLibrary {
    struct Node {
        uint40 parent;
        uint40 left;
        uint40 right;
        bool red;
        uint128 userData; // use freely. this is for gas efficiency
    }

    struct Tree {
        uint40 root;
        mapping(uint40 => Node) nodes;
    }

    uint40 private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint40 _key) {
        _key = self.root;
        if (_key != EMPTY) {
            _key = treeMinimum(self, self.root);
        }
    }

    function last(Tree storage self) internal view returns (uint40 _key) {
        _key = self.root;
        if (_key != EMPTY) {
            _key = treeMaximum(self, self.root);
        }
    }

    function next(Tree storage self, uint40 target)
        internal
        view
        returns (uint40 cursor)
    {
        require(target != EMPTY, "RBTL_N: target is empty");
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function prev(Tree storage self, uint40 target)
        internal
        view
        returns (uint40 cursor)
    {
        require(target != EMPTY, "RBTL_P: target is empty");
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function exists(Tree storage self, uint40 key)
        internal
        view
        returns (bool)
    {
        return
            (key != EMPTY) &&
            ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }

    function isEmpty(uint40 key) internal pure returns (bool) {
        return key == EMPTY;
    }

    function getEmpty() internal pure returns (uint256) {
        return EMPTY;
    }

    function getNode(Tree storage self, uint40 key)
        internal
        view
        returns (
            uint40 _returnKey,
            uint40 _parent,
            uint40 _left,
            uint40 _right,
            bool _red
        )
    {
        require(exists(self, key), "RBTL_GN: key not exist");
        return (
            key,
            self.nodes[key].parent,
            self.nodes[key].left,
            self.nodes[key].right,
            self.nodes[key].red
        );
    }

    function insert(
        Tree storage self,
        uint40 key,
        uint128 userData,
        function(uint40, uint40, uint256) view returns (bool) lessThan,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) internal {
        require(key != EMPTY, "RBTL_I: key is empty");
        require(!exists(self, key), "RBTL_I: key already exists");
        uint40 cursor = EMPTY;
        uint40 probe = self.root;
        self.nodes[key] = Node({
            parent: EMPTY,
            left: EMPTY,
            right: EMPTY,
            red: true,
            userData: userData
        });
        while (probe != EMPTY) {
            cursor = probe;
            if (lessThan(key, probe, data)) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key].parent = cursor;
        if (cursor == EMPTY) {
            self.root = key;
        } else if (lessThan(key, cursor, data)) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        aggregateRecursively(self, key, aggregate, data);
        insertFixup(self, key, aggregate, data);
    }

    function remove(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) internal {
        require(key != EMPTY, "RBTL_R: key is empty");
        require(exists(self, key), "RBTL_R: key not exist");
        uint40 probe;
        uint40 cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint40 yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
            aggregateRecursively(self, key, aggregate, data);
        }
        if (doFixup) {
            removeFixup(self, probe, aggregate, data);
        }
        aggregateRecursively(self, yParent, aggregate, data);

        // Fixed a bug that caused the parent of empty nodes to be non-zero.
        // TODO: Fix it the right way.
        if (probe == EMPTY) {
            self.nodes[probe].parent = EMPTY;
        }
    }

    // https://arxiv.org/pdf/1602.02120.pdf
    // changes from original
    // - handle empty
    // - handle parent
    // - change root to black

    // to avoid stack too deep
    struct JoinParams {
        uint40 left;
        uint40 key;
        uint40 right;
        uint8 leftBlackHeight;
        uint8 rightBlackHeight;
        uint256 data;
    }

    // destructive func
    function joinRight(
        Tree storage self,
        JoinParams memory params,
        function(uint40, uint256) returns (bool) aggregate
    ) private returns (uint40, uint8) {
        if (
            !self.nodes[params.left].red &&
            params.leftBlackHeight == params.rightBlackHeight
        ) {
            self.nodes[params.key].red = true;
            self.nodes[params.key].left = params.left;
            self.nodes[params.key].right = params.right;
            aggregate(params.key, params.data);
            return (params.key, params.leftBlackHeight);
        }

        (uint40 t, ) = joinRight(
            self,
            JoinParams({
                left: self.nodes[params.left].right,
                key: params.key,
                right: params.right,
                leftBlackHeight: params.leftBlackHeight -
                    (self.nodes[params.left].red ? 0 : 1),
                rightBlackHeight: params.rightBlackHeight,
                data: params.data
            }),
            aggregate
        );
        self.nodes[params.left].right = t;
        self.nodes[params.left].parent = EMPTY;
        aggregate(params.left, params.data);

        if (
            !self.nodes[params.left].red &&
            self.nodes[t].red &&
            self.nodes[self.nodes[t].right].red
        ) {
            self.nodes[self.nodes[t].right].red = false;
            rotateLeft(self, params.left, aggregate, params.data);
            return (t, params.leftBlackHeight);
            //            return (self.nodes[params.left].parent, tBlackHeight + 1); // TODO: replace with t
        }
        return (params.left, params.leftBlackHeight);
        //        return (params.left, tBlackHeight + (self.nodes[params.left].red ? 0 : 1));
    }

    // destructive func
    function joinLeft(
        Tree storage self,
        JoinParams memory params,
        function(uint40, uint256) returns (bool) aggregate
    ) internal returns (uint40 resultKey) {
        if (
            !self.nodes[params.right].red &&
            params.leftBlackHeight == params.rightBlackHeight
        ) {
            self.nodes[params.key].red = true;
            self.nodes[params.key].left = params.left;
            self.nodes[params.key].right = params.right;
            if (params.left != EMPTY) {
                self.nodes[params.left].parent = params.key;
            }
            if (params.right != EMPTY) {
                self.nodes[params.right].parent = params.key;
            }
            aggregate(params.key, params.data);
            return params.key;
        }

        uint40 t = joinLeft(
            self,
            JoinParams({
                left: params.left,
                key: params.key,
                right: self.nodes[params.right].left,
                leftBlackHeight: params.leftBlackHeight,
                rightBlackHeight: params.rightBlackHeight -
                    (self.nodes[params.right].red ? 0 : 1),
                data: params.data
            }),
            aggregate
        );
        self.nodes[params.right].left = t;
        self.nodes[params.right].parent = EMPTY;
        if (t != EMPTY) {
            self.nodes[t].parent = params.right;
        }
        aggregate(params.right, params.data);

        if (
            !self.nodes[params.right].red &&
            self.nodes[t].red &&
            self.nodes[self.nodes[t].left].red
        ) {
            self.nodes[self.nodes[t].left].red = false;
            rotateRight(self, params.right, aggregate, params.data);
            return t;
        }
        return params.right;
    }

    // destructive func
    function join(
        Tree storage self,
        uint40 left,
        uint40 key,
        uint40 right,
        function(uint40, uint256) returns (bool) aggregate,
        uint8 leftBlackHeight,
        uint8 rightBlackHeight,
        uint256 data
    ) private returns (uint40 t, uint8 tBlackHeight) {
        if (leftBlackHeight > rightBlackHeight) {
            (t, tBlackHeight) = joinRight(
                self,
                JoinParams({
                    left: left,
                    key: key,
                    right: right,
                    leftBlackHeight: leftBlackHeight,
                    rightBlackHeight: rightBlackHeight,
                    data: data
                }),
                aggregate
            );
            tBlackHeight = leftBlackHeight;
            if (self.nodes[t].red && self.nodes[self.nodes[t].right].red) {
                self.nodes[t].red = false;
                tBlackHeight += 1;
            }
        } else if (leftBlackHeight < rightBlackHeight) {
            t = joinLeft(
                self,
                JoinParams({
                    left: left,
                    key: key,
                    right: right,
                    leftBlackHeight: leftBlackHeight,
                    rightBlackHeight: rightBlackHeight,
                    data: data
                }),
                aggregate
            );
            tBlackHeight = rightBlackHeight;
            if (self.nodes[t].red && self.nodes[self.nodes[t].left].red) {
                self.nodes[t].red = false;
                tBlackHeight += 1;
            }
        } else {
            bool red = !self.nodes[left].red && !self.nodes[right].red;
            self.nodes[key].red = red;
            self.nodes[key].left = left;
            self.nodes[key].right = right;
            aggregate(key, data);
            (t, tBlackHeight) = (key, leftBlackHeight + (red ? 0 : 1));
        }
    }

    struct SplitParams {
        uint40 t;
        uint40 key;
        uint8 blackHeight;
        uint256 data;
    }

    // destructive func
    function splitRight(
        Tree storage self,
        SplitParams memory params,
        function(uint40, uint40, uint256) returns (bool) lessThan,
        function(uint40, uint256) returns (bool) aggregate,
        function(uint40, uint256) subtreeRemoved
    ) private returns (uint40 resultKey, uint8 resultBlackHeight) {
        if (params.t == EMPTY) return (EMPTY, params.blackHeight);
        params.blackHeight -= (self.nodes[params.t].red ? 0 : 1);
        if (params.key == params.t) {
            subtreeRemoved(params.t, params.data);
            return (self.nodes[params.t].right, params.blackHeight);
        }
        if (lessThan(params.key, params.t, params.data)) {
            (uint40 r, uint8 rBlackHeight) = splitRight(
                self,
                SplitParams({
                    t: self.nodes[params.t].left,
                    key: params.key,
                    blackHeight: params.blackHeight,
                    data: params.data
                }),
                lessThan,
                aggregate,
                subtreeRemoved
            );
            return
                join(
                    self,
                    r,
                    params.t,
                    self.nodes[params.t].right,
                    aggregate,
                    rBlackHeight,
                    params.blackHeight,
                    params.data
                );
        } else {
            subtreeRemoved(params.t, params.data);
            return
                splitRight(
                    self,
                    SplitParams({
                        t: self.nodes[params.t].right,
                        key: params.key,
                        blackHeight: params.blackHeight,
                        data: params.data
                    }),
                    lessThan,
                    aggregate,
                    subtreeRemoved
                );
        }
    }

    function removeLeft(
        Tree storage self,
        uint40 key,
        function(uint40, uint40, uint256) returns (bool) lessThan,
        function(uint40, uint256) returns (bool) aggregate,
        function(uint40, uint256) subtreeRemoved,
        uint256 data
    ) internal {
        require(key != EMPTY, "RBTL_RL: key is empty");
        require(exists(self, key), "RBTL_RL: key not exist");
        (self.root, ) = splitRight(
            self,
            SplitParams({t: self.root, key: key, blackHeight: 128, data: data}),
            lessThan,
            aggregate,
            subtreeRemoved
        );
        self.nodes[self.root].parent = EMPTY;
        self.nodes[self.root].red = false;
    }

    function aggregateRecursively(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) internal {
        while (key != EMPTY) {
            if (aggregate(key, data)) return;
            key = self.nodes[key].parent;
        }
    }

    function treeMinimum(Tree storage self, uint40 key)
        private
        view
        returns (uint40)
    {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }

    function treeMaximum(Tree storage self, uint40 key)
        private
        view
        returns (uint40)
    {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor = self.nodes[key].right;
        uint40 keyParent = self.nodes[key].parent;
        uint40 cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
        aggregate(key, data);
        aggregate(cursor, data);
    }

    function rotateRight(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor = self.nodes[key].left;
        uint40 keyParent = self.nodes[key].parent;
        uint40 cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
        aggregate(key, data);
        aggregate(cursor, data);
    }

    function insertFixup(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint40 keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                        key = keyParent;
                        rotateLeft(self, key, aggregate, data);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(
                        self,
                        self.nodes[keyParent].parent,
                        aggregate,
                        data
                    );
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                        key = keyParent;
                        rotateRight(self, key, aggregate, data);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(
                        self,
                        self.nodes[keyParent].parent,
                        aggregate,
                        data
                    );
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(
        Tree storage self,
        uint40 a,
        uint40 b
    ) private {
        uint40 bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }

    function removeFixup(
        Tree storage self,
        uint40 key,
        function(uint40, uint256) returns (bool) aggregate,
        uint256 data
    ) private {
        uint40 cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint40 keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent, aggregate, data);
                    cursor = self.nodes[keyParent].right;
                }
                if (
                    !self.nodes[self.nodes[cursor].left].red &&
                    !self.nodes[self.nodes[cursor].right].red
                ) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor, aggregate, data);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent, aggregate, data);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent, aggregate, data);
                    cursor = self.nodes[keyParent].left;
                }
                if (
                    !self.nodes[self.nodes[cursor].right].red &&
                    !self.nodes[self.nodes[cursor].left].red
                ) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor, aggregate, data);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent, aggregate, data);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

library PerpMath {
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return Math.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return Math.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return Math.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "PerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -SafeCast.toInt256(a);
    }

    function divBy10_18(int256 value) internal pure returns (int256) {
        // no overflow here
        return value / (1 ether);
    }

    function divBy10_18(uint256 value) internal pure returns (uint256) {
        // no overflow here
        return value / (1 ether);
    }

    function subRatio(uint24 a, uint24 b) internal pure returns (uint24) {
        require(b <= a, "PerpMath: subtraction overflow");
        return a - b;
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, ratio, 1e6);
    }

    function mulRatioRoundingUp(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, ratio, 1e6, Math.Rounding.Up);
    }

    function divRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, 1e6, ratio);
    }

    function divRatioRoundingUp(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return Math.mulDiv(value, 1e6, ratio, Math.Rounding.Up);
    }

    /// @param denominator cannot be 0 and is checked in Math.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = Math.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : SafeCast.toInt256(unsignedResult);

        return result;
    }

    function sign(int256 value) internal pure returns (int256) {
        return value > 0 ? int256(1) : (value < 0 ? int256(-1) : int256(0));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

interface IPerpdexPriceFeed {
    function decimals() external view returns (uint8);

    /// @dev Returns the index price of the token.
    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpdexMarket } from "../PerpdexMarket.sol";
import { MarketStructs } from "../lib/MarketStructs.sol";
import { PoolLibrary } from "../lib/PoolLibrary.sol";
import { PerpMath } from "../lib/PerpMath.sol";

contract TestPerpdexMarket is PerpdexMarket {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;

    constructor(
        string memory symbolArg,
        address exchangeArg,
        address priceFeedBaseArg,
        address priceFeedQuoteArg
    ) PerpdexMarket(msg.sender, symbolArg, exchangeArg, priceFeedBaseArg, priceFeedQuoteArg) {}

    function processFunding() external {
        _processFunding();
    }

    function setFundingInfo(MarketStructs.FundingInfo memory value) external {
        fundingInfo = value;
    }

    function setPoolInfo(MarketStructs.PoolInfo memory value) external {
        poolInfo = value;
    }

    function setPriceLimitInfo(MarketStructs.PriceLimitInfo memory value) external {
        priceLimitInfo = value;
    }

    function setPoolFeeInfo(MarketStructs.PoolFeeInfo memory value) external {
        poolFeeInfo = value;
    }

    function getLockedLiquidityInfo() external view returns (int256 base, int256 accountValue) {
        uint256 liquidity = PoolLibrary.MINIMUM_LIQUIDITY;

        if (poolInfo.totalLiquidity == 0) return (0, 0);

        (uint256 poolBase, uint256 poolQuote) = PoolLibrary.getLiquidityValue(poolInfo, liquidity);
        (int256 delBase, int256 delQuote) =
            PoolLibrary.getLiquidityDeleveraged(
                poolInfo.cumBasePerLiquidityX96,
                poolInfo.cumQuotePerLiquidityX96,
                liquidity,
                0,
                0
            );

        base = poolBase.toInt256().add(delBase);
        int256 quote = poolQuote.toInt256().add(delQuote);
        accountValue = quote.add(base.mulDiv(getShareMarkPriceX96().toInt256(), FixedPoint96.Q96));
    }

    // Calling this method breaks the integrity of the tree.
    // So after calling this, only some getters can be used.
    function markFullyExecuted(
        bool isBid,
        uint40 key,
        uint48 executionId,
        uint256 baseBalancePerShareX96
    ) external {
        if (executionId == 0) return;

        if (isBid) {
            _orderBookInfo.bid.orderInfos[key].executionId = executionId;
            _orderBookInfo.bid.tree.root = 0;
            _orderBookInfo.bid.tree.nodes[_orderBookInfo.bid.tree.nodes[key].left].parent = 0;
            _orderBookInfo.bid.tree.nodes[_orderBookInfo.bid.tree.nodes[key].right].parent = 0;
        } else {
            _orderBookInfo.ask.orderInfos[key].executionId = executionId;
            _orderBookInfo.ask.tree.root = 0;
            _orderBookInfo.ask.tree.nodes[_orderBookInfo.ask.tree.nodes[key].left].parent = 0;
            _orderBookInfo.ask.tree.nodes[_orderBookInfo.ask.tree.nodes[key].right].parent = 0;
        }
        _orderBookInfo.executionInfos[executionId].baseBalancePerShareX96 = baseBalancePerShareX96;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import { PerpMath } from "../lib/PerpMath.sol";

contract TestPerpMath {
    using PerpMath for uint160;
    using PerpMath for uint256;
    using PerpMath for int256;
    using PerpMath for uint24;

    function testFormatSqrtPriceX96ToPriceX96(uint160 value) external pure returns (uint256) {
        return value.formatSqrtPriceX96ToPriceX96();
    }

    function testFormatX10_18ToX96(uint256 value) external pure returns (uint256) {
        return value.formatX10_18ToX96();
    }

    function testFormatX96ToX10_18(uint256 value) external pure returns (uint256) {
        return value.formatX96ToX10_18();
    }

    function testMax(int256 a, int256 b) external pure returns (int256) {
        return PerpMath.max(a, b);
    }

    function testMin(int256 a, int256 b) external pure returns (int256) {
        return PerpMath.min(a, b);
    }

    function testAbs(int256 value) external pure returns (uint256) {
        return value.abs();
    }

    function testDivBy10_18(int256 value) external pure returns (int256) {
        return value.divBy10_18();
    }

    function testDivBy10_18(uint256 value) external pure returns (uint256) {
        return value.divBy10_18();
    }

    function testMulRatio(uint256 value, uint24 ratio) external pure returns (uint256) {
        return value.mulRatio(ratio);
    }

    function testSubRatio(uint24 value, uint24 ratio) external pure returns (uint256) {
        return value.subRatio(ratio);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { IPerpdexExchange } from "./interfaces/IPerpdexExchange.sol";
import { IPerpdexMarketMinimum } from "./interfaces/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./lib/PerpdexStructs.sol";
import { AccountLibrary } from "./lib/AccountLibrary.sol";
import { MakerLibrary } from "./lib/MakerLibrary.sol";
import { MakerOrderBookLibrary } from "./lib/MakerOrderBookLibrary.sol";
import { TakerLibrary } from "./lib/TakerLibrary.sol";
import { VaultLibrary } from "./lib/VaultLibrary.sol";
import { PerpMath } from "./lib/PerpMath.sol";

contract PerpdexExchange is IPerpdexExchange, ReentrancyGuard, Ownable, Multicall {
    using Address for address;
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for uint256;

    // states
    // trader
    mapping(address => PerpdexStructs.AccountInfo) public accountInfos;
    PerpdexStructs.InsuranceFundInfo public insuranceFundInfo;
    PerpdexStructs.ProtocolInfo public protocolInfo;
    // market, isBid, orderId, trader
    mapping(address => mapping(bool => mapping(uint40 => address))) public orderIdToTrader;

    // config
    address public immutable settlementToken;
    uint8 public constant quoteDecimals = 18;
    uint8 public maxMarketsPerAccount = 16;
    uint8 public maxOrdersPerAccount = 40;
    uint24 public imRatio = 10e4;
    uint24 public mmRatio = 5e4;
    uint24 public protocolFeeRatio = 0;
    PerpdexStructs.LiquidationRewardConfig public liquidationRewardConfig =
        PerpdexStructs.LiquidationRewardConfig({ rewardRatio: 20e4, smoothEmaTime: 100 });
    mapping(address => PerpdexStructs.MarketStatus) public marketStatuses;

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    modifier checkMarketOpen(address market) {
        _checkMarketOpen(market);
        _;
    }

    modifier checkMarketClosed(address market) {
        _checkMarketClosed(market);
        _;
    }

    constructor(
        address ownerArg,
        address settlementTokenArg,
        address[] memory initialMarkets
    ) {
        _transferOwnership(ownerArg);
        require(settlementTokenArg == address(0) || settlementTokenArg.isContract(), "PE_C: token address invalid");

        settlementToken = settlementTokenArg;

        for (uint256 i = 0; i < initialMarkets.length; ++i) {
            _setMarketStatus(initialMarkets[i], PerpdexStructs.MarketStatus.Open);
        }
    }

    function deposit(uint256 amount) external payable nonReentrant {
        address trader = _msgSender();
        _settleLimitOrders(trader);

        uint256 compensation = VaultLibrary.compensate(accountInfos[trader], insuranceFundInfo);
        if (compensation != 0) {
            emit CollateralCompensated(trader, compensation);
        }

        if (settlementToken == address(0)) {
            require(amount == 0, "PE_D: amount not zero");
            VaultLibrary.depositEth(accountInfos[trader], msg.value);
            emit Deposited(trader, msg.value);
        } else {
            require(msg.value == 0, "PE_D: msg.value not zero");
            VaultLibrary.deposit(
                accountInfos[trader],
                VaultLibrary.DepositParams({ settlementToken: settlementToken, amount: amount, from: trader })
            );
            emit Deposited(trader, amount);
        }
    }

    function withdraw(uint256 amount) external nonReentrant {
        address payable trader = payable(_msgSender());
        _settleLimitOrders(trader);

        VaultLibrary.withdraw(
            accountInfos[trader],
            VaultLibrary.WithdrawParams({
                settlementToken: settlementToken,
                amount: amount,
                to: trader,
                imRatio: imRatio
            })
        );
        emit Withdrawn(trader, amount);
    }

    function transferProtocolFee(uint256 amount) external onlyOwner nonReentrant {
        address trader = _msgSender();
        _settleLimitOrders(trader);
        VaultLibrary.transferProtocolFee(accountInfos[trader], protocolInfo, amount);
        emit ProtocolFeeTransferred(trader, amount);
    }

    function trade(TradeParams calldata params)
        external
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketOpen(params.market)
        returns (uint256 oppositeAmount)
    {
        _settleLimitOrders(params.trader);
        TakerLibrary.TradeResponse memory response = _doTrade(params);

        if (response.rawResponse.partialOrderId != 0) {
            address partialTrader =
                orderIdToTrader[params.market][params.isBaseToQuote][response.rawResponse.partialOrderId];
            int256 partialRealizedPnL =
                MakerOrderBookLibrary.processPartialExecution(
                    accountInfos[partialTrader],
                    params.market,
                    params.isBaseToQuote,
                    maxMarketsPerAccount,
                    response.rawResponse
                );

            emit PartiallyExecuted(
                partialTrader,
                params.market,
                params.isBaseToQuote,
                response.rawResponse.basePartial,
                response.rawResponse.quotePartial,
                partialRealizedPnL
            );
        }

        uint256 baseBalancePerShareX96 = IPerpdexMarketMinimum(params.market).baseBalancePerShareX96();
        uint256 shareMarkPriceAfterX96 = IPerpdexMarketMinimum(params.market).getShareMarkPriceX96();

        if (response.isLiquidation) {
            emit PositionLiquidated(
                params.trader,
                params.market,
                _msgSender(),
                response.base,
                response.quote,
                response.realizedPnl,
                response.protocolFee,
                baseBalancePerShareX96,
                shareMarkPriceAfterX96,
                response.liquidationPenalty,
                response.liquidationReward,
                response.insuranceFundReward
            );
        } else {
            emit PositionChanged(
                params.trader,
                params.market,
                response.base,
                response.quote,
                response.realizedPnl,
                response.protocolFee,
                baseBalancePerShareX96,
                shareMarkPriceAfterX96
            );
        }

        oppositeAmount = params.isExactInput == params.isBaseToQuote ? response.quote.abs() : response.base.abs();
    }

    function addLiquidity(AddLiquidityParams calldata params)
        external
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketOpen(params.market)
        returns (
            uint256 base,
            uint256 quote,
            uint256 liquidity
        )
    {
        address trader = _msgSender();
        _settleLimitOrders(trader);

        MakerLibrary.AddLiquidityResponse memory response =
            MakerLibrary.addLiquidity(
                accountInfos[trader],
                MakerLibrary.AddLiquidityParams({
                    market: params.market,
                    base: params.base,
                    quote: params.quote,
                    minBase: params.minBase,
                    minQuote: params.minQuote,
                    imRatio: imRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount
                })
            );

        PerpdexStructs.MakerInfo storage makerInfo = accountInfos[trader].makerInfos[params.market];
        emit LiquidityAdded(
            trader,
            params.market,
            response.base,
            response.quote,
            response.liquidity,
            makerInfo.cumBaseSharePerLiquidityX96,
            makerInfo.cumQuotePerLiquidityX96
        );

        return (response.base, response.quote, response.liquidity);
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketOpen(params.market)
        returns (uint256 base, uint256 quote)
    {
        _settleLimitOrders(params.trader);

        MakerLibrary.RemoveLiquidityResponse memory response =
            MakerLibrary.removeLiquidity(
                accountInfos[params.trader],
                MakerLibrary.RemoveLiquidityParams({
                    market: params.market,
                    liquidity: params.liquidity,
                    minBase: params.minBase,
                    minQuote: params.minQuote,
                    isSelf: params.trader == _msgSender(),
                    mmRatio: mmRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount
                })
            );

        emit LiquidityRemoved(
            params.trader,
            params.market,
            response.isLiquidation ? _msgSender() : address(0),
            response.base,
            response.quote,
            params.liquidity,
            response.takerBase,
            response.takerQuote,
            response.realizedPnl
        );

        return (response.base, response.quote);
    }

    function createLimitOrder(CreateLimitOrderParams calldata params)
        external
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketOpen(params.market)
        returns (uint40 orderId)
    {
        address trader = _msgSender();
        _settleLimitOrders(trader);

        orderId = MakerOrderBookLibrary.createLimitOrder(
            accountInfos[trader],
            MakerOrderBookLibrary.CreateLimitOrderParams({
                market: params.market,
                isBid: params.isBid,
                base: params.base,
                priceX96: params.priceX96,
                imRatio: imRatio,
                maxMarketsPerAccount: maxMarketsPerAccount,
                maxOrdersPerAccount: maxOrdersPerAccount
            })
        );
        orderIdToTrader[params.market][params.isBid][orderId] = trader;

        emit LimitOrderCreated(trader, params.market, params.isBid, params.base, params.priceX96, orderId);
    }

    function cancelLimitOrder(CancelLimitOrderParams calldata params)
        external
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketOpen(params.market)
    {
        address trader = orderIdToTrader[params.market][params.isBid][params.orderId];
        require(trader != address(0), "PE_CLO: order not exist");
        _settleLimitOrders(trader);

        bool isLiquidation =
            MakerOrderBookLibrary.cancelLimitOrder(
                accountInfos[trader],
                MakerOrderBookLibrary.CancelLimitOrderParams({
                    market: params.market,
                    isBid: params.isBid,
                    orderId: params.orderId,
                    isSelf: trader == _msgSender(),
                    mmRatio: mmRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount
                })
            );

        emit LimitOrderCanceled(
            trader,
            params.market,
            isLiquidation ? _msgSender() : address(0),
            params.isBid,
            params.orderId
        );
    }

    function closeMarket(address market) external nonReentrant checkMarketClosed(market) {
        address trader = _msgSender();
        _settleLimitOrders(trader);
        AccountLibrary.closeMarket(accountInfos[trader], market);
    }

    function _settleLimitOrders(address trader) internal {
        MakerOrderBookLibrary.settleLimitOrdersAll(accountInfos[trader], maxMarketsPerAccount);
    }

    function setMaxMarketsPerAccount(uint8 value) external onlyOwner nonReentrant {
        maxMarketsPerAccount = value;
        emit MaxMarketsPerAccountChanged(value);
    }

    function setMaxOrdersPerAccount(uint8 value) external onlyOwner nonReentrant {
        maxOrdersPerAccount = value;
        emit MaxOrdersPerAccountChanged(value);
    }

    function setImRatio(uint24 value) external onlyOwner nonReentrant {
        require(value < 1e6, "PE_SIR: too large");
        require(value >= mmRatio, "PE_SIR: smaller than mmRatio");
        imRatio = value;
        emit ImRatioChanged(value);
    }

    function setMmRatio(uint24 value) external onlyOwner nonReentrant {
        require(value <= imRatio, "PE_SMR: bigger than imRatio");
        require(value > 0, "PE_SMR: zero");
        mmRatio = value;
        emit MmRatioChanged(value);
    }

    function setLiquidationRewardConfig(PerpdexStructs.LiquidationRewardConfig calldata value)
        external
        onlyOwner
        nonReentrant
    {
        require(value.rewardRatio < 1e6, "PE_SLRC: too large reward ratio");
        require(value.smoothEmaTime > 0, "PE_SLRC: ema time is zero");
        liquidationRewardConfig = value;
        emit LiquidationRewardConfigChanged(value.rewardRatio, value.smoothEmaTime);
    }

    function setProtocolFeeRatio(uint24 value) external onlyOwner nonReentrant {
        require(value <= 1e4, "PE_SPFR: too large");
        protocolFeeRatio = value;
        emit ProtocolFeeRatioChanged(value);
    }

    function setMarketStatus(address market, PerpdexStructs.MarketStatus status) external onlyOwner nonReentrant {
        _setMarketStatus(market, status);
    }

    // all raw information can be retrieved through getters (including default getters)

    function getTakerInfo(address trader, address market) external view returns (PerpdexStructs.TakerInfo memory) {
        return accountInfos[trader].takerInfos[market];
    }

    function getMakerInfo(address trader, address market) external view returns (PerpdexStructs.MakerInfo memory) {
        return accountInfos[trader].makerInfos[market];
    }

    function getAccountMarkets(address trader) external view returns (address[] memory) {
        return accountInfos[trader].markets;
    }

    function getLimitOrderInfo(address trader, address market)
        external
        view
        returns (
            uint40 askRoot,
            uint40 bidRoot,
            uint256 totalBaseAsk,
            uint256 totalBaseBid
        )
    {
        PerpdexStructs.LimitOrderInfo storage info = accountInfos[trader].limitOrderInfos[market];
        return (info.ask.root, info.bid.root, info.totalBaseAsk, info.totalBaseBid);
    }

    function getLimitOrderIds(
        address trader,
        address market,
        bool isBid
    ) external view returns (uint40[] memory) {
        return MakerOrderBookLibrary.getLimitOrderIds(accountInfos[trader], market, isBid);
    }

    // dry run

    function previewTrade(PreviewTradeParams calldata params)
        external
        view
        checkMarketOpen(params.market)
        returns (uint256 oppositeAmount)
    {
        address trader = params.trader;
        address caller = params.caller;

        return
            TakerLibrary.previewTrade(
                accountInfos[trader],
                TakerLibrary.PreviewTradeParams({
                    market: params.market,
                    isBaseToQuote: params.isBaseToQuote,
                    isExactInput: params.isExactInput,
                    amount: params.amount,
                    oppositeAmountBound: params.oppositeAmountBound,
                    mmRatio: mmRatio,
                    protocolFeeRatio: protocolFeeRatio,
                    isSelf: trader == caller
                })
            );
    }

    function maxTrade(MaxTradeParams calldata params) external view returns (uint256 amount) {
        if (marketStatuses[params.market] != PerpdexStructs.MarketStatus.Open) return 0;

        address trader = params.trader;
        address caller = params.caller;

        return
            TakerLibrary.maxTrade({
                accountInfo: accountInfos[trader],
                market: params.market,
                isBaseToQuote: params.isBaseToQuote,
                isExactInput: params.isExactInput,
                mmRatio: mmRatio,
                protocolFeeRatio: protocolFeeRatio,
                isSelf: trader == caller
            });
    }

    // convenient getters

    function getTakerInfoLazy(address trader, address market) external view returns (PerpdexStructs.TakerInfo memory) {
        return AccountLibrary.getTakerInfo(accountInfos[trader], market);
    }

    function getCollateralBalance(address trader) external view returns (int256) {
        return AccountLibrary.getCollateralBalance(accountInfos[trader]);
    }

    function getTotalAccountValue(address trader) external view returns (int256) {
        return AccountLibrary.getTotalAccountValue(accountInfos[trader]);
    }

    function getPositionShare(address trader, address market) external view returns (int256) {
        return AccountLibrary.getPositionShare(accountInfos[trader], market);
    }

    function getPositionNotional(address trader, address market) external view returns (int256) {
        return AccountLibrary.getPositionNotional(accountInfos[trader], market);
    }

    function getTotalPositionNotional(address trader) external view returns (uint256) {
        return AccountLibrary.getTotalPositionNotional(accountInfos[trader]);
    }

    function getOpenPositionShare(address trader, address market) external view returns (uint256) {
        return AccountLibrary.getOpenPositionShare(accountInfos[trader], market);
    }

    function getOpenPositionNotional(address trader, address market) external view returns (uint256) {
        return AccountLibrary.getOpenPositionNotional(accountInfos[trader], market);
    }

    function getTotalOpenPositionNotional(address trader) external view returns (uint256) {
        return AccountLibrary.getTotalOpenPositionNotional(accountInfos[trader]);
    }

    function hasEnoughMaintenanceMargin(address trader) external view returns (bool) {
        return AccountLibrary.hasEnoughMaintenanceMargin(accountInfos[trader], mmRatio);
    }

    function hasEnoughInitialMargin(address trader) external view returns (bool) {
        return AccountLibrary.hasEnoughInitialMargin(accountInfos[trader], imRatio);
    }

    function isLiquidationFree(address trader) external view returns (bool) {
        return AccountLibrary.isLiquidationFree(accountInfos[trader]);
    }

    function getLimitOrderSummaries(
        address trader,
        address market,
        bool isBid
    ) external view returns (PerpdexStructs.LimitOrderSummary[] memory) {
        return MakerOrderBookLibrary.getLimitOrderSummaries(accountInfos[trader], market, isBid);
    }

    // for avoiding stack too deep error
    function _doTrade(TradeParams calldata params) private returns (TakerLibrary.TradeResponse memory) {
        return
            TakerLibrary.trade(
                accountInfos[params.trader],
                accountInfos[_msgSender()].vaultInfo,
                insuranceFundInfo,
                protocolInfo,
                TakerLibrary.TradeParams({
                    market: params.market,
                    isBaseToQuote: params.isBaseToQuote,
                    isExactInput: params.isExactInput,
                    amount: params.amount,
                    oppositeAmountBound: params.oppositeAmountBound,
                    mmRatio: mmRatio,
                    imRatio: imRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount,
                    protocolFeeRatio: protocolFeeRatio,
                    liquidationRewardConfig: liquidationRewardConfig,
                    isSelf: params.trader == _msgSender()
                })
            );
    }

    function _setMarketStatus(address market, PerpdexStructs.MarketStatus status) private {
        if (marketStatuses[market] == status) return;

        if (status == PerpdexStructs.MarketStatus.Open) {
            require(market.isContract(), "PE_SIMA: market address invalid");
            require(IPerpdexMarketMinimum(market).exchange() == address(this), "PE_SIMA: different exchange");
            require(marketStatuses[market] == PerpdexStructs.MarketStatus.NotAllowed, "PE_SIMA: market closed");
        } else if (status == PerpdexStructs.MarketStatus.Closed) {
            _checkMarketOpen(market);
        } else {
            require(false, "PE_SIMA: invalid status");
        }

        marketStatuses[market] = status;
        emit MarketStatusChanged(market, status);
    }

    // to reduce contract size
    function _checkDeadline(uint256 deadline) private view {
        require(block.timestamp <= deadline, "PE_CD: too late");
    }

    // to reduce contract size
    function _checkMarketOpen(address market) private view {
        require(marketStatuses[market] == PerpdexStructs.MarketStatus.Open, "PE_CMO: market not open");
    }

    // to reduce contract size
    function _checkMarketClosed(address market) private view {
        require(marketStatuses[market] == PerpdexStructs.MarketStatus.Closed, "PE_CMC: market not closed");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { PerpdexStructs } from "../lib/PerpdexStructs.sol";

interface IPerpdexExchange {
    struct AddLiquidityParams {
        address market;
        uint256 base;
        uint256 quote;
        uint256 minBase;
        uint256 minQuote;
        uint256 deadline;
    }

    struct RemoveLiquidityParams {
        address trader;
        address market;
        uint256 liquidity;
        uint256 minBase;
        uint256 minQuote;
        uint256 deadline;
    }

    struct TradeParams {
        address trader;
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint256 deadline;
    }

    struct PreviewTradeParams {
        address trader;
        address market;
        address caller;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
    }

    struct MaxTradeParams {
        address trader;
        address market;
        address caller;
        bool isBaseToQuote;
        bool isExactInput;
    }

    struct CreateLimitOrderParams {
        address market;
        bool isBid;
        uint256 base;
        uint256 priceX96;
        uint256 deadline;
    }

    struct CancelLimitOrderParams {
        address market;
        bool isBid;
        uint40 orderId;
        uint256 deadline;
    }

    event CollateralCompensated(address indexed trader, uint256 amount);
    event Deposited(address indexed trader, uint256 amount);
    event Withdrawn(address indexed trader, uint256 amount);
    event ProtocolFeeTransferred(address indexed trader, uint256 amount);

    event LiquidityAdded(
        address indexed trader,
        address indexed market,
        uint256 base,
        uint256 quote,
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    );

    event LiquidityRemoved(
        address indexed trader,
        address indexed market,
        address liquidator,
        uint256 base,
        uint256 quote,
        uint256 liquidity,
        int256 takerBase,
        int256 takerQuote,
        int256 realizedPnl
    );

    event PartiallyExecuted(
        address indexed maker,
        address indexed market,
        bool isAsk,
        uint256 basePartial,
        uint256 quotePartial,
        int256 partialRealizedPnL
    );

    event PositionLiquidated(
        address indexed trader,
        address indexed market,
        address indexed liquidator,
        int256 base,
        int256 quote,
        int256 realizedPnl,
        uint256 protocolFee,
        uint256 baseBalancePerShareX96,
        uint256 sharePriceAfterX96,
        uint256 liquidationPenalty,
        uint256 liquidationReward,
        uint256 insuranceFundReward
    );

    event PositionChanged(
        address indexed trader,
        address indexed market,
        int256 base,
        int256 quote,
        int256 realizedPnl,
        uint256 protocolFee,
        uint256 baseBalancePerShareX96,
        uint256 sharePriceAfterX96
    );

    event LimitOrderCreated(
        address indexed trader,
        address indexed market,
        bool isBid,
        uint256 base,
        uint256 priceX96,
        uint256 orderId
    );

    event LimitOrderCanceled(
        address indexed trader,
        address indexed market,
        address indexed liquidator,
        bool isBid,
        uint256 orderId
    );

    event MaxMarketsPerAccountChanged(uint8 value);
    event MaxOrdersPerAccountChanged(uint8 value);
    event ImRatioChanged(uint24 value);
    event MmRatioChanged(uint24 value);
    event LiquidationRewardConfigChanged(uint24 rewardRatio, uint16 smoothEmaTime);
    event ProtocolFeeRatioChanged(uint24 value);
    event MarketStatusChanged(address indexed market, PerpdexStructs.MarketStatus status);

    function deposit(uint256 amount) external payable;

    function withdraw(uint256 amount) external;

    function transferProtocolFee(uint256 amount) external;

    function addLiquidity(AddLiquidityParams calldata params)
        external
        returns (
            uint256 base,
            uint256 quote,
            uint256 liquidity
        );

    function removeLiquidity(RemoveLiquidityParams calldata params) external returns (uint256 base, uint256 quote);

    function createLimitOrder(CreateLimitOrderParams calldata params) external returns (uint40 orderId);

    function cancelLimitOrder(CancelLimitOrderParams calldata params) external;

    function trade(TradeParams calldata params) external returns (uint256 oppositeAmount);

    // setters

    function setMaxMarketsPerAccount(uint8 value) external;

    function setImRatio(uint24 value) external;

    function setMmRatio(uint24 value) external;

    function setLiquidationRewardConfig(PerpdexStructs.LiquidationRewardConfig calldata value) external;

    function setProtocolFeeRatio(uint24 value) external;

    function setMarketStatus(address market, PerpdexStructs.MarketStatus status) external;

    // dry run getters

    function previewTrade(PreviewTradeParams calldata params) external view returns (uint256 oppositeAmount);

    function maxTrade(MaxTradeParams calldata params) external view returns (uint256 amount);

    // default getters

    function accountInfos(address trader)
        external
        view
        returns (PerpdexStructs.VaultInfo memory, uint8 limitOrderCount);

    function insuranceFundInfo() external view returns (uint256 balance, uint256 liquidationRewardBalance);

    function protocolInfo() external view returns (uint256 protocolFee);

    function settlementToken() external view returns (address);

    function quoteDecimals() external view returns (uint8);

    function maxMarketsPerAccount() external view returns (uint8);

    function imRatio() external view returns (uint24);

    function mmRatio() external view returns (uint24);

    function liquidationRewardConfig() external view returns (uint24 rewardRatio, uint16 smoothEmaTime);

    function protocolFeeRatio() external view returns (uint24);

    function marketStatuses(address market) external view returns (PerpdexStructs.MarketStatus status);

    // getters not covered by default getters

    function getTakerInfo(address trader, address market) external view returns (PerpdexStructs.TakerInfo memory);

    function getMakerInfo(address trader, address market) external view returns (PerpdexStructs.MakerInfo memory);

    function getAccountMarkets(address trader) external view returns (address[] memory);

    function getLimitOrderInfo(address trader, address market)
        external
        view
        returns (
            uint40 askRoot,
            uint40 bidRoot,
            uint256 totalBaseAsk,
            uint256 totalBaseBid
        );

    function getLimitOrderIds(
        address trader,
        address market,
        bool isBid
    ) external view returns (uint40[] memory);

    // convenient getters

    function getTotalAccountValue(address trader) external view returns (int256);

    function getPositionShare(address trader, address market) external view returns (int256);

    function getPositionNotional(address trader, address market) external view returns (int256);

    function getTotalPositionNotional(address trader) external view returns (uint256);

    function getOpenPositionShare(address trader, address market) external view returns (uint256);

    function getOpenPositionNotional(address trader, address market) external view returns (uint256);

    function getTotalOpenPositionNotional(address trader) external view returns (uint256);

    function hasEnoughMaintenanceMargin(address trader) external view returns (bool);

    function hasEnoughInitialMargin(address trader) external view returns (bool);

    function isLiquidationFree(address trader) external view returns (bool);

    function getLimitOrderSummaries(
        address trader,
        address market,
        bool isBid
    ) external view returns (PerpdexStructs.LimitOrderSummary[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import {
    BokkyPooBahsRedBlackTreeLibrary as RBTreeLibrary
} from "../../deps/BokkyPooBahsRedBlackTreeLibrary/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

library PerpdexStructs {
    enum MarketStatus { NotAllowed, Open, Closed }

    struct TakerInfo {
        int256 baseBalanceShare;
        int256 quoteBalance;
    }

    struct MakerInfo {
        uint256 liquidity;
        uint256 cumBaseSharePerLiquidityX96;
        uint256 cumQuotePerLiquidityX96;
    }

    struct LimitOrderInfo {
        RBTreeLibrary.Tree ask;
        RBTreeLibrary.Tree bid;
        uint256 totalBaseAsk;
        uint256 totalBaseBid;
    }

    struct VaultInfo {
        int256 collateralBalance;
    }

    struct AccountInfo {
        // market
        mapping(address => TakerInfo) takerInfos;
        // market
        mapping(address => MakerInfo) makerInfos;
        // market
        mapping(address => LimitOrderInfo) limitOrderInfos;
        VaultInfo vaultInfo;
        address[] markets;
        uint8 limitOrderCount;
    }

    struct InsuranceFundInfo {
        uint256 balance; // for easy calculation
        uint256 liquidationRewardBalance;
    }

    struct ProtocolInfo {
        uint256 protocolFee;
    }

    struct LiquidationRewardConfig {
        uint24 rewardRatio;
        uint16 smoothEmaTime;
    }

    struct LimitOrderSummary {
        uint40 orderId;
        uint256 base;
        uint256 priceX96;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { PerpMath } from "./PerpMath.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IPerpdexMarketMinimum } from "../interfaces/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import { AccountPreviewLibrary } from "./AccountPreviewLibrary.sol";

// https://help.ftx.com/hc/en-us/articles/360024780511-Complete-Futures-Specs
library AccountLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct CalcMarketResponse {
        int256 baseShare;
        uint256 baseSharePool;
        uint256 baseShareAsk;
        uint256 baseShareBid;
        int256 quoteBalance;
        uint256 quoteBalancePool;
        int256 positionNotional;
        uint256 openPositionShare;
        uint256 openPositionNotional;
        int256 positionValue;
        int256 realizedPnl;
    }

    struct CalcTotalResponse {
        int256 accountValue;
        int256 collateralBalance;
        uint256 totalPositionNotional;
        uint256 totalOpenPositionNotional;
        bool isLiquidationFree;
    }

    function updateMarkets(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        uint8 maxMarketsPerAccount
    ) external {
        bool enabled =
            accountInfo.takerInfos[market].baseBalanceShare != 0 ||
                accountInfo.makerInfos[market].liquidity != 0 ||
                accountInfo.limitOrderInfos[market].ask.root != 0 ||
                accountInfo.limitOrderInfos[market].bid.root != 0;

        _setMarketEnabled(accountInfo, market, maxMarketsPerAccount, enabled);
    }

    function closeMarket(PerpdexStructs.AccountInfo storage accountInfo, address market) external {
        require(_marketExists(accountInfo, market), "AL_CM: market not exist");
        CalcMarketResponse memory response = _calcMarket(accountInfo, market);
        accountInfo.vaultInfo.collateralBalance += response.positionValue + response.realizedPnl;
        _setMarketEnabled(accountInfo, market, 0, false);
    }

    function getTakerInfo(PerpdexStructs.AccountInfo storage accountInfo, address market)
        external
        view
        returns (PerpdexStructs.TakerInfo memory takerInfo)
    {
        (AccountPreviewLibrary.Execution[] memory executions, , ) =
            AccountPreviewLibrary.getLimitOrderExecutions(accountInfo, market);
        (takerInfo, , , ) = AccountPreviewLibrary.previewSettleLimitOrders(accountInfo, market, executions);
    }

    function getCollateralBalance(PerpdexStructs.AccountInfo storage accountInfo) external view returns (int256) {
        return _calcTotal(accountInfo).collateralBalance;
    }

    function getTotalAccountValue(PerpdexStructs.AccountInfo storage accountInfo) external view returns (int256) {
        return _calcTotal(accountInfo).accountValue;
    }

    function getPositionShare(PerpdexStructs.AccountInfo storage accountInfo, address market)
        external
        view
        returns (int256)
    {
        return _calcMarket(accountInfo, market).baseShare;
    }

    function getPositionNotional(PerpdexStructs.AccountInfo storage accountInfo, address market)
        external
        view
        returns (int256)
    {
        return _calcMarket(accountInfo, market).positionNotional;
    }

    function getTotalPositionNotional(PerpdexStructs.AccountInfo storage accountInfo) external view returns (uint256) {
        return _calcTotal(accountInfo).totalPositionNotional;
    }

    function getOpenPositionShare(PerpdexStructs.AccountInfo storage accountInfo, address market)
        external
        view
        returns (uint256)
    {
        return _calcMarket(accountInfo, market).openPositionShare;
    }

    function getOpenPositionNotional(PerpdexStructs.AccountInfo storage accountInfo, address market)
        external
        view
        returns (uint256)
    {
        return _calcMarket(accountInfo, market).openPositionNotional;
    }

    function getTotalOpenPositionNotional(PerpdexStructs.AccountInfo storage accountInfo)
        external
        view
        returns (uint256)
    {
        return _calcTotal(accountInfo).totalOpenPositionNotional;
    }

    function hasEnoughMaintenanceMargin(PerpdexStructs.AccountInfo storage accountInfo, uint24 mmRatio)
        external
        view
        returns (bool)
    {
        CalcTotalResponse memory response = _calcTotal(accountInfo);
        return response.accountValue.mul(1e6) >= response.totalPositionNotional.mul(mmRatio).toInt256();
    }

    // always true when hasEnoughMaintenanceMargin is true
    function hasEnoughInitialMargin(PerpdexStructs.AccountInfo storage accountInfo, uint24 imRatio)
        external
        view
        returns (bool)
    {
        CalcTotalResponse memory response = _calcTotal(accountInfo);
        return
            response.accountValue.min(response.collateralBalance).mul(1e6) >=
            response.totalOpenPositionNotional.mul(imRatio).toInt256() ||
            response.isLiquidationFree;
    }

    function isLiquidationFree(PerpdexStructs.AccountInfo storage accountInfo) external view returns (bool) {
        return _calcTotal(accountInfo).isLiquidationFree;
    }

    function _setMarketEnabled(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        uint8 maxMarketsPerAccount,
        bool enabled
    ) private {
        address[] storage markets = accountInfo.markets;
        uint256 length = markets.length;

        for (uint256 i = 0; i < length; ++i) {
            if (markets[i] == market) {
                if (!enabled) {
                    markets[i] = markets[length - 1];
                    markets.pop();
                }
                return;
            }
        }

        if (!enabled) return;

        require(length + 1 <= maxMarketsPerAccount, "AL_UP: too many markets");
        markets.push(market);
    }

    function _calcMarket(PerpdexStructs.AccountInfo storage accountInfo, address market)
        private
        view
        returns (CalcMarketResponse memory response)
    {
        PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[market];
        PerpdexStructs.TakerInfo memory takerInfo;
        (AccountPreviewLibrary.Execution[] memory executions, , ) =
            AccountPreviewLibrary.getLimitOrderExecutions(accountInfo, market);

        uint256 totalExecutedBaseAsk;
        uint256 totalExecutedBaseBid;
        (takerInfo, response.realizedPnl, totalExecutedBaseAsk, totalExecutedBaseBid) = AccountPreviewLibrary
            .previewSettleLimitOrders(accountInfo, market, executions);

        response.baseShare = takerInfo.baseBalanceShare;
        response.quoteBalance = takerInfo.quoteBalance;

        uint256 totalOrderBaseAsk;
        uint256 totalOrderBaseBid;
        if (makerInfo.liquidity != 0) {
            (uint256 poolBaseShare, uint256 poolQuoteBalance) =
                IPerpdexMarketMinimum(market).getLiquidityValue(makerInfo.liquidity);
            (int256 deleveragedBaseShare, int256 deleveragedQuoteBalance) =
                IPerpdexMarketMinimum(market).getLiquidityDeleveraged(
                    makerInfo.liquidity,
                    makerInfo.cumBaseSharePerLiquidityX96,
                    makerInfo.cumQuotePerLiquidityX96
                );
            response.baseSharePool = poolBaseShare;
            response.baseShare = response.baseShare.add(deleveragedBaseShare).add(response.baseSharePool.toInt256());
            response.quoteBalancePool = poolQuoteBalance;
            response.quoteBalance = response.quoteBalance.add(deleveragedQuoteBalance).add(
                response.quoteBalancePool.toInt256()
            );
            totalOrderBaseAsk = poolBaseShare;
            totalOrderBaseBid = poolBaseShare;
        }

        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[market];
        response.baseShareAsk = limitOrderInfo.totalBaseAsk - totalExecutedBaseAsk;
        response.baseShareBid = limitOrderInfo.totalBaseBid - totalExecutedBaseBid;
        totalOrderBaseAsk += response.baseShareAsk;
        totalOrderBaseBid += response.baseShareBid;
        response.openPositionShare = Math.max(
            (response.baseShare - totalOrderBaseAsk.toInt256()).abs(),
            (response.baseShare + totalOrderBaseBid.toInt256()).abs()
        );

        if (response.openPositionShare != 0) {
            uint256 sharePriceX96 = IPerpdexMarketMinimum(market).getShareMarkPriceX96();
            response.openPositionNotional = Math.mulDiv(response.openPositionShare, sharePriceX96, FixedPoint96.Q96);

            if (response.baseShare != 0) {
                response.positionNotional = response.baseShare.mulDiv(sharePriceX96.toInt256(), FixedPoint96.Q96);
                response.positionValue = response.positionValue.add(response.positionNotional);
            }
        }

        response.positionValue = response.positionValue.add(response.quoteBalance);
    }

    function _calcTotal(PerpdexStructs.AccountInfo storage accountInfo)
        private
        view
        returns (CalcTotalResponse memory response)
    {
        response.collateralBalance = accountInfo.vaultInfo.collateralBalance;
        response.isLiquidationFree = true;
        int256 quoteBalanceWithoutPool;

        address[] storage markets = accountInfo.markets;
        uint256 length = markets.length;
        for (uint256 i = 0; i < length; ++i) {
            address market = markets[i];

            CalcMarketResponse memory marketResponse = _calcMarket(accountInfo, market);

            response.accountValue = response.accountValue.add(marketResponse.positionValue);
            response.collateralBalance = response.collateralBalance.add(marketResponse.realizedPnl);
            response.totalPositionNotional = response.totalPositionNotional.add(marketResponse.positionNotional.abs());
            response.totalOpenPositionNotional = response.totalOpenPositionNotional.add(
                marketResponse.openPositionNotional
            );

            response.isLiquidationFree =
                response.isLiquidationFree &&
                marketResponse.baseShare >= marketResponse.baseShareAsk.add(marketResponse.baseSharePool).toInt256() &&
                marketResponse.baseShareBid == 0;
            quoteBalanceWithoutPool = quoteBalanceWithoutPool.add(
                marketResponse.quoteBalance - marketResponse.quoteBalancePool.toInt256()
            );
        }
        response.accountValue = response.accountValue.add(response.collateralBalance);
        response.isLiquidationFree =
            response.isLiquidationFree &&
            quoteBalanceWithoutPool.add(response.collateralBalance) >= 0;
    }

    function _marketExists(PerpdexStructs.AccountInfo storage accountInfo, address market) private view returns (bool) {
        address[] storage markets = accountInfo.markets;
        uint256 length = markets.length;
        for (uint256 i = 0; i < length; ++i) {
            if (markets[i] == market) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IPerpdexMarketMinimum } from "../interfaces/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import { AccountLibrary } from "./AccountLibrary.sol";
import { TakerLibrary } from "./TakerLibrary.sol";

library MakerLibrary {
    using PerpMath for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct AddLiquidityParams {
        address market;
        uint256 base;
        uint256 quote;
        uint256 minBase;
        uint256 minQuote;
        uint24 imRatio;
        uint8 maxMarketsPerAccount;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 liquidity;
    }

    struct RemoveLiquidityParams {
        address market;
        uint256 liquidity;
        uint256 minBase;
        uint256 minQuote;
        uint24 mmRatio;
        uint8 maxMarketsPerAccount;
        bool isSelf;
    }

    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
        int256 takerBase;
        int256 takerQuote;
        int256 realizedPnl;
        bool isLiquidation;
    }

    function addLiquidity(PerpdexStructs.AccountInfo storage accountInfo, AddLiquidityParams memory params)
        external
        returns (AddLiquidityResponse memory response)
    {
        PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[params.market];

        // retrieve before addLiquidity
        (uint256 cumBasePerLiquidityX96, uint256 cumQuotePerLiquidityX96) =
            IPerpdexMarketMinimum(params.market).getCumDeleveragedPerLiquidityX96();

        (response.base, response.quote, response.liquidity) = IPerpdexMarketMinimum(params.market).addLiquidity(
            params.base,
            params.quote
        );

        require(response.base >= params.minBase, "ML_AL: too small output base");
        require(response.quote >= params.minQuote, "ML_AL: too small output quote");

        uint256 liquidityBefore = makerInfo.liquidity;
        makerInfo.liquidity = liquidityBefore.add(response.liquidity);
        {
            makerInfo.cumBaseSharePerLiquidityX96 = _blendCumPerLiquidity(
                liquidityBefore,
                response.liquidity,
                response.base,
                makerInfo.cumBaseSharePerLiquidityX96,
                cumBasePerLiquidityX96
            );
            makerInfo.cumQuotePerLiquidityX96 = _blendCumPerLiquidity(
                liquidityBefore,
                response.liquidity,
                response.quote,
                makerInfo.cumQuotePerLiquidityX96,
                cumQuotePerLiquidityX96
            );
        }

        AccountLibrary.updateMarkets(accountInfo, params.market, params.maxMarketsPerAccount);

        require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "ML_AL: not enough im");
    }

    // difficult to calculate without error
    // underestimate the value to maintain the liquidation free condition
    // the error will be a burden to the insurance fund
    // the error is much smaller than the gas fee, so it is impossible to attack
    function _blendCumPerLiquidity(
        uint256 liquidityBefore,
        uint256 addedLiquidity,
        uint256 addedToken,
        uint256 cumBefore,
        uint256 cumAfter
    ) private pure returns (uint256) {
        uint256 liquidityAfter = liquidityBefore.add(addedLiquidity);
        cumAfter = cumAfter.add(Math.mulDiv(addedToken, FixedPoint96.Q96, addedLiquidity));

        return
            Math.mulDiv(cumBefore, liquidityBefore, liquidityAfter).add(
                Math.mulDiv(cumAfter, addedLiquidity, liquidityAfter)
            );
    }

    function removeLiquidity(PerpdexStructs.AccountInfo storage accountInfo, RemoveLiquidityParams memory params)
        external
        returns (RemoveLiquidityResponse memory response)
    {
        response.isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, params.mmRatio);

        if (!params.isSelf) {
            require(response.isLiquidation, "ML_RL: enough mm");
        }

        uint256 shareMarkPriceBeforeX96;
        {
            PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[params.market];
            // retrieve before removeLiquidity
            (response.takerBase, response.takerQuote) = IPerpdexMarketMinimum(params.market).getLiquidityDeleveraged(
                params.liquidity,
                makerInfo.cumBaseSharePerLiquidityX96,
                makerInfo.cumQuotePerLiquidityX96
            );

            shareMarkPriceBeforeX96 = IPerpdexMarketMinimum(params.market).getShareMarkPriceX96();
        }

        {
            (response.base, response.quote) = IPerpdexMarketMinimum(params.market).removeLiquidity(params.liquidity);

            require(response.base >= params.minBase, "ML_RL: too small output base");
            require(response.quote >= params.minQuote, "ML_RL: too small output base");

            response.takerBase = response.takerBase.add(response.base.toInt256());
            response.takerQuote = response.takerQuote.add(response.quote.toInt256());

            PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[params.market];
            makerInfo.liquidity = makerInfo.liquidity.sub(params.liquidity);
        }

        {
            int256 takerQuoteCalculatedAtCurrentPrice =
                -response.takerBase.mulDiv(shareMarkPriceBeforeX96.toInt256(), FixedPoint96.Q96);

            // AccountLibrary.updateMarkets called
            response.realizedPnl = TakerLibrary.addToTakerBalance(
                accountInfo,
                params.market,
                response.takerBase,
                takerQuoteCalculatedAtCurrentPrice,
                response.takerQuote.sub(takerQuoteCalculatedAtCurrentPrice),
                params.maxMarketsPerAccount
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IPerpdexMarketMinimum } from "../interfaces/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import { AccountLibrary } from "./AccountLibrary.sol";
import { AccountPreviewLibrary } from "./AccountPreviewLibrary.sol";
import { TakerLibrary } from "./TakerLibrary.sol";
import {
    BokkyPooBahsRedBlackTreeLibrary as RBTreeLibrary
} from "../../deps/BokkyPooBahsRedBlackTreeLibrary/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

library MakerOrderBookLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using RBTreeLibrary for RBTreeLibrary.Tree;

    struct CreateLimitOrderParams {
        address market;
        uint256 base;
        uint256 priceX96;
        bool isBid;
        uint24 imRatio;
        uint8 maxMarketsPerAccount;
        uint8 maxOrdersPerAccount;
    }

    struct CancelLimitOrderParams {
        address market;
        uint40 orderId;
        bool isBid;
        uint24 mmRatio;
        bool isSelf;
        uint8 maxMarketsPerAccount;
    }

    function createLimitOrder(PerpdexStructs.AccountInfo storage accountInfo, CreateLimitOrderParams memory params)
        public
        returns (uint40 orderId)
    {
        require(accountInfo.limitOrderCount < params.maxOrdersPerAccount, "MOBL_CLO: max order count");
        orderId = IPerpdexMarketMinimum(params.market).createLimitOrder(params.isBid, params.base, params.priceX96);

        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[params.market];
        uint256 slot = _getSlot(limitOrderInfo);
        if (params.isBid) {
            limitOrderInfo.bid.insert(orderId, makeUserData(params.priceX96), _lessThanBid, _aggregate, slot);
            limitOrderInfo.totalBaseBid += params.base;
        } else {
            limitOrderInfo.ask.insert(orderId, makeUserData(params.priceX96), _lessThanAsk, _aggregate, slot);
            limitOrderInfo.totalBaseAsk += params.base;
        }
        accountInfo.limitOrderCount += 1;

        AccountLibrary.updateMarkets(accountInfo, params.market, params.maxMarketsPerAccount);

        require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "MOBL_CLO: not enough im");
    }

    function cancelLimitOrder(PerpdexStructs.AccountInfo storage accountInfo, CancelLimitOrderParams memory params)
        public
        returns (bool isLiquidation)
    {
        isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, params.mmRatio);

        if (!params.isSelf) {
            require(isLiquidation, "MOBL_CLO: enough mm");
        }

        (uint256 base, ) = IPerpdexMarketMinimum(params.market).getLimitOrderInfo(params.isBid, params.orderId);
        IPerpdexMarketMinimum(params.market).cancelLimitOrder(params.isBid, params.orderId);

        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[params.market];
        if (params.isBid) {
            limitOrderInfo.totalBaseBid -= base;
            limitOrderInfo.bid.remove(params.orderId, _aggregate, 0);
        } else {
            limitOrderInfo.totalBaseAsk -= base;
            limitOrderInfo.ask.remove(params.orderId, _aggregate, 0);
        }
        accountInfo.limitOrderCount -= 1;

        AccountLibrary.updateMarkets(accountInfo, params.market, params.maxMarketsPerAccount);
    }

    function makeUserData(uint256 priceX96) internal pure returns (uint128) {
        return priceX96.toUint128();
    }

    function userDataToPriceX96(uint128 userData) internal pure returns (uint128) {
        return userData;
    }

    function _lessThan(
        RBTreeLibrary.Tree storage tree,
        bool isBid,
        uint40 key0,
        uint40 key1
    ) private view returns (bool) {
        uint128 price0 = userDataToPriceX96(tree.nodes[key0].userData);
        uint128 price1 = userDataToPriceX96(tree.nodes[key1].userData);
        if (price0 == price1) {
            return key0 < key1; // time priority
        }
        // price priority
        return isBid ? price0 > price1 : price0 < price1;
    }

    function _lessThanAsk(
        uint40 key0,
        uint40 key1,
        uint256 slot
    ) private view returns (bool) {
        PerpdexStructs.LimitOrderInfo storage info = _getLimitOrderInfoFromSlot(slot);
        return _lessThan(info.ask, false, key0, key1);
    }

    function _lessThanBid(
        uint40 key0,
        uint40 key1,
        uint256 slot
    ) private view returns (bool) {
        PerpdexStructs.LimitOrderInfo storage info = _getLimitOrderInfoFromSlot(slot);
        return _lessThan(info.bid, true, key0, key1);
    }

    function _aggregate(uint40, uint256) private pure returns (bool) {
        return true;
    }

    function _subtreeRemoved(uint40, uint256) private pure {}

    function settleLimitOrdersAll(PerpdexStructs.AccountInfo storage accountInfo, uint8 maxMarketsPerAccount) public {
        address[] storage markets = accountInfo.markets;
        uint256 i = markets.length;
        while (i > 0) {
            --i;
            _settleLimitOrders(accountInfo, markets[i], maxMarketsPerAccount);
        }
    }

    function _settleLimitOrders(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        uint8 maxMarketsPerAccount
    ) private {
        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[market];
        (
            AccountPreviewLibrary.Execution[] memory executions,
            uint40 executedLastAskOrderId,
            uint40 executedLastBidOrderId
        ) = AccountPreviewLibrary.getLimitOrderExecutions(accountInfo, market);
        uint256 executionLength = executions.length;
        if (executionLength == 0) return;

        {
            uint256 slot = _getSlot(limitOrderInfo);
            if (executedLastAskOrderId != 0) {
                limitOrderInfo.ask.removeLeft(executedLastAskOrderId, _lessThanAsk, _aggregate, _subtreeRemoved, slot);
            }
            if (executedLastBidOrderId != 0) {
                limitOrderInfo.bid.removeLeft(executedLastBidOrderId, _lessThanBid, _aggregate, _subtreeRemoved, slot);
            }
        }

        int256 realizedPnl;
        uint256 totalExecutedBaseAsk;
        uint256 totalExecutedBaseBid;
        (
            accountInfo.takerInfos[market],
            realizedPnl,
            totalExecutedBaseAsk,
            totalExecutedBaseBid
        ) = AccountPreviewLibrary.previewSettleLimitOrders(accountInfo, market, executions);

        limitOrderInfo.totalBaseAsk -= totalExecutedBaseAsk;
        limitOrderInfo.totalBaseBid -= totalExecutedBaseBid;
        accountInfo.limitOrderCount -= executionLength.toUint8();
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(realizedPnl);
        AccountLibrary.updateMarkets(accountInfo, market, maxMarketsPerAccount);
    }

    function processPartialExecution(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isBaseToQuote,
        uint8 maxMarketsPerAccount,
        IPerpdexMarketMinimum.SwapResponse memory rawResponse
    ) external returns (int256 realizedPnl) {
        _settleLimitOrders(accountInfo, market, maxMarketsPerAccount);
        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[market];
        if (isBaseToQuote) {
            limitOrderInfo.totalBaseBid -= rawResponse.basePartial;
        } else {
            limitOrderInfo.totalBaseAsk -= rawResponse.basePartial;
        }
        realizedPnl = TakerLibrary.addToTakerBalance(
            accountInfo,
            market,
            isBaseToQuote ? rawResponse.basePartial.toInt256() : rawResponse.basePartial.neg256(),
            isBaseToQuote ? rawResponse.quotePartial.neg256() : rawResponse.quotePartial.toInt256(),
            0,
            maxMarketsPerAccount
        );
    }

    function getLimitOrderIds(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isBid
    ) public view returns (uint40[] memory result) {
        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[market];
        RBTreeLibrary.Tree storage tree = isBid ? limitOrderInfo.bid : limitOrderInfo.ask;
        uint40[256] memory orderIds;
        uint256 orderCount;
        uint40 key = tree.first();
        while (key != 0) {
            orderIds[orderCount] = key;
            ++orderCount;
            key = tree.next(key);
        }
        result = new uint40[](orderCount);
        for (uint256 i = 0; i < orderCount; ++i) {
            result[i] = orderIds[i];
        }
    }

    function getLimitOrderSummaries(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isBid
    ) external view returns (PerpdexStructs.LimitOrderSummary[] memory result) {
        uint40[] memory orderIds = getLimitOrderIds(accountInfo, market, isBid);
        uint256 length = orderIds.length;
        PerpdexStructs.LimitOrderSummary[256] memory summaries;
        uint256 summaryCount;
        uint256 i;
        while (i < length) {
            (uint48 executionId, , ) = IPerpdexMarketMinimum(market).getLimitOrderExecution(isBid, orderIds[i]);
            if (executionId != 0) break;
            ++i;
        }
        while (i < length) {
            summaries[summaryCount].orderId = orderIds[i];
            (summaries[summaryCount].base, summaries[summaryCount].priceX96) = IPerpdexMarketMinimum(market)
                .getLimitOrderInfo(isBid, orderIds[i]);
            ++summaryCount;
            ++i;
        }
        result = new PerpdexStructs.LimitOrderSummary[](summaryCount);
        for (uint256 i = 0; i < summaryCount; ++i) {
            result[i] = summaries[i];
        }
    }

    function _getSlot(PerpdexStructs.LimitOrderInfo storage d) private pure returns (uint256 slot) {
        assembly {
            slot := d.slot
        }
    }

    function _getLimitOrderInfoFromSlot(uint256 slot) private pure returns (PerpdexStructs.LimitOrderInfo storage d) {
        assembly {
            d.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { IPerpdexMarketMinimum } from "../interfaces/IPerpdexMarketMinimum.sol";
import { PerpMath } from "./PerpMath.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import { AccountLibrary } from "./AccountLibrary.sol";
import { AccountPreviewLibrary } from "./AccountPreviewLibrary.sol";

library TakerLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct TradeParams {
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint24 mmRatio;
        uint24 imRatio;
        uint8 maxMarketsPerAccount;
        uint24 protocolFeeRatio;
        bool isSelf;
        PerpdexStructs.LiquidationRewardConfig liquidationRewardConfig;
    }

    struct PreviewTradeParams {
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint24 mmRatio;
        uint24 protocolFeeRatio;
        bool isSelf;
    }

    struct TradeResponse {
        int256 base;
        int256 quote;
        int256 realizedPnl;
        uint256 protocolFee;
        uint256 liquidationPenalty;
        uint256 liquidationReward;
        uint256 insuranceFundReward;
        bool isLiquidation;
        IPerpdexMarketMinimum.SwapResponse rawResponse;
    }

    // to avoid stack too deep
    struct DoSwapParams {
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint8 maxMarketsPerAccount;
        uint24 protocolFeeRatio;
        bool isLiquidation;
    }

    function trade(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.VaultInfo storage liquidatorVaultInfo,
        PerpdexStructs.InsuranceFundInfo storage insuranceFundInfo,
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        TradeParams memory params
    ) internal returns (TradeResponse memory response) {
        response.isLiquidation = _validateTrade(accountInfo, params.market, params.isSelf, params.mmRatio, false);

        int256 takerBaseBefore = accountInfo.takerInfos[params.market].baseBalanceShare;

        (response.base, response.quote, response.realizedPnl, response.protocolFee, response.rawResponse) = _doSwap(
            accountInfo,
            protocolInfo,
            DoSwapParams({
                market: params.market,
                isBaseToQuote: params.isBaseToQuote,
                isExactInput: params.isExactInput,
                amount: params.amount,
                oppositeAmountBound: params.oppositeAmountBound,
                maxMarketsPerAccount: params.maxMarketsPerAccount,
                protocolFeeRatio: params.protocolFeeRatio,
                isLiquidation: response.isLiquidation
            })
        );

        bool isOpen = (takerBaseBefore.add(response.base)).sign() * response.base.sign() > 0;

        if (response.isLiquidation) {
            require(!isOpen, "TL_OP: no open when liquidation");

            (
                response.liquidationPenalty,
                response.liquidationReward,
                response.insuranceFundReward
            ) = processLiquidationReward(
                accountInfo.vaultInfo,
                liquidatorVaultInfo,
                insuranceFundInfo,
                params.mmRatio,
                params.liquidationRewardConfig,
                response.quote.abs()
            );
        }

        if (isOpen) {
            require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "TL_OP: not enough im");
        }
    }

    function addToTakerBalance(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        int256 baseShare,
        int256 quoteBalance,
        int256 quoteFee,
        uint8 maxMarketsPerAccount
    ) internal returns (int256 realizedPnl) {
        (accountInfo.takerInfos[market], realizedPnl) = AccountPreviewLibrary.previewAddToTakerBalance(
            accountInfo.takerInfos[market],
            baseShare,
            quoteBalance,
            quoteFee
        );

        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(realizedPnl);

        AccountLibrary.updateMarkets(accountInfo, market, maxMarketsPerAccount);
    }

    // Even if trade reverts, it may not revert.
    // Attempting to match reverts makes the implementation too complicated
    // ignored checks when liquidation:
    // - initial margin
    // - close only
    // - maker and limit order existence
    function previewTrade(PerpdexStructs.AccountInfo storage accountInfo, PreviewTradeParams memory params)
        internal
        view
        returns (uint256 oppositeAmount)
    {
        bool isLiquidation = _validateTrade(accountInfo, params.market, params.isSelf, params.mmRatio, true);

        oppositeAmount;
        if (params.protocolFeeRatio == 0) {
            oppositeAmount = IPerpdexMarketMinimum(params.market).previewSwap(
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                isLiquidation
            );
        } else {
            (oppositeAmount, ) = previewSwapWithProtocolFee(
                params.market,
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                params.protocolFeeRatio,
                isLiquidation
            );
        }
        validateSlippage(params.isExactInput, oppositeAmount, params.oppositeAmountBound);
    }

    // ignored checks when liquidation:
    // - initial margin
    // - close only
    // - maker and limit order existence
    function maxTrade(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint24 mmRatio,
        uint24 protocolFeeRatio,
        bool isSelf
    ) internal view returns (uint256 amount) {
        bool isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, mmRatio);

        if (!isSelf && !isLiquidation) {
            return 0;
        }

        if (protocolFeeRatio == 0) {
            amount = IPerpdexMarketMinimum(market).maxSwap(isBaseToQuote, isExactInput, isLiquidation);
        } else {
            amount = maxSwapWithProtocolFee(market, isBaseToQuote, isExactInput, protocolFeeRatio, isLiquidation);
        }
    }

    function _doSwap(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        DoSwapParams memory params
    )
        private
        returns (
            int256 base,
            int256 quote,
            int256 realizedPnl,
            uint256 protocolFee,
            IPerpdexMarketMinimum.SwapResponse memory rawResponse
        )
    {
        uint256 oppositeAmount;

        if (params.protocolFeeRatio > 0) {
            (oppositeAmount, protocolFee, rawResponse) = swapWithProtocolFee(
                protocolInfo,
                params.market,
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                params.protocolFeeRatio,
                params.isLiquidation
            );
        } else {
            rawResponse = IPerpdexMarketMinimum(params.market).swap(
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                params.isLiquidation
            );
            oppositeAmount = rawResponse.oppositeAmount;
        }
        validateSlippage(params.isExactInput, oppositeAmount, params.oppositeAmountBound);

        (base, quote) = swapResponseToBaseQuote(
            params.isBaseToQuote,
            params.isExactInput,
            params.amount,
            oppositeAmount
        );
        realizedPnl = addToTakerBalance(accountInfo, params.market, base, quote, 0, params.maxMarketsPerAccount);
    }

    function swapWithProtocolFee(
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint24 protocolFeeRatio,
        bool isLiquidation
    )
        internal
        returns (
            uint256 oppositeAmount,
            uint256 protocolFee,
            IPerpdexMarketMinimum.SwapResponse memory rawResponse
        )
    {
        if (isExactInput) {
            if (isBaseToQuote) {
                rawResponse = IPerpdexMarketMinimum(market).swap(isBaseToQuote, isExactInput, amount, isLiquidation);
                oppositeAmount = rawResponse.oppositeAmount;
                protocolFee = oppositeAmount.mulRatio(protocolFeeRatio);
                oppositeAmount = oppositeAmount.sub(protocolFee);
            } else {
                protocolFee = amount.mulRatio(protocolFeeRatio);
                rawResponse = IPerpdexMarketMinimum(market).swap(
                    isBaseToQuote,
                    isExactInput,
                    amount.sub(protocolFee),
                    isLiquidation
                );
                oppositeAmount = rawResponse.oppositeAmount;
            }
        } else {
            if (isBaseToQuote) {
                protocolFee = amount.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio)).sub(amount);
                rawResponse = IPerpdexMarketMinimum(market).swap(
                    isBaseToQuote,
                    isExactInput,
                    amount.add(protocolFee),
                    isLiquidation
                );
                oppositeAmount = rawResponse.oppositeAmount;
            } else {
                rawResponse = IPerpdexMarketMinimum(market).swap(isBaseToQuote, isExactInput, amount, isLiquidation);
                uint256 oppositeAmountWithoutFee = rawResponse.oppositeAmount;
                oppositeAmount = oppositeAmountWithoutFee.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
                protocolFee = oppositeAmount.sub(oppositeAmountWithoutFee);
            }
        }

        protocolInfo.protocolFee = protocolInfo.protocolFee.add(protocolFee);
    }

    function processLiquidationReward(
        PerpdexStructs.VaultInfo storage vaultInfo,
        PerpdexStructs.VaultInfo storage liquidatorVaultInfo,
        PerpdexStructs.InsuranceFundInfo storage insuranceFundInfo,
        uint24 mmRatio,
        PerpdexStructs.LiquidationRewardConfig memory liquidationRewardConfig,
        uint256 exchangedQuote
    )
        internal
        returns (
            uint256 penalty,
            uint256 liquidationReward,
            uint256 insuranceFundReward
        )
    {
        penalty = exchangedQuote.mulRatio(mmRatio);
        liquidationReward = penalty.mulRatio(liquidationRewardConfig.rewardRatio);
        insuranceFundReward = penalty.sub(liquidationReward);

        (insuranceFundInfo.liquidationRewardBalance, liquidationReward) = _smoothLiquidationReward(
            insuranceFundInfo.liquidationRewardBalance,
            liquidationReward,
            liquidationRewardConfig.smoothEmaTime
        );

        vaultInfo.collateralBalance = vaultInfo.collateralBalance.sub(penalty.toInt256());
        liquidatorVaultInfo.collateralBalance = liquidatorVaultInfo.collateralBalance.add(liquidationReward.toInt256());
        insuranceFundInfo.balance = insuranceFundInfo.balance.add(insuranceFundReward);
    }

    function _smoothLiquidationReward(
        uint256 rewardBalance,
        uint256 reward,
        uint24 emaTime
    ) private pure returns (uint256 outputRewardBalance, uint256 outputReward) {
        rewardBalance = rewardBalance.add(reward);
        outputReward = rewardBalance.div(emaTime);
        outputRewardBalance = rewardBalance.sub(outputReward);
    }

    function previewSwapWithProtocolFee(
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint24 protocolFeeRatio,
        bool isLiquidation
    ) internal view returns (uint256 oppositeAmount, uint256 protocolFee) {
        if (isExactInput) {
            if (isBaseToQuote) {
                oppositeAmount = IPerpdexMarketMinimum(market).previewSwap(
                    isBaseToQuote,
                    isExactInput,
                    amount,
                    isLiquidation
                );
                protocolFee = oppositeAmount.mulRatio(protocolFeeRatio);
                oppositeAmount = oppositeAmount.sub(protocolFee);
            } else {
                protocolFee = amount.mulRatio(protocolFeeRatio);
                oppositeAmount = IPerpdexMarketMinimum(market).previewSwap(
                    isBaseToQuote,
                    isExactInput,
                    amount.sub(protocolFee),
                    isLiquidation
                );
            }
        } else {
            if (isBaseToQuote) {
                protocolFee = amount.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio)).sub(amount);
                oppositeAmount = IPerpdexMarketMinimum(market).previewSwap(
                    isBaseToQuote,
                    isExactInput,
                    amount.add(protocolFee),
                    isLiquidation
                );
            } else {
                uint256 oppositeAmountWithoutFee =
                    IPerpdexMarketMinimum(market).previewSwap(isBaseToQuote, isExactInput, amount, isLiquidation);
                oppositeAmount = oppositeAmountWithoutFee.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
                protocolFee = oppositeAmount.sub(oppositeAmountWithoutFee);
            }
        }
    }

    function maxSwapWithProtocolFee(
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint24 protocolFeeRatio,
        bool isLiquidation
    ) internal view returns (uint256 amount) {
        amount = IPerpdexMarketMinimum(market).maxSwap(isBaseToQuote, isExactInput, isLiquidation);

        if (isExactInput) {
            if (isBaseToQuote) {} else {
                amount = amount.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
            }
        } else {
            if (isBaseToQuote) {
                amount = amount.mulRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
            } else {}
        }
    }

    function validateSlippage(
        bool isExactInput,
        uint256 oppositeAmount,
        uint256 oppositeAmountBound
    ) internal pure {
        if (isExactInput) {
            require(oppositeAmount >= oppositeAmountBound, "TL_VS: too small opposite amount");
        } else {
            require(oppositeAmount <= oppositeAmountBound, "TL_VS: too large opposite amount");
        }
    }

    function swapResponseToBaseQuote(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint256 oppositeAmount
    ) internal pure returns (int256, int256) {
        if (isExactInput) {
            if (isBaseToQuote) {
                return (amount.neg256(), oppositeAmount.toInt256());
            } else {
                return (oppositeAmount.toInt256(), amount.neg256());
            }
        } else {
            if (isBaseToQuote) {
                return (oppositeAmount.neg256(), amount.toInt256());
            } else {
                return (amount.toInt256(), oppositeAmount.neg256());
            }
        }
    }

    function _validateTrade(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isSelf,
        uint24 mmRatio,
        bool ignoreMakerOrderBookExistence
    ) private view returns (bool isLiquidation) {
        isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, mmRatio);

        if (!isSelf) {
            require(isLiquidation, "TL_VT: enough mm");
        }

        if (!ignoreMakerOrderBookExistence && isLiquidation) {
            require(accountInfo.makerInfos[market].liquidity == 0, "TL_VT: no maker when liquidation");
            require(accountInfo.limitOrderInfos[market].ask.root == 0, "TL_VT: no ask when liquidation");
            require(accountInfo.limitOrderInfos[market].bid.root == 0, "TL_VT: no bid when liquidation");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { PerpMath } from "./PerpMath.sol";
import { IERC20Metadata } from "../interfaces/IERC20Metadata.sol";
import { AccountLibrary } from "./AccountLibrary.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";

library VaultLibrary {
    using PerpMath for int256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct DepositParams {
        address settlementToken;
        uint256 amount;
        address from;
    }

    struct WithdrawParams {
        address settlementToken;
        uint256 amount;
        address payable to;
        uint24 imRatio;
    }

    function compensate(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.InsuranceFundInfo storage insuranceFundInfo
    ) external returns (uint256 compensation) {
        if (accountInfo.markets.length != 0) return 0;
        if (accountInfo.vaultInfo.collateralBalance >= 0) return 0;
        compensation = Math.min((-accountInfo.vaultInfo.collateralBalance).toUint256(), insuranceFundInfo.balance);
        accountInfo.vaultInfo.collateralBalance += compensation.toInt256();
        insuranceFundInfo.balance -= compensation;
    }

    function deposit(PerpdexStructs.AccountInfo storage accountInfo, DepositParams memory params) external {
        require(params.amount > 0, "VL_D: zero amount");
        _transferTokenIn(params.settlementToken, params.from, params.amount);
        uint256 collateralAmount =
            _toCollateralAmount(params.amount, IERC20Metadata(params.settlementToken).decimals());
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(
            collateralAmount.toInt256()
        );
    }

    function depositEth(PerpdexStructs.AccountInfo storage accountInfo, uint256 amount) external {
        require(amount > 0, "VL_DE: zero amount");
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(amount.toInt256());
    }

    function withdraw(PerpdexStructs.AccountInfo storage accountInfo, WithdrawParams memory params) external {
        require(params.amount > 0, "VL_W: zero amount");

        uint256 collateralAmount =
            params.settlementToken == address(0)
                ? params.amount
                : _toCollateralAmount(params.amount, IERC20Metadata(params.settlementToken).decimals());
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.sub(
            collateralAmount.toInt256()
        );

        require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "VL_W: not enough initial margin");

        if (params.settlementToken == address(0)) {
            params.to.transfer(params.amount);
        } else {
            SafeERC20.safeTransfer(IERC20(params.settlementToken), params.to, params.amount);
        }
    }

    function transferProtocolFee(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        uint256 amount
    ) external {
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(amount.toInt256());
        protocolInfo.protocolFee = protocolInfo.protocolFee.sub(amount);
    }

    function _transferTokenIn(
        address token,
        address from,
        uint256 amount
    ) private {
        // check for deflationary tokens by assuring balances before and after transferring to be the same
        uint256 balanceBefore = IERC20Metadata(token).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(token), from, address(this), amount);
        require(
            (IERC20Metadata(token).balanceOf(address(this)).sub(balanceBefore)) == amount,
            "VL_TTI: inconsistent balance"
        );
    }

    function _toCollateralAmount(uint256 amount, uint8 tokenDecimals) private pure returns (uint256) {
        int256 decimalsDiff = int256(18).sub(uint256(tokenDecimals).toInt256());
        uint256 decimalsDiffAbs = decimalsDiff.abs();
        require(decimalsDiffAbs <= 77, "VL_TCA: too large decimals diff");
        return decimalsDiff >= 0 ? amount.mul(10**decimalsDiffAbs) : amount.div(10**decimalsDiffAbs);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { IPerpdexMarketMinimum } from "../interfaces/IPerpdexMarketMinimum.sol";
import { PerpMath } from "./PerpMath.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import {
    BokkyPooBahsRedBlackTreeLibrary as RBTreeLibrary
} from "../../deps/BokkyPooBahsRedBlackTreeLibrary/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

// This is a technical library to avoid circular references between libraries
library AccountPreviewLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using RBTreeLibrary for RBTreeLibrary.Tree;

    struct Execution {
        int256 executedBase;
        int256 executedQuote;
    }

    function getLimitOrderExecutions(PerpdexStructs.AccountInfo storage accountInfo, address market)
        internal
        view
        returns (
            Execution[] memory executions,
            uint40 executedLastAskOrderId,
            uint40 executedLastBidOrderId
        )
    {
        PerpdexStructs.LimitOrderInfo storage limitOrderInfo = accountInfo.limitOrderInfos[market];

        uint40 ask = limitOrderInfo.ask.first();
        uint40 bid = limitOrderInfo.bid.first();
        uint256 executionIdAsk;
        uint256 executedBaseAsk;
        uint256 executedQuoteAsk;
        uint256 executionIdBid;
        uint256 executedBaseBid;
        uint256 executedQuoteBid;
        if (ask != 0) {
            (executionIdAsk, executedBaseAsk, executedQuoteAsk) = IPerpdexMarketMinimum(market).getLimitOrderExecution(
                false,
                ask
            );
            if (executionIdAsk == 0) {
                ask = 0;
            }
        }
        if (bid != 0) {
            (executionIdBid, executedBaseBid, executedQuoteBid) = IPerpdexMarketMinimum(market).getLimitOrderExecution(
                true,
                bid
            );
            if (executionIdBid == 0) {
                bid = 0;
            }
        }

        // Combine the ask and bid and process from the one with the smallest executionId.
        // Ask and bid are already sorted and can be processed like merge sort.
        Execution[256] memory executions2;
        uint256 executionCount;
        while (ask != 0 || bid != 0) {
            if (ask != 0 && (bid == 0 || executionIdAsk < executionIdBid)) {
                executions2[executionCount] = Execution({
                    executedBase: executedBaseAsk.neg256(),
                    executedQuote: executedQuoteAsk.toInt256()
                });
                ++executionCount;

                uint40 nextAsk = limitOrderInfo.ask.next(ask);
                if (nextAsk != 0) {
                    (executionIdAsk, executedBaseAsk, executedQuoteAsk) = IPerpdexMarketMinimum(market)
                        .getLimitOrderExecution(false, nextAsk);
                }
                if (executionIdAsk == 0 || nextAsk == 0) {
                    executedLastAskOrderId = ask;
                    ask = 0;
                } else {
                    ask = nextAsk;
                }
            } else {
                executions2[executionCount] = Execution({
                    executedBase: executedBaseBid.toInt256(),
                    executedQuote: executedQuoteBid.neg256()
                });
                ++executionCount;

                uint40 nextBid = limitOrderInfo.bid.next(bid);
                if (nextBid != 0) {
                    (executionIdBid, executedBaseBid, executedQuoteBid) = IPerpdexMarketMinimum(market)
                        .getLimitOrderExecution(true, nextBid);
                }
                if (executionIdBid == 0 || nextBid == 0) {
                    executedLastBidOrderId = bid;
                    bid = 0;
                } else {
                    bid = nextBid;
                }
            }
        }

        executions = new Execution[](executionCount);
        for (uint256 i = 0; i < executionCount; i++) {
            executions[i] = executions2[i];
        }
    }

    function previewSettleLimitOrders(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        Execution[] memory executions
    )
        internal
        view
        returns (
            PerpdexStructs.TakerInfo memory takerInfo,
            int256 realizedPnl,
            uint256 totalExecutedBaseAsk,
            uint256 totalExecutedBaseBid
        )
    {
        takerInfo = accountInfo.takerInfos[market];

        uint256 length = executions.length;
        for (uint256 i = 0; i < length; ++i) {
            int256 realizedPnl2;
            (takerInfo, realizedPnl2) = previewAddToTakerBalance(
                takerInfo,
                executions[i].executedBase,
                executions[i].executedQuote,
                0
            );
            realizedPnl += realizedPnl2;
            if (executions[i].executedBase >= 0) {
                totalExecutedBaseBid += executions[i].executedBase.abs();
            } else {
                totalExecutedBaseAsk += executions[i].executedBase.abs();
            }
        }
    }

    function previewAddToTakerBalance(
        PerpdexStructs.TakerInfo memory takerInfo,
        int256 baseShare,
        int256 quoteBalance,
        int256 quoteFee
    ) internal pure returns (PerpdexStructs.TakerInfo memory resultTakerInfo, int256 realizedPnl) {
        if (baseShare != 0 || quoteBalance != 0) {
            if (baseShare.sign() * quoteBalance.sign() != -1) {
                // ignore invalid input
                return (takerInfo, 0);
            }
            if (takerInfo.baseBalanceShare.sign() * baseShare.sign() == -1) {
                uint256 baseAbs = baseShare.abs();
                uint256 takerBaseAbs = takerInfo.baseBalanceShare.abs();

                if (baseAbs <= takerBaseAbs) {
                    int256 reducedOpenNotional = takerInfo.quoteBalance.mulDiv(baseAbs.toInt256(), takerBaseAbs);
                    realizedPnl = quoteBalance.add(reducedOpenNotional);
                } else {
                    int256 closedPositionNotional = quoteBalance.mulDiv(takerBaseAbs.toInt256(), baseAbs);
                    realizedPnl = takerInfo.quoteBalance.add(closedPositionNotional);
                }
            }
        }
        realizedPnl = realizedPnl.add(quoteFee);

        int256 newBaseBalanceShare = takerInfo.baseBalanceShare.add(baseShare);
        int256 newQuoteBalance = takerInfo.quoteBalance.add(quoteBalance).add(quoteFee).sub(realizedPnl);
        if (
            !((newBaseBalanceShare == 0 && newQuoteBalance == 0) ||
                newBaseBalanceShare.sign() * newQuoteBalance.sign() == -1)
        ) {
            // never occur. ignore
            return (takerInfo, 0);
        }

        resultTakerInfo.baseBalanceShare = newBaseBalanceShare;
        resultTakerInfo.quoteBalance = newQuoteBalance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { PerpdexExchange } from "../PerpdexExchange.sol";
import { PerpdexStructs } from "../lib/PerpdexStructs.sol";
import { MakerOrderBookLibrary } from "../lib/MakerOrderBookLibrary.sol";
import { TestPerpdexMarket } from "./TestPerpdexMarket.sol";

contract TestPerpdexExchange is PerpdexExchange {
    constructor(address settlementTokenArg) PerpdexExchange(msg.sender, settlementTokenArg, new address[](0)) {}

    function setAccountInfo(
        address trader,
        PerpdexStructs.VaultInfo memory vaultInfo,
        address[] memory markets
    ) external {
        accountInfos[trader].vaultInfo = vaultInfo;
        accountInfos[trader].markets = markets;
    }

    function setTakerInfo(
        address trader,
        address market,
        PerpdexStructs.TakerInfo memory takerInfo
    ) external {
        accountInfos[trader].takerInfos[market] = takerInfo;
    }

    function setMakerInfo(
        address trader,
        address market,
        PerpdexStructs.MakerInfo memory makerInfo
    ) external {
        accountInfos[trader].makerInfos[market] = makerInfo;
    }

    function setInsuranceFundInfo(PerpdexStructs.InsuranceFundInfo memory insuranceFundInfoArg) external {
        insuranceFundInfo = insuranceFundInfoArg;
    }

    function setProtocolInfo(PerpdexStructs.ProtocolInfo memory protocolInfoArg) external {
        protocolInfo = protocolInfoArg;
    }

    function setMarketStatusForce(address market, PerpdexStructs.MarketStatus status) external {
        marketStatuses[market] = status;
    }

    function settleLimitOrders(address trader) external {
        _settleLimitOrders(trader);
    }

    struct CreateLimitOrdersForTestParams {
        bool isBid;
        uint256 base;
        uint256 priceX96;
        uint48 executionId;
        uint256 baseBalancePerShareX96;
    }

    function createLimitOrdersForTest(CreateLimitOrdersForTestParams[] calldata paramsList, address market) external {
        address trader = msg.sender;
        int256 collateralBalance = accountInfos[trader].vaultInfo.collateralBalance;
        accountInfos[trader].vaultInfo.collateralBalance = 1 << 128;

        uint40[256] memory orderIds;
        for (uint256 i = 0; i < paramsList.length; ++i) {
            CreateLimitOrdersForTestParams memory params = paramsList[i];

            orderIds[i] = MakerOrderBookLibrary.createLimitOrder(
                accountInfos[trader],
                MakerOrderBookLibrary.CreateLimitOrderParams({
                    market: market,
                    isBid: params.isBid,
                    base: params.base,
                    priceX96: params.priceX96,
                    imRatio: imRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount,
                    maxOrdersPerAccount: maxOrdersPerAccount
                })
            );
            orderIdToTrader[market][params.isBid][orderIds[i]] = trader;
        }

        for (uint256 i = 0; i < paramsList.length; ++i) {
            CreateLimitOrdersForTestParams memory params = paramsList[i];
            TestPerpdexMarket(market).markFullyExecuted(
                params.isBid,
                orderIds[i],
                params.executionId,
                params.baseBalancePerShareX96
            );
        }

        accountInfos[trader].vaultInfo.collateralBalance = collateralBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { PoolLibrary } from "../lib/PoolLibrary.sol";
import { OrderBookLibrary } from "../lib/OrderBookLibrary.sol";
import { MarketStructs } from "../lib/MarketStructs.sol";

contract TestOrderBookLibrary {
    constructor() {}

    MarketStructs.OrderBookInfo info;

    function previewSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint256 baseBalancePerShareX96
    ) external view returns (OrderBookLibrary.PreviewSwapResponse memory response) {
        response = OrderBookLibrary.previewSwap(
            isBaseToQuote ? info.bid : info.ask,
            OrderBookLibrary.PreviewSwapParams({
                isBaseToQuote: isBaseToQuote,
                isExactInput: isExactInput,
                amount: amount,
                baseBalancePerShareX96: baseBalancePerShareX96
            }),
            poolMaxSwap
        );
    }

    function poolMaxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 priceX96
    ) private pure returns (uint256 amount) {
        uint256 base;
        if (isBaseToQuote) {
            if (priceX96 < FixedPoint96.Q96) {
                base = Math.mulDiv(100, FixedPoint96.Q96 - priceX96, FixedPoint96.Q96);
            }
        } else {
            if (priceX96 > FixedPoint96.Q96) {
                base = Math.mulDiv(100, priceX96 - FixedPoint96.Q96, FixedPoint96.Q96);
            }
        }
        bool isBase = isBaseToQuote == isExactInput;
        if (isBase) {
            amount = base;
        } else {
            amount = base * 2;
        }
    }

    function maxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 sharePriceBoundX96,
        uint256 baseBalancePerShareX96
    ) external view returns (uint256 amount) {
        return
            OrderBookLibrary.maxSwap(
                isBaseToQuote ? info.bid : info.ask,
                isBaseToQuote,
                isExactInput,
                sharePriceBoundX96,
                baseBalancePerShareX96
            );
    }

    struct CreateOrderParams {
        bool isBid;
        uint256 base;
        uint256 priceX96;
    }

    function createOrders(CreateOrderParams[] calldata params) external {
        for (uint256 i = 0; i < params.length; ++i) {
            createOrder(params[i]);
        }
    }

    function createOrder(CreateOrderParams calldata params) private {
        OrderBookLibrary.createOrder(info, params.isBid, params.base, params.priceX96);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { PriceLimitLibrary } from "../lib/PriceLimitLibrary.sol";
import { MarketStructs } from "../lib/MarketStructs.sol";

contract TestPriceLimitLibrary {
    constructor() {}

    MarketStructs.PriceLimitInfo public priceLimitInfo;
    MarketStructs.PriceLimitConfig public priceLimitConfig;

    function update(MarketStructs.PriceLimitInfo memory value) external {
        return PriceLimitLibrary.update(priceLimitInfo, value);
    }

    function updateDry(uint256 price) external view returns (MarketStructs.PriceLimitInfo memory) {
        return PriceLimitLibrary.updateDry(priceLimitInfo, priceLimitConfig, price);
    }

    function priceBound(
        uint256 referencePrice,
        uint256 emaPrice,
        bool isLiquidation,
        bool isUpperBound
    ) external view returns (uint256 price) {
        return PriceLimitLibrary.priceBound(referencePrice, emaPrice, priceLimitConfig, isLiquidation, isUpperBound);
    }

    function setPriceLimitInfo(MarketStructs.PriceLimitInfo memory value) external {
        priceLimitInfo = value;
    }

    function setPriceLimitConfig(MarketStructs.PriceLimitConfig memory value) external {
        priceLimitConfig = value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { TakerLibrary } from "../lib/TakerLibrary.sol";
import { PerpdexStructs } from "../lib/PerpdexStructs.sol";

contract TestTakerLibrary {
    constructor() {}

    event AddToTakerBalanceResult(int256 realizedPnl);
    event SwapWithProtocolFeeResult(uint256 oppositeAmount, uint256 protocolFee);
    event ProcessLiquidationRewardResult(
        uint256 liquidationPenalty,
        uint256 liquidationReward,
        uint256 insuranceFundReward
    );

    PerpdexStructs.AccountInfo public accountInfo;
    PerpdexStructs.VaultInfo public liquidatorVaultInfo;
    PerpdexStructs.InsuranceFundInfo public insuranceFundInfo;
    PerpdexStructs.ProtocolInfo public protocolInfo;

    function addToTakerBalance(
        address market,
        int256 baseShare,
        int256 quoteBalance,
        int256 quoteFee,
        uint8 maxMarketsPerAccount
    ) external {
        int256 realizedPnl =
            TakerLibrary.addToTakerBalance(
                accountInfo,
                market,
                baseShare,
                quoteBalance,
                quoteFee,
                maxMarketsPerAccount
            );
        emit AddToTakerBalanceResult(realizedPnl);
    }

    function swapWithProtocolFee(
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint24 protocolFeeRatio,
        bool isLiquidation
    ) external {
        (uint256 oppositeAmount, uint256 protocolFee, ) =
            TakerLibrary.swapWithProtocolFee(
                protocolInfo,
                market,
                isBaseToQuote,
                isExactInput,
                amount,
                protocolFeeRatio,
                isLiquidation
            );
        emit SwapWithProtocolFeeResult(oppositeAmount, protocolFee);
    }

    function previewSwapWithProtocolFee(
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint24 protocolFeeRatio,
        bool isLiquidation
    ) external view returns (uint256 oppositeAmount, uint256 protocolFee) {
        return
            TakerLibrary.previewSwapWithProtocolFee(
                market,
                isBaseToQuote,
                isExactInput,
                amount,
                protocolFeeRatio,
                isLiquidation
            );
    }

    function processLiquidationReward(
        uint24 mmRatio,
        PerpdexStructs.LiquidationRewardConfig memory liquidationRewardConfig,
        uint256 exchangedQuote
    ) external {
        (uint256 liquidationPenalty, uint256 liquidationReward, uint256 insuranceFundReward) =
            TakerLibrary.processLiquidationReward(
                accountInfo.vaultInfo,
                liquidatorVaultInfo,
                insuranceFundInfo,
                mmRatio,
                liquidationRewardConfig,
                exchangedQuote
            );
        emit ProcessLiquidationRewardResult(liquidationPenalty, liquidationReward, insuranceFundReward);
    }

    function validateSlippage(
        bool isExactInput,
        uint256 oppositeAmount,
        uint256 oppositeAmountBound
    ) external pure {
        TakerLibrary.validateSlippage(isExactInput, oppositeAmount, oppositeAmountBound);
    }

    function swapResponseToBaseQuote(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint256 oppositeAmount
    ) external pure returns (int256, int256) {
        return TakerLibrary.swapResponseToBaseQuote(isBaseToQuote, isExactInput, amount, oppositeAmount);
    }

    function setAccountInfo(PerpdexStructs.VaultInfo memory value, address[] memory markets) external {
        accountInfo.vaultInfo = value;
        accountInfo.markets = markets;
    }

    function setLiquidatorVaultInfo(PerpdexStructs.VaultInfo memory value) external {
        liquidatorVaultInfo = value;
    }

    function setInsuranceFundInfo(PerpdexStructs.InsuranceFundInfo memory value) external {
        insuranceFundInfo = value;
    }

    function setProtocolInfo(PerpdexStructs.ProtocolInfo memory value) external {
        protocolInfo = value;
    }

    function setTakerInfo(address market, PerpdexStructs.TakerInfo memory value) external {
        accountInfo.takerInfos[market] = value;
    }

    function getTakerInfo(address market) external view returns (PerpdexStructs.TakerInfo memory) {
        return accountInfo.takerInfos[market];
    }

    function getAccountMarkets() external view returns (address[] memory) {
        return accountInfo.markets;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { AccountLibrary } from "../lib/AccountLibrary.sol";
import { PerpdexStructs } from "../lib/PerpdexStructs.sol";

contract TestAccountLibrary {
    constructor() {}

    PerpdexStructs.AccountInfo public accountInfo;

    function updateMarkets(address market, uint8 maxMarketsPerAccount) external {
        AccountLibrary.updateMarkets(accountInfo, market, maxMarketsPerAccount);
    }

    function setMarkets(address[] memory markets) external {
        accountInfo.markets = markets;
    }

    function setTakerInfo(address market, PerpdexStructs.TakerInfo memory takerInfo) external {
        accountInfo.takerInfos[market] = takerInfo;
    }

    function setMakerInfo(address market, PerpdexStructs.MakerInfo memory makerInfo) external {
        accountInfo.makerInfos[market] = makerInfo;
    }

    function setAskRoot(address market, uint40 root) external {
        accountInfo.limitOrderInfos[market].ask.root = root;
    }

    function setBidRoot(address market, uint40 root) external {
        accountInfo.limitOrderInfos[market].bid.root = root;
    }

    function getMarkets() external view returns (address[] memory) {
        return accountInfo.markets;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { PoolLibrary } from "../lib/PoolLibrary.sol";
import { MarketStructs } from "../lib/MarketStructs.sol";

contract TestPoolLibrary {
    constructor() {}

    event SwapResult(uint256 oppositeAmount);

    MarketStructs.PoolInfo public poolInfo;

    function applyFunding(int256 fundingRateX96) external {
        PoolLibrary.applyFunding(poolInfo, fundingRateX96);
    }

    function swap(PoolLibrary.SwapParams memory params) external {
        uint256 oppositeAmount = PoolLibrary.swap(poolInfo, params);
        emit SwapResult(oppositeAmount);
    }

    function previewSwap(
        uint256 base,
        uint256 quote,
        PoolLibrary.SwapParams memory params
    ) external pure returns (uint256) {
        return PoolLibrary.previewSwap(base, quote, params);
    }

    function maxSwap(
        uint256 base,
        uint256 quote,
        bool isBaseToQuote,
        bool isExactInput,
        uint24 feeRatio,
        uint256 priceBoundX96
    ) external pure returns (uint256 output) {
        return PoolLibrary.maxSwap(base, quote, isBaseToQuote, isExactInput, feeRatio, priceBoundX96);
    }

    function setPoolInfo(MarketStructs.PoolInfo memory value) external {
        poolInfo = value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { PoolFeeLibrary } from "../lib/PoolFeeLibrary.sol";
import { MarketStructs } from "../lib/MarketStructs.sol";

contract TestPoolFeeLibrary {
    MarketStructs.PoolFeeInfo public poolFeeInfo;

    function update(
        MarketStructs.PoolFeeInfo memory poolFeeInfoArg,
        uint32 atrEmaBlocks,
        uint256 prevPriceX96,
        uint256 currentPriceX96
    ) external {
        poolFeeInfo = poolFeeInfoArg;
        PoolFeeLibrary.update(poolFeeInfo, atrEmaBlocks, prevPriceX96, currentPriceX96);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { FundingLibrary } from "../lib/FundingLibrary.sol";
import { MarketStructs } from "../lib/MarketStructs.sol";

contract TestFundingLibrary {
    constructor() {}

    event ProcessFundingResult(int256 fundingRateX96);

    MarketStructs.FundingInfo public fundingInfo;

    function processFunding(FundingLibrary.ProcessFundingParams memory params) external {
        (int256 fundingRateX96, , ) = FundingLibrary.processFunding(fundingInfo, params);
        emit ProcessFundingResult(fundingRateX96);
    }

    function validateInitialLiquidityPrice(
        address priceFeedBase,
        address priceFeedQuote,
        uint256 base,
        uint256 quote
    ) external view {
        FundingLibrary.validateInitialLiquidityPrice(priceFeedBase, priceFeedQuote, base, quote);
    }

    function setFundingInfo(MarketStructs.FundingInfo memory value) external {
        fundingInfo = value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { PerpdexExchange } from "../PerpdexExchange.sol";

contract DebugPerpdexExchange is PerpdexExchange {
    uint256 private constant _RINKEBY_CHAIN_ID = 4;
    uint256 private constant _MUMBAI_CHAIN_ID = 80001;
    uint256 private constant _SHIBUYA_CHAIN_ID = 81;
    // https://v2-docs.zksync.io/dev/zksync-v2/temp-limits.html#temporarily-simulated-by-constant-values
    uint256 private constant _ZKSYNC2_TESTNET_CHAIN_ID = 0;
    uint256 private constant _ARBITRUM_RINKEBY_CHAIN_ID = 421611;
    uint256 private constant _OPTIMISM_KOVAN_CHAIN_ID = 69;
    uint256 private constant _HARDHAT_CHAIN_ID = 31337;

    constructor(address settlementTokenArg) PerpdexExchange(msg.sender, settlementTokenArg, new address[](0)) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(
            chainId == _RINKEBY_CHAIN_ID ||
                chainId == _MUMBAI_CHAIN_ID ||
                chainId == _SHIBUYA_CHAIN_ID ||
                chainId == _ZKSYNC2_TESTNET_CHAIN_ID ||
                chainId == _ARBITRUM_RINKEBY_CHAIN_ID ||
                chainId == _OPTIMISM_KOVAN_CHAIN_ID ||
                chainId == _HARDHAT_CHAIN_ID,
            "DPE_C: testnet only"
        );
    }

    function setCollateralBalance(address trader, int256 balance) external {
        accountInfos[trader].vaultInfo.collateralBalance = balance;
    }
}