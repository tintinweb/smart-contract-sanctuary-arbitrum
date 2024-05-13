// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

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
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
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
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
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
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
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
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
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
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
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
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
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
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
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
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
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
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
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
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
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
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
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
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
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
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
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
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
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
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
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
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
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
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
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
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
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
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
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
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
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
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
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
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
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
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
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
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
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
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
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
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
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
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
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
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
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
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
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
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
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
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
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
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
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
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
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
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
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
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
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
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
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
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
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
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
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
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
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
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
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
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
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
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
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
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
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
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
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
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
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
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
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
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
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
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
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
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
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
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
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
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
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
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
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
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
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
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
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
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
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
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
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
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
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
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
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
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarketDescriptor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Configurable Interface
/// @notice This interface defines the functions for manage USD stablecoins and market configurations
interface IConfigurable {
    struct MarketConfig {
        MarketBaseConfig baseConfig;
        MarketFeeRateConfig feeRateConfig;
        MarketPriceConfig priceConfig;
    }

    struct MarketBaseConfig {
        // ==================== LP Position Configuration ====================
        /// @notice The minimum entry margin required for per LP position, for example, 10_000_000 means the minimum
        /// entry margin is 10 USD
        uint64 minMarginPerLiquidityPosition;
        /// @notice The maximum leverage for per LP position, for example, 100 means the maximum leverage is 100 times
        uint32 maxLeveragePerLiquidityPosition;
        /// @notice The liquidation fee rate for per LP position,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 liquidationFeeRatePerLiquidityPosition;
        // ==================== Trader Position Configuration ==================
        /// @notice The minimum entry margin required for per trader position, for example, 10_000_000 means
        /// the minimum entry margin is 10 USD
        uint64 minMarginPerPosition;
        /// @notice The maximum leverage for per trader position, for example, 100 means the maximum leverage
        /// is 100 times
        uint32 maxLeveragePerPosition;
        /// @notice The liquidation fee rate for per trader position,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 liquidationFeeRatePerPosition;
        /// @notice The maximum available liquidity used to calculate the maximum size
        /// of the trader's position
        uint128 maxPositionLiquidity;
        /// @notice The maximum value of all positions relative to `maxPositionLiquidity`,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        /// @dev The maximum position value rate is used to calculate the maximum size of
        /// the trader's position, the formula is
        /// `maxSize = maxPositionValueRate * min(liquidity, maxPositionLiquidity) / maxIndexPrice`
        uint32 maxPositionValueRate;
        /// @notice The maximum size of per position relative to `maxSize`,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        /// @dev The maximum size per position rate is used to calculate the maximum size of
        /// the trader's position, the formula is
        /// `maxSizePerPosition = maxSizeRatePerPosition
        ///                       * maxPositionValueRate * min(liquidity, maxPositionLiquidity) / maxIndexPrice`
        uint32 maxSizeRatePerPosition;
        // ==================== Other Configuration ==========================
        /// @notice The liquidation execution fee for LP and trader positions
        uint64 liquidationExecutionFee;
    }

    struct MarketFeeRateConfig {
        /// @notice The protocol funding fee rate as a percentage of funding fee,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 protocolFundingFeeRate;
        /// @notice A coefficient used to adjust how funding fees are paid to the market,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 fundingCoeff;
        /// @notice A coefficient used to adjust how funding fees are distributed between long and short positions,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 protocolFundingCoeff;
        /// @notice The interest rate used to calculate the funding rate,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 interestRate;
        /// @notice The funding buffer, denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 fundingBuffer;
        /// @notice The liquidity funding fee rate, denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 liquidityFundingFeeRate;
        /// @notice The maximum funding rate, denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 maxFundingRate;
    }

    struct VertexConfig {
        /// @notice The balance rate of the vertex, denominated in a bip (i.e. 1e-8)
        uint32 balanceRate;
        /// @notice The premium rate of the vertex, denominated in a bip (i.e. 1e-8)
        uint32 premiumRate;
    }

    struct MarketPriceConfig {
        /// @notice The maximum available liquidity used to calculate the premium rate
        /// when trader increase or decrease positions
        uint128 maxPriceImpactLiquidity;
        /// @notice The index used to store the net position of the liquidation
        uint8 liquidationVertexIndex;
        /// @notice The dynamic depth mode used to determine the formula for calculating the trade price
        uint8 dynamicDepthMode;
        /// @notice The dynamic depth level used to calculate the trade price,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 dynamicDepthLevel;
        VertexConfig[10] vertices;
    }

    /// @notice Emitted when a USD stablecoin is enabled
    /// @param usd The ERC20 token representing the USD stablecoin used in markets
    event USDEnabled(IERC20 indexed usd);

    /// @notice Emitted when a market is enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param baseCfg The new market base configuration
    /// @param feeRateCfg The new market fee rate configuration
    /// @param priceCfg The new market price configuration
    event MarketConfigEnabled(
        IMarketDescriptor indexed market,
        MarketBaseConfig baseCfg,
        MarketFeeRateConfig feeRateCfg,
        MarketPriceConfig priceCfg
    );

    /// @notice Emitted when a market configuration is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market base configuration
    event MarketBaseConfigChanged(IMarketDescriptor indexed market, MarketBaseConfig newCfg);

    /// @notice Emitted when a market fee rate configuration is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market fee rate configuration
    event MarketFeeRateConfigChanged(IMarketDescriptor indexed market, MarketFeeRateConfig newCfg);

    /// @notice Emitted when a market price configuration is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market price configuration
    event MarketPriceConfigChanged(IMarketDescriptor indexed market, MarketPriceConfig newCfg);

    /// @notice Market is not enabled
    error MarketNotEnabled(IMarketDescriptor market);
    /// @notice Market is already enabled
    error MarketAlreadyEnabled(IMarketDescriptor market);
    /// @notice Invalid maximum leverage for LP positions
    error InvalidMaxLeveragePerLiquidityPosition(uint32 maxLeveragePerLiquidityPosition);
    /// @notice Invalid liquidation fee rate for LP positions
    error InvalidLiquidationFeeRatePerLiquidityPosition(uint32 invalidLiquidationFeeRatePerLiquidityPosition);
    /// @notice Invalid maximum leverage for trader positions
    error InvalidMaxLeveragePerPosition(uint32 maxLeveragePerPosition);
    /// @notice Invalid liquidation fee rate for trader positions
    error InvalidLiquidationFeeRatePerPosition(uint32 liquidationFeeRatePerPosition);
    /// @notice Invalid maximum position value
    error InvalidMaxPositionLiquidity(uint128 maxPositionLiquidity);
    /// @notice Invalid maximum position value rate
    error InvalidMaxPositionValueRate(uint32 maxPositionValueRate);
    /// @notice Invalid maximum size per rate for per psoition
    error InvalidMaxSizeRatePerPosition(uint32 maxSizeRatePerPosition);
    /// @notice Invalid protocol funding fee rate
    error InvalidProtocolFundingFeeRate(uint32 protocolFundingFeeRate);
    /// @notice Invalid funding coefficient
    error InvalidFundingCoeff(uint32 fundingCoeff);
    /// @notice Invalid protocol funding coefficient
    error InvalidProtocolFundingCoeff(uint32 protocolFundingCoeff);
    /// @notice Invalid interest rate
    error InvalidInterestRate(uint32 interestRate);
    /// @notice Invalid funding buffer
    error InvalidFundingBuffer(uint32 fundingBuffer);
    /// @notice Invalid liquidity funding fee rate
    error InvalidLiquidityFundingFeeRate(uint32 liquidityFundingFeeRate);
    /// @notice Invalid maximum funding rate
    error InvalidMaxFundingRate(uint32 maxFundingRate);
    /// @notice Invalid maximum price impact liquidity
    error InvalidMaxPriceImpactLiquidity(uint128 maxPriceImpactLiquidity);
    /// @notice Invalid vertices length
    /// @dev The length of vertices must be equal to the `VERTEX_NUM`
    error InvalidVerticesLength(uint256 length, uint256 requiredLength);
    /// @notice Invalid liquidation vertex index
    /// @dev The liquidation vertex index must be less than the length of vertices
    error InvalidLiquidationVertexIndex(uint8 liquidationVertexIndex);
    /// @notice Invalid vertex
    /// @param index The index of the vertex
    error InvalidVertex(uint8 index);
    /// @notice Invalid dynamic depth level
    error InvalidDynamicDepthLevel(uint32 dynamicDepthLevel);

    /// @notice Get the USD stablecoin used in markets
    /// @return The ERC20 token representing the USD stablecoin used in markets
    function USD() external view returns (IERC20);

    /// @notice Checks if a market is enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @return True if the market is enabled, false otherwise
    function isEnabledMarket(IMarketDescriptor market) external view returns (bool);

    /// @notice Get market configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function marketBaseConfigs(IMarketDescriptor market) external view returns (MarketBaseConfig memory);

    /// @notice Get market fee rate configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function marketFeeRateConfigs(IMarketDescriptor market) external view returns (MarketFeeRateConfig memory);

    /// @notice Get market price configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function marketPriceConfigs(IMarketDescriptor market) external view returns (MarketPriceConfig memory);

    /// @notice Get market price vertex configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param index The index of the vertex
    function marketPriceVertexConfigs(
        IMarketDescriptor market,
        uint8 index
    ) external view returns (VertexConfig memory);

    /// @notice Enable a market
    /// @dev The call will fail if caller is not the governor or the market is already enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param cfg The market configuration
    function enableMarket(IMarketDescriptor market, MarketConfig calldata cfg) external;

    /// @notice Update a market configuration
    /// @dev The call will fail if caller is not the governor or the market is not enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market base configuration
    function updateMarketBaseConfig(IMarketDescriptor market, MarketBaseConfig calldata newCfg) external;

    /// @notice Update a market fee rate configuration
    /// @dev The call will fail if caller is not the governor or the market is not enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market fee rate configuration
    function updateMarketFeeRateConfig(IMarketDescriptor market, MarketFeeRateConfig calldata newCfg) external;

    /// @notice Update a market price configuration
    /// @dev The call will fail if caller is not the governor or the market is not enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market price configuration
    function updateMarketPriceConfig(IMarketDescriptor market, MarketPriceConfig calldata newCfg) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMarketDescriptor {
    /// @notice Error thrown when the symbol is already initialized
    error SymbolAlreadyInitialized();

    /// @notice Get the name of the market
    function name() external view returns (string memory);

    /// @notice Get the symbol of the market
    function symbol() external view returns (string memory);

    /// @notice Get the size decimals of the market
    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";

interface IMarketErrors {
    /// @notice Liquidity is not enough to open a liquidity position
    error InvalidLiquidityToOpen();
    /// @notice Invalid caller
    error InvalidCaller(address requiredCaller);
    /// @notice Insufficient size to decrease
    error InsufficientSizeToDecrease(uint128 size, uint128 requiredSize);
    /// @notice Insufficient margin
    error InsufficientMargin();
    /// @notice Position not found
    error PositionNotFound(address requiredAccount, Side requiredSide);
    /// @notice Size exceeds max size per position
    error SizeExceedsMaxSizePerPosition(uint128 requiredSize, uint128 maxSizePerPosition);
    /// @notice Size exceeds max size
    error SizeExceedsMaxSize(uint128 requiredSize, uint128 maxSize);
    /// @notice Liquidity position not found
    error LiquidityPositionNotFound(address requiredAccount);
    /// @notice Insufficient liquidity to decrease
    error InsufficientLiquidityToDecrease(uint256 liquidity, uint128 requiredLiquidity);
    /// @notice Last liquidity position cannot be closed
    error LastLiquidityPositionCannotBeClosed();
    /// @notice Caller is not the liquidator
    error CallerNotLiquidator();
    /// @notice Insufficient balance
    error InsufficientBalance(uint256 balance, uint256 requiredAmount);
    /// @notice Leverage is too high
    error LeverageTooHigh(uint256 margin, uint128 liquidity, uint32 maxLeverage);
    /// @notice Insufficient global liquidity
    error InsufficientGlobalLiquidity();
    /// @notice Risk rate is too high
    error RiskRateTooHigh(int256 margin, uint256 maintenanceMargin);
    /// @notice Risk rate is too low
    error RiskRateTooLow(int256 margin, uint256 maintenanceMargin);
    /// @notice Position margin rate is too low
    error MarginRateTooLow(int256 margin, int256 unrealizedPnL, uint256 maintenanceMargin);
    /// @notice Position margin rate is too high
    error MarginRateTooHigh(int256 margin, int256 unrealizedPnL, uint256 maintenanceMargin);
    /// @notice Emitted when premium rate overflows, should stop calculation
    error MaxPremiumRateExceeded();
    /// @notice Emitted when size delta is zero
    error ZeroSizeDelta();
    /// @notice The liquidation fund is experiencing losses
    error LiquidationFundLoss();
    /// @notice Insufficient liquidation fund
    error InsufficientLiquidationFund(uint128 requiredRiskBufferFund);
    /// @notice Emitted when trade price is invalid
    error InvalidTradePrice(int256 tradePriceX96TimesSizeTotal);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarketDescriptor.sol";
import {Side} from "../../types/Side.sol";

/// @notice Interface for managing liquidity positions
/// @dev The market liquidity position is the core component of the protocol, which stores the information of
/// all LP's positions.
interface IMarketLiquidityPosition {
    struct GlobalLiquidityPosition {
        /// @notice The size of the net position held by all LPs
        uint128 netSize;
        /// @notice The size of the net position held by all LPs in the liquidation buffer
        uint128 liquidationBufferNetSize;
        /// @notice The Previous Settlement Point Price, as a Q64.96
        uint160 previousSPPriceX96;
        /// @notice The side of the position (Long or Short)
        Side side;
        /// @notice The total liquidity of all LPs
        uint128 liquidity;
        /// @notice The accumulated unrealized Profit and Loss (PnL) growth per liquidity unit, as a Q192.64.
        /// The value is updated when the following actions are performed:
        ///     1. Settlement Point is reached
        ///     2. Funding fee is added
        ///     3. Liquidation loss is added
        int256 unrealizedPnLGrowthX64;
        uint256[50] __gap;
    }

    struct LiquidityPosition {
        /// @notice The margin of the position
        uint128 margin;
        /// @notice The liquidity (value) of the position
        uint128 liquidity;
        /// @notice The snapshot of `GlobalLiquidityPosition.realizedProfitGrowthX64`
        /// at the time of the position was opened.
        int256 entryUnrealizedPnLGrowthX64;
        uint256[50] __gap;
    }

    /// @notice Emitted when the global liquidity position net position changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param sideAfter The adjusted side of the net position
    /// @param netSizeAfter The adjusted net position size
    /// @param liquidationBufferNetSizeAfter The adjusted net position size in the liquidation buffer
    event GlobalLiquidityPositionNetPositionChanged(
        IMarketDescriptor indexed market,
        Side sideAfter,
        uint128 netSizeAfter,
        uint128 liquidationBufferNetSizeAfter
    );

    /// @notice Emitted when the position margin/liquidity (value) is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param marginDelta The increased margin
    /// @param marginAfter The adjusted margin
    /// @param liquidityAfter The adjusted liquidity
    /// @param realizedPnLDelta The realized PnL of the position
    event LiquidityPositionIncreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 liquidityAfter,
        int256 realizedPnLDelta
    );

    /// @notice Emitted when the position margin/liquidity (value) is decreased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param marginDelta The decreased margin
    /// @param marginAfter The adjusted margin
    /// @param liquidityAfter The adjusted liquidity
    /// @param realizedPnLDelta The realized PnL of the position
    /// @param receiver The address that receives the margin
    event LiquidityPositionDecreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 liquidityAfter,
        int256 realizedPnLDelta,
        address receiver
    );

    /// @notice Emitted when a position is liquidated
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidator The address that executes the liquidation of the position
    /// @param liquidationLoss The loss of the liquidated position.
    /// If it is a negative number, it means that the remaining LP bears this part of the loss,
    /// otherwise it means that the `Liquidation Fund` gets this part of the liquidation fee.
    /// @param unrealizedPnLGrowthAfterX64 The adjusted `GlobalLiquidityPosition.unrealizedPnLGrowthX64`, as a Q192.64
    /// @param feeReceiver The address that receives the liquidation execution fee
    event LiquidityPositionLiquidated(
        IMarketDescriptor indexed market,
        address indexed account,
        address indexed liquidator,
        int256 liquidationLoss,
        int256 unrealizedPnLGrowthAfterX64,
        address feeReceiver
    );

    /// @notice Emitted when the previous Settlement Point Price is initialized
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param previousSPPriceX96 The adjusted `GlobalLiquidityPosition.previousSPPriceX96`, as a Q64.96
    event PreviousSPPriceInitialized(IMarketDescriptor indexed market, uint160 previousSPPriceX96);

    /// @notice Emitted when the Settlement Point is reached
    /// @dev Settlement Point is triggered by the following 6 actions:
    ///     1. increaseLiquidityPosition
    ///     2. decreaseLiquidityPosition
    ///     3. liquidateLiquidityPosition
    ///     4. increasePosition
    ///     5. decreasePosition
    ///     6. liquidatePosition
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param unrealizedPnLGrowthAfterX64 The adjusted `GlobalLiquidityPosition.unrealizedPnLGrowthX64`, as a Q192.64
    /// @param previousSPPriceAfterX96 The adjusted `GlobalLiquidityPosition.previousSPPriceX96`, as a Q64.96
    event SettlementPointReached(
        IMarketDescriptor indexed market,
        int256 unrealizedPnLGrowthAfterX64,
        uint160 previousSPPriceAfterX96
    );

    /// @notice Emitted when the global liquidity position is increased by funding fee
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param unrealizedPnLGrowthAfterX64 The adjusted `GlobalLiquidityPosition.unrealizedPnLGrowthX64`, as a Q192.64
    event GlobalLiquidityPositionPnLGrowthIncreasedByFundingFee(
        IMarketDescriptor indexed market,
        int256 unrealizedPnLGrowthAfterX64
    );

    /// @notice Get the global liquidity position of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalLiquidityPositions(IMarketDescriptor market) external view returns (GlobalLiquidityPosition memory);

    /// @notice Get the information of a liquidity position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    function liquidityPositions(
        IMarketDescriptor market,
        address account
    ) external view returns (LiquidityPosition memory);

