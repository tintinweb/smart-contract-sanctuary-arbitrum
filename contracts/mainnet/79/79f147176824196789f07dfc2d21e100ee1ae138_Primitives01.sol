// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

interface IBoolOracle {
  function getBool(bytes memory params) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

interface ICallExecutor {
  function proxyCall(address to, bytes memory data) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

interface IPriceCurve {
  function getOutput (
    uint totalInput,
    uint filledInput,
    uint input,
    bytes memory curveParams
  ) external pure returns (uint output);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

import "./IBoolOracle.sol";

interface ITokenStatusOracle is IBoolOracle {
  function verifyTokenStatus(
    address contractAddr,
    uint tokenId,
    bool isFlagged,
    uint lastTransferTime,
    uint timestamp,
    bytes memory signature
  ) external view; 
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

interface IUint256Oracle {
  function getUint256(bytes memory params) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

/// @title Bit replay protection library
/// @notice Handles storage and loads for replay protection bits
/// @dev Solution adapted from https://github.com/PISAresearch/metamask-comp/blob/77fa8295c168ee0b6bf801cbedab797d6f8cfd5d/src/contracts/BitFlipMetaTransaction/README.md
/// @dev This is a gas optimized technique that stores up to 256 replay protection bits per bytes32 slot
library Bit {
  /// @dev Revert when bit provided is not valid
  error InvalidBit();

  /// @dev Revert when bit provided is used
  error BitUsed();

  /// @dev Initial pointer for bitmap storage ptr computation
  /// @notice This is the uint256 representation of keccak("bmp")
  uint256 constant INITIAL_BMP_PTR = 
  48874093989078844336340380824760280705349075126087700760297816282162649029611;

  /// @dev Adds a bit to the uint256 bitmap at bitmapIndex
  /// @dev Value of bit cannot be zero and must represent a single bit
  /// @param bitmapIndex The index of the uint256 bitmap
  /// @param bit The value of the bit within the uint256 bitmap
  function useBit(uint256 bitmapIndex, uint256 bit) internal {
    if (!validBit(bit)) {
      revert InvalidBit();
    }
    bytes32 ptr = bitmapPtr(bitmapIndex);
    uint256 bitmap = loadUint(ptr);
    if (bitmap & bit != 0) {
      revert BitUsed();
    }
    uint256 updatedBitmap = bitmap | bit;
    assembly { sstore(ptr, updatedBitmap) }
  }

  /// @dev Check that a bit is valid
  /// @param bit The bit to check
  /// @return isValid True if bit is greater than zero and represents a single bit
  function validBit(uint256 bit) internal pure returns (bool isValid) {
    assembly {
      // equivalent to: isValid = (bit > 0 && bit & bit-1) == 0;
      isValid := and(
        iszero(iszero(bit)), 
        iszero(and(bit, sub(bit, 1)))
      )
    } 
  }

  /// @dev Get a bitmap storage pointer
  /// @return The bytes32 pointer to the storage location of the uint256 bitmap at bitmapIndex
  function bitmapPtr (uint256 bitmapIndex) internal pure returns (bytes32) {
    return bytes32(INITIAL_BMP_PTR + bitmapIndex);
  }

  /// @dev Returns the uint256 value at storage location ptr
  /// @param ptr The storage location pointer
  /// @return val The uint256 value at storage location ptr
  function loadUint(bytes32 ptr) internal view returns (uint256 val) {
    assembly { val := sload(ptr) }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;


/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    Primitives01.sol :: 0x79f147176824196789f07dfc2d21e100ee1ae138
 *    etherscan.io verified 2023-11-30
 */ 
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../StrategyBase.sol";
import "../Interfaces/ICallExecutor.sol";
import "../Interfaces/IUint256Oracle.sol";
import "../Interfaces/IPriceCurve.sol";
import "../Libraries/Bit.sol";
import "../TokenHelper/TokenHelper.sol";
import "../Utils/SwapIO.sol";

error NftIdAlreadyOwned();
error NotEnoughNftReceived();
error NotEnoughTokenReceived(uint amountReceived);
error MerkleProofAndAmountMismatch();
error BlockMined();
error BlockNotMined();
error OracleUint256ReadZero();
error Uint256LowerBoundNotMet(uint256 oraclePrice);
error Uint256UpperBoundNotMet(uint256 oraclePrice);
error InvalidTokenInIds();
error InvalidTokenOutIds();
error BitUsed();
error BitNotUsed();
error SwapIdsAreEqual();
error InvalidSwapIdsLength();
error MaxBlockIntervals();
error BlockIntervalTooShort();

struct UnsignedTransferData {
  address recipient;
  IdsProof idsProof;
}

struct UnsignedMarketSwapData {
  address recipient;
  IdsProof tokenInIdsProof;
  IdsProof tokenOutIdsProof;
  Call fillCall;
}

struct UnsignedLimitSwapData {
  address recipient;
  uint amount;
  IdsProof tokenInIdsProof;
  IdsProof tokenOutIdsProof;
  Call fillCall;
}

struct UnsignedStakeProofData {
  bytes stakerSignature;
}

contract Primitives01 is TokenHelper, StrategyBase, SwapIO {
  using Math for uint256;
  using SignedMath for int256;

  ICallExecutor constant CALL_EXECUTOR_V2 = ICallExecutor(0x6FE756B9C61CF7e9f11D96740B096e51B64eBf13);

  // require bitmapIndex/bit not to be used
  function requireBitNotUsed (uint bitmapIndex, uint bit) public {
    uint256 bitmap = Bit.loadUint(Bit.bitmapPtr(bitmapIndex));
    if (bitmap & bit != 0) {
      revert BitUsed();
    }
  }

  // require bitmapIndex/bit to be used
  function requireBitUsed (uint bitmapIndex, uint bit) public {
    uint256 bitmap = Bit.loadUint(Bit.bitmapPtr(bitmapIndex));
    if (bitmap & bit == 0) {
      revert BitNotUsed();
    }
  }

  // set bitmapIndex/bit to used. Requires bit not to be used
  function useBit (uint bitmapIndex, uint bit) public {
    Bit.useBit(bitmapIndex, bit);
  }

  // require block <= current block
  function requireBlockMined (uint blockNumber) public view {
    if (blockNumber > block.number) {
      revert BlockNotMined();
    }
  }

  function requireBlockNotMined (uint blockNumber) public view {
    if (blockNumber <= block.number) {
      revert BlockMined();
    }
  }

  /**
    * @dev Allow execution on a block interval
    * @param id A unique id for the block interval. This id is used to store the block interval state. Use a random id to avoid collisions.
    * @param initialStart The initial start block number. Setting this to 0 will allow the first execution to occur immediately.
    * @param intervalMinSize The minimum size of the block interval. This is a minimum because the actual interval can be longer if execution is delayed.
    * @param maxIntervals The maximum number of intervals that can be executed. Set this to 0 for unlimited executions.
    */
  function blockInterval (uint64 id, uint128 initialStart, uint128 intervalMinSize, uint16 maxIntervals) public {
    (uint128 start, uint16 counter) = getBlockIntervalState(id);
    if (start == 0) {
      start = initialStart;
    }

    if (maxIntervals > 0 && counter >= maxIntervals) {
      revert MaxBlockIntervals();
    }

    uint128 blockNum = uint128(block.number);

    if (blockNum < start + intervalMinSize) {
      revert BlockIntervalTooShort();
    }

    _setBlockIntervalState(id, blockNum, counter + 1);
  }

  // Require a lower bound uint256 returned from an oracle. Revert if oracle returns 0.
  function requireUint256LowerBound (IUint256Oracle uint256Oracle, bytes memory params, uint lowerBound) public view {
    uint256 oracleUint256 = uint256Oracle.getUint256(params);
    if (oracleUint256 == 0) {
      revert OracleUint256ReadZero();
    }
    if(oracleUint256 > lowerBound) {
      revert Uint256LowerBoundNotMet(oracleUint256);
    }
  }

  // Require an upper bound uint256 returned from an oracle
  function requireUint256UpperBound (IUint256Oracle uint256Oracle, bytes memory params, uint upperBound) public {
    uint256 oracleUint256 = uint256Oracle.getUint256(params);
    if(oracleUint256 < upperBound) {
      revert Uint256UpperBoundNotMet(oracleUint256);
    }
  }

  function transfer (
    Token memory token,
    address owner,
    address recipient,
    uint amount,
    UnsignedTransferData memory data
  ) public {
    revert("NOT IMPLEMENTED");
  }

  // given an exact tokenIn amount, fill a tokenIn -> tokenOut swap at market price, as determined by priceOracle
  function marketSwapExactInput (
    IUint256Oracle priceOracle,
    bytes memory priceOracleParams,
    address owner,
    Token memory tokenIn,
    Token memory tokenOut,
    uint tokenInAmount,
    uint24 feePercent,
    uint feeMinTokenOut,
    UnsignedMarketSwapData memory data
  ) public {
    uint tokenOutAmount = getSwapAmount(priceOracle, priceOracleParams, tokenInAmount);
    tokenOutAmount = tokenOutAmount - calcFee(tokenOutAmount, feePercent, feeMinTokenOut);
    _fillSwap(
      tokenIn,
      tokenOut,
      owner,
      data.recipient,
      tokenInAmount,
      tokenOutAmount,
      data.tokenInIdsProof,
      data.tokenOutIdsProof,
      data.fillCall
    );
  }

  // given an exact tokenOut amount, fill a tokenIn -> tokenOut swap at market price, as determined by priceOracle
  function marketSwapExactOutput (
    IUint256Oracle priceOracle,
    bytes memory priceOracleParams,
    address owner,
    Token memory tokenIn,
    Token memory tokenOut,
    uint tokenOutAmount,
    uint24 feePercent,
    uint feeMinTokenIn,
    UnsignedMarketSwapData memory data
  ) public {
    uint tokenInAmount = getSwapAmount(priceOracle, priceOracleParams, tokenOutAmount);
    tokenInAmount = tokenInAmount + calcFee(tokenInAmount, feePercent, feeMinTokenIn);
    _fillSwap(
      tokenIn,
      tokenOut,
      owner,
      data.recipient,
      tokenInAmount,
      tokenOutAmount,
      data.tokenInIdsProof,
      data.tokenOutIdsProof,
      data.fillCall
    );
  }

  // fill all or part of a swap for tokenIn -> tokenOut, with exact tokenInAmount.
  // Price curve calculates output based on input
  function limitSwapExactInput (
    address owner,
    Token memory tokenIn,
    Token memory tokenOut,
    uint tokenInAmount,
    IPriceCurve priceCurve,
    bytes memory priceCurveParams,
    FillStateParams memory fillStateParams,
    UnsignedLimitSwapData memory data
  ) public {
    int fillStateX96 = getFillStateX96(fillStateParams.id);
    uint filledInput = getFilledAmount(fillStateParams, fillStateX96, tokenInAmount);

    uint tokenOutAmountRequired = limitSwapExactInput_getOutput(
      data.amount,
      filledInput,
      tokenInAmount,
      priceCurve,
      priceCurveParams
    );

    _setFilledAmount(fillStateParams, filledInput + data.amount, tokenInAmount);

    _fillSwap(
      tokenIn,
      tokenOut,
      owner,
      data.recipient,
      data.amount,
      tokenOutAmountRequired,
      data.tokenInIdsProof,
      data.tokenOutIdsProof,
      data.fillCall
    );
  }

  // fill all or part of a swap for tokenIn -> tokenOut, with exact tokenOutAmount.
  // Price curve calculates input based on output
  function limitSwapExactOutput (
    address owner,
    Token memory tokenIn,
    Token memory tokenOut,
    uint tokenOutAmount,
    IPriceCurve priceCurve,
    bytes memory priceCurveParams,
    FillStateParams memory fillStateParams,
    UnsignedLimitSwapData memory data
  ) public {
    int fillStateX96 = getFillStateX96(fillStateParams.id);
    uint filledOutput = getFilledAmount(fillStateParams, fillStateX96, tokenOutAmount);

    uint tokenInAmountRequired = limitSwapExactOutput_getInput(
      data.amount,
      filledOutput,
      tokenOutAmount,
      priceCurve,
      priceCurveParams
    );

    _setFilledAmount(fillStateParams, filledOutput + data.amount, tokenOutAmount);

    _fillSwap(
      tokenIn,
      tokenOut,
      owner,
      data.recipient,
      tokenInAmountRequired,
      data.amount,
      data.tokenInIdsProof,
      data.tokenOutIdsProof,
      data.fillCall
    );
  }
  

  function _checkUnsignedTransferData (Token memory token, uint amount, UnsignedTransferData memory unsignedData) private pure {
    if (token.idsMerkleRoot != bytes32(0) && unsignedData.idsProof.ids.length != amount) {
      revert MerkleProofAndAmountMismatch();
    }
  }

  function _fillSwap (
    Token memory tokenIn,
    Token memory tokenOut,
    address owner,
    address recipient,
    uint tokenInAmount,
    uint tokenOutAmount,
    IdsProof memory tokenInIdsProof,
    IdsProof memory tokenOutIdsProof,
    Call memory fillCall
  ) internal {
    verifyTokenIds(tokenIn, tokenInIdsProof);
    verifyTokenIds(tokenOut, tokenOutIdsProof);

    transferFrom(tokenIn.addr, tokenIn.standard, owner, recipient, tokenInAmount, tokenInIdsProof.ids);

    uint initialTokenOutBalance;
    {
      (uint _initialTokenOutBalance, uint initialOwnedIdCount,) = tokenOwnership(owner, tokenOut.standard, tokenOut.addr, tokenOutIdsProof.ids);
      initialTokenOutBalance = _initialTokenOutBalance;
      if (tokenOut.standard == TokenStandard.ERC721 && initialOwnedIdCount != 0) {
        revert NftIdAlreadyOwned();
      }
    }

    CALL_EXECUTOR_V2.proxyCall(fillCall.targetContract, fillCall.data);

    (uint finalTokenOutBalance,,) = tokenOwnership(owner, tokenOut.standard, tokenOut.addr, tokenOutIdsProof.ids);

    uint256 tokenOutAmountReceived = finalTokenOutBalance - initialTokenOutBalance;
    if (tokenOutAmountReceived < tokenOutAmount) {
      revert NotEnoughTokenReceived(tokenOutAmountReceived);
    }
  }

  function getSwapAmount (IUint256Oracle priceOracle, bytes memory priceOracleParams, uint token0Amount) public view returns (uint token1Amount) {
    uint priceX96 = priceOracle.getUint256(priceOracleParams);
    token1Amount = calcSwapAmount(priceX96, token0Amount);
  }

  function getFillStateX96 (uint64 fillStateId) public view returns (int fillState) {
    bytes32 position = keccak256(abi.encode(fillStateId, "fillState"));
    assembly { fillState := sload(position) } 
  }

  function getBlockIntervalState (uint64 id) public view returns (uint128 start, uint16 counter) {
    bytes32 position = keccak256(abi.encode(id, "blockInterval"));
    bytes32 slot;
    assembly { slot := sload(position) }
    start = uint128(uint256(slot));
    counter = uint16(uint256(slot >> 128)); 
  }

  function _setFilledAmount (FillStateParams memory fillStateParams, uint filledAmount, uint totalAmount) internal {
    _setFilledPercentX96(fillStateParams, filledAmount.mulDiv(Q96, totalAmount) + 1);
  }

  function _setFilledPercentX96 (FillStateParams memory fillStateParams, uint filledPercentX96) internal {
    int8 i = fillStateParams.sign ? int8(1) : -1;
    int j = fillStateParams.sign ? int(0) : int(Q96);
    int8 k = fillStateParams.sign ? -1 : int8(1);
    _setFillState(
      fillStateParams.id,
      (i * int128(fillStateParams.startX96) + j - int(filledPercentX96)) * k
    );
  }

  function _setFillState (uint64 fillStateId, int fillState) internal {
    bytes32 position = keccak256(abi.encode(fillStateId, "fillState"));
    assembly { sstore(position, fillState) } 
  }

  function _sign (int n) internal pure returns (int8 sign) {
    return n >= 0 ? int8(1) : -1;
  }

  function _setBlockIntervalState (uint64 id, uint128 start, uint16 counter) internal {
    bytes32 position = keccak256(abi.encode(id, "blockInterval"));
    bytes32 slot = bytes32(uint256(start)) | (bytes32(uint256(counter)) << 128);
    assembly { sstore(position, slot) }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

struct Call {
  address targetContract;
  bytes data;
}

abstract contract StrategyBase { }

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '../Interfaces/ITokenStatusOracle.sol';

enum TokenStandard { ERC20, ERC721, ERC1155, ETH }

struct Token {
  TokenStandard standard;
  address addr;
  bytes32 idsMerkleRoot;
  uint id;
  bool disallowFlagged;
}

struct IdsProof {
  uint[] ids;
  bytes32[] merkleProof_hashes;
  bool[] merkleProof_flags;
  uint[] statusProof_lastTransferTimes;
  uint[] statusProof_timestamps;
  bytes[] statusProof_signatures;
}

error UnsupportedTokenStandard();
error IdNotAllowed();
error AtLeastOneIdRequired();
error MerkleProofsRequired();
error ERC1155IdNotProvided();
error OwnerHasNft();
error InvalidIds();
error IdMismatch();
error IdsLengthZero();
error DuplicateIds();
error InvalidMerkleProof();

contract TokenHelper {

  ITokenStatusOracle private constant TOKEN_STATUS_ORACLE = ITokenStatusOracle(0x3403bbfefe9cc0DDAA801D4d89F74FB838148E2E);

  function transferFrom (address tokenAddress, TokenStandard tokenStandard, address from, address to, uint amount, uint[] memory ids) internal {
    if (tokenStandard == TokenStandard.ERC20) {
      IERC20(tokenAddress).transferFrom(from, to, amount);
      return;
    }
    
    if (tokenStandard == TokenStandard.ERC721) {
      if (ids.length == 0) {
        revert IdsLengthZero();
      }
      for (uint8 i=0; i < ids.length; i++) {
        IERC721(tokenAddress).transferFrom(from, to, ids[i]);
      }
      return;
    } else if (tokenStandard == TokenStandard.ERC1155) {
      if (ids.length == 1) {
        IERC1155(tokenAddress).safeTransferFrom(from, to, ids[0], amount, '');
      } else if (ids.length > 1) {
        // for ERC1155 transfers with multiple id's provided, transfer 1 per id
        uint[] memory amounts = new uint[](ids.length);
        for (uint8 i=0; i < ids.length; i++) {
          amounts[i] = 1;
        }
        IERC1155(tokenAddress).safeBatchTransferFrom(from, to, ids, amounts, '');
      } else {
        revert IdsLengthZero();
      }
      return;
    }

    revert UnsupportedTokenStandard();
  }

  // returns
  //    balance: total balance for all ids
  //    ownedIdCount: total number of ids with balance > 0
  //    idBalances: array of individual id balances
  function tokenOwnership (
    address owner,
    TokenStandard tokenStandard,
    address tokenAddress,
    uint[] memory ids
  ) internal view returns (uint balance, uint ownedIdCount, uint[] memory idBalances) {
    if (tokenStandard == TokenStandard.ERC721 || tokenStandard == TokenStandard.ERC1155) {
      if (ids[0] == 0) {
        revert AtLeastOneIdRequired();
      }

      idBalances = new uint[](ids.length);

      for (uint8 i=0; i<ids.length; i++) {
        if (tokenStandard == TokenStandard.ERC721 && IERC721(tokenAddress).ownerOf(ids[i]) == owner) {
          ownedIdCount++;
          balance++;
          idBalances[i] = 1;
        } else if (tokenStandard == TokenStandard.ERC1155) {
          idBalances[i] = IERC1155(tokenAddress).balanceOf(owner, ids[i]);
          if (idBalances[i] > 0) {
            ownedIdCount++;
            balance += idBalances[i];
          }
        }
      }
    } else if (tokenStandard == TokenStandard.ERC20) {
      balance = IERC20(tokenAddress).balanceOf(owner);
    } else if (tokenStandard == TokenStandard.ETH) {
      balance = owner.balance;
    } else {
      revert UnsupportedTokenStandard();
    }
  }

  function verifyTokenIds (Token memory token, IdsProof memory idsProof) internal view {
    // if token specifies a single id, verify that one proof id is provided that matches
    if (token.id > 0 && !(idsProof.ids.length == 1 && idsProof.ids[0] == token.id)) {
      revert IdMismatch();
    }

    // if token specifies a merkle root for ids, verify merkle proofs provided for the ids
    if (
      token.idsMerkleRoot != bytes32(0) &&
      !verifyIdsMerkleProof(
        idsProof.ids,
        idsProof.merkleProof_hashes,
        idsProof.merkleProof_flags,
        token.idsMerkleRoot
      )
    ) {
      revert InvalidMerkleProof();
    }

    // if token is ERC721 or ERC1155 and does not specify a merkleRoot or Id, verify that no duplicate ids are provided
    if (
      (
        token.standard == TokenStandard.ERC721 ||
        token.standard == TokenStandard.ERC1155
      ) &&
      token.idsMerkleRoot == bytes32(0) &&
      token.id == 0 &&
      idsProof.ids.length > 1
    ) {
      for (uint8 i=0; i<idsProof.ids.length; i++) {
        for (uint8 j=i+1; j<idsProof.ids.length; j++) {
          if (idsProof.ids[i] == idsProof.ids[j]) {
            revert DuplicateIds();
          }
        }
      }
    }

    // if token has disallowFlagged=true, verify status proofs provided for the ids
    if (token.disallowFlagged) {
      verifyTokenIdsNotFlagged(
        token.addr,
        idsProof.ids,
        idsProof.statusProof_lastTransferTimes,
        idsProof.statusProof_timestamps,
        idsProof.statusProof_signatures
      );
    }
  }

  function verifyTokenIdsNotFlagged (
    address tokenAddress,
    uint[] memory ids,
    uint[] memory lastTransferTimes,
    uint[] memory timestamps,
    bytes[] memory signatures
  ) internal view {
    for(uint8 i = 0; i < ids.length; i++) {
      TOKEN_STATUS_ORACLE.verifyTokenStatus(tokenAddress, ids[i], false, lastTransferTimes[i], timestamps[i], signatures[i]);
    }
  }

  function verifyIdsMerkleProof (uint[] memory ids, bytes32[] memory proof, bool[] memory proofFlags, bytes32 root) internal pure returns (bool) {
    if (ids.length == 0) {
      return false;
    } else if (ids.length == 1) {
      return verifyId(proof, root, ids[0]);
    } else {
      return verifyIds(proof, proofFlags, root, ids);
    }
  }

  function verifyId (bytes32[] memory proof, bytes32 root, uint id) internal pure returns (bool) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(id))));
    return MerkleProof.verify(proof, root, leaf);
  }

  function verifyIds (bytes32[] memory proof, bool[] memory proofFlags, bytes32 root, uint[] memory ids) internal pure returns (bool) {
    bytes32[] memory leaves = new bytes32[](ids.length);
    for (uint8 i=0; i<ids.length; i++) {
      leaves[i] = keccak256(bytes.concat(keccak256(abi.encode(ids[i]))));
    }
    return MerkleProof.multiProofVerify(proof, proofFlags, root, leaves);
  }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../Interfaces/IPriceCurve.sol";

struct FillStateParams {
  uint64 id;
  uint128 startX96;
  bool sign;
}

contract SwapIO {
  using Math for uint;

  uint256 internal constant Q96 = 0x1000000000000000000000000;

  // given an input amount to a limitSwapExactInput function, return the output amount
  function limitSwapExactInput_getOutput (
    uint input,
    uint filledInput,
    uint tokenInAmount,
    IPriceCurve priceCurve,
    bytes memory priceCurveParams
  ) public pure returns (uint output) {
    if (filledInput >= tokenInAmount) {
      return 0;
    }
    output = priceCurve.getOutput(
      tokenInAmount,
      filledInput,
      input,
      priceCurveParams
    );
  }

  // given an output to a limitSwapExactInput function, return the input
  function limitSwapExactInput_getInput () public pure returns (uint input) {
    revert("NOT IMPLEMENTED");
  }

  // given an input to a limitSwapExactOutput function, return the output
  function limitSwapExactOutput_getOutput (
  ) public pure returns (uint output) {
    revert("NOT IMPLEMENTED");
  }

  // given an ouput to a limitSwapExactOutput function, return the input
  function limitSwapExactOutput_getInput (
    uint output,
    uint filledOutput,
    uint tokenOutAmount,
    IPriceCurve priceCurve,
    bytes memory priceCurveParams
  ) public pure returns (uint input) {
    if (filledOutput >= tokenOutAmount) {
      return 0;
    }

    // the getOutput() function is used to calculate the input amount,
    // because for `limitSwapExactOutput` the price curve is inverted
    input = priceCurve.getOutput(
      tokenOutAmount,
      filledOutput,
      output,
      priceCurveParams
    );
  }

  // given fillState and total, return the amount unfilled
  function getUnfilledAmount (FillStateParams memory fillStateParams, int fillStateX96, uint totalAmount) public pure returns (uint unfilledAmount) {
    unfilledAmount = totalAmount - getFilledAmount(fillStateParams, fillStateX96, totalAmount);
  }

  // given fillState and total, return the amount filled
  function getFilledAmount (FillStateParams memory fillStateParams, int fillStateX96, uint totalAmount) public pure returns (uint filledAmount) {
    filledAmount = getFilledPercentX96(fillStateParams, fillStateX96).mulDiv(totalAmount, Q96);
  }

  // given fillState, return the percent filled
  function getFilledPercentX96 (FillStateParams memory fillStateParams, int fillStateX96) public pure returns (uint filledPercentX96) {
    int8 i = fillStateParams.sign ? int8(1) : -1;
    int j = fillStateParams.sign ? int(0) : int(Q96);
    filledPercentX96 = uint((fillStateX96 + int128(fillStateParams.startX96)) * i + j);
  }

  // given exact input, price, and fee info, return output and fee amounts
  function marketSwapExactInput_getOutput (
    uint input,
    uint priceX96,
    uint24 feePercent,
    uint feeMin
  ) public pure returns (
    uint output,
    uint fee,
    uint outputWithFee
  ) {
    output = calcSwapAmount(priceX96, input);
    fee = calcFee(output, feePercent, feeMin);
    outputWithFee = output - fee;
  }

  // given exact output, price, and fee info, return input and fee amounts
  function marketSwapExactOutput_getInput (
    uint output,
    uint priceX96,
    uint24 feePercent,
    uint feeMin
  ) public pure returns (
    uint input,
    uint fee,
    uint inputWithFee
  ) {
    input = calcSwapAmount(priceX96, output);
    fee = calcFee(input, feePercent, feeMin);
    inputWithFee = input + fee;
  }

  // given price and amount0, return amount1
  function calcSwapAmount (uint priceX96, uint amount0) public pure returns (uint amount1) {
    amount1 = priceX96 * amount0 / Q96;
  }

  // given amount, fee %, and fee minimum, return the fee
  function calcFee (uint amount, uint24 feePercent, uint feeMin) public pure returns (uint fee) {
    fee = amount.mulDiv(feePercent, 10**6);
    if (fee < feeMin) {
      fee = feeMin;
    }
  }

}