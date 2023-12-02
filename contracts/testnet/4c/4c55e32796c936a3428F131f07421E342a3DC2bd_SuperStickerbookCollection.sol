//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

// Stickerbook using both Utility Traits AND Visual Traits
// Badges and badge counters 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//import "../Traits/implementers/TraitUint8ValueImplementer.sol";
import "../Traits/Registry/GTRegistry.sol";
import "../Traits/Implementers/Generic/GenericTrait.sol";
import "../Traits/VisualTraitRegistry/VisualTraitRegistry.sol";
import "../Traits/interfaces/IRegistryConsumer.sol";
import "../@galaxis/registries/contracts/ICommunityList.sol";
import "../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../Traits/extras/recovery/BlackHolePrevention.sol";
import "../TraitMarket/CouponMinter.sol";

import "./ISuperStickerbookCollection.sol";
import "./SuperStickerbookUtils.sol";

import "hardhat/console.sol";

interface reward721 {
    function mintNext(address receiver) external;
}


contract SuperStickerbookCollection is Ownable ,ERC1155, SuperStickerbookData {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    function version() public view virtual returns (uint256) {
        return 20231020;
    }

    IRegistryConsumer   constant                              theRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
    bytes32             constant                       public STICKERBOOK_ADMIN = keccak256("STICKERBOOK_ADMIN");

   
    error StickerBookNameTaken(string name, uint value);
    error StickerBookDoesNotExist(string name);
    error StickerBookNotActive(string name);
    error ApprovalNotGiven(address owner, address operator);
    error MaxClaimsReached(uint16 maxClaims);
    error CommunityListNotLoaded(address);
    error CommunityRegistryNotLoaded(address);
    error NFTNotLoaded(address);
    error TraitRegistryNotLoaded(address);
    error StickerbookUtilsNotSet();

    error CardDoesNotHaveBadgeTrait(uint32 tokenId);
    error CardBadgeTraitNotActive(uint32 tokenId,uint8 status);


    error WrongNumberOfTokens(string name,uint256 tokenIdsLength ,uint256 ExpectedNumberOfTokens);
    error CriteriaNotMet(string name,uint256 tokenId,string criteria_name,uint256 actual);
    error TraitImplementerNotSet(string name);
    error InvalidLayerID(uint8 layer, uint256 numberOfTraits);
    error NFTnotSetInCommunityRegistry();
    error SBContractAlreadyInitialized();
    error TraitRegistryNotSetInCommunityRegistry();
    error StickerbookCannotModifyBadge();
    error ClaimantDoesNotOwnTheseTokens();
    error ClaimantDoesNotOwnRandomNft(address nft_address,uint256 tokenId);
    error TokenHasBeenUsed(uint32);

    error ConditionalNotMet(uint16,uint16,uint8,uint8);

    error TraitDoesNotExist(uint16 _traitToClear,uint16 _traitCount);
    error TraitHasNoImplementer(uint16 traitID);

    error InvalidRewardDefined(rewardTypeEnum rt);

    event BookIPFSUpdated(uint16 bookID,string xipfsHash);

    fallback(bytes calldata b) external returns (bytes memory) {

        address dest = ds().superstickerbook_utils;
        (bool success, bytes memory returnedData) = dest.delegatecall(b);
        if (!success) {
            assembly {
                revert(add(returnedData,32),mload(returnedData))
            }
        }
        return returnedData;
    }

    constructor() ERC1155("GOLDEN_STICKERBOOK") { // GOLDEN
        ds()._initialized = true; // to stop ppl messing with it
    }



    function init (StickerbookInitData memory data) external { // as proxy
        if (ds()._initialized) revert  SBContractAlreadyInitialized();
        ds().superstickerbook_utils = theRegistry.getRegistryAddress("STICKERBOOK_UTILS");
        if (ds().superstickerbook_utils == address(0)) revert StickerbookUtilsNotSet();
        // to allow traitTeleport
        ds().communityID = data.communityId;
        ds().collectionNumber = data.collectionNumber;
        
        address clAddr =  theRegistry.getRegistryAddress("COMMUNITY_LIST");
        if (clAddr.code.length == 0) {
            revert CommunityListNotLoaded(clAddr);
        }
        ICommunityList COMMUNITY_LIST = ICommunityList(clAddr);
        
        (,address crAddr,) = COMMUNITY_LIST.communities(data.communityId);
        if (crAddr.code.length == 0) {
            revert CommunityRegistryNotLoaded(crAddr);
        }
        ds().myCommunityRegistry = CommunityRegistry(crAddr);

        string memory tokenName = string.concat("TOKEN_",uint256(data.collectionNumber).toString());
        string memory traitRegistryName = string.concat("TRAIT_REGISTRY_",uint256(data.collectionNumber).toString());


        address nftAddress = ds().myCommunityRegistry.getRegistryAddress(tokenName);
        if (nftAddress == address(0)) revert NFTnotSetInCommunityRegistry();
        if (nftAddress.code.length == 0) {
            revert NFTNotLoaded(nftAddress);
        }
        ds().nft = IERC721(nftAddress);

        address traitRegAddress = ds().myCommunityRegistry.getRegistryAddress(traitRegistryName);
        if (traitRegAddress == address(0)) revert TraitRegistryNotSetInCommunityRegistry();
        if (traitRegAddress.code.length == 0) {
            revert TraitRegistryNotLoaded(crAddr);
        }

        ds().reg = GTRegistry(traitRegAddress);

        ds().parent = SBF(msg.sender);
        ds()._initialized = true;
    }

    //--- ADMIN


    function _newStickerBook(
        fullStickerBookData calldata fsbd
        // string calldata name,
        // uint16          maxRedemptions,
        // marking         _clearBadge,
        // uint16          _traitToClear,
        // string calldata ipfsHash,
        // bool            acceptsJoker,
        // uint16          jokerID,
        // uint16          rewardTrait,
        // rewardTypeEnum  rewardType,
        // address         nftToMint,
        // string calldata _uri
    ) internal {
        uint16 x = ds().stickerbooks[fsbd.name];
        if ( x != 0) {
            revert StickerBookNameTaken(fsbd.name,x);
        }
        if (fsbd.clearBadge == marking.CLEAR_BADGE) {
            if (fsbd.traitToClear >= ds().reg.traitCount())
                revert TraitDoesNotExist(fsbd.traitToClear,ds().reg.traitCount());
            address addr = ds().reg.getImplementer(fsbd.traitToClear);
            if (addr == address(0))
                revert TraitHasNoImplementer(fsbd.traitToClear);
            ds()._implementers[fsbd.traitToClear] = GenericTrait(addr);
            ds().parent.grantBadgeAccessToStickerbook(fsbd.traitToClear);   
        }
        uint16 bookPos = (ds().nextBook += 1);
        ds().stickerbooks[fsbd.name] = bookPos;
        ds().stickerBookData[bookPos] = stickerBookInfo(fsbd.name,bookPos,false,fsbd.maxRedemptions,0,0,fsbd.uri,0,fsbd.clearBadge,fsbd.traitToClear,fsbd.ipfsHash);
        ds().extraInfo[bookPos] = Extra(fsbd.acceptsJoker,fsbd.jokerID,fsbd.rewardType,fsbd.rewardTraitID,fsbd.nftToMint);

    }

    function numberOfStickers(uint16 stickerBookID,uint16 stickerPosition) external view returns (uint256) {
        return ds().stickers[stickerBookID][stickerPosition].length;
    }

    function numberOfConditions(uint16 stickerBookID,uint16 stickerPosition) external view returns (uint256) {
        return ds().conditionalStickers[stickerBookID][stickerPosition].length;
    }

   function getStickerBookID(string memory name) external view returns (uint16) {
        return _getStickerBookID(name);
   }
 
    function _getStickerBookID(string memory name) internal view returns (uint16) {
        uint16 stickerBookID = ds().stickerbooks[name];
        if (stickerBookID == 0) {
            revert StickerBookDoesNotExist(name);
        }
        return stickerBookID;
    }

    
    function _addSticker(
        uint16 stickerBookID,
        stickerInput[] calldata thisStickerData
    ) internal {
        uint16 stickerPosition = ds().stickerBookData[stickerBookID].stickerCount;
        for (uint256 pos = 0; pos < thisStickerData.length; pos++){
            uint256 len = ds().stickers[stickerBookID][stickerPosition].length++;
            newConvert(
                ds().stickers[stickerBookID][stickerPosition].data[len],
                thisStickerData[pos]);
        }
        ds().stickerBookData[stickerBookID].stickerCount++;
    }

    function newConvert(sticker storage sm, stickerInput memory si) internal {
        if (si.traitID >= ds().reg.traitCount())
            revert TraitDoesNotExist(si.traitID,ds().reg.traitCount());
        GTRegistry.traitStruct memory ts = ds().reg.getTrait(si.traitID);
        if (ts.storageImplementer == address(0)) 
            revert TraitHasNoImplementer(si.traitID);
        ds()._implementers[si.traitID] = GenericTrait(ts.storageImplementer);
        sm.name        = ts.name;
        sm.traitID     = si.traitID;
        sm.visual      = si.visual;
        sm.nft_address = si.nft_address;
        if (sm.visual == stickerType.VISUAL_TRAIT) {
            uint256 numberOfTraits = VisualTraitRegistry(ts.storageImplementer).numberOfTraits(sm.side);
            if (si.layer >= numberOfTraits) revert InvalidLayerID(si.layer, numberOfTraits);
            sm.side  = si.side;
            sm.layer = si.layer;
            string[] memory f = VisualTraitRegistry(ts.storageImplementer).getTraitNames(sm.side);
            sm.name = f[sm.layer];
        }
        for (uint256 pos = 0; pos < si.alternative_values.length; pos++) {
            sm.alternative_values.add(si.alternative_values[pos]);
        }
    }

    function setRewardURI(
        string calldata    name,
        string calldata    _uri
    ) external onlyAllowed(STICKERBOOK_ADMIN) {
        uint16 stickerBookID = _getStickerBookID(name);
        ds().stickerBookData[stickerBookID].uri = _uri;
    }

    function activate(
        string calldata    name,
        bool               status
    ) external onlyAllowed(STICKERBOOK_ADMIN) {
        uint16 stickerBookID = _getStickerBookID(name);
        ds().stickerBookData[stickerBookID].active = status;
    }

    // @to-do ensure that we have unique tokenIds

    function claim(string calldata name, uint32[] calldata tokenIds) external {
        
        uint16 stickerBookID = _getStickerBookID(name);
        if (! ds().stickerBookData[stickerBookID].active ) {
            revert StickerBookNotActive(name);
        }
        
        ds().stickerBookData[stickerBookID].numberRedeemed++;
        if (
            (ds().stickerBookData[stickerBookID].maxRedemptions != 0) && 
            (ds().stickerBookData[stickerBookID].numberRedeemed > ds().stickerBookData[stickerBookID].maxRedemptions)
        ) {
            revert MaxClaimsReached(ds().stickerBookData[stickerBookID].maxRedemptions);
        }

        
        if (tokenIds.length != ds().stickerBookData[stickerBookID].stickerCount){
            revert WrongNumberOfTokens(name,tokenIds.length ,ds().stickerBookData[stickerBookID].stickerCount);
        }

        marking _clearBadge = ds().stickerBookData[stickerBookID].clearBadge;
        uint16 _traitToClear = ds().stickerBookData[stickerBookID].traitToClear;
        if (_clearBadge == marking.TAKE_CARD) {
            if (! ds().nft.isApprovedForAll(msg.sender, address(this))) {
                revert ApprovalNotGiven(
                    msg.sender,
                    address(this)
                );
            }
            for (uint16 pos = 0; pos < tokenIds.length; pos++) {
                if (notRandomNft(stickerBookID,pos,tokenIds[pos])) {
                    ds().nft.transferFrom(msg.sender,address(this),tokenIds[pos]);
                }
            }
        } else if (_clearBadge == marking.CLEAR_BADGE) {
            
            if(!ds().reg.addressCanModifyTrait(address(this),_traitToClear)) revert StickerbookCannotModifyBadge();
            address imp = address(ds()._implementers[_traitToClear]);
            GenericTrait implementer = GenericTrait(imp);
            //console.log("in claim imp =  ",imp);
            for (uint p = 0; p < tokenIds.length; p++) {
                if (!implementer.hasTrait(tokenIds[p]))
                    revert CardDoesNotHaveBadgeTrait(tokenIds[p]);
                uint8 status = implementer.status(tokenIds[p]);
                if (status != 1) 
                    revert CardBadgeTraitNotActive(tokenIds[p],status);
                implementer.decrementCounter(tokenIds[p]);
            }
            
            for (uint16 pos = 0; pos < tokenIds.length; pos++) {  
                if (notRandomNft(stickerBookID,pos,tokenIds[pos])) {      
                    if(!underControlOfSender(tokenIds[pos])) revert ClaimantDoesNotOwnTheseTokens();
                    if(ds().used[stickerBookID][tokenIds[pos]]) revert TokenHasBeenUsed(tokenIds[pos]);
                    ds().used[stickerBookID][tokenIds[pos]] = true;
                }
            }

        }
        uint16 count = ds().stickerBookData[stickerBookID].conditionalCountCounter;
        bool[] memory jokers = anyJokers(tokenIds,stickerBookID);
        //console.log("onto stickers");
        for (uint16 pos = 0; pos < tokenIds.length; pos++) {
            if (jokers[pos]) continue; // this card gets a free pass!

            uint32 tokenId = tokenIds[pos];
            uint256 numberOfCriteria = ds().stickers[stickerBookID][pos].length;

            checkAllCriteria(stickerBookID,pos,name,numberOfCriteria,tokenId);

        }
        // now check the conditionals
        for (uint16 cpos = 0; cpos < count; cpos++) {
                uint8 conditionalCounter = 0;
                for (uint16 pos = 0; pos < tokenIds.length; pos++) {
                    if (jokers[pos] || checkConditional(stickerBookID,cpos,tokenIds[pos])) conditionalCounter++;
                }
                uint8 required = ds().conditionalCount[stickerBookID][cpos];
                //console.log("cc2",cpos,conditionalCounter,required);
                if(conditionalCounter < required) {
                    //console.log("reverting");
                    revert ConditionalNotMet(stickerBookID,cpos,conditionalCounter,ds().conditionalCount[stickerBookID][cpos]);
                }
        }
        rewardTypeEnum rt = ds().extraInfo[stickerBookID].rewardType;
        if (rt == rewardTypeEnum.TRAIT_COUPON){
            address teleporter = theRegistry.getRegistryAddress("TRAIT_COUPON_MINTER");
            //console.log("teleporting with ",teleporter);
            CouponMinter(teleporter).newTraitCoupon(msg.sender,ds().communityID,ds().collectionNumber,1,ds().extraInfo[stickerBookID].rewardTraitID);
            //console.log("telly ported");
        } else if(rt == rewardTypeEnum.CONTRACT_1155) {
            _mint(msg.sender,stickerBookID,1,new bytes(0));
        // } 
        // else if(rt == rewardTypeEnum.MINT_721) {
        //     reward721 rewardNFT = reward721(ds().extraInfo[stickerBookID].nftToMint);
        //     rewardNFT.mintNext(msg.sender);
        } else {
            revert InvalidRewardDefined(rt);
        }
    }

    function underControlOfSender(uint32 tokenId) internal view returns (bool) {
        CardOwnerRouter router = CardOwnerRouter(theRegistry.getRegistryAddress("CARD_OWNER_ROUTER"));
        if (address(router) == address(0)) {
            return IERC721(ds().nft).ownerOf(tokenId) == msg.sender;
         }
        return router.underControlOf(
            msg.sender,
            ds().communityID,
            ds().collectionNumber,
            tokenId
        );
    }

    function notRandomNft(uint16 stickerbookID,uint16 pos, uint32 tokenId) internal view returns (bool isRandom) {
        stickerStruct storage stix =  ds().stickers[stickerbookID][pos];
        if ((stix.length != 1) || stix.data[0].visual != stickerType.RANDOM_NFT) return true;
        require(IERC721(stix.data[0].nft_address).ownerOf(tokenId) == msg.sender,"SuperStickerbook : you do not own this random NFT");
        return false;
    }

    function checkAllCriteria(uint16 stickerBookID, uint16 pos, string calldata name,uint256 numberOfCriteria, uint32 tokenId) internal  {
        for (uint256 criteria = 0; criteria < numberOfCriteria; criteria++) {
            uint256 traitNum;
                sticker storage st = ds().stickers[stickerBookID][pos].data[criteria];
                if (st.visual == stickerType.RANDOM_NFT) {
                    //console.log("checking ",st.nft_address,tokenId);
                    if (msg.sender != IERC721(st.nft_address).ownerOf(tokenId))
                        revert ClaimantDoesNotOwnRandomNft(st.nft_address,tokenId);
                    require(!ds().randomNftsUsed[stickerBookID][st.nft_address][tokenId],"Stickerbook : this card has been used in this stickerbook");
                    ds().randomNftsUsed[stickerBookID][st.nft_address][tokenId] = true;
                    traitNum = tokenId;
                } else {
                    GenericTrait imp = ds()._implementers[st.traitID];

                    if (address(imp) == address(0)) {
                        revert TraitImplementerNotSet(st.name);
                    }
                    
                    if (st.visual == stickerType.VISUAL_TRAIT) {
                        VisualTraitRegistry  vtr = VisualTraitRegistry(address(imp));
                        traitNum = vtr.getValue(tokenId,st.side, st.layer); // get the value of that trait for this nft / tokenID
                    } else if (st.visual == stickerType.UTILITY_TRAIT){
                        traitNum = imp.hasTrait(tokenId) ? 1 : 0;
                    }
                }
                //uint256 traitVal = 1 << traitNum;
                if (! st.alternative_values.contains(traitNum)) {
                    
                    revert CriteriaNotMet(
                        name,
                        tokenId,
                        st.name,
                        traitNum
                    );
                }  
            } 
    }

    function anyJokers(uint32[] calldata tokenIds, uint16 stickerBookID) internal view returns (bool[] memory result) {
        return SuperStickerbookUtils(address(this)).anyJokers(tokenIds,stickerBookID);
    }


    function checkConditional(uint16 stickerBookID, uint16 pos, uint32 tokenId) internal view returns (bool) {
        return SuperStickerbookUtils(address(this)).checkConditional(stickerBookID, pos, tokenId); 
    }

    function updateStickerbookIPFSHashByName(string calldata bookName, string calldata ipfsHash) external onlyAllowed(STICKERBOOK_ADMIN) {
        uint16 bookID = ds().stickerbooks[bookName];
        ds().stickerBookData[bookID].ipfsHash = ipfsHash;
        emit BookIPFSUpdated(bookID,ipfsHash);
    }


    // aggregate functions

    function _addCounterSpecification(
        uint16 stickerBookID,
        conditionInput calldata condInput
        // uint8  count,
        // stickerInput[] calldata thisStickerData
    ) internal {
        uint16 stickerPosition = ds().stickerBookData[stickerBookID].conditionalCountCounter;
        for (uint256 pos = 0; pos < condInput.stix.length; pos++){
            uint256 len = ds().conditionalStickers[stickerBookID][stickerPosition].length++;
            newConvert(
                ds().conditionalStickers[stickerBookID][stickerPosition].data[len],
                condInput.stix[pos]
            );
        }
        ds().conditionalCount[stickerBookID][stickerPosition] = condInput.count;
        ds().stickerBookData[stickerBookID].conditionalCountCounter++;
    }

    function addFullStickerBook(fullStickerBookData calldata fsbd) external onlyAllowed(STICKERBOOK_ADMIN) {
        _newStickerBook(
            fsbd
        );
        uint16 stickerBookID = _getStickerBookID(fsbd.name);
        for (uint16 pos = 0; pos < fsbd.stix.length; pos++) {
            _addSticker(stickerBookID,fsbd.stix[pos]);
        }
        for (uint16 pos = 0; pos < fsbd.conditions.length; pos++) {
            _addCounterSpecification(stickerBookID,fsbd.conditions[pos]);
        }

    }

    function isStickerbookActive(string calldata name) external view returns (bool) {
        uint16 stickerBookId = _getStickerBookID(name);
        stickerBookInfo storage fsm = ds().stickerBookData[stickerBookId];
        if (! fsm.active) return false;
        if (fsm.maxRedemptions == 0) return true;
        return (fsm.maxRedemptions > fsm.numberRedeemed);
    }

    function hasRole(bytes32 key, address user) public view returns (bool) {
        return 
                ds().myCommunityRegistry.isUserCommunityAdmin(key, user) ||
                ds().myCommunityRegistry.hasRole(key,user);
    }

    /**
     * @dev Admin: Allow / Disallow addresses
     */

    modifier onlyAllowed(bytes32 role) { 
        require(isAllowed(role, msg.sender), "StickerBook : unauthorised");
        _;
    }

    function isAllowed(bytes32 role, address user) public view returns (bool) { 
        return( user == owner() || hasRole(role, user));
    }

}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

