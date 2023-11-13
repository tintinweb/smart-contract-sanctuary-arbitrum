// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IAdminACLV0 {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     * @param previousSuperAdmin The previous superAdmin address.
     * @param newSuperAdmin The new superAdmin address.
     * @param genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     */
    event SuperAdminTransferred(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin,
        address[] genArt721CoreAddressesToUpdate
    );

    /// Type of the Admin ACL contract, e.g. "AdminACLV0"
    function AdminACLType() external view returns (string memory);

    /// super admin address
    function superAdmin() external view returns (address);

    /**
     * @notice Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external;

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function renounceOwnershipOn(address _contract) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.0;

import "./IEngineRegistryV0.sol";

interface ICoreRegistryV1 is IEngineRegistryV0 {
    function registerContracts(
        address[] calldata contractAddresses,
        bytes32[] calldata coreVersions,
        bytes32[] calldata coreTypes
    ) external;

    function unregisterContracts(address[] calldata contractAddresses) external;

    function getNumRegisteredContracts() external view returns (uint256);

    function getRegisteredContractAt(
        uint256 index
    ) external view returns (address);

    function isRegisteredContract(
        address contractAddress
    ) external view returns (bool isRegistered);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.0;

interface IEngineRegistryV0 {
    /// ADDRESS
    /**
     * @notice contract has been registered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractRegistered(
        address indexed _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    );

    /// ADDRESS
    /**
     * @notice contract has been unregistered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractUnregistered(address indexed _contractAddress);

    /**
     * @notice Emits a `ContractRegistered` event with the provided information.
     * @dev this function should be gated to only deployer addresses.
     */
    function registerContract(
        address _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    ) external;

    /**
     * @notice Emits a `ContractUnregistered` event with the provided information, validating that the provided
     *         address was indeed previously registered.
     * @dev this function should be gated to only deployer addresses.
     */
    function unregisterContract(address _contractAddress) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IFilteredMinterV0 {
    /**
     * @notice Price per token in wei updated for project `_projectId` to
     * `_pricePerTokenInWei`.
     */
    event PricePerTokenInWeiUpdated(
        uint256 indexed _projectId,
        uint256 indexed _pricePerTokenInWei
    );

    /**
     * @notice Currency updated for project `_projectId` to symbol
     * `_currencySymbol` and address `_currencyAddress`.
     */
    event ProjectCurrencyInfoUpdated(
        uint256 indexed _projectId,
        address indexed _currencyAddress,
        string _currencySymbol
    );

    /// togglePurchaseToDisabled updated
    event PurchaseToDisabledUpdated(
        uint256 indexed _projectId,
        bool _purchaseToDisabled
    );

    // getter function of public variable
    function minterType() external view returns (string memory);

    function genArt721CoreAddress() external returns (address);

    function minterFilterAddress() external returns (address);

    // Triggers a purchase of a token from the desired project, to the
    // TX-sending address.
    function purchase(
        uint256 _projectId
    ) external payable returns (uint256 tokenId);

    // Triggers a purchase of a token from the desired project, to the specified
    // receiving address.
    function purchaseTo(
        address _to,
        uint256 _projectId
    ) external payable returns (uint256 tokenId);

    // Toggles the ability for `purchaseTo` to be called directly with a
    // specified receiving address that differs from the TX-sending address.
    function togglePurchaseToDisabled(uint256 _projectId) external;

    // Called to make the minter contract aware of the max invocations for a
    // given project.
    function setProjectMaxInvocations(uint256 _projectId) external;

    // Gets if token price is configured, token price in wei, currency symbol,
    // and currency address, assuming this is project's minter.
    // Supersedes any defined core price.
    function getPriceInfo(
        uint256 _projectId
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for generic project minter configuration updates.
 * @dev keys represent strings of finite length encoded in bytes32 to minimize
 * gas.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterV1 is IFilteredMinterV0 {
    /// ANY
    /**
     * @notice Generic project minter configuration event. Removes key `_key`
     * for project `_projectId`.
     */
    event ConfigKeyRemoved(uint256 indexed _projectId, bytes32 _key);

    /// BOOL
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(uint256 indexed _projectId, bytes32 _key, bool _value);

    /// UINT256
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of uint256 at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of uint256 at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /// ADDRESS
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of addresses at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of addresses at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /// BYTES32
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of bytes32 at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of bytes32 at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @dev Strings not supported. Recommend conversion of (short) strings to
     * bytes32 to remain gas-efficient.
     */
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV1.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV1 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterV2 is IFilteredMinterV1 {
    /**
     * @notice Local max invocations for project `_projectId`, tied to core contract `_coreContractAddress`,
     * updated to `_maxInvocations`.
     */
    event ProjectMaxInvocationsLimitUpdated(
        uint256 indexed _projectId,
        uint256 _maxInvocations
    );

    // Sets the local max invocations for a given project, checking that the provided max invocations is
    // less than or equal to the global max invocations for the project set on the core contract.
    // This does not impact the max invocations value defined on the core contract.
    function manuallyLimitProjectMaxInvocations(
        uint256 _projectId,
        uint256 _maxInvocations
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
/// use the Royalty Registry's IManifold interface for token royalties
import "./IManifold.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 flagship and derivative implementations.
 * This interface extends the IManifold royalty interface in order to
 * add support the Royalty Registry by default.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Base is IManifold {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     */
    event Mint(address indexed _to, uint256 indexed _tokenId);

    /**
     * @notice currentMinter updated to `_currentMinter`.
     * @dev Implemented starting with V3 core
     */
    event MinterUpdated(address indexed _currentMinter);

    /**
     * @notice Platform updated on bytes32-encoded field `_field`.
     */
    event PlatformUpdated(bytes32 indexed _field);

    /**
     * @notice Project ID `_projectId` updated on bytes32-encoded field
     * `_update`.
     */
    event ProjectUpdated(uint256 indexed _projectId, bytes32 indexed _update);

    event ProposedArtistAddressesAndSplits(
        uint256 indexed _projectId,
        address _artistAddress,
        address _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    );

    event AcceptedArtistAddressesAndSplits(uint256 indexed _projectId);

    // version and type of the core contract
    // coreVersion is a string of the form "0.x.y"
    function coreVersion() external view returns (string memory);

    // coreType is a string of the form "GenArt721CoreV3"
    function coreType() external view returns (string memory);

    // owner (pre-V3 was named admin) of contract
    // this is expected to be an Admin ACL contract for V3
    function owner() external view returns (address);

    // Admin ACL contract for V3, will be at the address owner()
    function adminACLContract() external returns (IAdminACLV0);

    // backwards-compatible (pre-V3) admin - equal to owner()
    function admin() external view returns (address);

    /**
     * Function determining if _sender is allowed to call function with
     * selector _selector on contract `_contract`. Intended to be used with
     * peripheral contracts such as minters, as well as internally by the
     * core contract itself.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);

    /// getter function of public variable
    function startingProjectId() external view returns (uint256);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(
        uint256 tokenId
    ) external view returns (uint256 projectId);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySales(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySalesPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    function projectIdToSecondaryMarketRoyaltyPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    function projectURIInfo(
        uint256 _projectId
    ) external view returns (string memory projectBaseURI);

    // @dev new function in V3
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        );

    function projectDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory projectName,
            string memory artist,
            string memory description,
            string memory website,
            string memory license
        );

    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        );

    function projectScriptByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (string memory);

    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);

    // function to set a token's hash (must be guarded)
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hash) external;

    // @dev gas-optimized signature in V3 for `mint`
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";

interface IGenArt721CoreContractV3_Engine is IGenArt721CoreContractV3_Base {
    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 renderProviderRevenue_,
            address payable renderProviderAddress_,
            uint256 platformProviderRevenue_,
            address payable platformProviderAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev The render provider primary sales payment address
    function renderProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider primary sales payment address
    function platformProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Percentage of primary sales allocated to the render provider
    function renderProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev Percentage of primary sales allocated to the platform provider
    function platformProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev The render provider secondary sales royalties payment address
    function renderProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider secondary sales royalties payment address
    function platformProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Basis points of secondary sales allocated to the render provider
    function renderProviderSecondarySalesBPS() external view returns (uint256);

    // @dev Basis points of secondary sales allocated to the platform provider
    function platformProviderSecondarySalesBPS()
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";

/**
 * @title This interface extends IGenArt721CoreContractV3_Base with functions
 * that are part of the Art Blocks Flagship core contract.
 * @author Art Blocks Inc.
 */
// This interface extends IGenArt721CoreContractV3_Base with functions that are
// in part of the Art Blocks Flagship core contract.
interface IGenArt721CoreContractV3 is IGenArt721CoreContractV3_Base {
    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 artblocksRevenue_,
            address payable artblocksAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev Art Blocks primary sales payment address
    function artblocksPrimarySalesAddress()
        external
        view
        returns (address payable);

    /**
     * @notice Backwards-compatible (pre-V3) function returning Art Blocks
     * primary sales payment address (now called artblocksPrimarySalesAddress).
     */
    function artblocksAddress() external view returns (address payable);

    // @dev Percentage of primary sales allocated to Art Blocks
    function artblocksPrimarySalesPercentage() external view returns (uint256);

    /**
     * @notice Backwards-compatible (pre-V3) function returning Art Blocks
     * primary sales percentage (now called artblocksPrimarySalesPercentage).
     */
    function artblocksPercentage() external view returns (uint256);

    // @dev Art Blocks secondary sales royalties payment address
    function artblocksSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Basis points of secondary sales allocated to Art Blocks
    function artblocksSecondarySalesBPS() external view returns (uint256);

    /**
     * @notice Backwards-compatible (pre-V3) function  that gets artist +
     * artist's additional payee royalty data for token ID `_tokenId`.
     * WARNING: Does not include Art Blocks portion of royalties.
     */
    function getRoyaltyData(
        uint256 _tokenId
    )
        external
        view
        returns (
            address artistAddress,
            address additionalPayee,
            uint256 additionalPayeePercentage,
            uint256 royaltyFeeByID
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev Royalty Registry interface, used to support the Royalty Registry.
/// @dev Source: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/specs/IManifold.sol

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {
    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(
        uint256 tokenId
    ) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV2.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface defines any events or functions required for a minter
 * to conform to the MinterBase contract.
 * @dev The MinterBase contract was not implemented from the beginning of the
 * MinterSuite contract suite, therefore early versions of some minters may not
 * conform to this interface.
 * @author Art Blocks Inc.
 */
interface IMinterBaseV0 {
    // Function that returns if a minter is configured to integrate with a V3 flagship or V3 engine contract.
    // Returns true only if the minter is configured to integrate with an engine contract.
    function isEngine() external returns (bool isEngine);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./ICoreRegistryV1.sol";
import "./IAdminACLV0.sol";

/**
 * @title IMinterFilterV1
 * @author Art Blocks Inc.
 * @notice Interface for a new minter filter contract.
 * This interface does not extend the previous version of the minter filter
 * interface, as the previous version is not compatible with the new
 * minter filter architecture.
 * @dev This interface is for a minter filter that supports multiple core
 * contracts, and allows for a minter to be set on a per-project basis.
 */
interface IMinterFilterV1 {
    /**
     * @notice Emitted when contract is deployed to notify indexing services
     * of the new contract deployment.
     */
    event Deployed();

    /**
     * @notice Globally approved minter `minter`.
     */
    event MinterApprovedGlobally(address indexed minter, string minterType);

    /**
     * @notice Globally revoked minter `minter`.
     * @dev contract owner may still approve this minter on a per-contract
     * basis.
     */
    event MinterRevokedGlobally(address indexed minter);

    /**
     * @notice Approved minter `minter` on core contract
     * `coreContract`.
     */
    event MinterApprovedForContract(
        address indexed coreContract,
        address indexed minter,
        string minterType
    );

    /**
     * @notice Revoked minter `minter` on core contract `coreContract`.
     * @dev minter filter owner may still globally approve this minter for all
     * contracts.
     */
    event MinterRevokedForContract(
        address indexed coreContract,
        address indexed minter
    );

    /**
     * @notice Minter at address `minter` set as minter for project
     * `projectId` on core contract `coreContract`.
     */
    event ProjectMinterRegistered(
        uint256 indexed projectId,
        address indexed coreContract,
        address indexed minter,
        string minterType
    );

    /**
     * @notice Minter removed for project `projectId` on core contract
     * `coreContract`.
     */
    event ProjectMinterRemoved(
        uint256 indexed projectId,
        address indexed coreContract
    );

    /**
     * @notice Admin ACL contract updated to `adminACLContract`.
     */
    event AdminACLUpdated(address indexed adminACLContract);

    /**
     * @notice Core Registry contract updated to `coreRegistry`.
     */
    event CoreRegistryUpdated(address indexed coreRegistry);

    // struct used to return minter info
    // @dev this is not used for storage of data
    struct MinterWithType {
        address minterAddress;
        string minterType;
    }

    function setMinterForProject(
        uint256 projectId,
        address coreContract,
        address minter
    ) external;

    function removeMinterForProject(
        uint256 projectId,
        address coreContract
    ) external;

    // @dev function name is optimized for gas
    function mint_joo(
        address to,
        uint256 projectId,
        address coreContract,
        address sender
    ) external returns (uint256);

    function updateCoreRegistry(address coreRegistry) external;

    /**
     * @notice Returns if `sender` is allowed to call function on `contract`
     * with `selector` selector, according to the MinterFilter's Admin ACL.
     */
    function adminACLAllowed(
        address sender,
        address contract_,
        bytes4 selector
    ) external returns (bool);

    function minterFilterType() external pure returns (string memory);

    function getMinterForProject(
        uint256 projectId,
        address coreContract
    ) external view returns (address);

    function projectHasMinter(
        uint256 projectId,
        address coreContract
    ) external view returns (bool);

    /**
     * @notice View that returns if a core contract is registered with the
     * core registry, allowing this minter filter to service it.
     * @param coreContract core contract address to be checked
     */
    function isRegisteredCoreContract(
        address coreContract
    ) external view returns (bool);

    /// Address of current core registry contract
    function coreRegistry() external view returns (ICoreRegistryV1);

    /// The current admin ACL contract
    function adminACLContract() external view returns (IAdminACLV0);

    /// The quantity of projects on a core contract that have assigned minters
    function getNumProjectsOnContractWithMinters(
        address coreContract
    ) external view returns (uint256);

    function getProjectAndMinterInfoOnContractAt(
        address coreContract,
        uint256 index
    )
        external
        view
        returns (
            uint256 projectId,
            address minterAddress,
            string memory minterType
        );

    function getAllGloballyApprovedMinters()
        external
        view
        returns (MinterWithType[] memory mintersWithTypes);

    function getAllContractApprovedMinters(
        address coreContract
    ) external view returns (MinterWithType[] memory mintersWithTypes);

    /**
     * Owner of contract.
     * @dev This returns the address of the Admin ACL contract.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Shared Minter Simple Purchase Interface
 * @notice This interface is designed to be used by minter contracts that
 * implement a simple purchase model, such that the only args required to
 * purchase a token are the project id and the core contract address, and an
 * optional recipient address.
 */
interface ISharedMinterSimplePurchaseV0 {
    // Triggers a purchase of a token from the desired project, to the
    // TX-sending address.
    function purchase(
        uint256 projectId,
        address coreContract
    ) external payable returns (uint256 tokenId);

    // Triggers a purchase of a token from the desired project, to the specified
    // receiving address.
    function purchaseTo(
        address to,
        uint256 projectId,
        address coreContract
    ) external payable returns (uint256 tokenId);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface ISharedMinterV0 {
    // Sets the local max invocations for a given project, checking that the provided max invocations is
    // less than or equal to the global max invocations for the project set on the core contract.
    // This does not impact the max invocations value defined on the core contract.
    function manuallyLimitProjectMaxInvocations(
        uint256 projectId,
        address coreContract,
        uint24 maxInvocations
    ) external;

    // Called to make the minter contract aware of the max invocations for a
    // given project.
    function syncProjectMaxInvocationsToCore(
        uint256 projectId,
        address coreContract
    ) external;

    // getter function of public variable
    function minterType() external view returns (string memory);

    function minterFilterAddress() external returns (address);

    // Gets if token price is configured, token price in wei, currency symbol,
    // and currency address, assuming this is project's minter.
    // Supersedes any defined core price.
    function getPriceInfo(
        uint256 projectId,
        address coreContract
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Helpers Library
 * @notice This library contains helper functions for common operations in the
 * Art Blocks ecosystem of smart contracts.
 * @author Art Blocks Inc.
 */

library ABHelpers {
    uint256 constant ONE_MILLION = 1_000_000;

    /**
     * @notice Function to convert token id to project id.
     * @param tokenId The id of the token.
     */
    function tokenIdToProjectId(
        uint256 tokenId
    ) internal pure returns (uint256) {
        // int division properly rounds down
        // @dev unchecked because will never divide by zero
        unchecked {
            return tokenId / ONE_MILLION;
        }
    }

    /**
     * @notice Function to convert token id to token number.
     * @param tokenId The id of the token.
     */
    function tokenIdToTokenNumber(
        uint256 tokenId
    ) internal pure returns (uint256) {
        // mod returns remainder, which is the token number
        // @dev no way to disable mod zero check in solidity, so not unchecked
        return tokenId % ONE_MILLION;
    }

    /**
     * @notice Function to convert token id to token invocation.
     * @dev token invocation is the token number plus one, because token #0 is
     * invocation 1.
     * @param tokenId The id of the token.
     */
    function tokenIdToTokenInvocation(
        uint256 tokenId
    ) internal pure returns (uint256) {
        // mod returns remainder, which is the token number
        // @dev no way to disable mod zero check in solidity, so not unchecked
        return (tokenId % ONE_MILLION) + 1;
    }

    /**
     * @notice Function to convert project id and token number to token id.
     * @param projectId The id of the project.
     * @param tokenNumber The token number.
     */
    function tokenIdFromProjectIdAndTokenNumber(
        uint256 projectId,
        uint256 tokenNumber
    ) internal pure returns (uint256) {
        // @dev intentionally not unchecked to ensure overflow detection, which
        // would likley only occur in a malicious call
        return (projectId * ONE_MILLION) + tokenNumber;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import {IGenArt721CoreContractV3_Base} from "../../interfaces/v0.8.x/IGenArt721CoreContractV3_Base.sol";
import {IMinterFilterV1} from "../../interfaces/v0.8.x/IMinterFilterV1.sol";

/**
 * @title Art Blocks Authorization Minter Library
 * @notice This library contains helper functions that may be used contracts to
 * check authorization for performing operations in the Art Blocks V3 core
 * contract ecosystem.
 * @author Art Blocks Inc.
 */

library AuthLib {
    /**
     * @notice Function to restrict access to only AdminACL allowed calls, where
     * AdminACL is the admin of an IMinterFilterV1.
     * Reverts if not allowed.
     * @param minterFilterAddress address of the minter filter to be checked,
     * should implement IMinterFilterV1
     * @param sender address of the caller
     * @param contract_ address of the contract being called
     * @param selector selector of the function being called
     */
    function onlyMinterFilterAdminACL(
        address minterFilterAddress,
        address sender,
        address contract_,
        bytes4 selector
    ) internal {
        require(
            _minterFilterAdminACLAllowed({
                minterFilterAddress: minterFilterAddress,
                sender: sender,
                contract_: contract_,
                selector: selector
            }),
            "Only MinterFilter AdminACL"
        );
    }

    /**
     * @notice Function to restrict access to only AdminACL allowed calls, where
     * AdminACL is the admin of a core contract at `coreContract`.
     * Reverts if not allowed.
     * @param coreContract address of the core contract to be checked
     * @param sender address of the caller
     * @param contract_ address of the contract being called
     * @param selector selector of the function being called
     */
    function onlyCoreAdminACL(
        address coreContract,
        address sender,
        address contract_,
        bytes4 selector
    ) internal {
        require(
            _coreAdminACLAllowed({
                coreContract: coreContract,
                sender: sender,
                contract_: contract_,
                selector: selector
            }),
            "Only Core AdminACL allowed"
        );
    }

    /**
     * @notice Throws if `sender` is any account other than the artist of the
     * specified project `projectId` on core contract `coreContract`.
     * @param projectId The ID of the project being checked.
     * @param coreContract The address of the GenArt721CoreContractV3_Base
     * contract.
     * @param sender Wallet to check. Typically, the address of the caller.
     * @dev `sender` must be the artist associated with `projectId` on `coreContract`.
     */
    function onlyArtist(
        uint256 projectId,
        address coreContract,
        address sender
    ) internal view {
        require(
            _senderIsArtist({
                projectId: projectId,
                coreContract: coreContract,
                sender: sender
            }),
            "Only Artist"
        );
    }

    /**
     * @notice Function to restrict access to only the artist of a project, or AdminACL
     * allowed calls, where AdminACL is the admin of a core contract at
     * `coreContract`.
     * @param projectId id of the project
     * @param coreContract address of the core contract to be checked
     * @param sender address of the caller
     * @param contract_ address of the contract being called
     * @param selector selector of the function being called
     */
    function onlyCoreAdminACLOrArtist(
        uint256 projectId,
        address coreContract,
        address sender,
        address contract_,
        bytes4 selector
    ) internal {
        require(
            _senderIsArtist({
                projectId: projectId,
                coreContract: coreContract,
                sender: sender
            }) ||
                _coreAdminACLAllowed({
                    coreContract: coreContract,
                    sender: sender,
                    contract_: contract_,
                    selector: selector
                }),
            "Only Artist or Core Admin ACL"
        );
    }

    // ------------------------------------------------------------------------
    // Private functions used internally by this library
    // ------------------------------------------------------------------------

    /**
     * @notice Private function that returns if minter filter contract's AdminACL
     * allows `sender` to call function with selector `selector` on contract
     * `contract`.
     * @param minterFilterAddress address of the minter filter to be checked.
     * Should implement IMinterFilterV1.
     * @param sender address of the caller
     * @param contract_ address of the contract being called
     * @param selector selector of the function being called
     */
    function _minterFilterAdminACLAllowed(
        address minterFilterAddress,
        address sender,
        address contract_,
        bytes4 selector
    ) private returns (bool) {
        return
            IMinterFilterV1(minterFilterAddress).adminACLAllowed({
                sender: sender,
                contract_: contract_,
                selector: selector
            });
    }

    /**
     * @notice Private function that returns if core contract's AdminACL allows
     * `sender` to call function with selector `selector` on contract
     * `contract`.
     * @param coreContract address of the core contract to be checked
     * @param sender address of the caller
     * @param contract_ address of the contract being called
     * @param selector selector of the function being called
     */
    function _coreAdminACLAllowed(
        address coreContract,
        address sender,
        address contract_,
        bytes4 selector
    ) private returns (bool) {
        return
            IGenArt721CoreContractV3_Base(coreContract).adminACLAllowed({
                _sender: sender,
                _contract: contract_,
                _selector: selector
            });
    }

    /**
     * @notice Private function that returns if `sender` is the artist of `projectId`
     * on `coreContract`.
     * @param projectId project ID to check
     * @param coreContract core contract to check
     * @param sender wallet to check
     */
    function _senderIsArtist(
        uint256 projectId,
        address coreContract,
        address sender
    ) private view returns (bool senderIsArtist) {
        return
            sender ==
            IGenArt721CoreContractV3_Base(coreContract)
                .projectIdToArtistAddress(projectId);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import {IGenArt721CoreContractV3_Base} from "../../../interfaces/v0.8.x/IGenArt721CoreContractV3_Base.sol";

import {ABHelpers} from "../ABHelpers.sol";

import {Math} from "@openzeppelin-4.7/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin-4.7/contracts/utils/math/SafeCast.sol";

/**
 * @title Art Blocks Max Invocations Library
 * @notice This library manages the maximum invocation limits for Art Blocks
 * projects. It provides functionality for synchronizing, manually limiting, and
 * updating these limits, ensuring the integrity in relation to the core Art
 * Blocks contract, and managing updates upon token minting.
 * @dev Functions include `syncProjectMaxInvocationsToCore`,
 * `manuallyLimitProjectMaxInvocations`, and `purchaseEffectsInvocations`.
 * @author Art Blocks Inc.
 */

library MaxInvocationsLib {
    using SafeCast for uint256;

    /**
     * @notice Local max invocations for project `projectId`, tied to core contract `coreContractAddress`,
     * updated to `maxInvocations`.
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     * @param maxInvocations The new max invocations limit.
     */
    event ProjectMaxInvocationsLimitUpdated(
        uint256 indexed projectId,
        address indexed coreContract,
        uint256 maxInvocations
    );

    // position of Max Invocations Lib storage, using a diamond storage pattern
    // for this library
    bytes32 constant MAX_INVOCATIONS_LIB_STORAGE_POSITION =
        keccak256("maxinvocationslib.storage");

    uint256 internal constant ONE_MILLION = 1_000_000;

    /**
     * @notice Data structure that holds max invocations project configuration.
     */
    struct MaxInvocationsProjectConfig {
        bool maxHasBeenInvoked;
        uint24 maxInvocations;
    }

    // Diamond storage pattern is used in this library
    struct MaxInvocationsLibStorage {
        mapping(address coreContract => mapping(uint256 projectId => MaxInvocationsProjectConfig)) maxInvocationsProjectConfigs;
    }

    /**
     * @notice Syncs project's max invocations to core contract value.
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     */
    function syncProjectMaxInvocationsToCore(
        uint256 projectId,
        address coreContract
    ) internal {
        (
            uint256 coreInvocations,
            uint256 coreMaxInvocations
        ) = coreContractInvocationData({
                projectId: projectId,
                coreContract: coreContract
            });
        // update storage with results
        MaxInvocationsProjectConfig
            storage maxInvocationsProjectConfig = getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        // @dev only bugged core would return > 1e6 invocations, but safe-cast
        // for additional overflow safety
        maxInvocationsProjectConfig.maxInvocations = coreMaxInvocations
            .toUint24();

        // We need to ensure maxHasBeenInvoked is correctly set after manually syncing the
        // local maxInvocations value with the core contract's maxInvocations value.
        maxInvocationsProjectConfig.maxHasBeenInvoked =
            coreInvocations == coreMaxInvocations;

        emit ProjectMaxInvocationsLimitUpdated({
            projectId: projectId,
            coreContract: coreContract,
            maxInvocations: coreMaxInvocations
        });
    }

    /**
     * @notice Manually limits project's max invocations.
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     * @param maxInvocations The new max invocations limit.
     */
    function manuallyLimitProjectMaxInvocations(
        uint256 projectId,
        address coreContract,
        uint24 maxInvocations
    ) internal {
        // CHECKS
        (
            uint256 coreInvocations,
            uint256 coreMaxInvocations
        ) = coreContractInvocationData({
                projectId: projectId,
                coreContract: coreContract
            });
        require(
            maxInvocations <= coreMaxInvocations,
            "Invalid max invocations"
        );
        require(maxInvocations >= coreInvocations, "Invalid max invocations");

        // EFFECTS
        MaxInvocationsProjectConfig
            storage maxInvocationsProjectConfig = getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        // update storage with results
        maxInvocationsProjectConfig.maxInvocations = uint24(maxInvocations);
        // We need to ensure maxHasBeenInvoked is correctly set after manually setting the
        // local maxInvocations value.
        maxInvocationsProjectConfig.maxHasBeenInvoked =
            coreInvocations == maxInvocations;

        emit ProjectMaxInvocationsLimitUpdated({
            projectId: projectId,
            coreContract: coreContract,
            maxInvocations: maxInvocations
        });
    }

    /**
     * @notice Validate effects on invocations after purchase. This ensures
     * that the token invocation is less than or equal to the local max
     * invocations, and also updates the local maxHasBeenInvoked value.
     * @dev This function checks that the token invocation is less than or
     * equal to the local max invocations, and also updates the local
     * maxHasBeenInvoked value.
     * @param tokenId The id of the token.
     * @param coreContract The address of the core contract.
     */
    function validateMintEffectsInvocations(
        uint256 tokenId,
        address coreContract
    ) internal {
        uint256 projectId = ABHelpers.tokenIdToProjectId(tokenId);
        MaxInvocationsProjectConfig
            storage maxInvocationsProjectConfig = getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        // invocation is token number plus one, and will never overflow due to
        // limit of 1e6 invocations per project. block scope for gas efficiency
        // (i.e. avoid an unnecessary var initialization to 0).
        unchecked {
            uint256 tokenInvocation = ABHelpers.tokenIdToTokenInvocation(
                tokenId
            );
            uint256 localMaxInvocations = maxInvocationsProjectConfig
                .maxInvocations;
            // handle the case where the token invocation == minter local max
            // invocations occurred on a different minter, and we have a stale
            // local maxHasBeenInvoked value returning a false negative.
            // @dev this is a CHECK after EFFECTS, so security was considered
            // in detail here.
            require(
                tokenInvocation <= localMaxInvocations,
                "Max invocations reached"
            );
            // in typical case, update the local maxHasBeenInvoked value
            // to true if the token invocation == minter local max invocations
            // (enables gas efficient reverts after sellout)
            if (tokenInvocation == localMaxInvocations) {
                maxInvocationsProjectConfig.maxHasBeenInvoked = true;
            }
        }
    }

    /**
     * @notice Checks that the max invocations have not been reached for a
     * given project. This only checks the minter's local max invocations, and
     * does not consider the core contract's max invocations.
     * The function reverts if the max invocations have been reached.
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     */
    function preMintChecks(
        uint256 projectId,
        address coreContract
    ) internal view {
        // check that max invocations have not been reached
        MaxInvocationsProjectConfig
            storage maxInvocationsProjectConfig = getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        require(
            !maxInvocationsProjectConfig.maxHasBeenInvoked,
            "Max invocations reached"
        );
    }

    /**
     * @notice Helper function to check if max invocations has not been initialized.
     * Returns true if not initialized, false if initialized.
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     * @return bool
     * @dev We know a project's max invocations have never been initialized if
     * both max invocations and maxHasBeenInvoked are still initial values.
     * This is because if maxInvocations were ever set to zero,
     * maxHasBeenInvoked would be set to true.
     */
    function maxInvocationsIsUnconfigured(
        uint256 projectId,
        address coreContract
    ) internal view returns (bool) {
        MaxInvocationsProjectConfig
            storage maxInvocationsProjectConfig = getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        return
            maxInvocationsProjectConfig.maxInvocations == 0 &&
            !maxInvocationsProjectConfig.maxHasBeenInvoked;
    }

    /**
     * @notice Function returns if invocations remain available for a given project.
     * This function calls the core contract to get the most up-to-date
     * invocation data (which may be useful to avoid reverts during mint).
     * This function considers core contract max invocations, and minter local
     * max invocations, and returns a response based on the most limiting
     * max invocations value.
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     */
    function invocationsRemain(
        uint256 projectId,
        address coreContract
    ) internal view returns (bool) {
        // get up-to-data invocation data from core contract
        (
            uint256 coreInvocations,
            uint256 coreMaxInvocations
        ) = coreContractInvocationData({
                projectId: projectId,
                coreContract: coreContract
            });
        // load minter-local max invocations into memory
        MaxInvocationsProjectConfig
            storage maxInvocationsProjectConfig = getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        // invocations remain available if the core contract has not reached
        // the most limiting max invocations, either on minter or core contract
        uint256 limitingMaxInvocations = Math.min(
            coreMaxInvocations,
            maxInvocationsProjectConfig.maxInvocations // local max invocations
        );
        return coreInvocations < limitingMaxInvocations;
    }

    /**
     * @notice Pulls core contract invocation data for a given project.
     * @dev This function calls the core contract to get the invocation data
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     * @return coreInvocations The number of invocations for the project.
     * @return coreMaxInvocations The max invocations for the project, as
     * defined on the core contract.
     */
    function coreContractInvocationData(
        uint256 projectId,
        address coreContract
    )
        internal
        view
        returns (uint256 coreInvocations, uint256 coreMaxInvocations)
    {
        (
            coreInvocations,
            coreMaxInvocations,
            ,
            ,
            ,

        ) = IGenArt721CoreContractV3_Base(coreContract).projectStateData(
            projectId
        );
    }

    /**
     * @notice Function returns the max invocations for a given project.
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     * to be queried.
     */
    function getMaxInvocations(
        uint256 projectId,
        address coreContract
    ) internal view returns (uint256) {
        MaxInvocationsProjectConfig
            storage maxInvocationsProjectConfig = getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        return maxInvocationsProjectConfig.maxInvocations;
    }

    /**
     * @notice Function returns if max has been invoked for a given project.
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     * to be queried.
     */
    function getMaxHasBeenInvoked(
        uint256 projectId,
        address coreContract
    ) internal view returns (bool) {
        MaxInvocationsProjectConfig
            storage maxInvocationsProjectConfig = getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        return maxInvocationsProjectConfig.maxHasBeenInvoked;
    }

    /**
     * @notice Function returns if a project has reached its max invocations.
     * Function is labelled as "safe" because it checks the core contract's
     * invocations and max invocations. If the local max invocations is greater
     * than the core contract's max invocations, it will defer to the core
     * contract's max invocations (since those are the limiting factor).
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     */
    function projectMaxHasBeenInvokedSafe(
        uint256 projectId,
        address coreContract
    ) internal view returns (bool) {
        // get max invocations from core contract
        (
            uint256 coreInvocations,
            uint256 coreMaxInvocations
        ) = coreContractInvocationData({
                projectId: projectId,
                coreContract: coreContract
            });

        MaxInvocationsProjectConfig
            storage maxInvocationsProjectConfig = getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        uint256 localMaxInvocations = maxInvocationsProjectConfig
            .maxInvocations;
        // value is locally defined, and could be out of date.
        // only possible illogical state is if local max invocations is
        // greater than core contract's max invocations, in which case
        // we should use the core contract's max invocations
        if (localMaxInvocations > coreMaxInvocations) {
            // local max invocations is stale and illogical, defer to core
            // contract's max invocations since it is the limiting factor
            return (coreMaxInvocations == coreInvocations);
        }
        // local max invocations is limiting, so check core invocations against
        // local max invocations
        return (coreInvocations >= localMaxInvocations);
    }

    /**
     * @notice Refreshes max invocations to account for core contract max
     * invocations state, without imposing any additional restrictions on the
     * minter's max invocations state.
     * If minter max invocations have never been populated, this function will
     * populate them to equal the core contract's max invocations state (which
     * is the least restrictive state).
     * If minter max invocations have been populated, this function will ensure
     * the minter's max invocations are not greater than the core contract's
     * max invocations (which would be stale and illogical), and update the
     * minter's max invocations and maxHasBeenInvoked state to be consistent
     * with the core contract's max invocations.
     * If the minter max invocations have been populated and are not greater
     * than the core contract's max invocations, this function will do nothing,
     * since that is a valid state in which the minter has been configured to
     * be more restrictive than the core contract.
     * @dev assumes core contract's max invocations may only be reduced, which
     * is the case for all V3 core contracts
     * @param projectId The id of the project.
     * @param coreContract The address of the core contract.
     */
    function refreshMaxInvocations(
        uint256 projectId,
        address coreContract
    ) internal {
        MaxInvocationsProjectConfig
            storage maxInvocationsProjectConfig = getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        if (maxInvocationsIsUnconfigured(projectId, coreContract)) {
            // populate the minter max invocation state to equal the values on
            // the core contract (least restrictive state)
            syncProjectMaxInvocationsToCore({
                projectId: projectId,
                coreContract: coreContract
            });
        } else {
            // if local max invocations were already populated, validate the local state
            (
                uint256 coreInvocations,
                uint256 coreMaxInvocations
            ) = coreContractInvocationData({
                    projectId: projectId,
                    coreContract: coreContract
                });

            uint256 localMaxInvocations = maxInvocationsProjectConfig
                .maxInvocations;
            if (localMaxInvocations > coreMaxInvocations) {
                // if local max invocations are greater than core max invocations, make
                // them equal since that is the least restrictive logical state
                // @dev this is only possible if the core contract's max invocations
                // have been reduced since the minter's max invocations were last
                // updated
                // set local max invocations to core contract's max invocations
                maxInvocationsProjectConfig.maxInvocations = uint24(
                    coreMaxInvocations
                );
                // update the minter's `maxHasBeenInvoked` state
                maxInvocationsProjectConfig
                    .maxHasBeenInvoked = (coreMaxInvocations ==
                    coreInvocations);
                emit ProjectMaxInvocationsLimitUpdated({
                    projectId: projectId,
                    coreContract: coreContract,
                    maxInvocations: coreMaxInvocations
                });
            } else if (coreInvocations >= localMaxInvocations) {
                // core invocations are greater than this minter's max
                // invocations, indicating that minting must have occurred on
                // another minter. update the minter's `maxHasBeenInvoked` to
                // true to prevent any false negatives on
                // `getMaxHasBeenInvoked'
                maxInvocationsProjectConfig.maxHasBeenInvoked = true;
                // @dev do not emit event, because we did not change the value
                // of minter-local max invocations
            }
        }
    }

    /**
     * @notice Loads the MaxInvocationsProjectConfig for a given project and core
     * contract.
     * @param projectId Project Id to get config for
     * @param coreContract Core contract address to get config for
     */
    function getMaxInvocationsProjectConfig(
        uint256 projectId,
        address coreContract
    ) internal view returns (MaxInvocationsProjectConfig storage) {
        return s().maxInvocationsProjectConfigs[coreContract][projectId];
    }

    /**
     * @notice Return the storage struct for reading and writing. This library
     * uses a diamond storage pattern when managing storage.
     * @return storageStruct The MaxInvocationsLibStorage struct.
     */
    function s()
        internal
        pure
        returns (MaxInvocationsLibStorage storage storageStruct)
    {
        bytes32 position = MAX_INVOCATIONS_LIB_STORAGE_POSITION;
        assembly ("memory-safe") {
            storageStruct.slot := position
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Set Price Minter Library
 * @notice This library is designed for the Art Blocks platform. It provides a
 * struct and functions that falicitate the configuring of projects that use a
 * fixed-price minting model.
 * @author Art Blocks Inc.
 */

library SetPriceLib {
    /**
     * @notice Price per token updated for project `projectId` to
     * `pricePerToken`.
     * @param projectId Project Id price was updated for
     * @param coreContract Core contract address price was updated for
     * @param pricePerToken price per token, no decimals (e.g. in wei for ETH)
     */
    event PricePerTokenUpdated(
        uint256 indexed projectId,
        address indexed coreContract,
        uint256 indexed pricePerToken
    );

    /**
     * @notice Price per token reset (unconfigured) for project `projectId`.
     * @param projectId Project Id price was reset for
     * @param coreContract Core contract address price was reset for
     */
    event PricePerTokenReset(
        uint256 indexed projectId,
        address indexed coreContract
    );

    // position of Set Price Lib storage, using a diamond storage pattern
    // for this library
    bytes32 constant SET_PRICE_LIB_STORAGE_POSITION =
        keccak256("setpricelib.storage");

    // project-level variables
    /**
     * Struct used to store a project's currently configured price, and
     * whether or not the price has been configured.
     */
    struct SetPriceProjectConfig {
        // @dev The price is stored with no accounting for decimals. e.g. in
        // wei for ETH.
        uint248 pricePerToken; // 0 if not configured
        bool priceIsConfigured;
    }

    // Diamond storage pattern is used in this library
    struct SetPriceLibStorage {
        mapping(address coreContract => mapping(uint256 projectId => SetPriceProjectConfig)) setPriceProjectConfigs;
    }

    /**
     * @notice Updates the minter's price per token to be `pricePerToken`.
     * @dev Note that it is intentionally supported here that the configured
     * price may be explicitly set to `0`.
     * @param projectId Project Id to update price for
     * @param coreContract Core contract address to update price for
     * @param pricePerToken price per token, no decimals (e.g. in wei for ETH)
     */
    function updatePricePerToken(
        uint256 projectId,
        address coreContract,
        uint256 pricePerToken
    ) internal {
        SetPriceProjectConfig
            storage setPriceProjectConfig = getSetPriceProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        // update storage with new values
        setPriceProjectConfig.pricePerToken = uint248(pricePerToken);
        setPriceProjectConfig.priceIsConfigured = true;

        emit PricePerTokenUpdated({
            projectId: projectId,
            coreContract: coreContract,
            pricePerToken: pricePerToken
        });
    }

    /**
     * @notice Resets the minter's price per token to be unconfigured.
     * @param projectId Project Id to reset price for
     * @param coreContract Core contract address to reset the price for
     */
    function resetPricePerToken(
        uint256 projectId,
        address coreContract
    ) internal {
        // @dev all fields must be deleted, and none of them are a complex type
        // @dev getSetPriceProjectConfig not used, as deletion of storage
        // pointers is not supported
        delete s().setPriceProjectConfigs[coreContract][projectId];

        emit PricePerTokenReset({
            projectId: projectId,
            coreContract: coreContract
        });
    }

    /**
     * @notice Checks that the minter's price per token is configured, and
     * returns the price per token.
     * Reverts if the price is not configured.
     * @param projectId Project Id to check and get price for
     * @param coreContract Core contract address to check and get price for
     * @return pricePerToken price per token, no decimals (e.g. in wei for ETH)
     */
    function preMintChecksAndGetPrice(
        uint256 projectId,
        address coreContract
    ) internal view returns (uint256 pricePerToken) {
        SetPriceProjectConfig
            storage setPriceProjectConfig = getSetPriceProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });

        // require artist to have configured price of token on this minter
        require(
            setPriceProjectConfig.priceIsConfigured,
            "Price not configured"
        );
        return setPriceProjectConfig.pricePerToken;
    }

    /**
     * @notice Loads the SetPriceProjectConfig for a given project and core contract.
     * @param projectId Project Id to get config for
     * @param coreContract Core contract address to get config for
     */
    function getSetPriceProjectConfig(
        uint256 projectId,
        address coreContract
    ) internal view returns (SetPriceProjectConfig storage) {
        return s().setPriceProjectConfigs[coreContract][projectId];
    }

    /**
     * @notice Return the storage struct for reading and writing. This library
     * uses a diamond storage pattern when managing storage.
     * @return storageStruct The SetPriceLibStorage struct.
     */
    function s()
        internal
        pure
        returns (SetPriceLibStorage storage storageStruct)
    {
        bytes32 position = SET_PRICE_LIB_STORAGE_POSITION;
        assembly ("memory-safe") {
            storageStruct.slot := position
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import {IMinterBaseV0} from "../../../interfaces/v0.8.x/IMinterBaseV0.sol";
import {IGenArt721CoreContractV3_Base} from "../../../interfaces/v0.8.x/IGenArt721CoreContractV3_Base.sol";
import {IGenArt721CoreContractV3} from "../../../interfaces/v0.8.x/IGenArt721CoreContractV3.sol";
import {IGenArt721CoreContractV3_Engine} from "../../../interfaces/v0.8.x/IGenArt721CoreContractV3_Engine.sol";

import {IERC20} from "@openzeppelin-4.7/contracts/token/ERC20/IERC20.sol";

/**
 * @title Art Blocks Split Funds Library
 * @notice This library is designed for the Art Blocks platform. It splits
 * Ether (ETH) and ERC20 token funds among stakeholders, such as sender
 * (if refund is applicable), providers, artists, and artists' additional
 * payees.
 * @author Art Blocks Inc.
 */

library SplitFundsLib {
    /**
     * @notice Currency updated for project `projectId` to symbol
     * `currencySymbol` and address `currencyAddress`.
     * @param projectId Project ID currency was updated for
     * @param coreContract Core contract address currency was updated for
     * @param currencyAddress Currency address
     * @param currencySymbol Currency symbol
     */
    event ProjectCurrencyInfoUpdated(
        uint256 indexed projectId,
        address indexed coreContract,
        address indexed currencyAddress,
        string currencySymbol
    );

    // position of Split Funds Lib storage, using a diamond storage pattern
    // for this library
    bytes32 constant SPLIT_FUNDS_LIB_STORAGE_POSITION =
        keccak256("splitfundslib.storage");

    // contract-level variables
    struct IsEngineCache {
        bool isEngine;
        bool isCached;
    }

    // project-level variables
    struct SplitFundsProjectConfig {
        address currencyAddress; // address(0) if ETH
        string currencySymbol; // Assumed to be ETH if null
    }

    // Diamond storage pattern is used in this library
    struct SplitFundsLibStorage {
        mapping(address coreContract => mapping(uint256 projectId => SplitFundsProjectConfig)) splitFundsProjectConfigs;
        mapping(address coreContract => IsEngineCache) isEngineCacheConfigs;
    }

    /**
     * @notice splits ETH funds between sender (if refund), providers,
     * artist, and artist's additional payee for a token purchased on
     * project `projectId`.
     * WARNING: This function uses msg.value and msg.sender to determine
     * refund amounts, and therefore may not be applicable to all use cases
     * (e.g. do not use with Dutch Auctions with on-chain settlement).
     * @dev This function relies on msg.sender and msg.value, so it must be
     * called directly from the contract that is receiving the payment.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     * @param projectId Project ID for which funds shall be split.
     * @param pricePerTokenInWei Current price of token, in Wei.
     * @param coreContract Address of the GenArt721CoreContract associated
     * with the project.
     */
    function splitFundsETHRefundSender(
        uint256 projectId,
        uint256 pricePerTokenInWei,
        address coreContract
    ) internal {
        if (msg.value > 0) {
            // send refund to sender
            uint256 refund = msg.value - pricePerTokenInWei;
            if (refund > 0) {
                (bool success_, ) = msg.sender.call{value: refund}("");
                require(success_, "Refund failed");
            }
            // split revenues
            splitRevenuesETHNoRefund({
                projectId: projectId,
                valueInWei: pricePerTokenInWei,
                coreContract: coreContract
            });
        }
    }

    /**
     * @notice Splits ETH revenues between providers, artist, and artist's
     * additional payee for revenue generated by project `projectId`.
     * This function does NOT refund msg.sender, and does NOT use msg.value
     * when determining the value to be split.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     * @param projectId Project ID for which funds shall be split.
     * @param valueInWei Value to be split, in Wei.
     * @param coreContract Address of the GenArt721CoreContract
     * associated with the project.
     */
    function splitRevenuesETHNoRefund(
        uint256 projectId,
        uint256 valueInWei,
        address coreContract
    ) internal {
        if (valueInWei == 0) {
            return; // return early
        }
        // split funds between platforms, artist, and artist's
        // additional payee
        bool isEngine_ = isEngine(coreContract);
        uint256 renderProviderRevenue;
        address payable renderProviderAddress;
        uint256 platformProviderRevenue;
        address payable platformProviderAddress;
        uint256 artistRevenue;
        address payable artistAddress;
        uint256 additionalPayeePrimaryRevenue;
        address payable additionalPayeePrimaryAddress;
        if (isEngine_) {
            // get engine splits
            (
                renderProviderRevenue,
                renderProviderAddress,
                platformProviderRevenue,
                platformProviderAddress,
                artistRevenue,
                artistAddress,
                additionalPayeePrimaryRevenue,
                additionalPayeePrimaryAddress
            ) = IGenArt721CoreContractV3_Engine(coreContract)
                .getPrimaryRevenueSplits({
                    _projectId: projectId,
                    _price: valueInWei
                });
        } else {
            // get flagship splits
            // @dev note that platformProviderAddress and
            // platformProviderRevenue remain 0 for flagship
            (
                renderProviderRevenue, // artblocks revenue
                renderProviderAddress, // artblocks address
                artistRevenue,
                artistAddress,
                additionalPayeePrimaryRevenue,
                additionalPayeePrimaryAddress
            ) = IGenArt721CoreContractV3(coreContract).getPrimaryRevenueSplits({
                _projectId: projectId,
                _price: valueInWei
            });
        }
        // require total revenue split is 100%
        // @dev note that platformProviderRevenue remains 0 for flagship
        require(
            renderProviderRevenue +
                platformProviderRevenue +
                artistRevenue +
                additionalPayeePrimaryRevenue ==
                valueInWei,
            "Invalid revenue split totals"
        );
        // distribute revenues
        // @dev note that platformProviderAddress and platformProviderRevenue
        // remain 0 for flagship
        _sendPaymentsETH({
            platformProviderRevenue: platformProviderRevenue,
            platformProviderAddress: platformProviderAddress,
            renderProviderRevenue: renderProviderRevenue,
            renderProviderAddress: renderProviderAddress,
            artistRevenue: artistRevenue,
            artistAddress: artistAddress,
            additionalPayeePrimaryRevenue: additionalPayeePrimaryRevenue,
            additionalPayeePrimaryAddress: additionalPayeePrimaryAddress
        });
    }

    /**
     * @notice Splits ERC20 funds between providers, artist, and artist's
     * additional payee, for a token purchased on project `projectId`.
     * The function performs checks to ensure that the ERC20 token is
     * approved for transfer, and that a non-zero ERC20 token address is
     * configured.
     * @dev This function relies on msg.sender, so it must be
     * called directly from the contract that is receiving the payment.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     * @param projectId Project ID for which funds shall be split.
     * @param pricePerToken Current price of token, in base units. For example,
     * if the ERC20 token has 6 decimals, an input value of `1_000_000` would
     * represent a price of `1.000000` tokens.
     * @param coreContract Core contract address.
     */
    function splitFundsERC20(
        uint256 projectId,
        uint256 pricePerToken,
        address coreContract
    ) internal {
        if (pricePerToken == 0) {
            return; // nothing to split, return early
        }
        IERC20 projectCurrency;
        // block scope to avoid stack too deep error
        {
            SplitFundsProjectConfig
                storage splitFundsProjectConfig = getSplitFundsProjectConfig({
                    projectId: projectId,
                    coreContract: coreContract
                });
            address currencyAddress = splitFundsProjectConfig.currencyAddress;
            require(
                currencyAddress != address(0),
                "ERC20: payment not configured"
            );
            // ERC20 token is used for payment
            validateERC20Approvals({
                msgSender: msg.sender,
                currencyAddress: currencyAddress,
                pricePerToken: pricePerToken
            });
            projectCurrency = IERC20(currencyAddress);
        }
        // split remaining funds between foundation, artist, and artist's
        bool isEngine_ = isEngine(coreContract);
        uint256 renderProviderRevenue;
        address payable renderProviderAddress;
        uint256 platformProviderRevenue;
        address payable platformProviderAddress;
        uint256 artistRevenue;
        address payable artistAddress;
        uint256 additionalPayeePrimaryRevenue;
        address payable additionalPayeePrimaryAddress;
        if (isEngine_) {
            // get engine splits
            (
                renderProviderRevenue,
                renderProviderAddress,
                platformProviderRevenue,
                platformProviderAddress,
                artistRevenue,
                artistAddress,
                additionalPayeePrimaryRevenue,
                additionalPayeePrimaryAddress
            ) = IGenArt721CoreContractV3_Engine(coreContract)
                .getPrimaryRevenueSplits({
                    _projectId: projectId,
                    _price: pricePerToken
                });
        } else {
            // get flagship splits
            // @dev note that platformProviderAddress and
            // platformProviderRevenue remain 0 for flagship
            (
                renderProviderRevenue, // artblocks revenue
                renderProviderAddress, // artblocks address
                artistRevenue,
                artistAddress,
                additionalPayeePrimaryRevenue,
                additionalPayeePrimaryAddress
            ) = IGenArt721CoreContractV3(coreContract).getPrimaryRevenueSplits({
                _projectId: projectId,
                _price: pricePerToken
            });
        }
        // require total revenue split is 100%
        // @dev note that platformProviderRevenue remains 0 for flagship
        require(
            renderProviderRevenue +
                platformProviderRevenue +
                artistRevenue +
                additionalPayeePrimaryRevenue ==
                pricePerToken,
            "Invalid revenue split totals"
        );
        // distribute revenues
        // @dev note that platformProviderAddress and platformProviderRevenue
        // remain 0 for flagship
        _sendPaymentsERC20({
            projectCurrency: projectCurrency,
            platformProviderRevenue: platformProviderRevenue,
            platformProviderAddress: platformProviderAddress,
            renderProviderRevenue: renderProviderRevenue,
            renderProviderAddress: renderProviderAddress,
            artistRevenue: artistRevenue,
            artistAddress: artistAddress,
            additionalPayeePrimaryRevenue: additionalPayeePrimaryRevenue,
            additionalPayeePrimaryAddress: additionalPayeePrimaryAddress
        });
    }

    /**
     * @notice Updates payment currency of the referenced
     * SplitFundsProjectConfig to be `currencySymbol` at address
     * `currencyAddress`.
     * Only supports setting currency info of ERC20 tokens.
     * Returns bool that is true if the price should be reset after this
     * update. Price is recommended to be reset if the currency address was
     * previously configured, but is now being updated to a different currency
     * address. This is to protect accidental price reductions when changing
     * currency if an artist is changing currencies in an unpaused state.
     * @dev artist-defined currency symbol is used instead of any on-chain
     * currency symbol.
     * @param projectId Project ID to update.
     * @param coreContract Core contract address.
     * @param currencySymbol Currency symbol.
     * @param currencyAddress Currency address.
     * @return recommendPriceReset True if the price should be reset after this
     * update.
     */
    function updateProjectCurrencyInfoERC20(
        uint256 projectId,
        address coreContract,
        string memory currencySymbol,
        address currencyAddress
    ) internal returns (bool recommendPriceReset) {
        // CHECKS
        require(currencyAddress != address(0), "null address, only ERC20");
        require(bytes(currencySymbol).length > 0, "only non-null symbol");
        // EFFECTS
        SplitFundsProjectConfig
            storage splitFundsProjectConfig = getSplitFundsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        // recommend price reset if currency address was previously configured
        recommendPriceReset = (splitFundsProjectConfig.currencyAddress !=
            address(0));
        splitFundsProjectConfig.currencySymbol = currencySymbol;
        splitFundsProjectConfig.currencyAddress = currencyAddress;

        emit ProjectCurrencyInfoUpdated({
            projectId: projectId,
            coreContract: coreContract,
            currencyAddress: currencyAddress,
            currencySymbol: currencySymbol
        });
    }

    /**
     * @notice Force sends `amount` (in wei) ETH to `to`, with a gas stipend
     * equal to `minterRefundGasLimit`.
     * If sending via the normal procedure fails, force sends the ETH by
     * creating a temporary contract which uses `SELFDESTRUCT` to force send
     * the ETH.
     * Reverts if the current contract has insufficient balance.
     * @param to The address to send ETH to.
     * @param amount The amount of ETH to send.
     * @param minterRefundGasLimit The gas limit to use when sending ETH, prior
     * to fallback.
     * @dev This function is adapted from the `forceSafeTransferETH` function
     * in the `https://github.com/Vectorized/solady` repository, with
     * modifications to not check if the current contract has sufficient
     * balance. Therefore, the contract should be checked for sufficient
     * balance before calling this function in the minter itself, if
     * applicable.
     */
    function forceSafeTransferETH(
        address to,
        uint256 amount,
        uint256 minterRefundGasLimit
    ) internal {
        // Manually inlined because the compiler doesn't inline functions with
        // branches.
        /// @solidity memory-safe-assembly
        assembly {
            // @dev intentionally do not check if this contract has sufficient
            // balance, because that is not intended to be a valid state.

            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(minterRefundGasLimit, to, amount, 0, 0, 0, 0)) {
                // if the transfer failed, we create a temporary contract with
                // initialization code that uses `SELFDESTRUCT` to force send
                // the ETH.
                // note: Compatible with `SENDALL`:
                // https://eips.ethereum.org/EIPS/eip-4758

                //---------------------------------------------------------------------------------------------------------------//
                // Opcode  | Opcode + Arguments  | Description        | Stack View                                               //
                //---------------------------------------------------------------------------------------------------------------//
                // Contract creation code that uses `SELFDESTRUCT` to force send ETH to a specified address.                     //
                // Creation code summary: 0x73<20-byte toAddress>0xff                                                            //
                //---------------------------------------------------------------------------------------------------------------//
                // 0x73    |  0x73_toAddress     | PUSH20 toAddress   | toAddress                                                //
                // 0xFF    |  0xFF               | SELFDESTRUCT       |                                                          //
                //---------------------------------------------------------------------------------------------------------------//
                // Store the address in scratch space, starting at 0x00, which begins the 20-byte address at 32-20=12 in memory
                // @dev use scratch space because we have enough space for simple creation code (less than 0x40 bytes)
                mstore(0x00, to)
                // store opcode PUSH20 immediately before the address, starting at 0x0b (11) in memory
                mstore8(0x0b, 0x73)
                // store opcode SELFDESTRUCT immediately after the address, starting at 0x20 (32) in memory
                mstore8(0x20, 0xff)
                // this will always succeed because the contract creation code is
                // valid, and the address is valid because it is a 20-byte value
                if iszero(create(amount, 0x0b, 0x16)) {
                    // @dev For better gas estimation.
                    if iszero(gt(gas(), 1000000)) {
                        revert(0, 0)
                    }
                }
            }
        }
    }

    /**
     * @notice Returns whether or not the provided address `coreContract`
     * is an Art Blocks Engine core contract. Caches the result for future access.
     * @param coreContract Address of the core contract to check.
     */
    function isEngine(address coreContract) internal returns (bool) {
        IsEngineCache storage isEngineCache = getIsEngineCacheConfig(
            coreContract
        );
        // check cache, return early if cached
        if (isEngineCache.isCached) {
            return isEngineCache.isEngine;
        }
        // populate cache and return result
        bool isEngine_ = getV3CoreIsEngineView(coreContract);
        isEngineCache.isCached = true;
        isEngineCache.isEngine = isEngine_;
        return isEngine_;
    }

    /**
     * @notice Returns whether a V3 core contract is an Art Blocks Engine
     * contract or not. Return value of false indicates that the core is a
     * flagship contract. This function does not update the cache state for the
     * given V3 core contract.
     * @dev this function reverts if a core contract does not return the
     * expected number of return values from getPrimaryRevenueSplits() for
     * either a flagship or engine core contract.
     * @dev this function uses the length of the return data (in bytes) to
     * determine whether the core is an engine or not.
     * @param coreContract The address of the deployed core contract.
     */
    function getV3CoreIsEngineView(
        address coreContract
    ) internal view returns (bool) {
        // call getPrimaryRevenueSplits() on core contract
        bytes memory payload = abi.encodeWithSignature(
            "getPrimaryRevenueSplits(uint256,uint256)",
            0,
            0
        );
        (bool success, bytes memory returnData) = coreContract.staticcall(
            payload
        );
        require(success, "getPrimaryRevenueSplits() call failed");
        // determine whether core is engine or not, based on return data length
        uint256 returnDataLength = returnData.length;
        if (returnDataLength == 6 * 32) {
            // 6 32-byte words returned if flagship (not engine)
            // @dev 6 32-byte words are expected because the non-engine core
            // contracts return a payout address and uint256 payment value for
            // the artist, and artist's additional payee, and Art Blocks.
            // also note that per Solidity ABI encoding, the address return
            // values are padded to 32 bytes.

            return false;
        } else if (returnDataLength == 8 * 32) {
            // 8 32-byte words returned if engine
            // @dev 8 32-byte words are expected because the engine core
            // contracts return a payout address and uint256 payment value for
            // the artist, artist's additional payee, render provider
            // typically Art Blocks, and platform provider (partner).
            // also note that per Solidity ABI encoding, the address return
            // values are padded to 32 bytes.
            return true;
        }
        // unexpected return value length
        revert("Unexpected revenue split bytes");
    }

    /**
     * @notice Gets the currency address and symbol for the referenced
     * SplitFundsProjectConfig.
     * Only supports ERC20 tokens - returns currencySymbol of `UNCONFIG` if
     * `currencyAddress` is zero.
     * @param projectId Project ID to get config for
     * @param coreContract Core contract address to get config for
     * @return currencyAddress
     * @return currencySymbol
     */
    function getCurrencyInfoERC20(
        uint256 projectId,
        address coreContract
    )
        internal
        view
        returns (address currencyAddress, string memory currencySymbol)
    {
        SplitFundsProjectConfig
            storage splitFundsProjectConfig = getSplitFundsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
        currencyAddress = splitFundsProjectConfig.currencyAddress;
        // default to "UNCONFIG" if project currency address is initial value
        currencySymbol = currencyAddress == address(0)
            ? "UNCONFIG"
            : splitFundsProjectConfig.currencySymbol;
    }

    /**
     * @notice Gets the balance of `currencyAddress` ERC20 tokens for `walletAddress`.
     * @param currencyAddress ERC20 token address.
     * @param walletAddress wallet address.
     * @return balance
     */
    function getERC20Balance(
        address currencyAddress,
        address walletAddress
    ) internal view returns (uint256) {
        return IERC20(currencyAddress).balanceOf(walletAddress);
    }

    /**
     * @notice Gets the allowance of `spenderAddress` to spend `walletAddress`'s
     * `currencyAddress` ERC20 tokens.
     * @param currencyAddress ERC20 token address.
     * @param walletAddress wallet address.
     * @param spenderAddress spender address.
     * @return allowance
     */
    function getERC20Allowance(
        address currencyAddress,
        address walletAddress,
        address spenderAddress
    ) internal view returns (uint256 allowance) {
        allowance = IERC20(currencyAddress).allowance({
            owner: walletAddress,
            spender: spenderAddress
        });
        return allowance;
    }

    /**
     * @notice Function validates that `msgSender` has approved the contract to spend at least
     * `pricePerToken` of `currencyAddress` ERC20 tokens, and that
     * `msgSender` has a balance of at least `pricePerToken` of
     * `currencyAddress` ERC20 tokens.
     * Reverts if insufficient allowance or balance.
     * @param msgSender Address of the message sender to validate.
     * @param currencyAddress Address of the ERC20 token to validate.
     * @param pricePerToken Price of token, in base units. For example,
     * if the ERC20 token has 6 decimals, an input value of `1_000_000` would
     * represent a price of `1.000000` tokens.
     */
    function validateERC20Approvals(
        address msgSender,
        address currencyAddress,
        uint256 pricePerToken
    ) private view {
        require(
            IERC20(currencyAddress).allowance({
                owner: msgSender,
                spender: address(this)
            }) >= pricePerToken,
            "Insufficient ERC20 allowance"
        );
        require(
            IERC20(currencyAddress).balanceOf(msgSender) >= pricePerToken,
            "Insufficient ERC20 balance"
        );
    }

    /**
     * @notice Sends ETH revenues between providers, artist, and artist's
     * additional payee. Reverts if any payment fails.
     * @dev This function pays priviliged addresses. DoS is acknowledged, and
     * mitigated by business practices, including end-to-end testing on
     * mainnet, and admin-accepted artist payment addresses.
     * @param platformProviderRevenue Platform Provider revenue.
     * @param platformProviderAddress Platform Provider address.
     * @param renderProviderRevenue Render Provider revenue.
     * @param renderProviderAddress Render Provider address.
     * @param artistRevenue Artist revenue.
     * @param artistAddress Artist address.
     * @param additionalPayeePrimaryRevenue Additional Payee revenue.
     * @param additionalPayeePrimaryAddress Additional Payee address.
     */
    function _sendPaymentsETH(
        uint256 platformProviderRevenue,
        address payable platformProviderAddress,
        uint256 renderProviderRevenue,
        address payable renderProviderAddress,
        uint256 artistRevenue,
        address payable artistAddress,
        uint256 additionalPayeePrimaryRevenue,
        address payable additionalPayeePrimaryAddress
    ) private {
        // Platform Provider payment (only possible if engine)
        if (platformProviderRevenue > 0) {
            (bool success, ) = platformProviderAddress.call{
                value: platformProviderRevenue
            }("");
            require(success, "Platform Provider payment failed");
        }
        // Render Provider / Art Blocks payment
        if (renderProviderRevenue > 0) {
            (bool success, ) = renderProviderAddress.call{
                value: renderProviderRevenue
            }("");
            require(success, "Render Provider payment failed");
        }
        // artist payment
        if (artistRevenue > 0) {
            (bool success, ) = artistAddress.call{value: artistRevenue}("");
            require(success, "Artist payment failed");
        }
        // additional payee payment
        if (additionalPayeePrimaryRevenue > 0) {
            (bool success, ) = additionalPayeePrimaryAddress.call{
                value: additionalPayeePrimaryRevenue
            }("");
            require(success, "Additional Payee payment failed");
        }
    }

    /**
     * @notice Sends ERC20 revenues between providers, artist, and artist's
     * additional payee. Reverts if any payment fails. All revenue values
     * should use base units. For example, if the ERC20 token has 6 decimals,
     * an input value of `1_000_000` would represent an amount of `1.000000`
     * tokens.
     * @dev This function relies on msg.sender, so it must be called from
     * the contract that is receiving the payment.
     * @param projectCurrency IERC20 payment token.
     * @param platformProviderRevenue Platform Provider revenue.
     * @param platformProviderAddress Platform Provider address.
     * @param renderProviderRevenue Render Provider revenue.
     * @param renderProviderAddress Render Provider address.
     * @param artistRevenue Artist revenue.
     * @param artistAddress Artist address.
     * @param additionalPayeePrimaryRevenue Additional Payee revenue.
     * @param additionalPayeePrimaryAddress Additional Payee address.
     */
    function _sendPaymentsERC20(
        IERC20 projectCurrency,
        uint256 platformProviderRevenue,
        address payable platformProviderAddress,
        uint256 renderProviderRevenue,
        address payable renderProviderAddress,
        uint256 artistRevenue,
        address payable artistAddress,
        uint256 additionalPayeePrimaryRevenue,
        address payable additionalPayeePrimaryAddress
    ) private {
        // Platform Provider payment (only possible if engine)
        if (platformProviderRevenue > 0) {
            require(
                projectCurrency.transferFrom({
                    from: msg.sender,
                    to: platformProviderAddress,
                    amount: platformProviderRevenue
                }),
                "Platform Provider payment failed"
            );
        }
        // Art Blocks payment
        if (renderProviderRevenue > 0) {
            require(
                projectCurrency.transferFrom({
                    from: msg.sender,
                    to: renderProviderAddress,
                    amount: renderProviderRevenue
                }),
                "Render Provider payment failed"
            );
        }
        // artist payment
        if (artistRevenue > 0) {
            require(
                projectCurrency.transferFrom({
                    from: msg.sender,
                    to: artistAddress,
                    amount: artistRevenue
                }),
                "Artist payment failed"
            );
        }
        // additional payee payment
        if (additionalPayeePrimaryRevenue > 0) {
            // @dev some ERC20 may not revert on transfer failure, so we
            // check the return value
            require(
                projectCurrency.transferFrom({
                    from: msg.sender,
                    to: additionalPayeePrimaryAddress,
                    amount: additionalPayeePrimaryRevenue
                }),
                "Additional Payee payment failed"
            );
        }
    }

    /**
     * @notice Loads the SplitFundsProjectConfig for a given project and core
     * contract.
     * @param projectId Project Id to get config for
     * @param coreContract Core contract address to get config for
     */
    function getSplitFundsProjectConfig(
        uint256 projectId,
        address coreContract
    ) internal view returns (SplitFundsProjectConfig storage) {
        return s().splitFundsProjectConfigs[coreContract][projectId];
    }

    /**
     * @notice Loads the IsEngineCache for a given core contract.
     * @param coreContract Core contract address to get config for
     */
    function getIsEngineCacheConfig(
        address coreContract
    ) internal view returns (IsEngineCache storage) {
        return s().isEngineCacheConfigs[coreContract];
    }

    /**
     * @notice Return the storage struct for reading and writing. This library
     * uses a diamond storage pattern when managing storage.
     * @return storageStruct The SetPriceLibStorage struct.
     */
    function s()
        internal
        pure
        returns (SplitFundsLibStorage storage storageStruct)
    {
        bytes32 position = SPLIT_FUNDS_LIB_STORAGE_POSITION;
        assembly ("memory-safe") {
            storageStruct.slot := position
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

// @dev fixed to specific solidity version for clarity and for more clear
// source code verification purposes.
pragma solidity 0.8.19;

import {ISharedMinterSimplePurchaseV0} from "../../interfaces/v0.8.x/ISharedMinterSimplePurchaseV0.sol";
import {ISharedMinterV0} from "../../interfaces/v0.8.x/ISharedMinterV0.sol";
import {IMinterFilterV1} from "../../interfaces/v0.8.x/IMinterFilterV1.sol";

import {AuthLib} from "../../libs/v0.8.x/AuthLib.sol";
import {SplitFundsLib} from "../../libs/v0.8.x/minter-libs/SplitFundsLib.sol";
import {MaxInvocationsLib} from "../../libs/v0.8.x/minter-libs/MaxInvocationsLib.sol";
import {SetPriceLib} from "../../libs/v0.8.x/minter-libs/SetPriceLib.sol";

import {ReentrancyGuard} from "@openzeppelin-4.5/contracts/security/ReentrancyGuard.sol";

/**
 * @title Shared, filtered Minter contract that allows tokens to be minted with
 * ETH.
 * This is designed to be used with GenArt721CoreContractV3 flagship or
 * engine contracts.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with limited powers.
 * Privileged roles and abilities are controlled by the project's artist, which
 * can be modified by the core contract's Admin ACL contract. Both of these
 * roles hold extensive power and can modify minter details.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to a project's artist:
 * - updatePricePerTokenInWei
 * - syncProjectMaxInvocationsToCore
 * - manuallyLimitProjectMaxInvocations
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on other
 * contracts that this minter integrates with.
 * ----------------------------------------------------------------------------
 * @notice Caution: While Engine projects must be registered on the Art Blocks
 * Core Registry to assign this minter, this minter does not enforce that a
 * project is registered when configured or queried. This is primarily for gas
 * optimization purposes. It is, therefore, possible that fake projects may be
 * configured on this minter, but they will not be able to mint tokens due to
 * checks performed by this minter's Minter Filter.
 */
contract MinterSetPriceV5 is
    ReentrancyGuard,
    ISharedMinterSimplePurchaseV0,
    ISharedMinterV0
{
    /// Minter filter address this minter interacts with
    address public immutable minterFilterAddress;

    /// Minter filter this minter may interact with.
    IMinterFilterV1 private immutable _minterFilter;

    /// minterType for this minter
    string public constant minterType = "MinterSetPriceV5";

    /// minter version for this minter
    string public constant minterVersion = "v5.0.0";

    // MODIFIERS
    // @dev contract uses modifier-like internal functions instead of modifiers
    // to reduce contract bytecode size
    // @dev contract uses AuthLib for some modifier-like functions

    /**
     * @notice Initializes contract to be a Filtered Minter for
     * `minterFilter` minter filter.
     * @param minterFilter Minter filter for which this will be a
     * filtered minter.
     */
    constructor(address minterFilter) ReentrancyGuard() {
        minterFilterAddress = minterFilter;
        _minterFilter = IMinterFilterV1(minterFilter);
    }

    /**
     * @notice Manually sets the local maximum invocations of project `projectId`
     * with the provided `maxInvocations`, checking that `maxInvocations` is less
     * than or equal to the value of project `project_id`'s maximum invocations that is
     * set on the core contract.
     * @dev Note that a `maxInvocations` of 0 can only be set if the current `invocations`
     * value is also 0 and this would also set `maxHasBeenInvoked` to true, correctly short-circuiting
     * this minter's purchase function, avoiding extra gas costs from the core contract's maxInvocations check.
     * @param projectId Project ID to set the maximum invocations for.
     * @param coreContract Core contract address for the given project.
     * @param maxInvocations Maximum invocations to set for the project.
     */
    function manuallyLimitProjectMaxInvocations(
        uint256 projectId,
        address coreContract,
        uint24 maxInvocations
    ) external {
        AuthLib.onlyArtist({
            projectId: projectId,
            coreContract: coreContract,
            sender: msg.sender
        });
        MaxInvocationsLib.manuallyLimitProjectMaxInvocations({
            projectId: projectId,
            coreContract: coreContract,
            maxInvocations: maxInvocations
        });
    }

    /**
     * @notice Updates this minter's price per token of project `projectId`
     * to be '_pricePerTokenInWei`, in Wei.
     * @dev Note that it is intentionally supported here that the configured
     * price may be explicitly set to `0`.
     * @param projectId Project ID to set the price per token for.
     * @param coreContract Core contract address for the given project.
     * @param pricePerTokenInWei Price per token to set for the project, in Wei.
     */
    function updatePricePerTokenInWei(
        uint256 projectId,
        address coreContract,
        uint248 pricePerTokenInWei
    ) external {
        AuthLib.onlyArtist({
            projectId: projectId,
            coreContract: coreContract,
            sender: msg.sender
        });
        SetPriceLib.updatePricePerToken({
            projectId: projectId,
            coreContract: coreContract,
            pricePerToken: pricePerTokenInWei
        });

        // for convenience, sync local max invocations to the core contract if
        // and only if max invocations have not already been synced.
        // @dev do not sync if max invocations have already been synced, as
        // local max invocations could have been manually set to be
        // intentionally less than the core contract's max invocations.
        // @dev if local maxInvocations and maxHasBeenInvoked are both
        // initial values, we know they have not been populated on this minter
        if (
            MaxInvocationsLib.maxInvocationsIsUnconfigured({
                projectId: projectId,
                coreContract: coreContract
            })
        ) {
            MaxInvocationsLib.syncProjectMaxInvocationsToCore({
                projectId: projectId,
                coreContract: coreContract
            });
        }
    }

    /**
     * @notice Purchases a token from project `projectId`.
     * @param projectId Project ID to mint a token on.
     * @param coreContract Core contract address for the given project.
     * @return tokenId Token ID of minted token
     */
    function purchase(
        uint256 projectId,
        address coreContract
    ) external payable returns (uint256 tokenId) {
        tokenId = purchaseTo({
            to: msg.sender,
            projectId: projectId,
            coreContract: coreContract
        });
        return tokenId;
    }

    // public getter functions
    /**
     * @notice Gets the maximum invocations project configuration.
     * @param projectId The ID of the project whose data needs to be fetched.
     * @param coreContract The address of the core contract.
     * @return MaxInvocationsLib.MaxInvocationsProjectConfig instance with the
     * configuration data.
     */
    function maxInvocationsProjectConfig(
        uint256 projectId,
        address coreContract
    )
        external
        view
        returns (MaxInvocationsLib.MaxInvocationsProjectConfig memory)
    {
        return
            MaxInvocationsLib.getMaxInvocationsProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
    }

    /**
     * @notice Gets the set price project configuration.
     * @param projectId The ID of the project whose data needs to be fetched.
     * @param coreContract The address of the core contract.
     * @return SetPriceProjectConfig struct with the fixed price project
     * configuration data.
     */
    function setPriceProjectConfig(
        uint256 projectId,
        address coreContract
    ) external view returns (SetPriceLib.SetPriceProjectConfig memory) {
        return
            SetPriceLib.getSetPriceProjectConfig({
                projectId: projectId,
                coreContract: coreContract
            });
    }

    /**
     * @notice Checks if the specified `coreContract` is a valid engine contract.
     * @dev This function retrieves the cached value of `isEngine` from
     * the `isEngineCache` mapping. If the cached value is already set, it
     * returns the cached value. Otherwise, it calls the `getV3CoreIsEngineView`
     * function from the `SplitFundsLib` library to check if `coreContract`
     * is a valid engine contract.
     * @dev This function will revert if the provided `coreContract` is not
     * a valid Engine or V3 Flagship contract.
     * @param coreContract The address of the contract to check.
     * @return bool indicating if `coreContract` is a valid engine contract.
     */
    function isEngineView(address coreContract) external view returns (bool) {
        SplitFundsLib.IsEngineCache storage isEngineCache = SplitFundsLib
            .getIsEngineCacheConfig(coreContract);
        if (isEngineCache.isCached) {
            return isEngineCache.isEngine;
        } else {
            // @dev this calls the non-state-modifying variant of isEngine
            return SplitFundsLib.getV3CoreIsEngineView(coreContract);
        }
    }

    /**
     * @notice projectId => has project reached its maximum number of
     * invocations? Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional, as it only enables gas optimization of mints after a
     * project's maximum invocations has been reached. A false negative will
     * only result in a gas cost increase, since the core contract will still
     * enforce a maxInvocation check during minting. A false positive is not
     * possible because the V3 core contract only allows maximum invocations
     * to be reduced, not increased. Based on this rationale, we intentionally
     * do not do input validation in this method as to whether or not the input
     * @param projectId is an existing project ID.
     * @param coreContract is an existing core contract address.
     */
    function projectMaxHasBeenInvoked(
        uint256 projectId,
        address coreContract
    ) external view returns (bool) {
        return
            MaxInvocationsLib.getMaxHasBeenInvoked({
                projectId: projectId,
                coreContract: coreContract
            });
    }

    /**
     * @notice projectId => project's maximum number of invocations.
     * Optionally synced with core contract value, for gas optimization.
     * Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional, as it only enables gas optimization of mints after a
     * project's maximum invocations has been reached.
     * @dev A number greater than the core contract's project max invocations
     * will only result in a gas cost increase, since the core contract will
     * still enforce a maxInvocation check during minting. A number less than
     * the core contract's project max invocations is only possible when the
     * project's max invocations have not been synced on this minter, since the
     * V3 core contract only allows maximum invocations to be reduced, not
     * increased. When this happens, the minter will enable minting, allowing
     * the core contract to enforce the max invocations check. Based on this
     * rationale, we intentionally do not do input validation in this method as
     * to whether or not the input `projectId` is an existing project ID.
     * @param projectId is an existing project ID.
     * @param coreContract is an existing core contract address.
     */
    function projectMaxInvocations(
        uint256 projectId,
        address coreContract
    ) external view returns (uint256) {
        return
            MaxInvocationsLib.getMaxInvocations({
                projectId: projectId,
                coreContract: coreContract
            });
    }

    /**
     * @notice Gets if price of token is configured, price of minting a
     * token on project `projectId`, and currency symbol and address to be
     * used as payment.
     * @param projectId Project ID to get price information for
     * @param coreContract Contract address of the core contract
     * @return isConfigured true only if token price has been configured on
     * this minter
     * @return tokenPriceInWei current price of token on this minter - invalid
     * if price has not yet been configured
     * @return currencySymbol currency symbol for purchases of project on this
     * minter. This minter always returns "ETH"
     * @return currencyAddress currency address for purchases of project on
     * this minter. This minter always returns null address, reserved for ether
     */
    function getPriceInfo(
        uint256 projectId,
        address coreContract
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        )
    {
        SetPriceLib.SetPriceProjectConfig
            storage setPriceProjectConfig_ = SetPriceLib
                .getSetPriceProjectConfig({
                    projectId: projectId,
                    coreContract: coreContract
                });
        isConfigured = setPriceProjectConfig_.priceIsConfigured;
        tokenPriceInWei = setPriceProjectConfig_.pricePerToken;
        currencySymbol = "ETH";
        currencyAddress = address(0);
    }

    /**
     * @notice Syncs local maximum invocations of project `projectId` based on
     * the value currently defined in the core contract.
     * @param projectId Project ID to set the maximum invocations for.
     * @param coreContract Core contract address for the given project.
     * @dev this enables gas reduction after maxInvocations have been reached -
     * core contracts shall still enforce a maxInvocation check during mint.
     */
    function syncProjectMaxInvocationsToCore(
        uint256 projectId,
        address coreContract
    ) public {
        AuthLib.onlyArtist({
            projectId: projectId,
            coreContract: coreContract,
            sender: msg.sender
        });

        MaxInvocationsLib.syncProjectMaxInvocationsToCore({
            projectId: projectId,
            coreContract: coreContract
        });
    }

    /**
     * @notice Purchases a token from project `projectId` and sets
     * the token's owner to `to`.
     * @param to Address to be the new token's owner.
     * @param projectId Project ID to mint a token on.
     * @param coreContract Core contract address for the given project.
     * @return tokenId Token ID of minted token
     */
    function purchaseTo(
        address to,
        uint256 projectId,
        address coreContract
    ) public payable nonReentrant returns (uint256 tokenId) {
        // CHECKS
        // pre-mint MaxInvocationsLib checks
        // Note that `maxHasBeenInvoked` is only checked here to reduce gas
        // consumption after a project has been fully minted.
        // `maxInvocationsProjectConfig.maxHasBeenInvoked` is locally cached to reduce
        // gas consumption, but if not in sync with the core contract's value,
        // the core contract also enforces its own max invocation check during
        // minting.
        MaxInvocationsLib.preMintChecks({
            projectId: projectId,
            coreContract: coreContract
        });

        // pre-mint checks for set price lib, and get price per token in wei
        // @dev price per token is loaded into memory here for gas efficiency
        uint256 pricePerTokenInWei = SetPriceLib.preMintChecksAndGetPrice({
            projectId: projectId,
            coreContract: coreContract
        });

        require(msg.value >= pricePerTokenInWei, "Min value to mint req.");

        // EFFECTS
        tokenId = _minterFilter.mint_joo({
            to: to,
            projectId: projectId,
            coreContract: coreContract,
            sender: msg.sender
        });

        MaxInvocationsLib.validateMintEffectsInvocations({
            tokenId: tokenId,
            coreContract: coreContract
        });

        // INTERACTIONS
        SplitFundsLib.splitFundsETHRefundSender({
            projectId: projectId,
            pricePerTokenInWei: pricePerTokenInWei,
            coreContract: coreContract
        });

        return tokenId;
    }
}