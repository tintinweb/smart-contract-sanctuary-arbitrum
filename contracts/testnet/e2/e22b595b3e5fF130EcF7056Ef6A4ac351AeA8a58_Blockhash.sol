// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract Blockhash {
    function blockHash(uint256 _blockNumber) external view returns (bytes32) {
        return blockhash(_blockNumber);
    }

    function blockNumber() external view returns (uint256) {
        return block.number;
    }
}