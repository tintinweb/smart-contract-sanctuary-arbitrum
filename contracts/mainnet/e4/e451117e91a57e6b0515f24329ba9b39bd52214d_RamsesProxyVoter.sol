/**
 *Submitted for verification at Arbiscan.io on 2023-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IVoter {
    function vote(
        uint256 tokenID,
        address[] calldata pools,
        uint256[] calldata _weights
    ) external;
}

contract RamsesProxyVoter {
    address public operator;
    IVoter public voter;

    constructor(address _operator, IVoter _voter) {
        operator = _operator;
        voter = _voter;
    }

    ///@notice vote on behalf of a veNFT approved to this contract
    function voteOnBehalfOf(
        uint256 _tokenID,
        address[] calldata _pools,
        uint256[] calldata _weights
    ) external {
        require(msg.sender == operator, "!AUTH");
        voter.vote(_tokenID, _pools, _weights);
    }
}