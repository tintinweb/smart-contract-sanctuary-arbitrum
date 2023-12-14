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
interface IERC20PermitUpgradeable {
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
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
library AddressUpgradeable {
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
library MathUpgradeable {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

/************
@title INFTOracleGetter interface
@notice Interface for getting NFT price oracle.*/
interface INFTOracleGetter {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  /***********
    @dev returns the asset price in ETH
     */
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface INToken {
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _underlyingAsset
    ) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IVault {
    event DirectPoolDeposit(address token, uint256 amount);

    struct NftInfo {
        address certiNft; // an NFT certificate proof-of-ownership, which can only be used to redeem their deposited NFT!
        uint256 nftLtv;
    }

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function router() external view returns (address);

    function ethg() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastBorrowingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setEthgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setBorrowingRate(DataTypes.BorrowingRate memory) external;

    function setFees(DataTypes.Fees memory params) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxEthgAmount,
        bool _isStable,
        bool _isShortable,
        bool _isNft
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyETHG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellETHG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function priceFeed() external view returns (address);

    function cumulativeBorrowingRates(
        address _token
    ) external view returns (uint256);

    function getFees() external view returns (DataTypes.Fees memory);

    function getBorrowingRate()
        external
        view
        returns (DataTypes.BorrowingRate memory);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function nftTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function getNftInfo(address _token) external view returns (NftInfo memory);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function ethgAmounts(address _token) external view returns (uint256);

    function maxEthgAmounts(address _token) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getRedemptionAmount(
        address _token,
        uint256 _ethgAmount
    ) external view returns (uint256);

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function mintCNft(
        address _cNft,
        address _to,
        uint256 _tokenId,
        uint256 _ltv
    ) external;

    function mintNToken(address _nToken, uint256 _amount) external;

    function burnCNft(address _cNft, uint256 _tokenId) external;

    function burnNToken(address _nToken, uint256 _amount) external;

    function getBendDAOAssetPrice(address _nft) external view returns (uint256);

    function addNftToUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external;

    function removeNftFromUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external;

    function isNftDepsoitedForUser(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external view returns (bool);

    function getFeeWhenRedeemNft(
        address _token,
        uint256 _ethgAmount
    ) external view returns (uint256);

    function nftUsers(uint256) external view returns (address);

    function nftUsersLength() external view returns (uint256);

    function getUserTokenIds(
        address _user,
        address _nft
    ) external view returns (DataTypes.DepositedNft[] memory);

    function updateNftRefinanceStatus(
        address _user,
        address _nft,
        uint256 _tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise) external view returns (uint256);
    function getLatestPrimaryPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library Errors {

string public constant VAULT_INVALID_MAXLEVERAGE = "0";
string public constant VAULT_INVALID_TAX_BASIS_POINTS = "1";
string public constant VAULT_INVALID_STABLE_TAX_BASIS_POINTS = "2";
string public constant VAULT_INVALID_MINT_BURN_FEE_BASIS_POINTS = "3";
string public constant VAULT_INVALID_SWAP_FEE_BASIS_POINTS = "4";
string public constant VAULT_INVALID_STABLE_SWAP_FEE_BASIS_POINTS = "5";
string public constant VAULT_INVALID_MARGIN_FEE_BASIS_POINTS = "6";
string public constant VAULT_INVALID_LIQUIDATION_FEE_USD = "7";
string public constant VAULT_INVALID_BORROWING_INTERVALE = "8";
string public constant VAULT_INVALID_BORROWING_RATE_FACTOR = "9";
string public constant VAULT_INVALID_STABLE_BORROWING_RATE_FACTOR = "10";
string public constant VAULT_TOKEN_NOT_WHITELISTED = "11";
string public constant VAULT_INVALID_TOKEN_AMOUNT = "12";
string public constant VAULT_INVALID_ETHG_AMOUNT = "13";
string public constant VAULT_INVALID_REDEMPTION_AMOUNT = "14";
string public constant VAULT_INVALID_AMOUNT_OUT = "15";
string public constant VAULT_SWAPS_NOT_ENABLED = "16";
string public constant VAULT_TOKEN_IN_NOT_WHITELISTED = "17";
string public constant VAULT_TOKEN_OUT_NOT_WHITELISTED = "18";
string public constant VAULT_INVALID_TOKENS = "19";
string public constant VAULT_INVALID_AMOUNT_IN = "20";
string public constant VAULT_LEVERAGE_NOT_ENABLED = "21";
string public constant VAULT_INSUFFICIENT_COLLATERAL_FOR_FEES = "22";
string public constant VAULT_INVALID_POSITION_SIZE = "23";
string public constant VAULT_EMPTY_POSITION = "24";
string public constant VAULT_POSITION_SIZE_EXCEEDED = "25";
string public constant VAULT_POSITION_COLLATERAL_EXCEEDED = "26";
string public constant VAULT_INVALID_LIQUIDATOR = "27";
string public constant VAULT_POSITION_CAN_NOT_BE_LIQUIDATED = "28";
string public constant VAULT_INVALID_POSITION = "29";
string public constant VAULT_INVALID_AVERAGE_PRICE = "30";
string public constant VAULT_COLLATERAL_SHOULD_BE_WITHDRAWN = "31";
string public constant VAULT_SIZE_MUST_BE_MORE_THAN_COLLATERAL = "32";
string public constant VAULT_INVALID_MSG_SENDER = "33";
string public constant VAULT_MISMATCHED_TOKENS = "34";
string public constant VAULT_COLLATERAL_TOKEN_NOT_WHITELISTED = "35";
string public constant VAULT_COLLATERAL_TOKEN_MUST_NOT_BE_A_STABLE_TOKEN = "36";
string public constant VAULT_COLLATERAL_TOKEN_MUST_BE_STABLE_TOKEN = "37";
string public constant VAULT_INDEX_TOKEN_MUST_NOT_BE_STABLE_TOKEN = "38";
string public constant VAULT_INDEX_TOKEN_NOT_SHORTABLE = "39";
string public constant VAULT_INVALID_INCREASE = "40";
string public constant VAULT_RESERVE_EXCEEDS_POOL = "41";
string public constant VAULT_MAX_ETHG_EXCEEDED = "42";
string public constant VAULT_FORBIDDEN = "43";
string public constant VAULT_MAX_GAS_PRICE_EXCEEDED = "44";
string public constant VAULT_POOL_AMOUNT_LESS_THAN_BUFFER_AMOUNT = "45";
string public constant VAULT_POOL_AMOUNT_EXCEEDED = "46";
string public constant VAULT_MAX_SHORTS_EXCEEDED = "47"; 
string public constant VAULT_INSUFFICIENT_RESERVE = "48";

string public constant MATH_MULTIPLICATION_OVERFLOW = "49";
string public constant MATH_DIVISION_BY_ZERO = "50";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {DataTypes} from "../types/DataTypes.sol";

library BorrowingFeeLogic {
    event UpdateBorrowingRate(address token, uint256 borrowngRate);

    function updateCumulativeBorrowingRate(
        DataTypes.UpdateCumulativeBorrowingRateParams memory params,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes
    ) external {
        bool shouldUpdate = _updateCumulativeBorrowingRate(
            params.collateralToken,
            params.indexToken
        );
        if (!shouldUpdate) {
            return;
        }

        if (lastBorrowingTimes[params.collateralToken] == 0) {
            lastBorrowingTimes[params.collateralToken] =
                (block.timestamp / params.borrowingInterval) *
                params.borrowingInterval;
            return;
        }

        if (
            lastBorrowingTimes[params.collateralToken] +
                params.borrowingInterval >
            block.timestamp
        ) {
            return;
        }

        uint256 borrowingRate = _getNextBorrowingRate(
            params.borrowingInterval,
            params.collateralTokenPoolAmount,
            params.collateralTokenReservedAmount,
            params.borrowingRateFactor,
            lastBorrowingTimes[params.collateralToken]
        );
        cumulativeBorrowingRates[params.collateralToken] =
            cumulativeBorrowingRates[params.collateralToken] +
            borrowingRate;
        lastBorrowingTimes[params.collateralToken] =
            (block.timestamp / params.borrowingInterval) *
            params.borrowingInterval;

        emit UpdateBorrowingRate(
            params.collateralToken,
            cumulativeBorrowingRates[params.collateralToken]
        );
    }

    function _getNextBorrowingRate(
        uint256 _borrowingInterval,
        uint256 _poolAmount,
        uint256 _reservedAmount,
        uint256 _borrowingRateFactor,
        uint256 _lastBorrowingTime
    ) internal view returns (uint256) {
        if (_lastBorrowingTime + _borrowingInterval > block.timestamp) {
            return 0;
        }

        uint256 intervals = block.timestamp -
            _lastBorrowingTime /
            _borrowingInterval;

        if (_poolAmount == 0) {
            return 0;
        }

        return
            (_borrowingRateFactor * _reservedAmount * intervals) / _poolAmount;
    }

    function _updateCumulativeBorrowingRate(
        address /* _collateralToken */,
        address /* _indexToken */
    ) internal pure returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {ValidationLogic} from "./ValidationLogic.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IVaultPriceFeed} from "../../interfaces/IVaultPriceFeed.sol";
import {PercentageMath} from "../math/PercentageMath.sol";

library GenericLogic {
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseEthgAmount(address token, uint256 amount);
    event DecreaseEthgAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);

    struct FeeBasisPointsParams {
        address token;
        uint256 ethgDelta;
        uint256 feeBasisPoints;
        uint256 taxBasisPoints;
        bool increment;
        bool hasDynamicFees;
        uint256 ethgAmount;
        uint256 targetEthgAmount;
    }

    struct CollectSwapFeesParams {
        address token;
        uint256 amount;
        uint256 feeBasisPoints;
        uint256 tokenDecimals;
        address priceFeed;
    }

    function collectSwapFees(
        CollectSwapFeesParams memory collectSwapFeesParams,
        mapping(address => uint256) storage feeReserves
    ) internal returns (uint256) {
        uint256 afterFeeAmount = (collectSwapFeesParams.amount *
            (PercentageMath.PERCENTAGE_FACTOR -
                collectSwapFeesParams.feeBasisPoints)) /
            PercentageMath.PERCENTAGE_FACTOR;
        uint256 feeAmount = collectSwapFeesParams.amount - afterFeeAmount;
        feeReserves[collectSwapFeesParams.token] =
            feeReserves[collectSwapFeesParams.token] +
            feeAmount;
        emit CollectSwapFees(
            collectSwapFeesParams.token,
            GenericLogic.tokenToUsdMin(
                collectSwapFeesParams.token,
                feeAmount,
                collectSwapFeesParams.tokenDecimals,
                collectSwapFeesParams.priceFeed
            ),
            feeAmount
        );
        return afterFeeAmount;
    }

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    function getFeeBasisPoints(
        FeeBasisPointsParams memory params
    ) internal pure returns (uint256) {
        if (params.hasDynamicFees) {
            return params.feeBasisPoints;
        }

        uint256 initialAmount = params.ethgAmount;
        uint256 nextAmount = initialAmount + params.ethgDelta;
        if (!params.increment) {
            nextAmount = params.ethgDelta > initialAmount
                ? 0
                : initialAmount - params.ethgDelta;
        }

        uint256 targetAmount = params.targetEthgAmount;
        if (targetAmount == 0) {
            return params.feeBasisPoints;
        }

        uint256 initialDiff = initialAmount > targetAmount
            ? initialAmount - targetAmount
            : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount
            ? nextAmount - targetAmount
            : targetAmount - nextAmount;

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = (params.taxBasisPoints * initialDiff) /
                targetAmount;
            return
                rebateBps > params.feeBasisPoints
                    ? 0
                    : params.feeBasisPoints - rebateBps;
        }

        uint256 averageDiff = initialDiff + nextDiff / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = (params.taxBasisPoints * averageDiff) / targetAmount;
        return params.feeBasisPoints + taxBps;
    }

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul,
        address _ethg,
        mapping(address => uint256) storage tokenDecimals
    ) internal view returns (uint256) {
        uint256 decimalsDiv = _tokenDiv == _ethg
            ? PercentageMath.ETHG_DECIMALS
            : 10 ** tokenDecimals[_tokenDiv];
        uint256 decimalsMul = _tokenMul == _ethg
            ? PercentageMath.ETHG_DECIMALS
            : 10 ** tokenDecimals[_tokenMul];
        return (_amount * decimalsMul) / decimalsDiv;
    }

    function getMaxPrice(
        address _token,
        address _priceFeed
    ) internal view returns (uint256) {
        return IVaultPriceFeed(_priceFeed).getPrice(_token, true);
    }

    function getMinPrice(
        address _token,
        address _priceFeed
    ) internal view returns (uint256) {
        return IVaultPriceFeed(_priceFeed).getPrice(_token, false);
    }

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount,
        uint256 _decimals,
        address _priceFeed
    ) internal view returns (uint256) {
        if (_tokenAmount == 0) {
            return 0;
        }
        uint256 price = getMinPrice(_token, _priceFeed);
        // uint256 decimals = tokenDecimals[_token];
        return (_tokenAmount * price) / 10 ** _decimals;
    }

    function usdToTokenMax(
        address _token,
        uint256 _usdAmount,
        uint256 _decimals,
        address _priceFeed
    ) internal view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        return
            usdToToken(_usdAmount, getMinPrice(_token, _priceFeed), _decimals);
    }

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount,
        uint256 _decimals,
        address _priceFeed
    ) internal view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        return
            usdToToken(_usdAmount, getMaxPrice(_token, _priceFeed), _decimals);
    }

    function usdToToken(
        uint256 _usdAmount,
        uint256 _price,
        uint256 _decimals
    ) internal pure returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        // uint256 decimals = tokenDecimals[_token];
        return (_usdAmount * 10 ** _decimals) / _price;
    }

