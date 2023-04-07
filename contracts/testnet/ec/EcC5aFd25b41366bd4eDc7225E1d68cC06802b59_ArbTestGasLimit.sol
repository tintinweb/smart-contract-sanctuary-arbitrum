// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract ArbTestGasLimit {
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup
  event DebugGas(uint256 index, uint256 indexed gas);

  constructor() {}

  function burn(uint256 gas) public {
    uint256 init = gasleft();
    emit DebugGas(0, init);
    uint256 blockNum = block.number;
    while (init - gasleft() < gas) {
      // Hard coded check gas to burn
      dummyMap[blockhash(blockNum)] = false; // arbitrary storage writes
      blockNum--;
    }
    emit DebugGas(1, gasleft());
  }
}