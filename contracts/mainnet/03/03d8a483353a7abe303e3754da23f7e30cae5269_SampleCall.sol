// SPDX-License-Identifier: SSPL-1.0
pragma solidity ^0.8.18;

import '../structs/PoolsharkStructs.sol';

interface ITwapSource {
    function initialize(PoolsharkStructs.CoverImmutables memory constants)
        external
        returns (uint8 initializable, int24 startingTick);

    function calculateAverageTick(
        PoolsharkStructs.CoverImmutables memory constants,
        int24 latestTick
    ) external view returns (int24 averageTick);

    function getPool(
        address tokenA,
        address tokenB,
        uint16 feeTier
    ) external view returns (address pool);

    function feeTierTickSpacing(uint16 feeTier)
        external
        view
        returns (int24 tickSpacing);

    function factory() external view returns (address);
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

import '../structs/RangePoolStructs.sol';
import './IRangePoolManager.sol';

interface IRangePool is RangePoolStructs {
    function mintRange(MintRangeParams memory mintParams)
        external
        returns (int256, int256);

    function burnRange(BurnRangeParams memory burnParams)
        external
        returns (int256, int256);

    function swap(SwapParams memory params)
        external
        returns (int256 amount0, int256 amount1);

    function quote(QuoteParams memory params)
        external
        view
        returns (
            uint256 inAmount,
            uint256 outAmount,
            uint160 priceAfter
        );

    function snapshotRange(uint32 positionId)
        external
        view
        returns (
            int56 tickSecondsAccum,
            uint160 secondsPerLiquidityAccum,
            uint128 feesOwed0,
            uint128 feesOwed1
        );

    function sample(uint32[] memory secondsAgo)
        external
        view
        returns (
            int56[] memory tickSecondsAccum,
            uint160[] memory secondsPerLiquidityAccum,
            uint160 averagePrice,
            uint128 averageLiquidity,
            int24 averageTick
        );

    function positions(uint256 positionId)
        external
        view
        returns (
            uint256 feeGrowthInside0Last,
            uint256 feeGrowthInside1Last,
            uint128 liquidity,
            int24 lower,
            int24 upper
        );

    function increaseSampleCount(uint16 newSampleCountMax) external;

    function ticks(int24)
        external
        view
        returns (RangeTick memory, LimitTick memory);

    function samples(uint256)
        external
        view
        returns (
            uint32,
            int56,
            uint160
        );
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

import '../structs/RangePoolStructs.sol';

interface IRangePoolManager {
    function owner() external view returns (address);

    function feeTo() external view returns (address);

    function protocolFees(address pool) external view returns (uint16);

    function feeTiers(uint16 swapFee) external view returns (int24);
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

import './PoolsharkStructs.sol';

interface LimitPoolStructs is PoolsharkStructs {
    struct LimitPosition {
        uint128 liquidity; // expected amount to be used not actual
        uint32 epochLast; // epoch when this position was created at
        int24 lower; // lower price tick of position range
        int24 upper; // upper price tick of position range
        bool crossedInto; // whether the position was crossed into already
    }

    struct MintLimitCache {
        GlobalState state;
        LimitPosition position;
        LimitImmutables constants;
        LimitPoolState pool;
        SwapCache swapCache;
        uint256 liquidityMinted;
        uint256 mintSize;
        uint256 priceLimit;
        int256 amountIn;
        uint256 amountOut;
        uint256 priceLower;
        uint256 priceUpper;
        int24 tickLimit;
    }

    struct BurnLimitCache {
        GlobalState state;
        LimitPoolState pool;
        LimitTick claimTick;
        LimitPosition position;
        PoolsharkStructs.LimitImmutables constants;
        uint160 priceLower;
        uint160 priceClaim;
        uint160 priceUpper;
        uint128 liquidityBurned;
        uint128 amountIn;
        uint128 amountOut;
        int24 claim;
        bool removeLower;
        bool removeUpper;
        bool search;
    }

    struct InsertSingleLocals {
        int24 previousFullTick;
        int24 nextFullTick;
        uint256 priceNext;
        uint256 pricePrevious;
        uint256 amountInExact;
        uint256 amountOutExact;
        uint256 amountToCross;
    }

    struct GetDeltasLocals {
        int24 previousFullTick;
        uint256 pricePrevious;
        uint256 priceNext;
    }

    struct SearchLocals {
        int24[] ticksFound;
        int24 searchTick;
        int24 searchTickAhead;
        uint16 searchIdx;
        uint16 startIdx;
        uint16 endIdx;
        uint16 ticksIncluded;
        uint32 claimTickEpoch;
        uint32 claimTickAheadEpoch;
    }

