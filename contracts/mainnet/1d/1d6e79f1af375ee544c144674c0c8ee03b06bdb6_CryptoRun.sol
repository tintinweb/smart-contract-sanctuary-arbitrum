/**
 *Submitted for verification at Arbiscan on 2022-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract CryptoRun {

    address public owner;
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    }

    function Crypto() public payable {
        payments[msg.sender] = msg.value;
    }

    function Run() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}