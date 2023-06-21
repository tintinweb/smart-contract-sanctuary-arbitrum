// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

contract Counter {
    uint public count;

    function inc() external {
        count += 1;
    }

    function getCounter() external view returns (uint) {
        return count;
    }
}