pragma solidity ^0.8.7;

// Deployed with the Atlas IDE
// https://app.atlaszk.com


contract Car {
    uint256 public currentGear;

    function changeGear(uint256 newGear) public {
        require(newGear >= 0 && newGear <= 5, "Invalid gear. Please enter a value between 0 and 5.");
        currentGear = newGear;
    }
}