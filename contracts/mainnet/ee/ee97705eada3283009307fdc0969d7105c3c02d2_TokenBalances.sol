/**
 *Submitted for verification at Arbiscan.io on 2024-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract TokenBalances {
    function getBalances(address[] memory tokenAddresses, address walletAddress) public view returns (uint256[] memory, uint256) {
        uint256[] memory balances = new uint256[](tokenAddresses.length);

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            IERC20 token = IERC20(tokenAddresses[i]);
            uint256 balance = token.balanceOf(walletAddress);
            uint8 decimals = token.decimals();

            // Adjust the balance by dividing by 10^decimals and multiplying by 10^6
            uint256 adjustedBalance = (balance * 10**6) / (10**decimals);

            balances[i] = adjustedBalance;
        }

        uint256 blockTime = block.timestamp;

        return (balances, blockTime);
    }
}