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
pragma solidity 0.8.13;

import './IRangePoolStructs.sol';
import './IRangePoolManager.sol';

interface IRangePool is IRangePoolStructs {
    function mint(MintParams calldata mintParams) external;

    function burn(BurnParams calldata burnParams) external;

    function swap(
        address recipient,
        address refundRecipient,
        bool zeroForOne,
        uint256 amountIn,
        uint160 priceLimit
    ) external returns (
        int256 amount0,
        int256 amount1
    );

    function quote(
        bool zeroForOne,
        uint256 amountIn,
        uint160 priceLimit
    ) external view returns (
        uint256 inAmount,
        uint256 outAmount,
        uint160 priceAfter
    );

    function increaseSampleLength(
        uint16 sampleLengthNext
    ) external;

    function protocolFees(
        uint16 protocolFee,
        bool setFee
    ) external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );

    function owner() external view returns (
        address
    );

    function tickSpacing() external view returns (
        int24
    );

    function samples(uint256) external view returns (
        uint32,
        int56,
        uint160
    );

    function poolState() external view returns (
        uint8,
        uint16,
        int24,
        int56,
        uint160,
        uint160,
        uint128,
        uint128,
        uint200,
        uint200,
        SampleState memory,
        ProtocolFees memory
    );

    function ticks(int24) external view returns (
        int128,
        uint200,
        uint200,
        int56,
        uint160
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRangePoolERC1155 is IERC165 {
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

    function mintFungible(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function burnFungible(
        address account,
        uint256 id,
        uint256 amount
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

import './IRangePoolStructs.sol';
import './IRangePoolERC1155.sol';

interface IRangePoolManager {
    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function protocolFees(address pool) external view returns (uint16);
    function feeTiers(uint16 swapFee) external view returns (int24);
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./IRangePoolERC1155.sol";

interface IRangePoolStructs {
    struct PoolState {
        uint8   unlocked;
        uint16  protocolFee;
        int24   tickAtPrice;
        int56   tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
        uint160 price;               /// @dev Starting price current
        uint128 liquidity;           /// @dev Liquidity currently active
        uint128 liquidityGlobal;     /// @dev Globally deposited liquidity
        uint200 feeGrowthGlobal0;
        uint200 feeGrowthGlobal1;
        SampleState  samples;
        ProtocolFees protocolFees;
    }

    struct SampleState {
        uint16  index;
        uint16  length;
        uint16  lengthNext;
    }

    struct Tick {
        int128  liquidityDelta;
        uint200 feeGrowthOutside0; // Per unit of liquidity.
        uint200 feeGrowthOutside1;
        int56   tickSecondsAccumOutside;
        uint160 secondsPerLiquidityAccumOutside;
    }

    struct TickMap {
        uint256 blocks;                     /// @dev - sets of words
        mapping(uint256 => uint256) words;  /// @dev - sets to words
        mapping(uint256 => uint256) ticks;  /// @dev - words to ticks
    }

    struct TickParams {
        TickMap tickMap;
        mapping(int24 => Tick) ticks;
    }

    struct Position {
        uint128 liquidity;
        uint128 amount0;
        uint128 amount1;
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
    }

    struct Sample {
        uint32  blockTimestamp;
        int56   tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
    }

    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }

    struct Immutables {
        uint16 swapFee;
        int24  tickSpacing;
    }

    struct MintParams {
        address to;
        int24 lower;
        int24 upper;
        uint128 amount0;
        uint128 amount1;
        bool fungible;
    }

    struct BurnParams {
        address to;
        int24 lower;
        int24 upper;
        uint128 amount;
        bool fungible;
        bool collect;
    }

    struct CompoundParams {
        address owner;
        int24 lower;
        int24 upper;
        bool fungible;
    }

    struct SwapParams {
        address recipient;
        bool zeroForOne;
        uint160 priceLimit;
        uint256 amountIn;
    }

    struct SampleParams {
        uint16 sampleIndex;
        uint16 sampleLength;
        uint32 time;
        uint32[] secondsAgos;
        int24 tick;
        uint128 liquidity;
    }

    struct AddParams {
        PoolState state;
        MintParams mint;
        uint128 amount;
        uint128 liquidity;
    }

    struct RemoveParams {
        uint128 amount0;
        uint128 amount1;
    }

    struct UpdateParams {
        address owner;
        int24 lower;
        int24 upper;
        uint128 amount;
        bool fungible;
    }

    struct MintCache {
        PoolState pool;
        MintParams params;
        Position position;
    }

    struct SwapCache {
        bool    cross;
        int24   tick;
        int24   crossTick;
        uint16  swapFee;
        uint16  protocolFee;
        int56   tickSecondsAccum;
        uint160 secondsPerLiquidityAccum;
        uint160 crossPrice;
        uint256 input;
        uint256 output;
        uint256 amountIn;
    }

    struct PositionCache {
        uint160 priceLower;
        uint160 priceUpper;
        uint256 liquidityOnPosition;
        uint256 liquidityAmount;
        uint256 totalSupply;
        uint256 tokenId;
    }

    struct UpdatePositionCache {
        Position position;
        uint160 priceLower;
        uint160 priceUpper;
        bool removeLower;
        bool removeUpper;
        int128 amountInDelta;
        int128 amountOutDelta;
    }

    struct SnapshotCache {
        int24   tick;
        uint160 price;
        uint32  blockTimestamp;
        uint32  secondsOutsideLower;
        uint32  secondsOutsideUpper;
        int56   tickSecondsAccum;
        int56   tickSecondsAccumLower;
        int56   tickSecondsAccumUpper;
        uint128 liquidity;
        uint160 secondsPerLiquidityAccum;
        uint160 secondsPerLiquidityAccumLower;
        uint160 secondsPerLiquidityAccumUpper;
        SampleState samples;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import './PrecisionMath.sol';

/// @notice Math library that facilitates ranged liquidity calculations.
library DyDxMath {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    error AmountsOutOfBounds();
    error PriceOutsideBounds();

    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (uint256 dy) {
        return _getDy(liquidity, priceLower, priceUpper, roundUp);
    }

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (uint256 dx) {
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
                dy = PrecisionMath.mulDivRoundingUp(liquidity, priceUpper - priceLower, Q96);
            } else {
                dy = PrecisionMath.mulDiv(liquidity, priceUpper - priceLower, Q96);
            }
        }
    }

    function _getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        if (roundUp) {
            dx = PrecisionMath.divRoundingUp(
                PrecisionMath.mulDivRoundingUp(
                    liquidity << 96,
                    priceUpper - priceLower,
                    priceUpper
                ),
                priceLower
            );
        } else {
            dx =
                PrecisionMath.mulDiv(liquidity << 96, priceUpper - priceLower, priceUpper) /
                priceLower;
        }
    }

    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) external pure returns (uint256 liquidity) {
        unchecked {
            if (priceUpper <= currentPrice) {
                liquidity = PrecisionMath.mulDiv(dy, Q96, priceUpper - priceLower);
            } else if (currentPrice <= priceLower) {
                liquidity = PrecisionMath.mulDiv(
                    dx,
                    PrecisionMath.mulDiv(priceLower, priceUpper, Q96),
                    priceUpper - priceLower
                );
            } else {
                uint256 liquidity0 = PrecisionMath.mulDiv(
                    dx,
                    PrecisionMath.mulDiv(priceUpper, currentPrice, Q96),
                    priceUpper - currentPrice
                );
                uint256 liquidity1 = PrecisionMath.mulDiv(dy, Q96, currentPrice - priceLower);
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
    ) external pure returns (
        uint128,
        uint128
    ) {
        uint256 dx; uint256 dy;
        if (currentPrice <= priceLower) {
            // token0 (X) is supplied
            dx = _getDx(liquidityAmount, priceLower, priceUpper, roundUp);
        } else if (priceUpper <= currentPrice) {
            // token1 (y) is supplied
            dy = _getDy(liquidityAmount, priceLower, priceUpper, roundUp);
        } else {
            // Both token0 (x) and token1 (y) are supplied
            dx = _getDx(liquidityAmount, currentPrice, priceUpper, roundUp);
            dy = _getDy(liquidityAmount, priceLower, currentPrice, roundUp);
        }
        if (dx > uint128(type(int128).max)) require(false, 'AmountsOutOfBounds()');
        if (dy > uint128(type(int128).max)) require(false, 'AmountsOutOfBounds()');
        return (uint128(dx), uint128(dy));
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./PrecisionMath.sol";
import "../interfaces/IRangePoolStructs.sol";

/// @notice Math library that facilitates fee handling.
library FeeMath {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    function calculate(
        IRangePoolStructs.PoolState memory pool,
        IRangePoolStructs.SwapCache memory cache,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (
            IRangePoolStructs.PoolState memory,
            IRangePoolStructs.SwapCache memory
        )
    {
        if (pool.liquidity == 0 ) return (pool, cache);
        uint256 feeAmount = PrecisionMath.mulDivRoundingUp(amountOut, cache.swapFee, 1e6); 
        uint256 protocolFee = PrecisionMath.mulDivRoundingUp(feeAmount, cache.protocolFee, 1e6);
        amountOut -= feeAmount;
        feeAmount -= protocolFee;

        if (zeroForOne) {
           pool.protocolFees.token1 += uint128(protocolFee);
           pool.feeGrowthGlobal1 += uint200(PrecisionMath.mulDiv(feeAmount, Q128, pool.liquidity));
        } else {
          pool.protocolFees.token0 += uint128(protocolFee);
          pool.feeGrowthGlobal0 += uint200(PrecisionMath.mulDiv(feeAmount, Q128, pool.liquidity));
        }
        cache.output += amountOut;
        return (pool, cache);
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../interfaces/IRangePoolStructs.sol';
import './DyDxMath.sol';
import './FeeMath.sol';
import './PrecisionMath.sol';
import './TickMath.sol';
import './Ticks.sol';
import './Tokens.sol';
import './Samples.sol';

/// @notice Position management library for ranged liquidity.
library Positions {
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

    event Mint(
        address indexed recipient,
        int24 lower,
        int24 upper,
        uint128 liquidityMinted,
        uint128 amount0,
        uint128 amount1
    );

    event Burn(
        address owner,
        address indexed recipient,
        int24 indexed lower,
        int24 indexed upper,
        uint128 liquidityBurned,
        uint128 amount0,
        uint128 amount1,
        bool collect
    );

    event Compound(
        address indexed owner,
        int24 indexed lower,
        int24 indexed upper,
        uint128 liquidityCompounded,
        uint128 positionAmount0,
        uint128 positionAmount1
    );

    event MintFungible(
        address indexed recipient,
        int24 lower,
        int24 upper,
        uint256 indexed tokenId,
        uint128 tokenMinted,
        uint128 liquidityMinted,
        uint128 amount0,
        uint128 amount1
    );

    event BurnFungible(
        address indexed recipient,
        int24 lower,
        int24 upper,
        uint256 indexed tokenId,
        uint128 tokenBurned,
        uint128 liquidityBurned,
        uint128 amount0,
        uint128 amount1
    );

    function validate(
        IRangePoolStructs.MintParams memory params,
        IRangePoolStructs.PoolState memory state,
        IRangePoolStructs.Immutables memory constants
    ) external pure returns (IRangePoolStructs.MintParams memory, uint256 liquidityMinted) {
        Ticks.validate(params.lower, params.upper, constants.tickSpacing);
        
        uint256 priceLower = uint256(TickMath.getSqrtRatioAtTick(params.lower));
        uint256 priceUpper = uint256(TickMath.getSqrtRatioAtTick(params.upper));

        liquidityMinted = DyDxMath.getLiquidityForAmounts(
            priceLower,
            priceUpper,
            state.price,
            params.amount1,
            params.amount0
        );
        if (liquidityMinted == 0) require(false, 'NoLiquidityBeingAdded()');
        (params.amount0, params.amount1) = DyDxMath.getAmountsForLiquidity(
            priceLower,
            priceUpper,
            state.price,
            liquidityMinted,
            true
        );
        if (liquidityMinted > uint128(type(int128).max)) require(false, 'LiquidityOverflow()');

        return (params, liquidityMinted);
    }

    function add(
        IRangePoolStructs.Position memory position,
        mapping(int24 => IRangePoolStructs.Tick) storage ticks,
        IRangePoolStructs.Sample[65535] storage samples,
        IRangePoolStructs.TickMap storage tickMap,
        IRangePoolStructs.AddParams memory params
    ) external returns (
        IRangePoolStructs.PoolState memory,
        IRangePoolStructs.Position memory,
        uint128
    ) {
        if (params.mint.amount0 == 0 && params.mint.amount1 == 0) return (params.state, position, 0);

        IRangePoolStructs.PositionCache memory cache = IRangePoolStructs.PositionCache({
            priceLower: TickMath.getSqrtRatioAtTick(params.mint.lower),
            priceUpper: TickMath.getSqrtRatioAtTick(params.mint.upper),
            liquidityOnPosition: 0,
            liquidityAmount: 0,
            totalSupply: Tokens.totalSupply(address(this), params.mint.lower, params.mint.upper),
            tokenId: Tokens.id(params.mint.lower, params.mint.upper)
        });

        params.state = Ticks.insert(
            ticks,
            samples,
            tickMap,
            params.state,
            params.mint.lower,
            params.mint.upper,
            params.amount
        );

        (
            position.feeGrowthInside0Last,
            position.feeGrowthInside1Last
        ) = rangeFeeGrowth(
            ticks[params.mint.lower],
            ticks[params.mint.upper],
            params.state,
            params.mint.lower,
            params.mint.upper
        );

        position.liquidity += uint128(params.amount);
        
        // modify liquidity minted to account for fees accrued
        if (params.mint.fungible) {
            if (position.amount0 > 0 || position.amount1 > 0
                || (position.liquidity - params.amount) > cache.totalSupply) {
                // modify amount based on autocompounded fees
                if (cache.totalSupply > 0) {
                    cache.liquidityOnPosition = DyDxMath.getLiquidityForAmounts(
                                                    cache.priceLower,
                                                    cache.priceUpper,
                                                    position.amount0 > 0 ? cache.priceLower : cache.priceUpper,
                                                    position.amount1,
                                                    position.amount0
                                                );
                    params.amount = uint128(uint256(params.amount) * cache.totalSupply /
                         (uint256(position.liquidity - params.amount) + cache.liquidityOnPosition));
                } /// @dev - if there are fees on the position we mint less positionToken
            }
            IRangePoolERC1155(address(this)).mintFungible(params.mint.to, cache.tokenId, params.amount);
            emit MintFungible(
                params.mint.to,
                params.mint.lower,
                params.mint.upper,
                cache.tokenId,
                params.amount,
                params.liquidity,
                params.mint.amount0,
                params.mint.amount1
            );
        } else {
            emit Mint(
                params.mint.to, 
                params.mint.lower,
                params.mint.upper,
                params.amount,
                params.mint.amount0,
                params.mint.amount1
            );
        }
        return (params.state, position, params.amount);
    }

    function remove(
        IRangePoolStructs.Position memory position,
        mapping(int24 => IRangePoolStructs.Tick) storage ticks,
        IRangePoolStructs.Sample[65535] storage samples,
        IRangePoolStructs.TickMap storage tickMap,
        IRangePoolStructs.PoolState memory state,
        IRangePoolStructs.BurnParams memory params,
        IRangePoolStructs.RemoveParams memory removeParams
    ) external returns (
        IRangePoolStructs.PoolState memory,
        IRangePoolStructs.Position memory,
        uint128,
        uint128
    ) {
        IRangePoolStructs.PositionCache memory cache = IRangePoolStructs.PositionCache({
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper),
            liquidityOnPosition: 0,
            liquidityAmount: 0,
            totalSupply: 0,
            tokenId: Tokens.id(params.lower, params.upper)
        }); 
        if (params.fungible){
            
            cache.totalSupply = Tokens.totalSupplyById(address(this), cache.tokenId);
        }
        cache.liquidityAmount = params.fungible && params.amount > 0 ? uint256(params.amount) * uint256(position.liquidity) 
                                                                       / (cache.totalSupply + params.amount)
                                                                     : params.amount;
        if (params.amount == 0) {
            emit Burn(
                params.fungible ? address(this) : msg.sender,
                msg.sender,
                params.lower,
                params.upper,
                params.amount,
                removeParams.amount0,
                removeParams.amount1,
                params.collect
            );
            return (state, position, removeParams.amount0, removeParams.amount1);
        } 
        if (params.amount > position.liquidity) require(false, 'NotEnoughPositionLiquidity()');
        {
            uint128 amount0Removed; uint128 amount1Removed;
            (amount0Removed, amount1Removed) = DyDxMath.getAmountsForLiquidity(
                cache.priceLower,
                cache.priceUpper,
                state.price,
                cache.liquidityAmount,
                false
            );
            if (params.fungible && params.amount > 0) {
                params.collect = true;
            }
            removeParams.amount0 += amount0Removed;
            removeParams.amount1 += amount1Removed;

            position.amount0 += amount0Removed;
            position.amount1 += amount1Removed;
            position.liquidity -= uint128(cache.liquidityAmount);
        }
        if (position.liquidity == 0) {
            position.feeGrowthInside0Last = 0;
            position.feeGrowthInside1Last = 0;
        }
        state = Ticks.remove(
            ticks,
            samples,
            tickMap,
            state, 
            params.lower,
            params.upper,
            uint128(cache.liquidityAmount)
        );

        if (params.fungible) {
            emit BurnFungible(
                params.to,
                params.lower,
                params.upper,
                cache.tokenId,
                params.amount,
                uint128(cache.liquidityAmount),
                removeParams.amount0,
                removeParams.amount1
            );
        } else {
            emit Burn(
                params.fungible ? address(this) : msg.sender,
                msg.sender,
                params.lower,
                params.upper,
                uint128(cache.liquidityAmount),
                removeParams.amount0,
                removeParams.amount1,
                params.collect
            );
        }
        return (state, position, removeParams.amount0, removeParams.amount1);
    }

    function compound(
        IRangePoolStructs.Position memory position,
        mapping(int24 => IRangePoolStructs.Tick) storage ticks,
        IRangePoolStructs.Sample[65535] storage samples,
        IRangePoolStructs.TickMap storage tickMap,
        IRangePoolStructs.PoolState memory state,
        IRangePoolStructs.CompoundParams memory params
    ) external returns (IRangePoolStructs.Position memory, IRangePoolStructs.PoolState memory) {
        IRangePoolStructs.PositionCache memory cache = IRangePoolStructs.PositionCache({
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper),
            liquidityOnPosition: 0,
            liquidityAmount: 0,
            totalSupply: 0,
            tokenId: 0
        });

        // price tells you the ratio so you need to swap into the correct ratio and add liquidity
        cache.liquidityAmount = DyDxMath.getLiquidityForAmounts(
            cache.priceLower,
            cache.priceUpper,
            state.price,
            position.amount1,
            position.amount0
        );
        if (cache.liquidityAmount > 0) {
            state = Ticks.insert(
                ticks,
                samples,
                tickMap,
                state,
                params.lower,
                params.upper,
                uint128(cache.liquidityAmount)
            );
            uint256 amount0; uint256 amount1;
            (amount0, amount1) = DyDxMath.getAmountsForLiquidity(
                cache.priceLower,
                cache.priceUpper,
                state.price,
                cache.liquidityAmount,
                true
            );
            position.amount0 -= (amount0 <= position.amount0) ? uint128(amount0) : position.amount0;
            position.amount1 -= (amount1 <= position.amount1) ? uint128(amount1) : position.amount1;
            position.liquidity += uint128(cache.liquidityAmount);
        }
        emit Compound(
            params.owner,
            params.lower,
            params.upper,
            uint128(cache.liquidityAmount),
            position.amount0,
            position.amount1
        );
        return (position, state);
    }

    function update(
        mapping(int24 => IRangePoolStructs.Tick) storage ticks,
        IRangePoolStructs.Position memory position,
        IRangePoolStructs.PoolState memory state,
        IRangePoolStructs.UpdateParams memory params
    ) external returns (
        IRangePoolStructs.Position memory, 
        uint128, 
        uint128
    ) {
        uint256 totalSupply;
        if (params.fungible) {
            totalSupply = Tokens.totalSupply(address(this), params.lower, params.upper);
            if (params.amount > 0) {
                uint256 tokenId = Tokens.id(params.lower, params.upper);
                IRangePoolERC1155(address(this)).burnFungible(msg.sender, tokenId, params.amount);
            }
        }
        
        (uint256 rangeFeeGrowth0, uint256 rangeFeeGrowth1) = rangeFeeGrowth(
            ticks[params.lower],
            ticks[params.upper],
            state,
            params.lower,
            params.upper
        );

        uint128 amount0Fees = uint128(
            PrecisionMath.mulDiv(
                rangeFeeGrowth0 - position.feeGrowthInside0Last,
                uint256(position.liquidity),
                Q128
            )
        );

        uint128 amount1Fees = uint128(
            PrecisionMath.mulDiv(
                rangeFeeGrowth1 - position.feeGrowthInside1Last,
                position.liquidity,
                Q128
            )
        );

        position.feeGrowthInside0Last = rangeFeeGrowth0;
        position.feeGrowthInside1Last = rangeFeeGrowth1;

        position.amount0 += uint128(amount0Fees);
        position.amount1 += uint128(amount1Fees);

        if (params.fungible) {
            uint128 feesBurned0; uint128 feesBurned1;
            if (params.amount > 0) {
                feesBurned0 = uint128(
                    (uint256(position.amount0) * uint256(uint128(params.amount))) / (totalSupply)
                );
                feesBurned1 = uint128(
                    (uint256(position.amount1) * uint256(uint128(params.amount))) / (totalSupply)
                );
            }
            return (position, feesBurned0, feesBurned1);
        }
        return (position, amount0Fees, amount1Fees);
    }

    function rangeFeeGrowth(
        IRangePoolStructs.Tick memory lowerTick,
        IRangePoolStructs.Tick memory upperTick,
        IRangePoolStructs.PoolState memory state,
        int24 lower,
        int24 upper
    ) internal pure returns (uint256 feeGrowthInside0, uint256 feeGrowthInside1) {

        uint256 feeGrowthGlobal0 = state.feeGrowthGlobal0;
        uint256 feeGrowthGlobal1 = state.feeGrowthGlobal1;

        uint256 feeGrowthBelow0;
        uint256 feeGrowthBelow1;
        if (state.tickAtPrice >= lower) {
            feeGrowthBelow0 = lowerTick.feeGrowthOutside0;
            feeGrowthBelow1 = lowerTick.feeGrowthOutside1;
        } else {
            feeGrowthBelow0 = feeGrowthGlobal0 - lowerTick.feeGrowthOutside0;
            feeGrowthBelow1 = feeGrowthGlobal1 - lowerTick.feeGrowthOutside1;
        }

        uint256 feeGrowthAbove0;
        uint256 feeGrowthAbove1;
        if (state.tickAtPrice < upper) {
            feeGrowthAbove0 = upperTick.feeGrowthOutside0;
            feeGrowthAbove1 = upperTick.feeGrowthOutside1;
        } else {
            feeGrowthAbove0 = feeGrowthGlobal0 - upperTick.feeGrowthOutside0;
            feeGrowthAbove1 = feeGrowthGlobal1 - upperTick.feeGrowthOutside1;
        }
        feeGrowthInside0 = feeGrowthGlobal0 - feeGrowthBelow0 - feeGrowthAbove0;
        feeGrowthInside1 = feeGrowthGlobal1 - feeGrowthBelow1 - feeGrowthAbove1;
    }

    function rangeFeeGrowth(
        address pool,
        int24 lower,
        int24 upper
    ) external view returns (
        uint256 feeGrowthInside0,
        uint256 feeGrowthInside1
    ) {
        Ticks.validate(lower, upper, IRangePool(pool).tickSpacing());
        (
            ,,
            int24 currentTick,
            ,,,,,
            uint256 _feeGrowthGlobal0,
            uint256 _feeGrowthGlobal1,
            ,
        ) = IRangePool(pool).poolState();
        (
            ,
            uint216 tickLowerFeeGrowthOutside0,
            uint216 tickLowerFeeGrowthOutside1,
            ,
        )
            = IRangePool(pool).ticks(lower);
        (
            ,
            uint216 tickUpperFeeGrowthOutside0,
            uint216 tickUpperFeeGrowthOutside1,
            ,
        )
            = IRangePool(pool).ticks(upper);

        // ticks not initialized or range not crossed into
        if (tickLowerFeeGrowthOutside0 == 0
            && tickLowerFeeGrowthOutside1 == 0
            && tickUpperFeeGrowthOutside0 == 0
            && tickUpperFeeGrowthOutside0 == 0) {
            return (0,0);
        }

        uint256 feeGrowthBelow0;
        uint256 feeGrowthBelow1;
        uint256 feeGrowthAbove0;
        uint256 feeGrowthAbove1;

        if (lower <= currentTick) {
            feeGrowthBelow0 = tickLowerFeeGrowthOutside0;
            feeGrowthBelow1 = tickLowerFeeGrowthOutside1;
        } else {
            feeGrowthBelow0 = _feeGrowthGlobal0 - tickLowerFeeGrowthOutside0;
            feeGrowthBelow1 = _feeGrowthGlobal1 - tickLowerFeeGrowthOutside1;
        }

        if (currentTick < upper) {
            feeGrowthAbove0 = tickUpperFeeGrowthOutside0;
            feeGrowthAbove1 = tickUpperFeeGrowthOutside1;
        } else {
            feeGrowthAbove0 = _feeGrowthGlobal0 - tickUpperFeeGrowthOutside0;
            feeGrowthAbove1 = _feeGrowthGlobal1 - tickUpperFeeGrowthOutside1;
        }
        feeGrowthInside0 = _feeGrowthGlobal0 - feeGrowthBelow0 - feeGrowthAbove0;
        feeGrowthInside1 = _feeGrowthGlobal1 - feeGrowthBelow1 - feeGrowthAbove1;
    }

    function snapshot(
        address pool,
        int24 lower,
        int24 upper
    ) external view returns (
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum,
        uint32  secondsGrowth
    ) {
        Ticks.validate(lower, upper, IRangePool(pool).tickSpacing());

        IRangePoolStructs.SnapshotCache memory cache;
        (
            ,
            ,,,,
            cache.price,
            cache.liquidity,
            ,,,
            cache.samples,
        ) = IRangePool(pool).poolState();
        (
            ,,,
            cache.tickSecondsAccumLower,
            cache.secondsPerLiquidityAccumLower
        )
            = IRangePool(pool).ticks(lower);

        // if both have never been crossed into return 0
        (
            ,,,
            cache.tickSecondsAccumUpper,
            cache.secondsPerLiquidityAccumUpper
        )
            = IRangePool(pool).ticks(upper);

        // ticks not initialized or range not crossed into
        if (cache.secondsOutsideUpper == 0
            && cache.secondsOutsideLower == 0){
            return (0,0,0);
        }
        
        cache.tick = TickMath.getTickAtSqrtRatio(cache.price);

        if (lower >= cache.tick) {
            return (
                cache.tickSecondsAccumLower - cache.tickSecondsAccumUpper,
                cache.secondsPerLiquidityAccumLower - cache.secondsPerLiquidityAccumUpper,
                cache.secondsOutsideLower - cache.secondsOutsideUpper
            );
        } else if (upper >= cache.tick) {
            cache.blockTimestamp = uint32(block.timestamp);
            (
                cache.tickSecondsAccum,
                cache.secondsPerLiquidityAccum
            ) = Samples.getSingle(
                IRangePool(address(this)), 
                IRangePoolStructs.SampleParams(
                    cache.samples.index,
                    cache.samples.length,
                    uint32(block.timestamp),
                    new uint32[](2),
                    cache.tick,
                    cache.liquidity
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
                cache.blockTimestamp
                  - cache.secondsOutsideLower
                  - cache.secondsOutsideUpper
            );
        }
    }

    function id(int24 lower, int24 upper) public pure returns (uint256) {
        return Tokens.id(lower, upper);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library PrecisionMath {
    error MaxUintExceeded();

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result) {
        return _mulDiv(a, b, denominator);
    }

    // @dev no underflow or overflow checks
    function divRoundingUp(uint256 x, uint256 y) external pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result) {
        return _mulDivRoundingUp(a, b, denominator);
    }

    /// @notice Calculates floor(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    function _mulDiv(
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
    function _mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = _mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) != 0) {
                if (result >= type(uint256).max) revert MaxUintExceeded();
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../interfaces/IRangePool.sol';
import '../interfaces/IRangePoolStructs.sol';

library Samples {

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
        IRangePoolStructs.Sample[65535] storage samples,
        IRangePoolStructs.PoolState memory state
    ) external returns (
        IRangePoolStructs.PoolState memory
    )
    {
        samples[0] = IRangePoolStructs.Sample({
            blockTimestamp: uint32(block.timestamp),
            tickSecondsAccum: 0,
            secondsPerLiquidityAccum: 0
        });

        emit SampleRecorded(
            0,
            0
        );

        state.samples.length = 1;
        state.samples.lengthNext = 5;

        return state;
        /// @dev - TWAP length of 5 is safer for oracle manipulation
    }

    function save(
        IRangePoolStructs.Sample[65535] storage samples,
        IRangePoolStructs.PoolState memory state,
        int24  tick
    ) external returns (
        uint16 sampleIndexNew,
        uint16 sampleLengthNew
    ) {
        // grab the latest sample
        IRangePoolStructs.Sample memory newSample = samples[state.samples.index];

        // early return if newest sample within 5 seconds
        if (newSample.blockTimestamp + 5 >= uint32(block.timestamp))
            return (state.samples.index, state.samples.length);

        if (state.samples.lengthNext > state.samples.length
            && state.samples.index == (state.samples.length - 1)) {
            // increase sampleLengthNew if old size exceeded
            sampleLengthNew = state.samples.lengthNext;
        } else {
            sampleLengthNew = state.samples.length;
        }
        sampleIndexNew = (state.samples.index + 1) % sampleLengthNew;
        samples[sampleIndexNew] = _build(newSample, uint32(block.timestamp), tick, state.liquidity);

        emit SampleRecorded(
            samples[sampleIndexNew].tickSecondsAccum,
            samples[sampleIndexNew].secondsPerLiquidityAccum
        );
    }

    function expand(
        IRangePoolStructs.Sample[65535] storage samples,
        IRangePoolStructs.PoolState memory state,
        uint16 sampleLengthNext
    ) external returns (
        IRangePoolStructs.PoolState memory
    ) {
        if (state.samples.length == 0) require(false, 'SampleArrayUninitialized()');
        for (uint16 i = state.samples.lengthNext; i < sampleLengthNext; i++) {
            samples[i].tickSecondsAccum = 1;
        }
        state.samples.lengthNext = sampleLengthNext;
        emit SampleLengthIncreased(sampleLengthNext);
        return state;
    }

    function get(
        address pool,
        IRangePoolStructs.SampleParams memory params
    ) external view returns (
        int56[]   memory tickSecondsAccum,
        uint160[] memory secondsPerLiquidityAccum
    ) {
        if (params.sampleLength == 0) require(false, 'InvalidSampleLength()');

        tickSecondsAccum = new int56[](params.secondsAgos.length);
        secondsPerLiquidityAccum = new uint160[](params.secondsAgos.length);

        for (uint256 i = 0; i < params.secondsAgos.length; i++) {
            (
                tickSecondsAccum[i],
                secondsPerLiquidityAccum[i]
            ) = getSingle(
                IRangePool(pool),
                params,
                params.secondsAgos[i]
            );
        }
    }

    function _poolSample(
        IRangePool pool,
        uint256 sampleIndex
    ) internal view returns (
        IRangePoolStructs.Sample memory
    ) {
        (
            uint32 blockTimestamp,
            int56 tickSecondsAccum,
            uint160 liquidityPerSecondsAccum
        ) = pool.samples(sampleIndex);

        return IRangePoolStructs.Sample(
            blockTimestamp,
            tickSecondsAccum,
            liquidityPerSecondsAccum
        );
    }

    function getSingle(
        IRangePool pool,
        IRangePoolStructs.SampleParams memory params,
        uint32 secondsAgo
    ) public view returns (
        int56   tickSecondsAccum,
        uint160 secondsPerLiquidityAccum
    ) {
        IRangePoolStructs.Sample memory latest = _poolSample(pool, params.sampleIndex);

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

        (
            IRangePoolStructs.Sample memory firstSample,
            IRangePoolStructs.Sample memory secondSample
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
        IRangePoolStructs.Sample memory newSample,
        uint32  blockTimestamp,
        int24   tick,
        uint128 liquidity
    ) internal pure returns (
         IRangePoolStructs.Sample memory
    ) {
        int56 timeDelta = int56(uint56(blockTimestamp - newSample.blockTimestamp));
        return
            IRangePoolStructs.Sample({
                blockTimestamp: blockTimestamp,
                tickSecondsAccum: newSample.tickSecondsAccum + int56(tick) * int32(timeDelta),
                secondsPerLiquidityAccum: newSample.secondsPerLiquidityAccum +
                    ((uint160(uint56(timeDelta)) << 128) / (liquidity > 0 ? liquidity : 1))
            });
    }

    function _binarySearch(
        IRangePool pool,
        uint32 targetTime,
        uint16 sampleIndex,
        uint16 sampleLength
    ) private view returns (
        IRangePoolStructs.Sample memory firstSample,
        IRangePoolStructs.Sample memory secondSample
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
        IRangePool pool,
        IRangePoolStructs.Sample memory firstSample,
        IRangePoolStructs.SampleParams memory params,
        uint32 targetTime
    ) private view returns (
        IRangePoolStructs.Sample memory,
        IRangePoolStructs.Sample memory
    ) {
        if (_lte(firstSample.blockTimestamp, targetTime)) {
            if (firstSample.blockTimestamp == targetTime) {
                return (firstSample, IRangePoolStructs.Sample(0,0,0));
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
pragma solidity ^0.8.13;

import './TickMath.sol';
import '../interfaces/IRangePool.sol';
import '../interfaces/IRangePoolStructs.sol';

library TickMap {

    error TickIndexOverflow();
    error TickIndexUnderflow();
    error TickIndexBadSpacing();
    error BlockIndexOverflow();

    function init(
        IRangePoolStructs.TickMap storage tickMap,
        int24 tick,
        int24 tickSpacing
    ) external returns (
        bool exists
    )    
    {
        return _set(tickMap, tick, tickSpacing);
    }

    function set(
        IRangePoolStructs.TickMap storage tickMap,
        int24 tick
    ) external returns (
        bool exists
    )    
    {
        int24 tickSpacing = IRangePool(address(this)).tickSpacing();
        return _set(tickMap, tick, tickSpacing);
    }

    function unset(
        IRangePoolStructs.TickMap storage tickMap,
        int24 tick
    ) external {
        int24 tickSpacing = IRangePool(address(this)).tickSpacing();
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
        IRangePoolStructs.TickMap storage tickMap,
        int24 tick
    ) external view returns (
        int24 previousTick
    ) {
        unchecked {
            int24 tickSpacing = IRangePool(address(this)).tickSpacing();
            // rounds up to ensure relative position
            if (tick % tickSpacing != 0) tick += tickSpacing;
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
        IRangePoolStructs.TickMap storage tickMap,
        int24 tick
    ) external view returns (
        int24 nextTick
    ) {
        unchecked {
            int24 tickSpacing = IRangePool(address(this)).tickSpacing();
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
            if (tick > TickMath.MAX_TICK) require(false, ' TickIndexOverflow()');
            if (tick < TickMath.MIN_TICK) require(false, 'TickIndexUnderflow()');
            if (tick % tickSpacing != 0) tick = _round(tick, tickSpacing);
            tickIndex = uint256(int256((tick - _round(TickMath.MIN_TICK, tickSpacing)) / tickSpacing));
            wordIndex = tickIndex >> 8;   // 2^8 ticks per word
            blockIndex = tickIndex >> 16; // 2^8 words per block
            if (blockIndex > 255) require(false, 'BlockIndexOverflow()');
        }
    }

    function _set(
        IRangePoolStructs.TickMap storage tickMap,
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

    function _tick (
        uint256 tickIndex,
        int24 tickSpacing
    ) internal pure returns (
        int24 tick
    ) {
        unchecked {
            if (tickIndex > uint24(_round(TickMath.MAX_TICK, tickSpacing) * 2)) 
                require(false, 'TickIndexOverflow()');
            tick = int24(int256(tickIndex) * tickSpacing + _round(TickMath.MIN_TICK, tickSpacing));
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

    function _round(
        int24 tick,
        int24 tickSpacing
    ) internal pure returns (
        int24 roundedTick
    ) {
        return tick / tickSpacing * tickSpacing;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

/// @notice Math library for computing sqrt price for ticks of size 1.0001, i.e., sqrt(1.0001^tick) as fixed point Q64.96 numbers - supports
/// prices between 2**-128 and 2**128 - 1.
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128.
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128 - 1.
    int24 internal constant MAX_TICK = -MIN_TICK;
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MIN_TICK).
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MAX_TICK).
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    error TickOutOfBounds();
    error PriceOutOfBounds();

    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160 getSqrtPriceX96) {
        return _getSqrtRatioAtTick(tick);
    }

    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24 tick) {
        return _getTickAtSqrtRatio(sqrtPriceX96);
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96.
    /// @dev Throws if |tick| > max tick.
    /// @param tick The input tick for the above formula.
    /// @return sqrtPriceX96 Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick.
    function _getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        if (absTick > uint256(uint24(MAX_TICK))) require(false, 'TickOutOfBounds()');
        
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
            // We round up in the division so getTickAtSqrtRatio of the output price is always consistent.
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    function validatePrice(uint160 price) external pure {
        if (price < MIN_SQRT_RATIO || price >= MAX_SQRT_RATIO) {
            require(false, 'PriceOutOfBounds()');
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio.
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96.
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio.
    function _getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO)
            require(false, 'PriceOutOfBounds()');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

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

        tick = tickLow == tickHi ? tickLow : _getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import '../interfaces/IRangePoolStructs.sol';
import '../interfaces/IRangePoolFactory.sol';
import '../interfaces/IRangePool.sol';
import './DyDxMath.sol';
import './FeeMath.sol';
import './Positions.sol';
import './PrecisionMath.sol';
import './TickMath.sol';
import './TickMap.sol';
import './Samples.sol';

/// @notice Tick management library
library Ticks {
    error LiquidityOverflow();
    error LiquidityUnderflow();
    error InvalidLowerTick();
    error InvalidUpperTick();
    error InvalidPositionAmount();
    error InvalidPositionBounds();

    event Swap(
        address indexed recipient,
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountOut,
        uint160 price,
        uint128 liquidity,
        int24 tickAtPrice
    );

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    using Ticks for mapping(int24 => IRangePoolStructs.Tick);

    function initialize(
        IRangePoolStructs.TickMap storage tickMap,
        IRangePoolStructs.Sample[65535] storage samples,
        IRangePoolStructs.PoolState memory state,
        int24 tickSpacing
    ) external returns (
        IRangePoolStructs.PoolState memory
    )    
    {
        uint160 minPrice = TickMath.getSqrtRatioAtTick(TickMap._round(TickMath.MIN_TICK, tickSpacing));
        uint160 maxPrice = TickMath.getSqrtRatioAtTick(TickMap._round(TickMath.MAX_TICK, tickSpacing));
        if (state.price < minPrice || state.price >= maxPrice) require(false, 'StartPriceInvalid()');
        TickMap.init(tickMap, TickMath.MIN_TICK, tickSpacing);
        TickMap.init(tickMap, TickMath.MAX_TICK, tickSpacing);
        state.tickAtPrice = TickMath.getTickAtSqrtRatio(state.price);
        return (
            Samples.initialize(samples, state)
        );
    }

    function validate(
        int24 lower,
        int24 upper,
        int24 tickSpacing
    ) public pure {
        if (lower % tickSpacing != 0) require(false, 'InvalidLowerTick()');
        if (lower <= TickMath.MIN_TICK) require(false, 'InvalidLowerTick()');
        if (upper % tickSpacing != 0) require(false, 'InvalidUpperTick()');
        if (upper >= TickMath.MAX_TICK) require(false, 'InvalidUpperTick()');
        if (lower >= upper) require(false, 'InvalidPositionBounds()');
    }

    function swap(
        mapping(int24 => IRangePoolStructs.Tick) storage ticks,
        IRangePoolStructs.Sample[65535] storage samples,
        IRangePoolStructs.TickMap storage tickMap,
        address recipient,
        bool zeroForOne,
        uint160 priceLimit,
        uint16 swapFee,
        uint256 amountIn,
        IRangePoolStructs.PoolState memory pool
    )
        external returns (
            IRangePoolStructs.PoolState memory,
            IRangePoolStructs.SwapCache memory
        )
    {
        IRangePoolStructs.SwapCache memory cache = IRangePoolStructs.SwapCache({
            cross: true,
            tick: pool.tickAtPrice,
            crossTick: zeroForOne ? TickMap.previous(tickMap, pool.tickAtPrice) 
                                  : TickMap.next(tickMap, pool.tickAtPrice),
            crossPrice: 0,
            swapFee: swapFee,
            protocolFee: pool.protocolFee,
            input: amountIn,
            output: 0,
            amountIn: amountIn,
            tickSecondsAccum: 0,
            secondsPerLiquidityAccum: 0
        });
        // grab latest sample and store in cache for _cross
        (
            cache.tickSecondsAccum,
            cache.secondsPerLiquidityAccum
        ) = Samples.getSingle(
                IRangePool(address(this)), 
                IRangePoolStructs.SampleParams(
                    pool.samples.index,
                    pool.samples.length,
                    uint32(block.timestamp),
                    new uint32[](2),
                    cache.tick,
                    pool.liquidity
                ),
                0
        );
        while (cache.cross) {
            cache.crossPrice = TickMath.getSqrtRatioAtTick(cache.crossTick);
            (pool, cache) = _quoteSingle(zeroForOne, priceLimit, pool, cache);
            if (cache.cross) {
                (pool, cache) = _cross(
                    ticks,
                    tickMap,
                    pool,
                    cache,
                    zeroForOne
                );
            }
        }
        if (pool.price != cache.crossPrice) {
            pool.tickAtPrice = TickMath.getTickAtSqrtRatio(pool.price);
        } else {
            pool.tickAtPrice = cache.crossTick;
        }
        /// @dev - write oracle entry after start of block
        (
            pool.samples.index,
            pool.samples.length
        ) = Samples.save(
            samples,
            pool,
            pool.tickAtPrice
        );
        emit Swap(
            recipient,
            zeroForOne,
            amountIn - cache.input,
            cache.output, /// @dev - subgraph will do math to compute fee amount
            pool.price,
            pool.liquidity,
            pool.tickAtPrice
        );
        return (pool, cache);
    }

    function quote(
        mapping(int24 => IRangePoolStructs.Tick) storage ticks,
        IRangePoolStructs.TickMap storage tickMap,
        bool zeroForOne,
        uint160 priceLimit,
        uint16 swapFee,
        uint256 amountIn,
        IRangePoolStructs.PoolState memory pool
    )
        external view returns (
            IRangePoolStructs.PoolState memory,
            IRangePoolStructs.SwapCache memory
        )
    {
        IRangePoolStructs.SwapCache memory cache = IRangePoolStructs.SwapCache({
            cross: true,
            tick: 0,
            crossTick: zeroForOne ? TickMap.previous(tickMap, pool.tickAtPrice) 
                                  : TickMap.next(tickMap, pool.tickAtPrice),
            crossPrice: 0,
            swapFee: swapFee,
            protocolFee: pool.protocolFee,
            input: amountIn,
            output: 0,
            amountIn: amountIn,
            tickSecondsAccum: 0,
            secondsPerLiquidityAccum: 0
        });
        while (cache.cross) {
            cache.crossPrice = TickMath.getSqrtRatioAtTick(cache.crossTick);
            (pool, cache) = _quoteSingle(zeroForOne, priceLimit, pool, cache);
            if (cache.cross) {
                (pool, cache) = _pass(
                    ticks,
                    tickMap,
                    pool,
                    cache,
                    zeroForOne
                );
            }
        }
        return (pool, cache);
    }

    function _quoteSingle(
        bool zeroForOne,
        uint160 priceLimit,
        IRangePoolStructs.PoolState memory pool,
        IRangePoolStructs.SwapCache memory cache
    ) internal pure returns (
            IRangePoolStructs.PoolState memory,
            IRangePoolStructs.SwapCache memory
    ) {
        if (zeroForOne ? priceLimit >= pool.price
                       : priceLimit <= pool.price)
        {
            cache.cross = false;
            return (pool, cache);
        }
        uint256 nextPrice = cache.crossPrice;
        uint256 amountOut;
        if (zeroForOne) {
            // Trading token 0 (x) for token 1 (y).
            // price  is decreasing.
            if (nextPrice < priceLimit) {
                nextPrice = priceLimit;
            }
            uint256 maxDx = DyDxMath.getDx(pool.liquidity, nextPrice, pool.price, true);
            if (cache.input <= maxDx) {
                // We can swap within the current range.
                uint256 liquidityPadded = uint256(pool.liquidity) << 96;
                // calculate price after swap
                uint256 newPrice = PrecisionMath.mulDivRoundingUp(
                    liquidityPadded,
                    pool.price,
                    liquidityPadded + uint256(pool.price) * uint256(cache.input)
                );
                amountOut = DyDxMath.getDy(pool.liquidity, newPrice, uint256(pool.price), false);
                cache.input = 0;
                cache.cross = false;
                pool.price = uint160(newPrice);
            } else { 
                amountOut = DyDxMath.getDy(pool.liquidity, nextPrice, pool.price, false);
                cache.input -= maxDx;
                if (nextPrice == cache.crossPrice
                        && nextPrice != pool.price) { cache.cross = true; }
                else cache.cross = false;
                pool.price = uint160(nextPrice);
            }
        } else {
            // Price is increasing.
            if (nextPrice > priceLimit) {
                nextPrice = priceLimit;
            }
            uint256 maxDy = DyDxMath.getDy(pool.liquidity, uint256(pool.price), nextPrice, true);
            if (cache.input <= maxDy) {
                // We can swap within the current range.
                // Calculate new price after swap: ΔP = Δy/L.
                uint256 newPrice = pool.price +
                    PrecisionMath.mulDiv(cache.input, Q96, pool.liquidity);
                // Calculate output of swap
                amountOut = DyDxMath.getDx(pool.liquidity, pool.price, newPrice, false);
                cache.input = 0;
                cache.cross = false;
                pool.price = uint160(newPrice);
            } else {
                // Swap & cross the tick.
                amountOut = DyDxMath.getDx(pool.liquidity, pool.price, nextPrice, false);
                cache.input -= maxDy;
                if (nextPrice == cache.crossPrice 
                    && nextPrice != pool.price) { cache.cross = true; }
                else cache.cross = false;
                pool.price = uint160(nextPrice);
            }
        }
        (pool, cache) = FeeMath.calculate(pool, cache, amountOut, zeroForOne);
        return (pool, cache);
    }

    //maybe call ticks on msg.sender to get tick
    function _cross(
        mapping(int24 => IRangePoolStructs.Tick) storage ticks,
        IRangePoolStructs.TickMap storage tickMap,
        IRangePoolStructs.PoolState memory pool,
        IRangePoolStructs.SwapCache memory cache,
        bool zeroForOne
    ) internal returns (
        IRangePoolStructs.PoolState memory,
        IRangePoolStructs.SwapCache memory
    ) {
        IRangePoolStructs.Tick memory crossTick = ticks[cache.crossTick];
        crossTick.feeGrowthOutside0       = pool.feeGrowthGlobal0 - crossTick.feeGrowthOutside0;
        crossTick.feeGrowthOutside1       = pool.feeGrowthGlobal1 - crossTick.feeGrowthOutside1;
        crossTick.tickSecondsAccumOutside = cache.tickSecondsAccum - crossTick.tickSecondsAccumOutside;
        crossTick.secondsPerLiquidityAccumOutside = cache.secondsPerLiquidityAccum - crossTick.secondsPerLiquidityAccumOutside;
        ticks[cache.crossTick] = crossTick;
        // observe most recent oracle update
        if (zeroForOne) {
            unchecked {
                pool.liquidity -= uint128(ticks[cache.crossTick].liquidityDelta);
            }
            pool.tickAtPrice = cache.crossTick;
            cache.crossTick = TickMap.previous(tickMap, cache.crossTick);
        } else {
            unchecked {
                pool.liquidity += uint128(ticks[cache.crossTick].liquidityDelta);
            }
            pool.tickAtPrice = cache.crossTick;
            cache.crossTick = TickMap.next(tickMap, cache.crossTick);
        }
        return (pool, cache);
    }

    function _pass(
        mapping(int24 => IRangePoolStructs.Tick) storage ticks,
        IRangePoolStructs.TickMap storage tickMap,
        IRangePoolStructs.PoolState memory pool,
        IRangePoolStructs.SwapCache memory cache,
        bool zeroForOne
    ) internal view returns (
        IRangePoolStructs.PoolState memory,
        IRangePoolStructs.SwapCache memory
    ) {
        if (zeroForOne) {
            unchecked {
                pool.liquidity -= uint128(ticks[cache.crossTick].liquidityDelta);
            }
            cache.crossTick = TickMap.previous(tickMap, cache.crossTick);
            pool.tickAtPrice = cache.crossTick;
        } else {
            unchecked {
                pool.liquidity += uint128(ticks[cache.crossTick].liquidityDelta);
            }
            pool.tickAtPrice = cache.crossTick;
            cache.crossTick = TickMap.next(tickMap, cache.crossTick);
        }
        return (pool, cache);
    }

    function insert(
        mapping(int24 => IRangePoolStructs.Tick) storage ticks,
        IRangePoolStructs.Sample[65535] storage samples,
        IRangePoolStructs.TickMap storage tickMap,
        IRangePoolStructs.PoolState memory state,
        int24 lower,
        int24 upper,
        uint128 amount
    ) external returns (IRangePoolStructs.PoolState memory) {
        validate(lower, upper, IRangePool(address(this)).tickSpacing());
        // check for amount to overflow liquidity delta & global
        if (amount == 0) return state;
        if (amount > uint128(type(int128).max)) require(false, 'LiquidityOverflow()');
        if (type(uint128).max - state.liquidityGlobal < amount) require(false, 'LiquidityOverflow()');

        // get tick at price
        int24 tickAtPrice = state.tickAtPrice;

        if(TickMap.set(tickMap, lower)) {
            ticks[lower].liquidityDelta += int128(amount);
        } else {
            if (lower <= tickAtPrice) {
                (
                    int56 tickSecondsAccum,
                    uint160 secondsPerLiquidityAccum
                ) = Samples.getSingle(
                        IRangePool(address(this)), 
                        IRangePoolStructs.SampleParams(
                            state.samples.index,
                            state.samples.length,
                            uint32(block.timestamp),
                            new uint32[](2),
                            state.tickAtPrice,
                            state.liquidity
                        ),
                        0
                );
                ticks[lower] = IRangePoolStructs.Tick(
                    int128(amount),
                    state.feeGrowthGlobal0,
                    state.feeGrowthGlobal1,
                    tickSecondsAccum,
                    secondsPerLiquidityAccum
                );
            } else {
                ticks[lower].liquidityDelta = int128(amount);
            }
        }

        if(TickMap.set(tickMap, upper)) {
            ticks[upper].liquidityDelta -= int128(amount);
        } else {
            if (upper <= tickAtPrice) {
                (
                    int56 tickSecondsAccum,
                    uint160 secondsPerLiquidityAccum
                ) = Samples.getSingle(
                        IRangePool(address(this)), 
                        IRangePoolStructs.SampleParams(
                            state.samples.index,
                            state.samples.length,
                            uint32(block.timestamp),
                            new uint32[](2),
                            state.tickAtPrice,
                            state.liquidity
                        ),
                        0
                );
                ticks[upper] = IRangePoolStructs.Tick(
                    -int128(amount),
                    state.feeGrowthGlobal0,
                    state.feeGrowthGlobal1,
                    tickSecondsAccum,
                    secondsPerLiquidityAccum
                );
            } else {
                ticks[upper].liquidityDelta = -int128(amount);
            }
        }
        if (tickAtPrice >= lower && tickAtPrice < upper) {
            // write an oracle entry
            (state.samples.index, state.samples.length) = Samples.save(
                samples,
                state,
                state.tickAtPrice
            );
            // update pool liquidity
            state.liquidity += amount;
        }
        // update global liquidity
        state.liquidityGlobal += amount;

        return state;
    }

    function remove(
        mapping(int24 => IRangePoolStructs.Tick) storage ticks,
        IRangePoolStructs.Sample[65535] storage samples,
        IRangePoolStructs.TickMap storage tickMap,
        IRangePoolStructs.PoolState memory state,
        int24 lower,
        int24 upper,
        uint128 amount
    ) external returns (IRangePoolStructs.PoolState memory) {
        validate(lower, upper, IRangePool(address(this)).tickSpacing());
        //check for amount to overflow liquidity delta & global
        if (amount == 0) return state;
        if (amount > uint128(type(int128).max)) require(false, 'LiquidityUnderflow()');
        if (amount > state.liquidityGlobal) require(false, 'LiquidityUnderflow()');

        // get tick at price
        int24 tickAtPrice = state.tickAtPrice;

        IRangePoolStructs.Tick storage current = ticks[lower];
        if (lower != TickMath.MIN_TICK && current.liquidityDelta == int128(amount)) {
            TickMap.unset(tickMap, lower);
            delete ticks[lower];
        } else {
            unchecked {
                current.liquidityDelta -= int128(amount);
            }
        }
        current = ticks[upper];

        if (upper != TickMath.MAX_TICK && current.liquidityDelta == -int128(amount)) {
            TickMap.unset(tickMap, upper);
            delete ticks[upper];
        } else {
            unchecked {
                current.liquidityDelta += int128(amount);
            }
        }
        if (tickAtPrice >= lower && tickAtPrice < upper) {
            // write an oracle entry
            (state.samples.index, state.samples.length) = Samples.save(
                samples,
                state,
                tickAtPrice
            );
            state.liquidity -= amount;  
        }
        state.liquidityGlobal -= amount;

        return state;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./PrecisionMath.sol";
import "../interfaces/IRangePoolFactory.sol";
import "../interfaces/IRangePoolStructs.sol";

/// @notice Math library that facilitates fee handling.
library Tokens {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    function id(
        int24 lower,
        int24 upper
    ) internal pure returns (
        uint256
    )
    {
        return uint256(keccak256(abi.encode(lower, upper)));
    }

    function totalSupply(
        address tokens,
        int24 lower,
        int24 upper
    ) internal view returns (
        uint256
    )
    {
        return IRangePoolERC1155(tokens).totalSupply(id(lower, upper));
    }

    function totalSupplyById(
        address tokens,
        uint256 _id
    ) internal view returns (
        uint256
    )
    {
        return IRangePoolERC1155(tokens).totalSupply(_id);
    } 
}