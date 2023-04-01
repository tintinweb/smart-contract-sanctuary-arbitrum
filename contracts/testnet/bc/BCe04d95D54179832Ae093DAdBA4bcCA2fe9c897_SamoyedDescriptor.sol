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
interface IERC165 {
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

pragma solidity ^0.8.0;

import "../IERC3525.sol";
import "./IERC721Metadata.sol";

/**
 * @title ERC-3525 Semi-Fungible Token Standard, optional extension for metadata
 * @dev Interfaces for any contract that wants to support query of the Uniform Resource Identifier
 *  (URI) for the ERC3525 contract as well as a specified slot.
 *  Because of the higher reliability of data stored in smart contracts compared to data stored in
 *  centralized systems, it is recommended that metadata, including `contractURI`, `slotURI` and
 *  `tokenURI`, be directly returned in JSON format, instead of being returned with a url pointing
 *  to any resource stored in a centralized system.
 *  See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0xe1600902.
 */
interface IERC3525Metadata is IERC3525, IERC721Metadata {
    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the current ERC3525 contract.
     * @dev This function SHOULD return the URI for this contract in JSON format, starting with
     *  header `data:application/json;`.
     *  See https://eips.ethereum.org/EIPS/eip-3525 for the JSON schema for contract URI.
     * @return The JSON formatted URI of the current ERC3525 contract
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the specified slot.
     * @dev This function SHOULD return the URI for `_slot` in JSON format, starting with header
     *  `data:application/json;`.
     *  See https://eips.ethereum.org/EIPS/eip-3525 for the JSON schema for slot URI.
     * @return The JSON formatted URI of `_slot`
     */
    function slotURI(uint256 _slot) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
 */
interface IERC721Metadata is IERC721 {
    /**
     * @notice A descriptive name for a collection of NFTs in this contract
     */
    function name() external view returns (string memory);

    /**
     * @notice An abbreviated name for NFTs in this contract
     */
    function symbol() external view returns (string memory);

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     *  3986. The URI may point to a JSON file that conforms to the "ERC721
     *  Metadata JSON Schema".
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC721.sol";

/**
 * @title ERC-3525 Semi-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0xc97ae3d5.
 */
interface IERC3525 is IERC165, IERC721 {
    /**
     * @dev MUST emit when value of a token is transferred to another token with the same slot,
     *  including zero value transfers (_value == 0) as well as transfers when tokens are created
     *  (`_fromTokenId` == 0) or destroyed (`_toTokenId` == 0).
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     */
    event TransferValue(uint256 indexed _fromTokenId, uint256 indexed _toTokenId, uint256 _value);

    /**
     * @dev MUST emits when the approval value of a token is set or changed.
     * @param _tokenId The token to approve
     * @param _operator The operator to approve for
     * @param _value The maximum value that `_operator` is allowed to manage
     */
    event ApprovalValue(uint256 indexed _tokenId, address indexed _operator, uint256 _value);

    /**
     * @dev MUST emit when the slot of a token is set or changed.
     * @param _tokenId The token of which slot is set or changed
     * @param _oldSlot The previous slot of the token
     * @param _newSlot The updated slot of the token
     */ 
    event SlotChanged(uint256 indexed _tokenId, uint256 indexed _oldSlot, uint256 indexed _newSlot);

    /**
     * @notice Get the number of decimals the token uses for value - e.g. 6, means the user
     *  representation of the value of a token can be calculated by dividing it by 1,000,000.
     *  Considering the compatibility with third-party wallets, this function is defined as
     *  `valueDecimals()` instead of `decimals()` to avoid conflict with ERC20 tokens.
     * @return The number of decimals for value
     */
    function valueDecimals() external view returns (uint8);

    /**
     * @notice Get the value of a token.
     * @param _tokenId The token for which to query the balance
     * @return The value of `_tokenId`
     */
    function balanceOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the slot of a token.
     * @param _tokenId The identifier for a token
     * @return The slot of the token
     */
    function slotOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Allow an operator to manage the value of a token, up to the `_value` amount.
     * @dev MUST revert unless caller is the current owner, an authorized operator, or the approved
     *  address for `_tokenId`.
     *  MUST emit ApprovalValue event.
     * @param _tokenId The token to approve
     * @param _operator The operator to be approved
     * @param _value The maximum value of `_toTokenId` that `_operator` is allowed to manage
     */
    function approve(
        uint256 _tokenId,
        address _operator,
        uint256 _value
    ) external payable;

