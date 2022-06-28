// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract ArbiGasLogger {
  event DebugGas(uint256 indexed gas);

  constructor() {}

  function log() public returns (bool) {
    emit DebugGas(gasleft());
    return true;
  }
}