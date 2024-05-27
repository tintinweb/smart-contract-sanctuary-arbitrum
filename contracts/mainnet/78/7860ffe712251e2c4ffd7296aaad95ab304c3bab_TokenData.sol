/**
 *Submitted for verification at Arbiscan.io on 2024-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IAaveOracle {
    function getAssetPrices(address[] calldata assets) external view returns (uint256[] memory);
}

contract TokenData {
    function getRates(address[] memory tokenAddresses, address oracleAddress) public view returns (uint256[] memory, uint256) {
        IAaveOracle oracle = IAaveOracle(oracleAddress);
        uint256[] memory rates = oracle.getAssetPrices(tokenAddresses);

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
        address[] memory rateTokenAddresses,
        address[] memory balanceTokenAddresses,
        address oracleAddress,
        address walletAddress
    ) public view returns (
        uint256[] memory rates,
        uint256[] memory balances,
        uint256 blockTime
    ) {
        (rates, blockTime) = getRates(rateTokenAddresses, oracleAddress);
        (balances, ) = getBalances(balanceTokenAddresses, walletAddress);
    }
}