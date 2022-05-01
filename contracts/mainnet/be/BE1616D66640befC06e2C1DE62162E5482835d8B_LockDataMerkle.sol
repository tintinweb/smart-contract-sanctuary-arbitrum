/**
 *Submitted for verification at Arbiscan on 2022-04-30
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

interface IAirdropVesting {
    function reduceVestStart(address _user, uint256 _amountReduced) external;
}

// MerkleDistributor for lock data
// Based on the ellipsis.finance airdrop contract
contract LockDataMerkle {

    bytes32[] public merkleRoots;
    bytes32 public pendingMerkleRoot;
    uint256 public lastRoot;

    //sanity check: can't reduce the vesting time by more than 2 years per cycle
    //the max vest start reduction should only be 610 days
    uint256 public constant MAX_VEST_REDUCTION = 730 days;

    // admin address which can propose adding a new merkle root
    address public proposalAuthority;
    //The vesting contract should be deployed before the distributor
    address public airdropVesting;
    // This is a packed array of booleans.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;
    mapping(uint256 => bool) public invalidRoots;


    constructor(address _address) public {
        airdropVesting = _address;
        proposalAuthority = msg.sender;
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

    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) external {
        require(merkleIndex < merkleRoots.length, "Invalid merkleIndex");
        require(!isClaimed(merkleIndex, index), 'Reduction already claimed.');
        require(!invalidRoots[merkleIndex], "Root has been invalidated");
        require(amount <= MAX_VEST_REDUCTION, "invalid lock reduction time"); //could be caused by generating an invalid root

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(verify(merkleProof, merkleRoots[merkleIndex], node), 'Invalid proof.');

        // Mark it claimed and reduce the vest time
        _setClaimed(merkleIndex, index);
        IAirdropVesting(airdropVesting).reduceVestStart(msg.sender, amount);

        emit Claimed(merkleIndex, index, msg.sender, amount);
    }

    function isValidClaim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) external view returns (bool) {
        if(isClaimed(merkleIndex, index)) return false;

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        return verify(merkleProof, merkleRoots[merkleIndex], node);
    }

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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

    /* ========== ADMIN FUNCTIONS ========== */

    // Each month, a new lock data snapshot is submitted
    function submitMerkleRoot(bytes32 _merkleRoot) public {
        require(msg.sender == proposalAuthority);
        merkleRoots.push(_merkleRoot);
    }

    // Invalidate a merkle root if required
    // The root should have been tested to make sure it's correct, but mistakes can happen i.e. I submit the previous month's root by accident
    function setMerkleRootValidity(uint256 _index, bool _isInvalid) public {
        require(msg.sender == proposalAuthority);
        invalidRoots[_index] = _isInvalid;
    }

    /* ========== EVENTS ========== */

    event Claimed(
        uint256 merkleIndex,
        uint256 index,
        address account,
        uint256 amount
    );
}