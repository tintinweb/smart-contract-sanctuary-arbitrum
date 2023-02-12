// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


contract Lending_DoSSF_4_Vulnerable {
  
  mapping(address => uint256) public debts;

  function repay(address user, uint256 amount) external {
    uint256 debt = debts[user];

    require(debt >= amount, "Insufficient debt");
    
    _payUserDebt(user, amount);
  }

  function deposit() external {
      debts[msg.sender] += 1;
  }

  function _payUserDebt(address user, uint256 amount) internal {
    unchecked{
      debts[user] -= amount;
    }
  }
}