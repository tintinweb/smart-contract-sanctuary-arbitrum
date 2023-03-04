/**
 *Submitted for verification at Arbiscan on 2023-03-04
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

contract MyLoveToken {
  string public name = "MyLoveToken";
  string public symbol = "MLT";
  uint8 public decimals = 18;
  uint256 public totalSupply = 1000;

  mapping (address => uint256) public balances;
  address public owner;

  constructor() {
    owner = msg.sender;
    balances[owner] = totalSupply;
  }

  function transfer(address recipient, uint256 amount) public {
    require(balances[msg.sender] >= amount, "Insufficient balance.");
    balances[msg.sender] -= amount;
    balances[recipient] += amount;
  }
}