    function getTargetEthgAmount(
        address _ethg,
        uint256 _tokenWeight,
        uint256 _totalTokenWeights
    ) internal view returns (uint256) {
        uint256 supply = IERC20Upgradeable(_ethg).totalSupply();
        if (supply == 0) {
            return 0;
        }
        return (_tokenWeight * supply) / _totalTokenWeights;
    }

    function transferIn(
        address _token,
        mapping(address => uint256) storage tokenBalances
    ) internal returns (uint256) {
        uint256 prevBalance = tokenBalances[_token];
        uint256 nextBalance = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        tokenBalances[_token] = nextBalance;

        return nextBalance - prevBalance;
    }

    function transferOut(
        address _token,
        uint256 _amount,
        address _receiver,
        mapping(address => uint256) storage tokenBalances
    ) internal {
        IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
        tokenBalances[_token] = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
    }

    function getRedemptionAmount(
        address _token,
        uint256 _ethgAmount,
        address _priceFeed,
        address _ethg,
        mapping(address => uint256) storage tokenDecimals
    ) internal view returns (uint256) {
        uint256 price = getMaxPrice(_token, _priceFeed);
        uint256 redemptionAmount = (_ethgAmount *
            PercentageMath.PRICE_PRECISION) / price;

        return
            adjustForDecimals(
                redemptionAmount,
                _ethg,
                _token,
                _ethg,
                tokenDecimals
            );
    }

