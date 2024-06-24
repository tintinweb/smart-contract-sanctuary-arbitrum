// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 7
 * @dev Interface for GNSStaking contract
 */
interface IGNSStaking {
    struct Staker {
        uint128 stakedGns; // 1e18
        uint128 debtDai; // 1e18
    }

    struct RewardState {
        uint128 accRewardPerGns; // 1e18
        uint128 precisionDelta;
    }

    struct RewardInfo {
        uint128 debtToken; // 1e18
        uint128 __placeholder;
    }

    struct UnlockSchedule {
        uint128 totalGns; // 1e18
        uint128 claimedGns; // 1e18
        uint128 debtDai; // 1e18
        uint48 start; // block.timestamp (seconds)
        uint48 duration; // in seconds
        bool revocable;
        UnlockType unlockType;
        uint16 __placeholder;
    }

    struct UnlockScheduleInput {
        uint128 totalGns; // 1e18
        uint48 start; // block.timestamp (seconds)
        uint48 duration; // in seconds
        bool revocable;
        UnlockType unlockType;
    }

    enum UnlockType {
        LINEAR,
        CLIFF
    }

    function owner() external view returns (address);

    function distributeReward(address _rewardToken, uint256 _amountToken) external;

    function createUnlockSchedule(UnlockScheduleInput calldata _schedule, address _staker) external;

    event UnlockManagerUpdated(address indexed manager, bool authorized);

    event DaiHarvested(address indexed staker, uint128 amountDai);

    event RewardHarvested(address indexed staker, address indexed token, uint128 amountToken);
    event RewardHarvestedFromUnlock(
        address indexed staker,
        address indexed token,
        bool isOldDai,
        uint256[] ids,
        uint128 amountToken
    );
    event RewardDistributed(address indexed token, uint256 amount);

    event GnsStaked(address indexed staker, uint128 amountGns);
    event GnsUnstaked(address indexed staker, uint128 amountGns);
    event GnsClaimed(address indexed staker, uint256[] ids, uint128 amountGns);

    event UnlockScheduled(address indexed staker, uint256 indexed index, UnlockSchedule schedule);
    event UnlockScheduleRevoked(address indexed staker, uint256 indexed index);

    event RewardTokenAdded(address token, uint256 index, uint128 precisionDelta);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/IGNSStaking.sol";

interface IStaking {
    function totalGnsStaked(address) external view returns (uint128);
}

contract StakedBalanceStrategy {
    IStaking public immutable staking;

    constructor(IStaking _staking) {
        if (address(_staking) == address(0)) revert();

        staking = _staking;
    }

    function balanceOf(address user) external view returns (uint256) {
        return uint256(staking.totalGnsStaked(user));
    }
}