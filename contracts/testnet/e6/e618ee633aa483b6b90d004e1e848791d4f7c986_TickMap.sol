// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../../structs/PoolsharkStructs.sol';

interface ITwapSource {
    function initialize(
        PoolsharkStructs.CoverImmutables memory constants
    ) external returns (
        uint8 initializable,
        int24 startingTick
    );

    function calculateAverageTick(
        PoolsharkStructs.CoverImmutables memory constants,
        int24 latestTick
    ) external view returns (
        int24 averageTick
    );

    function calculateAverageTicks(
        PoolsharkStructs.CoverImmutables memory constants
    ) external view returns (
        int24[4] memory averageTicks
    );

    function syncLatestTick(
        PoolsharkStructs.CoverImmutables memory constants,
        address coverPool
    ) external view returns (
        int24 latestTick,
        bool twapReady
    );

    function getPool(
        address tokenA,
        address tokenB,
        uint16 feeTier
    ) external view returns (
        address pool
    );

    function feeTierTickSpacing(
        uint16 feeTier
    ) external view returns (
        int24 tickSpacing
    );

    function factory()
        external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import './PoolsharkStructs.sol';
import '../modules/sources/ITwapSource.sol';

interface CoverPoolStructs is PoolsharkStructs {
    struct GlobalState {
        ProtocolFees protocolFees;
        uint160  latestPrice;      /// @dev price of latestTick
        uint128  liquidityGlobal;
        uint32   lastTime;         /// @dev last block checked
        uint32   auctionStart;     /// @dev last block price reference was updated
        uint32   accumEpoch;       /// @dev number of times this pool has been synced
        uint32   positionIdNext;
        int24    latestTick;       /// @dev latest updated inputPool price tick
        uint16   syncFee;
        uint16   fillFee;
        uint8    unlocked;
    }

    struct PoolState {
        uint160 price; /// @dev Starting price current
        uint128 liquidity; /// @dev Liquidity currently active
        uint128 amountInDelta; /// @dev Delta for the current tick auction
        uint128 amountInDeltaMaxClaimed;  /// @dev - needed when users claim and don't burn; should be cleared when users burn liquidity
        uint128 amountOutDeltaMaxClaimed; /// @dev - needed when users claim and don't burn; should be cleared when users burn liquidity
    }

    struct TickMap {
        uint256 blocks;                     /// @dev - sets of words
        mapping(uint256 => uint256) words;  /// @dev - sets to words
        mapping(uint256 => uint256) ticks;  /// @dev - words to ticks
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs0; /// @dev - ticks to pool0 epochs
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs1; /// @dev - ticks to pool1 epochs
    }

    struct Tick {
        Deltas deltas0;
        Deltas deltas1;                    
        int128 liquidityDelta;
        uint128 amountInDeltaMaxMinus;
        uint128 amountOutDeltaMaxMinus;
        uint128 amountInDeltaMaxStashed;
        uint128 amountOutDeltaMaxStashed;
        bool pool0Stash;
    }

    struct Deltas {
        uint128 amountInDelta;     /// @dev - amount filled
        uint128 amountOutDelta;    /// @dev - amount unfilled
        uint128 amountInDeltaMax;  /// @dev - max filled 
        uint128 amountOutDeltaMax; /// @dev - max unfilled
    }

    struct CoverPosition {
        uint160 claimPriceLast;    /// @dev - highest price claimed at
        uint128 liquidity;         /// @dev - expected amount to be used not actual
        uint128 amountIn;          /// @dev - token amount already claimed; balance
        uint128 amountOut;         /// @dev - necessary for non-custodial positions
        uint32  accumEpochLast;    /// @dev - last epoch this position was updated at
        int24 lower;
        int24 upper;
    }

    struct VolatilityTier {
        uint128 minAmountPerAuction; // based on 18 decimals and then converted based on token decimals
        uint16  auctionLength;
        uint16  sampleInterval; // average block time where 1e3 is 1 second
        uint16  syncFee;
        uint16  fillFee;
        int16   minPositionWidth;
        bool    minAmountLowerPriced;
    }

    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }

    struct SyncFees {
        uint128 token0;
        uint128 token1;
    }

    struct CollectParams {
        SyncFees syncFees;
        address to;
        uint32 positionId;
        int24 lower;
        int24 claim;
        int24 upper;
        bool zeroForOne;
    }

