// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.7;

contract Contabilitate {
    mapping(address => uint256) private balante;

    function depozit() public payable {
        balante[msg.sender] += msg.value;
    }

    function retrage(uint256 suma) public {
        require(balante[msg.sender] >= suma, "Fonduri insuficiente");
        balante[msg.sender] -= suma;
        payable(msg.sender).transfer(suma);
    }

    function balanta() public view returns (uint256) {
        return balante[msg.sender];
    }
}