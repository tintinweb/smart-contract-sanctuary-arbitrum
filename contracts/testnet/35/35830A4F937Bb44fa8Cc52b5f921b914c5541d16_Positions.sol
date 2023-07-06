// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../../interfaces/modules/sources/ITwapSource.sol';

interface CurveMathStructs {
    struct PriceBounds {
        uint160 min;
        uint160 max;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICoverPoolStructs.sol';

/**
 * @title ICoverPool
 * @author Poolshark
 * @notice Defines the basic interface for a Cover Pool.
 */
interface ICoverPool is ICoverPoolStructs {
    /**
     * @custom:struct MintParams
     */
    struct MintParams {
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
    }

    /**
     * @notice Deposits `amountIn` of asset to be auctioned off each time price range is crossed further into.
     * - E.g. User supplies 1 WETH in the range 1500 USDC per WETH to 1400 USDC per WETH
              As latestTick crosses from 1500 USDC per WETH to 1400 USDC per WETH,
              the user's liquidity within each tick spacing is auctioned off.
     * @dev The position will be shrunk onto the correct side of latestTick.
     * @dev The position will be minted with the `to` address as the owner.
     * @param params The parameters for the function. See MintParams above.
     */
    function mint(
        MintParams memory params
    ) external;

    /**
     * @custom:struct BurnParams
     */
    struct BurnParams {
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
         * @custom:field lower
         * @notice The lower price tick for the existing position range
         */
        int24 lower;

        /**
         * @custom:field claim
         * @notice The most recent tick crossed in this range
         * @notice if `zeroForOne` is true, claim tick progresses from upper => lower
         * @notice if `zeroForOne` is false, claim tick progresses from lower => upper
         */
        int24 claim;

        /**
         * @custom:field upper
         * @notice The upper price tick for the existing position range
         */
        int24 upper;

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
     * @notice Withdraws the input token and returns any filled and/or unfilled amounts to the 'to' address specified. 
     * - E.g. User supplies 1 WETH in the range 1500 USDC per WETH to 1400 USDC per WETH
              As latestTick crosses from 1500 USDC per WETH to 1400 USDC per WETH,
              the user's liquidity within each tick spacing is auctioned off.
     * @dev The position will be shrunk based on the claim tick passed.
     * @dev The position amounts will be returned to the `to` address specified.
     * @dev The `sync` flag can be set to false so users can exit safely without syncing latestTick.
     * @param params The parameters for the function. See BurnParams above.
     */
    function burn(
        BurnParams memory params
    ) external;

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
         * @custom:field refundTo
         * @notice Address for the receiver of any fees or refunds
         */
        address refundTo;

        /**
         * @custom:field priceLimit
         * @dev The Q64.96 square root price at which to stop swapping.
         */
        uint160 priceLimit;

        /**
         * @custom:field amountIn
         * @dev The tokenIn amount being passed into the swap.
         */
        uint128 amountIn;

        /**
         * @custom:field zeroForOne
         * @notice True if swapping in token0, the first token address in lexographical order
         * @notice False if swapping in token1, the second token address in lexographical order 
         */
        bool zeroForOne;
    }

    /**
     * @notice Swaps `tokenIn` for `tokenOut`. 
               `tokenIn` will be `token0` if `zeroForOne` is true.
               `tokenIn` will be `token1` if `zeroForOne` is false.
               The pool price represents token1 per token0.
               The pool price will decrease if `zeroForOne` is true.
               The pool price will increase if `zeroForOne` is false. 
     * @param params The parameters for the function. See SwapParams above.
     * @return inAmount The amount of tokenIn to be spent
     * @return outAmount The amount of tokenOut to be received
     * @return priceAfter The Q64.96 square root price after the swap
     */
    function swap(
        SwapParams memory params
    ) external returns (
        int256 inAmount,
        uint256 outAmount,
        uint256 priceAfter
    );

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
         * @custom:field amountIn
         * @dev The tokenIn amount being passed into the swap.
         */
        uint128 amountIn;

        /**
         * @custom:field zeroForOne
         * @notice True if swapping in token0, the first token address in lexographical order
         * @notice False if swapping in token1, the second token address in lexographical order 
         */
        bool zeroForOne;
    }

    /**
     * @notice Quotes the amount of `tokenIn` for `tokenOut`. 
               `tokenIn` will be `token0` if `zeroForOne` is true.
               `tokenIn` will be `token1` if `zeroForOne` is false.
               The pool price represents token1 per token0.
               The pool price will decrease if `zeroForOne` is true.
               The pool price will increase if `zeroForOne` is false. 
     * @param params The parameters for the function. See SwapParams above.
     * @return inAmount The amount of tokenIn to be spent
     * @return outAmount The amount of tokenOut to be received
     * @return priceAfter The Q64.96 square root price after the swap
     */
    function quote(
        QuoteParams memory params
    ) external view returns (
        int256 inAmount,
        uint256 outAmount,
        uint256 priceAfter
    );

    /**
     * @custom:struct SnapshotParams
     */
    struct SnapshotParams {
        /**
         * @custom:field to
         * @notice Address for the owner of the position
         */
        address owner;

        /**
         * @custom:field burnPercent
         * @notice Percent of the remaining liquidity to be removed
         * @notice 1e38 represents 100%
         * @notice 5e37 represents 50%
         * @notice 1e37 represents 10%
         */
        uint128 burnPercent;

        /**
         * @custom:field lower
         * @notice The lower price tick for the existing position range
         */
        int24 lower;
        
        /**
         * @custom:field claim
         * @notice The most recent tick crossed in this range
         * @notice if `zeroForOne` is true, claim tick progresses from upper => lower
         * @notice if `zeroForOne` is false, claim tick progresses from lower => upper
         */
        int24 claim;

        /**
         * @custom:field upper
         * @notice The upper price tick for the existing position range
         */
        int24 upper;

        /**
         * @custom:field zeroForOne
         * @notice True if deposited token0, the first token address in lexographical order
         * @notice False if deposited token1, the second token address in lexographical order 
         */
        bool zeroForOne;
    }

    /**
     * @notice Snapshots the current state of an existing position. 
     * @param params The parameters for the function. See SwapParams above.
     * @return position The updated position containing `amountIn` and `amountOut`
     * @dev positions amounts reflected will be collected by the user if `burn` is called
     */
    function snapshot(
        SnapshotParams memory params
    ) external view returns (
        Position memory position
    );

    /**
     * @notice Sets and collect protocol fees from the pool. 
     * @param syncFee The new syncFee to be set if `setFees` is true.
     * @param fillFee The new fillFee to be set if `setFees` is true.
     * @return token0Fees The `token0` fees collected.
     * @return token1Fees The `token1` fees collected.
     * @dev `syncFee` is a basis point fee to be paid to users who sync latestTick
     * @dev `fillFee` is a basis point fee to be paid to the protocol for amounts filled
     * @dev All fees are zero by default unless the protocol decides to enable them.
     */
    function fees(
        uint16 syncFee,
        uint16 fillFee,
        bool setFees
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );
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
        uint32   lastTime;         /// @dev last block checked
        uint32   auctionStart;     /// @dev last block price reference was updated
        uint32   accumEpoch;       /// @dev number of times this pool has been synced
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
        uint128 amountInDelta;     /// @dev - amount filled
        uint128 amountOutDelta;    /// @dev - amount unfilled
        uint128 amountInDeltaMax;  /// @dev - max filled 
        uint128 amountOutDeltaMax; /// @dev - max unfilled
    }

    struct Position {
        uint160 claimPriceLast;    /// @dev - highest price claimed at
        uint128 liquidity;         /// @dev - expected amount to be used not actual
        uint128 amountIn;          /// @dev - token amount already claimed; balance
        uint128 amountOut;         /// @dev - necessary for non-custodial positions
        uint32  accumEpochLast;    /// @dev - last epoch this position was updated at
    }

    struct Immutables {
        ITwapSource source;
        ICurveMath.PriceBounds bounds;
        address token0;
        address token1;
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
        PoolState pool0;
        PoolState pool1;
        uint256 liquidityMinted;
    }

    struct BurnCache {
        GlobalState state;
        Position position;
        Immutables constants;
        SyncFees syncFees;
        PoolState pool0;
        PoolState pool1;
    }

