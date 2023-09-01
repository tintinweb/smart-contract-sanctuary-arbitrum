/**
 *Submitted for verification at Arbiscan.io on 2023-08-28
*/

/**
 *Submitted for verification at Arbiscan.io on 2023-08-14
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File src/v0.8/dev/automation/2_1/interfaces/FeedLookupCompatibleInterface.sol


pragma solidity ^0.8.0;

interface FeedLookupCompatibleInterface {
  error FeedLookup(string feedParamKey, string[] feeds, string timeParamKey, uint256 time, bytes extraData);

  /**
   * @notice any contract which wants to utilize FeedLookup feature needs to
   * implement this interface as well as the automation compatible interface.
   * @param values an array of bytes returned from Mercury endpoint.
   * @param extraData context data from feed lookup process.
   * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
   */
  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external view returns (bool upkeepNeeded, bytes memory performData);
}


// File src/v0.8/dev/automation/2_1/interfaces/ILogAutomation.sol


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


// File src/v0.8/vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE


pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */



// File src/v0.8/dev/automation/tests/LogTriggeredFeedLookup.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;



interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier.
   * @param signedReport The encoded data to be verified.
   * @return verifierResponse The encoded response from the verifier.
   */
  function verify(bytes memory signedReport) external returns (bytes memory verifierResponse);
}

contract HelloUpkeep is ILogAutomation {
    event Hello(uint256 indexed blockNum);

  function checkLog(
    Log calldata log,
    bytes memory
  ) external override returns (bool upkeepNeeded, bytes memory performData) {
    return (true, "");
  }

  function performUpkeep(bytes calldata performData) external override {

      emit Hello(block.number);
  }
}