// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

import { ISwapRouter } from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import { ICurveStableSwap } from '../interfaces/curve/ICurveStableSwap.sol';

import { AggregatorV3Interface } from '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

/* solhint-disable not-rely-on-time */

library SwapManager {
    error CYS_NEGATIVE_CRV_PRICE();

    uint256 internal constant MAX_BPS = 10_000;

    function _getCrvPrice(AggregatorV3Interface crvOracle) internal view returns (uint256) {
        (, int256 answer, , , ) = crvOracle.latestRoundData();
        if (answer < 0) revert CYS_NEGATIVE_CRV_PRICE();
        return (uint256(answer));
    }

    function swapUsdcToUsdtAndAddLiquidity(
        uint256 amount,
        uint256 slippage,
        bytes memory path,
        ISwapRouter uniV3Router,
        ICurveStableSwap triCrypto
    ) external {
        uint256 minOut = (amount * (MAX_BPS - slippage)) / MAX_BPS;

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            amountIn: amount,
            amountOutMinimum: minOut,
            recipient: address(this),
            deadline: block.timestamp
        });

        uint256 usdtOut = uniV3Router.exactInput(params);

        // USDT, WBTC, WETH
        uint256[3] memory amounts = [usdtOut, uint256(0), uint256(0)];
        triCrypto.add_liquidity(amounts, 0);
    }

    function swapUsdtToUsdc(
        uint256 amount,
        uint256 slippage,
        bytes memory path,
        ISwapRouter uniV3Router
    ) external returns (uint256 usdcOut) {
        uint256 minOut = (amount * (MAX_BPS - slippage)) / MAX_BPS;

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            amountIn: amount,
            amountOutMinimum: minOut,
            recipient: address(this),
            deadline: block.timestamp
        });

        usdcOut = uniV3Router.exactInput(params);
    }

    function swapCrvToUsdtAndAddLiquidity(
        uint256 crvAmount,
        uint256 crvSwapSlippageTolerance,
        AggregatorV3Interface crvOracle,
        bytes memory path,
        ISwapRouter uniV3Router,
        ICurveStableSwap triCrypto
    ) external returns (uint256 usdtOut) {
        uint256 minOut = (_getCrvPrice(crvOracle) * crvAmount * (MAX_BPS - crvSwapSlippageTolerance)) / MAX_BPS;
        // should not underflow because crvAmount > crv swap threshold
        minOut = ((minOut * (10**6)) / 10**18) / 10**8;

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            amountIn: crvAmount,
            amountOutMinimum: minOut,
            recipient: address(this),
            deadline: block.timestamp
        });

        usdtOut = uniV3Router.exactInput(params);

        uint256[3] memory amounts = [usdtOut, uint256(0), uint256(0)];
        triCrypto.add_liquidity(amounts, 0);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

/* solhint-disable func-name-mixedcase */
/* solhint-disable var-name-mixedcase */

interface ICurveStableSwap {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 index,
        uint256 min_amount
    ) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function exchange(
        uint256,
        uint256,
        uint256,
        uint256,
        bool
    ) external;

    function get_dy(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);

    function balances(uint256) external view returns (uint256);

    function calc_token_amount(uint256[3] memory amounts, bool deposit) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}