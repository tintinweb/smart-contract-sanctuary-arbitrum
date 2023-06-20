// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IGrid.sol";
import "./interfaces/IWETHMinimum.sol";
import "./interfaces/callback/IGridSwapCallback.sol";
import "./interfaces/callback/IGridPlaceMakerOrderCallback.sol";
import "./interfaces/callback/IGridFlashCallback.sol";
import "./interfaces/IGridEvents.sol";
import "./interfaces/IGridStructs.sol";
import "./interfaces/IGridParameters.sol";
import "./interfaces/IGridDeployer.sol";
import "./interfaces/IPriceOracle.sol";
import "./libraries/BoundaryMath.sol";
import "./libraries/BoundaryBitmap.sol";
import "./libraries/BundleMath.sol";
import "./libraries/Uint128Math.sol";
import "./libraries/Uint160Math.sol";
import "./libraries/SwapMath.sol";

/// @title The implementation of a Gridex grid
contract Grid is IGrid, IGridStructs, IGridEvents, IGridParameters, Context {
    using SafeCast for uint256;
    using BoundaryBitmap for mapping(int16 => uint256);
    using BundleMath for Bundle;

    address public immutable override token0;
    address public immutable override token1;
    int24 public immutable override resolution;

    address private immutable weth9;
    address private immutable priceOracle;

    int24 public immutable takerFee;

    Slot0 public override slot0;

    mapping(int24 => Boundary) public override boundaries0;
    mapping(int24 => Boundary) public override boundaries1;
    mapping(int16 => uint256) public override boundaryBitmaps0;
    mapping(int16 => uint256) public override boundaryBitmaps1;

    uint256 private _orderId;
    mapping(uint256 => Order) public override orders;

    uint64 private _bundleId;
    mapping(uint64 => Bundle) public override bundles;

    mapping(address => TokensOwed) public override tokensOweds;

    /// @dev Used to receive Ether when settling and collecting orders
    receive() external payable {}

    constructor() {
        (token0, token1, resolution, takerFee, priceOracle, weth9) = IGridDeployer(_msgSender()).parameters();
    }

    modifier lock() {
        // G_PL: Grid locked
        require(slot0.unlocked, "G_GL");
        slot0.unlocked = false;
        _;
        slot0.unlocked = true;
    }

    /// @inheritdoc IGrid
    function initialize(
        InitializeParameters memory parameters,
        bytes calldata data
    ) external override returns (uint256[] memory orderIds0, uint256[] memory orderIds1) {
        // G_GAI: grid already initialized
        require(slot0.priceX96 == 0, "G_GAI");
        // G_POR: price out of range
        require(BoundaryMath.isPriceX96InRange(parameters.priceX96), "G_POR");
        // G_T0OE: token0 orders must be non-empty
        require(parameters.orders0.length > 0, "G_ONE");
        // G_T1OE: token1 orders must be non-empty
        require(parameters.orders1.length > 0, "G_ONE");

        IPriceOracle(priceOracle).register(token0, token1, resolution);

        int24 boundary = BoundaryMath.getBoundaryAtPriceX96(parameters.priceX96);
        slot0 = Slot0({
            priceX96: parameters.priceX96,
            boundary: boundary,
            blockTimestamp: uint32(block.timestamp),
            unlocked: false // still keep the grid locked to prevent reentrancy
        });
        // emits an Initialize event before placing orders
        emit Initialize(parameters.priceX96, boundary);

        // places orders for token0 and token1
        uint256 amount0Total;
        (orderIds0, amount0Total) = _placeMakerOrderInBatch(parameters.recipient, true, parameters.orders0);
        uint256 amount1Total;
        (orderIds1, amount1Total) = _placeMakerOrderInBatch(parameters.recipient, false, parameters.orders1);
        (uint256 balance0Before, uint256 balance1Before) = (_balance0(), _balance1());

        IGridPlaceMakerOrderCallback(_msgSender()).gridexPlaceMakerOrderCallback(amount0Total, amount1Total, data);

        (uint256 balance0After, uint256 balance1After) = (_balance0(), _balance1());
        // G_TPF: token pay failed
        require(
            balance0After - balance0Before >= amount0Total && balance1After - balance1Before >= amount1Total,
            "G_TPF"
        );

        slot0.unlocked = true;
    }

    /// @inheritdoc IGrid
    function placeMakerOrder(
        PlaceOrderParameters memory parameters,
        bytes calldata data
    ) external override lock returns (uint256 orderId) {
        orderId = _nextOrderId();

        _processPlaceOrder(orderId, parameters.recipient, parameters.zero, parameters.boundaryLower, parameters.amount);

        _processPlaceOrderReceiveAndCallback(parameters.zero, parameters.amount, data);
    }

    /// @inheritdoc IGrid
    function placeMakerOrderInBatch(
        PlaceOrderInBatchParameters memory parameters,
        bytes calldata data
    ) external override lock returns (uint256[] memory orderIds) {
        uint256 amountTotal;
        (orderIds, amountTotal) = _placeMakerOrderInBatch(parameters.recipient, parameters.zero, parameters.orders);
        _processPlaceOrderReceiveAndCallback(parameters.zero, amountTotal, data);
    }

    function _placeMakerOrderInBatch(
        address recipient,
        bool zero,
        BoundaryLowerWithAmountParameters[] memory parameters
    ) private returns (uint256[] memory orderIds, uint256 amountTotal) {
        orderIds = new uint256[](parameters.length);
        uint256 orderId = _nextOrderIdInBatch(parameters.length);

        for (uint256 i = 0; i < parameters.length; ) {
            BoundaryLowerWithAmountParameters memory each = parameters[i];

            _processPlaceOrder(orderId, recipient, zero, each.boundaryLower, each.amount);
            orderIds[i] = orderId;

            unchecked {
                // next order id
                orderId++;
                i++;
            }

            amountTotal += each.amount;
        }
    }

    function _processPlaceOrder(
        uint256 orderId,
        address recipient,
        bool zero,
        int24 boundaryLower,
        uint128 amount
    ) private {
        // G_OAZ: order amount is zero
        require(amount > 0, "G_OAZ");
        // G_IBL: invalid boundary lower
        require(
            boundaryLower >= BoundaryMath.MIN_BOUNDARY &&
                boundaryLower + resolution <= BoundaryMath.MAX_BOUNDARY &&
                BoundaryMath.isValidBoundary(boundaryLower, resolution),
            "G_IBL"
        );

        // updates the boundary
        Boundary storage boundary = _boundaryAt(boundaryLower, zero);
        Bundle storage bundle;
        uint64 bundleId = boundary.bundle1Id;
        // 1. If bundle1 has been initialized, add the order to bundle1 directly
        // 2. If bundle0 is not initialized, add the order to bundle0 after initialization
        // 3. If bundle0 has been initialized, and bundle0 has been used,
        //    then bundle1 is initialized and the order is added to bundle1, otherwise, it is added to bundle0
        if (bundleId > 0) {
            bundle = bundles[bundleId];
            bundle.addLiquidity(amount);
        } else {
            uint64 bundle0Id = boundary.bundle0Id;
            if (bundle0Id == 0) {
                // initializes new bundle
                (bundleId, bundle) = _nextBundle(boundaryLower, zero);
                boundary.bundle0Id = bundleId;

                bundle.makerAmountTotal = amount;
                bundle.makerAmountRemaining = amount;
            } else {
                bundleId = bundle0Id;
                bundle = bundles[bundleId];

                uint128 makerAmountTotal = bundle.makerAmountTotal;
                uint128 makerAmountRemaining = bundle.makerAmountRemaining;

                if (makerAmountRemaining < makerAmountTotal) {
                    // initializes new bundle
                    (bundleId, bundle) = _nextBundle(boundaryLower, zero);
                    boundary.bundle1Id = bundleId;

                    bundle.makerAmountTotal = amount;
                    bundle.makerAmountRemaining = amount;
                } else {
                    bundle.addLiquidityWithAmount(makerAmountTotal, makerAmountRemaining, amount);
                }
            }
        }

        // saves order
        orders[orderId] = Order({owner: recipient, bundleId: bundleId, amount: amount});
        emit PlaceMakerOrder(orderId, recipient, bundleId, zero, boundaryLower, amount);

        // If the current boundary has no liquidity, it must be flipped
        uint128 makerAmountRemainingForBoundary = boundary.makerAmountRemaining;

        if (makerAmountRemainingForBoundary == 0) _flipBoundary(boundaryLower, zero);

        boundary.makerAmountRemaining = makerAmountRemainingForBoundary + amount;
    }

    function _processPlaceOrderReceiveAndCallback(bool zero, uint256 amount, bytes calldata data) private {
        // tokens to be received
        (address tokenToReceive, uint256 amount0, uint256 amount1) = zero
            ? (token0, amount, uint256(0))
            : (token1, uint256(0), amount);
        uint256 balanceBefore = IERC20(tokenToReceive).balanceOf(address(this));
        IGridPlaceMakerOrderCallback(_msgSender()).gridexPlaceMakerOrderCallback(amount0, amount1, data);
        uint256 balanceAfter = IERC20(tokenToReceive).balanceOf(address(this));
        // G_TPF: token pay failed
        require(balanceAfter - balanceBefore >= amount, "G_TPF");
    }

    /// @inheritdoc IGrid
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 priceLimitX96,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {
        // G_ASZ: amount specified cannot be zero
        require(amountSpecified != 0, "G_ASZ");

        Slot0 memory slot0Cache = slot0;
        // G_PL: Grid locked
        require(slot0Cache.unlocked, "G_GL");
        // G_PLO: price limit over range
        require(zeroForOne ? priceLimitX96 < slot0Cache.priceX96 : priceLimitX96 > slot0Cache.priceX96, "G_PLO");

        // we lock the grid before swap
        slot0.unlocked = false;

        SwapState memory state = SwapState({
            zeroForOne: zeroForOne,
            amountSpecifiedRemaining: amountSpecified,
            amountInputCalculated: 0,
            feeAmountInputCalculated: 0,
            amountOutputCalculated: 0,
            priceX96: slot0Cache.priceX96,
            priceLimitX96: priceLimitX96,
            boundary: slot0Cache.boundary,
            boundaryLower: BoundaryMath.getBoundaryLowerAtBoundary(slot0Cache.boundary, resolution),
            initializedBoundaryLowerPriceX96: 0,
            initializedBoundaryUpperPriceX96: 0,
            stopSwap: false
        });

        mapping(int16 => uint256) storage counterBoundaryBitmap = _boundaryBitmaps(!zeroForOne);
        mapping(int24 => Boundary) storage counterBoundaries = _boundaries(!zeroForOne);
        while (state.amountSpecifiedRemaining != 0 && !state.stopSwap) {
            int24 boundaryNext;
            bool initialized;
            (
                boundaryNext,
                initialized,
                state.initializedBoundaryLowerPriceX96,
                state.initializedBoundaryUpperPriceX96
            ) = counterBoundaryBitmap.nextInitializedBoundary(
                state.boundary,
                state.priceX96,
                counterBoundaries[state.boundaryLower].makerAmountRemaining > 0,
                resolution,
                state.boundaryLower,
                state.zeroForOne
            );
            if (!initialized) break;

            // swap for boundary
            state.stopSwap = _processSwapForBoundary(counterBoundaryBitmap, counterBoundaries, boundaryNext, state);
        }

        // updates slot0
        if (state.priceX96 != slot0Cache.priceX96) {
            state.boundary = BoundaryMath.getBoundaryAtPriceX96(state.priceX96);
            uint32 blockTimestamp;
            // We only update the oracle in the first transaction of each block, using only the boundary
            // before the update to improve the security of the oracle
            if (
                slot0Cache.boundary != state.boundary &&
                slot0Cache.blockTimestamp != (blockTimestamp = uint32(block.timestamp))
            ) {
                IPriceOracle(priceOracle).update(slot0Cache.boundary, blockTimestamp);
                slot0.blockTimestamp = blockTimestamp;
            }

            (slot0.priceX96, slot0.boundary) = (state.priceX96, state.boundary);
        }

        (amount0, amount1) = _processTransferForSwap(state, recipient, data);
        emit Swap(_msgSender(), recipient, amount0, amount1, state.priceX96, state.boundary);

        // we unlock the grid after swap
        slot0.unlocked = true;
    }

    /// @dev Process swap for a given boundary
    /// @param counterBoundaryBitmap The boundary bitmap of the opposite side. When zeroForOne is true,
    /// it is the boundary bitmap of token1, otherwise it is the boundary bitmap of token0
    /// @param counterBoundaries The boundary of the opposite side. When zeroForOne is true,
    /// it is the boundary of token1, otherwise it is the boundary of token0
    /// @param boundaryNext The next boundary where liquidity exists
    /// @param state The state of the swap
    /// @return stopSwap stopSwap = true if the amount of swapped out is 0,
    /// or when the specified price limit is reached
    function _processSwapForBoundary(
        mapping(int16 => uint256) storage counterBoundaryBitmap,
        mapping(int24 => Boundary) storage counterBoundaries,
        int24 boundaryNext,
        SwapState memory state
    ) private returns (bool stopSwap) {
        SwapForBoundaryState memory swapForBoundaryState = SwapForBoundaryState({
            boundaryLowerPriceX96: state.initializedBoundaryLowerPriceX96,
            boundaryUpperPriceX96: state.initializedBoundaryUpperPriceX96,
            boundaryPriceX96: 0,
            priceX96: 0
        });
        // resets the current priceX96 to the price range
        (swapForBoundaryState.boundaryPriceX96, swapForBoundaryState.priceX96) = state.zeroForOne
            ? (
                swapForBoundaryState.boundaryLowerPriceX96,
                Uint160Math.minUint160(swapForBoundaryState.boundaryUpperPriceX96, state.priceX96)
            )
            : (
                swapForBoundaryState.boundaryUpperPriceX96,
                Uint160Math.maxUint160(swapForBoundaryState.boundaryLowerPriceX96, state.priceX96)
            );

        // when the price has reached the specified price limit, swapping stops
        if (
            (state.zeroForOne && swapForBoundaryState.priceX96 <= state.priceLimitX96) ||
            (!state.zeroForOne && swapForBoundaryState.priceX96 >= state.priceLimitX96)
        ) {
            return true;
        }

        Boundary storage boundary = counterBoundaries[boundaryNext];
        SwapMath.ComputeSwapStep memory step = SwapMath.computeSwapStep(
            swapForBoundaryState.priceX96,
            swapForBoundaryState.boundaryPriceX96,
            state.priceLimitX96,
            state.amountSpecifiedRemaining,
            boundary.makerAmountRemaining,
            takerFee
        );
        // when the amount of swapped out tokens is 0, swapping stops
        if (step.amountOut == 0) return true;

        // updates taker amount input and fee amount input
        state.amountInputCalculated = state.amountInputCalculated + step.amountIn;
        state.feeAmountInputCalculated = state.feeAmountInputCalculated + step.feeAmount;
        state.amountOutputCalculated = state.amountOutputCalculated + step.amountOut;
        state.amountSpecifiedRemaining = state.amountSpecifiedRemaining < 0
            ? state.amountSpecifiedRemaining + int256(uint256(step.amountOut))
            : state.amountSpecifiedRemaining - step.amountIn.toInt256() - int256(uint256(step.feeAmount));

        {
            Bundle storage bundle0 = bundles[boundary.bundle0Id];
            UpdateBundleForTakerParameters memory parameters = bundle0.updateForTaker(
                step.amountIn,
                step.amountOut,
                step.feeAmount
            );
            emit ChangeBundleForSwap(
                boundary.bundle0Id,
                -int256(uint256(parameters.amountOutUsed)),
                parameters.amountInUsed,
                parameters.takerFeeForMakerAmountUsed
            );

            // bundle0 has been fully filled
            if (bundle0.makerAmountRemaining == 0) {
                _activateBundle1(boundary);

                if (parameters.amountOutRemaining > 0) {
                    Bundle storage bundle1 = bundles[boundary.bundle0Id];
                    parameters = bundle1.updateForTaker(
                        parameters.amountInRemaining,
                        parameters.amountOutRemaining,
                        parameters.takerFeeForMakerAmountRemaining
                    );
                    emit ChangeBundleForSwap(
                        boundary.bundle0Id,
                        -int256(uint256(parameters.amountOutUsed)),
                        parameters.amountInUsed,
                        parameters.takerFeeForMakerAmountUsed
                    );
                    // bundle1 has been fully filled
                    if (bundle1.makerAmountRemaining == 0) {
                        _activateBundle1(boundary);
                    }
                }
            }
        }

        // updates remaining maker amount
        uint128 makerAmountRemaining;
        unchecked {
            makerAmountRemaining = boundary.makerAmountRemaining - step.amountOut;
        }
        boundary.makerAmountRemaining = makerAmountRemaining;
        // this boundary has been fully filled
        if (makerAmountRemaining == 0) counterBoundaryBitmap.flipBoundary(boundaryNext, resolution);

        state.priceX96 = step.priceNextX96;
        // when the price has reached the specified lower price, the boundary should equal to boundaryNext,
        // otherwise swapping stops and the boundary is recomputed
        state.boundary = boundaryNext;
        state.boundaryLower = boundaryNext;

        return false;
    }

    function _processTransferForSwap(
        SwapState memory state,
        address recipient,
        bytes calldata data
    ) private returns (int256 amount0, int256 amount1) {
        uint256 amountInputTotal = state.amountInputCalculated + state.feeAmountInputCalculated;
        uint256 amountOutputTotal = state.amountOutputCalculated;
        address tokenToPay;
        address tokenToReceive;
        (tokenToPay, tokenToReceive, amount0, amount1) = state.zeroForOne
            ? (token1, token0, SafeCast.toInt256(amountInputTotal), -SafeCast.toInt256(amountOutputTotal))
            : (token0, token1, -SafeCast.toInt256(amountOutputTotal), SafeCast.toInt256(amountInputTotal));

        // pays token to recipient
        SafeERC20.safeTransfer(IERC20(tokenToPay), recipient, amountOutputTotal);

        uint256 balanceBefore = IERC20(tokenToReceive).balanceOf(address(this));
        // receives token
        IGridSwapCallback(_msgSender()).gridexSwapCallback(amount0, amount1, data);
        uint256 balanceAfter = IERC20(tokenToReceive).balanceOf(address(this));
        // G_TRF: token to receive failed
        require(balanceAfter - balanceBefore >= amountInputTotal, "G_TRF");
    }

    /// @inheritdoc IGrid
    function settleMakerOrder(uint256 orderId) external override lock returns (uint128 amount0, uint128 amount1) {
        (amount0, amount1) = _settleMakerOrder(orderId);

        TokensOwed storage tokensOwed = tokensOweds[_msgSender()];
        if (amount0 > 0) tokensOwed.token0 = tokensOwed.token0 + amount0;
        if (amount1 > 0) tokensOwed.token1 = tokensOwed.token1 + amount1;
    }

    function _settleMakerOrder(uint256 orderId) private returns (uint128 amount0, uint128 amount1) {
        (bool zero, uint128 makerAmountOut, uint128 takerAmountOut, uint128 takerFeeAmountOut) = _processSettleOrder(
            orderId
        );
        (amount0, amount1) = zero
            ? (makerAmountOut, takerAmountOut + takerFeeAmountOut)
            : (takerAmountOut + takerFeeAmountOut, makerAmountOut);
    }

    /// @inheritdoc IGrid
    function settleMakerOrderAndCollect(
        address recipient,
        uint256 orderId,
        bool unwrapWETH9
    ) external override lock returns (uint128 amount0, uint128 amount1) {
        (amount0, amount1) = _settleMakerOrder(orderId);

        _collect(recipient, amount0, amount1, unwrapWETH9);
    }

    /// @inheritdoc IGrid
    function settleMakerOrderAndCollectInBatch(
        address recipient,
        uint256[] memory orderIds,
        bool unwrapWETH9
    ) external override lock returns (uint128 amount0Total, uint128 amount1Total) {
        (amount0Total, amount1Total) = _settleMakerOrderInBatch(orderIds);

        _collect(recipient, amount0Total, amount1Total, unwrapWETH9);
    }

    function _settleMakerOrderInBatch(
        uint256[] memory orderIds
    ) private returns (uint128 amount0Total, uint128 amount1Total) {
        for (uint256 i = 0; i < orderIds.length; i++) {
            (
                bool zero,
                uint128 makerAmountOut,
                uint128 takerAmountOut,
                uint128 takerFeeAmountOut
            ) = _processSettleOrder(orderIds[i]);
            (amount0Total, amount1Total) = zero
                ? (amount0Total + makerAmountOut, amount1Total + takerAmountOut + takerFeeAmountOut)
                : (amount0Total + takerAmountOut + takerFeeAmountOut, amount1Total + makerAmountOut);
        }
    }

    function _processSettleOrder(
        uint256 orderId
    ) private returns (bool zero, uint128 makerAmountOut, uint128 takerAmountOut, uint128 takerFeeAmountOut) {
        Order memory order = orders[orderId];
        // G_COO: caller is not the order owner
        require(order.owner == _msgSender(), "G_COO");

        // deletes order from storage
        delete orders[orderId];

        Bundle storage bundle = bundles[order.bundleId];
        zero = bundle.zero;

        uint128 makerAmountTotalNew;
        (makerAmountOut, takerAmountOut, takerFeeAmountOut, makerAmountTotalNew) = bundle.removeLiquidity(order.amount);

        emit ChangeBundleForSettleOrder(
            order.bundleId,
            -int256(uint256(order.amount)),
            -int256(uint256(makerAmountOut))
        );

        // removes liquidity from boundary
        Boundary storage boundary = _boundaryAt(bundle.boundaryLower, zero);
        uint64 bundle0Id = boundary.bundle0Id;
        if (bundle0Id == order.bundleId || boundary.bundle1Id == order.bundleId) {
            uint128 makerAmountRemaining = boundary.makerAmountRemaining - makerAmountOut;
            boundary.makerAmountRemaining = makerAmountRemaining;
            // all bundle liquidity is removed
            if (makerAmountTotalNew == 0) {
                // when the liquidity of bundle0 is fully removed:
                // 1. Activate directly when bundle1 has been initialized
                // 2. Reuse bundle0 to save gas
                if (bundle0Id == order.bundleId && boundary.bundle1Id > 0) _activateBundle1(boundary);
                if (makerAmountRemaining == 0) _flipBoundary(bundle.boundaryLower, zero);
            }
        }

        emit SettleMakerOrder(orderId, makerAmountOut, takerAmountOut, takerFeeAmountOut);
    }

    function _collect(address recipient, uint128 amount0, uint128 amount1, bool unwrapWETH9) private {
        if (amount0 > 0) {
            _collectSingle(recipient, token0, amount0, unwrapWETH9);
        }
        if (amount1 > 0) {
            _collectSingle(recipient, token1, amount1, unwrapWETH9);
        }
        emit Collect(_msgSender(), recipient, amount0, amount1);
    }

    function _collectSingle(address recipient, address token, uint128 amount, bool unwrapWETH9) private {
        if (unwrapWETH9 && token == weth9) {
            IWETHMinimum(token).withdraw(amount);
            Address.sendValue(payable(recipient), amount);
        } else {
            SafeERC20.safeTransfer(IERC20(token), recipient, amount);
        }
    }

    /// @inheritdoc IGrid
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external override lock {
        uint256 balance0Before;
        uint256 balance1Before;

        if (amount0 > 0) {
            balance0Before = _balance0();
            SafeERC20.safeTransfer(IERC20(token0), recipient, amount0);
        }
        if (amount1 > 0) {
            balance1Before = _balance1();
            SafeERC20.safeTransfer(IERC20(token1), recipient, amount1);
        }

        IGridFlashCallback(_msgSender()).gridexFlashCallback(data);

        uint128 paid0;
        uint128 paid1;
        if (amount0 > 0) {
            uint256 balance0After = _balance0();
            paid0 = (balance0After - balance0Before).toUint128();
        }
        if (amount1 > 0) {
            uint256 balance1After = _balance1();
            paid1 = (balance1After - balance1Before).toUint128();
        }

        emit Flash(_msgSender(), recipient, amount0, amount1, paid0, paid1);
    }

    /// @inheritdoc IGrid
    function collect(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock returns (uint128 amount0, uint128 amount1) {
        (amount0, amount1) = _collectOwed(tokensOweds[_msgSender()], recipient, amount0Requested, amount1Requested);

        emit Collect(_msgSender(), recipient, amount0, amount1);
    }

    function _collectOwed(
        TokensOwed storage tokensOwed,
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) private returns (uint128 amount0, uint128 amount1) {
        if (amount0Requested > 0) {
            amount0 = Uint128Math.minUint128(amount0Requested, tokensOwed.token0);
            unchecked {
                tokensOwed.token0 = tokensOwed.token0 - amount0;
            }

            SafeERC20.safeTransfer(IERC20(token0), recipient, amount0);
        }
        if (amount1Requested > 0) {
            amount1 = Uint128Math.minUint128(amount1Requested, tokensOwed.token1);
            unchecked {
                tokensOwed.token1 = tokensOwed.token1 - amount1;
            }
            SafeERC20.safeTransfer(IERC20(token1), recipient, amount1);
        }
    }

    function _balance0() private view returns (uint256) {
        return IERC20(token0).balanceOf(address(this));
    }

    function _balance1() private view returns (uint256) {
        return IERC20(token1).balanceOf(address(this));
    }

    /// @dev Returns the next order id
    function _nextOrderId() private returns (uint256 orderId) {
        orderId = ++_orderId;
    }

    /// @dev Returns the next order id in a given batch
    function _nextOrderIdInBatch(uint256 batch) private returns (uint256 orderId) {
        orderId = _orderId;
        _orderId = orderId + batch;
        unchecked {
            return orderId + 1;
        }
    }

    /// @dev Returns the next bundle id
    function _nextBundleId() private returns (uint64 bundleId) {
        bundleId = ++_bundleId;
    }

    /// @dev Creates and returns the next bundle and its corresponding id
    function _nextBundle(int24 boundaryLower, bool zero) private returns (uint64 bundleId, Bundle storage bundle) {
        bundleId = _nextBundleId();
        bundle = bundles[bundleId];
        bundle.boundaryLower = boundaryLower;
        bundle.zero = zero;
    }

    /// @dev Returns a mapping of the boundaries of either token0 or token1
    function _boundaries(bool zero) private view returns (mapping(int24 => Boundary) storage) {
        return zero ? boundaries0 : boundaries1;
    }

    /// @dev Returns the boundary of token0 or token1
    function _boundaryAt(int24 boundary, bool zero) private view returns (Boundary storage) {
        return zero ? boundaries0[boundary] : boundaries1[boundary];
    }

    /// @dev Flip the boundary of token0 or token1
    function _flipBoundary(int24 boundary, bool zero) private {
        _boundaryBitmaps(zero).flipBoundary(boundary, resolution);
    }

    /// @dev Returns the boundary bitmap of token0 or token1
    function _boundaryBitmaps(bool zero) private view returns (mapping(int16 => uint256) storage) {
        return zero ? boundaryBitmaps0 : boundaryBitmaps1;
    }

    /// @dev Closes bundle0 and activates bundle1
    function _activateBundle1(Boundary storage self) internal {
        self.bundle0Id = self.bundle1Id;
        self.bundle1Id = 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IGrid#flash
/// @notice Any contract that calls IGrid#flash must implement this interface
interface IGridFlashCallback {
    /// @notice Called to `msg.sender` after executing a flash via IGrid#flash
    /// @dev In this implementation, you are required to repay the grid the tokens owed for the flash.
    /// The caller of the method must be a grid deployed by the canonical GridFactory.
    /// @param data Any data passed through by the caller via the [email protected] call
    function gridexFlashCallback(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IGrid#placeMakerOrder
/// @notice Any contract that calls IGrid#placeMakerOrder must implement this interface
interface IGridPlaceMakerOrderCallback {
    /// @notice Called to `msg.sender` after executing a place maker order via IGrid#placeMakerOrder
    /// @dev In this implementation, you are required to pay the grid tokens owed for the maker order.
    /// The caller of the method must be a grid deployed by the canonical GridFactory.
    /// At most one of amount0 and amount1 is a positive number
    /// @param amount0 The grid will receive the amount of token0 upon placement of the maker order.
    /// In the receiving case, the callback must send this amount of token0 to the grid
    /// @param amount1 The grid will receive the amount of token1 upon placement of the maker order.
    /// In the receiving case, the callback must send this amount of token1 to the grid
    /// @param data Any data passed through by the caller via the IGrid#placeMakerOrder call
    function gridexPlaceMakerOrderCallback(uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IGrid#swap
/// @notice Any contract that calls IGrid#swap must implement this interface
interface IGridSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IGrid#swap
    /// @dev In this implementation, you are required to pay the grid tokens owed for the swap.
    /// The caller of the method must be a grid deployed by the canonical GridFactory.
    /// If there is no token swap, both amount0Delta and amount1Delta are 0
    /// @param amount0Delta The grid will send or receive the amount of token0 upon completion of the swap.
    /// In the receiving case, the callback must send this amount of token0 to the grid
    /// @param amount1Delta The grid will send or receive the quantity of token1 upon completion of the swap.
    /// In the receiving case, the callback must send this amount of token1 to the grid
    /// @param data Any data passed through by the caller via the IGrid#swap call
    function gridexSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IGridStructs.sol";
import "./IGridParameters.sol";

/// @title The interface for Gridex grid
interface IGrid {
    ///==================================== Grid States  ====================================

    /// @notice The first token in the grid, after sorting by address
    function token0() external view returns (address);

    /// @notice The second token in the grid, after sorting by address
    function token1() external view returns (address);

    /// @notice The step size in initialized boundaries for a grid created with a given fee
    function resolution() external view returns (int24);

    /// @notice The fee paid to the grid denominated in hundredths of a bip, i.e. 1e-6
    function takerFee() external view returns (int24);

    /// @notice The 0th slot of the grid holds a lot of values that can be gas-efficiently accessed
    /// externally as a single method
    /// @return priceX96 The current price of the grid, as a Q64.96
    /// @return boundary The current boundary of the grid
    /// @return blockTimestamp The time the oracle was last updated
    /// @return unlocked Whether the grid is unlocked or not
    function slot0() external view returns (uint160 priceX96, int24 boundary, uint32 blockTimestamp, bool unlocked);

    /// @notice Returns the boundary information of token0
    /// @param boundary The boundary of the grid
    /// @return bundle0Id The unique identifier of bundle0
    /// @return bundle1Id The unique identifier of bundle1
    /// @return makerAmountRemaining The remaining amount of token0 that can be swapped out,
    /// which is the sum of bundle0 and bundle1
    function boundaries0(
        int24 boundary
    ) external view returns (uint64 bundle0Id, uint64 bundle1Id, uint128 makerAmountRemaining);

    /// @notice Returns the boundary information of token1
    /// @param boundary The boundary of the grid
    /// @return bundle0Id The unique identifier of bundle0
    /// @return bundle1Id The unique identifier of bundle1
    /// @return makerAmountRemaining The remaining amount of token1 that can be swapped out,
    /// which is the sum of bundle0 and bundle1
    function boundaries1(
        int24 boundary
    ) external view returns (uint64 bundle0Id, uint64 bundle1Id, uint128 makerAmountRemaining);

    /// @notice Returns 256 packed boundary initialized boolean values for token0
    function boundaryBitmaps0(int16 wordPos) external view returns (uint256 word);

    /// @notice Returns 256 packed boundary initialized boolean values for token1
    function boundaryBitmaps1(int16 wordPos) external view returns (uint256 word);

    /// @notice Returns the amount owed for token0 and token1
    /// @param owner The address of owner
    /// @return token0 The amount of token0 owed
    /// @return token1 The amount of token1 owed
    function tokensOweds(address owner) external view returns (uint128 token0, uint128 token1);

    /// @notice Returns the information of a given bundle
    /// @param bundleId The unique identifier of the bundle
    /// @return boundaryLower The lower boundary of the bundle
    /// @return zero When zero is true, it represents token0, otherwise it represents token1
    /// @return makerAmountTotal The total amount of token0 or token1 that the maker added
    /// @return makerAmountRemaining The remaining amount of token0 or token1 that can be swapped out from the makers
    /// @return takerAmountRemaining The remaining amount of token0 or token1 that have been swapped in from the takers
    /// @return takerFeeAmountRemaining The remaining amount of fees that takers have paid in
    function bundles(
        uint64 bundleId
    )
        external
        view
        returns (
            int24 boundaryLower,
            bool zero,
            uint128 makerAmountTotal,
            uint128 makerAmountRemaining,
            uint128 takerAmountRemaining,
            uint128 takerFeeAmountRemaining
        );

    /// @notice Returns the information of a given order
    /// @param orderId The unique identifier of the order
    /// @return bundleId The unique identifier of the bundle -- represents which bundle this order belongs to
    /// @return owner The address of the owner of the order
    /// @return amount The amount of token0 or token1 to add
    function orders(uint256 orderId) external view returns (uint64 bundleId, address owner, uint128 amount);

    ///==================================== Grid Actions ====================================

    /// @notice Initializes the grid with the given parameters
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback.
    /// When initializing the grid, token0 and token1's liquidity must be added simultaneously.
    /// @param parameters The parameters used to initialize the grid
    /// @param data Any data to be passed through to the callback
    /// @return orderIds0 The unique identifiers of the orders for token0
    /// @return orderIds1 The unique identifiers of the orders for token1
    function initialize(
        IGridParameters.InitializeParameters memory parameters,
        bytes calldata data
    ) external returns (uint256[] memory orderIds0, uint256[] memory orderIds1);

    /// @notice Swaps token0 for token1, or vice versa
    /// @dev The caller of this method receives a callback in the form of IGridSwapCallback#gridexSwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The swap direction, true for token0 to token1 and false otherwise
    /// @param amountSpecified The amount of the swap, configured as an exactInput (positive)
    /// or an exactOutput (negative)
    /// @param priceLimitX96 Swap price limit: if zeroForOne, the price will not be less than this value after swap,
    /// if oneForZero, it will not be greater than this value after swap, as a Q64.96
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The balance change of the grid's token0. When negative, it will reduce the balance
    /// by the exact amount. When positive, it will increase by at least this amount
    /// @return amount1 The balance change of the grid's token1. When negative, it will reduce the balance
    /// by the exact amount. When positive, it will increase by at least this amount.
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 priceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Places a maker order on the grid
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback
    /// @param parameters The parameters used to place the maker order
    /// @param data Any data to be passed through to the callback
    /// @return orderId The unique identifier of the order
    function placeMakerOrder(
        IGridParameters.PlaceOrderParameters memory parameters,
        bytes calldata data
    ) external returns (uint256 orderId);

    /// @notice Places maker orders on the grid
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback
    /// @param parameters The parameters used to place the maker orders
    /// @param data Any data to be passed through to the callback
    /// @return orderIds The unique identifiers of the orders
    function placeMakerOrderInBatch(
        IGridParameters.PlaceOrderInBatchParameters memory parameters,
        bytes calldata data
    ) external returns (uint256[] memory orderIds);

    /// @notice Settles a maker order
    /// @param orderId The unique identifier of the order
    /// @return amount0 The amount of token0 that the maker received
    /// @return amount1 The amount of token1 that the maker received
    function settleMakerOrder(uint256 orderId) external returns (uint128 amount0, uint128 amount1);

    /// @notice Settle maker order and collect
    /// @param recipient The address to receive the output of the settlement
    /// @param orderId The unique identifier of the order
    /// @param unwrapWETH9 Whether to unwrap WETH9 to ETH
    /// @return amount0 The amount of token0 that the maker received
    /// @return amount1 The amount of token1 that the maker received
    function settleMakerOrderAndCollect(
        address recipient,
        uint256 orderId,
        bool unwrapWETH9
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Settles maker orders and collects in a batch
    /// @param recipient The address to receive the output of the settlement
    /// @param orderIds The unique identifiers of the orders
    /// @param unwrapWETH9 Whether to unwrap WETH9 to ETH
    /// @return amount0Total The total amount of token0 that the maker received
    /// @return amount1Total The total amount of token1 that the maker received
    function settleMakerOrderAndCollectInBatch(
        address recipient,
        uint256[] memory orderIds,
        bool unwrapWETH9
    ) external returns (uint128 amount0Total, uint128 amount1Total);

    /// @notice For flash swaps. The caller borrows assets and returns them in the callback of the function,
    /// in addition to a fee
    /// @dev The caller of this function receives a callback in the form of IGridFlashCallback#gridexFlashCallback
    /// @param recipient The address which will receive the token0 and token1
    /// @param amount0 The amount of token0 to receive
    /// @param amount1 The amount of token1 to receive
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

    /// @notice Collects tokens owed
    /// @param recipient The address to receive the collected fees
    /// @param amount0Requested The maximum amount of token0 to send.
    /// Set to 0 if fees should only be collected in token1.
    /// @param amount1Requested The maximum amount of token1 to send.
    /// Set to 0 if fees should only be collected in token0.
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title A contract interface for deploying grids
/// @notice A grid constructor must use the interface to pass arguments to the grid
/// @dev This is necessary to ensure there are no constructor arguments in the grid contract.
/// This keeps the grid init code hash constant, allowing a CREATE2 address to be computed on-chain gas-efficiently.
interface IGridDeployer {
    struct Parameters {
        address token0;
        address token1;
        int24 resolution;
        int24 takerFee;
        address priceOracle;
        address weth9;
    }

    /// @notice Returns the grid creation code
    function gridCreationCode() external view returns (bytes memory);

    /// @notice Getter for the arguments used in constructing the grid. These are set locally during grid creation
    /// @dev Retrieves grid parameters, after being called by the grid constructor
    /// @return token0 The first token in the grid, after sorting by address
    /// @return token1 The second token in the grid, after sorting by address
    /// @return resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return takerFee The taker fee, denominated in hundredths of a bip (i.e. 1e-6)
    /// @return priceOracle The address of the price oracle contract
    /// @return weth9 The address of the WETH9 contract
    function parameters()
        external
        view
        returns (
            address token0,
            address token1,
            int24 resolution,
            int24 takerFee,
            address priceOracle,
            address weth9
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IGridStructs.sol";

/// @title Events emitted by the grid contract
interface IGridEvents {
    /// @notice Emitted exactly once by a grid when #initialize is first called on the grid
    /// @param priceX96 The initial price of the grid, as a Q64.96
    /// @param boundary The initial boundary of the grid
    event Initialize(uint160 priceX96, int24 boundary);

    /// @notice Emitted when the maker places an order to add liquidity for token0 or token1
    /// @param orderId The unique identifier of the order
    /// @param recipient The address that received the order
    /// @param bundleId The unique identifier of the bundle -- represents which bundle this order belongs to
    /// @param zero When zero is true, it represents token0, otherwise it represents token1
    /// @param boundaryLower The lower boundary of the order
    /// @param amount The amount of token0 or token1 to add
    event PlaceMakerOrder(
        uint256 indexed orderId,
        address indexed recipient,
        uint64 indexed bundleId,
        bool zero,
        int24 boundaryLower,
        uint128 amount
    );

    /// @notice Emitted when settling a single range order
    /// @param orderId The unique identifier of the order
    /// @param makerAmountOut The amount of token0 or token1 that the maker has removed
    /// @param takerAmountOut The amount of token0 or token1 that the taker has submitted
    /// @param takerFeeAmountOut The amount of token0 or token1 fees that the taker has paid
    event SettleMakerOrder(
        uint256 indexed orderId,
        uint128 makerAmountOut,
        uint128 takerAmountOut,
        uint128 takerFeeAmountOut
    );

    /// @notice Emitted when a maker settles an order
    /// @dev When either of the bundle's total maker amount or the remaining maker amount becomes 0,
    /// the bundle is closed
    /// @param bundleId The unique identifier of the bundle
    /// @param makerAmountTotal The change in the total maker amount in the bundle
    /// @param makerAmountRemaining The change in the remaining maker amount in the bundle
    event ChangeBundleForSettleOrder(uint64 indexed bundleId, int256 makerAmountTotal, int256 makerAmountRemaining);

    /// @notice Emitted when a taker is swapping
    /// @dev When the bundle's remaining maker amount becomes 0, the bundle is closed
    /// @param bundleId The unique identifier of the bundle
    /// @param makerAmountRemaining The change in the remaining maker amount in the bundle
    /// @param amountIn The change in the remaining taker amount in the bundle
    /// @param takerFeeAmountIn The change in the remaining taker fee amount in the bundle
    event ChangeBundleForSwap(
        uint64 indexed bundleId,
        int256 makerAmountRemaining,
        uint256 amountIn,
        uint128 takerFeeAmountIn
    );

    /// @notice Emitted by the grid for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the grid
    /// @param amount1 The delta of the token1 balance of the grid
    /// @param priceX96 The price of the grid after the swap, as a Q64.96
    /// @param boundary The log base 1.0001 of the price of the grid after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 priceX96,
        int24 boundary
    );

    /// @notice Emitted by the grid for any flashes of token0/token1
    /// @param sender The address that initiated the flash call, and that received the callback
    /// @param recipient The address that received the tokens from the flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint128 paid0,
        uint128 paid1
    );

    /// @notice Emitted when the collected owed fees are withdrawn by the sender
    /// @param sender The address that collects the fees
    /// @param recipient The address that receives the fees
    /// @param amount0 The amount of token0 fees that is withdrawn
    /// @param amount1 The amount of token1 fees that is withdrawn
    event Collect(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IGridParameters {
    /// @dev Parameters for initializing the grid
    struct InitializeParameters {
        /// @dev The initial price of the grid, as a Q64.96.
        /// Price is represented as an amountToken1/amountToken0 Q64.96 value.
        uint160 priceX96;
        /// @dev The address to receive orders
        address recipient;
        /// @dev Represents the order parameters for token0
        BoundaryLowerWithAmountParameters[] orders0;
        /// @dev Represents the order parameters for token1
        BoundaryLowerWithAmountParameters[] orders1;
    }

    /// @dev Parameters for placing an order
    struct PlaceOrderParameters {
        /// @dev The address to receive the order
        address recipient;
        /// @dev When zero is true, it represents token0, otherwise it represents token1
        bool zero;
        /// @dev The lower boundary of the order
        int24 boundaryLower;
        /// @dev The amount of token0 or token1 to add
        uint128 amount;
    }

    struct PlaceOrderInBatchParameters {
        /// @dev The address to receive the order
        address recipient;
        /// @dev When zero is true, it represents token0, otherwise it represents token1
        bool zero;
        BoundaryLowerWithAmountParameters[] orders;
    }

    struct BoundaryLowerWithAmountParameters {
        /// @dev The lower boundary of the order
        int24 boundaryLower;
        /// @dev The amount of token0 or token1 to add
        uint128 amount;
    }

    /// @dev Status during swap
    struct SwapState {
        /// @dev When true, token0 is swapped for token1, otherwise token1 is swapped for token0
        bool zeroForOne;
        /// @dev The remaining amount of the swap, which implicitly configures
        /// the swap as exact input (positive), or exact output (negative)
        int256 amountSpecifiedRemaining;
        /// @dev The calculated amount to be inputted
        uint256 amountInputCalculated;
        /// @dev The calculated amount of fee to be inputted
        uint256 feeAmountInputCalculated;
        /// @dev The calculated amount to be outputted
        uint256 amountOutputCalculated;
        /// @dev The price of the grid, as a Q64.96
        uint160 priceX96;
        uint160 priceLimitX96;
        /// @dev The boundary of the grid
        int24 boundary;
        /// @dev The lower boundary of the grid
        int24 boundaryLower;
        uint160 initializedBoundaryLowerPriceX96;
        uint160 initializedBoundaryUpperPriceX96;
        /// @dev Whether the swap has been completed
        bool stopSwap;
    }

    struct SwapForBoundaryState {
        /// @dev The price indicated by the lower boundary, as a Q64.96
        uint160 boundaryLowerPriceX96;
        /// @dev The price indicated by the upper boundary, as a Q64.96
        uint160 boundaryUpperPriceX96;
        /// @dev The price indicated by the lower or upper boundary, as a Q64.96.
        /// When using token0 to exchange token1, it is equal to boundaryLowerPriceX96,
        /// otherwise it is equal to boundaryUpperPriceX96
        uint160 boundaryPriceX96;
        /// @dev The price of the grid, as a Q64.96
        uint160 priceX96;
    }

    struct UpdateBundleForTakerParameters {
        /// @dev The amount to be swapped in to bundle0
        uint256 amountInUsed;
        /// @dev The remaining amount to be swapped in to bundle1
        uint256 amountInRemaining;
        /// @dev The amount to be swapped out to bundle0
        uint128 amountOutUsed;
        /// @dev The remaining amount to be swapped out to bundle1
        uint128 amountOutRemaining;
        /// @dev The amount to be paid to bundle0
        uint128 takerFeeForMakerAmountUsed;
        /// @dev The amount to be paid to bundle1
        uint128 takerFeeForMakerAmountRemaining;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IGridStructs {
    struct Bundle {
        int24 boundaryLower;
        bool zero;
        uint128 makerAmountTotal;
        uint128 makerAmountRemaining;
        uint128 takerAmountRemaining;
        uint128 takerFeeAmountRemaining;
    }

    struct Boundary {
        uint64 bundle0Id;
        uint64 bundle1Id;
        uint128 makerAmountRemaining;
    }

    struct Order {
        uint64 bundleId;
        address owner;
        uint128 amount;
    }

    struct TokensOwed {
        uint128 token0;
        uint128 token1;
    }

    struct Slot0 {
        uint160 priceX96;
        int24 boundary;
        uint32 blockTimestamp;
        bool unlocked;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for the price oracle
interface IPriceOracle {
    /// @notice Emitted when the capacity of the array in which the oracle can store prices has increased.
    /// @param grid The grid address whose capacity has been increased
    /// @param capacityOld Array capacity before the increase in capacity
    /// @param capacityNew Array capacity after the increase in capacity
    event IncreaseCapacity(address indexed grid, uint16 capacityOld, uint16 capacityNew);

    struct GridPriceData {
        /// @dev The block timestamp of the price data
        uint32 blockTimestamp;
        /// @dev The time-cumulative boundary
        int56 boundaryCumulative;
        /// @dev Whether or not the price data is initialized
        bool initialized;
    }

    struct GridOracleState {
        /// @dev The index of the last updated price
        uint16 index;
        /// @dev The array capacity used by the oracle
        uint16 capacity;
        /// @dev The capacity of the array that the oracle can use
        uint16 capacityNext;
    }

    /// @notice Returns the state of the oracle for a given grid
    /// @param grid The grid to retrieve the state of
    /// @return index The index of the last updated price
    /// @return capacity The array capacity used by the oracle
    /// @return capacityNext The capacity of the array that the oracle can use
    function gridOracleStates(address grid) external view returns (uint16 index, uint16 capacity, uint16 capacityNext);

    /// @notice Returns the price data of the oracle for a given grid and index
    /// @param grid The grid to get the price data of
    /// @param index The index of the price data to get
    /// @return blockTimestamp The block timestamp of the price data
    /// @return boundaryCumulative The time-cumulative boundary
    /// @return initialized Whether or not the price data is initialized
    function gridPriceData(
        address grid,
        uint256 index
    ) external view returns (uint32 blockTimestamp, int56 boundaryCumulative, bool initialized);

    /// @notice Register a grid to the oracle using a given token pair and resolution
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    function register(address tokenA, address tokenB, int24 resolution) external;

    /// @notice Update the oracle price
    /// @param boundary The new boundary to write to the oracle
    /// @param blockTimestamp The timestamp of the oracle price to write
    function update(int24 boundary, uint32 blockTimestamp) external;

    /// @notice Increase the storage capacity of the oracle
    /// @param grid The grid whose capacity is to be increased
    /// @param capacityNext Array capacity after increase in capacity
    function increaseCapacity(address grid, uint16 capacityNext) external;

    /// @notice Get the time-cumulative price for a given time
    /// @param grid Get the price of a grid address
    /// @param secondsAgo The time elapsed (in seconds) to get the boundary for
    /// @return boundaryCumulative The time-cumulative boundary for the given time
    function getBoundaryCumulative(address grid, uint32 secondsAgo) external view returns (int56 boundaryCumulative);

    /// @notice Get a list of time-cumulative boundaries for given times
    /// @param grid The grid address to get the boundaries of
    /// @param secondsAgos A list of times elapsed (in seconds) to get the boundaries for
    /// @return boundaryCumulatives The list of time-cumulative boundaries for the given times
    function getBoundaryCumulatives(
        address grid,
        uint32[] calldata secondsAgos
    ) external view returns (int56[] memory boundaryCumulatives);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IWETHMinimum {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address dst) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title BitMath
/// @dev Library for computing the bit properties of unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                r += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                r += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                r += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                r += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                r += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                r += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                r += 2;
            }
            if (x >= 0x2) {
                r += 1;
            }
        }
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        r = 255;
        unchecked {
            if (x & type(uint128).max > 0) {
                r -= 128;
            } else {
                x >>= 128;
            }
            if (x & type(uint64).max > 0) {
                r -= 64;
            } else {
                x >>= 64;
            }
            if (x & type(uint32).max > 0) {
                r -= 32;
            } else {
                x >>= 32;
            }
            if (x & type(uint16).max > 0) {
                r -= 16;
            } else {
                x >>= 16;
            }
            if (x & type(uint8).max > 0) {
                r -= 8;
            } else {
                x >>= 8;
            }
            if (x & 0xf > 0) {
                r -= 4;
            } else {
                x >>= 4;
            }
            if (x & 0x3 > 0) {
                r -= 2;
            } else {
                x >>= 2;
            }
            if (x & 0x1 > 0) {
                r -= 1;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./BitMath.sol";
import "./BoundaryMath.sol";

library BoundaryBitmap {
    /// @notice Calculates the position of the bit in the bitmap for a given boundary
    /// @param boundary The boundary for calculating the bit position
    /// @return wordPos The key within the mapping that contains the word storing the bit
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 boundary) internal pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(boundary >> 8);
        bitPos = uint8(uint24(boundary));
    }

    /// @notice Flips the boolean value of the initialization state of the given boundary
    /// @param self The mapping that stores the initial state of the boundary
    /// @param boundary The boundary to flip
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    function flipBoundary(mapping(int16 => uint256) storage self, int24 boundary, int24 resolution) internal {
        require(boundary % resolution == 0);
        (int16 wordPos, uint8 bitPos) = position(boundary / resolution);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    /// @notice Returns the next initialized boundary as the left boundary (less than)
    /// or the right boundary (more than)
    /// @param self The mapping that stores the initial state of the boundary
    /// @param boundary The starting boundary
    /// @param priceX96 Price of the initial boundary, as a Q64.96
    /// @param currentBoundaryInitialized Whether the starting boundary is initialized or not
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @param boundaryLower The starting lower boundary of the grid
    /// @param lte Whether or not to search for the next initialized boundary
    /// to the left (less than or equal to the starting boundary)
    /// @return next The next boundary, regardless of initialization state
    /// @return initialized Whether or not the next boundary is initialized
    /// @return initializedBoundaryLowerPriceX96 If the current boundary has been initialized and can be swapped,
    /// return the current left boundary price, otherwise return 0, as a Q64.96
    /// @return initializedBoundaryUpperPriceX96 If the current boundary has been initialized and can be swapped,
    /// return the current right boundary price, otherwise return 0, as a Q64.96
    function nextInitializedBoundary(
        mapping(int16 => uint256) storage self,
        int24 boundary,
        uint160 priceX96,
        bool currentBoundaryInitialized,
        int24 resolution,
        int24 boundaryLower,
        bool lte
    )
        internal
        view
        returns (
            int24 next,
            bool initialized,
            uint160 initializedBoundaryLowerPriceX96,
            uint160 initializedBoundaryUpperPriceX96
        )
    {
        int24 boundaryUpper = boundaryLower + resolution;
        if (currentBoundaryInitialized) {
            if (lte) {
                uint160 boundaryLowerPriceX96 = BoundaryMath.getPriceX96AtBoundary(boundaryLower);
                if (boundaryLowerPriceX96 < priceX96) {
                    return (
                        boundaryLower,
                        true,
                        boundaryLowerPriceX96,
                        BoundaryMath.getPriceX96AtBoundary(boundaryUpper)
                    );
                }
            } else {
                uint160 boundaryUpperPriceX96 = BoundaryMath.getPriceX96AtBoundary(boundaryUpper);
                if (boundaryUpperPriceX96 > priceX96) {
                    return (
                        boundaryLower,
                        true,
                        BoundaryMath.getPriceX96AtBoundary(boundaryLower),
                        boundaryUpperPriceX96
                    );
                }
            }
        }

        // When the price is rising and the current boundary coincides with the upper boundary, start searching
        // from the lower boundary. Otherwise, start searching from the current boundary
        boundary = !lte && boundaryUpper == boundary ? boundaryLower : boundary;
        while (BoundaryMath.isInRange(boundary)) {
            (next, initialized) = nextInitializedBoundaryWithinOneWord(self, boundary, resolution, lte);
            if (initialized) {
                unchecked {
                    return (
                        next,
                        true,
                        BoundaryMath.getPriceX96AtBoundary(next),
                        BoundaryMath.getPriceX96AtBoundary(next + resolution)
                    );
                }
            }
            boundary = next;
        }
    }

    /// @notice Returns the next initialized boundary contained in the same (or adjacent) word
    /// as the boundary that is either to the left (less than) or right (greater than)
    /// of the given boundary
    /// @param self The mapping that stores the initial state of the boundary
    /// @param boundary The starting boundary
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @param lte Whether or not to search to the left (less than or equal to the start boundary)
    /// for the next initialization
    /// @return next The next boundary, regardless of initialization state
    /// @return initialized Whether or not the next boundary is initialized
    function nextInitializedBoundaryWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 boundary,
        int24 resolution,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = boundary / resolution;

        if (lte) {
            // Begin from the word of the next boundary, since the current boundary state is immaterial
            (int16 wordPos, uint8 bitPos) = position(compressed - 1);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = ~uint256(0) >> (type(uint8).max - bitPos);
            uint256 masked = self[wordPos] & mask;

            // If no initialized boundaries exist to the right of the current boundary,
            // return the rightmost boundary in the word
            initialized = masked != 0;
            // Overflow/underflow is possible. The resolution and the boundary should be limited
            // when calling externally to prevent this
            next = initialized
                ? (compressed - 1 - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * resolution
                : (compressed - 1 - int24(uint24(bitPos))) * resolution;
        } else {
            if (boundary < 0 && boundary % resolution != 0) {
                // round towards negative infinity
                --compressed;
            }

            // Begin from the word of the next boundary, since the current boundary state is immaterial
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~uint256(0) << bitPos;
            uint256 masked = self[wordPos] & mask;

            // If no initialized boundaries exist to the left of the current boundary,
            // return the leftmost boundary in the word
            initialized = masked != 0;
            // Overflow/underflow is possible. The resolution and the boundary should be limited
            // when calling externally to prevent this
            next = initialized
                ? (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * resolution
                : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * resolution;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library BoundaryMath {
    int24 public constant MIN_BOUNDARY = -527400;
    int24 public constant MAX_BOUNDARY = 443635;

    /// @dev The minimum value that can be returned from #getPriceX96AtBoundary. Equivalent to getPriceX96AtBoundary(MIN_BOUNDARY)
    uint160 internal constant MIN_RATIO = 989314;
    /// @dev The maximum value that can be returned from #getPriceX96AtBoundary. Equivalent to getPriceX96AtBoundary(MAX_BOUNDARY)
    uint160 internal constant MAX_RATIO = 1461300573427867316570072651998408279850435624081;

    /// @dev Checks if a boundary is divisible by a resolution
    /// @param boundary The boundary to check
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return isValid Whether or not the boundary is valid
    function isValidBoundary(int24 boundary, int24 resolution) internal pure returns (bool isValid) {
        return boundary % resolution == 0;
    }

    /// @dev Checks if a boundary is within the valid range
    /// @param boundary The boundary to check
    /// @return inRange Whether or not the boundary is in range
    function isInRange(int24 boundary) internal pure returns (bool inRange) {
        return boundary >= MIN_BOUNDARY && boundary <= MAX_BOUNDARY;
    }

    /// @dev Checks if a price is within the valid range
    /// @param priceX96 The price to check, as a Q64.96
    /// @return inRange Whether or not the price is in range
    function isPriceX96InRange(uint160 priceX96) internal pure returns (bool inRange) {
        return priceX96 >= MIN_RATIO && priceX96 <= MAX_RATIO;
    }

    /// @notice Calculates the price at a given boundary
    /// @dev priceX96 = pow(1.0001, boundary) * 2**96
    /// @param boundary The boundary to calculate the price at
    /// @return priceX96 The price at the boundary, as a Q64.96
    function getPriceX96AtBoundary(int24 boundary) internal pure returns (uint160 priceX96) {
        unchecked {
            uint256 absBoundary = boundary < 0 ? uint256(-int256(boundary)) : uint24(boundary);

            uint256 ratio = absBoundary & 0x1 != 0
                ? 0xfff97272373d413259a46990580e213a
                : 0x100000000000000000000000000000000;
            if (absBoundary & 0x2 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absBoundary & 0x4 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absBoundary & 0x8 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absBoundary & 0x10 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absBoundary & 0x20 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absBoundary & 0x40 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absBoundary & 0x80 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absBoundary & 0x100 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absBoundary & 0x200 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absBoundary & 0x400 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absBoundary & 0x800 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absBoundary & 0x1000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absBoundary & 0x2000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absBoundary & 0x4000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absBoundary & 0x8000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absBoundary & 0x10000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absBoundary & 0x20000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absBoundary & 0x40000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
            if (absBoundary & 0x80000 != 0) ratio = (ratio * 0x149b34ee7ac263) >> 128;

            if (boundary > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 and rounds up to go from a Q128.128 to a Q128.96.
            // due to out boundary input limitations, we then proceed to downcast as the
            // result will always fit within 160 bits.
            // we round up in the division so that getBoundaryAtPriceX96 of the output price is always consistent
            priceX96 = uint160((ratio + 0xffffffff) >> 32);
        }
    }

    /// @notice Calculates the boundary at a given price
    /// @param priceX96 The price to calculate the boundary at, as a Q64.96
    /// @return boundary The boundary at the price
    function getBoundaryAtPriceX96(uint160 priceX96) internal pure returns (int24 boundary) {
        unchecked {
            uint256 ratio = uint256(priceX96) << 32;

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

            int256 log10001 = log_2 * 127869479499801913173570;
            // 128.128 number

            int24 boundaryLow = int24((log10001 - 1701496478404566090792001455681771637) >> 128);
            int24 boundaryHi = int24((log10001 + 289637967442836604689790891002483458648) >> 128);

            boundary = boundaryLow == boundaryHi ? boundaryLow : getPriceX96AtBoundary(boundaryHi) <= priceX96
                ? boundaryHi
                : boundaryLow;
        }
    }

    /// @dev Returns the lower boundary for the given boundary and resolution.
    /// The lower boundary may not be valid (if out of the boundary range)
    /// @param boundary The boundary to get the lower boundary for
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return boundaryLower The lower boundary for the given boundary and resolution
    function getBoundaryLowerAtBoundary(int24 boundary, int24 resolution) internal pure returns (int24 boundaryLower) {
        unchecked {
            return boundary - (((boundary % resolution) + resolution) % resolution);
        }
    }

    /// @dev Rewrite the lower boundary that is not in the range to a valid value
    /// @param boundaryLower The lower boundary to rewrite
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return validBoundaryLower The valid lower boundary
    function rewriteToValidBoundaryLower(
        int24 boundaryLower,
        int24 resolution
    ) internal pure returns (int24 validBoundaryLower) {
        unchecked {
            if (boundaryLower < MIN_BOUNDARY) return boundaryLower + resolution;
            else if (boundaryLower + resolution > MAX_BOUNDARY) return boundaryLower - resolution;
            else return boundaryLower;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IGridStructs.sol";
import "../interfaces/IGridParameters.sol";
import "./FixedPointX128.sol";

library BundleMath {
    using SafeCast for uint256;

    /// @dev Updates for a taker
    /// @param self The bundle
    /// @param amountIn The amount of swapped in token by the taker
    /// @param amountOut The amount of swapped out token by the taker. If amountOut is greater than bundle balance, the difference is transferred to bundle1
    /// @param takerFeeForMakerAmount The fee paid by the taker(excluding the protocol fee). If amountOut is greater than bundle balance, the difference is transferred to bundle1
    function updateForTaker(
        IGridStructs.Bundle storage self,
        uint256 amountIn,
        uint128 amountOut,
        uint128 takerFeeForMakerAmount
    ) internal returns (IGridParameters.UpdateBundleForTakerParameters memory parameters) {
        uint128 makerAmountRemaining = self.makerAmountRemaining;
        // the amount out actually paid to the taker
        parameters.amountOutUsed = amountOut <= makerAmountRemaining ? amountOut : makerAmountRemaining;

        if (parameters.amountOutUsed == amountOut) {
            parameters.amountInUsed = amountIn;

            parameters.takerFeeForMakerAmountUsed = takerFeeForMakerAmount;
        } else {
            parameters.amountInUsed = parameters.amountOutUsed * amountIn / amountOut; // amountOutUsed * amountIn may overflow here
            unchecked {
                parameters.amountInRemaining = amountIn - parameters.amountInUsed;

                parameters.amountOutRemaining = amountOut - parameters.amountOutUsed;

                parameters.takerFeeForMakerAmountUsed = uint128(
                    (uint256(parameters.amountOutUsed) * takerFeeForMakerAmount) / amountOut
                );
                parameters.takerFeeForMakerAmountRemaining =
                    takerFeeForMakerAmount -
                    parameters.takerFeeForMakerAmountUsed;
            }
        }

        // updates maker amount remaining
        unchecked {
            self.makerAmountRemaining = makerAmountRemaining - parameters.amountOutUsed;
        }

        self.takerAmountRemaining = self.takerAmountRemaining + (parameters.amountInUsed).toUint128();

        self.takerFeeAmountRemaining = self.takerFeeAmountRemaining + parameters.takerFeeForMakerAmountUsed;
    }

    /// @notice Maker adds liquidity to the bundle
    /// @param self The bundle to be updated
    /// @param makerAmount The amount of token to be added to the bundle
    function addLiquidity(IGridStructs.Bundle storage self, uint128 makerAmount) internal {
        self.makerAmountTotal = self.makerAmountTotal + makerAmount;
        unchecked {
            self.makerAmountRemaining = self.makerAmountRemaining + makerAmount;
        }
    }

    /// @notice Maker adds liquidity to the bundle
    /// @param self The bundle to be updated
    /// @param makerAmountTotal The total amount of token that the maker has added to the bundle
    /// @param makerAmountRemaining The amount of token that the maker has not yet swapped
    /// @param makerAmount The amount of token to be added to the bundle
    function addLiquidityWithAmount(
        IGridStructs.Bundle storage self,
        uint128 makerAmountTotal,
        uint128 makerAmountRemaining,
        uint128 makerAmount
    ) internal {
        self.makerAmountTotal = makerAmountTotal + makerAmount;
        unchecked {
            self.makerAmountRemaining = makerAmountRemaining + makerAmount;
        }
    }

    /// @notice Maker removes liquidity from the bundle
    /// @param self The bundle to be updated
    /// @param makerAmountRaw The amount of liquidity added by the maker when placing an order
    /// @return makerAmountOut The amount of token0 or token1 that the maker will receive
    /// @return takerAmountOut The amount of token1 or token0 that the maker will receive
    /// @return takerFeeAmountOut The amount of fees that the maker will receive
    /// @return makerAmountTotalNew The remaining amount of liquidity added by the maker
    function removeLiquidity(
        IGridStructs.Bundle storage self,
        uint128 makerAmountRaw
    )
        internal
        returns (uint128 makerAmountOut, uint128 takerAmountOut, uint128 takerFeeAmountOut, uint128 makerAmountTotalNew)
    {
        uint128 makerAmountTotal = self.makerAmountTotal;
        uint128 makerAmountRemaining = self.makerAmountRemaining;
        uint128 takerAmountRemaining = self.takerAmountRemaining;
        uint128 takerFeeAmountRemaining = self.takerFeeAmountRemaining;

        unchecked {
            makerAmountTotalNew = makerAmountTotal - makerAmountRaw;
            self.makerAmountTotal = makerAmountTotalNew;

            // This calculation won't overflow because makerAmountRaw divided by
            // makerAmountTotal will always have a value between 0 and 1 (excluding 0), and
            // multiplying that by a uint128 value won't result in an overflow. So the
            // calculation is designed to work within the constraints of the data types being used,
            // without exceeding their maximum values.
            makerAmountOut = uint128((uint256(makerAmountRaw) * makerAmountRemaining) / makerAmountTotal);
            self.makerAmountRemaining = makerAmountRemaining - makerAmountOut;

            takerAmountOut = uint128((uint256(makerAmountRaw) * takerAmountRemaining) / makerAmountTotal);
            self.takerAmountRemaining = takerAmountRemaining - takerAmountOut;

            takerFeeAmountOut = uint128((uint256(makerAmountRaw) * takerFeeAmountRemaining) / makerAmountTotal);
            self.takerFeeAmountRemaining = takerFeeAmountRemaining - takerFeeAmountOut;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library FixedPointX128 {
    uint160 internal constant RESOLUTION = 1 << 128;
    uint160 internal constant Q = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library FixedPointX192 {
    uint256 internal constant RESOLUTION = 1 << 192;
    uint256 internal constant Q = 0x1000000000000000000000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library FixedPointX96 {
    uint160 internal constant RESOLUTION = 1 << 96;
    uint160 internal constant Q = 0x1000000000000000000000000;
    uint160 internal constant Q_2 = 0x2000000000000000000000000;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./Uint128Math.sol";
import "./FixedPointX96.sol";
import "./FixedPointX192.sol";

library SwapMath {
    using SafeCast for uint256;

    struct ComputeSwapStep {
        /// @dev The price after swapping the amount in/out
        uint160 priceNextX96;
        /// @dev The amount to be swapped in, of either token0 or token1, based on the direction of the swap
        uint256 amountIn;
        /// @dev The amount to be swapped out, of either token0 or token1, based on the direction of the swap
        uint128 amountOut;
        /// @dev The amount of fees paid by the taker
        uint128 feeAmount;
    }

    /// @notice Calculates the result of the swap through the given boundary parameters
    /// @param priceCurrentX96 The current price of the grid, as a Q64.96
    /// @param boundaryPriceX96 It is the upper boundary price when using token1 to exchange for token0.
    /// Otherwise, it is the lower boundary price, as a Q64.96
    /// @param priceLimitX96 The price limit of the swap, as a Q64.96
    /// @param amountRemaining The remaining amount to be swapped in (positive) or swapped out (negative)
    /// @param makerAmount The remaining amount of token0 or token1 that can be swapped out from the makers
    /// @param takerFeePips The taker fee, denominated in hundredths of a bip (i.e. 1e-6)
    /// @return step The result of the swap step
    function computeSwapStep(
        uint160 priceCurrentX96,
        uint160 boundaryPriceX96,
        uint160 priceLimitX96,
        int256 amountRemaining,
        uint128 makerAmount,
        int24 takerFeePips
    ) internal pure returns (ComputeSwapStep memory step) {
        if (amountRemaining > 0) {
            return
                computeSwapStepForExactIn(
                    priceCurrentX96,
                    boundaryPriceX96,
                    priceLimitX96,
                    uint256(amountRemaining),
                    makerAmount,
                    takerFeePips
                );
        } else {
            uint256 absAmountRemaining;
            unchecked {
                absAmountRemaining = uint256(-amountRemaining);
            }
            return
                computeSwapStepForExactOut(
                    priceCurrentX96,
                    boundaryPriceX96,
                    priceLimitX96,
                    // The converted value will not overflow. The maximum amount of liquidity
                    // allowed in each boundary is less than or equal to uint128.
                    absAmountRemaining > makerAmount ? makerAmount : uint128(absAmountRemaining),
                    makerAmount,
                    takerFeePips
                );
        }
    }

    function computeSwapStepForExactIn(
        uint160 priceCurrentX96,
        uint160 boundaryPriceX96,
        uint160 priceLimitX96,
        uint256 takerAmountInRemaining,
        uint128 makerAmount,
        int24 takerFeePips
    ) internal pure returns (ComputeSwapStep memory step) {
        if (!_priceInRange(priceCurrentX96, boundaryPriceX96, priceLimitX96)) {
            return
                _computeSwapStepForExactIn(
                    priceCurrentX96,
                    boundaryPriceX96,
                    takerAmountInRemaining,
                    makerAmount,
                    takerFeePips
                );
        } else {
            step.amountOut = _computeAmountOutForPriceLimit(
                priceCurrentX96,
                boundaryPriceX96,
                priceLimitX96,
                makerAmount
            );

            step = _computeSwapStepForExactOut(
                priceCurrentX96,
                boundaryPriceX96,
                step.amountOut,
                makerAmount,
                takerFeePips
            );
            return
                step.amountIn + step.feeAmount > takerAmountInRemaining // the remaining amount in is not enough to reach the limit price
                    ? _computeSwapStepForExactIn(
                        priceCurrentX96,
                        boundaryPriceX96,
                        takerAmountInRemaining,
                        makerAmount,
                        takerFeePips
                    )
                    : step;
        }
    }

    function _computeSwapStepForExactIn(
        uint160 priceCurrentX96,
        uint160 boundaryPriceX96,
        uint256 takerAmountInRemaining,
        uint128 makerAmount,
        int24 takerFeePips
    ) private pure returns (ComputeSwapStep memory step) {
        bool zeroForOne = priceCurrentX96 >= boundaryPriceX96;

        uint256 takerAmountInWithoutFee = Math.mulDiv(takerAmountInRemaining, 1e6 - uint256(uint24(takerFeePips)), 1e6);

        uint160 priceDeltaX96;
        unchecked {
            priceDeltaX96 = zeroForOne ? priceCurrentX96 - boundaryPriceX96 : boundaryPriceX96 - priceCurrentX96;
        }

        uint256 amountOut;
        if (zeroForOne) {
            // (2 * takerAmountIn * priceCurrent) / (2 - (priceMax - priceCurrent) * takerAmountIn / makerAmount)
            uint256 numerator = 2 * takerAmountInWithoutFee * priceCurrentX96;

            uint256 denominator = Math.mulDiv(
                priceDeltaX96,
                takerAmountInWithoutFee,
                makerAmount,
                Math.Rounding.Up // round up
            );

            amountOut = numerator / (FixedPointX96.Q_2 + denominator);
        } else {
            // ((2 * takerAmountIn * (1/priceCurrent) / (2 - (1/priceMax - 1/priceCurrent) * takerAmountIn / makerAmount))
            // Specifically divide first, then multiply to ensure that the amountOut is smaller
            uint256 numerator = 2 * takerAmountInWithoutFee * (FixedPointX192.Q / priceCurrentX96);

            uint256 reversePriceDeltaX96 = Math.ceilDiv(
                FixedPointX192.Q,
                priceCurrentX96 // round up
            ) - (FixedPointX192.Q / boundaryPriceX96);
            uint256 denominator = Math.mulDiv(
                reversePriceDeltaX96,
                takerAmountInWithoutFee,
                makerAmount,
                Math.Rounding.Up // round up
            );
            amountOut = numerator / (FixedPointX96.Q_2 + denominator);
        }

        if (amountOut > makerAmount) {
            step.priceNextX96 = boundaryPriceX96;
            step.amountOut = makerAmount;
            (step.amountIn, step.feeAmount) = _computeAmountInAndFeeAmount(
                zeroForOne,
                priceCurrentX96,
                boundaryPriceX96,
                makerAmount,
                Math.Rounding.Down,
                takerFeePips
            );
        } else {
            step.amountOut = amountOut.toUint128();
            step.priceNextX96 = _computePriceNextX96(
                zeroForOne,
                priceCurrentX96,
                priceDeltaX96,
                step.amountOut,
                makerAmount
            );
            step.amountIn = takerAmountInWithoutFee;
            unchecked {
                step.feeAmount = (takerAmountInRemaining - takerAmountInWithoutFee).toUint128();
            }
        }
    }

    function computeSwapStepForExactOut(
        uint160 priceCurrentX96,
        uint160 boundaryPriceX96,
        uint160 priceLimitX96,
        uint128 takerAmountOutRemaining,
        uint128 makerAmount,
        int24 takerFeePips
    ) internal pure returns (ComputeSwapStep memory step) {
        // if the limit price is not within the range, it will be calculated directly
        if (!_priceInRange(priceCurrentX96, boundaryPriceX96, priceLimitX96)) {
            return
                _computeSwapStepForExactOut(
                    priceCurrentX96,
                    boundaryPriceX96,
                    takerAmountOutRemaining,
                    makerAmount,
                    takerFeePips
                );
        }

        // otherwise calculate the new takerAmountRemaining value
        uint128 availableAmountOut = _computeAmountOutForPriceLimit(
            priceCurrentX96,
            boundaryPriceX96,
            priceLimitX96,
            makerAmount
        );

        return
            _computeSwapStepForExactOut(
                priceCurrentX96,
                boundaryPriceX96,
                Uint128Math.minUint128(availableAmountOut, takerAmountOutRemaining),
                makerAmount,
                takerFeePips
            );
    }

    /// @dev Checks if the price limit is within the range
    /// @param priceCurrentX96 The current price of the grid, as a Q64.96
    /// @param boundaryPriceX96 It is the upper boundary price when using token1 to exchange for token0.
    /// Otherwise, it is the lower boundary price, as a Q64.96
    /// @param priceLimitX96 The price limit of the swap, as a Q64.96
    /// @return True if the price limit is within the range
    function _priceInRange(
        uint160 priceCurrentX96,
        uint160 boundaryPriceX96,
        uint160 priceLimitX96
    ) private pure returns (bool) {
        return
            priceCurrentX96 >= boundaryPriceX96
                ? (priceLimitX96 > boundaryPriceX96 && priceLimitX96 <= priceCurrentX96)
                : (priceLimitX96 >= priceCurrentX96 && priceLimitX96 < boundaryPriceX96);
    }

    function _computeSwapStepForExactOut(
        uint160 priceCurrentX96,
        uint160 boundaryPriceX96,
        uint128 takerAmountOutRemaining,
        uint128 makerAmount,
        int24 takerFeePips
    ) private pure returns (ComputeSwapStep memory step) {
        bool zeroForOne = priceCurrentX96 >= boundaryPriceX96;

        uint160 priceDeltaX96;
        Math.Rounding priceNextRounding;
        unchecked {
            (priceDeltaX96, priceNextRounding) = zeroForOne
                ? (priceCurrentX96 - boundaryPriceX96, Math.Rounding.Down)
                : (boundaryPriceX96 - priceCurrentX96, Math.Rounding.Up);
        }

        step.priceNextX96 = _computePriceNextX96(
            zeroForOne,
            priceCurrentX96,
            priceDeltaX96,
            takerAmountOutRemaining,
            makerAmount
        );

        (step.amountIn, step.feeAmount) = _computeAmountInAndFeeAmount(
            zeroForOne,
            priceCurrentX96,
            step.priceNextX96,
            takerAmountOutRemaining,
            priceNextRounding,
            takerFeePips
        );
        step.amountOut = takerAmountOutRemaining;
    }

    function _computePriceNextX96(
        bool zeroForOne,
        uint160 priceCurrentX96,
        uint160 priceDeltaX96,
        uint160 takerAmountOut,
        uint128 makerAmount
    ) private pure returns (uint160) {
        uint256 priceDeltaX96WithRate = Math.mulDiv(priceDeltaX96, takerAmountOut, makerAmount, Math.Rounding.Up);
        unchecked {
            return
                zeroForOne
                    ? (priceCurrentX96 - priceDeltaX96WithRate).toUint160()
                    : (priceCurrentX96 + priceDeltaX96WithRate).toUint160();
        }
    }

    function _computeAmountInAndFeeAmount(
        bool zeroForOne,
        uint160 priceCurrentX96,
        uint160 priceNextX96,
        uint128 amountOut,
        Math.Rounding priceNextRounding,
        int24 takerFeePips
    ) private pure returns (uint256 amountIn, uint128 feeAmount) {
        uint160 priceAvgX96;
        unchecked {
            uint256 priceAccumulateX96 = uint256(priceCurrentX96) + priceNextX96;
            priceAccumulateX96 = priceNextRounding == Math.Rounding.Up ? priceAccumulateX96 + 1 : priceAccumulateX96;
            priceAvgX96 = uint160(priceAccumulateX96 >> 1);
        }

        amountIn = zeroForOne
            ? Math.mulDiv(amountOut, FixedPointX96.Q, priceAvgX96, Math.Rounding.Up)
            : Math.mulDiv(priceAvgX96, amountOut, FixedPointX96.Q, Math.Rounding.Up);

        // feeAmount = amountIn * takerFeePips / (1e6 - takerFeePips)
        feeAmount = Math
            .mulDiv(uint24(takerFeePips), amountIn, 1e6 - uint24(takerFeePips), Math.Rounding.Up)
            .toUint128();
    }

    function _computeAmountOutForPriceLimit(
        uint160 priceCurrentX96,
        uint160 boundaryPriceX96,
        uint160 priceLimitX96,
        uint128 makerAmount
    ) private pure returns (uint128 availableAmountOut) {
        uint160 priceLimitDeltaX96;
        uint160 priceMaxDeltaX96;
        unchecked {
            (priceLimitDeltaX96, priceMaxDeltaX96) = priceLimitX96 >= priceCurrentX96
                ? (priceLimitX96 - priceCurrentX96, boundaryPriceX96 - priceCurrentX96)
                : (priceCurrentX96 - priceLimitX96, priceCurrentX96 - boundaryPriceX96);
        }

        uint256 tempX96 = _divUpForPriceX96(priceLimitDeltaX96, priceMaxDeltaX96);
        availableAmountOut = Math.mulDiv(tempX96, makerAmount, FixedPointX96.Q, Math.Rounding.Up).toUint128();
    }

    function _divUpForPriceX96(uint160 aX96, uint160 bX96) private pure returns (uint256) {
        if (aX96 == 0) {
            return 0;
        }
        unchecked {
            // never overflows
            uint256 tempX96 = uint256(aX96) * FixedPointX96.Q;
            // (a + b - 1) / b can overflow on addition, so we distribute
            return (tempX96 - 1) / bX96 + 1;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library Uint128Math {
    /// @dev Returns the minimum of the two values
    /// @param a The first value
    /// @param b The second value
    /// @return min The minimum of the two values
    function minUint128(uint128 a, uint128 b) internal pure returns (uint128 min) {
        return a < b ? a : b;
    }

    /// @dev Returns the maximum of the two values
    /// @param a The first value
    /// @param b The second value
    /// @return max The maximum of the two values
    function maxUint128(uint128 a, uint128 b) internal pure returns (uint128 max) {
        return a > b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library Uint160Math {
    /// @dev Returns the minimum of the two values
    /// @param a The first value
    /// @param b The second value
    /// @return min The minimum of the two values
    function minUint160(uint160 a, uint160 b) internal pure returns (uint160 min) {
        return a < b ? a : b;
    }

    /// @dev Returns the maximum of the two values
    /// @param a The first value
    /// @param b The second value
    /// @return max The maximum of the two values
    function maxUint160(uint160 a, uint160 b) internal pure returns (uint160 max) {
        return a > b ? a : b;
    }
}