/**
 *Submitted for verification at Arbiscan on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SampleContract {
    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function setMessage(string memory _newMessage) public {
        message = _newMessage;
    }
}