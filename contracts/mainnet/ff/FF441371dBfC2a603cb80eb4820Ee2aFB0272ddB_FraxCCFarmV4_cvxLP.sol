/**
 *Submitted for verification at Arbiscan.io on 2024-01-10
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Sources flattened with hardhat v2.19.4 https://hardhat.org


// File contracts/Common/Context.sol

// Original license: SPDX_License_Identifier: MIT

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/Math/SafeMath.sol

// Original license: SPDX_License_Identifier: MIT

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/ERC20/IERC20.sol

// Original license: SPDX_License_Identifier: MIT


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


// File contracts/Utils/Address.sol

// Original license: SPDX_License_Identifier: MIT

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


// File contracts/ERC20/ERC20.sol

// Original license: SPDX_License_Identifier: MIT




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
    constructor (string memory __name, string memory __symbol) public {
        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
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
     * Requirements
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
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


// File contracts/ERC20/SafeERC20.sol

// Original license: SPDX_License_Identifier: MIT



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


// File contracts/Math/Math.sol

// Original license: SPDX_License_Identifier: MIT

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


// File contracts/Staking/Owned.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor (address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// File contracts/Uniswap/TransferHelper.sol

// Original license: SPDX_License_Identifier: MIT

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/Utils/ReentrancyGuard.sol

// Original license: SPDX_License_Identifier: MIT

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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


// File contracts/Curve/FraxCrossChainRewarder.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ====================== FraxCrossChainRewarder ======================
// ====================================================================
// One-to-one relationship with a FraxMiddlemanGauge on the Ethereum mainnet
// Because some bridges can only bridge to the exact same address on the other chain
// This accepts bridged FXS rewards and then distributes them to the actual farm on this chain

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian







contract FraxCrossChainRewarder is Owned, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /* ========== STATE VARIABLES ========== */

    // Instances and addresses
    address public reward_token_address;

    // Admin addresses
    address public timelock_address;
    address public curator_address;

    // Farm address
    address public farm_address;

    // Booleans
    bool public distributionsOn;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == owner || msg.sender == timelock_address, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnerOrCuratorOrGovernance() {
        require(msg.sender == owner || msg.sender == curator_address || msg.sender == timelock_address, "Not owner, curator, or timelock");
        _;
    }

    modifier isDistributing() {
        require(distributionsOn == true, "Distributions are off");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _owner,
        address _curator_address,
        address _reward_token_address
    ) Owned(_owner) {
        curator_address = _curator_address;
        reward_token_address = _reward_token_address;

        distributionsOn = true;
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    // Callable by anyone
    function distributeReward() public isDistributing nonReentrant returns (uint256 reward_balance) {
        // Get the reward balance
        reward_balance = ERC20(reward_token_address).balanceOf(address(this));

        // Pay out the rewards directly to the farm
        TransferHelper.safeTransfer(reward_token_address, farm_address, reward_balance);

        emit RewardDistributed(farm_address, reward_balance);
    }

    /* ========== RESTRICTED FUNCTIONS - Curator / migrator callable ========== */

    // For emergency situations
    function toggleDistributions() external onlyByOwnerOrCuratorOrGovernance {
        distributionsOn = !distributionsOn;

        emit DistributionsToggled(distributionsOn);
    }

    /* ========== RESTRICTED FUNCTIONS - Owner or timelock only ========== */
    
    // Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        // Only the owner address can ever receive the recovery withdrawal
        TransferHelper.safeTransfer(tokenAddress, owner, tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        return (success, result);
    }

    function setFarmAddress(address _farm_address) external onlyByOwnGov {
        farm_address = _farm_address;

        emit FarmAddressChanged(farm_address);
    }

    function setTimelock(address _new_timelock) external onlyByOwnGov {
        timelock_address = _new_timelock;
    }

    function setCurator(address _new_curator_address) external onlyByOwnGov {
        curator_address = _new_curator_address;
    }

    /* ========== EVENTS ========== */

    event RewardDistributed(address indexed farm_address, uint256 reward_amount);
    event RecoveredERC20(address token, uint256 amount);
    event FarmAddressChanged(address farm_address);
    event DistributionsToggled(bool distibutions_state);
}


// File contracts/ERC20/ERC20Permit/Counters.sol

// Original license: SPDX_License_Identifier: MIT


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/ERC20/ERC20Permit/ECDSA.sol

// Original license: SPDX_License_Identifier: MIT


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/ERC20/ERC20Permit/EIP712.sol

// Original license: SPDX_License_Identifier: MIT


/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File contracts/ERC20/ERC20Permit/IERC20Permit.sol

// Original license: SPDX_License_Identifier: MIT


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


// File contracts/ERC20/ERC20Permit/ERC20Permit.sol

// Original license: SPDX_License_Identifier: MIT






/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function PERMIT_TYPEHASH() external view returns (bytes32) {
        return _PERMIT_TYPEHASH;
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}


// File contracts/ERC20/__CROSSCHAIN/CrossChainCanonical.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================== CrossChainCanonical =======================
// ====================================================================
// Cross-chain / non mainnet canonical token contract.
// Can accept any number of old non-canonical tokens. These will be 
// withdrawable by the owner so they can de-bridge it and get back mainnet 'real' tokens
// Does not include any spurious mainnet logic

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Dennis: github.com/denett





