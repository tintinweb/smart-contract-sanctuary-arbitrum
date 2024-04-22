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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
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
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
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
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
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
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
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
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
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
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
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
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
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
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
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
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
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
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
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
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
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
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
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
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
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
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
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
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
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
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
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
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
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
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
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
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
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
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
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
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
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
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
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
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
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
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
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
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
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
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { DCSProduct, DCSVault } from "./cega-strategies/dcs/DCSStructs.sol";
import { FCNProduct, FCNVault } from "./cega-strategies/fcn/FCNStructs.sol";
import { IOracleEntry } from "./oracle-entry/interfaces/IOracleEntry.sol";

uint32 constant DCS_STRATEGY_ID = 1;
uint32 constant FCN_STRATEGY_ID = 2;

struct DepositQueue {
    uint128 queuedDepositsTotalAmount;
    uint128 processedIndex;
    mapping(address => uint128) amounts;
    address[] depositors;
    mapping(address => bool) depositorExists;
}

struct Withdrawer {
    address account;
    uint32 nextProductId;
}

struct ProductMetadata {
    string name;
    string tradeWinnerNftImage;
}

struct WithdrawalQueue {
    uint128 queuedWithdrawalSharesAmount;
    uint128 processedIndex;
    mapping(address => mapping(uint32 => uint256)) amounts;
    Withdrawer[] withdrawers;
    mapping(address => bool) withdrawingWithProxy;
}

struct CegaGlobalStorage {
    // Global information
    uint32 strategyIdCounter;
    uint32 productIdCounter;
    uint32[] strategyIds;
    mapping(uint32 => uint32) strategyOfProduct;
    mapping(uint32 => ProductMetadata) productMetadata;
    mapping(address => Vault) vaults;
    // DCS information
    mapping(uint32 => DCSProduct) dcsProducts;
    // Shared
    mapping(uint32 => DepositQueue) depositQueues;
    // DCS information
    mapping(address => DCSVault) dcsVaults;
    // Shared
    mapping(address => WithdrawalQueue) withdrawalQueues;
    // vaultAddress => (asset/s hash => timestamp => price)
    mapping(address => mapping(bytes32 => mapping(uint40 => uint128))) oraclePriceOverride;
    // this will be a bitmap that has all the configs for pausing
    uint256 protocolPauseConfig;
    // FCN information
    mapping(uint32 => FCNProduct) fcnProducts;
    mapping(address => FCNVault) fcnVaults;
    mapping(address => bool) fcnBondAllowList;
}

struct Vault {
    uint128 totalAssets;
    uint64 auctionWinnerTokenId;
    uint16 yieldFeeBps;
    uint16 managementFeeBps;
    uint32 productId;
    address auctionWinner;
    uint40 tradeStartDate;
    VaultStatus vaultStatus;
    IOracleEntry.DataSource dataSource;
    bool isInDispute;
    bool isDefaulted;
}

enum OldVaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    PreAuction,
    Auctioned,
    Traded,
    AwaitingSettlement,
    Settled,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct MMNFTMetadata {
    address vaultAddress;
    uint40 tradeStartDate;
    uint40 tradeEndDate;
    uint16 aprBps;
    uint128 notional;
    uint128 initialSpotPrice;
    uint128 strikePrice;
}

