/**
 *Submitted for verification at Arbiscan on 2023-07-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract NumbersGame {
    uint favoritenumber = 713;

    function setNewfavoritenumber(uint newNumber) external {
        favoritenumber = newNumber; 
    }

    function letsSeeYourNumber () external view returns (uint) 
    {return favoritenumber;
    }

}