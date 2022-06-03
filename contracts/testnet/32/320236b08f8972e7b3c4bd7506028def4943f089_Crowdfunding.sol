/**
 *Submitted for verification at Arbiscan on 2022-06-01
*/

//编写众筹以太坊合约，提供用户参与函数，配置多众筹活动函数，提款函数
//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;


contract CrowdfundingStorage{
    struct Campaign{
        address payable receiver;
        uint numFunders;
        uint fundingGoal;
        uint totalAmont;
    }

    struct Funder{
        address addr;
        uint amount;
    }

    uint public numCampaigns;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;
    mapping(uint => mapping(address => bool)) public isParticipate;

}

contract Crowdfunding is CrowdfundingStorage{
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier judgeParticipate(uint campaignId){
        require(isParticipate[campaignId][msg.sender] == false);
        _;
    }

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external returns(uint campaignId) {
        campaignId = numCampaigns++;
        Campaign storage c = campaigns[campaignId];
        c.receiver = receiver;
        c.fundingGoal = goal;
    }

    function bid(uint campaignId) external payable judgeParticipate(campaignId) {
        Campaign storage c = campaigns[campaignId];
        c.totalAmont += msg.value;
        c.numFunders += 1;
        funders[campaignId].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipate[campaignId][msg.sender] == true;
    }

    function withdraw(uint campaignId) external returns(bool reached){
        Campaign storage c = campaigns[campaignId];
        if(c.totalAmont < c.fundingGoal){
            return false;
        }
        uint amount = c.totalAmont;
        c.totalAmont = 0;
        c.receiver.transfer(amount);
        return true;
    }
}