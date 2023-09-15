/**
 *Submitted for verification at Arbiscan.io on 2023-09-14
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.4.22 <0.9.0; 

contract Random
{
    function random(uint totalEntries, string memory entropy) public view returns(uint)
    {
        return (uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,entropy))) % totalEntries) + 1;
    }
}