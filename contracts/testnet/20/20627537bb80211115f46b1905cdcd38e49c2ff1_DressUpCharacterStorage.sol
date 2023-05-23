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

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DressUpCharacterStorage is Ownable, StatusHandler, ImageDataHandler {
    using Strings for uint256;

    /* /////////////////////////////////////////////////////////////////////////////
    Setter
    ///////////////////////////////////////////////////////////////////////////// */

    function setImageDatas(bytes memory data, uint256 imageId, uint256 categoryId, uint256 transformId, uint256 styleId)
        external
        onlyOwner
    {
        _setImageDatas(data, imageId, categoryId, transformId, styleId);
    }

    function updateImageDatas(
        address pointer,
        uint256 imageId,
        uint256 categoryId,
        uint256 transformId,
        uint256 styleId
    ) external onlyOwner {
        _updateImageDatas(pointer, imageId, categoryId, transformId, styleId);
    }

    function setCharacterDatas(uint256[] memory imageIds, uint256 characterId, uint256 slot) external onlyOwner {
        _setCharacterDatas(imageIds, characterId, slot);
    }

    function setTransformDatas(uint256 index, bytes memory data) external onlyOwner {
        _setTransformDatas(index, data);
    }

    function setCharacterTransformDatas(uint256 characterId, uint256 characterTransformData) external onlyOwner {
        _setCharacterTransformDatas(characterId, characterTransformData);
    }

    function setStatus(uint256 tokenId, uint256 value) external onlyOwner {
        _setStatus(tokenId, value);
    }

    function setStyleDatas(uint256 index, bytes memory data) external onlyOwner {
        _setStyleDatas(index, data);
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Getter
    ///////////////////////////////////////////////////////////////////////////// */

    function createDataURI(uint256 tokenId, uint256 slot, uint256 iconCheck) public view returns (string memory) {
        string memory imageURI;

        if (iconCheck == 0) {
            imageURI = Base64.encode(bytes(_characterRender(tokenId, slot)));
        } else {
            imageURI = Base64.encode(bytes(_iconCharacterRender(tokenId, slot)));
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "{",
                        '"name":"',
                        "test-dress-uo-character",
                        tokenId.toString(),
                        '",',
                        '"description":"description",',
                        '"attributes":[',
                        createStatusTrait(status[tokenId]),
                        ',{"trait_type":"traitA","value":"valueA"}',
                        "],",
                        '"image": "data:image/svg+xml;base64,',
                        imageURI,
                        '"',
                        "}"
                    )
                )
            )
        );

        json = string(abi.encodePacked("data:application/json;base64,", json));
        return json;
    }

    // for specialCharacter
    function secondConcatCharacterRender(uint256 characterId, uint256 slot) public view returns (string memory data) {
        return _secondConcatCharacterRender(characterId, slot);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

abstract contract ImageDataHandler {
    using SSTORE2 for bytes;
    using SSTORE2 for address;
    using Strings for uint256;
    using Strings for string;

    uint256 private constant _MASK_UINT8 = (1 << 8) - 1;
    uint256 private constant _MASK_UINT16 = (1 << 16) - 1;

    // _IMAGE_DATAS / _CHARACTER_DATAS / _PARTS_DATAS / _TRANSFORM_DATAS
    uint256 private constant _DATAS_SEED = 0xfbbce30ee466491e05e534fb8e2a671f;
    uint256 private constant _STYLE_DATAS_SEED = 0xdfa6c9a2;

    // characterId => i => transformId
    // mapping(uint256 => mapping(uint256 => uint256)) characterTransformId;
    // mapping(uint256 => uint256) characterTransformDatas;
    uint256 private constant _CHARACTER_TRANSFORM_DATAS_SEED = 0x8e2a671f;

    string _prefixDataURI = "data:image/svg+xml;utf8,";
    string _prefix = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">';
    string _suffix = "</svg>";

    string _prefixStyle = '<style type="text/css">';
    string _suffixStyle = "</style>";

    string _prefixIcon =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" preserveAspectRatio="xMidYMid slice"><clipPath id="icon"><circle cx="500" cy="500" r="250" fill="#000"></circle></clipPath>';
    string _suffixGrope = "</symbol>";

    string[] public bgColorAssets = [
        "#E1C7EB",
        "#EBD7C7",
        "#C9C0ED",
        "#C0EDDA",
        "#E0EBC7",
        "#D3E8EB",
        "#EDC7C0",
        "#EDEACC",
        "#EAC0F0",
        "#F0D9C0",
        "#BEFABE",
        "#BED3FA",
        "#C0E3F0",
        "#DEF0CC",
        "#FACAE2",
        "#FAE7BE"
    ];

    string _useContentConcat =
        '<use href="#3" x="0" y="0"/><use href="#4" x="0" y="0"/><use href="#5" x="0" y="0"/><use href="#6" x="0" y="0"/><use href="#7" x="0" y="0"/><use href="#8" x="0" y="0"/>';

    /* /////////////////////////////////////////////////////////////////////////////
    Error
    ///////////////////////////////////////////////////////////////////////////// */

    error IncorrectValue();

    /* /////////////////////////////////////////////////////////////////////////////
    IMAGE_DATAS
    ///////////////////////////////////////////////////////////////////////////// */

    function _setImageDatas(
        bytes memory data,
        uint256 imageId,
        uint256 categoryId,
        uint256 transformId,
        uint256 styleId
    ) internal {
        address pointer = data.write();

        assembly {
            categoryId := and(categoryId, _MASK_UINT8)
            transformId := and(transformId, _MASK_UINT16)
            styleId := and(styleId, _MASK_UINT16)

            let imageData := or(or(or(shl(96, pointer), shl(88, categoryId)), shl(72, transformId)), shl(56, styleId))

            // write to storage
            mstore(0x16, _DATAS_SEED)
            mstore(0x00, imageId)
            sstore(keccak256(0x00, 0x24), imageData)
        }
    }

    function _updateImageDatas(
        address pointer,
        uint256 imageId,
        uint256 categoryId,
        uint256 transformId,
        uint256 styleId
    ) internal {
        assembly {
            categoryId := and(categoryId, _MASK_UINT8)
            transformId := and(transformId, _MASK_UINT16)
            styleId := and(styleId, _MASK_UINT16)

            let imageData := or(or(or(shl(96, pointer), shl(88, categoryId)), shl(72, transformId)), shl(56, styleId))

            // write to storage
            mstore(0x16, _DATAS_SEED)
            mstore(0x00, imageId)
            sstore(keccak256(0x00, 0x24), imageData)
        }
    }

    function getImageDatas(uint256 imageId)
        public
        view
        returns (address pointer, uint256 categoryId, uint256 transformId, uint256 styleId)
    {
        assembly {
            // read to storage
            mstore(0x16, _DATAS_SEED)
            mstore(0x00, imageId)
            let value := sload(keccak256(0x00, 0x24))

            pointer := shr(96, value)
            categoryId := and(_MASK_UINT8, shr(88, value))
            transformId := and(_MASK_UINT16, shr(72, value))
            styleId := and(_MASK_UINT16, shr(56, value))
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    CHARACTER_DATAS [slot = 3] / PARTS_DATAS [slot = 2]
    ///////////////////////////////////////////////////////////////////////////// */

    // setしていいパーツか確認してない
    function _setCharacterDatas(uint256[] memory imageIds, uint256 characterId, uint256 slot) internal {
        assembly {
            let packed := mload(imageIds)

            // 15 < imageIds.length --> not allow
            if lt(15, packed) {
                mstore(0x00, 0xd2ade556) // `IncorrectValue()`.
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
            mstore(mul(0x04, slot), _DATAS_SEED)
            mstore(0x00, characterId)
            sstore(keccak256(0x00, 0x24), packed)
        }
    }

    function getCharacterDatas(uint256 characterId, uint256 index, uint256 slot)
        public
        view
        returns (uint256 imageId)
    {
        assembly {
            // read to storage
            mstore(mul(0x04, slot), _DATAS_SEED)
            mstore(0x00, characterId)
            let value := sload(keccak256(0x00, 0x24))

            imageId := and(_MASK_UINT16, shr(mul(index, 16), value))
        }
    }

    function getAllCharacterDatas(uint256 characterId, uint256 slot) public view returns (uint256 characterData) {
        assembly {
            // read to storage
            mstore(mul(0x04, slot), _DATAS_SEED)
            mstore(0x00, characterId)
            characterData := sload(keccak256(0x00, 0x24))
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    CHARACTER_Render
    ///////////////////////////////////////////////////////////////////////////// */

    // function _characterRender(uint256 characterId, uint256 slot) internal view returns (string memory) {
    //     string memory symbol = _createBg(characterId);
    //     string memory useContent = '<use href="#0" x="0" y="0"/>';
    //     string memory style = _prefixStyle;
    //     // '<style type="text/css">#cceye1{fill:#E87C0C;} #cceye2{fill:#F2600C;} #cceye3{fill:#DC3100;} #cceye4{fill:#F21C0C;}</style>';

    //     uint256 len = getCharacterDatas(characterId, 0, slot);
    //     for (uint256 i = 1; i < len + 1;) {
    //         unchecked {
    //             uint256 imageId = getCharacterDatas(characterId, i, slot);

    //             (address pointer_, uint256 categoryId_, uint256 transformId_, uint256 styleId_) = getImageDatas(imageId);

    //             symbol = string(
    //                 abi.encodePacked(symbol, _createPrefixGrope(categoryId_), string(pointer_.read()), _suffixGrope)
    //             );

    //             style = string(abi.encodePacked(style, _createStyle(styleId_)));

    //             useContent = string(abi.encodePacked(useContent, _createUseContent(categoryId_, transformId_)));

    //             i++;
    //         }
    //     }

    //     string memory packedSVG = string.concat(_prefix, symbol, style, _suffixStyle, useContent, _suffix);
    //     return packedSVG;
    // }

    /* /////////////////////////////////////////////////////////////////////////////
    Icon_CHARACTER_Render
    ///////////////////////////////////////////////////////////////////////////// */

    function _iconCharacterRender(uint256 characterId, uint256 slot) internal view returns (string memory) {
        string memory symbol = _createBg(characterId);
        string memory useContent = '<use href="#0" x="0" y="0" clip-path="url(#icon)" />';

        uint256 len = getCharacterDatas(characterId, 0, slot);
        for (uint256 i = 1; i < len + 1;) {
            unchecked {
                uint256 imageId = getCharacterDatas(characterId, i, slot);

                (address pointer_, uint256 categoryId_, uint256 transformId_,) = getImageDatas(imageId);

                symbol = string.concat(symbol, _createPrefixGrope(categoryId_), string(pointer_.read()), _suffixGrope);

                useContent = string(abi.encodePacked(useContent, _createUseContentForIcon(categoryId_, transformId_)));
                i++;
            }
        }

        string memory packedSVG = string.concat(_prefixIcon, symbol, useContent, _suffix);
        return packedSVG;
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Concat_CHARACTER_Render
    ///////////////////////////////////////////////////////////////////////////// */

    function _firstConcatCharacterRender(uint256 characterId, uint256 slot) internal view returns (string memory) {
        string memory symbol = _createBg(characterId);

        uint256 len = getCharacterDatas(characterId, 0, slot);
        for (uint256 i = 1; i < len + 1;) {
            unchecked {
                uint256 imageId = getCharacterDatas(characterId, i, slot);

                (address pointer_, uint256 categoryId_,,) = getImageDatas(imageId);

                symbol = string.concat(symbol, _createPrefixGrope(categoryId_), string(pointer_.read()), _suffixGrope);

                i++;
            }
        }

        string memory packedSVG = string.concat(_prefix, symbol);
        return packedSVG;
    }

    // for special character
    function _secondConcatCharacterRender(uint256 characterId, uint256 slot) internal view returns (string memory) {
        string memory symbol;
        string memory useContent =
            '<use href="#0" x="0" y="0"/><use href="#1" x="0" y="0"/><use href="#2" x="0" y="0"/>';

        uint256 len = getCharacterDatas(characterId, 0, slot);
        for (uint256 i = 1; i < len + 1;) {
            unchecked {
                uint256 imageId = getCharacterDatas(characterId, i, slot);

                (address pointer_, uint256 categoryId_, uint256 transformId_,) = getImageDatas(imageId);

                symbol = string.concat(symbol, _createPrefixGrope(categoryId_), string(pointer_.read()), _suffixGrope);

                useContent = string(abi.encodePacked(useContent, _createUseContent(categoryId_, transformId_)));

                i++;
            }
        }

        string memory packedSVG = string.concat(symbol, useContent, _createUseContentCharacter(characterId), _suffix);
        return packedSVG;
    }

    /* /////////////////////////////////////////////////////////////////////////////
    characterTransformDatas
    ///////////////////////////////////////////////////////////////////////////// */

    function _setCharacterTransformDatas(uint256 characterId, uint256 characterTransformData) internal {
        assembly {
            // write to storage
            mstore(0x04, _CHARACTER_TRANSFORM_DATAS_SEED)
            mstore(0x00, characterId)

            sstore(keccak256(0x00, 0x24), characterTransformData)
        }
    }

    function _getCharacterTransformDatas(uint256 characterId, uint256 index)
        internal
        view
        returns (uint256 transformId)
    {
        assembly {
            // read to storage
            mstore(0x04, _CHARACTER_TRANSFORM_DATAS_SEED)
            mstore(0x00, characterId)

            let value := sload(keccak256(0x00, 0x24))
            transformId := and(_MASK_UINT16, shr(mul(index, 16), value))
        }
    }

    function _createUseContentCharacter(uint256 characterId) internal view returns (string memory) {
        string memory useContent;
        for (uint256 i = 3; i < 9;) {
            unchecked {
                useContent = string(
                    abi.encodePacked(useContent, _createUseContent(i, _getCharacterTransformDatas(characterId, i - 3)))
                );
                i++;
            }
        }
        return useContent;
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Render_helper
    ///////////////////////////////////////////////////////////////////////////// */

    function _createPrefixGrope(uint256 categoryId) internal pure returns (string memory) {
        return string.concat('<symbol id="', categoryId.toString(), '">');
    }

    function _createUseContent(uint256 categoryId, uint256 transformId) internal view returns (string memory) {
        return string.concat(
            '<use href="#', categoryId.toString(), '" x="0" y="0" transform="', _getTransformDatas(transformId), '" />'
        );
    }

    function _createUseContentForIcon(uint256 categoryId, uint256 transformId) internal view returns (string memory) {
        return string.concat(
            '<use href="#',
            categoryId.toString(),
            '" x="0" y="0" transform="',
            _getTransformDatas(transformId),
            '" clip-path="url(#icon)" />'
        );
    }

    function _createBg(uint256 characterId) internal view returns (string memory) {
        return string.concat(
            '<symbol id="0"><rect width="1000" height="1000" fill="',
            bgColorAssets[characterId % bgColorAssets.length],
            '"/></symbol>'
        );
    }

    function _createStyle(uint256 styleId) internal view returns (string memory) {
        return _getStyleDatas(styleId);
    }

    /* /////////////////////////////////////////////////////////////////////////////
    transformDatas
    ///////////////////////////////////////////////////////////////////////////// */

    function _setTransformDatas(uint256 index, bytes memory data) internal {
        assembly {
            mstore(0x04, _DATAS_SEED)
            mstore(0x00, index)
            let slot := keccak256(0x00, 0x24)

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

    function _getTransformDatas(uint256 index) internal view returns (string memory data) {
        assembly {
            // free memory pointer
            data := mload(0x40)

            mstore(0x04, _DATAS_SEED)
            mstore(0x00, index)
            let slot := keccak256(0x00, 0x24)

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
    transformDatasと一緒 _DATAS_SEED => _STYLE_DATAS_SEED
    ///////////////////////////////////////////////////////////////////////////// */

    function _setStyleDatas(uint256 index, bytes memory data) internal {
        assembly {
            // 下記のみ変更
            // mstore(0x04, _DATAS_SEED)

            mstore(0x04, _STYLE_DATAS_SEED)
            mstore(0x00, index)
            let slot := keccak256(0x00, 0x24)

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

    function _getStyleDatas(uint256 index) internal view returns (string memory data) {
        assembly {
            // free memory pointer
            data := mload(0x40)

            // 下記のみ変更
            // mstore(0x04, _DATAS_SEED)

            mstore(0x04, _STYLE_DATAS_SEED)
            mstore(0x00, index)
            let slot := keccak256(0x00, 0x24)

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
    Create dataURI
    ///////////////////////////////////////////////////////////////////////////// */

    function _characterRender(uint256 characterId, uint256 slot) internal view returns (string memory data) {
        // // memory counter
        // let mc := add(result, 0x20)

        assembly {
            // ImageDatas pointer
            let ptr := mload(0x40)

            // getCharacterDatas(uint256 characterId, uint256 index, uint256 slot) --> (uint256 imageId)
            // len
            mstore(mul(0x04, slot), _DATAS_SEED)
            mstore(0x00, characterId)
            let value := sload(keccak256(0x00, 0x24))

            let n := add(and(_MASK_UINT16, value), 1)
            let temp
            let mc := add(ptr, 0x20)

            for { let i := 1 } lt(i, n) {
                mc := add(mc, 0x20)
                i := add(i, 1)
            } {
                // imageId
                temp := and(_MASK_UINT16, shr(mul(i, 16), value))

                mstore(0x16, _DATAS_SEED)
                mstore(0x00, temp)
                temp := sload(keccak256(0x00, 0x24))

                mstore(mc, temp)
            }
            // free memory pointer
            mstore(0x40, add(mc, 0x20))

            // return data
            data := mload(0x40)
            let len := 0x20

            // _prefix
            mstore(add(data, len), '<hpc xmlns="http://www.w3.org/20')
            len := add(len, 32)

            mstore(add(data, len), '00/hpc" viewBox="0 0 1000 1000">')
            len := add(len, 32)

            // symbol
            for {
                let i := 0
                let cc
            } lt(i, n) {
                i := add(i, 1)
                cc := add(cc, 0x20)
            } {
                // i := add(i, 1)
                // symbol = _createBg(characterId);
                // '<symbol id="0"><rect width="1000" height="1000" fill="',
                mstore(add(data, len), '<symbol id="')
                len := add(len, 12)

                // scratch space toString
                temp := i
                let ss := 0x20
                for {} 1 {} {
                    ss := sub(ss, 1)

                    mstore8(ss, add(48, mod(temp, 10)))
                    temp := div(temp, 10)
                    if iszero(temp) { break }
                }
                mstore(add(data, len), mload(ss))
                len := add(len, sub(0x20, ss))
                // toString end

                mstore(add(data, len), '">')
                len := add(len, 2)

                switch i
                case 0 {
                    mstore(add(data, len), '<rect width="1000" height="1000"')
                    len := add(len, 32)

                    mstore(add(data, len), ' fill="')
                    len := add(len, 7)

                    // bgColorAssets[characterId % bgColorAssets.length],
                    // mstore(0x20, bgColorAssets.slot)
                    // mstore(0x00, 1)
                    // let slot2 := sload(keccak256(0x00, 0x40))
                    // temp := sload(slot2)
                    // temp := sload(add(add(slot2, mod(characterId, 16)), 0x40))
                    temp := "#E1C7EB"
                    mstore(add(data, len), temp)
                    len := add(len, 7)

                    // '"/></symbol>'
                    mstore(add(data, len), '"/>')
                    len := add(len, 3)
                }
                default {
                    // pointer_.read()
                    value := mload(add(ptr, cc))
                    // pointer
                    temp := shr(96, value)
                    let pointerCodesize := extcodesize(temp)
                    if iszero(pointerCodesize) {
                        // // Store the function selector of `InvalidPointer()`.
                        // mstore(0x00, 0x11052bb4)
                        // // Revert with (offset, size).
                        // revert(0x1c, 0x04)

                        pointerCodesize := 1
                    }
                    // Offset all indices by 1 to skip the STOP opcode.
                    let size := sub(pointerCodesize, 1)

                    extcodecopy(temp, add(data, len), 1, size)
                    len := add(len, size)
                }

                // '</symbol>'
                mstore(add(data, len), "</symbol>")
                len := add(len, 9)
            }

            // style = string(abi.encodePacked(style, _createStyle(styleId_)));

            // style
            mstore(add(data, len), '<style type="text/css">')
            len := add(len, 23)

            for {
                let i := 1
                let cc
            } lt(i, n) {
                i := add(i, 1)
                cc := add(cc, 0x20)
            } {
                // _createStyle(styleId_)
                value := mload(add(ptr, cc))
                // styleId
                temp := and(_MASK_UINT16, shr(56, value))

                // _getStyleDatas
                mstore(0x04, _STYLE_DATAS_SEED)
                mstore(0x00, temp)
                temp := keccak256(0x00, 0x24)
                value := sload(temp)

                let len2 := div(and(value, sub(mul(0x100, iszero(and(value, 1))), 1)), 2)

                // set value
                switch lt(len2, 32)
                // length < 32
                case 1 { mstore(add(data, len), value) }
                // length >= 32
                default {
                    // key
                    mstore(0x00, temp)
                    let sc := keccak256(0x00, 0x20)

                    for { let end := add(data, len2) } lt(data, end) {
                        sc := add(sc, 1)
                        mc := add(data, 0x20)
                    } { mstore(add(data, len), sload(sc)) }
                }

                len := add(len, len2)
                // _getStyleDatas end
            }

            mstore(add(data, len), "</style>")
            len := add(len, 8)

            // useContent = string(abi.encodePacked(useContent, _createUseContent(categoryId_, transformId_)));

            // useContent
            for {
                let i := 0
                let cc
            } lt(i, n) {
                i := add(i, 1)
                cc := add(cc, 0x20)
            } {
                mstore(add(data, len), '<use href="#')
                len := add(len, 12)

                // scratch space toString
                temp := i
                let ss := 0x20
                for {} 1 {} {
                    ss := sub(ss, 1)

                    mstore8(ss, add(48, mod(temp, 10)))
                    temp := div(temp, 10)
                    if iszero(temp) { break }
                }
                mstore(add(data, len), mload(ss))
                len := add(len, sub(0x20, ss))
                // toString end

                switch i
                case 0 {
                    mstore(add(data, len), '" x="0" y="0"/>')
                    len := add(len, 15)
                }
                default {
                    mstore(add(data, len), '" x="0" y="0" transform="')
                    len := add(len, 25)

                    // _getTransformDatas(transformId)
                    // transformId := and(_MASK_UINT16, shr(72, value))
                    value := mload(add(ptr, cc))
                    // transformId
                    temp := and(_MASK_UINT16, shr(72, value))

                    mstore(0x04, _DATAS_SEED)
                    mstore(0x00, temp)
                    temp := keccak256(0x00, 0x24)
                    value := sload(temp)

                    let len2 := div(and(value, sub(mul(0x100, iszero(and(value, 1))), 1)), 2)

                    // set value
                    switch lt(len2, 32)
                    // length < 32
                    case 1 { mstore(add(data, len), value) }
                    // length >= 32
                    default {
                        // key
                        mstore(0x00, temp)
                        let sc := keccak256(0x00, 0x20)

                        for { let end := add(data, len2) } lt(data, end) {
                            sc := add(sc, 1)
                            mc := add(data, 0x20)
                        } { mstore(add(data, len), sload(sc)) }
                    }

                    len := add(len, len2)

                    mstore(add(data, len), '" />')
                    len := add(len, 4)
                }
            }

            mstore(add(data, len), "</hpc>")
            len := add(len, 6)

            // write memory space
            mstore(data, len)
            mstore(0x40, and(add(add(data, len), 31), not(31)))
        }

        // getImageDatas(uint256 imageId) --> (address pointer, uint256 categoryId, uint256 transformId, uint256 styleId)
        // pointer := shr(96, value)
        // categoryId := and(_MASK_UINT8, shr(88, value))
        // transformId := and(_MASK_UINT16, shr(72, value))
        // styleId := and(_MASK_UINT16, shr(56, value))
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract StatusHandler {
    using Strings for uint256;

    string[] str = ['{"trait_type":', ',"value":', "},", ',"display_type":"number"', ',"max_value":"255"},'];

    string[] statusName = [
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

    string[] attributes = ["Fire", "Water", "Electric", "Ground", "Wind", "Ice", "Dark", "Light"];

    uint256 private constant _MASK_UINT8 = (1 << 8) - 1;

    /* /////////////////////////////////////////////////////////////////////////////
    Error
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev String < 32 0x4ee45b56
    error TooLong();

    /// @dev need to expand array.length 0xc758bb9e
    error ArrayIsShort();

    /* /////////////////////////////////////////////////////////////////////////////
    Error
    ///////////////////////////////////////////////////////////////////////////// */

    mapping(uint256 => uint256) public status;

    // ステータスはキャラクター依存？トークン依存？
    function _setStatus(uint256 tokenId, uint256 value) internal {
        status[tokenId] = value;
    }

    function createStatusTrait(uint256 value) public view returns (string memory result) {
        assembly {
            // tager slot value -> set memory & return len
            function setMemorySlot(slot, sc, mc, len) -> rlen {
                slot := sload(add(slot, sc))
                mstore(add(mc, len), slot)
                rlen := add(len, div(and(slot, _MASK_UINT8), 2))
            }

            // str
            mstore(0x00, str.slot)
            let strSlot := keccak256(0x00, 0x20)

            // statusName
            mstore(0x00, statusName.slot)
            let statusNameSlot := keccak256(0x00, 0x20)

            // attributes
            mstore(0x00, attributes.slot)
            let attributesSlot := keccak256(0x00, 0x20)
            let attributesLen := sload(attributes.slot)

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
                let statusLen := sub(sload(statusName.slot), 2)
            } lt(cc, add(statusLen, 2)) {
                cc := add(cc, 0x01)
                ss := 0x20
            } {
                // str1
                // len := setMemorySlot(strSlot, 0, mc, len)
                mstore(add(mc, len), '{"trait_type":')
                len := add(len, 14)

                // trait
                len := setMemorySlot(statusNameSlot, cc, mc, len)

                // str2
                // len := setMemorySlot(strSlot, 1, mc, len)
                mstore(add(mc, len), ',"value":')
                len := add(len, 9)

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

                    // opt
                    // len := setMemorySlot(strSlot, 3, mc, len)
                    mstore(add(mc, len), ',"display_type":"number"')
                    len := add(len, 24)

                    // len := setMemorySlot(strSlot, 4, mc, len)
                    mstore(add(mc, len), ',"max_value":"255"},')
                    len := add(len, 20)
                }

                // attributes:value
                if lt(statusLen, add(cc, 0x01)) {
                    mstore(add(mc, len), '"')
                    len := add(len, 0x01)

                    for {
                        let i := 0
                        let j := mul(sub(cc, statusLen), 16)
                    } lt(i, attributesLen) { i := add(i, 1) } {
                        if eq(1, and(1, shr(sub(sub(255, j), i), value))) {
                            len := setMemorySlot(attributesSlot, i, mc, len)

                            mstore(add(mc, len), ",")
                            len := add(len, 0x01)
                        }
                    }

                    len := sub(len, 0x01)

                    mstore(add(mc, len), '"')
                    len := add(len, 0x01)

                    // str3
                    // len := setMemorySlot(strSlot, 2, mc, len)
                    mstore(add(mc, len), "},")
                    len := add(len, 2)
                }
            }

            let last := add(mc, len)

            // write memory space
            mstore(result, sub(len, 0x01))
            mstore(0x40, and(add(last, 31), not(31)))
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    StringDatas
    ///////////////////////////////////////////////////////////////////////////// */

    function getSlot() external pure returns (uint256 statusNameSlot, uint256 attributesSlot) {
        assembly {
            statusNameSlot := statusName.slot
            attributesSlot := attributes.slot
        }
    }

    function _setStringDataLength(uint256 slot, uint256 len) internal {
        assembly {
            sstore(slot, len)
        }
    }

    function getStringDataLength(uint256 slot) external view returns (uint256 len) {
        assembly {
            len := sload(slot)
        }
    }

    function _setStringData(uint256 _slot, uint256 index, bytes memory data) internal {
        assembly {
            let len := sload(_slot)

            // index < StringDatas.length + 1
            if lt(len, index) {
                mstore(0x00, 0xc758bb9e) // ArrayIsShort()
                revert(0x1c, 0x04)
            }

            mstore(0x00, _slot)
            let slot := add(keccak256(0x00, 0x20), index)

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

    function getStringData(uint256 _slot, uint256 index) external view returns (string memory data) {
        assembly {
            // free memory pointer
            data := mload(0x40)

            mstore(0x00, _slot)
            let slot := add(keccak256(0x00, 0x20), index)

            let value := sload(slot)
            let len := div(and(value, sub(mul(0x100, iszero(and(value, 1))), 1)), 2)
            let mc := add(data, 0x20)

            // set length
            mstore(data, len)

            // because length < 32
            mstore(mc, value)
            mstore(0x40, and(add(add(mc, len), 31), not(31)))
        }
    }
}