// Stickerbook using both Utility Traits AND Visual Traits
// Badges and badge counters 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
//import "../traits/implementers/TraitUint8ValueImplementer.sol";
import "../Traits/Registry/GTRegistry.sol";
import "../Traits/VisualTraitRegistry/VisualTraitRegistry.sol";
import "../Traits/interfaces/IRegistryConsumer.sol";
import "../@galaxis/registries/contracts/ICommunityList.sol";
import "../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../Traits/extras/recovery/BlackHolePrevention.sol";

import "./SuperStickerbookData.sol";

// Notes :

// 1. No RANDOM_NFT option 
// 2. use LeaderBoard's underControlOf
// 3. MarketPLace to use ERC20 methods, not ERC1820Receiver

interface CardOwnerRouter {
    function underControlOf(
        address _addr,
        uint32 _communityId,
        uint32 _collectionId,
        uint32 _tokenId
    ) external view returns (bool);
}

// CARD_OWNER_ROUTER



interface ISuperStickerbookCollection  {
    

    error StickerBookNameTaken(string name, uint value);
    error StickerBookDoesNotExist(string name);
    error StickerBookNotActive(string name);
    error ApprovalNotGiven(address owner, address operator);
    error MaxClaimsReached(uint16 maxClaims);
    error NoBadge(uint16 badgeID, uint16 tokenID);
    error RegistryNotLoaded();
    error CommunityListNotLoaded(address);
    error CommunityRegistryNotLoaded(address);
    error NFTNotLoaded(address);
    error TraitRegistryNotLoaded(address);


    error NotOwnerOfToken(uint256 tokenID, address claimant);
    error WrongNumberOfTokens(string name,uint256 tokenIdsLength ,uint256 ExpectedNumberOfTokens);
    error CriteriaNotMet(string name,uint256 tokenId,string criteria_name,uint256 actual, uint256 alternative_value_bitset);
    error BooleanCriteriaNotMet(string name, uint256 tokenId, string  criteria_name ,  bool val, uint256 expected_value);
    error TraitImplementerNotSet(string name);
    error InvalidAlternateValue(string name,uint8 val);
    error InvalidLayerID(uint8 layer, uint256 numberOfTraits);
    error NotBadgeTrait(uint16,uint8);
    error NotStickerbookBadgeTrait(uint16,address);
    error NFTnotSetInCommunityRegistry();
    error SBContractAlreadyInitialized();
    error TraitRegistryNotSetInCommunityRegistry();
    error ImplementerRequiredForVisualTraits();
    error BooleanTraitsCanOnlyHaveOneValue();
    error BooleanValuesMustBeZeroOrOne();
    error StickerbookCannotModifyBadge();
    error ClaimantDoesNotOwnTheseTokens();
    error InvalidStickerNumber();
    error TokenHasBeenUsed(uint16);

    error ConditionalNotMet(uint16,uint16,uint8,uint8);

    event BookIPFSUpdated(uint16 bookID,string xipfsHash);

  
    function init (StickerbookInitData memory data) external; 

    //--- ADMIN

    function numberOfStickers(
        uint16 stickerBookID,
        uint16 stickerPosition
    ) external view returns (uint256) ;

    function numberOfConditions(
        uint16 stickerBookID,
        uint16 stickerPosition
    ) external view returns (uint256) ;
  
    function setRewardURI(
        string calldata    name,
        string calldata    _uri
    ) external;

    function activate(
        string calldata    name,
        bool               status
    ) external ;

    // @to-do ensure that we have unique tokenIds

    function claim(string calldata name, uint16[] calldata tokenIds) external ;
  

    //function checkConditional(uint16 stickerBookID, uint16 pos, uint16 tokenId) external view returns (bool) ;

    // TODO : you give me sticker and tokenId, I tell you what positions it satisfies
    function eligible(string memory name, uint16 tokenId) external view returns (uint256[] memory) ;

    // TODO : you give me sticker and position plus a number of tokenIds, I tell you which ones work
    function satisfies(string memory name, uint16 position, uint16[] memory tokenIds) external view returns (bool[] memory) ;

    function meetsCriteria(string memory name, uint16 tokenId, uint16 pos) external view returns (bool);

    function uri(uint256 tokenId) external returns (string memory) ;

    function setURI(string calldata _newURI) external ;

    function updateStickerbookIPFSHashByName(string calldata bookName, string calldata ipfsHash) external ;


    // aggregate functions

    function addFullStickerBook(fullStickerBookData calldata fsbd) external ;

    function isStickerbookActive(string calldata name) external view returns (bool);

    function hasRole(bytes32 key, address user) external view returns (bool) ;

}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../Traits/interfaces/IECRegistry.sol";
import "../@galaxis/registries/contracts/ICommunityList.sol";
import "../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../Traits/interfaces/IRegistryConsumer.sol";
import "../Traits/Implementers/Generic/GenericTrait.sol";
import "./IUtilityTraitCoupon.sol";


import "hardhat/console.sol";

// structure
// community_id         : 32 (highest 4 bytes)
// token/trait_registry : 32 (4 bytes)
// trait_id             : 16 (lowest 2 bytes)

// interface ITokenAccountRegistry {
//     function account(uint32 communityId,uint32 tokenNumber,uint32 destinationTokenId) external view returns (address);
// }

