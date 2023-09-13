// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values

interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

interface IZumiPool {
    function points(int24 tick) external view returns (uint256, int128, uint256, uint256, bool);

    function pointDelta() external view returns (int24);

    function orderOrEndpoint(int24 tick) external view returns (int24);

    function limitOrderData(int24 point)
        external
        view
        returns (
            uint128 sellingX,
            uint128 earnY,
            uint256 accEarnY,
            uint256 legacyAccEarnY,
            uint128 legacyEarnY,
            uint128 sellingY,
            uint128 earnX,
            uint128 legacyEarnX,
            uint256 accEarnX,
            uint256 legacyAccEarnX
        );

    function pointBitmap(int16 tick) external view returns (uint256);

    function factory() external view returns (address);
}

interface IHorizonPool {
    function tickDistance() external view returns (int24);

    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside,
            uint128 secondsPerLiquidityOutside
        );

    function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

    function getPoolState()
        external
        view
        returns (uint160 sqrtP, int24 currentTick, int24 nearestCurrentTick, bool locked);
}

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces

interface IAlgebraPool {
    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            int24 prevInitializedTick,
            uint16 fee,
            uint16 timepointIndex,
            uint8 communityFee,
            bool unlocked
        );

    function tickSpacing() external view returns (int24);

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

    function tickTable(int16 wordPosition) external view returns (uint256);
    function prevInitializedTick() external view returns (int24);
}

interface IAlgebraPoolV1_9 {
    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            int24 prevInitializedTick,
            uint16 fee,
            uint16 timepointIndex,
            uint8 communityFee,
            bool unlocked
        );

    function tickSpacing() external view returns (int24);
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityTotal,
            int128 liquidityDelta,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token,
            int56 outerTickCumulative,
            uint160 outerSecondsPerLiquidity,
            uint32 outerSecondsSpent,
            bool initialized
        );
    function tickTable(int16 wordPosition) external view returns (uint256);
}

interface IUniswapV3Pool is IUniswapV3PoolImmutables, IUniswapV3PoolState {}

