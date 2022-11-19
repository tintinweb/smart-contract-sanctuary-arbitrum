// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../core/interfaces/ISwapFactory.sol";
import "./libraries/Memory.sol";

struct PairData {
  uint256 amountIn;
  address tokenIn;
  uint256 _reserve0;
  uint256 _reserve1;
  address token0;
  uint256 decimals0;
  uint256 decimals1;
  bool stable;
}

struct ReserveData {
  uint256 reserve0;
  uint256 reserve1;
}

struct AmountOutData {
  ReserveData[] reservesBeforeTrade;
  uint256[] amountsOut;
}

struct routeWithOffset {
  address from;
  address to;
  bool stable;
  uint256 offset;
}

interface ISwapPair {
  function metadata()
    external
    view
    returns (
      uint256 dec0,
      uint256 dec1,
      uint256 r0,
      uint256 r1,
      bool st,
      address t0,
      address t1
    );
}

interface IRouter {
  function pairFor(
    address tokenA,
    address tokenB,
    bool stable
  ) external view returns (address pair);
}

contract MultiswapRouterUtil {
  IRouter public immutable router;
  ISwapFactory public immutable factory;

  constructor(address _router, address _factory) {
    router = IRouter(_router);
    factory = ISwapFactory(_factory);
  }

  function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
    return (x0 * ((((y * y) / 1e18) * y) / 1e18)) / 1e18 + (((((x0 * x0) / 1e18) * x0) / 1e18) * y) / 1e18;
  }

  function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
    return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
  }

  function _get_y(
    uint256 x0,
    uint256 xy,
    uint256 y
  ) internal pure returns (uint256) {
    for (uint256 i = 0; i < 255; i++) {
      uint256 y_prev = y;
      uint256 k = _f(x0, y);
      if (k < xy) {
        uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
        y = y + dy;
      } else {
        uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
        y = y - dy;
      }
      if (y > y_prev) {
        if (y - y_prev <= 1) {
          return y;
        }
      } else {
        if (y_prev - y <= 1) {
          return y;
        }
      }
    }
    return y;
  }

  function _k(
    uint256 x,
    uint256 y,
    bool stable,
    uint256 decimals0,
    uint256 decimals1
  ) internal pure returns (uint256) {
    if (stable) {
      uint256 _x = (x * 1e18) / decimals0;
      uint256 _y = (y * 1e18) / decimals1;
      uint256 _a = (_x * _y) / 1e18;
      uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
      return (_a * _b) / 1e18; // x3y+y3x >= k
    } else {
      return x * y; // xy >= k
    }
  }

  //given a set of routes, calculate the out amount accounting for different start reserves
  function getAmountOutWithPriorReserves(
    routeWithOffset[][] calldata routes,
    uint256[] calldata amountsIn,
    uint256 numPairs,
    uint256[] memory offsets,
    ReserveData[] memory reserves
  ) external view returns (AmountOutData[] memory) {
    uint256 startOffset = _allocateReserveSpaceInMemory(numPairs);
    for (uint256 index = 0; index < offsets.length; index++) {
      _updatePairReservesInMemory(startOffset, offsets[index], reserves[index].reserve0, reserves[index].reserve1);
    }
    return _getAmountOutForMultipleRoutes(routes, amountsIn, startOffset);
  }

  function getAmountOutForMultipleRoutes(
    routeWithOffset[][] calldata routes,
    uint256[] calldata amountsIn,
    uint256 numPairs
  ) external view returns (AmountOutData[] memory) {
    uint256 startOffset = _allocateReserveSpaceInMemory(numPairs);
    return _getAmountOutForMultipleRoutes(routes, amountsIn, startOffset);
  }

  function _getAmountOutForMultipleRoutes(
    routeWithOffset[][] calldata routes,
    uint256[] calldata amountsIn,
    uint256 startOffset
  ) internal view returns (AmountOutData[] memory) {
    AmountOutData[] memory amounts = new AmountOutData[](routes.length);
    for (uint256 index = 0; index < routes.length; index++) {
      amounts[index] = getAmountsAccountingForReserves(amountsIn[index], routes[index], startOffset);
      if (amounts[index].amountsOut.length == 0) {
        return new AmountOutData[](0);
      }
    }
    return amounts;
  }

  // performs chained getAmountOut calculations on any number of pairs, accounting for reserves changed
  function getAmountsAccountingForReserves(
    uint256 amountIn,
    routeWithOffset[] memory routes,
    uint256 startOffset
  ) internal view returns (AmountOutData memory) {
    require(routes.length >= 1, "BaseV1Router: INVALID_PATH");
    uint256[] memory amounts = new uint256[](routes.length + 1);
    ReserveData[] memory reserves = new ReserveData[](routes.length);
    amounts[0] = amountIn;
    for (uint256 i = 0; i < routes.length; i++) {
      address pair = router.pairFor(routes[i].from, routes[i].to, routes[i].stable);
      if (factory.isPair(pair)) {
        (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, , address t0, ) = ISwapPair(pair).metadata();
        (r0, r1) = _retrievePairReservesFromMemory(startOffset, routes[i].offset, r0, r1);
        uint256[2] memory newReserves;
        (amounts[i + 1], newReserves) = _calculateAmountOutWithReserveChange(
          PairData(amounts[i], routes[i].from, r0, r1, t0, dec0, dec1, routes[i].stable)
        );
        if (newReserves[0] <= 0 || newReserves[1] <= 0) {
          return AmountOutData(new ReserveData[](0), new uint256[](0));
        }
        uint256[2] memory sortedReserves = routes[i].from == t0 ? [r0, r1] : [r1, r0];
        reserves[i] = ReserveData(sortedReserves[0], sortedReserves[1]);
        _updatePairReservesInMemory(startOffset, routes[i].offset, newReserves[0], newReserves[1]);
      } else {
        return AmountOutData(new ReserveData[](0), new uint256[](0));
      }
    }
    return AmountOutData(reserves, amounts);
  }

  function _calculateAmountOutWithReserveChange(PairData memory pairData)
    internal
    view
    returns (uint256, uint256[2] memory)
  {
    pairData.amountIn -= (pairData.amountIn * ISwapFactory(factory).fee(pairData.stable)) / 1e6;
    if (pairData._reserve0 == 0 || pairData._reserve1 == 0) {
      return (0, [uint256(0), uint256(0)]);
    }
    uint256 amountOut;
    if (pairData.stable) {
      uint256 xy = _k(pairData._reserve0, pairData._reserve1, pairData.stable, pairData.decimals0, pairData.decimals1);
      (uint256 reserveA, uint256 reserveB) = pairData.tokenIn == pairData.token0
        ? ((pairData._reserve0 * 1e18) / pairData.decimals0, (pairData._reserve1 * 1e18) / pairData.decimals1)
        : ((pairData._reserve1 * 1e18) / pairData.decimals1, (pairData._reserve0 * 1e18) / pairData.decimals0);
      uint256 y = reserveB -
        _get_y(
          (
            pairData.tokenIn == pairData.token0
              ? (pairData.amountIn * 1e18) / pairData.decimals0
              : (pairData.amountIn * 1e18) / pairData.decimals1
          ) + reserveA,
          xy,
          reserveB
        );
      amountOut = (y * (pairData.tokenIn == pairData.token0 ? pairData.decimals1 : pairData.decimals0)) / 1e18;
    } else {
      (uint256 reserveA, uint256 reserveB) = pairData.tokenIn == pairData.token0
        ? (pairData._reserve0, pairData._reserve1)
        : (pairData._reserve1, pairData._reserve0);
      amountOut = (pairData.amountIn * reserveB) / (reserveA + pairData.amountIn);
    }
    uint256 reserve0Change = pairData.tokenIn == pairData.token0
      ? pairData._reserve0 + pairData.amountIn
      : pairData._reserve0 - amountOut;
    uint256 reserve1Change = pairData.tokenIn == pairData.token0
      ? pairData._reserve1 - amountOut
      : pairData._reserve1 + pairData.amountIn;

    if (amountOut > (pairData.tokenIn == pairData.token0 ? pairData._reserve1 : pairData._reserve0)) {
      return (0, [uint256(0), uint256(0)]);
    }

    return (amountOut, [reserve0Change, reserve1Change]);
  }

  function _allocateReserveSpaceInMemory(uint256 numPairs) internal pure returns (uint256 firstFreeMemPointer) {
    firstFreeMemPointer = Memory.getFreeMemoryPointer();
    //reserves 64 bytes for each pair
    //32 bytes for reserve0 and 32 bytes for reserve1
    Memory.jumpFreeMemoryPointer(bytes32(uint256(64 * numPairs)));
  }

  function _retrievePairReservesFromMemory(
    uint256 startOffset,
    uint256 offset,
    uint256 r0,
    uint256 r1
  ) internal pure returns (uint256, uint256) {
    uint256 _r0 = Memory.readUint256FromMemory(_getBytes32AtOffset(startOffset, offset, 0));
    uint256 _r1 = Memory.readUint256FromMemory(_getBytes32AtOffset(startOffset, offset, 1));
    if (_r0 == 0 && _r1 == 0) {
      _updatePairReservesInMemory(startOffset, offset, r0, r1);
    }
    return (
      Memory.readUint256FromMemory(_getBytes32AtOffset(startOffset, offset, 0)),
      Memory.readUint256FromMemory(_getBytes32AtOffset(startOffset, offset, 1))
    );
  }

  function _updatePairReservesInMemory(
    uint256 startOffset,
    uint256 offset,
    uint256 r0,
    uint256 r1
  ) internal pure {
    Memory.updateUint256InMemory(_getBytes32AtOffset(startOffset, offset, 0), r0);
    Memory.updateUint256InMemory(_getBytes32AtOffset(startOffset, offset, 1), r1);
  }

  function _getBytes32AtOffset(
    uint256 startOffset,
    uint256 offset,
    uint8 elementIndex
  ) internal pure returns (bytes32) {
    return bytes32(uint256(startOffset + ((offset * 64) + (elementIndex * 32))));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwapFactory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function fee(bool stable) external view returns (uint);
    function feeCollector() external view returns (address);
    function setFeeTier(bool stable, uint fee) external;
    function admin() external view returns (address);
    function setAdmin(address _admin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Memory {
  function writeUint256ToMemory(uint256 _input) internal pure {
    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(freeMemoryPointer, _input)
      let nextAvailableMemory := add(mload(0x40), 0x20)
      mstore(0x40, nextAvailableMemory)
    }
  }

  function readUint256FromMemory(bytes32 offset) internal pure returns (uint256 result) {
    assembly {
      result := mload(offset)
    }
  }

  function updateUint256InMemory(bytes32 offset, uint256 _input) internal pure {
    assembly {
      mstore(offset, _input)
    }
  }

  function getFreeMemoryPointer() internal pure returns (uint256 pointer) {
    assembly {
      pointer := mload(0x40)
    }
  }

  function jumpFreeMemoryPointer(bytes32 offset) internal pure {
    assembly {
      mstore(0x40, add(mload(0x40), offset))
    }
  }
}