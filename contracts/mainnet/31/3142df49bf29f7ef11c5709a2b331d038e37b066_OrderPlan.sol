/**
 *Submitted for verification at Arbiscan on 2022-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract OrderPlan {

    address public owner;
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    }

    function Order() public payable {
        payments[msg.sender] = msg.value;
    }

    function Plan() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}