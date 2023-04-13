/**
 *Submitted for verification at Arbiscan on 2023-04-13
*/

//Official Swaptrum Staking Contract - Version 1.3 - 13.04.2023

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Token {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract SwaptrumStakingContract {
    address public immutable TOKEN;
    uint256 public immutable MIN_LOCKUP_DAYS = 30;
    uint256 public immutable MAX_LOCKUP_DAYS = 120;
    uint256 public constant MAX_APY = 2000; // max APY is 2000 (20%)
    address public owner;
    uint256 public rewardRate;

    struct Staker {
        mapping(uint256 => uint256) stakedAmount;
        mapping(uint256 => uint256) reward;
        mapping(uint256 => uint256) lastUpdated;
        mapping(uint256 => uint256) unlockTime;
    }

    struct Pool {
        uint256 lockupDays;
        uint256 apy;
        uint256 totalStaked;
        mapping(address => Staker) stakers;
    }

    mapping(uint256 => Pool) public pools;
    mapping(address => Staker) private stakers;

    event Staked(address indexed staker, uint256 amount, uint256 poolId);
    event Unstaked(address indexed staker, uint256 amount, uint256 poolId);
    event RewardsClaimed(address indexed staker, uint256 amount, uint256 poolId);

    constructor(address _token, uint256 _rewardRate) {
        TOKEN = _token;
        owner = msg.sender;
        rewardRate = _rewardRate;

        // add supported pools
        pools[1].lockupDays = 30;
        pools[1].apy = 50;
        pools[1].totalStaked = 0;

        pools[2].lockupDays = 60;
        pools[2].apy = 100;
        pools[2].totalStaked = 0;

        pools[3].lockupDays = 90;
        pools[3].apy = 150;
        pools[3].totalStaked = 0;

        pools[4].lockupDays = 120;
        pools[4].apy = 200;
        pools[4].totalStaked = 0;
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        require(_rewardRate <= MAX_APY, "Reward rate too high");
        rewardRate = _rewardRate;
    }

    function approveTokens(uint256 amount) external {
        require(amount > 0, "Approval amount must be greater than 0");
        Token(0x620dA86403F5f9F8774454d6BB785A461f608C0E).approve(address(this), amount);
    }


    function stake(uint256 amount, uint256 poolId) external {
        require(poolId >= 1 && poolId <= 4, "Invalid pool ID");
        Pool storage pool = pools[poolId];

        require(amount > 0, "Staking amount must be greater than 0");
        require(Token(TOKEN).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // update staker's rewards in the pool they are staking
        updateRewards(msg.sender, poolId);

        Staker storage staker = pool.stakers[msg.sender];

        staker.stakedAmount[poolId] = amount;
        staker.lastUpdated[poolId] = block.timestamp;
        staker.unlockTime[poolId] = block.timestamp + (pool.lockupDays * 1 days);
        pool.totalStaked += amount;

        emit Staked(msg.sender, amount, poolId);
    }

    function unstake(uint256 poolId) external {
        require(poolId >= 1 && poolId <= 4, "Invalid pool ID");

        Pool storage pool = pools[poolId];
        Staker storage staker = pool.stakers[msg.sender];

        require(block.timestamp >= staker.unlockTime[poolId], "Staking period has not ended yet");

        updateRewards(msg.sender, poolId);

        uint256 stakedAmount = staker.stakedAmount[poolId];
        require(stakedAmount > 0, "No staked amount");

        uint256 reward = getRewards(msg.sender, poolId);

        staker.stakedAmount[poolId] = 0;
        pool.totalStaked -= stakedAmount;
        require(Token(TOKEN).transfer(msg.sender, stakedAmount), "Transfer failed");

        emit Unstaked(msg.sender, stakedAmount, poolId);
    }

    function claimRewards(uint256 poolId) external {
        require(poolId >= 1 && poolId <= 4, "Invalid pool ID");

        updateRewards(msg.sender, poolId);

        uint256 reward = getRewards(msg.sender, poolId);
        require(reward > 0, "No rewards available");

        Staker storage staker = pools[poolId].stakers[msg.sender];
        staker.reward[poolId] = 0;
        require(Token(TOKEN).transfer(msg.sender, reward), "Transfer failed");

        emit RewardsClaimed(msg.sender, reward, poolId);
    }

    function updateRewards(address stakerAddress, uint256 poolId) private {
        Staker storage staker = pools[poolId].stakers[stakerAddress];
        Pool storage pool = pools[poolId];

        uint256 elapsedTime = block.timestamp - staker.lastUpdated[poolId];
        uint256 newReward = staker.stakedAmount[poolId] * elapsedTime * pool.apy / 365 days;
        staker.reward[poolId] += newReward;
        staker.lastUpdated[poolId] = block.timestamp;
    }

    function updateAllRewards(address stakerAddress) private {
        for (uint256 i = 1; i <= 4; i++) {
            Staker storage staker = pools[i].stakers[stakerAddress];
            Pool storage pool = pools[i];

            uint256 elapsedTime = block.timestamp - staker.lastUpdated[i];
            uint256 newReward = staker.stakedAmount[i] * elapsedTime * pool.apy / 365 days;
            staker.reward[i] += newReward;
            staker.lastUpdated[i] = block.timestamp;
        }
    }

    function getRewards(address stakerAddress, uint256 poolId) public view returns (uint256) {
        Staker storage staker = pools[poolId].stakers[stakerAddress];
        Pool storage pool = pools[poolId];
        uint256 elapsedTime = block.timestamp - staker.lastUpdated[poolId];
        uint256 newReward = staker.stakedAmount[poolId] * elapsedTime * pool.apy / 365 days;
        return staker.reward[poolId] + newReward;
    }

    function getStaker(address stakerAddress, uint256 poolId) internal view returns (Staker storage) {
        return pools[poolId].stakers[stakerAddress];
    }

    function getStakerStakedAmount(address stakerAddress, uint256 poolId) public view returns (uint256) {
        return getStaker(stakerAddress, poolId).stakedAmount[poolId];
    }

    function getStakerReward(address stakerAddress, uint256 poolId) public view returns (uint256) {
        return getStaker(stakerAddress, poolId).reward[poolId];
    }

    function getStakerLastUpdated(address stakerAddress, uint256 poolId) public view returns (uint256) {
        return getStaker(stakerAddress, poolId).lastUpdated[poolId];
    }

    function getStakerUnlockTime(address stakerAddress, uint256 poolId) public view returns (uint256) {
        return getStaker(stakerAddress, poolId).unlockTime[poolId];
    }

    function withdrawTokens() external onlyOwner {
        uint256 balance = Token(TOKEN).balanceOf(address(this));
        require(Token(TOKEN).transfer(msg.sender, balance), "Transfer failed");
    }

    function setPoolLockup(uint8 poolIndex, uint256 lockup) external onlyOwner {
        require(poolIndex < 5, "Invalid pool index");
        pools[poolIndex].lockupDays = lockup;
    }

    function setPoolAPY(uint8 poolIndex, uint256 apy) external onlyOwner {
        require(poolIndex < 5, "Invalid pool index");
        require(apy <= MAX_APY, "APY too high");
        pools[poolIndex].apy = apy;
    }

    function getTotalStakedTokens() public view returns (uint256) {
        uint256 totalStaked = 0;
        for (uint256 i = 1; i <= 4; i++) {
            totalStaked += pools[i].totalStaked;
        }
        return totalStaked;
    }

    function getCurrentPoolAPY(uint256 poolId) public view returns (uint256) {
        require(poolId >= 1 && poolId <= 4, "Invalid pool ID");
        uint256 poolTotalStaked = pools[poolId].totalStaked;
        uint256 contractBalance = Token(TOKEN).balanceOf(address(this));
        if (contractBalance == 0 || poolTotalStaked == 0) {
            return 0;
        }
        uint256 poolPercentage = (poolTotalStaked * 100) / contractBalance;
        return (rewardRate * poolPercentage) / 100;
    }

    function getTokensStakedInPool(uint256 poolId) public view returns (uint256) {
        require(poolId >= 1 && poolId <= 4, "Invalid pool ID");
        return pools[poolId].totalStaked;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
}