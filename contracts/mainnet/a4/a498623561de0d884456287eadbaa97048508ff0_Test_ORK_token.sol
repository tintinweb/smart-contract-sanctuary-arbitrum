/**
 *Submitted for verification at Arbiscan on 2023-03-03
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

contract Test_ORK_token {
  string public name = "Galva_BIG_ORK";
  string public symbol = "GBO";
  uint8 public decimals = 18;
  uint256 public totalSupply = 9999;

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