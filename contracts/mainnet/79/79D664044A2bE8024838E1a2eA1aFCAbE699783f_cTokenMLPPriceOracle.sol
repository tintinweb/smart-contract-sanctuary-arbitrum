/**
 *Submitted for verification at Arbiscan on 2023-05-01
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface cToken {
    function underlying() external view returns (address);
    function totalSupply() external view returns (uint256);
}

interface MLPManager {
    function getAum(bool maximise) external view returns (uint256);
    function PRICE_PRECISION() external view returns (uint256);
    function mlp() external view returns (address);
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

contract cTokenMLPPriceOracle is PriceOracle {
    uint256 internal constant MLP_PRICE_DECIMALS_REDUCTION = 24;
    address constant MYCELIUM_MLP_MANAGER_ADDRESS = address(0x2DE28AB4827112Cd3F89E5353Ca5A8D80dB7018f);

    
    // This oracle dervies its prices from GMX platform
    // All prices are either mantissa with 18 decimals or 0 if stale price. 0 reverts on main contract
    function getUnderlyingPrice(address cTokenAddress) override external view returns (uint256) {
        cTokenAddress; // Not used here
        address mlpAddress = MLPManager(MYCELIUM_MLP_MANAGER_ADDRESS).mlp();
        uint256 aum = MLPManager(MYCELIUM_MLP_MANAGER_ADDRESS).getAum(true);
        uint256 supply = cToken(mlpAddress).totalSupply();
        uint256 price = aum * MLPManager(MYCELIUM_MLP_MANAGER_ADDRESS).PRICE_PRECISION() / supply;
        price = price / (10**MLP_PRICE_DECIMALS_REDUCTION);
        return price;
    }
}