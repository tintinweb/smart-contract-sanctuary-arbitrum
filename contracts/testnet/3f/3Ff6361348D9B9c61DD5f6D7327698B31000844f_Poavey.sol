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
pragma solidity ^0.8.4;

import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";

contract Poavey {
    ISemaphore public semaphore;
    mapping(uint256 => Event) public events;

    struct Event {
        uint256 id; 
        uint256 groupId;
        uint256 eventId;

        mapping(address => bool) attendees;
        mapping(uint256 => bool) nullifierHashes;
        // TODO: should be stored offchain.
        uint256[] commitments;
    }

    event EventRegistered(uint256 indexed id, uint256 indexed eventId, uint256 indexed groupId);
    event EventAttended(uint256 indexed id, address indexed attendee, uint256 indexed groupId);
    event SurveyAnswered(uint256 indexed id, uint256 indexed answers, uint256 indexed groupId);

    constructor(address semaphoreAddress) {
        semaphore = ISemaphore(semaphoreAddress);
    }

    function registerEvent(uint256 eventId, uint256 groupId) external {
        uint256 id = uint256(
            keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1)))
        );

        Event storage anEvent = events[id];
        if (anEvent.id != 0)
            revert("Poavey: event already exists");
        anEvent.id = id;
        anEvent.eventId = eventId;
        anEvent.groupId = groupId;

        emit EventRegistered(id, eventId, groupId);
    }

    function attendEvent(uint256 id, uint256 identityCommitment) external {
        Event storage anEvent = events[id];
        if (anEvent.id == 0)
            revert("Poavey: event does not exist");
        if (anEvent.attendees[msg.sender])
            revert("Poavey: already attended");

        anEvent.attendees[msg.sender] = true;
        anEvent.commitments.push(identityCommitment);
        semaphore.addMember(anEvent.groupId, identityCommitment);

        emit EventAttended(id, msg.sender, anEvent.groupId);
    }

    function answerSurvey(
        uint256 id,
        uint256 answers,
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        Event storage anEvent = events[id];
        if (anEvent.id == 0)
            revert("Poavey: event does not exist");
        if (anEvent.nullifierHashes[nullifierHash])
            revert("Poavey: already answered");

        semaphore.verifyProof(anEvent.groupId, merkleTreeRoot, answers, nullifierHash, anEvent.groupId, proof);

        emit SurveyAnswered(id, answers, anEvent.groupId);
    }
}