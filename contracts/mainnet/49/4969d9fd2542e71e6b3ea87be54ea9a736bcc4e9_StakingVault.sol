/**
 *Submitted for verification at Arbiscan on 2023-06-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

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


/**
 * @title StakingVault
 * @dev Vault that holds funds of investors
 * @notice Contract inherits from Pausable, Ownable and ReentrancyGuard contracts
 */
contract StakingVault is Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // MNTE Token
    IERC20 immutable tokenMNTE;
    // USDT Token
    IERC20 immutable tokenUSDT;
    // Minimum Amount to Stake in MNTE
    uint256 public constant MINIMUM_CONTRIBUTION_AMOUNT = 25e20;

    // Structure linking the staker address with amount and rewards
    struct Staker {
        uint256 previousStakedAmount; // The prevous month amount staked of the Staker
        uint256 stakedAmount;         // The current amount staked of the Staker
        uint256 yieldRewardAmount;    // The current amount rewarded in stablecoin to the Staker
        uint256 firstStakeTimestamp;  // First staking timestamp of the investor
        uint256 lastRewardTimestamp;  // Last claim timestamp of the investor
        uint256 stakerIndex;          // Staker index in the array stakerAddressList
    }

    // Mapping of all stakers
    mapping(address => Staker) public stakers;
    // List of all stakers
    address[] public stakerAddressList;
    // Farming address of USDT rewards
    address farmingAddress;

    // Global staking rewards
    // Total current staked amount in MNTE
    uint256 public totalStakedAmount;
    // Total current reward amount in USDT
    uint256 public totalRewardAmount;
    // Previous month staked amount that has been deposited in this contract in USDT
    uint256 public previousMonthStakedAmount;
    // Previous month reward amount that has been deposited in this contract in USDT
    uint256 public previousMonthRewardAmount;
    // Previous month reward timestamp that has been deposited in this contract in USDT
    uint256 public previousMonthRewardTimestamp;
    // Last reward amount that has been deposited in this contract in USDT
    uint256 public lastRewardAmount;
    // Last timestamp when the amount of rewards in USDT has been deposited
    uint256 public lastRewardTimestamp;
    // Current reward amount being distributed
    uint256 public currentNumberOfStakersRewarded;
    // Total reward overflow value that gets incremented each time an investor unstakes his tokens before last month reward distribution
    // This variable is used in order to avoid loosing any USDT tokens in this contract
    uint256 public totalRewardOverflow;
    bool public isDepositDone;

    // 3 periods of use defining access or not to some functions 
    enum Period {
        Staking,      // = 0
        Distributing, // = 1
        Claiming      // = 2
    }
    // Current period
    Period public period; // By default it will be set to the Staking period at deployment

    // Events
    event Stake(address indexed sender, uint256 amount);
    event Claim(address indexed sender, uint256 amount);
    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed receiver, uint256 amount);

    /**
     * @dev Throws if called by any account other than the farming address.
     */
    modifier onlyFarmer() {
        require(_msgSender() == farmingAddress, "OnlyFarmer: caller is not the farmer");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     * @notice It is also setting up addresses of MNTE and USDT
     * @notice The contract begins by default in staking period
     * @param _tokenMNTE {{address}} - MNTE contract address
     * @param _tokenUSDT {{address}} - USDT contract address
     * @param _farmingAddress {{address}} - Farming address that will deposit rewards on this contract
     */
    constructor(address _tokenMNTE, address _tokenUSDT, address _farmingAddress) {
        require(
            address(_tokenMNTE) != address(0),
            "MNTE Token Address cannot be address 0"
        );
        require(
            address(_tokenUSDT) != address(0),
            "USDT Token Address cannot be address 0"
        );

        // We set MNTE and USDT tokens
        tokenMNTE = IERC20(_tokenMNTE);
        tokenUSDT = IERC20(_tokenUSDT);

        // We set the farming address
        farmingAddress = _farmingAddress;
    }

    /**
     * @dev Allows investor to stake his MNTE tokens in the contract
     * @notice Contract must not be paused to run this function
     * @notice Minimum staking amount: 2500 MNTE
     * @notice The investor must have at least the amount sent as parameter in his MNTE balance
     * @notice The investor must give a minimum allowance of _amount to this contract
     * @notice The investor is not reseting his staking timestamp in order to earn his rewards after calling again this function twice
     * @notice Only the firstStakeTimestamp is taken into account to calculate the right to earn rewards
     * @notice The contract must be set in a staking period
     * @param _amount {{uint256}} - Amount of MNTE tokens going to be staked
     */
    function stake(uint256 _amount) public whenNotPaused {
        require(_amount >= MINIMUM_CONTRIBUTION_AMOUNT, "Stake amount should be more than 2500 MNTE");
        require(
            period == Period.Staking,
            "Staking period has not been reached yet"
        );

        // We first transfer staked tokens of sender to this contract
        require(
            tokenMNTE.transferFrom(_msgSender(), address(this), _amount),
            "Failed to transfer tokens to the staking contract"
        );

        // In the case, the staker address has still not have staked yet
        if (stakers[_msgSender()].firstStakeTimestamp == 0) {
            // Then we add its address to the investor list
            stakerAddressList.push(_msgSender());

            // In this case the Staker struct has still not been defined yet
            Staker memory staker;
            staker.stakerIndex = stakerAddressList.length - 1;
            staker.firstStakeTimestamp = block.timestamp;

            // We add it to the mapping
            stakers[_msgSender()] = staker;
        }

        // We add the amount to the current existing balance one
        stakers[_msgSender()].stakedAmount = stakers[_msgSender()].stakedAmount.add(_amount);

        // Finally, we update the total staked amount
        totalStakedAmount = totalStakedAmount.add(_amount);

        // We emit the event to log the amount staked
        emit Stake(_msgSender(), _amount);
    }

    /**
     * @dev Allows investor to claim his USDT tokens in the contract
     * @notice Contract must not be paused to run this function
     * @notice This function withdraw the total balance amount of USDT rewards, and decrement the total global amount of rewards
     * @notice This function can only be called by one another function within the contract
     * @notice The investor is only able to claim his rewards if his yield balance is more than 0
     * @notice The contract must be set in a claiming period
     */
    function _claim() internal whenNotPaused {
        uint256 amount = stakers[_msgSender()].yieldRewardAmount;

        if (amount > 0) {
            // The amount of rewards in USDT is transfered to the investor address
            require(
                tokenUSDT.transfer(_msgSender(), amount),
                "Failed to claim USDT tokens from the staking contract"
            );
            // Then we reset the reward balance of the investor in USDT
            delete stakers[_msgSender()].yieldRewardAmount;

            // We decrement the total reward amount in USDT
            totalRewardAmount = totalRewardAmount.sub(amount);

            // We emit the event to log the amount claimed
            emit Claim(_msgSender(), amount);
        }
    }

    /**
     * @dev Allows investor to claim his USDT tokens in the contract
     * @notice Contract must not be paused to run this function
     * @notice Reentrant guard to prevent recursive call attack
     * @notice This function can only be processed if the investor has any reward to claim
     * @notice The contract must be set in a claiming period
     */
    function claim() public nonReentrant whenNotPaused {
        require(
            period == Period.Claiming,
            "Claiming period has not been reached yet"
        );
        require(
            stakers[_msgSender()].yieldRewardAmount > 0,
            "Sender has not any rewards"
        );

        _claim();
    }

    /**
     * @dev Allows investor to unstake his USDT tokens in the contract
     * @notice Contract must not be paused to run this function
     * @notice This function can only be called internally
     * @notice The investor is only able to unstake his tokens if his stake balance is more than 0
     * @notice The contract must be set in a claiming period
     */
    function _unstake() internal whenNotPaused {
        // We transfer staked tokens to the sender
        uint256 amount = stakers[_msgSender()].stakedAmount;
        require(
            tokenMNTE.transfer(_msgSender(), amount),
            "Failed to withdraw MNTE tokens from the staking contract"
        );

        // We calculate the expected reward the investor should claim next month
        uint256 rewardOverflow = _calculateReward(_msgSender());

        // Then we update the reward overflow, in order to avoid loosing any USDT rewards
        totalRewardOverflow = totalRewardOverflow.add(rewardOverflow);
        
        // We  remove this address from the list
        uint256 index = stakers[_msgSender()].stakerIndex;
        if (index <= stakerAddressList.length - 1) {
            // In the case the index is not the last one
            stakerAddressList[index] = stakerAddressList[stakerAddressList.length - 1];
        }
        stakerAddressList.pop();

        // In the case we have more than 1 investor in the list of addresses 
        // AND if the address is not the last one in the list
        if (
            (stakerAddressList.length > 1) && 
            (index < stakerAddressList.length - 1)
        ) {
            // We replace the new index of the previous last address in the list
            stakers[stakerAddressList[index]].stakerIndex = index;
        }

        // We also remove related struct in the mapping
        delete stakers[_msgSender()];

        // Then we decrement the total staked amount by the withdrawn value
        totalStakedAmount = totalStakedAmount.sub(amount);

        // We emit the event to log the amount withdrawn
        emit Withdraw(_msgSender(), amount);
    }

    /**
     * @dev Allows investor to withdraw their staked tokens and rewards in the contract
     * @notice Contract must not be paused to run this function
     * @notice Reentrant guard to prevent recursive call attack
     * @notice This function can only be processed if the investor has any staked MNTE tokens
     * @notice The contract must be set in a claiming period
     */
    function withdraw() public nonReentrant whenNotPaused {
        require(
            period == Period.Claiming,
            "Claiming period has not been reached yet"
        );
        require(
            stakers[_msgSender()].stakedAmount > 0,
            "Sender has not staked any tokens"
        );

        // We first claim rewards before erasing memory structures
        _claim();

        // We transfer staked tokens to the sender
        _unstake();
    }

    /**
     * @dev Allows the farming address to send USDT as reward in the contract
     * @notice Contract must not be paused to run this function
     * @notice Reentrant guard to prevent recursive call attack
     * @notice The farmer must have at least the amount sent as parameter in his USDT balance
     * @notice The contract must be set in a distributing period, and before calling distribute() function
     * @param _amount {{uint256}} - Amount of USDT tokens going to be rewarded
     */
    function deposit(uint256 _amount) public nonReentrant whenNotPaused onlyFarmer {
        require(
            period == Period.Distributing,
            "Distributing period has not been reached yet"
        );
        require(
            !isDepositDone,
            "Deposit of USDT rewards has already been done"
        );

        // Then, we transfer reward tokens of sender to this contract
        require(
            tokenUSDT.transferFrom(_msgSender(), address(this), _amount),
            "Failed to deposit USDT tokens to the staking contract"
        );

        // Finally, we update the total reward amount
        lastRewardAmount = _amount;
        totalRewardAmount = totalRewardAmount.add(lastRewardAmount);
        // We also update the last reward timestamp in order to distinguish the previous one for distribution
        lastRewardTimestamp = block.timestamp;
        // We set the boolean to true
        isDepositDone = true;

        // We emit the event to log the amount of rewards for all stakers
        emit Deposit(_msgSender(), _amount);
    }

     /**
     * @dev Distrbute rewards to all investors depending on their shares in the pool
     * @notice This function will iterate on the entire array of addresses of stakers
     * @notice Warning: Please prefer distribution by batch function if the length of stakers becomes too big
     * @notice Only the contract owner can call this function
     * @notice Contract must not be paused to run this function
     * @notice The contract must be set in a distributing period, and after a deposit() call
     */
    function distribute() public onlyOwner whenNotPaused {
        distributeByBatch(0, stakerAddressList.length - 1);
    }

    /**
     * @dev Distrbute rewards to investors, on a specific range of values in the array, depending on their shares in the pool
     * @notice This function will iterate on a specific range of array of addresses of stakers
     * @notice Warning: Please prefer this function instead of distribute() if the length of staker becomes too big
     * @notice Only the contract owner can call this function
     * @notice Contract must not be paused to run this function
     * @notice Reentrant guard to prevent recursive call attack
     * @notice The contract must be set in a distributing period
     * @param _investorFirstIndex {{uint256}} - First investor index in the array list to iterate on
     * @param _investorLastIndex {{uint256}} - Last investor index in the array list to iterate on
     */
    function distributeByBatch(uint256 _investorFirstIndex, uint256 _investorLastIndex) public onlyOwner nonReentrant whenNotPaused {
        require(
            period == Period.Distributing,
            "Distributing period has not been reached yet"
        );
        require( isDepositDone, "Deposit of USDT should be done before distribution of rewards");
        require( stakerAddressList.length > 0, "No investors in the list of addresses");
        require( _investorFirstIndex <= _investorLastIndex, "First investor index should be lower or egual than the last");
        require( _investorLastIndex <= stakerAddressList.length - 1, "Last investor index is not referenced in the array");

        for (uint256 i = _investorFirstIndex; i <= _investorLastIndex; i++) {
            // We first check if this current staker has already been rewarded for this period
            // This could prevent from potential double rewarding issues
            if (stakers[stakerAddressList[i]].lastRewardTimestamp < lastRewardTimestamp) {
                // First we retrieve the appropriate amount of reward the investor has farmed
                uint256 reward = _calculateReward(stakerAddressList[i]);
                // We add this reward amount to the previous one defined
                stakers[stakerAddressList[i]].yieldRewardAmount = stakers[stakerAddressList[i]].yieldRewardAmount.add(reward);
                // We update the previous staked amount that will be processed into calculation for the next month
                stakers[stakerAddressList[i]].previousStakedAmount = stakers[stakerAddressList[i]].stakedAmount;
                // We update the last reward timestamp to avoid double rewarding issues
                stakers[stakerAddressList[i]].lastRewardTimestamp = block.timestamp;
                // Finally, we update the current reward amount being distributed 
                // in order to check if all USDT have been well allocated to investors
                currentNumberOfStakersRewarded = currentNumberOfStakersRewarded + 1;
            }
        }
    }

    /**
     * @dev Calculate potential reward in USDT of a specific address defined as input parameter
     * @notice This function is mainly used in the distribute() one in order to allocate the amount of rewards for each staker
     * @notice A staker has to wait a full period (staking + distributing + claiming) before being entitled to earn rewards
     * @param _investorAddress {{address}} - Investor address we calculate the reward he is allowed to currently claim
     * @return _reward {{uint256}} - USDT reward amount the investor can currently claim after the last deposit
     */
    function _calculateReward(address _investorAddress) internal view returns (uint256) {
        if (
            stakers[_investorAddress].firstStakeTimestamp < previousMonthRewardTimestamp &&
            previousMonthStakedAmount > 0
        ) {
            // In the case investor last reward timestamp is latter than the previous deposit of USDT
            return ((stakers[_investorAddress].previousStakedAmount).mul(previousMonthRewardAmount)).div(previousMonthStakedAmount);
        } else {
            return 0;
        }
    }

    /**
     * @dev Return the number of current stakers addresses in this contract
     * @return numberOfStakers {{uint256}} - Number of addresses staking MNTE
     */
    function numberOfStakers() public view returns (uint256) {
        return stakerAddressList.length;
    }

    /**
     * @dev Toggle to the staking period
     * @notice Only the owner is able to call this function
     * @notice Set the variable period to 'Period.Staking'
     * @notice This function can only be processed if the contract is in a claiming period
     */
    function toggleStakingPeriod() public onlyOwner {
        require(
            period == Period.Claiming,
            "Claiming period has not been reached yet"
        );
        period = Period.Staking;
    }

    /**
     * @dev Toggle to the distributing period
     * @notice Only the owner is able to call this function
     * @notice Set the variable period to 'Period.Distributing'
     * @notice This function can only be processed if the contract is in a staking period
     */
    function toggleDistributingPeriod() public onlyOwner {
        require(
            period == Period.Staking,
            "Staking period has not been reached yet"
        );
        period = Period.Distributing;
    }

    /**
     * @dev Toggle to the claiming period
     * @notice Only the owner is able to call this function
     * @notice Set the variable period to 'Period.Claiming'
     * @notice This function can only be processed if the contract is in a distributing period
     */
    function toggleClaimingPeriod() public onlyOwner {
        require(
            period == Period.Distributing,
            "Distributing period has not been reached yet"
        );
        require(
            currentNumberOfStakersRewarded == numberOfStakers(),
            "All stakers have not been rewarded yet"
        );

        // Then, we reset these variables for the next period
        // First, this temporary variable is reset to 0 for the next calculation of reward distribution for the next period
        currentNumberOfStakersRewarded = 0;
        // We set the previous month stake amount with the last value of amount staked this month (used to process shares in this pool)
        previousMonthStakedAmount = totalStakedAmount;
        // We also set the previous reward amount to calculate next distribution of rewards
        previousMonthRewardAmount = lastRewardAmount;
        // We set the timestamp to check if investors have staked before this date or not
        previousMonthRewardTimestamp = block.timestamp;
        // We reset the boolean to false
        isDepositDone = false;
        period = Period.Claiming;
    }

    /**
     * @dev Transfers farming of the contract to a new account (`_newFarmer`).
     * @notice Can only be called by the current owner.
     * @param _newFarmer {{address}} - Farming address that will deposit rewards on this contract
     */
    function transferFarming(address _newFarmer) public onlyOwner {
        require(
            _newFarmer != address(0),
            "Farmer Address cannot be address 0"
        );
        farmingAddress = _newFarmer;
    }

    /**
     * @dev Transfers all overflow rewards that has not been distributed to farmer address, 
     * @dev because they withdraw their tokens before the next period
     * @notice Contract must not be paused to run this function
     * @notice Reentrant guard to prevent recursive call attack
     * @notice Can only be called by the current farmer.
     * @param _amount {{uint256}} - USDT reward overflow amount to withdraw
     */
    function withdrawRewardOverflow(uint256 _amount) public onlyFarmer whenNotPaused {
        require(
            totalRewardOverflow > 0,
            "Total reward overflow should be more than 0"
        );
        require(
            _amount <= totalRewardOverflow,
            "Amount to withdraw should be inferior to total reward overflow"
        );
        // The amount of rewards overflow in USDT is transfered back to the farmer address
        require(
            tokenUSDT.transfer(_msgSender(), _amount),
            "Failed to withdraw USDT overflow tokens from the staking contract"
        );
        // Then we decrement this overflow variable
        totalRewardOverflow -= _amount;
    }

    /**
     * @dev Set contract to pause
     * @notice Only the owner is able to call this function
     * @notice Once the contract is paused, we can not call most functions of this contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     * @notice Only the owner is able to call this function
     * @notice Once the contract is unpaused, we can call most functions of this contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}