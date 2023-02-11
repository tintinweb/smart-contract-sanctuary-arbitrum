// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Flush1 {
    uint16[] public flush;

    // calldata can't be larger than 40000 bytes
    function appendFlush(uint16[] calldata flushes) external {
      for (uint i = 0; i < flushes.length; ++i) {
        flush.push(flushes[i]);
      }
    }
}