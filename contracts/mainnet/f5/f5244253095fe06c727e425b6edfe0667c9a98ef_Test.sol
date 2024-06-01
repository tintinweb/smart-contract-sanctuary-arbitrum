/**
 *Submitted for verification at Arbiscan.io on 2024-06-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;


contract Test {

  constructor(){
  }

  function foo() public view returns (uint256) {
    return block.number;
  }

}