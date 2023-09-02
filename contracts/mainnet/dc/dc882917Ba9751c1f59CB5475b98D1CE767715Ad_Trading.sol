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
import "../interfaces/IBorrowingFees.sol";
import "../libraries/ChainUtils.sol";
import "../libraries/TradeUtils.sol";


contract Trading {
    using TradeUtils for address;

    uint256 constant PRECISION = 1e10;
    uint256 constant MAX_SL_P = 75; // -75% PNL

    ITradingStorage public immutable storageT;
    IOrderExecutionTokenManagement public immutable orderTokenManagement;
    IPairInfos public immutable pairInfos;
    IBorrowingFees public immutable borrowingFees;

    uint256 public maxPosStable;
    uint256 public marketOrdersTimeout;

    bool public isPaused; // Prevent opening new trades
    bool public isDone; // Prevent any interaction with the contract

    event Done(bool done);
    event Paused(bool paused);

    event NumberUpdated(string name, uint256 value);

    event MarketOrderInitiated(uint256 indexed orderId, address indexed trader, uint256 indexed pairIndex, bool open);

    event OpenLimitPlaced(address indexed trader, uint256 indexed pairIndex, uint256 index);
    event OpenLimitUpdated(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 newPrice,
        uint256 newTp,
        uint256 newSl
    );
    event OpenLimitCanceled(address indexed trader, uint256 indexed pairIndex, uint256 index);

    event TpUpdated(address indexed trader, uint256 indexed pairIndex, uint256 index, uint256 newTp);
    event SlUpdated(address indexed trader, uint256 indexed pairIndex, uint256 index, uint256 newSl);
    event SlUpdateInitiated(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 newSl
    );

    event ChainlinkCallbackTimeout(uint256 indexed orderId, ITradingStorage.PendingMarketOrder order);
    event CouldNotCloseTrade(address indexed trader, uint256 indexed pairIndex, uint256 index);

    error TradingWrongParameters();
    error TradingInvalidGovAddress(address account);
    error TradingDone();
    error TradingInvalidValue(uint256 value);
    error TradingPaused();
    error TradingOverflow();
    error TradingAboveMaxTradesPerPair();
    error TradingAboveMaxPendingOrders(uint256 amount);
    error TradingAboveMaxPos(uint256 amount);
    error TradingBelowMinPos(uint256 amount);
    error TradingInvalidLeverage();
    error TradingWrongTP();
    error TradingWrongSL();
    error TradingPriceImpactTooHigh();
    error TradingIsContract();
    error TradingAlreadyBeingClosed();
    error TradingNoTrade();
    error TradingNoLimitOrder();
    error TradingTooBigSL();
    error TradingTimeout();
    error TradingInvalidOrderOwner();
    error TradingWrongMarketOrderType();
    error TradingHasSL();
    error TradingNoSL();
    error TradingNoTP();

    modifier onlyGov() {
        isGov();
        _;
    }

    modifier notContract() {
        isNotContract();
        _;
    }
    
    modifier notDone() {
        isNotDone();
        _;
    }

    constructor(
        ITradingStorage _storageT,
        IOrderExecutionTokenManagement _orderTokenManagement,
        IPairInfos _pairInfos,
        IBorrowingFees _borrowingFees,
        uint256 _maxPosStable,
        uint256 _marketOrdersTimeout
    ) {
        if (address(_storageT) == address(0) ||
            address(_orderTokenManagement) == address(0) ||
            address(_pairInfos) == address(0) ||
            address(_borrowingFees) == address(0) ||
            _maxPosStable == 0 ||
            _marketOrdersTimeout == 0) {
            revert TradingWrongParameters();
        }

        storageT = _storageT;
        orderTokenManagement = _orderTokenManagement;
        pairInfos = _pairInfos;
        borrowingFees = _borrowingFees;

        maxPosStable = _maxPosStable;
        marketOrdersTimeout = _marketOrdersTimeout;
    }

    function setMaxPosStable(uint256 value) external onlyGov {
        if (value == 0) {
            revert TradingInvalidValue(0);
        }
        maxPosStable = value;
        emit NumberUpdated("maxPosStable", value);
    }

    function setMarketOrdersTimeout(uint256 value) external onlyGov {
        if (value == 0) {
            revert TradingInvalidValue(0);
        }
        marketOrdersTimeout = value;
        emit NumberUpdated("marketOrdersTimeout", value);
    }

    function pause() external onlyGov {
        isPaused = !isPaused;
        emit Paused(isPaused);
    }

    function done() external onlyGov {
        isDone = !isDone;
        emit Done(isDone);
    }

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        ITradingStorage.Trade memory t,
        IOrderExecutionTokenManagement.OpenLimitOrderType orderType, // LEGACY => market
        uint256 slippageP // for market orders only
    ) external notContract notDone {
        if (isPaused) revert TradingPaused();
        if (t.openPrice * slippageP >= type(uint256).max) revert TradingOverflow();

        IAggregator01 aggregator = storageT.priceAggregator();
        IPairsStorage pairsStored = aggregator.pairsStorage();

        address sender = msg.sender;

        if (storageT.openTradesCount(sender, t.pairIndex) +
            storageT.pendingMarketOpenCount(sender, t.pairIndex) +
            storageT.openLimitOrdersCount(sender, t.pairIndex) >=
            storageT.maxTradesPerPair()) {
            revert TradingAboveMaxTradesPerPair();
        }

        if (storageT.pendingOrderIdsCount(sender) >= storageT.maxPendingMarketOrders()) {
            revert TradingAboveMaxPendingOrders(storageT.pendingOrderIdsCount(sender));
        }
        if (t.positionSizeStable > maxPosStable) revert TradingAboveMaxPos(t.positionSizeStable);
        if (t.positionSizeStable * t.leverage < pairsStored.pairMinLevPosStable(t.pairIndex)) {
            revert TradingBelowMinPos(t.positionSizeStable * t.leverage);
        }

        if (t.leverage == 0 ||
            t.leverage < pairsStored.pairMinLeverage(t.pairIndex) ||
            t.leverage > pairMaxLeverage(pairsStored, t.pairIndex)) {
            revert TradingInvalidLeverage();
        }

        if (t.tp != 0 && (t.buy ? t.tp <= t.openPrice : t.tp >= t.openPrice)) revert TradingWrongTP();
        if (t.sl != 0 && (t.buy ? t.sl >= t.openPrice : t.sl <= t.openPrice)) revert TradingWrongSL();

        (uint256 priceImpactP, ) = pairInfos.getTradePriceImpact(0, t.pairIndex, t.buy, t.positionSizeStable * t.leverage);
        if (priceImpactP * t.leverage > pairInfos.maxNegativePnlOnOpenP()) revert TradingPriceImpactTooHigh();

        storageT.transferStable(sender, address(storageT), t.positionSizeStable);

        if (orderType != IOrderExecutionTokenManagement.OpenLimitOrderType.LEGACY) {
            uint256 index = storageT.firstEmptyOpenLimitIndex(sender, t.pairIndex);

            storageT.storeOpenLimitOrder(
                ITradingStorage.OpenLimitOrder(
                    sender,
                    t.pairIndex,
                    index,
                    t.positionSizeStable,
                    t.buy,
                    t.leverage,
                    t.tp,
                    t.sl,
                    t.openPrice,
                    t.openPrice,
                    block.number,
                    0
                )
            );

            orderTokenManagement.setOpenLimitOrderType(sender, t.pairIndex, index, orderType);
            storageT.callbacks().setTradeLastUpdated(
                sender,
                t.pairIndex,
                index,
                ITradingCallbacks01.TradeType.LIMIT,
                ChainUtils.getBlockNumber()
            );

            emit OpenLimitPlaced(sender, t.pairIndex, index);
        } else {
            uint256 orderId = aggregator.getPrice(
                t.pairIndex,
                IAggregator01.OrderType.MARKET_OPEN,
                t.positionSizeStable * t.leverage
            );

            storageT.storePendingMarketOrder(
                ITradingStorage.PendingMarketOrder(
                    ITradingStorage.Trade(
                        sender,
                        t.pairIndex,
                        0,
                        t.positionSizeStable,
                        0,
                        t.buy,
                        t.leverage,
                        t.tp,
                        t.sl
                    ),
                    0,
                    t.openPrice,
                    slippageP,
                    0
                ),
                orderId,
                true
            );

            emit MarketOrderInitiated(orderId, sender, t.pairIndex, true);
        }
    }

    // Close trade (MARKET)
    function closeTradeMarket(uint256 pairIndex, uint256 index) external notContract notDone {
        address sender = msg.sender;

        ITradingStorage.Trade memory t = storageT.openTrades(sender, pairIndex, index);
        ITradingStorage.TradeInfo memory i = storageT.openTradesInfo(sender, pairIndex, index);

        if (storageT.pendingOrderIdsCount(sender) >= storageT.maxPendingMarketOrders()) {
            revert TradingAboveMaxPendingOrders(storageT.pendingOrderIdsCount(sender));
        }
        if (i.beingMarketClosed) revert TradingAlreadyBeingClosed();
        if (t.leverage == 0) revert TradingNoTrade();

        uint256 orderId = storageT.priceAggregator().getPrice(
            pairIndex,
            IAggregator01.OrderType.MARKET_CLOSE,
            (t.positionSizeStable * t.leverage) / PRECISION
        );

        storageT.storePendingMarketOrder(
            ITradingStorage.PendingMarketOrder(
                ITradingStorage.Trade(sender, pairIndex, index, 0, 0, false, 0, 0, 0),
                0,
                0,
                0,
                0
            ),
            orderId,
            false
        );

        emit MarketOrderInitiated(orderId, sender, pairIndex, false);
    }

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint256 pairIndex,
        uint256 index,
        uint256 price,
        uint256 tp,
        uint256 sl
    ) external notContract notDone {
        address sender = msg.sender;
        if (!storageT.hasOpenLimitOrder(sender, pairIndex, index)) revert TradingNoLimitOrder();

        ITradingStorage.OpenLimitOrder memory o = storageT.getOpenLimitOrder(sender, pairIndex, index);

        if (tp != 0 && (o.buy ? tp <= price : tp >= price)) revert TradingWrongTP();
        if (sl != 0 && (o.buy ? sl >= price : sl <= price)) revert TradingWrongSL();

        o.minPrice = price;
        o.maxPrice = price;
        o.tp = tp;
        o.sl = sl;

        storageT.updateOpenLimitOrder(o);
        storageT.callbacks().setTradeLastUpdated(
            sender,
            pairIndex,
            index,
            ITradingCallbacks01.TradeType.LIMIT,
            ChainUtils.getBlockNumber()
        );

        emit OpenLimitUpdated(sender, pairIndex, index, price, tp, sl);
    }

    function cancelOpenLimitOrder(uint256 pairIndex, uint256 index) external notContract notDone {
        address sender = msg.sender;
        if (!storageT.hasOpenLimitOrder(sender, pairIndex, index)) revert TradingNoLimitOrder();

        ITradingStorage.OpenLimitOrder memory o = storageT.getOpenLimitOrder(sender, pairIndex, index);

        storageT.unregisterOpenLimitOrder(sender, pairIndex, index);
        storageT.transferStable(address(storageT), sender, o.positionSize);

        emit OpenLimitCanceled(sender, pairIndex, index);
    }

    // Manage limit order (TP/SL)
    function updateTp(uint256 pairIndex, uint256 index, uint256 newTp) external notContract notDone {
        address sender = msg.sender;

        ITradingStorage.Trade memory t = storageT.openTrades(sender, pairIndex, index);
        if (t.leverage == 0) revert TradingNoTrade();

        storageT.updateTp(sender, pairIndex, index, newTp);
        storageT.callbacks().setTpLastUpdated(
            sender,
            pairIndex,
            index,
            ITradingCallbacks01.TradeType.MARKET,
            ChainUtils.getBlockNumber()
        );

        emit TpUpdated(sender, pairIndex, index, newTp);
    }

    function updateSl(uint256 pairIndex, uint256 index, uint256 newSl) external notContract notDone {
        address sender = msg.sender;

        ITradingStorage.Trade memory t = storageT.openTrades(sender, pairIndex, index);

        if (t.leverage == 0) revert TradingNoTrade();

        uint256 maxSlDist = (t.openPrice * MAX_SL_P) / 100 / t.leverage;

        if (newSl != 0 && (t.buy ? newSl < t.openPrice - maxSlDist : newSl > t.openPrice + maxSlDist)) {
            revert TradingTooBigSL();
        }

        IAggregator01 aggregator = storageT.priceAggregator();

        if (newSl == 0 || !aggregator.pairsStorage().guaranteedSlEnabled(pairIndex)) {
            storageT.updateSl(sender, pairIndex, index, newSl);
            storageT.callbacks().setSlLastUpdated(
                sender,
                pairIndex,
                index,
                ITradingCallbacks01.TradeType.MARKET,
                ChainUtils.getBlockNumber()
            );

            emit SlUpdated(sender, pairIndex, index, newSl);
        } else {
            uint256 orderId = aggregator.getPrice(
                pairIndex,
                IAggregator01.OrderType.UPDATE_SL,
                (t.positionSizeStable * t.leverage) / PRECISION
            );

            aggregator.storePendingSlOrder(
                orderId,
                IAggregator01.PendingSl(sender, pairIndex, index, t.openPrice, t.buy, newSl)
            );

            emit SlUpdateInitiated(orderId, sender, pairIndex, index, newSl);
        }
    }

    // Execute limit order
    function executeBotOrder(
        ITradingStorage.LimitOrder orderType,
        address trader,
        uint256 pairIndex,
        uint256 index
    ) external notContract notDone {
        if (!canExecute(
                orderType,
                ITradingCallbacks01.SimplifiedTradeId(
                    trader,
                    pairIndex,
                    index,
                    orderType == ITradingStorage.LimitOrder.OPEN
                        ? ITradingCallbacks01.TradeType.LIMIT
                        : ITradingCallbacks01.TradeType.MARKET
                )
        )) {
            revert TradingTimeout();
        }

        ITradingStorage.Trade memory t;

        if (orderType == ITradingStorage.LimitOrder.OPEN) {
            if (!storageT.hasOpenLimitOrder(trader, pairIndex, index)) revert TradingNoLimitOrder();
        } else {
            t = storageT.openTrades(trader, pairIndex, index);

            if (t.leverage == 0) revert TradingNoTrade();

            if (orderType == ITradingStorage.LimitOrder.LIQ) {
                uint256 liqPrice = borrowingFees.getTradeLiquidationPrice(
                    IBorrowingFees.LiqPriceInput(
                        t.trader,
                        t.pairIndex,
                        t.index,
                        t.openPrice,
                        t.buy,
                        t.positionSizeStable,
                        t.leverage
                    )
                );

                if (t.sl != 0 && (t.buy ? liqPrice <= t.sl : liqPrice >= t.sl)) revert TradingHasSL();
            } else {
                if (orderType == ITradingStorage.LimitOrder.SL && t.sl == 0) revert TradingNoSL();
                if (orderType == ITradingStorage.LimitOrder.TP && t.tp == 0) revert TradingNoTP();
            }
        }

        uint256 leveragedPosStable;

        if (orderType == ITradingStorage.LimitOrder.OPEN) {
            ITradingStorage.OpenLimitOrder memory l = storageT.getOpenLimitOrder(trader, pairIndex, index);

            leveragedPosStable = l.positionSize * l.leverage;
            (uint256 priceImpactP, ) = pairInfos.getTradePriceImpact(0, l.pairIndex, l.buy, leveragedPosStable);

            if (priceImpactP * l.leverage > pairInfos.maxNegativePnlOnOpenP()) revert TradingPriceImpactTooHigh();
        } else {
            leveragedPosStable = t.positionSizeStable * t.leverage;
        }

        IAggregator01 aggregator = storageT.priceAggregator();
        uint256 orderId = aggregator.getPrice(
            pairIndex,
            orderType == ITradingStorage.LimitOrder.OPEN
                ? IAggregator01.OrderType.LIMIT_OPEN
                : IAggregator01.OrderType.LIMIT_CLOSE,
            leveragedPosStable
        );

        storageT.storePendingBotOrder(
            ITradingStorage.PendingBotOrder(trader, pairIndex, index, orderType),
            orderId
        );
    }

    function openTradeMarketTimeout(uint256 _order) external notContract notDone {
        address sender = msg.sender;

        ITradingStorage.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);
        ITradingStorage.Trade memory t = o.trade;

        if (o.block == 0 || block.number < o.block + marketOrdersTimeout) revert TradingTimeout();
        if (t.trader != sender) revert TradingInvalidOrderOwner();
        if (t.leverage == 0) revert TradingWrongMarketOrderType();

        storageT.unregisterPendingMarketOrder(_order, true);
        storageT.transferStable(address(storageT), sender, t.positionSizeStable);

        emit ChainlinkCallbackTimeout(_order, o);
    }

    function closeTradeMarketTimeout(uint256 _order) external notContract notDone {
        address sender = msg.sender;

        ITradingStorage.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);
        ITradingStorage.Trade memory t = o.trade;

        if (o.block == 0 || block.number < o.block + marketOrdersTimeout) revert TradingTimeout();
        if (t.trader != sender) revert TradingInvalidOrderOwner();
        if (t.leverage > 0) revert TradingWrongMarketOrderType();

        storageT.unregisterPendingMarketOrder(_order, false);

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSignature("closeTradeMarket(uint256,uint256)", t.pairIndex, t.index)
        );

        if (!success) {
            emit CouldNotCloseTrade(sender, t.pairIndex, t.index);
        }

        emit ChainlinkCallbackTimeout(_order, o);
    }

    function canExecute(
        ITradingStorage.LimitOrder orderType,
        ITradingCallbacks01.SimplifiedTradeId memory id
    ) private view returns (bool) {
        if (orderType == ITradingStorage.LimitOrder.LIQ) return true;

        uint256 b = ChainUtils.getBlockNumber();
        address cb = storageT.callbacks();

        if (orderType == ITradingStorage.LimitOrder.TP) return !cb.isTpInTimeout(id, b);
        if (orderType == ITradingStorage.LimitOrder.SL) return !cb.isSlInTimeout(id, b);

        return !cb.isLimitInTimeout(id, b);
    }

    function pairMaxLeverage(IPairsStorage pairsStored, uint256 pairIndex) private view returns (uint256) {
        uint256 max = ITradingCallbacks01(storageT.callbacks()).pairMaxLeverage(pairIndex);
        return max > 0 ? max : pairsStored.pairMaxLeverage(pairIndex);
    }

    function isGov() private view {
        if (msg.sender != storageT.gov()) {
            revert TradingInvalidGovAddress(msg.sender);
        }
    }

    function isNotContract() private view {
        if (tx.origin != msg.sender) revert TradingIsContract();
    }

    function isNotDone() private view {
        if (isDone) revert TradingDone();
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/ITradingStorage.sol";


library TradeUtils {

    function setTradeLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        ITradingCallbacks01.TradeType _type,
        uint256 blockNumber
    ) external {
        uint32 b = uint32(blockNumber);
        ITradingCallbacks01 callbacks = ITradingCallbacks01(_callbacks);
        callbacks.setTradeLastUpdated(
            ITradingCallbacks01.SimplifiedTradeId(trader, pairIndex, index, _type),
            ITradingCallbacks01.LastUpdated(b, b, b, b)
        );
    }

    function setSlLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        ITradingCallbacks01.TradeType _type,
        uint256 blockNumber
    ) external {
        (
            ITradingCallbacks01 callbacks,
            ITradingCallbacks01.LastUpdated memory l,
            ITradingCallbacks01.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.sl = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function setTpLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        ITradingCallbacks01.TradeType _type,
        uint256 blockNumber
    ) external {
        (
            ITradingCallbacks01 callbacks,
            ITradingCallbacks01.LastUpdated memory l,
            ITradingCallbacks01.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.tp = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function setLimitLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        ITradingCallbacks01.TradeType _type,
        uint256 blockNumber
    ) external {
        (
            ITradingCallbacks01 callbacks,
            ITradingCallbacks01.LastUpdated memory l,
            ITradingCallbacks01.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.limit = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function isTpInTimeout(
        address _callbacks,
        ITradingCallbacks01.SimplifiedTradeId memory id,
        uint256 currentBlock
    ) external view returns (bool) {
        (ITradingCallbacks01 callbacks, ITradingCallbacks01.LastUpdated memory l, ) = _getTradeLastUpdated(
            _callbacks,
            id.trader,
            id.pairIndex,
            id.index,
            id.tradeType
        );

        return currentBlock < uint256(l.tp) + callbacks.canExecuteTimeout();
    }

    function isSlInTimeout(
        address _callbacks,
        ITradingCallbacks01.SimplifiedTradeId memory id,
        uint256 currentBlock
    ) external view returns (bool) {
        (ITradingCallbacks01 callbacks, ITradingCallbacks01.LastUpdated memory l, ) = _getTradeLastUpdated(
            _callbacks,
            id.trader,
            id.pairIndex,
            id.index,
            id.tradeType
        );

        return currentBlock < uint256(l.sl) + callbacks.canExecuteTimeout();
    }

    function isLimitInTimeout(
        address _callbacks,
        ITradingCallbacks01.SimplifiedTradeId memory id,
        uint256 currentBlock
    ) external view returns (bool) {
        (ITradingCallbacks01 callbacks, ITradingCallbacks01.LastUpdated memory l, ) = _getTradeLastUpdated(
            _callbacks,
            id.trader,
            id.pairIndex,
            id.index,
            id.tradeType
        );

        return currentBlock < uint256(l.limit) + callbacks.canExecuteTimeout();
    }

    function getTradeLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        ITradingCallbacks01.TradeType _type
    )
        external
        view
        returns (
            ITradingCallbacks01,
            ITradingCallbacks01.LastUpdated memory,
            ITradingCallbacks01.SimplifiedTradeId memory
        )
    {
        return _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);
    }

    function _getTradeLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        ITradingCallbacks01.TradeType _type
    )
        internal
        view
        returns (
            ITradingCallbacks01,
            ITradingCallbacks01.LastUpdated memory,
            ITradingCallbacks01.SimplifiedTradeId memory
        )
    {
        ITradingCallbacks01 callbacks = ITradingCallbacks01(_callbacks);
        ITradingCallbacks01.LastUpdated memory l = callbacks.tradeLastUpdated(trader, pairIndex, index, _type);

        return (callbacks, l, ITradingCallbacks01.SimplifiedTradeId(trader, pairIndex, index, _type));
    }
}