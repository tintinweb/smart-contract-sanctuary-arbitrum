// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOracle {
    function getPriceInUSD() external view returns (uint256);
}

contract GmxPriceOracleV2 {
    IOracle public constant oracle =
        IOracle(0x60E07B25Ba79bf8D40831cdbDA60CF49571c7Ee0);

    function latestAnswer() external view returns (int256) {
        return int256(oracle.getPriceInUSD());
    }
}