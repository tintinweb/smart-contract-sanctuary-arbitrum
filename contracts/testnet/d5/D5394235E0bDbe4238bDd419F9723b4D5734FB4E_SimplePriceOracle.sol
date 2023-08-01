// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./Ownable.sol";

import "./PriceOracle.sol";

contract SimplePriceOracle is Ownable, PriceOracle {
    // token => price (18 decimals)
    mapping(address => uint256) public prices;

    constructor() {}

    /**
     * @notice Set the price of the cToken
     * @param tokens_ token addresses
     * @param prices_ prices of token in 18 decimals
     */
    function setPrices(
        address[] memory tokens_,
        uint256[] memory prices_
    ) external onlyOwner {
        require(
            tokens_.length == prices_.length,
            "tokens and prices length mismatch"
        );

        for (uint256 i = 0; i < tokens_.length; i++) {
            prices[tokens_[i]] = prices_[i];
        }
    }

    // price in 18 decimals
    function getPrice(CToken cToken) public view returns (uint256) {
        address underlying = CErc20Interface(address(cToken)).underlying();
        return prices[underlying];
    }

    // price is extended for comptroller usage based on decimals of exchangeRate
    function getUnderlyingPrice(
        CToken cToken
    ) external view virtual override returns (uint) {
        address underlying = CErc20Interface(address(cToken)).underlying();
        uint256 underlyingDecimals = EIP20Interface(underlying).decimals();
        return prices[underlying] * (10 ** (18 - underlyingDecimals));
    }
}