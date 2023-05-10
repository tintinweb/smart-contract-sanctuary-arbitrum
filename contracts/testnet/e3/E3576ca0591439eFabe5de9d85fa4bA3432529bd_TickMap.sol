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