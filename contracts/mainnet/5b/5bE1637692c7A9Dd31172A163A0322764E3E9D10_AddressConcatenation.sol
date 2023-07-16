// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract AddressConcatenation {
    function concatenateAddresses(address remoteAddress, address localAddress) public pure returns (bytes memory) {
        bytes memory remoteBytes = abi.encodePacked(remoteAddress);
        bytes memory localBytes = abi.encodePacked(localAddress);
        bytes memory concatenatedBytes = new bytes(remoteBytes.length + localBytes.length);

        uint256 i;
        uint256 j;

        for (i = 0; i < remoteBytes.length; i++) {
            concatenatedBytes[j++] = remoteBytes[i];
        }

        for (i = 0; i < localBytes.length; i++) {
            concatenatedBytes[j++] = localBytes[i];
        }

        return concatenatedBytes;
    }
}