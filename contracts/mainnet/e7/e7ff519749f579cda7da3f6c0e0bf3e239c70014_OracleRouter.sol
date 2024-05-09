// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import { IOracleRouter } from "./interfaces/IOracleRouter.sol";
import { Errors } from "./libraries/Errors.sol";
import { IAggregatorV2V3 } from "./interfaces/IAggregatorV2V3.sol";
import { IPyth } from "./interfaces/IPyth.sol";
import { PythStructs } from "./interfaces/PythStructs.sol";

contract OracleRouter is Ownable, IOracleRouter {
    struct PriceFeedData {
        /// required by Chainlink
        address feedAddress;
        /// required by Pyth and API3
        bytes32 feedId;
        uint256 heartbeat;
        OracleProviderType oracleProviderType;
        bool isSet;
    }

    struct OracleProvider {
        address oracleProviderAddress;
        function(PriceFeedData memory) view returns (bool, uint256) getPrice;
    }

    //////////////// <*_*> Storage <*_*> ////////////////
    mapping(address => PriceFeedData) public feeds;
    mapping(address => PriceFeedData) public fallbackFeeds;
    mapping(IOracleRouter.OracleProviderType => OracleProvider) private oracleProviders;

    ////////////////// =^..^= Events =^..^= //////////////////
    event FeedUpdated(address asset, address feedAddress, bytes32 feedId, uint256 heartbeat);
    event FallbackFeedUpdated(address asset, address feedAddress, bytes32 feedId, uint256 heartbeat);
    event PricesUpdated();

    constructor(address _pyth) Ownable() {
        oracleProviders[OracleProviderType.Chainlink] = OracleProvider(address(0x0), _getChainlinkPrice);
        oracleProviders[OracleProviderType.Pyth] = OracleProvider(_pyth, _getPythPrice);
    }

    ////////////////// ô¿ô External and Public Functions ô¿ô //////////////////
    receive() external payable { }

    /// @notice Get the price of an asset
    /// @param asset The address of the asset
    function getAssetPrice(address asset) public view override returns (uint256) {
        PriceFeedData memory feed = feeds[address(asset)];

        if (!feed.isSet) {
            revert Errors.NoFeedSet();
        }

        bool success;
        uint256 price;
        (success, price) = oracleProviders[feed.oracleProviderType].getPrice(feed);
        // If the price is not available, try the fallback feed
        if (!success) {
            feed = fallbackFeeds[address(asset)];
            // If there is no fallback feed, revert
            if (!feed.isSet) {
                revert Errors.NoFallbackFeedSet();
            }
            (success, price) = oracleProviders[feed.oracleProviderType].getPrice(feed);
            // If the price is not available from the fallback feed, revert
            if (!success) {
                revert Errors.NoPriceAvailable();
            }
        }
        // Price cannot be 0
        if (price == 0) {
            revert Errors.NoPriceAvailable();
        }
        return price;
    }

    /// @notice Get the prices of multiple assets
    /// @param assets The addresses of the assets
    /// @return uint256[] The prices of the assets
    function getAssetsPrices(address[] calldata assets) external view override returns (uint256[] memory) {
        uint256 length = assets.length;
        uint256[] memory prices = new uint256[](length);
        for (uint256 i = 0; i < length;) {
            prices[i] = getAssetPrice(assets[i]);
            unchecked {
                i++;
            }
        }
        return prices;
    }

    /// @notice Get the source of an asset. Tries to get the primary feed, then the fallback feed address
    /// @notice If no feed is set, returns address(0)
    /// @param asset The address of the asset
    /// @return address The address of the feed
    function getSourceOfAsset(address asset) external view override returns (address) {
        PriceFeedData memory feed = feeds[address(asset)];
        if (feed.isSet) {
            return feed.feedAddress;
            // Check fallback feed if no primary feed is set
        } else {
            feed = fallbackFeeds[address(asset)];
            if (feed.isSet) {
                return feed.feedAddress;
            }
        }
        return address(0);
    }

    /// @notice Set the source of an asset
    /// @param _asset The address of the asset
    /// @param _feedAddress The address of the feed
    /// @param _feedId The id of the feed
    /// @param _heartbeat The heartbeat of the feed
    /// @param _oracleType The type of the oracle, CL is 0, Pyth is 1 and so on
    /// @param isFallback True if the feed is a fallback
    function setAssetSource(
        address _asset,
        address _feedAddress,
        bytes32 _feedId,
        uint256 _heartbeat,
        IOracleRouter.OracleProviderType _oracleType,
        bool isFallback
    ) external override onlyOwner {
        _setAssetSource(_asset, _feedAddress, _feedId, _heartbeat, _oracleType, isFallback);
    }

    /**
     * @notice Updates multiple price feeds on Pyth oracle
     * @param priceUpdateData received from Pyth network and used to update the oracle
     */
    function updateUnderlyingPrices(bytes[] calldata priceUpdateData) external override {
        IPyth pyth = IPyth(oracleProviders[OracleProviderType.Pyth].oracleProviderAddress);
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{ value: fee }(priceUpdateData);

        emit PricesUpdated();
    }

    ////////////////// ô¿ô Internal Functions ô¿ô  //////////////////

    /// @notice Get the underlying price of an asset from a Chainlink aggregator
    /// @param feed The feed data
    /// @return bool True if the price is available, false if not
    /// @return uint256 The price of the asset
    function _getChainlinkPrice(PriceFeedData memory feed) internal view returns (bool, uint256) {
        IAggregatorV2V3 chainlinkAggregator = IAggregatorV2V3(feed.feedAddress);
        uint256 decimalDelta = uint256(18) - (chainlinkAggregator.decimals());
        (, int256 answer,, uint256 updatedAt,) = chainlinkAggregator.latestRoundData();
        return
            block.timestamp <= updatedAt + feed.heartbeat ? (true, uint256(answer) * (10 ** decimalDelta)) : (false, 0);
    }

    /// @notice return price of an asset from Pyth
    /// @param feed contains feedId required by Pyth
    /// @return bool True if the price is available, false if not
    /// @return uint256 The price of the asset scaled to 1e18
    function _getPythPrice(PriceFeedData memory feed) internal view returns (bool, uint256) {
        IPyth pyth = IPyth(oracleProviders[OracleProviderType.Pyth].oracleProviderAddress);

        PythStructs.Price memory priceData = pyth.getPriceUnsafe(feed.feedId);
        return block.timestamp <= priceData.publishTime + feed.heartbeat
            ? (true, uint256(int256(priceData.price)) * (10 ** (18 - SignedMath.abs(priceData.expo))))
            : (false, 0);
    }

    /// @notice Internal function to set the source of an asset
    /// @param _asset The address of the asset
    /// @param _feedAddress The address of the feed
    /// @param _feedId The id of the feed
    /// @param _heartbeat The heartbeat of the feed
    /// @param _oracleType The type of the oracle
    /// @param isFallback True if the feed is a fallback
    function _setAssetSource(
        address _asset,
        address _feedAddress,
        bytes32 _feedId,
        uint256 _heartbeat,
        IOracleRouter.OracleProviderType _oracleType,
        bool isFallback
    ) internal {
        if (_oracleType == OracleProviderType.Chainlink) {
            if (_feedAddress == address(0)) {
                revert Errors.InvalidFeed();
            }
        } else if (_oracleType == OracleProviderType.Pyth) {
            if (_feedId == bytes32(0) && _feedAddress != address(0)) {
                revert Errors.InvalidFeed();
            }
        } else {
            revert Errors.InvalidOracleProviderType();
        }

        if (!isFallback) {
            feeds[_asset] = PriceFeedData(_feedAddress, _feedId, _heartbeat, _oracleType, true);
            emit FeedUpdated(_asset, _feedAddress, _feedId, _heartbeat);
        } else {
            fallbackFeeds[_asset] = PriceFeedData(_feedAddress, _feedId, _heartbeat, _oracleType, true);
            emit FallbackFeedUpdated(_asset, _feedAddress, _feedId, _heartbeat);
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@radiant-v2-core/interfaces/IPriceOracleGetter.sol";

interface IOracleRouter is IPriceOracleGetter {
    enum OracleProviderType {
        Chainlink,
        Pyth
    }
    // TODO: Add more oracle providers
    /**
     * @notice Get the underlying price of a kToken asset
     * @param asset to get the underlying price of
     * @return The underlying asset price
     *  Zero means the price is unavailable.
     */

    /// @notice Gets a list of prices from a list of assets addresses
    /// @param assets The list of assets addresses
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    /// @notice Gets the address of the source for an asset address
    /// @param asset The address of the asset
    /// @return address The address of the source
    function getSourceOfAsset(address asset) external view returns (address);

    /// @notice Set the source of an asset
    /// @param _asset The address of the asset
    /// @param _feedAddress The address of the feed
    /// @param _feedId The id of the feed
    /// @param _heartbeat The heartbeat of the feed
    /// @param _oracleType The type of the oracle
    /// @param isFallback True if the feed is a fallback
    function setAssetSource(
        address _asset,
        address _feedAddress,
        bytes32 _feedId,
        uint256 _heartbeat,
        OracleProviderType _oracleType,
        bool isFallback
    ) external;

    /**
     * @notice Updates multiple price feeds on Pyth oracle
     * @param priceUpdateData received from Pyth network and used to update the oracle
     */
    function updateUnderlyingPrices(bytes[] calldata priceUpdateData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Errors {
    // Common errors
    error NoFeedSet();
    error NoFallbackFeedSet();
    error NoPriceAvailable();
    error NotAContract();
    error PoolDisabled();
    error PoolNotDisabled();
    // Oracle specific errors
    error RoundNotComplete();

    // Oracles General errors
    error InvalidOracleProviderType();
    error InvalidFeed();

    // Riz Registry errors
    error PoolRegisteredAlready();
    error NoAddressProvider();

    // Riz LockZap errors
    error AddressZero();

    error CannotRizZap();

    error InvalidLendingPool();

    error InvalidRatio();

    error InvalidLockLength();

    error AmountZero();

    error SlippageTooHigh();

    error SpecifiedSlippageExceedLimit();

    error InvalidZapETHSource();

    error ReceivedETHOnAlternativeAssetZap();

    error InsufficientETH();

    error EthTransferFailed();

    error SwapFailed(address asset, uint256 amount);

    error WrongRoute(address fromToken, address toToken);

    // Riz Leverager errors
    error ReceiveNotAllowed();

    error FallbackNotAllowed();

    error InsufficientPermission();

    /// @notice Disallow a loop count of 0
    error InvalidLoopCount();

    /// @notice Thrown when deployer sets the margin too high
    error MarginTooHigh();

    // Bad Debt Manager errors
    error OnlyLendingPool();
    error UserAlreadyWithdrawn();
    error BadDebtIsZero();
    error UserAllowanceZero();
    error NotEmergencyAdmin();
    error InvalidAssetsLength();
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/**
 * @title The V2 & V3 Aggregator Interface
 * @notice Solidity V0.5 does not allow interfaces to inherit from other
 * interfaces so this contract is a combination of v0.5 AggregatorInterface.sol
 * and v0.5 AggregatorV3Interface.sol.
 */
interface IAggregatorV2V3 {
    //
    // V2 Interface:
    //
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

    //
    // V3 Interface:
    //
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices
/// safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint256 validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(bytes32 id, uint256 age) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(bytes32 id, uint256 age) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within
    /// `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256 feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint256 publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Aave price oracle.
 **/

interface IPriceOracleGetter {
	/**
	 * @dev returns the asset price in ETH
	 * @param asset the address of the asset
	 * @return the ETH price of the asset
	 **/
	function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(bytes32 indexed id, uint64 publishTime, int64 price, uint64 conf);

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}