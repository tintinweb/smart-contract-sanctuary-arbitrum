// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./IAovMetadata.sol";
import "../Adventurer/IAdventurerData.sol";

import "../Manager/ManagerModifier.sol";

contract AovMetadata is IAovMetadata, ManagerModifier {
  using Strings for uint256;
  //=======================================
  // Immutables
  //=======================================
  IAdventurerData public immutable ADVENTURER_DATA;

  //=======================================
  // Strings
  //=======================================
  string public baseURI;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager, address _adventurerData)
    ManagerModifier(_manager)
  {
    ADVENTURER_DATA = IAdventurerData(_adventurerData);
  }

  //=======================================
  // External
  //=======================================
  function uri(address _addr, uint256 _tokenId)
    external
    view
    override
    returns (string memory)
  {
    uint256[] memory aov = _aovData(_addr, _tokenId);

    string memory json = string(
      abi.encodePacked(
        '{"name": "Adventurer of the Void",',
        '"description": "The Realmverse awaits. Adventurers of the Void are the first inhabitants of the Realmverse and are ready to explore, quest, battle and much more.", "image": "',
        abi.encodePacked(baseURI, Strings.toString(aov[1])),
        '"',
        ',"attributes":',
        _attributes(_addr, _tokenId, aov),
        "}"
      )
    );

    return json;
  }

  //=======================================
  // Admin
  //=======================================
  function setBaseURI(string calldata _baseURI) external onlyAdmin {
    baseURI = _baseURI;
  }

  //=======================================
  // Internal
  //=======================================
  function _attributes(
    address _addr,
    uint256 _tokenId,
    uint256[] memory _aov
  ) internal view returns (string memory) {
    string[23] memory _parts;

    uint256[] memory base = _baseData(_addr, _tokenId);

    _parts[0] = '[{ "trait_type": "Transcendence Level", "value": "';
    _parts[1] = Strings.toString(_aov[0]);
    _parts[2] = '" }, { "trait_type": "Class", "value": "';
    _parts[3] = _class(_aov[2]);
    _parts[4] = '" }, { "trait_type": "Profession", "value": "';
    _parts[5] = _profession(_aov[3]);
    _parts[6] = '" }, { "trait_type": "XP", "value": "';
    _parts[7] = Strings.toString(base[0]);
    _parts[8] = '" }, { "trait_type": "HP", "value": "';
    _parts[9] = Strings.toString(base[1]);
    _parts[10] = '" }, { "trait_type": "Strength", "value": "';
    _parts[11] = Strings.toString(base[2]);
    _parts[12] = '" }, { "trait_type": "Dexterity", "value": "';
    _parts[13] = Strings.toString(base[3]);
    _parts[14] = '" }, { "trait_type": "Constitution", "value": "';
    _parts[15] = Strings.toString(base[4]);
    _parts[16] = '" }, { "trait_type": "Intelligence", "value": "';
    _parts[17] = Strings.toString(base[5]);
    _parts[18] = '" }, { "trait_type": "Wisdom", "value": "';
    _parts[19] = Strings.toString(base[6]);
    _parts[20] = '" }, { "trait_type": "Charisma", "value": "';
    _parts[21] = Strings.toString(base[7]);
    _parts[22] = '" }]';

    string memory _output = string(
      abi.encodePacked(
        _parts[0],
        _parts[1],
        _parts[2],
        _parts[3],
        _parts[4],
        _parts[5],
        _parts[6]
      )
    );
    _output = string(
      abi.encodePacked(
        _output,
        _parts[7],
        _parts[8],
        _parts[9],
        _parts[10],
        _parts[11],
        _parts[12]
      )
    );
    _output = string(
      abi.encodePacked(
        _output,
        _parts[13],
        _parts[14],
        _parts[15],
        _parts[16],
        _parts[17],
        _parts[18]
      )
    );
    _output = string(
      abi.encodePacked(_output, _parts[19], _parts[20], _parts[21], _parts[22])
    );

    return _output;
  }

  function _class(uint256 _classId) internal pure returns (string memory) {
    if (_classId == 1) {
      return "Chaos";
    } else if (_classId == 2) {
      return "Mischief";
    } else {
      return "Tranquility";
    }
  }

  function _profession(uint256 _professionId)
    internal
    pure
    returns (string memory)
  {
    if (_professionId == 1) {
      return "Explorer";
    } else if (_professionId == 2) {
      return "Zealot";
    } else {
      return "Scientist";
    }
  }

  function _baseData(address _addr, uint256 _adventurerId)
    internal
    view
    returns (uint256[] memory)
  {
    return ADVENTURER_DATA.baseProperties(_addr, _adventurerId, 0, 7);
  }

  function _aovData(address _addr, uint256 _adventurerId)
    internal
    view
    returns (uint256[] memory)
  {
    return ADVENTURER_DATA.aovProperties(_addr, _adventurerId, 0, 3);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAovMetadata {
  function uri(address _addr, uint256 _tokenId)
    external
    view
    returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAdventurerData {
  function initData(
    address[] calldata _addresses,
    uint256[] calldata _ids,
    bytes32[][] calldata _proofs,
    uint256[] calldata _professions,
    uint256[][] calldata _points
  ) external;

  function baseProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function aovProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function extensionProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function createFor(
    address _addr,
    uint256 _id,
    uint256[] calldata _points
  ) external;

  function createFor(
    address _addr,
    uint256 _id,
    uint256 _archetype
  ) external;

  function addToBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}