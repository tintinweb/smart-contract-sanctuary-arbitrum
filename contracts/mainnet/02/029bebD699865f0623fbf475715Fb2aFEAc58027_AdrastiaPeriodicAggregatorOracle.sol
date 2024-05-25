//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "../libraries/ObservationLibrary.sol";

/**
 * @title IHistoricalOracle
 * @notice An interface that defines an oracle contract that stores historical observations.
 */
interface IHistoricalOracle {
    /// @notice Gets an observation for a token at a specific index.
    /// @param token The address of the token to get the observation for.
    /// @param index The index of the observation to get, where index 0 contains the latest observation, and the last
    ///   index contains the oldest observation (uses reverse chronological ordering).
    /// @return observation The observation for the token at the specified index.
    function getObservationAt(
        address token,
        uint256 index
    ) external view returns (ObservationLibrary.Observation memory);

    /// @notice Gets the latest observations for a token.
    /// @param token The address of the token to get the observations for.
    /// @param amount The number of observations to get.
    /// @return observations The latest observations for the token, in reverse chronological order, from newest to oldest.
    function getObservations(
        address token,
        uint256 amount
    ) external view returns (ObservationLibrary.Observation[] memory);

    /// @notice Gets the latest observations for a token.
    /// @param token The address of the token to get the observations for.
    /// @param amount The number of observations to get.
    /// @param offset The index of the first observation to get (default: 0).
    /// @param increment The increment between observations to get (default: 1).
    /// @return observations The latest observations for the token, in reverse chronological order, from newest to oldest.
    function getObservations(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) external view returns (ObservationLibrary.Observation[] memory);

    /// @notice Gets the number of observations for a token.
    /// @param token The address of the token to get the number of observations for.
    /// @return count The number of observations for the token.
    function getObservationsCount(address token) external view returns (uint256);

    /// @notice Gets the capacity of observations for a token.
    /// @param token The address of the token to get the capacity of observations for.
    /// @return capacity The capacity of observations for the token.
    function getObservationsCapacity(address token) external view returns (uint256);

    /// @notice Sets the capacity of observations for a token.
    /// @param token The address of the token to set the capacity of observations for.
    /// @param amount The new capacity of observations for the token.
    function setObservationsCapacity(address token, uint256 amount) external;
}

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

/**
 * @title IPeriodic
 * @notice An interface that defines a contract containing a period.
 * @dev This typically refers to an update period.
 */
interface IPeriodic {
    /// @notice Gets the period, in seconds.
    /// @return periodSeconds The period, in seconds.
    function period() external view returns (uint256 periodSeconds);