contract CrossChainCanonical is ERC20Permit, Owned, ReentrancyGuard {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // Core
    address public timelock_address; // Governance timelock address
    address public custodian_address; 

    // Misc
    uint256 public mint_cap;
    mapping(address => uint256[2]) public swap_fees;
    mapping(address => bool) public fee_exempt_list;

    // Acceptable old tokens
    address[] public bridge_tokens_array;
    mapping(address => bool) public bridge_tokens;

    // The addresses in this array are able to mint tokens
    address[] public minters_array;
    mapping(address => bool) public minters; // Mapping is also used for faster verification

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    // Administrative booleans
    bool public exchangesPaused; // Pause old token exchanges in case of an emergency
    mapping(address => bool) public canSwap;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovCust() {
        require(msg.sender == timelock_address || msg.sender == owner || msg.sender == custodian_address, "Not owner, tlck, or custd");
        _;
    }

    modifier onlyMinters() {
       require(minters[msg.sender], "Not a minter");
        _;
    } 

    modifier onlyMintersOwnGov() {
       require(_isMinterOwnGov(msg.sender), "Not minter, owner, or tlck");
        _;
    } 

    modifier validBridgeToken(address token_address) {
       require(bridge_tokens[token_address], "Invalid old token");
        _;
    } 

    /* ========== CONSTRUCTOR ========== */

    constructor (
        string memory _name,
        string memory _symbol,
        address _creator_address,
        uint256 _initial_mint_amt,
        address _custodian_address,
        address[] memory _bridge_tokens
    ) ERC20(_name, _symbol) ERC20Permit(_name) Owned(_creator_address) {
        custodian_address = _custodian_address;

        // Initialize the starting old tokens
        for (uint256 i = 0; i < _bridge_tokens.length; i++){ 
            // Mark as accepted
            bridge_tokens[_bridge_tokens[i]] = true;

            // Add to the array
            bridge_tokens_array.push(_bridge_tokens[i]);

            // Set a small swap fee initially of 0.04%
            swap_fees[_bridge_tokens[i]] = [400, 400];

            // Make sure swapping is on
            canSwap[_bridge_tokens[i]] = true;
        }

        // Set the mint cap to the initial mint amount
        mint_cap = _initial_mint_amt;

        // Mint some canonical tokens to the creator
        super._mint(_creator_address, _initial_mint_amt);


    }

    /* ========== VIEWS ========== */

    // Helpful for UIs
    function allBridgeTokens() external view returns (address[] memory) {
        return bridge_tokens_array;
    }

    function _isMinterOwnGov(address the_address) internal view returns (bool) {
        return (the_address == timelock_address || the_address == owner || minters[the_address]);
    }

    function _isFeeExempt(address the_address) internal view returns (bool) {
        return (_isMinterOwnGov(the_address) || fee_exempt_list[the_address]);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // Enforce a minting cap
    function _mint_capped(address account, uint256 amount) internal {
        require(totalSupply() + amount <= mint_cap, "Mint cap");
        super._mint(account, amount);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Exchange old or bridge tokens for these canonical tokens
    function exchangeOldForCanonical(address bridge_token_address, uint256 token_amount) external nonReentrant validBridgeToken(bridge_token_address) returns (uint256 canonical_tokens_out) {
        require(!exchangesPaused && canSwap[bridge_token_address], "Exchanges paused");

        // Pull in the old / bridge tokens
        TransferHelper.safeTransferFrom(bridge_token_address, msg.sender, address(this), token_amount);

        // Handle the fee, if applicable
        canonical_tokens_out = token_amount;
        if (!_isFeeExempt(msg.sender)) {
            canonical_tokens_out -= ((canonical_tokens_out * swap_fees[bridge_token_address][0]) / PRICE_PRECISION);
        }

        // Mint canonical tokens and give it to the sender
        _mint_capped(msg.sender, canonical_tokens_out);
    }

    // Exchange canonical tokens for old or bridge tokens
    function exchangeCanonicalForOld(address bridge_token_address, uint256 token_amount) external nonReentrant validBridgeToken(bridge_token_address) returns (uint256 bridge_tokens_out) {
        require(!exchangesPaused && canSwap[bridge_token_address], "Exchanges paused");
        
        // Burn the canonical tokens
        super._burn(msg.sender, token_amount);

        // Handle the fee, if applicable
        bridge_tokens_out = token_amount;
        if (!_isFeeExempt(msg.sender)) {
            bridge_tokens_out -= ((bridge_tokens_out * swap_fees[bridge_token_address][1]) / PRICE_PRECISION);
        }

        // Give old / bridge tokens to the sender
        TransferHelper.safeTransfer(bridge_token_address, msg.sender, bridge_tokens_out);
    }

    /* ========== MINTERS OR GOVERNANCE FUNCTIONS ========== */

    // Collect old / bridge tokens so you can de-bridge them back on mainnet
    function withdrawBridgeTokens(address bridge_token_address, uint256 bridge_token_amount) external onlyMintersOwnGov validBridgeToken(bridge_token_address) {
        TransferHelper.safeTransfer(bridge_token_address, msg.sender, bridge_token_amount);
    }

    /* ========== MINTERS ONLY ========== */

    // This function is what other minters will call to mint new tokens 
    function minter_mint(address m_address, uint256 m_amount) external onlyMinters {
        _mint_capped(m_address, m_amount);
        emit TokenMinted(msg.sender, m_address, m_amount);
    }

    // This function is what other minters will call to burn tokens
    function minter_burn(uint256 amount) external onlyMinters {
        super._burn(msg.sender, amount);
        emit TokenBurned(msg.sender, amount);
    }

    /* ========== RESTRICTED FUNCTIONS, BUT CUSTODIAN CAN CALL TOO ========== */

    function toggleExchanges() external onlyByOwnGovCust {
        exchangesPaused = !exchangesPaused;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addBridgeToken(address bridge_token_address, uint256 _brdg_to_can_fee, uint256 _can_to_brdg_fee) external onlyByOwnGov {
        // Make sure the token is not already present
        for (uint i = 0; i < bridge_tokens_array.length; i++){ 
            if (bridge_tokens_array[i] == bridge_token_address){
                revert("Token already present");
            }
        }

        // Add the old token
        bridge_tokens[bridge_token_address] = true;
        bridge_tokens_array.push(bridge_token_address);

        // Turn swapping on
        canSwap[bridge_token_address] = true;

        // Set the fees
        swap_fees[bridge_token_address][0] = _brdg_to_can_fee;
        swap_fees[bridge_token_address][1] = _can_to_brdg_fee;

        emit BridgeTokenAdded(bridge_token_address);
    }

    function toggleBridgeToken(address bridge_token_address) external onlyByOwnGov {
        // Make sure the token is already present in the array
        bool bridge_tkn_found;
        for (uint i = 0; i < bridge_tokens_array.length; i++){ 
            if (bridge_tokens_array[i] == bridge_token_address){
                bridge_tkn_found = true;
                break;
            }
        }
        require(bridge_tkn_found, "Bridge tkn not in array");

        // Toggle the token
        bridge_tokens[bridge_token_address] = !bridge_tokens[bridge_token_address];

        // Toggle swapping
        canSwap[bridge_token_address] = !canSwap[bridge_token_address];

        emit BridgeTokenToggled(bridge_token_address, !bridge_tokens[bridge_token_address]);
    }

    // Adds a minter address
    function addMinter(address minter_address) external onlyByOwnGov {
        require(minter_address != address(0), "Zero address detected");

        require(minters[minter_address] == false, "Address already exists");
        minters[minter_address] = true; 
        minters_array.push(minter_address);

        emit MinterAdded(minter_address);
    }

    // Remove a minter 
    function removeMinter(address minter_address) external onlyByOwnGov {
        require(minter_address != address(0), "Zero address detected");
        require(minters[minter_address] == true, "Address nonexistent");
        
        // Delete from the mapping
        delete minters[minter_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < minters_array.length; i++){ 
            if (minters_array[i] == minter_address) {
                minters_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit MinterRemoved(minter_address);
    }

    function setMintCap(uint256 _mint_cap) external onlyByOwnGov {
        mint_cap = _mint_cap;

        emit MintCapSet(_mint_cap);
    }

    function setSwapFees(address bridge_token_address, uint256 _bridge_to_canonical, uint256 _canonical_to_old) external onlyByOwnGov {
        swap_fees[bridge_token_address] = [_bridge_to_canonical, _canonical_to_old];
    }

    function toggleFeesForAddress(address the_address) external onlyByOwnGov {
        fee_exempt_list[the_address] = !fee_exempt_list[the_address];
    }

    function setTimelock(address new_timelock) external onlyByOwnGov {
        require(new_timelock != address(0), "Zero address detected");
        timelock_address = new_timelock;

        emit TimelockSet(new_timelock);
    }

    function setCustodian(address _custodian_address) external onlyByOwnGov {
        require(_custodian_address != address(0), "Zero address detected");
        custodian_address = _custodian_address;

        emit CustodianSet(_custodian_address);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        require(!bridge_tokens[tokenAddress], "Cannot withdraw bridge tokens");
        require(tokenAddress != address(this), "Cannot withdraw these tokens");

        TransferHelper.safeTransfer(address(tokenAddress), msg.sender, tokenAmount);
    }

    // // Generic proxy
    // function execute(
    //     address _to,
    //     uint256 _value,
    //     bytes calldata _data
    // ) external onlyByOwnGov returns (bool, bytes memory) {
    //     (bool success, bytes memory result) = _to.call{value:_value}(_data);
    //     return (success, result);
    // }

    /* ========== EVENTS ========== */

    event TokenBurned(address indexed from, uint256 amount);
    event TokenMinted(address indexed from, address indexed to, uint256 amount);
    event BridgeTokenAdded(address indexed bridge_token_address);
    event BridgeTokenToggled(address indexed bridge_token_address, bool state);
    event MinterAdded(address pool_address);
    event MinterRemoved(address pool_address);
    event MintCapSet(uint256 new_mint_cap);
    event TimelockSet(address new_timelock);
    event CustodianSet(address custodian_address);
}


// File contracts/ERC20/__CROSSCHAIN/CrossChainCanonicalFXS.sol

// Original license: SPDX_License_Identifier: MIT

contract CrossChainCanonicalFXS is CrossChainCanonical {
    constructor (
        string memory _name,
        string memory _symbol,
        address _creator_address,
        uint256 _initial_mint_amt,
        address _custodian_address,
        address[] memory _bridge_tokens
    ) 
    CrossChainCanonical(_name, _symbol, _creator_address, _initial_mint_amt, _custodian_address, _bridge_tokens)
    {}
}


// File contracts/Curve/IveFXS.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later

interface IveFXS {

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function commit_transfer_ownership(address addr) external;
    function apply_transfer_ownership() external;
    function commit_smart_wallet_checker(address addr) external;
    function apply_smart_wallet_checker() external;
    function toggleEmergencyUnlock() external;
    function recoverERC20(address token_addr, uint256 amount) external;
    function get_last_user_slope(address addr) external view returns (int128);
    function user_point_history__ts(address _addr, uint256 _idx) external view returns (uint256);
    function locked__end(address _addr) external view returns (uint256);
    function checkpoint() external;
    function deposit_for(address _addr, uint256 _value) external;
    function create_lock(uint256 _value, uint256 _unlock_time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
    function balanceOf(address addr) external view returns (uint256);
    function balanceOf(address addr, uint256 _t) external view returns (uint256);
    function balanceOfAt(address addr, uint256 _block) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalSupply(uint256 t) external view returns (uint256);
    function totalSupplyAt(uint256 _block) external view returns (uint256);
    function totalFXSSupply() external view returns (uint256);
    function totalFXSSupplyAt(uint256 _block) external view returns (uint256);
    function changeController(address _newController) external;
    function token() external view returns (address);
    function supply() external view returns (uint256);
    function locked(address addr) external view returns (LockedBalance memory);
    function epoch() external view returns (uint256);
    function point_history(uint256 arg0) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 fxs_amt);
    function user_point_history(address arg0, uint256 arg1) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 fxs_amt);
    function user_point_epoch(address arg0) external view returns (uint256);
    function slope_changes(uint256 arg0) external view returns (int128);
    function controller() external view returns (address);
    function transfersEnabled() external view returns (bool);
    function emergencyUnlockActive() external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint256);
    function future_smart_wallet_checker() external view returns (address);
    function smart_wallet_checker() external view returns (address);
    function admin() external view returns (address);
    function future_admin() external view returns (address);
}


// File contracts/ERC20/__CROSSCHAIN/IanyFXS.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later

interface IanyFXS {
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external view returns (bytes32);
  function Swapin(bytes32 txhash, address account, uint256 amount) external returns (bool);
  function Swapout(uint256 amount, address bindaddr) external returns (bool);
  function TRANSFER_TYPEHASH() external view returns (bytes32);
  function allowance(address, address) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
  function balanceOf(address) external view returns (uint256);
  function burn(address from, uint256 amount) external returns (bool);
  function changeMPCOwner(address newVault) external returns (bool);
  function changeVault(address newVault) external returns (bool);
  function decimals() external view returns (uint8);
  function deposit(uint256 amount, address to) external returns (uint256);
  function deposit(uint256 amount) external returns (uint256);
  function deposit() external returns (uint256);
  function depositVault(uint256 amount, address to) external returns (uint256);
  function depositWithPermit(address target, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s, address to) external returns (uint256);
  function depositWithTransferPermit(address target, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s, address to) external returns (uint256);
  function mint(address to, uint256 amount) external returns (bool);
  function name() external view returns (string memory);
  function nonces(address) external view returns (uint256);
  function owner() external view returns (address);
  function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
  function underlying() external view returns (address);
  function vault() external view returns (address);
  function withdraw(uint256 amount, address to) external returns (uint256);
  function withdraw(uint256 amount) external returns (uint256);
  function withdraw() external returns (uint256);
  function withdrawVault(address from, uint256 amount, address to) external returns (uint256);
}


// File contracts/Misc_AMOs/convex/IConvexCvxLPRewardPoolCombo.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later

interface IConvexCvxLPRewardPoolCombo {
    struct EarnedData {
        address token;
        uint256 amount;
    }

    function addExtraReward ( address _token ) external;
    function allowance ( address owner, address spender ) external view returns ( uint256 );
    function approve ( address spender, uint256 amount ) external returns ( bool );
    function balanceOf ( address account ) external view returns ( uint256 );
    function claimable_reward ( address, address ) external view returns ( uint256 );
    function convexBooster (  ) external view returns ( address );
    function convexPoolId (  ) external view returns ( uint256 );
    function convexStaker (  ) external view returns ( address );
    function crv (  ) external view returns ( address );
    function curveGauge (  ) external view returns ( address );
    function decimals (  ) external pure returns ( uint8 );
    function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
    function earned ( address _account ) external returns ( EarnedData[] memory claimable );
    function emergencyWithdraw ( uint256 _amount ) external returns ( bool );
    function getReward ( address _account, address _forwardTo ) external;
    function getReward ( address _account ) external;
    function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
    function initialize ( address _crv, address _curveGauge, address _convexStaker, address _convexBooster, address _lptoken, uint256 _poolId ) external;
    function invalidateReward ( address _token ) external;
    function maxRewards (  ) external view returns ( uint256 );
    function name (  ) external view returns ( string memory );
    function rewardHook (  ) external view returns ( address );
    function rewardLength (  ) external view returns ( uint256 );
    function rewardMap ( address ) external view returns ( uint256 );
    function rewardRedirect ( address ) external view returns ( address );
    function reward_integral_for ( address, address ) external view returns ( uint256 );
    function rewards ( uint256 ) external view returns ( address reward_token, uint256 reward_integral, uint256 reward_remaining );
    function setRewardHook ( address _hook ) external;
    function setRewardRedirect ( address _to ) external;
    function stakeFor ( address _for, uint256 _amount ) external returns ( bool );
    function symbol (  ) external view returns ( string memory );
    function totalSupply (  ) external view returns ( uint256 );
    function transfer ( address recipient, uint256 amount ) external returns ( bool );
    function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
    function user_checkpoint ( address _account ) external returns ( bool );
    function withdraw ( uint256 _amount, bool _claim ) external returns ( bool );
    function withdrawAll ( bool claim ) external;
}


// File contracts/Misc_AMOs/curve/I2poolTokenNoLending.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later

interface I2poolTokenNoLending {
  function initialize ( string memory _name, string memory _symbol, address[4] memory _coins, uint256[4] memory _rate_multipliers, uint256 _A, uint256 _fee ) external;
  function decimals (  ) external view returns ( uint8 );
  function transfer ( address _to, uint256 _value ) external returns ( bool );
  function transferFrom ( address _from, address _to, uint256 _value ) external returns ( bool );
  function approve ( address _spender, uint256 _value ) external returns ( bool );
  function permit ( address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s ) external returns ( bool );
  function last_price (  ) external view returns ( uint256 );
  function ema_price (  ) external view returns ( uint256 );
  function get_balances (  ) external view returns ( uint256[2] memory );
  function admin_fee (  ) external view returns ( uint256 );
  function A (  ) external view returns ( uint256 );
  function A_precise (  ) external view returns ( uint256 );
  function get_p (  ) external view returns ( uint256 );
  function price_oracle (  ) external view returns ( uint256 );
  function get_virtual_price (  ) external view returns ( uint256 );
  function calc_token_amount ( uint256[2] memory _amounts, bool _is_deposit ) external view returns ( uint256 );
  function add_liquidity ( uint256[2] memory _amounts, uint256 _min_mint_amount ) external returns ( uint256 );
  function add_liquidity ( uint256[2] memory _amounts, uint256 _min_mint_amount, address _receiver ) external returns ( uint256 );
  function get_dy ( int128 i, int128 j, uint256 dx ) external view returns ( uint256 );
  function get_dx ( int128 i, int128 j, uint256 dy ) external view returns ( uint256 );
  function exchange ( int128 i, int128 j, uint256 _dx, uint256 _min_dy ) external returns ( uint256 );
  function exchange ( int128 i, int128 j, uint256 _dx, uint256 _min_dy, address _receiver ) external returns ( uint256 );
  function remove_liquidity ( uint256 _burn_amount, uint256[2] memory _min_amounts ) external returns ( uint256[2] memory );
  function remove_liquidity ( uint256 _burn_amount, uint256[2] memory _min_amounts, address _receiver ) external returns ( uint256[2] memory );
  function remove_liquidity_imbalance ( uint256[2] memory _amounts, uint256 _max_burn_amount ) external returns ( uint256 );
  function remove_liquidity_imbalance ( uint256[2] memory _amounts, uint256 _max_burn_amount, address _receiver ) external returns ( uint256 );
  function calc_withdraw_one_coin ( uint256 _burn_amount, int128 i ) external view returns ( uint256 );
  function remove_liquidity_one_coin ( uint256 _burn_amount, int128 i, uint256 _min_received ) external returns ( uint256 );
  function remove_liquidity_one_coin ( uint256 _burn_amount, int128 i, uint256 _min_received, address _receiver ) external returns ( uint256 );
  function ramp_A ( uint256 _future_A, uint256 _future_time ) external;
  function stop_ramp_A (  ) external;
  function set_ma_exp_time ( uint256 _ma_exp_time ) external;
  function admin_balances ( uint256 i ) external view returns ( uint256 );
  function commit_new_fee ( uint256 _new_fee ) external;
  function apply_new_fee (  ) external;
  function withdraw_admin_fees (  ) external;
  function version (  ) external pure returns ( string memory );
  function factory (  ) external view returns ( address );
  function coins ( uint256 arg0 ) external view returns ( address );
  function balances ( uint256 arg0 ) external view returns ( uint256 );
  function fee (  ) external view returns ( uint256 );
  function future_fee (  ) external view returns ( uint256 );
  function admin_action_deadline (  ) external view returns ( uint256 );
  function initial_A (  ) external view returns ( uint256 );
  function future_A (  ) external view returns ( uint256 );
  function initial_A_time (  ) external view returns ( uint256 );
  function future_A_time (  ) external view returns ( uint256 );
  function name (  ) external view returns ( string memory );
  function symbol (  ) external view returns ( string memory );
  function balanceOf ( address arg0 ) external view returns ( uint256 );
  function allowance ( address arg0, address arg1 ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function DOMAIN_SEPARATOR (  ) external view returns ( bytes32 );
  function nonces ( address arg0 ) external view returns ( uint256 );
  function ma_exp_time (  ) external view returns ( uint256 );
  function ma_last_time (  ) external view returns ( uint256 );
}


// File contracts/Misc_AMOs/curve/ICurveChildLiquidityGauge.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later

interface ICurveChildLiquidityGauge {

    struct Reward {
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }


    function deposit ( uint256 _value ) external;
    function deposit ( uint256 _value, address _user ) external;
    function deposit ( uint256 _value, address _user, bool _claim_rewards ) external;
    function withdraw ( uint256 _value ) external;
    function withdraw ( uint256 _value, address _user ) external;
    function withdraw ( uint256 _value, address _user, bool _claim_rewards ) external;
    function transferFrom ( address _from, address _to, uint256 _value ) external returns ( bool );
    function approve ( address _spender, uint256 _value ) external returns ( bool );
    function permit ( address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s ) external returns ( bool );
    function transfer ( address _to, uint256 _value ) external returns ( bool );
    function increaseAllowance ( address _spender, uint256 _added_value ) external returns ( bool );
    function decreaseAllowance ( address _spender, uint256 _subtracted_value ) external returns ( bool );
    function user_checkpoint ( address addr ) external returns ( bool );
    function claimable_tokens ( address addr ) external returns ( uint256 );
    function claimed_reward ( address _addr, address _token ) external view returns ( uint256 );
    function claimable_reward ( address _user, address _reward_token ) external view returns ( uint256 );
    function set_rewards_receiver ( address _receiver ) external;
    function claim_rewards (  ) external;
    function claim_rewards ( address _addr ) external;
    function claim_rewards ( address _addr, address _receiver ) external;
    function add_reward ( address _reward_token, address _distributor ) external;
    function set_reward_distributor ( address _reward_token, address _distributor ) external;
    function deposit_reward_token ( address _reward_token, uint256 _amount ) external;
    function set_manager ( address _manager ) external;
    function update_voting_escrow (  ) external;
    function set_killed ( bool _is_killed ) external;
    function decimals (  ) external view returns ( uint256 );
    function integrate_checkpoint (  ) external view returns ( uint256 );
    function version (  ) external view returns ( string memory );
    function factory (  ) external view returns ( address );
    function initialize ( address _lp_token, address _manager ) external;
    function DOMAIN_SEPARATOR (  ) external view returns ( bytes32 );
    function nonces ( address arg0 ) external view returns ( uint256 );
    function name (  ) external view returns ( string memory );
    function symbol (  ) external view returns ( string memory );
    function allowance ( address arg0, address arg1 ) external view returns ( uint256 );
    function balanceOf ( address arg0 ) external view returns ( uint256 );
    function totalSupply (  ) external view returns ( uint256 );
    function lp_token (  ) external view returns ( address );
    function manager (  ) external view returns ( address );
    function voting_escrow (  ) external view returns ( address );
    function working_balances ( address arg0 ) external view returns ( uint256 );
    function working_supply (  ) external view returns ( uint256 );
    function period (  ) external view returns ( uint256 );
    function period_timestamp ( uint256 arg0 ) external view returns ( uint256 );
    function integrate_checkpoint_of ( address arg0 ) external view returns ( uint256 );
    function integrate_fraction ( address arg0 ) external view returns ( uint256 );
    function integrate_inv_supply ( uint256 arg0 ) external view returns ( uint256 );
    function integrate_inv_supply_of ( address arg0 ) external view returns ( uint256 );
    function reward_count (  ) external view returns ( uint256 );
    function reward_tokens ( uint256 arg0 ) external view returns ( address );
    function reward_data ( address arg0 ) external view returns ( Reward memory );
    function rewards_receiver ( address arg0 ) external view returns ( address );
    function reward_integral_for ( address arg0, address arg1 ) external view returns ( uint256 );
    function is_killed (  ) external view returns ( bool );
    function inflation_rate ( uint256 arg0 ) external view returns ( uint256 );
}


// File contracts/Oracle/AggregatorV3Interface.sol

// Original license: SPDX_License_Identifier: MIT

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File contracts/Staking/FraxCrossChainFarmV4_ERC20.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ==================== FraxCrossChainFarmV4_ERC20 ====================
// ====================================================================
// No veFXS logic
// Because of lack of cross-chain reading of the gauge controller's emission rate,
// the contract sets its reward based on its token balance(s)
// Rolling 7 day reward period idea credit goes to denett
// rewardRate0 and rewardRate1 will look weird as people claim, but if you track the rewards actually emitted,
// the numbers do check out
// V3: Accepts canonicalFXS directly from Fraxferry and does not swap out
// V4: Adds variable number of rewards by using arrays instead of fixed names

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Sam Kazemian: https://github.com/samkazemian
// Dennis: github.com/denett

// Originally inspired by Synthetix.io, but heavily modified by the Frax team
// https://raw.githubusercontent.com/Synthetixio/synthetix/develop/contracts/StakingRewards.sol









// import '../Misc_AMOs/balancer/IBalancerVault.sol'; // Balancer frxETH-bb-a-WETH Gauge
// import '../Misc_AMOs/balancer/IBalancerChildLiquidityGauge.sol'; // Balancer frxETH-bb-a-WETH Gauge
// import '../Misc_AMOs/balancer/IL2BalancerPseudoMinter.sol'; // Balancer frxETH-bb-a-WETH Gauge
// import '../Misc_AMOs/balancer/IStablePool.sol'; // Balancer frxETH-bb-a-WETH Gauge

// Inheritance

/// @title FraxCrossChainFarmV4_ERC20
/// @notice Used as a farm, usually fed by rewards dropped in from various sources
contract FraxCrossChainFarmV4_ERC20 is Owned, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice Future address of veFXS, if applicable
    IveFXS public veFXS;

    /// @notice Array of all the reward tokens
    address[] public rewardTokens;
    
    // // KyberSwap Elastic
    // // Manually set during deploy
    // // ===================================================================
    // // <>KYBERSWAP<>KYBERSWAP<>KYBERSWAP<>KYBERSWAP<>KYBERSWAP<>KYBERSWAP<>KYBERSWAP<>
    // IKyberSwapFarmingToken public stakingToken; // KyberSwap Elastic
    // ComboOracle_KyberSwapElasticV2 public KSE_ComboOracleV2 = ComboOracle_KyberSwapElasticV2(0xfBCB0F967817c924f83e26e04F0FB28ED4d6276F);  // KyberSwap Elastic
    // IKyberFactory public immutable kyber_factory = IKyberFactory(0xC7a590291e07B9fe9E64b86c58fD8fC764308C4A);  // KyberSwap Elastic
    // // Need to seed a starting token to use both as a basis for fraxPerLPToken
    // // as well as getting ticks, etc
    // uint256 public seed_token_id = 7366; 
    
    // function setSeedTokenID(uint256 _seed_token_id) public onlyByOwnGov {
    //     seed_token_id = _seed_token_id;
    // }

    // function setKyberSwapElasticComboOracle(address _kse_combo_oracle_address) public onlyByOwnGov {
    //     KSE_ComboOracleV2 = ComboOracle_KyberSwapElasticV2(_kse_combo_oracle_address);
    // }
    // // <>KYBERSWAP<>KYBERSWAP<>KYBERSWAP<>KYBERSWAP<>KYBERSWAP<>KYBERSWAP<>KYBERSWAP<>


    // Balancer frxETH-bb-a-WETH Gauge or Convex frxETH/XXXETH
    // IBalancerChildLiquidityGauge public stakingToken; // Balancer frxETH-bb-a-WETH Gauge
    // AggregatorV3Interface internal priceFeedETHUSD = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612); // For Balancer frxETH-bb-a-WETH Gauge
    // function setETHUSDOracle(address _eth_usd_oracle_address) public onlyByOwnGov {
    //     require(_eth_usd_oracle_address != address(0), "Zero address detected");

    //     priceFeedETHUSD = AggregatorV3Interface(_eth_usd_oracle_address);
    // }
    // function getLatestETHPriceE8() public view returns (int) {
    //     // Returns in E8
    //     (uint80 roundID, int price, , uint256 updatedAt, uint80 answeredInRound) = priceFeedETHUSD.latestRoundData();
    //     require(price >= 0 && updatedAt!= 0 && answeredInRound >= roundID, "Invalid chainlink price");
        
    //     return price;
    // }
    
    /// @notice The token being staked
    // I2pool public stakingToken; // Curve 2-token
    // I3pool public stakingToken; // Curve 3-token
    // I3poolAndToken public stakingToken; // Curve 3-token with pool
    IConvexCvxLPRewardPoolCombo public stakingToken; // Convex cvxLP/RewardPool combo
    // IStableXPair public stakingToken; // Impossible
    // IFeederPool public stakingToken; // mStable
    // ISaddleLPToken public stakingToken; // Saddle L2D4
    // ILToken public stakingToken; // Sentiment LFrax
    // ILPToken public stakingToken; // Snowball S4D
    // IUniswapV2Pair public stakingToken; // Uniswap V2

    /// @notice An address where rewards are pulled from, if applicable
    FraxCrossChainRewarder public rewarder;

    /// @notice The address of FRAX
    address public fraxAddress;
    
    /// @notice Constant for various precisions
    uint256 private constant MULTIPLIER_PRECISION = 1e18;

    /// @notice Governance timelock address
    address public timelockAddress;

    /// @notice Gauge controller, if present
    address public controllerAddress;

    /// @notice The time the rewards period should finish
    uint256 public periodFinish;

    /// @notice The last time this contract was updated
    uint256 public lastUpdateTime;

    /// @notice The max weight multiplier you can get for locking your position
    uint256 public lock_max_multiplier = uint256(3e18); // E18. 1x = e18

    /// @notice The lock time needed to get the max weight multiplier
    uint256 public lock_time_for_max_multiplier = 3 * 365 * 86400; // 3 years

    /// @notice The minimum lock time required
    uint256 public lock_time_min = 1; // 1 second

    /// @notice How much veFXS you must have, per Frax in the LP, in order to get the veFXS boost, if applicable
    uint256 public vefxs_per_frax_for_max_boost = uint256(4e18); // E18. 4e18 means 4 veFXS must be held by the staker per 1 FRAX
    
    /// @notice The max weight multiplier you can get for having veFXS
    uint256 public vefxs_max_multiplier = uint256(2e18); // E18. 1x = 1e18

    /// @notice Tracks the veFXS multiplier of a user
    mapping(address => uint256) private _vefxsMultiplierStored;

    /// @notice The reward tokens per second
    uint256[] public rewardRates;

    /// @notice Helper to see if a token is a reward token on this farm
    mapping(address => bool) internal isRewardToken;

    /// @notice Helper to get the reward token index, given the address of the token
    mapping(address => uint256) public rewardTokenAddrToIdx;

    /// @notice The duration of each rewards period
    uint256 public rewardsDuration = 604800; // 7 * 86400 (7 days). 

    /// @notice The total amount of reward tokens owed to all farmers. Always increments
    /// @dev Technically ttlRewsOwed - ttlRewsPaid is what is actually uncollected, but both have to always be increasing
    /// for the tracking to work
    uint256[] public ttlRewsOwed;

    /// @notice The total amount of reward tokens paid out to all farmers
    uint256[] public ttlRewsPaid;

    /// @notice Accumulator for rewardsPerToken
    // https://www.paradigm.xyz/2021/05/liquidity-mining-on-uniswap-v3
    uint256[] private rewardsPerTokenStored;

    /// @notice Accumulator for userRewardsPerTokenPaid
    mapping(address => mapping(uint256 => uint256)) private userRewardsPerTokenPaid; // staker addr -> token id -> paid amount
    
    /// @notice Used for tracking current rewards
    mapping(address => mapping(uint256 => uint256)) private rewards; // staker addr -> token id -> reward amount
    
    /// @notice The last time rewards were pulled in
    uint256 public lastRewardPull;

    /// @notice The last time a farmer claimed their rewards
    mapping(address => uint256) internal lastRewardClaimTime; // staker addr -> timestamp

    /// @notice Total amount of LP in the farm
    uint256 private _total_liquidity_locked;

    /// @notice Total weight of farmers, which takes LP amount, veFXS balances, and time locked
    uint256 private _total_combined_weight;

    /// @notice A particular farmer's locked LP balance
    mapping(address => uint256) private _locked_liquidity;

    /// @notice A particular farmer's weight
    mapping(address => uint256) private _combined_weights;

    // Uniswap V2 / Impossible ONLY
    /// @notice If FRAX is token0
    bool frax_is_token0;

    /// @notice Locked stake positions for a farmer
    mapping(address => LockedStake[]) public lockedStakes;

    /// @notice List of valid migrators (set by governance)
    mapping(address => bool) public valid_migrators;

    /// @notice Stakers set which migrator(s) they want to use
    mapping(address => mapping(address => bool)) public staker_allowed_migrators;

    /// @notice Used for migrations. Prevents new stakes, but allows LP and reward withdrawals
    bool public migrationsOn;

    /// @notice Release locked stakes in case of system migration or emergency
    bool public stakesUnlocked;
    
    /// @notice If withdrawals are paused
    bool public withdrawalsPaused; 
    
    /// @notice If reward collections are paused
    bool public rewardsCollectionPaused; // For emergencies
    
    /// @notice If staking is paused
    bool public stakingPaused; // For emergencies
    
    // For emergencies if a token is overemitted or something else. Only callable once.
    // Bypasses certain logic, which will cause reward calculations to be off
    // But the goal is for the users to recover LP, and they couldn't claim the erroneous rewards anyways.
    // Reward reimbursement claims would be handled with pre-issue earned() snapshots and a claim contract, or similar.
    bool public withdrawalOnlyShutdown; 
    
    /// @notice If this contract has been initialized
    bool public isInitialized;

    /// @notice Version
    string public version = "0.0.9";

    /* ========== STRUCTS ========== */
    
    /// @notice Information about a particular locked stake
    /// @param kek_id A unique ID for the stake
    /// @param start_timestamp When the stake was locked
    /// @param liquidity How much LP the stake has
    /// @param ending_timestamp When the stake should be unlocked
    /// @param lock_multiplier Initial weight multiplier from the lock time component. 
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    /* ========== MODIFIERS ========== */

    /// @notice Only governance should be able to call
    modifier onlyByOwnGov() {
        require(msg.sender == owner || msg.sender == timelockAddress, "Not owner or timelock");
        _;
    }

    /// @notice Only governance or the controller should be able to call
    modifier onlyByOwnGovCtrlr() {
        require(msg.sender == owner || msg.sender == timelockAddress || msg.sender == controllerAddress, "Not own, tlk, or ctrlr");
        _;
    }

    /// @notice Should be in migration
    modifier isMigrating() {
        require(migrationsOn == true, "Not in migration");
        _;
    }

    /// @notice Staking should not be paused
    modifier notStakingPaused() {
        require(!stakingPaused, "Staking paused");
        _;
    }

    /// @notice Update rewards and balances
    modifier updateRewardAndBalance(address account, bool sync_too) {
        _updateRewardAndBalance(account, sync_too, false);
        _;
    }
    
    /* ========== CONSTRUCTOR ========== */

    /// @notice Constructor
    /// @param _owner The owner of the farm
    /// @param _rewardTokens Array of reward tokens
    /// @param _stakingToken The LP token being staked
    /// @param _fraxAddress Address of FRAX
    /// @param _timelockAddress Address of the timelock
    /// @param _rewarder_address Address of the rewarder contract, if applicable
    constructor (
        address _owner,
        address[] memory _rewardTokens,
        address _stakingToken,
        address _fraxAddress,
        address _timelockAddress,
        address _rewarder_address
    ) Owned(_owner){
        // Set state variables
        fraxAddress = _fraxAddress;
        rewardTokens = _rewardTokens;
        
        // Loop thought the reward tokens
        for (uint256 i = 0; i < _rewardTokens.length; i++) { 
            // For fast token address -> token ID lookups later
            rewardTokenAddrToIdx[_rewardTokens[i]] = i;

            // Add to the mapping
            isRewardToken[_rewardTokens[i]] = true;

            // Initialize the stored rewards
            rewardsPerTokenStored.push(0);

            // Initialize the rewards owed and paid
            ttlRewsOwed.push(0);
            ttlRewsPaid.push(0);

            // Initialize the reward rates
            rewardRates.push(0);
        }

        // stakingToken = IBalancerChildLiquidityGauge(_stakingToken); // Balancer frxETH-bb-a-WETH Gauge
        stakingToken = IConvexCvxLPRewardPoolCombo(_stakingToken);
        // stakingToken = I2pool(_stakingToken);
        // stakingToken = I3pool(_stakingToken);
        // stakingToken = I3poolAndToken(_stakingToken);
        // stakingToken = IStableXPair(_stakingToken);
        // stakingToken = IFeederPool(_stakingToken);
        // stakingToken = ISaddleLPToken(_stakingToken);
        // stakingToken = ILToken(_stakingToken);
        // stakingToken = ILPToken(_stakingToken);
        // stakingToken = IUniswapV2Pair(_stakingToken);
        // stakingToken = IKyberSwapFarmingToken(_stakingToken); // KyberSwap Elastic

        timelockAddress = _timelockAddress;
        rewarder = FraxCrossChainRewarder(_rewarder_address);

        // Uniswap V2 / Impossible ONLY
        // Need to know which token FRAX is (0 or 1)
        // address token0 = stakingToken.token0();
        // if (token0 == fraxAddress) frax_is_token0 = true;
        // else frax_is_token0 = false;
        
        // Other booleans
        migrationsOn = false;
        stakesUnlocked = false;

        // For initialization
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
    }

    /* ========== VIEWS ========== */

    /// @notice Total locked liquidity tokens
    /// @return uint256 Total amount of LP tokens in the farm
    function totalLiquidityLocked() external view returns (uint256) {
        return _total_liquidity_locked;
    }

    /// @notice Locked liquidity for a given account
    /// @return uint256 Total amount of LP tokens in the farm for a specific user
    function lockedLiquidityOf(address account) external view returns (uint256) {
        return _locked_liquidity[account];
    }

    /// @notice Total 'balance' used for calculating the percent of the pool the account owns
    /// @return uint256 The combined weight. Takes into account the locked stake time multiplier and veFXS multiplier
    function totalCombinedWeight() external view returns (uint256) {
        return _total_combined_weight;
    }

    /// @notice Combined weight for a specific account
    /// @return uint256 The combined weight.
    function combinedWeightOf(address account) external view returns (uint256) {
        return _combined_weights[account];
    }

    /// @notice All the locked stakes for a given account
    /// @return LockedStake Array of LockedStakes
    function lockedStakesOf(address account) external view returns (LockedStake[] memory) {
        return lockedStakes[account];
    }

    /// @notice The lock multiplier for a given amount of seconds
    /// @param secs Number of seconds you are locking
    /// @return uint256 The lock multiplier
    function lockMultiplier(uint256 secs) public view returns (uint256) {
        return Math.min(
            lock_max_multiplier,
            (secs * lock_max_multiplier) / lock_time_for_max_multiplier
        ) ;
    }

    /// @notice The last time rewards were applicable. Should be the lesser of the current timestamp, or the end of the last period
    /// @return uint256 The last timestamp where rewards were applicable
    function lastTimeRewardApplicable() internal view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice How much Frax per 1 LP token
    /// @return uint256 Amount of Frax
    function fraxPerLPToken() public view returns (uint256) {
        // Get the amount of FRAX 'inside' of the lp tokens
        uint256 frax_per_lp_token;

        // Balancer frxETH-bb-a-WETH Gauge
        // ============================================
        // {
        //     IBalancerVault vault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        //     /**
        //     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
        //     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
        //     * equals the sum of `cash` and `managed`.
        //     */
        
        //     (uint256 cash, uint256 managed, , ) = vault.getPoolTokenInfo(0xd00f9ca46ce0e4a63067c4657986f0167b0de1e5000000000000000000000b42, 0xEe327F889d5947c1dc1934Bb208a1E792F953E96);
        //     uint256 frxETH_usd_val_per_lp_e8 = ((cash + managed) * uint256(getLatestETHPriceE8())) / stakingToken.totalSupply();
        //     frax_per_lp_token = frxETH_usd_val_per_lp_e8 * (1e10); // We use USD as "Frax" here. Scale up to E18
        // }

        // Convex cvxLP/RewardPool Combo
        // ============================================
        // {
        //     // Half of the LP is FRAXBP. Half of that should be FRAX.
        //     // Using 0.25 * virtual price for gas savings
        //     ICurveChildLiquidityGauge gauge = ICurveChildLiquidityGauge(stakingToken.curveGauge());
        //     I3pool pool = I3pool(gauge.lp_token());
        //     frax_per_lp_token = pool.get_virtual_price() / 4; 
        // }

        // Convex cvxfrxETH/XXXETH
        // ============================================
        // {
        //     // Get the pool
        //     ICurveChildLiquidityGauge gauge = ICurveChildLiquidityGauge(stakingToken.curveGauge());
        //     I2poolTokenNoLending pool = I2poolTokenNoLending(gauge.lp_token());

        //     // Assume frxETH = ETH for pricing purposes
        //     // Get the USD value of the frxETH per LP token
        //     uint256 frxETH_in_pool = IERC20(0x178412e79c25968a32e89b11f63B33F733770c2A).balanceOf(address(pool));
        //     uint256 frxETH_usd_val_per_lp_e8 = (frxETH_in_pool * uint256(getLatestETHPriceE8())) / pool.totalSupply();
        //     frax_per_lp_token = frxETH_usd_val_per_lp_e8 * (1e10); // We use USD as "Frax" here
        // }

        // Curve 2-token (No Lending)
        // ============================================
        // {
        //     // Get the pool
        //     ICurveChildLiquidityGauge gauge = ICurveChildLiquidityGauge(stakingToken.curveGauge());
        //     I2poolTokenNoLending pool = I2poolTokenNoLending(gauge.lp_token());
        //     address coin0 = pool.coins(0);
        //     uint256 total_frax_reserves;
        //     uint256[2] memory _balanceResults = pool.get_balances();
        //     if (coin0 == fraxAddress) {
        //         total_frax_reserves = _balanceResults[0];
        //     }
        //     else {
        //         total_frax_reserves = _balanceResults[1];
        //     }
        //     frax_per_lp_token = total_frax_reserves.mul(1e18).div(pool.totalSupply());
        // }

    
        // Curve 3-token
        // ============================================
        // {
        //     address coin0 = stakingToken.coins(0);
        //     address coin1 = stakingToken.coins(1);
        //     uint256 total_frax_reserves;
        //     if (coin0 == fraxAddress) {
        //         total_frax_reserves = stakingToken.balances(0);
        //     }
        //     else if (coin1 == fraxAddress) {
        //         total_frax_reserves = stakingToken.balances(1);
        //     }
        //     else {
        //         total_frax_reserves = stakingToken.balances(2);
        //     }
        //     frax_per_lp_token = total_frax_reserves.mul(1e18).div(stakingToken.totalSupply());
        // }

        // Curve 3pool metapool (FRAXBP/Stable)
        // ============================================
        // {
        //     // Half of the LP is FRAXBP. Half of that should be FRAX.
        //     // Using 0.25 * virtual price for gas savings
        //     frax_per_lp_token = stakingToken.get_virtual_price() / 4; 
        // }

        // KyberSwap Elastic
        // ============================================
        // {
        //     // Fetch total pool TVL using the seed token id
        //     ComboOracle_KyberSwapElasticV2.NFTValueInfo memory nft_value_info = KSE_ComboOracleV2.getNFTValueInfo(seed_token_id);

        //     // Assume half of the liquidity is FRAX or FRAX-related, even if it is not.
        //     frax_per_lp_token = (nft_value_info.pool_tvl_usd * MULTIPLIER_PRECISION) / (stakingToken.totalSupply() * 2);
        // }

        // mStable
        // ============================================
        // {
        //     uint256 total_frax_reserves;
        //     (, IFeederPool.BassetData memory vaultData) = (stakingToken.getBasset(fraxAddress));
        //     total_frax_reserves = uint256(vaultData.vaultBalance);
        //     frax_per_lp_token = total_frax_reserves.mul(1e18).div(stakingToken.totalSupply());
        // }

        // Saddle L2D4
        // ============================================
        // {
        //     ISaddlePermissionlessSwap ISPS = ISaddlePermissionlessSwap(0xF2839E0b30B5e96083085F498b14bbc12530b734);
        //     uint256 total_frax = ISPS.getTokenBalance(ISPS.getTokenIndex(fraxAddress));
        //     frax_per_lp_token = total_frax.mul(1e18).div(stakingToken.totalSupply());
        // }

        // Most Saddles / Snowball S4D
        // ============================================
        // {
        //     ISwapFlashLoan ISFL = ISwapFlashLoan(0xfeEa4D1BacB0519E8f952460A70719944fe56Ee0);
        //     uint256 total_frax = ISFL.getTokenBalance(ISFL.getTokenIndex(fraxAddress));
        //     frax_per_lp_token = total_frax.mul(1e18).div(stakingToken.totalSupply());
        // }

        // Sentiment LFrax
        // ============================================
        // {
        //     frax_per_lp_token = stakingToken.convertToAssets(1e18);
        // }

        // Uniswap V2 & Impossible
        // ============================================
        // {
        //     uint256 total_frax_reserves;
        //     (uint256 reserve0, uint256 reserve1, ) = (stakingToken.getReserves());
        //     if (frax_is_token0) total_frax_reserves = reserve0;
        //     else total_frax_reserves = reserve1;

        //     frax_per_lp_token = total_frax_reserves.mul(1e18).div(stakingToken.totalSupply());
        // }



        return frax_per_lp_token;
    }

    /// @notice Amount of Frax in the user's locked LP
    /// @param account Address of the user
    /// @return uint256 Amount of Frax
    function userStakedFrax(address account) public view returns (uint256) {
        return (fraxPerLPToken()).mul(_locked_liquidity[account]).div(1e18);
    }

    /// @notice Minimum amount of veFXS a user needs to have to get the max veFXS boost, given their current position
    /// @param account Address of the user
    /// @return uint256 Amount of veFXS needed
    function minVeFXSForMaxBoost(address account) public view returns (uint256) {
        return (userStakedFrax(account)).mul(vefxs_per_frax_for_max_boost).div(MULTIPLIER_PRECISION);
    }

    /// @notice The weight boost multiplier from veFXS
    /// @param account Address of the user
    /// @return uint256 The multiplier
    function veFXSMultiplier(address account) public view returns (uint256) {
        if (address(veFXS) != address(0)){
            // The claimer gets a boost depending on amount of veFXS they have relative to the amount of FRAX 'inside'
            // of their locked LP tokens
            uint256 veFXS_needed_for_max_boost = minVeFXSForMaxBoost(account);
            if (veFXS_needed_for_max_boost > 0){ 
                uint256 user_vefxs_fraction = (veFXS.balanceOf(account)).mul(MULTIPLIER_PRECISION).div(veFXS_needed_for_max_boost);
                
                uint256 vefxs_multiplier = ((user_vefxs_fraction).mul(vefxs_max_multiplier)).div(MULTIPLIER_PRECISION);

                // Cap the boost to the vefxs_max_multiplier
                if (vefxs_multiplier > vefxs_max_multiplier) vefxs_multiplier = vefxs_max_multiplier;

                return vefxs_multiplier;        
            }
            else return 0; // This will happen with the first stake, when user_staked_frax is 0
        }
        else return 0;
    }

    /// @notice The current lock multiplier, due to time, for a given stake. Decays with time
    /// @param account Address of the user
    /// @param stake_idx Index of the stake
    /// @return midpoint_lock_multiplier The current lock multiplier
    function calcCurrLockMultiplier(address account, uint256 stake_idx) public view returns (uint256 midpoint_lock_multiplier) {
        // Get the stake
        LockedStake memory thisStake = lockedStakes[account][stake_idx];

        // Handles corner case where user never claims for a new stake
        // Don't want the multiplier going above the max
        uint256 accrue_start_time;
        if (lastRewardClaimTime[account] < thisStake.start_timestamp) {
            accrue_start_time = thisStake.start_timestamp;
        }
        else {
            accrue_start_time = lastRewardClaimTime[account];
        }
        
        // If the lock is expired
        if (thisStake.ending_timestamp <= block.timestamp) {
            // If the lock expired in the time since the last claim, the weight needs to be proportionately averaged this time
            if (lastRewardClaimTime[account] < thisStake.ending_timestamp){
                uint256 time_before_expiry = thisStake.ending_timestamp - accrue_start_time;
                uint256 time_after_expiry = block.timestamp - thisStake.ending_timestamp;

                // Average the pre-expiry lock multiplier
                uint256 pre_expiry_avg_multiplier = lockMultiplier(time_before_expiry / 2);

                // Get the weighted-average lock_multiplier
                // uint256 numerator = (pre_expiry_avg_multiplier * time_before_expiry) + (MULTIPLIER_PRECISION * time_after_expiry);
                uint256 numerator = (pre_expiry_avg_multiplier * time_before_expiry) + (0 * time_after_expiry);
                midpoint_lock_multiplier = numerator / (time_before_expiry + time_after_expiry);
            }
            else {
                // Otherwise, it needs to just be 1x
                // midpoint_lock_multiplier = MULTIPLIER_PRECISION;

                // Otherwise, it needs to just be 0x
                midpoint_lock_multiplier = 0;
            }
        }
        // If the lock is not expired
        else {
            // Decay the lock multiplier based on the time left
            uint256 avg_time_left;
            {
                uint256 time_left_p1 = thisStake.ending_timestamp - accrue_start_time;
                uint256 time_left_p2 = thisStake.ending_timestamp - block.timestamp;
                avg_time_left = (time_left_p1 + time_left_p2) / 2;
            }
            midpoint_lock_multiplier = lockMultiplier(avg_time_left);
        }

        // Sanity check: make sure it never goes above the initial multiplier
        if (midpoint_lock_multiplier > thisStake.lock_multiplier) midpoint_lock_multiplier = thisStake.lock_multiplier;
    }

    /// @notice Calculate the combined weight for an account
    /// @param account Address of the user
    /// @return old_combined_weight The old combined weight for the user
    /// @return new_vefxs_multiplier The new veFXS multiplier
    /// @return new_combined_weight The new combined weight for the user
    function calcCurCombinedWeight(address account) public view
        returns (
            uint256 old_combined_weight,
            uint256 new_vefxs_multiplier,
            uint256 new_combined_weight
        )
    {
        // Get the old combined weight
        old_combined_weight = _combined_weights[account];

        // Get the veFXS multipliers
        // For the calculations, use the midpoint (analogous to midpoint Riemann sum)
        new_vefxs_multiplier = veFXSMultiplier(account);

        uint256 midpoint_vefxs_multiplier;
        if (
            (_locked_liquidity[account] == 0 && _combined_weights[account] == 0) || 
            (new_vefxs_multiplier >= _vefxsMultiplierStored[account])
        ) {
            // This is only called for the first stake to make sure the veFXS multiplier is not cut in half
            // Also used if the user increased or maintained their position
            midpoint_vefxs_multiplier = new_vefxs_multiplier;
        }
        else {
            // Handles natural decay with a non-increased veFXS position
            midpoint_vefxs_multiplier = (new_vefxs_multiplier + _vefxsMultiplierStored[account]) / 2;
        }

        // Loop through the locked stakes, first by getting the liquidity * lock_multiplier portion
        new_combined_weight = 0;
        for (uint256 i = 0; i < lockedStakes[account].length; i++) {
            LockedStake memory thisStake = lockedStakes[account][i];

            // Calculate the midpoint lock multiplier
            uint256 midpoint_lock_multiplier = calcCurrLockMultiplier(account, i);

            // Calculate the combined boost
            uint256 liquidity = thisStake.liquidity;
            uint256 combined_boosted_amount = liquidity + ((liquidity * (midpoint_lock_multiplier + midpoint_vefxs_multiplier)) / MULTIPLIER_PRECISION);
            new_combined_weight += combined_boosted_amount;
        }
    }

    /// @notice The calculated rewardPerTokenStored accumulator
    /// @return _rtnRewardsPerTokenStored Array of rewardsPerTokenStored
    function rewardPerToken() public view returns (uint256[] memory _rtnRewardsPerTokenStored) {
        _rtnRewardsPerTokenStored = new uint256[](rewardTokens.length);
        if (_total_liquidity_locked == 0 || _total_combined_weight == 0) {
            _rtnRewardsPerTokenStored = rewardsPerTokenStored;
        }
        else {
            // Loop through the reward tokens
            for (uint256 i = 0; i < rewardTokens.length; i++) { 
                _rtnRewardsPerTokenStored[i] = rewardsPerTokenStored[i].add(
                    lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRates[i]).mul(1e18).div(_total_combined_weight)
                );
            }
        }

    }

    /// @notice The currently earned rewards for a user
    /// @param account The staker's address
    /// @return _rtnEarned Array of the amounts of reward tokens the staker can currently collect
    function earned(address account) public view returns (uint256[] memory _rtnEarned) {
        _rtnEarned = new uint256[](rewardTokens.length);
        if (_combined_weights[account] == 0){
            for (uint256 i = 0; i < rewardTokens.length; i++) { 
                _rtnEarned[i] = 0;
            }
        }
        else {
            uint256[] memory _rtnRewardsPerToken = rewardPerToken();

            // Loop through the reward tokens
            for (uint256 i = 0; i < rewardTokens.length; i++) { 
                _rtnEarned[i] = (_combined_weights[account].mul(_rtnRewardsPerToken[i].sub(userRewardsPerTokenPaid[account][i]))).div(1e18).add(rewards[account][i]);
            }
        }

    }

    /// @notice The duration (usually weekly) reward amounts for each token
    /// @return _rtnRewardForDuration Array of the amounts of the reward tokens
    function getRewardForDuration() external view returns (uint256[] memory _rtnRewardForDuration) {
        _rtnRewardForDuration = new uint256[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; i++) { 
            _rtnRewardForDuration[i] = rewardRates[i].mul(rewardsDuration);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Fetch a stake for a user
    /// @param staker_address The address of the user
    /// @param kek_id The kek_id of the stake
    /// @return locked_stake The stake information, as a LockedStake
    /// @return arr_idx The array index of the stake
    function _getStake(address staker_address, bytes32 kek_id) internal view returns (LockedStake memory locked_stake, uint256 arr_idx) {
        if (kek_id != 0) {
            for (uint256 i = 0; i < lockedStakes[staker_address].length; i++) { 
                if (kek_id == lockedStakes[staker_address][i].kek_id){
                    locked_stake = lockedStakes[staker_address][i];
                    arr_idx = i;
                    break;
                }
            }
        }
        require(kek_id != 0 && locked_stake.kek_id == kek_id, "Stake not found");
        
    }

    /// @notice Update the reward and balance state for a staker
    /// @param account The address of the user
    /// @param sync_too If the non-user state should be synced too
    /// @param pre_sync_vemxstored The pre-sync veFXS multiplier
    function _updateRewardAndBalance(address account, bool sync_too, bool pre_sync_vemxstored) internal {
        // Skip certain functions if we are in an emergency shutdown
        if (!withdrawalOnlyShutdown) {
            // Need to retro-adjust some things if the period hasn't been renewed, then start a new one
            if (sync_too){
                sync();
            }
        }
        
        // Used to make sure the veFXS multiplier is correct if a stake is increased, before calcCurCombinedWeight
        if (pre_sync_vemxstored){
            _vefxsMultiplierStored[account] = veFXSMultiplier(account);
        }

        if (account != address(0)) {
            // To keep the math correct, the user's combined weight must be recomputed to account for their
            // ever-changing veFXS balance.
            (   
                uint256 old_combined_weight,
                uint256 new_vefxs_multiplier,
                uint256 new_combined_weight
            ) = calcCurCombinedWeight(account);

            // Calculate the earnings first
            // Skip if we are in emergency shutdown
            if (!withdrawalOnlyShutdown) _syncEarned(account);

            // Update the user's stored veFXS multipliers
            _vefxsMultiplierStored[account] = new_vefxs_multiplier;

            // Update the user's and the global combined weights
            if (new_combined_weight >= old_combined_weight) {
                uint256 weight_diff = new_combined_weight.sub(old_combined_weight);
                _total_combined_weight = _total_combined_weight.add(weight_diff);
                _combined_weights[account] = old_combined_weight.add(weight_diff);
            } else {
                uint256 weight_diff = old_combined_weight.sub(new_combined_weight);
                _total_combined_weight = _total_combined_weight.sub(weight_diff);
                _combined_weights[account] = old_combined_weight.sub(weight_diff);
            }

        }
    }

    /// @notice Add additional LPs to an existing locked stake. Also claims rewards at the old balance first
    /// @param kek_id The kek_id of the stake
    /// @param addl_liq The amount of additional liquidity to add
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) nonReentrant public {
        // Make sure staking isn't paused
        require(!stakingPaused, "Staking paused");

        // Make sure you are not in shutdown
        require(!withdrawalOnlyShutdown, "Only withdrawals allowed");

        // Claim rewards at the old balance first
        _getReward(msg.sender, msg.sender);
        
        // Get the stake and its index
        (LockedStake memory thisStake, uint256 theArrayIndex) = _getStake(msg.sender, kek_id);

        // Calculate the new amount
        uint256 new_amt = thisStake.liquidity + addl_liq;

        // Checks
        require(addl_liq >= 0, "Must be nonzero");

        // Pull the tokens from the sender
        TransferHelper.safeTransferFrom(address(stakingToken), msg.sender, address(this), addl_liq);

        // Update the stake
        lockedStakes[msg.sender][theArrayIndex] = LockedStake(
            kek_id,
            thisStake.start_timestamp,
            new_amt,
            thisStake.ending_timestamp,
            thisStake.lock_multiplier
        );

        // Update liquidities
        _total_liquidity_locked += addl_liq;
        _locked_liquidity[msg.sender] += addl_liq;

        // Need to call to update the combined weights
        _updateRewardAndBalance(msg.sender, false, true);

        emit LockedAdditional(msg.sender, kek_id, addl_liq);
    }

    /// @notice Extends the lock of an existing stake. Also claims rewards at the old balance first
    /// @param kek_id The kek_id of the stake
    /// @param new_ending_ts The new ending timestamp you want to extend to
    function lockLonger(bytes32 kek_id, uint256 new_ending_ts) nonReentrant public {
        // Make sure staking isn't paused
        require(!stakingPaused, "Staking paused");

        // Make sure you are not in shutdown
        require(!withdrawalOnlyShutdown, "Only withdrawals allowed");

        // Claim rewards at the old balance first
        _getReward(msg.sender, msg.sender);
        
        // Get the stake and its index
        (LockedStake memory thisStake, uint256 theArrayIndex) = _getStake(msg.sender, kek_id);

        // Check
        require(new_ending_ts > block.timestamp, "Must be in the future");

        // Calculate some times
        uint256 time_left = (thisStake.ending_timestamp > block.timestamp) ? thisStake.ending_timestamp - block.timestamp : 0;
        uint256 new_secs = new_ending_ts - block.timestamp;

        // Checks
        // require(time_left > 0, "Already expired");
        require(new_secs > time_left, "Cannot shorten lock time");
        require(new_secs >= lock_time_min, "Minimum stake time not met");
        require(new_secs <= lock_time_for_max_multiplier, "Trying to lock for too long");

        // Update the stake
        lockedStakes[msg.sender][theArrayIndex] = LockedStake(
            kek_id,
            block.timestamp,
            thisStake.liquidity,
            new_ending_ts,
            lockMultiplier(new_secs)
        );

        // Need to call to update the combined weights
        _updateRewardAndBalance(msg.sender, false, true);

        emit LockedLonger(msg.sender, kek_id, new_secs, block.timestamp, new_ending_ts);
    }

    /// @notice Sync earnings for a specific staker
    /// @param account The account to sync
    function _syncEarned(address account) internal {
        if (account != address(0)) {
            // Calculate the earnings

            uint256[] memory _earneds = earned(account);
            for (uint256 i = 0; i < rewardTokens.length; i++) { 
                rewards[account][i] = _earneds[i];
                userRewardsPerTokenPaid[account][i] = rewardsPerTokenStored[i];
            }
        }
    }

    /// @notice Staker can allow a migrator 
    /// @param migrator_address The address you want to add as a migrator. The contract owner would need to have approved this address first
    function stakerAllowMigrator(address migrator_address) external {
        require(valid_migrators[migrator_address], "Invalid migrator address");
        staker_allowed_migrators[msg.sender][migrator_address] = true; 
    }

    /// @notice Staker can disallow a migrator that they previously allowed
    /// @param migrator_address The migrator address you want to disable
    function stakerDisallowMigrator(address migrator_address) external {
        // Delete from the mapping
        delete staker_allowed_migrators[msg.sender][migrator_address];
    }
    
    /// @notice Lock LP tokens
    /// @param liquidity The amount of LP tokens you want to stake
    /// @param secs The length of time you want to lock
    /// @dev Two different stake functions are needed because of delegateCall and msg.sender issues (important for migration)
    function stakeLocked(uint256 liquidity, uint256 secs) nonReentrant public {
        _stakeLocked(msg.sender, msg.sender, liquidity, secs, block.timestamp);
    }

    /// @notice If this were not internal, and source_address had an infinite approve, this could be exploitable (pull funds from source_address and stake for an arbitrary staker_address)
    /// @param staker_address The address of the farmer
    /// @param source_address The source of the LP tokens. Most of the time is the farmer, but could be the migrator
    /// @param liquidity The amount of LP tokens you want to stake
    /// @param secs The length of time you want to lock
    /// @param start_timestamp The starting timestamp of the stake. Used by the migrator, otherwise it stays the same
    function _stakeLocked(
        address staker_address, 
        address source_address, 
        uint256 liquidity, 
        uint256 secs,
        uint256 start_timestamp
    ) internal updateRewardAndBalance(staker_address, true) {
        require(!stakingPaused || valid_migrators[msg.sender] == true, "Staking paused or in migration");
        require(!withdrawalOnlyShutdown, "Only withdrawals allowed");
        require(liquidity > 0, "Must stake more than zero");
        require(secs >= lock_time_min, "Minimum stake time not met");
        require(secs <= lock_time_for_max_multiplier,"Trying to lock for too long");

        uint256 lock_multiplier = lockMultiplier(secs);
        bytes32 kek_id = keccak256(abi.encodePacked(staker_address, start_timestamp, liquidity, _locked_liquidity[staker_address]));
        lockedStakes[staker_address].push(LockedStake(
            kek_id,
            start_timestamp,
            liquidity,
            start_timestamp.add(secs),
            lock_multiplier
        ));

        // Pull the tokens from the source_address
        TransferHelper.safeTransferFrom(address(stakingToken), source_address, address(this), liquidity);

        // Update liquidities
        _total_liquidity_locked = _total_liquidity_locked.add(liquidity);
        _locked_liquidity[staker_address] = _locked_liquidity[staker_address].add(liquidity);

        // Need to call to update the combined weights
        _updateRewardAndBalance(staker_address, false, true);

        emit StakeLocked(staker_address, liquidity, secs, kek_id, source_address);
    }

    /// @notice Withdraw a stake. 
    /// @param kek_id The id for the stake
    /// @param claim_rewards_deprecated DEPRECATED, has no effect (always claims rewards regardless)
    /// @dev Two different withdrawLocked functions are needed because of delegateCall and msg.sender issues (important for migration)
    function withdrawLocked(bytes32 kek_id, bool claim_rewards_deprecated) nonReentrant public {
        require(withdrawalsPaused == false, "Withdrawals paused");
        _withdrawLocked(msg.sender, msg.sender, kek_id, claim_rewards_deprecated);
    }

    /// @notice No withdrawer == msg.sender check needed since this is only internally callable and the checks are done in the wrapper functions like withdraw(), migrator_withdraw_unlocked() and migrator_withdraw_locked()
    /// @param staker_address The address of the staker
    /// @param destination_address Destination address for the withdrawn LP
    /// @param kek_id The id for the stake
    /// @param claim_rewards_deprecated DEPRECATED, has no effect (always claims rewards regardless)
    function _withdrawLocked(address staker_address, address destination_address, bytes32 kek_id, bool claim_rewards_deprecated) internal  {
        // Collect rewards first and then update the balances
        // withdrawalOnlyShutdown to be used in an emergency situation if reward is overemitted or not available
        // and the user can forfeit rewards to get their principal back. 
        if (withdrawalOnlyShutdown) {
            // Do nothing.
        }
        else {
            // Get the rewards
            _getReward(staker_address, destination_address);
        }
        
        (LockedStake memory thisStake, uint256 theArrayIndex) = _getStake(staker_address, kek_id);
        require(block.timestamp >= thisStake.ending_timestamp || stakesUnlocked == true || valid_migrators[msg.sender] == true, "Stake is still locked!");

        uint256 liquidity = thisStake.liquidity;

        if (liquidity > 0) {
            // Update liquidities
            _total_liquidity_locked = _total_liquidity_locked.sub(liquidity);
            _locked_liquidity[staker_address] = _locked_liquidity[staker_address].sub(liquidity);

            // Remove the stake from the array
            delete lockedStakes[staker_address][theArrayIndex];

            // Need to call to update the combined weights
            _updateRewardAndBalance(staker_address, true, true);

            // Give the tokens to the destination_address
            // Should throw if insufficient balance
            stakingToken.transfer(destination_address, liquidity);

            emit WithdrawLocked(staker_address, liquidity, kek_id, destination_address);
        }

    }
    
    /// @notice Collect rewards
    /// @return uint256 The amounts of collected reward tokens
    /// @dev Two different getReward functions are needed because of delegateCall and msg.sender issues (important for migration)
    function getReward() external nonReentrant returns (uint256[] memory) {
        require(rewardsCollectionPaused == false,"Rewards collection paused");
        return _getReward(msg.sender, msg.sender);
    }

    /// @notice Collect rewards (internal)
    /// @param rewardee The address of the staker
    /// @param destination_address Destination address for the withdrawn LP
    /// @return _rtnRewards The amounts of collected reward tokens
    /// @dev No withdrawer == msg.sender check needed since this is only internally callable. This distinction is important for the migrator
    function _getReward(address rewardee, address destination_address) internal updateRewardAndBalance(rewardee, true) returns (uint256[] memory _rtnRewards) {
        // Make sure you are not in shutdown
        require(!withdrawalOnlyShutdown, "Only withdrawals allowed");
        
        _rtnRewards = new uint256[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; i++) { 
            _rtnRewards[i] = rewards[rewardee][i];

            if (_rtnRewards[i] > 0) {
                rewards[rewardee][i] = 0;
                ERC20(rewardTokens[i]).transfer(destination_address, _rtnRewards[i]);
                ttlRewsPaid[i] += _rtnRewards[i];
                emit RewardPaid(rewardee, _rtnRewards[i], rewardTokens[i], destination_address);
            }
        }
        

        // Update the last reward claim time
        lastRewardClaimTime[rewardee] = block.timestamp;
    }

    /// @notice Quasi-notifyRewardAmount() logic
    function syncRewards() internal {
        // Bring in rewards, if applicable
        if ((block.timestamp).sub(lastRewardPull) >= rewardsDuration) {
            if (address(rewarder) != address(0)) {
                rewarder.distributeReward();
            }

            // Pull in any 3rd party reward tokens, if applicable, using their specific ABI(s)
            // FXS is always assumed to be at [0]
            // for (uint256 i = 1; i < rewardTokens.length; i++) { 
            //     if (rewardTokens[i] != address(0)) {

            //     }
            // }

            {
                // Balancer
                // =========================
                // IL2BalancerPseudoMinter(0x47B489bf5836f83ABD928C316F8e39bC0587B020).mint(address(stakingToken));

                // Convex cvxLP/RewardPool Combo
                // =========================
                stakingToken.getReward(address(this));
            }


            lastRewardPull = block.timestamp;
        }

        // Loop through all the tokens
        uint256 _eligibleElapsedTime = Math.min((block.timestamp).sub(lastUpdateTime), rewardsDuration); // Cut off at the end of the week
        uint256[] memory _reward = rewardPerToken();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            // Get the current reward token balances
            uint256 _currBal = ERC20(rewardTokens[i]).balanceOf(address(this));

            // Update the owed amounts based off the old reward rates
            // Anything over a week is zeroed (see above)
            ttlRewsOwed[i] += rewardRates[i].mul(_eligibleElapsedTime);

            // Update the stored amounts too
            rewardsPerTokenStored[i] = _reward[i];

            // Set the reward rates based on the free amount of tokens
            {
                // Don't count unpaid rewards as free
                uint256 _unpaid = ttlRewsOwed[i].sub(ttlRewsPaid[i]);

                // Handle reward token0
                if (_currBal <= _unpaid){
                    // token is depleted, so stop emitting
                    rewardRates[i] = 0;
                }
                else {
                    uint256 _free = _currBal.sub(_unpaid);
                    rewardRates[i] = (_free).div(rewardsDuration);
                }

            }
        }
    }

    /// @notice Sync the contract
    function sync() public {
        require(isInitialized, "Contract not initialized");

        // Make sure you are not in shutdown
        require(!withdrawalOnlyShutdown, "Only withdrawals allowed");

        // Make sure the rewardRates are synced to the current reward token balances
        syncRewards();

        // Rolling 7 days rewards period
        lastUpdateTime = block.timestamp;
        periodFinish = (block.timestamp).add(rewardsDuration);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Needed when first deploying the farm, Make sure rewards are present
    function initializeDefault() external onlyByOwnGovCtrlr {
        require(!isInitialized, "Already initialized");
        isInitialized = true;

        // Sync the contract
        sync();

        emit DefaultInitialization();
    }

    /// @notice Migrator can stake for someone else (they won't be able to withdraw it back though, only staker_address can). 
    /// @param staker_address The address of the staker
    /// @param amount Amount of LP to stake
    /// @param secs Seconds for the lock
    /// @param start_timestamp Starting timestamp for the lock
    function migrator_stakeLocked_for(address staker_address, uint256 amount, uint256 secs, uint256 start_timestamp) external isMigrating {
        require(staker_allowed_migrators[staker_address][msg.sender] && valid_migrators[msg.sender], "Mig. invalid or unapproved");
        _stakeLocked(staker_address, msg.sender, amount, secs, start_timestamp);
    }

    /// @notice Migrator can withdraw for someone else
    /// @param staker_address The address of the staker
    /// @param kek_id The id of the stake
    function migrator_withdraw_locked(address staker_address, bytes32 kek_id) external isMigrating {
        require(staker_allowed_migrators[staker_address][msg.sender] && valid_migrators[msg.sender], "Mig. invalid or unapproved");
        _withdrawLocked(staker_address, msg.sender, kek_id, true);
    }

    /// @notice Adds a supported migrator address 
    /// @param migrator_address The address of the migrator
    function addMigrator(address migrator_address) external onlyByOwnGov {
        valid_migrators[migrator_address] = true;
    }

    /// @notice Removes a migrator address
    /// @param migrator_address The address of the migrator
    function removeMigrator(address migrator_address) external onlyByOwnGov {
        require(valid_migrators[migrator_address] == true, "Address nonexistent");
        
        // Delete from the mapping
        delete valid_migrators[migrator_address];
    }

    /// @notice Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
    /// @param tokenAddress The address of the token
    /// @param tokenAmount The amount of the token
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        // Admin cannot withdraw the staking token from the contract unless currently migrating
        if(!migrationsOn){
            require(tokenAddress != address(stakingToken), "Not in migration"); // Only Governance / Timelock can trigger a migration
        }
        // Only the owner address can ever receive the recovery withdrawal
        ERC20(tokenAddress).transfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }


    /// @notice Set various multipliers
    /// @param _lock_max_multiplier The max weight multiplier you can get for locking your position
    /// @param _vefxs_max_multiplier The max weight multiplier you can get for having veFXS
    /// @param _vefxs_per_frax_for_max_boost How much veFXS you must have, per Frax in the LP, in order to get the veFXS boost, if applicable
    function setMultipliers(uint256 _lock_max_multiplier, uint256 _vefxs_max_multiplier, uint256 _vefxs_per_frax_for_max_boost) external onlyByOwnGov {
        require(_lock_max_multiplier >= MULTIPLIER_PRECISION, "Mult must be >= MULTIPLIER_PRECISION");
        require(_vefxs_max_multiplier >= 0, "veFXS mul must be >= 0");
        require(_vefxs_per_frax_for_max_boost > 0, "veFXS pct max must be >= 0");

        lock_max_multiplier = _lock_max_multiplier;
        vefxs_max_multiplier = _vefxs_max_multiplier;
        vefxs_per_frax_for_max_boost = _vefxs_per_frax_for_max_boost;

        emit MaxVeFXSMultiplier(vefxs_max_multiplier);
        emit LockedStakeMaxMultiplierUpdated(lock_max_multiplier);
        emit veFXSPerFraxForMaxBoostUpdated(vefxs_per_frax_for_max_boost);
    }

    /// @notice Set various time variables
    /// @param _lock_time_for_max_multiplier The lock time needed to get the max weight multiplier
    /// @param _lock_time_min The minimum lock time required
    function setLockedStakeTimeForMinAndMaxMultiplier(uint256 _lock_time_for_max_multiplier, uint256 _lock_time_min) external onlyByOwnGov {
        require(_lock_time_for_max_multiplier >= 1, "Mul max time must be >= 1");
        require(_lock_time_min >= 1, "Mul min time must be >= 1");

        lock_time_for_max_multiplier = _lock_time_for_max_multiplier;
        lock_time_min = _lock_time_min;

        emit LockedStakeTimeForMaxMultiplier(lock_time_for_max_multiplier);
        emit LockedStakeMinTime(_lock_time_min);
    }

    /// @notice Unlock all stakes, in the case of an emergency
    function unlockStakes() external onlyByOwnGov {
        stakesUnlocked = !stakesUnlocked;
    }

    /// @notice Toggle migrations on or off
    function toggleMigrations() external onlyByOwnGov {
        migrationsOn = !migrationsOn;
    }

    /// @notice Only settable to true
    function initiateWithdrawalOnlyShutdown() external onlyByOwnGov {
        withdrawalOnlyShutdown = true;
    }

    /// @notice Toggle the ability to stake
    function toggleStaking() external onlyByOwnGov {
        stakingPaused = !stakingPaused;
    }

    /// @notice Toggle the ability to withdraw
    function toggleWithdrawals() external onlyByOwnGov {
        withdrawalsPaused = !withdrawalsPaused;
    }

    /// @notice Toggle the ability to collect rewards
    function toggleRewardsCollection() external onlyByOwnGov {
        rewardsCollectionPaused = !rewardsCollectionPaused;
    }

    /// @notice Set the address of the timelock
    /// @param _new_timelock The new address of the timelock
    function setTimelock(address _new_timelock) external onlyByOwnGov {
        timelockAddress = _new_timelock;
    }

    /// @notice Set the address of the controller
    /// @param _controllerAddress The new address of the controller
    function setController(address _controllerAddress) external onlyByOwnGov {
        controllerAddress = _controllerAddress;
    }

    /// @notice Set the veFXS address
    /// @param _vefxs_address The new address for veFXS
    function setVeFXS(address _vefxs_address) external onlyByOwnGov {
        veFXS = IveFXS(_vefxs_address);
    }

    /* ========== EVENTS ========== */

    /// @notice When LP tokens are locked
    /// @param user The staker
    /// @param amount Amount of LP staked
    /// @param secs Number of seconds the stake was locked
    /// @param kek_id The id of the stake
    /// @param source_address The origin address of the LP tokens. Usually the same as the user unless there is a migration in progress
    event StakeLocked(address indexed user, uint256 amount, uint256 secs, bytes32 kek_id, address source_address);
    
    /// @notice When LP tokens are withdrawn
    /// @param user The staker
    /// @param amount Amount of LP withdrawn
    /// @param kek_id The id of the stake
    /// @param destination_address Destination address of the withdrawn LP tokens
    event WithdrawLocked(address indexed user, uint256 amount, bytes32 kek_id, address destination_address);

    /// @notice When a staker collects rewards
    /// @param user The staker
    /// @param reward Amount of reward tokens
    /// @param token_address Address of the reward token
    /// @param destination_address Destination address of the reward tokens
    event RewardPaid(address indexed user, uint256 reward, address token_address, address destination_address);

    /// @notice When the farm has been initialized
    event DefaultInitialization();

    /// @notice When tokens are recovered, in the case of an emergency
    /// @param token Address of the token
    /// @param amount Amount of the recovered tokens
    event Recovered(address token, uint256 amount);

    /// @notice When the max weight multiplier you can get for locking your position is set
    /// @param multiplier The max weight multiplier
    event LockedStakeMaxMultiplierUpdated(uint256 multiplier);

    /// @notice When the lock time needed to get the max weight multiplier is set
    /// @param secs The lock time needed for the max multiplier, in seconds
    event LockedStakeTimeForMaxMultiplier(uint256 secs);

    /// @notice The minimum lock time required for a stake
    /// @param secs Min lock time, in seconds
    event LockedStakeMinTime(uint256 secs);

    /// @notice When someone adds additional LP to an existing stake
    /// @param user The staker's address
    /// @param kek_id The id of the stake
    /// @param amount The amount of extra LP being added to the stake
    event LockedAdditional(address indexed user, bytes32 kek_id, uint256 amount);

    /// @notice When someone locks for additional time
    /// @param user The staker's address
    /// @param kek_id The id of the stake
    /// @param new_secs The additional amount of seconds the lock is being extended
    /// @param new_start_ts The new start time of the stake. Should be block.timestamp
    /// @param new_end_ts The new ending time of the stake
    event LockedLonger(address indexed user, bytes32 kek_id, uint256 new_secs, uint256 new_start_ts, uint256 new_end_ts);
    
    /// @notice When the max weight multiplier you can get for having veFXS is updated
    /// @param multiplier The new max multiplier
    event MaxVeFXSMultiplier(uint256 multiplier);

    /// @notice When the amount of veFXS you must have, per Frax in the LP, in order to get the veFXS boost, if applicable
    /// @param scale_factor The new amount of veFXS
    event veFXSPerFraxForMaxBoostUpdated(uint256 scale_factor);
}


// File contracts/Staking/Variants/FraxCCFarmV4_cvxLP.sol

// Original license: SPDX_License_Identifier: GPL-2.0-or-later

contract FraxCCFarmV4_cvxLP is FraxCrossChainFarmV4_ERC20 {
    string public farm_type = "FraxCCFarmV4_cvxLP";

    constructor (
        address _owner,
        address[] memory _rewardTokens,
        address _stakingToken,
        address _fraxAddress,
        address _timelockAddress,
        address _rewarder_address
    ) 
    FraxCrossChainFarmV4_ERC20(_owner, _rewardTokens, _stakingToken, _fraxAddress, _timelockAddress, _rewarder_address)
    {}
}