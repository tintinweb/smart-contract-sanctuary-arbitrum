// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract RRSDailySpin {

    mapping(address=>uint256) public spinCount;

    event Spinned(address indexed walletAddress);

    function spin() external {
        spinCount[msg.sender] += 1;

        emit Spinned(msg.sender);
    }
}