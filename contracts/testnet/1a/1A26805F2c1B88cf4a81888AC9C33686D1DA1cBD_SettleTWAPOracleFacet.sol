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

error LengthMismatch();
error InvalidParam();
error TooFewSignLens();
error DuplicateSigner();
error InvalidStrategy();
error InvalidSignature();
error InvalidSignerNum();
error InvalidMarkPrice();
error RepeatedSignerAddress();
error InvalidPortfolioMarginForId(uint256 strategyId);
error InvalidPortfolioMarginForHash(bytes32 requestHash);
error PriceOutOfRange(uint256 reportPrice, uint256 anchorPrice);
error AnchorRatioMismatch(uint256 min, uint256 lower, uint256 upper, uint256 max);
error InvalidObservationsTimestamp(uint256 observationsTimestamp, uint256 latestTransmissionTimestamp);
error InvalidAddress(address thrower, address inputAddress);
error InvalidPosition();
error StrategyIsNotActive(uint256 strategyId);

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Constants} from "../../utils/Constants.sol";
import {LibUniTWAPOracle} from "../libraries/LibUniTWAPOracle.sol";
import {LibSettleTWAPOracle} from "../libraries/LibSettleTWAPOracle.sol";
import {LibAccessControlEnumerable} from "../libraries/LibAccessControlEnumerable.sol";
import {InvalidAddress, LengthMismatch, PriceOutOfRange, AnchorRatioMismatch, InvalidObservationsTimestamp} from "../errors/GenericErrors.sol";

