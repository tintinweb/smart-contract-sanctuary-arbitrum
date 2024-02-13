// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MateRewards {
    IERC20 public immutable rewardsToken;
    address public immutable stakingContract;

    address public owner;

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint) public rewards;

    // Total staked
    uint public totalSupply;
    // User address => staked amount
    mapping(address => uint) public balanceOf;

    bool public recoverDisabled = false;

    constructor(address _stakingContract, address _rewardToken) {
        owner = msg.sender;
        rewardsToken = IERC20(_rewardToken);
        stakingContract = _stakingContract;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier onlyStakingContract() {
        require(msg.sender == stakingContract, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function stake(uint _amount, address wallet) external updateReward(wallet) onlyStakingContract {
        require(_amount > 0, "amount = 0");
        balanceOf[wallet] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount, address wallet) external updateReward(wallet) onlyStakingContract {
        require(_amount > 0, "amount = 0");
        balanceOf[wallet] -= _amount;
        totalSupply -= _amount;
    }

    function claimable(address wallet) external view returns (uint) {
        return earned(wallet) - rewards[wallet];
    }

    function estimateRewards(uint _amount, uint _timeToStake) public view returns (uint) {
        if(totalSupply == 0) {
            return 0; // If there's no staking, no rewards can be earned.
        }

        // Calculate the new total supply as if the amount was staked
        uint newTotalSupply = totalSupply + _amount;

        // Calculate reward per token at the start of staking
        uint initialRewardPerToken = rewardPerToken();

        // Simulate the reward per token at the end of the staking period
        uint finalRewardPerToken = initialRewardPerToken + (rewardRate * _timeToStake * 1e18) / newTotalSupply;

        // Calculate the total rewards earned for the staked amount over the specified time period
        uint earnedRewards = (_amount * (finalRewardPerToken - initialRewardPerToken)) / 1e18;

        return earnedRewards;
    }

    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function getReward(address wallet) external updateReward(wallet) onlyStakingContract {
        uint reward = rewards[wallet];
        if (reward > 0) {
            rewards[wallet] = 0;
            rewardsToken.transfer(wallet, reward);
        }
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(
        uint _amount
    ) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function recoverERC20(address tokenAddress, uint tokenAmount) external onlyOwner {
        require(!recoverDisabled, "Recover disabled");

        IERC20(tokenAddress).transfer(owner, tokenAmount);
    }

    function disableRecover() external onlyOwner {
        recoverDisabled = true;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}