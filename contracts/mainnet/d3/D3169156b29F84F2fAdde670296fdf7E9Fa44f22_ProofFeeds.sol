// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/public/IProofFeeds.sol";
import "./interfaces/public/ICoreMultidataFeedsReader.sol";
import "./NonProxiedOwnerMultipartyCommons.sol";
import "./AbstractFeedsWithMetrics.sol";


contract ProofFeeds is IProofFeeds, ICoreMultidataFeedsReader, NonProxiedOwnerMultipartyCommons, AbstractFeedsWithMetrics {

    /**
     * @notice Contract version, using SemVer version scheme.
     */
    string public constant override VERSION = "0.1.0";

    bytes32 public constant override MERKLE_TREE_ROOT_TYPE_HASH = keccak256("MerkleTreeRoot(uint32 epoch,bytes32 root)");

    mapping(uint => uint) internal _values;
    mapping(uint => uint32) internal _updateTSs;

    ////////////////////////

    constructor (address sourceContractAddr_, uint sourceChainId_)
        NonProxiedOwnerMultipartyCommons(sourceContractAddr_, sourceChainId_) {

    }

    ///////////////////////

    function requireValidProof(
        SignedMerkleTreeRoot memory signedMerkleTreeRoot_,
        CheckedData memory checkedData_
    ) public view override {
        require(isProofValid(signedMerkleTreeRoot_, checkedData_), "MultidataFeeds: INVALID_PROOF");
    }

    function isProofValid(
        SignedMerkleTreeRoot memory signedMerkleTreeRoot_,
        CheckedData memory checkedData_
    ) public view override returns (bool) {
        bool isSignatureValid = isMessageSignatureValid(
            keccak256(
                abi.encode(MERKLE_TREE_ROOT_TYPE_HASH, signedMerkleTreeRoot_.epoch, signedMerkleTreeRoot_.root)
            ),
            signedMerkleTreeRoot_.v, signedMerkleTreeRoot_.r, signedMerkleTreeRoot_.s
        );

        if (!isSignatureValid) {
            return false;
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(
            signedMerkleTreeRoot_.epoch,
            checkedData_.metricName,
            checkedData_.metricValue,
            checkedData_.metricUpdateTs
        ))));

        return MerkleProof.verify(checkedData_.merkleTreeProof, signedMerkleTreeRoot_.root, leaf);
    }

    ////////////////////////////

    function quoteMetrics(string[] calldata names) external view override returns (Quote[] memory quotes) {
        uint length = names.length;
        quotes = new Quote[](length);

        for (uint i; i < length; i++) {
            (bool has, uint id) = hasMetric(names[i]);
            require(has, "MultidataFeeds: INVALID_METRIC_NAME");
            quotes[i] = Quote(_values[id], _updateTSs[id]);
        }
    }

    function quoteMetrics(uint256[] calldata ids) external view override returns (Quote[] memory quotes) {
        uint length = ids.length;
        quotes = new Quote[](length);

        uint metricsCount = getMetricsCount();
        for (uint i; i < length; i++) {
            uint id = ids[i];
            require(id < metricsCount, "MultidataFeeds: INVALID_METRIC");
            quotes[i] = Quote(_values[id], _updateTSs[id]);
        }
    }

    ////////////////////////////

    /**
     * @notice Upload signed value
     * @dev metric in this instance is created if it is not exists. Important: metric id is different from metric ids from other
     *      instances of ProofFeeds and MedianFeed
     */
    function setValue(SignedMerkleTreeRoot calldata signedMerkleTreeRoot_, CheckedData calldata data_) external {
        require(isProofValid(signedMerkleTreeRoot_, data_), "MultidataFeeds: INVALID_PROOF");

        (bool has, uint metricId) = hasMetric(data_.metricName);
        if (!has) {
            metricId = addMetric(Metric(data_.metricName, "", "", new string[](0)));
        }

        require(data_.metricUpdateTs > _updateTSs[metricId], "MultidataFeeds: STALE_UPDATE");

        _values[metricId] = data_.metricValue;
        _updateTSs[metricId] = data_.metricUpdateTs;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
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
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./IVersioned.sol";
import "./IProofFeedsCommons.sol";


interface IProofFeeds is IVersioned, IProofFeedsCommons {

    struct CheckedData {
        bytes32[] merkleTreeProof;
        string metricName;
        uint256 metricValue;
        uint32 metricUpdateTs;
    }

    function requireValidProof(
        SignedMerkleTreeRoot memory signedMerkleTreeRoot_,
        CheckedData memory checkedData_
    ) external view;

    function isProofValid(
        SignedMerkleTreeRoot memory signedMerkleTreeRoot_,
        CheckedData memory checkedData_
    ) external view returns (bool);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./IVersioned.sol";


/// @title Reader of MultidataFeeds core data.
interface ICoreMultidataFeedsReader is IVersioned {

    struct Metric {
        string name;    // unique, immutable in a contract
        string description;
        string currency;    // USD, ETH, PCT (for percent), BPS (for basis points), etc
        string[] tags;
    }

    struct Quote {
        uint256 value;
        uint32 updateTS;
    }

    event NewMetric(string name);
    event MetricInfoUpdated(string name);
    /// @notice updated one metric or all if metricId=type(uint256).max-1
    event MetricUpdated(uint indexed epochId, uint indexed metricId);


    /**
     * @notice Gets a list of metrics quoted by this oracle.
     * @return A list of metric info indexed by numerical metric ids.
     */
    function getMetrics() external view returns (Metric[] memory);

    /// @notice Gets a count of metrics quoted by this oracle.
    function getMetricsCount() external view returns (uint);

    /// @notice Gets metric info by a numerical id.
    function getMetric(uint256 id) external view returns (Metric memory);

    /**
     * @notice Checks if a metric is quoted by this oracle.
     * @param name Metric codename.
     * @return has `true` if metric exists.
     * @return id Metric numerical id, set if `has` is true.
     */
    function hasMetric(string calldata name) external view returns (bool has, uint256 id);

    /**
     * @notice Gets last known quotes for specified metrics.
     * @param names Metric codenames to query.
     * @return quotes Values and update timestamps for queried metrics.
     */
    function quoteMetrics(string[] calldata names) external view returns (Quote[] memory quotes);

    /**
     * @notice Gets last known quotes for specified metrics by internal numerical ids.
     * @dev Saves one storage lookup per metric.
     * @param ids Numerical metric ids to query.
     * @return quotes Values and update timestamps for queried metrics.
     */
    function quoteMetrics(uint256[] calldata ids) external view returns (Quote[] memory quotes);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MultipartyCommons.sol";


abstract contract NonProxiedOwnerMultipartyCommons is MultipartyCommons {
    event MPOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    OwnerMultisignature internal ownerMultisignature_; // informational field
    address internal mpOwner_;   // described by ownerMultisignature

    constructor(address verifyingContract, uint256 chainId) MultipartyCommons(verifyingContract, chainId) {
        address[] memory newParticipants = new address[](1);
        newParticipants[0] = msg.sender;
        changeOwner_(msg.sender, 1, newParticipants);
    }

    /**
     * @notice Changes multiparty owner data.
     * @param newOwner Address of the new mp owner.
     * @param quorum New quorum value.
     * @param newParticipants List of the new participants' addresses
     * @param salt Salt value
     * @param deadline Unix ts at which the work must be interrupted.
     */
    function changeOwner(address newOwner, uint quorum, address[] calldata newParticipants, uint salt, uint deadline)
        external
        selfCall
        applicable(salt, deadline)
    {
        changeOwner_(newOwner, quorum, newParticipants);
    }

    /**
     * @notice Changes multiparty owner data. Internal
     * @param newOwner Address of the new mp owner.
     * @param quorum New quorum value.
     * @param newParticipants List of the new participants' addresses
     */
    function changeOwner_(address newOwner, uint quorum, address[] memory newParticipants)
        internal
    {
        require(newOwner != address(0), "MP: ZERO_ADDRESS");
        emit MPOwnershipTransferred(mpOwner_, newOwner);
        address[] memory oldParticipants = ownerMultisignature_.participants;
        onNewOwner(newOwner, quorum, newParticipants, oldParticipants);
        ownerMultisignature_.quorum = quorum;
        ownerMultisignature_.participants = newParticipants;
        mpOwner_ = newOwner;
    }

    /**
     * @notice The new mp owner handler. Empty implementation
     * @param newOwner Address of the new mp owner.
     * @param newQuorum New quorum value.
     * @param newParticipants List of the new participants' addresses.
     * @param oldParticipants List of the old participants' addresses.
     */
    function onNewOwner(address newOwner, uint newQuorum, address[] memory newParticipants, address[] memory oldParticipants) virtual internal {}

    // @inheritdoc IMpOwnable
    function ownerMultisignature() public view virtual override returns (OwnerMultisignature memory) {
        return ownerMultisignature_;
    }

    // @inheritdoc IMpOwnable
    function mpOwner() public view virtual override returns (address) {
        return mpOwner_;
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./interfaces/public/ICoreMultidataFeedsReader.sol";


abstract contract AbstractFeedsWithMetrics is ICoreMultidataFeedsReader {

    Metric[] internal metrics;
    // Position of the metric in the `metrics` array, plus 1 because index 0
    // means that metric is not exists (to avoid additional checks of existence).
    mapping(string => uint) internal adjustedMetricId;

    /// @inheritdoc ICoreMultidataFeedsReader
    function getMetrics() public view override returns (Metric[] memory) {
        return metrics;
    }

    /// @inheritdoc ICoreMultidataFeedsReader
    function getMetricsCount() public view override returns (uint) {
        return metrics.length;
    }

    /// @inheritdoc ICoreMultidataFeedsReader
    function getMetric(uint256 id) external view override returns (Metric memory) {
        require(id < metrics.length, "MultidataFeeds: METRIC_NOT_FOUND");
        return metrics[id];
    }

    /// @inheritdoc ICoreMultidataFeedsReader
    function hasMetric(string calldata name) public view override returns (bool has, uint256 id) {
        uint adjustedId = adjustedMetricId[name];
        if (adjustedId != 0) {
            return (true, adjustedId - 1);
        }

        return (false, 0);
    }

    function addMetric(Metric memory metric_) internal returns (uint newMetricId_) {
        uint adjustedId = adjustedMetricId[metric_.name];
        require(adjustedId == 0, "MultidataFeeds: METRIC_EXISTS");

        newMetricId_ = metrics.length;
        adjustedMetricId[metric_.name] = newMetricId_ + 1;
        metrics.push(metric_);

        emit NewMetric(metric_.name);
    }

    function updateMetric(Metric memory metric_) internal {
        uint adjustedId = adjustedMetricId[metric_.name];
        require(adjustedId != 0, "MultidataFeeds: METRIC_NOT_FOUND");

        metrics[adjustedId-1] = metric_;
        emit MetricInfoUpdated(metric_.name);
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;


/// @title Contract supporting versioning using SemVer version scheme.
interface IVersioned {
    /// @notice Contract version, using SemVer version scheme.
    function VERSION() external view returns (string memory);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./IVersioned.sol";


interface IProofFeedsCommons {

    struct SignedMerkleTreeRoot {
        uint32 epoch;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 root;
    }

    /// @dev must be keccak256("MerkleTreeRoot(uint32 epoch,bytes32 root)")
    function MERKLE_TREE_ROOT_TYPE_HASH() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IMpOwnable.sol";


abstract contract MultipartyCommons is IMpOwnable {
    bytes32 immutable internal VOTE_TYPE_HASH;
    bytes32 internal DOMAIN_SEPARATOR;

    mapping(uint => bool) public usedSalt;

    // Self-calls are used to engage builtin deserialization facility (abi parsing) and not parse args ourselves
    modifier selfCall virtual {
        require(msg.sender == address(this), "MP: NO_ACCESS");
        _;
    }

    // Checks if a privileged call can be applied
    modifier applicable(uint salt, uint deadline) virtual {
        require(getTimeNow() <= deadline, "MP: DEADLINE");
        require(!usedSalt[salt], "MP: DUPLICATE");
        usedSalt[salt] = true;
        _;
    }

    constructor(address verifyingContract, uint256 chainId) {
        require(verifyingContract != address(0) && chainId != 0, 'MP: Invalid domain parameters');
        VOTE_TYPE_HASH = keccak256("Vote(bytes calldata)");
        setDomainSeparator(chainId, verifyingContract);
    }

    /**
     * @notice DOMAIN_SEPARATOR setter.
     * @param chainId Chain id of the verifying contract
     * @param verifyingContract Address of the verifying contract
     */
    function setDomainSeparator(uint256 chainId, address verifyingContract) internal {
        DOMAIN_SEPARATOR = buildDomainSeparator(chainId, verifyingContract);
    }

    function buildDomainSeparator(uint256 chainId, address verifyingContract) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Multidata.Multiparty.Protocol")),
                keccak256(bytes("1")),
                chainId,
                verifyingContract
            )
        );
    }

    /**
     * @notice Performs privileged call to the contract.
     * @param privilegedCallData Method calldata
     * @param v Signature v for the call
     * @param r Signature r for the call
     * @param s Signature s for the call
     */
    function privilegedCall(bytes calldata privilegedCallData, uint8 v, bytes32 r, bytes32 s) external
    {
        checkMessageSignature(keccak256(abi.encode(VOTE_TYPE_HASH, keccak256(privilegedCallData))), v, r, s);

        (bool success, bytes memory returnData) = address(this).call(privilegedCallData);
        if (!success) {
            revert(string(returnData));
        }
    }

    /**
     * @notice Checks the message signature.
     * @param hashStruct Hash of a message struct
     * @param v V of the message signature
     * @param r R of the message signature
     * @param s S of the message signature
     */
    function checkMessageSignature(bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal virtual view {
        require(isMessageSignatureValid(hashStruct, v, r, s), "MP: NO_ACCESS");
    }

    function isMessageSignatureValid(bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal virtual view returns (bool) {
        return ECDSA.recover(generateMessageHash(hashStruct), v, r, s) == mpOwner();
    }

    function checkMessageSignatureForDomain(bytes32 domainSeparator, bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal virtual view {
        require(ECDSA.recover(generateMessageHashForDomain(domainSeparator, hashStruct), v, r, s) == mpOwner(), "MP: NO_ACCESS");
    }

    /**
     * @notice Returns hash of the message for the hash of the struct.
     * @param hashStruct Hash of a message struct
     */
    function generateMessageHash(bytes32 hashStruct) internal view returns (bytes32) {
        return generateMessageHashForDomain(DOMAIN_SEPARATOR, hashStruct);
    }

    function generateMessageHashForDomain(bytes32 domainSeparator, bytes32 hashStruct) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                hashStruct
            )
        );
    }

    /**
     * @notice Returns current chain time in unix ts.
     */
    function getTimeNow() virtual internal view returns (uint32) {
        return uint32(block.timestamp);
    }

    // @inheritdoc IMpOwnable
    function ownerMultisignature() public view virtual override returns (OwnerMultisignature memory);

    // @inheritdoc IMpOwnable
    function mpOwner() public view virtual override returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMpOwnable {
    struct OwnerMultisignature {
        uint quorum;
        address[] participants;
    }

    // @notice Returns OwnerMultisignature data
    function ownerMultisignature() external view returns (OwnerMultisignature memory);

    // @notice Returns address og the multiparty owner
    function mpOwner() external view returns (address);
}