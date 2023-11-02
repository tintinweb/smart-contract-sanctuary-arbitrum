// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract HiArbitrum {
    string public hiMessage;

    constructor() {
        hiMessage = "Hi Arbitrum!";
    }

    function getHiMessage() public view returns (string memory) {
        return hiMessage;
    }
}