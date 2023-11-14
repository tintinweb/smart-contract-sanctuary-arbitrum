// SPDX-License-Identifier: MIT

pragma solidity >=0.8.21;

/**
 * @title Destination domains for CCTP transfers
 * @author Warbler Labs Engineering
 * @notice See https://developers.circle.com/stablecoins/docs/cctp-technical-reference#domain
 */
library CctpTransfers {
  /// @notice Domain id for bridging to Base Mainnet
  uint32 public constant BASE_DOMAIN = 6;

  /// @notice Convert an address to bytes32 with 12 leading zero bytes
  function addressToBytes32(address addr) external pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
  }
}