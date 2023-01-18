/**
 *Submitted for verification at Arbiscan on 2023-01-18
*/

// File: lib/Constant.sol




pragma solidity 0.8.11;

library Constant {
    uint    public constant SUPERDEED_VERSION   = 2;
    address public constant ZERO_ADDRESS        = address(0);
    uint    public constant PCNT_100            = 1e6;
    uint    public constant EMERGENCY_WINDOW    = 1 days;
}



// File: lib/DataType.sol




pragma solidity 0.8.11;

library DataType {
      
    struct Store {
        Asset asset;
        Groups groups;
        mapping(uint => NftInfo) nftInfoMap; // Maps NFT Id to NftInfo
        uint nextIds; // NFT Id management 
        mapping(address=>Action[]) history; // History management
        Erc721Handler erc721Handler; // Erc721 asset deposit & claiming management
    }

    struct Asset {
        string symbol;
        string deedName;
        address tokenAddress;
        AssetType tokenType;
        uint tokenId; // Specific for ERC1155 type of asset only
    }

    struct Groups {
        Group[] items;
        uint vestingStartTime; // Global timestamp for vesting to start
    }
    
    struct GroupInfo {
        string name;
        uint totalEntitlement; // Total tokens to be distributed to this group
    }

    struct GroupState {
        bool finalized;
        bool funded;
    }

    struct Group {
        GroupInfo info;
        VestingItem[] vestItems;
        
        // 2 modes to claim the deed.
        // 1: By merkle tree
        // 2: By SL Campaign
        bytes32 merkleRootUserSource;   // Deed claims using Merkle tree
        address campaignUserSource;     // Deed claims using the user addresses from SL campaign
        mapping(uint => uint) deedClaimMap;
        GroupState state;
    }

    struct Erc721Handler {
        uint[] erc721IdArray;
        mapping(uint => bool) idExistMap;
        uint erc721NextClaimIndex;
        uint numErc721TransferedOut;
        uint numUsedByVerifiedGroups;
    }

    struct NftInfo {
        uint groupId;
        uint totalEntitlement; 
        uint totalClaimed;
        bool valid;
    }  

    struct VestingItem {
        VestingReleaseType releaseType;
        uint delay;
        uint duration;
        uint percent;
    }
    
    struct Action {
        uint128     actionType;
        uint128     time;
        uint256     data1;
        uint256     data2;
    }
   
    struct History {
        mapping(address=>Action[]) investor;
        Action[] campaignOwner;
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

    enum ActionType {
        ClaimDeed,
        ClaimTokens
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


    
// File: logic/Vesting.sol



pragma solidity ^0.8.2;



library Vesting {

    event DefineVesting();

    function defineVesting(DataType.Group storage group,  DataType.VestingItem[] calldata vestItems) external returns (uint) {
        
        uint len = vestItems.length;

        // Clear existing vesting items
        delete group.vestItems;

        // Append items
        uint totalPercent;
        for (uint n=0; n<len; n++) {

            DataType.VestingReleaseType relType = vestItems[n].releaseType;

            _require(relType < DataType.VestingReleaseType.Unsupported, "Invalid type");
            _require(!(relType == DataType.VestingReleaseType.Linear && vestItems[n].duration == 0), "Invalid param");
            _require(vestItems[n].percent > 0, "Invalid percent");
            
            totalPercent += vestItems[n].percent;
            group.vestItems.push(vestItems[n]);
        }
        // The total percent have to add up to 100 %
        _require(totalPercent == Constant.PCNT_100, "Must be 100%");

        emit DefineVesting();
        
        return len;
    }

    function getClaimable(DataType.Groups storage groups, uint groupId) external view returns (uint claimablePercent) {

        _require(groupId < groups.items.length, "Invalid id");

        uint start = groups.vestingStartTime;
        uint end = block.timestamp;

        // Vesting not started yet ?
        if (start == 0 || end <= start) {
            return 0;
        }

        DataType.VestingItem[] storage items = groups.items[groupId].vestItems;
        uint len = items.length;
       
        for (uint n=0; n<len; n++) {

            (uint percent, bool continueNext, uint traverseBy) = getRelease(items[n], start, end);
            claimablePercent += percent;

            if (continueNext) {
                start += traverseBy;
            } else {
                break;
            }
        }
    }

    function getRelease(DataType.VestingItem storage item, uint start, uint end) public view returns (uint releasedPercent, bool continueNext, uint traverseBy) {

        releasedPercent = 0;
        bool passedDelay = (end > (start + item.delay));
        if (passedDelay) {
           
            if (item.releaseType == DataType.VestingReleaseType.LumpSum) {
                releasedPercent = item.percent;
                continueNext = true;
                traverseBy = item.delay;
            } else if (item.releaseType == DataType.VestingReleaseType.Linear) {
                uint elapsed = end - start - item.delay;
                releasedPercent = min(item.percent, (item.percent * elapsed) / item.duration);
                continueNext = (end > (start + item.delay + item.duration));
                traverseBy = (item.delay+item.duration);
            } 
            else {
                assert(false);
            }
        } 
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function _require(bool condition, string memory error) private pure {
        require(condition, error);
    }
}