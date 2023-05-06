// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {AggregatorV2V3Interface} from "src/interfaces/AggregatorV2V3Interface.sol";
import "src/bases/BondBaseOracle.sol";
import {FullMath} from "src/lib/FullMath.sol";

/// @title Bond Chainlink Oracle
/// @notice Bond Chainlink Oracle Sample Contract
contract BondChainlinkOracleArbitrum is BondBaseOracle {
    using FullMath for uint256;

    /* ========== ERRORS ========== */
    error BondOracle_BadFeed(address feed_);
    error BondOracle_SequencerDown();

    /* ========== STATE VARIABLES ========== */

    AggregatorV2V3Interface public immutable sequencerUptimeFeed;
    uint256 public constant SEQUENCER_GRACE_PERIOD = 1 hours;

    /// @dev Parameters to configure price feeds for a pair of tokens. There are 4 cases:
    /// 1. Single feed -> Use when there is a price feed for the exact asset pair in quote
    ///     tokens per payout token (e.g. OHM/ETH which provides the number of ETH (qt) per OHM (pt))
    ///
    ///     Params: numeratorFeed, numeratorUpdateThreshold, 0, 0, decimals, false
    ///
    /// 2. Single feed inverse -> Use when there is a price for the opposite of your asset
    ///     pair in quote tokens per payout token (e.g. OHM/ETH which provides the number
    ///     of ETH per OHM, but you need the number of OHM (qt) per ETH (pt)).
    ///
    ///     Params: numeratorFeed, numeratorUpdateThreshold, 0, 0, decimals, true
    ///
    /// 3. Double feed mul -> Use when two price feeds are required to get the price of the
    ///      desired asset pair in quote tokens per payout token. For example, if you need the
    ///      price of OHM/USD, but there is only a price feed for OHM/ETH and ETH/USD, then
    ///      multiplying the two feeds will give you the price of OHM/USD.
    ///
    ///     Params: numeratorFeed, numeratorUpdateThreshold, denominatorFeed, denominatorUpdateThreshold, decimals, false
    ///
    /// 4. Double feed div -> Use when two price feeds are required to get the price of the
    ///      desired asset pair in quote tokens per payout token. For example, if you need the
    ///      price of OHM/DAI, but there is only a price feed for OHM/ETH and DAI/ETH, then
    ///      dividing the two feeds will give you the price of OHM/DAI.
    ///
    ///     Params: numeratorFeed, numeratorUpdateThreshold, denominatorFeed, denominatorUpdateThreshold, decimals, true
    ///
    struct PriceFeedParams {
        AggregatorV2V3Interface numeratorFeed; // address of the numerator (or first) price feed
        uint48 numeratorUpdateThreshold; // update threshold for the numerator price feed, will revert if data is older than block.timestamp - this
        AggregatorV2V3Interface denominatorFeed; // address of the denominator (or second) price feed. if zero address, then only use numerator feed
        uint48 denominatorUpdateThreshold; // update threshold for the denominator price feed, will revert if data is older than block.timestamp - this
        uint8 decimals; // number of decimals that the price should be scaled to
        bool div; // if true, then the numerator feed is divided by the denominator feed, otherwise multiplied. if only one feed is used, then div = false is standard and div = true is the inverse.
    }

    mapping(ERC20 => mapping(ERC20 => PriceFeedParams)) public priceFeedParams;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address aggregator_,
        address[] memory auctioneers_,
        address sequencerUptimeFeed_
    ) BondBaseOracle(aggregator_, auctioneers_) {
        sequencerUptimeFeed = AggregatorV2V3Interface(sequencerUptimeFeed_);
    }

    /* ========== PRICE ========== */

    function _currentPrice(ERC20 quoteToken_, ERC20 payoutToken_)
        internal
        view
        override
        returns (uint256)
    {
        PriceFeedParams memory params = priceFeedParams[quoteToken_][payoutToken_];

        // Validate arbitrum sequencer is up
        _validateSequencerUp();

        // Get price from feed
        if (address(params.denominatorFeed) == address(0)) {
            return _getOneFeedPrice(params);
        } else {
            return _getTwoFeedPrice(params);
        }
    }

    function _getOneFeedPrice(PriceFeedParams memory params_) internal view returns (uint256) {
        // Get price from feed
        uint256 price = _validateAndGetPrice(
            params_.numeratorFeed,
            params_.numeratorUpdateThreshold
        );

        // Scale price and return
        return
            params_.div
                ? (10**params_.decimals).mulDiv(10**(params_.numeratorFeed.decimals()), price)
                : price.mulDiv(10**params_.decimals, 10**(params_.numeratorFeed.decimals()));
    }

    function _getTwoFeedPrice(PriceFeedParams memory params_) internal view returns (uint256) {
        // Get decimal value scale factor
        uint8 exponent;
        uint8 denomDecimals = params_.denominatorFeed.decimals();
        uint8 numDecimals = params_.numeratorFeed.decimals();
        if (params_.div) {
            if (params_.decimals + denomDecimals < numDecimals) revert BondOracle_InvalidParams();
            exponent =
                params_.decimals +
                params_.denominatorFeed.decimals() -
                params_.numeratorFeed.decimals();
        } else {
            if (numDecimals + denomDecimals < params_.decimals) revert BondOracle_InvalidParams();
            exponent =
                params_.denominatorFeed.decimals() +
                params_.numeratorFeed.decimals() -
                params_.decimals;
        }

        // Get prices from feeds
        uint256 numeratorPrice = _validateAndGetPrice(
            params_.numeratorFeed,
            params_.numeratorUpdateThreshold
        );
        uint256 denominatorPrice = _validateAndGetPrice(
            params_.denominatorFeed,
            params_.denominatorUpdateThreshold
        );

        // Calculate and scale price
        return
            params_.div
                ? numeratorPrice.mulDiv(10**exponent, denominatorPrice)
                : numeratorPrice.mulDiv(denominatorPrice, 10**exponent);
    }

    function _validateAndGetPrice(AggregatorV2V3Interface feed_, uint48 updateThreshold_)
        internal
        view
        returns (uint256)
    {
        // Get latest round data from feed
        (uint80 roundId, int256 priceInt, , uint256 updatedAt, uint80 answeredInRound) = feed_
            .latestRoundData();

        // Validate chainlink price feed data
        // 1. Answer should be greater than zero
        // 2. Updated at timestamp should be within the update threshold
        // 3. Answered in round ID should be the same as the round ID
        if (
            priceInt <= 0 ||
            updatedAt < block.timestamp - uint256(updateThreshold_) ||
            answeredInRound != roundId
        ) revert BondOracle_BadFeed(address(feed_));
        return uint256(priceInt);
    }

    function _validateSequencerUp() internal view {
        // Get latest round data from sequencer uptime feed
        (, int256 status, uint256 startedAt, , ) = sequencerUptimeFeed.latestRoundData();

        // Validate sequencer uptime feed data
        // 1. Status should be 0 (up). If 1, then it's down
        // 2. Current timestamp should be past catch-up grace period after a restart
        if (status == 1 || block.timestamp - startedAt <= SEQUENCER_GRACE_PERIOD)
            revert BondOracle_SequencerDown();
    }

    /* ========== DECIMALS ========== */

    function _decimals(ERC20 quoteToken_, ERC20 payoutToken_)
        internal
        view
        override
        returns (uint8)
    {
        return priceFeedParams[quoteToken_][payoutToken_].decimals;
    }

    /* ========== ADMIN ========== */

    function _setPair(
        ERC20 quoteToken_,
        ERC20 payoutToken_,
        bool supported_,
        bytes memory oracleData_
    ) internal override {
        if (supported_) {
            // Decode oracle data into PriceFeedParams struct
            PriceFeedParams memory params = abi.decode(oracleData_, (PriceFeedParams));

            // Feed decimals
            uint8 numerDecimals = params.numeratorFeed.decimals();
            uint8 denomDecimals = address(params.denominatorFeed) != address(0)
                ? params.denominatorFeed.decimals()
                : 0;

            // Validate params
            if (
                address(params.numeratorFeed) == address(0) ||
                params.numeratorUpdateThreshold < uint48(1 hours) ||
                params.numeratorUpdateThreshold > uint48(7 days) ||
                params.decimals < 6 ||
                params.decimals > 18 ||
                numerDecimals < 6 ||
                numerDecimals > 18 ||
                (address(params.denominatorFeed) == address(0) &&
                    !params.div &&
                    params.decimals < numerDecimals) ||
                (address(params.denominatorFeed) != address(0) &&
                    (params.denominatorUpdateThreshold < uint48(1 hours) ||
                        params.denominatorUpdateThreshold > uint48(7 days) ||
                        denomDecimals < 6 ||
                        denomDecimals > 18 ||
                        (params.div && params.decimals + denomDecimals < numerDecimals) ||
                        (!params.div && numerDecimals + denomDecimals < params.decimals)))
            ) revert BondOracle_InvalidParams();

            // Store params for token pair
            priceFeedParams[quoteToken_][payoutToken_] = params;
        } else {
            // Delete params for token pair
            delete priceFeedParams[quoteToken_][payoutToken_];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

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
}

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondOracle} from "../interfaces/IBondOracle.sol";
import {IBondAggregator} from "../interfaces/IBondAggregator.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

