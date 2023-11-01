// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract VotingSystem {
    struct Candidate {
        string name;
        uint voteCount;
    }

    Candidate[] public candidates;
    mapping(address => bool) public voters;

    function addCandidate(string memory _name) public {
        candidates.push(Candidate(_name, 0));
    }

    function vote(uint _candidateIndex) public {
        require(!voters[msg.sender], "You have already voted.");
        require(_candidateIndex < candidates.length, "No candidate at this index.");

        voters[msg.sender] = true;
        candidates[_candidateIndex].voteCount += 1;
    }

    function getLeadingCandidate() public view returns (string memory name, uint voteCount) {
        uint leadingVoteCount = 0;
        uint leadingCandidateIndex = 0;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > leadingVoteCount) {
                leadingVoteCount = candidates[i].voteCount;
                leadingCandidateIndex = i;
            }
        }

        name = candidates[leadingCandidateIndex].name;
        voteCount = leadingVoteCount;
    }
}