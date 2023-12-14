/**
 *Submitted for verification at Arbiscan.io on 2023-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProofStorage {
    address public owner;
    mapping(bytes32 => bytes32) public proofs;

    event ProofStored(bytes32 proofName, bytes32 proof);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function storeProof(bytes32 proofName, bytes32 proof) public onlyOwner {
        require(proofs[proofName] == bytes32(0), "Proof name already exists");
        proofs[proofName] = proof;
        emit ProofStored(proofName, proof);
    }

    function getProof(bytes32 proofName) public onlyOwner view returns (bytes32) {
        return proofs[proofName];
    }
}