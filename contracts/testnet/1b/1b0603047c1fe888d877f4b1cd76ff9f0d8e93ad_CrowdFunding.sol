/**
 *Submitted for verification at Arbiscan on 2022-05-29
*/

pragma solidity 0.8.0;

contract CrowdFunding {

    struct Funder {
        address addr;
        uint amount;
    }

    struct Campaign {
        address payable receiver;
        uint totalAmount;
        uint fundingGoal;
        uint numFunders;//有多少个人
    }


    uint public numCampagins;//有多少个活动在进行
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;
    mapping(uint => mapping(address => bool)) public isParticipate;



    modifier judgeParticipate(uint campaignID) {
        require(isParticipate[campaignID][msg.sender] == false);
        _;

    }




    function creatCampaign(address payable receiver, uint goal) public returns(uint campaignID) {
        campaignID = numCampagins++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;

    }

    function contribute(uint campaignID) public payable judgeParticipate(campaignID) {
        Campaign storage c = campaigns[campaignID];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipate[campaignID][msg.sender] = true;
    }

    function withdrawandcheckGoalReached(uint campaignID) public returns(bool reached) {
        Campaign storage c = campaigns[campaignID];
        if (c.totalAmount < c.fundingGoal) {
            return false;
        }
        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);
        return true;
        
    }
    


}