    struct TickMapLocals {
        uint256 word;
        uint256 tickIndex;
        uint256 wordIndex;
        uint256 blockIndex;
    }
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

import '../cover/ITwapSource.sol';

interface PoolsharkStructs {
    /**
     * @custom:struct LimitPoolParams
     */
    struct LimitPoolParams {
        /**
         * @custom:field tokenIn
         * @notice Address for the first token in the pair
         */
        address tokenIn;
        /**
         * @custom:field tokenOut
         * @notice Address for the second token in the pair
         */
        address tokenOut;
        /**
         * @custom:field startPrice
         * @notice Q64.96 formatted sqrt price to start the pool at
         */
        uint160 startPrice;
        /**
         * @custom:field swapFee
         * @notice The base swap fee for the pool; 1000 = 0.1% fee
         */
        uint16 swapFee;
        /**
         * @custom:field poolTypeId
         * @notice The pool type id for which to clone the implementation for
         */
        uint16 poolTypeId;
    }

    /**
     * @custom:struct MintRangeParams
     */
    struct MintRangeParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the minted position
         */
        address to;
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
         * @custom:field positionId
         * @notice 0 if creating a new position; id of previous if adding liquidity
         */
        uint32 positionId;
        /**
         * @custom:field amount0
         * @notice token0 amount to be deposited into the minted position
         */
        uint128 amount0;
        /**
         * @custom:field amount1
         * @notice token1 amount to be deposited into the minted position
         */
        uint128 amount1;
        /**
         * @custom:field callbackData
         * @notice callback data which gets passed back to msg.sender at the end of a `mint` call
         */
        bytes callbackData;
    }

    struct BurnRangeParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the burned liquidity
         */
        address to;
        /**
         * @custom:field positionId
         * @notice id of previous position minted
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
    }

    /**
     * @custom:struct MintLimitParams
     */
    struct MintLimitParams {
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
         * @custom:field mintPercent
         * @notice The percent of `amount` below which a LimitPosition will not be minted
         * @notice 1e26 = 1%
         * @notice 5e25 = 0.5%
         */
        uint96 mintPercent;
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
     * @custom:struct BurnLimitParams
     */
    struct BurnLimitParams {
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
         * @notice if `zeroForOne` is true, claim tick progresses from lower => upper
         * @notice if `zeroForOne` is false, claim tick progresses from upper => lower
         */
        int24 claim;
        /**
         * @custom:field zeroForOne
         * @notice True if deposited token0, the first token address in lexographical order
         * @notice False if deposited token1, the second token address in lexographical order
         */
        bool zeroForOne;
    }

    struct SwapParams {
        /**
         * @custom:field to
         * @notice Address for the receiver of the swap token output
         */
        address to;
        /**
         * @custom:field priceLimit
         * @notice The Q64.96 formatted sqrt price to stop swapping at
         * @notice zeroForOne (i.e. token0 => token1 swap) moves price lower
         * @notice !zeroForOne (i.e. token1 => token0 swap) moves price higher
         */
        uint160 priceLimit;
        /**
         * @custom:field amount
         * @notice The maximum tokenIn to be spent (exactIn)
         * @notice OR tokenOut amount to be received (!exactIn)
         */
        uint128 amount;
        /**
         * @custom:field exactIn
         * @notice True if `amount` is in tokenIn; False if `amount` is in tokenOut
         */
        bool exactIn;
        /**
         * @custom:field zeroForOne
         * @notice True if swapping token0 => token1
         * @notice False if swapping token1 => token0
         */
        bool zeroForOne;
        /**
         * @custom:field callbackData
         * @notice callback data which gets passed back to msg.sender at the end of a `mint` call
         */
        bytes callbackData;
    }

    struct QuoteParams {
        /**
         * @custom:field priceLimit
         * @notice The Q64.96 formatted sqrt price to stop swapping at
         * @notice zeroForOne (i.e. token0 => token1 swap) moves price lower
         * @notice !zeroForOne (i.e. token1 => token0 swap) moves price higher
         */
        uint160 priceLimit;
        /**
         * @custom:field amount
         * @notice The maximum tokenIn to be spent (exactIn)
         * @notice OR tokenOut amount to be received (!exactIn)
         */
        uint128 amount;
        /**
         * @custom:field exactIn
         * @notice True if `amount` is in tokenIn; False if `amount` is in tokenOut
         */
        bool exactIn;
        /**
         * @custom:field zeroForOne
         * @notice True if swapping token0 => token1
         * @notice False if swapping token1 => token0
         */
        bool zeroForOne;
    }

    struct SnapshotLimitParams {
        /**
         * @custom:field owner
         * @notice The owner address of the Limit Position
         */
        address owner;
        /**
         * @custom:field burnPercent
         * @notice The % of liquidity to burn
         * @notice 1e38 = 100%
         */
        uint128 burnPercent;
        /**
         * @custom:field positionId
         * @notice The position id for the LimitPosition
         */
        uint32 positionId;
        /**
         * @custom:field claim
         * @notice The most recent tick crossed in this range
         * @notice if `zeroForOne` is true, claim tick progresses from lower => upper
         * @notice if `zeroForOne` is false, claim tick progresses from upper => lower
         */
        int24 claim;
        /**
         * @custom:field zeroForOne
         * @notice True if swapping token0 => token1
         * @notice False if swapping token1 => token0
         */
        bool zeroForOne;
    }

