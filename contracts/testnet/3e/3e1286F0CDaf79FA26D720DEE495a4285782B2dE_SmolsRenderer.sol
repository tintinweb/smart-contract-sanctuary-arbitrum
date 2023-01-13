// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
/*

SmolsRenderer.sol

Written by: mousedev.eth

*/


import "./interfaces/ISchool.sol";
import "./interfaces/ISmolsState.sol";
import "./interfaces/ISmolsTraitStorage.sol";
import "./SmolsAddressRegistryConsumer.sol";

import "./utilities/OwnableOrAdminable.sol";
import "./libraries/SmolsLibrary.sol";

contract SmolsRenderer is OwnableOrAdminable, SmolsAddressRegistryConsumer  {
    uint256 public iqPerHeadSize = 50 * (10 ** 18);
    string public collectionDescription;
    string public namePrefix;


    /// @dev Gets a smol.
    /// @param _tokenId The smol to get.
    /// @return smol
    function getSmol(uint256 _tokenId) internal view returns (Smol memory) {
        address smolsStateAddress = smolsAddressRegistry.getAddress(SmolAddressEnum.SMOLSSTATEADDRESS);
        address schoolAddress = smolsAddressRegistry.getAddress(SmolAddressEnum.SCHOOLADDRESS);
        address smolsAddress = smolsAddressRegistry.getAddress(SmolAddressEnum.SMOLSADDRESS);

        Smol memory _smolState = ISmolsState(smolsStateAddress).getSmol(
            _tokenId
        );

        uint128 totalStatPlusPendingEmissions = ISchool(schoolAddress).getTotalStatPlusPendingEmissions(smolsAddress, 0, _tokenId);

        if(totalStatPlusPendingEmissions < iqPerHeadSize * _smolState.headSize){
            //Too smol brain
            uint256 realHeadSize = totalStatPlusPendingEmissions / iqPerHeadSize;
            //If it's bigger than the max setting, set it to 5 as a sanity check. (theoretically shouldn't be possible, as you cannot set your head size higher.)
            if(realHeadSize > 5) {
                _smolState.headSize = 5;
            } else {
                _smolState.headSize = uint8(realHeadSize);
            }

        }

        return _smolState;
    }

    /// @dev Sets certain collection metadata.
    /// @param _collectionDescription A description of the collection.
    /// @param _namePrefix A prefix to use with the name of the tokens.
    function setCollectionData(
        string memory _collectionDescription,
        string memory _namePrefix
    ) external onlyOwnerOrAdmin {
        if (bytes(_collectionDescription).length > 0)
            collectionDescription = _collectionDescription;
        if (bytes(_namePrefix).length > 0) namePrefix = _namePrefix;
    }


    function generatePNGFromTraitId(uint256 _traitId, uint8 _gender, uint256 _dependencyLevel)
        internal
        view
        returns (bytes memory)
    {
        
        address smolsTraitStorageAddress = smolsAddressRegistry.getAddress(SmolAddressEnum.SMOLSTRAITSTORAGEADDRESS);

        return
            ISmolsTraitStorage(smolsTraitStorageAddress).getTraitImage(
                _traitId,
                _gender,
                _dependencyLevel
            );
    }

    function generateSVG(Smol memory _smol) public view returns (bytes memory) {
        if (_smol.skin > 0) {
            return
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="smol" width="100%" height="100%" version="1.1" viewBox="0 0 360 360" ',
                    'style="background-color: transparent;background-image:url(',
                    generatePNGFromTraitId(_smol.skin, _smol.gender, 0),
                    "),url(",
                    generatePNGFromTraitId(_smol.body, _smol.gender, 0),
                    "),url(",
                    generatePNGFromTraitId(_smol.background, _smol.gender, 0),
                    ')"',
                    ">",
                    "<style>#smol {background-repeat: no-repeat;background-size: contain;background-position: center;image-rendering: -webkit-optimize-contrast;-ms-interpolation-mode: nearest-neighbor;image-rendering: -moz-crisp-edges;image-rendering: pixelated;}</style></svg>"
                );
        }
        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="smol" width="100%" height="100%" version="1.1" viewBox="0 0 360 360" ',
                'style="background-color: transparent;background-image:url(',
                generatePNGFromTraitId(_smol.mouth, _smol.gender, 0),
                "),url(",
                generatePNGFromTraitId(_smol.hat, _smol.gender, _smol.headSize),
                "),url(",
                generatePNGFromTraitId(_smol.glasses, _smol.gender, 0),
                "),url(",
                generatePNGFromTraitId(_smol.clothes, _smol.gender, 0),
                "),url(",
                generatePNGFromTraitId(_smol.hair, _smol.gender, _smol.headSize),
                "),url(",
                generatePNGFromTraitId(_smol.body, _smol.gender, _smol.headSize),
                "),url(",
                generatePNGFromTraitId(_smol.background, _smol.gender, 0),
                ')"',
                ">",
                "<style>#smol {background-repeat: no-repeat;background-size: contain;background-position: center;image-rendering: -webkit-optimize-contrast;-ms-interpolation-mode: nearest-neighbor;image-rendering: -moz-crisp-edges;image-rendering: pixelated;}</style></svg>"
            );
    }

    function generateMetadataString(
        bytes memory traitType,
        bytes memory traitName
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '{"trait_type":"',
                traitType,
                '","value":"',
                traitName,
                '"}'
            );
    }

    function generateMetadataStringForTrait(uint256 _traitId, uint8 _headSize)
        internal
        view
        returns (bytes memory)
    {
        address smolsTraitStorageAddress = smolsAddressRegistry.getAddress(SmolAddressEnum.SMOLSTRAITSTORAGEADDRESS);
        return
            generateMetadataString(
                ISmolsTraitStorage(smolsTraitStorageAddress).getTraitType(
                    _traitId,
                    _headSize
                ),
                ISmolsTraitStorage(smolsTraitStorageAddress).getTraitName(
                    _traitId,
                    _headSize
                )
            );
    }

    function generateMetadata(Smol memory _smol)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "[",
                //Load the background
                generateMetadataStringForTrait(_smol.background, 0),
                ",",
                //Load the Body
                generateMetadataStringForTrait(_smol.body, _smol.headSize),
                ",",
                //Load the Clothes
                generateMetadataStringForTrait(_smol.clothes, 0),
                ",",
                //Load the Glasses
                generateMetadataStringForTrait(_smol.glasses, 0),
                ",",
                //Load the Hat
                generateMetadataStringForTrait(_smol.hat, _smol.headSize),
                ",",
                //Load the Hair
                generateMetadataStringForTrait(_smol.hair, _smol.headSize),
                ",",
                //Load the Mouth
                generateMetadataStringForTrait(_smol.mouth, 0),
                ",",
                //Load the Gender
                generateMetadataString(
                    "Gender",
                    _smol.gender == 1 ? bytes("male") : bytes("female")
                ),
                "]"
            );
    }


    /// @dev Consructs and returns an on chain smol.
    /// @param _tokenId The tokenId of the smol to return.
    /// @return smol The smol to return.
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        Smol memory _smol = getSmol(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    SmolsLibrary.encode(
                        abi.encodePacked(
                            '{"description": "',
                            collectionDescription,
                            '","image": "data:image/svg+xml;base64,',
                            SmolsLibrary.encode(generateSVG(_smol)),
                            '","name": "',
                            namePrefix,
                            SmolsLibrary.toString(_tokenId),
                            '","attributes":',
                            generateMetadata(_smol),
                            "}"
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct TokenDetails {
    uint128 statAccrued;
    uint64 timestampJoined;
    bool joined;
}

struct StatDetails {
    uint128 globalStatAccrued;
    uint128 emissionRate;
    bool exists;
    bool joinable;
}

interface ISchool {
    function tokenDetails(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId
    ) external view returns (TokenDetails memory);

    function getPendingStatEmissions(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId
    ) external view returns (uint128);

    function statDetails(address _collectionAddress, uint64 _statId)
        external
        view
        returns (StatDetails memory);

    function totalStatsJoinedWithinCollection(
        address _collectionAddress,
        uint256 _tokenId
    ) external view returns (uint256);

    function getTotalStatPlusPendingEmissions(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId
    ) external view returns (uint128);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../libraries/SmolsLibrary.sol";

interface ISmolsState {
    function getSmol(uint256 tokenId) external view returns (Smol memory);

    function getInitialSmol(uint256 tokenId) external view returns (Smol memory);

    function setSmol(uint256 tokenId, Smol memory) external;

    function setInitialSmol(uint256 tokenId, Smol memory) external;

    function setBackground(uint256 _tokenId, uint24 _traitId) external;

    function setBody(uint256 _tokenId, uint24 _traitId) external;

    function setClothes(uint256 _tokenId, uint24 _traitId) external;

    function setMouth(uint256 _tokenId, uint24 _traitId) external;

    function setGlasses(uint256 _tokenId, uint24 _traitId) external;

    function setHat(uint256 _tokenId, uint24 _traitId) external;

    function setHair(uint256 _tokenId, uint24 _traitId) external;

    function setSkin(uint256 _tokenId, uint24 _traitId) external;

    function setGender(uint256 _tokenId, uint8 _gender) external;

    function setHeadSize(uint256 _tokenId, uint8 _headSize) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../libraries/SmolsLibrary.sol";

interface ISmolsTraitStorage {
    function traits(uint256 _traitId, uint256 _dependencyLevel) external view returns(Trait memory);

    function getTrait(uint256 _traitId, uint256 _dependencyLevel)
        external
        view
        returns (Trait memory);

    function getTraitType(uint256 _traitId, uint256 _dependencyLevel)
        external
        view
        returns (bytes memory);
        
    function getTraitName(uint256 _traitId, uint256 _dependencyLevel)
        external
        view
        returns (bytes memory);

    function getTraitImage(uint256 _traitId, uint8 _gender, uint256 _dependencyLevel)
        external
        view
        returns (bytes memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

SmolsAddressRegistryConsumer.sol

Written by: mousedev.eth

*/

import "./utilities/OwnableOrAdminable.sol";
import "./interfaces/ISmolsAddressRegistry.sol";


contract SmolsAddressRegistryConsumer is OwnableOrAdminable {

    ISmolsAddressRegistry smolsAddressRegistry;

    
    /// @dev Sets the smols address registry address.
    /// @param _smolsAddressRegistry The address of the registry.
    function setSmolsAddressRegistry(address _smolsAddressRegistry) external onlyOwner {
        smolsAddressRegistry = ISmolsAddressRegistry(_smolsAddressRegistry);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

abstract contract OwnableOrAdminable {
    address private _owner;

    mapping(address => bool) private _isAdmin;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwnerOrAdmin() {
        require(
            owner() == msg.sender || _isAdmin[msg.sender],
            "Ownable: caller is not the owner or admin"
        );
        _;
    }

    /**
     * @dev Allows owner or admin to add admins
     */

    function setAdmins(address[] memory _addresses, bool[] memory _isAdmins) public {
        require(
            owner() == msg.sender,
            "Ownable: caller is not the owner"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            _isAdmin[_addresses[i]] = _isAdmins[i];
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
pragma solidity ^0.8.0;



struct PngImage {
    bytes male;
    bytes female;
}

struct Trait {
    uint8 gender;
    uint24 traitId;
    bytes traitName;
    bytes traitType;
    PngImage pngImage;
}

struct Smol {
    uint24 background;
    uint24 body;
    uint24 clothes;
    uint24 mouth;
    uint24 glasses;
    uint24 hat;
    uint24 hair;
    uint24 skin;
    uint8 gender;
    //0 - Unset
    //1 - Male
    //2 - Female
    uint8 headSize;
}



library SmolsLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

enum SmolAddressEnum {
    OLDSMOLSADDRESS,
    SMOLSADDRESS,

    SMOLSSTATEADDRESS,
    SCHOOLADDRESS,

    SMOLSTRAITSTORAGEADDRESS,

    SMOLSRENDERERADDRESS,
    TRANSFERBLOCKERADDRESS
}

interface ISmolsAddressRegistry{
    function getAddress(SmolAddressEnum) external view returns(address);
}