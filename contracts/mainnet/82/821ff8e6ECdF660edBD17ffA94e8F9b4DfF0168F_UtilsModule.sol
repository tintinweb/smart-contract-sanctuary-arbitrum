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

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IAToken is IERC20 {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint[] calldata amounts,
    uint[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { ILendingPoolAddressesProvider } from "./ILendingPoolAddressesProvider.sol";
import { DataTypes } from "./lib/DataTypes.sol";

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

interface IController {
    function addSet(address _jasperVault) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isSet(address _jasperVault) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IJasperVault
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface IJasperVault is IERC20 {
    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
        uint256 coinType;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
        int256 virtualUnit;
        uint256 coinType;
        address[] externalPositionModules;
        mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
        uint256 coinType;
        int256 virtualUnit;
        bytes data;
    }

    /* ============ Functions ============ */
    function controller() external view returns (address);

    function editDefaultPositionCoinType(
        address _component,
        uint256 coinType
    ) external;

    function editExternalPositionCoinType(
        address _component,
        address _module,
        uint256 coinType
    ) external;

    function addComponent(address _component) external;

    function removeComponent(address _component) external;

    function editDefaultPositionUnit(
        address _component,
        int256 _realUnit
    ) external;

    function addExternalPositionModule(
        address _component,
        address _positionModule
    ) external;

    function removeExternalPositionModule(
        address _component,
        address _positionModule
    ) external;

    function editExternalPositionUnit(
        address _component,
        address _positionModule,
        int256 _realUnit
    ) external;

    function editExternalPositionData(
        address _component,
        address _positionModule,
        bytes calldata _data
    ) external;

    function invoke(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;

    function burn(address _account, uint256 _quantity) external;

    function lock() external;

    function unlock() external;

    function addModule(address _module) external;

    function removeModule(address _module) external;

    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);

    function moduleStates(address _module) external view returns (ModuleState);

    function getModules() external view returns (address[] memory);

    function getDefaultPositionRealUnit(
        address _component
    ) external view returns (int256);

    function getExternalPositionRealUnit(
        address _component,
        address _positionModule
    ) external view returns (int256);

    function getComponents() external view returns (address[] memory);

    function getExternalPositionModules(
        address _component
    ) external view returns (address[] memory);

    function getExternalPositionData(
        address _component,
        address _positionModule
    ) external view returns (bytes memory);

    function isExternalPositionModule(
        address _component,
        address _module
    ) external view returns (bool);

    function isComponent(address _component) external view returns (bool);

    function positionMultiplier() external view returns (int256);

    function getPositions() external view returns (Position[] memory);

    function getTotalComponentRealUnits(
        address _component
    ) external view returns (int256);

    function isInitializedModule(address _module) external view returns (bool);

    function isPendingModule(address _module) external view returns (bool);

    function isLocked() external view returns (bool);

    function masterToken() external view returns (address);

    function setBaseProperty(string memory _name,string memory _symbol,uint256 _followFee,uint256 _maxFollowFee) external;    
    function setBaseFeeAndToken(address _masterToken,uint256 _profitShareFee) external;

     function followFee() external view returns(uint256);
     function maxFollowFee() external view returns(uint256);
     function profitShareFee() external view returns(uint256);

     function removAllPosition() external;

}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;


/**
 * @title IModule
 * @author Set Protocol
 *
 * Interface for interacting with Modules.
 */
interface IModule {
    /**
     * Called by a SetToken to notify that this module was removed from the Set token. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

/**
 * @title IPriceOracle
 * @author Set Protocol
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {

    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { IJasperVault } from "../interfaces/IJasperVault.sol";

interface ISetValuer {
    function calculateSetTokenValuation(IJasperVault _jasperVault, address _quoteAsset) external view returns (uint256);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0

*/

pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 *
 * CHANGELOG:
 * - 4/21/21: Added validatePairsWithArray methods
 */
library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /**
     * Validate that address and uint array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of uint
     */
    function validatePairsWithArray(address[] memory A, uint[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bool array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bool
     */
    function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and string array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of strings
     */
    function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address array lengths match, and calling address array are not empty
     * and contain no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of addresses
     */
    function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bytes
     */
    function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param A          Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate addresses");
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ExplicitERC20
 * @author Set Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
    using SafeMath for uint256;

    /**
     * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     *
     * @param _token           ERC20 token to approve
     * @param _from            The account to transfer tokens from
     * @param _to              The account to transfer tokens to
     * @param _quantity        The quantity to transfer
     */
    function transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        internal
    {
        // Call specified ERC20 contract to transfer tokens (via proxy).
        if (_quantity > 0) {
            uint256 existingBalance = _token.balanceOf(_to);

            SafeERC20.safeTransferFrom(
                _token,
                _from,
                _to,
                _quantity
            );

            uint256 newBalance = _token.balanceOf(_to);

            // Verify transfer quantity is reflected in balance
            require(
                newBalance == existingBalance.add(_quantity),
                "Invalid post transfer balance"
            );
        }
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";


/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 * - 4/21/21: Added approximatelyEquals function
 * - 12/13/21: Added preciseDivCeil (int overloads) function
 * - 12/13/21: Added abs function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0). When `a` is 0, 0 is
     * returned. When `b` is 0, method reverts with divide-by-zero error.
     */
    function preciseDivCeil(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        
        a = a.mul(PRECISE_UNIT_INT);
        int256 c = a.div(b);

        if (a % b != 0) {
            // a ^ b == 0 case is covered by the previous if statement, hence it won't resolve to --c
            (a ^ b > 0) ? ++c : --c;
        }

        return c;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
        return a <= b.add(range) && a >= b.sub(range);
    }

    /**
     * Returns the absolute value of int256 `a` as a uint256
     */
    function abs(int256 a) internal pure returns (uint) {
        return a >= 0 ? a.toUint256() : a.mul(-1).toUint256();
    }

    /**
     * Returns the negation of a
     */
    function neg(int256 a) internal pure returns (int256) {
        require(a > MIN_INT_256, "Inversion overflow");
        return -a;
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IJasperVault } from "../../interfaces/IJasperVault.sol";


/**
 * @title Invoke
 * @author Set Protocol
 *
 * A collection of common utility functions for interacting with the JasperVault's invoke function
 */
library Invoke {
    using SafeMath for uint256;

    /* ============ Internal ============ */

    /**
     * Instructs the JasperVault to set approvals of the ERC20 token to a spender.
     *
     * @param _jasperVault        JasperVault instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the JasperVault's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        IJasperVault _jasperVault,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _jasperVault.invoke(_token, 0, callData);
    }

    /**
     * Instructs the JasperVault to transfer the ERC20 token to a recipient.
     *
     * @param _jasperVault        JasperVault instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        IJasperVault _jasperVault,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _jasperVault.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the JasperVault to transfer the ERC20 token to a recipient.
     * The new JasperVault balance must equal the existing balance less the quantity transferred
     *
     * @param _jasperVault        JasperVault instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        IJasperVault _jasperVault,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the JasperVault
            uint256 existingBalance = IERC20(_token).balanceOf(address(_jasperVault));

            Invoke.invokeTransfer(_jasperVault, _token, _to, _quantity);

            // Get new balance of transferred token for JasperVault
            uint256 newBalance = IERC20(_token).balanceOf(address(_jasperVault));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the JasperVault to unwrap the passed quantity of WETH
     *
     * @param _jasperVault        JasperVault instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(IJasperVault _jasperVault, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _jasperVault.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the JasperVault to wrap the passed quantity of ETH
     *
     * @param _jasperVault        JasperVault instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(IJasperVault _jasperVault, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _jasperVault.invoke(_weth, _quantity, callData);
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AddressArrayUtils } from "../../lib/AddressArrayUtils.sol";
import { ExplicitERC20 } from "../../lib/ExplicitERC20.sol";
import { IController } from "../../interfaces/IController.sol";
import { IModule } from "../../interfaces/IModule.sol";
import { IJasperVault } from "../../interfaces/IJasperVault.sol";
import { Invoke } from "./Invoke.sol";
import { Position } from "./Position.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { ResourceIdentifier } from "./ResourceIdentifier.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title ModuleBase
 * @author Set Protocol
 *
 * Abstract class that houses common Module-related state and functions.
 *
 * CHANGELOG:
 * - 4/21/21: Delegated modifier logic to internal helpers to reduce contract size
 *
 */
abstract contract ModuleBase is IModule {
    using AddressArrayUtils for address[];
    using Invoke for IJasperVault;
    using Position for IJasperVault;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    /* ============ Modifiers ============ */

    modifier onlyManagerAndValidSet(IJasperVault _jasperVault) {
        _validateOnlyManagerAndValidSet(_jasperVault);
        _;
    }

    modifier onlySetManager(IJasperVault _jasperVault, address _caller) {
        _validateOnlySetManager(_jasperVault, _caller);
        _;
    }

    modifier onlyValidAndInitializedSet(IJasperVault _jasperVault) {
        _validateOnlyValidAndInitializedSet(_jasperVault);
        _;
    }

    /**
     * Throws if the sender is not a JasperVault's module or module not enabled
     */
    modifier onlyModule(IJasperVault _jasperVault) {
        _validateOnlyModule(_jasperVault);
        _;
    }

    /**
     * Utilized during module initializations to check that the module is in pending state
     * and that the JasperVault is valid
     */
    modifier onlyValidAndPendingSet(IJasperVault _jasperVault) {
        _validateOnlyValidAndPendingSet(_jasperVault);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ Internal Functions ============ */

    /**
     * Transfers tokens from an address (that has set allowance on the module).
     *
     * @param  _token          The address of the ERC20 token
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     * @param  _quantity       The number of tokens to transfer
     */
    function transferFrom(IERC20 _token, address _from, address _to, uint256 _quantity) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }

    /**
     * Gets the integration for the module with the passed in name. Validates that the address is not empty
     */
    function getAndValidateAdapter(string memory _integrationName) internal view returns(address) {
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * Gets the integration for the module with the passed in hash. Validates that the address is not empty
     */
    function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns(address) {
        address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
            address(this),
            _integrationHash
        );

        require(adapter != address(0), "Must be valid adapter");
        return adapter;
    }

    /**
     * Gets the total fee for this module of the passed in index (fee % * quantity)
     */
    function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns(uint256) {
        uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
        return _quantity.preciseMul(feePercentage);
    }

    /**
     * Pays the _feeQuantity from the _jasperVault denominated in _token to the protocol fee recipient
     */
    function payProtocolFeeFromSetToken(IJasperVault _jasperVault, address _token, uint256 _feeQuantity) internal {
        if (_feeQuantity > 0) {
            _jasperVault.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity);
        }
    }

    /**
     * Returns true if the module is in process of initialization on the JasperVault
     */
    function isSetPendingInitialization(IJasperVault _jasperVault) internal view returns(bool) {
        return _jasperVault.isPendingModule(address(this));
    }

    /**
     * Returns true if the address is the JasperVault's manager
     */
    function isSetManager(IJasperVault _jasperVault, address _toCheck) internal view returns(bool) {
        return _jasperVault.manager() == _toCheck;
    }

    /**
     * Returns true if JasperVault must be enabled on the controller
     * and module is registered on the JasperVault
     */
    function isSetValidAndInitialized(IJasperVault _jasperVault) internal view returns(bool) {
        return controller.isSet(address(_jasperVault)) &&
            _jasperVault.isInitializedModule(address(this));
    }

    /**
     * Hashes the string and returns a bytes32 value
     */
    function getNameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /**
     * Caller must JasperVault manager and JasperVault must be valid and initialized
     */
    function _validateOnlyManagerAndValidSet(IJasperVault _jasperVault) internal view {
       require(isSetManager(_jasperVault, msg.sender), "Must be the JasperVault manager");
       require(isSetValidAndInitialized(_jasperVault), "Must be a valid and initialized JasperVault");
    }

    /**
     * Caller must JasperVault manager
     */
    function _validateOnlySetManager(IJasperVault _jasperVault, address _caller) internal view {
        require(isSetManager(_jasperVault, _caller), "Must be the JasperVault manager");
    }

    /**
     * JasperVault must be valid and initialized
     */
    function _validateOnlyValidAndInitializedSet(IJasperVault _jasperVault) internal view {
        require(isSetValidAndInitialized(_jasperVault), "Must be a valid and initialized JasperVault");
    }

    /**
     * Caller must be initialized module and module must be enabled on the controller
     */
    function _validateOnlyModule(IJasperVault _jasperVault) internal view {
        require(
            _jasperVault.moduleStates(msg.sender) == IJasperVault.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    /**
     * JasperVault must be in a pending state and module must be in pending state
     */
    function _validateOnlyValidAndPendingSet(IJasperVault _jasperVault) internal view {
        require(controller.isSet(address(_jasperVault)), "Must be controller-enabled JasperVault");
        require(isSetPendingInitialization(_jasperVault), "Must be pending initialization");
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import {IJasperVault} from "../../interfaces/IJasperVault.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";

/**
 * @title Position
 * @author Set Protocol
 *
 * Collection of helper functions for handling and updating JasperVault Positions
 *
 * CHANGELOG:
 *  - Updated editExternalPosition to work when no external position is associated with module
 */
library Position {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for uint256;

    /* ============ Helper ============ */

    /**
     * Returns whether the JasperVault has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(
        IJasperVault _jasperVault,
        address _component
    ) internal view returns (bool) {
        return _jasperVault.getDefaultPositionRealUnit(_component) > 0;
    }

    /**
     * Returns whether the JasperVault has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(
        IJasperVault _jasperVault,
        address _component
    ) internal view returns (bool) {
        return _jasperVault.getExternalPositionModules(_component).length > 0;
    }

    /**
     * Returns whether the JasperVault component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(
        IJasperVault _jasperVault,
        address _component,
        uint256 _unit
    ) internal view returns (bool) {
        return
            _jasperVault.getDefaultPositionRealUnit(_component) >=
            _unit.toInt256();
    }

    /**
     * Returns whether the JasperVault component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        IJasperVault _jasperVault,
        address _component,
        address _positionModule,
        uint256 _unit
    ) internal view returns (bool) {
        return
            _jasperVault.getExternalPositionRealUnit(
                _component,
                _positionModule
            ) >= _unit.toInt256();
    }

    /**
     * If the position does not exist, create a new Position and add to the JasperVault. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of
     * components where needed (in light of potential external positions).
     *
     * @param _jasperVault           Address of JasperVault being modified
     * @param _component          Address of the component
     * @param _newUnit            Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(
        IJasperVault _jasperVault,
        address _component,
        uint256 _newUnit
    ) internal {
        bool isPositionFound = hasDefaultPosition(_jasperVault, _component);
        if (!isPositionFound && _newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(_jasperVault, _component)) {
                _jasperVault.addComponent(_component);
            }
        } else if (isPositionFound && _newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(_jasperVault, _component)) {
                _jasperVault.removeComponent(_component);
            }
        }
        _jasperVault.editDefaultPositionUnit(_component, _newUnit.toInt256());
    }

    function editCoinType(
        IJasperVault _jasperVault,
        address _component,
        uint256 coinType
    ) internal {
        _jasperVault.editDefaultPositionCoinType(_component, coinType);
    }

    function editExternalCoinType(
        IJasperVault _jasperVault,
        address _component,
        address _module,
        uint256 coinType
    ) internal {
        _jasperVault.editExternalPositionCoinType(
            _component,
            _module,
            coinType
        );
    }

    /**
     * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position.
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component
     *    then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the
     *    external position.
     *
     * @param _jasperVault         JasperVault being updated
     * @param _component        Component position being updated
     * @param _module           Module external position is associated with
     * @param _newUnit          Position units of new external position
     * @param _data             Arbitrary data associated with the position
     */
    function editExternalPosition(
        IJasperVault _jasperVault,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    ) internal {
        if (_newUnit != 0) {
            if (!_jasperVault.isComponent(_component)) {
                _jasperVault.addComponent(_component);
                _jasperVault.addExternalPositionModule(_component, _module);
            } else if (
                !_jasperVault.isExternalPositionModule(_component, _module)
            ) {
                _jasperVault.addExternalPositionModule(_component, _module);
            }
            _jasperVault.editExternalPositionUnit(
                _component,
                _module,
                _newUnit
            );
            _jasperVault.editExternalPositionData(_component, _module, _data);
        } else {
            require(_data.length == 0, "Passed data must be null");
            // If no default or external position remaining then remove component from components array
            if (
                _jasperVault.getExternalPositionRealUnit(_component, _module) !=
                0
            ) {
                address[] memory positionModules = _jasperVault
                    .getExternalPositionModules(_component);
                if (
                    _jasperVault.getDefaultPositionRealUnit(_component) == 0 &&
                    positionModules.length == 1
                ) {
                    require(
                        positionModules[0] == _module,
                        "External positions must be 0 to remove component"
                    );
                    _jasperVault.removeComponent(_component);
                }
                _jasperVault.removeExternalPositionModule(_component, _module);
            }
        }
    }

    /**
     * Get total notional amount of Default position
     *
     * @param _setTokenSupply     Supply of JasperVault in precise units (10^18)
     * @param _positionUnit       Quantity of Position units
     *
     * @return                    Total notional amount of units
     */
    function getDefaultTotalNotional(
        uint256 _setTokenSupply,
        uint256 _positionUnit
    ) internal pure returns (uint256) {
        return _setTokenSupply.preciseMul(_positionUnit);
    }

    /**
     * Get position unit from total notional amount
     *
     * @param _setTokenSupply     Supply of JasperVault in precise units (10^18)
     * @param _totalNotional      Total notional amount of component prior to
     * @return                    Default position unit
     */
    function getDefaultPositionUnit(
        uint256 _setTokenSupply,
        uint256 _totalNotional
    ) internal pure returns (uint256) {
        return _totalNotional.preciseDiv(_setTokenSupply);
    }

    /**
     * Get the total tracked balance - total supply * position unit
     *
     * @param _jasperVault           Address of the JasperVault
     * @param _component          Address of the component
     * @return                    Notional tracked balance
     */
    function getDefaultTrackedBalance(
        IJasperVault _jasperVault,
        address _component
    ) internal view returns (uint256) {
        int256 positionUnit = _jasperVault.getDefaultPositionRealUnit(
            _component
        );
        return _jasperVault.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * Calculates the new default position unit and performs the edit with the new unit
     *
     * @param _jasperVault                 Address of the JasperVault
     * @param _component                Address of the component
     * @param _setTotalSupply           Current JasperVault supply
     * @param _componentPreviousBalance Pre-action component balance
     * @return                          Current component balance
     * @return                          Previous position unit
     * @return                          New position unit
     */
    function calculateAndEditDefaultPosition(
        IJasperVault _jasperVault,
        address _component,
        uint256 _setTotalSupply,
        uint256 _componentPreviousBalance
    ) internal returns (uint256, uint256, uint256) {
        uint256 currentBalance = IERC20(_component).balanceOf(
            address(_jasperVault)
        );
        uint256 positionUnit = _jasperVault
            .getDefaultPositionRealUnit(_component)
            .toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(
                _setTotalSupply,
                _componentPreviousBalance,
                currentBalance,
                positionUnit
            );
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(_jasperVault, _component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * Calculate the new position unit given total notional values pre and post executing an action that changes JasperVault state
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param _setTokenSupply     Supply of JasperVault in precise units (10^18)
     * @param _preTotalNotional   Total notional amount of component prior to executing action
     * @param _postTotalNotional  Total notional amount of component after the executing action
     * @param _prePositionUnit    Position unit of JasperVault prior to executing action
     * @return                    New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 _setTokenSupply,
        uint256 _preTotalNotional,
        uint256 _postTotalNotional,
        uint256 _prePositionUnit
    ) internal pure returns (uint256) {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = _preTotalNotional.sub(
            _prePositionUnit.preciseMul(_setTokenSupply)
        );
        return
            _postTotalNotional.sub(airdroppedAmount).preciseDiv(
                _setTokenSupply
            );
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IController } from "../../interfaces/IController.sol";
import { IIntegrationRegistry } from "../../interfaces/IIntegrationRegistry.sol";
import { IPriceOracle } from "../../interfaces/IPriceOracle.sol";
import { ISetValuer } from "../../interfaces/ISetValuer.sol";

/**
 * @title ResourceIdentifier
 * @author Set Protocol
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 constant internal INTEGRATION_REGISTRY_RESOURCE_ID = 0;
    // PriceOracle will always be resource ID 1 in the system
    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 1;
    // SetValuer resource will always be resource ID 2 in the system
    uint256 constant internal SET_VALUER_RESOURCE_ID = 2;
    /* ============ Internal ============ */

    /**
     * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
     * the Controller
     */
    function getIntegrationRegistry(IController _controller) internal view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
    }

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
     */
    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of Set valuer on Controller. Note: SetValuer is stored as index 2 on the Controller
     */
    function getSetValuer(IController _controller) internal view returns (ISetValuer) {
        return ISetValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity ^0.6.10;
pragma experimental "ABIEncoderV2";

import { IController } from "../../../interfaces/IController.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ModuleBase } from "../../lib/ModuleBase.sol";
import { Invoke } from "../../lib/Invoke.sol";
import { IJasperVault } from "../../../interfaces/IJasperVault.sol";
import { ModuleBase } from "../../lib/ModuleBase.sol";

import { IAToken } from "../../../interfaces/external/aave-v2/IAToken.sol";
import { ILendingPool } from "../../../interfaces/external/aave-v2/ILendingPool.sol";
import { IFlashLoanReceiver } from "../../../interfaces/external/aave-v2/IFlashLoanReceiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PreciseUnitMath } from "../../../lib/PreciseUnitMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
contract UtilsModule is ModuleBase, ReentrancyGuard,IFlashLoanReceiver{
   using PreciseUnitMath for int256;
   using SafeERC20 for IERC20;
   uint256 internal constant BORROW_RATE_MODE = 2;
   ILendingPool public lendingPool;
   address public uniswapRouter; 
   uint256 public positionMultiplier=10 ** 18;
   struct ParamInfo{
       uint256 optionType;    //1.reBalance    2.reset
       uint256 protocolType;  //1 aave  2 compound 
       IJasperVault  target;
       IJasperVault  jasperVault;
       int256 totalSupply;
       int256 ratio;
       address masterToken;
       address[]  flashLoanAssets;//flashLoan
       uint256[]  flashLoanAmounts;//flashLoan
       uint256[]  flashLoanModes;//flashLoan
       uint256 flashLoanLen;//flashLoan
       uint256 flashLoanIndex;
       address[]  handleAaveAssets;
       uint256[]  handleAaveAmounts;
       uint256 handleAaveLen;
       uint256 handleAaveIndex;
       address[]  handleAssets;//
       uint256[]  handleAmounts;//
       uint256   handleIndex;
       uint256  handleLen;

   }


   constructor(IController _controller, ILendingPool _lendingPool,address _uniswapRouter) public ModuleBase(_controller) {
        lendingPool=_lendingPool;
        uniswapRouter=_uniswapRouter;
   }

    function initialize(
        IJasperVault _jasperVault
    )
        external
    {
        _jasperVault.initializeModule();
    }


   function reset(IJasperVault _jasperVault) external nonReentrant onlyManagerAndValidSet(_jasperVault){
        int256 totalSupply=int256(_jasperVault.totalSupply());
        require(totalSupply>0,"totalSupply must greater than zero");
        address masterToken=_jasperVault.masterToken();
         ParamInfo memory param;
         param.target=_jasperVault;
         param.jasperVault=_jasperVault;
         param.totalSupply=totalSupply;
         param.masterToken=masterToken;
         param.optionType=2;
         param.protocolType=1;
        _reset(param);
   }  

   function rebalance(IJasperVault _target,IJasperVault _jasperVault,uint256 _ratio) external nonReentrant onlyManagerAndValidSet(_jasperVault){   
         int256 totalSupply=int256(_jasperVault.totalSupply());
         require(totalSupply>0,"totalSupply must greater than zero");
         address masterToken=_jasperVault.masterToken();
         ParamInfo memory param;
         param.target=_target;
         param.jasperVault=_jasperVault;
         param.ratio=int256(_ratio);
         param.totalSupply=totalSupply;
         param.masterToken=masterToken;
         param.optionType=1;
         param.protocolType=1;
        _rebalance(param);
   }


   //reset assets
   function _reset(ParamInfo memory param) internal {
       IJasperVault.Position[] memory  positions=param.jasperVault.getPositions();
       //get length
       for(uint256 i=0;i<positions.length;i++){ 
           if(positions[i].positionState==1&&positions[i].coinType==1){
                param.flashLoanLen++;
           }         
           if(positions[i].positionState==0&&positions[i].coinType==1){
                param.handleAaveLen++;
           }          
           if(positions[i].positionState==0&&positions[i].coinType==0){
                param.handleLen++;
           }                   
       }
       param.flashLoanAssets=new address[](param.flashLoanLen);
       param.flashLoanAmounts=new uint256[](param.flashLoanLen);
       param.flashLoanModes=new uint256[](param.flashLoanLen);

       param.handleAaveAssets=new address[](param.handleAaveLen);
       param.handleAssets=new address[](param.handleLen);

       for(uint256 i=0;i<positions.length;i++){ 
           if(positions[i].positionState==1&&positions[i].coinType==1){
               _updateExternalPosition(param.jasperVault,positions[i].component,positions[i].module,0,1);
               //handle data
               param.flashLoanAssets[param.flashLoanIndex]=positions[i].component;
               address dToken=BORROW_RATE_MODE==2?lendingPool.getReserveData(positions[i].component).variableDebtTokenAddress:lendingPool.getReserveData(positions[i].component).stableDebtTokenAddress;
               param.flashLoanAmounts[param.flashLoanIndex]=IERC20(dToken).balanceOf(address(param.jasperVault));
               param.flashLoanModes[param.flashLoanIndex]=0;
               param.flashLoanIndex++;
           }
           if(positions[i].positionState==0&&positions[i].coinType==1){
               _updatePosition(param.jasperVault,positions[i].component,0,1);
               param.handleAaveAssets[param.handleAaveIndex]=IAToken(positions[i].component).UNDERLYING_ASSET_ADDRESS();
               param.handleAaveIndex++;
           }        
           if(positions[i].positionState==0&&positions[i].coinType==0){
                param.handleAssets[param.handleIndex]=positions[i].component;       
                if(positions[i].component!=param.masterToken){    
                    _updatePosition(param.jasperVault,positions[i].component,0,0);
                }    
               param.handleIndex++;    
           }   
       }   
      bytes memory params=abi.encode(param);
      //is flashLoan
      if(param.flashLoanAssets.length>0){
        lendingPool.flashLoan(address(this), param.flashLoanAssets,param.flashLoanAmounts,param.flashLoanModes,address(this),params,0);
      }else{
        _afterresetToken(param,param.flashLoanAssets,param.flashLoanAmounts,param.flashLoanAmounts);
      }

   }  




   

   function _afterresetAave(       
        ParamInfo memory param,
        address[] memory assets,
        uint[] memory amounts,
        uint[] memory /*premiums*/)  internal{
            address _callContract;
            uint256  _callValue;
            bytes memory _callByteData;
            uint256 balance;
            for (uint i = 0; i < assets.length; i++) {
              param.jasperVault.invokeApprove(assets[i],address(lendingPool),amounts[i]);
              (_callContract, _callValue, _callByteData)= getAaveRepayCallData(assets[i],uint256(-1),address(param.jasperVault));
              param.jasperVault.invoke(_callContract, _callValue, _callByteData);
            }

            for(uint i=0;i<param.handleAaveAssets.length;i++){
               (_callContract,_callValue,_callByteData)= getAaveWithdrawCallData(param.handleAaveAssets[i],type(uint).max,address(param.jasperVault));
                param.jasperVault.invoke(_callContract, _callValue, _callByteData);
                 if(param.handleAaveAssets[i]!=param.masterToken){
                    balance=IERC20(param.handleAaveAssets[i]).balanceOf(address(param.jasperVault));
                    param.jasperVault.invokeApprove(param.handleAaveAssets[i],uniswapRouter,balance); 
                    (_callContract,_callValue,_callByteData)=getUniswapTokenCallData(param.handleAaveAssets[i],param.masterToken,balance,0,address(param.jasperVault));
                    param.jasperVault.invoke(_callContract, _callValue, _callByteData);
                 }
            }
   }
   function _afterresetToken(      
        ParamInfo memory param,
        address[] memory assets,
        uint[] memory amounts,
        uint[] memory premiums) internal{
            address _callContract;
            uint256  _callValue;
            bytes memory _callByteData;
            uint256 balance;

            for(uint256 i=0;i<param.handleAssets.length;i++){
                balance=IERC20(param.handleAssets[i]).balanceOf(address(param.jasperVault));
                if(balance>0&&param.handleAssets[i]!=param.masterToken){
                    param.jasperVault.invokeApprove(param.handleAssets[i],uniswapRouter,balance);                    
                    (_callContract,_callValue,_callByteData)=getUniswapTokenCallData(param.handleAssets[i],param.masterToken,balance,0,address(param.jasperVault));
                    param.jasperVault.invoke(_callContract, _callValue, _callByteData);
                }
            }
            if(assets.length>0){
                balance=IERC20(param.masterToken).balanceOf(address(param.jasperVault));
                param.jasperVault.invokeApprove(param.masterToken,uniswapRouter,balance);
                for(uint i = 0; i < assets.length; i++){
                    if(assets[i]!=param.masterToken){
                        uint256 amountOwing = amounts[i]+premiums[i];
                        if(amountOwing-balance>0){
                            (_callContract,_callValue,_callByteData)=getUniswapExactTokenCallData(param.masterToken,assets[i],amountOwing,balance,address(param.jasperVault));
                            param.jasperVault.invoke(_callContract, _callValue, _callByteData); 
                        }
                    }

                }   
            }
            balance=IERC20(param.masterToken).balanceOf(address(param.jasperVault));
            balance=uint256(int256(balance).preciseDiv(param.totalSupply));
            _updatePosition(param.jasperVault,param.masterToken,balance,0);

   }

   // 1%=1e16  100%=1e18
    function _rebalance(ParamInfo memory param) internal {
       IJasperVault.Position[] memory  positions=param.target.getPositions();
       require(positions.length==1 && positions[0].component == param.masterToken,"jasperVault not reset");
       for(uint256 i=0;i<positions.length;i++){ 
           if(positions[i].positionState==0&&positions[i].coinType==1){
                param.flashLoanLen++;
           }     
           if(positions[i].positionState==1&&positions[i].coinType==1){
                param.handleAaveLen++;
           }      
            if(positions[i].positionState==0&&positions[i].coinType==0){
                param.handleLen++;
           }                
       }
       param.flashLoanAssets=new address[](param.flashLoanLen);
       param.flashLoanAmounts=new uint256[](param.flashLoanLen);
       param.flashLoanModes=new uint256[](param.flashLoanLen);

       param.handleAaveAssets=new address[](param.handleAaveLen);
       param.handleAaveAmounts=new uint256[](param.handleAaveLen);

       param.handleAssets=new address[](param.handleLen);
       param.handleAmounts=new uint256[](param.handleLen);

       for(uint256 i=0;i<positions.length;i++){ 
           if(positions[i].positionState==0&&positions[i].coinType==1){
               param.flashLoanAssets[param.flashLoanIndex]=IAToken(positions[i].component).UNDERLYING_ASSET_ADDRESS();
               int256 newUnit=param.ratio.preciseMul(positions[i].unit);         
               param.flashLoanAmounts[param.flashLoanIndex]=uint256(newUnit.preciseMul(param.totalSupply));
               param.flashLoanModes[param.flashLoanIndex]=0;
               param.flashLoanIndex++;
               _updatePosition(param.jasperVault,positions[i].component,uint256(newUnit),1);
              
           }         

          if(positions[i].positionState==1&&positions[i].coinType==1){
               param.handleAaveAssets[param.handleAaveIndex]=positions[i].component;
               int256 newUnit=param.ratio.preciseMul(int256(positions[i].unit.abs()));
               param.handleAaveAmounts[param.handleAaveIndex]=uint256(newUnit.preciseMul(param.totalSupply));
               param.handleAaveIndex++;
               _updateExternalPosition(param.jasperVault,positions[i].component,positions[i].module,newUnit.neg(),1);
    
           }   
           if(positions[i].positionState==0&&positions[i].coinType==0){       
                int256 newUnit=param.ratio.preciseMul(positions[i].unit);
                param.handleAssets[param.handleIndex]=positions[i].component;       
                param.handleAmounts[param.handleIndex]=uint256(newUnit.preciseMul(param.totalSupply));
                param.handleIndex++;
                if(positions[i].component!=param.masterToken){
                    _updatePosition(param.jasperVault,positions[i].component,uint256(newUnit),0);
                }                
           }
       }   
      bytes memory params=abi.encode(param);
      if(param.flashLoanAssets.length>0){
        lendingPool.flashLoan(address(this), param.flashLoanAssets,param.flashLoanAmounts,param.flashLoanModes,address(this),params,0);
      }else{
         _afterRebalanceToken(param,param.flashLoanAssets,param.flashLoanAmounts,param.flashLoanAmounts);
      }

    } 
    function executeOperation(
        address[] calldata assets,
        uint[] calldata amounts,
        uint[] calldata premiums,
        address /*initiator*/,
        bytes calldata params
    ) external override returns (bool) {   
         (ParamInfo memory param)= abi.decode(params,(ParamInfo)); 
         for(uint256 i=0;i<assets.length;i++){
              IERC20(assets[i]).safeTransfer(address(param.jasperVault),amounts[i]);
         }
        if(param.optionType==1){
            _afterRebalanceAave(param,assets,amounts,premiums);
            _afterRebalanceToken(param,assets,amounts,premiums);
        }
        if(param.optionType==2){
            _afterresetAave(param,assets,amounts,premiums);
            _afterresetToken(param,assets,amounts,premiums);
        }     

        for(uint256 i=0;i<assets.length;i++){
             param.jasperVault.invokeTransfer(assets[i],address(this),(amounts[i]+premiums[i]));
        }
        for (uint i = 0; i < assets.length; i++) {
            IERC20(assets[i]).approve(address(lendingPool),(amounts[i]+premiums[i]));
        }
        // repay Aave
        return true;      
    }

    function _afterRebalanceAave(
        ParamInfo memory param,
        address[] memory assets,
        uint[] memory amounts,
        uint[] memory /*premiums*/
        ) internal {
            address _callContract;
            uint256  _callValue;
            bytes memory _callByteData;
            for (uint i = 0; i < assets.length; i++) {
              param.jasperVault.invokeApprove(assets[i],address(lendingPool),amounts[i]);
              (_callContract, _callValue, _callByteData)= getAaveDepositCallData(assets[i],amounts[i],address(param.jasperVault));
              param.jasperVault.invoke(_callContract, _callValue, _callByteData);
            }
            for(uint i=0;i<param.handleAaveAssets.length;i++){
               (_callContract,_callValue,_callByteData)= getAaveBorrowCallData(param.handleAaveAssets[i],param.handleAaveAmounts[i],address(param.jasperVault));
                param.jasperVault.invoke(_callContract, _callValue, _callByteData);
                 if(param.handleAaveAssets[i]!=param.masterToken){
                    param.jasperVault.invokeApprove(param.handleAaveAssets[i],uniswapRouter,param.handleAaveAmounts[i]); 
                    (_callContract,_callValue,_callByteData)=getUniswapTokenCallData(param.handleAaveAssets[i],param.masterToken,param.handleAaveAmounts[i],0,address(param.jasperVault));
                    param.jasperVault.invoke(_callContract, _callValue, _callByteData);
                 }

            }
    }

    function _afterRebalanceToken(
        ParamInfo memory param,        
        address[] memory assets,
        uint[] memory amounts,
        uint[] memory premiums) internal {
            address _callContract;
            uint256  _callValue;
            bytes memory _callByteData;
            uint256 balance=IERC20(param.masterToken).balanceOf(address(param.jasperVault));
            param.jasperVault.invokeApprove(param.masterToken,uniswapRouter,balance);           
            for(uint256 i=0;i<param.handleAssets.length;i++){
                 if(param.handleAssets[i]!=param.masterToken){
                    (_callContract,_callValue,_callByteData)=getUniswapExactTokenCallData(param.masterToken,param.handleAssets[i], param.handleAmounts[i],balance,address(param.jasperVault));
                    param.jasperVault.invoke(_callContract, _callValue, _callByteData); 
                 }           
            }

            if(assets.length>0){ 
                for(uint i = 0; i < assets.length; i++){
                    if(assets[i]!=param.masterToken){
                        uint256 amountOwing = amounts[i]+premiums[i];
                        (_callContract,_callValue,_callByteData)=getUniswapExactTokenCallData(param.masterToken,assets[i],amountOwing,balance,address(param.jasperVault));
                        param.jasperVault.invoke(_callContract, _callValue, _callByteData); 
                    }

                }
            }
            balance=IERC20(param.masterToken).balanceOf(address(param.jasperVault));
            balance=uint256(int256(balance).preciseDiv(param.totalSupply));
            _updatePosition(param.jasperVault,param.masterToken,balance,0);
    }
    function getAaveDepositCallData(
        address _asset,
        uint256 _amount,
        address _onBehalfOf
        ) internal view  returns (address, uint256, bytes memory){
            bytes memory callData = abi.encodeWithSignature(
                 "deposit(address,uint256,address,uint16)",
                 _asset,
                 _amount,
                 _onBehalfOf,
                 0
            );
            return (address(lendingPool), 0, callData);
    }
    function getAaveBorrowCallData(
        address _asset,
        uint256 _amount,
        address _onBehalfOf
       ) internal view  returns (address, uint256, bytes memory){
            bytes memory callData = abi.encodeWithSignature(
                 "borrow(address,uint256,uint256,uint16,address)",
                  _asset,
                  _amount,     
                  BORROW_RATE_MODE,
                  0,
                  _onBehalfOf     
            );           
            
            return (address(lendingPool), 0, callData);
         
    }
    function getAaveRepayCallData(address _assset,uint256 _amount,address _onBehalfOf) internal view  returns (address, uint256, bytes memory) {
            bytes memory callData = abi.encodeWithSignature(
                 "repay(address,uint256,uint256,address)",
                  _assset,
                  _amount,     
                  BORROW_RATE_MODE,
                  _onBehalfOf     
            );           
            
            return (address(lendingPool), 0, callData);
    }
    function getAaveWithdrawCallData(address _asset,uint256 _amount,address _to) internal view  returns (address, uint256, bytes memory) {
            bytes memory callData = abi.encodeWithSignature(
                 "withdraw(address,uint256,address)",
                  _asset,
                  _amount,     
                  _to     
            );           
            
            return (address(lendingPool), 0, callData);
     }
    function getUniswapTokenCallData(
        address _assetIn,
        address _assetOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) internal view  returns (address, uint256, bytes memory){
            address[] memory _path=new address[](2);
            _path[0]=_assetIn;
            _path[1]=_assetOut;
            uint _deadline = block.timestamp + 300;
            bytes memory callData = abi.encodeWithSignature(
                 "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                 _amountIn,
                 _amountOutMin,
                 _path,
                 _to,
                 _deadline
            );                    
            return (address(uniswapRouter), 0, callData);
    }
    function getUniswapExactTokenCallData(
        address _assetIn,
        address _assetOut,
        uint256 _amountOut,
        uint256 _amountInMax,
        address _to
    ) internal view  returns (address, uint256, bytes memory){
            address[] memory _path=new address[](2);
            _path[0]=_assetIn;
            _path[1]=_assetOut;
            uint _deadline = block.timestamp + 300;
            bytes memory callData = abi.encodeWithSignature(
                 "swapTokensForExactTokens(uint256,uint256,address[],address,uint256)",
                 _amountOut,
                 _amountInMax,
                 _path,
                 _to,
                 _deadline
            );                    
            return (address(uniswapRouter), 0, callData);
    }   
    function _updatePosition(
        IJasperVault _jasperVault,
        address _token,
        uint256 _newPositionUnit,
        uint256 _coinType
    ) internal {
        _jasperVault.editCoinType(_token,_coinType);
        _jasperVault.editDefaultPosition(_token, _newPositionUnit);
    }
   
    function _updateExternalPosition(
        IJasperVault _jasperVault,
        address _token,
        address _module,
        int256 _newPositionUnit,
        uint256 _coinType
    ) internal {
        _jasperVault.editExternalCoinType(_token,_module,_coinType);
        _jasperVault.editExternalPosition(
            _token,
            _module,
            _newPositionUnit,
            ""
        );
    
    }

   function removeModule() external override {}
}