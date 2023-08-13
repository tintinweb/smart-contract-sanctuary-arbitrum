/**
 *Submitted for verification at Arbiscan on 2023-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct Log {
  uint256 index;
  uint256 txIndex;
  bytes32 txHash;
  uint256 blockNumber;
  bytes32 blockHash;
  address source;
  bytes32[] topics;
  bytes data;
}

contract LogTriggeredUpkeep {
    bytes32 eventTopic = 0xd932f6a2eb240089fd3c3d5be9ad1a5ae5d828aefbddf87f93279481929d39d6;
    uint256 counter;

    event CounterUpdated(uint256 oldCounter, uint256 newCounter, Log log, uint256 checkData);

    function checkLog(
        Log calldata log,
        bytes memory checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        if (log.topics[0] != eventTopic) {
            revert("log topic does not match");
        }
        if (uint256(bytes32(log.data)) < uint256(bytes32(checkData))) {
            revert("log number too low");
        }
        return (true, abi.encode(log, checkData));
    }

    function performUpkeep(bytes calldata performData) external {
        (Log memory log, bytes memory checkData) = abi.decode(performData, (Log, bytes));

        if (log.topics[0] != eventTopic) {
            revert("event does not match");
        }

        uint256 emittedNum = uint256(bytes32(log.data));
        uint256 checkDataNum = uint256(bytes32(checkData));

        if (emittedNum < checkDataNum) {
            revert("number too low");
        }

        uint256 oldCounter = counter;
        counter = oldCounter + emittedNum + checkDataNum;

        emit CounterUpdated(oldCounter, counter, log, checkDataNum);
    }
}