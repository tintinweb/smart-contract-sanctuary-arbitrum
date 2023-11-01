// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import {Keys} from "./libraries/Keys.sol";

import {IDataStore} from "./interfaces/IDataStore.sol";

/// @title DataStore
/// @dev DataStore for all state values
contract DataStore is IDataStore {

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    // store for owner addresses
    mapping(address => bool) public owners;

    // store for uint values
    mapping(bytes32 => uint256) public uintValues;
    // store for int values
    mapping(bytes32 => int256) public intValues;
    // store for address values
    mapping(bytes32 => address) public addressValues;
    // store for bool values
    mapping(bytes32 => bool) public boolValues;
    // store for string values
    mapping(bytes32 => string) public stringValues;
    // store for bytes32 values
    mapping(bytes32 => bytes32) public bytes32Values;

    // store for uint[] values
    mapping(bytes32 => uint256[]) public uintArrayValues;
    // store for int[] values
    mapping(bytes32 => int256[]) public intArrayValues;
    // store for address[] values
    mapping(bytes32 => address[]) public addressArrayValues;
    // store for bool[] values
    mapping(bytes32 => bool[]) public boolArrayValues;
    // store for string[] values
    mapping(bytes32 => string[]) public stringArrayValues;
    // store for bytes32[] values
    mapping(bytes32 => bytes32[]) public bytes32ArrayValues;

    // store for address enumerable sets
    mapping(bytes32 => EnumerableSet.AddressSet) internal _addressSets;

    // store for address to uint enumerable maps
    mapping(bytes32 => EnumerableMap.AddressToUintMap) internal _addressToUintMaps;


    // ============================================================================================
    // Constructor
    // ============================================================================================

    /// @notice The ```constructor``` function is called on deployment
    /// @param _owner The owner address
    constructor(address _owner) {
        boolValues[Keys.PAUSED] = true;
        owners[_owner] = true;
    }

    // ============================================================================================
    // Modifiers
    // ============================================================================================

    /// @notice The ```onlyOwner``` modifier restricts functions to the owner
    modifier onlyOwner() {
        if (!owners[msg.sender]) revert Unauthorized();
        _;
    }

    // ============================================================================================
    // Owner Functions
    // ============================================================================================

    /// @inheritdoc IDataStore
    function updateOwnership(address _owner, bool _isActive) external onlyOwner {
        owners[_owner] = _isActive;

        emit UpdateOwnership(_owner, _isActive);
    }

    // ============================================================================================
    // Getters
    // ============================================================================================

    /// @inheritdoc IDataStore
    function getUint(bytes32 _key) external view returns (uint256) {
        return uintValues[_key];
    }

    /// @inheritdoc IDataStore
    function getInt(bytes32 _key) external view returns (int256) {
        return intValues[_key];
    }

    /// @inheritdoc IDataStore
    function getAddress(bytes32 _key) external view returns (address) {
        return addressValues[_key];
    }

    /// @inheritdoc IDataStore
    function getBool(bytes32 _key) external view returns (bool) {
        return boolValues[_key];
    }

    /// @inheritdoc IDataStore
    function getString(bytes32 _key) external view returns (string memory) {
        return stringValues[_key];
    }

    /// @inheritdoc IDataStore
    function getBytes32(bytes32 _key) external view returns (bytes32) {
        return bytes32Values[_key];
    }

    /// @inheritdoc IDataStore
    function getIntArray(bytes32 _key) external view returns (int256[] memory) {
        return intArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function getIntArrayAt(bytes32 _key, uint256 _index) external view returns (int256) {
        return intArrayValues[_key][_index];
    }

    /// @inheritdoc IDataStore
    function getUintArray(bytes32 _key) external view returns (uint256[] memory) {
        return uintArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function getUintArrayAt(bytes32 _key, uint256 _index) external view returns (uint256) {
        return uintArrayValues[_key][_index];
    }

    /// @inheritdoc IDataStore
    function getAddressArray(bytes32 _key) external view returns (address[] memory) {
        return addressArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function getAddressArrayAt(bytes32 _key, uint256 _index) external view returns (address) {
        return addressArrayValues[_key][_index];
    }

    /// @inheritdoc IDataStore
    function getBoolArray(bytes32 _key) external view returns (bool[] memory) {
        return boolArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function getBoolArrayAt(bytes32 _key, uint256 _index) external view returns (bool) {
        return boolArrayValues[_key][_index];
    }

    /// @inheritdoc IDataStore
    function getStringArray(bytes32 _key) external view returns (string[] memory) {
        return stringArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function getStringArrayAt(bytes32 _key, uint256 _index) external view returns (string memory) {
        return stringArrayValues[_key][_index];
    }

    /// @inheritdoc IDataStore
    function getBytes32Array(bytes32 _key) external view returns (bytes32[] memory) {
        return bytes32ArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function getBytes32ArrayAt(bytes32 _key, uint256 _index) external view returns (bytes32) {
        return bytes32ArrayValues[_key][_index];
    }

    /// @inheritdoc IDataStore
    function containsAddress(bytes32 _setKey, address _value) external view returns (bool) {
        return _addressSets[_setKey].contains(_value);
    }

    /// @inheritdoc IDataStore
    function getAddressCount(bytes32 _setKey) external view returns (uint256) {
        return _addressSets[_setKey].length();
    }

    /// @inheritdoc IDataStore
    function getAddressValueAt(bytes32 _setKey, uint256 _index) external view returns (address) {
        return _addressSets[_setKey].at(_index);
    }

    /// @inheritdoc IDataStore
    function containsAddressToUint(bytes32 _mapKey, address _key) external view returns (bool) {
        return _addressToUintMaps[_mapKey].contains(_key);
    }

    /// @inheritdoc IDataStore
    function getAddressToUintFor(bytes32 _mapKey, address _key) external view returns (uint256) {
        return _addressToUintMaps[_mapKey].get(_key);
    }

    /// @inheritdoc IDataStore
    function tryGetAddressToUintFor(bytes32 _mapKey, address _key) external view returns (bool, uint256) {
        return _addressToUintMaps[_mapKey].tryGet(_key);
    }

    /// @inheritdoc IDataStore
    function getAddressToUintCount(bytes32 _mapKey) external view returns (uint256) {
        return _addressToUintMaps[_mapKey].length();
    }

    /// @inheritdoc IDataStore
    function getAddressToUintAt(bytes32 _mapKey, uint256 _index) external view returns (address, uint256) {
        return _addressToUintMaps[_mapKey].at(_index);
    }

    // ============================================================================================
    // Setters
    // ============================================================================================

    /// @inheritdoc IDataStore
    function setUint(bytes32 _key, uint256 _value) external onlyOwner {
        uintValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function incrementUint(bytes32 _key, uint256 _value) external onlyOwner {
        uintValues[_key] += _value;
    }

    /// @inheritdoc IDataStore
    function decrementUint(bytes32 _key, uint256 _value) external onlyOwner {
        uintValues[_key] -= _value;
    }

    /// @inheritdoc IDataStore
    function setInt(bytes32 _key, int256 _value) external onlyOwner {
        intValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function incrementInt(bytes32 _key, int256 _value) external onlyOwner {
        intValues[_key] += _value;
    }

    /// @inheritdoc IDataStore
    function decrementInt(bytes32 _key, int256 _value) external onlyOwner {
        intValues[_key] -= _value;
    }

    /// @inheritdoc IDataStore
    function setAddress(bytes32 _key, address _value) external onlyOwner {
        addressValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function setBool(bytes32 _key, bool _value) external onlyOwner {
        boolValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function setString(bytes32 _key, string memory _value) external onlyOwner {
        stringValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function setBytes32(bytes32 _key, bytes32 _value) external onlyOwner {
        bytes32Values[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function setIntArray(bytes32 _key, int256[] memory _value) external onlyOwner {
        intArrayValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function pushIntArray(bytes32 _key, int256 _value) external onlyOwner {
        intArrayValues[_key].push(_value);
    }

    /// @inheritdoc IDataStore
    function setIntArrayAt(bytes32 _key, uint256 _index, int256 _value) external onlyOwner {
        intArrayValues[_key][_index] = _value;
    }

    /// @inheritdoc IDataStore
    function incrementIntArrayAt(bytes32 _key, uint256 _index, int256 _value) external onlyOwner {
        intArrayValues[_key][_index] += _value;
    }

    /// @inheritdoc IDataStore
    function decrementIntArrayAt(bytes32 _key, uint256 _index, int256 _value) external onlyOwner {
        intArrayValues[_key][_index] -= _value;
    }

    /// @inheritdoc IDataStore
    function setUintArray(bytes32 _key, uint256[] memory _value) external onlyOwner {
        uintArrayValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function pushUintArray(bytes32 _key, uint256 _value) external onlyOwner {
        uintArrayValues[_key].push(_value);
    }

    /// @inheritdoc IDataStore
    function setUintArrayAt(bytes32 _key, uint256 _index, uint256 _value) external onlyOwner {
        uintArrayValues[_key][_index] = _value;
    }

    /// @inheritdoc IDataStore
    function incrementUintArrayAt(bytes32 _key, uint256 _index, uint256 _value) external onlyOwner {
        uintArrayValues[_key][_index] += _value;
    }

    /// @inheritdoc IDataStore
    function decrementUintArrayAt(bytes32 _key, uint256 _index, uint256 _value) external onlyOwner {
        uintArrayValues[_key][_index] -= _value;
    }

    /// @inheritdoc IDataStore
    function setAddressArray(bytes32 _key, address[] memory _value) external onlyOwner {
        addressArrayValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function pushAddressArray(bytes32 _key, address _value) external onlyOwner {
        addressArrayValues[_key].push(_value);
    }

    /// @inheritdoc IDataStore
    function setAddressArrayAt(bytes32 _key, uint256 _index, address _value) external onlyOwner {
        addressArrayValues[_key][_index] = _value;
    }

    /// @inheritdoc IDataStore
    function setBoolArray(bytes32 _key, bool[] memory _value) external onlyOwner {
        boolArrayValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function pushBoolArray(bytes32 _key, bool _value) external onlyOwner {
        boolArrayValues[_key].push(_value);
    }

    /// @inheritdoc IDataStore
    function setBoolArrayAt(bytes32 _key, uint256 _index, bool _value) external onlyOwner {
        boolArrayValues[_key][_index] = _value;
    }

    /// @inheritdoc IDataStore
    function setStringArray(bytes32 _key, string[] memory _value) external onlyOwner {
        stringArrayValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function pushStringArray(bytes32 _key, string memory _value) external onlyOwner {
        stringArrayValues[_key].push(_value);
    }

    /// @inheritdoc IDataStore
    function setStringArrayAt(bytes32 _key, uint256 _index, string memory _value) external onlyOwner {
        stringArrayValues[_key][_index] = _value;
    }

    /// @inheritdoc IDataStore
    function setBytes32Array(bytes32 _key, bytes32[] memory _value) external onlyOwner {
        bytes32ArrayValues[_key] = _value;
    }

    /// @inheritdoc IDataStore
    function pushBytes32Array(bytes32 _key, bytes32 _value) external onlyOwner {
        bytes32ArrayValues[_key].push(_value);
    }

    /// @inheritdoc IDataStore
    function setBytes32ArrayAt(bytes32 _key, uint256 _index, bytes32 _value) external onlyOwner {
        bytes32ArrayValues[_key][_index] = _value;
    }

    /// @inheritdoc IDataStore
    function addAddress(bytes32 _setKey, address _value) external onlyOwner {
        _addressSets[_setKey].add(_value);
    }

    /// @inheritdoc IDataStore
    function addAddressToUint(bytes32 _mapKey, address _key, uint256 _value) external onlyOwner returns (bool) {
        return _addressToUintMaps[_mapKey].set(_key, _value);
    }

    // ============================================================================================
    // Removers
    // ============================================================================================

    /// @inheritdoc IDataStore
    function removeUint(bytes32 _key) external onlyOwner {
        delete uintValues[_key];
    }

    function removeInt(bytes32 _key) external onlyOwner {
        delete intValues[_key];
    }

    /// @inheritdoc IDataStore
    function removeAddress(bytes32 _key) external onlyOwner {
        delete addressValues[_key];
    }

    /// @inheritdoc IDataStore
    function removeBool(bytes32 _key) external onlyOwner {
        delete boolValues[_key];
    }

    /// @inheritdoc IDataStore
    function removeString(bytes32 _key) external onlyOwner {
        delete stringValues[_key];
    }

    /// @inheritdoc IDataStore
    function removeBytes32(bytes32 _key) external onlyOwner {
        delete bytes32Values[_key];
    }

    /// @inheritdoc IDataStore
    function removeUintArray(bytes32 _key) external onlyOwner {
        delete uintArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function removeIntArray(bytes32 _key) external onlyOwner {
        delete intArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function removeAddressArray(bytes32 _key) external onlyOwner {
        delete addressArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function removeBoolArray(bytes32 _key) external onlyOwner {
        delete boolArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function removeStringArray(bytes32 _key) external onlyOwner {
        delete stringArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function removeBytes32Array(bytes32 _key) external onlyOwner {
        delete bytes32ArrayValues[_key];
    }

    /// @inheritdoc IDataStore
    function removeAddress(bytes32 _setKey, address _value) external onlyOwner {
        _addressSets[_setKey].remove(_value);
    }

    /// @inheritdoc IDataStore
    function removeUintToAddress(bytes32 _mapKey, address _key) external onlyOwner returns (bool) {
        return _addressToUintMaps[_mapKey].remove(_key);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title Keys
/// @dev Keys for values in the DataStore
library Keys {

    // DataStore.uintValues

    /// @dev key for management fee (DataStore.uintValues)
    bytes32 public constant MANAGEMENT_FEE = keccak256(abi.encode("MANAGEMENT_FEE"));
    /// @dev key for withdrawal fee (DataStore.uintValues)
    bytes32 public constant WITHDRAWAL_FEE = keccak256(abi.encode("WITHDRAWAL_FEE"));
    /// @dev key for performance fee (DataStore.uintValues)
    bytes32 public constant PERFORMANCE_FEE = keccak256(abi.encode("PERFORMANCE_FEE"));

    // DataStore.intValues

    // DataStore.addressValues

    /// @dev key for sending received fees
    bytes32 public constant PLATFORM_FEES_RECIPIENT = keccak256(abi.encode("PLATFORM_FEES_RECIPIENT"));
    /// @dev key for subscribing to multiple Routes
    bytes32 public constant MULTI_SUBSCRIBER = keccak256(abi.encode("MULTI_SUBSCRIBER"));
    /// @dev key for the address of the keeper
    bytes32 public constant KEEPER = keccak256(abi.encode("KEEPER"));
    /// @dev key for the address of the Score Gauge
    bytes32 public constant SCORE_GAUGE = keccak256(abi.encode("SCORE_GAUGE"));
    /// @dev key for the address of the Route Factory
    bytes32 public constant ROUTE_FACTORY = keccak256(abi.encode("ROUTE_FACTORY"));
    /// @dev key for the address of the Route Setter
    bytes32 public constant ROUTE_SETTER = keccak256(abi.encode("ROUTE_SETTER"));
    /// @dev key for the address of the Orchestrator
    bytes32 public constant ORCHESTRATOR = keccak256(abi.encode("ORCHESTRATOR"));

    // DataStore.boolValues

    /// @dev key for pause status
    bytes32 public constant PAUSED = keccak256(abi.encode("PAUSED"));

    // DataStore.stringValues

    // DataStore.bytes32Values

    /// @dev key for the referral code
    bytes32 public constant REFERRAL_CODE = keccak256(abi.encode("REFERRAL_CODE"));

    // DataStore.addressArrayValues

    /// @dev key for the array of routes
    bytes32 public constant ROUTES = keccak256(abi.encode("ROUTES"));


    // -------------------------------------------------------------------------------------------

    // global

    function routeTypeKey(address _collateralToken, address _indexToken, bool _isLong, bytes memory _data) public pure returns (bytes32) {
        return keccak256(abi.encode(_collateralToken, _indexToken, _isLong, _data));
    }

    function routeTypeCollateralTokenKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("COLLATERAL_TOKEN", _routeTypeKey));
    }

    function routeTypeIndexTokenKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("INDEX_TOKEN", _routeTypeKey));
    }

    function routeTypeIsLongKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_LONG", _routeTypeKey));
    }

    function routeTypeDataKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("DATA", _routeTypeKey));
    }

    function platformAccountKey(address _asset) public pure returns (bytes32) {
        return keccak256(abi.encode("PLATFORM_ACCOUNT", _asset));
    }

    function isRouteTypeRegisteredKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_ROUTE_TYPE_REGISTERED", _routeTypeKey));
    }

    function isCollateralTokenKey(address _token) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_COLLATERAL_TOKEN", _token));
    }

    function collateralTokenDecimalsKey(address _collateralToken) public pure returns (bytes32) {
        return keccak256(abi.encode("COLLATERAL_TOKEN_DECIMALS", _collateralToken));
    }

    // route

    function routeCollateralTokenKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_COLLATERAL_TOKEN", _route));
    }

    function routeIndexTokenKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_INDEX_TOKEN", _route));
    }

    function routeIsLongKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_IS_LONG", _route));
    }

    function routeTraderKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_TRADER", _route));
    }

    function routeDataKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_DATA", _route));
    }

    function routeRouteTypeKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_ROUTE_TYPE", _route));
    }

    function routeAddressKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_ADDRESS", _routeKey));
    }

    function routePuppetsKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_PUPPETS", _routeKey));
    }

    function targetLeverageKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("TARGET_LEVERAGE", _routeKey));
    }

    function isKeeperRequestsKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("KEEPER_REQUESTS", _routeKey, _requestKey));
    }

    function isRouteRegisteredKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_ROUTE_REGISTERED", _routeKey));
    }

    function isWaitingForKeeperAdjustmentKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_WAITING_FOR_KEEPER_ADJUSTMENT", _routeKey));
    }

    function isKeeperAdjustmentEnabledKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_KEEPER_ADJUSTMENT_ENABLED", _routeKey));
    }

    function isPositionOpenKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_POSITION_OPEN", _routeKey));
    }

    // route position

    function positionIndexKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_INDEX", _routeKey));
    }

    function positionPuppetsKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_PUPPETS", _positionIndex, _routeKey));
    }

    function positionTraderSharesKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TRADER_SHARES", _positionIndex, _routeKey));
    }

    function positionPuppetsSharesKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_PUPPETS_SHARES", _positionIndex, _routeKey));
    }

    function positionLastTraderAmountInKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_LAST_TRADER_AMOUNT_IN", _positionIndex, _routeKey));
    }

    function positionLastPuppetsAmountsInKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_LAST_PUPPETS_AMOUNTS_IN", _positionIndex, _routeKey));
    }

    function positionTotalSupplyKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TOTAL_SUPPLY", _positionIndex, _routeKey));
    }

    function positionTotalAssetsKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TOTAL_ASSETS", _positionIndex, _routeKey));
    }

    function cumulativeVolumeGeneratedKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("CUMULATIVE_VOLUME_GENERATED", _routeKey));
    }

    function puppetsPnLKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPETS_PNL", _routeKey));
    }

    function traderPnLKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("TRADER_PNL", _routeKey));
    }

    // route request

    function requestKeyToAddCollateralRequestsIndexKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("REQUEST_KEY_TO_ADD_COLLATERAL_REQUESTS_INDEX", _routeKey, _requestKey));
    }

    function addCollateralRequestsIndexKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUESTS_INDEX", _positionIndex, _routeKey));
    }

    function addCollateralRequestPuppetsSharesKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_SHARES", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestPuppetsAmountsKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_AMOUNTS", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTraderAmountInKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TRADER_AMOUNT_IN", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestPuppetsAmountInKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_AMOUNT_IN", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestIsAdjustmentRequiredKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_IS_ADJUSTMENT_REQUIRED", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTraderSharesKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TRADER_SHARES", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTotalSupplyKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TOTAL_SUPPLY", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTotalAssetsKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TOTAL_ASSETS", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function pendingSizeDeltaKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PENDING_SIZE_DELTA", _routeKey, _requestKey));
    }

    function requestKeysKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("REQUEST_KEYS", _positionIndex, _routeKey));
    }

    // puppet

    function puppetAllowancesKey(address _puppet) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_ALLOWANCES", _puppet));
    }

    function puppetSubscriptionExpiryKey(address _puppet, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_SUBSCRIPTION_EXPIRY", _puppet, _routeKey));
    }

    function puppetDepositAccountKey(address _puppet, address _asset) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_DEPOSIT_ACCOUNT", _puppet, _asset));
    }

    function puppetThrottleLimitKey(address _puppet, bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_THROTTLE_LIMIT", _puppet, _routeTypeKey));
    }

    function puppetLastPositionOpenedTimestampKey(address _puppet, bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_LAST_POSITION_OPENED_TIMESTAMP", _puppet, _routeTypeKey));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ========================= IDataStore =========================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

interface IDataStore {

    // ============================================================================================
    // Owner Functions
    // ============================================================================================

    /// @notice Update the ownership of the contract
    /// @param _owner The owner address
    /// @param _isActive The status of the owner
    function updateOwnership(address _owner, bool _isActive) external;

    // ============================================================================================
    // Getters
    // ============================================================================================

    /// @dev get the uint value for the given key
    /// @param _key the key of the value
    /// @return _value the uint value for the key
    function getUint(bytes32 _key) external view returns (uint256 _value);

    /// @dev get the int value for the given key
    /// @param _key the key of the value
    /// @return _value the int value for the key
    function getInt(bytes32 _key) external view returns (int256 _value);

    /// @dev get the address value for the given key
    /// @param _key the key of the value
    /// @return _value the address value for the key
    function getAddress(bytes32 _key) external view returns (address _value);

    /// @dev get the bool value for the given key
    /// @param _key the key of the value
    /// @return _value the bool value for the key
    function getBool(bytes32 _key) external view returns (bool _value);

    /// @dev get the string value for the given key
    /// @param _key the key of the value
    /// @return _value the string value for the key
    function getString(bytes32 _key) external view returns (string memory _value);

    /// @dev get the bytes32 value for the given key
    /// @param _key the key of the value
    /// @return _value the bytes32 value for the key
    function getBytes32(bytes32 _key) external view returns (bytes32 _value);

    /// @dev get the int array for the given key
    /// @param _key the key of the int array
    /// @return _value the int array for the key
    function getIntArray(bytes32 _key) external view returns (int256[] memory _value);

    /// @dev get the int array for the given key and index
    /// @param _key the key of the int array
    /// @param _index the index of the int array
    function getIntArrayAt(bytes32 _key, uint256 _index) external view returns (int256);

    /// @dev get the uint array for the given key
    /// @param _key the key of the uint array
    /// @return _value the uint array for the key
    function getUintArray(bytes32 _key) external view returns (uint256[] memory _value);

    /// @dev get the uint array for the given key and index
    /// @param _key the key of the uint array
    /// @param _index the index of the uint array
    function getUintArrayAt(bytes32 _key, uint256 _index) external view returns (uint256);

    /// @dev get the address array for the given key
    /// @param _key the key of the address array
    /// @return _value the address array for the key
    function getAddressArray(bytes32 _key) external view returns (address[] memory _value);

    /// @dev get the address array for the given key and index
    /// @param _key the key of the address array
    /// @param _index the index of the address array
    function getAddressArrayAt(bytes32 _key, uint256 _index) external view returns (address);

    /// @dev get the bool array for the given key
    /// @param _key the key of the bool array
    /// @return _value the bool array for the key
    function getBoolArray(bytes32 _key) external view returns (bool[] memory _value);

    /// @dev get the bool array for the given key and index
    /// @param _key the key of the bool array
    /// @param _index the index of the bool array
    function getBoolArrayAt(bytes32 _key, uint256 _index) external view returns (bool);

    /// @dev get the string array for the given key
    /// @param _key the key of the string array
    /// @return _value the string array for the key
    function getStringArray(bytes32 _key) external view returns (string[] memory _value);

    /// @dev get the string array for the given key and index
    /// @param _key the key of the string array
    /// @param _index the index of the string array
    function getStringArrayAt(bytes32 _key, uint256 _index) external view returns (string memory);

    /// @dev get the bytes32 array for the given key
    /// @param _key the key of the bytes32 array
    /// @return _value the bytes32 array for the key
    function getBytes32Array(bytes32 _key) external view returns (bytes32[] memory _value);

    /// @dev get the bytes32 array for the given key and index
    /// @param _key the key of the bytes32 array
    /// @param _index the index of the bytes32 array
    function getBytes32ArrayAt(bytes32 _key, uint256 _index) external view returns (bytes32);

    /// @dev check whether the given value exists in the set
    /// @param _setKey the key of the set
    /// @param _value the value to check
    /// @return _exists whether the value exists in the set
    function containsAddress(bytes32 _setKey, address _value) external view returns (bool _exists);

    /// @dev get the length of the set
    /// @param _setKey the key of the set
    /// @return _length the length of the set
    function getAddressCount(bytes32 _setKey) external view returns (uint256 _length);

    /// @dev get the values of the set at the given index
    /// @param _setKey the key of the set
    /// @param _index the index of the value to return
    /// @return _value the value at the given index
    function getAddressValueAt(bytes32 _setKey, uint256 _index) external view returns (address _value);

    /// @dev check whether the key exists in the map
    /// @param _mapKey the key of the map
    /// @param _key the key to check
    /// @return _exists whether the key exists in the map
    function containsAddressToUint(bytes32 _mapKey, address _key) external view returns (bool _exists);

    /// @dev get the value associated with key. reverts if the key does not exist
    /// @param _mapKey the key of the map
    /// @param _key the key to get the value for
    /// @return _value the value associated with the key
    function getAddressToUintFor(bytes32 _mapKey, address _key) external view returns (uint256 _value);

    /// @dev tries to returns the value associated with key. does not revert if key is not in the map
    /// @param _mapKey the key of the map
    /// @param _key the key to get the value for
    /// @return _exists whether the key exists in the map
    /// @return _value the value associated with the key
    function tryGetAddressToUintFor(bytes32 _mapKey, address _key) external view returns (bool _exists, uint256 _value);

    /// @dev get the length of the map
    /// @param _mapKey the key of the map
    /// @return _length the length of the map
    function getAddressToUintCount(bytes32 _mapKey) external view returns (uint256 _length);

    /// @dev get the key and value pairs of the map in the given index
    /// @param _mapKey the key of the map
    /// @param _index the index of the key and value pair to return
    /// @return _key the key at the given index
    /// @return _value the value at the given index
    function getAddressToUintAt(bytes32 _mapKey, uint256 _index) external view returns (address _key, uint256 _value);

    /// ============================================================================================
    /// Setters
    /// ============================================================================================

    /// @dev set the uint value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setUint(bytes32 _key, uint256 _value) external;

    /// @dev add the input uint value to the existing uint value
    /// @param _key the key of the value
    /// @param _value the amount to add to the existing uint value
    function incrementUint(bytes32 _key, uint256 _value) external;

    /// @dev subtract the input uint value from the existing uint value
    /// @param _key the key of the value
    /// @param _value the amount to subtract from the existing uint value
    function decrementUint(bytes32 _key, uint256 _value) external;

    /// @dev set the int value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setInt(bytes32 _key, int256 _value) external;

    /// @dev add the input int value to the existing int value
    /// @param _key the key of the value
    /// @param _value the amount to add to the existing int value
    function incrementInt(bytes32 _key, int256 _value) external;

    /// @dev subtract the input int value from the existing int value
    /// @param _key the key of the value
    /// @param _value the amount to subtract from the existing int value
    function decrementInt(bytes32 _key, int256 _value) external;

    /// @dev set the address value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setAddress(bytes32 _key, address _value) external;

    /// @dev set the bool value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setBool(bytes32 _key, bool _value) external;

    /// @dev set the string value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setString(bytes32 _key, string memory _value) external;

    /// @dev set the bytes32 value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setBytes32(bytes32 _key, bytes32 _value) external;

    /// @dev set the int array for the given key
    /// @param _key the key of the int array
    /// @param _value the value of the int array
    function setIntArray(bytes32 _key, int256[] memory _value) external;

    /// @dev push the input int value to the existing int array
    /// @param _key the key of the int array
    /// @param _value the value to push to the existing int array
    function pushIntArray(bytes32 _key, int256 _value) external;

    /// @dev set a specific index of the int array with the input value
    /// @param _key the key of the int array
    /// @param _index the index of the int array to set
    /// @param _value the value to set
    function setIntArrayAt(bytes32 _key, uint256 _index, int256 _value) external;

    /// @dev increment the int value at the given index of the int array with the input value
    /// @param _key the key of the int array
    /// @param _index the index of the int array to increment
    /// @param _value the value to increment
    function incrementIntArrayAt(bytes32 _key, uint256 _index, int256 _value) external;

    /// @dev decrement the int value at the given index of the int array with the input value
    /// @param _key the key of the int array
    /// @param _index the index of the int array to decrement
    /// @param _value the value to decrement
    function decrementIntArrayAt(bytes32 _key, uint256 _index, int256 _value) external;

    /// @dev set the uint array for the given key
    /// @param _key the key of the uint array
    /// @param _value the value of the uint array
    function setUintArray(bytes32 _key, uint256[] memory _value) external;

    /// @dev push the input uint value to the existing uint array
    /// @param _key the key of the uint array
    /// @param _value the value to push to the existing uint array
    function pushUintArray(bytes32 _key, uint256 _value) external;

    /// @dev set a specific index of the uint array with the input value
    /// @param _key the key of the uint array
    /// @param _index the index of the uint array to set
    /// @param _value the value to set
    function setUintArrayAt(bytes32 _key, uint256 _index, uint256 _value) external;

    /// @dev increment the uint value at the given index of the uint array with the input value
    /// @param _key the key of the uint array
    /// @param _index the index of the uint array to increment
    /// @param _value the value to increment
    function incrementUintArrayAt(bytes32 _key, uint256 _index, uint256 _value) external;

    /// @dev decrement the uint value at the given index of the uint array with the input value
    /// @param _key the key of the uint array
    /// @param _index the index of the uint array to decrement
    /// @param _value the value to decrement
    function decrementUintArrayAt(bytes32 _key, uint256 _index, uint256 _value) external;

    /// @dev set the address array for the given key
    /// @param _key the key of the address array
    /// @param _value the value of the address array
    function setAddressArray(bytes32 _key, address[] memory _value) external;

    /// @dev push the input address value to the existing address array
    /// @param _key the key of the address array
    /// @param _value the value to push to the existing address array
    function pushAddressArray(bytes32 _key, address _value) external;

    /// @dev set a specific index of the address array with the input value
    /// @param _key the key of the address array
    /// @param _index the index of the address array to set
    /// @param _value the value to set
    function setAddressArrayAt(bytes32 _key, uint256 _index, address _value) external;

    /// @dev set the bool array for the given key
    /// @param _key the key of the bool array
    /// @param _value the value of the bool array
    function setBoolArray(bytes32 _key, bool[] memory _value) external;

    /// @dev push the input bool value to the existing bool array
    /// @param _key the key of the bool array
    /// @param _value the value to push to the existing bool array
    function pushBoolArray(bytes32 _key, bool _value) external;

    /// @dev set a specific index of the bool array with the input value
    /// @param _key the key of the bool array
    /// @param _index the index of the bool array to set
    /// @param _value the value to set
    function setBoolArrayAt(bytes32 _key, uint256 _index, bool _value) external;

    /// @dev set the string array for the given key
    /// @param _key the key of the string array
    /// @param _value the value of the string array
    function setStringArray(bytes32 _key, string[] memory _value) external;

    /// @dev push the input string value to the existing string array
    /// @param _key the key of the string array
    /// @param _value the value to push to the existing string array
    function pushStringArray(bytes32 _key, string memory _value) external;

    /// @dev set a specific index of the string array with the input value
    /// @param _key the key of the string array
    /// @param _index the index of the string array to set
    /// @param _value the value to set
    function setStringArrayAt(bytes32 _key, uint256 _index, string memory _value) external;

    /// @dev set the bytes32 array for the given key
    /// @param _key the key of the bytes32 array
    /// @param _value the value of the bytes32 array
    function setBytes32Array(bytes32 _key, bytes32[] memory _value) external;

    /// @dev push the input bytes32 value to the existing bytes32 array
    /// @param _key the key of the bytes32 array
    /// @param _value the value to push to the existing bytes32 array
    function pushBytes32Array(bytes32 _key, bytes32 _value) external;

    /// @dev set a specific index of the bytes32 array with the input value
    /// @param _key the key of the bytes32 array
    /// @param _index the index of the bytes32 array to set
    /// @param _value the value to set
    function setBytes32ArrayAt(bytes32 _key, uint256 _index, bytes32 _value) external;

    /// @dev add the given value to the set
    /// @param _setKey the key of the set
    /// @param _value the value to add
    function addAddress(bytes32 _setKey, address _value) external;

    /// @dev add a key-value pair to a map, or updates the value for an existing key returns true 
    ///      if the key was added to the map, that is if it was not already present
    /// @param _mapKey the key of the map
    /// @param _key the key to add
    /// @param _value the value to add
    function addAddressToUint(bytes32 _mapKey, address _key, uint256 _value) external returns (bool _added);

    // ============================================================================================
    // Removers
    // ============================================================================================

    /// @dev delete the uint value for the given key
    /// @param _key the key of the value
    function removeUint(bytes32 _key) external;

    function removeInt(bytes32 _key) external;

    /// @dev delete the address value for the given key
    /// @param _key the key of the value
    function removeAddress(bytes32 _key) external;

    /// @dev delete the bool value for the given key
    /// @param _key the key of the value
    function removeBool(bytes32 _key) external;

    /// @dev delete the string value for the given key
    /// @param _key the key of the value
    function removeString(bytes32 _key) external;

    /// @dev delete the bytes32 value for the given key
    /// @param _key the key of the value
    function removeBytes32(bytes32 _key) external;

    /// @dev delete the uint array for the given key
    /// @param _key the key of the uint array
    function removeUintArray(bytes32 _key) external;

    /// @dev delete the int array for the given key
    /// @param _key the key of the int array
    function removeIntArray(bytes32 _key) external;

    /// @dev delete the address array for the given key
    /// @param _key the key of the address array
    function removeAddressArray(bytes32 _key) external;

    /// @dev delete the bool array for the given key
    /// @param _key the key of the bool array
    function removeBoolArray(bytes32 _key) external;

    /// @dev delete the string array for the given key
    /// @param _key the key of the string array
    function removeStringArray(bytes32 _key) external;

    /// @dev delete the bytes32 array for the given key
    /// @param _key the key of the bytes32 array
    function removeBytes32Array(bytes32 _key) external;

    /// @dev remove the given value from the set
    /// @param _setKey the key of the set
    /// @param _value the value to remove
    function removeAddress(bytes32 _setKey, address _value) external;

    /// @dev removes a value from a set
    ///      returns true if the key was removed from the map, that is if it was present
    /// @param _mapKey the key of the map
    /// @param _key the key to remove
    /// @param _removed whether or not the key was removed
    function removeUintToAddress(bytes32 _mapKey, address _key) external returns (bool _removed);

    // ============================================================================================
    // Events
    // ============================================================================================

    event UpdateOwnership(address owner, bool isActive);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error Unauthorized();
}