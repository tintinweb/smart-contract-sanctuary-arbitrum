// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract Lending_DoSSF_1_Mitigation {
  
  mapping(address => uint256) public debts;
  
  function repay(uint256 amount) external {
    uint256 debt = debts[msg.sender];

    require(debt >= amount, "Insufficient debt");
    
    unchecked{
      debts[msg.sender] -= amount;
    }
  }

  function deposit() external {
      debts[msg.sender] += 1;
  }
}