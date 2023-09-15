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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../structs/PoolsharkStructs.sol';

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../interfaces/structs/PoolsharkStructs.sol';

interface IPool is PoolsharkStructs {
    function immutables() external view returns (LimitImmutables memory);
    
    function swap(
        SwapParams memory params
    ) external returns (
        int256 amount0,
        int256 amount1
    );

    function quote(
        QuoteParams memory params
    ) external view returns (
        int256 inAmount,
        int256 outAmount,
        uint160 priceAfter
    );

    function fees(
        FeesParams memory params
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );

    function sample(
        uint32[] memory secondsAgo
    ) external view returns (
        int56[]   memory tickSecondsAccum,
        uint160[] memory secondsPerLiquidityAccum,
        uint160 averagePrice,
        uint128 averageLiquidity,
        int24 averageTick
    );

    function snapshotRange(
        uint32 positionId
    ) external view returns(
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum,
        uint128 feesOwed0,
        uint128 feesOwed1
    );

    function snapshotLimit(
        SnapshotLimitParams memory params
    ) external view returns(
        uint128,
        uint128
    );

    function globalState() external view returns (
        RangePoolState memory pool,
        LimitPoolState memory pool0,
        LimitPoolState memory pool1,
        uint128 liquidityGlobal,
        uint32 epoch,
        uint8 unlocked
    );

    function samples(uint256) external view returns (
        uint32,
        int56,
        uint160
    );

    function ticks(int24) external view returns (
        RangeTick memory,
        LimitTick memory
    );

