/**
 *Submitted for verification at Arbiscan on 2022-12-29
*/

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity >=0.6.0 <0.8.0;



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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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


// File contracts/interfaces/IVVSPair.sol

pragma solidity 0.6.12;

interface IVVSPair {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function kLast() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function sync() external;
}


// File contracts/libraries/VVSLibrary.sol

// Ref https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
pragma solidity 0.6.12;


library VVSLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "VVSLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "VVSLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 initCodehash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        initCodehash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 initCodehash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IVVSPair(
            pairFor(factory, tokenA, tokenB, initCodehash)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }
}


// File contracts/interfaces/IVVSFactory.sol

pragma solidity 0.6.12;

interface IVVSFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


// File contracts/libraries/Babylonian.sol

// Exact copy of https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/Babylonian.sol
pragma solidity 0.6.12;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}


// File contracts/libraries/FullMath.sol

// Exact copy of https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/FullMath.sol
pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1

library FullMath {
    function fullMul(uint256 x, uint256 y)
        internal
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, "FullMath: FULLDIV_OVERFLOW");
        return fullDiv(l, h, d);
    }
}


// File contracts/libraries/VVSLiquidityMathLibrary.sol

// Ref: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2LiquidityMathLibrary.sol
pragma solidity 0.6.12;





// library containing some math for dealing with the liquidity shares of a pair, e.g. computing their exact value
// in terms of the underlying tokens
library VVSLiquidityMathLibrary {
    using SafeMath for uint256;

    // computes liquidity value given all the parameters of the pair
    function computeLiquidityValue(
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 liquidityAmount,
        bool feeOn,
        uint256 kLast
    ) internal pure returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        if (feeOn && kLast > 0) {
            uint256 rootK = Babylonian.sqrt(reservesA.mul(reservesB));
            uint256 rootKLast = Babylonian.sqrt(kLast);
            if (rootK > rootKLast) {
                uint256 numerator1 = totalSupply;
                uint256 numerator2 = rootK.sub(rootKLast);
                uint256 denominator = rootK.mul(4).add(rootKLast);
                uint256 feeLiquidity = FullMath.mulDiv(
                    numerator1,
                    numerator2,
                    denominator
                );
                totalSupply = totalSupply.add(feeLiquidity);
            }
        }
        return (
            reservesA.mul(liquidityAmount) / totalSupply,
            reservesB.mul(liquidityAmount) / totalSupply
        );
    }

    // get all current parameters from the pair and compute value of a liquidity amount
    // **note this is subject to manipulation, e.g. sandwich attacks**. prefer passing a manipulation resistant price to
    // #getLiquidityValueAfterArbitrageToPrice
    function getLiquidityValue(
        address factory,
        address tokenA,
        address tokenB,
        uint256 liquidityAmount,
        bytes32 initCodeHash
    ) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        (uint256 reservesA, uint256 reservesB) = VVSLibrary.getReserves(
            factory,
            tokenA,
            tokenB,
            initCodeHash
        );
        IVVSPair pair = IVVSPair(
            VVSLibrary.pairFor(factory, tokenA, tokenB, initCodeHash)
        );
        bool feeOn = IVVSFactory(factory).feeTo() != address(0);
        uint256 kLast = feeOn ? pair.kLast() : 0;
        uint256 totalSupply = pair.totalSupply();
        return
            computeLiquidityValue(
                reservesA,
                reservesB,
                totalSupply,
                liquidityAmount,
                feeOn,
                kLast
            );
    }
}


// File contracts/interfaces/IVVSRouter.sol

pragma solidity 0.6.12;

interface IVVSRouter {
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


// File contracts/interfaces/ICraftsman.sol

pragma solidity 0.6.12;

interface ICraftsman {
    function userInfo(uint256 pid, address user)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256,
            uint256,
            uint256
        );

    function pendingVVS(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function owner() external view returns (address);

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) external;

    function poolLength() external view returns (uint256);
}


