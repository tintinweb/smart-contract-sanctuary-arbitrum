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
    function fatalizeGnomeAuth(uint32 tokenId) external;
}

contract GnomePlayer {
    string public baseTokenURI;

    using Strings for uint256;
    bool public applyTxLimit;
    bool public burnGnome = false;

    // Number of days for HP to decrease to 0
    uint256 public daysToDie = 7 days;

    mapping(address => bool) public isAuth;
    mapping(uint256 => bool) public isDed;
    mapping(uint256 => bool) public isSignedUp;
    uint256[] public signedUpIDs;

    mapping(uint256 => string) public gnomeX_usr;
    mapping(uint256 => uint256) public xp; //Experience Points
    mapping(uint256 => uint256) public hp; //Health Points
    mapping(uint256 => bool[]) public items; //Gnome Items
    mapping(uint256 => uint256) public lastBoopTimeStamp;
    mapping(uint256 => uint256) public lastHPUpdateTime;
    mapping(uint256 => string) public gnomeMetadata;
    mapping(uint256 => mapping(string => uint256)) public activityAmount;
    mapping(uint256 => uint256) public boopAmount;
    mapping(uint256 => uint256) public ethAmount;
    mapping(uint256 => uint256) public gnomeAmount;
    mapping(uint256 => uint256) public meditateTimeStamp;
    mapping(uint256 => uint256) public sleepingTimeStamp;
    mapping(uint256 => uint256) public shieldTimeStamp;
    mapping(address => uint256) public gnomeAddressId;
    mapping(uint256 => uint256) public gnomeEmotion;
    mapping(uint256 => uint256) public amountSpentETH;
    mapping(uint256 => uint256) public amountSpentGNOME;
    mapping(uint256 => bool) public isSleeping;
    uint256 public constant SECONDS_PER_DAY = 86400; // 24 * 60 * 60
    uint256 public boopCoolDown = 15 minutes;
    uint256 public sleepCoolDown = 3 days;

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
        return isSignedUp[tokenId];
    }

    function getTokenUserName(uint256 tokenId) external view returns (string memory) {
        return gnomeX_usr[tokenId];
    }

    function deleteGameStats(uint256 tokenId) public onlyAuth {
        delete xp[tokenId];
        delete hp[tokenId];
        delete meditateTimeStamp[tokenId];
        delete gnomeX_usr[tokenId];
        delete lastBoopTimeStamp[tokenId];
        delete items[tokenId];
        delete amountSpentETH[tokenId];
        delete amountSpentGNOME[tokenId];
        delete gnomeAddressId[IGNOME(GNOME_NFT_ADDRESS).ownerOf(tokenId)];
        delete isSignedUp[tokenId];
        delete sleepingTimeStamp[tokenId];
        delete isSleeping[tokenId];

        // Find and remove the tokenId from signedUpIDs
        for (uint256 i = 0; i < signedUpIDs.length; i++) {
            if (signedUpIDs[i] == tokenId) {
                // Move the last element to the current index
                signedUpIDs[i] = signedUpIDs[signedUpIDs.length - 1];
                // Remove the last element
                signedUpIDs.pop();
                break; // Exit the loop once found and removed
            }
        }
    }

    function setGnomeX(uint256 tokenId, string memory gnomeX) external onlyAuth {
        gnomeX_usr[tokenId] = gnomeX;
    }

    function setGnomeMetadata(uint256 index, string memory uri) external onlyAuth {
        gnomeMetadata[index] = uri;
    }

    function signUpFactory(uint256 tokenId, string memory _Xusr, uint256 _gnomeEmotion) public {
        if (!isAuth[msg.sender]) {
            require(IGNOME(GNOME_NFT_ADDRESS).ownerOf(tokenId) == tx.origin, "Not Auth");
        }
        if (isSignedUp[tokenId]) {
            deleteGameStats(tokenId);
        }
        isSignedUp[tokenId] = true;
        gnomeAddressId[tx.origin] = tokenId;

        gnomeX_usr[tokenId] = _Xusr;
        xp[tokenId] = 10;
        hp[tokenId] = 100;
        lastHPUpdateTime[tokenId] = block.timestamp;
        gnomeEmotion[tokenId] = _gnomeEmotion;
        signedUpIDs.push(tokenId);
    }

    function signUpSecondary(uint256 tokenId, string memory _Xusr, uint256 _gnomeEmotion) public {
        if (!isAuth[msg.sender]) {
            require(IGNOME(GNOME_NFT_ADDRESS).ownerOf(tokenId) == msg.sender, "Not Auth");
        }
        if (!isSignedUp[tokenId]) {
            isSignedUp[tokenId] = true;
            xp[tokenId] = 10;
            hp[tokenId] = 100;
            signedUpIDs.push(tokenId);
        }

        gnomeAddressId[msg.sender] = tokenId;

        gnomeX_usr[tokenId] = _Xusr;

        lastHPUpdateTime[tokenId] = block.timestamp;
        gnomeEmotion[tokenId] = _gnomeEmotion;
    }

    function setBoopTimeStamp(uint256 tokenId, uint256 _lastBoopTimeStamp) external onlyAuth {
        lastBoopTimeStamp[tokenId] = _lastBoopTimeStamp;
    }

    function wakeUpGnome(uint256 tokenId) external onlyAuth {
        isSleeping[tokenId] = false;
    }

    function setShieldTimeStamp(uint256 tokenId, uint256 _shieldTimeStamp) external onlyAuth {
        shieldTimeStamp[tokenId] = _shieldTimeStamp;
    }

    function setMeditateTimeStamp(uint256 tokenId, uint256 _meditateTimeStamp) external onlyAuth {
        meditateTimeStamp[tokenId] = _meditateTimeStamp;
    }

    mapping(uint256 => uint256) public gnomeShieldTimeStamp;

    function setGnomeItems(uint256 tokenId, bool[] memory _items) external onlyAuth {
        items[tokenId] = _items;
    }

    function setGnomeActivityAmount(
        string memory activity,
        uint256 tokenId,
        uint256 _activityAmount
    ) external onlyAuth {
        activityAmount[tokenId][activity] = _activityAmount;
    }

    function increaseGnomeActivityAmount(
        string memory activity,
        uint256 tokenId,
        uint256 _activityAmount
    ) external onlyAuth {
        activityAmount[tokenId][activity] += _activityAmount;
    }

    function setGnomeBoopAmount(uint256 tokenId, uint256 _boopAmount) external onlyAuth {
        boopAmount[tokenId] = _boopAmount;
    }

    function increaseGnomeBoopAmount(uint256 tokenId, uint256 _gnomeAmount) external onlyAuth {
        gnomeAmount[tokenId] += _gnomeAmount;
    }

    function setGnomeSpentAmount(uint256 tokenId, uint256 _gnomeAmount) external onlyAuth {
        gnomeAmount[tokenId] = _gnomeAmount;
    }

    function increaseETHSpentAmount(uint256 tokenId, uint256 _ethAmount) external onlyAuth {
        ethAmount[tokenId] += _ethAmount;
    }

    function setETHSpentAmount(uint256 tokenId, uint256 _ethAmount) external onlyAuth {
        ethAmount[tokenId] = _ethAmount;
    }

    function increaseGnomeSpentAmount(uint256 tokenId, uint256 _gnomeAmount) external onlyAuth {
        gnomeAmount[tokenId] += _gnomeAmount;
    }

    function setGnomeHPUpdate(uint256 tokenId, uint256 _lastHPUpdateTime) external onlyAuth {
        lastHPUpdateTime[tokenId] = _lastHPUpdateTime;
    }

    function setIsAuth(address gnome, bool isAuthorized) external onlyAuth {
        isAuth[gnome] = isAuthorized;
    }

    function setBurnGnome(bool _burnActive) public onlyAuth {
        burnGnome = _burnActive;
    }

    function setBoopCoolDown(uint256 _boopCoolDown) public onlyAuth {
        boopCoolDown = _boopCoolDown;
    }

    function setSleepCoolDown(uint256 _sleepCoolDown) public onlyAuth {
        sleepCoolDown = _sleepCoolDown;
    }

    function setGnomeXP(uint256 tokenId, uint256 _xp) external onlyAuth {
        xp[tokenId] = _xp;
    }

    function setGnomeHP(uint256 tokenId, uint256 _hp) external onlyAuth {
        hp[tokenId] = _hp;
    }

    function increaseXP(uint256 tokenId, uint256 _XP) public onlyAuth {
        xp[tokenId] += _XP;
    }

    function decreaseXP(uint256 tokenId, uint256 _XP) public onlyAuth {
        xp[tokenId] = (_XP > xp[tokenId]) ? 0 : xp[tokenId] - _XP;
    }

    function increaseHP(uint256 tokenId, uint256 _HP) public onlyAuth {
        hp[tokenId] = currentHP(tokenId) + _HP;
        lastHPUpdateTime[tokenId] = block.timestamp;
    }

    function decreaseHP(uint256 tokenId, uint256 _HP) public onlyAuth {
        if (_HP > currentHP(tokenId)) {
            hp[tokenId] = 0;
            if (!isSleeping[tokenId]) {
                isSleeping[tokenId] = true;
                sleepingTimeStamp[tokenId] = block.timestamp;
            }
            if (burnGnome && (block.timestamp > sleepingTimeStamp[tokenId] + sleepCoolDown)) {
                IGNOME(GNOME_NFT_ADDRESS).fatalizeGnomeAuth(uint32(tokenId));
                deleteGameStats(tokenId);
            }
        } else {
            hp[tokenId] = currentHP(tokenId) - _HP;
        }
    }

    function setDaysToDie(uint256 _days) external onlyAuth {
        daysToDie = _days;
    }

    function currentHP(uint256 tokenId) public view returns (uint256) {
        // Get the last time HP was updated for the gnome
        uint256 lastUpdateTime = lastHPUpdateTime[tokenId];

        // Calculate the elapsed time since the last HP update
        uint256 elapsedTime = (block.timestamp - lastUpdateTime);

        // Calculate the expected HP decrease based on the elapsed time and decrease rate
        uint256 decreaseAmount = elapsedTime > daysToDie ? hp[tokenId] : (hp[tokenId] * elapsedTime) / daysToDie;

        // Calculate the expected HP
        uint256 expectedHP = hp[tokenId] > decreaseAmount ? hp[tokenId] - decreaseAmount : 0;

        return expectedHP;
    }

    function setItem(uint256 tokenId, uint256 _itemIndex) public onlyAuth {
        items[tokenId][_itemIndex] = true;
    }

    function setGnomeEmotion(uint256 tokenId, uint256 _gnomeEmotion) public onlyAuth {
        gnomeEmotion[tokenId] = _gnomeEmotion;
    }

    function getBoopTimeStamp(uint256 gnomeID) public view returns (uint256) {
        return lastBoopTimeStamp[gnomeID];
    }

    function getShieldTimeStamp(uint256 gnomeID) public view returns (uint256) {
        return shieldTimeStamp[gnomeID];
    }

    function getMeditateTimeStamp(uint256 gnomeID) public view returns (uint256) {
        return meditateTimeStamp[gnomeID];
    }

    function getSleepingTimeStamp(uint256 gnomeID) public view returns (uint256) {
        return sleepingTimeStamp[gnomeID];
    }

    function getXP(uint256 tokenId) public view returns (uint256) {
        return xp[tokenId];
    }

    function getHP(uint256 tokenId) public view returns (uint256) {
        return hp[tokenId];
    }

    function getID(address gnome) public view returns (uint256) {
        return gnomeAddressId[gnome];
    }

    function getIsSleeping(uint256 tokenId) public view returns (bool) {
        return isSleeping[tokenId];
    }

    function canGetBooped(uint256 tokenId) public view returns (bool) {
        if (
            block.timestamp > lastBoopTimeStamp[tokenId] + boopCoolDown &&
            block.timestamp > meditateTimeStamp[tokenId] &&
            block.timestamp > shieldTimeStamp[tokenId]
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isMeditating(uint256 tokenId) public view returns (bool) {
        if (block.timestamp > meditateTimeStamp[tokenId]) {
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
            bool[] memory _items,
            uint256 _activityAmount,
            uint256 _boopAmount,
            uint256 _WethSpent,
            uint256 _GnomeSpent,
            uint256 _lastHPUpdateTime,
            uint256 _gnomeEmotion
        )
    {
        _gnomeX = gnomeX_usr[tokenId];
        _xp = xp[tokenId];
        _hp = currentHP(tokenId);
        _shieldTimeStamp = shieldTimeStamp[tokenId];
        _meditationTimeStamp = meditateTimeStamp[tokenId];
        _items = items[tokenId];
        _activityAmount = activityAmount[tokenId]["mushroom"];
        _boopAmount = boopAmount[tokenId];
        _lastHPUpdateTime = lastHPUpdateTime[tokenId];
        _gnomeEmotion = gnomeEmotion[tokenId];
        _WethSpent = amountSpentETH[tokenId];
        _GnomeSpent = amountSpentGNOME[tokenId];
    }

    function setGnomeStats(
        uint256 tokenId,
        string memory _gnomeX,
        uint256 _xp,
        uint256 _hp,
        uint256 _shieldTimeStamp,
        uint256 _meditateTimeStamp,
        bool[] memory _items,
        uint256 _activityAmount,
        uint256 _boopAmount,
        uint256 _lastHPUpdateTime,
        uint256 _gnomeEmotion,
        uint256 _GnomeSpent,
        uint256 _WethSpent
    ) external onlyAuth returns (bool) {
        gnomeX_usr[tokenId] = _gnomeX;
        _xp = xp[tokenId];
        _hp = hp[tokenId];
        shieldTimeStamp[tokenId] = _shieldTimeStamp;
        meditateTimeStamp[tokenId] = _meditateTimeStamp;
        items[tokenId] = _items;
        activityAmount[tokenId]["mushroom"] = _activityAmount;
        boopAmount[tokenId] = _boopAmount;
        lastHPUpdateTime[tokenId] = _lastHPUpdateTime;
        gnomeEmotion[tokenId] = _gnomeEmotion;
        amountSpentGNOME[tokenId] = _GnomeSpent;
        amountSpentETH[tokenId] = _WethSpent;

        return true;
    }

    function getRankOfGnome(uint256 tokenId) public view returns (uint256) {
        uint256[] memory sortedTokenIds = new uint256[](signedUpIDs.length);
        uint256[] memory sortedXP = new uint256[](signedUpIDs.length);

        // Copy and sort token IDs based on XP
        for (uint256 i = 0; i < signedUpIDs.length; i++) {
            sortedTokenIds[i] = signedUpIDs[i];
            sortedXP[i] = xp[signedUpIDs[i]];
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
            bool[] memory canBeBooped,
            uint256[] memory sortedEmotion,
            address[] memory sortedOwners,
            string[] memory sortedOwnersX,
            uint256[] memory sortedXP,
            uint256[] memory sortedHP
        )
    {
        sortedTokenIds = new uint256[](signedUpIDs.length);
        sortedXP = new uint256[](signedUpIDs.length);
        sortedHP = new uint256[](signedUpIDs.length); // Add this line
        sortedOwners = new address[](signedUpIDs.length);
        sortedOwnersX = new string[](signedUpIDs.length);
        canBeBooped = new bool[](signedUpIDs.length);
        sortedEmotion = new uint256[](signedUpIDs.length);

        // Copy and sort token IDs based on XP
        for (uint256 i = 0; i < signedUpIDs.length; i++) {
            sortedTokenIds[i] = signedUpIDs[i];
            sortedXP[i] = xp[signedUpIDs[i]];
            sortedHP[i] = currentHP(signedUpIDs[i]);
            sortedOwners[i] = IGNOME(GNOME_NFT_ADDRESS).ownerOf(signedUpIDs[i]);
            sortedOwnersX[i] = gnomeX_usr[signedUpIDs[i]];
            canBeBooped[i] = canGetBooped(signedUpIDs[i]);
            sortedEmotion[i] = gnomeEmotion[signedUpIDs[i]];
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
                }
            }
        }

        return (sortedTokenIds, canBeBooped, sortedEmotion, sortedOwners, sortedOwnersX, sortedXP, sortedHP);
    }
}