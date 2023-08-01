/**
 *Submitted for verification at Arbiscan on 2023-07-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract NumbersGame {
    uint FavoriteNumber = 22;

    function setNewFavoriteNumber(uint newNumber) external {
        FavoriteNumber=newNumber;
    }

    function letsSeeYourNumber() external view returns (uint) {
        return FavoriteNumber;
    }
}