    // @notice Gets the number of observations made every period.
    // @return granularity The number of observations made every period.
    function granularity() external view returns (uint256 granularity);
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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

library StringLibrary {
    function bytes32ToString(bytes32 self) internal pure returns (string memory) {
        // Calculate string length
        uint256 i = 0;
        while (i < 32 && self[i] != 0) ++i;

        bytes memory bytesArray = new bytes(i);

        // Extract characters
        for (i = 0; i < 32 && self[i] != 0; ++i) bytesArray[i] = self[i];

        return string(bytesArray);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "./IOracleAggregator.sol";
import "./AbstractOracle.sol";
import "./HistoricalOracle.sol";
import "../interfaces/IOracle.sol";
import "../utils/ExplicitQuotationMetadata.sol";
import "../strategies/validation/IValidationStrategy.sol";

abstract contract AbstractAggregatorOracle is
    IOracleAggregator,
    AbstractOracle,
    HistoricalOracle,
    ExplicitQuotationMetadata
{
    struct TokenSpecificOracle {
        address token;
        address oracle;
    }

    /**
     * @notice An event emitted when data is aggregated.
     * @param token The token for which the data is aggregated.
     * @param tick The identifier of the aggregation iteration (i.e. timestamp) at which the data is aggregated.
     * @param numDataPoints The number of data points (i.e. underlying oracle responses) aggregated.
     */
    event AggregationPerformed(address indexed token, uint256 indexed tick, uint256 numDataPoints);

    IAggregationStrategy internal immutable generalAggregationStrategy;

    IValidationStrategy internal immutable generalValidationStrategy;

    /// @notice One whole unit of the quote token, in the quote token's smallest denomination.
    uint256 internal immutable _quoteTokenWholeUnit;

    uint8 internal immutable _liquidityDecimals;

    Oracle[] internal oracles;
    mapping(address => Oracle[]) internal tokenSpecificOracles;

    mapping(address => bool) private oracleExists;
    mapping(address => mapping(address => bool)) private oracleForExists;

    /// @notice Emitted when an underlying oracle (or this oracle) throws an update error with a reason.
    /// @param oracle The address or the oracle throwing the error.
    /// @param token The token for which the oracle is throwing the error.
    /// @param reason The reason for or description of the error.
    event UpdateErrorWithReason(address indexed oracle, address indexed token, string reason);

    /// @notice Emitted when an underlying oracle (or this oracle) throws an update error without a reason.
    /// @param oracle The address or the oracle throwing the error.
    /// @param token The token for which the oracle is throwing the error.
    /// @param err Data corresponding with a low level error being thrown.
    event UpdateError(address indexed oracle, address indexed token, bytes err);

    struct AbstractAggregatorOracleParams {
        IAggregationStrategy aggregationStrategy;
        IValidationStrategy validationStrategy;
        string quoteTokenName;
        address quoteTokenAddress;
        string quoteTokenSymbol;
        uint8 quoteTokenDecimals;
        uint8 liquidityDecimals;
        address[] oracles;
        TokenSpecificOracle[] tokenSpecificOracles;
    }

    constructor(
        AbstractAggregatorOracleParams memory params
    )
        HistoricalOracle(1)
        AbstractOracle(params.quoteTokenAddress)
        ExplicitQuotationMetadata(
            params.quoteTokenName,
            params.quoteTokenAddress,
            params.quoteTokenSymbol,
            params.quoteTokenDecimals
        )
    {
        if (
            address(params.validationStrategy) != address(0) &&
            params.validationStrategy.quoteTokenDecimals() != params.quoteTokenDecimals
        ) {
            revert("AbstractAggregatorOracle: QUOTE_TOKEN_DECIMALS_MISMATCH");
        }

        generalAggregationStrategy = params.aggregationStrategy;
        generalValidationStrategy = params.validationStrategy;

        _quoteTokenWholeUnit = 10 ** params.quoteTokenDecimals;

        _liquidityDecimals = params.liquidityDecimals;

        // Setup general oracles
        for (uint256 i = 0; i < params.oracles.length; ++i) {
            require(!oracleExists[params.oracles[i]], "AbstractAggregatorOracle: DUPLICATE_ORACLE");

            oracleExists[params.oracles[i]] = true;

            oracles.push(
                Oracle({
                    oracle: params.oracles[i],
                    priceDecimals: IOracle(params.oracles[i]).quoteTokenDecimals(),
                    liquidityDecimals: IOracle(params.oracles[i]).liquidityDecimals()
                })
            );
        }

        // Setup token-specific oracles
        for (uint256 i = 0; i < params.tokenSpecificOracles.length; ++i) {
            TokenSpecificOracle memory oracle = params.tokenSpecificOracles[i];

            require(!oracleExists[oracle.oracle], "AbstractAggregatorOracle: DUPLICATE_ORACLE");
            require(!oracleForExists[oracle.token][oracle.oracle], "AbstractAggregatorOracle: DUPLICATE_ORACLE");

            oracleForExists[oracle.token][oracle.oracle] = true;

            tokenSpecificOracles[oracle.token].push(
                Oracle({
                    oracle: oracle.oracle,
                    priceDecimals: IOracle(oracle.oracle).quoteTokenDecimals(),
                    liquidityDecimals: IOracle(oracle.oracle).liquidityDecimals()
                })
            );
        }
    }

    /// @inheritdoc IOracleAggregator
    function aggregationStrategy(address token) external view virtual override returns (IAggregationStrategy) {
        return _aggregationStrategy(token);
    }

    /// @inheritdoc IOracleAggregator
    function validationStrategy(address token) external view virtual override returns (IValidationStrategy) {
        return _validationStrategy(token);
    }

    /// @inheritdoc IOracleAggregator
    function getOracles(address token) external view virtual override returns (Oracle[] memory) {
        return _getOracles(token);
    }

    /// @inheritdoc IOracleAggregator
    function minimumResponses(address token) external view virtual override returns (uint256) {
        return _minimumResponses(token);
    }

    /// @inheritdoc IOracleAggregator
    function maximumResponseAge(address token) external view virtual override returns (uint256) {
        return _maximumResponseAge(token);
    }

    /// @inheritdoc ExplicitQuotationMetadata
    function quoteTokenName()
        public
        view
        virtual
        override(ExplicitQuotationMetadata, IQuoteToken, SimpleQuotationMetadata)
        returns (string memory)
    {
        return ExplicitQuotationMetadata.quoteTokenName();
    }

    /// @inheritdoc ExplicitQuotationMetadata
    function quoteTokenAddress()
        public
        view
        virtual
        override(ExplicitQuotationMetadata, IQuoteToken, SimpleQuotationMetadata)
        returns (address)
    {
        return ExplicitQuotationMetadata.quoteTokenAddress();
    }

    /// @inheritdoc ExplicitQuotationMetadata
    function quoteTokenSymbol()
        public
        view
        virtual
        override(ExplicitQuotationMetadata, IQuoteToken, SimpleQuotationMetadata)
        returns (string memory)
    {
        return ExplicitQuotationMetadata.quoteTokenSymbol();
    }

    /// @inheritdoc ExplicitQuotationMetadata
    function quoteTokenDecimals()
        public
        view
        virtual
        override(ExplicitQuotationMetadata, IQuoteToken, SimpleQuotationMetadata)
        returns (uint8)
    {
        return ExplicitQuotationMetadata.quoteTokenDecimals();
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ExplicitQuotationMetadata, AbstractOracle) returns (bool) {
        return
            interfaceId == type(IHistoricalOracle).interfaceId ||
            interfaceId == type(IOracleAggregator).interfaceId ||
            ExplicitQuotationMetadata.supportsInterface(interfaceId) ||
            AbstractOracle.supportsInterface(interfaceId);
    }

    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        if (!needsUpdate(data)) {
            return false;
        }

        if (canUpdateUnderlyingOracles(data)) {
            return true;
        }

        address token = abi.decode(data, (address));

        (, uint256 validResponses) = aggregateUnderlying(token, _maximumResponseAge(token));

        // Only return true if we have reached the minimum number of valid underlying oracle consultations
        return validResponses >= _minimumResponses(token);
    }

    /// @inheritdoc IOracle
    function liquidityDecimals() public view virtual override returns (uint8) {
        return _liquidityDecimals;
    }

    function getLatestObservation(
        address token
    ) public view virtual override returns (ObservationLibrary.Observation memory observation) {
        BufferMetadata storage meta = observationBufferMetadata[token];

        if (meta.size == 0) {
            // If the buffer is empty, return the default observation
            return ObservationLibrary.Observation({price: 0, tokenLiquidity: 0, quoteTokenLiquidity: 0, timestamp: 0});
        }

        return observationBuffers[token][meta.end];
    }

    /// @notice Checks if any of the underlying oracles for the token need to be updated.
    /// @dev This function is used to determine if the aggregator can be updated by updating one of the underlying
    /// oracles. Please ensure updateUnderlyingOracles will update the underlying oracles if this function returns true.
    /// @param data The encoded token address, along with any additional data required by the oracle.
    /// @return True if any of the underlying oracles can be updated, false otherwise.
    function canUpdateUnderlyingOracles(bytes memory data) internal view virtual returns (bool) {
        address token = abi.decode(data, (address));

        // Ensure all underlying oracles are up-to-date
        Oracle[] memory theOracles = _getOracles(token);
        for (uint256 i = 0; i < theOracles.length; ++i) {
            if (IOracle(theOracles[i].oracle).canUpdate(data)) {
                // We can update one of the underlying oracles
                return true;
            }
        }

        return false;
    }

    /// @notice Updates the underlying oracles for the token.
    /// @dev This function is used to update the underlying oracles before consulting them.
    /// @param data The encoded token address, along with any additional data required by the oracle.
    /// @return True if any of the underlying oracles were updated, false otherwise.
    function updateUnderlyingOracles(bytes memory data) internal virtual returns (bool) {
        bool underlyingUpdated;
        address token = abi.decode(data, (address));

        // Ensure all underlying oracles are up-to-date
        Oracle[] memory theOracles = _getOracles(token);
        for (uint256 i = 0; i < theOracles.length; ++i) {
            // We don't want any problematic underlying oracles to prevent this oracle from updating
            // so we put update in a try-catch block
            try IOracle(theOracles[i].oracle).update(data) returns (bool updated) {
                underlyingUpdated = underlyingUpdated || updated;
            } catch Error(string memory reason) {
                emit UpdateErrorWithReason(theOracles[i].oracle, token, reason);
            } catch (bytes memory err) {
                emit UpdateError(theOracles[i].oracle, token, err);
            }
        }

        return underlyingUpdated;
    }

    function _getOracles(address token) internal view virtual returns (Oracle[] memory) {
        Oracle[] memory generalOracles = oracles;
        Oracle[] memory specificOracles = tokenSpecificOracles[token];

        uint256 generalOraclesCount = generalOracles.length;
        uint256 specificOraclesCount = specificOracles.length;

        Oracle[] memory allOracles = new Oracle[](generalOraclesCount + specificOraclesCount);

        // Add the general oracles
        for (uint256 i = 0; i < generalOraclesCount; ++i) allOracles[i] = generalOracles[i];

        // Add the token specific oracles
        for (uint256 i = 0; i < specificOraclesCount; ++i) allOracles[generalOraclesCount + i] = specificOracles[i];

        return allOracles;
    }

    function performUpdate(bytes memory data) internal virtual returns (bool) {
        bool underlyingUpdated = updateUnderlyingOracles(data);

        address token = abi.decode(data, (address));

        (ObservationLibrary.Observation memory observation, uint256 validResponses) = aggregateUnderlying(
            token,
            _maximumResponseAge(token)
        );

        if (validResponses >= _minimumResponses(token)) {
            emit AggregationPerformed(token, block.timestamp, validResponses);

            push(token, observation);

            return true;
        } else emit UpdateErrorWithReason(address(this), token, "AbstractAggregatorOracle: INVALID_NUM_CONSULTATIONS");

        return underlyingUpdated;
    }

    function _minimumResponses(address token) internal view virtual returns (uint256);

    function _maximumResponseAge(address token) internal view virtual returns (uint256);

    function _aggregationStrategy(address token) internal view virtual returns (IAggregationStrategy) {
        token; // silence unused variable warning. We let subclasses override this function to use the token parameter.

        return generalAggregationStrategy;
    }

    function _validationStrategy(address token) internal view virtual returns (IValidationStrategy) {
        token; // silence unused variable warning. We let subclasses override this function to use the token parameter.

        return generalValidationStrategy;
    }

    function aggregateUnderlying(
        address token,
        uint256 maxAge
    ) internal view virtual returns (ObservationLibrary.Observation memory result, uint256 validResponses) {
        uint256 pDecimals = quoteTokenDecimals();
        uint256 lDecimals = liquidityDecimals();

        Oracle[] memory theOracles = _getOracles(token);
        ObservationLibrary.MetaObservation[] memory observations = new ObservationLibrary.MetaObservation[](
            theOracles.length
        );

        uint256 oPrice;
        uint256 oTokenLiquidity;
        uint256 oQuoteTokenLiquidity;

        IValidationStrategy validation = _validationStrategy(token);

        for (uint256 i = 0; i < theOracles.length; ++i) {
            // We don't want problematic underlying oracles to prevent us from calculating the aggregated
            // results from the other working oracles, so we use a try-catch block.
            try IOracle(theOracles[i].oracle).consult(token, maxAge) returns (
                uint112 _price,
                uint112 _tokenLiquidity,
                uint112 _quoteTokenLiquidity
            ) {
                // Promote returned data to uint256 to prevent scaling up from overflowing
                oPrice = _price;
                oTokenLiquidity = _tokenLiquidity;
                oQuoteTokenLiquidity = _quoteTokenLiquidity;
            } catch Error(string memory) {
                continue;
            } catch (bytes memory) {
                continue;
            }

            // Fix differing quote token decimal places (for price)
            if (theOracles[i].priceDecimals < pDecimals) {
                // Scale up
                uint256 scalar = 10 ** (pDecimals - theOracles[i].priceDecimals);

                oPrice *= scalar;
            } else if (theOracles[i].priceDecimals > pDecimals) {
                // Scale down
                uint256 scalar = 10 ** (theOracles[i].priceDecimals - pDecimals);

                oPrice /= scalar;
            }

            // Fix differing liquidity decimal places
            if (theOracles[i].liquidityDecimals < lDecimals) {
                // Scale up
                uint256 scalar = 10 ** (lDecimals - theOracles[i].liquidityDecimals);

                oTokenLiquidity *= scalar;
                oQuoteTokenLiquidity *= scalar;
            } else if (theOracles[i].liquidityDecimals > lDecimals) {
                // Scale down
                uint256 scalar = 10 ** (theOracles[i].liquidityDecimals - lDecimals);

                oTokenLiquidity /= scalar;
                oQuoteTokenLiquidity /= scalar;
            }

            if (
                // Check that the values are not too large
                oPrice <= type(uint112).max &&
                oTokenLiquidity <= type(uint112).max &&
                oQuoteTokenLiquidity <= type(uint112).max
            ) {
                ObservationLibrary.MetaObservation memory observation;

                {
                    bytes memory updateData = abi.encode(token);
                    uint256 timestamp = IOracle(theOracles[i].oracle).lastUpdateTime(updateData);

                    observation = ObservationLibrary.MetaObservation({
                        metadata: ObservationLibrary.ObservationMetadata({oracle: theOracles[i].oracle}),
                        data: ObservationLibrary.Observation({
                            price: uint112(oPrice),
                            tokenLiquidity: uint112(oTokenLiquidity),
                            quoteTokenLiquidity: uint112(oQuoteTokenLiquidity),
                            timestamp: uint32(timestamp)
                        })
                    });
                }

                if (address(validation) == address(0) || validation.validateObservation(token, observation)) {
                    // The observation is valid, so we add it to the array
                    observations[validResponses++] = observation;
                }
            }
        }

        if (validResponses == 0) {
            return (
                ObservationLibrary.Observation({price: 0, tokenLiquidity: 0, quoteTokenLiquidity: 0, timestamp: 0}),
                0
            );
        }

        result = _aggregationStrategy(token).aggregateObservations(token, observations, 0, validResponses - 1);

        if (address(validation) != address(0)) {
            // Validate the aggregated result
            ObservationLibrary.MetaObservation memory metaResult = ObservationLibrary.MetaObservation({
                metadata: ObservationLibrary.ObservationMetadata({oracle: address(this)}),
                data: result
            });
            if (!validation.validateObservation(token, metaResult)) {
                return (
                    ObservationLibrary.Observation({price: 0, tokenLiquidity: 0, quoteTokenLiquidity: 0, timestamp: 0}),
                    0
                );
            }
        }
    }

    /// @inheritdoc AbstractOracle
    function instantFetch(
        address token
    ) internal view virtual override returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        (ObservationLibrary.Observation memory result, uint256 validResponses) = aggregateUnderlying(token, 0);

        uint256 minResponses = _minimumResponses(token);
        require(validResponses >= minResponses, "AbstractAggregatorOracle: INVALID_NUM_CONSULTATIONS");

        price = result.price;
        tokenLiquidity = result.tokenLiquidity;
        quoteTokenLiquidity = result.quoteTokenLiquidity;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";

import "../interfaces/IOracle.sol";
import "../libraries/ObservationLibrary.sol";
import "../utils/SimpleQuotationMetadata.sol";

abstract contract AbstractOracle is IERC165, IOracle, SimpleQuotationMetadata {
    constructor(address quoteToken_) SimpleQuotationMetadata(quoteToken_) {}

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function update(bytes memory data) public virtual override returns (bool);

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function needsUpdate(bytes memory data) public view virtual override returns (bool);

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function canUpdate(bytes memory data) public view virtual override returns (bool);

    function getLatestObservation(
        address token
    ) public view virtual returns (ObservationLibrary.Observation memory observation);

    /// @param data The encoded address of the token for which the update relates to.
    /// @inheritdoc IUpdateable
    function lastUpdateTime(bytes memory data) public view virtual override returns (uint256) {
        address token = abi.decode(data, (address));

        return getLatestObservation(token).timestamp;
    }

    /// @param data The encoded address of the token for which the update relates to.
    /// @inheritdoc IUpdateable
    function timeSinceLastUpdate(bytes memory data) public view virtual override returns (uint256) {
        return block.timestamp - lastUpdateTime(data);
    }

    function consultPrice(address token) public view virtual override returns (uint112 price) {
        if (token == quoteTokenAddress()) return uint112(10 ** quoteTokenDecimals());

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");

        return observation.price;
    }

    /// @inheritdoc IPriceOracle
    function consultPrice(address token, uint256 maxAge) public view virtual override returns (uint112 price) {
        if (token == quoteTokenAddress()) return uint112(10 ** quoteTokenDecimals());

        if (maxAge == 0) {
            (price, , ) = instantFetch(token);

            return price;
        }

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "AbstractOracle: RATE_TOO_OLD");

        return observation.price;
    }

    /// @inheritdoc ILiquidityOracle
    function consultLiquidity(
        address token
    ) public view virtual override returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        if (token == quoteTokenAddress()) return (0, 0);

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");

        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc ILiquidityOracle
    function consultLiquidity(
        address token,
        uint256 maxAge
    ) public view virtual override returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        if (token == quoteTokenAddress()) return (0, 0);

        if (maxAge == 0) {
            (, tokenLiquidity, quoteTokenLiquidity) = instantFetch(token);

            return (tokenLiquidity, quoteTokenLiquidity);
        }

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "AbstractOracle: RATE_TOO_OLD");

        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc IOracle
    function consult(
        address token
    ) public view virtual override returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        if (token == quoteTokenAddress()) return (uint112(10 ** quoteTokenDecimals()), 0, 0);

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");

        price = observation.price;
        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc IOracle
    function consult(
        address token,
        uint256 maxAge
    ) public view virtual override returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        if (token == quoteTokenAddress()) return (uint112(10 ** quoteTokenDecimals()), 0, 0);

        if (maxAge == 0) return instantFetch(token);

        ObservationLibrary.Observation memory observation = getLatestObservation(token);

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "AbstractOracle: RATE_TOO_OLD");

