// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../interfaces/AggregatorV3Interface.sol";

contract FeedTester {
  AggregatorV3Interface public fastGasFeedOpt = AggregatorV3Interface(0x5ad5CAdeBc6908b3aeb378a56659d08391C4C043);
  AggregatorV3Interface public linkNativeFeedOpt = AggregatorV3Interface(0x9FF1c5b77fCe72f9AA291BbF1b53A03B478d8Cf2);

  AggregatorV3Interface public fastGasFeedArb = AggregatorV3Interface(0x116542f62410Ac122C73ED3bC478937e781c5333);
  AggregatorV3Interface public linkNativeFeedArb = AggregatorV3Interface(0xE07eb28DcE1EAC2e6ea30379320Db88ED4b8a871);

  function getOptData()
    external
    view
    returns (
      int256 optFastFeedValue,
      uint256 optFastTimestamp,
      int256 optLinkNativeFeedValue,
      uint256 optLinkNativeTimestamp
    )
  {
    (, optFastFeedValue, , optFastTimestamp, ) = fastGasFeedOpt.latestRoundData();
    (, optLinkNativeFeedValue, , optLinkNativeTimestamp, ) = linkNativeFeedOpt.latestRoundData();
    return (optFastFeedValue, optFastTimestamp, optLinkNativeFeedValue, optLinkNativeTimestamp);
  }

  function getArbData()
    external
    view
    returns (
      int256 arbFastFeedValue,
      uint256 arbFastTimestamp,
      int256 arbLinkNativeFeedValue,
      uint256 arbLinkNativeTimestamp
    )
  {
    (, arbFastFeedValue, , arbFastTimestamp, ) = fastGasFeedArb.latestRoundData();
    (, arbLinkNativeFeedValue, , arbLinkNativeTimestamp, ) = linkNativeFeedArb.latestRoundData();
    return (arbFastFeedValue, arbFastTimestamp, arbLinkNativeFeedValue, arbLinkNativeTimestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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