    struct FeesParams {
        /**
         * @custom:field protocolSwapFee0
         * @notice The protocol fee taken on all token0 fees
         * @notice 1e4 = 100%
         */
        uint16 protocolSwapFee0;
        /**
         * @custom:field protocolSwapFee1
         * @notice The protocol fee taken on all token1 fees
         * @notice 1e4 = 100%
         */
        uint16 protocolSwapFee1;
        /**
         * @custom:field protocolFillFee0
         * @notice The protocol fee taken on all token0 LimitPosition fills
         * @notice 1e2 = 1%
         */
        uint16 protocolFillFee0;
        /**
         * @custom:field protocolFillFee1
         * @notice The protocol fee taken on all token1 LimitPosition fills
         * @notice 1e2 = 1%
         */
        uint16 protocolFillFee1;
        /**
         * @custom:field setFeesFlags
         * @notice The flags for which protocol fees will be set
         * @notice - PROTOCOL_SWAP_FEE_0 = 2**0;
         * @notice - PROTOCOL_SWAP_FEE_1 = 2**1;
         * @notice - PROTOCOL_FILL_FEE_0 = 2**2;
         * @notice - PROTOCOL_FILL_FEE_1 = 2**3;
         */
        uint8 setFeesFlags;
    }

    struct GlobalState {
        RangePoolState pool;
        LimitPoolState pool0;
        LimitPoolState pool1;
        uint128 liquidityGlobal;
        uint32 positionIdNext;
        uint32 epoch;
        uint8 unlocked;
    }

    struct LimitPoolState {
        uint160 price; /// @dev Starting price current
        uint128 liquidity; /// @dev Liquidity currently active
        uint128 protocolFees;
        uint16 protocolFillFee;
        int24 tickAtPrice;
    }

    struct RangePoolState {
        SampleState samples;
        uint200 feeGrowthGlobal0;
        uint200 feeGrowthGlobal1;
        uint160 secondsPerLiquidityAccum;
        uint160 price; /// @dev Starting price current
        uint128 liquidity; /// @dev Liquidity currently active
        int56 tickSecondsAccum;
        int24 tickAtPrice;
        uint16 protocolSwapFee0;
        uint16 protocolSwapFee1;
    }

    struct Tick {
        RangeTick range;
        LimitTick limit;
    }

    struct LimitTick {
        uint160 priceAt;
        int128 liquidityDelta;
        uint128 liquidityAbsolute;
    }

    struct RangeTick {
        uint200 feeGrowthOutside0;
        uint200 feeGrowthOutside1;
        uint160 secondsPerLiquidityAccumOutside;
        int56 tickSecondsAccumOutside;
        int128 liquidityDelta;
        uint128 liquidityAbsolute;
    }

    struct Sample {
        uint32 blockTimestamp;
        int56 tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
    }

    struct SampleState {
        uint16 index;
        uint16 count;
        uint16 countMax;
    }

    struct StakeRangeParams {
        address to;
        address pool;
        uint32 positionId;
    }

    struct UnstakeRangeParams {
        address to;
        address pool;
        uint32 positionId;
    }

    struct StakeFinParams {
        address to;
        uint128 amount;
    }

    struct QuoteResults {
        address pool;
        int256 amountIn;
        int256 amountOut;
        uint160 priceAfter;
    }

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
        int16 minPositionWidth;
        int16 tickSpread;
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

    struct TickMap {
        uint256 blocks; /// @dev - sets of words
        mapping(uint256 => uint256) words; /// @dev - blocks to words
        mapping(uint256 => uint256) ticks; /// @dev - words to ticks
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs0; /// @dev - ticks to epochs
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs1; /// @dev - ticks to epochs
    }

    struct SwapCache {
        GlobalState state;
        LimitImmutables constants;
        uint256 price;
        uint256 liquidity;
        uint256 amountLeft;
        uint256 input;
        uint256 output;
        uint160 crossPrice;
        uint160 averagePrice;
        uint160 secondsPerLiquidityAccum;
        uint128 feeAmount;
        int56 tickSecondsAccum;
        int56 tickSecondsAccumBase;
        int24 crossTick;
        uint8 crossStatus;
        bool limitActive;
        bool exactIn;
        bool cross;
    }

    enum CrossStatus {
        RANGE,
        LIMIT,
        BOTH
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
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

import './PoolsharkStructs.sol';

interface RangePoolStructs is PoolsharkStructs {
    struct RangePosition {
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
        uint128 liquidity;
        int24 lower;
        int24 upper;
    }

    struct CompoundRangeParams {
        uint160 priceLower;
        uint160 priceUpper;
        uint128 amount0;
        uint128 amount1;
        uint32 positionId;
    }

    struct SampleParams {
        uint16 sampleIndex;
        uint16 sampleLength;
        uint32 time;
        uint32[] secondsAgo;
        int24 tick;
        uint128 liquidity;
        PoolsharkStructs.LimitImmutables constants;
    }

    struct UpdateParams {
        int24 lower;
        int24 upper;
        uint32 positionId;
        uint128 burnPercent;
    }

