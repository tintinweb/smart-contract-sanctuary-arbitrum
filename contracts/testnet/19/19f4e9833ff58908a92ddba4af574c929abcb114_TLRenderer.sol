//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../interfaces/ITLRenderer.sol";
import "./TLRendererState.sol";
import "../shared/Base64.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


contract TLRenderer is ITLRenderer, TLRendererState {

    using StringsUpgradeable for uint256;
	function initialize() external initializer {
		TLRendererState.__TLRendererState_init();
	}

    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Draw {
        uint8 length;
        uint8 colorIndex;
    }

    struct DecodedImage {
        ContentBounds bounds;
        Draw[] draws;
    }

    /**
	* Given RLE image data and color palette pointers, merge to generate a single SVG image.
    */
    // function generateSVG(SVGUtils.SVGParams calldata params) external pure returns (string memory svg) {
    //     if (bytes(params.background).length != 0) {
    //         // prettier-ignore
    //         return string(
    //             abi.encodePacked(
    //                 _SVG_START_TAG,
    //                 '<rect width="100%" height="100%" fill="#', params.background, '" />',
    //                 _generateSVGRects(params),
    //                 _SVG_END_TAG
    //             )
    //         );
    //     }
    //     return string(abi.encodePacked(_SVG_START_TAG, _generateSVGRects(params), _SVG_END_TAG));
    // }

    // function generateSVG(SVGUtils.SVGParams calldata params) 
    //     external 
    //     pure returns (string memory svg)
    // {
    //     return
    //         abi.encodePacked(
    //             '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="smol" width="100%" height="100%" version="1.1" viewBox="0 0 360 360" ',
    //             'style="background-color: transparent;background-image:url(',
    //             generatePNGFromTraitId(_smol.mouth, _smol.gender, 0), //image
    //             "),url(",
    //             generatePNGFromTraitId(_smol.hat, _smol.gender, _smol.headSize), //background
    //             "),url(",
    //             generatePNGFromTraitId(_smol.glasses, _smol.gender, 0), //body
    //             "),url(",
    //             generatePNGFromTraitId(_smol.clothes, _smol.gender, 0), //eyes
    //             "),url(",
    //             generatePNGFromTraitId(_smol.hair, _smol.gender, _smol.headSize), //look 
    //             "),url(",
    //             generatePNGFromTraitId(_smol.body, _smol.gender, _smol.headSize), //mouth
    //             "),url(",
    //             generatePNGFromTraitId(_smol.background, _smol.gender, 0),
    //             ')"',
    //             ">",
    //             "<style>#smol {background-repeat: no-repeat;background-size: contain;background-position: center;image-rendering: -webkit-optimize-contrast;-ms-interpolation-mode: nearest-neighbor;image-rendering: -moz-crisp-edges;image-rendering: pixelated;}</style></svg>"
    //         );
    // }

    function generateSVG(SVGUtils.SVGParams calldata params) 
        public 
        override
        view 
        returns (bytes memory svg)
    {
        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="smol" width="100%" height="100%" version="1.1" viewBox="0 0 360 360" ',
                'style="background-color: transparent;background-image:url(',
                params.parts[0].image,
                "),url(",
                params.parts[1].image,
                "),url(",
                params.parts[2].image,
                "),url(",
                params.parts[3].image,
                ')"',
                ">",
                "<style>#smol {background-repeat: no-repeat;background-size: contain;background-position: center;image-rendering: -webkit-optimize-contrast;-ms-interpolation-mode: nearest-neighbor;image-rendering: -moz-crisp-edges;image-rendering: pixelated;}</style></svg>"
            );

        // return abi.encodePacked(
        //         '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect width="100%" height="100%" fill="red" /></svg>'
        //     );
    }

    function tokenURI(uint256 _tokenId, SVGUtils.SVGParams calldata params) 
        external 
        view 
        override 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                            '{"id": ', _tokenId.toString(), ',',
                            '"name": "Lost Donkey #', _tokenId.toString(), '",',
                            '"image": "data:image/svg+xml;base64,', 
                            Base64.encode(generateSVG(params)), 
                            '","attributes": [',
                            // _getTraitMetadataString(_tokenId, BACKGROUND), ',',
                            // _getTraitMetadataString(_tokenId, BODY), ',',
                            // _getTraitMetadataString(_tokenId, EYES), ',', 
                            // _getTraitMetadataString(_tokenId, LOOK), ',',
                            _getTraitMetadataString(_tokenId, "MOUTH"),
                            // _getTraitMetadataString(_tokenId, GENDER), ',',
                            // _getTraitMetadataString(_tokenId, ACCESSORY), ',',
                            // _getTraitMetadataString(_tokenId, OUTFIT), ',',
                            // _getTraitMetadataString(_tokenId, FOOD), ',',
                            // _getTraitMetadataString(_tokenId, FACIALHAIR),
                            ']}'
                        )
                )
            )
        );
    }


    function _getTraitMetadataString(uint256 _tokenId, string memory _traitType) private view returns (string memory) {
        return string(
         abi.encodePacked(
            '{"trait_type": "', _traitType, '", ',
            '"value": "',_getTraitValueName(_tokenId, _traitType),
            '"}'
        ));
    }

    function _getTraitValueName(uint256 _tokenId, string memory _traitType) private view returns (string memory) {
        return string("braces");
    }

        // function generatePNGFromTraitId(uint256 _tokenId)
    //     public
    //     view
    //     returns (string memory)
    // {

    // }


    // function _getRegionAttributesForBarnJSON(uint256 _tokenId) private view returns (string memory) {
    //     BarnType barnType = tokenIdToBarnType[_tokenId];
    //     return string(
    //      abi.encodePacked(
    //         '{"trait_type": "Region",',
    //         '"value": "',getBarnRegionText(barnType),
    //         '"}'
    //     ));
    // }

    /**
     * Given RLE image data and a color palette pointer, merge to generate a partial SVG image.
     */
    // function generateSVGPart(SVGUtils.SVGPart calldata part) external pure returns (string memory partialSVG) {
    //     SVGUtils.SVGPart[] memory parts = new SVGUtils.SVGPart[](1);
    //     parts[0] = part;

    //     return _generateSVGRects(SVGUtils.SVGParams({ parts: parts, background: '' }));
    // }

    // /**
    //  * Given RLE image data and color palette pointers, merge to generate a partial SVG image.
    //  */
    // function generateSVGParts(SVGUtils.SVGPart[] calldata parts) external pure returns (string memory partialSVG) {
    //     return _generateSVGRects(SVGUtils.SVGParams({ parts: parts, background: '' }));
    // }

    // /**
    //  * Given RLE image parts and color palettes, generate SVG rects.
    //  */
    // // prettier-ignore
    // function _generateSVGRects(SVGUtils.SVGParams memory params)
    //     private
    //     pure
    //     returns (string memory svg)
    // {
    //     string[33] memory lookup = [
    //         '0', '10', '20', '30', '40', '50', '60', '70', 
    //         '80', '90', '100', '110', '120', '130', '140', '150', 
    //         '160', '170', '180', '190', '200', '210', '220', '230', 
    //         '240', '250', '260', '270', '280', '290', '300', '310',
    //         '320'
    //     ];
    //     string memory rects;
    //     string[] memory cache;
    //     for (uint8 p = 0; p < params.parts.length; p++) {
    //         cache = new string[](256); // Initialize color cache

    //         DecodedImage memory image = _decodeRLEImage(params.parts[p].image);
    //         bytes memory palette = params.parts[p].palette;
    //         uint256 currentX = image.bounds.left;
    //         uint256 currentY = image.bounds.top;
    //         uint256 cursor;
    //         string[16] memory buffer;

    //         string memory part;
    //         for (uint256 i = 0; i < image.draws.length; i++) {
    //             Draw memory draw = image.draws[i];

    //             uint8 length = _getRectLength(currentX, draw.length, image.bounds.right);
    //             while (length > 0) {
    //                 if (draw.colorIndex != 0) {
    //                     buffer[cursor] = lookup[length];                                 // width
    //                     buffer[cursor + 1] = lookup[currentX];                           // x
    //                     buffer[cursor + 2] = lookup[currentY];                           // y
    //                     buffer[cursor + 3] = _getColor(palette, draw.colorIndex, cache); // color

    //                     cursor += 4;

    //                     if (cursor >= 16) {
    //                         part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
    //                         cursor = 0;
    //                     }
    //                 }

    //                 currentX += length;
    //                 if (currentX == image.bounds.right) {
    //                     currentX = image.bounds.left;
    //                     currentY++;
    //                 }

    //                 draw.length -= length;
    //                 length = _getRectLength(currentX, draw.length, image.bounds.right);
    //             }
    //         }

    //         if (cursor != 0) {
    //             part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
    //         }
    //         rects = string(abi.encodePacked(rects, part));
    //     }
    //     return rects;
    // }

    // /**
    //  * Given an x-coordinate, draw length, and right bound, return the draw
    //  * length for a single SVG rectangle.
    //  */
    // function _getRectLength(
    //     uint256 currentX,
    //     uint8 drawLength,
    //     uint8 rightBound
    // ) private pure returns (uint8) {
    //     uint8 remainingPixelsInLine = rightBound - uint8(currentX);
    //     return drawLength <= remainingPixelsInLine ? drawLength : remainingPixelsInLine;
    // }

    // /**
    //  * Return a string that consists of all rects in the provided `buffer`.
    //  */
    // // prettier-ignore
    // function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
    //     string memory chunk;
    //     for (uint256 i = 0; i < cursor; i += 4) {
    //         chunk = string(
    //             abi.encodePacked(
    //                 chunk,
    //                 '<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
    //             )
    //         );
    //     }
    //     return chunk;
    // }

    // /**
    //  * Decode a single RLE compressed image into a `DecodedImage`.
    //  */
    // function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
    //     ContentBounds memory bounds = ContentBounds({
    //         top: uint8(image[1]),
    //         right: uint8(image[2]),
    //         bottom: uint8(image[3]),
    //         left: uint8(image[4])
    //     });

    //     uint256 cursor;
    //     Draw[] memory draws = new Draw[]((image.length - 5) / 2);
    //     for (uint256 i = 5; i < image.length; i += 2) {
    //         draws[cursor] = Draw({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
    //         cursor++;
    //     }
    //     return DecodedImage({ bounds: bounds, draws: draws });
    // }

    // /**
    //  * Get the target hex color code from the cache. Populate the cache if
    //  * the color code does not yet exist.
    //  */
    // function _getColor(
    //     bytes memory palette,
    //     uint256 index,
    //     string[] memory cache
    // ) private pure returns (string memory) {
    //     if (bytes(cache[index]).length == 0) {
    //         uint256 i = index * _INDEX_TO_BYTES3_FACTOR;
    //         cache[index] = _toHexString(abi.encodePacked(palette[i], palette[i + 1], palette[i + 2]));
    //     }
    //     return cache[index];
    // }

    // /**
    //  * @dev Convert `bytes` to a 6 character ASCII `string` hexadecimal representation.
    //  */
    // function _toHexString(bytes memory b) private pure returns (string memory) {
    //     uint24 value = uint24(bytes3(b));

    //     bytes memory buffer = new bytes(6);
    //     buffer[5] = _HEX_SYMBOLS[value & 0xf];
    //     buffer[4] = _HEX_SYMBOLS[(value >> 4) & 0xf];
    //     buffer[3] = _HEX_SYMBOLS[(value >> 8) & 0xf];
    //     buffer[2] = _HEX_SYMBOLS[(value >> 12) & 0xf];
    //     buffer[1] = _HEX_SYMBOLS[(value >> 16) & 0xf];
    //     buffer[0] = _HEX_SYMBOLS[(value >> 20) & 0xf];
    //     return string(buffer);
    // }

    //generate metadata
    //token URI
    //
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../shared/SVGUtils.sol";

