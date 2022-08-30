/**
 *Submitted for verification at Arbiscan on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Test{
    function returnData() external view returns(uint256, uint256) {
        return (block.number, block.timestamp);
    }
}