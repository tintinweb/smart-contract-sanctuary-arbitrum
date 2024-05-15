// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.20;

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
 * the Merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates Merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     *@dev The multiproof provided is not valid.
     */
    error MerkleProofInvalidMultiproof();

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
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
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
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all Merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * CAUTION: Not all Merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * CAUTION: Not all Merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the Merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proofLen != totalHashes + 1) {
            revert MerkleProofInvalidMultiproof();
        }

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
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
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
     * CAUTION: Not all Merkle trees admit multiproofs. See {processMultiProof} for details.
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the Merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proofLen != totalHashes + 1) {
            revert MerkleProofInvalidMultiproof();
        }

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
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
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
     * @dev Sorts the pair (a, b) and hashes the result.
     */
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    /**
     * @dev Implementation of keccak256(abi.encode(a, b)) that doesn't allocate or expand memory.
     */
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
pragma solidity ^0.8.22;

interface IStakePool {
    enum PenaltyType {
        NoPenalty,
        FixedPenalty,
        TimerPenalty
    }
    enum RewardType {
        PercentRatio,
        FixedRatio,
        NoRatio,
        NoReward
    }
    enum StakeStatus {
        Alive,
        Cancelled
    }
    struct StakerModel{
        uint32 stakerIndex; 
        uint64 lastClaimTimes;
        uint256 withdrawnRewards;
    }
    struct StakeExtra{        
        address rewardToken;
        address stakeToken;
        address stakeOwner;
        uint64 lastDistributeTime;
        uint256 depositAmount;
        uint256 totalRewardsDistributed;   
        bool isWhitelist;
        bytes32 rootHash;     
    }
    struct StakeModel {        
        uint64 startDateTime;
        uint64 endDateTime;
        uint64 unstakeDateTime;
        uint64 claimDateTime;  
        uint64 rewardEndDateTime;
        bool transferrable;
        RewardType rewardType;
        PenaltyType penaltyType;
        StakeStatus status;
        uint256 rewardRatio;        
        uint256 minAmountToStake;
        uint256 penaltyRatio;        
        string extraData; 
    }  
    function getStakeModel() external view returns (StakeModel memory);
    function getStakeExtra() external view returns (StakeExtra memory);
    function getStakerModel(address) external view returns (StakerModel memory);
    function updateExtraData(string calldata) external;
    // function updatePeriod(uint256 _startDateTime, uint256 _endDateTime) external;
    function updateAmountLimit(uint256 _minAmountToStake) external;
    function updateTransferrable(bool _transferrable) external;
    // function updateClaimTime(bool _canClaimAnyTime, uint256 _claimDateTime) external;
    
