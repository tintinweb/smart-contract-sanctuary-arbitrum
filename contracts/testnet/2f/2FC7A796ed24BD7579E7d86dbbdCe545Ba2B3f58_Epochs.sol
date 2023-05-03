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

library Deltas {

    function max(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool   isPool0,
        ICurveMath curve
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? curve.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : curve.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? curve.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : curve.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
    }

    function maxRoundUp(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool   isPool0,
        ICurveMath curve
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? curve.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
                : curve.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? curve.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
                : curve.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
        );
    }

    function maxAuction(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool isPool0,
        ICurveMath curve
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? curve.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
                : curve.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? curve.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
                : curve.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
        );
    }

    function transfer(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Deltas memory toDeltas,
        uint256 percentInTransfer,
        uint256 percentOutTransfer
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Deltas memory
    ) {
        {
            uint128 amountInDeltaChange = uint128(uint256(fromDeltas.amountInDelta) * percentInTransfer / 1e38);
            if (amountInDeltaChange < fromDeltas.amountInDelta ) {
                fromDeltas.amountInDelta -= amountInDeltaChange;
                toDeltas.amountInDelta += amountInDeltaChange;
            } else {
                toDeltas.amountInDelta += fromDeltas.amountInDelta;
                fromDeltas.amountInDelta = 0;
            }
        }
        {
            uint128 amountOutDeltaChange = uint128(uint256(fromDeltas.amountOutDelta) * percentOutTransfer / 1e38);
            if (amountOutDeltaChange < fromDeltas.amountOutDelta ) {
                fromDeltas.amountOutDelta -= amountOutDeltaChange;
                toDeltas.amountOutDelta += amountOutDeltaChange;
            } else {
                toDeltas.amountOutDelta += fromDeltas.amountOutDelta;
                fromDeltas.amountOutDelta = 0;
            }
        }
        return (fromDeltas, toDeltas);
    }

    function transferMax(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Deltas memory toDeltas,
        uint256 percentInTransfer,
        uint256 percentOutTransfer
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Deltas memory
    ) {
        {
            uint128 amountInDeltaMaxChange = uint128(uint256(fromDeltas.amountInDeltaMax) * percentInTransfer / 1e38);
            if (fromDeltas.amountInDeltaMax > amountInDeltaMaxChange) {
                fromDeltas.amountInDeltaMax -= amountInDeltaMaxChange;
                toDeltas.amountInDeltaMax += amountInDeltaMaxChange;
            } else {
                toDeltas.amountInDeltaMax += fromDeltas.amountInDeltaMax;
                fromDeltas.amountInDeltaMax = 0;
            }
        }
        {
            uint128 amountOutDeltaMaxChange = uint128(uint256(fromDeltas.amountOutDeltaMax) * percentOutTransfer / 1e38);
            if (fromDeltas.amountOutDeltaMax > amountOutDeltaMaxChange) {
                fromDeltas.amountOutDeltaMax -= amountOutDeltaMaxChange;
                toDeltas.amountOutDeltaMax   += amountOutDeltaMaxChange;
            } else {
                toDeltas.amountOutDeltaMax += fromDeltas.amountOutDeltaMax;
                fromDeltas.amountOutDeltaMax = 0;
            }
        }
        return (fromDeltas, toDeltas);
    }

    function burnMaxCache(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory burnTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory
    ) {
        fromDeltas.amountInDeltaMax -= (fromDeltas.amountInDeltaMax 
                                         < burnTick.amountInDeltaMaxMinus) ? fromDeltas.amountInDeltaMax
                                                                           : burnTick.amountInDeltaMaxMinus;
        if (fromDeltas.amountInDeltaMax == 1) {
            fromDeltas.amountInDeltaMax = 0; // handle rounding issues
        }
        fromDeltas.amountOutDeltaMax -= (fromDeltas.amountOutDeltaMax 
                                          < burnTick.amountOutDeltaMaxMinus) ? fromDeltas.amountOutDeltaMax
                                                                             : burnTick.amountOutDeltaMaxMinus;
        return fromDeltas;
    }

    function burnMaxMinus(
        ICoverPoolStructs.Tick memory fromTick,
        ICoverPoolStructs.Deltas memory burnDeltas
    ) external pure returns (
        ICoverPoolStructs.Tick memory
    ) {
        fromTick.amountInDeltaMaxMinus -= (fromTick.amountInDeltaMaxMinus
                                            < burnDeltas.amountInDeltaMax) ? fromTick.amountInDeltaMaxMinus
                                                                           : burnDeltas.amountInDeltaMax;
        if (fromTick.amountInDeltaMaxMinus == 1) {
            fromTick.amountInDeltaMaxMinus = 0; // handle rounding issues
        }
        fromTick.amountOutDeltaMaxMinus -= (fromTick.amountOutDeltaMaxMinus 
                                             < burnDeltas.amountOutDeltaMax) ? fromTick.amountOutDeltaMaxMinus
                                                                                  : burnDeltas.amountOutDeltaMax;
        return fromTick;
    }

    function burnMaxPool(
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICurveMath curve
    ) external pure returns (
        ICoverPoolStructs.PoolState memory
    )
    {
        uint128 amountInMaxClaimedBefore; uint128 amountOutMaxClaimedBefore;
        (
            amountInMaxClaimedBefore,
            amountOutMaxClaimedBefore
        ) = maxAuction(
            params.amount,
            cache.priceSpread,
            cache.position.claimPriceLast,
            params.zeroForOne,
            curve
        );
        pool.amountInDeltaMaxClaimed  -= pool.amountInDeltaMaxClaimed > amountInMaxClaimedBefore ? amountInMaxClaimedBefore
                                                                                                 : pool.amountInDeltaMaxClaimed;
        pool.amountOutDeltaMaxClaimed -= pool.amountOutDeltaMaxClaimed > amountOutMaxClaimedBefore ? amountOutMaxClaimedBefore
                                                                                                   : pool.amountOutDeltaMaxClaimed;
        return pool;
    }

    function from(
        ICoverPoolStructs.Tick memory fromTick,
        ICoverPoolStructs.Deltas memory toDeltas
    ) external pure returns (
        ICoverPoolStructs.Tick memory,
        ICoverPoolStructs.Deltas memory
    ) {
        uint256 percentOnTick = uint256(fromTick.deltas.amountInDeltaMax) * 1e38 / (uint256(fromTick.deltas.amountInDeltaMax) + uint256(fromTick.amountInDeltaMaxStashed));
        {
            uint128 amountInDeltaChange = uint128(uint256(fromTick.deltas.amountInDelta) * percentOnTick / 1e38);
            fromTick.deltas.amountInDelta -= amountInDeltaChange;
            toDeltas.amountInDelta += amountInDeltaChange;
            toDeltas.amountInDeltaMax += fromTick.deltas.amountInDeltaMax;
            fromTick.deltas.amountInDeltaMax = 0;
        }
        percentOnTick = uint256(fromTick.deltas.amountOutDeltaMax) * 1e38 / (uint256(fromTick.deltas.amountOutDeltaMax) + uint256(fromTick.amountOutDeltaMaxStashed));
        {
            uint128 amountOutDeltaChange = uint128(uint256(fromTick.deltas.amountOutDelta) * percentOnTick / 1e38);
            fromTick.deltas.amountOutDelta -= amountOutDeltaChange;
            toDeltas.amountOutDelta += amountOutDeltaChange;
            toDeltas.amountOutDeltaMax += fromTick.deltas.amountOutDeltaMax;
            fromTick.deltas.amountOutDeltaMax = 0;
        }
        return (fromTick, toDeltas);
    }

    function to(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory toTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Tick memory
    ) {
        toTick.deltas.amountInDelta     += fromDeltas.amountInDelta;
        toTick.deltas.amountInDeltaMax  += fromDeltas.amountInDeltaMax;
        toTick.deltas.amountOutDelta    += fromDeltas.amountOutDelta;
        toTick.deltas.amountOutDeltaMax += fromDeltas.amountOutDeltaMax;
        fromDeltas = ICoverPoolStructs.Deltas(0,0,0,0);
        return (fromDeltas, toTick);
    }

    function stash(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory toTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Tick memory
    ) {
        // store deltas on tick
        toTick.deltas.amountInDelta     += fromDeltas.amountInDelta;
        toTick.deltas.amountOutDelta    += fromDeltas.amountOutDelta;
        // store delta maxes on stashed deltas
        toTick.amountInDeltaMaxStashed  += fromDeltas.amountInDeltaMax;
        toTick.amountOutDeltaMaxStashed += fromDeltas.amountOutDeltaMax;
        fromDeltas = ICoverPoolStructs.Deltas(0,0,0,0);
        return (fromDeltas, toTick);
    }

    function unstash(
        ICoverPoolStructs.Tick memory fromTick,
        ICoverPoolStructs.Deltas memory toDeltas
    ) external pure returns (
        ICoverPoolStructs.Tick memory,
        ICoverPoolStructs.Deltas memory
    ) {
        toDeltas.amountInDeltaMax  += fromTick.amountInDeltaMaxStashed;
        toDeltas.amountOutDeltaMax += fromTick.amountOutDeltaMaxStashed;
        
        uint256 totalDeltaMax = uint256(fromTick.amountInDeltaMaxStashed) + uint256(fromTick.deltas.amountInDeltaMax);
        
        if (totalDeltaMax > 0) {
            uint256 percentStashed = uint256(fromTick.amountInDeltaMaxStashed) * 1e38 / totalDeltaMax;
            uint128 amountInDeltaChange = uint128(uint256(fromTick.deltas.amountInDelta) * percentStashed / 1e38);
            fromTick.deltas.amountInDelta -= amountInDeltaChange;
            toDeltas.amountInDelta += amountInDeltaChange;
        }
        
        totalDeltaMax = uint256(fromTick.amountOutDeltaMaxStashed) + uint256(fromTick.deltas.amountOutDeltaMax);
        
        if (totalDeltaMax > 0) {
            uint256 percentStashed = uint256(fromTick.amountOutDeltaMaxStashed) * 1e38 / totalDeltaMax;
            uint128 amountOutDeltaChange = uint128(uint256(fromTick.deltas.amountOutDelta) * percentStashed / 1e38);
            fromTick.deltas.amountOutDelta -= amountOutDeltaChange;
            toDeltas.amountOutDelta += amountOutDeltaChange;
        }

        fromTick.amountInDeltaMaxStashed = 0;
        fromTick.amountOutDeltaMaxStashed = 0;
        return (fromTick, toDeltas);
    }

    function update(
        ICoverPoolStructs.Tick memory tick,
        uint128 amount,
        uint160 priceLower,
        uint160 priceUpper,
        bool   isPool0,
        bool   isAdded,
        ICurveMath curve
    ) external pure returns (
        ICoverPoolStructs.Tick memory,
        ICoverPoolStructs.Deltas memory
    ) {
        // update max deltas
        uint128 amountInDeltaMax; uint128 amountOutDeltaMax;
        if (isPool0) {
            (
                amountInDeltaMax,
                amountOutDeltaMax
            ) = max(amount, priceUpper, priceLower, true, curve);
        } else {
            (
                amountInDeltaMax,
                amountOutDeltaMax
            ) = max(amount, priceLower, priceUpper, false, curve);
        }
        if (isAdded) {
            tick.amountInDeltaMaxMinus  += amountInDeltaMax;
            tick.amountOutDeltaMaxMinus += amountOutDeltaMax;
        } else {
            tick.amountInDeltaMaxMinus  -= tick.amountInDeltaMaxMinus  > amountInDeltaMax ? amountInDeltaMax
                                                                                          : tick.amountInDeltaMaxMinus;
            tick.amountOutDeltaMaxMinus -= tick.amountOutDeltaMaxMinus > amountOutDeltaMax ? amountOutDeltaMax                                                                           : tick.amountOutDeltaMaxMinus;
        }
        return (tick, ICoverPoolStructs.Deltas(0,0,amountInDeltaMax, amountOutDeltaMax));
    }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/modules/sources/ITwapSource.sol';
