/**
 *Submitted for verification at Arbiscan.io on 2024-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiDelegateCaller {
    function multiDelegatecall(
        address[] calldata targets,
        bytes[] calldata data
    ) external {
        require(targets.length == data.length, "Invalid input");
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].delegatecall(data[i]);
            require(success, "Delegatecall failed");
        }
    }
}