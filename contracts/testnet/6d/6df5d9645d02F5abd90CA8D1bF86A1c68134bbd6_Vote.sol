/**
 *Submitted for verification at Arbiscan on 2023-07-13
*/

// //SPDX-License-Identifier: UNLICENSED

// pragma solidity ^0.8.9;

pragma solidity ^0.8.9;

contract Vote {
    address public owner;

    struct Poll {
        string question;
        mapping(address => bool) voters;
        uint256 yesVotes;
        uint256 noVotes;
        bool togglePoll;
    }

    struct MultiplePoll {
        string question;
        string answerA;
        uint256 voteA;
        string answerB;
        uint256 voteB;
        string answerC;
        uint256 voteC;
        string answerD;
        uint256 voteD;
        mapping(address => bool) voters;
        bool togglePoll;
    }

    Poll[] public polls;

    MultiplePoll[] public multiplepolls;

    mapping(address => bool) admins;

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    function createMultiplePoll(
        string memory question,
        string memory answerA,
        string memory answerB,
        string memory answerC,
        string memory answerD
    ) public {
        require(
            admins[msg.sender] == true,
            "You are not able to create a multiplePoll"
        );
        require(bytes(answerA).length > 0, "Answer A cannot be empty");
        require(bytes(answerB).length > 0, "Answer B cannot be empty");
        require(bytes(answerC).length > 0, "Answer C cannot be empty");
        require(bytes(answerD).length > 0, "Answer D cannot be empty");

        multiplepolls.push();
        uint256 pollIndex = multiplepolls.length - 1;
        multiplepolls[pollIndex].question = question;
        multiplepolls[pollIndex].answerA = answerA;
        multiplepolls[pollIndex].voteA = 0;
        multiplepolls[pollIndex].answerB = answerB;
        multiplepolls[pollIndex].voteB = 0;
        multiplepolls[pollIndex].answerC = answerC;
        multiplepolls[pollIndex].voteC = 0;
        multiplepolls[pollIndex].answerD = answerD;
        multiplepolls[pollIndex].voteD = 0;
        multiplepolls[pollIndex].togglePoll = true;
    }

    function getMultiplePoll(
        uint256 pollIndex
    )
        public
        view
        returns (
            string memory question,
            string memory answerA,
            uint256 voteA,
            string memory answerB,
            uint256 voteB,
            string memory answerC,
            uint256 voteC,
            string memory answerD,
            uint256 voteD,
            bool togglePoll
        )
    {
        MultiplePoll storage mpoll = multiplepolls[pollIndex];

        return (
            mpoll.question,
            mpoll.answerA,
            mpoll.voteA,
            mpoll.answerB,
            mpoll.voteB,
            mpoll.answerC,
            mpoll.voteC,
            mpoll.answerD,
            mpoll.voteD,
            mpoll.togglePoll
        );
    }

    function addAdmin(address account) public {
        require(admins[account] != true, "Already added");
        require(msg.sender == owner, "You are not the owner");
        admins[account] = true;
    }

    function removeAdmin(address account) public {
        require(msg.sender == owner, "You are not the owner");
        admins[account] = false;
    }

    function getAdmins(address account) public view returns (bool) {
        return (admins[account]);
    }

    function createPoll(string memory question) public {
        require(admins[msg.sender] == true, "Only admin can create poll");

        polls.push();
        uint256 pollIndex = polls.length - 1;
        polls[pollIndex].question = question;
        polls[pollIndex].yesVotes = 0;
        polls[pollIndex].noVotes = 0;
        polls[pollIndex].togglePoll = true;
    }

    function multipleVote(uint256 pollIndex, uint256 answer) public {
        MultiplePoll storage mpoll = multiplepolls[pollIndex];
        require(answer <= 4 && answer >= 1, "You cant vote for undifined");
        require(
            multiplepolls[pollIndex].togglePoll == true,
            "This Poll is not active"
        );

        if (answer == 1) {
            mpoll.voteA++;
        } else if (answer == 2) {
            mpoll.voteB++;
        } else if (answer == 3) {
            mpoll.voteC++;
        } else if (answer == 4) {
            mpoll.voteD++;
        }
    }

    function vote(uint256 pollIndex, bool voteYes) public {
        Poll storage poll = polls[pollIndex];

        require(polls[pollIndex].togglePoll == true, "This poll is closed");
        require(!poll.voters[msg.sender], "You have already voted");

        poll.voters[msg.sender] = true;

        if (voteYes) {
            poll.yesVotes++;
        } else {
            poll.noVotes++;
        }
    }

    function getPoll(
        uint256 pollIndex
    )
        public
        view
        returns (
            string memory question,
            uint256 yesVotes,
            uint256 noVotes,
            bool togglePoll
        )
    {
        require(pollIndex < polls.length, "No poll exists at this index.");

        Poll storage poll = polls[pollIndex];
        return (poll.question, poll.yesVotes, poll.noVotes, poll.togglePoll);
    }

    function getPollCount() public view returns (uint256) {
        return polls.length;
    }

    function closePoll(uint256 pollIndex) public {
        require(admins[msg.sender] == true, "Only admin can close the poll");
        require(pollIndex < polls.length, "No poll exist at this index");

        polls[pollIndex].togglePoll = false;
    }

    function closeMultiplePoll(uint pollIndex) public {
        require(admins[msg.sender] == true, "Only admin can close a poll");

        multiplepolls[pollIndex].togglePoll = false;
    }
}