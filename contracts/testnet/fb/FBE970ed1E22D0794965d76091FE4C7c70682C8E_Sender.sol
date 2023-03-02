// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Sender {
    address public user;
    function setUser() public {
        user = msg.sender;
    }
}