    /**
     * @notice Get the maximum value of a token that an operator is allowed to manage.
     * @param _tokenId The token for which to query the allowance
     * @param _operator The address of an operator
     * @return The current approval value of `_tokenId` that `_operator` is allowed to manage
     */
    function allowance(uint256 _tokenId, address _operator) external view returns (uint256);

    /**
     * @notice Transfer value from a specified token to another specified token with the same slot.
     * @dev Caller MUST be the current owner, an authorized operator or an operator who has been
     *  approved the whole `_fromTokenId` or part of it.
     *  MUST revert if `_fromTokenId` or `_toTokenId` is zero token id or does not exist.
     *  MUST revert if slots of `_fromTokenId` and `_toTokenId` do not match.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `TransferValue` event.
     * @param _fromTokenId The token to transfer value from
     * @param _toTokenId The token to transfer value to
     * @param _value The transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value
    ) external payable;

    /**
     * @notice Transfer value from a specified token to an address. The caller should confirm that
     *  `_to` is capable of receiving ERC3525 tokens.
     * @dev This function MUST create a new ERC3525 token with the same slot for `_to` to receive
     *  the transferred value.
     *  MUST revert if `_fromTokenId` is zero token id or does not exist.
     *  MUST revert if `_to` is zero address.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `Transfer` and `TransferValue` events.
     * @param _fromTokenId The token to transfer value from
     * @param _to The address to transfer value to
     * @param _value The transferred value
     * @return ID of the new token created for `_to` which receives the transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        address _to,
        uint256 _value
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/** 
 * @title ERC-721 Non-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
 */
interface IERC721 is IERC165 {
    /** 
     * @dev This emits when ownership of any NFT changes by any mechanism.
     *  This event emits when NFTs are created (`from` == 0) and destroyed
     *  (`to` == 0). Exception: during contract creation, any number of NFTs
     *  may be created and assigned without emitting Transfer. At the time of
     *  any transfer, the approved address for that NFT (if any) is reset to none.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev This emits when the approved address for an NFT is changed or
     *  reaffirmed. The zero address indicates there is no approved address.
     *  When a Transfer event emits, this also indicates that the approved
     *  address for that NFT (if any) is reset to none.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev This emits when an operator is enabled or disabled for an owner.
     *  The operator can manage all NFTs of the owner.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *  function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries
     *  about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT. When transfer is complete, this function
     *  checks if `_to` is a smart contract (code size > 0). If so, it calls
     *  `onERC721Received` on `_to` and throws if the return value is not
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter,
     *  except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *  THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *  Throws unless `msg.sender` is the current NFT owner, or an authorized
     *  operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external payable;

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *  multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) external view returns (address);

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC3525MetadataDescriptor {

    function constructContractURI() external view returns (string memory);

    function constructSlotURI(uint256 slot) external view returns (string memory);
    
    function constructTokenURI(uint256 tokenId) external view returns (string memory);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Base64.sol";

import "../libraries/SVG.sol";
import "../libraries/Utils.sol";

library Samoyed {
    function render(uint256 _tokenId) public pure returns (bytes memory) {
        bytes memory hash = abi.encodePacked(
            keccak256(abi.encode("samoyed", _tokenId))
        );
        return
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '<svg xmlns="http://www.w3.org/2000/svg" width="640" height="640" style="background:#fff">',
                            dogeFilter(hash),
                            _skin(),
                            _detail(),
                            _body(),
                            _ear(),
                            _face(),
                            "</svg>"
                        )
                    )
                )
            );
    }

    function dogeFilter(bytes memory hash)
        internal
        pure
        returns (string memory)
    {
        string memory redOffset;
        string memory greenOffset;
        string memory blueOffset;
        {
            redOffset = getColourOffset(hash, 0);
            greenOffset = getColourOffset(hash, 1);
            blueOffset = getColourOffset(hash, 2);
        }

        uint256 seed = utils.getFineSandSeed(hash);
        uint256 octaves = utils.getFineSandOctaves(hash);

        return
            svg.filter(
                string.concat(
                    svg.prop("id", "dogeFilter"),
                    svg.prop("x", "0"),
                    svg.prop("y", "0"),
                    svg.prop("width", "100%"),
                    svg.prop("height", "100%")
                ),
                string.concat(
                    fineSandfeTurbulence(seed, octaves),
                    svg.el(
                        "feComponentTransfer",
                        "",
                        string.concat(
                            svg.el(
                                "feFuncR",
                                string.concat(
                                    svg.prop("type", "gamma"),
                                    svg.prop("offset", redOffset)
                                )
                            ),
                            svg.el(
                                "feFuncG",
                                string.concat(
                                    svg.prop("type", "gamma"),
                                    svg.prop("offset", greenOffset)
                                )
                            ),
                            svg.el(
                                "feFuncB",
                                string.concat(
                                    svg.prop("type", "gamma"),
                                    svg.prop("offset", blueOffset)
                                )
                            ),
                            svg.el(
                                "feFuncA",
                                string.concat(
                                    svg.prop("type", "linear"),
                                    svg.prop("intercept", "1")
                                )
                            )
                        )
                    )
                )
            );
    }

    function fineSandfeTurbulence(uint256 seed, uint256 octaves)
        internal
        pure
        returns (string memory)
    {
        return
            svg.el(
                "feTurbulence",
                string.concat(
                    svg.prop("baseFrequency", "0.01"),
                    svg.prop("numOctaves", utils.uint2str(octaves)),
                    svg.prop("seed", utils.uint2str(seed)),
                    svg.prop("result", "turbs")
                )
            );
    }

    function getColourOffset(bytes memory hash, uint256 offsetIndex)
        internal
        pure
        returns (string memory)
    {
        uint256 shift = utils.getColourOffsetShift(hash, offsetIndex);
        uint256 change = utils.getColourOffsetChange(hash, offsetIndex);
        string memory sign = "";
        if (shift == 1) {
            sign = "-";
        }
        return
            string(
                abi.encodePacked(sign, utils.generateDecimalString(change, 1))
            );
    }

    function _detail() internal pure returns (string memory) {
        return
            string.concat(
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 140; y: 300; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 100; y: 320; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 80; y: 360; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 100; y: 380; width: 80; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 180; y: 360; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 200; y: 340; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 220; y: 360; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 540; y: 180; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 560; y: 220; width: 20; height: 20"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 100; y: 460; width: 20; height: 100"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 120; y: 540; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 140; y: 560; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 160; y: 580; width: 40; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 140; y: 460; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 160; y: 480; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 180; y: 500; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 200; y: 520; width: 40; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 240; y: 480; width: 20; height: 20"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 240; y: 500; width: 40; height: 100"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 280; y: 560; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 300; y: 580; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 320; y: 480; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 340; y: 500; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 360; y: 520; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 380; y: 540; width: 80; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 460; y: 520; width: 40; height: 80"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 480; y: 500; width: 40; height: 60"
                        )
                    )
                ),
                svg.rect(
                    svg.prop(
                        "style",
                        "opacity: 0.4; fill: #000; x: 520; y: 480; width: 20; height: 20"
                    )
                )
            );
    }

    function _body() internal pure returns (string memory) {
        return
            string.concat(
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 380; y: 120; width: 80; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 360; y: 80; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 460; y: 80; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 340; y: 60; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 480; y: 60; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 300; y: 40; width: 40; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 500; y: 40; width: 40; height: 20"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 280; y: 60; width: 20; height: 120"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 540; y: 60; width: 20; height: 120"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 260; y: 180; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 240; y: 220; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 220; y: 260; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 200; y: 280; width: 20; height: 60"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 180; y: 320; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 160; y: 360; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 120; y: 380; width: 40; height: 20"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 100; y: 360; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 80; y: 320; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 100; y: 300; width: 40; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 180; y: 240; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 160; y: 220; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 140; y: 240; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 100; y: 220; width: 40; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 80; y: 240; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 60; y: 260; width: 20; height: 20"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 40; y: 280; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 20; y: 320; width: 20; height: 60"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 40; y: 380; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 60; y: 400; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 80; y: 420; width: 20; height: 140"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 100; y: 560; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 120; y: 580; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 140; y: 600; width: 200; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 200; y: 560; width: 40; height: 40"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 180; y: 540; width: 40; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 160; y: 520; width: 40; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 140; y: 500; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 240; y: 500; width: 20; height: 80"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 260; y: 580; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 340; y: 520; width: 20; height: 80"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 320; y: 500; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 360; y: 560; width: 120; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 480; y: 520; width: 20; height: 40"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 500; y: 500; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 460; y: 580; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 480; y: 600; width: 60; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 540; y: 580; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 560; y: 540; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 580; y: 220; width: 20; height: 320"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 560; y: 180; width: 20; height: 40"
                        )
                    )
                )
            );
    }

    function _skin() internal pure returns (string memory) {
        return
            string.concat(
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 40; y: 320; width: 20; height: 60"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 60; y: 280; width: 20; height: 120"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 80; y: 260; width: 20; height: 160"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 100; y: 240; width: 20; height: 320"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 120; y: 240; width: 20; height: 340"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 140; y: 240; width: 60; height: 360"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 200; y: 340; width: 20; height: 200"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 220; y: 300; width: 20; height: 260"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 240; y: 260; width: 20; height: 360"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 260; y: 220; width: 20; height: 400"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 280; y: 60; width: 80; height: 540"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 360; y: 120; width: 120; height: 440"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 480; y: 60; width: 80; height: 540"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "filter: url(#dogeFilter); x: 560; y: 220; width: 20; height: 320"
                        )
                    )
                )
            );
    }

    function _ear() internal pure returns (string memory) {
        return
            string.concat(
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 320; y: 100; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 340; y: 120; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #ff6464; x: 320; y: 120; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 500; y: 100; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 480; y: 120; width: 20; height: 40"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #ff6464; x: 500; y: 120; width: 20; height: 40"
                        )
                    )
                )
            );
    }

    function _face() internal pure returns (string memory) {
        return
            string.concat(
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 360; y: 220; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 340; y: 220; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 360; y: 200; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 460; y: 220; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 480; y: 220; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 460; y: 200; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 400; y: 260; width: 80; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 420; y: 280; width: 40; height: 20"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 320; y: 340; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 520; y: 340; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 340; y: 360; width: 180; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "opacity: 0.4; fill: #000; x: 400; y: 380; width: 80; height: 20"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 340; y: 300; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 500; y: 300; width: 20; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 360; y: 320; width: 140; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 380; y: 340; width: 100; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 400; y: 360; width: 80; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #000; x: 420; y: 380; width: 40; height: 20"
                        )
                    ),
                    svg.rect(
                        svg.prop(
                            "style",
                            "fill: #ff6464; x: 420; y: 340; width: 40; height: 40"
                        )
                    )
                )
            );
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "@solvprotocol/erc-3525/periphery/interface/IERC3525MetadataDescriptor.sol";
import "@solvprotocol/erc-3525/extensions/IERC3525Metadata.sol";

import "../interfaces/IERC3525ExtendedUpgradeable.sol";
import "./Samoyed.sol";

contract SamoyedDescriptor is IERC3525MetadataDescriptor {

    using Strings for uint256;

    function constructContractURI() external pure override returns (string memory) {
        return "";
    }

    function constructSlotURI(uint256 slot_) external pure override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    /* solhint-disable */
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"', 
                            _slotName(slot_),
                            '","description":"',
                            _slotDescription(slot_),
                            '","image":"',
                            _slotImage(slot_),
                            '","properties":',
                            _slotProperties(slot_),
                            '}'
                        )
                    )
                    /* solhint-enable */
                )
            );
    }

    function constructTokenURI(uint256 tokenId_) external view override returns (string memory) {
        IERC3525Metadata erc3525 = IERC3525Metadata(msg.sender);
        uint index = IERC3525ExtendedUpgradeable(msg.sender).getTokenIndexInSlot(tokenId_);
        return 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            /* solhint-disable */
                            '{"name":"',
                            _tokenName(index),
                            '","description":"',
                            _description(),
                            '","image_data":"',
                            Samoyed.render(index),
                            '","balance":"',
                            erc3525.balanceOf(tokenId_).toString(),
                            '","slot":"',
                            erc3525.slotOf(tokenId_).toString(),
                            '","properties":',
                            _tokenProperties(tokenId_),
                            "}"
                            /* solhint-enable */
                        )
                    )
                )
            );
    }

    function _name() internal pure returns (string memory) {
        return "Samoyed";
    }

    function _description() internal pure returns (string memory) {
        return "Just samoyed!";
    }

    function _slotName(uint256 slot_) internal pure returns (string memory) {
        slot_;
        return "Samoyed";
    }

    function _slotDescription(uint256 slot_) internal pure returns (string memory) {
        slot_;
        return _description();
    }

    function _slotImage(uint256 slot_) internal pure returns (bytes memory) {
        slot_;
        return "";
    }

    function _slotProperties(uint256 slot_) internal pure returns (string memory) {
        slot_;
        return "[]";
    }

    function _tokenName(uint256 tokenId_) internal pure returns (string memory) {
        // solhint-disable-next-line
        return 
            string(
                abi.encodePacked(
                    _name(), 
                    " #", tokenId_.toString()
                )
            );
    }

    function _tokenProperties(uint256 tokenId_) internal pure returns (string memory) {
        tokenId_;
        return "{}";
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IERC3525ExtendedUpgradeable {

    function getUserFirstTokenIdInSlot(address _owner, uint _slot) external view returns (uint tokenId_);

    function getTokenIndexInSlot(uint _tokenId) external view returns (uint index_);

    function getTokenIdInSlot(uint _slot, uint _index) external view returns (uint tokenId_);

    function getOwnerInSlot(uint _slot, uint _index) external view returns (address owner_);

    function slotBalanceOf(uint _slot, address _owner) external view returns (uint count_);

    function slotCurrentSupply(uint _slot) external view returns (uint supply_);

    function transferFromSlot(
        uint _fromIndex,
        uint _toIndex,
        uint _slot,
        uint _value
    ) external payable;
    
    function transferFromSlot(
        uint _fromIndex,
        address _to,
        uint _slot,
        uint _value
    ) external payable returns (uint);

    function transferFromSlot(
        address _from,
        address _to,
        uint _index,
        uint _slot
    ) external payable;

    function safeTransferFromSlot(
        address _from,
        address _to,
        uint _index,
        uint _slot,
        bytes memory _data
    ) external payable;

    function safeTransferFromSlot(
        address _from,
        address _to,
        uint _index,
        uint _slot
    ) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import './Utils.sol';

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('g', _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('path', _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('text', _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<![CDATA[', _content, ']]>');
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('radialGradient', _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                'stop',
                string.concat(
                    prop('stop-color', stopColor),
                    ' ',
                    prop('offset', string.concat(utils.uint2str(offset), '%')),
                    ' ',
                    _props
                )
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animateTransform', _props);
    }

    function image(string memory _href, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return
            el(
                'image',
                string.concat(prop('href', _href), ' ', _props)
            );
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '/>'
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
    }

    function whiteRect() internal pure returns (string memory) {
        return rect(
            string.concat(
                prop('width','100%'),
                prop('height', '100%'),
                prop('fill', 'white')
            )
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = '';

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('--', _key, ':', _val, ';');
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat('var(--', _key, ')');
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat('url(#', _id, ')');
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat('0.', utils.uint2str(_a))
            : '1';
        return
            string.concat(
                'rgba(',
                utils.uint2str(_r),
                ',',
                utils.uint2str(_g),
                ',',
                utils.uint2str(_b),
                ',',
                formattedA,
                ')'
            );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint; 

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

    function getFineSandSeed(bytes memory hash) internal pure returns (uint256) {return uint256(toUint8(hash, 7)); } 

    function getFineSandOctaves(bytes memory hash) internal pure returns (uint256) {return 1 + uint256(toUint8(hash, 8))/64; } 

    function getColourOffsetShift(bytes memory hash, uint256 offsetIndex) internal pure returns (uint256) {
        if(offsetIndex == 0 ) { return uint256(toUint8(hash, 9))/128; }
        if(offsetIndex == 1 ) { return uint256(toUint8(hash, 10))/128; }
        return uint256(toUint8(hash, 11))/128;
    } 

    function getColourOffsetChange(bytes memory hash, uint256 offsetIndex) internal pure returns (uint256) {

        if(offsetIndex == 0 ) { return uint256(toUint8(hash, 12))*100/256; }
        if(offsetIndex == 1 ) { return uint256(toUint8(hash, 13))*100/256; }
        return uint256(toUint8(hash, 14))*100/256;
    } 

    function generateDecimalString(uint nr, uint decimals) internal pure returns (string memory) {
        if(decimals == 1) { return string(abi.encodePacked('0.', uint2str(nr))); }
        if(decimals == 2) { return string(abi.encodePacked('0.0', uint2str(nr))); }
        if(decimals == 3) { return string(abi.encodePacked('0.00', uint2str(nr))); }
        return string(abi.encodePacked('0.000', uint2str(nr)));
    }
}