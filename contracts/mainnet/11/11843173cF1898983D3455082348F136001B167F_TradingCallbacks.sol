// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/ITradingStorage.sol";
import "../interfaces/IPairInfos.sol";
import "../libraries/ChainUtils.sol";
import "../interfaces/IBorrowingFees.sol";
import "../interfaces/TokenInterface.sol";
import "../interfaces/IFoxifyAffiliation.sol";
import "../interfaces/IFoxifyReferral.sol";


contract TradingCallbacks {

    uint256 constant PRECISION = 1e10;
    uint256 constant MAX_SL_P = 75; // -75% PNL
    uint256 constant MAX_GAIN_P = 900; // 900% PnL (10x)
    uint256 constant MAX_EXECUTE_TIMEOUT = 5; // 5 blocks

    enum TradeType {
        MARKET,
        LIMIT
    }

    enum CancelReason {
        NONE,
        PAUSED,
        MARKET_CLOSED,
        SLIPPAGE,
        TP_REACHED,
        SL_REACHED,
        EXPOSURE_LIMITS,
        PRICE_IMPACT,
        MAX_LEVERAGE,
        NO_TRADE,
        WRONG_TRADE,
        NOT_HIT
    }

    struct AggregatorAnswer {
        uint256 orderId;
        uint256 price;
        uint256 spreadP;
    }

    struct Values {
        uint256 posStable;
        uint256 levPosStable;
        int256 profitP;
        uint256 price;
        uint256 liqPrice;
        uint256 stableSentToTrader;
        uint256 reward1;
        uint256 reward2;
        uint256 reward3;
    }

    struct SimplifiedTradeId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        TradeType tradeType;
    }

    struct LastUpdated {
        uint32 tp;
        uint32 sl;
        uint32 limit;
        uint32 created;
    }

    struct AffiliationUserData {
        uint256 activeId;
        uint256 team;
        IFoxifyAffiliation.NFTData nftData;
    }

    ITradingStorage public storageT;
    IOrderExecutionTokenManagement public orderTokenManagement;
    IPairInfos public pairInfos;
    IBorrowingFees public borrowingFees;
    IFoxifyReferral public referral;
    IFoxifyAffiliation public affiliation;

    bool public isPaused;
    bool public isDone;
    uint256 public canExecuteTimeout; // How long an update to TP/SL/Limit has to wait before it is executable

    mapping(address => mapping(uint256 => mapping(uint256 => mapping(TradeType => LastUpdated))))
        public tradeLastUpdated; // Block numbers for last updated

    mapping(uint256 => uint256) public pairMaxLeverage;

    event OpenMarketExecutedWithAffiliationReferral(
        uint256 indexed orderId,
        ITradingStorage.Trade t,
        bool open,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeStable,
        int256 percentProfit,
        uint256 stableSentToTrader,
        AffiliationUserData affiliationInfo,
        uint256 referralTeamID
    );

    event OpenMarketExecuted(
        uint256 indexed orderId,
        ITradingStorage.Trade t,
        bool open,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeStable,
        int256 percentProfit,
        uint256 stableSentToTrader
    );

    event CloseMarketExecuted(
        uint256 indexed orderId,
        ITradingStorage.Trade t,
        bool open,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeStable,
        int256 percentProfit,
        uint256 stableSentToTrader
    );

    event OpenLimitExecutedWithAffiliationReferral(
        uint256 indexed orderId,
        uint256 limitIndex,
        ITradingStorage.Trade t,
        ITradingStorage.LimitOrder orderType,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeStable,
        int256 percentProfit,
        uint256 stableSentToTrader,
        AffiliationUserData affiliationInfo,
        uint256 referralTeamID
    );

    event OpenLimitExecuted(
        uint256 indexed orderId,
        uint256 limitIndex,
        ITradingStorage.Trade t,
        ITradingStorage.LimitOrder orderType,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeStable,
        int256 percentProfit,
        uint256 stableSentToTrader
    );

    event CloseLimitExecuted(
        uint256 indexed orderId,
        uint256 limitIndex,
        ITradingStorage.Trade t,
        ITradingStorage.LimitOrder orderType,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeStable,
        int256 percentProfit,
        uint256 stableSentToTrader
    );

    event MarketOpenCanceled(
        AggregatorAnswer a,
        ITradingStorage.PendingMarketOrder o,
        CancelReason cancelReason
    );
    event MarketCloseCanceled(
        AggregatorAnswer a,
        ITradingStorage.PendingMarketOrder o,
        CancelReason cancelReason
    );
    event BotOrderCanceled(
        uint256 indexed orderId,
        ITradingStorage.LimitOrder orderType,
        CancelReason cancelReason
    );
    event SlUpdated(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 newSl
    );
    event SlCanceled(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        CancelReason cancelReason
    );

    event CanExecuteTimeoutUpdated(uint newValue);

    event Pause(bool paused);
    event Done(bool done);

    event DevGovRefFeeCharged(address indexed trader, uint256 valueStable);

    event OrderExecutionFeeCharged(address indexed trader, uint256 valueStable);
    event StableWorkPoolFeeCharged(address indexed trader, uint256 valueStable);

    event BorrowingFeeCharged(
        address indexed trader,
        uint256 tradeValueStable,
        uint256 feeValueStable
    );
    event PairMaxLeverageUpdated(
        uint256 indexed pairIndex,
        uint256 maxLeverage
    );

    error TradingCallbacksWrongParams();
    error TradingCallbacksForbidden();
    error TradingCallbacksInvalidAddress(address account);

    modifier onlyGov() {
        isGov();
        _;
    }

    modifier onlyPriceAggregator() {
        isPriceAggregator();
        _;
    }

    modifier notDone() {
        isNotDone();
        _;
    }

    modifier onlyTrading() {
        isTrading();
        _;
    }

    modifier onlyManager() {
        isManager();
        _;
    }

    constructor(
        ITradingStorage _storageT,
        IOrderExecutionTokenManagement _orderTokenManagement,
        IPairInfos _pairInfos,
        IBorrowingFees _borrowingFees,
        address _workPoolToApprove,
        uint256 _canExecuteTimeout
    ) {
        if (
            address(_storageT) == address(0) ||
            address(_orderTokenManagement) == address(0) ||
            address(_pairInfos) == address(0) ||
            address(_borrowingFees) == address(0) ||
            _workPoolToApprove == address(0) ||
            _canExecuteTimeout > MAX_EXECUTE_TIMEOUT
        ) {
            revert TradingCallbacksWrongParams();
        }

        storageT = _storageT;
        orderTokenManagement = _orderTokenManagement;
        pairInfos = _pairInfos;
        borrowingFees = _borrowingFees;

        canExecuteTimeout = _canExecuteTimeout;

        TokenInterface t = storageT.stable();
        t.approve(_workPoolToApprove, type(uint256).max);
    }

    function setPairMaxLeverage(
        uint256 pairIndex,
        uint256 maxLeverage
    ) external onlyManager {
        _setPairMaxLeverage(pairIndex, maxLeverage);
    }

    function setPairMaxLeverageArray(
        uint256[] calldata indices,
        uint256[] calldata values
    ) external onlyManager {
        uint256 len = indices.length;

        if (len != values.length) {
            revert TradingCallbacksWrongParams();
        }

        for (uint256 i; i < len; ) {
            _setPairMaxLeverage(indices[i], values[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setCanExecuteTimeout(uint256 _canExecuteTimeout) external onlyGov {
        if (_canExecuteTimeout > MAX_EXECUTE_TIMEOUT) {
            revert TradingCallbacksWrongParams();
        }
        canExecuteTimeout = _canExecuteTimeout;
        emit CanExecuteTimeoutUpdated(_canExecuteTimeout);
    }

    function setReferral(address _referral) external onlyGov returns (bool) {
      if (_referral == address(0)) revert TradingCallbacksInvalidAddress(address(0));
      referral = IFoxifyReferral(_referral);
      return true;
    }

    function setAffiliation(address _affiliation) external onlyGov returns (bool) {
      if (_affiliation == address(0)) revert TradingCallbacksInvalidAddress(address(0));
      affiliation = IFoxifyAffiliation(_affiliation);
      return true;
    }

    function pause() external onlyGov {
        isPaused = !isPaused;

        emit Pause(isPaused);
    }

    function done() external onlyGov {
        isDone = !isDone;

        emit Done(isDone);
    }

    // Callbacks
    function openTradeMarketCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator notDone {
        ITradingStorage.PendingMarketOrder memory o = getPendingMarketOrder(
            a.orderId
        );

        if (o.block == 0) {
            return;
        }

        ITradingStorage.Trade memory t = o.trade;

        (uint256 priceImpactP, uint256 priceAfterImpact) = pairInfos
            .getTradePriceImpact(
                marketExecutionPrice(a.price, a.spreadP, t.buy),
                t.pairIndex,
                t.buy,
                t.positionSizeStable * t.leverage
            );

        t.openPrice = priceAfterImpact;

        uint256 maxSlippage = (o.wantedPrice * o.slippageP) / 100 / PRECISION;

        CancelReason cancelReason = isPaused
            ? CancelReason.PAUSED
            : (
                a.price == 0
                    ? CancelReason.MARKET_CLOSED
                    : (
                        t.buy
                            ? t.openPrice > o.wantedPrice + maxSlippage
                            : t.openPrice < o.wantedPrice - maxSlippage
                    )
                    ? CancelReason.SLIPPAGE
                    : (t.tp > 0 &&
                        (t.buy ? t.openPrice >= t.tp : t.openPrice <= t.tp))
                    ? CancelReason.TP_REACHED
                    : (t.sl > 0 &&
                        (t.buy ? t.openPrice <= t.sl : t.openPrice >= t.sl))
                    ? CancelReason.SL_REACHED
                    : !withinExposureLimits(
                        t.pairIndex,
                        t.buy,
                        t.positionSizeStable,
                        t.leverage
                    )
                    ? CancelReason.EXPOSURE_LIMITS
                    : priceImpactP * t.leverage >
                        pairInfos.maxNegativePnlOnOpenP()
                    ? CancelReason.PRICE_IMPACT
                    : !withinMaxLeverage(t.pairIndex, t.leverage)
                    ? CancelReason.MAX_LEVERAGE
                    : CancelReason.NONE
            );

        if (cancelReason == CancelReason.NONE) {
            ITradingStorage.Trade memory finalTrade = registerTrade(t);

            if (address(affiliation) != address(0) && address(referral) != address(0)) {

                uint256 _activeId = affiliation.usersActiveID(finalTrade.trader);
                AffiliationUserData memory _affiliationData = AffiliationUserData({
                    activeId: _activeId,
                    team: affiliation.usersTeam(finalTrade.trader),
                    nftData: affiliation.data(_activeId)
                });
                uint256 _referralTeamID = referral.userTeamID(finalTrade.trader);

                emit OpenMarketExecutedWithAffiliationReferral(
                    a.orderId,
                    finalTrade,
                    true,
                    finalTrade.openPrice,
                    priceImpactP,
                    finalTrade.positionSizeStable,
                    0,
                    0,
                    _affiliationData,
                    _referralTeamID
                );

            } else {

                emit OpenMarketExecuted(
                    a.orderId,
                    finalTrade,
                    true,
                    finalTrade.openPrice,
                    priceImpactP,
                    finalTrade.positionSizeStable,
                    0,
                    0
                );
            }

        } else {
            uint256 devGovRefFeesStable = storageT.handleDevGovRefFees(
                t.pairIndex,
                t.positionSizeStable * t.leverage,
                true,
                true
            );
            transferFromStorageToAddress(
                t.trader,
                t.positionSizeStable - devGovRefFeesStable
            );

            emit DevGovRefFeeCharged(t.trader, devGovRefFeesStable);
            emit MarketOpenCanceled(
                a,
                o,
                cancelReason
            );
        }

        storageT.unregisterPendingMarketOrder(a.orderId, true);
    }

    function closeTradeMarketCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator notDone {
        ITradingStorage.PendingMarketOrder memory o = getPendingMarketOrder(
            a.orderId
        );

        if (o.block == 0) {
            return;
        }

        ITradingStorage.Trade memory t = getOpenTrade(
            o.trade.trader,
            o.trade.pairIndex,
            o.trade.index
        );

        CancelReason cancelReason = t.leverage == 0
            ? CancelReason.NO_TRADE
            : (a.price == 0 ? CancelReason.MARKET_CLOSED : CancelReason.NONE);

        if (cancelReason != CancelReason.NO_TRADE) {
            ITradingStorage.TradeInfo memory i = getOpenTradeInfo(
                t.trader,
                t.pairIndex,
                t.index
            );
            IAggregator01 aggregator = storageT.priceAggregator();

            Values memory v;
            v.levPosStable = t.positionSizeStable * t.leverage;

            if (cancelReason == CancelReason.NONE) {
                v.profitP = currentPercentProfit(
                    t.openPrice,
                    a.price,
                    t.buy,
                    t.leverage
                );
                v.posStable = v.levPosStable / t.leverage;

                v.stableSentToTrader = unregisterTrade(
                    t,
                    v.profitP,
                    v.posStable,
                    i.openInterestStable,
                    (v.levPosStable *
                        aggregator.pairsStorage().pairCloseFeeP(t.pairIndex)) /
                        100 /
                        PRECISION,
                    (v.levPosStable *
                        aggregator.pairsStorage().pairExecuteLimitOrderFeeP(
                            t.pairIndex
                        )) /
                        100 /
                        PRECISION
                );

                emit CloseMarketExecuted(
                    a.orderId,
                    t,
                    false,
                    a.price,
                    0,
                    v.posStable,
                    v.profitP,
                    v.stableSentToTrader
                );
            } else {
                v.reward1 = storageT.handleDevGovRefFees(
                    t.pairIndex,
                    v.levPosStable,
                    true,
                    true
                );
                t.positionSizeStable -= v.reward1;
                storageT.updateTrade(t);

                emit DevGovRefFeeCharged(t.trader, v.reward1);
            }
        }

        if (cancelReason != CancelReason.NONE) {
            emit MarketCloseCanceled(
                a,
                o,
                cancelReason
            );
        }

        storageT.unregisterPendingMarketOrder(a.orderId, false);
    }

    function executeBotOpenOrderCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator notDone {
        ITradingStorage.PendingBotOrder memory n = storageT
            .reqID_pendingBotOrder(a.orderId);

        CancelReason cancelReason = isPaused
            ? CancelReason.PAUSED
            : (
                a.price == 0
                    ? CancelReason.MARKET_CLOSED
                    : !storageT.hasOpenLimitOrder(
                        n.trader,
                        n.pairIndex,
                        n.index
                    )
                    ? CancelReason.NO_TRADE
                    : CancelReason.NONE
            );

        if (cancelReason == CancelReason.NONE) {
            ITradingStorage.OpenLimitOrder memory o = storageT
                .getOpenLimitOrder(n.trader, n.pairIndex, n.index);

            IOrderExecutionTokenManagement.OpenLimitOrderType t = orderTokenManagement
                    .openLimitOrderTypes(n.trader, n.pairIndex, n.index);

            (uint256 priceImpactP, uint256 priceAfterImpact) = pairInfos
                .getTradePriceImpact(
                    marketExecutionPrice(a.price, a.spreadP, o.buy),
                    o.pairIndex,
                    o.buy,
                    o.positionSize * o.leverage
                );

            a.price = priceAfterImpact;

            cancelReason = (
                t == IOrderExecutionTokenManagement.OpenLimitOrderType.LEGACY
                    ? (a.price < o.minPrice || a.price > o.maxPrice)
                    : (
                        t ==
                            IOrderExecutionTokenManagement
                                .OpenLimitOrderType
                                .REVERSAL
                            ? (
                                o.buy
                                    ? a.price > o.maxPrice
                                    : a.price < o.minPrice
                            )
                            : (
                                o.buy
                                    ? a.price < o.minPrice
                                    : a.price > o.maxPrice
                            )
                    )
            )
                ? CancelReason.NOT_HIT
                : (
                    !withinExposureLimits(
                        o.pairIndex,
                        o.buy,
                        o.positionSize,
                        o.leverage
                    )
                        ? CancelReason.EXPOSURE_LIMITS
                        : priceImpactP * o.leverage >
                            pairInfos.maxNegativePnlOnOpenP()
                        ? CancelReason.PRICE_IMPACT
                        : !withinMaxLeverage(o.pairIndex, o.leverage)
                        ? CancelReason.MAX_LEVERAGE
                        : CancelReason.NONE
                );

            if (cancelReason == CancelReason.NONE) {
                ITradingStorage.Trade memory finalTrade = registerTrade(
                    ITradingStorage.Trade(
                        o.trader,
                        o.pairIndex,
                        0,
                        o.positionSize,
                        t ==
                            IOrderExecutionTokenManagement
                                .OpenLimitOrderType
                                .REVERSAL
                            ? o.maxPrice // o.minPrice = o.maxPrice in that case
                            : a.price,
                        o.buy,
                        o.leverage,
                        o.tp,
                        o.sl
                    )
                );

                storageT.unregisterOpenLimitOrder(
                    o.trader,
                    o.pairIndex,
                    o.index
                );

                if (address(affiliation) != address(0) && address(referral) != address(0)) {

                    uint256 _activeId = affiliation.usersActiveID(finalTrade.trader);
                    AffiliationUserData memory _affiliationData = AffiliationUserData({
                        activeId: _activeId,
                        team: affiliation.usersTeam(finalTrade.trader),
                        nftData: affiliation.data(_activeId)
                    });
                    uint256 _referralTeamID = referral.userTeamID(finalTrade.trader);

                    emit OpenLimitExecutedWithAffiliationReferral(
                        a.orderId,
                        n.index,
                        finalTrade,
                        ITradingStorage.LimitOrder.OPEN,
                        finalTrade.openPrice,
                        priceImpactP,
                        finalTrade.positionSizeStable,
                        0,
                        0,
                        _affiliationData,
                        _referralTeamID
                    );

                } else {

                    emit OpenLimitExecuted(
                        a.orderId,
                        n.index,
                        finalTrade,
                        ITradingStorage.LimitOrder.OPEN,
                        finalTrade.openPrice,
                        priceImpactP,
                        finalTrade.positionSizeStable,
                        0,
                        0
                    );
                }
            }
        }

        if (cancelReason != CancelReason.NONE) {
            emit BotOrderCanceled(
                a.orderId,
                ITradingStorage.LimitOrder.OPEN,
                cancelReason
            );
        }

        storageT.unregisterPendingBotOrder(a.orderId);
    }

    function executeBotCloseOrderCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator notDone {
        ITradingStorage.PendingBotOrder memory o = storageT
            .reqID_pendingBotOrder(a.orderId);
        ITradingStorage.Trade memory t = getOpenTrade(
            o.trader,
            o.pairIndex,
            o.index
        );

        IAggregator01 aggregator = storageT.priceAggregator();

        CancelReason cancelReason = a.price == 0
            ? CancelReason.MARKET_CLOSED
            : (t.leverage == 0 ? CancelReason.NO_TRADE : CancelReason.NONE);

        if (cancelReason == CancelReason.NONE) {
            ITradingStorage.TradeInfo memory i = getOpenTradeInfo(
                t.trader,
                t.pairIndex,
                t.index
            );

            IPairsStorage pairsStored = aggregator.pairsStorage();

            Values memory v;

            v.price = pairsStored.guaranteedSlEnabled(t.pairIndex)
                ? o.orderType == ITradingStorage.LimitOrder.TP
                    ? t.tp
                    : o.orderType == ITradingStorage.LimitOrder.SL
                    ? t.sl
                    : a.price
                : a.price;

            v.levPosStable = t.positionSizeStable * t.leverage;
            v.posStable = v.levPosStable / t.leverage;

            if (o.orderType == ITradingStorage.LimitOrder.LIQ) {
                v.liqPrice = borrowingFees.getTradeLiquidationPrice(
                    IBorrowingFees.LiqPriceInput(
                        t.trader,
                        t.pairIndex,
                        t.index,
                        t.openPrice,
                        t.buy,
                        v.posStable,
                        t.leverage
                    )
                );

                // Bot reward in Stable
                v.reward1 = (
                    t.buy ? a.price <= v.liqPrice : a.price >= v.liqPrice
                )
                    ? (v.posStable * 5) / 100
                    : 0;
            } else {
                // Bot reward in Stable
                v.reward1 = ((o.orderType == ITradingStorage.LimitOrder.TP &&
                    t.tp > 0 &&
                    (t.buy ? a.price >= t.tp : a.price <= t.tp)) ||
                    (o.orderType == ITradingStorage.LimitOrder.SL &&
                        t.sl > 0 &&
                        (t.buy ? a.price <= t.sl : a.price >= t.sl)))
                    ? (v.levPosStable *
                        pairsStored.pairExecuteLimitOrderFeeP(t.pairIndex)) /
                        100 /
                        PRECISION
                    : 0;
            }

            cancelReason = v.reward1 == 0
                ? CancelReason.NOT_HIT
                : CancelReason.NONE;

            if (cancelReason == CancelReason.NONE) {
                v.profitP = currentPercentProfit(
                    t.openPrice,
                    v.price,
                    t.buy,
                    t.leverage
                );

                v.stableSentToTrader = unregisterTrade(
                    t,
                    v.profitP,
                    v.posStable,
                    i.openInterestStable,
                    o.orderType == ITradingStorage.LimitOrder.LIQ
                        ? v.reward1
                        : (v.levPosStable *
                            pairsStored.pairCloseFeeP(t.pairIndex)) /
                            100 /
                            PRECISION,
                    v.reward1
                );

                emit CloseLimitExecuted(
                    a.orderId,
                    o.index,
                    t,
                    o.orderType,
                    v.price,
                    0,
                    v.posStable,
                    v.profitP,
                    v.stableSentToTrader
                );
            }
        }

        if (cancelReason != CancelReason.NONE) {
            emit BotOrderCanceled(a.orderId, o.orderType, cancelReason);
        }

        storageT.unregisterPendingBotOrder(a.orderId);
    }

    function updateSlCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator notDone {
        IAggregator01 aggregator = storageT.priceAggregator();
        IAggregator01.PendingSl memory o = aggregator.pendingSlOrders(
            a.orderId
        );

        ITradingStorage.Trade memory t = getOpenTrade(
            o.trader,
            o.pairIndex,
            o.index
        );

        CancelReason cancelReason = t.leverage == 0
            ? CancelReason.NO_TRADE
            : CancelReason.NONE;

        if (cancelReason == CancelReason.NONE) {
            Values memory v;

            v.levPosStable = (t.positionSizeStable * t.leverage) / 2;

            v.reward1 = storageT.handleDevGovRefFees(
                t.pairIndex,
                v.levPosStable,
                false,
                false
            );

            t.positionSizeStable -= v.reward1;
            storageT.updateTrade(t);

            emit DevGovRefFeeCharged(t.trader, v.reward1);

            cancelReason = a.price == 0
                ? CancelReason.MARKET_CLOSED
                : (
                    (t.buy != o.buy || t.openPrice != o.openPrice)
                        ? CancelReason.WRONG_TRADE
                        : (t.buy ? o.newSl > a.price : o.newSl < a.price)
                        ? CancelReason.SL_REACHED
                        : CancelReason.NONE
                );

            if (cancelReason == CancelReason.NONE) {
                storageT.updateSl(o.trader, o.pairIndex, o.index, o.newSl);
                LastUpdated storage l = tradeLastUpdated[o.trader][o.pairIndex][
                    o.index
                ][TradeType.MARKET];
                l.sl = uint32(ChainUtils.getBlockNumber());

                emit SlUpdated(
                    a.orderId,
                    o.trader,
                    o.pairIndex,
                    o.index,
                    o.newSl
                );
            }
        }

        if (cancelReason != CancelReason.NONE) {
            emit SlCanceled(
                a.orderId,
                o.trader,
                o.pairIndex,
                o.index,
                cancelReason
            );
        }

        storageT.orderTokenManagement().addAggregatorFund();
        aggregator.unregisterPendingSlOrder(a.orderId);
    }

    function setTradeLastUpdated(
        SimplifiedTradeId calldata _id,
        LastUpdated memory _lastUpdated
    ) external onlyTrading {
        tradeLastUpdated[_id.trader][_id.pairIndex][_id.index][
            _id.tradeType
        ] = _lastUpdated;
    }

    function getAllPairsMaxLeverage() external view returns (uint256[] memory) {
        uint256 len = getPairsStorage().pairsCount();
        uint256[] memory lev = new uint256[](len);

        for (uint256 i; i < len; ) {
            lev[i] = pairMaxLeverage[i];
            unchecked {
                ++i;
            }
        }
        return lev;
    }

    function _setPairMaxLeverage(
        uint256 pairIndex,
        uint256 maxLeverage
    ) private {
        pairMaxLeverage[pairIndex] = maxLeverage;
        emit PairMaxLeverageUpdated(pairIndex, maxLeverage);
    }

    function registerTrade(
        ITradingStorage.Trade memory trade
    ) private returns (ITradingStorage.Trade memory) {
        IAggregator01 aggregator = storageT.priceAggregator();
        IPairsStorage pairsStored = aggregator.pairsStorage();

        Values memory v;

        v.levPosStable = trade.positionSizeStable * trade.leverage;

        // 1. Charge opening fee
        v.reward2 = storageT.handleDevGovRefFees(
            trade.pairIndex,
            v.levPosStable,
            true,
            true
        );

        trade.positionSizeStable -= v.reward2;

        emit DevGovRefFeeCharged(trade.trader, v.reward2);

        // 2. Charge OrderExecutionReward
        v.reward2 =
            (v.levPosStable *
                pairsStored.pairExecuteLimitOrderFeeP(trade.pairIndex)) /
            100 /
            PRECISION;
        trade.positionSizeStable -= v.reward2;

        // 3. Distribute OrderExecutionReward
        distributeOrderExecutionReward(trade.trader, v.reward2);
        storageT.orderTokenManagement().addAggregatorFund();

        // 4. Set trade final details
        trade.index = storageT.firstEmptyTradeIndex(
            trade.trader,
            trade.pairIndex
        );

        trade.tp = correctTp(
            trade.openPrice,
            trade.leverage,
            trade.tp,
            trade.buy
        );
        trade.sl = correctSl(
            trade.openPrice,
            trade.leverage,
            trade.sl,
            trade.buy
        );

        // 5. Call other contracts
        pairInfos.storeTradeInitialAccFees(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy
        );
        pairsStored.updateGroupCollateral(
            trade.pairIndex,
            trade.positionSizeStable,
            trade.buy,
            true
        );
        borrowingFees.handleTradeAction(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.positionSizeStable * trade.leverage,
            true,
            trade.buy
        );

        // 6. Store final trade in storage contract
        storageT.storeTrade(
            trade,
            ITradingStorage.TradeInfo(
                0,
                trade.positionSizeStable * trade.leverage,
                0,
                0,
                false
            )
        );

        // 7. Store tradeLastUpdated
        LastUpdated storage lastUpdated = tradeLastUpdated[trade.trader][
            trade.pairIndex
        ][trade.index][TradeType.MARKET];
        uint32 currBlock = uint32(ChainUtils.getBlockNumber());
        lastUpdated.tp = currBlock;
        lastUpdated.sl = currBlock;
        lastUpdated.created = currBlock;

        return (trade);
    }

    function unregisterTrade(
        ITradingStorage.Trade memory trade,
        int256 percentProfit,
        uint256 currentStablePos,
        uint256 openInterestStable,
        uint256 closingFeeStable,
        uint256 botFeeStable
    ) private returns (uint256 stableSentToTrader) {
        IWorkPool workPool = storageT.workPool();

        // 1. Calculate net PnL (after all closing and holding fees)
        (stableSentToTrader, ) = _getTradeValue(
            trade,
            currentStablePos,
            percentProfit,
            closingFeeStable + botFeeStable
        );

        // 2. Calls to other contracts
        borrowingFees.handleTradeAction(
            trade.trader,
            trade.pairIndex,
            trade.index,
            openInterestStable,
            false,
            trade.buy
        );
        getPairsStorage().updateGroupCollateral(
            trade.pairIndex,
            openInterestStable / trade.leverage,
            trade.buy,
            false
        );

        // 3. Unregister trade from storage
        storageT.unregisterTrade(trade.trader, trade.pairIndex, trade.index);

        Values memory v;

        // 4.1.1 Stable workPool reward
        v.reward2 = closingFeeStable;
        transferFromStorageToAddress(address(this), v.reward2);
        TokenInterface stableToken = storageT.stable();
        stableToken.approve(address(workPool), type(uint256).max);
        workPool.distributeReward(v.reward2);

        emit StableWorkPoolFeeCharged(trade.trader, v.reward2);

        // 4.1.2 OrderExecutionReward
        distributeOrderExecutionReward(trade.trader, botFeeStable);
        storageT.orderTokenManagement().addAggregatorFund();

        // 4.1.3 Take Stable from workPool if winning trade
        // or send Stable to workPool if losing trade
        uint256 stableLeftInStorage = currentStablePos - v.reward2;

        if (stableSentToTrader > stableLeftInStorage) {
            workPool.sendAssets(stableSentToTrader - stableLeftInStorage, trade.trader);
            transferFromStorageToAddress(trade.trader, stableLeftInStorage);
        } else {
            sendToWorkPool(stableLeftInStorage - stableSentToTrader, trade.trader);
            transferFromStorageToAddress(trade.trader, stableSentToTrader);
        }
    }

    function _getTradeValue(
        ITradingStorage.Trade memory trade,
        uint256 currentStablePos,
        int256 percentProfit,
        uint256 closingFees
    ) private returns (uint256 value, uint256 borrowingFee) {
        int256 netProfitP;

        (netProfitP, borrowingFee) = _getBorrowingFeeAdjustedPercentProfit(
            trade,
            currentStablePos,
            percentProfit
        );
        value = pairInfos.getTradeValue(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy,
            currentStablePos,
            trade.leverage,
            netProfitP,
            closingFees
        );

        emit BorrowingFeeCharged(trade.trader, value, borrowingFee);
    }

    function distributeOrderExecutionReward(
        address trader,
        uint256 amountStable
    ) private {
        transferFromStorageToAddress(address(this), amountStable);
        address _orderTokenManagement = address(
            storageT.orderTokenManagement()
        );
        storageT.stable().transfer(_orderTokenManagement, amountStable);
        emit OrderExecutionFeeCharged(trader, amountStable);
    }

    function sendToWorkPool(uint256 amountStable, address trader) private {
        transferFromStorageToAddress(address(this), amountStable);
        storageT.workPool().receiveAssets(amountStable, trader);
    }

    function transferFromStorageToAddress(
        address to,
        uint256 amountStable
    ) private {
        storageT.transferStable(address(storageT), to, amountStable);
    }

    function isGov() private view {
        if (msg.sender != storageT.gov()) {
            revert TradingCallbacksForbidden();
        }
    }

    function isPriceAggregator() private view {
        if (msg.sender != address(storageT.priceAggregator())) {
            revert TradingCallbacksForbidden();
        }
    }

    function isNotDone() private view {
        if (isDone) {
            revert TradingCallbacksForbidden();
        }
    }

    function isTrading() private view {
        if (msg.sender != storageT.trading()) {
            revert TradingCallbacksForbidden();
        }
    }

    function isManager() private view {
        if (msg.sender != pairInfos.manager()) {
            revert TradingCallbacksForbidden();
        }
    }

    function _getBorrowingFeeAdjustedPercentProfit(
        ITradingStorage.Trade memory trade,
        uint256 currentStablePos,
        int256 percentProfit
    ) private view returns (int256 netProfitP, uint256 borrowingFee) {
        borrowingFee = borrowingFees.getTradeBorrowingFee(
            IBorrowingFees.BorrowingFeeInput(
                trade.trader,
                trade.pairIndex,
                trade.index,
                trade.buy,
                currentStablePos,
                trade.leverage
            )
        );
        netProfitP =
            percentProfit -
            int256((borrowingFee * 100 * PRECISION) / currentStablePos);
    }

    function withinMaxLeverage(
        uint256 pairIndex,
        uint256 leverage
    ) private view returns (bool) {
        uint256 pairMaxLev = pairMaxLeverage[pairIndex];
        return
            pairMaxLev == 0
                ? leverage <= getPairsStorage().pairMaxLeverage(pairIndex)
                : leverage <= pairMaxLev;
    }

    function withinExposureLimits(
        uint256 pairIndex,
        bool buy,
        uint256 positionSizeStable,
        uint256 leverage
    ) private view returns (bool) {
        uint256 levPositionSizeStable = positionSizeStable * leverage;

        return
            storageT.openInterestStable(pairIndex, buy ? 0 : 1) +
                levPositionSizeStable <=
            storageT.openInterestStable(pairIndex, 2) &&
            borrowingFees.withinMaxGroupOi(pairIndex, buy, levPositionSizeStable);
    }

    function getPendingMarketOrder(
        uint256 orderId
    ) private view returns (ITradingStorage.PendingMarketOrder memory) {
        return storageT.reqID_pendingMarketOrder(orderId);
    }

    function getPairsStorage() private view returns (IPairsStorage) {
        return storageT.priceAggregator().pairsStorage();
    }

    function getOpenTrade(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) private view returns (ITradingStorage.Trade memory) {
        return storageT.openTrades(trader, pairIndex, index);
    }

    function getOpenTradeInfo(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) private view returns (ITradingStorage.TradeInfo memory) {
        return storageT.openTradesInfo(trader, pairIndex, index);
    }

    function currentPercentProfit(
        uint256 openPrice,
        uint256 currentPrice,
        bool buy,
        uint256 leverage
    ) private pure returns (int256 p) {
        int256 maxPnlP = int256(MAX_GAIN_P) * int256(PRECISION);

        p =
            ((
                buy
                    ? int256(currentPrice) - int256(openPrice)
                    : int256(openPrice) - int256(currentPrice)
            ) *
                100 *
                int256(PRECISION) *
                int256(leverage)) /
            int256(openPrice);

        p = p > maxPnlP ? maxPnlP : p;
    }

    function correctTp(
        uint256 openPrice,
        uint256 leverage,
        uint256 tp,
        bool buy
    ) private pure returns (uint256) {
        if (
            tp == 0 ||
            currentPercentProfit(openPrice, tp, buy, leverage) ==
            int256(MAX_GAIN_P) * int256(PRECISION)
        ) {
            uint256 tpDiff = (openPrice * MAX_GAIN_P) / leverage / 100;

            return
                buy
                    ? openPrice + tpDiff
                    : (tpDiff <= openPrice ? openPrice - tpDiff : 0);
        }

        return tp;
    }

    function correctSl(
        uint256 openPrice,
        uint256 leverage,
        uint256 sl,
        bool buy
    ) private pure returns (uint256) {
        if (
            sl > 0 &&
            currentPercentProfit(openPrice, sl, buy, leverage) <
            int256(MAX_SL_P) * int256(PRECISION) * -1
        ) {
            uint256 slDiff = (openPrice * MAX_SL_P) / leverage / 100;

            return buy ? openPrice - slDiff : openPrice + slDiff;
        }

        return sl;
    }

    function marketExecutionPrice(
        uint256 price,
        uint256 spreadP,
        bool long
    ) private pure returns (uint256) {
        uint256 priceDiff = (price * spreadP) / 100 / PRECISION;

        return long ? price + priceDiff : price - priceDiff;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint256);

    function arbChainID() external view returns (uint256);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns (uint256);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns (address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns (uint256);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBorrowingFees {

    struct PairGroup {
        uint16 groupIndex;
        uint48 block;
        uint64 initialAccFeeLong; 
        uint64 initialAccFeeShort; 
        uint64 prevGroupAccFeeLong; 
        uint64 prevGroupAccFeeShort; 
        uint64 pairAccFeeLong; 
        uint64 pairAccFeeShort; 
        uint64 _placeholder; // might be useful later
    }
    struct Pair {
        PairGroup[] groups;
        uint32 feePerBlock; 
        uint64 accFeeLong; 
        uint64 accFeeShort; 
        uint48 accLastUpdatedBlock;
        uint48 _placeholder; // might be useful later
        uint256 lastAccBlockWeightedMarketCap; // 1e40
    }
    struct Group {
        uint112 oiLong; 
        uint112 oiShort; 
        uint32 feePerBlock; 
        uint64 accFeeLong; 
        uint64 accFeeShort; 
        uint48 accLastUpdatedBlock;
        uint80 maxOi; 
        uint256 lastAccBlockWeightedMarketCap; 
    }
    struct InitialAccFees {
        uint64 accPairFee; 
        uint64 accGroupFee; 
        uint48 block;
        uint80 _placeholder; // might be useful later
    }
    struct PairParams {
        uint16 groupIndex;
        uint32 feePerBlock; 
    }
    struct GroupParams {
        uint32 feePerBlock; 
        uint80 maxOi; 
    }
    struct BorrowingFeeInput {
        address trader;
        uint256 pairIndex;
        uint256 index;
        bool long;
        uint256 collateral; 
        uint256 leverage;
    }
    struct LiqPriceInput {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 openPrice; 
        bool long;
        uint256 collateral; 
        uint256 leverage;
    }

    event PairParamsUpdated(uint indexed pairIndex, uint16 indexed groupIndex, uint32 feePerBlock);
    event PairGroupUpdated(uint indexed pairIndex, uint16 indexed prevGroupIndex, uint16 indexed newGroupIndex);
    event GroupUpdated(uint16 indexed groupIndex, uint32 feePerBlock, uint80 maxOi);
    event TradeInitialAccFeesStored(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint64 initialPairAccFee,
        uint64 initialGroupAccFee
    );
    event TradeActionHandled(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        bool open,
        bool long,
        uint256 positionSizeStable 
    );
    event PairAccFeesUpdated(
        uint256 indexed pairIndex,
        uint256 currentBlock,
        uint64 accFeeLong,
        uint64 accFeeShort,
        uint256 accBlockWeightedMarketCap
    );
    event GroupAccFeesUpdated(
        uint16 indexed groupIndex,
        uint256 currentBlock,
        uint64 accFeeLong,
        uint64 accFeeShort,
        uint256 accBlockWeightedMarketCap
    );
    event GroupOiUpdated(
        uint16 indexed groupIndex,
        bool indexed long,
        bool indexed increase,
        uint112 amount,
        uint112 oiLong,
        uint112 oiShort
    );

    function getTradeLiquidationPrice(LiqPriceInput calldata) external view returns (uint256); 

    function getTradeBorrowingFee(BorrowingFeeInput memory) external view returns (uint256); 

    function handleTradeAction(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 positionSizeStable, // (collateral * leverage)
        bool open,
        bool long
    ) external;

    function withinMaxGroupOi(uint256 pairIndex, bool long, uint256 positionSizeStable) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChainlinkFeed{
    function latestRoundData() external view returns (uint80,int256,uint256,uint256,uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFoxifyAffiliation {
    enum Level {
        UNKNOWN,
        BRONZE,
        SILVER,
        GOLD
    }

    struct NFTData {
        Level level;
        bytes32 randomValue;
        uint256 timestamp;
    }

    function data(uint256) external view returns (NFTData memory);

    function usersActiveID(address) external view returns (uint256);

    function usersTeam(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFoxifyReferral {
    function maxTeamID() external view returns (uint256);

    function teamOwner(uint256) external view returns (address);

    function userTeamID(address) external view returns (uint256);

    event TeamCreated(uint256 teamID, address owner);
    event TeamJoined(uint256 indexed teamID, address indexed user);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPairInfos {
    
    struct TradeInitialAccFees {
        uint256 rollover;  
        int256 funding;  
        bool openedAfterUpdate;
    }

    function tradeInitialAccFees(address, uint256, uint256) external view returns (TradeInitialAccFees memory);

    function maxNegativePnlOnOpenP() external view returns (uint256); 

    function storeTradeInitialAccFees(address trader, uint256 pairIndex, uint256 index, bool long) external;

    function getTradePriceImpact(
        uint256 openPrice, 
        uint256 pairIndex,
        bool long,
        uint256 openInterest 
    )
        external
        view
        returns (
            uint256 priceImpactP, 
            uint256 priceAfterImpact 
        );

    function getTradeRolloverFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 collateral 
    ) external view returns (uint256);

    function getTradeFundingFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, 
        uint256 leverage
    )
        external
        view
        returns (
            int256  // Positive => Fee, Negative => Reward
        );

    function getTradeLiquidationPricePure(
        uint256 openPrice, 
        bool long,
        uint256 collateral, 
        uint256 leverage,
        uint256 rolloverFee, 
        int256 fundingFee 
    ) external pure returns (uint256);

    function getTradeLiquidationPrice(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 openPrice, 
        bool long,
        uint256 collateral, 
        uint256 leverage
    ) external view returns (uint256); 

    function getTradeValue(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral,  
        uint256 leverage,
        int256 percentProfit, 
        uint256 closingFee  
    ) external returns (uint256);  

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPairsStorage {

    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } 

    function incrementCurrentOrderId() external returns (uint256);

    function updateGroupCollateral(uint256, uint256, bool, bool) external;

    function pairJob(uint256) external returns (string memory, string memory, bytes32, uint256);

    function pairFeed(uint256) external view returns (Feed memory);

    function pairSpreadP(uint256) external view returns (uint256);

    function pairMinLeverage(uint256) external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);

    function groupMaxCollateral(uint256) external view returns (uint256);

    function groupCollateral(uint256, bool) external view returns (uint256);

    function guaranteedSlEnabled(uint256) external view returns (bool);

    function pairOpenFeeP(uint256) external view returns (uint256);

    function pairCloseFeeP(uint256) external view returns (uint256);

    function pairOracleFeeP(uint256) external view returns (uint256);

    function pairExecuteLimitOrderFeeP(uint256) external view returns (uint256);

    function pairReferralFeeP(uint256) external view returns (uint256);

    function pairMinLevPosStable(uint256) external view returns (uint256);

    function pairsCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./TokenInterface.sol";
import "./IWorkPool.sol";
import "./IPairsStorage.sol";
import "./IChainlinkFeed.sol";


interface ITradingStorage {

    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }

    struct Trade {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSizeStable;
        uint256 openPrice;
        bool buy;
        uint256 leverage;
        uint256 tp;
        uint256 sl; 
    }

    struct TradeInfo {
        uint256 tokenId;
        uint256 openInterestStable; 
        uint256 tpLastUpdated;
        uint256 slLastUpdated;
        bool beingMarketClosed;
    }

    struct OpenLimitOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSize;
        bool buy;
        uint256 leverage;
        uint256 tp;
        uint256 sl; 
        uint256 minPrice; 
        uint256 maxPrice; 
        uint256 block;
        uint256 tokenId; // index in supportedTokens
    }

    struct PendingMarketOrder {
        Trade trade;
        uint256 block;
        uint256 wantedPrice; 
        uint256 slippageP;
        uint256 tokenId; // index in supportedTokens
    }

    struct PendingBotOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint256);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function ref() external view returns (address);

    function devFeesStable() external view returns (uint256);

    function govFeesStable() external view returns (uint256);

    function refFeesStable() external view returns (uint256);

    function stable() external view returns (TokenInterface);

    function token() external view returns (TokenInterface);

    function orderTokenManagement() external view returns (IOrderExecutionTokenManagement);

    function linkErc677() external view returns (TokenInterface);

    function priceAggregator() external view returns (IAggregator01);

    function workPool() external view returns (IWorkPool);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint256, bool) external;

    function transferStable(address, address, uint256) external;

    function transferLinkToAggregator(address, uint256, uint256) external;

    function unregisterTrade(address, uint256, uint256) external;

    function unregisterPendingMarketOrder(uint256, bool) external;

    function unregisterOpenLimitOrder(address, uint256, uint256) external;

    function hasOpenLimitOrder(address, uint256, uint256) external view returns (bool);

    function storePendingMarketOrder(PendingMarketOrder memory, uint256, bool) external;

    function openTrades(address, uint256, uint256) external view returns (Trade memory);

    function openTradesInfo(address, uint256, uint256) external view returns (TradeInfo memory);

    function updateSl(address, uint256, uint256, uint256) external;

    function updateTp(address, uint256, uint256, uint256) external;

    function getOpenLimitOrder(address, uint256, uint256) external view returns (OpenLimitOrder memory);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint256) external view returns (PendingMarketOrder memory);

    function storePendingBotOrder(PendingBotOrder memory, uint256) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint256) external view returns (uint256);

    function firstEmptyOpenLimitIndex(address, uint256) external view returns (uint256);

    function reqID_pendingBotOrder(uint256) external view returns (PendingBotOrder memory);

    function updateTrade(Trade memory) external;

    function unregisterPendingBotOrder(uint256) external;

    function handleDevGovRefFees(uint256, uint256, bool, bool) external returns (uint256);

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint256) external view returns (uint256);

    function openTradesCount(address, uint256) external view returns (uint256);

    function pendingMarketOpenCount(address, uint256) external view returns (uint256);

    function pendingMarketCloseCount(address, uint256) external view returns (uint256);

    function maxTradesPerPair() external view returns (uint256);

    function pendingOrderIdsCount(address) external view returns (uint256);

    function maxPendingMarketOrders() external view returns (uint256);

    function openInterestStable(uint256, uint256) external view returns (uint256);

    function getPendingOrderIds(address) external view returns (uint256[] memory);

    function pairTradersArray(uint256) external view returns(address[] memory);

    function setWorkPool(address) external;

}


interface IAggregator01 {

    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    struct PendingSl {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 openPrice;
        bool buy;
        uint256 newSl;
    }

    function pairsStorage() external view returns (IPairsStorage);

    function getPrice(uint256, OrderType, uint256) external returns (uint256);

    function tokenPriceStable() external returns (uint256);

    function linkFee() external view returns (uint256);

    function openFeeP(uint256) external view returns (uint256);

    function pendingSlOrders(uint256) external view returns (PendingSl memory);

    function storePendingSlOrder(uint256 orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint256 orderId) external;
}


interface IAggregator02 is IAggregator01 {
    function linkPriceFeed() external view returns (IChainlinkFeed);
}


interface IOrderExecutionTokenManagement {

    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function setOpenLimitOrderType(address, uint256, uint256, OpenLimitOrderType) external;

    function openLimitOrderTypes(address, uint256, uint256) external view returns (OpenLimitOrderType);
    
    function addAggregatorFund() external returns (uint256);
}


interface ITradingCallbacks01 {

    enum TradeType {
        MARKET,
        LIMIT
    }

    struct SimplifiedTradeId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        TradeType tradeType;
    }
    
    struct LastUpdated {
        uint32 tp;
        uint32 sl;
        uint32 limit;
        uint32 created;
    }

    function tradeLastUpdated(address, uint256, uint256, TradeType) external view returns (LastUpdated memory);

    function setTradeLastUpdated(SimplifiedTradeId calldata, LastUpdated memory) external;

    function canExecuteTimeout() external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

interface IWorkPool {
    
    function mainPool() external view returns (address);

    function mainPoolOwner() external view returns (address);

    function currentEpochStart() external view returns (uint256);

    function currentEpochPositiveOpenPnl() external view returns (uint256);

    function updateAccPnlPerTokenUsed(uint256 prevPositiveOpenPnl, uint256 newPositiveOpenPnl) external returns (uint256);

    function sendAssets(uint256 assets, address receiver) external;

    function receiveAssets(uint256 assets, address user) external;

    function distributeReward(uint256 assets) external;

    function currentBalanceStable() external view returns (uint256);

    function tvl() external view returns (uint256);

    function marketCap() external view returns (uint256);

    function getPendingAccBlockWeightedMarketCap(uint256 currentBlock) external view returns (uint256);

    function shareToAssetsPrice() external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);

    function refill(uint256 assets) external; 

    function deplete(uint256 assets) external;

    function withdrawEpochsTimelock() external view returns (uint256);

    function collateralizationP() external view returns (uint256); 

    function currentEpoch() external view returns (uint256);

    function accPnlPerTokenUsed() external view returns (int256);

    function accPnlPerToken() external view returns (int256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface TokenInterface{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IArbSys.sol";


library ChainUtils {

    error ChainUtilsOverflow();

    uint256 public constant ARBITRUM_MAINNET = 42161;
    uint256 public constant ARBITRUM_GOERLI = 421613;
    IArbSys public constant ARB_SYS = IArbSys(address(100));

    function getBlockNumber() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_GOERLI) {
            return ARB_SYS.arbBlockNumber();
        }

        return block.number;
    }

    function getUint48BlockNumber(uint256 blockNumber) internal pure returns (uint48) {
        if (blockNumber > type(uint48).max) revert ChainUtilsOverflow();
        return uint48(blockNumber);
    }
}