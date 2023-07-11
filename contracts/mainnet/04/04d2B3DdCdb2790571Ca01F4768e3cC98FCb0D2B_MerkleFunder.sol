// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SelfMulticall.sol";
import "./interfaces/IExtendedSelfMulticall.sol";

/// @title Contract that extends SelfMulticall to fetch some of the global
/// variables
/// @notice Available global variables are limited to the ones that Airnode
/// tends to need
contract ExtendedSelfMulticall is SelfMulticall, IExtendedSelfMulticall {
    /// @notice Returns the chain ID
    /// @return Chain ID
    function getChainId() external view override returns (uint256) {
        return block.chainid;
    }

    /// @notice Returns the account balance
    /// @param account Account address
    /// @return Account balance
    function getBalance(
        address account
    ) external view override returns (uint256) {
        return account.balance;
    }

    /// @notice Returns if the account contains bytecode
    /// @dev An account not containing any bytecode does not indicate that it
    /// is an EOA or it will not contain any bytecode in the future.
    /// Contract construction and `SELFDESTRUCT` updates the bytecode at the
    /// end of the transaction.
    /// @return If the account contains bytecode
    function containsBytecode(
        address account
    ) external view override returns (bool) {
        return account.code.length > 0;
    }

    /// @notice Returns the current block number
    /// @return Current block number
    function getBlockNumber() external view override returns (uint256) {
        return block.number;
    }

    /// @notice Returns the current block timestamp
    /// @return Current block timestamp
    function getBlockTimestamp() external view override returns (uint256) {
        return block.timestamp;
    }

    /// @notice Returns the current block basefee
    /// @return Current block basefee
    function getBlockBasefee() external view override returns (uint256) {
        return block.basefee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISelfMulticall.sol";

interface IExtendedSelfMulticall is ISelfMulticall {
    function getChainId() external view returns (uint256);

    function getBalance(address account) external view returns (uint256);

    function containsBytecode(address account) external view returns (bool);

    function getBlockNumber() external view returns (uint256);

    function getBlockTimestamp() external view returns (uint256);

    function getBlockBasefee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISelfMulticall {
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory returndata);

    function tryMulticall(
        bytes[] calldata data
    ) external returns (bool[] memory successes, bytes[] memory returndata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISelfMulticall.sol";

/// @title Contract that enables calls to the inheriting contract to be batched
/// @notice Implements two ways of batching, one requires none of the calls to
/// revert and the other tolerates individual calls reverting
/// @dev This implementation uses delegatecall for individual function calls.
/// Since delegatecall is a message call, it can only be made to functions that
/// are externally visible. This means that a contract cannot multicall its own
/// functions that use internal/private visibility modifiers.
/// Refer to OpenZeppelin's Multicall.sol for a similar implementation.
contract SelfMulticall is ISelfMulticall {
    /// @notice Batches calls to the inheriting contract and reverts as soon as
    /// one of the batched calls reverts
    /// @param data Array of calldata of batched calls
    /// @return returndata Array of returndata of batched calls
    function multicall(
        bytes[] calldata data
    ) external override returns (bytes[] memory returndata) {
        uint256 callCount = data.length;
        returndata = new bytes[](callCount);
        for (uint256 ind = 0; ind < callCount; ) {
            bool success;
            // solhint-disable-next-line avoid-low-level-calls
            (success, returndata[ind]) = address(this).delegatecall(data[ind]);
            if (!success) {
                bytes memory returndataWithRevertData = returndata[ind];
                if (returndataWithRevertData.length > 0) {
                    // Adapted from OpenZeppelin's Address.sol
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        let returndata_size := mload(returndataWithRevertData)
                        revert(
                            add(32, returndataWithRevertData),
                            returndata_size
                        )
                    }
                } else {
                    revert("Multicall: No revert string");
                }
            }
            unchecked {
                ind++;
            }
        }
    }

    /// @notice Batches calls to the inheriting contract but does not revert if
    /// any of the batched calls reverts
    /// @param data Array of calldata of batched calls
    /// @return successes Array of success conditions of batched calls
    /// @return returndata Array of returndata of batched calls
    function tryMulticall(
        bytes[] calldata data
    )
        external
        override
        returns (bool[] memory successes, bytes[] memory returndata)
    {
        uint256 callCount = data.length;
        successes = new bool[](callCount);
        returndata = new bytes[](callCount);
        for (uint256 ind = 0; ind < callCount; ) {
            // solhint-disable-next-line avoid-low-level-calls
            (successes[ind], returndata[ind]) = address(this).delegatecall(
                data[ind]
            );
            unchecked {
                ind++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@api3/airnode-protocol-v1/contracts/utils/interfaces/IExtendedSelfMulticall.sol";

interface IMerkleFunder is IExtendedSelfMulticall {
    event DeployedMerkleFunderDepository(
        address indexed merkleFunderDepository,
        address owner,
        bytes32 root
    );

    event Funded(
        address indexed merkleFunderDepository,
        address recipient,
        uint256 amount
    );

    event Withdrew(
        address indexed merkleFunderDepository,
        address recipient,
        uint256 amount
    );

    error RootZero();

    error RecipientAddressZero();

    error LowThresholdHigherThanHigh();

    error HighThresholdZero();

    error InvalidProof();

    error RecipientBalanceLargerThanLowThreshold();

    error NoSuchMerkleFunderDepository();

    error AmountZero();

    error InsufficientBalance();

    function deployMerkleFunderDepository(
        address owner,
        bytes32 root
    ) external returns (address payable merkleFunderDepository);

    function fund(
        address owner,
        bytes32 root,
        bytes32[] calldata proof,
        address recipient,
        uint256 lowThreshold,
        uint256 highThreshold
    ) external returns (uint256 amount);

    function withdraw(bytes32 root, address recipient, uint256 amount) external;

    function withdrawAll(
        bytes32 root,
        address recipient
    ) external returns (uint256 amount);

    function computeMerkleFunderDepositoryAddress(
        address owner,
        bytes32 root
    ) external view returns (address merkleFunderDepository);

    function ownerToRootToMerkleFunderDepositoryAddress(
        address owner,
        bytes32 root
    ) external view returns (address payable merkleFunderDepository);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMerkleFunderDepository {
    error SenderNotMerkleFunder();

    error TransferUnsuccessful();

    function merkleFunder() external view returns (address);

    function owner() external view returns (address);

    function root() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@api3/airnode-protocol-v1/contracts/utils/ExtendedSelfMulticall.sol";
import "./interfaces/IMerkleFunder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./MerkleFunderDepository.sol";

/// @title Contract that can be called to deploy MerkleFunderDepository
/// contracts or transfer the funds in them within the limitations specified by
/// the respective Merkle trees
/// @notice Use-cases such as self-funded data feeds require users to keep
/// multiple accounts funded. The only way to achieve this without relying on
/// on-chain activity is running a bot that triggers the funding using a hot
/// wallet. In the naive implementation, the funds to be used would also be
/// kept by this hot wallet, which is obviously risky. This contract allows one
/// to deploy a MerkleFunderDepository where they can keep the funds, which
/// this contract only allows to be transferred within the limitations
/// specified by the respective Merkle tree. This means the bot's hot wallet no
/// longer needs to be trusted with the funds, and multiple bots with different
/// hot wallets can be run against the same MerkleFunderDepository deployment
/// for redundancy.
/// @dev MerkleFunder inherits SelfMulticall to allow `fund()` to be
/// multi-called so that multiple fundings can be executed in a single
/// transaction without depending on an external contract. Furthermore, it
/// inherits ExtendedSelfMulticall to allow `getBlockNumber()` be multi-called
/// to avoid race conditions that would have caused the bot implementation to
/// make redundant transactions that revert.
contract MerkleFunder is ExtendedSelfMulticall, IMerkleFunder {
    /// @notice Returns the address of the MerkleFunderDepository deployed for
    /// the owner address and the Merkle tree root, and zero-address if such a
    /// MerkleFunderDepository is not deployed yet
    /// @dev The MerkleFunderDepository address can be derived from the owner
    /// address and the Merkle tree root using
    /// `computeMerkleFunderDepositoryAddress()`, yet doing so is more
    /// expensive than reading it from this mapping, which is why we prefer
    /// storing it during deployment
    mapping(address => mapping(bytes32 => address payable))
        public
        override ownerToRootToMerkleFunderDepositoryAddress;

    /// @notice Called to deterministically deploy the MerkleFunderDepository
    /// with the owner address and the Merkle tree root
    /// @dev The owner address is allowed to be zero in case the deployer wants
    /// to disallow `withdraw()` from being called for the respective
    /// MerkleFunderDepository.
    /// See `fund()` for how the Merkle tree leaves are derived and how the
    /// comprising parameters are validated.
    /// @param owner Owner address
    /// @param root Merkle tree root
    /// @return merkleFunderDepository MerkleFunderDepository address
    function deployMerkleFunderDepository(
        address owner,
        bytes32 root
    ) external override returns (address payable merkleFunderDepository) {
        if (root == bytes32(0)) revert RootZero();
        merkleFunderDepository = payable(
            new MerkleFunderDepository{salt: bytes32(0)}(owner, root)
        );
        ownerToRootToMerkleFunderDepositoryAddress[owner][
            root
        ] = merkleFunderDepository;
        emit DeployedMerkleFunderDepository(
            merkleFunderDepository,
            owner,
            root
        );
    }

    /// @notice Called to transfer funds from a MerkleFunderDepository to the
    /// recipient within the limitations specified by the respective Merkle
    /// tree
    /// @param owner Owner address
    /// @param root Merkle tree root
    /// @param proof Merkle tree proof
    /// @param recipient Recipient address
    /// @param lowThreshold Low hysteresis threshold
    /// @param highThreshold High hysteresis threshold
    /// @return amount Amount used in funding
    function fund(
        address owner,
        bytes32 root,
        bytes32[] calldata proof,
        address recipient,
        uint256 lowThreshold,
        uint256 highThreshold
    ) external override returns (uint256 amount) {
        if (recipient == address(0)) revert RecipientAddressZero();
        if (lowThreshold > highThreshold) revert LowThresholdHigherThanHigh();
        if (highThreshold == 0) revert HighThresholdZero();
        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(abi.encode(recipient, lowThreshold, highThreshold))
            )
        );
        if (!MerkleProof.verify(proof, root, leaf)) revert InvalidProof();
        uint256 recipientBalance = recipient.balance;
        if (recipientBalance > lowThreshold)
            revert RecipientBalanceLargerThanLowThreshold();
        address payable merkleFunderDepository = ownerToRootToMerkleFunderDepositoryAddress[
                owner
            ][root];
        if (merkleFunderDepository == address(0))
            revert NoSuchMerkleFunderDepository();
        uint256 amountNeededToTopUp;
        unchecked {
            amountNeededToTopUp = highThreshold - recipientBalance;
        }
        amount = amountNeededToTopUp <= merkleFunderDepository.balance
            ? amountNeededToTopUp
            : merkleFunderDepository.balance;
        if (amount == 0) revert AmountZero();
        MerkleFunderDepository(merkleFunderDepository).transfer(
            recipient,
            amount
        );
        emit Funded(merkleFunderDepository, recipient, amount);
    }

    /// @notice Called by the owner of the respective MerkleFunderDepository to
    /// withdraw funds in a way that is exempt from the limitations specified
    /// by the respective Merkle tree
    /// @param root Merkle tree root
    /// @param recipient Recipient address
    /// @param amount Withdrawal amount
    function withdraw(
        bytes32 root,
        address recipient,
        uint256 amount
    ) public override {
        if (recipient == address(0)) revert RecipientAddressZero();
        if (amount == 0) revert AmountZero();
        address payable merkleFunderDepository = ownerToRootToMerkleFunderDepositoryAddress[
                msg.sender
            ][root];
        if (merkleFunderDepository == address(0))
            revert NoSuchMerkleFunderDepository();
        if (merkleFunderDepository.balance < amount)
            revert InsufficientBalance();
        MerkleFunderDepository(merkleFunderDepository).transfer(
            recipient,
            amount
        );
        emit Withdrew(merkleFunderDepository, recipient, amount);
    }

    /// @notice Called by the owner of the respective MerkleFunderDepository to
    /// withdraw its entire balance in a way that is exempt from the
    /// limitations specified by the respective Merkle tree
    /// @param root Merkle tree root
    /// @param recipient Recipient address
    /// @return amount Withdrawal amount
    function withdrawAll(
        bytes32 root,
        address recipient
    ) external override returns (uint256 amount) {
        amount = ownerToRootToMerkleFunderDepositoryAddress[msg.sender][root]
            .balance;
        withdraw(root, recipient, amount);
    }

    /// @notice Computes the address of the MerkleFunderDepository
    /// @param owner Owner address
    /// @param root Merkle tree root
    /// @return merkleFunderDepository MerkleFunderDepository address
    function computeMerkleFunderDepositoryAddress(
        address owner,
        bytes32 root
    ) external view override returns (address merkleFunderDepository) {
        if (root == bytes32(0)) revert RootZero();
        merkleFunderDepository = Create2.computeAddress(
            bytes32(0),
            keccak256(
                abi.encodePacked(
                    type(MerkleFunderDepository).creationCode,
                    abi.encode(owner, root)
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IMerkleFunderDepository.sol";

/// @title Contract that is deployed through MerkleFunder and keeps the funds
/// that can be transferred within the limitations specified by the respective
/// Merkle tree
/// @notice As noted above, this contract should only be deployed by a
/// MerkleFunder contract. Since the owner address and the Merkle tree root are
/// immutable, the only way to update these is to deploy a new
/// MerkleFunderDepository with the desired parameters and have the owner of
/// the previous MerkleFunderDepository withdraw the funds to the new one.
contract MerkleFunderDepository is IMerkleFunderDepository {
    /// @notice Address of the MerkleFunder that deployed this contract
    address public immutable override merkleFunder;

    /// @notice Owner address
    address public immutable override owner;

    /// @notice Merkle tree root
    bytes32 public immutable override root;

    /// @dev Argument validation is done in MerkleFunder to reduce the
    /// bytecode of this contract
    /// @param _owner Owner address
    /// @param _root Merkle tree root
    constructor(address _owner, bytes32 _root) {
        merkleFunder = msg.sender;
        owner = _owner;
        root = _root;
    }

    /// @dev Funds transferred to this contract can be transferred by anyone
    /// within the limitations of the respective Merkle tree
    receive() external payable {}

    /// @notice Called by the MerkleFunder that has deployed this contract to
    /// transfer its funds within the limitations of the respective Merkle tree
    /// or to allow the owner to withdraw funds
    /// @dev Argument validation is done in MerkleFunder to reduce the bytecode
    /// of this contract.
    /// This function is omitted in the interface because it is intended to
    /// only be called by MerkleFunder.
    /// @param recipient Recipient address
    /// @param amount Amount
    function transfer(address recipient, uint256 amount) external {
        if (msg.sender != merkleFunder) revert SenderNotMerkleFunder();
        // MerkleFunder checks for balance so MerkleFunderDepository does not
        // need to
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert TransferUnsuccessful();
        // MerkleFunder emits the event so MerkleFunderDepository does not need
        // to
    }
}