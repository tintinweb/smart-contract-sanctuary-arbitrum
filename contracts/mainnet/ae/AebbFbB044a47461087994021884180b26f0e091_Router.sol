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
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title OrderFillCallback interface
/// @notice Callback for updating token balances
interface IBalanceChangeCallback {
    /// @notice Transfer tokens from the contract to the user
    /// @param tokenToTransfer The token to transfer
    /// @param to The user to transfer to
    /// @param amount The amount to transfer
    /// @param orderBookId Id of caller the order book
    function addBalanceCallback(
        IERC20Metadata tokenToTransfer,
        address to,
        uint256 amount,
        uint8 orderBookId
    ) external;

    /// @notice Transfer tokens from the user to the contract
    /// @param tokenToTransferFrom The token to transfer from
    /// @param from The user to transfer from
    /// @param amount The amount to transfer
    /// @param orderBookId Id of caller the order book
    function subtractBalanceCallback(
        IERC20Metadata tokenToTransferFrom,
        address from,
        uint256 amount,
        uint8 orderBookId
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Factory Interface
/// @notice The Factory facilitates creation of order books
interface IFactory {
    /// @notice Event emitted when an order book is created
    /// @param orderBookId The id of the order book
    /// @param orderBookAddress The address of the created orderBook
    /// @param token0 The base token of the orderBook
    /// @param token1 The quote token of the orderBook
    /// @param logSizeTick Log10 of base token tick
    /// amount0 % 10**logSizeTick = 0 should be satisfied
    /// @param logPriceTick Log10 of price tick amount1 * dec0 % amount = 0
    /// and amount1 * dec0 / amount0 % 10**logPriceTick = 0 should be satisfied
    event OrderBookCreated(
        uint8 orderBookId,
        address orderBookAddress,
        address token0,
        address token1,
        uint8 logSizeTick,
        uint8 logPriceTick
    );

    /// @notice Event emitted when the owner is changed
    /// @param owner Address of the new owner
    event OwnerChanged(address owner);

    /// @notice Returns the current owner of the factory
    /// @return owner The address of the factory owner
    function owner() external view returns (address);

    /// @notice Set the router address for the factory. The router address
    /// can only be set once
    /// @param routerAddress The address of the router
    function setRouter(address routerAddress) external;

    /// @notice Set the owner of the factory
    /// @param _owner The address of the new owner
    function setOwner(address _owner) external;

    /// @notice Returns the address of the order book for a given token pair,
    /// or address 0 if it does not exist
    /// @dev token0 and token1 may be passed in either order
    /// @param token0 The contract address the first token
    /// @param token1 The contract address the second token
    /// @return orderBookAddress The address of the order book
    function getOrderBookFromTokenPair(address token0, address token1)
        external
        view
        returns (address);

    /// @notice Returns the address of the order book for the given order book id
    /// @param orderBookId The id of the order book to lookup
    /// @return orderBookAddress The address of the order book
    function getOrderBookFromId(uint8 orderBookId)
        external
        view
        returns (address);

    /// @notice Returns the details of the order book for a given token pair
    /// @param token0 The first token of the order book
    /// @param token1 The second token of the order book
    /// @return orderBookId The id of the order book
    /// @return orderBookAddress The address of the order book
    /// @return token0 The base token of the order book
    /// @return token1 The quote token of the order book
    /// @return sizeTick The size tick of the order book
    /// @return priceTick The price tick of the order book
    function getOrderBookDetailsFromTokenPair(address token0, address token1)
        external
        view
        returns (
            uint8,
            address,
            address,
            address,
            uint128,
            uint128
        );

    /// @notice Returns the details of the order book for a given order book id
    /// @param orderBookId The id of the order book to lookup
    /// @return orderBookId The id of the order book
    /// @return orderBookAddress The address of the order book
    /// @return token0 The base token of the order book
    /// @return token1 The quote token of the order book
    /// @return sizeTick The size tick of the order book
    /// @return priceTick The price tick of the order book
    function getOrderBookDetailsFromId(uint8 orderBookId)
        external
        view
        returns (
            uint8,
            address,
            address,
            address,
            uint128,
            uint128
        );

    /// @notice Creates a orderBook for the given two tokens
    /// @dev token0 and token1 may be passed in either order
    /// @param token0 The contract address the first token
    /// @param token1 The contract address the second token
    /// @param logSizeTick Log10 of base token tick
    /// amount0 % 10**logSizeTick = 0 should be satisfied
    /// @param logPriceTick Log10 of price tick amount1 * dec0 % amount = 0
    /// and amount1 * dec0 / amount0 % 10**logPriceTick = 0 should be satisfied
    /// @return orderBookAddress The address of the newly created orderBook
    function createOrderBook(
        address token0,
        address token1,
        uint8 logSizeTick,
        uint8 logPriceTick
    ) external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../library/LinkedList.sol";

/// @title Order Book Interface
/// @notice An order book facilitates placing limit and market orders to trade
/// two assets which conform to the ERC20 specification. token0 is the asset
/// traded in the order book, and token1 is the asset paid/received for trading
/// token0
interface IOrderBook {
    /// @notice Create a limit order in the order book. The order will be
    /// filled by existing orders if there is a price overlap. If the order
    /// is not fully filled, it will be added to the order book
    /// @param amount0Base The amount of token0 in the limit order in terms
    /// of number of sizeTicks. The actual amount of token0 in the order will
    /// be amount0Base * sizeTick.
    /// @param priceBase The price of the token0 in terms of token1 and size
    /// and price ticks. The actual amount of token1 in the order will be
    /// priceBase * amount0Base * priceTick * sizeTick / dec0
    /// @param isAsk Whether the order is an ask order. isAsk = true means
    /// the order sells token0 for token1
    /// @param from The address of the order sender
    /// @param hintId Where to insert the order in the order book. Meant to
    /// be calculated off-chain using the getMockIndexToInsert function
    /// @return id The id of the order
    function createLimitOrder(
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        address from,
        uint32 hintId
    ) external returns (uint32);

    /// @notice Cancel an existing limit order in the order book. Refunds the
    /// remaining tokens in the order to the owner
    /// @param id The id of the order to cancel
    /// @param from The address of the order sender
    /// @return isCanceled Whether the order was successfully canceled
    function cancelLimitOrder(uint32 id, address from) external returns (bool);

    /// @notice Create a market order in the order book. The order will be
    /// filled by existing orders if there is a price overlap. If the order
    /// is not fully filled, it will NOT be added to the order book
    /// @param amount0Base The amount of token0 in the limit order in terms
    /// of number of sizeTicks. The actual amount of token0 in the order will
    /// be amount0Base * sizeTick
    /// @param priceBase The price of the token0 in terms of token1 and size
    /// and price ticks. The actual amount of token1 in the order will be
    /// priceBase * amount0Base * priceTick * sizeTick / dec0
    /// @param isAsk Whether the order is an ask order. isAsk = true means
    /// the order sells token0 for token1
    /// @param from The address of the order sender
    function createMarketOrder(
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        address from
    ) external;

    /// @notice Get the order details of all limit orders in the order book.
    /// Each returned list contains the details of ask orders first, followed
    /// by bid orders
    /// @return id The ids of the orders
    /// @return owner The addresses of the orders' owners
    /// @return amount0 The amount of token0 remaining in the orders
    /// @return amount1 The amount of token1 remaining in the orders
    /// @return isAsk Whether each order is an ask order
    function getLimitOrders()
        external
        view
        returns (
            uint32[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory
        );

    /// @notice Get the order details of the ask order with the lowest price
    /// in the order book
    /// @return bestAsk LimitOrder data struct of the best ask order
    function getBestAsk() external view returns (LimitOrder memory);

    /// @notice Get the order details of the bid order with the highest price
    /// in the order book
    /// @return bestBid LimitOrder data struct of the best bid order
    function getBestBid() external view returns (LimitOrder memory);

    /// @notice Return whether an order is active
    /// @param id The id of the order
    /// @return isActive True if the order is active, false otherwise
    function isOrderActive(uint32 id) external view returns (bool);

    /// @notice Return whether an order is an ask order or not, fails if order is not active
    /// @param id The id of the order
    /// @return isActive True if the order is an ask order, false otherwise
    function isAskOrder(uint32 id) external view returns (bool);

    /// @notice Find the order id to the left of where the new order
    /// should be inserted. Meant to be used off-chain to find the
    /// hintId for the createLimitOrder functions
    /// @param amount0 The amount of token0 in the new order
    /// @param amount1 The amount of token1 in the new order
    /// @param isAsk Whether the new order is an ask order
    /// @return hintId The id of the order to the left of where the new order
    /// should be inserted
    function getMockIndexToInsert(
        uint256 amount0,
        uint256 amount1,
        bool isAsk
    ) external view returns (uint32);

    /// @notice Id of the order book
    /// @return orderBookId The unique identifier of an order book
    function orderBookId() external view returns (uint8);

    /// @notice The base token
    /// @return token0 The base token contract
    function token0() external view returns (IERC20Metadata);

    /// @notice The quote token
    /// @return token1 The quote token contract
    function token1() external view returns (IERC20Metadata);

    /// @notice The sizeTick of the order book
    /// @return sizeTick The sizeTick of the order book
    function sizeTick() external view returns (uint128);

    /// @notice The priceTick of the order book
    /// @return priceTick The priceTick of the order book
    function priceTick() external view returns (uint128);

    /// @notice The priceMultiplier of the order book
    /// @return priceMultiplier The priceMultiplier of the order book
    function priceMultiplier() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";

library FullMath {
    /// @notice Returns a*b/denominator, throws if remainder is not 0
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        require(denominator != 0, "Can not divide with 0");
        uint256 remainder = 0;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        require(remainder == 0, "Divison has a positive remainder");
        return Math.mulDiv(a, b, denominator);
    }

    /// @notice Returns true if a*b < c*d
    function mulCompare(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) internal pure returns (bool result) {
        uint256 prod0; // Least significant 256 bits of the product a*b
        uint256 prod1; // Most significant 256 bits of the product a*b
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        uint256 prod2; // Least significant 256 bits of the product c*d
        uint256 prod3; // Most significant 256 bits of the product c*d
        assembly {
            let mm := mulmod(c, d, not(0))
            prod2 := mul(c, d)
            prod3 := sub(sub(mm, prod2), lt(mm, prod2))
        }

        if (prod1 < prod3) return true;
        if (prod3 < prod1) return false;
        if (prod0 < prod2) return true;
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./FullMath.sol";

/// @notice Struct containing limit order data
struct LimitOrder {
    uint32 id;
    address owner;
    uint256 amount0;
    uint256 amount1;
}

/// @notice Struct for linked list node
/// @dev Each order id is mapped to a Node in the linked list
struct Node {
    uint32 prev;
    uint32 next;
    bool active;
}

/// @notice Struct for linked list sorted by price in non-decreasing order.
/// Used to store ask limit orders in the order book.
/// @dev Each order id is mapped to a Node and a LimitOrder
struct MinLinkedList {
    mapping(uint32 => Node) list;
    mapping(uint32 => LimitOrder) idToLimitOrder;
}

/// @notice Struct for linked list sorted in non-increasing order
/// Used to store bid limit orders in the order book.
/// @dev Each order id is mapped to a Node and a Limit Order
struct MaxLinkedList {
    mapping(uint32 => Node) list;
    mapping(uint32 => LimitOrder) idToLimitOrder;
}

/// @title MinLinkedListLib
/// @notice Library for linked list sorted in non-decreasing order
/// @dev Order ids 0 and 1 are special values. The first node of the
/// linked list has order id 0 and the last node has order id 1.
/// Order 0 should be initalized (in OrderBook.sol) with the lowest
/// possible price, and order 1 should be initialized with the highest
library MinLinkedListLib {
    /// @notice Comparison function for linked list. Returns true
    /// if the price of order id0 is strictly less than the price of order id1
    function compare(
        MinLinkedList storage listData,
        uint32 id0,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                listData.idToLimitOrder[id0].amount1,
                listData.idToLimitOrder[id1].amount0,
                listData.idToLimitOrder[id1].amount1,
                listData.idToLimitOrder[id0].amount0
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted
    /// @param orderId The order id to insert
    /// @param hintId The order id to start searching from
    function findIndexToInsert(
        MinLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) internal view returns (uint32) {
        // No element in the linked list can have next = 0, it means hintId is not in the linked list
        require(listData.list[hintId].next != 0, "Invalid hint id");

        while (!listData.list[hintId].active) {
            hintId = listData.list[hintId].next;
        }

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.
        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (compare(listData, orderId, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!compare(listData, orderId, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }

    /// @notice Inserts an order id into the linked list in sorted order
    /// @param orderId The order id to insert
    /// @param hintId The order id to begin searching for the position to
    /// insert the new order. Can be 0, 1, or the id of an actual order
    function insert(
        MinLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) public {
        uint32 indexToInsert = findIndexToInsert(listData, orderId, hintId);

        uint32 next = listData.list[indexToInsert].next;
        listData.list[orderId] = Node({
            prev: indexToInsert,
            next: next,
            active: true
        });
        listData.list[indexToInsert].next = orderId;
        listData.list[next].prev = orderId;
    }

    /// @notice Remove an order id from the linked list
    /// @dev Updates the linked list but does not delete the order id from
    /// the idToLimitOrder mapping
    /// @param orderId The order id to remove
    function erase(MinLinkedList storage listData, uint32 orderId) public {
        require(orderId > 1, "Cannot erase dummy orders");
        require(
            listData.list[orderId].active,
            "Cannot cancel an already inactive order"
        );

        uint32 prev = listData.list[orderId].prev;
        uint32 next = listData.list[orderId].next;

        listData.list[prev].next = next;
        listData.list[next].prev = prev;
        listData.list[orderId].active = false;
    }

    /// @notice Get the first order id in the linked list. Since the linked
    /// list is sorted, this gets the order id with the lowest price, if all
    /// the orders are dummy orders, returns 1
    /// @dev Order id 0 is a dummy value and should not be returned
    function getFirstNode(MinLinkedList storage listData)
        internal
        view
        returns (uint32)
    {
        return listData.list[0].next;
    }

    /// @notice Get the LimitOrder data struct for the first order
    function getTopLimitOrder(MinLinkedList storage listData)
        public
        view
        returns (LimitOrder storage)
    {
        require(!isEmpty(listData), "Book side is empty");
        return listData.idToLimitOrder[getFirstNode(listData)];
    }

    /// @notice Returns true if the linked list has no orders
    /// @dev Order id 0 and 1 are dummy values, so the linked list
    /// is empty if those are the only two orders
    function isEmpty(MinLinkedList storage listData)
        public
        view
        returns (bool)
    {
        return getFirstNode(listData) == 1;
    }

    /// @notice Returns the number of orders in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the number of
    /// orders does not include them
    function size(MinLinkedList storage listData) public view returns (uint32) {
        uint32 listSize = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) ++listSize;
        return listSize;
    }

    /// @notice Returns a list of LimitOrder data structs for each
    /// order in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the returned list
    /// does not include them
    function getOrders(MinLinkedList storage listData)
        public
        view
        returns (LimitOrder[] memory orders)
    {
        orders = new LimitOrder[](size(listData));
        uint32 i = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) {
            orders[i] = listData.idToLimitOrder[pointer];
            ++i;
        }
    }

    /// @notice Comparison function for linked list. Returns true if the
    /// price of amount0 to amount1 is less than the price of order id1
    function mockCompare(
        MinLinkedList storage listData,
        uint256 amount0,
        uint256 amount1,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                amount1,
                listData.idToLimitOrder[id1].amount0,
                listData.idToLimitOrder[id1].amount1,
                amount0
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted. Meant to be used off-chain to find the
    /// hintId for the insert function
    /// @param amount0 The amount of token0 in the new order
    /// @param amount1 The amount of token1 in the new order
    function getMockIndexToInsert(
        MinLinkedList storage listData,
        uint256 amount0,
        uint256 amount1
    ) public view returns (uint32) {
        uint32 hintId = 0;

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.
        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (mockCompare(listData, amount0, amount1, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!mockCompare(listData, amount0, amount1, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }
}

/// @title MaxLinkedListLib
/// @notice Library for linked list sorted in non-increasing order
/// @dev Order ids 0 and 1 are special values. The first node of the
/// linked list has order id 0 and the last node has order id 1.
/// Order 0 should be initalized (in OrderBook.sol) with the highest
/// possible price, and order 1 should be initialized with the lowest
library MaxLinkedListLib {
    /// @notice Comparison function for linked list. Returns true
    /// if the price of order id0 is strictly greater than the price of order id1
    function compare(
        MaxLinkedList storage listData,
        uint32 id0,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                listData.idToLimitOrder[id1].amount1,
                listData.idToLimitOrder[id0].amount0,
                listData.idToLimitOrder[id1].amount0,
                listData.idToLimitOrder[id0].amount1
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted
    /// @param orderId The order id to insert
    /// @param hintId The order id to start searching from
    function findIndexToInsert(
        MaxLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) internal view returns (uint32) {
        // No element in the linked list can have next = 0, it means hintId is not in the linked list
        require(listData.list[hintId].next != 0, "Invalid hint id");

        while (!listData.list[hintId].active) {
            hintId = listData.list[hintId].next;
        }

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.
        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (compare(listData, orderId, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!compare(listData, orderId, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }

    /// @notice Inserts an order id into the linked list in sorted order
    /// @param orderId The order id to insert
    /// @param hintId The order id to begin searching for the position to
    /// insert the new order. Can be 0, 1, or the id of an actual order
    function insert(
        MaxLinkedList storage listData,
        uint32 orderId,
        uint32 hintId
    ) public {
        uint32 indexToInsert = findIndexToInsert(listData, orderId, hintId);

        uint32 next = listData.list[indexToInsert].next;
        listData.list[orderId] = Node({
            prev: indexToInsert,
            next: next,
            active: true
        });
        listData.list[indexToInsert].next = orderId;
        listData.list[next].prev = orderId;
    }

    /// @notice Remove an order id from the linked list
    /// @dev Updates the linked list but does not delete the order id from
    /// the idToLimitOrder mapping
    /// @param orderId The order id to remove
    function erase(MaxLinkedList storage listData, uint32 orderId) public {
        require(orderId > 1, "Cannot erase dummy orders");
        require(
            listData.list[orderId].active,
            "Cannot cancel an already inactive order"
        );

        uint32 prev = listData.list[orderId].prev;
        uint32 next = listData.list[orderId].next;

        listData.list[prev].next = next;
        listData.list[next].prev = prev;
        listData.list[orderId].active = false;
    }

    /// @notice Get the first order id in the linked list. Since the linked
    /// list is sorted, this gets the order id with the highest price, if all
    /// the orders are dummy orders, returns 1
    /// @dev Order id 0 is a dummy value and should not be returned
    function getFirstNode(MaxLinkedList storage listData)
        internal
        view
        returns (uint32)
    {
        return listData.list[0].next;
    }

    /// @notice Get the LimitOrder data struct for the first order
    function getTopLimitOrder(MaxLinkedList storage listData)
        public
        view
        returns (LimitOrder storage)
    {
        require(!isEmpty(listData), "Book side is empty");
        return listData.idToLimitOrder[getFirstNode(listData)];
    }

    /// @notice Returns true if the linked list has no orders
    /// @dev Order id 0 and 1 are dummy values, so the linked list
    /// is empty if those are the only two orders
    function isEmpty(MaxLinkedList storage listData)
        public
        view
        returns (bool)
    {
        return getFirstNode(listData) == 1;
    }

    /// @notice Returns the number of orders in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the number of
    /// orders does not include them
    function size(MaxLinkedList storage listData) public view returns (uint32) {
        uint32 listSize = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) ++listSize;
        return listSize;
    }

    /// @notice Returns a list of LimitOrder data structs for each
    /// order in the linked list
    /// @dev Order id 0 and 1 are dummy values, so the returned list
    /// does not include them
    function getOrders(MaxLinkedList storage listData)
        public
        view
        returns (LimitOrder[] memory orders)
    {
        orders = new LimitOrder[](size(listData));
        uint32 i = 0;
        for (
            uint32 pointer = getFirstNode(listData);
            pointer != 1;
            pointer = listData.list[pointer].next
        ) {
            orders[i] = listData.idToLimitOrder[pointer];
            ++i;
        }
    }

    /// @notice Comparison function for linked list. Returns true if the
    /// price of amount0 to amount1 is greater than the price of order id1
    function mockCompare(
        MaxLinkedList storage listData,
        uint256 amount0,
        uint256 amount1,
        uint32 id1
    ) internal view returns (bool) {
        return
            FullMath.mulCompare(
                listData.idToLimitOrder[id1].amount1,
                amount0,
                listData.idToLimitOrder[id1].amount0,
                amount1
            );
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted. Meant to be used off-chain to find the
    /// hintId for the insert function
    /// @param amount0 The amount of token0 in the new order
    /// @param amount1 The amount of token1 in the new order
    function getMockIndexToInsert(
        MaxLinkedList storage listData,
        uint256 amount0,
        uint256 amount1
    ) public view returns (uint32) {
        uint32 hintId = 0;

        // After the two while loops, hintId will be the order id to the
        // left of where the new order should be inserted.

        while (hintId != 1) {
            uint32 nextId = listData.list[hintId].next;
            if (mockCompare(listData, amount0, amount1, nextId)) break;
            hintId = nextId;
        }

        while (hintId != 0) {
            uint32 prevId = listData.list[hintId].prev;
            if (!mockCompare(listData, amount0, amount1, hintId)) break;
            hintId = prevId;
        }

        return hintId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IOrderBook.sol";
import "./interfaces/IBalanceChangeCallback.sol";
import "./interfaces/IFactory.sol";

import "./library/FullMath.sol";

/// @title Router
/// @notice Router for interacting with order books. The user can specify the
/// token pair or the orderBookId of the order book to interact with, and the
/// router will interact with the contract address for that order book
contract Router is IBalanceChangeCallback {
    using SafeERC20 for IERC20Metadata;
    IFactory public immutable factory;

    constructor(address factoryAddress) {
        factory = IFactory(factoryAddress);
    }

    /// @notice Returns the order book given the orderBookId of that order book.
    /// @param orderBookId The id of the order book to lookup
    /// @return orderBook The order book contract for orderBookId
    function getOrderBookFromId(
        uint8 orderBookId
    ) private view returns (IOrderBook) {
        address orderBookAddress = factory.getOrderBookFromId(orderBookId);
        require(orderBookAddress != address(0), "Invalid orderBookId");
        return IOrderBook(orderBookAddress);
    }

    /// @notice Create multiple limit orders in the order book
    /// @param orderBookId The unique identifier of the order book
    /// @param size The number of limit orders to create. The size of each
    /// argument array must be equal to this size
    /// @param amount0Base The amount of token0 for each limit order in terms
    /// of number of sizeTicks. The actual amount of token0 in order i will
    /// be amount0Base[i] * sizeTick
    /// @param priceBase The price of the token0 for each limit order
    /// in terms of token1 and size and price ticks. The actual amount of token1
    /// in the order will be priceBase * amount0Base * priceTick * sizeTick / dec0
    /// @param isAsk Whether each order is an ask order. isAsk = true means
    /// the order sells token0 for token1
    /// @param hintId Where to insert each order in the order book. Meant to
    /// be calculated off-chain using the getMockIndexToInsert function
    /// @return orderId The ids of each created order
    function createLimitOrderBatch(
        uint8 orderBookId,
        uint8 size,
        uint64[] memory amount0Base,
        uint64[] memory priceBase,
        bool[] memory isAsk,
        uint32[] memory hintId
    ) public returns (uint32[] memory orderId) {
        IOrderBook orderBook = getOrderBookFromId(orderBookId);
        orderId = new uint32[](size);
        for (uint8 i = 0; i < size; i++) {
            orderId[i] = orderBook.createLimitOrder(
                amount0Base[i],
                priceBase[i],
                isAsk[i],
                msg.sender,
                hintId[i]
            );
        }
    }

    /// @notice Create limit order in the order book
    /// @param orderBookId The unique identifier of the order book
    /// @param amount0Base The amount of token0 in terms of number of sizeTicks.
    /// The actual amount of token0 in the order will be newAmount0Base * sizeTick
    /// @param priceBase The price of the token0 in terms of token1 and size
    /// and price ticks. The actual amount of token1 in the order will be
    /// priceBase * amount0Base * priceTick * sizeTick / dec0
    /// @param isAsk isAsk = true means the order sells token0 for token1
    /// @param hintId Where to insert order in the order book. Meant to
    /// be calculated off-chain using the getMockIndexToInsert function
    /// @return orderId The id of the created order
    function createLimitOrder(
        uint8 orderBookId,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        uint32 hintId
    ) public returns (uint32 orderId) {
        IOrderBook orderBook = getOrderBookFromId(orderBookId);
        orderId = orderBook.createLimitOrder(
            amount0Base,
            priceBase,
            isAsk,
            msg.sender,
            hintId
        );
    }

    /// @notice Cancels and creates multiple limit orders in the order book
    /// @param orderBookId The unique identifier of the order book
    /// @param size The number of limit orders to cancel and create. The size of each
    /// argument array must be equal to this size
    /// @param orderId The ids of the orders to update
    /// @param newAmount0Base The amount of token0 for each updated limit order
    /// in terms of number of sizeTicks. The actual amount of token0 in the
    /// order will be newAmount0Base * sizeTick
    /// @param newPriceBase The price of the token0 for each limit order
    /// in terms of token1 and size and price ticks. The actual amount of token1
    /// in the order will be priceBase * amount0Base * priceTick * sizeTick / dec0
    /// @param hintId Where to insert each new order in the order book. Meant to
    /// be calculated off-chain using the getMockIndexToInsert function
    /// @return newOrderId The new ids of the each updated order
    function updateLimitOrderBatch(
        uint8 orderBookId,
        uint8 size,
        uint32[] memory orderId,
        uint64[] memory newAmount0Base,
        uint64[] memory newPriceBase,
        uint32[] memory hintId
    ) public returns (uint32[] memory newOrderId) {
        newOrderId = new uint32[](size);
        IOrderBook orderBook = getOrderBookFromId(orderBookId);
        bool isCanceled;
        bool isAsk;
        for (uint256 i = 0; i < size; i++) {
            if (!orderBook.isOrderActive(orderId[i])) {
                newOrderId[i] = 0;
                continue;
            }
            isAsk = orderBook.isAskOrder(orderId[i]);
            isCanceled = orderBook.cancelLimitOrder(orderId[i], msg.sender);

            // Shouldn't happen since function checks if the order is active above
            require(isCanceled, "Could not cancel the order");

            newOrderId[i] = orderBook.createLimitOrder(
                newAmount0Base[i],
                newPriceBase[i],
                isAsk,
                msg.sender,
                hintId[i]
            );
        }
    }

    /// @notice Cancel limit order in the order book and create a new one
    /// @param orderBookId The unique identifier of the order book
    /// @param orderId The id of the order to cancel
    /// @param newAmount0Base The amount of token0 in terms of number of sizeTicks.
    /// The actual amount of token0 in the order will be newAmount0Base * sizeTick
    /// @param newPriceBase The price of the token0 in terms of token1 and size
    /// and price ticks. The actual amount of token1 in the order will be
    /// priceBase * amount0Base * priceTick * sizeTick / dec0
    /// @param hintId Where to insert new order in the order book. Meant to
    /// be calculated off-chain using the getMockIndexToInsert function
    /// @return newOrderId The new id of the updated order
    function updateLimitOrder(
        uint8 orderBookId,
        uint32 orderId,
        uint64 newAmount0Base,
        uint64 newPriceBase,
        uint32 hintId
    ) public returns (uint32 newOrderId) {
        IOrderBook orderBook = getOrderBookFromId(orderBookId);

        if (!orderBook.isOrderActive(orderId)) {
            newOrderId = 0;
        } else {
            bool isAsk = orderBook.isAskOrder(orderId);
            bool isCanceled = orderBook.cancelLimitOrder(orderId, msg.sender);

            // Shouldn't happen since function checks if the order is active above
            require(isCanceled, "Could not cancel the order");
            newOrderId = orderBook.createLimitOrder(
                newAmount0Base,
                newPriceBase,
                isAsk,
                msg.sender,
                hintId
            );
        }
    }

    /// @notice Cancel multiple limit orders in the order book
    /// @dev Including an inactive order in the batch cancelation does not
    /// revert. This is to make it easier for market markers to cancel
    /// @param orderBookId The unique identifier of the order book
    /// @param size The number of limit orders to update. The size of each
    /// argument array must be equal to this size
    /// @param orderId The ids of the orders to cancel
    /// @return isCanceled List of booleans indicating whether each order was successfully
    /// canceled
    function cancelLimitOrderBatch(
        uint8 orderBookId,
        uint8 size,
        uint32[] memory orderId
    ) public returns (bool[] memory isCanceled) {
        IOrderBook orderBook = getOrderBookFromId(orderBookId);
        isCanceled = new bool[](size);
        for (uint256 i = 0; i < size; i++) {
            isCanceled[i] = orderBook.cancelLimitOrder(orderId[i], msg.sender);
        }
    }

    /// @notice Cancel single limit order in the order book
    /// @param orderBookId The unique identifier of the order book
    /// @param orderId The id of the orders to cancel
    /// @return isCanceled A boolean indicating whether the order was successfully canceled
    function cancelLimitOrder(
        uint8 orderBookId,
        uint32 orderId
    ) public returns (bool) {
        IOrderBook orderBook = getOrderBookFromId(orderBookId);
        return orderBook.cancelLimitOrder(orderId, msg.sender);
    }

    /// @notice Create a market order in the order book
    /// @param orderBookId The unique identifier of the order book
    /// @param amount0Base The amount of token0 in the limit order in terms
    /// of number of sizeTicks. The actual amount of token0 in the order will
    /// be amount0Base * sizeTick
    /// @param priceBase The price of the token0 in terms of token1 and size
    /// and price ticks. The actual amount of token1 in the order will be
    /// priceBase * amount0Base * priceTick * sizeTick / dec0
    /// @param isAsk Whether the order is an ask order. isAsk = true means
    /// the order sells token0 for token1
    function createMarketOrder(
        uint8 orderBookId,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk
    ) public {
        IOrderBook orderBook = getOrderBookFromId(orderBookId);
        orderBook.createMarketOrder(amount0Base, priceBase, isAsk, msg.sender);
    }

    /// @inheritdoc IBalanceChangeCallback
    function addBalanceCallback(
        IERC20Metadata tokenToTransfer,
        address to,
        uint256 amount,
        uint8 orderBookId
    ) external override {
        require(
            msg.sender == address(getOrderBookFromId(orderBookId)),
            "Caller does not match order book"
        );
        uint256 contractBalanceBefore = tokenToTransfer.balanceOf(address(this)); 
        tokenToTransfer.safeTransfer(to, amount);
        uint256 contractBalanceAfter = tokenToTransfer.balanceOf(address(this));
        require(
            contractBalanceAfter + amount == contractBalanceBefore,
            "Contract balance change does not match the sent amount"
        );
    }

    /// @inheritdoc IBalanceChangeCallback
    function subtractBalanceCallback(
        IERC20Metadata tokenToTransferFrom,
        address from,
        uint256 amount,
        uint8 orderBookId
    ) external override {
        require(
            msg.sender == address(getOrderBookFromId(orderBookId)),
            "Caller does not match order book"
        );
        uint256 balance = tokenToTransferFrom.balanceOf(from);
        require(
            amount <= balance,
            "Insufficient funds associated with sender's address"
        );
        uint256 contractBalanceBefore = tokenToTransferFrom.balanceOf(address(this)); 
        tokenToTransferFrom.safeTransferFrom(from, address(this), amount);
        uint256 contractBalanceAfter = tokenToTransferFrom.balanceOf(address(this));
        require(
            contractBalanceAfter == contractBalanceBefore + amount,
            "Contract balance change does not match the received amount"
        );
    }

    /// @notice Get the order details of all limit orders in the order book.
    /// Each returned list contains the details of ask orders first, followed
    /// by bid orders
    /// @param orderBookId The id of the order book to lookup
    /// @return id The ids of the orders
    /// @return owner The addresses of the orders' owners
    /// @return amount0 The amount of token0 remaining in the orders
    /// @return amount1 The amount of token1 remaining in the orders
    /// @return isAsk Whether each order is an ask order
    function getLimitOrders(uint8 orderBookId)
        external
        view
        returns (
            uint32[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        IOrderBook orderBook = getOrderBookFromId(orderBookId);
        return orderBook.getLimitOrders();
    }

    /// @notice Get the order details of the ask order with the lowest price
    /// in the order book
    /// @param orderBookId The id of the order book to lookup
    /// @return bestAsk LimitOrder data struct of the best ask order
    function getBestAsk(
        uint8 orderBookId
    ) external view returns (LimitOrder memory) {
        IOrderBook orderBook = getOrderBookFromId(orderBookId);
        return orderBook.getBestAsk();
    }

    /// @notice Get the order details of the bid order with the highest price
    /// in the order book
    /// @param orderBookId The id of the order book to lookup
    /// @return bestBid LimitOrder data struct of the best bid order
    function getBestBid(
        uint8 orderBookId
    ) external view returns (LimitOrder memory) {
        IOrderBook orderBook = getOrderBookFromId(orderBookId);
        return orderBook.getBestBid();
    }

    /// @notice Find the order id to the left of where the new order
    /// should be inserted. Meant to be used off-chain to find the
    /// hintId for the createLimitOrder and updateLimitOrder functions
    /// @param orderBookId The id of the order book to lookup
    /// @param amount0 The amount of token0 in the new order
    /// @param amount1 The amount of token1 in the new order
    /// @param isAsk Whether the new order is an ask order
    /// @return hintId The id of the order to the left of where the new order
    /// should be inserted
    function getMockIndexToInsert(
        uint8 orderBookId,
        uint256 amount0,
        uint256 amount1,
        bool isAsk
    ) external view returns (uint32) {
        IOrderBook orderBook = getOrderBookFromId(orderBookId);
        return orderBook.getMockIndexToInsert(amount0, amount1, isAsk);
    }

    /// @dev Get the uint value from msg.data starting from a specific byte
    /// @param startByte The starting byte
    /// @param length The number of bytes to read
    /// @return val Parsed uint256 value from calldata
    function parseCallData(
        uint256 startByte,
        uint256 length
    ) private pure returns (uint256) {
        uint256 val;

        require(length <= 32, "Length limit is 32 bytes");

        require(
            length + startByte <= msg.data.length,
            "trying to read past end of calldata"
        );

        assembly {
            val := calldataload(startByte)
        }

        val = val >> (256 - length * 8);

        return val;
    }

    /// @notice This function is called when no other router function is
    /// called. The data should be passed in msg.data.
    /// The first byte of msg.data should be the function selector
    /// 1 = createLimitOrder
    /// 2 = updateLimitOrder
    /// 3 = cancelLimitOrder
    /// 4 = createMarketOrder
    /// The next byte should be the orderBookId of the order book
    /// The next byte should be the number of orders to batch. This is ignored
    /// for the createMarketOrder function
    /// Then, for data for each order is read in a loop
    fallback() external {
        uint256 _func;

        _func = parseCallData(0, 1);
        uint8 orderBookId = uint8(parseCallData(1, 1));
        uint8 batchSize = uint8(parseCallData(2, 1));
        uint256 currentByte = 3;
        uint64[] memory amount0Base = new uint64[](batchSize);
        uint64[] memory priceBase = new uint64[](batchSize);
        uint32[] memory hintId = new uint32[](batchSize);
        uint32[] memory orderId = new uint32[](batchSize);

        // createLimitOrder
        if (_func == 1) {
            bool[] memory isAsk = new bool[](batchSize);
            uint8 isAskByte;
            for (uint256 i = 0; i < batchSize; i++) {
                amount0Base[i] = uint64(parseCallData(currentByte, 8));
                priceBase[i] = uint64(parseCallData(currentByte + 8, 8));
                isAskByte = uint8(parseCallData(currentByte + 16, 1));
                require(isAskByte <= 1, "Invalid isAsk");
                isAsk[i] = isAskByte == 1;
                hintId[i] = uint32(parseCallData(currentByte + 17, 4));
                currentByte += 21;
            }
            createLimitOrderBatch(
                orderBookId,
                batchSize,
                amount0Base,
                priceBase,
                isAsk,
                hintId
            );
        }

        // updateLimitOrder
        if (_func == 2) {
            for (uint256 i = 0; i < batchSize; i++) {
                orderId[i] = uint32(parseCallData(currentByte, 4));
                amount0Base[i] = uint64(parseCallData(currentByte + 4, 8));
                priceBase[i] = uint64(parseCallData(currentByte + 12, 8));
                hintId[i] = uint32(parseCallData(currentByte + 20, 4));
                currentByte += 24;
            }
            updateLimitOrderBatch(
                orderBookId,
                batchSize,
                orderId,
                amount0Base,
                priceBase,
                hintId
            );
        }

        // cancelLimitOrder
        if (_func == 3) {
            for (uint256 i = 0; i < batchSize; i++) {
                orderId[i] = uint32(parseCallData(currentByte, 4));
                currentByte += 4;
            }
            cancelLimitOrderBatch(orderBookId, batchSize, orderId);
        }

        // createMarketOrder
        if (_func == 4) {
            uint8 isAskByte = uint8(parseCallData(18, 1));
            require(isAskByte <= 1, "Invalid isAsk");
            createMarketOrder(
                orderBookId,
                uint64(parseCallData(2, 8)),
                uint64(parseCallData(10, 8)),
                isAskByte == 1
            );
        }
    }
}