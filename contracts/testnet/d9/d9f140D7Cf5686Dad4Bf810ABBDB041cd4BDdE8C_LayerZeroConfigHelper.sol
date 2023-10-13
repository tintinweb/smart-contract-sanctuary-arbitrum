// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/**
 * Helps configures LayerZero contracts
 */
contract LayerZeroConfigHelper
{
    function encodeAdapterParams(uint16 version, uint256 gasLimit) external pure returns (bytes memory)
    {
        return abi.encodePacked(version, gasLimit);
    }
    
    function getTrustedRemote(address remoteAddress, address localAddress) external pure returns (bytes memory)
    {
        return abi.encodePacked(remoteAddress, localAddress);
    }
}