    /// @notice Increase the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param marginDelta The increase in margin, which can be 0
    /// @param liquidityDelta The increase in liquidity, which can be 0
    /// @return marginAfter The margin after increasing the position
    function increaseLiquidityPosition(
        IMarketDescriptor market,
        address account,
        uint128 marginDelta,
        uint128 liquidityDelta
    ) external returns (uint128 marginAfter);

    /// @notice Decrease the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param marginDelta The decrease in margin, which can be 0
    /// @param liquidityDelta The decrease in liquidity, which can be 0
    /// @param receiver The address to receive the margin at the time of closing
    /// @return marginAfter The margin after decreasing the position
    function decreaseLiquidityPosition(
        IMarketDescriptor market,
        address account,
        uint128 marginDelta,
        uint128 liquidityDelta,
        address receiver
    ) external returns (uint128 marginAfter);

    /// @notice Liquidate a liquidity position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param feeReceiver The address to receive the liquidation execution fee
    function liquidateLiquidityPosition(IMarketDescriptor market, address account, address feeReceiver) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IConfigurable.sol";
import "./IMarketErrors.sol";
import "./IMarketPosition.sol";
import "./IMarketLiquidityPosition.sol";
import "../../oracle/interfaces/IPriceFeed.sol";

interface IMarketManager is IMarketErrors, IMarketPosition, IMarketLiquidityPosition, IConfigurable {
    struct PriceVertex {
        /// @notice The available size when the price curve moves to this vertex
        uint128 size;
        /// @notice The premium rate when the price curve moves to this vertex, as a Q32.96
        uint128 premiumRateX96;
    }

    struct PriceState {
        /// @notice The premium rate during the last position adjustment by the trader, as a Q32.96
        uint128 premiumRateX96;
        /// @notice The index used to track the pending update of the price vertex
        uint8 pendingVertexIndex;
        /// @notice The index used to track the current used price vertex
        uint8 currentVertexIndex;
        /// @notice The basis index price, as a Q64.96
        uint160 basisIndexPriceX96;
        /// @notice The price vertices used to determine the price curve
        PriceVertex[10] priceVertices;
        /// @notice The net sizes of the liquidation buffer
        uint128[10] liquidationBufferNetSizes;
        uint256[50] __gap;
    }

    struct GlobalLiquidationFund {
        /// @notice The liquidation fund, primarily used to compensate for the difference between the
        /// liquidation price and the index price when a trader's position is liquidated. It consists of
        /// the following parts:
        ///     1. Increased by the liquidation fee when the trader's is liquidated
        ///     2. Increased by the liquidation fee when the LP's position is liquidated
        ///     3. Increased by the liquidity added to the liquidation fund
        ///     4. Decreased by the liquidity removed from the liquidation fund
        ///     5. Decreased by the funding fee compensated when the trader's position is liquidated
        ///     6. Decreased by the loss compensated when the LP's position is liquidated
        ///     7. Decreased by the difference between the liquidation price and the index price when
        ///      the trader's position is liquidated
        ///     8. Decreased by the governance when the liquidation fund is pofitable
        int256 liquidationFund;
        /// @notice The total liquidity of the liquidation fund
        uint256 liquidity;
        uint256[50] __gap;
    }

    struct State {
        /// @notice The value is used to track the price curve
        PriceState priceState;
        /// @notice The value is used to track the USD balance of the market
        uint128 usdBalance;
        /// @notice The value is used to track the remaining protocol fee of the market
        uint128 protocolFee;
        /// @notice Mapping of referral token to referral fee
        mapping(uint256 referralToken => uint256 feeAmount) referralFees;
        // ==================== Liquidity Position Stats ====================
        /// @notice The value is used to track the global liquidity position
        GlobalLiquidityPosition globalLiquidityPosition;
        /// @notice Mapping of account to liquidity position
        mapping(address account => LiquidityPosition) liquidityPositions;
        // ==================== Position Stats ==============================
        /// @notice The value is used to track the global position
        GlobalPosition globalPosition;
        /// @notice Mapping of account to position
        mapping(address account => mapping(Side => Position)) positions;
        // ==================== Liquidation Fund Position Stats =============
        /// @notice The value is used to track the global liquidation fund
        GlobalLiquidationFund globalLiquidationFund;
        /// @notice Mapping of account to liquidation fund position
        mapping(address account => uint256 liquidity) liquidationFundPositions;
        uint256[50] __gap;
    }

    /// @notice Emitted when the price vertex is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param index The index of the price vertex
    /// @param sizeAfter The available size when the price curve moves to this vertex
    /// @param premiumRateAfterX96 The premium rate when the price curve moves to this vertex, as a Q32.96
    event PriceVertexChanged(
        IMarketDescriptor indexed market,
        uint8 index,
        uint128 sizeAfter,
        uint128 premiumRateAfterX96
    );

    /// @notice Emitted when the protocol fee is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param amount The increased protocol fee
    event ProtocolFeeIncreased(IMarketDescriptor indexed market, uint128 amount);

    /// @notice Emitted when the protocol fee is collected
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param amount The collected protocol fee
    event ProtocolFeeCollected(IMarketDescriptor indexed market, uint128 amount);

    /// @notice Emitted when the price feed is changed
    /// @param priceFeedBefore The address of the price feed before changed
    /// @param priceFeedAfter The address of the price feed after changed
    event PriceFeedChanged(IPriceFeed indexed priceFeedBefore, IPriceFeed indexed priceFeedAfter);

    /// @notice Emitted when the premium rate is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param premiumRateAfterX96 The premium rate after changed, as a Q32.96
    event PremiumRateChanged(IMarketDescriptor indexed market, uint128 premiumRateAfterX96);

    /// @notice Emitted when liquidation buffer net size is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param index The index of the liquidation buffer net size
    /// @param netSizeAfter The net size of the liquidation buffer after changed
    event LiquidationBufferNetSizeChanged(IMarketDescriptor indexed market, uint8 index, uint128 netSizeAfter);

    /// @notice Emitted when the basis index price is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param basisIndexPriceAfterX96 The basis index price after changed, as a Q64.96
    event BasisIndexPriceChanged(IMarketDescriptor indexed market, uint160 basisIndexPriceAfterX96);

    /// @notice Emitted when the liquidation fund is used by `Gov`
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param receiver The address that receives the liquidation fund
    /// @param liquidationFundDelta The amount of liquidation fund used
    event GlobalLiquidationFundGovUsed(
        IMarketDescriptor indexed market,
        address indexed receiver,
        uint128 liquidationFundDelta
    );

    /// @notice Emitted when the liquidity of the liquidation fund is increased by liquidation
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param liquidationFee The amount of the liquidation fee that is added to the liquidation fund.
    /// It consists of following parts:
    ///     1. The liquidation fee paid by the position
    ///     2. The funding fee compensated when liquidating, covered by the liquidation fund (if any)
    ///     3. The difference between the liquidation price and the trade price when liquidating,
    ///     covered by the liquidation fund (if any)
    /// @param liquidationFundAfter The amount of the liquidation fund after the increase
    event GlobalLiquidationFundIncreasedByLiquidation(
        IMarketDescriptor indexed market,
        int256 liquidationFee,
        int256 liquidationFundAfter
    );

    /// @notice Emitted when the liquidity of the liquidation fund is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityAfter The total liquidity of the position after the increase
    event LiquidationFundPositionIncreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint256 liquidityAfter
    );

    /// @notice Emitted when the liquidity of the liquidation fund is decreased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityAfter The total liquidity of the position after the decrease
    /// @param receiver The address that receives the liquidity when it is decreased
    event LiquidationFundPositionDecreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint256 liquidityAfter,
        address receiver
    );

    /// @notice Change the price feed
    /// @param priceFeed The address of the new price feed
    function setPriceFeed(IPriceFeed priceFeed) external;

    /// @notice Get the price state of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function priceStates(IMarketDescriptor market) external view returns (PriceState memory);

    /// @notice Get the USD balance of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function usdBalances(IMarketDescriptor market) external view returns (uint256);

    /// @notice Get the protocol fee of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function protocolFees(IMarketDescriptor market) external view returns (uint128);

    /// @notice Change the price vertex of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param startExclusive The start index of the price vertex to be changed, exclusive
    /// @param endInclusive The end index of the price vertex to be changed, inclusive
    function changePriceVertex(IMarketDescriptor market, uint8 startExclusive, uint8 endInclusive) external;

    /// @notice Settle the funding fee of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function settleFundingFee(IMarketDescriptor market) external;

    /// @notice Collect the protocol fee of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function collectProtocolFee(IMarketDescriptor market) external;

    /// @notice Get the global liquidation fund of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalLiquidationFunds(IMarketDescriptor market) external view returns (GlobalLiquidationFund memory);

    /// @notice Get the liquidity of the liquidation fund
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    function liquidationFundPositions(
        IMarketDescriptor market,
        address account
    ) external view returns (uint256 liquidity);

    /// @notice `Gov` uses the liquidation fund
    /// @dev The call will fail if the caller is not the `Gov` or the liquidation fund is insufficient
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param receiver The address to receive the liquidation fund
    /// @param liquidationFundDelta The amount of liquidation fund to be used
    function govUseLiquidationFund(IMarketDescriptor market, address receiver, uint128 liquidationFundDelta) external;

    /// @notice Increase the liquidity of a liquidation fund position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityDelta The increase in liquidity
    function increaseLiquidationFundPosition(
        IMarketDescriptor market,
        address account,
        uint128 liquidityDelta
    ) external;

    /// @notice Decrease the liquidity of a liquidation fund position
    /// @dev The call will fail if the position liquidity is insufficient or the liquidation fund is losing
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityDelta The decrease in liquidity
    /// @param receiver The address to receive the liquidity when it is decreased
    function decreaseLiquidationFundPosition(
        IMarketDescriptor market,
        address account,
        uint128 liquidityDelta,
        address receiver
    ) external;

    /// @notice Get the market price of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param side The side of the position adjustment, 1 for opening long or closing short positions,
    /// 2 for opening short or closing long positions
    /// @return marketPriceX96 The market price, as a Q64.96
    function marketPriceX96s(IMarketDescriptor market, Side side) external view returns (uint160 marketPriceX96);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarketDescriptor.sol";
import {Side} from "../../types/Side.sol";

/// @notice Interface for managing market positions.
/// @dev The market position is the core component of the protocol, which stores the information of
/// all trader's positions and the funding rate.
interface IMarketPosition {
    struct GlobalPosition {
        /// @notice The sum of long position sizes
        uint128 longSize;
        /// @notice The sum of short position sizes
        uint128 shortSize;
        /// @notice The maximum available size of all positions
        uint128 maxSize;
        /// @notice The maximum available size of per position
        uint128 maxSizePerPosition;
        /// @notice The funding rate growth per unit of long position sizes, as a Q96.96
        int192 longFundingRateGrowthX96;
        /// @notice The funding rate growth per unit of short position sizes, as a Q96.96
        int192 shortFundingRateGrowthX96;
        /// @notice The last time the funding fee is settled
        uint64 lastFundingFeeSettleTime;
        uint256[50] __gap;
    }

    struct Position {
        /// @notice The margin of the position
        uint128 margin;
        /// @notice The size of the position
        uint128 size;
        /// @notice The entry price of the position, as a Q64.96
        uint160 entryPriceX96;
        /// @notice The snapshot of the funding rate growth at the time the position was opened.
        /// For long positions it is `GlobalPosition.longFundingRateGrowthX96`,
        /// and for short positions it is `GlobalPosition.shortFundingRateGrowthX96`
        int192 entryFundingRateGrowthX96;
        uint256[50] __gap;
    }
    /// @notice Emitted when the funding fee is settled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param longFundingRateGrowthAfterX96 The adjusted `GlobalPosition.longFundingRateGrowthX96`, as a Q96.96
    /// @param shortFundingRateGrowthAfterX96 The adjusted `GlobalPosition.shortFundingRateGrowthX96`, as a Q96.96
    event FundingFeeSettled(
        IMarketDescriptor indexed market,
        int192 longFundingRateGrowthAfterX96,
        int192 shortFundingRateGrowthAfterX96
    );

