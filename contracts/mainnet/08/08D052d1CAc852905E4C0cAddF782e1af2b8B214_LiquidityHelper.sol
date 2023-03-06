// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// ====================================================================
// ====================== LiquidityHelper.sol ============================
// ====================================================================

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "./TickMath.sol";
import "./FixedPoint96.sol";
import "./SqrtPriceMath.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./INonfungiblePositionManager.sol";
import "./ABDKMath64x64.sol";

contract LiquidityHelper {
    IUniswapV3Factory internal constant uniswapV3Factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    INonfungiblePositionManager internal constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function getTokenAmountsFromLP(
        uint256 tokenId,
        address token0,
        address token1,
        uint24 fee
    ) external view returns (uint256 amount0, uint256 amount1) {
        address pool_address = uniswapV3Factory.getPool(token0, token1, fee);
        IUniswapV3Pool pool = IUniswapV3Pool(pool_address);
        (uint160 sqrtPriceX96, int24 tickCurrent, , , , , ) = pool.slot0();
        (
            ,
            ,
            ,
            ,
            ,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(tokenId);

        if (tickCurrent < tickLower) {
            amount0 = SqrtPriceMath.getAmount0Delta(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity,
                true
            );
            amount1 = 0;
        } else if (tickCurrent < tickUpper) {
            amount0 = SqrtPriceMath.getAmount0Delta(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity,
                true
            );
            amount1 = SqrtPriceMath.getAmount1Delta(
                TickMath.getSqrtRatioAtTick(tickLower),
                sqrtPriceX96,
                liquidity,
                true
            );
        } else {
            amount0 = 0;
            amount1 = SqrtPriceMath.getAmount1Delta(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity,
                true
            );
        }
    }

    function getTickFromPrice(
        uint256 price,
        uint256 decimal,
        int24 tickSpacing,
        bool flag
    ) external pure returns (int24 tick) {
        int128 value1 = ABDKMath64x64.fromUInt(10**decimal);
        int128 value2 = ABDKMath64x64.fromUInt(price);
        int128 value = ABDKMath64x64.div(value2, value1);
        if (flag) {
            value = ABDKMath64x64.div(value1, value2);
        }
        tick = TickMath.getTickAtSqrtRatio(
            uint160(
                int160(
                    ABDKMath64x64.sqrt(value) << (FixedPoint96.RESOLUTION - 64)
                )
            )
        );

        tick = (tick / tickSpacing) * tickSpacing;
    }
}