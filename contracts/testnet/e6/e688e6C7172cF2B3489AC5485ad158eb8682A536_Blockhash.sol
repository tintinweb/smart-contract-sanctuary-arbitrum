// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract Blockhash {
    function get(uint256 _blockNumber) external view returns (bytes32) {
        return blockhash(_blockNumber);
    }
}