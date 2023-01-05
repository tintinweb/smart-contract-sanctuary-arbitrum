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
import {AggregatorV3Interface} from "../chainlink/AggregatorV3Interface.sol";

interface ICurvePool {
    function A() external view returns (uint256);
    function gamma() external view returns (uint256);
    function virtual_price() external view returns (uint256);
    function price_oracle(uint256) external view returns (uint256);
}

/**
    @title Curve tri crypto oracle
    @notice Price Oracle for crv3crypto
*/
contract CurveTriCryptoOracle is IOracle {

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice curve tricrypto pool
    ICurvePool public immutable pool;

    /// @notice ETH USD Chainlink price feed
    AggregatorV3Interface public immutable ethUSDFeed;

    /// @notice WBTC USD Chainlink price feed
    AggregatorV3Interface public immutable btcUSDFeed;

    /// @notice USDT USD Chainlink price feed
    AggregatorV3Interface public immutable usdtUSDFeed;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract constructor
        @param _ethUSDFeed eth/usd feed
        @param _btcUSDFeed btc/usd feed
        @param _usdtUSDFeed usdt/usd feed
    */
    constructor(
        AggregatorV3Interface _ethUSDFeed,
        AggregatorV3Interface _btcUSDFeed,
        AggregatorV3Interface _usdtUSDFeed,
        ICurvePool _pool
    ) {
        ethUSDFeed = _ethUSDFeed;
        btcUSDFeed = _btcUSDFeed;
        usdtUSDFeed = _usdtUSDFeed;
        pool = _pool;
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IOracle
    function getPrice(address) external view returns (uint) {
        uint ethPrice = getPriceFromCL(ethUSDFeed);

        return lp_price(
            getPriceFromCL(btcUSDFeed) * 1e10,
            ethPrice * 1e10,
            getPriceFromCL(usdtUSDFeed) * 1e10
        ) * 1e8 / ethPrice;
    }

    function getPriceFromCL(AggregatorV3Interface _feed) internal view returns (uint) {
        (, int answer,, uint updatedAt,) =
            _feed.latestRoundData();

        if (block.timestamp - updatedAt >= 86400)
            revert Errors.StalePrice(address(0), address(_feed));

        if (answer <= 0)
            revert Errors.NegativePrice(address(0), address(_feed));

        return uint(answer);
    }

    function lp_price(uint p1, uint p2, uint p3) internal view returns(uint) {
        return 3 * ICurvePool(pool).virtual_price() *
            cubicRoot(p1 * p2 / 1e18 * p3) / 1e18;
    }

    function cubicRoot(uint x) internal pure returns (uint) {
        uint D = x / 1e18;
        for (uint i; i < 255;) {
            uint D_prev = D;
            D = D * (2e18 + x / D * 1e18 / D * 1e18 / D) / (3e18);
            uint diff = (D > D_prev) ? D - D_prev : D_prev - D;
            if (diff < 2 || diff * 1e18 < D) return D;
            unchecked { ++i; }
        }
        revert("Did Not Converge");
    }
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