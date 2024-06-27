// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/access/Ownable.sol";

contract UnifiedStore is Ownable {
    mapping(string => string) public configString;
    mapping(string => address) public configAddress;
    mapping(string => bool) public configBool;
    mapping(string => uint256) public configUint256;

    event UpdateString(string key, string value);
    event DeleteString(string key);

    event UpdateAddress(string key, address value);
    event DeleteAddress(string key);

    event UpdateBool(string key, bool value);
    event DeleteBool(string key);

    event UpdateUint256(string key, uint256 value);
    event DeleteUint256(string key);

    constructor() Ownable(msg.sender) {}

    /// string
    function setStrings(string[] calldata keys, string[] calldata values) public onlyOwner {
        for (uint256 i = 0; i < keys.length; ++i) {
            configString[keys[i]] = values[i];
            emit UpdateString(keys[i], values[i]);
        }
    }

    function deleteStrings(string[] calldata keys) public onlyOwner {
        for (uint256 i = 0; i < keys.length; ++i) {
            delete configString[keys[i]];
            emit DeleteString(keys[i]);
        }
    }

    function setString(string calldata key, string calldata value) public onlyOwner {
        configString[key] = value;
        emit UpdateString(key, value);
    }

    function deleteString(string calldata key) public onlyOwner {
        delete configString[key];
        emit DeleteString(key);
    }

    function getStrings(string[] calldata keys) public view returns (string[] memory) {
        string[] memory values = new string[](keys.length);
        for (uint256 i = 0; i < keys.length; ++i) {
            values[i] = configString[keys[i]];
        }
        return values;
    }

    function getString(string calldata key) public view returns (string memory) {
        return configString[key];
    }

    /// address

    function setAddress(string calldata key, address value) public onlyOwner {
        configAddress[key] = value;
        emit UpdateAddress(key, value);
    }

    function deleteAddress(string calldata key) public onlyOwner {
        delete configAddress[key];
        emit DeleteAddress(key);
    }

    function getAddress(string calldata key) public view returns (address) {
        return configAddress[key];
    }

    function setAddresses(string[] calldata keys, address[] calldata values) public onlyOwner {
        for (uint256 i = 0; i < keys.length; ++i) {
            configAddress[keys[i]] = values[i];
            emit UpdateAddress(keys[i], values[i]);
        }
    }

    function getAddresses(string[] calldata keys) public view returns (address[] memory) {
        address[] memory values = new address[](keys.length);
        for (uint256 i = 0; i < keys.length; ++i) {
            values[i] = configAddress[keys[i]];
        }
        return values;
    }

    function deleteAddresses(string[] calldata keys) public onlyOwner {
        for (uint256 i = 0; i < keys.length; ++i) {
            delete configAddress[keys[i]];
            emit DeleteAddress(keys[i]);
        }
    }

    /// bool
    function setBool(string calldata key, bool value) public onlyOwner {
        configBool[key] = value;
        emit UpdateBool(key, value);
    }

    function deleteBool(string calldata key) public onlyOwner {
        delete configBool[key];
        emit DeleteBool(key);
    }

    function getBool(string calldata key) public view returns (bool) {
        return configBool[key];
    }

    function setBools(string[] calldata keys, bool[] calldata values) public onlyOwner {
        for (uint256 i = 0; i < keys.length; ++i) {
            configBool[keys[i]] = values[i];
            emit UpdateBool(keys[i], values[i]);
        }
    }

    function getBools(string[] calldata keys) public view returns (bool[] memory) {
        bool[] memory values = new bool[](keys.length);
        for (uint256 i = 0; i < keys.length; ++i) {
            values[i] = configBool[keys[i]];
        }
        return values;
    }

    function deleteBools(string[] calldata keys) public onlyOwner {
        for (uint256 i = 0; i < keys.length; ++i) {
            delete configBool[keys[i]];
            emit DeleteBool(keys[i]);
        }
    }

    // uint256
    function setUint256(string calldata key, uint256 value) public onlyOwner {
        configUint256[key] = value;
        emit UpdateUint256(key, value);
    }

    function deleteUint256(string calldata key) public onlyOwner {
        delete configUint256[key];
        emit DeleteUint256(key);
    }

    function getUint256(string calldata key) public view returns (uint256) {
        return configUint256[key];
    }

    function setUint256s(string[] calldata keys, uint256[] calldata values) public onlyOwner {
        for (uint256 i = 0; i < keys.length; ++i) {
            configUint256[keys[i]] = values[i];
            emit UpdateUint256(keys[i], values[i]);
        }
    }

    function getUint256s(string[] calldata keys) public view returns (uint256[] memory) {
        uint256[] memory values = new uint256[](keys.length);
        for (uint256 i = 0; i < keys.length; ++i) {
            values[i] = configUint256[keys[i]];
        }
        return values;
    }

    function deleteUint256s(string[] calldata keys) public onlyOwner {
        for (uint256 i = 0; i < keys.length; ++i) {
            delete configUint256[keys[i]];
            emit DeleteUint256(keys[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}