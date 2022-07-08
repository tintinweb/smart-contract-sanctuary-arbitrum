/**
 *Submitted for verification at Arbiscan on 2022-07-08
*/

pragma solidity 0.8.11;

contract CrowdFundingStorage{
     struct Campaign{
        address payable receiver;
        uint numFunders;  
        uint fundingGoal;  
        uint totalAmount;  
    }

    struct Funder{
        address addr;
        uint amount;
    }

    uint public numCampagins;
    mapping(uint => Campaign) campaigns;
    mapping(uint=> Funder[]) funders;
    mapping(uint=> mapping(address=>bool)) public isParticipate;
}

contract  CrowdFunding is CrowdFundingStorage{ 
    address immutable owner;
    
    constructor(){
        owner = msg.sender;
    }

   


    modifier judgeParticipate(uint campaginId){
        require(isParticipate[campaginId][msg.sender]==false);
        _;
    }

     modifier isOwner(){
          require(msg.sender == owner);
          _;
     }

    //owner 
    function newCampagin(address payable receiver,uint goal) external isOwner() returns (uint campaginId){
        campaginId = numCampagins++;
        Campaign storage c = campaigns[campaginId];
        c.receiver=receiver;
        c.fundingGoal=goal;
        
    }

    // participate
    function bid(uint campaginId) external payable judgeParticipate(campaginId){
        Campaign storage c = campaigns[campaginId];
        c.totalAmount += msg.value;
        c.numFunders += 1;

      
        funders[campaginId].push(Funder({
            addr:msg.sender,
            amount:msg.value
        }));


        isParticipate[campaginId][msg.sender]==true;
    } 

  
    function withdraw(uint campaginId) external returns(bool reached){
         Campaign storage c = campaigns[campaginId];
         if(c.totalAmount< c.fundingGoal){
             return false;
         }

         uint amount  = c.totalAmount;
         c.totalAmount =0 ;
         c.receiver.transfer(amount);

         return true;
    }

}