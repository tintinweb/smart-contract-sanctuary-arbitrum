/**
 *Submitted for verification at Arbiscan on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract BlockNowTest {
  function blockNow() public view returns (uint256) {
    return block.number;
  }
}