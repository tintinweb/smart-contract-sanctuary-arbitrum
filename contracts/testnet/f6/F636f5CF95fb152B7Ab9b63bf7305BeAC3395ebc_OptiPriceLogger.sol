// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract OptiPriceLogger {
  event DebugGas(
    uint256 indexed index,
    uint256 indexed blockNum,
    uint256 gasLeft,
    uint256 gasPrice
  );
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup

  constructor() {}

  function log() public returns (bool) {
    emit DebugGas(0, block.number, gasleft(), tx.gasprice);
    uint256 startGas = gasleft();
    bool dummy;
    uint256 blockNum = block.number - 1;
    // burn gas
    while (startGas - gasleft() < 500000) {
      dummy = dummy && dummyMap[blockhash(blockNum)]; // arbitrary storage reads
      blockNum--;
    }

    emit DebugGas(1, block.number, gasleft(), tx.gasprice);

    return true;
  }
}