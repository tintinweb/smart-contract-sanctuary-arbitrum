/**
 *Submitted for verification at Arbiscan.io on 2024-04-21
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MassTransfer {
    function massTransfer(address tokenAddress, address[] memory recipients, uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        uint256 totalRecipients = recipients.length;
        uint256 totalAmount = amount * totalRecipients;

        require(token.balanceOf(msg.sender) >= totalAmount, "Insufficient balance");

        for (uint256 i = 0; i < totalRecipients; i++) {
            token.transferFrom(msg.sender, recipients[i], amount);
        }
    }
}