// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

contract ProofContract is Ownable {
    mapping(bytes32 => bool) public walletHashes;
    mapping(bytes32 => bytes32[]) public userWallets;
    uint256 public requiredEtherPerHash = 0.0000000003 ether;

    error InvalidEtherAmount();
    error InvalidHash();
    error TransferFailed();
    error EmptyuHash();

    event WalletHashesAdded(bytes32 indexed uHash, bytes32[] aHashes);

    constructor() Ownable(msg.sender) {}

    function addWalletHashes(
        bytes32 _uHash,
        bytes32[] calldata _aHashes
    ) public payable {
        if (_uHash == bytes32(0)) {
            revert EmptyuHash();
        }

        uint256 requiredEther = _aHashes.length * requiredEtherPerHash;
        if (msg.value != requiredEther) {
            revert InvalidEtherAmount();
        }

        for (uint256 i = 0; i < _aHashes.length; i++) {
            bytes32 hash = _aHashes[i];
            if (hash == bytes32(0)) {
                revert InvalidHash();
            }
            walletHashes[hash] = true;
            userWallets[_uHash].push(hash);
        }
        emit WalletHashesAdded(_uHash, _aHashes);
    }

    function setRequiredEtherPerHash(uint256 _newRequiredEther)
        public
        onlyOwner
    {
        requiredEtherPerHash = _newRequiredEther;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function checkWalletHash(bytes32 _hash) public view returns (bool) {
        return walletHashes[_hash];
    }

    function getWalletHashesByUser(bytes32 uHash)
        public
        view
        returns (bytes32[] memory)
    {
        return userWallets[uHash];
    }
}