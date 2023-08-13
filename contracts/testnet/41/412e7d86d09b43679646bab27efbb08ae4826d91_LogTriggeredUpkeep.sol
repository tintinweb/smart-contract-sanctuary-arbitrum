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

    function getCounter() external view returns (uint256) {
        return counter;
    }

    function checkLog(
        Log calldata _log,
        bytes memory _checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        if (_log.topics[0] != eventTopic) {
            revert("log topic does not match");
        }
        if (uint256(bytes32(_log.data)) < uint256(bytes32(_checkData))) {
            revert("log number too low");
        }
        return (true, abi.encode(_log, _checkData));
    }

    function performUpkeep(bytes calldata _performData) external {
        (Log memory log, bytes memory checkData) = abi.decode(_performData, (Log, bytes));

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