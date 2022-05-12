//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract StorageExample {
    uint8  public a = 11;
    uint256 b=12;
    uint[2] c= [13,14];

    struct Entry {
        uint id;
        uint  value;
    }
    Entry d;
}