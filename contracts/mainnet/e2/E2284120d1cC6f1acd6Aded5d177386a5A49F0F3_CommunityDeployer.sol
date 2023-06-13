// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/MerkleProof.sol)

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
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
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
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
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

/*
Licensed under the Voltz v2 License (the "License"); you 
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/core/LICENSE
*/
pragma solidity >=0.8.19;

import "@voltz-protocol/util-contracts/src/proxy/UUPSProxyWithOwner.sol";

/**
 * Voltz V2 Core Proxy Contract
 */
contract CoreProxy is UUPSProxyWithOwner {
    // solhint-disable-next-line no-empty-blocks
    constructor(address firstImplementation, address initialOwner)
        UUPSProxyWithOwner(firstImplementation, initialOwner)
    {}
}

/*
Licensed under the Voltz v2 License (the "License"); you 
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/core/LICENSE
*/
pragma solidity >=0.8.19;

import "@voltz-protocol/util-modules/src/modules/BaseAssociatedSystemsModule.sol";

/**
 * @title Module for connecting to other systems.
 */
// solhint-disable-next-line no-empty-blocks
contract AssociatedSystemsModule is BaseAssociatedSystemsModule {}

pragma solidity >=0.8.19;

import "@voltz-protocol/util-contracts/src/proxy/UUPSProxyWithOwner.sol";

/**
 * Voltz V2 Periphery Proxy Contract
 */
contract PeripheryProxy is UUPSProxyWithOwner {
    // solhint-disable-next-line no-empty-blocks
    constructor(address firstImplementation, address initialOwner)
        UUPSProxyWithOwner(firstImplementation, initialOwner)
    {}
}

/*
Licensed under the Voltz v2 License (the "License"); you 
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/products/dated-irs/LICENSE
*/
pragma solidity >=0.8.19;

import "@voltz-protocol/util-contracts/src/proxy/UUPSProxyWithOwner.sol";

/**
 * Voltz V2 Product Proxy Contract
 */
contract ProductProxy is UUPSProxyWithOwner {
    // solhint-disable-next-line no-empty-blocks
    constructor(address firstImplementation, address initialOwner) UUPSProxyWithOwner(firstImplementation, initialOwner) { }
}

pragma solidity >=0.8.19;
/**
 * @title Library for access related errors.
 */

library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

pragma solidity >=0.8.19;
/**
 * @title Library for address related errors.
 */

library AddressError {
    /**
     * @dev Thrown when a zero address was passed as a function parameter (0x0000000000000000000000000000000000000000).
     */
    error ZeroAddress();

    /**
     * @dev Thrown when an address representing a contract is expected, but no code is found at the address.
     * @param contr The address that was expected to be a contract.
     */
    error NotAContract(address contr);
}

pragma solidity >=0.8.19;
/**
 * @title Library for change related errors.
 */

library ChangeError {
    /**
     * @dev Thrown when a change is expected but none is detected.
     */
    error NoChange();
}

pragma solidity >=0.8.19;

/**
 * @title Library for initialization related errors.
 */
library InitError {
    /**
     * @dev Thrown when attempting to initialize a contract that is already initialized.
     */
    error AlreadyInitialized();

    /**
     * @dev Thrown when attempting to interact with a contract that has not been initialized yet.
     */
    error NotInitialized();
}

pragma solidity >=0.8.19;

library AddressUtil {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
}

pragma solidity >=0.8.19;

/**
 * @title ERC721 non-fungible token (NFT) contract.
 */
interface IERC721 {
    /**
     * @notice Thrown when an address attempts to provide allowance to itself.
     * @param addr The address attempting to provide allowance.
     */
    error CannotSelfApprove(address addr);

    /**
     * @notice Thrown when attempting to transfer a token to an address that does not satisfy IERC721Receiver requirements.
     * @param addr The address that cannot receive the tokens.
     */
    error InvalidTransferRecipient(address addr);

    /**
     * @notice Thrown when attempting to specify an owner which is not valid (ex. the 0x00000... address)
     */
    error InvalidOwner(address addr);

    /**
     * @notice Thrown when attempting to operate on a token id that does not exist.
     * @param id The token id that does not exist.
     */
    error TokenDoesNotExist(uint256 id);

    /**
     * @notice Thrown when attempting to mint a token that already exists.
     * @param id The token id that already exists.
     */
    error TokenAlreadyMinted(uint256 id);

