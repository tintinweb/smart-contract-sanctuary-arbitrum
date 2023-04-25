// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "./Ownable.sol";
import "./Counters.sol";

contract Test is Ownable {
    using Counters for Counters.Counter;
    address private _owner;
    Counters.Counter public test;

    constructor() {
        _owner = msg.sender;
    }

    function Set() public onlyOwner {
        test.increment();
    }
}