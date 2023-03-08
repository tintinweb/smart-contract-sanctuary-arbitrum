// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== Pegging.sol ==============================
// ====================================================================

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

/*
**   The intention of this contract is to attepmt to calculate
**   the required amount of SWEEP to buy from the Uniswap AMM
**   in order to take the price to a desired target price.
*/

import "./IERC20.sol";
import "./ISweep.sol";

import "./SafeMath.sol";
import "./ABDKMath64x64.sol";
import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./FixedPoint96.sol";
import "./SqrtPriceMath.sol";
import "./IUniswapV3Factory.sol";
import "./INonfungiblePositionManager.sol";

contract Pegging {
    using SafeMath for uint256;

    IERC20 public USDX;
    ISweep public SWEEP;
    IUniswapV3Factory public constant uniswap_factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    constructor(
        address _sweep_address,
        address _usdc_address
    ) {
        USDX = IERC20(_usdc_address);
        SWEEP = ISweep(_sweep_address);
    }

    function amountToPeg_UsingConstantProduct() public view returns (uint256 amount) {
        address uniswapV3Pool = uniswap_factory.getPool(address(SWEEP), address(USDX), 3000);
        IUniswapV3Pool pool = IUniswapV3Pool(uniswapV3Pool);

        uint256 sweep_amount = SWEEP.balanceOf(uniswapV3Pool);
        uint256 usdx_amount = USDX.balanceOf(uniswapV3Pool);
        uint256 target_price = SWEEP.target_price();
        uint256 radicand = target_price * sweep_amount * usdx_amount * 1e6;
        uint256 root = radicand.sqrt();

        uint256 sweep_to_peg = (root > sweep_amount) ? (root - sweep_amount) : (sweep_amount - root);
        sweep_to_peg = sweep_to_peg * 997 / 1000;

        (, int24 tickCurrent, , , , , ) = pool.slot0();

        amount = getQuoteAtTick(tickCurrent, uint128(sweep_to_peg), address(SWEEP), address(USDX));
    }

    function amountToPeg_UsingTicks(uint256 tokenId) public view returns (uint256 amount) {
        address uniswapV3Pool = uniswap_factory.getPool(address(SWEEP), address(USDX), 3000);
        IUniswapV3Pool pool = IUniswapV3Pool(uniswapV3Pool);
        (, int24 tickCurrent, , , , , ) = pool.slot0();
        (,,,,, int24 tickLower,, uint128 liquidity,,,,) = nonfungiblePositionManager.positions(tokenId);

        int24 targetTick = getTickFromPrice(SWEEP.target_price(), 18);

        uint256 currentSweepAmount = SqrtPriceMath.getAmount0Delta(uint160(uint24(tickLower)), uint160(uint24(tickCurrent)), liquidity, true) / 1e32;
        uint256 targetSweepAmount = SqrtPriceMath.getAmount0Delta(uint160(uint24(tickLower)), uint160(uint24(targetTick)), liquidity, true) / 1e32;

        amount = (targetSweepAmount > currentSweepAmount ) ?
            targetSweepAmount - currentSweepAmount : 0;
    }

    function getTickFromPrice(uint256 _price, uint256 _decimals)
        public
        pure
        returns (int24 _tick)
    {
        int24 tickSpacing = 60;
        int128 value1 = ABDKMath64x64.fromUInt(10**_decimals);
        int128 value2 = ABDKMath64x64.fromUInt(_price);
        int128 value = ABDKMath64x64.div(value1, value2);
        _tick = TickMath.getTickAtSqrtRatio(
            uint160(int160(ABDKMath64x64.sqrt(value) << (FixedPoint96.RESOLUTION - 64)))
        );

        _tick = (_tick / tickSpacing) * tickSpacing;
    }

    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) public pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

}