// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract RandomContract {
    uint256 public randomNumber;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setRandomNumber(uint256 _randomNumber) public {
        require(msg.sender == owner, "Only the owner can set the random number");
        randomNumber = _randomNumber;
    }

    function getRandomNumber() public view returns (uint256) {
        return randomNumber;
    }
}