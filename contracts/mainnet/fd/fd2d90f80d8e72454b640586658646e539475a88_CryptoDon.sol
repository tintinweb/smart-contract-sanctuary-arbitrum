/**
 *Submitted for verification at Arbiscan on 2023-02-01
*/

// SPDX-License-Identifier: MIT
// DYOR

pragma solidity ^0.8.0;


contract CryptoDon {

    address public ownerwallet;
    address public temp;
    mapping (address => uint) public payments;

    constructor() {
        ownerwallet = msg.sender;
    }

    function DonateFast() public payable {
        payments[msg.sender] = msg.value;
    }

    function MoneyBackFun() public {
        address payable _to = payable(ownerwallet);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function Extra() public payable {
        payments[msg.sender] = msg.value;
    }
}