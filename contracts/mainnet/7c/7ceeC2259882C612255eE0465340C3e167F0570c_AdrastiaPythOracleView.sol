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

import "../AbstractOracle.sol";

interface IPyth {
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    function getPriceUnsafe(bytes32 id) external view returns (Price memory price);
}

contract PythOracleView is AbstractOracle {
    address internal immutable feedToken;
    address internal immutable pythAddress;
    bytes32 internal immutable feedId;
    uint64 internal immutable minConfidence;
    uint8 internal immutable feedTokenDecimals;

    uint8 public constant CONFIDENCE_DECIMALS = 8;
    uint256 internal constant CONFIDENCE_MULTIPLIER = 10 ** CONFIDENCE_DECIMALS;

    error AnswerCannotBeNegative(int256 answer);
    error AnswerTooLarge(int256 answer);
    error InvalidTimestamp(uint256 timestamp);
    error UnsupportedToken(address token);
    error InvalidConstructorArgument();
    error ConfidenceTooLow(uint256 confidence);
    error InvalidExponent(int32 exponent);

    /**
     * @notice Constructs a new PythOracleView contract.
     * @param pythAddress_  The address of the Pyth contract.
     * @param feedId_  The ID of the Pyth feed.
     * @param feedToken_  The address of the token that the feed describes.
     * @param minConfidence_  The minimum confidence level required for the oracle to return a price.
     *   1e`CONFIDENCE_DECIMALS` represents 100% confidence and 0 represents 0% confidence. 0% confidence is not
     *   allowed.
     * @param quoteToken_  (Optional) The address of the quote token.
     */
    constructor(
        address pythAddress_,
        bytes32 feedId_,
        address feedToken_,
        uint64 minConfidence_,
        address quoteToken_
    ) AbstractOracle(quoteToken_) {
        if (pythAddress_ == address(0) || feedToken_ == address(0) || minConfidence_ == 0) {
            revert InvalidConstructorArgument();
        }

        pythAddress = pythAddress_;
        feedId = feedId_;
        feedToken = feedToken_;
        minConfidence = minConfidence_;
        feedTokenDecimals = super.quoteTokenDecimals();
    }

    /// @inheritdoc IOracle
    function liquidityDecimals() public view virtual override returns (uint8) {
        return 0; // Liquidity is not supported
    }

    /**
     * @notice Updates the oracle data.
     * @dev This oracle doesn't support updates.
     * @return False as this oracle doesn't support updates.
     */
    function update(bytes memory) public virtual override returns (bool) {
        return false;
    }

    /**
     * @notice Checks if the oracle needs an update.
     * @dev This oracle doesn't support updates.
     * @return False as this oracle doesn't need updates.
     */
    function needsUpdate(bytes memory) public view virtual override returns (bool) {
        return false;
    }

    /**
     * @notice Checks if the oracle can be updated.
     * @dev This oracle doesn't support updates.
     * @return False as this oracle can't be updated.
     */
    function canUpdate(bytes memory) public view virtual override returns (bool) {
        return false;
    }

    /**
     * @notice Retrieves the latest observation data by consulting the underlying accumulators.
     * @dev The observation timestamp is the oldest of the two accumulator observation timestamps.
     * @param token The address of the token.
     * @return observation The latest observation data.
     */
    function getLatestObservation(
        address token
    ) public view virtual override returns (ObservationLibrary.Observation memory observation) {
        (observation.price, observation.timestamp) = readUnderlyingFeed(token);
        observation.tokenLiquidity = 0;
        observation.quoteTokenLiquidity = 0;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenDecimals() public view virtual override(SimpleQuotationMetadata, IQuoteToken) returns (uint8) {
        return feedTokenDecimals;
    }

    function getUnderlyingFeed() public view virtual returns (address) {
        return pythAddress;
    }

    function getUnderlyingFeedId() public view virtual returns (bytes32) {
        return feedId;
    }

    function getFeedToken() public view virtual returns (address) {
        return feedToken;
    }

    /**
     * @notice Gets the minimum confidence level required for the oracle to return a price.
     * @return The minimum confidence level, with 1e`CONFIDENCE_DECIMALS` representing 100% confidence and 0
     * representing 0% confidence.
     */
    function getMinConfidence() public view virtual returns (uint64) {
        return minConfidence;
    }

    /// @inheritdoc AbstractOracle
    function instantFetch(
        address token
    ) internal view virtual override returns (uint112 price, uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        (price, ) = readUnderlyingFeed(token);
        tokenLiquidity = 0;
        quoteTokenLiquidity = 0;
    }

    function readUnderlyingFeed(address token) internal view virtual returns (uint112 price, uint32 timestamp) {
        if (token != getFeedToken()) {
            revert UnsupportedToken(token);
        }

        IPyth.Price memory data = IPyth(getUnderlyingFeed()).getPriceUnsafe(getUnderlyingFeedId());

        if (data.price < 0) {
            revert AnswerCannotBeNegative(data.price);
        }

        uint256 ourDecimals = quoteTokenDecimals();
        uint256 workingPrice = uint256(int256(data.price)) * (10 ** ourDecimals);
        uint256 confidenceInterval = uint256(data.conf) * (10 ** ourDecimals);
        if (data.expo > 12 || data.expo < -12) {
            // The range of exponents supported by the Pyth Network client code is [-12, 12]
            revert InvalidExponent(data.expo);
        } else if (data.expo < 0) {
            uint256 divisor = 10 ** uint32(-data.expo);
            workingPrice /= divisor;
            confidenceInterval /= divisor;
        } else if (data.expo > 0) {
            uint256 multiplier = 10 ** uint32(data.expo);
            workingPrice *= multiplier;
            confidenceInterval *= multiplier;
        }

        if (workingPrice > type(uint112).max) {
            revert AnswerTooLarge(data.price);
        }

        if (data.publishTime == 0 || data.publishTime > type(uint32).max) {
            revert InvalidTimestamp(data.publishTime);
        }

        if (workingPrice > 0) {
            // Inverse confidence: 0 is 100% confidence; CONFIDENCE_MULTIPLIER or above is 0% confidence
            uint256 confidence = ((confidenceInterval * CONFIDENCE_MULTIPLIER) / workingPrice);
            if (confidence > CONFIDENCE_MULTIPLIER) {
                revert ConfidenceTooLow(0);
            }
            // Confidence: 0 is 0% confidence; CONFIDENCE_MULTIPLIER is 100% confidence
            confidence = CONFIDENCE_MULTIPLIER - confidence;
            if (confidence < getMinConfidence()) {
                revert ConfidenceTooLow(confidence);
            }
        } else {
            if (data.conf > 0) {
                // If the confidence interval is non-zero, we can't trust the price
                // The price can only be zero if we're 100% confident that it's zero
                revert ConfidenceTooLow(0);
            }
        }

        price = uint112(workingPrice);
        timestamp = uint32(data.publishTime);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

contract AdrastiaVersioning {
    string public constant ADRASTIA_CORE_VERSION = "v4.7.1";
    string public constant ADRASTIA_PERIPHERY_VERSION = "v4.7.2";
    string public constant ADRASTIA_PROTOCOL_VERSION = "v0.1.0";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-core/contracts/oracles/views/PythOracleView.sol";

import "../../AdrastiaVersioning.sol";

contract AdrastiaPythOracleView is AdrastiaVersioning, PythOracleView {
    struct PythOracleViewParams {
        address pythAddress;
        bytes32 feedId;
        address feedToken;
        uint64 minConfidence;
        address quoteToken;
    }

    string public name;

    constructor(
        string memory name_,
        PythOracleViewParams memory params
    ) PythOracleView(params.pythAddress, params.feedId, params.feedToken, params.minConfidence, params.quoteToken) {
        name = name_;
    }
}