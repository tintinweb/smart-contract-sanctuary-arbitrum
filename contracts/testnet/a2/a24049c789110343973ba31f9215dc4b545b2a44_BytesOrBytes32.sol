/**
 *Submitted for verification at Arbiscan on 2022-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract BytesOrBytes32 {
    
    event FirstBytes32(bytes32 first, bytes1 first_1);

    function trade(bytes calldata payload_bytes) external {
        bytes memory first = payload_bytes[:31];
        bytes32 first_32 = bytes32(first);
        bytes1 first_1 = first_32[0];
        //bytes2 first_2 = bytes2(first[0:2]);
        emit FirstBytes32(first_32, first_1);

    } 
}