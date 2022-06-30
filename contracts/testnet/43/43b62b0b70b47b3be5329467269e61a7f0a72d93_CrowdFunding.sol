/**
 *Submitted for verification at Arbiscan on 2022-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract CrowdFundStorage {
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

    mapping(uint => mapping(address => bool)) public isParticipated;

}

contract CrowdFunding is CrowdFundStorage {
    
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    Campaign[] public campaignsArray;
    event CampaignLog(uint campaignID, address receiver, uint goal);

    modifier judgeParticipated(uint campaignID) {
        require(isParticipated[campaignID][msg.sender] == false);
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external isOwner() returns(uint campaignID) {
        campaignID = numCampaigns++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;

        campaignsArray.push(c);
        emit CampaignLog(campaignID, receiver, goal);
    }

    function bid(uint campaignID) external payable judgeParticipated(campaignID) {
        Campaign storage c = campaigns[campaignID];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipated[campaignID][msg.sender] = true;
    }

    function withdraw(uint campaignID) external returns(bool reached) {
        Campaign storage c = campaigns[campaignID];

        if(c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }
}