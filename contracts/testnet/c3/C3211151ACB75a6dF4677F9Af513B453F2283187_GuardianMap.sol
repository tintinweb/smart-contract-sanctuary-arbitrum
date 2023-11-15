// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./GuardianRecord.sol";

library GuardianMap {
    /**
     * Iterable mapping of guardians.
     */
    struct Map {
        bytes32[] keys;
        mapping(bytes32 => GuardianRecord) values;
        mapping(bytes32 => uint) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    /**
     * Get Guaridan record for the given key.
     * @param map The mapping.
     * @param key The key.
     */
    function get(
        Map storage map,
        bytes32 key
    ) public view returns (GuardianRecord memory) {
        return map.values[key];
    }

    /**
     * Get the key at a given index.
     * @param map The mappping.
     * @param index The the index.
     */
    function getKeyAtIndex(
        Map storage map,
        uint index
    ) public view returns (bytes32) {
        return map.keys[index];
    }

    /**
     * Get the size of the mapping.
     * @param map The mappping.
     */
    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    /**
     * Set the value of a given key in the mapping.
     * @param map The mapping.
     * @param key The key.
     * @param val The value.
     */
    function set(
        Map storage map,
        bytes32 key,
        GuardianRecord memory val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    /**
     * Remove an entry from the mapping.
     * @param map The mapping.
     * @param key The key of the entry to be removed.
     */
    function remove(Map storage map, bytes32 key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        bytes32 lastKey = map.keys[map.keys.length - 1];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @notice Stores the sate of a guardian
 */
enum GuardianState {
    Unregistered,
    Added,
    Removed
}

/**
 * @notice Representation of a single guardian.
 */
struct GuardianRecord {
    /**
     * The guardian's address hash.
     */
    bytes32 guardianHash;

    /**
     * @notice The guardian state.
     */
    GuardianState state;

    /**
     * @notice The timestamp indicating when the current state goes into effect.
     */
    uint256 effectiveFrom;

    /**
     * @notice The end of a lock period for a guardian (to be used only for suspensions).
     */
    uint256 lockedUntil;
}