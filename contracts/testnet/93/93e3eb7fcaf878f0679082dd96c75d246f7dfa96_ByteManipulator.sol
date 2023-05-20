/**
 *Submitted for verification at Arbiscan on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ByteManipulator {
    
    // Each pixel contains 4 bytes (RGBA), and the whole space is 48*48 pixels.
    // Hence we have 48*48*4 bytes.
    bytes public data = new bytes(48*48);
    mapping(uint256 => uint256) timestamps;

    // This function performs XOR operation on the data at the specified index with the color.
    function manipulateBytes(bytes calldata color, uint16 index, uint32 ts) public {
        require(index*4 + 4 <= data.length, "Index out of bounds");
        data[index*4] = color[0];
        timestamps[index] = ts;
    }
}