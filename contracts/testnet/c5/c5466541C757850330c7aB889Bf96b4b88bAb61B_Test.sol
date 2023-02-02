// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test
{
    function Test001() public view returns (address, uint256) 
    {
        address user = Test002(msg.sender);
        return(user, user.balance);
    }

    function Test002(address user) public view returns(address)
    {
        return user;
    }
}