/**
 *Submitted for verification at Arbiscan on 2023-04-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
}

contract LockLPTokens {
    using SafeMath for uint256;
    
    address public owner;
    address treasury;
    uint256 createTime;
    uint256 public amountLocked;
    uint256 lockDuration;
    uint256 public releaseTime;
    uint256 public redeemTime;
    bool public isLocked;
    address public tokenAddress;
    IERC20 tokenInstance;

    constructor(address _tokenAddress, uint256 _lockDuration, address _treasury) {
        owner = msg.sender;
        treasury = _treasury;
        createTime = block.timestamp;
        tokenAddress = _tokenAddress;
        tokenInstance = IERC20(tokenAddress);
        lockDuration = _lockDuration;
        releaseTime = 0;
        redeemTime = 0;
        amountLocked = 0;
        isLocked = false;
    }

    // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    // Get how many LP tokens you have
    function getBalance() public view returns(uint256) {
        return tokenInstance.balanceOf(msg.sender);
    }

    // Get the allowance you provided for this contract for your LP token
    function getAllowance() public view returns(uint256) {
        return tokenInstance.allowance(msg.sender, address(this));
    }

    // Get the time until the lock ends in seconds
    // If error: lock ended
    function timeUntilRelease() public view returns(uint256) {
        return releaseTime.sub(block.timestamp);
    }

    // Renounce ownership of the contract
    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    // Lock the LP tokens
    function lockLiquidity() external onlyOwner {
        uint256 balance = getBalance();
        uint256 allowance = getAllowance();
        // Set release time
        releaseTime = block.timestamp.add(lockDuration);
        // Check allowance
        require(allowance >= balance, "Not enough balance");
        // Transfer LP tokens from user to contract
        require(tokenInstance.transferFrom(msg.sender, address(this), balance), "TransferFrom failed");
        amountLocked = balance;
        isLocked = true;
    }

    // Redeem LP tokens to the Treasury
    function redeem() external {
        // Check if release time has been reached
        require(block.timestamp >= releaseTime, "Tokens are still locked");
        // Check if tokens have already been redeemed
        require(redeemTime == 0, "Tokens already redeemed");
        // Transfer LP tokens from contract to user
        require(tokenInstance.transfer(treasury, amountLocked), "Transfer failed");
        // Set redeemed time
        redeemTime = block.timestamp;
        isLocked = false;
        amountLocked = 0;
    }
}