/**
 *Submitted for verification at Arbiscan on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract NeroxFridge {
    event BeerUpdate(uint amount);
    uint private beerCount;

    function restockBeer(uint amount) external {
        beerCount = amount;
        emit BeerUpdate(amount);
        return;
    }

    function howMuchBeer() external view returns(uint) {
        return beerCount;
    }

    function takeBeerFromFridge() external {
        require(beerCount > 0, "No more beer. Please restock!");
        beerCount = beerCount-1;
        return;
    }
}