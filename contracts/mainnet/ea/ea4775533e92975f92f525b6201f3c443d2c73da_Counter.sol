/**
 *Submitted for verification at Arbiscan.io on 2024-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Counter {
    uint public count;

    function getCount() public view returns (uint) {
        return count;
    }

    function inc() public {
        count++;
    }

    function dec() public {
        count--;
    }
}