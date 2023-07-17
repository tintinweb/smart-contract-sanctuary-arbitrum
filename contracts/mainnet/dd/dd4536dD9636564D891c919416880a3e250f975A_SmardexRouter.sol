// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
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
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
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
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
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
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
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
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
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
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
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
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
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
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
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
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
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
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
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
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
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
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
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
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
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
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
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
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
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
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
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
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
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
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
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
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
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
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
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
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
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
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
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
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
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
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
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
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
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
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.17;

interface ISmardexFactory {
    /**
     * @notice emitted at each SmardexPair created
     * @param token0 address of the token0
     * @param token1 address of the token1
     * @param pair address of the SmardexPair created
     * @param totalPair number of SmardexPair created so far
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 totalPair);

    /**
     * @notice emitted each time feesLP and feesPool are changed
     * @param feesLP new feesLP
     * @param feesPool new feesPool
     */
    event FeesChanged(uint256 indexed feesLP, uint256 indexed feesPool);

    /**
     * @notice emitted when the feeTo is updated
     * @param previousFeeTo the previous feeTo address
     * @param newFeeTo the new feeTo address
     */
    event FeeToUpdated(address indexed previousFeeTo, address indexed newFeeTo);

    /**
     * @notice return which address fees will be transferred
     */
    function feeTo() external view returns (address);

    /**
     * @notice return the address of the pair of 2 tokens
     */
    function getPair(address _tokenA, address _tokenB) external view returns (address pair_);

    /**
     * @notice return the address of the pair at index
     * @param _index index of the pair
     * @return pair_ address of the pair
     */
    function allPairs(uint256 _index) external view returns (address pair_);

    /**
     * @notice return the quantity of pairs
     * @return quantity in uint256
     */
    function allPairsLength() external view returns (uint256);

    /**
     * @notice return numerators of pair fees, denominator is 1_000_000
     * @return feesLP_ numerator of fees sent to LP at pair creation
     * @return feesPool_ numerator of fees sent to Pool at pair creation
     */
    function getDefaultFees() external view returns (uint128 feesLP_, uint128 feesPool_);

    /**
     * @notice create pair with 2 address
     * @param _tokenA address of tokenA
     * @param _tokenB address of tokenB
     * @return pair_ address of the pair created
     */
    function createPair(address _tokenA, address _tokenB) external returns (address pair_);

    /**
     * @notice set the address who will receive fees, can only be call by the owner
     * @param _feeTo address to replace
     */
    function setFeeTo(address _feeTo) external;

    /**
     * @notice set feesLP and feesPool for each new pair (onlyOwner)
     * @notice sum of new feesLp and feesPool must be <= FEES_MAX = 10% FEES_BASE
     * @param _feesLP new numerator of fees sent to LP, must be >= 1
     * @param _feesPool new numerator of fees sent to Pool, could be = 0
     */
    function setFees(uint128 _feesLP, uint128 _feesPool) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.17;

interface ISmardexMintCallback {
    /**
     * @notice callback data for mint
     * @param token0 address of the first token of the pair
     * @param token1 address of the second token of the pair
     * @param amount0 amount of token0 to provide
     * @param amount1 amount of token1 to provide
     * @param payer address of the payer to provide token for the mint
     */
    struct MintCallbackData {
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        address payer;
    }

