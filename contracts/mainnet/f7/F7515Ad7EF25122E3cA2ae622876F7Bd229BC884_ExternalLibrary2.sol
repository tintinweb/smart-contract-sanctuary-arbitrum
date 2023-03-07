// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

library ExternalLibrary2 {
    function calcNewUserEthBalance2(uint currentEthBalance, uint lockedNow) public pure returns (uint){
        return currentEthBalance + lockedNow;
    }
}