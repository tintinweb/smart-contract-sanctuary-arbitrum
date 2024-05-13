/**
 * @author - <Aureum-Technology.com>
 * SPDX-License-Identifier: Business Source License 1.1
 **/

import "./Ownable.sol";
import "./WhitelistRole.sol";

pragma solidity 0.6.12;

contract Whitelist is Ownable, WhitelistRole {
    mapping(address => bool) public whitelist;
    address[] public whitelistedAddresses;  
    mapping(address => uint256) private whitelistedIndex; 

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    /**
     * @dev add multiple addresses to the whitelist.
     *
     * Requirements:
     *
     * Each address in `_addresses` array cannot be the zero address.
     * Only a user with the Whitelister role can call this function.
     */
    function addToWhitelistBatch(address[] memory _addresses)
        public
        onlyWhitelister
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address _address = _addresses[i];
            require(
                _address != address(0),
                "Cannot add the zero address to the whitelist"
            );
            if (!whitelist[_address]) {
                whitelist[_address] = true;
                whitelistedAddresses.push(_address);
                whitelistedIndex[_address] = whitelistedAddresses.length;  // Speichert den Index (nicht Null-basiert)
                emit AddedToWhitelist(_address);
            }
        }
    }

    /**
     * @dev add address to the whitelist.
     *
     * Requirements:
     *
     * address `account` cannot be the zero address.
     */
    function addToWhitelist(address _address) public onlyWhitelister {
        require(_address != address(0), "Cannot add the zero address to the whitelist");
        if (!whitelist[_address]) {
            whitelist[_address] = true;
            whitelistedAddresses.push(_address);
            whitelistedIndex[_address] = whitelistedAddresses.length;  // Speichert den Index (nicht Null-basiert)
            emit AddedToWhitelist(_address);
        }
    }

    /**
     * @dev Remove address from whitelist.
     *
     * Requirements:
     *
     * address `account` cannot be the zero address.
     */
    function removeFromWhitelist(address _address) public onlyWhitelister {
        require(_address != address(0), "Cannot remove the zero address from the whitelist");
        if (whitelist[_address]) {
            whitelist[_address] = false;

            uint256 index = whitelistedIndex[_address] - 1;
            address lastAddress = whitelistedAddresses[whitelistedAddresses.length - 1];

            whitelistedAddresses[index] = lastAddress;  
            whitelistedIndex[lastAddress] = index + 1;  

            whitelistedAddresses.pop();  
            delete whitelistedIndex[_address];  

            emit RemovedFromWhitelist(_address);
        }
    }

    /**
     * @dev Returns address is whitelist true or false
     *
     * Requirements:
     *
     * address `account` cannot be the zero address.
     */
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    /**
     * @dev Returns all addresses that are currently whitelisted.
     */
    function getAllWhitelisted() public view returns (address[] memory) {
        return whitelistedAddresses;
    }

    /**
     * @dev Returns a range of whitelisted addresses from startId to endId.
     *
     * @param startId The index to start at (inclusive).
     * @param endId The index to end at (inclusive).
     *
     * Requirements:
     *
     * - `startId` must be less than or equal to `endId`.
     * - `endId` must be less than the length of the whitelisted addresses array.
     */
    function getWhitelistedRange(uint256 startId, uint256 endId) public view returns (address[] memory) {
        require(startId <= endId, "Start ID must be less than or equal to End ID");
        require(endId < whitelistedAddresses.length, "End ID must be within the range of stored addresses");

        address[] memory range = new address[](endId - startId + 1);
        
        for (uint256 i = 0; i <= endId - startId; i++) {
            range[i] = whitelistedAddresses[startId + i];
        }

        return range;
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity 0.6.12;

import "./Roles.sol";
import "./Ownable.sol";

contract WhitelistRole is Ownable {
    using Roles for Roles.Role;

    event WhitelisterAdded(address indexed account);
    event WhitelisterRemoved(address indexed account);

    Roles.Role private _whitelisters;

    constructor () internal {
        _addWhitelister(msg.sender);
    }

    modifier onlyWhitelister() {
        require(isWhitelister(msg.sender), "WhitelisterRole: caller does not have the Whitelister role");
        _;
    }

    /**
     * @dev Returns account address is whitelister true or false
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function isWhitelister(address account) public view returns (bool) {
        return _whitelisters.has(account);
    }


    /**
     * @dev add address to the Whitelist role.
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function addWhitelister(address account) public onlyOwner {
        _addWhitelister(account);
    }
    
    
    /**
     * @dev remove address from the Whitelist role.
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function renounceWhitelister(address account) public onlyOwner {
        _removeWhitelister(account);
    }

    /**
     * @dev add address to the Whitelist role (internal).
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function _addWhitelister(address account) internal {
        _whitelisters.add(account);
        emit WhitelisterAdded(account);
    }

    /**
     * @dev remove address from the Whitelist role (internal).
     * 
     * Requirements:
     * 
     * address `account` cannot be the zero address.
     */
    function _removeWhitelister(address account) internal {
        _whitelisters.remove(account);
        emit WhitelisterRemoved(account);
    }
}

/**
 * SPDX-License-Identifier: GNU GPLv2
 * File @openzeppelin/contracts/access/Ownable.sol
 **/
 
import "./Context.sol";

pragma solidity 0.6.12;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

/**
 * SPDX-License-Identifier: GNU GPLv2
 **/

pragma solidity 0.6.12;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * SPDX-License-Identifier: GNU GPLv2
 * File @openzeppelin/contracts/utils/Context.sol
 **/

pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}