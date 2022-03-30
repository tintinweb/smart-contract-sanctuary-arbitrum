/**
 *Submitted for verification at Arbiscan on 2022-03-29
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

interface IAirdropVesting {
    function depositFor(address _user, uint256 _amount) external;
}

// MerkleDistributor for ARBY airdrop
// Based on the ellipsis.finance airdrop contract
contract MerkleDistributor {

    bytes32 public merkleRoot = 0xf50771604d712834e2107f627010f733bf31a4305c08ca1a293a497272872098;
    //The vesting contract should be deployed before the distributor
    address public airdropVesting;
    // This is a packed array of booleans.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;


    constructor(address _address) public {
        airdropVesting = _address;
    }

    function isClaimed(uint256 merkleIndex, uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[merkleIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 merkleIndex, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[merkleIndex][claimedWordIndex] = claimedBitMap[merkleIndex][claimedWordIndex] | (1 << claimedBitIndex);
    }

    //`merkleIndex` is unused because there's only one merkle root
    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) external {
        require(!isClaimed(0, index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and vest the tokens
        _setClaimed(0, index);
        IAirdropVesting(airdropVesting).depositFor(msg.sender, amount);

        emit Claimed(merkleIndex, index, msg.sender, amount);
    }

    function isValidClaim(address _user, uint256 index, uint256 amount, bytes32[] calldata merkleProof) external view returns (bool) {
        if(isClaimed(0, index)) return false;

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, _user, amount));
        return verify(merkleProof, merkleRoot, node);
    }

    function verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf) public pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    /* ========== EVENTS ========== */

    event Claimed(
        uint256 merkleIndex,
        uint256 index,
        address account,
        uint256 amount
    );
}