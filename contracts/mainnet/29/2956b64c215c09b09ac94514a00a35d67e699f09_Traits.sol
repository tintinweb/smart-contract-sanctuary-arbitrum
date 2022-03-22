// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./ITraits.sol";
import "./TraitsBase.sol";
import "./IPeekABoo.sol";

contract Traits is Initializable, ITraits, OwnableUpgradeable, TraitsBase {
    using StringsUpgradeable for uint256;

    function initialize(address _peekaboo) public initializer {
        __Ownable_init();
        peekaboo = IPeekABoo(_peekaboo);
    }

    /** ADMIN */
    /**
     * administrative to upload the names and images associated with each trait
     * @param ghostOrBuster 0 if ghost, 1 if buster
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traits the names and base64 encoded PNGs for each trait
     */
    function uploadTraits(
        uint256 ghostOrBuster,
        uint256 traitType,
        uint256[] calldata traitIds,
        Trait[] calldata traits
    ) external onlyOwner {
        require(traitIds.length == traits.length, "Mismatched inputs");
        for (uint256 i = 0; i < traits.length; i++) {
            traitData[ghostOrBuster][traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].svg
            );
        }
    }

    function setPeekABoo(address _peekaboo) external onlyOwner {
        peekaboo = IPeekABoo(_peekaboo);
    }

    /** RENDER */
    function drawSVG(
        uint256 tokenId,
        uint256 width,
        uint256 height
    ) public view returns (string memory) {
        IPeekABoo.PeekABooTraits memory _peekaboo = peekaboo.getTokenTraits(
            tokenId
        );
        uint8 peekabooType = _peekaboo.isGhost ? 0 : 1;

        string memory svgString = string(
            abi.encodePacked(
                (traitData[0][0][_peekaboo.background]).svg,
                (traitData[peekabooType][1][_peekaboo.back]).svg,
                (traitData[peekabooType][2][_peekaboo.bodyColor]).svg,
                _peekaboo.isGhost
                    ? (traitData[peekabooType][3][_peekaboo.clothesOrHelmet])
                        .svg
                    : (traitData[peekabooType][3][_peekaboo.hat]).svg,
                _peekaboo.isGhost
                    ? (traitData[peekabooType][4][_peekaboo.hat]).svg
                    : (traitData[peekabooType][4][_peekaboo.face]).svg,
                _peekaboo.isGhost
                    ? (traitData[peekabooType][5][_peekaboo.face]).svg
                    : (traitData[peekabooType][5][_peekaboo.clothesOrHelmet])
                        .svg,
                _peekaboo.isGhost
                    ? (traitData[peekabooType][6][_peekaboo.hands]).svg
                    : ""
            )
        );

        return
            string(
                abi.encodePacked(
                    '<svg width="100%"',
                    ' height="100%" viewBox="0 0 100 100"',
                    ">",
                    svgString,
                    "</svg>"
                )
            );
    }

    function tryOutTraits(
        uint256 tokenId,
        uint256[2][] memory traitsToTry,
        uint256 width,
        uint256 height
    ) external view returns (string memory) {
        IPeekABoo.PeekABooTraits memory _peekaboo = peekaboo.getTokenTraits(
            tokenId
        );
        uint8 peekabooType = _peekaboo.isGhost ? 0 : 1;
        require(traitsToTry.length <= 7, "Trying too many traits");

        string[7] memory traits = [
            (traitData[0][0][_peekaboo.background]).svg,
            (traitData[peekabooType][1][_peekaboo.back]).svg,
            (traitData[peekabooType][2][_peekaboo.bodyColor]).svg,
            _peekaboo.isGhost
                ? (traitData[peekabooType][3][_peekaboo.clothesOrHelmet]).svg
                : (traitData[peekabooType][3][_peekaboo.hat]).svg,
            _peekaboo.isGhost
                ? (traitData[peekabooType][4][_peekaboo.hat]).svg
                : (traitData[peekabooType][4][_peekaboo.face]).svg,
            _peekaboo.isGhost
                ? (traitData[peekabooType][5][_peekaboo.face]).svg
                : (traitData[peekabooType][5][_peekaboo.clothesOrHelmet]).svg,
            _peekaboo.isGhost
                ? (traitData[peekabooType][6][_peekaboo.hands]).svg
                : ""
        ];

        for (uint256 i = 0; i < traitsToTry.length; i++) {
            if (traitsToTry[i][0] == 0) {
                traits[0] = (traitData[0][0][traitsToTry[i][1]]).svg;
            } else if (traitsToTry[i][0] == 1) {
                traits[1] = (traitData[peekabooType][1][traitsToTry[i][1]]).svg;
            } else if (traitsToTry[i][0] == 2) {
                traits[2] = (traitData[peekabooType][2][traitsToTry[i][1]]).svg;
            } else if (traitsToTry[i][0] == 3) {
                traits[3] = (traitData[peekabooType][3][traitsToTry[i][1]]).svg;
            } else if (traitsToTry[i][0] == 4) {
                traits[4] = (traitData[peekabooType][4][traitsToTry[i][1]]).svg;
            } else if (traitsToTry[i][0] == 5) {
                traits[5] = (traitData[peekabooType][5][traitsToTry[i][1]]).svg;
            } else if (traitsToTry[i][0] == 6) {
                traits[6] = (traitData[peekabooType][6][traitsToTry[i][1]]).svg;
            }
        }

        string memory svgString = string(
            abi.encodePacked(
                traits[0],
                traits[1],
                traits[2],
                traits[3],
                traits[4],
                traits[5],
                _peekaboo.isGhost ? traits[6] : ""
            )
        );

        return
            string(
                abi.encodePacked(
                    '<svg width="100%"',
                    // Strings.toString(width),
                    ' height="100%" viewBox="0 0 100 100"',
                    // Strings.toString(height),
                    ">",
                    svgString,
                    "</svg>"
                )
            );
    }

    function attributeForTypeAndValue(
        string memory traitType,
        string memory value
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    function attributeForTypeAndValue(string memory traitType, uint64 value)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    uint256(value).toString(),
                    '"}'
                )
            );
    }

    function compileAttributes(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        IPeekABoo.PeekABooTraits memory attr = peekaboo.getTokenTraits(tokenId);

        string memory traits;
        if (attr.isGhost) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        "Background",
                        traitData[0][0][attr.background].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Back",
                        traitData[0][1][attr.back].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "BodyColor",
                        traitData[0][2][attr.bodyColor].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Clothes",
                        traitData[0][3][attr.clothesOrHelmet].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Hat",
                        traitData[0][4][attr.hat].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Face",
                        traitData[0][5][attr.face].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Hands",
                        traitData[0][6][attr.hands].name
                    ),
                    ",",
                    attributeForTypeAndValue("Tier", attr.tier),
                    ",",
                    attributeForTypeAndValue("Level", attr.level)
                )
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        "Background",
                        traitData[0][0][attr.background].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Back",
                        traitData[1][1][attr.back].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "BodyColor",
                        traitData[1][2][attr.bodyColor].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Hat",
                        traitData[1][3][attr.hat].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Face",
                        traitData[1][4][attr.face].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Helmet",
                        traitData[1][5][attr.clothesOrHelmet].name
                    ),
                    ",",
                    attributeForTypeAndValue("Tier", attr.tier),
                    ",",
                    attributeForTypeAndValue("Level", attr.level)
                )
            );
        }
        return
            string(
                abi.encodePacked(
                    "[",
                    traits,
                    '{"trait_type":"Type","value":',
                    attr.isGhost ? '"Ghost"' : '"Buster"',
                    "}]"
                )
            );
    }

    function compileAttributesAsIDs(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        IPeekABoo.PeekABooTraits memory attr = peekaboo.getTokenTraits(tokenId);

        string memory traits;
        if (attr.isGhost) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        "Background",
                        attr.background.toString()
                    ),
                    ",",
                    attributeForTypeAndValue("Back", attr.back.toString()),
                    ",",
                    attributeForTypeAndValue(
                        "BodyColor",
                        attr.bodyColor.toString()
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Clothes",
                        attr.clothesOrHelmet.toString()
                    ),
                    ",",
                    attributeForTypeAndValue("Hat", attr.hat.toString()),
                    ",",
                    attributeForTypeAndValue("Face", attr.face.toString()),
                    ",",
                    attributeForTypeAndValue("Hands", attr.hands.toString()),
                    ","
                )
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        "Background",
                        attr.background.toString()
                    ),
                    ",",
                    attributeForTypeAndValue("Back", attr.back.toString()),
                    ",",
                    attributeForTypeAndValue(
                        "BodyColor",
                        attr.bodyColor.toString()
                    ),
                    ",",
                    attributeForTypeAndValue("Hat", attr.hat.toString()),
                    ",",
                    attributeForTypeAndValue("Face", attr.face.toString()),
                    ",",
                    attributeForTypeAndValue(
                        "Helmet",
                        attr.clothesOrHelmet.toString()
                    ),
                    ","
                )
            );
        }
        return
            string(
                abi.encodePacked(
                    "[",
                    traits,
                    '{"trait_type":"Type","value":',
                    attr.isGhost ? '"Ghost"' : '"Buster"',
                    "}]"
                )
            );
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        IPeekABoo.PeekABooTraits memory attr = peekaboo.getTokenTraits(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                attr.isGhost ? "Ghost #" : "Buster #",
                tokenId.toString(),
                '", "description": "Ghosts have come out to haunt the metaverse as the night awakes, Busters scramble to purge these ghosts and claim the bounties. Ghosts are accumulating $BOO, amassing it to grow their haunted grounds. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. The project is built on the Arbitrum L2.", "image": "data:image/svg+xml;base64,',
                bytes(drawSVG(tokenId, 512, 512)),
                '", "attributes":',
                compileAttributes(tokenId),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    bytes(metadata)
                )
            );
    }

    function setRarityIndex(
        uint256 ghostOrBuster,
        uint256 traitType,
        uint256[4] calldata traitIndices
    ) external onlyOwner {
        for (uint256 i = 0; i < 4; i++) {
            traitRarityIndex[ghostOrBuster][traitType][i] = traitIndices[i];
        }
    }

    function getRarityIndex(
        uint256 ghostOrBuster,
        uint256 traitType,
        uint256 rarity
    ) external returns (uint256) {
        return traitRarityIndex[ghostOrBuster][traitType][rarity];
    }
}

