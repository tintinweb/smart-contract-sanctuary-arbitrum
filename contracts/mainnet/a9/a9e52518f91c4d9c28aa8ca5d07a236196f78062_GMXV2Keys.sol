// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title GMXV2Keys
/// @dev Keys for values in the DataStore
library GMXV2Keys {
    /// @dev key for GMX V2's Router
    bytes32 public constant ROUTER = keccak256(abi.encode("GMXV2_ROUTER"));
    /// @dev key for GMX V2's Exchange Router
    bytes32 public constant EXCHANGE_ROUTER = keccak256(abi.encode("GMXV2_EXCHANGE_ROUTER"));
    /// @dev key for GMX V2's Order Vault
    bytes32 public constant ORDER_VAULT = keccak256(abi.encode("GMXV2_ORDER_VAULT"));
    /// @dev key for GMX V2's Order Handler
    bytes32 public constant ORDER_HANDLER = keccak256(abi.encode("GMXV2_ORDER_HANDLER"));
    /// @dev key for GMX V2's Reader
    bytes32 public constant GMX_READER = keccak256(abi.encode("GMXV2_GMX_READER"));
    /// @dev key for GMX V2's DataStore
    bytes32 public constant GMX_DATA_STORE = keccak256(abi.encode("GMXV2_GMX_DATA_STORE"));

    // -------------------------------------------------------------------------------------------

    function routeMarketToken(address _route) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("GMXV2_ROUTE_MARKET_TOKEN", _route));
    }
}