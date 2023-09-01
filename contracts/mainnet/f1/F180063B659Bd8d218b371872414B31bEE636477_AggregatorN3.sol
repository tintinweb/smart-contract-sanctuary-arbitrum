// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract Aggregator {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestAnswer() external pure returns (int256 answer) {
        return 99997069;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, 99997069, block.timestamp, block.timestamp, 0);
    }
}

contract AggregatorN3 {
    uint8 _decimals;
    int256 _latestAnswer;

    constructor() {
        _decimals = 8;
        _latestAnswer = 100000000;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function latestAnswer() external view returns (int256 answer) {
        return _latestAnswer;
    }

    function updateRate(uint8 newDecimals, int256 newLatestAnswer) external {
        _decimals = newDecimals;
        _latestAnswer = newLatestAnswer;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, _latestAnswer, block.timestamp, block.timestamp, 0);
    }
}

contract AggregatorN2 {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestAnswer() external pure returns (int256 answer) {
        return 99997069 * 2;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, 99997069 * 2, block.timestamp, block.timestamp, 0);
    }
}