/**
 *Submitted for verification at Arbiscan on 2022-05-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract PollingEvents {
    event Votes(
        address voter,
        uint256[] indexed pollId,
        uint256[] indexed optionId,
        uint256 indexed signature
    );
}

contract Polling is PollingEvents {
    function vote(uint256[] calldata pollIds, uint256[] calldata optionIds, uint256 signature)
        external
    {
        require(pollIds.length == optionIds.length, "non-matching-length");
        emit Votes(msg.sender, pollIds, optionIds, signature);
    }
}