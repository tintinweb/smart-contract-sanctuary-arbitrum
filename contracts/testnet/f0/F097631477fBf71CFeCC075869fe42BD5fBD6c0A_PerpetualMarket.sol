// SPDX-License-Identifier: GPL-3.0-only
//
// Original file is
// https://github.com/opynfinance/squeeth-monorepo/blob/main/packages/hardhat/contracts/strategy/base/StrategyFlashSwap.sol

pragma solidity =0.7.6;
pragma abicoder v2;

// interface
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// lib
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/Path.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

contract BaseFlashSwap is IUniswapV3SwapCallback {
    using Path for bytes;
    using SafeCast for uint256;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    /// @dev Uniswap factory address
    address public immutable factory;

    struct SwapCallbackData {
        bytes path;
        address caller;
        uint8 callSource;
        bytes callData;
    }

    /**
     * @dev constructor
     * @param _factory uniswap factory address
     */
    constructor(address _factory) {
        require(_factory != address(0), "invalid factory address");
        factory = _factory;
    }

    /**
     * @notice uniswap swap callback function for flashes
     * @param amount0Delta amount of token0
     * @param amount1Delta amount of token1
     * @param _data callback data encoded as SwapCallbackData struct
     */
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported

        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        //ensure that callback comes from uniswap pool
        CallbackValidation.verifyCallback(factory, tokenIn, tokenOut, fee);

        //determine the amount that needs to be repaid as part of the flashswap
        uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);

        //calls the function that uses the proceeds from flash swap and executes logic to have an amount of token to repay the flash swap
        _executeOperation(data.caller, tokenIn, tokenOut, fee, amountToPay, data.callData, data.callSource);
    }

    /**
     * @notice execute an exact-in flash swap (specify an exact amount to pay)
     * @param _tokenIn token address to sell
     * @param _tokenOut token address to receive
     * @param _fee pool fee
     * @param _amountIn amount to sell
     * @param _amountOutMinimum minimum amount to receive
     * @param _callSource function call source
     * @param _data arbitrary data assigned with the call
     */
    function _exactInFlashSwap(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint8 _callSource,
        bytes memory _data
    ) internal {
        //calls internal uniswap swap function that will trigger a callback for the flash swap
        uint256 amountOut = _exactInputInternal(
            _amountIn,
            address(this),
            uint160(0),
            SwapCallbackData({
                path: abi.encodePacked(_tokenIn, _fee, _tokenOut),
                caller: msg.sender,
                callSource: _callSource,
                callData: _data
            })
        );

        //slippage limit check
        require(amountOut >= _amountOutMinimum, "amount out less than min");
    }

    /**
     * @notice execute an exact-out flash swap (specify an exact amount to receive)
     * @param _tokenIn token address to sell
     * @param _tokenOut token address to receive
     * @param _fee pool fee
     * @param _amountOut exact amount to receive
     * @param _amountInMaximum maximum amount to sell
     * @param _callSource function call source
     * @param _data arbitrary data assigned with the call
     */
    function _exactOutFlashSwap(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _amountOut,
        uint256 _amountInMaximum,
        uint8 _callSource,
        bytes memory _data
    ) internal {
        //calls internal uniswap swap function that will trigger a callback for the flash swap
        uint256 amountIn = _exactOutputInternal(
            _amountOut,
            address(this),
            uint160(0),
            SwapCallbackData({
                path: abi.encodePacked(_tokenOut, _fee, _tokenIn),
                caller: msg.sender,
                callSource: _callSource,
                callData: _data
            })
        );

        //slippage limit check
        require(amountIn <= _amountInMaximum, "amount in greater than max");
    }

    /**
     * @notice function to be called by uniswap callback.
     * @dev this function should be overridden by the child contract
     * param _caller initial hedge function caller
     * param _tokenIn token address sold
     * param _tokenOut token address bought
     * param _fee pool fee
     * param _amountToPay amount to pay for the pool second token
     * param _callData arbitrary data assigned with the flashswap call
     * param _callSource function call source
     */
    function _executeOperation(
        address, /*_caller*/
        address, /*_tokenIn*/
        address, /*_tokenOut*/
        uint24, /*_fee*/
        uint256, /*_amountToPay*/
        bytes memory _callData,
        uint8 _callSource
    ) internal virtual {
        // call PerpetualMarket.execHedge
    }

    /**
     * @notice internal function for exact-in swap on uniswap (specify exact amount to pay)
     * @param _amountIn amount of token to pay
     * @param _recipient recipient for receive
     * @param _sqrtPriceLimitX96 price limit
     * @return amount of token bought (amountOut)
     */
    function _exactInputInternal(
        uint256 _amountIn,
        address _recipient,
        uint160 _sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256) {
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        //uniswap token0 has a lower address than token1
        //if tokenIn<tokenOut, we are selling an exact amount of token0 in exchange for token1
        //zeroForOne determines which token is being sold and which is being bought
        bool zeroForOne = tokenIn < tokenOut;

        //swap on uniswap, including data to trigger call back for flashswap
        (int256 amount0, int256 amount1) = _getPool(tokenIn, tokenOut, fee).swap(
            _recipient,
            zeroForOne,
            _amountIn.toInt256(),
            _sqrtPriceLimitX96 == 0
                ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : _sqrtPriceLimitX96,
            abi.encode(data)
        );

        //determine the amountOut based on which token has a lower address
        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    /**
     * @notice internal function for exact-out swap on uniswap (specify exact amount to receive)
     * @param _amountOut amount of token to receive
     * @param _recipient recipient for receive
     * @param _sqrtPriceLimitX96 price limit
     * @return amount of token sold (amountIn)
     */
    function _exactOutputInternal(
        uint256 _amountOut,
        address _recipient,
        uint160 _sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256) {
        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();

        //uniswap token0 has a lower address than token1
        //if tokenIn<tokenOut, we are buying an exact amount of token1 in exchange for token0
        //zeroForOne determines which token is being sold and which is being bought
        bool zeroForOne = tokenIn < tokenOut;

        //swap on uniswap, including data to trigger call back for flashswap
        (int256 amount0Delta, int256 amount1Delta) = _getPool(tokenIn, tokenOut, fee).swap(
            _recipient,
            zeroForOne,
            -_amountOut.toInt256(),
            _sqrtPriceLimitX96 == 0
                ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : _sqrtPriceLimitX96,
            abi.encode(data)
        );

        //determine the amountIn and amountOut based on which token has a lower address
        (uint256 amountIn, uint256 amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (_sqrtPriceLimitX96 == 0) require(amountOutReceived == _amountOut);

        return amountIn;
    }

    /**
     * @notice returns the uniswap pool for the given token pair and fee
     * @dev the pool contract may or may not exist
     * @param tokenA address of first token
     * @param tokenB address of second token
     * @param fee fee tier for pool
     */
    function _getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './PoolAddress.sol';

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        return verifyCallback(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address factory, PoolAddress.PoolKey memory poolKey)
        internal
        view
        returns (IUniswapV3Pool pool)
    {
        pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        require(msg.sender == address(pool));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
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

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
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

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IPerpetualMarket.sol";
import "./base/BaseFlashSwap.sol";

/**
 * @title FlashHedge
 * @notice FlashHedge helps to swap underlying assets and USDC tokens with Uniswap for delta hedging.
 * Error codes
 * FH0: no enough usdc amount
 * FH1: no enough usdc amount
 * FH2: profit is less than minUsdc
 * FH3: amounts must not be 0
 * FH4: caller is not bot
 */
contract FlashHedge is BaseFlashSwap, Ownable {
    using SafeERC20 for IERC20;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    address public immutable collateral;
    address public immutable underlying;

    /// @dev ETH:USDC uniswap pool
    address public immutable ethUsdcPool;

    IPerpetualMarket private perpetualMarket;

    /// @dev bot address
    address bot;

    struct FlashHedgeData {
        uint256 amountUsdc;
        uint256 amountUnderlying;
        uint256 minUsdc;
        bool withRebalance;
    }

    enum FLASH_SOURCE {
        FLASH_HEDGE_SELL,
        FLASH_HEDGE_BUY
    }

    event HedgeOnUniswap(address indexed hedger, uint256 hedgeTimestamp, uint256 minUsdc);

    modifier onlyBot() {
        require(msg.sender == bot, "FH4");
        _;
    }

    constructor(
        address _collateral,
        address _underlying,
        address _perpetualMarket,
        address _uniswapFactory,
        address _ethUsdcPool
    ) BaseFlashSwap(_uniswapFactory) {
        require(_collateral != address(0), "invalid collateral address");
        require(_underlying != address(0), "invalid underlying address");
        require(_perpetualMarket != address(0), "invalid perpetual market address");
        require(_ethUsdcPool != address(0), "invalid eth-usdc pool address");
        collateral = _collateral;
        underlying = _underlying;
        perpetualMarket = IPerpetualMarket(_perpetualMarket);
        ethUsdcPool = _ethUsdcPool;

        bot = msg.sender;
    }

    /**
     * @notice uniswap flash swap callback function
     * @dev this function will be called by flashswap callback function uniswapV3SwapCallback()
     * @param _caller address of original function caller
     * @param _amountToPay amount to pay back for flashswap
     * @param _callData arbitrary data attached to callback
     * @param _callSource identifier for which function triggered callback
     */
    function _executeOperation(
        address _caller,
        address, /*_tokenIn*/
        address, /*_tokenOut*/
        uint24, /*_fee*/
        uint256 _amountToPay,
        bytes memory _callData,
        uint8 _callSource
    ) internal override {
        FlashHedgeData memory data = abi.decode(_callData, (FlashHedgeData));

        if (FLASH_SOURCE(_callSource) == FLASH_SOURCE.FLASH_HEDGE_SELL) {
            uint256 amountUsdcToBuyETH = IERC20(collateral).balanceOf(address(this)).sub(data.minUsdc);
            require(amountUsdcToBuyETH >= data.amountUsdc, "FH0");

            IERC20(collateral).approve(address(perpetualMarket), amountUsdcToBuyETH);
            perpetualMarket.execHedge(data.withRebalance, amountUsdcToBuyETH);

            // Repay and safeTransfer profit
            IERC20(underlying).safeTransfer(ethUsdcPool, _amountToPay);
            IERC20(collateral).safeTransfer(_caller, data.minUsdc);
        } else if (FLASH_SOURCE(_callSource) == FLASH_SOURCE.FLASH_HEDGE_BUY) {
            uint256 amountUsdcReceiveFromPredy = _amountToPay.add(data.minUsdc);

            require(data.amountUsdc >= amountUsdcReceiveFromPredy, "FH1");

            IERC20(underlying).approve(address(perpetualMarket), data.amountUnderlying);
            perpetualMarket.execHedge(data.withRebalance, amountUsdcReceiveFromPredy);

            // Repay and safeTransfer profit
            IERC20(collateral).safeTransfer(ethUsdcPool, _amountToPay);
            IERC20(collateral).safeTransfer(_caller, data.minUsdc);
        }
    }

    /**
     * @notice Executes delta hedging by Uniswap
     * @param _minUsdc minimum USDC amount the caller willing to receive
     * @param _withRebalance exec hedge with rebalancing margin or not
     */
    function hedgeOnUniswap(uint256 _minUsdc, bool _withRebalance) external onlyBot {
        (bool isBuyingETH, uint256 amountUsdc, uint256 amountEth) = perpetualMarket.getTokenAmountForHedging();

        require(amountUsdc > 0 && amountEth > 0, "FH3");

        if (isBuyingETH) {
            _exactOutFlashSwap(
                collateral,
                underlying,
                IUniswapV3Pool(ethUsdcPool).fee(),
                amountEth,
                amountUsdc, // max amount of USDC to send
                uint8(FLASH_SOURCE.FLASH_HEDGE_BUY),
                abi.encode(FlashHedgeData(amountUsdc, amountEth, _minUsdc, _withRebalance))
            );
        } else {
            _exactInFlashSwap(
                underlying,
                collateral,
                IUniswapV3Pool(ethUsdcPool).fee(),
                amountEth,
                amountUsdc, // min amount of USDC to receive
                uint8(FLASH_SOURCE.FLASH_HEDGE_SELL),
                abi.encode(FlashHedgeData(amountUsdc, amountEth, _minUsdc, _withRebalance))
            );
        }

        emit HedgeOnUniswap(msg.sender, block.timestamp, _minUsdc);
    }

    /**
     * @notice set bot address
     * @param _bot bot address
     */
    function setBot(address _bot) external onlyOwner {
        bot = _bot;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../lib/TraderVaultLib.sol";

interface IPerpetualMarket {
    struct MultiTradeParams {
        uint256 vaultId;
        TradeParams[] trades;
        int256 marginAmount;
        uint256 deadline;
    }

    struct TradeParams {
        uint256 productId;
        uint256 subVaultIndex;
        int128 tradeAmount;
        uint256 limitPrice;
        bytes metadata;
    }

    struct VaultStatus {
        int256 positionValue;
        int256 minCollateral;
        int256[2][] positionValues;
        int256[2][] fundingPaid;
        TraderVaultLib.TraderVault rawVaultData;
    }

    struct TradeInfo {
        int256 tradePrice;
        int256 indexPrice;
        int256 fundingRate;
        int256 tradeFee;
        int256 protocolFee;
        int256 fundingFee;
        uint256 totalValue;
        uint256 totalFee;
    }

    function initialize(uint256 _depositAmount, int256 _initialFundingRate) external;

    function deposit(uint256 _depositAmount) external;

    function withdraw(uint128 _withdrawnAmount) external;

    function trade(MultiTradeParams memory _tradeParams) external;

    function addMargin(uint256 _vaultId, int256 _marginToAdd) external;

    function liquidateByPool(uint256 _vaultId) external;

    function getTokenAmountForHedging()
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function execHedge(bool _withRebalance, uint256 _amountUsdc) external returns (uint256 amountUnderlying);

    function getLPTokenPrice(int256 _deltaLiquidityAmount) external view returns (uint256);

    function getTradePrice(uint256 _productId, int256[2] memory _tradeAmounts)
        external
        view
        returns (TradeInfo memory tradePriceInfo);

    function getMinCollateralToAddPosition(uint256 _vaultId, int128[2] memory _tradeAmounts)
        external
        view
        returns (int256 minCollateral);

    function getTraderVault(uint256 _vaultId) external view returns (TraderVaultLib.TraderVault memory);

    function getVaultStatus(uint256 _vaultId) external view returns (VaultStatus memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "../interfaces/IPerpetualMarketCore.sol";
import "./Math.sol";
import "./EntryPriceMath.sol";

/**
 * @title TraderVaultLib
 * @notice TraderVaultLib has functions to calculate position value and minimum collateral for implementing cross margin wallet.
 *
 * Data Structure
 *  Vault
 *  - PositionUSDC
 *  - SubVault0(PositionPerpetuals, EntryPrices, entryFundingFee)
 *  - SubVault1(PositionPerpetuals, EntryPrices, entryFundingFee)
 *  - ...
 *
 *  PositionPerpetuals = [PositionSqueeth, PositionFuture]
 *  EntryPrices = [EntryPriceSqueeth, EntryPriceFuture]
 *  entryFundingFee = [entryFundingFeeqeeth, FundingFeeEntryValueFuture]
 *
 *
 * Error codes
 *  T0: PositionValue must be greater than MinCollateral
 *  T1: PositionValue must be less than MinCollateral
 *  T2: Vault is insolvent
 *  T3: subVaultIndex is too large
 *  T4: position must not be 0
 *  T5: usdc to add must be positive
 */
library TraderVaultLib {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;

    uint256 private constant MAX_PRODUCT_ID = 2;

    /// @dev minimum margin is 200 USDC
    uint256 private constant MIN_MARGIN = 200 * 1e8;

    /// @dev risk parameter for MinCollateral calculation is 5.0%
    uint256 private constant RISK_PARAM_FOR_VAULT = 500;

    struct SubVault {
        int128[2] positionPerpetuals;
        uint128[2] entryPrices;
        int256[2] entryFundingFee;
    }

    struct TraderVault {
        int128 positionUsdc;
        SubVault[] subVaults;
    }

    /**
     * @notice Gets amount of min collateral to add Squees/Future
     * @param _traderVault trader vault object
     * @param _tradeAmounts amount to trade
     * @param _tradePriceInfo trade price info
     * @return minCollateral and positionValue
     */
    function getMinCollateralToAddPosition(
        TraderVault memory _traderVault,
        int128[2] memory _tradeAmounts,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256 minCollateral) {
        int128[2] memory positionPerpetuals = getPositionPerpetuals(_traderVault);

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            positionPerpetuals[i] = positionPerpetuals[i].add(_tradeAmounts[i]).toInt128();
        }

        minCollateral = calculateMinCollateral(positionPerpetuals, _tradePriceInfo);
    }

    /**
     * @notice Updates USDC position
     * @param _traderVault trader vault object
     * @param _usdcPositionToAdd amount to add. if positive then increase amount, if negative then decrease amount.
     * @param _tradePriceInfo trade price info
     * @return finalUsdcPosition positive means amount of deposited margin
     * and negative means amount of withdrawn margin.
     */
    function updateUsdcPosition(
        TraderVault storage _traderVault,
        int256 _usdcPositionToAdd,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) external returns (int256 finalUsdcPosition) {
        finalUsdcPosition = _usdcPositionToAdd;

        int256 positionValue = getPositionValue(_traderVault, _tradePriceInfo);
        int256 minCollateral = getMinCollateral(_traderVault, _tradePriceInfo);
        int256 maxWithdrawable = positionValue - minCollateral;

        // If trader wants to withdraw all USDC, set maxWithdrawable.
        if (_usdcPositionToAdd < -maxWithdrawable && maxWithdrawable > 0 && _usdcPositionToAdd < 0) {
            finalUsdcPosition = -maxWithdrawable;
        }

        _traderVault.positionUsdc = _traderVault.positionUsdc.add(finalUsdcPosition).toInt128();

        require(!checkVaultIsDanger(_traderVault, _tradePriceInfo), "T0");
    }

    /**
     * @notice Add USDC position
     * @param _traderVault trader vault object
     * @param _usdcPositionToAdd amount to add. value is always positive.
     */
    function addUsdcPosition(TraderVault storage _traderVault, int256 _usdcPositionToAdd) external {
        require(_usdcPositionToAdd > 0, "T5");

        _traderVault.positionUsdc = _traderVault.positionUsdc.add(_usdcPositionToAdd).toInt128();
    }

    /**
     * @notice Gets total position of perpetuals in the vault
     * @param _traderVault trader vault object
     * @return positionPerpetuals are total amount of perpetual scaled by 1e8
     */
    function getPositionPerpetuals(TraderVault memory _traderVault)
        internal
        pure
        returns (int128[2] memory positionPerpetuals)
    {
        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            positionPerpetuals[i] = getPositionPerpetual(_traderVault, i);
        }
    }

    /**
     * @notice Gets position of a perpetual in the vault
     * @param _traderVault trader vault object
     * @param _productId product id
     * @return positionPerpetual is amount of perpetual scaled by 1e8
     */
    function getPositionPerpetual(TraderVault memory _traderVault, uint256 _productId)
        internal
        pure
        returns (int128 positionPerpetual)
    {
        for (uint256 i = 0; i < _traderVault.subVaults.length; i++) {
            positionPerpetual = positionPerpetual
                .add(_traderVault.subVaults[i].positionPerpetuals[_productId])
                .toInt128();
        }
    }

    /**
     * @notice Updates positions in the vault
     * @param _traderVault trader vault object
     * @param _subVaultIndex index of sub-vault
     * @param _productId product id
     * @param _positionPerpetual amount of position to increase or decrease
     * @param _tradePrice trade price
     * @param _fundingFeePerPosition entry funding fee paid per position
     */
    function updateVault(
        TraderVault storage _traderVault,
        uint256 _subVaultIndex,
        uint256 _productId,
        int128 _positionPerpetual,
        uint256 _tradePrice,
        int256 _fundingFeePerPosition
    ) external returns (int256 roundedDeltaUsdcPosition, uint256 lpProfit) {
        require(_positionPerpetual != 0, "T4");

        if (_traderVault.subVaults.length == _subVaultIndex) {
            int128[2] memory positionPerpetuals;
            uint128[2] memory entryPrices;
            int256[2] memory entryFundingFee;

            _traderVault.subVaults.push(SubVault(positionPerpetuals, entryPrices, entryFundingFee));
        } else {
            require(_traderVault.subVaults.length > _subVaultIndex, "T3");
        }

        SubVault storage subVault = _traderVault.subVaults[_subVaultIndex];
        int256 deltaUsdcPosition;

        {
            (int256 newEntryPrice, int256 profitValue) = EntryPriceMath.updateEntryPrice(
                int256(subVault.entryPrices[_productId]),
                subVault.positionPerpetuals[_productId],
                int256(_tradePrice),
                _positionPerpetual
            );

            subVault.entryPrices[_productId] = newEntryPrice.toUint256().toUint128();
            deltaUsdcPosition = deltaUsdcPosition.add(profitValue);
        }

        {
            (int256 newEntryFundingFee, int256 profitValue) = EntryPriceMath.updateEntryPrice(
                int256(subVault.entryFundingFee[_productId]),
                subVault.positionPerpetuals[_productId],
                _fundingFeePerPosition,
                _positionPerpetual
            );

            subVault.entryFundingFee[_productId] = newEntryFundingFee;
            deltaUsdcPosition = deltaUsdcPosition.sub(profitValue.div(1e8));
        }

        // if deltaUsdcPosition is positive, round down to the second decimal place, if negative round up.
        roundedDeltaUsdcPosition = Math.mulDiv(deltaUsdcPosition, 1, 1e6, deltaUsdcPosition < 0).mul(1e6);

        if (deltaUsdcPosition > roundedDeltaUsdcPosition) {
            lpProfit = deltaUsdcPosition.sub(roundedDeltaUsdcPosition).toUint256();
        }

        _traderVault.positionUsdc = _traderVault.positionUsdc.add(roundedDeltaUsdcPosition).toInt128();

        subVault.positionPerpetuals[_productId] = subVault
            .positionPerpetuals[_productId]
            .add(_positionPerpetual)
            .toInt128();
    }

    /**
     * @notice Checks the vault is danger or not
     * if PositionValue is less than MinCollateral return true
     * otherwise return false
     * @param _traderVault trader vault object
     */
    function checkVaultIsDanger(
        TraderVault memory _traderVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (bool) {
        int256 positionValue = getPositionValue(_traderVault, _tradePriceInfo);

        return positionValue < getMinCollateral(_traderVault, _tradePriceInfo);
    }

    /**
     * @notice Decreases liquidation reward from usdc position
     * @param _traderVault trader vault object
     * @param _minCollateral min collateral
     * @param _liquidationFee liquidation fee rate
     */
    function decreaseLiquidationReward(
        TraderVault storage _traderVault,
        int256 _minCollateral,
        int256 _liquidationFee
    ) external returns (uint256) {
        if (_traderVault.positionUsdc <= 0) {
            return 0;
        }

        int256 reward = _minCollateral.mul(_liquidationFee).div(1e4);

        reward = Math.min(reward, _traderVault.positionUsdc);

        // reduce margin
        // sub is safe because we know reward is less than positionUsdc
        _traderVault.positionUsdc -= reward.toInt128();

        return reward.toUint256();
    }

    /**
     * @notice Gets min collateral of the vault
     * @param _traderVault trader vault object
     * @param _tradePriceInfo trade price info
     * @return MinCollateral scaled by 1e8
     */
    function getMinCollateral(
        TraderVault memory _traderVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int128[2] memory assetAmounts = getPositionPerpetuals(_traderVault);

        return calculateMinCollateral(assetAmounts, _tradePriceInfo);
    }

    /**
     * @notice Calculates min collateral
     * MinCollateral = alpha*S*(|2*S*(1+fundingSqueeth)*PositionSqueeth + (1+fundingFuture)*PositionFuture| + 2*alpha*S*(1+fundingSqueeth)*|PositionSqueeth|)
     * where alpha is 0.05
     * @param positionPerpetuals amount of perpetual positions
     * @param _tradePriceInfo trade price info
     * @return MinCollateral scaled by 1e8
     */
    function calculateMinCollateral(
        int128[2] memory positionPerpetuals,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        // priceWithFunding = S*(1+fundingSqueeth)
        int256 priceWithFunding = int256(_tradePriceInfo.spotPrice).mul(_tradePriceInfo.fundingRates[1].add(1e16)).div(
            1e8
        );

        uint256 maxDelta = Math.abs(
            (priceWithFunding.mul(positionPerpetuals[1]).mul(2).div(1e20)).add(
                positionPerpetuals[0].mul(_tradePriceInfo.fundingRates[0].add(1e16)).div(1e16)
            )
        );

        maxDelta = maxDelta.add(
            Math.abs(int256(RISK_PARAM_FOR_VAULT).mul(priceWithFunding).mul(2).mul(positionPerpetuals[1]).div(1e24))
        );

        uint256 minCollateral = (RISK_PARAM_FOR_VAULT.mul(_tradePriceInfo.spotPrice).mul(maxDelta)) / 1e12;

        if ((positionPerpetuals[0] != 0 || positionPerpetuals[1] != 0) && minCollateral < MIN_MARGIN) {
            minCollateral = MIN_MARGIN;
        }

        return minCollateral.toInt256();
    }

    /**
     * @notice Gets position value in the vault
     * PositionValue = USDC + Σ(ValueOfSubVault_i)
     * @param _traderVault trader vault object
     * @param _tradePriceInfo trade price info
     * @return PositionValue scaled by 1e8
     */
    function getPositionValue(
        TraderVault memory _traderVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int256 value = _traderVault.positionUsdc;

        for (uint256 i = 0; i < _traderVault.subVaults.length; i++) {
            value = value.add(getSubVaultPositionValue(_traderVault.subVaults[i], _tradePriceInfo));
        }

        return value;
    }

    /**
     * @notice Gets position value in the sub-vault
     * ValueOfSubVault = TotalPerpetualValueOfSubVault + TotalFundingFeePaidOfSubVault
     * @param _subVault sub-vault object
     * @param _tradePriceInfo trade price info
     * @return ValueOfSubVault scaled by 1e8
     */
    function getSubVaultPositionValue(
        SubVault memory _subVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        return
            getTotalPerpetualValueOfSubVault(_subVault, _tradePriceInfo).add(
                getTotalFundingFeePaidOfSubVault(_subVault, _tradePriceInfo.amountsFundingPaidPerPosition)
            );
    }

    /**
     * @notice Gets total perpetual value in the sub-vault
     * TotalPerpetualValueOfSubVault = Σ(PerpetualValueOfSubVault_i)
     * @param _subVault sub-vault object
     * @param _tradePriceInfo trade price info
     * @return TotalPerpetualValueOfSubVault scaled by 1e8
     */
    function getTotalPerpetualValueOfSubVault(
        SubVault memory _subVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int256 pnl;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            pnl = pnl.add(getPerpetualValueOfSubVault(_subVault, i, _tradePriceInfo));
        }

        return pnl;
    }

    /**
     * @notice Gets perpetual value in the sub-vault
     * PerpetualValueOfSubVault_i = (TradePrice_i - EntryPrice_i)*Position_i
     * @param _subVault sub-vault object
     * @param _productId product id
     * @param _tradePriceInfo trade price info
     * @return PerpetualValueOfSubVault_i scaled by 1e8
     */
    function getPerpetualValueOfSubVault(
        SubVault memory _subVault,
        uint256 _productId,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int256 pnl = _tradePriceInfo.tradePrices[_productId].sub(_subVault.entryPrices[_productId].toInt256()).mul(
            _subVault.positionPerpetuals[_productId]
        );

        return pnl / 1e8;
    }

    /**
     * @notice Gets total funding fee in the sub-vault
     * TotalFundingFeePaidOfSubVault = Σ(FundingFeePaidOfSubVault_i)
     * @param _subVault sub-vault object
     * @param _amountsFundingPaidPerPosition the cumulative funding fee paid by long per position
     * @return TotalFundingFeePaidOfSubVault scaled by 1e8
     */
    function getTotalFundingFeePaidOfSubVault(
        SubVault memory _subVault,
        int256[2] memory _amountsFundingPaidPerPosition
    ) internal pure returns (int256) {
        int256 fundingFee;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            fundingFee = fundingFee.add(getFundingFeePaidOfSubVault(_subVault, i, _amountsFundingPaidPerPosition));
        }

        return fundingFee;
    }

    /**
     * @notice Gets funding fee in the sub-vault
     * FundingFeePaidOfSubVault_i = Position_i*(EntryFundingFee_i - FundingFeeGlobal_i)
     * @param _subVault sub-vault object
     * @param _productId product id
     * @param _amountsFundingPaidPerPosition cumulative funding fee paid by long per position.
     * @return FundingFeePaidOfSubVault_i scaled by 1e8
     */
    function getFundingFeePaidOfSubVault(
        SubVault memory _subVault,
        uint256 _productId,
        int256[2] memory _amountsFundingPaidPerPosition
    ) internal pure returns (int256) {
        int256 fundingFee = _subVault.entryFundingFee[_productId].sub(_amountsFundingPaidPerPosition[_productId]).mul(
            _subVault.positionPerpetuals[_productId]
        );

        return fundingFee.div(1e16);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../lib/NettingLib.sol";

interface IPerpetualMarketCore {
    struct TradePriceInfo {
        uint128 spotPrice;
        int256[2] tradePrices;
        int256[2] fundingRates;
        int256[2] amountsFundingPaidPerPosition;
    }

    function initialize(
        address _depositor,
        uint256 _depositAmount,
        int256 _initialFundingRate
    ) external returns (uint256 mintAmount);

    function deposit(address _depositor, uint256 _depositAmount) external returns (uint256 mintAmount);

    function withdraw(address _withdrawer, uint256 _withdrawnAmount) external returns (uint256 burnAmount);

    function addLiquidity(uint256 _amount) external;

    function updatePoolPositions(int256[2] memory _tradeAmounts)
        external
        returns (
            uint256[2] memory tradePrice,
            int256[2] memory,
            uint256 protocolFee
        );

    function completeHedgingProcedure(NettingLib.CompleteParams memory _completeParams) external;

    function updatePoolSnapshot() external;

    function executeFundingPayment() external;

    function getTradePriceInfo(int256[2] memory _tradeAmounts) external view returns (TradePriceInfo memory);

    function getTradePrice(uint256 _productId, int256[2] memory _tradeAmounts)
        external
        view
        returns (
            int256,
            int256,
            int256,
            int256,
            int256
        );

    function rebalance() external;

    function getTokenAmountForHedging() external view returns (NettingLib.CompleteParams memory completeParams);

    function getLPTokenPrice(int256 _deltaLiquidityAmount) external view returns (uint256);
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * Error codes
 * M0: y is too small
 * M1: y is too large
 * M2: possible overflow
 * M3: input should be positive number
 * M4: cannot handle exponents greater than 100
 */
library Math {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /// @dev Min exp
    int256 private constant MIN_EXP = -63 * 1e8;
    /// @dev Max exp
    uint256 private constant MAX_EXP = 100 * 1e8;
    /// @dev ln(2) scaled by 1e8
    uint256 private constant LN_2_E8 = 69314718;

    /**
     * @notice Return the addition of unsigned integer and sigined integer.
     * when y is negative reverting on negative result and when y is positive reverting on overflow.
     */
    function addDelta(uint256 x, int256 y) internal pure returns (uint256 z) {
        if (y < 0) {
            require((z = x - uint256(-y)) < x, "M0");
        } else {
            require((z = x + uint256(y)) >= x, "M1");
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? b : a;
    }

    function mulDiv(
        int256 _x,
        int256 _y,
        int256 _d,
        bool _roundUp
    ) internal pure returns (int256) {
        int256 tailing;
        if (_roundUp) {
            int256 remainer = (_x * _y) % _d;
            if (remainer > 0) {
                tailing = 1;
            } else if (remainer < 0) {
                tailing = -1;
            }
        }

        int256 result = (_x * _y) / _d + tailing;

        return result;
    }

    /**
     * @notice Returns scaled number.
     * Reverts if the scaler is greater than 50.
     */
    function scale(
        uint256 _a,
        uint256 _from,
        uint256 _to
    ) internal pure returns (uint256) {
        if (_from > _to) {
            require(_from - _to < 70, "M2");
            // (_from - _to) is safe because _from > _to.
            // 10**(_from - _to) is safe because it's less than 10**70.
            return _a.div(10**(_from - _to));
        } else if (_from < _to) {
            require(_to - _from < 70, "M2");
            // (_to - _from) is safe because _to > _from.
            // 10**(_to - _from) is safe because it's less than 10**70.
            return _a.mul(10**(_to - _from));
        } else {
            return _a;
        }
    }

    /**
     * @dev Calculates an approximate value of the logarithm of input value by Halley's method.
     */
    function log(uint256 x) internal pure returns (int256) {
        int256 res;
        int256 next;

        for (uint256 i = 0; i < 8; i++) {
            int256 e = int256(exp(res));
            next = res.add((int256(x).sub(e).mul(2)).mul(1e8).div(int256(x).add(e)));
            if (next == res) {
                break;
            }
            res = next;
        }

        return res;
    }

    /**
     * @dev Returns the exponent of the value using Taylor expansion with support for negative numbers.
     */
    function exp(int256 x) internal pure returns (uint256) {
        if (0 <= x) {
            return exp(uint256(x));
        } else if (x < MIN_EXP) {
            // return 0 because `exp(-63) < 1e-27`
            return 0;
        } else {
            return uint256(1e8).mul(1e8).div(exp(uint256(-x)));
        }
    }

    /**
     * @dev Calculates the exponent of the value using Taylor expansion.
     */
    function exp(uint256 x) internal pure returns (uint256) {
        if (x == 0) {
            return 1e8;
        }
        require(x <= MAX_EXP, "M4");

        uint256 k = floor(x.mul(1e8).div(LN_2_E8)) / 1e8;
        uint256 p = 2**k;
        uint256 r = x.sub(k.mul(LN_2_E8));

        uint256 multiplier = 1e8;

        uint256 lastMultiplier;
        for (uint256 i = 16; i > 0; i--) {
            multiplier = multiplier.mul(r / i).div(1e8).add(1e8);
            if (multiplier == lastMultiplier) {
                break;
            }
            lastMultiplier = multiplier;
        }

        return p.mul(multiplier);
    }

    /**
     * @dev Returns the floor of a 1e8
     */
    function floor(uint256 x) internal pure returns (uint256) {
        return x - (x % 1e8);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./Math.sol";

/**
 * @title EntryPriceMath
 * @notice Library contract which has functions to calculate new entry price and profit
 * from previous entry price and trade price for implementing margin wallet.
 */
library EntryPriceMath {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /**
     * @notice Calculates new entry price and return profit if position is closed
     *
     * Calculation Patterns
     *  |Position|PositionTrade|NewPosition|Pattern|
     *  |       +|            +|          +|      A|
     *  |       +|            -|          +|      B|
     *  |       +|            -|          -|      C|
     *  |       -|            -|          -|      A|
     *  |       -|            +|          -|      B|
     *  |       -|            +|          +|      C|
     *
     * Calculations
     *  Pattern A (open positions)
     *   NewEntryPrice = (EntryPrice * |Position| + TradePrce * |PositionTrade|) / (Position + PositionTrade)
     *
     *  Pattern B (close positions)
     *   NewEntryPrice = EntryPrice
     *   ProfitValue = -PositionTrade * (TradePrice - EntryPrice)
     *
     *  Pattern C (close all positions & open new)
     *   NewEntryPrice = TradePrice
     *   ProfitValue = Position * (TradePrice - EntryPrice)
     *
     * @param _entryPrice previous entry price
     * @param _position current position
     * @param _tradePrice trade price
     * @param _positionTrade position to trade
     * @return newEntryPrice new entry price
     * @return profitValue notional profit value when positions are closed
     */
    function updateEntryPrice(
        int256 _entryPrice,
        int256 _position,
        int256 _tradePrice,
        int256 _positionTrade
    ) internal pure returns (int256 newEntryPrice, int256 profitValue) {
        int256 newPosition = _position.add(_positionTrade);
        if (_position == 0 || (_position > 0 && _positionTrade > 0) || (_position < 0 && _positionTrade < 0)) {
            newEntryPrice = (
                _entryPrice.mul(int256(Math.abs(_position))).add(_tradePrice.mul(int256(Math.abs(_positionTrade))))
            ).div(int256(Math.abs(_position.add(_positionTrade))));
        } else if (
            (_position > 0 && _positionTrade < 0 && newPosition > 0) ||
            (_position < 0 && _positionTrade > 0 && newPosition < 0)
        ) {
            newEntryPrice = _entryPrice;
            profitValue = (-_positionTrade).mul(_tradePrice.sub(_entryPrice)) / 1e8;
        } else {
            if (newPosition != 0) {
                newEntryPrice = _tradePrice;
            }

            profitValue = _position.mul(_tradePrice.sub(_entryPrice)) / 1e8;
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./Math.sol";

/**
 * @title NettingLib
 *
 * HedgePositionValue = ETH * S + AmountUSDC
 *
 * Normally, Amount Locked is equal to HedgePositionValue.
 * AMM adjusts the HedgePositionValue to be equal to the RequiredMargin
 * by adding or decreasing AmountUSDC.
 *
 *  --------------------------------------------------
 * |              Total Liquidity Amount              |
 * |     Amount Locked       |
 * |    ETH     | AmountUSDC |
 *  --------------------------------------------------
 *
 * If RequiredMargin becomes smaller than ETH value that AMM has, AmountUSDC becomes negative.
 *
 *  --------------------------------------------------
 * |              Total Liquidity Amount              |
 * |      Amount Locked(10)       |
 * |            ETH(15)                          |
 *                                |AmountUSDC(-5)|
 *  --------------------------------------------------
 *
 * After hedge completed, AmountUSDC becomes positive.
 *
 *  --------------------------------------------------
 * |              Total Liquidity Amount              |
 * |      Amount Locked(10)       |
 * |      ETH(6)    |
 *                  |AmountUSDC(4)|
 *  --------------------------------------------------
 *
 * Error codes
 * N0: Unknown product id
 * N1: Total delta must be greater than 0
 * N2: No enough USDC
 */
library NettingLib {
    using SafeCast for int256;
    using SafeCast for uint128;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for int256;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;

    struct AddMarginParams {
        int256 delta0;
        int256 delta1;
        int256 gamma1;
        int256 spotPrice;
        int256 poolMarginRiskParam;
    }

    struct CompleteParams {
        uint256 amountUsdc;
        uint256 amountUnderlying;
        uint256 futureWeight;
        bool isLong;
    }

    struct Info {
        int256[2] amountsUsdc;
        uint256 amountUnderlying;
    }

    /**
     * @notice Adds required margin for delta hedging
     */
    function addMargin(
        Info storage _info,
        uint256 _productId,
        AddMarginParams memory _params
    ) internal returns (int256 requiredMargin, int256 hedgePositionValue) {
        int256 totalRequiredMargin = getRequiredMargin(_productId, _params);

        hedgePositionValue = getHedgePositionValue(_info, _params, _productId);

        requiredMargin = totalRequiredMargin.sub(hedgePositionValue);

        _info.amountsUsdc[_productId] = _info.amountsUsdc[_productId].add(requiredMargin);
    }

    function getRequiredTokenAmountsForHedge(
        uint256 _amountUnderlying,
        int256[2] memory _deltas,
        int256 _spotPrice
    ) internal pure returns (CompleteParams memory completeParams) {
        int256 totalUnderlyingPosition = _amountUnderlying.toInt256();

        // 1. Calculate required amount of underlying token
        int256 requiredUnderlyingAmount;
        {
            // required amount is -(net delta)
            requiredUnderlyingAmount = -_deltas[0].add(_deltas[1]).add(totalUnderlyingPosition);

            if (_deltas[0].add(_deltas[1]) > 0) {
                // if pool delta is positive
                requiredUnderlyingAmount = -totalUnderlyingPosition;
            }

            completeParams.isLong = requiredUnderlyingAmount > 0;
        }

        // 2. Calculate USDC and ETH amounts.
        completeParams.amountUnderlying = Math.abs(requiredUnderlyingAmount);
        completeParams.amountUsdc = (Math.abs(requiredUnderlyingAmount).mul(uint256(_spotPrice))) / 1e8;

        completeParams.futureWeight = calculateWeight(0, _deltas[0], _deltas[1]);

        return completeParams;
    }

    /**
     * @notice Completes delta hedging procedure
     * Calculate holding amount of Underlying and USDC after a hedge.
     */
    function complete(Info storage _info, CompleteParams memory _params) internal {
        uint256 amountRequired0 = _params.amountUsdc.mul(_params.futureWeight).div(1e16);
        uint256 amountRequired1 = _params.amountUsdc.sub(amountRequired0);

        require(_params.amountUnderlying > 0, "N1");

        if (_params.isLong) {
            _info.amountUnderlying = _info.amountUnderlying.add(_params.amountUnderlying);

            _info.amountsUsdc[0] = _info.amountsUsdc[0].sub(amountRequired0.toInt256());
            _info.amountsUsdc[1] = _info.amountsUsdc[1].sub(amountRequired1.toInt256());
        } else {
            _info.amountUnderlying = _info.amountUnderlying.sub(_params.amountUnderlying);

            _info.amountsUsdc[0] = _info.amountsUsdc[0].add(amountRequired0.toInt256());
            _info.amountsUsdc[1] = _info.amountsUsdc[1].add(amountRequired1.toInt256());
        }
    }

    /**
     * @notice Gets required margin
     * @param _productId Id of product to get required margin
     * @param _params parameters to calculate required margin
     * @return RequiredMargin scaled by 1e8
     */
    function getRequiredMargin(uint256 _productId, AddMarginParams memory _params) internal pure returns (int256) {
        int256 weightedDelta = calculateWeightedDelta(_productId, _params.delta0, _params.delta1);
        int256 deltaFromGamma = 0;

        if (_productId == 1) {
            deltaFromGamma = _params.poolMarginRiskParam.mul(_params.spotPrice).mul(_params.gamma1).div(1e12);
        }

        int256 requiredMargin = (
            _params.spotPrice.mul(Math.abs(weightedDelta).add(Math.abs(deltaFromGamma)).toInt256())
        ).div(1e8);

        return ((1e4 + _params.poolMarginRiskParam).mul(requiredMargin)).div(1e4);
    }

    /**
     * @notice Gets notional value of hedge positions
     * HedgePositionValue_i = AmountsUsdc_i+(|delta_i| / (Σ|delta_i|))*AmountUnderlying*S
     * @return HedgePositionValue scaled by 1e8
     */
    function getHedgePositionValue(
        Info memory _info,
        AddMarginParams memory _params,
        uint256 _productId
    ) internal pure returns (int256) {
        int256 totalHedgeNotional = _params.spotPrice.mul(_info.amountUnderlying.toInt256()).div(1e8);

        int256 productHedgeNotional = totalHedgeNotional
            .mul(calculateWeight(0, _params.delta0, _params.delta1).toInt256())
            .div(1e16);

        if (_productId == 1) {
            productHedgeNotional = totalHedgeNotional.sub(productHedgeNotional);
        }

        int256 hedgePositionValue = _info.amountsUsdc[_productId].add(productHedgeNotional);

        return hedgePositionValue;
    }

    /**
     * @notice Gets notional value of hedge positions
     * HedgePositionValue_i = AmountsUsdc_0+AmountsUsdc_1+AmountUnderlying*S
     * @return HedgePositionValue scaled by 1e8
     */
    function getTotalHedgePositionValue(Info memory _info, int256 _spotPrice) internal pure returns (int256) {
        int256 hedgeNotional = _spotPrice.mul(_info.amountUnderlying.toInt256()).div(1e8);

        return (_info.amountsUsdc[0].add(_info.amountsUsdc[1])).add(hedgeNotional);
    }

    /**
     * @notice Calculates weighted delta
     * WeightedDelta = |delta_i| * (Σdelta_i) / (Σ|delta_i|)
     * @return weighted delta scaled by 1e8
     */
    function calculateWeightedDelta(
        uint256 _productId,
        int256 _delta0,
        int256 _delta1
    ) internal pure returns (int256) {
        int256 netDelta = _delta0.add(_delta1);

        return netDelta.mul(calculateWeight(_productId, _delta0, _delta1).toInt256()).div(1e16);
    }

    /**
     * @notice Calculates delta weighted value
     * WeightedDelta = |delta_i| / (Σ|delta_i|)
     * @return weighted delta scaled by 1e16
     */
    function calculateWeight(
        uint256 _productId,
        int256 _delta0,
        int256 _delta1
    ) internal pure returns (uint256) {
        uint256 totalDelta = (Math.abs(_delta0).add(Math.abs(_delta1)));

        require(totalDelta >= 0, "N1");

        if (totalDelta == 0) {
            return 0;
        }

        if (_productId == 0) {
            return (Math.abs(_delta0).mul(1e16)).div(totalDelta);
        } else if (_productId == 1) {
            return (Math.abs(_delta1).mul(1e16)).div(totalDelta);
        } else {
            revert("N0");
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IPerpetualMarketCore.sol";
import "./interfaces/IPerpetualMarket.sol";
import "./base/BaseLiquidityPool.sol";
import "./lib/TraderVaultLib.sol";
import "./interfaces/IVaultNFT.sol";

/**
 * @title Perpetual Market
 * @notice Perpetual Market Contract is entry point of traders and liquidity providers.
 * It manages traders' vault storage and holds funds from traders and liquidity providers.
 *
 * Error Codes
 * PM0: tx exceed deadline
 * PM1: limit price
 * PM2: caller is not vault owner
 * PM3: vault not found
 * PM4: caller is not hedger
 * PM5: vault limit
 * PM6: Paused
 * PM7: Not paused
 * PM8: USDC amount is too large
 * PM9: USDC amount is too small
 */
contract PerpetualMarket is IPerpetualMarket, BaseLiquidityPool, Ownable {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;
    using TraderVaultLib for TraderVaultLib.TraderVault;

    uint256 private constant MAX_PRODUCT_ID = 2;

    /// @dev liquidation fee is 20%
    int256 private constant LIQUIDATION_FEE = 2000;

    IPerpetualMarketCore private immutable perpetualMarketCore;

    /// @dev hedger address
    address public hedger;

    // Fee recepient address
    IFeePool public feeRecepient;

    /// @dev maximum positions in a vault
    uint256[2] public maxPositionsInVault;

    address private vaultNFT;

    // trader's vaults storage
    mapping(uint256 => TraderVaultLib.TraderVault) private traderVaults;

    /// @dev is system paused
    bool public isSystemPaused;

    event Deposited(address indexed account, uint256 issued, uint256 amount);

    event Withdrawn(address indexed account, uint256 burned, uint256 amount);

    event PositionUpdated(
        address indexed trader,
        uint256 vaultId,
        uint256 subVaultIndex,
        uint256 productId,
        int256 tradeAmount,
        uint256 tradePrice,
        int256 fundingFeePerPosition,
        int256 deltaUsdcPosition,
        bytes metadata
    );
    event DepositedToVault(address indexed trader, uint256 vaultId, uint256 amount);
    event WithdrawnFromVault(address indexed trader, uint256 vaultId, uint256 amount);
    event Liquidated(address liquidator, uint256 indexed vaultId, uint256 reward);

    event Hedged(address hedger, bool isBuyingUnderlying, uint256 usdcAmount, uint256 underlyingAmount);

    event SetFeeRecepient(address feeRecepient);
    event Paused();
    event UnPaused();

    modifier onlyHedger() {
        require(msg.sender == hedger, "PM4");
        _;
    }

    modifier notPaused() {
        require(!isSystemPaused, "PM6");
        _;
    }

    modifier isPaused() {
        require(isSystemPaused, "PM7");
        _;
    }

    /**
     * @notice Constructor of Perpetual Market contract
     */
    constructor(
        address _perpetualMarketCoreAddress,
        address _quoteAsset,
        address _underlyingAsset,
        address _feeRecepient,
        address _vaultNFT
    ) BaseLiquidityPool(_quoteAsset, _underlyingAsset) {
        require(_feeRecepient != address(0));

        hedger = msg.sender;

        perpetualMarketCore = IPerpetualMarketCore(_perpetualMarketCoreAddress);
        feeRecepient = IFeePool(_feeRecepient);
        vaultNFT = _vaultNFT;

        maxPositionsInVault[0] = 1000000 * 1e8;
        maxPositionsInVault[1] = 1000000 * 1e8;
    }

    /**
     * @notice Initializes Perpetual Pool
     * @param _depositAmount deposit amount
     * @param _initialFundingRate initial funding rate
     */
    function initialize(uint256 _depositAmount, int256 _initialFundingRate) external override notPaused {
        require(_depositAmount > 0 && _initialFundingRate > 0);

        uint256 lpTokenAmount = perpetualMarketCore.initialize(msg.sender, _depositAmount * 1e2, _initialFundingRate);

        IERC20(quoteAsset).safeTransferFrom(msg.sender, address(this), _depositAmount);

        emit Deposited(msg.sender, lpTokenAmount, _depositAmount);
    }

    /**
     * @notice Provides liquidity to the pool and mints LP tokens
     */
    function deposit(uint256 _depositAmount) external override notPaused {
        require(_depositAmount > 0);

        // Funding payment should be proceeded before deposit
        perpetualMarketCore.executeFundingPayment();

        uint256 lpTokenAmount = perpetualMarketCore.deposit(msg.sender, _depositAmount * 1e2);

        IERC20(quoteAsset).safeTransferFrom(msg.sender, address(this), _depositAmount);

        emit Deposited(msg.sender, lpTokenAmount, _depositAmount);
    }

    /**
     * @notice Withdraws liquidity from the pool and burn LP tokens
     */
    function withdraw(uint128 _withdrawnAmount) external override notPaused {
        require(_withdrawnAmount > 0);

        // Funding payment should be proceeded before withdrawal
        perpetualMarketCore.executeFundingPayment();

        uint256 lpTokenAmount = perpetualMarketCore.withdraw(msg.sender, _withdrawnAmount * 1e2);

        // Send liquidity to msg.sender
        sendLiquidity(msg.sender, _withdrawnAmount);

        emit Withdrawn(msg.sender, lpTokenAmount, _withdrawnAmount);
    }

    /**
     * @notice Opens new positions or closes hold position of the perpetual contracts
     * and manage margin in the vault at the same time.
     * @param _tradeParams trade parameters
     */
    function trade(MultiTradeParams memory _tradeParams) external override notPaused {
        // check the transaction not exceed deadline
        require(_tradeParams.deadline == 0 || _tradeParams.deadline >= block.number, "PM0");

        if (_tradeParams.vaultId == 0) {
            // open new vault
            _tradeParams.vaultId = IVaultNFT(vaultNFT).mintNFT(msg.sender);
        } else {
            // check caller is vault owner
            require(IVaultNFT(vaultNFT).ownerOf(_tradeParams.vaultId) == msg.sender, "PM2");
        }

        // funding payment should bee proceeded before trade
        perpetualMarketCore.executeFundingPayment();

        uint256 totalProtocolFee;

        {
            uint256[2] memory tradePrices;
            int256[2] memory fundingPaidPerPositions;

            (tradePrices, fundingPaidPerPositions, totalProtocolFee) = updatePoolPosition(
                traderVaults[_tradeParams.vaultId],
                getTradeAmounts(_tradeParams.trades),
                getLimitPrices(_tradeParams.trades)
            );

            for (uint256 i = 0; i < _tradeParams.trades.length; i++) {
                updateSubVault(
                    traderVaults[_tradeParams.vaultId],
                    _tradeParams.trades[i].productId,
                    _tradeParams.vaultId,
                    _tradeParams.trades[i].subVaultIndex,
                    tradePrices[_tradeParams.trades[i].productId],
                    fundingPaidPerPositions[_tradeParams.trades[i].productId],
                    _tradeParams.trades[i].tradeAmount,
                    _tradeParams.trades[i].metadata
                );
            }
        }

        // Add protocol fee
        if (totalProtocolFee > 0) {
            IERC20(quoteAsset).approve(address(feeRecepient), totalProtocolFee);
            feeRecepient.sendProfitERC20(address(this), totalProtocolFee);
        }

        int256 finalDepositOrWithdrawAmount;

        finalDepositOrWithdrawAmount = traderVaults[_tradeParams.vaultId].updateUsdcPosition(
            _tradeParams.marginAmount.mul(1e2),
            perpetualMarketCore.getTradePriceInfo(getTradeAmountsToCloseVault(traderVaults[_tradeParams.vaultId]))
        );

        // Try to update variance after trade
        perpetualMarketCore.updatePoolSnapshot();

        if (finalDepositOrWithdrawAmount > 0) {
            uint256 depositAmount = uint256(finalDepositOrWithdrawAmount / 1e2);
            IERC20(quoteAsset).safeTransferFrom(msg.sender, address(this), depositAmount);
            emit DepositedToVault(msg.sender, _tradeParams.vaultId, depositAmount);
        } else if (finalDepositOrWithdrawAmount < 0) {
            uint256 withdrawAmount = uint256(-finalDepositOrWithdrawAmount) / 1e2;
            sendLiquidity(msg.sender, withdrawAmount);
            emit WithdrawnFromVault(msg.sender, _tradeParams.vaultId, withdrawAmount);
        }
    }

    function getTradeAmounts(TradeParams[] memory _trades) internal pure returns (int256[2] memory tradeAmounts) {
        for (uint256 i = 0; i < _trades.length; i++) {
            tradeAmounts[_trades[i].productId] = tradeAmounts[_trades[i].productId].add(_trades[i].tradeAmount);
        }

        return tradeAmounts;
    }

    function getLimitPrices(TradeParams[] memory _trades) internal pure returns (uint256[2] memory limitPrices) {
        for (uint256 i = 0; i < _trades.length; i++) {
            limitPrices[_trades[i].productId] = _trades[i].limitPrice;
        }

        return limitPrices;
    }

    /**
     * @notice Gets trade amounts to close the vault
     */
    function getTradeAmountsToCloseVault(TraderVaultLib.TraderVault memory _traderVault)
        internal
        pure
        returns (int256[2] memory tradeAmounts)
    {
        int128[2] memory positionPerpetuals = _traderVault.getPositionPerpetuals();

        tradeAmounts[0] = -positionPerpetuals[0];
        tradeAmounts[1] = -positionPerpetuals[1];

        return tradeAmounts;
    }

    /**
     * @notice Checks vault position limit and reverts if position exceeds limit
     */
    function checkVaultPositionLimit(TraderVaultLib.TraderVault memory _traderVault, int256[2] memory _tradeAmounts)
        internal
        view
    {
        int128[2] memory positionPerpetuals = _traderVault.getPositionPerpetuals();

        for (uint256 productId = 0; productId < MAX_PRODUCT_ID; productId++) {
            int256 positionAfter = positionPerpetuals[productId].add(_tradeAmounts[productId]);

            if (Math.abs(positionAfter) > Math.abs(positionPerpetuals[productId])) {
                // if the trader opens new position, check positionAfter is less than max.
                require(Math.abs(positionAfter) <= maxPositionsInVault[productId], "PM5");
            }
        }
    }

    /**
     * @notice Add margin to the vault
     * @param _vaultId id of the vault
     * @param _marginToAdd amount of margin to add
     */
    function addMargin(uint256 _vaultId, int256 _marginToAdd) external override {
        require(_vaultId > 0 && _vaultId < IVaultNFT(vaultNFT).nextId(), "PM3");

        // increase USDC position
        traderVaults[_vaultId].addUsdcPosition(_marginToAdd.mul(1e2));

        // receive USDC from caller
        uint256 depositAmount = _marginToAdd.toUint256();
        IERC20(quoteAsset).safeTransferFrom(msg.sender, address(this), depositAmount);

        // emit event
        emit DepositedToVault(msg.sender, _vaultId, depositAmount);
    }

    /**
     * @notice Liquidates a vault by Pool
     * Anyone can liquidate a vault whose PositionValue is less than MinCollateral.
     * The caller gets a portion of the margin as reward.
     * @param _vaultId The id of target vault
     */
    function liquidateByPool(uint256 _vaultId) external override notPaused {
        // funding payment should bee proceeded before liquidation
        perpetualMarketCore.executeFundingPayment();

        TraderVaultLib.TraderVault storage traderVault = traderVaults[_vaultId];

        IPerpetualMarketCore.TradePriceInfo memory tradePriceInfo = perpetualMarketCore.getTradePriceInfo(
            getTradeAmountsToCloseVault(traderVault)
        );

        // Check if PositionValue is less than MinCollateral or not
        require(traderVault.checkVaultIsDanger(tradePriceInfo), "vault is not danger");

        int256 minCollateral = traderVault.getMinCollateral(tradePriceInfo);

        require(minCollateral > 0, "vault has no positions");

        // Close all positions in the vault
        uint256 totalProtocolFee;

        {
            uint256[2] memory tradePrices;
            int256[2] memory fundingPaidPerPositions;

            (tradePrices, fundingPaidPerPositions, totalProtocolFee) = updatePoolPosition(
                traderVault,
                getTradeAmountsToCloseVault(traderVault),
                [uint256(0), uint256(0)]
            );

            for (uint256 subVaultIndex = 0; subVaultIndex < traderVault.subVaults.length; subVaultIndex++) {
                for (uint256 productId = 0; productId < MAX_PRODUCT_ID; productId++) {
                    int128 amountAssetInVault = traderVault.subVaults[subVaultIndex].positionPerpetuals[productId];

                    updateSubVault(
                        traderVault,
                        productId,
                        _vaultId,
                        subVaultIndex,
                        tradePrices[productId],
                        fundingPaidPerPositions[productId],
                        -amountAssetInVault,
                        ""
                    );
                }
            }
        }

        uint256 reward = traderVault.decreaseLiquidationReward(minCollateral, LIQUIDATION_FEE);

        // Sends a half of reward to the pool
        perpetualMarketCore.addLiquidity(reward / 2);

        // Sends a half of reward to the liquidator
        sendLiquidity(msg.sender, reward / (2 * 1e2));

        // Try to update variance after liquidation
        perpetualMarketCore.updatePoolSnapshot();

        // Sends protocol fee
        if (totalProtocolFee > 0) {
            IERC20(quoteAsset).approve(address(feeRecepient), totalProtocolFee);
            feeRecepient.sendProfitERC20(address(this), totalProtocolFee);
        }

        emit Liquidated(msg.sender, _vaultId, reward);
    }

    /**
     * @notice Updates pool position.
     * It returns trade price and fundingPaidPerPosition for each product, and protocol fee.
     */
    function updatePoolPosition(
        TraderVaultLib.TraderVault memory _traderVault,
        int256[2] memory _tradeAmounts,
        uint256[2] memory _limitPrices
    )
        internal
        returns (
            uint256[2] memory tradePrices,
            int256[2] memory fundingPaidPerPositions,
            uint256 protocolFee
        )
    {
        checkVaultPositionLimit(_traderVault, _tradeAmounts);

        (tradePrices, fundingPaidPerPositions, protocolFee) = perpetualMarketCore.updatePoolPositions(_tradeAmounts);

        require(checkPrice(_tradeAmounts[0] > 0, tradePrices[0], _limitPrices[0]), "PM1");
        require(checkPrice(_tradeAmounts[1] > 0, tradePrices[1], _limitPrices[1]), "PM1");

        protocolFee = protocolFee / 1e2;
    }

    /**
     * @notice Update sub-vault
     */
    function updateSubVault(
        TraderVaultLib.TraderVault storage _traderVault,
        uint256 _productId,
        uint256 _vaultId,
        uint256 _subVaultIndex,
        uint256 _tradePrice,
        int256 _fundingFeePerPosition,
        int128 _tradeAmount,
        bytes memory _metadata
    ) internal {
        if (_tradeAmount == 0) {
            return;
        }
        (int256 deltaUsdcPosition, uint256 lpProfit) = _traderVault.updateVault(
            _subVaultIndex,
            _productId,
            _tradeAmount,
            _tradePrice,
            _fundingFeePerPosition
        );

        perpetualMarketCore.addLiquidity(lpProfit);

        emit PositionUpdated(
            msg.sender,
            _vaultId,
            _subVaultIndex,
            _productId,
            _tradeAmount,
            _tradePrice,
            _fundingFeePerPosition,
            deltaUsdcPosition,
            _metadata
        );
    }

    /**
     * @notice Gets token amount for hedging
     * @return Amount of USDC and underlying reqired for hedging
     */
    function getTokenAmountForHedging()
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        NettingLib.CompleteParams memory completeParams = perpetualMarketCore.getTokenAmountForHedging();

        return (
            completeParams.isLong,
            completeParams.amountUsdc / 1e2,
            Math.scale(completeParams.amountUnderlying, 8, ERC20(underlyingAsset).decimals())
        );
    }

    /**
     * @notice Executes hedging
     */
    function execHedge(bool _withRebalance, uint256 _amountUsdc)
        external
        override
        onlyHedger
        returns (uint256 amountUnderlying)
    {
        // execute funding payment
        perpetualMarketCore.executeFundingPayment();

        // Try to update variance after funding payment
        perpetualMarketCore.updatePoolSnapshot();

        if (_withRebalance) {
            // rebalance before hedge
            perpetualMarketCore.rebalance();
        }

        NettingLib.CompleteParams memory completeParams = perpetualMarketCore.getTokenAmountForHedging();

        if (completeParams.isLong) {
            require(completeParams.amountUsdc / 1e2 >= _amountUsdc, "PM8");
        } else {
            require(completeParams.amountUsdc / 1e2 <= _amountUsdc, "PM9");
        }

        completeParams.amountUsdc = _amountUsdc.mul(1e2);

        perpetualMarketCore.completeHedgingProcedure(completeParams);

        if (_withRebalance) {
            // rebalance after hedge
            perpetualMarketCore.rebalance();
        }

        amountUnderlying = Math.scale(completeParams.amountUnderlying, 8, ERC20(underlyingAsset).decimals());

        if (completeParams.isLong) {
            IERC20(underlyingAsset).safeTransferFrom(msg.sender, address(this), amountUnderlying);
            sendLiquidity(msg.sender, _amountUsdc);
        } else {
            IERC20(quoteAsset).safeTransferFrom(msg.sender, address(this), _amountUsdc);
            sendUndrlying(msg.sender, amountUnderlying);
        }

        emit Hedged(msg.sender, completeParams.isLong, _amountUsdc, amountUnderlying);
    }

    /**
     * @notice Compares trade price and limit price
     * For long, if trade price is less than limit price then return true.
     * For short, if trade price is greater than limit price then return true.
     * if limit price is 0 then always return true.
     * @param _isLong true if the trade is long and false if the trade is short
     * @param _tradePrice trade price per trade amount
     * @param _limitPrice the worst price the trader accept
     */
    function checkPrice(
        bool _isLong,
        uint256 _tradePrice,
        uint256 _limitPrice
    ) internal pure returns (bool) {
        if (_limitPrice == 0) {
            return true;
        }
        if (_isLong) {
            return _tradePrice <= _limitPrice;
        } else {
            return _tradePrice >= _limitPrice;
        }
    }

    /**
     * @notice Gets current LP token price
     * @param _deltaLiquidityAmount difference of liquidity
     * If LPs want LP token price of deposit, _deltaLiquidityAmount is positive number of amount to deposit.
     * On the other hand, if LPs want LP token price of withdrawal, _deltaLiquidityAmount is negative number of amount to withdraw.
     * @return LP token price scaled by 1e6
     */
    function getLPTokenPrice(int256 _deltaLiquidityAmount) external view override returns (uint256) {
        return perpetualMarketCore.getLPTokenPrice(_deltaLiquidityAmount);
    }

    /**
     * @notice Gets trade price
     * @param _productId product id
     * @param _tradeAmounts amount of position to trade. positive to get long price and negative to get short price.
     * @return trade info
     */
    function getTradePrice(uint256 _productId, int256[2] memory _tradeAmounts)
        external
        view
        override
        returns (TradeInfo memory)
    {
        (
            int256 tradePrice,
            int256 indexPrice,
            int256 fundingRate,
            int256 tradeFee,
            int256 protocolFee
        ) = perpetualMarketCore.getTradePrice(_productId, _tradeAmounts);

        return
            TradeInfo(
                tradePrice,
                indexPrice,
                fundingRate,
                tradeFee,
                protocolFee,
                indexPrice.mul(fundingRate).div(1e16),
                tradePrice.toUint256().mul(Math.abs(_tradeAmounts[_productId])).div(1e8),
                tradeFee.toUint256().mul(Math.abs(_tradeAmounts[_productId])).div(1e8)
            );
    }

    /**
     * @notice Gets value of min collateral to add positions
     * @param _vaultId The id of target vault
     * @param _tradeAmounts amounts to trade
     * @return minCollateral scaled by 1e6
     */
    function getMinCollateralToAddPosition(uint256 _vaultId, int128[2] memory _tradeAmounts)
        external
        view
        override
        returns (int256 minCollateral)
    {
        TraderVaultLib.TraderVault memory traderVault = traderVaults[_vaultId];

        minCollateral = traderVault.getMinCollateralToAddPosition(
            _tradeAmounts,
            perpetualMarketCore.getTradePriceInfo(getTradeAmountsToCloseVault(traderVault))
        );

        minCollateral = minCollateral / 1e2;
    }

    function getTraderVault(uint256 _vaultId) external view override returns (TraderVaultLib.TraderVault memory) {
        return traderVaults[_vaultId];
    }

    /**
     * @notice Gets position value and min collateral
     * @param _vaultId The id of target vault
     */
    function getPositionValueAndMinCollateral(uint256 _vaultId) external view returns (int256, int256) {
        TraderVaultLib.TraderVault memory traderVault = traderVaults[_vaultId];
        IPerpetualMarketCore.TradePriceInfo memory tradePriceInfo = perpetualMarketCore.getTradePriceInfo(
            getTradeAmountsToCloseVault(traderVault)
        );

        return (traderVault.getPositionValue(tradePriceInfo), traderVault.getMinCollateral(tradePriceInfo));
    }

    /**
     * @notice Gets position value of a vault
     * @param _vaultId The id of target vault
     * @return vault status
     */
    function getVaultStatus(uint256 _vaultId) external view override returns (VaultStatus memory) {
        TraderVaultLib.TraderVault memory traderVault = traderVaults[_vaultId];

        IPerpetualMarketCore.TradePriceInfo memory tradePriceInfo = perpetualMarketCore.getTradePriceInfo(
            getTradeAmountsToCloseVault(traderVault)
        );

        int256[2][] memory positionValues = new int256[2][](traderVault.subVaults.length);
        int256[2][] memory fundingPaid = new int256[2][](traderVault.subVaults.length);

        for (uint256 i = 0; i < traderVault.subVaults.length; i++) {
            for (uint256 j = 0; j < MAX_PRODUCT_ID; j++) {
                positionValues[i][j] = TraderVaultLib.getPerpetualValueOfSubVault(
                    traderVault.subVaults[i],
                    j,
                    tradePriceInfo
                );
                fundingPaid[i][j] = TraderVaultLib.getFundingFeePaidOfSubVault(
                    traderVault.subVaults[i],
                    j,
                    tradePriceInfo.amountsFundingPaidPerPosition
                );
            }
        }

        return
            VaultStatus(
                traderVault.getPositionValue(tradePriceInfo),
                traderVault.getMinCollateral(tradePriceInfo),
                positionValues,
                fundingPaid,
                traderVault
            );
    }

    /////////////////////////
    //  Admin Functions    //
    /////////////////////////

    /**
     * @notice Sets new fee recepient
     * @param _feeRecepient The address of new fee recepient
     */
    function setFeeRecepient(address _feeRecepient) external onlyOwner {
        require(_feeRecepient != address(0));
        feeRecepient = IFeePool(_feeRecepient);
        emit SetFeeRecepient(_feeRecepient);
    }

    /**
     * @notice set bot address
     * @param _hedger bot address
     */
    function setHedger(address _hedger) external onlyOwner {
        hedger = _hedger;
    }

    /**
     * @notice Sets max amounts that a vault can hold
     * @param _maxFutureAmount max future amount
     * @param _maxSquaredAmount max squared amount
     */
    function setMaxAmount(uint256 _maxFutureAmount, uint256 _maxSquaredAmount) external onlyOwner {
        maxPositionsInVault[0] = _maxFutureAmount;
        maxPositionsInVault[1] = _maxSquaredAmount;
    }

    /**
     * @notice pause the contract
     */
    function pause() external onlyOwner notPaused {
        isSystemPaused = true;

        emit Paused();
    }

    /**
     * @notice unpause the contract
     */
    function unPause() external onlyOwner isPaused {
        isSystemPaused = false;

        emit UnPaused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

interface IFeePool {
    function sendProfitERC20(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title Base Liquidity Pool
 * @notice Base Liquidity Pool Contract
 */
abstract contract BaseLiquidityPool {
    using SafeERC20 for IERC20;

    address public immutable quoteAsset;
    address public immutable underlyingAsset;

    /**
     * @notice initialize liquidity pool
     */
    constructor(address _quoteAsset, address _underlyingAsset) {
        require(_quoteAsset != address(0));
        require(_underlyingAsset != address(0));

        quoteAsset = _quoteAsset;
        underlyingAsset = _underlyingAsset;
    }

    function sendLiquidity(address _recipient, uint256 _amount) internal {
        IERC20(quoteAsset).safeTransfer(_recipient, _amount);
    }

    function sendUndrlying(address _recipient, uint256 _amount) internal {
        IERC20(underlyingAsset).safeTransfer(_recipient, _amount);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVaultNFT is IERC721 {
    function nextId() external returns (uint256);

    function mintNFT(address _recipient) external returns (uint256 tokenId);
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import "./interfaces/IVaultNFT.sol";

/**
 * @notice ERC721 representing ownership of a vault
 */
contract VaultNFT is ERC721, IVaultNFT, Initializable {
    uint256 public override nextId = 1;

    address public perpetualMarket;
    address private immutable deployer;

    modifier onlyPerpetualMarket() {
        require(msg.sender == perpetualMarket, "Not Perpetual Market");
        _;
    }

    /**
     * @notice Vault NFT constructor
     * @param _name token name for ERC721
     * @param _symbol token symbol for ERC721
     * @param _baseURI base URI
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        deployer = msg.sender;
        _setBaseURI(_baseURI);
    }

    /**
     * @notice Initializes Vault NFT
     * @param _perpetualMarket Perpetual Market address
     */
    function init(address _perpetualMarket) public initializer {
        require(msg.sender == deployer, "Caller is not deployer");
        require(_perpetualMarket != address(0), "Zero address");
        perpetualMarket = _perpetualMarket;
    }

    /**
     * @notice mint new NFT
     * @dev auto increment tokenId starts from 1
     * @param _recipient recipient address for NFT
     */
    function mintNFT(address _recipient) external override onlyPerpetualMarket returns (uint256 tokenId) {
        _safeMint(_recipient, (tokenId = nextId++));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./interfaces/IPerpetualMarketCore.sol";
import "./lib/NettingLib.sol";
import "./lib/IndexPricer.sol";
import "./lib/SpreadLib.sol";
import "./lib/EntryPriceMath.sol";
import "./lib/PoolMath.sol";

import "arbos-precompiles/arbos/builtin/ArbSys.sol";

/**
 * @title PerpetualMarketCore
 * @notice Perpetual Market Core Contract manages perpetual pool positions and calculates amount of collaterals.
 * Error Code
 * PMC0: No available liquidity
 * PMC1: No available liquidity
 * PMC2: caller must be PerpetualMarket contract
 * PMC3: underlying price must not be 0
 * PMC4: pool delta must be negative
 * PMC5: invalid params
 */
contract PerpetualMarketCore is IPerpetualMarketCore, Ownable, ERC20 {
    using NettingLib for NettingLib.Info;
    using SpreadLib for SpreadLib.Info;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;

    uint256 private constant MAX_PRODUCT_ID = 2;

    // λ for exponentially weighted moving average is 94%
    int256 private constant LAMBDA = 94 * 1e6;

    // funding period is 1 days
    int256 private constant FUNDING_PERIOD = 1 days;

    // max ratio of (IV/RV)^2 for squeeth pool
    int256 private squaredPerpFundingMultiplier;

    // max funding rate of future pool
    int256 private perpFutureMaxFundingRate;

    // min slippage tolerance of a hedge
    uint256 private minSlippageToleranceOfHedge;

    // max slippage tolerance of a hedge
    uint256 private maxSlippageToleranceOfHedge;

    // rate of return threshold of a hedge
    uint256 private hedgeRateOfReturnThreshold;

    // allowable percentage of movement in the underlying spot price
    int256 private poolMarginRiskParam;

    // trade fee
    int256 private tradeFeeRate;

    // protocol fee
    int256 private protocolFeeRate;

    struct Pool {
        uint128 amountLockedLiquidity;
        int128 positionPerpetuals;
        uint128 entryPrice;
        int256 amountFundingPaidPerPosition;
        uint128 lastFundingPaymentTime;
    }

    struct PoolSnapshot {
        int128 futureBaseFundingRate;
        int128 ethVariance;
        int128 ethPrice;
        uint128 lastSnapshotTime;
    }

    enum MarginChange {
        ShortToShort,
        ShortToLong,
        LongToLong,
        LongToShort
    }

    // Total amount of liquidity provided by LPs
    uint256 public amountLiquidity;

    // Pools information storage
    mapping(uint256 => Pool) public pools;

    // Infos for spread calculation
    mapping(uint256 => SpreadLib.Info) private spreadInfos;

    // Infos for LPToken's spread calculation
    SpreadLib.Info private lpTokenSpreadInfo;

    // Snapshot of pool state at last ETH variance calculation
    PoolSnapshot public poolSnapshot;

    // Infos for collateral calculation
    NettingLib.Info private nettingInfo;

    // The address of Chainlink price feed
    AggregatorV3Interface private priceFeed;

    // The address of ArbSys
    ArbSys private arbSys;

    // The last spot price at heding
    int256 public lastHedgeSpotPrice;

    // The address of Perpetual Market Contract
    address private perpetualMarket;

    event FundingPayment(
        uint256 productId,
        int256 fundingRate,
        int256 amountFundingPaidPerPosition,
        int256 fundingPaidPerPosition,
        int256 poolReceived
    );
    event VarianceUpdated(int256 variance, int256 underlyingPrice, uint256 timestamp);

    event SetSquaredPerpFundingMultiplier(int256 squaredPerpFundingMultiplier);
    event SetPerpFutureMaxFundingRate(int256 perpFutureMaxFundingRate);
    event SetHedgeParams(
        uint256 minSlippageToleranceOfHedge,
        uint256 maxSlippageToleranceOfHedge,
        uint256 hedgeRateOfReturnThreshold
    );
    event SetPoolMarginRiskParam(int256 poolMarginRiskParam);
    event SetTradeFeeRate(int256 tradeFeeRate, int256 protocolFeeRate);
    event SetSpreadParams(uint256 safetyPeriod, uint256 numBlocksPerSpreadDecreasing);

    modifier onlyPerpetualMarket() {
        require(msg.sender == perpetualMarket, "PMC2");
        _;
    }

    constructor(
        address _priceFeedAddress,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _arbSysAddress
    ) ERC20(_tokenName, _tokenSymbol) {
        // The decimals of LP token is 8
        _setupDecimals(8);

        priceFeed = AggregatorV3Interface(_priceFeedAddress);

        arbSys = ArbSys(_arbSysAddress);

        // initialize spread infos
        spreadInfos[0].init();
        spreadInfos[1].init();
        lpTokenSpreadInfo.init();

        // 550%
        squaredPerpFundingMultiplier = 550 * 1e6;
        // 0.22%
        perpFutureMaxFundingRate = 22 * 1e4;
        // min slippage tolerance of a hedge is 0.4%
        minSlippageToleranceOfHedge = 40;
        // max slippage tolerance of a hedge is 0.8%
        maxSlippageToleranceOfHedge = 80;
        // rate of return threshold of a hedge is 2.5 %
        hedgeRateOfReturnThreshold = 25 * 1e5;
        // Pool collateral risk param is 40%
        poolMarginRiskParam = 4000;
        // Trade fee is 0.05%
        tradeFeeRate = 5 * 1e4;
        // Protocol fee is 0.02%
        protocolFeeRate = 2 * 1e4;
    }

    function setPerpetualMarket(address _perpetualMarket) external onlyOwner {
        require(perpetualMarket == address(0) && _perpetualMarket != address(0));
        perpetualMarket = _perpetualMarket;
    }

    /**
     * @notice Initialize pool with initial liquidity and funding rate
     */
    function initialize(
        address _depositor,
        uint256 _depositAmount,
        int256 _initialFundingRate
    ) external override onlyPerpetualMarket returns (uint256 mintAmount) {
        require(totalSupply() == 0);
        mintAmount = _depositAmount;

        (int256 spotPrice, ) = getUnderlyingPrice();

        // initialize pool snapshot
        poolSnapshot.ethVariance = _initialFundingRate.toInt128();
        poolSnapshot.ethPrice = spotPrice.toInt128();
        poolSnapshot.lastSnapshotTime = block.timestamp.toUint128();

        // initialize last spot price at heding
        lastHedgeSpotPrice = spotPrice;

        amountLiquidity = amountLiquidity.add(_depositAmount);
        _mint(_depositor, mintAmount);
    }

    /**
     * @notice Provides liquidity
     */
    function deposit(address _depositor, uint256 _depositAmount)
        external
        override
        onlyPerpetualMarket
        returns (uint256 mintAmount)
    {
        require(totalSupply() > 0);

        uint256 lpTokenPrice = getLPTokenPrice(_depositAmount.toInt256());

        lpTokenPrice = lpTokenSpreadInfo.checkPrice(true, int256(lpTokenPrice), arbSys.arbBlockNumber()).toUint256();

        mintAmount = _depositAmount.mul(1e16).div(lpTokenPrice);

        amountLiquidity = amountLiquidity.add(_depositAmount);
        _mint(_depositor, mintAmount);
    }

    /**xx
     * @notice Withdraws liquidity
     */
    function withdraw(address _withdrawer, uint256 _withdrawnAmount)
        external
        override
        onlyPerpetualMarket
        returns (uint256 burnAmount)
    {
        require(getAvailableLiquidityAmount() >= _withdrawnAmount, "PMC0");

        uint256 lpTokenPrice = getLPTokenPrice(-_withdrawnAmount.toInt256());

        lpTokenPrice = lpTokenSpreadInfo.checkPrice(false, int256(lpTokenPrice), arbSys.arbBlockNumber()).toUint256();

        burnAmount = _withdrawnAmount.mul(1e16).div(lpTokenPrice);

        amountLiquidity = amountLiquidity.sub(_withdrawnAmount);
        _burn(_withdrawer, burnAmount);
    }

    function addLiquidity(uint256 _amount) external override onlyPerpetualMarket {
        amountLiquidity = amountLiquidity.add(_amount);
    }

    /**
     * @notice Adds or removes pool positions
     * @param _tradeAmounts amount of positions to trade.
     * positive for pool short and negative for pool long.
     */
    function updatePoolPositions(int256[2] memory _tradeAmounts)
        public
        override
        onlyPerpetualMarket
        returns (
            uint256[2] memory tradePrice,
            int256[2] memory fundingPaidPerPosition,
            uint256 protocolFee
        )
    {
        require(amountLiquidity > 0, "PMC1");

        int256 profitValue = 0;

        // Updates pool positions
        pools[0].positionPerpetuals = pools[0].positionPerpetuals.sub(_tradeAmounts[0]).toInt128();
        pools[1].positionPerpetuals = pools[1].positionPerpetuals.sub(_tradeAmounts[1]).toInt128();

        if (_tradeAmounts[0] != 0) {
            uint256 futureProtocolFee;
            int256 futureProfitValue;
            (tradePrice[0], fundingPaidPerPosition[0], futureProtocolFee, futureProfitValue) = updatePoolPosition(
                0,
                _tradeAmounts[0]
            );
            protocolFee = protocolFee.add(futureProtocolFee);
            profitValue = profitValue.add(futureProfitValue);
        }
        if (_tradeAmounts[1] != 0) {
            uint256 squaredProtocolFee;
            int256 squaredProfitValue;
            (tradePrice[1], fundingPaidPerPosition[1], squaredProtocolFee, squaredProfitValue) = updatePoolPosition(
                1,
                _tradeAmounts[1]
            );
            protocolFee = protocolFee.add(squaredProtocolFee);
            profitValue = profitValue.add(squaredProfitValue);
        }

        amountLiquidity = Math.addDelta(amountLiquidity, profitValue.sub(protocolFee.toInt256()));
    }

    /**
     * @notice Adds or removes pool position for a product
     * @param _productId product id
     * @param _tradeAmount amount of position to trade. positive for pool short and negative for pool long.
     */
    function updatePoolPosition(uint256 _productId, int256 _tradeAmount)
        internal
        returns (
            uint256 tradePrice,
            int256,
            uint256 protocolFee,
            int256 profitValue
        )
    {
        (int256 spotPrice, ) = getUnderlyingPrice();

        // Calculate trade price
        (tradePrice, protocolFee) = calculateSafeTradePrice(_productId, spotPrice, _tradeAmount);

        {
            int256 newEntryPrice;
            (newEntryPrice, profitValue) = EntryPriceMath.updateEntryPrice(
                int256(pools[_productId].entryPrice),
                pools[_productId].positionPerpetuals.add(_tradeAmount),
                int256(tradePrice),
                -_tradeAmount
            );

            pools[_productId].entryPrice = newEntryPrice.toUint256().toUint128();
        }

        return (tradePrice, pools[_productId].amountFundingPaidPerPosition, protocolFee, profitValue);
    }

    /**
     * @notice Locks liquidity if more collateral required
     * and unlocks liquidity if there is unrequied collateral.
     */
    function rebalance() external override onlyPerpetualMarket {
        (int256 spotPrice, ) = getUnderlyingPrice();

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            int256 deltaMargin;
            int256 deltaLiquidity;

            {
                int256 hedgePositionValue;
                (deltaMargin, hedgePositionValue) = addMargin(i, spotPrice);

                (, deltaMargin, deltaLiquidity) = calculatePreTrade(
                    i,
                    deltaMargin,
                    hedgePositionValue,
                    MarginChange.LongToLong
                );
            }

            if (deltaLiquidity != 0) {
                amountLiquidity = Math.addDelta(amountLiquidity, deltaLiquidity);
            }
            if (deltaMargin != 0) {
                pools[i].amountLockedLiquidity = Math.addDelta(pools[i].amountLockedLiquidity, deltaMargin).toUint128();
            }
        }
    }

    /**
     * @notice Gets USDC and underlying amount to make the pool delta neutral
     */
    function getTokenAmountForHedging()
        external
        view
        override
        returns (NettingLib.CompleteParams memory completeParams)
    {
        (int256 spotPrice, ) = getUnderlyingPrice();

        (int256 futurePoolDelta, int256 sqeethPoolDelta) = getDeltas(
            spotPrice,
            pools[0].positionPerpetuals,
            pools[1].positionPerpetuals
        );

        int256[2] memory deltas;

        deltas[0] = futurePoolDelta;
        deltas[1] = sqeethPoolDelta;

        completeParams = NettingLib.getRequiredTokenAmountsForHedge(nettingInfo.amountUnderlying, deltas, spotPrice);

        uint256 slippageTolerance = calculateSlippageToleranceForHedging(spotPrice);

        if (completeParams.isLong) {
            completeParams.amountUsdc = (completeParams.amountUsdc.mul(uint256(10000).add(slippageTolerance))).div(
                10000
            );
        } else {
            completeParams.amountUsdc = (completeParams.amountUsdc.mul(uint256(10000).sub(slippageTolerance))).div(
                10000
            );
        }
    }

    /**
     * @notice Update netting info to complete heging procedure
     */
    function completeHedgingProcedure(NettingLib.CompleteParams memory _completeParams)
        external
        override
        onlyPerpetualMarket
    {
        (int256 spotPrice, ) = getUnderlyingPrice();

        lastHedgeSpotPrice = spotPrice;

        nettingInfo.complete(_completeParams);
    }

    function getNettingInfo() external view returns (NettingLib.Info memory) {
        return nettingInfo;
    }

    /**
     * @notice Updates pool snapshot
     * Calculates ETH variance and base funding rate for future pool.
     */
    function updatePoolSnapshot() external override onlyPerpetualMarket {
        if (block.timestamp < poolSnapshot.lastSnapshotTime + 12 hours) {
            return;
        }

        updateVariance(block.timestamp);
        updateBaseFundingRate();
    }

    function executeFundingPayment() external override onlyPerpetualMarket {
        (int256 spotPrice, ) = getUnderlyingPrice();

        // Funding payment
        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            _executeFundingPayment(i, spotPrice);
        }
    }

    /**
     * @notice Calculates ETH variance under the Exponentially Weighted Moving Average Model.
     */
    function updateVariance(uint256 _timestamp) internal {
        (int256 spotPrice, ) = getUnderlyingPrice();

        // u_{t-1} = (S_t - S_{t-1}) / S_{t-1}
        int256 u = spotPrice.sub(poolSnapshot.ethPrice).mul(1e8).div(poolSnapshot.ethPrice);

        int256 uPower2 = u.mul(u).div(1e8);

        // normalization
        uPower2 = (uPower2.mul(FUNDING_PERIOD)).div((_timestamp - poolSnapshot.lastSnapshotTime).toInt256());

        // Updates snapshot
        // variance_{t} = λ * variance_{t-1} + (1 - λ) * u_{t-1}^2
        poolSnapshot.ethVariance = ((LAMBDA.mul(poolSnapshot.ethVariance).add((1e8 - LAMBDA).mul(uPower2))) / 1e8)
            .toInt128();
        poolSnapshot.ethPrice = spotPrice.toInt128();
        poolSnapshot.lastSnapshotTime = _timestamp.toUint128();

        emit VarianceUpdated(poolSnapshot.ethVariance, poolSnapshot.ethPrice, _timestamp);
    }

    function updateBaseFundingRate() internal {
        poolSnapshot.futureBaseFundingRate = 0;
    }

    /////////////////////////
    //  Admin Functions    //
    /////////////////////////

    function setSquaredPerpFundingMultiplier(int256 _squaredPerpFundingMultiplier) external onlyOwner {
        require(_squaredPerpFundingMultiplier >= 0 && _squaredPerpFundingMultiplier <= 2000 * 1e6);
        squaredPerpFundingMultiplier = _squaredPerpFundingMultiplier;
        emit SetSquaredPerpFundingMultiplier(_squaredPerpFundingMultiplier);
    }

    function setPerpFutureMaxFundingRate(int256 _perpFutureMaxFundingRate) external onlyOwner {
        require(_perpFutureMaxFundingRate >= 0 && _perpFutureMaxFundingRate <= 1 * 1e6);
        perpFutureMaxFundingRate = _perpFutureMaxFundingRate;
        emit SetPerpFutureMaxFundingRate(_perpFutureMaxFundingRate);
    }

    function setHedgeParams(
        uint256 _minSlippageToleranceOfHedge,
        uint256 _maxSlippageToleranceOfHedge,
        uint256 _hedgeRateOfReturnThreshold
    ) external onlyOwner {
        require(
            _minSlippageToleranceOfHedge >= 0 && _maxSlippageToleranceOfHedge >= 0 && _hedgeRateOfReturnThreshold >= 0
        );
        require(
            _minSlippageToleranceOfHedge < _maxSlippageToleranceOfHedge && _maxSlippageToleranceOfHedge <= 200,
            "PMC5"
        );

        minSlippageToleranceOfHedge = _minSlippageToleranceOfHedge;
        maxSlippageToleranceOfHedge = _maxSlippageToleranceOfHedge;
        hedgeRateOfReturnThreshold = _hedgeRateOfReturnThreshold;
        emit SetHedgeParams(_minSlippageToleranceOfHedge, _maxSlippageToleranceOfHedge, _hedgeRateOfReturnThreshold);
    }

    function setPoolMarginRiskParam(int256 _poolMarginRiskParam) external onlyOwner {
        require(_poolMarginRiskParam >= 0);
        poolMarginRiskParam = _poolMarginRiskParam;
        emit SetPoolMarginRiskParam(_poolMarginRiskParam);
    }

    function setTradeFeeRate(int256 _tradeFeeRate, int256 _protocolFeeRate) external onlyOwner {
        require(0 <= _protocolFeeRate && _tradeFeeRate <= 30 * 1e4 && _protocolFeeRate < _tradeFeeRate, "PMC5");
        tradeFeeRate = _tradeFeeRate;
        protocolFeeRate = _protocolFeeRate;
        emit SetTradeFeeRate(_tradeFeeRate, _protocolFeeRate);
    }

    function setSpreadParams(uint256 _safetyPeriod, uint256 _numBlocksPerSpreadDecreasing) external onlyOwner {
        require(0 <= _safetyPeriod && _safetyPeriod <= 600, "PMC5");
        require(0 < _numBlocksPerSpreadDecreasing && _numBlocksPerSpreadDecreasing <= 600, "PMC5");

        spreadInfos[0].setParams(_safetyPeriod, _numBlocksPerSpreadDecreasing);
        spreadInfos[1].setParams(_safetyPeriod, _numBlocksPerSpreadDecreasing);
        lpTokenSpreadInfo.setParams(_safetyPeriod, _numBlocksPerSpreadDecreasing);
        emit SetSpreadParams(_safetyPeriod, _numBlocksPerSpreadDecreasing);
    }

    /////////////////////////
    //  Getter Functions   //
    /////////////////////////

    /**
     * @notice Gets LP token price
     * LPTokenPrice = (L + ΣUnrealizedPnL_i - ΣAmountLockedLiquidity_i) / Supply
     * @return LPTokenPrice scaled by 1e16
     */
    function getLPTokenPrice(int256 _deltaLiquidityAmount) public view override returns (uint256) {
        (int256 spotPrice, ) = getUnderlyingPrice();

        int256 unrealizedPnL = (
            getUnrealizedPnL(0, spotPrice, _deltaLiquidityAmount).add(
                getUnrealizedPnL(1, spotPrice, _deltaLiquidityAmount)
            )
        );

        int256 hedgePositionValue = nettingInfo.getTotalHedgePositionValue(spotPrice);

        return
            (
                (
                    uint256(amountLiquidity.toInt256().add(hedgePositionValue).add(unrealizedPnL))
                        .sub(pools[0].amountLockedLiquidity)
                        .sub(pools[1].amountLockedLiquidity)
                ).mul(1e16)
            ).div(totalSupply());
    }

    /**
     * @notice Gets trade price
     * @param _productId product id
     * @param _tradeAmounts amount of position to trade. positive for pool short and negative for pool long.
     */
    function getTradePrice(uint256 _productId, int256[2] memory _tradeAmounts)
        external
        view
        override
        returns (
            int256,
            int256,
            int256,
            int256,
            int256
        )
    {
        (int256 spotPrice, ) = getUnderlyingPrice();

        return calculateTradePriceReadOnly(_productId, spotPrice, _tradeAmounts, 0);
    }

    /**
     * @notice Gets utilization ratio
     * Utilization Ratio = (ΣAmountLockedLiquidity_i) / L
     * @return Utilization Ratio scaled by 1e8
     */
    function getUtilizationRatio() external view returns (uint256) {
        uint256 amountLocked;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            amountLocked = amountLocked.add(pools[i].amountLockedLiquidity);
        }

        return amountLocked.mul(1e8).div(amountLiquidity);
    }

    function getTradePriceInfo(int256[2] memory _tradeAmounts) external view override returns (TradePriceInfo memory) {
        (int256 spotPrice, ) = getUnderlyingPrice();

        int256[2] memory tradePrices;
        int256[2] memory fundingRates;
        int256[2] memory amountFundingPaidPerPositionGlobals;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            int256 indexPrice;
            (tradePrices[i], indexPrice, fundingRates[i], , ) = calculateTradePriceReadOnly(
                i,
                spotPrice,
                _tradeAmounts,
                0
            );

            // funding payments should be calculated from the current funding rate
            int256 currentFundingRate = getCurrentFundingRate(i);

            int256 fundingFeePerPosition = calculateFundingFeePerPosition(
                i,
                indexPrice,
                currentFundingRate,
                block.timestamp
            );

            amountFundingPaidPerPositionGlobals[i] = pools[i].amountFundingPaidPerPosition.add(fundingFeePerPosition);
        }

        return TradePriceInfo(uint128(spotPrice), tradePrices, fundingRates, amountFundingPaidPerPositionGlobals);
    }

    /////////////////////////
    //  Private Functions  //
    /////////////////////////

    /**
     * @notice Executes funding payment
     */
    function _executeFundingPayment(uint256 _productId, int256 _spotPrice) internal {
        if (pools[_productId].lastFundingPaymentTime == 0) {
            // Initialize timestamp
            pools[_productId].lastFundingPaymentTime = uint128(block.timestamp);
            return;
        }

        if (block.timestamp <= pools[_productId].lastFundingPaymentTime) {
            return;
        }

        (
            int256 currentFundingRate,
            int256 fundingFeePerPosition,
            int256 fundingReceived
        ) = calculateResultOfFundingPayment(_productId, _spotPrice, block.timestamp);

        pools[_productId].amountFundingPaidPerPosition = pools[_productId].amountFundingPaidPerPosition.add(
            fundingFeePerPosition
        );

        if (fundingReceived != 0) {
            amountLiquidity = Math.addDelta(amountLiquidity, fundingReceived);
        }

        // Update last timestamp of funding payment
        pools[_productId].lastFundingPaymentTime = uint128(block.timestamp);

        emit FundingPayment(
            _productId,
            currentFundingRate,
            pools[_productId].amountFundingPaidPerPosition,
            fundingFeePerPosition,
            fundingReceived
        );
    }

    /**
     * @notice Calculates funding rate, funding fee per position and funding fee that the pool will receive.
     * @param _productId product id
     * @param _spotPrice current spot price for index calculation
     * @param _currentTimestamp the timestamp to execute funding payment
     */
    function calculateResultOfFundingPayment(
        uint256 _productId,
        int256 _spotPrice,
        uint256 _currentTimestamp
    )
        internal
        view
        returns (
            int256 currentFundingRate,
            int256 fundingFeePerPosition,
            int256 fundingReceived
        )
    {
        int256 indexPrice = IndexPricer.calculateIndexPrice(_productId, _spotPrice);

        currentFundingRate = getCurrentFundingRate(_productId);

        fundingFeePerPosition = calculateFundingFeePerPosition(
            _productId,
            indexPrice,
            currentFundingRate,
            _currentTimestamp
        );

        // Pool receives 'FundingPaidPerPosition * -(Pool Positions)' USDC as funding fee.
        fundingReceived = (fundingFeePerPosition.mul(-pools[_productId].positionPerpetuals)).div(1e16);
    }

    /**
     * @notice Calculates amount of funding fee which long position should pay per position.
     * FundingPaidPerPosition = IndexPrice * FundingRate * (T-t) / 1 days
     * @param _productId product id
     * @param _indexPrice index price of the perpetual
     * @param _currentFundingRate current funding rate used to calculate funding fee
     * @param _currentTimestamp the timestamp to execute funding payment
     */
    function calculateFundingFeePerPosition(
        uint256 _productId,
        int256 _indexPrice,
        int256 _currentFundingRate,
        uint256 _currentTimestamp
    ) internal view returns (int256 fundingFeePerPosition) {
        fundingFeePerPosition = _indexPrice.mul(_currentFundingRate).div(1e8);

        // Normalization by FUNDING_PERIOD
        fundingFeePerPosition = (
            fundingFeePerPosition.mul(int256(_currentTimestamp.sub(pools[_productId].lastFundingPaymentTime)))
        ).div(FUNDING_PERIOD);
    }

    /**
     * @notice Gets current funding rate
     * @param _productId product id
     */
    function getCurrentFundingRate(uint256 _productId) internal view returns (int256) {
        return
            calculateFundingRate(
                _productId,
                getSignedMarginAmount(pools[_productId].positionPerpetuals, _productId),
                amountLiquidity.toInt256(),
                0,
                0
            );
    }

    /**
     * @notice Calculates signedDeltaMargin and changes of lockedLiquidity and totalLiquidity.
     * @return signedDeltaMargin is Δmargin: the change of the signed margin.
     * @return unlockLiquidityAmount is the change of the absolute amount of margin.
     * if return value is negative it represents unrequired.
     * @return deltaLiquidity Δliquidity: the change of the total liquidity amount.
     */
    function calculatePreTrade(
        uint256 _productId,
        int256 _deltaMargin,
        int256 _hedgePositionValue,
        MarginChange _marginChangeType
    )
        internal
        view
        returns (
            int256 signedDeltaMargin,
            int256 unlockLiquidityAmount,
            int256 deltaLiquidity
        )
    {
        if (_deltaMargin > 0) {
            if (_hedgePositionValue >= 0) {
                // In case of lock additional margin
                require(getAvailableLiquidityAmount() >= uint256(_deltaMargin), "PMC1");
                unlockLiquidityAmount = _deltaMargin;
            } else {
                // unlock all negative hedgePositionValue
                (deltaLiquidity, unlockLiquidityAmount) = (
                    _hedgePositionValue.sub(pools[_productId].amountLockedLiquidity.toInt256()),
                    -pools[_productId].amountLockedLiquidity.toInt256()
                );
                // lock additional margin
                require(getAvailableLiquidityAmount() >= uint256(_deltaMargin.add(_hedgePositionValue)), "PMC1");
                unlockLiquidityAmount = unlockLiquidityAmount.add(_deltaMargin.add(_hedgePositionValue));
            }
        } else if (_deltaMargin < 0) {
            // In case of unlock unrequired margin
            // _hedgePositionValue should be positive because _deltaMargin=RequiredMargin-_hedgePositionValue<0 => 0<RequiredMargin<_hedgePositionValue
            (deltaLiquidity, unlockLiquidityAmount) = calculateUnlockedLiquidity(
                pools[_productId].amountLockedLiquidity,
                _deltaMargin,
                _hedgePositionValue
            );
        }

        // Calculate signedDeltaMargin
        signedDeltaMargin = calculateSignedDeltaMargin(
            _marginChangeType,
            unlockLiquidityAmount,
            pools[_productId].amountLockedLiquidity
        );
    }

    /**
     * @notice Calculates trade price checked by spread manager
     * @return trade price and total protocol fee
     */
    function calculateSafeTradePrice(
        uint256 _productId,
        int256 _spotPrice,
        int256 _tradeAmount
    ) internal returns (uint256, uint256) {
        int256 deltaMargin;
        int256 signedDeltaMargin;
        int256 deltaLiquidity;
        {
            int256 hedgePositionValue;
            (deltaMargin, hedgePositionValue) = addMargin(_productId, _spotPrice);
            (signedDeltaMargin, deltaMargin, deltaLiquidity) = calculatePreTrade(
                _productId,
                deltaMargin,
                hedgePositionValue,
                getMarginChange(pools[_productId].positionPerpetuals, _tradeAmount)
            );
        }

        int256 signedMarginAmount = getSignedMarginAmount(
            // Calculate pool position before trade
            pools[_productId].positionPerpetuals.add(_tradeAmount),
            _productId
        );

        (int256 tradePrice, int256 protocolFee) = calculateTradePriceAndProtocolFee(
            _productId,
            _spotPrice,
            _tradeAmount,
            signedMarginAmount,
            signedDeltaMargin,
            deltaLiquidity
        );

        // Update pool liquidity and locked liquidity
        {
            if (deltaLiquidity != 0) {
                amountLiquidity = Math.addDelta(amountLiquidity, deltaLiquidity);
            }
            pools[_productId].amountLockedLiquidity = Math
                .addDelta(pools[_productId].amountLockedLiquidity, deltaMargin)
                .toUint128();
        }

        return (tradePrice.toUint256(), protocolFee.toUint256().mul(Math.abs(_tradeAmount)).div(1e8));
    }

    function calculateTradePriceAndProtocolFee(
        uint256 _productId,
        int256 _spotPrice,
        int256 _tradeAmount,
        int256 _signedMarginAmount,
        int256 _signedDeltaMargin,
        int256 _deltaLiquidity
    ) internal returns (int256 tradePrice, int256 protocolFee) {
        (tradePrice, , , , protocolFee) = calculateTradePrice(
            _productId,
            _spotPrice,
            _tradeAmount > 0,
            _signedMarginAmount,
            amountLiquidity.toInt256(),
            _signedDeltaMargin,
            _deltaLiquidity
        );

        tradePrice = spreadInfos[_productId].checkPrice(_tradeAmount > 0, tradePrice, arbSys.arbBlockNumber());
    }

    /**
     * @notice Calculates trade price as read-only trade.
     * @return tradePrice , indexPrice, fundingRate, tradeFee and protocolFee
     */
    function calculateTradePriceReadOnly(
        uint256 _productId,
        int256 _spotPrice,
        int256[2] memory _tradeAmounts,
        int256 _deltaLiquidity
    )
        internal
        view
        returns (
            int256 tradePrice,
            int256 indexPrice,
            int256 estFundingRate,
            int256 tradeFee,
            int256 protocolFee
        )
    {
        int256 signedDeltaMargin;

        if (_tradeAmounts[_productId] != 0) {
            (int256 deltaMargin, int256 hedgePositionValue, MarginChange marginChangeType) = getRequiredMargin(
                _productId,
                _spotPrice,
                _tradeAmounts
            );

            int256 deltaLiquidityByTrade;

            (signedDeltaMargin, , deltaLiquidityByTrade) = calculatePreTrade(
                _productId,
                deltaMargin,
                hedgePositionValue,
                marginChangeType
            );

            _deltaLiquidity = _deltaLiquidity.add(deltaLiquidityByTrade);
        }
        {
            int256 signedMarginAmount = getSignedMarginAmount(pools[_productId].positionPerpetuals, _productId);

            (tradePrice, indexPrice, , tradeFee, protocolFee) = calculateTradePrice(
                _productId,
                _spotPrice,
                _tradeAmounts[_productId] > 0,
                signedMarginAmount,
                amountLiquidity.toInt256(),
                signedDeltaMargin,
                _deltaLiquidity
            );

            // Calculate estimated funding rate
            estFundingRate = calculateFundingRate(
                _productId,
                signedMarginAmount.add(signedDeltaMargin),
                amountLiquidity.toInt256().add(_deltaLiquidity),
                0,
                0
            );
        }

        tradePrice = spreadInfos[_productId].getUpdatedPrice(
            _tradeAmounts[_productId] > 0,
            tradePrice,
            block.timestamp
        );

        return (tradePrice, indexPrice, estFundingRate, tradeFee, protocolFee);
    }

    /**
     * @notice Adds margin to Netting contract
     */
    function addMargin(uint256 _productId, int256 _spot)
        internal
        returns (int256 deltaMargin, int256 hedgePositionValue)
    {
        (int256 delta0, int256 delta1) = getDeltas(_spot, pools[0].positionPerpetuals, pools[1].positionPerpetuals);
        int256 gamma = (IndexPricer.calculateGamma(1).mul(pools[1].positionPerpetuals)) / 1e8;

        (deltaMargin, hedgePositionValue) = nettingInfo.addMargin(
            _productId,
            NettingLib.AddMarginParams(delta0, delta1, gamma, _spot, poolMarginRiskParam)
        );
    }

    /**
     * @notice Calculated required or unrequired margin for read-only price calculation.
     * @return deltaMargin is the change of the absolute amount of margin.
     * @return hedgePositionValue is current value of locked margin.
     * if return value is negative it represents unrequired.
     */
    function getRequiredMargin(
        uint256 _productId,
        int256 _spot,
        int256[2] memory _tradeAmounts
    )
        internal
        view
        returns (
            int256 deltaMargin,
            int256 hedgePositionValue,
            MarginChange marginChangeType
        )
    {
        int256 delta0;
        int256 delta1;
        int256 gamma;

        {
            int256 tradeAmount0 = pools[0].positionPerpetuals;
            int256 tradeAmount1 = pools[1].positionPerpetuals;

            tradeAmount0 = tradeAmount0.sub(_tradeAmounts[0]);
            tradeAmount1 = tradeAmount1.sub(_tradeAmounts[1]);

            if (_productId == 0) {
                marginChangeType = getMarginChange(tradeAmount0, _tradeAmounts[0]);
            }

            if (_productId == 1) {
                marginChangeType = getMarginChange(tradeAmount1, _tradeAmounts[1]);
            }

            (delta0, delta1) = getDeltas(_spot, tradeAmount0, tradeAmount1);
            gamma = (IndexPricer.calculateGamma(1).mul(tradeAmount1)) / 1e8;
        }

        NettingLib.AddMarginParams memory params = NettingLib.AddMarginParams(
            delta0,
            delta1,
            gamma,
            _spot,
            poolMarginRiskParam
        );

        int256 totalRequiredMargin = NettingLib.getRequiredMargin(_productId, params);

        hedgePositionValue = nettingInfo.getHedgePositionValue(params, _productId);

        deltaMargin = totalRequiredMargin.sub(hedgePositionValue);
    }

    /**
     * @notice Gets signed amount of margin used for trade price calculation.
     * @param _position current pool position
     * @param _productId product id
     * @return signedMargin is calculated by following rule.
     * If poolPosition is 0 then SignedMargin is 0.
     * If poolPosition is long then SignedMargin is negative.
     * If poolPosition is short then SignedMargin is positive.
     */
    function getSignedMarginAmount(int256 _position, uint256 _productId) internal view returns (int256) {
        if (_position == 0) {
            return 0;
        } else if (_position > 0) {
            return -pools[_productId].amountLockedLiquidity.toInt256();
        } else {
            return pools[_productId].amountLockedLiquidity.toInt256();
        }
    }

    /**
     * @notice Get signed delta margin. Signed delta margin is the change of the signed margin.
     * It is used for trade price calculation.
     * For example, if pool position becomes to short 10 from long 10 and deltaMargin hasn't changed.
     * Then deltaMargin should be 0 but signedDeltaMargin should be +20.
     * @param _deltaMargin amount of change in margin resulting from the trade
     * @param _currentMarginAmount amount of locked margin before trade
     * @return signedDeltaMargin is calculated by follows.
     * Crossing case:
     *   If position moves long to short then
     *     Δm = currentMarginAmount * 2 + deltaMargin
     *   If position moves short to long then
     *     Δm = -(currentMarginAmount * 2 + deltaMargin)
     * Non Crossing Case:
     *   If position moves long to long then
     *     Δm = -deltaMargin
     *   If position moves short to short then
     *     Δm = deltaMargin
     */
    function calculateSignedDeltaMargin(
        MarginChange _marginChangeType,
        int256 _deltaMargin,
        int256 _currentMarginAmount
    ) internal pure returns (int256) {
        if (_marginChangeType == MarginChange.LongToShort) {
            return _currentMarginAmount.mul(2).add(_deltaMargin);
        } else if (_marginChangeType == MarginChange.ShortToLong) {
            return -(_currentMarginAmount.mul(2).add(_deltaMargin));
        } else if (_marginChangeType == MarginChange.LongToLong) {
            return -_deltaMargin;
        } else {
            // In case of ShortToShort
            return _deltaMargin;
        }
    }

    /**
     * @notice Gets the type of margin change.
     * @param _newPosition positions resulting from trades
     * @param _positionTrade delta positions to trade
     * @return marginChange the type of margin change
     */
    function getMarginChange(int256 _newPosition, int256 _positionTrade) internal pure returns (MarginChange) {
        int256 position = _newPosition.add(_positionTrade);

        if (position > 0 && _newPosition < 0) {
            return MarginChange.LongToShort;
        } else if (position < 0 && _newPosition > 0) {
            return MarginChange.ShortToLong;
        } else if (position >= 0 && _newPosition >= 0) {
            return MarginChange.LongToLong;
        } else {
            return MarginChange.ShortToShort;
        }
    }

    /**
     * @notice Calculates delta liquidity amount and unlock liquidity amount
     * unlockLiquidityAmount = Δm * amountLockedLiquidity / hedgePositionValue
     * deltaLiquidity = Δm - UnlockAmount
     */
    function calculateUnlockedLiquidity(
        uint256 _amountLockedLiquidity,
        int256 _deltaMargin,
        int256 _hedgePositionValue
    ) internal pure returns (int256 deltaLiquidity, int256 unlockLiquidityAmount) {
        unlockLiquidityAmount = _deltaMargin.mul(_amountLockedLiquidity.toInt256()).div(_hedgePositionValue);

        return ((unlockLiquidityAmount.sub(_deltaMargin)), unlockLiquidityAmount);
    }

    /**
     * @notice Calculates perpetual's trade price
     * TradePrice = IndexPrice * (1 + FundingRate) + TradeFee
     * @return TradePrice scaled by 1e8
     */
    function calculateTradePrice(
        uint256 _productId,
        int256 _spotPrice,
        bool _isLong,
        int256 _margin,
        int256 _totalLiquidityAmount,
        int256 _deltaMargin,
        int256 _deltaLiquidity
    )
        internal
        view
        returns (
            int256,
            int256 indexPrice,
            int256,
            int256 tradeFee,
            int256 protocolFee
        )
    {
        int256 fundingRate = calculateFundingRate(
            _productId,
            _margin,
            _totalLiquidityAmount,
            _deltaMargin,
            _deltaLiquidity
        );

        indexPrice = IndexPricer.calculateIndexPrice(_productId, _spotPrice);

        int256 tradePrice = (indexPrice.mul(int256(1e16).add(fundingRate))).div(1e16);

        tradeFee = getTradeFee(_productId, _isLong, indexPrice);

        tradePrice = tradePrice.add(tradeFee);

        protocolFee = getProtocolFee(_productId, indexPrice);

        return (tradePrice, indexPrice, fundingRate, Math.abs(tradeFee).toInt256(), protocolFee);
    }

    /**
     * @notice Gets trade fee
     * TradeFee = IndxPrice * tradeFeeRate
     */
    function getTradeFee(
        uint256 _productId,
        bool _isLong,
        int256 _indexPrice
    ) internal view returns (int256) {
        require(_indexPrice > 0);

        if (_isLong) {
            return _indexPrice.mul(tradeFeeRate).mul(int256(_productId + 1)) / 1e8;
        } else {
            return -_indexPrice.mul(tradeFeeRate).mul(int256(_productId + 1)) / 1e8;
        }
    }

    /**
     * @notice Gets protocol fee
     * ProtocolFee = IndxPrice * protocolFeeRate
     */
    function getProtocolFee(uint256 _productId, int256 _indexPrice) internal view returns (int256) {
        require(_indexPrice > 0);

        return _indexPrice.mul(protocolFeeRate).mul(int256(_productId + 1)) / 1e8;
    }

    function getDeltas(
        int256 _spotPrice,
        int256 _tradeAmount0,
        int256 _tradeAmount1
    ) internal pure returns (int256, int256) {
        int256 futurePoolDelta = (IndexPricer.calculateDelta(0, _spotPrice).mul(_tradeAmount0)) / 1e8;
        int256 sqeethPoolDelta = (IndexPricer.calculateDelta(1, _spotPrice).mul(_tradeAmount1)) / 1e8;
        return (futurePoolDelta, sqeethPoolDelta);
    }

    /**
     * @notice Calculates Unrealized PnL
     * UnrealizedPnL = (TradePrice - EntryPrice) * Position_i + HedgePositionValue
     * TradePrice is calculated as fill price of closing all pool positions.
     * @return UnrealizedPnL scaled by 1e8
     */
    function getUnrealizedPnL(
        uint256 _productId,
        int256 _spotPrice,
        int256 _deltaLiquidityAmount
    ) internal view returns (int256) {
        int256 positionsValue;
        int256[2] memory positionPerpetuals;

        positionPerpetuals[0] = pools[0].positionPerpetuals;
        positionPerpetuals[1] = pools[1].positionPerpetuals;

        if (pools[_productId].positionPerpetuals != 0) {
            (int256 tradePrice, , , , ) = calculateTradePriceReadOnly(
                _productId,
                _spotPrice,
                positionPerpetuals,
                _deltaLiquidityAmount
            );
            positionsValue =
                pools[_productId].positionPerpetuals.mul(tradePrice.sub(pools[_productId].entryPrice.toInt256())) /
                1e8;
        }

        return positionsValue;
    }

    /**
     * @notice Calculates perpetual's funding rate
     * Squared:
     *   FundingRate = variance * (1 + squaredPerpFundingMultiplier * m / L)
     * Future:
     *   FundingRate = BASE_FUNDING_RATE + perpFutureMaxFundingRate * (m / L)
     * @param _productId product id
     * @param _margin amount of locked margin before trade
     * @param _totalLiquidityAmount amount of total liquidity before trade
     * @param _deltaMargin amount of change in margin resulting from the trade
     * @param _deltaLiquidity difference of liquidity
     * @return FundingRate scaled by 1e16 (1e16 = 100%)
     */
    function calculateFundingRate(
        uint256 _productId,
        int256 _margin,
        int256 _totalLiquidityAmount,
        int256 _deltaMargin,
        int256 _deltaLiquidity
    ) internal view returns (int256) {
        if (_productId == 0) {
            int256 fundingRate = perpFutureMaxFundingRate
                .mul(
                    PoolMath.calculateFundingRateFormula(_margin, _deltaMargin, _totalLiquidityAmount, _deltaLiquidity)
                )
                .div(1e8);
            return poolSnapshot.futureBaseFundingRate.add(fundingRate);
        } else if (_productId == 1) {
            if (_totalLiquidityAmount == 0) {
                return poolSnapshot.ethVariance.mul(1e8);
            } else {
                int256 addition = squaredPerpFundingMultiplier
                    .mul(
                        PoolMath.calculateFundingRateFormula(
                            _margin,
                            _deltaMargin,
                            _totalLiquidityAmount,
                            _deltaLiquidity
                        )
                    )
                    .div(1e8);
                return poolSnapshot.ethVariance.mul(int256(1e16).add(addition)).div(1e8);
            }
        }
        return 0;
    }

    /**
     * @notice Calculates the slippage tolerance of USDC amount for a hedge
     */
    function calculateSlippageToleranceForHedging(int256 _spotPrice) internal view returns (uint256 slippageTolerance) {
        uint256 rateOfReturn = Math.abs(_spotPrice.sub(lastHedgeSpotPrice).mul(1e8).div(lastHedgeSpotPrice));

        slippageTolerance = minSlippageToleranceOfHedge.add(
            (maxSlippageToleranceOfHedge - minSlippageToleranceOfHedge).mul(rateOfReturn).div(
                hedgeRateOfReturnThreshold
            )
        );

        if (slippageTolerance < minSlippageToleranceOfHedge) slippageTolerance = minSlippageToleranceOfHedge;
        if (slippageTolerance > maxSlippageToleranceOfHedge) slippageTolerance = maxSlippageToleranceOfHedge;
    }

    /**
     * @notice Gets available amount of liquidity
     * available amount = amountLiquidity - (ΣamountLocked_i)
     */
    function getAvailableLiquidityAmount() internal view returns (uint256) {
        uint256 amountLocked;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            amountLocked = amountLocked.add(pools[i].amountLockedLiquidity);

            if (nettingInfo.amountsUsdc[i] < 0) {
                amountLocked = Math.addDelta(amountLocked, -nettingInfo.amountsUsdc[i]);
            }
        }

        return amountLiquidity.sub(amountLocked);
    }

    /**
     * @notice get underlying price scaled by 1e8
     */
    function getUnderlyingPrice() internal view returns (int256, uint256) {
        (, int256 answer, , uint256 roundTimestamp, ) = priceFeed.latestRoundData();

        require(answer > 0, "PMC3");

        return (answer, roundTimestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title IndexPricer
 * @notice Library contract that has functions to calculate Index price and Greeks of perpetual
 */
library IndexPricer {
    using SignedSafeMath for int256;

    /// @dev Scaling factor for squared index price.
    int256 public constant SCALING_FACTOR = 1e4;

    /**
     * @notice Calculates index price of perpetuals
     * Future: ETH
     * Squeeth: ETH^2 / 10000
     * @return calculated index price scaled by 1e8
     */
    function calculateIndexPrice(uint256 _productId, int256 _spot) internal pure returns (int256) {
        if (_productId == 0) {
            return _spot;
        } else if (_productId == 1) {
            return (_spot.mul(_spot)) / (1e8 * SCALING_FACTOR);
        } else {
            revert("NP");
        }
    }

    /**
     * @notice Calculates delta of perpetuals
     * Future: 1
     * Squeeth: 2 * ETH / 10000
     * @return calculated delta scaled by 1e8
     */
    function calculateDelta(uint256 _productId, int256 _spot) internal pure returns (int256) {
        if (_productId == 0) {
            return 1e8;
        } else if (_productId == 1) {
            return _spot.mul(2) / SCALING_FACTOR;
        } else {
            revert("NP");
        }
    }

    /**
     * @notice Calculates gamma of perpetuals
     * Future: 0
     * Squeeth: 2 / 10000
     * @return calculated gamma scaled by 1e8
     */
    function calculateGamma(uint256 _productId) internal pure returns (int256) {
        if (_productId == 0) {
            return 0;
        } else if (_productId == 1) {
            return 2 * SCALING_FACTOR;
        } else {
            revert("NP");
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title SpreadLib
 * @notice Spread Library has functions to controls spread for short-term volatility risk management
 */
library SpreadLib {
    using SafeCast for int256;
    using SafeCast for uint128;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int128;

    /// @dev block period for ETH - USD
    uint256 private constant SAFETY_BLOCK_PERIOD = 17;

    /// @dev number of blocks per spread decreasing
    uint256 private constant NUM_BLOCKS_PER_SPREAD_DECREASING = 3;

    struct Info {
        uint128 blockLastLongTransaction;
        int128 minLongTradePrice;
        uint128 blockLastShortTransaction;
        int128 maxShortTradePrice;
        uint256 safetyBlockPeriod;
        uint256 numBlocksPerSpreadDecreasing;
    }

    function init(Info storage _info) internal {
        _info.minLongTradePrice = type(int128).max;
        _info.maxShortTradePrice = 0;
        _info.safetyBlockPeriod = SAFETY_BLOCK_PERIOD;
        _info.numBlocksPerSpreadDecreasing = NUM_BLOCKS_PER_SPREAD_DECREASING;
    }

    function setParams(
        Info storage _info,
        uint256 _safetyBlockPeriod,
        uint256 _numBlocksPerSpreadDecreasing
    ) internal {
        _info.safetyBlockPeriod = _safetyBlockPeriod;
        _info.numBlocksPerSpreadDecreasing = _numBlocksPerSpreadDecreasing;
    }

    /**
     * @notice Checks and updates price to guarantee that
     * max(bit) ≤ min(ask) from some point t to t-Safety Period.
     * @param _isLong trade is long or short
     * @param _price trade price
     * @return adjustedPrice adjusted price
     */
    function checkPrice(
        Info storage _info,
        bool _isLong,
        int256 _price,
        uint256 _blocknumber
    ) internal returns (int256 adjustedPrice) {
        Info memory cache = Info(
            _info.blockLastLongTransaction,
            _info.minLongTradePrice,
            _info.blockLastShortTransaction,
            _info.maxShortTradePrice,
            _info.safetyBlockPeriod,
            _info.numBlocksPerSpreadDecreasing
        );
        // MockArbSys mockArbSys = new MockArbSys();
        adjustedPrice = getUpdatedPrice(cache, _isLong, _price, _blocknumber);

        _info.blockLastLongTransaction = cache.blockLastLongTransaction;
        _info.minLongTradePrice = cache.minLongTradePrice;
        _info.blockLastShortTransaction = cache.blockLastShortTransaction;
        _info.maxShortTradePrice = cache.maxShortTradePrice;
    }

    function getUpdatedPrice(
        Info memory _info,
        bool _isLong,
        int256 _price,
        uint256 _blocknumber
    ) internal pure returns (int256 adjustedPrice) {
        adjustedPrice = _price;
        if (_isLong) {
            // if long
            if (_info.blockLastShortTransaction >= _blocknumber - _info.safetyBlockPeriod) {
                // Within safety period
                if (adjustedPrice < _info.maxShortTradePrice) {
                    int256 spreadClosing = ((_blocknumber - _info.blockLastShortTransaction) /
                        _info.numBlocksPerSpreadDecreasing).toInt256();
                    if (adjustedPrice <= (_info.maxShortTradePrice.mul(1e4 - spreadClosing)) / 1e4) {
                        _info.maxShortTradePrice = ((_info.maxShortTradePrice.mul(1e4 - spreadClosing)) / 1e4)
                            .toInt128();
                    }
                    adjustedPrice = _info.maxShortTradePrice;
                }
            }

            // Update min ask
            if (
                _info.minLongTradePrice > adjustedPrice ||
                _info.blockLastLongTransaction + _info.safetyBlockPeriod < _blocknumber
            ) {
                _info.minLongTradePrice = adjustedPrice.toInt128();
            }
            _info.blockLastLongTransaction = uint128(_blocknumber);
        } else {
            // if short
            if (_info.blockLastLongTransaction >= _blocknumber - _info.safetyBlockPeriod) {
                // Within safety period
                if (adjustedPrice > _info.minLongTradePrice) {
                    int256 spreadClosing = ((_blocknumber - _info.blockLastLongTransaction) /
                        _info.numBlocksPerSpreadDecreasing).toInt256();
                    if (adjustedPrice >= (_info.minLongTradePrice.mul(1e4 + spreadClosing)) / 1e4) {
                        _info.minLongTradePrice = ((_info.minLongTradePrice.mul(1e4 + spreadClosing)) / 1e4).toInt128();
                    }
                    adjustedPrice = _info.minLongTradePrice;
                }
            }

            // Update max bit
            if (
                _info.maxShortTradePrice < adjustedPrice ||
                _info.blockLastShortTransaction + _info.safetyBlockPeriod < _blocknumber
            ) {
                _info.maxShortTradePrice = adjustedPrice.toInt128();
            }
            _info.blockLastShortTransaction = uint128(_blocknumber);
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "./Math.sol";

/**
 * @notice AMM related math library
 */
library PoolMath {
    using SignedSafeMath for int256;
    using SafeCast for int256;

    int256 private constant K = 4;

    /**
     * @notice Calculate multiple integral of k*(m/L)+(1-k)(m/L)^3.
     * @param _m required margin
     * @param _deltaMargin difference of required margin
     * @param _l total amount of liquidity
     * @param _deltaL difference of liquidity
     * @return returns result of above formula
     */
    function calculateFundingRateFormula(
        int256 _m,
        int256 _deltaMargin,
        int256 _l,
        int256 _deltaL
    ) internal pure returns (int256) {
        require(_l > 0, "l must be positive");

        return
            K
                .mul(calculateMarginDivLiquidity(_m, _deltaMargin, _l, _deltaL))
                .add((10 - K).mul(calculateMarginDivLiquidity3(_m, _deltaMargin, _l, _deltaL)))
                .div(10);
    }

    /**
     * @notice Calculate multiple integral of (m/L)^3.
     * The formula is `(_m^3 + (3/2)*_m^2 * _deltaMargin + _m * _deltaMargin^2 + _deltaMargin^3 / 4) * (_l + _deltaL / 2) / (_l^2 * (_l + _deltaL)^2)`.
     * @param _m required margin
     * @param _deltaMargin difference of required margin
     * @param _l total amount of liquidity
     * @param _deltaL difference of liquidity
     * @return returns result of above formula
     */
    function calculateMarginDivLiquidity3(
        int256 _m,
        int256 _deltaMargin,
        int256 _l,
        int256 _deltaL
    ) internal pure returns (int256) {
        int256 result = 0;

        result = (_m.mul(_m).mul(_m));

        result = result.add(_m.mul(_m).mul(_deltaMargin).mul(3).div(2));

        result = result.add(_m.mul(_deltaMargin).mul(_deltaMargin));

        result = result.add(_deltaMargin.mul(_deltaMargin).mul(_deltaMargin).div(4));

        result = result.mul(1e8).div(_l).div(_l);

        return result.mul(_l.add(_deltaL.div(2))).mul(1e8).div(_l.add(_deltaL)).div(_l.add(_deltaL));
    }

    /**
     * @notice calculate multiple integral of m/L
     * the formula is ((_m + _deltaMargin / 2) / _deltaL) * (log(_l + _deltaL) - log(_l))
     * @param _m required margin
     * @param _deltaMargin difference of required margin
     * @param _l total amount of liquidity
     * @param _deltaL difference of liquidity
     * @return returns result of above formula
     */
    function calculateMarginDivLiquidity(
        int256 _m,
        int256 _deltaMargin,
        int256 _l,
        int256 _deltaL
    ) internal pure returns (int256) {
        if (_deltaL == 0) {
            return (_m.add(_deltaMargin / 2).mul(1e16)).div(_l);
        } else {
            return
                (_m.add(_deltaMargin / 2)).mul(Math.log(_l.add(_deltaL).mul(1e8).div(_l).toUint256())).mul(1e8).div(
                    _deltaL
                );
        }
    }
}

pragma solidity >=0.4.21 <0.9.0;

/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    function arbChainID() external view returns(uint);

    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */ 
    function arbBlockNumber() external view returns (uint);

    /** 
    * @notice Send given amount of Eth to dest from sender.
    * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
    * @param destination recipient address on L1
    * @return unique identifier for this L2-to-L1 transaction.
    */
    function withdrawEth(address destination) external payable returns(uint);

    /** 
    * @notice Send a transaction to L1
    * @param destination recipient address on L1 
    * @param calldataForL1 (optional) calldata for L1 contract call
    * @return a unique identifier for this L2-to-L1 transaction.
    */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns(uint);

    /** 
    * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
    * @param account target account
    * @return the number of transactions issued by the given external account or the account sequence number of the given contract
    */
    function getTransactionCount(address account) external view returns(uint256);

    /**  
    * @notice get the value of target L2 storage slot 
    * This function is only callable from address 0 to prevent contracts from being able to call it
    * @param account target account
    * @param index target index of storage slot 
    * @return stotage value for the given account at the given index
    */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
    * @notice check if current call is coming from l1
    * @return true if the caller of this was called directly from L1
    */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns(address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns(uint);

    event L2ToL1Transaction(address caller, address indexed destination, uint indexed uniqueId,
                            uint indexed batchNumber, uint indexInBatch,
                            uint arbBlockNum, uint ethBlockNum, uint timestamp,
                            uint callvalue, bytes data);
}

//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;
pragma abicoder v2;

import "../PerpetualMarketCore.sol";

/**
 * @title PerpetualMarketCoreTester
 * @notice Tester contract for Perpetual Market Core
 */
contract PerpetualMarketCoreTester is PerpetualMarketCore {
    uint256 public result;

    constructor(address _priceFeedAddress, address _arbSysAddress)
        PerpetualMarketCore(_priceFeedAddress, "TestLPToken", "TestLPToken", _arbSysAddress)
    {}

    function setPoolStatus(
        uint256 _productId,
        int128 _positionPerpetuals,
        uint128 _lastFundingPaymentTime
    ) external {
        pools[_productId].positionPerpetuals = _positionPerpetuals;
        pools[_productId].lastFundingPaymentTime = _lastFundingPaymentTime;
    }

    function setPoolSnapshot(
        int128 _ethPrice,
        int128 _ethVariance,
        uint128 _lastSnapshotTime
    ) external {
        poolSnapshot.ethPrice = _ethPrice;
        poolSnapshot.ethVariance = _ethVariance;
        poolSnapshot.lastSnapshotTime = _lastSnapshotTime;
    }

    function verifyCalculateUnlockedLiquidity(
        uint256 _amountLockedLiquidity,
        int256 _deltaM,
        int256 _hedgePositionValue
    ) external pure returns (int256 deltaLiquidity, int256 unlockLiquidityAmount) {
        return calculateUnlockedLiquidity(_amountLockedLiquidity, _deltaM, _hedgePositionValue);
    }

    function verifyUpdatePoolPositions(uint256 _productId, int256[2] memory _tradeAmounts) external {
        (uint256[2] memory tradePrice, , ) = updatePoolPositions(_tradeAmounts);
        result = tradePrice[_productId];
    }

    function verifyUpdateVariance(uint256 _timestamp) external {
        updateVariance(_timestamp);
    }

    function verifyExecuteFundingPayment(uint256 _productId, int256 _spotPrice) external {
        _executeFundingPayment(_productId, _spotPrice);
    }

    function verifyCalculateResultOfFundingPayment(
        uint256 _productId,
        int256 _spotPrice,
        uint256 _currentTimestamp
    )
        external
        view
        returns (
            int256 currentFundingRate,
            int256 fundingFeePerPosition,
            int256 fundingReceived
        )
    {
        return calculateResultOfFundingPayment(_productId, _spotPrice, _currentTimestamp);
    }

    function verifyGetSignedMarginAmount(uint256 _productId) external view returns (int256) {
        return getSignedMarginAmount(pools[_productId].positionPerpetuals, _productId);
    }

    function verifyCalculateSignedDeltaMargin(
        MarginChange _marginChangeType,
        int256 _deltaMargin,
        int256 _currentMarginAmount
    ) external pure returns (int256) {
        return calculateSignedDeltaMargin(_marginChangeType, _deltaMargin, _currentMarginAmount);
    }

    function verifyCalculateFundingRate(
        uint256 _productId,
        int256 _margin,
        int256 _totalLiquidityAmount,
        int256 _deltaMargin,
        int256 _deltaLiquidity
    ) external view returns (int256) {
        return calculateFundingRate(_productId, _margin, _totalLiquidityAmount, _deltaMargin, _deltaLiquidity);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "../lib/PoolMath.sol";

/**
 * @title PoolMathTester
 * @notice Tester contract for PoolMath library
 */
contract PoolMathTester {
    using SignedSafeMath for int256;

    function verifyCalculateFundingRateFormula(
        int256 _m,
        int256 _deltaMargin,
        int256 _l,
        int256 _deltaL
    ) external pure returns (int256) {
        return PoolMath.calculateFundingRateFormula(_m, _deltaMargin, _l, _deltaL);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "../lib/Math.sol";

/**
 * @title MathTester
 * @notice Tester contract for Math library
 */
contract MathTester {
    function testAddDelta(uint256 _x, int256 _y) external pure returns (uint256) {
        return Math.addDelta(_x, _y);
    }

    function testMulDiv(
        int256 _x,
        int256 _y,
        int256 _d,
        bool _roundUp
    ) external pure returns (int256) {
        return Math.mulDiv(_x, _y, _d, _roundUp);
    }

    function testScale(
        uint256 _a,
        uint256 _from,
        uint256 _to
    ) external pure returns (uint256) {
        return Math.scale(_a, _from, _to);
    }

    function testLog(uint256 _x) external pure returns (int256) {
        return Math.log(_x);
    }

    function testExp(int256 _x) external pure returns (uint256) {
        return Math.exp(_x);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "../lib/EntryPriceMath.sol";

contract EntryPriceMathTester {
    function verifyUpdateEntryPrice(
        int256 _entryPrice,
        int256 _position,
        int256 _tradePrice,
        int256 _positionTrade
    ) external pure returns (int256 newEntryPrice, int256 profit) {
        return EntryPriceMath.updateEntryPrice(_entryPrice, _position, _tradePrice, _positionTrade);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../lib/SpreadLib.sol";

/**
 * @title SpreadLibTester
 * @notice Tester contract for Spread library
 */
contract SpreadLibTester {
    SpreadLib.Info public info;

    function init() external {
        SpreadLib.init(info);
    }

    function getUpdatedPrice(
        SpreadLib.Info memory _info,
        bool _isLong,
        int256 _price,
        uint128 _timestamp
    ) external pure returns (int256 updatedPrice) {
        return SpreadLib.getUpdatedPrice(_info, _isLong, _price, _timestamp);
    }

    function updatePrice(
        bool _isLong,
        int256 _price,
        uint128 _timestamp
    ) external returns (int256 updatedPrice) {
        SpreadLib.Info memory cache = SpreadLib.Info(
            info.blockLastLongTransaction,
            info.minLongTradePrice,
            info.blockLastShortTransaction,
            info.maxShortTradePrice,
            info.safetyBlockPeriod,
            info.numBlocksPerSpreadDecreasing
        );

        updatedPrice = SpreadLib.getUpdatedPrice(cache, _isLong, _price, _timestamp);

        info.blockLastLongTransaction = cache.blockLastLongTransaction;
        info.minLongTradePrice = cache.minLongTradePrice;
        info.blockLastShortTransaction = cache.blockLastShortTransaction;
        info.maxShortTradePrice = cache.maxShortTradePrice;
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../lib/NettingLib.sol";

/**
 * @title NettingLibTester
 * @notice Tester contract for Netting library
 */
contract NettingLibTester {
    NettingLib.Info public info;

    function getInfo() external view returns (NettingLib.Info memory) {
        return info;
    }

    function addMargin(uint256 _productId, NettingLib.AddMarginParams memory _params)
        external
        returns (int256, int256)
    {
        return NettingLib.addMargin(info, _productId, _params);
    }

    function getRequiredTokenAmountsForHedge(
        uint256 _amountUnderlying,
        int256[2] memory _deltas,
        int256 _spotPrice
    ) external pure returns (NettingLib.CompleteParams memory) {
        return NettingLib.getRequiredTokenAmountsForHedge(_amountUnderlying, _deltas, _spotPrice);
    }

    function complete(NettingLib.CompleteParams memory _params) external {
        NettingLib.complete(info, _params);
    }

    function getRequiredMargin(uint256 _productId, NettingLib.AddMarginParams memory _params)
        external
        pure
        returns (int256)
    {
        return NettingLib.getRequiredMargin(_productId, _params);
    }

    function calculateWeightedDelta(
        uint256 _productId,
        int128 _delta0,
        int128 _delta1
    ) external pure returns (int256) {
        return NettingLib.calculateWeightedDelta(_productId, _delta0, _delta1);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../interfaces/IPerpetualMarketCore.sol";
import "../lib/TraderVaultLib.sol";

/**
 * @title TraderVaultLibTester
 * @notice Tester contract for TraderVault library
 */
contract TraderVaultLibTester {
    TraderVaultLib.TraderVault public traderVault;
    int256 public r;

    function clear() external {
        delete traderVault;
    }

    function getNumOfSubVault() external view returns (uint256) {
        return traderVault.subVaults.length;
    }

    function getSubVault(uint256 _subVaultId) external view returns (TraderVaultLib.SubVault memory) {
        return traderVault.subVaults[_subVaultId];
    }

    function verifyUpdateVault(
        uint256 _subVaultId,
        uint256 _productId,
        int128 _amountAsset,
        uint256 _tradePrice,
        int128 _fundingFeePerPosition
    ) external {
        TraderVaultLib.updateVault(
            traderVault,
            _subVaultId,
            _productId,
            _amountAsset,
            _tradePrice,
            _fundingFeePerPosition
        );
    }

    function verifyGetMinCollateralToAddPosition(
        int128[2] memory _tradeAmounts,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) external view returns (int256) {
        return TraderVaultLib.getMinCollateralToAddPosition(traderVault, _tradeAmounts, _tradePriceInfo);
    }

    function verifyUpdateUsdcPosition(int256 _amount, IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo)
        external
    {
        r = TraderVaultLib.updateUsdcPosition(traderVault, _amount, _tradePriceInfo);
    }

    function verifyCheckVaultIsDanger(IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo)
        external
        view
        returns (bool)
    {
        return TraderVaultLib.checkVaultIsDanger(traderVault, _tradePriceInfo);
    }

    function verifyDecreaseLiquidationReward(int256 _minCollateral, int256 liquidationFee) external {
        r = int128(TraderVaultLib.decreaseLiquidationReward(traderVault, _minCollateral, liquidationFee));
    }

    function getMinCollateral(IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo)
        external
        view
        returns (int256)
    {
        return TraderVaultLib.getMinCollateral(traderVault, _tradePriceInfo);
    }

    function getPositionValue(IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo)
        external
        view
        returns (int256)
    {
        return TraderVaultLib.getPositionValue(traderVault, _tradePriceInfo);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "../lib/IndexPricer.sol";

/**
 * @title PricerTester
 * @notice Tester contract for Pricer library
 */
contract PricerTester {
    function verifyCalculatePrice(uint256 _productId, int256 _spotPrice) external pure returns (int256) {
        return IndexPricer.calculateIndexPrice(_productId, _spotPrice);
    }

    function verifyCalculateDelta(uint256 _productId, int256 _spotPrice) external pure returns (int256) {
        return IndexPricer.calculateDelta(_productId, _spotPrice);
    }

    function verifyCalculateGamma(uint256 _productId) external pure returns (int256) {
        return IndexPricer.calculateGamma(_productId);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IFeePool.sol";

contract MockFeePool is ERC20, IFeePool {
    IERC20 public immutable token;

    constructor(ERC20 _token) ERC20("mock staking", "sMOCK") {
        token = _token;
    }

    function sendProfitERC20(address _account, uint256 _amount) external override {
        require(_amount > 0);
        token.transferFrom(_account, address(this), _amount);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
// Original file is
// https://github.com/predyprotocol/contracts/blob/main/contracts/FeePool.sol

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFeePool.sol";

contract FeePool is IFeePool, Ownable {
    IERC20 public immutable token;

    constructor(ERC20 _token) {
        token = _token;
    }

    function withdraw(address _recipient, uint256 _amount) external onlyOwner {
        require(_amount > 0);
        token.transfer(_recipient, _amount);
    }

    function sendProfitERC20(address _account, uint256 _amount) external override {
        require(_amount > 0);
        token.transferFrom(_account, address(this), _amount);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice Mock of ERC20 contract
 */
contract MockERC20 is ERC20 {
    uint8 _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals
    ) ERC20(_name, _symbol) {
        _decimals = __decimals;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}