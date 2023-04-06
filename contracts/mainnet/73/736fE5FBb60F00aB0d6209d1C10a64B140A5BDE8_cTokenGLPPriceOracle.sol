/**
 *Submitted for verification at Arbiscan on 2023-04-06
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface cToken {
    function underlying() external view returns (address);
}

interface GLPManager {
    function getPrice(bool _maximise) external view returns (uint256);
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

contract cTokenGLPPriceOracle is PriceOracle {
    uint256 internal constant GLP_PRICE_DECIMALS_REDUCTION = 12;
    address constant GMX_GLP_MANAGER_ADDRESS = address(0x3963FfC9dff443c2A94f21b129D429891E32ec18);
    
    // This oracle dervies its prices from GMX platform
    // All prices are either mantissa with 18 decimals or 0 if stale price. 0 reverts on main contract
    function getUnderlyingPrice(address cTokenAddress) override external view returns (uint256) {
        cTokenAddress; // Not used here
        uint256 price = GLPManager(GMX_GLP_MANAGER_ADDRESS).getPrice(true) / (10**GLP_PRICE_DECIMALS_REDUCTION);
        return price;
    }
}