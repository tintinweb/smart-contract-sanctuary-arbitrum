/**
 *Submitted for verification at Arbiscan.io on 2024-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library BytesToString {
    
    error Failed(string);
    /*
    @dev: returns 0x08c379a0
    function getErrorSelector() public pure returns (bytes4) {
        return bytes4(keccak256("Error(string)"));

        
    }*/
    function revertString(bytes32 source)
        /*
        @dev: Converts our error messages from bytes32 to string. They are stored as bytes32 because it's a little 
        cheaper to deploy this way vs strings.
        */
        public
        pure
        returns (string memory result)
    {
        uint8 length = 0;
        while (source[length] != 0 && length < 32) {
            length++;
        }
        assembly {
            result := mload(0x40)
            // new "memory end" including padding (the string isn't larger than 32 bytes)
            mstore(0x40, add(result, 0x40))
            // store length in memory
            mstore(result, length)
            // write actual data
            mstore(add(result, 0x20), source)
        }
        
    }
}