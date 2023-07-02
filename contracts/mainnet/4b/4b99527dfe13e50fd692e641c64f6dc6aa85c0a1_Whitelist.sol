// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {Auth, GlobalACL} from "../Auth.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Whitelist
 * @author Umami DAO
 * @notice The Whitelist contract manages a whitelist of users and their deposit limits for different assets.
 * This contract is used by aggregate vaults to ensure only authorized users can deposit specified amounts
 * of assets.
 */
contract Whitelist is GlobalACL {
    address public immutable aggregateVault;
    address public zap;

    constructor(Auth _auth, address _aggregateVault, address _zap) GlobalACL(_auth) {
        whitelistEnabled = true;
        aggregateVault = _aggregateVault;
        zap = _zap;
    }

    /// @dev asset -> user -> manual whitelist amount
    mapping(address => mapping(address => uint256)) public whitelistedDepositAmount;

    /// @dev asset -> merkle root
    mapping(address => bytes32) public merkleRoots;

    /// @dev asset -> deposit limit
    mapping(address => uint256) public merkleDepositLimit;

    /// @dev asset -> user -> total deposited
    mapping(address => mapping(address => uint256)) public merkleDepositorTracker;

    /// @dev flag for whitelist enabled
    bool public whitelistEnabled;

    event WhitelistUpdated(address indexed account, address asset, uint256 whitelistedAmount);
    
    // WHITELIST VIEWS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Checks if a user has priority access to the whitelist for a specific asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     */
    function isWhitelistedPriority(address _asset, address _account) external view returns (bool) {
        if (whitelistEnabled) return whitelistedDepositAmount[_account][_asset] > 0;
        return true;
    }

    /**
     * @notice Checks if a user is whitelisted using a merkle proof for a specific asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param merkleProof The merkle proof.
     */
    function isWhitelistedMerkle(address _asset, address _account, bytes32[] memory merkleProof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        if (whitelistEnabled) return MerkleProof.verify(merkleProof, merkleRoots[_asset], leaf);
        return true;
    }

    /**
     * @notice Checks if a user is whitelisted for a specific asset, using either their manual whitelist amount or merkle proof.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param merkleProof The merkle proof.
     */
    function isWhitelisted(address _asset, address _account, bytes32[] memory merkleProof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        bytes32 computedRoot = MerkleProof.processProof(merkleProof, leaf);
        if (merkleRoots[_asset] == bytes32(0) && computedRoot == leaf) return true;

        if (whitelistEnabled) return whitelistedDepositAmount[_account][_asset] > 0 || MerkleProof.verify(merkleProof, merkleRoots[_asset], leaf);
        return true;
    }

    // LIMIT TRACKERS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Records a user's deposit to their whitelist amount for a specific asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param _amount The amount of the deposit.
     */
    function whitelistDeposit(address _asset, address _account, uint256 _amount) external onlyAggregateVaultOrZap {
        require(whitelistedDepositAmount[_account][_asset] >= _amount, "Whitelist: amount > asset whitelist amount");
        whitelistedDepositAmount[_account][_asset] -= _amount;
    }
    /**
     * @notice Records a user's deposit to their whitelist amount for a specific asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param _amount The amount of the deposit.
     */
    function whitelistDepositMerkle(address _asset, address _account, uint256 _amount, bytes32[] memory merkleProof) external onlyAggregateVaultOrZap {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        bytes32 computedRoot = MerkleProof.processProof(merkleProof, leaf);
        if (merkleRoots[_asset] == bytes32(0) && computedRoot == leaf) return;

        require(
            MerkleProof.verify(merkleProof, merkleRoots[_asset], leaf),
            "Whitelist: invalid proof"
        );
        require(merkleDepositorTracker[_asset][_account] + _amount <= merkleDepositLimit[_asset], "Whitelist: amount > asset whitelist amount");
        merkleDepositorTracker[_asset][_account] += _amount;
    }

    // CONFIG
    // ------------------------------------------------------------------------------------------
    
    /**
     * @notice Updates the whitelist amount for a specific user and asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param _amount The new whitelist amount.
     */
    function updateWhitelist(
        address _asset,
        address _account,
        uint256 _amount
    ) external onlyConfigurator {
        whitelistedDepositAmount[_account][_asset] = _amount;
        emit WhitelistUpdated(_account, _asset, _amount);
    }

    /**
     * @notice Updates the whitelist enabled status.
     * @param _newVal The new whitelist enabled status.
     */
    function updateWhitelistEnabled(bool _newVal) external onlyConfigurator {
        whitelistEnabled = _newVal;
    }

    /**
     * @notice Updates the merkle root for a specific asset.
     * @param _asset The asset address.
     * @param _root The new merkle root.
     */
    function updateMerkleRoot(address _asset, bytes32 _root) external onlyConfigurator {
        merkleRoots[_asset] = _root;
    }

    /**
     * @notice Updates the merkle deposit limit for a specific asset.
     * @param _asset The asset address.
     * @param _depositLimit The new limit.
     */
    function updateMerkleDepositLimit(address _asset, uint256 _depositLimit) external onlyConfigurator {
        merkleDepositLimit[_asset] = _depositLimit;
    }

    /**
     * @notice Updates the merkle depositor tracker for a specific user and asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param _newValue The new tracked value.
     */
    function updateMerkleDepositorTracker(address _asset, address _account, uint256 _newValue) external onlyConfigurator {
        merkleDepositorTracker[_asset][_account] = _newValue;
    }

    function updateZap(address _newZap) external onlyConfigurator {
        zap = _newZap;
    }

    modifier onlyAggregateVault {
        require(msg.sender == aggregateVault, "Whitelist: only aggregate vault");
        _;
    }

    modifier onlyAggregateVaultOrZap {
        require(msg.sender == aggregateVault || msg.sender == zap, "Whitelist: only aggregate vault or zap");
        _;
    }
}

pragma solidity 0.8.17;

bytes32 constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR");
bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
bytes32 constant SWAP_KEEPER = keccak256("SWAP_KEEPER");

/// @title Auth
/// @author Umami Developers
/// @notice Simple centralized ACL
contract Auth {
    /// @dev user not authorized with given role
    error NotAuthorized(bytes32 _role, address _user);

    event RoleUpdated(
        bytes32 indexed role,
        address indexed user,
        bool authorized
    );

    bytes32 public constant AUTH_MANAGER_ROLE = keccak256("AUTH_MANAGER");
    mapping(bytes32 => mapping(address => bool)) public hasRole;

    constructor() {
        _updateRole(msg.sender, AUTH_MANAGER_ROLE, true);
    }

    function updateRole(
        address _user,
        bytes32 _role,
        bool _authorized
    ) external {
        onlyRole(AUTH_MANAGER_ROLE, msg.sender);
        _updateRole(_user, _role, _authorized);
    }

    function onlyRole(bytes32 _role, address _user) public view {
        if (!hasRole[_role][_user]) {
            revert NotAuthorized(_role, _user);
        }
    }

    function _updateRole(
        address _user,
        bytes32 _role,
        bool _authorized
    ) internal {
        hasRole[_role][_user] = _authorized;
        emit RoleUpdated(_role, _user, _authorized);
    }
}

abstract contract GlobalACL {
    Auth public immutable AUTH;

    constructor(Auth _auth) {
        require(address(_auth) != address(0), "GlobalACL: zero address");
        AUTH = _auth;
    }

    modifier onlyConfigurator() {
        AUTH.onlyRole(CONFIGURATOR_ROLE, msg.sender);
        _;
    }

    modifier onlyRole(bytes32 _role) {
        AUTH.onlyRole(_role, msg.sender);
        _;
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