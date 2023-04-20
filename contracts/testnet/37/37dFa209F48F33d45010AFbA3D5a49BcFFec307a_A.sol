// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract A {
    uint256 public number;

    function increaseNumber() external {
        number++;
    }
}