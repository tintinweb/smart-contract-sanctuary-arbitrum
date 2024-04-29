/**
 *Submitted for verification at Arbiscan.io on 2024-04-28
*/

// SPDX-License-Identifier: MIT
// Deployed at: 0x2d9c3E914a043CC3A08A281B35A589F98546FBAF (Arbitrum)
pragma solidity 0.8.25;

// Interfaces of external contracts we need to interact with (only the functions we use)
interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);
}

interface IUniswapV3Pool {
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data) external returns (int256 amount0, int256 amount1);
}

interface IUniswapV3SwapCallback {
  function uniswapV3SwapCallback(
    int256 amount0Delta, // negative = was sent, positive = must be received
    int256 amount1Delta,
    bytes calldata data) external;
}

// Conctract to buy and sell some tokens from/to specific pools on Arbitrum One
contract ArbitrumTradeHelper {
  address private constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address private constant wstETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
  address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address private constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
  address private constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; // USDC.e

  address private constant WETH_USDC_V3 = 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
  address private constant WBTC_WETH_V3 = 0x2f5e87C9312fa29aed5c179E456625D79015299c;
  address private constant WETH_ARB_V3 = 0xC6F780497A95e246EB9449f5e4770916DCd6396A;
  address private constant WETH_wstETH_V3 = 0x35218a1cbaC5Bbc3E57fd9Bd38219D37571b3537;

  uint256 private constant SWAP_IDLE = 1;
  uint256 private constant SWAP_IN_PROGRESS = 2;

  uint160 private constant MIN_SQRT_PRICE = 4295128739 + 1;
  uint160 private constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342 - 1;

  // Used for unpacking parameters to the buy and sell functions
  uint256 constant private MAX128 = type(uint128).max;

  uint256 private _swapStatus;  // To protect against malicious/misbehaving V3 pool

  constructor() {
    _swapStatus = SWAP_IDLE;
  }

  function _callerBalanceOf(address token) private view returns (uint256) {
    return IERC20(token).balanceOf(msg.sender);
  }

  function _transferFrom(address from, address token, address to, uint256 amount) private {
    bool success = IERC20(token).transferFrom(from, to, amount);
    require(success, "TradeHelper: token transfer failure (check allowance)");
  }

  function _v3Swap(address pool, bool zeroForOne, int256 amount) private {
    _swapStatus = SWAP_IN_PROGRESS;

    IUniswapV3Pool(pool).swap(
      msg.sender,
      zeroForOne,
      amount,
      zeroForOne ? MIN_SQRT_PRICE : MAX_SQRT_PRICE,
      abi.encode(msg.sender));

    _swapStatus = SWAP_IDLE;
  }

  function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
    require(_swapStatus == SWAP_IN_PROGRESS, "TradeHelper: unexpected callback invocation");

    (address user) = abi.decode(data, (address));

    address pool = msg.sender;

    // Transfer the correct token from the user to the pool
    if (pool == WETH_USDC_V3) {
      if (amount0Delta > 0) {
        _transferFrom(user, WETH, WETH_USDC_V3, uint256(amount0Delta));
      } else {
        _transferFrom(user, USDC, WETH_USDC_V3, uint256(amount1Delta));
      }
    } else if (pool == WBTC_WETH_V3) {
      if (amount0Delta > 0) {
        _transferFrom(user, WBTC, WBTC_WETH_V3, uint256(amount0Delta));
      } else {
        _transferFrom(user, WETH, WBTC_WETH_V3, uint256(amount1Delta));
      }
    } else if (pool == WETH_ARB_V3) {
      if (amount0Delta > 0) {
        _transferFrom(user, WETH, WETH_ARB_V3, uint256(amount0Delta));
      } else {
        _transferFrom(user, ARB, WETH_ARB_V3, uint256(amount1Delta));
      }
    } else if (pool == WETH_wstETH_V3) {
      if (amount0Delta > 0) {
        _transferFrom(user, WETH, WETH_wstETH_V3, uint256(amount0Delta));
      } else {
        _transferFrom(user, wstETH, WETH_wstETH_V3, uint256(amount1Delta));
      }
    } else {
      revert("TradeHelper: unknown pool");
    }
  }

  function buyWeth(uint256 packedParams) external returns (uint256 usdcBalanceAfter) {
    uint256 wethBuyAmount = packedParams & MAX128;
    packedParams >>= 128;
    uint256 minUsdcBalanceAfter = packedParams;

    _v3Swap(WETH_USDC_V3, false, -int256(wethBuyAmount));

    usdcBalanceAfter = _callerBalanceOf(USDC);
    require(usdcBalanceAfter >= minUsdcBalanceAfter, "TradeHelper: would cost too much USDC");
  }

  function sellWeth(uint256 packedParams) external returns (uint256 usdcBalanceAfter) {
    uint256 wethSellAmount = packedParams & MAX128;
    packedParams >>= 128;
    uint256 minUsdcBalanceAfter = packedParams;

    if (wethSellAmount == 0) {
      wethSellAmount = _callerBalanceOf(WETH);
    }

    _v3Swap(WETH_USDC_V3, true, int256(wethSellAmount));

    usdcBalanceAfter = _callerBalanceOf(USDC);
    require(usdcBalanceAfter >= minUsdcBalanceAfter, "TradeHelper: would give too little USDC");
  }

  function buyUsdc(uint256 packedParams) external returns (uint256 wethBalanceAfter) {
    uint256 usdcBuyAmount = packedParams & MAX128;
    packedParams >>= 128;
    uint256 minWethBalanceAfter = packedParams;

    _v3Swap(WETH_USDC_V3, true, -int256(usdcBuyAmount));

    wethBalanceAfter = _callerBalanceOf(WETH);
    require(wethBalanceAfter >= minWethBalanceAfter, "TradeHelper: would cost too much WETH");
  }

  function sellUsdc(uint256 packedParams) external returns (uint256 wethBalanceAfter) {
    uint256 usdcSellAmount = packedParams & MAX128;
    packedParams >>= 128;
    uint256 minWethBalanceAfter = packedParams;

    if (usdcSellAmount == 0) {
      usdcSellAmount = _callerBalanceOf(USDC);
    }

    _v3Swap(WETH_USDC_V3, false, int256(usdcSellAmount));

    wethBalanceAfter = _callerBalanceOf(WETH);
    require(wethBalanceAfter >= minWethBalanceAfter, "TradeHelper: would give too little WETH");
  }

  function buyWbtc(uint256 packedParams) external returns (uint256 wethBalanceAfter) {
    uint256 wbtcBuyAmount = packedParams & MAX128;
    packedParams >>= 128;
    uint256 minWethBalanceAfter = packedParams;

    _v3Swap(WBTC_WETH_V3, false, -int256(wbtcBuyAmount));

    wethBalanceAfter = _callerBalanceOf(WETH);
    require(wethBalanceAfter >= minWethBalanceAfter, "TradeHelper: would cost too much WETH");
  }

  function sellWbtc(uint256 packedParams) external returns (uint256 wethBalanceAfter) {
    uint256 wbtcSellAmount = packedParams & MAX128;
    packedParams >>= 128;
    uint256 minWethBalanceAfter = packedParams;

    if (wbtcSellAmount == 0) {
      wbtcSellAmount = _callerBalanceOf(WBTC);
    }

    _v3Swap(WBTC_WETH_V3, true, int256(wbtcSellAmount));

    wethBalanceAfter = _callerBalanceOf(WETH);
    require(wethBalanceAfter >= minWethBalanceAfter, "TradeHelper: would give too little WETH");
  }

  function buyArb(uint256 packedParams) external returns (uint256 wethBalanceAfter) {
    uint256 arbBuyAmount = packedParams & MAX128;
    packedParams >>= 128;
    uint256 minWethBalanceAfter = packedParams;

    _v3Swap(WETH_ARB_V3, true, -int256(arbBuyAmount));

    wethBalanceAfter = _callerBalanceOf(WETH);
    require(wethBalanceAfter >= minWethBalanceAfter, "TradeHelper: would cost too much WETH");
  }

  function sellArb(uint256 packedParams) external returns (uint256 wethBalanceAfter) {
    uint256 arbSellAmount = packedParams & MAX128;
    packedParams >>= 128;
    uint256 minWethBalanceAfter = packedParams;

    if (arbSellAmount == 0) {
      arbSellAmount = _callerBalanceOf(ARB);
    }

    _v3Swap(WETH_ARB_V3, false, int256(arbSellAmount));

    wethBalanceAfter = _callerBalanceOf(WETH);
    require(wethBalanceAfter >= minWethBalanceAfter, "TradeHelper: would give too little WETH");
  }

  function buyWstEth(uint256 packedParams) external returns (uint256 wethBalanceAfter) {
    uint256 wstEthBuyAmount = packedParams & MAX128;
    packedParams >>= 128;
    uint256 minWethBalanceAfter = packedParams;

    _v3Swap(WETH_wstETH_V3, true, -int256(wstEthBuyAmount));

    wethBalanceAfter = _callerBalanceOf(WETH);
    require(wethBalanceAfter >= minWethBalanceAfter, "TradeHelper: would cost too much WETH");
  }

  function sellWstEth(uint256 packedParams) external returns (uint256 wethBalanceAfter) {
    uint256 wstEthSellAmount = packedParams & MAX128;
    packedParams >>= 128;
    uint256 minWethBalanceAfter = packedParams;

    if (wstEthSellAmount == 0) {
      wstEthSellAmount = _callerBalanceOf(wstETH);
    }

    _v3Swap(WETH_wstETH_V3, false, int256(wstEthSellAmount));

    wethBalanceAfter = _callerBalanceOf(WETH);
    require(wethBalanceAfter >= minWethBalanceAfter, "TradeHelper: would give too little WETH");
  }
}