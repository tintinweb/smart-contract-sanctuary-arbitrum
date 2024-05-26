/**
 *Submitted for verification at Arbiscan.io on 2024-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IOracle {
    function getRate(IERC20 srcToken, IERC20 dstToken, bool useWrappers) external view returns (uint256 weightedRate);
}

contract TokenData {
    function getRates(address[] memory srcTokens, address[] memory dstTokens, address oracleAddress) public view returns (uint256[] memory, uint256) {
        require(srcTokens.length == dstTokens.length, "Arrays must be of the same length");

        uint256[] memory rates = new uint256[](srcTokens.length);
        IOracle oracle = IOracle(oracleAddress);

        for (uint256 i = 0; i < srcTokens.length; i++) {
            IERC20 srcToken = IERC20(srcTokens[i]);
            IERC20 dstToken = IERC20(dstTokens[i]);

            uint256 rate = oracle.getRate(srcToken, dstToken, false);
            uint8 decimals = srcToken.decimals();
            uint256 adjustedRate = rate / (10 ** (24 - decimals));

            rates[i] = adjustedRate;
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
        address[] memory srcTokens,
        address[] memory dstTokens,
        address oracleAddress,
        address[] memory tokenAddresses,
        address walletAddress
    ) public view returns (
        uint256[] memory rates,
        uint256[] memory balances,
        uint256 blockTime
    ) {
        (rates, blockTime) = getRates(srcTokens, dstTokens, oracleAddress);
        (balances, ) = getBalances(tokenAddresses, walletAddress);
    }
}