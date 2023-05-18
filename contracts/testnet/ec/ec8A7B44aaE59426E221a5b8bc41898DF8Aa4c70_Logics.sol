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

// SPDX-License-Identifier: BUSL-1.1


pragma solidity 0.8.15;

library Constant {

    address public constant ZERO_ADDRESS                        = address(0);
    uint    public constant E18                                 = 1e18;
    uint    public constant PCNT_100                            = 1e18;
    uint    public constant PCNT_50                             = 5e17;
    uint    public constant E12                                 = 1e12;
    
    // SaleTypes
    uint8    public constant TYPE_IDO                            = 0;
    uint8    public constant TYPE_OTC                            = 1;
    uint8    public constant TYPE_NFT                            = 2;

    uint8    public constant PUBLIC                              = 0;
    uint8    public constant STAKER                              = 1;
    uint8    public constant WHITELISTED                         = 2;

    // Misc
    bytes public constant ETH_SIGN_PREFIX                       = "\x19Ethereum Signed Message:\n32";

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

library CertsTypes {
    struct Store {
        Vestings vestings;
        mapping(uint => NftInfo) nftInfoMap; // Maps NFT Id to NftInfo
        uint nextIds; // NFT Id management
        Erc721Handler erc721Handler; // Erc721 asset deposit & claiming management
    }

    struct Asset {
        string symbol;
        string certsName;
        address tokenAddress;
        AssetType tokenType;
        uint tokenId; // Specific for ERC1155 type of asset only
        bool isFunded;
    }

    struct Fund {
        address currency;
        address claimer;
        uint canRefundToGroupId; // Which group Id can this fund be refunded
    }

    struct Vestings {
        TeamGroup team;
        UserGroups users;
        uint vestingStartTime; // Global timestamp for vesting to start
    }

    struct TeamGroup {
        Fund fund;
        Group item;
    }

    struct UserGroups {
        Asset asset;
        Group[] items;
    }

    struct Group {
        GroupInfo info;
        GroupSource source;
        VestingItem[] vestItems;
        mapping(uint => uint) deedClaimMap;
        GroupState state;
    }

    struct GroupSource {
        // 2 modes to claim the deed.
        // 1: By merkle tree
        // 2: By SL Campaign
        bytes32 merkleRootUserSource; // Cert claims using Merkle tree
        address campaignUserSource; // SL campaign to define the users (including team vesting)
    }

    struct VestingItem {
        VestingReleaseType releaseType;
        uint delay;
        uint duration;
        uint percent;
    }

    struct GroupInfo {
        string name;
        uint totalEntitlement; // Total tokens to be distributed to this group
        uint totalClaimed; // In case of refund, we use this to determine the remaining unclaimed entitlement.
    }

    struct GroupState {
        bool finalized;
        bool funded;
    }

    struct Erc721Handler {
        uint[] erc721IdArray;
        mapping(uint => bool) idExistMap;
        uint erc721NextClaimIndex;
        uint numErc721TransferedOut;
        uint numUsedByVerifiedGroups;
    }

    struct NftInfo {
        bool isTeam; // Team vesting NFT or User vesting NFT
        uint groupId;
        uint totalEntitlement;
        uint totalClaimed;
        bool valid;
    }

    // ENUMS
    enum AssetType {
        ERC20,
        ERC1155,
        ERC721
    }

    enum VestingReleaseType {
        LumpSum,
        Linear,
        Unsupported
    }

    enum GroupError {
        None,
        InvalidId,
        NotYetFinalized,
        NoUserSource,
        NoEntitlement,
        NoVestingItem
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../CertsTypes.sol";
import "../../../Constant.sol";

library Logics {
    // Events for Groups
    event AppendGroup(address indexed user, string name);
    event AttachToCampaign(address campaign, string name);
    event SetGroupFinalized(address indexed user, string name);
    event SetUserSource(address indexed campaign, string name, uint totalTokens);
    event SetTeamSource(address indexed campaign, address fundAddress, uint fundAmount);
    // Events for Vesting
    event DefineVesting();
    event StartVesting(address indexed user, uint timeStamp);
    // Misc events
    event SetAssetDetails(address indexed user, address tokenAddress, CertsTypes.AssetType tokenType, uint tokenIdFor1155);

    //--------------//
    // GROUPS LOGIC //
    //--------------//

    function appendGroups(CertsTypes.UserGroups storage groups, string[] memory names) external returns (uint len) {
        len = names.length;
        for (uint n = 0; n < len; n++) {
            (bool found, ) = exist(groups, names[n]);
            _require(!found, "Group exist");

            CertsTypes.Group storage newGroup = groups.items.push();
            newGroup.info.name = names[n];
            emit AppendGroup(msg.sender, names[n]);
        }
    }

    function setUserSourceByMerkle(CertsTypes.Group storage group, bytes32 root, uint totalTokens) external {
        group.source.merkleRootUserSource = root;
        group.info.totalEntitlement = totalTokens;
        emit SetUserSource(msg.sender, group.info.name, totalTokens);
    }

    function setUserSourceByCampaign(CertsTypes.Group storage group, address campaign, uint totalTokens, bool finalizeGroup) external {
        // Check is the campaign hook?
        _require(group.source.campaignUserSource == campaign, "Wrong hook");

        group.info.totalEntitlement = totalTokens;

        if (finalizeGroup) {
            setFinalized(group);
        }
        emit SetUserSource(msg.sender, group.info.name, totalTokens);
    }

    function setTeamSourceByCampaign(CertsTypes.TeamGroup storage team, address campaign, address teamAddress, address currency, uint amount) external {
        // Check is the campaign hook?
        _require(team.item.source.campaignUserSource == campaign, "Wrong hook");

        team.item.info.totalEntitlement = amount;
        team.fund.currency = currency;
        team.fund.claimer = teamAddress;
        setFinalized(team.item);
        emit SetTeamSource(msg.sender, currency, amount);
    }

    // Can only be attached to a single campaign only.
    function attachToCampaign(CertsTypes.Vestings storage vestings, address campaign, uint groupId, string memory groupName) external {
        _require(campaign != address(0), "Invalid address");
        _require(vestings.team.item.source.campaignUserSource == address(0), "Already attached");

        CertsTypes.Group storage group = at(vestings.users, groupId, groupName);
        group.source.campaignUserSource = campaign; // For UserGroup
        vestings.team.item.source.campaignUserSource = campaign; // For TeamGroup
        vestings.team.fund.canRefundToGroupId = groupId;
        emit AttachToCampaign(campaign, group.info.name);
    }

    function setFinalized(CertsTypes.Group storage group) public {
        // Either merkleroot OR campaign source is required
        _require(hasUserSource(group), "No source");

        _require(group.info.totalEntitlement > 0, "No entitlement");
        _require(group.vestItems.length > 0, "No vesting");
        group.state.finalized = true;
        emit SetGroupFinalized(msg.sender, group.info.name);
    }

    function statusCheck(CertsTypes.UserGroups storage groups, uint groupId) external view returns (CertsTypes.GroupError) {
        uint len = groups.items.length;
        if (groupId >= len) return CertsTypes.GroupError.InvalidId;

        CertsTypes.Group storage item = groups.items[groupId];
        if (!item.state.finalized) return CertsTypes.GroupError.NotYetFinalized;
        if (!hasUserSource(item)) return CertsTypes.GroupError.NoUserSource;
        if (item.info.totalEntitlement == 0) return CertsTypes.GroupError.NoEntitlement;
        if (item.vestItems.length == 0) return CertsTypes.GroupError.NoVestingItem;
        return CertsTypes.GroupError.None;
    }

    function exist(CertsTypes.UserGroups storage groups, string memory name) public view returns (bool, uint) {
        uint len = groups.items.length;
        for (uint n = 0; n < len; n++) {
            if (_strcmp(groups.items[n].info.name, name)) {
                return (true, n);
            }
        }
        return (false, 0);
    }

    function at(CertsTypes.UserGroups storage groups, uint groupId, string memory groupName, bool requiredFinalizeState) external view returns (CertsTypes.Group storage group) {
        group = at(groups, groupId, groupName);
        _require(group.state.finalized == requiredFinalizeState, "Wrong state");
    }

    function at(CertsTypes.UserGroups storage groups, uint groupId, string memory groupName) public view returns (CertsTypes.Group storage group) {
        group = groups.items[groupId];
        bool matched = _strcmp(group.info.name, groupName);
        _require(matched, "Unnmatched");
    }

    function hasUserSource(CertsTypes.Group storage group) private view returns (bool) {
        return group.source.merkleRootUserSource.length > 0 || group.source.campaignUserSource != address(0);
    }

    //---------------------//
    // MERKLE CLAIMS LOGIC //
    //---------------------//

    function isClaimed(CertsTypes.Group storage group, uint index) public view returns (bool) {
        uint claimedWordIndex = index / 256;
        uint claimedBitIndex = index % 256;
        uint claimedWord = group.deedClaimMap[claimedWordIndex];
        uint mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function setClaimed(CertsTypes.Group storage group, uint index) public {
        uint claimedWordIndex = index / 256;
        uint claimedBitIndex = index % 256;
        group.deedClaimMap[claimedWordIndex] = group.deedClaimMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(CertsTypes.Group storage group, uint index, address account, uint amount, bytes32[] calldata merkleProof) external {
        _require(!isClaimed(group, index), "Claimed");
        _require(amount > 0 && verifyClaim(group, index, account, amount, merkleProof), "Invalid");
        setClaimed(group, index);
    }

    function verifyClaim(CertsTypes.Group storage group, uint index, address account, uint amount, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        return MerkleProof.verify(merkleProof, group.source.merkleRootUserSource, node);
    }

    //---------------//
    // VESTING LOGIC //
    //---------------//

    function defineVesting(CertsTypes.Group storage group, CertsTypes.VestingItem[] calldata vestItems) external returns (uint) {
        uint len = vestItems.length;
        delete group.vestItems; // Clear existing vesting items

        // Append items
        uint totalPercent;
        for (uint n = 0; n < len; n++) {
            CertsTypes.VestingReleaseType relType = vestItems[n].releaseType;

            _require(relType < CertsTypes.VestingReleaseType.Unsupported, "Invalid type");
            _require(!(relType == CertsTypes.VestingReleaseType.Linear && vestItems[n].duration == 0), "Invalid param");
            _require(vestItems[n].percent > 0, "Invalid percent");

            totalPercent += vestItems[n].percent;
            group.vestItems.push(vestItems[n]);
        }
        // The total percent have to add up to 100 %
        _require(totalPercent == Constant.PCNT_100, "Must be 100%");

        emit DefineVesting();

        return len;
    }

    function getClaimablePercent(CertsTypes.Vestings storage vestings, uint groupId, bool isTeam) public view returns (uint claimablePercent, uint totalEntitlement) {
        CertsTypes.Group storage group;
        if (isTeam) {
            group = vestings.team.item;
        } else {
            group = vestings.users.items[groupId];
        }

        if (!group.state.finalized) {
            return (0, 0);
        }

        totalEntitlement = group.info.totalEntitlement;

        uint start = vestings.vestingStartTime;
        uint end = block.timestamp;

        // Vesting not started yet ?
        if (start == 0 || end <= start) {
            return (0, totalEntitlement);
        }

        CertsTypes.VestingItem[] storage items = group.vestItems;
        uint len = items.length;

        for (uint n = 0; n < len; n++) {
            (uint percent, bool continueNext, uint traverseBy) = getRelease(items[n], start, end);
            claimablePercent += percent;

            if (continueNext) {
                start += traverseBy;
            } else {
                break;
            }
        }
    }

    function getClaimable(CertsTypes.Vestings storage vestings, CertsTypes.NftInfo storage nft) external view returns (uint claimable) {
        (uint percentReleasable, ) = getClaimablePercent(vestings, nft.groupId, nft.isTeam);
        if (percentReleasable > 0) {
            uint totalReleasable = (percentReleasable * nft.totalEntitlement) / Constant.PCNT_100;
            if (totalReleasable > nft.totalClaimed) {
                claimable = totalReleasable - nft.totalClaimed;
            }
        }
    }

    function getRelease(CertsTypes.VestingItem storage item, uint start, uint end) public view returns (uint releasedPercent, bool continueNext, uint traverseBy) {
        releasedPercent = 0;
        bool passedDelay = (end > (start + item.delay));
        if (passedDelay) {
            if (item.releaseType == CertsTypes.VestingReleaseType.LumpSum) {
                releasedPercent = item.percent;
                continueNext = true;
                traverseBy = item.delay;
            } else if (item.releaseType == CertsTypes.VestingReleaseType.Linear) {
                uint elapsed = end - start - item.delay;
                releasedPercent = _min(item.percent, (item.percent * elapsed) / item.duration);
                continueNext = (end > (start + item.delay + item.duration));
                traverseBy = (item.delay + item.duration);
            } else {
                assert(false);
            }
        }
    }

    function startVesting(CertsTypes.Vestings storage vestings, uint startTime) external {
        if (startTime == 0) {
            startTime = block.timestamp;
        }

        // Make sure that the asset address are set before start vesting.
        // Also, at least 1 group must be funded
        CertsTypes.Asset storage asset = vestings.users.asset;
        _require(asset.tokenAddress != Constant.ZERO_ADDRESS && asset.isFunded && startTime >= block.timestamp, "Cannot start");

        vestings.vestingStartTime = startTime;
        emit StartVesting(msg.sender, startTime);
    }

    

    function getUnClaimed(CertsTypes.Vestings storage vestings, uint groupId, bool isTeam) external view returns(uint) {
        
        CertsTypes.Group storage group;
        if (isTeam) {
            group = vestings.team.item;
        } else {
            group = vestings.users.items[groupId];
        }
        return group.info.totalEntitlement - group.info.totalClaimed;
    }

    //------------//
    // MISC LOGIC //
    //------------//

    function setAssetDetails(CertsTypes.Asset storage asset, address tokenAddress, CertsTypes.AssetType tokenType, uint tokenIdFor1155) external {
        _require(!asset.isFunded, "Funded");
        _require(tokenAddress != Constant.ZERO_ADDRESS, "Invalid address");
        asset.tokenAddress = tokenAddress;
        asset.tokenType = tokenType;
        asset.tokenId = tokenIdFor1155;
        emit SetAssetDetails(msg.sender, tokenAddress, tokenType, tokenIdFor1155);
    }

    // Helpers
    function _strcmp(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }

    function _require(bool condition, string memory error) private pure {
        require(condition, error);
    }
}