/// @title Bond Oracle
/// @notice Bond Oracle Base Contract
/// @dev Bond Protocol is a system to create bond markets for any token pair.
///      The markets do not require maintenance and will manage bond prices
///      based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev Oracles are used by Oracle-based Auctioneers in the Bond system.
///      This base contract implements the IBondOracle interface and provides
///      a starting point for implementing custom Oracle contract.
///      Market creators deploy their own instances of Oracle contracts to
///      control the price feeds used for specific token pairs.
///
/// @author Oighty
abstract contract BondBaseOracle is IBondOracle, Ownable {
    /* ========== ERRORS ========== */
    error BondOracle_InvalidParams();
    error BondOracle_NotAuctioneer(address auctioneer);
    error BondOracle_PairNotSupported(ERC20 quoteToken, ERC20 payoutToken);
    error BondOracle_MarketNotRegistered(uint256 id);

    /* ========== EVENTS ========== */
    event PairUpdated(ERC20 quoteToken, ERC20 payoutToken, bool supported);
    event AuctioneerUpdated(address auctioneer, bool supported);
    event MarketRegistered(uint256 id, ERC20 quoteToken, ERC20 payoutToken);

    /* ========== STATE VARIABLES ========== */
    IBondAggregator public immutable aggregator;

    /// @notice Index of market to [quoteToken, payoutToken]
    mapping(uint256 => ERC20[2]) public markets;

    /// @notice Index of supported token pairs (quoteToken => payoutToken => supported)
    mapping(ERC20 => mapping(ERC20 => bool)) public supportedPairs;

    /// @notice Index of supported auctioneers (auctioneer => supported)
    mapping(address => bool) public isAuctioneer;

    /* ========== CONSTRUCTOR ========== */
    constructor(address aggregator_, address[] memory auctioneers_) {
        aggregator = IBondAggregator(aggregator_);

        uint256 len = auctioneers_.length;
        for (uint256 i = 0; i < len; ++i) {
            isAuctioneer[auctioneers_[i]] = true;
        }
    }

    /* ========== REGISTER ========== */
    /// @inheritdoc IBondOracle
    function registerMarket(
        uint256 id_,
        ERC20 quoteToken_,
        ERC20 payoutToken_
    ) external virtual override {
        // Confirm that call is from supported auctioneer
        if (!isAuctioneer[msg.sender]) revert BondOracle_NotAuctioneer(msg.sender);

        // Confirm that the calling auctioneer is the creator of the market ID
        if (address(aggregator.getAuctioneer(id_)) != msg.sender) revert BondOracle_InvalidParams();

        // Confirm that the quote token : payout token pair is supported
        if (!supportedPairs[quoteToken_][payoutToken_])
            revert BondOracle_PairNotSupported(quoteToken_, payoutToken_);

        // Store pair for market ID
        markets[id_] = [quoteToken_, payoutToken_];

        // Emit event
        emit MarketRegistered(id_, quoteToken_, payoutToken_);
    }

    /* ========== PRICE ========== */
    /// @inheritdoc IBondOracle
    function currentPrice(uint256 id_) external view virtual override returns (uint256) {
        // Get tokens for market
        ERC20[2] memory tokens = markets[id_];

        // Check that the market is registered on this oracle
        if (address(tokens[0]) == address(0) || address(tokens[1]) == address(0))
            revert BondOracle_MarketNotRegistered(id_);

        // Get price from oracle
        return _currentPrice(tokens[0], tokens[1]);
    }

    /// @inheritdoc IBondOracle
    function currentPrice(ERC20 quoteToken_, ERC20 payoutToken_)
        external
        view
        virtual
        override
        returns (uint256)
    {
        // Check that the pair is supported by the oracle
        if (
            address(quoteToken_) == address(0) ||
            address(payoutToken_) == address(0) ||
            !supportedPairs[quoteToken_][payoutToken_]
        ) revert BondOracle_PairNotSupported(quoteToken_, payoutToken_);

        // Get price from oracle
        return _currentPrice(quoteToken_, payoutToken_);
    }

    function _currentPrice(ERC20 quoteToken_, ERC20 payoutToken_)
        internal
        view
        virtual
        returns (uint256);

    /* ========== DECIMALS ========== */
    /// @inheritdoc IBondOracle
    function decimals(uint256 id_) external view virtual override returns (uint8) {
        // Get tokens for market
        ERC20[2] memory tokens = markets[id_];

        // Check that the market is registered on this oracle
        if (address(tokens[0]) == address(0) || address(tokens[1]) == address(0))
            revert BondOracle_MarketNotRegistered(id_);

        // Get decimals from oracle
        return _decimals(tokens[0], tokens[1]);
    }

    /// @inheritdoc IBondOracle
    function decimals(ERC20 quoteToken_, ERC20 payoutToken_)
        external
        view
        virtual
        override
        returns (uint8)
    {
        // Check that the pair is supported by the oracle
        if (
            address(quoteToken_) == address(0) ||
            address(payoutToken_) == address(0) ||
            !supportedPairs[quoteToken_][payoutToken_]
        ) revert BondOracle_PairNotSupported(quoteToken_, payoutToken_);

        // Get decimals from oracle
        return _decimals(quoteToken_, payoutToken_);
    }

    function _decimals(ERC20 quoteToken_, ERC20 payoutToken_) internal view virtual returns (uint8);

    /* ========== ADMIN ========== */

    function setAuctioneer(address auctioneer_, bool supported_) external onlyOwner {
        // Check auctioneers current status and revert is not changed to avoid emitting unnecessary events
        if (isAuctioneer[auctioneer_] == supported_) revert BondOracle_InvalidParams();

        // Add/remove auctioneer
        isAuctioneer[auctioneer_] = supported_;

        // Emit event
        emit AuctioneerUpdated(auctioneer_, supported_);
    }

    function setPair(
        ERC20 quoteToken_,
        ERC20 payoutToken_,
        bool supported_,
        bytes calldata oracleData_
    ) external onlyOwner {
        // Don't allow setting tokens to zero address
        if (address(quoteToken_) == address(0) || address(payoutToken_) == address(0))
            revert BondOracle_InvalidParams();

        // Toggle pair status
        supportedPairs[quoteToken_][payoutToken_] = supported_;

        // Update oracle data for particular implementation
        _setPair(quoteToken_, payoutToken_, supported_, oracleData_);

        // Emit event
        emit PairUpdated(quoteToken_, payoutToken_, supported_);
    }

    function _setPair(
        ERC20 quoteToken_,
        ERC20 payoutToken_,
        bool supported_,
        bytes memory oracleData_
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondOracle {
    /// @notice Register a new bond market on the oracle
    function registerMarket(
        uint256 id_,
        ERC20 quoteToken_,
        ERC20 payoutToken_
    ) external;

    /// @notice Returns the price as a ratio of quote tokens to base tokens for the provided market id scaled by 10^decimals
    function currentPrice(uint256 id_) external view returns (uint256);

    /// @notice Returns the price as a ratio of quote tokens to base tokens for the provided token pair scaled by 10^decimals
    function currentPrice(ERC20 quoteToken_, ERC20 payoutToken_) external view returns (uint256);

    /// @notice Returns the number of configured decimals of the price value for the provided market id
    function decimals(uint256 id_) external view returns (uint8);

    /// @notice Returns the number of configured decimals of the price value for the provided token pair
    function decimals(ERC20 quoteToken_, ERC20 payoutToken_) external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondAuctioneer} from "../interfaces/IBondAuctioneer.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";

interface IBondAggregator {
    /// @notice             Register a auctioneer with the aggregator
    /// @notice             Only Guardian
    /// @param auctioneer_  Address of the Auctioneer to register
    /// @dev                A auctioneer must be registered with an aggregator to create markets
    function registerAuctioneer(IBondAuctioneer auctioneer_) external;

    /// @notice             Register a new market with the aggregator
    /// @notice             Only registered depositories
    /// @param payoutToken_ Token to be paid out by the market
    /// @param quoteToken_  Token to be accepted by the market
    /// @param marketId     ID of the market being created
    function registerMarket(ERC20 payoutToken_, ERC20 quoteToken_)
        external
        returns (uint256 marketId);

    /// @notice     Get the auctioneer for the provided market ID
    /// @param id_  ID of Market
    function getAuctioneer(uint256 id_) external view returns (IBondAuctioneer);

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @dev                Accounts for debt and control variable decay since last deposit (vs _marketPrice())
    /// @param id_          ID of market
    /// @return             Price for market (see the specific auctioneer for units)
    //
    // if price is below minimum price, minimum price is returned
    // this is enforced on deposits by manipulating total debt (see _decay())
    function marketPrice(uint256 id_) external view returns (uint256);

    /// @notice             Scale value to use when converting between quote token and payout token amounts with marketPrice()
    /// @param id_          ID of market
    /// @return             Scaling factor for market in configured decimals
    function marketScale(uint256 id_) external view returns (uint256);

    /// @notice             Payout due for amount of quote tokens
    /// @dev                Accounts for debt and control variable decay so it is up to date
    /// @param amount_      Amount of quote tokens to spend
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    /// @return             amount of payout tokens to be paid
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) external view returns (uint256);

    /// @notice             Returns maximum amount of quote token accepted by the market
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256);

    /// @notice             Does market send payout immediately
    /// @param id_          Market ID to search for
    function isInstantSwap(uint256 id_) external view returns (bool);

    /// @notice             Is a given market accepting deposits
    /// @param id_          ID of market
    function isLive(uint256 id_) external view returns (bool);

    /// @notice             Returns array of active market IDs within a range
    /// @dev                Should be used if length exceeds max to query entire array
    function liveMarketsBetween(uint256 firstIndex_, uint256 lastIndex_)
        external
        view
        returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given quote token
    /// @param token_       Address of token to query by
    /// @param isPayout_    If true, search by payout token, else search for quote token
    function liveMarketsFor(address token_, bool isPayout_)
        external
        view
        returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given owner
    /// @param owner_       Address of owner to query by
    /// @param firstIndex_  Market ID to start at
    /// @param lastIndex_   Market ID to end at (non-inclusive)
    function liveMarketsBy(
        address owner_,
        uint256 firstIndex_,
        uint256 lastIndex_
    ) external view returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given payout and quote token
    /// @param payout_      Address of payout token
    /// @param quote_       Address of quote token
    function marketsFor(address payout_, address quote_) external view returns (uint256[] memory);

    /// @notice                 Returns the market ID with the highest current payoutToken payout for depositing quoteToken
    /// @param payout_          Address of payout token
    /// @param quote_           Address of quote token
    /// @param amountIn_        Amount of quote tokens to deposit
    /// @param minAmountOut_    Minimum amount of payout tokens to receive as payout
    /// @param maxExpiry_       Latest acceptable vesting timestamp for bond
    ///                         Inputting the zero address will take into account just the protocol fee.
    function findMarketFor(
        address payout_,
        address quote_,
        uint256 amountIn_,
        uint256 minAmountOut_,
        uint256 maxExpiry_
    ) external view returns (uint256 id);

    /// @notice             Returns the Teller that services the market ID
    function getTeller(uint256 id_) external view returns (IBondTeller);

    /// @notice             Returns current capacity of a market
    function currentCapacity(uint256 id_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";
import {IBondAggregator} from "../interfaces/IBondAggregator.sol";

interface IBondAuctioneer {
    /// @notice                 Creates a new bond market
    /// @param params_          Configuration data needed for market creation, encoded in a bytes array
    /// @dev                    See specific auctioneer implementations for details on encoding the parameters.
    /// @return id              ID of new bond market
    function createMarket(bytes memory params_) external returns (uint256);

    /// @notice                 Disable existing bond market
    /// @notice                 Must be market owner
    /// @param id_              ID of market to close
    function closeMarket(uint256 id_) external;

    /// @notice                 Exchange quote tokens for a bond in a specified market
    /// @notice                 Must be teller
    /// @param id_              ID of the Market the bond is being purchased from
    /// @param amount_          Amount to deposit in exchange for bond (after fee has been deducted)
    /// @param minAmountOut_    Minimum acceptable amount of bond to receive. Prevents frontrunning
    /// @return payout          Amount of payout token to be received from the bond
    function purchaseBond(
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external returns (uint256 payout);

    /// @notice                         Set market intervals to different values than the defaults
    /// @notice                         Must be market owner
    /// @dev                            Changing the intervals could cause markets to behave in unexpected way
    ///                                 tuneInterval should be greater than tuneAdjustmentDelay
    /// @param id_                      Market ID
    /// @param intervals_               Array of intervals (3)
    ///                                 1. Tune interval - Frequency of tuning
    ///                                 2. Tune adjustment delay - Time to implement downward tuning adjustments
    ///                                 3. Debt decay interval - Interval over which debt should decay completely
    function setIntervals(uint256 id_, uint32[3] calldata intervals_) external;

    /// @notice                      Designate a new owner of a market
    /// @notice                      Must be market owner
    /// @dev                         Doesn't change permissions until newOwner calls pullOwnership
    /// @param id_                   Market ID
    /// @param newOwner_             New address to give ownership to
    function pushOwnership(uint256 id_, address newOwner_) external;

    /// @notice                      Accept ownership of a market
    /// @notice                      Must be market newOwner
    /// @dev                         The existing owner must call pushOwnership prior to the newOwner calling this function
    /// @param id_                   Market ID
    function pullOwnership(uint256 id_) external;

    /// @notice             Set the auctioneer defaults
    /// @notice             Must be policy
    /// @param defaults_    Array of default values
    ///                     1. Tune interval - amount of time between tuning adjustments
    ///                     2. Tune adjustment delay - amount of time to apply downward tuning adjustments
    ///                     3. Minimum debt decay interval - minimum amount of time to let debt decay to zero
    ///                     4. Minimum deposit interval - minimum amount of time to wait between deposits
    ///                     5. Minimum market duration - minimum amount of time a market can be created for
    ///                     6. Minimum debt buffer - the minimum amount of debt over the initial debt to trigger a market shutdown
    /// @dev                The defaults set here are important to avoid edge cases in market behavior, e.g. a very short market reacts doesn't tune well
    /// @dev                Only applies to new markets that are created after the change
    function setDefaults(uint32[6] memory defaults_) external;

    /// @notice             Change the status of the auctioneer to allow creation of new markets
    /// @dev                Setting to false and allowing active markets to end will sunset the auctioneer
    /// @param status_      Allow market creation (true) : Disallow market creation (false)
    function setAllowNewMarkets(bool status_) external;

    /// @notice             Change whether a market creator is allowed to use a callback address in their markets or not
    /// @notice             Must be guardian
    /// @dev                Callback is believed to be safe, but a whitelist is implemented to prevent abuse
    /// @param creator_     Address of market creator
    /// @param status_      Allow callback (true) : Disallow callback (false)
    function setCallbackAuthStatus(address creator_, bool status_) external;

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice                 Provides information for the Teller to execute purchases on a Market
    /// @param id_              Market ID
    /// @return owner           Address of the market owner (tokens transferred from this address if no callback)
    /// @return callbackAddr    Address of the callback contract to get tokens for payouts
    /// @return payoutToken     Payout Token (token paid out) for the Market
    /// @return quoteToken      Quote Token (token received) for the Market
    /// @return vesting         Timestamp or duration for vesting, implementation-dependent
    /// @return maxPayout       Maximum amount of payout tokens you can purchase in one transaction
    function getMarketInfoForPurchase(uint256 id_)
        external
        view
        returns (
            address owner,
            address callbackAddr,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 vesting,
            uint256 maxPayout
        );

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @param id_          ID of market
    /// @return             Price for market in configured decimals
    //
    // if price is below minimum price, minimum price is returned
    function marketPrice(uint256 id_) external view returns (uint256);

    /// @notice             Scale value to use when converting between quote token and payout token amounts with marketPrice()
    /// @param id_          ID of market
    /// @return             Scaling factor for market in configured decimals
    function marketScale(uint256 id_) external view returns (uint256);

    /// @notice             Payout due for amount of quote tokens
    /// @dev                Accounts for debt and control variable decay so it is up to date
    /// @param amount_      Amount of quote tokens to spend
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    /// @return             amount of payout tokens to be paid
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) external view returns (uint256);

    /// @notice             Returns maximum amount of quote token accepted by the market
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256);

    /// @notice             Does market send payout immediately
    /// @param id_          Market ID to search for
    function isInstantSwap(uint256 id_) external view returns (bool);

    /// @notice             Is a given market accepting deposits
    /// @param id_          ID of market
    function isLive(uint256 id_) external view returns (bool);

    /// @notice             Returns the address of the market owner
    /// @param id_          ID of market
    function ownerOf(uint256 id_) external view returns (address);

    /// @notice             Returns the Teller that services the Auctioneer
    function getTeller() external view returns (IBondTeller);

    /// @notice             Returns the Aggregator that services the Auctioneer
    function getAggregator() external view returns (IBondAggregator);

    /// @notice             Returns current capacity of a market
    function currentCapacity(uint256 id_) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondTeller {
    /// @notice                 Exchange quote tokens for a bond in a specified market
    /// @param recipient_       Address of recipient of bond. Allows deposits for other addresses
    /// @param referrer_        Address of referrer who will receive referral fee. For frontends to fill.
    ///                         Direct calls can use the zero address for no referrer fee.
    /// @param id_              ID of the Market the bond is being purchased from
    /// @param amount_          Amount to deposit in exchange for bond
    /// @param minAmountOut_    Minimum acceptable amount of bond to receive. Prevents frontrunning
    /// @return                 Amount of payout token to be received from the bond
    /// @return                 Timestamp at which the bond token can be redeemed for the underlying token
    function purchase(
        address recipient_,
        address referrer_,
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external returns (uint256, uint48);

    /// @notice          Get current fee charged by the teller based on the combined protocol and referrer fee
    /// @param referrer_ Address of the referrer
    /// @return          Fee in basis points (3 decimal places)
    function getFee(address referrer_) external view returns (uint48);

    /// @notice         Set protocol fee
    /// @notice         Must be guardian
    /// @param fee_     Protocol fee in basis points (3 decimal places)
    function setProtocolFee(uint48 fee_) external;

    /// @notice          Set the discount for creating bond tokens from the base protocol fee
    /// @dev             The discount is subtracted from the protocol fee to determine the fee
    ///                  when using create() to mint bond tokens without using an Auctioneer
    /// @param discount_ Create Fee Discount in basis points (3 decimal places)
    function setCreateFeeDiscount(uint48 discount_) external;

    /// @notice         Set your fee as a referrer to the protocol
    /// @notice         Fee is set for sending address
    /// @param fee_     Referrer fee in basis points (3 decimal places)
    function setReferrerFee(uint48 fee_) external;

    /// @notice         Claim fees accrued by sender in the input tokens and sends them to the provided address
    /// @param tokens_  Array of tokens to claim fees for
    /// @param to_      Address to send fees to
    function claimFees(ERC20[] memory tokens_, address to_) external;
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