contract CouponMinter {
    using Strings  for uint256;

    function version() external pure returns(uint256) {
        return 20230911;
    }

    address                             constant            regAddress = 0x1e8150050A7a4715aad42b905C08df76883f396F;
    IRegistryConsumer                   constant            galaxisRegistry  = IRegistryConsumer(regAddress);
    bytes32                             constant    public  COUPON_MINTER_ADMIN = keccak256("COUPON_MINTER_ADMIN");
    string                              constant            UTILITY_TRAIT_COUPON = "UTILITY_TRAIT_COUPON";
    string                              constant            TOKEN_ACCOUNT_REGISTRY = "TOKEN_ACCOUNT_REGISTRY";
    string                              constant            TRAIT_COUPON_MINTER = "TRAIT_COUPON_MINTER";

    ICommunityList                                          COMMUNITY_LIST;

    error RegistryNotLoaded();
    error CommunityListNotLoaded(address);
    error TraitRegistryNotLoaded(uint32,string,address);
    error CommunityRegistryNotLoaded(address);

    constructor() {
        scanForRegistry();
    }

    function scanForRegistry() public {
        if (regAddress.code.length == 0) {
            revert RegistryNotLoaded();
        }

        address clAddr =  galaxisRegistry.getRegistryAddress("COMMUNITY_LIST");
        if (clAddr.code.length == 0) {
            revert CommunityListNotLoaded(clAddr);
        }
        COMMUNITY_LIST = ICommunityList(clAddr);
    }

    struct tokenInfo {
        uint32 communityId;
        uint32 tokenNumber;
        uint16 traitNumber;
        uint32 tokenId;
    }

    function newTraitCoupon(
        address claimant,
        uint32 communityID, 
        uint32 tokenNum, 
        uint256 numberToMint,
        uint16 rewardTraitID
    ) external 
        onlyCommunityAdmins(communityID)
    {
        require(numberToMint > 0,"CouponMinter : numberToMint cannot be zero");
        string memory traitRegistryName = string.concat("TRAIT_REGISTRY_",uint256(tokenNum).toString());
        (CommunityRegistry myCommunityRegistry,address traitRegistryAddress ) = findMyTraitRegistry(communityID,traitRegistryName,false);
        require(
            rewardTraitID < IECRegistry(traitRegistryAddress).traitCount(),
            "CouponMinter : rewardTraitID does not exist"
        );
        IUtilityTraitCoupon iutc = IUtilityTraitCoupon(myCommunityRegistry.getRegistryAddress("UTILITY_TRAIT_COUPON"));
        require(address(iutc).code.length > 0,"CouponMinter : no Utility Trait Coupon found");
        iutc.mint(tokenNum,rewardTraitID,claimant,numberToMint,new bytes(0));
        //console.log("fresh mint",tokenNum,rewardTraitID);
    }

    function expectedID(uint32 communityId, uint32 tokenNum, uint16 traitID, uint256 value) external view returns(uint256) {
        string memory traitRegistryName = string.concat("TRAIT_REGISTRY_",uint256(tokenNum).toString());
        (CommunityRegistry myCommunityRegistry, ) = findMyTraitRegistry(communityId,traitRegistryName,false);
        IUtilityTraitCoupon iutc = IUtilityTraitCoupon(myCommunityRegistry.getRegistryAddress("UTILITY_TRAIT_COUPON"));
        require(address(iutc).code.length > 0,"CouponMinter : no Utility Trait Coupon found");
        return iutc.makeId(tokenNum,traitID,value);
    }

    function tokeniseMyTrait(
        tokenInfo calldata ti
    ) external currentTTF {
        
        bytes memory data;
        string memory tokenName = string.concat("TOKEN_",uint256(ti.tokenNumber).toString());
        string memory traitRegistryName = string.concat("TRAIT_REGISTRY_",uint256(ti.tokenNumber).toString());

        (CommunityRegistry myCommunityRegistry, address traitRegAddress) = findMyTraitRegistry(ti.communityId,traitRegistryName,false);
        address tokenAddress = myCommunityRegistry.getRegistryAddress(tokenName);

        require(IERC721(tokenAddress).ownerOf(ti.tokenId)==msg.sender,"CouponMinter : You do not own this token");
        IECRegistry tr = IECRegistry(traitRegAddress);
        IECRegistry.traitStruct memory ts = tr.getTrait(ti.traitNumber);
        require (ts.storageImplementer != address(0),"CouponMinter : trait does not exist") ;
        require (GenericTrait(ts.storageImplementer).movement_permission() == uint8(MovementPermission.OPEN),"CouponMinter : trait cannot be removed");
        require (GenericTrait(ts.storageImplementer).hasTrait(ti.tokenId),"CouponMinter : Trait not on token");
        uint32[] memory tokenIds = new uint32[](1);
        tokenIds[0] = ti.tokenId;
        if (GenericTrait(ts.storageImplementer).isInitialized(ti.tokenId)) {
            data =  GenericTrait(ts.storageImplementer).getData(ti.tokenId);
        }
        GenericTrait(ts.storageImplementer).removeTrait(tokenIds);

        IUtilityTraitCoupon(
            myCommunityRegistry.getRegistryAddress(UTILITY_TRAIT_COUPON)
        ).mint(ti.tokenNumber,ti.traitNumber,msg.sender,1,data);
        //console.log("tokenize mint",ti.tokenNumber,ti.traitNumber,data.length);
    }

    function _getId(uint256 tokenId) internal pure returns (uint32 tokenNumber, uint16 traitNumber, uint256 pointer) {
        traitNumber = uint16(
            tokenId & 0xffff
        );
        tokenNumber = uint32(
            (tokenId >> 16) & 0xffffffff
        );
        pointer = tokenId >> 16+32;
    }

    struct tokenStruct {
        uint32 tokenNumber;
        uint16 traitNumber;
        uint256 pointer;
    }

    function _getIdStruct(uint256 tokenId) internal view returns (tokenStruct memory) {
        (
            uint32 tokenNumber,
            uint16 traitNumber,
            uint256 pointer
        ) = _getId(tokenId);
        return tokenStruct(tokenNumber,traitNumber,pointer);
    }

    function getIds(uint256[] calldata tokenIds) external view returns(tokenStruct[] memory result) {
        result = new tokenStruct[](tokenIds.length);
        for (uint j = 0; j < tokenIds.length; j++) {
            result[j] = _getIdStruct(tokenIds[j]);
        }
        return result;
    }

    function getId(uint256 tokenId) external pure returns (uint32 tokenNumber, uint16 traitNumber, uint256 pointer) {
        return _getId(tokenId);
    }

    function applyTraitToNFT(address from, uint256 tokenId,  uint32 destinationTokenId) internal {
        uint32 communityId = IUtilityTraitCoupon(msg.sender).communityId();
        address community1155     = getCommunityRegistry(communityId).getRegistryAddress(UTILITY_TRAIT_COUPON);
        require(
            msg.sender == community1155,
            "CouponMinter : Invalid 1155"
        );

        (
            uint32 tokenNumber, 
            uint16 traitNumber, 
            uint256 value
        ) = _getId(tokenId);
        bytes memory data = IUtilityTraitCoupon(msg.sender).getData(tokenNumber, traitNumber, value);

        (address tokenAddress, address traitRegAddress)= getTraitRegAndTokenAddress(communityId,tokenNumber);
        // check for NFT owned accounts
        // address account = ITokenAccountRegistry(galaxisRegistry.getRegistryAddress(TOKEN_ACCOUNT_REGISTRY)).account(communityId,tokenNumber,destinationTokenId);
        // if (account != from) { // sent by EOA
            require (
                IERC721(tokenAddress).ownerOf(destinationTokenId) == from,
                "CouponMinter : You do not own this token"
            );
        // }
        IECRegistry tr = IECRegistry(traitRegAddress);
        IECRegistry.traitStruct memory ts = tr.getTrait(traitNumber);
        if (value == 0) {
            uint32[] memory ids = new uint32[](1);
            ids[0] = destinationTokenId;
            GenericTrait(ts.storageImplementer).addTrait(ids); // will set as royalty unpaid if owner changes
        } else {
            bytes memory _data_ = IUtilityTraitCoupon(msg.sender).getData(tokenNumber,traitNumber,value);
            GenericTrait(ts.storageImplementer).setData(destinationTokenId,data);

        }
        IUtilityTraitCoupon(msg.sender).burn(tokenId,1);
    }

    function getTraitRegAndTokenAddress(uint32 communityId, uint32 tokenNumber) internal view returns (address,address) {
        string memory tokenName = string.concat("TOKEN_",uint256(tokenNumber).toString());
        string memory traitRegistryName = string.concat("TRAIT_REGISTRY_",uint256(tokenNumber).toString());
        (CommunityRegistry myCommunityRegistry, address traitRegAddress) = findMyTraitRegistry(communityId,traitRegistryName,false);
        return  (myCommunityRegistry.getRegistryAddress(tokenName),traitRegAddress);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data // <- contains <tokenId>
    ) external returns (bytes4){
        // require(operator == msg.sender,"CouponMinter : no operator allowed");
        require(data.length == 4 ,"CouponMinter : invalid tokenId");
        require(value == 1, "CouponMinter : Can only redeem one!");
        uint32 destinationTokenId = uint32(bytes4(data[0:4]));
        applyTraitToNFT(from, id, destinationTokenId) ;
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4){ 
        //require(operator == from,"CouponMinter : no operator allowed");
        require(data.length == 4,"CouponMinter : invalid data");
        uint32 destinationTokenId = uint32(bytes4(data[0:4]));
        for (uint256 idpos = 0; idpos < ids.length; idpos++) {
            uint256 value = values[idpos];
            require(value == 1, "CouponMinter : Can only redeem one per tokenId!");
            applyTraitToNFT(from, ids[idpos], destinationTokenId) ;
        }
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function getCommunityRegistry(uint32 _communityId) internal view returns(CommunityRegistry) {
        (,address crAddr,) = COMMUNITY_LIST.communities(_communityId);
        if (crAddr.code.length == 0) {
            revert CommunityRegistryNotLoaded(crAddr);
        }
        return CommunityRegistry(crAddr);
    }

    function findMyTraitRegistry(uint32 projectID,  string memory traitRegistryName,bool mustBeAdmin ) internal view returns (CommunityRegistry myCommunityRegistry,address traitRegAddress) {
        myCommunityRegistry = getCommunityRegistry(projectID);
        if (mustBeAdmin){
            require(myCommunityRegistry.isUserCommunityAdmin(COUPON_MINTER_ADMIN,msg.sender),"CouponMinter : unauthorised");
        }
        traitRegAddress = myCommunityRegistry.getRegistryAddress(traitRegistryName);
        require(traitRegAddress != address(0),"Trait Registry not set in community registry");
        if (traitRegAddress.code.length == 0) {
            revert TraitRegistryNotLoaded(projectID,traitRegistryName,address(myCommunityRegistry));
        }
    }

    modifier currentTTF() {
        require(galaxisRegistry.getRegistryAddress(TRAIT_COUPON_MINTER)==address(this),"invalid TRAIT COUPON MINTER");
        _;
    }


    modifier onlyCommunityAdmins(uint32 _communityId) {
    (,address crAddr,) = COMMUNITY_LIST.communities(_communityId);
        if (crAddr.code.length == 0) {
            revert CommunityRegistryNotLoaded(crAddr);
        }
        CommunityRegistry myCommunityRegistry = CommunityRegistry(crAddr);
        require(
            myCommunityRegistry.isUserCommunityAdmin(COUPON_MINTER_ADMIN,msg.sender) ||
            myCommunityRegistry.hasRole(COUPON_MINTER_ADMIN,msg.sender) ,
            "CouponMinter : unauthorised");
        _;
    }



}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

/// Stickerbook using both Utility Traits AND Visual Traits

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../Traits/Registry/GTRegistry.sol";
import "../Traits/Implementers/Generic/GenericTrait.sol";
import "../Traits/VisualTraitRegistry/VisualTraitRegistry.sol";
import "../Traits/interfaces/IRegistryConsumer.sol";
import "../@galaxis/registries/contracts/IRegistry.sol";
import "../@galaxis/registries/contracts/ICommunityList.sol";
import "../@galaxis/registries/contracts/CommunityRegistry.sol";

import "./SuperStickerbookData.sol";
import "./SuperStickerbookCollection.sol";

//import "hardhat/console.sol";


contract SuperStickerbookUtils is SuperStickerbookData {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 constant          public STICKERBOOK_ADMIN = keccak256("STICKERBOOK_ADMIN");

    // stickerbook stuff

    function libraryVersion() public view virtual returns (uint256) {
        return 20231127;    
    }

    error RegistryNotLoaded();
    error StickerBookDoesNotExist(string name);
    error CriteriaNotMet(string name,uint256 tokenId,string criteria_name,uint256 actual, uint256 alternative_value_bitset);
    error SBContractAlreadyInitialized();
    error TraitImplementerNotSet(string name);
    error InvalidStickerNumber();

    fallback(bytes calldata b) external returns (bytes memory) {

        address dest = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F).getRegistryAddress("STICKERBOOK_DATA_VIEWER");
        require(dest != address(0),"StickerbookUtils : bad function");
        (bool success, bytes memory returnedData) = dest.delegatecall(b);
        if (!success) {
            assembly {
                revert(add(returnedData,32),mload(returnedData))
            }
        }
        return returnedData;
    }

 

    function getStickerBookID(string memory name) internal view returns (uint16) {
        uint16 stickerBookID = ds().stickerbooks[name];
        if (stickerBookID == 0) {
            revert StickerBookDoesNotExist(name);
        }
        return stickerBookID;
    }


    function eligible(string memory name, uint16 tokenId) external view returns (uint256[] memory) {
        uint16[] memory tokenIdA = new uint16[](1);
        tokenIdA[0] = tokenId;
        if (! (getBadges(name,tokenIdA)[0])) return new uint256[](0); // token does not have badge
        uint16 stickerBookID = getStickerBookID(name);
        stickerBookInfo memory st= getStickerbookData(stickerBookID);
        
        uint256[] memory temp = new uint256[](st.stickerCount);
        uint256 pointer;
 
        for (uint16 position = 0; position < st.stickerCount; position++) {
            if (meetsCriteria(name,tokenId,position)) {
                temp[pointer++] = position;
            }
        }
        if (pointer == st.stickerCount) return temp;
        
        uint256[] memory result = new uint256[](pointer);
        for (uint256 ptr = 0; ptr < pointer; ptr++) {
            result[ptr] = temp[ptr];
        }
        return result; 
    }

    // TODO : you give me sticker and position plus a number of tokenIds, I tell you which ones work
    function satisfies(string memory name, uint16 position, uint16[] memory tokenIds) external view returns (bool[] memory) {
        bool[] memory badges  = getBadges(name,tokenIds);
        bool[] memory res = new bool[](tokenIds.length);
        for (uint256 pos = 0; pos < tokenIds.length; pos++) {
            res[pos] = 
                meetsCriteria(name, tokenIds[pos],position) && badges[pos];
        }
        return res;
    }

    function getBadges(string memory name,uint16[] memory tokenIds) internal view returns(bool[] memory result) {
        GTRegistry  reg = ds().reg;
        result = new bool[](tokenIds.length);
        uint16 stickerBookID = getStickerBookID(name);
        stickerBookInfo memory st = getStickerbookData(stickerBookID);
        if (st.clearBadge != marking.CLEAR_BADGE) {
            for(uint i = 0; i < tokenIds.length; i++) {
                result[i] = true;
            }
            return result;
        }
        require(st.traitToClear < reg.traitCount(),"Stickerbook : Invalid trait number");
        //(,,,,,address storageImplementer,,) = reg.traits(st.traitToClear);
        GenericTrait iut = ds()._implementers[st.traitToClear];
        require(address(iut) != address(0),"Stickerbook : No storage implementer found") ;
        for(uint j = 0; j < tokenIds.length; j++) {
            result[j] = iut.hasTrait(tokenIds[j]);
        }
        return result;
    }

    function meetsCriteria(string memory name, uint16 tokenId, uint16 pos) public view returns (bool) {
        uint16 stickerBookID = getStickerBookID(name);
        uint256 numberOfCriteria = ds().stickers[stickerBookID][pos].length ;//ds().numberOfStickers(stickerBookID,pos);
        for (uint256 criteria = 0; criteria < numberOfCriteria; criteria++) {
            sticker storage st = ds().stickers[stickerBookID][pos].data[criteria];

            GenericTrait imp = ds()._implementers[st.traitID];

            if (address(imp) == address(0)) {
                revert TraitImplementerNotSet(st.name);
            }

            uint256 traitNum;
            if (st.visual == stickerType.VISUAL_TRAIT) {
                VisualTraitRegistry  vtr = VisualTraitRegistry(address(imp));
                traitNum = vtr.getValue(uint16(tokenId),st.side, st.layer); // get the value of that trait for this nft / tokenID

            } else if (st.visual == stickerType.UTILITY_TRAIT){ 
                traitNum = imp.hasTrait(tokenId) ? 1 : 0; 
            }
            
            if (!st.alternative_values.contains(traitNum)) {
                return false;
            }
        }
        return true;
    }


    function getStickers(string memory stickerBookName,uint16 stickerPosition) external view returns (stickerOutput[] memory response) {
        uint16 stickerBookID = getStickerBookID(stickerBookName);
        uint256 count  = ds().stickerBookData[stickerBookID].stickerCount;        
        if (stickerPosition >= count) revert InvalidStickerNumber();
        uint256 len = ds().stickers[stickerBookID][stickerPosition].length;
        response = new stickerOutput[](len);
        for (uint pos = 0; pos < len; pos++) {
            response[pos] = stickerToStickerOutput(
                ds().stickers[stickerBookID][stickerPosition].data[pos]
            );
        }
    }

    function stickerToStickerOutput(
        sticker storage stk
    ) internal view returns (stickerOutput memory response) {
            response.name = stk.name;
            response.traitID = stk.traitID;
            response.visual = stk.visual;
            response.side = stk.side;
            response.layer = stk.layer;
            response.nft_address = stk.nft_address;
            response.alternative_values = stk.alternative_values.values();
    }



    function getStickerbookData(uint16 stickerBookId) internal view returns (stickerBookInfo memory st) {
        return ds().stickerBookData[stickerBookId];
    }


    function isStickerbookActive(string calldata name) external view returns (bool) {
        uint16 stickerBookId = getStickerBookID(name);
        stickerBookInfo memory st = getStickerbookData(stickerBookId);
        if (! st.active) return false;
        if (st.maxRedemptions == 0) return true;
        return (st.maxRedemptions > st.numberRedeemed);
    }

    function getStickerBookData(string calldata name) external view returns (fullStickerBookInfo memory fsbd) {
        
        uint16 id = getStickerBookID(name);
        return _getStickerbookData(id);
    }

    function _getStickerbookData(uint16 id) internal view returns (fullStickerBookInfo memory fsbd) {
        // twice to remove stack too deep errors !!!
        stickerBookInfo memory st = getStickerbookData(id);
        
        fsbd.name = st.name;
        fsbd.stickerBookId = st.stickerBookId;
        fsbd.active = st.active;
        fsbd.maxRedemptions = st.maxRedemptions;
        fsbd.uri = st.uri;
        fsbd.numberRedeemed = st.numberRedeemed;
        fsbd.clearBadge = st.clearBadge;
        fsbd.traitToClear = st.traitToClear;
        fsbd.ipfsHash = st.ipfsHash;

        Extra memory ex =  ds().extraInfo[id];

        fsbd.acceptsJoker = ex.acceptsJoker;
        fsbd.jokerID = ex.jokerID;
        fsbd.rewardTraitID = ex.rewardTraitID;
        fsbd.rewardType = ex.rewardType;
        fsbd.nftToMint = ex.nftToMint;
        
        fsbd.stickers = new stickerOutput[][](st.stickerCount);
        for (uint16 j = 0; j < st.stickerCount; j++) {
            uint256 len = ds().stickers[fsbd.stickerBookId][j].length;
            fsbd.stickers[j] = new stickerOutput[](len);
            for (uint k = 0; k < len; k++) {
                fsbd.stickers[j][k] = stickerToStickerOutput( ds().stickers[fsbd.stickerBookId][j].data[k]);
            }
        }
        fsbd.conditions = new conditionOutput[](st.conditionalCountCounter);
        for (uint16 j = 0; j < st.conditionalCountCounter; j++) {
            fsbd.conditions[j].counter = ds().conditionalCount[id][j];
            uint256 len = ds().conditionalStickers[fsbd.stickerBookId][j].length;
            fsbd.conditions[j].stix = new stickerOutput[](len);
            for (uint k = 0; k < len; k++) {
                fsbd.conditions[j].stix[k] = stickerToStickerOutput(ds().conditionalStickers[fsbd.stickerBookId][j].data[k]);
            }
        }
    }

    function getAllStickerbookData() external view returns (fullStickerBookInfo[] memory fullData) {
        //console.log("getAllStickerbookData");
        uint16 num_sb = _numberOfStickerbooks();
        //console.log(num_sb,"stickerbooks in contract");
        fullData = new fullStickerBookInfo[](num_sb);
        for (uint16 sb = 0; sb < num_sb; sb++) {
            fullData[sb] = _getStickerbookData(sb+1);
        }
    }

    function _numberOfStickerbooks() internal view returns (uint16) {
        return ds().nextBook;
    }

    function checkConditional(uint16 stickerBookID, uint16 pos, uint32 tokenId) external view returns (bool) {
        return _checkConditional(stickerBookID,pos,tokenId);
    }
    
    function _checkConditional(uint16 stickerBookID, uint16 pos, uint32 tokenId) internal view returns (bool) 
    {
        uint256 numberOfCriteria = ds().conditionalStickers[stickerBookID][pos].length;
        for (uint256 criteria = 0; criteria < numberOfCriteria; criteria++) {
            sticker storage stc = ds().conditionalStickers[stickerBookID][pos].data[criteria];
            
            GenericTrait imp = ds()._implementers[stc.traitID];

            if (address(imp) == address(0)) {
                revert TraitImplementerNotSet(stc.name);
            }
            
            uint256 traitNum;
            if (stc.visual == stickerType.VISUAL_TRAIT) {
                VisualTraitRegistry  vtr = VisualTraitRegistry(address(imp));
                traitNum = vtr.getValue(uint16(tokenId),stc.side, stc.layer); // get the value of that trait for this nft / tokenID

            } else if (stc.visual == stickerType.UTILITY_TRAIT){ 
                traitNum = imp.hasTrait(tokenId) ? 1 : 0; 
            }
            
            if (!stc.alternative_values.contains(traitNum)) {
                return false;
            }
        }
        return true;
    }


    function anyJokers(uint32[] calldata tokenIds, uint16 stickerBookID) public view returns (bool[] memory result) {
        result = new bool[](tokenIds.length);
        Extra memory ex = ds().extraInfo[stickerBookID];
        if (!ex.acceptsJoker) return result; // all false
        
        GenericTrait imp = ds()._implementers[ex.jokerID];
        GTRegistry reg = ds().reg;
        if (address(imp) == address(0)) {
            // get it from reg
            (,,,,,address ia,,) = reg.traits(ex.jokerID);
            if (ia == address(0)) {
                ia = address(reg);
            }
            imp = GenericTrait(ia);
        }
        for (uint j = 0; j < tokenIds.length; j++) {
            result[j] = imp.hasTrait(tokenIds[j]);
        }
        return result;
    }

    function checkConditionalsForSet(uint16 stickerBookID, uint32[] memory tokenIds) external view returns (bool result,bool[] memory details) {
        stickerBookInfo memory st= getStickerbookData(stickerBookID);
        details = new bool[](st.conditionalCountCounter);
        uint16 count = st.conditionalCountCounter;
        result = true;
        for (uint16 cpos = 0; cpos < count; cpos++) {
            uint8 conditionalCounter = 0;
            for (uint16 pos = 0; pos < tokenIds.length; pos++) {
                if (_checkConditional(stickerBookID,cpos,tokenIds[pos])) conditionalCounter++;
            }
            uint8 required = ds().conditionalCount[stickerBookID][cpos];
            if(conditionalCounter < required) {
                result = false;
            } else {
                details[cpos] = true;
            }
        }
    }

}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../interfaces/IRegistryConsumer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// import "hardhat/console.sol";

