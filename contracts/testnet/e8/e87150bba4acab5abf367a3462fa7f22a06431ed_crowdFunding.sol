/**
 *Submitted for verification at Arbiscan on 2022-06-04
*/

pragma solidity ^0.8.11;

contract crowdFunding{
     address immutable owner;

     constructor() {
         owner = msg.sender;
     }

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

     uint public numCampagins;
     mapping (uint => Campaign) campaigns;
     mapping (uint => Funder[]) funders;

     function newCampaign (address payable receiver, uint goal) external returns(uint campaignID) {
         campaignID = numCampagins++;
         Campaign storage c = campaigns[campaignID];
         c.receiver = receiver;
         c.fundingGoal = goal;
     }

     function bid(uint campaignID) external payable {
         Campaign storage c = campaigns[campaignID];

         c.totalAmount += msg.value;
         c.numFunders += 1;

         funders[campaignID].push(Funder({
             addr: msg.sender,
             amount: msg.value
         }));
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