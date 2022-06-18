/**
 *Submitted for verification at Arbiscan on 2022-06-17
*/

pragma solidity 0.8.11;


contract CrowFundingStorage {
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
}


contract CrowFunding is CrowFundingStorage{
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier judgeParticipate(uint campaignId) {
        require(isParticipate[campaignId][msg.sender] == false);
        _;
    }

    modifier isOwner() {
        require(owner == msg.sender);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external isOwner() returns(uint campaignId)  {
        campaignId = numCampaigns++;
        Campaign storage c = campaigns[campaignId];
        c.receiver = receiver;
        c.fundingGoal = goal;
    }

    function bid(uint campaignId) external payable judgeParticipate(campaignId) {
        Campaign storage c = campaigns[campaignId];
        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignId].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipate[campaignId][msg.sender] = true;
    }

    function withdraw(uint campaignId) external returns(bool reached) {
        Campaign storage c = campaigns[campaignId];

        if (c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);
    }
}