contract GTRegistry is Ownable {

    function version() public pure virtual returns (uint256) {
        return 20230903;
    }

    bytes32                 public constant TRAIT_REGISTRY_ADMIN = keccak256("TRAIT_REGISTRY_ADMIN");
    bytes32                 public constant TRAIT_DROP_ADMIN     = keccak256("TRAIT_DROP_ADMIN");

    IRegistryConsumer       public constant GalaxisRegistry      = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
    CommunityRegistry       public          myCommunityRegistry;
    uint32                  public          tokenNumber;
    string                  public          TOKEN_KEY;
    bool                                    initialised;

    struct traitStruct {
        uint16  id;
        uint8   traitType;              
        
        // 0 normal (1bit), 1 range, 2 inverted range, >=3 with storageImplementer
        
        // internal 
        // - 0 for normal
        // - 1 for inverted
        // - 2 for inverted range
        // external 
        // - 3 Physical redeemables
        // - 4 Appointment
        // - 5 Autograph
        // 
        // - 100 uint8 values,
        // - 101 uint256 values
        // - 102 bytes32,
        // - 103 string
        // - 104 visual traits implementer

        uint16  start;                  // Range start for type 1/2 traits               
        uint16  end;                    // Range end for type 1/2 traits               
        bool    enabled;                // Frontend is responsible to hide disabled traits
        address storageImplementer;     // address of the smart contract that will implement the storage for the trait
        string  ipfsHash;               // IPFS address to store trait data (icon, etc.)
        string  name;
    }

    uint16 public traitCount;
    mapping(uint16 => traitStruct) public traits;


    // trait controller access designates sub contracts that can affect 1 or more traits
    mapping(uint16 => address ) public traitControllerById;
    mapping(address => uint16 ) public traitControllerByAddress;
    uint16 public traitControllerCount = 0;
    mapping(address => mapping(uint8 => uint8) ) public traitControllerAccess;
    mapping( uint8 => address ) public defaultTraitControllerAddressByType;

    /*
    *   Events
    */
    event traitControllerEvent(address _address);

    // Traits master data change
    event newTraitMasterEvent(uint16 indexed _id, string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end);
    event updateTraitMasterEvent(uint16 indexed _id, string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end);

    constructor () {
        initialised = true;                 // GOLDEN protection
    }

    function init(uint32  _communityId, uint32  _tokenNum, address _owner) external {
        _init(_communityId, _tokenNum, _owner);
    }

    function _init(uint32  _communityId, uint32  _tokenNum, address _owner) internal virtual {
        require(!initialised,"TraitRegistry: Already initialised");
        initialised = true;

        // Needed to handle owner behind proxy
        _transferOwnership(_owner);

        // Get the community_list contract
        CommunityList COMMUNITY_LIST = CommunityList(GalaxisRegistry.getRegistryAddress("COMMUNITY_LIST"));
        // Get the community data
        (,address crAddr,) = COMMUNITY_LIST.communities(_communityId);
        myCommunityRegistry = CommunityRegistry(crAddr);
        tokenNumber = _tokenNum;
        TOKEN_KEY = string(abi.encodePacked("TOKEN_", Strings.toString(tokenNumber)));


        // Only the GOLDEN version can exist without valid community ID
        address GoldenECRegistryAddr = GalaxisRegistry.getRegistryAddress("GOLDEN_TRAIT_REGISTRY");
        if( GoldenECRegistryAddr != address(this) ) {
            require(crAddr != address(0), "TraitRegistry: Invalid community ID");
        }
    }

    function getTrait(uint16 id) public view returns (traitStruct memory) {
        return traits[id];
    }

    function getTraits() public view returns (traitStruct[] memory) {
        traitStruct[] memory retval = new traitStruct[](traitCount);
        for(uint16 i = 0; i < traitCount; i++) {
            retval[i] = traits[i];
        }
        return retval;
    }

    function addTrait(
        traitStruct[] calldata _newTraits
    ) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {

        for (uint8 i = 0; i < _newTraits.length; i++) {

            uint16 newTraitId = traitCount++;
            traitStruct storage newT = traits[newTraitId];
            newT.id =           newTraitId;
            newT.name =         _newTraits[i].name;
            newT.traitType =    _newTraits[i].traitType;
            newT.start =        _newTraits[i].start;
            newT.end =          _newTraits[i].end;
            newT.enabled =      _newTraits[i].enabled;
            newT.ipfsHash =     _newTraits[i].ipfsHash;
            newT.storageImplementer = _newTraits[i].storageImplementer;

            emit newTraitMasterEvent(newTraitId, newT.name, newT.storageImplementer, newT.traitType, newT.start, newT.end );
        }
    }

    function updateTrait(
        uint16 _index,
        string memory _name,
        address _storageImplementer,
        uint8   _traitType,
        uint16  _start,
        uint16  _end,
        bool    _enabled,
        string memory _ipfsHash
    ) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        traits[_index].name = _name;
        traits[_index].storageImplementer = _storageImplementer;
        traits[_index].ipfsHash = _ipfsHash;
        traits[_index].enabled = _enabled;
        traits[_index].traitType = _traitType;
        traits[_index].start = _start;
        traits[_index].end = _end;

        emit updateTraitMasterEvent(traits[_index].id, _name, _storageImplementer, _traitType, _start, _end);
    }

    function getTraitControllerAccessData(address _addr) public view returns (uint8[] memory) {
        uint16 _returnCount = getByteCountToStoreTraitData();
        uint8[] memory retValues = new uint8[](_returnCount);
        for(uint8 i = 0; i < _returnCount; i++) {
            retValues[i] = traitControllerAccess[_addr][i];
        }
        return retValues;
    }

    function getByteCountToStoreTraitData() internal view returns (uint16) {
        uint16 _returnCount = traitCount/8;
        if(_returnCount * 8 < traitCount) {
            _returnCount++;
        }
        return _returnCount;
    }

    function getByteAndBit(uint16 _offset) public pure returns (uint16 _byte, uint8 _bit)
    {
        // find byte storig our bit
        _byte = uint16(_offset / 8);
        _bit = uint8(_offset - _byte * 8);
    }

    function getImplementer(uint16 traitID) public view returns (address implementer)
    {
        return traits[traitID].storageImplementer;
    }


    /*
    *   Admin Stuff
    */

    function setDefaultTraitControllerType(address _addr, uint8 _traitType) external onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        defaultTraitControllerAddressByType[_traitType] = _addr;
        emit traitControllerEvent(_addr);
    }

    function getDefaultTraitControllerByType(uint8 _traitType) external view returns (address) {
        return defaultTraitControllerAddressByType[_traitType];
    }

    /*
    *   Trait Controllers
    */

    function indexTraitController(address _addr) internal {
        if(traitControllerByAddress[_addr] == 0) {
            uint16 controllerId = ++traitControllerCount;
            traitControllerByAddress[_addr] = controllerId;
            traitControllerById[controllerId] = _addr;
        }
    }

    function setTraitControllerAccessData(address _addr, uint8[] calldata _data) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        indexTraitController(_addr);
        for (uint8 i = 0; i < _data.length; i++) {
            traitControllerAccess[_addr][i] = _data[i];
        }
        emit traitControllerEvent(_addr);
    }

    function setTraitControllerAccess(address _addr, uint16 traitID, bool _value) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        indexTraitController(_addr);
        if(_addr != address(0)) {
            (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
            if(_value) {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] | 2**bitPos);
            } else {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] & ~(2**bitPos));
            }
        }
        emit traitControllerEvent(_addr);
    }
 
    function addressCanModifyTrait(address _addr, uint16 traitID) public view returns (bool result) {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
        return hasRole(TRAIT_DROP_ADMIN, _addr) || _addr == owner() || traitControllerAccess[_addr][uint8(byteNum)] & (0x01 * 2**bitPos) != 0;
    }

    function addressCanModifyTraits(address _addr, uint16[] memory traitIDs) public view returns (bool result) {
        for(uint16 i = 0; i < traitIDs.length; i++) {
            if(!addressCanModifyTrait(_addr, traitIDs[i])) {
                return false;
            }
        }
        return true;
    }

    modifier onlyAllowed(bytes32 role) { 
        require(isAllowed(role, msg.sender), "TraitRegistry: Unauthorised");
        _;
    }

    function isAllowed(bytes32 role, address user) public view returns (bool) {
        return( user == owner() || hasRole(role, user));
    }

    function hasRole(bytes32 key, address user) public view returns (bool) {
        return myCommunityRegistry.hasRole(key, user);
    }

    modifier onlyTraitController(uint16 traitID) {
        require(
            addressCanModifyTrait(msg.sender, traitID),
            "TraitRegistry: Not Authorised"
        );
        _;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRegistryConsumer {

    function getRegistryAddress(string memory key) external view returns (address) ;

    function getRegistryBool(string memory key) external view returns (bool);

    function getRegistryUINT(string memory key) external view returns (uint256) ;

    function getRegistryString(string memory key) external view returns (string memory) ;

    function isAdmin(address user) external view returns (bool) ;

    function isAppAdmin(address app, address user) external view returns (bool);

}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IECRegistry.sol";

contract VisualTraitRegistry {

    function version() public pure virtual returns (uint256) {
        return 20230909;
    }

    bool                            initialised;
    uint16      public              traitId;
    IECRegistry public              ECRegistry;


    struct definition {
        uint8       len;
        string      name;
    }

    struct field {
        uint8       start;
        uint8       len;
        string      name;
    }

    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");
    mapping(uint8   => mapping(uint8 => field))     public visualTraits;
    mapping(uint8   => mapping(string  => uint8))   public visualTraitPositions;

    mapping(uint8   => mapping(uint8 => mapping(uint256 => string))) public layerPointers;

    mapping(uint8 => string)                        public traitSetNames;
    mapping(uint8 => mapping(uint16 => uint256))    public visualTraitData;
    mapping(uint8 => uint256)                       public traitInfoLength; // number of bits in a side's traits
    //mapping(uint8 => uint16)                        public wordCount;
    //mapping(uint8 => uint16)                        public numberOfTokens;
    mapping(uint8 =>uint256)                        public numberOfTraits; // numberOfLayers
    uint8                                           public numberOfSides;

    mapping(uint8 => uint16)                        public maxUsedIndex;
    mapping(uint8 => uint32)                        public maxTokenID;

    event updateTraitEvent(uint8 _side, uint16 indexed _tokenId,  uint256 _newData, uint8 dataLength);
    event TraitsUpdated(uint8 sideID, uint32 tokenId, uint256 newData, uint256 oldData);
    event WordFound(uint8 sideID,uint256 nwordPos,uint256 answer);
    event WordUpdated(uint8 sideID,uint256 wordPos,uint256 answer);


    modifier onlyAllowed() { // commented out for easy testing
        require(
            ECRegistry.addressCanModifyTrait(msg.sender, traitId),
            "Not Authorised" 
        );
        _;
    }

    constructor() {
        _init(address(0),42);
    }

    function init(address _registry, uint16 _traitId) external {
        _init(_registry,_traitId);
    }

    function _init(address _registry, uint16 _traitId) internal {
        require(!initialised,"VisualTraitRegistry: Already initialised");
        initialised = true;
        traitId = _traitId;
        ECRegistry = IECRegistry(_registry);
    }

    function createTraitSet(string calldata traitSetName, definition[] calldata traitInfo) external  onlyAllowed {
        uint8 _newTraitSet = numberOfSides++;
        traitSetNames[_newTraitSet] = traitSetName;
        uint8 start;
        for (uint8 pos = 0; pos < traitInfo.length; pos++) {
            visualTraitPositions[_newTraitSet][traitInfo[pos].name] = pos;
            visualTraits[_newTraitSet][pos] = field(
                start,
                traitInfo[pos].len,
                traitInfo[pos].name
            );
            start += traitInfo[pos].len;
        }
        numberOfTraits[_newTraitSet] = traitInfo.length;
        traitInfoLength[_newTraitSet] = start;
    }

    function setTraitsByRandomWords(uint8 sideID, uint16[] calldata indexes, uint256[] calldata values, uint32 _maxTokenID)  external onlyAllowed  {
        require(indexes.length == values.length,"arrays are of unequal length");
        for (uint i = 0; i < indexes.length; i++) {
            visualTraitData[sideID][indexes[i]] = values[i];
        }

        // assumes ASC ordering of indexes
        if(indexes[indexes.length-1] > maxUsedIndex[sideID]) {
             maxUsedIndex[sideID] = indexes[indexes.length-1];
        }
        if (maxTokenID[sideID] < _maxTokenID)  maxTokenID[sideID] = _maxTokenID;
    }

    function setTraitsByRandomWordsWithMasks(uint8 sideID, uint16[] calldata indexes, uint256[] calldata values, uint256[] calldata masks, uint32 _maxTokenID)  external onlyAllowed  {
        require(indexes.length == values.length,"index & value arrays are of unequal length");
        require(indexes.length == masks.length,"index & mask arrays are of unequal length");
        for (uint i = 0; i < indexes.length; i++) {
            uint256 v1 = visualTraitData[sideID][indexes[i]] & (~masks[i]); // retain wanted data
            uint256 v2 = values[i] & masks[i];
            visualTraitData[sideID][indexes[i]] = v1 | v2;
        }

        // assumes ASC ordering of indexes
        if(indexes[indexes.length-1] > maxUsedIndex[sideID]) {
             maxUsedIndex[sideID] = indexes[indexes.length-1];
        }
        if (maxTokenID[sideID] < _maxTokenID)  maxTokenID[sideID] = _maxTokenID;
    }

    function getWholeTraitData(uint8 sideID, uint32 tokenId) external  view returns(uint256) {
        return _getWholeTraitData(sideID,tokenId);
    }

    function getBitAndWordPosition(uint8 sideID, uint32 tokenId ) public view returns (uint16 wordPos,uint256 bitPos, uint256 traitsLength) {
        return _getBitAndWordPosition(sideID,tokenId );
    }
    function _getBitAndWordPosition(uint8 sideID, uint32 tokenId ) internal view returns (uint16 wordPos,uint256 bitPos, uint256 traitsLength) {
        traitsLength = traitInfoLength[sideID];
        uint256 bitPosFromZero = uint256(tokenId) * traitsLength;
        bitPos = bitPosFromZero % 256;
        wordPos = uint16(bitPosFromZero / 256);
    }

    function _getWholeTraitData(uint8 sideID, uint32 tokenId) internal  view returns(uint256) {
        uint16 wordPos;
        uint256 traitsLength;
        uint256 bitPos;
        (wordPos,bitPos,traitsLength) = _getBitAndWordPosition(sideID,tokenId );
        if ((bitPos + traitsLength) < 256) {
            // all fits in one word
            uint256 answer = visualTraitData[sideID][wordPos];
            answer = answer  >> bitPos;
            uint256 mask   = (1 << (traitsLength)) - 1;
            return (answer & mask);
        } else {
            uint256 answer_1 = visualTraitData[sideID][wordPos] >> bitPos;
            uint256 answer_2 = visualTraitData[sideID][wordPos+1] << 256 - bitPos;
            uint256 mask_2   = (1 << (traitsLength)) - 1;
            return answer_1  + (answer_2 & mask_2);
        }
    }

    function getIndividualTraitData(uint8 sideID, uint8 layerID, uint32 tokenId) external view returns (uint256) {
        uint wtd = _getWholeTraitData(sideID,tokenId);
        uint start = visualTraits[sideID][layerID].start;
        uint len   = visualTraits[sideID][layerID].len;
        return (wtd >> start) & ((1 << len) - 1 );
    }

    function setIndividualTraitData(uint8 sideID, uint8 layerID, uint32 tokenId, uint256 newData) external onlyAllowed {
        uint oldTraitData = _getWholeTraitData(sideID,tokenId);
        uint start = visualTraits[sideID][layerID].start;
        uint len   = visualTraits[sideID][layerID].len;
        uint traitData = (oldTraitData >> start) & ((1 << len) - 1 );
        uint newTraitData = oldTraitData - (traitData << start) + (newData << start);
        _setWholeTraitData(sideID,tokenId,newTraitData,oldTraitData);
    }

    function setWholeTraitData(uint8 sideID, uint32 tokenId, uint256 newData) external onlyAllowed {
        uint oldData = _getWholeTraitData(sideID,tokenId);
        _setWholeTraitData(sideID,tokenId,newData, oldData);
    }

    function _setWholeTraitData(uint8 sideID, uint32 tokenId, uint256 newData, uint256 oldData) internal {
        uint256 traitsLength = traitInfoLength[sideID];
        uint256 bitPosFromZero = uint256(tokenId) * traitsLength;
        uint256 bitPos = bitPosFromZero % 256;
        uint16  wordPos = uint16(bitPosFromZero / 256);
        if ((bitPos + traitsLength) < 256) {
            uint256 answer = visualTraitData[sideID][wordPos];
            emit WordFound(sideID,wordPos,answer);
            answer -= oldData << bitPos;
            answer += newData << bitPos;
            visualTraitData[sideID][wordPos] = answer;
            emit WordUpdated(sideID,wordPos,answer);
        } else {
            uint256 answer_1 = visualTraitData[sideID][wordPos];
            uint256 answer_2 = visualTraitData[sideID][wordPos+1];
            emit WordFound(sideID,wordPos,answer_1);
            emit WordFound(sideID,wordPos+1,answer_2);

            answer_1 -= oldData << bitPos;
            answer_1 += newData << bitPos;

            answer_2 -= oldData >> (256 - bitPos);
            answer_2 += newData >> (256 - bitPos);

            visualTraitData[sideID][wordPos]     = answer_1;
            visualTraitData[sideID][wordPos + 1] = answer_2;
            emit WordUpdated(sideID,wordPos,answer_1);
            emit WordUpdated(sideID,wordPos+1,answer_2);
        }
        emit TraitsUpdated(sideID, tokenId, newData,  oldData);
    }

    function getTraitNames(uint8 sideID) external view returns (string[] memory) {
        uint256 numTraits = numberOfTraits[sideID];
        string[] memory response = new string[](numTraits);
        for (uint8 pos = 0; pos < numTraits; pos++) {
            response[pos] = visualTraits[sideID][pos].name;
        }
        return response;
    }

    function getValue(uint32 tokenId, uint8 sideId, uint8 layerId ) external view returns ( uint8 ) {
        uint wtd = _getWholeTraitData(sideId,tokenId);
        uint start = visualTraits[sideId][layerId].start;
        uint len   = visualTraits[sideId][layerId].len;
        return uint8((wtd >> start) & ((1 << len) - 1 ));
    }

    function getValues(uint32 tokenId, uint8 sideId ) external view returns (uint8[] memory response) {
        uint wtd = _getWholeTraitData(sideId,tokenId);
        uint nots = numberOfTraits[sideId];
        response  = new uint8[](nots);
        uint start = 0;
        for (uint8 layerId = 0; layerId < nots; layerId++) {
            uint len = visualTraits[sideId][layerId].len;
            response[layerId] = uint8((wtd >> start) & ((1 << len) - 1 ));
            start += len;
        }
        return response;
    }

    function getValues(uint32 tokenId) external view returns (uint8[][] memory response) {
        uint8 nts = numberOfSides;
        response = new uint8[][](nts);
        for (uint8 sideId = 0; sideId < nts; sideId++) {
            uint wtd = _getWholeTraitData(sideId,tokenId);
            uint numTraits = numberOfTraits[sideId];
            response[sideId] = new uint8[](numTraits);
            uint start = 0;
            for (uint8 layerId = 0; layerId < numTraits; layerId++) {
                uint len = visualTraits[sideId][layerId].len;
                response[sideId][layerId] = uint8((wtd >> start) & ((1 << len) - 1 ));
                start += len;
            }
        }
        return response;
    }

    function getValues(uint32[] calldata tokenIds) external view returns (uint8[][][] memory response) {
        uint8 _numberOfSides = numberOfSides;
        response = new uint8[][][](tokenIds.length);
        for (uint tokenPos = 0; tokenPos < tokenIds.length; tokenPos++){
            uint32 tokenId = tokenIds[tokenPos];
            response[tokenPos] = new uint8[][](_numberOfSides);
            for (uint8 sideId = 0; sideId < _numberOfSides; sideId++) {
                uint wtd = _getWholeTraitData(sideId,tokenId);
                uint numTraits = numberOfTraits[sideId];
                response[tokenPos][sideId] = new uint8[](numTraits);
                uint start = 0;
                for (uint8 layerId = 0; layerId < numTraits; layerId++) {
                    uint len = visualTraits[sideId][layerId].len;
                    response[tokenPos][sideId][layerId] = uint8((wtd >> start) & ((1 << len) - 1 ));
                    start += len;
                }
            }
        }
        return response;
    }

    function getDataStream(uint8 side, uint16 start, uint16 len) external view returns (uint256[] memory data) {
        // check not over end of data
        if (start > maxUsedIndex[side]) {
            return data;
        }
        uint16 count;
        uint16 wCount = maxUsedIndex[side]+1;
        if (start+len < wCount) { // or <=
            count = wCount - start + len;
        } else {
            count = len;
        }
        data = new uint256[](len);
        uint16 wordPos = start;        
        for (uint16 pos = 0; pos < count; pos++) {
            data[pos] = visualTraitData[side][wordPos++];
        }
    }

    function getRandomDataStream(uint8 side, uint16[] calldata positions) external view returns (uint256[] memory data) {
        data = new uint256[](positions.length);
        for (uint j = 0; j < positions.length; j++) {
            data[j] = visualTraitData[side][positions[j]];
        }
    }

    function getAllMetadata() internal view returns (string[] memory sideNames, field[][] memory result) {
        uint8 _numberOfSides = numberOfSides;
        result = new field[][](_numberOfSides);
        sideNames = new string[](_numberOfSides);
        for (uint8 side = 0; side < _numberOfSides; side++) {
            sideNames[side] = traitSetNames[side];
            uint count = numberOfTraits[side];
            result[side] = new field[](count);
            for (uint8 traitID = 0; traitID < count; traitID++) {
                result[side][traitID] = visualTraits[side][traitID];
            }
        }
    }

    function getMaxIndexes() internal view returns (uint16[] memory result) {
        uint8 _numberOfSides = numberOfSides;
        result = new uint16[](_numberOfSides);
        for (uint8 pos = 0; pos < _numberOfSides; pos++) {
            result[pos] = maxUsedIndex[pos];
        }
    }

    function MetaData() external view returns (string[] memory sideNames, field[][] memory Fields,uint16[] memory wordCounts) {
        string[] memory sn;
        field[][] memory fa;
        (sn,fa) = getAllMetadata();
        return (sn,fa,getMaxIndexes());
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "hardhat/console.sol";

interface IGTRegistry {
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function getTraitControllerAccessData(address) external view returns (uint8[] memory);
    function myCommunityRegistry() external view returns (CommunityRegistry);
    function tokenNumber() external view returns (uint32);
    function TOKEN_KEY() external view returns (string memory);
}

enum FieldTypes {
    NONE,
    STORED_BOOL,
    STORED_UINT_8,
    STORED_UINT_16,
    STORED_UINT_32,
    STORED_UINT_64,
    STORED_UINT_128,
    STORED_UINT_256,       
    STORED_BYTES_32,       // bytes32 fixed
    STORED_STRING,         // bytes array
    STORED_BYTES,          // bytes array
    STORED_ADDRESS,
    LOGIC_BOOL,
    LOGIC_UINT_8,
    LOGIC_UINT_32,
    LOGIC_UINT_64,
    LOGIC_UINT_128,
    LOGIC_UINT_256,
    LOGIC_BYTES_32,
    LOGIC_ADDRESS
}

struct traitProperty {
    bytes32     _name;
    FieldTypes  _type;
    bytes4      _selector;
    bytes       _default;
    bool        _limited;
    uint256     _min;
    uint256     _max;
    bool        _reset_on_owner_change;
}

struct traitInfo {
    uint16 _id;
    uint16 _type;
    address _registry;
    uint256 _baseVersion;
    uint256 _version;
    traitProperty[] _schema;
    uint8   _propertyCount;
    bytes32 _app;
}

enum BitType {
    NONE,
    EXISTS,
    INITIALIZED
}

enum TraitStatus {
    NONE,
    // NOT_INITIALIZED,
    ACTIVE,
    DORMANT,
    SPENT
}

enum MovementPermission {
    NONE,
    OPEN,
    LOCKED,
    SOULBOUND,
    SOULBURN
}

enum ModifierMode {
    NONE,
    ADD,
    SET
}


contract GenericTrait {

    uint16      public     traitId;
    IGTRegistry public     GTRegistry;
    event tokenTraitChangeEvent(uint32 indexed _tokenId);

    function baseVersion() public pure returns (uint256) {
        return 2023082401;
    }

    function version() public pure virtual returns (uint256) {
        return baseVersion();
    }
    
    function TRAIT_TYPE() public pure virtual returns (uint16) {
        return 0;   // Physical redemption
    }

    function APP() public pure virtual returns (bytes32) {
        return "generic-trait";   // Physical redemption
    }

    function tellEverything() external view returns(traitInfo memory) {
        return traitInfo(
            traitId,
            TRAIT_TYPE(),
            address(GTRegistry),
            baseVersion(),
            version(),
            getSchema(),
            propertyCount,
            APP()
        );
    }

    // constructor(
    //     address _registry,
    //     uint16 _traitId,
    //     bytes[] memory _defaultPropValues
    // ) {
    //     traitId = _traitId;
    //     GTRegistry = IGTRegistry(_registry);
    //     for(uint8 i = 0; i < _defaultPropValues.length; i++) {
    //         defaultPropValues[i] = _defaultPropValues[i];
    //     }
    // }

    // cannot store as bytes unless we only allow simple types, no string / array 

    /*
        Set Properties
        Name	            type	defaults	description
        Expiration  date	date	-	        Trait can't be used after expiration date passes
        Counter	            int	    -	        Trait can only be used this many times
        Cooldown	        int	    -	        current date + cooldonw = Activation Date
        Activation Date	    date	-	        If set, trait can't be used before this date
        Modifier Lock	    bool	FALSE	    if True, Value Modifier Traits can't modify limiters
        Burn If Spent	    bool	FALSE	    If trait's status ever becomes "spent", it gets burned.
        Movement Permission	status	OPEN	    See "movement permission"
        Royalty ID	        ID	    -	        ID of the entity who is entitled to the Usage Royalty
        Royalty Amount	    int	    0	        Royalty amount in GLX


        Discount Trait Properties
        Name	        type	defaults	    Description
        Discount Type	status	PERCENTAGE	    It can be either PERCENTAGE or a fix GLX AMOUNT
        Discount Amount	int	    -	            Either 0-100 or a GLX amount
        Acceptor Type	status	MARKETPLACE	    Acceptor Type, can't be blank. Check Discounts for list.
        Max	            int	    -	            max value possible (value modifier can't go beyond)
        Modifier Lock	bool	FALSE	        If true, Value Modifier Traits have no effect


        Digital Redeemable Trait Properties
        Name	        Type	defaults	description
        Vault	        ID	    -	        The target vault of the redeemable. Can not be empty.
        Luck	        0-100	0	        If greater than zero, the Luck Process is invoked.
        Redeem Mode	    ID	    RR	        See "Redeem Modes" in the Vault page.
        Modifier Lock	bool	FALSE	    If True, Value Modifiers can't apply to this trait.


        Physical Redeemable Trait Properties
        name	    type	description
        item name	ID	    name of the item that can be redeemed


        Value Modifier Trait Properties
        name	    type	defaults	description
        Trait Type	ID	    -	        What type of trait to modify (Digital Redeemable, etc)
        Property	ID	    -	        What property of that trait to modify
        Mode	    ID	    ADD	        ADD or SET
        Value	    int	    -	        By how much

    */

    bool initialized = false;

    mapping(uint8 => traitProperty) property;
    uint8 propertyCount = 0;
    mapping(bytes32 => uint8) propertyNameToId;
    mapping(uint8 => uint8) propertyStorageMap;

    //      propId  => tokenId => ( index => value )
    mapping(uint8 => mapping( uint32 => bytes ) ) storageMapArray;
    //      tokenId => data ( except bytes / string which go into storageMapArray )
    mapping(uint32 => bytes ) storageData;

    //      propId  => tokenId => ( index => value )
    mapping(uint8 => bytes ) storageMapArrayDEFAULT;
    //      tokenId => data ( except bytes / string which go into storageMapArrayDEFAULT )

    bytes tokenDataDEFAULT;
    mapping(uint8 => bytes ) defaultPropValues;

    // we need an efficient way to activate traits at mint or by using dropper
    // to achieve this we set 1 bit per tokenId
    // 

    mapping(uint32 => uint8 )    public existsData;
    mapping(uint32 => uint8 )    initializedData;

    // indexed props
    bool    public modifier_lock;
    uint8   public movement_permission;

    bytes32 constant constant_royalty_id_key = hex"726f79616c74795f696400000000000000000000000000000000000000000000";
    bytes32 constant constant_royalty_amount_key = hex"726f79616c74795f616d6f756e74000000000000000000000000000000000000";
    bytes32 constant constant_owner_stored_key = hex"6f776e65725f73746f7265640000000000000000000000000000000000000000";

    // constructor() {
    //     init();
    // }

    function isLogicFieldType(FieldTypes _type) internal pure returns (bool) {
        if(_type == FieldTypes.LOGIC_BOOL) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_UINT_8) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_UINT_32) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_UINT_64) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_UINT_128) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_UINT_256) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_BYTES_32) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_ADDRESS) {
            return true;
        }
        return false;
    }

    function _addProperty(bytes32 _name, FieldTypes _type, bytes4 _selector) internal {
        uint8 thisId = propertyCount;

        if(propertyNameToId[_name] > 0) {
            // no duplicates
            revert();
        } else {
            propertyNameToId[_name]     = thisId;
            traitProperty storage prop = property[thisId];
            prop._name = _name;
            prop._type = _type;
            prop._selector = _selector;
            prop._default = defaultPropValues[thisId]; // _default;
            propertyCount++;
        }
    }

    function addStoredProperty(bytes32 _name, FieldTypes _type) internal {
        _addProperty(_name, _type, bytes4(0));
    }

    function addLogicProperty(bytes32 _name, FieldTypes _type, bytes4 _selector) internal {
        _addProperty(_name, _type, _selector);
    }

    function addPropertyLimits(bytes32 _name, uint256 _min, uint256 _max) internal {
        uint8 _id = propertyNameToId[_name];
        traitProperty storage thisProp = property[_id];
        require(thisProp._selector == bytes4(hex"00000000"), "Trait: Cannot set limits on Logic property");
        thisProp._limited = true;
        thisProp._min = _min;
        thisProp._max = _max;
    }

    function setPropertyResetOnOwnerChange(bytes32 _name) internal {
        uint8 _id = propertyNameToId[_name];
        traitProperty storage thisProp = property[_id];
        thisProp._reset_on_owner_change = true;
    }

    function _initStandardProps() internal {
        require(!initialized, "Trait: already initialized!");

        addLogicProperty( bytes32("exists"),              FieldTypes.LOGIC_BOOL,        bytes4(keccak256("hasTrait(uint32)")));
        addLogicProperty( bytes32("initialized"),         FieldTypes.LOGIC_BOOL,        bytes4(keccak256("isInitialized(uint32)")));
        
        // required for soulbound
        addStoredProperty(bytes32("owner_stored"),        FieldTypes.STORED_ADDRESS);
        addLogicProperty( bytes32("owner_current"),       FieldTypes.LOGIC_ADDRESS,     bytes4(keccak256("currentTokenOwnerAddress(uint32)")));


        // if true, Value Modifier Traits can't modify limiters
        addStoredProperty(bytes32("modifier_lock"),       FieldTypes.STORED_BOOL);
        addStoredProperty(bytes32("movement_permission"), FieldTypes.STORED_UINT_8);
        addStoredProperty(bytes32("activation"),          FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("cooldown"),            FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("expiration"),          FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("counter"),             FieldTypes.STORED_UINT_8);

        addStoredProperty(bytes32("royalty_id"),          FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("royalty_amount"),      FieldTypes.STORED_UINT_256);

        addLogicProperty( bytes32("status"),              FieldTypes.LOGIC_UINT_8,      bytes4(keccak256("status(uint32)")));



        // setPropertySoulbound()
            // owner_stored
            // if(_name == hex"6f776e65725f73746f7265640000000000000000000000000000000000000000") {
            //     prop._soulbound = true;
            // }


        // status change on owner_current change
        // if movement_permission == MovementPermission.SOULBOUND
        // on addTrait / setProperty / setData set owner_stored
        // 
        

        // prop reset on owner_stored
        // _reset_on_owner_change
        // addStoredProperty(bytes32("points"),              FieldTypes.STORED_UINT_256);
        // setPropertyResetOnOwnerChange(bytes32("points"));
        // addStoredProperty(bytes32("points"),              FieldTypes.STORED_UINT_256);

        // addPropertyLimits(bytes32("cooldown"),      0,      3600 * 24);
        // addPropertyLimits(bytes32("counter"),       0,      100);
    }

    function setup(
        address _registry,
        uint16 _traitId,
        bytes[] memory _defaultPropValues
    ) virtual public {
        traitId = _traitId;
        GTRegistry = IGTRegistry(_registry);
        for(uint8 i = 0; i < _defaultPropValues.length; i++) {
            defaultPropValues[i] = _defaultPropValues[i];
        }
    }

    function init() virtual public {
        _initStandardProps();
        // custom props
        afterInit();
    }

    function getRoyaltiesForThisTraitType() internal view returns (uint256, uint256) {
        // external call to payment matrix ?
        if(initialized){}
        return (1337, 4321);
    }

    function afterInit() internal {

        // overwrite royalty_id / royalty_amount
        (uint256 royalty_id, uint256 royalty_amount) = getRoyaltiesForThisTraitType();
        for(uint8 _id = 0; _id < propertyCount; _id++) {
            traitProperty memory thisProp = property[_id];
            if(thisProp._name == constant_royalty_id_key || thisProp._name == constant_royalty_amount_key) {
                bytes memory value;
                if(thisProp._name == constant_royalty_id_key) {
                    value = abi.encode(royalty_id);
                } else if(thisProp._name == constant_royalty_amount_key) {
                    value = abi.encode(royalty_amount);
                }
                defaultPropValues[_id] = value;
                property[_id]._default = value;
            } 

            // reset default owner in case deployer wrote a different address here
            if(thisProp._name == constant_owner_stored_key ) {
                property[_id]._default = abi.encode(address(0));
            }
        }

        // index for cheaper internal logic
        modifier_lock = (uint256(bytes32(getProperty("modifier_lock", 0))) > 0 );
        movement_permission = abi.decode(getProperty("movement_permission", 0), (uint8));
        // set defaults
        tokenDataDEFAULT = getDefaultTokenDataOutput();

        initialized = true;
    }


    function getSchema() public view returns (traitProperty[] memory) {
        traitProperty[] memory myProps = new traitProperty[](propertyCount);
        for(uint8 i = 0; i < propertyCount; i++) {
            myProps[i] = property[i];
        }
        return myProps;
    }

    // function _getFieldTypeByteLenght(uint8 _id) public view returns (uint16) {
    //     traitProperty storage thisProp = property[_id];
    //     if(thisProp._type == FieldTypes.LOGIC_BOOL || thisProp._type == FieldTypes.STORED_BOOL) {
    //         return 1;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_8) {
    //         return 1;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_16) {
    //         return 2;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_32) {
    //         return 4;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_64) {
    //         return 8;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_128) {
    //         return 16;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_256) {
    //         return 32;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_STRING || thisProp._type == FieldTypes.STORED_BYTES) {
    //         // array length for strings / bytes limited to uint16.
    //         return 2;
    //     }

    //     revert("Trait: FieldType Not Implemented");
    // }

    function getOutputBufferLength(uint32 _tokenId) public view returns(uint16, uint16) {
        // abi.encode style 32 byte blocks
        // with memory pointer at location for complex types
        // pointer to length followed by records
        uint16 propCount = propertyCount;
        uint16 _length = 32 * propCount;
        uint16 complexDataOutputPtr = _length;
        bytes memory tokenData = bytes(storageData[_tokenId]);
        
        for(uint8 _id = 0; _id < propertyCount; _id++) {
            FieldTypes thisPropType = property[_id]._type;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                uint16 offset = uint16(_id) * 32;
                // console.log("getOutputBufferLength", _id, offset);
                bytes memory arrayLenB = new bytes(2);
                if(tokenData.length > 0) {
                    arrayLenB[0] = bytes1(tokenData[offset + 30]);
                    arrayLenB[1] = bytes1(tokenData[offset + 31]);
                    // each complex type adds another 32 for length 
                    // and data 32 * ceil(length/32)
                    _length+= 32 + 32 + ( 32 * ( uint16(bytes2(arrayLenB)) / 32 ) );

                } else {
                    arrayLenB[0] = 0;
                    arrayLenB[1] = 0;
                    _length+= 32;
                }
            }
        }
        return (_length, complexDataOutputPtr);
    }

    function getData(uint32[] memory _tokenIds) public view returns(bytes[] memory) {
        bytes[] memory outputs = new bytes[](_tokenIds.length);
        for(uint32 i = 0; i < _tokenIds.length; i++) {
            outputs[i] = getData(_tokenIds[i]);
        }
        return outputs;
    }

    function getDefaultTokenDataOutput() public view returns(bytes memory) {
        uint32 _tokenId = 0;
        ( uint16 _length, uint16 complexDataOutputPtr) = getOutputBufferLength(_tokenId);
        bytes memory outputBuffer = new bytes(_length);
        uint256 outputPtr;
        uint256 complexDataOutputRealPtr;
        uint256 _start = 0;

        assembly {
            // jump over length 32 byte block
            outputPtr := add(outputBuffer, 32)
            complexDataOutputRealPtr := add(outputPtr, complexDataOutputPtr)
        }

        for(uint8 _id = 0; _id < propertyCount; _id++) {
            _start+=32;

            FieldTypes thisPropType = property[_id]._type;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                bytes memory value = storageMapArrayDEFAULT[_id];
                assembly {
                    // let readptr := add(tokenData, _start)
                    // store location of data in place
                    mstore(outputPtr, complexDataOutputPtr)

                    complexDataOutputPtr := add(complexDataOutputPtr, 32)
                    let byteLength := mload(value)
                    let itemBlocks := div(byteLength, 32)
                    if lt(mul(itemBlocks, 32), byteLength ) {
                        itemBlocks := add(itemBlocks, 1)
                    }
                    // store array length
                    mstore(complexDataOutputRealPtr, byteLength)
                    complexDataOutputRealPtr:= add(complexDataOutputRealPtr, 32)
                    for { let n := 0 } lt(n, itemBlocks) { n := add(n, 1) } {
                        // store array 32 byte blocks
                        mstore(
                            complexDataOutputRealPtr, 
                            mload(
                                add(value, mul(add(n,1), 32) ) 
                            )
                        )
                        complexDataOutputRealPtr:= add(complexDataOutputRealPtr, 32)
                    }
                    complexDataOutputPtr := add(complexDataOutputPtr, mul(itemBlocks, 32))
                }

            }
            else {
                bytes32 value = bytes32(property[_id]._default);
                assembly {
                    // store empty value in place
                    mstore(outputPtr, value)
                }
            }

            assembly {
                outputPtr := add(outputPtr, 32)
            }
        }
        return outputBuffer;

    }

    function getData(uint32 _tokenId) public view returns(bytes memory) {
        uint16 _length = 0;
        uint16 complexDataOutputPtr;
        ( _length, complexDataOutputPtr) = getOutputBufferLength(_tokenId);
        bytes memory outputBuffer = new bytes(_length);
        bytes memory tokenData = storageData[_tokenId];

        if(!isInitialized(_tokenId)) {
            tokenData = tokenDataDEFAULT;
        }

        // 32 byte block contains bytes array size / length
        if(tokenData.length == 0) {
            // could simply return empty outputBuffer here..;
            tokenData = new bytes(
                uint16(propertyCount) * 32
            );
        }

        uint256 outputPtr;
        uint256 complexDataOutputRealPtr;
        uint256 _start = 0;

        assembly {
            // jump over length 32 byte block
            outputPtr := add(outputBuffer, 32)
            complexDataOutputRealPtr := add(outputPtr, complexDataOutputPtr)
        }

        for(uint8 _id = 0; _id < propertyCount; _id++) {
            _start+=32;

            FieldTypes thisPropType = property[_id]._type;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                bytes memory value = storageMapArray[_id][_tokenId];
                assembly {
                    // let readptr := add(tokenData, _start)
                    // store location of data in place
                    mstore(outputPtr, complexDataOutputPtr)

                    complexDataOutputPtr := add(complexDataOutputPtr, 32)
                    let byteLength := mload(value)
                    let itemBlocks := div(byteLength, 32)
                    if lt(mul(itemBlocks, 32), byteLength ) {
                        itemBlocks := add(itemBlocks, 1)
                    }
                    // store array length
                    mstore(complexDataOutputRealPtr, byteLength)
                    complexDataOutputRealPtr:= add(complexDataOutputRealPtr, 32)
                    for { let n := 0 } lt(n, itemBlocks) { n := add(n, 1) } {
                        // store array 32 byte blocks
                        mstore(
                            complexDataOutputRealPtr, 
                            mload(
                                add(value, mul(add(n,1), 32) ) 
                            )
                        )
                        complexDataOutputRealPtr:= add(complexDataOutputRealPtr, 32)
                    }
                    complexDataOutputPtr := add(complexDataOutputPtr, mul(itemBlocks, 32))
                }

            }
            else if(isLogicFieldType(thisPropType)) {

                callMethodAndCopyToOutputPointer(
                    property[_id]._selector, 
                    _tokenId,
                    outputPtr
                );

            } else {
                assembly {
                    // store value in place
                    mstore(outputPtr, mload(
                        add(tokenData, _start)
                    ))
                }
            }

            assembly {
                outputPtr := add(outputPtr, 32)
            }
        }
        return outputBuffer;
    }

    function callMethodAndCopyToOutputPointer(bytes4 _selector, uint32 _tokenId, uint256 outputPtr ) internal view {
        (bool success, bytes memory callResult) = address(this).staticcall(
            abi.encodeWithSelector(_selector, _tokenId)
        );
        require(success, "Trait: internal method call failed");
        // console.logBytes(callResult);
        assembly {
            // store value in place  // shift by 32 so we just get the value
            mstore(outputPtr, mload(add(callResult, 32)))
        }
    }

    /*
        should remove, gives too much power
    */
    function setData(uint32 _tokenId, bytes memory _bytesData) public onlyAllowed {
        _setData(_tokenId, _bytesData);
        
        //
        _updateCurrentOwnerInStorage(_tokenId);
    }

    function _setData(uint32 _tokenId, bytes memory _bytesData) internal {
        
        if(!hasTrait(_tokenId)) {
            // if the trait does not exist
            _tokenSetBit(_tokenId, BitType.EXISTS, true);
        }

        if(!isInitialized(_tokenId)) {
            // if the trait is not initialized
            _tokenSetBit(_tokenId, BitType.INITIALIZED, true);
        }

        uint16 _length = uint16(propertyCount) * 32;
        if(_bytesData.length < _length) {
            revert("Trait: Message not long enough");
        }

        bytes memory newTokenData = new bytes(_length);
        uint256 newTokenDataPtr;
        uint256 readPtr;
        assembly {
            // jump over length 32 byte block
            newTokenDataPtr := add(newTokenData, 32)
            readPtr := add(_bytesData, 32)
        }

        for(uint8 _id = 0; _id < propertyCount; _id++) {
            FieldTypes thisPropType = property[_id]._type;
            bytes32 fieldValue;
            assembly {
                fieldValue:= mload(readPtr)
            }

            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                // read length from offset stored in fieldValue
                bytes32 byteLength;
                uint256 complexDataPtr;
                assembly {
                    complexDataPtr:= add(
                        add(_bytesData, 32),
                        fieldValue
                    )

                    byteLength:= mload(complexDataPtr)
                    // store length
                    mstore(newTokenDataPtr, byteLength)
                }

                bytes memory propValue = new bytes(uint256(byteLength));

                assembly {
                
                    let propValuePtr := add(propValue, 32)
                    let itemBlocks := div(byteLength, 32)
                    if lt(mul(itemBlocks, 32), byteLength ) {
                        itemBlocks := add(itemBlocks, 1)
                    }

                    // store array 32 byte blocks
                    for { let n := 0 } lt(n, itemBlocks) { n := add(n, 1) } {
                        complexDataPtr:= add(complexDataPtr, 32)
                        mstore(
                            propValuePtr, 
                            mload(complexDataPtr)
                        )                        
                        propValuePtr:= add(propValuePtr, 32)
                    }

                }
                storageMapArray[_id][_tokenId] = propValue;
            
            } else if(isLogicFieldType(thisPropType)) {
                // do nothing
            } else {
                // just store fieldValue in newTokenData
                assembly {
                    mstore(newTokenDataPtr, fieldValue)
                }
            }

            assembly {
                newTokenDataPtr := add(newTokenDataPtr, 32)
                readPtr := add(readPtr, 32)
            }
        }
        storageData[_tokenId] = newTokenData;
        emit tokenTraitChangeEvent(_tokenId);
    }

    // function getPropertyOutputBufferLength(uint8 _id, FieldTypes _thisPropType, uint32 _tokenId) public view returns(uint16) {
    //     uint16 _length = 32;
    //     bytes memory tokenData = bytes(storageData[_tokenId]);
    //     if(_thisPropType == FieldTypes.STORED_STRING || _thisPropType == FieldTypes.STORED_BYTES) {
    //         uint16 offset = _id * 32;
    //         bytes memory arrayLenB = new bytes(2);
    //         if(tokenData.length > 0) {
    //             arrayLenB[0] = bytes1(tokenData[offset + 30]);
    //             arrayLenB[1] = bytes1(tokenData[offset +31]);
    //             // each complex type adds another 32 for length 
    //             // and data 32 * ceil(length/32)
    //             _length+= 32 + 32 + ( 32 * ( uint16(bytes2(arrayLenB)) / 32 ) );
    //         } else {
    //             arrayLenB[0] = 0;
    //             arrayLenB[1] = 0;
    //         }
    //     }
        
    //     return _length;
    // }

    function getProperties(uint32 _tokenId, bytes32[] memory _names) public  view returns(bytes[] memory) {
        bytes[] memory outputs = new bytes[](_names.length);
        for(uint32 i = 0; i < _names.length; i++) {
            outputs[i] = getProperty(_names[i], _tokenId);
        }
        return outputs;
    }

    function getProperty(bytes32 _name, uint32 _tokenId) public view returns (bytes memory) {
        uint8 _id = propertyNameToId[_name];
        FieldTypes thisPropType = property[_id]._type;
        if(!isInitialized(_tokenId) && !isLogicFieldType(thisPropType)) {
            // if the trait has not been initialized, and is not a method return, we return default stored data
            return property[_id]._default;
        } else {
            return _getProperty(_id, _tokenId);
        }
    }

    function _getProperty(uint8 _id, uint32 _tokenId) internal view returns (bytes memory) {
        FieldTypes thisPropType = property[_id]._type;
        bytes memory output = new bytes(32);
        uint256 outputPtr;
        assembly {
            outputPtr := add(output, 32)
        }
        if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
            output = storageMapArray[_id][_tokenId];
        }
        else if(isLogicFieldType(thisPropType)) {
            callMethodAndCopyToOutputPointer(
                property[_id]._selector, 
                _tokenId,
                outputPtr
            );
        }
        else {
            bytes memory tokenData = bytes(storageData[_tokenId]);
            // first 32 is tokenData length
            uint256 _start = 32 + 32 * uint16(_id);
            assembly {
                outputPtr := add(output, 32)
                // store value in place
                mstore(outputPtr, mload(
                        add(tokenData, _start)
                    )
                )
            }
        }
        return output; 
    }

    // function canUpdateTo(bytes32 _name, bytes memory newValue) public view returns (bool) {
    //     return true;

    //     uint8 _id = propertyNameToId[_name];
    //     traitProperty memory thisProp = property[_id];
        
    //     thisProp._limited;

    //     if(modifier_lock) {
    //         // if()
    //         return false;
    //     }
    //     return false;
    //     // 
    // }

    function setProperties(uint32 _tokenId, bytes32[] memory _names, bytes[] memory inputs) public onlyAllowed {
        _updateCurrentOwnerInStorage(_tokenId);

        for(uint8 i = 0; i < _names.length; i++) {
            bytes32 name = _names[i];
            if(name == constant_owner_stored_key) {
                revert("Trait: dissalowed! Cannot set owner_stored value!");
            }
            _setProperty(name, _tokenId, inputs[i]);
        }
    }


    function setProperty(bytes32 _name, uint32 _tokenId, bytes memory input) public onlyAllowed {
        if(_name == constant_owner_stored_key) {
            revert("Trait: dissalowed! Cannot set owner_stored value!");
        }
        _updateCurrentOwnerInStorage(_tokenId);
        _setProperty(_name, _tokenId, input);
    }

    function _updateCurrentOwnerInStorage(uint32 _tokenId) internal {
        if(movement_permission == uint8(MovementPermission.SOULBOUND)) {
            // if default address 0 value, then do the update
            if(
                // decoded stored value
                abi.decode(getProperty(constant_owner_stored_key, _tokenId), (address)) 
                == address(0)
            ) {
                _setProperty(
                    constant_owner_stored_key,
                    _tokenId, 
                    // abi encodePacked left shifts everything, but ethers.js cannot decode that properly!
                    abi.encode(currentTokenOwnerAddress(_tokenId))
                );
            }
            // else do nothing
        } else {
            _setProperty(
                constant_owner_stored_key,
                _tokenId, 
                // abi encodePacked left shifts everything, but ethers.js cannot decode that properly!
                abi.encode(currentTokenOwnerAddress(_tokenId))
            );
        }

    }

    function _setProperty(bytes32 _name, uint32 _tokenId, bytes memory input) internal {
        // if(!canUpdateTo(_name, input)) {
        //     revert("Trait: Cannot update values because modifier lock is true");
        // }

        if(!hasTrait(_tokenId)) {
            // if the trait does not exist
            _tokenSetBit(_tokenId, BitType.EXISTS, true);
        }

        if(!isInitialized(_tokenId)) {
            // if the trait is not initialized
            _tokenSetBit(_tokenId, BitType.INITIALIZED, true);
            _setData(_tokenId, tokenDataDEFAULT);
        }

        uint8 _id = propertyNameToId[_name];
        FieldTypes thisPropType = property[_id]._type;

        if(isLogicFieldType(thisPropType)) {
            revert("Trait: Cannot set logic value!");
        } else {

            uint16 _length = uint16(propertyCount) * 32;
            bytes memory tokenData = bytes(storageData[_tokenId]);
            if(tokenData.length == 0) {
                tokenData = new bytes(_length);
                // init default tokenData.. empty for now
            }

            uint256 valuePtr;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                assembly {
                    valuePtr := input
                }
                storageMapArray[_id][_tokenId] = input;

            } else {
                assembly {
                    // load from pointer location
                    valuePtr := add(input, 32)
                }
            }

            assembly {
                // store incomming length value into value slot
                mstore(
                    add(
                        add(tokenData, 32),
                        mul(_id, 32) 
                    ),
                    mload(valuePtr)
                )
            }
            storageData[_tokenId] = tokenData;
        }
        
        emit tokenTraitChangeEvent(_tokenId);
    }

    function getByteAndBit(uint32 _offset) public pure returns (uint32 _byte, uint8 _bit) {
        // find byte storig our bit
        _byte = uint32(_offset / 8);
        _bit = uint8(_offset - _byte * 8);
    }

    function hasTrait(uint32 _tokenId) public view returns (bool result) {
        return _tokenHasBit(_tokenId, BitType.EXISTS);
    }

    function isInitialized(uint32 _tokenId) public view returns (bool result) {
        return _tokenHasBit(_tokenId, BitType.INITIALIZED);
    }

    function _tokenHasBit(uint32 _tokenId, BitType _bitType) internal view returns (bool result) {
        uint8 bitType = uint8(_bitType);
        (uint32 byteNum, uint8 bitPos) = getByteAndBit(_tokenId);
        if(bitType == 1) {
            return existsData[byteNum] & (0x01 * 2**bitPos) != 0;
        } else if(bitType == 2) {
            return initializedData[byteNum] & (0x01 * 2**bitPos) != 0;
        }
    }

    function status(uint32 _tokenId) public view returns ( uint8 ) {
        TraitStatus statusValue = TraitStatus.NONE;
        if(hasTrait(_tokenId)) {
            uint256 activation  = uint256(bytes32(getProperty("activation", _tokenId)));
            uint256 expiration  = uint256(bytes32(getProperty("expiration", _tokenId)));
            uint256 counter     = uint256(bytes32(getProperty("counter",    _tokenId)));

            if(counter > 0) {
                if(activation <= block.timestamp && block.timestamp <= expiration) {

                    // SOULBOUND Check
                    if(movement_permission == uint8(MovementPermission.SOULBOUND)) {

                        address storedOwnerValue = abi.decode(getProperty(constant_owner_stored_key, _tokenId), (address));
                        address currentOwnerValue = currentTokenOwnerAddress(_tokenId);
                        
                        if(storedOwnerValue == currentOwnerValue) {
                            statusValue = TraitStatus.ACTIVE;
                        } else {
                            statusValue = TraitStatus.DORMANT;
                        }

                    } else {
                        statusValue = TraitStatus.ACTIVE;
                    }

                } else {
                    statusValue = TraitStatus.DORMANT;
                }
            } else {
                statusValue = TraitStatus.SPENT;
            }
        }
        return uint8(statusValue);
    }

    // marks token as having the trait
    function addTrait(uint32[] memory _tokenIds) public onlyAllowed {
        for(uint16 _id = 0; _id < _tokenIds.length; _id++) {
            if(!hasTrait(_tokenIds[_id])) {
                // if trait is soulbound we have to initialize it.. 
                if(movement_permission == uint8(MovementPermission.SOULBOUND)) {
                    _updateCurrentOwnerInStorage(_tokenIds[_id]);     
                } else {
                    _tokenSetBit(_tokenIds[_id], BitType.EXISTS, true);
                    emit tokenTraitChangeEvent(_tokenIds[_id]);
                }
            } else {
                revert("Trait: Token already has trait!");
            }
        }
    }

    // util, sets bit in item in map at position as true / false
    function _tokenSetBit(uint32 _tokenId, BitType _bitType, bool _value) internal {
        (uint32 byteNum, uint8 bitPos) = getByteAndBit(_tokenId);
        if(_bitType == BitType.EXISTS) {
            if(_value) {
                existsData[byteNum] = uint8(existsData[byteNum] | 2**bitPos);
            } else {
                existsData[byteNum] = uint8(existsData[byteNum] & ~(2**bitPos));
            }
        } else if(_bitType == BitType.INITIALIZED) {
            if(_value) {
                initializedData[byteNum] = uint8(initializedData[byteNum] | 2**bitPos);
            } else {
                initializedData[byteNum] = uint8(initializedData[byteNum] & ~(2**bitPos));
            }
        }
    }

    function _removeTrait(uint32 _tokenId) internal returns (bool) {
        delete storageData[_tokenId];
        for(uint8 _id = 0; _id < propertyCount; _id++) {
            FieldTypes thisPropType = property[_id]._type;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                delete storageMapArray[_id][_tokenId];
            }
        }
        _tokenSetBit(_tokenId, BitType.EXISTS, false);
        _tokenSetBit(_tokenId, BitType.INITIALIZED, false);

        emit tokenTraitChangeEvent(_tokenId);
        return true;
    }

    function removeTrait(uint32[] memory _tokenIds) public onlyAllowed returns (bool) {
        for(uint8 i = 0; i < _tokenIds.length; i++) {
            _removeTrait(_tokenIds[i]);
        }
        return true;
    }

    function incrementCounter(uint32 _tokenId) public onlyAllowed {
        uint256 counter     = uint256(bytes32(getProperty("counter",    _tokenId))) + 1;
        require(counter < 256,"GenericTrait : counter exceeds max (255)");
        setProperty("counter",_tokenId,abi.encodePacked(counter));
    }

    function decrementCounter(uint32 _tokenId) public onlyAllowed {
        uint256 counter     = uint256(bytes32(getProperty("counter",    _tokenId)));
        require(counter > 0,"GenericTrait : attempt to decrement zero counter");
        setProperty("counter",_tokenId,abi.encodePacked(counter-1));
    }


    function currentTokenOwnerAddress(uint32 _tokenId) public view returns (address) {
        return IERC721(
            (GTRegistry.myCommunityRegistry()).getRegistryAddress(
                GTRegistry.TOKEN_KEY()
            )
        ).ownerOf(_tokenId);
    }

    modifier onlyAllowed() {
        require(GTRegistry.addressCanModifyTrait(msg.sender, traitId), "Trait: Not authorized.");
        _;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface ICommunityList {
    // struct community_entry {
    //     string      name;
    //     address     registry;
    //     uint32      id;
    // }
    // mapping(uint32 => community_entry)  public communities;   // community_id => record

    // function communities(uint32) external returns (struct community_entry memory);
    function communities(uint32) external view returns (string memory, address, uint32);
    function addCommunity(uint32, string memory, address community_registry) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../../Traits/interfaces/IRegistryConsumer.sol";

// import "hardhat/console.sol";

interface IOwnable {
    function owner() external view returns (address);
}

contract CommunityRegistry is AccessControlEnumerable  {

    bytes32 public constant COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");

    IRegistryConsumer       constant     galaxisRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);

    function version() virtual external view returns(uint256) {
        return 20230921;
    }


    uint32                      public  community_id;
    string                      public  community_name;
    address                     public  community_admin;

    mapping(bytes32 => address)         addresses;
    mapping(bytes32 => uint256)         uints;
    mapping(bytes32 => bool)            booleans;
    mapping(bytes32 => string)          strings;

   // mapping(address => bool)    public  admins;

    mapping(address => mapping(address => bool)) public app_admins;

    mapping (uint => string)    public  addressEntries;
    mapping (uint => string)    public  uintEntries;
    mapping (uint => string)    public  boolEntries;
    mapping (uint => string)    public  stringEntries;
    uint                        public  numberOfAddresses;
    uint                        public  numberOfUINTs;
    uint                        public  numberOfBooleans;
    uint                        public  numberOfStrings;

    uint                        public  nextAdmin;
    mapping(address => bool)    public  adminHas;
    mapping(uint256 => address) public  adminEntries;
    mapping(address => uint256) public  appAdminCounter;
    mapping(address =>mapping(uint256 =>address)) public appAdminEntries;

    address                     public  owner;

    bool                                initialised;

    bool                        public  independant;

    event IndependanceDay(bool gain_independance);

    modifier onlyAdmin() {
        require(isCommunityAdmin(COMMUNITY_REGISTRY_ADMIN),"CommunityRegistry : Unauthorised");
        _;
    }


    function isCommunityAdmin(bytes32 role) internal view returns (bool) {
        return isUserCommunityAdmin( role, msg.sender);
    }

    // function isUserCommunityAdmin(bytes32 role, address user) public view returns (bool) {
    //     if (user == owner || hasRole(DEFAULT_ADMIN_ROLE,user) ) return true;
    //     if (independant){        
    //         return(
    //             hasRole(role,user)
    //         );
    //     } else {            
    //        IAccessControlEnumerable ac = IAccessControlEnumerable(owner);   
    //        return(
    //             ac.hasRole(role,user));
    //     }
    // }

    function isUserCommunityAdmin(bytes32 role, address user) public view returns (bool) {
        if (hasRole(DEFAULT_ADMIN_ROLE,user) ) return true; // community_admin can do anything
        if (independant){        
            return(
                hasRole(role,user)
            );
        } else { // for Factories
           return(roleManager().hasRole(role,user));
        }
    }


    function roleManager() internal view returns (IAccessControlEnumerable) {
        address addr = galaxisRegistry.getRegistryAddress("ROLE_MANAGER"); // mainnet
        if (addr != address(0)) return IAccessControlEnumerable(addr);
        addr = galaxisRegistry.getRegistryAddress("MAINNET_CHAIN_IMPLEMENTER"); // mainnet
        if (addr != address(0)) return IAccessControlEnumerable(addr);
        addr = galaxisRegistry.getRegistryAddress("L2_RECEIVER"); // mainnet
        require(addr != address(0),"CommunityRegistry : no higher authority found");
        return IAccessControlEnumerable(addr);
    }


    function grantRole(bytes32 key, address user) public override(AccessControl,IAccessControl) onlyAdmin {
        _grantRole(key,user);
    }
 
    constructor (
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) {
        _init(_community_id,_community_admin,_community_name);
    }

    
    function init(
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) external {
        _init(_community_id,_community_admin,_community_name);
    }

    function _init(
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) internal {
        require(!initialised,"This can only be called once");
        initialised = true;
        community_id = _community_id;
        community_name  = _community_name;
        community_admin = _community_admin;
        _setupRole(DEFAULT_ADMIN_ROLE, community_admin); // default admin = launchpad
        owner = msg.sender;
    }



    event AdminUpdated(address user, bool isAdmin);
    event AppAdminChanged(address app,address user,bool state);
    //===
    event AddressChanged(string key, address value);
    event UintChanged(string key, uint256 value);
    event BooleanChanged(string key, bool value);
    event StringChanged(string key, string value);

    function setIndependant(bool gain_independance) external onlyAdmin {
        if (independant != gain_independance) {
                independant = gain_independance;
                emit IndependanceDay(gain_independance);
        }
    }


    function setAdmin(address user,bool status ) external onlyAdmin {
        if (status)
            _grantRole(COMMUNITY_REGISTRY_ADMIN,user);
        else
            _revokeRole(COMMUNITY_REGISTRY_ADMIN,user);
    }

    function hash(string memory field) internal pure returns (bytes32) {
        return keccak256(abi.encode(field));
    }

    function setRegistryAddress(string memory fn, address value) external onlyAdmin {
        bytes32 hf = hash(fn);
        addresses[hf] = value;
        addressEntries[numberOfAddresses++] = fn;
        emit AddressChanged(fn,value);
    }

    function setRegistryBool(string memory fn, bool value) external onlyAdmin {
        bytes32 hf = hash(fn);
        booleans[hf] = value;
        boolEntries[numberOfBooleans++] = fn;
        emit BooleanChanged(fn,value);
    }

    function setRegistryString(string memory fn, string memory value) external onlyAdmin {
        bytes32 hf = hash(fn);
        strings[hf] = value;
        stringEntries[numberOfStrings++] = fn;
        emit StringChanged(fn,value);
    }

    function setRegistryUINT(string memory fn, uint value) external onlyAdmin {
        bytes32 hf = hash(fn);
        uints[hf] = value;
        uintEntries[numberOfUINTs++] = fn;
        emit UintChanged(fn,value);
    }

    function setAppAdmin(address app, address user, bool state) external {
        require(
            msg.sender == IOwnable(app).owner() ||
            app_admins[app][msg.sender],
            "You do not have access permission"
        );
        app_admins[app][user] = state;
        if (state)
            appAdminEntries[app][appAdminCounter[app]++] = user;
        emit AppAdminChanged(app,user,state);
    }

    function getRegistryAddress(string memory key) external view returns (address) {
        return addresses[hash(key)];
    }

    function getRegistryBool(string memory key) external view returns (bool) {
        return booleans[hash(key)];
    }

    function getRegistryUINT(string memory key) external view returns (uint256) {
        return uints[hash(key)];
    }

    function getRegistryString(string memory key) external view returns (string memory) {
        return strings[hash(key)];
    }

 

    function isAppAdmin(address app, address user) external view returns (bool) {
        return 
            user == IOwnable(app).owner() ||
            app_admins[app][user];
    }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlackHolePrevention is Ownable {
    // blackhole prevention methods
    function retrieveETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
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

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../Traits/Implementers/Generic/GenericTrait.sol";
import "../Traits/Registry/GTRegistry.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct stickerInput {
    uint16        traitID;
    stickerType   visual;
    uint8         side;
    uint8         layer;
    address       nft_address;    
    uint32[]      alternative_values;
}

enum stickerType{
    UTILITY_TRAIT,
    VISUAL_TRAIT,
    RANDOM_NFT
}

enum marking {
    DO_NOTHING,
    CLEAR_BADGE,
    TAKE_CARD
}



struct sticker {
    string          name ;
    uint16          traitID;
    stickerType     visual;
    uint8           side;
    uint8           layer;
    address         nft_address;
    EnumerableSet.UintSet  alternative_values;
}

struct stickerOutput {
    string          name ;
    uint16          traitID;
    stickerType     visual;
    uint8           side;
    uint8           layer;
    address         nft_address;
    uint256[]       alternative_values;
}


struct stickerBookInfo {
    string    name;
    uint16    stickerBookId;
    bool      active;
    uint16    maxRedemptions;
    uint16    stickerCount;
    uint16    conditionalCountCounter;
    string    uri;
    uint16    numberRedeemed;
    marking   clearBadge;
    uint16    traitToClear;
    string    ipfsHash;
}

struct fullStickerBookInfo {
    string              name;
    uint16              stickerBookId;
    bool                active;
    uint16              maxRedemptions;
    stickerOutput[][]   stickers;
    string              uri;
    uint16              numberRedeemed;
    marking             clearBadge;
    uint16              traitToClear;
    string              ipfsHash;
    conditionOutput[]   conditions;
    bool                acceptsJoker;
    uint16              jokerID;
    rewardTypeEnum      rewardType;
    uint16              rewardTraitID;
    address             nftToMint;
}

struct Extra {
    bool                acceptsJoker;
    uint16              jokerID;
    rewardTypeEnum      rewardType;
    uint16              rewardTraitID;
    address             nftToMint;
}


struct StickerbookInitData {
    uint32      communityId;
    uint32      collectionNumber;
    string      uri;
}

struct condition {
    sticker[] stix;
    uint8     counter;
}

struct conditionOutput {
    stickerOutput[] stix;
    uint8           counter;
}


struct conditionInput {
    stickerInput[]  stix;
    uint8           count;
}

enum rewardTypeEnum {
    TRAIT_COUPON,
    CONTRACT_1155,
    MINT_721
}

struct fullStickerBookData {
        string              name;
        uint16              maxRedemptions;
        marking             clearBadge;
        uint16              traitToClear;
        stickerInput[][]    stix;
        string              ipfsHash;
        conditionInput[]    conditions;
        bool                acceptsJoker;
        uint16              jokerID;
        rewardTypeEnum      rewardType;
        uint16              rewardTraitID;
        address             nftToMint;
        string              uri;
}

interface SBF {
    function grantBadgeAccessToStickerbook(
        uint16 traitID
    ) external;
}

struct stickerStruct {
    uint256 length;
    mapping (uint256 => sticker) data;
}

struct SuperStickerbookInfo {
    address                                            superstickerbook_utils;
    uint16                                             nextBook;
    mapping(string  => uint16)                         stickerbooks;
    mapping(uint16 => stickerBookInfo)                 stickerBookData;
    mapping(uint16 => Extra)                           extraInfo;
    mapping(uint16 =>                                  // book id
            mapping(uint16 =>  stickerStruct))             stickers;     // sticker set in a particular book 1 - stickerCount -1 

    mapping(uint16 =>                                  // book id
            mapping(uint16 =>  stickerStruct))             conditionalStickers;     // sticker set in a particular book 1 - stickerCount -1 
    mapping(uint16 =>                                  // book id
            mapping(uint16 =>  uint8))                 conditionalCount;     // sticker set in a particular book 1 - stickerCount -1 

    mapping(uint16 => GenericTrait)                    _implementers;
    mapping(string => uint16)                          traitNumbers;
    IERC721                                            nft;
    GTRegistry                                         reg;
    
    uint32                                             communityID; 
    uint32                                             collectionNumber;
    bool                                               _initialized;
    CommunityRegistry                                  myCommunityRegistry;

    mapping(uint16 =>                                  // stickerbookID
                    mapping(uint32 => bool))           used; // tokenId => bool

    SBF                                                parent;

    mapping(uint16 =>                                  // stickerBookID
        mapping(address =>                             // random NFT Address
            mapping(uint32 => bool)))                  randomNftsUsed;
}

contract SuperStickerbookData {

    bytes32 constant SUPER_STICKERBOOK_DATA_STORAGE_POSITION = keccak256("SUPER_STICKERBOOK_DATA_STORAGE_POSITION");

    function ds() internal pure returns (SuperStickerbookInfo storage dss) {
        bytes32 position = SUPER_STICKERBOOK_DATA_STORAGE_POSITION;
        assembly {
            dss.slot := position
        }
    }
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract CommunityList is AccessControlEnumerable { 

    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");


    uint256                              public numberOfEntries;

    struct community_entry {
        string      name;
        address     registry;
        uint32      id;
    }
    
    mapping(uint32 => community_entry)  public communities;   // community_id => record
    mapping(uint256 => uint32)           public index;         // entryNumber => community_id for enumeration

    event CommunityAdded(uint256 pos, string community_name, address community_registry, uint32 community_id);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN,msg.sender);
    }

    function addCommunity(uint32 community_id, string memory community_name, address community_registry) external onlyRole(CONTRACT_ADMIN) {
        uint256 pos = numberOfEntries++;
        index[pos]  = community_id;
        communities[community_id] = community_entry(community_name, community_registry, community_id);
        emit CommunityAdded(pos, community_name, community_registry, community_id);
    }

}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IECRegistry {
    function addTrait(traitStruct[] memory) external; 
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] memory) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    // ---- Change start ----
    function setTrait(uint16 traitID, uint16 tokenID, bool) external returns (bool);
    function setTraitUnchecked(uint16 traitID, uint16 tokenId, bool _value) external;
    function setTraitOnMultiple(uint16 traitID, uint16[] memory tokenIds, bool _value) external returns(uint16 changes);
    function setTraitOnMultipleUnchecked(uint16 traitID, uint16[] memory tokenIds, bool[] memory _value) external;
    function getTrait(uint16 id) external view returns (traitStruct memory);
    function getTraits() external view returns (traitStruct[] memory);
    // ---- Change end ----
    function owner() external view returns (address);
    function contractController(address) external view returns (bool);
    function getDefaultTraitControllerByType(uint8) external view returns (address);
    function setDefaultTraitControllerType(address, uint8) external;
    function setTraitControllerAccess(address, uint16, bool) external;
    function traitCount() external view returns (uint16);

    struct traitStruct {
        uint16  id;
        uint8   traitType;              // 0 normal (1bit), 1 range, 2 inverted range, >=3 with storageImplementer
        uint16  start;
        uint16  end;
        bool    enabled;
        address storageImplementer;     // address of the smart contract that will implement the storage for the trait
        string  ipfsHash;
        string  name;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IUtilityTraitCoupon {

    function mint(
        uint32 _tokenNumber,
        uint16 _traitNumber,
        address _recipient,
        uint256 _numberToMint,
        bytes calldata data
    ) external ;

    function burn(
        uint256 _tokenId, 
        uint256 quantity
    ) external;

    function getData(
        uint32 tokenNum, 
        uint16 traitNum, 
        uint256 value
    ) external view returns (bytes memory);

    function makeId(
        uint32 tokenNumber, 
        uint16 traitNumber, 
        uint256 value
    ) external pure returns (uint256);

    function init(uint32 communityId, string calldata URI ) external;

    function communityId() external view returns (uint32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRegistry {
    function setRegistryAddress(string memory fn, address value) external ;
    function setRegistryBool(string memory fn, bool value) external ;
    function setRegistryUINT(string memory key) external view returns (uint256) ;
    function setRegistryString(string memory fn, string memory value) external ;
    function setAdmin(address user,bool status ) external;
    function setAppAdmin(address app, address user, bool state) external;

    function getRegistryAddress(string memory key) external view returns (address) ;
    function getRegistryBool(string memory key) external view returns (bool);
    function getRegistryUINT(string memory key) external view returns (uint256) ;
    function getRegistryString(string memory key) external view returns (string memory) ;
    function isAdmin(address user) external view returns (bool) ;
    function isAppAdmin(address app, address user) external view returns (bool);
}