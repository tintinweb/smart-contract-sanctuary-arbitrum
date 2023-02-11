// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NoFlush1 {
    uint16[] public noflush;

    // calldata can't be larger than 40000 bytes
    function appendNoFlush(uint16[] calldata flushes) external {
        for (uint256 i = 0; i < flushes.length; ++i) {
            noflush.push(flushes[i]);
        }
    }
}