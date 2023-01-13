// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

SmolsState.sol

Written by: mousedev.eth

*/

import "./utilities/OwnableOrAdminable.sol";
import "./libraries/SmolsLibrary.sol";

contract SmolsState is OwnableOrAdminable {
    mapping(address => bool) public allowedSetters;

    mapping(uint256 => Smol) internal smolToTraits;
    mapping(uint256 => Smol) internal initialSmolToTraits;

    /**
     * @dev Throws if called by any account other than an allowed setter.
     */
    modifier onlyAllowedSetter() {
        require(
            allowedSetters[msg.sender] || msg.sender == owner(),
            "Not an allowed setter!"
        );
        _;
    }

    /// @dev Sets an allowed setter.
    /// @param _setter The address to set.
    /// @param _allowed Whether they are allowed or not.
    function setAllowedSetter(address _setter, bool _allowed) external onlyOwnerOrAdmin {
        allowedSetters[_setter] = _allowed;
    }

    /// @dev Returns a smol struct representing the current adjusted state of the smol.
    /// @param _tokenId The smol to get.
    /// @return Smol The smol you requested.
    function getSmol(uint256 _tokenId) external view returns (Smol memory) {
        return smolToTraits[_tokenId];
    }

    /// @dev Returns a smol struct representing the initial state of the smol.
    /// @param _tokenId The smol to get.
    /// @return Smol The smol you requested.
    function getInitialSmol(uint256 _tokenId) external view returns (Smol memory) {
        return initialSmolToTraits[_tokenId];
    }

    /// @dev Adjust smol data.
    /// @param _tokenId The smol to get.
    /// @param _smol The smol data to set.
    function setSmol(uint256 _tokenId, Smol memory _smol)
        external
        onlyAllowedSetter
    {
        smolToTraits[_tokenId] = _smol;
    }

    /// @dev Adjust smol initial data.
    /// @param _tokenId The smol to get.
    /// @param _smol The smol data to set.
    function setInitialSmol(uint256 _tokenId, Smol memory _smol)
        external
        onlyAllowedSetter
    {
        initialSmolToTraits[_tokenId] = _smol;
        smolToTraits[_tokenId] = _smol;
    }

    /// @dev Adjust smol trait.
    /// @param _tokenId The smol to set.
    /// @param _traitId The smol traitId to set this trait to.
    function setBackground(uint256 _tokenId, uint24 _traitId)
        external
        onlyAllowedSetter
    {
        if(_traitId == 0){
            smolToTraits[_tokenId].background = initialSmolToTraits[_tokenId].background;
        } else {
            smolToTraits[_tokenId].background = _traitId;
        }
    }

    /// @dev Adjust smol trait.
    /// @param _tokenId The smol to set.
    /// @param _traitId The smol traitId to set this trait to.
    function setBody(uint256 _tokenId, uint24 _traitId)
        external
        onlyAllowedSetter
    {
        if(_traitId == 0){
            smolToTraits[_tokenId].body = initialSmolToTraits[_tokenId].body;
        } else {
            smolToTraits[_tokenId].body = _traitId;
        }
    }

    /// @dev Adjust smol trait.
    /// @param _tokenId The smol to set.
    /// @param _traitId The smol traitId to set this trait to.
    function setClothes(uint256 _tokenId, uint24 _traitId)
        external
        onlyAllowedSetter
    {
        if(_traitId == 0){
            smolToTraits[_tokenId].clothes = initialSmolToTraits[_tokenId].clothes;
        } else {
            smolToTraits[_tokenId].clothes = _traitId;
        }
    }

    /// @dev Adjust smol trait.
    /// @param _tokenId The smol to set.
    /// @param _traitId The smol traitId to set this trait to.
    function setMouth(uint256 _tokenId, uint24 _traitId)
        external
        onlyAllowedSetter
    {
        if(_traitId == 0){
            smolToTraits[_tokenId].mouth = initialSmolToTraits[_tokenId].mouth;
        } else {
            smolToTraits[_tokenId].mouth = _traitId;
        }
    }

    /// @dev Adjust smol trait.
    /// @param _tokenId The smol to set.
    /// @param _traitId The smol traitId to set this trait to.
    function setGlasses(uint256 _tokenId, uint24 _traitId)
        external
        onlyAllowedSetter
    {
        if(_traitId == 0){
            smolToTraits[_tokenId].glasses = initialSmolToTraits[_tokenId].glasses;
        } else {
            smolToTraits[_tokenId].glasses = _traitId;
        }
    }

    /// @dev Adjust smol trait.
    /// @param _tokenId The smol to set.
    /// @param _traitId The smol traitId to set this trait to.
    function setHat(uint256 _tokenId, uint24 _traitId)
        external
        onlyAllowedSetter
    {
        if(_traitId == 0){
            smolToTraits[_tokenId].hat = initialSmolToTraits[_tokenId].hat;
        } else {
            smolToTraits[_tokenId].hat = _traitId;
        }
    }

    /// @dev Adjust smol trait.
    /// @param _tokenId The smol to set.
    /// @param _traitId The smol traitId to set this trait to.
    function setHair(uint256 _tokenId, uint24 _traitId)
        external
        onlyAllowedSetter
    {
        if(_traitId == 0){
            smolToTraits[_tokenId].hair = initialSmolToTraits[_tokenId].hair;
        } else {
            smolToTraits[_tokenId].hair = _traitId;
        }
    }

    /// @dev Adjust smol trait.
    /// @param _tokenId The smol to set.
    /// @param _traitId The smol traitId to set this trait to.
    function setSkin(uint256 _tokenId, uint24 _traitId)
        external
        onlyAllowedSetter
    {
        smolToTraits[_tokenId].skin = _traitId;
    }

    /// @dev Adjust smol gender.
    /// @param _tokenId The smol to set.
    /// @param _gender The smol gender to set this smol to.
    function setGender(uint256 _tokenId, uint8 _gender)
        external
        onlyAllowedSetter
    {
        smolToTraits[_tokenId].gender = _gender;
    }

    /// @dev Adjust smol headsize.
    /// @param _tokenId The smol to set.
    /// @param _headSize The smol headsize to set it to.
    function setHeadSize(uint256 _tokenId, uint8 _headSize)
        external
        onlyAllowedSetter
    {
        smolToTraits[_tokenId].headSize = _headSize;
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