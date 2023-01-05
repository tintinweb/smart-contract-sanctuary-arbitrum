// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface AggregatorV3Interface {
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

    function decimals() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ChainlinkOracle} from "./ChainlinkOracle.sol";
import {Errors} from "../utils/Errors.sol";
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

/**
    @title Arbitrum Chain Link Oracle
    @notice Oracle to fetch price using chainlink oracles on arbitrum
*/
contract ArbiChainlinkOracle is ChainlinkOracle {

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice L2 Sequencer feed
    AggregatorV3Interface public immutable sequencer;

    /// @notice L2 Sequencer grace period
    uint256 public constant GRACE_PERIOD_TIME = 3600;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract constructor
        @param _ethUsdPriceFeed ETH USD Chainlink price feed
        @param _sequencer L2 sequencer
    */
    constructor(
        AggregatorV3Interface _ethUsdPriceFeed,
        AggregatorV3Interface _sequencer
    )
        ChainlinkOracle(_ethUsdPriceFeed)
    {
        sequencer = _sequencer;
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ChainlinkOracle
    function getPrice(address token) public view override returns (uint) {
        if (!isSequencerActive()) revert Errors.L2SequencerUnavailable();
        return super.getPrice(token);
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    function isSequencerActive() internal view returns (bool) {
        (, int256 answer, uint256 startedAt,,) = sequencer.latestRoundData();
        if (block.timestamp - startedAt <= GRACE_PERIOD_TIME || answer == 1)
            return false;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOracle} from "../core/IOracle.sol";
import {Ownable} from "../utils/Ownable.sol";
import {Errors} from "../utils/Errors.sol";
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

/**
    @title Chain Link Oracle
    @notice Oracle to fetch price using chainlink oracles
*/
contract ChainlinkOracle is Ownable, IOracle {

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice ETH USD Chainlink price feed
    AggregatorV3Interface public immutable ethUsdPriceFeed;

    /// @notice Mapping of token to token/usd chainlink price feed
    mapping(address => AggregatorV3Interface) public feed;

    /// @notice HeatBeat of chainlink feed
    mapping(address => uint) public heartBeatOf;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event UpdateFeed(address indexed token, address indexed feed);

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract constructor
        @param _ethUsdPriceFeed ETH USD Chainlink price feed
    */
    constructor(AggregatorV3Interface _ethUsdPriceFeed) Ownable(msg.sender) {
        ethUsdPriceFeed = _ethUsdPriceFeed;
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IOracle
    /// @dev feed[token].latestRoundData should return price scaled by 8 decimals
    function getPrice(address token) public view virtual returns (uint) {
        (, int answer,, uint updatedAt,) =
            feed[token].latestRoundData();

        if (block.timestamp - updatedAt >= heartBeatOf[token])
            revert Errors.StalePrice(token, address(feed[token]));

        if (answer <= 0)
            revert Errors.NegativePrice(token, address(feed[token]));

        return (
            (uint(answer)*1e18)/getEthPrice()
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    function getEthPrice() internal view returns (uint) {
        (, int answer,, uint updatedAt,) =
            ethUsdPriceFeed.latestRoundData();

        if (block.timestamp - updatedAt >= 86400)
            revert Errors.StalePrice(address(0), address(ethUsdPriceFeed));

        if (answer <= 0)
            revert Errors.NegativePrice(address(0), address(ethUsdPriceFeed));

        return uint(answer);
    }

    /* -------------------------------------------------------------------------- */
    /*                               ADMIN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    function setFeed(
        address token,
        AggregatorV3Interface _feed,
        uint heartBeat
    ) external adminOnly {
        if (_feed.decimals() != 8) revert Errors.IncorrectDecimals();
        feed[token] = _feed;
        heartBeatOf[token] = heartBeat;
        emit UpdateFeed(token, address(_feed));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOracle {

    /**
        @notice Fetches price of a given token in terms of ETH
        @param token Address of token
        @return price Price of token in terms of ETH
    */
    function getPrice(address token) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface Errors {
    error AdminOnly();
    error ZeroAddress();
    error PriceUnavailable();
    error IncorrectDecimals();
    error L2SequencerUnavailable();
    error InactivePriceFeed(address feed);
    error StalePrice(address token, address feed);
    error NegativePrice(address token, address feed);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "./Errors.sol";

abstract contract Ownable {
    address public admin;

    event OwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);

    constructor(address _admin) {
        if (_admin == address(0)) revert Errors.ZeroAddress();
        admin = _admin;
    }

    modifier adminOnly() {
        if (admin != msg.sender) revert Errors.AdminOnly();
        _;
    }

    function transferOwnership(address newAdmin) external virtual adminOnly {
        if (newAdmin == address(0)) revert Errors.ZeroAddress();
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}