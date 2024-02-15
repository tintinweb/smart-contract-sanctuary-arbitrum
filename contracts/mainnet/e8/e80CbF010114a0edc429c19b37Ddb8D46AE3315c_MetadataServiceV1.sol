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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

struct Metadata {
    uint256 crowdtainerId;
    uint256 tokenId;
    address currentOwner;
    bool claimed;
    uint256[] unitPricePerType;
    uint256[] quantities;
    string[] productDescription;
    uint256 numberOfProducts;
}

/**
 * @dev Metadata service used to provide URI for a voucher / token id.
 */
interface IMetadataService {
    function uri(Metadata memory) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./IMetadataService.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/* solhint-disable quotes */

contract MetadataServiceV1 is IMetadataService {
    using Strings for uint256;
    using Strings for uint24;
    using Strings for uint8;

    uint24 internal constant yIncrement = 1;
    uint24 internal constant yStartingPoint = 10;
    uint24 internal constant anchorX = 1;

    uint8 private erc20Decimals;

    string private unitSymbol;
    string private ticketFootnotes;

    function generateSVGProductDescription(
        uint256 quantities,
        uint256 price,
        string memory _unitSymbol,
        string memory description
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    quantities.toString(),
                    unicode"\t",
                    "x ",
                    unicode"\t",
                    description,
                    unicode"\t",
                    " - ",
                    unicode"\t",
                    price.toString(),
                    unicode"\t",
                    _unitSymbol
                )
            );
    }

    function generateProductList(
        Metadata calldata _metadata,
        string memory _unitSymbol,
        uint8 _erc20Decimals
    ) internal pure returns (string memory productList, uint256 totalCost) {
        uint256 newY = yStartingPoint;

        for (uint24 i = 0; i < _metadata.numberOfProducts; i++) {
            if (_metadata.quantities[i] == 0) {
                continue;
            }

            productList = string(
                abi.encodePacked(
                    productList,
                    '<text xml:space="preserve" class="small" x="',
                    anchorX.toString(),
                    '" y="',
                    newY.toString(),
                    '" transform="matrix(16.4916,0,0,15.627547,7.589772,6.9947903)">',
                    generateSVGProductDescription(
                        _metadata.quantities[i],
                        _metadata.unitPricePerType[i] / (10**_erc20Decimals),
                        _unitSymbol,
                        _metadata.productDescription[i]
                    ),
                    "</text>"
                )
            );

            if (i < _metadata.numberOfProducts) {
                newY += yIncrement;
            }

            totalCost +=
                _metadata.unitPricePerType[i] *
                _metadata.quantities[i];
        }

        return (productList, totalCost / 10**_erc20Decimals);
    }

    function getSVGHeader() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg width="100mm" height="130mm" viewBox="0 0 300 430" version="1.1" id="svg5" '
                    'class="svgBody" xmlns="http://www.w3.org/2000/svg">'
                    '<g id="layer1">'
                    '<path id="path2" style="color:#000000;fill:url(#SvgjsLinearGradient2561);fill-opacity:0.899193;fill-rule:evenodd;stroke-width:1.54543;-inkscape-stroke:none" '
                    'd="m32.202 12.58q-26.5047-.0216-26.4481 26.983l0 361.7384q.0114 11.831 15.7269 11.7809h76.797c-.1609-1.7418-.6734-11.5291 '
                    "8.1908-11.0679.1453.008.3814.0165.5275.0165h90.8068c.1461 0 .383-.005.5291-.005 6.7016-.006 7.7083 9.3554 "
                    "7.836 11.0561.0109.1453.1352.2634.2813.2634l80.0931 0q12.2849.02 12.2947-12.2947v-361.7669q-.1068-26.9614-26.4482-26.9832h-66.2794c.003 "
                    '12.6315.0504 9.5559-54.728 9.546-48.348.0106-51.5854 2.1768-51.8044-9.7542z"/>'
                    '<text xml:space="preserve" class="medium" x="10.478354" y="0" id="text16280-6-9" transform="matrix(16.4916,0,0,15.627547,7.1325211,54.664932)">',
                    '<tspan x="15.478354" y="1">Crowdtainer '
                )
            );
    }

    function getSVGFooter() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<style>.svgBody {font-family: "Helvetica" }'
                    ".tiny {font-stretch:normal;font-size:0.525624px;line-height:1.25;text-anchor:end;white-space:pre;fill:#f9f9f9;}"
                    ".footer {font-stretch:normal;font-size:7px;line-height:.25;white-space:pre;fill:#f9f9f9;}"
                    ".small {font-size:0.5px;text-align:start;text-anchor:start;white-space:pre;fill:#f9f9f9;}"
                    ".medium {font-size:0.92px;"
                    "font-family:Helvetica;text-align:end;text-anchor:end;white-space:pre;"
                    "fill:#f9f9f9;}</style>"
                    "<linearGradient x1='0%' y1='30%' x2='60%' y2='90%' gradientUnits='userSpaceOnUse' id='SvgjsLinearGradient2561'>"
                    "<stop stop-color='rgba(20, 110, 160, 100)' offset='0.02'></stop>"
                    "<stop stop-color='rgba(25, 59, 90, 100)' offset='1'></stop></linearGradient>"
                    "</svg>"
                )
            );
    }

    function getSVGTotalCost(uint256 totalCost, uint256 numberOfProuducts)
        internal
        pure
        returns (string memory)
    {
        uint256 totalCostYShift = yStartingPoint +
            yIncrement *
            numberOfProuducts;

        return
            string(
                abi.encodePacked(
                    '<text xml:space="preserve" class="small" ',
                    'x="2" y="',
                    totalCostYShift.toString(),
                    '" transform="matrix(16.4916,0,0,15.627547,7.589772,6.9947903)">',
                    "Total ",
                    unicode"＄",
                    totalCost.toString(),
                    "</text>"
                )
            );
    }

    function getSVGClaimedInformation(bool claimedStatus)
        internal
        pure
        returns (string memory)
    {
        string
            memory part1 = '<text xml:space="preserve" class="tiny" x="10.478354" y="0" id="text16280-6-9-7" '
            'transform="matrix(16.4916,0,0,15.627547,5.7282884,90.160098)"><tspan x="15.478354" '
            'y="1.5" id="tspan1163">Claimed: ';
        string
            memory part2 = '</tspan></text><text xml:space="preserve" class="medium" '
            'x="13.478354" y="14.1689944" id="text16280-6" transform="matrix(16.4916,0,0,15.627547,7.589772,6.9947903)">'
            '<tspan x="15.478354" y="5.4" id="tspan1165">Voucher ';
        if (claimedStatus) {
            return string(abi.encodePacked(part1, "Yes", part2));
        } else {
            return string(abi.encodePacked(part1, "No", part2));
        }
    }

    function generateImage(
        Metadata calldata _metadata,
        string memory _ticketFootnotes
    ) internal view returns (string memory) {
        string memory description;
        uint256 totalCost;

        (description, totalCost) = generateProductList(
            _metadata,
            unitSymbol,
            erc20Decimals
        );

        return
            string(
                abi.encodePacked(
                    getSVGHeader(),
                    _metadata.crowdtainerId.toString(),
                    "</tspan></text>",
                    getSVGClaimedInformation(_metadata.claimed),
                    _metadata.tokenId.toString(),
                    "</tspan></text>",
                    description,
                    getSVGTotalCost(totalCost, _metadata.numberOfProducts),
                    '<text xml:space="preserve" class="footer" x="85" y="390" transform="scale(1.0272733,0.97345081)">',
                    _ticketFootnotes,
                    "</text></g>",
                    getSVGFooter()
                )
            );
    }

    constructor(
        string memory _unitSymbol,
        uint8 _erc20Decimals,
        string memory _ticketFootnotes
    ) {
        unitSymbol = _unitSymbol;
        erc20Decimals = _erc20Decimals;
        ticketFootnotes = _ticketFootnotes;
    }

    /**
     * @dev Return a DATAURI containing a voucher SVG representation of the given tokenId.
     * @param _metadata Address that represents the product or service provider.
     * @return The voucher image in SVG, in data URI scheme.
     */
    function uri(Metadata calldata _metadata)
        external
        view
        returns (string memory)
    {
        string memory productList = "[";
        uint256 totalCost;

        for (uint256 i = 0; i < _metadata.numberOfProducts; i++) {
            productList = string(
                abi.encodePacked(
                    productList,
                    '{"description":"',
                    _metadata.productDescription[i],
                    '","amount":"',
                    _metadata.quantities[i].toString(),
                    '","pricePerUnit":"',
                    _metadata.unitPricePerType[i].toString(),
                    '"}'
                )
            );

            if (i < _metadata.numberOfProducts - 1) {
                productList = string(abi.encodePacked(productList, ", "));
            }
            totalCost +=
                _metadata.unitPricePerType[i] *
                _metadata.quantities[i];
        }

        productList = string(abi.encodePacked(productList, "]"));

        string memory description = string(
            abi.encodePacked(
                productList,
                ', "TotalCost":"',
                totalCost.toString(),
                '"'
            )
        );

        string memory image = Base64.encode(
            bytes(generateImage(_metadata, ticketFootnotes))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"crowdtainerId":"',
                                _metadata.crowdtainerId.toString(),
                                '", "voucherId":"',
                                _metadata.tokenId.toString(),
                                '", "currentOwner":"',
                                addressToString(_metadata.currentOwner),
                                '", ',
                                '"erc20Symbol":"',
                                unitSymbol,
                                '", "erc20Decimals":"',
                                erc20Decimals.toString(),
                                '", "description":',
                                description,
                                ', "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        return Strings.toHexString(uint256(uint160(_address)), 20);
    }
}
/* solhint-enable quotes */