// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Base64.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
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

// File: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Base64.sol";

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin/contracts/utils/math/Math.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
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
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)
interface IGNOME {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getGnomeIds(address _gnome) external view returns (uint32[] memory);
    function fatalizeGnomeAuth(uint32 tokenId) external;
}

contract GnomePlayerV2 {
    string public baseTokenURI;

    using Strings for uint256;
    bool public applyTxLimit;
    bool public burnGnome = false;

    // Number of days for HP to decrease to 0
    uint256 public daysToDie = 7 days;

    mapping(address => bool) public isAuth;
    mapping(address => mapping(uint256 => bool)) public isDed;
    mapping(address => mapping(uint256 => bool)) public isSignedUp;
    mapping(address => bool) public gnomeFractionalSignUp;
    uint256 public totalFractalGnomes;
    uint256[] public signedUpIDs;
    uint256 public constant SECONDS_PER_DAY = 86400; // 24 * 60 * 60
    uint256 public boopCoolDown = 15 minutes;
    uint256 public sleepCoolDown = 3 days;
    mapping(uint256 => address) public oldTokenIdOwner;
    mapping(uint256 => address) public ownerOfGnome;
    mapping(uint256 => string) public gnomeMetadata;
    mapping(address => uint256[]) public gnomeAddressIds;
    mapping(address => mapping(uint256 => string)) public gnomeX_usr;
    mapping(address => mapping(uint256 => uint256)) public xp; //Experience Points
    mapping(address => mapping(uint256 => uint256)) public hp; //Health Points

    mapping(address => mapping(uint256 => uint256)) public lastBoopTimeStamp;
    mapping(address => mapping(uint256 => uint256)) public lastHPUpdateTime;

    mapping(address => mapping(uint256 => mapping(string => uint256))) public activityAmount;
    mapping(address => mapping(uint256 => uint256)) public boopAmount;
    mapping(address => mapping(uint256 => uint256)) public ethAmount;
    mapping(address => mapping(uint256 => uint256)) public gnomeAmount;
    mapping(address => mapping(uint256 => uint256)) public meditateTimeStamp;
    mapping(address => mapping(uint256 => uint256)) public sleepingTimeStamp;
    mapping(address => mapping(uint256 => uint256)) public shieldTimeStamp;

    mapping(address => mapping(uint256 => uint256)) public gnomeEmotion;
    mapping(address => mapping(uint256 => uint256)) public amountSpentETH;
    mapping(address => mapping(uint256 => uint256)) public amountSpentGNOME;
    mapping(address => uint256) public crystalShardsAmount;
    mapping(address => mapping(uint256 => bool)) public isSleeping;

    address public GNOME_NFT_ADDRESS;

    constructor(address _gnomeNFT) {
        isAuth[msg.sender] = true; //set minted at ONE to ensure correct operation within range of IDs
        GNOME_NFT_ADDRESS = _gnomeNFT;
    }

    modifier onlyAuth() {
        require(isAuth[msg.sender], "Caller is not the authorized");
        _;
    }

    function isGnomeSignedUp(uint256 tokenId) external view returns (bool) {
        address gnomeAddress = ownerOfGnome[tokenId];
        return isSignedUp[gnomeAddress][tokenId];
    }

    function isGnomeAddressSignedUp(address gnome) external view returns (bool) {
        uint256[] memory tokenIds = gnomeAddressIds[gnome];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isSignedUp[gnome][tokenIds[i]]) {
                return true; // Return true if any token ID is signed up
            }
        }
        return false; // Return false if no token IDs are signed up
    }

    function getTokenUserName(uint256 tokenId) external view returns (string memory) {
        address gnomeAddress = ownerOfGnome[tokenId];
        return gnomeX_usr[gnomeAddress][tokenId];
    }

    function deleteGameStats(uint256 tokenId) public onlyAuth {
        address currentOwner = ownerOfGnome[tokenId];

        delete xp[currentOwner][tokenId];
        delete hp[currentOwner][tokenId];
        delete meditateTimeStamp[currentOwner][tokenId];
        delete gnomeX_usr[currentOwner][tokenId];
        delete lastBoopTimeStamp[currentOwner][tokenId];

        delete amountSpentETH[currentOwner][tokenId];
        delete amountSpentGNOME[currentOwner][tokenId];

        delete isSignedUp[currentOwner][tokenId];
        delete sleepingTimeStamp[currentOwner][tokenId];
        delete isSleeping[currentOwner][tokenId];

        // Find and remove the tokenId from gnomeAddressIds
        uint256 length = gnomeAddressIds[currentOwner].length;
        for (uint i = 0; i < length; i++) {
            if (gnomeAddressIds[currentOwner][i] == tokenId) {
                gnomeAddressIds[currentOwner][i] = gnomeAddressIds[currentOwner][length - 1];
                gnomeAddressIds[currentOwner].pop();
                break;
            }
        }

        for (uint256 i = 0; i < signedUpIDs.length; i++) {
            if (signedUpIDs[i] == tokenId) {
                // Move the last element to the current index
                signedUpIDs[i] = signedUpIDs[signedUpIDs.length - 1];
                // Remove the last element
                signedUpIDs.pop();
                break; // Exit the loop once found and removed
            }
        }
        if (tokenId < 100000000) {
            gnomeFractionalSignUp[currentOwner] = true;
        }
        oldTokenIdOwner[tokenId] = ownerOfGnome[tokenId];
        delete ownerOfGnome[tokenId];
    }

    function setGnomeX(uint256 tokenId, string memory gnomeX) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        gnomeX_usr[gnomeAddress][tokenId] = gnomeX;
    }

    function setGnomeMetadata(uint256 index, string memory uri) external onlyAuth {
        gnomeMetadata[index] = uri;
    }

    function signUpFactory(uint256 tokenId, string memory _Xusr, uint256 _gnomeEmotion) public {
        address gnomeAddress = ownerOfGnome[tokenId];
        if (!isAuth[msg.sender]) {
            if (tokenId >= 100000000) {
                require(IGNOME(GNOME_NFT_ADDRESS).ownerOf(tokenId) == tx.origin, "Not Auth");
            } else {
                if (gnomeAddress != address(0)) {
                    require(gnomeAddress == tx.origin, "Not Auth");
                    require(!gnomeFractionalSignUp[tx.origin], "You Already Signed Up");
                }
            }
        }

        if (isSignedUp[gnomeAddress][tokenId]) {
            deleteGameStats(tokenId);
        }
        isSignedUp[tx.origin][tokenId] = true;

        bool exists = false;
        for (uint i = 0; i < gnomeAddressIds[tx.origin].length; i++) {
            if (gnomeAddressIds[tx.origin][i] == tokenId) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            gnomeAddressIds[tx.origin].push(tokenId);
        }
        ownerOfGnome[tokenId] = tx.origin;
        gnomeX_usr[tx.origin][tokenId] = _Xusr;
        xp[tx.origin][tokenId] = 10;
        hp[tx.origin][tokenId] = 100;
        lastHPUpdateTime[tx.origin][tokenId] = block.timestamp;
        gnomeEmotion[tx.origin][tokenId] = _gnomeEmotion;
        signedUpIDs.push(tokenId);

        if (tokenId < 100000000) {
            gnomeFractionalSignUp[tx.origin] = true;
            totalFractalGnomes++;
        }
    }

    function deleteDumpedGnomes(uint256 tokenId) public {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        require(
            IGNOME(GNOME_NFT_ADDRESS).ownerOf(tokenId) != address(0),
            "Invalid tokenId: owner cannot be the zero address"
        );
        require(
            IGNOME(GNOME_NFT_ADDRESS).ownerOf(tokenId) != gnomeAddress,
            "Current owner cannot be the same as SignedUp owner"
        );
        deleteGameStats(tokenId);
        crystalShardsAmount[tx.origin] += 1;
    }

    function setBoopTimeStamp(uint256 tokenId, uint256 _lastBoopTimeStamp) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");

        lastBoopTimeStamp[gnomeAddress][tokenId] = _lastBoopTimeStamp;
    }

    function wakeUpGnome(uint256 tokenId) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        isSleeping[gnomeAddress][tokenId] = false;
    }

    function setShieldTimeStamp(uint256 tokenId, uint256 _shieldTimeStamp) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        shieldTimeStamp[gnomeAddress][tokenId] = _shieldTimeStamp;
    }

    function setMeditateTimeStamp(uint256 tokenId, uint256 _meditateTimeStamp) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        meditateTimeStamp[gnomeAddress][tokenId] = _meditateTimeStamp;
    }

    mapping(uint256 => uint256) public gnomeShieldTimeStamp;

    function setGnomeActivityAmount(
        string memory activity,
        uint256 tokenId,
        uint256 _activityAmount
    ) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        activityAmount[gnomeAddress][tokenId][activity] = _activityAmount;
    }

    function increaseGnomeActivityAmount(
        string memory activity,
        uint256 tokenId,
        uint256 _activityAmount
    ) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        activityAmount[gnomeAddress][tokenId][activity] += _activityAmount;
    }

    function setGnomeBoopAmount(uint256 tokenId, uint256 _boopAmount) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        boopAmount[gnomeAddress][tokenId] = _boopAmount;
    }

    function increaseGnomeBoopAmount(uint256 tokenId, uint256 _gnomeAmount) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        gnomeAmount[gnomeAddress][tokenId] += _gnomeAmount;
    }

    function setGnomeSpentAmount(uint256 tokenId, uint256 _gnomeAmount) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        gnomeAmount[gnomeAddress][tokenId] = _gnomeAmount;
    }

    function increaseETHSpentAmount(uint256 tokenId, uint256 _ethAmount) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        ethAmount[gnomeAddress][tokenId] += _ethAmount;
    }

    function setETHSpentAmount(uint256 tokenId, uint256 _ethAmount) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        ethAmount[gnomeAddress][tokenId] = _ethAmount;
    }

    function increaseGnomeSpentAmount(uint256 tokenId, uint256 _gnomeAmount) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        gnomeAmount[gnomeAddress][tokenId] += _gnomeAmount;
    }

    function setGnomeHPUpdate(uint256 tokenId, uint256 _lastHPUpdateTime) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        lastHPUpdateTime[gnomeAddress][tokenId] = _lastHPUpdateTime;
    }

    function setIsAuth(address gnome, bool isAuthorized) external onlyAuth {
        isAuth[gnome] = isAuthorized;
    }

    function setBurnGnome(bool _burnActive) public onlyAuth {
        burnGnome = _burnActive;
    }

    function setFractalGnomes(uint256 _totalFractalGnomes) public onlyAuth {
        totalFractalGnomes = _totalFractalGnomes;
    }

    function increaseFractalGnomes() public onlyAuth {
        totalFractalGnomes++;
    }

    function setBoopCoolDown(uint256 _boopCoolDown) public onlyAuth {
        boopCoolDown = _boopCoolDown;
    }

    function getFractalGnomes() public view returns (uint256) {
        return totalFractalGnomes;
    }

    function setSleepCoolDown(uint256 _sleepCoolDown) public onlyAuth {
        sleepCoolDown = _sleepCoolDown;
    }

    function setGnomeXP(uint256 tokenId, uint256 _xp) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        xp[gnomeAddress][tokenId] = _xp;
    }

    function setGnomeHP(uint256 tokenId, uint256 _hp) external onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        hp[gnomeAddress][tokenId] = _hp;
    }

    function increaseXP(uint256 tokenId, uint256 _XP) public onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        xp[gnomeAddress][tokenId] += _XP;
    }

    function decreaseXP(uint256 tokenId, uint256 _XP) public onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        xp[gnomeAddress][tokenId] = (_XP > xp[gnomeAddress][tokenId]) ? 0 : xp[gnomeAddress][tokenId] - _XP;
    }

    function increaseHP(uint256 tokenId, uint256 _HP) public onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        hp[gnomeAddress][tokenId] = currentHP(tokenId) + _HP;
        lastHPUpdateTime[gnomeAddress][tokenId] = block.timestamp;
    }

    function decreaseHP(uint256 tokenId, uint256 _HP) public onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        if (_HP > currentHP(tokenId)) {
            hp[gnomeAddress][tokenId] = 0;
            if (!isSleeping[gnomeAddress][tokenId]) {
                isSleeping[gnomeAddress][tokenId] = true;
                sleepingTimeStamp[gnomeAddress][tokenId] = block.timestamp;
            }
            if (burnGnome && (block.timestamp > sleepingTimeStamp[gnomeAddress][tokenId] + sleepCoolDown)) {
                if (tokenId >= 100000000) {
                    IGNOME(GNOME_NFT_ADDRESS).fatalizeGnomeAuth(uint32(tokenId));
                    crystalShardsAmount[tx.origin] += 1;
                }
                deleteGameStats(tokenId);
            }
        } else {
            hp[gnomeAddress][tokenId] = currentHP(tokenId) - _HP;
        }
    }

    function setDaysToDie(uint256 _days) external onlyAuth {
        daysToDie = _days;
    }

    function setCrystalShards(address gnome, uint256 _shards) external onlyAuth {
        crystalShardsAmount[gnome] = _shards;
    }

    function increaseCrystalShards(address gnome, uint256 _shards) external onlyAuth {
        crystalShardsAmount[gnome] += _shards;
    }

    function currentHP(uint256 tokenId) public view returns (uint256) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        // Get the last time HP was updated for the gnome
        uint256 lastUpdateTime = lastHPUpdateTime[gnomeAddress][tokenId];

        // Calculate the elapsed time since the last HP update
        uint256 elapsedTime = (block.timestamp - lastUpdateTime);

        // Calculate the expected HP decrease based on the elapsed time and decrease rate
        uint256 decreaseAmount = elapsedTime > daysToDie
            ? hp[gnomeAddress][tokenId]
            : (hp[gnomeAddress][tokenId] * elapsedTime) / daysToDie;

        // Calculate the expected HP
        uint256 expectedHP = hp[gnomeAddress][tokenId] > decreaseAmount
            ? hp[gnomeAddress][tokenId] - decreaseAmount
            : 0;

        return expectedHP;
    }

    function setGnomeEmotion(uint256 tokenId, uint256 _gnomeEmotion) public onlyAuth {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        gnomeEmotion[gnomeAddress][tokenId] = _gnomeEmotion;
    }

    function getBoopTimeStamp(uint256 tokenId) public view returns (uint256) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        return lastBoopTimeStamp[gnomeAddress][tokenId];
    }

    function getShieldTimeStamp(uint256 tokenId) public view returns (uint256) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        return shieldTimeStamp[gnomeAddress][tokenId];
    }

    function getMeditateTimeStamp(uint256 tokenId) public view returns (uint256) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        return meditateTimeStamp[gnomeAddress][tokenId];
    }

    function getSleepingTimeStamp(uint256 tokenId) public view returns (uint256) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        return sleepingTimeStamp[gnomeAddress][tokenId];
    }

    function getXP(uint256 tokenId) public view returns (uint256) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        return xp[gnomeAddress][tokenId];
    }

    function getHP(uint256 tokenId) public view returns (uint256) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        return hp[gnomeAddress][tokenId];
    }

    function getID(address gnome) public view returns (uint256[] memory) {
        return gnomeAddressIds[gnome];
    }

    function getIsSleeping(uint256 tokenId) public view returns (bool) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        return isSleeping[gnomeAddress][tokenId];
    }

    function canGetBooped(uint256 tokenId) public view returns (bool) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        if (
            block.timestamp > lastBoopTimeStamp[gnomeAddress][tokenId] + boopCoolDown &&
            block.timestamp > meditateTimeStamp[gnomeAddress][tokenId] &&
            block.timestamp > shieldTimeStamp[gnomeAddress][tokenId]
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isMeditating(uint256 tokenId) public view returns (bool) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        if (block.timestamp > meditateTimeStamp[gnomeAddress][tokenId]) {
            return false;
        } else {
            return true;
        }
    }

    function getGnomeStats(
        uint256 tokenId
    )
        external
        view
        returns (
            string memory _gnomeX,
            uint256 _xp,
            uint256 _hp,
            uint256 _shieldTimeStamp,
            uint256 _meditationTimeStamp,
            uint256 _activityAmount,
            uint256 _boopAmount,
            uint256 _WethSpent,
            uint256 _GnomeSpent,
            uint256 _lastHPUpdateTime,
            uint256 _gnomeEmotion
        )
    {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        _gnomeX = gnomeX_usr[gnomeAddress][tokenId];
        _xp = xp[gnomeAddress][tokenId];
        _hp = currentHP(tokenId);
        _shieldTimeStamp = shieldTimeStamp[gnomeAddress][tokenId];
        _meditationTimeStamp = meditateTimeStamp[gnomeAddress][tokenId];

        _activityAmount = activityAmount[gnomeAddress][tokenId]["mushroom"];
        _boopAmount = boopAmount[gnomeAddress][tokenId];
        _lastHPUpdateTime = lastHPUpdateTime[gnomeAddress][tokenId];
        _gnomeEmotion = gnomeEmotion[gnomeAddress][tokenId];
        _WethSpent = amountSpentETH[gnomeAddress][tokenId];
        _GnomeSpent = amountSpentGNOME[gnomeAddress][tokenId];
    }

    function setGnomeStats(
        uint256 tokenId,
        string memory _gnomeX,
        uint256 _xp,
        uint256 _hp,
        uint256 _shieldTimeStamp,
        uint256 _meditateTimeStamp,
        uint256 _activityAmount,
        uint256 _boopAmount,
        uint256 _lastHPUpdateTime,
        uint256 _gnomeEmotion,
        uint256 _GnomeSpent,
        uint256 _WethSpent
    ) external onlyAuth returns (bool) {
        address gnomeAddress = ownerOfGnome[tokenId];
        require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
        gnomeX_usr[gnomeAddress][tokenId] = _gnomeX;
        xp[gnomeAddress][tokenId] = _xp;
        hp[gnomeAddress][tokenId] = _hp;
        shieldTimeStamp[gnomeAddress][tokenId] = _shieldTimeStamp;
        meditateTimeStamp[gnomeAddress][tokenId] = _meditateTimeStamp;

        activityAmount[gnomeAddress][tokenId]["mushroom"] = _activityAmount;
        boopAmount[gnomeAddress][tokenId] = _boopAmount;
        lastHPUpdateTime[gnomeAddress][tokenId] = _lastHPUpdateTime;
        gnomeEmotion[gnomeAddress][tokenId] = _gnomeEmotion;
        amountSpentGNOME[gnomeAddress][tokenId] = _GnomeSpent;
        amountSpentETH[gnomeAddress][tokenId] = _WethSpent;

        return true;
    }

    function getRankOfGnome(uint256 tokenId) public view returns (uint256) {
        uint256[] memory sortedTokenIds = new uint256[](signedUpIDs.length);
        uint256[] memory sortedXP = new uint256[](signedUpIDs.length);

        // Copy and sort token IDs based on XP
        for (uint256 i = 0; i < signedUpIDs.length; i++) {
            address gnomeAddress = ownerOfGnome[signedUpIDs[i]];
            require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
            sortedTokenIds[i] = signedUpIDs[i];
            sortedXP[i] = xp[gnomeAddress][signedUpIDs[i]];
        }

        // Simple sort (consider using a more efficient sorting algorithm for larger datasets)
        for (uint256 i = 0; i < signedUpIDs.length - 1; i++) {
            for (uint256 j = 0; j < signedUpIDs.length - i - 1; j++) {
                if (sortedXP[j] < sortedXP[j + 1]) {
                    // Swap XP
                    (sortedXP[j], sortedXP[j + 1]) = (sortedXP[j + 1], sortedXP[j]);
                    // Swap Token IDs
                    (sortedTokenIds[j], sortedTokenIds[j + 1]) = (sortedTokenIds[j + 1], sortedTokenIds[j]);
                }
            }
        }

        // Find the rank of the specific tokenId
        for (uint256 rank = 0; rank < sortedTokenIds.length; rank++) {
            if (sortedTokenIds[rank] == tokenId) {
                // Rank is index + 1 since array indices start at 0
                return rank + 1;
            }
        }

        // Return 0 if tokenId is not found in the list
        // Consider handling this case differently as per your application's logic
        return 0;
    }

    function getRankedGnomes()
        public
        view
        returns (
            uint256[] memory sortedTokenIds,
            address[] memory sortedOwners,
            string[] memory sortedOwnersX,
            uint256[] memory sortedEmotion,
            uint256[] memory sortedXP,
            uint256[] memory sortedHP,
            bool[] memory canBeBooped,
            bool[] memory sortedIsMeditating,
            bool[] memory sortedIsSleeping
        )
    {
        sortedTokenIds = new uint256[](signedUpIDs.length);
        sortedXP = new uint256[](signedUpIDs.length);
        sortedHP = new uint256[](signedUpIDs.length); // Add this line
        sortedOwners = new address[](signedUpIDs.length);
        sortedOwnersX = new string[](signedUpIDs.length);
        canBeBooped = new bool[](signedUpIDs.length);
        sortedIsMeditating = new bool[](signedUpIDs.length);
        sortedIsSleeping = new bool[](signedUpIDs.length);
        sortedEmotion = new uint256[](signedUpIDs.length);

        // Copy and sort token IDs based on XP
        for (uint256 i = 0; i < signedUpIDs.length; i++) {
            address gnomeAddress = ownerOfGnome[signedUpIDs[i]];
            require(gnomeAddress != address(0), "Invalid tokenId: owner cannot be the zero address");
            sortedTokenIds[i] = signedUpIDs[i];
            sortedXP[i] = xp[gnomeAddress][signedUpIDs[i]];
            sortedHP[i] = currentHP(signedUpIDs[i]);
            sortedOwners[i] = IGNOME(GNOME_NFT_ADDRESS).ownerOf(signedUpIDs[i]);
            sortedOwnersX[i] = gnomeX_usr[gnomeAddress][signedUpIDs[i]];
            canBeBooped[i] = canGetBooped(signedUpIDs[i]);
            sortedEmotion[i] = gnomeEmotion[gnomeAddress][signedUpIDs[i]];
            sortedIsSleeping[i] = isSleeping[gnomeAddress][signedUpIDs[i]];
            sortedIsMeditating[i] = isMeditating(signedUpIDs[i]);
        }

        // Simple sort (consider using a more efficient sorting algorithm for larger datasets)
        for (uint256 i = 0; i < signedUpIDs.length - 1; i++) {
            for (uint256 j = 0; j < signedUpIDs.length - i - 1; j++) {
                if (sortedXP[j] < sortedXP[j + 1]) {
                    // Swap XP
                    (sortedXP[j], sortedXP[j + 1]) = (sortedXP[j + 1], sortedXP[j]);
                    (sortedHP[j], sortedHP[j + 1]) = (sortedHP[j + 1], sortedHP[j]);
                    // Swap Token IDs
                    (sortedTokenIds[j], sortedTokenIds[j + 1]) = (sortedTokenIds[j + 1], sortedTokenIds[j]);
                    (sortedOwners[j], sortedOwners[j + 1]) = (sortedOwners[j + 1], sortedOwners[j]);
                    (sortedOwnersX[j], sortedOwnersX[j + 1]) = (sortedOwnersX[j + 1], sortedOwnersX[j]);
                    (canBeBooped[j], canBeBooped[j + 1]) = (canBeBooped[j + 1], canBeBooped[j]);
                    (sortedEmotion[j], sortedEmotion[j + 1]) = (sortedEmotion[j + 1], sortedEmotion[j]);
                    (sortedIsSleeping[j], sortedIsSleeping[j + 1]) = (sortedIsSleeping[j + 1], sortedIsSleeping[j]);
                    (sortedIsMeditating[j], sortedIsMeditating[j + 1]) = (
                        sortedIsMeditating[j + 1],
                        sortedIsMeditating[j]
                    );
                }
            }
        }

        return (
            sortedTokenIds,
            sortedOwners,
            sortedOwnersX,
            sortedEmotion,
            sortedXP,
            sortedHP,
            canBeBooped,
            sortedIsMeditating,
            sortedIsSleeping
        );
    }
}