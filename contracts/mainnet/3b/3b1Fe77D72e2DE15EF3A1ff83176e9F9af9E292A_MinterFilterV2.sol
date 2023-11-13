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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 * ```
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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IAdminACLV0 {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     * @param previousSuperAdmin The previous superAdmin address.
     * @param newSuperAdmin The new superAdmin address.
     * @param genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     */
    event SuperAdminTransferred(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin,
        address[] genArt721CoreAddressesToUpdate
    );

    /// Type of the Admin ACL contract, e.g. "AdminACLV0"
    function AdminACLType() external view returns (string memory);

    /// super admin address
    function superAdmin() external view returns (address);

    /**
     * @notice Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external;

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function renounceOwnershipOn(address _contract) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.0;

import "./IEngineRegistryV0.sol";

interface ICoreRegistryV1 is IEngineRegistryV0 {
    function registerContracts(
        address[] calldata contractAddresses,
        bytes32[] calldata coreVersions,
        bytes32[] calldata coreTypes
    ) external;

    function unregisterContracts(address[] calldata contractAddresses) external;

    function getNumRegisteredContracts() external view returns (uint256);

    function getRegisteredContractAt(
        uint256 index
    ) external view returns (address);

    function isRegisteredContract(
        address contractAddress
    ) external view returns (bool isRegistered);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.0;

interface IEngineRegistryV0 {
    /// ADDRESS
    /**
     * @notice contract has been registered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractRegistered(
        address indexed _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    );

    /// ADDRESS
    /**
     * @notice contract has been unregistered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractUnregistered(address indexed _contractAddress);

    /**
     * @notice Emits a `ContractRegistered` event with the provided information.
     * @dev this function should be gated to only deployer addresses.
     */
    function registerContract(
        address _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    ) external;

    /**
     * @notice Emits a `ContractUnregistered` event with the provided information, validating that the provided
     *         address was indeed previously registered.
     * @dev this function should be gated to only deployer addresses.
     */
    function unregisterContract(address _contractAddress) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
/// use the Royalty Registry's IManifold interface for token royalties
import "./IManifold.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 flagship and derivative implementations.
 * This interface extends the IManifold royalty interface in order to
 * add support the Royalty Registry by default.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Base is IManifold {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     */
    event Mint(address indexed _to, uint256 indexed _tokenId);

    /**
     * @notice currentMinter updated to `_currentMinter`.
     * @dev Implemented starting with V3 core
     */
    event MinterUpdated(address indexed _currentMinter);

    /**
     * @notice Platform updated on bytes32-encoded field `_field`.
     */
    event PlatformUpdated(bytes32 indexed _field);

    /**
     * @notice Project ID `_projectId` updated on bytes32-encoded field
     * `_update`.
     */
    event ProjectUpdated(uint256 indexed _projectId, bytes32 indexed _update);

    event ProposedArtistAddressesAndSplits(
        uint256 indexed _projectId,
        address _artistAddress,
        address _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    );

    event AcceptedArtistAddressesAndSplits(uint256 indexed _projectId);

    // version and type of the core contract
    // coreVersion is a string of the form "0.x.y"
    function coreVersion() external view returns (string memory);

    // coreType is a string of the form "GenArt721CoreV3"
    function coreType() external view returns (string memory);

    // owner (pre-V3 was named admin) of contract
    // this is expected to be an Admin ACL contract for V3
    function owner() external view returns (address);

    // Admin ACL contract for V3, will be at the address owner()
    function adminACLContract() external returns (IAdminACLV0);

    // backwards-compatible (pre-V3) admin - equal to owner()
    function admin() external view returns (address);

    /**
     * Function determining if _sender is allowed to call function with
     * selector _selector on contract `_contract`. Intended to be used with
     * peripheral contracts such as minters, as well as internally by the
     * core contract itself.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);

    /// getter function of public variable
    function startingProjectId() external view returns (uint256);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(
        uint256 tokenId
    ) external view returns (uint256 projectId);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySales(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySalesPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    function projectIdToSecondaryMarketRoyaltyPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    function projectURIInfo(
        uint256 _projectId
    ) external view returns (string memory projectBaseURI);

    // @dev new function in V3
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        );

    function projectDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory projectName,
            string memory artist,
            string memory description,
            string memory website,
            string memory license
        );

    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        );

    function projectScriptByIndex(
        uint256 _projectId,
        uint256 _index
    ) external view returns (string memory);

    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);

    // function to set a token's hash (must be guarded)
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hash) external;

    // @dev gas-optimized signature in V3 for `mint`
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev Royalty Registry interface, used to support the Royalty Registry.
/// @dev Source: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/specs/IManifold.sol

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {
    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(
        uint256 tokenId
    ) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./ICoreRegistryV1.sol";
import "./IAdminACLV0.sol";

/**
 * @title IMinterFilterV1
 * @author Art Blocks Inc.
 * @notice Interface for a new minter filter contract.
 * This interface does not extend the previous version of the minter filter
 * interface, as the previous version is not compatible with the new
 * minter filter architecture.
 * @dev This interface is for a minter filter that supports multiple core
 * contracts, and allows for a minter to be set on a per-project basis.
 */
interface IMinterFilterV1 {
    /**
     * @notice Emitted when contract is deployed to notify indexing services
     * of the new contract deployment.
     */
    event Deployed();

    /**
     * @notice Globally approved minter `minter`.
     */
    event MinterApprovedGlobally(address indexed minter, string minterType);

    /**
     * @notice Globally revoked minter `minter`.
     * @dev contract owner may still approve this minter on a per-contract
     * basis.
     */
    event MinterRevokedGlobally(address indexed minter);

    /**
     * @notice Approved minter `minter` on core contract
     * `coreContract`.
     */
    event MinterApprovedForContract(
        address indexed coreContract,
        address indexed minter,
        string minterType
    );

    /**
     * @notice Revoked minter `minter` on core contract `coreContract`.
     * @dev minter filter owner may still globally approve this minter for all
     * contracts.
     */
    event MinterRevokedForContract(
        address indexed coreContract,
        address indexed minter
    );

    /**
     * @notice Minter at address `minter` set as minter for project
     * `projectId` on core contract `coreContract`.
     */
    event ProjectMinterRegistered(
        uint256 indexed projectId,
        address indexed coreContract,
        address indexed minter,
        string minterType
    );

    /**
     * @notice Minter removed for project `projectId` on core contract
     * `coreContract`.
     */
    event ProjectMinterRemoved(
        uint256 indexed projectId,
        address indexed coreContract
    );

    /**
     * @notice Admin ACL contract updated to `adminACLContract`.
     */
    event AdminACLUpdated(address indexed adminACLContract);

    /**
     * @notice Core Registry contract updated to `coreRegistry`.
     */
    event CoreRegistryUpdated(address indexed coreRegistry);

    // struct used to return minter info
    // @dev this is not used for storage of data
    struct MinterWithType {
        address minterAddress;
        string minterType;
    }

    function setMinterForProject(
        uint256 projectId,
        address coreContract,
        address minter
    ) external;

    function removeMinterForProject(
        uint256 projectId,
        address coreContract
    ) external;

    // @dev function name is optimized for gas
    function mint_joo(
        address to,
        uint256 projectId,
        address coreContract,
        address sender
    ) external returns (uint256);

    function updateCoreRegistry(address coreRegistry) external;

    /**
     * @notice Returns if `sender` is allowed to call function on `contract`
     * with `selector` selector, according to the MinterFilter's Admin ACL.
     */
    function adminACLAllowed(
        address sender,
        address contract_,
        bytes4 selector
    ) external returns (bool);

    function minterFilterType() external pure returns (string memory);

    function getMinterForProject(
        uint256 projectId,
        address coreContract
    ) external view returns (address);

    function projectHasMinter(
        uint256 projectId,
        address coreContract
    ) external view returns (bool);

    /**
     * @notice View that returns if a core contract is registered with the
     * core registry, allowing this minter filter to service it.
     * @param coreContract core contract address to be checked
     */
    function isRegisteredCoreContract(
        address coreContract
    ) external view returns (bool);

    /// Address of current core registry contract
    function coreRegistry() external view returns (ICoreRegistryV1);

    /// The current admin ACL contract
    function adminACLContract() external view returns (IAdminACLV0);

    /// The quantity of projects on a core contract that have assigned minters
    function getNumProjectsOnContractWithMinters(
        address coreContract
    ) external view returns (uint256);

    function getProjectAndMinterInfoOnContractAt(
        address coreContract,
        uint256 index
    )
        external
        view
        returns (
            uint256 projectId,
            address minterAddress,
            string memory minterType
        );

    function getAllGloballyApprovedMinters()
        external
        view
        returns (MinterWithType[] memory mintersWithTypes);

    function getAllContractApprovedMinters(
        address coreContract
    ) external view returns (MinterWithType[] memory mintersWithTypes);

    /**
     * Owner of contract.
     * @dev This returns the address of the Admin ACL contract.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface ISharedMinterV0 {
    // Sets the local max invocations for a given project, checking that the provided max invocations is
    // less than or equal to the global max invocations for the project set on the core contract.
    // This does not impact the max invocations value defined on the core contract.
    function manuallyLimitProjectMaxInvocations(
        uint256 projectId,
        address coreContract,
        uint24 maxInvocations
    ) external;

    // Called to make the minter contract aware of the max invocations for a
    // given project.
    function syncProjectMaxInvocationsToCore(
        uint256 projectId,
        address coreContract
    ) external;

    // getter function of public variable
    function minterType() external view returns (string memory);

    function minterFilterAddress() external returns (address);

    // Gets if token price is configured, token price in wei, currency symbol,
    // and currency address, assuming this is project's minter.
    // Supersedes any defined core price.
    function getPriceInfo(
        uint256 projectId,
        address coreContract
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
// Inspired by: https://ethereum.stackexchange.com/a/123950/103422

pragma solidity ^0.8.0;

/**
 * @dev Operations on bytes32 data type, dealing with conversion to string.
 */
library Bytes32Strings {
    /**
     * @notice Intended to convert a `bytes32`-encoded string literal to `string`.
     * Trims zero padding to arrive at original string literal.
     */
    function toString(
        bytes32 source
    ) internal pure returns (string memory result) {
        uint8 length;
        while (source[length] != 0 && length < 32) {
            length++;
        }
        assembly {
            // free memory pointer
            result := mload(0x40)
            // update free memory pointer to new "memory end"
            // (offset is 64-bytes: 32 for length, 32 for data)
            mstore(0x40, add(result, 0x40))
            // store length in first 32-byte memory slot
            mstore(result, length)
            // write actual data in second 32-byte memory slot
            mstore(add(result, 0x20), source)
        }
    }

    /**
     * @notice Intended to check if a `bytes32`-encoded string contains a given
     * character with UTF-8 character code `utf8CharCode exactly `targetQty`
     * times. Does not support searching for multi-byte characters, only
     * characters with UTF-8 character codes < 0x80.
     */
    function containsExactCharacterQty(
        bytes32 source,
        uint8 utf8CharCode,
        uint8 targetQty
    ) internal pure returns (bool) {
        uint8 _occurrences;
        uint8 i;
        for (i; i < 32; ) {
            uint8 _charCode = uint8(source[i]);
            // if not a null byte, or a multi-byte UTF-8 character, check match
            if (_charCode != 0 && _charCode < 0x80) {
                if (_charCode == utf8CharCode) {
                    unchecked {
                        // no risk of overflow since max 32 iterations < max uin8=255
                        ++_occurrences;
                    }
                }
            }
            unchecked {
                // no risk of overflow since max 32 iterations < max uin8=255
                ++i;
            }
        }
        return _occurrences == targetQty;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

// @dev fixed to specific solidity version for clarity and for more clear
// source code verification purposes.
pragma solidity 0.8.19;

import {IMinterFilterV1} from "../../interfaces/v0.8.x/IMinterFilterV1.sol";
import {ISharedMinterV0} from "../../interfaces/v0.8.x/ISharedMinterV0.sol";
import {IGenArt721CoreContractV3_Base} from "../../interfaces/v0.8.x/IGenArt721CoreContractV3_Base.sol";
import {ICoreRegistryV1} from "../../interfaces/v0.8.x/ICoreRegistryV1.sol";
import {IAdminACLV0} from "../../interfaces/v0.8.x/IAdminACLV0.sol";

import {Bytes32Strings} from "../../libs/v0.8.x/Bytes32Strings.sol";

import {Ownable} from "@openzeppelin-4.7/contracts/access/Ownable.sol";
import {EnumerableMap} from "@openzeppelin-4.7/contracts/utils/structs/EnumerableMap.sol";
import {EnumerableSet} from "@openzeppelin-4.7/contracts/utils/structs/EnumerableSet.sol";
import {Math} from "@openzeppelin-4.7/contracts/utils/math/Math.sol";

/**
 * @title MinterFilterV2
 * @dev At the time of deployment, this contract is intended to be used with
 * core contracts that implement IGenArt721CoreContractV3_Base.
 * @author Art Blocks Inc.
 * @notice This Minter Filter V2 contract allows minters to be set on a
 * per-project basis, for any registered core contract. This minter filter does
 * not extend the previous version of the minter filters, as the previous
 * version is not compatible with multiple core contracts.
 *
 * This contract is designed to be managed by an Admin ACL contract, as well as
 * delegated privileges to core contract artists and Admin ACL contracts.
 * These roles hold extensive power and can arbitrarily control and modify
 * how a project's tokens may be minted.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * ----------------------------------------------------------------------------
 * The following functions are restricted as allowed by this contract's Admin
 * ACL:
 * - updateCoreRegistry
 * - approveMinterGlobally
 * - revokeMinterGlobally
 * ----------------------------------------------------------------------------
 * The following functions are restricted as allowed by each core contract's
 * Admin ACL contract:
 * - approveMinterForContract
 * - revokeMinterForContract
 * - removeMintersForProjectsOnContract
 * ----------------------------------------------------------------------------
 * The following functions are restricted as allowed by each core contract's
 * Admin ACL contract, or to the artist address of the project:
 * - setMinterForProject
 * - removeMinterForProject
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on minters,
 * registries, and other contracts that may interact with this contract.
 */
contract MinterFilterV2 is Ownable, IMinterFilterV1 {
    // add Enumerable Map, Enumerable Set methods
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.AddressSet;
    // add Bytes32Strings methods
    using Bytes32Strings for bytes32;

    /// @notice Version of this minter filter contract
    // @dev use function minterFilterVersion to get this as a string
    bytes32 constant MINTER_FILTER_VERSION = "v2.0.0";

    /// @notice Type of this minter filter contract
    // @dev use function minterFilterType to get this as a string
    bytes32 constant MINTER_FILTER_TYPE = "MinterFilterV2";

    /// @notice Admin ACL contract for this minter filter
    IAdminACLV0 public adminACLContract;

    /**
     * @notice Core registry, that tracks all registered core contracts
     */
    ICoreRegistryV1 public coreRegistry;

    /// @notice Minter address => qty projects across all core contracts currently
    /// using the minter
    mapping(address minterAddress => uint256 numProjects)
        public numProjectsUsingMinter;

    /**
     * @notice Enumerable Set of globally approved minters.
     * This is a Set of addresses that are approved to mint on any
     * project, for any core contract.
     * @dev note that contract admins can extend a separate Set of minters for
     * their core contract via the `approveMinterForContract` function.
     */
    EnumerableSet.AddressSet private _globallyApprovedMinters;

    /**
     * @notice Mapping of core contract addresses to Enumerable Sets of approved
     * minters for that core contract.
     * @dev note that contract admins can extend this Set for their core
     * contract by via the `approveMinterForContract` function, and can remove
     * minters from this Set via the `revokeMinterForContract` function.
     */
    mapping(address coreContract => EnumerableSet.AddressSet approvedMintersForContract)
        private _contractApprovedMinters;

    /**
     * @notice Mapping of core contract addresses to Enumerable Maps of project IDs to
     * minter addresses.
     */
    mapping(address coreContract => EnumerableMap.UintToAddressMap projectIdToMinterAddress)
        private _minterForProject;

    /**
     * @notice Function to validate an address is non-zero.
     * @param address_ Address to validate
     */
    function _onlyNonZeroAddress(address address_) internal pure {
        require(address_ != address(0), "Only non-zero address");
    }

    /**
     * @notice Function to restrict access to only AdminACL allowed calls
     * on this minter filter's admin ACL contract.
     * @param selector function selector to be checked
     */
    function _onlyAdminACL(bytes4 selector) internal {
        require(
            adminACLAllowed(msg.sender, address(this), selector),
            "Only Admin ACL allowed"
        );
    }

    /**
     * @notice Function to restrict access to only AdminACL allowed calls
     * on a given core contract.
     * @dev defers to the ACL contract used by the core contract
     * @param coreContract core contract address
     * @param selector function selector to be checked
     */
    function _onlyCoreAdminACL(address coreContract, bytes4 selector) internal {
        require(
            IGenArt721CoreContractV3_Base(coreContract).adminACLAllowed({
                _sender: msg.sender,
                _contract: address(this),
                _selector: selector
            }),
            "Only Core AdminACL allowed"
        );
    }

    /**
     * @notice Function to restrict access to only core AdminACL or the project artist.
     * @dev Defers to the ACL contract used by the core contract
     * @param coreContract core contract address
     * @param selector function selector to be checked
     */
    function _onlyCoreAdminACLOrArtist(
        uint256 projectId,
        address coreContract,
        bytes4 selector
    ) internal {
        IGenArt721CoreContractV3_Base genArtCoreContract_Base = IGenArt721CoreContractV3_Base(
                coreContract
            );
        require(
            (msg.sender ==
                genArtCoreContract_Base.projectIdToArtistAddress(projectId)) ||
                (
                    genArtCoreContract_Base.adminACLAllowed({
                        _sender: msg.sender,
                        _contract: address(this),
                        _selector: selector
                    })
                ),
            "Only Artist or Core Admin ACL"
        );
    }

    /**
     * @notice Function to restrict access to only core contracts registered with the
     * currently configured core registry. This is used to prevent non-registered core
     * contracts from being used with this minter filter.
     * @param coreContract core contract address
     */
    function _onlyRegisteredCoreContract(address coreContract) internal view {
        // @dev use core registry to check if core contract is registered
        require(
            coreRegistry.isRegisteredContract(coreContract),
            "Only registered core contract"
        );
    }

    /**
     * @notice Function to restrict access to only valid project IDs.
     * @param projectId Project ID to validate.
     * @param coreContract core contract address
     */
    function _onlyValidProjectId(
        uint256 projectId,
        address coreContract
    ) internal view {
        IGenArt721CoreContractV3_Base genArtCoreContract = IGenArt721CoreContractV3_Base(
                coreContract
            );
        require(
            (projectId >= genArtCoreContract.startingProjectId()) &&
                (projectId < genArtCoreContract.nextProjectId()),
            "Only valid project ID"
        );
    }

    /**
     * @notice Function to check if minter is globally approved or approved for a core contract.
     * @param coreContract core contract address
     * @param minter Minter to validate.
     */
    function _onlyApprovedMinter(
        address coreContract,
        address minter
    ) internal view {
        require(
            isApprovedMinterForContract({
                coreContract: coreContract,
                minter: minter
            }),
            "Only approved minters"
        );
    }

    /**
     * @notice Initializes contract to be a Minter for `genArt721Address`.
     * @param adminACLContract_ Address of admin access control contract, to be
     * set as contract owner.
     * @param coreRegistry_ Address of core registry contract.
     */
    constructor(address adminACLContract_, address coreRegistry_) {
        // set AdminACL management contract as owner
        _transferOwnership(adminACLContract_);
        // set core registry contract
        _updateCoreRegistry(coreRegistry_);
        emit Deployed();
    }

    /**
     * @notice returns the version of this minter filter contract
     */
    function minterFilterVersion() external pure returns (string memory) {
        return MINTER_FILTER_VERSION.toString();
    }

    /**
     * @notice returns the type of this minter filter contract
     */
    function minterFilterType() external pure returns (string memory) {
        return MINTER_FILTER_TYPE.toString();
    }

    /**
     * @notice Updates the core registry contract to be used by this contract.
     * Only callable as allowed by AdminACL of this contract.
     * @param coreRegistry_ Address of the new core registry contract.
     */
    function updateCoreRegistry(address coreRegistry_) external {
        _onlyAdminACL(this.updateCoreRegistry.selector);
        _updateCoreRegistry(coreRegistry_);
    }

    /**
     * @notice Globally approves minter `minter` to be available for
     * minting on any project, for any core contract.
     * Only callable as allowed by AdminACL of this contract.
     * @dev Reverts if minter is already globally approved, or does not
     * implement minterType().
     * @param minter Minter to be approved.
     */
    function approveMinterGlobally(address minter) external {
        _onlyAdminACL(this.approveMinterGlobally.selector);
        // @dev add() return true if the value was added to the set
        require(
            _globallyApprovedMinters.add(minter),
            "Minter already approved"
        );
        emit MinterApprovedGlobally({
            minter: minter,
            minterType: ISharedMinterV0(minter).minterType()
        });
    }

    /**
     * @notice Removes previously globally approved minter `minter`
     * from the list of globally approved minters.
     * Only callable as allowed by AdminACL of this contract.
     * Reverts if minter is not globally approved.
     * @dev intentionally do not check if minter is still in use by any
     * project, meaning that any projects currently using the minter will
     * continue to be able to use it. If existing projects should be forced
     * to discontinue using a minter, the minter may be removed by the minter
     * filter admin in bulk via the `removeMintersForProjectsOnContract`
     * function.
     * @param minter Minter to remove.
     */
    function revokeMinterGlobally(address minter) external {
        _onlyAdminACL(this.revokeMinterGlobally.selector);
        // @dev remove() returns true only if the value was already in the Set
        require(
            _globallyApprovedMinters.remove(minter),
            "Only previously approved minter"
        );
        emit MinterRevokedGlobally(minter);
    }

    /**
     * @notice Approves minter `minter` to be available for minting on
     * any project on core contarct `coreContract`.
     * Only callable as allowed by AdminACL of core contract `coreContract`.
     * Reverts if core contract is not registered, if minter is already
     * approved for the contract, or if minter does not implement minterType().
     * @param coreContract Core contract to approve minter for.
     * @param minter Minter to be approved.
     */
    function approveMinterForContract(
        address coreContract,
        address minter
    ) external {
        _onlyRegisteredCoreContract(coreContract);
        _onlyCoreAdminACL({
            coreContract: coreContract,
            selector: this.approveMinterForContract.selector
        });
        // @dev add() returns true if the value was added to the Set
        require(
            _contractApprovedMinters[coreContract].add(minter),
            "Minter already approved"
        );
        emit MinterApprovedForContract({
            coreContract: coreContract,
            minter: minter,
            minterType: ISharedMinterV0(minter).minterType()
        });
    }

    /**
     * @notice Removes previously approved minter `minter` from the
     * list of approved minters on core contract `coreContract`.
     * Only callable as allowed by AdminACL of core contract `coreContract`.
     * Reverts if core contract is not registered, or if minter is not approved
     * on contract.
     * @dev intentionally does not check if minter is still in use by any
     * project, meaning that any projects currently using the minter will
     * continue to be able to use it. If existing projects should be forced
     * to discontinue using a minter, the minter may be removed by the contract
     * admin in bulk via the `removeMintersForProjectsOnContract` function.
     * @param coreContract Core contract to remove minter from.
     * @param minter Minter to remove.
     */
    function revokeMinterForContract(
        address coreContract,
        address minter
    ) external {
        _onlyRegisteredCoreContract(coreContract);
        _onlyCoreAdminACL({
            coreContract: coreContract,
            selector: this.revokeMinterForContract.selector
        });
        // @dev intentionally do not check if minter is still in use by any
        // project, since it is possible that a different contract's project is
        // using the minter
        // @dev remove() returns true only if the value was already in the Set
        require(
            _contractApprovedMinters[coreContract].remove(minter),
            "Only previously approved minter"
        );
        emit MinterRevokedForContract({
            coreContract: coreContract,
            minter: minter
        });
    }

    /**
     * @notice Sets minter for project `projectId` on contract `coreContract`
     * to minter `minter`.
     * Only callable by the project's artist or as allowed by AdminACL of
     * core contract `coreContract`.
     * Reverts if:
     *  - core contract is not registered
     *  - minter is not approved globally on this minter filter or for the
     *    project's core contract
     *  - project is not valid on the core contract
     *  - function is called by an address other than the project's artist
     *    or a sender allowed by the core contract's admin ACL
     *  - minter does not implement minterType()
     * @param projectId Project ID to set minter for.
     * @param coreContract Core contract of project.
     * @param minter Minter to be the project's minter.
     */
    function setMinterForProject(
        uint256 projectId,
        address coreContract,
        address minter
    ) external {
        /// CHECKS
        _onlyRegisteredCoreContract(coreContract);
        _onlyCoreAdminACLOrArtist({
            projectId: projectId,
            coreContract: coreContract,
            selector: this.setMinterForProject.selector
        });
        _onlyApprovedMinter({coreContract: coreContract, minter: minter});
        _onlyValidProjectId({projectId: projectId, coreContract: coreContract});
        /// EFFECTS
        // decrement number of projects using a previous minter
        (bool hasPreviousMinter, address previousMinter) = _minterForProject[
            coreContract
        ].tryGet(projectId);
        if (hasPreviousMinter) {
            numProjectsUsingMinter[previousMinter]--;
        }
        // assign new minter
        numProjectsUsingMinter[minter]++;
        _minterForProject[coreContract].set(projectId, minter);
        emit ProjectMinterRegistered({
            projectId: projectId,
            coreContract: coreContract,
            minter: minter,
            minterType: ISharedMinterV0(minter).minterType()
        });
    }

    /**
     * @notice Updates project `projectId` on contract `coreContract` to have
     * no configured minter.
     * Only callable by the project's artist or as allowed by AdminACL of
     * core contract `coreContract`.
     * Reverts if:
     *  - core contract is not registered
     *  - project does not already have a minter assigned
     *  - function is called by an address other than the project's artist
     *    or a sender allowed by the core contract's admin ACL
     * @param projectId Project ID to remove minter for.
     * @param coreContract Core contract of project.
     * @dev requires project to have an assigned minter
     */
    function removeMinterForProject(
        uint256 projectId,
        address coreContract
    ) external {
        _onlyRegisteredCoreContract(coreContract);
        _onlyCoreAdminACLOrArtist({
            projectId: projectId,
            coreContract: coreContract,
            selector: this.removeMinterForProject.selector
        });
        // @dev this will revert if project does not have a minter
        _removeMinterForProject({
            projectId: projectId,
            coreContract: coreContract
        });
    }

    /**
     * @notice Updates an array of project IDs to have no configured minter.
     * Only callable as allowed by AdminACL of core contract `coreContract`.
     * Reverts if the core contract is not registered, or if any project does
     * not already have a minter assigned.
     * @param projectIds Array of project IDs to remove minters for.
     * @param coreContract Core contract of projects.
     * @dev caution with respect to single tx gas limits
     */
    function removeMintersForProjectsOnContract(
        uint256[] calldata projectIds,
        address coreContract
    ) external {
        _onlyRegisteredCoreContract(coreContract);
        _onlyCoreAdminACL({
            coreContract: coreContract,
            selector: this.removeMintersForProjectsOnContract.selector
        });
        uint256 numProjects = projectIds.length;
        for (uint256 i; i < numProjects; ) {
            _removeMinterForProject({
                projectId: projectIds[i],
                coreContract: coreContract
            });
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Mint a token from project `projectId` on contract
     * `coreContract` to `to`, originally purchased by `sender`.
     * @param to The new token's owner.
     * @param projectId Project ID to mint a new token on.
     * @param sender Address purchasing a new token.
     * @param coreContract Core contract of project.
     * @return tokenId Token ID of minted token
     * @dev reverts w/nonexistent key error when project has no assigned minter
     * @dev does not check if core contract is registered, for gas efficiency
     * and because project must have already been assigned a minter, which
     * requires the core contract to have been previously registered. If core
     * contract was unregistered but the project still has an assigned minter,
     * minting will remain possible.
     * @dev function name is optimized for gas.
     */
    function mint_joo(
        address to,
        uint256 projectId,
        address coreContract,
        address sender
    ) external returns (uint256 tokenId) {
        // CHECKS
        // minter is the project's minter
        require(
            msg.sender == _minterForProject[coreContract].get(projectId),
            "Only assigned minter"
        );
        // INTERACTIONS
        tokenId = IGenArt721CoreContractV3_Base(coreContract).mint_Ecf({
            _to: to,
            _projectId: projectId,
            _by: sender
        });
        return tokenId;
    }

    /**
     * @notice Gets the assigned minter for project `projectId` on core
     * contract `coreContract`.
     * Reverts if project does not have an assigned minter.
     * @param projectId Project ID to query.
     * @param coreContract Core contract of project.
     * @return address Minter address assigned to project
     * @dev requires project to have an assigned minter
     * @dev this function intentionally does not check that the core contract
     * is registered, since it must have been registered at the time the
     * project was assigned a minter
     */
    function getMinterForProject(
        uint256 projectId,
        address coreContract
    ) external view returns (address) {
        // @dev use tryGet to control revert message if no minter assigned
        (bool hasMinter, address currentMinter) = _minterForProject[
            coreContract
        ].tryGet(projectId);
        require(hasMinter, "No minter assigned");
        return currentMinter;
    }

    /**
     * @notice Queries if project `projectId` on core contract `coreContract`
     * has an assigned minter.
     * @param projectId Project ID to query.
     * @param coreContract Core contract of project.
     * @return bool true if project has an assigned minter, else false
     * @dev requires project to have an assigned minter
     * @dev this function intentionally does not check that the core contract
     * is registered, since it must have been registered at the time the
     * project was assigned a minter
     */
    function projectHasMinter(
        uint256 projectId,
        address coreContract
    ) external view returns (bool) {
        (bool hasMinter, ) = _minterForProject[coreContract].tryGet(projectId);
        return hasMinter;
    }

    /**
     * @notice Gets quantity of projects on a given core contract that have
     * assigned minters.
     * @param coreContract Core contract to query.
     * @return uint256 quantity of projects that have assigned minters
     * @dev this function intentionally does not check that the core contract
     * is registered, since it must have been registered at the time the
     * project was assigned a minter
     */
    function getNumProjectsOnContractWithMinters(
        address coreContract
    ) external view returns (uint256) {
        return _minterForProject[coreContract].length();
    }

    /**
     * @notice Get project ID and minter address at index `index` of
     * enumerable map.
     * @param coreContract Core contract to query.
     * @param index enumerable map index to query.
     * @return projectId project ID at index `index`
     * @return minterAddress minter address for project at index `index`
     * @return minterType minter type of minter at minterAddress
     * @dev index must be < quantity of projects that have assigned minters,
     * otherwise reverts
     * @dev reverts if minter does not implement minterType() function
     * @dev this function intentionally does not check that the core contract
     * is registered, since it must have been registered at the time the
     * project was assigned a minter
     */
    function getProjectAndMinterInfoOnContractAt(
        address coreContract,
        uint256 index
    )
        external
        view
        returns (
            uint256 projectId,
            address minterAddress,
            string memory minterType
        )
    {
        // @dev at() reverts if index is out of bounds
        (projectId, minterAddress) = _minterForProject[coreContract].at(index);
        minterType = ISharedMinterV0(minterAddress).minterType();
    }

    /**
     * @notice View that returns if a core contract is registered with the
     * core registry, allowing this minter filter to service it.
     * @param coreContract core contract address to be checked
     * @return bool true if core contract is registered, else false
     */
    function isRegisteredCoreContract(
        address coreContract
    ) external view override returns (bool) {
        return coreRegistry.isRegisteredContract(coreContract);
    }

    /**
     * @notice Gets all projects on core contract `coreContract` that are
     * using minter `minter`.
     * Warning: Unbounded gas limit. This function is gas-intensive and should
     * only be used for off-chain queries. Alternatively, the subgraph indexing
     * layer may be used to query these values.
     * @param coreContract core contract to query
     * @param minter minter to query
     */
    function getProjectsOnContractUsingMinter(
        address coreContract,
        address minter
    ) external view returns (uint256[] memory projectIds) {
        EnumerableMap.UintToAddressMap storage minterMap = _minterForProject[
            coreContract
        ];
        // initialize arrays with maximum potential length
        // @dev use lesser of num projects using minter across all contracts
        // and number of projects on the contract with minters assigned, since
        // both values represent an upper bound on the number of projects that
        // could be using the minter on the contract
        uint256 maxNumProjects = Math.min(
            numProjectsUsingMinter[minter],
            minterMap.length()
        );
        projectIds = new uint256[](maxNumProjects);
        // iterate over all projects on contract, adding to array if using
        // `minter`
        uint256 numProjects = minterMap.length();
        uint256 numProjectsOnContractUsingMinter;
        for (uint256 i; i < numProjects; ) {
            (uint256 projectId, address minter_) = minterMap.at(i);
            unchecked {
                if (minter_ == minter) {
                    projectIds[numProjectsOnContractUsingMinter++] = projectId;
                }
                ++i;
            }
        }
        // trim array if necessary
        if (maxNumProjects > numProjectsOnContractUsingMinter) {
            assembly ("memory-safe") {
                mstore(projectIds, numProjectsOnContractUsingMinter)
            }
        }
        return projectIds;
    }

    /**
     * @notice Gets all minters that are globally approved on this minter
     * filter. Returns an array of MinterWithType structs, which contain the
     * minter address and minter type.
     * This function has unbounded gas, and should only be used for off-chain
     * queries.
     * Alternatively, the subgraph indexing layer may be used to query these
     * values.
     * @return mintersWithTypes Array of MinterWithType structs, which contain
     * the minter address and minter type.
     */
    function getAllGloballyApprovedMinters()
        external
        view
        returns (MinterWithType[] memory mintersWithTypes)
    {
        // initialize arrays with appropriate length
        uint256 numMinters = _globallyApprovedMinters.length();
        mintersWithTypes = new MinterWithType[](numMinters);
        // iterate over all globally approved minters, adding to array
        for (uint256 i; i < numMinters; ) {
            address minterAddress = _globallyApprovedMinters.at(i);
            // @dev we know minterType() does not revert, because it was called
            // when globally approving the minter
            string memory minterType = ISharedMinterV0(minterAddress)
                .minterType();
            mintersWithTypes[i] = MinterWithType({
                minterAddress: minterAddress,
                minterType: minterType
            });
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Gets all minters that are approved for a specific core contract.
     * Returns an array of MinterWithType structs, which contain the minter
     * address and minter type.
     * This function has unbounded gas, and should only be used for off-chain
     * queries.
     * @param coreContract Core contract to query.
     * @return mintersWithTypes Array of MinterWithType structs, which contain
     * the minter address and minter type.
     */
    function getAllContractApprovedMinters(
        address coreContract
    ) external view returns (MinterWithType[] memory mintersWithTypes) {
        // initialize arrays with appropriate length
        EnumerableSet.AddressSet
            storage contractApprovedMinters = _contractApprovedMinters[
                coreContract
            ];
        uint256 numMinters = contractApprovedMinters.length();
        mintersWithTypes = new MinterWithType[](numMinters);
        // iterate over all minters approved for a given contract, adding to
        // array
        for (uint256 i; i < numMinters; ) {
            address minterAddress = contractApprovedMinters.at(i);
            // @dev we know minterType() does not revert, because it was called
            // when approving the minter for a contract
            string memory minterType = ISharedMinterV0(minterAddress)
                .minterType();
            mintersWithTypes[i] = MinterWithType({
                minterAddress: minterAddress,
                minterType: minterType
            });
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Convenience function that returns whether `sender` is allowed
     * to call function with selector `selector` on contract `contract`, as
     * determined by this contract's current Admin ACL contract. Expected use
     * cases include minter contracts checking if caller is allowed to call
     * admin-gated functions on minter contracts.
     * @param sender Address of the sender calling function with selector
     * `selector` on contract `contract`.
     * @param contract_ Address of the contract being called by `sender`.
     * @param selector Function selector of the function being called by
     * `sender`.
     * @return bool Whether `sender` is allowed to call function with selector
     * `selector` on contract `contract`.
     * @dev assumes the Admin ACL contract is the owner of this contract, which
     * is expected to always be true.
     * @dev adminACLContract is expected to not be null address (owner cannot
     * renounce ownership on this contract), and conform to IAdminACLV0
     * interface.
     */
    function adminACLAllowed(
        address sender,
        address contract_,
        bytes4 selector
    ) public returns (bool) {
        return
            adminACLContract.allowed({
                _sender: sender,
                _contract: contract_,
                _selector: selector
            });
    }

    /**
     * @notice Returns whether `minter` is globally approved to mint tokens
     * on any contract.
     * @param minter Address of minter to check.
     */
    function isGloballyApprovedMinter(
        address minter
    ) public view returns (bool) {
        return _globallyApprovedMinters.contains(minter);
    }

    /**
     * @notice Returns whether `minter` is approved to mint tokens on
     * core contract `coreContract`.
     * @param coreContract Address of core contract to check.
     * @param minter Address of minter to check.
     */
    function isApprovedMinterForContract(
        address coreContract,
        address minter
    ) public view returns (bool) {
        return
            isGloballyApprovedMinter(minter) ||
            _contractApprovedMinters[coreContract].contains(minter);
    }

    /**
     * @notice Returns contract owner. Set to deployer's address by default on
     * contract deployment.
     * @return address Address of contract owner.
     * @dev ref: https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
     * @dev owner role was called `admin` prior to V3 core contract
     */
    function owner()
        public
        view
        override(Ownable, IMinterFilterV1)
        returns (address)
    {
        return Ownable.owner();
    }

    /// @dev override to prevent renouncing ownership
    /// @dev not permission gated since this immediately reverts
    function renounceOwnership() public pure override {
        revert("Cannot renounce ownership");
    }

    /**
     * @notice Updates project `projectId` to have no configured minter
     * Reverts if project does not already have an assigned minter.
     * @param projectId Project ID to remove minter.
     * @param coreContract Core contract of project.
     * @dev requires project to have an assigned minter
     * @dev this function intentionally does not check that the core contract
     * is registered, since it must have been registered at the time the
     * project was assigned a minter
     */
    function _removeMinterForProject(
        uint256 projectId,
        address coreContract
    ) internal {
        // remove minter for project and emit
        // @dev `minterForProject.get()` reverts tx if no minter set for project
        numProjectsUsingMinter[
            _minterForProject[coreContract].get(projectId, "No minter assigned")
        ]--;
        _minterForProject[coreContract].remove(projectId);
        emit ProjectMinterRemoved({
            projectId: projectId,
            coreContract: coreContract
        });
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`owner`).
     * Internal function without access restriction.
     * @param owner_ New owner.
     * @dev owner role was called `admin` prior to V3 core contract.
     * @dev Overrides and wraps OpenZeppelin's _transferOwnership function to
     * also update adminACLContract for improved introspection.
     */
    function _transferOwnership(address owner_) internal override {
        Ownable._transferOwnership(owner_);
        adminACLContract = IAdminACLV0(owner_);
    }

    /**
     * @notice Updates this contract's core registry contract to
     * `coreRegistry`.
     * @param coreRegistry_ New core registry contract address.
     */
    function _updateCoreRegistry(address coreRegistry_) internal {
        _onlyNonZeroAddress(coreRegistry_);
        coreRegistry = ICoreRegistryV1(coreRegistry_);
        emit CoreRegistryUpdated(coreRegistry_);
    }
}