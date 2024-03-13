// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../utils/Governable.sol";

/// @title DataStore
/// @notice General purpose storage contract
/// @dev Access is restricted to governance
contract DataStore is Governable {
    uint256 private constant swV = 1000101;

    // Key-value stores
    mapping(bytes32 => uint256) public uintValues;
    mapping(bytes32 => int256) public intValues;
    mapping(bytes32 => address) public addressValues;
    mapping(bytes32 => bytes32) public dataValues;
    mapping(bytes32 => bool) public boolValues;
    mapping(bytes32 => string) public stringValues;

    constructor() Governable() {}

    /// @param key The key for the record
    /// @param value value to store
    /// @param overwrite Overwrites existing value if set to true
    function setUint(string calldata key, uint256 value, bool overwrite) external onlyGov returns (bool) {
        bytes32 hash = getHash(key);
        if (overwrite || uintValues[hash] == 0) {
            uintValues[hash] = value;
            return true;
        }
        return false;
    }

    /// @param key The key for the record
    function getUint(string calldata key) external view returns (uint256) {
        return uintValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value value to store
    /// @param overwrite Overwrites existing value if set to true
    function setInt(string calldata key, int256 value, bool overwrite) external onlyGov returns (bool) {
        bytes32 hash = getHash(key);
        if (overwrite || intValues[hash] == 0) {
            intValues[hash] = value;
            return true;
        }
        return false;
    }

    /// @param key The key for the record
    function getInt(string calldata key) external view returns (int256) {
        return intValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value address to store
    /// @param overwrite Overwrites existing value if set to true
    function setAddress(string calldata key, address value, bool overwrite) external onlyGov returns (bool) {
        bytes32 hash = getHash(key);
        if (overwrite || addressValues[hash] == address(0)) {
            addressValues[hash] = value;
            return true;
        }
        return false;
    }

    /// @param key The key for the record
    function getAddress(string calldata key) external view returns (address) {
        return addressValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value byte value to store
    function setData(string calldata key, bytes32 value) external onlyGov returns (bool) {
        dataValues[getHash(key)] = value;
        return true;
    }

    /// @param key The key for the record
    function getData(string calldata key) external view returns (bytes32) {
        return dataValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value value to store (true / false)
    function setBool(string calldata key, bool value) external onlyGov returns (bool) {
        boolValues[getHash(key)] = value;
        return true;
    }

    /// @param key The key for the record
    function getBool(string calldata key) external view returns (bool) {
        return boolValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value string to store
    function setString(string calldata key, string calldata value) external onlyGov returns (bool) {
        stringValues[getHash(key)] = value;
        return true;
    }

    /// @param key The key for the record
    function getString(string calldata key) external view returns (string memory) {
        return stringValues[getHash(key)];
    }

    /// @param key string to hash
    function getHash(string memory key) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(key));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Governable
/// @notice Basic access control mechanism, gov has access to certain functions
contract Governable {
    uint256 private constant swV = 1000101;
    address public gov;

    event SetGov(address prevGov, address nextGov);

    /// @dev Initializes the contract setting the deployer address as governance
    constructor() {
        _setGov(msg.sender);
    }

    /// @dev Reverts if called by any account other than gov
    modifier onlyGov() {
        require(msg.sender == gov, "!gov");
        _;
    }

    /// @notice Sets a new governance address
    /// @dev Only callable by governance
    function setGov(address _gov) external onlyGov {
        _setGov(_gov);
    }

    /// @notice Sets a new governance address
    /// @dev Internal function without access restriction
    function _setGov(address _gov) internal {
        address prevGov = gov;
        gov = _gov;
        emit SetGov(prevGov, _gov);
    }
}