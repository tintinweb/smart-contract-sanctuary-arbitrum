// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DegenFetcherV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";


/**
 * @title The PriceFeeds contract
 * @notice A contract that returns latest price from Chainlink Price Feeds
 */
contract PriceFeeds is Ownable, DegenFetcherV2 {
    // TODO, Now directly get by price, can apply register in the future
    // tokenAddress=>priceFeedAddress
    mapping(address => address) priceFeedAddresses;

    constructor(address _tokenAddress, address _priceFeed) Ownable(_msgSender()) {
        priceFeedAddresses[_tokenAddress] = _priceFeed;
    }

    /**
     * @notice Returns the latest price
     *
     * @return latest price
     */

    //  TODO, should check updatTime, keep the price is the latest price
    function getLatestPrice(address tokenAddress) public view returns (int256) {
        (
            /* uint80 roundID */
            ,
            int256 price,
            /* uint256 startedAt */
            ,
            /* uint256 timeStamp */
            ,
            /* uint80 answeredInRound */
        ) = AggregatorV3Interface(priceFeedAddresses[tokenAddress]).latestRoundData();

        return price;
    }

    // Through degenFetcher, get historypirce
    // TODO how to config the params?
    function getHistoryPrice(address tokenAddress, uint256 timestamp) public view returns (int256) {
        int256 price = fetchPriceDataForFeed(priceFeedAddresses[tokenAddress], timestamp);
        return price;
    }

    /**
     * @notice Returns the Price Feed address
     *
     * @return Price Feed address
     */
    function getPriceFeed(address tokenAddress) public view returns (address) {
        return priceFeedAddresses[tokenAddress];
    }

    // TODO for test
    function description(address tokenAddress) public view returns (string memory) {
        return AggregatorV3Interface(priceFeedAddresses[tokenAddress]).description();
    }

    // TODO, below function should optimize
    function addPriceFeed(address tokenAddress, address priceFeedAddress) external onlyOwner {
        priceFeedAddresses[tokenAddress] = priceFeedAddress;
    }

    function priceFeedDecimals(address tokenAddress) public view returns (uint8) {
        return AggregatorV3Interface(priceFeedAddresses[tokenAddress]).decimals();
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

contract DegenFetcherV2 {
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
        uint256 fromTime
    )
        public
        view
        returns (uint80 firstRoundToSearch, uint80 numRoundsToSearch)
    {
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

        (uint80 fromRound, uint80 toRound) = binarySearchForTimestamp(feed, fromTime, lhRound, lhTime, rhRound, rhTime);
        return (fromRound, toRound);
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
        returns (uint80 targetRoundL, uint80 targetRoundR)
    {
        if (lhTime > targetTime) return (0, 0);

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
        return (lhRound, rhRound);
    }

    function getClosestPrice(
        AggregatorV2V3Interface feed,
        uint256 targetTimestamp,
        uint80 roundId1,
        uint80 roundId2
    )
        public
        view
        returns (int256 price)
    {
        (, int256 price1, uint256 timestamp1,,) = feed.getRoundData(roundId1);
        (, int256 price2, uint256 timestamp2,,) = feed.getRoundData(roundId2);
        uint256 diff1 = targetTimestamp > timestamp1 ? targetTimestamp - timestamp1 : timestamp1 - targetTimestamp;
        uint256 diff2 = targetTimestamp > timestamp2 ? targetTimestamp - timestamp2 : timestamp2 - targetTimestamp;

        if (diff1 < diff2) {
            return price1;
        } else {
            return price2;
        }
    }

    function fetchPriceDataForFeed(address feedAddress, uint256 targetTimestamp) public view returns (int32) {
        AggregatorV2V3Interface feed = AggregatorV2V3Interface(feedAddress);

        require(targetTimestamp > 0);

        (uint80 roundId1, uint80 roundId2) = guessSearchRoundsForTimestamp(feed, targetTimestamp);
        int256 price = getClosestPrice(feed, targetTimestamp, roundId1, roundId2);

        // return price;
        return int32(price / 10 ** 8);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
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