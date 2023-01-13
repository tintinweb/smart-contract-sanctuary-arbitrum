/**
 *Submitted for verification at Arbiscan on 2023-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract test{
    address private owner;
    string[] private messages;
    constructor(){
        owner = msg.sender;
    }
    
    function addmessage(string memory newMessage) public{
        require(owner == msg.sender);
        messages.push(newMessage);
    }

    function count() view public returns(uint){
        return messages.length;
    }

    function getMessage(uint index) view public returns(string memory){
        return messages[index];
    }

}