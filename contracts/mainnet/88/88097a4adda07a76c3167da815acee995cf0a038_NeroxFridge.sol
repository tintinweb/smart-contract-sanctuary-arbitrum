/**
 *Submitted for verification at Arbiscan on 2023-05-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract NeroxFridge {
    event inventoryUpdate(string beverage, uint16 amount); 
    mapping(string => uint16) private _inventory;  //data structure to store how much inventory there is

    function getAmountOfBeverage(string calldata beverage) external view returns (uint16)  {
        return _inventory[beverage];
    }

    function restockFridge(string calldata beverage, uint16 amount) external returns (bool) {
        require(amount > 0, "At least one drink");
        uint16 newAmount = _inventory[beverage] + amount;
        _inventory[beverage] = newAmount;
        emit inventoryUpdate(beverage, amount);
        return true;
    }

    function takeBeverageFromFridge(string calldata beverage) external returns (bool) {
        uint16 amount = _inventory[beverage];
        require(amount > 0, "Your beverage cannot be found. Please restock");
        amount = amount - 1;
        _inventory[beverage] = amount;
        emit inventoryUpdate(beverage, amount);
        return true;
    }
}