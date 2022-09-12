pragma solidity ^0.8.10;

contract MockAggregator {

int256 price;

function setPrice (int256 _price) external returns (int256) {
    price = _price;
    return price;
}

function latestRoundData() public view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
    uint80 _roundId = 1;
    int256 _answer = price;
    uint256 _startedAt = 1;
    uint256 _updatedAt = 1;
    uint80 _answeredInRound = 1;

    return(_roundId, _answer, _startedAt, _updatedAt, _answeredInRound);
}

function decimals() public view returns (uint8) {
    uint8 decimals = 8;
    return decimals;
}

}