    function increasePoolAmount(
        address _token,
        uint256 _amount,
        mapping(address => uint256) storage poolAmounts
    ) internal {
        poolAmounts[_token] += _amount;
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        ValidationLogic.validate(
            poolAmounts[_token] <= balance,
            Errors.VAULT_POOL_AMOUNT_EXCEEDED
        );
        emit IncreasePoolAmount(_token, _amount);
    }

    function decreasePoolAmount(
        address _token,
        uint256 _amount,
        uint256 _tokenReservedAmount,
        mapping(address => uint256) storage poolAmounts
    ) internal {
        ValidationLogic.validate(
            poolAmounts[_token] - _amount >= 0,
            Errors.VAULT_POOL_AMOUNT_EXCEEDED
        );
        poolAmounts[_token] -= _amount;
        ValidationLogic.validate(
            _tokenReservedAmount <= poolAmounts[_token],
            Errors.VAULT_RESERVE_EXCEEDS_POOL
        );
        emit DecreasePoolAmount(_token, _amount);
    }

    function increaseEthgAmount(
        address _token,
        uint256 _amount,
        uint256 _maxEthgAmount,
        mapping(address => uint256) storage ethgAmounts
    ) internal {
        ethgAmounts[_token] = ethgAmounts[_token] + _amount;
        if (_maxEthgAmount != 0) {
            ValidationLogic.validate(
                ethgAmounts[_token] <= _maxEthgAmount,
                Errors.VAULT_MAX_ETHG_EXCEEDED
            );
        }
        emit IncreaseEthgAmount(_token, _amount);
    }