    /// @notice Emitted when the max available size is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param maxSizeAfter The adjusted `maxSize`
    /// @param maxSizePerPositionAfter The adjusted `maxSizePerPosition`
    event GlobalPositionSizeChanged(
        IMarketDescriptor indexed market,
        uint128 maxSizeAfter,
        uint128 maxSizePerPositionAfter
    );

    /// @notice Emitted when the position margin/liquidity (value) is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increased margin
    /// @param marginAfter The adjusted margin
    /// @param sizeAfter The adjusted position size
    /// @param tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    /// @param entryPriceAfterX96 The adjusted entry price of the position, as a Q64.96
    /// @param fundingFee The funding fee, a positive value means the position receives funding fee,
    /// while a negative value means the position positive pays funding fee
    event PositionIncreased(
        IMarketDescriptor indexed market,
        address indexed account,
        Side side,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 sizeAfter,
        uint160 tradePriceX96,
        uint160 entryPriceAfterX96,
        int256 fundingFee
    );

    /// @notice Emitted when the position margin/liquidity (value) is decreased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decreased margin
    /// @param marginAfter The adjusted margin
    /// @param sizeAfter The adjusted position size
    /// @param tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    /// @param realizedPnLDelta The realized PnL
    /// @param fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param receiver The address that receives the margin
    event PositionDecreased(
        IMarketDescriptor indexed market,
        address indexed account,
        Side side,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 sizeAfter,
        uint160 tradePriceX96,
        int256 realizedPnLDelta,
        int256 fundingFee,
        address receiver
    );

    /// @notice Emitted when a position is liquidated
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param liquidator The address that executes the liquidation of the position
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param indexPriceX96 The index price when liquidating the position, as a Q64.96
    /// @param tradePriceX96 The trade price at which the position is liquidated, as a Q64.96
    /// @param liquidationPriceX96 The liquidation price of the position, as a Q64.96
    /// @param fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee. If it's negative,
    /// it represents the actual funding fee paid during liquidation
    /// @param liquidationFee The liquidation fee paid by the position
    /// @param liquidationExecutionFee The liquidation execution fee paid by the position
    /// @param feeReceiver The address that receives the liquidation execution fee
    event PositionLiquidated(
        IMarketDescriptor indexed market,
        address indexed liquidator,
        address indexed account,
        Side side,
        uint160 indexPriceX96,
        uint160 tradePriceX96,
        uint160 liquidationPriceX96,
        int256 fundingFee,
        uint128 liquidationFee,
        uint64 liquidationExecutionFee,
        address feeReceiver
    );

    /// @notice Get the global position of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalPositions(IMarketDescriptor market) external view returns (GlobalPosition memory);

    /// @notice Get the information of a position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    function positions(IMarketDescriptor market, address account, Side side) external view returns (Position memory);

    /// @notice Increase the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increase in margin, which can be 0
    /// @param sizeDelta The increase in size, which can be 0
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    function increasePosition(
        IMarketDescriptor market,
        address account,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta
    ) external returns (uint160 tradePriceX96);

    /// @notice Decrease the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decrease in margin, which can be 0
    /// @param sizeDelta The decrease in size, which can be 0
    /// @param receiver The address to receive the margin
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    function decreasePosition(
        IMarketDescriptor market,
        address account,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta,
        address receiver
    ) external returns (uint160 tradePriceX96);

