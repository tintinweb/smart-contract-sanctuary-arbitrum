/**
 *Submitted for verification at Arbiscan on 2023-07-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract NumbersGame {
    uint favouriteNumber = 42;

    function setNewFavouriteNumber(uint newNumber) external {
        favouriteNumber = newNumber;
    }

    function letsSeeYourNumber() external view returns (uint){
        return favouriteNumber;
    }
}