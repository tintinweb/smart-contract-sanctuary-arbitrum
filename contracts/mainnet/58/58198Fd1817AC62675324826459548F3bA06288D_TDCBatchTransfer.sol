// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Because the invoker of the safeTransferFrom() function (on the collection) is now the BatchTransfer contract address 
// (and not the user), the user needs to approve your contract to transfer their tokens before performing the actual transfer.

// Either by executing the approve() function multiple times, once for each token ID. Or a less safe option - by executing 
// the setApprovalForAll() giving the BatchTransfer contract address approval to transfer any of the user's tokens.
// https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#IERC721-setApprovalForAll-address-bool-

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract TDCBatchTransfer {
    IERC721 collection;

    constructor (address _collection) {
        collection = IERC721(_collection);
    }

    function batchTransfer(address _from, address _to, uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            collection.safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }
}