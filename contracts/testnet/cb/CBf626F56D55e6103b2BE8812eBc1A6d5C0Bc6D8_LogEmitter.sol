/**
 *Submitted for verification at Arbiscan.io on 2023-09-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.19;

contract LogEmitter {

    event Log(address indexed msgSender);

    function logEmitter() public {
        emit Log(msg.sender);
    }
}