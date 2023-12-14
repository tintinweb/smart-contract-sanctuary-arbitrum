//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IECRegistry.sol";

contract VisualTraitRegistry {

    function version() public pure virtual returns (uint256) {
        return 2023120601;
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