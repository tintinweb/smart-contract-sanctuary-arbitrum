// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract ArbiGasLogger {
  event DebugGas(uint256 index, uint256 indexed gas);

  constructor() {}

  function log() public returns (bool) {
    emit DebugGas(0, gasleft());
    emit DebugGas(1, gasleft());
    emit DebugGas(2, gasleft());
    return true;
  }
}