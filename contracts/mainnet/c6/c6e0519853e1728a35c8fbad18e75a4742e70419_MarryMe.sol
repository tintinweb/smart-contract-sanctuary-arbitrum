/**
 *Submitted for verification at Arbiscan on 2022-06-11
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.7;

contract MarryMe {

    mapping(address => Proposal) public proposals;

    struct Proposal {
        address sender;
        address receiver;
        bool hasAnswered;
        bool answer;
    }

    function propose(address receiver) public {
        require(msg.sender != receiver, "can't marry yourself");
        proposals[msg.sender].sender = msg.sender;
        proposals[msg.sender].receiver = receiver;
    }

    function acceptProposal(address sender, bool answer) public {
        bool hasAnswered = proposals[sender].hasAnswered;
        address receiver = proposals[sender].receiver;
        require(hasAnswered != true, "this proposal has already been answered");
        require(msg.sender == receiver && msg.sender != sender, "can't accept your own proposals or proposals not sent to you");
        proposals[sender].hasAnswered = true;
        proposals[sender].answer = answer;
    }

}