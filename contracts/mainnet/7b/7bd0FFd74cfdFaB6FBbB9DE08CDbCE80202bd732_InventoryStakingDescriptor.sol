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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.15;

import {Base64} from "base64-sol/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {HexStrings} from "@uni-periphery/libraries/HexStrings.sol";

contract InventoryStakingDescriptor {
    using Strings for uint256;
    using HexStrings for uint256;

    // =============================================================
    //                        CONSTANTS
    // =============================================================

    string internal constant PREFIX = "x";

    // =============================================================
    //                        INTERNAL
    // =============================================================

    function renderSVG(
        uint256 tokenId,
        uint256 vaultId,
        address vToken,
        string calldata vTokenSymbol,
        uint256 vTokenBalance,
        uint256 wethBalance,
        uint256 timelockLeft
    ) public pure returns (string memory) {
        return
            string.concat(
                '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                getDefs(
                    tokenToColorHex(uint256(uint160(vToken)), 136),
                    tokenToColorHex(uint256(uint160(vToken)), 100)
                ),
                '<g mask="url(#fade-symbol)">',
                text("32", "70", "200", "32"),
                PREFIX,
                vTokenSymbol,
                "</text>",
                underlyingBalances(vTokenSymbol, vTokenBalance, wethBalance),
                '<rect x="16" y="16" width="258" height="468" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"/>',
                infoTags(tokenId, vaultId, timelockLeft),
                "</svg>"
            );
    }

    function tokenURI(
        uint256 tokenId,
        uint256 vaultId,
        address vToken,
        string calldata vTokenSymbol,
        uint256 vTokenBalance,
        uint256 wethBalance,
        uint256 timelockedUntil
    ) external view returns (string memory) {
        string memory image = Base64.encode(
            bytes(
                renderSVG(
                    tokenId,
                    vaultId,
                    vToken,
                    vTokenSymbol,
                    vTokenBalance,
                    wethBalance,
                    block.timestamp > timelockedUntil
                        ? 0
                        : timelockedUntil - block.timestamp
                )
            )
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name":"',
                            string.concat(
                                "x",
                                vTokenSymbol,
                                " #",
                                tokenId.toString()
                            ),
                            '", "description":"',
                            "xNFT representing inventory staking position on NFTX",
                            '", "image": "',
                            "data:image/svg+xml;base64,",
                            image,
                            '", "attributes": [{"trait_type": "VaultId", "value": "',
                            vaultId.toString(),
                            '"}]}'
                        )
                    )
                )
            );
    }

    // =============================================================
    //                        PRIVATE
    // =============================================================

    function getDefs(
        string memory color2,
        string memory color3
    ) private pure returns (string memory) {
        return
            string.concat(
                "<defs>",
                '<filter id="f1"><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='16' cy='232' r='120px' fill='#",
                            color2,
                            "'/></svg>"
                        )
                    )
                ),
                '"/><feImage result="p3" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='20' cy='100' r='130px' fill='#",
                            color3,
                            "'/></svg>"
                        )
                    )
                ),
                '"/><feBlend mode="exclusion" in2="p2"/><feBlend mode="overlay" in2="p3" result="blendOut"/><feGaussianBlur in="blendOut" stdDeviation="42"/></filter><clipPath id="corners"><rect width="290" height="500" rx="42" ry="42"/></clipPath><filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24"/></filter><linearGradient id="grad-symbol"><stop offset="0.7" stop-color="white" stop-opacity="1"/><stop offset=".95" stop-color="white" stop-opacity="0"/></linearGradient><mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290px" height="200px" fill="url(#grad-symbol)"/></mask></defs>',
                '<g clip-path="url(#corners)"><rect fill="2c9715" x="0px" y="0px" width="290px" height="500px"/><rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="500px"/><g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;"><rect fill="none" x="0px" y="0px" width="290px" height="500px"/><ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85"/></g><rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"/></g>'
            );
    }

    function text(
        string memory x,
        string memory y,
        string memory fontWeight,
        string memory fontSize
    ) private pure returns (string memory) {
        return text(x, y, fontWeight, fontSize, false);
    }

    function text(
        string memory x,
        string memory y,
        string memory fontWeight,
        string memory fontSize,
        bool onlyMonospace
    ) private pure returns (string memory) {
        return
            string.concat(
                '<text y="',
                y,
                'px" x="',
                x,
                'px" fill="white" font-family="',
                !onlyMonospace ? "'Courier New', " : "",
                'monospace" font-weight="',
                fontWeight,
                '" font-size="',
                fontSize,
                'px">'
            );
    }

    function tokenToColorHex(
        uint256 token,
        uint256 offset
    ) private pure returns (string memory str) {
        return string((token >> offset).toHexStringNoPrefix(3));
    }

    function balanceTag(
        string memory y,
        uint256 tokenBalance,
        string memory tokenSymbol
    ) private pure returns (string memory) {
        uint256 beforeDecimal = tokenBalance / 1 ether;
        string memory afterDecimals = getAfterDecimals(tokenBalance);

        uint256 leftPadding = 12;
        uint256 beforeDecimalFontSize = 20;
        uint256 afterDecimalFontSize = 16;

        uint256 width = leftPadding +
            ((getDigitsCount(beforeDecimal) + 1) * beforeDecimalFontSize) /
            2 +
            (bytes(afterDecimals).length * afterDecimalFontSize * 100) /
            100;

        return
            string.concat(
                '<g style="transform:translate(29px, ',
                y,
                'px)"><rect width="',
                width.toString(),
                'px" height="30px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)"/>',
                text(
                    leftPadding.toString(),
                    "21",
                    "100",
                    beforeDecimalFontSize.toString(),
                    true
                ),
                beforeDecimal.toString(),
                '.<tspan font-size="',
                afterDecimalFontSize.toString(),
                'px">',
                afterDecimals,
                '</tspan> <tspan fill="rgba(255,255,255,0.8)">',
                tokenSymbol,
                "</tspan></text></g>"
            );
    }

    function infoTag(
        string memory y,
        string memory label,
        string memory value
    ) private pure returns (string memory) {
        return
            string.concat(
                '<g style="transform:translate(29px, ',
                y,
                'px)"><rect width="98px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)"/>',
                text("12", "17", "100", "12"),
                '<tspan fill="rgba(255,255,255,0.6)">',
                label,
                ": </tspan>",
                value,
                "</text></g>"
            );
    }

    function underlyingBalances(
        string memory vTokenSymbol,
        uint256 vTokenBalance,
        uint256 wethBalance
    ) private pure returns (string memory) {
        return
            string.concat(
                text("32", "160", "200", "16"),
                "Underlying Balance</text></g>",
                balanceTag("180", vTokenBalance, vTokenSymbol),
                balanceTag("220", wethBalance, "WETH")
            );
    }

    function infoTags(
        uint256 tokenId,
        uint256 vaultId,
        uint256 timelockLeft
    ) private pure returns (string memory) {
        return
            string.concat(
                infoTag("384", "ID", tokenId.toString()),
                infoTag("414", "VaultId", vaultId.toString()),
                infoTag(
                    "444",
                    "Timelock",
                    timelockLeft > 0
                        ? string.concat(timelockLeft.toString(), "s left")
                        : "Unlocked"
                )
            );
    }

    function getDigitsCount(uint256 num) private pure returns (uint256 count) {
        if (num == 0) return 1;

        while (num > 0) {
            ++count;
            num /= 10;
        }
    }

    function getAfterDecimals(
        uint256 tokenBalance
    ) private pure returns (string memory afterDecimals) {
        uint256 afterDecimal = (tokenBalance % 1 ether) / 10 ** (18 - 10); // show 10 decimals

        uint256 leadingZeroes;
        if (afterDecimal == 0) {
            leadingZeroes = 0;
        } else {
            leadingZeroes = 10 - getDigitsCount(afterDecimal);
        }

        afterDecimals = afterDecimal.toString();
        for (uint256 i; i < leadingZeroes; ) {
            afterDecimals = string.concat("0", afterDecimals);

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    /// @notice Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}