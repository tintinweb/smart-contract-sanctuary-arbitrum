/**
 *Submitted for verification at Arbiscan on 2023-07-27
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

contract NumbersGame {
    uint favouriteNumber = 42;

    function setNewFavouriteNumber( uint newNumber) external {
        favouriteNumber = newNumber;
    }

     function addToFavouriteNumber( uint newNumber) external {
        favouriteNumber = favouriteNumber + newNumber;
            }

    function letsSeeYourNumber() external view returns (uint) {
        return favouriteNumber;
    }
}