struct VaultCreationParams {
    string tokenName;
    string tokenSymbol;
    uint16 yieldFeeBps;
    uint16 managementFeeBps;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IACLManager {
    /**
     * @notice Sets the admin role for a specific role.
     * @param role The role for which to set the admin.
     * @param adminRole The admin role to be set for the specified role.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new Cega Admin.
     * @param admin The address to be granted Cega Admin role.
     */
    function addCegaAdmin(address admin) external;

    /**
     * @notice Removes a Cega Admin.
     * @param admin The address to be removed from Cega Admin role.
     */
    function removeCegaAdmin(address admin) external;

    /**
     * @notice Adds a new Trader Admin.
     * @param admin The address to be granted Trader Admin role.
     */
    function addTraderAdmin(address admin) external;

    /**
     * @notice Removes a Trader Admin.
     * @param admin The address to be removed from Trader Admin role.
     */
    function removeTraderAdmin(address admin) external;

    /**
     * @notice Adds a new Operator Admin.
     * @param admin The address to be granted Operator Admin role.
     */
    function addOperatorAdmin(address admin) external;

    /**
     * @notice Removes an Operator Admin.
     * @param admin The address to be removed from Operator Admin role.
     */
    function removeOperatorAdmin(address admin) external;

    /**
     * @notice Adds a new Service Admin.
     * @param admin The address to be granted Service Admin role.
     */
    function addServiceAdmin(address admin) external;

    /**
     * @notice Removes a Service Admin.
     * @param admin The address to be removed from Service Admin role.
     */
    function removeServiceAdmin(address admin) external;

    /**
     * @notice Checks if an address is a Cega Admin.
     * @param admin The address to check for Cega Admin role.
     * @return bool True if the address is a Cega Admin, false otherwise.
     */
    function isCegaAdmin(address admin) external view returns (bool);

    /**
     * @notice Checks if an address is a Trader Admin.
     * @param admin The address to check for Trader Admin role.
     * @return bool True if the address is a Trader Admin, false otherwise.
     */
    function isTraderAdmin(address admin) external view returns (bool);

    /**
     * @notice Checks if an address is an Operator Admin.
     * @param admin The address to check for Operator Admin role.
     * @return bool True if the address is an Operator Admin, false otherwise.
     */
    function isOperatorAdmin(address admin) external view returns (bool);

    /**
     * @notice Checks if an address is a Service Admin.
     * @param admin The address to check for Service Admin role.
     * @return bool True if the address is a Service Admin, false otherwise.
     */
    function isServiceAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import { ICegaEntry } from "../../cega-entry/interfaces/ICegaEntry.sol";

interface IAddressManager {
    /**
     * @dev Emitted when a new CegaEntry is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationParams The params of the implementation update
     */
    event CegaEntryCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        ICegaEntry.ProxyImplementation[] indexed implementationParams
    );

    /**
     * @dev Emitted when the CegaEntry is updated.
     * @param implementationParams The old address of the CegaEntry
     * @param _init The new address to call upon upgrade
     * @param _calldata The calldata input for the call
     */
    event CegaEntryUpdated(
        ICegaEntry.ProxyImplementation[] indexed implementationParams,
        address _init,
        bytes _calldata
    );

    /**
     * @dev Emitted when a new address is set
     * @param id The identifier of the proxy
     * @param oldAddress The previous address assoicated with the id
     * @param newAddress The new address set to the id
     */
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when asset wrapping proxy is updated
     * @param asset The address of the asset.
     * @param proxy The address of the new proxy.
     */
    event AssetProxyUpdated(address asset, address proxy);

    /**
     * @dev Returns the address of the Cega Oracle.
     * @return The address of the Cega Oracle.
     */
    function getCegaOracle() external view returns (address);

    /**
     * @dev Returns the address of the Cega Entry.
     * @return The address of the Cega Entry.
     */
    function getCegaEntry() external view returns (address);

    /**
     * @dev Returns the address of the Trade Winner NFT.
     * @return The address of the Trade Winner NFT.
     */
    function getTradeWinnerNFT() external view returns (address);

    /**
     * @dev Returns the address of the ACL Manager.
     * @return The address of the ACL Manager.
     */
    function getACLManager() external view returns (address);

    /**
     * @dev Returns the address of the Redeposit Manager.
     * @return The address of the Redeposit Manager.
     */
    function getRedepositManager() external view returns (address);

    /**
     * @dev Returns the address of the Cega Fee Receiver.
     * @return The address of the Cega Fee Receiver.
     */
    function getCegaFeeReceiver() external view returns (address);

    /**
     * @dev Retrieves the address associated with a given ID.
     * @param id The bytes32 ID.
     * @return The associated address.
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @dev Retrieves the asset wrapping proxy address for a given asset.
     * @param asset The address of the asset.
     * @return The address of the asset wrapping proxy.
     */
    function getAssetWrappingProxy(
        address asset
    ) external view returns (address);

    /**
     * @dev Sets the address of the Cega Entry contract.
     * @param newAddress The new address of the Cega Entry contract.
     */
    function setCegaEntry(address newAddress) external;

    /**
     * @dev Sets the address of the Trade Winner NFT contract.
     * @param newAddress The new address of the Trade Winner NFT contract.
     */
    function setTradeWinnerNFT(address newAddress) external;

    /**
     * @dev Sets the address of the Cega Oracle contract.
     * @param newAddress The new address of the Cega Oracle contract.
     */
    function setCegaOracle(address newAddress) external;

    /**
     * @dev Sets the address of the Redeposit Manager contract.
     * @param newAddress The new address of the Redeposit Manager contract.
     */
    function setRedepositManager(address newAddress) external;

    /**
     * @dev Sets the address of the Cega Fee Receiver address.
     * @param newAddress The new address of the Cega Fee Receiver contract.
     */
    function setCegaFeeReceiver(address newAddress) external;

    /**
     * @dev Sets the address of the ACL Manager contract.
     * @param newAddress The new address of the ACL Manager contract.
     */
    function setACLManager(address newAddress) external;

    /**
     * @dev Sets a new address for a given ID.
     * @param id The bytes32 ID.
     * @param newAddress The new address to be associated with the ID.
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @dev Sets a new asset wrapping proxy for a given asset.
     * @param asset The address of the asset.
     * @param proxy The address of the new proxy.
     */
    function setAssetWrappingProxy(address asset, address proxy) external;

    /**
     * @dev Updates the implementation of the Cega Entry.
     * @param implementationParams An array of new implementation parameters.
     * @param _init The address to call upon upgrade.
     * @param _calldata The calldata input for the call.
     */
    function updateCegaEntryImpl(
        ICegaEntry.ProxyImplementation[] calldata implementationParams,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { MMNFTMetadata } from "../../Structs.sol";

interface ITradeWinnerNFT is IERC721AUpgradeable {
    /**
     * @dev Mints new nft to a given address
     * @param _tokenMetadata The metadata to be stored for the token
     * @return The id of the minted nft
     */
    function mint(
        address to,
        MMNFTMetadata calldata _tokenMetadata
    ) external returns (uint256);

    /**
     * @dev Mints multiple nfts to a given address
     * @param _tokensMetadata The list of metadata to be stored for the each token
     * @return The list ids of the minted nfts
     */
    function mintBatch(
        address to,
        MMNFTMetadata[] calldata _tokensMetadata
    ) external returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

/******************************************************************************\
* EIP-2535: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface ICegaEntry {
    enum ProxyImplementationAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct ProxyImplementation {
        address implAddress;
        ProxyImplementationAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _implementationParams Contains the implementation addresses and function selectors
    /// @param _init The address of the contract or implementation to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        ProxyImplementation[] calldata _implementationParams,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(
        ProxyImplementation[] _diamondCut,
        address _init,
        bytes _calldata
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

struct AddToDepositQueueParams {
    uint32 productId;
    uint128 amount;
    address receiver;
    address depositAsset;
    bool isDepositQueueOpen;
    uint128 minDepositAmount;
    uint128 sumVaultUnderlyingAmounts;
    uint128 maxUnderlyingAmountLimit;
}

struct RemoveFromDepositQueueParams {
    uint32 productId;
    uint128 amount;
    address depositor;
    address depositAsset;
    uint128 minDepositAmount;
}

struct ProcessQueueParams {
    uint32 productId;
    address vaultAddress;
    address depositAsset;
    uint128 sumVaultUnderlyingAmounts;
    uint256 maxProcessCount;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { VaultStatus, OldVaultStatus } from "../../../Structs.sol";

interface ICommonEvents {
    event DepositQueued(
        uint32 indexed productId,
        address sender,
        address receiver,
        uint128 amount
    );

    event DepositRemoved(
        uint32 indexed productId,
        address depositor,
        uint128 amount
    );

    event DepositProcessed(
        address indexed vaultAddress,
        address receiver,
        uint128 amount
    );

    event WithdrawalQueued(
        address indexed vaultAddress,
        uint256 sharesAmount,
        address owner,
        uint32 nextProductId,
        bool withProxy
    );

    event WithdrawalProcessed(
        address indexed vaultAddress,
        uint256 sharesAmount,
        address owner,
        uint32 nextProductId
    );

    event CommonVaultStatusUpdated(
        address indexed vaultAddress,
        VaultStatus vaultStatus
    );

    event VaultDefaultUpdated(address indexed vaultAddress, bool value);

    event OraclePriceOverriden(
        address indexed vaultAddress,
        address indexed asset,
        uint256 timestamp,
        uint256 newPrice
    );

    event ManagementFeeUpdated(address indexed vaultAddress, uint16 value);

    event YieldFeeUpdated(address indexed vaultAddress, uint16 value);

    event ProductNameUpdated(uint32 indexed productId, string name);

    event TradeWinnerNftImageUpdated(uint32 indexed productId, string imageUrl);

    // Legacy event, left for compatibility

    event VaultStatusUpdated(
        address indexed vaultAddress,
        OldVaultStatus vaultStatus
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {
    AddToDepositQueueParams,
    RemoveFromDepositQueueParams,
    ProcessQueueParams
} from "../CommonStructs.sol";
import { CegaStorage } from "../../../storage/CegaStorage.sol";
import { Errors } from "../../../utils/Errors.sol";
import { Transfers } from "../../../utils/Transfers.sol";
import {
    CegaGlobalStorage,
    Vault,
    VaultStatus,
    DepositQueue,
    WithdrawalQueue,
    Withdrawer,
    MMNFTMetadata
} from "../../../Structs.sol";
import { VaultLogic } from "./VaultLogic.sol";
import { ICegaVault } from "../../../vaults/interfaces/ICegaVault.sol";
import { ITreasury } from "../../../treasuries/interfaces/ITreasury.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import { IWrappingProxy } from "../../../proxies/interfaces/IWrappingProxy.sol";
import {
    IRedepositManager
} from "../../../redeposits/interfaces/IRedepositManager.sol";
import { ICommonEvents } from "../interfaces/ICommonEvents.sol";

library ProductLogic {
    using Transfers for address;
    using SafeCast for uint256;

    function addToDepositQueue(
        CegaGlobalStorage storage cgs,
        address treasury,
        AddToDepositQueueParams memory params
    ) internal {
        require(params.isDepositQueueOpen, Errors.DEPOSIT_QUEUE_NOT_OPEN);
        require(
            params.amount >= params.minDepositAmount,
            Errors.VALUE_TOO_SMALL
        );

        DepositQueue storage depositQueue = cgs.depositQueues[params.productId];

        uint128 _queuedDepositsTotalAmount = depositQueue
            .queuedDepositsTotalAmount + params.amount;
        depositQueue.queuedDepositsTotalAmount = _queuedDepositsTotalAmount;
        require(
            params.sumVaultUnderlyingAmounts + _queuedDepositsTotalAmount <=
                params.maxUnderlyingAmountLimit,
            Errors.MAX_DEPOSIT_LIMIT_REACHED
        );

        uint128 currentQueuedAmount = depositQueue.amounts[params.receiver];
        if (currentQueuedAmount == 0) {
            bool exists = depositQueue.depositorExists[params.receiver];
            if (!exists) {
                depositQueue.depositors.push(params.receiver);
                depositQueue.depositorExists[params.receiver] = true;
            }
        }
        depositQueue.amounts[params.receiver] =
            currentQueuedAmount +
            params.amount;

        params.depositAsset.receiveTo(treasury, params.amount);

        emit ICommonEvents.DepositQueued(
            params.productId,
            msg.sender,
            params.receiver,
            params.amount
        );
    }

    function removeFromDepositQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        RemoveFromDepositQueueParams memory params
    ) internal {
        DepositQueue storage depositQueue = cgs.depositQueues[params.productId];

        uint128 queuedAmount = depositQueue.amounts[params.depositor];
        require(queuedAmount > 0, Errors.VALUE_IS_ZERO);

        if (params.amount == 0) {
            params.amount = queuedAmount;
        }

        require(
            params.amount == queuedAmount ||
                queuedAmount - params.amount >= params.minDepositAmount,
            Errors.VALUE_TOO_SMALL
        );

        depositQueue.amounts[params.depositor] = queuedAmount - params.amount;
        depositQueue.queuedDepositsTotalAmount -= params.amount;

        treasury.withdraw(
            params.depositAsset,
            params.depositor,
            params.amount,
            false
        );

        emit ICommonEvents.DepositRemoved(
            params.productId,
            params.depositor,
            params.amount
        );
    }

    function processDepositQueue(
        CegaGlobalStorage storage cgs,
        ProcessQueueParams memory params,
        function(
            CegaGlobalStorage storage,
            uint32,
            uint128
        ) processDepositQueueHook
    ) internal returns (uint256 processCount) {
        Vault storage vaultData = cgs.vaults[params.vaultAddress];
        uint256 totalSupply = ICegaVault(params.vaultAddress).totalSupply();
        uint128 totalAssets = VaultLogic.totalAssets(cgs, params.vaultAddress);

        require(
            vaultData.vaultStatus == VaultStatus.DepositsOpen,
            Errors.INVALID_VAULT_STATUS
        );
        require(
            !(totalAssets == 0 && totalSupply > 0),
            Errors.VAULT_IN_ZOMBIE_STATE
        );

        DepositQueue storage queue = cgs.depositQueues[params.productId];
        uint256 queueLength = queue.depositors.length;
        uint256 index = queue.processedIndex;
        processCount = params.maxProcessCount == 0
            ? queueLength - index
            : Math.min(queueLength - index, params.maxProcessCount);

        uint128 totalDepositsAmount;

        for (uint256 i = 0; i < processCount; i++) {
            address depositor = queue.depositors[index + i];
            uint128 depositAmount = queue.amounts[depositor];
            delete queue.depositorExists[depositor];

            if (depositAmount > 0) {
                totalDepositsAmount += depositAmount;

                uint256 sharesAmount = VaultLogic.convertToShares(
                    totalSupply,
                    totalAssets,
                    VaultLogic.getAssetDecimals(params.depositAsset),
                    depositAmount
                );
                ICegaVault(params.vaultAddress).mint(depositor, sharesAmount);

                delete queue.amounts[depositor];

                emit ICommonEvents.DepositProcessed(
                    params.vaultAddress,
                    depositor,
                    depositAmount
                );
            }
        }
        queue.processedIndex += processCount.toUint128();

        queue.queuedDepositsTotalAmount -= totalDepositsAmount;

        processDepositQueueHook(cgs, params.productId, totalDepositsAmount);

        vaultData.totalAssets = totalAssets + totalDepositsAmount;

        if (processCount + index == queueLength) {
            VaultLogic.setVaultStatus(
                cgs,
                params.vaultAddress,
                VaultStatus.PreAuction
            );
        }
    }

    /**
     * @dev Processes the withdrawal queue for a specific vault.
     * @param cgs The Cega global storage.
     * @param treasury The treasury contract.
     * @param addressManager The address manager.
     * @param vaultAddress The address of the vault.
     * @param maxProcessCount The maximum number of withdrawals to process.
     * @return processCount The number of processed withdrawals.
     */
    function processWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress,
        uint256 maxProcessCount,
        address settlementAsset,
        function(CegaGlobalStorage storage, address, uint128)
            internal postWithdrawalHook
    ) internal returns (uint256 processCount) {
        require(
            VaultLogic.isWithdrawalPossible(cgs, vaultAddress),
            Errors.INVALID_VAULT_STATUS
        );

        Vault storage vaultData = cgs.vaults[vaultAddress];

        uint128 totalAssets = vaultData.totalAssets;
        uint256 totalSupply = ICegaVault(vaultAddress).totalSupply();
        address wrappingProxy = addressManager.getAssetWrappingProxy(
            settlementAsset
        );

        WithdrawalQueue storage queue = cgs.withdrawalQueues[vaultAddress];
        uint256 queueLength = queue.withdrawers.length;
        uint256 index = queue.processedIndex;
        processCount = maxProcessCount == 0
            ? queueLength - index
            : Math.min(queueLength - index, maxProcessCount);
        uint256 totalSharesWithdrawn;
        uint128 totalAssetsWithdrawn;
        uint256 sharesAmount;

        for (uint256 i = 0; i < processCount; i++) {
            Withdrawer memory withdrawer = queue.withdrawers[index + i];
            sharesAmount = queue.amounts[withdrawer.account][
                withdrawer.nextProductId
            ];
            delete queue.amounts[withdrawer.account][withdrawer.nextProductId];
            uint128 assetAmount = processWithdrawal(
                withdrawer.account,
                sharesAmount,
                withdrawer.nextProductId,
                queue.withdrawingWithProxy[withdrawer.account],
                treasury,
                addressManager,
                vaultAddress,
                settlementAsset,
                totalAssets,
                totalSupply,
                wrappingProxy
            );
            totalSharesWithdrawn += sharesAmount;
            totalAssetsWithdrawn += assetAmount;
        }

        ICegaVault(vaultAddress).burn(vaultAddress, totalSharesWithdrawn);
        queue.queuedWithdrawalSharesAmount -= totalSharesWithdrawn.toUint128();
        queue.processedIndex += processCount.toUint128();
        vaultData.totalAssets -= totalAssetsWithdrawn;

        postWithdrawalHook(cgs, vaultAddress, totalAssetsWithdrawn);

        if (index + processCount == queueLength) {
            VaultLogic.setVaultStatus(
                cgs,
                vaultAddress,
                VaultStatus.WithdrawalQueueProcessed
            );
        }
    }

    /**
     * @dev Adds a request to the withdrawal queue for a specific vault or withdraw instatly if possible.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param sharesAmount The amount of shares to withdraw.
     * @param nextProductId The product ID for the next investment cycle, if applicable.
     * @param useProxy Whether to use a proxy for withdrawal.
     */
    function withdrawOrAddToWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy,
        uint128 minWithdrawalAmount,
        address settlementAsset,
        function(CegaGlobalStorage storage, address, uint128)
            internal postWithdrawalHook
    ) internal {
        require(sharesAmount >= minWithdrawalAmount, Errors.VALUE_TOO_SMALL);
        uint256 sharesBalance = ICegaVault(vaultAddress).balanceOf(msg.sender);
        require(
            sharesBalance >= sharesAmount &&
                (sharesBalance - sharesAmount == 0 ||
                    sharesBalance - sharesAmount >= minWithdrawalAmount),
            Errors.REMAINING_VALUE_TOO_SMALL
        );

        require(nextProductId == 0 || !useProxy, Errors.NO_PROXY_FOR_REDEPOSIT);

        if (VaultLogic.isWithdrawalPossible(cgs, vaultAddress)) {
            withdrawInstantly(
                cgs,
                treasury,
                addressManager,
                vaultAddress,
                sharesAmount,
                nextProductId,
                useProxy,
                settlementAsset,
                postWithdrawalHook
            );
        } else {
            addToWithdrawalQueue(
                cgs,
                vaultAddress,
                sharesAmount,
                nextProductId,
                useProxy
            );
        }
    }

    function withdrawInstantly(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy,
        address settlementAsset,
        function(CegaGlobalStorage storage, address, uint128)
            internal postWithdrawalHook
    ) internal {
        Vault storage vaultData = cgs.vaults[vaultAddress];
        uint128 totalAssets = vaultData.totalAssets;
        uint256 totalSupply = ICegaVault(vaultAddress).totalSupply();
        address wrappingProxy = addressManager.getAssetWrappingProxy(
            settlementAsset
        );

        ICegaVault(vaultAddress).burn(msg.sender, sharesAmount);
        uint128 assetAmount = processWithdrawal(
            msg.sender,
            sharesAmount,
            nextProductId,
            useProxy,
            treasury,
            addressManager,
            vaultAddress,
            settlementAsset,
            totalAssets,
            totalSupply,
            wrappingProxy
        );

        vaultData.totalAssets -= assetAmount;

        postWithdrawalHook(cgs, vaultAddress, assetAmount);
    }

    function addToWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy
    ) internal {
        ICegaVault(vaultAddress).transferFrom(
            msg.sender,
            vaultAddress,
            sharesAmount
        );

        WithdrawalQueue storage queue = cgs.withdrawalQueues[vaultAddress];
        uint256 currentQueuedAmount = queue.amounts[msg.sender][nextProductId];
        if (currentQueuedAmount == 0) {
            queue.withdrawers.push(
                Withdrawer({
                    account: msg.sender,
                    nextProductId: nextProductId
                })
            );
        }
        queue.amounts[msg.sender][nextProductId] =
            currentQueuedAmount +
            sharesAmount;
        queue.withdrawingWithProxy[msg.sender] = useProxy;

        queue.queuedWithdrawalSharesAmount += sharesAmount;

        emit ICommonEvents.WithdrawalQueued(
            vaultAddress,
            sharesAmount,
            msg.sender,
            nextProductId,
            useProxy
        );
    }

