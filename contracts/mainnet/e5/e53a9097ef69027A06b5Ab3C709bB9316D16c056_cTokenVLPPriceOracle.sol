/**
 *Submitted for verification at Arbiscan on 2023-04-06
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface cToken {
    function underlying() external view returns (address);
}

interface VLPVault {
    function getVLPPrice() external view returns (uint256);
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

contract cTokenVLPPriceOracle is PriceOracle {
    uint256 internal constant VLP_PRICE_DECIMALS = 5;
    address constant VELA_VLP_VAULT_ADDRESS = address(0x5957582F020301a2f732ad17a69aB2D8B2741241);
    
    // This oracle dervies its prices from Vela platform
    // All prices are either mantissa with 18 decimals or 0 if stale price. 0 reverts on main contract
    function getUnderlyingPrice(address cTokenAddress) override external view returns (uint256) {
        cTokenAddress; // Not used here
        uint256 price = VLPVault(VELA_VLP_VAULT_ADDRESS).getVLPPrice() * 1e18 / (10**VLP_PRICE_DECIMALS);
        return price;
    }
}