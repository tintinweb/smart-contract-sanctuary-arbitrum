// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../verifiers/zk-verifiers/common/IVerifier.sol";

interface ISMT {
    struct SmtUpdate {
        bytes32 newSmtRoot;
        uint64 endBlockNum;
        bytes32 endBlockHash;
        bytes32 nextChunkMerkleRoot;
        IVerifier.Proof proof;
        bytes32 commitPub;
    }

    function updateRoot(uint64 chainId, SmtUpdate memory u) external;

    function isSmtRootValid(uint64 chainId, bytes32 smtRoot) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/Lib.sol";
import "../../interfaces/ISMT.sol";
import "../../verifiers/interfaces/IZkpVerifier.sol";

contract BrevisAggProof is Ownable {
    ISMT public smtContract;

    constructor(ISMT _smtContract) {
        smtContract = _smtContract;
    }

    mapping(bytes32 => bool) public merkleRoots;
    mapping(bytes32 => bool) public requestIds;
    mapping(uint64 => IZkpVerifier) public aggProofVerifierAddress;
    event SmtContractUpdated(ISMT smtContract);
    event AggProofVerifierAddressesUpdated(uint64[] chainIds, IZkpVerifier[] newAddresses);

    uint32 constant PUBLIC_BYTES_START_IDX = 12 * 32; // the first 12 32bytes are groth16 proof (A/B/C/Commitment/CommitmentPOK)
    uint8 constant TREE_DEPTH = 4;
    uint256 constant LEAF_NODES_LEN = 2 ** TREE_DEPTH;

    function mustValidateRequest(
        uint64 _chainId,
        Brevis.ProofData calldata _proofData,
        bytes32 _merkleRoot,
        bytes32[] calldata _merkleProof,
        uint8 _nodeIndex
    ) external view {
        require(merkleRoots[_merkleRoot], "merkle root not exists");
        require(smtContract.isSmtRootValid(_chainId, _proofData.smtRoot), "invalid smt root");

        bytes32 proofDataHash = keccak256(
            abi.encodePacked(
                _proofData.commitHash,
                _proofData.smtRoot,
                _proofData.vkHash,
                _proofData.appCommitHash,
                _proofData.appVkHash
            )
        );
        bytes32 root = proofDataHash;
        for (uint8 depth = 0; depth < TREE_DEPTH; depth++) {
            if ((_nodeIndex >> depth) & 1 == 0) {
                root = keccak256(abi.encodePacked(root, _merkleProof[depth]));
            } else {
                root = keccak256(abi.encodePacked(_merkleProof[depth], root));
            }
        }
        require(_merkleRoot == root, "invalid data");
    }

    function mustValidateRequests(uint64 _chainId, Brevis.ProofData[] calldata _proofDataArray) external view {
        uint dataLen = _proofDataArray.length;
        require(dataLen <= LEAF_NODES_LEN, "size exceeds");
        bytes32[2 * LEAF_NODES_LEN - 1] memory hashes;
        for (uint i = 0; i < dataLen; i++) {
            require(smtContract.isSmtRootValid(_chainId, _proofDataArray[i].smtRoot), "invalid smt root");
            hashes[i] = keccak256(
                abi.encodePacked(
                    _proofDataArray[i].commitHash,
                    _proofDataArray[i].smtRoot,
                    _proofDataArray[i].vkHash,
                    _proofDataArray[i].appCommitHash,
                    _proofDataArray[i].appVkHash
                )
            );
        }
        // note, hashes[dataLen] to hashes[LEAF_NODES_LEN - 1] filled with last real one
        if (dataLen < LEAF_NODES_LEN) {
            for (uint i = dataLen; i < LEAF_NODES_LEN; i++) {
                hashes[i] = hashes[dataLen - 1];
            }
        }

        uint shift = 0;
        uint counter = LEAF_NODES_LEN;
        while (counter > 0) {
            for (uint i = 0; i < counter - 1; i += 2) {
                hashes[shift + counter + i / 2] = keccak256(abi.encodePacked(hashes[shift + i], hashes[shift + i + 1]));
            }
            shift += counter;
            counter /= 2;
        }

        require(merkleRoots[hashes[hashes.length - 1]], "merkle root not exists");
    }

    function mustSubmitAggProof(
        uint64 _chainId,
        bytes32[] calldata _requestIds,
        bytes calldata _proofWithPubInputs
    ) external {
        IZkpVerifier verifier = aggProofVerifierAddress[_chainId];
        require(address(verifier) != address(0), "chain agg proof verifier not set");
        require(verifier.verifyRaw(_proofWithPubInputs), "proof not valid");

        (bytes32 root, bytes32 commitHash) = unpack(_proofWithPubInputs);

        uint dataLen = _requestIds.length;
        bytes32[LEAF_NODES_LEN] memory rIds;
        for (uint i = 0; i < dataLen; i++) {
            rIds[i] = _requestIds[i];
        }
        // note, to align with circuit, rIds[dataLen] to rIds[LEAF_NODES_LEN - 1] filled with last real one
        if (dataLen < LEAF_NODES_LEN) {
            for (uint i = dataLen; i < LEAF_NODES_LEN; i++) {
                rIds[i] = rIds[dataLen - 1];
            }
        }
        require(keccak256(abi.encodePacked(rIds)) == commitHash, "requestIds not right");
        merkleRoots[root] = true;
        for (uint i = 0; i < _requestIds.length; i++) {
            requestIds[_requestIds[i]] = true;
        }
    }

    function inAgg(bytes32 _requestId) public view returns (bool) {
        return requestIds[_requestId];
    }

    function unpack(bytes calldata _proofWithPubInputs) internal pure returns (bytes32 merkleRoot, bytes32 commitHash) {
        merkleRoot = bytes32(_proofWithPubInputs[PUBLIC_BYTES_START_IDX:PUBLIC_BYTES_START_IDX + 32]);
        commitHash = bytes32(_proofWithPubInputs[PUBLIC_BYTES_START_IDX + 32:PUBLIC_BYTES_START_IDX + 2 * 32]);
    }

    function updateSmtContract(ISMT _smtContract) public onlyOwner {
        smtContract = _smtContract;
        emit SmtContractUpdated(smtContract);
    }

    function updateAggProofVerifierAddresses(
        uint64[] calldata _chainIds,
        IZkpVerifier[] calldata _verifierAddresses
    ) public onlyOwner {
        require(_chainIds.length == _verifierAddresses.length, "length not match");
        for (uint256 i = 0; i < _chainIds.length; i++) {
            aggProofVerifierAddress[_chainIds[i]] = _verifierAddresses[i];
        }
        emit AggProofVerifierAddressesUpdated(_chainIds, _verifierAddresses);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BrevisAggProof.sol";
import "../lib/Lib.sol";
import "../../interfaces/ISMT.sol";
import "../../verifiers/interfaces/IZkpVerifier.sol";

contract BrevisProof is BrevisAggProof {
    struct ChainZKVerifier {
        IZkpVerifier contractAppZkVerifier;
        IZkpVerifier circuitAppZkVerifier;
    }
    mapping(uint64 => ChainZKVerifier) public verifierAddresses; // chainid => snark verifier contract address

    mapping(bytes32 => Brevis.ProofData) public proofs; // TODO: store hash of proof data to save gas cost
    mapping(bytes32 => uint256) public vkHashesToBatchSize; // batch tier vk hashes => tier batch size

    event VerifierAddressesUpdated(uint64[] chainIds, ChainZKVerifier[] newAddresses);
    event BatchTierVkHashesUpdated(bytes32[] vkHashes, uint256[] sizes);

    constructor(ISMT _smtContract) BrevisAggProof(_smtContract) {}

    function submitProof(
        uint64 _chainId,
        bytes calldata _proofWithPubInputs,
        bool _withAppProof
    ) external returns (bytes32 _requestId) {
        require(verifyRaw(_chainId, _proofWithPubInputs, _withAppProof), "proof not valid");
        Brevis.ProofData memory data = unpackProofData(_proofWithPubInputs, _withAppProof);
        require(data.vkHash > 0, "vkHash should be larger than 0");
        uint256 batchSize = vkHashesToBatchSize[data.vkHash];
        require(batchSize > 0, "vkHash not valid");

        _requestId = data.commitHash;
        if (_withAppProof) {
            require(smtContract.isSmtRootValid(_chainId, data.smtRoot), "smt root not valid");
            proofs[_requestId].appCommitHash = data.appCommitHash; // save necessary fields only, to save gas
            proofs[_requestId].appVkHash = data.appVkHash;
        } else {
            proofs[_requestId].commitHash = data.commitHash;
        }
    }

    // used by contract app
    function validateRequest(
        bytes32 _requestId,
        uint64 _chainId,
        Brevis.ExtractInfos calldata _extractInfos
    ) external view {
        Brevis.ProofData memory data = proofs[_requestId];
        require(data.commitHash != bytes32(0), "proof not exists");
        require(smtContract.isSmtRootValid(_chainId, _extractInfos.smtRoot), "smt root not valid");

        uint256 itemsLength = _extractInfos.receipts.length + _extractInfos.stores.length + _extractInfos.txs.length;
        require(itemsLength > 0, "empty items");
        uint256 batchSize = vkHashesToBatchSize[data.vkHash];
        require(itemsLength <= batchSize, "item length exceeds batch size");

        bytes memory hashes;

        for (uint256 i = 0; i < _extractInfos.receipts.length; i++) {
            bytes memory fieldInfos;
            for (uint256 j = 0; j < Brevis.NumField; j++) {
                fieldInfos = abi.encodePacked(
                    fieldInfos,
                    _extractInfos.receipts[i].logs[j].logExtraInfo.valueFromTopic,
                    _extractInfos.receipts[i].logs[j].logIndex,
                    _extractInfos.receipts[i].logs[j].logExtraInfo.valueIndex,
                    _extractInfos.receipts[i].logs[j].logExtraInfo.contractAddress,
                    _extractInfos.receipts[i].logs[j].logExtraInfo.logTopic0,
                    _extractInfos.receipts[i].logs[j].value
                );
            }

            hashes = abi.encodePacked(
                hashes,
                keccak256(
                    abi.encodePacked(
                        _extractInfos.smtRoot,
                        _extractInfos.receipts[i].blkNum,
                        _extractInfos.receipts[i].receiptIndex,
                        fieldInfos
                    )
                )
            );
        }

        for (uint256 i = 0; i < _extractInfos.stores.length; i++) {
            hashes = abi.encodePacked(
                hashes,
                keccak256(
                    abi.encodePacked(
                        _extractInfos.smtRoot,
                        _extractInfos.stores[i].blockHash,
                        keccak256(abi.encodePacked(_extractInfos.stores[i].account)),
                        _extractInfos.stores[i].slot,
                        _extractInfos.stores[i].slotValue,
                        _extractInfos.stores[i].blockNumber
                    )
                )
            );
        }
        for (uint256 i = 0; i < _extractInfos.txs.length; i++) {
            hashes = abi.encodePacked(
                hashes,
                keccak256(
                    abi.encodePacked(
                        _extractInfos.smtRoot,
                        _extractInfos.txs[i].leafHash,
                        _extractInfos.txs[i].blockHash,
                        _extractInfos.txs[i].blockNumber,
                        _extractInfos.txs[i].blockTime
                    )
                )
            );
        }

        if (itemsLength < batchSize) {
            bytes32 emptyHash = bytes32(0x0000000000000000000000000000000100000000000000000000000000000001);
            for (uint256 i = itemsLength; i < batchSize; i++) {
                hashes = abi.encodePacked(hashes, emptyHash);
            }
        }
        require(keccak256(hashes) == data.commitHash, "commitHash and info not match");
    }

    function hasProof(bytes32 _requestId) external view returns (bool) {
        return
            proofs[_requestId].commitHash != bytes32(0) ||
            proofs[_requestId].appCommitHash != bytes32(0) ||
            inAgg(_requestId);
    }

    function getProofData(bytes32 _requestId) external view returns (Brevis.ProofData memory) {
        return proofs[_requestId];
    }

    function getProofAppData(bytes32 _requestId) external view returns (bytes32, bytes32) {
        return (proofs[_requestId].appCommitHash, proofs[_requestId].appVkHash);
    }

    function verifyRaw(
        uint64 _chainId,
        bytes calldata _proofWithPubInputs,
        bool _withAppProof
    ) private view returns (bool) {
        IZkpVerifier verifier;
        if (!_withAppProof) {
            verifier = verifierAddresses[_chainId].contractAppZkVerifier;
        } else {
            verifier = verifierAddresses[_chainId].circuitAppZkVerifier;
        }
        require(address(verifier) != address(0), "chain verifier not set");
        return verifier.verifyRaw(_proofWithPubInputs);
    }

    function unpackProofData(
        bytes calldata _proofWithPubInputs,
        bool _withAppProof
    ) internal pure returns (Brevis.ProofData memory data) {
        if (_withAppProof) {
            data.commitHash = bytes32(_proofWithPubInputs[PUBLIC_BYTES_START_IDX:PUBLIC_BYTES_START_IDX + 32]);
            data.smtRoot = bytes32(_proofWithPubInputs[PUBLIC_BYTES_START_IDX + 32:PUBLIC_BYTES_START_IDX + 2 * 32]);
            data.vkHash = bytes32(_proofWithPubInputs[PUBLIC_BYTES_START_IDX + 2 * 32:PUBLIC_BYTES_START_IDX + 3 * 32]);
            data.appCommitHash = bytes32(
                _proofWithPubInputs[PUBLIC_BYTES_START_IDX + 3 * 32:PUBLIC_BYTES_START_IDX + 4 * 32]
            );
            data.appVkHash = bytes32(
                _proofWithPubInputs[PUBLIC_BYTES_START_IDX + 4 * 32:PUBLIC_BYTES_START_IDX + 5 * 32]
            );
        } else {
            data.commitHash = bytes32(_proofWithPubInputs[PUBLIC_BYTES_START_IDX:PUBLIC_BYTES_START_IDX + 32]);
            // data length field in between no need to be unpacked
            data.vkHash = bytes32(_proofWithPubInputs[PUBLIC_BYTES_START_IDX + 2 * 32:PUBLIC_BYTES_START_IDX + 3 * 32]);
        }
    }

    function updateVerifierAddress(
        uint64[] calldata _chainIds,
        ChainZKVerifier[] calldata _verifierAddresses
    ) public onlyOwner {
        require(_chainIds.length == _verifierAddresses.length, "length not match");
        for (uint256 i = 0; i < _chainIds.length; i++) {
            verifierAddresses[_chainIds[i]] = _verifierAddresses[i];
        }
        emit VerifierAddressesUpdated(_chainIds, _verifierAddresses);
    }

    function setBatchTierVkHashes(bytes32[] calldata _vkHashes, uint256[] calldata _sizes) public onlyOwner {
        require(_vkHashes.length == _sizes.length, "length not match");
        for (uint256 i = 0; i < _vkHashes.length; i++) {
            vkHashesToBatchSize[_vkHashes[i]] = _sizes[i];
        }

        emit BatchTierVkHashesUpdated(_vkHashes, _sizes);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "solidity-rlp/contracts/RLPReader.sol";

library Brevis {
    uint256 constant NumField = 5; // supports at most 5 fields per receipt log

    struct ReceiptInfo {
        uint64 blkNum;
        uint64 receiptIndex; // ReceiptIndex in the block
        LogInfo[NumField] logs;
    }

    struct LogInfo {
        LogExtraInfo logExtraInfo;
        uint64 logIndex; // LogIndex of the field
        bytes32 value;
    }

    struct LogExtraInfo {
        uint8 valueFromTopic;
        uint64 valueIndex; // index of the fields in topic or data
        address contractAddress;
        bytes32 logTopic0;
    }

    struct StorageInfo {
        bytes32 blockHash;
        address account;
        bytes32 slot;
        bytes32 slotValue;
        uint64 blockNumber;
    }

    struct TransactionInfo {
        bytes32 leafHash;
        bytes32 blockHash;
        uint64 blockNumber;
        uint64 blockTime;
        bytes leafRlpPrefix;
    }

    struct ExtractInfos {
        bytes32 smtRoot;
        ReceiptInfo[] receipts;
        StorageInfo[] stores;
        TransactionInfo[] txs;
    }

    // retrieved from proofData, to align the logs with circuit...
    struct ProofData {
        bytes32 commitHash;
        bytes32 vkHash;
        bytes32 appCommitHash; // zk-program computing circuit commit hash
        bytes32 appVkHash; // zk-program computing circuit Verify Key hash
        bytes32 smtRoot; // for zk-program computing proof only
    }
}

library Tx {
    using RLPReader for bytes;
    using RLPReader for uint;
    using RLPReader for RLPReader.RLPItem;

    struct TxInfo {
        uint64 chainId;
        uint64 nonce;
        uint256 gasTipCap;
        uint256 gasFeeCap;
        uint256 gas;
        address to;
        uint256 value;
        bytes data;
        address from; // calculate from V R S
    }

    // support DynamicFeeTxType for now
    function decodeTx(bytes calldata txRaw) public pure returns (TxInfo memory info) {
        uint8 txType = uint8(txRaw[0]);
        require(txType == 2, "not a DynamicFeeTxType");

        bytes memory rlpData = txRaw[1:];
        RLPReader.RLPItem[] memory values = rlpData.toRlpItem().toList();
        info.chainId = uint64(values[0].toUint());
        info.nonce = uint64(values[1].toUint());
        info.gasTipCap = values[2].toUint();
        info.gasFeeCap = values[3].toUint();
        info.gas = values[4].toUint();
        info.to = values[5].toAddress();
        info.value = values[6].toUint();
        info.data = values[7].toBytes();

        (uint8 v, bytes32 r, bytes32 s) = (
            uint8(values[9].toUint()),
            bytes32(values[10].toBytes()),
            bytes32(values[11].toBytes())
        );
        // remove r,s,v and adjust length field
        bytes memory unsignedTxRaw;
        uint16 unsignedTxRawDataLength;
        uint8 prefix = uint8(txRaw[1]);
        uint8 lenBytes = prefix - 0xf7; // assume lenBytes won't larger than 2, means the tx rlp data size won't exceed 2^16
        if (lenBytes == 1) {
            unsignedTxRawDataLength = uint8(bytes1(txRaw[2:3])) - 67; //67 is the bytes of r,s,v
        } else {
            unsignedTxRawDataLength = uint16(bytes2(txRaw[2:2 + lenBytes])) - 67;
        }
        if (unsignedTxRawDataLength <= 55) {
            unsignedTxRaw = abi.encodePacked(txRaw[:2], txRaw[3:txRaw.length - 67]);
            unsignedTxRaw[1] = bytes1(0xc0 + uint8(unsignedTxRawDataLength));
        } else {
            if (unsignedTxRawDataLength <= 255) {
                unsignedTxRaw = abi.encodePacked(
                    txRaw[0],
                    bytes1(0xf8),
                    bytes1(uint8(unsignedTxRawDataLength)),
                    txRaw[2 + lenBytes:txRaw.length - 67]
                );
            } else {
                unsignedTxRaw = abi.encodePacked(
                    txRaw[0],
                    bytes1(0xf9),
                    bytes2(unsignedTxRawDataLength),
                    txRaw[2 + lenBytes:txRaw.length - 67]
                );
            }
        }
        info.from = recover(keccak256(unsignedTxRaw), r, s, v);
    }

    function recover(bytes32 message, bytes32 r, bytes32 s, uint8 v) internal pure returns (address) {
        if (v < 27) {
            v += 27;
        }
        return ecrecover(message, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IZkpVerifier {
    function verifyRaw(bytes calldata proofData) external view returns (bool r);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IVerifier {
    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[2] commitment;
    }

    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory commit,
        uint256[10] calldata input
    ) external view returns (bool r);
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

    /** RLPItem conversions into data types **/

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
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
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
            uint256 mask = 256**(WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}