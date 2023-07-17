// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
    constructor (string memory name_, string memory symbol_) {
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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.6;

/// @title GmxLeveragePositionDataDecoder Contract
/// @author Alfred Team <[email protected]>
/// @notice Abstract contract containing data decodings for GmxLeveragePositions payloads
abstract contract GmxLeveragePositionDataDecoder {
    /// @dev Helper to decode args used during the AddLiquidity action
    function __decodeCreateIncreasePositionActionArgs(
        bytes memory _actionArgs
    )
        internal
        pure
        returns (
            address[] memory _path,
            address _indexToken,
            uint256 _minOut,
            uint256 _amount,
            uint256 _sizeDelta,
            bool _isLong,
            uint256 _acceptablePrice,
            uint256 _executionFee,
            bytes32 _referralCode
        )
    {
        return
            abi.decode(
                _actionArgs,
                (address[], address, uint256, uint256, uint256, bool, uint256, uint256, bytes32)
            );
    }

    function __decodeCreateDecreaseActionArgs(
        bytes memory _actionArgs
    )
        internal
        pure
        returns (
            address[] memory _path,
            address _indexToken,
            uint256 _collateralDelta,
            uint256 _sizeDelta,
            bool _isLong,
            uint256 _acceptablePrice,
            uint256 _minOut,
            uint256 _executionFee,
            bool _withdrawETH
        )
    {
        return
            abi.decode(
                _actionArgs,
                (address[], address, uint256, uint256, bool, uint256, uint256, uint256, bool)
            );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin-solc-0.7/contracts/math/SafeMath.sol";
import "@openzeppelin-solc-0.7/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin-solc-0.7/contracts/token/ERC20/SafeERC20.sol";
import "./gmx/IPositionRouter.sol";
import "./gmx/IRouter.sol";
import "./gmx/IGmxVault.sol";
import "./GmxLeveragePositionDataDecoder.sol";
import "./interfaces/IGmxLeveragePosition.sol";
import {IPositionRouterCallbackReceiver} from "./interfaces/IPositionRouterCallbackReceiver.sol";
import "./utils/AddressArrayLib.sol";

// import {IWETH} from "../../../../interfaces/IWETH.sol";

interface IFundManager {
    function successCallBack() external;

    function failCallBack() external;
}

interface IVault {
    function getOwner() external view returns (address);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

/// @title GMXLeveragePositionLib Contract
/// @author Alfred Council <[email protected]>
/// @notice An External Position library contract for taking gmx leverage positions
/// @title GMXLeveragePositionLib Contract
/// @author Alfred Council <[email protected]>
/// @notice An External Position library contract for taking gmx leverage positions
contract GmxLeveragePositionLib is
    GmxLeveragePositionDataDecoder,
    IGmxLeveragePosition,
    IPositionRouterCallbackReceiver
{
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using AddressArrayLib for address[];

    struct PendingPositionParams {
        address collateralToken;
        address indexToken;
        bool isLong;
        bool isIncrease;
        address vaultProxy;
        uint256 amountToTransfer;
        uint256 size;
    }

    uint256 public constant GMX_FUNDING_RATE_PRECISION = 1000000;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address private immutable GMX_POSITION_ROUTER;
    address private immutable VALUE_INTERPRETER;
    address private immutable GMX_ROUTER;

    address private immutable GMX_VAULT;
    address private immutable GMX_READER;

    address public immutable WETH_TOKEN;

    address[] internal collateralAssets;

    address[] internal supportedIndexTokens;

    mapping(bytes32 => PendingPositionParams) public pendingPositions;

    event GmxPositionCallback(
        address keeper,
        bytes32 requestKey,
        bool isExecuted,
        bool isIncrease
    );

    constructor(
        address _gmxPositionRouter,
        address _gmxVault,
        address _gmxReader,
        address _gmxRouter,
        address _valueInterpreter,
        address _weth
    ) public {
        GMX_POSITION_ROUTER = _gmxPositionRouter;
        GMX_VAULT = _gmxVault;
        GMX_READER = _gmxReader;
        GMX_ROUTER = _gmxRouter;
        VALUE_INTERPRETER = _valueInterpreter;
        WETH_TOKEN = _weth;
    }

    /// @notice Initializes the external position
    /// @dev Nothing to initialize for this contract
    function init(bytes memory) external override {}

    function assetIsCollateral(address _asset) public view returns (bool isCollateral_) {
        return collateralAssets.contains(_asset);
    }

    function assetIsIndexToken(address _asset) public view returns (bool isIndex_) {
        return supportedIndexTokens.contains(_asset);
    }

    /// @notice Receives and executes a call from the Vault
    /// @param _actionData Encoded data to execute the action
    function receiveCallFromVault(bytes memory _actionData) external override {
        (uint256 actionId, bytes memory actionArgs) = abi.decode(_actionData, (uint256, bytes));
        if (
            actionId ==
            uint256(IGmxLeveragePosition.GmxLeveragePositionActions.CreateIncreasePosition)
        ) {
            (
                address[] memory _path,
                address _indexToken,
                uint256 _amount,
                uint256 _minOut,
                uint256 _sizeDelta,
                bool _isLong,
                uint256 _acceptablePrice,
                uint256 _executionFee,
                bytes32 _referralCode
            ) = __decodeCreateIncreasePositionActionArgs(actionArgs);

            __createIncreasePosition(
                _path,
                address(_indexToken),
                _amount,
                _minOut,
                _sizeDelta,
                _isLong,
                _acceptablePrice,
                _executionFee,
                _referralCode
            );
        } else if (
            actionId ==
            uint256(IGmxLeveragePosition.GmxLeveragePositionActions.CreateDecreasePosition)
        ) {
            (
                address[] memory path,
                address indexToken,
                uint256 collateralDelta,
                uint256 sizeDelta,
                bool isLong,
                uint256 acceptablePrice,
                uint256 minOut,
                uint256 executionFee,
                bool withdrawETH
            ) = __decodeCreateDecreaseActionArgs(actionArgs);

            __createDecreasePosition(
                path,
                indexToken,
                collateralDelta,
                sizeDelta,
                isLong,
                address(msg.sender),
                acceptablePrice,
                minOut,
                executionFee,
                withdrawETH,
                address(this)
            );
        } else if (
            actionId == uint256(IGmxLeveragePosition.GmxLeveragePositionActions.RemoveCollateral)
        ) {
            __removeCollateralAssets();
        } else {
            revert("receiveCallFromVault: Invalid actionId");
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Approve assets to GMX Router contract

    /// @dev Helper to approve a target account with the max amount of an asset
    function __approveAsset(address _asset, address _target, uint256 _neededAmount) internal {
        uint256 allowance = ERC20(_asset).allowance(address(this), _target);
        if (allowance < _neededAmount) {
            if (allowance > 0) {
                ERC20(_asset).safeApprove(_target, 0);
            }
            ERC20(_asset).safeApprove(_target, _neededAmount);
        }

        //call approvePlugin function on gmx position router
        IRouter(getGmxRouter()).approvePlugin(getPositionRouter());

        __addCollateralAssets(_asset);
    }

    /// @dev Mints a new uniswap position, receiving an nft as a receipt
    function __createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amount,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode
    ) private {
        // Grant max token approval to the position router as necessary
        __approveAsset(_path[0], getGmxRouter(), _amount);

        IWETH(payable(WETH_TOKEN)).withdraw(_executionFee);

        // create increase position on Gmx
        bytes32 _requestKey = IPositionRouter(getPositionRouter()).createIncreasePosition{
            value: _executionFee
        }(
            _path,
            address(_indexToken),
            _amount,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            _referralCode,
            address(this)
        );

        __addIndexTokens(_indexToken);

        // Update local storage

        pendingPositions[_requestKey] = PendingPositionParams({
            collateralToken: _path[0],
            indexToken: _indexToken,
            isLong: _isLong,
            isIncrease: true,
            amountToTransfer: _amount,
            vaultProxy: msg.sender,
            size: _sizeDelta
        });
    }

    function __addCollateralAssets(address _asset) private {
        if (!assetIsCollateral(_asset)) {
            collateralAssets.push(_asset);
            // emit CollateralAssetAdded(aTokens[i]);
        }
    }

    function __addIndexTokens(address _asset) private {
        if (!assetIsIndexToken(_asset)) {
            supportedIndexTokens.push(_asset);
            // emit CollateralAssetAdded(aTokens[i]);
        }
    }

    function __createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) private {
        IWETH(payable(WETH_TOKEN)).withdraw(_executionFee);
        require(address(this).balance >= _executionFee, "insufficient exec fee");
        bytes32 _requestKey = IPositionRouter(getPositionRouter()).createDecreasePosition{
            value: _executionFee
        }(
            _path,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver,
            _acceptablePrice,
            _minOut,
            _executionFee,
            _withdrawETH,
            _callbackTarget
        );

        pendingPositions[_requestKey] = PendingPositionParams({
            collateralToken: _path[0],
            indexToken: _indexToken,
            isLong: _isLong,
            isIncrease: false,
            vaultProxy: msg.sender,
            amountToTransfer: _collateralDelta,
            size: _sizeDelta
        });
    }

    function __removeCollateralAssets() private {
        uint256 len = collateralAssets.length;
        uint256[] memory amounts = new uint256[](len);
        for (uint256 i; i < len; ++i) {
            require(
                assetIsCollateral(collateralAssets[i]),
                "__removeCollateralAssets: Invalid collateral asset"
            );

            uint256 collateralBalance = ERC20(collateralAssets[i]).balanceOf(address(this));

            if (collateralBalance != 0)
                ERC20(collateralAssets[i]).safeTransfer(msg.sender, amounts[i]);
        }

        uint256 arrayLen = supportedIndexTokens.length;

        for (uint256 i; i < arrayLen; ++i) {
            address indexToken = supportedIndexTokens[i];
            require(
                assetIsIndexToken(indexToken),
                "__removeCollateralAssets: Invalid index token"
            );

            uint256 collateralBalance = ERC20(indexToken).balanceOf(address(this));

            if (collateralBalance != 0)
                ERC20(indexToken).safeTransfer(msg.sender, collateralBalance);
        }
    }

    ////////////////////
    // POSITION VALUE //
    ////////////////////

    // EXTERNAL FUNCTIONS

    /// @notice Retrieves the debt assets (negative value) of the external position
    /// @return assets_ Debt assets
    /// @return amounts_ Debt asset amounts
    function getDebtAssets()
        external
        pure
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        return (assets_, amounts_);
    }

    // WETH->WETH : Long Position
    // usdc->WETH : short Position,
    // DAI -> WETH : short Position
    // usdt -> WETH : short Position

    // @notice Retrieves the managed assets (positive value) of the external position
    // @return assets_ Managed assets
    // @return amounts_ Managed asset amounts
    function getManagedAssets()
        external
        view
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        uint256 count = supportedIndexTokens.length;

        if (collateralAssets.length != 0) {
            assets_ = new address[](count + 1);
            amounts_ = new uint256[](count + 1);
            assets_[0] = collateralAssets[0];
            amounts_[0] = ERC20(assets_[0]).balanceOf(address(this));
        }

        for (uint256 j; j < count; ++j) {
            address indexToken = supportedIndexTokens[j];
            assets_[j + 1] = indexToken;

            (
                uint256 longSize,
                uint256 positionCollateral,
                ,
                uint256 _entryFundingRate,
                ,
                ,
                ,

            ) = IGmxVault(getGmxVault()).getPosition(address(this), indexToken, indexToken, true);

            if (longSize != 0) {
                // Calculate amount after fees for long position
                uint256 usdOutAfterFee = getUsdOutAfterFee(
                    longSize,
                    positionCollateral,
                    _entryFundingRate,
                    indexToken,
                    indexToken,
                    true
                );
                uint256 amount = IGmxVault(getGmxVault()).usdToTokenMin(
                    indexToken,
                    usdOutAfterFee
                );

                amounts_[j + 1] += amount;
            }
            // Get short position details
            (
                uint256 shortSize,
                uint256 shortCollateral,
                ,
                uint256 entryFundingRate,
                ,
                ,
                ,

            ) = IGmxVault(getGmxVault()).getPosition(address(this), assets_[0], indexToken, false);

            if (shortSize != 0) {
                uint256 usdOutAfterFee = getUsdOutAfterFee(
                    shortSize,
                    shortCollateral,
                    entryFundingRate,
                    assets_[0],
                    indexToken,
                    false
                );

                uint256 amount = IGmxVault(getGmxVault()).usdToTokenMin(
                    assets_[0],
                    usdOutAfterFee
                );
                amounts_[0] += amount;
            }

            amounts_[j + 1] += ERC20(assets_[j + 1]).balanceOf(address(this));
        }

        return (assets_, amounts_);
    }

    function getUsdOutAfterFee(
        uint256 size,
        uint256 positionCollateral,
        uint256 entryFundingRate,
        address collateralToken,
        address indexToken,
        bool isLong
    ) private view returns (uint256) {
        (bool hasProfit, uint256 adjustedDelta) = IGmxVault(getGmxVault()).getPositionDelta(
            address(this),
            collateralToken,
            indexToken,
            isLong
        );

        uint256 usdOut;
        // transfer profits out
        if (hasProfit && adjustedDelta > 0) usdOut = adjustedDelta;

        if (!hasProfit && adjustedDelta > 0)
            positionCollateral = positionCollateral - adjustedDelta;

        usdOut = usdOut + positionCollateral;

        uint256 feeUsd = size.sub(getPositionFee(size));

        uint256 fundingFee = getFundingFee(size, collateralToken, entryFundingRate);

        uint256 totalFee = feeUsd + fundingFee;

        uint256 usdOutAfterFee = usdOut > totalFee ? usdOut - totalFee : usdOut;

        return usdOutAfterFee;
    }

    function getPositionFee(uint256 size) public view returns (uint256) {
        return
            size
                .mul(BASIS_POINTS_DIVISOR.sub(IGmxVault(getGmxVault()).marginFeeBasisPoints()))
                .div(BASIS_POINTS_DIVISOR);
    }

    function getFundingFee(
        uint256 size,
        address collateralToken,
        uint256 entryFundingRate
    ) public view returns (uint256) {
        uint256 fundingRate = (
            IGmxVault(getGmxVault()).cumulativeFundingRates(collateralToken).sub(entryFundingRate)
        );
        return size.mul(fundingRate).div(GMX_FUNDING_RATE_PRECISION);
    }

    ///////////////////
    // CallBack Handle //
    ///////////////////

    function gmxPositionCallback(
        bytes32 _requestKey,
        bool _isExecuted,
        bool _isIncrease
    ) external override {
        _onlyPositionRouter();
        PendingPositionParams memory params = pendingPositions[_requestKey];
        if (_isExecuted) {
            _successCallback(_requestKey, _isExecuted, params);
        } else {
            _failCallback(_requestKey, _isIncrease, params);
        }

        emit GmxPositionCallback(msg.sender, _requestKey, _isExecuted, _isIncrease);
    }

    function _successCallback(
        bytes32 _requestKey,
        bool _isIncrease,
        PendingPositionParams memory params
    ) private {
        // PendingPositionParams memory params = pendingPositions[_requestKey];

        IFundManager(IVault(params.vaultProxy).getOwner()).successCallBack();

        if (_isIncrease)
            emit PositionIncreased(
                params.collateralToken,
                params.indexToken,
                params.isLong,
                params.size
            );
        else
            emit PositionDecreased(
                params.collateralToken,
                params.indexToken,
                params.isLong,
                params.size
            );

        delete pendingPositions[_requestKey];
    }

    function _failCallback(
        bytes32 _requestKey,
        bool _isIncrease,
        PendingPositionParams memory params
    ) private {
        if (_isIncrease) {
            ERC20(params.collateralToken).safeTransfer(params.vaultProxy, params.amountToTransfer);
        }

        IFundManager(IVault(params.vaultProxy).getOwner()).successCallBack();

        emit ExecutionFailed(
            params.collateralToken,
            params.indexToken,
            params.isLong,
            params.isIncrease,
            params.size
        );
        delete pendingPositions[_requestKey];
    }

    //Require for PositionCallBack Interface
    function isContract() external pure returns (bool) {
        return true;
    }

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _collateralToken, _indexToken, _isLong));
    }

    function getOpenPositionsCount() public view override returns (uint256) {
        uint256 count;
        address[] memory assets;

        assets = supportedIndexTokens;

        for (uint256 j; j < assets.length; ++j) {
            address indexToken = assets[j];
            (uint256 longPositionSize, , , , , , , ) = IGmxVault(getGmxVault()).getPosition(
                address(this),
                indexToken,
                indexToken,
                true
            );
            if (longPositionSize != 0) {
                ++count;
            }

            for (uint256 i; i < collateralAssets.length; ++i) {
                (uint256 shortPositionSize, , , , , , , ) = IGmxVault(getGmxVault()).getPosition(
                    address(this),
                    collateralAssets[i],
                    indexToken,
                    false
                );
                if (shortPositionSize != 0) {
                    ++count;
                }
            }
        }
        return count;
    }

    function getOpenPositions(
        address user,
        address[] memory indexTokens,
        address[] memory collateralTokens
    ) public view override returns (bytes32[] memory keys, uint256 count) {
        //Possible gmx positions are 20 for any address for now
        keys = new bytes32[](20);

        for (uint256 j; j < indexTokens.length; ++j) {
            address indexToken = indexTokens[j];
            (uint256 size, , , , , , , ) = IGmxVault(getGmxVault()).getPosition(
                user,
                indexToken,
                indexToken,
                true
            );
            if (size != 0) {
                bytes32 key = getPositionKey(user, indexToken, indexToken, true);
                keys[count] = key;
                ++count;
            }
            for (uint256 i; i < collateralTokens.length; ++i) {
                (uint256 shortPositionSize, , , , , , , ) = IGmxVault(getGmxVault()).getPosition(
                    user,
                    collateralTokens[i],
                    indexToken,
                    false
                );
                if (shortPositionSize != 0) {
                    bytes32 key = getPositionKey(user, collateralTokens[i], indexToken, false);
                    keys[count] = key;
                    ++count;
                }
            }
        }

        return (keys, count);
    }

    function _onlyPositionRouter() internal view {
        require(msg.sender == getPositionRouter(), "invalid positionRouter");
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    function getMinExecutionFee() public view returns (uint256) {
        return IPositionRouter(getPositionRouter()).minExecutionFee();
    }

    function getGmxVault() public view returns (address gmxVault_) {
        return GMX_VAULT;
    }

    function getGmxRouter() public view returns (address router_) {
        return GMX_ROUTER;
    }

    function getPositionRouter() public view returns (address positionRouter_) {
        return GMX_POSITION_ROUTER;
    }

    /// @notice Gets the `VALUE_INTERPRETER` variable
    /// @return valueInterpreter_ The `NON_FUNGIBLE_TOKEN_MANAGER` variable value
    function getValueInterpreter() public view returns (address valueInterpreter_) {
        return VALUE_INTERPRETER;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGmxVault {
    function taxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function whitelistedTokens(address) external view returns (bool);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function stableTokens(address) external view returns (bool);

    function poolAmounts(address) external view returns (uint256);

    function globalShortSizes(address) external view returns (uint256);

    function globalShortAveragePrices(address) external view returns (uint256);

    function guaranteedUsd(address) external view returns (uint256);

    function reservedAmounts(address) external view returns (uint256);

    function cumulativeFundingRates(address) external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function lastFundingTimes(address) external view returns (uint256);

    function updateCumulativeFundingRate(address _token) external;

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPositionFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) external returns (uint256);

    function getFundingFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) external returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function gov() external view returns (address);

    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);

    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IPositionRouter {
    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function increasePositionRequestKeysStart() external view returns (uint256);

    function decreasePositionRequestKeysStart() external view returns (uint256);

    function maxGlobalShortSizes(address _indexToken) external view returns (uint256);

    function minExecutionFee() external view returns (uint256);

    function setCallbackGasLimit(uint256 _callbackGasLimit) external;

    function increasePositionsIndex(address) external view returns (uint256);

    function decreasePositionsIndex(address) external view returns (uint256);

    function getRequestQueueLengths() external view returns (uint256, uint256, uint256, uint256);

    function increasePositionRequests(
        bytes32
    ) external view returns (IncreasePositionRequest memory);

    function decreasePositionRequests(
        bytes32
    ) external view returns (DecreasePositionRequest memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IRouter {
    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external;

    function approvePlugin(address _plugin) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.7.6;

/// @title IUnis`wapV3LiquidityPosition Interface
/// @author Enzyme Council <[email protected]>
interface IGmxLeveragePosition {
    enum GmxLeveragePositionActions {
        CreateIncreasePosition,
        CreateDecreasePosition,
        RemoveCollateral
    }

    event PositionIncreased(
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size
    );

    event PositionDecreased(
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size
    );

    event ExecutionFailed(
        address collateral,
        address indexToken,
        bool isLong,
        bool isIncrease,
        uint256 size
    );

    function getOpenPositionsCount() external view returns (uint256);

    function getDebtAssets() external returns (address[] memory, uint256[] memory);

    function getManagedAssets() external returns (address[] memory, uint256[] memory);

    function init(bytes memory) external;

    function receiveCallFromVault(bytes memory) external;

    function getOpenPositions(
        address,
        address[] memory,
        address[] memory
    ) external view returns (bytes32[] memory, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPositionRouterCallbackReceiver {
    // function isContract() external view returns (bool);

    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.7.6;

/// @title AddressArray Library
/// @author Enzyme Council <[email protected]>
/// @notice A library to extend the address array data type
library AddressArrayLib {
    /////////////
    // STORAGE //
    /////////////

    /// @dev Helper to remove an item from a storage array
    function removeStorageItem(
        address[] storage _self,
        address _itemToRemove
    ) internal returns (bool removed_) {
        uint256 itemCount = _self.length;
        for (uint256 i; i < itemCount; i++) {
            if (_self[i] == _itemToRemove) {
                if (i < itemCount - 1) {
                    _self[i] = _self[itemCount - 1];
                }
                _self.pop();
                removed_ = true;
                break;
            }
        }

        return removed_;
    }

    /// @dev Helper to verify if a storage array contains a particular value
    function storageArrayContains(
        address[] storage _self,
        address _target
    ) internal view returns (bool doesContain_) {
        uint256 arrLength = _self.length;
        for (uint256 i; i < arrLength; i++) {
            if (_target == _self[i]) {
                return true;
            }
        }
        return false;
    }

    ////////////
    // MEMORY //
    ////////////

    /// @dev Helper to add an item to an array. Does not assert uniqueness of the new item.
    function addItem(
        address[] memory _self,
        address _itemToAdd
    ) internal pure returns (address[] memory nextArray_) {
        nextArray_ = new address[](_self.length + 1);
        for (uint256 i; i < _self.length; i++) {
            nextArray_[i] = _self[i];
        }
        nextArray_[_self.length] = _itemToAdd;

        return nextArray_;
    }

    /// @dev Helper to add an item to an array, only if it is not already in the array.
    function addUniqueItem(
        address[] memory _self,
        address _itemToAdd
    ) internal pure returns (address[] memory nextArray_) {
        if (contains(_self, _itemToAdd)) {
            return _self;
        }

        return addItem(_self, _itemToAdd);
    }

    /// @dev Helper to verify if an array contains a particular value
    function contains(
        address[] memory _self,
        address _target
    ) internal pure returns (bool doesContain_) {
        for (uint256 i; i < _self.length; i++) {
            if (_target == _self[i]) {
                return true;
            }
        }
        return false;
    }

    /// @dev Helper to merge the unique items of a second array.
    /// Does not consider uniqueness of either array, only relative uniqueness.
    /// Preserves ordering.
    function mergeArray(
        address[] memory _self,
        address[] memory _arrayToMerge
    ) internal pure returns (address[] memory nextArray_) {
        uint256 newUniqueItemCount;
        for (uint256 i; i < _arrayToMerge.length; i++) {
            if (!contains(_self, _arrayToMerge[i])) {
                newUniqueItemCount++;
            }
        }

        if (newUniqueItemCount == 0) {
            return _self;
        }

        nextArray_ = new address[](_self.length + newUniqueItemCount);
        for (uint256 i; i < _self.length; i++) {
            nextArray_[i] = _self[i];
        }
        uint256 nextArrayIndex = _self.length;
        for (uint256 i; i < _arrayToMerge.length; i++) {
            if (!contains(_self, _arrayToMerge[i])) {
                nextArray_[nextArrayIndex] = _arrayToMerge[i];
                nextArrayIndex++;
            }
        }

        return nextArray_;
    }

    /// @dev Helper to verify if array is a set of unique values.
    /// Does not assert length > 0.
    function isUniqueSet(address[] memory _self) internal pure returns (bool isUnique_) {
        if (_self.length <= 1) {
            return true;
        }

        uint256 arrayLength = _self.length;
        for (uint256 i; i < arrayLength; i++) {
            for (uint256 j = i + 1; j < arrayLength; j++) {
                if (_self[i] == _self[j]) {
                    return false;
                }
            }
        }

        return true;
    }

    /// @dev Helper to remove items from an array. Removes all matching occurrences of each item.
    /// Does not assert uniqueness of either array.
    function removeItems(
        address[] memory _self,
        address[] memory _itemsToRemove
    ) internal pure returns (address[] memory nextArray_) {
        if (_itemsToRemove.length == 0) {
            return _self;
        }

        bool[] memory indexesToRemove = new bool[](_self.length);
        uint256 remainingItemsCount = _self.length;
        for (uint256 i; i < _self.length; i++) {
            if (contains(_itemsToRemove, _self[i])) {
                indexesToRemove[i] = true;
                remainingItemsCount--;
            }
        }

        if (remainingItemsCount == _self.length) {
            nextArray_ = _self;
        } else if (remainingItemsCount > 0) {
            nextArray_ = new address[](remainingItemsCount);
            uint256 nextArrayIndex;
            for (uint256 i; i < _self.length; i++) {
                if (!indexesToRemove[i]) {
                    nextArray_[nextArrayIndex] = _self[i];
                    nextArrayIndex++;
                }
            }
        }

        return nextArray_;
    }
}