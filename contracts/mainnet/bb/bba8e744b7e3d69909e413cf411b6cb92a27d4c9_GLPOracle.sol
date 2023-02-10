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

import {Errors} from "../utils/Errors.sol";
import {IOracle} from "../core/IOracle.sol";
import {IGLPManager} from "./IGLPManager.sol";
import {AggregatorV3Interface} from "../chainlink/AggregatorV3Interface.sol";

/**
 * @title GLP Oracle
 */
contract GLPOracle is IOracle {
    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice address of gmx manager
    IGLPManager public immutable manager;

    /// @notice ETH USD Chainlink price feed
    AggregatorV3Interface immutable ethUsdPriceFeed;

    /// @notice L2 Sequencer feed
    AggregatorV3Interface immutable sequencer;

    /// @notice L2 Sequencer grace period
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Contract constructor
     *     @param _manager address of gmx vault
     *     @param _ethFeed address of eth usdc chainlink feed
     */
    constructor(IGLPManager _manager, AggregatorV3Interface _ethFeed, AggregatorV3Interface _sequencer) {
        manager = _manager;
        ethUsdPriceFeed = _ethFeed;
        sequencer = _sequencer;
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IOracle
    function getPrice(address) external view returns (uint256) {
        if (!isSequencerActive()) revert Errors.L2SequencerUnavailable();
        return manager.getPrice(false) / (getEthPrice() * 1e4);
    }

    function getEthPrice() internal view returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = ethUsdPriceFeed.latestRoundData();

        if (block.timestamp - updatedAt >= 86400) {
            revert Errors.StalePrice(address(0), address(ethUsdPriceFeed));
        }

        if (answer <= 0) {
            revert Errors.NegativePrice(address(0), address(ethUsdPriceFeed));
        }

        return uint256(answer);
    }

    function isSequencerActive() internal view returns (bool) {
        (, int256 answer, uint256 startedAt,,) = sequencer.latestRoundData();
        if (block.timestamp - startedAt <= GRACE_PERIOD_TIME || answer == 1) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGLPManager {
    function getPrice(bool maximise) external view returns (uint256);
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