    struct SwapCache {
        GlobalState state;
        SyncFees syncFees;
        Immutables constants;
        PoolState pool0;
        PoolState pool1;
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
        ICoverPoolStructs.Immutables memory constants,
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './Deltas.sol';
import '../interfaces/ICoverPoolStructs.sol';
import '../interfaces/modules/curves/ICurveMath.sol';
import './EpochMap.sol';
import './TickMap.sol';
import './utils/String.sol';

library Claims {

    function validate(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // validate position liquidity
        if (params.amount > cache.position.liquidity) require (false, 'NotEnoughPositionLiquidity()');
        if (cache.position.liquidity == 0) {
            cache.earlyReturn = true;
            return cache;
        }
        // if the position has not been crossed into at all
        else if (params.zeroForOne ? params.claim == params.upper 
                                        && EpochMap.get(params.upper, tickMap, constants) <= cache.position.accumEpochLast
                                     : params.claim == params.lower 
                                        && EpochMap.get(params.lower, tickMap, constants) <= cache.position.accumEpochLast
        ) {
            cache.earlyReturn = true;
            return cache;
        }
        // early return if no update and amount burned is 0
        if (
            (
                params.zeroForOne
                    ? params.claim == params.upper && cache.priceUpper != pool.price
                    : params.claim == params.lower && cache.priceLower != pool.price /// @dev - if pool price is start tick, set claimPriceLast to next tick crossed
            ) && params.claim == state.latestTick
        ) { if (params.amount == 0 && cache.position.claimPriceLast == pool.price) {
                cache.earlyReturn = true;
                return cache;
            } 
        } /// @dev - nothing to update if pool price hasn't moved
        
        // claim tick sanity checks
        else if (
            // claim tick is on a prior tick
            cache.position.claimPriceLast > 0 &&
            (params.zeroForOne
                    ? cache.position.claimPriceLast < cache.priceClaim
                    : cache.position.claimPriceLast > cache.priceClaim
            ) && params.claim != state.latestTick
        ) require (false, 'InvalidClaimTick()'); /// @dev - wrong claim tick
        if (params.claim < params.lower || params.claim > params.upper) require (false, 'InvalidClaimTick()');

        uint32 claimTickEpoch = EpochMap.get(params.claim, tickMap, constants);

        // validate claim tick
        if (params.claim == (params.zeroForOne ? params.lower : params.upper)) {
             if (claimTickEpoch <= cache.position.accumEpochLast)
                require (false, 'WrongTickClaimedAt()');
        } else {
            // zero fill or partial fill
            uint32 claimTickNextAccumEpoch = params.zeroForOne
                ? EpochMap.get(TickMap.previous(params.claim, tickMap, constants), tickMap, constants)
                : EpochMap.get(TickMap.next(params.claim, tickMap, constants), tickMap, constants);
            ///@dev - next accumEpoch should not be greater
            if (claimTickNextAccumEpoch > cache.position.accumEpochLast) {
                require (false, 'WrongTickClaimedAt()');
            }
        }
        if (params.claim != params.upper && params.claim != params.lower) {
            // check accumEpochLast on claim tick
            if (claimTickEpoch <= cache.position.accumEpochLast)
                require (false, 'WrongTickClaimedAt()');
            // prevent position overwriting at claim tick
            if (params.zeroForOne) {
                if (positions[params.owner][params.lower][params.claim].liquidity > 0) {
                    require (false, string.concat('UpdatePositionFirstAt(', String.from(params.lower), ', ', String.from(params.claim), ')'));
                }
            } else {
                if (positions[params.owner][params.claim][params.upper].liquidity > 0) {
                    require (false, string.concat('UpdatePositionFirstAt(', String.from(params.claim), ', ', String.from(params.upper), ')'));
                }
            }
            /// @dev - user cannot add liquidity if auction is active; checked for in Positions.validate()
        }
        return cache;
    }

    function getDeltas(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // transfer deltas into cache
        if (params.claim == (params.zeroForOne ? params.lower : params.upper)) {
            (cache.claimTick, cache.deltas) = Deltas.from(cache.claimTick, cache.deltas);
        } else {
            /// @dev - deltas are applied once per each tick claimed at
            /// @dev - deltas should never be applied if position is not crossed into
            // check if tick already claimed at
            bool transferDeltas = (cache.position.claimPriceLast == 0
                               && (params.claim != (params.zeroForOne ? params.upper : params.lower)))
                               || (params.zeroForOne ? cache.position.claimPriceLast > cache.priceClaim
                                                     : cache.position.claimPriceLast < cache.priceClaim && cache.position.claimPriceLast != 0);
            if (transferDeltas) {
                (cache.claimTick, cache.deltas) = Deltas.unstash(cache.claimTick, cache.deltas);
            }
        } /// @dev - deltas transfer from claim tick are replaced after applying changes
        return cache;
    }

    function applyDeltas(
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        uint256 percentInDelta; uint256 percentOutDelta;
        if(cache.deltas.amountInDeltaMax > 0) { //TODO: if this is zero for some reason we can just give 100% of amountInDelta
            percentInDelta = uint256(cache.amountInFilledMax) * 1e38 / uint256(cache.deltas.amountInDeltaMax);
            percentInDelta = percentInDelta > 1e38 ? 1e38 : percentInDelta;
            if (cache.deltas.amountOutDeltaMax > 0) {
                percentOutDelta = uint256(cache.amountOutUnfilledMax) * 1e38 / uint256(cache.deltas.amountOutDeltaMax);
                percentOutDelta = percentOutDelta > 1e38 ? 1e38 : percentOutDelta;
            }
        }
        (cache.deltas, cache.finalDeltas) = Deltas.transfer(cache.deltas, cache.finalDeltas, percentInDelta, percentOutDelta);
        (cache.deltas, cache.finalDeltas) = Deltas.transferMax(cache.deltas, cache.finalDeltas, percentInDelta, percentOutDelta);

        uint128 fillFeeAmount = cache.finalDeltas.amountInDelta * state.fillFee / 1e6;
        if (params.zeroForOne) {
            state.protocolFees.token1 += fillFeeAmount;
        } else {
            state.protocolFees.token0 += fillFeeAmount;
        }
        cache.finalDeltas.amountInDelta -= fillFeeAmount;
        cache.position.amountIn  += cache.finalDeltas.amountInDelta;
        cache.position.amountOut += cache.finalDeltas.amountOutDelta;

        if (params.claim != (params.zeroForOne ? params.lower : params.upper)) {
            // burn deltas on final tick of position
            cache.finalTick = Deltas.burnMaxMinus(cache.finalTick, cache.finalDeltas);
            if (params.claim == (params.zeroForOne ? params.upper : params.lower)) {
                (cache.deltas, cache.claimTick) = Deltas.to(cache.deltas, cache.claimTick);
            } else {
                (cache.deltas, cache.claimTick) = Deltas.stash(cache.deltas, cache.claimTick);
            }
        } else {
            (cache.deltas, cache.claimTick) = Deltas.to(cache.deltas, cache.claimTick);
        }
        return cache;
    }

    /// @dev - calculate claim portion of partially claimed previous auction
    function section1(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // delta check complete - update CPL for new position
        if(cache.position.claimPriceLast == 0) {
            cache.position.claimPriceLast = (params.zeroForOne ? cache.priceUpper 
                                                               : cache.priceLower);
        } else if (params.zeroForOne ? (cache.position.claimPriceLast != cache.priceUpper
                                        && cache.position.claimPriceLast > cache.priceClaim)
                                     : (cache.position.claimPriceLast != cache.priceLower
                                        && cache.position.claimPriceLast < cache.priceClaim))
        {
            // section 1 - complete previous auction claim
            {
                // amounts claimed on this update
                uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
                (
                    amountInFilledMax,
                    amountOutUnfilledMax
                ) = Deltas.maxAuction(
                    cache.position.liquidity,
                    cache.position.claimPriceLast,
                    params.zeroForOne ? cache.priceUpper
                                      : cache.priceLower,
                    params.zeroForOne
                );
                //TODO: modify delta max on claim tick and lower : upper tick
                cache.amountInFilledMax    += amountInFilledMax;
                cache.amountOutUnfilledMax += amountOutUnfilledMax;
            }
            // move price to next tick in sequence for section 2
            cache.position.claimPriceLast  = params.zeroForOne ? ConstantProduct.getPriceAtTick(params.upper - constants.tickSpread, constants)
                                                               : ConstantProduct.getPriceAtTick(params.lower + constants.tickSpread, constants);
        }
        return cache;
    }

    /// @dev - calculate claim from position start up to claim tick
    function section2(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 2 - position start up to claim tick
        if (params.zeroForOne ? cache.priceClaim < cache.position.claimPriceLast 
                              : cache.priceClaim > cache.position.claimPriceLast) {
            // calculate if we at least cover one full tick
            uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
            (
                amountInFilledMax,
                amountOutUnfilledMax
            ) = Deltas.maxRoundUp(
                cache.position.liquidity,
                cache.position.claimPriceLast,
                cache.priceClaim,
                params.zeroForOne
            );
            cache.amountInFilledMax += amountInFilledMax;
            cache.amountOutUnfilledMax += amountOutUnfilledMax;
        }
        return cache;
    }

    /// @dev - calculate claim from current auction unfilled section
    function section3(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.PoolState memory pool
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 3 - current auction unfilled section
        if (params.amount > 0) {
            // remove if burn
            uint128 amountOutRemoved = uint128(
                params.zeroForOne
                    ? ConstantProduct.getDx(params.amount, pool.price, cache.priceClaim, false)
                    : ConstantProduct.getDy(params.amount, cache.priceClaim, pool.price, false)
            );
            uint128 amountInOmitted = uint128(
                params.zeroForOne
                    ? ConstantProduct.getDy(params.amount, pool.price, cache.priceClaim, false)
                    : ConstantProduct.getDx(params.amount, cache.priceClaim, pool.price, false)
            );
            // add to position
            cache.position.amountOut += amountOutRemoved;
            // modify max deltas to be burned
            cache.finalDeltas.amountInDeltaMax  += amountInOmitted;
            cache.finalDeltas.amountOutDeltaMax += amountOutRemoved;
        }
        return cache;
    }

    /// @dev - calculate claim from position start up to claim tick
    function section4(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.PoolState memory pool
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 4 - current auction filled section
        {
            // amounts claimed on this update
            uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
            (
                amountInFilledMax,
                amountOutUnfilledMax
            ) = Deltas.maxAuction(
                cache.position.liquidity,
                (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                    : cache.position.claimPriceLast > cache.priceClaim) 
                                        ? cache.position.claimPriceLast 
                                        : cache.priceSpread,
                pool.price,
                params.zeroForOne
            );
            uint256 poolAmountInDeltaChange = uint256(cache.position.liquidity) * 1e38 
                                                / uint256(pool.liquidity) * uint256(pool.amountInDelta) / 1e38;   
            
            cache.position.amountIn += uint128(poolAmountInDeltaChange);
            pool.amountInDelta -= uint128(poolAmountInDeltaChange); //CHANGE POOL TO MEMORY
            cache.finalDeltas.amountInDeltaMax += amountInFilledMax;
            cache.finalDeltas.amountOutDeltaMax += amountOutUnfilledMax;
            /// @dev - record how much delta max was claimed
            if (params.amount < cache.position.liquidity) {
                (
                    amountInFilledMax,
                    amountOutUnfilledMax
                ) = Deltas.maxAuction(
                    cache.position.liquidity - params.amount,
                    (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                    : cache.position.claimPriceLast > cache.priceClaim) 
                                            ? cache.position.claimPriceLast 
                                            : cache.priceSpread,
                    pool.price,
                    params.zeroForOne
                );
                pool.amountInDeltaMaxClaimed  += amountInFilledMax;
                pool.amountOutDeltaMaxClaimed += amountOutUnfilledMax;
            }
        }
        if (params.amount > 0 /// @ dev - if removing L and second claim on same tick
            && (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                    : cache.position.claimPriceLast > cache.priceClaim)) {
                // reduce delta max claimed based on liquidity removed
                pool = Deltas.burnMaxPool(pool, cache, params);
        }
        // modify claim price for section 5
        cache.priceClaim = cache.priceSpread;
        // save pool changes to cache
        cache.pool = pool;
        return cache;
    }

    /// @dev - calculate claim from position start up to claim tick
    function section5(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 5 - burned liquidity past claim tick
        {
            uint160 endPrice = params.zeroForOne ? cache.priceLower
                                                 : cache.priceUpper;
            if (params.amount > 0 && cache.priceClaim != endPrice) {
                // update max deltas based on liquidity removed
                uint128 amountInOmitted; uint128 amountOutRemoved;
                (
                    amountInOmitted,
                    amountOutRemoved
                ) = Deltas.max(
                    params.amount,
                    cache.priceClaim,
                    endPrice,
                    params.zeroForOne
                );
                cache.position.amountOut += amountOutRemoved;
                /// @auditor - we don't add to cache.amountInFilledMax and cache.amountOutUnfilledMax 
                ///            since this section of the curve is not reflected in the deltas
                if (params.claim != (params.zeroForOne ? params.lower : params.upper)) {
                    cache.finalDeltas.amountInDeltaMax += amountInOmitted;
                    cache.finalDeltas.amountOutDeltaMax += amountOutRemoved;
                }      
            }
        }
        return cache;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/ICoverPoolStructs.sol';
import './math/ConstantProduct.sol';

library Deltas {

    function max(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool   isPool0
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? ConstantProduct.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : ConstantProduct.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? ConstantProduct.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : ConstantProduct.getDy(
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
        bool   isPool0
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? ConstantProduct.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
                : ConstantProduct.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? ConstantProduct.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
                : ConstantProduct.getDy(
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
        bool isPool0
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? ConstantProduct.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
                : ConstantProduct.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? ConstantProduct.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
                : ConstantProduct.getDy(
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
        ICoverPoolStructs.UpdateParams memory params
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
            params.zeroForOne
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
        bool   isAdded
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
            ) = max(amount, priceUpper, priceLower, true);
        } else {
            (
                amountInDeltaMax,
                amountOutDeltaMax
            ) = max(amount, priceLower, priceUpper, false);
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

import './math/ConstantProduct.sol';
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
            if (tick > ConstantProduct.maxTick(constants.tickSpread)) require (false, 'TickIndexOverflow()');
            if (tick < ConstantProduct.minTick(constants.tickSpread)) require (false, 'TickIndexUnderflow()');
            if (tick % constants.tickSpread != 0) require (false, 'TickIndexInvalid()');
            tickIndex = uint256(int256((tick - ConstantProduct.minTick(constants.tickSpread))) / constants.tickSpread);
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
            if (tickIndex > uint24(ConstantProduct.maxTick(constants.tickSpread) * 2)) require (false, 'TickIndexOverflow()');
            tick = int24(int256(tickIndex) * int256(constants.tickSpread) + ConstantProduct.maxTick(constants.tickSpread));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../../../interfaces/modules/curves/IDyDxMath.sol';
import '../../../libraries/math/FullPrecisionMath.sol';

/// @notice Math library that facilitates ranged liquidity calculations.
library DyDxMath
{
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dy) {
        return _getDy(liquidity, priceLower, priceUpper, roundUp);
    }

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        return _getDx(liquidity, priceLower, priceUpper, roundUp);
    }

    function _getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dy) {
        unchecked {
            if (roundUp) {
                dy = FullPrecisionMath.mulDivRoundingUp(liquidity, priceUpper - priceLower, Q96);
            } else {
                dy = FullPrecisionMath.mulDiv(liquidity, priceUpper - priceLower, Q96);
            }
        }
    }

    function _getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        unchecked {
            if (roundUp) {
                dx = FullPrecisionMath.divRoundingUp(FullPrecisionMath.mulDivRoundingUp(liquidity << 96, priceUpper - priceLower, priceUpper), priceLower);
            } else {
                dx = FullPrecisionMath.mulDiv(liquidity << 96, priceUpper - priceLower, priceUpper) / priceLower;
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
            if (priceUpper == currentPrice) {
                liquidity = FullPrecisionMath.mulDiv(dy, Q96, priceUpper - priceLower);
            } else if (currentPrice == priceLower) {
                liquidity = FullPrecisionMath.mulDiv(
                    dx,
                    FullPrecisionMath.mulDiv(priceLower, priceUpper, Q96),
                    priceUpper - priceLower
                );
            } else {
                /// @dev - price should either be priceUpper or priceLower
                require (false, 'PriceOutsideBounds()');
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
            token1amount = uint128(_getDy(liquidityAmount, priceLower, priceUpper, roundUp));
        } else if (currentPrice <= priceLower) {
            token0amount = uint128(_getDx(liquidityAmount, priceLower, priceUpper, roundUp));
        } else {
            token0amount = uint128(_getDx(liquidityAmount, currentPrice, priceUpper, roundUp));
            token1amount = uint128(_getDy(liquidityAmount, priceLower, currentPrice, roundUp));
        }
    }

    function getNewPrice(
        uint256 price,
        uint256 liquidity,
        uint256 input,
        bool zeroForOne
    ) internal pure returns (
        uint256 newPrice
    ) {
        if (zeroForOne) {
            uint256 liquidityPadded = liquidity << 96;
            newPrice = FullPrecisionMath.mulDivRoundingUp(
                            liquidityPadded,
                            price,
                            liquidityPadded + price * input
                       );
        } else {
            newPrice = price + FullPrecisionMath.mulDiv(input, Q96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import '../../../interfaces/modules/curves/ITickMath.sol';
import '../../../libraries/math/FullPrecisionMath.sol';

/// @notice Math library for computing sqrt price for ticks of size 1.0001, i.e., sqrt(1.0001^tick) as fixed point Q64.96 numbers - supports
/// prices between 2**-128 and 2**128 - 1.
/// @author Adapted from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/TickMath.sol.
library TickMath {
    /// @dev The minimum tick that may be passed to #getPriceAtTick computed from log base 1.0001 of 2**-128.
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getPriceAtTick computed from log base 1.0001 of 2**128 - 1.
    int24 internal constant MAX_TICK = -MIN_TICK;
    uint256 private constant Q96 = 0x1000000000000000000000000;

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

    function minPrice(
        int16 tickSpacing
    ) internal pure returns (
        uint160 price
    ) {
        ICoverPoolStructs.Immutables memory constants;
        constants.tickSpread = tickSpacing;
        return getPriceAtTick(minTick(tickSpacing), constants);
    }

    function maxPrice(
        int16 tickSpacing
    ) internal pure returns (
        uint160 price
    ) {
        ICoverPoolStructs.Immutables memory constants;
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
        ITickMath.PriceBounds memory bounds
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
        ICoverPoolStructs.Immutables memory constants
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
        ICoverPoolStructs.Immutables memory constants
    ) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (price < constants.bounds.min || price >= constants.bounds.max)
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './constant-product/DyDxMath.sol';
import './constant-product/TickMath.sol';

/// @notice Math library that facilitates ranged liquidity calculations.
library ConstantProduct {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    /////////////////////////////////////////////////////////////
    ///////////////////////// DYDX MATH /////////////////////////
    /////////////////////////////////////////////////////////////

    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dy) {
        return _getDy(liquidity, priceLower, priceUpper, roundUp);
    }

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        return _getDx(liquidity, priceLower, priceUpper, roundUp);
    }

    function _getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dy) {
        unchecked {
            if (roundUp) {
                dy = FullPrecisionMath.mulDivRoundingUp(liquidity, priceUpper - priceLower, Q96);
            } else {
                dy = FullPrecisionMath.mulDiv(liquidity, priceUpper - priceLower, Q96);
            }
        }
    }

    function _getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        unchecked {
            if (roundUp) {
                dx = FullPrecisionMath.divRoundingUp(FullPrecisionMath.mulDivRoundingUp(liquidity << 96, priceUpper - priceLower, priceUpper), priceLower);
            } else {
                dx = FullPrecisionMath.mulDiv(liquidity << 96, priceUpper - priceLower, priceUpper) / priceLower;
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
            if (priceUpper == currentPrice) {
                liquidity = FullPrecisionMath.mulDiv(dy, Q96, priceUpper - priceLower);
            } else if (currentPrice == priceLower) {
                liquidity = FullPrecisionMath.mulDiv(
                    dx,
                    FullPrecisionMath.mulDiv(priceLower, priceUpper, Q96),
                    priceUpper - priceLower
                );
            } else {
                /// @dev - price should either be priceUpper or priceLower
                require (false, 'PriceOutsideBounds()');
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
            token1amount = uint128(_getDy(liquidityAmount, priceLower, priceUpper, roundUp));
        } else if (currentPrice <= priceLower) {
            token0amount = uint128(_getDx(liquidityAmount, priceLower, priceUpper, roundUp));
        } else {
            token0amount = uint128(_getDx(liquidityAmount, currentPrice, priceUpper, roundUp));
            token1amount = uint128(_getDy(liquidityAmount, priceLower, currentPrice, roundUp));
        }
    }

    function getNewPrice(
        uint256 price,
        uint256 liquidity,
        uint256 input,
        bool zeroForOne
    ) internal pure returns (
        uint256 newPrice
    ) {
        if (zeroForOne) {
            uint256 liquidityPadded = liquidity << 96;
            newPrice = FullPrecisionMath.mulDivRoundingUp(
                            liquidityPadded,
                            price,
                            liquidityPadded + price * input
                       );
        } else {
            newPrice = price + FullPrecisionMath.mulDiv(input, Q96, liquidity);
        }
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
        ICoverPoolStructs.Immutables memory constants;
        constants.tickSpread = tickSpacing;
        return getPriceAtTick(minTick(tickSpacing), constants);
    }

    function maxPrice(
        int16 tickSpacing
    ) internal pure returns (
        uint160 price
    ) {
        ICoverPoolStructs.Immutables memory constants;
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
        ITickMath.PriceBounds memory bounds
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
        ICoverPoolStructs.Immutables memory constants
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
        ICoverPoolStructs.Immutables memory constants
    ) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (price < constants.bounds.min || price >= constants.bounds.max)
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
pragma solidity ^0.8.13;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library FullPrecisionMath {

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
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import './Ticks.sol';
import './Deltas.sol';
import '../interfaces/ICoverPoolStructs.sol';
import '../interfaces/ICoverPool.sol';
import './math/FullPrecisionMath.sol';
import '../interfaces/modules/curves/ICurveMath.sol';
import './Claims.sol';
import './EpochMap.sol';

/// @notice Position management library for ranged liquidity.
library Positions {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    event Mint(
        address indexed to,
        int24 lower,
        int24 upper,
        bool zeroForOne,
        uint32 epochLast,
        uint128 amountIn,
        uint128 liquidityMinted,
        uint128 amountInDeltaMaxMinted,
        uint128 amountOutDeltaMaxMinted
    );

    event Burn(
        address indexed to,
        int24 lower,
        int24 upper,
        int24 claim,
        bool zeroForOne,
        uint128 liquidityBurned,
        uint128 tokenInClaimed,
        uint128 tokenOutClaimed,
        uint128 tokenOutBurned,
        uint128 amountInDeltaMaxStashedBurned,
        uint128 amountOutDeltaMaxStashedBurned,
        uint128 amountInDeltaMaxBurned,
        uint128 amountOutDeltaMaxBurned,
        uint160 claimPriceLast
    );

    function resize(
        ICoverPoolStructs.Position memory position,
        ICoverPool.MintParams memory params,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants
    ) internal pure returns (
        ICoverPool.MintParams memory,
        uint256
    )
    {
        ConstantProduct.checkTicks(params.lower, params.upper, constants.tickSpread);

        ICoverPoolStructs.PositionCache memory cache = ICoverPoolStructs.PositionCache({
            position: ICoverPoolStructs.Position(0,0,0,0,0),
            deltas: ICoverPoolStructs.Deltas(0,0,0,0),
            requiredStart: params.zeroForOne ? state.latestTick - int24(constants.tickSpread) * constants.minPositionWidth
                                             : state.latestTick + int24(constants.tickSpread) * constants.minPositionWidth,
            auctionCount: uint24((params.upper - params.lower) / constants.tickSpread),
            priceLower: ConstantProduct.getPriceAtTick(params.lower, constants),
            priceUpper: ConstantProduct.getPriceAtTick(params.upper, constants),
            priceAverage: 0,
            liquidityMinted: 0,
            denomTokenIn: true
        });

        // cannot mint empty position
        if (params.amount == 0) require (false, 'PositionAmountZero()');

        // enforce safety window
        if (params.zeroForOne) {    
            if (params.lower >= cache.requiredStart) require (false, 'PositionInsideSafetyWindow()'); 
        } else {
            if (params.upper <= cache.requiredStart) require (false, 'PositionInsideSafetyWindow()');
        }

        cache.liquidityMinted = ConstantProduct.getLiquidityForAmounts(
            cache.priceLower,
            cache.priceUpper,
            params.zeroForOne ? cache.priceLower : cache.priceUpper,
            params.zeroForOne ? 0 : uint256(params.amount),
            params.zeroForOne ? uint256(params.amount) : 0
        );

        // handle partial mints
        if (params.zeroForOne) {
            if (params.upper > cache.requiredStart) {
                params.upper = cache.requiredStart;
                uint256 priceNewUpper = ConstantProduct.getPriceAtTick(params.upper, constants);
                params.amount -= uint128(
                    ConstantProduct.getDx(cache.liquidityMinted, priceNewUpper, cache.priceUpper, false)
                );
                cache.priceUpper = uint160(priceNewUpper);
            }
            // update auction count
            cache.auctionCount = uint24((params.upper - params.lower) / constants.tickSpread);
            if (cache.auctionCount == 0) require (false, 'InvalidPositionWidth()');
        } else {
            if (params.lower < cache.requiredStart) {
                params.lower = cache.requiredStart;
                uint256 priceNewLower = ConstantProduct.getPriceAtTick(params.lower, constants);
                params.amount -= uint128(
                    ConstantProduct.getDy(cache.liquidityMinted, cache.priceLower, priceNewLower, false)
                );
                cache.priceLower = uint160(priceNewLower);
            }
            // update auction count
            cache.auctionCount = uint24((params.upper - params.lower) / constants.tickSpread);
            if (cache.auctionCount == 0) require (false, 'InvalidPositionWidth()');
        }
        // enforce minimum position width
        if (cache.auctionCount < uint16(constants.minPositionWidth)) require (false, 'InvalidPositionWidth()');
        if (cache.liquidityMinted > uint128(type(int128).max)) require (false, 'LiquidityOverflow()');

        // enforce minimum amount per auction
        _size(
            ICoverPoolStructs.SizeParams(
                cache.priceLower,
                cache.priceUpper,
                uint128(position.liquidity + cache.liquidityMinted),
                params.zeroForOne,
                state.latestTick,
                cache.auctionCount
            ),
            constants
        );
 
        return (
            params,
            cache.liquidityMinted
        );
    }

    function add(
       ICoverPoolStructs.Position memory position,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.AddParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) internal returns (
        ICoverPoolStructs.GlobalState memory,
        ICoverPoolStructs.Position memory
    ) {
        if (params.amount == 0) return (state, position);
        // initialize cache
        ICoverPoolStructs.PositionCache memory cache = ICoverPoolStructs.PositionCache({
            position: position,
            deltas: ICoverPoolStructs.Deltas(0,0,0,0),
            requiredStart: 0,
            auctionCount: 0,
            priceLower: ConstantProduct.getPriceAtTick(params.lower, constants),
            priceUpper: ConstantProduct.getPriceAtTick(params.upper, constants),
            priceAverage: 0,
            liquidityMinted: 0,
            denomTokenIn: true
        });
        /// call if claim != lower and liquidity being added
        /// initialize new position

        if (cache.position.liquidity == 0) {
            cache.position.accumEpochLast = state.accumEpoch;
        } else {
            // safety check in case we somehow get here
            if (
                params.zeroForOne
                    ? state.latestTick < params.upper ||
                        EpochMap.get(TickMap.previous(params.upper, tickMap, constants), tickMap, constants)
                            > cache.position.accumEpochLast
                    : state.latestTick > params.lower ||
                        EpochMap.get(TickMap.next(params.lower, tickMap, constants), tickMap, constants)
                            > cache.position.accumEpochLast
            ) {
                require (false, string.concat('UpdatePositionFirstAt(', String.from(params.lower), ', ', String.from(params.upper), ')'));
            }
        }
        
        // add liquidity to ticks
        Ticks.insert(
            ticks,
            tickMap,
            state,
            constants,
            params.lower,
            params.upper,
            uint128(params.amount),
            params.zeroForOne
        );

        // update liquidity global
        state.liquidityGlobal += params.amount;

        {
            // update max deltas
            ICoverPoolStructs.Tick memory finalTick = ticks[params.zeroForOne ? params.lower : params.upper];
            (finalTick, cache.deltas) = Deltas.update(finalTick, params.amount, cache.priceLower, cache.priceUpper, params.zeroForOne, true);
            ticks[params.zeroForOne ? params.lower : params.upper] = finalTick;
            // revert if either max delta is zero
            if (cache.deltas.amountInDeltaMax == 0) {
                require(false, 'AmountInDeltaIsZero()');
            } else if (cache.deltas.amountOutDeltaMax == 0)
                require(false, 'AmountOutDeltaIsZero()');
        }
        cache.position.liquidity += uint128(params.amount);
        emit Mint(
            params.to,
            params.lower,
            params.upper,
            params.zeroForOne,
            state.accumEpoch,
            params.amountIn,
            params.amount,
            cache.deltas.amountInDeltaMax,
            cache.deltas.amountOutDeltaMax
        );

        return (state, cache.position);
    }

    function remove(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.RemoveParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) internal returns (uint128, ICoverPoolStructs.GlobalState memory) {
        // validate burn percentage
        if (params.amount > 1e38) require (false, 'InvalidBurnPercentage()');
        // initialize cache
        ICoverPoolStructs.PositionCache memory cache = ICoverPoolStructs.PositionCache({
            position: positions[params.owner][params.lower][params.upper],
            deltas: ICoverPoolStructs.Deltas(0,0,0,0),
            requiredStart: params.zeroForOne ? state.latestTick - int24(constants.tickSpread) * constants.minPositionWidth
                                             : state.latestTick + int24(constants.tickSpread) * constants.minPositionWidth,
            auctionCount: uint24((params.upper - params.lower) / constants.tickSpread),
            priceLower: ConstantProduct.getPriceAtTick(params.lower, constants),
            priceUpper: ConstantProduct.getPriceAtTick(params.upper, constants),
            priceAverage: 0,
            liquidityMinted: 0,
            denomTokenIn: true
        });
        // convert percentage to liquidity amount
        params.amount = _convert(cache.position.liquidity, params.amount);
        // early return if no liquidity to remove
        if (params.amount == 0) return (0, state);
        if (params.amount > cache.position.liquidity) {
            require (false, 'NotEnoughPositionLiquidity()');
        } else {
            _size(
                ICoverPoolStructs.SizeParams(
                    cache.priceLower,
                    cache.priceUpper,
                    cache.position.liquidity - params.amount,
                    params.zeroForOne,
                    state.latestTick,
                    cache.auctionCount
                ),
                constants
            );
            /// @dev - validate needed in case user passes in wrong tick
            if (
                params.zeroForOne
                    ? state.latestTick < params.upper ||
                        EpochMap.get(TickMap.previous(params.upper, tickMap, constants), tickMap, constants)
                            > cache.position.accumEpochLast
                    : state.latestTick > params.lower ||
                        EpochMap.get(TickMap.next(params.lower, tickMap, constants), tickMap, constants)
                            > cache.position.accumEpochLast
            ) {
                require (false, 'WrongTickClaimedAt()');
            }
        }

        Ticks.remove(
            ticks,
            tickMap,
            constants,
            params.lower,
            params.upper,
            params.amount,
            params.zeroForOne,
            true,
            true
        );

        // update liquidity global
        state.liquidityGlobal -= params.amount;

        {
            // update max deltas
            ICoverPoolStructs.Tick memory finalTick = ticks[params.zeroForOne ? params.lower : params.upper];
            (finalTick, cache.deltas) = Deltas.update(finalTick, params.amount, cache.priceLower, cache.priceUpper, params.zeroForOne, false);
            ticks[params.zeroForOne ? params.lower : params.upper] = finalTick;
        }

        cache.position.amountOut += uint128(
            params.zeroForOne
                ? ConstantProduct.getDx(params.amount, cache.priceLower, cache.priceUpper, false)
                : ConstantProduct.getDy(params.amount, cache.priceLower, cache.priceUpper, false)
        );

        cache.position.liquidity -= uint128(params.amount);
        if (cache.position.liquidity == 0){
            cache.position.accumEpochLast = 0;
        }
        positions[params.owner][params.lower][params.upper] = cache.position;

        if (params.amount > 0) {
            emit Burn(
                    params.to,
                    params.lower,
                    params.upper,
                    params.zeroForOne ? params.upper : params.lower,
                    params.zeroForOne,
                    params.amount,
                    0, 0,
                    cache.position.amountOut,
                    0, 0,
                    cache.deltas.amountInDeltaMax,
                    cache.deltas.amountOutDeltaMax,
                    cache.position.claimPriceLast
            );
        }
        return (params.amount, state);
    }

    function update(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) internal returns (
            ICoverPoolStructs.GlobalState memory,
            ICoverPoolStructs.PoolState memory,
            int24
        )
    {
        ICoverPoolStructs.UpdatePositionCache memory cache;
        (
            cache,
            state
        ) = _deltas(
            positions,
            ticks,
            tickMap,
            state,
            pool,
            params,
            constants
        );

        if (cache.earlyReturn)
            return (state, pool, params.claim);

        pool.amountInDelta = cache.pool.amountInDelta;
        pool.amountInDeltaMaxClaimed  = cache.pool.amountInDeltaMaxClaimed;
        pool.amountOutDeltaMaxClaimed = cache.pool.amountOutDeltaMaxClaimed;

        // save claim tick
        ticks[params.claim] = cache.claimTick;
        if (params.claim != (params.zeroForOne ? params.lower : params.upper))
            ticks[params.zeroForOne ? params.lower : params.upper] = cache.finalTick;
        
        // update pool liquidity
        if (state.latestTick == params.claim
            && params.claim != (params.zeroForOne ? params.lower : params.upper)
        ) pool.liquidity -= params.amount;
        
        if (params.amount > 0) {
            if (params.claim == (params.zeroForOne ? params.lower : params.upper)) {
                // only remove once if final tick of position
                cache.removeLower = false;
                cache.removeUpper = false;
            } else {
                params.zeroForOne ? cache.removeUpper = true 
                                  : cache.removeLower = true;
            }
            Ticks.remove(
                ticks,
                tickMap,
                constants,
                params.zeroForOne ? params.lower : params.claim,
                params.zeroForOne ? params.claim : params.upper,
                params.amount,
                params.zeroForOne,
                cache.removeLower,
                cache.removeUpper
            );
            // update position liquidity
            cache.position.liquidity -= uint128(params.amount);
            // update global liquidity
            state.liquidityGlobal -= params.amount;
        }

        (
            cache,
            params
        ) = _checkpoint(state, pool, params, constants, cache);

        // clear out old position
        if (params.zeroForOne ? params.claim != params.upper 
                              : params.claim != params.lower) {
            /// @dev - this also clears out position end claims
            if (params.zeroForOne ? params.claim == params.lower 
                                  : params.claim == params.upper) {
                // subtract remaining position liquidity out from global
                state.liquidityGlobal -= cache.position.liquidity;
            }
            delete positions[params.owner][params.lower][params.upper];
        }
        // force collection to the user
        // store cached position in memory
        if (cache.position.liquidity == 0) {
            cache.position.accumEpochLast = 0;
            cache.position.claimPriceLast = 0;
        }
        params.zeroForOne
            ? positions[params.owner][params.lower][params.claim] = cache.position
            : positions[params.owner][params.claim][params.upper] = cache.position;
        
        emit Burn(
            params.to,
            params.lower,
            params.upper,
            params.claim,
            params.zeroForOne,
            params.amount,
            cache.position.amountIn,
            cache.finalDeltas.amountOutDelta,
            cache.position.amountOut - cache.finalDeltas.amountOutDelta,
            uint128(cache.amountInFilledMax),
            uint128(cache.amountOutUnfilledMax),
            cache.finalDeltas.amountInDeltaMax,
            cache.finalDeltas.amountOutDeltaMax,
            cache.position.claimPriceLast
        );
        // return cached position in memory and transfer out
        return (state, pool, params.claim);
    }

    function snapshot(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) external view returns (
        ICoverPoolStructs.Position memory
    ) {
        ICoverPoolStructs.UpdatePositionCache memory cache;
        (
            cache,
            state
        ) = _deltas(
            positions,
            ticks,
            tickMap,
            state,
            pool,
            params,
            constants
        );

        if (cache.earlyReturn) {
            if (params.amount > 0)
                cache.position.amountOut += uint128(
                    params.zeroForOne
                        ? ConstantProduct.getDx(params.amount, cache.priceLower, cache.priceUpper, false)
                        : ConstantProduct.getDy(params.amount, cache.priceLower, cache.priceUpper, false)
                );
            return cache.position;
        }

        if (params.amount > 0) {
            cache.position.liquidity -= uint128(params.amount);
        }
        // checkpoint claimPriceLast
        (
            cache,
            params
        ) = _checkpoint(state, pool, params, constants, cache);
        
        // clear position values if empty
        if (cache.position.liquidity == 0) {
            cache.position.accumEpochLast = 0;
            cache.position.claimPriceLast = 0;
        }    
        return cache.position;
    }

    function _convert(
        uint128 liquidity,
        uint128 percent
    ) internal pure returns (
        uint128
    ) {
        // convert percentage to liquidity amount
        if (percent > 1e38) require (false, 'InvalidBurnPercentage()');
        if (liquidity == 0 && percent > 0) require (false, 'NotEnoughPositionLiquidity()');
        return uint128(uint256(liquidity) * uint256(percent) / 1e38);
    }

    function _deltas(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) internal view returns (
        ICoverPoolStructs.UpdatePositionCache memory,
        ICoverPoolStructs.GlobalState memory
    ) {
        ICoverPoolStructs.UpdatePositionCache memory cache = ICoverPoolStructs.UpdatePositionCache({
            position: positions[params.owner][params.lower][params.upper],
            pool: pool,
            priceLower: ConstantProduct.getPriceAtTick(params.lower, constants),
            priceClaim: ConstantProduct.getPriceAtTick(params.claim, constants),
            priceUpper: ConstantProduct.getPriceAtTick(params.upper, constants),
            priceSpread: ConstantProduct.getPriceAtTick(params.zeroForOne ? params.claim - constants.tickSpread 
                                                                          : params.claim + constants.tickSpread,
                                                        constants),
            amountInFilledMax: 0,
            amountOutUnfilledMax: 0,
            claimTick: ticks[params.claim],
            finalTick: ticks[params.zeroForOne ? params.lower : params.upper],
            earlyReturn: false,
            removeLower: true,
            removeUpper: true,
            deltas: ICoverPoolStructs.Deltas(0,0,0,0),
            finalDeltas: ICoverPoolStructs.Deltas(0,0,0,0)
        });

        params.amount = _convert(cache.position.liquidity, params.amount);

        // check claim is valid
        cache = Claims.validate(
            positions,
            tickMap,
            state,
            cache.pool,
            params,
            cache,
            constants
        );
        if (cache.earlyReturn) {
            return (cache, state);
        }
        if (params.amount > 0)
            _size(
                ICoverPoolStructs.SizeParams(
                    cache.priceLower,
                    cache.priceUpper,
                    cache.position.liquidity - params.amount,
                    params.zeroForOne,
                    state.latestTick,
                    uint24((params.upper - params.lower) / constants.tickSpread)
                ),
                constants
            );
        // get deltas from claim tick
        cache = Claims.getDeltas(cache, params);
        /// @dev - section 1 => position start - previous auction
        cache = Claims.section1(cache, params, constants);
        /// @dev - section 2 => position start -> claim tick
        cache = Claims.section2(cache, params);
        // check if auction in progress 
        if (params.claim == state.latestTick 
            && params.claim != (params.zeroForOne ? params.lower : params.upper)) {
            /// @dev - section 3 => claim tick - unfilled section
            cache = Claims.section3(cache, params, cache.pool);
            /// @dev - section 4 => claim tick - filled section
            cache = Claims.section4(cache, params, cache.pool);
        }
        /// @dev - section 5 => claim tick -> position end
        cache = Claims.section5(cache, params);
        // adjust position amounts based on deltas
        cache = Claims.applyDeltas(state, cache, params);

        return (cache, state);
    }

    function _size(
        ICoverPoolStructs.SizeParams memory params,
        ICoverPoolStructs.Immutables memory constants
    ) internal pure  
    {
        // early return if 100% of position burned
        if (constants.minAmountPerAuction == 0) return;
        if (params.liquidityAmount == 0 || params.auctionCount == 0) return;
        // set minAmountPerAuction based on token decimals
        uint256 minAmountPerAuction; bool denomTokenIn;
        if (params.latestTick > 0) {
            if (constants.minAmountLowerPriced) {
                // token1 is the lower priced token
                denomTokenIn = !params.zeroForOne;
                minAmountPerAuction = constants.minAmountPerAuction / 10**(18 - constants.token1Decimals);
            } else {
                // token0 is the higher priced token
                denomTokenIn = params.zeroForOne;
                minAmountPerAuction = constants.minAmountPerAuction / 10**(18 - constants.token0Decimals);
            }
        } else {
            if (constants.minAmountLowerPriced) {
                // token0 is the lower priced token
                denomTokenIn = params.zeroForOne;
                minAmountPerAuction = constants.minAmountPerAuction / 10**(18 - constants.token0Decimals);
            } else {
                // token1 is the higher priced token
                denomTokenIn = !params.zeroForOne;
                minAmountPerAuction = constants.minAmountPerAuction / 10**(18 - constants.token1Decimals);
            }
        }
        if (params.zeroForOne) {
            //calculate amount in the position currently
            uint128 amount = uint128(ConstantProduct.getDx(
                params.liquidityAmount,
                params.priceLower,
                params.priceUpper,
                false
            ));
            if (denomTokenIn) {
                if (amount / params.auctionCount < minAmountPerAuction)
                    require (false, 'PositionAuctionAmountTooSmall()');
            } else {
                // denominate in incoming token
                uint256 priceAverage = (params.priceUpper + params.priceLower) / 2;
                uint256 convertedAmount = amount * priceAverage / Q96 
                                                 * priceAverage / Q96; // convert by squaring price
                if (convertedAmount / params.auctionCount < minAmountPerAuction) 
                    require (false, 'PositionAuctionAmountTooSmall()');
            }
        } else {
            uint128 amount = uint128(ConstantProduct.getDy(
                params.liquidityAmount,
                params.priceLower,
                params.priceUpper,
                false
            ));
            if (denomTokenIn) {
                // denominate in token1
                // calculate amount in position currently
                if (amount / params.auctionCount < minAmountPerAuction) 
                    require (false, 'PositionAuctionAmountTooSmall()');
            } else {
                // denominate in token0
                uint256 priceAverage = (params.priceUpper + params.priceLower) / 2;
                uint256 convertedAmount = amount * Q96 / priceAverage 
                                                 * Q96 / priceAverage; // convert by squaring price
                if (convertedAmount / params.auctionCount < minAmountPerAuction) 
                    require (false, 'PositionAuctionAmountTooSmall()');
            }
        }
    }

    function _checkpoint(
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState memory pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.Immutables memory constants,
        ICoverPoolStructs.UpdatePositionCache memory cache
    ) internal pure returns (
        ICoverPoolStructs.UpdatePositionCache memory,
        ICoverPoolStructs.UpdateParams memory
    ) {
        // update claimPriceLast
        cache.priceClaim = ConstantProduct.getPriceAtTick(params.claim, constants);
        cache.position.claimPriceLast = (params.claim == state.latestTick)
            ? pool.price
            : cache.priceClaim;
        /// @dev - if tick 0% filled, set CPL to latestTick
        if (pool.price == cache.priceSpread) cache.position.claimPriceLast = cache.priceClaim;
        /// @dev - if tick 100% filled, set CPL to next tick to unlock
        if (pool.price == cache.priceClaim && params.claim == state.latestTick){
            cache.position.claimPriceLast = cache.priceSpread;
            // set claim tick to claim + tickSpread
            params.claim = params.zeroForOne ? params.claim - constants.tickSpread
                                             : params.claim + constants.tickSpread;
        }
        return (cache, params);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/ICoverPoolStructs.sol';
import './math/ConstantProduct.sol';

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
        ICoverPoolStructs.Immutables memory constants
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
        ICoverPoolStructs.Immutables memory constants
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/ICoverPoolStructs.sol';
import '../utils/CoverPoolErrors.sol';
import './math/FullPrecisionMath.sol';
import '../interfaces/modules/curves/ICurveMath.sol';
import '../interfaces/modules/sources/ITwapSource.sol';
import './TickMap.sol';

/// @notice Tick management library for ranged liquidity.
library Ticks {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    event Initialize(
        int24 minTick,
        int24 maxTick,
        int24 latestTick,
        uint32 genesisTime,
        uint32 auctionStart,
        uint160 pool0Price,
        uint160 pool1Price
    );

    function quote(
        bool zeroForOne,
        uint160 priceLimit,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.SwapCache memory cache,
        ICoverPoolStructs.Immutables memory constants
    ) internal pure returns (ICoverPoolStructs.SwapCache memory) {
        if ((zeroForOne ? priceLimit >= cache.price 
                        : priceLimit <= cache.price) 
            || cache.liquidity == 0 
            || cache.input == 0
        )
            return cache;
        uint256 nextPrice = state.latestPrice;
        // determine input boost from tick auction
        cache.auctionBoost = ((cache.auctionDepth <= constants.auctionLength) ? cache.auctionDepth
                                                                              : constants.auctionLength
                             ) * 1e14 / constants.auctionLength * uint16(constants.tickSpread);
        cache.inputBoosted = cache.input * (1e18 + cache.auctionBoost) / 1e18;
        if (zeroForOne) {
            // trade token 0 (x) for token 1 (y)
            // price decreases
            if (priceLimit > nextPrice) {
                // stop at price limit
                nextPrice = priceLimit;
            }
            uint256 maxDx = ConstantProduct.getDx(cache.liquidity, nextPrice, cache.price, false);
            // check if all input is used
            if (cache.inputBoosted <= maxDx) {
                // calculate price after swap
                uint256 newPrice = ConstantProduct.getNewPrice(cache.price, cache.liquidity, cache.inputBoosted, zeroForOne);
                cache.output += ConstantProduct.getDy(cache.liquidity, newPrice, cache.price, false);
                cache.price = newPrice;
                cache.input = 0;
                cache.amountInDelta = cache.amountIn;
            } else if (maxDx > 0) {
                cache.output += ConstantProduct.getDy(cache.liquidity, nextPrice, cache.price, false);
                cache.price = nextPrice;
                cache.input -= maxDx * (1e18 - cache.auctionBoost) / 1e18; /// @dev - convert back to input amount
                cache.amountInDelta = cache.amountIn - cache.input;
            }
        } else {
            // price increases
            if (priceLimit < nextPrice) {
                // stop at price limit
                nextPrice = priceLimit;
            }
            uint256 maxDy = ConstantProduct.getDy(cache.liquidity, cache.price, nextPrice, false);
            if (cache.inputBoosted <= maxDy) {
                // calculate price after swap
                uint256 newPrice = ConstantProduct.getNewPrice(cache.price, cache.liquidity, cache.inputBoosted, zeroForOne);
                cache.output += ConstantProduct.getDx(cache.liquidity, cache.price, newPrice, false);
                cache.price = newPrice;
                cache.input = 0;
                cache.amountInDelta = cache.amountIn;
            } else if (maxDy > 0) {
                cache.output += ConstantProduct.getDx(cache.liquidity, cache.price, nextPrice, false);
                cache.price = nextPrice;
                cache.input -= maxDy * (1e18 - cache.auctionBoost) / 1e18; 
                cache.amountInDelta = cache.amountIn - cache.input;
            }
        }
        return (cache);
    }

    function initialize(
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.PoolState storage pool0,
        ICoverPoolStructs.PoolState storage pool1,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants 
    ) external returns (ICoverPoolStructs.GlobalState memory) {
        if (state.unlocked == 0) {
            (state.unlocked, state.latestTick) = constants.source.initialize(constants);
            if (state.unlocked == 1) {
                // initialize state
                state.latestTick = (state.latestTick / int24(constants.tickSpread)) * int24(constants.tickSpread);
                state.latestPrice = ConstantProduct.getPriceAtTick(state.latestTick, constants);
                state.auctionStart = uint32(block.timestamp - constants.genesisTime);
                state.accumEpoch = 1;

                // initialize ticks
                TickMap.set(ConstantProduct.minTick(constants.tickSpread), tickMap, constants);
                TickMap.set(ConstantProduct.maxTick(constants.tickSpread), tickMap, constants);
                TickMap.set(state.latestTick, tickMap, constants);

                // initialize price
                pool0.price = ConstantProduct.getPriceAtTick(state.latestTick - constants.tickSpread, constants);
                pool1.price = ConstantProduct.getPriceAtTick(state.latestTick + constants.tickSpread, constants);
            
                emit Initialize(
                    ConstantProduct.minTick(constants.tickSpread),
                    ConstantProduct.maxTick(constants.tickSpread),
                    state.latestTick,
                    constants.genesisTime,
                    state.auctionStart,
                    pool0.price,
                    pool1.price
                );
            }
        }
        return state;
    }

    function insert(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.Immutables memory constants,
        int24 lower,
        int24 upper,
        uint128 amount,
        bool isPool0
    ) external {
        /// @dev - validation of ticks is in Positions.validate
        if (amount > uint128(type(int128).max)) require (false, 'LiquidityOverflow()');
        if ((uint128(type(int128).max) - state.liquidityGlobal) < amount)
            require (false, 'LiquidityOverflow()');

        // load ticks into memory to reduce reads/writes
        ICoverPoolStructs.Tick memory tickLower = ticks[lower];
        ICoverPoolStructs.Tick memory tickUpper = ticks[upper];

        // sets bit in map
        TickMap.set(lower, tickMap, constants);

        // updates liquidity values
        if (isPool0) {
                tickLower.liquidityDelta -= int128(amount);
        } else {
                tickLower.liquidityDelta += int128(amount);
        }

        TickMap.set(upper, tickMap, constants);

        if (isPool0) {
                tickUpper.liquidityDelta += int128(amount);
        } else {
            tickUpper.liquidityDelta -= int128(amount);
        }
        ticks[lower] = tickLower;
        ticks[upper] = tickUpper;
    }

    function remove(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants,
        int24 lower,
        int24 upper,
        uint128 amount,
        bool isPool0,
        bool removeLower,
        bool removeUpper
    ) external {
        {
            ICoverPoolStructs.Tick memory tickLower = ticks[lower];
            if (removeLower) {
                if (isPool0) {
                    tickLower.liquidityDelta += int128(amount);
                } else {
                    tickLower.liquidityDelta -= int128(amount);
                }
                ticks[lower] = tickLower;
            }
            if (lower != ConstantProduct.minTick(constants.tickSpread)) {
                cleanup(ticks, tickMap, constants, tickLower, lower);
            }
        }
        {
            ICoverPoolStructs.Tick memory tickUpper = ticks[upper];
            if (removeUpper) {
                if (isPool0) {
                    tickUpper.liquidityDelta -= int128(amount);
                } else {
                    tickUpper.liquidityDelta += int128(amount);
                }
                ticks[upper] = tickUpper;
            }
            if (upper != ConstantProduct.maxTick(constants.tickSpread)) {
                cleanup(ticks, tickMap, constants, tickUpper, upper);
            }
        }
    }

    function cleanup(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.TickMap storage tickMap,
        ICoverPoolStructs.Immutables memory constants,
        ICoverPoolStructs.Tick memory tick,
        int24 tickIndex
    ) internal {
        if (_empty(tick)) {
            TickMap.unset(tickIndex, tickMap, constants);
            delete ticks[tickIndex];
        } else {
            // if one of the values is 0 clear out both
            if (tick.amountInDeltaMaxMinus == 0 || tick.amountOutDeltaMaxMinus == 0) {
                tick.amountInDeltaMaxMinus = 0;
                tick.amountOutDeltaMaxMinus = 0;
            }
            if (tick.amountInDeltaMaxStashed == 0 || tick.amountOutDeltaMaxStashed == 0) {
                tick.amountInDeltaMaxStashed = 0;
                tick.amountOutDeltaMaxStashed = 0;
            }
            if (_inactive(tick)) {
                // zero out all values for safety
                tick.amountInDeltaMaxMinus = 0;
                tick.amountOutDeltaMaxMinus = 0;
                tick.amountInDeltaMaxStashed = 0;
                tick.amountOutDeltaMaxStashed = 0;
                TickMap.unset(tickIndex, tickMap, constants);
            }
            ticks[tickIndex] = tick;
        }
    }

    function _inactive(
        ICoverPoolStructs.Tick memory tick
    ) internal pure returns (
        bool
    ) {
        if (tick.amountInDeltaMaxStashed > 0 && tick.amountOutDeltaMaxStashed > 0) {
            return false;
        } else if (tick.amountInDeltaMaxMinus > 0 && tick.amountOutDeltaMaxMinus > 0){
            return false;
        } else if (tick.liquidityDelta != 0) {
            return false;
        }
        return true;
    }

    function _empty(
        ICoverPoolStructs.Tick memory tick
    ) internal pure returns (
        bool
    ) {
        if (tick.amountInDeltaMaxStashed > 0 && tick.amountOutDeltaMaxStashed > 0) {
            return false;
        } else if (tick.amountInDeltaMaxMinus > 0 && tick.amountOutDeltaMaxMinus > 0){
            return false;
        } else if (tick.deltas.amountInDeltaMax > 0 && tick.deltas.amountOutDeltaMax > 0) {
            return false;
        } else if (tick.liquidityDelta != 0) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library String {
    bytes16 private constant alphabet = "0123456789abcdef";

    function from(bytes32 value) internal pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function from(address account) internal pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function from(uint256 value) internal pure returns(string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), alphabet))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function from(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", from(abs(value))));
    }

    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }

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

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract CoverPoolErrors {
    error Locked();
    error OwnerOnly();
    error InvalidToken();
    error InvalidPosition();
    error InvalidSwapFee();
    error InvalidTokenDecimals();
    error InvalidTickSpread();
    error LiquidityOverflow();
    error Token0Missing();
    error Token1Missing();
    error InvalidTick();
    error FactoryOnly();
    error LowerNotEvenTick();
    error UpperNotOddTick();
    error MaxTickLiquidity();
    error CollectToZeroAddress();
    error Overflow();
    error NotEnoughOutputLiquidity();
    error WaitUntilEnoughObservations();
}

abstract contract CoverTicksErrors {
    error WrongTickLowerRange();
    error WrongTickUpperRange();
    error WrongTickLowerOrder();
    error WrongTickUpperOrder();
    error WrongTickClaimedAt();
}

abstract contract CoverMiscErrors {
    // to be removed before production
    error NotImplementedYet();
}

abstract contract CoverPositionErrors {
    error NotEnoughPositionLiquidity();
    error InvalidClaimTick();
}

abstract contract CoverPoolFactoryErrors {
    error OwnerOnly();
    error InvalidPoolTokenAddress();
    error PoolAlreadyExists();
    error FeeTierNotSupported();
    error VolatilityTierNotSupported();
    error InvalidTickSpread();
    error TwapSourceNotFound();
    error CurveMathNotFound();
    error TickSpreadNotMultipleOfTickSpacing();
    error TickSpreadNotAtLeastDoubleTickSpread();
}

abstract contract CoverTransferErrors {
    error TransferFailed(address from, address dest);
}