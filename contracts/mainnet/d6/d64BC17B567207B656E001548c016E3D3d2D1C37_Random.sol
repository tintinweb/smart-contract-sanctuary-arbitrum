//SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity >=0.5.0 <0.8.7;

contract Random
{
    function getRandom(uint _seed) public view returns(uint) 
    {
        return uint(keccak256(abi.encodePacked(_seed, block.timestamp, block.difficulty, msg.sender)));
    }
}