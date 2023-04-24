/**
 *Submitted for verification at Arbiscan on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Chinese {

    string public name;

    function setName(string memory _name) public {
        name = _name;
    }

    function getBytes32BySlot(uint256 slot) public view returns (bytes32) {
        bytes32 valueBytes32;
        assembly {
            valueBytes32 := sload(slot)
        }
        return valueBytes32;
    }
    
}