/**
 *Submitted for verification at Arbiscan on 2023-07-31
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

contract SecurityCouncilNomineeElectionGovernor {
    function addContender(uint256 proposalId) external {
        return;
    }

    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual returns (uint256 balance) {
        return 1;
    }
}