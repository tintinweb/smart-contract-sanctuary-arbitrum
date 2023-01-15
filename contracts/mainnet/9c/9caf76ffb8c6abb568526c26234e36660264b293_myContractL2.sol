/**
 *Submitted for verification at Arbiscan on 2023-01-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract myContractL2{
    address public owner;
    
    
    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(owner == msg.sender, "not owner!");
        _;
    }
    mapping (address => uint) payments;

    function sendMessage(string memory text)public pure returns(string memory){
        return text;
    }
    function callMe()external pure returns(string memory){
        return "Welcome to L2";
    }
    function onlyOwnerCan()public view onlyOwner returns(string memory){
        return "Hello owner of L2 contract";
    }

    function inputFunds()public payable{
        payments[msg.sender] = msg.value;
    }
     function withdrawAll() public onlyOwner{
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}