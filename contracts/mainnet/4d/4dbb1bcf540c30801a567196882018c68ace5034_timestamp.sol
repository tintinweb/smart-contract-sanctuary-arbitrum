/**
 *Submitted for verification at Arbiscan on 2023-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract timestamp {
    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}