    function positions(uint32) external view returns (
        uint256 feeGrowthInside0Last,
        uint256 feeGrowthInside1Last,
        uint128 liquidity,
        int24 lower,
        int24 upper
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import '../interfaces/structs/PoolsharkStructs.sol';
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPositionERC1155 is IERC165, PoolsharkStructs {
    event TransferSingle(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed account,
        address indexed sender,
        bool approve
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (
        uint256[] memory batchBalances
    );

    function totalSupply(uint256 id) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function setApprovalForAll(address sender, bool approved) external;

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        PoolsharkStructs.LimitImmutables memory constants
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 amount,
        PoolsharkStructs.LimitImmutables memory constants
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata id,
        uint256[] calldata amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../structs/RangePoolStructs.sol';
import './IRangePoolManager.sol';

interface IRangePool is RangePoolStructs {
    function mintRange(
        MintRangeParams memory mintParams
    ) external;

    function burnRange(
        BurnRangeParams memory burnParams
    ) external;

    function swap(
        SwapParams memory params
    ) external returns (
        int256 amount0,
        int256 amount1
    );

    function quote(
        QuoteParams memory params
    ) external view returns (
        uint256 inAmount,
        uint256 outAmount,
        uint160 priceAfter
    );

    function snapshotRange(
        uint32 positionId
    ) external view returns(
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum,
        uint128 feesOwed0,
        uint128 feesOwed1
    );

    function increaseSampleLength(
        uint16 sampleLengthNext
    ) external;
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

interface IRangePoolFactory {
    function createRangePool(
        address fromToken,
        address destToken,
        uint16 fee,
        uint160 startPrice
    ) external returns (address book);

    function getRangePool(
        address fromToken,
        address destToken,
        uint256 fee
    ) external view returns (address);

    function owner() external view returns(address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../structs/RangePoolStructs.sol';

interface IRangePoolManager {
    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function protocolFees(address pool) external view returns (uint16);
    function feeTiers(uint16 swapFee) external view returns (int24);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import './PoolsharkStructs.sol';

interface LimitPoolStructs is PoolsharkStructs {

    struct LimitPosition {
        uint128 liquidity; // expected amount to be used not actual
        uint32 epochLast;  // epoch when this position was created at
        int24 lower;       // lower price tick of position range
        int24 upper;       // upper price tick of position range
        bool crossedInto;  // whether the position was crossed into already
    }

    struct MintLimitParams {
        address to;
        uint128 amount;
        uint96 mintPercent;
        uint32 positionId;
        int24 lower;
        int24 upper;
        bool zeroForOne;
    }

    struct BurnLimitParams {
        address to;
        uint128 burnPercent;
        uint32 positionId;
        int24 claim;
        bool zeroForOne;
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
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../cover/ITwapSource.sol';

interface PoolsharkStructs {
    struct GlobalState {
        RangePoolState pool;
        LimitPoolState pool0;
        LimitPoolState pool1;
        uint128 liquidityGlobal;
        uint32  positionIdNext;
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
        uint32  blockTimestamp;
        int56   tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
    }

    struct SampleState {
        uint16  index;
        uint16  length;
        uint16  lengthNext;
    }

    struct LimitPoolParams {
        bytes32 poolType;
        address tokenIn;
        address tokenOut;
        uint160 startPrice;
        uint16  swapFee;
    }

    struct SwapParams {
        address to;
        uint160 priceLimit;
        uint128  amount;
        bool exactIn;
        bool zeroForOne;
        bytes callbackData;
    }

    struct QuoteParams {
        uint160 priceLimit;
        uint128 amount;
        bool exactIn;
        bool zeroForOne;
    }

    struct FeesParams {
        uint16 protocolSwapFee0;
        uint16 protocolSwapFee1;
        uint16 protocolFillFee0;
        uint16 protocolFillFee1;
        uint8 setFeesFlags;
    }

    struct SnapshotLimitParams {
        address owner;
        uint128 burnPercent;
        uint32 positionId;
        int24 claim;
        bool zeroForOne;
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
        address inputPool;
        uint128 minAmountPerAuction;
        uint32 genesisTime;
        int16  minPositionWidth;
        int16  tickSpread;
        uint16 twapLength;
        uint16 auctionLength;
        uint16 blockTime;
        uint8 token0Decimals;
        uint8 token1Decimals;
        bool minAmountLowerPriced;
    }

    struct PriceBounds {
        uint160 min;
        uint160 max;
    }

    struct TickMap {
        uint256 blocks;                     /// @dev - sets of words
        mapping(uint256 => uint256) words;  /// @dev - sets to words
        mapping(uint256 => uint256) ticks;  /// @dev - words to ticks
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
        int56   tickSecondsAccum;
        int56   tickSecondsAccumBase;
        int24   crossTick;
        uint8   crossStatus;
        bool    limitActive;
        bool    exactIn;
        bool    cross;
    }  

    enum CrossStatus {
        RANGE,
        LIMIT,
        BOTH
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import './PoolsharkStructs.sol';

interface RangePoolStructs is PoolsharkStructs {

    struct RangePosition {
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
        uint128 liquidity;
        int24 lower;
        int24 upper;
    }

    struct MintRangeParams {
        address to;
        int24 lower;
        int24 upper;
        uint32 positionId;
        uint128 amount0;
        uint128 amount1;
    }

    struct BurnRangeParams {
        address to;
        uint32 positionId;
        uint128 burnPercent;
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
        uint256 liquidityMinted;
        uint160 priceLower;
        uint160 priceUpper;
        int128 amount0;
        int128 amount1;
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
        int56   tickSecondsAccum;
        int56   tickSecondsAccumLower;
        int56   tickSecondsAccumUpper;
        uint32  secondsOutsideLower;
        uint32  secondsOutsideUpper;
        uint32  blockTimestamp;
        int24   tick;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

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
        PoolsharkStructs.LimitImmutables  memory constants;
        constants.tickSpacing = tickSpacing;
        return getPriceAtTick(minTick(tickSpacing), constants);
    }

    function maxPrice(
        int16 tickSpacing
    ) internal pure returns (
        uint160 price
    ) {
        PoolsharkStructs.LimitImmutables  memory constants;
        constants.tickSpacing = tickSpacing;
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
        PoolsharkStructs.LimitImmutables memory constants
    ) internal pure returns (
        uint160 price
    ) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        if (absTick > uint256(uint24(maxTick(constants.tickSpacing)))) require (false, 'TickOutOfBounds()');
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
        PoolsharkStructs.LimitImmutables  memory constants
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

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../../Samples.sol';
import '../../utils/SafeCast.sol';
import "../../math/OverflowMath.sol";
import '../../../interfaces/structs/PoolsharkStructs.sol';
import "../../../interfaces/structs/RangePoolStructs.sol";

/// @notice Math library that facilitates fee handling.
library FeeMath {
    using SafeCast for uint256;

    uint256 internal constant FEE_DELTA_CONST = 0;
    //TODO: change FEE_DELTA_CONST before launch
    // uint256 internal constant FEE_DELTA_CONST = 5000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    struct CalculateLocals {
        uint256 price;
        uint256 minPrice;
        uint256 lastPrice;
        uint256 swapFee;
        uint256 feeAmount;
        uint256 protocolFee;
        uint256 protocolFeesAccrued;
        uint256 amountRange;
        bool feeDirection;
    }

    function calculate(
        PoolsharkStructs.SwapCache memory cache,
        uint256 amountIn,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (
        PoolsharkStructs.SwapCache memory
    )
    {
        CalculateLocals memory locals;
        if (cache.state.pool.liquidity != 0) {
            // calculate dynamic fee
            {
                locals.minPrice = ConstantProduct.getPrice(cache.constants.bounds.min);
                // square prices to take delta
                locals.price = ConstantProduct.getPrice(cache.price);
                locals.lastPrice = ConstantProduct.getPrice(cache.averagePrice);
                if (locals.price < locals.minPrice)
                    locals.price = locals.minPrice;
                if (locals.lastPrice < locals.minPrice)
                    locals.lastPrice = locals.minPrice;
                // delta is % modifier on the swapFee
                uint256 delta = OverflowMath.mulDiv(
                        FEE_DELTA_CONST / uint16(cache.constants.tickSpacing), // higher FEE_DELTA_CONST means
                        (                                                      // more aggressive dynamic fee
                            locals.price > locals.lastPrice
                                ? locals.price - locals.lastPrice
                                : locals.lastPrice - locals.price
                        ) * 1_000_000,
                        locals.lastPrice 
                );
                // max fee increase at 5x
                if (delta > 4_000_000) delta = 4_000_000;
                // true means increased fee for zeroForOne = true
                locals.feeDirection = locals.price < locals.lastPrice;
                // adjust fee based on direction
                if (zeroForOne == locals.feeDirection) {
                    // if swapping away from twap price, increase fee
                    locals.swapFee = cache.constants.swapFee + OverflowMath.mulDiv(delta,cache.constants.swapFee, 1e6);
                } else if (delta < 1e6) {
                    // if swapping towards twap price, decrease fee
                    locals.swapFee = cache.constants.swapFee - OverflowMath.mulDiv(delta,cache.constants.swapFee, 1e6);
                } else {
                    // if swapping towards twap price and delta > 100%, set fee to zero
                    locals.swapFee = 0;
                }
                // console.log('price movement', locals.lastPrice, locals.price);
                // console.log('swap fee adjustment',cache.constants.swapFee + delta * cache.constants.swapFee / 1e6);
            }
            if (cache.exactIn) {
                // calculate output from range liquidity
                locals.amountRange = OverflowMath.mulDiv(amountOut, cache.state.pool.liquidity, cache.liquidity);
                // take enough fees to cover fee growth
                locals.feeAmount = OverflowMath.mulDivRoundingUp(locals.amountRange, locals.swapFee, 1e6);
                amountOut -= locals.feeAmount;
            } else {
                // calculate input from range liquidity
                locals.amountRange = OverflowMath.mulDiv(amountIn, cache.state.pool.liquidity, cache.liquidity);
                // take enough fees to cover fee growth
                locals.feeAmount = OverflowMath.mulDivRoundingUp(locals.amountRange, locals.swapFee, 1e6);
                amountIn += locals.feeAmount;
            }
            // add to total fees paid for swap
            cache.feeAmount += locals.feeAmount.toUint128();
            // load protocol fee from cache
            // zeroForOne && exactIn   = fee on token1
            // zeroForOne && !exactIn  = fee on token0
            // !zeroForOne && !exactIn = fee on token1
            // !zeroForOne && exactIn  = fee on token0
            locals.protocolFee = (zeroForOne == cache.exactIn) ? cache.state.pool.protocolSwapFee1 
                                                               : cache.state.pool.protocolSwapFee0;
            // calculate fee
            locals.protocolFeesAccrued = OverflowMath.mulDiv(locals.feeAmount, locals.protocolFee, 1e4);
            // fees for this swap step
            locals.feeAmount -= locals.protocolFeesAccrued;
            // save fee growth and protocol fees
            if (zeroForOne == cache.exactIn) {
                cache.state.pool0.protocolFees += uint128(locals.protocolFeesAccrued);
                cache.state.pool.feeGrowthGlobal1 += uint200(OverflowMath.mulDiv(locals.feeAmount, Q128, cache.state.pool.liquidity));
            } else {
                cache.state.pool1.protocolFees += uint128(locals.protocolFeesAccrued);
                cache.state.pool.feeGrowthGlobal0 += uint200(OverflowMath.mulDiv(locals.feeAmount, Q128, cache.state.pool.liquidity));
            }
        }
        cache.input  += amountIn;
        cache.output += amountOut;

        return cache;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../../interfaces/IPool.sol';
import '../../interfaces/IPositionERC1155.sol';
import '../../interfaces/structs/RangePoolStructs.sol';
import '../math/ConstantProduct.sol';
import './math/FeeMath.sol';
import '../math/OverflowMath.sol';
import '../utils/SafeCast.sol';
import './RangeTicks.sol';
import '../Samples.sol';

/// @notice Position management library for ranged liquidity.
library RangePositions {
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using SafeCast for int128;

    error NotEnoughPositionLiquidity();
    error InvalidClaimTick();
    error LiquidityOverflow();
    error WrongTickClaimedAt();
    error NoLiquidityBeingAdded();
    error PositionNotUpdated();
    error InvalidLowerTick();
    error InvalidUpperTick();
    error InvalidPositionAmount();
    error InvalidPositionBoundsOrder();
    error NotImplementedYet();

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    event BurnRange(
        address indexed recipient,
        uint256 indexed positionId,
        uint128 liquidityBurned,
        int128 amount0,
        int128 amount1
    );

    event CompoundRange(
        uint32 indexed positionId,
        uint128 liquidityCompounded
    );

    function validate(
        RangePoolStructs.MintRangeParams memory params,
        RangePoolStructs.MintRangeCache memory cache
    ) internal pure returns (
        RangePoolStructs.MintRangeParams memory,
        RangePoolStructs.MintRangeCache memory
    ) {
        RangeTicks.validate(cache.position.lower, cache.position.upper, cache.constants.tickSpacing);

        cache.liquidityMinted = ConstantProduct.getLiquidityForAmounts(
            cache.priceLower,
            cache.priceUpper,
            cache.state.pool.price,
            params.amount1,
            params.amount0
        );
        if (cache.liquidityMinted == 0) require(false, 'NoLiquidityBeingAdded()');
        (params.amount0, params.amount1) = ConstantProduct.getAmountsForLiquidity(
            cache.priceLower,
            cache.priceUpper,
            cache.state.pool.price,
            cache.liquidityMinted,
            true
        );
        if (cache.liquidityMinted > uint128(type(int128).max)) require(false, 'LiquidityOverflow()');

        return (params, cache);
    }

    function add(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.TickMap storage tickMap,
        RangePoolStructs.MintRangeCache memory cache,
        RangePoolStructs.MintRangeParams memory params
    ) internal returns (
        RangePoolStructs.MintRangeCache memory
    ) {
        if (params.amount0 == 0 && params.amount1 == 0) return cache;

        cache.state = RangeTicks.insert(
            ticks,
            samples,
            tickMap,
            cache.state,
            cache.constants,
            cache.position.lower,
            cache.position.upper,
            cache.liquidityMinted.toUint128()
        );
        (
            cache.position.feeGrowthInside0Last,
            cache.position.feeGrowthInside1Last
        ) = rangeFeeGrowth(
            ticks[cache.position.lower].range,
            ticks[cache.position.upper].range,
            cache.state,
            cache.position.lower,
            cache.position.upper
        );
        if (cache.position.liquidity == 0) {
            IPositionERC1155(cache.constants.poolToken).mint(
                params.to,
                params.positionId,
                1,
                cache.constants
            );
        }
        cache.position.liquidity += uint128(cache.liquidityMinted);
        return cache;
    }

    function remove(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.TickMap storage tickMap,
        RangePoolStructs.BurnRangeParams memory params,
        RangePoolStructs.BurnRangeCache memory cache
    ) internal returns (
        RangePoolStructs.BurnRangeCache memory
    ) {
        cache.priceLower = ConstantProduct.getPriceAtTick(cache.position.lower, cache.constants);
        cache.priceUpper = ConstantProduct.getPriceAtTick(cache.position.upper, cache.constants);
        cache.liquidityBurned = uint256(params.burnPercent) * cache.position.liquidity / 1e38;
        if (cache.liquidityBurned  == 0) {
            return cache;
        }
        if (cache.liquidityBurned > cache.position.liquidity) require(false, 'NotEnoughPositionLiquidity()');
        {
            uint128 amount0Removed; uint128 amount1Removed;
            (amount0Removed, amount1Removed) = ConstantProduct.getAmountsForLiquidity(
                cache.priceLower,
                cache.priceUpper,
                cache.state.pool.price,
                cache.liquidityBurned ,
                false
            );
            cache.amount0 += amount0Removed.toInt128();
            cache.amount1 += amount1Removed.toInt128();
            cache.position.liquidity -= cache.liquidityBurned.toUint128();
        }
        cache.state = RangeTicks.remove(
            ticks,
            samples,
            tickMap,
            cache.state,
            cache.constants,
            cache.position.lower,
            cache.position.upper,
            uint128(cache.liquidityBurned)
        );
        emit BurnRange(
            params.to,
            params.positionId,
            uint128(cache.liquidityBurned),
            cache.amount0,
            cache.amount1
        );
        if (cache.position.liquidity == 0) {
            cache.position.feeGrowthInside0Last = 0;
            cache.position.feeGrowthInside1Last = 0;
            cache.position.lower = 0;
            cache.position.upper = 0;
        }
        return cache;
    }

    function compound(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.TickMap storage tickMap,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        RangePoolStructs.RangePosition memory position,
        RangePoolStructs.CompoundRangeParams memory params
    ) internal returns (
        RangePoolStructs.RangePosition memory,
        PoolsharkStructs.GlobalState memory,
        int128,
        int128
    ) {
        // price tells you the ratio so you need to swap into the correct ratio and add liquidity
        uint256 liquidityAmount = ConstantProduct.getLiquidityForAmounts(
            params.priceLower,
            params.priceUpper,
            state.pool.price,
            params.amount1,
            params.amount0
        );
        if (liquidityAmount > 0) {
            state = RangeTicks.insert(
                ticks,
                samples,
                tickMap,
                state,
                constants,
                position.lower,
                position.upper,
                uint128(liquidityAmount)
            );
            uint256 amount0; uint256 amount1;
            (amount0, amount1) = ConstantProduct.getAmountsForLiquidity(
                params.priceLower,
                params.priceUpper,
                state.pool.price,
                liquidityAmount,
                true
            );
            params.amount0 -= (amount0 <= params.amount0) ? uint128(amount0) : params.amount0;
            params.amount1 -= (amount1 <= params.amount1) ? uint128(amount1) : params.amount1;
            position.liquidity += uint128(liquidityAmount);
        }
        emit CompoundRange(
            params.positionId,
            uint128(liquidityAmount)
        );
        return (position, state, params.amount0.toInt128(), params.amount1.toInt128());
    }

    function update(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.RangePosition memory position,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        RangePoolStructs.UpdateParams memory params
    ) internal returns (
        RangePoolStructs.RangePosition memory,
        int128,
        int128
    ) {
        RangePoolStructs.RangePositionCache memory cache;
        /// @dev - only true if burn call
        if (params.burnPercent > 0) {
            cache.liquidityAmount = uint256(params.burnPercent) * position.liquidity / 1e38;
            if (position.liquidity == cache.liquidityAmount)
                IPositionERC1155(constants.poolToken).burn(msg.sender, params.positionId, 1, constants);
        }

        (uint256 rangeFeeGrowth0, uint256 rangeFeeGrowth1) = rangeFeeGrowth(
            ticks[position.lower].range,
            ticks[position.upper].range,
            state,
            position.lower,
            position.upper
        );

        int128 amount0Fees = OverflowMath.mulDiv(
            rangeFeeGrowth0 - position.feeGrowthInside0Last,
            uint256(position.liquidity),
            Q128
        ).toInt256().toInt128();

        int128 amount1Fees = OverflowMath.mulDiv(
            rangeFeeGrowth1 - position.feeGrowthInside1Last,
            position.liquidity,
            Q128
        ).toInt256().toInt128();

        position.feeGrowthInside0Last = rangeFeeGrowth0;
        position.feeGrowthInside1Last = rangeFeeGrowth1;

        return (position, amount0Fees, amount1Fees);
    }

    function rangeFeeGrowth(
        PoolsharkStructs.RangeTick memory lowerTick,
        PoolsharkStructs.RangeTick memory upperTick,
        PoolsharkStructs.GlobalState memory state,
        int24 lower,
        int24 upper
    ) internal pure returns (uint256 feeGrowthInside0, uint256 feeGrowthInside1) {

        uint256 feeGrowthGlobal0 = state.pool.feeGrowthGlobal0;
        uint256 feeGrowthGlobal1 = state.pool.feeGrowthGlobal1;

        uint256 feeGrowthBelow0;
        uint256 feeGrowthBelow1;
        if (state.pool.tickAtPrice >= lower) {
            feeGrowthBelow0 = lowerTick.feeGrowthOutside0;
            feeGrowthBelow1 = lowerTick.feeGrowthOutside1;
        } else {
            feeGrowthBelow0 = feeGrowthGlobal0 - lowerTick.feeGrowthOutside0;
            feeGrowthBelow1 = feeGrowthGlobal1 - lowerTick.feeGrowthOutside1;
        }

        uint256 feeGrowthAbove0;
        uint256 feeGrowthAbove1;
        if (state.pool.tickAtPrice < upper) {
            feeGrowthAbove0 = upperTick.feeGrowthOutside0;
            feeGrowthAbove1 = upperTick.feeGrowthOutside1;
        } else {
            feeGrowthAbove0 = feeGrowthGlobal0 - upperTick.feeGrowthOutside0;
            feeGrowthAbove1 = feeGrowthGlobal1 - upperTick.feeGrowthOutside1;
        }
        feeGrowthInside0 = feeGrowthGlobal0 - feeGrowthBelow0 - feeGrowthAbove0;
        feeGrowthInside1 = feeGrowthGlobal1 - feeGrowthBelow1 - feeGrowthAbove1;
    }

    function snapshot(
        mapping(uint256 => RangePoolStructs.RangePosition)
            storage positions,
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        uint32 positionId
    ) internal view returns (
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum,
        uint128 feesOwed0,
        uint128 feesOwed1
    ) {
        RangePoolStructs.SnapshotRangeCache memory cache;
        cache.position = positions[positionId];

        // early return if position empty
        if (cache.position.liquidity == 0)
            return (0,0,0,0);

        cache.price = state.pool.price;
        cache.liquidity = state.pool.liquidity;
        cache.samples = state.pool.samples;

        // grab lower tick
        PoolsharkStructs.RangeTick memory tickLower = ticks[cache.position.lower].range;
        
        // grab upper tick
        PoolsharkStructs.RangeTick memory tickUpper = ticks[cache.position.upper].range;

        cache.tickSecondsAccumLower =  tickLower.tickSecondsAccumOutside;
        cache.secondsPerLiquidityAccumLower = tickLower.secondsPerLiquidityAccumOutside;

        // if both have never been crossed into return 0
        cache.tickSecondsAccumUpper = tickUpper.tickSecondsAccumOutside;
        cache.secondsPerLiquidityAccumUpper = tickUpper.secondsPerLiquidityAccumOutside;
        cache.constants = constants;

        (uint256 rangeFeeGrowth0, uint256 rangeFeeGrowth1) = rangeFeeGrowth(
            tickLower,
            tickUpper,
            state,
            cache.position.lower,
            cache.position.upper
        );

        // calcuate fees earned
        cache.amount0 += uint128(
            OverflowMath.mulDiv(
                rangeFeeGrowth0 - cache.position.feeGrowthInside0Last,
                cache.position.liquidity,
                Q128
            )
        );
        cache.amount1 += uint128(
            OverflowMath.mulDiv(
                rangeFeeGrowth1 - cache.position.feeGrowthInside1Last,
                cache.position.liquidity,
                Q128
            )
        );

        cache.tick = state.pool.tickAtPrice;
        if (cache.position.lower >= cache.tick) {
            return (
                cache.tickSecondsAccumLower - cache.tickSecondsAccumUpper,
                cache.secondsPerLiquidityAccumLower - cache.secondsPerLiquidityAccumUpper,
                cache.amount0,
                cache.amount1
            );
        } else if (cache.position.upper >= cache.tick) {
            cache.blockTimestamp = uint32(block.timestamp);
            (
                cache.tickSecondsAccum,
                cache.secondsPerLiquidityAccum
            ) = Samples.getSingle(
                IPool(address(this)), 
                RangePoolStructs.SampleParams(
                    cache.samples.index,
                    cache.samples.length,
                    uint32(block.timestamp),
                    new uint32[](2),
                    cache.tick,
                    cache.liquidity,
                    cache.constants
                ),
                0
            );
            return (
                cache.tickSecondsAccum 
                  - cache.tickSecondsAccumLower 
                  - cache.tickSecondsAccumUpper,
                cache.secondsPerLiquidityAccum
                  - cache.secondsPerLiquidityAccumLower
                  - cache.secondsPerLiquidityAccumUpper,
                cache.amount0,
                cache.amount1
            );
        }
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../../interfaces/structs/PoolsharkStructs.sol';
import '../../interfaces/structs/RangePoolStructs.sol';
import '../../interfaces/range/IRangePoolFactory.sol';
import '../../interfaces/range/IRangePool.sol';
import './math/FeeMath.sol';
import './RangePositions.sol';
import '../math/OverflowMath.sol';
import '../math/ConstantProduct.sol';
import '../TickMap.sol';
import '../Samples.sol';

/// @notice Tick management library for range pools
library RangeTicks {
    error LiquidityOverflow();
    error LiquidityUnderflow();
    error InvalidLowerTick();
    error InvalidUpperTick();
    error InvalidPositionAmount();
    error InvalidPositionBounds();

    event Initialize(
        uint160 startPrice,
        int24 tickAtPrice,
        int24 minTick,
        int24 maxTick
    );

    event SyncRangeTick(
        uint200 feeGrowthOutside0,
        uint200 feeGrowthOutside1,
        int24 tick
    );

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    function validate(
        int24 lower,
        int24 upper,
        int16 tickSpacing
    ) internal pure {
        if (lower % tickSpacing != 0) require(false, 'InvalidLowerTick()');
        if (lower < ConstantProduct.minTick(tickSpacing)) require(false, 'InvalidLowerTick()');
        if (upper % tickSpacing != 0) require(false, 'InvalidUpperTick()');
        if (upper > ConstantProduct.maxTick(tickSpacing)) require(false, 'InvalidUpperTick()');
        if (lower >= upper) require(false, 'InvalidPositionBounds()');
    }

    function insert(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.TickMap storage tickMap,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        int24 lower,
        int24 upper,
        uint128 amount
    ) internal returns (PoolsharkStructs.GlobalState memory) {
        validate(lower, upper, constants.tickSpacing);

        // check for amount to overflow liquidity delta & global
        if (amount == 0)
            require(false, 'NoLiquidityBeingAdded()');
        if (state.liquidityGlobal + amount > uint128(type(int128).max))
            require(false, 'LiquidityOverflow()');

        // get tick at price
        int24 tickAtPrice = state.pool.tickAtPrice;

        if(TickMap.set(tickMap, lower, constants.tickSpacing)) {
            ticks[lower].range.liquidityDelta += int128(amount);
            ticks[lower].range.liquidityAbsolute += amount;
        } else {
            if (lower <= tickAtPrice) {
                (
                    int56 tickSecondsAccum,
                    uint160 secondsPerLiquidityAccum
                ) = Samples.getSingle(
                        IPool(address(this)), 
                        RangePoolStructs.SampleParams(
                            state.pool.samples.index,
                            state.pool.samples.length,
                            uint32(block.timestamp),
                            new uint32[](2),
                            state.pool.tickAtPrice,
                            state.pool.liquidity,
                            constants
                        ),
                        0
                );
                ticks[lower].range = PoolsharkStructs.RangeTick(
                    state.pool.feeGrowthGlobal0,
                    state.pool.feeGrowthGlobal1,
                    secondsPerLiquidityAccum,
                    tickSecondsAccum,
                    int128(amount),             // liquidityDelta
                    amount                      // liquidityAbsolute
                );
                emit SyncRangeTick(
                    state.pool.feeGrowthGlobal0,
                    state.pool.feeGrowthGlobal1,
                    lower
                );
            } else {
                ticks[lower].range.liquidityDelta = int128(amount);
                ticks[lower].range.liquidityAbsolute += amount;
            }
        }
        if(TickMap.set(tickMap, upper, constants.tickSpacing)) {
            ticks[upper].range.liquidityDelta -= int128(amount);
            ticks[upper].range.liquidityAbsolute += amount;
        } else {
            if (upper <= tickAtPrice) {

                (
                    int56 tickSecondsAccum,
                    uint160 secondsPerLiquidityAccum
                ) = Samples.getSingle(
                        IPool(address(this)), 
                        RangePoolStructs.SampleParams(
                            state.pool.samples.index,
                            state.pool.samples.length,
                            uint32(block.timestamp),
                            new uint32[](2),
                            state.pool.tickAtPrice,
                            state.pool.liquidity,
                            constants
                        ),
                        0
                );
                ticks[upper].range = PoolsharkStructs.RangeTick(
                    state.pool.feeGrowthGlobal0,
                    state.pool.feeGrowthGlobal1,
                    secondsPerLiquidityAccum,
                    tickSecondsAccum,
                    -int128(amount),
                    amount
                );
                emit SyncRangeTick(
                    state.pool.feeGrowthGlobal0,
                    state.pool.feeGrowthGlobal1,
                    upper
                );
            } else {
                ticks[upper].range.liquidityDelta = -int128(amount);
                ticks[upper].range.liquidityAbsolute = amount;
            }
        }
        if (tickAtPrice >= lower && tickAtPrice < upper) {
            // write an oracle entry
            (state.pool.samples.index, state.pool.samples.length) = Samples.save(
                samples,
                state.pool.samples,
                state.pool.liquidity,
                state.pool.tickAtPrice
            );
            // update pool liquidity
            state.pool.liquidity += amount;
        }
        // update global liquidity
        state.liquidityGlobal += amount;

        return state;
    }

    function remove(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.TickMap storage tickMap,
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants, 
        int24 lower,
        int24 upper,
        uint128 amount
    ) internal returns (PoolsharkStructs.GlobalState memory) {
        validate(lower, upper, constants.tickSpacing);
        //check for amount to overflow liquidity delta & global
        if (amount == 0) return state;
        if (amount > uint128(type(int128).max)) require(false, 'LiquidityUnderflow()');
        if (amount > state.liquidityGlobal) require(false, 'LiquidityUnderflow()');

        // get pool tick at price
        int24 tickAtPrice = state.pool.tickAtPrice;

        // update lower liquidity values
        PoolsharkStructs.RangeTick memory tickLower = ticks[lower].range;
        unchecked {
            tickLower.liquidityDelta -= int128(amount);
            tickLower.liquidityAbsolute -= amount;
        }
        ticks[lower].range = tickLower;
        // try to clear tick if possible
        clear(ticks, constants, tickMap, lower);

        // update upper liquidity values
        PoolsharkStructs.RangeTick memory tickUpper = ticks[upper].range;
        unchecked {
            tickUpper.liquidityDelta += int128(amount);
            tickUpper.liquidityAbsolute -= amount;
        }
        ticks[upper].range = tickUpper;
        // try to clear tick if possible
        clear(ticks, constants, tickMap, upper);

        if (tickAtPrice >= lower && tickAtPrice < upper) {
            // write an oracle entry
            (state.pool.samples.index, state.pool.samples.length) = Samples.save(
                samples,
                state.pool.samples,
                state.pool.liquidity,
                tickAtPrice
            );
            state.pool.liquidity -= amount;  
        }
        state.liquidityGlobal -= amount;

        return state;
    }

    function clear(
        mapping(int24 => PoolsharkStructs.Tick) storage ticks,
        PoolsharkStructs.LimitImmutables memory constants,
        PoolsharkStructs.TickMap storage tickMap,
        int24 tickToClear
    ) internal {
        if (_empty(ticks[tickToClear])) {
            if (tickToClear != ConstantProduct.maxTick(constants.tickSpacing) &&
                    tickToClear != ConstantProduct.minTick(constants.tickSpacing)) {
                ticks[tickToClear].range = PoolsharkStructs.RangeTick(0,0,0,0,0,0);
                TickMap.unset(tickMap, tickToClear, constants.tickSpacing);
            }
        }
    }

    function _empty(
        LimitPoolStructs.Tick memory tick
    ) internal pure returns (
        bool
    ) {
        if (tick.range.liquidityAbsolute != 0) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import './math/ConstantProduct.sol';
import './utils/SafeCast.sol';
import '../interfaces/IPool.sol';
import '../interfaces/range/IRangePool.sol';
import '../interfaces/structs/RangePoolStructs.sol';

library Samples {
    using SafeCast for uint256;

    uint8 internal constant TIME_DELTA_MAX = 6;

    error InvalidSampleLength();
    error SampleArrayUninitialized();
    error SampleLengthNotAvailable();

    event SampleRecorded(
        int56 tickSecondsAccum,
        uint160 secondsPerLiquidityAccum
    );

    event SampleLengthIncreased(
        uint16 sampleLengthNext
    );

    function initialize(
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.RangePoolState memory state
    ) internal returns (
        PoolsharkStructs.RangePoolState memory
    )
    {
        samples[0] = PoolsharkStructs.Sample({
            blockTimestamp: uint32(block.timestamp),
            tickSecondsAccum: 0,
            secondsPerLiquidityAccum: 0
        });

        state.samples.length = 1;
        state.samples.lengthNext = 5;

        return state;
        /// @dev - TWAP length of 5 is safer for oracle manipulation
    }

    function save(
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.SampleState memory sampleState,
        uint128 startLiquidity, /// @dev - liquidity from start of block
        int24  tick
    ) internal returns (
        uint16 sampleIndexNew,
        uint16 sampleLengthNew
    ) {
        // grab the latest sample
        RangePoolStructs.Sample memory newSample = samples[sampleState.index];

        // early return if timestamp has not advanced 2 seconds
        if (newSample.blockTimestamp + 2 > uint32(block.timestamp))
            return (sampleState.index, sampleState.length);

        if (sampleState.lengthNext > sampleState.length
            && sampleState.index == (sampleState.length - 1)) {
            // increase sampleLengthNew if old size exceeded
            sampleLengthNew = sampleState.lengthNext;
        } else {
            sampleLengthNew = sampleState.length;
        }
        sampleIndexNew = (sampleState.index + 1) % sampleLengthNew;
        samples[sampleIndexNew] = _build(newSample, uint32(block.timestamp), tick, startLiquidity);

        emit SampleRecorded(
            samples[sampleIndexNew].tickSecondsAccum,
            samples[sampleIndexNew].secondsPerLiquidityAccum
        );
    }

    function expand(
        RangePoolStructs.Sample[65535] storage samples,
        PoolsharkStructs.RangePoolState storage pool,
        uint16 sampleLengthNext
    ) internal {
        if (sampleLengthNext <= pool.samples.lengthNext) return ;
        for (uint16 i = pool.samples.lengthNext; i < sampleLengthNext; i++) {
            samples[i].blockTimestamp = 1;
        }
        pool.samples.lengthNext = sampleLengthNext;
        emit SampleLengthIncreased(sampleLengthNext);
    }

    function get(
        address pool,
        RangePoolStructs.SampleParams memory params
    ) internal view returns (
        int56[]   memory tickSecondsAccum,
        uint160[] memory secondsPerLiquidityAccum,
        uint160 averagePrice,
        uint128 averageLiquidity,
        int24 averageTick
    ) {
        if (params.sampleLength == 0) require(false, 'InvalidSampleLength()');
        if (params.secondsAgo.length == 0) require(false, 'SecondsAgoArrayEmpty()');
        uint256 size = params.secondsAgo.length > 1 ? params.secondsAgo.length : 2;
        uint32[] memory secondsAgo = new uint32[](size);
        if (params.secondsAgo.length == 1) {
            secondsAgo = new uint32[](2);
            secondsAgo[0] = params.secondsAgo[0];
            secondsAgo[1] = params.secondsAgo[0] + 2;
        }
        else secondsAgo = params.secondsAgo;

        if (secondsAgo[0] == secondsAgo[secondsAgo.length - 1]) require(false, 'SecondsAgoArrayValuesEqual()');

        tickSecondsAccum = new int56[](secondsAgo.length);
        secondsPerLiquidityAccum = new uint160[](secondsAgo.length);

        for (uint256 i = 0; i < secondsAgo.length; i++) {
            (
                tickSecondsAccum[i],
                secondsPerLiquidityAccum[i]
            ) = getSingle(
                IPool(pool),
                params,
                secondsAgo[i]
            );
        }
        if (secondsAgo[secondsAgo.length - 1] > secondsAgo[0]) {
            averageTick = int24((tickSecondsAccum[0] - tickSecondsAccum[secondsAgo.length - 1]) 
                                / int32(secondsAgo[secondsAgo.length - 1] - secondsAgo[0]));
            averagePrice = ConstantProduct.getPriceAtTick(averageTick, params.constants);
            averageLiquidity = uint128((secondsPerLiquidityAccum[0] - secondsPerLiquidityAccum[secondsAgo.length - 1]) 
                                    * (secondsAgo[secondsAgo.length - 1] - secondsAgo[0]));
        } else {
            averageTick = int24((tickSecondsAccum[secondsAgo.length - 1] - tickSecondsAccum[0]) 
                                / int32(secondsAgo[0] - secondsAgo[secondsAgo.length - 1]));
            averagePrice = ConstantProduct.getPriceAtTick(averageTick, params.constants);
            averageLiquidity = uint128((secondsPerLiquidityAccum[secondsAgo.length - 1] - secondsPerLiquidityAccum[0]) 
                                    * (secondsAgo[0] - secondsAgo[secondsAgo.length - 1]));
        }
    }

    function _poolSample(
        IPool pool,
        uint256 sampleIndex
    ) internal view returns (
        RangePoolStructs.Sample memory
    ) {
        (
            uint32 blockTimestamp,
            int56 tickSecondsAccum,
            uint160 liquidityPerSecondsAccum
        ) = pool.samples(sampleIndex);

        return PoolsharkStructs.Sample(
            blockTimestamp,
            tickSecondsAccum,
            liquidityPerSecondsAccum
        );
    }

    function getSingle(
        IPool pool,
        RangePoolStructs.SampleParams memory params,
        uint32 secondsAgo
    ) internal view returns (
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum
    ) {
        RangePoolStructs.Sample memory latest = _poolSample(pool, params.sampleIndex);

        if (secondsAgo == 0) {
            if (latest.blockTimestamp != uint32(block.timestamp)) {
                latest = _build(
                    latest,
                    uint32(block.timestamp),
                    params.tick,
                    params.liquidity
                );
            } 
            return (
                latest.tickSecondsAccum,
                latest.secondsPerLiquidityAccum
            );
        }

        uint32 targetTime = uint32(block.timestamp) - secondsAgo;

        // should be getting samples
        (
            RangePoolStructs.Sample memory firstSample,
            RangePoolStructs.Sample memory secondSample
        ) = _getAdjacentSamples(
                pool,
                latest,
                params,
                targetTime
        );

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
            int32 sampleTimeDelta = int32(secondSample.blockTimestamp - firstSample.blockTimestamp);
            int56 targetDelta = int56(int32(targetTime - firstSample.blockTimestamp));
            return (
                firstSample.tickSecondsAccum +
                    ((secondSample.tickSecondsAccum - firstSample.tickSecondsAccum) 
                    / sampleTimeDelta)
                    * targetDelta,
                firstSample.secondsPerLiquidityAccum +
                    uint160(
                        (uint256(
                            secondSample.secondsPerLiquidityAccum - firstSample.secondsPerLiquidityAccum
                        ) 
                        * uint256(uint56(targetDelta))) 
                        / uint32(sampleTimeDelta)
                    )
            );
        }
    }

    function getLatest(
        PoolsharkStructs.GlobalState memory state,
        PoolsharkStructs.LimitImmutables memory constants,
        uint256 liquidity
    ) internal view returns (
        uint160 latestPrice,
        uint160 secondsPerLiquidityAccum,
        int56 tickSecondsAccum
    ) {
        uint32 timeDelta = timeElapsed(constants);
        (
            tickSecondsAccum,
            secondsPerLiquidityAccum
        ) = getSingle(
                IPool(address(this)), 
                RangePoolStructs.SampleParams(
                    state.pool.samples.index,
                    state.pool.samples.length,
                    uint32(block.timestamp),
                    new uint32[](2),
                    state.pool.tickAtPrice,
                    liquidity.toUint128(),
                    constants
                ),
                0
        );
        // grab older sample for dynamic fee calculation
        (
            int56 tickSecondsAccumBase,
        ) = Samples.getSingle(
                IPool(address(this)), 
                RangePoolStructs.SampleParams(
                    state.pool.samples.index,
                    state.pool.samples.length,
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
    ) private pure returns (
        uint160 averagePrice
    ) {
        int56 tickSecondsAccumDiff = tickSecondsAccum - tickSecondsAccumBase;
        int24 averageTick;
        if (timeDelta == timeDeltaMax) {
            averageTick = int24(tickSecondsAccumDiff / int32(timeDelta));
        } else {
            averageTick = int24(tickSecondsAccum / int32(timeDelta));
        }
        averagePrice = ConstantProduct.getPriceAtTick(averageTick, constants);
    }


    function timeElapsed(
        PoolsharkStructs.LimitImmutables memory constants
    ) private view returns (
        uint32
    )    
    {
        return  uint32(block.timestamp) - constants.genesisTime >= TIME_DELTA_MAX
                    ? TIME_DELTA_MAX
                    : uint32(block.timestamp - constants.genesisTime);
    }

    function _lte(
        uint32 timeA,
        uint32 timeB
    ) private view returns (bool) {
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
        uint32  blockTimestamp,
        int24   tick,
        uint128 liquidity
    ) internal pure returns (
         RangePoolStructs.Sample memory
    ) {
        int56 timeDelta = int56(uint56(blockTimestamp - newSample.blockTimestamp));

        return
            PoolsharkStructs.Sample({
                blockTimestamp: blockTimestamp,
                tickSecondsAccum: newSample.tickSecondsAccum + int56(tick) * int32(timeDelta),
                secondsPerLiquidityAccum: newSample.secondsPerLiquidityAccum +
                    ((uint160(uint56(timeDelta)) << 128) / (liquidity > 0 ? liquidity : 1))
            });
    }

    function _binarySearch(
        IPool pool,
        uint32 targetTime,
        uint16 sampleIndex,
        uint16 sampleLength
    ) private view returns (
        RangePoolStructs.Sample memory firstSample,
        RangePoolStructs.Sample memory secondSample
    ) {
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
            bool targetAfterFirst   = _lte(firstSample.blockTimestamp, targetTime);
            bool targetBeforeSecond = _lte(targetTime, secondSample.blockTimestamp);
            if (targetAfterFirst && targetBeforeSecond) break;
            if (!targetAfterFirst) newIndex = index - 1;
            else oldIndex = index + 1;
        }
    }

    function _getAdjacentSamples(
        IPool pool,
        RangePoolStructs.Sample memory firstSample,
        RangePoolStructs.SampleParams memory params,
        uint32 targetTime
    ) private view returns (
        RangePoolStructs.Sample memory,
        RangePoolStructs.Sample memory
    ) {
        if (_lte(firstSample.blockTimestamp, targetTime)) {
            if (firstSample.blockTimestamp == targetTime) {
                return (firstSample, PoolsharkStructs.Sample(0,0,0));
            } else {
                return (firstSample, _build(firstSample, targetTime, params.tick, params.liquidity));
            }
        }
        firstSample = _poolSample(pool, (params.sampleIndex + 1) % params.sampleLength);
        if (firstSample.blockTimestamp == 0) {
            firstSample = _poolSample(pool, 0);
        }
        if(!_lte(firstSample.blockTimestamp, targetTime)) require(false, 'SampleLengthNotAvailable()');

        return _binarySearch(
            pool,
            targetTime,
            params.sampleIndex,
            params.sampleLength
        );
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import './math/ConstantProduct.sol';
import '../interfaces/structs/PoolsharkStructs.sol';

library TickMap {

    error TickIndexOverflow();
    error TickIndexUnderflow();
    error TickIndexBadSpacing();
    error BlockIndexOverflow();

    function get(
        PoolsharkStructs.TickMap storage tickMap,
        int24 tick,
        int24 tickSpacing
    ) internal view returns (
        bool exists
    ) {
        (
            uint256 tickIndex,
            uint256 wordIndex,
        ) = getIndices(tick, tickSpacing);

        // check if bit is already set
        uint256 word = tickMap.ticks[wordIndex] | 1 << (tickIndex & 0xFF);
        if (word == tickMap.ticks[wordIndex]) {
            return true;
        }
        return false;
    }

    function set(
        PoolsharkStructs.TickMap storage tickMap,
        int24 tick,
        int24 tickSpacing
    ) internal returns (
        bool exists
    ) {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        ) = getIndices(tick, tickSpacing);

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
        PoolsharkStructs.TickMap storage tickMap,
        int24 tick,
        int16 tickSpacing
    ) internal {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        ) = getIndices(tick, tickSpacing);

        tickMap.ticks[wordIndex] &= ~(1 << (tickIndex & 0xFF));
        if (tickMap.ticks[wordIndex] == 0) {
            tickMap.words[blockIndex] &= ~(1 << (wordIndex & 0xFF));
            if (tickMap.words[blockIndex] == 0) {
                tickMap.blocks &= ~(1 << blockIndex);
            }
        }
    }

    function previous(
        PoolsharkStructs.TickMap storage tickMap,
        int24 tick,
        int16 tickSpacing,
        bool inclusive
    ) internal view returns (
        int24 previousTick
    ) {
        unchecked {
            // rounds up to ensure relative position
            if (tick % (tickSpacing / 2) != 0 || inclusive) {
                if (tick < (ConstantProduct.maxTick(tickSpacing) - tickSpacing / 2)) {
                    /// @dev - ensures we cross when tick >= 0
                    if (tick >= 0) {
                        tick += tickSpacing / 2;
                    } else if (inclusive && tick % (tickSpacing / 2) == 0) {
                    /// @dev - ensures we cross when tick == tickAtPrice
                        tick += tickSpacing / 2;
                    }
                }
            }
            (
              uint256 tickIndex,
              uint256 wordIndex,
              uint256 blockIndex
            ) = getIndices(tick, tickSpacing);

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
            previousTick = _tick((wordIndex << 8) | _msb(word), tickSpacing);
        }
    }

    function next(
        PoolsharkStructs.TickMap storage tickMap,
        int24 tick,
        int16 tickSpacing,
        bool inclusive
    ) internal view returns (
        int24 nextTick
    ) {
        unchecked {
            /// @dev - handles tickAtPrice being past tickSpacing / 2
            if (inclusive && tick % tickSpacing != 0) {
                // e.g. tick is 5 we subtract 1 to look ahead at 5
                if (tick > 0 && (tick % tickSpacing <= (tickSpacing / 2)))
                    tick -= 1;
                // e.g. tick is -5 we subtract 1 to look ahead at -5
                else if (tick < 0 && (tick % tickSpacing <= -(tickSpacing / 2)))
                    tick -= 1;
                // e.g. tick = 7 and tickSpacing = 10 we sub 5 to look ahead at 5
                // e.g. tick = -2 and tickSpacing = 10 we sub 5 to look ahead at -5
                else
                    tick -= tickSpacing / 2;
            }
            /// @dev - handles negative ticks rounding up
            if (tick % (tickSpacing / 2) != 0) {
                if (tick < 0)
                    if (tick > (ConstantProduct.minTick(tickSpacing) + tickSpacing / 2))
                        tick -= tickSpacing / 2;
            }
            (
              uint256 tickIndex,
              uint256 wordIndex,
              uint256 blockIndex
            ) = getIndices(tick, tickSpacing);
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
            nextTick = _tick((wordIndex << 8) | _lsb(word), tickSpacing);
        }
    }

    function getIndices(
        int24 tick,
        int24 tickSpacing
    ) public pure returns (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        )
    {
        unchecked {
            if (tick > ConstantProduct.MAX_TICK) require(false, ' TickIndexOverflow()');
            if (tick < ConstantProduct.MIN_TICK) require(false, 'TickIndexUnderflow()');
            if (tick % (tickSpacing / 2) != 0) tick = round(tick, tickSpacing / 2);
            tickIndex = uint256(int256((round(tick, tickSpacing / 2) 
                                        - round(ConstantProduct.MIN_TICK, tickSpacing / 2)) 
                                        / (tickSpacing / 2)));
            wordIndex = tickIndex >> 8;   // 2^8 ticks per word
            blockIndex = tickIndex >> 16; // 2^8 words per block
            if (blockIndex > 255) require(false, 'BlockIndexOverflow()');
        }
    }



    function _tick (
        uint256 tickIndex,
        int24 tickSpacing
    ) internal pure returns (
        int24 tick
    ) {
        unchecked {
            if (tickIndex > uint24(round(ConstantProduct.MAX_TICK, tickSpacing) * 2) * 2) 
                require(false, 'TickIndexOverflow()');
            tick = int24(int256(tickIndex) * (tickSpacing / 2) + round(ConstantProduct.MIN_TICK, tickSpacing / 2));
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

    function round(
        int24 tick,
        int24 tickSpacing
    ) internal pure returns (
        int24 roundedTick
    ) {
        return tick / tickSpacing * tickSpacing;
    }

    function roundHalf(
        int24 tick,
        PoolsharkStructs.LimitImmutables memory constants,
        uint256 price
    ) internal pure returns (
        int24 roundedTick,
        uint160 roundedTickPrice
    ) {
        //pool.tickAtPrice -99.5
        //pool.tickAtPrice -100
        //-105
        //-95
        roundedTick = tick / constants.tickSpacing * constants.tickSpacing;
        roundedTickPrice = ConstantProduct.getPriceAtTick(roundedTick, constants);
        if (price == roundedTickPrice)
            return (roundedTick, roundedTickPrice);
        if (roundedTick > 0) {
            roundedTick += constants.tickSpacing / 2;
        } else if (roundedTick < 0) {
            if (roundedTickPrice < price)
                roundedTick += constants.tickSpacing / 2;
            else
                roundedTick -= constants.tickSpacing / 2;
        } else {
            if (price > roundedTickPrice) {
                roundedTick += constants.tickSpacing / 2;
            } else if (price < roundedTickPrice) {
                roundedTick -= constants.tickSpacing / 2;
            }
        }
    }

    function roundAhead(
        int24 tick,
        PoolsharkStructs.LimitImmutables memory constants,
        bool zeroForOne,
        uint256 price
    ) internal pure returns (
        int24 roundedTick
    ) {
        roundedTick = tick / constants.tickSpacing * constants.tickSpacing;
        uint160 roundedTickPrice = ConstantProduct.getPriceAtTick(roundedTick, constants);
        if (price == roundedTickPrice)
            return roundedTick;
        if (zeroForOne) {
            // round up if positive
            if (roundedTick > 0 || (roundedTick == 0 && tick >= 0))
                roundedTick += constants.tickSpacing;
            else if (tick % constants.tickSpacing == 0) {
                // handle price at -99.5 and tickAtPrice == -100
                if (tick < 0 && roundedTickPrice < price) {
                    roundedTick += constants.tickSpacing;
                }
            }
        } else {
            // round down if negative
            if (roundedTick < 0 || (roundedTick == 0 && tick < 0))
            /// @dev - strictly less due to TickMath always rounding to lesser values
                roundedTick -= constants.tickSpacing;
        }
    }

    function roundBack(
        int24 tick,
        PoolsharkStructs.LimitImmutables memory constants,
        bool zeroForOne,
        uint256 price
    ) internal pure returns (
        int24 roundedTick
    ) {
        roundedTick = tick / constants.tickSpacing * constants.tickSpacing;
        uint160 roundedTickPrice = ConstantProduct.getPriceAtTick(roundedTick, constants);
        if (price == roundedTickPrice)
            return roundedTick;
        if (zeroForOne) {
            // round down if negative
            if (roundedTick < 0 || (roundedTick == 0 && tick < 0))
                roundedTick -= constants.tickSpacing;
        } else {
            // round up if positive
            if (roundedTick > 0 || (roundedTick == 0 && tick >= 0))
                roundedTick += constants.tickSpacing;
            else if (tick % constants.tickSpacing == 0) {
                // handle price at -99.5 and tickAtPrice == -100
                if (tick < 0 && roundedTickPrice < price) {
                    roundedTick += constants.tickSpacing;
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        if((z = uint128(y)) != y) require(false, 'Uint256ToUint128:Overflow()');
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(int128 y) internal pure returns (uint128 z) {
        if(y < 0) require(false, 'Int128ToUint128:Underflow()');
        z = uint128(y);
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        if((z = uint160(y)) != y) require(false, 'Uint256ToUint160:Overflow()');
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint32(uint256 y) internal pure returns (uint32 z) {
        if((z = uint32(y)) != y) require(false, 'Uint256ToUint32:Overflow()');
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
        if(y > uint128(type(int128).max)) require(false, 'Uint128ToInt128:Overflow()');
        z = int128(y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        if(y > uint256(type(int256).max)) require(false, 'Uint256ToInt256:Overflow()');
        z = int256(y);
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint256(int256 y) internal pure returns (uint256 z) {
        if(y < 0) require(false, 'Int256ToUint256:Underflow()');
        z = uint256(y);
    }
}