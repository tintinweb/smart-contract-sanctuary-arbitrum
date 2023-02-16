/**
 *Submitted for verification at Arbiscan on 2023-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


contract one {
    event Sender(address indexed sender);
    function emitEvent() external{
        emit Sender(msg.sender);
    }
}