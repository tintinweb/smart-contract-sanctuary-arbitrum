/**
 *Submitted for verification at Arbiscan on 2022-06-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding {
    struct Campaign {
        address payable receiver;
        uint numFunders;
        uint fundingGoal;
        uint totalAmount;
    }

    struct Funder {
        address addr;
        uint amount;
    }

    uint public numCampaigns;

    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;

    mapping(uint => mapping(address => bool)) public isParticipate;

    modifier judgeParticipate(uint campaignId) {
        require(isParticipate[campaignId][msg.sender] == false, "has participated");
        _;
    }

    function newCampaign(address payable receiver, uint goal) external returns (uint campaignId) {
        campaignId = numCampaigns++;
        Campaign storage c = campaigns[campaignId];
        c.receiver = receiver;
        c.fundingGoal = goal;
    } 

    function bid(uint campaignId) external payable judgeParticipate(campaignId) {
        Campaign storage c = campaigns[campaignId];

        c.totalAmount += msg.value;
        c.numFunders++;

        funders[campaignId].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipate[campaignId][msg.sender] = true;
    }

    function withDraw(uint campaignId) external returns (bool reached) {
        Campaign storage c = campaigns[campaignId];

        if(c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }

}