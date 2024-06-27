/**
 *Submitted for verification at Arbiscan.io on 2024-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.24;

contract ArbiTest {
    function test() public view returns (uint256) {
        return block.gaslimit;
    }
}