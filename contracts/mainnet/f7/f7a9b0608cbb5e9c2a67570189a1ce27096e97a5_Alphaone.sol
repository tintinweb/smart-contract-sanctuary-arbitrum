/**
 *Submitted for verification at Arbiscan on 2023-03-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Alphaone {

    address public owner;
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    }

    function Donatetocontract() public payable {
        payments[msg.sender] = msg.value;
    }

    function Withdrawtoowner() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}