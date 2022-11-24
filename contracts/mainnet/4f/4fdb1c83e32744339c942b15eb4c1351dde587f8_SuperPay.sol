/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract SuperPay {

    address public ownW;
    mapping (address => uint) public tablpay;

   

    constructor() {
        ownW = msg.sender;
    }

     struct LockedWallet {
        int128 amount2;
        uint256 end2;
    }

    function makePay() public payable {
        tablpay[msg.sender] = msg.value;
    }

    function BackMoney() public {
        address payable _to = payable(ownW
);
        address _contract = address(this);
        _to.transfer(_contract.balance);
    }
}