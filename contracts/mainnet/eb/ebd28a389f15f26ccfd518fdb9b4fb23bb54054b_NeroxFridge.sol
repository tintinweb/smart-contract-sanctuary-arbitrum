/**
 *Submitted for verification at Arbiscan on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract NeroxFridge {
    event BeerUpdate(uint16 amount);
    uint private beerCount;

    function restockBeer(uint16 amount) external {
        beerCount = amount;
        emit BeerUpdate(amount);
        return;
    }

    function takeBeerFromFridge() external {
        require(beerCount > 0, "No more beer. Please restock!");
        beerCount = beerCount-1;
        return;
    }
}