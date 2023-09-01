/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol


pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

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

// File: AutoCtr.sol

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity 0.8.19;


// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol


contract AutoCtr is AutomationCompatibleInterface {

    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public interval;
    uint public maxCounter;
    event Logger(address indexed addr, bytes indexed checkD, uint timestamp,uint blocknbr, uint curcount);
    struct Target {
  
            uint lastTimeStamp;
            uint counter;
            address sender;
            }
    mapping(bytes => Target) public s_targets;

    constructor() {
      interval = 60;
      maxCounter = 4;
    }


    function checkUpkeep(bytes calldata checkData) external view  override returns (bool upkeepNeeded, bytes memory  performData ) {
          if ((s_targets[checkData].counter<maxCounter)&&(block.timestamp - s_targets[checkData].lastTimeStamp) > interval ) {
              return(true,checkData);
          } else {return(false,checkData);}
    }

    function performUpkeep(bytes calldata performData ) external override {
        uint currCount = 0;
        s_targets[performData].lastTimeStamp = block.timestamp;
        s_targets[performData].sender = msg.sender;
        currCount = s_targets[performData].counter +1;
        emit Logger(msg.sender, performData, block.timestamp,block.number, currCount);
        s_targets[performData].counter = currCount;  
    }
}