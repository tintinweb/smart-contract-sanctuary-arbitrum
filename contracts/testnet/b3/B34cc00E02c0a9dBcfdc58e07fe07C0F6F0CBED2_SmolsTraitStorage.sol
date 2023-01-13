// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

SmolsTraitStorage.sol

Written by: mousedev.eth

*/

import "./utilities/OwnableOrAdminable.sol";
import "./libraries/SmolsLibrary.sol";

contract SmolsTraitStorage is OwnableOrAdminable {
    mapping(uint256 => mapping(uint256 => Trait)) public traits;

    /// @dev Set a single trait and dependency level to a trait.
    /// @param _traitId The trait id to set.
    /// @param _dependencyLevel The dependency level to set.
    /// @param _trait The trait to set.
    function setTrait(
        uint256 _traitId,
        uint256 _dependencyLevel,
        Trait memory _trait
    ) external onlyOwnerOrAdmin {
        traits[_traitId][_dependencyLevel] = _trait;
    }

    /// @dev Sets multiple traitIds and dependency levels to traits.
    /// @param _traitIds The trait ids to set.
    /// @param _dependencyLevels The dependency levels to set.
    /// @param _traits The traits to set.
    function setTraits(
        uint256[] memory _traitIds,
        uint256[] memory _dependencyLevels,
        Trait[] memory _traits
    ) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _traits.length; i++) {
            traits[_traitIds[i]][_dependencyLevels[i]] = _traits[i];
        }
    }

    /// @dev Returns a single Trait struct from a traitId and dependencyLevel.
    /// @param _traitId The trait id to return.
    /// @param _dependencyLevel The dependency level of that trait to return.
    /// @return Trait The trait to return.
    function getTrait(uint256 _traitId, uint256 _dependencyLevel)
        external
        view
        returns (Trait memory)
    {
        return traits[_traitId][_dependencyLevel];
    }

    /// @dev Returns a single trait type from a traitId and dependencyLevel.
    /// @param _traitId The trait id to return.
    /// @param _dependencyLevel The dependency level of that trait to return.
    /// @return traitType The trait type to return.
    function getTraitType(uint256 _traitId, uint256 _dependencyLevel)
        external
        view
        returns (bytes memory)
    {
        return traits[_traitId][_dependencyLevel].traitType;
    }

    /// @dev Returns a single trait name from a traitId and dependencyLevel.
    /// @param _traitId The trait id to return.
    /// @param _dependencyLevel The dependency level of that trait to return.
    /// @return traitName The trait name to return.
    function getTraitName(uint256 _traitId, uint256 _dependencyLevel)
        external
        view
        returns (bytes memory)
    {
        return traits[_traitId][_dependencyLevel].traitName;
    }

    /// @dev Returns a single trait image from a traitId and dependencyLevel.
    /// @param _traitId The trait id to return.
    /// @param _dependencyLevel The dependency level of that trait to return.
    /// @param _gender The gender of the trait to return.
    /// @return traitImage The trait image to return.
    function getTraitImage(uint256 _traitId, uint8 _gender, uint256 _dependencyLevel)
        external
        view
        returns (bytes memory)
    {
        if(_gender == 1){
            return traits[_traitId][_dependencyLevel].pngImage.male;
        }
        if(_gender == 2){
            return traits[_traitId][_dependencyLevel].pngImage.female;
        }

        revert("Gender not specified");
        //return traits[_traitId][_dependencyLevel].pngImage;
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