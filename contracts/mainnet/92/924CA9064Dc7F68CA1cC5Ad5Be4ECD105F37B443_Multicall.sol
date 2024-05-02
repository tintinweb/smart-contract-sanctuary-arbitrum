/**
 *Submitted for verification at Arbiscan.io on 2024-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multicall {
    function aggregate(bytes[] memory calls) external returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success, "Delegate call failed");
            results[i] = result;
        }
    }
}