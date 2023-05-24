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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOracleAggregator {
    function CANCELATION_PERIOD() external view returns (uint256);
    function getData(address oracleId, uint256 timestamp) external view returns (uint256);
    function hasData(address oracleId, uint256 timestamp) external view returns (bool);
    function keepers(uint256 index) external view returns (address);
    function keepersCount() external view returns (uint256);
    function keepersContains(address keeper) external view returns (bool);
    function keepersList(uint256 offset, uint256 limit) external view returns (address[] memory output);
    function updater() external view returns (address);

    event KeepersAdded(address[] keepers);
    event KeepersRemoved(address[] keepers);
    event LogDataProvided(address indexed oracleId, uint256 indexed timestamp, uint256 data);
    event UpdaterUpdated(address indexed updater);

    function __callback(uint256 timestamp, uint256 data) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IOracleAggregator.sol";

interface IOracleTemplate {
    function decimals() external view returns (uint256);
    function oracleAggregator() external view returns (IOracleAggregator);
    function name() external view returns (string memory);
    function period() external view returns (uint256);
    function START() external view returns (uint256);
    function validateTimestamp(uint256 timestamp) external view returns (bool);

    event LogDataProvided(uint256 indexed _timestamp, uint256 indexed _data);

    function __callback(uint256 timestamp) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../OracleTemplate.sol";

contract ChainlinkPriceFeed is OracleTemplate {
    AggregatorV3Interface public immutable aggregator;

    constructor(
        AggregatorV3Interface aggregator_,
        address oracleAggregator_,
        uint256 period_
    ) OracleTemplate(oracleAggregator_, aggregator_.description(), aggregator_.decimals(), period_) {
        require(address(aggregator_) != address(0), "ChainlinkPriceFeed: Aggregator is zero address");
        aggregator = aggregator_;
    }

    function _getPrice() internal view override returns (uint256) {
        (, int256 price, , , ) = aggregator.latestRoundData();
        return uint256(price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IOracleTemplate.sol";

abstract contract OracleTemplate is IOracleTemplate {
    uint256 public constant START = 36000;

    IOracleAggregator public immutable oracleAggregator;
    uint256 public immutable decimals;
    uint256 public immutable period;

    string public name;

    function validateTimestamp(uint256 timestamp) public view returns (bool) {
        return (timestamp - START) % period == 0;
    }

    function _getPrice() internal view virtual returns (uint256);

    constructor(address oracleAggregator_, string memory name_, uint256 decimals_, uint256 period_) {
        require(oracleAggregator_ != address(0), "OracleTemplate: Oracle aggregator is zero address");
        require(period_ > 0, "OracleTemplate: Period is not positive");
        oracleAggregator = IOracleAggregator(oracleAggregator_);
        name = name_;
        decimals = decimals_;
        period = period_;
    }

    function __callback(uint256 timestamp) external returns (bool) {
        require(oracleAggregator.updater() == msg.sender, "OracleTemplate: Caller is not updater");
        require(
            timestamp + oracleAggregator.CANCELATION_PERIOD() >= block.timestamp,
            "OracleTemplate: Timestamp lt cancelation period"
        );
        require(timestamp < block.timestamp, "OracleTemplate: Timestamp gte current");
        require(validateTimestamp(timestamp), "OracleTemplate: Timestamp is incorrect");
        uint256 data = _getPrice();
        oracleAggregator.__callback(timestamp, data);
        emit LogDataProvided(timestamp, data);
        return true;
    }
}