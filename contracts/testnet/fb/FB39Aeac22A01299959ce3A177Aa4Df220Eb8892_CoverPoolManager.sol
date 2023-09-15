// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

abstract contract CoverPoolManagerEvents {
    event FactoryChanged(address indexed previousFactory, address indexed newFactory);
    event VolatilityTierEnabled(
        bytes32 poolType,
        uint16  feeTier,
        int16   tickSpread,
        uint16  twapLength,
        uint128 minAmountPerAuction,
        uint16  auctionLength,
        uint16  blockTime,
        uint16  syncFee,
        uint16  fillFee,
        int16   minPositionWidth,
        bool    minLowerPriced
    );
    event PoolTypeEnabled(
        bytes32 poolType,
        address implAddress,
        address sourceAddress,
        address factoryAddress
    );
    event FeeToTransfer(address indexed previousFeeTo, address indexed newFeeTo);
    event OwnerTransfer(address indexed previousOwner, address indexed newOwner);
    event ProtocolFeesModified(
        address[] modifyPools,
        uint16[] syncFees,
        uint16[] fillFees,
        bool[] setFees,
        uint128[] token0Fees,
        uint128[] token1Fees
    );
    event ProtocolFeesCollected(
        address[] collectPools,
        uint128[] token0Fees,
        uint128[] token1Fees
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

abstract contract CoverPoolFactoryStorage {
    mapping(bytes32 => address) public coverPools;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../structs/CoverPoolStructs.sol';
import '../structs/PoolsharkStructs.sol';

/**
 * @title ICoverPool
 * @author Poolshark
 * @notice Defines the basic interface for a Cover Pool.
 */
interface ICoverPool is CoverPoolStructs {
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
     * @notice Swaps `tokenIn` for `tokenOut`. 
               `tokenIn` will be `token0` if `zeroForOne` is true.
               `tokenIn` will be `token1` if `zeroForOne` is false.
               The pool price represents token1 per token0.
               The pool price will decrease if `zeroForOne` is true.
               The pool price will increase if `zeroForOne` is false. 
     * @param params The parameters for the function. See SwapParams above.
     * @return amount0Delta The amount of token0 spent (negative) or received (positive) by the user
     * @return amount1Delta The amount of token1 spent (negative) or received (positive) by the user
     */
    function swap(
        SwapParams memory params
    ) external returns (
        int256 amount0Delta,
        int256 amount1Delta
    );

    /**
     * @notice Quotes the amount of `tokenIn` for `tokenOut`. 
               `tokenIn` will be `token0` if `zeroForOne` is true.
               `tokenIn` will be `token1` if `zeroForOne` is false.
               The pool price represents token1 per token0.
               The pool price will decrease if `zeroForOne` is true.
               The pool price will increase if `zeroForOne` is false. 
     * @param params The parameters for the function. See SwapParams above.
     * @return inAmount  The amount of tokenIn to be spent
     * @return outAmount The amount of tokenOut to be received
     * @return priceAfter The Q64.96 square root price after the swap
     */
    function quote(
        QuoteParams memory params
    ) external view returns (
        int256 inAmount,
        int256 outAmount,
        uint256 priceAfter
    );

    /**
     * @custom:struct SnapshotParams
     */
    struct SnapshotParams {
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
     * @notice Snapshots the current state of an existing position. 
     * @param params The parameters for the function. See SwapParams above.
     * @return position The updated position containing `amountIn` and `amountOut`
     * @dev positions amounts reflected will be collected by the user if `burn` is called
     */
    function snapshot(
        SnapshotParams memory params
    ) external view returns (
        CoverPosition memory position
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

    function immutables(
    ) external view returns (
        CoverImmutables memory constants
    );

    function priceBounds(
        int16 tickSpacing
    ) external pure returns (
        uint160 minPrice,
        uint160 maxPrice
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '../../base/storage/CoverPoolFactoryStorage.sol';

abstract contract ICoverPoolFactory is CoverPoolFactoryStorage {

    struct CoverPoolParams {
        bytes32 poolType;
        address tokenIn;
        address tokenOut;
        uint16 feeTier;
        int16  tickSpread;
        uint16 twapLength;
    }

    /**
     * @notice Creates a new CoverPool.
     * @param params The CoverPoolParams struct referenced above.
     */
    function createCoverPool(
        CoverPoolParams memory params
    ) external virtual returns (
        address pool,
        address poolToken
    );

    /**
     * @notice Fetches an existing CoverPool.
     * @param params The CoverPoolParams struct referenced above.
     */
    function getCoverPool(
        CoverPoolParams memory params
    ) external view virtual returns (
        address pool,
        address poolToken
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../../interfaces/structs/CoverPoolStructs.sol';

/// @notice CoverPoolManager interface
interface ICoverPoolManager is CoverPoolStructs {
    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function poolTypes(
        bytes32 poolType
    ) external view returns (
        address poolImpl,
        address tokenImpl,
        address twapImpl
    );
    function volatilityTiers(
        bytes32 implName,
        uint16 feeTier,
        int16  tickSpread,
        uint16 twapLength
    ) external view returns (
        VolatilityTier memory
    );
}

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
        uint16  blockTime; // average block time where 1e3 is 1 second
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
        uint16 blockTime;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import '../interfaces/cover/ICoverPool.sol';
import '../interfaces/cover/ICoverPoolFactory.sol';
import '../interfaces/cover/ICoverPoolManager.sol';
import '../base/events/CoverPoolManagerEvents.sol';

/**
 * @dev Defines the actions which can be executed by the factory admin.
 */
contract CoverPoolManager is ICoverPoolManager, CoverPoolManagerEvents {
    address public owner;
    address public feeTo;
    address public factory;
    uint16  public constant MAX_PROTOCOL_FEE = 1e4; /// @dev - max protocol fee of 1%
    uint16  public constant oneSecond = 1000;
    // sourceName => sourceAddress
    mapping(bytes32 => address) internal _poolTypes;
    mapping(bytes32 => address) internal _poolTokens;
    mapping(bytes32 => address) internal _twapSources;
    // sourceName => feeTier => tickSpread => twapLength => VolatilityTier
    mapping(bytes32 => mapping(uint16 => mapping(int16 => mapping(uint16 => VolatilityTier)))) internal _volatilityTiers;

    constructor() {
        owner = msg.sender;
        feeTo = msg.sender;
        emit OwnerTransfer(address(0), msg.sender);
        emit FeeToTransfer(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyFeeTo() {
        _checkFeeTo();
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwner(address newOwner) public virtual onlyOwner {
        if(newOwner == address(0)) require (false, 'TransferredToZeroAddress()');
        _transferOwner(newOwner);
    }

    function transferFeeTo(address newFeeTo) public virtual onlyFeeTo {
        if(newFeeTo == address(0)) require (false, 'TransferredToZeroAddress()');
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

    function enablePoolType(
        bytes32 poolType,
        address poolImpl,
        address tokenImpl,
        address twapImpl
    ) external onlyOwner {
        if (poolType[0] == bytes32("")) require (false, 'TwapSourceNameInvalid()');
        if (poolImpl == address(0) || twapImpl == address(0)) require (false, 'TwapSourceAddressZero()');
        if (_twapSources[poolType] != address(0)) require (false, 'ImplementationAlreadyExists()');
        if (_poolTypes[poolType] != address(0)) require (false, 'ImplementationAlreadyExists()');
        _poolTypes[poolType] = poolImpl;
        _poolTokens[poolType] = tokenImpl;
        _twapSources[poolType] = twapImpl;
        emit PoolTypeEnabled(poolType, poolImpl, twapImpl, ITwapSource(twapImpl).factory());
    }

    function enableVolatilityTier(
        bytes32 poolType,
        uint16  feeTier,
        int16   tickSpread,
        uint16  twapLength,
        VolatilityTier memory volTier
    ) external onlyOwner {
        if (_volatilityTiers[poolType][feeTier][tickSpread][twapLength].auctionLength != 0) {
            require (false, 'VolatilityTierAlreadyEnabled()');
        } else if (volTier.auctionLength == 0 ||  volTier.minPositionWidth <= 0) {
            require (false, 'VolatilityTierCannotBeZero()');
        } else if (twapLength < 5 * volTier.blockTime / oneSecond) {
            require (false, 'VoltatilityTierTwapTooShort()');
        } else if (volTier.syncFee > 10000 || volTier.fillFee > 10000) {
            require (false, 'ProtocolFeeCeilingExceeded()');
        }
        address sourceAddress = _twapSources[poolType];
        {
            // check fee tier exists
            if (sourceAddress == address(0)) require (false, 'TwapSourceNotFound()');
            int24 tickSpacing = ITwapSource(sourceAddress).feeTierTickSpacing(feeTier);
            if (tickSpacing == 0) {
                require (false, 'FeeTierNotSupported()');
            }
            // check tick multiple
            int24 tickMultiple = tickSpread / tickSpacing;
            if (tickMultiple * tickSpacing != tickSpread) {
                require (false, 'TickSpreadNotMultipleOfTickSpacing()');
            } else if (tickMultiple < 2) {
                require (false, 'TickSpreadNotAtLeastDoubleTickSpread()');
            }
        }
        // twapLength * blockTime should never overflow uint16
        _volatilityTiers[poolType][feeTier][tickSpread][twapLength] = volTier;

        emit VolatilityTierEnabled(
            poolType,
            feeTier,
            tickSpread,
            twapLength,
            volTier.minAmountPerAuction,
            volTier.auctionLength,
            volTier.blockTime,
            volTier.syncFee,
            volTier.fillFee,
            volTier.minPositionWidth,
            volTier.minAmountLowerPriced
        );
    }

    function modifyVolatilityTierFees(
        bytes32 implName,
        uint16 feeTier,
        int16 tickSpread,
        uint16 twapLength,
        uint16 syncFee,
        uint16 fillFee
    ) external onlyOwner {
        if (syncFee > 10000 || fillFee > 10000) {
            require (false, 'ProtocolFeeCeilingExceeded()');
        }
        _volatilityTiers[implName][feeTier][tickSpread][twapLength].syncFee = syncFee;
        _volatilityTiers[implName][feeTier][tickSpread][twapLength].fillFee = fillFee;
    }

    function setFactory(
        address factory_
    ) external onlyOwner {
        if (factory != address(0)) require (false, 'FactoryAlreadySet()');
        emit FactoryChanged(factory, factory_);
        factory = factory_;
    }

    function collectProtocolFees(
        address[] calldata collectPools
    ) external {
        if (collectPools.length == 0) require (false, 'EmptyPoolsArray()');
        uint128[] memory token0Fees = new uint128[](collectPools.length);
        uint128[] memory token1Fees = new uint128[](collectPools.length);
        for (uint i; i < collectPools.length; i++) {
            (token0Fees[i], token1Fees[i]) = ICoverPool(collectPools[i]).fees(0,0,false);
        }
        emit ProtocolFeesCollected(collectPools, token0Fees, token1Fees);
    }

    function modifyProtocolFees(
        address[] calldata modifyPools,
        uint16[] calldata syncFees,
        uint16[] calldata fillFees,
        bool[] calldata setFees
    ) external onlyOwner {
        if (modifyPools.length == 0) require (false, 'EmptyPoolsArray()');
        if (modifyPools.length != syncFees.length
            || syncFees.length != fillFees.length
            || fillFees.length != setFees.length) {
            require (false, 'MismatchedArrayLengths()');
        }
        uint128[] memory token0Fees = new uint128[](modifyPools.length);
        uint128[] memory token1Fees = new uint128[](modifyPools.length);
        for (uint i; i < modifyPools.length; i++) {
            if (syncFees[i] > MAX_PROTOCOL_FEE) require (false, 'ProtocolFeeCeilingExceeded()');
            if (fillFees[i] > MAX_PROTOCOL_FEE) require (false, 'ProtocolFeeCeilingExceeded()');
            (
                token0Fees[i],
                token1Fees[i]
            ) =ICoverPool(modifyPools[i]).fees(
                syncFees[i],
                fillFees[i],
                setFees[i]
            );
        }
        emit ProtocolFeesModified(modifyPools, syncFees, fillFees, setFees, token0Fees, token1Fees);
    }

    function poolTypes(
        bytes32 poolType
    ) external view returns (
        address poolImpl,
        address tokenImpl,
        address twapImpl
    ) {
        return (
            _poolTypes[poolType],
            _poolTokens[poolType],
            _twapSources[poolType]
        );
    }

    function volatilityTiers(
        bytes32 implName,
        uint16 feeTier,
        int16 tickSpread,
        uint16 twapLength
    ) external view returns (
        VolatilityTier memory config
    ) {
        config = _volatilityTiers[implName][feeTier][tickSpread][twapLength];
    }
    
    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view {
        if (owner != msg.sender) require (false, 'OwnerOnly()');
    }

    /**
     * @dev Throws if the sender is not the feeTo.
     */
    function _checkFeeTo() internal view {
        if (feeTo != msg.sender) require (false, 'FeeToOnly()');
    }
}