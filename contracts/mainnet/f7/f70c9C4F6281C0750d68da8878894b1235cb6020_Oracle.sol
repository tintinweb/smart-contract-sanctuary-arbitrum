// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
import './FullMath.sol';
import './SafeCast.sol';
import '@openzeppelin-3.4.1/contracts/math/Math.sol';

/// @title Math library for liquidity
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }

    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta256(uint256 x, int256 y) internal pure returns (uint256 z) {
        if (y < 0) {
            require((z = x - uint256(-y)) < x, 'LS');
        } else {
            require((z = x + uint256(y)) >= x, 'LA');
        }
    }

    function calculateBoostedLiquidity(
        uint128 liquidity,
        int128 veRamAmount,
        int128 totalVeRamAmount
    ) internal pure returns (uint128 boostedLiquidity) {
        // users acheive full boost if their veRAM is >=10% of the total veRAM attached to the pool
        // full boost is 1x original + 1.5x boost
        uint256 boostRatio = Math.min(
            FullMath.mulDiv(uint256(veRamAmount), 1.5e18, totalVeRamAmount != 0 ? uint256(totalVeRamAmount / 10) : 1),
            1.5e18
        ); // veRamAmount and totalVeRamAmount can't go below 0

        boostedLiquidity = SafeCast.toUint128(FullMath.mulDiv(liquidity, boostRatio, 1e18));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

import './Tick.sol';
import './States.sol';

/// @title Oracle
/// @notice Provides price and liquidity data useful for a wide variety of system designs
/// @dev Instances of stored oracle data, "observations", are collected in the oracle array
/// Every pool is initialized with an oracle array length of 1. Anyone can pay the SSTOREs to increase the
/// maximum length of the oracle array. New slots will be added when the array is fully populated.
/// Observations are overwritten when the full length of the oracle array is populated.
/// The most recent observation is available, independent of the length of the oracle array, by passing 0 to observe()
library Oracle {
    /// @notice Transforms a previous observation into a new observation, given the passage of time and the current tick and liquidity values
    /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
    /// @param last The specified observation to be transformed
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @param liquidity The total in-range liquidity at the time of the new observation
    /// @return Observation The newly populated observation
    function transform(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint128 boostedLiquidity
    ) internal pure returns (Observation memory) {
        uint32 delta = blockTimestamp - last.blockTimestamp;
        return
            Observation({
                blockTimestamp: blockTimestamp,
                tickCumulative: last.tickCumulative + int56(tick) * delta,
                secondsPerLiquidityCumulativeX128: last.secondsPerLiquidityCumulativeX128 +
                    ((uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)),
                secondsPerBoostedLiquidityPeriodX128: last.secondsPerBoostedLiquidityPeriodX128 +
                    ((uint160(delta) << 128) / (boostedLiquidity > 0 ? boostedLiquidity : 1)),
                initialized: true,
                boostedInRange: boostedLiquidity > 0 ? last.boostedInRange + delta : last.boostedInRange
            });
    }

    /// @notice Initialize the oracle array by writing the first slot. Called once for the lifecycle of the observations array
    /// @param self The stored oracle array
    /// @param time The time of the oracle initialization, via block.timestamp truncated to uint32
    /// @return cardinality The number of populated elements in the oracle array
    /// @return cardinalityNext The new length of the oracle array, independent of population
    function initialize(
        Observation[65535] storage self,
        uint32 time
    ) external returns (uint16 cardinality, uint16 cardinalityNext) {
        self[0] = Observation({
            blockTimestamp: time,
            tickCumulative: 0,
            secondsPerLiquidityCumulativeX128: 0,
            secondsPerBoostedLiquidityPeriodX128: 0,
            initialized: true,
            boostedInRange: 0
        });
        return (1, 1);
    }

    /// @notice Writes an oracle observation to the array
    /// @dev Writable at most once per block. Index represents the most recently written element. cardinality and index must be tracked publicly.
    /// If the index is at the end of the allowable array length (according to cardinality), and the next cardinality
    /// is greater than the current one, cardinality may be increased. This restriction is created to preserve ordering.
    /// @param self The stored oracle array
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @param liquidity The total in-range liquidity at the time of the new observation
    /// @param cardinality The number of populated elements in the oracle array
    /// @param cardinalityNext The new length of the oracle array, independent of population
    /// @return indexUpdated The new index of the most recently written element in the oracle array
    /// @return cardinalityUpdated The new cardinality of the oracle array
    function write(
        Observation[65535] storage self,
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint128 boostedLiquidity,
        uint16 cardinality,
        uint16 cardinalityNext
    ) external returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        Observation memory last = self[index];

        // early return if we've already written an observation this block
        if (last.blockTimestamp == blockTimestamp) return (index, cardinality);

        // if the conditions are right, we can bump the cardinality
        if (cardinalityNext > cardinality && index == (cardinality - 1)) {
            cardinalityUpdated = cardinalityNext;
        } else {
            cardinalityUpdated = cardinality;
        }

        indexUpdated = (index + 1) % cardinalityUpdated;
        self[indexUpdated] = transform(last, blockTimestamp, tick, liquidity, boostedLiquidity);
    }

    /// @notice Prepares the oracle array to store up to `next` observations
    /// @param self The stored oracle array
    /// @param current The current next cardinality of the oracle array
    /// @param next The proposed next cardinality which will be populated in the oracle array
    /// @return next The next cardinality which will be populated in the oracle array
    function grow(Observation[65535] storage self, uint16 current, uint16 next) external returns (uint16) {
        require(current > 0, 'I');
        // no-op if the passed next value isn't greater than the current next value
        if (next <= current) return current;
        // store in each slot to prevent fresh SSTOREs in swaps
        // this data will not be used because the initialized boolean is still false
        for (uint16 i = current; i < next; i++) self[i].blockTimestamp = 1;
        return next;
    }

    /// @notice comparator for 32-bit timestamps
    /// @dev safe for 0 or 1 overflows, a and b _must_ be chronologically before or equal to time
    /// @param time A timestamp truncated to 32 bits
    /// @param a A comparison timestamp from which to determine the relative position of `time`
    /// @param b From which to determine the relative position of `time`
    /// @return bool Whether `a` is chronologically <= `b`
    function lte(uint32 time, uint32 a, uint32 b) internal pure returns (bool) {
        // if there hasn't been overflow, no need to adjust
        if (a <= time && b <= time) return a <= b;

        uint256 aAdjusted = a > time ? a : a + 2 ** 32;
        uint256 bAdjusted = b > time ? b : b + 2 ** 32;

        return aAdjusted <= bAdjusted;
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a target, i.e. where [beforeOrAt, atOrAfter] is satisfied.
    /// The result may be the same observation, or adjacent observations.
    /// @dev The answer must be contained in the array, used when the target is located within the stored observation
    /// boundaries: older than the most recent observation and younger, or the same age as, the oldest observation
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved observation should be for
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation recorded before, or at, the target
    /// @return atOrAfter The observation recorded at, or after, the target
    function binarySearch(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        uint16 index,
        uint16 cardinality
    ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 l = (index + 1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % cardinality];

            // we've landed on an uninitialized tick, keep searching higher (more recently)
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);

            // check if we've found the answer!
            if (targetAtOrAfter && lte(time, target, atOrAfter.blockTimestamp)) break;

            if (!targetAtOrAfter) r = i - 1;
            else l = i + 1;
        }
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a given target, i.e. where [beforeOrAt, atOrAfter] is satisfied
    /// @dev Assumes there is at least 1 initialized observation.
    /// Used by observeSingle() to compute the counterfactual accumulator values as of a given block timestamp.
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved observation should be for
    /// @param tick The active tick at the time of the returned or simulated observation
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The total pool liquidity at the time of the call
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation which occurred at, or before, the given timestamp
    /// @return atOrAfter The observation which occurred at, or after, the given timestamp
    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint128 boostedLiquidity,
        uint16 cardinality
    ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        // optimistically set before to the newest observation
        beforeOrAt = self[index];

        // if the target is chronologically at or after the newest observation, we can early return
        if (lte(time, beforeOrAt.blockTimestamp, target)) {
            if (beforeOrAt.blockTimestamp == target) {
                // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                // otherwise, we need to transform
                return (beforeOrAt, transform(beforeOrAt, target, tick, liquidity, boostedLiquidity));
            }
        }

        // now, set before to the oldest observation
        beforeOrAt = self[(index + 1) % cardinality];
        if (!beforeOrAt.initialized) beforeOrAt = self[0];

        // ensure that the target is chronologically at or after the oldest observation
        require(lte(time, beforeOrAt.blockTimestamp, target), 'OLD');

        // if we've reached this point, we have to binary search
        return binarySearch(self, time, target, index, cardinality);
    }

    /// @dev Reverts if an observation at or before the desired observation timestamp does not exist.
    /// 0 may be passed as `secondsAgo' to return the current cumulative values.
    /// If called with a timestamp falling between two observations, returns the counterfactual accumulator values
    /// at exactly the timestamp between the two observations.
    /// @param self The stored oracle array
    /// @param time The current block timestamp
    /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an observation
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @param cardinality The number of populated elements in the oracle array
    /// @return tickCumulative The tick * time elapsed since the pool was first initialized, as of `secondsAgo`
    /// @return secondsPerLiquidityCumulativeX128 The time elapsed / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint128 boostedLiquidity,
        uint16 cardinality
    )
        public
        view
        returns (
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            uint160 periodSecondsPerBoostedLiquidityX128
        )
    {
        if (secondsAgo == 0) {
            Observation memory last = self[index];
            if (last.blockTimestamp != time) {
                last = transform(last, time, tick, liquidity, boostedLiquidity);
            }
            return (
                last.tickCumulative,
                last.secondsPerLiquidityCumulativeX128,
                last.secondsPerBoostedLiquidityPeriodX128
            );
        }

        uint32 target = time - secondsAgo;

        (Observation memory beforeOrAt, Observation memory atOrAfter) = getSurroundingObservations(
            self,
            time,
            target,
            tick,
            index,
            liquidity,
            boostedLiquidity,
            cardinality
        );

        if (target == beforeOrAt.blockTimestamp) {
            // we're at the left boundary
            return (
                beforeOrAt.tickCumulative,
                beforeOrAt.secondsPerLiquidityCumulativeX128,
                beforeOrAt.secondsPerBoostedLiquidityPeriodX128
            );
        } else if (target == atOrAfter.blockTimestamp) {
            // we're at the right boundary
            return (
                atOrAfter.tickCumulative,
                atOrAfter.secondsPerLiquidityCumulativeX128,
                atOrAfter.secondsPerBoostedLiquidityPeriodX128
            );
        } else {
            // we're in the middle
            uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
            uint32 targetDelta = target - beforeOrAt.blockTimestamp;
            return (
                beforeOrAt.tickCumulative +
                    ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / observationTimeDelta) *
                    targetDelta,
                beforeOrAt.secondsPerLiquidityCumulativeX128 +
                    uint160(
                        (uint256(
                            atOrAfter.secondsPerLiquidityCumulativeX128 - beforeOrAt.secondsPerLiquidityCumulativeX128
                        ) * targetDelta) / observationTimeDelta
                    ),
                beforeOrAt.secondsPerBoostedLiquidityPeriodX128 +
                    uint160(
                        (uint256(
                            atOrAfter.secondsPerBoostedLiquidityPeriodX128 -
                                beforeOrAt.secondsPerBoostedLiquidityPeriodX128
                        ) * targetDelta) / observationTimeDelta
                    )
            );
        }
    }

    /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
    /// @dev Reverts if `secondsAgos` > oldest observation
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an observation
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @param cardinality The number of populated elements in the oracle array
    /// @return tickCumulatives The tick * time elapsed since the pool was first initialized, as of each `secondsAgo`
    /// @return secondsPerLiquidityCumulativeX128s The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
    function observe(
        Observation[65535] storage self,
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint128 boostedLiquidity,
        uint16 cardinality
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s,
            uint160[] memory periodSecondsPerBoostedLiquidityX128s
        )
    {
        require(cardinality > 0, 'I');

        tickCumulatives = new int56[](secondsAgos.length);
        secondsPerLiquidityCumulativeX128s = new uint160[](secondsAgos.length);
        periodSecondsPerBoostedLiquidityX128s = new uint160[](secondsAgos.length);

        for (uint256 i = 0; i < secondsAgos.length; i++) {
            (
                tickCumulatives[i],
                secondsPerLiquidityCumulativeX128s[i],
                periodSecondsPerBoostedLiquidityX128s[i]
            ) = observeSingle(self, time, secondsAgos[i], tick, index, liquidity, boostedLiquidity, cardinality);
        }
    }

    function newPeriod(
        Observation[65535] storage self,
        uint16 index,
        uint256 period
    )
        external
        returns (
            uint160 secondsPerLiquidityCumulativeX128,
            uint160 secondsPerBoostedLiquidityCumulativeX128,
            uint32 boostedInRange
        )
    {
        Observation memory last = self[index];
        States.PoolStates storage states = States.getStorage();

        uint32 delta = uint32(period) * 1 weeks - last.blockTimestamp;

        secondsPerLiquidityCumulativeX128 =
            last.secondsPerLiquidityCumulativeX128 +
            ((uint160(delta) << 128) / (states.liquidity > 0 ? states.liquidity : 1));

        secondsPerBoostedLiquidityCumulativeX128 =
            last.secondsPerBoostedLiquidityPeriodX128 +
            ((uint160(delta) << 128) / (states.boostedLiquidity > 0 ? states.boostedLiquidity : 1));

        boostedInRange = states.boostedLiquidity > 0 ? last.boostedInRange + delta : last.boostedInRange;

        self[index] = Observation({
            blockTimestamp: uint32(period) * 1 weeks,
            tickCumulative: last.tickCumulative,
            secondsPerLiquidityCumulativeX128: secondsPerLiquidityCumulativeX128,
            secondsPerBoostedLiquidityPeriodX128: secondsPerBoostedLiquidityCumulativeX128,
            initialized: last.initialized,
            boostedInRange: 0
        });
    }

    struct SnapShot {
        int56 tickCumulativeLower;
        int56 tickCumulativeUpper;
        uint160 secondsPerLiquidityOutsideLowerX128;
        uint160 secondsPerLiquidityOutsideUpperX128;
        uint160 secondsPerBoostedLiquidityOutsideLowerX128;
        uint160 secondsPerBoostedLiquidityOutsideUpperX128;
        uint32 secondsOutsideLower;
        uint32 secondsOutsideUpper;
    }

    struct SnapshotCumulativesInsideCache {
        uint32 time;
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        uint160 secondsPerBoostedLiquidityCumulativeX128;
    }

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken. Boosted data is only valid if it's within the same period
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsPerBoostedLiquidityInsideX128 The snapshot of seconds per boosted liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint160 secondsPerBoostedLiquidityInsideX128,
            uint32 secondsInside
        )
    {
        States.PoolStates storage states = States.getStorage();

        TickInfo storage lower = states._ticks[tickLower];
        TickInfo storage upper = states._ticks[tickUpper];

        SnapShot memory snapshot;

        {
            uint256 period = States._blockTimestamp() / 1 weeks;
            bool initializedLower;
            (
                snapshot.tickCumulativeLower,
                snapshot.secondsPerLiquidityOutsideLowerX128,
                snapshot.secondsPerBoostedLiquidityOutsideLowerX128,
                snapshot.secondsOutsideLower,
                initializedLower
            ) = (
                lower.tickCumulativeOutside,
                lower.secondsPerLiquidityOutsideX128,
                uint160(lower.periodSecondsPerBoostedLiquidityOutsideX128[period]),
                lower.secondsOutside,
                lower.initialized
            );
            require(initializedLower);

            bool initializedUpper;
            (
                snapshot.tickCumulativeUpper,
                snapshot.secondsPerLiquidityOutsideUpperX128,
                snapshot.secondsPerBoostedLiquidityOutsideUpperX128,
                snapshot.secondsOutsideUpper,
                initializedUpper
            ) = (
                upper.tickCumulativeOutside,
                upper.secondsPerLiquidityOutsideX128,
                uint160(upper.periodSecondsPerBoostedLiquidityOutsideX128[period]),
                upper.secondsOutside,
                upper.initialized
            );
            require(initializedUpper);
        }

        Slot0 memory _slot0 = states.slot0;

        if (_slot0.tick < tickLower) {
            return (
                snapshot.tickCumulativeLower - snapshot.tickCumulativeUpper,
                snapshot.secondsPerLiquidityOutsideLowerX128 - snapshot.secondsPerLiquidityOutsideUpperX128,
                snapshot.secondsPerBoostedLiquidityOutsideLowerX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideUpperX128,
                snapshot.secondsOutsideLower - snapshot.secondsOutsideUpper
            );
        } else if (_slot0.tick < tickUpper) {
            SnapshotCumulativesInsideCache memory cache;
            cache.time = States._blockTimestamp();
            (
                cache.tickCumulative,
                cache.secondsPerLiquidityCumulativeX128,
                cache.secondsPerBoostedLiquidityCumulativeX128
            ) = observeSingle(
                states.observations,
                cache.time,
                0,
                _slot0.tick,
                _slot0.observationIndex,
                states.liquidity,
                states.boostedLiquidity,
                _slot0.observationCardinality
            );
            return (
                cache.tickCumulative - snapshot.tickCumulativeLower - snapshot.tickCumulativeUpper,
                cache.secondsPerLiquidityCumulativeX128 -
                    snapshot.secondsPerLiquidityOutsideLowerX128 -
                    snapshot.secondsPerLiquidityOutsideUpperX128,
                cache.secondsPerBoostedLiquidityCumulativeX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideLowerX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideUpperX128,
                cache.time - snapshot.secondsOutsideLower - snapshot.secondsOutsideUpper
            );
        } else {
            return (
                snapshot.tickCumulativeUpper - snapshot.tickCumulativeLower,
                snapshot.secondsPerLiquidityOutsideUpperX128 - snapshot.secondsPerLiquidityOutsideLowerX128,
                snapshot.secondsPerBoostedLiquidityOutsideUpperX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideLowerX128,
                snapshot.secondsOutsideUpper - snapshot.secondsOutsideLower
            );
        }
    }

    /// @notice Returns the seconds per liquidity and seconds inside a tick range for a period
    /// @dev This does not ensure the range is a valid range
    /// @param period The timestamp of the period
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsPerBoostedLiquidityInsideX128 The snapshot of seconds per boosted liquidity for the range
    function periodCumulativesInside(
        uint32 period,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint160 secondsPerLiquidityInsideX128, uint160 secondsPerBoostedLiquidityInsideX128) {
        States.PoolStates storage states = States.getStorage();

        TickInfo storage lower = states._ticks[tickLower];
        TickInfo storage upper = states._ticks[tickUpper];

        SnapShot memory snapshot;

        {
            int24 startTick = states.periods[period].startTick;
            uint256 previousPeriod = states.periods[period].previousPeriod;

            (snapshot.secondsPerLiquidityOutsideLowerX128, snapshot.secondsPerBoostedLiquidityOutsideLowerX128) = (
                uint160(lower.periodSecondsPerLiquidityOutsideX128[period]),
                uint160(lower.periodSecondsPerBoostedLiquidityOutsideX128[period])
            );
            if (tickLower <= startTick && snapshot.secondsPerLiquidityOutsideLowerX128 == 0) {
                snapshot.secondsPerLiquidityOutsideLowerX128 = states
                    .periods[previousPeriod]
                    .endSecondsPerLiquidityPeriodX128;
            }

            // separate conditions because liquidity and boosted liquidity can be different
            if (tickLower <= startTick && snapshot.secondsPerBoostedLiquidityOutsideLowerX128 == 0) {
                snapshot.secondsPerBoostedLiquidityOutsideLowerX128 = states
                    .periods[previousPeriod]
                    .endSecondsPerBoostedLiquidityPeriodX128;
            }

            (snapshot.secondsPerLiquidityOutsideUpperX128, snapshot.secondsPerBoostedLiquidityOutsideUpperX128) = (
                uint160(upper.periodSecondsPerLiquidityOutsideX128[period]),
                uint160(upper.periodSecondsPerBoostedLiquidityOutsideX128[period])
            );
            if (tickUpper <= startTick && snapshot.secondsPerLiquidityOutsideUpperX128 == 0) {
                snapshot.secondsPerLiquidityOutsideUpperX128 = states
                    .periods[previousPeriod]
                    .endSecondsPerLiquidityPeriodX128;
            }

            // separate conditions because liquidity and boosted liquidity can be different
            if (tickUpper <= startTick && snapshot.secondsPerBoostedLiquidityOutsideUpperX128 == 0) {
                snapshot.secondsPerBoostedLiquidityOutsideUpperX128 = states
                    .periods[previousPeriod]
                    .endSecondsPerBoostedLiquidityPeriodX128;
            }
        }

        int24 lastTick;
        uint256 currentPeriod = states.lastPeriod;
        {
            // if period is already finalized, use period's last tick, if not, use current tick
            if (currentPeriod > period) {
                lastTick = states.periods[period].lastTick;
            } else {
                lastTick = states.slot0.tick;
            }
        }

        if (lastTick < tickLower) {
            return (
                snapshot.secondsPerLiquidityOutsideLowerX128 - snapshot.secondsPerLiquidityOutsideUpperX128,
                snapshot.secondsPerBoostedLiquidityOutsideLowerX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideUpperX128
            );
        } else if (lastTick < tickUpper) {
            SnapshotCumulativesInsideCache memory cache;
            // if period's on-going, observeSingle, if finalized, use endSecondsPerLiquidityPeriodX128
            if (currentPeriod <= period) {
                cache.time = States._blockTimestamp();
                // limit to the end of period
                if (cache.time > currentPeriod * 1 weeks + 1 weeks) {
                    cache.time = uint32(currentPeriod * 1 weeks + 1 weeks);
                }

                Slot0 memory _slot0 = states.slot0;

                (
                    ,
                    cache.secondsPerLiquidityCumulativeX128,
                    cache.secondsPerBoostedLiquidityCumulativeX128
                ) = observeSingle(
                    states.observations,
                    cache.time,
                    0,
                    _slot0.tick,
                    _slot0.observationIndex,
                    states.liquidity,
                    states.boostedLiquidity,
                    _slot0.observationCardinality
                );
            } else {
                cache.secondsPerLiquidityCumulativeX128 = states.periods[period].endSecondsPerLiquidityPeriodX128;
                cache.secondsPerBoostedLiquidityCumulativeX128 = states
                    .periods[period]
                    .endSecondsPerBoostedLiquidityPeriodX128;
            }

            return (
                cache.secondsPerLiquidityCumulativeX128 -
                    snapshot.secondsPerLiquidityOutsideLowerX128 -
                    snapshot.secondsPerLiquidityOutsideUpperX128,
                cache.secondsPerBoostedLiquidityCumulativeX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideLowerX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideUpperX128
            );
        } else {
            return (
                snapshot.secondsPerLiquidityOutsideUpperX128 - snapshot.secondsPerLiquidityOutsideLowerX128,
                snapshot.secondsPerBoostedLiquidityOutsideUpperX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideLowerX128
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        require((z = uint128(y)) == y);
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2 ** 255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // the most-recently updated index of the observations array
    uint16 observationIndex;
    // the current maximum number of observations that are being stored
    uint16 observationCardinality;
    // the next maximum number of observations to store, triggered in observations.write
    uint16 observationCardinalityNext;
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
    uint8 feeProtocol;
    // whether the pool is locked
    bool unlocked;
}

struct Observation {
    // the block timestamp of the observation
    uint32 blockTimestamp;
    // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
    int56 tickCumulative;
    // the seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized
    uint160 secondsPerLiquidityCumulativeX128;
    // whether or not the observation is initialized
    bool initialized;
    // see secondsPerLiquidityCumulativeX128 but with boost, only valid if timestamp < new period
    // recorded at the end to not breakup struct slot
    uint160 secondsPerBoostedLiquidityPeriodX128;
    // the seconds boosted positions were in range in this period
    uint32 boostedInRange;
}

// info stored for each user's position
struct PositionInfo {
    // the amount of liquidity owned by this position
    uint128 liquidity;
    // fee growth per unit of liquidity as of the last update to liquidity or fees owed
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    // the fees owed to the position owner in token0/token1
    uint128 tokensOwed0;
    uint128 tokensOwed1;
    uint256 attachedVeRamId;
}

struct PeriodBoostInfo {
    // the total amount of boost this period has
    uint128 totalBoostAmount;
    // the total amount of veRam attached to this period
    int128 totalVeRamAmount;
    // individual positions' boost info for this period
    mapping(bytes32 => BoostInfo) positions;
}

struct BoostInfo {
    // the amount of boost this position has for this period
    uint128 boostAmount;
    // the amount of veRam attached to this position for this period
    int128 veRamAmount;
    // used to account for changes in the boostAmount and veRam locked during the period
    int256 boostedSecondsDebtX96;
    // used to account for changes in the deposit amount
    int256 secondsDebtX96;
}

// info stored for each initialized individual tick
struct TickInfo {
    // the total position liquidity that references this tick
    uint128 liquidityGross;
    // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
    int128 liquidityNet;
    // the total position boosted liquidity that references this tick
    uint128 cleanUnusedSlot;
    // clean unused slot
    int128 cleanUnusedSlot2;
    // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint256 feeGrowthOutside0X128;
    uint256 feeGrowthOutside1X128;
    // the cumulative tick value on the other side of the tick
    int56 tickCumulativeOutside;
    // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint160 secondsPerLiquidityOutsideX128;
    // the seconds spent on the other side of the tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint32 secondsOutside;
    // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
    // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
    bool initialized;
    // secondsPerLiquidityOutsideX128 separated into periods, placed here to preserve struct slots
    mapping(uint256 => uint256) periodSecondsPerLiquidityOutsideX128;
    // see secondsPerLiquidityOutsideX128, for boosted liquidity
    mapping(uint256 => uint256) periodSecondsPerBoostedLiquidityOutsideX128;
    // the total position boosted liquidity that references this tick
    mapping(uint256 => uint128) boostedLiquidityGross;
    // period amount of net boosted liquidity added (subtracted) when tick is crossed from left to right (right to left),
    mapping(uint256 => int128) boostedLiquidityNet;
}

// info stored for each period
struct PeriodInfo {
    uint32 previousPeriod;
    int24 startTick;
    int24 lastTick;
    uint160 endSecondsPerLiquidityPeriodX128;
    uint160 endSecondsPerBoostedLiquidityPeriodX128;
    uint32 boostedInRange;
}

// accumulated protocol fees in token0/token1 units
struct ProtocolFees {
    uint128 token0;
    uint128 token1;
}

// Position period and liquidity
struct PositionCheckpoint {
    uint256 period;
    uint256 liquidity;
}

library States {
    bytes32 public constant STATES_SLOT = keccak256('states.storage');

    struct PoolStates {
        address factory;
        address nfpManager;
        address veRam;
        address voter;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
        uint128 maxLiquidityPerTick;
        Slot0 slot0;
        mapping(uint256 => PeriodInfo) periods;
        uint256 lastPeriod;
        uint256 feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1X128;
        ProtocolFees protocolFees;
        uint128 liquidity;
        uint128 boostedLiquidity;
        mapping(int24 => TickInfo) _ticks;
        mapping(int16 => uint256) tickBitmap;
        mapping(bytes32 => PositionInfo) positions;
        mapping(uint256 => PeriodBoostInfo) boostInfos;
        mapping(bytes32 => uint256) cleanUnusedSlot;
        Observation[65535] observations;
        mapping(bytes32 => PositionCheckpoint[]) positionCheckpoints;
    }

    // Return state storage struct for reading and writing
    function getStorage() internal pure returns (PoolStates storage storageStruct) {
        bytes32 position = STATES_SLOT;
        assembly {
            storageStruct.slot := position
        }
    }

    /// @dev Returns the block timestamp truncated to 32 bits, i.e. mod 2**32. This method is overridden in tests.
    function _blockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;
pragma abicoder v2;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './TickMath.sol';
import './LiquidityMath.sol';
import './States.sol';

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations
library Tick {
    using LowGasSafeMath for int256;
    using SafeCast for int256;

    /// @notice Derives max liquidity per tick from given tick spacing
    /// @dev Executed within the pool constructor
    /// @param tickSpacing The amount of required tick separation, realized in multiples of `tickSpacing`
    ///     e.g., a tickSpacing of 3 requires ticks to be initialized every 3rd tick i.e., ..., -6, -3, 0, 3, 6, ...
    /// @return The max liquidity per tick
    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) external pure returns (uint128) {
        int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
        uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
        return type(uint128).max / numTicks;
    }

    /// @notice Retrieves fee growth data
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @param tickCurrent The current tick
    /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @return feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @return feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function getFeeGrowthInside(
        mapping(int24 => TickInfo) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        TickInfo storage lower = self[tickLower];
        TickInfo storage upper = self[tickUpper];

        // calculate fee growth below
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (tickCurrent >= tickLower) {
            feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
        } else {
            feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
        }

        // calculate fee growth above
        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (tickCurrent < tickUpper) {
            feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
        } else {
            feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
        }

        feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
    }

    /// @notice Retrieves fee growth data
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @param tickCurrent The current tick
    /// @param endSecondsPerBoostedLiquidityPeriodX128 The seconds in range, per unit of liquidity
    /// @param period The period's timestamp
    /// @return secondsInsidePerBoostedLiquidityX128 The seconds per unit of liquidity, inside the position's tick boundaries
    function getSecondsInsidePerBoostedLiquidity(
        mapping(int24 => TickInfo) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 endSecondsPerBoostedLiquidityPeriodX128,
        uint256 period
    ) external view returns (uint256 secondsInsidePerBoostedLiquidityX128) {
        TickInfo storage lower = self[tickLower];
        TickInfo storage upper = self[tickUpper];

        // calculate secondInside growth below
        uint256 secondsInsidePerBoostedLiquidityBelowX128;
        if (tickCurrent >= tickLower) {
            secondsInsidePerBoostedLiquidityBelowX128 = lower.periodSecondsPerBoostedLiquidityOutsideX128[period];
        } else {
            secondsInsidePerBoostedLiquidityBelowX128 =
                endSecondsPerBoostedLiquidityPeriodX128 -
                lower.periodSecondsPerBoostedLiquidityOutsideX128[period];
        }

        // calculate secondsInside growth above
        uint256 secondsInsidePerBoostedLiquidityAboveX128;
        if (tickCurrent < tickUpper) {
            secondsInsidePerBoostedLiquidityAboveX128 = upper.periodSecondsPerBoostedLiquidityOutsideX128[period];
        } else {
            secondsInsidePerBoostedLiquidityAboveX128 =
                endSecondsPerBoostedLiquidityPeriodX128 -
                upper.periodSecondsPerBoostedLiquidityOutsideX128[period];
        }

        secondsInsidePerBoostedLiquidityX128 =
            endSecondsPerBoostedLiquidityPeriodX128 -
            secondsInsidePerBoostedLiquidityBelowX128 -
            secondsInsidePerBoostedLiquidityAboveX128;
    }

    struct UpdateTickParams {
        // the tick that will be updated
        int24 tick;
        // the current tick
        int24 tickCurrent;
        // a new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
        int128 liquidityDelta;
        // a new amount of boosted liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
        int128 boostedLiquidityDelta;
        // the all-time global fee growth, per unit of liquidity, in token0
        uint256 feeGrowthGlobal0X128;
        // the all-time global fee growth, per unit of liquidity, in token1
        uint256 feeGrowthGlobal1X128;
        // The all-time seconds per max(1, liquidity) of the pool
        uint160 secondsPerLiquidityCumulativeX128;
        // The period seconds per max(1, boostedLiquidity) of the pool
        uint160 secondsPerBoostedLiquidityPeriodX128;
        // the tick * time elapsed since the pool was first initialized
        int56 tickCumulative;
        // the current block timestamp cast to a uint32
        uint32 time;
        // true for updating a position's upper tick, or false for updating a position's lower tick
        bool upper;
        // the maximum liquidity allocation for a single tick
        uint128 maxLiquidity;
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param params the tick details and changes
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
    function update(
        mapping(int24 => TickInfo) storage self,
        UpdateTickParams memory params
    ) internal returns (bool flipped) {
        TickInfo storage info = self[params.tick];

        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(liquidityGrossBefore, params.liquidityDelta);

        require(liquidityGrossAfter <= params.maxLiquidity, 'LO');

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (liquidityGrossBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (params.tick <= params.tickCurrent) {
                uint256 period = params.time / 1 weeks;
                info.feeGrowthOutside0X128 = params.feeGrowthGlobal0X128;
                info.feeGrowthOutside1X128 = params.feeGrowthGlobal1X128;
                info.secondsPerLiquidityOutsideX128 = params.secondsPerLiquidityCumulativeX128;
                info.periodSecondsPerLiquidityOutsideX128[period] = params.secondsPerLiquidityCumulativeX128;
                info.periodSecondsPerBoostedLiquidityOutsideX128[period] = params.secondsPerBoostedLiquidityPeriodX128;
                info.tickCumulativeOutside = params.tickCumulative;
                info.secondsOutside = params.time;
            }
            info.initialized = true;
        }

        info.liquidityGross = liquidityGrossAfter;
        info.boostedLiquidityGross[params.time / 1 weeks] = LiquidityMath.addDelta(
            info.boostedLiquidityGross[params.time / 1 weeks],
            params.boostedLiquidityDelta
        );

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        info.liquidityNet = params.upper
            ? int256(info.liquidityNet).sub(params.liquidityDelta).toInt128()
            : int256(info.liquidityNet).add(params.liquidityDelta).toInt128();

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        info.boostedLiquidityNet[params.time / 1 weeks] = params.upper
            ? int256(info.boostedLiquidityNet[params.time / 1 weeks]).sub(params.boostedLiquidityDelta).toInt128()
            : int256(info.boostedLiquidityNet[params.time / 1 weeks]).add(params.boostedLiquidityDelta).toInt128();
    }

    /// @notice Clears tick data
    /// @param self The mapping containing all initialized tick information for initialized ticks
    /// @param tick The tick that will be cleared
    function clear(mapping(int24 => TickInfo) storage self, int24 tick) internal {
        delete self[tick];
    }

    struct CrossParams {
        // The destination tick of the transition
        int24 tick;
        // The all-time global fee growth, per unit of liquidity, in token0
        uint256 feeGrowthGlobal0X128;
        // The all-time global fee growth, per unit of liquidity, in token1
        uint256 feeGrowthGlobal1X128;
        // The current seconds per liquidity
        uint160 secondsPerLiquidityCumulativeX128;
        // The current seconds per boosted liquidity
        uint160 secondsPerBoostedLiquidityCumulativeX128;
        // The previous period end's seconds per liquidity
        uint256 endSecondsPerLiquidityPeriodX128;
        // The previous period end's seconds per boosted liquidity
        uint256 endSecondsPerBoostedLiquidityPeriodX128;
        // The starting tick of the period
        int24 periodStartTick;
        // The tick * time elapsed since the pool was first initialized
        int56 tickCumulative;
        // The current block.timestamp
        uint32 time;
    }

    /// @notice Transitions to next tick as needed by price movement
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param params Structured cross params
    /// @return liquidityNet The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    /// @return boostedLiquidityNet The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    function cross(
        mapping(int24 => TickInfo) storage self,
        CrossParams calldata params
    ) external returns (int128 liquidityNet, int128 boostedLiquidityNet) {
        TickInfo storage info = self[params.tick];
        uint256 period = params.time / 1 weeks;

        info.feeGrowthOutside0X128 = params.feeGrowthGlobal0X128 - info.feeGrowthOutside0X128;
        info.feeGrowthOutside1X128 = params.feeGrowthGlobal1X128 - info.feeGrowthOutside1X128;
        info.secondsPerLiquidityOutsideX128 =
            params.secondsPerLiquidityCumulativeX128 -
            info.secondsPerLiquidityOutsideX128;

        {
            uint256 periodSecondsPerLiquidityOutsideX128;
            uint256 periodSecondsPerLiquidityOutsideBeforeX128 = info.periodSecondsPerLiquidityOutsideX128[period];
            if (params.tick < params.periodStartTick && periodSecondsPerLiquidityOutsideBeforeX128 == 0) {
                periodSecondsPerLiquidityOutsideX128 =
                    params.secondsPerLiquidityCumulativeX128 -
                    periodSecondsPerLiquidityOutsideBeforeX128 -
                    params.endSecondsPerLiquidityPeriodX128;
            } else {
                periodSecondsPerLiquidityOutsideX128 =
                    params.secondsPerLiquidityCumulativeX128 -
                    periodSecondsPerLiquidityOutsideBeforeX128;
            }
            info.periodSecondsPerLiquidityOutsideX128[period] = periodSecondsPerLiquidityOutsideX128;
        }
        {
            uint256 periodSecondsPerBoostedLiquidityOutsideX128;
            uint256 periodSecondsPerBoostedLiquidityOutsideBeforeX128 = info
                .periodSecondsPerBoostedLiquidityOutsideX128[period];
            if (params.tick < params.periodStartTick && periodSecondsPerBoostedLiquidityOutsideBeforeX128 == 0) {
                periodSecondsPerBoostedLiquidityOutsideX128 =
                    params.secondsPerBoostedLiquidityCumulativeX128 -
                    periodSecondsPerBoostedLiquidityOutsideBeforeX128 -
                    params.endSecondsPerBoostedLiquidityPeriodX128;
            } else {
                periodSecondsPerBoostedLiquidityOutsideX128 =
                    params.secondsPerBoostedLiquidityCumulativeX128 -
                    periodSecondsPerBoostedLiquidityOutsideBeforeX128;
            }

            info.periodSecondsPerBoostedLiquidityOutsideX128[period] = periodSecondsPerBoostedLiquidityOutsideX128;
        }
        info.tickCumulativeOutside = params.tickCumulative - info.tickCumulativeOutside;
        info.secondsOutside = params.time - info.secondsOutside;
        liquidityNet = info.liquidityNet;
        boostedLiquidityNet = info.boostedLiquidityNet[period];
    }

    /// @dev Common checks for valid tick inputs.
    function checkTicks(int24 tickLower, int24 tickUpper) external pure {
        require(tickLower < tickUpper, 'TLU');
        require(tickLower >= TickMath.MIN_TICK, 'TLM');
        require(tickUpper <= TickMath.MAX_TICK, 'TUM');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}