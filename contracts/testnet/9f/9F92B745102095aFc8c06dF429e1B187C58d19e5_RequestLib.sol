// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library RequestLib {
    function generateId(
        address callbackContract,
        bytes memory callbackArgs
    ) external pure returns (bytes32) {
        return keccak256(abi.encode(callbackContract, callbackArgs));
    }
}