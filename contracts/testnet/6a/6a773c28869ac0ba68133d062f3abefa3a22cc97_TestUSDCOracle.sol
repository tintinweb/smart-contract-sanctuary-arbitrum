// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract TestUSDCOracle { 

    int256 price = 100000000;
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            return (1,price, 1, 1, 1);
        }

    function setPrice(int256 newPrice) public {
        price = newPrice;
    }
    function decimals() external view returns (uint8) {
        return 8;
    }
}