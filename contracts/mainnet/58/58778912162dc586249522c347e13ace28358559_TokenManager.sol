/**
 *Submitted for verification at Arbiscan.io on 2024-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


struct Records {
  uint256 amount;
  uint256 avgPrice;
}

contract TokenManager {

  mapping(address owner => mapping(address token => Records record)) accounts;

  function deposit(address token, uint256 amount, uint256 price) external {
    bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
    require(success, "insufficient token amount");
    Records memory cache = accounts[msg.sender][token];
    uint256 oldAmount = cache.amount;
    uint256 oldAvgPrice = cache.avgPrice;
    accounts[msg.sender][token] = Records(
      {
        amount: oldAmount + amount,
        avgPrice: (oldAvgPrice * oldAmount + price * amount) / (oldAmount + amount)
      }
    );
  }

  function withdraw(address token, uint256 amount) external {
    Records memory cache = accounts[msg.sender][token];
    require(cache.amount >= amount, "insufficient token amount");
    bool success = IERC20(token).transfer(msg.sender, amount);
    require(success, "insufficient token amount");
    accounts[msg.sender][token].amount = cache.amount - amount;
  }

  function averagePrice(address token) external view returns (uint256) {
    return accounts[msg.sender][token].avgPrice;
  }

  function amount(address token) external view returns (uint256) {
    return accounts[msg.sender][token].amount;
  }

  // function withdraw()
  receive() external payable {
    revert();
  }
}