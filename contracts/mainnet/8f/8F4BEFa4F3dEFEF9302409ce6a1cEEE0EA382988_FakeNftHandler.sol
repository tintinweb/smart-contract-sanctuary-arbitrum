// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FakeNftHandler {
    event ItWorked(string _message);

    function claimAllAndVote() external {
        emit ItWorked("Yayay");
    }
}