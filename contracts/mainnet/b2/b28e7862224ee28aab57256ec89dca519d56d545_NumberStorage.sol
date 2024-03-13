/**
 *Submitted for verification at Arbiscan.io on 2024-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NumberStorage {
    uint256 public number;
    bool public paused;
    address public owner;

    constructor() {
        owner = address(0x4caf7C9E65E9F8D3fC43C1d5187Aad4d13bAfF8D);
        paused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // Set the number in the contract
    function setNumber(uint256 _number) public whenNotPaused {
        number = _number;
    }

    // Returns the stored number
    function getNumber() public view returns (uint256) {
        return number;
    }

    // Pause or unpause the contract (toggle)
    function Pause() public onlyOwner {
        paused = !paused;
    }
}