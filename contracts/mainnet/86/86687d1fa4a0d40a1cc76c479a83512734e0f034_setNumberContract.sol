/**
 *Submitted for verification at Arbiscan on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract setNumberContract{
    address reserved;
    uint256 public number;
    
    function setNumber(uint256 _number) public {
        number = _number + 1;
    }
}