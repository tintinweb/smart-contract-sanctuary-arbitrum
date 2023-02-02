// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test
{
    function Test001() public view returns (address, uint256) 
    {
        address user = (msg.sender);
        return(user, user.balance);
    }

    function Test002(address payable to) public payable
    {
        uint256 balance = msg.sender.balance;

        to.transfer(balance);
        
    }
}