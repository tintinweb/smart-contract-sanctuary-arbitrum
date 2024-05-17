// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.16;

interface IVault {
    function convertToAssets(uint256 _amount) external view returns (int256);
    function decimals() external view returns (uint8);
}


// Price feed for Arbitrum stUSD
 contract stUSDPriceFeedArbitrum {

    address stUSD = 0x0022228a2cc5E7eF0274A7Baa600d44da5aB5776;
    constructor () {
    }

    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        uint8 decimalNumber = IVault(stUSD).decimals();
        return (0, IVault(stUSD).convertToAssets(1 * 10**decimalNumber), 0, block.timestamp, 0);
    }

    function decimals() external view returns (uint8) {
        return IVault(stUSD).decimals();
    }
 }