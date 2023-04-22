/**
 *Submitted for verification at Arbiscan on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockTimestamp {
    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}