    function decreaseEthgAmount(
        address _token,
        uint256 _amount,
        mapping(address => uint256) storage ethgAmounts
    ) internal {
        uint256 value = ethgAmounts[_token];
        // since ETHG can be minted using multiple assets
        // it is possible for the ETHG debt for a single asset to be less than zero
        // the ETHG debt is capped to zero for this case
        if (value <= _amount) {
            ethgAmounts[_token] = 0;
            emit DecreaseEthgAmount(_token, value);
            return;
        }
        ethgAmounts[_token] = value - _amount;
        emit DecreaseEthgAmount(_token, _amount);
    }

    function increaseReservedAmount(
        address _token,
        uint256 _amount,
        uint256 _tokenPoolAmount,
        mapping(address => uint256) storage reservedAmounts
    ) internal {
        reservedAmounts[_token] = reservedAmounts[_token] + _amount;
        ValidationLogic.validate(
            reservedAmounts[_token] <= _tokenPoolAmount,
            Errors.VAULT_RESERVE_EXCEEDS_POOL
        );
        emit IncreaseReservedAmount(_token, _amount);
    }

    function decreaseReservedAmount(
        address _token,
        uint256 _amount,
        mapping(address => uint256) storage reservedAmounts
    ) internal {
        ValidationLogic.validate(
            reservedAmounts[_token] - _amount >= 0,
            Errors.VAULT_INSUFFICIENT_RESERVE
        );

        reservedAmounts[_token] -= _amount;
        emit DecreaseReservedAmount(_token, _amount);
    }

    function increaseGuaranteedUsd(
        address _token,
        uint256 _usdAmount,
        mapping(address => uint256) storage guaranteedUsd
    ) internal {
        guaranteedUsd[_token] = guaranteedUsd[_token] + _usdAmount;
        emit IncreaseGuaranteedUsd(_token, _usdAmount);
    }

    function decreaseGuaranteedUsd(
        address _token,
        uint256 _usdAmount,
        mapping(address => uint256) storage guaranteedUsd
    ) internal {
        guaranteedUsd[_token] = guaranteedUsd[_token] - _usdAmount;
        emit DecreaseGuaranteedUsd(_token, _usdAmount);
    }

    function increaseGlobalShortSize(
        address _token,
        uint256 _amount,
        uint256 _tokenMaxGlobalShortSizes,
        mapping(address => uint256) storage globalShortSizes
    ) internal {
        globalShortSizes[_token] = globalShortSizes[_token] + _amount;
        if (_tokenMaxGlobalShortSizes != 0) {
            ValidationLogic.validate(
                globalShortSizes[_token] <= _tokenMaxGlobalShortSizes,
                Errors.VAULT_MAX_SHORTS_EXCEEDED
            );
        }
    }

    function decreaseGlobalShortSize(
        address _token,
        uint256 _amount,
        mapping(address => uint256) storage globalShortSizes
    ) internal {
        uint256 size = globalShortSizes[_token];
        if (_amount > size) {
            globalShortSizes[_token] = 0;
            return;
        }

        globalShortSizes[_token] = size - _amount;
    }

    function updateTokenBalance(
        address _token,
        mapping(address => uint256) storage tokenBalances
    ) internal {
        uint256 nextBalance = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        tokenBalances[_token] = nextBalance;
    }

