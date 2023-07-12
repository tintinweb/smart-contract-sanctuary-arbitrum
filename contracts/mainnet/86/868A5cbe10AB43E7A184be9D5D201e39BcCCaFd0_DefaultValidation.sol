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

import "./IValidationStrategy.sol";

/**
 * @title DefaultValidation
 * @notice The default validation strategy implementation for validating observation data in a token pair.
 * @dev This validation strategy checks that the token liquidity value is greater than or equal to a minimum value, that
 * the quote token liquidity is greater than or equal to a minimum value, and that the token liquidity value divided by
 * the quote token liquidity value is within a minimum and maximum ratio.
 *
 * Note that the minimum token liquidity value and the minimum quote token liquidity don't have any implicit units, but
 * the units for both the token and the quote token liquidity must be the same. Validation results may vary depending on
 * the units used by the caller.
 *
 * All observations with a price, token liquidity, or quote token liquidity of one or less are considered invalid.
 */
contract DefaultValidation is IERC165, IValidationStrategy {
    /// @notice The number of decimals of the quote token.
    /// @dev This is used to scale the quote token liquidity value.
    uint8 public immutable override quoteTokenDecimals;

    /// @notice The minimum quote token denominated value of the token liquidity, scaled by this oracle's liquidity
    /// decimals, required for all underlying oracles to be considered valid and thus included in the aggregation.
    uint256 public immutable minimumTokenLiquidityValue;

    /// @notice The minimum quote token liquidity, scaled by this oracle's liquidity decimals, required for all
    /// underlying oracles to be considered valid and thus included in the aggregation.
    uint256 public immutable minimumQuoteTokenLiquidity;

    /// @notice The minimum ratio of token liquidity value to quote token liquidity value, scaled by 10,000.
    uint256 public immutable minimumLiquidityRatio;

    /// @notice The maximum ratio of token liquidity value to quote token liquidity value, scaled by 10,000.
    uint256 public immutable maximumLiquidityRatio;

    /// @notice One whole unit of the quote token, in the quote token's smallest denomination.
    uint256 internal immutable _quoteTokenWholeUnit;

    /**
     * @notice Constructor for the DefaultValidation contract.
     * @param quoteTokenDecimals_ The number of decimals that prices are scaled by for the quote token.
     * @param minimumTokenLiquidityValue_   The minimum quote token denominated value of the token liquidity.
     * @param minimumQuoteTokenLiquidity_ The minimum quote token liquidity.
     * @param minimumLiquidityRatio_ The minimum ratio of token liquidity value to quote token liquidity value, scaled
     * by 10,000.
     * @param maximumLiquidityRatio_ The maximum ratio of token liquidity value to quote token liquidity value, scaled
     * by 10,000.
     */
    constructor(
        uint8 quoteTokenDecimals_,
        uint256 minimumTokenLiquidityValue_,
        uint256 minimumQuoteTokenLiquidity_,
        uint256 minimumLiquidityRatio_,
        uint256 maximumLiquidityRatio_
    ) {
        minimumTokenLiquidityValue = minimumTokenLiquidityValue_;
        minimumQuoteTokenLiquidity = minimumQuoteTokenLiquidity_;
        quoteTokenDecimals = quoteTokenDecimals_;
        _quoteTokenWholeUnit = 10 ** quoteTokenDecimals_;
        minimumLiquidityRatio = minimumLiquidityRatio_;
        maximumLiquidityRatio = maximumLiquidityRatio_;
    }

    /// @inheritdoc IValidationStrategy
    function validateObservation(
        address,
        ObservationLibrary.MetaObservation calldata observation
    ) external view override returns (bool) {
        return validate(observation.data.price, observation.data.tokenLiquidity, observation.data.quoteTokenLiquidity);
    }

    // @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IValidationStrategy).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice Validates the given observation data based on the provided price, token liquidity, and quote token
     * liquidity.
     * @param price The price of the token pair.
     * @param tokenLiquidity The token liquidity value.
     * @param quoteTokenLiquidity The quote token liquidity value.
     * @return True if the observation passes validation; false otherwise.
     */
    function validate(
        uint256 price,
        uint256 tokenLiquidity,
        uint256 quoteTokenLiquidity
    ) internal view virtual returns (bool) {
        if (price <= 1 || tokenLiquidity <= 1 || quoteTokenLiquidity <= 1) {
            // Ignore any observations where any of the data points are less than or equal to one.
            return false;
        }

        return
            sanityCheckTokenLiquidityValue(price, tokenLiquidity) &&
            sanityCheckQuoteTokenLiquidity(quoteTokenLiquidity) &&
            sanityCheckTvlDistributionRatio(price, tokenLiquidity, quoteTokenLiquidity);
    }

    /**
     * @notice Validates the given price, token liquidity, and quote token liquidity based on the liquidity distribution
     * ratio.
     * @param price The price of the token.
     * @param tokenLiquidity The token liquidity.
     * @param quoteTokenLiquidity The quote token liquidity.
     * @return True if the TVL distribution ratio is within the minimum and maximum ratio; false otherwise.
     */
    function sanityCheckTvlDistributionRatio(
        uint256 price,
        uint256 tokenLiquidity,
        uint256 quoteTokenLiquidity
    ) internal view virtual returns (bool) {
        if (quoteTokenLiquidity == 0) {
            // We'll always ignore consultations where the quote token liquidity is 0
            return false;
        }

        // Calculate the ratio of token liquidity value (denominated in the quote token) to quote token liquidity
        // Safe from overflows: price and tokenLiquidity are actually uint112 in disguise
        // 10000 represents a ratio of 1:1
        uint256 ratio = (((price * tokenLiquidity * 10000) / _quoteTokenWholeUnit) / quoteTokenLiquidity);

        return ratio >= minimumLiquidityRatio && ratio <= maximumLiquidityRatio;
    }

    /**
     * @notice Validates the given quote token liquidity based on the minimum quote token liquidity value.
     * @param quoteTokenLiquidity The quote token liquidity.
     * @return True if the quote token liquidity is greater than or equal to the minimum quote token liquidity; false
     * otherwise.
     */
    function sanityCheckQuoteTokenLiquidity(uint256 quoteTokenLiquidity) internal view virtual returns (bool) {
        return quoteTokenLiquidity >= minimumQuoteTokenLiquidity;
    }

    /**
     * @notice Validates the token liquidity value based on the minimum token liquidity value.
     * @param price The price of the token.
     * @param tokenLiquidity The token liquidity.
     * @return True if the token liquidity value is greater than or equal to the minimum token liquidity value; false
     * otherwise.
     */
    function sanityCheckTokenLiquidityValue(
        uint256 price,
        uint256 tokenLiquidity
    ) internal view virtual returns (bool) {
        return ((price * tokenLiquidity) / _quoteTokenWholeUnit) >= minimumTokenLiquidityValue;
    }
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