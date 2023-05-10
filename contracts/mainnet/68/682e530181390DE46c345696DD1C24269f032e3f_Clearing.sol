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
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

/// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "./interfaces/IAlgebraPoolV2.sol";
import "./interfaces/IOracle.sol";

/// @title Clearing v1.2.3
/// @notice Proxy contract for hypervisor positions management
contract Clearing is ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  string constant VERSION = '1.2.3';
  address public owner;
  mapping(address => Position) public positions;

  bool public twapCheck = false;
  uint32 public twapInterval = 120;
  uint256 public depositDelta = 1010;
  uint256 public deltaScale = 1000; /// must be a power of 10
  uint256 public priceThreshold = 100;
  uint256 constant MAX_UINT = 2**256 - 1;

  struct Position {
    bool zeroDeposit;
    bool customRatio;
    bool customTwap;
    bool ratioRemoved;
    bool depositOverride; // force custom deposit constraints
    bool twapOverride; // force twap check for hypervisor instance
    uint8 version; 
    uint32 twapInterval; // override global twap
    uint256 priceThreshold; // custom price threshold
    uint256 deposit0Max;
    uint256 deposit1Max;
    uint256 maxTotalSupply;
    uint256 fauxTotal0;
    uint256 fauxTotal1;
    mapping(address=>bool) list; // whitelist certain accounts for freedeposit
  }

  event PositionAdded(address, uint8);
  event CustomDeposit(address, uint256, uint256, uint256);
  event PriceThresholdSet(uint256 _priceThreshold);
  event DepositDeltaSet(uint256 _depositDelta);
  event DeltaScaleSet(uint256 _deltaScale);
  event TwapIntervalSet(uint32 _twapInterval);
  event TwapOverrideSet(address pos, bool twapOverride, uint32 _twapInterval, uint256 _priceThreshold);
  event PriceThresholdPosSet(address pos, uint256 _priceThreshold);
  event DepositZeroToggled();
  event DepositOverrideToggled(address pos);
  event DepositZeroOverrideToggled(address pos);
  event TwapToggled();
  event ListAppended(address pos, address[] listed);
  event ListRemoved(address pos, address listed);
  event CustomRatio(address pos, uint256 fauxTotal0, uint256 fauxTotal1);
  event RatioRemoved(address pos);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyAddedPosition(address pos) {
    Position storage p = positions[pos];
    require(p.version != 0, "not added");
    _;
  }

  /// @notice Add the hypervisor position
  /// @param pos Address of the hypervisor
  /// @param version Type of hypervisor
  function addPosition(address pos, uint8 version) external onlyOwner {
    Position storage p = positions[pos];
    require(p.version == 0, 'already added');
    require(version > 0, 'version < 1');
    p.version = version;
    IHypervisor(pos).token0().safeApprove(pos, MAX_UINT);
    IHypervisor(pos).token1().safeApprove(pos, MAX_UINT);
    emit PositionAdded(pos, version);
  }

  /// @notice apply configuration constraints to shares minted 
  /// @param pos Address of the hypervisor
  /// @param shares Amount of shares minted (included for upgrades)
  /// @return cleared whether shares are cleared 
  function clearShares(
    address pos,
    uint256 shares 
  ) public view onlyAddedPosition(pos) returns (bool cleared) {
    if(positions[pos].maxTotalSupply != 0) {
      require(IHypervisor(pos).totalSupply() <= positions[pos].maxTotalSupply, "exceeds max supply");
    }
    return true;
  }

  /// @notice apply configuration constraints to deposit 
  /// @param pos Address of the hypervisor
  /// @param deposit0 Amount of token0 to deposit
  /// @param deposit1 Amount of token1 to deposit
  /// @param to Address to receive liquidity tokens
  /// @param pos Hypervisor Address
  /// @param minIn min assets to expect in position during a direct deposit 
  /// @return cleared whether deposit is cleared 
  function clearDeposit(
    uint256 deposit0,
    uint256 deposit1,
    address to,
    address pos,
    uint256[4] memory minIn
  ) public view onlyAddedPosition(pos) returns (bool cleared) {
    require(to != address(0), "to should be non-zero");
    Position storage p = positions[pos];
    if(!positions[pos].list[msg.sender]) {
      if(!p.zeroDeposit) require(deposit0 > 0 && deposit1 > 0, "must deposit to both sides");
      if (deposit0 > 0) {
        (uint256 test1Min, uint256 test1Max) = getDepositAmount(pos, address(IHypervisor(pos).token0()), deposit0);
        require(deposit1 >= test1Min && deposit1 <= test1Max, "Improper ratio"); 
      }
      if (deposit1 > 0) {
        (uint256 test0Min, uint256 test0Max) = getDepositAmount(pos, address(IHypervisor(pos).token1()), deposit1);
        require(deposit0 >= test0Min && deposit0 <= test0Max, "Improper ratio"); 
      }
    }
    if (twapCheck || p.twapOverride) {
      /// check twap
      checkPriceChange(
        pos,
        (p.twapOverride ? p.twapInterval : twapInterval),
        (p.twapOverride ? p.priceThreshold : priceThreshold)
      );
    }

    if (p.depositOverride) {
      if (p.deposit0Max > 0) {
        require(deposit0 <= p.deposit0Max, "token0 exceeds");
      }
      if (p.deposit1Max > 0) {
        require(deposit1 <= p.deposit1Max, "token1 exceeds");
      }
    }
    return true;
  }

  /// @notice Get the amount of token to deposit for the given amount of pair token
  /// @param pos Hypervisor Address
  /// @param token Address of token to deposit
  /// @param _deposit Amount of token to deposit
  /// @return amountStart Minimum amounts of the pair token to deposit
  /// @return amountEnd Maximum amounts of the pair token to deposit
  function getDepositAmount(
    address pos,
    address token,
    uint256 _deposit
  ) public view returns (uint256 amountStart, uint256 amountEnd) {
    require(token == address(IHypervisor(pos).token0()) || token == address(IHypervisor(pos).token1()), "token mistmatch");
    require(_deposit > 0, "deposits can't be zero");
    (uint256 total0, uint256 total1) = IHypervisor(pos).getTotalAmounts();
    if (IHypervisor(pos).totalSupply() == 0 || total0 == 0 || total1 == 0) {
      amountStart = 0;
      if (token == address(IHypervisor(pos).token0())) {
        amountEnd = IHypervisor(pos).deposit1Max();
      } else {
        amountEnd = IHypervisor(pos).deposit0Max();
      }
    } else {
      (uint256 ratioStart, uint256 ratioEnd) = positions[pos].customRatio ? 
        applyRatio(pos, token, positions[pos].fauxTotal0, positions[pos].fauxTotal1) :
        applyRatio(pos, token, total0, total1);
      amountStart = FullMath.mulDiv(_deposit, 1e18, ratioStart);
      amountEnd = FullMath.mulDiv(_deposit, 1e18, ratioEnd);
    }
  }

  /// @notice Get range for deposit based on provided amounts
  /// @param pos Hypervisor Address
  /// @param token Address of token to deposit
  /// @param total0 Amount of token0 in hype 
  /// @param total1 Amount of token1 in hype 
  /// @return ratioStart Minimum amounts of the pair token to deposit
  /// @return ratioEnd Maximum amounts of the pair token to deposit
  function applyRatio(
    address pos,
    address token,
    uint256 total0,
    uint256 total1
  ) public view returns (uint256 ratioStart, uint256 ratioEnd) {
    require(token == address(IHypervisor(pos).token0()) || token == address(IHypervisor(pos).token1()), "token mistmatch");
    if (token == address(IHypervisor(pos).token0())) {
      ratioStart = FullMath.mulDiv(total0.mul(depositDelta), 1e18, total1.mul(deltaScale));
      ratioEnd = FullMath.mulDiv(total0.mul(deltaScale), 1e18, total1.mul(depositDelta));
    } else {
      ratioStart = FullMath.mulDiv(total1.mul(depositDelta), 1e18, total0.mul(deltaScale));
      ratioEnd = FullMath.mulDiv(total1.mul(deltaScale), 1e18, total0.mul(depositDelta));
    }
  }

  /// @notice Check if the price change overflows or not based on given twap and threshold in the hypervisor
  /// @param pos Hypervisor Address
  /// @param _twapInterval Time intervals
  /// @param _priceThreshold Price Threshold
  /// @return price Current price
  function checkPriceChange(
    address pos,
    uint32 _twapInterval,
    uint256 _priceThreshold
  ) public view returns (uint256 price) {
    uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(IHypervisor(pos).currentTick());
    price = FullMath.mulDiv(uint256(sqrtPrice).mul(uint256(sqrtPrice)), 1e18, 2**(96 * 2));

    uint160 sqrtPriceBefore = getSqrtTwapX96(pos, _twapInterval);
    uint256 priceBefore = FullMath.mulDiv(uint256(sqrtPriceBefore).mul(uint256(sqrtPriceBefore)), 1e18, 2**(96 * 2));
    if (price.mul(100).div(priceBefore) > _priceThreshold || priceBefore.mul(100).div(price) > _priceThreshold)
      revert("Price change Overflow");
  }

  /// @notice Get the sqrt price before the given interval
  /// @param pos Hypervisor Address
  /// @param _twapInterval Time intervals
  /// @return sqrtPriceX96 Sqrt price before interval
  function getSqrtTwapX96(address pos, uint32 _twapInterval) public view returns (uint160 sqrtPriceX96) {
    (sqrtPriceX96, , , , , , ) = IHypervisor(pos).pool().globalState();
    /// return the current price if _twapInterval == 0
    if (_twapInterval != 0) {
      uint32[] memory secondsAgos = new uint32[](2);
      secondsAgos[0] = _twapInterval; /// from (before)
      secondsAgos[1] = 0; /// to (now)

      (int56[] memory tickCumulatives, ) = IOracle((IHypervisor(pos).pool()).dataStorageOperator()).getTimepoints(secondsAgos);
      sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
        int24((tickCumulatives[1] - tickCumulatives[0]) / _twapInterval)
      );  
    }   
  }

  /// @param _priceThreshold Price Threshold
  function setPriceThreshold(uint256 _priceThreshold) external onlyOwner {
    priceThreshold = _priceThreshold;
    emit PriceThresholdSet(_priceThreshold);
  }

  /// @param _depositDelta Number to calculate deposit ratio
  function setDepositDelta(uint256 _depositDelta) external onlyOwner {
    depositDelta = _depositDelta;
    emit DepositDeltaSet(_depositDelta);
  }

  /// @param _deltaScale Number to calculate deposit ratio
  function setDeltaScale(uint256 _deltaScale) external onlyOwner {
    deltaScale = _deltaScale;
    emit DeltaScaleSet(_deltaScale);
  }

  /// @param pos Hypervisor address
  /// @param deposit0Max Amount of maximum deposit amounts of token0
  /// @param deposit1Max Amount of maximum deposit amounts of token1
  /// @param maxTotalSupply Maximum total suppoy of hypervisor
  function customDeposit(
    address pos,
    uint256 deposit0Max,
    uint256 deposit1Max,
    uint256 maxTotalSupply
  ) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.deposit0Max = deposit0Max;
    p.deposit1Max = deposit1Max;
    p.maxTotalSupply = maxTotalSupply;
    emit CustomDeposit(pos, deposit0Max, deposit1Max, maxTotalSupply);
  }

  /// @param pos Hypervisor address
  /// @param customRatio whether to use custom ratio 
  /// @param fauxTotal0 override total0
  /// @param fauxTotal1 override total1 
  function customRatio(
    address pos,
    bool customRatio,
    uint256 fauxTotal0,
    uint256 fauxTotal1
  ) external onlyOwner onlyAddedPosition(pos) {
    require(!positions[pos].ratioRemoved, "custom ratio is no longer available");
    Position storage p = positions[pos];
    p.customRatio = customRatio;
    p.fauxTotal0 = fauxTotal0;
    p.fauxTotal1 = fauxTotal1;
    emit CustomRatio(pos, fauxTotal0, fauxTotal1);
  }

  // @note permantently remove ability to apply custom ratio to hype
  function removeRatio(address pos) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.ratioRemoved = true;
    emit RatioRemoved(pos);
  }

  /// @notice Toggle deposit override
  /// @param pos Hypervisor Address
  function toggleDepositOverride(address pos) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.depositOverride = !p.depositOverride;
    emit DepositOverrideToggled(pos);
  }

  /// @notice Toggle free deposit of the given hypervisor
  /// @param pos Hypervisor Address
  function toggleDepositZeroOverride(address pos) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.zeroDeposit = !p.zeroDeposit;
    emit DepositZeroOverrideToggled(pos);
  }

  /// @param _twapInterval Time intervals
  function setTwapInterval(uint32 _twapInterval) external onlyOwner {
    twapInterval = _twapInterval;
    emit TwapIntervalSet(_twapInterval);
  }

  /// @param pos Hypervisor Address
  /// @param twapOverride Twap Override
  /// @param _twapInterval Time Intervals
  /// @param _priceThreshold Price Threshold
  function setTwapOverride(address pos, bool twapOverride, uint32 _twapInterval, uint256 _priceThreshold) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.twapOverride = twapOverride;
    p.twapInterval = _twapInterval;
    p.priceThreshold = _priceThreshold;
    emit TwapOverrideSet(pos, twapOverride, _twapInterval, _priceThreshold);
  }

  /// @notice Twap Toggle
  function toggleTwap() external onlyOwner {
    twapCheck = !twapCheck;
    emit TwapToggled();
  }

  // @notice check if an address is whitelisted for hype
  function getListed(address pos, address i) public view returns(bool) {
    Position storage p = positions[pos];
    return p.list[i];
  }

  /// @notice Append whitelist to hypervisor
  /// @param pos Hypervisor Address
  /// @param listed Address array to add in whitelist
  function appendList(address pos, address[] memory listed) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    for (uint8 i; i < listed.length; i++) {
      p.list[listed[i]] = true;
    }
    emit ListAppended(pos, listed);
  }

  /// @notice Remove address from whitelist
  /// @param pos Hypervisor Address
  /// @param listed Address to remove from whitelist
  function removeListed(address pos, address listed) external onlyOwner onlyAddedPosition(pos) {
    Position storage p = positions[pos];
    p.list[listed] = false;
    emit ListRemoved(pos, listed);
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "newOwner should be non-zero");
    owner = newOwner;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "only owner");
    _;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IAlgebraPoolV2 {
	function token0() external view returns(address);
	function token1() external view returns(address);
	function tickSpacing() external view returns(int24);
	function burn(int24, int24, uint128) external returns(uint256,uint256); 
	function mint(address, address, int24, int24, uint128, bytes calldata) external returns(uint256,uint256,uint128); 
	function collect(address, int24, int24, uint128, uint128) external returns(uint256,uint256); 
	function positions(bytes32) external view returns(uint256, uint256, uint256, uint128, uint128);
	function globalState() external view returns(uint160, int24, uint16, uint16, uint16, uint8, bool);
  function dataStorageOperator() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAlgebraPoolV2.sol";
interface IHypervisor {


  function deposit(
      uint256,
      uint256,
      address,
      address,
      uint256[4] memory minIn
  ) external returns (uint256);

  function withdraw(
    uint256,
    address,
    address,
    uint256[4] memory
  ) external returns (uint256, uint256);

  function compound() external returns (

    uint128 baseToken0Owed,
    uint128 baseToken1Owed,
    uint128 limitToken0Owed,
    uint128 limitToken1Owed
  );

  function compound(uint256[4] memory inMin) external returns (

    uint128 baseToken0Owed,
    uint128 baseToken1Owed,
    uint128 limitToken0Owed,
    uint128 limitToken1Owed
  );


  function rebalance(
    int24 _baseLower,
    int24 _baseUpper,
    int24 _limitLower,
    int24 _limitUpper,
    address _feeRecipient,
    uint256[4] memory minIn, 
    uint256[4] memory outMin
    ) external;

  function addBaseLiquidity(
    uint256 amount0, 
    uint256 amount1,
    uint256[2] memory minIn
  ) external;

  function addLimitLiquidity(
    uint256 amount0, 
    uint256 amount1,
    uint256[2] memory minIn
  ) external;   

  function pullLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint128 shares,
    uint256[2] memory amountMin
  ) external returns (
    uint256 base0,
    uint256 base1
  );

  function pullLiquidity(
    uint256 shares,
    uint256[4] memory minAmounts 
  ) external returns(
      uint256 base0,
      uint256 base1,
      uint256 limit0,
      uint256 limit1
  );

  function addLiquidity(
      int24 tickLower,
      int24 tickUpper,
      uint256 amount0,
      uint256 amount1,
      uint256[2] memory inMin
  ) external;

  function pool() external view returns (IAlgebraPoolV2);

  function currentTick() external view returns (int24 tick);
  
  function tickSpacing() external view returns (int24 spacing);

  function baseLower() external view returns (int24 tick);

  function baseUpper() external view returns (int24 tick);

  function limitLower() external view returns (int24 tick);

  function limitUpper() external view returns (int24 tick);

  function token0() external view returns (IERC20);

  function token1() external view returns (IERC20);

  function deposit0Max() external view returns (uint256);

  function deposit1Max() external view returns (uint256);

  function balanceOf(address) external view returns (uint256);

  function approve(address, uint256) external returns (bool);

  function transferFrom(address, address, uint256) external returns (bool);

  function transfer(address, uint256) external returns (bool);

  function getTotalAmounts() external view returns (uint256 total0, uint256 total1);
  
  function getBasePosition() external view returns (uint256 liquidity, uint256 total0, uint256 total1);

  function totalSupply() external view returns (uint256 );

  function setWhitelist(address _address) external;
  
  function setFee(uint8 newFee) external;
  
  function removeWhitelisted() external;

  function transferOwnership(address newOwner) external;

}

interface IOracle {
	function getTimepoints(uint32[] memory secondsAgos) external view returns (int56[] memory tickCumulatives, uint112[] memory volatilityCumulatives);
}