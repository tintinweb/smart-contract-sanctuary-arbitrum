/**
 *Submitted for verification at Arbiscan.io on 2024-01-10
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

interface IReferee {
    function claimReward(uint256 _nodeLicenseId, uint256 _challengeId) external;
    struct Submission {
        bool submitted;
        bool claimed;
        bool eligibleForPayout;
        uint256 nodeLicenseId;
        bytes assertionStateRootOrConfirmData;
    }
    function submissions(uint256 challengeId, uint256 nodeLicenseId) external view returns (Submission memory);
}


contract EsXAIClaim {
    event Claim(uint256 indexed nodeId, uint256 indexed challangeId);
    address rewarder = address(0xfD41041180571C5D371BEA3D9550E55653671198);

    constructor() {}

    function batchClaim(
        uint256[] calldata nodeIds,
        uint256[] calldata challengeIds
    ) external {
        require(nodeIds.length == challengeIds.length, "invalid params");
        for (uint256 i = 0; i < nodeIds.length; i++) {
            if (IReferee(rewarder).submissions(nodeIds[i], challengeIds[i]).claimed) {
                continue;
            }
            IReferee(rewarder).claimReward(
                nodeIds[i],
                challengeIds[i]
            );
            emit Claim(nodeIds[i], challengeIds[i]);
        }
    }
}