import '../interfaces/ICoverPoolStructs.sol';
import './Deltas.sol';
import './TickMap.sol';
import './EpochMap.sol';

library Epochs {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    event Sync(
        uint160 pool0Price,
        uint160 pool1Price,
        uint128 pool0Liquidity,
        uint128 pool1Liquidity,
        uint32 auctionStart,
        uint32 accumEpoch,
        int24 oldLatestTick,
        int24 newLatestTick
    );

    event FinalDeltasAccumulated(
        uint128 amountInDelta,
        uint128 amountOutDelta,
        uint32 accumEpoch,
        int24 accumTick,
        bool isPool0
    );

    event StashDeltasCleared(
        int24 stashTick,
        bool isPool0
    );

    event StashDeltasAccumulated(
        uint128 amountInDelta,
        uint128 amountOutDelta,
        uint128 amountInDeltaMaxStashed,
        uint128 amountOutDeltaMaxStashed,
        uint32 accumEpoch,
        int24 stashTick,
        bool isPool0
    );

    event SyncFeesCollected(
        address collector,
        uint128 token0Amount,
        uint128 token1Amount
    );

    function simulateSync(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks0,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks1,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.PoolState memory pool0,
        ICoverPoolStructs.PoolState memory pool1,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        ICoverPoolStructs.GlobalState memory,
        ICoverPoolStructs.SyncFees memory,
        ICoverPoolStructs.PoolState memory,
        ICoverPoolStructs.PoolState memory
    ) {
        ICoverPoolStructs.AccumulateCache memory cache;
        {
            bool earlyReturn;
            (cache.newLatestTick, earlyReturn) = _syncTick(state, constants);
            if (earlyReturn) {
                return (state, ICoverPoolStructs.SyncFees(0, 0), pool0, pool1);
            }
            // else we have a TWAP update
        }

        // setup cache
        cache = ICoverPoolStructs.AccumulateCache({
            deltas0: ICoverPoolStructs.Deltas(0, 0, 0, 0), // deltas for pool0
            deltas1: ICoverPoolStructs.Deltas(0, 0, 0, 0),  // deltas for pool1
            syncFees: ICoverPoolStructs.SyncFees(0, 0),
            newLatestTick: cache.newLatestTick,
            nextTickToCross0: state.latestTick, // above
            nextTickToCross1: state.latestTick, // below
            nextTickToAccum0: TickMap.previous(state.latestTick, tickMap, constants), // below
            nextTickToAccum1: TickMap.next(state.latestTick, tickMap, constants),     // above
            stopTick0: (cache.newLatestTick > state.latestTick) // where we do stop for pool0 sync
                ? state.latestTick - constants.tickSpread
                : cache.newLatestTick, 
            stopTick1: (cache.newLatestTick > state.latestTick) // where we do stop for pool1 sync
                ? cache.newLatestTick
                : state.latestTick + constants.tickSpread
        });

        while (true) {
            // rollover and calculate sync fees
            (cache, pool0) = _rollover(state, cache, pool0, constants, true);
            // keep looping until accumulation reaches stopTick0 
            if (cache.nextTickToAccum0 >= cache.stopTick0) {
                (pool0.liquidity, cache.nextTickToCross0, cache.nextTickToAccum0) = _cross(
                    ticks0[cache.nextTickToAccum0].liquidityDelta,
                    tickMap,
                    constants,
                    cache.nextTickToCross0,
                    cache.nextTickToAccum0,
                    pool0.liquidity,
                    true
                );
            } else break;
        }

        while (true) {
            (cache, pool1) = _rollover(state, cache, pool1, constants, false);
            // keep looping until accumulation reaches stopTick1 
            if (cache.nextTickToAccum1 <= cache.stopTick1) {
                (pool1.liquidity, cache.nextTickToCross1, cache.nextTickToAccum1) = _cross(
                    ticks1[cache.nextTickToAccum1].liquidityDelta,
                    tickMap,
                    constants,
                    cache.nextTickToCross1,
                    cache.nextTickToAccum1,
                    pool1.liquidity,
                    false
                );
            } else break;
        }

        // update ending pool price for fully filled auction
        state.latestPrice = constants.curve.getPriceAtTick(cache.newLatestTick, constants);
        
        // set pool price and liquidity
        if (cache.newLatestTick > state.latestTick) {
            pool0.liquidity = 0;
            pool0.price = state.latestPrice;
            pool1.price = constants.curve.getPriceAtTick(cache.newLatestTick + constants.tickSpread, constants);
        } else {
            pool1.liquidity = 0;
            pool0.price = constants.curve.getPriceAtTick(cache.newLatestTick - constants.tickSpread, constants);
            pool1.price = state.latestPrice;
        }
        
        // set auction start as an offset of the pool genesis block
        state.auctionStart = uint32(block.timestamp) - constants.genesisTime;
        state.latestTick = cache.newLatestTick;
    
        return (state, cache.syncFees, pool0, pool1);
    }

    function syncLatest(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks0,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks1,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.PoolState memory pool0,
        ICoverPoolStructs.PoolState memory pool1,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants
    ) external returns (
        ICoverPoolStructs.GlobalState memory,
        ICoverPoolStructs.SyncFees memory,
        ICoverPoolStructs.PoolState memory,
        ICoverPoolStructs.PoolState memory
    )
    {
        ICoverPoolStructs.AccumulateCache memory cache;
        {
            bool earlyReturn;
            (cache.newLatestTick, earlyReturn) = _syncTick(state, constants);
            if (earlyReturn) {
                return (state, ICoverPoolStructs.SyncFees(0,0), pool0, pool1);
            }
            // else we have a TWAP update
        }

        // increase epoch counter
        state.accumEpoch += 1;

        // setup cache
        cache = ICoverPoolStructs.AccumulateCache({
            deltas0: ICoverPoolStructs.Deltas(0, 0, 0, 0), // deltas for pool0
            deltas1: ICoverPoolStructs.Deltas(0, 0, 0, 0),  // deltas for pool1
            syncFees: ICoverPoolStructs.SyncFees(0,0),
                newLatestTick: cache.newLatestTick,
            nextTickToCross0: state.latestTick, // above
            nextTickToCross1: state.latestTick, // below
            nextTickToAccum0: TickMap.previous(state.latestTick, tickMap, constants), // below
            nextTickToAccum1: TickMap.next(state.latestTick, tickMap, constants),     // above
            stopTick0: (cache.newLatestTick > state.latestTick) // where we do stop for pool0 sync
                ? state.latestTick - constants.tickSpread
                : cache.newLatestTick, 
            stopTick1: (cache.newLatestTick > state.latestTick) // where we do stop for pool1 sync
                ? cache.newLatestTick
                : state.latestTick + constants.tickSpread
        });

        while (true) {
            // get values from current auction
            (cache, pool0) = _rollover(state, cache, pool0, constants, true);
            if (cache.nextTickToAccum0 > cache.stopTick0 
                 && ticks0[cache.nextTickToAccum0].amountInDeltaMaxMinus > 0) {
                EpochMap.set(cache.nextTickToAccum0, state.accumEpoch, tickMap, constants);
            }
            // accumulate to next tick
            ICoverPoolStructs.AccumulateParams memory params = ICoverPoolStructs.AccumulateParams({
                deltas: cache.deltas0,
                crossTick: ticks0[cache.nextTickToCross0],
                accumTick: ticks0[cache.nextTickToAccum0],
                updateAccumDeltas: cache.newLatestTick > state.latestTick
                                            ? cache.nextTickToAccum0 == cache.stopTick0
                                            : cache.nextTickToAccum0 >= cache.stopTick0,
                isPool0: true
            });
            params = _accumulate(
                cache,
                params,
                state
            );
            /// @dev - deltas in cache updated after _accumulate
            cache.deltas0 = params.deltas;
            ticks0[cache.nextTickToCross0] = params.crossTick;
            ticks0[cache.nextTickToAccum0] = params.accumTick;
            
            // keep looping until accumulation reaches stopTick0 
            if (cache.nextTickToAccum0 >= cache.stopTick0) {
                (pool0.liquidity, cache.nextTickToCross0, cache.nextTickToAccum0) = _cross(
                    ticks0[cache.nextTickToAccum0].liquidityDelta,
                    tickMap,
                    constants,
                    cache.nextTickToCross0,
                    cache.nextTickToAccum0,
                    pool0.liquidity,
                    true
                );
            } else break;
        }
        // pool0 checkpoint
        {
            // create stopTick0 if necessary
            if (cache.nextTickToAccum0 != cache.stopTick0) {
                TickMap.set(cache.stopTick0, tickMap, constants);
            }
            ICoverPoolStructs.Tick memory stopTick0 = ticks0[cache.stopTick0];
            // checkpoint at stopTick0
            (stopTick0) = _stash(
                stopTick0,
                cache,
                state,
                pool0.liquidity,
                true
            );
            EpochMap.set(cache.stopTick0, state.accumEpoch, tickMap, constants);
            ticks0[cache.stopTick0] = stopTick0;
        }

        while (true) {
            // rollover deltas pool1
            (cache, pool1) = _rollover(state, cache, pool1, constants, false);
            // accumulate deltas pool1
            if (cache.nextTickToAccum1 < cache.stopTick1 
                 && ticks1[cache.nextTickToAccum1].amountInDeltaMaxMinus > 0) {
                EpochMap.set(cache.nextTickToAccum1, state.accumEpoch, tickMap, constants);
            }
            {
                ICoverPoolStructs.AccumulateParams memory params = ICoverPoolStructs.AccumulateParams({
                    deltas: cache.deltas1,
                    crossTick: ticks1[cache.nextTickToCross1],
                    accumTick: ticks1[cache.nextTickToAccum1],
                    updateAccumDeltas: cache.newLatestTick > state.latestTick
                                                ? cache.nextTickToAccum1 <= cache.stopTick1
                                                : cache.nextTickToAccum1 == cache.stopTick1,
                    isPool0: false
                });
                params = _accumulate(
                    cache,
                    params,
                    state
                );
                /// @dev - deltas in cache updated after _accumulate
                cache.deltas1 = params.deltas;
                ticks1[cache.nextTickToCross1] = params.crossTick;
                ticks1[cache.nextTickToAccum1] = params.accumTick;
            }
            // keep looping until accumulation reaches stopTick1 
            if (cache.nextTickToAccum1 <= cache.stopTick1) {
                (pool1.liquidity, cache.nextTickToCross1, cache.nextTickToAccum1) = _cross(
                    ticks1[cache.nextTickToAccum1].liquidityDelta,
                    tickMap,
                    constants,
                    cache.nextTickToCross1,
                    cache.nextTickToAccum1,
                    pool1.liquidity,
                    false
                );
            } else break;
        }
        // pool1 checkpoint
        {
            // create stopTick1 if necessary
            if (cache.nextTickToAccum1 != cache.stopTick1) {
                TickMap.set(cache.stopTick1, tickMap, constants);
            }
            ICoverPoolStructs.Tick memory stopTick1 = ticks1[cache.stopTick1];
            // update deltas on stopTick
            (stopTick1) = _stash(
                stopTick1,
                cache,
                state,
                pool1.liquidity,
                false
            );
            ticks1[cache.stopTick1] = stopTick1;
            EpochMap.set(cache.stopTick1, state.accumEpoch, tickMap, constants);
        }
        // update ending pool price for fully filled auction
        state.latestPrice = constants.curve.getPriceAtTick(cache.newLatestTick, constants);
        
        // set pool price and liquidity
        if (cache.newLatestTick > state.latestTick) {
            pool0.liquidity = 0;
            pool0.price = state.latestPrice;
            pool1.price = constants.curve.getPriceAtTick(cache.newLatestTick + constants.tickSpread, constants);
        } else {
            pool1.liquidity = 0;
            pool0.price = constants.curve.getPriceAtTick(cache.newLatestTick - constants.tickSpread, constants);
            pool1.price = state.latestPrice;
        }
        
        // set auction start as an offset of the pool genesis block
        state.auctionStart = uint32(block.timestamp) - constants.genesisTime;

        // emit sync event
        emit Sync(pool0.price, pool1.price, pool0.liquidity, pool1.liquidity, state.auctionStart, state.accumEpoch, state.latestTick, cache.newLatestTick);
        
        // update latestTick
        state.latestTick = cache.newLatestTick;

        if (cache.syncFees.token0 > 0 || cache.syncFees.token1 > 0) {
            emit SyncFeesCollected(msg.sender, cache.syncFees.token0, cache.syncFees.token1);
        }
    
        return (state, cache.syncFees, pool0, pool1);
    }

    function _syncTick(
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants
    ) internal view returns(
        int24 newLatestTick,
        bool
    ) {
        // update last block checked
        if(state.lastTime == uint32(block.timestamp) - constants.genesisTime) {
            return (state.latestTick, true);
        }
        state.lastTime = uint32(block.timestamp) - constants.genesisTime;
        // check auctions elapsed
        uint32 timeElapsed = state.lastTime - state.auctionStart;
        int32 auctionsElapsed = int32(timeElapsed / constants.twapLength) - 1; /// @dev - subtract 1 for 3/4 twapLength check
        // if 3/4 of twapLength has passed allow for latestTick move
        if (timeElapsed > 3 * constants.twapLength / 4) auctionsElapsed += 1;

        if (auctionsElapsed < 1) {
            return (state.latestTick, true);
        }
        newLatestTick = constants.source.calculateAverageTick(constants);
        /// @dev - shift up/down one quartile to put pool ahead of TWAP
        if (newLatestTick > state.latestTick)
             newLatestTick += constants.tickSpread / 4;
        else if (newLatestTick <= state.latestTick - 3 * constants.tickSpread / 4)
             newLatestTick -= constants.tickSpread / 4;
        newLatestTick = newLatestTick / constants.tickSpread * constants.tickSpread; // even multiple of tickSpread
        if (newLatestTick == state.latestTick) {
            return (state.latestTick, true);
        }

        // rate-limiting tick move
        int24 maxLatestTickMove = int24(constants.tickSpread * auctionsElapsed);

        /// @dev - latestTick can only move based on auctionsElapsed 
        if (newLatestTick > state.latestTick) {
            if (newLatestTick - state.latestTick > maxLatestTickMove)
                newLatestTick = state.latestTick + maxLatestTickMove;
        } else {
            if (state.latestTick - newLatestTick > maxLatestTickMove)
                newLatestTick = state.latestTick - maxLatestTickMove;
        }

        return (newLatestTick, false);
    }

    function _rollover(
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.AccumulateCache memory cache,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.Immutables memory constants,
        bool isPool0
    ) internal pure returns (
        ICoverPoolStructs.AccumulateCache memory,
        ICoverPoolStructs.PoolState memory
    ) {
        //TODO: add syncing fee
        if (pool.liquidity == 0) {
            return (cache, pool);
        }
        uint160 crossPrice; uint160 accumPrice; uint160 currentPrice;
        if (isPool0) {
            crossPrice = constants.curve.getPriceAtTick(cache.nextTickToCross0, constants);
            int24 nextTickToAccum = (cache.nextTickToAccum0 < cache.stopTick0)
                                        ? cache.stopTick0
                                        : cache.nextTickToAccum0;
            accumPrice = constants.curve.getPriceAtTick(nextTickToAccum, constants);
            // check for multiple auction skips
            if (cache.nextTickToCross0 == state.latestTick && cache.nextTickToCross0 - nextTickToAccum > constants.tickSpread) {
                uint160 spreadPrice = constants.curve.getPriceAtTick(cache.nextTickToCross0 - constants.tickSpread, constants);
                /// @dev - amountOutDeltaMax accounted for down below
                cache.deltas0.amountOutDelta += uint128(constants.curve.getDx(pool.liquidity, accumPrice, spreadPrice, false));
            }
            currentPrice = pool.price;
            // if pool.price the bounds set currentPrice to start of auction
            if (!(pool.price > accumPrice && pool.price < crossPrice)) currentPrice = accumPrice;
            // if auction is current and fully filled => set currentPrice to crossPrice
            if (state.latestTick == cache.nextTickToCross0 && crossPrice == pool.price) currentPrice = crossPrice;
        } else {
            crossPrice = constants.curve.getPriceAtTick(cache.nextTickToCross1, constants);
            int24 nextTickToAccum = (cache.nextTickToAccum1 > cache.stopTick1)
                                        ? cache.stopTick1
                                        : cache.nextTickToAccum1;
            accumPrice = constants.curve.getPriceAtTick(nextTickToAccum, constants);
            // check for multiple auction skips
            if (cache.nextTickToCross1 == state.latestTick && nextTickToAccum - cache.nextTickToCross1 > constants.tickSpread) {
                uint160 spreadPrice = constants.curve.getPriceAtTick(cache.nextTickToCross1 + constants.tickSpread, constants);
                /// @dev - DeltaMax values accounted for down below
                cache.deltas1.amountOutDelta += uint128(constants.curve.getDy(pool.liquidity, spreadPrice, accumPrice, false));
            }
            currentPrice = pool.price;
            if (!(pool.price < accumPrice && pool.price > crossPrice)) currentPrice = accumPrice;
            if (state.latestTick == cache.nextTickToCross1 && crossPrice == pool.price) currentPrice = crossPrice;
        }

        //handle liquidity rollover
        if (isPool0) {
            {
                // amountIn pool did not receive
                uint128 amountInDelta;
                uint128 amountInDeltaMax  = uint128(constants.curve.getDy(pool.liquidity, accumPrice, crossPrice, false));
                amountInDelta       = pool.amountInDelta;
                amountInDeltaMax   -= (amountInDeltaMax < pool.amountInDeltaMaxClaimed) ? amountInDeltaMax 
                                                                                        : pool.amountInDeltaMaxClaimed;
                pool.amountInDelta  = 0;
                pool.amountInDeltaMaxClaimed = 0;

                // update cache in deltas
                cache.deltas0.amountInDelta     += amountInDelta;
                cache.deltas0.amountInDeltaMax  += amountInDeltaMax;
            }
            {
                // amountOut pool has leftover
                uint128 amountOutDelta    = uint128(constants.curve.getDx(pool.liquidity, currentPrice, crossPrice, false));
                uint128 amountOutDeltaMax = uint128(constants.curve.getDx(pool.liquidity, accumPrice, crossPrice, false));
                amountOutDeltaMax -= (amountOutDeltaMax < pool.amountOutDeltaMaxClaimed) ? amountOutDeltaMax
                                                                                        : pool.amountOutDeltaMaxClaimed;
                pool.amountOutDeltaMaxClaimed = 0;

                // calculate sync fee
                uint128 syncFeeAmount = state.syncFee * amountOutDelta / 1e6;
                cache.syncFees.token0 += syncFeeAmount;
                amountOutDelta -= syncFeeAmount;

                // update cache out deltas
                cache.deltas0.amountOutDelta    += amountOutDelta;
                cache.deltas0.amountOutDeltaMax += amountOutDeltaMax;
            }
        } else {
            {
                // amountIn pool did not receive
                uint128 amountInDelta;
                uint128 amountInDeltaMax = uint128(constants.curve.getDx(pool.liquidity, crossPrice, accumPrice, false));
                amountInDelta       = pool.amountInDelta;
                amountInDeltaMax   -= (amountInDeltaMax < pool.amountInDeltaMaxClaimed) ? amountInDeltaMax 
                                                                                        : pool.amountInDeltaMaxClaimed;
                pool.amountInDelta  = 0;
                pool.amountInDeltaMaxClaimed = 0;

                // update cache in deltas
                cache.deltas1.amountInDelta     += amountInDelta;
                cache.deltas1.amountInDeltaMax  += amountInDeltaMax;
            }
            {
                // amountOut pool has leftover
                uint128 amountOutDelta    = uint128(constants.curve.getDy(pool.liquidity, crossPrice, currentPrice, false));
                uint128 amountOutDeltaMax = uint128(constants.curve.getDy(pool.liquidity, crossPrice, accumPrice, false));
                amountOutDeltaMax -= (amountOutDeltaMax < pool.amountOutDeltaMaxClaimed) ? amountOutDeltaMax
                                                                                        : pool.amountOutDeltaMaxClaimed;
                pool.amountOutDeltaMaxClaimed = 0;

                // calculate sync fee
                uint128 syncFeeAmount = state.syncFee * amountOutDelta / 1e6;
                cache.syncFees.token1 += syncFeeAmount;
                amountOutDelta -= syncFeeAmount;    

                // update cache out deltas
                cache.deltas1.amountOutDelta    += amountOutDelta;
                cache.deltas1.amountOutDeltaMax += amountOutDeltaMax;
            }
        }
        return (cache, pool);
    }

    function _accumulate(
        ICoverPoolStructs.AccumulateCache memory cache,
        ICoverPoolStructs.AccumulateParams memory params,
        ICoverPoolStructs.GlobalState memory state
    ) internal returns (
        ICoverPoolStructs.AccumulateParams memory
    ) {
        if (params.crossTick.amountInDeltaMaxStashed > 0) {
            /// @dev - else we migrate carry deltas onto cache
            // add carry amounts to cache
            (params.crossTick, params.deltas) = Deltas.unstash(params.crossTick, params.deltas);
            // clear out stash
            params.crossTick.amountInDeltaMaxStashed  = 0;
            params.crossTick.amountOutDeltaMaxStashed = 0;
            emit StashDeltasCleared(
                params.isPool0 ? cache.nextTickToCross0 : cache.nextTickToCross1,
                params.isPool0
            );
        }
        if (params.updateAccumDeltas) {
            // migrate carry deltas from cache to accum tick
            ICoverPoolStructs.Deltas memory accumDeltas;
            if (params.accumTick.amountInDeltaMaxMinus > 0) {
                // calculate percent of deltas left on tick
                uint256 percentInOnTick  = uint256(params.accumTick.amountInDeltaMaxMinus)  * 1e38 / (params.deltas.amountInDeltaMax);
                uint256 percentOutOnTick = uint256(params.accumTick.amountOutDeltaMaxMinus) * 1e38 / (params.deltas.amountOutDeltaMax);
                // transfer deltas to the accum tick
                (params.deltas, accumDeltas) = Deltas.transfer(params.deltas, accumDeltas, percentInOnTick, percentOutOnTick);
                
                // burn tick deltas maxes from cache
                params.deltas = Deltas.burnMaxCache(params.deltas, params.accumTick);
                
                // empty delta max minuses into delta max
                accumDeltas.amountInDeltaMax  += params.accumTick.amountInDeltaMaxMinus;
                accumDeltas.amountOutDeltaMax += params.accumTick.amountOutDeltaMaxMinus;

                // clear out delta max minus and save on tick
                params.accumTick.amountInDeltaMaxMinus  = 0;
                params.accumTick.amountOutDeltaMaxMinus = 0;
                params.accumTick.deltas = accumDeltas;

                emit FinalDeltasAccumulated(
                    accumDeltas.amountInDelta,
                    accumDeltas.amountOutDelta,
                    state.accumEpoch,
                    params.isPool0 ? cache.nextTickToAccum0 : cache.nextTickToAccum1,
                    params.isPool0
                );
            }
        }
        // remove all liquidity
        params.crossTick.liquidityDelta = 0;

        return params;
    }

    //maybe call ticks on msg.sender to get tick
    function _cross(
        int128 liquidityDelta,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants,
        int24 nextTickToCross,
        int24 nextTickToAccum,
        uint128 currentLiquidity,
        bool zeroForOne
    ) internal view returns (
        uint128,
        int24,
        int24
    )
    {
        nextTickToCross = nextTickToAccum;

        if (liquidityDelta > 0) {
            currentLiquidity += uint128(liquidityDelta);
        } else {
            currentLiquidity -= uint128(-liquidityDelta);
        }
        if (zeroForOne) {
            nextTickToAccum = TickMap.previous(nextTickToAccum, tickMap, constants);
        } else {
            nextTickToAccum = TickMap.next(nextTickToAccum, tickMap, constants);
        }
        return (currentLiquidity, nextTickToCross, nextTickToAccum);
    }

    function _stash(
        ICoverPoolStructs.Tick memory stashTick,
        ICoverPoolStructs.AccumulateCache memory cache,
        ICoverPoolStructs.GlobalState memory state,
        uint128 currentLiquidity,
        bool isPool0
    ) internal returns (ICoverPoolStructs.Tick memory) {
        // return since there is nothing to update
        if (currentLiquidity == 0) return (stashTick);
        // handle deltas
        ICoverPoolStructs.Deltas memory deltas = isPool0 ? cache.deltas0 : cache.deltas1;
        emit StashDeltasAccumulated(
            deltas.amountInDelta,
            deltas.amountOutDelta,
            deltas.amountInDeltaMax,
            deltas.amountOutDeltaMax,
            state.accumEpoch,
            isPool0 ? cache.stopTick0 : cache.stopTick1,
            isPool0
        );
        if (deltas.amountInDeltaMax > 0) {
            (deltas, stashTick) = Deltas.stash(deltas, stashTick);
        }
        stashTick.liquidityDelta += int128(currentLiquidity);
        return (stashTick);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/ICoverPoolStructs.sol';

library TickMap {
    function set(
        int24 tick,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
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
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
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
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
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
                    // assert(blockMap != 0);
                    // if blockMap == 0 return type(int24).min() or MIN_TICK

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
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        int24 nextTick
    ) {
        unchecked {
            (
              uint256 tickIndex,
              uint256 wordIndex,
              uint256 blockIndex
            ) = getIndices(tick, constants);
            uint256 word = tickMap.ticks[wordIndex] & ~((1 << ((tickIndex & 0xFF) + 1)) - 1);
            if (word == 0) {
                uint256 block_ = tickMap.words[blockIndex] & ~((1 << ((wordIndex & 0xFF) + 1)) - 1);
                if (block_ == 0) {
                    uint256 blockMap = tickMap.blocks & ~((1 << blockIndex + 1) - 1);
                    // assert(blockMap != 0);
                    //if blockMap == 0 return type(int24).max()

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
        ICoverPoolStructs.Immutables memory constants
    ) public pure returns (
            uint256 tickIndex,
            uint256 wordIndex,
            uint256 blockIndex
        )
    {
        unchecked {
            if (tick > constants.curve.maxTick(constants.tickSpread)) require (false, 'TickIndexOverflow()');
            if (tick < constants.curve.minTick(constants.tickSpread)) require (false, 'TickIndexUnderflow()');
            if (tick % constants.tickSpread != 0) require (false, 'TickIndexInvalid()');
            tickIndex = uint256(int256((tick - constants.curve.minTick(constants.tickSpread))) / constants.tickSpread);
            wordIndex = tickIndex >> 8;   // 2^8 ticks per word
            blockIndex = tickIndex >> 16; // 2^8 words per block
            if (blockIndex > 255) require (false, 'BlockIndexOverflow()');
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
            tick = int24(int256(tickIndex) * int256(constants.tickSpread) + constants.curve.minTick(constants.tickSpread));
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