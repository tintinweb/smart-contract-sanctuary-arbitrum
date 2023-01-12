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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPriceOracle {
    /**
     * @dev Emitted when price feed address is updated
     */
    event FeedUpdated(address indexed token, address indexed feed);
    
    /**
     * @dev Price data structure
     */
    struct Price {
        uint256 price;
        uint256 decimals;
    }
    /**
     * @dev Get price feed address for an asset
     * @param _token Asset address
     */
    function getFeed(address _token) external view returns (address);

    /**
     * @dev Get price for an asset
     * @param _asset Asset address
     * @return Price
     */
    function getAssetPrice(address _asset) external view returns(Price memory);

    /**
     * @dev Get prices for multiple assets
     * @param _assets Array of asset addresses
     * @return Array of prices
     */
    function getAssetPrices(address[] memory _assets) external view returns(Price[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IPriceOracle.sol";
import "./interfaces/IChainlinkAggregator.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceOracle is IPriceOracle, Ownable {
    /**
     * @dev Mapping to store price feed for an asset
     */
    mapping(address => IChainlinkAggregator) public feeds;

    /**
     * @dev Set price feed for an asset
     * @param _token Asset address
     * @param _feed Price feed address
     */
    function setFeed(address _token, address _feed) public onlyOwner {
        feeds[_token] = IChainlinkAggregator(_feed);
        emit FeedUpdated(_token, _feed);
    }

    /**
     * @dev Get price feed address for an asset
     * @param _token Asset address
     */
    function getFeed(address _token) public view returns (address) {
        return address(feeds[_token]);
    }

    /**
     * @dev Get price for an asset from price feed
     * @param _asset Asset address
     * @return Price
     */
    function getAssetPrice(address _asset) public view returns(Price memory) {
        IChainlinkAggregator _feed = feeds[_asset];
        int256 price = _feed.latestAnswer();
        uint8 decimals = _feed.decimals();

        require(price > 0, "PriceOracle: Price is <= 0");

        return Price({
            price: uint256(price),
            decimals: decimals
        });
    }

    /**
     * @dev Get prices for multiple assets
     * @param _assets Asset addresses
     * @return Array of prices
     */
    function getAssetPrices(address[] memory _assets) public view returns(Price[] memory) {
        Price[] memory prices = new Price[](_assets.length);
        for(uint256 i = 0; i < _assets.length; i++) {
            prices[i] = getAssetPrice(_assets[i]);
        }
        return prices;
    }
}