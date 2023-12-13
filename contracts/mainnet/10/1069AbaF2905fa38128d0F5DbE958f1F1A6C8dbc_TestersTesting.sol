/**
 *Submitted for verification at Arbiscan.io on 2023-12-12
*/

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.17;

interface IERC20 {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

contract TestersTesting {
    IERC20 public stakingToken = IERC20(0x1f9376607b1A25032B7fbe3e14b410554c319aFe);
    address public owner;
    uint public totalStaked;
    uint public globalDebtRatio;
    uint public minimumStake = 1000000 * 1e18; // 2500000 * 1e18 Minimum stake of 2.5 million tokens

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 stakingStartTime;
        uint256 userDebt;
        uint256 userStartDebtRatio;
    }

    mapping(address => StakerInfo) public stakers;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Update: Record global debt ratio per user at staking start
    function stake(uint amount) external {
        require(amount >= minimumStake, "Stake amount too low");
        updateRewards(msg.sender);
        if (stakers[msg.sender].stakedAmount == 0) {
            stakers[msg.sender].stakingStartTime = block.timestamp;
            stakers[msg.sender].userStartDebtRatio = globalDebtRatio;
        }
        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakers[msg.sender].stakedAmount += amount;
        totalStaked += amount;
    }

    function unstake(uint amount) external {
        updateRewards(msg.sender);
        require(stakers[msg.sender].stakedAmount >= amount, "Not enough tokens");
        stakers[msg.sender].stakedAmount -= amount;
        totalStaked -= amount;
        stakingToken.transfer(msg.sender, amount);
    }

    function claimRewards() external {
        updateRewards(msg.sender);
        uint owed = claimableRewards(msg.sender);
        stakers[msg.sender].userDebt = stakers[msg.sender].stakedAmount * globalDebtRatio;
        payable(msg.sender).transfer(owed);
    }

    fallback() external payable {
    if (totalStaked > 0) {
        // Scale msg.value to the same scale as totalStaked
        uint256 additionalDebt = (msg.value * 1e18) / totalStaked; 
        globalDebtRatio += additionalDebt;
    }
}

    receive() external payable {
        if (totalStaked > 0) {
        // Scale msg.value to the same scale as totalStaked
        uint256 additionalDebt = (msg.value * 1e18) / totalStaked; 
        globalDebtRatio += additionalDebt;
    }
    }

    function addRevenue() external payable {
        if (totalStaked > 0) {
            globalDebtRatio += msg.value / totalStaked;
        }
    }

    function updateRewards(address user) internal {
        uint owed = claimableRewards(user);
        if (owed > 0) {
            payable(user).transfer(owed);
        }
        stakers[user].userDebt = stakers[user].stakedAmount * globalDebtRatio / 1e18;
    }

    // Update: Calculate reward based on user debt ratio
    function claimableRewardsBase(address user) public view returns (uint) {
        uint256 userDebtAtStakeStart = stakers[user].userStartDebtRatio * stakers[user].stakedAmount / 1e18;
        uint256 currentDebt = globalDebtRatio * stakers[user].stakedAmount / 1e18;
        if(currentDebt < userDebtAtStakeStart) {
            return 0; // Handles the case where globalDebtRatio has decreased
        }
        return currentDebt - userDebtAtStakeStart;
    }

    // Update: Calculate reward based on user debt ratio with unlocked percentage
    function claimableRewards(address user) public view returns (uint) {
        uint256 baseOwed = claimableRewardsBase(user);
        uint256 unlockedPercentage = calculateUnlockedPercentage(user);
        return baseOwed * unlockedPercentage / 100;
    }

    function calculateUnlockedPercentage(address user) public view returns (uint256) {
        if (stakers[user].stakedAmount == 0) {
            return 0;
        }
        uint256 stakingDuration = block.timestamp - stakers[user].stakingStartTime;
        uint256 unlockedDays = stakingDuration / 1 days;
        uint256 unlockedPercentage = unlockedDays * 14;
        if (unlockedPercentage > 100) {
            unlockedPercentage = 100;
        }
        return unlockedPercentage;
    }

    function poolPercentage(address user) public view returns (uint) {
        if (totalStaked == 0) return 0;
        return (stakers[user].stakedAmount * 1e18) / totalStaked; // Multiplied by 1e18 for precision
    }

    // Owner can withdraw ETH from the contract
    function withdrawETH(uint amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner).transfer(amount);
    }

    // Owner can withdraw ERC20 tokens from the contract
    function withdrawERC20(uint amount) external onlyOwner {
        require(stakingToken.balanceOf(address(this)) >= amount, "Insufficient token balance");
        stakingToken.transfer(owner, amount);
    }

    function setTokenAddress(address newTokenAddress) external onlyOwner {
        stakingToken = IERC20(newTokenAddress);
    }
}