pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IMerkelRoot} from "./ArbitrumKeyStoreModule/ArbMerkleRootHistory.sol";

contract KeystoreProofMerkelTree {
    mapping(bytes32 => address) public l1SlotToSigningKey;
    mapping(bytes32 => uint256) public lastProofBlock;
    mapping(uint256 => bytes32) public l1BlockToStateRoot;

    address public immutable MERKLE_ROOT_HISTORY;

    event KeyStoreStorageProved(bytes32 stateRoot, bytes32 storageRoot);
    event L1KeyStoreProved(bytes32 l1Slot, address signingKey);

    constructor(address _merkelRootHistory) {
        MERKLE_ROOT_HISTORY = _merkelRootHistory;
    }

    function proofL1Keystore(
        bytes32 stateRoot,
        bytes32 l1Slot,
        bytes32 newSigningKey,
        uint256 blockNumber,
        uint256 index,
        bytes32[] memory proof
    ) external {
        bytes32 leaf = sha256(abi.encodePacked(l1Slot, newSigningKey, blockNumber));
        require(IMerkelRoot(MERKLE_ROOT_HISTORY).isKnownRoot(stateRoot), "unkown state root");
        uint256 lastProofBlockNumber = lastProofBlock[l1Slot];
        require(blockNumber > lastProofBlockNumber, "needs to proof newer block");
        require(verify(proof, stateRoot, leaf, index), "Invalid proof");
        address newSigner;
        assembly ("memory-safe") {
            newSigner := newSigningKey
        }
        l1SlotToSigningKey[l1Slot] = newSigner;
        lastProofBlock[l1Slot] = blockNumber;
        emit L1KeyStoreProved(l1Slot, newSigner);
    }

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf, uint256 index) public pure returns (bool) {
        bytes32 hash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if ((index & 1) == 1) {
                hash = sha256(abi.encodePacked(proofElement, hash));
            } else {
                hash = sha256(abi.encodePacked(hash, proofElement));
            }

            index = index / 2;
        }
        return hash == root;
    }

    function keystoreBySlot(bytes32 l1Slot) external view returns (address signingKey) {
        return (l1SlotToSigningKey[l1Slot]);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

pragma solidity ^0.8.17;

import "../KnownStateRootWithHistoryBase.sol";
import "@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMerkelRoot {
    function isKnownRoot(bytes32 _root) external view returns (bool);
}

contract ArbMerkleRootHistory is Ownable, IMerkelRoot {
    address public l1Target;
    mapping(uint256 => bytes32) public merkelRoots;
    uint32 public constant ROOT_HISTORY_SIZE = 30;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;

    constructor(address _l1Target, address _owner) {
        l1Target = _l1Target;
        transferOwnership(_owner);
    }

    function updateL1Target(address _l1Target) public onlyOwner {
        l1Target = _l1Target;
    }

    function setMerkelRoot(bytes32 l1MerkelRoot) external {
        uint32 _nextIndex = nextIndex;
        // To check that message came from L1, we check that the sender is the L1 contract's L2 alias.
        require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1Target), "blockhash only updateable by L1Target");
        require(l1MerkelRoot != bytes32(0), "l1 block hash is 0");

        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        merkelRoots[newRootIndex] = l1MerkelRoot;
        nextIndex = _nextIndex + 1;
    }

    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (_root == 0) {
            return false;
        }
        uint32 _currentRootIndex = currentRootIndex;
        uint32 i = _currentRootIndex;
        do {
            if (_root == merkelRoots[i]) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != _currentRootIndex);
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./IKnownStateRootWithHistory.sol";
import "./BlockVerifier.sol";

