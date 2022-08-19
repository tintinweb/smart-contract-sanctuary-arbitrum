/**
 *Submitted for verification at Arbiscan on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract RubberDuckZ {
  uint256 public duck;
  address public rubber;

  constructor(address _rubber) {
    rubber = _rubber;
    duck = 1;
  }
}