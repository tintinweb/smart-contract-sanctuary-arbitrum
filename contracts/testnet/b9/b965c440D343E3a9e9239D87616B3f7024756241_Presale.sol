// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the erc token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    function processProof(
        bytes32[] memory proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
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
    function processProofCalldata(
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
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
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

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
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
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
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

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
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
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

    function _efficientHash(
        bytes32 a,
        bytes32 b
    ) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";
import "./MerkleProof.sol";

contract Presale {

    // Verification
    bytes32 public originalistMerkleRoot;
    bytes32 public waitlistMerkleRoot;

    // Address Configs
    address public owner;
    address public omo;
    address public stable;

    // Sale Details
    uint public saleAmount; // 50,000,000
    uint public privateSaleRatio; // 700 / 1000
    uint public price; //0.007 usdc per token
    uint public maxDeposit; //1000 usdc

    // Sale Progress
    uint public originalistSold;
    uint public waitlistSold;
    uint public publicSold;

    // Sale Stages
    bool public isOriginalistStart;
    bool public isWaitlistStart;
    bool public isPublicStart;
    bool public isClaimStart;

    mapping(address => uint) public alloc;
    mapping(address => uint) public deposit;

    constructor(
        address _omo,
        address _stable,
        uint _price,
        uint _saleAmount,
        uint _maxDeposit,
        uint _privateSaleRatio,
        bytes32 _originalistMerkleRoot,
        bytes32 _waitlistMerkleRoot
    ) {
        owner = msg.sender;
        omo = _omo;
        stable = _stable;
        price = _price;
        saleAmount = _saleAmount;
        maxDeposit = _maxDeposit;
        privateSaleRatio = _privateSaleRatio;
        originalistMerkleRoot = _originalistMerkleRoot;
        waitlistMerkleRoot = _waitlistMerkleRoot;
    }

    function depositOriginalist(
        uint _stableAmount,
        bytes32[] calldata _merkleProof
    ) public {
        require(_stableAmount > 0, "Amount cannot be zero");
        require(isOriginalistStart == true, "Originalist Sale is not available");
        require(
            deposit[msg.sender] + _stableAmount <= maxDeposit,
            "Max alloc reached"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, originalistMerkleRoot, leaf),
            "Invalid address"
        );

        uint tokenAmt = (_stableAmount * 1e18) / price;
        require(saleAmount * privateSaleRatio / 1000 >= tokenAmt + originalistSold, "Insufficient token balance");

        IERC20(stable).transferFrom(msg.sender, owner, _stableAmount);
        deposit[msg.sender] += _stableAmount;

        // Update Alloc
        alloc[msg.sender] += tokenAmt;

        originalistSold += tokenAmt;
    }

    function depositWaitlist(
        uint _stableAmount,
        bytes32[] calldata _merkleProof
    ) public {
        require(_stableAmount > 0, "Amount cannot be zero");
        require(isWaitlistStart == true, "Waitlist Sale is not available");
        require(
            deposit[msg.sender] + _stableAmount <= maxDeposit,
            "Max alloc reached"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, waitlistMerkleRoot, leaf),
            "Invalid address"
        );

        uint tokenAmt = (_stableAmount * 1e18) / price;
        uint tokenSold = originalistSold + waitlistSold;
        require(saleAmount * privateSaleRatio / 1000 >= tokenAmt + tokenSold , "Insufficient token balance");

        IERC20(stable).transferFrom(msg.sender, owner, _stableAmount);
        deposit[msg.sender] += _stableAmount;

        // Update Alloc
        alloc[msg.sender] += tokenAmt;

        waitlistSold += tokenAmt;
    }

    function depositPublic(uint _stableAmount) public {
        require(_stableAmount > 0, "Amount cannot be zero");
        require(isPublicStart == true, "Public Sale is not available");
        require(
            deposit[msg.sender] + _stableAmount <= maxDeposit,
            "Max alloc reached"
        );

        uint tokenAmt = (_stableAmount * 1e18) / price;
        uint tokenSold = originalistSold + waitlistSold + publicSold;
        require(saleAmount >= tokenAmt + tokenSold, "Insufficient token balance");

        IERC20(stable).transferFrom(msg.sender, owner, _stableAmount);
        deposit[msg.sender] += _stableAmount;

        // Update Alloc
        alloc[msg.sender] += tokenAmt;

        publicSold += tokenAmt;
    }

    function claim() public {
        require(isClaimStart == true, "Claim not allowed");
        require(alloc[msg.sender] > 0, "Nothing to claim");
        IERC20(omo).transfer(msg.sender, alloc[msg.sender]);
        alloc[msg.sender] = 0;
    }

    function startOriginalistSale() public onlyOwner {
        isOriginalistStart = true;
    }

    function startWaitlistSale() public onlyOwner {
        isOriginalistStart = false;
        isWaitlistStart = true;
    }

    function startPublicSale() public onlyOwner {
        isWaitlistStart = false;
        isPublicStart = true;
    }

    function endPublicSale() public onlyOwner {
        isPublicStart = false;
    }

    function startClaim() public onlyOwner {
        require(isPublicStart == false, "Presale is open");
        isClaimStart = true;
    }

    function recover() public onlyOwner {
        require(isClaimStart == true, "Claim not allowed");
        uint unsoldAmt = saleAmount - originalistSold - waitlistSold - publicSold;
        IERC20(omo).transfer(owner, unsoldAmt);
    }

    function setOwner(address _address) public onlyOwner {
        owner = _address;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
}