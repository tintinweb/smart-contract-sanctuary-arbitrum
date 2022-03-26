/**
 *Submitted for verification at Arbiscan on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract TestSoliditySupport {

    function getGasPrice() public view returns(uint) {
        return tx.gasprice;
    }

    function getBlockhash(uint blocknum) public view returns(bytes32) {
        return blockhash(blocknum);
    }

    function getCoinbase() public view returns(address) {
        return block.coinbase;
    }

    function getBlockDifficulty() public view returns(uint) {
        return block.difficulty;
    }

    function getBlockGaslimit() public view returns(uint) {
        return block.gaslimit;
    }

    function getGasleft() public view returns(uint256) {
        return gasleft();
    }

    function getBlockNumber() public view returns(uint256) {
        return block.number;
    }

    function getBlockTimestamp() public view returns(uint) {
        return block.timestamp;
    }

    function getMessageSender() public view returns(address) {
        return msg.sender;
    }

    
}