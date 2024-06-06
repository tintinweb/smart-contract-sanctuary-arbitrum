/**
 *Submitted for verification at Arbiscan.io on 2024-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IToken {
    function balanceOf(address account) external view returns (uint256);
}

contract BalanceChecker {
    function tokenBalance(address user, address token) public view returns (uint256) {
        try IToken(token).balanceOf(user) returns (uint256 balance) {
            return balance;
        } catch {
            return 0;
        }
    }

    function balances(address[] calldata users, address[] calldata tokens) external view returns (uint256[] memory) {
        uint256[] memory addrBalances = new uint256[](tokens.length * users.length);

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 index = j + tokens.length * i;
                if (tokens[j] != address(0)) {
                    addrBalances[index] = tokenBalance(users[i], tokens[j]); // Token balance
                } else {
                    addrBalances[index] = users[i].balance; // ETH balance
                }
            }
        }

        return addrBalances;
    }
}