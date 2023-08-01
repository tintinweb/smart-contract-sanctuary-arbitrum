/**
 *Submitted for verification at Arbiscan on 2023-07-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract NumbersGame {
    uint favoriteNumber = 42;

    function setNewFavoriteNumber(uint newNumber) external {
        favoriteNumber = newNumber;
    }

    function letsSeeYourNumber() external view returns (uint)   {
        return favoriteNumber;
    }
}