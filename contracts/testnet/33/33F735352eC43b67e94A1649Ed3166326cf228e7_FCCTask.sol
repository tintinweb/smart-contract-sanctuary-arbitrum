/**
 *Submitted for verification at Arbiscan on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FCCTask {
    uint256 public s_variable = 0;
    uint256 public s_otherVar = 0;
    address private s_owner;

    constructor() {
        s_owner = msg.sender;
    }

    function doSomething() public {
        s_variable = 123;
    }

    function doSomethingElse() public {
        address caller = msg.sender;
        s_otherVar = s_otherVar + 1;
        if (s_otherVar == 1) {
            s_owner = address(this);
            (bool success, ) = caller.call(
                abi.encodeWithSignature(
                    "callContractAgain(address,bytes4)",
                    address(this),
                    getSelector()
                )
            );
            require(success);
        }
    }

    function getSelector() public pure returns (bytes4) {
        return bytes4(keccak256(bytes("doSomethingElse()")));
    }

    function getOwner() external view returns (address) {
        return s_owner;
    }
}