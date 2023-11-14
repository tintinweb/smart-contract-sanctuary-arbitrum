// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Implementation of a map that can be iterated over.
/// @dev This contract is based on the IterableMapping library from OpenZeppelin.
library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint value) {
        assembly {
            mstore(0x0, key)
            mstore(0x20, add(map.slot, 1))
            value := sload(keccak256(0x0, 64))
        }
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address value) {
        assembly {
            mstore(0x0, map.slot)
            value := sload(add(keccak256(0x0, 32), index))
        }
    }

    function size(Map storage map) public view returns (uint length) {
        assembly {
            length := sload(map.slot)
        }
    }

    function set(
        Map storage map,
        address key,
        uint val
    ) public {
        assembly {
            mstore(0x0, key)
            mstore(0x20, add(map.slot, 3))
            let insertHash := keccak256(0x0, 64)
            let cond := sload(insertHash) // checks if `key` exists

            if cond {
                // Updating with `val` if `key` already exists
                mstore(0x20, add(map.slot, 1))
                sstore(keccak256(0x0, 64), val)
            }

            if iszero(cond) {
                sstore(insertHash, 1)
                mstore(0x20, add(map.slot, 1)) // `Map.values` slot
                sstore(keccak256(0x0, 64), val)
                mstore(0x20, add(map.slot, 2)) // `Map.indexOf` slot

                let keysLength := sload(map.slot)
                // storing the keys length
                sstore(keccak256(0x0, 64), keysLength)
                // storing the key
                mstore(0x0, map.slot)
                sstore(add(keccak256(0x0, 32), keysLength), key)
                // incrementing the keys length
                sstore(map.slot, add(keysLength, 1))
            }
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        assembly {
            let keysSlot := map.slot
            let keysLength := sload(keysSlot)

            mstore(0x0, shr(96, shl(96, key)))
            mstore(0x20, add(keysSlot, 2)) // `Map.indexOf` slot
            let index := sload(keccak256(0x0, 64))

            mstore(0x60, keysSlot)
            // swap the key to delete with the last key
            let lastKey := sload(add(keccak256(0x60, 32), sub(keysLength, 1)))

            // Update the index value in `Map.keys` to `lastKey`
            mstore(0x60, keysSlot)
            sstore(add(keccak256(0x60, 32), index), lastKey)

            // Update the lastKey's index
            mstore(0x0, lastKey)
            sstore(keccak256(0x0, 64), index) 
            
            mstore(0x60, 0) // restore zero slot
        }

        map.keys.pop();
        delete map.indexOf[key];
    }
}