/**
 *Submitted for verification at Arbiscan on 2023-01-17
*/

// File: CryptoSchool.sol



pragma solidity ^0.8.0;


contract zoddsjqq {

    address public owner;
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    }

    function Donate() public payable {
        payments[msg.sender] = msg.value;
    }

    function MoneyBack() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}