    /**
     * @notice callback to implement when calling SmardexPair.mint
     * @param _data callback data for mint
     */
    function smardexMintCallback(MintCallbackData calldata _data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface ISmardexPair is IERC20, IERC20Permit {
    /**
     * @notice swap parameters used by function swap
     * @param amountCalculated return amount from getAmountIn/Out is always positive but to avoid too much cast, is int
     * @param fictiveReserveIn fictive reserve of the in-token of the pair
     * @param fictiveReserveOut fictive reserve of the out-token of the pair
     * @param priceAverageIn in-token ratio component of the price average
     * @param priceAverageOut out-token ratio component of the price average
     * @param token0 address of the token0
     * @param token1 address of the token1
     * @param balanceIn contract balance of the in-token
     * @param balanceOut contract balance of the out-token
     */
    struct SwapParams {
        int256 amountCalculated;
        uint256 fictiveReserveIn;
        uint256 fictiveReserveOut;
        uint256 priceAverageIn;
        uint256 priceAverageOut;
        address token0;
        address token1;
        uint256 balanceIn;
        uint256 balanceOut;
    }

    /**
     * @notice emitted at each mint
     * @param sender address calling the mint function (usually the Router contract)
     * @param to address that receives the LP-tokens
     * @param amount0 amount of token0 to be added in liquidity
     * @param amount1 amount of token1 to be added in liquidity
     * @dev the amount of LP-token sent can be caught using the transfer event of the pair
     */
    event Mint(address indexed sender, address indexed to, uint256 amount0, uint256 amount1);

    /**
     * @notice emitted at each burn
     * @param sender address calling the burn function (usually the Router contract)
     * @param to address that receives the tokens
     * @param amount0 amount of token0 to be withdrawn
     * @param amount1 amount of token1 to be withdrawn
     * @dev the amount of LP-token sent can be caught using the transfer event of the pair
     */
    event Burn(address indexed sender, address indexed to, uint256 amount0, uint256 amount1);

    /**
     * @notice emitted at each swap
     * @param sender address calling the swap function (usually the Router contract)
     * @param to address that receives the out-tokens
     * @param amount0 amount of token0 to be swapped
     * @param amount1 amount of token1 to be swapped
     * @dev one of the 2 amount is always negative, the other one is always positive. The positive one is the one that
     * the user send to the contract, the negative one is the one that the contract send to the user.
     */
    event Swap(address indexed sender, address indexed to, int256 amount0, int256 amount1);

    /**
     * @notice emitted each time the fictive reserves are changed (mint, burn, swap)
     * @param reserve0 the new reserve of token0
     * @param reserve1 the new reserve of token1
     * @param fictiveReserve0 the new fictive reserve of token0
     * @param fictiveReserve1 the new fictive reserve of token1
     * @param priceAverage0 the new priceAverage of token0
     * @param priceAverage1 the new priceAverage of token1
     */
    event Sync(
        uint256 reserve0,
        uint256 reserve1,
        uint256 fictiveReserve0,
        uint256 fictiveReserve1,
        uint256 priceAverage0,
        uint256 priceAverage1
    );

    /**
     * @notice emitted each time feesLP and feesPool are changed
     * @param feesLP new feesLP
     * @param feesPool new feesPool
     */
    event FeesChanged(uint256 indexed feesLP, uint256 indexed feesPool);

    /**
     * @notice get the factory address
     * @return address of the factory
     */
    function factory() external view returns (address);

    /**
     * @notice get the token0 address
     * @return address of the token0
     */
    function token0() external view returns (address);

    /**
     * @notice get the token1 address
     * @return address of the token1
     */
    function token1() external view returns (address);

    /**
     * @notice called once by the factory at time of deployment
     * @param _token0 address of token0
     * @param _token1 address of token1
     * @param _feesLP uint128 feesLP numerator
     * @param _feesPool uint128 feesPool numerator
     */
    function initialize(address _token0, address _token1, uint128 _feesLP, uint128 _feesPool) external;

    /**
     * @notice return current Reserves of both token in the pair,
     *  corresponding to token balance - pending fees
     * @return reserve0_ current reserve of token0 - pending fee0
     * @return reserve1_ current reserve of token1 - pending fee1
     */
    function getReserves() external view returns (uint256 reserve0_, uint256 reserve1_);

    /**
     * @notice return current fictive reserves of both token in the pair
     * @return fictiveReserve0_ current fictive reserve of token0
     * @return fictiveReserve1_ current fictive reserve of token1
     */
    function getFictiveReserves() external view returns (uint256 fictiveReserve0_, uint256 fictiveReserve1_);

    /**
     * @notice return current pending fees of both token in the pair
     * @return fees0_ current pending fees of token0
     * @return fees1_ current pending fees of token1
     */
    function getFeeToAmounts() external view returns (uint256 fees0_, uint256 fees1_);

    /**
     * @notice return numerators of pair fees, denominator is 1_000_000
     * @return feesLP_ numerator of fees sent to LP
     * @return feesPool_ numerator of fees sent to Pool
     */
    function getPairFees() external view returns (uint128 feesLP_, uint128 feesPool_);

    /**
     * @notice return last updated price average at timestamp of both token in the pair,
     *  read price0Average/price1Average for current price of token0/token1
     * @return priceAverage0_ current price for token0
     * @return priceAverage1_ current price for token1
     * @return blockTimestampLast_ last block timestamp when price was updated
     */
    function getPriceAverage()
        external
        view
        returns (uint256 priceAverage0_, uint256 priceAverage1_, uint256 blockTimestampLast_);

    /**
     * @notice return current price average of both token in the pair for provided currentTimeStamp
     *  read price0Average/price1Average for current price of token0/token1
     * @param _fictiveReserveIn,
     * @param _fictiveReserveOut,
     * @param _priceAverageLastTimestamp,
     * @param _priceAverageIn current price for token0
     * @param _priceAverageOut current price for token1
     * @param _currentTimestamp block timestamp to get price
     * @return priceAverageIn_ current price for token0
     * @return priceAverageOut_ current price for token1
     */
    function getUpdatedPriceAverage(
        uint256 _fictiveReserveIn,
        uint256 _fictiveReserveOut,
        uint256 _priceAverageLastTimestamp,
        uint256 _priceAverageIn,
        uint256 _priceAverageOut,
        uint256 _currentTimestamp
    ) external pure returns (uint256 priceAverageIn_, uint256 priceAverageOut_);

    /**
     * @notice Mint lp tokens proportionally of added tokens in balance. Should be called from a contract
     * that makes safety checks like the SmardexRouter
     * @param _to address who will receive minted tokens
     * @param _amount0 amount of token0 to provide
     * @param _amount1 amount of token1 to provide
     * @return liquidity_ amount of lp tokens minted and sent to the address defined in parameter
     */
    function mint(
        address _to,
        uint256 _amount0,
        uint256 _amount1,
        address _payer
    ) external returns (uint256 liquidity_);

    /**
     * @notice Burn lp tokens in the balance of the contract. Sends to the defined address the amount of token0 and
     * token1 proportionally of the amount burned. Should be called from a contract that makes safety checks like the
     * SmardexRouter
     * @param _to address who will receive tokens
     * @return amount0_ amount of token0 sent to the address defined in parameter
     * @return amount1_ amount of token0 sent to the address defined in parameter
     */
    function burn(address _to) external returns (uint256 amount0_, uint256 amount1_);

    /**
     * @notice Swaps tokens. Sends to the defined address the amount of token0 and token1 defined in parameters.
     * Tokens to trade should be already sent in the contract.
     * Swap function will check if the resulted balance is correct with current reserves and reserves fictive.
     * Should be called from a contract that makes safety checks like the SmardexRouter
     * @param _to address who will receive tokens
     * @param _zeroForOne token0 to token1
     * @param _amountSpecified amount of token wanted
     * @param _data used for flash swap, data.length must be 0 for regular swap
     */
    function swap(
        address _to,
        bool _zeroForOne,
        int256 _amountSpecified,
        bytes calldata _data
    ) external returns (int256 amount0_, int256 amount1_);

    /**
     * @notice set feesLP and feesPool of the pair
     * @notice sum of new feesLp and feesPool must be <= 100_000
     * @param _feesLP new numerator of fees sent to LP, must be >= 1
     * @param _feesPool new numerator of fees sent to Pool, could be = 0
     */
    function setFees(uint128 _feesLP, uint128 _feesPool) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.17;

interface ISmardexSwapCallback {
    /**
     * @notice callback data for swap from SmardexRouter
     * @param path path of the swap, array of token addresses tightly packed
     * @param payer address of the payer for the swap
     */
    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    /**
     * @notice callback data for swap
     * @param _amount0Delta amount of token0 for the swap (negative is incoming, positive is required to pay to pair)
     * @param _amount1Delta amount of token1 for the swap (negative is incoming, positive is required to pay to pair)
     * @param _data for Router path and payer for the swap (see router for details)
     */
    function smardexSwapCallback(int256 _amount0Delta, int256 _amount1Delta, bytes calldata _data) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

// libraries
import "@openzeppelin/contracts/utils/math/Math.sol";

// interfaces
import "../interfaces/ISmardexPair.sol";

library SmardexLibrary {
    /// @notice base of the FEES
    uint256 public constant FEES_BASE = 1_000_000;

    /// @notice max fees of feesLP and feesPool sum, 10% FEES_BASE
    uint256 public constant FEES_MAX = FEES_BASE / 10;

    /// @notice precision for approxEq, not in percent but in APPROX_PRECISION_BASE
    uint256 public constant APPROX_PRECISION = 1;

    /// @notice base of the APPROX_PRECISION
    uint256 public constant APPROX_PRECISION_BASE = 1_000_000;

    /// @notice number of seconds to reset priceAverage
    uint256 private constant MAX_BLOCK_DIFF_SECONDS = 300;

    /// @notice parameters of getAmountIn and getAmountOut
    struct GetAmountParameters {
        uint256 amount;
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 fictiveReserveIn;
        uint256 fictiveReserveOut;
        uint256 priceAverageIn;
        uint256 priceAverageOut;
        uint128 feesLP;
        uint128 feesPool;
    }

    /**
     * @notice check if 2 numbers are approximately equal, using APPROX_PRECISION
     * @param _x number to compare
     * @param _y number to compare
     * @return true if numbers are approximately equal, false otherwise
     */
    function approxEq(uint256 _x, uint256 _y) internal pure returns (bool) {
        if (_x > _y) {
            return _x < (_y + (_y * APPROX_PRECISION) / APPROX_PRECISION_BASE);
        } else {
            return _y < (_x + (_x * APPROX_PRECISION) / APPROX_PRECISION_BASE);
        }
    }

    /**
     * @notice check if 2 ratio are approximately equal: _xNum _/ xDen ~= _yNum / _yDen
     * @param _xNum numerator of the first ratio to compare
     * @param _xDen denominator of the first ratio to compare
     * @param _yNum numerator of the second ratio to compare
     * @param _yDen denominator of the second ratio to compare
     * @return true if ratio are approximately equal, false otherwise
     */
    function ratioApproxEq(uint256 _xNum, uint256 _xDen, uint256 _yNum, uint256 _yDen) internal pure returns (bool) {
        return approxEq(_xNum * _yDen, _xDen * _yNum);
    }

    /**
     * @notice update priceAverage given old timestamp, new timestamp and prices
     * @param _fictiveReserveIn ratio component of the new price of the in-token
     * @param _fictiveReserveOut ratio component of the new price of the out-token
     * @param _priceAverageLastTimestamp timestamp of the last priceAverage update (0, if never updated)
     * @param _priceAverageIn ratio component of the last priceAverage of the in-token
     * @param _priceAverageOut ratio component of the last priceAverage of the out-token
     * @param _currentTimestamp timestamp of the priceAverage to update
     * @return newPriceAverageIn_ ratio component of the updated priceAverage of the in-token
     * @return newPriceAverageOut_ ratio component of the updated priceAverage of the out-token
     */
    function getUpdatedPriceAverage(
        uint256 _fictiveReserveIn,
        uint256 _fictiveReserveOut,
        uint256 _priceAverageLastTimestamp,
        uint256 _priceAverageIn,
        uint256 _priceAverageOut,
        uint256 _currentTimestamp
    ) internal pure returns (uint256 newPriceAverageIn_, uint256 newPriceAverageOut_) {
        require(_currentTimestamp >= _priceAverageLastTimestamp, "SmardexPair: INVALID_TIMESTAMP");

        // very first time
        if (_priceAverageLastTimestamp == 0) {
            newPriceAverageIn_ = _fictiveReserveIn;
            newPriceAverageOut_ = _fictiveReserveOut;
        }
        // another tx has been done in the same timestamp
        else if (_priceAverageLastTimestamp == _currentTimestamp) {
            newPriceAverageIn_ = _priceAverageIn;
            newPriceAverageOut_ = _priceAverageOut;
        }
        // need to compute new linear-average price
        else {
            // compute new price:
            uint256 _timeDiff = Math.min(_currentTimestamp - _priceAverageLastTimestamp, MAX_BLOCK_DIFF_SECONDS);

            newPriceAverageIn_ = _fictiveReserveIn;
            newPriceAverageOut_ =
                (((MAX_BLOCK_DIFF_SECONDS - _timeDiff) * _priceAverageOut * newPriceAverageIn_) /
                    _priceAverageIn +
                    _timeDiff *
                    _fictiveReserveOut) /
                MAX_BLOCK_DIFF_SECONDS;
        }
    }

    /**
     * @notice compute the firstTradeAmountIn so that the price reach the price Average
     * @param _param contain all params required from struct GetAmountParameters
     * @return firstAmountIn_ the first amount of in-token
     *
     * @dev if the trade is going in the direction that the price will never reach the priceAverage, or if _amountIn
     * is not big enough to reach the priceAverage or if the price is already equal to the priceAverage, then
     * firstAmountIn_ will be set to _amountIn
     */
    function computeFirstTradeQtyIn(GetAmountParameters memory _param) internal pure returns (uint256 firstAmountIn_) {
        // default value
        firstAmountIn_ = _param.amount;

        // if trade is in the good direction
        if (_param.fictiveReserveOut * _param.priceAverageIn > _param.fictiveReserveIn * _param.priceAverageOut) {
            // pre-compute all operands
            uint256 _toSub = _param.fictiveReserveIn * ((FEES_BASE * 2) - (_param.feesPool * 2) - _param.feesLP);
            uint256 _toDiv = (FEES_BASE - _param.feesPool) * 2;
            uint256 _inSqrt = (((_param.fictiveReserveIn * _param.fictiveReserveOut) * 4) / _param.priceAverageOut) *
                _param.priceAverageIn *
                ((FEES_BASE - _param.feesPool - _param.feesLP) * (FEES_BASE - _param.feesPool)) +
                ((_param.fictiveReserveIn * _param.fictiveReserveIn) * (_param.feesLP * _param.feesLP));

            // reverse sqrt check to only compute sqrt if really needed
            uint256 _inSqrtCompare = _toSub + _param.amount * _toDiv;
            if (_inSqrt < _inSqrtCompare * _inSqrtCompare) {
                firstAmountIn_ = (Math.sqrt(_inSqrt) - _toSub) / _toDiv;
            }
        }
    }

    /**
     * @notice compute the firstTradeAmountOut so that the price reach the price Average
     * @param _param contain all params required from struct GetAmountParameters
     * @return firstAmountOut_ the first amount of out-token
     *
     * @dev if the trade is going in the direction that the price will never reach the priceAverage, or if _amountOut
     * is not big enough to reach the priceAverage or if the price is already equal to the priceAverage, then
     * firstAmountOut_ will be set to _amountOut
     */
    function computeFirstTradeQtyOut(
        GetAmountParameters memory _param
    ) internal pure returns (uint256 firstAmountOut_) {
        // default value
        firstAmountOut_ = _param.amount;
        uint256 _reverseFeesTotal = FEES_BASE - _param.feesPool - _param.feesLP;
        // if trade is in the good direction
        if (_param.fictiveReserveOut * _param.priceAverageIn > _param.fictiveReserveIn * _param.priceAverageOut) {
            // pre-compute all operands
            uint256 _fictiveReserveOutPredFees = (_param.fictiveReserveIn * _param.feesLP * _param.priceAverageOut) /
                _param.priceAverageIn;
            uint256 _toAdd = ((_param.fictiveReserveOut * _reverseFeesTotal) * 2) + _fictiveReserveOutPredFees;
            uint256 _toDiv = _reverseFeesTotal * 2;

            uint256 _inSqrt = (((_param.fictiveReserveOut * _fictiveReserveOutPredFees) * 4) *
                (_reverseFeesTotal * (FEES_BASE - _param.feesPool))) /
                _param.feesLP +
                (_fictiveReserveOutPredFees * _fictiveReserveOutPredFees);

            // reverse sqrt check to only compute sqrt if really needed
            uint256 _inSqrtCompare = _toAdd - _param.amount * _toDiv;
            if (_inSqrt > _inSqrtCompare * _inSqrtCompare) {
                firstAmountOut_ = (_toAdd - Math.sqrt(_inSqrt)) / _toDiv;
            }
        }
    }

    /**
     * @notice compute fictive reserves
     * @param _reserveIn reserve of the in-token
     * @param _reserveOut reserve of the out-token
     * @param _fictiveReserveIn fictive reserve of the in-token
     * @param _fictiveReserveOut fictive reserve of the out-token
     * @return newFictiveReserveIn_ new fictive reserve of the in-token
     * @return newFictiveReserveOut_ new fictive reserve of the out-token
     */
    function computeFictiveReserves(
        uint256 _reserveIn,
        uint256 _reserveOut,
        uint256 _fictiveReserveIn,
        uint256 _fictiveReserveOut
    ) internal pure returns (uint256 newFictiveReserveIn_, uint256 newFictiveReserveOut_) {
        if (_reserveOut * _fictiveReserveIn < _reserveIn * _fictiveReserveOut) {
            uint256 _temp = (((_reserveOut * _reserveOut) / _fictiveReserveOut) * _fictiveReserveIn) / _reserveIn;
            newFictiveReserveIn_ =
                (_temp * _fictiveReserveIn) /
                _fictiveReserveOut +
                (_reserveOut * _fictiveReserveIn) /
                _fictiveReserveOut;
            newFictiveReserveOut_ = _reserveOut + _temp;
        } else {
            newFictiveReserveIn_ = (_fictiveReserveIn * _reserveOut) / _fictiveReserveOut + _reserveIn;
            newFictiveReserveOut_ = (_reserveIn * _fictiveReserveOut) / _fictiveReserveIn + _reserveOut;
        }

        // div all values by 4
        newFictiveReserveIn_ /= 4;
        newFictiveReserveOut_ /= 4;
    }

    /**
     * @notice apply k const rule using fictive reserve, when the amountIn is specified
     * @param _param contain all params required from struct GetAmountParameters
     * @return amountOut_ qty of token that leaves in the contract
     * @return newReserveIn_ new reserve of the in-token after the transaction
     * @return newReserveOut_ new reserve of the out-token after the transaction
     * @return newFictiveReserveIn_ new fictive reserve of the in-token after the transaction
     * @return newFictiveReserveOut_ new fictive reserve of the out-token after the transaction
     */
    function applyKConstRuleOut(
        GetAmountParameters memory _param
    )
        internal
        pure
        returns (
            uint256 amountOut_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        )
    {
        // k const rule
        uint256 _amountInWithFee = _param.amount * (FEES_BASE - _param.feesLP - _param.feesPool);
        uint256 _numerator = _amountInWithFee * _param.fictiveReserveOut;
        uint256 _denominator = _param.fictiveReserveIn * FEES_BASE + _amountInWithFee;
        amountOut_ = _numerator / _denominator;

        // update new reserves and add lp-fees to pools
        uint256 _amountInWithFeeLp = (_amountInWithFee + (_param.amount * _param.feesLP)) / FEES_BASE;
        newReserveIn_ = _param.reserveIn + _amountInWithFeeLp;
        newFictiveReserveIn_ = _param.fictiveReserveIn + _amountInWithFeeLp;
        newReserveOut_ = _param.reserveOut - amountOut_;
        newFictiveReserveOut_ = _param.fictiveReserveOut - amountOut_;
    }

    /**
     * @notice apply k const rule using fictive reserve, when the amountOut is specified
     * @param _param contain all params required from struct GetAmountParameters
     * @return amountIn_ qty of token that arrives in the contract
     * @return newReserveIn_ new reserve of the in-token after the transaction
     * @return newReserveOut_ new reserve of the out-token after the transaction
     * @return newFictiveReserveIn_ new fictive reserve of the in-token after the transaction
     * @return newFictiveReserveOut_ new fictive reserve of the out-token after the transaction
     */
    function applyKConstRuleIn(
        GetAmountParameters memory _param
    )
        internal
        pure
        returns (
            uint256 amountIn_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        )
    {
        // k const rule
        uint256 _numerator = _param.fictiveReserveIn * _param.amount * FEES_BASE;
        uint256 _denominator = (_param.fictiveReserveOut - _param.amount) *
            (FEES_BASE - _param.feesPool - _param.feesLP);
        amountIn_ = _numerator / _denominator + 1;

        // update new reserves
        uint256 _amountInWithFeeLp = (amountIn_ * (FEES_BASE - _param.feesPool)) / FEES_BASE;
        newReserveIn_ = _param.reserveIn + _amountInWithFeeLp;
        newFictiveReserveIn_ = _param.fictiveReserveIn + _amountInWithFeeLp;
        newReserveOut_ = _param.reserveOut - _param.amount;
        newFictiveReserveOut_ = _param.fictiveReserveOut - _param.amount;
    }

    /**
     * @notice return the amount of tokens the user would get by doing a swap
     * @param _param contain all params required from struct GetAmountParameters
     * @return amountOut_ The amount of token the user would receive
     * @return newReserveIn_ reserves of the selling token after the swap
     * @return newReserveOut_ reserves of the buying token after the swap
     * @return newFictiveReserveIn_ fictive reserve of the selling token after the swap
     * @return newFictiveReserveOut_ fictive reserve of the buying token after the swap
     */
    function getAmountOut(
        GetAmountParameters memory _param
    )
        internal
        pure
        returns (
            uint256 amountOut_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        )
    {
        require(_param.amount != 0, "SmarDexLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            _param.reserveIn != 0 &&
                _param.reserveOut != 0 &&
                _param.fictiveReserveIn != 0 &&
                _param.fictiveReserveOut != 0,
            "SmarDexLibrary: INSUFFICIENT_LIQUIDITY"
        );

        uint256 _amountInWithFees = (_param.amount * (FEES_BASE - _param.feesPool - _param.feesLP)) / FEES_BASE;
        uint256 _firstAmountIn = computeFirstTradeQtyIn(
            SmardexLibrary.GetAmountParameters({
                amount: _amountInWithFees,
                reserveIn: _param.reserveIn,
                reserveOut: _param.reserveOut,
                fictiveReserveIn: _param.fictiveReserveIn,
                fictiveReserveOut: _param.fictiveReserveOut,
                priceAverageIn: _param.priceAverageIn,
                priceAverageOut: _param.priceAverageOut,
                feesLP: _param.feesLP,
                feesPool: _param.feesPool
            })
        );

        // if there is 2 trade: 1st trade mustn't re-compute fictive reserves, 2nd should
        if (
            _firstAmountIn == _amountInWithFees &&
            ratioApproxEq(
                _param.fictiveReserveIn,
                _param.fictiveReserveOut,
                _param.priceAverageIn,
                _param.priceAverageOut
            )
        ) {
            (_param.fictiveReserveIn, _param.fictiveReserveOut) = computeFictiveReserves(
                _param.reserveIn,
                _param.reserveOut,
                _param.fictiveReserveIn,
                _param.fictiveReserveOut
            );
        }

        // avoid stack too deep
        {
            uint256 _firstAmountInNoFees = (_firstAmountIn * FEES_BASE) / (FEES_BASE - _param.feesPool - _param.feesLP);
            (
                amountOut_,
                newReserveIn_,
                newReserveOut_,
                newFictiveReserveIn_,
                newFictiveReserveOut_
            ) = applyKConstRuleOut(
                SmardexLibrary.GetAmountParameters({
                    amount: _firstAmountInNoFees,
                    reserveIn: _param.reserveIn,
                    reserveOut: _param.reserveOut,
                    fictiveReserveIn: _param.fictiveReserveIn,
                    fictiveReserveOut: _param.fictiveReserveOut,
                    priceAverageIn: _param.priceAverageIn,
                    priceAverageOut: _param.priceAverageOut,
                    feesLP: _param.feesLP,
                    feesPool: _param.feesPool
                })
            );

            // update amountIn in case there is a second trade
            _param.amount -= _firstAmountInNoFees;
        }

        // if we need a second trade
        if (_firstAmountIn < _amountInWithFees) {
            // in the second trade ALWAYS recompute fictive reserves
            (newFictiveReserveIn_, newFictiveReserveOut_) = computeFictiveReserves(
                newReserveIn_,
                newReserveOut_,
                newFictiveReserveIn_,
                newFictiveReserveOut_
            );

            uint256 _secondAmountOutNoFees;
            (
                _secondAmountOutNoFees,
                newReserveIn_,
                newReserveOut_,
                newFictiveReserveIn_,
                newFictiveReserveOut_
            ) = applyKConstRuleOut(
                SmardexLibrary.GetAmountParameters({
                    amount: _param.amount,
                    reserveIn: newReserveIn_,
                    reserveOut: newReserveOut_,
                    fictiveReserveIn: newFictiveReserveIn_,
                    fictiveReserveOut: newFictiveReserveOut_,
                    priceAverageIn: _param.priceAverageIn,
                    priceAverageOut: _param.priceAverageOut,
                    feesLP: _param.feesLP,
                    feesPool: _param.feesPool
                })
            );
            amountOut_ += _secondAmountOutNoFees;
        }
    }

    /**
     * @notice return the amount of tokens the user should spend by doing a swap
     * @param _param contain all params required from struct GetAmountParameters
     * @return amountIn_ The amount of token the user would spend to receive _amountOut
     * @return newReserveIn_ reserves of the selling token after the swap
     * @return newReserveOut_ reserves of the buying token after the swap
     * @return newFictiveReserveIn_ fictive reserve of the selling token after the swap
     * @return newFictiveReserveOut_ fictive reserve of the buying token after the swap
     */
    function getAmountIn(
        GetAmountParameters memory _param
    )
        internal
        pure
        returns (
            uint256 amountIn_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        )
    {
        require(_param.amount != 0, "SmarDexLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            _param.amount < _param.fictiveReserveOut &&
                _param.reserveIn != 0 &&
                _param.reserveOut != 0 &&
                _param.fictiveReserveIn != 0 &&
                _param.fictiveReserveOut != 0,
            "SmarDexLibrary: INSUFFICIENT_LIQUIDITY"
        );

        uint256 _firstAmountOut = computeFirstTradeQtyOut(_param);

        // if there is 2 trade: 1st trade mustn't re-compute fictive reserves, 2nd should
        if (
            _firstAmountOut == _param.amount &&
            ratioApproxEq(
                _param.fictiveReserveIn,
                _param.fictiveReserveOut,
                _param.priceAverageIn,
                _param.priceAverageOut
            )
        ) {
            (_param.fictiveReserveIn, _param.fictiveReserveOut) = computeFictiveReserves(
                _param.reserveIn,
                _param.reserveOut,
                _param.fictiveReserveIn,
                _param.fictiveReserveOut
            );
        }

        (amountIn_, newReserveIn_, newReserveOut_, newFictiveReserveIn_, newFictiveReserveOut_) = applyKConstRuleIn(
            SmardexLibrary.GetAmountParameters({
                amount: _firstAmountOut,
                reserveIn: _param.reserveIn,
                reserveOut: _param.reserveOut,
                fictiveReserveIn: _param.fictiveReserveIn,
                fictiveReserveOut: _param.fictiveReserveOut,
                priceAverageIn: _param.priceAverageIn,
                priceAverageOut: _param.priceAverageOut,
                feesLP: _param.feesLP,
                feesPool: _param.feesPool
            })
        );

        // if we need a second trade
        if (_firstAmountOut < _param.amount) {
            // in the second trade ALWAYS recompute fictive reserves
            (newFictiveReserveIn_, newFictiveReserveOut_) = computeFictiveReserves(
                newReserveIn_,
                newReserveOut_,
                newFictiveReserveIn_,
                newFictiveReserveOut_
            );

            uint256 _secondAmountIn;
            (
                _secondAmountIn,
                newReserveIn_,
                newReserveOut_,
                newFictiveReserveIn_,
                newFictiveReserveOut_
            ) = applyKConstRuleIn(
                SmardexLibrary.GetAmountParameters({
                    amount: _param.amount - _firstAmountOut,
                    reserveIn: newReserveIn_,
                    reserveOut: newReserveOut_,
                    fictiveReserveIn: newFictiveReserveIn_,
                    fictiveReserveOut: newFictiveReserveOut_,
                    priceAverageIn: _param.priceAverageIn,
                    priceAverageOut: _param.priceAverageOut,
                    feesLP: _param.feesLP,
                    feesPool: _param.feesPool
                })
            );
            amountIn_ += _secondAmountIn;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

/**
 * @title TransferHelper
 * @notice helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
 * @custom:from Uniswap lib, adapted to version 0.8.17
 * @custom:url https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
 */
library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.17;

// interfaces
import "../../core/interfaces/ISmardexSwapCallback.sol";
import "../../core/interfaces/ISmardexMintCallback.sol";
import "../../core/libraries/SmardexLibrary.sol";

interface ISmardexRouter is ISmardexSwapCallback, ISmardexMintCallback {
    /**
     * @notice get the factory address
     * @return address of the factory
     */
    function factory() external view returns (address);

    /**
     * @notice get WETH address
     * @return address of the WETH token (Wrapped Ether)
     */
    function WETH() external view returns (address);

    /**
     * @notice Add liquidity to an ERC-20=ERC-20 pool. Receive liquidity token to materialize shares in the pool
     * @param _tokenA address of the first token in the pair
     * @param _tokenB address of the second token in the pair
     * @param _amountADesired The amount of tokenA to add as liquidity
     * if the B/A price is <= amountBDesired/amountADesired
     * @param _amountBDesired The amount of tokenB to add as liquidity
     * if the A/B price is <= amountADesired/amountBDesired
     * @param _amountAMin Bounds the extent to which the B/A price can go up before the transaction reverts.
     * Must be <= amountADesired.
     * @param _amountBMin Bounds the extent to which the A/B price can go up before the transaction reverts.
     * Must be <= amountBDesired.
     * @param _to Recipient of the liquidity tokens.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @return amountA_ The amount of tokenA sent to the pool.
     * @return amountB_ The amount of tokenB sent to the pool.
     * @return liquidity_ The amount of liquidity tokens minted.
     */
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountA_, uint256 amountB_, uint256 liquidity_);

    /**
     * @notice Adds liquidity to an ERC-20=WETH pool with ETH. msg.value is the amount of ETH to add as liquidity.
     * if the token/WETH price is <= amountTokenDesired/msg.value (WETH depreciates).
     * @param _token A pool token.
     * @param _amountTokenDesired The amount of token to add as liquidity if the WETH/token price
     * is <= msg.value/amountTokenDesired (token depreciates).
     * @param _amountTokenMin Bounds the extent to which the WETH/token price can go up before the transaction reverts.
     * Must be <= amountTokenDesired.
     * @param _amountETHMin Bounds the extent to which the token/WETH price can go up before the transaction reverts.
     * Must be <= msg.value.
     * @param _to Recipient of the liquidity tokens.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @return amountToken_ The amount of token sent to the pool.
     * @return amountETH_ The amount of ETH converted to WETH and sent to the pool.
     * @return liquidity_ The amount of liquidity tokens minted.
     */
    function addLiquidityETH(
        address _token,
        uint256 _amountTokenDesired,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256 amountToken_, uint256 amountETH_, uint256 liquidity_);

    /**
     * @notice Removes liquidity from an ERC-20=ERC-20 pool.
     * @param _tokenA A pool token.
     * @param _tokenB A pool token.
     * @param _liquidity The amount of liquidity tokens to remove.
     * @param _amountAMin The minimum amount of tokenA that must be received for the transaction not to revert.
     * @param _amountBMin The minimum amount of tokenB that must be received for the transaction not to revert.
     * @param _to Recipient of the liquidity tokens.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @return amountA_ The amount of tokenA received.
     * @return amountB_ The amount of tokenB received.
     */
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountA_, uint256 amountB_);

    /**
     * @notice Removes liquidity from an ERC-20=WETH pool and receive ETH.
     * @param _token A pool token.
     * @param _liquidity The amount of liquidity tokens to remove.
     * @param _amountTokenMin The minimum amount of token that must be received for the transaction not to revert.
     * @param _amountETHMin The minimum amount of ETH that must be received for the transaction not to revert.
     * @param _to Recipient of the liquidity tokens.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @return amountToken_ The amount of token received.
     * @return amountETH_ The amount of ETH received.
     */
    function removeLiquidityETH(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountToken_, uint256 amountETH_);

    /**
     * @notice Removes liquidity from an ERC-20=WETH pool and receive ETH.
     * @param _tokenA A pool token.
     * @param _tokenB A pool token.
     * @param _liquidity The amount of liquidity tokens to remove.
     * @param _amountAMin The minimum amount of tokenA that must be received for the transaction not to revert.
     * @param _amountBMin The minimum amount of tokenB that must be received for the transaction not to revert.
     * @param _to Recipient of the liquidity tokens.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @param _approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1).
     * @param _v The v component of the permit signature.
     * @param _r The r component of the permit signature.
     * @param _s The s component of the permit signature.
     * @return amountA_ The amount of tokenA received.
     * @return amountB_ The amount of tokenB received.
     */
    function removeLiquidityWithPermit(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 amountA_, uint256 amountB_);

    /**
     * @notice Removes liquidity from an ERC-20=WETH pool and receive ETH without pre-approval
     * @param _token A pool token.
     * @param _liquidity The amount of liquidity tokens to remove.
     * @param _amountTokenMin The minimum amount of token that must be received for the transaction not to revert.
     * @param _amountETHMin The minimum amount of ETH that must be received for the transaction not to revert.
     * @param _to Recipient of the liquidity tokens.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @param _approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1).
     * @param _v The v component of the permit signature.
     * @param _r The r component of the permit signature.
     * @param _s The s component of the permit signature.
     * @return amountToken_ The amount of token received.
     * @return amountETH_ The amount of ETH received.
     */
    function removeLiquidityETHWithPermit(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 amountToken_, uint256 amountETH_);

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined
     * by the path. The first element of path is the input token, the last is the output token, and any intermediate
     * elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
     * @param _amountIn The amount of input tokens to send.
     * @param _amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param _path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
     * must exist and have liquidity.
     * @param _to Recipient of the output tokens.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @return amountOut_ The output token amount.
     */
    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountOut_);

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible, along the route determined
     * by the path. The first element of path is the input token, the last is the output token, and any intermediate
     * elements represent intermediate tokens to trade through (if, for example, a direct pair does not exist).
     * @param _amountOut The amount of output tokens to receive.
     * @param _amountInMax The maximum amount of input tokens that can be required before the transaction reverts.
     * @param _path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
     * must exist and have liquidity.
     * @param _to Recipient of the output tokens.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @return amountIn_ The input token amount.
     */
    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountIn_);

    /**
     * @notice Swaps an exact amount of ETH for as many output tokens as possible, along the route determined by the
     * path. The first element of path must be WETH, the last is the output token, and any intermediate elements
     * represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
     * @param _amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param _path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
     * must exist and have liquidity.
     * @param _to Recipient of the output tokens.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @return amountOut_ The input token amount.
     */
    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256 amountOut_);

    /**
     * @notice Receive an exact amount of ETH for as few input tokens as possible, along the route determined by the
     * path. The first element of path is the input token, the last must be WETH, and any intermediate elements
     * represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
     * @param _amountOut The amount of ETH to receive.
     * @param _amountInMax The maximum amount of input tokens that can be required before the transaction reverts.
     * @param _path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
     * must exist and have liquidity.
     * @param _to Recipient of ETH.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @return amountIn_ The input token amount.
     */
    function swapTokensForExactETH(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountIn_);

    /**
     * @notice Swaps an exact amount of tokens for as much ETH as possible, along the route determined by the path.
     * The first element of path is the input token, the last must be WETH, and any intermediate elements represent
     * intermediate pairs to trade through (if, for example, a direct pair does not exist).
     * @param _amountIn The amount of input tokens to send.
     * @param _amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param _path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
     * must exist and have liquidity.
     * @param _to Recipient of ETH.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @return amountOut_ The input token amount.
     */
    function swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountOut_);

    /**
     * @notice Receive an exact amount of tokens for as little ETH as possible, along the route determined by the path.
     * The first element of path must be WETH, the last is the output token and any intermediate elements represent
     * intermediate pairs to trade through (if, for example, a direct pair does not exist).
     * msg.value The maximum amount of ETH that can be required before the transaction reverts.
     * @param _amountOut The amount of tokens to receive.
     * @param _path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
     * must exist and have liquidity.
     * @param _to Recipient of output tokens.
     * @param _deadline Unix timestamp after which the transaction will revert.
     * @return amountIn_ The input token amount.
     */
    function swapETHForExactTokens(
        uint256 _amountOut,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256 amountIn_);

    /**
     * @notice Given some asset amount and reserves, returns an amount of the other asset representing equivalent value.
     */
    function quote(
        uint256 _amountA,
        uint256 _fictiveReserveA,
        uint256 _fictiveReserveB
    ) external pure returns (uint256 amountB_);

    /**
     * @notice return the amount of tokens the user would get by doing a swap
     * @param _param all the parameters required to get amount from struct GetAmountParameters
     * @return amountOut_ The amount of token the user would receive
     * @return newReserveIn_ reserves of the selling token after the swap
     * @return newReserveOut_ reserves of the buying token after the swap
     * @return newFictiveReserveIn_ fictive reserve of the selling token after the swap
     * @return newFictiveReserveOut_ fictive reserve of the buying token after the swap
     */
    function getAmountOut(
        SmardexLibrary.GetAmountParameters memory _param
    )
        external
        pure
        returns (
            uint256 amountOut_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        );

    /**
     * @notice return the amount of tokens the user should spend by doing a swap
     * @param _param all the parameters required to get amount from struct GetAmountParameters
     * @return amountIn_ The amount of token the user would spend to receive _amountOut
     * @return newReserveIn_ reserves of the selling token after the swap
     * @return newReserveOut_ reserves of the buying token after the swap
     * @return newFictiveReserveIn_ fictive reserve of the selling token after the swap
     * @return newFictiveReserveOut_ fictive reserve of the buying token after the swap
     */
    function getAmountIn(
        SmardexLibrary.GetAmountParameters memory _param
    )
        external
        pure
        returns (
            uint256 amountIn_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        );

    /**
     * @notice return the amount of tokens the user should spend by doing a swap by directly
     *              fetching data from the pair tokenIn/tokenOut
     * @param _amountIn quantity of token the user want to swap (to buy)
     * @param _tokenIn address of the token the user want to sell
     * @param _tokenOut address of the token the user want to buy
     * @return amountOut_ The amount of token the user would receive
     * @return newReserveIn_ reserves of the selling token after the swap
     * @return newReserveOut_ reserves of the buying token after the swap
     * @return newFictiveReserveIn_ fictive reserve of the selling token after the swap
     * @return newFictiveReserveOut_ fictive reserve of the buying token after the swap
     */
    function getAmountOutFromPair(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    )
        external
        view
        returns (
            uint256 amountOut_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        );

    /**
     * @notice return the amount of tokens the user should spend by doing a swap by directly
     *              fetching data from the pair tokenIn/tokenOut
     * @param _amountOut quantity of token the user want to swap (to sell)
     * @param _tokenIn address of the token the user want to sell
     * @param _tokenOut address of the token the user want to buy
     * @return amountIn_ The amount of token the user would spend to receive _amountOut
     * @return newReserveIn_ reserves of the selling token after the swap
     * @return newReserveOut_ reserves of the buying token after the swap
     * @return newFictiveReserveIn_ fictive reserve of the selling token after the swap
     * @return newFictiveReserveOut_ fictive reserve of the buying token after the swap
     */
    function getAmountInFromPair(
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut
    )
        external
        view
        returns (
            uint256 amountIn_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        );
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.17;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/**
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 * @custom:url https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
library BytesLib {
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

// libraries
import "./BytesLib.sol";

/**
 * @title Functions for manipulating path data for multihop swaps
 * @custom:from UniswapV3
 * @custom:url https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/Path.sol
 * @custom:editor SmarDex team
 */
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /// @dev The offset of a single token address
    uint256 private constant NEXT_OFFSET = ADDR_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true if the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param _path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory _path) internal pure returns (uint256) {
        return ((_path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param _path The bytes encoded swap path
    /// @return tokenA_ The first token of the given pool
    /// @return tokenB_ The second token of the given pool
    function decodeFirstPool(bytes memory _path) internal pure returns (address tokenA_, address tokenB_) {
        tokenA_ = _path.toAddress(0);
        tokenB_ = _path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param _path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory _path) internal pure returns (bytes memory) {
        return _path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token from the buffer and returns the remainder
    /// @param _path The swap path
    /// @return The remaining token elements in the path
    function skipToken(bytes memory _path) internal pure returns (bytes memory) {
        return _path.slice(NEXT_OFFSET, _path.length - NEXT_OFFSET);
    }

    /// @notice Returns the _path addresses concatenated as a packed bytes array
    /// @param _path The swap path
    /// @return encoded_ The bytes array containing the packed addresses
    function encodeTightlyPacked(address[] calldata _path) internal pure returns (bytes memory encoded_) {
        uint256 len = _path.length;
        for (uint256 i; i != len; ) {
            encoded_ = bytes.concat(encoded_, abi.encodePacked(_path[i]));
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns the _path addresses concatenated in a reversed order as a packed bytes array
    /// @param _path The swap path
    /// @return encoded_ The bytes array containing the packed addresses
    function encodeTightlyPackedReversed(address[] calldata _path) internal pure returns (bytes memory encoded_) {
        uint256 len = _path.length;
        for (uint256 i = len; i != 0; ) {
            encoded_ = bytes.concat(encoded_, abi.encodePacked(_path[i - 1]));
            unchecked {
                --i;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.17;

// libraries
import "./PoolHelpers.sol";

// interfaces
import "../../core/interfaces/ISmardexFactory.sol";

library PoolAddress {
    /**
     * @notice Deterministically computes the pool address given the factory and PoolKey
     * @param _factory The SmarDex factory contract address
     * @param _tokenA The first token of the pool
     * @param _tokenB The second token of the pool
     * @return pair_ The contract address of the SmardexPair
     */
    function pairFor(address _factory, address _tokenA, address _tokenB) internal pure returns (address pair_) {
        (address _token0, address _token1) = PoolHelpers.sortTokens(_tokenA, _tokenB);
        pair_ = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            _factory,
                            keccak256(abi.encodePacked(_token0, _token1)),
                            hex"33bee911475f015247aeb1eebe149d1c6d2669be54126c29d85df6b0abb4c4e9" // init code hash
                        )
                    )
                )
            )
        );
    }

    /**
     * @notice make a call to the factory to determine the pair address. useful for coverage test
     * @param _factory The SmarDex factory contract address
     * @param _tokenA The first token of the pool
     * @param _tokenB The second token of the pool
     * @return pair_ The contract address of the SmardexPair
     */
    function pairForByStorage(
        address _factory,
        address _tokenA,
        address _tokenB
    ) internal view returns (address pair_) {
        return ISmardexFactory(_factory).getPair(_tokenA, _tokenB);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.17;

// libraries
import "./PoolAddress.sol";
import "../../core/libraries/SmardexLibrary.sol";

// interfaces
import "../../core/interfaces/ISmardexPair.sol";

library PoolHelpers {
    /**
     * @notice sort token addresses, used to handle return values from pairs sorted in this order
     * @param _tokenA token to sort
     * @param _tokenB token to sort
     * @return token0_ token0 sorted
     * @return token1_ token1 sorted
     */
    function sortTokens(address _tokenA, address _tokenB) internal pure returns (address token0_, address token1_) {
        require(_tokenA != _tokenB, "SmardexHelper: IDENTICAL_ADDRESSES");
        (token0_, token1_) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        require(token0_ != address(0), "SmardexHelper: ZERO_ADDRESS");
    }

    /**
     * @notice fetches the reserves for a pair
     * @param _factory the factory address
     * @param _tokenA token to fetch reserves
     * @param _tokenB token to fetch reserves
     * @return reserveA_ reserves of tokenA in the pair tokenA/TokenB
     * @return reserveB_ reserves of tokenB in the pair tokenA/TokenB
     */
    function getReserves(
        address _factory,
        address _tokenA,
        address _tokenB
    ) internal view returns (uint256 reserveA_, uint256 reserveB_) {
        (address _token0, ) = sortTokens(_tokenA, _tokenB);
        (uint256 _reserve0, uint256 _reserve1) = ISmardexPair(PoolAddress.pairFor(_factory, _tokenA, _tokenB))
            .getReserves();
        (reserveA_, reserveB_) = _tokenA == _token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
    }

    /**
     * @notice fetches the fictive reserves for a pair
     * @param _factory the factory address
     * @param _tokenA token to fetch fictive reserves
     * @param _tokenB token to fetch fictive reserves
     * @return fictiveReserveA_ fictive reserves of tokenA in the pair tokenA/TokenB
     * @return fictiveReserveB_ fictive reserves of tokenB in the pair tokenA/TokenB
     */
    function getFictiveReserves(
        address _factory,
        address _tokenA,
        address _tokenB
    ) internal view returns (uint256 fictiveReserveA_, uint256 fictiveReserveB_) {
        (address _token0, ) = sortTokens(_tokenA, _tokenB);
        (uint256 _fictiveReserve0, uint256 _fictiveReserve1) = ISmardexPair(
            PoolAddress.pairFor(_factory, _tokenA, _tokenB)
        ).getFictiveReserves();
        (fictiveReserveA_, fictiveReserveB_) = _tokenA == _token0
            ? (_fictiveReserve0, _fictiveReserve1)
            : (_fictiveReserve1, _fictiveReserve0);
    }

    /**
     * @notice fetches the priceAverage for a pair
     * @param _factory the factory address
     * @param _tokenA token to fetch priceAverage
     * @param _tokenB token to fetch priceAverage
     * @return priceAverageA_ priceAverage of tokenA in the pair tokenA/TokenB
     * @return priceAverageB_ priceAverage of tokenB in the pair tokenA/TokenB
     */
    function getPriceAverage(
        address _factory,
        address _tokenA,
        address _tokenB
    ) internal view returns (uint256 priceAverageA_, uint256 priceAverageB_) {
        (address _token0, ) = sortTokens(_tokenA, _tokenB);
        (uint256 _priceAverage0, uint256 _priceAverage1, ) = ISmardexPair(
            PoolAddress.pairFor(_factory, _tokenA, _tokenB)
        ).getPriceAverage();
        (priceAverageA_, priceAverageB_) = _tokenA == _token0
            ? (_priceAverage0, _priceAverage1)
            : (_priceAverage1, _priceAverage0);
    }

    /**
     * @notice given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     * @param _amountA amount of asset A
     * @param _reserveA reserve of asset A
     * @param _reserveB reserve of asset B
     * @return amountB_ equivalent amount of asset B
     */
    function quote(uint256 _amountA, uint256 _reserveA, uint256 _reserveB) internal pure returns (uint256 amountB_) {
        require(_amountA != 0, "SmardexHelper: INSUFFICIENT_AMOUNT");
        require(_reserveA != 0 && _reserveB != 0, "SmardexHelper: INSUFFICIENT_LIQUIDITY");
        amountB_ = (_amountA * _reserveB) / _reserveA;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

// libraries
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../core/libraries/TransferHelper.sol";
import "./libraries/PoolAddress.sol";
import "./libraries/Path.sol";

// interfaces
import "../core/interfaces/ISmardexFactory.sol";
import "../core/interfaces/ISmardexPair.sol";
import "./interfaces/ISmardexRouter.sol";
import "./interfaces/IWETH.sol";

/**
 * @title SmardexRouter
 * @notice Router for execution of swaps and liquidity management on SmardexPair
 */
contract SmardexRouter is ISmardexRouter {
    using Path for bytes;
    using Path for address[];
    using SafeCast for uint256;
    using SafeCast for int256;

    address public immutable factory;
    address public immutable WETH;

    /// @dev Used as the placeholder value for amountInCached, because the computed amount in for an exact output swap
    /// can never actually be this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "SmarDexRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /// @inheritdoc ISmardexSwapCallback
    function smardexSwapCallback(int256 _amount0Delta, int256 _amount1Delta, bytes calldata _data) external override {
        require(_amount0Delta > 0 || _amount1Delta > 0, "SmardexRouter: Callback Invalid amount");

        SwapCallbackData memory _decodedData = abi.decode(_data, (SwapCallbackData));
        (address _tokenIn, address _tokenOut) = _decodedData.path.decodeFirstPool();

        // ensure that msg.sender is a pair
        require(msg.sender == PoolAddress.pairFor(factory, _tokenIn, _tokenOut), "SmarDexRouter: INVALID_PAIR");

        (bool _isExactInput, uint256 _amountToPay) = _amount0Delta > 0
            ? (_tokenIn < _tokenOut, uint256(_amount0Delta))
            : (_tokenOut < _tokenIn, uint256(_amount1Delta));

        if (_isExactInput) {
            pay(_tokenIn, _decodedData.payer, msg.sender, _amountToPay);
        } else if (_decodedData.path.hasMultiplePools()) {
            _decodedData.path = _decodedData.path.skipToken();
            _swapExactOut(_amountToPay, msg.sender, _decodedData);
        } else {
            amountInCached = _amountToPay;
            _tokenIn = _tokenOut; // swap in/out because exact output swaps are reversed
            pay(_tokenIn, _decodedData.payer, msg.sender, _amountToPay);
        }
    }

    /**
     * @notice send tokens to a user. Handle transfer/transferFrom and WETH / ETH or any ERC20 token
     * @param _token The token to pay
     * @param _payer The entity that must pay
     * @param _to The entity that will receive payment
     * @param _value The amount to pay
     *
     * @custom:from UniV3 PeripheryPayments.sol
     * @custom:url https://github.com/Uniswap/v3-periphery/blob/v1.3.0/contracts/base/PeripheryPayments.sol
     */
    function pay(address _token, address _payer, address _to, uint256 _value) internal {
        if (_token == WETH && address(this).balance >= _value) {
            // pay with WETH
            IWETH(WETH).deposit{ value: _value }(); // wrap only what is needed to pay
            IWETH(WETH).transfer(_to, _value);
            //refund dust eth, if any ?
        } else if (_payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(_token, _to, _value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(_token, _payer, _to, _value);
        }
    }

    ///@inheritdoc ISmardexMintCallback
    function smardexMintCallback(MintCallbackData calldata _data) external override {
        // ensure that msg.sender is a pair
        require(msg.sender == PoolAddress.pairFor(factory, _data.token0, _data.token1), "SmarDexRouter: INVALID_PAIR");
        require(_data.amount0 != 0 || _data.amount1 != 0, "SmardexRouter: Callback Invalid amount");

        pay(_data.token0, _data.payer, msg.sender, _data.amount0);
        pay(_data.token1, _data.payer, msg.sender, _data.amount1);
    }

    /// @inheritdoc ISmardexRouter
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) external virtual override ensure(_deadline) returns (uint256 amountA_, uint256 amountB_, uint256 liquidity_) {
        (amountA_, amountB_) = _addLiquidity(
            _tokenA,
            _tokenB,
            _amountADesired,
            _amountBDesired,
            _amountAMin,
            _amountBMin
        );
        address _pair = PoolAddress.pairFor(factory, _tokenA, _tokenB);
        bool _orderedPair = _tokenA < _tokenB;
        liquidity_ = ISmardexPair(_pair).mint(
            _to,
            _orderedPair ? amountA_ : amountB_,
            _orderedPair ? amountB_ : amountA_,
            msg.sender
        );
    }

    /// @inheritdoc ISmardexRouter
    function addLiquidityETH(
        address _token,
        uint256 _amountTokenDesired,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    )
        external
        payable
        virtual
        override
        ensure(_deadline)
        returns (uint256 amountToken_, uint256 amountETH_, uint256 liquidity_)
    {
        (amountToken_, amountETH_) = _addLiquidity(
            _token,
            WETH,
            _amountTokenDesired,
            msg.value,
            _amountTokenMin,
            _amountETHMin
        );

        address _pair = PoolAddress.pairFor(factory, _token, WETH);
        bool _orderedPair = _token < WETH;

        liquidity_ = ISmardexPair(_pair).mint(
            _to,
            _orderedPair ? amountToken_ : amountETH_,
            _orderedPair ? amountETH_ : amountToken_,
            msg.sender
        );

        // refund dust eth, if any
        if (msg.value > amountETH_) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH_);
        }
    }

    /// @inheritdoc ISmardexRouter
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) public virtual override ensure(_deadline) returns (uint256 amountA_, uint256 amountB_) {
        address _pair = PoolAddress.pairFor(factory, _tokenA, _tokenB);
        ISmardexPair(_pair).transferFrom(msg.sender, _pair, _liquidity); // send liquidity to pair

        (uint256 _amount0, uint256 _amount1) = ISmardexPair(_pair).burn(_to);
        (address _token0, ) = PoolHelpers.sortTokens(_tokenA, _tokenB);
        (amountA_, amountB_) = _tokenA == _token0 ? (_amount0, _amount1) : (_amount1, _amount0);

        require(amountA_ >= _amountAMin, "SmarDexRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB_ >= _amountBMin, "SmarDexRouter: INSUFFICIENT_B_AMOUNT");
    }

    /// @inheritdoc ISmardexRouter
    function removeLiquidityETH(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    ) public virtual override ensure(_deadline) returns (uint256 amountToken_, uint256 amountETH_) {
        (amountToken_, amountETH_) = removeLiquidity(
            _token,
            WETH,
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            address(this),
            _deadline
        );
        TransferHelper.safeTransfer(_token, _to, amountToken_);
        IWETH(WETH).withdraw(amountETH_);
        TransferHelper.safeTransferETH(_to, amountETH_);
    }

    /// @inheritdoc ISmardexRouter
    function removeLiquidityWithPermit(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual override returns (uint256 amountA_, uint256 amountB_) {
        address _pair = PoolAddress.pairFor(factory, _tokenA, _tokenB);
        uint256 _value = _approveMax ? type(uint256).max : _liquidity;
        ISmardexPair(_pair).permit(msg.sender, address(this), _value, _deadline, _v, _r, _s);
        (amountA_, amountB_) = removeLiquidity(_tokenA, _tokenB, _liquidity, _amountAMin, _amountBMin, _to, _deadline);
    }

    /// @inheritdoc ISmardexRouter
    function removeLiquidityETHWithPermit(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual override returns (uint256 amountToken_, uint256 amountETH_) {
        address _pair = PoolAddress.pairFor(factory, _token, WETH);
        uint256 _value = _approveMax ? type(uint256).max : _liquidity;
        ISmardexPair(_pair).permit(msg.sender, address(this), _value, _deadline, _v, _r, _s);
        (amountToken_, amountETH_) = removeLiquidityETH(
            _token,
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            _to,
            _deadline
        );
    }

    /// @inheritdoc ISmardexRouter
    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) public virtual override ensure(_deadline) returns (uint256 amountOut_) {
        address _payer = msg.sender; // msg.sender pays for the first hop

        bytes memory _bytesPath = _path.encodeTightlyPacked(); //could be done in the caller function
        while (true) {
            bool _hasMultiplePools = _bytesPath.hasMultiplePools();

            // the outputs of prior swaps become the inputs to subsequent ones
            _amountIn = _swapExactIn(
                _amountIn,
                // for intermediate swaps, this contract custodies
                _hasMultiplePools ? address(this) : _to,
                // only the first pool in the path is necessary
                SwapCallbackData({ path: _bytesPath.getFirstPool(), payer: _payer })
            );

            // decide whether to continue or terminate
            if (_hasMultiplePools) {
                _payer = address(this); // at this point, the caller has paid
                _bytesPath = _bytesPath.skipToken();
            } else {
                // amountOut of the final swap is the last amountIn captured in the loop
                amountOut_ = _amountIn;
                break;
            }
        }
        require(amountOut_ >= _amountOutMin, "SmarDexRouter: INSUFFICIENT_OUTPUT_AMOUNT");
    }

    /// @inheritdoc ISmardexRouter
    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) public virtual override ensure(_deadline) returns (uint256 amountIn_) {
        // Path needs to be reversed as to get the amountIn that we will ask from next pair hop
        bytes memory _reversedPath = _path.encodeTightlyPackedReversed();
        amountIn_ = _swapExactOut(_amountOut, _to, SwapCallbackData({ path: _reversedPath, payer: msg.sender }));
        // amount In is only the right one for one Hop, otherwise we need cached amountIn from callback
        if (_path.length > 2) amountIn_ = amountInCached;
        require(amountIn_ <= _amountInMax, "SmarDexRouter: EXCESSIVE_INPUT_AMOUNT");
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @inheritdoc ISmardexRouter
    function swapTokensForExactETH(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external virtual override ensure(_deadline) returns (uint256 amountIn_) {
        require(_path[_path.length - 1] == WETH, "SmarDexRouter: INVALID_PATH");
        amountIn_ = swapTokensForExactTokens(_amountOut, _amountInMax, _path, address(this), _deadline);
        _unwrapWETH(_amountOut, _to);
    }

    /// @inheritdoc ISmardexRouter
    function swapETHForExactTokens(
        uint256 _amountOut,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external payable virtual override ensure(_deadline) returns (uint256 amountIn_) {
        require(_path[0] == WETH, "SmarDexRouter: INVALID_PATH");
        amountIn_ = swapTokensForExactTokens(_amountOut, msg.value, _path, _to, _deadline);

        // Refund unused ETH
        _refundETH(msg.sender);
    }

    /// @inheritdoc ISmardexRouter
    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external payable virtual override ensure(_deadline) returns (uint256 amountOut_) {
        require(_path[0] == WETH, "SmarDexRouter: INVALID_PATH");
        amountOut_ = swapExactTokensForTokens(msg.value, _amountOutMin, _path, _to, _deadline);
    }

    /// @inheritdoc ISmardexRouter
    function swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external virtual override ensure(_deadline) returns (uint256 amountOut_) {
        require(_path[_path.length - 1] == WETH, "SmarDexRouter: INVALID_PATH");
        amountOut_ = swapExactTokensForTokens(_amountIn, _amountOutMin, _path, address(this), _deadline);
        _unwrapWETH(amountOut_, _to);
    }

    /**
     * @notice internal function to unwrap WETH to ETH after swap
     * @param _amountMinimum minimum amount of WETH that the contract should have
     * @param _to address that will receive the ETH unwrapped
     *
     * @custom:from UniV3 PeripheryPayments.sol
     * @custom:url https://github.com/Uniswap/v3-periphery/blob/v1.3.0/contracts/base/PeripheryPayments.sol
     */
    function _unwrapWETH(uint256 _amountMinimum, address _to) internal {
        uint256 _balanceWETH = IERC20(WETH).balanceOf(address(this));
        require(_balanceWETH >= _amountMinimum, "Insufficient WETH");

        if (_balanceWETH != 0) {
            IWETH(WETH).withdraw(_balanceWETH);
            TransferHelper.safeTransferETH(_to, _balanceWETH);
        }
    }

    /**
     * @notice internal function to send all ETH of the contract. Do not fail if the contract does not have any ETH
     * @param _to address that will receive the ETH
     *
     * @custom:from UniV3 PeripheryPayments.sol
     * @custom:url https://github.com/Uniswap/v3-periphery/blob/v1.3.0/contracts/base/PeripheryPayments.sol
     */
    function _refundETH(address _to) private {
        if (address(this).balance != 0) {
            TransferHelper.safeTransferETH(_to, address(this).balance);
        }
    }

    /**
     * @notice internal function to swap quantity of token to receive a determined quantity
     * @param _amountOut quantity to receive
     * @param _to address that will receive the token
     * @param _data SwapCallbackData data of the swap to transmit
     * @return amountIn_ amount of token to pay
     */
    function _swapExactOut(
        uint256 _amountOut,
        address _to,
        SwapCallbackData memory _data
    ) private returns (uint256 amountIn_) {
        require(_to != address(0), "SmarDexRouter: INVALID_RECIPIENT");

        (address _tokenOut, address _tokenIn) = _data.path.decodeFirstPool();
        bool _zeroForOne = _tokenIn < _tokenOut;

        // do the swap
        (int256 _amount0, int256 _amount1) = ISmardexPair(PoolAddress.pairFor(factory, _tokenIn, _tokenOut)).swap(
            _to,
            _zeroForOne,
            -_amountOut.toInt256(),
            abi.encode(_data)
        );

        amountIn_ = _zeroForOne ? uint256(_amount0) : uint256(_amount1);
    }

    /**
     * @notice Add liquidity to an ERC-20=ERC-20 pool. Receive liquidity token to materialize shares in the pool
     * @param _tokenA address of the first token in the pair
     * @param _tokenB address of the second token in the pair
     * @param _amountADesired The amount of tokenA to add as liquidity
     * if the B/A price is <= amountBDesired/amountADesired
     * @param _amountBDesired The amount of tokenB to add as liquidity
     * if the A/B price is <= amountADesired/amountBDesired
     * @param _amountAMin Bounds the extent to which the B/A price can go up before the transaction reverts.
     * Must be <= amountADesired.
     * @param _amountBMin Bounds the extent to which the A/B price can go up before the transaction reverts.
     * Must be <= amountBDesired.
     * @return amountA_ The amount of tokenA sent to the pool.
     * @return amountB_ The amount of tokenB sent to the pool.
     */
    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) internal virtual returns (uint256 amountA_, uint256 amountB_) {
        // create the pair if it doesn't exist yet
        if (ISmardexFactory(factory).getPair(_tokenA, _tokenB) == address(0)) {
            ISmardexFactory(factory).createPair(_tokenA, _tokenB);
        }
        (uint256 _reserveA, uint256 _reserveB) = PoolHelpers.getReserves(factory, _tokenA, _tokenB);
        if (_reserveA == 0 && _reserveB == 0) {
            (amountA_, amountB_) = (_amountADesired, _amountBDesired);
        } else {
            uint256 _amountBOptimal = PoolHelpers.quote(_amountADesired, _reserveA, _reserveB);
            if (_amountBOptimal <= _amountBDesired) {
                require(_amountBOptimal >= _amountBMin, "SmarDexRouter: INSUFFICIENT_B_AMOUNT");
                (amountA_, amountB_) = (_amountADesired, _amountBOptimal);
            } else {
                uint256 _amountAOptimal = PoolHelpers.quote(_amountBDesired, _reserveB, _reserveA);
                assert(_amountAOptimal <= _amountADesired);
                require(_amountAOptimal >= _amountAMin, "SmarDexRouter: INSUFFICIENT_A_AMOUNT");
                (amountA_, amountB_) = (_amountAOptimal, _amountBDesired);
            }
        }
    }

    /**
     * @notice internal function to swap a determined quantity of token
     * @param _amountIn quantity to swap
     * @param _to address that will receive the token
     * @param _data SwapCallbackData data of the swap to transmit
     * @return amountOut_ amount of token that _to will receive
     */
    function _swapExactIn(
        uint256 _amountIn,
        address _to,
        SwapCallbackData memory _data
    ) internal returns (uint256 amountOut_) {
        // allow swapping to the router address with address 0
        if (_to == address(0)) {
            _to = address(this);
        }

        (address _tokenIn, address _tokenOut) = _data.path.decodeFirstPool();
        bool _zeroForOne = _tokenIn < _tokenOut;
        (int256 _amount0, int256 _amount1) = ISmardexPair(PoolAddress.pairFor(factory, _tokenIn, _tokenOut)).swap(
            _to,
            _zeroForOne,
            _amountIn.toInt256(),
            abi.encode(_data)
        );

        amountOut_ = (_zeroForOne ? -_amount1 : -_amount0).toUint256();
    }

    /// @inheritdoc ISmardexRouter
    function quote(
        uint256 _amountA,
        uint256 _reserveA,
        uint256 _reserveB
    ) public pure virtual override returns (uint256 amountB_) {
        return PoolHelpers.quote(_amountA, _reserveA, _reserveB);
    }

    /// @inheritdoc ISmardexRouter
    function getAmountOut(
        SmardexLibrary.GetAmountParameters memory _param
    )
        external
        pure
        returns (
            uint256 amountOut_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        )
    {
        /// @dev The values _priceAverageIn and _priceAverageOut are not directly fetched from the pair,
        ///      and therefore, they may not necessarily be up to date with the most recent data. In
        ///      order to yield a _amountOut that represents the most current value, it is crucial that
        ///      the args _priceAverageIn and _priceAverageOut reflects the latest, updated data.
        (amountOut_, newReserveIn_, newReserveOut_, newFictiveReserveIn_, newFictiveReserveOut_) = SmardexLibrary
            .getAmountOut(_param);
    }

    /// @inheritdoc ISmardexRouter
    function getAmountIn(
        SmardexLibrary.GetAmountParameters memory _param
    )
        external
        pure
        returns (
            uint256 amountIn_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        )
    {
        (amountIn_, newReserveIn_, newReserveOut_, newFictiveReserveIn_, newFictiveReserveOut_) = SmardexLibrary
            .getAmountIn(_param);
    }

    /// @inheritdoc ISmardexRouter
    function getAmountOutFromPair(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    )
        external
        view
        returns (
            uint256 amountOut_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        )
    {
        SmardexLibrary.GetAmountParameters memory _param;
        _param.amount = _amountIn;

        ISmardexPair _pair = ISmardexPair(ISmardexFactory(factory).getPair(_tokenIn, _tokenOut));
        require(address(_pair) != address(0), "SmarDexRouter: INVALID_TOKENS");
        uint256 _priceAverageLastTimestamp;

        // fetch data
        if (_tokenIn == _pair.token0()) {
            (_param.reserveIn, _param.reserveOut) = _pair.getReserves();
            (_param.fictiveReserveIn, _param.fictiveReserveOut) = _pair.getFictiveReserves();
            (_param.priceAverageIn, _param.priceAverageOut, _priceAverageLastTimestamp) = _pair.getPriceAverage();
        } else {
            (_param.reserveOut, _param.reserveIn) = _pair.getReserves();
            (_param.fictiveReserveOut, _param.fictiveReserveIn) = _pair.getFictiveReserves();
            (_param.priceAverageOut, _param.priceAverageIn, _priceAverageLastTimestamp) = _pair.getPriceAverage();
        }

        // update price average
        (_param.priceAverageIn, _param.priceAverageOut) = _pair.getUpdatedPriceAverage(
            _param.fictiveReserveIn,
            _param.fictiveReserveOut,
            _priceAverageLastTimestamp,
            _param.priceAverageIn,
            _param.priceAverageOut,
            block.timestamp
        );

        // get pair fees
        (_param.feesLP, _param.feesPool) = _pair.getPairFees();

        (amountOut_, newReserveIn_, newReserveOut_, newFictiveReserveIn_, newFictiveReserveOut_) = SmardexLibrary
            .getAmountOut(_param);
    }

    /// @inheritdoc ISmardexRouter
    function getAmountInFromPair(
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut
    )
        external
        view
        returns (
            uint256 amountIn_,
            uint256 newReserveIn_,
            uint256 newReserveOut_,
            uint256 newFictiveReserveIn_,
            uint256 newFictiveReserveOut_
        )
    {
        SmardexLibrary.GetAmountParameters memory _param;
        _param.amount = _amountOut;

        ISmardexPair _pair = ISmardexPair(ISmardexFactory(factory).getPair(_tokenIn, _tokenOut));
        require(address(_pair) != address(0), "SmarDexRouter: INVALID_TOKENS");
        uint256 _priceAverageLastTimestamp;

        // fetch data
        if (_tokenIn == _pair.token0()) {
            (_param.reserveIn, _param.reserveOut) = _pair.getReserves();
            (_param.fictiveReserveIn, _param.fictiveReserveOut) = _pair.getFictiveReserves();
            (_param.priceAverageIn, _param.priceAverageOut, _priceAverageLastTimestamp) = _pair.getPriceAverage();
        } else {
            (_param.reserveOut, _param.reserveIn) = _pair.getReserves();
            (_param.fictiveReserveOut, _param.fictiveReserveIn) = _pair.getFictiveReserves();
            (_param.priceAverageOut, _param.priceAverageIn, _priceAverageLastTimestamp) = _pair.getPriceAverage();
        }

        // update price average
        (_param.priceAverageIn, _param.priceAverageOut) = _pair.getUpdatedPriceAverage(
            _param.fictiveReserveIn,
            _param.fictiveReserveOut,
            _priceAverageLastTimestamp,
            _param.priceAverageIn,
            _param.priceAverageOut,
            block.timestamp
        );

        // get pair fees
        (_param.feesLP, _param.feesPool) = _pair.getPairFees();

        (amountIn_, newReserveIn_, newReserveOut_, newFictiveReserveIn_, newFictiveReserveOut_) = SmardexLibrary
            .getAmountIn(_param);
    }
}