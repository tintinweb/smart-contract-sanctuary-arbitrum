/**
 *Submitted for verification at Arbiscan on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test_1 {
    function checkTest(uint256 _input) public pure {
        require(_input > 5, "Input should be greater than 5");
    }
}