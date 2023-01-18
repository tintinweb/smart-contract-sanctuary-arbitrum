/**
 *Submitted for verification at Arbiscan on 2023-01-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IArbSys {
  function arbBlockNumber() external view returns (uint256);
}

contract BlockNumberTest {
  address constant private ArbSys = address(0x64);

  function makeAlisaPregnant() external view returns(
    uint256 blockNumberNormal,
    uint256 blockNumberArbitrum,
    uint256 timestamp) {

    blockNumberNormal = block.number;
    blockNumberArbitrum = IArbSys(ArbSys).arbBlockNumber();
    timestamp = block.timestamp;
  }
}