    struct SizeParams {
        uint256 priceLower;
        uint256 priceUpper;
        uint128 liquidityAmount;
        bool zeroForOne;
        int24 latestTick;
        uint24 auctionCount;
    }

    struct AddParams {
        address to;
        uint128 amount;
        uint128 amountIn;
        uint32 positionId;
        int24 lower;
        int24 upper;
        bool zeroForOne;
    }

    struct RemoveParams {
        address owner;
        address to;
        uint128 amount;
        uint32 positionId;
        int24 lower;
        int24 upper;
        bool zeroForOne;
    }

    struct UpdateParams {
        address owner;
        address to;
        uint128 amount;
        uint32 positionId;
        int24 lower;
        int24 upper;
        int24 claim;
        bool zeroForOne;
    }

    struct MintCache {
        GlobalState state;
        CoverPosition position;
        CoverImmutables constants;
        SyncFees syncFees;
        PoolState pool0;
        PoolState pool1;
        uint256 liquidityMinted;
    }

    struct BurnCache {
        GlobalState state;
        CoverPosition position;
        CoverImmutables constants;
        SyncFees syncFees;
        PoolState pool0;
        PoolState pool1;
    }

    struct SwapCache {
        GlobalState state;
        SyncFees syncFees;
        CoverImmutables constants;
        PoolState pool0;
        PoolState pool1;
        uint256 price;
        uint256 liquidity;
        uint256 amountLeft;
        uint256 input;
        uint256 output;
        uint256 amountBoosted;
        uint256 auctionDepth;
        uint256 auctionBoost;
        uint256 amountInDelta;
        int256 amount0Delta;
        int256 amount1Delta;
        bool exactIn;
    }

    struct CoverPositionCache {
        CoverPosition position;
        Deltas deltas;
        uint160 priceLower;
        uint160 priceUpper;
        uint256 priceAverage;
        uint256 liquidityMinted;
        int24 requiredStart;
        uint24 auctionCount;
        bool denomTokenIn;
    }

    struct UpdatePositionCache {
        Deltas deltas;
        Deltas finalDeltas;
        PoolState pool;
        uint256 amountInFilledMax;    // considers the range covered by each update
        uint256 amountOutUnfilledMax; // considers the range covered by each update
        Tick claimTick;
        Tick finalTick;
        CoverPosition position;
        uint160 priceLower;
        uint160 priceClaim;
        uint160 priceUpper;
        uint160 priceSpread;
        bool earlyReturn;
        bool removeLower;
        bool removeUpper;
    }

    struct AccumulateCache {
        Deltas deltas0;
        Deltas deltas1;
        SyncFees syncFees;
        int24 newLatestTick;
        int24 nextTickToCross0;
        int24 nextTickToCross1;
        int24 nextTickToAccum0;
        int24 nextTickToAccum1;
        int24 stopTick0;
        int24 stopTick1;
    }

    struct AccumulateParams {
        Deltas deltas;
        Tick crossTick;
        Tick accumTick;
        bool updateAccumDeltas;
        bool isPool0;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../modules/sources/ITwapSource.sol';

interface PoolsharkStructs {
    struct LimitImmutables {
        address owner;
        address poolImpl;
        address factory;
        PriceBounds bounds;
        address token0;
        address token1;
        address poolToken;
        uint32 genesisTime;
        int16 tickSpacing;
        uint16 swapFee;
    }

    struct CoverImmutables {
        ITwapSource source;
        PriceBounds bounds;
        address owner;
        address token0;
        address token1;
        address poolImpl;
        address poolToken;
        address inputPool;
        uint128 minAmountPerAuction;
        uint32 genesisTime;
        int16  minPositionWidth;
        int16  tickSpread;
        uint16 twapLength;
        uint16 auctionLength;
        uint16 sampleInterval;
        uint8 token0Decimals;
        uint8 token1Decimals;
        bool minAmountLowerPriced;
    }

    struct PriceBounds {
        uint160 min;
        uint160 max;
    }

    struct QuoteResults {
        address pool;
        int256 amountIn;
        int256 amountOut;
        uint160 priceAfter;
    }

    struct LimitPoolParams {
        address tokenIn;
        address tokenOut;
        uint160 startPrice;
        uint16  swapFee;
        uint8   poolTypeId;
    }

    struct MintLimitParams {
        address to;
        uint128 amount;
        uint96 mintPercent;
        uint32 positionId;
        int24 lower;
        int24 upper;
        bool zeroForOne;
        bytes callbackData;
    }