    struct MintRangeCache {
        GlobalState state;
        RangePosition position;
        PoolsharkStructs.LimitImmutables constants;
        address owner;
        uint256 liquidityMinted;
        uint160 priceLower;
        uint160 priceUpper;
        int128 amount0;
        int128 amount1;
        int128 feesAccrued0;
        int128 feesAccrued1;
    }

    struct BurnRangeCache {
        GlobalState state;
        RangePosition position;
        PoolsharkStructs.LimitImmutables constants;
        uint256 liquidityBurned;
        uint160 priceLower;
        uint160 priceUpper;
        int128 amount0;
        int128 amount1;
    }

    struct RangePositionCache {
        uint256 liquidityAmount;
        uint256 rangeFeeGrowth0;
        uint256 rangeFeeGrowth1;
        uint128 amountFees0;
        uint128 amountFees1;
        uint128 feesBurned0;
        uint128 feesBurned1;
    }

    struct SnapshotRangeCache {
        RangePosition position;
        SampleState samples;
        PoolsharkStructs.LimitImmutables constants;
        uint160 price;
        uint160 secondsPerLiquidityAccum;
        uint160 secondsPerLiquidityAccumLower;
        uint160 secondsPerLiquidityAccumUpper;
        uint128 liquidity;
        uint128 amount0;
        uint128 amount1;
        int56 tickSecondsAccum;
        int56 tickSecondsAccumLower;
        int56 tickSecondsAccumUpper;
        uint32 secondsOutsideLower;
        uint32 secondsOutsideUpper;
        uint32 blockTimestamp;
        int24 tick;
    }
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

import './OverflowMath.sol';
import '../../interfaces/structs/LimitPoolStructs.sol';
import '../../interfaces/structs/PoolsharkStructs.sol';

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
                dy = OverflowMath.mulDivRoundingUp(
                    liquidity,
                    priceUpper - priceLower,
                    Q96
                );
            } else {
                dy = OverflowMath.mulDiv(
                    liquidity,
                    priceUpper - priceLower,
                    Q96
                );
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
                dx =
                    OverflowMath.mulDiv(
                        liquidity << 96,
                        priceUpper - priceLower,
                        priceUpper
                    ) /
                    priceLower;
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
                liquidity = OverflowMath.mulDiv(
                    dy,
                    Q96,
                    priceUpper - priceLower
                );
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
                uint256 liquidity1 = OverflowMath.mulDiv(
                    dy,
                    Q96,
                    currentPrice - priceLower
                );
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
            token1amount = uint128(
                getDy(liquidityAmount, priceLower, priceUpper, roundUp)
            );
        } else if (currentPrice <= priceLower) {
            token0amount = uint128(
                getDx(liquidityAmount, priceLower, priceUpper, roundUp)
            );
        } else {
            token0amount = uint128(
                getDx(liquidityAmount, currentPrice, priceUpper, roundUp)
            );
            token1amount = uint128(
                getDy(liquidityAmount, priceLower, currentPrice, roundUp)
            );
        }
        if (token0amount > uint128(type(int128).max))
            require(false, 'AmountsOutOfBounds()');
        if (token1amount > uint128(type(int128).max))
            require(false, 'AmountsOutOfBounds()');
    }

