// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test
{
    function Test001() public view returns (address, uint256) 
    {
        return(msg.sender, msg.sender.balance);
    }
}