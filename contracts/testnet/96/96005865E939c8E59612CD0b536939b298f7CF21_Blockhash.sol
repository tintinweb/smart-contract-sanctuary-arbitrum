// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract Blockhash {
    function get() external view returns (bytes32) {
        return blockhash(block.number);
    }
}