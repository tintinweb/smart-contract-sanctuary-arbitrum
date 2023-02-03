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

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "base64-sol/base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IUserNFTDescriptor.sol";
import "./interfaces/IUserManager.sol";
import "./interfaces/Gameable.sol";

abstract contract BaseNFTUserDescriptor is IUserNFTDescriptor {
    function tokenURI(
        address hub,
        uint256 userId
    ) external view override returns (string memory) {
        IUserManager.UserDescription memory _userDescription = IUserManager(hub)
            .getUserDescription(userId);
        return _constructTokenURI(_userDescription);
    }

    function _constructTokenURI(
        IUserManager.UserDescription memory _userDescription
    ) private pure returns (string memory) {
        string memory _name = _generateName(_userDescription);
        string memory _description = _generateDescription();
        string memory _image = Base64.encode(
            bytes(_generateSVG(_userDescription))
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _name,
                                '", "description":"',
                                _description,
                                '", "image": "data:image/svg+xml;base64,',
                                _image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _generateDescription() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This collection contains all the heroes who participated in the Bored In Borderland Season 1.\\n\\n",
                    "Whether they are dead or alive, they are the pioneers of the game and all players who participated in Season 1 will receive benefits for future seasons.\\n\\n",
                    "Each NFT contains the name of the hero, the score represented by the amount of xBCOIN accumulated by the NFT and the current APR of the Hero."
                )
            );
    }

    function _getHeroCategory() internal pure virtual returns (string memory);

    function _generateName(
        IUserManager.UserDescription memory _userDescription
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Heroes of Borderland Season 1 - ",
                    _getHeroCategory(),
                    " - #",
                    Strings.toString(_userDescription.userId)
                )
            );
    }

    function _generateSVG(
        IUserManager.UserDescription memory _userDescription
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _generateSVGMeta(),
                    _generateStyleDefs(),
                    _generateSVGCalques(),
                    _generateSVGForm(),
                    _generateSVGDesign(),
                    _generateSVGData(_userDescription),
                    "</g></g></svg>"
                )
            );
    }

    function _generateSVGDesign() internal pure virtual returns (string memory);

    function _generateSVGMeta() internal pure virtual returns (string memory);

    function _generateStyleDefs() internal pure virtual returns (string memory);

    function _generateSVGCalques() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g id="Calque_1" data-name="Calque 1"><g id="Calque_2" data-name="Calque 2">'
                )
            );
    }

    function _generateSVGForm() internal pure virtual returns (string memory);

    function _generateSVGData(
        IUserManager.UserDescription memory _userDescription
    ) private pure returns (string memory) {
        uint256 _scoreRounded = (_userDescription.balance -
            (_userDescription.balance % 10 ** 18)) / 10 ** 18;
        uint256 _aprRounded = (_userDescription.apr -
            (_userDescription.apr % 10 ** 18) /
            10 ** 18) / 10000;
        string memory _apr = Strings.toString(_aprRounded);
        string memory _score = Strings.toString(_scoreRounded);
        return _getSVGData(_userDescription.userId, _score, _apr);
    }

    function _getSVGData(
        uint256 userID,
        string memory score,
        string memory apr
    ) internal pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseNFTUserDescriptor.sol";

