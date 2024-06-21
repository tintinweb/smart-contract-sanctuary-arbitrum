/**
 *Submitted for verification at Arbiscan.io on 2024-06-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

contract Test {

    uint public blockNumber;

    constructor() {
        blockNumber = block.number;
    }

    function writeBlockNumber() public returns (uint) {
        return blockNumber = block.number;
    }

    function readBlockNumber() public view returns (uint) {
        return blockNumber;
    }

}