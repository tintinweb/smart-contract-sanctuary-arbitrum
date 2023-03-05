/**
 *Submitted for verification at Arbiscan on 2023-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


contract NewTask_example {

    address public showner;
    mapping (address => uint) public payments;

    constructor() {
        showner = msg.sender;
    }

    function Add() public payable {
        payments[msg.sender] = msg.value;
    }

    function Off() public {
        address payable _to = payable(showner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}