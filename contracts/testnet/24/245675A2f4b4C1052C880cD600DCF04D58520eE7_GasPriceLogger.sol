// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract GasPriceLogger {
  event DebugGas(
    uint256 indexed index,
    uint256 indexed blockNum,
    uint256 gasLeft,
    uint256 gasPrice,
    uint256 l1GasCost
  );
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup

  constructor() {}

  function log() public returns (bool) {
    emit DebugGas(0, block.number, gasleft(), tx.gasprice, 0);
    uint256 l1CostWei;

    // Get L1 cost of this tx
    // contract to call is precompiled arb gas info at 0x000000000000000000000000000000000000006C
    // function to call is getCurrentTxL1GasFees() uint256 which corresponds to 0xc6f7de0e
    (bool success, bytes memory result) = address(0x000000000000000000000000000000000000006C).call(
      abi.encodeWithSelector(0xc6f7de0e)
    );
    l1CostWei = abi.decode(result, (uint256));

    emit DebugGas(0, block.number, gasleft(), tx.gasprice, l1CostWei);

    uint256 startGas = gasleft();
    bool dummy;
    uint256 blockNum = block.number - 1;
    // burn gas
    while (startGas - gasleft() < 500000) {
      dummy = dummy && dummyMap[blockhash(blockNum)]; // arbitrary storage reads
      blockNum--;
    }

    emit DebugGas(2, block.number, gasleft(), tx.gasprice, 0);

    return true;
  }
}