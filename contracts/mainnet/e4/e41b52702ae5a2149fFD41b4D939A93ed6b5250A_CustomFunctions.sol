/**
 *Submitted for verification at Arbiscan on 2023-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CustomFunctions {
    address private owner;
    event MoonMissionPrepared();
    event StakingRewardsStarted();
    event GovernanceVotingEnabled();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the Memelord can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function prepareMoonMission() public onlyOwner {
        emit MoonMissionPrepared();
    }

    function startStakingRewards() public onlyOwner {
        emit StakingRewardsStarted();
    }

    function enableGovernanceVoting() public onlyOwner {
        emit GovernanceVotingEnabled();
    }
}