    function getNewPrice(
        uint256 price,
        uint256 liquidity,
        uint256 amount,
        bool zeroForOne,
        bool exactIn
    ) internal pure returns (uint256 newPrice) {
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
                newPrice =
                    price -
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

    function getPrice(uint256 sqrtPrice) internal pure returns (uint256 price) {
        if (sqrtPrice >= 2**48)
            price = OverflowMath.mulDiv(sqrtPrice, sqrtPrice, 2**96);
        else price = sqrtPrice;
    }

    /////////////////////////////////////////////////////////////
    ///////////////////////// TICK MATH /////////////////////////
    /////////////////////////////////////////////////////////////

    int24 internal constant MIN_TICK = -887272; /// @dev - tick for price of 2^-128
    int24 internal constant MAX_TICK = -MIN_TICK; /// @dev - tick for price of 2^128

    function minTick(int16 tickSpacing) internal pure returns (int24 tick) {
        return (MIN_TICK / tickSpacing) * tickSpacing;
    }

    function maxTick(int16 tickSpacing) internal pure returns (int24 tick) {
        return (MAX_TICK / tickSpacing) * tickSpacing;
    }

    function priceBounds(int16 tickSpacing)
        internal
        pure
        returns (uint160, uint160)
    {
        return (minPrice(tickSpacing), maxPrice(tickSpacing));
    }

    function minPrice(int16 tickSpacing) internal pure returns (uint160 price) {
        PoolsharkStructs.LimitImmutables memory constants;
        constants.tickSpacing = tickSpacing;
        return getPriceAtTick(minTick(tickSpacing), constants);
    }

    function maxPrice(int16 tickSpacing) internal pure returns (uint160 price) {
        PoolsharkStructs.LimitImmutables memory constants;
        constants.tickSpacing = tickSpacing;
        return getPriceAtTick(maxTick(tickSpacing), constants);
    }

    function checkTicks(
        int24 lower,
        int24 upper,
        int16 tickSpacing
    ) internal pure {
        if (lower < minTick(tickSpacing))
            require(false, 'LowerTickOutOfBounds()');
        if (upper > maxTick(tickSpacing))
            require(false, 'UpperTickOutOfBounds()');
        if (lower % tickSpacing != 0)
            require(false, 'LowerTickOutsideTickSpacing()');
        if (upper % tickSpacing != 0)
            require(false, 'UpperTickOutsideTickSpacing()');
        if (lower >= upper) require(false, 'LowerUpperTickOrderInvalid()');
    }

    function checkPrice(uint160 price, PriceBounds memory bounds)
        internal
        pure
    {
        if (price < bounds.min || price >= bounds.max)
            require(false, 'PriceOutOfBounds()');
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96.
    /// @dev Throws if |tick| > max tick.
    /// @param tick The input tick for the above formula.
    /// @return price Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick.
    function getPriceAtTick(
        int24 tick,
        PoolsharkStructs.LimitImmutables memory constants
    ) internal pure returns (uint160 price) {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        if (absTick > uint256(uint24(maxTick(constants.tickSpacing))))
            require(false, 'TickOutOfBounds()');
        unchecked {
            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0)
                ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0)
                ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0)
                ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0)
                ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0)
                ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0)
                ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0)
                ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0)
                ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0)
                ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0)
                ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0)
                ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0)
                ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0)
                ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0)
                ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0)
                ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0)
                ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0)
                ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0)
                ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0)
                ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

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
        PoolsharkStructs.LimitImmutables memory constants
    ) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (price < constants.bounds.min || price > constants.bounds.max)
            require(false, 'PriceOutOfBounds()');
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

        int24 tickLow = int24(
            (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
        );
        int24 tickHi = int24(
            (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
        );

        tick = tickLow == tickHi
            ? tickLow
            : getPriceAtTick(tickHi, constants) <= price
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library OverflowMath {
    // @dev no underflow or overflow checks
    function divRoundingUp(uint256 x, uint256 y)
        internal
        pure
        returns (uint256 z)
    {
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
                if (result >= type(uint256).max)
                    require(false, 'MaxUintExceeded()');
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import '../../interfaces/structs/RangePoolStructs.sol';
import '../Samples.sol';

library SampleCall {
    uint8 private constant _ENTERED = 2;

    event Event();

    function perform(
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        uint32[] memory secondsAgo
    )
        external
        view
        returns (
            int56[] memory tickSecondsAccum,
            uint160[] memory secondsPerLiquidityAccum,
            uint160 averagePrice,
            uint128 averageLiquidity,
            int24 averageTick
        )
    {
        if (state.unlocked == _ENTERED)
            require(false, 'ReentrancyGuardReadOnlyReentrantCall()');
        return
            Samples.get(
                address(this),
                RangePoolStructs.SampleParams(
                    state.pool.samples.index,
                    state.pool.samples.count,
                    uint32(block.timestamp),
                    secondsAgo,
                    state.pool.tickAtPrice,
                    state.pool.liquidity,
                    constants
                )
            );
    }
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

import './math/ConstantProduct.sol';
import './utils/SafeCast.sol';
import '../interfaces/range/IRangePool.sol';
import '../interfaces/structs/RangePoolStructs.sol';

library Samples {
    using SafeCast for int56;
    using SafeCast for uint160;
    using SafeCast for uint256;

    uint8 internal constant TIME_DELTA_MAX = 6;

    event SampleRecorded(
        int56 tickSecondsAccum,
        uint160 secondsPerLiquidityAccum
    );

    event SampleCountIncreased(uint16 newSampleCountMax);

    function initialize(
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.RangePoolState memory state
    ) internal returns (PoolsharkStructs.RangePoolState memory) {
        samples[0] = PoolsharkStructs.Sample({
            blockTimestamp: uint32(block.timestamp),
            tickSecondsAccum: 0,
            secondsPerLiquidityAccum: 0
        });

        state.samples.count = 1;
        state.samples.countMax = 5;

        return state;
        /// @dev - TWAP length of 5 is safer for oracle manipulation
    }

    function save(
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.SampleState memory sampleState,
        uint128 startLiquidity, /// @dev - liquidity from start of block
        int24 tick
    ) internal returns (uint16 sampleIndexNew, uint16 sampleLengthNew) {
        // grab the latest sample
        RangePoolStructs.Sample memory newSample = samples[sampleState.index];

        // early return if timestamp has not advanced 2 seconds
        if (newSample.blockTimestamp + 2 > uint32(block.timestamp))
            return (sampleState.index, sampleState.count);

        if (
            sampleState.countMax > sampleState.count &&
            sampleState.index == (sampleState.count - 1)
        ) {
            // increase sampleLengthNew if old size exceeded
            sampleLengthNew = sampleState.count + 1;
        } else {
            sampleLengthNew = sampleState.count;
        }
        sampleIndexNew = (sampleState.index + 1) % sampleLengthNew;
        samples[sampleIndexNew] = _build(
            newSample,
            uint32(block.timestamp),
            tick,
            startLiquidity
        );

        emit SampleRecorded(
            samples[sampleIndexNew].tickSecondsAccum,
            samples[sampleIndexNew].secondsPerLiquidityAccum
        );
    }

    function expand(
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.RangePoolState storage pool,
        uint16 newSampleCountMax
    ) internal {
        if (newSampleCountMax <= pool.samples.countMax) return;
        for (uint16 i = pool.samples.countMax; i < newSampleCountMax; i++) {
            samples[i].blockTimestamp = 1;
        }
        pool.samples.countMax = newSampleCountMax;
        emit SampleCountIncreased(newSampleCountMax);
    }

    function get(address pool, RangePoolStructs.SampleParams memory params)
        internal
        view
        returns (
            int56[] memory tickSecondsAccum,
            uint160[] memory secondsPerLiquidityAccum,
            uint160 averagePrice,
            uint128 averageLiquidity,
            int24 averageTick
        )
    {
        if (params.sampleLength == 0) require(false, 'InvalidSampleLength()');
        if (params.secondsAgo.length == 0)
            require(false, 'SecondsAgoArrayEmpty()');
        uint256 size = params.secondsAgo.length > 1
            ? params.secondsAgo.length
            : 2;
        uint32[] memory secondsAgo = new uint32[](size);
        if (params.secondsAgo.length == 1) {
            secondsAgo = new uint32[](2);
            secondsAgo[0] = params.secondsAgo[0];
            secondsAgo[1] = params.secondsAgo[0] + 2;
        } else secondsAgo = params.secondsAgo;

        if (secondsAgo[0] == secondsAgo[secondsAgo.length - 1])
            require(false, 'SecondsAgoArrayValuesEqual()');

        tickSecondsAccum = new int56[](secondsAgo.length);
        secondsPerLiquidityAccum = new uint160[](secondsAgo.length);

        for (uint256 i = 0; i < secondsAgo.length; i++) {
            (tickSecondsAccum[i], secondsPerLiquidityAccum[i]) = getSingle(
                IRangePool(pool),
                params,
                secondsAgo[i]
            );
        }
        if (secondsAgo[secondsAgo.length - 1] > secondsAgo[0]) {
            averageTick = int24(
                (tickSecondsAccum[0].safeMinusInt56(
                    tickSecondsAccum[secondsAgo.length - 1])
                ) / int32(secondsAgo[secondsAgo.length - 1] - secondsAgo[0])
            );
            averagePrice = ConstantProduct.getPriceAtTick(
                averageTick,
                params.constants
            );
            averageLiquidity = uint128(
                (secondsPerLiquidityAccum[0].safeMinusUint160(
                    secondsPerLiquidityAccum[secondsAgo.length - 1])
                ) * (secondsAgo[secondsAgo.length - 1] - secondsAgo[0])
            );
        } else {
            averageTick = int24(
                (tickSecondsAccum[secondsAgo.length - 1].safeMinusInt56(
                    tickSecondsAccum[0])
                ) / int32(secondsAgo[0] - secondsAgo[secondsAgo.length - 1])
            );
            averagePrice = ConstantProduct.getPriceAtTick(
                averageTick,
                params.constants
            );
            averageLiquidity = uint128(
                (secondsPerLiquidityAccum[secondsAgo.length - 1].safeMinusUint160(
                    secondsPerLiquidityAccum[0])
                ) * (secondsAgo[0] - secondsAgo[secondsAgo.length - 1])
            );
        }
    }

    function _poolSample(IRangePool pool, uint256 sampleIndex)
        internal
        view
        returns (RangePoolStructs.Sample memory)
    {
        (
            uint32 blockTimestamp,
            int56 tickSecondsAccum,
            uint160 liquidityPerSecondsAccum
        ) = IRangePool(pool).samples(sampleIndex);

        return
            PoolsharkStructs.Sample(
                blockTimestamp,
                tickSecondsAccum,
                liquidityPerSecondsAccum
            );
    }

    function getSingle(
        IRangePool pool,
        RangePoolStructs.SampleParams memory params,
        uint32 secondsAgo
    )
        internal
        view
        returns (int56 tickSecondsAccum, uint160 secondsPerLiquidityAccum)
    {
        RangePoolStructs.Sample memory latest = _poolSample(
            pool,
            params.sampleIndex
        );

        if (secondsAgo == 0) {
            // if 2 seconds have elapsed build new sample
            if (latest.blockTimestamp + 2 <= uint32(block.timestamp)) {
                latest = _build(
                    latest,
                    uint32(block.timestamp),
                    params.tick,
                    params.liquidity
                );
            }
            return (latest.tickSecondsAccum, latest.secondsPerLiquidityAccum);
        }

        uint32 targetTime = uint32(block.timestamp) - secondsAgo;

        // should be getting samples
        (
            RangePoolStructs.Sample memory firstSample,
            RangePoolStructs.Sample memory secondSample
        ) = _getAdjacentSamples(pool, latest, params, targetTime);

        if (targetTime == firstSample.blockTimestamp) {
            // first sample
            return (
                firstSample.tickSecondsAccum,
                firstSample.secondsPerLiquidityAccum
            );
        } else if (targetTime == secondSample.blockTimestamp) {
            // second sample
            return (
                secondSample.tickSecondsAccum,
                secondSample.secondsPerLiquidityAccum
            );
        } else {
            // average two samples
            int32 sampleTimeDelta = int32(
                secondSample.blockTimestamp - firstSample.blockTimestamp
            );
            int56 targetDelta = int56(
                int32(targetTime - firstSample.blockTimestamp)
            );
            return (
                firstSample.tickSecondsAccum +
                    ((secondSample.tickSecondsAccum.safeMinusInt56(
                        firstSample.tickSecondsAccum)
                    ) / sampleTimeDelta) * targetDelta,
                firstSample.secondsPerLiquidityAccum +
                    uint160(
                        (uint256(
                            secondSample.secondsPerLiquidityAccum.safeMinusUint160(
                                firstSample.secondsPerLiquidityAccum
                            )
                        ) * uint256(uint56(targetDelta))) /
                            uint32(sampleTimeDelta)
                    )
            );
        }
    }

    function getLatest(
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        uint256 liquidity
    )
        internal
        view
        returns (
            uint160 latestPrice,
            uint160 secondsPerLiquidityAccum,
            int56 tickSecondsAccum
        )
    {
        uint32 timeDelta = timeElapsed(constants);
        (tickSecondsAccum, secondsPerLiquidityAccum) = getSingle(
            IRangePool(address(this)),
            RangePoolStructs.SampleParams(
                state.pool.samples.index,
                state.pool.samples.count,
                uint32(block.timestamp),
                new uint32[](2),
                state.pool.tickAtPrice,
                liquidity.toUint128(),
                constants
            ),
            0
        );
        // grab older sample for dynamic fee calculation
        (int56 tickSecondsAccumBase, ) = Samples.getSingle(
            IRangePool(address(this)),
            RangePoolStructs.SampleParams(
                state.pool.samples.index,
                state.pool.samples.count,
                uint32(block.timestamp),
                new uint32[](2),
                state.pool.tickAtPrice,
                liquidity.toUint128(),
                constants
            ),
            timeDelta
        );

        latestPrice = calculateLatestPrice(
            tickSecondsAccum,
            tickSecondsAccumBase,
            timeDelta,
            TIME_DELTA_MAX,
            constants
        );
    }

    function calculateLatestPrice(
        int56 tickSecondsAccum,
        int56 tickSecondsAccumBase,
        uint32 timeDelta,
        uint32 timeDeltaMax,
        PoolsharkStructs.LimitImmutables memory constants
    ) private pure returns (uint160 averagePrice) {
        int56 tickSecondsAccumDiff = tickSecondsAccum.safeMinusInt56(tickSecondsAccumBase);
        int24 averageTick;
        if (timeDelta == timeDeltaMax) {
            averageTick = int24(tickSecondsAccumDiff / int32(timeDelta));
        } else {
            averageTick = int24(tickSecondsAccum / int32(timeDelta));
        }
        averagePrice = ConstantProduct.getPriceAtTick(averageTick, constants);
    }

    function timeElapsed(PoolsharkStructs.LimitImmutables memory constants)
        private
        view
        returns (uint32)
    {
        return
            uint32(block.timestamp) - constants.genesisTime >= TIME_DELTA_MAX
                ? TIME_DELTA_MAX
                : uint32(block.timestamp - constants.genesisTime);
    }

    function _lte(uint32 timeA, uint32 timeB) private view returns (bool) {
        uint32 currentTime = uint32(block.timestamp);
        if (timeA <= currentTime && timeB <= currentTime) return timeA <= timeB;

        uint256 timeAOverflow = timeA;
        uint256 timeBOverflow = timeB;

        if (timeA <= currentTime) {
            timeAOverflow = timeA + 2**32;
        }
        if (timeB <= currentTime) {
            timeBOverflow = timeB + 2**32;
        }

        return timeAOverflow <= timeBOverflow;
    }

    function _build(
        RangePoolStructs.Sample memory newSample,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity
    ) internal pure returns (RangePoolStructs.Sample memory) {
        int56 timeDelta = int56(
            uint56(blockTimestamp - newSample.blockTimestamp)
        );

        return
            PoolsharkStructs.Sample({
                blockTimestamp: blockTimestamp,
                tickSecondsAccum: newSample.tickSecondsAccum +
                    int56(tick) *
                    int32(timeDelta),
                secondsPerLiquidityAccum: newSample.secondsPerLiquidityAccum +
                    ((uint160(uint56(timeDelta)) << 128) /
                        (liquidity > 0 ? liquidity : 1))
            });
    }

    function _binarySearch(
        IRangePool pool,
        uint32 targetTime,
        uint16 sampleIndex,
        uint16 sampleLength
    )
        private
        view
        returns (
            RangePoolStructs.Sample memory firstSample,
            RangePoolStructs.Sample memory secondSample
        )
    {
        uint256 oldIndex = (sampleIndex + 1) % sampleLength;
        uint256 newIndex = oldIndex + sampleLength - 1;
        uint256 index;
        while (true) {
            // start in the middle
            index = (oldIndex + newIndex) / 2;

            // get the first sample
            firstSample = _poolSample(pool, index % sampleLength);

            // if sample is uninitialized
            if (firstSample.blockTimestamp == 0) {
                // skip this index and continue
                oldIndex = index + 1;
                continue;
            }
            // else grab second sample
            secondSample = _poolSample(pool, (index + 1) % sampleLength);

            // check if target time within first and second sample
            bool targetAfterFirst = _lte(
                firstSample.blockTimestamp,
                targetTime
            );
            bool targetBeforeSecond = _lte(
                targetTime,
                secondSample.blockTimestamp
            );
            if (targetAfterFirst && targetBeforeSecond) break;
            if (!targetAfterFirst) newIndex = index - 1;
            else oldIndex = index + 1;
        }
    }

    function _getAdjacentSamples(
        IRangePool pool,
        RangePoolStructs.Sample memory firstSample,
        RangePoolStructs.SampleParams memory params,
        uint32 targetTime
    )
        private
        view
        returns (RangePoolStructs.Sample memory, RangePoolStructs.Sample memory)
    {
        if (_lte(firstSample.blockTimestamp, targetTime)) {
            if (firstSample.blockTimestamp == targetTime) {
                return (firstSample, PoolsharkStructs.Sample(0, 0, 0));
            } else {
                return (
                    firstSample,
                    _build(
                        firstSample,
                        targetTime,
                        params.tick,
                        params.liquidity
                    )
                );
            }
        }
        firstSample = _poolSample(
            pool,
            (params.sampleIndex + 1) % params.sampleLength
        );
        if (firstSample.blockTimestamp == 0) {
            firstSample = _poolSample(pool, 0);
        }
        if (!_lte(firstSample.blockTimestamp, targetTime))
            require(false, 'SampleLengthNotAvailable()');

        return
            _binarySearch(
                pool,
                targetTime,
                params.sampleIndex,
                params.sampleLength
            );
    }
}

// SPDX-License-Identifier: SSPL-1.0
pragma solidity 0.8.18;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        if ((z = uint128(y)) != y)
            require(false, 'Uint256ToUint128:Overflow()');
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(int128 y) internal pure returns (uint128 z) {
        if (y < 0) require(false, 'Int128ToUint128:Underflow()');
        z = uint128(y);
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        if ((z = uint160(y)) != y)
            require(false, 'Uint256ToUint160:Overflow()');
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint32(uint256 y) internal pure returns (uint32 z) {
        if ((z = uint32(y)) != y) require(false, 'Uint256ToUint32:Overflow()');
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        if ((z = int128(y)) != y) require(false, 'Int256ToInt128:Overflow()');
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(uint128 y) internal pure returns (int128 z) {
        if (y > uint128(type(int128).max))
            require(false, 'Uint128ToInt128:Overflow()');
        z = int128(y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        if (y > uint256(type(int256).max))
            require(false, 'Uint256ToInt256:Overflow()');
        z = int256(y);
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint256(int256 y) internal pure returns (uint256 z) {
        if (y < 0) require(false, 'Int256ToUint256:Underflow()');
        z = uint256(y);
    }

    /// @notice Cast a uint256 to a uint16, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint16(uint256 y) internal pure returns (uint16 z) {
        if ((z = uint16(y)) != y) require(false, 'Uint256ToUint16:Overflow()');
    }

    function safeMinusInt56(
        int56 valueA,
        int56 valueB
    ) internal pure returns (int56) {
        if (valueB >= 0) {
            // check for underflow if valueB gt 0
            if (valueA < type(int56).min + valueB) {
                return type(int56).min;
            }
        } else {
            // check for overflow if valueB lt 0
            if (valueA > type(int56).max + valueB) {
                return type(int56).max;
            }
        }
        return valueA - valueB;
    }

    function safeMinusUint160(
        uint160 valueA,
        uint160 valueB
    ) internal pure returns (uint160) {
        // check for underflow
        if (valueA >= valueB) {
            return valueA - valueB;
        }
        return 0;
    }

    function safeMinusUint256(
        uint256 valueA,
        uint256 valueB
    ) internal pure returns (uint256) {
        // check for underflow
        if (valueA >= valueB) {
            return valueA - valueB;
        }
        return 0;
    }

    function safeMinusFees0(
        uint200 valueA,
        uint200 valueB
    ) internal pure returns (uint200 valueC) {
        if (valueA >= valueB) {
            return valueA - valueB;
        }
        require (false, 'FeeGrowthGlobal0Underflow()');
    }

    function safeMinusFees1(
        uint200 valueA,
        uint200 valueB
    ) internal pure returns (uint200 valueC) {
        if (valueA >= valueB) {
            return valueA - valueB;
        }
        require (false, 'FeeGrowthGlobal1Underflow()');
    }
}