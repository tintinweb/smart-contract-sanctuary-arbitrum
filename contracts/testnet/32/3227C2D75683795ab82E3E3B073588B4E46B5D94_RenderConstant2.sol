// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";

library RenderConstant2 {

    string internal constant _P10 =
        '<svg xmlns="http://www.w3.org/2000/svg" x="72" y="380"><svg width="120" height="120"><clipPath id="prefix__clipCircle"><circle cx="48" cy="48" r="48"/></clipPath><circle cx="48" cy="48" r="48" fill="#C8145C"/><g clip-path="url(#prefix__clipCircle)"><path fill="#FA6000" d="M29.633 48.617l-86.61-83.057 83.056-86.611 86.611 83.057z"/><path fill="#F5AF00" d="M63.4 142.048l-119.678 8.788-8.788-119.677L54.61 22.37z"/><path fill="#03585E" d="M21.906-1.682l9.833 119.597-119.596 9.832L-97.69 8.151z"/></g></svg></svg><defs><linearGradient id="prefix__p0" x1="622.044" y1="-2.347" x2="622.044" y2="678.332" gradientUnits="userSpaceOnUse"><stop stop-color="#452F16"/><stop offset="1" stop-color="#1B2023"/></linearGradient><linearGradient id="prefix__p1" x1="622.044" y1="-2.347" x2="622.044" y2="668.943" gradientUnits="userSpaceOnUse"><stop stop-color="#FF8A00"/><stop offset="1" stop-color="#52391B"/></linearGradient><linearGradient id="prefix__p2" x1="622.171" y1="-1.73" x2="622.171" y2="347.827" gradientUnits="userSpaceOnUse"><stop stop-color="#F78602" stop-opacity=".35"/><stop offset="1" stop-color="#F78602" stop-opacity="0"/></linearGradient><linearGradient id="prefix__p75" x1="919" y1="180" x2="919" y2="276" gradientUnits="userSpaceOnUse"><stop stop-color="#FFFFDA"/><stop offset=".503" stop-color="#FFE7B6"/><stop offset="1" stop-color="#A87945"/></linearGradient><pattern id="prefix__pattern0" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#prefix__image0_539_2800" transform="matrix(.00255 0 0 .00255 -.639 -1.77)"/></pattern></defs><style>@font-face{font-family:&apos;Black Ops One&apos;;font-style:normal;font-weight:400;src:url(data:application/font;base64,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) format(&apos;woff2&apos;);unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}@font-face{font-family:&apos;VT323&apos;;font-style:normal;font-weight:400;src:url(data:application/font;base64,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) format(&apos;woff2&apos;)}</style></svg>';

 
    function P10() public pure returns (string memory) {
        return _P10;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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