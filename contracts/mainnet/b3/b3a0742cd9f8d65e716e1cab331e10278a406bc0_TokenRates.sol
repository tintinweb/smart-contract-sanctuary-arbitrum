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
    function getRates(address[] memory srcTokens, address[] memory dstTokens, address oracleAddress) public view returns (uint256[] memory) {
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

        return rates;
    }
}