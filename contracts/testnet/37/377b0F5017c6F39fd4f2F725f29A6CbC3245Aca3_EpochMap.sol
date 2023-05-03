// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../../interfaces/modules/sources/ITwapSource.sol';

interface CurveMathStructs {
    struct PriceBounds {
        uint160 min;
        uint160 max;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './modules/curves/ICurveMath.sol';
import './modules/sources/ITwapSource.sol';

interface ICoverPoolStructs {
    struct GlobalState {
        ProtocolFees protocolFees;
        uint160  latestPrice;      /// @dev price of latestTick
        uint128  liquidityGlobal;
        //uint32   genesisTime;      /// @dev reference time for which auctionStart is an offset of
        uint32   lastTime;         /// @dev last block checked
        uint32   auctionStart;     /// @dev last block price reference was updated
        uint32   accumEpoch;       /// @dev number of times this pool has been synced
        int24    latestTick;       /// @dev latest updated inputPool price tick
        uint16   syncFee;
        uint16   fillFee;
        //int16    tickSpread;       /// @dev this is a integer multiple of the inputPool tickSpacing
        //uint16   twapLength;       /// @dev number of blocks used for TWAP sampling
        //uint16   auctionLength;    /// @dev number of seconds to improve price by tickSpread
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
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) epochs; /// @dev - ticks to epochs
    }

    struct Tick {
        Deltas deltas;
        int128  liquidityDelta;
        uint128 amountInDeltaMaxMinus;
        uint128 amountOutDeltaMaxMinus;
        uint128 amountInDeltaMaxStashed;
        uint128 amountOutDeltaMaxStashed;
    }

    struct Deltas {
        uint128 amountInDelta;     // amt unfilled
        uint128 amountOutDelta;    // amt unfilled
        uint128 amountInDeltaMax;  // max unfilled 
        uint128 amountOutDeltaMax; // max unfilled
    }

    struct Position {
        uint160 claimPriceLast; // highest price claimed at
        uint128 liquidity; // expected amount to be used not actual
        uint128 amountIn; // token amount already claimed; balance
        uint128 amountOut; // necessary for non-custodial positions
        uint32  accumEpochLast;  // last epoch this position was updated at
    }

    struct Immutables {
        ICurveMath  curve;
        ITwapSource source;
        ICurveMath.PriceBounds bounds;
        address inputPool;
        uint256 minAmountPerAuction;
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

    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }

    struct SyncFees {
        uint128 token0;
        uint128 token1;
    }

    struct MintParams {
        address to;
        uint128 amount;
        int24 lower;
        int24 claim;
        int24 upper;
        bool zeroForOne;
    }

    struct BurnParams {
        address to;
        uint128 burnPercent;
        int24 lower;
        int24 claim;
        int24 upper;
        bool zeroForOne;
        bool sync;
    }

    struct SnapshotParams {
        address owner;
        uint128 burnPercent;
        int24 lower;
        int24 upper;
        int24 claim;
        bool zeroForOne;
    }

    struct CollectParams {
        SyncFees syncFees;
        address to;
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
        int24 lower;
        int24 claim;
        int24 upper;
        bool zeroForOne;
    }

    struct RemoveParams {
        address owner;
        address to;
        uint128 amount;
        int24 lower;
        int24 upper;
        bool zeroForOne;
    }

    struct UpdateParams {
        address owner;
        address to;
        uint128 amount;
        int24 lower;
        int24 upper;
        int24 claim;
        bool zeroForOne;
    }

    struct MintCache {
        GlobalState state;
        Position position;
        Immutables constants;
        SyncFees syncFees;
        uint256 liquidityMinted;
    }

    struct BurnCache {
        GlobalState state;
        Position position;
        Immutables constants;
        SyncFees syncFees;
    }

    struct SwapCache {
        GlobalState state;
        SyncFees syncFees;
        Immutables constants;
        uint256 price;
        uint256 liquidity;
        uint256 amountIn;
        uint256 input;
        uint256 output;
        uint256 inputBoosted;
        uint256 auctionDepth;
        uint256 auctionBoost;
        uint256 amountInDelta;
    }

    struct PositionCache {
        Position position;
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
        Position position;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './IDyDxMath.sol';
import './ITickMath.sol';

interface ICurveMath is 
    IDyDxMath,
    ITickMath
{}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../../../interfaces/ICoverPoolStructs.sol';
import '../../../base/structs/CurveMathStructs.sol';

interface IDyDxMath {
    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (
        uint256 dy
    );

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (
        uint256 dx
    );

    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) external pure returns (
        uint256 liquidity
    );

