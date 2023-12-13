// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract Counter {
    uint256 public count;

    function incrementCount() public {
        count += 1;
    }

    function decrementCount() public {
        require(count > 0, "Count is already at minimum value");
        count -= 1;
    }
}