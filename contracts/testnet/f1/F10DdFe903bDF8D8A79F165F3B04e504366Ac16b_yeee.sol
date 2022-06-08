// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract yeee {
    // Below are the variables which consume storage slots.
    address public operator;

    constructor(address _operator) public {
        operator = _operator;
    }

    receive() external payable {}
}