    /**
     * @notice Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @notice Returns the number of tokens in ``owner``'s account.
     *
     * Requirements:
     *
     * - `owner` must be a valid address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe
     * transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe
     * transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @notice Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @notice Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

pragma solidity >=0.8.19;

import "./IERC721.sol";
/**
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 */

interface IERC721Enumerable is IERC721 {
    /**
     * @notice Thrown calling *ByIndex function with an index greater than the number of tokens existing
     * @param requestedIndex The index requested by the caller
     * @param length The length of the list that is being iterated, making the max index queryable length - 1
     */
    error IndexOverrun(uint256 requestedIndex, uint256 length);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     *
     * Requirements:
     * - `owner` must be a valid address
     * - `index` must be less than the balance of the tokens for the owner
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     *
     * Requirements:
     * - `index` must be less than the total supply of the tokens
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity >=0.8.19;

/**
 * @title Contract for facilitating ownership by a single address.
 */

interface IOwnable {
    /**
     * @notice Thrown when an address tries to accept ownership but has not been nominated.
     * @param addr The address that is trying to accept ownership.
     */
    error NotNominated(address addr);

    /**
     * @notice Emitted when an address has been nominated.
     * @param newOwner The address that has been nominated.
     */
    event OwnerNominated(address newOwner);

    /**
     * @notice Emitted when the owner of the contract has changed.
     * @param oldOwner The previous owner of the contract.
     * @param newOwner The new owner of the contract.
     */
    event OwnerChanged(address oldOwner, address newOwner);

    /**
     * @notice Allows a nominated address to accept ownership of the contract.
     * @dev Reverts if the caller is not nominated.
     */
    function acceptOwnership() external;

    /**
     * @notice Allows the current owner to nominate a new owner.
     * @dev The nominated owner will have to call `acceptOwnership` in a separate transaction in order to finalize the action and
     * become the new contract owner.
     * @param newNominatedOwner The address that is to become nominated.
     */
    function nominateNewOwner(address newNominatedOwner) external;

    /**
     * @notice Allows a nominated owner to reject the nomination.
     */
    function renounceNomination() external;

    /**
     * @notice Returns the current owner of the contract.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the current nominated owner of the contract.
     * @dev Only one address can be nominated at a time.
     */
    function nominatedOwner() external view returns (address);
}

pragma solidity >=0.8.19;
/**
 * @title Contract to be used as the implementation of a Universal Upgradeable Proxy Standard (UUPS) proxy.
 *
 * Important: A UUPS proxy requires its upgradeability functions to be in the implementation as opposed to the proxy. This means
 * that if the proxy is upgraded to an implementation that does not support this interface, it will no longer be upgradeable.
 */

interface IUUPSImplementation {
    /**
     * @notice Thrown when an incoming implementation will not be able to receive future upgrades.
     */
    error ImplementationIsSterile(address implementation);

    /**
     * @notice Thrown intentionally when testing future upgradeability of an implementation.
     */
    error UpgradeSimulationFailed();

    /**
     * @notice Emitted when the implementation of the proxy has been upgraded.
     * @param self The address of the proxy whose implementation was upgraded.
     * @param implementation The address of the proxy's new implementation.
     */
    event Upgraded(address indexed self, address implementation);

    /**
     * @notice Allows the proxy to be upgraded to a new implementation.
     * @param newImplementation The address of the proxy's new implementation.
     * @dev Will revert if `newImplementation` is not upgradeable.
     * @dev The implementation of this function needs to be protected by some sort of access control such as `onlyOwner`.
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @notice Function used to determine if a new implementation will be able to receive future upgrades in `upgradeTo`.
     * @param newImplementation The address of the new implementation being tested for future upgradeability.
     * @dev This function will always revert, but will revert with different error messages. The function `upgradeTo` uses this
     * error to determine the future upgradeability of the implementation in question.
     */
    function simulateUpgradeTo(address newImplementation) external;

