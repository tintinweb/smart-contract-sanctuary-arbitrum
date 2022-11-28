// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Zoomer {
    uint public count;
    event Zoomed(uint indexed count, uint indexed when);

    function zoom() public {
        count += 1;
        emit Zoomed(count, block.timestamp);
    }
}