/**
 *Submitted for verification at Arbiscan.io on 2023-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INonfungiblePositionManager {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract NFTExistenceChecker {
    INonfungiblePositionManager public nonfungiblePositionManager;

    constructor(address _nonfungiblePositionManagerAddress) {
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManagerAddress);
    }

    function checkNFTsExistence(uint256[] memory nftIds) public view returns (uint256[] memory) {
        uint256[] memory existingNFTs = new uint256[](nftIds.length);
        uint256 count = 0;

        for (uint256 i = 0; i < nftIds.length; i++) {
            try nonfungiblePositionManager.ownerOf(nftIds[i]) {
                // If the call doesn't revert, the NFT exists
                existingNFTs[count] = nftIds[i];
                count++;
            } catch {
                // If the call reverts, the NFT doesn't exist, do nothing
            }
        }

        // Resize the array to fit the actual number of existing NFTs
        uint256[] memory resizedArray = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedArray[i] = existingNFTs[i];
        }

        return resizedArray;
    }
}