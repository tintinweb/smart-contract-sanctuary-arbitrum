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

contract SimpleLogTriggeredUpkeep {
    uint256 counter;
    event CounterUpdated(uint256 newCounter);
    function getCounter() external view returns (uint256) {
        return counter;
    }
    function setEventTopic(uint256 _counter) external {
        counter = _counter;
        emit CounterUpdated(counter);
    }

    bytes32 eventTopic = 0x776f5bdcf949d816af88d9bac5515262b4b76341abbde373b7bbd86b5b780ed9;
    event EventTopicUpdated(bytes32 newEventTopic);
    function getEventTopic() external view returns (bytes32) {
        return eventTopic;
    }
    function setEventTopic(bytes32 _eventTopic) external {
        eventTopic = _eventTopic;
        emit EventTopicUpdated(eventTopic);
    }

    // Log Trigger Upkeep
    function checkLog(Log calldata _log, bytes memory) external view returns (bool upkeepNeeded, bytes memory performData) {
        if (_log.topics[0] != eventTopic) {
            revert("log topic does not match");
        }
        return (true, bytes(""));
    }

    function performUpkeep(bytes calldata) external {
        counter++;
        emit CounterUpdated(counter);
    }
}