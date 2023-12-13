/**
 *Submitted for verification at Arbiscan.io on 2023-12-11
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface cToken {
    function underlying() external view returns (address);
}

interface ZSToken {
    function pricePerToken() external view returns (uint256);
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

contract cTokenZSGMUSDCPriceOracle is PriceOracle {
    
    // All prices are either mantissa with 18 decimals or 0 if stale price. 0 reverts on main contract
    function getUnderlyingPrice(address cTokenAddress) override external view returns (uint256) {
        address underlyingZS = cToken(cTokenAddress).underlying();
        uint256 price = ZSToken(underlyingZS).pricePerToken();
        return price;
    }
}