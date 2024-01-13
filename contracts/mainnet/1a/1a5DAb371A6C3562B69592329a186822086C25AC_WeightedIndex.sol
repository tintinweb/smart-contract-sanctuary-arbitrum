// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import './interfaces/IDecentralizedIndex.sol';
import './interfaces/IERC20Metadata.sol';
import './interfaces/IFlashLoanRecipient.sol';
import './interfaces/ITokenRewards.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';
import './StakingPoolToken.sol';

abstract contract DecentralizedIndex is IDecentralizedIndex, ERC20 {
    using SafeERC20 for IERC20;

    uint256 public constant override FLASH_FEE_DAI = 10; // 10 DAI
    uint256 public immutable override BOND_FEE;
    uint256 public immutable override DEBOND_FEE;
    address immutable V2_ROUTER;
    address immutable V2_POOL;
    address immutable DAI;
    address immutable WETH;
    IV3TwapUtilities immutable V3_TWAP_UTILS;

    IndexType public override indexType;
    uint256 public override created;
    address public override lpStakingPool;
    address public override lpRewardsToken;

    IndexAssetInfo[] public indexTokens;
    mapping(address => bool) _isTokenInIndex;
    mapping(address => uint256) _fundTokenIdx;

    bool _swapping;
    bool _swapOn = true;

    event FlashLoan(
        address indexed executor,
        address indexed recipient,
        address token,
        uint256 amount
    );

    modifier noSwap() {
        _swapOn = false;
        _;
        _swapOn = true;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _bondFee,
        uint256 _debondFee,
        address _lpRewardsToken,
        address _v2Router,
        address _dai,
        bool _stakeRestriction,
        IV3TwapUtilities _v3TwapUtilities
    ) ERC20(_name, _symbol) {
        created = block.timestamp;
        BOND_FEE = _bondFee;
        DEBOND_FEE = _debondFee;
        lpRewardsToken = _lpRewardsToken;
        V2_ROUTER = _v2Router;
        address _v2Pool = IUniswapV2Factory(IUniswapV2Router02(_v2Router).factory())
        .createPair(address(this), _dai);
        lpStakingPool = address(
            new StakingPoolToken(
                string(abi.encodePacked('Staked ', _name)),
                string(abi.encodePacked('s', _symbol)),
                _dai,
                _v2Pool,
                lpRewardsToken,
                _stakeRestriction ? _msgSender() : address(0),
                _v3TwapUtilities
            )
        );
        V2_POOL = _v2Pool;
        DAI = _dai;
        WETH = IUniswapV2Router02(_v2Router).WETH();
        V3_TWAP_UTILS = _v3TwapUtilities;
        emit Create(address(this), _msgSender());
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        if (_swapOn && !_swapping) {
            uint256 _bal = balanceOf(address(this));
            uint256 _min = totalSupply() / 10000; // 0.01%
            if (_from != V2_POOL && _bal >= _min && balanceOf(V2_POOL) > 0) {
                _swapping = true;
                _feeSwap(
                    _bal >= _min * 100 ? _min * 100 : _bal >= _min * 20 ? _min * 20 : _min
                );
                _swapping = false;
            }
        }
        super._transfer(_from, _to, _amount);
    }

    function _feeSwap(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DAI;
        _approve(address(this), V2_ROUTER, _amount);
        address _rewards = StakingPoolToken(lpStakingPool).poolRewards();
        IUniswapV2Router02(V2_ROUTER)
        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            _rewards,
            block.timestamp
        );
        uint256 _rewardsDAIBal = IERC20(DAI).balanceOf(_rewards);
        if (_rewardsDAIBal > 0) {
            ITokenRewards(_rewards).depositFromDAI(0);
        }
    }

    function _transferAndValidate(
        IERC20 _token,
        address _sender,
        uint256 _amount
    ) internal {
        uint256 _balanceBefore = _token.balanceOf(address(this));
        _token.safeTransferFrom(_sender, address(this), _amount);
        require(
            _token.balanceOf(address(this)) >= _balanceBefore + _amount,
            'TFRVAL'
        );
    }

    function _isFirstIn() internal view returns (bool) {
        return totalSupply() == 0;
    }

    function _isLastOut(uint256 _debondAmount) internal view returns (bool) {
        return _debondAmount >= (totalSupply() * 98) / 100;
    }

    function isAsset(address _token) public view override returns (bool) {
        return _isTokenInIndex[_token];
    }

    function getAllAssets()
    external
    view
    override
    returns (IndexAssetInfo[] memory)
    {
        return indexTokens;
    }

    function addLiquidityV2(
        uint256 _idxLPTokens,
        uint256 _daiLPTokens,
        uint256 _slippage // 100 == 10%, 1000 == 100%
    ) external override noSwap {
        uint256 _idxTokensBefore = balanceOf(address(this));
        uint256 _daiBefore = IERC20(DAI).balanceOf(address(this));

        _transfer(_msgSender(), address(this), _idxLPTokens);
        _approve(address(this), V2_ROUTER, _idxLPTokens);

        IERC20(DAI).safeTransferFrom(_msgSender(), address(this), _daiLPTokens);
        IERC20(DAI).safeIncreaseAllowance(V2_ROUTER, _daiLPTokens);

        IUniswapV2Router02(V2_ROUTER).addLiquidity(
            address(this),
            DAI,
            _idxLPTokens,
            _daiLPTokens,
            (_idxLPTokens * (1000 - _slippage)) / 1000,
            (_daiLPTokens * (1000 - _slippage)) / 1000,
            _msgSender(),
            block.timestamp
        );

        // check & refund excess tokens from LPing
        if (balanceOf(address(this)) > _idxTokensBefore) {
            _transfer(
                address(this),
                _msgSender(),
                balanceOf(address(this)) - _idxTokensBefore
            );
        }
        if (IERC20(DAI).balanceOf(address(this)) > _daiBefore) {
            IERC20(DAI).safeTransfer(
                _msgSender(),
                IERC20(DAI).balanceOf(address(this)) - _daiBefore
            );
        }
        emit AddLiquidity(_msgSender(), _idxLPTokens, _daiLPTokens);
    }

    function removeLiquidityV2(
        uint256 _lpTokens,
        uint256 _minIdxTokens, // 0 == 100% slippage
        uint256 _minDAI // 0 == 100% slippage
    ) external override noSwap {
        _lpTokens = _lpTokens == 0
        ? IERC20(V2_POOL).balanceOf(_msgSender())
        : _lpTokens;
        require(_lpTokens > 0, 'LPREM');

        uint256 _balBefore = IERC20(V2_POOL).balanceOf(address(this));
        IERC20(V2_POOL).safeTransferFrom(_msgSender(), address(this), _lpTokens);
        IERC20(V2_POOL).safeIncreaseAllowance(V2_ROUTER, _lpTokens);
        IUniswapV2Router02(V2_ROUTER).removeLiquidity(
            address(this),
            DAI,
            _lpTokens,
            _minIdxTokens,
            _minDAI,
            _msgSender(),
            block.timestamp
        );
        if (IERC20(V2_POOL).balanceOf(address(this)) > _balBefore) {
            IERC20(V2_POOL).safeTransfer(
                _msgSender(),
                IERC20(V2_POOL).balanceOf(address(this)) - _balBefore
            );
        }
        emit RemoveLiquidity(_msgSender(), _lpTokens);
    }

    function flash(
        address _recipient,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external override {
        address _rewards = StakingPoolToken(lpStakingPool).poolRewards();
        IERC20(DAI).safeTransferFrom(
            _msgSender(),
            _rewards,
            FLASH_FEE_DAI * 10 ** IERC20Metadata(DAI).decimals()
        );
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_recipient, _amount);
        IFlashLoanRecipient(_recipient).callback(_data);
        require(IERC20(_token).balanceOf(address(this)) >= _balance, 'FLASHAFTER');
        emit FlashLoan(_msgSender(), _recipient, _token, _amount);
    }

    function rescueERC20(address _token) external {
        // cannot withdraw tokens/assets that belong to the index
        require(!isAsset(_token) && _token != address(this), 'UNAVAILABLE');
        IERC20(_token).safeTransfer(
            Ownable(address(V3_TWAP_UTILS)).owner(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    function rescueETH() external {
        require(address(this).balance > 0, 'NOETH');
        _rescueETH(address(this).balance);
    }

    function _rescueETH(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }
        (bool _sent, ) = Ownable(address(V3_TWAP_UTILS)).owner().call{
        value: _amount
        }('');
        require(_sent, 'SENT');
    }

    receive() external payable {
        _rescueETH(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDecentralizedIndex is IERC20 {
    enum IndexType {
        WEIGHTED,
        UNWEIGHTED
    }

    struct IndexAssetInfo {
        address token;
        uint256 weighting;
        uint256 basePriceUSDX96;
        address c1; // arbitrary contract/address field we can use for an index
        uint256 q1; // arbitrary quantity/number field we can use for an index
    }

    event Create(address indexed newIdx, address indexed wallet);
    event Bond(
        address indexed wallet,
        address indexed token,
        uint256 amountTokensBonded,
        uint256 amountTokensMinted
    );
    event Debond(address indexed wallet, uint256 amountDebonded);
    event AddLiquidity(
        address indexed wallet,
        uint256 amountTokens,
        uint256 amountDAI
    );
    event RemoveLiquidity(address indexed wallet, uint256 amountLiquidity);

    function FLASH_FEE_DAI() external view returns (uint256);

    function BOND_FEE() external view returns (uint256); // 1 == 0.01%, 10 == 0.1%, 100 == 1%

    function DEBOND_FEE() external view returns (uint256); // 1 == 0.01%, 10 == 0.1%, 100 == 1%

    function indexType() external view returns (IndexType);

    function created() external view returns (uint256);

    function lpStakingPool() external view returns (address);

    function lpRewardsToken() external view returns (address);

    function getIdxPriceUSDX96() external view returns (uint256, uint256);

    function isAsset(address token) external view returns (bool);

    function getAllAssets() external view returns (IndexAssetInfo[] memory);

    function getTokenPriceUSDX96(address token) external view returns (uint256);

    function bond(address token, uint256 amount) external;

    function debond(
        uint256 amount,
        address[] memory token,
        uint8[] memory percentage
    ) external;

    function addLiquidityV2(
        uint256 idxTokens,
        uint256 daiTokens,
        uint256 slippage
    ) external;

    function removeLiquidityV2(
        uint256 lpTokens,
        uint256 minTokens,
        uint256 minDAI
    ) external;

    function flash(
        address recipient,
        address token,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20Metadata {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IFlashLoanRecipient {
    function callback(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPPP is IERC20 {
    event Burn(address indexed user, uint256 amount);

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IStakingPoolToken {
    event Stake(address indexed executor, address indexed user, uint256 amount);

    event Unstake(address indexed user, uint256 amount);

    function indexFund() external view returns (address);

    function stakingToken() external view returns (address);

    function poolRewards() external view returns (address);

    function stakeUserRestriction() external view returns (address);

    function stake(address user, uint256 amount) external;

    function unstake(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ITokenRewards {
    event AddShares(address indexed wallet, uint256 amount);

    event RemoveShares(address indexed wallet, uint256 amount);

    event ClaimReward(address indexed wallet);

    event DistributeReward(address indexed wallet, uint256 amount);

    event DepositRewards(address indexed wallet, uint256 amount);

    function totalShares() external view returns (uint256);

    function totalStakers() external view returns (uint256);

    function rewardsToken() external view returns (address);

    function trackingToken() external view returns (address);

    function depositFromDAI(uint256 amount) external;

    function depositRewards(uint256 amount) external;

    function claimReward(address wallet) external;

    function setShares(
        address wallet,
        uint256 amount,
        bool sharesRemoving
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IUniswapV2Router02 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IV3TwapUtilities {
    function getV3Pool(
        address v3Factory,
        address token0,
        address token1,
        uint24 poolFee
    ) external view returns (address);

    function getPoolPriceUSDX96(
        address pricePool,
        address nativeStablePool,
        address WETH9
    ) external view returns (uint256);

    function sqrtPriceX96FromPoolAndInterval(
        address pool
    ) external view returns (uint160);

    function priceX96FromSqrtPriceX96(
        uint160 sqrtPriceX96
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(
        uint _days
    ) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        int _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampToDate(
        uint timestamp
    ) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import './interfaces/IStakingPoolToken.sol';
import './TokenRewards.sol';

contract StakingPoolToken is IStakingPoolToken, ERC20 {
    using SafeERC20 for IERC20;

    address public override indexFund;
    address public override stakingToken;
    address public override poolRewards;
    address public override stakeUserRestriction;

    modifier onlyRestricted() {
        require(_msgSender() == stakeUserRestriction, 'RESUSERAUTH');
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _dai,
        address _stakingToken,
        address _rewardsToken,
        address _stakeUserRestriction,
        IV3TwapUtilities _v3TwapUtilities
    ) ERC20(_name, _symbol) {
        indexFund = _msgSender();
        stakingToken = _stakingToken;
        stakeUserRestriction = _stakeUserRestriction;
        poolRewards = address(
            new TokenRewards(_v3TwapUtilities, _dai, address(this), _rewardsToken)
        );
    }

    function stake(address _user, uint256 _amount) external override {
        if (stakeUserRestriction != address(0)) {
            require(_user == stakeUserRestriction, 'RESTRICT');
        }
        _mint(_user, _amount);
        IERC20(stakingToken).safeTransferFrom(_msgSender(), address(this), _amount);
        emit Stake(_msgSender(), _user, _amount);
    }

    function unstake(uint256 _amount) external override {
        _burn(_msgSender(), _amount);
        IERC20(stakingToken).safeTransfer(_msgSender(), _amount);
        emit Unstake(_msgSender(), _amount);
    }

    function removeStakeUserRestriction() external onlyRestricted {
        stakeUserRestriction = address(0);
    }

    function setStakeUserRestriction(address _user) external onlyRestricted {
        stakeUserRestriction = _user;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        super._transfer(_from, _to, _amount);
        _afterTokenTransfer(_from, _to, _amount);
    }

    function _mint(address _to, uint256 _amount) internal override {
        super._mint(_to, _amount);
        _afterTokenTransfer(address(0), _to, _amount);
    }

    function _burn(address _from, uint256 _amount) internal override {
        super._burn(_from, _amount);
        _afterTokenTransfer(_from, address(0), _amount);
    }

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from != address(0) && _from != address(0xdead)) {
            TokenRewards(poolRewards).setShares(_from, _amount, true);
        }
        if (_to != address(0) && _to != address(0xdead)) {
            TokenRewards(poolRewards).setShares(_to, _amount, false);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import './libraries/BokkyPooBahsDateTimeLibrary.sol';
import './interfaces/IPPP.sol';
import './interfaces/ITokenRewards.sol';
import './interfaces/IV3TwapUtilities.sol';

contract TokenRewards is ITokenRewards, Context {
    using SafeERC20 for IERC20;

    address constant V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint256 constant PRECISION = 10 ** 36;
    uint24 constant REWARDS_POOL_FEE = 10000; // 1%
    address immutable DAI;
    IV3TwapUtilities immutable V3_TWAP_UTILS;

    struct Reward {
        uint256 excluded;
        uint256 realized;
    }

    address public override trackingToken;
    address public override rewardsToken;
    uint256 public override totalShares;
    uint256 public override totalStakers;
    mapping(address => uint256) public shares;
    mapping(address => Reward) public rewards;

    uint256 _rewardsSwapSlippage = 10; // 1%
    uint256 _rewardsPerShare;
    uint256 public rewardsDistributed;
    uint256 public rewardsDeposited;
    mapping(uint256 => uint256) public rewardsDepMonthly;

    modifier onlyTrackingToken() {
        require(_msgSender() == trackingToken, 'UNAUTHORIZED');
        _;
    }

    constructor(
        IV3TwapUtilities _v3TwapUtilities,
        address _dai,
        address _trackingToken,
        address _rewardsToken
    ) {
        V3_TWAP_UTILS = _v3TwapUtilities;
        DAI = _dai;
        trackingToken = _trackingToken;
        rewardsToken = _rewardsToken;
    }

    function setShares(
        address _wallet,
        uint256 _amount,
        bool _sharesRemoving
    ) external override onlyTrackingToken {
        _setShares(_wallet, _amount, _sharesRemoving);
    }

    function _setShares(
        address _wallet,
        uint256 _amount,
        bool _sharesRemoving
    ) internal {
        if (_sharesRemoving) {
            _removeShares(_wallet, _amount);
            emit RemoveShares(_wallet, _amount);
        } else {
            _addShares(_wallet, _amount);
            emit AddShares(_wallet, _amount);
        }
    }

    function _addShares(address _wallet, uint256 _amount) internal {
        if (shares[_wallet] > 0) {
            _distributeReward(_wallet);
        }
        uint256 sharesBefore = shares[_wallet];
        totalShares += _amount;
        shares[_wallet] += _amount;
        if (sharesBefore == 0 && shares[_wallet] > 0) {
            totalStakers++;
        }
        rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet]);
    }

    function _removeShares(address _wallet, uint256 _amount) internal {
        require(shares[_wallet] > 0 && _amount <= shares[_wallet], 'REMOVE');
        _distributeReward(_wallet);
        totalShares -= _amount;
        shares[_wallet] -= _amount;
        if (shares[_wallet] == 0) {
            totalStakers--;
        }
        rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet]);
    }

    function depositFromDAI(uint256 _amountDAIDepositing) external override {
        if (_amountDAIDepositing > 0) {
            IERC20(DAI).safeTransferFrom(
                _msgSender(),
                address(this),
                _amountDAIDepositing
            );
        }
        uint256 _amountDAI = IERC20(DAI).balanceOf(address(this));
        require(_amountDAI > 0, 'NEEDDAI');
        (address _token0, address _token1) = DAI < rewardsToken
        ? (DAI, rewardsToken)
        : (rewardsToken, DAI);
        PoolAddress.PoolKey memory _poolKey = PoolAddress.PoolKey({
        token0: _token0,
        token1: _token1,
        fee: REWARDS_POOL_FEE
        });
        address _pool = PoolAddress.computeAddress(
            IPeripheryImmutableState(V3_ROUTER).factory(),
            _poolKey
        );
        uint160 _rewardsSqrtPriceX96 = V3_TWAP_UTILS
        .sqrtPriceX96FromPoolAndInterval(_pool);
        uint256 _rewardsPriceX96 = V3_TWAP_UTILS.priceX96FromSqrtPriceX96(
            _rewardsSqrtPriceX96
        );
        uint256 _amountOut = _token0 == DAI
        ? (_rewardsPriceX96 * _amountDAI) / FixedPoint96.Q96
        : (_amountDAI * FixedPoint96.Q96) / _rewardsPriceX96;

        uint256 _rewardsBalBefore = IERC20(rewardsToken).balanceOf(address(this));
        IERC20(DAI).safeIncreaseAllowance(V3_ROUTER, _amountDAI);
        try
        ISwapRouter(V3_ROUTER).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
        tokenIn: DAI,
        tokenOut: rewardsToken,
        fee: REWARDS_POOL_FEE,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amountDAI,
        amountOutMinimum: (_amountOut * (1000 - _rewardsSwapSlippage)) / 1000,
        sqrtPriceLimitX96: 0
        })
        )
        {
            _rewardsSwapSlippage = 10;
            _depositRewards(
                IERC20(rewardsToken).balanceOf(address(this)) - _rewardsBalBefore
            );
        } catch {
            _rewardsSwapSlippage += 10;
            IERC20(DAI).safeDecreaseAllowance(V3_ROUTER, _amountDAI);
        }
    }

    function depositRewards(uint256 _amount) external override {
        require(_amount > 0, 'DEPAM');
        uint256 _rewardsBalBefore = IERC20(rewardsToken).balanceOf(address(this));
        IERC20(rewardsToken).safeTransferFrom(_msgSender(), address(this), _amount);
        _depositRewards(
            IERC20(rewardsToken).balanceOf(address(this)) - _rewardsBalBefore
        );
    }

    function _depositRewards(uint256 _amountTotal) internal {
        if (_amountTotal == 0) {
            return;
        }
        if (totalShares == 0) {
            _burnRewards(_amountTotal);
            return;
        }

        uint256 _burnAmount = _amountTotal / 10;
        uint256 _depositAmount = _amountTotal - _burnAmount;
        _burnRewards(_burnAmount);
        rewardsDeposited += _depositAmount;
        rewardsDepMonthly[beginningOfMonth(block.timestamp)] += _depositAmount;
        _rewardsPerShare += (PRECISION * _depositAmount) / totalShares;
        emit DepositRewards(_msgSender(), _depositAmount);
    }

    function _distributeReward(address _wallet) internal {
        if (shares[_wallet] == 0) {
            return;
        }
        uint256 _amount = getUnpaid(_wallet);
        rewards[_wallet].realized += _amount;
        rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet]);
        if (_amount > 0) {
            rewardsDistributed += _amount;
            IERC20(rewardsToken).safeTransfer(_wallet, _amount);
            emit DistributeReward(_wallet, _amount);
        }
    }

    function _burnRewards(uint256 _burnAmount) internal {
        try IPPP(rewardsToken).burn(_burnAmount) {} catch {
            IERC20(rewardsToken).safeTransfer(address(0xdead), _burnAmount);
        }
    }

    function beginningOfMonth(uint256 _timestamp) public pure returns (uint256) {
        (, , uint256 _dayOfMonth) = BokkyPooBahsDateTimeLibrary.timestampToDate(
            _timestamp
        );
        return _timestamp - ((_dayOfMonth - 1) * 1 days) - (_timestamp % 1 days);
    }

    function claimReward(address _wallet) external override {
        _distributeReward(_wallet);
        emit ClaimReward(_wallet);
    }

    function getUnpaid(address _wallet) public view returns (uint256) {
        if (shares[_wallet] == 0) {
            return 0;
        }
        uint256 earnedRewards = _cumulativeRewards(shares[_wallet]);
        uint256 rewardsExcluded = rewards[_wallet].excluded;
        if (earnedRewards <= rewardsExcluded) {
            return 0;
        }
        return earnedRewards - rewardsExcluded;
    }

    function _cumulativeRewards(uint256 _share) internal view returns (uint256) {
        return (_share * _rewardsPerShare) / PRECISION;
    }
}

// https://pepepods.finance

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import './interfaces/IERC20Metadata.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IV3TwapUtilities.sol';
import './DecentralizedIndex.sol';

contract WeightedIndex is DecentralizedIndex {
    using SafeERC20 for IERC20;

    IUniswapV2Factory immutable V2_FACTORY;

    uint256 _totalWeights;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _bondFee,
        uint256 _debondFee,
        address[] memory _tokens,
        uint256[] memory _weights,
        address _lpRewardsToken,
        address _v2Router,
        address _dai,
        bool _stakeRestriction,
        IV3TwapUtilities _v3TwapUtilities
    )
    DecentralizedIndex(
        _name,
        _symbol,
        _bondFee,
        _debondFee,
        _lpRewardsToken,
        _v2Router,
        _dai,
        _stakeRestriction,
        _v3TwapUtilities
    )
    {
        indexType = IndexType.WEIGHTED;
        V2_FACTORY = IUniswapV2Factory(IUniswapV2Router02(_v2Router).factory());
        require(_tokens.length == _weights.length, 'INIT');
        for (uint256 _i; _i < _tokens.length; _i++) {
            indexTokens.push(
                IndexAssetInfo({
            token: _tokens[_i],
            basePriceUSDX96: 0,
            weighting: _weights[_i],
            c1: address(0),
            q1: 0 // amountsPerIdxTokenX96
            })
            );
            _totalWeights += _weights[_i];
            _fundTokenIdx[_tokens[_i]] = _i;
            _isTokenInIndex[_tokens[_i]] = true;
        }
        // at idx == 0, need to find X in [1/X = tokenWeightAtIdx/totalWeights]
        // at idx > 0, need to find Y in (Y/X = tokenWeightAtIdx/totalWeights)
        uint256 _xX96 = (FixedPoint96.Q96 * _totalWeights) / _weights[0];
        for (uint256 _i; _i < _tokens.length; _i++) {
            indexTokens[_i].q1 =
            (_weights[_i] * _xX96 * 10 ** IERC20Metadata(_tokens[_i]).decimals()) /
            _totalWeights;
        }
    }

    function _getNativePriceUSDX96() internal view returns (uint256) {
        IUniswapV2Pair _nativeStablePool = IUniswapV2Pair(
            V2_FACTORY.getPair(DAI, WETH)
        );
        address _token0 = _nativeStablePool.token0();
        (uint8 _decimals0, uint8 _decimals1) = (
        IERC20Metadata(_token0).decimals(),
        IERC20Metadata(_nativeStablePool.token1()).decimals()
        );
        (uint112 _res0, uint112 _res1, ) = _nativeStablePool.getReserves();
        return
        _token0 == DAI
        ? (FixedPoint96.Q96 * _res0 * 10 ** _decimals1) /
        _res1 /
        10 ** _decimals0
        : (FixedPoint96.Q96 * _res1 * 10 ** _decimals0) /
        _res0 /
        10 ** _decimals1;
    }

    function _getTokenPriceUSDX96(
        address _token
    ) internal view returns (uint256) {
        if (_token == WETH) {
            return _getNativePriceUSDX96();
        }
        IUniswapV2Pair _pool = IUniswapV2Pair(V2_FACTORY.getPair(_token, WETH));
        address _token0 = _pool.token0();
        uint8 _decimals0 = IERC20Metadata(_token0).decimals();
        uint8 _decimals1 = IERC20Metadata(_pool.token1()).decimals();
        (uint112 _res0, uint112 _res1, ) = _pool.getReserves();
        uint256 _nativePriceUSDX96 = _getNativePriceUSDX96();
        return
        _token0 == WETH
        ? (_nativePriceUSDX96 * _res0 * 10 ** _decimals1) /
        _res1 /
        10 ** _decimals0
        : (_nativePriceUSDX96 * _res1 * 10 ** _decimals0) /
        _res0 /
        10 ** _decimals1;
    }

    function bond(address _token, uint256 _amount) external override noSwap {
        require(_isTokenInIndex[_token], 'INVALIDTOKEN');
        uint256 _tokenIdx = _fundTokenIdx[_token];
        uint256 _tokensMinted = (_amount * FixedPoint96.Q96 * 10 ** decimals()) /
        indexTokens[_tokenIdx].q1;
        uint256 _feeTokens = _isFirstIn() ? 0 : (_tokensMinted * BOND_FEE) / 10000;
        _mint(_msgSender(), _tokensMinted - _feeTokens);
        if (_feeTokens > 0) {
            _mint(address(this), _feeTokens);
        }
        for (uint256 _i; _i < indexTokens.length; _i++) {
            uint256 _transferAmount = _i == _tokenIdx
            ? _amount
            : (_amount *
            indexTokens[_i].weighting *
            10 ** IERC20Metadata(indexTokens[_i].token).decimals()) /
            indexTokens[_tokenIdx].weighting /
            10 ** IERC20Metadata(_token).decimals();
            _transferAndValidate(
                IERC20(indexTokens[_i].token),
                _msgSender(),
                _transferAmount
            );
        }
        emit Bond(_msgSender(), _token, _amount, _tokensMinted);
    }

    function debond(
        uint256 _amount,
        address[] memory,
        uint8[] memory
    ) external override noSwap {
        uint256 _amountAfterFee = _isLastOut(_amount)
        ? _amount
        : (_amount * (10000 - DEBOND_FEE)) / 10000;
        uint256 _percAfterFeeX96 = (_amountAfterFee * FixedPoint96.Q96) /
        totalSupply();
        _transfer(_msgSender(), address(this), _amount);
        _burn(address(this), _amountAfterFee);
        for (uint256 _i; _i < indexTokens.length; _i++) {
            uint256 _tokenSupply = IERC20(indexTokens[_i].token).balanceOf(
                address(this)
            );
            uint256 _debondAmount = (_tokenSupply * _percAfterFeeX96) /
            FixedPoint96.Q96;
            IERC20(indexTokens[_i].token).safeTransfer(_msgSender(), _debondAmount);
            require(
                IERC20(indexTokens[_i].token).balanceOf(address(this)) >=
                _tokenSupply - _debondAmount,
                'HEAVY'
            );
        }
        emit Debond(_msgSender(), _amount);
    }

    function getTokenPriceUSDX96(
        address _token
    ) external view override returns (uint256) {
        return _getTokenPriceUSDX96(_token);
    }

    function getIdxPriceUSDX96() public view override returns (uint256, uint256) {
        uint256 _priceX96;
        uint256 _X96_2 = 2 ** (96 / 2);
        for (uint256 _i; _i < indexTokens.length; _i++) {
            uint256 _tokenPriceUSDX96_2 = _getTokenPriceUSDX96(
                indexTokens[_i].token
            ) / _X96_2;
            _priceX96 +=
            (_tokenPriceUSDX96_2 * indexTokens[_i].q1) /
            10 ** IERC20Metadata(indexTokens[_i].token).decimals() /
            _X96_2;
        }
        return (0, _priceX96);
    }
}