/**
 *Submitted for verification at Arbiscan on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract T {
    uint8 val;

    function get() public view returns (uint8) {
        return val;
    }

    function set(uint8 _newVal) public {
        val = _newVal;
    }
}