/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/mocks/MockFallbackOracle.sol

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

contract FallbackPriceOracle {
  // Map of asset prices (asset => price)
  mapping(address => uint256) internal prices;

  uint256 internal ethPriceUsd;

  event AssetPriceUpdated(address asset, uint256 price, uint256 timestamp);
  event EthPriceUpdated(uint256 price, uint256 timestamp);

  function getAssetPrice(address asset) external view returns (uint256) {
    return prices[asset];
  }

  // set access control if we want to deploy this to mainnet
  function setAssetPrice(address asset, uint256 price) external {
    prices[asset] = price;
    emit AssetPriceUpdated(asset, price, block.timestamp);
  }

  function getEthUsdPrice() external view returns (uint256) {
    return ethPriceUsd;
  }

  function setEthUsdPrice(uint256 price) external {
    ethPriceUsd = price;
    emit EthPriceUpdated(price, block.timestamp);
  }
}