/**
 *Submitted for verification at Arbiscan.io on 2024-05-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

 /**
   * @title Dex
   * @dev get price contract
   * @custom:dev-run-script scripts/deploy_with_ethers.ts
   */

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IERC20Metadata {
    function decimals() external view returns (uint8);
}

contract PriceGetter {

    error PairDoesntExist();

    function getPrice(address factory, address token1, address token2, uint8 decimalsAfterPoint) public view returns (uint256 price) {
        
        address pair = IUniswapV2Factory(factory).getPair(token1, token2);

        if (pair == address(0)) {
            revert PairDoesntExist();
        }
        
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        address token0 = IUniswapV2Pair(pair).token0();

        uint8 decimals0 = IERC20Metadata(token0).decimals();
        uint8 decimals1 = IERC20Metadata(token0 == token1 ? token2 : token1).decimals();
        uint256 scaleFactor = 10 ** decimalsAfterPoint;

        
        if (token0 == token1) {
            price = (reserve1 * (10 ** decimals0) * scaleFactor) / reserve0 / (10 ** decimals1);
        } else {
            price = (reserve0 * (10 ** decimals1) * scaleFactor) / reserve1 / (10 ** decimals0);
        }
    }

}