    function processWithdrawal(
        address account,
        uint256 sharesAmount,
        uint32 nextProductId,
        bool withdrawingWithProxy,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress,
        address settlementAsset,
        uint128 totalAssets,
        uint256 totalSupply,
        address wrappingProxy
    ) private returns (uint128 assetAmount) {
        assetAmount = VaultLogic.convertToAssets(
            totalSupply,
            totalAssets,
            sharesAmount
        );

        if (nextProductId == 0) {
            if (wrappingProxy != address(0) && withdrawingWithProxy) {
                treasury.withdraw(
                    settlementAsset,
                    wrappingProxy,
                    assetAmount,
                    true
                );
                IWrappingProxy(wrappingProxy).unwrapAndTransfer(
                    account,
                    assetAmount
                );
            } else {
                treasury.withdraw(settlementAsset, account, assetAmount, false);
            }
        } else {
            redeposit(
                treasury,
                addressManager,
                settlementAsset,
                assetAmount,
                account,
                nextProductId
            );
        }

        emit ICommonEvents.WithdrawalProcessed(
            vaultAddress,
            sharesAmount,
            account,
            nextProductId
        );
    }

    function redeposit(
        ITreasury treasury,
        IAddressManager addressManager,
        address asset,
        uint128 amount,
        address owner,
        uint32 nextProductId
    ) private {
        address redepositManager = addressManager.getRedepositManager();
        // TODO add code for redeposit
        IRedepositManager(redepositManager).redeposit(
            treasury,
            nextProductId,
            asset,
            amount,
            owner
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    IERC20Metadata,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { CegaGlobalStorage, Vault, VaultStatus } from "../../../Structs.sol";
import { ICommonEvents } from "../interfaces/ICommonEvents.sol";
import { Errors } from "../../../utils/Errors.sol";

library VaultLogic {
    using SafeCast for uint256;

    // CONSTANTS

    uint128 internal constant DAYS_IN_YEAR = 365;

    uint128 internal constant BPS_DECIMALS = 1e4;

    uint8 internal constant VAULT_DECIMALS = 18;

    uint8 internal constant NATIVE_ASSET_DECIMALS = 18;

    // FUNCTIONS

    /**
     * @notice Retrieves the decimals for a given asset.
     * @param asset The address of the asset.
     * @return uint8 The number of decimals of the asset.
     */
    function getAssetDecimals(address asset) internal view returns (uint8) {
        return
            asset == address(0)
                ? NATIVE_ASSET_DECIMALS
                : IERC20Metadata(asset).decimals();
    }

    /**
     * @notice Retrieves the total assets of a given vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @return uint128 The total assets of the vault.
     */
    function totalAssets(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (uint128) {
        return cgs.vaults[vaultAddress].totalAssets;
    }

    /**
     * @notice Converts share amount to equivalent asset amount.
     * @param _totalSupply The total supply of shares in the vault.
     * @param _totalAssets The total assets held in the vault.
     * @param _shares The number of shares to convert.
     * @return uint128 The equivalent asset amount.
     */
    function convertToAssets(
        uint256 _totalSupply,
        uint128 _totalAssets,
        uint256 _shares
    ) internal pure returns (uint128) {
        // assumption: all assets we support have <= 18 decimals
        return ((_shares * _totalAssets) / _totalSupply).toUint128();
    }

    /**
     * @notice Converts share amount to equivalent asset amount for a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param shares The number of shares to convert.
     * @return uint128 The equivalent asset amount.
     */
    function convertToAssets(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint256 shares
    ) internal view returns (uint128) {
        uint256 _totalSupply = IERC20(vaultAddress).totalSupply();

        if (_totalSupply == 0) return 0;
        // assumption: all assets we support have <= 18 decimals
        // shares and _totalSupply have 18 decimals
        return
            ((shares * totalAssets(cgs, vaultAddress)) / _totalSupply)
                .toUint128();
    }

    /**
     * @notice Converts asset amount to equivalent share amount.
     * @param _totalSupply The total supply of shares in the vault.
     * @param _totalAssets The total assets held in the vault.
     * @param _depositAssetDecimals The decimals of the deposit asset.
     * @param assets The amount of assets to convert.
     * @return uint256 The equivalent share amount.
     */
    function convertToShares(
        uint256 _totalSupply,
        uint128 _totalAssets,
        uint8 _depositAssetDecimals,
        uint128 assets
    ) internal pure returns (uint256) {
        if (_totalAssets == 0 || _totalSupply == 0) {
            return assets * 10 ** (VAULT_DECIMALS - _depositAssetDecimals);
        } else {
            // _totalSupply has 18 decimals, assets and _totalAssets have the same decimals
            return (_totalSupply * assets) / (_totalAssets);
        }
    }

    /**
     * @notice Checks if withdrawals are possible for a given vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @return bool True if withdrawals are possible, false otherwise.
     */
    function isWithdrawalPossible(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (bool) {
        Vault storage vault = cgs.vaults[vaultAddress];

        VaultStatus vaultStatus = vault.vaultStatus;
        if (
            vaultStatus == VaultStatus.FeesCollected ||
            vaultStatus == VaultStatus.WithdrawalQueueProcessed ||
            vaultStatus == VaultStatus.Zombie
        ) {
            return true;
        }

        return (vaultStatus == VaultStatus.Auctioned && vault.isDefaulted);
    }

    /**
     * @notice Determines if a vault has defaulted based on the current date and product parameters.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @return bool True if the vault has defaulted, false otherwise.
     */
    function getIsAuctionDefaulted(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint8 daysToStartAuctionDefault
    ) internal view returns (bool) {
        Vault storage vault = cgs.vaults[vaultAddress];
        if (vault.vaultStatus != VaultStatus.Auctioned) {
            return false;
        }
        uint40 startDate = cgs.vaults[vaultAddress].tradeStartDate;
        uint40 daysLate = getDaysLate(startDate);
        return daysLate >= daysToStartAuctionDefault;
    }

    /**
     * @notice Calculates the number of days that have passed since a given start date.
     * @param startDate The start date.
     * @return uint40 The number of days that have passed.
     */
    function getDaysLate(uint40 startDate) internal view returns (uint40) {
        uint40 currentTime = block.timestamp.toUint40();
        if (currentTime < startDate) {
            return 0;
        } else {
            return (currentTime - startDate) / 1 days;
        }
    }

    /**
     * @notice Calculates the coupon payment for a given set of parameters.
     * @param underlyingAmount The amount of underlying asset.
     * @param tradeStartDate The start date of the trade.
     * @param tenorInSeconds The tenor of the product in seconds.
     * @param aprBps The annual percentage rate in basis points.
     * @param endDate The end date for the coupon payment calculation.
     * @return uint128 The calculated coupon payment.
     */
    function calculateCouponPayment(
        uint128 underlyingAmount,
        uint40 tradeStartDate,
        uint40 tenorInSeconds,
        uint16 aprBps,
        uint40 endDate
    ) internal pure returns (uint128) {
        uint40 secondsPassed = endDate - tradeStartDate;
        uint40 couponSeconds = secondsPassed < tenorInSeconds
            ? secondsPassed
            : tenorInSeconds;
        return
            ((uint256(underlyingAmount) * couponSeconds * aprBps) /
                (DAYS_IN_YEAR * BPS_DECIMALS * 1 days)).toUint128();
    }

    /**
     * @notice Calculates the late fee based on the coupon, start date, and late fee parameters.
     * @param coupon The coupon amount.
     * @param startDate The start date of the period.
     * @param lateFeeBps The late fee in basis points.
     * @param daysToStartLateFees The number of days to start charging late fees.
     * @param daysToStartAuctionDefault The number of days to start auction default.
     * @return uint128 The calculated late fee.
     */
    function calculateLateFee(
        uint128 coupon,
        uint40 startDate,
        uint16 lateFeeBps,
        uint8 daysToStartLateFees,
        uint8 daysToStartAuctionDefault
    ) internal view returns (uint128) {
        uint40 daysLate = getDaysLate(startDate);
        if (daysLate < daysToStartLateFees) {
            return 0;
        } else {
            if (daysLate >= daysToStartAuctionDefault) {
                daysLate = daysToStartAuctionDefault;
            }
            return (coupon * daysLate * lateFeeBps) / (BPS_DECIMALS);
        }
    }

    function calculateFees(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint64 tenorInSeconds,
        uint128 underlyingAmount,
        uint128 totalYield
    ) internal view returns (uint128, uint128, uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];

        uint128 managementFee = (underlyingAmount *
            tenorInSeconds *
            vault.managementFeeBps) / (DAYS_IN_YEAR * 1 days * BPS_DECIMALS);
        uint128 yieldFee = (totalYield * vault.yieldFeeBps) / BPS_DECIMALS;
        uint128 totalFee = managementFee + yieldFee;

        return (totalFee, managementFee, yieldFee);
    }

    /**
     * @notice Sets the status of a vault in the global storage.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param status The new status to be set for the vault.
     */
    function setVaultStatus(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        VaultStatus status
    ) internal {
        cgs.vaults[vaultAddress].vaultStatus = status;

        emit ICommonEvents.CommonVaultStatusUpdated(vaultAddress, status);
    }

    function setIsDefaulted(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        bool value
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];

        vault.isDefaulted = value;

        emit ICommonEvents.VaultDefaultUpdated(vaultAddress, value);
    }

    /**
     * @notice Opens a vault for deposits.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     */
    function openVaultDeposits(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal {
        require(
            cgs.vaults[vaultAddress].vaultStatus == VaultStatus.DepositsClosed,
            Errors.INVALID_VAULT_STATUS
        );
        setVaultStatus(cgs, vaultAddress, VaultStatus.DepositsOpen);
    }

    function getAssetCode(address asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(asset));
    }

    /**
     * @notice Overrides the oracle price for a specific vault and timestamp.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param timestamp The timestamp for which the price is overridden.
     * @param newPrice The new price to override.
     */
    function overrideOraclePrice(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        address asset,
        uint40 timestamp,
        uint128 newPrice
    ) internal {
        require(newPrice != 0, Errors.INVALID_PRICE);

        cgs.oraclePriceOverride[vaultAddress][getAssetCode(asset)][
            timestamp
        ] = newPrice;

        emit ICommonEvents.OraclePriceOverriden(
            vaultAddress,
            asset,
            timestamp,
            newPrice
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

enum DCSOptionType {
    BuyLow,
    SellHigh
}

enum SettlementStatus {
    NotAuctioned,
    Auctioned,
    InitialPremiumPaid,
    AwaitingSettlement,
    Settled,
    Defaulted
}

struct DCSProductCreationParams {
    uint128 maxUnderlyingAmountLimit;
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    address quoteAssetAddress;
    address baseAssetAddress;
    DCSOptionType dcsOptionType;
    uint8 daysToStartLateFees;
    uint8 daysToStartAuctionDefault;
    uint8 daysToStartSettlementDefault;
    uint16 lateFeeBps;
    uint16 strikeBarrierBps;
    uint40 tenorInSeconds;
    uint8 disputePeriodInHours;
    uint8 disputeGraceDelayInHours;
    string name;
    string tradeWinnerNftImage;
}

struct DCSProduct {
    uint128 maxUnderlyingAmountLimit;
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    uint128 sumVaultUnderlyingAmounts; //revisit later
    address quoteAssetAddress; // should be immutable
    uint40 tenorInSeconds;
    uint16 lateFeeBps;
    uint8 daysToStartLateFees;
    address baseAssetAddress; // should be immutable
    uint16 strikeBarrierBps;
    uint8 daysToStartAuctionDefault;
    uint8 daysToStartSettlementDefault;
    uint8 disputePeriodInHours;
    DCSOptionType dcsOptionType;
    bool isDepositQueueOpen;
    address[] vaults;
    uint8 disputeGraceDelayInHours;
}

struct DCSVault {
    uint128 initialSpotPrice;
    uint128 strikePrice;
    uint128 totalYield;
    uint16 aprBps;
    SettlementStatus settlementStatus; // DEPRECATED
    bool isPayoffInDepositAsset;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { ICommonEvents } from "../../common/interfaces/ICommonEvents.sol";
import { VaultCreationParams } from "../../../Structs.sol";
import { SettlementStatus } from "../DCSStructs.sol";

interface IDCSEvents is ICommonEvents {
    event DCSProductCreated(uint32 indexed productId);

    event DCSVaultFeesCollected(
        address indexed vaultAddress,
        uint128 totalFees,
        uint128 managementFee,
        uint128 yieldFee
    );

    event DCSVaultCreated(
        uint32 indexed productId,
        address indexed vaultAddress,
        VaultCreationParams params
    );

    event DCSAuctionEnded(
        address indexed vaultAddress,
        address indexed auctionWinner,
        uint40 tradeStartDate,
        uint16 aprBps,
        uint128 initialSpotPrice,
        uint128 strikePrice
    );

    event DCSTradeStarted(
        address indexed vaultAddress,
        address auctionWinner,
        uint128 notionalAmount,
        uint128 yieldAmount
    );

    event DCSLateFeePaid(address indexed vaultAddress, uint128 feeAmount);

    event DCSVaultSettled(
        address indexed vaultAddress,
        address settler,
        uint128 depositedAmount,
        uint128 withdrawnAmount
    );

    event DCSVaultRolledOver(address indexed vaultAddress);

    event DCSIsPayoffInDepositAssetUpdated(
        address indexed vaultAddress,
        bool isPayoffInDepositAsset
    );

    event DCSLateFeeBpsUpdated(uint32 indexed productId, uint16 lateFeeBps);

    event DCSMinDepositAmountUpdated(
        uint32 indexed productId,
        uint128 minDepositAmount
    );

    event DCSMinWithdrawalAmountUpdated(
        uint32 indexed productId,
        uint128 minWithdrawalAmount
    );

    event DCSIsDepositQueueOpenUpdated(
        uint32 indexed productId,
        bool isDepositQueueOpen
    );

    event DCSMaxUnderlyingAmountLimitUpdated(
        uint32 indexed productId,
        uint128 maxUnderlyingAmountLimit
    );

    event DCSManagementFeeUpdated(address indexed vaultAddress, uint16 value);

    event DCSYieldFeeUpdated(address indexed vaultAddress, uint16 value);

    event DCSDisputeSubmitted(address indexed vaultAddress);

    event DCSDisputeProcessed(
        address indexed vaultAddress,
        bool isDisputeAccepted,
        uint40 timestamp,
        uint128 newPrice
    );

    event DCSDisputePeriodInHoursUpdated(
        uint32 indexed productId,
        uint8 disputePeriodInHours
    );

    event DCSDisputeGraceDelayInHoursUpdated(
        uint32 indexed productId,
        uint8 disputeGraceDelayInHours
    );

    event DCSDaysToStartLateFeesUpdated(
        uint32 indexed productId,
        uint8 daysToStartLateFees
    );

    event DCSDaysToStartAuctionDefaultUpdated(
        uint32 indexed productId,
        uint8 daysToStartAuctionDefault
    );

    event DCSDaysToStartSettlementDefaultUpdated(
        uint32 indexed productId,
        uint8 daysToStartSettlementDefault
    );

    // Legacy events, left for compatibility

    event VaultCreated(
        uint32 indexed productId,
        address indexed vaultAddress,
        string _tokenSymbol,
        string _tokenName
    );

    event DCSSettlementStatusUpdated(
        address indexed vaultAddress,
        SettlementStatus settlementStatus
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {
    IERC721AUpgradeable
} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

import {
    CegaGlobalStorage,
    Vault,
    VaultStatus,
    DepositQueue,
    WithdrawalQueue,
    Withdrawer,
    MMNFTMetadata
} from "../../../Structs.sol";
import {
    AddToDepositQueueParams,
    RemoveFromDepositQueueParams,
    ProcessQueueParams
} from "../../common/CommonStructs.sol";
import { ITradeWinnerNFT } from "../../../aux/interfaces/ITradeWinnerNFT.sol";
import { DCSProduct, DCSVault, DCSOptionType } from "../DCSStructs.sol";
import { Transfers } from "../../../utils/Transfers.sol";
import { Errors } from "../../../utils/Errors.sol";
import { AddressManagement } from "../../../utils/AddressManagement.sol";
import { DCSVaultLogic } from "./DCSVaultLogic.sol";
import { VaultLogic } from "../../common/lib/VaultLogic.sol";
import { ProductLogic } from "../../common/lib/ProductLogic.sol";
import { ICegaVault } from "../../../vaults/interfaces/ICegaVault.sol";
import { ITreasury } from "../../../treasuries/interfaces/ITreasury.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import {
    IRedepositManager
} from "../../../redeposits/interfaces/IRedepositManager.sol";
import { IWrappingProxy } from "../../../proxies/interfaces/IWrappingProxy.sol";
import { ISwapManager } from "../../../swaps/interfaces/ISwapManager.sol";
import { IDCSEvents } from "../interfaces/IDCSEvents.sol";

library DCSLogic {
    using Transfers for address;
    using SafeCast for uint256;
    using AddressManagement for IAddressManager;

    // CONSTANTS

    uint128 private constant BPS_DECIMALS = 1e4;

    // MODIFIERS

    modifier onlyValidVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) {
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
        _;
    }

    // VIEW FUNCTIONS

    /**
     * @dev Retrieves the deposit asset for a given DCS product.
     * @param dcsProduct The DCS product.
     * @return The address of the deposit asset.
     */
    function dcsGetProductDepositAsset(
        DCSProduct storage dcsProduct
    ) internal view returns (address) {
        return
            dcsProduct.dcsOptionType == DCSOptionType.BuyLow
                ? dcsProduct.quoteAssetAddress
                : dcsProduct.baseAssetAddress;
    }

    /**
     * @dev Gets the deposit and swap assets for a given DCS product.
     * @param dcsProduct The DCS product.
     * @return depositAsset The address of the deposit asset.
     * @return swapAsset The address of the swap asset.
     * @return dcsOptionType The option type of the DCS product.
     */
    function getDCSProductDepositAndSwapAsset(
        DCSProduct storage dcsProduct
    )
        internal
        view
        returns (
            address depositAsset,
            address swapAsset,
            DCSOptionType dcsOptionType
        )
    {
        dcsOptionType = dcsProduct.dcsOptionType;

        if (dcsOptionType == DCSOptionType.BuyLow) {
            depositAsset = dcsProduct.quoteAssetAddress;
            swapAsset = dcsProduct.baseAssetAddress;
        } else {
            depositAsset = dcsProduct.baseAssetAddress;
            swapAsset = dcsProduct.quoteAssetAddress;
        }
    }

    /**
     * @dev Retrieves the settlement asset for a given vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @return address The address of the settlement asset.
     */
    function getVaultSettlementAsset(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (address) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        if (dcsProduct.dcsOptionType == DCSOptionType.BuyLow) {
            return
                dcsVault.isPayoffInDepositAsset
                    ? dcsProduct.quoteAssetAddress
                    : dcsProduct.baseAssetAddress;
        } else {
            return
                dcsVault.isPayoffInDepositAsset
                    ? dcsProduct.baseAssetAddress
                    : dcsProduct.quoteAssetAddress;
        }
    }

    /**
     * @dev Gets the spot price at a given timestamp.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param addressManager The address manager.
     * @param priceTimestamp The timestamp for the price.
     * @return The spot price at the given timestamp.
     */
    function getSpotPriceAt(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        IAddressManager addressManager,
        uint40 priceTimestamp
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        uint128 price = cgs.oraclePriceOverride[vaultAddress][
            VaultLogic.getAssetCode(address(0))
        ][priceTimestamp];

        if (price > 0) {
            return price;
        }

        IOracleEntry iOracleEntry = IOracleEntry(
            addressManager.getCegaOracle()
        );

        // We always use baseAsset, even if the deposit asset is quote asset, because we
        // need to express the units of quote asset in terms of base asset
        return
            iOracleEntry.getPrice(
                dcsProduct.baseAssetAddress,
                dcsProduct.quoteAssetAddress,
                priceTimestamp,
                vault.dataSource
            );
    }

    /**
     * @dev Converts deposit units to swap asset units.
     * @param amountToConvert The amount to convert.
     * @param addressManager The address manager.
     * @param conversionPrice The conversion price.
     * @param depositAssetDecimals The decimals of the deposit asset.
     * @param swapAssetDecimals The decimals of the swap asset.
     * @param dcsOptionType The DCS option type.
     * @return uint128 The converted amount.
     */
    function convertDepositUnitsToSwap(
        uint256 amountToConvert,
        IAddressManager addressManager,
        uint128 conversionPrice,
        uint8 depositAssetDecimals,
        uint8 swapAssetDecimals,
        DCSOptionType dcsOptionType
    ) internal view returns (uint128) {
        IOracleEntry iOracleEntry = IOracleEntry(
            addressManager.getCegaOracle()
        );

        // Calculating the notionalInSwapAsset is different because finalSpotPrice is always
        // in units of quote / base.
        uint256 convertedAmount;
        if (dcsOptionType == DCSOptionType.BuyLow) {
            convertedAmount =
                (
                    (amountToConvert *
                        10 **
                            (swapAssetDecimals +
                                iOracleEntry.getTargetDecimals()))
                ) /
                (conversionPrice * 10 ** depositAssetDecimals);
        } else {
            convertedAmount = ((amountToConvert *
                conversionPrice *
                10 ** (swapAssetDecimals)) /
                (10 **
                    (depositAssetDecimals + iOracleEntry.getTargetDecimals())));
        }
        return convertedAmount.toUint128();
    }

    /**
     * @dev Checks if a swap is occurring based on option type and price conditions.
     * @param finalSpotPrice The final spot price.
     * @param strikePrice The strike price.
     * @param dcsOptionType The DCS option type.
     * @return bool True if a swap is occurring, false otherwise.
     */
    function isSwapOccurring(
        uint128 finalSpotPrice,
        uint128 strikePrice,
        DCSOptionType dcsOptionType
    ) internal pure returns (bool) {
        if (dcsOptionType == DCSOptionType.BuyLow) {
            return finalSpotPrice < strikePrice;
        } else {
            return finalSpotPrice > strikePrice;
        }
    }

    /**
     * @dev Calculates the final payoff for a vault.
     * @param cgs The Cega global storage.
     * @param addressManager The address manager.
     * @param vaultAddress The address of the vault.
     * @return uint128 The final payoff amount.
     */
    function calculateVaultFinalPayoff(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        require(
            vault.vaultStatus == VaultStatus.AwaitingSettlement ||
                vault.vaultStatus == VaultStatus.Settled,
            Errors.INVALID_VAULT_STATUS
        );

        if (
            !dcsVault.isPayoffInDepositAsset &&
            vault.vaultStatus != VaultStatus.Settled
        ) {
            (
                address depositAsset,
                address swapAsset,

            ) = getDCSProductDepositAndSwapAsset(dcsProduct);
            uint8 depositAssetDecimals = VaultLogic.getAssetDecimals(
                depositAsset
            );
            uint8 swapAssetDecimals = VaultLogic.getAssetDecimals(swapAsset);

            return
                convertDepositUnitsToSwap(
                    vault.totalAssets,
                    addressManager,
                    dcsVault.strikePrice,
                    depositAssetDecimals,
                    swapAssetDecimals,
                    dcsProduct.dcsOptionType
                );
        } else {
            // totalAssets already has totalYield included inside, because premium is paid upfront
            return vault.totalAssets;
        }
    }

    // MUTATIVE FUNCTIONS

    function endAuction(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress,
        address _auctionWinner,
        uint40 _tradeStartDate,
        uint16 _aprBps,
        IOracleEntry.DataSource _dataSource
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        VaultStatus vaultStatus = vault.vaultStatus;

        require(
            vaultStatus == VaultStatus.PreAuction ||
                vaultStatus == VaultStatus.Auctioned,
            Errors.INVALID_VAULT_STATUS
        );

        require(_tradeStartDate != 0, Errors.VALUE_IS_ZERO);

        vault.auctionWinner = _auctionWinner;
        vault.tradeStartDate = _tradeStartDate;
        vault.dataSource = _dataSource;

        dcsVault.aprBps = _aprBps;
        uint128 initialSpotPrice = getSpotPriceAt(
            cgs,
            vaultAddress,
            addressManager,
            vault.tradeStartDate
        );
        dcsVault.initialSpotPrice = initialSpotPrice;

        uint128 strikePrice = (dcsVault.initialSpotPrice *
            dcsProduct.strikeBarrierBps) / BPS_DECIMALS;
        dcsVault.strikePrice = strikePrice;

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Auctioned);

        emit IDCSEvents.DCSAuctionEnded(
            vaultAddress,
            _auctionWinner,
            _tradeStartDate,
            _aprBps,
            initialSpotPrice,
            strikePrice
        );
    }

    /**
     * @dev Checks for trade expiry for a specific vault.
     * @param cgs The Cega global storage.
     * @param addressManager The address manager.
     * @param vaultAddress The address of the vault.
     */
    function checkTradeExpiry(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        VaultStatus vaultStatus = vault.vaultStatus;

        if (
            (vaultStatus != VaultStatus.Traded &&
                vaultStatus != VaultStatus.AwaitingSettlement) ||
            vault.isInDispute
        ) {
            return;
        }

        uint40 tenorInSeconds = dcsProduct.tenorInSeconds;
        uint40 tradeStartDate = vault.tradeStartDate;
        uint256 currentTime = block.timestamp;
        if (currentTime <= tradeStartDate + tenorInSeconds) {
            return;
        }

        uint128 finalSpotPrice = getSpotPriceAt(
            cgs,
            vaultAddress,
            addressManager,
            tradeStartDate + tenorInSeconds
        );
        if (
            isSwapOccurring(
                finalSpotPrice,
                dcsVault.strikePrice,
                dcsProduct.dcsOptionType
            )
        ) {
            DCSVaultLogic.setIsPayoffInDepositAsset(cgs, vaultAddress, false);

            VaultLogic.setVaultStatus(
                cgs,
                vaultAddress,
                VaultStatus.AwaitingSettlement
            );
        } else {
            VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Settled);
        }
    }

    /**
     * @dev Checks for settlement default for a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     */
    function checkSettlementDefault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        uint256 daysLate = VaultLogic.getDaysLate(
            vault.tradeStartDate + dcsProduct.tenorInSeconds
        );
        if (
            daysLate >= dcsProduct.daysToStartSettlementDefault &&
            vault.vaultStatus == VaultStatus.AwaitingSettlement
        ) {
            VaultLogic.setIsDefaulted(cgs, vaultAddress, true);
            DCSVaultLogic.setIsPayoffInDepositAsset(cgs, vaultAddress, true);
        }
    }

    /**
     * @dev Starts a trade for a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param tradeWinnerNFT The address of the trade winner NFT contract.
     * @param treasury The treasury contract.
     * @param addressManager The address manager.
     * @return nativeValueReceived The native value received.
     * @return nftMetadata The metadata for the minted NFT.
     */
    function startTrade(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        address tradeWinnerNFT,
        ITreasury treasury,
        IAddressManager addressManager
    )
        internal
        onlyValidVault(cgs, vaultAddress)
        returns (uint256 nativeValueReceived, MMNFTMetadata memory nftMetadata)
    {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        uint40 tenorInSeconds = dcsProduct.tenorInSeconds;

        require(msg.sender == vault.auctionWinner, Errors.NOT_TRADE_WINNER);
        require(
            vault.vaultStatus == VaultStatus.Auctioned,
            Errors.INVALID_VAULT_STATUS
        );
        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        require(
            block.timestamp >= vault.tradeStartDate,
            Errors.TRADE_NOT_STARTED
        );
        require(
            !VaultLogic.getIsAuctionDefaulted(
                cgs,
                vaultAddress,
                dcsProduct.daysToStartAuctionDefault
            ),
            Errors.TRADE_DEFAULTED
        );

        // Transfer the premium + any applicable late fee
        uint40 tradeStartDate = vault.tradeStartDate;
        address depositAsset = dcsGetProductDepositAsset(dcsProduct);
        uint128 totalAssets = vault.totalAssets;
        uint16 aprBps = dcsVault.aprBps;

        nftMetadata = MMNFTMetadata({
            vaultAddress: vaultAddress,
            tradeStartDate: tradeStartDate,
            tradeEndDate: tradeStartDate + tenorInSeconds,
            notional: totalAssets,
            aprBps: aprBps,
            initialSpotPrice: dcsVault.initialSpotPrice,
            strikePrice: dcsVault.strikePrice
        });

        uint128 totalYield = VaultLogic.calculateCouponPayment(
            totalAssets,
            tradeStartDate,
            tenorInSeconds,
            aprBps,
            tradeStartDate + tenorInSeconds
        );
        dcsVault.totalYield = totalYield;
        uint128 lateFee = VaultLogic.calculateLateFee(
            totalYield,
            tradeStartDate,
            dcsProduct.lateFeeBps,
            dcsProduct.daysToStartLateFees,
            dcsProduct.daysToStartAuctionDefault
        );
        // Send deposit to treasury, and late fee to fee recipient
        if (lateFee > 0) {
            nativeValueReceived = depositAsset.receiveTo(
                addressManager.getCegaFeeReceiver(),
                lateFee
            );
            emit IDCSEvents.DCSLateFeePaid(vaultAddress, lateFee);
        }

        nativeValueReceived += depositAsset.receiveTo(
            address(treasury),
            totalYield
        );
        // Late fee is not used for coupon payment or for user payouts
        uint128 notionalAmount = vault.totalAssets;
        vault.totalAssets = notionalAmount + totalYield;
        dcsProduct.sumVaultUnderlyingAmounts += totalYield;

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Traded);

        if (tradeWinnerNFT != address(0)) {
            uint256 tokenId = ITradeWinnerNFT(tradeWinnerNFT).mint(
                msg.sender,
                nftMetadata
            );
            vault.auctionWinnerTokenId = tokenId.toUint64();
        }

        emit IDCSEvents.DCSTradeStarted(
            vaultAddress,
            msg.sender,
            notionalAmount,
            totalYield
        );
    }

    /**
     * @dev Checks for auction default for a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     */
    function checkAuctionDefault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        uint32 productId = cgs.vaults[vaultAddress].productId;

        bool isDefaulted = VaultLogic.getIsAuctionDefaulted(
            cgs,
            vaultAddress,
            cgs.dcsProducts[productId].daysToStartAuctionDefault
        );
        if (isDefaulted) {
            VaultLogic.setIsDefaulted(cgs, vaultAddress, true);
        }
    }

    /**
     * @dev Settles a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param treasury The treasury contract.
     * @param addressManager The address manager.
     * @return nativeValueReceived The native value received.
     */
    function settleVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        ITreasury treasury,
        IAddressManager addressManager
    )
        internal
        onlyValidVault(cgs, vaultAddress)
        returns (uint256 nativeValueReceived)
    {
        (
            address depositAsset,
            address swapAsset,
            uint128 depositTotalAssets,
            uint128 convertedTotalAssets
        ) = prepareSettleVault(cgs, addressManager, vaultAddress);

        // After converting units, we actually transfer the depositAsset to nftHolder and receive swapAsset from nftHolder
        treasury.withdraw(depositAsset, msg.sender, depositTotalAssets, false);
        nativeValueReceived = swapAsset.receiveTo(
            address(treasury),
            convertedTotalAssets
        );

        emit IDCSEvents.DCSVaultSettled(
            vaultAddress,
            msg.sender,
            convertedTotalAssets,
            depositTotalAssets
        );
    }

    function swapAndSettleVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        ISwapManager.SwapProtocol swapProtocol,
        ISwapManager.SwapData calldata swapData,
        ITreasury treasury,
        IAddressManager addressManager
    )
        internal
        onlyValidVault(cgs, vaultAddress)
        returns (uint256 nativeValueReceived)
    {
        (
            address depositAsset,
            address swapAsset,
            uint128 depositTotalAssets,
            uint128 convertedTotalAssets
        ) = prepareSettleVault(cgs, addressManager, vaultAddress);

        ISwapManager swapManager = ISwapManager(
            addressManager.getSwapManager()
        );
        treasury.withdraw(
            depositAsset,
            swapManager.swapProtocolAdapters(swapProtocol),
            depositTotalAssets,
            true
        );
        uint128 outputAmount = ISwapManager(swapManager).swap(
            depositAsset,
            swapAsset,
            depositTotalAssets,
            address(treasury),
            swapProtocol,
            swapData
        );

        if (outputAmount > convertedTotalAssets) {
            treasury.withdraw(
                swapAsset,
                msg.sender,
                outputAmount - convertedTotalAssets,
                false
            );
        } else if (outputAmount < convertedTotalAssets) {
            nativeValueReceived = swapAsset.receiveTo(
                address(treasury),
                convertedTotalAssets - outputAmount
            );
        }

        emit IDCSEvents.DCSVaultSettled(
            vaultAddress,
            msg.sender,
            convertedTotalAssets,
            depositTotalAssets
        );
    }

