// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

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
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
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
     * @dev Tries to returns the value associated with `key`. O(1).
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
     * @dev Returns the value associated with `key`. O(1).
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
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
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
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
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
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
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
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
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
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
struct ActionInfo {
  uint16 actionId;
  address latest;
  address[] whitelist;
  address[] blacklist;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import '@openzeppelin/contracts/utils/structs/EnumerableMap.sol';

import './Ownable.sol';
import './ActionInfo.sol';

contract EternalStorage is Ownable {
  address internal writer;

  modifier onlyWriter() {
    require(msg.sender == writer);
    _;
  }

  constructor(address owner, address initialWriter) Ownable(owner) {
    writer = initialWriter;
  }

  event StorageWriterChanged(address oldWriter, address newWriter);

  function getWriter() public view returns (address) {
    return writer;
  }

  function setWriter(address newWriter) public onlyOwner {
    emit StorageWriterChanged(writer, newWriter);
    writer = newWriter;
  }

  mapping(bytes32 => uint256) uIntStorage;
  mapping(bytes32 => string) stringStorage;
  mapping(bytes32 => address) addressStorage;
  mapping(bytes32 => bytes) bytesStorage;
  mapping(bytes32 => bool) boolStorage;
  mapping(bytes32 => int256) intStorage;

  using EnumerableMap for EnumerableMap.UintToAddressMap;
  using EnumerableMap for EnumerableMap.AddressToUintMap;
  using EnumerableMap for EnumerableMap.Bytes32ToBytes32Map;
  using EnumerableMap for EnumerableMap.UintToUintMap;
  using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
  mapping(bytes32 => EnumerableMap.UintToAddressMap) enumerableMapUintToAddressMapStorage;
  mapping(bytes32 => EnumerableMap.AddressToUintMap) enumerableMapAddressToUintMapStorage;
  mapping(bytes32 => EnumerableMap.Bytes32ToBytes32Map) enumerableMapBytes32ToBytes32MapStorage;
  mapping(bytes32 => EnumerableMap.UintToUintMap) enumerableMapUintToUintMapStorage;
  mapping(bytes32 => EnumerableMap.Bytes32ToUintMap) enumerableMapBytes32ToUintMapStorage;

  // *** Getter Methods ***
  function getUint(bytes32 _key) external view returns (uint256) {
    return uIntStorage[_key];
  }

  function getString(bytes32 _key) external view returns (string memory) {
    return stringStorage[_key];
  }

  function getAddress(bytes32 _key) external view returns (address) {
    return addressStorage[_key];
  }

  function getBytes(bytes32 _key) external view returns (bytes memory) {
    return bytesStorage[_key];
  }

  function getBool(bytes32 _key) external view returns (bool) {
    return boolStorage[_key];
  }

  function getInt(bytes32 _key) external view returns (int256) {
    return intStorage[_key];
  }

  // *** Setter Methods ***
  function setUint(bytes32 _key, uint256 _value) external onlyWriter {
    uIntStorage[_key] = _value;
  }

  function setString(bytes32 _key, string memory _value) external onlyWriter {
    stringStorage[_key] = _value;
  }

  function setAddress(bytes32 _key, address _value) external {
    addressStorage[_key] = _value;
  }

  function setBytes(bytes32 _key, bytes memory _value) external onlyWriter {
    bytesStorage[_key] = _value;
  }

  function setBool(bytes32 _key, bool _value) external onlyWriter {
    boolStorage[_key] = _value;
  }

  function setInt(bytes32 _key, int256 _value) external onlyWriter {
    intStorage[_key] = _value;
  }

  // *** Delete Methods ***
  function deleteUint(bytes32 _key) external onlyWriter {
    delete uIntStorage[_key];
  }

  function deleteString(bytes32 _key) external onlyWriter {
    delete stringStorage[_key];
  }

  function deleteAddress(bytes32 _key) external onlyWriter {
    delete addressStorage[_key];
  }

  function deleteBytes(bytes32 _key) external onlyWriter {
    delete bytesStorage[_key];
  }

  function deleteBool(bytes32 _key) external onlyWriter {
    delete boolStorage[_key];
  }

  function deleteInt(bytes32 _key) external onlyWriter {
    delete intStorage[_key];
  }

  // enumerable get

  function getEnumerableMapUintToAddress(bytes32 _key1, uint256 _key2) external view returns (address) {
    return enumerableMapUintToAddressMapStorage[_key1].get(_key2);
  }

  function getEnumerableMapAddressToUint(bytes32 _key1, address _key2) external view returns (uint256) {
    return enumerableMapAddressToUintMapStorage[_key1].get(_key2);
  }

  function getEnumerableMapBytes32ToBytes32Map(bytes32 _key1, bytes32 _key2) external view returns (bytes32) {
    return enumerableMapBytes32ToBytes32MapStorage[_key1].get(_key2);
  }

  function getEnumerableMapUintToUintMap(bytes32 _key1, uint256 _key2) external view returns (uint256) {
    return enumerableMapUintToUintMapStorage[_key1].get(_key2);
  }

  function getEnumerableMapBytes32ToUintMap(bytes32 _key1, bytes32 _key2) external view returns (uint256) {
    return enumerableMapBytes32ToUintMapStorage[_key1].get(_key2);
  }

  // enumerable tryGet

  function tryGetEnumerableMapUintToAddress(bytes32 _key1, uint256 _key2) external view returns (bool, address) {
    return enumerableMapUintToAddressMapStorage[_key1].tryGet(_key2);
  }

  function tryGetEnumerableMapAddressToUint(bytes32 _key1, address _key2) external view returns (bool, uint256) {
    return enumerableMapAddressToUintMapStorage[_key1].tryGet(_key2);
  }

  function tryGetEnumerableMapBytes32ToBytes32Map(bytes32 _key1, bytes32 _key2) external view returns (bool, bytes32) {
    return enumerableMapBytes32ToBytes32MapStorage[_key1].tryGet(_key2);
  }

  function tryGetEnumerableMapUintToUintMap(bytes32 _key1, uint256 _key2) external view returns (bool, uint256) {
    return enumerableMapUintToUintMapStorage[_key1].tryGet(_key2);
  }

  function tryGetEnumerableMapBytes32ToUintMap(bytes32 _key1, bytes32 _key2) external view returns (bool, uint256) {
    return enumerableMapBytes32ToUintMapStorage[_key1].tryGet(_key2);
  }

  // enumerable set

  function setEnumerableMapUintToAddress(
    bytes32 _key1,
    uint256 _key2,
    address _value
  ) external onlyWriter returns (bool) {
    return enumerableMapUintToAddressMapStorage[_key1].set(_key2, _value);
  }

  function setEnumerableMapAddressToUint(
    bytes32 _key1,
    address _key2,
    uint256 _value
  ) external onlyWriter returns (bool) {
    return enumerableMapAddressToUintMapStorage[_key1].set(_key2, _value);
  }

  function setEnumerableMapBytes32ToBytes32Map(
    bytes32 _key1,
    bytes32 _key2,
    bytes32 _value
  ) external onlyWriter returns (bool) {
    return enumerableMapBytes32ToBytes32MapStorage[_key1].set(_key2, _value);
  }

  function setEnumerableMapUintToUintMap(
    bytes32 _key1,
    uint256 _key2,
    uint256 _value
  ) external onlyWriter returns (bool) {
    return enumerableMapUintToUintMapStorage[_key1].set(_key2, _value);
  }

  function setEnumerableMapBytes32ToUintMap(
    bytes32 _key1,
    bytes32 _key2,
    uint256 _value
  ) external onlyWriter returns (bool) {
    return enumerableMapBytes32ToUintMapStorage[_key1].set(_key2, _value);
  }

  // enumerable remove

  function removeEnumerableMapUintToAddress(bytes32 _key1, uint256 _key2) external onlyWriter {
    enumerableMapUintToAddressMapStorage[_key1].remove(_key2);
  }

  function removeEnumerableMapAddressToUint(bytes32 _key1, address _key2) external onlyWriter {
    enumerableMapAddressToUintMapStorage[_key1].remove(_key2);
  }

  function removeEnumerableMapBytes32ToBytes32Map(bytes32 _key1, bytes32 _key2) external onlyWriter {
    enumerableMapBytes32ToBytes32MapStorage[_key1].remove(_key2);
  }

  function removeEnumerableMapUintToUintMap(bytes32 _key1, uint256 _key2) external onlyWriter {
    enumerableMapUintToUintMapStorage[_key1].remove(_key2);
  }

  function removeEnumerableMapBytes32ToUintMap(bytes32 _key1, bytes32 _key2) external onlyWriter {
    enumerableMapBytes32ToUintMapStorage[_key1].remove(_key2);
  }

  // enumerable contains

  function containsEnumerableMapUintToAddress(bytes32 _key1, uint256 _key2) external view returns (bool) {
    return enumerableMapUintToAddressMapStorage[_key1].contains(_key2);
  }

  function containsEnumerableMapAddressToUint(bytes32 _key1, address _key2) external view returns (bool) {
    return enumerableMapAddressToUintMapStorage[_key1].contains(_key2);
  }

  function containsEnumerableMapBytes32ToBytes32Map(bytes32 _key1, bytes32 _key2) external view returns (bool) {
    return enumerableMapBytes32ToBytes32MapStorage[_key1].contains(_key2);
  }

  function containsEnumerableMapUintToUintMap(bytes32 _key1, uint256 _key2) external view returns (bool) {
    return enumerableMapUintToUintMapStorage[_key1].contains(_key2);
  }

  function containsEnumerableMapBytes32ToUintMap(bytes32 _key1, bytes32 _key2) external view returns (bool) {
    return enumerableMapBytes32ToUintMapStorage[_key1].contains(_key2);
  }

  // enumerable length

  function lengthEnumerableMapUintToAddress(bytes32 _key1) external view returns (uint256) {
    return enumerableMapUintToAddressMapStorage[_key1].length();
  }

  function lengthEnumerableMapAddressToUint(bytes32 _key1) external view returns (uint256) {
    return enumerableMapAddressToUintMapStorage[_key1].length();
  }

  function lengthEnumerableMapBytes32ToBytes32Map(bytes32 _key1) external view returns (uint256) {
    return enumerableMapBytes32ToBytes32MapStorage[_key1].length();
  }

  function lengthEnumerableMapUintToUintMap(bytes32 _key1) external view returns (uint256) {
    return enumerableMapUintToUintMapStorage[_key1].length();
  }

  function lengthEnumerableMapBytes32ToUintMap(bytes32 _key1) external view returns (uint256) {
    return enumerableMapBytes32ToUintMapStorage[_key1].length();
  }

  // enumerable at

  function atEnumerableMapUintToAddress(bytes32 _key1, uint256 _index) external view returns (uint256, address) {
    return enumerableMapUintToAddressMapStorage[_key1].at(_index);
  }

  function atEnumerableMapAddressToUint(bytes32 _key1, uint256 _index) external view returns (address, uint256) {
    return enumerableMapAddressToUintMapStorage[_key1].at(_index);
  }

  function atEnumerableMapBytes32ToBytes32Map(bytes32 _key1, uint256 _index) external view returns (bytes32, bytes32) {
    return enumerableMapBytes32ToBytes32MapStorage[_key1].at(_index);
  }

  function atEnumerableMapUintToUintMap(bytes32 _key1, uint256 _index) external view returns (uint256, uint256) {
    return enumerableMapUintToUintMapStorage[_key1].at(_index);
  }

  function atEnumerableMapBytes32ToUintMap(bytes32 _key1, uint256 _index) external view returns (bytes32, uint256) {
    return enumerableMapBytes32ToUintMapStorage[_key1].at(_index);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import './Ownable.sol';

contract FreeMarketBase is Ownable {
  // TODO create getters
  address public eternalStorageAddress;
  address public upstreamAddress;
  bool public isUserProxy;

  constructor(
    address owner,
    address eternalStorage,
    address upstream,
    bool userProxy
  ) Ownable(owner) {
    eternalStorageAddress = eternalStorage;
    upstreamAddress = upstream;
    isUserProxy = userProxy;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import './EternalStorage.sol';
import './Proxy.sol';
import './LibStorageWriter.sol';

contract FrontDoor is Proxy {
  constructor() Proxy(msg.sender, address(new EternalStorage(msg.sender, address(this))), address(0x0), false) {
    bytes32 key = keccak256(abi.encodePacked('frontDoor'));
    StorageWriter.setAddress(eternalStorageAddress, key, address(this));
  }

  event UpstreamChanged(address oldUpstream, address newUpstream);

  function setUpstream(address newUpstream) public onlyOwner {
    address oldUpstream = upstreamAddress;
    upstreamAddress = newUpstream;
    emit UpstreamChanged(oldUpstream, newUpstream);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IHasUpstream {
  function getUpstream() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library StorageWriter {
  // *** Setter Methods ***
  function setUint(
    address storageAddr,
    bytes32 key,
    uint256 value
  ) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(abi.encodeWithSignature('setUint(bytes32,uint256)', key, value));
    require(success, string(returnData));
  }

  function setString(
    address storageAddr,
    bytes32 key,
    string memory value
  ) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(
      abi.encodeWithSignature('setString(bytes32,string memory)', key, value)
    );
    require(success, string(returnData));
  }

  function setAddress(
    address storageAddr,
    bytes32 key,
    address value
  ) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(abi.encodeWithSignature('setAddress(bytes32,address)', key, value));
    require(success, string(returnData));
  }

  function setBytes(
    address storageAddr,
    bytes32 key,
    bytes memory value
  ) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(
      abi.encodeWithSignature('setBytes(bytes32,bytes memory)', key, value)
    );
    require(success, string(returnData));
  }

  function setBool(
    address storageAddr,
    bytes32 key,
    bool value
  ) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(abi.encodeWithSignature('setBool(bytes32,bool)', key, value));
    require(success, string(returnData));
  }

  function setInt(
    address storageAddr,
    bytes32 key,
    int256 value
  ) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(abi.encodeWithSignature('setInt(bytes32,int256)', key, value));
    require(success, string(returnData));
  }

  // *** Delete Methods ***
  function deleteUint(address storageAddr, bytes32 key) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(abi.encodeWithSignature('deleteUint(bytes32,string memory)', key));
    require(success, string(returnData));
  }

  function deleteString(address storageAddr, bytes32 key) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(abi.encodeWithSignature('setString(bytes32,string memory)', key));
    require(success, string(returnData));
  }

