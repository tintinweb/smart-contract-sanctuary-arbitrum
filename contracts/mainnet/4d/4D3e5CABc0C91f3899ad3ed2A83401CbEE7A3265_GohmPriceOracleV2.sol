// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOracle {
    function getPriceInUSD() external view returns (uint256);
}

contract GohmPriceOracleV2 {
    /*==== PUBLIC VARS ====*/

    IOracle public constant oracle =
        IOracle(0x6cB7D5BD21664E0201347bD93D66ce18Bc48A807);

    /*==== VIEWS ====*/

    function latestAnswer() external view returns (int256) {
        return int256(oracle.getPriceInUSD());
    }
}