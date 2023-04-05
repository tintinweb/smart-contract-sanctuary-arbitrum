/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenDistribution {
    address public treasury;
    address public tokenAddress;
    mapping(address => bool) public canClaim;
    mapping(address => uint256) public claimAmounts;
    uint256 public deploymentTime;
    uint256 public totalAmount;
    
    constructor(address _tokenAddress, address[] memory addresses, uint256[] memory amounts) {
        treasury = msg.sender;
        tokenAddress = _tokenAddress;
        deploymentTime = block.timestamp;
        require(addresses.length == amounts.length, "Invalid input data.");
        // Distribute tokens
        for (uint256 i = 0; i < addresses.length; i++) {
            require(amounts[i] > 0, "Invalid claim amount.");
            canClaim[addresses[i]] = true;
            claimAmounts[addresses[i]] = amounts[i];
            totalAmount += amounts[i];
        }
    }
    
    function depositTokens() external {
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), totalAmount), "Failed to transfer tokens to contract.");
    }
    
    function checkClaimStatus(address account) external view returns (bool) {
        return canClaim[account];
    }
    
    function getClaimAmount(address account) external view returns (uint256) {
        return claimAmounts[account];
    }
    
    function claimTokens() external {
        require(canClaim[msg.sender], "Address cannot claim tokens.");  
        uint256 amount = claimAmounts[msg.sender];
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "Failed to claim tokens.");
        claimAmounts[msg.sender] = 0;
        canClaim[msg.sender] = false;
    }
    
    function ownerWithdraw() external {
        require(block.timestamp >= deploymentTime + 90 days, "Withdrawal not yet available.");
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw.");
        require(IERC20(tokenAddress).transfer(treasury, balance), "Failed to withdraw tokens.");
    }
}