    struct BurnLimitParams {
        address to;
        uint128 burnPercent;
        uint32 positionId;
        int24 claim;
        bool zeroForOne;
    }

    struct MintRangeParams {
        address to;
        int24 lower;
        int24 upper;
        uint32 positionId;
        uint128 amount0;
        uint128 amount1;
        bytes callbackData;
    }

    struct BurnRangeParams {
        address to;
        uint32 positionId;
        uint128 burnPercent;
    }

    struct SnapshotLimitParams {
        address owner;
        uint128 burnPercent;
        uint32 positionId;
        int24 claim;
        bool zeroForOne;
    }

    struct FeesParams {
        uint16 protocolSwapFee0;
        uint16 protocolSwapFee1;
        uint16 protocolFillFee0;
        uint16 protocolFillFee1;
        uint8 setFeesFlags;
    }

    struct LimitPoolState {
        uint160 price; /// @dev Starting price current
        uint128 liquidity; /// @dev Liquidity currently active
        uint128 protocolFees;
        uint16 protocolFillFee;
        int24 tickAtPrice;
    }

    struct RangePoolState {
        SampleState  samples;
        uint200 feeGrowthGlobal0;
        uint200 feeGrowthGlobal1;
        uint160 secondsPerLiquidityAccum;
        uint160 price;               /// @dev Starting price current
        uint128 liquidity;           /// @dev Liquidity currently active
        int56   tickSecondsAccum;
        int24   tickAtPrice;
        uint16 protocolSwapFee0;
        uint16 protocolSwapFee1;
    }

    struct SampleState {
        uint16  index;
        uint16  count;
        uint16  countMax;
    }

    /**
     * @custom:struct MintCoverParams
     */
    struct MintCoverParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the minted position
         */
        address to;

        /**
         * @custom:field amount
         * @notice Token amount to be deposited into the minted position
         */
        uint128 amount;

        /**
         * @custom:field positionId
         * @notice 0 if creating a new position; id of previous if adding liquidity
         */
        uint32 positionId;

        /**
         * @custom:field lower
         * @notice The lower price tick for the position range
         */
        int24 lower;

        /**
         * @custom:field upper
         * @notice The upper price tick for the position range
         */
        int24 upper;

        /**
         * @custom:field zeroForOne
         * @notice True if depositing token0, the first token address in lexographical order
         * @notice False if depositing token1, the second token address in lexographical order 
         */
        bool zeroForOne;

        /**
         * @custom:field callbackData
         * @notice callback data which gets passed back to msg.sender at the end of a `mint` call
         */
        bytes callbackData;
    }

    /**
     * @custom:struct BurnCoverParams
     */
    struct BurnCoverParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the collected position amounts
         */
        address to;

        /**
         * @custom:field burnPercent
         * @notice Percent of the remaining liquidity to be removed
         * @notice 1e38 represents 100%
         * @notice 5e37 represents 50%
         * @notice 1e37 represents 10%
         */
        uint128 burnPercent;

        /**
         * @custom:field positionId
         * @notice 0 if creating a new position; id of previous if adding liquidity
         */
        uint32 positionId;

        /**
         * @custom:field claim
         * @notice The most recent tick crossed in this range
         * @notice if `zeroForOne` is true, claim tick progresses from upper => lower
         * @notice if `zeroForOne` is false, claim tick progresses from lower => upper
         */
        int24 claim;

        /**
         * @custom:field zeroForOne
         * @notice True if deposited token0, the first token address in lexographical order
         * @notice False if deposited token1, the second token address in lexographical order 
         */
        bool zeroForOne;

        /**
         * @custom:field sync
         * @notice True will sync the pool latestTick
         * @notice False will skip syncing latestTick 
         */
        bool sync;
    }

    /**
     * @custom:struct SnapshotCoverParams
     */
    struct SnapshotCoverParams {
        /**
         * @custom:field to
         * @notice Address of the position owner
         */
        address owner;

        /**
         * @custom:field positionId
         * @notice id of position
         */
        uint32 positionId;

        /**
         * @custom:field burnPercent
         * @notice Percent of the remaining liquidity to be removed
         * @notice 1e38 represents 100%
         * @notice 5e37 represents 50%
         * @notice 1e37 represents 10%
         */
        uint128 burnPercent;

