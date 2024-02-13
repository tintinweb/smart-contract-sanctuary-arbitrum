// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

contract ChainlinkXAGUSDPriceConsumer {

    AggregatorV3Interface internal priceFeed;

    //Arbitrum: 0xC56765f04B248394CF1619D20dB8082Edbfa75b1
    //Ethereum: 0x379589227b15F1a12195D3f2d90bBc9F31f95235
    constructor() {
        priceFeed = AggregatorV3Interface(0xC56765f04B248394CF1619D20dB8082Edbfa75b1);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID
            , 
            int price,
            ,
            ,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        require(answeredInRound >= roundID);
        return price;
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }
}

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