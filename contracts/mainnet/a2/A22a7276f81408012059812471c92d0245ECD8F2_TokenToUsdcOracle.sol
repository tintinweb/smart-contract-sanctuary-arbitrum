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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.5.0;

interface ITokenToUsdcOracle {
    function usdcAmount(uint256 tokenAmount) external view returns (uint256 usdcAmount);
}

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../interfaces/ITokenToUsdcOracle.sol";

contract TokenToUsdcOracle is ITokenToUsdcOracle {
    AggregatorV3Interface internal dataFeed;
    AggregatorV3Interface internal usdcDataFeed;
    uint256 decimals;

    // if token decimals 18 need pass _decimals arg as 1e18
    constructor(address priceFeedAddress, address usdcPriceFeedAddress, uint256 _decimals) {
        dataFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        usdcDataFeed = AggregatorV3Interface(
            usdcPriceFeedAddress
        );
        decimals = _decimals;
    }

    function usdcAmount(uint256 tokenAmount) external view override returns (uint256 amount) {
        uint256 tokenPrice = uint256(_getLatestData());
        uint256 usdcPrice = uint256(_getLatestUsdcData());
        uint256 usdAmount = tokenAmount * tokenPrice / decimals;
        amount = usdAmount * 1e6 / usdcPrice;

        return amount;
    }

    function _getLatestData() internal view returns (int) {
        (,int answer,,,) = dataFeed.latestRoundData();

        return answer;
    }

    function _getLatestUsdcData() internal view returns (int) {
        (,int answer,,,) = usdcDataFeed.latestRoundData();

        return answer;
    }
}