abstract contract KnownStateRootWithHistoryBase is IKnownStateRootWithHistory {
    uint256 public constant ROOT_HISTORY_SIZE = 100;
    uint256 public currentRootIndex = 0;

    mapping(uint256 => BlockInfo) public stateRoots;
    mapping(uint256 => bytes32) public blockHashs;

    event L1BlockSyncd(uint256 indexed blockNumber, bytes32 blockHash);
    event NewStateRoot(bytes32 indexed stateRoot, uint256 indexed blockNumber, address user);

    function isKnownStateRoot(bytes32 _stateRoot) public view override returns (bool) {
        if (_stateRoot == 0) {
            return false;
        }
        uint256 _currentRootIndex = currentRootIndex;
        uint256 i = _currentRootIndex;

        do {
            BlockInfo memory blockinfo = stateRoots[i];
            if (_stateRoot == blockinfo.storageRootHash) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != _currentRootIndex);
        return false;
    }

    function insertNewStateRoot(uint256 _blockNumber, bytes memory _blockInfo) external {
        bytes32 _blockHash = blockHashs[_blockNumber];
        require(_blockHash != bytes32(0), "blockhash not set");
        (bytes32 stateRoot, uint256 blockTimestamp, uint256 blockNumber) =
            BlockVerifier.extractStateRootAndTimestamp(_blockInfo, _blockHash);

        require(!isKnownStateRoot(stateRoot), "duplicate state root");

        BlockInfo memory currentBlockInfo = stateRoots[currentRootIndex];
        require(blockNumber > currentBlockInfo.blockNumber, "blockNumber too old");

        uint256 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;

        stateRoots[newRootIndex].blockHash = _blockHash;
        stateRoots[newRootIndex].storageRootHash = stateRoot;
        stateRoots[newRootIndex].blockNumber = blockNumber;
        stateRoots[newRootIndex].blockTimestamp = blockTimestamp;
        emit NewStateRoot(stateRoot, blockNumber, msg.sender);
    }

    function stateRootInfo(bytes32 _stateRoot) external view override returns (bool result, BlockInfo memory info) {
        if (_stateRoot == 0) {
            return (false, info);
        }
        uint256 _currentRootIndex = currentRootIndex;
        uint256 i = _currentRootIndex;

        do {
            BlockInfo memory blockinfo = stateRoots[i];
            if (_stateRoot == blockinfo.storageRootHash) {
                return (true, blockinfo);
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != _currentRootIndex);
        return (false, info);
    }

    function lastestStateRootInfo() external view returns (BlockInfo memory info) {
        return stateRoots[currentRootIndex];
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );

    error InvalidBlockNumber(uint256 requested, uint256 current);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

struct BlockInfo {
    bytes32 storageRootHash;
    bytes32 blockHash;
    uint256 blockNumber;
    uint256 blockTimestamp;
}

interface IKnownStateRootWithHistory {
    function isKnownStateRoot(bytes32 _stateRoot) external returns (bool);
    function stateRootInfo(bytes32 _stateRoot) external view returns (bool result, BlockInfo memory info);
}

// SPDX-License-Identifier: GPL-3.0
/*
This code is based on https://github.com/Keydonix/uniswap-oracle/blob/master/contracts/source/BlockVerifier.sol
Credit to the original authors and contributors.
*/

pragma solidity ^0.8.17;

library BlockVerifier {
    function extractStateRootAndTimestamp(bytes memory rlpBytes, bytes32 blockHash)
        internal
        pure
        returns (bytes32 stateRoot, uint256 blockTimestamp, uint256 blockNumber)
    {
        assembly {
            function revertWithReason(message, length) {
                // 4-byte function selector of `Error(string)` which is `0x08c379a0`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                // Offset of string return value
                mstore(4, 0x20)
                // Length of string return value (the revert reason)
                mstore(0x24, length)
                // actuall revert message
                mstore(0x44, message)
                revert(0, add(0x44, length))
            }

            function readDynamic(prefixPointer) -> dataPointer, dataLength {
                let value := byte(0, mload(prefixPointer))
                switch lt(value, 0x80)
                case 1 {
                    dataPointer := prefixPointer
                    dataLength := 1
                }
                case 0 {
                    dataPointer := add(prefixPointer, 1)
                    dataLength := sub(value, 0x80)
                }
            }

            // get the length of the data
            let rlpLength := mload(rlpBytes)
            // move pointer forward, ahead of length
            rlpBytes := add(rlpBytes, 0x20)

            // we know the length of the block will be between 483 bytes and 709 bytes, which means it will have 2 length bytes after the prefix byte, so we can skip 3 bytes in
            // CONSIDER: we could save a trivial amount of gas by compressing most of this into a single add instruction
            let parentHashPrefixPointer := add(rlpBytes, 3)
            let parentHashPointer := add(parentHashPrefixPointer, 1)
            let uncleHashPrefixPointer := add(parentHashPointer, 32)
            let uncleHashPointer := add(uncleHashPrefixPointer, 1)
            let minerAddressPrefixPointer := add(uncleHashPointer, 32)
            let minerAddressPointer := add(minerAddressPrefixPointer, 1)
            let stateRootPrefixPointer := add(minerAddressPointer, 20)
            let stateRootPointer := add(stateRootPrefixPointer, 1)
            let transactionRootPrefixPointer := add(stateRootPointer, 32)
            let transactionRootPointer := add(transactionRootPrefixPointer, 1)
            let receiptsRootPrefixPointer := add(transactionRootPointer, 32)
            let receiptsRootPointer := add(receiptsRootPrefixPointer, 1)
            let logsBloomPrefixPointer := add(receiptsRootPointer, 32)
            let logsBloomPointer := add(logsBloomPrefixPointer, 3)
            let difficultyPrefixPointer := add(logsBloomPointer, 256)
            let difficultyPointer, difficultyLength := readDynamic(difficultyPrefixPointer)
            let blockNumberPrefixPointer := add(difficultyPointer, difficultyLength)
            let blockNumberPointer, blockNumberLength := readDynamic(blockNumberPrefixPointer)
            let gasLimitPrefixPointer := add(blockNumberPointer, blockNumberLength)
            let gasLimitPointer, gasLimitLength := readDynamic(gasLimitPrefixPointer)
            let gasUsedPrefixPointer := add(gasLimitPointer, gasLimitLength)
            let gasUsedPointer, gasUsedLength := readDynamic(gasUsedPrefixPointer)
            let timestampPrefixPointer := add(gasUsedPointer, gasUsedLength)
            let timestampPointer, timestampLength := readDynamic(timestampPrefixPointer)

            blockNumber := shr(sub(256, mul(blockNumberLength, 8)), mload(blockNumberPointer))
            let rlpHash := keccak256(rlpBytes, rlpLength)
            if iszero(eq(blockHash, rlpHash)) { revertWithReason("blockHash != rlpHash", 20) }

            stateRoot := mload(stateRootPointer)
            blockTimestamp := shr(sub(256, mul(timestampLength, 8)), mload(timestampPointer))
        }
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