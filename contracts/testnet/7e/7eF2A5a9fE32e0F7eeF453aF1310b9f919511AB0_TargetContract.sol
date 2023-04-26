/**
 *Submitted for verification at Arbiscan on 2023-04-25
*/

pragma solidity 0.8.17;

contract TargetContract {
  event Perform(
    address indexed from,
    uint256 initialBlock,
    uint256 lastBlock,
    uint256 previousBlock,
    uint256 counter
  );

  uint256 public lastBlock;
  uint256 public previousPerformBlock;
  uint256 public initialBlock;
  uint256 public counter;

  constructor() {
    previousPerformBlock = 0;
    lastBlock = block.number;
    initialBlock = 0;
    counter = 0;
  }

  function perform(bytes calldata performData) external {
    if (initialBlock == 0) {
      initialBlock = block.number;
    }
    lastBlock = block.number;
    counter = counter + 1;
    performData;
    emit Perform(tx.origin, initialBlock, lastBlock, previousPerformBlock, counter);
    previousPerformBlock = lastBlock;
  }
}