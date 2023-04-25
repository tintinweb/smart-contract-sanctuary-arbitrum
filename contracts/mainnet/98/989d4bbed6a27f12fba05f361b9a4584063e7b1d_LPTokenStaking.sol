// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./Ownable.sol";

contract LPTokenStaking is Ownable {
    IERC20 public lpToken;
    IERC20 public rewardToken;

    uint256 public rewardRate;

    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;

    uint256 public lastRewardTime;
    uint256 public accRewardPerShare;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(IERC20 _lpToken, IERC20 _rewardToken, uint256 totalReward, uint256 durationInDays) {
        lpToken = _lpToken;
        rewardToken = _rewardToken;
        lastRewardTime = block.timestamp;

        uint256 durationInSeconds = durationInDays * 1 days;
        rewardRate = totalReward / durationInSeconds;
    }

    function updatePool() internal {
        if (block.timestamp <= lastRewardTime) {
            return;
        }

        if (totalStaked == 0) {
            lastRewardTime = block.timestamp;
            return;
        }

        if(rewardToken.balanceOf(address(this)) == 0) {
            lastRewardTime = block.timestamp;
            return;
        }

        uint256 multiplier = block.timestamp - lastRewardTime;
        uint256 reward = multiplier * rewardRate;
        accRewardPerShare += (reward * 1e12) / totalStaked;
        lastRewardTime = block.timestamp;
    }

    function pendingReward(address _user) external view returns (uint256) {
        StakeInfo storage stake = stakes[_user];
        uint256 _accRewardPerShare = accRewardPerShare;

        if (block.timestamp > lastRewardTime && totalStaked > 0) {
            uint256 multiplier = block.timestamp - lastRewardTime;
            uint256 reward = multiplier * rewardRate;
            _accRewardPerShare += (reward * 1e12) / totalStaked;
        }

        return (stake.amount * _accRewardPerShare) / 1e12 - stake.rewardDebt;
    }

    function stake(uint256 _amount) external {
        updatePool();
        StakeInfo storage stake = stakes[msg.sender];

        if (stake.amount > 0) {
            uint256 pending = (stake.amount * accRewardPerShare) /
                1e12 -
                stake.rewardDebt;
            if (pending > 0) {
                rewardToken.transfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            lpToken.transferFrom(msg.sender, address(this), _amount);
            stake.amount += _amount;
            totalStaked += _amount;
        }

        stake.rewardDebt = (stake.amount * accRewardPerShare) / 1e12;
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        StakeInfo storage stake = stakes[msg.sender];
        require(stake.amount >= _amount, "withdraw: not enough LP tokens");

        updatePool();

        uint256 pending = (stake.amount * accRewardPerShare) /
            1e12 -
            stake.rewardDebt;

        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        uint256 claimableReward = pending <= rewardTokenBalance ? pending : rewardTokenBalance;

        if (claimableReward > 0) {
            rewardToken.transfer(msg.sender, claimableReward);
        }

        if (_amount > 0) {
            stake.amount -= _amount;
            totalStaked -= _amount;
            lpToken.transfer(msg.sender, _amount);
        }

        stake.rewardDebt = (stake.amount * accRewardPerShare) / 1e12;
        emit Withdrawn(msg.sender, _amount);
    }

    function claimReward() external {
        updatePool();
        StakeInfo storage stake = stakes[msg.sender];

        uint256 pending = (stake.amount * accRewardPerShare) /
            1e12 -
            stake.rewardDebt;
        
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        uint256 claimableReward = pending <= rewardTokenBalance ? pending : rewardTokenBalance;

        if (claimableReward > 0) {
            rewardToken.transfer(msg.sender, claimableReward);
        }

        stake.rewardDebt = (stake.amount * accRewardPerShare) / 1e12;
        emit RewardClaimed(msg.sender, pending);
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        updatePool();
        rewardRate = _rewardRate;
    }
}