    function getAmountsForLiquidity(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 price,
        uint256 liquidity,
        bool roundUp
    ) external pure returns (
        uint128 token0amount,
        uint128 token1amount
    );

    function getNewPrice(
        uint256 price,
        uint256 liquidity,
        uint256 input,
        bool zeroForOne
    ) external pure returns (
        uint256 newPrice
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../../../interfaces/ICoverPoolStructs.sol';
import '../../../base/structs/CurveMathStructs.sol';

interface ITickMath {
    struct PriceBounds {
        uint160 min;
        uint160 max;
    }

    function getPriceAtTick(
        int24 tick,
        ICoverPoolStructs.Immutables memory
    ) external pure returns (
        uint160 price
    );

    function getTickAtPrice(
        uint160 price,
        ICoverPoolStructs.Immutables memory
    ) external view returns (
        int24 tick
    );

    function minTick(
        int16 tickSpacing
    ) external pure returns (
        int24 tick
    );

    function maxTick(
        int16 tickSpacing
    ) external pure returns (
        int24 tick
    );

    function minPrice(
        int16 tickSpacing
    ) external pure returns (
        uint160 minPrice
    );

    function maxPrice(
        int16 tickSpacing
    ) external pure returns (
        uint160 maxPrice
    );

    function checkTicks(
        int24 lower,
        int24 upper,
        int16 tickSpacing
    ) external pure;

    function checkPrice(
        uint160 price,
        PriceBounds memory bounds
    ) external pure;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../../ICoverPoolStructs.sol';

interface ITwapSource {
    function initialize(
        ICoverPoolStructs.Immutables memory constants
    ) external returns (
        uint8 initializable,
        int24 startingTick
    );

    function calculateAverageTick(
        ICoverPoolStructs.Immutables memory constants
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/ICoverPoolStructs.sol';

library EpochMap {
    function set(
        int24  tick,
        uint256 epoch,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        ) = getIndices(tick, constants);
        // assert epoch isn't bigger than max uint32
        uint256 epochValue = tickMap.epochs[volumeIndex][blockIndex][wordIndex];
        // clear previous value
        epochValue &=  ~(((1 << 9) - 1) << ((tickIndex & 0x7) * 32));
        // add new value to word
        epochValue |= epoch << ((tickIndex & 0x7) * 32);
        // store word in map
        tickMap.epochs[volumeIndex][blockIndex][wordIndex] = epochValue;
    }

    function unset(
        int24 tick,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        ) = getIndices(tick, constants);

        uint256 epochValue = tickMap.epochs[volumeIndex][blockIndex][wordIndex];
        // clear previous value
        epochValue &= ~(1 << (tickIndex & 0x7 * 32) - 1);
        // store word in map
        tickMap.epochs[volumeIndex][blockIndex][wordIndex] = epochValue;
    }

    function get(
        int24 tick,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        uint32 epoch
    ) {
        (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        ) = getIndices(tick, constants);

        uint256 epochValue = tickMap.epochs[volumeIndex][blockIndex][wordIndex];
        // right shift so first 8 bits are epoch value
        epochValue >>= ((tickIndex & 0x7) * 32);
        // clear other bits
        epochValue &= ((1 << 32) - 1);
        return uint32(epochValue);
    }

    function getIndices(
        int24 tick,
        ICoverPoolStructs.Immutables memory constants
    ) public pure returns (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex,
            uint256 volumeIndex
        )
    {
        unchecked {
            if (tick > constants.curve.maxTick(constants.tickSpread)) require (false, 'TickIndexOverflow()');
            if (tick < constants.curve.minTick(constants.tickSpread)) require (false, 'TickIndexUnderflow()');
            if (tick % constants.tickSpread != 0) require (false, 'TickIndexInvalid()');
            tickIndex = uint256(int256((tick - constants.curve.minTick(constants.tickSpread))) / constants.tickSpread);
            wordIndex = tickIndex >> 3;        // 2^3 epochs per word
            blockIndex = tickIndex >> 11;      // 2^8 words per block
            volumeIndex = tickIndex >> 19;     // 2^8 blocks per volume
            if (blockIndex > 1023) require (false, 'BlockIndexOverflow()');
        }
    }

    function _tick (
        uint256 tickIndex,
        ICoverPoolStructs.Immutables memory constants
    ) internal pure returns (
        int24 tick
    ) {
        unchecked {
            if (tickIndex > uint24(constants.curve.maxTick(constants.tickSpread) * 2)) require (false, 'TickIndexOverflow()');
            tick = int24(int256(tickIndex) * int256(constants.tickSpread) + constants.curve.maxTick(constants.tickSpread));
        }
    }
}