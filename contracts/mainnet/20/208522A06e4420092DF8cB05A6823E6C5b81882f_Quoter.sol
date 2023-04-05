/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

library SafeCast {
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255, '!toInt256');
    z = int256(y);
  }
}

interface IPair {
  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
}

interface IPairV3 {
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);
}

interface IRouter {
  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 wad) external;

  function balanceOf(address account) external view returns (uint256);
}

contract Quoter {
  using SafeCast for uint256;

  uint256 private amountOutCached;

  uint160 private constant _MIN_SQRT_RATIO = 4295128739 + 1;

  uint160 private constant _MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;

  receive() external payable {}
  
  function withdraw(address weth, uint256 amount) external {
    IWETH(weth).withdraw(amount);
    (bool success,) = msg.sender.call{value:amount}(new bytes(0));
    require(success, "Quoter withdraw: ETH transfer failed");
  }

  struct SwapCallbackData {
    address tokenIn;
    address tokenOut;
  }

  struct Path {
    address pair;
    address tokenIn;
    address tokenOut;
    address router;
  }

  struct SwapV3Param {
    IPairV3 pair;
    address tokenIn;
    address tokenOut;
  }

  function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes memory _data
  ) external view {
    require(amount0Delta > 0 || amount1Delta > 0, '!amountDelta');
    SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));

    (bool isExactInput, uint256 amountToPay, uint256 amountReceived) =
      amount0Delta > 0
        ? (data.tokenIn < data.tokenOut, uint256(amount0Delta), uint256(-amount1Delta))
        : (data.tokenOut < data.tokenIn, uint256(amount1Delta), uint256(-amount0Delta));
    if (isExactInput) {
      assembly {
        let ptr := mload(0x40)
        mstore(ptr, amountReceived)
        revert(ptr, 32)
      }
    } else {
      if (amountOutCached != 0) require(amountReceived == amountOutCached, '!amountReceived');
      assembly {
        let ptr := mload(0x40)
        mstore(ptr, amountToPay)
        revert(ptr, 32)
      }
    }
  }

  function parseRevertReason(bytes memory reason) private pure returns (uint256) {
    if (reason.length != 32) {
      if (reason.length < 68) revert('Unexpected error');
      assembly {
        reason := add(reason, 0x04)
      }
      revert(abi.decode(reason, (string)));
    }
    return abi.decode(reason, (uint256));
  }

  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, 'Quoter: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'Quoter: ZERO_ADDRESS');
  }

  function getReserves(
    address pair,
    address tokenIn,
    address tokenOut
  ) private view returns (uint256 reserveInput, uint256 reserveOutput) {
    (address token0, ) = sortTokens(tokenIn, tokenOut);
    (uint256 reserve0, uint256 reserve1, ) = IPair(pair).getReserves();
    (reserveInput, reserveOutput) = tokenIn == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  function quoteExactInputSingle(SwapV3Param memory param, uint256 amountIn)
    public
    returns (uint256 amountOut)
  {
    bool zeroForOne = param.tokenIn < param.tokenOut;
    try
      param.pair.swap(
        address(this),
        zeroForOne,
        amountIn.toInt256(),
        zeroForOne ? _MIN_SQRT_RATIO : _MAX_SQRT_RATIO,
        abi.encode(SwapCallbackData({tokenIn: param.tokenIn, tokenOut: param.tokenOut}))
      )
    {} catch (bytes memory reason) {
      return parseRevertReason(reason);
    }
  }

  function quoteExactOutputSingle(SwapV3Param memory param, uint256 amountOut)
    public
    returns (uint256 amountIn)
  {
    bool zeroForOne = param.tokenIn < param.tokenOut;
    amountOutCached = amountOut;
    try
      param.pair.swap(
        address(this),
        zeroForOne,
        -amountOut.toInt256(),
        zeroForOne ? _MIN_SQRT_RATIO : _MAX_SQRT_RATIO,
        abi.encode(SwapCallbackData({tokenIn: param.tokenOut, tokenOut: param.tokenIn}))
      )
    {} catch (bytes memory reason) {
      delete amountOutCached; // clear cache
      return parseRevertReason(reason);
    }
  }

  function getAmountOut(
    IRouter router,
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) private view returns (uint256 amountOut) {
    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;
    uint256[] memory amounts = router.getAmountsOut(amountIn, path);
    amountOut = amounts[1];
  }

  function getAmountIn(
    IRouter router,
    address tokenIn,
    address tokenOut,
    uint256 amountOut
  ) private view returns (uint256 amountIn) {
    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;
    uint256[] memory amounts = router.getAmountsIn(amountOut, path);
    amountIn = amounts[0];
  }

  function getAmountsOut(Path[] memory path, uint256 amountIn)
    external
    returns (uint256[] memory amounts)
  {
    require(path.length >= 1, 'Quoter: INVALID_PATH');
    amounts = new uint256[](path.length + 1);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length; i++) {
      Path memory _path = path[i];
      if (_path.router != address(0)) {
        amounts[i + 1] = getAmountOut(
          IRouter(_path.router),
          _path.tokenIn,
          _path.tokenOut,
          amounts[i]
        );
      } else {
        amounts[i + 1] = quoteExactInputSingle(
          SwapV3Param({
            pair: IPairV3(_path.pair),
            tokenIn: _path.tokenIn,
            tokenOut: _path.tokenOut
          }),
          amounts[i]
        );
      }
    }
  }

  function getAmountsIn(Path[] memory path, uint256 amountOut)
    external
    returns (uint256[] memory amounts)
  {
    require(path.length >= 1, 'Quoter: INVALID_PATH');
    amounts = new uint256[](path.length + 1);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length; i > 0; i--) {
      Path memory _path = path[i - 1];
      if (_path.router != address(0)) {
        amounts[i - 1] = getAmountIn(
          IRouter(_path.router),
          _path.tokenIn,
          _path.tokenOut,
          amounts[i]
        );
      } else {
        amounts[i - 1] = quoteExactOutputSingle(
          SwapV3Param({
            pair: IPairV3(_path.pair),
            tokenIn: _path.tokenIn,
            tokenOut: _path.tokenOut
          }),
          amounts[i]
        );
      }
    }
  }
}