// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../../interfaces/structs/PoolsharkStructs.sol';

abstract contract LimitPoolManagerEvents is PoolsharkStructs {
    event FactoryChanged(address indexed previousFactory, address indexed newFactory);
    event ImplementationEnabled(
        bytes32 key,
        address poolImpl,
        address tokenImpl
    );
    event FeeTierEnabled(
        uint16 swapFee,
        int16 tickSpacing
    );
    event FeeToTransfer(address indexed previousFeeTo, address indexed newFeeTo);
    event OwnerTransfer(address indexed previousOwner, address indexed newOwner);
    event ProtocolSwapFeesModified(
        address[] pools,
        uint16[] protocolSwapFees0,
        uint16[] protocolSwapFees1
    );
    event ProtocolFillFeesModified(
        address[] pools,
        uint16[] protocolFillFees0,
        uint16[] protocolFillFees1
    );
    event ProtocolFeesCollected(
        address[] pools,
        uint128[] token0FeesCollected,
        uint128[] token1FeesCollected
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

abstract contract LimitPoolFactoryStorage {
    mapping(bytes32 => address) public pools;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../structs/LimitPoolStructs.sol';
import '../structs/LimitPoolFactoryStructs.sol';

interface ILimitPool is LimitPoolStructs {
    function initialize(
        uint160 startPrice
    ) external;

    function mintLimit(
        MintLimitParams memory params
    ) external;

    function burnLimit(
        BurnLimitParams memory params
    ) external;

    function snapshotLimit(
        SnapshotLimitParams memory params
    ) external view returns(
        uint128,
        uint128
    );

    function fees(
        FeesParams memory params
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );

    function immutables(
    ) external view returns(
        LimitImmutables memory
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

import '../structs/PoolsharkStructs.sol';
import '../../base/storage/LimitPoolFactoryStorage.sol';

abstract contract ILimitPoolFactory is LimitPoolFactoryStorage, PoolsharkStructs {
    function createLimitPool(
        LimitPoolParams memory params
    ) external virtual returns (
        address pool,
        address poolToken
    );

    function getLimitPool(
        bytes32 poolType,
        address tokenIn,
        address tokenOut,
        uint16  swapFee
    ) external view virtual returns (
        address pool,
        address poolToken
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/// @notice LimitPoolManager interface
interface ILimitPoolManager {
    
    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function implementations(
        bytes32 poolType
    ) external view returns (
        address poolImpl,
        address tokenImpl
    );
    function feeTiers(
        uint16 swapFee
    ) external view returns (
        int16 tickSpacing
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface LimitPoolFactoryStructs {
    struct LimitPoolParams {
        address owner;
        address token0;
        address token1;
        uint160 minPrice;
        uint160 maxPrice;
        uint160 startPrice;
        int16   tickSpacing;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../interfaces/IPool.sol';
import '../interfaces/limit/ILimitPool.sol';
import '../interfaces/limit/ILimitPoolFactory.sol';
import '../interfaces/limit/ILimitPoolManager.sol';
import '../base/events/LimitPoolManagerEvents.sol';

/**
 * @dev Defines the actions which can be executed by the factory admin.
 */
contract LimitPoolManager is ILimitPoolManager, LimitPoolManagerEvents {
    address public owner;
    address public feeTo;
    address public factory;
    uint16  public constant MAX_PROTOCOL_SWAP_FEE = 1e4; /// @dev - max protocol swap fee of 100%
    uint16  public constant MAX_PROTOCOL_FILL_FEE = 1e2; /// @dev - max protocol fill fee of 1%
    // impl name => impl address
    mapping(bytes32 => address) internal _poolImpls;
    mapping(bytes32 => address) internal _tokenImpls;
    // swap fee => tick spacing
    mapping(uint16 => int16) internal _feeTiers;

    error InvalidSwapFee();
    error InvalidTickSpacing();
    error InvalidImplAddress();
    error TickSpacingAlreadyEnabled();
    error ImplementationAlreadyExists();

    constructor() {
        owner = msg.sender;
        feeTo = msg.sender;
        emit OwnerTransfer(address(0), msg.sender);

        // create initial fee tiers
        _feeTiers[500] = 10;
        _feeTiers[10000] = 100;
        emit FeeTierEnabled(500, 10);
        emit FeeTierEnabled(10000, 100);
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
        emit OwnerTransfer(oldFeeTo, newFeeTo);
    }

    function enableTickSpacing(
        int16 tickSpacing,
        uint16 swapFee
    ) external onlyOwner {
        if (_feeTiers[swapFee] != 0) revert TickSpacingAlreadyEnabled();
        if (tickSpacing <= 0) revert InvalidTickSpacing();
        if (tickSpacing % 2 != 0) revert InvalidTickSpacing();
        if (swapFee == 0) revert InvalidSwapFee();
        if (swapFee > 10000) revert InvalidSwapFee();
        _feeTiers[swapFee] = tickSpacing;
        emit FeeTierEnabled(swapFee, tickSpacing);
    }

    function enableImplementation(
        bytes32 poolType_,
        address poolImpl_,
        address tokenImpl_
    ) external onlyOwner {
        if (_poolImpls[poolType_] != address(0)) revert ImplementationAlreadyExists();
        if (poolImpl_ == address(0) || tokenImpl_ == address(0)) revert InvalidImplAddress();
        /// @dev - prevent same addresses since factory does not support this
        if (poolImpl_ == tokenImpl_) revert InvalidImplAddress();
        _poolImpls[poolType_] = poolImpl_;
        _tokenImpls[poolType_] = tokenImpl_;
        emit ImplementationEnabled(poolType_, poolImpl_, tokenImpl_);
    }

    function setFactory(
        address factory_
    ) external onlyOwner {
        if (factory != address(0)) require (false, 'FactoryAlreadySet()');
        emit FactoryChanged(factory, factory_);
        factory = factory_;
    }

    function collectProtocolFees(
        address[] calldata pools
    ) external {
        if (pools.length == 0) require (false, 'EmptyPoolsArray()');
        uint128[] memory token0FeesCollected = new uint128[](pools.length);
        uint128[] memory token1FeesCollected = new uint128[](pools.length);
        // pass empty fees params
        FeesParams memory feesParams;
        for (uint i; i < pools.length;) {
            (
                token0FeesCollected[i],
                token1FeesCollected[i]
            ) = IPool(pools[i]).fees(feesParams);
            unchecked {
                ++i;
            }
        }
        emit ProtocolFeesCollected(pools, token0FeesCollected, token1FeesCollected);
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
        if (pools.length == 0) require (false, 'EmptyPoolsArray()');
        if (pools.length != feesParams.length) {
            require (false, 'MismatchedArrayLengths()');
        }
        uint128[] memory token0FeesCollected = new uint128[](pools.length);
        uint128[] memory token1FeesCollected = new uint128[](pools.length);
        uint16[] memory protocolSwapFees0 = new uint16[](pools.length);
        uint16[] memory protocolSwapFees1 = new uint16[](pools.length);
        uint16[] memory protocolFillFees0 = new uint16[](pools.length);
        uint16[] memory protocolFillFees1 = new uint16[](pools.length);
        for (uint i; i < pools.length;) {
            (
                token0FeesCollected[i],
                token1FeesCollected[i]
            ) = IPool(pools[i]).fees(
                feesParams[i]
            );
            if ((feesParams[i].setFeesFlags & PROTOCOL_SWAP_FEE_0) > 0) {
                protocolSwapFees0[i] = feesParams[i].protocolSwapFee0;
            }
            if ((feesParams[i].setFeesFlags & PROTOCOL_SWAP_FEE_1) > 0) {
                protocolSwapFees1[i] = feesParams[i].protocolSwapFee1;
            }
            if ((feesParams[i].setFeesFlags & PROTOCOL_FILL_FEE_0) > 0) {
                protocolFillFees0[i] = feesParams[i].protocolFillFee0;
            }
            if ((feesParams[i].setFeesFlags & PROTOCOL_FILL_FEE_1) > 0) {
                protocolFillFees1[i] = feesParams[i].protocolFillFee1;
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

    function implementations(
        bytes32 key
    ) external view returns (
        address,
        address
    ) {
        return (_poolImpls[key], _tokenImpls[key]);
    }

    function feeTiers(
        uint16 swapFee
    ) external view returns (
        int16 tickSpacing
    ) {
        return _feeTiers[swapFee];
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