// SPDX-License-Identifier: MIT LICENSE
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITraits.sol";
import "./IPeekABoo.sol";

pragma solidity ^0.8.0;

contract TraitsBase {
    using Strings for uint256;

    IPeekABoo public peekaboo;
    mapping(uint256 => mapping(uint256 => ITraits.Trait))[2] public traitData;
    mapping(uint256 => uint256[4])[2] public traitRarityIndex;
}

// SPDX-License-Identifier: MIT LICENSE
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.0;

interface ITraits {
    struct Trait {
        string name;
        string svg;
    }

    /** ADMIN */
    function uploadTraits(
        uint256 ghostOrBuster,
        uint256 traitType,
        uint256[] calldata traitIds,
        Trait[] calldata traits
    ) external;

    function setPeekABoo(address _peekaboo) external;

    /** RENDER */
    function tryOutTraits(
        uint256 tokenId,
        uint256[2][] memory traitsToTry,
        uint256 width,
        uint256 height
    ) external view returns (string memory);

    function compileAttributesAsIDs(uint256 tokenId)
        external
        view
        returns (string memory);

    function setRarityIndex(
        uint256 ghostOrBuster,
        uint256 traitType,
        uint256[4] calldata traitIndices
    ) external;

    function getRarityIndex(
        uint256 ghostOrBuster,
        uint256 traitType,
        uint256 rarity
    ) external returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity >0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IPeekABoo is IERC721Upgradeable {
    struct PeekABooTraits {
        bool isGhost;
        uint256 background;
        uint256 back;
        uint256 bodyColor;
        uint256 hat;
        uint256 face;
        uint256 clothesOrHelmet;
        uint256 hands;
        uint64 ability;
        uint64 revealShape;
        uint64 tier;
        uint64 level;
    }

    struct GhostMap {
        uint256[10][10] grid;
        int256 gridSize;
        uint256 difficulty;
        bool initialized;
    }

    function devMint(address to, uint256[] memory types) external;

    function mint(uint256[] calldata types, bytes32[] memory proof) external;

    function publicMint(uint256[] calldata types) external payable;

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (PeekABooTraits memory);

    function setTokenTraits(
        uint256 tokenId,
        uint256 traitType,
        uint256 traitId
    ) external;

    function setMultipleTokenTraits(
        uint256 tokenId,
        uint256[] calldata traitTypes,
        uint256[] calldata traitIds
    ) external;

    function getGhostMapGridFromTokenId(uint256 tokenId)
        external
        view
        returns (GhostMap memory);

    function mintPhase2(
        uint256 tokenId,
        uint256[] memory types,
        uint256 amount,
        uint256 booAmount
    ) external;

    function incrementLevel(uint256 tokenId) external;

    function incrementTier(uint256 tokenId) external;

    function getPhase1Minted() external view returns (uint256 result);

    function getPhase2Minted() external view returns (uint256 result);

    function withdraw() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}