/**
 *Submitted for verification at Arbiscan on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingPoolFactory {
    function calStakingPoolApeXReward(address token) external view returns (uint256 reward, uint256 newPriceOfWeight);
}

interface IStakingPool {
    struct Deposit {
        uint256 amount;
        uint256 weight;
        uint256 lockFrom;
        uint256 lockDuration;
    }

    struct User {
        uint256 tokenAmount; //vest + stake
        uint256 totalWeight; //stake
        uint256 subYieldRewards;
        Deposit[] deposits; //stake slp/alp
        uint256  lastYieldRewardsPerWeight;
    }

    function yieldRewardsPerWeight() external view returns (uint256);

    function usersLockingWeight() external view returns (uint256);

    function REWARD_PER_WEIGHT_MULTIPLIER() external view returns (uint256);

    function users(address userAddr) external view returns (User memory);

    function factory() external view returns (IStakingPoolFactory);

    function poolToken() external view returns (address);
}

contract StakingPoolQueryReward {

    function pendingYieldRewards(address pool_, address staker_) external view returns (uint256 pending) {
        IStakingPool pool = IStakingPool(pool_);
        IStakingPoolFactory factory = pool.factory();
        address poolToken = pool.poolToken();
        uint256 yieldRewardsPerWeight = pool.yieldRewardsPerWeight();
        uint256 usersLockingWeight = pool.usersLockingWeight();
        uint256 REWARD_PER_WEIGHT_MULTIPLIER = pool.REWARD_PER_WEIGHT_MULTIPLIER();

        uint256 newYieldRewardsPerWeight = yieldRewardsPerWeight;

        if (usersLockingWeight != 0) {
            (uint256 apeXReward,) = factory.calStakingPoolApeXReward(poolToken);
            newYieldRewardsPerWeight += (apeXReward * REWARD_PER_WEIGHT_MULTIPLIER) / usersLockingWeight;
        }

        IStakingPool.User memory user = pool.users(staker_);
        pending = (user.totalWeight * (newYieldRewardsPerWeight - user.lastYieldRewardsPerWeight)) / REWARD_PER_WEIGHT_MULTIPLIER;
    }
}