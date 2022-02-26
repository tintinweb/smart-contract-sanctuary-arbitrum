// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICustomPriceOracle {
    function getPriceInUSD() external view returns (uint256);
}

contract DpxPriceOracleV2 {
    ICustomPriceOracle public constant oracle =
        ICustomPriceOracle(0x252C07E0356d3B1a8cE273E39885b094053137b9);

    function latestAnswer() external view returns (int256) {
        return int256(oracle.getPriceInUSD());
    }
}