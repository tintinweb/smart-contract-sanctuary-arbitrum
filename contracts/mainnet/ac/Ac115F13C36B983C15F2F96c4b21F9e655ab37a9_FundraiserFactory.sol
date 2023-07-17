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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FundraiserFactory.sol";
import "./Vesting.sol";
import "./VestingCliff.sol";

contract Fundraiser is Pausable, Ownable {
    using SafeMath for uint256;
    struct TokenConfig {
        address depositToken1;
        address depositToken2;
        address factory;
    }

    struct AllocationConfig {
        uint256 nftTicketAllocation;
        uint256 baseAllocationPerWallet;
        uint256 maxTotalAllocation;
        uint256 rate;
    }

    struct TimeConfig {
        uint256 nftStartTime;
        uint256 openStartTime;
        uint256 endTime;
    }

    TokenConfig public tokenConfig;
    AllocationConfig public allocationConfig;
    TimeConfig public timeConfig;
    address public nftToken;
    bytes32 internal merkleRoot;
    uint256 public whitelistedAllocation;
    uint256 public constant ALLOCATION_DIVIDER = 10000;


    mapping(address => uint256) public depositedAmount;
    uint256 public totalDeposited;
    mapping(uint256 => bool) public usedNftId;
    address public vestingAddress;

    mapping(address => bool) public whitelistUser;

    event Deposit(address indexed user, uint256 amount);
    event DepositWithNft(address indexed user, uint256 amount, uint256[] nftIds);
    event DepositWithWhitelist(address indexed user, uint256 amount);
    event DepositWithNftAndWhitelist(address indexed user, uint256 amount, uint256[] nftIds);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event VestingDeployed(address vestingAddress);
    event RegisterWhitelist(bytes32 merkleRoot, uint256 whitelistedAllocation);
    event WithdrawToken(address user, uint256 amount);
    event WithdrawEth(address user, uint256 amount);

    modifier canDeposit(uint256 _amount) {
        require(_amount > 0, "Fundraiser: deposit amount must be greater than 0");
        require(block.timestamp <= timeConfig.endTime, "Fundraising has already ended");
        require(totalDeposited.add(_amount) <= allocationConfig.maxTotalAllocation, "Max total allocation reached");
        _;
    }

    error TransferFailed();

    constructor(
        address _depositToken1,
        address _depositToken2,
        uint256 _baseAllocationPerWallet,
        uint256 _maxTotalAllocation,
        uint256 _nftTicketAllocation,
        uint256 _rate,
        uint256 _nftFundraiseStartTime,
        uint256 _openFundraiseStartTime,
        uint256 _fundraiseEndTime,
        address _owner,
        address _factory,
        address _nftToken
    ) {
        require(_nftFundraiseStartTime <= _openFundraiseStartTime, "NFT fundraise start time must be greater than open fundraise start time");
        require(_openFundraiseStartTime <= _fundraiseEndTime, "Open fundraise start time must not be greater than fundraise end time");
        require(_baseAllocationPerWallet <= _maxTotalAllocation, "Base allocation per wallet must not exceed maximum total allocation");

        tokenConfig.depositToken1 = _depositToken1;
        tokenConfig.depositToken2 = _depositToken2;
        allocationConfig.baseAllocationPerWallet = _baseAllocationPerWallet;
        allocationConfig.maxTotalAllocation = _maxTotalAllocation;
        allocationConfig.nftTicketAllocation = _nftTicketAllocation;
        allocationConfig.rate = _rate;
        timeConfig.nftStartTime = _nftFundraiseStartTime;
        timeConfig.openStartTime = _openFundraiseStartTime;
        timeConfig.endTime = _fundraiseEndTime;
        tokenConfig.factory = _factory;
        nftToken = _nftToken;
        _transferOwnership(_owner);
    }

    function deposit(uint256 _token1Amount, uint256 _token2Amount) external whenNotPaused canDeposit(_token1Amount + _token2Amount) {
        require(block.timestamp >= timeConfig.openStartTime, "Fundraising has not started yet");
        uint256 userNewDeposit = _token1Amount + _token2Amount;
        require(depositedAmount[msg.sender] + userNewDeposit <= allocationConfig.baseAllocationPerWallet, "Max allocation per wallet reached");

        chargeUser(_token1Amount, _token2Amount);

        depositedAmount[msg.sender] = depositedAmount[msg.sender].add(userNewDeposit);
        totalDeposited = totalDeposited.add(userNewDeposit);

        emit Deposit(msg.sender, _token1Amount + _token2Amount);
    }

    function depositWithNft(uint256 _token1Amount, uint256 _token2Amount, uint256[] memory nftIds) external whenNotPaused canDeposit(_token1Amount + _token2Amount) {
        require(block.timestamp >= timeConfig.nftStartTime, "Fundraising has not started yet");
        require(block.timestamp < timeConfig.openStartTime, "Fundraising in open phase");
        require(nftIds.length <= 3, "Max nftIds is 3");
        require(nftIds.length >= 1, "Min nftIds is 1");
        require(areElementsUnique(nftIds), "NFT identifiers must be unique!");
        uint256 userDeposit = _token1Amount + _token2Amount;

        useAllocationWithNfts(nftIds, userDeposit);
        chargeUser(_token1Amount, _token2Amount);

        depositedAmount[msg.sender] = depositedAmount[msg.sender].add(userDeposit);
        totalDeposited = totalDeposited.add(userDeposit);

        emit DepositWithNft(msg.sender, userDeposit, nftIds);
    }

    function depositWithWhitelist(uint256 _token1Amount, uint256 _token2Amount, bytes32[] memory proof_) external whenNotPaused canDeposit(_token1Amount + _token2Amount) {
        require(block.timestamp >= timeConfig.nftStartTime, "Fundraising has not started yet");
        require(block.timestamp < timeConfig.openStartTime, "Fundraising in open phase");
        require(MerkleProof.verify(proof_, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "User is not whitelisted.");
        whitelistUser[msg.sender] = true;

        uint256 userDeposit = depositedAmount[msg.sender];
        uint256 userNewDeposit = _token1Amount + _token2Amount;

        require(userNewDeposit.add(userDeposit) <= whitelistedAllocation, "Whitelist max allocation overflow");
        chargeUser(_token1Amount, _token2Amount);

        depositedAmount[msg.sender] = depositedAmount[msg.sender].add(userNewDeposit);
        totalDeposited = totalDeposited.add(userNewDeposit);

        emit DepositWithWhitelist(msg.sender, userNewDeposit);
    }

    function depositWithWhitelistAndNft(uint256 _token1Amount, uint256 _token2Amount, uint256[] memory nftIds, bytes32[] memory proof_) external whenNotPaused canDeposit(_token1Amount + _token2Amount) {
        require(block.timestamp >= timeConfig.nftStartTime, "Fundraising has not started yet");
        require(block.timestamp < timeConfig.openStartTime, "Fundraising in open phase");
        require(nftIds.length <= 3, "Max nftIds is 3");
        require(nftIds.length >= 1, "Min nftIds is 1");
        require(areElementsUnique(nftIds), "NFT identifiers must be unique!");

        require(MerkleProof.verify(proof_, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "User is not whitelisted.");
        whitelistUser[msg.sender] = true;

        uint256 userDeposit = depositedAmount[msg.sender];

        (uint256 validNftCount, uint256 invalidNftCount) = countValidAndInvalidNfts(msg.sender, nftIds);
        uint256 nftMaxAllocation = calculateMaxAllocation(userDeposit, validNftCount, invalidNftCount);

        uint256 userNewDeposit = _token1Amount + _token2Amount;
        require(userDeposit.add(userNewDeposit) <= nftMaxAllocation.add(whitelistedAllocation), "Max whitelisted and nft allocation overflow");

        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];

            if (IERC721(nftToken).ownerOf(nftId) == msg.sender && !usedNftId[nftId]) {
                usedNftId[nftId] = true;
            }
        }

        chargeUser(_token1Amount, _token2Amount);

        depositedAmount[msg.sender] = depositedAmount[msg.sender].add(userNewDeposit);
        totalDeposited = totalDeposited.add(userNewDeposit);

        emit DepositWithNftAndWhitelist(msg.sender, userNewDeposit, nftIds);
    }

    function setWhitelist(bytes32 _merkleRoot, uint256 _whitelistedAllocation) external onlyOwner {

        whitelistedAllocation = _whitelistedAllocation;
        merkleRoot = _merkleRoot;
        emit RegisterWhitelist(_merkleRoot, _whitelistedAllocation);
    }

    function withdraw() external whenNotPaused onlyOwner {
        require(block.timestamp > timeConfig.endTime, "Fundraise has not ended yet");

        uint256 balance1 = IERC20(tokenConfig.depositToken1).balanceOf(address(this));
        if (
            !IERC20(tokenConfig.depositToken1).transfer(owner(), balance1)
        ) {
            revert TransferFailed();
        }

        uint256 balance2 = IERC20(tokenConfig.depositToken2).balanceOf(address(this));
        if (
            !IERC20(tokenConfig.depositToken2).transfer(owner(), balance2)
        ) {
            revert TransferFailed();
        }


        FundraiserFactory(tokenConfig.factory).endFundraiser(address(this));

        emit Withdraw(owner(), balance1 + balance2);
    }

    function startVesting(uint256 _vestingStart, uint256 _vestingEnd, address _tokenAddress, uint256 _tokenAmount, uint256 _ethFee) external whenNotPaused onlyOwner {

        require(vestingAddress == address(0), "Vesting already deployed");
        require(_vestingStart > timeConfig.endTime, "Vesting has to start after fundraise end time");

        Vesting vesting = new Vesting(
            address(this),
            _vestingStart,
            _vestingEnd,
            _tokenAddress,
            _ethFee,
            owner()
        );

        vestingAddress = address(vesting);

        if (
            !IERC20(_tokenAddress).transferFrom(msg.sender, vestingAddress, _tokenAmount)
        ) {
            revert TransferFailed();
        }

        emit VestingDeployed(vestingAddress);
    }

    function startVestingCliff(
        uint256 _vestingStart,
        uint256 _vestingEnd,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint256 _tgeDate,
        uint256 _tgePercent,
        uint256 _ethFee
    ) external whenNotPaused onlyOwner {

        require(vestingAddress == address(0), "Vesting already deployed");
        require(_vestingStart > timeConfig.endTime, "Vesting has to start after fundraise end time");

        VestingCliff vesting = new VestingCliff(
            address(this),
            _vestingStart,
            _vestingEnd,
            _tokenAddress,
            _tgePercent,
            _tgeDate,
            _ethFee,
            owner()
        );

        vestingAddress = address(vesting);

        if (
            !IERC20(_tokenAddress).transferFrom(msg.sender, vestingAddress, _tokenAmount)
        ) {
            revert TransferFailed();
        }

        emit VestingDeployed(vestingAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function userAllocation(address userAddress) external view returns (uint256) {
        return depositedAmount[userAddress].mul(allocationConfig.rate).div(ALLOCATION_DIVIDER);
    }

    function getEndTime() external view returns (uint256) {
        return timeConfig.endTime;
    }

    function getMaxAllocation(address userAddress, uint256[] memory nftIds) external view returns (uint256) {
        uint256 userDeposit = depositedAmount[userAddress];
        (uint256 validNftCount, uint256 invalidNftCount) = countValidAndInvalidNfts(userAddress, nftIds);
        uint256 userMaxAllocation = calculateMaxAllocation(userDeposit, validNftCount, invalidNftCount);

        uint256 currentTotal = totalDeposited.add(userMaxAllocation);
        if (currentTotal > allocationConfig.maxTotalAllocation) {
            return allocationConfig.maxTotalAllocation.sub(totalDeposited);
        }

        return userMaxAllocation;
    }

    function useAllocationWithNfts(uint256[] memory nftIds, uint256 additionalDeposit) private {
        uint256 userDeposit = depositedAmount[msg.sender];
        (uint256 validNftCount, uint256 invalidNftCount) = countValidAndInvalidNfts(msg.sender, nftIds);
        uint256 maxAllocation = calculateMaxAllocation(userDeposit, validNftCount, invalidNftCount);

        require(userDeposit.add(additionalDeposit) <= maxAllocation, "Max allocation overflow");

        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            address tempOwner = IERC721(nftToken).ownerOf(nftId);
            require(tempOwner == msg.sender, "You are not the nft owner");
            usedNftId[nftId] = true;
        }
    }

    function countValidAndInvalidNfts(address userAddress, uint256[] memory nftIds) private view returns (uint256 validNftCount, uint256 invalidNftCount) {

        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];

            if (IERC721(nftToken).ownerOf(nftId) == userAddress) {
                if (!usedNftId[nftId]) {
                    validNftCount++;
                } else {
                    invalidNftCount++;
                }
            }
        }
    }

    function calculateMaxAllocation(uint256 userDeposit, uint256 validNftCount, uint256 invalidNftCount) private view returns (uint256) {
        uint256 maxAllocation;
        uint256 allowedNfts;

        uint256 userAllo;
        if (whitelistUser[msg.sender]) {
            userAllo = whitelistedAllocation;
        }

        if (userDeposit <= userAllo) {
            maxAllocation = userAllo.add(validNftCount.mul(allocationConfig.nftTicketAllocation));
        } else {
            uint256 threshold1 = userAllo.add(allocationConfig.nftTicketAllocation);
            uint256 threshold2 = userAllo.add(allocationConfig.nftTicketAllocation.mul(2));

            if (userDeposit <= threshold1) {
                allowedNfts = invalidNftCount >= 1 ? 1 + validNftCount : validNftCount;
            } else if (userDeposit <= threshold2) {
                allowedNfts = invalidNftCount >= 2 ? 2 + validNftCount : invalidNftCount == 1 ? validNftCount + 1 : validNftCount;
            } else {
                allowedNfts = invalidNftCount >= 3 ? 3 : validNftCount + invalidNftCount;
            }
            maxAllocation = userAllo.add(allowedNfts.mul(allocationConfig.nftTicketAllocation));
        }

        return maxAllocation;
    }

    function checkUsed(uint256[] memory nftIds) external view returns (uint256[] memory) {
        uint256[] memory validNfts = new uint256[](nftIds.length);

        uint256 validCount = 0;
        for (uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            if (!usedNftId[nftId]) {
                validNfts[validCount] = nftId;
                validCount++;
            }
        }

        uint256[] memory result = new uint256[](validCount);
        for (uint256 i = 0; i < validCount; i++) {
            result[i] = validNfts[i];
        }

        return result;
    }

    function areElementsUnique(uint256[] memory nftIds) internal pure returns (bool) {
        if (nftIds.length > 1 && nftIds[0] == nftIds[1]) return false;
        if (nftIds.length > 2 && (nftIds[0] == nftIds[2] || nftIds[1] == nftIds[2])) return false;
        return true;
    }

    function chargeUser(uint256 _token1Amount, uint256 _token2Amount) internal {
        if (_token1Amount > 0) {
            if (!IERC20(tokenConfig.depositToken1).transferFrom(msg.sender, address(this), _token1Amount)) {
                revert TransferFailed();
            }
        }

        if (_token2Amount > 0) {
            if (!IERC20(tokenConfig.depositToken2).transferFrom(msg.sender, address(this), _token2Amount)) {
                revert TransferFailed();
            }
        }
    }

    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {

        if (
            !token.transfer(owner(), amount)
        ) {
            revert TransferFailed();
        }

        emit WithdrawToken(owner(), amount);
    }

    function withdrawEth(uint256 amount) external onlyOwner {

        (bool success,) = payable(owner()).call{value : amount}("");
        if (!success) {
            revert TransferFailed();
        }
        emit WithdrawEth(owner(), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Fundraiser.sol";
import "./IterableMapping.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FundraiserFactory is Ownable {
    using IterableMapping for IterableMapping.Map;

    enum FundraiserStatus {COMING_SOON, NFT_PHASE, OPEN, CLOSED, DISTRIBUTION}

    IterableMapping.Map private activeFundraisers;
    IterableMapping.Map private endedFundraisers;

    event FundraiserCreated(address indexed fundraiser);
    event FundraiserEnded(address indexed fundraiser);

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    function createFundraiser(
        address _buyToken1,
        address _buyToken2,
        uint256 _baseAllocationPerWallet,
        uint256 _maxTotalAllocation,
        uint256 _nftTicketAllocation,
        uint256 _rate,
        uint256 _nftFundraiseStartTime,
        uint256 _openFundraiseStartTime,
        uint256 _fundraiseEndTime,
        address _nftAddress
    ) external onlyOwner() {
        Fundraiser newFundraiser = new Fundraiser(
            _buyToken1,
            _buyToken2,
            _baseAllocationPerWallet,
            _maxTotalAllocation,
            _nftTicketAllocation,
            _rate,
            _nftFundraiseStartTime,
            _openFundraiseStartTime,
            _fundraiseEndTime,
            owner(),
            address(this),
            _nftAddress
        );
        activeFundraisers.set(address(newFundraiser), activeFundraisers.size());
        emit FundraiserCreated(address(newFundraiser));
    }

    function endFundraiser(address fundraiserAddress) external {
        require(activeFundraisers.inserted[fundraiserAddress], "Fundraiser not found");
        require(msg.sender == fundraiserAddress, "Only the fundraiser contract can call this function");

        uint256 endTime = Fundraiser(fundraiserAddress).getEndTime();
        require(block.timestamp > endTime, "Fundraiser has not ended yet");

        activeFundraisers.remove(fundraiserAddress);
        endedFundraisers.set(fundraiserAddress, endedFundraisers.size());
        emit FundraiserEnded(fundraiserAddress);
    }

    function getFundraiserStatus(address fundraiserAddress) external view returns (FundraiserStatus) {
        (
        uint256 nftStartTime,
        uint256 openStartTime,
        uint256 endTime
        ) = Fundraiser(fundraiserAddress).timeConfig();
        if (block.timestamp < nftStartTime) {
            return FundraiserStatus.COMING_SOON;
        } else if (block.timestamp <= openStartTime) {
            return FundraiserStatus.NFT_PHASE;
        } else if (block.timestamp <= endTime) {
            return FundraiserStatus.OPEN;
        } else {
            return FundraiserStatus.DISTRIBUTION;
        }
    }

    function getFundraisersCount() external view returns (uint256) {
        return activeFundraisers.size();
    }

    function getEndedFundraisersCount() external view returns (uint256) {
        return endedFundraisers.size();
    }

    function getFundraiserAtIndex(uint256 index) external view returns (address) {
        require(index < activeFundraisers.size(), "Index out of bounds");
        return activeFundraisers.getKeyAtIndex(index);
    }

    function getEndedFundraiserAtIndex(uint256 index) external view returns (address) {
        require(index < endedFundraisers.size(), "Index out of bounds");
        return endedFundraisers.getKeyAtIndex(index);
    }

    function getActiveFundraisersAtIndexes(uint256[] calldata indexes) external view returns (address[] memory) {
        require(indexes.length > 0, "Indexes array must not be empty");

        address[] memory activeFundraisersAddresses = new address[](indexes.length);

        for (uint256 i = 0; i < indexes.length; i++) {
            require(indexes[i] < activeFundraisers.size(), "Index out of bounds");
            activeFundraisersAddresses[i] = activeFundraisers.getKeyAtIndex(indexes[i]);
        }

        return activeFundraisersAddresses;
    }

    function getEndedFundraisersAtIndexes(uint256[] calldata indexes) external view returns (address[] memory) {
        require(indexes.length > 0, "Indexes array must not be empty");

        address[] memory endedFundraisersAddresses = new address[](indexes.length);

        for (uint256 i = 0; i < indexes.length; i++) {
            require(indexes[i] < endedFundraisers.size(), "Index out of bounds");
            endedFundraisersAddresses[i] = endedFundraisers.getKeyAtIndex(indexes[i]);
        }

        return endedFundraisersAddresses;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) external view returns (uint) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint index) external view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) external view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) external {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) external {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Fundraiser.sol";

contract Vesting {
    using SafeMath for uint256;

    struct Config {
        address fundingAddress;
        uint256 startTime;
        uint256 endTime;
        IERC20 token;
    }

    Config public config;
    uint256 private ethFee;
    address private feeAdmin;
    mapping(address => uint256) public tokensReleased;

    event TokensReleased(uint256 amount, address user);
    event Withdraw(address user, uint256 amount);
    event WithdrawEth(address user, uint256 amount);
    event UpdateFee(uint256 newFee);

    error TransferFailed();
    error WithdrawFailed();

    modifier onlyFeeAdmin(){
        require(msg.sender == feeAdmin);
        _;
    }

    constructor(
        address _fundingAddress,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress,
        uint256 _ethFee,
        address _feeAdmin
    ) {
        require(_endTime > _startTime, "End time must be greater than start time");
        require(_tokenAddress != address(0), "Token address cannot be zero address");

        config.fundingAddress = _fundingAddress;
        config.startTime = _startTime;
        config.endTime = _endTime;
        config.token = IERC20(_tokenAddress);
        ethFee = _ethFee;
        feeAdmin = _feeAdmin;
    }

    function release() external payable {
        uint256 unreleased = releasableAmount(msg.sender);
        require(unreleased > 0, "No tokens to release");
        require(msg.value >= ethFee, "Insufficient fee: the required fee must be covered");

        tokensReleased[msg.sender] = tokensReleased[msg.sender].add(unreleased);
        if (
            !config.token.transfer(msg.sender, unreleased)
        ) {
            revert TransferFailed();
        }

        uint256 dust = msg.value - ethFee;
        (bool sent,) = address(msg.sender).call{value : dust}("");
        require(sent, "Failed to return overpayment");

        emit TokensReleased(unreleased, msg.sender);
    }

    function releasableAmount(address userAddress) public view returns (uint256) {
        if (block.timestamp < config.startTime) {
            return 0;
        } else if (block.timestamp >= config.endTime) {
            uint256 totalTokens = Fundraiser(config.fundingAddress).userAllocation(userAddress);
            return totalTokens.sub(tokensReleased[userAddress]);
        } else {
            uint256 elapsedTime = block.timestamp.sub(config.startTime);
            uint256 totalVestingTime = config.endTime.sub(config.startTime);
            uint256 totalTokens = Fundraiser(config.fundingAddress).userAllocation(userAddress);
            uint256 vestedAmount = totalTokens.mul(elapsedTime).div(totalVestingTime);
            return vestedAmount.sub(tokensReleased[userAddress]);
        }
    }

    function withdrawToken(IERC20 token, uint256 amount) external onlyFeeAdmin {

        if (
            !token.transfer(feeAdmin, amount)
        ) {
            revert TransferFailed();
        }

        emit Withdraw(feeAdmin, amount);
    }

    function withdrawEth(uint256 amount) external onlyFeeAdmin {

        (bool success,) = payable(feeAdmin).call{value : amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
        emit WithdrawEth(feeAdmin, amount);
    }

    function updateEthFee(uint256 _newFee) external onlyFeeAdmin {

        ethFee = _newFee;
        emit UpdateFee(_newFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Fundraiser.sol";

contract VestingCliff {
    using SafeMath for uint256;
    uint256 public constant VESTING_DIVIDER = 10000;

    struct Config {
        address fundingAddress;
        uint256 startTime;
        uint256 endTime;
        uint256 tgePercent;
        uint256 tgeDate;
        IERC20 token;
    }

    Config public config;
    uint256 private ethFee;
    address private feeAdmin;
    mapping(address => uint256) public tokensReleased;

    event TokensReleased(uint256 amount, address user);
    event Withdraw(address user, uint256 amount);
    event WithdrawEth(address user, uint256 amount);
    event UpdateFee(uint256 newFee);

    error TransferFailed();
    error WithdrawFailed();

    modifier onlyFeeAdmin(){
        require(msg.sender == feeAdmin);
        _;
    }

    constructor(
        address _fundingAddress,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress,
        uint256 _tgePercent,
        uint256 _tgeDate,
        uint256 _ethFee,
        address _feeAdmin
    ) {
        require(_endTime > _startTime, "End time must be greater than start time");
        require(_tokenAddress != address(0), "Token address cannot be zero address");

        config.fundingAddress = _fundingAddress;
        config.startTime = _startTime;
        config.endTime = _endTime;
        config.token = IERC20(_tokenAddress);
        config.tgePercent = _tgePercent;
        config.tgeDate = _tgeDate;
        ethFee = _ethFee;
        feeAdmin = _feeAdmin;
    }

    function release() external payable {
        uint256 unreleased = releasableAmount(msg.sender);
        require(unreleased > 0, "No tokens to release");
        require(msg.value >= ethFee, "Insufficient fee: the required fee must be covered");

        tokensReleased[msg.sender] = tokensReleased[msg.sender].add(unreleased);
        if (
            !config.token.transfer(msg.sender, unreleased)
        ) {
            revert TransferFailed();
        }

        uint256 dust = msg.value - ethFee;
        (bool sent,) = address(msg.sender).call{value : dust}("");
        require(sent, "Failed to return overpayment");

        emit TokensReleased(unreleased, msg.sender);
    }

    function releasableAmount(address userAddress) public view returns (uint256) {
        if (block.timestamp < config.tgeDate) {
            return 0;
        }

        uint256 totalTokens = Fundraiser(config.fundingAddress).userAllocation(userAddress);

        if (block.timestamp > config.endTime) {
            return totalTokens.sub(tokensReleased[userAddress]);
        }

        uint256 totalTgeTokens = totalTokens.mul(config.tgePercent).div(VESTING_DIVIDER);

        if (block.timestamp < config.startTime) {
            return totalTgeTokens.sub(tokensReleased[userAddress]);
        }

        uint256 elapsedTime = block.timestamp.sub(config.startTime);
        uint256 totalVestingTime = config.endTime.sub(config.startTime);
        uint256 totalLinearTokens = totalTokens.sub(totalTgeTokens);
        uint256 vestedAmount = totalLinearTokens.mul(elapsedTime).div(totalVestingTime).add(totalTgeTokens);
        return vestedAmount.sub(tokensReleased[userAddress]);
    }

    function withdrawToken(IERC20 token, uint256 amount) external onlyFeeAdmin {

        if (
            !token.transfer(feeAdmin, amount)
        ) {
            revert TransferFailed();
        }

        emit Withdraw(feeAdmin, amount);
    }

    function withdrawEth(uint256 amount) external onlyFeeAdmin {

        (bool success,) = payable(feeAdmin).call{value : amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
        emit WithdrawEth(feeAdmin, amount);
    }

    function updateEthFee(uint256 _newFee) external onlyFeeAdmin {

        ethFee = _newFee;
        emit UpdateFee(_newFee);
    }
}