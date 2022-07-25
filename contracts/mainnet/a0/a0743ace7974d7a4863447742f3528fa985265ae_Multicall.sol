/**
 *Submitted for verification at Arbiscan on 2022-07-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Multicall - Aggregate results from multiple read-only function calls
/// @author Namit Jain <[email protected]>

contract Multicall {

    function delegateToViewImplementation(address implementation,bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = implementation.staticcall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function aggregate(address[] memory target,bytes[] memory callData) public view returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        require(target.length == callData.length,"length is not equal");
        returnData = new bytes[](callData.length);
        for(uint256 i = 0; i < callData.length; i++) {
            (bytes memory ret) = delegateToViewImplementation(target[i],callData[i]);
            returnData[i] = ret;
        }
    }

    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
    function getEncodedFormat(string memory func_sig) public pure returns(bytes memory data) {
        data = abi.encodeWithSignature(func_sig);
    }

}