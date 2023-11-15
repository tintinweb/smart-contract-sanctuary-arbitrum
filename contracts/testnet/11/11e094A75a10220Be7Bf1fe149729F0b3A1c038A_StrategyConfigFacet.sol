// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

error TooFewSignLens();
error DuplicateSigner();
error InvalidStrategy();
error InvalidSignature();
error InvalidSignerNum();
error InvalidMarkPrice();
error RepeatedSignerAddress();
error InvalidPortfolioMargin();
error InvalidObservationsTimestamp(uint256 observationsTimestamp, uint256 latestTransmissionTimestamp);
error InvalidAddress(address thrower, address inputAddress);
error InvalidPosition();

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Constants} from "../../utils/Constants.sol";
import {IStrategyConfig} from "../interfaces/IStrategyConfig.sol";
import {LibStrategyConfig} from "../libraries/LibStrategyConfig.sol";
import {LibAccessControlEnumerable} from "../libraries/LibAccessControlEnumerable.sol";
import {StrategyTypes} from "../libraries/StrategyTypes.sol";

/**
 * @title DEDERI Strategy Config
 * @author dederi
 * @notice This contract is strategy Config.
 */
contract StrategyConfigFacet is IStrategyConfig {
    // market
    error MarketAlreadyAdded(address market_);
    error SupportMarketExist(address market);
    error StrategyConfig__CollateralAlreadyListed(address asset);
    error StrategyConfig__CollateralNotExist(address asset);

    /// @notice Emitted when an admin supports a market
    event MarketAdded(address indexed market);
    event MarketRemoved(address indexed market);

    event CollateralListed(address indexed asset);
    event CollateralDelisted(address indexed asset);

    function isReserveToken(address token) external view returns (bool) {
        return LibStrategyConfig._isReserveToken(token);
    }

    /**
     * @notice 是否支持该市场
     * @param underlying 要查询的标的资产地址
     * @return 返回
     */
    function getMarketInfo(address underlying) external view returns (StrategyTypes.Market memory) {
        return LibStrategyConfig.layout().markets[underlying];
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() external view returns (address[] memory) {
        return LibStrategyConfig.layout().allMarkets;
    }

    /// @notice 上架或下架抵押品
    function updateCollateral(address _asset, bool isList) external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);

        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        if (isList) {
            if (l.isReserveToken[_asset]) {
                revert StrategyConfig__CollateralAlreadyListed(_asset);
            }

            l.isReserveToken[_asset] = true;
            emit CollateralListed(_asset);
        } else {
            if (!l.isReserveToken[_asset]) {
                revert StrategyConfig__CollateralNotExist(_asset);
            }

            delete l.isReserveToken[_asset];
            emit CollateralDelisted(_asset);
        }
    }

    function addMarket(address underlying_) external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);

        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        if (l.markets[underlying_].isListed) {
            revert SupportMarketExist(underlying_);
        }

        // Note that isComped is not in active use anymore
        l.markets[underlying_].isListed = true;
        _addMarketInternal(l, underlying_);
        emit MarketAdded(underlying_);
    }

    function removeMarket(address underlying_) external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        LibStrategyConfig._ensureListed(l.markets[underlying_]);

        // Remove the market from markets.
        delete l.markets[underlying_];
        uint256 allMarketsLen = l.allMarkets.length;
        for (uint256 i; i < allMarketsLen; ) {
            if (l.allMarkets[i] == underlying_) {
                l.allMarkets[i] = l.allMarkets[allMarketsLen - 1];
                // Remove last element from array
                l.allMarkets.pop();

                break;
            }
            unchecked {
                ++i;
            }
        }

        emit MarketRemoved(underlying_);
    }

    /*//////////////////////////////////////////////////////////////
                      INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _addMarketInternal(LibStrategyConfig.Layout storage l, address market_) internal {
        uint256 allMarketLen = l.allMarkets.length;
        for (uint i = 0; i < allMarketLen; ) {
            if (l.allMarkets[i] == market_) {
                revert MarketAlreadyAdded(market_);
            }
            unchecked {
                ++i;
            }
        }
        l.allMarkets.push(market_);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "../libraries/StrategyTypes.sol";

interface IStrategyConfig {
    //////////
    // View //
    //////////
    function getMarketInfo(address underlying) external view returns (StrategyTypes.Market memory);

    function isReserveToken(address token) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibAccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.AccessControlEnumerable");

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
        mapping(bytes4 => bool) supportedInterfaces;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function checkRole(bytes32 role) internal view {
        checkRole(role, msg.sender);
    }

    function checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        return l.roles[role].members[account];
    }

    function grantRole(bytes32 role, address account) internal {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        if (!hasRole(role, account)) {
            l.roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
            l.roleMembers[role].add(account);
        }
    }

    function revokeRole(bytes32 role, address account) internal {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        if (hasRole(role, account)) {
            l.roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
            l.roleMembers[role].remove(account);
        }
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        bytes32 previousAdminRole = l.roles[role].adminRole;
        l.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {InvalidStrategy} from "../errors/GenericErrors.sol";
import {StrategyTypes} from "./StrategyTypes.sol";

library LibStrategyConfig {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.StrategyConfig");

    error MarketNotListed();
    error OnlyReserveToken(address token);
    error OnlyStrategyOwner();
    error PositionIdDuplicates(uint256 id);
    error StrategyIsNotActive(uint256 strategyId);
    // signature
    error InvalidSignature();
    error SignatureAlreadyUsed(address user);

    struct Layout {
        /// @notice 支持的抵押品
        mapping(address => bool) isReserveToken;
        /**
         * @notice Official mapping of cTokens -> Market metadata
         * @dev Used e.g. to determine if a market is supported
         */
        mapping(address => StrategyTypes.Market) markets;
        /// @notice 所有市场的标的资产地址
        address[] allMarkets;
        address vault;
        /// @notice 用户对应的admin nonce，用于生成某个admin唯一的requestHash
        mapping(address => uint256) userNonce;
        mapping(address => mapping(bytes32 => bool)) usedSignatureHash;
        /// @notice 开仓，开仓加腿合并，平仓等请求中需要的参数
        mapping(bytes32 => StrategyTypes.StrategyRequest) userRequestStrategy;
        // @notice 提前平仓请求中需要的参数
        mapping(bytes32 => StrategyTypes.SellStrategyRequest) userSellRequest;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Reverts if the signature is used
    function _checkSignatureExists(address user, bytes memory signature) internal {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        bytes32 userSigHash = keccak256(signature);
        if (l.usedSignatureHash[user][userSigHash]) {
            revert SignatureAlreadyUsed(user);
        }
        // // Mark the signature as used
        l.usedSignatureHash[user][userSigHash] = true;
    }

    /// @notice Reverts if the caller is not support collateral
    function _ensureSupportCollateral(address _token) internal view {
        if (!LibStrategyConfig._isReserveToken(_token)) {
            revert OnlyReserveToken(_token);
        }
    }

    /// @notice Reverts if the market is not listed
    function _ensureListed(StrategyTypes.Market storage market) internal view {
        if (!market.isListed) {
            revert MarketNotListed();
        }
    }

    /// @notice 是否为支持的抵押品
    function _isReserveToken(address token) internal view returns (bool) {
        return LibStrategyConfig.layout().isReserveToken[token];
    }

    /// @notice Reverts if the caller is not admin or strategy is not active
    function _ensureAdminAndActive(StrategyTypes.StrategyDataWithOwner memory strategy, address _admin) internal pure {
        if (_admin != strategy.owner) {
            revert OnlyStrategyOwner();
        }
        if (!strategy.isActive) {
            revert StrategyIsNotActive(strategy.strategyId);
        }
    }

    /**
     * @notice 先获取requestHash，然后更新nonce
     * @param user 用户地址
     * @return requestHash 返回requestHash
     */
    function _getRequestHashAndUpdateNonce(address user) internal returns (bytes32 requestHash) {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        requestHash = keccak256(abi.encode(user, l.userNonce[user]));
        l.userNonce[user] += 1;
    }

    function _checkSamePosition(StrategyTypes.StrategyRequest memory strategy) internal pure {
        uint256 optionLen = strategy.option.length;
        uint256 futureLen = strategy.option.length;
        for (uint256 i = 0; i < optionLen; ) {
            for (uint256 j = i + 1; j < optionLen; ) {
                bool isSame = _checkOptionPosition(
                    strategy.option[i],
                    strategy.option[j],
                    strategy.option[i].underlying
                );
                if (!isSame) {
                    revert InvalidStrategy();
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < futureLen; ) {
            for (uint256 j = i + 1; j < futureLen; ) {
                bool isSame = _checkFuturePosition(
                    strategy.future[i],
                    strategy.future[j],
                    strategy.future[i].underlying
                );
                if (!isSame) {
                    revert InvalidStrategy();
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function _validateStrategy(
        StrategyTypes.StrategyRequest memory makerStrategy,
        StrategyTypes.StrategyRequest memory takerStrategy
    ) internal pure returns (bool) {
        uint256 makerOptionLen = makerStrategy.option.length;
        uint256 makerFutureLen = makerStrategy.future.length;
        uint256 takerOptionLen = takerStrategy.option.length;
        uint256 takerFutureLen = takerStrategy.future.length;
        uint256 makerLen = makerOptionLen + makerFutureLen;
        uint256 takerLen = takerOptionLen + takerFutureLen;
        uint256 legLimit;

        if (makerLen != takerLen || takerLen > legLimit) {
            return false;
        }
        address underlying;
        if (makerOptionLen > 0) {
            underlying = makerStrategy.option[0].underlying;
        } else {
            underlying = makerStrategy.future[0].underlying;
        }

        for (uint256 i = 0; i < makerOptionLen; ) {
            bool isSame = _checkOptionPosition(makerStrategy.option[i], takerStrategy.option[i], underlying);
            if (!isSame) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _checkFuturePosition(
        StrategyTypes.Future memory future1,
        StrategyTypes.Future memory future2,
        address underlying
    ) internal pure returns (bool) {
        if (future1.underlying != underlying) {
            return false;
        }
        if (future2.underlying != underlying) {
            return false;
        }
        bytes32 future1Hash = keccak256(
            abi.encode(future1.entryPrice, future1.expiryTime, future1.size, future1.isLong)
        );
        bytes32 future2Hash = keccak256(
            abi.encode(future2.entryPrice, future2.expiryTime, future2.size, future2.isLong)
        );
        if (future1Hash == future2Hash) {
            return false;
        }
        if (future1.isLong == !future2.isLong) {
            return false;
        }
        // TODO 验证每条腿开仓的时间是不是我们限定的时间点
        return true;
    }

    function _checkOptionPosition(
        StrategyTypes.Option memory option1,
        StrategyTypes.Option memory option2,
        address underlying
    ) internal pure returns (bool) {
        if (option1.underlying != underlying) {
            return false;
        }
        if (option2.underlying != underlying) {
            return false;
        }
        bytes32 option1Hash = keccak256(
            abi.encode(option1.strikePrice, option1.premium, option1.size, option1.expiryTime)
        );
        bytes32 option2Hash = keccak256(
            abi.encode(option2.strikePrice, option2.premium, option2.size, option2.expiryTime)
        );
        if (option1Hash == option2Hash) {
            return false;
        }
        if (option1.optionType == StrategyTypes.OptionType.LONG_CALL) {
            if (option2.optionType != StrategyTypes.OptionType.SHORT_CALL) {
                return false;
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.SHORT_CALL) {
            if (option2.optionType != StrategyTypes.OptionType.LONG_CALL) {
                return false;
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.LONG_PUT) {
            if (option2.optionType != StrategyTypes.OptionType.SHORT_PUT) {
                return false;
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.SHORT_PUT) {
            if (option2.optionType != StrategyTypes.OptionType.LONG_PUT) {
                return false;
            }
        }
        // TODO 验证每条腿开仓的时间是不是我们限定的时间点
        return true;
    }

    /// @notice 此函数用于检查腿 ID 数组中是否存在重复的腿 ID，如果有重复，将触发错误。
    function _checkPositionIdDuplicates(uint256[] memory ids) internal pure {
        uint256 idsLen = ids.length;
        for (uint256 i; i < idsLen; ) {
            for (uint256 j = i + 1; j < idsLen; ) {
                if (ids[i] == ids[j]) {
                    revert PositionIdDuplicates(ids[i]);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice 设置开仓时的userRequst 参数
    function _updateUserRequestStrategy(bytes32 requestId, StrategyTypes.StrategyRequest memory _strategy) internal {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        l.userRequestStrategy[requestId].timestamp = _strategy.timestamp;
        l.userRequestStrategy[requestId].mergeId = _strategy.mergeId;
        // 抵押品
        uint256 collateralLen = _strategy.collaterals.length;
        for (uint256 i; i < collateralLen; ) {
            StrategyTypes.CollateralInfo memory collateral_ = _strategy.collaterals[i];
            l.userRequestStrategy[requestId].collaterals.push(collateral_);
            unchecked {
                ++i;
            }
        }

        uint256 optionLen = _strategy.option.length;
        for (uint256 i; i < optionLen; ) {
            StrategyTypes.Option memory option_ = _strategy.option[i];
            l.userRequestStrategy[requestId].option.push(option_);

            unchecked {
                ++i;
            }
        }

        uint256 futureLen = _strategy.future.length;
        for (uint256 i; i < futureLen; ) {
            StrategyTypes.Future memory future_ = _strategy.future[i];
            l.userRequestStrategy[requestId].future.push(future_);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice 设置开仓时的userRequst 参数
    function _updateUserSellRequestStrategy(
        bytes32 requestId,
        StrategyTypes.SellStrategyRequest memory _strategy
    ) internal {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        l.userSellRequest[requestId].strategyId = _strategy.strategyId;
        l.userSellRequest[requestId].price = _strategy.price;
        l.userSellRequest[requestId].receiver = _strategy.receiver;
        l.userSellRequest[requestId].admin = _strategy.admin;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

library StrategyTypes {
    enum AssetType {
        OPTION,
        FUTURE
    }

    enum OptionType {
        LONG_CALL,
        LONG_PUT,
        SHORT_CALL,
        SHORT_PUT
    }

    ///////////////////
    // Internal Data //
    ///////////////////

    struct Option {
        uint256 positionId;
        // underlying asset address
        address underlying;
        // option strike price (with 18 decimals)
        uint256 strikePrice;
        int256 premium;
        // option expiry timestamp
        uint256 expiryTime;
        // order size
        uint256 size;
        // option type
        OptionType optionType;
        bool isActive;
    }

    struct Future {
        uint256 positionId;
        // underlying asset address
        address underlying;
        // (with 18 decimals)
        uint256 entryPrice;
        // future expiry timestamp
        uint256 expiryTime;
        // order size
        uint256 size;
        bool isLong;
        bool isActive;
    }

    struct CollateralInfo {
        address collateralToken;
        uint256 collateralAmount;
    }

    struct PositionData {
        uint256 positionId;
        AssetType assetType;
        bool isActive;
    }

    struct StrategyData {
        uint256 strategyId;
        uint256 timestamp;
        uint256[] positionIds;
        CollateralInfo[] collaterals;
        int256 realisedPnl;
        bool isActive;
    }

    struct StrategyDataWithOwner {
        uint256 strategyId;
        uint256[] positionIds;
        CollateralInfo[] collaterals;
        int256 realisedPnl;
        bool isActive;
        address owner;
    }

    struct Strategy {
        address admin;
        uint256 timestamp;
        int256 realizedPnl;
        // 合并的id：如果为0，表示不合并；有值进行验证并合并
        uint256 mergeId;
        bool isActive;
        CollateralInfo[] collaterals;
        Option[] option;
        Future[] future;
    }

    struct CreateAndMergeStrategyRequest {
        uint256 strategyId;
    }

    struct DecreaseStrategyCollateralRequest {
        address admin;
        uint256 strategyId;
        CollateralInfo[] collaterals;
    }

    struct MergeStrategyRequest {
        address admin;
        uint256 firstStrategyId;
        uint256 secondStrategyId;
        CollateralInfo[] newCollaterals;
    }

    struct SpiltStrategyRequest {
        address admin;
        uint256 strategyId;
        uint256[] positionIds;
        CollateralInfo[] originalCollateralsToTopUp;
        CollateralInfo[] newlySplitCollaterals;
    }

    struct LiquidateStrategyRequest {
        uint256 strategyId;
        address admin;
    }

    struct StrategyRequest {
        address admin;
        uint256 timestamp;
        uint256 mergeId;
        CollateralInfo[] collaterals;
        Option[] option;
        Future[] future;
    }

    struct SellStrategyRequest {
        uint256 strategyId;
        uint256[] positionIds;
        int256 price;
        address receiver;
        address admin;
    }

    struct Market {
        // Whether or not this market is listed
        bool isListed;
        // 保证金缩水率
        uint256 marginScale;
        // 合约乘数
        // 上限
        // 下限
    }

    ///////////////////
    // Margin Oracle //
    ///////////////////

    struct MarginItemWithId {
        uint256 strategyId;
        uint256 im;
        uint256 mm;
        uint256 updateAt;
    }

    struct MarginItemWithHash {
        bytes32 requestHash;
        uint256 im;
        uint256 mm;
        uint256 updateAt;
    }

    ///////////////////
    //   Mark Price  //
    ///////////////////

    struct MarkPriceItemWithId {
        uint256 positionId;
        uint256 price;
        uint256 updateAt;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

type Price8 is uint64;
type Qty10 is uint80;
type Usd18 is uint96;

library Constants {
    /*-------------------------------- Role --------------------------------*/
    // 0x0000000000000000000000000000000000000000000000000000000000000000
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    // 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // 0xfc425f2263d0df187444b70e47283d622c70181c5baebb1306a01edba1ce184c
    bytes32 internal constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    // 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab
    bytes32 internal constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    // 0xa47af3fd2c1c79eb1dca3988e5817b1cc324b3345b8992b0bc7c0ff492863c88
    // bytes32 internal constant MARK_SIGNER_ROLE = keccak256("MARK_SIGNER_ROLE");
    // 0xb5f6c0f8c55ae10f5b95eff27f33679ba36b6c38c8459d642ed21a2d895bda6f
    bytes32 internal constant MARGIN_SIGNER_ROLE = keccak256("MARGIN_SIGNER_ROLE");
    // 0x8227712ef8ad39d0f26f06731ef0df8665eb7ada7f41b1ee089adf3c238862a2
    bytes32 internal constant MONITOR_ROLE = keccak256("MONITOR_ROLE");

    bytes32 internal constant STRATEGY_REQUEST_TYPE_HASH =
        keccak256(
            "Strategy("
            "address admin,"
            "uint256 timestamp,"
            "uint256[] mergeId,"
            "CollateralInfo[] collaterals,"
            "Option[] option,"
            "Future[] future"
            ")"
        );

    /*-------------------------------- Decimals --------------------------------*/
    uint8 public constant PRICE_DECIMALS = 8;
    uint8 public constant QTY_DECIMALS = 10;
    uint8 public constant USD_DECIMALS = 18;

    uint16 public constant BASIS_POINTS_DIVISOR = 1e4;
    uint16 public constant MAX_LEVERAGE = 1e3;
    int256 public constant FUNDING_FEE_RATE_DIVISOR = 1e18;
    uint16 public constant MAX_DAO_SHARE_P = 2000;
    uint16 public constant MAX_COMMISSION_P = 8000;
    uint8 public constant FEED_DELAY_BLOCK = 100;
    uint8 public constant MAX_REQUESTS_PER_PAIR_IN_BLOCK = 100;
    uint256 public constant TIME_LOCK_DELAY = 2 hours;
    uint256 public constant TIME_LOCK_GRACE_PERIOD = 12 hours;
}