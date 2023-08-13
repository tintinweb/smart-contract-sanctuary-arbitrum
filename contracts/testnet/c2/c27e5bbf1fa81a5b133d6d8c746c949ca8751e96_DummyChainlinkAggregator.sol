// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../oracle/interfaces/AggregatorV3Interface.sol";

contract DummyChainlinkAggregator is AggregatorV3Interface {
    uint80 public latestRoundId;
    string public id;
    uint8 public tokenDecimals;
    uint256 public latestPrice;

    constructor(string memory _id, uint8 _tokenDecimals, uint256 _latestPrice) {
        id = _id;
        tokenDecimals = _tokenDecimals;
        latestPrice = _latestPrice;
    }

    function decimals() external view override returns (uint8) {
        return tokenDecimals;
    } 

    function description() external view override returns (string memory) {
        return id;
    }

    function version() external pure override returns (uint256) {
        return 9969;
    }

    function getRoundData(uint80 _roundId) external view override returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {

    }

    function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (latestRoundId, int256(latestPrice), block.timestamp, block.timestamp, 0);
    }


    function setDecimals(uint8 _decimals) external {
        require(_decimals > 0, "Invalid decimals");
        tokenDecimals = _decimals;
    }

    function setLatestPrice(uint256 _latestPrice) external {
        latestPrice = _latestPrice;
        latestRoundId += 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//Chain Link aggregator
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId) external view returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );

  function latestRoundData() external view returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );
}