/// @title DexNativeRouter
/// @notice Entrance of trading native token in web3-dex
contract QueryData {
    int24 internal constant MIN_TICK_MINUS_1 = -887272 - 1;
    int24 internal constant MAX_TICK_PLUS_1 = 887272 + 1;

    struct SuperVar {
        int24 tickSpacing;
        int24 currTick;
        int24 right;
        int24 left;
        int24 leftMost;
        int24 rightMost;
        uint256 initPoint;
        uint256 initPoint2;
    }

    function queryUniv3TicksSuperCompact(address pool, uint256 len) public view returns (bytes memory) {
        SuperVar memory tmp;
        tmp.tickSpacing = IUniswapV3Pool(pool).tickSpacing();
        // fix-bug: pancake pool's slot returns different types of params than uniV3, which will cause problem
        {
            (, bytes memory slot0) = pool.staticcall(abi.encodeWithSignature("slot0()"));
            int24 currTick;
            assembly {
                currTick := mload(add(slot0, 64))
            }
            tmp.currTick = currTick;
        }

        tmp.right = tmp.currTick / tmp.tickSpacing / int24(256);
        tmp.leftMost = -887272 / tmp.tickSpacing / int24(256) - 2;
        tmp.rightMost = 887272 / tmp.tickSpacing / int24(256) + 1;

        if (tmp.currTick < 0) {
            tmp.initPoint = 256 - ((uint256(int256(-tmp.currTick)) / uint256(int256(tmp.tickSpacing))) % 256);
        } else {
            tmp.initPoint = (uint256(int256(tmp.currTick)) / uint256(int256(tmp.tickSpacing))) % 256;
        }
        tmp.initPoint2 = tmp.initPoint;

        if (tmp.currTick < 0) tmp.right--;

        bytes memory tickInfo;

        tmp.left = tmp.right;

        uint256 index = 0;

        while (index < len / 2 && tmp.right < tmp.rightMost) {
            uint256 res = IUniswapV3Pool(pool).tickBitmap(int16(tmp.right));
            if (res > 0) {
                res = res >> tmp.initPoint;
                for (uint256 i = tmp.initPoint; i < 256 && index < len / 2; i++) {
                    uint256 isInit = res & 0x01;
                    if (isInit > 0) {
                        int256 tick = int256((256 * tmp.right + int256(i)) * tmp.tickSpacing);
                        (, int128 liquidityNet,,,,,,) = IUniswapV3Pool(pool).ticks(int24(int256(tick)));

                        int256 data = int256(uint256(int256(tick)) << 128)
                            + (int256(liquidityNet) & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
                        tickInfo = bytes.concat(tickInfo, bytes32(uint256(data)));

                        index++;
                    }

                    res = res >> 1;
                }
            }
            tmp.initPoint = 0;
            tmp.right++;
        }
        bool isInitPoint = true;
        while (index < len && tmp.left > tmp.leftMost) {
            uint256 res = IUniswapV3Pool(pool).tickBitmap(int16(tmp.left));
            if (res > 0) {
                res = isInitPoint ? res << tmp.initPoint2 : res;
                for (uint256 i = tmp.initPoint2; i >= 0 && index < len; i--) {
                    uint256 isInit = res & 0x8000000000000000000000000000000000000000000000000000000000000000;
                    if (isInit > 0) {
                        int256 tick = int256((256 * tmp.left + int256(i)) * tmp.tickSpacing);
                        (, int128 liquidityNet,,,,,,) = IUniswapV3Pool(pool).ticks(int24(int256(tick)));

                        int256 data = int256(uint256(int256(tick)) << 128)
                            + (int256(liquidityNet) & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
                        tickInfo = bytes.concat(tickInfo, bytes32(uint256(data)));

                        index++;
                    }

                    res = res << 1;
                    if (i == 0) break;
                }
            }
            isInitPoint = false;
            tmp.initPoint2 = 255;

            tmp.left--;
        }
        return tickInfo;
    }

    function queryAlgebraTicksSuperCompact(address pool, uint256 len) public view returns (bytes memory) {
        SuperVar memory tmp;

        (, tmp.currTick,,,,,) = IAlgebraPoolV1_9(pool).globalState();
        tmp.right = tmp.currTick / int24(256);
        tmp.leftMost = -887272 / int24(256) - 2;
        tmp.rightMost = 887272 / int24(256) + 1;

        if (tmp.currTick < 0) {
            tmp.initPoint = 256 - (uint256(int256(-tmp.currTick)) % 256);
        } else {
            tmp.initPoint = uint256(int256(tmp.currTick)) % 256;
        }
        tmp.initPoint2 = tmp.initPoint;

        if (tmp.currTick < 0) tmp.right--;

        bytes memory tickInfo;

        tmp.left = tmp.right;

        uint256 index = 0;

        while (index < len / 2 && tmp.right < tmp.rightMost) {
            uint256 res = IAlgebraPoolV1_9(pool).tickTable(int16(tmp.right));
            if (res > 0) {
                res = res >> tmp.initPoint;
                for (uint256 i = tmp.initPoint; i < 256 && index < len / 2; i++) {
                    uint256 isInit = res & 0x01;
                    if (isInit > 0) {
                        int256 tick = int256((256 * tmp.right + int256(i)));
                        (, int128 liquidityNet,,,,,,) = IAlgebraPoolV1_9(pool).ticks(int24(int256(tick)));

                        int256 data = int256(uint256(int256(tick)) << 128)
                            + (int256(liquidityNet) & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
                        tickInfo = bytes.concat(tickInfo, bytes32(uint256(data)));

                        index++;
                    }

                    res = res >> 1;
                }
            }
            tmp.initPoint = 0;
            tmp.right++;
        }
        bool isInitPoint = true;
        while (index < len && tmp.left > tmp.leftMost) {
            uint256 res = IAlgebraPoolV1_9(pool).tickTable(int16(tmp.left));
            if (res > 0) {
                res = isInitPoint ? res << tmp.initPoint2 : res;
                for (uint256 i = tmp.initPoint2; i >= 0 && index < len; i--) {
                    uint256 isInit = res & 0x8000000000000000000000000000000000000000000000000000000000000000;
                    if (isInit > 0) {
                        int256 tick = int256((256 * tmp.left + int256(i)));
                        (, int128 liquidityNet,,,,,,) = IAlgebraPoolV1_9(pool).ticks(int24(int256(tick)));

                        int256 data = int256(uint256(int256(tick)) << 128)
                            + (int256(liquidityNet) & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
                        tickInfo = bytes.concat(tickInfo, bytes32(uint256(data)));

                        index++;
                    }

                    res = res << 1;
                    if (i == 0) break;
                }
            }
            isInitPoint = false;
            tmp.initPoint2 = 255;

            tmp.left--;
        }
        return tickInfo;
    }

    function queryHorizonTicksSuperCompact(address pool, uint256 iteration) public view returns (bytes memory) {
        (,, int24 currTick,) = IHorizonPool(pool).getPoolState();
        int24 currTick2 = currTick;
        uint256 threshold = iteration / 2;

        // travel from left to right
        bytes memory tickInfo;

        while (currTick < MAX_TICK_PLUS_1 && iteration > threshold) {
            (, int128 liquidityNet,,) = IHorizonPool(pool).ticks(currTick);

            int256 data = int256(uint256(int256(currTick)) << 128)
                + (int256(liquidityNet) & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
            tickInfo = bytes.concat(tickInfo, bytes32(uint256(data)));
            (, int24 nextTick) = IHorizonPool(pool).initializedTicks(currTick);
            if (currTick == nextTick) {
                break;
            }
            currTick = nextTick;
            iteration--;
        }

        while (currTick2 > MIN_TICK_MINUS_1 && iteration > 0) {
            (, int128 liquidityNet,,) = IHorizonPool(pool).ticks(currTick2);
            int256 data = int256(uint256(int256(currTick2)) << 128)
                + (int256(liquidityNet) & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
            tickInfo = bytes.concat(tickInfo, bytes32(uint256(data)));
            (int24 prevTick,) = IHorizonPool(pool).initializedTicks(currTick2);
            if (prevTick == currTick2) {
                break;
            }
            currTick2 = prevTick;
            iteration--;
        }

        return tickInfo;
    }

    function queryAlgebraTicksSuperCompact2(address pool, uint256 iteration) public view returns (bytes memory) {
        int24 currTick;
        {
            (bool s, bytes memory res) = pool.staticcall(abi.encodeWithSignature("prevInitializedTick()"));
            if (s) {
                currTick = abi.decode(res, (int24));
            } else {
                (s, res) = pool.staticcall(abi.encodeWithSignature("globalState()"));
                if (s) {
                    assembly {
                        currTick := mload(add(res, 96))
                    }
                }
            }
        }

        int24 currTick2 = currTick;
        uint256 threshold = iteration / 2;
        // travel from left to right
        bytes memory tickInfo;

        while (currTick < MAX_TICK_PLUS_1 && iteration > threshold) {
            (, int128 liquidityNet,,, int24 prevTick, int24 nextTick,,,) = IAlgebraPool(pool).ticks(currTick);

            int256 data = int256(uint256(int256(currTick)) << 128)
                + (int256(liquidityNet) & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
            tickInfo = bytes.concat(tickInfo, bytes32(uint256(data)));

            if (currTick == nextTick) {
                break;
            }
            currTick = nextTick;
            iteration--;
        }

        while (currTick2 > MIN_TICK_MINUS_1 && iteration > 0) {
            (, int128 liquidityNet,,, int24 prevTick, int24 nextTick,,,) = IAlgebraPool(pool).ticks(currTick2);

            int256 data = int256(uint256(int256(currTick2)) << 128)
                + (int256(liquidityNet) & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
            tickInfo = bytes.concat(tickInfo, bytes32(uint256(data)));

            if (currTick2 == prevTick) {
                break;
            }
            currTick2 = prevTick;
            iteration--;
        }

        return tickInfo;
    }

    function getBoundry(int24 tickSpacing, int24 leftPoint, int24 rightPoint)
        internal
        pure
        returns (int24 left, int24 right, uint256 initPoint)
    {
        left = leftPoint / tickSpacing / int24(256);
        if (leftPoint < 0) {
            initPoint = 256 - ((uint256(int256(-leftPoint)) / uint256(int256(tickSpacing))) % 256);
        } else {
            initPoint = (uint256(int256(leftPoint)) / uint256(int256(tickSpacing))) % 256;
        }

        right = rightPoint / tickSpacing / int24(256);
        // fix-bug: -2 /100 = 0; 2/100 = 0; to avoid -2 and 2 use the same world, make the -2 store inside world -1, 2 store inside world 0
        if (leftPoint < 0) left--;
        if (rightPoint < 0) right--;
    }

    struct Var {
        int24 tickSpacing;
        int24 left;
        int24 right;
        uint256 initPoint;
        uint256 index0;
        uint256 index1;
    }

    function queryIzumiTicksPool(address pool, int24 leftPoint, int24 rightPoint, uint256 len)
        public
        view
        returns (
            int24[] memory ticks,
            int128[] memory liquidityNets,
            int24[] memory orders,
            uint256[] memory sellingArr
        )
    {
        Var memory local;
        local.tickSpacing = IZumiPool(pool).pointDelta();
        (local.left, local.right, local.initPoint) = getBoundry(local.tickSpacing, leftPoint, rightPoint);
        if (len == 0) {
            len = uint256(int256((rightPoint - leftPoint) / local.tickSpacing));
        }
        ticks = new int24[](len);
        liquidityNets = new int128[](len);
        orders = new int24[](len);
        sellingArr = new uint256[](len);

        while (local.left < local.right + 1) {
            uint256 res = IZumiPool(pool).pointBitmap(int16(local.left));
            if (res > 0) {
                res = res >> local.initPoint;
                for (uint256 i = local.initPoint; i < 256; i++) {
                    uint256 isInit = res & 0x01;
                    if (isInit > 0) {
                        int24 tick = int24(int256((256 * local.left + int256(i)) * local.tickSpacing));
                        int24 orderOrEndpoint = IZumiPool(pool).orderOrEndpoint(tick / local.tickSpacing);
                        if (orderOrEndpoint & 0x01 == 0x01) {
                            (, int128 liquidityNet,,,) = IZumiPool(pool).points(tick);
                            if (liquidityNet != 0) {
                                ticks[local.index0] = int24(tick);
                                liquidityNets[local.index0] = liquidityNet;

                                local.index0++;
                            }
                        }
                        if (orderOrEndpoint & 0x02 == 0x02) {
                            (uint128 sellingX,,,,, uint128 sellingY,,,,) = IZumiPool(pool).limitOrderData(tick);
                            if (sellingX != 0 || sellingY != 0) {
                                orders[local.index1] = int24(tick);
                                sellingArr[local.index1] = (uint256(sellingX) << 128)
                                    + (sellingY & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);

                                local.index1++;
                            }
                        }
                    }

                    res = res >> 1;
                }
            }
            local.initPoint = 0;
            local.left++;
        }
        uint256 index0 = local.index0;
        uint256 index1 = local.index1;
        assembly {
            mstore(ticks, index0)
            mstore(liquidityNets, index0)
            mstore(orders, index1)
            mstore(sellingArr, index1)
            // mstore(sellingYArr, index1)
        }
        return (ticks, liquidityNets, orders, sellingArr);
    }
}