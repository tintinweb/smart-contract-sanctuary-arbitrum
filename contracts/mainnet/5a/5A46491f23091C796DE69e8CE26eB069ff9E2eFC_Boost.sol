// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {Constants} from "./Constants.sol";
import {IBoost} from "./IBoost.sol";
import {IRewards} from "./IRewards.sol";
import {Allowed} from "./Allowed.sol";

contract Boost is IBoost, Allowed {
    LockSetting[] public lockSettings;
    mapping(address => LockStatus) public userLockStatus;
    address[] public rewardStores;

    struct LockSetting {
        uint256 duration;
        uint256 miningBoost;
    }

    struct LockStatus {
        uint256 unlockTime;
        uint256 duration;
        uint256 miningBoost;
    }

    constructor() Allowed(msg.sender){
        lockSettings.push(LockSetting(Constants.SETTING_1_LOCK_PERIOD, Constants.SETTING_1_BOOST));
        lockSettings.push(LockSetting(Constants.SETTING_2_LOCK_PERIOD, Constants.SETTING_2_BOOST));
        lockSettings.push(LockSetting(Constants.SETTING_3_LOCK_PERIOD, Constants.SETTING_3_BOOST));
        lockSettings.push(LockSetting(Constants.SETTING_4_LOCK_PERIOD, Constants.SETTING_4_BOOST));
    }

    function addLockSetting(LockSetting memory setting) external onlyOwner {
        lockSettings.push(setting);
    }

    function addRS(address _rs) external onlyOwner {
        require(_rs != address(0) && _rs != address(this), "Boost: Invalid address");
        rewardStores.push(_rs);
    }

    function removeRS(uint index) external onlyOwner{
        require(index <= rewardStores.length -1, "Boost: index out of bounds");
        rewardStores[index] = rewardStores[rewardStores.length - 1];
        rewardStores.pop();
    }

    function updateRewards(address user) internal {
        for(uint i=0; i<rewardStores.length ; i++) {
            IRewards(rewardStores[i]).refreshReward(user);
        }
    }

    function getRSSize() external view returns (uint256) {
        return rewardStores.length ;
    }

    function setLockStatus(uint256 id) external {
        address _user = msg.sender;
        updateRewards(_user);
        LockSetting memory _setting = lockSettings[id];
        LockStatus memory userStatus = userLockStatus[_user];
        if (userStatus.unlockTime > block.timestamp) {
            require(
                userStatus.duration <= _setting.duration,
                "Boost: Your lock-in period has not ended, and the term can only be extended, not reduced."
            );
        }
        userLockStatus[_user] = LockStatus(
            block.timestamp + _setting.duration,
            _setting.duration,
            _setting.miningBoost
        );
    }
    
    function getUnlockTime(address user) external view returns (uint256 unlockTime) {
        unlockTime = userLockStatus[user].unlockTime;
    }

    function getUserBoost(address user, uint256 userUpdatedAt, uint256 finishAt) external view returns (uint256) {
        uint256 boostEndTime = userLockStatus[user].unlockTime;
        uint256 maxBoost = userLockStatus[user].miningBoost;
        if (userUpdatedAt >= boostEndTime || userUpdatedAt >= finishAt) {
            return 0;
        }
        if (finishAt <= boostEndTime || block.timestamp <= boostEndTime) {
            return maxBoost;
        } else {
            uint256 time = block.timestamp > finishAt
                ? finishAt
                : block.timestamp;
            return
                ((boostEndTime - userUpdatedAt) * maxBoost) /
                (time - userUpdatedAt);
        }
    }
}