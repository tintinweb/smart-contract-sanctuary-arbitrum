// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import '../../interfaces/structs/PoolsharkStructs.sol';

/// @notice Events emitted by the LimitPoolManager contract
abstract contract LimitPoolManagerEvents is PoolsharkStructs {
    /// @notice Event emitted when pool is initialized by the factory
    event FactoryChanged(
        address indexed previousFactory,
        address indexed newFactory
    );

    /// @notice Event emitted the fee delta constant is modified
    event FeeDeltaConstChanged(
        uint16 oldFeeDeltaConst,
        uint16 newFeeDeltaConst
    );

    /// @notice Event emitted when a new pool type is enabled
    event PoolTypeEnabled(
        bytes32 poolTypeName,
        address poolImpl,
        address tokenImpl,
        uint16 poolTypeId
    );

    /// @notice Event emitted when a new fee tier is enabled
    event FeeTierEnabled(uint16 swapFee, int16 tickSpacing);

    /// @notice Event emitted when the feeTo address is modified
    event FeeToTransfer(
        address indexed previousFeeTo,
        address indexed newFeeTo
    );

    /// @notice Event emitted when the owner address is modified
    event OwnerTransfer(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Event emitted when protocolSwapFees0 or protocolSwapFees1 is modified
    event ProtocolSwapFeesModified(
        address[] pools,
        int16[] protocolSwapFees0,
        int16[] protocolSwapFees1
    );

    /// @notice Event emitted when protocolSwapFees0 or protocolSwapFees1 is modified
    event ProtocolFillFeesModified(
        address[] pools,
        int16[] protocolFillFees0,
        int16[] protocolFillFees1
    );

    /// @notice Event emitted when protocol fees are collected
    event ProtocolFeesCollected(
        address[] pools,
        uint128[] token0FeesCollected,
        uint128[] token1FeesCollected
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

abstract contract LimitPoolFactoryStorage {
    mapping(bytes32 => address) public pools; ///@dev - map for limit pool lookup by key
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import '../interfaces/structs/PoolsharkStructs.sol';

interface IPool is PoolsharkStructs {
    function immutables() external view returns (LimitImmutables memory);

    function swap(SwapParams memory params)
        external
        returns (int256 amount0, int256 amount1);

    function quote(QuoteParams memory params)
        external
        view
        returns (
            int256 inAmount,
            int256 outAmount,
            uint160 priceAfter
        );

    function fees(FeesParams memory params)
        external
        returns (uint128 token0Fees, uint128 token1Fees);

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

    function snapshotRange(uint32 positionId)
        external
        view
        returns (
            int56 tickSecondsAccum,
            uint160 secondsPerLiquidityAccum,
            uint128 feesOwed0,
            uint128 feesOwed1
        );

    function snapshotLimit(SnapshotLimitParams memory params)
        external
        view
        returns (uint128 amountIn, uint128 amountOut);

    function poolToken() external view returns (address poolToken);

    function token0() external view returns (address token0);

    function token1() external view returns (address token1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import '../structs/LimitPoolStructs.sol';

interface ILimitPool is LimitPoolStructs {
    function initialize(uint160 startPrice) external;

    function mintLimit(MintLimitParams memory params)
        external
        returns (int256, int256);

    function burnLimit(BurnLimitParams memory params)
        external
        returns (int256, int256);

    function fees(FeesParams memory params)
        external
        returns (uint128 token0Fees, uint128 token1Fees);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import '../structs/PoolsharkStructs.sol';
import '../../base/storage/LimitPoolFactoryStorage.sol';

abstract contract ILimitPoolFactory is
    LimitPoolFactoryStorage,
    PoolsharkStructs
{
    function createLimitPool(LimitPoolParams memory params)
        external
        virtual
        returns (address pool, address poolToken);

    function getLimitPool(
        address tokenIn,
        address tokenOut,
        uint16 swapFee,
        uint16 poolTypeId
    ) external view virtual returns (address pool, address poolToken);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @notice LimitPoolManager interface
interface ILimitPoolManager {
    function owner() external view returns (address);

    function feeTo() external view returns (address);

    function feeDeltaConst() external view returns (uint16);

    function poolTypes(uint16 poolType)
        external
        view
        returns (address poolImpl, address tokenImpl);

    function feeTiers(uint16 swapFee) external view returns (int16 tickSpacing);
}

// SPDX-License-Identifier: BUSL-1.1
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

// SPDX-License-Identifier: GPLv3
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
        mapping(uint256 => uint256) words; /// @dev - sets to words
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

// SPDX-License-Identifier: GPL-2.0-or-later
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '../interfaces/IPool.sol';
import '../interfaces/limit/ILimitPool.sol';
import '../interfaces/limit/ILimitPoolFactory.sol';
import '../interfaces/limit/ILimitPoolManager.sol';
import '../base/events/LimitPoolManagerEvents.sol';
import '../libraries/utils/SafeCast.sol';

/**
 * @title LimitPoolManager
 * @notice The manager for all limit pools
 * @author Poolshark
 * @author @alphak3y
 */
contract LimitPoolManager is ILimitPoolManager, LimitPoolManagerEvents {
    address public owner;
    address public feeTo;
    address public factory;
    // fee delta const for dynamic fees
    uint16 public feeDeltaConst;
    // max protocol fees
    uint16 public constant MAX_PROTOCOL_SWAP_FEE = 1e4; /// @dev - max protocol swap fee of 100%
    uint16 public constant MAX_PROTOCOL_FILL_FEE = 1e2; /// @dev - max protocol fill fee of 1%
    // impl name => impl address
    bytes32[] _poolTypeNames;
    mapping(uint256 => address) internal _poolImpls;
    mapping(uint256 => address) internal _tokenImpls;
    // swap fee => tick spacing
    mapping(uint16 => int16) internal _feeTiers;

    using SafeCast for uint256;

    error InvalidSwapFee();
    error InvalidTickSpacing();
    error InvalidPoolImplAddress();
    error InvalidTokenImplAddress();
    error InvalidImplAddresses();
    error FeeTierAlreadyEnabled();
    error PoolTypeAlreadyExists();
    error MaxPoolTypesCountExceeded();

    constructor() {
        owner = msg.sender;
        feeTo = msg.sender;
        emit OwnerTransfer(address(0), msg.sender);
        emit FeeToTransfer(address(0), msg.sender);

        // create initial fee tiers
        _feeTiers[1000] = 10;
        _feeTiers[3000] = 30;
        _feeTiers[10000] = 100;
        emit FeeTierEnabled(1000, 10);
        emit FeeTierEnabled(3000, 30);
        emit FeeTierEnabled(10000, 100);

        // set initial fee delta const
        feeDeltaConst = 0;
        emit FeeDeltaConstChanged(0, 0);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyOwnerOrFeeTo() {
        _checkFeeToAndOwner();
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwner(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0))
            require(false, 'TransferredToZeroAddress()');
        _transferOwner(newOwner);
    }

    function transferFeeTo(address newFeeTo) public virtual onlyOwner {
        if (newFeeTo == address(0))
            require(false, 'TransferredToZeroAddress()');
        _transferFeeTo(newFeeTo);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwner(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnerTransfer(oldOwner, newOwner);
    }

    /**
     * @dev Transfers fee collection to a new account (`newFeeTo`).
     * Internal function without access restriction.
     */
    function _transferFeeTo(address newFeeTo) internal virtual {
        address oldFeeTo = feeTo;
        feeTo = newFeeTo;
        emit FeeToTransfer(oldFeeTo, newFeeTo);
    }

    function enableFeeTier(uint16 swapFee, int16 tickSpacing)
        external
        onlyOwner
    {
        if (_feeTiers[swapFee] != 0) revert FeeTierAlreadyEnabled();
        if (tickSpacing <= 0) revert InvalidTickSpacing();
        if (tickSpacing % 2 != 0) revert InvalidTickSpacing();
        if (swapFee == 0) revert InvalidSwapFee();
        if (swapFee > 10000) revert InvalidSwapFee();
        _feeTiers[swapFee] = tickSpacing;
        emit FeeTierEnabled(swapFee, tickSpacing);
    }

    function enablePoolType(
        address poolImpl_,
        address tokenImpl_,
        bytes32 poolTypeName_
    ) external onlyOwner {
        uint16 poolTypeId_ = _poolTypeNames.length.toUint16();
        if (poolTypeId_ > type(uint8).max) revert MaxPoolTypesCountExceeded();
        if (poolImpl_ == address(0)) revert InvalidPoolImplAddress();
        if (tokenImpl_ == address(0)) revert InvalidTokenImplAddress();
        /// @dev - prevent same addresses since factory does not support this
        if (poolImpl_ == tokenImpl_) revert InvalidImplAddresses();
        _poolImpls[poolTypeId_] = poolImpl_;
        _tokenImpls[poolTypeId_] = tokenImpl_;
        _poolTypeNames.push(poolTypeName_);
        emit PoolTypeEnabled(poolTypeName_, poolImpl_, tokenImpl_, poolTypeId_);
    }

    function setFactory(address factory_) external onlyOwner {
        if (factory != address(0)) require(false, 'FactoryAlreadySet()');
        emit FactoryChanged(factory, factory_);
        factory = factory_;
    }

    function setFeeDeltaConst(uint16 feeDeltaConst_) external onlyOwner {
        if (feeDeltaConst_ > 10000)
            require(false, 'FeeDeltaConstCeilingExceeded()');
        emit FeeDeltaConstChanged(feeDeltaConst, feeDeltaConst_);
        feeDeltaConst = feeDeltaConst_;
    }

    function collectProtocolFees(address[] calldata pools)
        external
        onlyOwnerOrFeeTo
    {
        if (pools.length == 0) require(false, 'EmptyPoolsArray()');
        uint128[] memory token0FeesCollected = new uint128[](pools.length);
        uint128[] memory token1FeesCollected = new uint128[](pools.length);
        // pass empty fees params
        FeesParams memory feesParams;
        for (uint256 i; i < pools.length; ) {
            (token0FeesCollected[i], token1FeesCollected[i]) = IPool(pools[i])
                .fees(feesParams);
            unchecked {
                ++i;
            }
        }
        emit ProtocolFeesCollected(
            pools,
            token0FeesCollected,
            token1FeesCollected
        );
    }

    // protocol fee flags
    uint8 internal constant PROTOCOL_SWAP_FEE_0 = 2**0;
    uint8 internal constant PROTOCOL_SWAP_FEE_1 = 2**1;
    uint8 internal constant PROTOCOL_FILL_FEE_0 = 2**2;
    uint8 internal constant PROTOCOL_FILL_FEE_1 = 2**3;

    function modifyProtocolFees(
        address[] calldata pools,
        FeesParams[] calldata feesParams
    ) external onlyOwner {
        if (pools.length == 0) require(false, 'EmptyPoolsArray()');
        if (pools.length != feesParams.length) {
            require(false, 'MismatchedArrayLengths()');
        }
        uint128[] memory token0FeesCollected = new uint128[](pools.length);
        uint128[] memory token1FeesCollected = new uint128[](pools.length);
        int16[] memory protocolSwapFees0 = new int16[](pools.length);
        int16[] memory protocolSwapFees1 = new int16[](pools.length);
        int16[] memory protocolFillFees0 = new int16[](pools.length);
        int16[] memory protocolFillFees1 = new int16[](pools.length);
        for (uint256 i; i < pools.length; ) {
            (token0FeesCollected[i], token1FeesCollected[i]) = IPool(pools[i])
                .fees(feesParams[i]);
            if ((feesParams[i].setFeesFlags & PROTOCOL_SWAP_FEE_0) > 0) {
                protocolSwapFees0[i] = int16(feesParams[i].protocolSwapFee0);
            } else {
                // no protocol fee change
                protocolSwapFees0[i] = -1;
            }
            if ((feesParams[i].setFeesFlags & PROTOCOL_SWAP_FEE_1) > 0) {
                protocolSwapFees1[i] = int16(feesParams[i].protocolSwapFee1);
            } else {
                // no protocol fee change
                protocolSwapFees1[i] = -1;
            }
            if ((feesParams[i].setFeesFlags & PROTOCOL_FILL_FEE_0) > 0) {
                protocolFillFees0[i] = int16(feesParams[i].protocolFillFee0);
            } else {
                // no protocol fee change
                protocolFillFees0[i] = -1;
            }
            if ((feesParams[i].setFeesFlags & PROTOCOL_FILL_FEE_1) > 0) {
                protocolFillFees1[i] = int16(feesParams[i].protocolFillFee1);
            } else {
                // no protocol fee change
                protocolFillFees1[i] = -1;
            }
            // else values will remain zero
            unchecked {
                ++i;
            }
        }
        emit ProtocolSwapFeesModified(
            pools,
            protocolSwapFees0,
            protocolSwapFees1
        );
        emit ProtocolFillFeesModified(
            pools,
            protocolFillFees0,
            protocolFillFees1
        );
        emit ProtocolFeesCollected(
            pools,
            token0FeesCollected,
            token1FeesCollected
        );
    }

    function poolTypes(uint16 poolTypeId)
        external
        view
        returns (address, address)
    {
        return (_poolImpls[poolTypeId], _tokenImpls[poolTypeId]);
    }

    function feeTiers(uint16 swapFee)
        external
        view
        returns (int16 tickSpacing)
    {
        return _feeTiers[swapFee];
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view {
        if (owner != msg.sender) require(false, 'OwnerOnly()');
    }

    /**
     * @dev Throws if the sender is not the feeTo.
     */
    function _checkFeeToAndOwner() internal view {
        if (feeTo != msg.sender && owner != msg.sender)
            require(false, 'OwnerOrFeeToOnly()');
    }
}