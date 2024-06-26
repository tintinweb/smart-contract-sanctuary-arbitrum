/**
 *Submitted for verification at Arbiscan.io on 2024-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

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
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

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
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
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

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// From https://github.com/AmbireTech/signature-validator/blob/main/contracts/EIP6492.sol
// with minimal modifications

// From https://eips.ethereum.org/EIPS/eip-6492
// you can use `ValidateSigOffchain` for this library in exactly the same way that the other contract (DeploylessUniversalSigValidator.sol) is used
// As per ERC-1271
interface IERC1271Wallet {
  function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}

error ERC1271Revert(bytes error);
error ERC6492DeployFailed(bytes error);
error InvalidSignatureLength();
error InvalidSignatureVValue();

contract UniversalSigValidator {
  bytes32 private constant ERC6492_DETECTION_SUFFIX = 0x6492649264926492649264926492649264926492649264926492649264926492;
  bytes4 private constant ERC1271_SUCCESS = 0x1626ba7e;

  function isValidSigImpl(
    address _signer,
    bytes32 _hash,
    bytes calldata _signature,
    bool allowSideEffects
  ) public returns (bool) {
    uint256 contractCodeLen = address(_signer).code.length;
    bytes memory sigToValidate;
    // The order here is strictly defined in https://eips.ethereum.org/EIPS/eip-6492
    // - ERC-6492 suffix check and verification first, while being permissive in case the contract is already deployed; if the contract is deployed we will check the sig against the deployed version, this allows 6492 signatures to still be validated while taking into account potential key rotation
    // - ERC-1271 verification if there's contract code
    // - finally, ecrecover
    bool isCounterfactual = _signature.length >= 32
      && bytes32(_signature[_signature.length-32:_signature.length]) == ERC6492_DETECTION_SUFFIX;
    if (isCounterfactual) {
      address create2Factory;
      bytes memory factoryCalldata;
      (create2Factory, factoryCalldata, sigToValidate) = abi.decode(_signature[0:_signature.length-32], (address, bytes, bytes));

      if (contractCodeLen == 0) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory err) = create2Factory.call(factoryCalldata);
        if (!success) revert ERC6492DeployFailed(err);
      }
    } else {
      sigToValidate = _signature;
    }

    // Try ERC-1271 verification
    if (isCounterfactual || contractCodeLen > 0) {
      try IERC1271Wallet(_signer).isValidSignature(_hash, sigToValidate) returns (bytes4 magicValue) {
        bool isValid = magicValue == ERC1271_SUCCESS;

        if (contractCodeLen == 0 && isCounterfactual && !allowSideEffects) {
          // if the call had side effects we need to return the
          // result using a `revert` (to undo the state changes)
          assembly {
           mstore(0, isValid)
           revert(31, 1)
          }
        }

        return isValid;
      } catch (bytes memory err) { revert ERC1271Revert(err); }
    }

    // ecrecover verification
    if (_signature.length != 65) {
      revert InvalidSignatureLength();
    }
    bytes32 r = bytes32(_signature[0:32]);
    bytes32 s = bytes32(_signature[32:64]);
    uint8 v = uint8(_signature[64]);
    if (v != 27 && v != 28) {
      revert InvalidSignatureVValue();
    }
    return ECDSA.recover(_hash, v, r, s) == _signer;
  }

  function isValidSigWithSideEffects(address _signer, bytes32 _hash, bytes calldata _signature)
    external returns (bool)
  {
    return this.isValidSigImpl(_signer, _hash, _signature, true);
  }

  function isValidSig(address _signer, bytes32 _hash, bytes calldata _signature)
    public returns (bool)
  {
    try this.isValidSigImpl(_signer, _hash, _signature, false) returns (bool isValid) { return isValid; }
    catch (bytes memory error) {
      // in order to avoid side effects from the contract getting deployed, the entire call will revert with a single byte result
      uint256 len = error.length;
      if (len == 1) return error[0] == 0x01;
      // all other errors are simply forwarded, but in custom formats so that nothing else can revert with a single byte in the call
      else assembly { revert(add(error, 0x20), len) }
    }
  }
}

// this is a helper so we can perform validation in a single eth_call without pre-deploying a singleton
contract ValidateSigOffchain {
  constructor (address _signer, bytes32 _hash, bytes memory _signature) {
    UniversalSigValidator validator = new UniversalSigValidator();
    bool isValidSig = validator.isValidSigWithSideEffects(_signer, _hash, _signature);
    assembly {
      mstore(0, isValidSig)
      return(31, 1)
    }
  }
}

error InvalidEip1271Signature(bytes32 orderHash, address account, bytes signature);
error OrderNotPresigned(bytes32 orderHash, address account);
error InvalidPresignLength(uint256 expectedLength, uint256 actualLength);

/// @notice Limit order signature validator
contract SignatureValidator is UniversalSigValidator {

  /// @dev Storage for keeping pre-signed orders
  mapping(address account => mapping(bytes32 orderHash => bool preSigned)) public preSignedOrders;

  /// @dev Keeps the signature and the signature validation method
  struct Signature {
    /// Depending on the validationMethod value, the signature format is:
    /// EIP712 - 65 bytes signature represented as abi.encodePacked(r, s, v)
    /// EIP1271 - the first 20 bytes contain the order owner address and the remaining part contains the signature
    /// PreSign - 20 bytes which contain the order owner address
    bytes signature;
    SignatureValidationMethod validationMethod;
  }

  /// @dev Order signature validation methods
  /// EIP712
  /// EIP1271
  /// PreSign - The order hash expected to be added via the setPreSignature() function prior to execution
  enum SignatureValidationMethod {
    EIP712,
    EIP1271,
    PreSign
  }

  /// @dev Event for setting pre-signature for an order hash
  event OrderPreSigned(
    bytes32 indexed orderHash,
    address indexed account,
    bool preSigned
  );

  /// @dev Validates the signature and decodes the order owner address
  /// @param orderHash Order hash
  /// @param encodedSignature order signature or account address or account address and order signature, depending on the validationMethod value
  /// @return account Order owner address
  function _getOrderOwnerOrRevert(
    bytes32 orderHash,
    bytes calldata encodedSignature,
    SignatureValidationMethod validationMethod
  )
  internal
  returns (address account)
  {
    if (validationMethod == SignatureValidationMethod.EIP712) {
      account = ECDSA.recover(orderHash, encodedSignature);
    } else if (validationMethod == SignatureValidationMethod.EIP1271) {
      assembly {
        // account = address(encodedSignature[0:20])
        account := shr(96, calldataload(encodedSignature.offset))
      }
      // the first 20 bytes of the encodedSignature contain the account address,
      // and the remaining part of the bytes array contains the signature.
      bytes calldata signature = encodedSignature[20:];

      if (!isValidSig(account, orderHash, signature)) {
        revert InvalidEip1271Signature(orderHash, account, signature);
      }
    } else { // validationMethod == SignatureValidationMethod.PreSign
      if (encodedSignature.length != 20) {
        revert InvalidPresignLength(20, encodedSignature.length);
      }
      assembly {
        // account = address(encodedSignature[0:20])
        account := shr(96, calldataload(encodedSignature.offset))
      }

      if (!preSignedOrders[account][orderHash]) {
        revert OrderNotPresigned(orderHash, account);
      }
    }
  }

  /// @notice Sets a pre-signature for the specified order hash
  /// @param orderHash EIP712 encoded order hash of single or multi input limit order
  /// @param preSigned True to set the order as enabled for filling with pre-sign, false to unset it
  function setPreSignature(
    bytes32 orderHash,
    bool preSigned
  )
  external
  {
    preSignedOrders[msg.sender][orderHash] = preSigned;
    emit OrderPreSigned(orderHash, msg.sender, preSigned);
  }
}

/// @title Odos executor interface
interface IOdosExecutor {
  function executePath (
    bytes calldata bytecode,
    uint256[] memory inputAmount,
    address msgSender
  ) external payable;
}

/// @title Odos router v2 interface
interface IOdosRouterV2 {

  /// @dev Holds all information for a given referral
  // solhint-disable-next-line contract-name-camelcase
  struct referralInfo {
    uint64 referralFee;
    address beneficiary;
    bool registered;
  }

  function referralLookup(
    uint32 referralCode
  )
  external
  view
  returns (
    referralInfo memory ri
  );

  function registerReferralCode(
    uint32 _referralCode,
    uint64 _referralFee,
    address _beneficiary
  )
  external;
}


interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// From https://github.com/Uniswap/permit2

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer is IEIP712 {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

using SafeERC20 for IERC20;

error AddressNotAllowed(address account);
error OrderExpired(uint256 orderExpiry, uint256 currentTimestamp);
error CurrentAmountMismatch(address tokenAddress, uint256 orderAmount, uint256 filledAmount, uint256 currentAmount);
error SlippageLimitExceeded(address tokenAddress, uint256 expectedAmount, uint256 actualAmount);
error ArbitrageNotAllowed(address tokenAddress);
error TransferFailed(address destination, uint256 amount);
error OrderCancelled(bytes32 orderHash);
error InvalidArguments();
error MinSurplusCheckFailed(address tokenAddress, uint256 expectedValue, uint256 actualValue);
error InvalidAddress(address _address);
error FunctionIsDisabled();


/// @title Routing contract for Odos Limit Orders with single and multi input and output tokens
contract OdosLimitOrderRouter is EIP712, Ownable2Step, SignatureValidator {

  /// @dev SCALE is required for fractional proportion calculation
  uint256 private constant SCALE = 1e18;

  /// @dev The zero address is used to represent ETH due to its gas efficiency
  address private constant _ETH = address(0);

  /// @dev Constants for managing referrals and fees
  uint256 private constant REFERRAL_WITH_FEE_THRESHOLD = 1 << 31;
  uint256 private constant FEE_DENOM = 1e18;

  /// @dev OdosRouterV2 address
  address immutable private ODOS_ROUTER_V2;

  /// @dev Address which allowed to call `swapRouterFunds()` besides the owner
  address private liquidatorAddress;

  /// @dev Event emitted on successful single input limit order execution
  event LimitOrderFilled(
    bytes32 indexed orderHash,
    address indexed orderOwner,
    address inputToken,
    address outputToken,
    uint256 orderInputAmount,
    uint256 orderOutputAmount,
    uint256 filledInputAmount,   // filled by this execution
    uint256 filledOutputAmount,  // filled by this execution
    uint256 surplus,
    uint32 referralCode
  );

  /// @dev Event emitted on successful multi input limit order execution
  event MultiLimitOrderFilled(
    bytes32 indexed orderHash,
    address indexed orderOwner,
    address[] inputTokens,
    address[] outputTokens,
    uint256[] orderInputAmounts,
    uint256[] orderOutputAmounts,
    uint256[] filledInputAmounts,   // filled by this execution
    uint256[] filledOutputAmounts,  // filled by this execution
    uint256[] surplus,
    uint32 referralCode
  );

  /// @dev Event emitted on single input limit order cancellation
  event LimitOrderCancelled(
    bytes32 indexed orderHash,
    address indexed orderOwner
  );

  /// @dev Event emitted on multi input limit order cancellation
  event MultiLimitOrderCancelled(
    bytes32 indexed orderHash,
    address indexed orderOwner
  );

  /// @dev Event emitted on adding allowed order filler
  event AllowedFillerAdded(address indexed account);

  /// @dev Event emitted on removing allowed order filler
  event AllowedFillerRemoved(address indexed account);

  /// @dev Event emitted on changing the liquidator address
  event LiquidatorAddressChanged(address indexed account);

  /// @dev Event emitted on swapping internal router funds
  event SwapRouterFunds(
    address sender,
    address[] inputTokens,
    uint256[] inputAmounts,
    address[] inputReceivers,
    address outputToken,
    uint256 outputAmount,
    address outputReceiver,
    uint256 amountOut
  );

  /// @dev Token address and amount
  struct TokenInfo {
    address tokenAddress;
    uint256 tokenAmount;
  }

  /// @dev Single input and output limit order structure
  struct LimitOrder {
    TokenInfo input;
    TokenInfo output;
    uint256 expiry;
    uint256 salt;
    uint32 referralCode;
    bool partiallyFillable;
  }

  /// @dev Multiple inputs and outputs limit order structure
  struct MultiLimitOrder {
    TokenInfo[] inputs;
    TokenInfo[] outputs;
    uint256 expiry;
    uint256 salt;
    uint32 referralCode;
    bool partiallyFillable;
  }

  /// @dev The execution context provided by the filler for single token limit order
  struct LimitOrderContext {
    bytes pathDefinition;
    address odosExecutor;
    uint256 currentAmount;
    address inputReceiver;
    uint256 minSurplus;
  }

  /// @dev The execution context provided by the filler for multi token limit order
  struct MultiLimitOrderContext {
    bytes pathDefinition;
    address odosExecutor;
    uint256[] currentAmounts;
    address[] inputReceivers;
    uint256[] minSurplus;
  }

  /// @dev A helper which is used for avoiding "Stack too deep" error with single input order
  struct LimitOrderHelper {
    uint256 balanceBefore;
    uint256 amountOut;
    uint256 surplus;
    uint256 proratedAmount;
  }

  /// @dev A helper which is used for avoiding "Stack too deep" error with multi input order
  struct MultiLimitOrderHelper {
    address[] inputTokens;
    address[] outputTokens;
    uint256[] orderInputAmounts;
    uint256[] orderOutputAmounts;
    uint256[] filledAmounts;
    uint256[] filledOutputAmounts;
    uint256[] surplus;
    uint256[] balancesBefore;
    address orderOwner;
    bytes32 orderHash;
  }

  /// @dev Contains information required for Permit2 token transfer
  struct Permit2Info {
    address contractAddress;  // Permit2 contract address
    uint256 nonce;
    uint256 deadline;
    address orderOwner;
    bytes signature;
  }

  /// @dev Holds all information for a given referral
  struct ReferralInfo {
    uint64 referralFee;
    address beneficiary;
    bool registered;
  }

  /// @dev Single token limit order storage
  mapping(address orderOwner => mapping(bytes32 orderHash => uint256 filledAmount)) public limitOrders;

  /// @dev Multi token limit order storage
  mapping(address orderOwner => mapping(bytes32 orderHash => uint256[] filledAmounts)) public multiLimitOrders;

  /// @dev Allowed order fillers
  mapping(address => bool) public allowedFillers;

  /// @dev Type strings for EIP-712 signing
  bytes internal constant TOKEN_PERMISSIONS_TYPE_STRING = "TokenPermissions(address token,uint256 amount)";

  bytes internal constant TOKEN_INFO_TYPE_STRING = "TokenInfo(address tokenAddress,uint256 tokenAmount)";

  bytes internal constant LIMIT_ORDER_TYPE_STRING = 
    "LimitOrder("
      "TokenInfo input,"
      "TokenInfo output,"
      "uint256 expiry,"
      "uint256 salt,"
      "uint32 referralCode,"
      "bool partiallyFillable"
    ")";

  bytes internal constant MULTI_LIMIT_ORDER_TYPE_STRING =
    "MultiLimitOrder("
      "TokenInfo[] inputs,"
      "TokenInfo[] outputs,"
      "uint256 expiry,"
      "uint256 salt,"
      "uint32 referralCode,"
      "bool partiallyFillable"
    ")";

  string public constant LIMIT_ORDER_WITNESS_TYPE_STRING = string(abi.encodePacked(
    "LimitOrder witness)",
    LIMIT_ORDER_TYPE_STRING,
    TOKEN_INFO_TYPE_STRING,
    TOKEN_PERMISSIONS_TYPE_STRING
  ));

  string public constant MULTI_LIMIT_ORDER_WITNESS_TYPE_STRING = string(abi.encodePacked(
    "MultiLimitOrder witness)",
    MULTI_LIMIT_ORDER_TYPE_STRING,
    TOKEN_INFO_TYPE_STRING,
    TOKEN_PERMISSIONS_TYPE_STRING
  ));

  /// @dev Type hashes for EIP-712 signing
  bytes32 public constant TOKEN_INFO_TYPEHASH = keccak256(TOKEN_INFO_TYPE_STRING);

  bytes32 public constant LIMIT_ORDER_TYPEHASH = keccak256(abi.encodePacked(
    LIMIT_ORDER_TYPE_STRING, 
    TOKEN_INFO_TYPE_STRING
  ));

  bytes32 public constant MULTI_LIMIT_ORDER_TYPEHASH = keccak256(abi.encodePacked(
    MULTI_LIMIT_ORDER_TYPE_STRING, 
    TOKEN_INFO_TYPE_STRING
  ));

  /// @param _odosRouterV2 OdosRouterV2 address
  constructor(address _odosRouterV2)
  EIP712("OdosLimitOrderRouter", "1")
  {
    if (_odosRouterV2 == address(0)) {
      revert InvalidAddress(_odosRouterV2);
    }
    ODOS_ROUTER_V2 = _odosRouterV2;
    changeLiquidatorAddress(msg.sender);
  }


  /// @notice Tries to execute a single input limit order, expects the input token to be approved via the ERC20 interface
  /// @param order Single input limit order struct
  /// @param signature Order signature and signature validation method
  /// @param context Execution context
  /// @return orderHash Order hash
  function fillLimitOrder(
    LimitOrder calldata order,
    Signature calldata signature,
    LimitOrderContext calldata context
  )
  external
  returns (bytes32 orderHash)
  {
    // 1-3 Checks
    _limitOrderChecks(order);

    // 4. Get order hash
    orderHash = getLimitOrderHash(order);

    // 5. Recover the orderOwner and validate signature
    address orderOwner = _getOrderOwnerOrRevert(orderHash, signature.signature, signature.validationMethod);

    // 6,7 Try get order filled amount
    uint256 filledAmount = _getFilledAmount(order, context, orderHash, orderOwner);

    // 8. Transfer tokens from order owner
    IERC20(order.input.tokenAddress).safeTransferFrom(orderOwner, context.inputReceiver, context.currentAmount);

    // 9-17 Fill order
    _limitOrderFill(order, context, orderHash, orderOwner, filledAmount);
  }

  /// @notice Tries to execute a single input limit order, expects the input token to be approved via the Permit2 interface
  /// @param order Single input limit order struct
  /// @param context Execution context
  /// @param permit2 Permit2 struct
  /// @return orderHash Order hash
  function fillLimitOrderPermit2(
    LimitOrder calldata order,
    LimitOrderContext calldata context,
    Permit2Info calldata permit2
  )
  external
  returns (bytes32 orderHash)
  {
    // 1-3 Checks
    _limitOrderChecks(order);

    // 4. Get order hash
    bytes32 orderStructHash = getLimitOrderStructHash(order);
    orderHash = _hashTypedDataV4(orderStructHash);

    // 5. No need to recover address as it is set in Permit2Info

    // 6,7 Try get order filled amount
    uint256 filledAmount = _getFilledAmount(order, context, orderHash, permit2.orderOwner);

    // 8. Transfer tokens from order owner
    ISignatureTransfer(permit2.contractAddress).permitWitnessTransferFrom(
      ISignatureTransfer.PermitTransferFrom(
        ISignatureTransfer.TokenPermissions(
          order.input.tokenAddress,
          context.currentAmount
        ),
        permit2.nonce,
        permit2.deadline
      ),
      ISignatureTransfer.SignatureTransferDetails(
        context.inputReceiver,
        context.currentAmount
      ),
      permit2.orderOwner,
      orderStructHash,
      LIMIT_ORDER_WITNESS_TYPE_STRING,
      permit2.signature
    );

    // 9-17 Fill order
    _limitOrderFill(order, context, orderHash, permit2.orderOwner, filledAmount);
  }

  /// @notice Tries to execute a multi input limit order, expects the input tokens to be approved via the ERC20 interface
  /// @param order Multi input limit order struct
  /// @param signature Signature and signature validation method
  /// @param context Execution context
  /// @return orderHash Order hash
  function fillMultiLimitOrder(
    MultiLimitOrder calldata order,
    Signature calldata signature,
    MultiLimitOrderContext calldata context
  )
  external
  returns (bytes32 orderHash)
  {
    // 1-3 Checks
    _multiOrderChecks(order);

    // 4. Get order hash
    orderHash = getMultiLimitOrderHash(order);

    // 5. Recover the orderOwner and validate signature
    address orderOwner = _getOrderOwnerOrRevert(orderHash, signature.signature, signature.validationMethod);

    // 6,7 Try get order filled amount
    MultiLimitOrderHelper memory helper = _getMultiFilledAmount(order, context, orderHash, orderOwner);

    // 8. Transfer tokens from order owner to the receiver
    for (uint256 i = 0; i < order.inputs.length; i++) {
      IERC20(order.inputs[i].tokenAddress).safeTransferFrom(orderOwner, context.inputReceivers[i], context.currentAmounts[i]);
      // update filled amount
      helper.filledAmounts[i] += context.currentAmounts[i];
      helper.inputTokens[i] = order.inputs[i].tokenAddress;
      helper.orderInputAmounts[i] = order.inputs[i].tokenAmount;
    }

    _multiLimitOrderFill(order, context, helper);
  }

  /// @notice Tries to execute a multi input limit order, expects the input tokens to be approved via the Permit2 interface
  /// @param order Single input limit order struct
  /// @param context Execution context
  /// @param permit2 Permit2 struct
  /// @return orderHash Order hash
  function fillMultiLimitOrderPermit2(
    MultiLimitOrder calldata order,
    MultiLimitOrderContext calldata context,
    Permit2Info calldata permit2
  )
  external
  returns (bytes32 orderHash)
  {
    // 1-3 Checks
    _multiOrderChecks(order);

    // 4. Get order hash
    bytes32 orderStructHash = getMultiLimitOrderStructHash(order);
    orderHash = _hashTypedDataV4(orderStructHash);

    // 5. No need to recover address as it is set in Permit2Info

    // 6,7 Try get order filled amount
    MultiLimitOrderHelper memory helper = _getMultiFilledAmount(order, context, orderHash, permit2.orderOwner);

    // 8. Transfer tokens from order owner to the receiver
    ISignatureTransfer.PermitBatchTransferFrom memory permit = ISignatureTransfer.PermitBatchTransferFrom(
      new ISignatureTransfer.TokenPermissions[](order.inputs.length),
      permit2.nonce,
      permit2.deadline
    );
    ISignatureTransfer.SignatureTransferDetails[] memory transferDetails
      = new ISignatureTransfer.SignatureTransferDetails[](order.inputs.length);

    for (uint256 i = 0; i < order.inputs.length; i++) {
      permit.permitted[i].token = order.inputs[i].tokenAddress;
      permit.permitted[i].amount = context.currentAmounts[i];

      // Fill helper data
      helper.filledAmounts[i] += context.currentAmounts[i];
      helper.inputTokens[i] = order.inputs[i].tokenAddress;
      helper.orderInputAmounts[i] = context.currentAmounts[i];

      transferDetails[i].to = context.inputReceivers[i];
      transferDetails[i].requestedAmount = context.currentAmounts[i];

    }
    ISignatureTransfer(permit2.contractAddress).permitWitnessTransferFrom(
      permit,
      transferDetails,
      permit2.orderOwner,
      orderStructHash,
      MULTI_LIMIT_ORDER_WITNESS_TYPE_STRING,
      permit2.signature
    );

    // 9-15 Fill order
    _multiLimitOrderFill(order, context, helper);
  }

  /// @notice Cancels single input limit order. Only the order owner address can cancel it.
  /// @param orderHash Single input limit order hash
  function cancelLimitOrder(
    bytes32 orderHash
  )
  external
  {
    limitOrders[msg.sender][orderHash] = type(uint256).max;
    emit LimitOrderCancelled(orderHash, msg.sender);
  }

  /// @notice Cancels multi input limit order. Only the order owner address can cancel it.
  /// @param orderHash Multi input limit order hash
  function cancelMultiLimitOrder(
    bytes32 orderHash
  )
  external
  {
    uint256[] memory _filledAmounts = new uint256[](1);
    _filledAmounts[0] = type(uint256).max;
    multiLimitOrders[msg.sender][orderHash] = _filledAmounts;

    emit MultiLimitOrderCancelled(orderHash, msg.sender);
  }

  /// @notice Directly swap funds held in router, multi input tokens to one output token. Only owner or liquidatorAddress can call it.
  /// @param inputs List of input token structs
  /// @param inputReceivers List of addresses for swap execution
  /// @param output Output token structs
  /// @param outputReceiver Address which will receive output token
  /// @param pathDefinition Encoded path definition for executor
  /// @param odosExecutor Address of contract which will execute the path
  /// @return amountOut Amount of output token after swap
  function swapRouterFunds(
    TokenInfo[] memory inputs,
    address[] memory inputReceivers,
    TokenInfo memory output,
    address outputReceiver,
    bytes calldata pathDefinition,
    address odosExecutor
  )
  external
  returns (uint256 amountOut)
  {
    if (msg.sender != liquidatorAddress && msg.sender != owner()) {
      revert AddressNotAllowed(msg.sender);
    }
    uint256[] memory amountsIn = new uint256[](inputs.length);
    address[] memory tokensIn = new address[](inputs.length);

    for (uint256 i = 0; i < inputs.length; i++) {
      tokensIn[i] = inputs[i].tokenAddress;

      // Allow total amount spending
      amountsIn[i] = inputs[i].tokenAmount == 0 ?
        IERC20(tokensIn[i]).balanceOf(address(this)) : inputs[i].tokenAmount;

      // Transfer funds to the receivers
      IERC20(tokensIn[i]).safeTransfer(inputReceivers[i], amountsIn[i]);
    }
    // Get output token balances before
    uint256 balanceBefore = IERC20(output.tokenAddress).balanceOf(address(this));

    // Delegate the execution of the path to the specified Odos Executor
    IOdosExecutor(odosExecutor).executePath(pathDefinition, amountsIn, msg.sender);

    // Get output token balances difference
    amountOut = IERC20(output.tokenAddress).balanceOf(address(this)) - balanceBefore;

    if (amountOut < output.tokenAmount) {
      revert SlippageLimitExceeded(output.tokenAddress, output.tokenAmount, amountOut);
    }

    // Transfer tokens to the receiver
    IERC20(output.tokenAddress).safeTransfer(outputReceiver, amountOut);

    emit SwapRouterFunds(
      msg.sender,
      tokensIn,
      amountsIn,
      inputReceivers,
      output.tokenAddress,
      output.tokenAmount,
      outputReceiver,
      amountOut
    );
  }

  /// @notice Transfers funds held by the router contract
  /// @param tokens List of token address to be transferred
  /// @param amounts List of amounts of each token to be transferred
  /// @param dest Address to which the funds should be sent
  function transferRouterFunds(
    address[] calldata tokens,
    uint256[] calldata amounts,
    address dest
  )
  external
  onlyOwner
  {
    if (dest == address(0)) {
      revert InvalidAddress(dest);
    }
    if (tokens.length != amounts.length) revert InvalidArguments();
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] == _ETH) {
        (bool success,) = payable(dest).call{value: amounts[i]}("");
        if (!success) {
          revert TransferFailed(dest, amounts[i]);
        }
      } else {
        IERC20(tokens[i]).safeTransfer(
          dest,
          amounts[i] == 0 ? IERC20(tokens[i]).balanceOf(address(this)) : amounts[i]
        );
      }
    }
  }

  /// @notice Adds an address to the list of allowed filler addresses
  /// @param account The address to be allowed
  function addAllowedFiller(address account) external onlyOwner {
    allowedFillers[account] = true;
    emit AllowedFillerAdded(account);
  }

  /// @notice Removes an address from the list of allowed filler addresses
  /// @param account The address to be disabled
  function removeAllowedFiller(address account) external onlyOwner {
    allowedFillers[account] = false;
    emit AllowedFillerRemoved(account);
  }

  /// @notice Disable the Ownable.renounceOwnership() function to prevent ownerless state
  function renounceOwnership() public onlyOwner view override {
    revert FunctionIsDisabled();
  }

  /// @notice Changes the address which can call `swapRouterFunds()` function
  /// @param account The address of new liquidator
  function changeLiquidatorAddress(address account)
  public
  onlyOwner
  {
    liquidatorAddress = account;
    emit LiquidatorAddressChanged(account);
  }

  /// @dev Encodes TokenInfo struct according to EIP-712
  /// @param tokenInfo TokenInfo struct
  /// @return Encoded struct
  function encodeTokenInfo(
    TokenInfo calldata tokenInfo
  )
  public
  pure
  returns (bytes memory)
  {
    return abi.encode(TOKEN_INFO_TYPEHASH, tokenInfo.tokenAddress, tokenInfo.tokenAmount);
  }

  /// @notice gets LimitOrder struct hash according to EIP-712
  /// @param order LimitOrder struct
  /// @return structHash EIP-712 struct hash
  function getLimitOrderStructHash(
    LimitOrder calldata order
  )
  public
  pure
  returns (bytes32 structHash)
  {
    return keccak256(
        abi.encode(
        LIMIT_ORDER_TYPEHASH,
        keccak256(encodeTokenInfo(order.input)),
        keccak256(encodeTokenInfo(order.output)),
        order.expiry,
        order.salt,
        order.referralCode,
        order.partiallyFillable
      )
    );
  }

  /// @notice gets MultiLimitOrder struct hash according to EIP-712
  /// @param order MultiLimitOrder struct
  /// @return structHash EIP-712 struct hash
  function getMultiLimitOrderStructHash(
    MultiLimitOrder calldata order
  )
  public
  pure
  returns (bytes32 structHash)
  {
    bytes32[] memory encodedInputs = new bytes32[](order.inputs.length);
    for (uint256 i = 0; i < order.inputs.length; i++) {
      encodedInputs[i] = keccak256(encodeTokenInfo(order.inputs[i]));
    }
    bytes32[] memory encodedOutputs = new bytes32[](order.outputs.length);
    for (uint256 i = 0; i < order.outputs.length; i++) {
      encodedOutputs[i] = keccak256(encodeTokenInfo(order.outputs[i]));
    }

    return keccak256(
        abi.encode(
        MULTI_LIMIT_ORDER_TYPEHASH,
        keccak256(abi.encodePacked(encodedInputs)),
        keccak256(abi.encodePacked(encodedOutputs)),
        order.expiry,
        order.salt,
        order.referralCode,
        order.partiallyFillable
      )
    );
  }

  /// @notice Returns single input limit order hash
  /// @param order Single input limit order
  /// @return hash Order hash
  function getLimitOrderHash(LimitOrder calldata order)
  public
  view
  returns (bytes32 hash)
  {
    return _hashTypedDataV4(getLimitOrderStructHash(order));
  }

  /// @notice Returns multi input limit order hash
  /// @param order Multi input limit order
  /// @return hash Order hash
  function getMultiLimitOrderHash(
    MultiLimitOrder calldata order
  )
  public
  view
  returns (bytes32 hash)
  {
    return _hashTypedDataV4(getMultiLimitOrderStructHash(order));
  }

  /// @dev Checks order parameters and current order state before execution
  /// @param order Single input limit order struct
  function _limitOrderChecks(
    LimitOrder calldata order
  )
  internal
  view
  {
    // 1. Check msg.sender allowed
    if (!allowedFillers[msg.sender]) {
      revert AddressNotAllowed(msg.sender);
    }

    // 2. Check if order still valid
    if (order.expiry < block.timestamp) {
      revert OrderExpired(order.expiry, block.timestamp);
    }

    // 3. Check tokens, amounts
    if (order.input.tokenAddress == order.output.tokenAddress) {
      revert ArbitrageNotAllowed(order.input.tokenAddress);
    }
  }

  /// @dev Limit order checks
  /// @param order Single input limit order struct
  /// @param context Order execution context
  /// @param orderHash Limit order struct hash
  /// @param orderOwner Order owner address
  /// @return filledAmount Order amount filled by now
  function _getFilledAmount(
    LimitOrder calldata order,
    LimitOrderContext calldata context,
    bytes32 orderHash,
    address orderOwner
  )
  internal
  view
  returns (
    uint256 filledAmount
  )
  {
    // 6. Extract previously filled amounts for order from storage, or create
    filledAmount = limitOrders[orderOwner][orderHash];

    if (filledAmount == type(uint256).max) {
      revert OrderCancelled(orderHash);
    }

    // 7. Check if fill possible:
    //   - If partiallyFillable, total amount do not exceed
    //   - If not partiallyFillable - it was not filled previously
    if (order.partiallyFillable) {
      // Check that the currentAmount fits the total order amount
      if (filledAmount + context.currentAmount > order.input.tokenAmount) {
        revert CurrentAmountMismatch(order.input.tokenAddress, order.input.tokenAmount, filledAmount, context.currentAmount);
      }
    } else {
      // Revert if order was filled or currentAmount is not equal to the order amount
      if (filledAmount > 0 || context.currentAmount != order.input.tokenAmount) {
        revert CurrentAmountMismatch(order.input.tokenAddress, order.input.tokenAmount, filledAmount, context.currentAmount);
      }
    }
  }

  /// @dev Fills single input limit order
  /// @param order Single input limit order struct
  /// @param context Order execution context
  /// @param orderHash Order hash
  /// @param orderOwner Order owner address
  /// @param filledAmount Amount filled by now
  function _limitOrderFill(
    LimitOrder calldata order,
    LimitOrderContext calldata context,
    bytes32 orderHash,
    address orderOwner,
    uint256 filledAmount
  )
  internal
  {
    // 9. Update order filled amounts in storage
    filledAmount += context.currentAmount;
    limitOrders[orderOwner][orderHash] = filledAmount;

    LimitOrderHelper memory helper;

    // 10. Get output token balances before
    helper.balanceBefore = IERC20(order.output.tokenAddress).balanceOf(address(this));

    // 11. Call Odos Executor
    {
      uint256[] memory amountsIn = new uint256[](1);
      amountsIn[0] = context.currentAmount;
      IOdosExecutor(context.odosExecutor).executePath(context.pathDefinition, amountsIn, msg.sender);
    }

    // 12. Get output token balances difference
    helper.amountOut = IERC20(order.output.tokenAddress).balanceOf(address(this)) - helper.balanceBefore;

    // calculate prorated output amount in case of partial fill, otherwise it will be equal to order.output.tokenAmount
    helper.proratedAmount = SCALE * order.output.tokenAmount * context.currentAmount / order.input.tokenAmount / SCALE;

    // 13. Calculate and transfer referral fee if any
    if (order.referralCode > REFERRAL_WITH_FEE_THRESHOLD) {
      IOdosRouterV2.referralInfo memory ri = IOdosRouterV2(ODOS_ROUTER_V2).referralLookup(order.referralCode);
      uint256 beneficiaryAmount = helper.amountOut * ri.referralFee * 8 / (FEE_DENOM * 10);
      helper.amountOut = helper.amountOut * (FEE_DENOM - ri.referralFee) / FEE_DENOM;
      IERC20(order.output.tokenAddress).safeTransfer(ri.beneficiary, beneficiaryAmount);
    }

    // 14. Check slippage, adjust amountOut
    if (helper.amountOut < helper.proratedAmount) {
      revert SlippageLimitExceeded(order.output.tokenAddress, helper.proratedAmount, helper.amountOut);
    }

    // 15. Check surplus
    helper.surplus = helper.amountOut - helper.proratedAmount;
    if (helper.surplus < context.minSurplus) {
      revert MinSurplusCheckFailed(order.output.tokenAddress, context.minSurplus, helper.surplus);
    }

    // 16. Transfer tokens to the order owner
    IERC20(order.output.tokenAddress).safeTransfer(orderOwner, helper.proratedAmount);

    // 17. Emit LimitOrderFilled event
    emit LimitOrderFilled(
      orderHash,
      orderOwner,
      order.input.tokenAddress,
      order.output.tokenAddress,
      order.input.tokenAmount,
      order.output.tokenAmount,
      context.currentAmount,
      helper.proratedAmount,
      helper.surplus,
      order.referralCode
    );
  }

  /// @dev Checks order parameters and current order state before execution
  /// @param order Multi input limit order struct
  function _multiOrderChecks(
    MultiLimitOrder calldata order
  )
  internal
  view
  {
    // 1. Check msg.sender allowed
    if (!allowedFillers[msg.sender]) {
      revert AddressNotAllowed(msg.sender);
    }

    // 2. Check if order still valid
    if (order.expiry < block.timestamp) {
      revert OrderExpired(order.expiry, block.timestamp);
    }

    // 3. Check tokens, amounts
    for (uint256 i = 0; i < order.inputs.length; i++) {
      for (uint256 j = 0; j < order.outputs.length; j++) {
        if (order.inputs[i].tokenAddress == order.outputs[j].tokenAddress) {
          revert ArbitrageNotAllowed(order.inputs[i].tokenAddress);
        }
      }
    }
  }

  /// @dev Checks order parameters and current order state before execution
  /// @param order Multi input limit order struct
  /// @param context Order execution context
  /// @param orderHash Order struct hash
  /// @return helper Helper struct which contains order information
  function _getMultiFilledAmount(
    MultiLimitOrder calldata order,
    MultiLimitOrderContext calldata context,
    bytes32 orderHash,
    address orderOwner
  )
  internal
  view
  returns (
    MultiLimitOrderHelper memory helper
  )
  {
    helper = MultiLimitOrderHelper({
      inputTokens: new address[](order.inputs.length),
      outputTokens: new address[](order.outputs.length),
      orderInputAmounts: new uint256[](order.inputs.length),
      orderOutputAmounts: new uint256[](order.outputs.length),
      filledAmounts: new uint256[](order.inputs.length),
      filledOutputAmounts: new uint256[](order.outputs.length),
      surplus: new uint256[](order.outputs.length),
      balancesBefore: new uint256[](order.outputs.length),
      orderOwner : orderOwner,
      orderHash : orderHash
    });

    // 6. Extract previously filled amounts for order from storage, or create
    helper.filledAmounts = multiLimitOrders[orderOwner][orderHash];

    if (helper.filledAmounts.length > 0 && helper.filledAmounts[0] == type(uint256).max) {
      revert OrderCancelled(orderHash);
    }

    if (helper.filledAmounts.length == 0) {
      helper.filledAmounts = new uint256[](order.inputs.length);
    }

    // 7. Check if fill possible:
    //   - If partiallyFillable, total amount do not exceed
    //   - If not partiallyFillable - it was not filled previously
    if (order.partiallyFillable) {
      // Check that the currentAmount fits the total order amount
      for (uint256 i = 0; i < helper.filledAmounts.length; i++) {
        if (helper.filledAmounts[i] + context.currentAmounts[i] > order.inputs[i].tokenAmount) {
          revert CurrentAmountMismatch(order.inputs[i].tokenAddress, order.inputs[i].tokenAmount,
            helper.filledAmounts[i], context.currentAmounts[i]);
        }
      }
    } else {
      // Revert if order was filled or currentAmount is not equal to the order amount
      for (uint256 i = 0; i < helper.filledAmounts.length; i++) {
        if (helper.filledAmounts[i] > 0 || context.currentAmounts[i] != order.inputs[i].tokenAmount) {
          revert CurrentAmountMismatch(order.inputs[i].tokenAddress, order.inputs[i].tokenAmount,
            helper.filledAmounts[i], context.currentAmounts[i]);
        }
      }
    }
  }

  /// @dev Fills multi input limit order
  /// @param order Multi input limit order struct
  /// @param context Order execution context
  /// @param helper Helper struct which contains order information
  function _multiLimitOrderFill(
    MultiLimitOrder calldata order,
    MultiLimitOrderContext calldata context,
    MultiLimitOrderHelper memory helper
  )
  internal
  {
    // 9. Update order filled amounts in storage
    multiLimitOrders[helper.orderOwner][helper.orderHash] = helper.filledAmounts;

    // 10. Get output token balances before
    for (uint256 i = 0; i < order.outputs.length; i++) {
      helper.outputTokens[i] = order.outputs[i].tokenAddress;
      helper.orderOutputAmounts[i] = order.outputs[i].tokenAmount;
      helper.balancesBefore[i] = IERC20(order.outputs[i].tokenAddress).balanceOf(address(this));
    }
    // 11. Call Odos Executor
    IOdosExecutor(context.odosExecutor).executePath(context.pathDefinition, context.currentAmounts, msg.sender);

    {
      // 12. Get output token balances difference
      uint256[] memory amountsOut = new uint256[](order.outputs.length);
      for (uint256 i = 0; i < order.outputs.length; i++) {
        amountsOut[i] = IERC20(order.outputs[i].tokenAddress).balanceOf(address(this)) - helper.balancesBefore[i];
      }


      IOdosRouterV2.referralInfo memory ri;
      if (order.referralCode > REFERRAL_WITH_FEE_THRESHOLD) {
        ri = IOdosRouterV2(ODOS_ROUTER_V2).referralLookup(order.referralCode);
      }

      for (uint256 i = 0; i < order.outputs.length; i++) {
        // 13. Calculate and transfer referral fee if any
        if (order.referralCode > REFERRAL_WITH_FEE_THRESHOLD) {
          uint256 beneficiaryAmount = amountsOut[i] * ri.referralFee * 8 / (FEE_DENOM * 10);
          amountsOut[i] = amountsOut[i] * (FEE_DENOM - ri.referralFee) / FEE_DENOM;
          IERC20(order.outputs[i].tokenAddress).safeTransfer(ri.beneficiary, beneficiaryAmount);
        }

        // calculate prorated output amount in case of partial fill, otherwise it will be equal to order.output.tokenAmount
        uint256 proratedAmount = SCALE * order.outputs[i].tokenAmount * context.currentAmounts[i] / order.inputs[i].tokenAmount / SCALE;

        // 14. Check slippage, adjust amountOut
        if (amountsOut[i] < proratedAmount) {
          revert SlippageLimitExceeded(order.outputs[i].tokenAddress, proratedAmount, amountsOut[i]);
        }
        helper.filledOutputAmounts[i] = proratedAmount;

        // 15. Check surplus
        helper.surplus[i] = amountsOut[i] - proratedAmount;
        if (helper.surplus[i] < context.minSurplus[i]) {
          revert MinSurplusCheckFailed(order.outputs[i].tokenAddress, context.minSurplus[i], helper.surplus[i]);
        }

        // 16. Transfer tokens to the order owner
        IERC20(order.outputs[i].tokenAddress).safeTransfer(helper.orderOwner, proratedAmount);
      }
    }

    // 17. Emit LimitOrderFilled event
    emit MultiLimitOrderFilled(
      helper.orderHash,
      helper.orderOwner,
      helper.inputTokens,
      helper.outputTokens,
      helper.orderInputAmounts,
      helper.orderOutputAmounts,
      context.currentAmounts,
      helper.filledOutputAmounts,
      helper.surplus,
      order.referralCode
    );
  }
}