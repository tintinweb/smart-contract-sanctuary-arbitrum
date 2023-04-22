pragma solidity ^0.8.0;

interface IDIAOracle {
    function setValue(
        string memory key,
        uint128 value,
        uint128 timestamp
    ) external;

    function getValue(string memory key) external view returns (uint128, uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/oracle/IDIAOracle.sol';

contract MockDIAOracle is IDIAOracle {
    mapping(string => uint128) prices;

    constructor() {}

    function setValue(
        string memory key,
        uint128 value,
        uint128 // timestamp
    ) external override {
        prices[key] = value;
    }

    function getValue(
        string memory key
    ) external view override returns (uint128, uint128) {
        if (prices[key] > 0) {
            return (prices[key], uint128(block.timestamp));
        }
        return (10**8, uint128(block.timestamp));
    }
}