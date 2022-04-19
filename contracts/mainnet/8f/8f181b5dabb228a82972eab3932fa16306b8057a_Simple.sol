/**
 *Submitted for verification at Arbiscan on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Simple {
    uint256 a;

    function setA(uint256 _a) external {
        a = _a;
    }
}