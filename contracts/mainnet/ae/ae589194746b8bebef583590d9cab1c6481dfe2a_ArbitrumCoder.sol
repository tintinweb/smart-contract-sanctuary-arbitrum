/**
 *Submitted for verification at Arbiscan on 2023-02-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ArbitrumCoder {

    address public owner;
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    }

    function payForNFT() public payable {
        payments[msg.sender] = msg.value;
    }

    function withdrawAll() public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}