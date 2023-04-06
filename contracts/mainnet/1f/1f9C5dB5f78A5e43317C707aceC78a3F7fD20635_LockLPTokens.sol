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

    // Throws if tokens have been redeemed
    modifier notRedeemed() {
        require(redeemTime == 0, "Tokens already redeemed");
        _;
    }

    // Get how many LP tokens the owner has
    function getThisBalance() public view returns(uint256) {
        return tokenInstance.balanceOf(address(this));
    }

    // Get how many LP tokens the owner has
    function getBalance(address _address) public view returns(uint256) {
        return tokenInstance.balanceOf(_address);
    }

    // Get the allowance you provided for this contract for your LP token
    function getAllowance(address _address) public view returns(uint256) {
        return tokenInstance.allowance(_address, address(this));
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
    function lockLiquidity() external onlyOwner notRedeemed {
        // Require that tokens are not yet locked
        require(!isLocked, "Already locked");
        // Get balance
        uint256 balance = getBalance(owner);
        // Get allowance
        uint256 allowance = getAllowance(owner);
        // Check allowance
        require(allowance >= balance, "Not enough balance");
        // Transfer LP tokens from user to contract
        require(tokenInstance.transferFrom(msg.sender, address(this), balance), "TransferFrom failed");
        // Set release time and amount locked
        releaseTime = block.timestamp.add(lockDuration);
        amountLocked = balance;
        isLocked = true;
    }

    // Redeem LP tokens to the Treasury
    function redeem() external notRedeemed {
        // Check if release time has been reached
        require(block.timestamp >= releaseTime, "Tokens are still locked");
        // Get balance of this address for the LP token
        uint256 currentBalance = getThisBalance();
        // Transfer LP tokens from contract to user
        require(tokenInstance.transfer(treasury, currentBalance), "Transfer failed");
        // Set redeemed time
        redeemTime = block.timestamp;
        isLocked = false;
        amountLocked = 0;
    }
}