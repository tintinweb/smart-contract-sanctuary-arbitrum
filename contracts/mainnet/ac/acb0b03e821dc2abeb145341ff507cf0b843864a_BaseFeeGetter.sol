/**
 *Submitted for verification at Arbiscan on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract BaseFeeGetter {
  function getBaseFee() view external returns (uint256) {
    return block.basefee;
  }
}