// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "@openzeppelin/access/Ownable.sol";


/**
 * @title Whitelist contract
 * @notice Contract responsible for managing whitelist of assets which are permited to have their transfer rights tokenized.
 *         Whitelist is temporarily solution for onboarding first users and will be dropped in the future.
 */
contract Whitelist is Ownable {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @notice Stored flag that incidates, whether ATR token minting is permited only to whitelisted assets.
     */
    bool public useWhitelist;

    /**
     * @notice Whitelist of asset addresses, which are permited to mint their transfer rights.
     * @dev Used only if `useWhitelist` flag is set to true.
     */
    mapping (address => bool) public isWhitelisted;

    /**
     * @notice Whitelist of library addresses, which are permited to be called via delegatecall.
     * @dev Always used, even if `useWhitelist` flag is set to false.
     */
    mapping (address => bool) public isWhitelistedLib;


    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    /**
     * @dev Emitted when asset address is whitelisted.
     */
    event AssetWhitelisted(address indexed assetAddress, bool indexed isWhitelisted);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor() Ownable() {

    }


    /*----------------------------------------------------------*|
    |*  # GETTERS                                               *|
    |*----------------------------------------------------------*/

    /**
     * @notice Get if an asset can have its transfer rights tokenized.
     * @param assetAddress Address of asset which transfer rights should be tokenized.
     * @return True if asset is whitelisted or whitelist is not used at all.
     */
    function canBeTokenized(address assetAddress) external view returns (bool) {
        if (!useWhitelist)
            return true;

        return isWhitelisted[assetAddress];
    }


    /*----------------------------------------------------------*|
    |*  # SETTERS                                               *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set if ATR token minting is restricted by the whitelist.
     * @dev Set `useWhitelist` stored flag.
     * @param _useWhitelist New `useWhitelist` flag value.
     */
    function setUseWhitelist(bool _useWhitelist) external onlyOwner {
        useWhitelist = _useWhitelist;
    }

    /**
     * @notice Set if asset address is whitelisted.
     * @dev Set `isWhitelisted` mapping value.
     * @param assetAddress Address of the whitelisted asset.
     * @param _isWhitelisted New `isWhitelisted` mapping value.
     */
    function setIsWhitelisted(address assetAddress, bool _isWhitelisted) public onlyOwner {
        isWhitelisted[assetAddress] = _isWhitelisted;

        emit AssetWhitelisted(assetAddress, _isWhitelisted);
    }

    /**
     * @notice Set if asset addresses from a list are whitelisted.
     * @dev Set `isWhitelisted` mapping value for every address in a list.
     * @param assetAddresses List of whitelisted asset addresses.
     * @param _isWhitelisted New `isWhitelisted` mapping value for every address in a list.
     */
    function setIsWhitelistedBatch(address[] calldata assetAddresses, bool _isWhitelisted) external onlyOwner {
        uint256 length = assetAddresses.length;
        for (uint256 i; i < length;) {
            setIsWhitelisted(assetAddresses[i], _isWhitelisted);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Set if library address is whitelisted.
     * @dev Set `isWhitelistedLib` mapping value.
     * @param libAddress Address of the whitelisted library.
     * @param _isWhitelisted New `isWhitelisted` mapping value.
     */
    function setIsWhitelistedLib(address libAddress, bool _isWhitelisted) public onlyOwner {
        isWhitelistedLib[libAddress] = _isWhitelisted;
    }

}

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