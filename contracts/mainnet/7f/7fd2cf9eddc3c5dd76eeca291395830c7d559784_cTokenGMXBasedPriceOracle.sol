/**
 *Submitted for verification at Arbiscan on 2023-04-06
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface cToken {
    function underlying() external view returns (address);
}

interface GMXVault {
    function priceFeed() external view returns (address);
}

interface GMXPriceFeed {
    function getLatestPrimaryPrice(address) external view returns (uint256); // Returns tokens with 8 decimals
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

contract cTokenGMXBasedPriceOracle is PriceOracle {
    uint256 internal constant GMX_PRICE_DECIMALS = 8;
    address constant GMX_VAULT_ADDRESS = address(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    
    // This oracle dervies its prices from GMX platform
    // All prices are either mantissa with 18 decimals or 0 if stale price. 0 reverts on main contract
    function getUnderlyingPrice(address cTokenAddress) override external view returns (uint256) {
        address _underlying = cToken(cTokenAddress).underlying();
        address feed = GMXVault(GMX_VAULT_ADDRESS).priceFeed();
        uint256 price = GMXPriceFeed(feed).getLatestPrimaryPrice(_underlying) * 1e18 / (10**GMX_PRICE_DECIMALS);
        return price;
    }
}