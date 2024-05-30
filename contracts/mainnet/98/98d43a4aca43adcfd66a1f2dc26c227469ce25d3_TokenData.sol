/**
 *Submitted for verification at Arbiscan.io on 2024-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IAaveOracle {
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
}

interface IOneInchRate {
    function getRate(
        address srcToken,
        address dstToken,
        bool useWrappers
    ) external view returns (uint256);
}

contract TokenData {
    function getRates(address[] memory tokenAddresses, address oracleAddress) public view returns (uint256[] memory, uint256) {
        IAaveOracle oracle = IAaveOracle(oracleAddress);
        uint256[] memory rates = oracle.getAssetsPrices(tokenAddresses);

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
        address walletAddress,
        address[] memory srcTokens,
        address[] memory dstTokens,
        address oneInchContract
    ) public view returns (
        uint256[] memory rates,
        uint256[] memory balances,
        uint256 blockTime,
        uint256[] memory oneInchRates
    ) {
        (rates, blockTime) = getRates(rateTokenAddresses, oracleAddress);
        (balances, ) = getBalances(balanceTokenAddresses, walletAddress);
        oneInchRates = getOneInchRates(srcTokens, dstTokens, oneInchContract);
    }

    function getOneInchRates(
        address[] memory srcTokens,
        address[] memory dstTokens,
        address oneInchContract
    ) public view returns (uint256[] memory) {
        require(srcTokens.length == dstTokens.length, "Token arrays must be of equal length");

        uint256[] memory rates = new uint256[](srcTokens.length);
        IOneInchRate oneInchRateContract = IOneInchRate(oneInchContract);

        for (uint256 i = 0; i < srcTokens.length; i++) {
            uint256 rate = oneInchRateContract.getRate(srcTokens[i], dstTokens[i], false);
            uint8 srcDecimals = IERC20(srcTokens[i]).decimals();
            uint256 adjustedRate = (rate * 10**6) / (24 - srcDecimals);
            rates[i] = adjustedRate;
        }

        return rates;
    }
}