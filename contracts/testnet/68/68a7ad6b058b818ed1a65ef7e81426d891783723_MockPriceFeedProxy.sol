// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./MockPriceFeedAggregator.sol";

contract MockPriceFeedProxy {
    address public aggregator;

    constructor(address aggregator_) {
        aggregator = aggregator_;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = MockPriceFeedAggregator(aggregator).latestRoundData();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

struct RoundData {
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
}

contract MockPriceFeedAggregator {
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    address public immutable owner;

    RoundData[] public roundData;

    constructor(int256 initialPrice) {
        owner = msg.sender;
        setNewPrice(initialPrice);
        setNewPrice(initialPrice); // Make sure roundId is 1
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "MockPriceFeed: not owner");
        _;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        RoundData memory data = roundData[roundData.length - 1];
        return (data.roundId, data.answer, data.startedAt, data.updatedAt, data.answeredInRound);
    }

    function setNewPrice(int256 newPrice) public onlyOwner {
        uint40 newRoundId = uint40(roundData.length);
        roundData.push(
            RoundData({
                roundId: newRoundId,
                answer: newPrice,
                startedAt: block.timestamp,
                updatedAt: block.timestamp,
                answeredInRound: newRoundId
            })
        );

        emit AnswerUpdated(newPrice, newRoundId, block.timestamp);
    }
}