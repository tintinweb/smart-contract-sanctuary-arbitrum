// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Codec.sol";
import "../interfaces/StateMachine.sol";
import "../interfaces/IConsensusClient.sol";

import "solidity-merkle-trees/MerkleMultiProof.sol";
import "solidity-merkle-trees/MerkleMountainRange.sol";
import "solidity-merkle-trees/MerklePatricia.sol";
import "solidity-merkle-trees/trie/substrate/ScaleCodec.sol";
import "solidity-merkle-trees/trie/Bytes.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";

struct BeefyConsensusState {
    /// block number for the latest mmr_root_hash
    uint256 latestHeight;
    /// Block number that the beefy protocol was activated on the relay chain.
    /// This should be the first block in the merkle-mountain-range tree.
    uint256 beefyActivationBlock;
    /// authorities for the current round
    AuthoritySetCommitment currentAuthoritySet;
    /// authorities for the next round
    AuthoritySetCommitment nextAuthoritySet;
}

struct AuthoritySetCommitment {
    /// Id of the set.
    uint256 id;
    /// Number of validators in the set.
    uint256 len;
    /// Merkle Root Hash built from BEEFY AuthorityIds.
    bytes32 root;
}

struct Payload {
    bytes2 id;
    bytes data;
}

struct Commitment {
    Payload[] payload;
    uint256 blockNumber;
    uint256 validatorSetId;
}

struct Vote {
    bytes signature;
    uint256 authorityIndex;
}

struct SignedCommitment {
    Commitment commitment;
    Vote[] votes;
}

struct BeefyMmrLeaf {
    uint256 version;
    uint256 parentNumber;
    bytes32 parentHash;
    AuthoritySetCommitment nextAuthoritySet;
    bytes32 extra;
    uint256 kIndex;
    uint256 leafIndex;
}

struct PartialBeefyMmrLeaf {
    uint256 version;
    uint256 parentNumber;
    bytes32 parentHash;
    AuthoritySetCommitment nextAuthoritySet;
}

struct RelayChainProof {
    /// Signed commitment
    SignedCommitment signedCommitment;
    /// Latest leaf added to mmr
    BeefyMmrLeaf latestMmrLeaf;
    /// Proof for the latest mmr leaf
    bytes32[] mmrProof;
    /// Proof for authorities in current/next session
    Node[][] proof;
}

struct Parachain {
    /// k-index for latestHeadsRoot
    uint256 index;
    /// Parachain Id
    uint256 id;
    /// SCALE encoded header
    bytes header;
}

struct ParachainProof {
    Parachain parachain;
    Node[][] proof;
}

struct BeefyConsensusProof {
    RelayChainProof relay;
    ParachainProof parachain;
}

struct ConsensusMessage {
    BeefyConsensusProof proof;
}

