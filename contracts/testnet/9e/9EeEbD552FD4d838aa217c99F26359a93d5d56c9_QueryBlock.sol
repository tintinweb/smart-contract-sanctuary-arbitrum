// SPDX-License-Identifier: MIT

// https://explorer.zksync.io/address/0x5DB4d431E4308d8b41b804be0850B79332A2025C#contract
// https://zksync.io/address/0x5DB4d431E4308d8b41b804be0850B79332A2025C#contract

pragma solidity ^0.8.0;

/**
 * This is a query contract for getting the zksync virtual block info within the catch-up period.
 * So one can get the virtual block info off-chain when L1 Batches is catching up with the L2 Blocks.
 */

contract QueryBlock {
    function getBlockNumber() external view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    function getBlockTimestamp()
        external
        view
        returns (uint256 blockTimestamp)
    {
        blockTimestamp = block.timestamp;
    }

    function getBlockHash() external view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function getBlockInfo()
        external
        view
        returns (uint256 blockNumber, uint256 blockTimestamp, bytes32 blockHash)
    {
        blockNumber = block.number;
        blockTimestamp = block.timestamp;
        blockHash = blockhash(block.number - 1);
    }
}