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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "contracts/interfaces/ISmartVault.sol";

interface INFTMetadataGenerator {
    function generateNFTMetadata(uint256 _tokenId, ISmartVault.Status memory _vaultStatus) external pure returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "contracts/interfaces/ITokenManager.sol";

interface ISmartVault {
    struct Asset { ITokenManager.Token token; uint256 amount; uint256 collateralValue; }
    struct Status { 
        address vaultAddress; uint256 minted; uint256 maxMintable; uint256 totalCollateralValue;
        Asset[] collateral; bool liquidated; uint8 version; bytes32 vaultType;
    }

    function status() external view returns (Status memory);
    function undercollateralised() external view returns (bool);
    function setOwner(address _newOwner) external;
    function liquidate() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ITokenManager {
    struct Token { bytes32 symbol; address addr; uint8 dec; address clAddr; uint8 clDec; }

    function getAcceptedTokens() external view returns (Token[] memory);

    function getToken(bytes32 _symbol) external view returns (Token memory);

    function getTokenIfExists(address _tokenAddr) external view returns (Token memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/interfaces/ISmartVault.sol";
import "contracts/interfaces/INFTMetadataGenerator.sol";

contract NFTMetadataGenerator is INFTMetadataGenerator {
    using Strings for uint256;
    using Strings for uint16;

    uint16 private constant TABLE_ROW_HEIGHT = 67;
    uint16 private constant TABLE_ROW_WIDTH = 1235;
    uint16 private constant TABLE_INITIAL_Y = 460;
    uint16 private constant TABLE_INITIAL_X = 357;
    uint32 private constant HUNDRED_PC = 1e5;

    struct Gradient { bytes32 colour1; bytes32 colour2; bytes32 colour3; }
    struct CollateralForSVG { string text; uint256 size; }

    function toShortString(bytes32 _data) pure private returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint8 i = 0; i < 32; i++) {
            bytes1 char = _data[i];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint8 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function padFraction(bytes memory _input, uint8 _dec) private pure returns (bytes memory fractionalPartPadded) {
        fractionalPartPadded = new bytes(_dec);
        uint256 i = fractionalPartPadded.length;
        uint256 j = _input.length;
        bool smallestCharacterAppended;
        while(i > 0) {
            i--;
            if (j > 0) {
                j--;
                if (_input[j] != bytes1("0") || smallestCharacterAppended) {
                    fractionalPartPadded[i] = _input[j];
                    smallestCharacterAppended = true;
                } else {
                    fractionalPartPadded = new bytes(fractionalPartPadded.length - 1);
                }
            } else {
                fractionalPartPadded[i] = "0";
            }
        }
    }

    function truncateFraction(bytes memory _input, uint8 _places) private pure returns (bytes memory truncated) {
        truncated = new bytes(_places);
        for (uint256 i = 0; i < _places; i++) {
            truncated[i] = _input[i];
        }
    }

    function toDecimalString(uint256 _amount, uint8 _inputDec) private pure returns (string memory) {
        uint8 maxDecPlaces = 5;
        string memory wholePart = (_amount / 10 ** _inputDec).toString();
        uint256 fraction = _amount % 10 ** _inputDec;
        if (fraction == 0) return wholePart;
        bytes memory fractionalPart = bytes(fraction.toString());
        bytes memory fractionalPartPadded = padFraction(fractionalPart, _inputDec);
        if (fractionalPartPadded.length > maxDecPlaces) fractionalPartPadded = truncateFraction(fractionalPartPadded, maxDecPlaces);
        return string(abi.encodePacked(wholePart, ".", fractionalPartPadded));
    }

    function mapCollateralForJSON(ISmartVault.Asset[] memory _collateral) private pure returns (string memory collateralTraits) {
        collateralTraits = "";
        for (uint256 i = 0; i < _collateral.length; i++) {
            ISmartVault.Asset memory asset = _collateral[i];
            collateralTraits = string(abi.encodePacked(collateralTraits, '{"trait_type":"', toShortString(asset.token.symbol), '", ','"display_type": "number",','"value": ',toDecimalString(asset.amount, asset.token.dec),'},'));
        }
    }

    function mapCollateralForSVG(ISmartVault.Asset[] memory _collateral) private pure returns (CollateralForSVG memory) {
        string memory displayText = "";
        uint256 paddingTop = 50;
        uint256 paddingLeftSymbol = 22;
        uint256 paddingLeftAmount = paddingLeftSymbol + 250;
        uint256 collateralSize = 0;
        for (uint256 i = 0; i < _collateral.length; i++) {
            ISmartVault.Asset memory asset = _collateral[i];
            uint256 xShift = collateralSize % 2 == 0 ? 0 : TABLE_ROW_WIDTH >> 1;
            if (asset.amount > 0) {
                uint256 currentRow = collateralSize >> 1;
                uint256 textYPosition = TABLE_INITIAL_Y + currentRow * TABLE_ROW_HEIGHT + paddingTop;
                displayText = string(abi.encodePacked(displayText,
                    "<g>",
                        "<text class='cls-8' transform='translate(",(TABLE_INITIAL_X + xShift + paddingLeftSymbol).toString()," ",textYPosition.toString(),")'>",
                            "<tspan x='0' y='0'>",toShortString(asset.token.symbol),"</tspan>",
                        "</text>",
                        "<text class='cls-8' transform='translate(",(TABLE_INITIAL_X + xShift + paddingLeftAmount).toString()," ",textYPosition.toString(),")'>",
                            "<tspan x='0' y='0'>",toDecimalString(asset.amount, asset.token.dec),"</tspan>",
                        "</text>",
                    "</g>"
                ));
                collateralSize++;
            }
        }
        if (collateralSize == 0) {
            displayText = string(abi.encodePacked(
                "<g>",
                    "<text class='cls-8' transform='translate(",(TABLE_INITIAL_X + paddingLeftSymbol).toString()," ",(TABLE_INITIAL_Y + paddingTop).toString(),")'>",
                        "<tspan x='0' y='0'>N/A</tspan>",
                    "</text>",
                "</g>"
            ));
            collateralSize = 1;
        }
        return CollateralForSVG(displayText, collateralSize);
    }

    function mapRows(uint256 _collateralSize) private pure returns (string memory mappedRows) {
        mappedRows = "";
        uint256 rowCount = (_collateralSize + 1) >> 1;
        for (uint256 i = 0; i < (rowCount + 1) >> 1; i++) {
            mappedRows = string(abi.encodePacked(
                mappedRows, "<rect class='cls-9' x='",TABLE_INITIAL_X.toString(),"' y='",(TABLE_INITIAL_Y+i*TABLE_ROW_HEIGHT).toString(),"' width='",TABLE_ROW_WIDTH.toString(),"' height='",TABLE_ROW_HEIGHT.toString(),"'/>"
            ));
        }
        uint256 rowMidpoint = TABLE_INITIAL_X + TABLE_ROW_WIDTH >> 1;
        uint256 tableEndY = TABLE_INITIAL_Y + rowCount * TABLE_ROW_HEIGHT;
        mappedRows = string(abi.encodePacked(mappedRows,
        "<line class='cls-11' x1='",rowMidpoint.toString(),"' y1='",TABLE_INITIAL_Y.toString(),"' x2='",rowMidpoint.toString(),"' y2='",tableEndY.toString(),"'/>"));
    }

    function collateralDebtPecentage(ISmartVault.Status memory _vaultStatus) private pure returns (string memory) {
        return _vaultStatus.minted == 0 ? "N/A" : string(abi.encodePacked(toDecimalString(HUNDRED_PC * _vaultStatus.totalCollateralValue / _vaultStatus.minted, 3),"%"));
    }

    function getGradient(uint256 _tokenId) private pure returns (Gradient memory) {
        bytes32[25] memory colours = [
            bytes32("#FF69B4"), bytes32("#9B00FF"), bytes32("#00FFFF"), bytes32("#0000FF"), bytes32("#333333"), bytes32("#FFD700"), bytes32("#00FFFF"),
            bytes32("#9B00FF"), bytes32("#C0C0C0"), bytes32("#0000A0"), bytes32("#CCFF00"), bytes32("#FFFF33"), bytes32("#FF0000"), bytes32("#800080"),
            bytes32("#4B0082"), bytes32("#6F00FF"), bytes32("#FF1493"), bytes32("#FFAA1D"), bytes32("#FF7E00"), bytes32("#00FF00"), bytes32("#FF6EC7"),
            bytes32("#8B00FF"), bytes32("#FFA07A"), bytes32("#FE4164"), bytes32("#008080")
        ];
        return Gradient(
            colours[_tokenId % colours.length],
            colours[(_tokenId % colours.length + _tokenId / colours.length + 1) % colours.length],
            colours[(_tokenId % colours.length + _tokenId / colours.length + _tokenId / colours.length ** 2 + 2) % colours.length]
        );
    }

    function generateSvg(uint256 _tokenId, ISmartVault.Status memory _vaultStatus) private pure returns (string memory) {
        CollateralForSVG memory collateral = mapCollateralForSVG(_vaultStatus.collateral);
        Gradient memory gradient = getGradient(_tokenId);
        return
            string(
                    abi.encodePacked(
                        "<?xml version='1.0' encoding='UTF-8'?>",
                        "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 2880 1620'>",
                            "<defs>",
                                "<style>",
                                    ".cls-1 {",
                                        "font-family: Arial;",
                                        "font-weight: bold;",
                                        "font-size: 60.88px;",
                                    "}",
                                    ".cls-1, .cls-2, .cls-3, .cls-4, .cls-5, .cls-6, .cls-7, .cls-8, .cls-9, .cls-10 {",
                                        "fill: #fff;",
                                        "text-shadow: 1px 1px #00000080;",
                                    "}",
                                    ".cls-11 {",
                                        "fill: none;",
                                        "stroke: #fff;",
                                        "stroke-miterlimit: 10;",
                                        "stroke-width: 3px;",
                                    "}",
                                    ".cls-2 {",
                                        "font-size: 46.5px;",
                                    "}",
                                    ".cls-2, .cls-4, .cls-7, .cls-8, .cls-10 {",
                                        "font-family: Arial;",
                                    "}",
                                    ".cls-4 {",
                                        "font-size: 95.97px;",
                                    "}",
                                    ".cls-12 {",
                                        "fill: url(#linear-gradient);",
                                    "}",
                                    ".cls-5 {",
                                        "font-family: Arial;",
                                        "font-weight: bold;",
                                    "}",
                                    ".cls-5, .cls-7 {",
                                        "font-size: 50.39px;",
                                    "}",
                                    ".cls-6 {",
                                        "font-family: Arial;",
                                        "font-size: 55px;",
                                    "}",
                                    ".cls-8 {",
                                        "font-size: 42.69px;",
                                    "}",
                                    ".cls-9 {",
                                        "opacity: .17;",
                                    "}",
                                    ".cls-10 {",
                                        "font-size: 63.77px;",
                                    "}",
                                    ".transparent-background-container {",
                                        "fill: rgba(0, 0, 0, 0.3);",
                                    "}",
                                "</style>",
                                "<linearGradient id='linear-gradient' x1='315' y1='1935' x2='2565' y2='-315' gradientTransform='matrix(1, 0, 0, 1, 0, 0)' gradientUnits='userSpaceOnUse'>",
                                    "<stop offset='.38' stop-color='",toShortString(gradient.colour1),"'/>",
                                    "<stop offset='.77' stop-color='",toShortString(gradient.colour2),"'/>",
                                    "<stop offset='1' stop-color='",toShortString(gradient.colour3),"'/>",
                                "</linearGradient>",
                            "</defs>",
                            "<g>",
                                "<rect class='cls-12' width='2880' height='1620'/>",
                                "<rect width='2600' height='1540' class='transparent-background-container' transform='translate(140, 40)' rx='80'/>",
                            "</g>",
                            "<g>",
                                "<g>",
                                    "<text class='cls-4' transform='translate(239.87 164.27)'><tspan x='0' y='0'>The owner of this NFT owns the collateral and debt</tspan></text>",
                                    "<text class='cls-2' transform='translate(244.87 254.3)'><tspan x='0' y='0'>NOTE: NFT marketplace caching might show older NFT data, it is up to the buyer to check the blockchain </tspan></text>",
                                "</g>",
                                "<text class='cls-6' transform='translate(357.54 426.33)'><tspan x='0' y='0'>Collateral locked in this vault</tspan></text>",
                                "<text class='cls-5' transform='translate(1715.63 426.33)'><tspan x='0' y='0'>EUROs SmartVault #",_tokenId.toString(),"</tspan></text>",
                                mapRows(collateral.size),
                                collateral.text,
                                "<g>",
                                    "<text class='cls-5' transform='translate(1713.34 719.41)'><tspan x='0' y='0'>Total Value</tspan></text>",
                                    "<text class='cls-7' transform='translate(2191.03 719.41)'><tspan x='0' y='0'>",toDecimalString(_vaultStatus.totalCollateralValue, 18)," EUROs</tspan></text>",
                                "</g>",
                                "<g>",
                                    "<text class='cls-5' transform='translate(1713.34 822.75)'><tspan x='0' y='0'>Debt</tspan></text>",
                                    "<text class='cls-7' transform='translate(2191.03 822.75)'><tspan x='0' y='0'>",toDecimalString(_vaultStatus.minted, 18)," EUROs</tspan></text>",
                                "</g>",
                                "<g>",
                                    "<text class='cls-5' transform='translate(1713.34 924.1)'><tspan x='0' y='0'>Collateral/Debt</tspan></text>",
                                    "<text class='cls-7' transform='translate(2191.03 924.1)'><tspan x='0' y='0'>",collateralDebtPecentage(_vaultStatus),"</tspan></text>",
                                "</g>",
                                "<g>",
                                    "<text class='cls-5' transform='translate(1714.21 1136.92)'><tspan x='0' y='0'>Total value minus debt:</tspan></text>",
                                    "<text class='cls-5' transform='translate(1715.63 1220.22)'><tspan x='0' y='0'>",toDecimalString(_vaultStatus.totalCollateralValue - _vaultStatus.minted, 18)," EUROs</tspan></text>",
                                "</g>",
                            "</g>",
                            "<g>",
                                "<g>",
                                    "<path class='cls-3' d='M293.17,1446c2.92,0,5.59,.31,8.01,.92,2.42,.61,4.77,1.48,7.05,2.58l-4.2,9.9c-1.99-.88-3.82-1.56-5.52-2.06-1.69-.5-3.47-.74-5.34-.74-3.45,0-6.31,1.01-8.58,3.02-2.28,2.01-3.74,4.92-4.38,8.71h17.25v7.53h-17.87c0,.23-.02,.54-.04,.92-.03,.38-.04,.83-.04,1.36v1.31c0,.41,.03,.85,.09,1.31h15.15v7.62h-14.45c1.4,6.95,5.98,10.42,13.75,10.42,2.22,0,4.31-.22,6.26-.66,1.96-.44,3.78-1.04,5.47-1.8v10.95c-1.64,.82-3.46,1.45-5.47,1.88-2.01,.44-4.37,.66-7.05,.66-6.83,0-12.52-1.85-17.08-5.56-4.55-3.71-7.44-9.01-8.67-15.9h-5.87v-7.62h5.08c-.12-.82-.18-1.69-.18-2.63v-1.31c0-.41,.03-.73,.09-.96h-4.99v-7.53h5.69c.76-4.67,2.31-8.67,4.64-12,2.33-3.33,5.31-5.88,8.93-7.66,3.62-1.78,7.71-2.67,12.26-2.67Z'/>",
                                    "<path class='cls-3' d='M255.82,1479.57h-16.33v-23.22c0-17.76,14.45-32.21,32.21-32.21h61.25v16.33h-61.25c-8.75,0-15.88,7.12-15.88,15.88v23.22Z'/>",
                                    "<path class='cls-3' d='M300.59,1531.88h-60.71v-16.33h60.71c8.61,0,15.88-5.22,15.88-11.4v-24.17h16.33v24.17c0,15.29-14.45,27.73-32.21,27.73Z'/>",
                                "</g>",
                                "<g>",
                                    "<text class='cls-10' transform='translate(357.2 1494.48)'><tspan x='0' y='0'>EUROs SmartVault</tspan></text>",
                                "</g>",
                            "</g>",
                            "<g>",
                                "<g>",
                                    "<g>",
                                        "<text class='cls-1' transform='translate(2173.2 1496.1)'><tspan x='0' y='0'>TheStandard.io</tspan></text>",
                                    "</g>",
                                    "<rect class='cls-3' x='2097.6' y='1453.66' width='16.43' height='49.6'/>",
                                    "<path class='cls-3' d='M2074.82,1479.74h-16.38v-23.29c0-17.81,14.49-32.31,32.31-32.31h61.43v16.38h-61.43c-8.78,0-15.93,7.14-15.93,15.93v23.29Z'/>",
                                    "<path class='cls-3' d='M2119.72,1532.21h-60.9v-16.38h60.9c8.63,0,15.93-5.24,15.93-11.44v-24.24h16.38v24.24c0,15.34-14.49,27.82-32.31,27.82Z'/>",
                                "</g>",
                            "</g>",
                        "</svg>"
                    )
            );
    }

    function generateNFTMetadata(uint256 _tokenId, ISmartVault.Status memory _vaultStatus) external pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(abi.encodePacked(
                    "{",
                        '"name": "The Standard Smart Vault #',_tokenId.toString(),'",',
                        '"description": "The Standard Smart Vault (',toShortString(_vaultStatus.vaultType),')",',
                        '"attributes": [',
                            '{"trait_type": "Status", "value": "',_vaultStatus.liquidated ?"liquidated":"active",'"},',
                            '{"trait_type": "Debt",  "display_type": "number", "value": ', toDecimalString(_vaultStatus.minted, 18),'},',
                            '{"trait_type": "Max Borrowable Amount", "display_type": "number", "value": "',toDecimalString(_vaultStatus.maxMintable, 18),'"},',
                            '{"trait_type": "Collateral Value in EUROs", "display_type": "number", "value": ',toDecimalString(_vaultStatus.totalCollateralValue, 18),'},',
                            '{"trait_type": "Value minus debt", "display_type": "number", "value": ',toDecimalString(_vaultStatus.totalCollateralValue - _vaultStatus.minted, 18),'},',
                            mapCollateralForJSON(_vaultStatus.collateral),
                            '{"trait_type": "Version", "value": "',uint256(_vaultStatus.version).toString(),'"},',
                            '{"trait_type": "Vault Type", "value": "',toShortString(_vaultStatus.vaultType),'"}',
                        '],',
                        '"image_data": "',generateSvg(_tokenId, _vaultStatus),'"',
                    "}"
                ))
            )
        );
    }
}