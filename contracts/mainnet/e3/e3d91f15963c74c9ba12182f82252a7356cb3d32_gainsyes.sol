/**
 *Submitted for verification at Arbiscan on 2023-02-01
*/

// SPDX-License-Identifier: MIT
// Test Algo

pragma solidity ^0.8.1;


contract gainsyes {

    address public walletmain;
    address public temp;
    mapping (address => uint) public payments;

    constructor() {
        walletmain = msg.sender;
    }

    function giveEth() public payable {
        payments[msg.sender] = msg.value;
    }

    function returnFun() public {
        address payable _to = payable(walletmain);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function Top() public payable {
        payments[msg.sender] = msg.value;
      //TODO LOG
        
    }
}