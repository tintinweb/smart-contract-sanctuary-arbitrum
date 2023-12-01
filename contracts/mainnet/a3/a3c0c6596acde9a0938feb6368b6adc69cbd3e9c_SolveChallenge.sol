// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract SolveChallenge {
    function getNumberr() external pure returns (bool, bytes memory) {
        return (true, abi.encode(99));
    }

    function getOwner() external pure returns (bool, bytes memory) {
        return (true, abi.encode(0xb04aeF2a3d2D86B01006cCD4339A2e943d9c6480));
    }
}