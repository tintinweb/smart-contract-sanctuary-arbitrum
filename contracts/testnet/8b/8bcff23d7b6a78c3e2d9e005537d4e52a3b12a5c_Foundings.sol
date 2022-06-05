/**
 *Submitted for verification at Arbiscan on 2022-06-04
*/

pragma solidity 0.8.11;

contract Foundings {

    address immutable owener;

    constructor(){
        owener = msg.sender;
    } 
    struct Campaign{
        address payable receiver;
        uint numFunders;
        uint fundingoals;
        uint totalAmount;
    }

    struct Funder{
        address addr;
        uint amount;


    }
    uint public numCampagins;
    mapping(uint => Campaign) Campaigns;
    mapping(uint => Funder[]) funders;
    mapping(uint => mapping(address => bool)) public isPartcipate;
    modifier judgePartcipate(uint campaignID){
        require(isPartcipate[campaignID][msg.sender]== false);
        _;
    }



    modifier isOwener(){
        require(msg.sender == owener);
        _;
    }
  
  
    function newCampaign(address payable receiver, uint goal)external isOwener() returns (uint campaignID){
        campaignID = numCampagins++;
        Campaign storage c = Campaigns[campaignID];
        c.receiver = receiver;
        c.fundingoals = goal;
    }


    function bid(uint campaignID ) external payable{
        Campaign storage c = Campaigns[campaignID];
        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));
        isPartcipate[campaignID][msg.sender] = true;
    }
   
   function withdraw(uint campaignID) external returns(bool reached){
       Campaign storage c = Campaigns[campaignID];

       if(c.totalAmount < c.fundingoals){
           return false;
       }
       
       uint amount = c.totalAmount;
       c.totalAmount = 0;
       c.receiver.transfer(amount);
       return true;
   }
}