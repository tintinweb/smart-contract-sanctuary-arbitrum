// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DegenFetcher.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title PriceFeedManager
/// @notice Manages multiple Chainlink price feeds and provides the latest and historical price data.
/// @dev Inherits from Ownable for access control and DegenFetcher for fetching historical data.
contract PriceFeedManager is Ownable, DegenFetcher {
    /// @notice Maps feed IDs to their corresponding Chainlink price feed addresses.
    mapping(uint16 => address) public priceFeedAddresses;

    /// @notice Emitted when a new price feed is added.
    /// @param feedId The identifier of the feed.
    /// @param feedAddress The address of the Chainlink price feed.
    event PriceFeedAdded(uint16 indexed feedId, address indexed feedAddress);

    /// @notice Emitted when a price feed is removed.
    /// @param feedId The identifier of the feed.
    event PriceFeedRemoved(uint16 indexed feedId);

    /// @notice Emitted when a price is queried from a feed.
    /// @param feedId The identifier of the feed.
    /// @param price The latest price retrieved.
    event PriceQueried(uint16 indexed feedId, int256 price);

    /// @notice Indicates an attempt to interact with a feed that already exists.
    error FeedAlreadyExists(uint16 feedId);

    /// @notice Indicates an attempt to interact with a feed that does not exist.
    error FeedDoesNotExist(uint16 feedId);

    /// @notice Indicates an unauthorized attempt to perform an operation.
    error Unauthorized();

    /// @notice Initializes the contract setting the owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Adds a new price feed to the manager.
    /// @param _feedId The identifier for the new price feed.
    /// @param priceFeedAddress The address of the Chainlink price feed contract.
    /// @dev Reverts if the feed already exists.
    function addPriceFeed(uint16 _feedId, address priceFeedAddress) external onlyOwner {
        if (priceFeedAddresses[_feedId] != address(0)) {
            revert FeedAlreadyExists(_feedId);
        }
        priceFeedAddresses[_feedId] = priceFeedAddress;
        emit PriceFeedAdded(_feedId, priceFeedAddress);
    }

    /// @notice Removes an existing price feed from the manager.
    /// @param _feedId The identifier of the price feed to remove.
    /// @dev Reverts if the feed does not exist.
    function removePriceFeed(uint16 _feedId) external onlyOwner {
        if (priceFeedAddresses[_feedId] == address(0)) {
            revert FeedDoesNotExist(_feedId);
        }
        delete priceFeedAddresses[_feedId];
        emit PriceFeedRemoved(_feedId);
    }

    /// @notice Retrieves the latest price from a specified feed.
    /// @param _feedId The identifier of the feed.
    /// @return price The latest price from the feed.
    /// @dev Reverts if the feed does not exist.
    function getLatestPrice(uint16 _feedId) public returns (int256) {
        if (priceFeedAddresses[_feedId] == address(0)) {
            revert FeedDoesNotExist(_feedId);
        }
        (,int256 price,,,) = AggregatorV3Interface(priceFeedAddresses[_feedId]).latestRoundData();
        emit PriceQueried(_feedId, price);
        return price;
    }

    /// @notice Retrieves historical price data for a specified feed and averages it.
    /// @param _feedId The identifier of the feed.
    /// @param timestamp The timestamp for historical data retrieval.
    /// @return average The average price calculated from the historical data.
    /// @dev Uses DegenFetcher to fetch the data.
    function getHistoryPrice(uint16 _feedId, uint256 timestamp) public view returns (int256) {
        if (priceFeedAddresses[_feedId] == address(0)) {
            revert FeedDoesNotExist(_feedId);
        }
        int32[] memory prices = fetchPriceDataForFeed(priceFeedAddresses[_feedId], timestamp, uint80(1), uint256(48));
        int256 average = int256(calculatePriceAverage(prices));
        return average;
    }

    /// @notice Returns the description of the specified feed.
    /// @param _feedId The identifier of the feed.
    /// @return The description of the feed.
    function description(uint16 _feedId) public view returns (string memory) {
        if (priceFeedAddresses[_feedId] == address(0)) {
            revert FeedDoesNotExist(_feedId);
        }
        return AggregatorV3Interface(priceFeedAddresses[_feedId]).description();
    }

    /// @notice Returns the number of decimals used in the specified feed.
    /// @param _feedId The identifier of the feed.
    /// @return The number of decimals used by the feed.
    function priceFeedDecimals(uint16 _feedId) public view returns (uint8) {
        if (priceFeedAddresses[_feedId] == address(0)) {
            revert FeedDoesNotExist(_feedId);
        }
        return AggregatorV3Interface(priceFeedAddresses[_feedId]).decimals();
    }

    /// @notice Calculates the average of an array of prices.
    /// @param data The array of prices to average.
    /// @return The calculated average price.
    function calculatePriceAverage(int32[] memory data) public pure returns (int32) {
        int256 sum = 0;
        uint256 count = 0;

        for(uint i = 0; i < data.length; i++) {
            if(data[i] != 0) {
                sum += int256(data[i]);
                count++;
            }
        }

        if (count == 0) {
            return 0;
        } else {
            return int32(sum / int256(count));
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
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract DegenFetcher {
    uint80 constant SECONDS_PER_DAY = 3600 * 24;

    function getPhaseForTimestamp(
        AggregatorV2V3Interface feed,
        uint256 targetTime
    )
        public
        view
        returns (uint80, uint256, uint80)
    {
        uint16 currentPhase = uint16(feed.latestRound() >> 64);
        uint80 firstRoundOfCurrentPhase = (uint80(currentPhase) << 64) + 1;

        for (uint16 phase = currentPhase; phase >= 1; phase--) {
            uint80 firstRoundOfPhase = (uint80(phase) << 64) + 1;
            uint256 firstTimeOfPhase = feed.getTimestamp(firstRoundOfPhase);

            if (targetTime > firstTimeOfPhase) {
                return (firstRoundOfPhase, firstTimeOfPhase, firstRoundOfCurrentPhase);
            }
        }
        return (0, 0, firstRoundOfCurrentPhase);
    }

    function guessSearchRoundsForTimestamp(
        AggregatorV2V3Interface feed,
        uint256 fromTime,
        uint80 daysToFetch
    )
        public
        view
        returns (uint80 firstRoundToSearch, uint80 numRoundsToSearch)
    {
        uint256 toTime = fromTime + SECONDS_PER_DAY * daysToFetch;

        (uint80 lhRound, uint256 lhTime, uint80 firstRoundOfCurrentPhase) = getPhaseForTimestamp(feed, fromTime);

        uint80 rhRound;
        uint256 rhTime;
        if (lhRound == 0) {
            // Date is too far in the past, no data available
            return (0, 0);
        } else if (lhRound == firstRoundOfCurrentPhase) {
            // Data is in the current phase
            (rhRound,, rhTime,,) = feed.latestRoundData();
        } else {
            // No good way to get last round of phase from Chainlink feed, so our binary search function will have to
            // use trial & error.
            // Use 2**16 == 65536 as a upper bound on the number of rounds to search in a single Chainlink phase.

            rhRound = lhRound + 2 ** 16;
            rhTime = 0;
        }

        uint80 fromRound = binarySearchForTimestamp(feed, fromTime, lhRound, lhTime, rhRound, rhTime);
        uint80 toRound = binarySearchForTimestamp(feed, toTime, fromRound, fromTime, rhRound, rhTime);
        return (fromRound, toRound - fromRound);
    }

    function binarySearchForTimestamp(
        AggregatorV2V3Interface feed,
        uint256 targetTime,
        uint80 lhRound,
        uint256 lhTime,
        uint80 rhRound,
        uint256 rhTime
    )
        public
        view
        returns (uint80 targetRound)
    {
        if (lhTime > targetTime) return 0;

        uint80 guessRound = rhRound;
        while (rhRound - lhRound > 1) {
            guessRound = uint80(int80(lhRound) + int80(rhRound - lhRound) / 2);
            uint256 guessTime = feed.getTimestamp(uint256(guessRound));
            if (guessTime == 0 || guessTime > targetTime) {
                (rhRound, rhTime) = (guessRound, guessTime);
            } else if (guessTime < targetTime) {
                (lhRound, lhTime) = (guessRound, guessTime);
            }
        }
        return guessRound;
    }

    function roundIdsToSearch(
        AggregatorV2V3Interface feed,
        uint256 fromTimestamp,
        uint80 daysToFetch,
        uint256 dataPointsToFetchPerDay
    )
        public
        view
        returns (uint80[] memory)
    {
        (uint80 startingId, uint80 numRoundsToSearch) = guessSearchRoundsForTimestamp(feed, fromTimestamp, daysToFetch);

        uint80 fetchFilter = uint80(numRoundsToSearch / (daysToFetch * dataPointsToFetchPerDay));
        if (fetchFilter < 1) {
            fetchFilter = 1;
        }
        uint80[] memory roundIds = new uint80[](numRoundsToSearch / fetchFilter);

        // Snap startingId to a round that is a multiple of fetchFilter. This prevents the perpetual jam from changing
        // more often than
        // necessary, and keeps it aligned with the daily prints.
        startingId -= startingId % fetchFilter;

        for (uint80 i = 0; i < roundIds.length; i++) {
            roundIds[i] = startingId + i * fetchFilter;
        }
        return roundIds;
    }

    function fetchPriceData(
        AggregatorV2V3Interface feed,
        uint256 fromTimestamp,
        uint80 daysToFetch,
        uint256 dataPointsToFetchPerDay
    )
        public
        view
        returns (int32[] memory)
    {
        uint80[] memory roundIds = roundIdsToSearch(feed, fromTimestamp, daysToFetch, dataPointsToFetchPerDay);
        uint256 dataPointsToReturn;
        if (roundIds.length == 0) {
            dataPointsToReturn = 0;
        } else {
            dataPointsToReturn = dataPointsToFetchPerDay * daysToFetch; // Number of data points to return
        }
        uint256 secondsBetweenDataPoints = SECONDS_PER_DAY / dataPointsToFetchPerDay;

        int32[] memory prices = new int32[](dataPointsToReturn);

        uint80 latestRoundId = uint80(feed.latestRound());
        for (uint80 i = 0; i < roundIds.length; i++) {
            if (roundIds[i] != 0 && roundIds[i] < latestRoundId) {
                (, int256 price, uint256 timestamp,,) = feed.getRoundData(roundIds[i]);

                if (timestamp >= fromTimestamp) {
                    uint256 segmentsSinceStart = (timestamp - fromTimestamp) / secondsBetweenDataPoints;
                    if (segmentsSinceStart < prices.length) {
                        prices[segmentsSinceStart] = int32(price / 10 ** 8);
                    }
                }
            }
        }

        return prices;
    }

    function fetchPriceDataForFeed(
        address feedAddress,
        uint256 fromTimestamp,
        uint80 daysToFetch,
        uint256 dataPointsToFetchPerDay
    )
        public
        view
        returns (int32[] memory)
    {
        AggregatorV2V3Interface feed = AggregatorV2V3Interface(feedAddress);

        require(fromTimestamp > 0);

        int32[] memory prices = fetchPriceData(feed, fromTimestamp, daysToFetch, dataPointsToFetchPerDay);
        return prices;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}