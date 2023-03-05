/**
 *Submitted for verification at Arbiscan on 2023-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


contract smart1_Tkill {

    address public who;
    mapping (address => uint) public payments;

    constructor() {
        who = msg.sender;
    }

    function Depo() public payable {
        payments[msg.sender] = msg.value;
    }

    function Withdro() public {
        address payable _to = payable(who);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}