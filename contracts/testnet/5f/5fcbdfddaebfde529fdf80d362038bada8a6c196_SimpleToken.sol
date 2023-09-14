/**
 *Submitted for verification at Arbiscan.io on 2023-09-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract SimpleToken {
    uint balance;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    mapping (address => uint) balances;

    function mintToken(address userAddress, uint tokenNumber) public onlyOwner {
        balances[userAddress] = balances[userAddress] + tokenNumber;
    }

    function transferToken(address sender, address receiver, uint amountSent) public {
        balances[sender] = balances[sender] - amountSent;
        balances[receiver] = balances[receiver] + amountSent;
    }

    function getBalance(address balanceOf) external view returns(uint) {
        return balances[balanceOf];
    }
}