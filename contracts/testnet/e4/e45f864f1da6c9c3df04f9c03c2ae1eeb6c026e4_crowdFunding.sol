/**
 *Submitted for verification at Arbiscan on 2022-05-31
*/

pragma solidity 0.8.7;

contract crowdFundingTemplate{
    struct Funding{
        uint target;
        uint currentsum;
        address payable receiver;
    }
    uint public currentFundingID;
    mapping(uint => Funding) fundings;
    mapping(uint => address[]) funders; 
    mapping(uint => mapping(address => bool)) isExists;
}
contract crowdFunding is crowdFundingTemplate{
    modifier judgeExist(uint fundingID) {
        require(isExists[fundingID][msg.sender] == false);
        _;
    }
    modifier isOwner(uint fundingID){
        Funding storage f = fundings[fundingID];
        require(msg.sender == f.receiver);
        _;
    }
    function newFunding(address payable receiver,uint target) external returns(uint fundingID){
        fundingID = currentFundingID++;
        Funding storage f = fundings[fundingID];
        f.receiver = receiver;
        f.target = target;
        f.currentsum = 0;
    }
    function bid(uint fundingID) external payable judgeExist(fundingID){
        Funding storage f = fundings[fundingID];
        f.currentsum += msg.value;
        funders[fundingID].push(msg.sender);
        isExists[fundingID][msg.sender] = true;
    }
    function withdraw(uint fundingID) external isOwner(fundingID) returns(bool successed) {
        Funding storage f = fundings[fundingID];
        if(f.currentsum < f.target) return false;
        else{
            uint amount = f.target;
            f.target = 0;
            f.receiver.transfer(amount);
            return true;
        }
    }
}