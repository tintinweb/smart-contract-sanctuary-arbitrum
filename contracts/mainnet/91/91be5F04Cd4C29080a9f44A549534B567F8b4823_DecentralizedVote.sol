// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract DecentralizedVote {
    address public owner;
    struct Proposal {
        string description;
        uint voteCount;
    }

    struct Voter {
        bool hasVoted;
        uint votedProposalId;
    }

    Proposal[] public proposals;
    mapping(address => Voter) public voters;
    bool public votingActive;
    uint public winningProposalId;

    event ProposalRegistered(uint proposalId, string description);
    event Vote(address voter, uint proposalId);
    event VotingEnded(uint winningProposalId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier voteIsActive() {
        require(votingActive, "Voting is not active");
        _;
    }

    constructor() {
        owner = msg.sender;
        votingActive = true;
    }

    function registerProposal(string memory description) public onlyOwner {
        proposals.push(Proposal({
            description: description,
            voteCount: 0
        }));
        emit ProposalRegistered(proposals.length - 1, description);
    }

    function vote(uint proposalId) public voteIsActive {
        require(!voters[msg.sender].hasVoted, "Already voted");
        require(proposalId < proposals.length, "Invalid proposal id");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;
        proposals[proposalId].voteCount += 1;
        emit Vote(msg.sender, proposalId);
    }

    function endVoting() public onlyOwner voteIsActive {
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }

        votingActive = false;
        emit VotingEnded(winningProposalId);
    }

    function getProposalsCount() public view returns (uint) {
        return proposals.length;
    }

    function getWinningProposal() public view returns (Proposal memory) {
        require(!votingActive, "Voting is not ended yet");
        return proposals[winningProposalId];
    }
}