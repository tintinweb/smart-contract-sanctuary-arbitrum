// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract Lending_DoSSF_2_Mitigation {

  mapping(address => uint256) public debts;
  
  function repay(address user, uint256 amount) external {
    uint256 debt = debts[user];

    if(debt < amount) debts[user] = 0;
   
    else { unchecked{debts[user] -= amount;} }
  }

  function deposit() external {
      debts[msg.sender] += 1;
  }
}