// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract OracleEthToUsd {
    IOracle public ethOracle;
    IOracle public oracle;

    constructor(address _ethOracle, address _oracle) {
        ethOracle = IOracle(_ethOracle);
        oracle = IOracle(_oracle);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestAnswer() external view returns (int256) {
        int256 price = oracle.latestAnswer() * 1e18 / int256(10 ** oracle.decimals());
        return price * ethOracle.latestAnswer() / int256(10 ** ethOracle.decimals());
    }
}

interface IOracle {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}