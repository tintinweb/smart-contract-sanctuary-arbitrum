/**
 *Submitted for verification at Arbiscan on 2023-04-16
*/

// Official Swaptrum Locking Contract

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract TokenLock is Ownable {
    IERC20 public token;
    uint256 public lockPeriod = 365 days;
    uint256 public unlockInterval = 30 days;
    uint256 public unlockPercentage = 10;

    struct DepositInfo {
        uint256 amount;
        uint256 lastUnlock;
    }

    mapping(address => DepositInfo) public deposits;

    constructor(IERC20 _token) {
        token = _token;
    }

    function depositTokens(uint256 _amount) external {
        require(_amount > 0, "Amount should be greater than 0");

        uint256 decimals = 18; // Replace with the actual number of decimals for your token
        uint256 tokenAmount = _amount * (10 ** decimals);

        token.transferFrom(msg.sender, address(this), tokenAmount);

        DepositInfo storage depositInfo = deposits[msg.sender];
        depositInfo.amount = depositInfo.amount + tokenAmount;
        depositInfo.lastUnlock = block.timestamp;
    }


    function claimUnlockedTokens() external {
        DepositInfo storage depositInfo = deposits[msg.sender];
        require(depositInfo.amount > 0, "No locked tokens");

        uint256 unlockTimePassed = block.timestamp - depositInfo.lastUnlock;
        require(unlockTimePassed >= unlockInterval, "Unlock interval not reached");

        uint256 unlockTimes = unlockTimePassed / unlockInterval;
        uint256 unlockedAmount = depositInfo.amount * (unlockPercentage * unlockTimes) / 100;
        
        depositInfo.amount = depositInfo.amount - unlockedAmount;
        depositInfo.lastUnlock = depositInfo.lastUnlock + (unlockInterval * unlockTimes);

        token.transfer(msg.sender, unlockedAmount);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 contractBalance = token.balanceOf(address(this));
        token.transfer(owner(), contractBalance);
    }

    function increaseLockPeriod(uint256 _extraDays) external onlyOwner {
        lockPeriod += _extraDays * 1 days;
    }

    function decreaseUnlockPercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage < unlockPercentage, "New percentage should be smaller than current percentage");
        unlockPercentage = _newPercentage;
    }

    function getNextUnlockInfo(address _user) external view returns (uint256 nextUnlockTime, uint256 nextUnlockAmount) {
        DepositInfo storage depositInfo = deposits[_user];
        if (depositInfo.amount == 0) {
            return (0, 0);
        }

        uint256 unlockTimePassed = block.timestamp - depositInfo.lastUnlock;
        if (unlockTimePassed < unlockInterval) {
            nextUnlockTime = depositInfo.lastUnlock + unlockInterval;
        } else {
            uint256 unlockTimes = unlockTimePassed / unlockInterval;
            nextUnlockTime = depositInfo.lastUnlock + (unlockInterval * (unlockTimes + 1));
        }

        nextUnlockAmount = depositInfo.amount * unlockPercentage / 100;
    }
}