    /// @notice Liquidate a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param feeReceiver The address that receives the liquidation execution fee
    function liquidatePosition(IMarketDescriptor market, address account, Side side, address feeReceiver) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Constants {
    uint32 internal constant BASIS_POINTS_DIVISOR = 100_000_000;

    uint8 internal constant VERTEX_NUM = 10;
    uint8 internal constant LATEST_VERTEX = VERTEX_NUM - 1;

    uint32 internal constant FUNDING_RATE_SETTLE_CONFIG_INTERVAL = 8 hours;

    uint256 internal constant Q64 = 1 << 64;
    uint256 internal constant Q96 = 1 << 96;
    uint256 internal constant Q152 = 1 << 152;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./MarketUtil.sol";

/// @notice Utility library for calculating funding rates
library FundingRateUtil {
    using SafeCast for *;

    /// @notice Adjust the funding rate
    /// @param _state The state of the market
    /// @param _market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param _longFundingRateGrowthAfterX96 The long funding rate growth after the funding rate is updated,
    /// as a Q96.96
    /// @param _shortFundingRateGrowthAfterX96 The short funding rate growth after the funding rate is updated,
    /// as a Q96.96
    function adjustFundingRate(
        IMarketManager.State storage _state,
        IMarketDescriptor _market,
        int192 _longFundingRateGrowthAfterX96,
        int192 _shortFundingRateGrowthAfterX96
    ) internal {
        _state.globalPosition.longFundingRateGrowthX96 = _longFundingRateGrowthAfterX96;
        _state.globalPosition.shortFundingRateGrowthX96 = _shortFundingRateGrowthAfterX96;
        emit IMarketPosition.FundingFeeSettled(
            _market,
            _longFundingRateGrowthAfterX96,
            _shortFundingRateGrowthAfterX96
        );
    }

    /// @notice Settle the funding fee
    function settleFundingFee(
        IMarketManager.State storage _state,
        IConfigurable.MarketConfig storage _cfg,
        IPriceFeed _priceFeed,
        IMarketDescriptor _market
    ) public {
        uint64 currentTimestamp = block.timestamp.toUint64();
        IMarketManager.GlobalPosition storage _globalPosition = _state.globalPosition;
        uint64 lastFundingFeeSettleTime = _globalPosition.lastFundingFeeSettleTime;
        if (lastFundingFeeSettleTime == currentTimestamp) return;

        (uint128 longSize, uint128 shortSize) = (_globalPosition.longSize, _globalPosition.shortSize);
        IMarketManager.GlobalLiquidityPosition storage _globalLiquidityPosition = _state.globalLiquidityPosition;
        // Ignore funding fees if there is no liquidity or no user position
        if (_globalLiquidityPosition.liquidity == 0 || (longSize | shortSize) == 0) {
            _globalPosition.lastFundingFeeSettleTime = currentTimestamp;
            emit IMarketPosition.FundingFeeSettled(
                _market,
                _globalPosition.longFundingRateGrowthX96,
                _globalPosition.shortFundingRateGrowthX96
            );
            return;
        }

        uint160 indexPriceX96 = _priceFeed.getMaxPriceX96(_market);
        IConfigurable.MarketFeeRateConfig memory feeRateCfgCache = _cfg.feeRateConfig;
        uint64 timeDelta = currentTimestamp - lastFundingFeeSettleTime;
        // actualPremiumRate = marketPrice / indexPrice - 1
        //                   = (indexPrice + premiumRate * basisIndexPrice) / indexPrice - 1
        //                   = premiumRate * basisIndexPrice / indexPrice
        IMarketManager.PriceState storage priceState = _state.priceState;
        uint128 actualPremiumRateX96 = Math
            .mulDivUp(priceState.premiumRateX96, priceState.basisIndexPriceX96, indexPriceX96)
            .toUint128();
        int192 baseRateX96 = calculateBaseRateX96(
            feeRateCfgCache,
            longSize,
            shortSize,
            actualPremiumRateX96,
            timeDelta
        );

        (int256 longFundingFee, int256 shortFundingFee, uint256 liquidityFundingFee) = settleProtocolFundingFee(
            _state,
            feeRateCfgCache,
            _market,
            longSize,
            shortSize,
            indexPriceX96,
            timeDelta
        );

        (uint128 paidSize, uint128 receivedSize, uint256 paidFundingRateX96) = baseRateX96 >= 0
            ? (longSize, shortSize, uint256(int256(baseRateX96)))
            : (shortSize, longSize, uint256(-int256(baseRateX96)));

        if (paidSize > 0 && baseRateX96 != 0) {
            uint256 paidLiquidity = Math.mulDivUp(paidSize, indexPriceX96, Constants.Q96);
            int256 paidFundingFee = Math.mulDivUp(paidLiquidity, paidFundingRateX96, Constants.Q96).toInt256();

            int256 receivedFundingFee = paidFundingFee;
            if (paidSize > receivedSize) {
                uint256 liquidityFundingFee2;
                unchecked {
                    liquidityFundingFee2 = Math.mulDiv(paidSize - receivedSize, uint256(paidFundingFee), paidSize);
                    receivedFundingFee = receivedSize == 0
                        ? int256(0)
                        : (paidFundingFee - int256(liquidityFundingFee2));
                }

                liquidityFundingFee += liquidityFundingFee2;
            }

            if (baseRateX96 >= 0) {
                longFundingFee = -longFundingFee - paidFundingFee;
                shortFundingFee = -shortFundingFee + receivedFundingFee;
            } else {
                longFundingFee = -longFundingFee + receivedFundingFee;
                shortFundingFee = -shortFundingFee - paidFundingFee;
            }
        }

        uint256 unrealizedPnLGrowthDeltaX64 = (uint256(liquidityFundingFee.toUint128()) << 64) /
            _globalLiquidityPosition.liquidity;
        int256 unrealizedPnLGrowthAfterX64 = _globalLiquidityPosition.unrealizedPnLGrowthX64 +
            unrealizedPnLGrowthDeltaX64.toInt256();
        _globalLiquidityPosition.unrealizedPnLGrowthX64 = unrealizedPnLGrowthAfterX64.toInt192();
        emit IMarketLiquidityPosition.GlobalLiquidityPositionPnLGrowthIncreasedByFundingFee(
            _market,
            unrealizedPnLGrowthAfterX64
        );

        int192 longFundingRateGrowthDeltaX96 = calculateFundingRateGrowthDeltaX96(longFundingFee, longSize);
        int192 shortFundingRateGrowthDeltaX96 = calculateFundingRateGrowthDeltaX96(shortFundingFee, shortSize);

        int192 longFundingRateGrowthX96 = _globalPosition.longFundingRateGrowthX96 + longFundingRateGrowthDeltaX96;
        int192 shortFundingRateGrowthX96 = _globalPosition.shortFundingRateGrowthX96 + shortFundingRateGrowthDeltaX96;
        _globalPosition.lastFundingFeeSettleTime = currentTimestamp;
        adjustFundingRate(_state, _market, longFundingRateGrowthX96, shortFundingRateGrowthX96);
    }

    function calculateFundingRateGrowthDeltaX96(
        int256 _fundingFee,
        uint128 _size
    ) internal pure returns (int192 deltaX96) {
        if (_size == 0) return int192(0);

        unchecked {
            (uint256 fundingFeeAbs, Math.Rounding rounding) = _fundingFee >= 0
                ? (uint256(_fundingFee), Math.Rounding.Down)
                : (uint256(-_fundingFee), Math.Rounding.Up);
            deltaX96 = Math.mulDiv(fundingFeeAbs, Constants.Q96, _size, rounding).toInt256().toInt192();
        }

        deltaX96 = _fundingFee >= 0 ? deltaX96 : -deltaX96;
    }

    /// @notice Settle the protocol funding fee
    /// @return longFundingFee The long funding fee that should be paid to the protocol, always non-negative
    /// @return shortFundingFee The short funding fee that should be paid to the protocol, always non-negative
    /// @return liquidityFundingFee The funding fee that should be paid to the liquidity provider
    function settleProtocolFundingFee(
        IMarketManager.State storage _state,
        IConfigurable.MarketFeeRateConfig memory _feeRateCfgCache,
        IMarketDescriptor _market,
        uint128 _longSize,
        uint128 _shortSize,
        uint160 _indexPriceX96,
        uint64 _timeDelta
    ) internal returns (int256 longFundingFee, int256 shortFundingFee, uint256 liquidityFundingFee) {
        (uint256 longFundingRateX96, uint256 shortFundingRateX96) = calculateFundingRateX96(
            _feeRateCfgCache,
            _timeDelta
        );
        uint256 longLiquidity = Math.mulDivUp(_longSize, _indexPriceX96, Constants.Q96);
        longFundingFee = Math.mulDivUp(longLiquidity, longFundingRateX96, Constants.Q96).toInt256();

        uint256 shortLiquidity = Math.mulDivUp(_shortSize, _indexPriceX96, Constants.Q96);
        shortFundingFee = Math.mulDivUp(shortLiquidity, shortFundingRateX96, Constants.Q96).toInt256();

        uint256 totalProtocolFundingFee = uint256(longFundingFee) + uint256(shortFundingFee);
        liquidityFundingFee = Math.mulDiv(
            totalProtocolFundingFee,
            _feeRateCfgCache.liquidityFundingFeeRate,
            Constants.BASIS_POINTS_DIVISOR
        );
        unchecked {
            uint128 protocolFeeDelta = (totalProtocolFundingFee - liquidityFundingFee).toUint128();
            _state.protocolFee += protocolFeeDelta; // overflow is desired
            emit IMarketManager.ProtocolFeeIncreased(_market, protocolFeeDelta);
        }
    }

    /// @notice Calculate the funding rate that should be paid to the protocol
    /// @param _feeRateCfgCache The cache of the fee rate configuration
    /// @param _timeDelta The time delta between the last funding fee settlement and the current time
    /// @return longFundingRateX96 The long funding rate that should be paid to the protocol, as a Q96.96
    /// @return shortFundingRateX96 The short funding rate that should be paid to the protocol, as a Q96.96
    function calculateFundingRateX96(
        IConfigurable.MarketFeeRateConfig memory _feeRateCfgCache,
        uint64 _timeDelta
    ) internal pure returns (uint256 longFundingRateX96, uint256 shortFundingRateX96) {
        unchecked {
            // tempValueX96 is less than 1 << 146
            uint256 tempValueX96 = Math.ceilDiv(
                (uint256(_feeRateCfgCache.protocolFundingFeeRate) * _timeDelta) << 96,
                uint256(Constants.BASIS_POINTS_DIVISOR) * Constants.FUNDING_RATE_SETTLE_CONFIG_INTERVAL
            );
            longFundingRateX96 = Math.ceilDiv(
                tempValueX96 * _feeRateCfgCache.protocolFundingCoeff,
                Constants.BASIS_POINTS_DIVISOR
            );

            shortFundingRateX96 = Math.ceilDiv(
                tempValueX96 * (Constants.BASIS_POINTS_DIVISOR - _feeRateCfgCache.protocolFundingCoeff),
                Constants.BASIS_POINTS_DIVISOR
            );
        }
    }

    /// @notice Calculate the base rate
    /// @return baseRateX96 The base rate, as a Q96.96.
    /// If the base rate is positive, it means that the LP holds a short position,
    /// otherwise it means that the LP holds a long position.
    function calculateBaseRateX96(
        IConfigurable.MarketFeeRateConfig memory _feeRateCfgCache,
        uint128 _longSize,
        uint128 _shortSize,
        uint128 _premiumRateX96,
        uint64 _timeDelta
    ) internal pure returns (int192 baseRateX96) {
        int256 fundingX96;
        unchecked {
            int256 tempValueX96 = int256(uint256(_premiumRateX96) * _feeRateCfgCache.fundingCoeff);
            // LP holds a short position, it is a positive number, otherwise it is a negative number
            tempValueX96 = _longSize >= _shortSize ? tempValueX96 : -tempValueX96;
            fundingX96 = (int256(uint256(_feeRateCfgCache.interestRate) << 96)) - tempValueX96;

            int256 fundingBufferX96 = int256(uint256(_feeRateCfgCache.fundingBuffer) << 96);
            if (fundingX96 > fundingBufferX96) fundingX96 = fundingBufferX96;
            else if (fundingX96 < -fundingBufferX96) fundingX96 = -fundingBufferX96;

            fundingX96 = tempValueX96 + fundingX96;

            baseRateX96 = Math
                .mulDivUp(
                    fundingX96 <= 0 ? uint256(-fundingX96) : uint256(fundingX96),
                    _timeDelta,
                    uint256(Constants.BASIS_POINTS_DIVISOR) * Constants.FUNDING_RATE_SETTLE_CONFIG_INTERVAL
                )
                .toInt256()
                .toInt192();
        }

        int256 maxFundingRateX96 = Math
            .ceilDiv(uint256(_feeRateCfgCache.maxFundingRate) << 96, Constants.BASIS_POINTS_DIVISOR)
            .toInt256();
        int256 oneHourBaseRateX96 = (int256(baseRateX96) * 1 hours) / int128(uint128(_timeDelta));
        if (oneHourBaseRateX96 > maxFundingRateX96) {
            baseRateX96 = Math.mulDivUp(uint256(maxFundingRateX96), _timeDelta, 1 hours).toInt256().toInt192();
        }

        baseRateX96 = fundingX96 > 0 ? baseRateX96 : -baseRateX96;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Constants.sol";
import {M as Math} from "./Math.sol";
import "../core/interfaces/IMarketManager.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @notice Utility library for market manager
library MarketUtil {
    using SafeCast for *;

    /// @notice `Gov` uses the liquidation fund
    /// @param _state The state of the market
    /// @param _market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param _liquidationFundDelta The amount of liquidation fund to be used
    /// @param _receiver The address to receive the liquidation fund
    function govUseLiquidationFund(
        IMarketManager.State storage _state,
        IMarketDescriptor _market,
        uint128 _liquidationFundDelta,
        address _receiver
    ) public {
        int256 liquidationFundAfter = _state.globalLiquidationFund.liquidationFund -
            int256(uint256(_liquidationFundDelta));
        if (liquidationFundAfter < _state.globalLiquidationFund.liquidity.toInt256())
            revert IMarketErrors.InsufficientLiquidationFund(_liquidationFundDelta);

        _state.globalLiquidationFund.liquidationFund = liquidationFundAfter;

        emit IMarketManager.GlobalLiquidationFundGovUsed(_market, _receiver, _liquidationFundDelta);
    }

    /// @notice Increase the liquidity of a liquidation fund position
    /// @param _state The state of the market
    /// @param _market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param _account The owner of the position
    /// @param _liquidityDelta The increase in liquidity
    function increaseLiquidationFundPosition(
        IMarketManager.State storage _state,
        IMarketDescriptor _market,
        address _account,
        uint128 _liquidityDelta
    ) public {
        _state.globalLiquidationFund.liquidity += _liquidityDelta;

        int256 liquidationFundAfter = _state.globalLiquidationFund.liquidationFund + int256(uint256(_liquidityDelta));
        _state.globalLiquidationFund.liquidationFund = liquidationFundAfter;

        unchecked {
            // Because `positionLiquidityAfter` is less than or equal to `globalLiquidityAfter`, it will not overflow
            uint256 positionLiquidityAfter = _state.liquidationFundPositions[_account] + _liquidityDelta;
            _state.liquidationFundPositions[_account] = positionLiquidityAfter;

            emit IMarketManager.LiquidationFundPositionIncreased(_market, _account, positionLiquidityAfter);
        }
    }

    /// @notice Decrease the liquidity of a liquidation fund position
    /// @param _state The state of the market
    /// @param _market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param _liquidityDelta The decrease in liquidity
    /// @param _receiver The address to receive the liquidity when it is decreased
    function decreaseLiquidationFundPosition(
        IMarketManager.State storage _state,
        IMarketDescriptor _market,
        address _account,
        uint128 _liquidityDelta,
        address _receiver
    ) public {
        uint256 positionLiquidity = _state.liquidationFundPositions[_account];
        if (positionLiquidity < _liquidityDelta)
            revert IMarketErrors.InsufficientLiquidityToDecrease(positionLiquidity, _liquidityDelta);

        if (_state.globalLiquidationFund.liquidationFund < _state.globalLiquidationFund.liquidity.toInt256())
            revert IMarketErrors.LiquidationFundLoss();

        unchecked {
            _state.globalLiquidationFund.liquidity -= _liquidityDelta;
            _state.globalLiquidationFund.liquidationFund -= int256(uint256(_liquidityDelta));

            uint256 positionLiquidityAfter = positionLiquidity - _liquidityDelta;
            _state.liquidationFundPositions[_account] = positionLiquidityAfter;

            emit IMarketManager.LiquidationFundPositionDecreased(_market, _account, positionLiquidityAfter, _receiver);
        }
    }

    /// @notice Change the price vertices of a market
    /// @param _state The state of the market
    /// @param _marketPriceCfg The price configuration of the market
    /// @param _market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param _indexPriceX96 The index price used to calculate the price vertices, as a Q64.96
    function changePriceVertices(
        IMarketManager.State storage _state,
        IConfigurable.MarketPriceConfig storage _marketPriceCfg,
        IMarketDescriptor _market,
        uint160 _indexPriceX96
    ) internal {
        IMarketManager.PriceState storage priceState = _state.priceState;
        uint8 currentVertexIndex = priceState.currentVertexIndex;
        priceState.pendingVertexIndex = currentVertexIndex;

        changePriceVertex(
            _state,
            _marketPriceCfg,
            _market,
            _indexPriceX96,
            currentVertexIndex,
            Constants.LATEST_VERTEX
        );
    }

    function changePriceVertex(
        IMarketManager.State storage _state,
        IConfigurable.MarketPriceConfig storage _marketPriceCfg,
        IMarketDescriptor _market,
        uint160 _indexPriceX96,
        uint8 _startExclusive,
        uint8 _endInclusive
    ) internal {
        uint128 liquidity = uint128(
            Math.min(_state.globalLiquidityPosition.liquidity, _marketPriceCfg.maxPriceImpactLiquidity)
        );

        unchecked {
            IMarketManager.PriceVertex[10] storage priceVertices = _state.priceState.priceVertices;
            IConfigurable.VertexConfig[10] storage vertexCfgs = _marketPriceCfg.vertices;
            for (uint8 index = _startExclusive + 1; index <= _endInclusive; ++index) {
                (uint128 sizeAfter, uint128 premiumRateAfterX96) = _calculatePriceVertex(
                    vertexCfgs[index],
                    liquidity,
                    _indexPriceX96
                );
                if (index > 1) {
                    IMarketManager.PriceVertex memory previous = priceVertices[index - 1];
                    if (previous.size >= sizeAfter || previous.premiumRateX96 >= premiumRateAfterX96)
                        (sizeAfter, premiumRateAfterX96) = (previous.size, previous.premiumRateX96);
                }

                priceVertices[index].size = sizeAfter;
                priceVertices[index].premiumRateX96 = premiumRateAfterX96;
                emit IMarketManager.PriceVertexChanged(_market, index, sizeAfter, premiumRateAfterX96);

                // If the vertex represented by end is the same as the vertex represented by end + 1,
                // then the vertices in range (start, LATEST_VERTEX] need to be updated
                if (index == _endInclusive && _endInclusive < Constants.LATEST_VERTEX) {
                    IMarketManager.PriceVertex memory next = priceVertices[index + 1];
                    if (sizeAfter >= next.size || premiumRateAfterX96 >= next.premiumRateX96)
                        _endInclusive = Constants.LATEST_VERTEX;
                }
            }
        }
    }

    /// @notice Validate the leverage of a position
    /// @param _margin The margin of the position
    /// @param _liquidity The liquidity of the position
    /// @param _maxLeverage The maximum acceptable leverage of the position
    function validateLeverage(uint256 _margin, uint128 _liquidity, uint32 _maxLeverage) internal pure {
        if (_margin * _maxLeverage < _liquidity)
            revert IMarketErrors.LeverageTooHigh(_margin, _liquidity, _maxLeverage);
    }

    /// @notice Validate the margin of a position
    /// @param _margin The margin of the position
    /// @param _minMargin The minimum acceptable margin of the position
    function validateMargin(uint128 _margin, uint64 _minMargin) internal pure {
        if (_margin < _minMargin) revert IMarketErrors.InsufficientMargin();
    }

    function globalLiquidityPositionNetSize(
        IMarketManager.GlobalLiquidityPosition storage _position
    ) internal view returns (uint136) {
        // prettier-ignore
        unchecked { return uint136(_position.netSize) + _position.liquidationBufferNetSize; }
    }

    /// @notice Initialize the previous Settlement Point Price if it is not initialized
    /// @dev This function MUST be called when the trader's position is changed, to ensure that the LP can correctly
    /// initialize the Settlment Point Price after holding the net position
    /// @param _market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param _netSizeSnapshot The net size of the LP position before the trader's position is changed
    /// @param _tradePriceX96 The trade price when operating the trader's position, as a Q64.96
    function initializePreviousSPPrice(
        IMarketManager.GlobalLiquidityPosition storage _position,
        IMarketDescriptor _market,
        uint136 _netSizeSnapshot,
        uint160 _tradePriceX96
    ) internal {
        if (_netSizeSnapshot == 0) {
            _position.previousSPPriceX96 = _tradePriceX96;
            emit IMarketLiquidityPosition.PreviousSPPriceInitialized(_market, _tradePriceX96);
        }
    }

    /// @notice Settle the unrealized PnL of the LP position
    /// @dev This function MUST be called before the following actions:
    ///     1. Increase liquidity's position
    ///     2. Decrease liquidity's position
    ///     3. Liquidate liquidity's position
    ///     4. Increase trader's position
    ///     5. Decrease trader's position
    ///     6. Liquidate trader's position
    /// @param _position The global liquidity position of market
    function settleLiquidityUnrealizedPnL(
        IMarketManager.GlobalLiquidityPosition storage _position,
        IMarketDescriptor _market,
        uint136 _totalNetSize,
        uint160 _spPriceAfterX96
    ) internal {
        if (_totalNetSize == 0) return;

        Side side = _position.side;
        bool isSameSign;
        int256 unrealizedPnLGrowthDeltaX64;
        unchecked {
            int256 priceDeltaX96 = int256(uint256(_spPriceAfterX96)) - int256(uint256(_position.previousSPPriceX96));
            int256 totalNetSizeInt256 = side.isLong()
                ? int256(uint256(_totalNetSize))
                : -int256(uint256(_totalNetSize));
            isSameSign = (priceDeltaX96 ^ totalNetSizeInt256) >= 0;
            // abs(priceDeltaX96) * totalNetSize / (liquidity * (1 << 32))
            unrealizedPnLGrowthDeltaX64 = Math
                .mulDiv(
                    priceDeltaX96 >= 0 ? uint256(priceDeltaX96) : uint256(-priceDeltaX96),
                    _totalNetSize,
                    uint256(_position.liquidity) << 32,
                    isSameSign ? Math.Rounding.Down : Math.Rounding.Up
                )
                .toInt256();
        }
        int256 unrealizedPnLGrowthAfterX64 = _position.unrealizedPnLGrowthX64 +
            (isSameSign ? unrealizedPnLGrowthDeltaX64 : -unrealizedPnLGrowthDeltaX64);

        _position.unrealizedPnLGrowthX64 = unrealizedPnLGrowthAfterX64;
        _position.previousSPPriceX96 = _spPriceAfterX96;

        emit IMarketLiquidityPosition.SettlementPointReached(_market, unrealizedPnLGrowthAfterX64, _spPriceAfterX96);
    }

    /// @dev The function selects the appropriate index price based on the given side (Long or Short).
    /// For Long positions, it returns the minimum index price; for Short positions, it returns the maximum
    /// index price.
    /// @param _side The side of the position: Long for decreasing long position, Short for decreasing short position.
    /// @return indexPriceX96 The selected index price, as a Q64.96
    function chooseDecreaseIndexPriceX96(
        IPriceFeed _priceFeed,
        IMarketDescriptor _market,
        Side _side
    ) internal view returns (uint160) {
        return chooseIndexPriceX96(_priceFeed, _market, _side.flip());
    }

    /// @dev The function selects the appropriate index price based on the given side (Long or Short).
    /// For Long positions, it returns the maximum index price; for Short positions, it returns the minimum
    /// index price.
    /// @param _side The side of the position: Long for increasing long position or decreasing short position,
    /// Short for increasing short position or decreasing long position.
    /// @return indexPriceX96 The selected index price, as a Q64.96
    function chooseIndexPriceX96(
        IPriceFeed _priceFeed,
        IMarketDescriptor _market,
        Side _side
    ) internal view returns (uint160) {
        return _side.isLong() ? _priceFeed.getMaxPriceX96(_market) : _priceFeed.getMinPriceX96(_market);
    }

    function _validateGlobalLiquidity(uint128 _globalLiquidity) private pure {
        if (_globalLiquidity == 0) revert IMarketErrors.InsufficientGlobalLiquidity();
    }

    function _calculatePriceVertex(
        IConfigurable.VertexConfig memory _vertexCfg,
        uint128 _liquidity,
        uint160 _indexPriceX96
    ) private pure returns (uint128 size, uint128 premiumRateX96) {
        unchecked {
            uint256 balanceRateX96 = (Constants.Q96 * _vertexCfg.balanceRate) / Constants.BASIS_POINTS_DIVISOR;
            size = Math.mulDiv(balanceRateX96, _liquidity, _indexPriceX96).toUint128();

            premiumRateX96 = uint128((Constants.Q96 * _vertexCfg.premiumRate) / Constants.BASIS_POINTS_DIVISOR);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Math as _math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Math library
/// @dev Derived from OpenZeppelin's Math library. To avoid conflicts with OpenZeppelin's Math,
/// it has been renamed to `M` here. Import it using the following statement:
///      import {M as Math} from "path/to/Math.sol";
library M {
    enum Rounding {
        Up,
        Down
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Calculate `a / b` with rounding up
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // Guarantee the same behavior as in a regular Solidity division
        if (b == 0) return a / b;

        // prettier-ignore
        unchecked { return a == 0 ? 0 : (a - 1) / b + 1; }
    }

    /// @notice Calculate `x * y / denominator` with rounding down
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        return _math.mulDiv(x, y, denominator);
    }

    /// @notice Calculate `x * y / denominator` with rounding up
    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        return _math.mulDiv(x, y, denominator, _math.Rounding.Ceil);
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        return _math.mulDiv(x, y, denominator, rounding == Rounding.Up ? _math.Rounding.Ceil : _math.Rounding.Floor);
    }

    /// @notice Calculate `x * y / denominator` with rounding down and up
    /// @return result Result with rounding down
    /// @return resultUp Result with rounding up
    function mulDiv2(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result, uint256 resultUp) {
        result = _math.mulDiv(x, y, denominator);
        resultUp = result;
        if (mulmod(x, y, denominator) > 0) resultUp += 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./PriceUtil.sol";
import "./FundingRateUtil.sol";

/// @notice Utility library for trader positions
library PositionUtil {
    using SafeCast for *;

    struct IncreasePositionParameter {
        IMarketDescriptor market;
        address account;
        Side side;
        uint128 marginDelta;
        uint128 sizeDelta;
        IPriceFeed priceFeed;
    }

    struct DecreasePositionParameter {
        IMarketDescriptor market;
        address account;
        Side side;
        uint128 marginDelta;
        uint128 sizeDelta;
        IPriceFeed priceFeed;
        address receiver;
    }

    struct LiquidatePositionParameter {
        IMarketDescriptor market;
        address account;
        Side side;
        IPriceFeed priceFeed;
        address feeReceiver;
    }

    struct MaintainMarginRateParameter {
        int256 margin;
        Side side;
        uint128 size;
        uint160 entryPriceX96;
        uint160 decreasePriceX96;
        bool liquidatablePosition;
    }

    struct LiquidateParameter {
        IMarketDescriptor market;
        address account;
        Side side;
        uint160 tradePriceX96;
        uint160 decreaseIndexPriceX96;
        int256 requiredFundingFee;
        address feeReceiver;
    }

    /// @notice Change the maximum available size after the liquidity changes
    /// @param _state The state of the market
    /// @param _baseCfg The base configuration of the market
    /// @param _market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param _indexPriceX96 The index price of the market, as a Q64.96
    function changeMaxSize(
        IMarketManager.State storage _state,
        IConfigurable.MarketBaseConfig storage _baseCfg,
        IMarketDescriptor _market,
        uint160 _indexPriceX96
    ) public {
        unchecked {
            uint128 maxSizeAfter = Math
                .mulDiv(
                    Math.min(_state.globalLiquidityPosition.liquidity, _baseCfg.maxPositionLiquidity),
                    uint256(_baseCfg.maxPositionValueRate) << 96,
                    uint256(Constants.BASIS_POINTS_DIVISOR) * _indexPriceX96
                )
                .toUint128();
            uint128 maxSizePerPositionAfter = uint128(
                (uint256(maxSizeAfter) * _baseCfg.maxSizeRatePerPosition) / Constants.BASIS_POINTS_DIVISOR
            );

            IMarketManager.GlobalPosition storage position = _state.globalPosition;
            position.maxSize = maxSizeAfter;
            position.maxSizePerPosition = maxSizePerPositionAfter;

            emit IMarketPosition.GlobalPositionSizeChanged(_market, maxSizeAfter, maxSizePerPositionAfter);
        }
    }

    function increasePosition(
        IMarketManager.State storage _state,
        IConfigurable.MarketConfig storage _marketCfg,
        IncreasePositionParameter memory _parameter
    ) public returns (uint160 tradePriceX96) {
        _parameter.side.requireValid();

        IConfigurable.MarketBaseConfig storage baseCfg = _marketCfg.baseConfig;
        IMarketManager.Position memory positionCache = _state.positions[_parameter.account][_parameter.side];
        if (positionCache.size == 0) {
            if (_parameter.sizeDelta == 0) revert IMarketErrors.PositionNotFound(_parameter.account, _parameter.side);

            MarketUtil.validateMargin(_parameter.marginDelta, baseCfg.minMarginPerPosition);
        }

        _validateGlobalLiquidity(_state.globalLiquidityPosition.liquidity);

        uint128 sizeAfter = positionCache.size;
        if (_parameter.sizeDelta > 0) {
            sizeAfter = _validateIncreaseSize(_state.globalPosition, positionCache.size, _parameter.sizeDelta);

            uint160 indexPriceX96 = MarketUtil.chooseIndexPriceX96(
                _parameter.priceFeed,
                _parameter.market,
                _parameter.side
            );

            uint136 netSizeSnapshot = MarketUtil.globalLiquidityPositionNetSize(_state.globalLiquidityPosition);

            IConfigurable.MarketPriceConfig storage priceConfig = _marketCfg.priceConfig;
            tradePriceX96 = PriceUtil.updatePriceState(
                _state.globalLiquidityPosition,
                _state.priceState,
                PriceUtil.UpdatePriceStateParameter({
                    market: _parameter.market,
                    side: _parameter.side,
                    sizeDelta: _parameter.sizeDelta,
                    indexPriceX96: indexPriceX96,
                    liquidationVertexIndex: priceConfig.liquidationVertexIndex,
                    liquidation: false,
                    dynamicDepthMode: priceConfig.dynamicDepthMode,
                    dynamicDepthLevel: priceConfig.dynamicDepthLevel
                })
            );

            _initializeAndSettleLiquidityUnrealizedPnL(
                _state.globalLiquidityPosition,
                _parameter.market,
                netSizeSnapshot,
                tradePriceX96
            );
        }

        int192 globalFundingRateGrowthX96 = chooseFundingRateGrowthX96(_state.globalPosition, _parameter.side);
        int256 fundingFee = calculateFundingFee(
            globalFundingRateGrowthX96,
            positionCache.entryFundingRateGrowthX96,
            positionCache.size
        );

        int256 marginAfter = int256(uint256(positionCache.margin) + _parameter.marginDelta) + fundingFee;

        uint160 entryPriceAfterX96 = calculateNextEntryPriceX96(
            _parameter.side,
            positionCache.size,
            positionCache.entryPriceX96,
            _parameter.sizeDelta,
            tradePriceX96
        );

        _validatePositionLiquidateMaintainMarginRate(
            baseCfg,
            MaintainMarginRateParameter({
                margin: marginAfter,
                side: _parameter.side,
                size: sizeAfter,
                entryPriceX96: entryPriceAfterX96,
                decreasePriceX96: MarketUtil.chooseDecreaseIndexPriceX96(
                    _parameter.priceFeed,
                    _parameter.market,
                    _parameter.side
                ),
                liquidatablePosition: false
            })
        );
        uint128 marginAfterUint128 = uint256(marginAfter).toUint128();

        if (_parameter.sizeDelta > 0) {
            MarketUtil.validateLeverage(
                marginAfterUint128,
                calculateLiquidity(sizeAfter, entryPriceAfterX96),
                baseCfg.maxLeveragePerPosition
            );
            _increaseGlobalPosition(_state.globalPosition, _parameter.side, _parameter.sizeDelta);
        }

        IMarketManager.Position storage position = _state.positions[_parameter.account][_parameter.side];
        position.margin = marginAfterUint128;
        position.size = sizeAfter;
        position.entryPriceX96 = entryPriceAfterX96;
        position.entryFundingRateGrowthX96 = globalFundingRateGrowthX96;
        emit IMarketPosition.PositionIncreased(
            _parameter.market,
            _parameter.account,
            _parameter.side,
            _parameter.marginDelta,
            marginAfterUint128,
            sizeAfter,
            tradePriceX96,
            entryPriceAfterX96,
            fundingFee
        );
    }

    function decreasePosition(
        IMarketManager.State storage _state,
        IConfigurable.MarketConfig storage _marketCfg,
        DecreasePositionParameter memory _parameter
    ) public returns (uint160 tradePriceX96, uint128 adjustedMarginDelta) {
        IMarketManager.Position memory positionCache = _state.positions[_parameter.account][_parameter.side];
        if (positionCache.size == 0) revert IMarketErrors.PositionNotFound(_parameter.account, _parameter.side);

        if (positionCache.size < _parameter.sizeDelta)
            revert IMarketErrors.InsufficientSizeToDecrease(positionCache.size, _parameter.sizeDelta);

        uint160 decreaseIndexPriceX96 = MarketUtil.chooseDecreaseIndexPriceX96(
            _parameter.priceFeed,
            _parameter.market,
            _parameter.side
        );

        uint128 sizeAfter = positionCache.size;
        int256 realizedPnLDelta;
        if (_parameter.sizeDelta > 0) {
            // never underflow because of the validation above
            // prettier-ignore
            unchecked { sizeAfter -= _parameter.sizeDelta; }

            uint136 netSizeSnapshot = MarketUtil.globalLiquidityPositionNetSize(_state.globalLiquidityPosition);

            IConfigurable.MarketPriceConfig storage priceConfig = _marketCfg.priceConfig;
            tradePriceX96 = PriceUtil.updatePriceState(
                _state.globalLiquidityPosition,
                _state.priceState,
                PriceUtil.UpdatePriceStateParameter({
                    market: _parameter.market,
                    side: _parameter.side.flip(),
                    sizeDelta: _parameter.sizeDelta,
                    indexPriceX96: decreaseIndexPriceX96,
                    liquidationVertexIndex: _marketCfg.priceConfig.liquidationVertexIndex,
                    liquidation: false,
                    dynamicDepthMode: priceConfig.dynamicDepthMode,
                    dynamicDepthLevel: priceConfig.dynamicDepthLevel
                })
            );

            _initializeAndSettleLiquidityUnrealizedPnL(
                _state.globalLiquidityPosition,
                _parameter.market,
                netSizeSnapshot,
                tradePriceX96
            );

            realizedPnLDelta = calculateUnrealizedPnL(
                _parameter.side,
                _parameter.sizeDelta,
                positionCache.entryPriceX96,
                tradePriceX96
            );
        }

        int192 globalFundingRateGrowthX96 = chooseFundingRateGrowthX96(_state.globalPosition, _parameter.side);
        int256 fundingFee = calculateFundingFee(
            globalFundingRateGrowthX96,
            positionCache.entryFundingRateGrowthX96,
            positionCache.size
        );

        int256 marginAfter = int256(uint256(positionCache.margin));
        marginAfter += realizedPnLDelta + fundingFee - int256(uint256(_parameter.marginDelta));
        if (marginAfter < 0) revert IMarketErrors.InsufficientMargin();

        uint128 marginAfterUint128 = uint256(marginAfter).toUint128();
        if (sizeAfter > 0) {
            IConfigurable.MarketBaseConfig storage baseCfg = _marketCfg.baseConfig;
            _validatePositionLiquidateMaintainMarginRate(
                baseCfg,
                MaintainMarginRateParameter({
                    margin: marginAfter,
                    side: _parameter.side,
                    size: sizeAfter,
                    entryPriceX96: positionCache.entryPriceX96,
                    decreasePriceX96: decreaseIndexPriceX96,
                    liquidatablePosition: false
                })
            );
            if (_parameter.marginDelta > 0)
                MarketUtil.validateLeverage(
                    marginAfterUint128,
                    calculateLiquidity(sizeAfter, positionCache.entryPriceX96),
                    baseCfg.maxLeveragePerPosition
                );

            // Update position
            IMarketManager.Position storage position = _state.positions[_parameter.account][_parameter.side];
            position.margin = marginAfterUint128;
            position.size = sizeAfter;
            position.entryFundingRateGrowthX96 = globalFundingRateGrowthX96;
        } else {
            // If the position is closed, the marginDelta needs to be added back to ensure that the
            // remaining margin of the position is 0.
            _parameter.marginDelta += marginAfterUint128;
            marginAfterUint128 = 0;

            // Delete position
            delete _state.positions[_parameter.account][_parameter.side];
        }

        adjustedMarginDelta = _parameter.marginDelta;

        if (_parameter.sizeDelta > 0)
            _decreaseGlobalPosition(_state.globalPosition, _parameter.side, _parameter.sizeDelta);

        emit IMarketPosition.PositionDecreased(
            _parameter.market,
            _parameter.account,
            _parameter.side,
            adjustedMarginDelta,
            marginAfterUint128,
            sizeAfter,
            tradePriceX96,
            realizedPnLDelta,
            fundingFee,
            _parameter.receiver
        );
    }

    function liquidatePosition(
        IMarketManager.State storage _state,
        IConfigurable.MarketConfig storage _marketCfg,
        LiquidatePositionParameter memory _parameter
    ) public {
        IMarketManager.Position memory positionCache = _state.positions[_parameter.account][_parameter.side];
        if (positionCache.size == 0) revert IMarketErrors.PositionNotFound(_parameter.account, _parameter.side);

        uint160 decreaseIndexPriceX96 = MarketUtil.chooseDecreaseIndexPriceX96(
            _parameter.priceFeed,
            _parameter.market,
            _parameter.side
        );

        int256 requiredFundingFee = calculateFundingFee(
            chooseFundingRateGrowthX96(_state.globalPosition, _parameter.side),
            positionCache.entryFundingRateGrowthX96,
            positionCache.size
        );

        _validatePositionLiquidateMaintainMarginRate(
            _marketCfg.baseConfig,
            MaintainMarginRateParameter({
                margin: int256(uint256(positionCache.margin)) + requiredFundingFee,
                side: _parameter.side,
                size: positionCache.size,
                entryPriceX96: positionCache.entryPriceX96,
                decreasePriceX96: decreaseIndexPriceX96,
                liquidatablePosition: true
            })
        );

        uint136 netSizeSnapshot = MarketUtil.globalLiquidityPositionNetSize(_state.globalLiquidityPosition);

        // try to update price state
        IConfigurable.MarketPriceConfig storage priceConfig = _marketCfg.priceConfig;
        uint160 tradePriceX96 = PriceUtil.updatePriceState(
            _state.globalLiquidityPosition,
            _state.priceState,
            PriceUtil.UpdatePriceStateParameter({
                market: _parameter.market,
                side: _parameter.side.flip(),
                sizeDelta: positionCache.size,
                indexPriceX96: decreaseIndexPriceX96,
                liquidationVertexIndex: _marketCfg.priceConfig.liquidationVertexIndex,
                liquidation: true,
                dynamicDepthMode: priceConfig.dynamicDepthMode,
                dynamicDepthLevel: priceConfig.dynamicDepthLevel
            })
        );

        _initializeAndSettleLiquidityUnrealizedPnL(
            _state.globalLiquidityPosition,
            _parameter.market,
            netSizeSnapshot,
            tradePriceX96
        );

        liquidatePosition(
            _state,
            _marketCfg,
            positionCache,
            LiquidateParameter({
                market: _parameter.market,
                account: _parameter.account,
                side: _parameter.side,
                tradePriceX96: tradePriceX96,
                decreaseIndexPriceX96: decreaseIndexPriceX96,
                requiredFundingFee: requiredFundingFee,
                feeReceiver: _parameter.feeReceiver
            })
        );
    }

    function liquidatePosition(
        IMarketManager.State storage _state,
        IConfigurable.MarketConfig storage _marketCfg,
        IMarketManager.Position memory _positionCache,
        LiquidateParameter memory _parameter
    ) internal {
        IConfigurable.MarketBaseConfig storage baseCfg = _marketCfg.baseConfig;
        (uint64 liquidationExecutionFee, uint32 liquidationFeeRate) = (
            baseCfg.liquidationExecutionFee,
            baseCfg.liquidationFeeRatePerPosition
        );
        (uint160 liquidationPriceX96, int256 adjustedFundingFee) = calculateLiquidationPriceX96(
            _positionCache,
            _parameter.side,
            _parameter.requiredFundingFee,
            liquidationFeeRate,
            liquidationExecutionFee
        );

        uint128 liquidationFee = calculateLiquidationFee(
            _positionCache.size,
            _positionCache.entryPriceX96,
            liquidationFeeRate
        );
        int256 liquidationFundDelta = int256(uint256(liquidationFee));

        if (_parameter.requiredFundingFee != adjustedFundingFee)
            liquidationFundDelta += _adjustFundingRateByLiquidation(
                _state,
                _parameter.market,
                _parameter.side,
                _parameter.requiredFundingFee,
                adjustedFundingFee
            );

        // If the liquidation price is different from the trade price,
        // the funds of the difference need to be transferred
        liquidationFundDelta += calculateUnrealizedPnL(
            _parameter.side,
            _positionCache.size,
            liquidationPriceX96,
            _parameter.tradePriceX96
        );

        IMarketManager.GlobalLiquidationFund storage globalLiquidationFund = _state.globalLiquidationFund;
        int256 liquidationFundAfter = globalLiquidationFund.liquidationFund + liquidationFundDelta;
        globalLiquidationFund.liquidationFund = liquidationFundAfter;
        emit IMarketManager.GlobalLiquidationFundIncreasedByLiquidation(
            _parameter.market,
            liquidationFundDelta,
            liquidationFundAfter
        );

        _decreaseGlobalPosition(_state.globalPosition, _parameter.side, _positionCache.size);

        delete _state.positions[_parameter.account][_parameter.side];

        emit IMarketPosition.PositionLiquidated(
            _parameter.market,
            msg.sender,
            _parameter.account,
            _parameter.side,
            _parameter.decreaseIndexPriceX96,
            _parameter.tradePriceX96,
            liquidationPriceX96,
            adjustedFundingFee,
            liquidationFee,
            liquidationExecutionFee,
            _parameter.feeReceiver
        );
    }

    /// @notice Calculate the next entry price of a position
    /// @param _side The side of the position (Long or Short)
    /// @param _sizeBefore The size of the position before the trade
    /// @param _entryPriceBeforeX96 The entry price of the position before the trade, as a Q64.96
    /// @param _sizeDelta The size of the trade
    /// @param _tradePriceX96 The price of the trade, as a Q64.96
    /// @return nextEntryPriceX96 The entry price of the position after the trade, as a Q64.96
    function calculateNextEntryPriceX96(
        Side _side,
        uint128 _sizeBefore,
        uint160 _entryPriceBeforeX96,
        uint128 _sizeDelta,
        uint160 _tradePriceX96
    ) internal pure returns (uint160 nextEntryPriceX96) {
        if ((_sizeBefore | _sizeDelta) == 0) nextEntryPriceX96 = 0;
        else if (_sizeBefore == 0) nextEntryPriceX96 = _tradePriceX96;
        else if (_sizeDelta == 0) nextEntryPriceX96 = _entryPriceBeforeX96;
        else {
            uint256 liquidityAfterX96 = uint256(_sizeBefore) * _entryPriceBeforeX96;
            liquidityAfterX96 += uint256(_sizeDelta) * _tradePriceX96;
            unchecked {
                uint256 sizeAfter = uint256(_sizeBefore) + _sizeDelta;
                nextEntryPriceX96 = (
                    _side.isLong() ? Math.ceilDiv(liquidityAfterX96, sizeAfter) : liquidityAfterX96 / sizeAfter
                ).toUint160();
            }
        }
    }

    /// @notice Calculate the liquidity (value) of a position
    /// @param _size The size of the position
    /// @param _priceX96 The trade price, as a Q64.96
    /// @return liquidity The liquidity (value) of the position
    function calculateLiquidity(uint128 _size, uint160 _priceX96) internal pure returns (uint128 liquidity) {
        liquidity = Math.mulDivUp(_size, _priceX96, Constants.Q96).toUint128();
    }

    /// @dev Calculate the unrealized PnL of a position based on entry price
    /// @param _side The side of the position (Long or Short)
    /// @param _size The size of the position
    /// @param _entryPriceX96 The entry price of the position, as a Q64.96
    /// @param _priceX96 The trade price or index price, as a Q64.96
    /// @return unrealizedPnL The unrealized PnL of the position, positive value means profit,
    /// negative value means loss
    function calculateUnrealizedPnL(
        Side _side,
        uint128 _size,
        uint160 _entryPriceX96,
        uint160 _priceX96
    ) internal pure returns (int256 unrealizedPnL) {
        unchecked {
            // Because the maximum value of size is type(uint128).max, and the maximum value of entryPriceX96 and
            // priceX96 is type(uint160).max, so the maximum value of
            //      size * (entryPriceX96 - priceX96) / Q96
            // is type(uint192).max, so it is safe to convert the type to int256.
            if (_side.isLong()) {
                if (_entryPriceX96 > _priceX96)
                    unrealizedPnL = -int256(Math.mulDivUp(_size, _entryPriceX96 - _priceX96, Constants.Q96));
                else unrealizedPnL = int256(Math.mulDiv(_size, _priceX96 - _entryPriceX96, Constants.Q96));
            } else {
                if (_entryPriceX96 < _priceX96)
                    unrealizedPnL = -int256(Math.mulDivUp(_size, _priceX96 - _entryPriceX96, Constants.Q96));
                else unrealizedPnL = int256(Math.mulDiv(_size, _entryPriceX96 - _priceX96, Constants.Q96));
            }
        }
    }

    function chooseFundingRateGrowthX96(
        IMarketManager.GlobalPosition storage _globalPosition,
        Side _side
    ) internal view returns (int192) {
        return _side.isLong() ? _globalPosition.longFundingRateGrowthX96 : _globalPosition.shortFundingRateGrowthX96;
    }

    /// @notice Calculate the liquidation fee of a position
    /// @param _size The size of the position
    /// @param _entryPriceX96 The entry price of the position, as a Q64.96
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return liquidationFee The liquidation fee of the position
    function calculateLiquidationFee(
        uint128 _size,
        uint160 _entryPriceX96,
        uint32 _liquidationFeeRate
    ) internal pure returns (uint128 liquidationFee) {
        unchecked {
            uint256 denominator = Constants.BASIS_POINTS_DIVISOR * Constants.Q96;
            liquidationFee = Math
                .mulDivUp(uint256(_size) * _liquidationFeeRate, _entryPriceX96, denominator)
                .toUint128();
        }
    }

    /// @notice Calculate the funding fee of a position
    /// @param _globalFundingRateGrowthX96 The global funding rate growth, as a Q96.96
    /// @param _positionFundingRateGrowthX96 The position funding rate growth, as a Q96.96
    /// @param _positionSize The size of the position
    /// @return fundingFee The funding fee of the position, a positive value means the position receives
    /// funding fee, while a negative value means the position pays funding fee
    function calculateFundingFee(
        int192 _globalFundingRateGrowthX96,
        int192 _positionFundingRateGrowthX96,
        uint128 _positionSize
    ) internal pure returns (int256 fundingFee) {
        int256 deltaX96 = _globalFundingRateGrowthX96 - _positionFundingRateGrowthX96;
        if (deltaX96 >= 0) fundingFee = Math.mulDiv(uint256(deltaX96), _positionSize, Constants.Q96).toInt256();
        else fundingFee = -Math.mulDivUp(uint256(-deltaX96), _positionSize, Constants.Q96).toInt256();
    }

    /// @notice Calculate the maintenance margin
    /// @dev maintenanceMargin = size * entryPrice * liquidationFeeRate
    ///                          + liquidationExecutionFee
    /// @param _size The size of the position
    /// @param _entryPriceX96 The entry price of the position, as a Q64.96
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _liquidationExecutionFee The liquidation execution fee paid by the position
    /// @return maintenanceMargin The maintenance margin
    function calculateMaintenanceMargin(
        uint128 _size,
        uint160 _entryPriceX96,
        uint32 _liquidationFeeRate,
        uint64 _liquidationExecutionFee
    ) internal pure returns (uint256 maintenanceMargin) {
        unchecked {
            maintenanceMargin = Math.mulDivUp(
                _size,
                uint256(_entryPriceX96) * _liquidationFeeRate,
                Constants.BASIS_POINTS_DIVISOR * Constants.Q96
            );
            // Because the maximum value of size is type(uint128).max, and the maximum value of entryPriceX96
            // is type(uint160).max, and liquidationFeeRate is at most DIVISOR,
            // so the maximum value of
            //      size * entryPriceX96 * liquidationFeeRate / (Q96 * DIVISOR)
            // is type(uint192).max, so there will be no overflow here.
            maintenanceMargin += _liquidationExecutionFee;
        }
    }

    /// @notice calculate the liquidation price
    /// @param _positionCache The cache of position
    /// @param _side The side of the position (Long or Short)
    /// @param _fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _liquidationExecutionFee The liquidation execution fee paid by the position
    /// @return liquidationPriceX96 The liquidation price of the position, as a Q64.96
    /// @return adjustedFundingFee The liquidation price based on the funding fee. If `_fundingFee` is negative,
    /// then this value is not less than `_fundingFee`
    function calculateLiquidationPriceX96(
        IMarketManager.Position memory _positionCache,
        Side _side,
        int256 _fundingFee,
        uint32 _liquidationFeeRate,
        uint64 _liquidationExecutionFee
    ) internal pure returns (uint160 liquidationPriceX96, int256 adjustedFundingFee) {
        int256 marginInt256 = int256(uint256(_positionCache.margin));
        if ((marginInt256 + _fundingFee) > 0) {
            liquidationPriceX96 = _calculateLiquidationPriceX96(
                _positionCache,
                _side,
                _fundingFee,
                _liquidationFeeRate,
                _liquidationExecutionFee
            );
            if (_isAcceptableLiquidationPriceX96(_side, liquidationPriceX96, _positionCache.entryPriceX96))
                return (liquidationPriceX96, _fundingFee);
        }

        adjustedFundingFee = _fundingFee;

        if (adjustedFundingFee < 0) {
            adjustedFundingFee = 0;
            liquidationPriceX96 = _calculateLiquidationPriceX96(
                _positionCache,
                _side,
                adjustedFundingFee,
                _liquidationFeeRate,
                _liquidationExecutionFee
            );
        }
    }

    function _isAcceptableLiquidationPriceX96(
        Side _side,
        uint160 _liquidationPriceX96,
        uint160 _entryPriceX96
    ) private pure returns (bool) {
        return
            (_side.isLong() && _liquidationPriceX96 < _entryPriceX96) ||
            (_side.isShort() && _liquidationPriceX96 > _entryPriceX96);
    }

    /// @notice Calculate the liquidation price
    /// @dev Given the liquidation condition as:
    /// For long position: margin + fundingFee - positionSize * (entryPrice - liquidationPrice)
    ///                     = entryPrice * positionSize * liquidationFeeRate + liquidationExecutionFee
    /// For short position: margin + fundingFee - positionSize * (liquidationPrice - entryPrice)
    ///                     = entryPrice * positionSize * liquidationFeeRate + liquidationExecutionFee
    /// @param _positionCache The cache of position
    /// @param _side The side of the position (Long or Short)
    /// @param _fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _liquidationExecutionFee The liquidation execution fee paid by the position
    /// @return liquidationPriceX96 The liquidation price of the position, as a Q64.96
    function _calculateLiquidationPriceX96(
        IMarketManager.Position memory _positionCache,
        Side _side,
        int256 _fundingFee,
        uint32 _liquidationFeeRate,
        uint64 _liquidationExecutionFee
    ) private pure returns (uint160 liquidationPriceX96) {
        int136 marginAfter = int136(uint136(_positionCache.margin)) + _fundingFee.toInt136();
        marginAfter -= int136(uint136(_liquidationExecutionFee));

        int256 step1X96;
        int256 step2X96;
        unchecked {
            uint32 feeRateDelta = _side.isLong()
                ? Constants.BASIS_POINTS_DIVISOR + _liquidationFeeRate
                : Constants.BASIS_POINTS_DIVISOR - _liquidationFeeRate;
            step1X96 = Math
                .mulDiv(
                    _positionCache.entryPriceX96,
                    feeRateDelta,
                    Constants.BASIS_POINTS_DIVISOR,
                    _side.isLong() ? Math.Rounding.Down : Math.Rounding.Up
                )
                .toInt256();

            if (marginAfter >= 0)
                step2X96 = int256(Math.ceilDiv(uint256(uint136(marginAfter)) << 96, _positionCache.size));
            else step2X96 = int256((uint256(uint144(-int144(marginAfter))) << 96) / _positionCache.size);
        }

        if (_side.isLong())
            liquidationPriceX96 = (step1X96 - (marginAfter >= 0 ? step2X96 : -step2X96)).toUint256().toUint160();
        else liquidationPriceX96 = (step1X96 + (marginAfter >= 0 ? step2X96 : -step2X96)).toUint256().toUint160();
    }

    function _validateIncreaseSize(
        IMarketManager.GlobalPosition storage _position,
        uint128 _sizeBefore,
        uint128 _sizeDelta
    ) private view returns (uint128 sizeAfter) {
        sizeAfter = _sizeBefore + _sizeDelta;
        if (sizeAfter > _position.maxSizePerPosition)
            revert IMarketErrors.SizeExceedsMaxSizePerPosition(sizeAfter, _position.maxSizePerPosition);

        uint128 totalSizeAfter = _position.longSize + _position.shortSize + _sizeDelta;
        if (totalSizeAfter > _position.maxSize)
            revert IMarketErrors.SizeExceedsMaxSize(totalSizeAfter, _position.maxSize);
    }

    function _validateGlobalLiquidity(uint128 _globalLiquidity) private pure {
        if (_globalLiquidity == 0) revert IMarketErrors.InsufficientGlobalLiquidity();
    }

    function _increaseGlobalPosition(
        IMarketManager.GlobalPosition storage _globalPosition,
        Side _side,
        uint128 _size
    ) private {
        unchecked {
            if (_side.isLong()) _globalPosition.longSize += _size;
            else _globalPosition.shortSize += _size;
        }
    }

    function _decreaseGlobalPosition(
        IMarketManager.GlobalPosition storage _globalPosition,
        Side _side,
        uint128 _size
    ) private {
        unchecked {
            if (_side.isLong()) _globalPosition.longSize -= _size;
            else _globalPosition.shortSize -= _size;
        }
    }

    function _adjustFundingRateByLiquidation(
        IMarketManager.State storage _state,
        IMarketDescriptor _market,
        Side _side,
        int256 _requiredFundingFee,
        int256 _adjustedFundingFee
    ) private returns (int256 liquidationFundLoss) {
        int256 insufficientFundingFee = _adjustedFundingFee - _requiredFundingFee;
        IMarketManager.GlobalPosition storage globalPosition = _state.globalPosition;
        uint128 oppositeSize = _side.isLong() ? globalPosition.shortSize : globalPosition.longSize;
        if (oppositeSize > 0) {
            int192 insufficientFundingRateGrowthDeltaX96 = Math
                .mulDiv(uint256(insufficientFundingFee), Constants.Q96, oppositeSize)
                .toInt256()
                .toInt192();
            int192 longFundingRateGrowthAfterX96 = globalPosition.longFundingRateGrowthX96;
            int192 shortFundingRateGrowthAfterX96 = globalPosition.shortFundingRateGrowthX96;
            if (_side.isLong()) shortFundingRateGrowthAfterX96 -= insufficientFundingRateGrowthDeltaX96;
            else longFundingRateGrowthAfterX96 -= insufficientFundingRateGrowthDeltaX96;
            FundingRateUtil.adjustFundingRate(
                _state,
                _market,
                longFundingRateGrowthAfterX96,
                shortFundingRateGrowthAfterX96
            );
        } else liquidationFundLoss = -insufficientFundingFee;
    }

    /// @notice Validate the position has not reached the liquidation margin rate
    function _validatePositionLiquidateMaintainMarginRate(
        IConfigurable.MarketBaseConfig storage _baseCfg,
        MaintainMarginRateParameter memory _parameter
    ) private view {
        int256 unrealizedPnL = calculateUnrealizedPnL(
            _parameter.side,
            _parameter.size,
            _parameter.entryPriceX96,
            _parameter.decreasePriceX96
        );
        uint256 maintenanceMargin = calculateMaintenanceMargin(
            _parameter.size,
            _parameter.entryPriceX96,
            _baseCfg.liquidationFeeRatePerPosition,
            _baseCfg.liquidationExecutionFee
        );
        int256 marginAfter = _parameter.margin + unrealizedPnL;
        if (!_parameter.liquidatablePosition) {
            if (_parameter.margin <= 0 || marginAfter <= 0 || maintenanceMargin >= uint256(marginAfter))
                revert IMarketErrors.MarginRateTooHigh(_parameter.margin, unrealizedPnL, maintenanceMargin);
        } else {
            if (_parameter.margin > 0 && marginAfter > 0 && maintenanceMargin < uint256(marginAfter))
                revert IMarketErrors.MarginRateTooLow(_parameter.margin, unrealizedPnL, maintenanceMargin);
        }
    }

    function _initializeAndSettleLiquidityUnrealizedPnL(
        IMarketManager.GlobalLiquidityPosition storage _position,
        IMarketDescriptor _market,
        uint136 _netSizeSnapshot,
        uint160 _tradePriceX96
    ) private {
        MarketUtil.initializePreviousSPPrice(_position, _market, _netSizeSnapshot, _tradePriceX96);
        MarketUtil.settleLiquidityUnrealizedPnL(_position, _market, _netSizeSnapshot, _tradePriceX96);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Constants.sol";
import "../core/interfaces/IMarketManager.sol";
import {M as Math} from "../libraries/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library PriceUtil {
    using SafeCast for *;

    struct UpdatePriceStateParameter {
        IMarketDescriptor market;
        Side side;
        uint128 sizeDelta;
        uint160 indexPriceX96;
        uint8 liquidationVertexIndex;
        bool liquidation;
        uint8 dynamicDepthMode;
        uint32 dynamicDepthLevel;
    }

    struct SimulateMoveStep {
        Side side;
        uint128 sizeLeft;
        uint160 indexPriceX96;
        uint160 basisIndexPriceX96;
        bool improveBalance;
        IMarketManager.PriceVertex from;
        IMarketManager.PriceVertex current;
        IMarketManager.PriceVertex to;
    }

    struct PriceStateCache {
        uint128 premiumRateX96;
        uint8 pendingVertexIndex;
        uint8 liquidationVertexIndex;
        uint8 currentVertexIndex;
        uint160 basisIndexPriceX96;
    }

    /// @notice Calculate trade price and update the price state when trader positions adjusted.
    /// @param _globalPosition Global position of the lp (will be updated)
    /// @param _priceState States of the price (will be updated)
    /// @return tradePriceX96 The average price of the adjustment
    function updatePriceState(
        IMarketManager.GlobalLiquidityPosition storage _globalPosition,
        IMarketManager.PriceState storage _priceState,
        UpdatePriceStateParameter memory _parameter
    ) internal returns (uint160 tradePriceX96) {
        if (_parameter.sizeDelta == 0) revert IMarketErrors.ZeroSizeDelta();
        IMarketManager.GlobalLiquidityPosition memory globalPositionCache = _globalPosition;
        PriceStateCache memory priceStateCache = PriceStateCache({
            premiumRateX96: _priceState.premiumRateX96,
            pendingVertexIndex: _priceState.pendingVertexIndex,
            liquidationVertexIndex: _parameter.liquidationVertexIndex,
            currentVertexIndex: _priceState.currentVertexIndex,
            basisIndexPriceX96: _priceState.basisIndexPriceX96
        });

        bool balanced = (globalPositionCache.netSize | globalPositionCache.liquidationBufferNetSize) == 0;
        if (balanced) priceStateCache.basisIndexPriceX96 = _parameter.indexPriceX96;

        bool improveBalance = _parameter.side == globalPositionCache.side && !balanced;
        (int256 tradePriceX96TimesSizeTotal, uint128 sizeLeft, uint128 totalBufferUsed) = _updatePriceState(
            globalPositionCache,
            _priceState,
            priceStateCache,
            _parameter,
            improveBalance
        );

        if (!improveBalance) {
            globalPositionCache.side = _parameter.side.flip();
            globalPositionCache.netSize += _parameter.sizeDelta - totalBufferUsed;
            globalPositionCache.liquidationBufferNetSize += totalBufferUsed;
        } else {
            // When the net position of LP decreases and reaches or crosses the vertex,
            // at least the vertex represented by (current, pending] needs to be updated
            if (priceStateCache.pendingVertexIndex > priceStateCache.currentVertexIndex) {
                IMarketManager(address(this)).changePriceVertex(
                    _parameter.market,
                    priceStateCache.currentVertexIndex,
                    priceStateCache.pendingVertexIndex
                );
                _priceState.pendingVertexIndex = priceStateCache.currentVertexIndex;
            }

            uint128 improveBalanceTotalSizeUsed = _parameter.sizeDelta - sizeLeft;
            globalPositionCache.netSize -= improveBalanceTotalSizeUsed - totalBufferUsed;
            globalPositionCache.liquidationBufferNetSize -= totalBufferUsed;

            uint160 meanPriceX96 = _parameter.side.isLong()
                ? Math.ceilDiv(uint256(tradePriceX96TimesSizeTotal), improveBalanceTotalSizeUsed).toUint160()
                : (uint256(tradePriceX96TimesSizeTotal) / improveBalanceTotalSizeUsed).toUint160();

            uint160 dynamicDepthPriceX96 = _parameter.dynamicDepthMode == 0
                ? calculateMarketPriceX96(
                    globalPositionCache.side,
                    _parameter.side,
                    _parameter.indexPriceX96,
                    priceStateCache.basisIndexPriceX96,
                    priceStateCache.premiumRateX96
                )
                : _parameter.indexPriceX96;

            uint160 improveBalanceTradePriceAfterX96;
            unchecked {
                uint256 improveBalanceTradePriceBeforeX96 = _parameter.dynamicDepthLevel *
                    uint256(dynamicDepthPriceX96) +
                    (Constants.BASIS_POINTS_DIVISOR - _parameter.dynamicDepthLevel) *
                    uint256(meanPriceX96);

                improveBalanceTradePriceAfterX96 = _parameter.side.isLong()
                    ? Math.ceilDiv(improveBalanceTradePriceBeforeX96, Constants.BASIS_POINTS_DIVISOR).toUint160()
                    : (improveBalanceTradePriceBeforeX96 / Constants.BASIS_POINTS_DIVISOR).toUint160();
            }

            tradePriceX96TimesSizeTotal = (improveBalanceTradePriceAfterX96 * uint256(improveBalanceTotalSizeUsed))
                .toInt256();
        }

        if (sizeLeft > 0) {
            assert((globalPositionCache.netSize | globalPositionCache.liquidationBufferNetSize) == 0);
            globalPositionCache.side = globalPositionCache.side.flip();

            balanced = true;
            priceStateCache.basisIndexPriceX96 = _parameter.indexPriceX96;

            uint128 sizeDeltaCopy = _parameter.sizeDelta;
            _parameter.sizeDelta = sizeLeft;
            (int256 tradePriceX96TimesSizeTotal2, , uint128 totalBufferUsed2) = _updatePriceState(
                globalPositionCache,
                _priceState,
                priceStateCache,
                _parameter,
                false
            );
            _parameter.sizeDelta = sizeDeltaCopy; // Restore the original value

            tradePriceX96TimesSizeTotal += tradePriceX96TimesSizeTotal2;

            globalPositionCache.netSize = sizeLeft - totalBufferUsed2;
            globalPositionCache.liquidationBufferNetSize = totalBufferUsed2;
        }

        if (tradePriceX96TimesSizeTotal < 0) revert IMarketErrors.InvalidTradePrice(tradePriceX96TimesSizeTotal);

        tradePriceX96 = _parameter.side.isLong()
            ? Math.ceilDiv(uint256(tradePriceX96TimesSizeTotal), _parameter.sizeDelta).toUint160()
            : (uint256(tradePriceX96TimesSizeTotal) / _parameter.sizeDelta).toUint160();

        // Write the changes back to storage
        _globalPosition.side = globalPositionCache.side;
        _globalPosition.netSize = globalPositionCache.netSize;
        _globalPosition.liquidationBufferNetSize = globalPositionCache.liquidationBufferNetSize;
        emit IMarketLiquidityPosition.GlobalLiquidityPositionNetPositionChanged(
            _parameter.market,
            globalPositionCache.side,
            globalPositionCache.netSize,
            globalPositionCache.liquidationBufferNetSize
        );
        if (balanced) {
            _priceState.basisIndexPriceX96 = priceStateCache.basisIndexPriceX96;
            emit IMarketManager.BasisIndexPriceChanged(_parameter.market, priceStateCache.basisIndexPriceX96);
        }
        _priceState.currentVertexIndex = priceStateCache.currentVertexIndex;
        _priceState.premiumRateX96 = priceStateCache.premiumRateX96;
        emit IMarketManager.PremiumRateChanged(_parameter.market, priceStateCache.premiumRateX96);
    }

    function _updatePriceState(
        IMarketManager.GlobalLiquidityPosition memory _globalPositionCache,
        IMarketManager.PriceState storage _priceState,
        PriceStateCache memory _priceStateCache,
        UpdatePriceStateParameter memory _parameter,
        bool _improveBalance
    ) internal returns (int256 tradePriceX96TimesSizeTotal, uint128 sizeLeft, uint128 totalBufferUsed) {
        SimulateMoveStep memory step = SimulateMoveStep({
            side: _parameter.side,
            sizeLeft: _parameter.sizeDelta,
            indexPriceX96: _parameter.indexPriceX96,
            basisIndexPriceX96: _priceStateCache.basisIndexPriceX96,
            improveBalance: _improveBalance,
            from: IMarketManager.PriceVertex(0, 0),
            current: IMarketManager.PriceVertex(_globalPositionCache.netSize, _priceStateCache.premiumRateX96),
            to: IMarketManager.PriceVertex(0, 0)
        });
        if (!step.improveBalance) {
            // Balance rate got worse
            if (_priceStateCache.currentVertexIndex == 0) _priceStateCache.currentVertexIndex = 1;
            uint8 end = _parameter.liquidation ? _priceStateCache.liquidationVertexIndex + 1 : Constants.VERTEX_NUM;
            for (uint8 i = _priceStateCache.currentVertexIndex; i < end && step.sizeLeft > 0; ++i) {
                (step.from, step.to) = (_priceState.priceVertices[i - 1], _priceState.priceVertices[i]);
                (int160 tradePriceX96, uint128 sizeUsed, , uint128 premiumRateAfterX96) = simulateMove(step);

                if (
                    sizeUsed < step.sizeLeft &&
                    !(_parameter.liquidation && i == _priceStateCache.liquidationVertexIndex)
                ) {
                    // Crossed
                    // prettier-ignore
                    unchecked { _priceStateCache.currentVertexIndex = i + 1; }
                    step.current = step.to;
                }

                // prettier-ignore
                unchecked { step.sizeLeft -= sizeUsed; }
                tradePriceX96TimesSizeTotal += tradePriceX96 * int256(uint256(sizeUsed));
                _priceStateCache.premiumRateX96 = premiumRateAfterX96;
            }

            if (step.sizeLeft > 0) {
                if (!_parameter.liquidation) revert IMarketErrors.MaxPremiumRateExceeded();

                step.current = step.from = step.to = _priceState.priceVertices[_priceStateCache.liquidationVertexIndex];
                (int160 tradePriceX96, , , ) = simulateMove(step);
                tradePriceX96TimesSizeTotal += tradePriceX96 * int256(uint256(step.sizeLeft));

                // prettier-ignore
                unchecked { totalBufferUsed += step.sizeLeft; }

                uint8 liquidationVertexIndex = _priceStateCache.liquidationVertexIndex;
                uint128 liquidationBufferNetSizeAfter = _priceState.liquidationBufferNetSizes[liquidationVertexIndex] +
                    step.sizeLeft;
                _priceState.liquidationBufferNetSizes[liquidationVertexIndex] = liquidationBufferNetSizeAfter;
                emit IMarketManager.LiquidationBufferNetSizeChanged(
                    _parameter.market,
                    liquidationVertexIndex,
                    liquidationBufferNetSizeAfter
                );
            }
        } else {
            // Balance rate got better, note that when `i` == 0, loop continues to use liquidation buffer in (0, 0)
            for (uint8 i = _priceStateCache.currentVertexIndex; i >= 0 && step.sizeLeft > 0; --i) {
                // Use liquidation buffer in `from`
                uint128 bufferSizeAfter = _priceState.liquidationBufferNetSizes[i];
                if (bufferSizeAfter > 0) {
                    step.from = step.to = _priceState.priceVertices[uint8(i)];
                    (int160 tradePriceX96, , , ) = simulateMove(step);
                    uint128 sizeUsed = uint128(Math.min(bufferSizeAfter, step.sizeLeft));
                    // prettier-ignore
                    unchecked { bufferSizeAfter -= sizeUsed; }
                    _priceState.liquidationBufferNetSizes[i] = bufferSizeAfter;
                    // prettier-ignore
                    unchecked { totalBufferUsed += sizeUsed; }

                    // prettier-ignore
                    unchecked { step.sizeLeft -= sizeUsed; }
                    tradePriceX96TimesSizeTotal += tradePriceX96 * int256(uint256(sizeUsed));
                    emit IMarketManager.LiquidationBufferNetSizeChanged(_parameter.market, i, bufferSizeAfter);
                }
                if (i == 0) break;
                if (step.sizeLeft > 0) {
                    step.from = _priceState.priceVertices[uint8(i)];
                    step.to = _priceState.priceVertices[uint8(i - 1)];
                    (int160 tradePriceX96, uint128 sizeUsed, bool reached, uint128 premiumRateAfterX96) = simulateMove(
                        step
                    );
                    if (reached) {
                        // Reached or crossed
                        _priceStateCache.currentVertexIndex = uint8(i - 1);
                        step.current = step.to;
                    }
                    // prettier-ignore
                    unchecked { step.sizeLeft -= sizeUsed; }
                    tradePriceX96TimesSizeTotal += tradePriceX96 * int256(uint256(sizeUsed));
                    _priceStateCache.premiumRateX96 = premiumRateAfterX96;
                }
            }
            sizeLeft = step.sizeLeft;
        }
    }

    function calculateAX248AndBX96(
        Side _globalSide,
        IMarketManager.PriceVertex memory _from,
        IMarketManager.PriceVertex memory _to
    ) internal pure returns (uint256 aX248, int256 bX96) {
        if (_from.size > _to.size) (_from, _to) = (_to, _from);
        assert(_to.premiumRateX96 >= _from.premiumRateX96);

        unchecked {
            uint128 sizeDelta = _to.size - _from.size;
            aX248 = Math.mulDivUp(_to.premiumRateX96 - _from.premiumRateX96, Constants.Q152, sizeDelta);

            uint256 numeratorPart1X96 = uint256(_from.premiumRateX96) * _to.size;
            uint256 numeratorPart2X96 = uint256(_to.premiumRateX96) * _from.size;
            if (_globalSide.isShort()) {
                if (numeratorPart1X96 >= numeratorPart2X96)
                    bX96 = ((numeratorPart1X96 - numeratorPart2X96) / sizeDelta).toInt256();
                else bX96 = -((numeratorPart2X96 - numeratorPart1X96) / sizeDelta).toInt256();
            } else {
                if (numeratorPart2X96 >= numeratorPart1X96)
                    bX96 = ((numeratorPart2X96 - numeratorPart1X96) / sizeDelta).toInt256();
                else bX96 = -((numeratorPart1X96 - numeratorPart2X96) / sizeDelta).toInt256();
            }
        }
    }

    function simulateMove(
        SimulateMoveStep memory _step
    ) internal pure returns (int160 tradePriceX96, uint128 sizeUsed, bool reached, uint128 premiumRateAfterX96) {
        (reached, sizeUsed) = calculateReachedAndSizeUsed(_step);
        premiumRateAfterX96 = calculatePremiumRateAfterX96(_step, reached, sizeUsed);
        uint128 premiumRateBeforeX96 = _step.current.premiumRateX96;
        (uint256 priceDeltaX96Down, uint256 priceDeltaX96Up) = Math.mulDiv2(
            _step.basisIndexPriceX96,
            uint256(premiumRateBeforeX96) + premiumRateAfterX96,
            Constants.Q96 << 1
        );

        if (_step.side.isLong())
            tradePriceX96 = _step.improveBalance
                ? (int256(uint256(_step.indexPriceX96)) - int256(priceDeltaX96Down)).toInt160()
                : (_step.indexPriceX96 + priceDeltaX96Up).toInt256().toInt160();
        else
            tradePriceX96 = _step.improveBalance
                ? (_step.indexPriceX96 + priceDeltaX96Down).toInt256().toInt160()
                : (int256(uint256(_step.indexPriceX96)) - int256(priceDeltaX96Up)).toInt160();
    }

    function calculateReachedAndSizeUsed(
        SimulateMoveStep memory _step
    ) internal pure returns (bool reached, uint128 sizeUsed) {
        uint128 sizeCost = _step.improveBalance
            ? _step.current.size - _step.to.size
            : _step.to.size - _step.current.size;
        reached = _step.sizeLeft >= sizeCost;
        sizeUsed = reached ? sizeCost : _step.sizeLeft;
    }

    function calculatePremiumRateAfterX96(
        SimulateMoveStep memory _step,
        bool _reached,
        uint128 _sizeUsed
    ) internal pure returns (uint128 premiumRateAfterX96) {
        if (_reached) {
            premiumRateAfterX96 = _step.to.premiumRateX96;
        } else {
            Side globalSide = _step.improveBalance ? _step.side : _step.side.flip();
            (uint256 aX248, int256 bX96) = calculateAX248AndBX96(globalSide, _step.from, _step.to);
            uint256 sizeAfter = _step.improveBalance ? _step.current.size - _sizeUsed : _step.current.size + _sizeUsed;
            if (globalSide.isLong()) bX96 = -bX96;
            premiumRateAfterX96 = (Math.mulDivUp(aX248, sizeAfter, Constants.Q152).toInt256() + bX96)
                .toUint256()
                .toUint128();
        }
    }

    function calculateMarketPriceX96(
        Side _globalSide,
        Side _side,
        uint160 _indexPriceX96,
        uint160 _basisIndexPriceX96,
        uint128 _premiumRateX96
    ) internal pure returns (uint160 marketPriceX96) {
        (uint256 priceDeltaX96Down, uint256 priceDeltaX96Up) = Math.mulDiv2(
            _basisIndexPriceX96,
            _premiumRateX96,
            Constants.Q96
        );
        if (_globalSide.isLong()) {
            if (_side.isLong())
                marketPriceX96 = (_indexPriceX96 > priceDeltaX96Down ? _indexPriceX96 - priceDeltaX96Down : 0)
                    .toUint160();
            else marketPriceX96 = (_indexPriceX96 > priceDeltaX96Up ? _indexPriceX96 - priceDeltaX96Up : 0).toUint160();
        } else
            marketPriceX96 = (_side.isLong() ? _indexPriceX96 + priceDeltaX96Up : _indexPriceX96 + priceDeltaX96Down)
                .toUint160();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IChainLinkAggregator {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IChainLinkAggregator.sol";
import "../../core/interfaces/IMarketDescriptor.sol";

interface IPriceFeed {
    struct MarketConfig {
        /// @notice ChainLink contract address for corresponding market
        IChainLinkAggregator refPriceFeed;
        /// @notice Expected update interval of chain link price feed
        uint32 refHeartbeatDuration;
        /// @notice Maximum cumulative change ratio difference between prices and ChainLink price
        /// within a period of time.
        uint64 maxCumulativeDeltaDiff;
    }

    struct PriceDataItem {
        uint32 prevRound;
        uint160 prevRefPriceX96;
        uint64 cumulativeRefPriceDelta;
        uint160 prevPriceX96;
        uint64 cumulativePriceDelta;
    }

    struct PricePack {
        /// @notice The timestamp when updater uploads the price
        uint64 updateTimestamp;
        /// @notice Calculated maximum price, as a Q64.96
        uint160 maxPriceX96;
        /// @notice Calculated minimum price, as a Q64.96
        uint160 minPriceX96;
        /// @notice The block timestamp when price is committed
        uint64 updateBlockTimestamp;
    }

    struct MarketPrice {
        IMarketDescriptor market;
        uint160 priceX96;
    }

    /// @notice Emitted when market price updated
    /// @param market Market address
    /// @param priceX96 The price passed in by updater, as a Q64.96
    /// @param maxPriceX96 Calculated maximum price, as a Q64.96
    /// @param minPriceX96 Calculated minimum price, as a Q64.96
    event PriceUpdated(IMarketDescriptor indexed market, uint160 priceX96, uint160 minPriceX96, uint160 maxPriceX96);

    /// @notice Emitted when maxCumulativeDeltaDiff exceeded
    /// @param market Market address
    /// @param priceX96 The price passed in by updater, as a Q64.96
    /// @param refPriceX96 The price provided by ChainLink, as a Q64.96
    /// @param cumulativeDelta The cumulative value of the price change ratio
    /// @param cumulativeRefDelta The cumulative value of the ChainLink price change ratio
    event MaxCumulativeDeltaDiffExceeded(
        IMarketDescriptor indexed market,
        uint160 priceX96,
        uint160 refPriceX96,
        uint64 cumulativeDelta,
        uint64 cumulativeRefDelta
    );

    /// @notice Price not be initialized
    error NotInitialized();

    /// @notice Reference price feed not set
    error ReferencePriceFeedNotSet();

    /// @notice Invalid reference price
    /// @param referencePrice Reference price
    error InvalidReferencePrice(int256 referencePrice);

    /// @notice Reference price timeout
    /// @param elapsed The time elapsed since the last price update.
    error ReferencePriceTimeout(uint256 elapsed);

    /// @notice Stable market price timeout
    /// @param elapsed The time elapsed since the last price update.
    error StableMarketPriceTimeout(uint256 elapsed);

    /// @notice Invalid stable market price
    /// @param stableMarketPrice Stable market price
    error InvalidStableMarketPrice(int256 stableMarketPrice);

    /// @notice Invalid update timestamp
    /// @param timestamp Update timestamp
    error InvalidUpdateTimestamp(uint64 timestamp);
    /// @notice L2 sequencer is down
    error SequencerDown();
    /// @notice Grace period is not over
    /// @param sequencerUptime Sequencer uptime
    error GracePeriodNotOver(uint256 sequencerUptime);

    struct Slot {
        // Maximum deviation ratio between price and ChainLink price.
        uint32 maxDeviationRatio;
        // Period for calculating cumulative deviation ratio.
        uint32 cumulativeRoundDuration;
        // The number of additional rounds for ChainLink prices to participate in price update calculation.
        uint32 refPriceExtraSample;
        // The timeout for price update transactions.
        uint32 updateTxTimeout;
    }

    /// @notice Get the address of stable market price feed
    /// @return priceFeed The address of stable market price feed
    function stableMarketPriceFeed() external view returns (IChainLinkAggregator priceFeed);

    /// @notice Get the expected update interval of stable market price
    /// @return duration The expected update interval of stable market price
    function stableMarketPriceFeedHeartBeatDuration() external view returns (uint32 duration);

    /// @notice The 0th storage slot in the price feed stores many values, which helps reduce gas
    /// costs when interacting with the price feed.
    function slot() external view returns (Slot memory);

    /// @notice Get market configuration for updating price
    /// @param market The market address to query the configuration
    /// @return marketConfig The packed market config data
    function marketConfig(IMarketDescriptor market) external view returns (MarketConfig memory marketConfig);

    /// @notice `ReferencePriceFeedNotSet` will be ignored when `ignoreReferencePriceFeedError` is true
    function ignoreReferencePriceFeedError() external view returns (bool);

    /// @notice Get latest price data for corresponding market.
    /// @param market The market address to query the price data
    /// @return packedData The packed price data
    function latestPrice(IMarketDescriptor market) external view returns (PricePack memory packedData);

    /// @notice Update prices
    /// @dev Updater calls this method to update prices for multiple markets. The contract calculation requires
    /// higher precision prices, so the passed-in prices need to be adjusted.
    ///
    /// ## Example
    ///
    /// The price of ETH is $2000, and ETH has 18 decimals, so the price of one unit of ETH is $`2000 / (10 ^ 18)`.
    ///
    /// The price of USD is $1, and USD has 6 decimals, so the price of one unit of USD is $`1 / (10 ^ 6)`.
    ///
    /// Then the price of ETH/USD pair is 2000 / (10 ^ 18) * (10 ^ 6)
    ///
    /// Finally convert the price to Q64.96, ETH/USD priceX96 = 2000 / (10 ^ 18) * (10 ^ 6) * (2 ^ 96)
    /// @param marketPrices Array of market addresses and prices to update for
    /// @param timestamp The timestamp of price update
    function setPriceX96s(MarketPrice[] calldata marketPrices, uint64 timestamp) external;

    /// @notice calculate min and max price if passed a specific price value
    /// @param marketPrices Array of market addresses and prices to update for
    function calculatePriceX96s(
        MarketPrice[] calldata marketPrices
    ) external view returns (uint160[] memory minPriceX96s, uint160[] memory maxPriceX96s);

    /// @notice Get minimum market price
    /// @param market The market address to query the price
    /// @return priceX96 Minimum market price
    function getMinPriceX96(IMarketDescriptor market) external view returns (uint160 priceX96);

    /// @notice Get maximum market price
    /// @param market The market address to query the price
    /// @return priceX96 Maximum market price
    function getMaxPriceX96(IMarketDescriptor market) external view returns (uint160 priceX96);

    /// @notice Set updater status active or not
    /// @param account Updater address
    /// @param active Status of updater permission to set
    function setUpdater(address account, bool active) external;

    /// @notice Check if is updater
    /// @param account The address to query the status
    /// @return active Status of updater
    function isUpdater(address account) external returns (bool active);

    /// @notice Set ChainLink contract address for corresponding market.
    /// @param market The market address to set
    /// @param priceFeed ChainLink contract address
    function setRefPriceFeed(IMarketDescriptor market, IChainLinkAggregator priceFeed) external;

    /// @notice Set SequencerUptimeFeed contract address.
    /// @param sequencerUptimeFeed SequencerUptimeFeed contract address
    function setSequencerUptimeFeed(IChainLinkAggregator sequencerUptimeFeed) external;

    /// @notice Get SequencerUptimeFeed contract address.
    /// @return sequencerUptimeFeed SequencerUptimeFeed contract address
    function sequencerUptimeFeed() external returns (IChainLinkAggregator sequencerUptimeFeed);

    /// @notice Set the expected update interval for the ChainLink oracle price of the corresponding market.
    /// If ChainLink does not update the price within this period, it is considered that ChainLink has broken down.
    /// @param market The market address to set
    /// @param duration Expected update interval
    function setRefHeartbeatDuration(IMarketDescriptor market, uint32 duration) external;

    /// @notice Set maximum deviation ratio between price and ChainLink price.
    /// If exceeded, the updated price will refer to ChainLink price.
    /// @param maxDeviationRatio Maximum deviation ratio
    function setMaxDeviationRatio(uint32 maxDeviationRatio) external;

    /// @notice Set period for calculating cumulative deviation ratio.
    /// @param cumulativeRoundDuration Period in seconds to set.
    function setCumulativeRoundDuration(uint32 cumulativeRoundDuration) external;

    /// @notice Set the maximum acceptable cumulative change ratio difference between prices and ChainLink prices
    /// within a period of time. If exceeded, the updated price will refer to ChainLink price.
    /// @param market The market address to set
    /// @param maxCumulativeDeltaDiff Maximum cumulative change ratio difference
    function setMaxCumulativeDeltaDiffs(IMarketDescriptor market, uint64 maxCumulativeDeltaDiff) external;

    /// @notice Set number of additional rounds for ChainLink prices to participate in price update calculation.
    /// @param refPriceExtraSample The number of additional sampling rounds.
    function setRefPriceExtraSample(uint32 refPriceExtraSample) external;

    /// @notice Set the timeout for price update transactions.
    /// @param updateTxTimeout The timeout for price update transactions
    function setUpdateTxTimeout(uint32 updateTxTimeout) external;

    /// @notice Set ChainLink contract address and heart beat duration config for stable market.
    /// @param stableMarketPriceFeed The stable market address to set
    /// @param stableMarketPriceFeedHeartBeatDuration The expected update interval of stable market price
    function setStableMarketPriceFeed(
        IChainLinkAggregator stableMarketPriceFeed,
        uint32 stableMarketPriceFeedHeartBeatDuration
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

Side constant LONG = Side.wrap(1);
Side constant SHORT = Side.wrap(2);

type Side is uint8;

error InvalidSide(Side side);

using {requireValid, isLong, isShort, flip, eq as ==} for Side global;

function requireValid(Side self) pure {
    if (!isLong(self) && !isShort(self)) revert InvalidSide(self);
}

function isLong(Side self) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(LONG);
}

function isShort(Side self) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(SHORT);
}

function eq(Side self, Side other) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(other);
}

function flip(Side self) pure returns (Side) {
    return isLong(self) ? SHORT : LONG;
}