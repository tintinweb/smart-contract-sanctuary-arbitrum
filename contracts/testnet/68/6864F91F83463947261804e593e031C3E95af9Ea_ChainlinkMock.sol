// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IChainlink {
    function decimals() external view returns (uint8);
    function getRoundData(uint80 _roundId) external view 
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData() external view 
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "contracts/interfaces/IChainlink.sol";

contract ChainlinkMock is IChainlink {
    PriceRound[] private prices;

    struct PriceRound { uint256 timestamp; int256 price; }

    function decimals() external pure returns (uint8) { return 8; }

    function addPriceRound(uint256 timestamp, int256 price) external {
        prices.push(PriceRound(timestamp, price));
    }

    function setPrice(int256 _price) external {
        while (prices.length > 0) prices.pop();
        prices.push(PriceRound(block.timestamp - 4 hours, _price));
    }

    function getRoundData(uint80 _roundId) external view 
        returns (uint80 roundId, int256 answer, uint256, uint256 updatedAt, uint80) {
            roundId = _roundId;
            answer = prices[roundId].price;
            updatedAt = prices[roundId].timestamp;
        }

    function latestRoundData() external view 
        returns (uint80 roundId, int256 answer,uint256, uint256 updatedAt,uint80) {
            roundId = uint80(prices.length - 1);
            answer = prices[roundId].price;
            updatedAt = prices[roundId].timestamp;
        }
}