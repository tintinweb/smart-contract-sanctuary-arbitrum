// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IChainlinkAggregator.sol";

contract OracleWrapper {
	uint8 private constant DECIMALS = 8; 
	IChainlinkAggregator public immutable ethOracle;
	IChainlinkAggregator public immutable underlyingOracle;

	constructor(address _ethOracle, address _underlyingOracle) public {
		ethOracle = IChainlinkAggregator(_ethOracle);
		underlyingOracle = IChainlinkAggregator(_underlyingOracle);
	}

	function latestAnswer() external view returns (int256) {
		int256 ethPricInUSD = ethOracle.latestAnswer();
		int256 underlyingPriceInETH = underlyingOracle.latestAnswer();
		return underlyingPriceInETH * ethPricInUSD / 10 ** 18;
	}

	function latestTimestamp() external view returns (uint256) {
		return underlyingOracle.latestTimestamp();
	}

	function decimals() external view returns (uint8) {
		return DECIMALS;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IChainlinkAggregator {
  function decimals() external view returns (uint8);
  
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}