        /**
         * @custom:field claim
         * @notice The most recent tick crossed in this range
         * @notice if `zeroForOne` is true, claim tick progresses from upper => lower
         * @notice if `zeroForOne` is false, claim tick progresses from lower => upper
         */
        int24 claim;

        /**
         * @custom:field zeroForOne
         * @notice True if deposited token0, the first token address in lexographical order
         * @notice False if deposited token1, the second token address in lexographical order 
         */
        bool zeroForOne;
    }

    /**
     * @custom:struct QuoteParams
     */
    struct QuoteParams {
        /**
         * @custom:field priceLimit
         * @dev The Q64.96 square root price at which to stop swapping.
         */
        uint160 priceLimit;

        /**
         * @custom:field amount
         * @dev The exact input amount if exactIn = true
         * @dev The exact output amount if exactIn = false.
         */
        uint128 amount;

        /**
         * @custom:field zeroForOne
         * @notice True if amount is an input amount.
         * @notice False if amount is an output amount. 
         */
        bool exactIn;

        /**
         * @custom:field zeroForOne
         * @notice True if swapping token0 for token1.
         * @notice False if swapping in token1 for token0. 
         */
        bool zeroForOne;
    }

    /**
     * @custom:struct SwapParams
     */
    struct SwapParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the swap output
         */
        address to;

        /**
         * @custom:field priceLimit
         * @dev The Q64.96 square root price at which to stop swapping.
         */
        uint160 priceLimit;

        /**
         * @custom:field amount
         * @dev The exact input amount if exactIn = true
         * @dev The exact output amount if exactIn = false.
         */
        uint128 amount;

        /**
         * @custom:field zeroForOne
         * @notice True if amount is an input amount.
         * @notice False if amount is an output amount. 
         */
        bool exactIn;

        /**
         * @custom:field zeroForOne
         * @notice True if swapping token0 for token1.
         * @notice False if swapping in token1 for token0. 
         */
        bool zeroForOne;
        
