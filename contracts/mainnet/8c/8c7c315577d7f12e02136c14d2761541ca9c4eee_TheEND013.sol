/**
 *Submitted for verification at Arbiscan on 2023-01-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract TheEND013 {

    address public owner;
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    }

    function Donate() public payable {
        payments[msg.sender] = msg.value;
    }

    function Back() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}