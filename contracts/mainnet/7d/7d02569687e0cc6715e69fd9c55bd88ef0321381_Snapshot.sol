// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Snapshot {
    address public owner;

    event SnapshotTaken(uint256 timestamp);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function snapshot() external onlyOwner {
        // Perform snapshot logic here

        emit SnapshotTaken(block.timestamp);
    }
}