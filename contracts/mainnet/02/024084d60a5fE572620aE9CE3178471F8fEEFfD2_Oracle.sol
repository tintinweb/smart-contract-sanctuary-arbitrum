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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAggregator.sol";
import "./interfaces/IOracle.sol";

/**
 * @title Oracle
 * @author LC
 * @notice Contract to get asset prices, manage price sources
 */
contract Oracle is IOracle, Ownable {
    // Map of asset price sources (asset => priceSource)
    mapping(address => IAggregator) private assetsSources;

    // token address => usd price (8 decimals)
    mapping(address => uint256) private priceFeeds;

    constructor(
        address owner,
        address[] memory assets1,
        address[] memory sources,
        address[] memory assets2,
        uint256[] memory prices
    ) Ownable(owner) {
        _setAssetSources(assets1, sources);
        _setPriceFeeds(assets2, prices);
    }

    function setPriceFeeds(address[] memory assets, uint256[] memory prices) external onlyOwner {
        _setPriceFeeds(assets, prices);
    }

    function setAssetSources(address[] memory assets, address[] memory sources) external onlyOwner {
        _setAssetSources(assets, sources);
    }

    function getAssetPrice(address asset) public view returns (uint256) {
        IAggregator source = assetsSources[asset];

        if (address(source) != address(0)) {
            (, int256 price, , , ) = source.latestRoundData();
            return uint256(price);
        }

        if (priceFeeds[asset] != 0) {
            return priceFeeds[asset];
        }

        revert("asset not found");
    }

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getAssetPrice(assets[i]);
        }
        return prices;
    }

    function getSourceOfAsset(address asset) external view returns (address) {
        return address(assetsSources[asset]);
    }

    function _setPriceFeeds(address[] memory assets, uint256[] memory prices) private {
        require(assets.length == prices.length, "array parameters should be equal");

        for (uint256 i = 0; i < assets.length; i++) {
            priceFeeds[assets[i]] = prices[i];
            emit AssetPriceUpdated(assets[i], prices[i]);
        }
    }

    function _setAssetSources(address[] memory assets, address[] memory sources) private {
        require(assets.length == sources.length, "array parameters should be equal");

        for (uint256 i = 0; i < assets.length; i++) {
            assetsSources[assets[i]] = IAggregator(sources[i]);
            emit AssetSourceUpdated(assets[i], sources[i]);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAggregator {
  function decimals() external view returns (uint8);
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title IOracle
 * @author LC
 * @notice Defines the basic interface for the Oracle
 */
interface IOracle {
    event AssetSourceUpdated(address indexed asset, address source);
    event AssetPriceUpdated(address indexed asset, uint256 price);

    /**
     * @notice Sets or replaces price sources of assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setAssetSources(address[] calldata assets, address[] calldata sources) external;

    /**
     * @notice Returns the asset price in the base currency
     * @param asset The address of the asset
     * @return The price of the asset
     */
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param assets The list of assets addresses
     * @return The prices of the given assets
     */
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    /**
     * @notice Returns the address of the source for an asset address
     * @param asset The address of the asset
     * @return The address of the source
     */
    function getSourceOfAsset(address asset) external view returns (address);
}