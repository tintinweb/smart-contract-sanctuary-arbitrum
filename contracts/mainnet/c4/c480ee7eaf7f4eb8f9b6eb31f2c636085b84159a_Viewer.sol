// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWrapper {
  function getCurrentPrice (  ) external view returns ( uint160 sqrtRatioX96 );
  function getRangePrices (  ) external view returns ( uint160 sqrtRatioAX96, uint160 sqrtRatioBX96 );
  function token0 (  ) external view returns ( address );
  function token1 (  ) external view returns ( address );
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract Viewer {
    function getRange(IWrapper wrapper) public view returns (uint256 l, uint256 c, uint256 u, uint256 li, uint256 ci, uint256 ui) {
        uint256 decimals0 = 10 ** IERC20(wrapper.token0()).decimals();
        uint256 decimals1 = 10 ** IERC20(wrapper.token1()).decimals();
        (uint256 L, uint256 C, uint256 U) = getPrices(wrapper);
        l = L * decimals0 / decimals1;
        c = C * decimals0 / decimals1;
        u = U * decimals0 / decimals1;
        ui = 1e36 * decimals1 / (decimals0 * L);
        ci = 1e36 * decimals1 / (decimals0 * C);
        li = 1e36 * decimals1 / (decimals0 * U);
    }

    function getPrices(IWrapper wrapper) public view returns (uint256 a, uint256 c, uint256 b) {
        (uint160 sqrtRatioAX96, uint160 sqrtRatioBX96) = wrapper.getRangePrices();
        uint160 currentPrice = wrapper.getCurrentPrice();
        uint256 q96 = 2 ** 96;
        a = (1e9 * sqrtRatioAX96 / q96) ** 2;
        b = (1e9 * sqrtRatioBX96 / q96) ** 2;
        c = (1e9 * currentPrice / q96) ** 2;
    }
}