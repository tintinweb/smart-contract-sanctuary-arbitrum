// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import {BondBaseOSDA, IBondAggregator, Authority} from "./bases/BondBaseOSDA.sol";
import {IBondTeller} from "./interfaces/IBondTeller.sol";

/// @title Bond Fixed-Term Oracle-based Sequential Dutch Auctioneer
/// @notice Bond Fixed-Term Oracle-based Sequential Dutch Auctioneer Contract
/// @dev Bond Protocol is a permissionless system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The Fixed-Term Oracle-based SDA is an implementation of the
///      Bond Base OSDA contract specific to creating bond markets where
///      purchases vest in a fixed amount of time after purchased (rounded to the day).
///
/// @author Oighty, Zeus, Potted Meat, indigo
contract BondFixedTermOSDA is BondBaseOSDA {
    /* ========== CONSTRUCTOR ========== */
    constructor(
        IBondTeller teller_,
        IBondAggregator aggregator_,
        address guardian_,
        Authority authority_
    ) BondBaseOSDA(teller_, aggregator_, guardian_, authority_) {}

    /* ========== MARKET FUNCTIONS ========== */
    /// @inheritdoc BondBaseOSDA
    function createMarket(bytes calldata params_) external override returns (uint256) {
        // Decode params into the struct type expected by this auctioneer
        MarketParams memory params = abi.decode(params_, (MarketParams));

        // Check that the vesting parameter is valid for a fixed-term market
        if (params.vesting != 0 && (params.vesting < 1 days || params.vesting > MAX_FIXED_TERM))
            revert Auctioneer_InvalidParams();

        // Create market and return market ID
        return _createMarket(params);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {IBondOSDA, IBondAuctioneer} from "../interfaces/IBondOSDA.sol";
import {IBondOracle} from "../interfaces/IBondOracle.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";
import {IBondCallback} from "../interfaces/IBondCallback.sol";
import {IBondAggregator} from "../interfaces/IBondAggregator.sol";

import {TransferHelper} from "../lib/TransferHelper.sol";
import {FullMath} from "../lib/FullMath.sol";

/// @title Bond Oracle-based Sequential Dutch Auctioneer (OSDA)
/// @notice Bond Oracle-based Sequential Dutch Auctioneer Base Contract
/// @dev Bond Protocol is a system to create bond markets for any token pair.
///      The markets do not require maintenance and will manage bond prices
///      based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The Oracle-based Sequential Dutch Auctioneer contract allows users to create
///      and manage bond markets. All bond market data is stored in the Auctioneer.
///      The market price is based on an outside Oracle and varies based on whether the
///      market is under- or oversold with the goal of selling a target amount of
///      payout tokens or buying a target amount of quote tokens over the duration of
///      a market. An Auctioneer is dependent on a Teller to serve external users and
///      an Aggregator to register new markets.
///
/// @author Oighty
abstract contract BondBaseOSDA is IBondOSDA, Auth {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    /* ========== ERRORS ========== */

    error Auctioneer_OnlyMarketOwner();
    error Auctioneer_InitialPriceLessThanMin();
    error Auctioneer_MarketNotActive();
    error Auctioneer_MaxPayoutExceeded();
    error Auctioneer_AmountLessThanMinimum();
    error Auctioneer_NotEnoughCapacity();
    error Auctioneer_InvalidCallback();
    error Auctioneer_BadExpiry();
    error Auctioneer_InvalidParams();
    error Auctioneer_NotAuthorized();
    error Auctioneer_NewMarketsNotAllowed();
    error Auctioneer_OraclePriceZero();

    /* ========== EVENTS ========== */

    event MarketCreated(
        uint256 indexed id,
        address indexed payoutToken,
        address indexed quoteToken,
        uint48 vesting
    );
    event MarketClosed(uint256 indexed id);
    event Tuned(uint256 indexed id, uint256 oldControlVariable, uint256 newControlVariable);

    /* ========== STATE VARIABLES ========== */

    /// @notice Main information pertaining to bond market
    mapping(uint256 => BondMarket) public markets;

    /// @notice Information used to control how a bond market changes
    mapping(uint256 => BondTerms) public terms;

    /// @notice New address to designate as market owner. They must accept ownership to transfer permissions.
    mapping(uint256 => address) public newOwners;

    /// @notice Whether or not the market creator is authorized to use a callback address
    mapping(address => bool) public callbackAuthorized;

    /// @notice Whether or not the auctioneer allows new markets to be created
    /// @dev    Changing to false will sunset the auctioneer after all active markets end
    bool public allowNewMarkets;

    // Minimum time parameter values. Can be updated by admin.
    /// @notice Minimum deposit interval for a market
    uint48 public minDepositInterval;

    /// @notice Minimum duration for a market
    uint48 public minMarketDuration;

    // A 'vesting' param longer than 50 years is considered a timestamp for fixed expiry.
    uint48 internal constant MAX_FIXED_TERM = 52 weeks * 50;
    uint48 internal constant ONE_HUNDRED_PERCENT = 100e3; // one percent equals 1000.

    // BondAggregator contract with utility functions
    IBondAggregator internal immutable _aggregator;

    // BondTeller contract that handles interactions with users and issues tokens
    IBondTeller internal immutable _teller;

    constructor(
        IBondTeller teller_,
        IBondAggregator aggregator_,
        address guardian_,
        Authority authority_
    ) Auth(guardian_, authority_) {
        _aggregator = aggregator_;
        _teller = teller_;

        minDepositInterval = 1 hours;
        minMarketDuration = 1 days;

        allowNewMarkets = true;
    }

    /* ========== MARKET FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function createMarket(bytes calldata params_) external virtual returns (uint256);

    /// @notice core market creation logic, see IBondOSDA.MarketParams documentation
    function _createMarket(MarketParams memory params_) internal returns (uint256) {
        // Upfront permission and timing checks
        {
            // Check that the auctioneer is allowing new markets to be created
            if (!allowNewMarkets) revert Auctioneer_NewMarketsNotAllowed();
            // Restrict the use of a callback address unless allowed
            if (!callbackAuthorized[msg.sender] && params_.callbackAddr != address(0))
                revert Auctioneer_NotAuthorized();
            // Start time must be zero or in the future
            if (params_.start > 0 && params_.start < block.timestamp)
                revert Auctioneer_InvalidParams();
        }
        // Register new market on aggregator and get marketId
        uint256 marketId = _aggregator.registerMarket(params_.payoutToken, params_.quoteToken);

        // Set basic market data
        BondMarket storage market = markets[marketId];
        market.owner = msg.sender;
        market.quoteToken = params_.quoteToken;
        market.payoutToken = params_.payoutToken;
        market.callbackAddr = params_.callbackAddr;
        market.capacityInQuote = params_.capacityInQuote;
        market.capacity = params_.capacity;

        // Check that the base discount is in bounds (cannot be 100% or greater)
        BondTerms storage term = terms[marketId];
        if (
            params_.baseDiscount >= ONE_HUNDRED_PERCENT ||
            params_.baseDiscount > params_.maxDiscountFromCurrent
        ) revert Auctioneer_InvalidParams();
        term.baseDiscount = params_.baseDiscount;

        // Validate oracle and get price variables
        (uint256 price, uint256 oracleConversion, uint256 scale) = _validateOracle(
            marketId,
            params_.oracle,
            params_.quoteToken,
            params_.payoutToken,
            params_.baseDiscount
        );
        term.oracle = params_.oracle;
        term.oracleConversion = oracleConversion;
        term.scale = scale;

        // Check that the max discount from current price is in bounds (cannot be greater than 100%)
        if (params_.maxDiscountFromCurrent > ONE_HUNDRED_PERCENT) revert Auctioneer_InvalidParams();

        // Calculate the minimum price for the market
        term.minPrice = price.mulDivUp(
            uint256(ONE_HUNDRED_PERCENT - params_.maxDiscountFromCurrent),
            uint256(ONE_HUNDRED_PERCENT)
        );

        // Check time bounds
        if (
            params_.duration < minMarketDuration ||
            params_.depositInterval < minDepositInterval ||
            params_.depositInterval > params_.duration
        ) revert Auctioneer_InvalidParams();

        // Calculate the maximum payout amount for this market, determined by deposit interval
        uint256 capacity = params_.capacityInQuote
            ? params_.capacity.mulDiv(
                scale,
                price.mulDivUp(
                    uint256(ONE_HUNDRED_PERCENT - params_.baseDiscount),
                    uint256(ONE_HUNDRED_PERCENT)
                )
            )
            : params_.capacity;
        market.maxPayout = capacity.mulDiv(
            uint256(params_.depositInterval),
            uint256(params_.duration)
        );

        // Check target interval discount in bounds
        if (params_.targetIntervalDiscount > ONE_HUNDRED_PERCENT) revert Auctioneer_InvalidParams();

        // Calculate decay speed
        term.decaySpeed =
            (params_.duration * params_.targetIntervalDiscount) /
            params_.depositInterval;

        // Store bond time terms
        term.vesting = params_.vesting;
        uint48 start = params_.start == 0 ? uint48(block.timestamp) : params_.start;
        term.start = start;
        term.conclusion = start + params_.duration;

        // Emit market created event
        emit MarketCreated(
            marketId,
            address(params_.payoutToken),
            address(params_.quoteToken),
            params_.vesting
        );

        return marketId;
    }

    function _validateOracle(
        uint256 id_,
        IBondOracle oracle_,
        ERC20 quoteToken_,
        ERC20 payoutToken_,
        uint48 baseDiscount_
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Ensure token decimals are in bounds
        uint8 payoutTokenDecimals = payoutToken_.decimals();
        uint8 quoteTokenDecimals = quoteToken_.decimals();

        if (payoutTokenDecimals < 6 || payoutTokenDecimals > 18) revert Auctioneer_InvalidParams();
        if (quoteTokenDecimals < 6 || quoteTokenDecimals > 18) revert Auctioneer_InvalidParams();

        // Check that oracle is valid. It should:
        // 1. Be a contract
        if (address(oracle_) == address(0) || address(oracle_).code.length == 0)
            revert Auctioneer_InvalidParams();

        // 2. Allow registering markets
        oracle_.registerMarket(id_, quoteToken_, payoutToken_);

        // 3. Return a valid price for the quote token : payout token pair
        uint256 currentPrice = oracle_.currentPrice(id_);
        if (currentPrice == 0) revert Auctioneer_OraclePriceZero();

        // 4. Return a valid decimal value for the quote token : payout token pair price
        uint8 oracleDecimals = oracle_.decimals(id_);
        if (oracleDecimals < 6 || oracleDecimals > 18) revert Auctioneer_InvalidParams();

        // Calculate scaling values for market:
        // 1. We need a value to convert between the oracle decimals to the bond market decimals
        // 2. We need the bond scaling value to convert between quote and payout tokens using the market price

        // Get the price decimals for the current oracle price
        // Oracle price is in quote tokens per payout token
        // E.g. if quote token is $10 and payout token is $2000,
        // then the oracle price is 200 quote tokens per payout token.
        // If the oracle has 18 decimals, then it would return 200 * 10^18.
        // In this case, the price decimals would be 2 since 200 = 2 * 10^2.
        // We apply the base discount to the oracle price before calculating
        // since this will be the initial equilibrium price of the market.
        int8 priceDecimals = _getPriceDecimals(
            currentPrice.mulDivUp(
                uint256(ONE_HUNDRED_PERCENT - baseDiscount_),
                uint256(ONE_HUNDRED_PERCENT)
            ),
            oracleDecimals
        );
        // Check price decimals in reasonable range
        // These bounds are quite large and it is unlikely any combination of tokens
        // will have a price difference larger than 10^24 in either direction.
        // Check that oracle decimals are large enough to avoid precision loss from negative price decimals
        if (int8(oracleDecimals) <= -priceDecimals || priceDecimals > 24)
            revert Auctioneer_InvalidParams();

        // Calculate the oracle price conversion factor
        // oraclePriceFactor = int8(oracleDecimals) + priceDecimals;
        // bondPriceFactor = 36 - priceDecimals / 2 + priceDecimals;
        // oracleConversion = 10^(bondPriceFactor - oraclePriceFactor);
        uint256 oracleConversion = 10**uint8(36 - priceDecimals / 2 - int8(oracleDecimals));

        // Unit to scale calculation for this market by to ensure reasonable values
        // for price, debt, and control variable without under/overflows.
        //
        // scaleAdjustment should be equal to (payoutDecimals - quoteDecimals) - ((payoutPriceDecimals - quotePriceDecimals) / 2)
        // scale = 10^(36 + scaleAdjustment);
        uint256 scale = 10 **
            uint8(36 + int8(payoutTokenDecimals) - int8(quoteTokenDecimals) - priceDecimals / 2);

        return (currentPrice * oracleConversion, oracleConversion, scale);
    }

    /// @inheritdoc IBondAuctioneer
    function pushOwnership(uint256 id_, address newOwner_) external override {
        if (msg.sender != markets[id_].owner) revert Auctioneer_OnlyMarketOwner();
        newOwners[id_] = newOwner_;
    }

    /// @inheritdoc IBondAuctioneer
    function pullOwnership(uint256 id_) external override {
        if (msg.sender != newOwners[id_]) revert Auctioneer_NotAuthorized();
        markets[id_].owner = newOwners[id_];
    }

    /// @inheritdoc IBondOSDA
    function setMinMarketDuration(uint48 duration_) external override requiresAuth {
        // Restricted to authorized addresses

        // Require duration to be greater than minimum deposit interval and at least 1 day
        if (duration_ < minDepositInterval || duration_ < 1 days) revert Auctioneer_InvalidParams();

        minMarketDuration = duration_;
    }

    /// @inheritdoc IBondOSDA
    function setMinDepositInterval(uint48 depositInterval_) external override requiresAuth {
        // Restricted to authorized addresses

        // Require min deposit interval to be less than minimum market duration and at least 1 hour
        if (depositInterval_ > minMarketDuration || depositInterval_ < 1 hours)
            revert Auctioneer_InvalidParams();

        minDepositInterval = depositInterval_;
    }

    // Unused, but required by interface
    function setIntervals(uint256 id_, uint32[3] calldata intervals_) external override {}

    // Unused, but required by interface
    function setDefaults(uint32[6] memory defaults_) external override {}

    /// @inheritdoc IBondAuctioneer
    function setAllowNewMarkets(bool status_) external override requiresAuth {
        /// Restricted to authorized addresses, initially restricted to guardian
        allowNewMarkets = status_;
    }

    /// @inheritdoc IBondAuctioneer
    function setCallbackAuthStatus(address creator_, bool status_) external override requiresAuth {
        /// Restricted to authorized addresses, initially restricted to guardian
        callbackAuthorized[creator_] = status_;
    }

    /// @inheritdoc IBondAuctioneer
    function closeMarket(uint256 id_) external override {
        if (msg.sender != markets[id_].owner) revert Auctioneer_OnlyMarketOwner();
        _close(id_);
    }

    /* ========== TELLER FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function purchaseBond(
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external override returns (uint256 payout) {
        if (msg.sender != address(_teller)) revert Auctioneer_NotAuthorized();

        BondMarket storage market = markets[id_];
        BondTerms memory term = terms[id_];

        // If market uses a callback, check that owner is still callback authorized
        if (market.callbackAddr != address(0) && !callbackAuthorized[market.owner])
            revert Auctioneer_NotAuthorized();

        // Check if market is live, if not revert
        if (!isLive(id_)) revert Auctioneer_MarketNotActive();

        // Retrieve price and calculate payout
        uint256 price = marketPrice(id_);

        // Payout for the deposit = amount / price
        //
        // where:
        // payout = payout tokens out
        // amount = quote tokens in
        // price = quote tokens : payout token (i.e. 200 QUOTE : BASE), adjusted for scaling
        payout = amount_.mulDiv(term.scale, price);

        // Payout must be greater than user inputted minimum
        if (payout < minAmountOut_) revert Auctioneer_AmountLessThanMinimum();

        // Markets have a max payout amount, capping size because deposits
        // do not experience slippage. max payout is recalculated upon tuning
        if (payout > market.maxPayout) revert Auctioneer_MaxPayoutExceeded();

        // Update Capacity

        // Capacity is either the number of payout tokens that the market can sell
        // (if capacity in quote is false),
        //
        // or the number of quote tokens that the market can buy
        // (if capacity in quote is true)

        // If amount/payout is greater than capacity remaining, revert
        if (market.capacityInQuote ? amount_ > market.capacity : payout > market.capacity)
            revert Auctioneer_NotEnoughCapacity();
        unchecked {
            // Capacity is decreased by the deposited or paid amount
            market.capacity -= market.capacityInQuote ? amount_ : payout;

            // Markets keep track of how many quote tokens have been
            // purchased, and how many payout tokens have been sold
            market.purchased += amount_;
            market.sold += payout;
        }
    }

    /* ========== INTERNAL DEPO FUNCTIONS ========== */

    /// @notice          Close a market
    /// @dev             Closing a market sets capacity to 0 and immediately stops bonding
    function _close(uint256 id_) internal {
        terms[id_].conclusion = uint48(block.timestamp);
        markets[id_].capacity = 0;

        emit MarketClosed(id_);
    }

    /* ========== INTERNAL VIEW FUNCTIONS ========== */

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @dev                See marketPrice() in IBondOSDA for explanation of price computation
    /// @param id_          Market ID
    /// @return             Price for market as a ratio of quote tokens to payout tokens with 36 decimals
    function _currentMarketPrice(uint256 id_) internal view returns (uint256) {
        BondMarket memory market = markets[id_];
        BondTerms memory term = terms[id_];

        // Get price from oracle, apply oracle conversion factor, and apply target discount
        uint256 price = (term.oracle.currentPrice(id_) * term.oracleConversion).mulDivUp(
            (ONE_HUNDRED_PERCENT - term.baseDiscount),
            ONE_HUNDRED_PERCENT
        );

        // Revert if price is 0
        if (price == 0) revert Auctioneer_OraclePriceZero();

        // Calculate initial capacity based on remaining capacity and amount sold/purchased up to this point
        uint256 initialCapacity = market.capacity +
            (market.capacityInQuote ? market.purchased : market.sold);

        // Compute seconds remaining until market will conclude
        uint256 conclusion = uint256(term.conclusion);
        uint256 timeRemaining = conclusion - block.timestamp;

        // Calculate expectedCapacity as the capacity expected to be bought or sold up to this point
        // Higher than current capacity means the market is undersold, lower than current capacity means the market is oversold
        uint256 expectedCapacity = initialCapacity.mulDiv(
            timeRemaining,
            conclusion - uint256(term.start)
        );

        // Price is increased or decreased based on how far the market is ahead or behind
        // Intuition:
        // If the time neutral capacity is higher than the initial capacity, then the market is undersold and price should be discounted
        // If the time neutral capacity is lower than the initial capacity, then the market is oversold and price should be increased
        //
        // This implementation uses a linear price decay
        // P(t) = P(0) * (1 + k * (X(t) - C(t) / C(0)))
        // P(t): price at time t
        // P(0): initial/target price of the market provided by oracle + base discount (see IOSDA.MarketParams)
        // k: decay speed of the market
        // k = L / I * d, where L is the duration/length of the market, I is the deposit interval, and d is the target interval discount.
        // X(t): expected capacity of the market at time t.
        // X(t) = C(0) * t / L.
        // C(t): actual capacity of the market at time t.
        // C(0): initial capacity of the market provided by the user (see IOSDA.MarketParams).
        uint256 adjustment;
        if (expectedCapacity > market.capacity) {
            adjustment =
                ONE_HUNDRED_PERCENT +
                (term.decaySpeed * (expectedCapacity - market.capacity)) /
                initialCapacity;
        } else {
            // If actual capacity is greater than expected capacity, we need to check for underflows
            // The adjustment has a minimum value of 0 since that will reduce the price to 0 as well.
            uint256 factor = (term.decaySpeed * (market.capacity - expectedCapacity)) /
                initialCapacity;
            adjustment = ONE_HUNDRED_PERCENT > factor ? ONE_HUNDRED_PERCENT - factor : 0;
        }

        return price.mulDivUp(adjustment, ONE_HUNDRED_PERCENT);
    }

    /* ========== INTERNAL VIEW FUNCTIONS ========== */

    /// @notice         Helper function to calculate number of price decimals based on the value returned from the price feed.
    /// @param price_   The price to calculate the number of decimals for
    /// @return         The number of decimals
    function _getPriceDecimals(uint256 price_, uint8 feedDecimals_) internal pure returns (int8) {
        int8 decimals;
        while (price_ >= 10) {
            price_ = price_ / 10;
            decimals++;
        }

        // Subtract the stated decimals from the calculated decimals to get the relative price decimals.
        // Required to do it this way vs. normalizing at the beginning since price decimals can be negative.
        return decimals - int8(feedDecimals_);
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /// @inheritdoc IBondAuctioneer
    function getMarketInfoForPurchase(uint256 id_)
        external
        view
        override
        returns (
            address owner,
            address callbackAddr,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 vesting,
            uint256 maxPayout_
        )
    {
        BondMarket memory market = markets[id_];
        return (
            market.owner,
            market.callbackAddr,
            market.payoutToken,
            market.quoteToken,
            terms[id_].vesting,
            maxPayout(id_)
        );
    }

    /// @inheritdoc IBondOSDA
    function marketPrice(uint256 id_) public view override returns (uint256) {
        uint256 price = _currentMarketPrice(id_);

        return (price > terms[id_].minPrice) ? price : terms[id_].minPrice;
    }

    /// @inheritdoc IBondAuctioneer
    function marketScale(uint256 id_) external view override returns (uint256) {
        return terms[id_].scale;
    }

    /// @inheritdoc IBondAuctioneer
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) public view override returns (uint256) {
        /// Calculate the payout for the given amount of tokens
        uint256 fee = amount_.mulDiv(_teller.getFee(referrer_), 1e5);
        uint256 payout = (amount_ - fee).mulDiv(terms[id_].scale, marketPrice(id_));

        /// Check that the payout is less than or equal to the maximum payout,
        /// Revert if not, otherwise return the payout
        if (payout > maxPayout(id_)) {
            revert Auctioneer_MaxPayoutExceeded();
        } else {
            return payout;
        }
    }

    /// @inheritdoc IBondOSDA
    function maxPayout(uint256 id_) public view override returns (uint256) {
        // Get current price
        uint256 price = marketPrice(id_);

        BondMarket memory market = markets[id_];
        BondTerms memory term = terms[id_];

        // Convert capacity to payout token units for comparison with max payout
        uint256 capacity = market.capacityInQuote
            ? market.capacity.mulDiv(term.scale, price)
            : market.capacity;

        // Cap max payout at the remaining capacity
        return market.maxPayout > capacity ? capacity : market.maxPayout;
    }

    /// @inheritdoc IBondAuctioneer
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256) {
        // Calculate maximum amount of quote tokens that correspond to max bond size
        // Maximum of the maxPayout and the remaining capacity converted to quote tokens
        BondMarket memory market = markets[id_];
        BondTerms memory term = terms[id_];
        uint256 price = marketPrice(id_);
        uint256 quoteCapacity = market.capacityInQuote
            ? market.capacity
            : market.capacity.mulDiv(price, term.scale);
        uint256 maxQuote = market.maxPayout.mulDiv(price, term.scale);
        uint256 amountAccepted = quoteCapacity < maxQuote ? quoteCapacity : maxQuote;

        // Take into account teller fees and return
        // Estimate fee based on amountAccepted. Fee taken will be slightly larger than
        // this given it will be taken off the larger amount, but this avoids rounding
        // errors with trying to calculate the exact amount.
        // Therefore, the maxAmountAccepted is slightly conservative.
        uint256 estimatedFee = amountAccepted.mulDiv(
            _teller.getFee(referrer_),
            ONE_HUNDRED_PERCENT
        );

        return amountAccepted + estimatedFee;
    }

    /// @inheritdoc IBondAuctioneer
    function isInstantSwap(uint256 id_) public view returns (bool) {
        uint256 vesting = terms[id_].vesting;
        return (vesting <= MAX_FIXED_TERM) ? vesting == 0 : vesting <= block.timestamp;
    }

    /// @inheritdoc IBondAuctioneer
    function isLive(uint256 id_) public view override returns (bool) {
        return (markets[id_].capacity != 0 &&
            terms[id_].conclusion > uint48(block.timestamp) &&
            terms[id_].start <= uint48(block.timestamp));
    }

    /// @inheritdoc IBondAuctioneer
    function ownerOf(uint256 id_) external view override returns (address) {
        return markets[id_].owner;
    }

    /// @inheritdoc IBondAuctioneer
    function getTeller() external view override returns (IBondTeller) {
        return _teller;
    }

    /// @inheritdoc IBondAuctioneer
    function getAggregator() external view override returns (IBondAggregator) {
        return _aggregator;
    }

    /// @inheritdoc IBondAuctioneer
    function currentCapacity(uint256 id_) external view override returns (uint256) {
        return markets[id_].capacity;
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondAuctioneer} from "../interfaces/IBondAuctioneer.sol";
import {IBondOracle} from "../interfaces/IBondOracle.sol";

interface IBondOSDA is IBondAuctioneer {
    /// @notice Basic token and capacity information for a bond market
    struct BondMarket {
        address owner; // market owner. sends payout tokens, receives quote tokens (defaults to creator)
        ERC20 payoutToken; // token to pay depositors with
        ERC20 quoteToken; // token to accept as payment
        address callbackAddr; // address to call for any operations on bond purchase. Must implement IBondCallback.
        bool capacityInQuote; // capacity limit is in payment token (true) or in payout (false, default)
        uint256 capacity; // capacity remaining
        uint256 maxPayout; // max payout tokens out in one order
        uint256 sold; // payout tokens out
        uint256 purchased; // quote tokens in
    }

    /// @notice Information pertaining to pricing and time parameters for a bond market
    struct BondTerms {
        IBondOracle oracle; // address to call for reference price. Must implement IBondOracle.
        uint48 start; // timestamp when market starts
        uint48 conclusion; // timestamp when market no longer offered
        uint48 vesting; // length of time from deposit to expiry if fixed-term, vesting timestamp if fixed-expiry
        uint48 baseDiscount; // base discount from oracle price, with 3 decimals of precision. E.g. 10_000 = 10%
        uint48 decaySpeed; // market price decay speed (discount achieved over a target deposit interval)
        uint256 minPrice; // minimum price (hard floor for the market)
        uint256 scale; // scaling factor for the market
        uint256 oracleConversion; // conversion factor for oracle -> market price
    }

    /// @notice             Parameters to create a new bond market
    /// @param params_      Encoded bytes array, with the following elements
    /// @dev                    0. Payout Token (token paid out)
    /// @dev                    1. Quote Token (token to be received)
    /// @dev                    2. Callback contract address, should conform to IBondCallback. If 0x00, tokens will be transferred from market.owner
    /// @dev                    3. Oracle contract address, should conform to IBondOracle.
    /// @dev                    4. Base discount with 3 decimals of precision, e.g. 10_000 = 10%. Sets a base discount against the oracle price before time-related decay is applied.
    /// @dev                    5. Maximum discount from current oracle price with 3 decimals of precision, sets absolute minimum price for market
    /// @dev                    6. Target interval discount with 3 decimals of precision. The discount to be achieved over a deposit interval (in addition to base discount).
    /// @dev                    7. Is Capacity in Quote Token?
    /// @dev                    8. Capacity (amount in the decimals of the token chosen to provided capacity in).
    /// @dev                    9. Deposit interval (seconds). Desired frequency of bonds. Used to calculate max payout of market (maxPayout = duration / depositInterval * capacity)
    /// @dev                    10. Is fixed term ? Vesting length (seconds) : Vesting expiry (timestamp).
    /// @dev                        A 'vesting' param longer than 50 years is considered a timestamp for fixed expiry.
    /// @dev                    11. Start Time of the Market (timestamp) - Allows starting a market in the future.
    /// @dev                        If a start time is provided, the txn must be sent prior to the start time (functions as a deadline).
    /// @dev                        If start time is not provided (i.e. 0), the market will start immediately.
    /// @dev                    12. Market Duration (seconds) - Duration of the market in seconds.
    struct MarketParams {
        ERC20 payoutToken;
        ERC20 quoteToken;
        address callbackAddr;
        IBondOracle oracle;
        uint48 baseDiscount;
        uint48 maxDiscountFromCurrent;
        uint48 targetIntervalDiscount;
        bool capacityInQuote;
        uint256 capacity;
        uint48 depositInterval;
        uint48 vesting;
        uint48 start;
        uint48 duration;
    }

    /// @notice Set the minimum market duration
    /// @notice Access controlled
    /// @param duration_ Minimum market duration in seconds
    function setMinMarketDuration(uint48 duration_) external;

    /// @notice Set the minimum deposit interval
    /// @notice Access controlled
    /// @param depositInterval_ Minimum deposit interval in seconds
    function setMinDepositInterval(uint48 depositInterval_) external;

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @param id_          ID of market
    /// @return             Price for market in configured decimals (see MarketParams)
    /// @dev price is derived from the equation
    //
    // p(t) = max(min_p, o_p * (1 - d) * (1 + k * r(t)))
    //
    // where
    // p: price
    // min_p: minimum price
    // o_p: oracle price
    // d: base discount
    //
    // k: decay speed
    // k = l / i_d * t_d
    // where
    // l: market length
    // i_d: deposit interval
    // t_d: target interval discount
    //
    // r(t): percent difference of expected capacity and actual capacity at time t
    // r(t) = (ec(t) - c(t)) / ic
    // where
    // ec(t): expected capacity at time t (assumes capacity is expended linearly over the duration)
    // ec(t) = ic * (l - t) / l
    // c(t): capacity remaining at time t
    // ic = initial capacity
    //
    // if price is below minimum price, minimum price is returned
    function marketPrice(uint256 id_) external view override returns (uint256);

    /// @notice             Calculate max payout of the market in payout tokens
    /// @dev                Returns a dynamically calculated payout or the maximum set by the creator, whichever is less.
    /// @param id_          ID of market
    /// @return             Current max payout for the market in payout tokens
    function maxPayout(uint256 id_) external view returns (uint256);
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

interface IBondCallback {
    /// @notice                 Send payout tokens to Teller while allowing market owners to perform custom logic on received or paid out tokens
    /// @notice                 Market ID on Teller must be whitelisted
    /// @param id_              ID of the market
    /// @param inputAmount_     Amount of quote tokens bonded to the market
    /// @param outputAmount_    Amount of payout tokens to be paid out to the market
    /// @dev Must transfer the output amount of payout tokens back to the Teller
    /// @dev Should check that the quote tokens have been transferred to the contract in the _callback function
    function callback(
        uint256 id_,
        uint256 inputAmount_,
        uint256 outputAmount_
    ) external;

    /// @notice         Returns the number of quote tokens received and payout tokens paid out for a market
    /// @param id_      ID of the market
    /// @return in_     Amount of quote tokens bonded to the market
    /// @return out_    Amount of payout tokens paid out to the market
    function amountsForMarket(uint256 id_) external view returns (uint256 in_, uint256 out_);

    /// @notice         Whitelist a teller and market ID combination
    /// @notice         Must be callback owner
    /// @param teller_  Address of the Teller contract which serves the market
    /// @param id_      ID of the market
    function whitelist(address teller_, uint256 id_) external;

    /// @notice Remove a market ID on a teller from the whitelist
    /// @dev    Shutdown function in case there's an issue with the teller
    /// @param  teller_ Address of the Teller contract which serves the market
    /// @param  id_     ID of the market to remove from whitelist
    function blacklist(address teller_, uint256 id_) external;

    /// @notice         Withdraw tokens from the callback and update balances
    /// @notice         Only callback owner
    /// @param to_      Address of the recipient
    /// @param token_   Address of the token to withdraw
    /// @param amount_  Amount of tokens to withdraw
    function withdraw(
        address to_,
        ERC20 token_,
        uint256 amount_
    ) external;

    /// @notice         Deposit tokens to the callback and update balances
    /// @notice         Only callback owner
    /// @param token_   Address of the token to deposit
    /// @param amount_  Amount of tokens to deposit
    function deposit(ERC20 token_, uint256 amount_) external;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Safe ERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// @author Taken from Solmate.
library TransferHelper {
    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, amount)
        );

        require(
            success &&
                (data.length == 0 || abi.decode(data, (bool))) &&
                address(token).code.length > 0,
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, amount)
        );

        require(
            success &&
                (data.length == 0 || abi.decode(data, (bool))) &&
                address(token).code.length > 0,
            "TRANSFER_FAILED"
        );
    }

    // function safeApprove(
    //     ERC20 token,
    //     address to,
    //     uint256 amount
    // ) internal {
    //     (bool success, bytes memory data) = address(token).call(
    //         abi.encodeWithSelector(ERC20.approve.selector, to, amount)
    //     );

    //     require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    // }

    // function safeTransferETH(address to, uint256 amount) internal {
    //     (bool success, ) = to.call{value: amount}(new bytes(0));

    //     require(success, "ETH_TRANSFER_FAILED");
    // }
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