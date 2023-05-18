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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import { IERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IPool } from "./interfaces/IPool.sol";

contract Pool is IPool {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // Mapping from higher to lower
    // By convention, _nextPriceLevels[0] is the highest bid;
    // For every price P, _nextPriceLevels[P] is the highest active price smaller than P
    mapping(uint256 => uint256) internal _nextPriceLevels;

    address public immutable factory;
    // Makers provide underlying and get accounting after match
    // Takers sell accounting and get underlying immediately
    IERC20 public immutable accounting;
    IERC20 public immutable underlying;
    // the accounting token decimals (stored to save gas)
    uint256 public immutable priceResolution;
    // maximum price to prevent overflow (computed at construction to save gas)
    uint256 public immutable maximumPrice;
    // maximum amount to prevent overflow (computed at construction to save gas)
    uint256 public immutable maximumAmount;

    // The minimum spacing percentage between prices, 1e4 corresponding to 100%
    // lower values allow for a more fluid price but frontrunning is exacerbated and staking less useful
    // higher values make token staking useful and frontrunning exploit less feasible
    // but makers must choose between more stringent bids
    // lower values are indicated for stable pairs
    // higher vlaues are indicated for more volatile pairs
    uint16 public immutable tick;

    // id of the order to access its data, by price
    mapping(uint256 => uint256) public id;
    // orders[price][id]
    mapping(uint256 => mapping(uint256 => Order)) internal _orders;

    event OrderCreated(
        address indexed offerer,
        uint256 price,
        uint256 indexed index,
        uint256 underlyingAmount,
        uint256 staked,
        uint256 previous,
        uint256 next
    );
    event OrderFulfilled(
        uint256 indexed id,
        address indexed offerer,
        address indexed fulfiller,
        uint256 amount,
        uint256 price,
        bool totalFill
    );

    event OrderCancelled(uint256 indexed id, address indexed offerer, uint256 price, uint256 underlyingToTransfer);

    error RestrictedToOwner();
    error NullAmount();
    error WrongIndex();
    error PriceTooHigh();
    error AmountTooHigh();
    error StaleOrder();
    error ReceivedTooLow();
    error PaidTooHigh();

    constructor(address _underlying, address _accounting, uint16 _tick) {
        factory = msg.sender;
        accounting = IERC20(_accounting);
        priceResolution = 10**IERC20Metadata(_accounting).decimals();
        underlying = IERC20(_underlying);
        tick = _tick;
        maximumPrice = type(uint256).max / (10000 + tick);
        maximumAmount = type(uint256).max / priceResolution;
    }

    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert StaleOrder();
        _;
    }

    // Example WETH / USDC, maker USDC, taker WETH
    // priceResolution = 1e18 (decimals of WETH)
    // Price = 1753.54 WETH/USDC -> 1753540000 (it has USDC decimals)
    // Sell 2.3486 WETH -> accountingAmount = 2348600000000000000
    // underlyingOut = 2348600000000000000 * 1753540000 / 1e18 = 4118364044 -> 4,118.364044 USDC
    function convertToUnderlying(uint256 accountingAmount, uint256 price) public view returns (uint256) {
        return accountingAmount.mulDiv(price, priceResolution, Math.Rounding.Down);
    }

    function convertToAccounting(uint256 underlyingAmount, uint256 price) public view returns (uint256) {
        return underlyingAmount.mulDiv(priceResolution, price, Math.Rounding.Up);
    }

    function getOrder(uint256 price, uint256 index) public view returns (Order memory) {
        return _orders[price][index];
    }

    function getNextPriceLevel(uint256 price) public view returns (uint256) {
        return _nextPriceLevels[price];
    }

    function _checkMidSpacing(uint256 lower, uint256 higher) internal view returns (bool) {
        return lower == 0 || higher >= lower.mulDiv(tick + 20000, 20000, Math.Rounding.Up);
    }

    function _checkExtSpacing(uint256 lower, uint256 higher) internal view returns (bool) {
        return lower == 0 || higher >= lower.mulDiv(tick + 10000, 10000, Math.Rounding.Up);
    }

    function _addNode(uint256 price, uint256 amount, uint256 staked, address maker, address recipient)
        internal
        returns (uint256, uint256, uint256)
    {
        uint256 higherPrice = 0;
        while (_nextPriceLevels[higherPrice] > price) {
            higherPrice = _nextPriceLevels[higherPrice];
        }

        if (_nextPriceLevels[higherPrice] < price) {
            bool updatePrices = true;
            // If price is the highest so far and too close to the previous highest
            // round it up to the smallest available tick
            if (!_checkExtSpacing(_nextPriceLevels[higherPrice], price) && higherPrice == 0) {
                price = _nextPriceLevels[higherPrice].mulDiv(tick + 10000, 10000, Math.Rounding.Up);
            }
            // If price is the lowest so far and too close to the previous lowest
            // round it up to the previous lowest
            if (!_checkExtSpacing(price, higherPrice) && _nextPriceLevels[higherPrice] == 0 && higherPrice != 0) {
                price = higherPrice;
                updatePrices = false;
            }
            // If price is in the middle of two price levels and does not respect tick spacing
            // we approximate it with the nearest one, with priority upwards
            if (
                (!_checkMidSpacing(_nextPriceLevels[higherPrice], price) || !_checkMidSpacing(price, higherPrice)) &&
                _nextPriceLevels[higherPrice] != 0 &&
                higherPrice != 0
            ) {
                price = price - _nextPriceLevels[higherPrice] < higherPrice - price
                    ? _nextPriceLevels[higherPrice]
                    : higherPrice;
                updatePrices = false;
            }

            // In case updatePrices = false we have fallen into already existing price levels
            // therefore we only need to update prices if the flag is true
            if (updatePrices) {
                _nextPriceLevels[price] = _nextPriceLevels[higherPrice];
                _nextPriceLevels[higherPrice] = price;
            }
        }

        // The "next" index of the last order is 0
        id[price]++;
        uint256 previous = 0;
        uint256 next = _orders[price][0].next;

        // Get the latest position such that staked <= orders[price][previous].staked
        while (staked <= _orders[price][next].staked && next != 0) {
            previous = next;
            next = _orders[price][next].next;
        }
        _orders[price][id[price]] = Order(maker, recipient, amount, staked, previous, next);
        // The "next" index of the previous node is now id[price] (already bumped by 1)
        _orders[price][previous].next = id[price];
        // The "previous" index of the 0 node is now id[price]
        _orders[price][next].previous = id[price];
        return (price, previous, next);
    }

    function _deleteNode(uint256 price, uint256 index) internal {
        // Zero index cannot be deleted
        assert(index != 0);
        Order memory toDelete = _orders[price][index];
        // If the offerer is zero, the order was already canceled or fulfilled
        if (toDelete.offerer == address(0)) revert WrongIndex();

        _orders[price][toDelete.previous].next = toDelete.next;
        _orders[price][toDelete.next].previous = toDelete.previous;

        delete _orders[price][index];
    }

    // Add a node to the list
    function createOrder(uint256 amount, uint256 price, address recipient, uint256 deadline)
        external
        payable
        checkDeadline(deadline)
    {
        if (amount == 0 || price == 0) revert NullAmount();
        if (price > maximumPrice) revert PriceTooHigh();
        if (amount > maximumAmount) revert AmountTooHigh();
        underlying.safeTransferFrom(msg.sender, address(this), amount);
        uint256 previous;
        uint256 next;
        (price, previous, next) = _addNode(price, amount, msg.value, msg.sender, recipient);

        emit OrderCreated(msg.sender, price, id[price], amount, msg.value, previous, next);
    }

    function cancelOrder(uint256 index, uint256 price) external override {
        Order memory order = _orders[price][index];
        if (order.offerer != msg.sender) revert RestrictedToOwner();

        _deleteNode(price, index);
        // If the order is the only one of the priceLevel, update price levels
        if (_orders[price][0].next == 0) {
            uint256 higherPrice = 0;
            while (_nextPriceLevels[higherPrice] > price) higherPrice = _nextPriceLevels[higherPrice];
            _nextPriceLevels[higherPrice] = _nextPriceLevels[price];
            delete _nextPriceLevels[price];
        }

        underlying.safeTransfer(msg.sender, order.underlyingAmount);

        if (order.staked > 0) {
            (bool success, ) = msg.sender.call{ value: order.staked }("");
            assert(success);
        }

        emit OrderCancelled(index, order.offerer, price, order.underlyingAmount);
    }

    // amount is always of underlying currency
    function fulfillOrder(uint256 amount, address receiver, uint256 minReceived, uint256 maxPaid, uint256 deadline)
        external
        checkDeadline(deadline)
        returns (uint256, uint256)
    {
        uint256 accountingToPay = 0;
        uint256 totalStake = 0;
        uint256 initialAmount = amount;
        while (amount > 0 && _nextPriceLevels[0] != 0) {
            (uint256 payStep, uint256 underlyingReceived, uint256 stakeStep, uint256 iterator) = _fulfillOrderByPrice(
                amount,
                _nextPriceLevels[0]
            );
            // underlyingReceived <= amount
            unchecked {
                amount -= underlyingReceived;
            }
            accountingToPay += payStep;
            totalStake += stakeStep;
            if (iterator == 0) {
                uint256 priceToDelete = _nextPriceLevels[0];
                _nextPriceLevels[0] = _nextPriceLevels[priceToDelete];
                delete _nextPriceLevels[priceToDelete];
            }
        }

        if (initialAmount - amount < minReceived) revert ReceivedTooLow();
        if (accountingToPay > maxPaid) revert PaidTooHigh();

        if (totalStake > 0) {
            // slither-disable-next-line arbitrary-send-eth
            (bool success, ) = factory.call{ value: totalStake }("");
            assert(success);
        }

        underlying.safeTransfer(receiver, initialAmount - amount);

        return (accountingToPay, initialAmount - amount);
    }

    // amount is always of underlying currency
    function _fulfillOrderByPrice(uint256 amount, uint256 price) internal returns (uint256, uint256, uint256, uint256) {
        uint256 iterator = _orders[price][0].next;
        if (iterator == 0) return (0, 0, 0, 0);
        Order memory order = _orders[price][iterator];

        uint256 totalStake = 0;
        uint256 accountingToTransfer = 0;
        uint256 initialAmount = amount;

        while (amount >= order.underlyingAmount) {
            _deleteNode(price, iterator);
            amount -= order.underlyingAmount;
            // Wrap toTransfer variable to avoid a stack too deep
            {
                uint256 toTransfer = convertToAccounting(order.underlyingAmount, price);
                accounting.safeTransferFrom(msg.sender, order.recipient, toTransfer);
                accountingToTransfer += toTransfer;
                totalStake += order.staked;
            }

            emit OrderFulfilled(iterator, order.offerer, msg.sender, order.underlyingAmount, price, true);
            iterator = order.next;
            // in case the next is zero, we reached the end of all orders
            if (iterator == 0) break;
            order = _orders[price][iterator];
        }

        if (amount > 0 && iterator != 0) {
            _orders[price][iterator].underlyingAmount -= amount;
            // Wrap toTransfer variable to avoid a stack too deep
            {
                uint256 toTransfer = convertToAccounting(amount, price);
                accounting.safeTransferFrom(msg.sender, order.recipient, toTransfer);
                accountingToTransfer += toTransfer;
            }

            emit OrderFulfilled(iterator, order.offerer, msg.sender, amount, price, false);
            amount = 0;
        }

        return (accountingToTransfer, initialAmount - amount, totalStake, iterator);
    }

    // Check in which position a new order would be, given the staked amount and price
    function previewOrder(uint256 price, uint256 staked)
        public
        view
        returns (uint256 prev, uint256 next, uint256 position, uint256 cumulativeUndAmount, uint256 actualPrice)
    {
        actualPrice = price;
        uint256 higherPrice = 0;
        while (_nextPriceLevels[higherPrice] > price) {
            higherPrice = _nextPriceLevels[higherPrice];
        }

        if (_nextPriceLevels[higherPrice] < price) {
            // If price is the highest so far and too close to the previous highest
            // round it up to the smallest available tick
            if (!_checkExtSpacing(_nextPriceLevels[higherPrice], price) && higherPrice == 0) {
                actualPrice = _nextPriceLevels[higherPrice].mulDiv(tick + 10000, 10000, Math.Rounding.Up);
            }
            // If price is the lowest so far and too close to the previous lowest
            // round it up to the previous lowest
            if (!_checkExtSpacing(price, higherPrice) && _nextPriceLevels[higherPrice] == 0 && higherPrice != 0) {
                actualPrice = higherPrice;
            }

            // If price is in the middle of two price levels and does not respect tick spacing
            // we approximate it with the nearest one, with priority upwards
            if (
                (!_checkMidSpacing(_nextPriceLevels[higherPrice], price) || !_checkMidSpacing(price, higherPrice)) &&
                _nextPriceLevels[higherPrice] != 0 &&
                higherPrice != 0
            ) {
                actualPrice = price - _nextPriceLevels[higherPrice] < higherPrice - price
                    ? _nextPriceLevels[higherPrice]
                    : higherPrice;
            }
        }

        next = _orders[actualPrice][0].next;

        while (staked <= _orders[actualPrice][next].staked && next != 0) {
            cumulativeUndAmount += _orders[actualPrice][next].underlyingAmount;
            position++;
            prev = next;
            next = _orders[actualPrice][next].next;
        }
    }

    // amount is always of underlying currency
    function previewTake(uint256 amount) external view returns (uint256, uint256) {
        uint256 accountingToPay = 0;
        uint256 initialAmount = amount;
        uint256 price = _nextPriceLevels[0];
        while (amount > 0 && price != 0) {
            (uint256 payStep, uint256 underlyingReceived) = previewTakeByPrice(amount, price);
            // underlyingPaid <= amount
            unchecked {
                amount -= underlyingReceived;
            }
            accountingToPay += payStep;
            if (amount > 0) price = _nextPriceLevels[price];
        }

        return (accountingToPay, initialAmount - amount);
    }

    // View function to calculate how much accounting the taker needs to take amount
    function previewTakeByPrice(uint256 amount, uint256 price) internal view returns (uint256, uint256) {
        uint256 iterator = _orders[price][0].next;
        if (iterator == 0) return (0, 0);
        Order memory order = _orders[price][iterator];

        uint256 accountingToTransfer = 0;
        uint256 initialAmount = amount;
        while (amount >= order.underlyingAmount) {
            uint256 toTransfer = convertToAccounting(order.underlyingAmount, price);
            accountingToTransfer += toTransfer;
            amount -= order.underlyingAmount;
            iterator = order.next;
            // in case the next is zero, we reached the end of all orders
            if (iterator == 0) break;
            order = _orders[price][iterator];
        }

        if (amount > 0 && iterator != 0) {
            uint256 toTransfer = convertToAccounting(amount, price);
            accountingToTransfer += toTransfer;
            amount = 0;
        }

        return (accountingToTransfer, initialAmount - amount);
    }

    // View function to calculate how much accounting and underlying a redeem would return
    function previewRedeem(uint256 index, uint256 price) external view returns (uint256) {
        return _orders[price][index].underlyingAmount;
    }

    function volumes(uint256 startPrice, uint256 minPrice, uint256 maxLength) external view returns (Volume[] memory) {
        Volume[] memory volumeArray = new Volume[](maxLength);
        uint256 price = _nextPriceLevels[startPrice];
        uint256 index = 0;
        while (price >= minPrice && price != 0 && index < maxLength) {
            Volume memory volume = Volume(price, volumeByPrice(price));
            volumeArray[index] = volume;
            price = _nextPriceLevels[price];
            index++;
        }

        return volumeArray;
    }

    function volumeByPrice(uint256 price) internal view returns (uint256) {
        uint256 iterator = _orders[price][0].next;
        if (iterator == 0) return 0;
        Order memory order = _orders[price][iterator];

        uint256 volume = 0;
        while (iterator != 0) {
            volume += order.underlyingAmount;
            iterator = order.next;
            order = _orders[price][iterator];
        }

        return volume;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IPool {
    // We model makers as a circular doubly linked list with zero as first and last element
    // This facilitates insertion and deletion of orders making the process gas efficient
    struct Order {
        address offerer;
        address recipient;
        uint256 underlyingAmount;
        uint256 staked;
        uint256 previous;
        uint256 next;
    }

    // Structure to fetch prices and volumes, only used in view functions
    struct Volume {
        uint256 price;
        uint256 volume;
    }

    function createOrder(uint256 amount, uint256 price, address recipient, uint256 deadline) external payable;

    function cancelOrder(uint256 index, uint256 price) external;

    function fulfillOrder(uint256 amount, address receiver, uint256 minReceived, uint256 maxPaid, uint256 deadline)
        external
        returns (uint256, uint256);
}