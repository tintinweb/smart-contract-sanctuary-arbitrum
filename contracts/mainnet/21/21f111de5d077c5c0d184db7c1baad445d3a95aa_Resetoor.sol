/**
 *Submitted for verification at Arbiscan.io on 2024-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICC {
    function resetVotes(uint256[] calldata tokenIDs) external;
}
error NotOwner();

contract Resetoor {
    address public owner;
    ICC public commandCenter;

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address _commandCenter) {
        commandCenter = ICC(_commandCenter);
        owner = msg.sender;
    }

    ///@dev reset dead NFTs, right after epoch flip to prevent dead emissions accrual
    function batchReset(uint256 rangeOne, uint256 rangeTwo) external onlyOwner {
        uint256[] memory currentIDs = new uint256[](rangeTwo - rangeOne);
        for (uint256 i = rangeOne; i < rangeTwo; ++i) {
            currentIDs[i] = i;
        }
        commandCenter.resetVotes(currentIDs);
    }

    ///@dev reset dead NFTs 1 by 1
    function directBatchReset(uint256 rangeOne, uint256 rangeTwo)
        external
        onlyOwner
    {
        uint256[] memory currentIDs = new uint256[](1);
        for (uint256 i = rangeOne; i < rangeTwo; ++i) {
            currentIDs[0] = i;
            commandCenter.resetVotes(currentIDs);
        }
    }
}