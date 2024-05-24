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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

library SortingLibrary {
    /**
     * @notice Sorts the array of numbers using the quick sort algorithm.
     *
     * @param self The array of numbers to sort.
     * @param left The left boundary of the sorting range.
     * @param right The right boundary of the sorting range.
     */
    function quickSort(uint112[] memory self, int256 left, int256 right) internal pure {
        if (right - left <= 10) {
            insertionSort(self, left, right);
            return;
        }

        int256 i = left;
        int256 j = right;

        // The following is commented out because it is not possible for i to be equal to j at this point.
        // if (i == j) return;

        uint256 pivotIndex = uint256(left + (right - left) / 2);
        uint256 pivotPrice = self[pivotIndex];

        while (i <= j) {
            while (self[uint256(i)] < pivotPrice) {
                i = i + 1;
            }
            while (pivotPrice < self[uint256(j)]) {
                j = j - 1;
            }
            if (i <= j) {
                (self[uint256(i)], self[uint256(j)]) = (self[uint256(j)], self[uint256(i)]);
                i = i + 1;
                j = j - 1;
            }
        }

        if (left < j) {
            quickSort(self, left, j);
        }
        if (i < right) {
            quickSort(self, i, right);
        }
    }

    /**
     * @notice Sorts the array of numbers using the insertion sort algorithm.
     *
     * @param self The array of numbers to sort.
     * @param left The left boundary of the sorting range.
     * @param right The right boundary of the sorting range.
     */
    function insertionSort(uint112[] memory self, int256 left, int256 right) internal pure {
        for (int256 i = left + 1; i <= right; i = i + 1) {
            uint112 key = self[uint256(i)];
            int256 j = i - 1;

            while (j >= left && self[uint256(j)] > key) {
                self[uint256(j + 1)] = self[uint256(j)];
                j = j - 1;
            }
            self[uint256(j + 1)] = key;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "./AbstractAggregator.sol";
import "../../libraries/SortingLibrary.sol";

/**
 * @title MedianAggregator
 * @notice An implementation of IAggregationStrategy that aggregates observations by taking the median price and the
 * sum of the token and quote token liquidity.
 *
 * This contract extends the AbstractAggregator and overrides the aggregateObservations function to perform
 * median-based aggregation.
 */
contract MedianAggregator is AbstractAggregator {
    using SortingLibrary for uint112[];

    /**
     * @notice Aggregates the observations by taking the median price and the sum of the token and quote token
     * liquidity.
     *
     * @param observations The observations to aggregate.
     * @param from The index of the first observation to aggregate.
     * @param to The index of the last observation to aggregate.
     *
     * @return observation The aggregated observation with the median price, the sum of the token and quote token
     * liquidity, and the current block timestamp.
     */
    function aggregateObservations(
        address,
        ObservationLibrary.MetaObservation[] calldata observations,
        uint256 from,
        uint256 to
    ) external view override returns (ObservationLibrary.Observation memory) {
        if (from > to) revert BadInput();
        if (observations.length <= to) revert InsufficientObservations(observations.length, to - from + 1);
        uint256 length = to - from + 1;
        if (length == 1) {
            ObservationLibrary.Observation memory observation = observations[from].data;
            observation.timestamp = uint32(block.timestamp);
            return observation;
        }

        uint112[] memory prices = new uint112[](length);
        uint256 sumTokenLiquidity = 0;
        uint256 sumQuoteTokenLiquidity = 0;

        for (uint256 i = from; i <= to; ++i) {
            prices[i] = observations[i].data.price;

            sumTokenLiquidity += observations[i].data.tokenLiquidity;
            sumQuoteTokenLiquidity += observations[i].data.quoteTokenLiquidity;
        }

        prices.quickSort(0, int256(length - 1));

        // Take the median price
        uint256 medianIndex = length / 2;
        uint112 medianPrice;
        if (length % 2 == 0) {
            // Casting to uint112 because the average of two uint112s cannot overflow a uint112
            medianPrice = uint112((uint256(prices[medianIndex - 1]) + uint256(prices[medianIndex])) / 2);
        } else {
            medianPrice = prices[medianIndex];
        }

        return prepareResult(medianPrice, sumTokenLiquidity, sumQuoteTokenLiquidity);
    }
}