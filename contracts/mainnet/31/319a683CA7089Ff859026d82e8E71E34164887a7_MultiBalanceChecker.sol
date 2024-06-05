// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC20Balance {
  function balanceOf(address account) external view returns (uint256);
}

// Forked from HIM
contract MultiBalanceChecker {

  // Function to check the token balances of multiple addresses
  function checkBalances(address tokenAddress, address[] calldata accounts) public view returns (uint256[] memory) {
    uint256[] memory balances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; i++)
      balances[i] = IERC20Balance(tokenAddress).balanceOf(accounts[i]);

    return balances;
  }

}