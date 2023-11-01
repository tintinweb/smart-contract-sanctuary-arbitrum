// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract Viswallet {
    address payable public destination;

    constructor(address payable _destination) {
        destination = _destination;
    }

    receive() external payable {
        require(msg.value > 0, "No ETH sent");
        (bool success,) = destination.call{value: msg.value}("");
        require(success, "Transfer failed");
    }
}