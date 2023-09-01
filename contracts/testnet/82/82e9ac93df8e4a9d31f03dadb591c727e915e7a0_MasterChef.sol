// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IMasterChef} from "./interfaces/IMasterChef.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract MasterChef is IMasterChef {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }
    uint256 public constant MAX_REWARD_PER_BLOCK = 100 ether;
    uint256 public constant PRECISION = 1e12;

    IERC20 public lpToken;

    IERC20 public rewardToken;

    uint256 public accumulatedRewardsPerShare = 0;

    uint256 public lastRewardBlock = 0;

    uint256 public rewardPerBlock = 1 ether;

    address public owner;

    mapping (address => UserInfo) public userInfo;

    constructor(IERC20 _lpToken, IERC20 _rewardToken) {
        require(address(_lpToken) != address(0), "Invalid lpToken");
        require(address(_rewardToken) != address(0), "Invalid rewardToken");

        owner = msg.sender;
        lpToken = _lpToken;
        rewardToken = _rewardToken;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Only owner");

        owner = newOwner;
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external {
        require(msg.sender == owner, "Only owner");
        require(_rewardPerBlock <= MAX_REWARD_PER_BLOCK, "Invalid rewardPerBlock");
        _updateAccumulatedRewardsPerShare();
        rewardPerBlock = _rewardPerBlock;
        emit RewardPerBlockUpdated(_rewardPerBlock);
    }

    function deposit(address to, uint256 amount) external {
        _updateAccumulatedRewardsPerShare();

        UserInfo memory user = userInfo[to];

        user.amount += amount;
        user.rewardDebt += int256(amount * accumulatedRewardsPerShare / PRECISION);
        userInfo[to] = user;

        lpToken.transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, to, amount);
    }

    function withdraw(address to, uint256 amount) external {
        UserInfo memory user = userInfo[msg.sender];

        require(amount <= user.amount, "Invalid amount");

        _updateAccumulatedRewardsPerShare();

        user.rewardDebt -= int256(amount * accumulatedRewardsPerShare / PRECISION);
        user.amount -= amount;
        userInfo[msg.sender] = user;

        lpToken.transfer(to, amount);

        emit Withdraw(msg.sender, to, amount);
    }

    function emergencyWithdraw(address to) external {
        UserInfo memory user = userInfo[msg.sender];

        uint256 amount = user.amount;

        user.amount = 0;
        user.rewardDebt = 0;
        userInfo[msg.sender] = user;

        lpToken.transfer(to, amount);

        emit EmergencyWithdraw(msg.sender, to, amount);
    }

    function claim(address to) external {
        _updateAccumulatedRewardsPerShare();

        UserInfo storage user = userInfo[msg.sender];

        int256 accumulatedRewards = int256(user.amount * accumulatedRewardsPerShare / PRECISION);

        int256 rewards = accumulatedRewards - user.rewardDebt;

        uint256 amount = rewards < 0 ? 0 : uint256(rewards);

        user.rewardDebt = accumulatedRewards;

        rewardToken.transfer(to, amount);

        emit Claim(msg.sender, to, amount);
    }

    function claimable(address account) external view returns (uint256) {
        UserInfo memory user = userInfo[account];
        uint256 _accumulatedRewardsPerShare = accumulatedRewardsPerShare;

        uint256 _elapsedBlock = block.number - lastRewardBlock;
        if (_elapsedBlock > 0) {
            uint256 _lpSupply = lpToken.balanceOf(address(this));
            if (_lpSupply > 0) {
                _accumulatedRewardsPerShare += _elapsedBlock * rewardPerBlock * PRECISION / _lpSupply;
            }
        }

        int256 accumulatedRewards = int256(user.amount * _accumulatedRewardsPerShare / PRECISION);

        int256 rewards = accumulatedRewards - user.rewardDebt;

        return rewards < 0 ? 0 : uint256(rewards);
    }

    function _updateAccumulatedRewardsPerShare() private {
        uint256 _elapsedBlock = block.number - lastRewardBlock;

        if (_elapsedBlock > 0) {
            uint256 _lpSupply = lpToken.balanceOf(address(this));

            if (_lpSupply > 0) {
                accumulatedRewardsPerShare += _elapsedBlock * rewardPerBlock * PRECISION / _lpSupply;
            }

            lastRewardBlock = block.number;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IMasterChef {
    function setRewardPerBlock(uint256 rewardPerBlock) external;
    function deposit(address to, uint256 amount) external;
    function withdraw(address to, uint256 amount) external;
    function emergencyWithdraw(address to) external;
    function claim(address to) external;
    function claimable(address account) external view returns (uint256);

    event RewardPerBlockUpdated(uint256 rewardPerBlock);
    event Deposit(address indexed user, address indexed to, uint256 amount);
    event Withdraw(address indexed user, address indexed to, uint256 amount);
    event EmergencyWithdraw(address indexed user, address indexed to, uint256 amount);
    event Claim(address indexed user, address indexed to, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}