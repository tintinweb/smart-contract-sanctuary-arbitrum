/**
 *Submitted for verification at Arbiscan.io on 2023-10-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

contract GiveAway {
    uint public MinDeposit = 1 ether;
    Vault vault;

    constructor(address v) {
        vault = Vault(v);
    }

    function Deposit() public payable {
        if (msg.value >= MinDeposit) {
            vault.Add(msg.sender, msg.value);
        }
    }

    function Withdraw(uint amount) public {
        if (amount <= vault.balances(msg.sender)) {
            (bool suc, ) = msg.sender.call{value: amount}("");
            if (suc) {
                vault.Sub(msg.sender, amount);
            }
        }
    }

    receive() external payable {}
}

contract Vault {
    mapping(address => uint) public balances;
    address giveaway;

    function Add(address user, uint256 amount) external {
        require(msg.sender == giveaway);
        balances[user] += amount;
    }

    function Sub(address user, uint256 amount) external {
        require(msg.sender == giveaway);
        balances[user] -= amount;
    }

    function setGiveaway(address g) external {
        require(giveaway == address(0));
        giveaway = g;
    }
}