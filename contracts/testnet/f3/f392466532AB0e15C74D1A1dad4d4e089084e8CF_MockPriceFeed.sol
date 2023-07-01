// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MockPriceFeed {
    uint80 currentRoundId;
    mapping(uint80 => int) marketPrice;
    mapping(uint => uint) timestamp;

    constructor() {}

    function setMarketPrice(int price) external {
        currentRoundId++;
        marketPrice[currentRoundId] = price;
        timestamp[currentRoundId] = block.timestamp;
    }

    function getPrice() external view returns (int) {
        return marketPrice[currentRoundId];
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            currentRoundId,
            marketPrice[currentRoundId],
            timestamp[currentRoundId],
            timestamp[currentRoundId],
            currentRoundId
        );
    }
}