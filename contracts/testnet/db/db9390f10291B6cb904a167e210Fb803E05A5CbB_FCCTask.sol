/**
 *Submitted for verification at Arbiscan on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FCCTask {
    uint256 public s_variable = 0;
    uint256 public s_otherVar = 0;
    address private s_owner;

    constructor() public {
        s_owner = msg.sender;
    }

    function doSomething() public {
        s_variable = 123;
    }

    function doSomethingElse() public {
        s_otherVar = s_otherVar + 1;
    }

    function getSelector() public pure returns (bytes4) {
        return bytes4(keccak256(bytes("doSomethingElse()")));
    }

    function getOwner() external view returns (address) {
        return s_owner;
    }
}