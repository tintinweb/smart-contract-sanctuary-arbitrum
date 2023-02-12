// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


contract Lending_DoSSF_3_Vulnerable {

  mapping(address => mapping(address => uint256)) public debts;

  function repay(address user, address token, uint256 amount) external {
    uint256 debt = debts[user][token];

    require(debt >= amount, "Insufficient debt");
    
    unchecked{
      debts[user][token] -= amount;
    }
  }

  function deposit(address token) external {
      debts[msg.sender][token] += 1;
  }
}