        /**
         * @custom:field callbackData
         * @notice Data to be passed through to the swap callback. 
         */
         bytes callbackData;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import './OverflowMath.sol';
import '../../interfaces/structs/CoverPoolStructs.sol';

/// @notice Math library that facilitates ranged liquidity calculations.
library ConstantProduct {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    struct PriceBounds {
        uint160 min;
        uint160 max;
    }

    /////////////////////////////////////////////////////////////
    ///////////////////////// DYDX MATH /////////////////////////
    /////////////////////////////////////////////////////////////

    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dy) {
        unchecked {
            if (liquidity == 0) return 0;
            if (roundUp) {
                dy = OverflowMath.mulDivRoundingUp(liquidity, priceUpper - priceLower, Q96);
            } else {
                dy = OverflowMath.mulDiv(liquidity, priceUpper - priceLower, Q96);
            }
        }
    }

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        unchecked {
            if (liquidity == 0) return 0;
            if (roundUp) {
                dx = OverflowMath.divRoundingUp(
                        OverflowMath.mulDivRoundingUp(
                            liquidity << 96, 
                            priceUpper - priceLower,
                            priceUpper
                        ),
                        priceLower
                );
            } else {
                dx = OverflowMath.mulDiv(
                        liquidity << 96,
                        priceUpper - priceLower,
                        priceUpper
                ) / priceLower;
            }
        }
    }

    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) internal pure returns (uint256 liquidity) {
        unchecked {
            if (priceUpper <= currentPrice) {
                liquidity = OverflowMath.mulDiv(dy, Q96, priceUpper - priceLower);
            } else if (currentPrice <= priceLower) {
                liquidity = OverflowMath.mulDiv(
                    dx,
                    OverflowMath.mulDiv(priceLower, priceUpper, Q96),
                    priceUpper - priceLower
                );
            } else {
                uint256 liquidity0 = OverflowMath.mulDiv(
                    dx,
                    OverflowMath.mulDiv(priceUpper, currentPrice, Q96),
                    priceUpper - currentPrice
                );
                uint256 liquidity1 = OverflowMath.mulDiv(dy, Q96, currentPrice - priceLower);
                liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
            }
        }
    }

    function getAmountsForLiquidity(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 liquidityAmount,
        bool roundUp
    ) internal pure returns (uint128 token0amount, uint128 token1amount) {
        if (priceUpper <= currentPrice) {
            token1amount = uint128(getDy(liquidityAmount, priceLower, priceUpper, roundUp));
        } else if (currentPrice <= priceLower) {
            token0amount = uint128(getDx(liquidityAmount, priceLower, priceUpper, roundUp));
        } else {
            token0amount = uint128(getDx(liquidityAmount, currentPrice, priceUpper, roundUp));
            token1amount = uint128(getDy(liquidityAmount, priceLower, currentPrice, roundUp));
        }
        if (token0amount > uint128(type(int128).max)) require(false, 'AmountsOutOfBounds()');
        if (token1amount > uint128(type(int128).max)) require(false, 'AmountsOutOfBounds()');
    }

    function getNewPrice(
        uint256 price,
        uint256 liquidity,
        uint256 amount,
        bool zeroForOne,
        bool exactIn
    ) internal pure returns (
        uint256 newPrice
    ) {
        if (exactIn) {
            if (zeroForOne) {
                uint256 liquidityPadded = liquidity << 96;
                newPrice = OverflowMath.mulDivRoundingUp(
                        liquidityPadded,
                        price,
                        liquidityPadded + price * amount
                    );
            } else {
                newPrice = price + (amount << 96) / liquidity;
            }
        } else {
            if (zeroForOne) {
                newPrice = price - 
                        OverflowMath.divRoundingUp(amount << 96, liquidity);
            } else {
                uint256 liquidityPadded = uint256(liquidity) << 96;
                newPrice = OverflowMath.mulDivRoundingUp(
                        liquidityPadded, 
                        price,
                        liquidityPadded - uint256(price) * amount
                );
            }
        }
    }

    function getPrice(
        uint256 sqrtPrice
    ) internal pure returns (uint256 price) {
        if (sqrtPrice >= 2 ** 48)
            price = OverflowMath.mulDiv(sqrtPrice, sqrtPrice, 2 ** 96);
        else
            price = sqrtPrice;
    }

    /////////////////////////////////////////////////////////////
    ///////////////////////// TICK MATH /////////////////////////
    /////////////////////////////////////////////////////////////

    int24 internal constant MIN_TICK = -887272;   /// @dev - tick for price of 2^-128
    int24 internal constant MAX_TICK = -MIN_TICK; /// @dev - tick for price of 2^128

    function minTick(
        int16 tickSpacing
    ) internal pure returns (
        int24 tick
    ) {
        return MIN_TICK / tickSpacing * tickSpacing;
    }

    function maxTick(
        int16 tickSpacing
    ) internal pure returns (
        int24 tick
    ) {
        return MAX_TICK / tickSpacing * tickSpacing;
    }

    function priceBounds(
        int16 tickSpacing
    ) internal pure returns (
        uint160,
        uint160
    ) {
        return (minPrice(tickSpacing), maxPrice(tickSpacing));
    }

    function minPrice(
        int16 tickSpacing
    ) internal pure returns (
        uint160 price
    ) {
        PoolsharkStructs.CoverImmutables  memory constants;
        constants.tickSpread = tickSpacing;
        return getPriceAtTick(minTick(tickSpacing), constants);
    }

    function maxPrice(
        int16 tickSpacing
    ) internal pure returns (
        uint160 price
    ) {
        PoolsharkStructs.CoverImmutables  memory constants;
        constants.tickSpread = tickSpacing;
        return getPriceAtTick(maxTick(tickSpacing), constants);
    }

    function checkTicks(
        int24 lower,
        int24 upper,
        int16 tickSpacing
    ) internal pure
    {
        if (lower < minTick(tickSpacing)) require (false, 'LowerTickOutOfBounds()');
        if (upper > maxTick(tickSpacing)) require (false, 'UpperTickOutOfBounds()');
        if (lower % tickSpacing != 0) require (false, 'LowerTickOutsideTickSpacing()');
        if (upper % tickSpacing != 0) require (false, 'UpperTickOutsideTickSpacing()');
        if (lower >= upper) require (false, 'LowerUpperTickOrderInvalid()');
    }

    function checkPrice(
        uint160 price,
        PriceBounds memory bounds
    ) internal pure {
        if (price < bounds.min || price >= bounds.max) require (false, 'PriceOutOfBounds()');
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96.
    /// @dev Throws if |tick| > max tick.
    /// @param tick The input tick for the above formula.
    /// @return price Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick.
    function getPriceAtTick(
        int24 tick,
        PoolsharkStructs.CoverImmutables memory constants
    ) internal pure returns (
        uint160 price
    ) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        if (absTick > uint256(uint24(maxTick(constants.tickSpread)))) require (false, 'TickOutOfBounds()');
        unchecked {
            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;
            // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // We then downcast because we know the result always fits within 160 bits due to our tick input constraint.
            // We round up in the division so getTickAtPrice of the output price is always consistent.
            price = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio.
    /// @param price The sqrt ratio for which to compute the tick as a Q64.96.
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio.
    function getTickAtPrice(
        uint160 price,
        PoolsharkStructs.CoverImmutables  memory constants
    ) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (price < constants.bounds.min || price > constants.bounds.max)
            require (false, 'PriceOutOfBounds()');
        uint256 ratio = uint256(price) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getPriceAtTick(tickHi, constants) <= price
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library OverflowMath {

    // @dev no underflow or overflow checks
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }

    /// @notice Calculates floor(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b.
            // Compute the product mod 2**256 and mod 2**256 - 1,
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product.
            uint256 prod1; // Most significant 256 bits of the product.
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }
            // Make sure the result is less than 2**256 -
            // also prevents denominator == 0.
            require(denominator > prod1);
            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////
            // Make division exact by subtracting the remainder from [prod1 prod0] -
            // compute remainder using mulmod.
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number.
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }
            // Factor powers of two out of denominator -
            // compute largest power of two divisor of denominator
            // (always >= 1).
            uint256 twos = uint256(-int256(denominator)) & denominator;
            // Divide denominator by power of two.
            assembly {
                denominator := div(denominator, twos)
            }
            // Divide [prod1 prod0] by the factors of two.
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos -
            // if twos is zero, then it becomes one.
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;
            // Invert denominator mod 2**256 -
            // now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // for four bits. That is, denominator * inv = 1 mod 2**4.
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // Inverse mod 2**8.
            inv *= 2 - denominator * inv; // Inverse mod 2**16.
            inv *= 2 - denominator * inv; // Inverse mod 2**32.
            inv *= 2 - denominator * inv; // Inverse mod 2**64.
            inv *= 2 - denominator * inv; // Inverse mod 2**128.
            inv *= 2 - denominator * inv; // Inverse mod 2**256.
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

    /// @notice Calculates ceil(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) != 0) {
                if (result >= type(uint256).max) require (false, 'MaxUintExceeded()');
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '../interfaces/structs/CoverPoolStructs.sol';
import './math/ConstantProduct.sol';

