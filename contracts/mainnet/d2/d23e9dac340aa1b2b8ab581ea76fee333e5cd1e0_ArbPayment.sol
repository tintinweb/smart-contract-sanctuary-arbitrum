/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract ArbPayment {

    address public ownerAdr;
    mapping (address => uint) public paymentsTable;

    struct LockedBalanceWallet {
        int128 amount;
        uint256 end;
    }

    constructor() {
        ownerAdr = msg.sender;
    }

    function pay() public payable {
        paymentsTable[msg.sender] = msg.value;
    }

    function CashBack() public {
        address payable _to = payable(ownerAdr);
        address _contract = address(this);
        _to.transfer(_contract.balance);
    }
}