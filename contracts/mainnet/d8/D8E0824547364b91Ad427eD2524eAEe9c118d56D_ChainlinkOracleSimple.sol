// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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
pragma solidity ^0.8.14;

interface IOracle {
	function fetchPrice() external returns (uint256);
    function getDirectPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "../Interfaces/IOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract ChainlinkOracleSimple is IOracle {

	AggregatorV3Interface public immutable toUSD;
	AggregatorV3Interface public immutable toETH;

	// Use to convert a price answer to an 18-digit precision uint
	uint256 public constant TARGET_DECIMAL_1E18 = 1e18;

	constructor(address _toETH, address _toUSD) {
		require(_toETH != address(0), "Invalid chainlink address");
		require(_toUSD != address(0), "Invalid chainlink address");
		toUSD = AggregatorV3Interface(_toUSD);
		toETH = AggregatorV3Interface(_toETH);
	}


	function getDirectPrice() external view returns (uint256 _priceAssetInUSD) {
		return _getChainlinkPrice();
	}

	function fetchPrice() external override returns (uint256) {
		return _getChainlinkPrice();
	}

	function _getChainlinkPrice() internal view returns (uint256) {
		(, int256 _priceIntETH, , uint256 _updatedAtETH, ) = toETH.latestRoundData();
		(, int256 _priceIntUSD, , uint256 _updatedAtUSD, ) = toUSD.latestRoundData();
		require(
			_updatedAtETH > block.timestamp - 24 hours &&
			_updatedAtUSD > block.timestamp - 24 hours,
			"Chainlink price outdated"
		);
		return uint256(_priceIntETH) * uint256(_priceIntUSD) * TARGET_DECIMAL_1E18 / 1e26;
	}
}