library TickMap {
    function set(
        int24 tick,
        CoverPoolStructs.TickMap storage tickMap,
        PoolsharkStructs.CoverImmutables memory constants
    ) external returns (
        bool exists
    )    
    {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        ) = getIndices(tick, constants);

        // check if bit is already set
        uint256 word = tickMap.ticks[wordIndex] | 1 << (tickIndex & 0xFF);
        if (word == tickMap.ticks[wordIndex]) {
            return true;
        }

        tickMap.ticks[wordIndex]     = word; 
        tickMap.words[blockIndex]   |= 1 << (wordIndex & 0xFF); // same as modulus 255
        tickMap.blocks              |= 1 << blockIndex;
        return false;
    }

    function unset(
        int24 tick,
        CoverPoolStructs.TickMap storage tickMap,
        PoolsharkStructs.CoverImmutables memory constants
    ) external {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        ) = getIndices(tick, constants);

        tickMap.ticks[wordIndex] &= ~(1 << (tickIndex & 0xFF));
        if (tickMap.ticks[wordIndex] == 0) {
            tickMap.words[blockIndex] &= ~(1 << (wordIndex & 0xFF));
            if (tickMap.words[blockIndex] == 0) {
                tickMap.blocks &= ~(1 << blockIndex);
            }
        }
    }

    function previous(
        int24 tick,
        CoverPoolStructs.TickMap storage tickMap,
        PoolsharkStructs.CoverImmutables memory constants
    ) external view returns (
        int24 previousTick
    ) {
        unchecked {
            (
              uint256 tickIndex,
              uint256 wordIndex,
              uint256 blockIndex
            ) = getIndices(tick, constants);

            uint256 word = tickMap.ticks[wordIndex] & ((1 << (tickIndex & 0xFF)) - 1);
            if (word == 0) {
                uint256 block_ = tickMap.words[blockIndex] & ((1 << (wordIndex & 0xFF)) - 1);
                if (block_ == 0) {
                    uint256 blockMap = tickMap.blocks & ((1 << blockIndex) - 1);
                    if (blockMap == 0) return tick;
                    blockIndex = _msb(blockMap);
                    block_ = tickMap.words[blockIndex];
                }
                wordIndex = (blockIndex << 8) | _msb(block_);
                word = tickMap.ticks[wordIndex];
            }
            previousTick = _tick((wordIndex << 8) | _msb(word), constants);
        }
    }

    function next(
        int24 tick,
        CoverPoolStructs.TickMap storage tickMap,
        PoolsharkStructs.CoverImmutables memory constants
    ) external view returns (
        int24 nextTick
    ) {
        unchecked {
            (
              uint256 tickIndex,
              uint256 wordIndex,
              uint256 blockIndex
            ) = getIndices(tick, constants);
            uint256 word;
            if ((tickIndex & 0xFF) != 255) {
                word = tickMap.ticks[wordIndex] & ~((1 << ((tickIndex & 0xFF) + 1)) - 1);
            }
            if (word == 0) {
                uint256 block_;
                if ((blockIndex & 0xFF) != 255) {
                    block_ = tickMap.words[blockIndex] & ~((1 << ((wordIndex & 0xFF) + 1)) - 1);
                }
                if (block_ == 0) {
                    uint256 blockMap = tickMap.blocks & ~((1 << blockIndex + 1) - 1);
                    if (blockMap == 0) return tick;
                    blockIndex = _lsb(blockMap);
                    block_ = tickMap.words[blockIndex];
                }
                wordIndex = (blockIndex << 8) | _lsb(block_);
                word = tickMap.ticks[wordIndex];
            }
            nextTick = _tick((wordIndex << 8) | _lsb(word), constants);
        }
    }

    function getIndices(
        int24 tick,
        PoolsharkStructs.CoverImmutables memory constants
    ) public pure returns (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        )
    {
        unchecked {
            if (tick > ConstantProduct.maxTick(constants.tickSpread)) require (false, 'TickIndexOverflow()');
            if (tick < ConstantProduct.minTick(constants.tickSpread)) require (false, 'TickIndexUnderflow()');
            if (tick % constants.tickSpread != 0) require (false, 'TickIndexInvalid()');
            tickIndex = uint256(int256((tick - ConstantProduct.minTick(constants.tickSpread))) / constants.tickSpread);
            wordIndex = tickIndex >> 8;   // 2^8 ticks per word
            blockIndex = tickIndex >> 16; // 2^8 words per block
            if (blockIndex > 255) require (false, 'BlockIndexOverflow()');
        }
    }

    function _tick (
        uint256 tickIndex,
        PoolsharkStructs.CoverImmutables memory constants
    ) internal pure returns (
        int24 tick
    ) {
        unchecked {
            if (tickIndex > uint24(ConstantProduct.maxTick(constants.tickSpread) * 2)) require (false, 'TickIndexOverflow()');
            tick = int24(int256(tickIndex) * int256(constants.tickSpread) + ConstantProduct.minTick(constants.tickSpread));
        }
    }

    function _msb(
        uint256 x
    ) internal pure returns (
        uint8 r
    ) {
        unchecked {
            assert(x > 0);
            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                r += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                r += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                r += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                r += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                r += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                r += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                r += 2;
            }
            if (x >= 0x2) r += 1;
        }
    }

    function _lsb(
        uint256 x
    ) internal pure returns (
        uint8 r
    ) {
        unchecked {
            assert(x > 0); // if x is 0 return 0
            r = 255;
            if (x & type(uint128).max > 0) {
                r -= 128;
            } else {
                x >>= 128;
            }
            if (x & type(uint64).max > 0) {
                r -= 64;
            } else {
                x >>= 64;
            }
            if (x & type(uint32).max > 0) {
                r -= 32;
            } else {
                x >>= 32;
            }
            if (x & type(uint16).max > 0) {
                r -= 16;
            } else {
                x >>= 16;
            }
            if (x & type(uint8).max > 0) {
                r -= 8;
            } else {
                x >>= 8;
            }
            if (x & 0xf > 0) {
                r -= 4;
            } else {
                x >>= 4;
            }
            if (x & 0x3 > 0) {
                r -= 2;
            } else {
                x >>= 2;
            }
            if (x & 0x1 > 0) r -= 1;
        }
    }
    
}