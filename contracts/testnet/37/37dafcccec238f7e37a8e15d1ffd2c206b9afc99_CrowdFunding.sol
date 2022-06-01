/**
 *Submitted for verification at Arbiscan on 2022-05-31
*/

pragma solidity 0.8.11;

contract CrowdFundingStorage {
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
    mapping(uint => mapping(address => bool)) public participate;
}

contract CrowdFunding is CrowdFundingStorage {
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier validate(uint id) {
        require(participate[id][msg.sender] == false);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external isOwner() returns(uint id) {
        id = numCampaigns++;
        Campaign storage c = campaigns[id];
        c.receiver = receiver;
        c.fundingGoal = goal;
    }

    function bid(uint id) external payable validate(id) {
        Campaign storage c = campaigns[id];
        
        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[id].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        participate[id][msg.sender] = true;
    }

    function withdraw(uint id) external returns(bool reached) {
        Campaign storage c = campaigns[id];

        if(c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }
}