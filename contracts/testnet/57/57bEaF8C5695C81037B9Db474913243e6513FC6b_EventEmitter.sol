/**
 *Submitted for verification at Arbiscan.io on 2023-12-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract EventEmitter {
    event Test(uint256 indexed _a, uint256 _b);

    function trigger(uint256 _a) external {
        emit Test(_a, _a);
    }
}