    function stake(uint256 amount, bytes32[] calldata proof) external;
    function unstake(uint256 amount, bytes32[] calldata proof) external;
    function withdrawnRewardOf(address owner_)
        external
        view
        returns (uint256);
    function withdrawableRewardOf(address owner_)
        external
        view
        returns (uint256);
    function accumulativeRewardOf(address owner_)
        external
        view
        returns (uint256);
    function getAccount(address _account)
        external
        view
        returns (
            address account,
            int256 index,
            uint256 withdrawableRewards,
            uint256 totalRewards,
            uint256 lastClaimTime
        );
    function claim() external;
    function getNumberOfStakers() external view returns (uint256);
    function depositRewards(uint256 amount) external;
    function distributeRewards() external returns (uint256);
    function initialize(
        string memory name_,
        string memory symbol_,
        StakeModel memory _stakeModel,
        address _rewardToken,
        address _stakeToken,
        address _stakeOwner,
        uint256 hardCap
    ) external;
    function cancel() external;
    function forceCancel() external;

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../interfaces/IStakePool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library StakeValidate {
    function validateRewardType(
        IStakePool.StakeModel memory stakeModel,
        address rewardToken
    ) external pure {
        if(stakeModel.rewardType==IStakePool.RewardType.PercentRatio ||
            stakeModel.rewardType==IStakePool.RewardType.FixedRatio || stakeModel.rewardType==IStakePool.RewardType.NoRatio){
            require(rewardToken!=address(0), "invalide reward Token");         
            if(stakeModel.rewardType==IStakePool.RewardType.NoRatio){
                require(stakeModel.rewardRatio==0, "invalide reward ratio");
            }else{
                require(stakeModel.rewardEndDateTime>stakeModel.startDateTime, "reward end > stake start");
                require(stakeModel.rewardEndDateTime>=stakeModel.endDateTime, "reward end >= stake end");
                require(stakeModel.rewardEndDateTime>=stakeModel.unstakeDateTime, "reward end >= unstake");
                require(stakeModel.rewardEndDateTime>=stakeModel.claimDateTime, "reward end >= claim");
            }
        }else{
            require(stakeModel.rewardRatio==0, "invalide reward ratio");
        }
    }

    function validatePenalty(  
        IStakePool.StakeModel memory stakeModel
    ) external pure {
        if(stakeModel.penaltyType==IStakePool.PenaltyType.FixedPenalty || stakeModel.penaltyType==IStakePool.PenaltyType.TimerPenalty){
            require(stakeModel.startDateTime<stakeModel.unstakeDateTime, "no stake period");
            require(stakeModel.unstakeDateTime<=stakeModel.claimDateTime, "claim any time");
            require(stakeModel.penaltyRatio<=100 && stakeModel.penaltyRatio>0, "Penalty = 0~100%");
        }
    }
    function validatePeriod(
        uint256 _startDateTime,
        uint256 _endDateTime
    ) external view {
        require(_startDateTime >= block.timestamp, "start time >= now");
        require(_endDateTime > _startDateTime, "end time > start time");
    }

    function validateMinAmount(
        uint256 minAmountToStake,
        uint256 hardCap
    ) external pure {
        require(hardCap >= minAmountToStake, "hardCap >= minAmountToStake");
    }

    function validateStake(
        IStakePool.StakeModel storage stakeModel,
        IStakePool.StakeExtra storage stakeExtra,
        bytes32[] calldata proof
    ) external view {
        require(block.timestamp>=stakeModel.startDateTime, "not started");
        require(block.timestamp<stakeModel.endDateTime, "ended");
        require(stakeModel.status==IStakePool.StakeStatus.Alive, "cancelled stake");
        require(!stakeExtra.isWhitelist || MerkleProof.verify(proof, stakeExtra.rootHash, keccak256(abi.encodePacked(msg.sender))), "Not Whitelisted");
    }

    function validateUnstake(
        IStakePool.StakeExtra storage stakeExtra,
        bytes32[] calldata proof
    ) external view {
        require(!stakeExtra.isWhitelist || MerkleProof.verify(proof, stakeExtra.rootHash, keccak256(abi.encodePacked(msg.sender))), "Not Whitelisted");
    }

    function validateOwner(IStakePool.StakeExtra storage stakeExtra) external view {
        require(stakeExtra.stakeOwner == msg.sender, "Ownable");
    }

    function validateWithdrawRewards(IStakePool.StakeExtra storage stakeExtra, uint256 amount) external view {
        require(stakeExtra.stakeOwner == msg.sender, "Ownable");
        require(stakeExtra.depositAmount >= amount, "insufficient amount");
    }

    function validateUpdateWhitelist(IStakePool.StakeExtra storage stakeExtra) external view {
        require(stakeExtra.stakeOwner == msg.sender, "Ownable");
        require(stakeExtra.isWhitelist, "!W");
    }

    function validateClaim(
        uint256 claimDateTime,
        IStakePool.RewardType rewardType
    ) external view {
        require(block.timestamp>=claimDateTime, "not claimDateTime");
        require(rewardType!=IStakePool.RewardType.NoReward, "No reward stake pool.");
    }
    function validateDeposit(
        IStakePool.RewardType rewardType,
        IStakePool.StakeStatus status
    ) external pure {
        require(rewardType!=IStakePool.RewardType.NoReward, "No reward stake pool.");
        require(status==IStakePool.StakeStatus.Alive, "cancelled stake");
    }
    function validateDistribute(
        IStakePool.RewardType rewardType,
        IStakePool.StakeStatus status,
        uint256 totalSupply
    ) external pure {
        require(status==IStakePool.StakeStatus.Alive, "cancelled stake");
        require(rewardType!=IStakePool.RewardType.NoReward && rewardType!=IStakePool.RewardType.NoRatio, "No ratio reward stake pool.");
        require(totalSupply>0, "No stakers!");
    }
}