/**
 *Submitted for verification at Arbiscan on 2023-07-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Distributor {
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can invoke this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function distributeETH(address payable[] memory recipients) external payable  {
        require(recipients.length > 0, "At least one recipient is required");

        uint256 totalAmount = msg.value;
        uint256 distributionAmount = totalAmount / recipients.length;
        uint256 remainingAmount = totalAmount % recipients.length;

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(distributionAmount);
        }

        // Refund remaining amount to the contract owner
        if (remainingAmount > 0) {
            payable(owner).transfer(remainingAmount);
        }
    }

   function distributeToken(address tokenAddress, address[] memory recipients, uint256 totalAmount) external {
        require(tokenAddress != address(0), "Invalid token address");
        require(recipients.length > 0, "At least one recipient is required");
        require(totalAmount > 0, "Total amount must be greater than zero");

        ERC20 token = ERC20(tokenAddress);
        uint256 totalRecipients = recipients.length;
        uint256 distributionAmount = totalAmount / totalRecipients;
        uint256 remainingAmount = totalAmount % totalRecipients;

        // Transfer tokens from sender to contract address
        require(token.transferFrom(msg.sender, address(this), totalAmount), "Token transfer failed");

        for (uint256 i = 0; i < totalRecipients; i++) {
            require(token.transfer(recipients[i], distributionAmount), "Token transfer failed");
        }

        // Refund remaining tokens to the contract owner
        if (remainingAmount > 0) {
            require(token.transfer(owner, remainingAmount), "Token refund failed");
        }
    }


    function transferEther(address payable recipient, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");

        recipient.transfer(amount);
    }

    function transferToken(address tokenAddress, address recipient, uint256 amount) external onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        require(amount <= token.balanceOf(address(this)), "Insufficient balance");

        require(token.transfer(recipient, amount), "Token transfer failed");
    }

    function withdrawEther() external onlyOwner {
        require(address(this).balance > 0, "No Ether to withdraw");
        payable(owner).transfer(address(this).balance);
    }
}