    /**
     * @notice Retrieves the current implementation of the proxy.
     * @return The address of the current implementation.
     */
    function getImplementation() external view returns (address);
}

pragma solidity >=0.8.19;

import "../storage/OwnableStorage.sol";
import "../interfaces/IOwnable.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";

/**
 * @title Contract for facilitating ownership by a single address.
 * See IOwnable.
 */
contract Ownable is IOwnable {
    constructor(address initialOwner) {
        OwnableStorage.load().owner = initialOwner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function acceptOwnership() public override {
        OwnableStorage.Data storage store = OwnableStorage.load();

        address currentNominatedOwner = store.nominatedOwner;
        if (msg.sender != currentNominatedOwner) {
            revert NotNominated(msg.sender);
        }

        emit OwnerChanged(store.owner, currentNominatedOwner);
        store.owner = currentNominatedOwner;

        store.nominatedOwner = address(0);
    }

    /**
     * @inheritdoc IOwnable
     */
    function nominateNewOwner(address newNominatedOwner) public override onlyOwner {
        OwnableStorage.Data storage store = OwnableStorage.load();

        if (newNominatedOwner == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (newNominatedOwner == store.nominatedOwner) {
            revert ChangeError.NoChange();
        }

        store.nominatedOwner = newNominatedOwner;
        emit OwnerNominated(newNominatedOwner);
    }

    /**
     * @inheritdoc IOwnable
     */
    function renounceNomination() external override {
        OwnableStorage.Data storage store = OwnableStorage.load();

        if (store.nominatedOwner != msg.sender) {
            revert NotNominated(msg.sender);
        }

        store.nominatedOwner = address(0);
    }

    /**
     * @inheritdoc IOwnable
     */
    function owner() external view override returns (address) {
        return OwnableStorage.load().owner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function nominatedOwner() external view override returns (address) {
        return OwnableStorage.load().nominatedOwner;
    }

    /**
     * @dev Reverts if the caller is not the owner.
     */
    modifier onlyOwner() {
        OwnableStorage.onlyOwner();

        _;
    }
}

pragma solidity >=0.8.19;

abstract contract AbstractProxy {
    fallback() external payable {
        _forward();
    }

    receive() external payable {
        _forward();
    }

    function _forward() internal {
        address implementation = _getImplementation();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _getImplementation() internal view virtual returns (address);
}

pragma solidity >=0.8.19;

import "../interfaces/IUUPSImplementation.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";
import "../helpers/AddressUtil.sol";
import "../storage/ProxyStorage.sol";

abstract contract UUPSImplementation is IUUPSImplementation, ProxyStorage {
    /**
     * @inheritdoc IUUPSImplementation
     */
    function simulateUpgradeTo(address newImplementation) public override {
        ProxyStore storage store = _proxyStore();

        store.simulatingUpgrade = true;

        address currentImplementation = store.implementation;
        store.implementation = newImplementation;

        (bool rollbackSuccessful,) =
            newImplementation.delegatecall(abi.encodeCall(this.upgradeTo, (currentImplementation)));

        if (!rollbackSuccessful || _proxyStore().implementation != currentImplementation) {
            revert UpgradeSimulationFailed();
        }

        store.simulatingUpgrade = false;

        // solhint-disable-next-line reason-string
        revert();
    }

    /**
     * @inheritdoc IUUPSImplementation
     */
    function getImplementation() external view override returns (address) {
        return _proxyStore().implementation;
    }

    function _upgradeTo(address newImplementation) internal virtual {
        if (newImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(newImplementation)) {
            revert AddressError.NotAContract(newImplementation);
        }

        ProxyStore storage store = _proxyStore();

        if (newImplementation == store.implementation) {
            revert ChangeError.NoChange();
        }

        if (!store.simulatingUpgrade && _implementationIsSterile(newImplementation)) {
            revert ImplementationIsSterile(newImplementation);
        }

        store.implementation = newImplementation;

        emit Upgraded(address(this), newImplementation);
    }

    function _implementationIsSterile(address candidateImplementation) internal virtual returns (bool) {
        (bool simulationReverted, bytes memory simulationResponse) =
            address(this).delegatecall(abi.encodeCall(this.simulateUpgradeTo, (candidateImplementation)));

        return !simulationReverted
            && keccak256(abi.encodePacked(simulationResponse))
                == keccak256(abi.encodePacked(UpgradeSimulationFailed.selector));
    }
}

pragma solidity >=0.8.19;

import "./AbstractProxy.sol";
import "../storage/ProxyStorage.sol";
import "../errors/AddressError.sol";
import "../helpers/AddressUtil.sol";

contract UUPSProxy is AbstractProxy, ProxyStorage {
    constructor(address firstImplementation) {
        if (firstImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(firstImplementation)) {
            revert AddressError.NotAContract(firstImplementation);
        }

        _proxyStore().implementation = firstImplementation;
    }

    function _getImplementation() internal view virtual override returns (address) {
        return _proxyStore().implementation;
    }
}

pragma solidity >=0.8.19;

import "./UUPSProxy.sol";
import "../storage/OwnableStorage.sol";

contract UUPSProxyWithOwner is UUPSProxy {
    // solhint-disable-next-line no-empty-blocks
    constructor(address firstImplementation, address initialOwner) UUPSProxy(firstImplementation) {
        OwnableStorage.load().owner = initialOwner;
    }
}

pragma solidity >=0.8.19;

import "../errors/AccessError.sol";

library OwnableStorage {
    bytes32 private constant _SLOT_OWNABLE_STORAGE = keccak256(abi.encode("xyz.voltz.OwnableStorage"));

    struct Data {
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_OWNABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

pragma solidity >=0.8.19;

contract ProxyStorage {
    bytes32 private constant _SLOT_PROXY_STORAGE = keccak256(abi.encode("xyz.voltz.Proxy"));

    struct ProxyStore {
        address implementation;
        bool simulatingUpgrade;
    }

    function _proxyStore() internal pure returns (ProxyStore storage store) {
        bytes32 s = _SLOT_PROXY_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

pragma solidity >=0.8.19;

/**
 * @title Module for connecting a system with other associated systems.
 * Associated systems become available to all system modules for communication and interaction,
 * but as opposed to inter-modular communications, interactions with associated systems will require the use of `CALL`.
 *
 * Associated systems can be managed or unmanaged.
 * - Managed systems are connected via a proxy, which means that their implementation can be updated,
 * and the system controls the execution context of the associated system. Example,
 * account token connected to the system, and controlled by the system.
 * - Unmanaged systems are just addresses tracked by the system, for which it has no control whatsoever.
 * Currently, we're not using these, however may consider using for interactions with external
 * instruments and exchanges (e.g. dated irs instrument).
 *
 * Furthermore, associated systems are typed in the AssociatedSystem utility library (See AssociatedSystem.sol):
 * - KIND_ERC721: A managed associated system specifically wrapping an ERC721 implementation.
 * - KIND_UNMANAGED: Any unmanaged associated system. (currently not supporting this)
 */
interface IBaseAssociatedSystemsModule {
    /**
     * @notice Emitted when an associated system is set.
     * @param kind The type of associated system (managed ERC721, etc - See the AssociatedSystem util).
     * @param id The bytes32 identifier of the associated system.
     * @param proxy The main external contract address of the associated system.
     * @param impl The address of the implementation of the associated system (if not behind a proxy, will equal `proxy`).
     */
    event AssociatedSystemSet(bytes32 indexed kind, bytes32 indexed id, address proxy, address impl);

    /**
     * @notice Emitted when the function you are calling requires an associated system, but it
     * has not been registered
     */
    error MissingAssociatedSystem(bytes32 id);

    /**
     * @notice Creates or initializes a managed associated ERC721 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system,
     * it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param uri The token uri that will be used to initialize the proxy.
     * @param impl The ERC721 implementation of the proxy.
     */
    function initOrUpgradeNft(bytes32 id, string memory name, string memory symbol, string memory uri, address impl)
        external;

    /**
     * @notice Retrieves an associated system.
     * @param id The bytes32 identifier used to reference the associated system.
     * @return addr The external contract address of the associated system.
     * @return kind The type of associated system (managed ERC721, etc - See the AssociatedSystem util).
     */
    function getAssociatedSystem(bytes32 id) external view returns (address addr, bytes32 kind);
}

pragma solidity >=0.8.19;

/**
 * @title Module for giving a system owner based access control.
 */
// solhint-disable-next-line no-empty-blocks
interface IBaseOwnerModule {}

pragma solidity >=0.8.19;

import "@voltz-protocol/util-contracts/src/interfaces/IERC721Enumerable.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 */
interface INftModule is IERC721Enumerable {
    /**
     * @notice Returns wether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and uri.
     */
    function initialize(string memory tokenName, string memory tokenSymbol, string memory uri) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param tokenId The ID of the newly minted token
     */
    function mint(address to, uint256 tokenId) external;

    /**
     * @notice Allows the owner to mint tokens. Verifies that the receiver can receive the token
     * @param to The address to receive the newly minted token.
     * @param tokenId The ID of the newly minted token
     * @param data any data which should be sent to the receiver
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param tokenId The token to burn
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param tokenId The token which should be allowed to spender
     * @param spender The address that is given allowance.
     */
    function setAllowance(uint256 tokenId, address spender) external;
}

pragma solidity >=0.8.19;

import "@voltz-protocol/util-contracts/src/errors/InitError.sol";
import "@voltz-protocol/util-contracts/src/storage/OwnableStorage.sol";
import "@voltz-protocol/util-contracts/src/proxy/UUPSProxyWithOwner.sol";
import "@voltz-protocol/util-contracts/src/interfaces/IUUPSImplementation.sol";
import "../interfaces/IBaseAssociatedSystemsModule.sol";
import "../interfaces/INftModule.sol";
import "../storage/AssociatedSystem.sol";
/**
 * @title Module for connecting a system with other associated systems.
 * @dev See IBaseAssociatedSystemsModule.
 */

contract BaseAssociatedSystemsModule is IBaseAssociatedSystemsModule {
    using AssociatedSystem for AssociatedSystem.Data;

    /**
     * @inheritdoc IBaseAssociatedSystemsModule
     */
    function initOrUpgradeNft(bytes32 id, string memory name, string memory symbol, string memory uri, address impl)
        external
        override
    {
        OwnableStorage.onlyOwner();
        _initOrUpgradeNft(id, name, symbol, uri, impl);
    }

    /**
     * @inheritdoc IBaseAssociatedSystemsModule
     */
    function getAssociatedSystem(bytes32 id) external view override returns (address addr, bytes32 kind) {
        addr = AssociatedSystem.load(id).proxy;
        kind = AssociatedSystem.load(id).kind;
    }

    modifier onlyIfAssociated(bytes32 id) {
        if (address(AssociatedSystem.load(id).proxy) == address(0)) {
            revert MissingAssociatedSystem(id);
        }

        _;
    }

    function _setAssociatedSystem(bytes32 id, bytes32 kind, address proxy, address impl) internal {
        AssociatedSystem.load(id).set(proxy, impl, kind);
        emit AssociatedSystemSet(kind, id, proxy, impl);
    }

    function _upgradeNft(bytes32 id, address impl) internal {
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);
        store.expectKind(AssociatedSystem.KIND_ERC721);

        store.impl = impl;

        address proxy = store.proxy;

        // tell the associated proxy to upgrade to the new implementation
        IUUPSImplementation(proxy).upgradeTo(impl);

        _setAssociatedSystem(id, AssociatedSystem.KIND_ERC721, proxy, impl);
    }

    function _initOrUpgradeNft(bytes32 id, string memory name, string memory symbol, string memory uri, address impl)
        internal
    {
        OwnableStorage.onlyOwner();
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);

        if (store.proxy != address(0)) {
            _upgradeNft(id, impl);
        } else {
            // create a new proxy and own it
            address proxy = address(new UUPSProxyWithOwner(impl, address(this)));

            INftModule(proxy).initialize(name, symbol, uri);

            _setAssociatedSystem(id, AssociatedSystem.KIND_ERC721, proxy, impl);
        }
    }
}

pragma solidity >=0.8.19;

import "../interfaces/IBaseOwnerModule.sol";
import "@voltz-protocol/util-contracts/src/ownership/Ownable.sol";

/**
 * @title Module for giving a system owner based access control.
 * See IOwnerModule.
 */
contract BaseOwnerModule is Ownable, IBaseOwnerModule {
    // solhint-disable-next-line no-empty-blocks
    constructor() Ownable(address(0)) {
        // empty intentionally
    }

    // no impl intentionally
}

pragma solidity >=0.8.19;

import "@voltz-protocol/util-contracts/src/proxy/UUPSImplementation.sol";
import "@voltz-protocol/util-contracts/src/storage/OwnableStorage.sol";

contract BaseUpgradeModule is UUPSImplementation {
    function upgradeTo(address newImplementation) public override {
        OwnableStorage.onlyOwner();
        _upgradeTo(newImplementation);
    }
}

pragma solidity >=0.8.19;

import "./BaseOwnerModule.sol";
import "./BaseUpgradeModule.sol";

// solhint-disable-next-line no-empty-blocks
contract OwnerUpgradeModule is BaseOwnerModule, BaseUpgradeModule {}

pragma solidity >=0.8.19;

import "../interfaces/INftModule.sol";

library AssociatedSystem {
    struct Data {
        address proxy;
        address impl;
        bytes32 kind;
    }

    error MismatchAssociatedSystemKind(bytes32 expected, bytes32 actual);

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.AssociatedSystem", id));
        assembly {
            store.slot := s
        }
    }

    bytes32 public constant KIND_ERC721 = "erc721";

    function getAddress(Data storage self) internal view returns (address) {
        return self.proxy;
    }

    function asNft(Data storage self) internal view returns (INftModule) {
        expectKind(self, KIND_ERC721);
        return INftModule(self.proxy);
    }

    function set(Data storage self, address proxy, address impl, bytes32 kind) internal {
        self.proxy = proxy;
        self.impl = impl;
        self.kind = kind;
    }

    function expectKind(Data storage self, bytes32 kind) internal view {
        bytes32 actualKind = self.kind;

        if (actualKind != kind) {
            revert MismatchAssociatedSystemKind(kind, actualKind);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@voltz-protocol/util-contracts/src/proxy/UUPSProxyWithOwner.sol";

/**
 * Voltz V2 VAMM Proxy Contract
 */
contract VammProxy is UUPSProxyWithOwner {
    // solhint-disable-next-line no-empty-blocks
    constructor(address firstImplementation, address initialOwner)
        UUPSProxyWithOwner(firstImplementation, initialOwner)
    {}
}

pragma solidity >=0.8.19;

import "oz/utils/cryptography/MerkleProof.sol";

import "./interfaces/ICommunityDeployer.sol";

import "./storage/CoreDeployment.sol";
import "./storage/DatedIrsDeployment.sol";
import "./storage/PeripheryDeployment.sol";
import "./storage/VammDeployment.sol";

contract CommunityDeployer is ICommunityDeployer {
    /// @notice Timelock Period In Seconds, once the deployment is queued,
    /// 1 day needs to pass in order to make deployment of the Voltz Factory possible
    uint256 public constant TIMELOCK_PERIOD_IN_SECONDS = 1 days;

    /// @notice Multisig owner address
    address public ownerAddress;

    /// @notice The number of votes in support of a proposal required in order for a quorum
    /// to be reached and for a vote to succeed
    uint256 public quorumVotes;

    /// @notice Total number of votes in favour of deploying Voltz Protocol V2 Core
    uint256 public yesVoteCount;

    /// @notice Total number of votes against the deployment of Voltz Protocol V2 Core
    uint256 public noVoteCount;

    /// @notice voting end block timestamp (once this contract is deployed, voting is considered
    /// to be officially started)
    uint256 public blockTimestampVotingEnd;

    /// @notice timelock end block timestamp (once the proposal is queued, the timelock period pre-deployment
    /// is considered to be officially started)
    uint256 public blockTimestampTimelockEnd;

    /// @notice isQueued needs to be true in order for the timelock period to start in advance of the deployment
    bool public isQueued;

    /// @notice isDeployed makes sure contract is deploying at most one Core Proxy
    bool public isDeployed;

    // Merkle Tree
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private _votedBitMap;

    /// @notice Voltz V2 Core Proxy to be deployed in a scenario where a successful vote is 
    /// followed by the queue and deployment
    address public coreProxy;

    /// @notice Voltz V2 Account NFT Proxy to be deployed in a scenario where a successful vote is 
    /// followed by the queue and deployment
    address public accountNftProxy;

    /// @notice Voltz V2 Dated IRS Proxy to be deployed in a scenario where a successful vote is 
    /// followed by the queue and deployment
    address public datedIrsProxy;

    /// @notice Voltz V2 Periphery Proxy to be deployed in a scenario where a successful vote is 
    /// followed by the queue and deployment
    address public peripheryProxy;

    /// @notice Voltz V2 VAMM Proxy to be deployed in a scenario where a successful vote is 
    /// followed by the queue and deployment
    address public vammProxy;

    constructor(
        uint256 _quorumVotes,
        address _ownerAddress,
        bytes32 _merkleRoot,
        uint256 _blockTimestampVotingEnd,
        CoreDeployment.Data memory _coreDeploymentConfig,
        DatedIrsDeployment.Data memory _datedIrsDeploymentConfig,
        PeripheryDeployment.Data memory _peripheryDeploymentConfig,
        VammDeployment.Data memory _vammDeploymentConfig
    ) {
        quorumVotes = _quorumVotes;
        ownerAddress = _ownerAddress;
        merkleRoot = _merkleRoot;
        blockTimestampVotingEnd = _blockTimestampVotingEnd;

        CoreDeployment.set(_coreDeploymentConfig);
        DatedIrsDeployment.set(_datedIrsDeploymentConfig);
        PeripheryDeployment.set(_peripheryDeploymentConfig);
        VammDeployment.set(_vammDeploymentConfig);
    }

    function hasVoted(uint256 index) public override view returns (bool) {
        uint256 votedWordIndex = index / 256;
        uint256 votedBitIndex = index % 256;
        uint256 votedWord = _votedBitMap[votedWordIndex];
        uint256 mask = (1 << votedBitIndex);
        return votedWord & mask == mask;
    }

    function _setVoted(uint256 index) private {
        uint256 votedWordIndex = index / 256;
        uint256 votedBitIndex = index % 256;
        _votedBitMap[votedWordIndex] = _votedBitMap[votedWordIndex] | (1 << votedBitIndex);
    }

    /// @notice Deploy the Voltz Factory by passing the masterVAMM and the masterMarginEngine
    /// into the Factory constructor
    function deploy() external override {
        require(isQueued, "not queued");
        require(block.timestamp > blockTimestampTimelockEnd, "timelock is ongoing");
        require(isDeployed == false, "already deployed");

        (coreProxy, accountNftProxy) = CoreDeployment.deploy(ownerAddress);
        datedIrsProxy = DatedIrsDeployment.deploy(ownerAddress);
        peripheryProxy = PeripheryDeployment.deploy(ownerAddress);
        vammProxy = VammDeployment.deploy(ownerAddress);

        isDeployed = true;
    }

    /// @notice Queue the deployment of the Voltz Factory
    function queue() external override {
        require(block.timestamp > blockTimestampVotingEnd, "voting is ongoing");
        require(yesVoteCount >= quorumVotes, "quorum not reached");
        require(yesVoteCount > noVoteCount, "no >= yes");
        require(isQueued == false, "already queued");
        isQueued = true;
        blockTimestampTimelockEnd = block.timestamp + TIMELOCK_PERIOD_IN_SECONDS;
    }

    /// @notice Vote for the proposal to deploy the Voltz Factory contract
    /// @param _index index of the voter
    /// @param _numberOfVotes number of voltz genesis nfts held by the msg.sender before the snapshot was taken
    /// @param _yesVote if this boolean is true then the msg.sender is casting a yes vote,
    /// if the boolean is false the msg.sender is casting a no vote
    /// @param _merkleProof merkle proof that needs to be verified against the merkle root to
    /// check the msg.sender against the snapshot
    function castVote(uint256 _index, uint256 _numberOfVotes, bool _yesVote, bytes32[] calldata _merkleProof)
        external override
    {
        require(block.timestamp <= blockTimestampVotingEnd, "voting period over");

        // check if msg.sender has already voted
        require(!hasVoted(_index), "duplicate vote");

        // verify the merkle proof
        bytes32 _node = keccak256(abi.encodePacked(_index, msg.sender, _numberOfVotes));
        require(MerkleProof.verify(_merkleProof, merkleRoot, _node), "invalid merkle proof");

        // mark hasVoted
        _setVoted(_index);

        // cast the vote
        if (_yesVote) {
            yesVoteCount += _numberOfVotes;
        } else {
            noVoteCount += _numberOfVotes;
        }

        // emit an event
        emit Voted(_index, msg.sender, _numberOfVotes, _yesVote);
    }
}

pragma solidity >=0.8.19;

/**
 * @title Commmunity Deployer Interface.
 */
interface ICommunityDeployer {
    // This event is triggered whenever a call to cast a vote succeeds
    event Voted(uint256 index, address account, uint256 numberOfVotes, bool yesVote);

    function hasVoted(uint256 index) external view returns (bool);
  
    function deploy() external;

    function queue() external;

    function castVote(
      uint256 _index, 
      uint256 _numberOfVotes, 
      bool _yesVote, 
      bytes32[] calldata _merkleProof
    ) external;
}

pragma solidity >=0.8.19;

// Core
import "@voltz-protocol/core/src/CoreProxy.sol";
import "@voltz-protocol/core/src/modules/AssociatedSystemsModule.sol";

import "@voltz-protocol/util-modules/src/modules/OwnerUpgradeModule.sol";

/**
 * @title Core Deployment
 */
library CoreDeployment {
    /**
     * @dev Thrown when CoreRouter is missing
     */
    error MissingCoreRouter();
    /**
     * @dev Thrown when AccountNftRouter is missing
     */
    error MissingAccountNftRouter();

    struct Data {
        /// @notice Voltz Protocol V2 Core Router
        address coreRouter;

        /// @notice Voltz Protocol V2 Account NFT Router
        address accountNftRouter;

        /// @notice Id of Voltz Protocol V2 Account NFT as stored in the core proxy's associated system
        bytes32 accountNftId;

        /// @notice Name of Voltz Protocol V2 Account NFT
        string accountNftName;

        /// @notice Symbol of Voltz Protocol V2 Account NFT
        string accountNftSymbol;

        /// @notice Uri of Voltz Protocol V2 Account NFT
        string accountNftUri;
    }

    /**
     * @dev Loads the CoreDeploymentConfiguration object.
     * @return config The CoreDeploymentConfiguration object.
     */
    function load() internal pure returns (Data storage config) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.CommunityCoreDeployment"));
        assembly {
            config.slot := s
        }
    }

    /**
     * @dev Sets the core deployment configuration
     * @param config The CoreDeploymentConfiguration object with all the parameters
     */
    function set(Data memory config) internal {
        Data storage storedConfig = load();
        if (config.coreRouter == address(0)) {
            revert MissingCoreRouter();
        }
        if (config.accountNftRouter == address(0)) {
            revert MissingAccountNftRouter();
        }
        storedConfig.coreRouter = config.coreRouter;
        storedConfig.accountNftRouter = config.accountNftRouter;
        storedConfig.accountNftId = config.accountNftId;
        storedConfig.accountNftName = config.accountNftName;
        storedConfig.accountNftSymbol = config.accountNftSymbol;
        storedConfig.accountNftUri = config.accountNftUri;
    }

    function deploy(address ownerAddress) internal returns (address coreProxy, address accountNftProxy) {
        Data storage config = load();

        coreProxy = address(new CoreProxy(config.coreRouter, address(this)));
        AssociatedSystemsModule(coreProxy).initOrUpgradeNft(
            config.accountNftId, config.accountNftName, config.accountNftSymbol, config.accountNftUri, config.accountNftRouter
        );
        OwnerUpgradeModule(coreProxy).nominateNewOwner(ownerAddress);

        (accountNftProxy, ) = AssociatedSystemsModule(coreProxy).getAssociatedSystem(config.accountNftId);
    }
}

pragma solidity >=0.8.19;

// Dated IRS
import "@voltz-protocol/products-dated-irs/src/ProductProxy.sol";

import "@voltz-protocol/util-modules/src/modules/OwnerUpgradeModule.sol";

/**
 * @title DatedIrs Deployment
 */
library DatedIrsDeployment {
    /**
     * @dev Thrown when DatedIrsRouter is missing
     */
    error MissingDatedIrsRouter();

    struct Data {
        /// @notice Voltz Protocol V2 Dated IRS Router
        address datedIrsRouter;
    }

    /**
     * @dev Loads the DatedIrsConfiguration object.
     * @return config The DatedIrsConfiguration object.
     */
    function load() internal pure returns (Data storage config) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.CommunityDatedIrsDeployment"));
        assembly {
            config.slot := s
        }
    }

    /**
     * @dev Sets the dated irs deployment configuration
     * @param config The DatedIrsDeploymentConfiguration object with all the parameters
     */
    function set(Data memory config) internal {
        Data storage storedConfig = load();
        if (config.datedIrsRouter == address(0)) {
            revert MissingDatedIrsRouter();
        }
        storedConfig.datedIrsRouter = config.datedIrsRouter;
    }

    function deploy(address ownerAddress) internal returns (address datedIrsProxy) {
        Data storage config = load();

        datedIrsProxy = address(new ProductProxy(config.datedIrsRouter, address(this)));
        OwnerUpgradeModule(datedIrsProxy).nominateNewOwner(ownerAddress);
    }
}

pragma solidity >=0.8.19;

// Periphery
import "@voltz-protocol/periphery/src/PeripheryProxy.sol";

import "@voltz-protocol/util-modules/src/modules/OwnerUpgradeModule.sol";

/**
 * @title Periphery Deployment
 */
library PeripheryDeployment {
    /**
     * @dev Thrown when PeripheryRouter is missing
     */
    error MissingPeripheryRouter();

    struct Data {
        /// @notice Voltz Protocol V2 Periphery Router
        address peripheryRouter;
    }

    /**
     * @dev Loads the PeripheryConfiguration object.
     * @return config The PeripheryConfiguration object.
     */
    function load() internal pure returns (Data storage config) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.CommunityPeripheryDeployment"));
        assembly {
            config.slot := s
        }
    }

    /**
     * @dev Sets the periphery deployment configuration
     * @param config The PeripheryDeploymentConfiguration object with all the parameters
     */
    function set(Data memory config) internal {
        Data storage storedConfig = load();
        if (config.peripheryRouter == address(0)) {
            revert MissingPeripheryRouter();
        }
        storedConfig.peripheryRouter = config.peripheryRouter;
    }

    function deploy(address ownerAddress) internal returns (address peripheryProxy) {
        Data storage config = load();

        peripheryProxy = address(new PeripheryProxy(config.peripheryRouter, address(this)));
        OwnerUpgradeModule(peripheryProxy).nominateNewOwner(ownerAddress);
    }
}

pragma solidity >=0.8.19;

// Vamm
import "@voltz-protocol/v2-vamm/src/VammProxy.sol";

import "@voltz-protocol/util-modules/src/modules/OwnerUpgradeModule.sol";

/**
 * @title Vamm Deployment
 */
library VammDeployment {
    /**
     * @dev Thrown when VammRouter is missing
     */
    error MissingVammRouter();

    struct Data {
        /// @notice Voltz Protocol V2 Vamm Router
        address vammRouter;
    }

    /**
     * @dev Loads the VammConfiguration object.
     * @return config The VammConfiguration object.
     */
    function load() internal pure returns (Data storage config) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.CommunityVammDeployment"));
        assembly {
            config.slot := s
        }
    }

    /**
     * @dev Sets the vamm deployment configuration
     * @param config The VammDeploymentConfiguration object with all the parameters
     */
    function set(Data memory config) internal {
        Data storage storedConfig = load();
        if (config.vammRouter == address(0)) {
            revert MissingVammRouter();
        }
        storedConfig.vammRouter = config.vammRouter;
    }

    function deploy(address ownerAddress) internal returns (address vammProxy) {
        Data storage config = load();

        vammProxy = address(new VammProxy(config.vammRouter, address(this)));
        OwnerUpgradeModule(vammProxy).nominateNewOwner(ownerAddress);
    }
}