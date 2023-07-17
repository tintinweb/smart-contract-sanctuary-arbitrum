// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {IERC20} from "./IERC20.sol";
import {IMeta} from "./IMeta.sol";
import {IBoost} from "./IBoost.sol";
import {IMetaManager} from "./IMetaManager.sol";
import {IMUSDManager} from "./IMUSDManager.sol";
import {IMeta} from "./IMeta.sol";
import {Allowed} from "./Allowed.sol";

import {Constants} from "./Constants.sol";

contract MintRewards is Allowed {
    // Tokens
    IMUSDManager public mUSDManager;
    IMeta public immutable esMeta;

    // Contract levelt
    IBoost public boost;
    IMetaManager public metaMgr;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration = Constants.REWARDS_PAYOUT_PERIOD;

    // Reward vault level
    uint256 public finishAt;
    uint256 public updatedAt;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;

    // User level variables
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userUpdatedAt;
    uint256 public extraRate = Constants.REDEEMER_BOOST_RATE;

    constructor(
        address _mUSDManager,
        address _boost,
        address _metaMgr,
        address _esMeta
    ) Allowed(msg.sender) {
        mUSDManager = IMUSDManager(_mUSDManager);
        boost = IBoost(_boost);
        esMeta = IMeta(_esMeta);
        metaMgr = IMetaManager(_metaMgr);
    }

    function setExtraRate(uint256 rate) external onlyOwner {
        extraRate = rate;
    }

    function setBoost(address _boost) external onlyOwner {
        require(_boost != address(0), "MR: Invalid boost"); 
        boost = IBoost(_boost);
    }

    function setMetaManager(address _metaManager) external onlyOwner {
        require(_metaManager != address(0), "MR: Invalid meta manager");
        metaMgr = IMetaManager(_metaManager);
    }

    function setMUSDManager(address _mUSDManager) external onlyOwner {
        require(_mUSDManager != address(0), "MR: Invalid meta manager");
        mUSDManager = IMUSDManager(_mUSDManager);
    } 

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(_duration > 1 days && finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function totalStaked() internal view returns (uint256) {
        return mUSDManager.totalSupply();
    }

    function stakedOf(address user) public view returns (uint256) {
        return mUSDManager.getBorrowedOf(user);
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
            userUpdatedAt[_account] = block.timestamp;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked() == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalStaked();
    }

    // Function to refresh the rewards, not other actions to be performed
    function refreshReward(address _account) external updateReward(_account) {}

    function getBoost(address _account) public view returns (uint256) {
        uint256 redemptionBoost;
        if (mUSDManager.isRedemptionProvider(_account)) {
            redemptionBoost = extraRate;
        }
        return
            100 *
            Constants.PINT +
            redemptionBoost +
            boost.getUserBoost(
                _account,
                userUpdatedAt[_account],
                finishAt
            );
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((stakedOf(_account) *
                getBoost(_account) *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e38) +
            rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        require(
            block.timestamp >= boost.getUnlockTime(msg.sender),
            "Your lock-in period has not ended. You can't claim your esMETA now."
        );
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            metaMgr.refreshReward(msg.sender);
            esMeta.mint(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 amount) external onlyOwner updateReward(address(0)) {
        require(amount > 0, "amount = 0");
        if (block.timestamp >= finishAt) {
            rewardRate = amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) *
                rewardRate;
            rewardRate = (amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}