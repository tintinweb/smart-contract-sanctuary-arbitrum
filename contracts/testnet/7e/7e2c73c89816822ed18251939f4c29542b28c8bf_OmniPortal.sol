// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {OmniCodec} from "./OmniCodec.sol";
import {Ics23} from "./ics23/ics23.sol";
import {Ics23CommitmentProof} from "./ics23/proofs.sol";
import {Ics23ProofSpecs} from "./ics23/specs.sol";
import {OmniProofs} from "./OmniProofs.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title OmniPortal
 * @notice Repurposed from Optimism's OmniPortal.
 */
contract OmniPortal is Initializable, OwnableUpgradeable {
    address internal constant OMNI_PREDEPLOY_ADDRESS = 0x1212400000000000000000000000000000000001;

    OmniCodec.BlockChunk public latestOmniBlockChunk;

    // block number -> chunk index -> block chunk
    mapping(uint64 => mapping(uint64 => OmniCodec.BlockChunk)) public omniBlocks;

    bool public isXChainTx; // set to true before processing an xchain tx
    address public txSender; // set tx.from before processing an xchain tx
    string public txSourceChain; // set to tx.sourceChain before processing an xchain tx

    // just initialized in contructor for now
    // TODO: track orchestrator stake and weight votes by stake
    mapping(address => bool) orchestrators;

    string public chain;
    uint256 public nonce;
    OmniProofs public proofs;

    mapping(string => bool) supportedChains;

    event TransactionDeposited(address indexed from, address indexed to, uint256 indexed nonce, bytes data);
    event OmniBlockAdded(uint256 indexed blockNumber, OmniCodec.BlockChunk block);
    event XChainTxResult(bytes32 indexed sourceTxHash, uint256 indexed omniNonce, bool success);

    constructor() initializer {}

    function initialize(string memory _chain, address[] memory _orchestrators, address _proofs) public initializer {
        __Ownable_init();
        chain = _chain;
        for (uint64 i = 0; i < _orchestrators.length; i++) {
            orchestrators[_orchestrators[i]] = true;
        }
        proofs = OmniProofs(_proofs);
    }

    modifier onlySupportedChain(string memory _chain) {
        require(supportedChains[_chain], "Omni: chain is not supported");
        _;
    }

    modifier isBelowXChainCalldataLimit(bytes memory _data) {
        require(OmniCodec.isBelowXChainCalldataLimit(_data), "Omni: tx data is too large");
        _;
    }

    function addSupportedChain(string memory _chain) external onlyOwner {
        supportedChains[_chain] = true;
    }

    function removeSupportedChain(string memory _chain) external onlyOwner {
        supportedChains[_chain] = false;
    }

    function addOrchestrator(address _orchestrator) external onlyOwner {
        orchestrators[_orchestrator] = true;
    }

    function removeOrchestrator(address _orchestrator) external onlyOwner {
        orchestrators[_orchestrator] = false;
    }

    // used only for testing
    function resetState(OmniCodec.BlockChunk calldata _block, uint256 _nonce) external onlyOwner {
        nonce = _nonce;
        latestOmniBlockChunk = _block;
    }

    function getLatestOmniBlockChunk() public view returns (OmniCodec.BlockChunk memory) {
        return latestOmniBlockChunk;
    }

    function isOrchestrator(address _address) public view returns (bool) {
        return orchestrators[_address];
    }

    function addOmniBlockChunk(OmniCodec.BlockChunk calldata _blockChunk, bytes[] calldata signatures) public {
        if (_blockChunk.number == latestOmniBlockChunk.number) {
            require(_blockChunk.hash == latestOmniBlockChunk.hash, "OmniPortal: invalid hash");
            require(_blockChunk.parentHash == latestOmniBlockChunk.parentHash, "OmniPortal: invalid parent hash");
            require(_blockChunk.chunkIndex == latestOmniBlockChunk.chunkIndex + 1, "OmniPortal: invalid chunk");
        } else {
            require(_blockChunk.parentHash == latestOmniBlockChunk.hash, "OmniPortal: invalid parent hash");
            require(_blockChunk.chunkIndex == 0, "OmniPortal: invalid chunk");

            // require first block to be complete, if it exists
            if (latestOmniBlockChunk.hash != bytes32(0)) {
                require(
                    latestOmniBlockChunk.chunkIndex == latestOmniBlockChunk.totalChunks - 1,
                    "OmniPortal: current block is not complete"
                );
            }
        }

        bytes32 digest = keccak256(OmniCodec.encodeBlockChunk(_blockChunk));
        address[] memory signers = new address[](signatures.length);

        // check signatures
        for (uint64 i = 0; i < signatures.length; i++) {
            (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(digest, signatures[i]);

            require(err == ECDSA.RecoverError.NoError, "OmniPortal: invalid signature");
            require(isOrchestrator(signer), "OmniPortal: signer is not an orchestrator");

            // check signer is unique
            for (uint64 j = 0; j < i; j++) {
                require(signers[j] != signer, "OmniPortal: duplicate signer");
            }

            signers[i] = signer;
        }

        // for testnet2, block is added if any orchestrator voted for it
        require(signers.length >= 1, "OmniPortal: not enough signatures");

        latestOmniBlockChunk = _blockChunk;
        omniBlocks[_blockChunk.number][_blockChunk.chunkIndex] = _blockChunk;

        for (uint64 i = 0; i < _blockChunk.txs.length; i++) {
            // only execute block transactions where destination is current chain
            OmniCodec.Tx memory blockTx = _blockChunk.txs[i];
            if (OmniCodec.packChain(blockTx.destChain) == OmniCodec.packChain(chain)) {
                _executeTx(blockTx);
            }
        }

        emit OmniBlockAdded(_blockChunk.number, _blockChunk);
    }

    function addOmniBlockChunks(OmniCodec.BlockChunk[] calldata _blockChunks, bytes[][] calldata signatures) public {
        require(_blockChunks.length == signatures.length, "OmniPortal: blocks and signatures length mismatch");

        for (uint64 i = 0; i < _blockChunks.length; i++) {
            addOmniBlockChunk(_blockChunks[i], signatures[i]);
        }
    }

    function _executeTx(OmniCodec.Tx memory _tx) internal {
        txSender = _tx.from;
        txSourceChain = _tx.sourceChain;
        isXChainTx = true;

        uint256 gasStart = gasleft();
        (bool success, bytes memory returnValue) = address(_tx.to).call(_tx.data);
        uint256 gasSpent = gasStart - gasleft();

        txSender = address(0);
        txSourceChain = "";
        isXChainTx = false;

        if (success) {
            _sendOmniTx(
                OMNI_PREDEPLOY_ADDRESS,
                abi.encodeWithSignature(
                    "markSuccess(bytes,address,bytes,uint256)",
                    OmniCodec.encodeTx(_tx),
                    msg.sender,
                    returnValue,
                    gasSpent
                )
            );
        } else {
            _sendOmniTx(
                OMNI_PREDEPLOY_ADDRESS,
                abi.encodeWithSignature(
                    "markReverted(bytes,address,uint256)", OmniCodec.encodeTx(_tx), msg.sender, gasSpent
                )
            );
        }

        emit XChainTxResult(_tx.sourceTxHash, _tx.nonce, success);
    }

    function sendOmniTx(address _to, bytes memory _data) external {
        require(_to != OMNI_PREDEPLOY_ADDRESS, "OmniPortal: direct sendOmniTx to Omni allowed only by portal");
        _sendOmniTx(_to, _data);
    }

    function _sendOmniTx(address _to, bytes memory _data) private {
        uint256 value = 0;
        uint64 gasLimit = 1_000_000;
        bytes memory txData = abi.encodePacked(msg.value, value, gasLimit, _data);
        emit TransactionDeposited(msg.sender, _to, nonce, txData);
        nonce = nonce + 1;
    }

    function sendXChainTx(string memory _chain, address _to, bytes memory _data)
        external
        onlySupportedChain(_chain)
        isBelowXChainCalldataLimit(_data)
    {
        _sendOmniTx(OMNI_PREDEPLOY_ADDRESS, abi.encodeWithSignature("sendTx(string,address,bytes)", _chain, _to, _data));
    }

    function verifyOmniState(
        uint64 _blockNumber,
        bytes memory _storageProof,
        bytes memory _storageKey,
        bytes memory _storageValue
    ) public view returns (bool) {
        OmniCodec.BlockChunk storage b = omniBlocks[_blockNumber][0];
        require(b.hash != 0x0, "OmniPortal: state root not found");

        bytes memory root = abi.encodePacked(b.hash);

        Ics23CommitmentProof.Data memory storageProof = Ics23CommitmentProof.decode(_storageProof);
        Ics23.VerifyMembershipError err =
            proofs.ics23VerifyMembership(Ics23ProofSpecs.iavlSpec(), root, storageProof, _storageKey, _storageValue);

        require(err == Ics23.VerifyMembershipError.None, "OmniPortal: invalid storageProof");

        return true;
    }

    /**
     * txSourceChain helpers
     *
     * NOTE: copied from Omni.sol helpers. We might join implementations in some library or abstract contract.
     */

    function isTxFrom(string memory _chain) public view returns (bool) {
        return OmniCodec.cmpChains(txSourceChain, _chain);
    }

    function isOmniTx() public view returns (bool) {
        return isTxFrom("omni");
    }

    function isTxFromOneOf(string memory _chain1, string memory _chain2) public view returns (bool) {
        return isTxFrom(_chain1) || isTxFrom(_chain2);
    }

    function isTxFromOneOf(string memory _chain1, string memory _chain2, string memory _chain3)
        public
        view
        returns (bool)
    {
        return isTxFrom(_chain1) || isTxFrom(_chain2) || isTxFrom(_chain3);
    }

    function isTxFromOneOf(string memory _chain1, string memory _chain2, string memory _chain3, string memory _chain4)
        public
        view
        returns (bool)
    {
        return isTxFrom(_chain1) || isTxFrom(_chain2) || isTxFrom(_chain3) || isTxFrom(_chain4);
    }

    function isTxFromOneOf(
        string memory _chain1,
        string memory _chain2,
        string memory _chain3,
        string memory _chain4,
        string memory _chain5
    ) public view returns (bool) {
        return isTxFrom(_chain1) || isTxFrom(_chain2) || isTxFrom(_chain3) || isTxFrom(_chain4) || isTxFrom(_chain5);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library OmniCodec {
    struct Tx {
        bytes32 sourceTxHash;
        string sourceChain; // differs from block.sourceChain in external chain -> chain txs
        string destChain;
        uint64 nonce;
        address from;
        address to;
        uint256 value;
        uint256 paid;
        uint64 gasLimit;
        bytes data;
    }

    struct BlockChunk {
        string destChain;
        bytes32 parentHash;
        bytes32 hash;
        uint64 number;
        Tx[] txs;
        uint64 totalChunks;
        uint64 chunkIndex;
    }

    // Many rollups follow ethereum post EIP-1559 block gas limit of
    // 30,000,000. Average calldata byte costs 15.95 gas (4 gas if the byte
    // is zero, 16 otherwise). The theoretical maximum size is about 1.8 MB for
    // a single tx, that takes up an entire block. Omni xchain txs are batch,
    // and submitted together in a single tx. So we set a conservative limit of
    // for a single omni xchain tx of < 1% 1.8MB.
    uint64 public constant MAX_XCHAIN_CALLDATA_BYTES = 10_000; // 10kb

    function isBelowXChainCalldataLimit(bytes memory _data) internal pure returns (bool) {
        return _data.length <= MAX_XCHAIN_CALLDATA_BYTES;
    }

    function packChain(string memory _chain) internal pure returns (bytes32) {
        return keccak256(abi.encode(_chain));
    }

    function cmpChains(string memory _chain1, string memory _chain2) internal pure returns (bool) {
        return packChain(_chain1) == packChain(_chain2);
    }

    function encodeBlockChunk(BlockChunk memory _block) internal pure returns (bytes memory) {
        return abi.encode(_block);
    }

    function decodeBlockChunk(bytes memory _block) internal pure returns (BlockChunk memory) {
        return abi.decode(_block, (BlockChunk));
    }

    function encodeTx(Tx memory _tx) internal pure returns (bytes memory) {
        return abi.encode(_tx);
    }

    function decodeTx(bytes memory _tx) internal pure returns (Tx memory) {
        return abi.decode(_tx, (Tx));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

import {
    Ics23BatchProof, Ics23CompressedBatchProof, Ics23CommitmentProof, Ics23ProofSpec, Ics23ExistenceProof, Ics23NonExistenceProof
} from "./proofs.sol";
import {Compress} from "./ics23Compress.sol";
import {Proof} from "./ics23Proof.sol";
import {Ops} from "./ics23Ops.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";


library Ics23  {

    enum VerifyMembershipError {
        None,
        ExistenceProofIsNil,
        ProofVerify,
        Decompress
    }
    function verifyMembership(
        Ics23ProofSpec.Data memory spec,
        bytes memory commitmentRoot,
        Ics23CommitmentProof.Data memory proof,
        bytes memory key,
        bytes memory value
    ) internal pure returns(VerifyMembershipError){
        (Ics23CommitmentProof.Data memory decoProof, Compress.DecompressEntryError erCode) = Compress.decompress(proof);
        if (erCode != Compress.DecompressEntryError.None) return VerifyMembershipError.Decompress;
        Ics23ExistenceProof.Data memory exiProof = getExistProofForKey(decoProof, key);
        //require(Ics23ExistenceProof.isNil(exiProof) == false); // dev: getExistProofForKey not available
        if (Ics23ExistenceProof.isNil(exiProof)) return VerifyMembershipError.ExistenceProofIsNil;
        Proof.VerifyExistenceError vCode = Proof.verify(exiProof, spec, commitmentRoot, key, value);
        if (vCode != Proof.VerifyExistenceError.None) return VerifyMembershipError.ProofVerify;

        return VerifyMembershipError.None;
    }

    enum VerifyNonMembershipError {
        None,
        NonExistenceProofIsNil,
        ProofVerify,
        Decompress
    }

    function verifyNonMembership(
        Ics23ProofSpec.Data memory spec,
        bytes memory commitmentRoot,
        Ics23CommitmentProof.Data memory proof,
        bytes memory key
    ) internal pure returns(VerifyNonMembershipError) {
        (Ics23CommitmentProof.Data memory decoProof, Compress.DecompressEntryError erCode) = Compress.decompress(proof);
        if (erCode != Compress.DecompressEntryError.None) return VerifyNonMembershipError.Decompress;
        Ics23NonExistenceProof.Data memory nonProof = getNonExistProofForKey(decoProof, key);
        //require(Ics23NonExistenceProof.isNil(nonProof) == false); // dev: getNonExistProofForKey not available
        if (Ics23NonExistenceProof.isNil(nonProof)) return VerifyNonMembershipError.NonExistenceProofIsNil;
        Proof.VerifyNonExistenceError vCode =  Proof.verify(nonProof, spec, commitmentRoot, key);
        if (vCode != Proof.VerifyNonExistenceError.None) return VerifyNonMembershipError.ProofVerify;

        return VerifyNonMembershipError.None;
    }
/* -- temporarily disabled as they are not covered by unit tests
    struct BatchItem {
        bytes key;
        bytes value;
    }
    function batchVerifyMembership(ProofSpec.Data memory spec, bytes memory commitmentRoot, CommitmentProof.Data memory proof, BatchItem[] memory items ) internal pure {
        CommitmentProof.Data memory decoProof = Compress.decompress(proof);
        for (uint i = 0; i < items.length; i++) {
            verifyMembership(spec, commitmentRoot, decoProof, items[i].key, items[i].value);
        }
    }

    function batchVerifyNonMembership(ProofSpec.Data memory spec, bytes memory commitmentRoot, CommitmentProof.Data memory proof, bytes[] memory keys ) internal pure {
        CommitmentProof.Data memory decoProof = Compress.decompress(proof);
        for (uint i = 0; i < keys.length; i++) {
            verifyNonMembership(spec, commitmentRoot, decoProof, keys[i]);
        }
    }
*/

    // private
    function getExistProofForKey(
        Ics23CommitmentProof.Data memory proof,
        bytes memory key
    ) private pure returns(Ics23ExistenceProof.Data memory) {
        if (Ics23ExistenceProof.isNil(proof.exist) == false){
            if (BytesLib.equal(proof.exist.key, key) == true) {
                return proof.exist;
            }
        } else if(Ics23BatchProof.isNil(proof.batch) == false) {
            for (uint i = 0; i < proof.batch.entries.length; i++) {
                if (Ics23ExistenceProof.isNil(proof.batch.entries[i].exist) == false &&
                    BytesLib.equal(proof.batch.entries[i].exist.key, key)) {
                    return proof.batch.entries[i].exist;
                }
            }
        }
        return Ics23ExistenceProof.nil();
    }

    function getNonExistProofForKey(
        Ics23CommitmentProof.Data memory proof,
        bytes memory key
    ) private pure returns(Ics23NonExistenceProof.Data memory) {
        if (Ics23NonExistenceProof.isNil(proof.nonexist) == false) {
            if (isLeft(proof.nonexist.left, key) && isRight(proof.nonexist.right, key)) {
                return proof.nonexist;
            }
        } else if (Ics23BatchProof.isNil(proof.batch) == false) {
            for (uint i = 0; i < proof.batch.entries.length; i++) {
                if (Ics23NonExistenceProof.isNil(proof.batch.entries[i].nonexist) == false &&
                    isLeft(proof.batch.entries[i].nonexist.left, key) &&
                    isRight(proof.batch.entries[i].nonexist.right, key)) {
                    return proof.batch.entries[i].nonexist;
                }
            }
        }
        return Ics23NonExistenceProof.nil();
    }

    function isLeft(Ics23ExistenceProof.Data memory left, bytes memory key) private pure returns(bool) {
        // Ics23ExistenceProof.isNil does not work
        return Ics23ExistenceProof._empty(left) || Ops.compare(left.key, key) < 0;
    }

    function isRight(Ics23ExistenceProof.Data memory right, bytes memory key) private pure returns(bool) {
        // Ics23ExistenceProof.isNil does not work
        return Ics23ExistenceProof._empty(right) || Ops.compare(right.key, key) > 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;
import "./ProtoBufRuntime.sol";
import "./GoogleProtobufAny.sol";

library Ics23ExistenceProof {


  //struct definition
  struct Data {
    bytes key;
    bytes value;
    Ics23LeafOp.Data leaf;
    Ics23InnerOp.Data[] path;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[5] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_key(pointer, bs, r);
      } else
      if (fieldId == 2) {
        pointer += _read_value(pointer, bs, r);
      } else
      if (fieldId == 3) {
        pointer += _read_leaf(pointer, bs, r);
      } else
      if (fieldId == 4) {
        pointer += _read_unpacked_repeated_path(pointer, bs, nil(), counters);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    pointer = offset;
    if (counters[4] > 0) {
      require(r.path.length == 0);
      r.path = new Ics23InnerOp.Data[](counters[4]);
    }

    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 4) {
        pointer += _read_unpacked_repeated_path(pointer, bs, r, counters);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }
    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_key(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    r.key = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_value(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    r.value = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_leaf(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23LeafOp.Data memory x, uint256 sz) = _decode_Ics23LeafOp(p, bs);
    r.leaf = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_unpacked_repeated_path(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[5] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (Ics23InnerOp.Data memory x, uint256 sz) = _decode_Ics23InnerOp(p, bs);
    if (isNil(r)) {
      counters[4] += 1;
    } else {
      r.path[r.path.length - counters[4]] = x;
      counters[4] -= 1;
    }
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23LeafOp(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23LeafOp.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23LeafOp.Data memory r, ) = Ics23LeafOp._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }

  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23InnerOp(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23InnerOp.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23InnerOp.Data memory r, ) = Ics23InnerOp._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    uint256 i;
    if (r.key.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.key, pointer, bs);
    }
    if (r.value.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.value, pointer, bs);
    }
    
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23LeafOp._encode_nested(r.leaf, pointer, bs);
    
    if (r.path.length != 0) {
    for(i = 0; i < r.path.length; i++) {
      pointer += ProtoBufRuntime._encode_key(
        4,
        ProtoBufRuntime.WireType.LengthDelim,
        pointer,
        bs)
      ;
      pointer += Ics23InnerOp._encode_nested(r.path[i], pointer, bs);
    }
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;uint256 i;
    e += 1 + ProtoBufRuntime._sz_lendelim(r.key.length);
    e += 1 + ProtoBufRuntime._sz_lendelim(r.value.length);
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23LeafOp._estimate(r.leaf));
    for(i = 0; i < r.path.length; i++) {
      e += 1 + ProtoBufRuntime._sz_lendelim(Ics23InnerOp._estimate(r.path[i]));
    }
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.key.length != 0) {
    return false;
  }

  if (r.value.length != 0) {
    return false;
  }

  if (r.path.length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.key = input.key;
    output.value = input.value;
    Ics23LeafOp.store(input.leaf, output.leaf);

    for(uint256 i4 = 0; i4 < input.path.length; i4++) {
      output.path.push(input.path[i4]);
    }
    

  }


  //array helpers for Path
  /**
   * @dev Add value to an array
   * @param self The in-memory struct
   * @param value The value to add
   */
  function addPath(Data memory self, Ics23InnerOp.Data memory value) internal pure {
    /**
     * First resize the array. Then add the new element to the end.
     */
    Ics23InnerOp.Data[] memory tmp = new Ics23InnerOp.Data[](self.path.length + 1);
    for (uint256 i = 0; i < self.path.length; i++) {
      tmp[i] = self.path[i];
    }
    tmp[self.path.length] = value;
    self.path = tmp;
  }


  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23ExistenceProof

library Ics23NonExistenceProof {


  //struct definition
  struct Data {
    bytes key;
    Ics23ExistenceProof.Data left;
    Ics23ExistenceProof.Data right;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_key(pointer, bs, r);
      } else
      if (fieldId == 2) {
        pointer += _read_left(pointer, bs, r);
      } else
      if (fieldId == 3) {
        pointer += _read_right(pointer, bs, r);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_key(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    r.key = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_left(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23ExistenceProof.Data memory x, uint256 sz) = _decode_Ics23ExistenceProof(p, bs);
    r.left = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_right(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23ExistenceProof.Data memory x, uint256 sz) = _decode_Ics23ExistenceProof(p, bs);
    r.right = x;
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23ExistenceProof(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23ExistenceProof.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23ExistenceProof.Data memory r, ) = Ics23ExistenceProof._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    if (r.key.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.key, pointer, bs);
    }
    
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23ExistenceProof._encode_nested(r.left, pointer, bs);
    
    
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23ExistenceProof._encode_nested(r.right, pointer, bs);
    
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(r.key.length);
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23ExistenceProof._estimate(r.left));
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23ExistenceProof._estimate(r.right));
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.key.length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.key = input.key;
    Ics23ExistenceProof.store(input.left, output.left);
    Ics23ExistenceProof.store(input.right, output.right);

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23NonExistenceProof

library Ics23CommitmentProof {


  //struct definition
  struct Data {
    Ics23ExistenceProof.Data exist;
    Ics23NonExistenceProof.Data nonexist;
    Ics23BatchProof.Data batch;
    Ics23CompressedBatchProof.Data compressed;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_exist(pointer, bs, r);
      } else
      if (fieldId == 2) {
        pointer += _read_nonexist(pointer, bs, r);
      } else
      if (fieldId == 3) {
        pointer += _read_batch(pointer, bs, r);
      } else
      if (fieldId == 4) {
        pointer += _read_compressed(pointer, bs, r);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_exist(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23ExistenceProof.Data memory x, uint256 sz) = _decode_Ics23ExistenceProof(p, bs);
    r.exist = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_nonexist(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23NonExistenceProof.Data memory x, uint256 sz) = _decode_Ics23NonExistenceProof(p, bs);
    r.nonexist = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_batch(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23BatchProof.Data memory x, uint256 sz) = _decode_Ics23BatchProof(p, bs);
    r.batch = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_compressed(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23CompressedBatchProof.Data memory x, uint256 sz) = _decode_Ics23CompressedBatchProof(p, bs);
    r.compressed = x;
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23ExistenceProof(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23ExistenceProof.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23ExistenceProof.Data memory r, ) = Ics23ExistenceProof._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }

  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23NonExistenceProof(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23NonExistenceProof.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23NonExistenceProof.Data memory r, ) = Ics23NonExistenceProof._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }

  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23BatchProof(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23BatchProof.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23BatchProof.Data memory r, ) = Ics23BatchProof._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }

  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23CompressedBatchProof(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23CompressedBatchProof.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23CompressedBatchProof.Data memory r, ) = Ics23CompressedBatchProof._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23ExistenceProof._encode_nested(r.exist, pointer, bs);
    
    
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23NonExistenceProof._encode_nested(r.nonexist, pointer, bs);
    
    
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23BatchProof._encode_nested(r.batch, pointer, bs);
    
    
    pointer += ProtoBufRuntime._encode_key(
      4,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23CompressedBatchProof._encode_nested(r.compressed, pointer, bs);
    
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23ExistenceProof._estimate(r.exist));
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23NonExistenceProof._estimate(r.nonexist));
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23BatchProof._estimate(r.batch));
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23CompressedBatchProof._estimate(r.compressed));
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    Ics23ExistenceProof.store(input.exist, output.exist);
    Ics23NonExistenceProof.store(input.nonexist, output.nonexist);
    Ics23BatchProof.store(input.batch, output.batch);
    Ics23CompressedBatchProof.store(input.compressed, output.compressed);

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23CommitmentProof

library Ics23LeafOp {


  //struct definition
  struct Data {
    PROOFS_PROTO_GLOBAL_ENUMS.HashOp hash;
    PROOFS_PROTO_GLOBAL_ENUMS.HashOp prehash_key;
    PROOFS_PROTO_GLOBAL_ENUMS.HashOp prehash_value;
    PROOFS_PROTO_GLOBAL_ENUMS.LengthOp length;
    bytes prefix;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_hash(pointer, bs, r);
      } else
      if (fieldId == 2) {
        pointer += _read_prehash_key(pointer, bs, r);
      } else
      if (fieldId == 3) {
        pointer += _read_prehash_value(pointer, bs, r);
      } else
      if (fieldId == 4) {
        pointer += _read_length(pointer, bs, r);
      } else
      if (fieldId == 5) {
        pointer += _read_prefix(pointer, bs, r);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_hash(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    PROOFS_PROTO_GLOBAL_ENUMS.HashOp x = PROOFS_PROTO_GLOBAL_ENUMS.decode_HashOp(tmp);
    r.hash = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_prehash_key(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    PROOFS_PROTO_GLOBAL_ENUMS.HashOp x = PROOFS_PROTO_GLOBAL_ENUMS.decode_HashOp(tmp);
    r.prehash_key = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_prehash_value(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    PROOFS_PROTO_GLOBAL_ENUMS.HashOp x = PROOFS_PROTO_GLOBAL_ENUMS.decode_HashOp(tmp);
    r.prehash_value = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_length(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    PROOFS_PROTO_GLOBAL_ENUMS.LengthOp x = PROOFS_PROTO_GLOBAL_ENUMS.decode_LengthOp(tmp);
    r.length = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_prefix(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    r.prefix = x;
    return sz;
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    if (uint(r.hash) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int32 _enum_hash = PROOFS_PROTO_GLOBAL_ENUMS.encode_HashOp(r.hash);
    pointer += ProtoBufRuntime._encode_enum(_enum_hash, pointer, bs);
    }
    if (uint(r.prehash_key) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int32 _enum_prehash_key = PROOFS_PROTO_GLOBAL_ENUMS.encode_HashOp(r.prehash_key);
    pointer += ProtoBufRuntime._encode_enum(_enum_prehash_key, pointer, bs);
    }
    if (uint(r.prehash_value) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int32 _enum_prehash_value = PROOFS_PROTO_GLOBAL_ENUMS.encode_HashOp(r.prehash_value);
    pointer += ProtoBufRuntime._encode_enum(_enum_prehash_value, pointer, bs);
    }
    if (uint(r.length) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      4,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int32 _enum_length = PROOFS_PROTO_GLOBAL_ENUMS.encode_LengthOp(r.length);
    pointer += ProtoBufRuntime._encode_enum(_enum_length, pointer, bs);
    }
    if (r.prefix.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      5,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.prefix, pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_enum(PROOFS_PROTO_GLOBAL_ENUMS.encode_HashOp(r.hash));
    e += 1 + ProtoBufRuntime._sz_enum(PROOFS_PROTO_GLOBAL_ENUMS.encode_HashOp(r.prehash_key));
    e += 1 + ProtoBufRuntime._sz_enum(PROOFS_PROTO_GLOBAL_ENUMS.encode_HashOp(r.prehash_value));
    e += 1 + ProtoBufRuntime._sz_enum(PROOFS_PROTO_GLOBAL_ENUMS.encode_LengthOp(r.length));
    e += 1 + ProtoBufRuntime._sz_lendelim(r.prefix.length);
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (uint(r.hash) != 0) {
    return false;
  }

  if (uint(r.prehash_key) != 0) {
    return false;
  }

  if (uint(r.prehash_value) != 0) {
    return false;
  }

  if (uint(r.length) != 0) {
    return false;
  }

  if (r.prefix.length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.hash = input.hash;
    output.prehash_key = input.prehash_key;
    output.prehash_value = input.prehash_value;
    output.length = input.length;
    output.prefix = input.prefix;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23LeafOp

library Ics23InnerOp {


  //struct definition
  struct Data {
    PROOFS_PROTO_GLOBAL_ENUMS.HashOp hash;
    bytes prefix;
    bytes suffix;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_hash(pointer, bs, r);
      } else
      if (fieldId == 2) {
        pointer += _read_prefix(pointer, bs, r);
      } else
      if (fieldId == 3) {
        pointer += _read_suffix(pointer, bs, r);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_hash(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    PROOFS_PROTO_GLOBAL_ENUMS.HashOp x = PROOFS_PROTO_GLOBAL_ENUMS.decode_HashOp(tmp);
    r.hash = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_prefix(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    r.prefix = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_suffix(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    r.suffix = x;
    return sz;
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    if (uint(r.hash) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int32 _enum_hash = PROOFS_PROTO_GLOBAL_ENUMS.encode_HashOp(r.hash);
    pointer += ProtoBufRuntime._encode_enum(_enum_hash, pointer, bs);
    }
    if (r.prefix.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.prefix, pointer, bs);
    }
    if (r.suffix.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.suffix, pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_enum(PROOFS_PROTO_GLOBAL_ENUMS.encode_HashOp(r.hash));
    e += 1 + ProtoBufRuntime._sz_lendelim(r.prefix.length);
    e += 1 + ProtoBufRuntime._sz_lendelim(r.suffix.length);
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (uint(r.hash) != 0) {
    return false;
  }

  if (r.prefix.length != 0) {
    return false;
  }

  if (r.suffix.length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.hash = input.hash;
    output.prefix = input.prefix;
    output.suffix = input.suffix;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23InnerOp

library Ics23ProofSpec {


  //struct definition
  struct Data {
    Ics23LeafOp.Data leaf_spec;
    Ics23InnerSpec.Data inner_spec;
    int32 max_depth;
    int32 min_depth;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_leaf_spec(pointer, bs, r);
      } else
      if (fieldId == 2) {
        pointer += _read_inner_spec(pointer, bs, r);
      } else
      if (fieldId == 3) {
        pointer += _read_max_depth(pointer, bs, r);
      } else
      if (fieldId == 4) {
        pointer += _read_min_depth(pointer, bs, r);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_leaf_spec(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23LeafOp.Data memory x, uint256 sz) = _decode_Ics23LeafOp(p, bs);
    r.leaf_spec = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_inner_spec(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23InnerSpec.Data memory x, uint256 sz) = _decode_Ics23InnerSpec(p, bs);
    r.inner_spec = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_max_depth(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
    r.max_depth = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_min_depth(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
    r.min_depth = x;
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23LeafOp(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23LeafOp.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23LeafOp.Data memory r, ) = Ics23LeafOp._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }

  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23InnerSpec(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23InnerSpec.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23InnerSpec.Data memory r, ) = Ics23InnerSpec._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23LeafOp._encode_nested(r.leaf_spec, pointer, bs);
    
    
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23InnerSpec._encode_nested(r.inner_spec, pointer, bs);
    
    if (r.max_depth != 0) {
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_int32(r.max_depth, pointer, bs);
    }
    if (r.min_depth != 0) {
    pointer += ProtoBufRuntime._encode_key(
      4,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_int32(r.min_depth, pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23LeafOp._estimate(r.leaf_spec));
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23InnerSpec._estimate(r.inner_spec));
    e += 1 + ProtoBufRuntime._sz_int32(r.max_depth);
    e += 1 + ProtoBufRuntime._sz_int32(r.min_depth);
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.max_depth != 0) {
    return false;
  }

  if (r.min_depth != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    Ics23LeafOp.store(input.leaf_spec, output.leaf_spec);
    Ics23InnerSpec.store(input.inner_spec, output.inner_spec);
    output.max_depth = input.max_depth;
    output.min_depth = input.min_depth;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23ProofSpec

library Ics23InnerSpec {


  //struct definition
  struct Data {
    int32[] child_order;
    int32 child_size;
    int32 min_prefix_length;
    int32 max_prefix_length;
    bytes empty_child;
    PROOFS_PROTO_GLOBAL_ENUMS.HashOp hash;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[7] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          pointer += _read_packed_repeated_child_order(pointer, bs, r);
        } else {
          pointer += _read_unpacked_repeated_child_order(pointer, bs, nil(), counters);
        }
      } else
      if (fieldId == 2) {
        pointer += _read_child_size(pointer, bs, r);
      } else
      if (fieldId == 3) {
        pointer += _read_min_prefix_length(pointer, bs, r);
      } else
      if (fieldId == 4) {
        pointer += _read_max_prefix_length(pointer, bs, r);
      } else
      if (fieldId == 5) {
        pointer += _read_empty_child(pointer, bs, r);
      } else
      if (fieldId == 6) {
        pointer += _read_hash(pointer, bs, r);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    pointer = offset;
    if (counters[1] > 0) {
      require(r.child_order.length == 0);
      r.child_order = new int32[](counters[1]);
    }

    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1 && wireType != ProtoBufRuntime.WireType.LengthDelim) {
        pointer += _read_unpacked_repeated_child_order(pointer, bs, r, counters);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }
    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_unpacked_repeated_child_order(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[7] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.child_order[r.child_order.length - counters[1]] = x;
      counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_packed_repeated_child_order(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (uint256 len, uint256 size) = ProtoBufRuntime._decode_varint(p, bs);
    p += size;
    uint256 count = ProtoBufRuntime._count_packed_repeated_varint(p, len, bs);
    r.child_order = new int32[](count);
    for (uint256 i = 0; i < count; i++) {
      (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
      p += sz;
      r.child_order[i] = x;
    }
    return size + len;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_child_size(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
    r.child_size = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_min_prefix_length(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
    r.min_prefix_length = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_max_prefix_length(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
    r.max_prefix_length = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_empty_child(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    r.empty_child = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_hash(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
    PROOFS_PROTO_GLOBAL_ENUMS.HashOp x = PROOFS_PROTO_GLOBAL_ENUMS.decode_HashOp(tmp);
    r.hash = x;
    return sz;
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    uint256 i;
    if (r.child_order.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_varint(
      ProtoBufRuntime._estimate_packed_repeated_int32(r.child_order),
      pointer,
      bs
    );
    for(i = 0; i < r.child_order.length; i++) {
      pointer += ProtoBufRuntime._encode_int32(r.child_order[i], pointer, bs);
    }
    }
    if (r.child_size != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_int32(r.child_size, pointer, bs);
    }
    if (r.min_prefix_length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_int32(r.min_prefix_length, pointer, bs);
    }
    if (r.max_prefix_length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      4,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_int32(r.max_prefix_length, pointer, bs);
    }
    if (r.empty_child.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      5,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.empty_child, pointer, bs);
    }
    if (uint(r.hash) != 0) {
    pointer += ProtoBufRuntime._encode_key(
      6,
      ProtoBufRuntime.WireType.Varint,
      pointer,
      bs
    );
    int32 _enum_hash = PROOFS_PROTO_GLOBAL_ENUMS.encode_HashOp(r.hash);
    pointer += ProtoBufRuntime._encode_enum(_enum_hash, pointer, bs);
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;uint256 i;
    e += 1 + ProtoBufRuntime._sz_lendelim(ProtoBufRuntime._estimate_packed_repeated_int32(r.child_order));
    e += 1 + ProtoBufRuntime._sz_int32(r.child_size);
    e += 1 + ProtoBufRuntime._sz_int32(r.min_prefix_length);
    e += 1 + ProtoBufRuntime._sz_int32(r.max_prefix_length);
    e += 1 + ProtoBufRuntime._sz_lendelim(r.empty_child.length);
    e += 1 + ProtoBufRuntime._sz_enum(PROOFS_PROTO_GLOBAL_ENUMS.encode_HashOp(r.hash));
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.child_order.length != 0) {
    return false;
  }

  if (r.child_size != 0) {
    return false;
  }

  if (r.min_prefix_length != 0) {
    return false;
  }

  if (r.max_prefix_length != 0) {
    return false;
  }

  if (r.empty_child.length != 0) {
    return false;
  }

  if (uint(r.hash) != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.child_order = input.child_order;
    output.child_size = input.child_size;
    output.min_prefix_length = input.min_prefix_length;
    output.max_prefix_length = input.max_prefix_length;
    output.empty_child = input.empty_child;
    output.hash = input.hash;

  }


  //array helpers for ChildOrder
  /**
   * @dev Add value to an array
   * @param self The in-memory struct
   * @param value The value to add
   */
  function addChildOrder(Data memory self, int32  value) internal pure {
    /**
     * First resize the array. Then add the new element to the end.
     */
    int32[] memory tmp = new int32[](self.child_order.length + 1);
    for (uint256 i = 0; i < self.child_order.length; i++) {
      tmp[i] = self.child_order[i];
    }
    tmp[self.child_order.length] = value;
    self.child_order = tmp;
  }


  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23InnerSpec

library Ics23BatchProof {


  //struct definition
  struct Data {
    Ics23BatchEntry.Data[] entries;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[2] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_unpacked_repeated_entries(pointer, bs, nil(), counters);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    pointer = offset;
    if (counters[1] > 0) {
      require(r.entries.length == 0);
      r.entries = new Ics23BatchEntry.Data[](counters[1]);
    }

    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_unpacked_repeated_entries(pointer, bs, r, counters);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }
    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_unpacked_repeated_entries(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[2] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (Ics23BatchEntry.Data memory x, uint256 sz) = _decode_Ics23BatchEntry(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.entries[r.entries.length - counters[1]] = x;
      counters[1] -= 1;
    }
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23BatchEntry(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23BatchEntry.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23BatchEntry.Data memory r, ) = Ics23BatchEntry._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    uint256 i;
    if (r.entries.length != 0) {
    for(i = 0; i < r.entries.length; i++) {
      pointer += ProtoBufRuntime._encode_key(
        1,
        ProtoBufRuntime.WireType.LengthDelim,
        pointer,
        bs)
      ;
      pointer += Ics23BatchEntry._encode_nested(r.entries[i], pointer, bs);
    }
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;uint256 i;
    for(i = 0; i < r.entries.length; i++) {
      e += 1 + ProtoBufRuntime._sz_lendelim(Ics23BatchEntry._estimate(r.entries[i]));
    }
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.entries.length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {

    for(uint256 i1 = 0; i1 < input.entries.length; i1++) {
      output.entries.push(input.entries[i1]);
    }
    

  }


  //array helpers for Entries
  /**
   * @dev Add value to an array
   * @param self The in-memory struct
   * @param value The value to add
   */
  function addEntries(Data memory self, Ics23BatchEntry.Data memory value) internal pure {
    /**
     * First resize the array. Then add the new element to the end.
     */
    Ics23BatchEntry.Data[] memory tmp = new Ics23BatchEntry.Data[](self.entries.length + 1);
    for (uint256 i = 0; i < self.entries.length; i++) {
      tmp[i] = self.entries[i];
    }
    tmp[self.entries.length] = value;
    self.entries = tmp;
  }


  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23BatchProof

library Ics23BatchEntry {


  //struct definition
  struct Data {
    Ics23ExistenceProof.Data exist;
    Ics23NonExistenceProof.Data nonexist;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_exist(pointer, bs, r);
      } else
      if (fieldId == 2) {
        pointer += _read_nonexist(pointer, bs, r);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_exist(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23ExistenceProof.Data memory x, uint256 sz) = _decode_Ics23ExistenceProof(p, bs);
    r.exist = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_nonexist(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23NonExistenceProof.Data memory x, uint256 sz) = _decode_Ics23NonExistenceProof(p, bs);
    r.nonexist = x;
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23ExistenceProof(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23ExistenceProof.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23ExistenceProof.Data memory r, ) = Ics23ExistenceProof._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }

  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23NonExistenceProof(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23NonExistenceProof.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23NonExistenceProof.Data memory r, ) = Ics23NonExistenceProof._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23ExistenceProof._encode_nested(r.exist, pointer, bs);
    
    
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23NonExistenceProof._encode_nested(r.nonexist, pointer, bs);
    
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23ExistenceProof._estimate(r.exist));
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23NonExistenceProof._estimate(r.nonexist));
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    Ics23ExistenceProof.store(input.exist, output.exist);
    Ics23NonExistenceProof.store(input.nonexist, output.nonexist);

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23BatchEntry

library Ics23CompressedBatchProof {


  //struct definition
  struct Data {
    Ics23CompressedBatchEntry.Data[] entries;
    Ics23InnerOp.Data[] lookup_inners;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[3] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_unpacked_repeated_entries(pointer, bs, nil(), counters);
      } else
      if (fieldId == 2) {
        pointer += _read_unpacked_repeated_lookup_inners(pointer, bs, nil(), counters);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    pointer = offset;
    if (counters[1] > 0) {
      require(r.entries.length == 0);
      r.entries = new Ics23CompressedBatchEntry.Data[](counters[1]);
    }
    if (counters[2] > 0) {
      require(r.lookup_inners.length == 0);
      r.lookup_inners = new Ics23InnerOp.Data[](counters[2]);
    }

    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_unpacked_repeated_entries(pointer, bs, r, counters);
      } else
      if (fieldId == 2) {
        pointer += _read_unpacked_repeated_lookup_inners(pointer, bs, r, counters);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }
    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_unpacked_repeated_entries(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (Ics23CompressedBatchEntry.Data memory x, uint256 sz) = _decode_Ics23CompressedBatchEntry(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.entries[r.entries.length - counters[1]] = x;
      counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_unpacked_repeated_lookup_inners(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (Ics23InnerOp.Data memory x, uint256 sz) = _decode_Ics23InnerOp(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.lookup_inners[r.lookup_inners.length - counters[2]] = x;
      counters[2] -= 1;
    }
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23CompressedBatchEntry(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23CompressedBatchEntry.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23CompressedBatchEntry.Data memory r, ) = Ics23CompressedBatchEntry._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }

  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23InnerOp(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23InnerOp.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23InnerOp.Data memory r, ) = Ics23InnerOp._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    uint256 i;
    if (r.entries.length != 0) {
    for(i = 0; i < r.entries.length; i++) {
      pointer += ProtoBufRuntime._encode_key(
        1,
        ProtoBufRuntime.WireType.LengthDelim,
        pointer,
        bs)
      ;
      pointer += Ics23CompressedBatchEntry._encode_nested(r.entries[i], pointer, bs);
    }
    }
    if (r.lookup_inners.length != 0) {
    for(i = 0; i < r.lookup_inners.length; i++) {
      pointer += ProtoBufRuntime._encode_key(
        2,
        ProtoBufRuntime.WireType.LengthDelim,
        pointer,
        bs)
      ;
      pointer += Ics23InnerOp._encode_nested(r.lookup_inners[i], pointer, bs);
    }
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;uint256 i;
    for(i = 0; i < r.entries.length; i++) {
      e += 1 + ProtoBufRuntime._sz_lendelim(Ics23CompressedBatchEntry._estimate(r.entries[i]));
    }
    for(i = 0; i < r.lookup_inners.length; i++) {
      e += 1 + ProtoBufRuntime._sz_lendelim(Ics23InnerOp._estimate(r.lookup_inners[i]));
    }
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.entries.length != 0) {
    return false;
  }

  if (r.lookup_inners.length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {

    for(uint256 i1 = 0; i1 < input.entries.length; i1++) {
      output.entries.push(input.entries[i1]);
    }
    

    for(uint256 i2 = 0; i2 < input.lookup_inners.length; i2++) {
      output.lookup_inners.push(input.lookup_inners[i2]);
    }
    

  }


  //array helpers for Entries
  /**
   * @dev Add value to an array
   * @param self The in-memory struct
   * @param value The value to add
   */
  function addEntries(Data memory self, Ics23CompressedBatchEntry.Data memory value) internal pure {
    /**
     * First resize the array. Then add the new element to the end.
     */
    Ics23CompressedBatchEntry.Data[] memory tmp = new Ics23CompressedBatchEntry.Data[](self.entries.length + 1);
    for (uint256 i = 0; i < self.entries.length; i++) {
      tmp[i] = self.entries[i];
    }
    tmp[self.entries.length] = value;
    self.entries = tmp;
  }

  //array helpers for LookupInners
  /**
   * @dev Add value to an array
   * @param self The in-memory struct
   * @param value The value to add
   */
  function addLookupInners(Data memory self, Ics23InnerOp.Data memory value) internal pure {
    /**
     * First resize the array. Then add the new element to the end.
     */
    Ics23InnerOp.Data[] memory tmp = new Ics23InnerOp.Data[](self.lookup_inners.length + 1);
    for (uint256 i = 0; i < self.lookup_inners.length; i++) {
      tmp[i] = self.lookup_inners[i];
    }
    tmp[self.lookup_inners.length] = value;
    self.lookup_inners = tmp;
  }


  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23CompressedBatchProof

library Ics23CompressedBatchEntry {


  //struct definition
  struct Data {
    Ics23CompressedExistenceProof.Data exist;
    Ics23CompressedNonExistenceProof.Data nonexist;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_exist(pointer, bs, r);
      } else
      if (fieldId == 2) {
        pointer += _read_nonexist(pointer, bs, r);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_exist(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23CompressedExistenceProof.Data memory x, uint256 sz) = _decode_Ics23CompressedExistenceProof(p, bs);
    r.exist = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_nonexist(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23CompressedNonExistenceProof.Data memory x, uint256 sz) = _decode_Ics23CompressedNonExistenceProof(p, bs);
    r.nonexist = x;
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23CompressedExistenceProof(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23CompressedExistenceProof.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23CompressedExistenceProof.Data memory r, ) = Ics23CompressedExistenceProof._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }

  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23CompressedNonExistenceProof(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23CompressedNonExistenceProof.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23CompressedNonExistenceProof.Data memory r, ) = Ics23CompressedNonExistenceProof._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23CompressedExistenceProof._encode_nested(r.exist, pointer, bs);
    
    
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23CompressedNonExistenceProof._encode_nested(r.nonexist, pointer, bs);
    
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23CompressedExistenceProof._estimate(r.exist));
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23CompressedNonExistenceProof._estimate(r.nonexist));
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    Ics23CompressedExistenceProof.store(input.exist, output.exist);
    Ics23CompressedNonExistenceProof.store(input.nonexist, output.nonexist);

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23CompressedBatchEntry

library Ics23CompressedExistenceProof {


  //struct definition
  struct Data {
    bytes key;
    bytes value;
    Ics23LeafOp.Data leaf;
    int32[] path;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[5] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_key(pointer, bs, r);
      } else
      if (fieldId == 2) {
        pointer += _read_value(pointer, bs, r);
      } else
      if (fieldId == 3) {
        pointer += _read_leaf(pointer, bs, r);
      } else
      if (fieldId == 4) {
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          pointer += _read_packed_repeated_path(pointer, bs, r);
        } else {
          pointer += _read_unpacked_repeated_path(pointer, bs, nil(), counters);
        }
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    pointer = offset;
    if (counters[4] > 0) {
      require(r.path.length == 0);
      r.path = new int32[](counters[4]);
    }

    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 4 && wireType != ProtoBufRuntime.WireType.LengthDelim) {
        pointer += _read_unpacked_repeated_path(pointer, bs, r, counters);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }
    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_key(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    r.key = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_value(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    r.value = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_leaf(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23LeafOp.Data memory x, uint256 sz) = _decode_Ics23LeafOp(p, bs);
    r.leaf = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_unpacked_repeated_path(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[5] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
    if (isNil(r)) {
      counters[4] += 1;
    } else {
      r.path[r.path.length - counters[4]] = x;
      counters[4] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_packed_repeated_path(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (uint256 len, uint256 size) = ProtoBufRuntime._decode_varint(p, bs);
    p += size;
    uint256 count = ProtoBufRuntime._count_packed_repeated_varint(p, len, bs);
    r.path = new int32[](count);
    for (uint256 i = 0; i < count; i++) {
      (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
      p += sz;
      r.path[i] = x;
    }
    return size + len;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23LeafOp(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23LeafOp.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23LeafOp.Data memory r, ) = Ics23LeafOp._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    uint256 i;
    if (r.key.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.key, pointer, bs);
    }
    if (r.value.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.value, pointer, bs);
    }
    
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23LeafOp._encode_nested(r.leaf, pointer, bs);
    
    if (r.path.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      4,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_varint(
      ProtoBufRuntime._estimate_packed_repeated_int32(r.path),
      pointer,
      bs
    );
    for(i = 0; i < r.path.length; i++) {
      pointer += ProtoBufRuntime._encode_int32(r.path[i], pointer, bs);
    }
    }
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;uint256 i;
    e += 1 + ProtoBufRuntime._sz_lendelim(r.key.length);
    e += 1 + ProtoBufRuntime._sz_lendelim(r.value.length);
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23LeafOp._estimate(r.leaf));
    e += 1 + ProtoBufRuntime._sz_lendelim(ProtoBufRuntime._estimate_packed_repeated_int32(r.path));
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.key.length != 0) {
    return false;
  }

  if (r.value.length != 0) {
    return false;
  }

  if (r.path.length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.key = input.key;
    output.value = input.value;
    Ics23LeafOp.store(input.leaf, output.leaf);
    output.path = input.path;

  }


  //array helpers for Path
  /**
   * @dev Add value to an array
   * @param self The in-memory struct
   * @param value The value to add
   */
  function addPath(Data memory self, int32  value) internal pure {
    /**
     * First resize the array. Then add the new element to the end.
     */
    int32[] memory tmp = new int32[](self.path.length + 1);
    for (uint256 i = 0; i < self.path.length; i++) {
      tmp[i] = self.path[i];
    }
    tmp[self.path.length] = value;
    self.path = tmp;
  }


  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23CompressedExistenceProof

library Ics23CompressedNonExistenceProof {


  //struct definition
  struct Data {
    bytes key;
    Ics23CompressedExistenceProof.Data left;
    Ics23CompressedExistenceProof.Data right;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_key(pointer, bs, r);
      } else
      if (fieldId == 2) {
        pointer += _read_left(pointer, bs, r);
      } else
      if (fieldId == 3) {
        pointer += _read_right(pointer, bs, r);
      } else
      {
        pointer += ProtoBufRuntime._skip_field_decode(wireType, pointer, bs);
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_key(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    r.key = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_left(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23CompressedExistenceProof.Data memory x, uint256 sz) = _decode_Ics23CompressedExistenceProof(p, bs);
    r.left = x;
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_right(
    uint256 p,
    bytes memory bs,
    Data memory r
  ) internal pure returns (uint) {
    (Ics23CompressedExistenceProof.Data memory x, uint256 sz) = _decode_Ics23CompressedExistenceProof(p, bs);
    r.right = x;
    return sz;
  }

  // struct decoder
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function _decode_Ics23CompressedExistenceProof(uint256 p, bytes memory bs)
    internal
    pure
    returns (Ics23CompressedExistenceProof.Data memory, uint)
  {
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    (Ics23CompressedExistenceProof.Data memory r, ) = Ics23CompressedExistenceProof._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;
    
    if (r.key.length != 0) {
    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.key, pointer, bs);
    }
    
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23CompressedExistenceProof._encode_nested(r.left, pointer, bs);
    
    
    pointer += ProtoBufRuntime._encode_key(
      3,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += Ics23CompressedExistenceProof._encode_nested(r.right, pointer, bs);
    
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(r.key.length);
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23CompressedExistenceProof._estimate(r.left));
    e += 1 + ProtoBufRuntime._sz_lendelim(Ics23CompressedExistenceProof._estimate(r.right));
    return e;
  }
  // empty checker

  function _empty(
    Data memory r
  ) internal pure returns (bool) {
    
  if (r.key.length != 0) {
    return false;
  }

    return true;
  }


  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.key = input.key;
    Ics23CompressedExistenceProof.store(input.left, output.left);
    Ics23CompressedExistenceProof.store(input.right, output.right);

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Ics23CompressedNonExistenceProof

library PROOFS_PROTO_GLOBAL_ENUMS {

  //enum definition
  // Solidity enum definitions
  enum HashOp {
    NO_HASH,
    SHA256,
    SHA512,
    KECCAK,
    RIPEMD160,
    BITCOIN,
    SHA512_256
  }


  // Solidity enum encoder
  function encode_HashOp(HashOp x) internal pure returns (int32) {
    
    if (x == HashOp.NO_HASH) {
      return 0;
    }

    if (x == HashOp.SHA256) {
      return 1;
    }

    if (x == HashOp.SHA512) {
      return 2;
    }

    if (x == HashOp.KECCAK) {
      return 3;
    }

    if (x == HashOp.RIPEMD160) {
      return 4;
    }

    if (x == HashOp.BITCOIN) {
      return 5;
    }

    if (x == HashOp.SHA512_256) {
      return 6;
    }
    revert();
  }


  // Solidity enum decoder
  function decode_HashOp(int64 x) internal pure returns (HashOp) {
    
    if (x == 0) {
      return HashOp.NO_HASH;
    }

    if (x == 1) {
      return HashOp.SHA256;
    }

    if (x == 2) {
      return HashOp.SHA512;
    }

    if (x == 3) {
      return HashOp.KECCAK;
    }

    if (x == 4) {
      return HashOp.RIPEMD160;
    }

    if (x == 5) {
      return HashOp.BITCOIN;
    }

    if (x == 6) {
      return HashOp.SHA512_256;
    }
    revert();
  }


  /**
   * @dev The estimator for an packed enum array
   * @return The number of bytes encoded
   */
  function estimate_packed_repeated_HashOp(
    HashOp[] memory a
  ) internal pure returns (uint256) {
    uint256 e = 0;
    for (uint i = 0; i < a.length; i++) {
      e += ProtoBufRuntime._sz_enum(encode_HashOp(a[i]));
    }
    return e;
  }

  // Solidity enum definitions
  enum LengthOp {
    NO_PREFIX,
    VAR_PROTO,
    VAR_RLP,
    FIXED32_BIG,
    FIXED32_LITTLE,
    FIXED64_BIG,
    FIXED64_LITTLE,
    REQUIRE_32_BYTES,
    REQUIRE_64_BYTES
  }


  // Solidity enum encoder
  function encode_LengthOp(LengthOp x) internal pure returns (int32) {
    
    if (x == LengthOp.NO_PREFIX) {
      return 0;
    }

    if (x == LengthOp.VAR_PROTO) {
      return 1;
    }

    if (x == LengthOp.VAR_RLP) {
      return 2;
    }

    if (x == LengthOp.FIXED32_BIG) {
      return 3;
    }

    if (x == LengthOp.FIXED32_LITTLE) {
      return 4;
    }

    if (x == LengthOp.FIXED64_BIG) {
      return 5;
    }

    if (x == LengthOp.FIXED64_LITTLE) {
      return 6;
    }

    if (x == LengthOp.REQUIRE_32_BYTES) {
      return 7;
    }

    if (x == LengthOp.REQUIRE_64_BYTES) {
      return 8;
    }
    revert();
  }


  // Solidity enum decoder
  function decode_LengthOp(int64 x) internal pure returns (LengthOp) {
    
    if (x == 0) {
      return LengthOp.NO_PREFIX;
    }

    if (x == 1) {
      return LengthOp.VAR_PROTO;
    }

    if (x == 2) {
      return LengthOp.VAR_RLP;
    }

    if (x == 3) {
      return LengthOp.FIXED32_BIG;
    }

    if (x == 4) {
      return LengthOp.FIXED32_LITTLE;
    }

    if (x == 5) {
      return LengthOp.FIXED64_BIG;
    }

    if (x == 6) {
      return LengthOp.FIXED64_LITTLE;
    }

    if (x == 7) {
      return LengthOp.REQUIRE_32_BYTES;
    }

    if (x == 8) {
      return LengthOp.REQUIRE_64_BYTES;
    }
    revert();
  }


  /**
   * @dev The estimator for an packed enum array
   * @return The number of bytes encoded
   */
  function estimate_packed_repeated_LengthOp(
    LengthOp[] memory a
  ) internal pure returns (uint256) {
    uint256 e = 0;
    for (uint i = 0; i < a.length; i++) {
      e += ProtoBufRuntime._sz_enum(encode_LengthOp(a[i]));
    }
    return e;
  }
}
//library PROOFS_PROTO_GLOBAL_ENUMS

// SPDX-License-Identifier: MIT
// added by us
pragma solidity ^0.8.10;

import "./proofs.sol";


library Ics23ProofSpecs {
  function iavlSpec() internal pure returns (Ics23ProofSpec.Data memory spec) {
    spec = Ics23ProofSpec.decode(
      hex"0a090801180120012a0100120c0a02000110211804200c3001"
    );
  }

  function tendermintSpec() internal pure returns (Ics23ProofSpec.Data memory spec) {
    spec = Ics23ProofSpec.decode(
      hex"0a090801180120012a0100120c0a0200011020180120013001"
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ics23} from "./ics23/ics23.sol";
import {Ics23CommitmentProof, Ics23ProofSpec} from "./ics23/proofs.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// simple wrapper around Ics23 library
contract OmniProofs is Initializable {

    constructor() initializer {}

    function initialize() public initializer {}

    function ics23VerifyMembership(
        Ics23ProofSpec.Data memory _spec,
        bytes memory _root,
        Ics23CommitmentProof.Data memory _proof,
        bytes memory _key,
        bytes memory _value
    ) external pure returns (Ics23.VerifyMembershipError) {
        return Ics23.verifyMembership(_spec, _root, _proof, _key, _value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

import {
    Ics23InnerOp, Ics23ExistenceProof, Ics23NonExistenceProof, Ics23CommitmentProof, Ics23CompressedBatchEntry, Ics23CompressedBatchProof,
    Ics23CompressedExistenceProof, Ics23BatchEntry, Ics23BatchProof
} from "./proofs.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

library Compress {
    /**
      @notice will return a Ics23BatchProof if the input is CompressedBatchProof. Otherwise it will return the input.
      This is safe to call multiple times (idempotent)
    */
    function decompress(
        Ics23CommitmentProof.Data memory proof
    ) internal pure returns(Ics23CommitmentProof.Data memory, DecompressEntryError) {
        //Ics23CompressedBatchProof.isNil() does not work
        if (Ics23CompressedBatchProof._empty(proof.compressed) == true){
            return (proof, DecompressEntryError.None);
        }
        (Ics23BatchEntry.Data[] memory entries, DecompressEntryError erCode) = decompress(proof.compressed);
        if (erCode != DecompressEntryError.None) return (Ics23CommitmentProof.nil(), erCode);
        Ics23CommitmentProof.Data memory retVal;
        retVal.exist = Ics23ExistenceProof.nil();
        retVal.nonexist = Ics23NonExistenceProof.nil();
        retVal.compressed = Ics23CompressedBatchProof.nil();
        retVal.batch.entries = entries;
        return (retVal, DecompressEntryError.None);
    }

    function decompress(
        Ics23CompressedBatchProof.Data memory proof
    ) private pure returns(Ics23BatchEntry.Data[] memory, DecompressEntryError) {
        Ics23BatchEntry.Data[] memory entries = new Ics23BatchEntry.Data[](proof.entries.length);
        for(uint i = 0; i < proof.entries.length; i++) {
            (Ics23BatchEntry.Data memory entry, DecompressEntryError erCode) = decompressEntry(proof.entries[i], proof.lookup_inners);
            if (erCode != DecompressEntryError.None) return (entries, erCode);
            entries[i] = entry;
        }
        return (entries, DecompressEntryError.None);
    }

    enum DecompressEntryError{
        None,
        ExistDecompress,
        LeftDecompress,
        RightDecompress
    }
    function decompressEntry(
        Ics23CompressedBatchEntry.Data memory entry,
        Ics23InnerOp.Data[] memory lookup
    ) private pure returns(Ics23BatchEntry.Data memory, DecompressEntryError) {
        //Ics23CompressedExistenceProof.isNil does not work
        if (Ics23CompressedExistenceProof._empty(entry.exist) == false) {
            (Ics23ExistenceProof.Data memory exist, DecompressExistError existErCode) = decompressExist(entry.exist, lookup);
            if (existErCode != DecompressExistError.None) return(Ics23BatchEntry.nil(), DecompressEntryError.ExistDecompress);
            return (Ics23BatchEntry.Data({
                exist: exist,
                nonexist: Ics23NonExistenceProof.nil()
            }), DecompressEntryError.None);
        }
        (Ics23ExistenceProof.Data memory left, DecompressExistError leftErCode) = decompressExist(entry.nonexist.left, lookup);
        if (leftErCode != DecompressExistError.None) return(Ics23BatchEntry.nil(), DecompressEntryError.LeftDecompress);
        (Ics23ExistenceProof.Data memory right, DecompressExistError rightErCode) = decompressExist(entry.nonexist.right, lookup);
        if (rightErCode != DecompressExistError.None) return(Ics23BatchEntry.nil(), DecompressEntryError.RightDecompress);
        return (Ics23BatchEntry.Data({
            exist: Ics23ExistenceProof.nil(),
            nonexist: Ics23NonExistenceProof.Data({
                key: entry.nonexist.key,
                left: left,
                right: right
            })
        }), DecompressEntryError.None);
    }

    enum DecompressExistError{
        None,
        PathLessThanZero,
        StepGreaterOrEqualToLength
    }
    function decompressExist(
        Ics23CompressedExistenceProof.Data memory proof,
        Ics23InnerOp.Data[] memory lookup
    ) private pure returns(Ics23ExistenceProof.Data memory, DecompressExistError) {
        if (Ics23CompressedExistenceProof._empty(proof)) {
            return (Ics23ExistenceProof.nil(), DecompressExistError.None);
        }
        Ics23ExistenceProof.Data memory decoProof = Ics23ExistenceProof.Data({
            key: proof.key,
            value: proof.value,
            leaf: proof.leaf,
            path : new Ics23InnerOp.Data[](proof.path.length)
        });
        for (uint i = 0; i < proof.path.length; i++) {
            //require(proof.path[i] >= 0); // dev: proof.path < 0
            if (proof.path[i] < 0) return (Ics23ExistenceProof.nil(), DecompressExistError.PathLessThanZero);
            uint step = SafeCast.toUint256(proof.path[i]);
            //require(step < lookup.length); // dev: step >= lookup.length
            if (step >= lookup.length) return (Ics23ExistenceProof.nil(), DecompressExistError.StepGreaterOrEqualToLength);
            decoProof.path[i] = lookup[step];
        }
        return (decoProof, DecompressExistError.None);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

import {
    Ics23LeafOp, Ics23CompressedBatchProof, Ics23ExistenceProof, Ics23NonExistenceProof, Ics23BatchEntry, Ics23BatchProof,
    Ics23ProofSpec, Ics23InnerOp, Ics23InnerSpec, Ics23CommitmentProof
} from "./proofs.sol";
import {Ops} from "./ics23Ops.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";
import {Compress} from "./ics23Compress.sol";
import {Ops} from "./ics23Ops.sol";

library Proof{
    bytes constant empty = new bytes(0);

    enum VerifyExistenceError{
        None,
        KeyNotMatching,
        ValueNotMatching,
        CheckSpec,
        CalculateRoot,
        RootNotMatching
    }
    /**
    @notice verify does all checks to ensure this proof proves this key, value -> root and matches the spec.
    @return VerifyExistenceError enum giving indication of where error happened, None if verification succeded
        */
    function verify(
        Ics23ExistenceProof.Data memory proof,
        Ics23ProofSpec.Data memory spec,
        bytes memory commitmentRoot,
        bytes memory key,
        bytes memory value
    ) internal pure returns(VerifyExistenceError) {
        //require(BytesLib.equal(proof.key, key)); // dev: Provided key doesn't match proof
        bool keyMatch = BytesLib.equal(proof.key, key);
        if (keyMatch == false) return VerifyExistenceError.KeyNotMatching;
        //require(BytesLib.equal(proof.value, value)); // dev: Provided value doesn't match proof
        bool valueMatch = BytesLib.equal(proof.value, value);
        if (valueMatch == false) return VerifyExistenceError.ValueNotMatching;
        CheckAgainstSpecError cCode = checkAgainstSpec(proof, spec);
        if (cCode != CheckAgainstSpecError.None) return VerifyExistenceError.CheckSpec;
        (bytes memory root, CalculateRootError rCode) = calculateRoot(proof);
        if (rCode != CalculateRootError.None) return VerifyExistenceError.CalculateRoot;
        //require(BytesLib.equal(root, commitmentRoot)); // dev: Calculcated root doesn't match provided root
        bool rootMatch = BytesLib.equal(root, commitmentRoot);
        if (rootMatch == false) return VerifyExistenceError.RootNotMatching;

        return VerifyExistenceError.None;
    }

    enum CalculateRootError {
        None,
        LeafNil,
        LeafOp,
        PathOp,
        BatchEntriesLength,
        BatchEntryEmpty,
        EmptyProof,
        Decompress
    }
    /**
    @notice calculateRoot determines the root hash that matches the given proof. You must validate the result in what you have in a header.
    @return CalculateRootError enum giving indication of where error happened, None if verification succeded
        */
    function calculateRoot(Ics23ExistenceProof.Data memory proof) internal pure returns(bytes memory, CalculateRootError) {
        //require(Ics23LeafOp.isNil(proof.leaf) == false); // dev: Existence Proof needs defined Ics23LeafOp
        if (Ics23LeafOp.isNil(proof.leaf)) return (empty, CalculateRootError.LeafNil);
        (bytes memory root, Ops.ApplyLeafOpError lCode) = Ops.applyOp(proof.leaf, proof.key, proof.value);
        if (lCode != Ops.ApplyLeafOpError.None) return (empty, CalculateRootError.LeafOp);
        for (uint i = 0; i < proof.path.length; i++) {
            Ops.ApplyInnerOpError iCode;
            (root, iCode) = Ops.applyOp(proof.path[i], root);
            if (iCode != Ops.ApplyInnerOpError.None) return (empty, CalculateRootError.PathOp);
        }

        return (root, CalculateRootError.None);
    }

    enum CheckAgainstSpecError{
        None,
        EmptyLeaf,
        OpsCheckAgainstSpec,
        InnerOpsDepthTooShort,
        InnerOpsDepthTooLong
    }
    /**
    @notice checkAgainstSpec will verify the leaf and all path steps are in the format defined in spec
    @return CheckAgainstSpecError enum giving indication of where error happened, None if verification succeded
        */
    function checkAgainstSpec(
        Ics23ExistenceProof.Data memory proof,
        Ics23ProofSpec.Data memory spec
    ) internal pure returns(CheckAgainstSpecError) {
        // Ics23LeafOp.isNil does not work
        //require(Ics23LeafOp._empty(proof.leaf) == false); // dev: Existence Proof needs defined Ics23LeafOp
        if (Ics23LeafOp._empty(proof.leaf)) return CheckAgainstSpecError.EmptyLeaf;
        Ops.CheckAgainstSpecError cCode = Ops.checkAgainstSpec(proof.leaf, spec);
        if (cCode != Ops.CheckAgainstSpecError.None) return CheckAgainstSpecError.OpsCheckAgainstSpec;
        if (spec.min_depth > 0) {
            bool innerOpsDepthTooShort = proof.path.length < SafeCast.toUint256(int256(spec.min_depth));
            //require(innerOpsDepthTooShort == false); // dev: InnerOps depth too short
            if (innerOpsDepthTooShort) return CheckAgainstSpecError.InnerOpsDepthTooShort;
        }
        if (spec.max_depth > 0) {
            bool innerOpsDepthTooLong = proof.path.length > SafeCast.toUint256(int256(spec.max_depth));
            //require(innerOpsDepthTooLong == false); // dev: InnerOps depth too long
            if (innerOpsDepthTooLong) return CheckAgainstSpecError.InnerOpsDepthTooLong;
        }
        for(uint i = 0; i < proof.path.length; i++) {
            Ops.CheckAgainstSpecError opscCode = Ops.checkAgainstSpec(proof.path[i], spec);
            if (opscCode != Ops.CheckAgainstSpecError.None) return CheckAgainstSpecError.OpsCheckAgainstSpec;
        }
    }

    enum VerifyNonExistenceError {
        None,
        VerifyLeft,
        VerifyRight,
        LeftAndRightKeyEmpty,
        RightKeyRange,
        LeftKeyRange,
        RightProofLeftMost,
        LeftProofRightMost,
        IsLeftNeighbor
    }
    /**
    @notice verify does all checks to ensure the proof has valid non-existence proofs,
    and they ensure the given key is not in the CommitmentState
    @return VerifyNonExistenceError enum giving indication of where error happened, None if verification succeded
        */
    function verify(
        Ics23NonExistenceProof.Data memory proof,
        Ics23ProofSpec.Data memory spec,
        bytes memory commitmentRoot,
        bytes memory key
    ) internal pure returns(VerifyNonExistenceError) {
        bytes memory leftKey;
        bytes memory rightKey;
        // Ics23ExistenceProof.isNil does not work
        if (Ics23ExistenceProof._empty(proof.left) == false) {
            VerifyExistenceError eCode = verify(proof.left, spec, commitmentRoot, proof.left.key, proof.left.value);
            if (eCode != VerifyExistenceError.None) return VerifyNonExistenceError.VerifyLeft;

            leftKey = proof.left.key;
        }
        if (Ics23ExistenceProof._empty(proof.right) == false) {
            VerifyExistenceError eCode = verify(proof.right, spec, commitmentRoot, proof.right.key, proof.right.value);
            if (eCode != VerifyExistenceError.None) return VerifyNonExistenceError.VerifyRight;

            rightKey = proof.right.key;
        }
        // If both proofs are missing, this is not a valid proof
        //require(leftKey.length > 0 || rightKey.length > 0); // dev: both left and right proofs missing
        if (leftKey.length == 0 && rightKey.length == 0) return VerifyNonExistenceError.LeftAndRightKeyEmpty;
        // Ensure in valid range
        if (rightKey.length > 0 && Ops.compare(key, rightKey) >= 0) {
            //require(Ops.compare(key, rightKey) < 0); // dev: key is not left of right proof
            return VerifyNonExistenceError.RightKeyRange;
        }
        if (leftKey.length > 0 && Ops.compare(key, leftKey) <= 0) {
            //require(Ops.compare(key, leftKey) > 0); // dev: key is not right of left proof
            return VerifyNonExistenceError.LeftKeyRange;
        }
        if (leftKey.length == 0) {
            //require(isLeftMost(spec.inner_spec, proof.right.path)); // dev: left proof missing, right proof must be left-most
            if(isLeftMost(spec.inner_spec, proof.right.path) == false) return VerifyNonExistenceError.RightProofLeftMost;
        } else if (rightKey.length == 0) {
            //require(isRightMost(spec.inner_spec, proof.left.path)); // dev: isRightMost: right proof missing, left proof must be right-most
            if (isRightMost(spec.inner_spec, proof.left.path) == false) return VerifyNonExistenceError.LeftProofRightMost;
        } else {
            //require(isLeftNeighbor(spec.inner_spec, proof.left.path, proof.right.path)); // dev: isLeftNeighbor: right proof missing, left proof must be right-most
            bool isLeftNeigh = isLeftNeighbor(spec.inner_spec, proof.left.path, proof.right.path);
            if (isLeftNeigh == false) return VerifyNonExistenceError.IsLeftNeighbor;
        }

        return VerifyNonExistenceError.None;
    }

    /**
    @notice calculateRoot determines the root hash that matches the given proof. You must validate the result in what you have in a header.
    @return CalculateRootError enum giving indication of where error happened, None if verification succeded
        */
    function calculateRoot(Ics23NonExistenceProof.Data memory proof) internal pure returns(bytes memory, CalculateRootError) {
        if (Ics23ExistenceProof._empty(proof.left) == false) {
            return calculateRoot(proof.left);
        }
        if (Ics23ExistenceProof._empty(proof.right) == false) {
            return calculateRoot(proof.right);
        }
        //revert(); // dev: Nonexistence proof has empty Left and Right proof
        return (empty, CalculateRootError.EmptyProof);
    }

    /**
    @notice calculateRoot determines the root hash that matches the given proof by switching and calculating root based on proof type
    NOTE: Calculate will return the first calculated root in the proof, you must validate that all other embedded ExistenceProofs
    commit to the same root. This can be done with the Verify method
    @return CalculateRootError enum giving indication of where error happened, None if verification succeded
        */
    function calculateRoot(Ics23CommitmentProof.Data memory proof) internal pure returns(bytes memory, CalculateRootError) {
        if (Ics23ExistenceProof._empty(proof.exist) == false) {
            return calculateRoot(proof.exist);
        }
        if (Ics23NonExistenceProof._empty(proof.nonexist) == false) {
            return calculateRoot(proof.nonexist);
        }
        if (Ics23BatchProof._empty(proof.batch) == false) {
            //require(proof.batch.entries.length > 0); // dev: batch proof has no entry
            if (proof.batch.entries.length == 0) return (empty, CalculateRootError.BatchEntriesLength);
            //require(Ics23BatchEntry._empty(proof.batch.entries[0]) == false); // dev: batch proof has empty entry
            if (Ics23BatchEntry._empty(proof.batch.entries[0])) return (empty, CalculateRootError.BatchEntryEmpty);
            if (Ics23ExistenceProof._empty(proof.batch.entries[0].exist) == false) {
                return calculateRoot(proof.batch.entries[0].exist);
            }
            if (Ics23NonExistenceProof._empty(proof.batch.entries[0].nonexist) == false) {
                return calculateRoot(proof.batch.entries[0].nonexist);
            }
        }
        if (Ics23CompressedBatchProof._empty(proof.compressed) == false) {
            (Ics23CommitmentProof.Data memory proof, Compress.DecompressEntryError erCode) = Compress.decompress(proof);
            if (erCode != Compress.DecompressEntryError.None) return (empty, CalculateRootError.Decompress);
            return calculateRoot(proof);
        }
        //revert(); // dev: calculateRoot(CommitmentProof) empty proof
        return (empty, CalculateRootError.EmptyProof);
    }


    /**
    @return true if this is the left-most path in the tree
    */
    function isLeftMost(Ics23InnerSpec.Data memory spec, Ics23InnerOp.Data[] memory path) private pure returns(bool) {
        (uint minPrefix, uint maxPrefix, uint suffix, GetPaddingError gCode) = getPadding(spec, 0);
        if (gCode != GetPaddingError.None) return false;
        for (uint i = 0; i < path.length; i++) {
            if (hasPadding(path[i], minPrefix, maxPrefix, suffix) == false){
                return false;
            }
        }
        return true;
    }

    /**
    @return true if this is the right-most path in the tree
    */
    function isRightMost(Ics23InnerSpec.Data memory spec, Ics23InnerOp.Data[] memory path) private pure returns(bool){
        uint last = spec.child_order.length - 1;
        (uint minPrefix, uint maxPrefix, uint suffix, GetPaddingError gCode) = getPadding(spec, last);
        if (gCode != GetPaddingError.None) return false;
        for (uint i = 0; i < path.length; i++) {
            if (hasPadding(path[i], minPrefix, maxPrefix, suffix) == false){
                return false;
            }
        }

        return true;
    }

    /**
    @notice assumes left and right have common parents checks if left is exactly one slot to the left of right
    */
    function isLeftStep(
        Ics23InnerSpec.Data memory spec,
        Ics23InnerOp.Data memory left,
        Ics23InnerOp.Data memory right
    ) private pure returns(bool){
        (uint leftIdx, OrderFromPaddingError lCode) = orderFromPadding(spec, left);
        if (lCode != OrderFromPaddingError.None) return false;
        (uint rightIdx, OrderFromPaddingError rCode) = orderFromPadding(spec, right);
        if (lCode != OrderFromPaddingError.None) return false;
        if (rCode != OrderFromPaddingError.None) return false;

        return rightIdx == leftIdx + 1;
    }

    /**
    @notice find the common suffix from the Left.Path and Right.Path and remove it. We have LPath and RPath now, which must be neighbors.
    Validate that LPath[len-1] is the left neighbor of RPath[len-1]
    For step in LPath[0..len-1], validate step is right-most node
    For step in RPath[0..len-1], validate step is left-most node
     */
    function isLeftNeighbor(
        Ics23InnerSpec.Data memory spec,
        Ics23InnerOp.Data[] memory left,
        Ics23InnerOp.Data[] memory right
    ) private pure returns(bool) {
        uint leftIdx = left.length - 1;
        uint rightIdx = right.length - 1;
        while (leftIdx >= 0 && rightIdx >= 0) {
            if (BytesLib.equal(left[leftIdx].prefix, right[rightIdx].prefix) &&
                BytesLib.equal(left[leftIdx].suffix, right[rightIdx].suffix)) {
                leftIdx -= 1;
            rightIdx -= 1;
            continue;
            }
            break;
        }
        if (isLeftStep(spec, left[leftIdx], right[rightIdx]) == false) {
            return false;
        }
        // slicing does not work for ``memory`` types
        if (isRightMost(spec, sliceInnerOps(left, 0, leftIdx)) == false){
            return false;
        }
        if (isLeftMost(spec, sliceInnerOps(right, 0, rightIdx)) == false) {
            return false;
        }
        return true;
    }

    enum OrderFromPaddingError {
        None,
        NotFound,
        GetPadding
    }
    /**
    @notice this will look at the proof and determine which order it is... So we can see if it is branch 0, 1, 2 etc... to determine neighbors
    */
    function orderFromPadding(
        Ics23InnerSpec.Data memory spec,
        Ics23InnerOp.Data memory op
    ) private pure returns(uint, OrderFromPaddingError) {
        uint256 maxBranch = spec.child_order.length;
        for(uint branch = 0; branch < maxBranch; branch++) {
            (uint minp, uint maxp, uint suffix, GetPaddingError gCode) = getPadding(spec, branch);
            if (gCode != GetPaddingError.None) return (0, OrderFromPaddingError.GetPadding);
            if (hasPadding(op, minp, maxp, suffix) == true) return (branch, OrderFromPaddingError.None);
        }
        //revert(); // dev: Cannot find any valid spacing for this node
        return (0, OrderFromPaddingError.NotFound);
    }

    enum GetPaddingError {
        None,
        GetPosition
    }
    /**
    @notice determines prefix and suffix with the given spec and position in the tree
    */
    function getPadding(
        Ics23InnerSpec.Data memory spec,
        uint branch
    ) private pure returns(uint minPrefix, uint maxPrefix, uint suffix, GetPaddingError) {
        uint uChildSize = SafeCast.toUint256(spec.child_size);
        (uint idx, GetPositionError gCode) = getPosition(spec.child_order, branch);
        if (gCode != GetPositionError.None) return (0, 0, 0, GetPaddingError.GetPosition);
        uint prefix = idx * uChildSize;
        minPrefix = prefix + SafeCast.toUint256(spec.min_prefix_length);
        maxPrefix = prefix + SafeCast.toUint256(spec.max_prefix_length);
        suffix = (spec.child_order.length - 1 - idx) * uChildSize;

        return (minPrefix, maxPrefix, suffix, GetPaddingError.None);
    }

    enum GetPositionError {
        None,
        BranchLength,
        NoFound
    }
    /**
    @notice checks where the branch is in the order and returns the index of this branch
    @return GetPositionError enum giving indication of where error happened, None if verification succeded
        */
    function getPosition(int32[] memory order, uint branch) private pure returns(uint, GetPositionError) {
        //require(branch < order.length); // dev: invalid branch
        if (branch >= order.length) return (0, GetPositionError.BranchLength);
        for (uint i = 0; i < order.length; i++) {
            if (SafeCast.toUint256(order[i]) == branch) return (i, GetPositionError.None);
        }
        //revert(); // dev: branch not found in order
        return (0, GetPositionError.NoFound);
    }

    function hasPadding(Ics23InnerOp.Data memory op, uint minPrefix, uint maxPrefix, uint suffix) private pure returns(bool) {
        if (op.prefix.length < minPrefix) return false;
        if (op.prefix.length > maxPrefix) return false;
        return op.suffix.length == suffix;
    }

    /**
    @return a slice of of InnerOp.Data, array[start..end]
    */
    function sliceInnerOps(Ics23InnerOp.Data[] memory array, uint start, uint end) private pure returns(Ics23InnerOp.Data[] memory) {
        Ics23InnerOp.Data[] memory slice = new Ics23InnerOp.Data[](end-start);
        for (uint i = start; i < end; i++) {
            slice[i] = array[i];
        }
        return slice;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

import {Ics23LeafOp, Ics23InnerOp, PROOFS_PROTO_GLOBAL_ENUMS, Ics23ProofSpec} from "./proofs.sol";
import {ProtoBufRuntime} from "./ProtoBufRuntime.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

library Ops {
    bytes constant empty = new bytes(0);

    enum ApplyLeafOpError {
        None,
        KeyLength,
        ValueLength,
        DoHash,
        PrepareLeafData
    }
    /**
    @notice calculates the leaf hash given the key and value being proven
    @return VerifyExistenceError enum giving indication of where error happened, None if verification succeded
        */
    function applyOp(
        Ics23LeafOp.Data memory leafOp,
        bytes memory key,
        bytes memory value
    ) internal pure returns(bytes memory, ApplyLeafOpError) {
        //require(key.length > 0); // dev: Leaf op needs key
        if (key.length == 0) return (empty, ApplyLeafOpError.KeyLength);
        //require(value.length > 0); // dev: Leaf op needs value
        if (value.length == 0) return (empty, ApplyLeafOpError.ValueLength);
        (bytes memory pKey, PrepareLeafDataError pCode1) = prepareLeafData(leafOp.prehash_key, leafOp.length, key);
        if (pCode1 != PrepareLeafDataError.None) return (empty, ApplyLeafOpError.PrepareLeafData);
        (bytes memory pValue, PrepareLeafDataError pCode2) = prepareLeafData(leafOp.prehash_value, leafOp.length, value);
        if (pCode2 != PrepareLeafDataError.None) return (empty, ApplyLeafOpError.PrepareLeafData);
        bytes memory data = abi.encodePacked(leafOp.prefix, pKey, pValue);
        (bytes memory hashed, DoHashError hCode) = doHash(leafOp.hash, data);
        if (hCode != DoHashError.None) return (empty, ApplyLeafOpError.DoHash);
        return(hashed, ApplyLeafOpError.None);
    }

    enum PrepareLeafDataError {
        None,
        DoHash,
        DoLengthOp
    }
    function prepareLeafData(
        PROOFS_PROTO_GLOBAL_ENUMS.HashOp hashOp,
        PROOFS_PROTO_GLOBAL_ENUMS.LengthOp lenOp,
        bytes memory data
    ) internal pure returns(bytes memory, PrepareLeafDataError) {
        (bytes memory hased, DoHashError hCode) = doHashOrNoop(hashOp, data);
        if (hCode != DoHashError.None)return (empty, PrepareLeafDataError.DoHash);
        (bytes memory res, DoLengthOpError lCode) = doLengthOp(lenOp, hased);
        if (lCode != DoLengthOpError.None) return (empty, PrepareLeafDataError.DoLengthOp);

        return (res, PrepareLeafDataError.None);
    }

    enum CheckAgainstSpecError{
        None,
        Hash,
        PreHashKey,
        PreHashValue,
        Length,
        MinPrefixLength,
        HasPrefix,
        MaxPrefixLength
    }
    /**
    @notice will verify the Ics23LeafOp is in the format defined in spec
    */
    function checkAgainstSpec(
        Ics23LeafOp.Data memory leafOp,
        Ics23ProofSpec.Data memory spec
    ) internal pure returns(CheckAgainstSpecError) {
        //require (leafOp.hash == spec.leaf_spec.hash); // dev: checkAgainstSpec for LeafOp - Unexpected HashOp
        if (leafOp.hash != spec.leaf_spec.hash) return CheckAgainstSpecError.Hash;
        //require(leafOp.prehash_key == spec.leaf_spec.prehash_key); // dev: checkAgainstSpec for LeafOp - Unexpected PrehashKey
        if (leafOp.prehash_key != spec.leaf_spec.prehash_key) return CheckAgainstSpecError.PreHashKey;
        //require(leafOp.prehash_value == spec.leaf_spec.prehash_value); // dev: checkAgainstSpec for LeafOp - Unexpected PrehashValue");
        if (leafOp.prehash_value != spec.leaf_spec.prehash_value) return CheckAgainstSpecError.PreHashValue;
        //require(leafOp.length == spec.leaf_spec.length); // dev: checkAgainstSpec for LeafOp - Unexpected lengthOp
        if (leafOp.length != spec.leaf_spec.length) return CheckAgainstSpecError.Length;
        bool hasprefix = hasPrefix(leafOp.prefix, spec.leaf_spec.prefix);
        //require(hasprefix); // dev: checkAgainstSpec for LeafOp - Leaf Prefix doesn't start with
        if (hasprefix == false) return CheckAgainstSpecError.HasPrefix;

        return CheckAgainstSpecError.None;
    }

    enum ApplyInnerOpError {
        None,
        ChildLength,
        DoHash
    }
    /**
    @notice apply will calculate the hash of the next step, given the hash of the previous step
    */
    function applyOp(Ics23InnerOp.Data memory innerOp, bytes memory child ) internal pure returns(bytes memory, ApplyInnerOpError) {
        //require(child.length > 0); // dev: Inner op needs child value
        if (child.length == 0) return (empty, ApplyInnerOpError.ChildLength);
        bytes memory preImage = abi.encodePacked(innerOp.prefix, child, innerOp.suffix);
        (bytes memory hashed, DoHashError code) = doHash(innerOp.hash, preImage);
        if (code != DoHashError.None) return (empty, ApplyInnerOpError.DoHash);

        return (hashed, ApplyInnerOpError.None);
    }

    /**
    @notice will verify the Ics23InnerOp is in the format defined in spec
    */
    function checkAgainstSpec(
        Ics23InnerOp.Data memory innerOp,
        Ics23ProofSpec.Data memory spec
    ) internal pure returns(CheckAgainstSpecError) {
        //require(innerOp.hash == spec.inner_spec.hash); // dev: checkAgainstSpec for InnerOp - Unexpected HashOp
        if (innerOp.hash != spec.inner_spec.hash) return CheckAgainstSpecError.Hash;
        uint256 minPrefixLength = SafeCast.toUint256(spec.inner_spec.min_prefix_length);
        //require(innerOp.prefix.length >= minPrefixLength); // dev: InnerOp prefix too short;
        if (innerOp.prefix.length < minPrefixLength)  return CheckAgainstSpecError.MinPrefixLength;
        bytes memory leafPrefix = spec.leaf_spec.prefix;
        bool hasprefix = hasPrefix(innerOp.prefix, leafPrefix);
        //require(hasprefix == false); // dev: Inner Prefix starts with wrong value
        if (hasprefix) return CheckAgainstSpecError.HasPrefix;
        uint256 childSize = SafeCast.toUint256(spec.inner_spec.child_size);
        uint256 maxLeftChildBytes = (spec.inner_spec.child_order.length - 1) * childSize;
        uint256 maxPrefixLength = SafeCast.toUint256(spec.inner_spec.max_prefix_length);
        //require(innerOp.prefix.length <= maxPrefixLength + maxLeftChildBytes); // dev: InnerOp prefix too long
        if (innerOp.prefix.length > maxPrefixLength + maxLeftChildBytes)  return CheckAgainstSpecError.MaxPrefixLength;

        return CheckAgainstSpecError.None;
    }

    /**
    @notice will return the preimage untouched if hashOp == NONE, otherwise, perform doHash
    */
    function doHashOrNoop(PROOFS_PROTO_GLOBAL_ENUMS.HashOp hashOp, bytes memory preImage) internal pure returns(bytes memory, DoHashError) {
        if (hashOp == PROOFS_PROTO_GLOBAL_ENUMS.HashOp.NO_HASH) {
            return (preImage, DoHashError.None);
        }
        return doHash(hashOp, preImage);
    }

    enum DoHashError {
        None,
        Sha512,
        Sha512_256,
        Unsupported
    }
    /**
    @notice will preform the specified hash on the preimage. If hashOp == NONE,
     */
    function doHash(PROOFS_PROTO_GLOBAL_ENUMS.HashOp hashOp, bytes memory preImage) internal pure returns(bytes memory, DoHashError) {
        if (hashOp == PROOFS_PROTO_GLOBAL_ENUMS.HashOp.SHA256) {
            return (abi.encodePacked(sha256(preImage)), DoHashError.None);
        }
        if (hashOp == PROOFS_PROTO_GLOBAL_ENUMS.HashOp.KECCAK) {
            return (abi.encodePacked(keccak256(preImage)), DoHashError.None);
        }
        if (hashOp == PROOFS_PROTO_GLOBAL_ENUMS.HashOp.RIPEMD160) {
            return (abi.encodePacked(ripemd160(preImage)), DoHashError.None);
        }
        if (hashOp == PROOFS_PROTO_GLOBAL_ENUMS.HashOp.BITCOIN) {
            bytes memory tmp = abi.encodePacked(sha256(preImage));
            return (abi.encodePacked(ripemd160(tmp)), DoHashError.None);
        }
        //require(hashOp != PROOFS_PROTO_GLOBAL_ENUMS.HashOp.Sha512); // dev: SHA512 not supported
        if (hashOp == PROOFS_PROTO_GLOBAL_ENUMS.HashOp.SHA512) {
            return (empty, DoHashError.Sha512);
        }
        //require(hashOp != PROOFS_PROTO_GLOBAL_ENUMS.HashOp.Sha512_256); // dev: SHA512_256 not supported
        if (hashOp == PROOFS_PROTO_GLOBAL_ENUMS.HashOp.SHA512_256) {
            return (empty, DoHashError.Sha512_256);
        }
        //revert(); // dev: Unsupported hashOp
        return (empty, DoHashError.Unsupported);
    }

    function compare(bytes memory a, bytes memory b) internal pure returns(int) {
        uint256 minLen = Math.min(a.length, b.length);
        for (uint i = 0; i < minLen; i++) {
            if (uint8(a[i]) < uint8(b[i])) {
                return -1;
            } else if (uint8(a[i]) > uint8(b[i])) {
                return 1;
            }
        }
        if (a.length > minLen) {
            return 1;
        }
        if (b.length > minLen) {
            return -1;
        }
        return 0;
    }

    // private
    enum DoLengthOpError {
        None,
        Require32DataLength,
        Require64DataLength,
        Unsupported
    }
    /**
      @notice will calculate the proper prefix and return it prepended doLengthOp(op, data) -> length(data) || data
     */
    function doLengthOp(PROOFS_PROTO_GLOBAL_ENUMS.LengthOp lenOp, bytes memory data) private pure returns(bytes memory, DoLengthOpError) {
        if (lenOp == PROOFS_PROTO_GLOBAL_ENUMS.LengthOp.NO_PREFIX) {
            return (data, DoLengthOpError.None);
        }
        if (lenOp == PROOFS_PROTO_GLOBAL_ENUMS.LengthOp.VAR_PROTO) {
            uint256 sz = ProtoBufRuntime._sz_varint(data.length);
            bytes memory encoded = new bytes(sz);
            ProtoBufRuntime._encode_varint(data.length, 32, encoded);
            return (abi.encodePacked(encoded, data), DoLengthOpError.None);
        }
        if (lenOp == PROOFS_PROTO_GLOBAL_ENUMS.LengthOp.REQUIRE_32_BYTES) {
            //require(data.length == 32); // dev: data.length != 32
            if (data.length != 32) return (empty, DoLengthOpError.Require32DataLength);

            return (data, DoLengthOpError.None);
        }
        if (lenOp == PROOFS_PROTO_GLOBAL_ENUMS.LengthOp.REQUIRE_64_BYTES) {
            //require(data.length == 64); // dev: data.length != 64"
            if (data.length != 64) return (empty, DoLengthOpError.Require64DataLength);

            return (data, DoLengthOpError.None);
        }
        if (lenOp == PROOFS_PROTO_GLOBAL_ENUMS.LengthOp.FIXED32_LITTLE) {
            uint32 size = SafeCast.toUint32(data.length);
            // maybe some assembly here to make it faster
            bytes4 sizeB = bytes4(size);
            bytes memory littleE = new bytes(4);
            //unfolding for loop is cheaper
            littleE[0] = sizeB[3];
            littleE[1] = sizeB[2];
            littleE[2] = sizeB[1];
            littleE[3] = sizeB[0];
            return (abi.encodePacked(littleE, data), DoLengthOpError.None);
        }
        //revert(); // dev: Unsupported lenOp
        return (empty, DoLengthOpError.Unsupported);
    }

    function hasPrefix(bytes memory element, bytes memory prefix) private pure returns (bool) {
        if (prefix.length == 0) {
            return true;
        }
        if (prefix.length > element.length) {
            return false;
        }
        bytes memory slice = BytesLib.slice(element, 0, prefix.length);
        return BytesLib.equal(prefix, slice);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;


/**
 * @title Runtime library for ProtoBuf serialization and/or deserialization.
 * All ProtoBuf generated code will use this library.
 */
library ProtoBufRuntime {
  // Types defined in ProtoBuf
  enum WireType { Varint, Fixed64, LengthDelim, StartGroup, EndGroup, Fixed32 }
  // Constants for bytes calculation
  uint256 constant WORD_LENGTH = 32;
  uint256 constant HEADER_SIZE_LENGTH_IN_BYTES = 4;
  uint256 constant BYTE_SIZE = 8;
  uint256 constant REMAINING_LENGTH = WORD_LENGTH - HEADER_SIZE_LENGTH_IN_BYTES;
  string constant OVERFLOW_MESSAGE = "length overflow";

  //Storages
  /**
   * @dev Encode to storage location using assembly to save storage space.
   * @param location The location of storage
   * @param encoded The encoded ProtoBuf bytes
   */
  function encodeStorage(bytes storage location, bytes memory encoded)
    internal
  {
    /**
     * This code use the first four bytes as size,
     * and then put the rest of `encoded` bytes.
     */
    uint256 length = encoded.length;
    uint256 firstWord;
    uint256 wordLength = WORD_LENGTH;
    uint256 remainingLength = REMAINING_LENGTH;

    assembly {
      firstWord := mload(add(encoded, wordLength))
    }
    firstWord =
      (firstWord >> (BYTE_SIZE * HEADER_SIZE_LENGTH_IN_BYTES)) |
      (length << (BYTE_SIZE * REMAINING_LENGTH));

    assembly {
      sstore(location.slot, firstWord)
    }

    if (length > REMAINING_LENGTH) {
      length -= REMAINING_LENGTH;
      for (uint256 i = 0; i < ceil(length, WORD_LENGTH); i++) {
        assembly {
          let offset := add(mul(i, wordLength), remainingLength)
          let slotIndex := add(i, 1)
          sstore(
            add(location.slot, slotIndex),
            mload(add(add(encoded, wordLength), offset))
          )
        }
      }
    }
  }

  /**
   * @dev Decode storage location using assembly using the format in `encodeStorage`.
   * @param location The location of storage
   * @return The encoded bytes
   */
  function decodeStorage(bytes storage location)
    internal
    view
    returns (bytes memory)
  {
    /**
     * This code is to decode the first four bytes as size,
     * and then decode the rest using the decoded size.
     */
    uint256 firstWord;
    uint256 remainingLength = REMAINING_LENGTH;
    uint256 wordLength = WORD_LENGTH;

    assembly {
      firstWord := sload(location.slot)
    }

    uint256 length = firstWord >> (BYTE_SIZE * REMAINING_LENGTH);
    bytes memory encoded = new bytes(length);

    assembly {
      mstore(add(encoded, remainingLength), firstWord)
    }

    if (length > REMAINING_LENGTH) {
      length -= REMAINING_LENGTH;
      for (uint256 i = 0; i < ceil(length, WORD_LENGTH); i++) {
        assembly {
          let offset := add(mul(i, wordLength), remainingLength)
          let slotIndex := add(i, 1)
          mstore(
            add(add(encoded, wordLength), offset),
            sload(add(location.slot, slotIndex))
          )
        }
      }
    }
    return encoded;
  }

  /**
   * @dev Fast memory copy of bytes using assembly.
   * @param src The source memory address
   * @param dest The destination memory address
   * @param len The length of bytes to copy
   */
  function copyBytes(uint256 src, uint256 dest, uint256 len) internal pure {
    if (len == 0) {
      return;
    }

    // Copy word-length chunks while possible
    for (; len > WORD_LENGTH; len -= WORD_LENGTH) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += WORD_LENGTH;
      src += WORD_LENGTH;
    }

    // Copy remaining bytes
    uint256 mask = 256**(WORD_LENGTH - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  /**
   * @dev Use assembly to get memory address.
   * @param r The in-memory bytes array
   * @return The memory address of `r`
   */
  function getMemoryAddress(bytes memory r) internal pure returns (uint256) {
    uint256 addr;
    assembly {
      addr := r
    }
    return addr;
  }

  /**
   * @dev Implement Math function of ceil
   * @param a The denominator
   * @param m The numerator
   * @return r The result of ceil(a/m)
   */
  function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
    return (a + m - 1) / m;
  }

  // Decoders
  /**
   * This section of code `_decode_(u)int(32|64)`, `_decode_enum` and `_decode_bool`
   * is to decode ProtoBuf native integers,
   * using the `varint` encoding.
   */

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_uint32(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint32, uint256)
  {
    (uint256 varint, uint256 sz) = _decode_varint(p, bs);
    return (uint32(varint), sz);
  }

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_uint64(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint64, uint256)
  {
    (uint256 varint, uint256 sz) = _decode_varint(p, bs);
    return (uint64(varint), sz);
  }

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_int32(uint256 p, bytes memory bs)
    internal
    pure
    returns (int32, uint256)
  {
    (uint256 varint, uint256 sz) = _decode_varint(p, bs);
    int32 r;
    assembly {
      r := varint
    }
    return (r, sz);
  }

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_int64(uint256 p, bytes memory bs)
    internal
    pure
    returns (int64, uint256)
  {
    (uint256 varint, uint256 sz) = _decode_varint(p, bs);
    int64 r;
    assembly {
      r := varint
    }
    return (r, sz);
  }

  /**
   * @dev Decode enum
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded enum's integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_enum(uint256 p, bytes memory bs)
    internal
    pure
    returns (int64, uint256)
  {
    return _decode_int64(p, bs);
  }

  /**
   * @dev Decode enum
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded boolean
   * @return The length of `bs` used to get decoded
   */
  function _decode_bool(uint256 p, bytes memory bs)
    internal
    pure
    returns (bool, uint256)
  {
    (uint256 varint, uint256 sz) = _decode_varint(p, bs);
    if (varint == 0) {
      return (false, sz);
    }
    return (true, sz);
  }

  /**
   * This section of code `_decode_sint(32|64)`
   * is to decode ProtoBuf native signed integers,
   * using the `zig-zag` encoding.
   */

  /**
   * @dev Decode signed integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_sint32(uint256 p, bytes memory bs)
    internal
    pure
    returns (int32, uint256)
  {
    (int256 varint, uint256 sz) = _decode_varints(p, bs);
    return (int32(varint), sz);
  }

  /**
   * @dev Decode signed integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_sint64(uint256 p, bytes memory bs)
    internal
    pure
    returns (int64, uint256)
  {
    (int256 varint, uint256 sz) = _decode_varints(p, bs);
    return (int64(varint), sz);
  }

  /**
   * @dev Decode string
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded string
   * @return The length of `bs` used to get decoded
   */
  function _decode_string(uint256 p, bytes memory bs)
    internal
    pure
    returns (string memory, uint256)
  {
    (bytes memory x, uint256 sz) = _decode_lendelim(p, bs);
    return (string(x), sz);
  }

  /**
   * @dev Decode bytes array
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded bytes array
   * @return The length of `bs` used to get decoded
   */
  function _decode_bytes(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes memory, uint256)
  {
    return _decode_lendelim(p, bs);
  }

  /**
   * @dev Decode ProtoBuf key
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded field ID
   * @return The decoded WireType specified in ProtoBuf
   * @return The length of `bs` used to get decoded
   */
  function _decode_key(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256, WireType, uint256)
  {
    (uint256 x, uint256 n) = _decode_varint(p, bs);
    WireType typeId = WireType(x & 7);
    uint256 fieldId = x / 8;
    return (fieldId, typeId, n);
  }

  /**
   * @dev Decode ProtoBuf varint
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded unsigned integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_varint(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256, uint256)
  {
    /**
     * Read a byte.
     * Use the lower 7 bits and shift it to the left,
     * until the most significant bit is 0.
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint256 x = 0;
    uint256 sz = 0;
    uint256 length = bs.length + WORD_LENGTH;
    assembly {
      let b := 0x80
      p := add(bs, p)
      for {

      } eq(0x80, and(b, 0x80)) {

      } {
        if eq(lt(sub(p, bs), length), 0) {
          mstore(
            0,
            0x08c379a000000000000000000000000000000000000000000000000000000000
          ) //error function selector
          mstore(4, 32)
          mstore(36, 15)
          mstore(
            68,
            0x6c656e677468206f766572666c6f770000000000000000000000000000000000
          ) // length overflow in hex
          revert(0, 83)
        }
        let tmp := mload(p)
        let pos := 0
        for {

        } and(eq(0x80, and(b, 0x80)), lt(pos, 32)) {

        } {
          if eq(lt(sub(p, bs), length), 0) {
            mstore(
              0,
              0x08c379a000000000000000000000000000000000000000000000000000000000
            ) //error function selector
            mstore(4, 32)
            mstore(36, 15)
            mstore(
              68,
              0x6c656e677468206f766572666c6f770000000000000000000000000000000000
            ) // length overflow in hex
            revert(0, 83)
          }
          b := byte(pos, tmp)
          x := or(x, shl(mul(7, sz), and(0x7f, b)))
          sz := add(sz, 1)
          pos := add(pos, 1)
          p := add(p, 0x01)
        }
      }
    }
    return (x, sz);
  }

  /**
   * @dev Decode ProtoBuf zig-zag encoding
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded signed integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_varints(uint256 p, bytes memory bs)
    internal
    pure
    returns (int256, uint256)
  {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    (uint256 u, uint256 sz) = _decode_varint(p, bs);
    int256 s;
    assembly {
      s := xor(shr(1, u), add(not(and(u, 1)), 1))
    }
    return (s, sz);
  }

  /**
   * @dev Decode ProtoBuf fixed-length encoding
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded unsigned integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_uintf(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (uint256, uint256)
  {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint256 x = 0;
    uint256 length = bs.length + WORD_LENGTH;
    assert(p + sz <= length);
    assembly {
      let i := 0
      p := add(bs, p)
      let tmp := mload(p)
      for {

      } lt(i, sz) {

      } {
        x := or(x, shl(mul(8, i), byte(i, tmp)))
        p := add(p, 0x01)
        i := add(i, 1)
      }
    }
    return (x, sz);
  }

  /**
   * `_decode_(s)fixed(32|64)` is the concrete implementation of `_decode_uintf`
   */
  function _decode_fixed32(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint32, uint256)
  {
    (uint256 x, uint256 sz) = _decode_uintf(p, bs, 4);
    return (uint32(x), sz);
  }

  function _decode_fixed64(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint64, uint256)
  {
    (uint256 x, uint256 sz) = _decode_uintf(p, bs, 8);
    return (uint64(x), sz);
  }

  function _decode_sfixed32(uint256 p, bytes memory bs)
    internal
    pure
    returns (int32, uint256)
  {
    (uint256 x, uint256 sz) = _decode_uintf(p, bs, 4);
    int256 r;
    assembly {
      r := x
    }
    return (int32(r), sz);
  }

  function _decode_sfixed64(uint256 p, bytes memory bs)
    internal
    pure
    returns (int64, uint256)
  {
    (uint256 x, uint256 sz) = _decode_uintf(p, bs, 8);
    int256 r;
    assembly {
      r := x
    }
    return (int64(r), sz);
  }

  /**
   * @dev Decode bytes array
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded bytes array
   * @return The length of `bs` used to get decoded
   */
  function _decode_lendelim(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes memory, uint256)
  {
    /**
     * First read the size encoded in `varint`, then use the size to read bytes.
     */
    (uint256 len, uint256 sz) = _decode_varint(p, bs);
    bytes memory b = new bytes(len);
    uint256 length = bs.length + WORD_LENGTH;
    assert(p + sz + len <= length);
    uint256 sourcePtr;
    uint256 destPtr;
    assembly {
      destPtr := add(b, 32)
      sourcePtr := add(add(bs, p), sz)
    }
    copyBytes(sourcePtr, destPtr, len);
    return (b, sz + len);
  }

  /**
   * @dev Skip the decoding of a single field
   * @param wt The WireType of the field
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The length of `bs` to skipped
   */
  function _skip_field_decode(WireType wt, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    if (wt == ProtoBufRuntime.WireType.Fixed64) {
      return 8;
    } else if (wt == ProtoBufRuntime.WireType.Fixed32) {
      return 4;
    } else if (wt == ProtoBufRuntime.WireType.Varint) {
      (, uint256 size) = ProtoBufRuntime._decode_varint(p, bs);
      return size;
    } else {
      require(wt == ProtoBufRuntime.WireType.LengthDelim);
      (uint256 len, uint256 size) = ProtoBufRuntime._decode_varint(p, bs);
      return size + len;
    }
  }

  // Encoders
  /**
   * @dev Encode ProtoBuf key
   * @param x The field ID
   * @param wt The WireType specified in ProtoBuf
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_key(uint256 x, WireType wt, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 i;
    assembly {
      i := or(mul(x, 8), mod(wt, 8))
    }
    return _encode_varint(i, p, bs);
  }

  /**
   * @dev Encode ProtoBuf varint
   * @param x The unsigned integer to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_varint(uint256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint256 sz = 0;
    assembly {
      let bsptr := add(bs, p)
      let byt := and(x, 0x7f)
      for {

      } gt(shr(7, x), 0) {

      } {
        mstore8(bsptr, or(0x80, byt))
        bsptr := add(bsptr, 1)
        sz := add(sz, 1)
        x := shr(7, x)
        byt := and(x, 0x7f)
      }
      mstore8(bsptr, byt)
      sz := add(sz, 1)
    }
    return sz;
  }

  /**
   * @dev Encode ProtoBuf zig-zag encoding
   * @param x The signed integer to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_varints(int256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint256 encodedInt = _encode_zigzag(x);
    return _encode_varint(encodedInt, p, bs);
  }

  /**
   * @dev Encode ProtoBuf bytes
   * @param xs The bytes array to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_bytes(bytes memory xs, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 xsLength = xs.length;
    uint256 sz = _encode_varint(xsLength, p, bs);
    uint256 count = 0;
    assembly {
      let bsptr := add(bs, add(p, sz))
      let xsptr := add(xs, 32)
      for {

      } lt(count, xsLength) {

      } {
        mstore8(bsptr, byte(0, mload(xsptr)))
        bsptr := add(bsptr, 1)
        xsptr := add(xsptr, 1)
        count := add(count, 1)
      }
    }
    return sz + count;
  }

  /**
   * @dev Encode ProtoBuf string
   * @param xs The string to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_string(string memory xs, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_bytes(bytes(xs), p, bs);
  }

  /**
   * `_encode_(u)int(32|64)`, `_encode_enum` and `_encode_bool`
   * are concrete implementation of `_encode_varint`
   */
  function _encode_uint32(uint32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_varint(x, p, bs);
  }

  function _encode_uint64(uint64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_varint(x, p, bs);
  }

  function _encode_int32(int32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint64 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_varint(twosComplement, p, bs);
  }

  function _encode_int64(int64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint64 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_varint(twosComplement, p, bs);
  }

  function _encode_enum(int32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_int32(x, p, bs);
  }

  function _encode_bool(bool x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    if (x) {
      return _encode_varint(1, p, bs);
    } else return _encode_varint(0, p, bs);
  }

  /**
   * `_encode_sint(32|64)`, `_encode_enum` and `_encode_bool`
   * are the concrete implementation of `_encode_varints`
   */
  function _encode_sint32(int32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_varints(x, p, bs);
  }

  function _encode_sint64(int64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_varints(x, p, bs);
  }

  /**
   * `_encode_(s)fixed(32|64)` is the concrete implementation of `_encode_uintf`
   */
  function _encode_fixed32(uint32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_uintf(x, p, bs, 4);
  }

  function _encode_fixed64(uint64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_uintf(x, p, bs, 8);
  }

  function _encode_sfixed32(int32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint32 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_uintf(twosComplement, p, bs, 4);
  }

  function _encode_sfixed64(int64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint64 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_uintf(twosComplement, p, bs, 8);
  }

  /**
   * @dev Encode ProtoBuf fixed-length integer
   * @param x The unsigned integer to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_uintf(uint256 x, uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (uint256)
  {
    assembly {
      let bsptr := add(sz, add(bs, p))
      let count := sz
      for {

      } gt(count, 0) {

      } {
        bsptr := sub(bsptr, 1)
        mstore8(bsptr, byte(sub(32, count), x))
        count := sub(count, 1)
      }
    }
    return sz;
  }

  /**
   * @dev Encode ProtoBuf zig-zag signed integer
   * @param i The unsigned integer to be encoded
   * @return The encoded unsigned integer
   */
  function _encode_zigzag(int256 i) internal pure returns (uint256) {
    if (i >= 0) {
      return uint256(i) * 2;
    } else return uint256(i * -2) - 1;
  }

  // Estimators
  /**
   * @dev Estimate the length of encoded LengthDelim
   * @param i The length of LengthDelim
   * @return The estimated encoded length
   */
  function _sz_lendelim(uint256 i) internal pure returns (uint256) {
    return i + _sz_varint(i);
  }

  /**
   * @dev Estimate the length of encoded ProtoBuf field ID
   * @param i The field ID
   * @return The estimated encoded length
   */
  function _sz_key(uint256 i) internal pure returns (uint256) {
    if (i < 16) {
      return 1;
    } else if (i < 2048) {
      return 2;
    } else if (i < 262144) {
      return 3;
    } else {
      revert("not supported");
    }
  }

  /**
   * @dev Estimate the length of encoded ProtoBuf varint
   * @param i The unsigned integer
   * @return The estimated encoded length
   */
  function _sz_varint(uint256 i) internal pure returns (uint256) {
    uint256 count = 1;
    assembly {
      i := shr(7, i)
      for {

      } gt(i, 0) {

      } {
        i := shr(7, i)
        count := add(count, 1)
      }
    }
    return count;
  }

  /**
   * `_sz_(u)int(32|64)` and `_sz_enum` are the concrete implementation of `_sz_varint`
   */
  function _sz_uint32(uint32 i) internal pure returns (uint256) {
    return _sz_varint(i);
  }

  function _sz_uint64(uint64 i) internal pure returns (uint256) {
    return _sz_varint(i);
  }

  function _sz_int32(int32 i) internal pure returns (uint256) {
    if (i < 0) {
      return 10;
    } else return _sz_varint(uint32(i));
  }

  function _sz_int64(int64 i) internal pure returns (uint256) {
    if (i < 0) {
      return 10;
    } else return _sz_varint(uint64(i));
  }

  function _sz_enum(int64 i) internal pure returns (uint256) {
    if (i < 0) {
      return 10;
    } else return _sz_varint(uint64(i));
  }

  /**
   * `_sz_sint(32|64)` and `_sz_enum` are the concrete implementation of zig-zag encoding
   */
  function _sz_sint32(int32 i) internal pure returns (uint256) {
    return _sz_varint(_encode_zigzag(i));
  }

  function _sz_sint64(int64 i) internal pure returns (uint256) {
    return _sz_varint(_encode_zigzag(i));
  }

  /**
   * `_estimate_packed_repeated_(uint32|uint64|int32|int64|sint32|sint64)`
   */
  function _estimate_packed_repeated_uint32(uint32[] memory a) internal pure returns (uint256) {
    uint256 e = 0;
    for (uint i = 0; i < a.length; i++) {
      e += _sz_uint32(a[i]);
    }
    return e;
  }

  function _estimate_packed_repeated_uint64(uint64[] memory a) internal pure returns (uint256) {
    uint256 e = 0;
    for (uint i = 0; i < a.length; i++) {
      e += _sz_uint64(a[i]);
    }
    return e;
  }

  function _estimate_packed_repeated_int32(int32[] memory a) internal pure returns (uint256) {
    uint256 e = 0;
    for (uint i = 0; i < a.length; i++) {
      e += _sz_int32(a[i]);
    }
    return e;
  }

  function _estimate_packed_repeated_int64(int64[] memory a) internal pure returns (uint256) {
    uint256 e = 0;
    for (uint i = 0; i < a.length; i++) {
      e += _sz_int64(a[i]);
    }
    return e;
  }

  function _estimate_packed_repeated_sint32(int32[] memory a) internal pure returns (uint256) {
    uint256 e = 0;
    for (uint i = 0; i < a.length; i++) {
      e += _sz_sint32(a[i]);
    }
    return e;
  }

  function _estimate_packed_repeated_sint64(int64[] memory a) internal pure returns (uint256) {
    uint256 e = 0;
    for (uint i = 0; i < a.length; i++) {
      e += _sz_sint64(a[i]);
    }
    return e;
  }

  // Element counters for packed repeated fields
  function _count_packed_repeated_varint(uint256 p, uint256 len, bytes memory bs) internal pure returns (uint256) {
    uint256 count = 0;
    uint256 end = p + len;
    while (p < end) {
      uint256 sz;
      (, sz) = _decode_varint(p, bs);
      p += sz;
      count += 1;
    }
    return count;
  }

  // Soltype extensions
  /**
   * @dev Decode Solidity integer and/or fixed-size bytes array, filling from lowest bit.
   * @param n The maximum number of bytes to read
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The bytes32 representation
   * @return The number of bytes used to decode
   */
  function _decode_sol_bytesN_lower(uint8 n, uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes32, uint256)
  {
    uint256 r;
    (uint256 len, uint256 sz) = _decode_varint(p, bs);
    if (len + sz > n + 3) {
      revert(OVERFLOW_MESSAGE);
    }
    p += 3;
    assert(p < bs.length + WORD_LENGTH);
    assembly {
      r := mload(add(p, bs))
    }
    for (uint256 i = len - 2; i < WORD_LENGTH; i++) {
      r /= 256;
    }
    return (bytes32(r), len + sz);
  }

  /**
   * @dev Decode Solidity integer and/or fixed-size bytes array, filling from highest bit.
   * @param n The maximum number of bytes to read
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The bytes32 representation
   * @return The number of bytes used to decode
   */
  function _decode_sol_bytesN(uint8 n, uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes32, uint256)
  {
    (uint256 len, uint256 sz) = _decode_varint(p, bs);
    uint256 wordLength = WORD_LENGTH;
    uint256 byteSize = BYTE_SIZE;
    if (len + sz > n + 3) {
      revert(OVERFLOW_MESSAGE);
    }
    p += 3;
    bytes32 acc;
    assert(p < bs.length + WORD_LENGTH);
    assembly {
      acc := mload(add(p, bs))
      let difference := sub(wordLength, sub(len, 2))
      let bits := mul(byteSize, difference)
      acc := shl(bits, shr(bits, acc))
    }
    return (acc, len + sz);
  }

  /*
   * `_decode_sol*` are the concrete implementation of decoding Solidity types
   */
  function _decode_sol_address(uint256 p, bytes memory bs)
    internal
    pure
    returns (address, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytesN(20, p, bs);
    return (address(bytes20(r)), sz);
  }

  function _decode_sol_bool(uint256 p, bytes memory bs)
    internal
    pure
    returns (bool, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(1, p, bs);
    if (r == 0) {
      return (false, sz);
    }
    return (true, sz);
  }

  function _decode_sol_uint(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256, uint256)
  {
    return _decode_sol_uint256(p, bs);
  }

  function _decode_sol_uintN(uint8 n, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256, uint256)
  {
    (bytes32 u, uint256 sz) = _decode_sol_bytesN_lower(n, p, bs);
    uint256 r;
    assembly {
      r := u
    }
    return (r, sz);
  }

  function _decode_sol_uint8(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint8, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(1, p, bs);
    return (uint8(r), sz);
  }

  function _decode_sol_uint16(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint16, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(2, p, bs);
    return (uint16(r), sz);
  }

  function _decode_sol_uint24(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint24, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(3, p, bs);
    return (uint24(r), sz);
  }

  function _decode_sol_uint32(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint32, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(4, p, bs);
    return (uint32(r), sz);
  }

  function _decode_sol_uint40(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint40, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(5, p, bs);
    return (uint40(r), sz);
  }

  function _decode_sol_uint48(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint48, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(6, p, bs);
    return (uint48(r), sz);
  }

  function _decode_sol_uint56(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint56, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(7, p, bs);
    return (uint56(r), sz);
  }

  function _decode_sol_uint64(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint64, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(8, p, bs);
    return (uint64(r), sz);
  }

  function _decode_sol_uint72(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint72, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(9, p, bs);
    return (uint72(r), sz);
  }

  function _decode_sol_uint80(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint80, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(10, p, bs);
    return (uint80(r), sz);
  }

  function _decode_sol_uint88(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint88, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(11, p, bs);
    return (uint88(r), sz);
  }

  function _decode_sol_uint96(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint96, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(12, p, bs);
    return (uint96(r), sz);
  }

  function _decode_sol_uint104(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint104, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(13, p, bs);
    return (uint104(r), sz);
  }

  function _decode_sol_uint112(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint112, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(14, p, bs);
    return (uint112(r), sz);
  }

  function _decode_sol_uint120(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint120, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(15, p, bs);
    return (uint120(r), sz);
  }

  function _decode_sol_uint128(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint128, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(16, p, bs);
    return (uint128(r), sz);
  }

  function _decode_sol_uint136(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint136, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(17, p, bs);
    return (uint136(r), sz);
  }

  function _decode_sol_uint144(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint144, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(18, p, bs);
    return (uint144(r), sz);
  }

  function _decode_sol_uint152(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint152, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(19, p, bs);
    return (uint152(r), sz);
  }

  function _decode_sol_uint160(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint160, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(20, p, bs);
    return (uint160(r), sz);
  }

  function _decode_sol_uint168(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint168, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(21, p, bs);
    return (uint168(r), sz);
  }

  function _decode_sol_uint176(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint176, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(22, p, bs);
    return (uint176(r), sz);
  }

  function _decode_sol_uint184(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint184, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(23, p, bs);
    return (uint184(r), sz);
  }

  function _decode_sol_uint192(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint192, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(24, p, bs);
    return (uint192(r), sz);
  }

  function _decode_sol_uint200(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint200, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(25, p, bs);
    return (uint200(r), sz);
  }

  function _decode_sol_uint208(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint208, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(26, p, bs);
    return (uint208(r), sz);
  }

  function _decode_sol_uint216(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint216, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(27, p, bs);
    return (uint216(r), sz);
  }

  function _decode_sol_uint224(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint224, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(28, p, bs);
    return (uint224(r), sz);
  }

  function _decode_sol_uint232(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint232, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(29, p, bs);
    return (uint232(r), sz);
  }

  function _decode_sol_uint240(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint240, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(30, p, bs);
    return (uint240(r), sz);
  }

  function _decode_sol_uint248(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint248, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(31, p, bs);
    return (uint248(r), sz);
  }

  function _decode_sol_uint256(uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256, uint256)
  {
    (uint256 r, uint256 sz) = _decode_sol_uintN(32, p, bs);
    return (uint256(r), sz);
  }

  function _decode_sol_int(uint256 p, bytes memory bs)
    internal
    pure
    returns (int256, uint256)
  {
    return _decode_sol_int256(p, bs);
  }

  function _decode_sol_intN(uint8 n, uint256 p, bytes memory bs)
    internal
    pure
    returns (int256, uint256)
  {
    (bytes32 u, uint256 sz) = _decode_sol_bytesN_lower(n, p, bs);
    int256 r;
    assembly {
      r := u
      r := signextend(sub(sz, 4), r)
    }
    return (r, sz);
  }

  function _decode_sol_bytes(uint8 n, uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes32, uint256)
  {
    (bytes32 u, uint256 sz) = _decode_sol_bytesN(n, p, bs);
    return (u, sz);
  }

  function _decode_sol_int8(uint256 p, bytes memory bs)
    internal
    pure
    returns (int8, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(1, p, bs);
    return (int8(r), sz);
  }

  function _decode_sol_int16(uint256 p, bytes memory bs)
    internal
    pure
    returns (int16, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(2, p, bs);
    return (int16(r), sz);
  }

  function _decode_sol_int24(uint256 p, bytes memory bs)
    internal
    pure
    returns (int24, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(3, p, bs);
    return (int24(r), sz);
  }

  function _decode_sol_int32(uint256 p, bytes memory bs)
    internal
    pure
    returns (int32, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(4, p, bs);
    return (int32(r), sz);
  }

  function _decode_sol_int40(uint256 p, bytes memory bs)
    internal
    pure
    returns (int40, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(5, p, bs);
    return (int40(r), sz);
  }

  function _decode_sol_int48(uint256 p, bytes memory bs)
    internal
    pure
    returns (int48, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(6, p, bs);
    return (int48(r), sz);
  }

  function _decode_sol_int56(uint256 p, bytes memory bs)
    internal
    pure
    returns (int56, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(7, p, bs);
    return (int56(r), sz);
  }

  function _decode_sol_int64(uint256 p, bytes memory bs)
    internal
    pure
    returns (int64, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(8, p, bs);
    return (int64(r), sz);
  }

  function _decode_sol_int72(uint256 p, bytes memory bs)
    internal
    pure
    returns (int72, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(9, p, bs);
    return (int72(r), sz);
  }

  function _decode_sol_int80(uint256 p, bytes memory bs)
    internal
    pure
    returns (int80, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(10, p, bs);
    return (int80(r), sz);
  }

  function _decode_sol_int88(uint256 p, bytes memory bs)
    internal
    pure
    returns (int88, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(11, p, bs);
    return (int88(r), sz);
  }

  function _decode_sol_int96(uint256 p, bytes memory bs)
    internal
    pure
    returns (int96, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(12, p, bs);
    return (int96(r), sz);
  }

  function _decode_sol_int104(uint256 p, bytes memory bs)
    internal
    pure
    returns (int104, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(13, p, bs);
    return (int104(r), sz);
  }

  function _decode_sol_int112(uint256 p, bytes memory bs)
    internal
    pure
    returns (int112, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(14, p, bs);
    return (int112(r), sz);
  }

  function _decode_sol_int120(uint256 p, bytes memory bs)
    internal
    pure
    returns (int120, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(15, p, bs);
    return (int120(r), sz);
  }

  function _decode_sol_int128(uint256 p, bytes memory bs)
    internal
    pure
    returns (int128, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(16, p, bs);
    return (int128(r), sz);
  }

  function _decode_sol_int136(uint256 p, bytes memory bs)
    internal
    pure
    returns (int136, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(17, p, bs);
    return (int136(r), sz);
  }

  function _decode_sol_int144(uint256 p, bytes memory bs)
    internal
    pure
    returns (int144, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(18, p, bs);
    return (int144(r), sz);
  }

  function _decode_sol_int152(uint256 p, bytes memory bs)
    internal
    pure
    returns (int152, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(19, p, bs);
    return (int152(r), sz);
  }

  function _decode_sol_int160(uint256 p, bytes memory bs)
    internal
    pure
    returns (int160, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(20, p, bs);
    return (int160(r), sz);
  }

  function _decode_sol_int168(uint256 p, bytes memory bs)
    internal
    pure
    returns (int168, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(21, p, bs);
    return (int168(r), sz);
  }

  function _decode_sol_int176(uint256 p, bytes memory bs)
    internal
    pure
    returns (int176, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(22, p, bs);
    return (int176(r), sz);
  }

  function _decode_sol_int184(uint256 p, bytes memory bs)
    internal
    pure
    returns (int184, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(23, p, bs);
    return (int184(r), sz);
  }

  function _decode_sol_int192(uint256 p, bytes memory bs)
    internal
    pure
    returns (int192, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(24, p, bs);
    return (int192(r), sz);
  }

  function _decode_sol_int200(uint256 p, bytes memory bs)
    internal
    pure
    returns (int200, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(25, p, bs);
    return (int200(r), sz);
  }

  function _decode_sol_int208(uint256 p, bytes memory bs)
    internal
    pure
    returns (int208, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(26, p, bs);
    return (int208(r), sz);
  }

  function _decode_sol_int216(uint256 p, bytes memory bs)
    internal
    pure
    returns (int216, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(27, p, bs);
    return (int216(r), sz);
  }

  function _decode_sol_int224(uint256 p, bytes memory bs)
    internal
    pure
    returns (int224, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(28, p, bs);
    return (int224(r), sz);
  }

  function _decode_sol_int232(uint256 p, bytes memory bs)
    internal
    pure
    returns (int232, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(29, p, bs);
    return (int232(r), sz);
  }

  function _decode_sol_int240(uint256 p, bytes memory bs)
    internal
    pure
    returns (int240, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(30, p, bs);
    return (int240(r), sz);
  }

  function _decode_sol_int248(uint256 p, bytes memory bs)
    internal
    pure
    returns (int248, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(31, p, bs);
    return (int248(r), sz);
  }

  function _decode_sol_int256(uint256 p, bytes memory bs)
    internal
    pure
    returns (int256, uint256)
  {
    (int256 r, uint256 sz) = _decode_sol_intN(32, p, bs);
    return (int256(r), sz);
  }

  function _decode_sol_bytes1(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes1, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(1, p, bs);
    return (bytes1(r), sz);
  }

  function _decode_sol_bytes2(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes2, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(2, p, bs);
    return (bytes2(r), sz);
  }

  function _decode_sol_bytes3(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes3, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(3, p, bs);
    return (bytes3(r), sz);
  }

  function _decode_sol_bytes4(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes4, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(4, p, bs);
    return (bytes4(r), sz);
  }

  function _decode_sol_bytes5(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes5, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(5, p, bs);
    return (bytes5(r), sz);
  }

  function _decode_sol_bytes6(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes6, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(6, p, bs);
    return (bytes6(r), sz);
  }

  function _decode_sol_bytes7(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes7, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(7, p, bs);
    return (bytes7(r), sz);
  }

  function _decode_sol_bytes8(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes8, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(8, p, bs);
    return (bytes8(r), sz);
  }

  function _decode_sol_bytes9(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes9, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(9, p, bs);
    return (bytes9(r), sz);
  }

  function _decode_sol_bytes10(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes10, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(10, p, bs);
    return (bytes10(r), sz);
  }

  function _decode_sol_bytes11(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes11, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(11, p, bs);
    return (bytes11(r), sz);
  }

  function _decode_sol_bytes12(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes12, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(12, p, bs);
    return (bytes12(r), sz);
  }

  function _decode_sol_bytes13(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes13, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(13, p, bs);
    return (bytes13(r), sz);
  }

  function _decode_sol_bytes14(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes14, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(14, p, bs);
    return (bytes14(r), sz);
  }

  function _decode_sol_bytes15(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes15, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(15, p, bs);
    return (bytes15(r), sz);
  }

  function _decode_sol_bytes16(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes16, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(16, p, bs);
    return (bytes16(r), sz);
  }

  function _decode_sol_bytes17(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes17, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(17, p, bs);
    return (bytes17(r), sz);
  }

  function _decode_sol_bytes18(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes18, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(18, p, bs);
    return (bytes18(r), sz);
  }

  function _decode_sol_bytes19(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes19, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(19, p, bs);
    return (bytes19(r), sz);
  }

  function _decode_sol_bytes20(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes20, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(20, p, bs);
    return (bytes20(r), sz);
  }

  function _decode_sol_bytes21(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes21, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(21, p, bs);
    return (bytes21(r), sz);
  }

  function _decode_sol_bytes22(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes22, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(22, p, bs);
    return (bytes22(r), sz);
  }

  function _decode_sol_bytes23(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes23, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(23, p, bs);
    return (bytes23(r), sz);
  }

  function _decode_sol_bytes24(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes24, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(24, p, bs);
    return (bytes24(r), sz);
  }

  function _decode_sol_bytes25(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes25, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(25, p, bs);
    return (bytes25(r), sz);
  }

  function _decode_sol_bytes26(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes26, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(26, p, bs);
    return (bytes26(r), sz);
  }

  function _decode_sol_bytes27(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes27, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(27, p, bs);
    return (bytes27(r), sz);
  }

  function _decode_sol_bytes28(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes28, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(28, p, bs);
    return (bytes28(r), sz);
  }

  function _decode_sol_bytes29(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes29, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(29, p, bs);
    return (bytes29(r), sz);
  }

  function _decode_sol_bytes30(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes30, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(30, p, bs);
    return (bytes30(r), sz);
  }

  function _decode_sol_bytes31(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes31, uint256)
  {
    (bytes32 r, uint256 sz) = _decode_sol_bytes(31, p, bs);
    return (bytes31(r), sz);
  }

  function _decode_sol_bytes32(uint256 p, bytes memory bs)
    internal
    pure
    returns (bytes32, uint256)
  {
    return _decode_sol_bytes(32, p, bs);
  }

  /*
   * `_encode_sol*` are the concrete implementation of encoding Solidity types
   */
  function _encode_sol_address(address x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(uint160(x)), 20, p, bs);
  }

  function _encode_sol_uint(uint256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 32, p, bs);
  }

  function _encode_sol_uint8(uint8 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 1, p, bs);
  }

  function _encode_sol_uint16(uint16 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 2, p, bs);
  }

  function _encode_sol_uint24(uint24 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 3, p, bs);
  }

  function _encode_sol_uint32(uint32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 4, p, bs);
  }

  function _encode_sol_uint40(uint40 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 5, p, bs);
  }

  function _encode_sol_uint48(uint48 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 6, p, bs);
  }

  function _encode_sol_uint56(uint56 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 7, p, bs);
  }

  function _encode_sol_uint64(uint64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 8, p, bs);
  }

  function _encode_sol_uint72(uint72 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 9, p, bs);
  }

  function _encode_sol_uint80(uint80 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 10, p, bs);
  }

  function _encode_sol_uint88(uint88 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 11, p, bs);
  }

  function _encode_sol_uint96(uint96 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 12, p, bs);
  }

  function _encode_sol_uint104(uint104 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 13, p, bs);
  }

  function _encode_sol_uint112(uint112 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 14, p, bs);
  }

  function _encode_sol_uint120(uint120 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 15, p, bs);
  }

  function _encode_sol_uint128(uint128 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 16, p, bs);
  }

  function _encode_sol_uint136(uint136 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 17, p, bs);
  }

  function _encode_sol_uint144(uint144 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 18, p, bs);
  }

  function _encode_sol_uint152(uint152 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 19, p, bs);
  }

  function _encode_sol_uint160(uint160 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 20, p, bs);
  }

  function _encode_sol_uint168(uint168 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 21, p, bs);
  }

  function _encode_sol_uint176(uint176 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 22, p, bs);
  }

  function _encode_sol_uint184(uint184 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 23, p, bs);
  }

  function _encode_sol_uint192(uint192 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 24, p, bs);
  }

  function _encode_sol_uint200(uint200 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 25, p, bs);
  }

  function _encode_sol_uint208(uint208 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 26, p, bs);
  }

  function _encode_sol_uint216(uint216 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 27, p, bs);
  }

  function _encode_sol_uint224(uint224 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 28, p, bs);
  }

  function _encode_sol_uint232(uint232 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 29, p, bs);
  }

  function _encode_sol_uint240(uint240 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 30, p, bs);
  }

  function _encode_sol_uint248(uint248 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 31, p, bs);
  }

  function _encode_sol_uint256(uint256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(uint256(x), 32, p, bs);
  }

  function _encode_sol_int(int256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(x, 32, p, bs);
  }

  function _encode_sol_int8(int8 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 1, p, bs);
  }

  function _encode_sol_int16(int16 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 2, p, bs);
  }

  function _encode_sol_int24(int24 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 3, p, bs);
  }

  function _encode_sol_int32(int32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 4, p, bs);
  }

  function _encode_sol_int40(int40 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 5, p, bs);
  }

  function _encode_sol_int48(int48 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 6, p, bs);
  }

  function _encode_sol_int56(int56 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 7, p, bs);
  }

  function _encode_sol_int64(int64 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 8, p, bs);
  }

  function _encode_sol_int72(int72 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 9, p, bs);
  }

  function _encode_sol_int80(int80 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 10, p, bs);
  }

  function _encode_sol_int88(int88 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 11, p, bs);
  }

  function _encode_sol_int96(int96 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 12, p, bs);
  }

  function _encode_sol_int104(int104 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 13, p, bs);
  }

  function _encode_sol_int112(int112 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 14, p, bs);
  }

  function _encode_sol_int120(int120 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 15, p, bs);
  }

  function _encode_sol_int128(int128 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 16, p, bs);
  }

  function _encode_sol_int136(int136 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 17, p, bs);
  }

  function _encode_sol_int144(int144 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 18, p, bs);
  }

  function _encode_sol_int152(int152 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 19, p, bs);
  }

  function _encode_sol_int160(int160 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 20, p, bs);
  }

  function _encode_sol_int168(int168 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 21, p, bs);
  }

  function _encode_sol_int176(int176 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 22, p, bs);
  }

  function _encode_sol_int184(int184 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 23, p, bs);
  }

  function _encode_sol_int192(int192 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 24, p, bs);
  }

  function _encode_sol_int200(int200 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 25, p, bs);
  }

  function _encode_sol_int208(int208 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 26, p, bs);
  }

  function _encode_sol_int216(int216 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 27, p, bs);
  }

  function _encode_sol_int224(int224 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 28, p, bs);
  }

  function _encode_sol_int232(int232 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 29, p, bs);
  }

  function _encode_sol_int240(int240 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 30, p, bs);
  }

  function _encode_sol_int248(int248 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(int256(x), 31, p, bs);
  }

  function _encode_sol_int256(int256 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol(x, 32, p, bs);
  }

  function _encode_sol_bytes1(bytes1 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 1, p, bs);
  }

  function _encode_sol_bytes2(bytes2 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 2, p, bs);
  }

  function _encode_sol_bytes3(bytes3 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 3, p, bs);
  }

  function _encode_sol_bytes4(bytes4 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 4, p, bs);
  }

  function _encode_sol_bytes5(bytes5 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 5, p, bs);
  }

  function _encode_sol_bytes6(bytes6 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 6, p, bs);
  }

  function _encode_sol_bytes7(bytes7 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 7, p, bs);
  }

  function _encode_sol_bytes8(bytes8 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 8, p, bs);
  }

  function _encode_sol_bytes9(bytes9 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 9, p, bs);
  }

  function _encode_sol_bytes10(bytes10 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 10, p, bs);
  }

  function _encode_sol_bytes11(bytes11 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 11, p, bs);
  }

  function _encode_sol_bytes12(bytes12 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 12, p, bs);
  }

  function _encode_sol_bytes13(bytes13 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 13, p, bs);
  }

  function _encode_sol_bytes14(bytes14 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 14, p, bs);
  }

  function _encode_sol_bytes15(bytes15 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 15, p, bs);
  }

  function _encode_sol_bytes16(bytes16 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 16, p, bs);
  }

  function _encode_sol_bytes17(bytes17 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 17, p, bs);
  }

  function _encode_sol_bytes18(bytes18 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 18, p, bs);
  }

  function _encode_sol_bytes19(bytes19 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 19, p, bs);
  }

  function _encode_sol_bytes20(bytes20 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 20, p, bs);
  }

  function _encode_sol_bytes21(bytes21 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 21, p, bs);
  }

  function _encode_sol_bytes22(bytes22 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 22, p, bs);
  }

  function _encode_sol_bytes23(bytes23 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 23, p, bs);
  }

  function _encode_sol_bytes24(bytes24 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 24, p, bs);
  }

  function _encode_sol_bytes25(bytes25 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 25, p, bs);
  }

  function _encode_sol_bytes26(bytes26 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 26, p, bs);
  }

  function _encode_sol_bytes27(bytes27 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 27, p, bs);
  }

  function _encode_sol_bytes28(bytes28 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 28, p, bs);
  }

  function _encode_sol_bytes29(bytes29 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 29, p, bs);
  }

  function _encode_sol_bytes30(bytes30 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 30, p, bs);
  }

  function _encode_sol_bytes31(bytes31 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(bytes32(x), 31, p, bs);
  }

  function _encode_sol_bytes32(bytes32 x, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    return _encode_sol_bytes(x, 32, p, bs);
  }

  /**
   * @dev Encode the key of Solidity integer and/or fixed-size bytes array.
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol_header(uint256 sz, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 offset = p;
    p += _encode_varint(sz + 2, p, bs);
    p += _encode_key(1, WireType.LengthDelim, p, bs);
    p += _encode_varint(sz, p, bs);
    return p - offset;
  }

  /**
   * @dev Encode Solidity type
   * @param x The unsinged integer to be encoded
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol(uint256 x, uint256 sz, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 offset = p;
    uint256 size;
    p += 3;
    size = _encode_sol_raw_other(x, p, bs, sz);
    p += size;
    _encode_sol_header(size, offset, bs);
    return p - offset;
  }

  /**
   * @dev Encode Solidity type
   * @param x The signed integer to be encoded
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol(int256 x, uint256 sz, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 offset = p;
    uint256 size;
    p += 3;
    size = _encode_sol_raw_other(x, p, bs, sz);
    p += size;
    _encode_sol_header(size, offset, bs);
    return p - offset;
  }

  /**
   * @dev Encode Solidity type
   * @param x The fixed-size byte array to be encoded
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol_bytes(bytes32 x, uint256 sz, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint256)
  {
    uint256 offset = p;
    uint256 size;
    p += 3;
    size = _encode_sol_raw_bytes_array(x, p, bs, sz);
    p += size;
    _encode_sol_header(size, offset, bs);
    return p - offset;
  }

  /**
   * @dev Get the actual size needed to encoding an unsigned integer
   * @param x The unsigned integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @return The number of bytes needed for encoding `x`
   */
  function _get_real_size(uint256 x, uint256 sz)
    internal
    pure
    returns (uint256)
  {
    uint256 base = 0xff;
    uint256 realSize = sz;
    while (
      x & (base << (realSize * BYTE_SIZE - BYTE_SIZE)) == 0 && realSize > 0
    ) {
      realSize -= 1;
    }
    if (realSize == 0) {
      realSize = 1;
    }
    return realSize;
  }

  /**
   * @dev Get the actual size needed to encoding an signed integer
   * @param x The signed integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @return The number of bytes needed for encoding `x`
   */
  function _get_real_size(int256 x, uint256 sz)
    internal
    pure
    returns (uint256)
  {
    int256 base = 0xff;
    if (x >= 0) {
      uint256 tmp = _get_real_size(uint256(x), sz);
      int256 remainder = (x & (base << (tmp * BYTE_SIZE - BYTE_SIZE))) >>
        (tmp * BYTE_SIZE - BYTE_SIZE);
      if (remainder >= 128) {
        tmp += 1;
      }
      return tmp;
    }

    uint256 realSize = sz;
    while (
      x & (base << (realSize * BYTE_SIZE - BYTE_SIZE)) ==
      (base << (realSize * BYTE_SIZE - BYTE_SIZE)) &&
      realSize > 0
    ) {
      realSize -= 1;
    }
    {
      int256 remainder = (x & (base << (realSize * BYTE_SIZE - BYTE_SIZE))) >>
        (realSize * BYTE_SIZE - BYTE_SIZE);
      if (remainder < 128) {
        realSize += 1;
      }
    }
    return realSize;
  }

  /**
   * @dev Encode the fixed-bytes array
   * @param x The fixed-size byte array to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes needed for encoding `x`
   */
  function _encode_sol_raw_bytes_array(
    bytes32 x,
    uint256 p,
    bytes memory bs,
    uint256 sz
  ) internal pure returns (uint256) {
    /**
     * The idea is to not encode the leading bytes of zero.
     */
    uint256 actualSize = sz;
    for (uint256 i = 0; i < sz; i++) {
      uint8 current = uint8(x[sz - 1 - i]);
      if (current == 0 && actualSize > 1) {
        actualSize--;
      } else {
        break;
      }
    }
    assembly {
      let bsptr := add(bs, p)
      let count := actualSize
      for {

      } gt(count, 0) {

      } {
        mstore8(bsptr, byte(sub(actualSize, count), x))
        bsptr := add(bsptr, 1)
        count := sub(count, 1)
      }
    }
    return actualSize;
  }

  /**
   * @dev Encode the signed integer
   * @param x The signed integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes needed for encoding `x`
   */
  function _encode_sol_raw_other(
    int256 x,
    uint256 p,
    bytes memory bs,
    uint256 sz
  ) internal pure returns (uint256) {
    /**
     * The idea is to not encode the leading bytes of zero.or one,
     * depending on whether it is positive.
     */
    uint256 realSize = _get_real_size(x, sz);
    assembly {
      let bsptr := add(bs, p)
      let count := realSize
      for {

      } gt(count, 0) {

      } {
        mstore8(bsptr, byte(sub(32, count), x))
        bsptr := add(bsptr, 1)
        count := sub(count, 1)
      }
    }
    return realSize;
  }

  /**
   * @dev Encode the unsigned integer
   * @param x The unsigned integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes needed for encoding `x`
   */
  function _encode_sol_raw_other(
    uint256 x,
    uint256 p,
    bytes memory bs,
    uint256 sz
  ) internal pure returns (uint256) {
    uint256 realSize = _get_real_size(x, sz);
    assembly {
      let bsptr := add(bs, p)
      let count := realSize
      for {

      } gt(count, 0) {

      } {
        mstore8(bsptr, byte(sub(32, count), x))
        bsptr := add(bsptr, 1)
        count := sub(count, 1)
      }
    }
    return realSize;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;
import "./ProtoBufRuntime.sol";

library GoogleProtobufAny {


  //struct definition
  struct Data {
    string type_url;
    bytes value;
  }

  // Decoder section

  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // inner decoder

  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns (Data memory, uint)
  {
    Data memory r;
    uint[3] memory counters;
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;
      if (fieldId == 1) {
        pointer += _read_type_url(pointer, bs, r, counters);
      }
      else if (fieldId == 2) {
        pointer += _read_value(pointer, bs, r, counters);
      }

      else {
        if (wireType == ProtoBufRuntime.WireType.Fixed64) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Fixed32) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.Varint) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
          pointer += size;
        }
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
          uint256 size;
          (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
          pointer += size;
        }
      }

    }
    return (r, sz);
  }

  // field readers

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_type_url(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
    if (isNil(r)) {
      counters[1] += 1;
    } else {
      r.type_url = x;
      if (counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_value(
    uint256 p,
    bytes memory bs,
    Data memory r,
    uint[3] memory counters
  ) internal pure returns (uint) {
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
    if (isNil(r)) {
      counters[2] += 1;
    } else {
      r.value = x;
      if (counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }


  // Encoder section

  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {
      mstore(bs, sz)
    }
    return bs;
  }
  // inner encoder

  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    uint256 offset = p;
    uint256 pointer = p;

    pointer += ProtoBufRuntime._encode_key(
      1,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_string(r.type_url, pointer, bs);
    pointer += ProtoBufRuntime._encode_key(
      2,
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_bytes(r.value, pointer, bs);
    return pointer - offset;
  }
  // nested encoder

  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested(Data memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }
  // estimator

  /**
   * @dev The estimator for a struct
   * @param r The struct to be encoded
   * @return The number of bytes encoded in estimation
   */
  function _estimate(
    Data memory r
  ) internal pure returns (uint) {
    uint256 e;
    e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.type_url).length);
    e += 1 + ProtoBufRuntime._sz_lendelim(r.value.length);
    return e;
  }

  //store function
  /**
   * @dev Store in-memory struct to storage
   * @param input The in-memory struct
   * @param output The in-storage struct
   */
  function store(Data memory input, Data storage output) internal {
    output.type_url = input.type_url;
    output.value = input.value;

  }



  //utility functions
  /**
   * @dev Return an empty struct
   * @return r The empty struct
   */
  function nil() internal pure returns (Data memory r) {
    assembly {
      r := 0
    }
  }

  /**
   * @dev Test whether a struct is empty
   * @param x The struct to be tested
   * @return r True if it is empty
   */
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly {
      r := iszero(x)
    }
  }
}
//library Any

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}