        price = observation.price;
        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(SimpleQuotationMetadata, IERC165) returns (bool) {
        return
            interfaceId == type(IOracle).interfaceId ||
            interfaceId == type(IUpdateable).interfaceId ||
            interfaceId == type(IPriceOracle).interfaceId ||
            interfaceId == type(ILiquidityOracle).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Fetches the instant rates as of the latest block, straight from the source.
     * @dev This is costly in gas and the rates are easier to manipulate.
     * @param token The token to get the rates for.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function instantFetch(
        address token
    ) internal view virtual returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "../interfaces/IHistoricalOracle.sol";
import "../libraries/ObservationLibrary.sol";

abstract contract HistoricalOracle is IHistoricalOracle {
    struct BufferMetadata {
        uint16 start;
        uint16 end;
        uint16 size;
        uint16 maxSize;
        uint16 flags; // Bit flags for future use
        uint112 __reserved; // Reserved for future use
        uint64 extra; // For user extensions
    }

    mapping(address => BufferMetadata) internal observationBufferMetadata;

    mapping(address => ObservationLibrary.Observation[]) internal observationBuffers;

    uint16 internal immutable initialCapacity;

    /// @notice Emitted when a stored quotation is updated.
    /// @param token The address of the token that the quotation is for.
    /// @param price The quote token denominated price for a whole token.
    /// @param tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
    /// @param quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
    /// @param timestamp The epoch timestamp of the quotation (in seconds).
    event Updated(
        address indexed token,
        uint256 price,
        uint256 tokenLiquidity,
        uint256 quoteTokenLiquidity,
        uint256 timestamp
    );

    /// @notice Event emitted when an observation buffer's capacity is increased past the initial capacity.
    /// @dev Buffer initialization does not emit an event.
    /// @param token The token for which the observation buffer's capacity was increased.
    /// @param oldCapacity The previous capacity of the observation buffer.
    /// @param newCapacity The new capacity of the observation buffer.
    event ObservationCapacityIncreased(address indexed token, uint256 oldCapacity, uint256 newCapacity);

    /// @notice Event emitted when an observation buffer's capacity is initialized.
    /// @param token The token for which the observation buffer's capacity was initialized.
    /// @param capacity The capacity of the observation buffer.
    event ObservationCapacityInitialized(address indexed token, uint256 capacity);

    /// @notice An error that is thrown if we try to initialize an observation buffer that has already been initialized.
    /// @param token The token for which we tried to initialize the observation buffer.
    error BufferAlreadyInitialized(address token);

    /// @notice An error that is thrown if we try to retrieve an observation at an invalid index.
    /// @param token The token for which we tried to retrieve the observation.
    /// @param index The index of the observation that we tried to retrieve.
    /// @param size The size of the observation buffer.
    error InvalidIndex(address token, uint256 index, uint256 size);

    /// @notice An error that is thrown if we try to decrease the capacity of an observation buffer.
    /// @param token The token for which we tried to decrease the capacity of the observation buffer.
    /// @param amount The capacity that we tried to decrease the observation buffer to.
    /// @param currentCapacity The current capacity of the observation buffer.
    error CapacityCannotBeDecreased(address token, uint256 amount, uint256 currentCapacity);

    /// @notice An error that is thrown if we try to increase the capacity of an observation buffer past the maximum capacity.
    /// @param token The token for which we tried to increase the capacity of the observation buffer.
    /// @param amount The capacity that we tried to increase the observation buffer to.
    /// @param maxCapacity The maximum capacity of the observation buffer.
    error CapacityTooLarge(address token, uint256 amount, uint256 maxCapacity);

    /// @notice An error that is thrown if we try to retrieve more observations than are available in the observation buffer.
    /// @param token The token for which we tried to retrieve the observations.
    /// @param size The size of the observation buffer.
    /// @param minSizeRequired The minimum size of the observation buffer that we require.
    error InsufficientData(address token, uint256 size, uint256 minSizeRequired);

    constructor(uint16 initialCapacity_) {
        initialCapacity = initialCapacity_;
    }

    /// @inheritdoc IHistoricalOracle
    function getObservationAt(
        address token,
        uint256 index
    ) external view virtual override returns (ObservationLibrary.Observation memory) {
        BufferMetadata memory meta = observationBufferMetadata[token];

        if (index >= meta.size) {
            revert InvalidIndex(token, index, meta.size);
        }

        uint256 bufferIndex = meta.end < index ? meta.end + meta.size - index : meta.end - index;

        return observationBuffers[token][bufferIndex];
    }

    /// @inheritdoc IHistoricalOracle
    function getObservations(
        address token,
        uint256 amount
    ) external view virtual override returns (ObservationLibrary.Observation[] memory) {
        return getObservationsInternal(token, amount, 0, 1);
    }

    /// @inheritdoc IHistoricalOracle
    function getObservations(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) external view virtual returns (ObservationLibrary.Observation[] memory) {
        return getObservationsInternal(token, amount, offset, increment);
    }

    /// @inheritdoc IHistoricalOracle
    function getObservationsCount(address token) external view override returns (uint256) {
        return observationBufferMetadata[token].size;
    }

    /// @inheritdoc IHistoricalOracle
    function getObservationsCapacity(address token) external view virtual override returns (uint256) {
        uint256 maxSize = observationBufferMetadata[token].maxSize;
        if (maxSize == 0) return initialCapacity;

        return maxSize;
    }

    /// @inheritdoc IHistoricalOracle
    /// @param amount The new capacity of observations for the token. Must be greater than the current capacity, but
    ///   less than 65536.
    function setObservationsCapacity(address token, uint256 amount) external virtual override {
        BufferMetadata storage meta = observationBufferMetadata[token];
        if (meta.maxSize == 0) {
            // Buffer is not initialized yet
            initializeBuffers(token);
        }

        if (amount < meta.maxSize) revert CapacityCannotBeDecreased(token, amount, meta.maxSize);
        if (amount > type(uint16).max) revert CapacityTooLarge(token, amount, type(uint16).max);

        ObservationLibrary.Observation[] storage observationBuffer = observationBuffers[token];

        // Add new slots to the buffer
        uint256 capacityToAdd = amount - meta.maxSize;
        for (uint256 i = 0; i < capacityToAdd; ++i) {
            // Push a dummy observation with non-zero values to put most of the gas cost on the caller
            observationBuffer.push(
                ObservationLibrary.Observation({price: 1, tokenLiquidity: 1, quoteTokenLiquidity: 1, timestamp: 1})
            );
        }

        if (meta.maxSize != amount) {
            emit ObservationCapacityIncreased(token, meta.maxSize, amount);

            // Update the metadata
            meta.maxSize = uint16(amount);
        }
    }

    function getObservationsInternal(
        address token,
        uint256 amount,
        uint256 offset,
        uint256 increment
    ) internal view virtual returns (ObservationLibrary.Observation[] memory) {
        if (amount == 0) return new ObservationLibrary.Observation[](0);

        BufferMetadata memory meta = observationBufferMetadata[token];
        if (meta.size <= (amount - 1) * increment + offset)
            revert InsufficientData(token, meta.size, (amount - 1) * increment + offset + 1);

        ObservationLibrary.Observation[] memory observations = new ObservationLibrary.Observation[](amount);

        uint256 count = 0;

        for (
            uint256 i = meta.end < offset ? meta.end + meta.size - offset : meta.end - offset;
            count < amount;
            i = (i < increment) ? (i + meta.size) - increment : i - increment
        ) {
            observations[count++] = observationBuffers[token][i];
        }

        return observations;
    }

    function initializeBuffers(address token) internal virtual {
        if (observationBuffers[token].length != 0) {
            revert BufferAlreadyInitialized(token);
        }

        BufferMetadata storage meta = observationBufferMetadata[token];

        // Initialize the buffers
        ObservationLibrary.Observation[] storage observationBuffer = observationBuffers[token];

        for (uint256 i = 0; i < initialCapacity; ++i) {
            observationBuffer.push();
        }

        // Initialize the metadata
        meta.start = 0;
        meta.end = 0;
        meta.size = 0;
        meta.maxSize = initialCapacity;

        emit ObservationCapacityInitialized(token, meta.maxSize);
    }

    function push(address token, ObservationLibrary.Observation memory observation) internal virtual {
        BufferMetadata storage meta = observationBufferMetadata[token];

        if (meta.size == 0) {
            if (meta.maxSize == 0) {
                // Initialize the buffers
                initializeBuffers(token);
            }
        } else {
            meta.end = (meta.end + 1) % meta.maxSize;
        }

        observationBuffers[token][meta.end] = observation;

        emit Updated(
            token,
            observation.price,
            observation.tokenLiquidity,
            observation.quoteTokenLiquidity,
            block.timestamp
        );

        if (meta.size < meta.maxSize && meta.end == meta.size) {
            // We are at the end of the array and we have not yet filled it
            meta.size++;
        } else {
            // start was just overwritten
            meta.start = (meta.start + 1) % meta.size;
        }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "./AbstractAggregatorOracle.sol";
import "../interfaces/IPeriodic.sol";

contract PeriodicAggregatorOracle is IPeriodic, AbstractAggregatorOracle {
    uint256 public immutable override period;
    uint256 public immutable override granularity;

    uint internal immutable _updateEvery;

    constructor(
        AbstractAggregatorOracleParams memory params,
        uint256 period_,
        uint256 granularity_
    ) AbstractAggregatorOracle(params) {
        require(period_ > 0, "PeriodicAggregatorOracle: INVALID_PERIOD");
        require(granularity_ > 0, "PeriodicAggregatorOracle: INVALID_GRANULARITY");
        require(period_ % granularity_ == 0, "PeriodicAggregatorOracle: INVALID_PERIOD_GRANULARITY");

        period = period_;
        granularity = granularity_;

        _updateEvery = period_ / granularity_;
    }

    /// @inheritdoc AbstractOracle
    function update(bytes memory data) public virtual override returns (bool) {
        if (needsUpdate(data)) return performUpdate(data);

        return false;
    }

    /// @inheritdoc AbstractOracle
    function needsUpdate(bytes memory data) public view virtual override returns (bool) {
        return timeSinceLastUpdate(data) >= _updateEvery;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IPeriodic).interfaceId || AbstractAggregatorOracle.supportsInterface(interfaceId);
    }

    function _minimumResponses(address) internal view virtual override returns (uint256) {
        return 1;
    }

    function _maximumResponseAge(address) internal view virtual override returns (uint256) {
        if (period == 1) {
            // We don't want to subtract 1 from this and use 0 as the max age, because that would cause the oracle
            // to return data straight from the current block, which may not be secure.
            return 1;
        }

        return period - 1; // Subract 1 to ensure that we don't use any data from the previous period
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

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IQuoteToken.sol";

contract ExplicitQuotationMetadata is IQuoteToken, IERC165 {
    string internal _quoteTokenName;
    string internal _quoteTokenSymbol;
    address internal immutable _quoteTokenAddress;
    uint8 internal immutable _quoteTokenDecimals;

    constructor(
        string memory quoteTokenName_,
        address quoteTokenAddress_,
        string memory quoteTokenSymbol_,
        uint8 quoteTokenDecimals_
    ) {
        _quoteTokenName = quoteTokenName_;
        _quoteTokenSymbol = quoteTokenSymbol_;
        _quoteTokenAddress = quoteTokenAddress_;
        _quoteTokenDecimals = quoteTokenDecimals_;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenName() public view virtual override returns (string memory) {
        return _quoteTokenName;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenAddress() public view virtual override returns (address) {
        return _quoteTokenAddress;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenSymbol() public view virtual override returns (string memory) {
        return _quoteTokenSymbol;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenDecimals() public view virtual override returns (uint8) {
        return _quoteTokenDecimals;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IQuoteToken).interfaceId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IQuoteToken.sol";
import "../libraries/StringLibrary.sol";

contract SimpleQuotationMetadata is IQuoteToken, IERC165 {
    using StringLibrary for bytes32;

    address public immutable quoteToken;

    constructor(address quoteToken_) {
        quoteToken = quoteToken_;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenName() public view virtual override returns (string memory) {
        return getStringOrBytes32(quoteToken, IERC20Metadata.name.selector);
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenAddress() public view virtual override returns (address) {
        return quoteToken;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenSymbol() public view virtual override returns (string memory) {
        return getStringOrBytes32(quoteToken, IERC20Metadata.symbol.selector);
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenDecimals() public view virtual override returns (uint8) {
        (bool success, bytes memory result) = quoteToken.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (!success) return 18; // Return 18 by default

        return abi.decode(result, (uint8));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IQuoteToken).interfaceId;
    }

    function getStringOrBytes32(address contractAddress, bytes4 selector) internal view returns (string memory) {
        (bool success, bytes memory result) = contractAddress.staticcall(abi.encodeWithSelector(selector));
        if (!success) return "";

        return result.length == 32 ? (bytes32(result)).bytes32ToString() : abi.decode(result, (string));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0 <0.9.0;

library Roles {
    bytes32 public constant ADMIN = keccak256("ADMIN_ROLE");

    bytes32 public constant UPDATER_ADMIN = keccak256("UPDATER_ADMIN_ROLE");

    bytes32 public constant ORACLE_UPDATER = keccak256("ORACLE_UPDATER_ROLE");

    bytes32 public constant RATE_ADMIN = keccak256("RATE_ADMIN_ROLE");

    bytes32 public constant UPDATE_PAUSE_ADMIN = keccak256("UPDATE_PAUSE_ADMIN_ROLE");

    bytes32 public constant CONFIG_ADMIN = keccak256("CONFIG_ADMIN_ROLE");

    bytes32 public constant TARGET_ADMIN = keccak256("TARGET_ADMIN_ROLE");
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-core/contracts/oracles/PeriodicAggregatorOracle.sol";

import "./bases/ManagedAggregatorOracleBase.sol";

contract ManagedPeriodicAggregatorOracle is PeriodicAggregatorOracle, ManagedAggregatorOracleBase {
    constructor(
        AbstractAggregatorOracleParams memory params,
        uint256 period_,
        uint256 granularity_
    ) PeriodicAggregatorOracle(params, period_, granularity_) ManagedAggregatorOracleBase() {}

    function setUpdatesPaused(address token, bool paused) external virtual onlyRole(Roles.UPDATE_PAUSE_ADMIN) {
        uint16 flags = observationBufferMetadata[token].flags;

        bool currentlyPaused = (flags & PAUSE_FLAG_MASK) != 0;
        if (currentlyPaused != paused) {
            if (paused) {
                flags |= PAUSE_FLAG_MASK;
            } else {
                flags &= ~PAUSE_FLAG_MASK;
            }

            observationBufferMetadata[token].flags = flags;

            emit PauseStatusChanged(token, paused);
        } else {
            revert PauseStatusUnchanged(token, paused);
        }
    }

    function areUpdatesPaused(address token) external view virtual returns (bool) {
        return _areUpdatesPaused(token);
    }

    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        // Return false if the message sender is missing the required role
        if (!hasRole(Roles.ORACLE_UPDATER, address(0)) && !hasRole(Roles.ORACLE_UPDATER, msg.sender)) return false;

        address token = abi.decode(data, (address));
        if (_areUpdatesPaused(token)) return false;

        return super.canUpdate(data);
    }

    function update(bytes memory data) public virtual override onlyRoleOrOpenRole(Roles.ORACLE_UPDATER) returns (bool) {
        address token = abi.decode(data, (address));
        if (_areUpdatesPaused(token)) revert UpdatesArePaused(token);

        return super.update(data);
    }

    function quoteTokenDecimals()
        public
        view
        virtual
        override(AbstractAggregatorOracle, ManagedAggregatorOracleBase)
        returns (uint8)
    {
        return AbstractAggregatorOracle.quoteTokenDecimals();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerable, PeriodicAggregatorOracle) returns (bool) {
        return
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            PeriodicAggregatorOracle.supportsInterface(interfaceId);
    }

    function _minimumResponses(address token) internal view virtual override returns (uint256) {
        IOracleAggregatorTokenConfig tokenConfig = tokenConfigs[token];
        if (address(tokenConfig) != address(0)) {
            return tokenConfig.minimumResponses();
        }

        return super._minimumResponses(token);
    }

    function _aggregationStrategy(address token) internal view virtual override returns (IAggregationStrategy) {
        IOracleAggregatorTokenConfig tokenConfig = tokenConfigs[token];
        if (address(tokenConfig) != address(0)) {
            return tokenConfig.aggregationStrategy();
        }

        return super._aggregationStrategy(token);
    }

    function _validationStrategy(address token) internal view virtual override returns (IValidationStrategy) {
        IOracleAggregatorTokenConfig tokenConfig = tokenConfigs[token];
        if (address(tokenConfig) != address(0)) {
            return tokenConfig.validationStrategy();
        }

        return super._validationStrategy(token);
    }

    function _getOracles(address token) internal view virtual override returns (Oracle[] memory oracles) {
        IOracleAggregatorTokenConfig tokenConfig = tokenConfigs[token];
        if (address(tokenConfig) != address(0)) {
            return tokenConfig.oracles();
        }

        return super._getOracles(token);
    }

    function _areUpdatesPaused(address token) internal view virtual returns (bool) {
        return (observationBufferMetadata[token].flags & PAUSE_FLAG_MASK) != 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "./ManagedOracleBase.sol";
import "../configs/IOracleAggregatorTokenConfig.sol";

/// @title ManagedAggregatorOracleBase
/// @notice A base contract for aggregators that are managed by access control with support for token-specific
/// configurations.
abstract contract ManagedAggregatorOracleBase is ManagedOracleBase {
    uint256 internal constant ERROR_MISSING_ORACLES = 1;
    uint256 internal constant ERROR_INVALID_MINIMUM_RESPONSES = 2;
    uint256 internal constant ERROR_INVALID_AGGREGATION_STRATEGY = 3;
    uint256 internal constant ERROR_DUPLICATE_ORACLES = 4;
    uint256 internal constant ERROR_QUOTE_TOKEN_DECIMALS_MISMATCH = 5;
    uint256 internal constant ERROR_MINIMUM_RESPONSES_TOO_LARGE = 6;
    uint256 internal constant ERROR_INVALID_ORACLE = 7;

    /// @notice A mapping of token addresses to their configurations.
    mapping(address => IOracleAggregatorTokenConfig) internal tokenConfigs;

    /// @notice Emitted when a token's configuration is updated.
    /// @param token The token whose configuration was updated.
    /// @param oldConfig The old configuration address.
    /// @param newConfig The new configuration address.
    event TokenConfigUpdated(
        address indexed token,
        IOracleAggregatorTokenConfig oldConfig,
        IOracleAggregatorTokenConfig newConfig
    );

    error InvalidTokenConfig(IOracleAggregatorTokenConfig config, uint256 errorCode);

    /// @notice An error thrown when attempting to set a new token configuration that is the same as the current
    /// configuration (using a only shallow check to allow for implementation changes).
    /// @dev This is thrown to make it more noticeable when nothing changes. It's probably a mistake.
    /// @param token The token whose configuration was unchanged.
    /// @param config The unchanged configuration.
    error TokenConfigUnchanged(address token, IOracleAggregatorTokenConfig config);

    /// @notice Constructs a new ManagedAggregatorOracleBase.
    constructor() ManagedOracleBase() {}

    /**
     * @notice Sets a new configuration for a specific token.
     * @dev This configuration is for the strategies, minimum responses, and underlying oracles.
     * @param token The token to set the configuration for.
     * @param newConfig The new token configuration.
     */
    function setTokenConfig(
        address token,
        IOracleAggregatorTokenConfig newConfig
    ) external onlyRole(Roles.CONFIG_ADMIN) {
        if (address(newConfig) != address(0)) {
            IOracleAggregator.Oracle[] memory oracles = newConfig.oracles();

            // Validate that newConfig.oracles().length > 0
            if (oracles.length == 0) revert InvalidTokenConfig(newConfig, ERROR_MISSING_ORACLES);

            // Validate that newConfig.minimumResponses() > 0
            uint256 minResponses = newConfig.minimumResponses();
            if (minResponses == 0) revert InvalidTokenConfig(newConfig, ERROR_INVALID_MINIMUM_RESPONSES);
            if (minResponses > newConfig.oracles().length)
                revert InvalidTokenConfig(newConfig, ERROR_MINIMUM_RESPONSES_TOO_LARGE);

            // Validate that newConfig.aggregationStrategy() != address(0)
            if (address(newConfig.aggregationStrategy()) == address(0))
                revert InvalidTokenConfig(newConfig, ERROR_INVALID_AGGREGATION_STRATEGY);

            // Validate that there are no duplicate oracles and that no oracle is the zero address
            for (uint256 i = 0; i < oracles.length; ++i) {
                if (address(oracles[i].oracle) == address(0))
                    revert InvalidTokenConfig(newConfig, ERROR_INVALID_ORACLE);

                for (uint256 j = i + 1; j < oracles.length; ++j) {
                    if (address(oracles[i].oracle) == address(oracles[j].oracle))
                        revert InvalidTokenConfig(newConfig, ERROR_DUPLICATE_ORACLES);
                }
            }

            // Validate that the validation strategy's quote token decimals match our quote token decimals
            // (if the validation strategy is set)
            IValidationStrategy validationStrategy = newConfig.validationStrategy();
            if (address(validationStrategy) != address(0)) {
                if (validationStrategy.quoteTokenDecimals() != quoteTokenDecimals())
                    revert InvalidTokenConfig(newConfig, ERROR_QUOTE_TOKEN_DECIMALS_MISMATCH);
            }
        }

        IOracleAggregatorTokenConfig oldConfig = tokenConfigs[token];

        // Ensure that the new config is different from the current config
        if (oldConfig == newConfig) revert TokenConfigUnchanged(token, newConfig);

        tokenConfigs[token] = newConfig;
        emit TokenConfigUpdated(token, oldConfig, newConfig);
    }

    function quoteTokenDecimals() public view virtual returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/access/AccessControlEnumerable.sol";
import "../../access/Roles.sol";

abstract contract ManagedOracleBase is AccessControlEnumerable {
    uint16 internal constant PAUSE_FLAG_MASK = 1;

    /// @notice Event emitted when the pause status of updates for a token is changed.
    /// @param token The token for which the pause status of updates was changed.
    /// @param areUpdatesPaused Whether updates are paused for the token.
    event PauseStatusChanged(address indexed token, bool areUpdatesPaused);

    /// @notice An error that is thrown when we try to change the pause state for a token, but the current pause state
    /// is the same as the new pause state.
    /// @dev This error is thrown to make it easier to notice when we try to change the pause state but nothing changes.
    /// This is useful in preventing human error, in the case that we expect a change when there is none.
    /// @param token The token for which we tried to change the pause state.
    /// @param paused The pause state we tried to set.
    error PauseStatusUnchanged(address token, bool paused);

    /// @notice An error that is thrown when updates are paused for a token.
    /// @param token The token for which updates are paused.
    error UpdatesArePaused(address token);

    /// @notice An error thrown when attempting to call a function that requires a certain role.
    /// @param account The account that is missing the role.
    /// @param role The role that is missing.
    error MissingRole(address account, bytes32 role);

    constructor() {
        initializeRoles();
    }

    /**
     * @notice Modifier to make a function callable only by a certain role. In addition to checking the sender's role,
     * `address(0)` 's role is also considered. Granting a role to `address(0)` is equivalent to enabling this role for
     * everyone.
     * @param role The role to check.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            if (!hasRole(role, msg.sender)) revert MissingRole(msg.sender, role);
        }
        _;
    }

    function initializeRoles() internal virtual {
        // Setup admin role, setting msg.sender as admin
        _setupRole(Roles.ADMIN, msg.sender);
        _setRoleAdmin(Roles.ADMIN, Roles.ADMIN);

        // CONFIG_ADMIN is managed by ADMIN
        _setRoleAdmin(Roles.CONFIG_ADMIN, Roles.ADMIN);

        // UPDATER_ADMIN is managed by ADMIN
        _setRoleAdmin(Roles.UPDATER_ADMIN, Roles.ADMIN);

        // ORACLE_UPDATER is managed by UPDATER_ADMIN
        _setRoleAdmin(Roles.ORACLE_UPDATER, Roles.UPDATER_ADMIN);

        // UPDATE_PAUSE_ADMIN is managed by ADMIN
        _setRoleAdmin(Roles.UPDATE_PAUSE_ADMIN, Roles.ADMIN);

        // Hierarchy:
        // ADMIN
        //   - CONFIG_ADMIN
        //   - UPDATER_ADMIN
        //     - ORACLE_UPDATER
        //   - UPDATE_PAUSE_ADMIN
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

contract AdrastiaVersioning {
    string public constant ADRASTIA_CORE_VERSION = "v4.7.1";
    string public constant ADRASTIA_PERIPHERY_VERSION = "v4.7.2";
    string public constant ADRASTIA_PROTOCOL_VERSION = "v0.1.0";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-periphery/contracts/oracles/ManagedPeriodicAggregatorOracle.sol";

import "../AdrastiaVersioning.sol";

contract AdrastiaPeriodicAggregatorOracle is AdrastiaVersioning, ManagedPeriodicAggregatorOracle {
    string public name;

    constructor(
        string memory name_,
        AbstractAggregatorOracleParams memory params,
        uint256 period_,
        uint256 granularity_
    ) ManagedPeriodicAggregatorOracle(params, period_, granularity_) {
        name = name_;
    }
}