/**
 *Submitted for verification at Arbiscan.io on 2024-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IMultiplier {
    /**
     * Applies a multiplier on the _amount, based on the _pool and _beneficiary.
     * The multiplier is not necessarily a constant number, it can be a more complex factor.
     */
    function applyMultiplier(uint256 _amount, uint256 _duration) external view returns (uint256);

    function getMultiplier(uint256 _amount, uint256 _duration) external view returns (uint256);

    function getDurationGroup(uint256 _duration) external view returns (uint256);

    function getDurationMultiplier(uint256 _duration) external view returns (uint256);
}

interface IPenaltyFee {
    /**
     * Calculates the penalty fee for the given _amount for a specific _beneficiary.
     */
    function calculate(
        uint256 _amount,
        uint256 _duration,
        address _pool
    ) external view returns (uint256);
}

interface IStakingPool {
    struct StakingInfo {
        uint256 stakedAmount; // amount of the stake
        uint256 minimumStakeTimestamp; // timestamp of the minimum stake
        uint256 duration; // in seconds
        uint256 rewardPerTokenPaid; // Reward per token paid
        uint256 rewards; // rewards to be claimed
    }

    function rewardsMultiplier() external view returns (IMultiplier);

    function penaltyFeeCalculator() external view returns (IPenaltyFee);

    event Staked(address indexed user, uint256 stakeNumber, uint256 amount);
    event Unstaked(address indexed user, uint256 stakeNumber, uint256 amount);
    event RewardPaid(address indexed user, uint256 stakeNumber, uint256 reward);
}

contract PenaltyFee is IPenaltyFee {
    uint256 public constant MULTIPLIER_BASIS = 1e4;
    uint256[] public penaltyFeePerGroup;

    constructor(uint256[] memory _penaltyFeePerGroup) {
        for (uint256 i = 0; i < _penaltyFeePerGroup.length; i++) {
            require(_penaltyFeePerGroup[i] < MULTIPLIER_BASIS, "PenaltyFee::constructor: penaltyBasis >= MAX_ALLOWED_PENALTY");
        }
        penaltyFeePerGroup = _penaltyFeePerGroup;
    }

    function calculate(
        uint256 _amount,
        uint256 _duration,
        address _pool
    ) external view override returns (uint256) {
        IMultiplier rewardsMultiplier = IStakingPool(_pool).rewardsMultiplier();
        uint256 group = rewardsMultiplier.getDurationGroup(_duration);
        return (_amount * penaltyFeePerGroup[group]) / MULTIPLIER_BASIS;
    }
}