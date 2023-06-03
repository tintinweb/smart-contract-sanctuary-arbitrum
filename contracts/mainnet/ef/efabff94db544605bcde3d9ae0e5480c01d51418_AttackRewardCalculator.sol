//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
@title AttackRewardCalculator

Just a lil weighted distrubution for distributing attack rewards weighted by tier
 */

import "@openzeppelin/contracts/utils/math/Math.sol";

contract AttackRewardCalculator {
    uint256 public constant MULDIV_FACTOR = 10000;

    function calculateTotalWeight(uint256 tier1Attacks, uint256 tier2Attacks, uint256 tier3Attacks, uint256 tier1Weight, uint256 tier2Weight, uint256 tier3Weight) internal pure returns(uint256){
        return Math.mulDiv(tier1Attacks, tier1Weight, 1) +
            Math.mulDiv(tier2Attacks, tier2Weight, 1) +
            Math.mulDiv(tier3Attacks, tier3Weight, 1);
    }

    function calculateShare(uint256 totalKarrotsDepositedThisEpoch, uint256 tierAttacks, uint256 tierWeight, uint256 totalWeight) internal pure returns(uint256){
        if(tierAttacks > 0){
            return Math.mulDiv(
                totalKarrotsDepositedThisEpoch * tierAttacks,
                tierWeight * MULDIV_FACTOR,
                totalWeight * MULDIV_FACTOR
            );
        }
        return 0;
    }

    function calculateRewardPerAttack(uint256 tierShare, uint256 tierAttacks) internal pure returns(uint256){
        if(tierAttacks > 0){
            return Math.mulDiv(tierShare, 1, tierAttacks);
        }
        return 0;
    }

    function calculateRewardPerAttackByTier(
        uint256 tier1Attacks,
        uint256 tier2Attacks,
        uint256 tier3Attacks,
        uint256 tier1Weight,
        uint256 tier2Weight,
        uint256 tier3Weight,
        uint256 totalKarrotsDepositedThisEpoch
    ) external view returns (uint256[] memory) {
        
        uint256 totalWeight = calculateTotalWeight(tier1Attacks, tier2Attacks, tier3Attacks, tier1Weight, tier2Weight, tier3Weight);
        uint256 tier1Share = calculateShare(totalKarrotsDepositedThisEpoch, tier1Attacks, tier1Weight, totalWeight);
        uint256 tier2Share = calculateShare(totalKarrotsDepositedThisEpoch, tier2Attacks, tier2Weight, totalWeight);
        uint256 tier3Share = calculateShare(totalKarrotsDepositedThisEpoch, tier3Attacks, tier3Weight, totalWeight);

        uint256[] memory rewards = new uint256[](3);
        rewards[0] = calculateRewardPerAttack(tier1Share, tier1Attacks);
        rewards[1] = calculateRewardPerAttack(tier2Share, tier2Attacks);
        rewards[2] = calculateRewardPerAttack(tier3Share, tier3Attacks);

        return rewards;
    }
}

// pragma solidity ^0.8.19;

// /**
// @title AttackRewardCalculator

// Just a lil weighted distrubution for distributing attack rewards weighted by tier
//  */

// import "@openzeppelin/contracts/utils/math/Math.sol";

// contract AttackRewardCalculator {
//     uint256 public constant MULDIV_FACTOR = 10000;

//     //hook for formula to be changed later if need be
//     //this outputs reward per attack by tier based on input balance since the last epoch started
//     function calculateRewardPerAttackByTier(
//         uint256 tier1Attacks,
//         uint256 tier2Attacks,
//         uint256 tier3Attacks,
//         uint256 tier1Weight,
//         uint256 tier2Weight,
//         uint256 tier3Weight,
//         uint256 totalKarrotsDepositedThisEpoch
//     ) external view returns (uint256[] memory) {

//         uint256[] memory rewards = new uint256[](3);
        
//         uint256 tier1Share;
//         uint256 tier2Share;
//         uint256 tier3Share;
//         uint256 tier1RewardsPerAttack;
//         uint256 tier2RewardsPerAttack;
//         uint256 tier3RewardsPerAttack;
        
//         uint256 totalWeight = Math.mulDiv(tier1Attacks, tier1Weight, 1) +
//             Math.mulDiv(tier2Attacks, tier2Weight, 1) +
//             Math.mulDiv(tier3Attacks, tier3Weight, 1);

//         if (tier1Attacks > 0) {
//             tier1Share = Math.mulDiv(
//                 totalKarrotsDepositedThisEpoch * tier1Attacks,
//                 tier1Weight * MULDIV_FACTOR,
//                 totalWeight * MULDIV_FACTOR
//             );
//         } else {
//             tier1Share = 0;
//         }

//         if (tier2Attacks > 0) {
//             tier2Share = Math.mulDiv(
//                 totalKarrotsDepositedThisEpoch * tier2Attacks,
//                 tier2Weight * MULDIV_FACTOR,
//                 totalWeight * MULDIV_FACTOR
//             );
//         } else {
//             tier2Share = 0;
//         }

//         if (tier3Attacks > 0) {
//             tier3Share = Math.mulDiv(
//                 totalKarrotsDepositedThisEpoch * tier3Attacks,
//                 tier3Weight * MULDIV_FACTOR,
//                 totalWeight * MULDIV_FACTOR
//             );
//         } else {
//             tier3Share = 0;
//         }

//         if (tier1Attacks > 0) {
//             tier1RewardsPerAttack = Math.mulDiv(tier1Share, 1, tier1Attacks);
//         } else {
//             tier1RewardsPerAttack = 0;
//         }

//         if (tier2Attacks > 0) {
//             tier2RewardsPerAttack = Math.mulDiv(tier2Share, 1, tier2Attacks);
//         } else {
//             tier2RewardsPerAttack = 0;
//         }

//         if (tier3Attacks > 0) {
//             tier3RewardsPerAttack = Math.mulDiv(tier3Share, 1, tier3Attacks);
//         } else {
//             tier3RewardsPerAttack = 0;
//         }

//         rewards[0] = tier1RewardsPerAttack;
//         rewards[1] = tier2RewardsPerAttack;
//         rewards[2] = tier3RewardsPerAttack;

//         return rewards;
//     }
// }

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