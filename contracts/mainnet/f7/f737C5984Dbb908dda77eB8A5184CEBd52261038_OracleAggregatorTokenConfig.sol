//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./IQuoteToken.sol";

/**
 * @title ILiquidityOracle
 * @notice An interface that defines a liquidity oracle with a single quote token (or currency) and many exchange
 *  tokens.
 */
abstract contract ILiquidityOracle is IUpdateable, IQuoteToken {
    /// @notice Gets the liquidity levels of the token and the quote token in the underlying pool.
    /// @param token The token to get liquidity levels of (along with the quote token).
    /// @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
    /// @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
    function consultLiquidity(
        address token
    ) public view virtual returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);

    /**
     * @notice Gets the liquidity levels of the token and the quote token in the underlying pool, reverting if the
     *  quotation is older than the maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get liquidity levels of (along with the quote token).
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source. WARNING: Using a maxAge of 0 is expensive and is generally insecure.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consultLiquidity(
        address token,
        uint256 maxAge
    ) public view virtual returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./ILiquidityOracle.sol";
import "./IPriceOracle.sol";

/**
 * @title IOracle
 * @notice An interface that defines a price and liquidity oracle.
 */
abstract contract IOracle is IUpdateable, IPriceOracle, ILiquidityOracle {
    /**
     * @notice Gets the price of a token in terms of the quote token along with the liquidity levels of the token
     *  andquote token in the underlying pool.
     * @param token The token to get the price of.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consult(
        address token
    ) public view virtual returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity);

    /**
     * @notice Gets the price of a token in terms of the quote token along with the liquidity levels of the token and
     *  quote token in the underlying pool, reverting if the quotation is older than the maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get the price of.
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source. WARNING: Using a maxAge of 0 is expensive and is generally insecure.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consult(
        address token,
        uint256 maxAge
    ) public view virtual returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity);

    function liquidityDecimals() public view virtual returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./IQuoteToken.sol";

/// @title IPriceOracle
/// @notice An interface that defines a price oracle with a single quote token (or currency) and many exchange tokens.
abstract contract IPriceOracle is IUpdateable, IQuoteToken {
    /**
     * @notice Gets the price of a token in terms of the quote token.
     * @param token The token to get the price of.
     * @return price The quote token denominated price for a whole token.
     */
    function consultPrice(address token) public view virtual returns (uint112 price);

    /**
     * @notice Gets the price of a token in terms of the quote token, reverting if the quotation is older than the
     *  maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get the price of.
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source. WARNING: Using a maxAge of 0 is expensive and is generally insecure.
     * @return price The quote token denominated price for a whole token.
     */
    function consultPrice(address token, uint256 maxAge) public view virtual returns (uint112 price);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IQuoteToken
 * @notice An interface that defines a contract containing a quote token (or currency), providing the associated
 *  metadata.
 */
abstract contract IQuoteToken {
    /// @notice Gets the quote token (or currency) name.
    /// @return The name of the quote token (or currency).
    function quoteTokenName() public view virtual returns (string memory);

    /// @notice Gets the quote token address (if any).
    /// @dev This may return address(0) if no specific quote token is used (such as an aggregate of quote tokens).
    /// @return The address of the quote token, or address(0) if no specific quote token is used.
    function quoteTokenAddress() public view virtual returns (address);

    /// @notice Gets the quote token (or currency) symbol.
    /// @return The symbol of the quote token (or currency).
    function quoteTokenSymbol() public view virtual returns (string memory);

    /// @notice Gets the number of decimal places that quote prices have.
    /// @return The number of decimals of the quote token (or currency) that quote prices have.
    function quoteTokenDecimals() public view virtual returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/// @title IUpdateByToken
/// @notice An interface that defines a contract that is updateable as per the input data.
abstract contract IUpdateable {
    /// @notice Performs an update as per the input data.
    /// @param data Any data needed for the update.
    /// @return b True if anything was updated; false otherwise.
    function update(bytes memory data) public virtual returns (bool b);

    /// @notice Checks if an update needs to be performed.
    /// @param data Any data relating to the update.
    /// @return b True if an update needs to be performed; false otherwise.
    function needsUpdate(bytes memory data) public view virtual returns (bool b);

    /// @notice Check if an update can be performed by the caller (if needed).
    /// @dev Tries to determine if the caller can call update with a valid observation being stored.
    /// @dev This is not meant to be called by state-modifying functions.
    /// @param data Any data relating to the update.
    /// @return b True if an update can be performed by the caller; false otherwise.
    function canUpdate(bytes memory data) public view virtual returns (bool b);

    /// @notice Gets the timestamp of the last update.
    /// @param data Any data relating to the update.
    /// @return A unix timestamp.
    function lastUpdateTime(bytes memory data) public view virtual returns (uint256);

    /// @notice Gets the amount of time (in seconds) since the last update.
    /// @param data Any data relating to the update.
    /// @return Time in seconds.
    function timeSinceLastUpdate(bytes memory data) public view virtual returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

library ObservationLibrary {
    struct ObservationMetadata {
        address oracle;
    }

    struct Observation {
        uint112 price;
        uint112 tokenLiquidity;
        uint112 quoteTokenLiquidity;
        uint32 timestamp;
    }

    struct MetaObservation {
        ObservationMetadata metadata;
        Observation data;
    }

    struct LiquidityObservation {
        uint112 tokenLiquidity;
        uint112 quoteTokenLiquidity;
        uint32 timestamp;
    }

    struct PriceObservation {
        uint112 price;
        uint32 timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

import "../strategies/aggregation/IAggregationStrategy.sol";
import "../strategies/validation/IValidationStrategy.sol";

/**
 * @title IOracleAggregator
 * @notice This interface defines the functions for an aggregator oracle. An aggregator oracle collects and processes
 * data from multiple underlying oracles to provide a single source of truth that is accurate and reliable.
 */
interface IOracleAggregator {
    /**
     * @dev Struct representing an individual oracle.
     * Contains the following properties:
     * - oracle: The address of the oracle (160 bits)
     * - priceDecimals: The number of decimals in the oracle's price data
     * - liquidityDecimals: The number of decimals in the oracle's liquidity data
     */
    struct Oracle {
        address oracle; // The oracle address, 160 bits
        uint8 priceDecimals; // The number of decimals of the price
        uint8 liquidityDecimals; // The number of decimals of the liquidity
    }

    /**
     * @notice Returns the aggregation strategy being used by the aggregator oracle for a given token.
     * @dev The aggregation strategy is used to aggregate the data from the underlying oracles.
     * @param token The address of the token for which the aggregation strategy is being requested.
     * @return strategy The instance of the IAggregationStrategy being used.
     */
    function aggregationStrategy(address token) external view returns (IAggregationStrategy strategy);

    /**
     * @notice Returns the validation strategy being used by the aggregator oracle for a given token.
     * @dev The validation strategy is used to validate the data from the underlying oracles before it is aggregated.
     * Results from the underlying oracles that do not pass validation will be ignored.
     * @param token The address of the token for which the validation strategy is being requested.
     * @return strategy The instance of the IValidationStrategy being used, or the zero address if no validation
     * strategy is being used.
     */
    function validationStrategy(address token) external view returns (IValidationStrategy strategy);

    /**
     * @notice Returns an array of Oracle structs representing the underlying oracles for a given token.
     * @param token The address of the token for which oracles are being requested.
     * @return oracles An array of Oracle structs for the given token.
     */
    function getOracles(address token) external view returns (Oracle[] memory oracles);

    /**
     * @notice Returns the minimum number of oracle responses required for the aggregator to push a new observation.
     * @param token The address of the token for which the minimum number of responses is being requested.
     * @return minimumResponses The minimum number of responses required.
     */
    function minimumResponses(address token) external view returns (uint256 minimumResponses);

    /**
     * @notice Returns the maximum age (in seconds) of an underlying oracle response for it to be considered valid.
     * @dev The maximum response age is used to prevent stale data from being aggregated.
     * @param token The address of the token for which the maximum response age is being requested.
     * @return maximumResponseAge The maximum response age in seconds.
     */
    function maximumResponseAge(address token) external view returns (uint256 maximumResponseAge);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "../../libraries/ObservationLibrary.sol";

/**
 * @title IAggregationStrategy
 * @notice Interface for implementing a strategy to aggregate data from a series of observations
 * within a specified range. This can be useful when working with time-weighted average prices,
 * volume-weighted average prices, or any other custom aggregation logic.
 *
 * Implementations of this interface can be used in a variety of scenarios, such as DeFi
 * protocols, on-chain analytics, and other smart contract applications.
 */
interface IAggregationStrategy {
    /**
     * @notice Aggregate the observations within the specified range and return the result
     * as a single Observation.
     *
     * The aggregation strategy can be customized to include various forms of logic,
     * such as calculating the median, mean, or mode of the observations.
     *
     * @dev The implementation of this function should perform input validation, such as
     * ensuring the provided range is valid (i.e., 'from' <= 'to'), and that the input
     * array of observations is not empty.
     *
     * @param token The address of the token for which to aggregate observations.
     * @param observations An array of MetaObservation structs containing the data to aggregate.
     * @param from The starting index (inclusive) of the range to aggregate from the observations array.
     * @param to The ending index (inclusive) of the range to aggregate from the observations array.
     *
     * @return ObservationLibrary.Observation memory An Observation struct containing the result
     * of the aggregation.
     */
    function aggregateObservations(
        address token,
        ObservationLibrary.MetaObservation[] calldata observations,
        uint256 from,
        uint256 to
    ) external view returns (ObservationLibrary.Observation memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "../../libraries/ObservationLibrary.sol";

/**
 * @title IValidationStrategy
 * @notice Interface for implementing validation strategies for observation data in a token pair.
 */
interface IValidationStrategy {
    /**
     * @notice Returns the number of decimals of the quote token.
     * @dev This is useful for validations involving prices, which are always expressed in the quote token.
     * @return The number of decimals for the quote token.
     */
    function quoteTokenDecimals() external view returns (uint8);

    /**
     * @notice Validates the given observation data for a token pair.
     * @param token The address of the token for which the observation data is being validated.
     * @param observation The observation data to be validated.
     * @return True if the observation passes validation; false otherwise.
     */
    function validateObservation(
        address token,
        ObservationLibrary.MetaObservation calldata observation
    ) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-core/contracts/oracles/IOracleAggregator.sol";

interface IOracleAggregatorTokenConfig {
    function aggregationStrategy() external view returns (IAggregationStrategy);

    function validationStrategy() external view returns (IValidationStrategy);

    function minimumResponses() external view returns (uint256);

    function oracles() external view returns (IOracleAggregator.Oracle[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-core/contracts/interfaces/IOracle.sol";

import "./IOracleAggregatorTokenConfig.sol";

contract OracleAggregatorTokenConfig is IOracleAggregatorTokenConfig {
    uint256 public constant MAX_ORACLES = 8;

    IAggregationStrategy public immutable override aggregationStrategy;

    IValidationStrategy public immutable override validationStrategy;

    uint256 public immutable override minimumResponses;

    uint256 internal immutable oraclesCount;

    address internal immutable oracle0Address;
    uint8 internal immutable oracle0PriceDecimals;
    uint8 internal immutable oracle0LiquidityDecimals;

    address internal immutable oracle1Address;
    uint8 internal immutable oracle1PriceDecimals;
    uint8 internal immutable oracle1LiquidityDecimals;

    address internal immutable oracle2Address;
    uint8 internal immutable oracle2PriceDecimals;
    uint8 internal immutable oracle2LiquidityDecimals;

    address internal immutable oracle3Address;
    uint8 internal immutable oracle3PriceDecimals;
    uint8 internal immutable oracle3LiquidityDecimals;

    address internal immutable oracle4Address;
    uint8 internal immutable oracle4PriceDecimals;
    uint8 internal immutable oracle4LiquidityDecimals;

    address internal immutable oracle5Address;
    uint8 internal immutable oracle5PriceDecimals;
    uint8 internal immutable oracle5LiquidityDecimals;

    address internal immutable oracle6Address;
    uint8 internal immutable oracle6PriceDecimals;
    uint8 internal immutable oracle6LiquidityDecimals;

    address internal immutable oracle7Address;
    uint8 internal immutable oracle7PriceDecimals;
    uint8 internal immutable oracle7LiquidityDecimals;

    uint256 internal constant ERROR_MISSING_ORACLES = 1;
    uint256 internal constant ERROR_MINIMUM_RESPONSES_TOO_SMALL = 2;
    uint256 internal constant ERROR_INVALID_AGGREGATION_STRATEGY = 3;
    uint256 internal constant ERROR_DUPLICATE_ORACLES = 4;
    uint256 internal constant ERROR_MINIMUM_RESPONSES_TOO_LARGE = 6;
    uint256 internal constant ERROR_INVALID_ORACLE = 7;
    uint256 internal constant ERROR_TOO_MANY_ORACLES = 8;

    error InvalidConfig(uint256 errorCode);

    constructor(
        IAggregationStrategy aggregationStrategy_,
        IValidationStrategy validationStrategy_,
        uint256 minimumResponses_,
        address[] memory oracles_
    ) {
        validateConstructorArgs(aggregationStrategy_, validationStrategy_, minimumResponses_, oracles_);

        aggregationStrategy = aggregationStrategy_;
        validationStrategy = validationStrategy_;
        minimumResponses = minimumResponses_;

        oraclesCount = oracles_.length;

        IOracleAggregator.Oracle[] memory oraclesCpy = new IOracleAggregator.Oracle[](MAX_ORACLES);

        for (uint256 i = 0; i < oracles_.length; ++i) {
            oraclesCpy[i] = IOracleAggregator.Oracle({
                oracle: oracles_[i],
                priceDecimals: IOracle(oracles_[i]).quoteTokenDecimals(),
                liquidityDecimals: IOracle(oracles_[i]).liquidityDecimals()
            });
        }

        oracle0Address = oraclesCpy[0].oracle;
        oracle0PriceDecimals = oraclesCpy[0].priceDecimals;
        oracle0LiquidityDecimals = oraclesCpy[0].liquidityDecimals;

        oracle1Address = oraclesCpy[1].oracle;
        oracle1PriceDecimals = oraclesCpy[1].priceDecimals;
        oracle1LiquidityDecimals = oraclesCpy[1].liquidityDecimals;

        oracle2Address = oraclesCpy[2].oracle;
        oracle2PriceDecimals = oraclesCpy[2].priceDecimals;
        oracle2LiquidityDecimals = oraclesCpy[2].liquidityDecimals;

        oracle3Address = oraclesCpy[3].oracle;
        oracle3PriceDecimals = oraclesCpy[3].priceDecimals;
        oracle3LiquidityDecimals = oraclesCpy[3].liquidityDecimals;

        oracle4Address = oraclesCpy[4].oracle;
        oracle4PriceDecimals = oraclesCpy[4].priceDecimals;
        oracle4LiquidityDecimals = oraclesCpy[4].liquidityDecimals;

        oracle5Address = oraclesCpy[5].oracle;
        oracle5PriceDecimals = oraclesCpy[5].priceDecimals;
        oracle5LiquidityDecimals = oraclesCpy[5].liquidityDecimals;

        oracle6Address = oraclesCpy[6].oracle;
        oracle6PriceDecimals = oraclesCpy[6].priceDecimals;
        oracle6LiquidityDecimals = oraclesCpy[6].liquidityDecimals;

        oracle7Address = oraclesCpy[7].oracle;
        oracle7PriceDecimals = oraclesCpy[7].priceDecimals;
        oracle7LiquidityDecimals = oraclesCpy[7].liquidityDecimals;
    }

    function oracles() external view virtual override returns (IOracleAggregator.Oracle[] memory) {
        uint256 count = oraclesCount;

        IOracleAggregator.Oracle[] memory result = new IOracleAggregator.Oracle[](count);

        if (count > 0) {
            result[0] = IOracleAggregator.Oracle({
                oracle: oracle0Address,
                priceDecimals: oracle0PriceDecimals,
                liquidityDecimals: oracle0LiquidityDecimals
            });
        }
        if (count > 1) {
            result[1] = IOracleAggregator.Oracle({
                oracle: oracle1Address,
                priceDecimals: oracle1PriceDecimals,
                liquidityDecimals: oracle1LiquidityDecimals
            });
        }
        if (count > 2) {
            result[2] = IOracleAggregator.Oracle({
                oracle: oracle2Address,
                priceDecimals: oracle2PriceDecimals,
                liquidityDecimals: oracle2LiquidityDecimals
            });
        }
        if (count > 3) {
            result[3] = IOracleAggregator.Oracle({
                oracle: oracle3Address,
                priceDecimals: oracle3PriceDecimals,
                liquidityDecimals: oracle3LiquidityDecimals
            });
        }
        if (count > 4) {
            result[4] = IOracleAggregator.Oracle({
                oracle: oracle4Address,
                priceDecimals: oracle4PriceDecimals,
                liquidityDecimals: oracle4LiquidityDecimals
            });
        }
        if (count > 5) {
            result[5] = IOracleAggregator.Oracle({
                oracle: oracle5Address,
                priceDecimals: oracle5PriceDecimals,
                liquidityDecimals: oracle5LiquidityDecimals
            });
        }
        if (count > 6) {
            result[6] = IOracleAggregator.Oracle({
                oracle: oracle6Address,
                priceDecimals: oracle6PriceDecimals,
                liquidityDecimals: oracle6LiquidityDecimals
            });
        }
        if (count > 7) {
            result[7] = IOracleAggregator.Oracle({
                oracle: oracle7Address,
                priceDecimals: oracle7PriceDecimals,
                liquidityDecimals: oracle7LiquidityDecimals
            });
        }

        return result;
    }

    function validateConstructorArgs(
        IAggregationStrategy aggregationStrategy_,
        IValidationStrategy,
        uint256 minimumResponses_,
        address[] memory oracles_
    ) internal view virtual {
        if (oracles_.length == 0) revert InvalidConfig(ERROR_MISSING_ORACLES);
        if (oracles_.length > MAX_ORACLES) revert InvalidConfig(ERROR_TOO_MANY_ORACLES);
        if (minimumResponses_ == 0) revert InvalidConfig(ERROR_MINIMUM_RESPONSES_TOO_SMALL);
        if (minimumResponses_ > oracles_.length) revert InvalidConfig(ERROR_MINIMUM_RESPONSES_TOO_LARGE);
        if (address(aggregationStrategy_) == address(0)) revert InvalidConfig(ERROR_INVALID_AGGREGATION_STRATEGY);

        // Validate that there are no duplicate oracles and that no oracle is the zero address.
        for (uint256 i = 0; i < oracles_.length; ++i) {
            if (oracles_[i] == address(0)) revert InvalidConfig(ERROR_INVALID_ORACLE);

            for (uint256 j = i + 1; j < oracles_.length; ++j) {
                if (oracles_[i] == oracles_[j]) revert InvalidConfig(ERROR_DUPLICATE_ORACLES);
            }
        }
    }
}