// File contracts/ConditionalLiquidity.sol

pragma solidity 0.6.12;












contract ConditionalLiquidity is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IVVSFactory public immutable factory;
    IVVSRouter public immutable router;
    ICraftsman public immutable craftsman;
    IERC20 public immutable vvs;
    bytes32 public immutable INIT_CODE_PAIR_HASH;

    uint256 public constant MAX_VVS_FEE = 10000; // 100%
    uint256 public vvsTreasuryFee = 400; // 4%
    uint256 public vvsCallerFee = 100; // 1 %

    address public treasury;

    // Store how LP user have deposited. LP address -> (User address, staked)
    mapping(address => mapping(address => UserInfo)) public userInfo;

    // Store LP address to craftsman info
    mapping(address => PoolInfo) public lpPoolInfo;

    // Store whether an address is whitelisted to breakLp
    bool public breakLpWhitelistEnabled = true;
    mapping(address => bool) public breakLpWhitelist;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        bool hasRuleEnabled; // whether the user has rule enabled
        uint256 minToken0Amt; // how much token0 before break
        uint256 minToken1Amt; // how much token1 before break
        uint256 rewardDebt; // number of reward debt which user has claimed
    }

    struct PoolInfo {
        uint256 pid; // pid of craftsman
        uint256 accVVSPerLp; // number of VVS per Lp
    }

    event Deposit(
        address indexed user,
        address indexed lpToken,
        uint256 amount
    );
    event Withdraw(
        address indexed user,
        address indexed lpToken,
        uint256 amount
    );
    event LpRuleUpdate(
        address indexed user,
        address indexed lpToken,
        bool hasRuleEnabled,
        uint256 token0,
        uint256 token1
    );
    event LpRedeemed(
        address indexed user,
        address indexed caller,
        address indexed lpToken,
        uint256 liquidity,
        uint256 token0,
        uint256 token1
    );
    event TreasuryReward(address indexed lpToken, uint256 vvsAmount);
    event CallerReward(
        address indexed lpToken,
        address indexed user,
        uint256 vvsAmount
    );
    event PoolSet(address indexed lpToken, uint256 pid);
    event SetVVSTreasuryFee(uint256 vvsFee);
    event SetVVSCallerFee(uint256 vvsFee);
    event SetTreasury(address treasury);
    event BreakLpWhitelistAdded(address addr);
    event BreakLpWhitelistRemoved(address addr);
    event BreakLpWhitelistEnabledSet(bool enabled);
    event EmergencyWithdraw(address indexed user, address indexed lpToken, uint256 amount);

    modifier onlyVVSPair(IVVSPair _lpToken) {
        address pair = VVSLibrary.pairFor(
            address(factory),
            _lpToken.token0(),
            _lpToken.token1(),
            INIT_CODE_PAIR_HASH
        );
        require(
            pair == address(_lpToken),
            "ConditionalLiquidity: Not VVS pair"
        );
        _;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "ConditionalLiquidity: EXPIRED");
        _;
    }

    constructor(
        IVVSFactory _factory,
        IVVSRouter _router,
        ICraftsman _craftsman,
        IERC20 _vvs,
        address _treasury
    ) public {
        factory = _factory;
        router = _router;
        craftsman = _craftsman;
        vvs = _vvs;
        treasury = _treasury;
        INIT_CODE_PAIR_HASH = _factory.INIT_CODE_PAIR_HASH();
    }

    /**
     * @dev Set up new pool or overwrite existing lpToken pool pid
     */
    function setPoolPid(IVVSPair _lpToken, uint256 _pid)
        external
        onlyVVSPair(_lpToken)
        onlyOwner
    {
        require(_pid > 0, "ConditionalLiquidity: pid must be 1 or greater");
        PoolInfo storage pool = lpPoolInfo[address(_lpToken)];

        uint256 balance = _lpToken.balanceOf(address(this));
        uint256 pid = pool.pid;

        // Verify if pid is assigned this lpToken on craftsman
        (address craftsmanPoolLp, , , ) = craftsman.poolInfo(_pid);
        require(
            craftsmanPoolLp == address(_lpToken),
            "ConditionalLiquidity: LP token not same as craftsman"
        );

        // Scenario 1: PID does not exist previously, deposit LP craftsman
        if (pid == 0 && balance != 0) {
            _lpToken.approve(address(craftsman), balance);
            craftsman.deposit(_pid, balance);
        }

        // Scenario 2: PID exist previously - migrate to the other pid and update pool.accVVSPerLp
        if (pid != 0) {
            (uint256 _totalLp, ) = craftsman.userInfo(pid, address(this));

            if (_totalLp > 0) {
                // Update pool.accVVSPerLp so existing user can claim them later
                uint256 pendingVVS = craftsman.pendingVVS(pid, address(this));

                pool.accVVSPerLp = pool.accVVSPerLp.add(
                    pendingVVS.mul(1e12).div(_totalLp)
                );
                craftsman.withdraw(pid, _totalLp);

                // deposit all LP token in contract
                _lpToken.approve(address(craftsman), _totalLp.add(balance));
                craftsman.deposit(_pid, _totalLp.add(balance));
            }
        }

        pool.pid = _pid;
        emit PoolSet(address(_lpToken), _pid);
    }

    /**
     * @dev Deposit user's LP, remove existing rule for user
     * If amount: 0 - trigger only vvs rewards collection
     */
    function deposit(IVVSPair _lpToken, uint256 _amount)
        external
        onlyVVSPair(_lpToken)
        whenNotPaused
    {
        if (_amount > 0) {
            _lpToken.transferFrom(msg.sender, address(this), _amount);
        }

        UserInfo storage user = userInfo[address(_lpToken)][msg.sender];
        PoolInfo storage pool = lpPoolInfo[address(_lpToken)];

        uint256 pid = pool.pid;
        // pid != 0 means lp token has a craftsman pid
        if (pid != 0) {
            (uint256 _totalLp, ) = craftsman.userInfo(pid, address(this)); // get total amount staked
            uint256 pendingVVS = craftsman.pendingVVS(pid, address(this));
            if (pendingVVS > 0 && _totalLp > 0) {
                // _totalLp should be over 0 here if there is pending vvs
                pool.accVVSPerLp = pool.accVVSPerLp.add(
                    pendingVVS.mul(1e12).div(_totalLp)
                );
            }

            // deposit lp token from here into the craftsman to get pending vvs as well
            _lpToken.approve(address(craftsman), _amount);
            craftsman.deposit(pid, _amount);

            uint256 pending = user.amount.mul(pool.accVVSPerLp).div(1e12).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                uint256 fee = _distributeVVSFeeToTreasury(_lpToken, pending);
                vvs.safeTransfer(msg.sender, pending.sub(fee));
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            _removeRule(_lpToken, msg.sender);
        }
        user.rewardDebt = user.amount.mul(pool.accVVSPerLp).div(1e12);
        emit Deposit(msg.sender, address(_lpToken), _amount);
    }

    /**
     * @dev Withdraw user's LP, remove existing rule for user
     * If amount: 0 - trigger only vvs rewards collection
     */
    function withdraw(IVVSPair _lpToken, uint256 _amount) external {
        UserInfo storage user = userInfo[address(_lpToken)][msg.sender];
        require(
            _amount <= user.amount,
            "ConditionalLiquidity: withdraw amount > balance"
        );

        PoolInfo storage pool = lpPoolInfo[address(_lpToken)];

        uint256 pid = pool.pid;
        // pid != 0 means lp token has a craftsman pid
        if (pid != 0) {
            (uint256 _totalLp, ) = craftsman.userInfo(pid, address(this)); // get total amount staked
            uint256 pendingVVS = craftsman.pendingVVS(pid, address(this));
            if (pendingVVS > 0 && _totalLp > 0) {
                // _totalLp should be over 0 here if there is pending vvs
                pool.accVVSPerLp = pool.accVVSPerLp.add(
                    pendingVVS.mul(1e12).div(_totalLp)
                );
            }

            // withdraw lp token from craftsman to get pending vvs as well
            craftsman.withdraw(pid, _amount);

            uint256 pending = user.amount.mul(pool.accVVSPerLp).div(1e12).sub(
                user.rewardDebt
            );

            if (pending > 0) {
                uint256 fee = _distributeVVSFeeToTreasury(_lpToken, pending);
                vvs.safeTransfer(msg.sender, pending.sub(fee));
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            _lpToken.transfer(msg.sender, _amount);
            _removeRule(_lpToken, msg.sender);
        }
        user.rewardDebt = user.amount.mul(pool.accVVSPerLp).div(1e12);
        emit Withdraw(msg.sender, address(_lpToken), _amount);
    }

    /**
     * @dev Add rule for an LP. If existing rule exist, it will be replaced
     * @param _lpToken token to add rule for
     * @param _minToken0Amt min token0 amount, must be higher than current LP value
     * @param _minToken1Amt min token1 amount, must be higher than current LP value
     * @param _deadline in sec, if block timestamp is after, txn will fail
     */
    function addRule(
        IVVSPair _lpToken,
        uint256 _minToken0Amt,
        uint256 _minToken1Amt,
        uint256 _deadline
    ) external ensure(_deadline) whenNotPaused {
        UserInfo storage user = userInfo[address(_lpToken)][msg.sender];
        require(user.amount > 0, "ConditionalLiquidity: Amount is 0");

        (uint256 token0Amt, uint256 token1Amt) = VVSLiquidityMathLibrary
            .getLiquidityValue(
                address(factory),
                _lpToken.token0(),
                _lpToken.token1(),
                user.amount,
                INIT_CODE_PAIR_HASH
            );

        // Either token0 or token1 must be greater than LP current val
        require(
            token0Amt < _minToken0Amt || token1Amt < _minToken1Amt,
            "ConditionalLiquidity: token0 or token1 must be greater than LP val"
        );

        user.hasRuleEnabled = true;
        user.minToken0Amt = _minToken0Amt;
        user.minToken1Amt = _minToken1Amt;

        emit LpRuleUpdate(
            msg.sender,
            address(_lpToken),
            true,
            _minToken0Amt,
            _minToken1Amt
        );
    }

    /**
     * @dev remove previously set rule for the lp token
     * @param _lpToken address of lp token to remove rule
     */
    function removeRule(IVVSPair _lpToken) external {
        _removeRule(_lpToken, msg.sender);
    }

    /**
     * @dev Break user LP if it matches user's rule,
     * @dev Requirements: lp token0 and token1 matches user's rule
     * @param _lpToken address of lp token to break
     * @param _user address of user
     */
    function breakLp(IVVSPair _lpToken, address _user)
        external
        whenNotPaused
        nonReentrant
    {
        require(
            !breakLpWhitelistEnabled || breakLpWhitelist[msg.sender],
            "CL: Not in whitelist"
        );

        UserInfo storage user = userInfo[address(_lpToken)][_user];
        require(user.amount > 0, "ConditionalLiquidity: No LP added");
        require(user.hasRuleEnabled, "ConditionalLiquidity: No rule");

        uint256 amount = user.amount;

        PoolInfo storage pool = lpPoolInfo[address(_lpToken)];

        uint256 pid = pool.pid;
        // pid != 0 means lp token has a craftsman pid
        if (pid != 0) {
            (uint256 _totalLp, ) = craftsman.userInfo(pid, address(this)); // get total amount staked

            uint256 pendingVVS = craftsman.pendingVVS(pid, address(this));
            if (pendingVVS > 0 && _totalLp > 0) {
                // _totalLp should not be 0 over here if there is pending vvs
                pool.accVVSPerLp = pool.accVVSPerLp.add(
                    pendingVVS.mul(1e12).div(_totalLp)
                );
            }

            // deposit lp token from here into the craftsman to get pending vvs as well
            craftsman.withdraw(pid, amount);

            uint256 pending = amount.mul(pool.accVVSPerLp).div(1e12).sub(
                user.rewardDebt
            );

            if (pending > 0) {
                // fee to treasury and caller
                uint256 treasuryFee = _distributeVVSFeeToTreasury(
                    _lpToken,
                    pending
                );
                uint256 callerFee = _distributeVVSFeeToCaller(
                    _lpToken,
                    pending,
                    msg.sender
                );
                vvs.safeTransfer(
                    _user,
                    pending.sub(treasuryFee).sub(callerFee)
                );
            }
        }

        address token0 = _lpToken.token0();
        address token1 = _lpToken.token1();
        
        // Store the token0 and token1 diff in user bal 
        uint256 beforeToken0Bal = IERC20(token0).balanceOf(address(_user));
        uint256 beforeToken1Bal = IERC20(token1).balanceOf(address(_user));
        _lpToken.approve(address(router), amount);
        router.removeLiquidity(
            token0,
            token1,
            amount,
            0,
            0,
            _user,
            block.timestamp.add(600)
        );
        uint256 afterToken0Bal = IERC20(token0).balanceOf(address(_user));
        uint256 afterToken1Bal = IERC20(token1).balanceOf(address(_user));

        uint256 token0Diff = afterToken0Bal.sub(beforeToken0Bal);
        require(
            token0Diff >= user.minToken0Amt,
            "ConditionalLiquidity: token0Diff below minToken0Amt"
        );
        uint256 token1Diff = afterToken1Bal.sub(beforeToken1Bal);
        require(
            token1Diff >= user.minToken1Amt,
            "ConditionalLiquidity: token1Diff under minToken1Amt"
        );

        // revert user's rule and set amount = 0
        user.amount = 0;
        user.rewardDebt = 0;
        _removeRule(_lpToken, _user);

        emit LpRedeemed(
            _user,
            msg.sender,
            address(_lpToken),
            amount,
            token0Diff,
            token1Diff
        );
    }

    /**
     * @notice get pending VVS for the user, does not take into account of fees
     * @param _lpToken adress of lp token to check
     * @param _user address of user to check
     * @return user pending vvs
     */
    function pendingVVS(IVVSPair _lpToken, address _user)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[address(_lpToken)][_user];
        PoolInfo storage pool = lpPoolInfo[address(_lpToken)];

        uint256 pid = pool.pid;
        if (pid == 0) {
            return 0; // not staked in craftsman = 0 vvs reward
        }

        (uint256 _totalLp, ) = craftsman.userInfo(pid, address(this)); // get total amount staked
        uint256 accVVSPerLp = pool.accVVSPerLp;
        if (_totalLp != 0) {
            uint256 poolPendingVVS = craftsman.pendingVVS(pid, address(this));
            accVVSPerLp = pool.accVVSPerLp.add(
                poolPendingVVS.mul(1e12).div(_totalLp)
            );
        }

        return user.amount.mul(accVVSPerLp).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Update vvs treasury fee,, check that treasury + caller fee does not exceed max fee
     */
    function setVVSTreasuryFee(uint256 _vvsTreasuryFee) external onlyOwner {
        require(
            _vvsTreasuryFee.add(vvsCallerFee) <= MAX_VVS_FEE,
            "ConditionalLiquidity: fee cannot be more than MAX_VVS_FEE"
        );
        vvsTreasuryFee = _vvsTreasuryFee;

        emit SetVVSTreasuryFee(_vvsTreasuryFee);
    }

    /**
     * @dev Update vvs caller fee, check that treasury + caller fee does not exceed max fee
     */
    function setVVSCallerFee(uint256 _vvsCallerFee) external onlyOwner {
        require(
            _vvsCallerFee.add(vvsTreasuryFee) <= MAX_VVS_FEE,
            "ConditionalLiquidity: fee cannot be more than MAX_VVS_FEE"
        );
        vvsCallerFee = _vvsCallerFee;

        emit SetVVSCallerFee(_vvsCallerFee);
    }

    /*
     * @dev Update treasury
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;

        emit SetTreasury(_treasury);
    }

    /**
     * @dev add addresses to breakLp whitelist
     * @param addr address
     */
    function addAddressesToWhitelist(address addr) external onlyOwner {
        if (!breakLpWhitelist[addr]) {
            breakLpWhitelist[addr] = true;
            emit BreakLpWhitelistAdded(addr);
        }
    }

    /**
     * @dev remove an address from breakLp whitelist
     * @param addr address
     */
    function removeAddressFromWhitelist(address addr) external onlyOwner {
        if (breakLpWhitelist[addr]) {
            breakLpWhitelist[addr] = false;
            emit BreakLpWhitelistRemoved(addr);
        }
    }

    /**
     * @dev if true, breakLp only allow whitelist caller, else anyone can call breakLp
     */
    function setBreakLpWhitelistEnabled(bool _enabled) external onlyOwner {
        breakLpWhitelistEnabled = _enabled;
        emit BreakLpWhitelistEnabledSet(_enabled);
    }

    function _removeRule(IVVSPair _lpToken, address _user) internal {
        UserInfo storage user = userInfo[address(_lpToken)][_user];
        user.hasRuleEnabled = false;
        user.minToken0Amt = 0;
        user.minToken1Amt = 0;
        emit LpRuleUpdate(_user, address(_lpToken), false, 0, 0);
    }

    /**
     * @dev distribute vvs fee to treasury
     * @return fee sent to treasury
     */
    function _distributeVVSFeeToTreasury(IVVSPair _lpToken, uint256 _amt)
        internal
        returns (uint256)
    {
        uint256 fee = 0;
        if (_amt > 0) {
            fee = _amt.mul(vvsTreasuryFee).div(MAX_VVS_FEE);

            vvs.safeTransfer(treasury, fee);
            emit TreasuryReward(address(_lpToken), fee);
        }

        return fee;
    }

    /**
     * @dev distribute vvs fee to caller
     * @return fee sent to caller
     */
    function _distributeVVSFeeToCaller(
        IVVSPair _lpToken,
        uint256 _amt,
        address _caller
    ) internal returns (uint256) {
        uint256 fee = 0;

        if (_amt > 0) {
            fee = _amt.mul(vvsCallerFee).div(MAX_VVS_FEE);

            vvs.safeTransfer(_caller, fee);
            emit CallerReward(address(_lpToken), _caller, fee);
        }

        return fee;
    }

    /**
     * @notice withdraw without caring about rewards. EMERGENCY ONLY.
     */
    function emergencyWithdraw(IVVSPair _lpToken) public onlyVVSPair(_lpToken) {
        UserInfo storage user = userInfo[address(_lpToken)][msg.sender];
        PoolInfo storage pool = lpPoolInfo[address(_lpToken)];

        uint256 pid = pool.pid;
        uint256 amount = user.amount;
        if (pid != 0) {
            (uint256 _totalLp, ) = craftsman.userInfo(pid, address(this)); 
            uint256 pending = craftsman.pendingVVS(pid, address(this));
            uint256 remainingLp = _totalLp.sub(amount);

            // Split user's reward with the remaining stakers, however if user was 
            // the only staker, any pending vvs reward goes to the contract
            if (pending > 0 && remainingLp > 0) {
                pool.accVVSPerLp = pool.accVVSPerLp.add(
                    pending.mul(1e12).div(remainingLp)
                );
            }

            craftsman.withdraw(pid, amount);
        }

        user.amount = 0;
        user.rewardDebt = 0;

        _lpToken.transfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, address(_lpToken), amount);
    }
}