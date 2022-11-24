/**
 *Submitted for verification at Arbiscan on 2022-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Storage {
    mapping(uint=>uint) i2i; //position is 0

    function setInt(uint key, uint val) public {        
        i2i[key] = val;            
    }

    function getInt(uint key) 
        public
        view
        returns (uint)
    {
        return i2i[key];
    }

    function mapLocationInt(uint256 slot, uint256 k) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(k, slot)));
    }
}