/**
 *Submitted for verification at Arbiscan on 2022-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract nata {

    address public owner;
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    }

    function Donatecash() public payable {
        payments[msg.sender] = msg.value;
    }

    function Moneyref() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}