    function getFeeWhenRedeemNft(
        address _token,
        uint256 _ethgAmount,
        address _priceFeed,
        address _ethg,
        uint256 _tokenWeight,
        uint256 _totalTokenWeights,
        uint256 _tokenEthgAmount,
        DataTypes.Fees memory fees,
        mapping(address => uint256) storage tokenDecimals
    ) internal view returns (uint256) {
        uint256 redemptionAmount = getRedemptionAmount(
            _token,
            _ethgAmount,
            _priceFeed,
            _ethg,
            tokenDecimals
        );
        ValidationLogic.validate(
            redemptionAmount > 0,
            Errors.VAULT_INVALID_REDEMPTION_AMOUNT
        );

        uint256 targetEthgAmountToken = getTargetEthgAmount(
            _ethg,
            _tokenWeight,
            _totalTokenWeights
        );

        uint256 feeBasisPoints = getSellEthgFeeBasisPoints(
            _token,
            _ethgAmount,
            _tokenEthgAmount,
            targetEthgAmountToken,
            fees
        );

        uint256 afterFeeAmount = (redemptionAmount *
            (PercentageMath.PERCENTAGE_FACTOR - feeBasisPoints)) /
            PercentageMath.PERCENTAGE_FACTOR;
        uint256 feeAmount = redemptionAmount - afterFeeAmount;

        return feeAmount;
    }

    function getBuyEthgFeeBasisPoints(
        address _token,
        uint256 _ethgDelta,
        uint256 _ethgAmount,
        uint256 _targetEthgAmount,
        DataTypes.Fees memory _fees
    ) internal pure returns (uint256) {
        return
            getFeeBasisPoints(
                FeeBasisPointsParams({
                    token: _token,
                    ethgDelta: _ethgDelta,
                    feeBasisPoints: _fees.mintBurnFeeBasisPoints,
                    taxBasisPoints: _fees.taxBasisPoints,
                    increment: true,
                    hasDynamicFees: _fees.hasDynamicFees,
                    ethgAmount: _ethgAmount,
                    targetEthgAmount: _targetEthgAmount
                })
            );
    }

