// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

contract ArbTestGetter {
  event Log(uint256 value);

  function getTxGasprice() external view returns (uint256) {
    return tx.gasprice;
  }

  function eventTxGasprice() external {
    emit Log(tx.gasprice);
  }
}