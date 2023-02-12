// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


contract Lending_DoSSF_3_Mitigation {
  
  address public owner;

  mapping(address => uint256) public debts;
  
  constructor() {
    owner = msg.sender;
  }

  function repay(address user, uint256 amount) external {
    require(msg.sender == owner);
    
    uint256 debt = debts[user];

    require(debt >= amount, "Insufficient debt");
    
    unchecked{
      debts[user] -= amount;
    }
  }

  function deposit() external {
      debts[msg.sender] += 1;
  }
}