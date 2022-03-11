/**
 *Submitted for verification at arbiscan.io on 2022-03-10
*/

// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.4;

contract Defender {
    uint public count;

function increaseCount(uint256 amount) external  {
        count += amount;
    }
}