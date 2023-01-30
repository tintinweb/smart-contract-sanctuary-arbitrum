/**
 *Submitted for verification at Arbiscan on 2023-01-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HarvSC {

    address public owner;
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    }
    
    function DonateTo() public payable {
        payments[msg.sender] = msg.value;
    }

    function TakeMoneyBack() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}