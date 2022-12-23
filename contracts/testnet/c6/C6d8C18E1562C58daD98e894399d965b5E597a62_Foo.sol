/**
 *Submitted for verification at Arbiscan on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Foo {
    uint val;

    constructor(){
        val=3;
    }
    function setInt(uint256 _val) public {
        val = _val;
    }

    function getInt() public view returns (uint256) {
        return val;
    }
}