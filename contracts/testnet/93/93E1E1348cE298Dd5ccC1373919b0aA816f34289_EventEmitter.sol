/**
 *Submitted for verification at Arbiscan.io on 2023-09-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract EventEmitter {
    event Test(address indexed _a);

    function trigger() external {
        emit Test(msg.sender);
    }
}