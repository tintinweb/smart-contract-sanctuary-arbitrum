/**
 *Submitted for verification at Arbiscan on 2023-05-01
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface cToken {
    function underlying() external view returns (address);
}

interface ChainLinkOracle{
    function latestAnswer() external view returns (int256);
}

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address cToken) virtual external view returns (uint);
}

contract cTokenRETHPriceOracle is PriceOracle {
    uint256 internal constant CHAINLINK_ETH_PRICE_SCALE = 8;
    address constant RETH_CHAINLINK_ORACLE = address(0xF3272CAfe65b190e76caAF483db13424a3e23dD2);
    address constant ETH_CHAINLINK_ORACLE = address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    
    // This oracle derives its prices from Chainlink
    // All prices are either mantissa with 18 decimals or 0 if stale price. 0 reverts on main contract
    function getUnderlyingPrice(address cTokenAddress) override external view returns (uint256) {
        cTokenAddress; // Not used here
        uint256 price = uint256(ChainLinkOracle(RETH_CHAINLINK_ORACLE).latestAnswer()) * uint256(ChainLinkOracle(ETH_CHAINLINK_ORACLE).latestAnswer()) / (10 ** CHAINLINK_ETH_PRICE_SCALE);
        return price;
    }
}