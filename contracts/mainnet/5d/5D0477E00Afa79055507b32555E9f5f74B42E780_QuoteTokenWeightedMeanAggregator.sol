// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";

import "./IAggregationStrategy.sol";

/**
 * @title AbstractAggregator
 * @notice An abstract contract that implements the IAggregationStrategy interface and provides
 * utility functions for aggregation strategy implementations.
 *
 * This contract should be inherited by custom aggregator implementations that want to leverage
 * the utility functions to validate input parameters and prepare the aggregated result.
 *
 * @dev This contract cannot be deployed directly and should be inherited by another contract.
 * All inheriting contracts must implement the aggregateObservations function as required
 * by the IAggregationStrategy interface.
 */
abstract contract AbstractAggregator is IERC165, IAggregationStrategy {
    /// @notice An error thrown when the price value exceeds the maximum allowed value for uint112.
    error PriceTooHigh(uint256 price);

    /// @notice An error thrown when the observations array doesn't have enough elements.
    error InsufficientObservations(uint256 provided, uint256 required);

    /// @notice An error thrown when the from index is greater than the to index.
    error BadInput();

    // @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAggregationStrategy).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice Prepares the aggregated result by validating and converting the calculated
     * price, token liquidity, and quote token liquidity values to their respective types.
     *
     * @dev This function should be called by inheriting contracts after performing any custom
     * aggregation logic to prepare the result for return.
     *
     * @param price The calculated price value.
     * @param tokenLiquidity The calculated token liquidity value.
     * @param quoteTokenLiquidity The calculated quote token liquidity value.
     *
     * @return result An Observation struct containing the aggregated result with the
     * validated price, token liquidity, quote token liquidity, and the current block timestamp.
     */
    function prepareResult(
        uint256 price,
        uint256 tokenLiquidity,
        uint256 quoteTokenLiquidity
    ) internal view returns (ObservationLibrary.Observation memory result) {
        if (price > type(uint112).max) {
            revert PriceTooHigh(price);
        } else {
            result.price = uint112(price);
        }
        if (tokenLiquidity > type(uint112).max) {
            result.tokenLiquidity = type(uint112).max; // Cap to max value
        } else {
            result.tokenLiquidity = uint112(tokenLiquidity);
        }
        if (quoteTokenLiquidity > type(uint112).max) {
            result.quoteTokenLiquidity = type(uint112).max; // Cap to max value
        } else {
            result.quoteTokenLiquidity = uint112(quoteTokenLiquidity);
        }
        result.timestamp = uint32(block.timestamp);

        return result;
    }
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

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./AbstractAggregator.sol";
import "../averaging/IAveragingStrategy.sol";

/**
 * @title MeanAggregator
 * @notice An implementation of IAggregationStrategy that aggregates observations by taking the weighted mean price and
 *   sum of the token and quote token liquidity.
 * @dev Override the extractWeight function to use a custom weight for each observation. The default weight for every
 *   observation is 1.
 */
contract MeanAggregator is AbstractAggregator {
    IAveragingStrategy public immutable averagingStrategy;

    /// @notice An error thrown when the total weight of the observations is zero.
    error ZeroWeight();

    /**
     * @notice Constructor for the MeanAggregator contract.
     * @param averagingStrategy_ The averaging strategy to use for calculating the weighted mean.
     */
    constructor(IAveragingStrategy averagingStrategy_) {
        averagingStrategy = averagingStrategy_;
    }

    /**
     * @notice Aggregates the observations by taking the weighted mean price and the sum of the token and quote token
     *   liquidity.
     * @param observations The observations to aggregate.
     * @param from The index of the first observation to aggregate.
     * @param to The index of the last observation to aggregate.
     * @return observation The aggregated observation with the weighted mean price, the sum of the token and quote token
     *   liquidity, and the current block timestamp.
     * @custom:throws BadInput if the `from` index is greater than the `to` index.
     * @custom:throws InsufficientObservations if the `to` index is greater than the length of the observations array.
     * @custom:throws ZeroWeight if the total weight of the observations is zero.
     */
    function aggregateObservations(
        address,
        ObservationLibrary.MetaObservation[] calldata observations,
        uint256 from,
        uint256 to
    ) external view override returns (ObservationLibrary.Observation memory) {
        if (from > to) revert BadInput();
        if (observations.length <= to) revert InsufficientObservations(observations.length, to - from + 1);

        uint256 sumWeightedPrice;
        uint256 sumWeight;
        uint256 sumTokenLiquidity = 0;
        uint256 sumQuoteTokenLiquidity = 0;

        for (uint256 i = from; i <= to; ++i) {
            uint256 weight = extractWeight(observations[i].data);

            sumWeightedPrice += averagingStrategy.calculateWeightedValue(observations[i].data.price, weight);
            sumWeight += weight;

            sumTokenLiquidity += observations[i].data.tokenLiquidity;
            sumQuoteTokenLiquidity += observations[i].data.quoteTokenLiquidity;
        }

        if (sumWeight == 0) revert ZeroWeight();

        uint256 price = averagingStrategy.calculateWeightedAverage(sumWeightedPrice, sumWeight);

        return prepareResult(price, sumTokenLiquidity, sumQuoteTokenLiquidity);
    }

    /**
     * @notice Override this function to provide a custom weight for each observation.
     * @dev The default weight for every observation is 1.
     * @return weight The weight of the provided observation.
     */
    function extractWeight(ObservationLibrary.Observation memory) internal pure virtual returns (uint256) {
        return 1;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./MeanAggregator.sol";

/**
 * @title QuoteTokenWeightedMeanAggregator
 * @notice An implementation of MeanAggregator that uses the quote token liquidity as weight for each observation.
 * @dev This aggregator calculates the weighted mean price based on the quote token liquidity of each observation.
 */
contract QuoteTokenWeightedMeanAggregator is MeanAggregator {
    /**
     * @notice Constructor for the QuoteTokenWeightedMeanAggregator contract.
     * @param averagingStrategy_ The averaging strategy to use for calculating the weighted mean.
     */
    constructor(IAveragingStrategy averagingStrategy_) MeanAggregator(averagingStrategy_) {}

    /**
     * @notice Extracts the weight from the provided observation using the quote token liquidity.
     * @dev Override this function to use a custom weight for each observation. In this case, the weight is the quote
     *   token liquidity of the observation.
     * @param observation The observation from which to extract the weight.
     * @return weight The weight of the provided observation, which is the quote token liquidity.
     */
    function extractWeight(ObservationLibrary.Observation memory observation) internal pure override returns (uint256) {
        return observation.quoteTokenLiquidity;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/// @title IAveragingStrategy
/// @notice An interface defining a strategy for calculating weighted averages.
interface IAveragingStrategy {
    /// @notice An error that is thrown when we try calculating a weighted average with a total weight of zero.
    /// @dev A total weight of zero is ambiguous, so we throw an error.
    error TotalWeightCannotBeZero();

    /// @notice Calculates a weighted value.
    /// @param value The value to weight.
    /// @param weight The weight to apply to the value.
    /// @return The weighted value.
    function calculateWeightedValue(uint256 value, uint256 weight) external pure returns (uint256);

    /// @notice Calculates a weighted average.
    /// @param totalWeightedValues The sum of the weighted values.
    /// @param totalWeight The sum of the weights.
    /// @return The weighted average.
    /// @custom:throws TotalWeightCannotBeZero if the total weight is zero.
    function calculateWeightedAverage(uint256 totalWeightedValues, uint256 totalWeight) external pure returns (uint256);
}