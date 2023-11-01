// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract Voting {
    struct Proposal {
        uint voteCount;
        string description;
    }

    address public owner;
    Proposal[] public proposals;

    mapping(address => bool) public voters;

    constructor() {
        owner = msg.sender;
    }

    function createProposal(string memory description) public {
        require(msg.sender == owner, "Only owner can create proposal");
        proposals.push(Proposal({
            description: description,
            voteCount: 0
        }));
    }

    function vote(uint proposalIndex) public {
        require(!voters[msg.sender], "You have already voted");
        require(proposalIndex < proposals.length, "Invalid proposal");

        voters[msg.sender] = true;
        proposals[proposalIndex].voteCount++;
    }

    function getWinningProposal() public view returns (string memory) {
        uint winningVoteCount = 0;
        uint winningProposalIndex = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }

        return proposals[winningProposalIndex].description;
    }
}