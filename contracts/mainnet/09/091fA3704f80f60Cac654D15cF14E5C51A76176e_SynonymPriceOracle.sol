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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISynonymPriceSource} from "../../interfaces/ISynonymPriceSource.sol";

/**
 * @title BaseSynonymPriceOracle
 */
abstract contract BaseSynonymPriceSource is ISynonymPriceSource, Ownable {
    uint256 public constant PRICE_PRECISION = 1e18;
    bytes32 public constant OUTPUT_ASSET_USD = keccak256("USD");
    bytes32 public constant OUTPUT_ASSET_ETH = keccak256("ETH");
    string public override outputAsset;

    constructor(string memory _outputAsset) Ownable(msg.sender) {
        outputAsset = _outputAsset;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BaseSynonymPriceSource} from "./BaseSynonymPriceSource.sol";
import {ISynonymPriceOracle, ISynonymPriceSource, AggregatorV3Interface} from "../../interfaces/ISynonymPriceOracle.sol";

/**
 * @title SynonymPriceOracle
 */
contract SynonymPriceOracle is ISynonymPriceOracle, BaseSynonymPriceSource {
    mapping(address => PriceSource) public sources;
    AggregatorV3Interface public override sequencerUptimeFeed;
    uint256 public override sequencerGracePeriod;

    error InvalidAsset();
    error InvalidPriceSource();
    error InvalidMaxPriceAge();
    error InvalidSequencerFeed();
    error InvalidGracePeriod();
    error SequencerDown();

    event PriceSourceSet(address indexed asset, ISynonymPriceSource priceSource, uint256 maxPriceAge);
    event SequencerUptimeFeedSet(address indexed sequencerUptimeFeed, uint256 gracePeriod);

    constructor(
        string memory _outputAsset,
        AggregatorV3Interface _sequencerUptimeFeed,
        uint256 _sequencerGracePeriod
    ) BaseSynonymPriceSource(_outputAsset) {
        sequencerUptimeFeed = _sequencerUptimeFeed;
        sequencerGracePeriod = _sequencerGracePeriod;
    }

    function priceAvailable(address _asset) public view override returns (bool) {
        return sources[_asset].priceSource != ISynonymPriceSource(address(0));
    }

    function getPrice(address _asset) public view override returns (ISynonymPriceOracle.Price memory price) {
        return getPrice(_asset, sources[_asset].maxPriceAge);
    }

    function getPrice(address _asset, uint256 _maxAge) public view override returns (ISynonymPriceOracle.Price memory price) {
        if (!priceAvailable(_asset)) {
            revert InvalidPriceSource();
        }

        if (!_sequencerUpAndGracePeriodPassed()) {
            revert SequencerDown();
        }

        return sources[_asset].priceSource.getPrice(_asset, _maxAge);
    }

    function setSequencerUptimeFeed(AggregatorV3Interface _feed, uint256 _gracePeriod) public onlyOwner {
        if (address(_feed) == address(0)) {
            revert InvalidSequencerFeed();
        }

        if (_gracePeriod == 0) {
            revert InvalidGracePeriod();
        }

        sequencerUptimeFeed = _feed;
        sequencerGracePeriod = _gracePeriod;
        emit SequencerUptimeFeedSet(address(_feed), _gracePeriod);
    }

    /**
     * @notice Checks the sequencer oracle is healthy: is up and grace period passed.
     * @return True if the SequencerOracle is up and the grace period passed, false otherwise
     */
    function _sequencerUpAndGracePeriodPassed() internal view returns (bool) {
        (, int256 answer, uint256 startedAt,, ) = sequencerUptimeFeed.latestRoundData();
        // zero means the sequencer is up. there is a grace period that needs to elapse before we start accepting prices again - for things to stabilize.
        // it also allows users to repay any underwater loans that have become liquidatable during the outage
        // see https://docs.chain.link/data-feeds/l2-sequencer-feeds for more info
        return answer == 0 && block.timestamp - startedAt > sequencerGracePeriod;
    }

    function setPriceSource(
        address _asset,
        PriceSource memory _priceSource
    ) external override onlyOwner {
        if (_asset == address(0)) {
            revert InvalidAsset();
        }
        if (_priceSource.priceSource == ISynonymPriceSource(address(0))) {
            revert InvalidPriceSource();
        }
        if (_priceSource.maxPriceAge == 0) {
            revert InvalidMaxPriceAge();
        }
        if (keccak256(abi.encodePacked(_priceSource.priceSource.outputAsset())) != keccak256(abi.encodePacked(outputAsset))) {
            revert InvalidPriceSource();
        }
        sources[_asset] = _priceSource;

        emit PriceSourceSet(_asset, _priceSource.priceSource, _priceSource.maxPriceAge);
    }

    function removePriceSource(address _asset) external onlyOwner {
        if (sources[_asset].priceSource == ISynonymPriceSource(address(0))) {
            revert InvalidPriceSource();
        }
        delete sources[_asset];
        emit PriceSourceSet(_asset, ISynonymPriceSource(address(0)), 0);
    }

    function getPriceSource(address _asset) external view override returns (PriceSource memory) {
        if (sources[_asset].priceSource == ISynonymPriceSource(address(0))) {
            revert InvalidAsset();
        }
        return sources[_asset];
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ISynonymPriceSource} from "./ISynonymPriceSource.sol";

interface ISynonymPriceOracle is ISynonymPriceSource {
    struct PriceSource {
        ISynonymPriceSource priceSource;
        uint256 maxPriceAge;
    }

    function sequencerUptimeFeed() external view returns (AggregatorV3Interface);
    function sequencerGracePeriod() external view returns (uint256);
    function getPrice(address _asset) external view returns (Price memory price);
    function setPriceSource(address _asset, PriceSource memory _priceSource) external;
    function removePriceSource(address _asset) external;
    function getPriceSource(address _asset) external view returns (PriceSource memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISynonymPriceSource {
    error NoPriceForAsset();
    error StalePrice();

    struct Price {
        uint256 price;
        uint256 confidence;
        uint256 precision;
        uint256 updatedAt;
    }

    function getPrice(address _asset, uint256 _maxAge) external view returns (Price memory price);
    function priceAvailable(address _asset) external view returns (bool);
    function outputAsset() external view returns (string memory);
}