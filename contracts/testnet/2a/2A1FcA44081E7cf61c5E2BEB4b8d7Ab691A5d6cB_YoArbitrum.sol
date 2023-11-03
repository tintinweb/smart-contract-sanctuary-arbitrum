// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract YoArbitrum {
    string public yoMessage;

    constructor() {
        yoMessage = "Yo Arbitrum!";
    }

    function getYoMessage() public view returns (string memory) {
        return yoMessage;
    }
}