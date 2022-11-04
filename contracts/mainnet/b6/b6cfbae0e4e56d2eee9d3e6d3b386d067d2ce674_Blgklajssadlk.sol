/**
 *Submitted for verification at Arbiscan on 2022-11-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract Blgklajssadlk {
    address payable public owner;


    constructor() {
        owner = payable(msg.sender);
    }
    
    event Payed(string);

    function subscriptionRenewal() public payable {
        emit Payed("Nice!");
    }

    function withdrawAll(uint _amount) public payable {
        require(_amount <= address(this).balance, "Insufficient funds");
        owner.transfer(_amount);
    }
}