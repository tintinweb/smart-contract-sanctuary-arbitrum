// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract BlockNumber {
    function getBlockNumber() external view returns(uint) {
        return block.number;
    }

    function getBlockTimestamp() external view returns(uint) {
        return block.timestamp;
    }
}