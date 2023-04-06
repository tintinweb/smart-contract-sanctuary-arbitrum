// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/ISemaphore.sol";
import "./interfaces/ISemaphoreVerifier.sol";
import "./base/SemaphoreGroups.sol";

/// @title Semaphore
/// @dev This contract uses the Semaphore base contracts to provide a complete service
/// to allow admins to create and manage groups and their members to generate Semaphore proofs
/// and verify them. Group admins can add, update or remove group members, and can be
/// an Ethereum account or a smart contract. This contract also assigns each new Merkle tree
/// generated with a new root a duration (or an expiry) within which the proofs generated with that root
/// can be validated.
contract Semaphore is ISemaphore, SemaphoreGroups {
    ISemaphoreVerifier public verifier;

    /// @dev Gets a group id and returns the group parameters.
    mapping(uint256 => Group) public groups;

    /// @dev Checks if the group admin is the transaction sender.
    /// @param groupId: Id of the group.
    modifier onlyGroupAdmin(uint256 groupId) {
        if (groups[groupId].admin != _msgSender()) {
            revert Semaphore__CallerIsNotTheGroupAdmin();
        }
        _;
    }

    /// @dev Checks if there is a verifier for the given tree depth.
    /// @param merkleTreeDepth: Depth of the tree.
    modifier onlySupportedMerkleTreeDepth(uint256 merkleTreeDepth) {
        if (merkleTreeDepth < 16 || merkleTreeDepth > 32) {
            revert Semaphore__MerkleTreeDepthIsNotSupported();
        }
        _;
    }

    /// @dev Initializes the Semaphore verifier used to verify the user's ZK proofs.
    /// @param _verifier: Semaphore verifier address.
    constructor(ISemaphoreVerifier _verifier) {
        verifier = _verifier;
    }

    /// @dev See {ISemaphore-createGroup}.
    function createGroup(
        uint256 groupId,
        uint256 merkleTreeDepth,
        address admin
    ) external override onlySupportedMerkleTreeDepth(merkleTreeDepth) {
        _createGroup(groupId, merkleTreeDepth);

        groups[groupId].admin = admin;
        groups[groupId].merkleTreeDuration = 1 hours;

        emit GroupAdminUpdated(groupId, address(0), admin);
    }

    /// @dev See {ISemaphore-createGroup}.
    function createGroup(
        uint256 groupId,
        uint256 merkleTreeDepth,
        address admin,
        uint256 merkleTreeDuration
    ) external override onlySupportedMerkleTreeDepth(merkleTreeDepth) {
        _createGroup(groupId, merkleTreeDepth);

        groups[groupId].admin = admin;
        groups[groupId].merkleTreeDuration = merkleTreeDuration;

        emit GroupAdminUpdated(groupId, address(0), admin);
    }

    /// @dev See {ISemaphore-updateGroupAdmin}.
    function updateGroupAdmin(uint256 groupId, address newAdmin) external override onlyGroupAdmin(groupId) {
        groups[groupId].admin = newAdmin;

        emit GroupAdminUpdated(groupId, _msgSender(), newAdmin);
    }

    /// @dev See {ISemaphore-updateGroupMerkleTreeDuration}.
    function updateGroupMerkleTreeDuration(
        uint256 groupId,
        uint256 newMerkleTreeDuration
    ) external override onlyGroupAdmin(groupId) {
        uint256 oldMerkleTreeDuration = groups[groupId].merkleTreeDuration;

        groups[groupId].merkleTreeDuration = newMerkleTreeDuration;

        emit GroupMerkleTreeDurationUpdated(groupId, oldMerkleTreeDuration, newMerkleTreeDuration);
    }

    /// @dev See {ISemaphore-addMember}.
    function addMember(uint256 groupId, uint256 identityCommitment) external override onlyGroupAdmin(groupId) {
        _addMember(groupId, identityCommitment);

        uint256 merkleTreeRoot = getMerkleTreeRoot(groupId);

        groups[groupId].merkleRootCreationDates[merkleTreeRoot] = block.timestamp;
    }

    /// @dev See {ISemaphore-addMembers}.
    function addMembers(
        uint256 groupId,
        uint256[] calldata identityCommitments
    ) external override onlyGroupAdmin(groupId) {
        for (uint256 i = 0; i < identityCommitments.length; ) {
            _addMember(groupId, identityCommitments[i]);

            unchecked {
                ++i;
            }
        }

        uint256 merkleTreeRoot = getMerkleTreeRoot(groupId);

        groups[groupId].merkleRootCreationDates[merkleTreeRoot] = block.timestamp;
    }

    /// @dev See {ISemaphore-updateMember}.
    function updateMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256 newIdentityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external override onlyGroupAdmin(groupId) {
        _updateMember(groupId, identityCommitment, newIdentityCommitment, proofSiblings, proofPathIndices);

        uint256 merkleTreeRoot = getMerkleTreeRoot(groupId);

        groups[groupId].merkleRootCreationDates[merkleTreeRoot] = block.timestamp;
    }

    /// @dev See {ISemaphore-removeMember}.
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external override onlyGroupAdmin(groupId) {
        _removeMember(groupId, identityCommitment, proofSiblings, proofPathIndices);

        uint256 merkleTreeRoot = getMerkleTreeRoot(groupId);

        groups[groupId].merkleRootCreationDates[merkleTreeRoot] = block.timestamp;
    }

    /// @dev See {ISemaphore-verifyProof}.
    function verifyProof(
        uint256 groupId,
        uint256 merkleTreeRoot,
        uint256 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external override {
        uint256 merkleTreeDepth = getMerkleTreeDepth(groupId);

        if (merkleTreeDepth == 0) {
            revert Semaphore__GroupDoesNotExist();
        }

        uint256 currentMerkleTreeRoot = getMerkleTreeRoot(groupId);

        // A proof could have used an old Merkle tree root.
        // https://github.com/semaphore-protocol/semaphore/issues/98
        if (merkleTreeRoot != currentMerkleTreeRoot) {
            uint256 merkleRootCreationDate = groups[groupId].merkleRootCreationDates[merkleTreeRoot];
            uint256 merkleTreeDuration = groups[groupId].merkleTreeDuration;

            if (merkleRootCreationDate == 0) {
                revert Semaphore__MerkleTreeRootIsNotPartOfTheGroup();
            }

            if (block.timestamp > merkleRootCreationDate + merkleTreeDuration) {
                revert Semaphore__MerkleTreeRootIsExpired();
            }
        }

        if (groups[groupId].nullifierHashes[nullifierHash]) {
            revert Semaphore__YouAreUsingTheSameNillifierTwice();
        }

        verifier.verifyProof(merkleTreeRoot, nullifierHash, signal, externalNullifier, proof, merkleTreeDepth);

        groups[groupId].nullifierHashes[nullifierHash] = true;

        emit ProofVerified(groupId, merkleTreeRoot, nullifierHash, externalNullifier, signal);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title Semaphore contract interface.
interface ISemaphore {
    error Semaphore__CallerIsNotTheGroupAdmin();
    error Semaphore__MerkleTreeDepthIsNotSupported();
    error Semaphore__MerkleTreeRootIsExpired();
    error Semaphore__MerkleTreeRootIsNotPartOfTheGroup();
    error Semaphore__YouAreUsingTheSameNillifierTwice();

    /// It defines all the group parameters, in addition to those in the Merkle tree.
    struct Group {
        address admin;
        uint256 merkleTreeDuration;
        mapping(uint256 => uint256) merkleRootCreationDates;
        mapping(uint256 => bool) nullifierHashes;
    }

    /// @dev Emitted when an admin is assigned to a group.
    /// @param groupId: Id of the group.
    /// @param oldAdmin: Old admin of the group.
    /// @param newAdmin: New admin of the group.
    event GroupAdminUpdated(uint256 indexed groupId, address indexed oldAdmin, address indexed newAdmin);

    /// @dev Emitted when the Merkle tree duration of a group is updated.
    /// @param groupId: Id of the group.
    /// @param oldMerkleTreeDuration: Old Merkle tree duration of the group.
    /// @param newMerkleTreeDuration: New Merkle tree duration of the group.
    event GroupMerkleTreeDurationUpdated(
        uint256 indexed groupId,
        uint256 oldMerkleTreeDuration,
        uint256 newMerkleTreeDuration
    );

    /// @dev Emitted when a Semaphore proof is verified.
    /// @param groupId: Id of the group.
    /// @param merkleTreeRoot: Root of the Merkle tree.
    /// @param nullifierHash: Nullifier hash.
    /// @param externalNullifier: External nullifier.
    /// @param signal: Semaphore signal.
    event ProofVerified(
        uint256 indexed groupId,
        uint256 indexed merkleTreeRoot,
        uint256 nullifierHash,
        uint256 indexed externalNullifier,
        uint256 signal
    );

    /// @dev Saves the nullifier hash to avoid double signaling and emits an event
    /// if the zero-knowledge proof is valid.
    /// @param groupId: Id of the group.
    /// @param merkleTreeRoot: Root of the Merkle tree.
    /// @param signal: Semaphore signal.
    /// @param nullifierHash: Nullifier hash.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    function verifyProof(
        uint256 groupId,
        uint256 merkleTreeRoot,
        uint256 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /// @dev Creates a new group. Only the admin will be able to add or remove members.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param admin: Admin of the group.
    function createGroup(uint256 groupId, uint256 depth, address admin) external;

    /// @dev Creates a new group. Only the admin will be able to add or remove members.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param admin: Admin of the group.
    /// @param merkleTreeRootDuration: Time before the validity of a root expires.
    function createGroup(uint256 groupId, uint256 depth, address admin, uint256 merkleTreeRootDuration) external;

    /// @dev Updates the group admin.
    /// @param groupId: Id of the group.
    /// @param newAdmin: New admin of the group.
    function updateGroupAdmin(uint256 groupId, address newAdmin) external;

    /// @dev Updates the group Merkle tree duration.
    /// @param groupId: Id of the group.
    /// @param newMerkleTreeDuration: New Merkle tree duration.
    function updateGroupMerkleTreeDuration(uint256 groupId, uint256 newMerkleTreeDuration) external;

    /// @dev Adds a new member to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: New identity commitment.
    function addMember(uint256 groupId, uint256 identityCommitment) external;

    /// @dev Adds new members to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitments: New identity commitments.
    function addMembers(uint256 groupId, uint256[] calldata identityCommitments) external;

    /// @dev Updates an identity commitment of an existing group. A proof of membership is
    /// needed to check if the node to be updated is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Existing identity commitment to be updated.
    /// @param newIdentityCommitment: New identity commitment.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function updateMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256 newIdentityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;

    /// @dev Removes a member from an existing group. A proof of membership is
    /// needed to check if the node to be removed is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Identity commitment to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../base/Pairing.sol";

/// @title SemaphoreVerifier contract interface.
interface ISemaphoreVerifier {
    struct VerificationKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    /// @dev Verifies whether a Semaphore proof is valid.
    /// @param merkleTreeRoot: Root of the Merkle tree.
    /// @param nullifierHash: Nullifier hash.
    /// @param signal: Semaphore signal.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    /// @param merkleTreeDepth: Depth of the tree.
    function verifyProof(
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256 signal,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        uint256 merkleTreeDepth
    ) external view;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/ISemaphoreGroups.sol";
import "@zk-kit/incremental-merkle-tree.sol/IncrementalBinaryTree.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/// @title Semaphore groups contract.
/// @dev This contract allows you to create groups, add, remove and update members.
/// You can use getters to obtain informations about groups (root, depth, number of leaves).
abstract contract SemaphoreGroups is Context, ISemaphoreGroups {
    using IncrementalBinaryTree for IncrementalTreeData;

    /// @dev Gets a group id and returns the tree data.
    mapping(uint256 => IncrementalTreeData) internal merkleTrees;

    /// @dev Creates a new group by initializing the associated tree.
    /// @param groupId: Id of the group.
    /// @param merkleTreeDepth: Depth of the tree.
    function _createGroup(uint256 groupId, uint256 merkleTreeDepth) internal virtual {
        if (getMerkleTreeDepth(groupId) != 0) {
            revert Semaphore__GroupAlreadyExists();
        }

        // The zeroValue is an implicit member of the group, or an implicit leaf of the Merkle tree.
        // Although there is a remote possibility that the preimage of
        // the hash may be calculated, using this value we aim to minimize the risk.
        uint256 zeroValue = uint256(keccak256(abi.encodePacked(groupId))) >> 8;

        merkleTrees[groupId].init(merkleTreeDepth, zeroValue);

        emit GroupCreated(groupId, merkleTreeDepth, zeroValue);
    }

    /// @dev Adds an identity commitment to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: New identity commitment.
    function _addMember(uint256 groupId, uint256 identityCommitment) internal virtual {
        if (getMerkleTreeDepth(groupId) == 0) {
            revert Semaphore__GroupDoesNotExist();
        }

        merkleTrees[groupId].insert(identityCommitment);

        uint256 merkleTreeRoot = getMerkleTreeRoot(groupId);
        uint256 index = getNumberOfMerkleTreeLeaves(groupId) - 1;

        emit MemberAdded(groupId, index, identityCommitment, merkleTreeRoot);
    }

    /// @dev Updates an identity commitment of an existing group. A proof of membership is
    /// needed to check if the node to be updated is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Existing identity commitment to be updated.
    /// @param newIdentityCommitment: New identity commitment.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function _updateMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256 newIdentityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal virtual {
        if (getMerkleTreeDepth(groupId) == 0) {
            revert Semaphore__GroupDoesNotExist();
        }

        merkleTrees[groupId].update(identityCommitment, newIdentityCommitment, proofSiblings, proofPathIndices);

        uint256 merkleTreeRoot = getMerkleTreeRoot(groupId);
        uint256 index = proofPathIndicesToMemberIndex(proofPathIndices);

        emit MemberUpdated(groupId, index, identityCommitment, newIdentityCommitment, merkleTreeRoot);
    }

    /// @dev Removes an identity commitment from an existing group. A proof of membership is
    /// needed to check if the node to be deleted is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Existing identity commitment to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function _removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal virtual {
        if (getMerkleTreeDepth(groupId) == 0) {
            revert Semaphore__GroupDoesNotExist();
        }

        merkleTrees[groupId].remove(identityCommitment, proofSiblings, proofPathIndices);

        uint256 merkleTreeRoot = getMerkleTreeRoot(groupId);
        uint256 index = proofPathIndicesToMemberIndex(proofPathIndices);

        emit MemberRemoved(groupId, index, identityCommitment, merkleTreeRoot);
    }

    /// @dev See {ISemaphoreGroups-getMerkleTreeRoot}.
    function getMerkleTreeRoot(uint256 groupId) public view virtual override returns (uint256) {
        return merkleTrees[groupId].root;
    }

    /// @dev See {ISemaphoreGroups-getMerkleTreeDepth}.
    function getMerkleTreeDepth(uint256 groupId) public view virtual override returns (uint256) {
        return merkleTrees[groupId].depth;
    }

    /// @dev See {ISemaphoreGroups-getNumberOfMerkleTreeLeaves}.
    function getNumberOfMerkleTreeLeaves(uint256 groupId) public view virtual override returns (uint256) {
        return merkleTrees[groupId].numberOfLeaves;
    }

    /// @dev Converts the path indices of a Merkle proof to the identity commitment index in the tree.
    /// @param proofPathIndices: Path of the proof of membership.
    /// @return Index of a group member.
    function proofPathIndicesToMemberIndex(uint8[] calldata proofPathIndices) private pure returns (uint256) {
        uint256 memberIndex = 0;

        for (uint8 i = uint8(proofPathIndices.length); i > 0; ) {
            if (memberIndex > 0 || proofPathIndices[i - 1] != 0) {
                memberIndex *= 2;

                if (proofPathIndices[i - 1] == 1) {
                    memberIndex += 1;
                }
            }

            unchecked {
                --i;
            }
        }

        return memberIndex;
    }
}

// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// The following Pairing library is a modified version adapted to Semaphore.
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Pairing {
    error InvalidProof();

    // The prime q in the base field F_q for G1
    uint256 constant BASE_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // The prime modulus of the scalar field of G1.
    uint256 constant SCALAR_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /// @return the generator of G1
    function P1() public pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    function P2() public pure returns (G2Point memory) {
        return
            G2Point(
                [
                    11559732032986387107991004021392285783925812861821192530917403151452391805634,
                    10857046999023057135944570762232829481370756359578518086990519993285655852781
                ],
                [
                    4082367875863433681332203403145435568316851327593401208105741076214120093531,
                    8495653923123431417604973247489272438418190587263600148770280649306958101930
                ]
            );
    }

    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) public pure returns (G1Point memory r) {
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }

        // Validate input or revert
        if (p.X >= BASE_MODULUS || p.Y >= BASE_MODULUS) {
            revert InvalidProof();
        }

        // We know p.Y > 0 and p.Y < BASE_MODULUS.
        return G1Point(p.X, BASE_MODULUS - p.Y);
    }

    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) public view returns (G1Point memory r) {
        // By EIP-196 all input is validated to be less than the BASE_MODULUS and form points
        // on the curve.
        uint256[4] memory input;

        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;

        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        }

        if (!success) {
            revert InvalidProof();
        }
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint256 s) public view returns (G1Point memory r) {
        // By EIP-196 the values p.X and p.Y are verified to be less than the BASE_MODULUS and
        // form a valid point on the curve. But the scalar is not verified, so we do that explicitly.
        if (s >= SCALAR_MODULUS) {
            revert InvalidProof();
        }

        uint256[3] memory input;

        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;

        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        }

        if (!success) {
            revert InvalidProof();
        }
    }

    /// Asserts the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should succeed
    function pairingCheck(G1Point[] memory p1, G2Point[] memory p2) public view {
        // By EIP-197 all input is verified to be less than the BASE_MODULUS and form elements in their
        // respective groups of the right order.
        if (p1.length != p2.length) {
            revert InvalidProof();
        }

        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }

        if (!success || out[0] != 1) {
            revert InvalidProof();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title SemaphoreGroups contract interface.
interface ISemaphoreGroups {
    error Semaphore__GroupDoesNotExist();
    error Semaphore__GroupAlreadyExists();

    /// @dev Emitted when a new group is created.
    /// @param groupId: Id of the group.
    /// @param merkleTreeDepth: Depth of the tree.
    /// @param zeroValue: Zero value of the tree.
    event GroupCreated(uint256 indexed groupId, uint256 merkleTreeDepth, uint256 zeroValue);

    /// @dev Emitted when a new identity commitment is added.
    /// @param groupId: Group id of the group.
    /// @param index: Identity commitment index.
    /// @param identityCommitment: New identity commitment.
    /// @param merkleTreeRoot: New root hash of the tree.
    event MemberAdded(uint256 indexed groupId, uint256 index, uint256 identityCommitment, uint256 merkleTreeRoot);

    /// @dev Emitted when an identity commitment is updated.
    /// @param groupId: Group id of the group.
    /// @param index: Identity commitment index.
    /// @param identityCommitment: Existing identity commitment to be updated.
    /// @param newIdentityCommitment: New identity commitment.
    /// @param merkleTreeRoot: New root hash of the tree.
    event MemberUpdated(
        uint256 indexed groupId,
        uint256 index,
        uint256 identityCommitment,
        uint256 newIdentityCommitment,
        uint256 merkleTreeRoot
    );

    /// @dev Emitted when a new identity commitment is removed.
    /// @param groupId: Group id of the group.
    /// @param index: Identity commitment index.
    /// @param identityCommitment: Existing identity commitment to be removed.
    /// @param merkleTreeRoot: New root hash of the tree.
    event MemberRemoved(uint256 indexed groupId, uint256 index, uint256 identityCommitment, uint256 merkleTreeRoot);

    /// @dev Returns the last root hash of a group.
    /// @param groupId: Id of the group.
    /// @return Root hash of the group.
    function getMerkleTreeRoot(uint256 groupId) external view returns (uint256);

    /// @dev Returns the depth of the tree of a group.
    /// @param groupId: Id of the group.
    /// @return Depth of the group tree.
    function getMerkleTreeDepth(uint256 groupId) external view returns (uint256);

    /// @dev Returns the number of tree leaves of a group.
    /// @param groupId: Id of the group.
    /// @return Number of tree leaves.
    function getNumberOfMerkleTreeLeaves(uint256 groupId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PoseidonT3} from "./Hashes.sol";

// Each incremental tree has certain properties and data that will
// be used to add new leaves.
struct IncrementalTreeData {
    uint256 depth; // Depth of the tree (levels - 1).
    uint256 root; // Root hash of the tree.
    uint256 numberOfLeaves; // Number of leaves of the tree.
    mapping(uint256 => uint256) zeroes; // Zero hashes used for empty nodes (level -> zero hash).
    // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node]).
    mapping(uint256 => uint256[2]) lastSubtrees; // Caching these values is essential to efficient appends.
}

/// @title Incremental binary Merkle tree.
/// @dev The incremental tree allows to calculate the root hash each time a leaf is added, ensuring
/// the integrity of the tree.
library IncrementalBinaryTree {
    uint8 internal constant MAX_DEPTH = 32;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// @dev Initializes a tree.
    /// @param self: Tree data.
    /// @param depth: Depth of the tree.
    /// @param zero: Zero value to be used.
    function init(
        IncrementalTreeData storage self,
        uint256 depth,
        uint256 zero
    ) public {
        require(zero < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

        self.depth = depth;

        for (uint8 i = 0; i < depth; ) {
            self.zeroes[i] = zero;
            zero = PoseidonT3.poseidon([zero, zero]);

            unchecked {
                ++i;
            }
        }

        self.root = zero;
    }

    /// @dev Inserts a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be inserted.
    function insert(IncrementalTreeData storage self, uint256 leaf) public {
        uint256 depth = self.depth;

        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(self.numberOfLeaves < 2**depth, "IncrementalBinaryTree: tree is full");

        uint256 index = self.numberOfLeaves;
        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            if (index & 1 == 0) {
                self.lastSubtrees[i] = [hash, self.zeroes[i]];
            } else {
                self.lastSubtrees[i][1] = hash;
            }

            hash = PoseidonT3.poseidon(self.lastSubtrees[i]);
            index >>= 1;

            unchecked {
                ++i;
            }
        }

        self.root = hash;
        self.numberOfLeaves += 1;
    }

    /// @dev Updates a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be updated.
    /// @param newLeaf: New leaf.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function update(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256 newLeaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        require(newLeaf != leaf, "IncrementalBinaryTree: new leaf cannot be the same as the old one");
        require(newLeaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: new leaf must be < SNARK_SCALAR_FIELD");
        require(
            verify(self, leaf, proofSiblings, proofPathIndices),
            "IncrementalBinaryTree: leaf is not part of the tree"
        );

        uint256 depth = self.depth;
        uint256 hash = newLeaf;
        uint256 updateIndex;

        for (uint8 i = 0; i < depth; ) {
            updateIndex |= uint256(proofPathIndices[i]) << uint256(i);

            if (proofPathIndices[i] == 0) {
                if (proofSiblings[i] == self.lastSubtrees[i][1]) {
                    self.lastSubtrees[i][0] = hash;
                }

                hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
            } else {
                if (proofSiblings[i] == self.lastSubtrees[i][0]) {
                    self.lastSubtrees[i][1] = hash;
                }

                hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }
        require(updateIndex < self.numberOfLeaves, "IncrementalBinaryTree: leaf index out of range");

        self.root = hash;
    }

    /// @dev Removes a leaf from the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function remove(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        update(self, leaf, self.zeroes[0], proofSiblings, proofPathIndices);
    }

    /// @dev Verify if the path is correct and the leaf is part of the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    /// @return True or false.
    function verify(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) private view returns (bool) {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        uint256 depth = self.depth;
        require(
            proofPathIndices.length == depth && proofSiblings.length == depth,
            "IncrementalBinaryTree: length of path is not correct"
        );

        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            require(
                proofSiblings[i] < SNARK_SCALAR_FIELD,
                "IncrementalBinaryTree: sibling node must be < SNARK_SCALAR_FIELD"
            );

            require(
                proofPathIndices[i] == 1 || proofPathIndices[i] == 0,
                "IncrementalBinaryTree: path index is neither 0 nor 1"
            );

            if (proofPathIndices[i] == 0) {
                hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
            } else {
                hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }

        return hash == self.root;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library PoseidonT3 {
    function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

library PoseidonT6 {
    function poseidon(uint256[5] memory) public pure returns (uint256) {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/ISemaphoreWhistleblowing.sol";
import "../interfaces/ISemaphoreVerifier.sol";
import "../base/SemaphoreGroups.sol";

/// @title Semaphore whistleblowing contract.
/// @notice It allows users to leak information anonymously .
/// @dev The following code allows you to create entities for whistleblowers (e.g. non-profit
/// organization, newspaper) and allow them to leak anonymously.
/// Leaks can be IPFS hashes, permanent links or other kinds of references.
contract SemaphoreWhistleblowing is ISemaphoreWhistleblowing, SemaphoreGroups {
    ISemaphoreVerifier public verifier;

    /// @dev Gets an entity id and return its editor address.
    mapping(uint256 => address) private entities;

    /// @dev Checks if the editor is the transaction sender.
    /// @param entityId: Id of the entity.
    modifier onlyEditor(uint256 entityId) {
        if (entities[entityId] != _msgSender()) {
            revert Semaphore__CallerIsNotTheEditor();
        }

        _;
    }

    /// @dev Initializes the Semaphore verifier used to verify the user's ZK proofs.
    /// @param _verifier: Semaphore verifier address.
    constructor(ISemaphoreVerifier _verifier) {
        verifier = _verifier;
    }

    /// @dev See {ISemaphoreWhistleblowing-createEntity}.
    function createEntity(uint256 entityId, address editor, uint256 merkleTreeDepth) public override {
        if (merkleTreeDepth < 16 || merkleTreeDepth > 32) {
            revert Semaphore__MerkleTreeDepthIsNotSupported();
        }

        _createGroup(entityId, merkleTreeDepth);

        entities[entityId] = editor;

        emit EntityCreated(entityId, editor);
    }

    /// @dev See {ISemaphoreWhistleblowing-addWhistleblower}.
    function addWhistleblower(uint256 entityId, uint256 identityCommitment) public override onlyEditor(entityId) {
        _addMember(entityId, identityCommitment);
    }

    /// @dev See {ISemaphoreWhistleblowing-removeWhistleblower}.
    function removeWhistleblower(
        uint256 entityId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public override onlyEditor(entityId) {
        _removeMember(entityId, identityCommitment, proofSiblings, proofPathIndices);
    }

    /// @dev See {ISemaphoreWhistleblowing-publishLeak}.
    function publishLeak(
        uint256 leak,
        uint256 nullifierHash,
        uint256 entityId,
        uint256[8] calldata proof
    ) public override {
        uint256 merkleTreeDepth = getMerkleTreeDepth(entityId);
        uint256 merkleTreeRoot = getMerkleTreeRoot(entityId);

        verifier.verifyProof(merkleTreeRoot, nullifierHash, leak, entityId, proof, merkleTreeDepth);

        emit LeakPublished(entityId, leak);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title SemaphoreWhistleblowing contract interface.
interface ISemaphoreWhistleblowing {
    error Semaphore__CallerIsNotTheEditor();
    error Semaphore__MerkleTreeDepthIsNotSupported();

    struct Verifier {
        address contractAddress;
        uint256 merkleTreeDepth;
    }

    /// @dev Emitted when a new entity is created.
    /// @param entityId: Id of the entity.
    /// @param editor: Editor of the entity.
    event EntityCreated(uint256 entityId, address indexed editor);

    /// @dev Emitted when a whistleblower publish a new leak.
    /// @param entityId: Id of the entity.
    /// @param leak: News leak.
    event LeakPublished(uint256 indexed entityId, uint256 leak);

    /// @dev Creates an entity and the associated Merkle tree/group.
    /// @param entityId: Id of the entity.
    /// @param editor: Editor of the entity.
    /// @param merkleTreeDepth: Depth of the tree.
    function createEntity(uint256 entityId, address editor, uint256 merkleTreeDepth) external;

    /// @dev Adds a whistleblower to an entity.
    /// @param entityId: Id of the entity.
    /// @param identityCommitment: Identity commitment of the group member.
    function addWhistleblower(uint256 entityId, uint256 identityCommitment) external;

    /// @dev Removes a whistleblower from an entity.
    /// @param entityId: Id of the entity.
    /// @param identityCommitment: Identity commitment of the group member.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function removeWhistleblower(
        uint256 entityId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;

    /// @dev Allows whistleblowers to publish leaks anonymously.
    /// @param leak: News leak.
    /// @param nullifierHash: Nullifier hash.
    /// @param entityId: Id of the entity.
    /// @param proof: Private zk-proof parameters.
    function publishLeak(uint256 leak, uint256 nullifierHash, uint256 entityId, uint256[8] calldata proof) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/ISemaphoreVoting.sol";
import "../interfaces/ISemaphoreVerifier.sol";
import "../base/SemaphoreGroups.sol";

/// @title Semaphore voting contract.
/// @notice It allows users to vote anonymously in a poll.
/// @dev The following code allows you to create polls, add voters and allow them to vote anonymously.
contract SemaphoreVoting is ISemaphoreVoting, SemaphoreGroups {
    ISemaphoreVerifier public verifier;

    /// @dev Gets a poll id and returns the poll data.
    mapping(uint256 => Poll) internal polls;

    /// @dev Checks if the poll coordinator is the transaction sender.
    /// @param pollId: Id of the poll.
    modifier onlyCoordinator(uint256 pollId) {
        if (polls[pollId].coordinator != _msgSender()) {
            revert Semaphore__CallerIsNotThePollCoordinator();
        }

        _;
    }

    /// @dev Initializes the Semaphore verifier used to verify the user's ZK proofs.
    /// @param _verifier: Semaphore verifier address.
    constructor(ISemaphoreVerifier _verifier) {
        verifier = _verifier;
    }

    /// @dev See {ISemaphoreVoting-createPoll}.
    function createPoll(uint256 pollId, address coordinator, uint256 merkleTreeDepth) public override {
        if (merkleTreeDepth < 16 || merkleTreeDepth > 32) {
            revert Semaphore__MerkleTreeDepthIsNotSupported();
        }

        _createGroup(pollId, merkleTreeDepth);

        polls[pollId].coordinator = coordinator;

        emit PollCreated(pollId, coordinator);
    }

    /// @dev See {ISemaphoreVoting-addVoter}.
    function addVoter(uint256 pollId, uint256 identityCommitment) public override onlyCoordinator(pollId) {
        if (polls[pollId].state != PollState.Created) {
            revert Semaphore__PollHasAlreadyBeenStarted();
        }

        _addMember(pollId, identityCommitment);
    }

    /// @dev See {ISemaphoreVoting-addVoter}.
    function startPoll(uint256 pollId, uint256 encryptionKey) public override onlyCoordinator(pollId) {
        if (polls[pollId].state != PollState.Created) {
            revert Semaphore__PollHasAlreadyBeenStarted();
        }

        polls[pollId].state = PollState.Ongoing;

        emit PollStarted(pollId, _msgSender(), encryptionKey);
    }

    /// @dev See {ISemaphoreVoting-castVote}.
    function castVote(uint256 vote, uint256 nullifierHash, uint256 pollId, uint256[8] calldata proof) public override {
        if (polls[pollId].state != PollState.Ongoing) {
            revert Semaphore__PollIsNotOngoing();
        }

        if (polls[pollId].nullifierHashes[nullifierHash]) {
            revert Semaphore__YouAreUsingTheSameNillifierTwice();
        }

        uint256 merkleTreeDepth = getMerkleTreeDepth(pollId);
        uint256 merkleTreeRoot = getMerkleTreeRoot(pollId);

        verifier.verifyProof(merkleTreeRoot, nullifierHash, vote, pollId, proof, merkleTreeDepth);

        polls[pollId].nullifierHashes[nullifierHash] = true;

        emit VoteAdded(pollId, vote);
    }

    /// @dev See {ISemaphoreVoting-publishDecryptionKey}.
    function endPoll(uint256 pollId, uint256 decryptionKey) public override onlyCoordinator(pollId) {
        if (polls[pollId].state != PollState.Ongoing) {
            revert Semaphore__PollIsNotOngoing();
        }

        polls[pollId].state = PollState.Ended;

        emit PollEnded(pollId, _msgSender(), decryptionKey);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title SemaphoreVoting contract interface.
interface ISemaphoreVoting {
    error Semaphore__CallerIsNotThePollCoordinator();
    error Semaphore__MerkleTreeDepthIsNotSupported();
    error Semaphore__PollHasAlreadyBeenStarted();
    error Semaphore__PollIsNotOngoing();
    error Semaphore__YouAreUsingTheSameNillifierTwice();

    enum PollState {
        Created,
        Ongoing,
        Ended
    }

    struct Verifier {
        address contractAddress;
        uint256 merkleTreeDepth;
    }

    struct Poll {
        address coordinator;
        PollState state;
        mapping(uint256 => bool) nullifierHashes;
    }

    /// @dev Emitted when a new poll is created.
    /// @param pollId: Id of the poll.
    /// @param coordinator: Coordinator of the poll.
    event PollCreated(uint256 pollId, address indexed coordinator);

    /// @dev Emitted when a poll is started.
    /// @param pollId: Id of the poll.
    /// @param coordinator: Coordinator of the poll.
    /// @param encryptionKey: Key to encrypt the poll votes.
    event PollStarted(uint256 pollId, address indexed coordinator, uint256 encryptionKey);

    /// @dev Emitted when a user votes on a poll.
    /// @param pollId: Id of the poll.
    /// @param vote: User encrypted vote.
    event VoteAdded(uint256 indexed pollId, uint256 vote);

    /// @dev Emitted when a poll is ended.
    /// @param pollId: Id of the poll.
    /// @param coordinator: Coordinator of the poll.
    /// @param decryptionKey: Key to decrypt the poll votes.
    event PollEnded(uint256 pollId, address indexed coordinator, uint256 decryptionKey);

    /// @dev Creates a poll and the associated Merkle tree/group.
    /// @param pollId: Id of the poll.
    /// @param coordinator: Coordinator of the poll.
    /// @param merkleTreeDepth: Depth of the tree.
    function createPoll(uint256 pollId, address coordinator, uint256 merkleTreeDepth) external;

    /// @dev Adds a voter to a poll.
    /// @param pollId: Id of the poll.
    /// @param identityCommitment: Identity commitment of the group member.
    function addVoter(uint256 pollId, uint256 identityCommitment) external;

    /// @dev Starts a pull and publishes the key to encrypt the votes.
    /// @param pollId: Id of the poll.
    /// @param encryptionKey: Key to encrypt poll votes.
    function startPoll(uint256 pollId, uint256 encryptionKey) external;

    /// @dev Casts an anonymous vote in a poll.
    /// @param vote: Encrypted vote.
    /// @param nullifierHash: Nullifier hash.
    /// @param pollId: Id of the poll.
    /// @param proof: Private zk-proof parameters.
    function castVote(uint256 vote, uint256 nullifierHash, uint256 pollId, uint256[8] calldata proof) external;

    /// @dev Ends a pull and publishes the key to decrypt the votes.
    /// @param pollId: Id of the poll.
    /// @param decryptionKey: Key to decrypt poll votes.
    function endPoll(uint256 pollId, uint256 decryptionKey) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/ISemaphoreVerifier.sol";

/// @title Semaphore verifier contract.
/// @notice Minimal code to allow users to verify their Semaphore proofs.
/// @dev This contract allows you to verify whether a Semaphore proof is correct.
/// It is a modified version of the Groth16 verifier template of SnarkJS
/// (https://github.com/iden3/snarkjs) adapted to Semaphore. The Pairing library
/// is external.
contract SemaphoreVerifier is ISemaphoreVerifier {
    using Pairing for *;

    // prettier-ignore
    // solhint-disable-next-line
    uint256[2][7][17]  VK_POINTS = [[[13406811599156507528361773763681356312643537981039994686313383243831956396116,16243966861079634958125511652590761846958471358623040426599000904006426210032],[11781596534582143578120404722739278517564025497573071755253972265891888117374,15688083679237922164673518758181461582601853873216319711156397437601833996222],[1964404930528116823793003656764176108669615750422202377358993070935069307720,2137714996673694828207437580381836490878070731768805974506391024595988817424],[19568893707760843340848992184233194433177372925415116053368211122719346671126,11639469568629189918046964192305250472192697612201524135560178632824282818614],[5317268879687484957437879782519918549127939892210247573193613900261494313825,528174394975085006443543773707702838726735933116136102590448357278717993744],[14865918005176722116473730206622066845866539143554731094374354951675249722731,3197770568483953664363740385883457803041685902965668289308665954510373380344],[6863358721495494421022713667808247652425178970453300712435830652679038918987,15025816433373311798308762709072064417001390853103872064614174594927359131281]],[[15629200772768268814959330350023920183087521275477047626405113853190187031523,13589689305661231568162336263197960570915890299814486885851912452076929115480],[11464919285924930973853174493551975632739604254498590354200272115844983493029,16004221700357242255845535848024178544616388017965468694776181247983831995562],[17789438292552571310739605737896030466581277887660997531707911256058650850910,4112657509505371631825493224748310061184972897405589115208158208294581472016],[3322052920119834475842380240689494113984887785733316517680891208549118967155,381029395779795399840019487059126246243641886087320875571067736504031557148],[8777645223617381095463415690983421308854368583891690388850387317049320450400,11923582117369144413749726090967341613266070909169947059497952692052020331958],[15493263571528401950994933073246603557158047091963487223668240334879173885581,6315532173951617115856055775098532808695228294437279844344466163873167020700],[3481637421055377106140197938175958155334313900824697193932986771017625492245,20088416136090515091300914661950097694450984520235647990572441134215240947932]],[[9218320951536642499143228327011901814587826948504871816273184688188019956292,19717684456458906358368865507225121991585492363133107109865920739019288468011],[16717590750910963405756115910371408378114896008824240863060392362901176601412,18221695645112467945186983098720611586049108689347006136423489099202471884089],[4691595252082380256698158158199364410440273386659834000993210659508747323919,9205801980459323513061837717352821162780471027241700646145937351740096374660],[16150531426263112884093068164597994126623437929929609532055221646496813246000,20245743178241899668170758952526381872637304119026868520579207157118516761827],[6063536446992770713985314309889717594240410784717230886576072989709763902848,18258781411255795973918859665416013869184055573057512603788635470145328981347],[10109932964756104512054045207253535333686585863745296080906925765480296575285,4174640428253153601540284363759502713687021920150940723252842152556151210349],[18049428534741480832385046397049175120355008065781483226058177421025493210952,591730261265040164434889324846001338201068482543108348317417391345612814922]],[[3995128789564535587814512245259203300137618476815456454931286633947953135662,15953239752392927777442331623182226063776310198012173504208557434319753428770],[20957319343912866335583737646657534123362052690050674068142580221965936605075,2523786679709693946058523307330825034772478122295850507521258983130425334580],[9877211178693075145402462781884120278654771727348087433632224794894486095150,19972682062587174829535281061580296764150591339640180868104711395548066529340],[6324578424031095537345184040149690238371517387586958921377481904541316423724,15513931720576048544404512239839508014664224085062729779520992909505663748296],[11371337652479737143800707796204655130812036287859296372695832558127430723628,11757275188600040111649009832378343123994225623498773406233261322165903848967],[13282496583564708104981015168203451877588903263486398132954741568835583461335,1746144324840370907926720490289700342734912534857331743685374514401176014195],[7993952462467372951144011615584426050192046712674662254138390197508963352374,5156942148925224345709309361345680948125600198010285179548841917923439945819]],[[18976133691706015337908381757202123182841901611067930614519324084182946094218,1382518990777992893805140303684642328066746531257780279226677247567004248173],[6627710380771660558660627878547223719795356903257079198333641681330388499309,21806956747910197517744499423107239699428979652113081469385876768212706694581],[19918517214839406678907482305035208173510172567546071380302965459737278553528,7151186077716310064777520690144511885696297127165278362082219441732663131220],[690581125971423619528508316402701520070153774868732534279095503611995849608,21271996888576045810415843612869789314680408477068973024786458305950370465558],[16461282535702132833442937829027913110152135149151199860671943445720775371319,2814052162479976678403678512565563275428791320557060777323643795017729081887],[4319780315499060392574138782191013129592543766464046592208884866569377437627,13920930439395002698339449999482247728129484070642079851312682993555105218086],[3554830803181375418665292545416227334138838284686406179598687755626325482686,5951609174746846070367113593675211691311013364421437923470787371738135276998]],[[3811592683283527904145155808200366192489850711742363953668998371801696238057,9032545080831535702239063467087720597970266046938395860207839433937324718536],[16308433125974933290258540904373317426123214107276055539769464205982500660715,12429982191499850873612518410809641163252887523090441166572590809691267943605],[9494885690931955877467315318223108618392113101843890678090902614660136056680,11783514256715757384821021009301806722951917744219075907912683963173706887379],[7562082660623781416745328104576133910743071878837764423695105915778139873834,17954307004260053757579194018551114133664721761483240877658498973152950708099],[19338184851116432029108109461622579541195083625346674255186169347975445785058,38361206266360048012365562393026952048730052530888439195454086987795985927],[21178537742782571863590222710872928190886000600239072595684369348717288330049,9786438258541172244884631831247223050494423968411444302812755467521949734320],[11330504221972341797183339350494223413034293674225690456356444509688810101433,1490009915387901405464437253469086864085891770312035292355706249426866485365]],[[9485639152672984144988597737758037391807993615552051606205480347442429414340,17626503110323089701269363177710295379967225765713250625279671011873619640598],[12391874700409435648975069978280047983726144854114915177376036190441913967689,18953587685067712486092665232725058638563458484886448540567142557894080640927],[21791720972262589799021600767292883644106575897307484548888696814333235336885,11092962469758788187888592619035811117815082357439060720677582048880121542623],[9418924955930663972575130074928583215922927562059194231976193350658171304436,16113558481826020406162261319744796072664750077095575593106901121115073101408],[20054934960262983176880675919444457578562219675808407582143519621873973120773,14877415271301547911435683263206245199959943680225555496786470669330176961657],[4215199263810110748751715719957184804379752373072771007598572158043965517488,5225943468606602818132879686778547605180105897615251160509064537462109826521],[6250242626034734280813142093008675407723196706248829741247204621913994561803,1472231555266678689888727724824566171966416459791722465278225775922487343641]],[[9830856103389248449121962275587399130605902703453384856543071762984116567573,11408965575174993375815840422438995549652812400401163392501956884932167624437],[11814906841949499037550820576929552248172160643991870665022770052632331265834,19969543376625663966419118899515353499678204573709836615846115182224340858492],[3047486363455933831148688762823238723024952519326207356549121929667745957778,20241836359289449005887237560564358543646542598344362915541027571505243817211],[5965631918800530319167124148627450454569264331058008407732200168631989208657,20463557477532480934514091877628554948892025887087712764683631108388998871350],[16605042322692983282732511249912403956057999815658038166796858627082222971215,12219061498275616585164456833410962809536084885494309093787669879221959361956],[1548998572074037722622224303222294716243074837074272552644853986075252666508,10393312002885367652301897874262367916506364670364584602554176742602334134772],[16180907689593358346406392015123900260925622357393826746385511046141256905390,12267326749885120640972074479210537480053065569337817484467225562817467244765]],[[15035335306919942325459417688135340085377315274625768597233474641923619728582,10090041889587324002759549286390619541526396451963494627957072069124011137562],[21342049717074059749518233491526445388158772701642182532370641230478027030319,10507786999799841055999967456762679569286329319056926475375760604262707147294],[19590996174696909242575628014943555633938195923520472786993379268302478708283,2673753072556442230312995111304911178679525806396134504594492458566941824354],[13411253172375451489380472831999887223592471057462692619008484995624281735092,17181767455563581254432161119660408482332423481128600038352147258951772423229],[19138864631164378176055647711995352935065134904103255748190268290992108588628,14282526277736365863821375748687709839392307698935143595732632710176778519757],[20183773658676161990469276414858234178608794783112866811307579993999118293429,5223464433544489066271184294750886227362580875255044558831927430970236355539],[12333466991139269670298178539679773509487545471126920233507132846828588847444,3787586478923104354547687861486563468235879611952775292288436085429794222238]],[[15718373132479769904443326381037437528372212185108294117696143473979328398658,43456740675249348549891878341522275183186932745162972528932808393415299552],[11236864934894600819960883124570686936554376109344998527334431594565774237827,4289247401578837038775845192875793775418122783738936298355403103074020081838],[18580370382199518848261939652153768394883698461842792002922164533882262019935,20516185953882700254387267244708111605796661864845495645678049276372075842359],[20041291712709610738573661974551517833120775539593003477018637287434210072702,6326630253906616820412999166182553773360987412889775567442543181359104720511],[13268971611130152315428629919012388924225656285593904211561391821918930327614,9247437189452353488017802041158840512956111558640958728149597697508914590433],[6267384495557139339708615182113725421733376438932580472141549274050146739549,1832264154031452148715318442722960696977572389206897240030908464579133134237],[16650684165487873559901140599157559153018449083939294496255590830891994564285,14140282729498011406186082176268025578697081678243955538935501306868500498994]],[[1723458149089715907994189658689343304709709060535625667210252753337752162173,4023016874169005249382064394379671330447496454371261692205411970999350949293],[7651670126664625790835334090273463062538865895183205964669372719235003083565,17710652158212212080502343565075513548898593397103675832636832371532093744857],[4247947150009812467217672970806328247513830308400387953244764907353849211641,14500381439127180474801393438175928191199696177607750163263715436006533630877],[21213779524495874664157797605662894019112036728653622806607467354233012380232,1429370857470083395421401524518861545167550347090873730934256398864585069083],[12465277751642747637430517396067173985821959773399832969105187923427872239200,4377704428607835904642653580543541241155601291484645500691968624389522190030],[11283027832501128633761619552392013253304972822086786857121687098087331014745,21463394238922953607096052056881931791797740737164052798044623278557203313720],[19687293493101130967741578773742597470558958652351513582962108464055656171331,4445165696525061401582979300506082669540223774145877762689724631935313716632]],[[745924679191739894055143748466112994378439645681039136007774787076115375124,13132169670125192016391258838554965176628317453468870968867717287446623320643],[2126777833939378028304266129616145667925849332481755567268747182629795296580,20909608709868730010029182074820840312550443752829480953667886902663547957991],[3388767735894417381503201756905214431625081913405504580464345986403824999889,21014112837214011009096825602791072748195337199912773858499588477762724153070],[10521317016331497094903116740581271122844131442882845700567581775404872949272,13201921794561774338466680421903602920184688290946713194187958007088351657367],[16170260722059932609965743383032703380650557609693540121262881902248073364496,6004983491336500911294872035126141746032033211872472427212274143945425740617],[10275615677574391293596971122111363003313434841806630200532546038183081960924,5955568702561336410725734958627459212680756023420452791680213386065159525989],[19059081014385850734732058652137664919364805650872154944590269874395511868415,19202365837673729366500417038229950532560250566916189579621883380623278182155]],[[4553625243522856553165922942982108474187282402890756796515747778282922584601,16835654219229187428071649241190746119082269636345872682107941472241044260584],[3272293478534046729728233267765357195255129499603632413158978822084188871854,873742823867191038535544062852920538566418819521732785500614249239215175476],[7856986171681248404396064225772749784181602218562773063185003409958949630985,11707218736744382138692483591389641607570557654489363179025201039696228471230],[2902255937308264958973169948617099471543255757887963647238093192858290079050,4092153880227661899721872164083575597602963673456107552146583620177664115673],[18380478859138320895837407377103009470968863533040661874531861881638854174636,14502773952184441371657781525836310753176308880224816843041318743809785835984],[2781117248053224106149213822307598926495461873135153638774638501111353469325,3500056595279027698683405880585654897391289317486204483344715855049598477604],[8880120765926282932795149634761705738498809569874317407549203808931092257005,19080036326648068547894941015038877788526324720587349784852594495705578761000]],[[7252337675475138150830402909353772156046809729627064992143762325769537840623,7601443214415704135008588588192028557655441716696726549510699770097979655628],[436607343827794507835462908831699962173244647704538949914686722631806931932,18500126298578278987997086114400065402270866280547473913420536595663876273004],[18427701611614193839908361166447988195308352665132182219164437649866377475111,5299493942596042045861137432338955179078182570752746487573709678936617478454],[4188155714164125069834512529839479682516489319499446390214266838952761728656,2720966082507704094346897998659841489771837229143573083003847010258396944787],[13256461570028177373135283778770729308216900804505379897951455548375840027026,10722074030307391322177899534114921764931623271723882054692012663305322382747],[9824147497244652955949696442395586567974424828238608972020527958186701134273,15755269950882650791869946186461432242513999576056199368058858215068920022191],[21172488506061181949536573476893375313339715931330476837156243346077173297265,13892434487977776248366965108031841947713544939953824768291380177301871559945]],[[10202326166286888893675634318107715186834588694714750762952081034135561546271,15028154694713144242204861571552635520290993855826554325002991692907421516918],[18486039841380105976272577521609866666900576498507352937328726490052296469859,12766289885372833812620582632847872978085960777075662988932200910695848591357],[1452272927738590248356371174422184656932731110936062990115610832462181634644,3608050114233210789542189629343107890943266759827387991788718454179833288695],[14798240452388909327945424685903532333765637883272751382037716636327236955001,10773894897711848209682368488916121016695006898681985691467605219098835500201],[17204267933132009093604099819536245144503489322639121825381131096467570698650,7704298975420304156332734115679983371345754866278811368869074990486717531131],[8060465662017324080560848316478407038163145149983639907596180500095598669247,20475082166427284188002500222093571716651248980245637602667562336751029856573],[7457566682692308112726332096733260585025339741083447785327706250123165087868,11904519443874922292602150685069370036383697877657723976244907400392778002614]],[[14930624777162656776068112402283260602512252179767747308433194885322661150422,13682963731073238132274278610660469286329368216526659590944079211949686450402],[18705481657148807016785305378773304476425591636333098330324049960258682574070,21315724107376627085778492378001676935454590984229146391746301404292016287653],[12628427235010608529869146871556870477182704310235373946877240509680742038961,15093298104438768585559335868663959710321348106117735180051519837845319121254],[6593907467779318957599440584793099005109789224774644007604434924706249001015,18549596630007199540674697114946251030815675677713256327810772799104711621483],[6271101737045248834759003849256661059806617144229427987717476992610974162336,355748132218964841305454070022507122319085542484477110563322753565651576458],[2116139772133141967317791473319540620104888687412078412336248003979594158546,4004400204967325849492155713520296687406035356901102254880522534085890616486],[4206647028595764233995379982714022410660284578620723510907006350595207905228,19380634286337609988098517090003334645113675227742745065381519159322795845003]],[[12315240965742683516581565369496371929586281338862761742109651525191835544242,18994803742708336446369128568423705404354655742604689352630273180469431952708],[18019403342409608922812569436317484250134945386869657285229378095251425778096,12707009780301102830224094192984906206920666691015255692741008594808694787917],[2592407181901686208061988776764501828311271519595797153264758207470081204331,11847594161160074962679125411562687287595382335410213641115001866587988494499],[3346927026869562921166545684451290646273836362895645367665514203662899621366,15758185693543979820528128025093553492246135914029575732836221618882836493143],[20528686657810499188368147206002308531447185877994439397529705707372170337045,18025396678079701612906003769476076600196287001844168390936182972248852818155],[9799815250059685769827017947834627563597884023490186073806184882963949644596,4998495094322372762314630336611134866447406022687118703953312157819349892603],[16176535527670849161173306151058200762642157343823553073439957507563856439772,21877331533292960470552563236986670222564955589137303622102707801351340670855]]];

    /// @dev See {ISemaphoreVerifier-verifyProof}.
    function verifyProof(
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256 signal,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        uint256 merkleTreeDepth
    ) external view override {
        signal = _hash(signal);
        externalNullifier = _hash(externalNullifier);

        Proof memory p;

        p.A = Pairing.G1Point(proof[0], proof[1]);
        p.B = Pairing.G2Point([proof[2], proof[3]], [proof[4], proof[5]]);
        p.C = Pairing.G1Point(proof[6], proof[7]);

        VerificationKey memory vk = _getVerificationKey(merkleTreeDepth - 16);

        Pairing.G1Point memory vk_x = vk.IC[0];

        vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[1], merkleTreeRoot));
        vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[2], nullifierHash));
        vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[3], signal));
        vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[4], externalNullifier));

        Pairing.G1Point[] memory p1 = new Pairing.G1Point[](4);
        Pairing.G2Point[] memory p2 = new Pairing.G2Point[](4);

        p1[0] = Pairing.negate(p.A);
        p2[0] = p.B;
        p1[1] = vk.alfa1;
        p2[1] = vk.beta2;
        p1[2] = vk_x;
        p2[2] = vk.gamma2;
        p1[3] = p.C;
        p2[3] = vk.delta2;

        Pairing.pairingCheck(p1, p2);
    }

    /// @dev Creates the verification key for a specific Merkle tree depth.
    /// @param vkPointsIndex: Index of the verification key points.
    /// @return Verification key.
    function _getVerificationKey(uint256 vkPointsIndex) private view returns (VerificationKey memory) {
        VerificationKey memory vk;

        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );

        vk.gamma2 = Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );

        vk.delta2 = Pairing.G2Point(VK_POINTS[vkPointsIndex][0], VK_POINTS[vkPointsIndex][1]);

        vk.IC = new Pairing.G1Point[](5);

        vk.IC[0] = Pairing.G1Point(VK_POINTS[vkPointsIndex][2][0], VK_POINTS[vkPointsIndex][2][1]);
        vk.IC[1] = Pairing.G1Point(VK_POINTS[vkPointsIndex][3][0], VK_POINTS[vkPointsIndex][3][1]);
        vk.IC[2] = Pairing.G1Point(VK_POINTS[vkPointsIndex][4][0], VK_POINTS[vkPointsIndex][4][1]);
        vk.IC[3] = Pairing.G1Point(VK_POINTS[vkPointsIndex][5][0], VK_POINTS[vkPointsIndex][5][1]);
        vk.IC[4] = Pairing.G1Point(VK_POINTS[vkPointsIndex][6][0], VK_POINTS[vkPointsIndex][6][1]);

        return vk;
    }

    /// @dev Creates a keccak256 hash of a message compatible with the SNARK scalar modulus.
    /// @param message: Message to be hashed.
    /// @return Message digest.
    function _hash(uint256 message) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(message))) >> 8;
    }
}