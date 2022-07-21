// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAtlasMine.sol";

library BattleflyAtlasStakerUtils {
    /**
     * @dev Get lock period
     *      Need to consider about adding 1 more day to lock period regarding the daily cron job
     */
    function getLockPeriod(IAtlasMine.Lock _lock, IAtlasMine ATLAS_MINE) external pure returns (uint64) {
        if (_lock == IAtlasMine.Lock.twoWeeks) {
            return 14 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.oneMonth) {
            return 30 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.threeMonths) {
            return 90 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.sixMonths) {
            return 180 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.twelveMonths) {
            return 365 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }

        revert("BattleflyAtlasStaker: Invalid Lock");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IAtlasMine {
    enum Lock {
        twoWeeks,
        oneMonth,
        threeMonths,
        sixMonths,
        twelveMonths
    }
    struct UserInfo {
        uint256 originalDepositAmount;
        uint256 depositAmount;
        uint256 lpAmount;
        uint256 lockedUntil;
        uint256 vestingLastUpdate;
        int256 rewardDebt;
        Lock lock;
    }

    function treasure() external view returns (address);

    function legion() external view returns (address);

    function unlockAll() external view returns (bool);

    function boosts(address user) external view returns (uint256);

    function userInfo(address user, uint256 depositId)
        external
        view
        returns (
            uint256 originalDepositAmount,
            uint256 depositAmount,
            uint256 lpAmount,
            uint256 lockedUntil,
            uint256 vestingLastUpdate,
            int256 rewardDebt,
            Lock lock
        );

    function getLockBoost(Lock _lock) external pure returns (uint256 boost, uint256 timelock);

    function getVestingTime(Lock _lock) external pure returns (uint256 vestingTime);

    function stakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function unstakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function stakeLegion(uint256 _tokenId) external;

    function unstakeLegion(uint256 _tokenId) external;

    function withdrawPosition(uint256 _depositId, uint256 _amount) external returns (bool);

    function withdrawAll() external;

    function pendingRewardsAll(address _user) external view returns (uint256 pending);

    function deposit(uint256 _amount, Lock _lock) external;

    function harvestAll() external;

    function harvestPosition(uint256 _depositId) external;

    function currentId(address _user) external view returns (uint256);

    function pendingRewardsPosition(address _user, uint256 _depositId) external view returns (uint256);

    function getAllUserDepositIds(address) external view returns (uint256[] memory);
}