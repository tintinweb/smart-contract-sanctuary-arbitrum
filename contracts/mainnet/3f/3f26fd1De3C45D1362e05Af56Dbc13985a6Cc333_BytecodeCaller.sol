/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract BytecodeCaller {
    function executeBytecode(
        bytes memory contractBytecode,
        bytes memory callData
    ) public returns (bytes memory returnData) {
        address pointer;
        assembly {
            pointer := create(0, add(contractBytecode, 0x20), mload(contractBytecode))
        }
        (, returnData) = pointer.call(callData);
    }
}