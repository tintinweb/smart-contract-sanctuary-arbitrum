// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Constants {
    address public constant ZERO_ADDRESS = address(0);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    uint256 public constant DEFAULT_MAX_OPEN_INTEREST = 10000000000 * PRICE_PRECISION;
    uint256 public constant DEFAULT_VLP_PRICE = 100000;
    uint256 public constant FUNDING_RATE_PRECISION = 1e6;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    uint256 public constant LIQUIDATION_FEE_DIVISOR = 1e18;
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;

    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;

    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%
    uint256 public constant PRICE_PRECISION = 1e12;
    uint256 public constant LP_DECIMALS = 18;
    uint256 public constant LP_INITIAL_PRICE = 1e12; // init set to 1$
    uint256 public constant USD_VALUE_PRECISION = 1e18;

    uint256 public constant TOKEN_PRECISION = 1e18;
    uint256 public constant FEE_PRECISION = 1e6;

    uint8 public constant ORACLE_PRICE_DECIMALS = 18;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library Errors {
    string constant ZERO_AMOUNT = "0 amount";
    string constant ZERO_ADDRESS = "0x address";
    string constant UNAUTHORIZED = "UNAUTHORIZED";

    string constant MARKET_NOT_LISTED = "TradingEngine:Market not listed";
    string constant INVALID_COLLATERAL_TOKEN = "TradingEngine:Invalid collateral token";
    string constant INVALID_POSITION_SIZE = "TradingEngine:Invalid size";
    string constant EXCEED_LIQUIDITY = "TradingEngine:Exceed liquidity";
    string constant POSITION_NOT_EXIST = "TradingEngine:Position not exists";
    string constant INVALID_COLLATERAL_DELTA = "TradingEngine:Invalid collateralDelta";
    string constant POSITION_NOT_LIQUIDATABLE = "TradingEngine:Position not liquidatable";
    string constant EXCEED_MAX_OI = "TradingEngine:Exceed max OI";

    string constant INVALID_COLLATERAL_AMOUNT = "Exchange:Invalid collateral amount";
    string constant TRIGGER_PRICE_NOT_PASS = "Exchange:Trigger price not pass";
    string constant TP_SL_NOT_PASS = "Exchange:TP/SL price not pass";
    string constant LOW_EXECUTION_FEE = "Exchange:Low execution fee";
    string constant ORDER_NOT_FOUND = "Exchange:Order not found";
    string constant NOT_ORDER_OWNER = "Exchange:Not order owner";
    string constant INVALID_TP_SL_PRICE = "Exchange:Invalid TP/SL price";

    error InvalidPositionSize();
    error InsufficientCollateral();
    error PriceFeedInActive();
    error PositionNotExist();
    error InvalidCollateralAmount();
    // Orderbook

    error OrderNotFound(uint256 orderId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library InternalMath {
    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function subMinZero(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }

    // source Compound
    error InvalidUInt64();
    error InvalidUInt104();
    error InvalidUInt128();
    error InvalidInt104();
    error InvalidInt256();
    error NegativeNumber();

    function safe64(uint n) internal pure returns (uint64) {
        if (n > type(uint64).max) revert InvalidUInt64();
        return uint64(n);
    }

    function safe104(uint n) internal pure returns (uint104) {
        if (n > type(uint104).max) revert InvalidUInt104();
        return uint104(n);
    }

    function safe128(uint n) internal pure returns (uint128) {
        if (n > type(uint128).max) revert InvalidUInt128();
        return uint128(n);
    }

    function signed104(uint104 n) internal pure returns (int104) {
        if (n > uint104(type(int104).max)) revert InvalidInt104();
        return int104(n);
    }

    function signed256(uint256 n) internal pure returns (int256) {
        if (n > uint256(type(int256).max)) revert InvalidInt256();
        return int256(n);
    }

    function unsigned104(int104 n) internal pure returns (uint104) {
        if (n < 0) revert NegativeNumber();
        return uint104(n);
    }

    function unsigned256(int256 n) internal pure returns (uint256) {
        if (n < 0) revert NegativeNumber();
        return uint256(n);
    }

    function toUInt8(bool x) internal pure returns (uint8) {
        return x ? 1 : 0;
    }

    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Index, FundingMode, IFundingRateModel, PrevFundingState, FundingConfiguration} from "../interfaces/IFundingManager.sol";
import {ITradingEngine} from "../interfaces/ITradingEngine.sol";
import {InternalMath} from "../common/InternalMath.sol";
import {console} from "forge-std/console.sol";
import {Storage} from "./Storage.sol";

contract FundingManager is Storage {
    using InternalMath for int256;
    using Math for uint256;

    uint256 public constant DEFAULT_FUNDING_INTERVAL = 8 hours;

    event UpdateIndex(
        bytes32 indexed marketId,
        uint256 longFunding,
        uint256 shortFunding,
        uint256 longPayout,
        uint256 shortPayout,
        uint256 nInterval
    );
    event FundingPayout(bytes32 indexed marketId, address indexed account, uint256 value);
    event FundingDebtPaid(bytes32 indexed marketId, address indexed account, uint256 value);

    function _updatePayoutIndex(
        Index memory index,
        uint256 fundingRate,
        uint256 longOpenInterest,
        uint256 shortOpenInterest,
        uint256 nInterval,
        FundingMode mode
    ) internal pure {
        if (mode == FundingMode.BothSide) {
            return;
        }
        // TODO : handle initial funding rate for one side get stuck if there is no otherside (longOpenInterest == 0 || shortOpenInterest == 0)

        if (fundingRate > 0 && shortOpenInterest > 0) {
            index.shortPayout += (nInterval * fundingRate * longOpenInterest) / shortOpenInterest;
        } else if (fundingRate < 0 && longOpenInterest > 0) {
            index.longPayout += (nInterval * fundingRate * shortOpenInterest) / longOpenInterest;
        }
    }

    function _updateIndex(
        bytes32 marketId,
        Index memory index,
        uint256 fundingRate,
        uint256 longOpenInterest,
        uint256 shortOpenInterest,
        uint256 nInterval,
        FundingMode mode
    ) internal {
        if (fundingRate > 0) {
            index.longFunding += nInterval * fundingRate;
        } else if (fundingRate < 0) {
            index.shortFunding += nInterval * fundingRate;
        }

        _updatePayoutIndex(
            index,
            fundingRate,
            longOpenInterest,
            shortOpenInterest,
            nInterval,
            mode
        );

        emit UpdateIndex(
            marketId,
            index.longFunding,
            index.shortFunding,
            index.longPayout,
            index.shortPayout,
            nInterval
        );
    }

    function updateIndex(bytes32 marketId) internal returns (Index memory) {
        PrevFundingState memory state = _prevFundingStates[marketId];
        Index memory index = _indexes[marketId];
        uint256 longOpenInterest = _markets[marketId].longOpenInterest;
        uint256 shortOpenInterest = _markets[marketId].shortOpenInterest;

        FundingConfiguration memory config = _fundingConfigs[marketId];

        uint256 _now = block.timestamp;

        if (state.timestamp == 0) {
            _prevFundingStates[marketId].timestamp = (_now / config.interval) * config.interval;
        } else {
            uint256 nInterval = (_now - state.timestamp) / config.interval;
            if (nInterval == 0) {
                return index;
            }

            int256 nextFundingRate = config.model.getNextFundingRate(
                state,
                longOpenInterest,
                shortOpenInterest
            ); // return fundingRate;
            FundingMode mode = config.model.getFundingMode();

            if (nInterval > 1) {
                // accumulate funding and payout of previous intervals but skip for the current one
                _updateIndex(
                    marketId,
                    index,
                    uint256(state.fundingRate.abs()),
                    state.longOpenInterest,
                    state.shortOpenInterest,
                    nInterval - 1,
                    mode
                );
            }

            _updateIndex(
                marketId,
                index,
                uint256(nextFundingRate.abs()),
                longOpenInterest,
                shortOpenInterest,
                1,
                mode
            );

            // set new state for prevState
            state.fundingRate = nextFundingRate;
            state.timestamp += nInterval * config.interval;
            state.longOpenInterest = longOpenInterest;
            state.shortOpenInterest = shortOpenInterest;

            _indexes[marketId] = index;
            _prevFundingStates[marketId] = state;

            return index;
        }

        return index;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketParams, MarketAddresses, Market, PriceFeedType} from "../interfaces/IMarket.sol";
import {Index, FundingMode, IFundingRateModel, PrevFundingState, FundingConfiguration} from "../interfaces/IFundingManager.sol";
import {VaultState} from "../interfaces/ITradingEngine.sol";
import {Position} from "./position/Position.sol";

contract Storage {
    mapping(bytes32 => MarketParams) public marketParams;
    mapping(bytes32 => MarketAddresses) public marketAddresses;
    mapping(bytes32 => address[]) public extraCollaterals;
    mapping(bytes32 => bool) public isListed;

    mapping(bytes32 => Index) internal _indexes;
    mapping(address => VaultState) internal _vaultStates;
    mapping(address => bool) internal _allowedVault;

    // Fundings
    mapping(bytes32 => PrevFundingState) internal _prevFundingStates;
    mapping(bytes32 => FundingConfiguration) internal _fundingConfigs;

    mapping(bytes32 => Market) internal _markets;
    mapping(bytes32 => Position) internal _positions;
    // map priceFeed => types
    mapping(bytes32 => address) internal _priceFeeds;
    mapping(address => PriceFeedType) internal _priceFeedTypes;

    // marketId -> token -> amount
    mapping(bytes32 => mapping(address => uint256)) internal _feeReserves;
    mapping(address => uint8) internal _decimals;
    mapping(uint8 => bytes32) internal _marketCategories;

    address public exchange;
}

// SPDX-LicenseiIdentifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ITradingEngine, IncreasePositionParams, DecreasePositionParams, LiquidatePositionParams} from "../interfaces/ITradingEngine.sol";
import {Index, FundingConfiguration} from "../interfaces/IFundingManager.sol";
import {MarketParams, MarketAddresses, MarketType, PriceFeedType, Market} from "../interfaces/IMarket.sol";
import {FeeLib} from "./fee/Fee.sol";
import {IStandardPriceFeed, INoSpreadPriceFeed} from "../interfaces/IPriceFeed.sol";
import {IVault} from "../interfaces/IVault.sol";
import {Storage} from "./Storage.sol";
import {MarketManager} from "./market/MarketManager.sol";
import {FundingManager} from "./FundingManager.sol";
import {Validator} from "./Validator.sol";
import {Position, PositionLib, IncreasePositionRequest, IncreasePositionResult, DecreasePositionRequest, DecreasePositionResult} from "./position/Position.sol";
import {Errors} from "../common/Errors.sol";
import {Constants} from "../common/Constants.sol";
import {console} from "forge-std/console.sol";
import {InternalMath} from "../common/InternalMath.sol";

contract TradingEngine is Storage, Validator, FundingManager, ReentrancyGuard {
    using Math for uint256;
    using MarketManager for Market;
    using PositionLib for Position;

    address public gov;

    constructor() {
        gov = msg.sender;
    }

    event ExchangeSet(address indexed exchange);

    modifier onlyGov() {
        require(msg.sender == gov, "TradingEngine: onlygov");
        _;
    }

    modifier onlyExchange() {
        console.log("onlyExchange");
        require(msg.sender == exchange, "TradingEngine: onlyexchange");
        _;
    }

    function setExchange(address _exchange) external onlyGov {
        exchange = _exchange;
        emit ExchangeSet(_exchange);
    }

    function _addMarket(
        MarketAddresses calldata addresses,
        MarketParams calldata params
    ) internal returns (bytes32) {
        bytes32 marketId = MarketManager.addMarket(
            marketParams,
            marketAddresses,
            addresses,
            params
        );
        MarketManager.setMarketListed(isListed, marketId, true);

        _fundingConfigs[marketId] = FundingConfiguration({
            model: addresses.fundingRateModel,
            interval: params.fundingInterval
        });

        _allowedVault[addresses.vault] = addresses.vault != address(0);
        _allowedVault[addresses.quoteVault] = addresses.quoteVault != address(0);

        _priceFeeds[marketId] = addresses.priceFeed;
        _priceFeedTypes[addresses.priceFeed] = params.priceFeedType;

        if (_decimals[addresses.indexToken] == 0) {
            uint8 tokenDecimals = IERC20Metadata(addresses.indexToken).decimals();
            _decimals[addresses.indexToken] = tokenDecimals;
        }

        if (_decimals[addresses.quoteToken] == 0) {
            uint8 tokenDecimals = IERC20Metadata(addresses.quoteToken).decimals();
            _decimals[addresses.quoteToken] = tokenDecimals;
        }

        return marketId;
    }

    function getVault(bytes32 marketId, address collateralToken) external view returns (address) {
        return _getVault(marketId, collateralToken);
    }

    // this function might be reused
    function validatePositionSize(
        bytes32 marketId,
        address collateralToken,
        uint256 size
    ) public view {
        require(isListed[marketId], Errors.MARKET_NOT_LISTED);
        // check if position size doesnt surpass liquidity
        address vault = _getVault(marketId, collateralToken);
        uint256 reserveDelta = _usdToTokenAmountMax(marketId, collateralToken, size);
        // convert to size to token amount
        require(
            _vaultStates[vault].reserveAmount + reserveDelta <= _vaultStates[vault].vaultBalance,
            Errors.EXCEED_LIQUIDITY
        );
        // check doesnt exceed max open interest
    }

    function _getPositionFee(
        bytes32 marketId,
        bool open,
        uint256 sizeDelta
    ) internal view returns (uint256) {
        uint256 feeRate = open ? marketParams[marketId].openFee : marketParams[marketId].closeFee;
        uint256 feeUsd = FeeLib.calculateFee(sizeDelta, feeRate);
        return feeUsd;
    }

    function getVaultAndPositionFee(
        bytes32 marketId,
        address collateralToken,
        bool open,
        uint256 sizeDelta
    ) external view returns (address, uint256, uint256) {
        uint256 feeUsd = _getPositionFee(marketId, open, sizeDelta);
        console.log(
            "_usdToTokenAmountMax",
            _usdToTokenAmountMax(marketId, collateralToken, feeUsd)
        );
        return (
            _getVault(marketId, collateralToken),
            feeUsd,
            _usdToTokenAmountMax(marketId, collateralToken, feeUsd)
        );
    }

    function _getVault(
        bytes32 marketId,
        address collateralToken
    ) internal view returns (address vault) {
        MarketAddresses memory addresses = marketAddresses[marketId];
        MarketType marketType = marketParams[marketId].marketType;

        require(collateralToken != address(0), Errors.ZERO_ADDRESS);
        if (marketType == MarketType.Standard) {
            require(
                collateralToken == addresses.indexToken || collateralToken == addresses.quoteToken,
                Errors.INVALID_COLLATERAL_TOKEN
            );
            return collateralToken == addresses.indexToken ? addresses.vault : addresses.quoteVault;
        } else {
            require(collateralToken == addresses.quoteToken, Errors.INVALID_COLLATERAL_TOKEN);
            return addresses.quoteVault;
        }
    }

    function increasePosition(IncreasePositionParams calldata params) external onlyExchange {
        require(isListed[params.marketId], Errors.MARKET_NOT_LISTED);
        Index memory index = updateIndex(params.marketId);

        bytes32 key = _getPositionKey(
            params.marketId,
            params.account,
            params.collateralToken,
            params.isLong
        );

        Position storage position = _positions[key];

        address vault = _getVault(params.marketId, params.collateralToken);

        uint256 vaultBalanceInUsd = _tokenAmountToUsdMin(
            params.marketId,
            params.collateralToken,
            _vaultStates[vault].vaultBalance
        );

        validateIncreaseSizeDelta(
            params.marketId,
            vaultBalanceInUsd,
            params.isLong,
            params.sizeDelta
        );

        IncreasePositionResult memory result = _increasePosition(key, index, params, vault);

        validateLeverage(
            true,
            position.size,
            position.collateralValue,
            marketParams[params.marketId].maxLeverage
        );

        validateExceedMaxOpenInterest(params.marketId, true, position.size, vaultBalanceInUsd);
        // other validation like openinterest, reserve

        // if (result.fundingDebt > 0) {
        //     emit FundingDebtPaid(params.marketId, params.account, result.fundingDebt);
        // }

        // if (result.fundingPayout > 0) {
        // emit FundingPayout(params.marketId, params.account, result.fundingPayout);
        // }

        // {
        //     emit IncreasePosition(
        //         params.marketId,
        //         params.account,
        //         key,
        //         params.collateralToken,
        //         params.sizeDelta,
        //         params.initialCollateralAmount,
        //         _tokenAmountToUsdMin(
        //             params.marketId,
        //             params.collateralToken,
        //             params.initialCollateralAmount
        //         ),
        //         _getPositionFee(params.marketId, true, params.sizeDelta),
        //         result.fundingDebt,
        //         result.fundingPayout
        //     );
        // }

        emit FeeAndFundings(
            params.marketId,
            key,
            params.openFee,
            result.fundingDebt,
            result.fundingPayout
        );
        emit UpdatePosition(
            params.marketId,
            params.account,
            key,
            params.collateralToken,
            position.size,
            position.collateralValue,
            position.entryPrice,
            position.entryFundingIndex,
            position.entryPayoutIndex
        );
    }

    function decreasePosition(DecreasePositionParams calldata params) external onlyExchange {
        require(isListed[params.marketId], Errors.MARKET_NOT_LISTED);
        Index memory index = updateIndex(params.marketId);

        bytes32 key = _getPositionKey(
            params.marketId,
            params.account,
            params.collateralToken,
            params.isLong
        );

        Position storage position = _positions[key];
        bool isFullyClosed = params.sizeDelta == position.size;
        // if (isFullyClosed) {
        //     require(
        //         params.collateralDelta == position.collateralValue,
        //         Errors.INVALID_COLLATERAL_DELTA
        //     );
        // }

        address vault = _getVault(params.marketId, params.collateralToken);
        require(position.size > 0, Errors.POSITION_NOT_EXIST);

        DecreasePositionResult memory result = _decreasePosition(key, index, params, vault, false);

        if (!isFullyClosed) {
            validateLeverage(
                false,
                position.size,
                position.collateralValue,
                marketParams[params.marketId].maxLeverage
            );
            validateLiquidation(
                position.size,
                position.collateralValue,
                marketParams[params.marketId].maintenanceMarginBps,
                marketParams[params.marketId].liquidationFee
            );
        }

        uint256 payoutAmount = _usdToTokenAmountMin(
            params.marketId,
            params.collateralToken,
            result.payoutValue
        );

        {
            uint256 feeAmount = _usdToTokenAmountMin(
                params.marketId,
                params.collateralToken,
                result.totalFee + result.fundingDebt
            );

            uint256 fundingDebtAmount = (result.fundingDebt * feeAmount) /
                (result.totalFee + result.fundingDebt);
            console.log("feeAmount", feeAmount);
            console.log("result.fundingDebt", result.fundingDebt);
            console.log("fundingDebtAmount", fundingDebtAmount);
            console.log("result payout =======", result.payoutValue);

            if (result.payoutValue > 0) {
                console.log("payoutValue", result.payoutValue);
                console.log("payoutAmount", payoutAmount);

                uint256 collateralAmount = position.collateralAmount;
                uint256 total = feeAmount + payoutAmount;
                bool exceeds = total > collateralAmount;
                console.log("collateral amount", collateralAmount);
                uint256 vaultDelta = exceeds ? total - collateralAmount : 0;
                uint256 collateralAmountDelta = exceeds ? collateralAmount : total;

                console.log("delta", vaultDelta);
                console.log("collateralAmountDelta", collateralAmountDelta);
                // if total exceeds collateralAmount, this means this is a loss to the vault
                IVault(vault).updateVault(!exceeds, vaultDelta, feeAmount);
                position.collateralAmount -= collateralAmountDelta;
                console.log("new psotion collateralAmount", position.collateralAmount);
            } else {
                // payout = 0, means this is a loss to the trader and profit to the vault
                // @suppress-overflow-check
                // feeAmount can > collateralAmountReduced if this is not a full close
                uint256 remain = InternalMath.subMinZero(result.collateralAmountReduced, feeAmount);
                IVault(vault).updateVault(true, remain, feeAmount);
                // @suppress-overflow-check
                // collateralReduced is calculated based on collateralAmount so not possible to verflow
                position.collateralAmount -= result.collateralAmountReduced;

                console.log("done ====");
                // result payout value = 0, this means there trader cut loss
            }
        }

        // (bool hasProfit, uint256 pnl) = _getRealizedPnl(result.realizedPnl);
        // IVault(vault).updateVault(
        //     !hasProfit,
        //     _usdToTokenAmountMin(params.marketId, params.collateralToken, pnl),
        //     _usdToTokenAmountMin(params.marketId, params.collateralToken, result.totalFee)
        // );

        _doTransferOut(vault, params.account, payoutAmount);
        if (result.fundingDebt > 0) {
            emit FundingDebtPaid(params.marketId, params.account, result.fundingDebt);
        }

        if (result.fundingPayout > 0) {
            emit FundingPayout(params.marketId, params.account, result.fundingPayout);
        }

        emit FeeAndFundings(
            params.marketId,
            key,
            result.totalFee,
            result.fundingDebt,
            result.fundingPayout
        );

        if (position.size == 0) {
            emit ClosePosition(
                key,
                position.size,
                position.collateralValue,
                params.isLong ? index.longFunding : index.shortFunding,
                params.isLong ? index.longPayout : index.shortPayout
            );

            delete _positions[key];
        } else {
            emit UpdatePosition(
                params.marketId,
                params.account,
                key,
                params.collateralToken,
                position.size,
                position.collateralValue,
                position.entryPrice,
                position.entryFundingIndex,
                position.entryPayoutIndex
            );
        }
    }

    function updateCollateral() external nonReentrant {}

    function liquidatePosition(LiquidatePositionParams calldata params) external nonReentrant {
        require(isListed[params.marketId], Errors.MARKET_NOT_LISTED);
        Index memory index = updateIndex(params.marketId);
        bytes32 key = _getPositionKey(
            params.marketId,
            params.account,
            params.collateralToken,
            params.isLong
        );

        Position storage position = _positions[key];
        if (position.size == 0) {
            revert Errors.PositionNotExist();
        }

        DecreasePositionParams memory decreaseParams = DecreasePositionParams({
            marketId: params.marketId,
            account: params.account,
            collateralToken: params.collateralToken,
            sizeDelta: position.size,
            isLong: position.isLong
        });

        console.log("initialCollateralAmount, ", position.collateralAmount);

        address vault = _getVault(params.marketId, params.collateralToken);
        DecreasePositionResult memory result = _decreasePosition(
            key,
            index,
            decreaseParams,
            vault,
            true
        );

        uint256 indexPrice = _getPrice(
            _priceFeeds[params.marketId],
            marketAddresses[params.marketId].indexToken,
            position.isLong
        );

        if (result.fundingDebt > 0) {
            emit FundingDebtPaid(params.marketId, params.account, result.fundingDebt);
        }

        if (result.fundingPayout > 0) {
            emit FundingPayout(params.marketId, params.account, result.fundingPayout);
        }

        (, uint256 liquidationFeeTokens) = calcLiquidationFees(
            params.marketId,
            params.collateralToken,
            result.collateralReduced
        );

        {
            uint256 feeAmount = _usdToTokenAmountMin(
                params.marketId,
                params.collateralToken,
                result.totalFee + result.fundingDebt
            );

            uint256 remain = result.collateralAmountReduced - feeAmount;

            // need to subtract liquidation fee tokens from feeAmount because liquidationFeeTokens will be sent to liquidator
            IVault(vault).updateVault(true, remain, feeAmount - liquidationFeeTokens);
        }

        _doTransferOut(vault, params.feeTo, liquidationFeeTokens);

        emit LiquidatePosition(key, params.account, indexPrice);

        // send funding payout for liquidator
        emit FeeAndFundings(
            params.marketId,
            key,
            result.totalFee,
            result.fundingDebt,
            result.fundingPayout
        );

        delete _positions[key];
    }

    function calcLiquidationFees(
        bytes32 marketId,
        address token,
        uint256 collateralReduced
    ) internal view returns (uint256 inUsd, uint256 inTokens) {
        uint256 liquidationFee = marketParams[marketId].liquidationFee;
        inUsd = FeeLib.calculateFee(collateralReduced, liquidationFee);
        inTokens = _usdToTokenAmountMin(marketId, token, inUsd);
    }

    function _getRealizedPnl(
        int256 _realizedPnl
    ) internal pure returns (bool hasProfit, uint256 amount) {
        if (_realizedPnl > 0) {
            hasProfit = true;
            amount = uint256(_realizedPnl);
        } else {
            hasProfit = false;
            amount = uint256(-_realizedPnl);
        }
    }

    function _doTransferOut(address vault, address to, uint256 amount) internal {
        if (amount > 0) {
            IVault(vault).payout(amount, to);
        }
    }

    function _getTotalFeeDecreasePosition(
        uint256 collateralValue,
        uint256 positionSize,
        uint256 closeFee,
        uint256 liquidationFee
    ) internal pure returns (uint256) {
        uint256 closeFeeUsd = FeeLib.calculateFee(positionSize, closeFee);

        uint256 liquidationFeeUsd = liquidationFee > 0
            ? FeeLib.calculateFee(collateralValue, liquidationFee)
            : 0;

        return liquidationFeeUsd + closeFeeUsd;
    }

    function _decreasePosition(
        bytes32 positionKey,
        Index memory index,
        DecreasePositionParams memory params,
        address vault,
        bool isLiquidate
    ) internal returns (DecreasePositionResult memory result) {
        address priceFeed = _priceFeeds[params.marketId];
        Position storage position = _positions[positionKey];

        uint256 indexPrice = _getPrice(
            priceFeed,
            marketAddresses[params.marketId].indexToken,
            // TODO: check if we should reverse this for close position
            position.isLong
        );

        uint256 totalFee = _getTotalFeeDecreasePosition(
            position.collateralValue,
            // fees over size delta
            params.sizeDelta,
            marketParams[params.marketId].closeFee,
            isLiquidate ? marketParams[params.marketId].liquidationFee : 0
        );

        console.log("totalFee", totalFee);

        uint256 fundingRatePrecision = _fundingConfigs[params.marketId]
            .model
            .getFundingRatePrecision();

        if (isLiquidate == true) {
            // validate liquidation
            require(
                isLiquidatable(
                    position,
                    index,
                    indexPrice,
                    totalFee,
                    marketParams[params.marketId].maintenanceMarginBps,
                    fundingRatePrecision
                ),
                Errors.POSITION_NOT_LIQUIDATABLE
            );
        }

        DecreasePositionRequest memory request = DecreasePositionRequest({
            sizeDelta: params.sizeDelta,
            indexPrice: indexPrice,
            totalFee: totalFee,
            fundingRatePrecision: fundingRatePrecision
        });

        result = position.decrease(request, index);

        // increase vault reserve
        _vaultStates[vault].reserveAmount -= result.reserveDelta;
        _markets[params.marketId].updateMarketDecrease(
            result.collateralReduced,
            params.sizeDelta,
            position.isLong
        );

        emit DecreasePosition(params.marketId, params.account, positionKey, params, result);

        // emit LiquidatePosition(key, account, marketAddresses[marketId].indexToken);
    }

    function _getCollateral(
        address collateralToken,
        address vault,
        uint256 price
    ) internal returns (uint256, uint256) {
        uint256 collateralAmount = _requireAmount(IVault(vault).getAmountInAndUpdateVaultBalance());

        console.log("Get collateralAmount", collateralAmount);
        uint256 value = _tokenAmountToUsd(collateralToken, price, collateralAmount);
        return (value, collateralAmount);
    }

    function _increasePosition(
        bytes32 positionKey,
        Index memory index,
        IncreasePositionParams calldata params,
        address vault
    ) internal returns (IncreasePositionResult memory result) {
        (uint256 maxPrice, uint256 minPrice) = _getPriceWithSpread(
            _priceFeeds[params.marketId],
            params.collateralToken
        );

        (uint256 collateralValue, uint256 collateralAmount) = _getCollateral(
            params.collateralToken,
            vault,
            minPrice
        );

        {
            uint256 reserveDelta = _usdToTokenAmount(
                params.collateralToken,
                maxPrice,
                params.sizeDelta
            );

            IncreasePositionRequest memory args = IncreasePositionRequest({
                // price is the price of index token
                price: _getPrice(
                    _priceFeeds[params.marketId],
                    marketAddresses[params.marketId].indexToken,
                    params.isLong
                ),
                sizeDelta: params.sizeDelta,
                collateralValue: collateralValue,
                collateralAmount: collateralAmount,
                reserveDelta: reserveDelta,
                fundingRatePrecision: _fundingConfigs[params.marketId]
                    .model
                    .getFundingRatePrecision(),
                isLong: params.isLong
            });

            result = _positions[positionKey].increase(args, index);

            // increase vault reserve
            _vaultStates[vault].reserveAmount += reserveDelta;
            _markets[params.marketId].updateMarketIncrease(
                collateralValue,
                params.sizeDelta,
                params.isLong
            );

            emit VaultUpdated(params.marketId, vault, collateralAmount, reserveDelta);
        }

        emit IncreasePosition(
            params.marketId,
            params.account,
            positionKey,
            _tokenAmountToUsd(params.collateralToken, minPrice, params.initialCollateralAmount),
            _getPositionFee(params.marketId, true, params.sizeDelta),
            params,
            result
        );

        // params.marketId,
        // key,
        // params.openFee,
        // result.fundingDebt,
        // result.fundingPayout
    }

    function _getDecimals(address token) internal view returns (uint8) {
        return _decimals[token];
    }

    function _getDecimalsOrCache(address token) internal returns (uint8) {
        uint8 decimals = _decimals[token];
        if (decimals != 0) {
            return decimals;
        }

        uint8 tokenDecimals = IERC20Metadata(token).decimals();
        _decimals[token] = tokenDecimals;
        return tokenDecimals;
    }

    function _requireAmount(uint256 amount) internal pure returns (uint256) {
        require(amount > 0, Errors.ZERO_AMOUNT);
        return amount;
    }

    function updateVaultBalance(address vault, uint256 delta, bool isIncrease) external {
        require(msg.sender == vault, Errors.UNAUTHORIZED);
        require(_allowedVault[vault], Errors.UNAUTHORIZED);
        // require vault is allowed
        if (isIncrease) {
            _vaultStates[vault].vaultBalance += delta;
        } else {
            _vaultStates[vault].vaultBalance -= delta;
        }
    }

    function _usdToTokenAmountMin(
        bytes32 marketId,
        address collateralToken,
        uint256 usd
    ) internal view returns (uint256) {
        address priceFeed = _priceFeeds[marketId];
        // get minimum price of collateralToken
        // min price means more usd value
        uint256 maxPrice = _getPrice(priceFeed, collateralToken, false);
        return _usdToTokenAmount(collateralToken, maxPrice, usd);
        // convert scaled amount back to normailized amount
    }

    function _usdToTokenAmount(
        address collateralToken,
        uint256 price,
        uint256 usd
    ) internal view returns (uint256) {
        uint8 decimals = _getDecimals(collateralToken);
        return usd.mulDiv(10 ** decimals, price);
        // convert scaled amount back to normailized amount
    }

    function _usdToTokenAmountMax(
        bytes32 marketId,
        address collateralToken,
        uint256 usd
    ) internal view returns (uint256) {
        address priceFeed = _priceFeeds[marketId];
        // get minimum price of collateralToken
        // min price means more usd value
        uint256 minPrice = _getPrice(priceFeed, collateralToken, false);
        return _usdToTokenAmount(collateralToken, minPrice, usd);
    }

    function _tokenAmountToUsdMin(
        bytes32 marketId,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        address priceFeed = _priceFeeds[marketId];
        // get minimum price of collateralToken
        uint256 maxPrice = _getPrice(priceFeed, token, true);
        return _tokenAmountToUsd(token, maxPrice, amount);
    }

    function _tokenAmountToUsd(
        address collateralToken,
        uint256 price,
        uint256 amount
    ) internal returns (uint256) {
        // scale amount to 18 decimals
        uint256 scaledAmount = amount.mulDiv(price, 10 ** _getDecimalsOrCache(collateralToken));
        return scaledAmount;
    }

    function _getPositionKey(
        bytes32 marketId,
        address account,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(marketId, account, collateralToken, isLong));
    }

    function getPositionKey(
        bytes32 marketId,
        address account,
        address collateralToken,
        bool isLong
    ) external pure returns (bytes32) {
        return _getPositionKey(marketId, account, collateralToken, isLong);
    }

    function _getPriceWithSpread(
        address priceFeed,
        address collateralToken
    ) internal view returns (uint256 min, uint256 max) {
        min = _getPrice(priceFeed, collateralToken, true);
        max = _getPrice(priceFeed, collateralToken, false);
    }

    function _getPrice(
        address priceFeed,
        address token,
        bool isMax
    ) internal view returns (uint256) {
        PriceFeedType priceFeedType = _priceFeedTypes[priceFeed];
        uint256 price;
        if (priceFeedType == PriceFeedType.Standard) {
            price = IStandardPriceFeed(priceFeed).getPrice(token, isMax);
        } else if (priceFeedType == PriceFeedType.StandardNoSpread) {
            price = INoSpreadPriceFeed(priceFeed).getPrice(token);
        }

        require(price > 0, "TradingEngine::INVALID_PRICE");
        return price;
    }

    function getIndexToken(bytes32 marketId) external view returns (address) {
        return marketAddresses[marketId].indexToken;
    }

    function getPriceFeed(
        bytes32 marketId
    ) external view returns (PriceFeedType feedType, address priceFeed) {
        priceFeed = _priceFeeds[marketId];
        feedType = _priceFeedTypes[priceFeed];
    }

    function getIndex(bytes32 marketKey) external view returns (Index memory) {
        return _indexes[marketKey];
    }

    function getPrevFundingState(
        bytes32 marketKey
    )
        public
        view
        returns (
            uint256 timestamp,
            uint256 longOpenInterest,
            uint256 shortOpenInterest,
            int256 fundingRate
        )
    {
        return (
            _prevFundingStates[marketKey].timestamp,
            _prevFundingStates[marketKey].longOpenInterest,
            _prevFundingStates[marketKey].shortOpenInterest,
            _prevFundingStates[marketKey].fundingRate
        );
    }

    // function _getAmountInAndUpdateVaultBalance(
    //     bytes32 marketId,
    //     address token
    // ) internal returns (uint256) {
    //     uint256 balance = IERC20(token).balanceOf(address(this));
    //     uint256 amountIn = balance - _vaultStates[marketId][token].vaultBalance;
    //     _vaultStates[marketId][token].vaultBalance = balance;
    //     return amountIn;
    // }

    function getPosition(bytes32 key) external view returns (Position memory) {
        return _positions[key];
    }

    function getPositionSize(bytes32 key) external view returns (uint256) {
        return _positions[key].size;
    }

    function getFundingInfo(
        bytes32 marketId,
        bytes32 key
    ) external view returns (uint256 fundingPayout, uint256 fundingDebt) {
        Position memory position = _positions[key];
        Index memory index = _indexes[marketId];
        (fundingPayout, fundingDebt) = FeeLib.getFunding(
            index,
            position.entryPayoutIndex,
            position.entryFundingIndex,
            position.size,
            position.isLong,
            _fundingConfigs[marketId].model.getFundingRatePrecision()
        );
    }

    function addMarket(
        MarketAddresses calldata addresses,
        MarketParams calldata params
    ) external returns (bytes32) {
        require(params.isGoverned == false, "TradingEngine: Market is governed");
        return _addMarket(addresses, params);
    }

    function addGovernedMarket(
        MarketAddresses calldata addresses,
        MarketParams calldata params
    ) external onlyGov returns (bytes32) {
        require(params.isGoverned == true, "TradingEngine: Market is not governed");
        return _addMarket(addresses, params);
    }

    function getFundingInterval(bytes32 marketId) external view returns (uint256) {
        return marketParams[marketId].fundingInterval;
    }

    event UpdatePosition(
        bytes32 indexed marketId,
        address indexed account,
        bytes32 key,
        address collateralToken,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryFundingIndex,
        uint256 entryPayoutIndex
    );

    event IncreasePosition(
        bytes32 indexed marketId,
        address indexed account,
        bytes32 key,
        uint256 initialCollateralValue,
        uint256 feeUsd,
        IncreasePositionParams params,
        IncreasePositionResult result
    );

    // add realized pnl everytime decreased position
    event DecreasePosition(
        bytes32 indexed marketId,
        address indexed account,
        bytes32 key,
        DecreasePositionParams params,
        DecreasePositionResult result
    );

    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 exitFundingIndex,
        uint256 exitPayoutIndex
    );

    event LiquidatePosition(bytes32 key, address account, uint256 indexPrice);
    event VaultUpdated(
        bytes32 marketId,
        address vault,
        uint256 collateralAmount, // TODO: write subgraph, borrowedAmount = reserveDelta - collateralAmount
        uint256 reserveDelta
    );

    event FeeAndFundings(
        bytes32 indexed marketId,
        bytes32 indexed key,
        uint256 fee,
        uint256 fundingDebt,
        uint256 fundingPayout
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Errors} from "../common/Errors.sol";
import {Position, PositionLib} from "./position/Position.sol";
import {Index} from "../interfaces/IFundingManager.sol";
import {FeeLib} from "./fee/Fee.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Constants} from "../common/Constants.sol";
import {console} from "forge-std/console.sol";
import {Storage} from "./Storage.sol";
import {Market} from "../interfaces/IMarket.sol";

contract Validator is Storage {
    using SafeCast for uint256;

    function validateIncreaseSizeDelta(
        bytes32 marketId,
        uint256 vaultBalanceInUsd,
        bool isLong,
        uint256 sizeDelta
    ) internal view {
        if (isLong) {
            uint256 maxLongOI = (marketParams[marketId].maxExposureMultiplier *
                vaultBalanceInUsd *
                marketParams[marketId].maxLongShortSkew[0]) / 100;

            console.log(
                "_markets[marketId].longOpenInterest + sizeDelta ",
                _markets[marketId].longOpenInterest + sizeDelta
            );
            console.log("maxLongOI", maxLongOI);

            require(
                _markets[marketId].longOpenInterest + sizeDelta <= maxLongOI,
                Errors.EXCEED_MAX_OI
            );
        } else {
            uint256 maxShortOI = (marketParams[marketId].maxExposureMultiplier *
                vaultBalanceInUsd *
                marketParams[marketId].maxLongShortSkew[1]) / 100;

            require(
                _markets[marketId].shortOpenInterest + sizeDelta <= maxShortOI,
                Errors.EXCEED_MAX_OI
            );
        }
    }

    function validateExceedMaxOpenInterest(
        bytes32 marketId,
        bool isIncrease,
        uint256 size,
        uint256 vaultBalanceInUsd
    ) internal view {
        if (isIncrease && size == 0) {
            revert Errors.InvalidPositionSize();
        }
        // require(size >= collateralValue, "Validator:: invalid leverage");

        console.log("size", size);
        console.log(
            "max size",
            (marketParams[marketId].maxPostionSizeOverVault * vaultBalanceInUsd) /
                Constants.BASIS_POINTS_DIVISOR
        );

        require(
            size <=
                (marketParams[marketId].maxPostionSizeOverVault * vaultBalanceInUsd) /
                    Constants.BASIS_POINTS_DIVISOR,
            "Validator:: size exceeds max"
        );
    }

    function validateLeverage(
        bool isIncrease,
        uint256 size,
        uint256 collateralValue,
        uint256 maxLeverage
    ) internal view {
        console.log("----validateLeverage----");
        if (isIncrease && size == 0) {
            revert Errors.InvalidPositionSize();
        }
        // Drop this condition: Will it affect anything
        // require(size >= collateralValue, "RiskManagement:: invalid leverage");

        console.log("Size", size);
        console.log("collateralValue", collateralValue);
        console.log("collateralValue * maxLeverage", collateralValue * maxLeverage);
        require(size <= collateralValue * maxLeverage, "RiskManagement: max leverage exceeded");
    }

    function validateLiquidation(
        uint256 size,
        uint256 collateralValue,
        uint256 maintenanceMarginBps,
        uint256 liquidationFeeBps
    ) internal view {
        uint256 liquidationFee = FeeLib.calculateFee(collateralValue, liquidationFeeBps);

        uint256 maintenanceMargin = (size * maintenanceMarginBps) / Constants.BASIS_POINTS_DIVISOR;
        console.log("maintenanceMargin", maintenanceMargin);
        int256 remain = collateralValue.toInt256() - liquidationFee.toInt256();
        console.log("remain");
        console.logInt(remain);

        if (remain < maintenanceMargin.toInt256()) {
            revert Errors.InsufficientCollateral();
        }
    }

    function isLiquidatable(
        Position memory position,
        Index memory index,
        uint256 indexPrice,
        uint256 totalFee,
        uint256 maintenanceMarginBps,
        uint256 fundingRatePrecision
    ) internal view returns (bool) {
        if (position.size == 0) {
            return false;
        }

        console.log("checkiing is liquidatable");

        (uint256 fundingPayout, uint256 fundingDebt) = FeeLib.getFunding(
            index,
            position.entryPayoutIndex,
            position.entryFundingIndex,
            position.size,
            position.isLong,
            fundingRatePrecision
        );

        int256 pnl = PositionLib.calcPnl(
            position.isLong,
            position.size,
            position.entryPrice,
            indexPrice
        );

        int256 fee = fundingPayout.toInt256() - fundingDebt.toInt256() - totalFee.toInt256();

        uint256 maintenanceMargin = (position.size * maintenanceMarginBps) /
            Constants.BASIS_POINTS_DIVISOR;

        console.log("maintenanceMargin", maintenanceMargin);
        console.log("fee");
        console.logInt(fee);

        int256 remain = position.collateralValue.toInt256() + pnl + fee;
        console.log("=====remain ====");
        console.logInt(remain);
        return remain < maintenanceMargin.toInt256();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Index} from "../../interfaces/IFundingManager.sol";
import {Constants} from "../../common/Constants.sol";

library FeeLib {
    using Math for uint256;

    function calculateFee(uint256 size, uint256 rate) internal pure returns (uint256) {
        return size.mulDiv(rate, Constants.FEE_PRECISION);
    }

    function getFundingPayout(
        Index memory index,
        uint256 entryPayoutIndex,
        uint256 positionSize,
        bool isLong,
        uint256 precision
    ) internal pure returns (uint256) {
        uint256 payoutIndex = isLong ? index.longPayout : index.shortPayout;
        require(entryPayoutIndex <= payoutIndex, "FundingManager: invalid entry payout index");
        uint256 diff = payoutIndex - entryPayoutIndex;
        return diff.mulDiv(positionSize, precision);
    }

    function getFundingDebt(
        Index memory index,
        uint256 entryFundingIndex,
        uint256 positionSize,
        bool isLong,
        uint256 precision
    ) internal pure returns (uint256) {
        uint256 fundingIndex = isLong ? index.longFunding : index.shortFunding;
        require(entryFundingIndex <= fundingIndex, "FundingManager: invalid entry funding index");
        uint256 diff = fundingIndex - entryFundingIndex;
        return diff.mulDiv(positionSize, precision);
    }

    function getFunding(
        Index memory index,
        uint256 entryPayoutIndex,
        uint256 entryFundingIndex,
        uint256 positionSize,
        bool isLong,
        uint256 precision
    ) internal pure returns (uint256 payout, uint256 debt) {
        uint256 payoutIndex = isLong ? index.longPayout : index.shortPayout;
        uint256 fundingIndex = isLong ? index.longFunding : index.shortFunding;

        require(entryPayoutIndex <= payoutIndex, "FundingManager: invalid entry payout index");
        require(entryFundingIndex <= fundingIndex, "FundingManager: invalid entry funding index");

        uint256 diffPayoutIndex = payoutIndex - entryPayoutIndex;
        payout = diffPayoutIndex.mulDiv(positionSize, precision);

        uint256 diffFundingIndex = fundingIndex - entryFundingIndex;
        debt = diffFundingIndex.mulDiv(positionSize, precision);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketType, MarketParams, MarketAddresses, Market} from "../../interfaces/IMarket.sol";
import {MarketUtils} from "./MarketUtils.sol";
import {console} from "forge-std/console.sol";

library MarketManager {
    event MarketCreated(
        MarketType indexed marketType,
        bytes32 indexed marketId,
        address indexed owner,
        address indexToken,
        address quoteToken,
        bytes32 name,
        bool isGoverned,
        uint8 category,
        uint8 maxLeverage
    );
    event MarketListed(bytes32 indexed marketId, bool isListed);
    event CategoriesUpdated(uint8[] categories, bytes32[] values);

    modifier _validateMarketAddresses(MarketAddresses memory addresses, MarketType marketType) {
        if (marketType != MarketType.Synthetic) {
            require(address(addresses.vault) != address(0), "MarketManager:Vault is required");
        }

        if (marketType != MarketType.SyntheticNoIndex) {
            require(
                address(addresses.indexToken) != address(0),
                "MarketManager:Index token is required"
            );
        }

        require(
            address(addresses.quoteToken) != address(0),
            "MarketManager:Stablecoin is required"
        );
        require(
            address(addresses.quoteVault) != address(0),
            "MarketManager:StablecoinVault is required"
        );
        require(address(addresses.priceFeed) != address(0), "MarketManager:priceFeed is required");
        require(
            address(addresses.fundingRateModel) != address(0),
            "MarketManager: fundingRateModel is required"
        );
        _;
    }

    function updateMarketIncrease(
        Market storage market,
        uint256 collateralValue,
        uint256 sizeDelta,
        bool isLong
    ) internal {
        if (isLong) {
            market.longOpenInterest += sizeDelta;
        } else {
            market.shortOpenInterest += sizeDelta;
        }

        market.totalCollateralValue += collateralValue;
        market.totalBorrowedValue += (sizeDelta - collateralValue);
    }

    function updateMarketDecrease(
        Market storage market,
        uint256 collateralReduced,
        uint256 sizeDelta,
        bool isLong
    ) internal {
        if (isLong) {
            market.longOpenInterest -= sizeDelta;
        } else {
            market.shortOpenInterest -= sizeDelta;
        }

        market.totalCollateralValue -= collateralReduced;
        market.totalBorrowedValue = market.totalBorrowedValue + collateralReduced - sizeDelta;
    }

    function addMarket(
        mapping(bytes32 => MarketParams) storage marketParams,
        mapping(bytes32 => MarketAddresses) storage marketAddresses,
        MarketAddresses calldata addresses,
        MarketParams calldata params
    ) internal _validateMarketAddresses(addresses, params.marketType) returns (bytes32 marketId) {
        // Check msg.sender is vault owner
        // we shouldn't allow a user to use protocol's vault for their market
        if (params.marketType != MarketType.SyntheticNoIndex) {
            require(address(addresses.indexToken) != address(0), "MarketManager:Asset is required");
        }

        if (params.maxLongShortSkew[0] != 0 || params.maxLongShortSkew[1] != 0) {
            require(
                params.maxLongShortSkew[0] + params.maxLongShortSkew[1] == 100,
                "MarketManager: maxLongShortSkew should equal 100"
            );
        }

        marketId = MarketUtils.getMarketKey(
            params.marketType,
            addresses.owner,
            addresses.indexToken,
            addresses.quoteToken
        );

        require(marketAddresses[marketId].owner == address(0), "MarketManager: market exists");
        marketParams[marketId] = params;
        marketAddresses[marketId] = addresses;

        emit MarketCreated(
            params.marketType,
            marketId,
            addresses.owner,
            addresses.indexToken,
            addresses.quoteToken,
            params.name,
            params.isGoverned,
            params.category,
            params.maxLeverage
        );

        emit MarketListed(marketId, true);
    }

    function setMarketListed(
        mapping(bytes32 => bool) storage isListed,
        bytes32 marketId,
        bool flag
    ) internal {
        isListed[marketId] = flag;
        emit MarketListed(marketId, flag);
    }

    function setMarketCategories(
        mapping(uint8 => bytes32) storage marketCategories,
        uint8[] calldata categories,
        bytes32[] calldata values
    ) internal {
        for (uint256 i = 0; i < categories.length; i++) {
            marketCategories[categories[i]] = values[i];
        }

        emit CategoriesUpdated(categories, values);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketType} from "../../interfaces/IMarket.sol";

library MarketUtils {
    function getMarketKey(
        MarketType marketType,
        address account,
        address indexToken,
        address stablecoin
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(marketType, account, indexToken, stablecoin));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Index} from "../../interfaces/IFundingManager.sol";
import {Constants} from "../../common/Constants.sol";
import {FundingManager} from "../FundingManager.sol";
import {FeeLib} from "../fee/Fee.sol";
import {console} from "forge-std/console.sol";
import {InternalMath} from "../../common/InternalMath.sol";

struct Position {
    /// @dev side of the position, long or short
    bool isLong;
    /// @dev contract size is evaluated in dollar
    uint256 size;
    /// @dev collateral value in dollar
    uint256 collateralValue;
    uint256 collateralAmount;
    /// @dev average entry price
    uint256 entryPrice;
    /// @dev last cumulative interest rate
    uint256 entryFundingIndex;
    uint256 entryPayoutIndex;
    uint256 reserveAmount;
}

struct IncreasePositionRequest {
    uint256 price;
    uint256 sizeDelta;
    uint256 collateralValue;
    uint256 collateralAmount;
    uint256 fundingRatePrecision;
    uint256 reserveDelta;
    bool isLong;
}

struct DecreasePositionRequest {
    uint256 sizeDelta;
    uint256 indexPrice;
    uint256 totalFee; // 1e18
    uint256 fundingRatePrecision;
}

struct IncreasePositionResult {
    uint256 fundingPayout;
    uint256 fundingDebt;
    uint256 executedPrice;
}

struct DecreasePositionResult {
    int256 realizedPnl;
    uint256 reserveDelta;
    uint256 payoutValue;
    uint256 collateralReduced;
    uint256 collateralAmountReduced;
    uint256 totalFee;
    uint256 fundingPayout;
    uint256 fundingDebt;
    uint256 executedPrice;
}

library PositionLib {
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    function increase(
        Position storage position,
        IncreasePositionRequest memory params,
        Index memory index
    ) internal returns (IncreasePositionResult memory result) {
        uint256 size = position.size;
        // set entry price
        if (size == 0) {
            position.entryPrice = params.price;
        } else {
            position.entryPrice = getNextAveragePrice(
                size,
                position.entryPrice,
                params.isLong,
                params.price,
                params.sizeDelta
            );
        }
        (uint256 fundingPayout, uint256 fundingDebt) = FeeLib.getFunding(
            index,
            position.entryPayoutIndex,
            position.entryFundingIndex,
            size,
            position.isLong,
            params.fundingRatePrecision
        );

        console.log("Funding payout, debt", fundingPayout, fundingDebt);

        uint256 nextCollateralValue = InternalMath.subMinZero(
            position.collateralValue + params.collateralValue + fundingPayout,
            fundingDebt
        );

        position.collateralValue = nextCollateralValue;
        position.size += params.sizeDelta;
        position.entryFundingIndex = params.isLong ? index.longFunding : index.shortFunding;
        position.entryPayoutIndex = params.isLong ? index.longPayout : index.shortPayout;
        position.isLong = params.isLong;
        position.reserveAmount += params.reserveDelta;

        position.collateralAmount += params.collateralAmount;
        console.log("INcrease params collateralAmount", params.collateralAmount);

        result.fundingPayout = fundingPayout;
        result.fundingDebt = fundingDebt;
        result.executedPrice = params.price;
    }

    function decrease(
        Position storage position,
        DecreasePositionRequest memory params,
        Index memory index
    ) internal returns (DecreasePositionResult memory result) {
        require(position.size >= params.sizeDelta, "Position:decrease: insufficient position size");
        // require(
        //     position.collateralValue >= params.collateralDelta,
        //     "Position:decrease: insufficient collateral"
        // );

        uint256 size = position.size;

        int256 pnl = calcPnl(
            position.isLong,
            position.size,
            position.entryPrice,
            params.indexPrice
        );

        result.realizedPnl = (pnl * toInt256(params.sizeDelta)) / toInt256(position.size);

        (result.fundingPayout, result.fundingDebt) = FeeLib.getFunding(
            index,
            position.entryPayoutIndex,
            position.entryFundingIndex,
            size,
            position.isLong,
            params.fundingRatePrecision
        );

        console.log("Decrease sizeDelta", params.sizeDelta);
        console.log("Decrease size", size);
        uint256 collateralDelta = params.sizeDelta == size ? position.collateralValue : 0;
        uint256 nextCollateralValue = position.collateralValue - collateralDelta;
        console.log("Decrease collateralDelta", collateralDelta);

        console.log("positoin size", position.size);
        console.log("entryPrice", position.entryPrice);
        console.log("initial collateralValue", position.collateralValue);
        console.log("PNL");
        console.logInt(result.realizedPnl);

        int256 payoutValueInt = result.realizedPnl +
            toInt256(collateralDelta) +
            toInt256(result.fundingPayout) -
            toInt256(result.fundingDebt) -
            toInt256(params.totalFee);
        console.log("payout value");
        console.logInt(payoutValueInt);

        if (payoutValueInt < 0) {
            // if payoutValue is negative, deduct uncovered lost from collateral
            // set a cap zero for the substraction to avoid underflow
            nextCollateralValue = InternalMath.subMinZero(
                nextCollateralValue,
                uint256(InternalMath.abs(payoutValueInt))
            );
        }

        result.reserveDelta = (position.reserveAmount * params.sizeDelta) / position.size;
        result.payoutValue = payoutValueInt > 0 ? uint256(payoutValueInt) : 0;
        result.collateralReduced = position.collateralValue - nextCollateralValue;
        result.totalFee = params.totalFee;
        result.executedPrice = params.indexPrice;
        bool isLong = position.isLong;
        if (result.collateralReduced > 0) {
            result.collateralAmountReduced =
                (position.collateralAmount * result.collateralReduced) /
                position.collateralValue;
            // position.collateralAmount -= result.collateralAmountReduced;
        }

        position.entryFundingIndex = isLong ? index.longFunding : index.shortFunding;
        position.entryPayoutIndex = isLong ? index.longPayout : index.shortPayout;
        position.size -= params.sizeDelta;
        position.collateralValue = nextCollateralValue;
        position.reserveAmount = position.reserveAmount - result.reserveDelta;
    }

    function getFundingFeeValue(
        uint256 _entryFundingIndex,
        uint256 _nextFundingIndex,
        uint256 _positionSize,
        uint256 _precision
    ) internal pure returns (uint256) {
        return (_positionSize * (_nextFundingIndex - _entryFundingIndex)) / _precision;
    }

    function calcMarginFees(
        Position memory position,
        uint256 _positionFee,
        uint256 _sizeDelta,
        uint256 _nextFundingIndex,
        uint256 _fundingRatePrecision
    ) internal pure returns (uint256) {
        uint256 positionFee = (_sizeDelta * _positionFee) / Constants.FEE_PRECISION;
        uint256 fundingFee = getFundingFeeValue(
            position.entryFundingIndex,
            _nextFundingIndex,
            position.size,
            _fundingRatePrecision
        );

        return positionFee + fundingFee;
    }

    function calcPnl(
        bool _isLong,
        uint256 _positionSize,
        uint256 _entryPrice,
        uint256 _nextPrice
    ) internal pure returns (int256) {
        if (_positionSize == 0) {
            return 0;
        }

        if (_isLong) {
            int256 priceDelta = int256(_nextPrice) - int256(_entryPrice);

            return (priceDelta * int256(_positionSize)) / int256(_entryPrice);
        }

        int256 priceDeltaShort = int256(_entryPrice) - int256(_nextPrice);
        return (priceDeltaShort * int256(_positionSize)) / int256(_entryPrice);

        // TODO: GMX handle front running bot
        // if the minProfitTime has passed then there will be no min profit threshold
        // the min profit threshold helps to prevent front-running issues
        // uint256 minBps = block.timestamp > _lastIncreasedTime.add(minProfitTime) ? 0 : minProfitBasisPoints[_indexToken];
        // if (hasProfit && delta.mul(BASIS_POINTS_DIVISOR) <= _size.mul(minBps)) {
        //     delta = 0;
        // }
    }

    function getNextAveragePrice(
        uint256 _size,
        uint256 _entryPrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) internal pure returns (uint256) {
        if (_sizeDelta == 0) {
            return _entryPrice;
        }

        int256 pnl = calcPnl(_isLong, _size, _entryPrice, _nextPrice);

        uint256 nextSize = _size + _sizeDelta;
        int256 divisor = int256(nextSize) + pnl; // always > 0
        return (_nextPrice * nextSize) / uint256(divisor);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

enum FundingMode {
    SingleSide,
    BothSide
}

struct Index {
    uint256 longPayout;
    uint256 shortPayout;
    uint256 longFunding;
    uint256 shortFunding;
}

struct FundingConfiguration {
    IFundingRateModel model;
    uint256 interval;
}

// state of previous funding interval
struct PrevFundingState {
    uint256 timestamp;
    uint256 longOpenInterest;
    uint256 shortOpenInterest;
    int256 fundingRate;
}

interface IFundingRateModel {
    function getNextFundingRate(
        PrevFundingState memory prevState,
        uint256 longOpenInterest,
        uint256 shortOpenInterest
    ) external view returns (int256);

    function getFundingMode() external view returns (FundingMode mode);

    function getFundingRatePrecision() external pure returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IFundingRateModel} from "./IFundingManager.sol";

enum MarketType {
    Standard,
    Synthetic,
    SyntheticNoIndex // synthetic market without index token. For example: commodities/ Forex
}

enum PriceFeedType {
    Standard,
    StandardNoSpread,
    Chainlink
}

struct MarketAddresses {
    address owner;
    address indexToken;
    // vault is address 0 for synthetic markets
    address vault;
    address quoteToken;
    address quoteVault;
    address priceFeed;
    IFundingRateModel fundingRateModel;
}

struct MarketParams {
    bytes32 name;
    // list of two number, the first for index token liquidity providers, the second is for stablecoinVault liquidity providers
    uint8[2] feeDistributionWeights; // 20 , 30
    uint8[2] maxLongShortSkew; // Don'' set item[0] + item[1] should equal 100
    uint16 maintenanceMarginBps;
    uint16 liquidationFee; // liquidationFee rate over collateralValue
    uint16 maxPostionSizeOverVault; // 1% // bps
    uint16 openFee; // rate - over size, bps
    uint16 closeFee; // rate - over size, bps
    uint32 fundingInterval; // default 8 hours
    uint8 maxLeverage;
    uint8 maxExposureMultiplier; // 1 - 3 // max OI is 3x of the total collateral, default: 1
    uint8 category;
    MarketType marketType;
    PriceFeedType priceFeedType;
    bool isGoverned;
}

struct Market {
    uint256 totalBorrowedValue;
    uint256 totalCollateralValue;
    uint256 longOpenInterest;
    uint256 shortOpenInterest;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IStandardPriceFeed {
    function getPrice(address token, bool isMax) external view returns (uint256);

    function setPrices(address[] calldata tokens, uint256[] calldata prices) external;
}

interface INoSpreadPriceFeed {
    function getPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketParams, MarketAddresses, MarketType, PriceFeedType, Market} from "../interfaces/IMarket.sol";

struct IncreasePositionParams {
    bytes32 marketId;
    uint256 sizeDelta;
    uint256 openFee;
    uint256 initialCollateralAmount;
    address account;
    address collateralToken;
    bool isLong;
}

struct DecreasePositionParams {
    bytes32 marketId;
    address account;
    address collateralToken;
    uint256 sizeDelta;
    bool isLong;
}

struct LiquidatePositionParams {
    bytes32 marketId;
    address account;
    address collateralToken;
    bool isLong;
    address feeTo;
}

struct VaultState {
    /// @notice amount of token deposited (via adding liquidity or increasing long position)
    uint256 vaultBalance;
    /// @notice amount of token reserved for paying out when user takes profit, is the amount of tokens borrowed plus long position collateral
    uint256 reserveAmount;
}

interface ITradingEngine {
    function updateVaultBalance(address token, uint256 delta, bool isIncrease) external;

    function getPositionSize(bytes32 key) external view returns (uint256);

    function increasePosition(IncreasePositionParams calldata params) external;

    function decreasePosition(DecreasePositionParams calldata params) external;

    function getVault(bytes32 marketId, address collateralToken) external view returns (address);

    function getPriceFeed(
        bytes32 marketId
    ) external view returns (PriceFeedType feedType, address priceFeed);

    function getVaultAndPositionFee(
        bytes32 marketId,
        address collateralToken,
        bool open,
        uint256 sizeDelta
    ) external view returns (address vault, uint256 feesInUsd, uint256 feesInTokens);

    function getIndexToken(bytes32 marketId) external view returns (address);

    function validatePositionSize(
        bytes32 marketId,
        address collateralToken,
        uint256 size
    ) external view;

    function getPositionKey(
        bytes32 marketId,
        address account,
        address collateralToken,
        bool isLong
    ) external returns (bytes32);

    function addMarket(
        MarketAddresses calldata addresses,
        MarketParams calldata params
    ) external returns (bytes32);

    function setExchange(address exchange) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IVault {
    function getAmountInAndUpdateVaultBalance() external returns (uint256);

    function payout(uint256 amount, address receiver) external;

    function updateVault(bool hasProfit, uint256 pnl, uint256 fee) external;

    function deposit(uint256 amount, address receiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}