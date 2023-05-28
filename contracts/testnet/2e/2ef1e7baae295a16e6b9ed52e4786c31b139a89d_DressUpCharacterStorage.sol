// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <[email protected]>.
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding)
        internal
        pure
        returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(0, mload(and(shr(18, input), 0x3F)))
                    mstore8(1, mload(and(shr(12, input), 0x3F)))
                    mstore8(2, mload(and(shr(6, input), 0x3F)))
                    mstore8(3, mload(and(input, 0x3F)))
                    mstore(ptr, mload(0x00))

                    ptr := add(ptr, 4) // Advance 4 bytes.

                    if iszero(lt(ptr, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))

                // Equivalent to `o = [0, 2, 1][dataLength % 3]`.
                let o := div(2, mod(dataLength, 3))

                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore(sub(ptr, o), shl(240, 0x3d3d))
                // Set `o` to zero if there is padding.
                o := mul(iszero(iszero(noPadding)), o)
                // Zeroize the slot after the string.
                mstore(sub(ptr, o), 0)
                // Write the length of the string.
                mstore(result, sub(encodedLength, o))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe)
        internal
        pure
        returns (string memory result)
    {
        result = encode(data, fileSafe, false);
    }

    /// @dev Decodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let decodedLength := mul(shr(2, dataLength), 3)

                for {} 1 {} {
                    // If padded.
                    if iszero(and(dataLength, 3)) {
                        let t := xor(mload(add(data, dataLength)), 0x3d3d)
                        // forgefmt: disable-next-item
                        decodedLength := sub(
                            decodedLength,
                            add(iszero(byte(30, t)), iszero(byte(31, t)))
                        )
                        break
                    }
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                    break
                }
                result := mload(0x40)

                // Write the length of the bytes.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, decodedLength)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    // forgefmt: disable-next-item
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)

                    if iszero(lt(ptr, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
                // Zeroize the slot after the bytes.
                mstore(end, 0)
                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solady (https://github.com/vectorized/solmady/blob/main/src/utils/SSTORE2.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev We skip the first byte as it's a STOP opcode,
    /// which ensures the contract can't be called.
    uint256 internal constant DATA_OFFSET = 1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the storage contract.
    error DeploymentFailed();

    /// @dev The storage contract address is invalid.
    error InvalidPointer();

    /// @dev Attempt to read outside of the storage contract's bytecode bounds.
    error ReadOutOfBounds();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         WRITE LOGIC                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    function write(bytes memory data) internal returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, DATA_OFFSET)

            /**
             * ------------------------------------------------------------------------------+
             * Opcode      | Mnemonic        | Stack                   | Memory              |
             * ------------------------------------------------------------------------------|
             * 61 codeSize | PUSH2 codeSize  | codeSize                |                     |
             * 80          | DUP1            | codeSize codeSize       |                     |
             * 60 0xa      | PUSH1 0xa       | 0xa codeSize codeSize   |                     |
             * 3D          | RETURNDATASIZE  | 0 0xa codeSize codeSize |                     |
             * 39          | CODECOPY        | codeSize                | [0..codeSize): code |
             * 3D          | RETURNDATASIZE  | 0 codeSize              | [0..codeSize): code |
             * F3          | RETURN          |                         | [0..codeSize): code |
             * 00          | STOP            |                         |                     |
             * ------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                data,
                or(
                    0x61000080600a3d393df300,
                    // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                    shl(0x40, dataSize)
                )
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(dataSize, 0xa))

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Writes `data` into the bytecode of a storage contract with `salt`
    /// and returns its deterministic address.
    function writeDeterministic(bytes memory data, bytes32 salt)
        internal
        returns (address pointer)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, DATA_OFFSET)

            mstore(data, or(0x61000080600a3d393df300, shl(0x40, dataSize)))

            // Deploy a new contract with the generated creation code.
            pointer := create2(0, add(data, 0x15), add(dataSize, 0xa), salt)

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Returns the initialization code hash of the storage contract for `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(bytes memory data) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, DATA_OFFSET)

            mstore(data, or(0x61000080600a3d393df300, shl(0x40, dataSize)))

            hash := keccak256(add(data, 0x15), add(dataSize, 0xa))

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Returns the address of the storage contract for `data`
    /// deployed with `salt` by `deployer`.
    function predictDeterministicAddress(bytes memory data, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(data);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         READ LOGIC                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns all the `data` from the bytecode of the storage contract at `pointer`.
    function read(address pointer) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Offset all indices by 1 to skip the STOP opcode.
            let size := sub(pointerCodesize, DATA_OFFSET)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), DATA_OFFSET, size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the end of the data stored.
    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > start)`, reverts.
            // This also handles the case where `start + DATA_OFFSET` overflows.
            if iszero(gt(pointerCodesize, start)) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(pointerCodesize, add(start, DATA_OFFSET))

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the byte at `end` (exclusive) of the data stored.
    function read(address pointer, uint256 start, uint256 end)
        internal
        view
        returns (bytes memory data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > end) || (start > end)`, revert.
            // This also handles the cases where
            // `end + DATA_OFFSET` or `start + DATA_OFFSET` overflows.
            if iszero(
                and(
                    gt(pointerCodesize, end), // Within bounds.
                    iszero(gt(start, end)) // Valid range.
                )
            ) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(end, start)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {StatusHandler} from "./lib/StatusHandler.sol";
import {ImageDataHandler} from "./lib/ImageDataHandler.sol";
import {DataURIHandler} from "./lib/DataURIHandler.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DressUpCharacterStorage is Ownable, DataURIHandler {
    using Strings for uint256;

    /* /////////////////////////////////////////////////////////////////////////////
    Setter
    ///////////////////////////////////////////////////////////////////////////// */

    function setImageDatas(uint256 imageId, bytes memory data, uint256 categoryId, uint256 transformId, uint256 styleId)
        external
        onlyOwner
    {
        _setImageDatas(imageId, data, categoryId, transformId, styleId);
    }

    function updateImageDatas(
        uint256 imageId,
        address pointer,
        uint256 categoryId,
        uint256 transformId,
        uint256 styleId
    ) external onlyOwner {
        _updateImageDatas(imageId, pointer, categoryId, transformId, styleId);
    }

    function setTransformDatas(uint256 index, bytes memory data) external onlyOwner {
        _setOptionDatas(index, data, 0);
    }

    function setStyleDatas(uint256 index, bytes memory data) external onlyOwner {
        _setOptionDatas(index, data, 1);
    }

    // few many people
    function setCharacterDatas(uint256 tokenId, uint256[] memory imageIds) external {
        _checkCategolyId(imageIds);
        _setStructureDatas(tokenId, imageIds, 0);
    }

    // onlyowner
    function setPartsDatas(uint256 tokenId, uint256[] memory imageIds) external onlyOwner {
        _setStructureDatas(tokenId, imageIds, 1);
    }
    /* /////////////////////////////////////////////////////////////////////////////
    Getter
    ///////////////////////////////////////////////////////////////////////////// */

    function characterRender(uint256 tokenId) public view returns (string memory) {
        return _render(tokenId, 0);
    }

    function partsRender(uint256 tokenId) public view returns (string memory) {
        return _render(tokenId, 1);
    }

    // function createDataURI(uint256 tokenId, uint256 slot, uint256 iconCheck) public view returns (string memory) {
    //     // string memory imageURI;

    //     // if (iconCheck == 0) {
    //     //     imageURI = Base64.encode(bytes(_characterRender(tokenId, slot)));
    //     // } else {
    //     //     imageURI = Base64.encode(bytes(_iconCharacterRender(tokenId, slot)));
    //     // }

    //     string memory imageURI = Base64.encode(bytes(_characterRender(tokenId, slot)));

    //     // string memory json = Base64.encode(
    //     //     bytes(
    //     //         string(
    //     //             abi.encodePacked(
    //     //                 "{",
    //     //                 '"name":"',
    //     //                 "test-dress-uo-character",
    //     //                 tokenId.toString(),
    //     //                 '",',
    //     //                 '"description":"description",',
    //     //                 '"attributes":[',
    //     //                 createStatusTrait(status[tokenId]),
    //     //                 ',{"trait_type":"traitA","value":"valueA"}',
    //     //                 "],",
    //     //                 '"image": "data:image/svg+xml;base64,',
    //     //                 imageURI,
    //     //                 '"',
    //     //                 "}"
    //     //             )
    //     //         )
    //     //     )
    //     // );

    //     string memory json = string(
    //         abi.encodePacked(
    //             "{",
    //             '"name":"',
    //             "test-dress-uo-character",
    //             tokenId.toString(),
    //             '",',
    //             '"description":"description",',
    //             '"attributes":[',
    //             createStatusTrait(status[tokenId]),
    //             ',{"trait_type":"traitA","value":"valueA"}',
    //             "],",
    //             '"image": "data:image/svg+xml;base64,',
    //             imageURI,
    //             '"',
    //             "}"
    //         )
    //     );

    //     json = string(abi.encodePacked("data:application/json;base64,", json));
    //     return json;
    // }

    // function createDataURI(uint256 tokenId, uint256 slot, uint256 markCheck)
    //     public
    //     view
    //     returns (string memory result)
    // {
    //     assembly {
    //         function toStr(p, x) -> rp {
    //             // use scratch space
    //             let ss := 0x20
    //             for {} 1 {} {
    //                 ss := sub(ss, 1)

    //                 mstore8(ss, add(48, mod(x, 10)))
    //                 x := div(x, 10)
    //                 if iszero(x) { break }
    //             }
    //             mstore(p, mload(ss))
    //             rp := add(p, sub(0x20, ss))
    //         }

    //         // Set `result` to point to the start of the free memory.
    //         result := mload(0x40)

    //         // Skip the first slot, which stores the length.
    //         let mc := add(result, 0x20)

    //         // data:application/json;charset=utf-8;, ???
    //         mstore(mc, "data:application/json;base64,")
    //         mc := add(mc, 29)

    //         mstore(mc, '{"name":"')
    //         mc := add(mc, 9)

    //         mstore(mc, "test")
    //         mc := add(mc, 4)

    //         // tokenId.toString(),
    //         mc := toStr(mc, tokenId)

    //         mstore(mc, '","description":"')
    //         mc := add(mc, 17)

    //         mstore(mc, "description")
    //         mc := add(mc, 11)

    //         mstore(mc, '","attributes":[')
    //         mc := add(mc, 16)

    //         mstore(mc, "createStatusTrait(status[tokenId")
    //         mc := add(mc, 32)

    //         mstore(mc, "])")
    //         mc := add(mc, 2)

    //         mstore(mc, ',{"trait_type":"traitA","value":')
    //         mc := add(mc, 32)

    //         mstore(mc, '"valueA"}')
    //         mc := add(mc, 9)

    //         mstore(mc, "],")
    //         mc := add(mc, 2)

    //         mstore(mc, '"image":"data:image/svg+xml;base')
    //         mc := add(mc, 32)

    //         mstore(mc, "64,")
    //         mc := add(mc, 3)

    //         // imageURI
    //         // bytes4(keccak256("createImageURI(uint256,uint256)"))
    //         mstore(0x00, 0x4b96326d)
    //         mstore(0x20, tokenId)
    //         mstore(0x40, slot)

    //         pop(staticcall(gas(), address(), 0x1c, 0x44, 0x00, 0x00))
    //         returndatacopy(mc, 0x40, sub(returndatasize(), 0x40))

    //         mc := add(mc, sub(returndatasize(), 0x4c))

    //         mstore(mc, '"}')
    //         mc := add(mc, 2)

    //         // // base64Encode

    //         // write memory space
    //         mstore(result, sub(sub(mc, 0x20), result))
    //         mstore(0x40, and(add(add(result, mc), 31), not(31)))
    //     }

    //     return Base64.encode(bytes(result));
    // }

    // for specialCharacter
    // function secondConcatCharacterRender(uint256 characterId, uint256 slot) public view returns (string memory data) {
    //     return _secondConcatCharacterRender(characterId, slot);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {StatusHandler} from "./StatusHandler.sol";
import {ImageDataHandler} from "./ImageDataHandler.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

abstract contract DataURIHandler is StatusHandler, ImageDataHandler {
    /* /////////////////////////////////////////////////////////////////////////////
    Create dataURI
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev createDataURI(uri encode / image svg base64 encode)
    /// @param tokenId uint96
    /// @param slot characterDatas [slot = 0] / partsDatas [slot = 1]
    function createDataURI(uint256 tokenId, uint256 slot) public view returns (string memory result) {
        assembly {
            /// @dev uint to String
            /// @param sp start pointer
            /// @param x uint96
            /// @return	rp end pointer
            function toStr(sp, x) -> ep {
                // use scratch space
                let ss := 0x20
                for {} 1 {} {
                    ss := sub(ss, 1)

                    mstore8(ss, add(48, mod(x, 10)))
                    x := div(x, 10)
                    if iszero(x) { break }
                }
                mstore(sp, mload(ss))
                ep := add(sp, sub(0x20, ss))
            }

            // Set `result` to point to the start of the free memory.
            result := mload(0x40)

            // Skip the first slot, which stores the length.
            let mc := add(result, 0x20)

            mstore(mc, "data:application/json,")
            mc := add(mc, 29)

            // '{"name":"')
            mstore(mc, '{"name":"')
            mc := add(mc, 9)
            // mstore(mc, "%7B%22name%22%3A%22")
            // mc := add(mc, 19)

            mstore(mc, "test")
            mc := add(mc, 4)

            // tokenId.toString(),
            mc := toStr(mc, tokenId)

            // ","description":"
            mstore(mc, ',"description":')
            mc := add(mc, 15)
            // mstore(mc, "%22%2C%22description%22%3A%22")
            // mc := add(mc, 29)

            mstore(mc, "description")
            mc := add(mc, 11)

            // ","attributes":["
            mstore(mc, ',"attributes":[')
            mc := add(mc, 15)
            // mstore(mc, "%22%2C%22attributes%22%3A%5B")
            // mc := add(mc, 28)

            let len

            // // status
            // // bytes4(keccak256("createStatusTrait(uint256)"))
            // mstore(0x00, 0x9853c741)
            // mstore(0x20, tokenId)
            // pop(staticcall(gas(), address(), 0x1c, 0x24, 0x00, 0x00))

            // // data.len
            // returndatacopy(0x00, 0x20, 0x20)
            // let len := mload(0x00)

            // // data
            // returndatacopy(mc, 0x40, len)
            // mc := add(mc, len)

            // '{"trait_type":"traitA","value":"valueA"}'
            mstore(mc, '{"trait_type":"traitA","value":"')
            mc := add(mc, 32)

            mstore(mc, 'valueA"}')
            mc := add(mc, 8)

            // mstore(mc, "%7B%22trait_type%22%3A%22trai")
            // mc := add(mc, 32)

            // mstore(mc, "tA%22%2C%22value%22%3A%22valueA%")
            // mc := add(mc, 32)

            // mstore(mc, "22%7D")
            // mc := add(mc, 5)

            // "],"
            mstore(mc, "],")
            mc := add(mc, 2)
            // mstore(mc, "%5D%2C")
            // mc := add(mc, 6)

            // '"image":"'
            mstore(mc, '"image":"')
            mc := add(mc, 9)

            // mstore(mc, "%22image%22%3A%22")
            // mc := add(mc, 17)

            // // mstore(mc, '"image":"data:image/svg+xml;base64,')
            // mstore(mc, "%22image%22%3A%22data%3Aimage%2F")
            // mc := add(mc, 32)

            // mstore(mc, "svg%2Bxml%3Bbase64%2C")
            // mc := add(mc, 21)

            // imageURI
            // bytes4(keccak256("characterRender(uint256)"))
            mstore(0x00, 0xe1c47cdf)
            mstore(0x20, tokenId)
            // mstore(0x40, slot)

            // pop(staticcall(gas(), address(), 0x1c, 0x44, 0x00, 0x00))
            pop(staticcall(gas(), address(), 0x1c, 0x24, 0x00, 0x00))

            // data.len
            returndatacopy(0x00, 0x20, 0x20)
            len := mload(0x00)

            // data
            returndatacopy(mc, 0x40, len)

            mc := add(mc, len)

            // '"}'
            mstore(mc, '"}')
            mc := add(mc, 2)

            // mstore(mc, "%22%7D")
            // mc := add(mc, 6)

            // write memory space
            mstore(result, sub(sub(mc, 0x20), result))
            mstore(0x40, and(add(add(result, mc), 31), not(31)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {Base64} from "solady/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LibBase64} from "contracts/lib/LibBase64.sol";

abstract contract ImageDataHandler {
    using SSTORE2 for bytes;
    using SSTORE2 for address;
    using Strings for uint256;
    using Strings for string;

    uint256 private constant _MASK_UINT8 = (1 << 8) - 1;
    uint256 private constant _MASK_UINT16 = (1 << 16) - 1;

    // _IMAGE_DATAS / _CHARACTER_DATAS_SEED / _TRANSFORM_DATAS / _STYLE_DATAS_SEED
    uint256 private constant _CHARACTER_DATAS_SEED = 0xfbbce30ee466491e8e2a671f95d3935e;

    // _IMAGE_DATAS / _PARTS_DATAS_SEED / _TRANSFORM_DATAS / _STYLE_DATAS_SEED
    uint256 private constant _PARTS_DATAS_SEED = 0xfbbce30e05e534fb8e2a671f95d3935e;

    // string _prefixDataURI = "data:image/svg+xml;utf8,";
    // string _prefix = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">';
    // string _suffix = "</svg>";

    // string _prefixStyle = '<style type="text/css">';
    // string _suffixStyle = "</style>";

    // string _prefixIcon =
    //     '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" preserveAspectRatio="xMidYMid slice"><clipPath id="mark"><circle cx="500" cy="500" r="250" fill="#000"></circle></clipPath>';
    // string _suffixGrope = "</symbol>";

    // string _useContentConcat =
    //     '<use href="#3" x="0" y="0"/><use href="#4" x="0" y="0"/><use href="#5" x="0" y="0"/><use href="#6" x="0" y="0"/><use href="#7" x="0" y="0"/><use href="#8" x="0" y="0"/>';

    modifier onlyMultiple3(bytes memory data) {
        LibBase64.checkStringLength(data);
        _;
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Error
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev
    error IncorrectValue();

    /// @dev Argument types do not match.`0xb4902a13`
    error TypeMismatch();

    /// @dev Array length is incorrect.`0x3be6499c`
    error IncorrectArrayLength();

    /// @dev Not available due to default index.`0x27324a04`
    error NotAvailableDefaultIndex();

    /// @dev String length must be a multiple of 3.`0x9959fc03`
    error StringLengthNotMultiple3();

    /* /////////////////////////////////////////////////////////////////////////////
    IMAGE_DATAS
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev set imageDatas[imageId] = imageData
    /// imageData = addres  / uint8      / uint16      / uint16  / uint56
    ///             pointer / categoryId / transformId / styleId / blank
    /// @param data bytes onlyMultiple3(base64 encoded) => address(SSTORE2)
    /// @param categoryId uint8
    /// @param transformId uint16
    /// @param styleId uint16
    function _setImageDatas(
        uint256 imageId,
        bytes memory data,
        uint256 categoryId,
        uint256 transformId,
        uint256 styleId
    ) internal onlyMultiple3(data) {
        address pointer = data.write();

        assembly {
            // check uint8
            if lt(255, categoryId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            // check uint16
            if lt(65535, transformId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            // check uint16
            if lt(65535, styleId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            categoryId := and(categoryId, _MASK_UINT8)
            transformId := and(transformId, _MASK_UINT16)
            styleId := and(styleId, _MASK_UINT16)

            let imageData := or(or(or(shl(96, pointer), shl(88, categoryId)), shl(72, transformId)), shl(56, styleId))

            // write to storage
            mstore(0x16, _CHARACTER_DATAS_SEED)
            mstore(0x00, imageId)
            sstore(keccak256(0x00, 0x24), imageData)
        }
    }

    /// @dev update imageDatas[imageId] = imageData
    /// imageData = addres  / uint8      / uint16      / uint16  / uint56
    ///             pointer / categoryId / transformId / styleId / blank
    /// @param pointer address(SSTORE2)
    /// @param categoryId uint8
    /// @param transformId uint16
    /// @param styleId uint16
    function _updateImageDatas(
        uint256 imageId,
        address pointer,
        uint256 categoryId,
        uint256 transformId,
        uint256 styleId
    ) internal {
        assembly {
            // check uint8
            if lt(255, categoryId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            // check uint16
            if lt(65535, transformId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            // check uint16
            if lt(65535, styleId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            categoryId := and(categoryId, _MASK_UINT8)
            transformId := and(transformId, _MASK_UINT16)
            styleId := and(styleId, _MASK_UINT16)

            let imageData := or(or(or(shl(96, pointer), shl(88, categoryId)), shl(72, transformId)), shl(56, styleId))

            // write to storage
            mstore(0x16, _CHARACTER_DATAS_SEED)
            mstore(0x00, imageId)
            sstore(keccak256(0x00, 0x24), imageData)
        }
    }

    /// @dev get imageDatas[imageId]
    /// imageData = addres  / uint8      / uint16      / uint16  / uint56
    ///             pointer / categoryId / transformId / styleId / blank
    /// @param pointer address(SSTORE2)
    /// @param categoryId uint8
    /// @param transformId uint16
    /// @param styleId uint16
    function getImageDatas(uint256 imageId)
        public
        view
        returns (address pointer, uint256 categoryId, uint256 transformId, uint256 styleId)
    {
        assembly {
            // read to storage
            mstore(0x16, _CHARACTER_DATAS_SEED)
            mstore(0x00, imageId)
            let value := sload(keccak256(0x00, 0x24))

            pointer := shr(96, value)
            categoryId := and(_MASK_UINT8, shr(88, value))
            transformId := and(_MASK_UINT16, shr(72, value))
            styleId := and(_MASK_UINT16, shr(56, value))
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    CHARACTER_DATAS [slot = 0] / PARTS_DATAS [slot = 1]
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev set StructureDatas[tokenId] = characterDatas / partsDatas
    /// structureDatas = uint16 parts / ... / uint16 parts / uint16 length
    /// [attention]Not checked to see if it's something I can set.
    /// @param imageIds array.length < 16
    /// @param slot characterDatas [slot = 0] / partsDatas [slot = 1]
    function _setStructureDatas(uint256 tokenId, uint256[] memory imageIds, uint256 slot) internal {
        assembly {
            let packed := mload(imageIds)

            // imageIds.length <= 15
            if lt(15, packed) {
                mstore(0x00, 0x3be6499c) // `IncorrectArrayLength()`
                revert(0x1c, 0x04)
            }

            for {
                // loop setting
                let cc := 0
                let ptr := add(imageIds, 0x20)
                let last := packed
            } lt(cc, last) {
                cc := add(cc, 1)
                ptr := add(ptr, 0x20)
            } {
                // packed = imageId / imageId / imageId / ... / imageIds.length
                packed := or(packed, shl(mul(add(cc, 1), 16), and(mload(ptr), _MASK_UINT16)))
            }

            // write to storage
            mstore(0x12, add(_CHARACTER_DATAS_SEED, iszero(iszero(slot))))
            mstore(0x00, tokenId)
            sstore(keccak256(0x00, 0x24), packed)
        }
    }

    /// @dev check imageIds.index === categoryId
    /// @param imageIds 0 < array.length < 16
    function _checkCategolyId(uint256[] memory imageIds) internal view {
        assembly {
            let len := mload(imageIds)
            for {
                // loop setting
                let cc := 0
                let ptr := add(imageIds, 0x20)
                let last := len
            } lt(cc, last) {
                cc := add(cc, 1)
                ptr := add(ptr, 0x20)
            } {
                // read to storage
                mstore(0x16, _CHARACTER_DATAS_SEED)
                mstore(0x00, mload(ptr))
                let value := sload(keccak256(0x00, 0x24))

                let categoryId := and(_MASK_UINT8, shr(88, value))

                if categoryId {
                    if iszero(eq(categoryId, cc)) {
                        mstore(0x00, 0xd2ade556) // `IncorrectValue()`
                        revert(0x1c, 0x04)
                    }
                }
            }
        }
    }

    /// @dev get structureDatas[tokenId]
    /// characterData = uint16 parts / ... / uint16 parts / uint16 length
    /// @param index index < 15 --> target imageId / 16 --> characterId
    /// @param slot characterDatas [slot = 0] / partsDatas [slot = 1]
    /// @return value index < 15 --> target imageId / 16 --> characterId
    function getStructureDatas(uint256 tokenId, uint256 index, uint256 slot) public view returns (uint256 value) {
        assembly {
            // read to storage
            mstore(0x12, add(_CHARACTER_DATAS_SEED, iszero(iszero(slot))))
            mstore(0x00, tokenId)
            value := sload(keccak256(0x00, 0x24))

            if iszero(eq(index, 16)) { value := and(_MASK_UINT16, shr(mul(index, 16), value)) }
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    _TRANSFORM_DATAS [slot = 0] / _STYLE_DATAS_SEED [slot = 1]
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev set OptionDatas[optionId] = transformDatas / styleDatas
    /// @param optionId uint16 (Because uint16 transformId / uint16 styleId)
    /// Not available due to default index 0.
    /// 0 < optionId < 65536
    /// @param data bytes onlyMultiple3(base64 encoded) => address(SSTORE2)
    /// @param slot transformDatas [slot = 0] / styleDatas [slot = 1]
    function _setOptionDatas(uint256 optionId, bytes memory data, uint256 slot) internal onlyMultiple3(data) {
        assembly {
            // check uint16
            if iszero(optionId) {
                mstore(0x00, 0x27324a04) // `NotAvailableDefaultIndex()`
                revert(0x1c, 0x04)
            }

            // check uint16
            if lt(65535, optionId) {
                mstore(0x00, 0xb4902a13) // `TypeMismatch()`
                revert(0x1c, 0x04)
            }

            slot := mul(0x04, add(iszero(slot), 1))
            mstore(slot, _CHARACTER_DATAS_SEED)
            mstore(0x00, optionId)
            slot := keccak256(0x00, 0x24)

            let len := mload(data)

            switch lt(len, 32)
            // length < 32
            case 1 {
                // (value & length) set to slot
                sstore(slot, add(mload(add(data, 0x20)), mul(len, 2)))
            }
            // length >= 32
            default {
                // length info set to slot
                sstore(slot, add(mul(len, 2), 1))

                // key
                mstore(0x0, slot)
                let sc := keccak256(0x00, 0x20)

                // value set
                for {
                    let mc := add(data, 0x20)
                    let end := add(mc, len)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }
            }
        }
    }

    /// @dev OptionDatas[optionId]
    /// @param optionId uint16 (Because uint16 transformId / uint16 styleId)
    /// @param slot transformDatas [slot = 0] / styleDatas [slot = 1]
    function getOptionDatas(uint256 optionId, uint256 slot) public view returns (string memory data) {
        assembly {
            // free memory pointer
            data := mload(0x40)

            slot := mul(0x04, add(iszero(slot), 1))
            mstore(slot, _CHARACTER_DATAS_SEED)
            mstore(0x00, optionId)
            slot := keccak256(0x00, 0x24)

            let value := sload(slot)
            let len := div(and(value, sub(mul(0x100, iszero(and(value, 1))), 1)), 2)
            let mc := add(data, 0x20)

            // set length
            mstore(data, len)

            // set value
            switch lt(len, 32)
            // length < 32
            case 1 { mstore(mc, value) }
            // length >= 32
            default {
                // key
                mstore(0x0, slot)
                let sc := keccak256(0x00, 0x20)

                for { let end := add(mc, len) } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { mstore(mc, sload(sc)) }
            }

            mstore(0x40, and(add(add(mc, len), 31), not(31)))
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    SVG render
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev get svg data
    /// @param slot characterDatas [slot = 0] / partsDatas [slot = 1]
    function _render(uint256 tokenId, uint256 slot) internal view returns (string memory result) {
        assembly {
            /// @dev uint to String
            /// @param sp start pointer
            /// @param x uint16
            /// @return	ep end pointer
            function encode64(sp, x) -> ep {
                // use scratch space
                let ss := 0x20
                for {} 1 {} {
                    ss := sub(ss, 1)

                    mstore8(ss, add(48, mod(x, 10)))
                    x := div(x, 10)
                    if iszero(x) { break }
                }

                // padding '//'
                mstore(0x20, "//")
                let input := mload(ss)

                // base64 encode materials
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, "ghijklmnopqrstuvwxyz0123456789+/")

                // base64 encode
                for {} 1 { input := shl(24, input) } {
                    mstore8(0, mload(and(shr(250, input), 0x3F)))
                    mstore8(1, mload(and(shr(244, input), 0x3F)))
                    mstore8(2, mload(and(shr(238, input), 0x3F)))
                    mstore8(3, mload(and(shr(232, input), 0x3F)))
                    mstore(sp, mload(0x00))

                    sp := add(sp, 4)
                    ss := add(ss, 0x03)

                    if iszero(lt(ss, 0x20)) { break }
                }
                ep := sp
            }

            function getStr(p, i, n) -> rp {
                // getStyleDatas
                mstore(n, _CHARACTER_DATAS_SEED)
                mstore(0x00, i)
                i := keccak256(0x00, 0x24)
                let v := sload(i)

                let len := div(and(v, sub(mul(0x100, iszero(and(v, 1))), 1)), 2)

                // set value
                switch lt(len, 32)
                // length < 32
                case 1 { mstore(p, v) }
                // length >= 32
                default {
                    // key
                    mstore(0x00, i)
                    let sc := keccak256(0x00, 0x20)

                    for { let end := add(p, len) } lt(p, end) {
                        sc := add(sc, 1)
                        p := add(p, 0x20)
                    } { mstore(p, sload(sc)) }
                }

                rp := add(p, len)
            }

            // Set `ImageData` to point to the start of the free memory.
            let imageDataPtr := mload(0x40)

            // getCharacterDatas(uint256 characterId, uint256 index, uint256 slot) --> (uint256 imageId)
            mstore(0x12, add(_CHARACTER_DATAS_SEED, iszero(iszero(slot))))
            mstore(0x00, tokenId)
            let temp := sload(keccak256(0x00, 0x24))

            // len
            let imageDataLen := and(_MASK_UINT16, temp)
            let index

            // memory counter
            let mc := imageDataPtr

            for { let i := 1 } 1 {
                mc := add(mc, 0x20)
                i := add(i, 1)
            } {
                // imageId
                index := and(_MASK_UINT16, shr(mul(i, 16), temp))

                mstore(0x16, _CHARACTER_DATAS_SEED)
                mstore(0x00, index)
                index := sload(keccak256(0x00, 0x24))

                mstore(mc, index)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // free memory pointer
            mstore(0x40, add(mc, 0x20))

            // return data
            result := mload(0x40)

            // Skip the first slot, which stores the length.
            mc := add(result, 0x20)

            // // mstore(mc, 'data:image/svg+xml;base64,')
            // mstore(mc, "data%3Aimage%2Fsvg%2Bxml%3Bbase6")
            // mc := add(mc, 32)

            // mstore(mc, "4%2C")
            // mc := add(mc, 4)

            mstore(mc, "data:image/svg+xml;base64,")
            mc := add(mc, 26)

            // <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">
            mstore(mc, "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53")
            mc := add(mc, 32)

            mstore(mc, "My5vcmcvMjAwMC9zdmciICAgdmlld0Jv")
            mc := add(mc, 32)

            mstore(mc, "eD0iMCAwIDEwMDAgMTAwMCI+")
            mc := add(mc, 24)

            // symbol
            for {
                let i := 0
                let cc
            } 1 { i := add(i, 1) } {
                // getTransformDatas(transformId)
                temp := mload(add(imageDataPtr, cc))

                if temp {
                    // <symbol id="
                    mstore(mc, "PHN5bWJvbCBpZD0i")
                    mc := add(mc, 16)

                    // transformId
                    index := and(_MASK_UINT8, shr(88, temp))
                    // i.toString
                    mc := encode64(mc, index)

                    // ">
                    mstore(mc, "IiA+")
                    mc := add(mc, 4)

                    // SSTORE2 pointer_.read()
                    temp := mload(add(imageDataPtr, cc))

                    // pointer
                    index := shr(96, temp)

                    let pointerCodesize := extcodesize(index)
                    if iszero(pointerCodesize) { pointerCodesize := 1 }

                    // Offset all indices by 1 to skip the STOP opcode.
                    let size := sub(pointerCodesize, 1)

                    extcodecopy(index, mc, 1, size)
                    mc := add(mc, size)

                    // </symbol>
                    mstore(mc, "PC9zeW1ib2w+")
                    mc := add(mc, 12)
                }
                cc := add(cc, 0x20)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // style
            // <style type="text/css">
            mstore(mc, "PHN0eWxlIHR5cGU9InRleHQvY3NzIiA+")
            mc := add(mc, 32)

            for {
                let i := 0
                let cc
            } 1 {
                i := add(i, 1)
                cc := add(cc, 0x20)
            } {
                // _createStyle(styleId_)
                temp := mload(add(imageDataPtr, cc))
                // styleId
                index := and(_MASK_UINT16, shr(56, temp))

                // _getStyleDatas
                mc := getStr(mc, index, 0x04)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // </style>
            mstore(mc, "IDwvc3R5bGU+")
            mc := add(mc, 12)

            // useContent
            for {
                let i := 0
                let cc
            } 1 { i := add(i, 1) } {
                temp := mload(add(imageDataPtr, cc))

                if temp {
                    // <use href="#
                    mstore(mc, "PHVzZSBocmVmPSIj")
                    mc := add(mc, 16)

                    // transformId
                    index := and(_MASK_UINT8, shr(88, temp))

                    // i.toString
                    mc := encode64(mc, index)

                    // " x="0" y="0" transform="
                    mstore(mc, "IiB4PSIwIiB5PSIwIiAgIHRyYW5zZm9y")
                    mc := add(mc, 32)

                    mstore(mc, "bT0i")
                    mc := add(mc, 4)

                    // getTransformDatas(transformId)
                    temp := mload(add(imageDataPtr, cc))

                    // transformId
                    index := and(_MASK_UINT16, shr(72, temp))

                    // _TRANSFORM_DATAS
                    mc := getStr(mc, index, 0x08)

                    // " />
                    mstore(mc, "IiAgIC8+")
                    mc := add(mc, 8)
                }

                cc := add(cc, 0x20)

                if iszero(lt(i, imageDataLen)) { break }
            }

            // </svg>
            mstore(mc, "PC9zdmc+")
            mc := add(mc, 8)

            // write memory space
            mstore(result, sub(sub(mc, 0x20), result))
            mstore(0x40, and(add(add(result, mc), 31), not(31)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Base64} from "solady/utils/Base64.sol";

/// @notice Library to encode strings in Base64.
library LibBase64 {
    /// @dev Check if the length of the string is a multiple of 3.
    function checkStringLength(bytes memory data) internal pure {
        assembly {
            // str.length
            let length := mload(data)

            // Get 32bytes containing the last character
            let check := mload(add(data, length))

            // If the last character is `=` or `==`, an error occurs
            if eq(and(check, 0xff), 0x3d) {
                mstore(0x00, 0x9959fc03) // `StringLengthNotMultiple3()`
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Base64 encoding of values padding with spaces to multiples of 3.
    function paddingStringBase64Encode(string memory str) internal pure returns (string memory) {
        assembly {
            // str.length
            let length := mload(str)

            // memory counter
            let mc := add(str, 0x20)

            // p = [0, 2, 1][len % 3]
            let p := div(2, mod(length, 3))

            // padding ' '(space)
            mstore(add(mc, length), shl(240, 0x2020))

            // Allocate the memory for the string.
            // Add 31 and mask with `not(31)` to round the
            // free memory pointer up the next multiple of 32.
            mstore(0x40, and(add(add(mc, add(length, p)), 31), not(31)))

            // Write the length of the string.
            mstore(str, add(length, p))
        }
        return Base64.encode(bytes(str));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract StatusHandler {
    using Strings for uint256;

    uint256 private constant _MASK_UINT8 = (1 << 8) - 1;

    // string[] _str = ['{"trait_type":', ',"value":', "},", ',"display_type":"number"', ',"max_value":"255"},'];

    string[] _statusName = [
        '"HP"',
        '"MP"',
        '"ATK"',
        '"DEF"',
        '"INT"',
        '"RES"',
        '"AGI"',
        '"DEX"',
        '"EVA"',
        '"LUK"',
        '"WT"',
        '"VIT"',
        '"Strong"',
        '"Weak"'
    ];

    string[] _attributes = ["Fire", "Water", "Electric", "Ground", "Wind", "Ice", "Dark", "Light"];

    /* /////////////////////////////////////////////////////////////////////////////
    Error
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev String < 32 0x4ee45b56
    error TooLong();

    /// @dev need to expand array.length 0xc758bb9e
    error ArrayIsShort();

    /// @dev Available slots are predetermined. 0x172ca015
    error NotAvailableSlot();

    /* /////////////////////////////////////////////////////////////////////////////
    Error
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev set characterBasicDatas[characterId] = name / status
    /// @param characterId uint256
    /// name string / length < 32
    /// status uint256
    /// @return result parameter
    function createStatusTrait(uint256 characterId) public view returns (string memory result) {
        (string memory name, uint256 value) = getCharacterBasicDatas(characterId);
        name;
        assembly {
            // tager slot value -> set memory & return len
            function setMemorySlot(slot, sc, mc, len) -> rlen {
                slot := sload(add(slot, sc))
                mstore(add(mc, len), slot)
                rlen := add(len, div(and(slot, _MASK_UINT8), 2))
            }

            // _statusName
            mstore(0x00, _statusName.slot)
            let _statusNameSlot := keccak256(0x00, 0x20)

            // _attributes
            mstore(0x00, _attributes.slot)
            let _attributesSlot := keccak256(0x00, 0x20)
            let _attributesLen := sload(_attributes.slot)

            // free memory pointer
            result := mload(0x40)

            // memory counter
            let mc := add(result, 0x20)
            let len := 0

            // concat
            for {
                // loop counter
                let cc := 0
                let temp

                // scratch space
                let ss := 0x20
                let statusLen := sub(sload(_statusName.slot), 2)
            } lt(cc, add(statusLen, 2)) {
                cc := add(cc, 0x01)
                ss := 0x20
            } {
                // str1 '{"trait_type":'
                mstore(add(mc, len), "%7B%22trait_type%22%3A")
                len := add(len, 22)

                // trait
                len := setMemorySlot(_statusNameSlot, cc, mc, len)

                // str2 ',"value":'
                mstore(add(mc, len), "%2C%22value%22%3A")
                len := add(len, 17)

                // status:value
                if lt(cc, statusLen) {
                    // value
                    temp := shr(mul(cc, 8), value)
                    temp := and(temp, _MASK_UINT8)

                    // uint8 -> string
                    // scratch space
                    for {} 1 {} {
                        ss := sub(ss, 1)

                        mstore8(ss, add(48, mod(temp, 10)))
                        temp := div(temp, 10)
                        if iszero(temp) { break }
                    }

                    mstore(add(mc, len), mload(ss))
                    len := add(len, sub(0x20, ss))

                    // str4 ',"display_type":"numbe'
                    mstore(add(mc, len), "%2C%22display_type%22%3A%22numbe")
                    len := add(len, 32)

                    // str5 'r","max_value":"255"},'
                    mstore(add(mc, len), "r%22%2C%22max_value%22%3A%22255")
                    len := add(len, 31)

                    // str6 '"},'
                    mstore(add(mc, len), "%22%7D%2C")
                    len := add(len, 9)
                }

                // _attributes:value
                if lt(statusLen, add(cc, 0x01)) {
                    // str7 '"'
                    mstore(add(mc, len), "%22")
                    len := add(len, 3)

                    for {
                        let i := 0
                        let j := mul(sub(cc, statusLen), 16)
                    } lt(i, _attributesLen) { i := add(i, 1) } {
                        if eq(1, and(1, shr(sub(sub(255, j), i), value))) {
                            len := setMemorySlot(_attributesSlot, i, mc, len)

                            // str8 ','
                            mstore(add(mc, len), "%2C")
                            len := add(len, 3)
                        }
                    }

                    len := sub(len, 3)

                    // str7 '"'
                    mstore(add(mc, len), "%22")
                    len := add(len, 3)

                    // str3 "},"
                    mstore(add(mc, len), "%7D%2C")
                    len := add(len, 6)
                }
            }

            let last := add(mc, len)

            // write memory space
            mstore(result, sub(len, 3))
            mstore(0x40, and(add(last, 31), not(31)))
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    String mapping [ uint256 _STATUS / string _NAME]
    ///////////////////////////////////////////////////////////////////////////// */

    uint256 private constant _CHARACTER_DATAS_SEED = 0xb6eb53efca6e379b;

    // mapping(uint256 => uint256) public status;

    // // ステータスはキャラクター依存？トークン依存？
    // function _setStatus(uint256 tokenId, uint256 value) internal {
    //     status[tokenId] = value;
    // }

    /// @dev set characterBasicDatas[characterId] = name / status
    /// @param characterId uint256
    /// @param name string / length < 32
    /// @param status uint256
    function _setCharacterBasicDatas(uint256 characterId, string memory name, uint256 status) internal {
        assembly {
            // name write to storage
            mstore(0x04, _CHARACTER_DATAS_SEED)
            mstore(0x00, characterId)
            let slot := keccak256(0x00, 0x24)

            // name.length
            let len := mload(name)

            // string.length < 32
            if lt(31, len) {
                mstore(0x00, 0x4ee45b56) // TooLong()
                revert(0x1c, 0x04)
            }

            // (value & length) set to slot
            sstore(slot, add(mload(add(name, 0x20)), mul(len, 2)))

            // status write to storage
            mstore(0x08, _CHARACTER_DATAS_SEED)
            mstore(0x00, characterId)
            slot := keccak256(0x00, 0x24)
            sstore(slot, status)
        }
    }

    /// @dev name / status = characterBasicDatas[characterId]
    /// @param characterId uint256
    /// @return name string / length < 32
    /// @return status uint256
    function getCharacterBasicDatas(uint256 characterId) public view returns (string memory name, uint256 status) {
        assembly {
            // free memory pointer
            name := mload(0x40)

            // name read to storage
            mstore(0x04, _CHARACTER_DATAS_SEED)
            mstore(0x00, characterId)
            let slot := keccak256(0x00, 0x24)

            let value := sload(slot)

            // value.length
            let len := div(and(value, sub(mul(0x100, iszero(and(value, 1))), 1)), 2)
            let mc := add(name, 0x20)

            // set length
            mstore(name, len)

            // because length < 32
            mstore(mc, value)
            mstore(0x40, and(add(add(mc, len), 31), not(31)))

            // status read to storage
            mstore(0x08, _CHARACTER_DATAS_SEED)
            mstore(0x00, characterId)
            slot := keccak256(0x00, 0x24)
            status := sload(slot)
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    String Array [_str / _statusName / _attributes]
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev check slot
    /// @param slot _str[0] / _statusName[1] / _attributes[2]
    /// @return slot _str.slot / _statusName.slot / _attributes.slot
    function _checkSlot(uint256 slot) internal pure returns (uint256) {
        assembly {
            switch slot
            // case 0 { slot := _str.slot }
            case 1 { slot := _statusName.slot }
            case 2 { slot := _attributes.slot }
            default {
                mstore(0x00, 0x172ca015) // NotAvailableSlot()
                revert(0x1c, 0x04)
            }
        }
        return slot;
    }

    /// @dev string array.length = len
    /// @param slot _str[0] / _statusName[1] / _attributes[2]
    /// @param len array.length
    function _setStringArrayLength(uint256 slot, uint256 len) internal {
        slot = _checkSlot(slot);
        assembly {
            sstore(slot, len)
        }
    }

    /// @dev string array.length
    /// @param slot _str[0] / _statusName[1] / _attributes[2]
    /// @return len array.length
    function getStringArrayLength(uint256 slot) external view returns (uint256 len) {
        slot = _checkSlot(slot);
        assembly {
            slot := add(_statusName.slot, iszero(iszero(slot)))
            len := sload(slot)
        }
    }

    /// @dev string array[index] = data
    /// @param slot _str[0] / _statusName[1] / _attributes[2]
    /// @param index index < array.length + 1
    /// @param data bytes / bytes.length < 32
    function _setStringArray(uint256 slot, uint256 index, bytes memory data) internal {
        slot = _checkSlot(slot);
        assembly {
            let len := sload(slot)

            // index < array.length + 1
            if lt(len, index) {
                mstore(0x00, 0xc758bb9e) // ArrayIsShort()
                revert(0x1c, 0x04)
            }

            // scracth space
            mstore(0x00, slot)
            slot := add(keccak256(0x00, 0x20), index)

            // data.length
            len := mload(data)

            // string.length < 32
            if lt(31, len) {
                mstore(0x00, 0x4ee45b56) // TooLong()
                revert(0x1c, 0x04)
            }

            // (value & length) set to slot
            sstore(slot, add(mload(add(data, 0x20)), mul(len, 2)))
        }
    }

    /// @dev string array[index] = data
    /// @param slot _str / _statusName / _attributes
    /// @param index index
    /// @return data string
    function getStringArray(uint256 slot, uint256 index) external view returns (string memory data) {
        slot = _checkSlot(slot);
        assembly {
            // free memory pointer
            data := mload(0x40)

            // scracth space
            mstore(0x00, slot)
            slot := add(keccak256(0x00, 0x20), index)

            let value := sload(slot)

            // value.length
            let len := div(and(value, sub(mul(0x100, iszero(and(value, 1))), 1)), 2)

            // memory counter
            let mc := add(data, 0x20)

            // set length
            mstore(data, len)

            // because length < 32
            mstore(mc, value)
            mstore(0x40, and(add(add(mc, len), 31), not(31)))
        }
    }
}