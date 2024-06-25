/**
 *Submitted for verification at Arbiscan.io on 2024-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPancakeAIPrediction {
    struct Round {
        uint32 startTimestamp; // type(uint32).max is equal to timestamp 4294967295(Sunday February 7 2106 6:28:15 AM), which will meet the requirement
        uint32 lockTimestamp;
        uint32 closeTimestamp;
        uint128 AIPrice;
        uint128 lockPrice;
        uint128 closePrice;
        uint128 totalAmount;
        uint128 bullAmount;
        uint128 bearAmount;
        uint128 rewardBaseCalAmount;
        uint128 rewardAmount;
        bool oracleCalled;
    }

    function rounds(uint256 _roundId) external view returns (Round memory);

    function genesisLockOnce() external view returns (bool);
    function genesisStartOnce() external view returns (bool);

    function currentEpoch() external view returns (uint256);
}

contract PancakeAIPredictionMonitor {
    IPancakeAIPrediction public immutable pancakeAIPrediction;

    constructor(IPancakeAIPrediction _pancakeAIPrediction) {
        pancakeAIPrediction = _pancakeAIPrediction;
    }

    // query how long the latest round is delayed
    function queryCurrentRoundDelay() public view returns (uint256 delay) {
        uint256 currentEpoch = pancakeAIPrediction.currentEpoch();
        if (currentEpoch != 0) {
            IPancakeAIPrediction.Round memory round = pancakeAIPrediction.rounds(currentEpoch);
            uint256 lockTimestamp = round.lockTimestamp;
            bool genesisLockOnce = pancakeAIPrediction.genesisLockOnce();
            bool genesisStartOnce = pancakeAIPrediction.genesisStartOnce();
            if (!genesisLockOnce && !genesisStartOnce && (lockTimestamp < block.timestamp)) {
                delay = block.timestamp - lockTimestamp;
            }
        }
    }
}