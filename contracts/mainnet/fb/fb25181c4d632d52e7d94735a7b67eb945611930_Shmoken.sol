/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

contract Shmoken {
  string public name = "MSC_f";
  string public symbol = "SHLP";
  uint8 public decimals = 18;
  uint256 public totalSupply = 100000000;

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