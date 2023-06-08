// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockAggregator is AggregatorV3Interface {
	// storage variables to hold the mock data
	uint8 private decimalsVal = 8;
	int256 private price = 190000000000;
	int256 private prevPrice = 190000000000;
	uint256 private updateTime;
	uint256 private prevUpdateTime;

	uint80 private latestRoundId = 2;
	uint80 private prevRoundId = 1;

	bool latestRevert;
	bool prevRevert;
	bool decimalsRevert;
	bool priceIsAlwaysUpToDate = true;

	// --- Functions ---

	function setDecimals(uint8 _decimals) external {
		decimalsVal = _decimals;
	}

	function setPrice(int256 _price) external {
		// setting a price will also set the previous one, so we don't create a deviation problem between rounds
		price = _price;
		prevPrice = _price;
	}

	function setPrevPrice(int256 _prevPrice) external {
		prevPrice = _prevPrice;
	}

	function setPrevUpdateTime(uint256 _prevUpdateTime) external {
		prevUpdateTime = _prevUpdateTime;
	}

	function setUpdateTime(uint256 _updateTime) external {
		updateTime = _updateTime;
	}

	function setLatestRevert() external {
		latestRevert = !latestRevert;
	}

	function setPrevRevert() external {
		prevRevert = !prevRevert;
	}

	function setDecimalsRevert() external {
		decimalsRevert = !decimalsRevert;
	}

	function setLatestRoundId(uint80 _latestRoundId) external {
		latestRoundId = _latestRoundId;
	}

	function setPrevRoundId(uint80 _prevRoundId) external {
		prevRoundId = _prevRoundId;
	}

	function setPriceIsAlwaysUpToDate(bool _priceIsAlwaysUpToDate) external {
		priceIsAlwaysUpToDate = _priceIsAlwaysUpToDate;
	}

	// --- Getters that adhere to the AggregatorV3 interface ---

	function decimals() external view override returns (uint8) {
		if (decimalsRevert) {
			require(1 == 0, "decimals reverted");
		}

		return decimalsVal;
	}

	function latestRoundData()
		external
		view
		override
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		)
	{
		if (latestRevert) {
			require(1 == 0, "latestRoundData reverted");
		}
		uint256 timestamp = priceIsAlwaysUpToDate ? block.timestamp - 2 minutes : updateTime;
		return (latestRoundId, price, 0, timestamp, 0);
	}

	function getRoundData(uint80)
		external
		view
		override
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		)
	{
		if (prevRevert) {
			require(1 == 0, "getRoundData reverted");
		}

		uint256 timestamp = priceIsAlwaysUpToDate ? block.timestamp - 5 minutes : updateTime;
		return (prevRoundId, prevPrice, 0, timestamp, 0);
	}

	function description() external pure override returns (string memory) {
		return "";
	}

	function version() external pure override returns (uint256) {
		return 1;
	}
}