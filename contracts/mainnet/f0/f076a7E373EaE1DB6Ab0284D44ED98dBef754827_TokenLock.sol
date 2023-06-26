/**
 *Submitted for verification at Arbiscan on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract TokenLock {
    struct Lock {
        address tokenAddress;
        uint256 lockTimestamp;
        uint256 lockDuration;
        uint256 amount;
    }

    mapping(address => Lock[]) public userLocks;

    function depositTokens(
        address tokenAddress,
        uint256 lockDuration,
        uint256 amount
    ) external {
        require(lockDuration > 0, "Lock duration must be greater than zero");

        IERC20 token = IERC20(tokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient token allowance");

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );

        Lock memory newLock = Lock(tokenAddress, block.timestamp, lockDuration, amount);
        userLocks[msg.sender].push(newLock);
    }

    function withdrawTokens(uint256 index) external {
        Lock[] storage locks = userLocks[msg.sender];
        require(index < locks.length, "Invalid lock index");

        Lock storage senderLock = locks[index];
        require(senderLock.amount > 0, "No tokens to withdraw");
        require(
            block.timestamp >= senderLock.lockTimestamp + senderLock.lockDuration,
            "Lock duration has not passed yet"
        );

        IERC20 token = IERC20(senderLock.tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= senderLock.amount, "Insufficient token balance");

        require(token.transfer(msg.sender, senderLock.amount), "Token transfer failed");

        senderLock.amount = 0;
    }

    function getRemainingLockTime(address depositor, uint256 index) public view returns (uint256) {
        Lock[] storage locks = userLocks[depositor];
        require(index < locks.length, "Invalid lock index");

        Lock storage senderLock = locks[index];
        if (block.timestamp >= senderLock.lockTimestamp + senderLock.lockDuration) {
            return 0;
        } else {
            return senderLock.lockTimestamp + senderLock.lockDuration - block.timestamp;
        }
    }

    function getUserLocksCount(address depositor) public view returns (uint256) {
        return userLocks[depositor].length;
    }
}