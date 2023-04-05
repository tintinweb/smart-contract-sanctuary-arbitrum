/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}

contract LockLPTokens {
    using SafeMath for uint256;

    address owner;

    struct LockInfo {
        uint256 amount;
        uint256 releaseTime;
        bool redeemed;
    }

    mapping(address => mapping(address => LockInfo)) public lockedTokens;

    constructor() {
        owner = msg.sender;
    }

    // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function lock(address lpToken, uint256 amount, uint256 lockDuration) external onlyOwner {
        require(amount * lockDuration > 0, "Amount and lock duration cannot be zero");
        IERC20 lpTokenInstance = IERC20(lpToken);
        require(lpTokenInstance.allowance(msg.sender, address(this)) >= amount);
        // Transfer LP tokens from user to contract
        require(lpTokenInstance.transferFrom(msg.sender, address(this), amount), "TransferFrom failed");
        // Calculate release time based on lock duration (seconds)
        uint256 releaseTime = block.timestamp.add(lockDuration);
        // Store locked token information
        lockedTokens[msg.sender][lpToken].amount += amount;
        lockedTokens[msg.sender][lpToken].releaseTime = releaseTime;
        lockedTokens[msg.sender][lpToken].redeemed = false;
    }

    function redeem(address lpToken) external onlyOwner {
        require(lockedTokens[msg.sender][lpToken].amount > 0, "No locked tokens");
        // Check if release time has been reached
        require(block.timestamp >= lockedTokens[msg.sender][lpToken].releaseTime, "Tokens are still locked");
        // Check if tokens have already been redeemed
        require(!lockedTokens[msg.sender][lpToken].redeemed, "Tokens already redeemed");
        // Set redeemed flag to true
        lockedTokens[msg.sender][lpToken].redeemed = true;
        // Transfer LP tokens from contract to user
        IERC20 lpTokenInstance = IERC20(lpToken);
        require(lpTokenInstance.transfer(owner, lockedTokens[msg.sender][lpToken].amount), "Transfer failed");
    }
}