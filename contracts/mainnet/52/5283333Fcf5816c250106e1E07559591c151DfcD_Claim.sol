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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract AirdropVerifier {
    bytes32 immutable private airdropRoot_;

    constructor(bytes32 _root) {
        // Not able to change anymore after deploying
        airdropRoot_ = _root;
    }

    function _airdropVerify(
        bytes32[] memory proof,
        address addr
    )
        internal
        virtual
        view
    {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr))));
        require(MerkleProof.verify(proof, airdropRoot_, leaf), "Invalid proof");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Verifier.sol";
import "./AirdropVerifier.sol";

contract Claim is Ownable, ReentrancyGuard, Verifier, AirdropVerifier {
    struct Holder {
        address owner;
        uint256 heldNfts;
        uint256 transferredTokens;
        bool claimed;
    }

    struct AirdropClaim {
        address owner;
        uint256 timeStamp;
        uint256 transferredTokens;
    }

    mapping(address => Holder) internal _holders;
    mapping(address => AirdropClaim) internal _claimedAirdrop;
    address public immutable tokenToClaimAddress;
    IERC20 public immutable tokenToClaim;
    uint256 public totalTokensClaimed;
    uint256 public airdropTotalTokensClaimed;
    uint256 public constant AIRDROP_AMOUNT = 17_700_000_000_000; // Same value as Tier 4
    uint256 public startedTimeStamp = 0;
    uint256 public withdrawTimeStamp = 0;

    event ClaimedTokens(address indexed to, uint256 transferAmount, uint256 snapshottedNftHoldings);

    error ContractBalanceIsZero();
    error WithdrawingNotAllowedYet();
    error ClaimingAlreadyStarted();
    error ClaimingHasNotStartedYet();
    error AddressCannotBeZero();
    error Bytes32CannotBeEmpty();
    error AlreadyClaimed();
    error NotHoldingPreviousNfts();

    constructor(
        address claimTokenAddress_,
        bytes32 root_,
        bytes32 airdropRoot_
    )
        Verifier(root_)
        AirdropVerifier(airdropRoot_)
    {
        _checkZeroAddress(claimTokenAddress_);
        _checkBytesAreNotEmpty(root_);
        _checkBytesAreNotEmpty(airdropRoot_);

        tokenToClaimAddress = claimTokenAddress_;
        tokenToClaim = IERC20(claimTokenAddress_);
    }

    function _verify(
        bytes32[] memory proof,
        address addr,
        uint256 amount
    )
        internal
        override
        view
    {
        super._verify(proof, addr, amount);

        if(_hasCallerClaimed(addr))
            revert AlreadyClaimed();
    }

    function _airdropVerify(
        bytes32[] memory proof,
        address addr
    )
        internal
        override
        view
    {
        super._airdropVerify(proof, addr);

        if(_claimedAirdrop[addr].owner != address(0))
            revert AlreadyClaimed();
    }

    function claimAirdrop(bytes32[] memory proof) external nonReentrant() {
        _hasClaimingStarted();
        address caller = msg.sender;

        // Verify the caller that he is able to claim with the amount of previous nft tokens
        _airdropVerify(proof, caller);

        uint256 transferAmount = AIRDROP_AMOUNT;

        // Set claimed to true
        _claimedAirdrop[caller] = AirdropClaim({
            owner: caller,
            transferredTokens: transferAmount,
            timeStamp: block.timestamp
        });

        // Transfer tokens
        require(tokenToClaim.transfer(caller, transferAmount));

        // Add tokens to claim to the totalTokensClaimed variable
        airdropTotalTokensClaimed += transferAmount;

        emit ClaimedTokens(caller, transferAmount, 0);
    }

    function claim(bytes32[] memory proof, uint256 amount) external nonReentrant() {
        _hasClaimingStarted();
        address caller = msg.sender;

        // Verify the caller that he is able to claim with the amount of previous nft tokens
        _verify(proof, caller, amount);

        uint256 transferAmount = _getTierAmount(amount);

        // Set claimed to true
        _holders[caller] = Holder({
            owner: caller,
            heldNfts: amount,
            transferredTokens: transferAmount,
            claimed: true
        });

        // Transfer tokens
        require(tokenToClaim.transfer(caller, transferAmount));

        // Add tokens to claim to the totalTokensClaimed variable
        totalTokensClaimed += transferAmount;

        emit ClaimedTokens(caller, transferAmount, amount);
    }

    // Can start only once
    function startClaiming() external onlyOwner() {
        if(startedTimeStamp != 0)
            revert ClaimingAlreadyStarted();

        uint256 timeStamp = block.timestamp;
        startedTimeStamp = timeStamp;
        withdrawTimeStamp = timeStamp + 30 days;
    }

    function withdrawRemainingTokensAfterClaimTime(address to) external onlyOwner() {
        _isOwnerAbleToWithdraw();

        uint256 contractTokenBalance = _isContractBalanceForClaimingTokensZero();
        tokenToClaim.transfer(to, contractTokenBalance);
    }

    function _hasCallerClaimed(address claimer_) internal view returns(bool) {
        return _holders[claimer_].claimed;
    }

    function _checkBytesAreNotEmpty(bytes32 bytes_) internal pure {
        if(bytes_ == bytes32(0))
            revert Bytes32CannotBeEmpty();
    }

    function _checkZeroAddress(address addressToCheck) internal pure {
        if(addressToCheck == address(0))
            revert AddressCannotBeZero();
    }
    function _isContractBalanceForClaimingTokensZero() internal view returns(uint256 contractTokenBalance) {
        contractTokenBalance = tokenToClaim.balanceOf(address(this));

        if(contractTokenBalance == 0)
            revert ContractBalanceIsZero();
    }
    function _isOwnerAbleToWithdraw() internal view {
        if(block.timestamp < withdrawTimeStamp)
            revert WithdrawingNotAllowedYet();
    }

    function _getTierAmount(uint256 heldNfts) internal pure returns(uint256 transferAmount) {
        if(heldNfts == 0)
            revert NotHoldingPreviousNfts();
        // Tier 1
        if(1 <= heldNfts && heldNfts <= 2)
            transferAmount = 840_750_000_000;
        // Tier 2
        else if(3 <= heldNfts && heldNfts <= 4)
            transferAmount = 3_375_000_000_000;
        // Tier 3
        else if(5 <= heldNfts && heldNfts <= 9)
            transferAmount = 7_750_000_000_000;
        // Tier 4
        else if(heldNfts >= 10)
            transferAmount = 17_700_000_000_000;
    }

    function _hasClaimingStarted() internal view {
        if(startedTimeStamp == 0)
            revert ClaimingHasNotStartedYet();
    }

    function getHolder(address owner_)
        public
        view
        returns(
            address ownerAddress,
            uint256 heldNfts,
            uint256 transferredTokens,
            bool claimed
        )
    {
        Holder memory holder = _holders[owner_];

        ownerAddress = holder.owner;
        heldNfts = holder.heldNfts;
        transferredTokens = holder.transferredTokens;
        claimed = holder.claimed;
    }

    function getAirdropHolder(address owner_)
        public
        view
        returns(
            address ownerAddress,
            uint256 timeStamp,
            uint256 transferredTokens
        )
    {
        AirdropClaim memory holder = _claimedAirdrop[owner_];

        ownerAddress = holder.owner;
        timeStamp = holder.timeStamp;
        transferredTokens = holder.transferredTokens;
    }

    function getTotalTokensClaimed()
        external
        view
        returns(uint256 totalClaimedTokens)
    {
        totalClaimedTokens = totalTokensClaimed + airdropTotalTokensClaimed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Verifier {
    bytes32 immutable private root_;

    constructor(bytes32 _root) {
        // Not able to change anymore after deploying
        root_ = _root;
    }

    function _verify(
        bytes32[] memory proof,
        address addr,
        uint256 amount
    )
        internal
        virtual
        view
    {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, amount))));
        require(MerkleProof.verify(proof, root_, leaf), "Invalid proof");
    }
}