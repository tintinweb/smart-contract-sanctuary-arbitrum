/**
 *Submitted for verification at Arbiscan.io on 2024-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

contract TokenData {
    function getRates(address[] memory aggregatorAddresses) public view returns (int256[] memory, uint256) {
        int256[] memory rates = new int256[](aggregatorAddresses.length);

        for (uint256 i = 0; i < aggregatorAddresses.length; i++) {
            AggregatorInterface aggregator = AggregatorInterface(aggregatorAddresses[i]);
            int256 rate = aggregator.latestAnswer();
            rates[i] = rate;
        }

        uint256 blockTime = block.timestamp;

        return (rates, blockTime);
    }

    function getBalances(address[] memory tokenAddresses, address walletAddress) public view returns (uint256[] memory, uint256) {
        uint256[] memory balances = new uint256[](tokenAddresses.length);

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            IERC20 token = IERC20(tokenAddresses[i]);
            uint256 balance = token.balanceOf(walletAddress);
            uint8 decimals = token.decimals();

            // we expect to adjust balance by 1000000 to get float value with precision
            uint256 adjustedBalance = (balance * 10**6) / (10**decimals);

            balances[i] = adjustedBalance;
        }

        uint256 blockTime = block.timestamp;

        return (balances, blockTime);
    }

    function getRatesAndBalances(
        address[] memory aggregatorAddresses,
        address[] memory tokenAddresses,
        address walletAddress
    ) public view returns (
        int256[] memory rates,
        uint256[] memory balances,
        uint256 blockTime
    ) {
        (rates, blockTime) = getRates(aggregatorAddresses);
        (balances, ) = getBalances(tokenAddresses, walletAddress);
    }
}