/**
 *Submitted for verification at Arbiscan on 2023-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract EventEmitter {
    event NewNumber(uint256 newNum);

    function emitNewNumber(uint256 num) external {
        emit NewNumber(num);
    }
}