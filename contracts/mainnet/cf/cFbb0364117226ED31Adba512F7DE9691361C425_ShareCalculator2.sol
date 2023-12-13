/**
 *Submitted for verification at Arbiscan.io on 2023-12-11
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File contracts/shareCalculator/ShareCalculator2.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICalculateShare {
    function calculateShare(uint64 mainType, uint64 subType, address player, uint256 dollar) external returns (uint256);
}

// For chanceGame
contract ShareCalculator2 is ICalculateShare {
    uint8 public constant DECIMALS = 6; // No adjustment required, adjusted with a replacement contract
    uint256 public constant UNIT = (10 ** DECIMALS);
    uint256 public base = 10000;
    uint256 public threshold = 1000000 * UNIT;
    uint256 public curThreshold = 1000000 * UNIT;
    uint256 public round = 1;
    uint256 public accDollar;
    uint256 public accShare;

    address platform;

    modifier onlyPlatform() {
        require(msg.sender == platform, "Not granted");
        _;
    }

    constructor(address _platform) {
        platform = _platform;
    }

    function calculateShare(
        uint64 /* mainType */,
        uint64 /* subType */,
        address /* player */,
        uint256 dollar
    ) external onlyPlatform returns (uint256) {
        uint256 share = dollar * base;
        accShare += share;
        accDollar += dollar;
        if (accDollar >= threshold) {
            curThreshold = (curThreshold * 6) / 5;
            threshold += curThreshold;
            base = (base * 4) / 5;
            round += 1;
        }
        return share;
    }
}