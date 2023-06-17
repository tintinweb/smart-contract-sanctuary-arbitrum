// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MockChainlink {
    function latestRoundData() external pure returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (0, 100000000,0,0,0);
    }

    function decimals() external view returns(uint) {
        return 18;
    }
}