contract BoredNFTDescriptor is BaseNFTUserDescriptor {
    function _getHeroCategory()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return "AZRAEL";
    }

    function _generateSVGDesign()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<path class="cls-2" d="M293,182.36h0l32.93-6.47,1.24.56a8.42,8.42,0,0,1,3.67,3.19c3,4.77,9.45,16.31,7.88,24.16-2,10.11-8.9,29.12-16.18,35.19s-24.67,19-24.67,19L295,261.64l8.5,2s13.75,6.51,15.77,8.92,9.31,7.67,3.24,17-8.09,12.94-11.73,16.58-10.92,17-10.92,17l-19.42,29.13s-5.26,8.9-22.65,13.35-43.68,7.68-43.68,7.68l-1.22,4.85s-.4,13.35,2.43,21,2.83,9.3,2.83,9.3l11.73,4.45s15.37,4.45,19,9.3,4.86,6.88,4.86,6.88l20.63,8.9a16.66,16.66,0,0,1,6.47,6.07,24.65,24.65,0,0,0,5.66,6.47l9.71,63.14H26.33V490.31l5.39-12.94s2.16-30.74,20-38.83S104,418,107.76,414.27s11.33-6.47,16.18-12.4,9.17-16.72,9.71-20.5,0-60.94,0-60.94-15.64-15.1-12.4-25.89a43.3,43.3,0,0,1,12.64-19.42c1.92-1.61,3-7.82,3-7.82l-15.64,3.51s-27.51-1.62-32.36-3.51-23.73-26.69-25.35-38,.54-22.11,3.24-27.5S84,170,84,170s4.86-8.63,14.57-9.17,15.64-3.24,25.88,8.63l10.25,11.86,27.51-21.14s27.5-19.31,48-22,32.89-2.69,32.89-2.69,17.8-4.32,21.58-6.47,12.94-4.86,12.94-4.86l-5.93,10.25,14-3.24-3.23,4.32,7-.54-3.69,5.43,4-2.86L293,182.36"/>',
                    '<g id="Calque_3" data-name="Calque 3"><path class="cls-7" d="M175.68,210.61h0Z"/><path class="cls-7" d="M175.54,210.6h0Z"/><path class="cls-7" d="M175.72,210.61h0Z"/><path class="cls-7" d="M175.79,210.61h0Z"/><path class="cls-7" d="M175,210.6Z"/>',
                    '<path class="cls-7" d="M429,37.26l-209.2,145a4.37,4.37,0,0,1-2.15.74c-25,1.9-41.87,27.62-41.87,27.62,1.23.75,22.91,12,34.24,9.7,7.82-1.61,9.53-2.24,10.34-2.72,7.44-2.34,13.34-5.87,14-7a8.5,8.5,0,0,0,.92-2.54C279.5,179.54,415.91,90.8,433.75,79.19a4.25,4.25,0,0,0,1.93-3.56V40.75A4.25,4.25,0,0,0,429,37.26Z"/><path class="cls-7" d="M175.38,210.6h0Z"/><path class="cls-7" d="M175.41,210.6h0Z"/><path class="cls-7" d="M262.35,216.27c7.07-1,153-96.64,171.42-108.76a4.28,4.28,0,0,0,1.91-3.56V94.22a4.25,4.25,0,0,0-6.6-3.54L254,206.94a4.27,4.27,0,0,0-.06,7.05A11.69,11.69,0,0,0,262.35,216.27Z"/></g>',
                    '<path class="cls-8" d="M289.34,291.74a3.39,3.39,0,0,0,2.18.12,13,13,0,0,0,6.18-12.72,1.9,1.9,0,0,0-2.3-1,5.68,5.68,0,0,0-1.82.72,1.74,1.74,0,0,0,.12,1.34l-.36,1.09c-.61.68-1.1.6-1.45-.25a10.69,10.69,0,0,0-.61-2.3,30.77,30.77,0,0,0-4.6.25,10.5,10.5,0,0,0,.84,8.11A7.32,7.32,0,0,0,289.34,291.74Z"/><path class="cls-8" d="M306.79,279.5a9,9,0,0,0-.73,1.45,1,1,0,0,1-1,0c-.31-.83-.59-1.68-.85-2.54a1.05,1.05,0,0,0-.84-.24,5.52,5.52,0,0,0-1.1,2.42,13.42,13.42,0,0,1-.72,4.36,10.18,10.18,0,0,0,3.27,9.45,9.11,9.11,0,0,0,1.82-2.18q1.23-3,2.18-6.06a50,50,0,0,0,.36-6.54A7.57,7.57,0,0,0,306.79,279.5Z"/>',
                    '<path class="cls-8" d="M278.44,278.41a1.23,1.23,0,0,1-1,.61,56.28,56.28,0,0,1-15,1.33v.72a3.34,3.34,0,0,0-3.15,1.82q-1.28,6.42-3,12.72a1.52,1.52,0,0,0,0,1.22c.66.39,1.35.75,2.05,1.09a39.39,39.39,0,0,0,9.94.48,1.72,1.72,0,0,0,1.09-.61,19.23,19.23,0,0,0,.48-3.39c.73-.33,1.21-.09,1.46.73a7.89,7.89,0,0,1,.12,1.94,6.1,6.1,0,0,0,1.33-.49,5.85,5.85,0,0,0,1.94.73,47.42,47.42,0,0,0,7.15-1.82,2.23,2.23,0,0,0,1.09-1.33,24.53,24.53,0,0,0-1.21-14.3A2.61,2.61,0,0,0,278.44,278.41Z"/><path class="cls-8" d="M184.3,284c-.64-.74-1.24-1.51-1.82-2.3a24.8,24.8,0,0,1-3.88-1.7,3.16,3.16,0,0,0-2.3-.12,7.43,7.43,0,0,0,.73,4.61,1,1,0,0,0,.48.24,1.26,1.26,0,0,1,1.94,0q1,2.12,1.82,4.24l-.85.85a3.22,3.22,0,0,1-1.57-1.7,1.22,1.22,0,0,0-1-.24,1.44,1.44,0,0,1-.37,1.21,3.18,3.18,0,0,1-1.45-1.45q-1.38-3.94-2.42-8a1.61,1.61,0,0,0-1.09-.24l-1,.73a51.79,51.79,0,0,0-.12,15,48.26,48.26,0,0,0,8.6,14.42.6.6,0,0,0,.72,0,35.34,35.34,0,0,0,6.43-15.39,7.82,7.82,0,0,0-.25-5.33A34.5,34.5,0,0,1,184.3,284Z"/>',
                    '<path class="cls-8" d="M197.75,300.82a11.25,11.25,0,0,0,6.9,2.31,30.69,30.69,0,0,0,12-3.76,7,7,0,0,0,2.78-4,42.17,42.17,0,0,0,.25-8.48,4.22,4.22,0,0,1-1.82-1.94,11.68,11.68,0,0,1-1.7-1.09c-1.18-.36-1.7.09-1.57,1.33-.77.69-1.33.53-1.7-.48a9.31,9.31,0,0,0-.85-2.79c-1.75-.61-3.52-1.17-5.33-1.69a21.49,21.49,0,0,0-4.6-.37,49.74,49.74,0,0,1-7.27.61,4.87,4.87,0,0,0,.24,4.36.62.62,0,0,1-.6.61,12.71,12.71,0,0,1-2.31-2.79,1,1,0,0,0-1,0,4.12,4.12,0,0,1-1.33,1.09,67.71,67.71,0,0,0,.73,6.79A34.54,34.54,0,0,0,197.75,300.82Z"/><path class="cls-8" d="M254.81,285.92a11.21,11.21,0,0,0-2.3-5.94,9.94,9.94,0,0,0-2.18-.12,2.73,2.73,0,0,0-.61.73l-.24,3.88c-.48.64-1,.64-1.45,0-.2-1.38-.44-2.76-.73-4.12a1.54,1.54,0,0,0-.73-.24q-5,.52-10,.84a6.31,6.31,0,0,0-1.82.85,3.68,3.68,0,0,0-1.82-.73q-3,.75-6.06,1.82a46.74,46.74,0,0,0-3.51,4.24,6.29,6.29,0,0,1-1,2.67c-.09,1.46-.21,2.91-.36,4.36a7.11,7.11,0,0,0,7,5.45q5.93.24,11.87,0A52.14,52.14,0,0,0,253,297.67a10.54,10.54,0,0,0,1.58-3.27,37.81,37.81,0,0,0,.73-5.09A4.59,4.59,0,0,0,254.81,285.92Z"/>',
                    '<path class="cls-8" d="M299.52,291.37a11.26,11.26,0,0,0-3.15-.6,26.25,26.25,0,0,1-8,5.21,13.81,13.81,0,0,0-2.54,3.51,9.9,9.9,0,0,0,.12,3.76,1.59,1.59,0,0,0,1.21,0,59.13,59.13,0,0,0,11.15-5.33,5.13,5.13,0,0,0,1.21-1.7,9.07,9.07,0,0,0,1.94-.85,1.3,1.3,0,0,0,.12-1.21C300.86,293.24,300.17,292.31,299.52,291.37Z"/><path class="cls-8" d="M168.43,295.86a2.21,2.21,0,0,1-1.21-.25,10.71,10.71,0,0,1-3-4.12,1.71,1.71,0,0,0-2.06.37q-1.66,1.59-3.15,3.27v.73a1.21,1.21,0,0,0,.72-.13,7.56,7.56,0,0,1,3.4-2.54,1.22,1.22,0,0,1,.48.36,9.59,9.59,0,0,1-2.3,3,.66.66,0,0,0,.12.85l5.33,2.18a8.56,8.56,0,0,0,3.39.61,4.67,4.67,0,0,0-.36-1.46A4.78,4.78,0,0,1,168.43,295.86Z"/>',
                    '<path class="cls-8" d="M279.16,298.52a19.5,19.5,0,0,1-5.08,1.58,105.39,105.39,0,0,1-15.27.72,11.53,11.53,0,0,1-2.67,2.55c-.38,1.52-.7,3.05-1,4.6a2.75,2.75,0,0,0,3.15,2.79,1.64,1.64,0,0,0,1.22.73,33.3,33.3,0,0,0,17-1.7l.6-.61c.15-1.53.31-3.07.49-4.6a1.67,1.67,0,0,1,.6-.85,6.34,6.34,0,0,0,1.82-1.09.87.87,0,0,1,.73.73,11.53,11.53,0,0,1,.24,3.87.67.67,0,0,0,.85.13l1.57-1.58a35.9,35.9,0,0,0-.72-5.81A6.16,6.16,0,0,0,279.16,298.52Z"/><path class="cls-8" d="M198.23,303.73q-3.31-2.07-6.78-3.88a7.89,7.89,0,0,0-1.94-.12,3.09,3.09,0,0,1-.12,1.21,8.35,8.35,0,0,0-1.21,4.12,1.58,1.58,0,0,1,1.09,1.34,5.65,5.65,0,0,0-.49,2.54h1.45a1.14,1.14,0,0,0,.49,1.09,60.34,60.34,0,0,0,17.2,1.7,2.76,2.76,0,0,0,1.09-.85,12.76,12.76,0,0,0,2.06-6.79,43.57,43.57,0,0,0-4.36.85A14.64,14.64,0,0,1,198.23,303.73Z"/>',
                    '<path class="cls-8" d="M247.42,301.67c-1.26.18-2.55.38-3.88.61-3.11.06-6.22.19-9.33.36-1.16-.11-2.34-.19-3.51-.24q-6.3.38-12.6.85a2.28,2.28,0,0,0-.6.36,21.51,21.51,0,0,1-1.46,2.67,19.12,19.12,0,0,1-1.21,3.15q-2.87,2.1.61,2.54,7.42.18,14.78,1.09a3.71,3.71,0,0,0,1.45-1.94,1.07,1.07,0,0,1,1.33,0c-.11,1.59.62,2.23,2.18,1.94q5.77-.42,11.51-1.09a11.69,11.69,0,0,0,4.12-1.82,16.21,16.21,0,0,0,1-4.36A5.67,5.67,0,0,0,247.42,301.67Z"/>'
                )
            );
    }

    function _generateSVGMeta()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 435.68 592.4">'
                )
            );
    }

    function _generateStyleDefs()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<defs>",
                    '<style>@import url("https://fonts.googleapis.com/css?family=Bowlby One:400");.cls-1{fill:#202020;}.cls-2{fill:url(#gradient41);}.cls-3,.cls-6{font-size:36px;}.cls-3,.cls-4{fill:#fff;}.cls-3,.cls-4,.cls-9{font-family:BowlbyOne-Regular, Bowlby One;}.cls-4{font-size:15px;}.cls-5{opacity:0.5;}.cls-6,.cls-7{fill:#ff0007;}.cls-8{fill:#fe0000;fill-rule:evenodd;opacity:0.98;isolation:isolate;}.cls-9{font-size:82px;fill:#3c3c3b;}</style>',
                    '<linearGradient id="gradient41" x1="182.65" y1="513.68" x2="182.65" y2="124.11" gradientUnits="userSpaceOnUse"><stop offset="0" stop-opacity="0"/><stop offset="0.18"/></linearGradient>',
                    "</defs>"
                )
            );
    }

    function _generateSVGForm()
        internal
        pure
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<rect class="cls-1" width="392.04" height="574.3" rx="11.72"/>'
                )
            );
    }

    function _getSVGData(
        uint256 userID,
        string memory score,
        string memory apr
    ) internal pure virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text class="cls-3" transform="translate(73.04 479.84)">N',
                    unicode"°",
                    Strings.toString(userID),
                    '</text><text class="cls-4" transform="translate(25.06 30.83)"><tspan class="cls-5">xBCOIN</tspan><tspan class="cls-6"><tspan x="0" y="32">',
                    score,
                    '</tspan></tspan></text><text class="cls-4" transform="translate(331.08 30.83)"><tspan class="cls-5">APR</tspan><tspan class="cls-6"><tspan x="-68.1" y="33">',
                    apr,
                    '%</tspan></tspan></text><text class="cls-9" transform="translate(19.75 555.09)">AZRAEL</text>'
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface Gameable {
    enum TierType {
        BORED,
        MUTANT,
        SOUL
    }

    struct NumberChosen {
        uint256 tokenID;
        uint256 number;
        uint256 balanceBeforeGame;
        uint256 createdAt;
    }

    struct UserGame {
        uint256 gameID;
        uint256 balanceBeforeGame;
        TierType category;
        bool isWinner;
    }

    struct Player {
        uint256 tokenID;
        string name;
        uint256 categoryPlayer;
        uint256 initialBalance;
        uint256 currentBalance;
        uint256 createdAt;
        uint256 number;
    }

    struct Game {
        uint256 id;
        uint256 winner;
        uint256 playersInGame;
        uint256 startedAt;
        uint256 endedAt;
        uint256 updatedAt;
        uint256 pool;
        TierType category;
    }

    struct Tier {
        TierType category;
        uint256 duration;
        uint256 amount;
        uint8 maxPlayer;
        uint256 createdAt;
        uint256 updatedAt;
        bool isActive;
    }

    function getGame(uint256 idGame) external returns (Game memory);

    function play(
        TierType category,
        uint256 tokenID,
        uint8 numberChosen
    ) external returns (uint256);

    function getGamesOf(uint256 tokenID) external returns (Game[] memory);

    function getGamesEndedBetweenIntervalOf(
        uint256 tokenID,
        uint256 startInterval,
        uint256 endInterval
    ) external view returns (UserGame[] memory);

    function getTier(TierType category) external view returns (Tier memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserManager {
    enum AprType {
        BORED,
        MUTANT,
        SOUL
    }
    
    event Created(
        address indexed userAdrr,
        uint256 indexed tokenId,
        AprType category,
        uint256 amount,
        uint256 createdAt
    );

    struct UserGame {
        uint256 id;
        uint256 rewardT0;
        uint256 rewardT1;
        uint256 totalReward;
        uint256 tokenBalance;
        uint256[3] gameIds;
        uint256 date;
        uint256 lastClaimTime;
    }

    struct User {
        uint256 balance;
        uint256 initialBalance;
        AprType category;
        string name;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct UserDescription {
        uint256 userId;
        uint256 balance;
        uint256 apr;
        uint256 initialBalance;
        string name;
        AprType category;
    }
    
    function getUserDescription(
        uint256 tokenId
    ) external view returns (UserDescription memory userDescription);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserNFTDescriptor {
  function tokenURI(address hub, uint256 tokenId) external view returns (string memory);
}