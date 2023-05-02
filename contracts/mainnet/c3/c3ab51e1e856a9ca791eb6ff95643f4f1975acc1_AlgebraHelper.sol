/**
 *Submitted for verification at Arbiscan on 2023-05-02
*/

pragma solidity 0.8.15;

contract AlgebraHelper {
    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;

    uint16 internal constant _BASE_FEE = 100;
    int24 internal constant _TICK_SPACING = 60;

    struct Tick {
        uint128 liquidityGross;
        int128 liquidityNet;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        int56 tickCumulativeOutside;
        uint160 secondsPerLiquidityOutsideX128;
        uint32 secondsOutside;
        int24 index; // tick index
    }

    function getTicks(IAlgebra pool, int24 tickRange)
        external
        view
        returns (bytes[] memory ticks)
    {
        (, int24 tick, , , , , ) = pool.globalState();

        int24 fromTick = tick - (_TICK_SPACING * tickRange);
        int24 toTick = tick + (_TICK_SPACING * tickRange);
        if (fromTick < _MIN_TICK) {
            fromTick = _MIN_TICK;
        }
        if (toTick > _MAX_TICK) {
            toTick = _MAX_TICK;
        }

        int24[] memory initTicks = new int24[](
            uint256(int256((toTick - fromTick + 1) / _TICK_SPACING))
        );

        uint256 counter = 0;
        for (
            int24 tickNum = ((fromTick / _TICK_SPACING) * _TICK_SPACING);
            tickNum <= ((toTick / _TICK_SPACING) * _TICK_SPACING);
            tickNum += (256 * _TICK_SPACING)
        ) {
            int16 pos = int16((tickNum / _TICK_SPACING) >> 8);
            uint256 bm = pool.tickTable(pos);

            while (bm != 0) {
                uint8 bit = _mostSignificantBit(bm);
                bm ^= 1 << bit;
                int24 extractedTick = (int24(pos) * 256 + int24(uint24(bit))) *
                    _TICK_SPACING;
                if (extractedTick >= fromTick && extractedTick <= toTick) {
                    initTicks[counter++] = extractedTick;
                }
            }
        }

        ticks = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            (
                uint128 liquidityTotal,
                int128 liquidityDelta,
                uint256 outerFeeGrowth0Token,
                uint256 outerFeeGrowth1Token
                ,
                ,
                ,
                ,
                ,

            ) = pool.ticks(initTicks[i]);

            ticks[i] = abi.encodePacked(
                liquidityTotal,
                liquidityDelta,
                outerFeeGrowth0Token,
                outerFeeGrowth1Token,
                // outerTickCumulative,
                // outerSecondsPerLiquidity,
                // outerSecondsSpent,
                initTicks[i]
            );
        }
    }

    function _mostSignificantBit(uint256 x) private pure returns (uint8 r) {
        require(x > 0, "x is 0");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IAlgebra {
    /**
     * @notice The globalState structure in the pool stores many values but requires only one slot
     * and is exposed as a single method to save gas when accessed externally.
     * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value;
     * Returns tick The current tick of the pool, i.e. according to the last tick transition that was run;
     * Returns This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
     * boundary;
     * Returns fee The last pool fee value in hundredths of a bip, i.e. 1e-6;
     * Returns timepointIndex The index of the last written timepoint;
     * Returns communityFeeToken0 The community fee percentage of the swap fee in thousandths (1e-3) for token0;
     * Returns communityFeeToken1 The community fee percentage of the swap fee in thousandths (1e-3) for token1;
     * Returns unlocked Whether the pool is currently locked to reentrancy;
     */
    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            uint16 feeZtO,
            uint16 feeOtZ,
            uint16 timepointIndex,
            uint8 communityFee,
            bool unlocked
        );

    /**
     * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
     * @dev This value can overflow the uint256
     */
    function totalFeeGrowth0Token() external view returns (uint256);

    /**
     * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
     * @dev This value can overflow the uint256
     */
    function totalFeeGrowth1Token() external view returns (uint256);

    /**
     * @notice The currently in range liquidity available to the pool
     * @dev This value has no relationship to the total liquidity across all ticks.
     * Returned value cannot exceed type(uint128).max
     */
    function liquidity() external view returns (uint128);

    /**
     * @notice Look up information about a specific tick in the pool
     * @dev This is a public structure, so the `return` natspec tags are omitted.
     * @param tick The tick to look up
     * @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
     * tick upper
     * @return liquidityDelta how much liquidity changes when the pool price crosses the tick;
     * Returns outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0;
     * Returns outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1;
     * Returns outerTickCumulative the cumulative tick value on the other side of the tick from the current tick;
     * Returns outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick;
     * Returns outerSecondsSpent the seconds spent on the other side of the tick from the current tick;
     * Returns initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0
     * otherwise equal to false. Outside values can only be used if the tick is initialized.
     * In addition, these values are only relative and must be used only in comparison to previous snapshots for
     * a specific position.
     */
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityTotal,
            int128 liquidityDelta,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token,
            int24 prevTick,
            int24 nextTick,
            uint160 outerSecondsPerLiquidity,
            uint32 outerSecondsSpent,
            bool hasLimitOrders
        );

    /** @notice Returns 256 packed tick initialized boolean values. See TickTable for more information */
    function tickTable(int16 wordPosition) external view returns (uint256);

    function positions(bytes32 key)
        external
        view
        returns (
            uint256 liquidity,
            uint256 innerFeeGrowth0Token,
            uint256 innerFeeGrowth1Token,
            uint128 fees0,
            uint128 fees1
        );
}