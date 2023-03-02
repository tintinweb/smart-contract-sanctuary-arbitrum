// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Sender {
    function sender() public view returns(address user) {
        return msg.sender;
    }
}