interface ITLRenderer {
	
	function generateSVG(SVGUtils.SVGParams memory params) external view returns (bytes memory svg);

	// function generateSVGPart(SVGUtils.SVGPart memory part) external view returns (string memory partialSVG);

	// function generateSVGParts(SVGUtils.SVGPart[] memory parts) external view returns (string memory partialSVG);

	function tokenURI(uint256 _tokenId, SVGUtils.SVGParams calldata params) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../shared/AdminableUpgradeable.sol";

abstract contract TLRendererState is Initializable, AdminableUpgradeable {


	//Events

	//Errors

	//Constants
	bytes16 public constant _HEX_SYMBOLS = '0123456789abcdef';
	uint256 public constant _INDEX_TO_BYTES3_FACTOR = 3;
    
	string public constant _SVG_START_TAG = '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">';
	string public constant _SVG_END_TAG = '</svg>';

	string public constant BACKGROUND = "BG";
 	// string public constant BODY = "B";
 	// string public constant EYES = "E";
 	// string public constant LOOK = "L";
 	// string public constant MOUTH = "M";
 	// string public constant GENDER = "G";
 	// string public constant ACCESSORY = "A";
 	// string public constant OUTFIT = "O";
 	// string public constant FOOD = "F";
 	// string public constant FACIALHAIR = "FH";
 	string public constant POUND = "#";

	function __TLRendererState_init() internal initializer {
		AdminableUpgradeable.__Adminable_init();
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


contract SVGUtils {
    struct Seed {
		uint48 id;
		uint48 name;
		uint48 image;
		uint48 background;
		uint48 body;
		uint48 eyes;
		uint48 look;
		uint48 mouth;
		uint48 gender;
		uint48 accessory;
		uint48 outfit;
		uint48 food;
		uint48 facialHair;
	}

	struct Context {
		string tokenType;
	}

	struct SVGPart {
        bytes image;
        bytes palette;
    }

    struct SVGParams {
        SVGPart[] parts;
        string background;
    }

    string public constant BACKGROUND = "BG";
 	string public constant BODY = "B";
 	string public constant EYES = "E";
 	string public constant LOOK = "L";
 	string public constant MOUTH = "M";
 	string public constant GENDER = "G";
 	string public constant ACCESSORY = "A";
 	string public constant OUTFIT = "O";
 	string public constant FOOD = "F";
 	string public constant FACIALHAIR = "FH";
 	string public constant POUND = "#";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {
    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.2;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint256[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(
        uint256[] memory _array1,
        uint256[] memory _array2
    ) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns (bool) {
        return owner() == msg.sender;
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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