/**
 *Submitted for verification at Arbiscan on 2023-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract EventEmitter {
    event NewEvent();

    function emitNewEvent() external {
        emit NewEvent();
    }
}