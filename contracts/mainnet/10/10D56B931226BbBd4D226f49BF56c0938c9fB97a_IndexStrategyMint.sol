// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IIndexToken } from "./interfaces/IIndexToken.sol";
import { SwapAdapter } from "./libraries/SwapAdapter.sol";

struct MintingData {
    uint256 amountIndex;
    uint256 amountWNATIVETotal;
    uint256[] amountWNATIVEs;
    address[] bestRouters;
    uint256[] amountComponents;
}

struct MintParams {
    address token;
    uint256 amountTokenMax;
    uint256 amountIndexMin;
    address recipient;
    address msgSender;
    address wNATIVE;
    address[] components;
    IIndexToken indexToken;
}

struct BurnParams {
    address token;
    uint256 amountTokenMin;
    uint256 amountIndex;
    address recipient;
    address msgSender;
    address wNATIVE;
    address[] components;
    IIndexToken indexToken;
}

struct ManagementParams {
    address wNATIVE;
    address[] components;
    IIndexToken indexToken;
    uint256[] targetWeights;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ICamelotPair {
    function stableSwap() external view returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint16 token0FeePercent,
            uint16 token1FeePercent
        );

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ICamelotRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IChronosFactory {
    function getFee(bool isStable) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IChronosPair {
    function isStable() external view returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint256 reserve0,
            uint256 reserve1,
            uint256 blockTimestampLast
        );

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IChronosRouter {
    struct Route {
        address from;
        address to;
        bool stable;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface INATIVE {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeV2Pair {
    function tokenX() external view returns (address);

    function tokenY() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeV2Point1Pair {
    function getTokenX() external view returns (address tokenX);

    function getTokenY() external view returns (address tokenY);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeV2Point1Router {
    enum Version {
        V1,
        V2,
        V2_1
    }

    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        address[] tokenPath;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function getSwapIn(
        address lbPair,
        uint128 amountOut,
        bool swapForY
    )
        external
        view
        returns (
            uint128 amountIn,
            uint128 amountOutLeft,
            uint128 fee
        );

    function getSwapOut(
        address lbPair,
        uint128 amountIn,
        bool swapForY
    )
        external
        view
        returns (
            uint128 amountInLeft,
            uint128 amountOut,
            uint128 fee
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory binSteps,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory binSteps,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function getSwapIn(
        address lbPair,
        uint256 amountOut,
        bool swapForY
    ) external view returns (uint256 amountIn, uint256 feesIn);

    function getSwapOut(
        address lbPair,
        uint256 amountIn,
        bool swapForY
    ) external view returns (uint256 amountOut, uint256 feesIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IIndexToken is IERC20Upgradeable {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { Errors } from "./Errors.sol";
import { ICamelotPair } from "../dependencies/ICamelotPair.sol";
import { ICamelotRouter } from "../dependencies/ICamelotRouter.sol";

library CamelotLibrary {
    function swapExactTokensForTokens(
        ICamelotRouter router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        uint256 tokenOutBalanceBefore = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            address(0),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        uint256 tokenOutBalanceAfter = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        amountOut = tokenOutBalanceAfter - tokenOutBalanceBefore;
    }

    function swapTokensForExactTokens(
        ICamelotRouter router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        uint256 tokenOutBalanceBefore = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        // Note: In current algorithm, `swapTokensForExactTokens` is called
        // only when `amountInMax` equals to actual amount in. Under this assumption,
        // `swapExactTokensForTokens` is used instead of `swapTokensForExactTokens`
        // because Solidly forks doesn't support `swapTokensForExactTokens`.
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInMax,
            amountOut,
            path,
            address(this),
            address(0),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        uint256 tokenOutBalanceAfter = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        uint256 amountOutReceived = tokenOutBalanceAfter -
            tokenOutBalanceBefore;

        if (amountOutReceived < amountOut) {
            revert Errors.Index_WrongSwapAmount();
        }

        amountIn = amountInMax;
    }

    function getAmountOut(
        ICamelotRouter,
        ICamelotPair pair,
        uint256 amountIn,
        address tokenIn
    ) internal view returns (uint256 amountOut) {
        amountOut = pair.getAmountOut(amountIn, tokenIn);
    }

    function getAmountIn(
        ICamelotRouter,
        ICamelotPair pair,
        uint256 amountOut,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        bool isStable = pair.stableSwap();

        if (isStable) {
            revert Errors.Index_SolidlyStableSwapNotSupported();
        }

        (
            uint112 reserve0,
            uint112 reserve1,
            uint16 token0FeePercent,
            uint16 token1FeePercent
        ) = pair.getReserves();

        address token1 = pair.token1();

        (uint112 reserveIn, uint112 reserveOut) = (tokenOut == token1)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        uint16 feePercent = (tokenOut == token1)
            ? token0FeePercent
            : token1FeePercent;

        amountIn =
            (reserveIn * amountOut * 100000) /
            (reserveOut - amountOut) /
            (100000 - feePercent) +
            1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { Errors } from "./Errors.sol";
import { IChronosFactory } from "../dependencies/IChronosFactory.sol";
import { IChronosPair } from "../dependencies/IChronosPair.sol";
import { IChronosRouter } from "../dependencies/IChronosRouter.sol";

library ChronosLibrary {
    function swapExactTokensForTokens(
        IChronosRouter router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        IChronosRouter.Route[] memory routes = new IChronosRouter.Route[](1);
        routes[0] = IChronosRouter.Route(path[0], path[path.length - 1], false);

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            routes,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[path.length - 1];
    }

    function swapTokensForExactTokens(
        IChronosRouter router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        // Note: In current algorithm, `swapTokensForExactTokens` is called
        // only when `amountInMax` equals to actual amount in. Under this assumption,
        // `swapExactTokensForTokens` is used instead of `swapTokensForExactTokens`
        // because Solidly forks doesn't support `swapTokensForExactTokens`.
        IChronosRouter.Route[] memory routes = new IChronosRouter.Route[](1);
        routes[0] = IChronosRouter.Route(path[0], path[path.length - 1], false);

        uint256 amountOutReceived = router.swapExactTokensForTokens(
            amountInMax,
            amountOut,
            routes,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[path.length - 1];

        if (amountOutReceived < amountOut) {
            revert Errors.Index_WrongSwapAmount();
        }

        amountIn = amountInMax;
    }

    function getAmountOut(
        IChronosRouter,
        IChronosPair pair,
        uint256 amountIn,
        address tokenIn
    ) internal view returns (uint256 amountOut) {
        amountOut = pair.getAmountOut(amountIn, tokenIn);
    }

    function getAmountIn(
        IChronosRouter,
        IChronosPair pair,
        IChronosFactory factory,
        uint256 amountOut,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        bool isStable = pair.isStable();

        if (isStable) {
            revert Errors.Index_SolidlyStableSwapNotSupported();
        }

        uint256 fee = factory.getFee(isStable);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        address token1 = pair.token1();

        (uint256 reserveIn, uint256 reserveOut) = (tokenOut == token1)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        amountIn =
            (reserveIn * amountOut * 10000) /
            (reserveOut - amountOut) /
            (10000 - fee) +
            1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Constants {
    uint256 internal constant DECIMALS = 1e18;

    uint256 internal constant PRECISION = 1e18;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Errors {
    // IndexStrategyUpgradeable errors.
    error Index_ComponentAlreadyExists(address component);
    error Index_ComponentHasNonZeroWeight(address component);
    error Index_NotWhitelistedToken(address token);
    error Index_ExceedEquityValuationLimit();
    error Index_AboveMaxAmount();
    error Index_BelowMinAmount();
    error Index_ZeroAddress();
    error Index_SolidlyStableSwapNotSupported();
    error Index_ReceivedNativeTokenDirectly();
    error Index_WrongSwapAmount();
    error Index_WrongPair(address tokenIn, address tokenOut);
    error Index_WrongTargetWeightsLength();
    error Index_WrongTargetWeights();

    // SwapAdapter errors.
    error SwapAdapter_WrongDEX(uint8 dex);
    error SwapAdapter_WrongPair(address tokenIn, address tokenOut);

    // IndexOracle errors.
    error Oracle_TokenNotSupported(address token);
    error Oracle_ZeroAddress();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { Errors } from "../libraries/Errors.sol";
import { MintingData, MintParams } from "../Common.sol";
import { SwapAdapter } from "../libraries/SwapAdapter.sol";
import { IndexStrategyUtils } from "./IndexStrategyUtils.sol";
import { IIndexToken } from "../interfaces/IIndexToken.sol";
import { Constants } from "../libraries/Constants.sol";
import { INATIVE } from "../dependencies/INATIVE.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library IndexStrategyMint {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SwapAdapter for SwapAdapter.Setup;

    struct MintIndexFromTokenLocals {
        address bestRouter;
        MintingData mintingData;
    }

    /**
     * @dev Mints index tokens in exchange for a specified token.
     * @param mintParams The mint parameters that species the minting details.
     * @param pairData The datastructure describing swapping pairs (used for swapping).
     * @param dexs The datastructure describing dexes (used for swapping).
     * @param weights The datastructure describing component weights.
     * @param routers The datastructure describing routers (used for swapping).
     * @return amountIndex The amount of index tokens minted.
     * @return amountToken The amount of tokens swapped.
     */
    function mintIndexFromToken(
        MintParams memory mintParams,
        mapping(address => mapping(address => mapping(address => SwapAdapter.PairData)))
            storage pairData,
        mapping(address => SwapAdapter.DEX) storage dexs,
        mapping(address => uint256) storage weights,
        mapping(address => address[]) storage routers
    ) external returns (uint256 amountIndex, uint256 amountToken) {
        MintIndexFromTokenLocals memory mintIndexFromTokenLocals;

        if (mintParams.recipient == address(0)) {
            revert Errors.Index_ZeroAddress();
        }

        (
            amountToken,
            mintIndexFromTokenLocals.bestRouter,
            mintIndexFromTokenLocals.mintingData
        ) = getMintingDataFromToken(
            mintParams,
            pairData,
            dexs,
            weights,
            routers
        );

        if (amountToken > mintParams.amountTokenMax) {
            revert Errors.Index_AboveMaxAmount();
        }

        if (
            mintIndexFromTokenLocals.mintingData.amountIndex <
            mintParams.amountIndexMin
        ) {
            revert Errors.Index_BelowMinAmount();
        }

        amountIndex = mintIndexFromTokenLocals.mintingData.amountIndex;

        IERC20Upgradeable(mintParams.token).safeTransferFrom(
            mintParams.msgSender,
            address(this),
            amountToken
        );

        uint256 amountTokenSpent = IndexStrategyUtils.swapTokenForExactToken(
            mintIndexFromTokenLocals.bestRouter,
            mintIndexFromTokenLocals.mintingData.amountWNATIVETotal,
            amountToken,
            mintParams.token,
            mintParams.wNATIVE,
            dexs,
            pairData
        );

        if (amountTokenSpent != amountToken) {
            revert Errors.Index_WrongSwapAmount();
        }

        uint256 amountWNATIVESpent = mintExactIndexFromWNATIVE(
            mintIndexFromTokenLocals.mintingData,
            mintParams.recipient,
            mintParams.components,
            mintParams.wNATIVE,
            mintParams.indexToken,
            dexs,
            pairData
        );

        if (
            amountWNATIVESpent !=
            mintIndexFromTokenLocals.mintingData.amountWNATIVETotal
        ) {
            revert Errors.Index_WrongSwapAmount();
        }
    }

    /**
     * @dev Mints index tokens by swapping the native asset (such as Ether).
     * @param mintParams The mint parameters that species the minting details.
     * @param pairData The datastructure describing swapping pairs (used for swapping).
     * @param dexs The datastructure describing dexes (used for swapping).
     * @param weights The datastructure describing component weights.
     * @param routers The datastructure describing routers (used for swapping).
     * @return amountIndex The amount of index tokens minted.
     * @return amountNATIVE The amount of native tokens swapped.
     */
    function mintIndexFromNATIVE(
        MintParams memory mintParams,
        mapping(address => mapping(address => mapping(address => SwapAdapter.PairData)))
            storage pairData,
        mapping(address => SwapAdapter.DEX) storage dexs,
        mapping(address => uint256) storage weights,
        mapping(address => address[]) storage routers
    ) external returns (uint256 amountIndex, uint256 amountNATIVE) {
        MintingData memory mintingData = getMintingDataFromWNATIVE(
            mintParams.amountTokenMax,
            mintParams,
            routers,
            pairData,
            dexs,
            weights
        );

        if (mintingData.amountWNATIVETotal > mintParams.amountTokenMax) {
            revert Errors.Index_AboveMaxAmount();
        }

        if (mintingData.amountIndex < mintParams.amountIndexMin) {
            revert Errors.Index_BelowMinAmount();
        }

        amountIndex = mintingData.amountIndex;
        amountNATIVE = mintingData.amountWNATIVETotal;

        INATIVE(mintParams.wNATIVE).deposit{
            value: mintingData.amountWNATIVETotal
        }();

        uint256 amountWNATIVESpent = mintExactIndexFromWNATIVE(
            mintingData,
            mintParams.recipient,
            mintParams.components,
            mintParams.wNATIVE,
            mintParams.indexToken,
            dexs,
            pairData
        );

        if (amountWNATIVESpent != mintingData.amountWNATIVETotal) {
            revert Errors.Index_WrongSwapAmount();
        }

        uint256 amountNATIVERefund = mintParams.amountTokenMax - amountNATIVE;

        if (amountNATIVERefund > 0) {
            payable(mintParams.msgSender).transfer(amountNATIVERefund);
        }
    }

    /**
     * @dev Calculates the minting data from the given token and maximum token amount.
     * @param mintParams The mint parameters that species the minting details.
     * @param pairData The datastructure describing swapping pairs (used for swapping).
     * @param dexs The datastructure describing dexes (used for swapping).
     * @param weights The datastructure describing component weights.
     * @param routers The datastructure describing routers (used for swapping).
     * @return amountToken The actual token amount used for minting.
     * @return bestRouter The best router to use for minting.
     * @return mintingData The minting data containing information about the components, routers, and wNATIVE amounts.
     */
    function getMintingDataFromToken(
        MintParams memory mintParams,
        mapping(address => mapping(address => mapping(address => SwapAdapter.PairData)))
            storage pairData,
        mapping(address => SwapAdapter.DEX) storage dexs,
        mapping(address => uint256) storage weights,
        mapping(address => address[]) storage routers
    )
        public
        view
        returns (
            uint256 amountToken,
            address bestRouter,
            MintingData memory mintingData
        )
    {
        (uint256 amountWNATIVE, ) = IndexStrategyUtils.getAmountOutMax(
            routers[mintParams.token],
            mintParams.amountTokenMax,
            mintParams.token,
            mintParams.wNATIVE,
            dexs,
            pairData
        );

        mintingData = getMintingDataFromWNATIVE(
            amountWNATIVE,
            mintParams,
            routers,
            pairData,
            dexs,
            weights
        );

        (amountToken, bestRouter) = IndexStrategyUtils.getAmountInMin(
            routers[mintParams.token],
            mintingData.amountWNATIVETotal,
            mintParams.token,
            mintParams.wNATIVE,
            dexs,
            pairData
        );
    }

    /**
     * @dev Mints the exact index amount of the index token by swapping components with wNATIVE.
     * @param mintingData The minting data containing information about the components and routers.
     * @param recipient The address to receive the minted index tokens.
     * @param components The components that make up the index.
     * @param wNATIVE The address of the wrapped native currency.
     * @param indexToken The address of the indexToken.
     * @param dexs The datastructure describing dexes (used for swapping).
     * @param pairData The datastructure describing swapping pairs (used for swapping).
     * @return amountWNATIVESpent The amount of wNATIVE spent during the minting process.
     */
    function mintExactIndexFromWNATIVE(
        MintingData memory mintingData,
        address recipient,
        address[] memory components,
        address wNATIVE,
        IIndexToken indexToken,
        mapping(address => SwapAdapter.DEX) storage dexs,
        mapping(address => mapping(address => mapping(address => SwapAdapter.PairData)))
            storage pairData
    ) internal returns (uint256 amountWNATIVESpent) {
        for (uint256 i = 0; i < components.length; i++) {
            if (mintingData.amountComponents[i] == 0) {
                continue;
            }

            amountWNATIVESpent += IndexStrategyUtils.swapTokenForExactToken(
                mintingData.bestRouters[i],
                mintingData.amountComponents[i],
                mintingData.amountWNATIVEs[i],
                wNATIVE,
                components[i],
                dexs,
                pairData
            );
        }

        indexToken.mint(recipient, mintingData.amountIndex);
    }

    /**
     * @dev Calculates the minting data from the given wNATIVE amount.
     * @param amountWNATIVEMax The maximum wNATIVE amount to use for minting.
     * @param mintParams The mint parameters that species the minting details.
     * @param routers The datastructure describing routers (used for swapping).
     * @param pairData The datastructure describing swapping pairs (used for swapping).
     * @param dexs The datastructure describing dexes (used for swapping).
     * @param weights The datastructure describing component weights.
     * @return mintingData The minting data containing information about the components, routers, and wNATIVE amounts.
     */
    function getMintingDataFromWNATIVE(
        uint256 amountWNATIVEMax,
        MintParams memory mintParams,
        mapping(address => address[]) storage routers,
        mapping(address => mapping(address => mapping(address => SwapAdapter.PairData)))
            storage pairData,
        mapping(address => SwapAdapter.DEX) storage dexs,
        mapping(address => uint256) storage weights
    ) public view returns (MintingData memory mintingData) {
        MintingData memory mintingDataUnit = getMintingDataForExactIndex(
            Constants.PRECISION,
            dexs,
            pairData,
            weights,
            mintParams.components,
            routers,
            mintParams.wNATIVE
        );

        uint256 amountIndex = type(uint256).max;

        for (uint256 i = 0; i < mintParams.components.length; i++) {
            if (mintingDataUnit.amountWNATIVEs[i] == 0) {
                continue;
            }

            uint256 amountWNATIVE = (amountWNATIVEMax *
                mintingDataUnit.amountWNATIVEs[i]) /
                mintingDataUnit.amountWNATIVETotal;

            if (amountWNATIVE == 0) {
                continue;
            }

            (uint256 amountComponent, ) = IndexStrategyUtils.getAmountOutMax(
                routers[mintParams.components[i]],
                amountWNATIVE,
                mintParams.wNATIVE,
                mintParams.components[i],
                dexs,
                pairData
            );

            amountIndex = MathUpgradeable.min(
                amountIndex,
                (amountComponent * Constants.PRECISION) /
                    weights[mintParams.components[i]]
            );
        }

        mintingData = IndexStrategyMint.getMintingDataForExactIndex(
            amountIndex,
            dexs,
            pairData,
            weights,
            mintParams.components,
            routers,
            mintParams.wNATIVE
        );
    }

    /**
     * @dev Calculates the minting data for the exact index amount.
     * @param amountIndex The exact index amount to mint.
     * @param dexs The datastructure describing dexes (used for swapping).
     * @param pairData The datastructure describing swapping pairs (used for swapping).
     * @param weights The datastructure describing component weights.
     * @param components The components that make up the index.
     * @param routers The datastructure describing routers (used for swapping).
     * @param wNATIVE The address of the wrapped native currency.
     * @return mintingData The minting data containing information about the components, routers, and wNATIVE amounts.
     */
    function getMintingDataForExactIndex(
        uint256 amountIndex,
        mapping(address => SwapAdapter.DEX) storage dexs,
        mapping(address => mapping(address => mapping(address => SwapAdapter.PairData)))
            storage pairData,
        mapping(address => uint256) storage weights,
        address[] memory components,
        mapping(address => address[]) storage routers,
        address wNATIVE
    ) internal view returns (MintingData memory mintingData) {
        mintingData.amountIndex = amountIndex;
        mintingData.amountWNATIVEs = new uint256[](components.length);
        mintingData.bestRouters = new address[](components.length);
        mintingData.amountComponents = new uint256[](components.length);

        for (uint256 i = 0; i < components.length; i++) {
            if (weights[components[i]] == 0) {
                continue;
            }

            mintingData.amountComponents[i] =
                (amountIndex * weights[components[i]]) /
                Constants.PRECISION;

            (
                mintingData.amountWNATIVEs[i],
                mintingData.bestRouters[i]
            ) = IndexStrategyUtils.getAmountInMin(
                routers[components[i]],
                mintingData.amountComponents[i],
                wNATIVE,
                components[i],
                dexs,
                pairData
            );

            mintingData.amountWNATIVETotal += mintingData.amountWNATIVEs[i];
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { Errors } from "../libraries/Errors.sol";
import { SwapAdapter } from "../libraries/SwapAdapter.sol";

library IndexStrategyUtils {
    using SwapAdapter for SwapAdapter.Setup;

    /**
     * @dev Calculates the maximum amount of `tokenOut` tokens that can be received for a given `amountIn` of `tokenIn` tokens,
     *      and identifies the best router to use for the swap among a list of routers.
     * @param routers The list of router addresses to consider for the swap.
     * @param amountIn The amount of `tokenIn` tokens.
     * @param tokenIn The address of the token to be swapped.
     * @param tokenOut The address of the token to receive.
     * @return amountOutMax The maximum amount of `tokenOut` tokens that can be received for the given `amountIn`.
     * @return bestRouter The address of the best router to use for the swap.
     */
    function getAmountOutMax(
        address[] memory routers,
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        mapping(address => SwapAdapter.DEX) storage dexs,
        mapping(address => mapping(address => mapping(address => SwapAdapter.PairData)))
            storage pairData
    ) external view returns (uint256 amountOutMax, address bestRouter) {
        if (tokenIn == tokenOut) {
            return (amountIn, address(0));
        }

        if (routers.length == 0) {
            revert Errors.Index_WrongPair(tokenIn, tokenOut);
        }

        amountOutMax = type(uint256).min;

        for (uint256 i = 0; i < routers.length; i++) {
            address router = routers[i];

            uint256 amountOut = SwapAdapter
                .Setup(
                    dexs[router],
                    router,
                    pairData[router][tokenIn][tokenOut]
                )
                .getAmountOut(amountIn, tokenIn, tokenOut);

            if (amountOut > amountOutMax) {
                amountOutMax = amountOut;
                bestRouter = router;
            }
        }
    }

    /**
     * @dev Calculates the minimum amount of `tokenIn` tokens required to receive a given `amountOut` of `tokenOut` tokens,
     *      and identifies the best router to use for the swap among a list of routers.
     * @param routers The list of router addresses to consider for the swap.
     * @param amountOut The amount of `tokenOut` tokens to receive.
     * @param tokenIn The address of the token to be swapped.
     * @param tokenOut The address of the token to receive.
     * @return amountInMin The minimum amount of `tokenIn` tokens required to receive the given `amountOut`.
     * @return bestRouter The address of the best router to use for the swap.
     */
    function getAmountInMin(
        address[] memory routers,
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        mapping(address => SwapAdapter.DEX) storage dexs,
        mapping(address => mapping(address => mapping(address => SwapAdapter.PairData)))
            storage pairData
    ) external view returns (uint256 amountInMin, address bestRouter) {
        if (tokenIn == tokenOut) {
            return (amountOut, address(0));
        }

        if (routers.length == 0) {
            revert Errors.Index_WrongPair(tokenIn, tokenOut);
        }

        amountInMin = type(uint256).max;

        for (uint256 i = 0; i < routers.length; i++) {
            address router = routers[i];

            uint256 amountIn = SwapAdapter
                .Setup(
                    dexs[router],
                    router,
                    pairData[router][tokenIn][tokenOut]
                )
                .getAmountIn(amountOut, tokenIn, tokenOut);

            if (amountIn < amountInMin) {
                amountInMin = amountIn;
                bestRouter = router;
            }
        }
    }

    /**
     * @dev Swaps a specific amount of `tokenIn` for an exact amount of `tokenOut` using a specified router.
     * @param router The address of the router contract to use for the swap.
     * @param amountOut The exact amount of `tokenOut` tokens to receive.
     * @param amountInMax The maximum amount of `tokenIn` tokens to be used for the swap.
     * @param tokenIn The address of the token to be swapped.
     * @param tokenOut The address of the token to receive.
     * @return amountIn The actual amount of `tokenIn` tokens used for the swap.
     */
    function swapTokenForExactToken(
        address router,
        uint256 amountOut,
        uint256 amountInMax,
        address tokenIn,
        address tokenOut,
        mapping(address => SwapAdapter.DEX) storage dexs,
        mapping(address => mapping(address => mapping(address => SwapAdapter.PairData)))
            storage pairData
    ) external returns (uint256 amountIn) {
        if (tokenIn == tokenOut) {
            return amountOut;
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        amountIn = SwapAdapter
            .Setup(dexs[router], router, pairData[router][tokenIn][tokenOut])
            .swapTokensForExactTokens(amountOut, amountInMax, path);
    }

    /**
     * @dev Swaps exact token for token using a specific router.
     * @param router The router address to use for swapping.
     * @param amountIn The exact amount of input tokens.
     * @param amountOutMin The minimum amount of output tokens to receive.
     * @param tokenIn The input token address.
     * @param tokenOut The output token address.
     * @return amountOut The amount of output tokens received.
     */
    function swapExactTokenForToken(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        mapping(address => SwapAdapter.DEX) storage dexs,
        mapping(address => mapping(address => mapping(address => SwapAdapter.PairData)))
            storage pairData
    ) external returns (uint256 amountOut) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        amountOut = SwapAdapter
            .Setup(dexs[router], router, pairData[router][tokenIn][tokenOut])
            .swapExactTokensForTokens(amountIn, amountOutMin, path);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ICamelotPair } from "../dependencies/ICamelotPair.sol";
import { ICamelotRouter } from "../dependencies/ICamelotRouter.sol";
import { IChronosFactory } from "../dependencies/IChronosFactory.sol";
import { IChronosPair } from "../dependencies/IChronosPair.sol";
import { IChronosRouter } from "../dependencies/IChronosRouter.sol";
import { ITraderJoeV2Pair } from "../dependencies/ITraderJoeV2Pair.sol";
import { ITraderJoeV2Point1Pair } from "../dependencies/ITraderJoeV2Point1Pair.sol";
import { ITraderJoeV2Router } from "../dependencies/ITraderJoeV2Router.sol";
import { ITraderJoeV2Point1Router } from "../dependencies/ITraderJoeV2Point1Router.sol";
import { IUniswapV2Pair } from "../dependencies/IUniswapV2Pair.sol";
import { IUniswapV2Router } from "../dependencies/IUniswapV2Router.sol";
import { CamelotLibrary } from "./CamelotLibrary.sol";
import { ChronosLibrary } from "./ChronosLibrary.sol";
import { TraderJoeV2Library } from "./TraderJoeV2Library.sol";
import { TraderJoeV2Point1Library } from "./TraderJoeV2Point1Library.sol";
import { UniswapV2Library } from "./UniswapV2Library.sol";

import { Errors } from "./Errors.sol";

library SwapAdapter {
    using CamelotLibrary for ICamelotRouter;
    using ChronosLibrary for IChronosRouter;
    using UniswapV2Library for IUniswapV2Router;
    using TraderJoeV2Library for ITraderJoeV2Router;
    using TraderJoeV2Point1Library for ITraderJoeV2Point1Router;

    enum DEX {
        None,
        UniswapV2,
        TraderJoeV2,
        Camelot,
        Chronos,
        TraderJoeV2_1
    }

    struct PairData {
        address pair;
        bytes data; // Pair specific data such as bin step of TraderJoeV2, pool fee of Uniswap V3, etc.
    }

    struct Setup {
        DEX dex;
        address router;
        PairData pairData;
    }

    function swapExactTokensForTokens(
        Setup memory setup,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) external returns (uint256 amountOut) {
        if (path[0] == path[path.length - 1]) {
            return amountIn;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            uint256[] memory binSteps = new uint256[](1);
            binSteps[0] = abi.decode(setup.pairData.data, (uint256));

            return
                ITraderJoeV2Router(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    binSteps,
                    path
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path
                );
        }

        if (setup.dex == DEX.Chronos) {
            return
                IChronosRouter(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path
                );
        }

        if (setup.dex == DEX.TraderJoeV2_1) {
            uint256[] memory binSteps = new uint256[](1);
            binSteps[0] = abi.decode(setup.pairData.data, (uint256));

            return
                ITraderJoeV2Point1Router(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    binSteps,
                    path
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }

    function swapTokensForExactTokens(
        Setup memory setup,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) external returns (uint256 amountIn) {
        if (path[0] == path[path.length - 1]) {
            return amountOut;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    path
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            uint256[] memory binSteps = new uint256[](1);
            binSteps[0] = abi.decode(setup.pairData.data, (uint256));

            return
                ITraderJoeV2Router(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    binSteps,
                    path
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    path
                );
        }

        if (setup.dex == DEX.Chronos) {
            return
                IChronosRouter(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    path
                );
        }

        if (setup.dex == DEX.TraderJoeV2_1) {
            uint256[] memory binSteps = new uint256[](1);
            binSteps[0] = abi.decode(setup.pairData.data, (uint256));

            return
                ITraderJoeV2Point1Router(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    binSteps,
                    path
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }

    function getAmountOut(
        Setup memory setup,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).getAmountOut(
                    IUniswapV2Pair(setup.pairData.pair),
                    amountIn,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            return
                ITraderJoeV2Router(setup.router).getAmountOut(
                    ITraderJoeV2Pair(setup.pairData.pair),
                    amountIn,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).getAmountOut(
                    ICamelotPair(setup.pairData.pair),
                    amountIn,
                    tokenIn
                );
        }

        if (setup.dex == DEX.Chronos) {
            return
                IChronosRouter(setup.router).getAmountOut(
                    IChronosPair(setup.pairData.pair),
                    amountIn,
                    tokenIn
                );
        }

        if (setup.dex == DEX.TraderJoeV2_1) {
            return
                ITraderJoeV2Point1Router(setup.router).getAmountOut(
                    ITraderJoeV2Point1Pair(setup.pairData.pair),
                    amountIn,
                    tokenIn,
                    tokenOut
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }

    function getAmountIn(
        Setup memory setup,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn) {
        if (tokenIn == tokenOut) {
            return amountOut;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).getAmountIn(
                    IUniswapV2Pair(setup.pairData.pair),
                    amountOut,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            return
                ITraderJoeV2Router(setup.router).getAmountIn(
                    ITraderJoeV2Pair(setup.pairData.pair),
                    amountOut,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).getAmountIn(
                    ICamelotPair(setup.pairData.pair),
                    amountOut,
                    tokenOut
                );
        }

        if (setup.dex == DEX.Chronos) {
            address factory = abi.decode(setup.pairData.data, (address));

            return
                IChronosRouter(setup.router).getAmountIn(
                    IChronosPair(setup.pairData.pair),
                    IChronosFactory(factory),
                    amountOut,
                    tokenOut
                );
        }

        if (setup.dex == DEX.TraderJoeV2_1) {
            return
                ITraderJoeV2Point1Router(setup.router).getAmountIn(
                    ITraderJoeV2Point1Pair(setup.pairData.pair),
                    amountOut,
                    tokenIn,
                    tokenOut
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { ITraderJoeV2Pair } from "../dependencies/ITraderJoeV2Pair.sol";
import { ITraderJoeV2Router } from "../dependencies/ITraderJoeV2Router.sol";

library TraderJoeV2Library {
    function swapExactTokensForTokens(
        ITraderJoeV2Router router,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory binSteps,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            binSteps,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    function swapTokensForExactTokens(
        ITraderJoeV2Router router,
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory binSteps,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        amountIn = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            binSteps,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[0];
    }

    function getAmountOut(
        ITraderJoeV2Router router,
        ITraderJoeV2Pair pair,
        uint256 amountIn,
        address,
        address tokenOut
    ) internal view returns (uint256 amountOut) {
        (amountOut, ) = router.getSwapOut(
            address(pair),
            amountIn,
            tokenOut == address(pair.tokenY())
        );
    }

    function getAmountIn(
        ITraderJoeV2Router router,
        ITraderJoeV2Pair pair,
        uint256 amountOut,
        address,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        (amountIn, ) = router.getSwapIn(
            address(pair),
            amountOut,
            tokenOut == address(pair.tokenY())
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { ITraderJoeV2Point1Pair } from "../dependencies/ITraderJoeV2Point1Pair.sol";
import { ITraderJoeV2Point1Router } from "../dependencies/ITraderJoeV2Point1Router.sol";

library TraderJoeV2Point1Library {
    function swapExactTokensForTokens(
        ITraderJoeV2Point1Router router,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory binSteps,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        ITraderJoeV2Point1Router.Version[]
            memory versions = new ITraderJoeV2Point1Router.Version[](
                binSteps.length
            );

        for (uint256 i = 0; i < versions.length; i++) {
            versions[i] = ITraderJoeV2Point1Router.Version.V2_1;
        }

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            ITraderJoeV2Point1Router.Path(binSteps, versions, path),
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    function swapTokensForExactTokens(
        ITraderJoeV2Point1Router router,
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory binSteps,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        ITraderJoeV2Point1Router.Version[]
            memory versions = new ITraderJoeV2Point1Router.Version[](
                binSteps.length
            );

        for (uint256 i = 0; i < versions.length; i++) {
            versions[i] = ITraderJoeV2Point1Router.Version.V2_1;
        }

        amountIn = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            ITraderJoeV2Point1Router.Path(binSteps, versions, path),
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[0];
    }

    function getAmountOut(
        ITraderJoeV2Point1Router router,
        ITraderJoeV2Point1Pair pair,
        uint256 amountIn,
        address,
        address tokenOut
    ) internal view returns (uint256 amountOut) {
        (, amountOut, ) = router.getSwapOut(
            address(pair),
            uint128(amountIn),
            tokenOut == address(pair.getTokenY())
        );
    }

    function getAmountIn(
        ITraderJoeV2Point1Router router,
        ITraderJoeV2Point1Pair pair,
        uint256 amountOut,
        address,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        (amountIn, , ) = router.getSwapIn(
            address(pair),
            uint128(amountOut),
            tokenOut == address(pair.getTokenY())
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { Errors } from "./Errors.sol";
import { IUniswapV2Pair } from "../dependencies/IUniswapV2Pair.sol";
import { IUniswapV2Router } from "../dependencies/IUniswapV2Router.sol";

library UniswapV2Library {
    function swapExactTokensForTokens(
        IUniswapV2Router router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[path.length - 1];
    }

    function swapTokensForExactTokens(
        IUniswapV2Router router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        amountIn = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[0];
    }

    function getAmountOut(
        IUniswapV2Router router,
        IUniswapV2Pair pair,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = _getReserveInAndOut(
            pair,
            tokenIn,
            tokenOut
        );

        amountOut = router.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        IUniswapV2Router router,
        IUniswapV2Pair pair,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        (uint256 reserveIn, uint256 reserveOut) = _getReserveInAndOut(
            pair,
            tokenIn,
            tokenOut
        );

        amountIn = router.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function _getReserveInAndOut(
        IUniswapV2Pair pair,
        address tokenIn,
        address tokenOut
    ) private view returns (uint256 reserveIn, uint256 reserveOut) {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        (address token0, address token1) = (pair.token0(), pair.token1());

        if (tokenIn == token0 && tokenOut == token1) {
            (reserveIn, reserveOut) = (reserve0, reserve1);
        } else if (tokenIn == token1 && tokenOut == token0) {
            (reserveIn, reserveOut) = (reserve1, reserve0);
        } else {
            revert Errors.SwapAdapter_WrongPair(tokenIn, tokenOut);
        }
    }
}