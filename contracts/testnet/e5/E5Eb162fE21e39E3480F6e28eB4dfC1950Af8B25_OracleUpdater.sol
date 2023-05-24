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

import "./interfaces/IOracleTemplate.sol";

contract OracleUpdater {
    IOracleAggregator public immutable oracleAggregator;

    constructor(address oracleAggregator_) {
        require(oracleAggregator_ != address(0), "OracleUpdater: Oracle aggregator is zero address");
        oracleAggregator = IOracleAggregator(oracleAggregator_);
    }

    function __callback(address[] memory oracles, uint256 timestamp) external returns (bool[] memory results) {
        require(oracleAggregator.keepersContains(msg.sender), "OracleUpdater: Caller is not keeper");
        require(
            timestamp + oracleAggregator.CANCELATION_PERIOD() >= block.timestamp,
            "OracleTemplate: Timestamp lt cancelation period"
        );
        require(timestamp < block.timestamp, "OracleTemplate: Timestamp gte current");
        results = new bool[](oracles.length);
        for (uint256 i = 0; i < oracles.length; i++) {
            results[i] = IOracleTemplate(oracles[i]).__callback(timestamp);
        }
    }
}