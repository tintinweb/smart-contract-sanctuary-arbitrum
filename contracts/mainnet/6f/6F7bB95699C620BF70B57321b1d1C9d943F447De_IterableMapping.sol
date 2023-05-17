pragma solidity ^0.8.13;

// https://solidity-by-example.org/app/iterable-mapping/
library IterableMapping {
    // Iterable mapping from uint256 to uint;
    struct Map {
        uint256[] keys;
        mapping(uint256 => uint) values;
        mapping(uint256 => uint) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function get(Map storage map, uint256 key) public view returns (uint) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (uint256) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        uint256 key,
        uint val
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

    function remove(Map storage map, uint256 key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        uint256 lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}