/**
 *Submitted for verification at Arbiscan on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
contract CustomOwnable {
    // The current owner of this resource.
    address internal _owner;

    /**
     * @notice This event is triggered when the current owner transfers ownership of the contract.
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OnOwnershipTransferred (address previousOwner, address newOwner);

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) external virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        _transferOwnership(addr);
    }

    /**
     * @notice Gets the owner of this contract.
     * @return Returns the address of the owner.
     */
    function owner () external virtual view returns (address) {
        return _owner;
    }

    function _transferOwnership (address addr) internal virtual {
        address oldValue = _owner;
        _owner = addr;
        emit OnOwnershipTransferred(oldValue, _owner);
    }
}

/**
 * @notice Defines the interface for whitelisting addresses.
 */
interface IAddressWhitelist {
    /**
     * @notice Whitelists the address specified.
     * @param addr The address to enable
     */
    function enableAddress (address addr) external;

    /**
     * @notice Disables the address specified.
     * @param addr The address to disable
     */
    function disableAddress (address addr) external;

    /**
     * @notice Indicates if the address is whitelisted or not.
     * @param addr The address to disable
     * @return Returns 1 if the address is whitelisted
     */
    function isWhitelistedAddress (address addr) external view returns (bool);

    /**
     * This event is triggered when a new address is whitelisted.
     * @param addr The address that was whitelisted
     */
    event OnAddressEnabled(address addr);

    /**
     * This event is triggered when an address is disabled.
     * @param addr The address that was disabled
     */
    event OnAddressDisabled(address addr);
}

/**
 * @title Contract for whitelisting addresses
 */
contract AddressWhitelist is IAddressWhitelist, CustomOwnable {
    mapping (address => bool) internal whitelistedAddresses;

    /**
     * @notice Constructor.
     * @param ownerAddr The address of the owner
     */
    constructor (address ownerAddr) {
        _transferOwnership(ownerAddr);
    }

    /**
     * @notice Whitelists the address specified.
     * @param addr The address to enable
     */
    function enableAddress (address addr) external override onlyOwner {
        require(!whitelistedAddresses[addr], "Already enabled");
        whitelistedAddresses[addr] = true;
        emit OnAddressEnabled(addr);
    }

    /**
     * @notice Disables the address specified.
     * @param addr The address to disable
     */
    function disableAddress (address addr) external override onlyOwner {
        require(whitelistedAddresses[addr], "Already disabled");
        whitelistedAddresses[addr] = false;
        emit OnAddressDisabled(addr);
    }

    /**
     * @notice Indicates if the address is whitelisted or not.
     * @param addr The address to disable
     * @return Returns true if the address is whitelisted
     */
    function isWhitelistedAddress (address addr) external view override returns (bool) {
        return whitelistedAddresses[addr];
    }
}