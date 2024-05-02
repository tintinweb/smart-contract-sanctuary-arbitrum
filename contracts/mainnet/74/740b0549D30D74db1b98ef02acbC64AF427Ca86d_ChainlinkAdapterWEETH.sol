// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(
		uint80 _roundId
	)
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function latestRoundData()
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IChainlinkAdapter {
	function latestAnswer() external view returns (uint256 price);

	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IChainlinkAdapter} from "../../../interfaces/IChainlinkAdapter.sol";
import {AggregatorV3Interface} from "../../../interfaces/AggregatorV3Interface.sol";

/// @title WEETH Oracle Contract
/// @notice Provides weETH/USD price using ETH/USD Chainlink oracle and weETH/ETH Chainlink oracle
/// @author Radiant
contract ChainlinkAdapterWEETH is IChainlinkAdapter {
	/// @notice ETH/USD price feed
	IChainlinkAdapter public ethUSDOracle;
	/// @notice weETH/ETH feed
	IChainlinkAdapter public ethPerWeETHOracle;

	error AddressZero();    
    error InvalidWeETHToEthRatio();

	/**
	 * @notice Constructor
	 * @param _ethUSDOracle ETH/USD price feed
	 * @param _ethPerWeETHOracle wstETHRatio feed
	 */
	constructor (address _ethUSDOracle, address _ethPerWeETHOracle) {
		if (_ethUSDOracle == address(0)) revert AddressZero();
		if (_ethPerWeETHOracle == address(0)) revert AddressZero();

		ethUSDOracle = IChainlinkAdapter(_ethUSDOracle); // 8 decimals
		ethPerWeETHOracle = IChainlinkAdapter(_ethPerWeETHOracle); // 18 decimals
	}

	/**
	 * @notice Returns weETH/USD price. Checks for Chainlink oracle staleness with validate() in BaseChainlinkAdapter
	 * @return answer weETH/USD price with 8 decimals
	 */
	function latestAnswer() external view returns (uint256 answer) {
		// decimals 8
		uint256 ethPrice = ethUSDOracle.latestAnswer();
		// decimals 18
		uint256 weETHToEthRatio = ethPerWeETHOracle.latestAnswer();
        
        if (weETHToEthRatio < 1 ether) {
			revert InvalidWeETHToEthRatio();
		}

		answer = (ethPrice * weETHToEthRatio) / 1 ether;
	}

	function decimals() external pure returns (uint8) {
		return 8;
	}
}