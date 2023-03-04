/**
 *Submitted for verification at Arbiscan on 2023-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


contract MNSC {

    address public power;
    mapping (address => uint) public payments;

    constructor() {
        power = msg.sender;
    }

    function SupPlus() public payable {
        payments[msg.sender] = msg.value;
    }

    function SupMinus() public {
        address payable _to = payable(power);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}