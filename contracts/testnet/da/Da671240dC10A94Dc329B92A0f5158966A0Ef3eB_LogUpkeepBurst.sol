// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import {ILogAutomation, Log} from "./ILogAutomation.sol";

contract LogUpkeepBurst is ILogAutomation {
    bytes32 sig = 0x5121119bad45ca7e58e0bdadf39045f5111e93ba4304a0f6457a3e7bc9791e71;

    event PerformingUpkeep(address from, uint256 block, uint256 previousBlock, uint256 counter);

    /**
     * @dev we include multiple event types for testing various filters, signatures, etc
     */
    event Trigger(uint256 indexed a, uint256 indexed b, uint256 indexed c); // 0x5121119bad45ca7e58e0bdadf39045f5111e93ba4304a0f6457a3e7bc9791e71

    uint256 public lastPerform;
    uint256 public counter;

    constructor() {
        counter = 0;
    }

    function start() public {
        counter = 0;
        emit Trigger(0, 0, counter);
        emit Trigger(0, 0, counter);
    }

    function checkLog(Log calldata log, bytes memory)
        external
        view
        override
        returns (bool, bytes memory)
    {
        if (log.topics[0] == sig) {
            return (true, abi.encode(log));
        } else {
            revert("bad log");
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        Log memory log = abi.decode(performData, (Log));
        if (log.topics[0] == sig) {
            counter = counter + 1;
            emit Trigger(0, 0, counter);
            emit Trigger(0, 0, counter);
        } else {
            revert("could not find matching sig");
        }
        emit PerformingUpkeep(tx.origin, block.number, lastPerform, counter);
        lastPerform = block.number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface ILogAutomation {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param log the raw log data matching the filter that this contract has
   * registered as a trigger
   * @param checkData user-specified extra data to provide context to this upkeep
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkLog(
    Log calldata log,
    bytes memory checkData
  ) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}