contract SettleTWAPOracleFacet {
    struct SettleTWAPOracleParam {
        address asset; // Asset address
        uint256 expireTime; // 到期结算时间
        uint256 price; // Asset price in 18 decimals
        uint256 observationsTimestamp; // when were observations made offchain
    }
    /// @notice Emit when a price is manually set
    event SettleTWAPPosted(address indexed asset, uint256 indexed price, uint256 startedAt, uint256 updatedAt);

    /// @notice Emit when a anchor ratio is updated
    event SettleTWAPAnchorRatioUpdated(uint256 lowerBoundAnchorRatio, uint256 upperBoundAnchorRatio);

    ///////////////
    // Modifiers //
    ///////////////

    modifier notNullAddress(address someone) {
        if (someone == address(0)) revert InvalidAddress(address(this), someone);
        _;
    }

    /**
     * @notice Get the settle twap of a listed underlying token asset
     * @param asset Address of the asset
     * @param expireTime 到期结算时间
     * @return price Price in USDC, with 18 decimals of precision
     */
    function getSettleTWAP(address asset, uint256 expireTime) external view returns (uint256) {
        return LibSettleTWAPOracle._getSettleTWAP(asset, expireTime);
    }

    /// @notice 获取settle twap 锚定比例
    function getSettleTWAPAnchorRatio() external view returns (uint256, uint256) {
        LibSettleTWAPOracle.Layout storage l = LibSettleTWAPOracle.layout();
        return (l.lowerBoundAnchorRatio, l.upperBoundAnchorRatio);
    }

    function setSettleTWAPAnchorRatio(uint256 _lowerBoundAnchorRatio, uint256 _upperBoundAnchorRatio) external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        LibSettleTWAPOracle.Layout storage l = LibSettleTWAPOracle.layout();
        if (
            Constants.MIN_BOUND_ANCHOR_RATIO > _lowerBoundAnchorRatio ||
            Constants.MAX_BOUND_ANCHOR_RATIO < _upperBoundAnchorRatio ||
            _upperBoundAnchorRatio <= _lowerBoundAnchorRatio
        ) {
            revert AnchorRatioMismatch(
                Constants.MIN_BOUND_ANCHOR_RATIO,
                _lowerBoundAnchorRatio,
                _upperBoundAnchorRatio,
                Constants.MAX_BOUND_ANCHOR_RATIO
            );
        }

        l.lowerBoundAnchorRatio = _lowerBoundAnchorRatio;
        l.upperBoundAnchorRatio = _upperBoundAnchorRatio;

        emit SettleTWAPAnchorRatioUpdated(l.lowerBoundAnchorRatio, l.upperBoundAnchorRatio);
    }

    /**
     * @notice Manually set the price of a given asset
     * @param params 到期结算设置价格结构体数组
     */
    function setSettleTWAPs(SettleTWAPOracleParam[] calldata params) external {
        uint256 numAssets = params.length;
        for (uint256 i; i < numAssets; ) {
            setSettleTWAP(params[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Manually set the price of a given asset
     * @param param 到期结算设置价格结构体
     */
    function setSettleTWAP(SettleTWAPOracleParam calldata param) public notNullAddress(param.asset) {
        LibAccessControlEnumerable.checkRole(Constants.KEEPER_ROLE);
        LibSettleTWAPOracle.Layout storage l = LibSettleTWAPOracle.layout();
        uint256 latestTransmissionTimestamp = l.priceData[param.asset][param.expireTime].transmissionTimestamp;
        if (param.observationsTimestamp <= latestTransmissionTimestamp) {
            revert InvalidObservationsTimestamp(param.observationsTimestamp, latestTransmissionTimestamp);
        }
        // check diff with twap price
        uint256 twapPrice = LibUniTWAPOracle._getTWAPUniV3(param.asset);
        if (!_isWithinAnchor(param.price, twapPrice)) {
            revert PriceOutOfRange(param.price, twapPrice);
        }

        l.priceData[param.asset][param.expireTime] = LibSettleTWAPOracle.PriceDataItem(
            param.price,
            param.observationsTimestamp,
            uint256(block.timestamp)
        );
        emit SettleTWAPPosted(param.asset, param.price, param.observationsTimestamp, block.timestamp);
    }

    /**
     * @notice This is called by the reporter whenever a new price is posted on-chain
     * @param reporterPrice the price from the reporter
     * @param anchorPrice the price from the other contract
     * @return valid bool
     */
    function _isWithinAnchor(uint256 reporterPrice, uint256 anchorPrice) internal view returns (bool) {
        LibSettleTWAPOracle.Layout storage l = LibSettleTWAPOracle.layout();
        if (reporterPrice > 0 && anchorPrice > 0) {
            uint256 minAnswer = (anchorPrice * l.lowerBoundAnchorRatio) / Constants.EXP_SCALE;
            uint256 maxAnswer = (anchorPrice * l.upperBoundAnchorRatio) / Constants.EXP_SCALE;
            return minAnswer <= reporterPrice && reporterPrice <= maxAnswer;
        }
        return false;
    }
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

import {LibStrategyConfig} from "./LibStrategyConfig.sol";

library LibSettleTWAPOracle {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.SettleTWAPOracle");

    struct PriceDataItem {
        uint256 price; // USDC-rate, multiplied by 1e18.
        uint256 observationsTimestamp; // when were observations made offchain
        uint256 transmissionTimestamp; // when was report received onchain
    }

    struct Layout {
        /// @notice The highest ratio of the new price to the anchor price that will still trigger the price to be updated
        uint256 upperBoundAnchorRatio;
        /// @notice The lowest ratio of the new price to the anchor price that will still trigger the price to be updated
        uint256 lowerBoundAnchorRatio;
        /// @notice Manually set an override price, useful under extenuating conditions such as price feed failure
        mapping(address => mapping(uint256 => PriceDataItem)) priceData;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    error SettleOracle__InvalidPrice();

    /////////////
    // Getters //
    /////////////

    /**
     * @notice Get the settle twap of a listed underlying token asset
     * @param asset Address of the asset
     * @param expireTime 到期结算时间
     * @return price Price in USDC, with 18 decimals of precision
     */
    function _getSettleTWAP(address asset, uint256 expireTime) internal view returns (uint256) {
        LibSettleTWAPOracle.Layout storage l = LibSettleTWAPOracle.layout();
        LibStrategyConfig.Layout storage cl = LibStrategyConfig.layout();
        if (asset == cl.usdcToken) {
            return 1e18;
        }
        PriceDataItem memory priceData = l.priceData[asset][expireTime];

        if (priceData.price == 0) {
            revert SettleOracle__InvalidPrice();
        }
        return priceData.price;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {Constants} from "../../utils/Constants.sol";
import {TimestampCheck} from "../../utils/TimestampCheck.sol";
import {InvalidStrategy, StrategyIsNotActive} from "../errors/GenericErrors.sol";

library LibStrategyConfig {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.StrategyConfig");

    error OnlyStrategyOwner(address owner, address admin);
    error PositionIdDuplicates(uint256 id);
    error OnlySupportCollateralToken(address token);
    // signature
    error InvalidSignature();
    error SignatureAlreadyUsed(address user);
    // market
    error MarketNotListed();

    struct Layout {
        /// @notice 支持的抵押品
        // mapping(address => bool) isSupportCollateralToken;
        /**
         * @notice Official mapping of cTokens -> Market metadata
         * @dev Used e.g. to determine if a market is supported
         */
        mapping(address => StrategyTypes.Market) markets;
        /// @notice 所有市场的标的资产地址
        address[] allMarkets;
        /// @notice usdc token 地址
        address usdcToken;
        /// @notice weth 地址
        address wrappedNativeToken;
        /// @notice 用户对应的admin nonce，用于生成某个admin唯一的requestHash
        mapping(address => uint256) userNonce;
        mapping(address => mapping(bytes32 => bool)) usedSignatureHash;
        /// @notice 开仓，开仓加腿合并，平仓等请求中需要的参数
        mapping(bytes32 => StrategyTypes.StrategyRequest) userRequestStrategy;
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
    // function _ensureSupportCollateral(address _token) internal view {
    //     if (!LibStrategyConfig.layout().isSupportCollateralToken[_token]) {
    //         revert OnlySupportCollateralToken(_token);
    //     }
    // }

    /// @notice Reverts if the market is not listed
    function _ensureListed(address token) internal view {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();

        if (!l.markets[token].isListed) {
            revert MarketNotListed();
        }
    }

    /// @notice Reverts if the caller is not admin or strategy is not active
    function _ensureAdminAndActive(StrategyTypes.StrategyAllData memory strategy, address _admin) internal pure {
        if (_admin != strategy.owner) {
            revert OnlyStrategyOwner(strategy.owner,_admin);
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

    /// @notice 检查是否可以有可以合并的
    function _validateMergeabilityOfStrategy(StrategyTypes.StrategyRequest memory strategy) internal pure {
        uint256 optionLen = strategy.option.length;
        uint256 futureLen = strategy.option.length;
        address underlying;
        if (optionLen > 0) {
            underlying = strategy.option[0].underlying;
        } else if (futureLen > 0) {
            underlying = strategy.future[0].underlying;
        }
        for (uint256 i; i < optionLen; ) {
            for (uint256 j = i + 1; j < optionLen; ) {
                bool isCanBeMerged = _checkOptionPositionMergeability(
                    strategy.option[i],
                    strategy.option[j],
                    underlying
                );
                // 这里是true表示可以合并的话报错
                if (isCanBeMerged) {
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
                bool isCanBeMerged = _checkFuturePositionMergeability(
                    strategy.future[i],
                    strategy.future[j],
                    underlying
                );
                // 这里是true表示可以合并的话报错
                if (isCanBeMerged) {
                    revert InvalidStrategy();
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice 验证2个角色的策略是否完成相反
    function _validateOppositeStrategies(
        StrategyTypes.StrategyRequest memory makerStrategy,
        StrategyTypes.StrategyRequest memory takerStrategy
    ) internal view returns (bool) {
        uint256 makerOptionLen = makerStrategy.option.length;
        uint256 makerFutureLen = makerStrategy.future.length;
        uint256 takerOptionLen = takerStrategy.option.length;
        uint256 takerFutureLen = takerStrategy.future.length;
        uint256 makerLen = makerOptionLen + makerFutureLen;
        uint256 takerLen = takerOptionLen + takerFutureLen;

        // 验证策略腿数量和期权腿数量（期货腿数量包含在内，无需验证）
        if (makerLen != takerLen || makerOptionLen != takerOptionLen || takerLen > Constants.LEG_LIMIT) {
            return false;
        }

        for (uint256 i; i < makerOptionLen; ) {
            // 验证这个标的资产是否支持
            _ensureListed(makerStrategy.option[i].underlying);
            // 验证期权仓位是否相反 true 表示相反，false表示相同
            bool isOpposite = _isOppositeOptionPosition(makerStrategy.option[i], takerStrategy.option[i]);
            if (!isOpposite) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < makerFutureLen; ) {
            // 验证这个标的资产是否支持
            _ensureListed(makerStrategy.future[i].underlying);
            // 验证期权仓位是否相反
            bool isOpposite = _isOppositeFuturePosition(makerStrategy.future[i], takerStrategy.future[i]);
            if (!isOpposite) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _checkFuturePositionMergeability(
        StrategyTypes.Future memory future1,
        StrategyTypes.Future memory future2,
        address underlying
    ) internal pure returns (bool) {
        if (future1.underlying != underlying) {
            return true;
        }
        bytes32 future1Hash = keccak256(abi.encode(future1.underlying, future1.expiryTime));
        bytes32 future2Hash = keccak256(abi.encode(future2.underlying, future2.expiryTime));
        if (future1Hash == future2Hash) {
            return true;
        }

        // if (!TimestampCheck.isFridayEightAM(future1.expiryTime)) {
        //     return false;
        // }
        return false;
    }

    /// @notice 检查期权仓位数组是否存在可以合并的仓位
    function _checkOptionPositionMergeability(
        StrategyTypes.Option memory option1,
        StrategyTypes.Option memory option2,
        address underlying
    ) internal pure returns (bool) {
        //这里不合并是因为当前版本只支持单策略单币种
        if (option1.underlying != underlying) {
            return false;
        }
        //  premium 需要是相反方向，因此加个“-”符号
        bytes32 option1Hash = keccak256(abi.encode(option1.underlying, option1.strikePrice, option1.expiryTime));
        bytes32 option2Hash = keccak256(abi.encode(option2.underlying, option2.strikePrice, option2.expiryTime));
        //todo 这里还少了一个比较，longcall 和 longcall，shortcall 和 shortcall
        if (option1.optionType == StrategyTypes.OptionType.LONG_CALL) {
            if (option2.optionType != StrategyTypes.OptionType.SHORT_CALL) {
                if (option1Hash == option2Hash) {
                    return true;
                }
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.SHORT_CALL) {
            if (option2.optionType != StrategyTypes.OptionType.LONG_CALL) {
                if (option1Hash == option2Hash) {
                    return true;
                }
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.LONG_PUT) {
            if (option2.optionType != StrategyTypes.OptionType.SHORT_PUT) {
                if (option1Hash == option2Hash) {
                    return true;
                }
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.SHORT_PUT) {
            if (option2.optionType != StrategyTypes.OptionType.LONG_PUT) {
                if (option1Hash == option2Hash) {
                    return true;
                }
            }
        }
        // if (!TimestampCheck.isFridayEightAM(option1.expiryTime)) {
        //     return false;
        // }
        return false;
    }

    // @notice 检查2个角色对应的期权仓位是否完全相反
    function _isOppositeOptionPosition(
        StrategyTypes.Option memory option1,
        StrategyTypes.Option memory option2
    ) internal pure returns (bool) {
        //  premium 需要是相反方向，因此加个“-”符号
        bytes32 option1Hash = keccak256(
            abi.encode(option1.underlying, option1.strikePrice, -option1.premium, option1.size, option1.expiryTime)
        );
        bytes32 option2Hash = keccak256(
            abi.encode(option2.underlying, option2.strikePrice, option2.premium, option2.size, option2.expiryTime)
        );
        if (option1Hash != option2Hash) {
            return false;
        }

        // 2 个 option hash 进行比较了，因此这里无需比较
        //        int256 premium = option1.premium + option2.premium;
        //        if (premium != 0) {
        //            return false;
        //        }
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
        //判断开仓的时间点是不是我们规定的时间点
        if (!TimestampCheck.isFridayEightAM(option1.expiryTime)) {
            return false;
        }
        return true;
    }

    // @notice 检查2个角色对应的期货仓位是否完全相反
    function _isOppositeFuturePosition(
        StrategyTypes.Future memory future1,
        StrategyTypes.Future memory future2
    ) internal pure returns (bool) {
        // 期货方向设置为相反
        bytes32 future1Hash = keccak256(
            abi.encode(future1.underlying, future1.entryPrice, future1.size, future1.expiryTime, future1.isLong)
        );
        bytes32 future2Hash = keccak256(
            abi.encode(future2.underlying, future2.entryPrice, future2.size, future2.expiryTime, !future2.isLong)
        );
        if (future1Hash != future2Hash) {
            return false;
        }
        if (!TimestampCheck.isFridayEightAM(future1.expiryTime)) {
            return false;
        }

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
        l.userRequestStrategy[requestId].owner = _strategy.owner;
        l.userRequestStrategy[requestId].collateralAmount = _strategy.collateralAmount;
        l.userRequestStrategy[requestId].timestamp = _strategy.timestamp;
        l.userRequestStrategy[requestId].mergeId = _strategy.mergeId;
        l.userRequestStrategy[requestId].owner = _strategy.owner;

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
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {LibStrategyConfig} from "./LibStrategyConfig.sol";
import {InvalidAddress} from "../errors/GenericErrors.sol";
import {FixedPoint96, FullMath, TickMath, IUniswapV3Pool} from "../libraries/UniswapLib.sol";

library LibUniTWAPOracle {
    /// @dev Describe how to interpret the fixedPrice in the TokenConfig.
    enum PriceSource {
        FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
    }

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenTWAPConfig object for each supported asset, passed in the constructor.
    struct TokenTWAPConfig {
        // The address of the underlying market token.
        address underlying;
        // Where price is coming from.  Refer to README for more information
        PriceSource priceSource;
        // The number of smallest units of measurement in a single whole unit.
        uint256 baseDecimals;
        // The number of smallest units of measurement in a single whole unit.
        uint256 quoteDecimals;
        // The address of the pool being used as the anchor for this market.
        address uniswapMarket;
        // True if the pair on Uniswap is defined as ETH / X
        bool isUniswapReversed;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.UniTWAPOracle");

    /// @notice The number of wei in 1 ETH
    uint256 public constant ETH_BASE_UNIT = 1e18;

    /// @notice A common scaling factor to maintain precision
    uint256 public constant EXP_SCALE = 1e18;

    error TWAPOracle__TickNotInRange();
    error TWAPOracle__AlreadyInitialized();
    error TWAPOracle__TimeWeightedAverageTickExceedsLimit();

    struct Layout {
        /// @notice The time interval to search for TWAPs when calling the Uniswap V3 observe function
        uint32 anchorPeriod;
        /// @notice Token config by assets
        mapping(address => TokenTWAPConfig) tokenTWAPConfigs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function initialize(uint32 _anchorPeriod) internal {
        LibUniTWAPOracle.Layout storage l = LibUniTWAPOracle.layout();
        if (l.anchorPeriod != 0) {
            revert TWAPOracle__AlreadyInitialized();
        }
        l.anchorPeriod = _anchorPeriod;
    }

    function _getTWAPUniV3(address asset) internal view returns (uint256) {
        LibUniTWAPOracle.Layout storage l = LibUniTWAPOracle.layout();
        TokenTWAPConfig memory config = l.tokenTWAPConfigs[asset];
        uint256 anchorPrice = _calculateAnchorPriceFromEthPrice(config);
        return anchorPrice;
    }

    /**
     * @notice Calculate the anchor price by fetching price data from the TWAP
     * @param config TokenTWAPConfig
     * @return anchorPrice uint
     */
    function _calculateAnchorPriceFromEthPrice(
        TokenTWAPConfig memory config
    ) internal view returns (uint256 anchorPrice) {
        if (config.priceSource == PriceSource.FIXED_ETH) {
            // btc-eth eth-usdc -> btc-usdc
            uint256 ethPrice = _fetchEthPrice();
            anchorPrice = _fetchAnchorPrice(config, ethPrice);
        } else {
            // eth-usdc
            anchorPrice = _fetchAnchorPrice(config, ETH_BASE_UNIT);
        }
    }

    /**
     * @dev Fetches the current eth/usd price from Uniswap, with 18 decimals of precision.
     *  Conversion factor is 1e18 for eth/usdc market, since we decode Uniswap price statically with 18 decimals.
     */
    function _fetchEthPrice() internal view returns (uint256) {
        LibUniTWAPOracle.Layout storage l = LibUniTWAPOracle.layout();
        LibStrategyConfig.Layout storage cl = LibStrategyConfig.layout();
        return _fetchAnchorPrice(l.tokenTWAPConfigs[cl.wrappedNativeToken], ETH_BASE_UNIT);
    }

    /**
     * @dev Fetches the current token/usd price from Uniswap, with 18 decimals of precision.
     * @param conversionFactor 1e18 if seeking the ETH price, and a 18 decimal ETH-USDC price in the case of other assets
     */

    function _fetchAnchorPrice(
        TokenTWAPConfig memory config,
        uint256 conversionFactor
    ) internal view returns (uint256) {
        if (config.underlying == address(0) || config.uniswapMarket == address(0)) {
            revert InvalidAddress(address(this), address(0));
        }
        // `getUniswapTwap(config)`
        //      -> TWAP between the baseUnits of Uniswap pair (scaled to 1e18)
        uint256 twap = _getUniswapTwap(config);

        // `unscaledPriceMantissa * 10^config.baseDecimals / 10^config.quoteDecimals / EXP_SCALE`
        //      -> price of 1 token relative to baseUnit of the other token (scaled to 1)
        uint256 unscaledPriceMantissa = twap * conversionFactor;

        // Adjust twap price decimals
        uint256 anchorPrice = (unscaledPriceMantissa * (10 ** config.baseDecimals)) /
            (10 ** config.quoteDecimals) /
            EXP_SCALE;

        return anchorPrice;
    }

    /**
     * @dev Fetches the latest TWATP from the UniV3 pool oracle, over the last anchor period.
     *      Note that the TWATP (time-weighted average tick-price) is not equivalent to the TWAP,
     *      as ticks are logarithmic. The TWATP returned by this function will usually
     *      be lower than the TWAP.
     */
    function _getUniswapTwap(TokenTWAPConfig memory config) internal view returns (uint256) {
        LibUniTWAPOracle.Layout storage l = LibUniTWAPOracle.layout();
        uint32 anchorPeriod_ = l.anchorPeriod;
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = anchorPeriod_;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(config.uniswapMarket).observe(secondsAgos);

        int56 anchorPeriod__ = int56(uint56(anchorPeriod_));
        int56 timeWeightedAverageTickS56 = (tickCumulatives[1] - tickCumulatives[0]) / anchorPeriod__;
        //        require(
        //            timeWeightedAverageTickS56 >= TickMath.MIN_TICK && timeWeightedAverageTickS56 <= TickMath.MAX_TICK,
        //            "TWAP not in range"
        //        );
        if (timeWeightedAverageTickS56 < TickMath.MIN_TICK || timeWeightedAverageTickS56 > TickMath.MAX_TICK) {
            revert TWAPOracle__TickNotInRange();
        }
        // require(timeWeightedAverageTickS56 < type(int24).max, "timeWeightedAverageTick > max");
        if (timeWeightedAverageTickS56 >= type(int24).max) {
            revert TWAPOracle__TimeWeightedAverageTickExceedsLimit();
        }
        int24 timeWeightedAverageTick = int24(timeWeightedAverageTickS56);
        if (config.isUniswapReversed) {
            // If the reverse price is desired, inverse the tick
            // price = 1.0001^{tick}
            // (price)^{-1} = (1.0001^{tick})^{-1}
            // \frac{1}{price} = 1.0001^{-tick}
            timeWeightedAverageTick = -timeWeightedAverageTick;
        }
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(timeWeightedAverageTick);
        // Squaring the result also squares the Q96 scalar (2**96),
        // so after this mulDiv, the resulting TWAP is still in Q96 fixed precision.
        uint256 twapX96 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);

        // Scale up to a common precision (EXP_SCALE), then down-scale from Q96.
        return FullMath.mulDiv(EXP_SCALE, twapX96, FixedPoint96.Q96);
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

    struct PositionData {
        uint256 positionId;
        AssetType assetType;
        bool isActive;
    }

    struct StrategyData {
        uint256 strategyId;
        // usdc 计价的抵押品余额
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 unsettled;
        int256 realisedPnl;
        uint256[] positionIds;
        bool isActive;
    }

    struct StrategyDataWithOwner {
        uint256 strategyId;
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 unsettled;
        int256 realisedPnl;
        uint256[] positionIds;
        bool isActive;
        address owner;
    }

    struct StrategyAllData {
        uint256 strategyId;
        // usdc 计价的抵押品余额
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 unsettled;
        int256 realisedPnl;
        bool isActive;
        address owner;
        Option[] option;
        Future[] future;
    }

    struct Strategy {
        address owner;
        // usdc 计价的抵押品余额
        uint256 collateralAmount;
        uint256 timestamp;
        int256 realisedPnl;
        // 合并的id：如果为0，表示不合并；有值进行验证并合并
        uint256 mergeId;
        bool isActive;
        Option[] option;
        Future[] future;
    }

    struct DecreaseStrategyCollateralRequest {
        address owner;
        uint256 strategyId;
        uint256 collateralAmount;
    }

    struct MergeStrategyRequest {
        address owner;
        uint256 firstStrategyId;
        uint256 secondStrategyId;
        uint256 collateralAmount;
    }

    struct SpiltStrategyRequest {
        address owner;
        uint256 strategyId;
        uint256[] positionIds;
        uint256 originalCollateralsToTopUpAmount;
        uint256 originalSplitCollateralAmount;
        uint256 newlySplitCollateralAmount;
    }

    struct LiquidateStrategyRequest {
        uint256 strategyId;
        uint256 mergeId;
        uint256 collateralAmount;
        address owner;
        Future[] future;
        Option[] option;
    }

    struct StrategyRequest {
        address owner;
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 mergeId;
        Option[] option;
        Future[] future;
    }

    struct SellStrategyRequest {
        uint256 strategyId;
        uint256 collateralAmount;
        // uint256[] positionIds;
        address receiver;
        address owner;
        Option[] option;
        Future[] future;
    }

    struct ADLStrategyRequest {
        uint256 strategyId;
        uint256 positionId;
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
        int256 futureUnrealizedPnl;
        int256 futurePredictUnrealizedPnl;
        int256 optionValue; // 已有期权价值的盈利或亏损
        int256 optionValueToBeTraded; // 新开期权价值的盈利或亏损
        uint256 updateAt;
    }

    struct MarginItemWithHash {
        bytes32 requestHash;
        uint256 im;
        uint256 mm;
        int256 futureUnrealizedPnl;
        int256 futurePredictUnrealizedPnl;
        int256 optionValue; // 已有期权价值的盈利或亏损
        int256 optionValueToBeTraded; // 新开期权价值的盈利或亏损
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

// From: https://github.com/Uniswap/uniswap-v3-core

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }
}

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
}

interface IUniswapV3Pool {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(
        uint32[] calldata secondsAgos
    ) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

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
    // 0x8227712ef8ad39d0f26f06731ef0df8665eb7ada7f41b1ee089adf3c238862a2
    bytes32 internal constant MONITOR_ROLE = keccak256("MONITOR_ROLE");

    // eip 712 type hash
    // 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f
    bytes32 internal constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // struct type hash
    //keccak256("StrategyRequest(address owner,uint256 collateralAmount,uint256 timestamp,uint256 mergeId,Option[] option,Future[] future)Future(uint256 positionId,address underlying,uint256 entryPrice,uint256 expiryTime,uint256 size,bool isLong,bool isActive)Option(uint256 positionId,address underlying,uint256 strikePrice,int256 premium,uint256 expiryTime,uint256 size,uint256 optionType,bool isActive)");
    bytes32 public constant STRATEGY_REQUEST_TYPE_HASH =
        0xd3064c8ea492a12d694a85b1787ddd3f7037857a3ed1c74415588464b5ce1a21;

    //keccak256("Future(uint256 positionId,address underlying,uint256 entryPrice,uint256 expiryTime,uint256 size,bool isLong,bool isActive)");
    bytes32 public constant FUTURE_TYPE_HASH = 0xcdff66689589cd15845093f3be135b778815fc2b8dfa35ff5112e645191afe86;

    //keccak256("Option(uint256 positionId,address underlying,uint256 strikePrice,int256 premium,uint256 expiryTime,uint256 size,uint256 optionType,bool isActive)");
    bytes32 public constant OPTION_TYPE_HASH = 0xbc63504838568be333400315a4bfe079d052fe27fe59b4bdac11192ccbca3e47;

    // time lock
    uint256 public constant TIME_LOCK_DELAY = 2 hours;
    uint256 public constant TIME_LOCK_GRACE_PERIOD = 12 hours;
    // mark price oracle or margin oracle
    uint256 public constant MAX_SIGNER_NUM = 9;
    // spot price oracle
    uint256 internal constant MIN_BOUND_ANCHOR_RATIO = 0.8e18;
    uint256 internal constant MAX_BOUND_ANCHOR_RATIO = 1.2e18;
    // position core
    uint256 internal constant LEG_LIMIT = 8;

    /// @notice A common scaling factor to maintain precision
    uint256 internal constant EXP_SCALE = 1e18;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

library TimestampCheck {
    function isFridayEightAM(uint256 timestamp) internal pure returns (bool) {
        // 获取当前区块的时间戳
        uint256 currentTimestamp = timestamp;

        // 计算当前时间戳对应的周几（0表示星期天，6表示星期六）
        uint256 currentDay = (currentTimestamp / 1 days + 4) % 7;

        // 计算当前时间戳对应的小时
        uint256 currentHour = (currentTimestamp / 1 hours) % 24;

        // 判断是否为每周五北京时间下午4点
        return currentDay == 5 && currentHour == 8;
    }

    function isDailyEightAM(uint256 timestamp) internal pure returns (bool) {
        // 获取当前区块的时间戳
        uint256 currentTimestamp = timestamp;

        // 计算当前时间戳对应的小时
        uint256 currentHour = (currentTimestamp / 1 hours) % 24;

        // 判断是否为北京时间下午4点
        return currentHour == 8;
    }
}