// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract Forwarder {
    address payable public destinationAddress;

    constructor(address payable _destinationAddress) {
        destinationAddress = _destinationAddress;
    }

    receive() external payable {
        destinationAddress.transfer(msg.value);
    }
}