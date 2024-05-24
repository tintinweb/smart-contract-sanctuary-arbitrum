/**
 *Submitted for verification at Arbiscan.io on 2024-05-24
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

contract TokenRates {
    function getRates(address[] memory srcTokens, address[] memory dstTokens, address oracleAddress) public view returns (uint256[] memory, uint256) {
        require(srcTokens.length == dstTokens.length, "Arrays must be of the same length");

        uint256[] memory rates = new uint256[](srcTokens.length);
        IOracle oracle = IOracle(oracleAddress);

        for (uint256 i = 0; i < srcTokens.length; i++) {
            IERC20 srcToken = IERC20(srcTokens[i]);
            IERC20 dstToken = IERC20(dstTokens[i]);

            // Get the rate from the Oracle
            uint256 rate = oracle.getRate(srcToken, dstToken, false);

            // Get the decimals of the srcToken
            uint8 decimals = srcToken.decimals();

            // Adjust the rate according to the token decimals
            uint256 adjustedRate = rate / (10 ** (24 - decimals));

            // Store the adjusted rate in the array
            rates[i] = adjustedRate;
        }

        uint256 blockTime = block.timestamp;

        return (rates, blockTime);
    }
}