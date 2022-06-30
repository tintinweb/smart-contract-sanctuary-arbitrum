// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract OptiPriceLogger {
  event DebugGas(uint256 indexed index, uint256 indexed gasLeft, uint256 indexed gasPrice);
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup

  constructor() {}

  function log() public returns (bool) {
    emit DebugGas(0, gasleft(), tx.gasprice);
    uint256 startGas = gasleft();
    bool dummy;
    uint256 blockNum = block.number - 1;
    // burn gas
    while (startGas - gasleft() < 500000) {
      dummy = dummy && dummyMap[blockhash(blockNum)]; // arbitrary storage reads
      blockNum--;
    }

    emit DebugGas(1, gasleft(), tx.gasprice);

    return true;
  }
}