contract BeefyV1 is IConsensusClient {
    /// Slot duration in milliseconds
    uint256 public constant SLOT_DURATION = 12000;
    /// The PayloadId for the mmr root.
    bytes2 public constant MMR_ROOT_PAYLOAD_ID = bytes2("mh");
    /// ChainId for ethereum
    bytes4 public constant ISMP_CONSENSUS_ID = bytes4("ISMP");
    /// ConsensusID for aura
    bytes4 public constant AURA_CONSENSUS_ID = bytes4("aura");

    uint256 private _paraId;

    constructor(uint256 paraId) {
        _paraId = paraId;
    }

    function verifyConsensus(bytes memory encodedState, bytes memory encodedProof)
        external
        returns (bytes memory, IntermediateState memory)
    {
        BeefyConsensusState memory consensusState = abi.decode(encodedState, (BeefyConsensusState));
        (RelayChainProof memory relay, ParachainProof memory parachain) =
            abi.decode(encodedProof, (RelayChainProof, ParachainProof));

        (BeefyConsensusState memory newState, IntermediateState memory intermediate) =
            this.verifyConsensus(consensusState, BeefyConsensusProof(relay, parachain));

        return (abi.encode(newState), intermediate);
    }

    /// Verify the consensus proof and return the new trusted consensus state and any intermediate states finalized
    /// by this consensus proof.
    function verifyConsensus(BeefyConsensusState memory trustedState, BeefyConsensusProof memory proof)
        external
        view
        returns (BeefyConsensusState memory, IntermediateState memory)
    {
        // verify mmr root proofs
        (BeefyConsensusState memory state, bytes32 headsRoot) = verifyMmrUpdateProof(trustedState, proof.relay);

        // verify intermediate state commitment proofs
        IntermediateState memory intermediate = verifyParachainHeaderProof(headsRoot, proof.parachain);

        return (state, intermediate);
    }

    /// Verifies a new Mmmr root update, the relay chain accumulates its blocks into a merkle mountain range tree
    /// which light clients can use as a source for log_2(n) ancestry proofs. This new mmr root hash is signed by
    /// the relay chain authority set and we can verify the membership of the authorities who signed this new root
    /// using a merkle multi proof and a merkle commitment to the total authorities.
    function verifyMmrUpdateProof(BeefyConsensusState memory trustedState, RelayChainProof memory relayProof)
        private
        pure
        returns (BeefyConsensusState memory, bytes32)
    {
        uint256 signatures_length = relayProof.signedCommitment.votes.length;
        uint256 latestHeight = relayProof.signedCommitment.commitment.blockNumber;

        require(latestHeight > trustedState.latestHeight, "consensus clients only accept proofs for new headers");
        require(
            checkParticipationThreshold(signatures_length, trustedState.currentAuthoritySet.len)
                || checkParticipationThreshold(signatures_length, trustedState.nextAuthoritySet.len),
            "Super majority threshold not reached"
        );

        Commitment memory commitment = relayProof.signedCommitment.commitment;

        require(
            commitment.validatorSetId == trustedState.currentAuthoritySet.id
                || commitment.validatorSetId == trustedState.nextAuthoritySet.id,
            "Unknown authority set"
        );

        bool is_current_authorities = commitment.validatorSetId == trustedState.currentAuthoritySet.id;

        uint256 payload_len = commitment.payload.length;
        bytes32 mmrRoot;

        for (uint256 i = 0; i < payload_len; i++) {
            if (commitment.payload[i].id == MMR_ROOT_PAYLOAD_ID && commitment.payload[i].data.length == 32) {
                mmrRoot = Bytes.toBytes32(commitment.payload[i].data);
            }
        }

        require(mmrRoot != bytes32(0), "Mmr root hash not found");

        bytes32 commitment_hash = keccak256(Codec.Encode(commitment));
        Node[] memory authorities = new Node[](signatures_length);

        // verify authorities' votes
        for (uint256 i = 0; i < signatures_length; i++) {
            Vote memory vote = relayProof.signedCommitment.votes[i];
            address authority = ECDSA.recover(commitment_hash, vote.signature);
            authorities[i] = Node(vote.authorityIndex, keccak256(abi.encodePacked(authority)));
        }

        // check authorities proof
        if (is_current_authorities) {
            require(
                MerkleMultiProof.VerifyProof(trustedState.currentAuthoritySet.root, relayProof.proof, authorities),
                "Invalid current authorities proof"
            );
        } else {
            require(
                MerkleMultiProof.VerifyProof(trustedState.nextAuthoritySet.root, relayProof.proof, authorities),
                "Invalid next authorities proof"
            );
        }

        verifyMmrLeaf(trustedState, relayProof, mmrRoot);

        if (!is_current_authorities || trustedState.nextAuthoritySet.id != relayProof.latestMmrLeaf.nextAuthoritySet.id)
        {
            trustedState.currentAuthoritySet = trustedState.nextAuthoritySet;
            trustedState.nextAuthoritySet = relayProof.latestMmrLeaf.nextAuthoritySet;
        }

        trustedState.latestHeight = latestHeight;

        return (trustedState, relayProof.latestMmrLeaf.extra);
    }

    /// Stack too deep, sigh solidity
    function verifyMmrLeaf(BeefyConsensusState memory trustedState, RelayChainProof memory relay, bytes32 mmrRoot)
        private
        pure
    {
        bytes32 hash = keccak256(Codec.Encode(relay.latestMmrLeaf));
        uint256 leafCount = leafIndex(trustedState.beefyActivationBlock, relay.latestMmrLeaf.parentNumber) + 1;

        MmrLeaf[] memory leaves = new MmrLeaf[](1);
        leaves[0] = MmrLeaf(relay.latestMmrLeaf.kIndex, relay.latestMmrLeaf.leafIndex, hash);

        require(MerkleMountainRange.VerifyProof(mmrRoot, relay.mmrProof, leaves, leafCount), "Invalid Mmr Proof");
    }

    /// Verifies that some parachain header has been finalized, given the current trusted consensus state.
    function verifyParachainHeaderProof(bytes32 headsRoot, ParachainProof memory proof)
        private
        view
        returns (IntermediateState memory)
    {
        Node[] memory leaves = new Node[](1);
        Parachain memory para = proof.parachain;
        if (para.id != _paraId) {
            revert("Unknown paraId");
        }

        Header memory header = Codec.DecodeHeader(para.header);
        require(header.number != 0, "Genesis block should not be included");
        // extract verified metadata from header
        bytes32 commitment;
        uint256 timestamp;
        for (uint256 j = 0; j < header.digests.length; j++) {
            if (header.digests[j].isConsensus && header.digests[j].consensus.consensusId == ISMP_CONSENSUS_ID) {
                commitment = Bytes.toBytes32(header.digests[j].consensus.data);
            }

            if (header.digests[j].isPreRuntime && header.digests[j].preruntime.consensusId == AURA_CONSENSUS_ID) {
                uint256 slot = ScaleCodec.decodeUint256(header.digests[j].preruntime.data);
                timestamp = slot * SLOT_DURATION;
            }
        }
        // require(commitment != bytes32(0), "Request commitment not found!");
        require(timestamp != 0, "Request commitment not found!");

        leaves[0] = Node(
            para.index,
            keccak256(bytes.concat(ScaleCodec.encode32(uint32(para.id)), ScaleCodec.encodeBytes(para.header)))
        );

        IntermediateState memory intermediate =
            IntermediateState(para.id, header.number, StateCommitment(timestamp, commitment, header.stateRoot));

        require(MerkleMultiProof.VerifyProof(headsRoot, proof.proof, leaves), "Invalid parachains heads proof");

        return intermediate;
    }

    /// Calculates the mmr leaf index for a block whose parent number is given.
    function leafIndex(uint256 activationBlock, uint256 parentNumber) private pure returns (uint256) {
        if (activationBlock == 0) {
            return parentNumber;
        } else {
            return activationBlock - (parentNumber + 2);
        }
    }

    /// Check for supermajority participation.
    function checkParticipationThreshold(uint256 len, uint256 total) private pure returns (bool) {
        return len >= ((2 * total) / 3) + 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "solidity-merkle-trees/MerkleMultiProof.sol";
import "solidity-merkle-trees/trie/substrate/ScaleCodec.sol";
import "solidity-merkle-trees/trie/Bytes.sol";
import "./Header.sol";
import "./BeefyV1.sol";

/// type encoding stuff
library Codec {
    uint8 internal constant DIGEST_ITEM_OTHER = 0;
    uint8 internal constant DIGEST_ITEM_CONSENSUS = 4;
    uint8 internal constant DIGEST_ITEM_SEAL = 5;
    uint8 internal constant DIGEST_ITEM_PRERUNTIME = 6;
    uint8 internal constant DIGEST_ITEM_RUNTIME_ENVIRONMENT_UPDATED = 8;

    function Encode(Commitment memory commitment) internal pure returns (bytes memory) {
        uint256 payloadLen = commitment.payload.length;
        bytes memory accumulator = bytes("");
        for (uint256 i = 0; i < payloadLen; i++) {
            accumulator = bytes.concat(
                abi.encodePacked(commitment.payload[i].id), ScaleCodec.encodeBytes(commitment.payload[i].data)
            );
        }

        bytes memory payload = bytes.concat(ScaleCodec.encodeUintCompact(payloadLen), accumulator);

        bytes memory rest = bytes.concat(
            ScaleCodec.encode32(uint32(commitment.blockNumber)), ScaleCodec.encode64(uint64(commitment.validatorSetId))
        );

        return bytes.concat(payload, rest);
    }

    function Encode(BeefyMmrLeaf memory leaf) internal pure returns (bytes memory) {
        bytes memory first =
            bytes.concat(abi.encodePacked(uint8(leaf.version)), ScaleCodec.encode32(uint32(leaf.parentNumber)));
        bytes memory second =
            bytes.concat(bytes.concat(leaf.parentHash), ScaleCodec.encode64(uint64(leaf.nextAuthoritySet.id)));
        bytes memory third = bytes.concat(
            ScaleCodec.encode32(uint32(leaf.nextAuthoritySet.len)), bytes.concat(leaf.nextAuthoritySet.root)
        );
        return bytes.concat(bytes.concat(first, second), bytes.concat(third, bytes.concat(leaf.extra)));
    }

    function DecodeHeader(bytes memory encoded) internal pure returns (Header memory) {
        ByteSlice memory slice = ByteSlice(encoded, 0);
        bytes32 parentHash = Bytes.toBytes32(Bytes.read(slice, 32));
        uint256 blockNumber = ScaleCodec.decodeUintCompact(slice);
        bytes32 stateRoot = Bytes.toBytes32(Bytes.read(slice, 32));
        bytes32 extrinsicsRoot = Bytes.toBytes32(Bytes.read(slice, 32));

        uint256 length = ScaleCodec.decodeUintCompact(slice);
        Digest[] memory digests = new Digest[](length);

        for (uint256 i = 0; i < length; i++) {
            uint8 kind = Bytes.readByte(slice);
            Digest memory digest;
            if (kind == DIGEST_ITEM_OTHER) {
                digest.isOther = true;
            } else if (kind == DIGEST_ITEM_CONSENSUS) {
                digest.isConsensus = true;
                digest.consensus = decodeDigestItem(slice);
            } else if (kind == DIGEST_ITEM_SEAL) {
                digest.isSeal = true;
                digest.seal = decodeDigestItem(slice);
            } else if (kind == DIGEST_ITEM_PRERUNTIME) {
                digest.isPreRuntime = true;
                digest.preruntime = decodeDigestItem(slice);
            } else if (kind == DIGEST_ITEM_RUNTIME_ENVIRONMENT_UPDATED) {
                digest.isRuntimeEnvironmentUpdated = true;
            }
            digests[i] = digest;
        }

        return Header(parentHash, blockNumber, stateRoot, extrinsicsRoot, digests);
    }

    function decodeDigestItem(ByteSlice memory slice) internal pure returns (DigestItem memory) {
        bytes4 id = Bytes.toBytes4(read(slice, 4), 0);
        uint256 length = ScaleCodec.decodeUintCompact(slice);
        bytes memory data = Bytes.read(slice, length);
        return DigestItem(id, data);
    }

    function read(ByteSlice memory self, uint256 len) internal pure returns (bytes memory) {
        require(self.offset + len <= self.data.length);
        if (len == 0) {
            return "";
        }
        uint256 addr = Memory.dataPtr(self.data);
        bytes memory slice = Memory.toBytes(addr + self.offset, len);
        self.offset += len;
        return slice;
    }

    function readByte(ByteSlice memory self) internal pure returns (uint8) {
        require(self.offset + 1 <= self.data.length);

        uint8 b = uint8(self.data[self.offset]);
        self.offset += 1;

        return b;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(ByteSlice memory data) internal pure returns (uint256 v) {
        uint8 b = readByte(data); // read the first byte
        uint8 mode = b & 3; // bitwise operation

        uint256 value;
        if (mode == 0) {
            // [0, 63]
            value = b >> 2; // right shift to remove mode bits
        } else if (mode == 1) {
            // [64, 16383]
            uint8 bb = readByte(data); // read the second byte
            uint64 r = bb; // convert to uint64
            r <<= 6; // multiply by * 2^6
            r += b >> 2; // right shift to remove mode bits
            value = r;
        } else if (mode == 2) {
            // [16384, 1073741823]
            uint8 b2 = readByte(data); // read the next 3 bytes
            uint8 b3 = readByte(data);
            uint8 b4 = readByte(data);

            uint32 x1 = uint32(b) | (uint32(b2) << 8); // convert to little endian
            uint32 x2 = x1 | (uint32(b3) << 16);
            uint32 x3 = x2 | (uint32(b4) << 24);

            x3 >>= 2; // remove the last 2 mode bits
            value = uint256(x3);
        } else if (mode == 3) {
            // [1073741824, 4503599627370496]
            uint8 l = (b >> 2) + 4; // remove mode bits
            require(l <= 8, "unexpected prefix decoding Compact<Uint>");
            return ScaleCodec.decodeUint256(read(data, l));
        } else {
            revert("Code should be unreachable");
        }
        return (value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "openzeppelin/utils/Strings.sol";

library StateMachine {
    /// The identifier for the relay chain.
    uint256 public constant RELAY_CHAIN = 0;

    // Address a state machine on the polkadot relay chain
    function polkadot(uint256 id) public pure returns (bytes memory) {
        return bytes(string.concat("POLKADOT-", Strings.toString(id)));
    }

    // Address a state machine on the kusama relay chain
    function kusama(uint256 id) public pure returns (bytes memory) {
        return bytes(string.concat("KUSAMA-", Strings.toString(id)));
    }

    // Address the ethereum "execution layer"
    function ethereum() public pure returns (bytes memory) {
        return bytes("ETHE");
    }

    // Address the Arbitrum state machine
    function arbitrum() public pure returns (bytes memory) {
        return bytes("ARBI");
    }

    // Address the Optimism state machine
    function optimism() public pure returns (bytes memory) {
        return bytes("OPTI");
    }

    // Address the Base state machine
    function base() public pure returns (bytes memory) {
        return bytes("BASE");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "solidity-merkle-trees/MerklePatricia.sol";

// The state commiment identifies a commiment to some intermediate state in the state machine.
// This contains some metadata about the state machine like it's own timestamp at the time of this commitment.
struct StateCommitment {
    // This timestamp is useful for handling request timeouts.
    uint256 timestamp;
    // merkle mountain range commitment to all ismp requests & response.
    bytes32 overlayRoot;
    // state root for processing timeouts.
    bytes32 stateRoot;
}

// Identifies some state machine height. We allow for a state machine identifier here
// as some consensus clients may track multiple, concurrent state machines.
struct StateMachineHeight {
    // the state machine identifier
    uint256 stateMachineId;
    // height of this state machine
    uint256 height;
}

struct IntermediateState {
    // the state machine identifier
    uint256 stateMachineId;
    // height of this state machine
    uint256 height;
    // state commitment
    StateCommitment commitment;
}

interface IConsensusClient {
    /// Verify the consensus proof and return the new trusted consensus state and any intermediate states finalized
    /// by this consensus proof.
    function verifyConsensus(bytes memory trustedState, bytes memory proof)
        external
        returns (bytes memory, IntermediateState memory);
}

// SPDX-License-Identifier: Apache2
pragma solidity ^0.8.17;

import "openzeppelin/utils/math/Math.sol";

/// @title A representation of a Merkle tree node
struct Node {
    // Distance of the node to the leftmost node
    uint256 k_index;
    // A hash of the node itself
    bytes32 node;
}

/**
 * @title A Merkle Multi proof library
 * @author Polytope Labs
 * @dev Use this library to verify merkle tree leaves using merkle multi proofs
 * @dev refer to research for more info. https://research.polytope.technology/merkle-multi-proofs
 */
library MerkleMultiProof {
    /**
     * @notice Verify a Merkle Multi Proof
     * @param root hash of the root node of the merkle tree
     * @param proof A list of the merkle nodes along with their k-indices that are needed to re-calculate root node.
     * @param leaves A list of the leaves along with their k-indices to prove
     * @return boolean if the calculated root matches the provides root node
     */
    function VerifyProof(bytes32 root, Node[][] memory proof, Node[] memory leaves) internal pure returns (bool) {
        return root == CalculateRoot(proof, leaves);
    }

    /**
     * @notice Verify a Merkle Multi Proof whose internal nodes are sorted
     * @param root hash of the root node of the merkle tree
     * @param proof A list of the merkle nodes along with their k-indices that are needed to re-calculate root node.
     * @param leaves A list of the leaves along with their k-indices to prove
     * @return boolean if the calculated root matches the provides root node
     */
    function VerifyProofSorted(bytes32 root, Node[][] memory proof, Node[] memory leaves)
        internal
        pure
        returns (bool)
    {
        return root == CalculateRootSorted(proof, leaves);
    }

    /// @notice Calculate the hash of the root node
    /// @dev Use this function to calculate the hash of the root node
    /// @param proof A list of the merkle nodes along with their k-indices that are needed to re-calculate root node.
    /// @param leaves A list of the leaves along with their k-indices to prove
    /// @return Hash of root node, value is a bytes32 type
    function CalculateRoot(Node[][] memory proof, Node[] memory leaves) internal pure returns (bytes32) {
        // holds the output from hashing a previous layer
        Node[] memory next_layer = new Node[](0);

        // merge leaves
        proof[0] = mergeSort(leaves, proof[0]);

        uint256 proof_length = proof.length;
        for (uint256 height = 0; height < proof_length; height++) {
            Node[] memory current_layer = new Node[](0);

            if (next_layer.length == 0) {
                current_layer = proof[height];
            } else {
                current_layer = mergeSort(proof[height], next_layer);
            }

            next_layer = new Node[](div_ceil(current_layer.length, 2));

            uint256 p = 0;
            uint256 current_layer_length = current_layer.length;
            for (uint256 index = 0; index < current_layer_length; index += 2) {
                if (index + 1 >= current_layer_length) {
                    Node memory node = current_layer[index];
                    node.k_index = div_floor(current_layer[index].k_index, 2);
                    next_layer[p] = node;
                } else {
                    Node memory node;
                    node.k_index = div_floor(current_layer[index].k_index, 2);
                    node.node = _optimizedHash(current_layer[index].node, current_layer[index + 1].node);
                    next_layer[p] = node;
                    unchecked {
                        p++;
                    }
                }
            }
        }

        // we should have arrived at the root node
        require(next_layer.length == 1);

        return next_layer[0].node;
    }

    /// @notice Calculate the hash of the root node using a sorted node approach.
    /// @dev Use this function to calculate the hash of the root node
    /// @param proof A list of the merkle nodes that are needed to re-calculate root node.
    /// @param leaves A list of the leaves to prove
    /// @return Hash of root node, value is a bytes32 type
    function CalculateRootSorted(Node[][] memory proof, Node[] memory leaves) internal pure returns (bytes32) {
        // holds the output from hashing a previous layer
        Node[] memory next_layer = new Node[](0);

        // merge leaves
        proof[0] = mergeSort(leaves, proof[0]);

        uint256 proof_length = proof.length;
        for (uint256 height = 0; height < proof_length; height++) {
            Node[] memory current_layer = new Node[](0);

            if (next_layer.length == 0) {
                current_layer = proof[height];
            } else {
                current_layer = mergeSort(proof[height], next_layer);
            }
            uint256 current_layer_length = current_layer.length;
            uint256 p = 0;

            next_layer = new Node[](div_ceil(current_layer_length, 2));
            for (uint256 index = 0; index < current_layer_length; index += 2) {
                if (index + 1 >= current_layer_length) {
                    Node memory node = current_layer[index];
                    node.k_index = div_floor(current_layer[index].k_index, 2);
                    next_layer[p] = node;
                } else {
                    Node memory node;
                    bytes32 a = current_layer[index].node;
                    bytes32 b = current_layer[index + 1].node;
                    if (a < b) {
                        node.node = _optimizedHash(a, b);
                    } else {
                        node.node = _optimizedHash(b, a);
                    }
                    node.k_index = div_floor(current_layer[index].k_index, 2);
                    next_layer[p] = node;
                    unchecked {
                        p++;
                    }
                }
            }
        }

        // we should have arrived at the root node
        require(next_layer.length == 1);

        return next_layer[0].node;
    }

    function div_floor(uint256 x, uint256 y) internal pure returns (uint256) {
        return x / y;
    }

    function div_ceil(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 result = x / y;
        if (x % y != 0) {
            unchecked {
                result += 1;
            }
        }

        return result;
    }

    /// @notice an internal function to merge two arrays and sort them at the same time.
    /// @dev compares the k-index of each node and sort in increasing order
    /// @param arr1 leftmost index in arr
    /// @param arr2 highest index in arr
    function mergeSort(Node[] memory arr1, Node[] memory arr2) internal pure returns (Node[] memory) {
        // merge the two arrays
        uint256 i = 0;
        uint256 j = 0;
        uint256 k = 0;
        uint256 arr1_length = arr1.length;
        uint256 arr2_length = arr2.length;
        uint256 out_len = arr1_length + arr2_length;
        Node[] memory out = new Node[](out_len);

        while (i < arr1_length && j < arr2_length) {
            if (arr1[i].k_index < arr2[j].k_index) {
                out[k] = arr1[i];
                unchecked {
                    i++;
                    k++;
                }
            } else {
                out[k] = arr2[j];
                unchecked {
                    j++;
                    k++;
                }
            }
        }

        while (i < arr1_length) {
            out[k] = arr1[i];
            unchecked {
                i++;
                k++;
            }
        }

        while (j < arr2_length) {
            out[k] = arr2[j];
            unchecked {
                j++;
                k++;
            }
        }

        return out;
    }

    /// @notice compute the keccak256 hash of two nodes
    /// @param node1 hash of one of the two nodes
    /// @param node2 hash of the other of the two nodes
    function _optimizedHash(bytes32 node1, bytes32 node2) internal pure returns (bytes32 hash) {
        assembly {
            // use EVM scratch space, its memory safe
            mstore(0x0, node1)
            mstore(0x20, node2)
            hash := keccak256(0x0, 0x40)
        }
    }

    /// @notice compute the height of the tree whose total number of leaves is given, it accounts for unbalanced trees.
    /// @param leavesCount number of leaves in the tree
    /// @return height of the tree
    function TreeHeight(uint256 leavesCount) internal pure returns (uint256) {
        uint256 height = Math.log2(leavesCount, Math.Rounding.Up);
        if (!isPowerOfTwo(leavesCount)) {
            unchecked {
                height++;
            }
        }

        return height;
    }

    function isPowerOfTwo(uint256 x) internal pure returns (bool) {
        if (x == 0) {
            return false;
        }

        return (x & (x - 1)) == 0;
    }
}

// SPDX-License-Identifier: Apache2
pragma solidity ^0.8.17;

import "./MerkleMultiProof.sol";
import "openzeppelin/utils/math/Math.sol";

/// @title A representation of a MerkleMountainRange leaf
struct MmrLeaf {
    // the leftmost index of a node
    uint256 k_index;
    // The position in the tree
    uint256 leaf_index;
    // The hash of the position in the tree
    bytes32 hash;
}

struct Iterator {
    uint256 offset;
    bytes32[] data;
}

/**
 * @title A Merkle Mountain Range proof library
 * @author Polytope Labs
 * @notice Use this library to verify the leaves of a merkle mountain range tree
 * @dev refer to research for more info. https://research.polytope.technology/merkle-mountain-range-multi-proofs
 */
library MerkleMountainRange {
    /// @notice Verify that merkle proof is accurate
    /// @notice This calls CalculateRoot(...) under the hood
    /// @param root hash of the Merkle's root node
    /// @param proof a list of nodes required for the proof to be verified
    /// @param leaves a list of mmr leaves to prove
    /// @return boolean if the calculated root matches the provides root node
    function VerifyProof(bytes32 root, bytes32[] memory proof, MmrLeaf[] memory leaves, uint256 mmrSize)
        public
        pure
        returns (bool)
    {
        return root == CalculateRoot(proof, leaves, mmrSize);
    }

    /// @notice Calculate merkle root
    /// @notice this method allows computing the root hash of a merkle tree using Merkle Mountain Range
    /// @param proof A list of the merkle nodes that are needed to re-calculate root node.
    /// @param leaves a list of mmr leaves to prove
    /// @param leafCount the size of the merkle tree
    /// @return bytes32 hash of the computed root node
    function CalculateRoot(bytes32[] memory proof, MmrLeaf[] memory leaves, uint256 leafCount)
        public
        pure
        returns (bytes32)
    {
        // special handle the only 1 leaf MMR
        if (leafCount == 1 && leaves.length == 1 && leaves[0].leaf_index == 0) {
            return leaves[0].hash;
        }

        uint256[] memory subtrees = subtreeHeights(leafCount);
        uint256 length = subtrees.length;
        Iterator memory peakRoots = Iterator(0, new bytes32[](length));
        Iterator memory proofIter = Iterator(0, proof);

        uint256 current_subtree = 0;
        for (uint256 p = 0; p < length; p++) {
            uint256 height = subtrees[p];
            current_subtree += 2 ** height;

            MmrLeaf[] memory subtreeLeaves = new MmrLeaf[](0);
            if (leaves.length > 0) {
                (subtreeLeaves, leaves) = leavesForSubtree(leaves, current_subtree);
            }

            if (subtreeLeaves.length == 0) {
                if (proofIter.data.length == proofIter.offset) {
                    break;
                } else {
                    push(peakRoots, next(proofIter));
                }
            } else if (subtreeLeaves.length == 1 && height == 0) {
                push(peakRoots, subtreeLeaves[0].hash);
            } else {
                push(peakRoots, CalculateSubtreeRoot(subtreeLeaves, proofIter, height));
            }
        }

        unchecked {
            peakRoots.offset--;
        }

        while (peakRoots.offset != 0) {
            bytes32 right = previous(peakRoots);
            bytes32 left = previous(peakRoots);
            unchecked {
                ++peakRoots.offset;
            }
            peakRoots.data[peakRoots.offset] = keccak256(abi.encodePacked(right, left));
        }

        return peakRoots.data[0];
    }

    function subtreeHeights(uint256 leavesLength) internal pure returns (uint256[] memory) {
        uint256 maxSubtrees = 64;
        uint256[] memory indices = new uint256[](maxSubtrees);
        uint256 i = 0;
        uint256 current = leavesLength;
        for (; i < maxSubtrees; i++) {
            if (current == 0) {
                break;
            }
            uint256 log = Math.log2(current);
            indices[i] = log;
            current = current - 2 ** log;
        }

        // resize array?, sigh solidity.
        uint256 excess = maxSubtrees - i;
        assembly {
            mstore(indices, sub(mload(indices), excess))
        }

        return indices;
    }

    /// @notice calculate root hash of a subtree of the merkle mountain
    /// @param peakLeaves  a list of nodes to provide proof for
    /// @param proofIter   a list of node hashes to traverse to compute the peak root hash
    /// @param height    Height of the subtree
    /// @return peakRoot a tuple containing the peak root hash, and the peak root position in the merkle
    function CalculateSubtreeRoot(MmrLeaf[] memory peakLeaves, Iterator memory proofIter, uint256 height)
        internal
        pure
        returns (bytes32)
    {
        uint256[] memory current_layer;
        Node[] memory leaves;
        (leaves, current_layer) = mmrLeafToNode(peakLeaves);

        Node[][] memory layers = new Node[][](height);
        for (uint256 i = 0; i < height; i++) {
            uint256 nodelength = 2 ** (height - i);
            if (current_layer.length == nodelength) {
                break;
            }

            uint256[] memory siblings = siblingIndices(current_layer);
            uint256[] memory diff = difference(siblings, current_layer);

            uint256 length = diff.length;
            layers[i] = new Node[](length);
            for (uint256 j = 0; j < length; j++) {
                layers[i][j] = Node(diff[j], next(proofIter));
            }

            current_layer = parentIndices(siblings);
        }

        return MerkleMultiProof.CalculateRoot(layers, leaves);
    }

    /**
     * @notice difference ensures all nodes have a sibling.
     * @dev left and right are designed to be equal length array
     * @param left a list of hashes
     * @param right a list of hashes to compare
     * @return uint256[] a new array with difference
     */
    function difference(uint256[] memory left, uint256[] memory right) internal pure returns (uint256[] memory) {
        uint256 length = left.length;
        uint256 rightLength = right.length;

        uint256[] memory diff = new uint256[](length);
        uint256 d = 0;
        for (uint256 i = 0; i < length; i++) {
            bool found = false;
            for (uint256 j = 0; j < rightLength; j++) {
                if (left[i] == right[j]) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                diff[d] = left[i];
                d++;
            }
        }

        // resize array?, sigh solidity.
        uint256 excess = length - d;
        assembly {
            mstore(diff, sub(mload(diff), excess))
        }

        return diff;
    }

    /**
     * @dev calculates the index of each sibling index of the proof nodes
     * @dev proof nodes are the nodes that will be traversed to estimate the root hash
     * @param indices a list of proof nodes indices
     * @return uint256[] a list of sibling indices
     */
    function siblingIndices(uint256[] memory indices) internal pure returns (uint256[] memory) {
        uint256 length = indices.length;
        uint256[] memory siblings = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 index = indices[i];
            if (index == 0) {
                siblings[i] = index + 1;
            } else if (index % 2 == 0) {
                siblings[i] = index + 1;
            } else {
                siblings[i] = index - 1;
            }
        }

        return siblings;
    }

    /**
     * @notice Compute Parent Indices
     * @dev Used internally to calculate the indices of the parent nodes of the provided proof nodes
     * @param indices a list of indices of proof nodes in a merkle mountain
     * @return uint256[] a list of parent indices for each index provided
     */
    function parentIndices(uint256[] memory indices) internal pure returns (uint256[] memory) {
        uint256 length = indices.length;
        uint256[] memory parents = new uint256[](length);
        uint256 k = 0;

        for (uint256 i = 0; i < length; i++) {
            uint256 index = indices[i] / 2;
            if (k > 0 && parents[k - 1] == index) {
                continue;
            }
            parents[k] = index;
            unchecked {
                ++k;
            }
        }

        // resize array?, sigh solidity.
        uint256 excess = length - k;

        assembly {
            mstore(parents, sub(mload(parents), excess))
        }

        return parents;
    }

    /**
     * @notice Convert Merkle mountain Leaf to a Merkle Node
     * @param leaves list of merkle mountain range leaf
     * @return A tuple with the list of merkle nodes and the list of nodes at 0 and 1 respectively
     */
    function mmrLeafToNode(MmrLeaf[] memory leaves) internal pure returns (Node[] memory, uint256[] memory) {
        uint256 i = 0;
        uint256 length = leaves.length;
        Node[] memory nodes = new Node[](length);
        uint256[] memory indices = new uint256[](length);
        while (i < length) {
            nodes[i] = Node(leaves[i].k_index, leaves[i].hash);
            indices[i] = leaves[i].k_index;
            ++i;
        }

        return (nodes, indices);
    }

    /**
     * @notice Get a meountain peak's leaves
     * @notice this splits the leaves into either side of the peak [left & right]
     * @param leaves a list of mountain merkle leaves, for a subtree
     * @param leafIndex the index of the leaf of the next subtree
     * @return A tuple of 2 arrays of mountain merkle leaves. Index 1 and 2 represent left and right of the peak respectively
     */
    function leavesForSubtree(MmrLeaf[] memory leaves, uint256 leafIndex)
        internal
        pure
        returns (MmrLeaf[] memory, MmrLeaf[] memory)
    {
        uint256 p = 0;
        uint256 length = leaves.length;
        for (; p < length; p++) {
            if (leafIndex <= leaves[p].leaf_index) {
                break;
            }
        }

        uint256 len = p == 0 ? 0 : p;
        MmrLeaf[] memory left = new MmrLeaf[](len);
        MmrLeaf[] memory right = new MmrLeaf[](length - len);

        uint256 i = 0;
        uint256 leftLength = left.length;
        while (i < leftLength) {
            left[i] = leaves[i];
            ++i;
        }

        uint256 j = 0;
        while (i < length) {
            right[j] = leaves[i];
            ++i;
            ++j;
        }

        return (left, right);
    }

    function push(Iterator memory iterator, bytes32 data) internal pure {
        iterator.data[iterator.offset] = data;
        unchecked {
            ++iterator.offset;
        }
    }

    function next(Iterator memory iterator) internal pure returns (bytes32) {
        bytes32 data = iterator.data[iterator.offset];
        unchecked {
            ++iterator.offset;
        }

        return data;
    }

    function previous(Iterator memory iterator) internal pure returns (bytes32) {
        bytes32 data = iterator.data[iterator.offset];
        unchecked {
            --iterator.offset;
        }

        return data;
    }
}

pragma solidity ^0.8.17;

import "./trie/Node.sol";
import "./trie/Option.sol";
import "./trie/NibbleSlice.sol";
import "./trie/TrieDB.sol";

import "./trie/substrate/SubstrateTrieDB.sol";
import "./trie/ethereum/EthereumTrieDB.sol";

// SPDX-License-Identifier: Apache2

// Outcome of a successfully verified merkle-patricia proof
struct StorageValue {
    // the storage key
    bytes key;
    // the encoded value
    bytes value;
}

/**
 * @title A Merkle Patricia library
 * @author Polytope Labs
 * @dev Use this library to verify merkle patricia proofs
 * @dev refer to research for more info. https://research.polytope.technology/state-(machine)-proofs
 */
library MerklePatricia {
    /// @notice libraries in solidity can only have constant variables
    /// @dev MAX_TRIE_DEPTH, we don't explore deeply nested trie keys.
    uint256 internal constant MAX_TRIE_DEPTH = 50;

    /**
     * @notice Verifies substrate specific merkle patricia proofs.
     * @param root hash of the merkle patricia trie
     * @param proof a list of proof nodes
     * @param keys a list of keys to verify
     * @return bytes[] a list of values corresponding to the supplied keys.
     */
    function VerifySubstrateProof(bytes32 root, bytes[] memory proof, bytes[] memory keys)
        public
        pure
        returns (StorageValue[] memory)
    {
        StorageValue[] memory values = new StorageValue[](keys.length);
        TrieNode[] memory nodes = new TrieNode[](proof.length);

        for (uint256 i = 0; i < proof.length; i++) {
            nodes[i] = TrieNode(keccak256(proof[i]), proof[i]);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            values[i].key = keys[i];
            NibbleSlice memory keyNibbles = NibbleSlice(keys[i], 0);
            NodeKind memory node = SubstrateTrieDB.decodeNodeKind(TrieDB.get(nodes, root));

            // worst case scenario, so we avoid unbounded loops
            for (uint256 j = 0; j < MAX_TRIE_DEPTH; j++) {
                NodeHandle memory nextNode;

                if (TrieDB.isLeaf(node)) {
                    Leaf memory leaf = SubstrateTrieDB.decodeLeaf(node);
                    if (NibbleSliceOps.eq(leaf.key, keyNibbles)) {
                        values[i].value = TrieDB.load(nodes, leaf.value);
                    }
                    break;
                } else if (TrieDB.isNibbledBranch(node)) {
                    NibbledBranch memory nibbled = SubstrateTrieDB.decodeNibbledBranch(node);
                    uint256 nibbledBranchKeyLength = NibbleSliceOps.len(nibbled.key);
                    if (!NibbleSliceOps.startsWith(keyNibbles, nibbled.key)) {
                        break;
                    }

                    if (NibbleSliceOps.len(keyNibbles) == nibbledBranchKeyLength) {
                        if (Option.isSome(nibbled.value)) {
                            values[i].value = TrieDB.load(nodes, nibbled.value.value);
                        }
                        break;
                    } else {
                        uint256 index = NibbleSliceOps.at(keyNibbles, nibbledBranchKeyLength);
                        NodeHandleOption memory handle = nibbled.children[index];
                        if (Option.isSome(handle)) {
                            keyNibbles = NibbleSliceOps.mid(keyNibbles, nibbledBranchKeyLength + 1);
                            nextNode = handle.value;
                        } else {
                            break;
                        }
                    }
                } else if (TrieDB.isEmpty(node)) {
                    break;
                }

                node = SubstrateTrieDB.decodeNodeKind(TrieDB.load(nodes, nextNode));
            }
        }

        return values;
    }

    /**
     * @notice Verify child trie keys
     * @dev substrate specific method in order to verify keys in the child trie.
     * @param root hash of the merkle root
     * @param proof a list of proof nodes
     * @param keys a list of keys to verify
     * @param childInfo data that can be used to compute the root of the child trie
     * @return bytes[], a list of values corresponding to the supplied keys.
     */
    function ReadChildProofCheck(bytes32 root, bytes[] memory proof, bytes[] memory keys, bytes memory childInfo)
        public
        pure
        returns (StorageValue[] memory)
    {
        // fetch the child trie root hash;
        bytes memory prefix = bytes(":child_storage:default:");
        bytes memory key = bytes.concat(prefix, childInfo);
        bytes[] memory _keys = new bytes[](1);
        _keys[0] = key;
        StorageValue[] memory values = VerifySubstrateProof(root, proof, _keys);

        bytes32 childRoot = bytes32(values[0].value);
        require(childRoot != bytes32(0), "Invalid child trie proof");

        return VerifySubstrateProof(childRoot, proof, keys);
    }

    /**
     * @notice Verifies ethereum specific merkle patricia proofs as described by EIP-1188.
     * @param root hash of the merkle patricia trie
     * @param proof a list of proof nodes
     * @param keys a list of keys to verify
     * @return bytes[] a list of values corresponding to the supplied keys.
     */
    function VerifyEthereumProof(bytes32 root, bytes[] memory proof, bytes[] memory keys)
        public
        pure
        returns (StorageValue[] memory)
    {
        StorageValue[] memory values = new StorageValue[](keys.length);
        TrieNode[] memory nodes = new TrieNode[](proof.length);

        for (uint256 i = 0; i < proof.length; i++) {
            nodes[i] = TrieNode(keccak256(proof[i]), proof[i]);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            values[i].key = keys[i];
            NibbleSlice memory keyNibbles = NibbleSlice(keys[i], 0);
            NodeKind memory node = EthereumTrieDB.decodeNodeKind(TrieDB.get(nodes, root));

            // worst case scenario, so we avoid unbounded loops
            for (uint256 j = 0; j < MAX_TRIE_DEPTH; j++) {
                NodeHandle memory nextNode;

                if (TrieDB.isLeaf(node)) {
                    Leaf memory leaf = EthereumTrieDB.decodeLeaf(node);
                    // Let's retrieve the offset to be used
                    uint256 offset = keyNibbles.offset % 2 == 0 ? keyNibbles.offset / 2 : keyNibbles.offset / 2 + 1;
                    // Let's cut the key passed as input
                    keyNibbles = NibbleSlice(NibbleSliceOps.bytesSlice(keyNibbles.data, offset), 0);
                    if (NibbleSliceOps.eq(leaf.key, keyNibbles)) {
                        values[i].value = TrieDB.load(nodes, leaf.value);
                    }
                    break;
                } else if (TrieDB.isExtension(node)) {
                    Extension memory extension = EthereumTrieDB.decodeExtension(node);
                    if (NibbleSliceOps.startsWith(keyNibbles, extension.key)) {
                        // Let's cut the key passed as input
                        keyNibbles = NibbleSlice(
                            NibbleSliceOps.bytesSlice(keyNibbles.data, NibbleSliceOps.len(extension.key)), 0
                        );
                        nextNode = extension.node;
                    } else {
                        break;
                    }
                } else if (TrieDB.isBranch(node)) {
                    Branch memory branch = EthereumTrieDB.decodeBranch(node);
                    if (NibbleSliceOps.isEmpty(keyNibbles)) {
                        if (Option.isSome(branch.value)) {
                            values[i].value = TrieDB.load(nodes, branch.value.value);
                        }
                        break;
                    } else {
                        NodeHandleOption memory handle = branch.children[NibbleSliceOps.at(keyNibbles, 0)];
                        if (Option.isSome(handle)) {
                            keyNibbles = NibbleSliceOps.mid(keyNibbles, 1);
                            nextNode = handle.value;
                        } else {
                            break;
                        }
                    }
                } else if (TrieDB.isEmpty(node)) {
                    break;
                }

                node = EthereumTrieDB.decodeNodeKind(TrieDB.load(nodes, nextNode));
            }
        }

        return values;
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache2

import {Bytes, ByteSlice} from "../Bytes.sol";

library ScaleCodec {
    // Decodes a SCALE encoded uint256 by converting bytes (bid endian) to little endian format
    function decodeUint256(bytes memory data) internal pure returns (uint256) {
        uint256 number;
        for (uint256 i = data.length; i > 0; i--) {
            number = number + uint256(uint8(data[i - 1])) * (2 ** (8 * (i - 1)));
        }
        return number;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(ByteSlice memory data) internal pure returns (uint256 v) {
        uint8 b = Bytes.readByte(data); // read the first byte
        uint8 mode = b % 4; // bitwise operation

        uint256 value;
        if (mode == 0) {
            // [0, 63]
            value = b >> 2; // right shift to remove mode bits
        } else if (mode == 1) {
            // [64, 16383]
            uint8 bb = Bytes.readByte(data); // read the second byte
            uint64 r = bb; // convert to uint64
            r <<= 6; // multiply by * 2^6
            r += b >> 2; // right shift to remove mode bits
            value = r;
        } else if (mode == 2) {
            // [16384, 1073741823]
            uint8 b2 = Bytes.readByte(data); // read the next 3 bytes
            uint8 b3 = Bytes.readByte(data);
            uint8 b4 = Bytes.readByte(data);

            uint32 x1 = uint32(b) | (uint32(b2) << 8); // convert to little endian
            uint32 x2 = x1 | (uint32(b3) << 16);
            uint32 x3 = x2 | (uint32(b4) << 24);

            x3 >>= 2; // remove the last 2 mode bits
            value = uint256(x3);
        } else if (mode == 3) {
            // [1073741824, 4503599627370496]
            uint8 l = (b >> 2) + 4; // remove mode bits
            require(l <= 8, "unexpected prefix decoding Compact<Uint>");
            return decodeUint256(Bytes.read(data, l));
        } else {
            revert("Code should be unreachable");
        }
        return value;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(bytes memory data) internal pure returns (uint256 v, uint8 m) {
        uint8 b = readByteAtIndex(data, 0); // read the first byte
        uint8 mode = b & 3; // bitwise operation

        uint256 value;
        if (mode == 0) {
            // [0, 63]
            value = b >> 2; // right shift to remove mode bits
        } else if (mode == 1) {
            // [64, 16383]
            uint8 bb = readByteAtIndex(data, 1); // read the second byte
            uint64 r = bb; // convert to uint64
            r <<= 6; // multiply by * 2^6
            r += b >> 2; // right shift to remove mode bits
            value = r;
        } else if (mode == 2) {
            // [16384, 1073741823]
            uint8 b2 = readByteAtIndex(data, 1); // read the next 3 bytes
            uint8 b3 = readByteAtIndex(data, 2);
            uint8 b4 = readByteAtIndex(data, 3);

            uint32 x1 = uint32(b) | (uint32(b2) << 8); // convert to little endian
            uint32 x2 = x1 | (uint32(b3) << 16);
            uint32 x3 = x2 | (uint32(b4) << 24);

            x3 >>= 2; // remove the last 2 mode bits
            value = uint256(x3);
        } else if (mode == 3) {
            // [1073741824, 4503599627370496]
            uint8 l = b >> 2; // remove mode bits
            require(l > 32, "Not supported: number cannot be greater than 32 bytes");
        } else {
            revert("Code should be unreachable");
        }
        return (value, mode);
    }

    // The biggest compact supported uint is 2 ** 536 - 1.
    // But the biggest value supported by this method is 2 ** 256 - 1(max of uint256)
    function encodeUintCompact(uint256 v) internal pure returns (bytes memory) {
        if (v < 64) {
            return abi.encodePacked(uint8(v << 2));
        } else if (v < 2 ** 14) {
            return abi.encodePacked(reverse16(uint16(((v << 2) + 1))));
        } else if (v < 2 ** 30) {
            return abi.encodePacked(reverse32(uint32(((v << 2) + 2))));
        } else {
            bytes memory valueBytes = Bytes.removeEndingZero(abi.encodePacked(reverse256(v)));

            uint256 length = valueBytes.length;
            uint8 prefix = uint8(((length - 4) << 2) + 3);

            return abi.encodePacked(prefix, valueBytes);
        }
    }

    // Read a byte at a specific index and return it as type uint8
    function readByteAtIndex(bytes memory data, uint8 index) internal pure returns (uint8) {
        return uint8(data[index]);
    }

    // Sources:
    //   * https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity/50528
    //   * https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel

    function reverse256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8)
            | ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16)
            | ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32)
            | ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64)
            | ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    function reverse128(uint128 input) internal pure returns (uint128 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) | ((v & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = (v >> 64) | (v << 64);
    }

    function reverse64(uint64 input) internal pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    function reverse32(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) | ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    function reverse16(uint16 input) internal pure returns (uint16 v) {
        v = input;

        // swap bytes
        v = (v >> 8) | (v << 8);
    }

    function encode256(uint256 input) internal pure returns (bytes32) {
        return bytes32(reverse256(input));
    }

    function encode128(uint128 input) internal pure returns (bytes16) {
        return bytes16(reverse128(input));
    }

    function encode64(uint64 input) internal pure returns (bytes8) {
        return bytes8(reverse64(input));
    }

    function encode32(uint32 input) internal pure returns (bytes4) {
        return bytes4(reverse32(input));
    }

    function encode16(uint16 input) internal pure returns (bytes2) {
        return bytes2(reverse16(input));
    }

    function encodeBytes(bytes memory input) internal pure returns (bytes memory) {
        return abi.encodePacked(encodeUintCompact(input.length), input);
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache2

import {Memory} from "./Memory.sol";

struct ByteSlice {
    bytes data;
    uint256 offset;
}

library Bytes {
    uint256 internal constant BYTES_HEADER_SIZE = 32;

    // Checks if two `bytes memory` variables are equal. This is done using hashing,
    // which is much more gas efficient then comparing each byte individually.
    // Equality means that:
    //  - 'self.length == other.length'
    //  - For 'n' in '[0, self.length)', 'self[n] == other[n]'
    function equals(bytes memory self, bytes memory other) internal pure returns (bool equal) {
        if (self.length != other.length) {
            return false;
        }
        uint256 addr;
        uint256 addr2;
        assembly {
            addr := add(self, /*BYTES_HEADER_SIZE*/ 32)
            addr2 := add(other, /*BYTES_HEADER_SIZE*/ 32)
        }
        equal = Memory.equals(addr, addr2, self.length);
    }

    function readByte(ByteSlice memory self) internal pure returns (uint8) {
        if (self.offset + 1 > self.data.length) {
            revert("Out of range");
        }

        uint8 b = uint8(self.data[self.offset]);
        self.offset += 1;

        return b;
    }

    // Copies 'len' bytes from 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that:
    //  - 'startIndex + len <= self.length'
    // The length of the substring is: 'len'
    function read(ByteSlice memory self, uint256 len) internal pure returns (bytes memory) {
        require(self.offset + len <= self.data.length);
        if (len == 0) {
            return "";
        }
        uint256 addr = Memory.dataPtr(self.data);
        bytes memory slice = Memory.toBytes(addr + self.offset, len);
        self.offset += len;
        return slice;
    }

    // Copies a section of 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that 'startIndex <= self.length'
    // The length of the substring is: 'self.length - startIndex'
    function substr(bytes memory self, uint256 startIndex) internal pure returns (bytes memory) {
        require(startIndex <= self.length);
        uint256 len = self.length - startIndex;
        uint256 addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIndex, len);
    }

    // Copies 'len' bytes from 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that:
    //  - 'startIndex + len <= self.length'
    // The length of the substring is: 'len'
    function substr(bytes memory self, uint256 startIndex, uint256 len) internal pure returns (bytes memory) {
        require(startIndex + len <= self.length);
        if (len == 0) {
            return "";
        }
        uint256 addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIndex, len);
    }

    // Combines 'self' and 'other' into a single array.
    // Returns the concatenated arrays:
    //  [self[0], self[1], ... , self[self.length - 1], other[0], other[1], ... , other[other.length - 1]]
    // The length of the new array is 'self.length + other.length'
    function concat(bytes memory self, bytes memory other) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(self.length + other.length);
        uint256 src;
        uint256 srcLen;
        (src, srcLen) = Memory.fromBytes(self);
        uint256 src2;
        uint256 src2Len;
        (src2, src2Len) = Memory.fromBytes(other);
        uint256 dest;
        (dest,) = Memory.fromBytes(ret);
        uint256 dest2 = dest + srcLen;
        Memory.copy(src, dest, srcLen);
        Memory.copy(src2, dest2, src2Len);
        return ret;
    }

    function toBytes32(bytes memory self) internal pure returns (bytes32 out) {
        require(self.length >= 32, "Bytes:: toBytes32: data is to short.");
        assembly {
            out := mload(add(self, 32))
        }
    }

    function toBytes16(bytes memory self, uint256 offset) internal pure returns (bytes16 out) {
        for (uint256 i = 0; i < 16; i++) {
            out |= bytes16(bytes1(self[offset + i]) & 0xFF) >> (i * 8);
        }
    }

    function toBytes8(bytes memory self, uint256 offset) internal pure returns (bytes8 out) {
        for (uint256 i = 0; i < 8; i++) {
            out |= bytes8(bytes1(self[offset + i]) & 0xFF) >> (i * 8);
        }
    }

    function toBytes4(bytes memory self, uint256 offset) internal pure returns (bytes4) {
        bytes4 out;

        for (uint256 i = 0; i < 4; i++) {
            out |= bytes4(self[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function toBytes2(bytes memory self, uint256 offset) internal pure returns (bytes2) {
        bytes2 out;

        for (uint256 i = 0; i < 2; i++) {
            out |= bytes2(self[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function removeLeadingZero(bytes memory data) internal pure returns (bytes memory) {
        uint256 length = data.length;

        uint256 startIndex = 0;
        for (uint256 i = 0; i < length; i++) {
            if (data[i] != 0) {
                startIndex = i;
                break;
            }
        }

        return substr(data, startIndex);
    }

    function removeEndingZero(bytes memory data) internal pure returns (bytes memory) {
        uint256 length = data.length;

        uint256 endIndex = 0;
        for (uint256 i = length - 1; i >= 0; i--) {
            if (data[i] != 0) {
                endIndex = i;
                break;
            }
        }

        return substr(data, 0, endIndex + 1);
    }

    function reverse(bytes memory inbytes) internal pure returns (bytes memory) {
        uint256 inlength = inbytes.length;
        bytes memory outbytes = new bytes(inlength);

        for (uint256 i = 0; i <= inlength - 1; i++) {
            outbytes[i] = inbytes[inlength - i - 1];
        }

        return outbytes;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

struct DigestItem {
    bytes4 consensusId;
    bytes data;
}

struct Digest {
    bool isPreRuntime;
    DigestItem preruntime;
    bool isConsensus;
    DigestItem consensus;
    bool isSeal;
    DigestItem seal;
    bool isOther;
    bytes other;
    bool isRuntimeEnvironmentUpdated;
}

struct Header {
    bytes32 parentHash;
    uint256 number;
    bytes32 stateRoot;
    bytes32 extrinsicRoot;
    Digest[] digests;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache2

import "./NibbleSlice.sol";
import "./Bytes.sol";

/// This is an enum for the different node types.
struct NodeKind {
    bool isEmpty;
    bool isLeaf;
    bool isHashedLeaf;
    bool isNibbledValueBranch;
    bool isNibbledHashedValueBranch;
    bool isNibbledBranch;
    bool isExtension;
    bool isBranch;
    uint256 nibbleSize;
    ByteSlice data;
}

struct NodeHandle {
    bool isHash;
    bytes32 hash;
    bool isInline;
    bytes inLine;
}

struct Extension {
    NibbleSlice key;
    NodeHandle node;
}

struct Branch {
    NodeHandleOption value;
    NodeHandleOption[16] children;
}

struct NibbledBranch {
    NibbleSlice key;
    NodeHandleOption value;
    NodeHandleOption[16] children;
}

struct ValueOption {
    bool isSome;
    bytes value;
}

struct NodeHandleOption {
    bool isSome;
    NodeHandle value;
}

struct Leaf {
    NibbleSlice key;
    NodeHandle value;
}

struct TrieNode {
    bytes32 hash;
    bytes node;
}

pragma solidity ^0.8.17;

import "./Node.sol";

// SPDX-License-Identifier: Apache2

library Option {
    function isSome(ValueOption memory val) internal pure returns (bool) {
        return val.isSome == true;
    }

    function isSome(NodeHandleOption memory val) internal pure returns (bool) {
        return val.isSome == true;
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache2

struct NibbleSlice {
    bytes data;
    uint256 offset;
}

library NibbleSliceOps {
    uint256 internal constant NIBBLE_PER_BYTE = 2;
    uint256 internal constant BITS_PER_NIBBLE = 4;

    function len(NibbleSlice memory nibble) internal pure returns (uint256) {
        return nibble.data.length * NIBBLE_PER_BYTE - nibble.offset;
    }

    function mid(NibbleSlice memory self, uint256 i) internal pure returns (NibbleSlice memory) {
        return NibbleSlice(self.data, self.offset + i);
    }

    function isEmpty(NibbleSlice memory self) internal pure returns (bool) {
        return len(self) == 0;
    }

    function eq(NibbleSlice memory self, NibbleSlice memory other) internal pure returns (bool) {
        return len(self) == len(other) && startsWith(self, other);
    }

    function at(NibbleSlice memory self, uint256 i) internal pure returns (uint256) {
        uint256 ix = (self.offset + i) / NIBBLE_PER_BYTE;
        uint256 pad = (self.offset + i) % NIBBLE_PER_BYTE;
        uint8 data = uint8(self.data[ix]);
        return (pad == 1) ? data & 0x0F : data >> BITS_PER_NIBBLE;
    }

    function startsWith(NibbleSlice memory self, NibbleSlice memory other) internal pure returns (bool) {
        return commonPrefix(self, other) == len(other);
    }

    function commonPrefix(NibbleSlice memory self, NibbleSlice memory other) internal pure returns (uint256) {
        uint256 self_align = self.offset % NIBBLE_PER_BYTE;
        uint256 other_align = other.offset % NIBBLE_PER_BYTE;

        if (self_align == other_align) {
            uint256 self_start = self.offset / NIBBLE_PER_BYTE;
            uint256 other_start = other.offset / NIBBLE_PER_BYTE;
            uint256 first = 0;

            if (self_align != 0) {
                if ((self.data[self_start] & 0x0F) != (other.data[other_start] & 0x0F)) {
                    return 0;
                }
                ++self_start;
                ++other_start;
                ++first;
            }
            bytes memory selfSlice = bytesSlice(self.data, self_start);
            bytes memory otherSlice = bytesSlice(other.data, other_start);
            return biggestDepth(selfSlice, otherSlice) + first;
        } else {
            uint256 s = min(len(self), len(other));
            uint256 i = 0;
            while (i < s) {
                if (at(self, i) != at(other, i)) {
                    break;
                }
                ++i;
            }
            return i;
        }
    }

    function biggestDepth(bytes memory a, bytes memory b) internal pure returns (uint256) {
        uint256 upperBound = min(a.length, b.length);
        uint256 i = 0;
        while (i < upperBound) {
            if (a[i] != b[i]) {
                return i * NIBBLE_PER_BYTE + leftCommon(a[i], b[i]);
            }
            ++i;
        }
        return i * NIBBLE_PER_BYTE;
    }

    function leftCommon(bytes1 a, bytes1 b) internal pure returns (uint256) {
        if (a == b) {
            return 2;
        } else if (uint8(a) & 0xF0 == uint8(b) & 0xF0) {
            return 1;
        } else {
            return 0;
        }
    }

    function bytesSlice(bytes memory _bytes, uint256 _start) internal pure returns (bytes memory) {
        uint256 bytesLength = _bytes.length;
        uint256 _length = bytesLength - _start;
        require(bytesLength >= _start, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40) // load free memory pointer
                let lengthmod := and(_length, 31)

                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for { let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start) } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }
        return tempBytes;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a < b) ? a : b;
    }
}

// SPDX-License-Identifier: Apache2
pragma solidity ^0.8.17;

import "./Node.sol";

library TrieDB {
    function get(TrieNode[] memory nodes, bytes32 hash) internal pure returns (bytes memory) {
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i].hash == hash) {
                return nodes[i].node;
            }
        }
        revert("Incomplete Proof!");
    }

    function load(TrieNode[] memory nodes, NodeHandle memory node) internal pure returns (bytes memory) {
        if (node.isInline) {
            return node.inLine;
        } else if (node.isHash) {
            return get(nodes, node.hash);
        }

        return bytes("");
    }

    function isNibbledBranch(NodeKind memory node) internal pure returns (bool) {
        return (node.isNibbledBranch || node.isNibbledHashedValueBranch || node.isNibbledValueBranch);
    }

    function isExtension(NodeKind memory node) internal pure returns (bool) {
        return node.isExtension;
    }

    function isBranch(NodeKind memory node) internal pure returns (bool) {
        return node.isBranch;
    }

    function isLeaf(NodeKind memory node) internal pure returns (bool) {
        return (node.isLeaf || node.isHashedLeaf);
    }

    function isEmpty(NodeKind memory node) internal pure returns (bool) {
        return node.isEmpty;
    }

    function isHash(NodeHandle memory node) internal pure returns (bool) {
        return node.isHash;
    }

    function isInline(NodeHandle memory node) internal pure returns (bool) {
        return node.isInline;
    }
}

pragma solidity ^0.8.17;

import "../Node.sol";
import "../Bytes.sol";
import {NibbleSliceOps} from "../NibbleSlice.sol";

import {ScaleCodec} from "./ScaleCodec.sol";
import "openzeppelin/utils/Strings.sol";

// SPDX-License-Identifier: Apache2

library SubstrateTrieDB {
    uint8 public constant FIRST_PREFIX = 0x00 << 6;
    uint8 public constant PADDING_BITMASK = 0x0F;
    uint8 public constant EMPTY_TRIE = FIRST_PREFIX | (0x00 << 4);
    uint8 public constant LEAF_PREFIX_MASK = 0x01 << 6;
    uint8 public constant BRANCH_WITH_MASK = 0x03 << 6;
    uint8 public constant BRANCH_WITHOUT_MASK = 0x02 << 6;
    uint8 public constant ALT_HASHING_LEAF_PREFIX_MASK = FIRST_PREFIX | (0x01 << 5);
    uint8 public constant ALT_HASHING_BRANCH_WITH_MASK = FIRST_PREFIX | (0x01 << 4);
    uint8 public constant NIBBLE_PER_BYTE = 2;
    uint256 public constant NIBBLE_SIZE_BOUND = uint256(type(uint16).max);
    uint256 public constant BITMAP_LENGTH = 2;
    uint256 public constant HASH_lENGTH = 32;

    function decodeNodeKind(bytes memory encoded) internal pure returns (NodeKind memory) {
        NodeKind memory node;
        ByteSlice memory input = ByteSlice(encoded, 0);
        uint8 i = Bytes.readByte(input);

        if (i == EMPTY_TRIE) {
            node.isEmpty = true;
            return node;
        }

        uint8 mask = i & (0x03 << 6);

        if (mask == LEAF_PREFIX_MASK) {
            node.nibbleSize = decodeSize(i, input, 2);
            node.isLeaf = true;
        } else if (mask == BRANCH_WITH_MASK) {
            node.nibbleSize = decodeSize(i, input, 2);
            node.isNibbledValueBranch = true;
        } else if (mask == BRANCH_WITHOUT_MASK) {
            node.nibbleSize = decodeSize(i, input, 2);
            node.isNibbledBranch = true;
        } else if (mask == EMPTY_TRIE) {
            if (i & (0x07 << 5) == ALT_HASHING_LEAF_PREFIX_MASK) {
                node.nibbleSize = decodeSize(i, input, 3);
                node.isHashedLeaf = true;
            } else if (i & (0x0F << 4) == ALT_HASHING_BRANCH_WITH_MASK) {
                node.nibbleSize = decodeSize(i, input, 4);
                node.isNibbledHashedValueBranch = true;
            } else {
                // do not allow any special encoding
                revert("Unallowed encoding");
            }
        }
        node.data = input;

        return node;
    }

    function decodeNibbledBranch(NodeKind memory node) internal pure returns (NibbledBranch memory) {
        NibbledBranch memory nibbledBranch;
        ByteSlice memory input = node.data;

        bool padding = node.nibbleSize % NIBBLE_PER_BYTE != 0;
        if (padding && (padLeft(uint8(input.data[input.offset])) != 0)) {
            revert("Bad Format!");
        }
        uint256 nibbleLen = ((node.nibbleSize + (NibbleSliceOps.NIBBLE_PER_BYTE - 1)) / NibbleSliceOps.NIBBLE_PER_BYTE);
        nibbledBranch.key = NibbleSlice(Bytes.read(input, nibbleLen), node.nibbleSize % NIBBLE_PER_BYTE);

        bytes memory bitmapBytes = Bytes.read(input, BITMAP_LENGTH);
        uint16 bitmap = uint16(ScaleCodec.decodeUint256(bitmapBytes));

        NodeHandleOption memory valueHandle;
        if (node.isNibbledHashedValueBranch) {
            valueHandle.isSome = true;
            valueHandle.value.isHash = true;
            valueHandle.value.hash = Bytes.toBytes32(Bytes.read(input, HASH_lENGTH));
        } else if (node.isNibbledValueBranch) {
            uint256 len = ScaleCodec.decodeUintCompact(input);
            valueHandle.isSome = true;
            valueHandle.value.isInline = true;
            valueHandle.value.inLine = Bytes.read(input, len);
        }
        nibbledBranch.value = valueHandle;

        for (uint256 i = 0; i < 16; i++) {
            NodeHandleOption memory childHandle;
            if (valueAt(bitmap, i)) {
                childHandle.isSome = true;
                uint256 len = ScaleCodec.decodeUintCompact(input);
                //                revert(string.concat("node index: ", Strings.toString(len)));
                if (len == HASH_lENGTH) {
                    childHandle.value.isHash = true;
                    childHandle.value.hash = Bytes.toBytes32(Bytes.read(input, HASH_lENGTH));
                } else {
                    childHandle.value.isInline = true;
                    childHandle.value.inLine = Bytes.read(input, len);
                }
            }
            nibbledBranch.children[i] = childHandle;
        }

        return nibbledBranch;
    }

    function decodeLeaf(NodeKind memory node) internal pure returns (Leaf memory) {
        Leaf memory leaf;
        ByteSlice memory input = node.data;

        bool padding = node.nibbleSize % NIBBLE_PER_BYTE != 0;
        if (padding && padLeft(uint8(input.data[input.offset])) != 0) {
            revert("Bad Format!");
        }
        uint256 nibbleLen = (node.nibbleSize + (NibbleSliceOps.NIBBLE_PER_BYTE - 1)) / NibbleSliceOps.NIBBLE_PER_BYTE;
        bytes memory nibbleBytes = Bytes.read(input, nibbleLen);
        leaf.key = NibbleSlice(nibbleBytes, node.nibbleSize % NIBBLE_PER_BYTE);

        NodeHandle memory handle;
        if (node.isHashedLeaf) {
            handle.isHash = true;
            handle.hash = Bytes.toBytes32(Bytes.read(input, HASH_lENGTH));
        } else {
            uint256 len = ScaleCodec.decodeUintCompact(input);
            handle.isInline = true;
            handle.inLine = Bytes.read(input, len);
        }
        leaf.value = handle;

        return leaf;
    }

    function decodeSize(uint8 first, ByteSlice memory encoded, uint8 prefixMask) internal pure returns (uint256) {
        uint8 maxValue = uint8(255 >> prefixMask);
        uint256 result = uint256(first & maxValue);

        if (result < maxValue) {
            return result;
        }

        result -= 1;

        while (result <= NIBBLE_SIZE_BOUND) {
            uint256 n = uint256(Bytes.readByte(encoded));
            if (n < 255) {
                return result + n + 1;
            }
            result += 255;
        }

        return NIBBLE_SIZE_BOUND;
    }

    function padLeft(uint8 b) internal pure returns (uint8) {
        return b & ~PADDING_BITMASK;
    }

    function valueAt(uint16 bitmap, uint256 i) internal pure returns (bool) {
        return bitmap & (uint16(1) << uint16(i)) != 0;
    }
}

pragma solidity ^0.8.17;

import "../Node.sol";
import "../Bytes.sol";
import {NibbleSliceOps} from "../NibbleSlice.sol";
import "./RLPReader.sol";

// SPDX-License-Identifier: Apache2

library EthereumTrieDB {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;

    bytes constant HASHED_NULL_NODE = hex"56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421";

    function decodeNodeKind(bytes memory encoded) external pure returns (NodeKind memory) {
        NodeKind memory node;
        ByteSlice memory input = ByteSlice(encoded, 0);
        if (Bytes.equals(encoded, HASHED_NULL_NODE)) {
            node.isEmpty = true;
            return node;
        }
        RLPReader.RLPItem[] memory itemList = encoded.toRlpItem().toList();
        uint256 numItems = itemList.length;
        if (numItems == 0) {
            node.isEmpty = true;
            return node;
        } else if (numItems == 2) {
            //It may be a leaf or extension
            bytes memory key = itemList[0].toBytes();
            uint256 prefix;
            assembly {
                let first := shr(248, mload(add(key, 32)))
                prefix := shr(4, first)
            }
            if (prefix == 2 || prefix == 3) {
                node.isLeaf = true;
            } else {
                node.isExtension = true;
            }
        } else if (numItems == 17) {
            node.isBranch = true;
        } else {
            revert("Invalid data");
        }
        node.data = input;
        return node;
    }

    function decodeLeaf(NodeKind memory node) external pure returns (Leaf memory) {
        Leaf memory leaf;
        RLPReader.RLPItem[] memory decoded = node.data.data.toRlpItem().toList();
        bytes memory data = decoded[1].toBytes();
        //Remove the first byte, which is the prefix and not present in the user provided key
        leaf.key = NibbleSlice(Bytes.substr(decoded[0].toBytes(), 1), 0);
        leaf.value = NodeHandle(false, bytes32(0), true, data);

        return leaf;
    }

    function decodeExtension(NodeKind memory node) external pure returns (Extension memory) {
        Extension memory extension;
        RLPReader.RLPItem[] memory decoded = node.data.data.toRlpItem().toList();
        bytes memory data = decoded[1].toBytes();
        //Remove the first byte, which is the prefix and not present in the user provided key
        extension.key = NibbleSlice(Bytes.substr(decoded[0].toBytes(), 1), 0);
        extension.node = NodeHandle(true, Bytes.toBytes32(data), false, new bytes(0));
        return extension;
    }

    function decodeBranch(NodeKind memory node) external pure returns (Branch memory) {
        Branch memory branch;
        RLPReader.RLPItem[] memory decoded = node.data.data.toRlpItem().toList();

        NodeHandleOption[16] memory childrens;

        for (uint256 i = 0; i < 16; i++) {
            bytes memory dataAsBytes = decoded[i].toBytes();
            if (dataAsBytes.length != 32) {
                childrens[i] = NodeHandleOption(false, NodeHandle(false, bytes32(0), false, new bytes(0)));
            } else {
                bytes32 data = Bytes.toBytes32(dataAsBytes);
                childrens[i] = NodeHandleOption(true, NodeHandle(true, data, false, new bytes(0)));
            }
        }
        if (isEmpty(decoded[16].toBytes())) {
            branch.value = NodeHandleOption(false, NodeHandle(false, bytes32(0), false, new bytes(0)));
        } else {
            branch.value = NodeHandleOption(true, NodeHandle(false, bytes32(0), true, decoded[16].toBytes()));
        }
        branch.children = childrens;

        return branch;
    }

    function isEmpty(bytes memory item) internal pure returns (bool) {
        return item.length > 0 && (item[0] == 0xc0 || item[0] == 0x80);
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache2

library Memory {
    uint256 internal constant WORD_SIZE = 32;

    // Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(uint256 addr, uint256 addr2, uint256 len) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'

    function equals(uint256 addr, uint256 len, bytes memory bts) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint256 addr2;
        assembly {
            addr2 := add(bts, /*BYTES_HEADER_SIZE*/ 32)
        }
        return equals(addr, addr2, len);
    }
    // Returns a memory pointer to the data portion of the provided bytes array.

    function dataPtr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/ 32)
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint256 addr, uint256 len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint256 btsptr;
        assembly {
            btsptr := add(bts, /*BYTES_HEADER_SIZE*/ 32)
        }
        copy(addr, btsptr, len);
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'
    // The returned bytes will be of length '32'.
    function toBytes(bytes32 self) internal pure returns (bytes memory bts) {
        bts = new bytes(32);
        assembly {
            mstore(add(bts, /*BYTES_HEADER_SIZE*/ 32), self)
        }
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(uint256 src, uint256 dest, uint256 len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        // Copy remaining bytes
        uint256 mask =
            len == 0 ? 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff : 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts) internal pure returns (uint256 addr, uint256 len) {
        len = bts.length;
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/ 32)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity >=0.5.10 <0.9.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param the RLP item.
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @param the RLP item.
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        (, uint256 len) = payloadLocation(item);
        return len;
    }

    /*
     * @param the RLP item containing the encoded list.
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /**
     * RLPItem conversions into data types *
     */

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        (uint256 memPtr, uint256 len) = payloadLocation(item);

        uint256 result;
        assembly {
            result := mload(memPtr)

            // shift to the correct location if neccesary
            if lt(len, 32) { result := div(result, exp(256, sub(32, len))) }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            itemLen = 1;
        } else if (byte0 < STRING_LONG_START) {
            itemLen = byte0 - STRING_SHORT_START + 1;
        } else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            return 0;
        } else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) {
            return 1;
        } else if (byte0 < LIST_SHORT_START) {
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        } else {
            return byte0 - (LIST_LONG_START - 1) + 1;
        }
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(uint256 src, uint256 dest, uint256 len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint256 mask = 256 ** (WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}