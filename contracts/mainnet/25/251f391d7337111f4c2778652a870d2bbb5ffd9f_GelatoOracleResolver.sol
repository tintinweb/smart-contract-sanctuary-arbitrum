// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOracleTWAP {
  function lastTimestamp() external view returns (uint256);
  function updateInterval() external view returns (uint256);
}

contract GelatoOracleResolver {
    function checker(address oracle) external view returns (bool, bytes memory) {
        uint256 lastTimestamp = IOracleTWAP(oracle).lastTimestamp();
        uint256 updateInterval = IOracleTWAP(oracle).updateInterval();
        return (block.timestamp > lastTimestamp + (updateInterval * 150 / 100), "");
    }
}