    function getSellEthgFeeBasisPoints(
        address _token,
        uint256 _ethgDelta,
        uint256 _ethgAmount,
        uint256 _targetEthgAmount,
        DataTypes.Fees memory _fees
    ) internal pure returns (uint256) {
        return
            getFeeBasisPoints(
                FeeBasisPointsParams({
                    token: _token,
                    ethgDelta: _ethgDelta,
                    feeBasisPoints: _fees.mintBurnFeeBasisPoints,
                    taxBasisPoints: _fees.taxBasisPoints,
                    increment: false,
                    hasDynamicFees: _fees.hasDynamicFees,
                    ethgAmount: _ethgAmount,
                    targetEthgAmount: _targetEthgAmount
                })
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ValidationLogic} from "./ValidationLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {BorrowingFeeLogic} from "./BorrowingFeeLogic.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IETHG} from "../../../tokens/interfaces/IETHG.sol";
import {INFTOracleGetter} from "../../BendDAO/interfaces/INFTOracleGetter.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {INToken} from "../../interfaces/INToken.sol";

import {PercentageMath} from "../math/PercentageMath.sol";

library SupplyLogic {
    event BuyETHG(
        address account,
        address token,
        uint256 tokenAmount,
        uint256 ethgAmount,
        uint256 feeBasisPoints
    );
    event SellETHG(
        address account,
        address token,
        uint256 ethgAmount,
        uint256 tokenAmount,
        uint256 feeBasisPoints
    );

    function ExecuteBuyETHG(
        address _token,
        address _receiver,
        bool _inManagerMode,
        address _bendOracle,
        address _priceFeed,
        address _ethg,
        uint256 _totalTokenWeights,
        DataTypes.Fees memory fees,
        DataTypes.BorrowingRate memory borrowingRate,
        mapping(address => bool) storage isManager,
        mapping(address => bool) storage whitelistedTokens,
        mapping(address => bool) storage nftTokens,
        mapping(address => uint256) storage tokenBalances,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes,
        mapping(address => uint256) storage poolAmounts,
        mapping(address => uint256) storage reservedAmounts,
        mapping(address => uint256) storage tokenDecimals,
        mapping(address => uint256) storage maxEthgAmounts,
        mapping(address => uint256) storage ethgAmounts,
        mapping(address => uint256) storage tokenWeights,
        mapping(address => uint256) storage feeReserves
    ) external returns (uint256) {
        ValidationLogic.validateManager(_inManagerMode, isManager);
        ValidationLogic.validateWhitelistedToken(_token, whitelistedTokens);

        uint256 tokenAmount;

        tokenAmount = GenericLogic.transferIn(_token, tokenBalances);

        ValidationLogic.validate(
            tokenAmount > 0,
            Errors.VAULT_INVALID_TOKEN_AMOUNT
        );

        BorrowingFeeLogic.updateCumulativeBorrowingRate(
            DataTypes.UpdateCumulativeBorrowingRateParams({
                collateralToken: _token,
                indexToken: _token,
                borrowingInterval: borrowingRate.borrowingInterval,
                borrowingRateFactor: borrowingRate.borrowingRateFactor,
                collateralTokenPoolAmount: poolAmounts[_token],
                collateralTokenReservedAmount: reservedAmounts[_token]
            }),
            cumulativeBorrowingRates,
            lastBorrowingTimes
        );

        uint256 price = GenericLogic.getMinPrice(_token, _priceFeed);
        if (nftTokens[_token]) {
            uint256 priceBend = INFTOracleGetter(_bendOracle).getAssetPrice(
                _token
            );
            price = price < priceBend ? price : priceBend;
        }

        uint256 ethgAmount = (tokenAmount * price) /
            PercentageMath.PRICE_PRECISION;

        ethgAmount = GenericLogic.adjustForDecimals(
            ethgAmount,
            _token,
            _ethg,
            _ethg,
            tokenDecimals
        );
        ValidationLogic.validate(
            ethgAmount > 0,
            Errors.VAULT_INVALID_ETHG_AMOUNT
        );

        uint256 targetEthgAmountToken = GenericLogic.getTargetEthgAmount(
            _ethg,
            tokenWeights[_token],
            _totalTokenWeights
        );

        uint256 feeBasisPoints = GenericLogic.getBuyEthgFeeBasisPoints(
            _token,
            ethgAmount,
            ethgAmounts[_token],
            targetEthgAmountToken,
            fees
        );

        uint256 amountAfterFees = GenericLogic.collectSwapFees(
            GenericLogic.CollectSwapFeesParams({
                token: _token,
                amount: tokenAmount,
                feeBasisPoints: feeBasisPoints,
                tokenDecimals: tokenDecimals[_token],
                priceFeed: _priceFeed
            }),
            feeReserves
        );
        uint256 mintAmount = (amountAfterFees * price) /
            PercentageMath.PRICE_PRECISION;
        mintAmount = GenericLogic.adjustForDecimals(
            mintAmount,
            _token,
            _ethg,
            _ethg,
            tokenDecimals
        );

        GenericLogic.increaseEthgAmount(
            _token,
            mintAmount,
            maxEthgAmounts[_token],
            ethgAmounts
        );
        GenericLogic.increasePoolAmount(_token, amountAfterFees, poolAmounts);

        IETHG(_ethg).mint(_receiver, mintAmount);

        emit BuyETHG(
            _receiver,
            _token,
            tokenAmount,
            mintAmount,
            feeBasisPoints
        );

        return mintAmount;
    }

    function ExecuteSellETHG(
        address _token,
        address _receiver,
        address _priceFeed,
        address _ethg,
        uint256 _totalTokenWeights,
        bool _inManagerMode,
        DataTypes.Fees memory fees,
        DataTypes.BorrowingRate memory borrowingRate,
        mapping(address => bool) storage isManager,
        mapping(address => uint256) storage tokenBalances,
        mapping(address => bool) storage whitelistedTokens,
        mapping(address => uint256) storage cumulativeBorrowingRates,
        mapping(address => uint256) storage lastBorrowingTimes,
        mapping(address => uint256) storage poolAmounts,
        mapping(address => uint256) storage reservedAmounts,
        mapping(address => uint256) storage ethgAmounts,
        mapping(address => uint256) storage tokenWeights,
        mapping(address => uint256) storage tokenDecimals,
        mapping(address => uint256) storage feeReserves,
        mapping(address => bool) storage nftTokens
    ) external returns (uint256) {
        ValidationLogic.validateManager(_inManagerMode, isManager);
        ValidationLogic.validateWhitelistedToken(_token, whitelistedTokens);

        uint256 ethgAmount = GenericLogic.transferIn(_ethg, tokenBalances);
        ValidationLogic.validate(
            ethgAmount > 0,
            Errors.VAULT_INVALID_ETHG_AMOUNT
        );

        BorrowingFeeLogic.updateCumulativeBorrowingRate(
            DataTypes.UpdateCumulativeBorrowingRateParams({
                collateralToken: _token,
                indexToken: _token,
                borrowingInterval: borrowingRate.borrowingInterval,
                borrowingRateFactor: borrowingRate.borrowingRateFactor,
                collateralTokenPoolAmount: poolAmounts[_token],
                collateralTokenReservedAmount: reservedAmounts[_token]
            }),
            cumulativeBorrowingRates,
            lastBorrowingTimes
        );

        uint256 redemptionAmount = GenericLogic.getRedemptionAmount(
            _token,
            ethgAmount,
            _priceFeed,
            _ethg,
            tokenDecimals
        );
        ValidationLogic.validate(
            redemptionAmount > 0,
            Errors.VAULT_INVALID_REDEMPTION_AMOUNT
        );

        GenericLogic.decreaseEthgAmount(_token, ethgAmount, ethgAmounts);
        GenericLogic.decreasePoolAmount(
            _token,
            redemptionAmount,
            reservedAmounts[_token],
            poolAmounts
        );

        IETHG(_ethg).burn(address(this), ethgAmount);

        // the _transferIn call increased the value of tokenBalances[ethg]
        // usually decreases in token balances are synced by calling _transferOut
        // however, for ethg, the tokens are burnt, so _updateTokenBalance should
        // be manually called to record the decrease in tokens
        GenericLogic.updateTokenBalance(_ethg, tokenBalances);

        uint256 targetEthgAmountToken = GenericLogic.getTargetEthgAmount(
            _ethg,
            tokenWeights[_token],
            _totalTokenWeights
        );

        uint256 feeBasisPoints = GenericLogic.getSellEthgFeeBasisPoints(
            _token,
            ethgAmount,
            ethgAmounts[_token],
            targetEthgAmountToken,
            fees
        );

        uint256 amountOut = GenericLogic.collectSwapFees(
            GenericLogic.CollectSwapFeesParams({
                token: _token,
                amount: redemptionAmount,
                feeBasisPoints: feeBasisPoints,
                tokenDecimals: tokenDecimals[_token],
                priceFeed: _priceFeed
            }),
            feeReserves
        );

        ValidationLogic.validate(
            amountOut > 0,
            Errors.VAULT_INVALID_AMOUNT_OUT
        );

        if (nftTokens[_token]) {
            INToken(_token).burn(address(this), amountOut);
        } else {
            GenericLogic.transferOut(
                _token,
                amountOut,
                _receiver,
                tokenBalances
            );
        }

        emit SellETHG(_receiver, _token, ethgAmount, amountOut, feeBasisPoints);

        return amountOut;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Errors} from "../helpers/Errors.sol";

import {DataTypes} from "../types/DataTypes.sol";

library ValidationLogic {
    function validateSwapParams(
        bool _isSwapEnabled,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        mapping(address => bool) storage whitelistedTokens
    ) internal view {
        validate(_amountIn > 0, Errors.VAULT_INVALID_AMOUNT_IN);
        validate(_isSwapEnabled, Errors.VAULT_SWAPS_NOT_ENABLED);
        validate(
            whitelistedTokens[_tokenIn],
            Errors.VAULT_TOKEN_IN_NOT_WHITELISTED
        );
        validate(
            whitelistedTokens[_tokenOut],
            Errors.VAULT_TOKEN_OUT_NOT_WHITELISTED
        );
        validate(_tokenIn != _tokenOut, Errors.VAULT_INVALID_TOKENS);
    }

    function validateIncreasePositionParams(
        DataTypes.IncreasePositionParams memory params,
        mapping(address => mapping(address => bool)) storage approvedRouters,
        mapping(address => bool) storage whitelistedTokens,
        mapping(address => bool) storage stableTokens,
        mapping(address => bool) storage shortableTokens
    ) internal view {
        validateLeverage(params.isLeverageEnabled);
        validateGasPrice(params.maxGasPrice);
        validateRouter(params.account, params.router, approvedRouters);
        validateTokens(
            params.collateralToken,
            params.indexToken,
            params.isLong,
            whitelistedTokens,
            stableTokens,
            shortableTokens
        );

        validateIncreasePosition(
            params.account,
            params.collateralToken,
            params.indexToken,
            params.sizeDelta,
            params.isLong
        );
    }

    function validateDecreasePositionParams(
        DataTypes.DecreasePositionParams memory params,
        mapping(address => mapping(address => bool)) storage approvedRouters
    ) internal view {
        validateGasPrice(params.maxGasPrice);
        validateRouter(params.account, params.router, approvedRouters);
        validateDecreasePosition(
            params.account,
            params.collateralToken,
            params.indexToken,
            params.collateralDelta,
            params.sizeDelta,
            params.isLong,
            params.receiver
        );
    }

    function validateGasPrice(uint256 _maxGasPrice) internal view {
        if (_maxGasPrice == 0) {
            return;
        }
        validate(
            tx.gasprice <= _maxGasPrice,
            Errors.VAULT_MAX_GAS_PRICE_EXCEEDED
        );
    }

    function validateWhitelistedToken(
        address _token,
        mapping(address => bool) storage whitelistedTokens
    ) internal view {
        validate(
            whitelistedTokens[_token],
            Errors.VAULT_TOKEN_IN_NOT_WHITELISTED
        );
    }

    function validateBufferAmount(
        uint256 _poolAmount,
        uint256 _bufferAmount
    ) internal pure {
        validate(
            _poolAmount >= _bufferAmount,
            Errors.VAULT_POOL_AMOUNT_LESS_THAN_BUFFER_AMOUNT
        );
    }

    function validateManager(
        bool _inManagerMode,
        mapping(address => bool) storage isManager
    ) internal view {
        if (_inManagerMode) {
            validate(isManager[msg.sender], Errors.VAULT_FORBIDDEN);
        }
    }

    function validateTokens(
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        mapping(address => bool) storage whitelistedTokens,
        mapping(address => bool) storage stableTokens,
        mapping(address => bool) storage shortableTokens
    ) internal view {
        if (_isLong) {
            validate(
                _collateralToken == _indexToken,
                Errors.VAULT_MISMATCHED_TOKENS
            );
            validate(
                whitelistedTokens[_collateralToken],
                Errors.VAULT_COLLATERAL_TOKEN_NOT_WHITELISTED
            );
            validate(
                !stableTokens[_collateralToken],
                Errors.VAULT_COLLATERAL_TOKEN_MUST_BE_STABLE_TOKEN
            );
            return;
        }

        validate(
            whitelistedTokens[_collateralToken],
            Errors.VAULT_COLLATERAL_TOKEN_NOT_WHITELISTED
        );
        validate(
            stableTokens[_collateralToken],
            Errors.VAULT_COLLATERAL_TOKEN_MUST_BE_STABLE_TOKEN
        );
        validate(
            !stableTokens[_indexToken],
            Errors.VAULT_INDEX_TOKEN_MUST_NOT_BE_STABLE_TOKEN
        );
        validate(
            shortableTokens[_indexToken],
            Errors.VAULT_INDEX_TOKEN_NOT_SHORTABLE
        );
    }

    function validatePosition(
        uint256 _size,
        uint256 _collateral
    ) internal pure {
        if (_size == 0) {
            validate(
                _collateral == 0,
                Errors.VAULT_COLLATERAL_SHOULD_BE_WITHDRAWN
            );
            return;
        }
        validate(
            _size >= _collateral,
            Errors.VAULT_SIZE_MUST_BE_MORE_THAN_COLLATERAL
        );
    }

    function validateRouter(
        address _account,
        address _router,
        mapping(address => mapping(address => bool)) storage approvedRouters
    ) internal view {
        if (msg.sender == _account) {
            return;
        }
        if (msg.sender == _router) {
            return;
        }
        validate(
            approvedRouters[_account][msg.sender],
            Errors.VAULT_INVALID_MSG_SENDER
        );
    }

    function validateLeverage(bool _isLeverageEnabled) internal pure {
        validate(_isLeverageEnabled, Errors.VAULT_LEVERAGE_NOT_ENABLED);
    }

    function validateIncreasePosition(
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        uint256 /* _sizeDelta */,
        bool /* _isLong */
    ) internal pure {
        // no additional validations
    }

    function validateDecreasePosition(
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        uint256 /* _collateralDelta */,
        uint256 /* _sizeDelta */,
        bool /* _isLong */,
        address /* _receiver */
    ) internal pure {
        // no additional validations
    }

    function validate(bool _condition, string memory _errorCode) internal pure {
        require(_condition, _errorCode);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Errors} from "../helpers/Errors.sol";

library PercentageMath {
    uint256 public constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 public constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

    uint256 public constant PRICE_PRECISION = 1e30;
    uint256 public constant ETHG_DECIMALS = 1e18;
    uint256 public constant GLP_PRECISION = 1e18;
    uint256 public constant NTOKEN_PRECISION = 1e18;

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(
        uint256 value,
        uint256 percentage
    ) internal pure returns (uint256) {
        if (value == 0 || percentage == 0) {
            return 0;
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(
        uint256 value,
        uint256 percentage
    ) internal pure returns (uint256) {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfPercentage = percentage / 2;

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library DataTypes {
    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryBorrowingRate;
        uint256 fundingFeeAmountPerSize;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    struct Fees {
        uint256 taxBasisPoints;
        uint256 stableTaxBasisPoints;
        uint256 mintBurnFeeBasisPoints;
        uint256 swapFeeBasisPoints;
        uint256 stableSwapFeeBasisPoints;
        uint256 marginFeeBasisPoints;
        uint256 liquidationFeeUsd;
        uint256 minProfitTime;
        bool hasDynamicFees;
    }

    struct UpdateCumulativeBorrowingRateParams {
        address collateralToken;
        address indexToken;
        uint256 borrowingInterval;
        uint256 borrowingRateFactor;
        uint256 collateralTokenPoolAmount;
        uint256 collateralTokenReservedAmount;
    }

    struct SwapParams {
        bool isSwapEnabled;
        address tokenIn;
        address tokenOut;
        address receiver;
        bool isStableSwap;
        address ethg;
        address priceFeed;
        uint256 totalTokenWeights;
    }

    struct IncreasePositionParams {
        address account;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        address priceFeed;
        bool isLeverageEnabled;
        uint256 maxGasPrice;
        address router;
        uint256 borrowingRatePrecision;
        uint256 maxLeverage;
    }

    struct DecreasePositionParams {
        address account;
        address collateralToken;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        address priceFeed;
        uint256 maxGasPrice;
        address router;
        uint256 borrowingRatePrecision;
        uint256 maxLeverage;
    }

    struct LiquidatePositionParams {
        address account;
        address collateralToken;
        address indexToken;
        bool isLong;
        address feeReceiver;
        bool inPrivateLiquidationMode;
        address priceFeed;
        uint256 maxGasPrice;
        address router;
        uint256 borrowingRatePrecision;
        uint256 maxLeverage;
    }

    struct BorrowingRate {
        uint256 borrowingInterval;
        uint256 borrowingRateFactor;
        uint256 stableBorrowingRateFactor;
    }

    struct DepositedNft {
        uint256 tokenId;
        bool isRefinanced;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IETHG {
    function addVault(address _vault) external;
    function removeVault(address _vault) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}