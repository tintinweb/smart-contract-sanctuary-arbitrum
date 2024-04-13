pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
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
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {LibExchangeHelper, ExchangeInfo, TokenInfo} from "./libraries/LibExchangeHelper.sol";
import {LibDataStore, DataStoreInitParams} from "./libraries/LibDataStore.sol";
import {LibTokenHelper} from "./libraries/LibTokenHelper.sol";

contract BotManager {

    function addExchange (ExchangeInfo memory  exchangeParams) external {
        LibExchangeHelper.addExchange(exchangeParams);
    }
    function addToken (address token) external {
        LibTokenHelper.addToken(token);
    }
    function getToken (uint id) external view returns(TokenInfo memory token) {
        token = LibTokenHelper.getToken (id);
    }
    function getTokens (uint[] memory ids) external view returns (TokenInfo[] memory tokens) {
        uint i;
        uint len = ids.length;

        tokens = new TokenInfo[](len);

        for (i; i < len; i++) {
            tokens[i] = LibTokenHelper.getToken(i);
        }
    }

    function getExchange (uint _id) external view returns (ExchangeInfo memory exchange) {
        exchange = LibExchangeHelper.getExchange(_id);
    }
    function getExchanges (uint[] memory _ids) external view returns (ExchangeInfo[] memory exchanges) {
        uint len = _ids.length;
        uint i;
        exchanges = new ExchangeInfo[](len);
        for (i; i < len; i++) {
            exchanges[i] = LibExchangeHelper.getExchange(i);
        }
    }
    function getAllExchanges () external view returns (ExchangeInfo[] memory exchanges) {
        uint len = LibExchangeHelper.getExchangesCount();
        uint i;
        exchanges = new ExchangeInfo[](len);
        for (i; i < len; i++) {
            exchanges[i] = LibExchangeHelper.getExchange(i);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {IMulticall3} from "../shared/interfaces/IMulticall3.sol";
import {LibExecutor, ExecutionType, ExecutionParams, ExecutorInitParams, FlashProvider} from "./libraries/LibExecutor.sol";
import {LibExchangeHelper, ExchangeInfo, TokenInfo} from "./libraries/LibExchangeHelper.sol";
import {IWETH} from "../shared/interfaces/IWETH.sol";
import {Treasury} from "./Treasury.sol";

contract Executor {
    IMulticall3 immutable multicall3;
    IWETH immutable WETH;

    constructor (ExecutorInitParams memory params) payable {
        multicall3 = IMulticall3(params.multicall3);
        WETH = IWETH(params.weth);
    }
    function processExecutions (ExecutionParams[] memory executions) external {
        LibExecutor.processExecutions(executions);
    }
    function setWETH (address _weth) internal {
        LibExecutor.setWETH(_weth);
    }
    function addFlashProvider (FlashProvider memory _provider) external {
        LibExecutor.addFlashProvider(_provider);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {LibDataStore, DataStoreInitParams} from "./libraries/LibDataStore.sol";

contract Factory {
    function initializeBotManager (DataStoreInitParams memory params) external {
        LibDataStore.initialize(params);
    }
    function getExecutor () external view returns(address executor) {
        executor = address(LibDataStore.getExecutor());
    }
    function getBotManager () external view returns(address botManager) {
        botManager = address(LibDataStore.getBotManager());
    }
    function getTreasury () external view returns(address treasury) {
        treasury = address(LibDataStore.getTreasury());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import { BotManager } from "../BotManager.sol";
import { Executor, ExecutorInitParams } from "../Executor.sol";
import { Treasury } from "../Treasury.sol";

error ZeroAddress();
error SameManager();
error AlreadyInitialized();

enum ValueType { UINT8, UINT16, UINT32, UINT64, UINT28, UINT256, STRING, BYTES, BYTES32 }

struct DataStoreStorage {
    string VERSION;
    BotManager botManager;
    Executor executor;
    Treasury treasury;
}
struct KeyVakue {
    string key;
    ValueType valType;
    bytes val;
}
struct DataStoreInitParams {
    address botManager;
    address executor;
    ExecutorInitParams executorParams;
    address treasury;
}

library LibDataStore {
    bytes32 constant DATA_STORE_STORAGE_POSITION = keccak256("fraktal.protocol.data.store.storage");

    function diamondStorage () internal pure returns(DataStoreStorage storage ds) {
        bytes32 position = DATA_STORE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function initialize (DataStoreInitParams memory params) internal {
        DataStoreStorage storage ds = diamondStorage();

        if (initialized()) revert AlreadyInitialized();

        if (address(params.botManager) == address(0)) ds.botManager = new BotManager();
        else setBotManager(params.botManager);

        if (address(params.executor) == address(0)) ds.executor = new Executor(params.executorParams);
        else setExecutor(params.executor);

        if (address(params.treasury) == address(0)) ds.treasury = new Treasury();
        else setExecutor(params.treasury);

    }



    function initialized () internal view returns(bool isInit) {
        if (hasBotManager()) isInit = true;
        if (hasExecutor()) isInit = true;
    }
    function hasBotManager () internal view returns(bool hasIt) {
        DataStoreStorage storage ds = diamondStorage();

        if (address(ds.botManager) == address(0)) return hasIt;
        hasIt = true;
    }
    function getBotmanager () internal view returns (BotManager botManager) {
        return diamondStorage().botManager;
    }
    function setBotManager (address botManager) internal {
        DataStoreStorage storage ds = diamondStorage();
        if (botManager == address(0)) revert ZeroAddress();
        if (botManager == address(ds.botManager)) revert SameManager();
        ds.botManager = BotManager(botManager);
    }
    function hasExecutor () internal view returns(bool hasIt) {
        DataStoreStorage storage ds = diamondStorage();
    
        if (address(ds.executor) == address(0)) return hasIt;
        hasIt = true;
    }
    function getExecutor () internal view returns (Executor executor) {
        executor = diamondStorage().executor;
    }

    function getBotManager () internal view returns(BotManager botManager) {
        botManager = diamondStorage().botManager;
    }
    function getTreasury () internal view returns(Treasury treasury) {
        treasury = diamondStorage().treasury;
    }
    function setExecutor (address executor) internal {
        DataStoreStorage storage ds = diamondStorage();
        if ((executor) == address(0)) revert ZeroAddress();
        if (executor == address(ds.executor)) revert SameManager();
        ds.executor = Executor(executor);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {LibUniswapV2Helper, LibUniswapV3Helper, UniswapV2SwapParams, UniswapV3SwapParams} from "./LibUniswapHelper.sol";
import {TokenInfo, LibTokenHelper } from "./LibTokenHelper.sol";

error ExchangeAlreadyAdded(ExchangeInfo exchange);
error ExchangePoolAlreadyAdded();
error ExchangeNotYetImplemented();

enum ExchangeType {
    UNISWAP_V2, UNISWAP_V3, BALANCER_V2
}

enum ExchangePoolType {
    UNISWAP_V2_PAIR,
    UNISWAP_V3_POOL,
    BALANCER_V2_POOL
}
struct ExchangePool {
    address pool;
    uint exchangeId;
    uint token0;
    uint token1;
    uint24 fee;
    ExchangePoolType poolType;
}

struct SwapParams {
    address recipient;
    uint exchangeId;
    uint tokenIn;
    uint tokenOut;
    uint amountIn;
    uint amountOut;
    uint24 fee;
    bool isExactIn;
    bytes extra;
}
struct ExchangeInfo {
    string name;
    ExchangeType exchangeType;
    address router;
    address factory;
}
struct ExchangeHelperStrorage {
    mapping(uint => ExchangeInfo) exchanges;
    uint exchangesCount;

    mapping(uint => ExchangePool) exchangePools;
    uint exchangePoolsCount;


}

library LibExchangeHelper {
    bytes32 constant EXECUTOR_STORAGE_POSITION = keccak256("fraktal.protocol.exchange.helper.storage");
    function diamondStorage () internal pure returns(ExchangeHelperStrorage storage ds) {
        bytes32 position = EXECUTOR_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }

    }


    function getExchange (uint _id) internal view returns (ExchangeInfo memory exchange) {
        if (_id > diamondStorage().exchangesCount) return exchange;
        exchange = diamondStorage().exchanges[_id];
    }
    function getExchange (address routerOrFactory) internal view returns (ExchangeInfo memory exchange) {
        exchange = diamondStorage().exchanges[getExchangeId(routerOrFactory)];
    }
    function hasExchange (address routerOrFactory) internal view returns(bool hasIt) {
        uint i;
        uint len = diamondStorage().exchangesCount;
        if (len == 0) return hasIt;

        for (i; i < len; i++) {
            if (
                address(diamondStorage().exchanges[i].router) == routerOrFactory ||
                address(diamondStorage().exchanges[i].factory) == routerOrFactory
            ) {
            return hasIt = true;
            }
        }       
    }
    function getExchangeId (address routerOrFactory) internal view returns (uint _id) {
        uint i;
        uint len = diamondStorage().exchangesCount;

        for (i; i < len; i++) {
            if (
                address(diamondStorage().exchanges[i].router) == routerOrFactory ||
                address(diamondStorage().exchanges[i].factory) == routerOrFactory
            ) {
                _id = i;
                return _id;
            }
        }

    }
    function addExchange (ExchangeInfo memory _exchange) internal {
        if (hasExchange(_exchange.router) || hasExchange(_exchange.factory)) revert ExchangeAlreadyAdded(_exchange);
        ExchangeInfo storage exchange = diamondStorage().exchanges[diamondStorage().exchangesCount];

        exchange.name = _exchange.name;
        exchange.exchangeType = _exchange.exchangeType;
        exchange.router = _exchange.router;
        exchange.factory = _exchange.factory;

        diamondStorage().exchangesCount++;
    }
    function updateExchange (uint _id, ExchangeInfo memory _exchange) internal {
        if (hasExchange(_exchange.router) || hasExchange(_exchange.factory)) {
            ExchangeInfo storage exchange = diamondStorage().exchanges[_id];

            exchange.name = _exchange.name;
            exchange.exchangeType = _exchange.exchangeType;
            exchange.router = _exchange.router;
            exchange.factory = _exchange.factory;
        } else {
            addExchange(_exchange);
        }
    }

    function hasExchangePool (address poolAddress) internal view returns(bool hasIt) {
        uint i;
        uint len = diamondStorage().exchangePoolsCount;
        for (i; i < len; i++) {
            if (diamondStorage().exchangePools[i].pool == poolAddress) return hasIt = true;
        }
    }
    function getExchangePool (uint _id) internal view returns (ExchangePool memory pool) {
        pool = diamondStorage().exchangePools[_id];
    }
        
    
    function getExchangePool (address poolAddress) internal view returns (ExchangePool memory pool) {
        pool = getExchangePool(getExchangePoolId(poolAddress));
    }

    function getExchangePoolId (address poolAddress) internal view returns(uint _id) {
                uint i;
        uint len = diamondStorage().exchangePoolsCount;
        for (i; i < len; i++) {
            if (diamondStorage().exchangePools[i].pool == poolAddress) return _id = i;
        }
    }
    function addExchangePool (ExchangePool memory pool) internal {
        ExchangeHelperStrorage storage ds = diamondStorage();
        if (hasExchangePool(pool.pool)) revert ExchangePoolAlreadyAdded();
        ds.exchangePools[ds.exchangePoolsCount] = pool;
        ds.exchangePoolsCount++;
    }
    function getExchangesCount () internal view returns (uint count) {
        count = diamondStorage().exchangesCount;
    }

    function swap (SwapParams memory params) internal returns (uint amount) {

        ExchangeInfo memory exchange = getExchange(params.exchangeId);
        // IUniswapV2Router02 router = IUniswapV2Router02(rouer);
        if (exchange.exchangeType == ExchangeType.UNISWAP_V2) {
            UniswapV2SwapParams memory swapParams = UniswapV2SwapParams({
                router: exchange.router,
                recipient: params.recipient,
                tokenIn: LibTokenHelper.getToken(params.tokenIn).token,
                tokenOut: LibTokenHelper.getToken(params.tokenOut).token,
                amountIn: params.amountIn,
                amountOut: params.amountOut,
                isExactIn: params.isExactIn
            });
            return LibUniswapV2Helper.swap(swapParams);
        } else if (exchange.exchangeType == ExchangeType.UNISWAP_V3) {
            UniswapV3SwapParams memory swapParams = UniswapV3SwapParams({
                router: exchange.router,
                recipient: params.recipient,
                tokenIn: LibTokenHelper.getToken(params.tokenIn).token,
                tokenOut: LibTokenHelper.getToken(params.tokenOut).token,
                amountIn: params.amountIn,
                amountOut: params.amountOut,
                isExactIn: params.isExactIn,
                fee: params.fee
            });

            return LibUniswapV3Helper.swap(swapParams);
        } else if (exchange.exchangeType == ExchangeType.BALANCER_V2) {
            revert ExchangeNotYetImplemented();
        }
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {LibExchangeHelper, SwapParams} from "./LibExchangeHelper.sol";
import {IMulticall3, Call3Value} from "../../shared/interfaces/IMulticall3.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {IWETH} from "../../shared/interfaces/IWETH.sol";

event SetWETH (address weth);
event AddedFlashProvider(FlashProvider _provider);

error SameMulticall3(address mc3);
error InsuffientEthSendAmount(address account, uint value);
error SameWETH();

enum ExecutionType {
    SEND_ETH,
    UNWRAP_ETH,
    WRAP_ETH,
    LIQUIDIDATION,
    SWAP,
    ADD_LIQUIDITY,
    REMOVE_LIQUIDITY,
    LEND,
    BORROW,
    REPAY_LOAN,
    STAKE,
    UNSTAKE,
    REDEEM,
    MINT,
    BURN
}
struct ExecutorInitParams {
    address multicall3;
    address weth;
}
enum FlashProviderType {
    AAVE_V2_SIMPLE, AAVE_V3_COMPLEX, UNISWAV_V2, UNISWAP_V3
}
struct WETHParams {
    uint amount;
}
struct ExecutionParams {
    ExecutionType executionType;
    uint value;
    bytes data;
    // address target;
}
struct FlashProvider {
    string name;
    address provider;
    FlashProviderType providerType;
}

struct ExecutorStorage {
    IMulticall3 multicall3;
    mapping(address => bool) executor;
    
    mapping(uint => FlashProvider) flashProviders;
    uint flashProvidersCount;

    IWETH WETH;
}


library LibExecutor {
    bytes32 constant EXECUTOR_STORAGE_POSITION = keccak256("fraktal.protocol.executor.storage");
    function diamondStorage () internal pure returns(ExecutorStorage storage ds) {
        bytes32 position = EXECUTOR_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }

    }
    function setMulticall3 (address _multicall3) internal {
        if (_multicall3 == address(diamondStorage().multicall3)) revert SameMulticall3(_multicall3);
        diamondStorage().multicall3 = IMulticall3(_multicall3);
    }
    function getFlashProvider (uint _id) internal view returns (FlashProvider memory provider) {
        provider = diamondStorage().flashProviders[_id];
    }
    function getFlashProvider (address _provider) internal view returns (FlashProvider memory provider) {
        provider = diamondStorage().flashProviders[getFlasHProviderId(_provider)];
    }

    function getFlasHProviderId (address _provider) internal view returns (uint _id) {
        uint i;
        uint len = diamondStorage().flashProvidersCount;
        for (i; i < len; i++) {
            if (diamondStorage().flashProviders[i].provider == _provider) return _id = i;
        }
    }
    function hasFlasHProvider (address _provider) internal view returns (bool hasIt) {
        uint i;
        uint len = diamondStorage().flashProvidersCount;
        for (i; i < len; i++) {
            if (diamondStorage().flashProviders[i].provider == _provider) return hasIt = true;
        }
    }

    function addFlashProvider (FlashProvider memory _provider) internal {

        FlashProvider storage provider = diamondStorage().flashProviders[diamondStorage().flashProvidersCount];

        provider.name = _provider.name;
        provider.provider = _provider.provider;
        provider.providerType = _provider.providerType;

        diamondStorage().flashProvidersCount++;
        emit AddedFlashProvider(_provider);
    }
    
    function execute (ExecutionParams memory exec) internal {
        // ExecutorStorage storage ds = diamondStorage();

        if (exec.executionType == ExecutionType.SEND_ETH) {
            (address target, uint amount) = abi.decode(exec.data, (address, uint));
            if (address(this).balance < exec.value) revert InsuffientEthSendAmount(LibMeta.msgSender(), exec.value);
            (bool success, ) = target.call{value: amount}("");
            
        }
        else if (exec.executionType == ExecutionType.WRAP_ETH) {
            (WETHParams memory wethParams) = abi.decode(exec.data, (WETHParams));
                diamondStorage().WETH.withdraw(wethParams.amount);
            
        }
        else if (exec.executionType == ExecutionType.UNWRAP_ETH) {
            (WETHParams memory wethParams) = abi.decode(exec.data, (WETHParams));
            diamondStorage().WETH.deposit{value: wethParams.amount}();
            
        }
        else if (exec.executionType == ExecutionType.SWAP) {
            (SwapParams memory swapParams) = abi.decode(exec.data, (SwapParams));
            LibExchangeHelper.swap(swapParams);
            
        }
        else {
            (Call3Value[] memory calls) = abi.decode(exec.data, (Call3Value[]));
            getMulticall3().aggregate3Value(calls);
        }
    }
    function getMulticall3 () internal view returns(IMulticall3 multicall3) {
        multicall3 = diamondStorage().multicall3;
    }
    function processExecutions (ExecutionParams[] memory executions) internal {

        uint i;
        uint len = executions.length;

        for (i; i < len; i++) {
            ExecutionParams memory exec = executions[i];
            execute(exec);            
        }
    }
    function setWETH (address _weth) internal {
        if (address(diamondStorage().WETH) == _weth) revert SameWETH();
        diamondStorage().WETH = IWETH(_weth);
        emit SetWETH(_weth);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {IERC20, IERC20Meta} from "../../shared/interfaces/IERC20.sol";

struct TokenInfo {
    string symbol;
    uint8 decimals;
    address token;
}

struct TokenStorage {
    mapping(uint => TokenInfo) tokens;
    uint tokensCount;
}

library LibTokenHelper {
    bytes32 constant EXECUTOR_STORAGE_POSITION = keccak256("fraktal.protocol.token.helper.storage");
    function diamondStorage () internal pure returns(TokenStorage storage ds) {
        bytes32 position = EXECUTOR_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }

    }    
    function hasToken (address _token) internal view returns (bool hasIt) {
        uint i;
        uint len = diamondStorage().tokensCount;
        if (len == 0) return hasIt;

        for (i; i < len; i++) {
            if (diamondStorage().tokens[i].token == _token) return hasIt = true;
        }
    }
    function getTokenId (address _token) internal view returns (uint _id) {
        uint i;
        uint len = diamondStorage().tokensCount;
        for (i; i < len; i++) {
            if (diamondStorage().tokens[i].token == _token) return _id = i;
        }
    }

    function getToken (uint _id) internal view returns (TokenInfo memory token) {
        token = diamondStorage().tokens[_id];
    }

    function getToken (address _token) internal view returns (TokenInfo memory token) {
        token = getToken(getTokenId(_token));
    }

    function addToken (address _token) internal {
        TokenInfo memory token = diamondStorage().tokens[diamondStorage().tokensCount];

        token.token = _token;
        token.symbol = IERC20Meta(_token).symbol();
        token.decimals = IERC20Meta(_token).decimals();

        diamondStorage().tokensCount++;
    }
}

// SPDX-License-Identifier: FRAKTAL-PROTOCOL
pragma solidity 0.8.24;
pragma abicoder v2;

import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {IERC20} from "../../shared/interfaces/IERC20.sol";


struct ReserveInfo {
    uint reserve0;
    uint reserve1;
    uint ts;
}

struct UniswapV2SwapParams {
    address router;
    address recipient;
    address tokenIn;
    address tokenOut;
    uint amountIn;
    uint amountOut;
    bool isExactIn;
}
struct UniswapV3SwapParams {
    address router;
    address recipient;
    address tokenIn;
    address tokenOut;
    uint amountIn;
    uint amountOut;
    bool isExactIn;
    uint24 fee;
}
struct UniswapV2LiquidityParams {
    address router;
    address recipient;
    address token0;
    address token1;
    uint amount0;
    uint amount1;
    bool add;
}
struct UniswapV3LiquidityParams {
    address router;
    address recipient;
    address token0;
    address token1;
    uint amount0;
    uint amount1;
    bool add;
    uint24 fee;
}
struct UniswapV2PairInfo {
    IUniswapV2Pair pair;
    address factory;
    address token0;
    address token1;
    uint112 reserve0;
    uint112 reserve1;
}

library LibUniswapV2Helper {
    function getPairAddress (address _factory, address _token0, address _token1) internal view returns(address pairAddress) {
        IUniswapV2Factory factory = IUniswapV2Factory(_factory);
        pairAddress = factory.getPair(_token0, _token1);
    }
    function getPair (address pairAddress) internal pure returns(IUniswapV2Pair pair) {
        pair = IUniswapV2Pair(pairAddress);
    }
    function getPair (address _factory, address _token0, address _token1) internal  view returns(IUniswapV2Pair pair) {
        pair = IUniswapV2Pair(getPairAddress(_factory, _token0, _token1));
    }
    function getReserves (address _factory, address _token0, address _token1)  internal view returns(ReserveInfo memory reserves) {
        reserves = getReserves(getPairAddress(_factory, _token0, _token1));
    }
    function getReserves (address pairAddress) internal view returns(ReserveInfo memory reserves) {
        IUniswapV2Pair pair = getPair(pairAddress);
        (uint112 reserve0, uint112 reserve1, uint ts) = pair.getReserves();
        reserves.reserve0 = reserve0;
        reserves.reserve1 = reserve1;
        reserves.ts = ts;
    }
        // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = reserveOut - amountOut * 997;
        amountIn = (numerator / denominator) + 1;
    }
    function getPairInfo (address _factory, address _token0, address _token1) internal view returns(UniswapV2PairInfo memory info) {
        IUniswapV2Pair pair = getPair(_factory, _token0, _token1);
        info.pair = pair;
        info.factory = _factory;
        info.token0 = pair.token0();
        info.token1 = pair.token1();
        (uint112 reserve0, uint112 reserve1, uint ts) = pair.getReserves();
        info.reserve0 = reserve0;
        info.reserve1 = reserve1;
    }
    function hasArbitrage (
        address _factory0,
        address _factory1,
        address _token0,
        address _token1,
        uint _amountIn,
        address tokenBowwow
    ) internal view returns (bool hasArb) {
        // get info an price for pair0

        UniswapV2PairInfo memory info0 = getPairInfo(_factory0, _token0, _token1);
        UniswapV2PairInfo memory info1 = getPairInfo(_factory1, _token0, _token1);

        uint reserveIn;
        uint reserveOut;
        address tokenIn;
        address tokenOut;

        if (tokenBowwow == tokenIn) {
            reserveIn = info0.reserve0;
            reserveOut = info0.reserve1;
            tokenIn = info0.token0;
            tokenOut = info0.token1;
        } else {
            reserveOut = info0.reserve0;
            reserveIn = info0.reserve1;
            tokenIn = info0.token1;
            tokenOut = info0.token0;
        }

        uint amountInArb = getAmountOut(_amountIn, reserveIn, reserveOut);

        if (tokenBowwow == tokenIn) {
            reserveIn = info1.reserve0;
            reserveOut = info1.reserve1;
            tokenIn = info1.token0;
            tokenOut = info1.token1;
        } else {
            reserveOut = info1.reserve0;
            reserveIn = info1.reserve1;
            tokenIn = info1.token1;
            tokenOut = info1.token0;
        }
       
        uint amountOut = getAmountOut(amountInArb, reserveIn, reserveOut);
        hasArb = _amountIn < amountOut;
    }

    function swap (UniswapV2SwapParams memory params) internal returns(uint amountOut) {

    //    if (params.in) params.router.swapExactTokensForTokens()
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        IERC20(params.tokenIn).approve(address(params.router), params.amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = params.tokenIn;
        path[1] = params.tokenOut;

        uint256[] memory amounts;
        if (params.isExactIn) {
           amounts = IUniswapV2Router02(params.router).swapExactTokensForTokens(
                params.amountIn,
                params.amountOut,
                path,
                params.recipient,
                block.timestamp
            );

        } else {
            amounts = IUniswapV2Router02(params.router).swapExactTokensForTokens(
                params.amountOut, params.amountIn, path, params.recipient, block.timestamp
            );
        }

        // amounts[0] = WETH amount, amounts[1] = DAI amount
        return amounts[1];

    }
    // function liquidity (UniswapV2LiquidityParams memory params) internal returns (uint[] amounts) {
    //     if (params.)
    // }


}

library LibUniswapV3Helper {
    function getPoolAddress (address _factory, address _token0, address _token1, uint24 _fee) internal view returns(address poolAddress) {
        IUniswapV3Factory factory = IUniswapV3Factory(_factory);
        poolAddress = factory.getPool(_token0, _token1, _fee);
    }
    function getPool (address poolAddress) internal pure returns (IUniswapV3Pool pool) {
        pool = IUniswapV3Pool(poolAddress);
    }

    function getPool (address _factory, address _token0, address _token1, uint24 _fee) internal view returns(IUniswapV3Pool pool) {
        IUniswapV3Factory factory = IUniswapV3Factory(_factory);
        pool = IUniswapV3Pool(getPoolAddress(_factory, _token0, _token1, _fee));
    }
    function swap (UniswapV3SwapParams memory params) internal returns(uint amountOut) {
        if (params.isExactIn) {
            ISwapRouter.ExactInputSingleParams memory v3SwapParams = ISwapRouter.ExactInputSingleParams({
                    tokenIn: params.tokenIn,
                    tokenOut: params.tokenOut,
                    fee: params.fee,
                    recipient: params.recipient,
                    deadline: block.timestamp + 120,
                    amountIn: params.amountIn,
                    amountOutMinimum: params.amountOut,
                    sqrtPriceLimitX96: 0
            });
            ISwapRouter(params.router).exactInputSingle(v3SwapParams);
        } else {
            ISwapRouter.ExactOutputSingleParams memory v3SwapParams = ISwapRouter.ExactOutputSingleParams ({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: params.fee,
                recipient: params.recipient,
                deadline: block.timestamp + 120,
                amountOut: params.amountOut,
                amountInMaximum: params.amountIn,
                sqrtPriceLimitX96: 0
            });
            ISwapRouter(params.router).exactOutputSingle(v3SwapParams);
        }
    }
    function getPrice (bool zFor1, int8 dx, int8 dy, uint160 sqrtPriceX96, uint256 amount) internal view returns (uint price, uint8 decimals) {
        // uint8 decimals = (zFor1) ? dy - dx : dx - dy
        // uint Q96 = 2 ** 96;

        // uint P = (sqrtPriceX96 / Q96) ** 2;

        // uint ETH = 
    }
    // function addLiquidity () internal returns (uint[] amounts) {
        
    // }
    // function reoveLiquidity () internal returns (uint[] amounts) {
        
    // }
}

library LibUniswapHelper {
    function swap () internal {

    }
    // function addLiquidity () internal {

    // }
    // function removeLiquidity () internal {

    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
pragma abicoder v2;

import {LibMeta } from "../shared/libraries/LibMeta.sol";
import {IERC20} from "../shared/interfaces/IERC20.sol";

struct TreasuryStorage {
    address manager;
    mapping(address => mapping(address => uint)) balances;
}

event TreasuryDeposited(address indexed account, address indexed token, uint amount);
event TreasuryWithdrawn(address indexed account, address indexed token, uint amount);

error LowTokenBalance(address to, address token);
error TrasnferFailed(address to, address token, uint amount);
error WithdarwalFailure(address to, address token, uint amount);

struct ExecutionParams {
    address to;
    uint value;
    bytes data;
}
struct ExecutionReturn {
    bool success;
    bytes data;
}

library LibTreasury {
    bytes32 constant STORAGE_POTISION = keccak256("fraktal.protocol.treasury.storage");

    function diamondStorage () internal pure returns (TreasuryStorage storage ds) {
        bytes32 position = STORAGE_POTISION;
        assembly {
            ds.slot := position
        }
    }
    function isManager (address account) internal view returns(bool isM) {
        return diamondStorage().manager == account;
    }
    function isManager () internal view returns (bool isM) {
        isM = isManager(LibMeta.msgSender());
    }
    function deposit (address to, address token, uint amount) internal {
        TreasuryStorage storage ds = diamondStorage();
        if (IERC20(token).balanceOf(to) < amount) revert LowTokenBalance(to, address(token));

        ds.balances[to][token] += amount;
        if (!IERC20(token).transferFrom(to, address(this), amount)) revert TrasnferFailed(to, address(token), amount);

        emit TreasuryDeposited(to, token, amount);
    }
    function withdraw (address to, address token, uint amount) internal {
        TreasuryStorage storage ds = diamondStorage();
        if (ds.balances[to][token] < amount) revert WithdarwalFailure(to, token, amount);
        emit TreasuryWithdrawn(to, token, amount);

    }
    function execute (ExecutionParams memory params) internal returns(ExecutionReturn memory returnData) {
        (returnData.success, returnData.data) = params.to.call{value: params.value}(params.data);
    }
    function execute (ExecutionParams[] memory params) internal returns(ExecutionReturn[] memory returnData) {
        uint len = params.length;
        uint i;

        returnData = new ExecutionReturn[](len);

        for (i; i < len; i++) {
            (returnData[i].success, returnData[i].data) = params[i].to.call{value: params[i].value}(params[i].data);
        }
    }

}
contract Treasury {
    address payable immutable deployer;
    constructor () payable {
        deployer = payable(LibMeta.msgSender());
    }
    receive () external payable {
        if (msg.value > 0) LibTreasury.deposit(LibMeta.msgSender(), address(0), msg.value);
    }
    function deposit (address to, address token, uint amount) external {
        LibTreasury.deposit(to, token, amount);
    }
    function deposit (address token, uint amount) external {
        address to = address(0);
        LibTreasury.deposit(to, token, amount);
    }
    function deposit (uint amount) external {
        address to = address(0);
        address token = address(0);
        LibTreasury.deposit(to, token, amount);
    }
    function withdraw (address to, address token, uint amount) internal {
        LibTreasury.withdraw(to, token, amount);
    }
    function withdraw ( address token, uint amount) internal {
        address to = address(0);
        LibTreasury.withdraw(to, token, amount);
    }
    function withdraw (uint amount) internal {
        address to = address(0);
        address token = address(0);
        LibTreasury.withdraw(to, token, amount);
    }
    function execute (ExecutionParams memory params) internal returns(ExecutionReturn memory returnData) {
        returnData = LibTreasury.execute (params);
    }
    function execute (ExecutionParams[] memory params) internal returns(ExecutionReturn[] memory returnData) {
        returnData = LibTreasury.execute (params);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20Events {
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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20BaseModifiers {
    // modifier onlyMinter() {}
    // modifier onlyBurner() {}
    function _isERC20BaseInitialized() external view returns (bool);
}

interface IERC20Meta {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals () external view returns (uint8);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Multicall3
/// @notice Aggregate results from multiple function calls
/// @dev Multicall & Multicall2 backwards-compatible
/// @dev Aggregate methods are marked `payable` to save 24 gas per call
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>
/// @author Andreas Bigger <[email protected]>
/// @author Matt Solomon <[email protected]>
struct Call {
    address target;
    bytes callData;
}

struct Call3 {
    address target;
    bool allowFailure;
    bytes callData;
}

struct Call3Value {
    address target;
    bool allowFailure;
    uint256 value;
    bytes callData;
}

struct Result {
    bool success;
    bytes returnData;
}
interface IMulticall3 {
    function aggregate(Call[] calldata calls) external payable returns (uint256 blockNumber, bytes[] memory returnData);
    function tryAggregate(bool requireSuccess, Call[] calldata calls) external payable returns (Result[] memory returnData);
    function tryBlockAndAggregate(bool requireSuccess, Call[] calldata calls) external payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);
    function blockAndAggregate(Call[] calldata calls) external payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);
    function aggregate3(Call3[] calldata calls) external payable returns (Result[] memory returnData);
    function aggregate3Value(Call3Value[] calldata calls) external payable returns (Result[] memory returnData);
    function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash);
    function getBlockNumber() external view returns (uint256 blockNumber);
    function getCurrentBlockCoinbase() external view returns (address coinbase);
    function getCurrentBlockDifficulty() external view returns (uint256 difficulty);
    function getCurrentBlockGasLimit() external view returns (uint256 gaslimit);
    function getCurrentBlockTimestamp() external view returns (uint256 timestamp);
    function getEthBalance(address addr) external view returns (uint256 balance);
    function getLastBlockHash() external view returns (bytes32 blockHash);
    function getBasefee() external view returns (uint256 basefee);
    function getChainId() external view returns (uint256 chainid);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import { IERC20 } from './IERC20.sol';

interface IWETH is IERC20 {
  function deposit() external payable;
  function transfer(address to, uint256 value) external returns (bool);
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: COPPER-PROTOCOL
pragma solidity 0.8.24;

library LibMeta {
    // EIP712 domain type hash
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)");

    // /**
    //  * @dev Generates the domain separator for EIP712 signatures.
    //  * @param name The name of the contract.
    //  * @param version The version of the contract.
    //  * @return The generated domain separator.
    //  */
    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        // Generate the domain separator hash using EIP712_DOMAIN_TYPEHASH and contract-specific information
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    // /**
    //  * @dev Gets the current chain ID.
    //  * @return The chain ID.
    //  */
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    // /**
    //  * @dev Gets the actual sender of the message.
    //  * @return The actual sender of the message.
    //  */
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}