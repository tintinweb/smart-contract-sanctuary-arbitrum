/**
 *Submitted for verification at Arbiscan on 2022-10-07
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: contracts/vault.sol



pragma solidity 0.8.12;





interface GLPRouter{
  function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256) ;
  function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external  returns (uint256);
  function claimFees() external;
  function claimEsGmx() external;
}

interface GDtoken is IERC20 {
    function mint(address recipient, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external ;
}

interface GLPPriceFeed {

    function getGLPprice() external view returns (uint256);
    function getPrice(address _token) external  view returns (uint256) ;
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract vault is Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    uint256 public treasuryMintedGLP = 0;
    uint256 public slippage = 500;
    IWETH public WETH = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 public USDC;
    IERC20 public EsGMX = IERC20(0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA);
    //IERC20 public WETH;
    //IERC20 public WBTC;
    
    GDtoken public gdUSDC;
    //IERC20 public gdWETH;
    //IERC20 public gdWBTC;
    GLPRouter public _GLPRouter = GLPRouter(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1); 
    address poolGLP = 0x321F653eED006AD1C29D174e17d96351BDe22649;
    GLPPriceFeed public priceFeed = GLPPriceFeed(0x06e31Ad70174D7dB1Eb06fCDa75Aa254E311BC3f);

    uint256 public compoundPercentage = 500;

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.

    }

    struct PoolInfo {
        IERC20 lpToken;    
        GDtoken GDlptoken; 
        uint256 EarnRateSec;     
        uint256 totalStaked; 
        uint256 lastUpdate; 
        uint256 vaultcap;
        uint256 glpFees;
        uint256 APR;
        bool stakable;
        bool withdrawable;
        bool rewardStart;
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    constructor(IERC20 _USDC/*, IERC20 _WETH, IERC20 _WBTC*/ , GDtoken _gdUSDC) {
        USDC = _USDC;
        gdUSDC = _gdUSDC;
        //WETH = _WETH;
        //WBTC = _WBTC;
        poolInfo.push(PoolInfo({
            lpToken: USDC,
            GDlptoken: gdUSDC,
            totalStaked:0,
            EarnRateSec:0,
            lastUpdate: block.timestamp,
            vaultcap: 0,
            stakable: false,
            withdrawable: false,
            rewardStart: false,
            glpFees: 500, 
            APR: 15000000
            
        }));

    }

    function swapGLPto(uint256 _amount, address token, uint256 min_receive) private returns(uint256) {
        return _GLPRouter.unstakeAndRedeemGlp(token, _amount, min_receive, address(this));
    }

    function swapGLPout(uint256 _amount, address token, uint256 min_receive) external onlyOwner returns(uint256) {
        return _GLPRouter.unstakeAndRedeemGlp(token, _amount, min_receive, address(this));
    }

    function swaptoGLP(uint256 _amount, address token) private returns(uint256) {
        IERC20(token).approve(poolGLP, _amount);
        return _GLPRouter.mintAndStakeGlp(token, _amount,0, 0);
    }

    function treasuryMint(uint _amount, address _token) public  {
        require(IERC20(_token).balanceOf(address(this)) >= _amount);
        treasuryMintedGLP = treasuryMintedGLP.add(swaptoGLP(_amount, _token));

        IERC20(_token).approve(address(_GLPRouter), 0);

    }

    function cycleRewards() external nonReentrant onlyOwner {

        _GLPRouter.claimFees();
        _GLPRouter.claimEsGmx();
        uint256 rewards = WETH.balanceOf(address(this));
        uint256 compoundAmount = rewards.mul(compoundPercentage).div(1000);
        swaptoGLP(compoundAmount, address(WETH));
        WETH.transfer(owner(),  WETH.balanceOf(address(this)));
        EsGMX.transfer(owner(), EsGMX.balanceOf(address(this)));

    }

    function setCompoundPercentage(uint256 _percent) external onlyOwner {
        require(_percent < 900 && _percent > 0, "not in range");
        compoundPercentage = _percent;
    }

    // Unlocks the staked + gained USDC and burns xUSDC
    function updatePool(uint256 _pid) internal {
        uint256 timepass = block.timestamp - poolInfo[_pid].lastUpdate;
        poolInfo[_pid].lastUpdate = block.timestamp;
        uint256 reward = poolInfo[_pid].EarnRateSec.mul(timepass);
        poolInfo[_pid].totalStaked = poolInfo[_pid].totalStaked.add(reward);
        
    }

    function currrentPoolTotal(uint256 _pid) external view returns (uint256) {
        uint256 timepass = block.timestamp - poolInfo[_pid].lastUpdate;
        uint256 reward = poolInfo[_pid].EarnRateSec.mul(timepass);
        return poolInfo[_pid].totalStaked.add(reward);
    }

    function updatePoolRate(uint256 _pid) internal {
        poolInfo[_pid].EarnRateSec =  poolInfo[_pid].totalStaked.mul(poolInfo[_pid].APR).div(100000000).div(365 days);
    }


    

    function setPool(uint256 _pid, uint256 _vaultcap, bool _withdrawable, bool _stakable, bool _rewardStart) external onlyOwner {
        
        poolInfo[_pid].vaultcap = _vaultcap;
        poolInfo[_pid].withdrawable = _withdrawable;
        poolInfo[_pid].stakable = _stakable;
        poolInfo[_pid].rewardStart = _rewardStart;

    }

    function setAPR(uint256 _pid, uint256 _apr) external onlyOwner {
        require(_apr > 5000000 && _apr < 16000000, " apr not in range");
        poolInfo[_pid].APR = _apr;
    }

    function openVault(uint256 _pid, uint256 _vaultcap) external onlyOwner {

        poolInfo[_pid].vaultcap = _vaultcap;
        poolInfo[_pid].stakable = true;
        poolInfo[_pid].withdrawable = false;
        
    }

    function openWithdraw(uint256 _pid) external onlyOwner {

        poolInfo[_pid].stakable = false;
        poolInfo[_pid].withdrawable = true;
    }


    function setSlippage(uint256 _slippage) external onlyOwner{

        require(_slippage >= 200 && _slippage <= 1000, "not in range");
        slippage = _slippage;
    }

    function addPool(IERC20 _lptoken, GDtoken _GDlptoken, uint256 _fees, uint256 _apr) external onlyOwner{
            
            require(_fees <= 700, "out of range. Fees too high");
            require(_apr > 5000000 && _apr < 16000000, " apr not in range");

            poolInfo.push(PoolInfo({
            lpToken: _lptoken,
            GDlptoken: _GDlptoken,
            totalStaked:0,
            EarnRateSec:0,
            lastUpdate: block.timestamp,
            vaultcap: 0,
            stakable: false,
            withdrawable: false,
            rewardStart: false, 
            glpFees: _fees,
            APR: _apr
            
        }));
    }

    function enterETH(uint256 _pid) external payable {

        require(msg.value > 0, "RewardRouter: invalid msg.value");

        uint256 _amount = msg.value;
        IERC20 StakedToken = poolInfo[_pid].lpToken;
        GDtoken GDT = poolInfo[_pid].GDlptoken;
        require(address(StakedToken) == address(WETH), "not eth pool");
        WETH.deposit{value: _amount};
        WETH.approve(address(this), _amount);
        enter(_amount, _pid);
        GDT.transfer(msg.sender, GDT.balanceOf(address(this)));

    }

    function leaveETH(uint256 _amountin, uint256 _pid, address payable receiver) external {

        IERC20 StakedToken = poolInfo[_pid].lpToken;
        require(address(StakedToken) == address(WETH), "not eth pool");
        
        uint256 _amountOut = leave(_amountin, _pid);
        WETH.withdraw(_amountOut);
        
        bool sent = receiver.send(_amountOut);
        require(sent, "ether not sent");

    }
    

    function enter(uint256 _amountin, uint256 _pid) public nonReentrant {

        uint256 _amount = _amountin;

        if (_pid == 0){
            _amount = _amountin.mul(1000000000000);
        }

        GDtoken GDT = poolInfo[_pid].GDlptoken;
        IERC20 StakedToken = poolInfo[_pid].lpToken;

        require(_amountin <= StakedToken.balanceOf(msg.sender), "balance too low" );
        require(poolInfo[_pid].stakable, "not stakable");
        require((poolInfo[_pid].totalStaked + _amount) <= poolInfo[_pid].vaultcap, "cant deposit more than vault cap");

        if (poolInfo[_pid].rewardStart){
            updatePool(_pid);
        }
        
        // Gets the amount of USDC locked in the contract
        uint256 totalStakedTokens = poolInfo[_pid].totalStaked;
        // Gets the amount of gdUSDC in existence
        uint256 totalShares = GDT.totalSupply();

        uint256 balanceMultipier = 100000 - poolInfo[_pid].glpFees;
        uint256 amountAfterFee = _amount.mul(balanceMultipier).div(100000);
        // If no gdUSDC exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalStakedTokens == 0) {
            GDT.mint(msg.sender, amountAfterFee);
        } 
        // Calculate and mint the amount of gdUSDC the USDC is worth. The ratio will change overtime
        else {
            uint256 what = amountAfterFee.mul(totalShares).div(totalStakedTokens);
            GDT.mint(msg.sender, what);
        }
        
        poolInfo[_pid].totalStaked = poolInfo[_pid].totalStaked.add(amountAfterFee);

        updatePoolRate(_pid);
        
        StakedToken.transferFrom(msg.sender, address(this), _amountin);
        
        swaptoGLP(_amountin, address(StakedToken));
        StakedToken.approve(address(_GLPRouter), 0);
    }

    function leave(uint256 _share, uint256 _pid) public  nonReentrant returns(uint256){

        GDtoken GDT = poolInfo[_pid].GDlptoken;
        IERC20 StakedToken = poolInfo[_pid].lpToken;

        require(_share <= GDT.balanceOf(msg.sender), "balance too low");
        require(poolInfo[_pid].withdrawable, "withdraw window not opened");

        if (poolInfo[_pid].rewardStart){
            updatePool(_pid);
        }


        // Gets the amount of xUSDC in existence
        uint256 totalShares = GDT.totalSupply();
        // Calculates the amount of USDC the xUSDC is worth
        uint256 amountOut = _share.mul(poolInfo[_pid].totalStaked).div(totalShares);



        poolInfo[_pid].totalStaked = poolInfo[_pid].totalStaked.sub(amountOut);
        updatePoolRate(_pid);
        GDT.burn(msg.sender, _share);

        uint256 amountSendOut = amountOut;

        if (_pid == 0){
            amountSendOut = amountOut.div(1000000000000);
        }

        uint256 percentage = 100000 - slippage;

        uint256 glpPrice = priceFeed.getGLPprice().mul(percentage).div(100000);
        uint256 glpOut = amountOut.mul(1000000000000).div(glpPrice);
        swapGLPto(glpOut, address(StakedToken), amountSendOut);
        
        StakedToken.transfer(msg.sender, amountSendOut);
        
        convertDust(address(StakedToken));
        return amountSendOut;
    }

    function convertDust(address _token) internal  {
        swaptoGLP(IERC20(_token).balanceOf(address(this)), _token);
    }

    //Recover treasury tokens from contract if needed 

    function recoverTreasuryTokens(address _token, uint256 GLPamount) external onlyOwner {

        //only allow to recover treasury tokens and not drain the vault
        require((treasuryMintedGLP > GLPamount));
        treasuryMintedGLP = treasuryMintedGLP.sub(GLPamount);
    
        swapGLPto(GLPamount, _token, 0);
        IERC20(_token).transfer(msg.sender,  IERC20(_token).balanceOf(address(this)));
        
    }

}