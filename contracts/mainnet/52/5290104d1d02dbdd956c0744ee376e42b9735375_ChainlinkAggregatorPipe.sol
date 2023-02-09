// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IChainlinkAggregator {
  function decimals() external view returns (uint8);
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);
}

contract ChainlinkAggregatorPipe {

    IChainlinkAggregator public immutable source;
    IChainlinkAggregator public immutable target;

    constructor(
        IChainlinkAggregator _source,
        IChainlinkAggregator _target
    ) {
        source = _source;
        target = _target;
    }

    function latestAnswer() external view returns (int256) {
        return source.latestAnswer() * 1e18 / target.latestAnswer();
    }
}