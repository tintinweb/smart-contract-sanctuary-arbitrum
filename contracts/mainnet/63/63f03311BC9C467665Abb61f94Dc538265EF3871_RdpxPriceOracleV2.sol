// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICustomPriceOracle {
    function getPriceInUSD() external view returns (uint256);
}

contract RdpxPriceOracleV2 {
    ICustomPriceOracle public constant oracle =
        ICustomPriceOracle(0xC0cdD1176aA1624b89B7476142b41C04414afaa0);

    function latestAnswer() external view returns (int256) {
        return int256(oracle.getPriceInUSD());
    }
}