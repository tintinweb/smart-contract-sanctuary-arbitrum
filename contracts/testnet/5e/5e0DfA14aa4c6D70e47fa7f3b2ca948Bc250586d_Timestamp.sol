/**
 *Submitted for verification at Arbiscan on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Timestamp {

    function timestamp() external view returns(uint256) {
        return block.timestamp;
    }

    function blocknumber() external view returns(uint256) {
        return block.number;
    }

    function blockhash() external view returns(bytes32) {
        return blockhash(block.number);
    }

    function blockhashminus(uint256 x) external view returns(bytes32) {
        return blockhash(block.number - x);
    }

}