    function prepareSettleVault(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address vaultAddress
    )
        internal
        returns (
            address depositAsset,
            address swapAsset,
            uint128 depositTotalAssets,
            uint128 convertedTotalAssets
        )
    {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        {
            uint256 auctionWinnerTokenId = vault.auctionWinnerTokenId;

            require(auctionWinnerTokenId != 0, Errors.TRADE_HAS_NO_WINNER);
            require(
                msg.sender ==
                    IERC721AUpgradeable(addressManager.getTradeWinnerNFT())
                        .ownerOf(auctionWinnerTokenId),
                Errors.NOT_TRADE_WINNER
            );
        }
        require(
            dcsVault.isPayoffInDepositAsset == false,
            Errors.TRADE_NOT_CONVERTED
        );
        require(
            vault.vaultStatus == VaultStatus.AwaitingSettlement,
            Errors.INVALID_VAULT_STATUS
        );

        require(
            block.timestamp >
                vault.tradeStartDate +
                    dcsProduct.tenorInSeconds +
                    (uint256(dcsProduct.disputeGraceDelayInHours) * 1 hours),
            Errors.VALUE_IN_DISPUTE_GRACE_DELAY
        );

        checkSettlementDefault(cgs, vaultAddress);

        require(!vault.isDefaulted, Errors.TRADE_DEFAULTED);

        DCSOptionType dcsOptionType;
        (
            depositAsset,
            swapAsset,
            dcsOptionType
        ) = getDCSProductDepositAndSwapAsset(dcsProduct);

        // First, store the totalAssets and totalYield in depositAsset units
        depositTotalAssets = vault.totalAssets;
        uint128 depositTotalYield = dcsVault.totalYield;
        uint128 strikePrice = dcsVault.strikePrice;
        uint8 depositAssetDecimals = VaultLogic.getAssetDecimals(depositAsset);
        uint8 swapAssetDecimals = VaultLogic.getAssetDecimals(swapAsset);

        // Then, calculate the totalAssets and totalYield in swapAsset units
        convertedTotalAssets = convertDepositUnitsToSwap(
            depositTotalAssets,
            addressManager,
            strikePrice,
            depositAssetDecimals,
            swapAssetDecimals,
            dcsOptionType
        );
        uint128 convertedTotalYield = convertDepositUnitsToSwap(
            depositTotalYield,
            addressManager,
            strikePrice,
            depositAssetDecimals,
            swapAssetDecimals,
            dcsOptionType
        );

        // Then, update state. Store the new converted amounts of totalAssets and totalYield
        // and subtract assets from sumVaultUnderlyingAmounts. We've converted, so this vault
        // no longer applies to sumVaultUnderlyingAmounts
        dcsProduct.sumVaultUnderlyingAmounts -= depositTotalAssets;
        vault.totalAssets = convertedTotalAssets;
        dcsVault.totalYield = convertedTotalYield;

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Settled);
    }

    /**
     * @dev Collects fees from a specific vault.
     * @param cgs The Cega global storage.
     * @param treasury The treasury contract.
     * @param addressManager The address manager.
     * @param vaultAddress The address of the vault.
     */
    function collectVaultFees(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];

        VaultStatus vaultStatus = vault.vaultStatus;
        uint40 tenorInSeconds = dcsProduct.tenorInSeconds;

        require(
            vaultStatus == VaultStatus.Settled ||
                (vaultStatus == VaultStatus.AwaitingSettlement &&
                    vault.isDefaulted),
            Errors.INVALID_VAULT_STATUS
        );

        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);
        require(
            block.timestamp >
                vault.tradeStartDate +
                    tenorInSeconds +
                    (uint256(dcsProduct.disputeGraceDelayInHours) * 1 hours),
            Errors.VALUE_IN_DISPUTE_GRACE_DELAY
        );

        uint128 totalYield = dcsVault.totalYield;

        (
            uint128 totalFees,
            uint128 managementFee,
            uint128 yieldFee
        ) = VaultLogic.calculateFees(
                cgs,
                vaultAddress,
                tenorInSeconds,
                vault.totalAssets - totalYield,
                totalYield
            );

        VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.FeesCollected);
        vault.totalAssets -= totalFees;

        treasury.withdraw(
            getVaultSettlementAsset(cgs, vaultAddress),
            addressManager.getCegaFeeReceiver(),
            totalFees,
            true
        );

        if (dcsVault.isPayoffInDepositAsset) {
            dcsProduct.sumVaultUnderlyingAmounts -= uint128(totalFees);
        }

        emit IDCSEvents.DCSVaultFeesCollected(
            vaultAddress,
            totalFees,
            managementFee,
            yieldFee
        );
    }

    function dcsDecreaseSumVaultUnderlyingAmounts(
        CegaGlobalStorage storage cgs,
        uint32 productId,
        uint128 assetAmount
    ) internal {
        cgs.dcsProducts[productId].sumVaultUnderlyingAmounts -= assetAmount;
    }

    function dcsAddToWithdrawalQueueHook(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 assetAmount
    ) internal {
        if (
            cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset ||
            cgs.vaults[vaultAddress].isDefaulted
        ) {
            cgs
                .dcsProducts[cgs.vaults[vaultAddress].productId]
                .sumVaultUnderlyingAmounts -= assetAmount;
        }
    }

    function dcsProcessDepositQueueHook(
        CegaGlobalStorage storage cgs,
        uint32 productId,
        uint128 totalDepositsAmount
    ) internal {
        cgs
            .dcsProducts[productId]
            .sumVaultUnderlyingAmounts += totalDepositsAmount;
    }

    function addToDepositQueue(
        CegaGlobalStorage storage cgs,
        address treasury,
        uint32 productId,
        uint128 amount,
        address receiver
    ) internal {
        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];
        ProductLogic.addToDepositQueue(
            cgs,
            treasury,
            AddToDepositQueueParams({
                productId: productId,
                amount: amount,
                receiver: receiver,
                depositAsset: dcsGetProductDepositAsset(dcsProduct),
                isDepositQueueOpen: dcsProduct.isDepositQueueOpen,
                minDepositAmount: dcsProduct.minDepositAmount,
                sumVaultUnderlyingAmounts: dcsProduct.sumVaultUnderlyingAmounts,
                maxUnderlyingAmountLimit: dcsProduct.maxUnderlyingAmountLimit
            })
        );
    }

    function removeFromDepositQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        uint32 productId,
        uint128 amount
    ) internal {
        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];
        ProductLogic.removeFromDepositQueue(
            cgs,
            treasury,
            RemoveFromDepositQueueParams({
                productId: productId,
                amount: amount,
                depositor: msg.sender,
                depositAsset: dcsGetProductDepositAsset(dcsProduct),
                minDepositAmount: dcsProduct.minDepositAmount
            })
        );
    }

    function addToWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        ITreasury treasury,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy
    ) internal {
        Vault storage vaultData = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vaultData.productId];
        ProductLogic.withdrawOrAddToWithdrawalQueue(
            cgs,
            treasury,
            addressManager,
            vaultAddress,
            sharesAmount,
            nextProductId,
            useProxy,
            dcsProduct.minWithdrawalAmount,
            getVaultSettlementAsset(cgs, vaultAddress),
            DCSLogic.dcsAddToWithdrawalQueueHook
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    IERC20Metadata,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {
    CegaGlobalStorage,
    Vault,
    VaultStatus,
    MMNFTMetadata
} from "../../../Structs.sol";
import { DCSProduct, DCSVault, DCSOptionType } from "../DCSStructs.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import { IACLManager } from "../../../aux/interfaces/IACLManager.sol";
import { Errors } from "../../../utils/Errors.sol";
import { VaultLogic } from "../../common/lib/VaultLogic.sol";
import { IDCSEvents, ICommonEvents } from "../interfaces/IDCSEvents.sol";

library DCSVaultLogic {
    using SafeCast for uint256;

    // MODIFIERS

    modifier onlyValidVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) {
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
        _;
    }

    // VIEW FUNCTIONS

    /**
     * @notice Calculates the current yield of a vault up to a specified end date.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param endDate The end date for the yield calculation.
     * @return uint128 The calculated yield.
     */
    function getCurrentYield(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint40 endDate
    ) internal view returns (uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        return
            VaultLogic.calculateCouponPayment(
                vault.totalAssets - dcsVault.totalYield,
                vault.tradeStartDate,
                dcsProduct.tenorInSeconds,
                dcsVault.aprBps,
                endDate
            );
    }

    // Duplicates DCSProductEntry.sol
    function getProductDepositAsset(
        DCSProduct storage dcsProduct
    ) internal view returns (address) {
        return
            dcsProduct.dcsOptionType == DCSOptionType.BuyLow
                ? dcsProduct.quoteAssetAddress
                : dcsProduct.baseAssetAddress;
    }

    // MUTATIVE FUNCTIONS

    /**
     * @notice Sets whether the payoff for a vault is in the deposit asset.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param value True if the payoff is in the deposit asset, false otherwise.
     */
    function setIsPayoffInDepositAsset(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        bool value
    ) internal {
        cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset = value;
        emit IDCSEvents.DCSIsPayoffInDepositAssetUpdated(vaultAddress, value);
    }

    /**
     * @notice Rolls over a vault to the next trading period or marks it as a zombie vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     */
    function rolloverVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal onlyValidVault(cgs, vaultAddress) {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        require(
            vault.vaultStatus == VaultStatus.WithdrawalQueueProcessed,
            Errors.INVALID_VAULT_STATUS
        );
        uint40 tradeEndDate = vault.tradeStartDate + dcsProduct.tenorInSeconds;

        require(tradeEndDate != 0, Errors.INVALID_TRADE_END_DATE);

        if (cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset) {
            bytes32 assetCode = VaultLogic.getAssetCode(address(0));
            delete cgs.oraclePriceOverride[vaultAddress][assetCode][
                vault.tradeStartDate
            ];
            delete cgs.oraclePriceOverride[vaultAddress][assetCode][
                tradeEndDate
            ];

            vault.tradeStartDate = 0;
            vault.auctionWinner = address(0);
            vault.auctionWinnerTokenId = 0;

            dcsVault.aprBps = 0;
            dcsVault.initialSpotPrice = 0;
            dcsVault.strikePrice = 0;
            dcsVault.totalYield = 0;

            VaultLogic.setVaultStatus(
                cgs,
                vaultAddress,
                VaultStatus.DepositsOpen
            );
        } else {
            VaultLogic.setVaultStatus(cgs, vaultAddress, VaultStatus.Zombie);
        }

        emit IDCSEvents.DCSVaultRolledOver(vaultAddress);
    }

    /**
     * @notice Submits a dispute for a vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param tradeWinnerNFT The NFT representing the trade winner.
     * @param aclManager The ACL manager contract.
     */
    function disputeVault(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        address tradeWinnerNFT,
        IACLManager aclManager
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage product = cgs.dcsProducts[vault.productId];

        uint256 tradeStartDate = vault.tradeStartDate;
        uint256 tradeEndDate = vault.tradeStartDate + product.tenorInSeconds;
        uint256 currentTime = block.timestamp;
        VaultStatus vaultStatus = vault.vaultStatus;

        require(!vault.isInDispute, Errors.VAULT_IN_DISPUTE);

        if (currentTime < tradeEndDate) {
            require(
                msg.sender == vault.auctionWinner ||
                    aclManager.isTraderAdmin(msg.sender),
                Errors.NOT_TRADE_WINNER_OR_TRADER_ADMIN
            );

            require(
                currentTime > tradeStartDate &&
                    currentTime <
                    tradeStartDate +
                        (uint256(product.disputePeriodInHours) * 1 hours),
                Errors.OUTSIDE_DISPUTE_PERIOD
            );
            require(
                vaultStatus == VaultStatus.Auctioned,
                Errors.INVALID_VAULT_STATUS
            );
        } else {
            require(
                msg.sender ==
                    IERC721(tradeWinnerNFT).ownerOf(
                        vault.auctionWinnerTokenId
                    ) ||
                    aclManager.isTraderAdmin((msg.sender)),
                Errors.NOT_TRADE_WINNER_OR_TRADER_ADMIN
            );
            require(
                currentTime <
                    tradeEndDate +
                        (uint256(product.disputePeriodInHours) * 1 hours),
                Errors.OUTSIDE_DISPUTE_PERIOD
            );
            require(
                vaultStatus == VaultStatus.AwaitingSettlement ||
                    (dcsVault.isPayoffInDepositAsset &&
                        vaultStatus == VaultStatus.Settled),
                Errors.INVALID_VAULT_STATUS
            );
        }

        vault.isInDispute = true;

        emit IDCSEvents.DCSDisputeSubmitted(vaultAddress);
    }

    /**
     * @notice Processes a dispute for a vault, potentially overriding the oracle price.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param newPrice The new price to set if the dispute is accepted.
     */
    function processDispute(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 newPrice
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage product = cgs.dcsProducts[vault.productId];

        require(vault.isInDispute, Errors.VAULT_NOT_IN_DISPUTE);

        uint40 timestamp;
        if (newPrice != 0) {
            VaultStatus vaultStatus = vault.vaultStatus;

            if (vaultStatus == VaultStatus.Auctioned) {
                timestamp = vault.tradeStartDate;
            } else {
                timestamp = vault.tradeStartDate + product.tenorInSeconds;

                VaultLogic.setVaultStatus(
                    cgs,
                    vaultAddress,
                    VaultStatus.AwaitingSettlement
                );
                setIsPayoffInDepositAsset(cgs, vaultAddress, true);
            }

            VaultLogic.overrideOraclePrice(
                cgs,
                vaultAddress,
                address(0),
                timestamp,
                newPrice
            );
        }

        vault.isInDispute = false;

        emit IDCSEvents.DCSDisputeProcessed(
            vaultAddress,
            newPrice != 0,
            timestamp,
            newPrice
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";

struct FCNProductCreationParams {
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    uint128 maxUnderlyingAmountLimit;
    address underlyingAsset;
    uint64 leverage;
    uint40 tenorInSeconds;
    uint8 daysToStartLateFees;
    uint8 daysToStartAuctionDefault;
    uint8 daysToStartSettlementDefault;
    uint8 disputePeriodInHours;
    uint8 disputeGraceDelayInHours;
    uint16 lateFeeBps;
    string name;
    string tradeWinnerNftImage;
    bool isBondOption;
    uint24 observationIntervalInSeconds;
    FCNOptionBarrier[] optionBarriers;
}

struct FCNProduct {
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    uint128 maxUnderlyingAmountLimit;
    uint128 sumVaultUnderlyingAmounts;
    address underlyingAsset;
    uint64 leverage;
    uint40 tenorInSeconds;
    uint8 daysToStartLateFees;
    uint8 daysToStartAuctionDefault;
    uint8 daysToStartSettlementDefault;
    uint8 disputePeriodInHours;
    uint8 disputeGraceDelayInHours;
    uint16 lateFeeBps;
    bool isDepositQueueOpen;
    bool isBondOption;
    uint24 observationIntervalInSeconds;
    FCNOptionBarrier[] optionBarriers;
    address[] vaults;
}

struct FCNVaultCreationParams {
    string tokenName;
    string tokenSymbol;
    uint16 yieldFeeBps;
    uint16 managementFeeBps;
}

struct FCNVaultBarrierData {
    uint128 initialSpotPrice;
    IOracleEntry.DataSource dataSource;
}

struct FCNVault {
    uint128 notional;
    uint128 totalYield;
    uint16 aprBps;
    bool isKnockedIn;
    uint16 observationsDone;
    uint96 buffer; // buffer if we need to add any more data
    FCNVaultBarrierData[] barrierData;
}

struct FCNOptionBarrier {
    uint16 barrierBps;
    FCNOptionBarrierType barrierType;
    address asset;
    uint8 exponent;
}

enum FCNOptionBarrierType {
    None,
    KnockIn
}

enum FCNVaultStatus {
    DepositsClosed,
    DepositsOpen,
    PreAuction,
    Auctioned,
    Traded,
    AwaitingSettlement,
    Settled,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    FCNProductCreationParams,
    FCNProduct,
    FCNVaultCreationParams,
    FCNOptionBarrier
} from "../FCNStructs.sol";
import { CegaGlobalStorage, Vault } from "../../../Structs.sol";
import {
    AddToDepositQueueParams,
    RemoveFromDepositQueueParams
} from "../../common/CommonStructs.sol";
import { ProductLogic } from "../../common/lib/ProductLogic.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import { ITreasury } from "../../../treasuries/interfaces/ITreasury.sol";

library FCNProductLogic {
    /**
     * @dev Retrieves the deposit asset for a given FCN product.
     * @param fcnProduct The FCN product.
     * @return The address of the deposit asset.
     */
    function fcnGetProductDepositAsset(
        FCNProduct storage fcnProduct
    ) internal view returns (address) {
        return fcnProduct.underlyingAsset;
    }

    function fcnProcessDepositQueueHook(
        CegaGlobalStorage storage cgs,
        uint32 productId,
        uint128 totalDepositsAmount
    ) internal {
        cgs
            .fcnProducts[productId]
            .sumVaultUnderlyingAmounts += totalDepositsAmount;
    }

    function fcnAddToWithdrawalQueueHook(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 assetAmount
    ) internal {
        cgs
            .fcnProducts[cgs.vaults[vaultAddress].productId]
            .sumVaultUnderlyingAmounts -= assetAmount;
    }

    function addToDepositQueue(
        CegaGlobalStorage storage cgs,
        address treasury,
        uint32 productId,
        uint128 amount,
        address receiver
    ) internal {
        FCNProduct storage fcnProduct = cgs.fcnProducts[productId];
        ProductLogic.addToDepositQueue(
            cgs,
            treasury,
            AddToDepositQueueParams({
                productId: productId,
                amount: amount,
                receiver: receiver,
                depositAsset: fcnProduct.underlyingAsset,
                isDepositQueueOpen: fcnProduct.isDepositQueueOpen,
                minDepositAmount: fcnProduct.minDepositAmount,
                sumVaultUnderlyingAmounts: fcnProduct.sumVaultUnderlyingAmounts,
                maxUnderlyingAmountLimit: fcnProduct.maxUnderlyingAmountLimit
            })
        );
    }

    function removeFromDepositQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        uint32 productId,
        uint128 amount
    ) internal {
        FCNProduct storage fcnProduct = cgs.fcnProducts[productId];
        ProductLogic.removeFromDepositQueue(
            cgs,
            treasury,
            RemoveFromDepositQueueParams({
                productId: productId,
                amount: amount,
                depositor: msg.sender,
                depositAsset: fcnProduct.underlyingAsset,
                minDepositAmount: fcnProduct.minDepositAmount
            })
        );
    }

    function addToWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        ITreasury treasury,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy
    ) internal {
        Vault storage vaultData = cgs.vaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vaultData.productId];
        ProductLogic.withdrawOrAddToWithdrawalQueue(
            cgs,
            treasury,
            addressManager,
            vaultAddress,
            sharesAmount,
            nextProductId,
            useProxy,
            fcnProduct.minWithdrawalAmount,
            fcnProduct.underlyingAsset,
            FCNProductLogic.fcnAddToWithdrawalQueueHook
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { CegaStorage } from "../storage/CegaStorage.sol";
import { CegaGlobalStorage } from "../Structs.sol";
import { IAddressManager } from "../aux/interfaces/IAddressManager.sol";
import { IACLManager } from "../aux/interfaces/IACLManager.sol";
import { Errors } from "../utils/Errors.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract EntryBase is ReentrancyGuard, CegaStorage {
    // CONSTANTS & IMMUTABLE

    uint256 internal constant MAX_BPS = 1e4;

    IAddressManager internal immutable addressManager;

    // MODIFIERS

    modifier onlyCegaAdmin() {
        require(
            IACLManager(addressManager.getACLManager()).isCegaAdmin(msg.sender),
            Errors.NOT_CEGA_ADMIN
        );
        _;
    }

    modifier onlyTraderAdmin() {
        require(
            IACLManager(addressManager.getACLManager()).isTraderAdmin(
                msg.sender
            ),
            Errors.NOT_TRADER_ADMIN
        );
        _;
    }

    modifier onlyValidVault(address vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
        _;
    }

    modifier onlyIfNotPaused() {
        CegaGlobalStorage storage cgs = getStorage();
        require(cgs.protocolPauseConfig == 0, Errors.PROTOCOL_PAUSED);
        _;
    }

    modifier onlyValidProductStrategy(uint32 strategyId, uint32 productId) {
        CegaGlobalStorage storage cgs = getStorage();
        require(
            cgs.strategyOfProduct[productId] == strategyId,
            Errors.WRONG_STRATEGY
        );
        _;
    }

    modifier onlyValidVaultStrategy(uint32 strategyId, address vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();

        require(
            cgs.strategyOfProduct[cgs.vaults[vaultAddress].productId] ==
                strategyId,
            Errors.INVALID_VAULT
        );
        _;
    }

    modifier onlyValidVaultsStrategy(
        uint32 strategyId,
        address[] calldata vaultAddresses
    ) {
        CegaGlobalStorage storage cgs = getStorage();

        for (uint256 index = 0; index < vaultAddresses.length; index++) {
            require(
                cgs.strategyOfProduct[
                    cgs.vaults[vaultAddresses[index]].productId
                ] == strategyId,
                Errors.INVALID_VAULT
            );
        }
        _;
    }

    // CONSTRUCTOR

    constructor(IAddressManager _addressManager) {
        addressManager = _addressManager;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { EntryBase } from "./EntryBase.sol";
import { IProductEntry } from "./interfaces/IProductEntry.sol";
import { Vault, DCS_STRATEGY_ID, FCN_STRATEGY_ID } from "../Structs.sol";
import { CegaStorage, CegaGlobalStorage } from "../storage/CegaStorage.sol";
import { Errors } from "../utils/Errors.sol";
import { DCSLogic } from "../cega-strategies/dcs/lib/DCSLogic.sol";
import {
    FCNProductLogic
} from "../cega-strategies/fcn/lib/FCNProductLogic.sol";
import { ITreasury } from "../treasuries/interfaces/ITreasury.sol";
import { IAddressManager } from "../aux/interfaces/IAddressManager.sol";

contract ProductEntry is IProductEntry, CegaStorage, EntryBase {
    // IMMUTABLE

    ITreasury internal immutable treasury;

    // CONSTRUCTOR

    constructor(
        IAddressManager _addressManager,
        ITreasury _treasury
    ) EntryBase(_addressManager) {
        treasury = _treasury;
    }

    // FUNCTIONS

    function addToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external payable {
        CegaGlobalStorage storage cgs = getStorage();

        uint32 strategy = cgs.strategyOfProduct[productId];
        if (strategy == DCS_STRATEGY_ID) {
            DCSLogic.addToDepositQueue(
                cgs,
                address(treasury),
                productId,
                amount,
                receiver
            );
        } else if (strategy == FCN_STRATEGY_ID) {
            FCNProductLogic.addToDepositQueue(
                cgs,
                address(treasury),
                productId,
                amount,
                receiver
            );
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }

    function removeFromDepositQueue(uint32 productId, uint128 amount) external {
        CegaGlobalStorage storage cgs = getStorage();

        uint32 strategy = cgs.strategyOfProduct[productId];
        if (strategy == DCS_STRATEGY_ID) {
            DCSLogic.removeFromDepositQueue(cgs, treasury, productId, amount);
        } else if (strategy == FCN_STRATEGY_ID) {
            FCNProductLogic.removeFromDepositQueue(
                cgs,
                treasury,
                productId,
                amount
            );
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }

    function addToWithdrawalQueue(
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId
    ) external {
        CegaGlobalStorage storage cgs = getStorage();

        Vault storage vault = cgs.vaults[vaultAddress];
        uint32 strategy = cgs.strategyOfProduct[vault.productId];
        if (strategy == DCS_STRATEGY_ID) {
            DCSLogic.addToWithdrawalQueue(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                sharesAmount,
                nextProductId,
                false
            );
        } else if (strategy == FCN_STRATEGY_ID) {
            FCNProductLogic.addToWithdrawalQueue(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                sharesAmount,
                nextProductId,
                false
            );
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }

    function addToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    ) external {
        CegaGlobalStorage storage cgs = getStorage();

        Vault storage vault = cgs.vaults[vaultAddress];
        uint32 strategy = cgs.strategyOfProduct[vault.productId];
        if (strategy == DCS_STRATEGY_ID) {
            DCSLogic.addToWithdrawalQueue(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                sharesAmount,
                0,
                true
            );
        } else if (strategy == FCN_STRATEGY_ID) {
            FCNProductLogic.addToWithdrawalQueue(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                sharesAmount,
                0,
                true
            );
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

interface IProductEntry {
    function addToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external payable;

    function removeFromDepositQueue(uint32 productId, uint128 amount) external;

    function addToWithdrawalQueue(
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId
    ) external;

    function addToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

interface IOracleEntry {
    enum DataSource {
        None,
        Pyth
    }

    /**
     * @dev Emitted when a data source adapter is set.
     * @param dataSource The data source for which the adapter is set.
     * @param adapter The address of the adapter.
     */
    event DataSourceAdapterSet(DataSource dataSource, address adapter);

    /**
     * @notice Gets the price of an asset at a specific timestamp using a data source.
     * @param asset The address of the asset.
     * @param timestamp The timestamp for which the price is required.
     * @param dataSource The data source to use for fetching the price.
     * @return The price of the asset at the specified timestamp.
     */
    function getSinglePrice(
        address asset,
        uint40 timestamp,
        DataSource dataSource
    ) external view returns (uint128);

    /**
     * @notice Gets the price of a base asset in terms of a quote asset at a specific timestamp using a data source.
     * @param baseAsset The address of the base asset.
     * @param quoteAsset The address of the quote asset.
     * @param timestamp The timestamp for which the price is required.
     * @param dataSource The data source to use for fetching the price.
     * @return The price of the base asset in terms of the quote asset at the specified timestamp.
     */
    function getPrice(
        address baseAsset,
        address quoteAsset,
        uint40 timestamp,
        DataSource dataSource
    ) external view returns (uint128);

    /**
     * @notice Sets the adapter for a specific data source.
     * @param dataSource The data source for which to set the adapter.
     * @param adapter The address of the adapter.
     */
    function setDataSourceAdapter(
        DataSource dataSource,
        address adapter
    ) external;

    /**
     * @notice Returns the target number of decimals for price values.
     * @return The number of decimals.
     */
    function getTargetDecimals() external pure returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

interface IWrappingProxy {
    /**
     * @notice Unwraps the wrapped token and transfers the underlying token to the receiver.
     * @param receiver The address to receive the unwrapped tokens.
     * @param amount The amount of wrapped tokens to unwrap.
     */
    function unwrapAndTransfer(address receiver, uint256 amount) external;

    /**
     * @notice Wraps the token and adds it to the DCS deposit queue.
     * @param productId The product ID for the DCS deposit.
     * @param amount The amount of tokens to wrap.
     * @param receiver The address that will receive the deposit queue shares.
     */
    function wrapAndAddToDCSDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external;

    /**
     * @notice Wraps the token and adds it to the FCN deposit queue.
     * @param productId The product ID for the FCN deposit.
     * @param amount The amount of tokens to wrap.
     * @param receiver The address that will receive the deposit queue shares.
     */
    function wrapAndAddToFCNDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external;

    /**
     * @notice Wraps the token and adds it to the generic deposit queue.
     * @param productId The product ID for the deposit.
     * @param amount The amount of tokens to wrap.
     * @param receiver The address that will receive the deposit queue shares.
     */
    function wrapAndAddToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { ITreasury } from "../../treasuries/interfaces/ITreasury.sol";

interface IRedepositManager {
    // EVENTS

    event Redeposited(
        uint32 indexed productId,
        address asset,
        uint128 amount,
        address receiver,
        bool succeeded
    );

    // FUNCTIONS

    function redeposit(
        ITreasury treasury,
        uint32 productId,
        address asset,
        uint128 amount,
        address receiver
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { CegaGlobalStorage } from "../Structs.sol";

contract CegaStorage {
    bytes32 private constant CEGA_STORAGE_POSITION =
        bytes32(uint256(keccak256("cega.global.storage")) - 1);

    function getStorage() internal pure returns (CegaGlobalStorage storage ds) {
        bytes32 position = CEGA_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

interface ISwapManager {
    enum SwapProtocol {
        None,
        UniswapV3
    }

    struct SwapData {
        uint256 deadline;
        uint128 minOutputAmount;
        bytes extraData;
    }

    event SwapProtocolAdapterUpdated(
        SwapProtocol swapProtocol,
        address adapter
    );

    event Swapped(
        address fromAsset,
        address toAsset,
        uint128 amount,
        address receiver,
        SwapProtocol swapProtocol,
        SwapData swapData
    );

    /**
     * @notice Gets adapter address for swap protocol
     * @param swapProtocol Swap protocol
     * @return Address of the adapter
     */
    function swapProtocolAdapters(
        SwapProtocol swapProtocol
    ) external view returns (address);

    /**
     * @notice Sets (or resets) adapter for swap protocol
     * @param swapProtocol Swap protocol
     * @param adapter Address of the adapter contract
     */
    function setSwapProtocolAdapter(
        SwapProtocol swapProtocol,
        address adapter
    ) external;

    /**
     * @notice Swaps with given params
     * @param fromAsset Input asset
     * @param toAsset Output asset
     * @param amount Amount to swap
     * @param receiver Address to receive the swap
     * @param swapProtocol Protocol to use for the swap
     * @param swapData Other data for the swap
     */
    function swap(
        address fromAsset,
        address toAsset,
        uint128 amount,
        address receiver,
        SwapProtocol swapProtocol,
        SwapData calldata swapData
    ) external returns (uint128 outputAmount);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

interface ITreasury {
    event Withdrawn(
        address indexed asset,
        address indexed receiver,
        uint256 amount
    );

    event StuckAssetsAdded(
        address indexed asset,
        address indexed receiver,
        uint256 amount
    );

    receive() external payable;

    /**
     * @dev Withdraw funds from the treasury
     * @param asset Address of the asset (0 for native token)
     * @param receiver Address of the withdrawal receiver
     * @param amount The amount of funds to withdraw.
     * @param trustedReceiver Flag if we trust that receiver won't revert withdrawal
     */
    function withdraw(
        address asset,
        address receiver,
        uint256 amount,
        bool trustedReceiver
    ) external;

    function withdrawStuckAssets(address asset, address receiver) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import { IAddressManager } from "../aux/interfaces/IAddressManager.sol";

library AddressManagement {
    bytes32 private constant SWAP_MANAGER = "SWAP_MANAGER";

    function getSwapManager(
        IAddressManager addressManager
    ) internal view returns (address) {
        return addressManager.getAddress(SWAP_MANAGER);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

library Errors {
    string public constant NOT_CEGA_ENTRY = "1";
    string public constant NOT_CEGA_ADMIN = "2";
    string public constant NOT_TRADER_ADMIN = "3";
    string public constant NOT_TRADE_WINNER = "4";
    string public constant INVALID_VAULT = "5";
    string public constant INVALID_VAULT_STATUS = "6";
    string public constant VAULT_IN_ZOMBIE_STATE = "7";
    string public constant TRADE_DEFAULTED = "8";
    string public constant INVALID_SETTLEMENT_STATUS = "9";
    string public constant VAULT_IN_DISPUTE = "10";
    string public constant VAULT_NOT_IN_DISPUTE = "11";
    string public constant OUTSIDE_DISPUTE_PERIOD = "12";
    string public constant TRADE_HAS_NO_WINNER = "13";
    string public constant TRADE_NOT_CONVERTED = "14";
    string public constant TRADE_CONVERTED = "15";
    string public constant INVALID_TRADE_END_DATE = "16";
    string public constant INVALID_PRICE = "17";
    string public constant VALUE_TOO_SMALL = "18";
    string public constant VALUE_TOO_LARGE = "19";
    string public constant VALUE_IS_ZERO = "20";
    string public constant MAX_DEPOSIT_LIMIT_REACHED = "21";
    string public constant DEPOSIT_QUEUE_NOT_OPEN = "22";
    string public constant INVALID_QUOTE_OR_BASE_ASSETS = "23";
    string public constant INVALID_MIN_DEPOSIT_AMOUNT = "24";
    string public constant INVALID_MIN_WITHDRAWAL_AMOUNT = "25";
    string public constant INVALID_STRIKE_PRICE = "26";
    string public constant TRANSFER_FAILED = "27";
    string public constant NOT_AVAILABLE_DATA_SOURCE = "28";
    string public constant NO_PRICE_AVAILABLE = "29";
    string public constant NO_PRICE_FEED_SET = "30";
    string public constant INCOMPATIBLE_PRICE = "31";
    string public constant NOT_CEGA_ENTRY_OR_REDEPOSIT_MANAGER = "32";
    string public constant NO_PROXY_FOR_REDEPOSIT = "33";
    string public constant NOT_TRADE_WINNER_OR_TRADER_ADMIN = "34";
    string public constant TRADE_NOT_STARTED = "35";
    string public constant NOT_AVAILABLE_SWAP_TYPE = "36";
    string public constant NOT_AVAILABLE_SWAP_PATH = "37";
    string public constant PROTOCOL_PAUSED = "38";
    string public constant WRONG_STRATEGY = "39";
    string public constant INVALID_ARRAY_LENGTH = "40";
    string public constant UNKNOWN_BARRIER_TYPE = "41";
    string public constant NOT_BOND_OPTION = "42";
    string public constant UNAUTHORIZED_BOND_RECEIVER = "43";
    string public constant REMAINING_VALUE_TOO_SMALL = "44";
    string public constant VALUE_IN_DISPUTE_GRACE_DELAY = "45";
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Errors } from "../utils/Errors.sol";

library Transfers {
    using SafeERC20 for IERC20;

    function receiveTo(
        address asset,
        address to,
        uint256 amount
    ) internal returns (uint256 nativeValueReceived) {
        if (asset == address(0)) {
            require(msg.value >= amount, Errors.VALUE_TOO_SMALL);
            (bool success, ) = to.call{ value: amount }("");
            if (!success) {
                revert(Errors.TRANSFER_FAILED);
            }
            return amount;
        } else {
            IERC20(asset).safeTransferFrom(msg.sender, to, amount);
            return 0;
        }
    }

    function transfer(
        address asset,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (asset == address(0)) {
            (bool success, ) = payable(to).call{ value: amount }("");
            return success;
        } else {
            (bool success, bytes memory returndata) = asset.call(
                abi.encodeCall(IERC20.transfer, (to, amount))
            );
            if (!success || asset.code.length == 0) {
                return false;
            }
            return returndata.length == 0 || abi.decode(returndata, (bool));
        }
    }

    /// @notice Adds if needed, and returns required value to pass
    /// @param asset Asset to ensure
    /// @param to Spender
    /// @param amount Amount to ensure
    /// @return Native value to pass
    function ensureApproval(
        address asset,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (asset != address(0)) {
            uint256 allowance = IERC20(asset).allowance(address(this), to);
            if (allowance < amount) {
                IERC20(asset).safeIncreaseAllowance(to, amount - allowance);
            }
            return 0;
        } else {
            return amount;
        }
    }

    function receiveNativeValue(uint256 value) internal {
        require(value <= msg.value, Errors.VALUE_TOO_SMALL);
        uint256 excessValue = msg.value - value;
        if (excessValue > 0) {
            (bool success, ) = payable(msg.sender).call{ value: excessValue }(
                ""
            );
            require(success, Errors.TRANSFER_FAILED);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ICegaVault is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}