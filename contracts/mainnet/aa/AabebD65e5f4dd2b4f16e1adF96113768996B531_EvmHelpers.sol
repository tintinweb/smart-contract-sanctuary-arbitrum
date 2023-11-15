// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

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

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


contract Ether {
    function balanceOf(address wallet) external view returns (uint256) {
        return wallet.balance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Ether.sol";
import "./MultiCall.sol";
import "./UniV3Helper.sol";

//solhint-disable-next-line no-empty-blocks
contract EvmHelpers is Ether, MultiCall, UniV3Helper {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


interface IUniswapV3 {
    function tickSpacing() external view returns (int24);

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick
            // the rest is ignored
        );

    function feeGrowthGlobal0X128() external view returns (uint256);

    function feeGrowthGlobal1X128() external view returns (uint256);

    function protocolFees() external view returns (uint128 token0, uint128 token1);

    function liquidity() external view returns (uint128);

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

    function tickBitmap(int16 wordPosition) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title MultiCall
/// @dev A contract for batching multiple contract function calls into a single transaction.
contract MultiCall {

    /// @dev A struct representing a single call to a contract function.
    struct Call {
        address to; // The address of the contract to call.
        bytes data; // The calldata to send with the call.
    }

    /**
     * @notice Executes multiple calls in a single transaction.
     * @dev The function is not gas-limited and may revert due to out of gas errors.
     * @param calls An array of Call structs, each representing a function call.
     * @return results An array of bytes, each entry being the result of the respective function call.
     */
   function multicall(Call[] memory calls) public returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
        }
    }

    /**
     * @notice Executes multiple calls in a single transaction with gas limitations.
     * @dev The function will stop making calls when the remaining gas is less than `gasBuffer`.
     * Passing emtpy calls array (calls.length == 0) will result in having lastSuccessIndex = uint256.max.
     * @param calls An array of Call struct instances representing each call.
     * @param gasBuffer The amount of gas that should remain after the last function call.
     * @return results An array of bytes. Each entry represents the return data of each call.
     * @return lastSuccessIndex The index of the last successful call in the `calls` array.
     */
    function multicallWithGasLimitation(Call[] memory calls, uint256 gasBuffer) public returns (bytes[] memory results, uint256 lastSuccessIndex) {
        results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
            if (gasleft() < gasBuffer) {
                return (results, i);
            }
        }
        return (results, calls.length - 1);
    }

    /**
     * @notice Executes multiple calls in a single transaction and measures the gas used by each call.
     * @dev This function is not gas-limited and may revert due to out of gas errors.
     * @param calls An array of Call struct instances representing each call.
     * @return results An array of bytes. Each entry represents the return data of each call.
     * @return gasUsed An array of uint256. Each entry represents the amount of gas used by the corresponding call.
     */
   function multicallWithGas(Call[] memory calls) public returns (bytes[] memory results, uint256[] memory gasUsed) {
        results = new bytes[](calls.length);
        gasUsed = new uint256[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            uint256 initialGas = gasleft();
            (, results[i]) = calls[i].to.call(calls[i].data);  // solhint-disable-line avoid-low-level-calls
            gasUsed[i] = initialGas - gasleft();
        }
    }

    /// @notice Fetches the block gas limit.
    /// @return result The block gas limit.
    function gaslimit() external view returns (uint256) {
        return block.gaslimit;
    }

    /// @notice Fetches the remaining gas available for the current transaction.
    /// @return result The remaining gas.
    function gasLeft() external view returns (uint256) {
        return gasleft();
    }

    /// @notice Fetches the block timestamp.
    /// @return result timestamp of the block.
    function getCurrentBlockTimestamp() external view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@uniswap/v3-core/contracts/libraries/BitMath.sol";
import "./interfaces/IUniswapV3.sol";

/// @title UniV3Helper
/// @dev Helper contract to interact with Uniswap V3 pool contracts.
contract UniV3Helper {
    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;

    /**
     * @notice Fetches tick data for a specified range from a Uniswap V3 pool.
     * @dev The function returns an array of bytes each containing packed data about each tick in the specified range.
     * The returned tick data includes the total liquidity, liquidity delta, outer fee growth for the two tokens, and
     * the tick value itself. The tick range is centered around the current tick of the pool and spans tickRange*2.
     * The tick range is constrained by the global min and max tick values.
     * If there are no initialized ticks in the range, the function returns an empty array.
     * @param pool The Uniswap V3 pool from which to fetch tick data.
     * @param tickRange The range (either side of the current tick) within which to fetch tick data.
     * @return ticks An array of bytes each containing packed data about each tick in the specified range.
     */
    function getTicks(IUniswapV3 pool, int24 tickRange) external view returns (bytes[] memory ticks) {
        int24 tickSpacing = pool.tickSpacing();
        (,int24 tick) = pool.slot0();

        tickRange *= tickSpacing;
        int24 fromTick = tick - tickRange;
        int24 toTick = tick + tickRange;
        if (fromTick < _MIN_TICK) {
            fromTick = _MIN_TICK;
        }
        if (toTick > _MAX_TICK) {
            toTick = _MAX_TICK;
        }

        int24[] memory initTicks = new int24[](uint256(int256((toTick - fromTick + 1) / tickSpacing)));

        uint256 counter = 0;
        int16 pos = int16((fromTick / tickSpacing) >> 8);
        int16 endPos = int16((toTick / tickSpacing) >> 8);
        for (; pos <= endPos; pos++) {
            uint256 bm = pool.tickBitmap(pos);

            while (bm != 0) {
                uint8 bit = BitMath.leastSignificantBit(bm);
                bm ^= 1 << bit;
                int24 extractedTick = ((int24(pos) << 8) | int24(uint24(bit))) * tickSpacing;
                if (extractedTick >= fromTick && extractedTick <= toTick) {
                    initTicks[counter++] = extractedTick;
                }
            }
        }

        ticks = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            (
                uint128 liquidityGross,
                int128 liquidityNet,
                uint256 feeGrowthOutside0X128,
                uint256 feeGrowthOutside1X128
                , // int56 tickCumulativeOutside,
                , // secondsPerLiquidityOutsideX128
                , // uint32 secondsOutside
                , // init
            ) = pool.ticks(initTicks[i]);

            ticks[i] = abi.encodePacked(
                liquidityGross,
                liquidityNet,
                feeGrowthOutside0X128,
                feeGrowthOutside1X128,
                // tickCumulativeOutside,
                // secondsPerLiquidityOutsideX128,
                // secondsOutside,
                initTicks[i]
            );
        }
    }
}