/**
 *Submitted for verification at Arbiscan on 2022-06-04
*/

pragma solidity ^0.8.11;

contract CrowdFundingStorage{
    struct Campaign {
        address payable receiver;
        uint numFunding;
        uint fundingGoal;
        uint totalAmount;
    }

    struct Funder {
        address addr;
        uint amount;
    }

    uint public numCapaign;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;

    mapping(uint => mapping(address => bool)) public isDone;

}




contract CrowdFunding is CrowdFundingStorage{
    address immutable owner;

    constructor (){
        owner = msg.sender;
    }

    

    modifier judgeDone(uint campaignID){
        require(isDone[campaignID][msg.sender] == false);
        _;
    }


    function newCapaign (address payable receiver, uint goal) external returns(uint campaignID){
        campaignID = numCapaign++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;
    }

    function bid(uint campaignID) external payable judgeDone(campaignID){
        Campaign storage c = campaigns[campaignID];

        c.totalAmount += msg.value;
        c.numFunding += 1;

        funders[campaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isDone[campaignID][msg.sender] = true;
    }

    function withdraw(uint campaignID) external returns(bool reacher){
        Campaign storage c = campaigns[campaignID];

        if (c.totalAmount < c.fundingGoal){
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }

}