  function deleteAddress(address storageAddr, bytes32 key) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(abi.encodeWithSignature('setString(bytes32,string memory)', key));
    require(success, string(returnData));
  }

  function deleteBytes(address storageAddr, bytes32 key) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(abi.encodeWithSignature('setString(bytes32,string memory)', key));
    require(success, string(returnData));
  }

  function deleteBool(address storageAddr, bytes32 key) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(abi.encodeWithSignature('setString(bytes32,string memory)', key));
    require(success, string(returnData));
  }

  function deleteInt(address storageAddr, bytes32 key) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(abi.encodeWithSignature('setString(bytes32,string memory)', key));
    require(success, string(returnData));
  }

  function setActionAddress(
    address storageAddr,
    uint16 actionId,
    address actionAddress
  ) internal {
    (bool success, bytes memory returnData) = storageAddr.delegatecall(
      abi.encodeWithSignature('setActionAddress(uint16,address)', actionId, actionAddress)
    );
    require(success, string(returnData));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ownable {
  address payable public owner;

  constructor(address initialOwner) {
    owner = payable(initialOwner);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  event LogNewOwner(address sender, address newOwner);

  function setOwner(address payable newOwner) external onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    emit LogNewOwner(msg.sender, newOwner);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import './IHasUpstream.sol';
import './FreeMarketBase.sol';

contract Proxy is FreeMarketBase, IHasUpstream {
  constructor(
    address owner,
    address storageAddress,
    address upstream,
    bool userProxy
  ) FreeMarketBase(owner, storageAddress, upstream, userProxy) {}

  function getUpstream() external view virtual returns (address) {
    return upstreamAddress;
  }

  /// @dev this forwards all calls generically to upstream, only the owner can invoke this
  fallback() external payable {
    // enforce owner authz in upstream
    // require(owner == msg.sender);
    _delegate(this.getUpstream());
  }

  /// @dev this allows this contract to receive ETH
  receive() external payable {
    // noop
  }

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   */
  function _delegate(address upstr) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())
      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), upstr, 0, calldatasize(), 0, 0)
      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())
      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
      // let ptr := mload(0x40)
      // calldatacopy(ptr, 0, calldatasize())
      // let result := delegatecall(gas(), implementation, ptr, calldatasize(), 0, 0)
      // let size := returndatasize()
      // returndatacopy(ptr, 0, size)
      // switch result
      // case 0 {
      //   revert(ptr, size)
      // }
      // default {
      //   return(ptr, size)
      // }
    }
  }
}