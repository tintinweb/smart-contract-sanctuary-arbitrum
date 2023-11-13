// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PBM Address list Interface.
/// @notice The PBM address list stores and manages whitelisted merchants and blacklisted address for the PBMs
interface IPBMAddressList {
    /// @notice Adds wallet addresses to the blacklist who are unable to receive the pbm tokens.
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    function blacklistAddresses(address[] memory addresses, string memory metadata) external;

    /// @notice Removes wallet addresses from the blacklist who are  unable to receive the PBM tokens.
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    function unBlacklistAddresses(address[] memory addresses, string memory metadata) external;

    /// @notice Checks if the address is one of the blacklisted addresses
    /// @param _address The address in query
    /// @return True if address is a blacklisted, else false
    function isBlacklisted(address _address) external returns (bool);

    /// @notice Adds wallet addresses of merchants who are the only wallets able to receive the underlying ERC-20 tokens (whitelisting).
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    function addMerchantAddresses(address[] memory addresses, string memory metadata) external;

    /// @notice Removes wallet addresses from the merchant addresses who are  able to receive the underlying ERC-20 tokens (un-whitelisting).
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    function removeMerchantAddresses(address[] memory addresses, string memory metadata) external;

    /// @notice Checks if the address is one of the whitelisted merchant
    /// @param _address The address in query
    /// @return True if address is a merchant, else false
    function isMerchant(address _address) external returns (bool);

    /// @notice Adds wallet addresses of merchants who are hero merchants.
    /// @param addresses The list of hero merchant wallet address
    /// @param token_ids The list of heroNFT token_id
    function addHeroMerchant(address[] memory addresses, uint256[] memory token_ids) external;

    /// @notice Removes wallet addresses of merchants who are hero merchants.
    /// @param addresses The list of hero merchant wallet address
    function removeHeroMerchant(address[] memory addresses) external;

    /// @notice Get the heroNFT token_id
    /// @param _address The address in query
    /// @return 0 if not a hero merchant, else the heroNFT token_id
    function getHeroNFTId(address _address) external returns (uint256);

    /// @notice Event emitted when the Merchant List is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    event MerchantList(string action, address[] addresses, string metadata);

    /// @notice Event emitted when the Blacklist is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    event Blacklist(string action, address[] addresses, string metadata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IPBMAddressList.sol";

contract PBMAddressList is Ownable, IPBMAddressList {
    // list of merchants who are able to receive the underlying ERC-20 tokens
    mapping(address => bool) internal merchantList;
    // list of merchants who are unable to receive the PBM tokens
    mapping(address => bool) internal blacklistedAddresses;
    // mapping of hero merchant address to hero nft id
    mapping(address => uint256) internal heroNFTId;

    /**
     * @dev See {IPBMAddressList-blacklistAddresses}.
     *
     * Requirements:
     *
     * - caller must be owner
     */
    function blacklistAddresses(address[] memory addresses, string memory metadata) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            blacklistedAddresses[addresses[i]] = true;
        }
        emit Blacklist("add", addresses, metadata);
    }

    /**
     * @dev See {IPBMAddressList-unBlacklistAddresses}.
     *
     * Requirements:
     *
     * - caller must be owner
     */
    function unBlacklistAddresses(address[] memory addresses, string memory metadata) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            blacklistedAddresses[addresses[i]] = false;
        }
        emit Blacklist("remove", addresses, metadata);
    }

    /**
     * @dev See {IPBMAddressList-isBlacklisted}.
     *
     */
    function isBlacklisted(address _address) external view override returns (bool) {
        return blacklistedAddresses[_address];
    }

    /**
     * @dev See {IPBMAddressList-addMerchantAddresses}.
     *
     * Requirements:
     *
     * - caller must be owner
     */
    function addMerchantAddresses(address[] memory addresses, string memory metadata) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            merchantList[addresses[i]] = true;
        }
        emit MerchantList("add", addresses, metadata);
    }

    /**
     * @dev See {IPBMAddressList-removeMerchantAddresses}.
     *
     * Requirements:
     *
     * - caller must be owner
     */
    function removeMerchantAddresses(address[] memory addresses, string memory metadata) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            merchantList[addresses[i]] = false;
        }
        emit MerchantList("remove", addresses, metadata);
    }

    /**
     * @dev See {IPBMAddressList-isMerchant}.
     *
     */
    function isMerchant(address _address) external view override returns (bool) {
        return merchantList[_address];
    }

    /**
     * @dev See {IPBMAddressList-addHeroMerchant}.
     *
     * Requirements:
     *
     * - caller must be owner
     */
    function addHeroMerchant(address[] memory addresses, uint256[] memory token_ids) external override onlyOwner {
        require(addresses.length == token_ids.length, "PBMAddressList: addresses and token_ids length mismatch");
        for (uint256 i = 0; i < addresses.length; i++) {
            require(token_ids[i] != 0, "PBMAddressList: heroNFT token_id cannot be 0");
            heroNFTId[addresses[i]] = token_ids[i];
        }
    }

    /**
     * @dev See {IPBMAddressList-removeHeroMerchant}.
     *
     * Requirements:
     *
     * - caller must be owner
     */
    function removeHeroMerchant(address[] memory addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            heroNFTId[addresses[i]] = 0;
        }
    }

    /**
     * @dev See {IPBMAddressList-getHeroNFTId}.
     *
     */
    function getHeroNFTId(address _address) external view override returns (uint256) {
        return heroNFTId[_address];
    }
}