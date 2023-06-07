// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
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
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
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
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../token/MintableToken.sol";

contract ALP is MintableToken {
    constructor() public MintableToken("ACY LP", "ALP", 0) {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';
import './SymbolsLens.sol';
import '../token/IERC20.sol';
import '../vault/IVault.sol';

contract DeriLens is NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;

    ISymbolsLens immutable symbolsLens;

    constructor (address symbolsLens_) NameVersion('DeriLens', '3.0.2') {
        symbolsLens = ISymbolsLens(symbolsLens_);
    }

    struct PoolInfo {
        address pool;
        address implementation;
        address protocolFeeCollector;

        address tokenB0;
        address tokenWETH;
        address vTokenB0;
        address vTokenETH;
        address lToken;
        address pToken;
        address oracleManager;
        address swapper;
        address symbolManager;
        uint256 reserveRatioB0;
        int256 minRatioB0;
        int256 poolInitialMarginMultiplier;
        int256 protocolFeeCollectRatio;
        int256 minLiquidationReward;
        int256 maxLiquidationReward;
        int256 liquidationRewardCutRatio;

        int256 liquidity;
        int256 lpsPnl;
        int256 cumulativePnlPerLiquidity;
        int256 protocolFeeAccrued;

        address symbolManagerImplementation;
        int256 initialMarginRequired;
        uint256 totalSupply;
    }

    struct MarketInfo {
        address underlying;
        address vToken;
        string underlyingSymbol;
        string vTokenSymbol;
        uint256 underlyingPrice;
        uint256 exchangeRate;
        uint256 vTokenBalance;
    }

    struct TokenInfo {
        address token;
        uint256 price;
        uint256 balance;
        string symbol;
    }

    struct LpInfo {
        address account;
        uint256 lTokenId;
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
        uint256 vaultLiquidity;
        // MarketInfo[] markets;
    }

    struct PositionInfo {
        address symbolAddress;
        string symbol;
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
        int256 margin;
        int256 marginUsed;
        uint256 vaultLiquidity;
        address vault;
        int256 leverage;
        int256 liquidationPrice;
    }

    struct TdInfo {
        address account;
        uint256 pTokenId;
        int256 amountB0;
        // MarketInfo[] markets;
        PositionInfo[] positions;
    }

    struct TradeData {
        int256 tradeVolume;
        int256 K;
        int256 tradeCost;
        int256 tradeFee;
        int256 cumulativeFundingPerVolume;
        int256 diff;
        int256 traderFunding;
        int256 tradeRealizedCost;
        int256 cost;
        int256 traderPnl;
        int256 amountB0;
        int256 traderMargin;
        int256 marginA;
        int256 volumeA;
    }

    struct TradeInfo {
        int256 vaultLiquidity;
        int256 amountB0;
        int256 funding;
        int256 cost;
        int256 volume;
        int256 feeRatio;
        int256 maxLeverage;
        int256 cumulativeFundingPerVolume;
        int256 diff;
        int256 marginUsed;
        int256 availableMargin;
        int256 maxVolume;
        int256 curIndexPrice;
        int256 marginRequiredRatio;
    }

    function getInfo(address pool_, address account_, ISymbolsLens.PriceAndVolatility[] memory pvs) external view returns (
        PoolInfo memory poolInfo,
        // MarketInfo[] memory marketsInfo,
        ISymbolsLens.SymbolInfo[] memory symbolsInfo,
        TdInfo memory tdInfo,
        TokenInfo[] memory tokenInfo
    ) {
        poolInfo = getPoolInfo(pool_);
        // marketsInfo = getMarketsInfo(pool_);
        symbolsInfo = getSymbolsInfo(pool_, pvs);
        // lpInfo = getLpInfo(pool_, account_);
        tdInfo = getTdInfo(pool_, account_);
        tokenInfo = getTokenInfo(pool_, account_);
    }

    function getPoolInfo(address pool_) public view returns (PoolInfo memory info) {
        ILensPool p = ILensPool(pool_);
        info.pool = pool_;
        info.implementation = p.implementation();
        info.protocolFeeCollector = p.protocolFeeCollector();
        info.tokenB0 = p.tokenB0();
        info.tokenWETH = p.tokenWETH();
        // info.vTokenB0 = p.vTokenB0();
        // info.vTokenETH = p.vTokenETH();
        // info.lToken = p.lToken();
        // info.pToken = p.pToken();

        info.oracleManager = p.oracleManager();
        info.swapper = p.swapper();
        info.symbolManager = p.symbolManager();
        info.reserveRatioB0 = p.reserveRatioB0();
        info.minRatioB0 = p.minRatioB0();
        info.poolInitialMarginMultiplier = p.poolInitialMarginMultiplier();
        info.protocolFeeCollectRatio = p.protocolFeeCollectRatio();
        info.minLiquidationReward = p.minLiquidationReward();
        info.maxLiquidationReward = p.maxLiquidationReward();
        info.liquidationRewardCutRatio = p.liquidationRewardCutRatio();
        info.liquidity =  p.getLiquidity().utoi();

        address lpAddress = p.lpTokenAddress();
        info.totalSupply = IERC20(lpAddress).totalSupply();

        info.lpsPnl = p.lpsPnl();
        info.cumulativePnlPerLiquidity = p.cumulativePnlPerLiquidity();
        info.protocolFeeAccrued = p.protocolFeeAccrued();

        info.symbolManagerImplementation = ILensSymbolManager(info.symbolManager).implementation();
        info.initialMarginRequired = ILensSymbolManager(info.symbolManager).initialMarginRequired();
    }

    // function getMarketsInfo(address pool_) public view returns (MarketInfo[] memory infos) {
    //     ILensPool pool = ILensPool(pool_);
    //     ILensComptroller comptroller = ILensComptroller(ILensVault(pool.vaultImplementation()).comptroller());
    //     ILensOracle oracle = ILensOracle(comptroller.oracle());

    //     address tokenB0 = pool.tokenB0();
    //     address tokenWETH = pool.tokenWETH();
    //     address vTokenB0 = pool.vTokenB0();
    //     address vTokenETH = pool.vTokenETH();

    //     address[] memory allMarkets = comptroller.getAllMarkets();
    //     address[] memory underlyings = new address[](allMarkets.length);
    //     uint256 count;
    //     for (uint256 i = 0; i < allMarkets.length; i++) {
    //         address vToken = allMarkets[i];
    //         if (vToken == vTokenB0) {
    //             underlyings[i] = tokenB0;
    //             count++;
    //         } else if (vToken == vTokenETH) {
    //             underlyings[i] = tokenWETH;
    //             count++;
    //         } else {
    //             address underlying = ILensVToken(vToken).underlying();
    //             if (pool.markets(underlying) == vToken) {
    //                 underlyings[i] = underlying;
    //                 count++;
    //             }
    //         }
    //     }

    //     infos = new MarketInfo[](count);
    //     count = 0;
    //     for (uint256 i = 0; i < underlyings.length; i++) {
    //         if (underlyings[i] != address(0)) {
    //             infos[count].underlying = underlyings[i];
    //             infos[count].vToken = allMarkets[i];
    //             infos[count].underlyingSymbol = ILensERC20(underlyings[i]).symbol();
    //             infos[count].vTokenSymbol = ILensVToken(allMarkets[i]).symbol();
    //             infos[count].underlyingPrice = oracle.getUnderlyingPrice(allMarkets[i]);
    //             infos[count].exchangeRate = ILensVToken(allMarkets[i]).exchangeRateStored();
    //             count++;
    //         }
    //     }
    // }

    function getTokenInfo(address pool_, address account_) public view returns (TokenInfo [] memory infos) {
        ILensPool pool = ILensPool(pool_);
        uint256 length = pool.allWhitelistedTokensLength();

        infos = new TokenInfo[](length);

        for(uint256 i=0 ; i< length ; i++) {
            address token = pool.allWhitelistedTokens(i);
            infos[i].token = token;
            infos[i].price = pool.getTokenPrice(token);
            infos[i].balance = IERC20(token).balanceOf(account_);
            infos[i].symbol = IERC20(token).symbol();
        }   
    }

    function getSymbolInfo(address pool_, string calldata symbolName, ISymbolsLens.PriceAndVolatility[] memory pvs)
    public view returns (ISymbolsLens.SymbolInfo memory info) {
        info = symbolsLens.getSymbolInfo(pool_, symbolName, pvs);
        return info;
    }

    function getSymbolsInfo(address pool_, ISymbolsLens.PriceAndVolatility[] memory pvs)
    public view returns (ISymbolsLens.SymbolInfo[] memory infos) {
        return symbolsLens.getSymbolsInfo(pool_, pvs);
    }

    function getLpInfo(address pool_, address account_) public view returns (LpInfo memory info) {
        ILensPool pool = ILensPool(pool_);
        info.account = account_;
        // info.lTokenId = ILensDToken(pool.lToken()).getTokenIdOf(account_);
        // if (info.lTokenId != 0) {
        //     ILensPool.PoolLpInfo memory tmp = pool.lpInfos(info.lTokenId);
        //     info.vault = tmp.vault;
        //     info.amountB0 = tmp.amountB0;
        //     info.liquidity = tmp.liquidity;
        //     info.cumulativePnlPerLiquidity = tmp.cumulativePnlPerLiquidity;
        //     info.vaultLiquidity = ILensVault(info.vault).getVaultLiquidity();

            // address[] memory markets = ILensVault(info.vault).getMarketsIn();
            // info.markets = new MarketInfo[](markets.length);
            // for (uint256 i = 0; i < markets.length; i++) {
            //     address vToken = markets[i];
            //     info.markets[i].vToken = vToken;
            //     info.markets[i].vTokenSymbol = ILensVToken(vToken).symbol();
            //     info.markets[i].underlying = vToken != pool.vTokenETH() ? ILensVToken(vToken).underlying() : pool.tokenWETH();
            //     info.markets[i].underlyingSymbol = ILensERC20(info.markets[i].underlying).symbol();
            //     info.markets[i].underlyingPrice = ILensOracle(ILensComptroller(ILensVault(pool.vaultImplementation()).comptroller()).oracle()).getUnderlyingPrice(vToken);
            //     info.markets[i].exchangeRate = ILensVToken(vToken).exchangeRateStored();
            //     info.markets[i].vTokenBalance = ILensVToken(vToken).balanceOf(info.vault);
            // }
        // }
        // ILensPool.PoolLpInfo memory tmp = pool.lpInfos(info.lTokenId);
        info.vault = address(0);
        info.amountB0 = 0;
        info.liquidity =  pool.getLiquidity().utoi();
        info.cumulativePnlPerLiquidity = 0;

        address lpAddress = pool.lpTokenAddress();
        uint256 totalSupply = IERC20(lpAddress).totalSupply();
        uint256 balance = IERC20(lpAddress).balanceOf(account_);
        

        info.vaultLiquidity = info.liquidity.itou() * balance / totalSupply;
    }

    function estimateLiquidationPrice(address pool_, address account_, string memory symbolName, int256 tradeVolume) public view returns (int256 liquidationPrice) {
        // return 0;
        bytes32 vaultId = keccak256(abi.encodePacked(account_, symbolName));
        ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));
        address symbolAddress = manager.symbols(symbolId);
        ILensSymbol symbol = ILensSymbol(symbolAddress);
        ILensPool pool = ILensPool(pool_);
        ILensSymbol.Position memory p = symbol.positions(account_);
        int256 curIndexPrice;
        if(symbol.nameId() != keccak256(abi.encodePacked("SymbolImplementationFutures"))){
            return 0;
        }
        curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.symbolId()).utoi();
        // if(symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationFutures"))){
        //     curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.symbolId()).utoi();
        // }
        // else {
        //     curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.priceId()).utoi();
        // }
        TradeData memory tradeData;
        tradeData.tradeVolume = tradeVolume;
        tradeData.K = curIndexPrice * symbol.alpha() / pool.getLiquidity().utoi();
        tradeData.tradeCost = DpmmLinearPricing.calculateCost(curIndexPrice, tradeData.K, symbol.netVolume(), tradeData.tradeVolume);
        tradeData.tradeFee = tradeData.tradeCost.abs() * symbol.feeRatio() / ONE;
        tradeData.cumulativeFundingPerVolume = symbol.cumulativeFundingPerVolume();
        tradeData.diff = tradeData.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume;
        tradeData.traderFunding = p.volume * tradeData.diff / ONE;
        if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = p.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                tradeData.tradeRealizedCost = tradeData.tradeCost * absVolume / absTradeVolume + p.cost;
            } else {
                tradeData.tradeRealizedCost = p.cost * absTradeVolume / absVolume + tradeData.tradeCost;
            }
        }
        p.volume = p.volume + tradeData.tradeVolume;
        tradeData.cost = p.cost + tradeData.tradeCost - tradeData.tradeRealizedCost;
        tradeData.traderPnl = p.volume * curIndexPrice / ONE - tradeData.cost;
        tradeData.amountB0 = pool.userAmountB0(vaultId) - tradeData.traderFunding - tradeData.tradeFee - tradeData.tradeRealizedCost;
        tradeData.traderMargin = tradeData.traderPnl + ILensVault(pool.userVault(vaultId)).getVaultLiquidity().utoi() + tradeData.amountB0;
        for (uint256 i = 0; i < pool.allWhitelistedTokensLength(); i++) {
            if (!pool.whitelistedTokens(pool.allWhitelistedTokens(i))) {
                continue;
            }
            bytes32 priceId = pool.getTokenPriceId(pool.allWhitelistedTokens(i));
            if (priceId==symbolId){
                tradeData.volumeA = ILensVault(pool.userVault(vaultId)).getVaultLiquidityTokenVolume(pool.allWhitelistedTokens(i)).utoi();
                tradeData.marginA = ILensVault(pool.userVault(vaultId)).getVaultLiquidityToken(pool.allWhitelistedTokens(i)).utoi();
            }
        }
        if (p.volume!=0){
            liquidationPrice = (p.cost-tradeData.traderMargin+tradeData.marginA)/(p.volume+tradeData.volumeA)*ONE;
            if (liquidationPrice<0){
                liquidationPrice = 0;
            }
        }
        // return (p.cost-tradeData.traderMargin+tradeData.marginA)/(p.volume+tradeData.volumeA)*ONE;
    }

    function getTdInfo(address pool_, address account_) public view returns (TdInfo memory info) {
        ILensPool pool = ILensPool(pool_);
        info.account = account_;
        // info.pTokenId = ILensDToken(pool.pToken()).getTokenIdOf(account_);
            // address[] memory markets = ILensVault(info.vault).getMarketsIn();
            // info.markets = new MarketInfo[](markets.length);
            // for (uint256 i = 0; i < markets.length; i++) {
            //     address vToken = markets[i];
            //     info.markets[i].vToken = vToken;
            //     info.markets[i].vTokenSymbol = ILensVToken(vToken).symbol();
            //     info.markets[i].underlying = vToken != pool.vTokenETH() ? ILensVToken(vToken).underlying() : pool.tokenWETH();
            //     info.markets[i].underlyingSymbol = ILensERC20(info.markets[i].underlying).symbol();
            //     info.markets[i].underlyingPrice = ILensOracle(ILensComptroller(ILensVault(pool.vaultImplementation()).comptroller()).oracle()).getUnderlyingPrice(vToken);
            //     info.markets[i].exchangeRate = ILensVToken(vToken).exchangeRateStored();
            //     info.markets[i].vTokenBalance = ILensVToken(vToken).balanceOf(info.vault);
            // }


        uint256 length = ILensSymbolManager(pool.symbolManager()).getSymbolsLength();
        info.positions = new PositionInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            address symbolAddr = ILensSymbolManager(pool.symbolManager()).indexedSymbols(i);
            ILensSymbol symbol = ILensSymbol(symbolAddr);
            info.positions[i].symbolAddress = symbolAddr;
            info.positions[i].symbol = symbol.symbol();

            bytes32 vaultId = keccak256(abi.encodePacked(account_, info.positions[i].symbol));
            info.positions[i].vault = pool.userVault(vaultId);
            info.positions[i].vaultLiquidity = info.positions[i].vault == address(0) ? 0 : ILensVault(info.positions[i].vault).getVaultLiquidity();
            
            ILensSymbol.Position memory p = symbol.positions(account_);
            info.positions[i].volume = p.volume;
            info.positions[i].cost = p.cost;
            info.positions[i].cumulativeFundingPerVolume = p.cumulativeFundingPerVolume;

            // ILensPool.PoolTdInfo memory tmp = pool.tdInfos(info.pTokenId);

            // int256 K;
            // int256 curVolatility = ILensOracleManager(symbol.oracleManager()).value(symbol.volatilityId()).utoi();
            // int256 liquidity = pool.getLiquidity().utoi() + pool.lpsPnl() + 1;
            // if (symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationFutures"))){
            //     K = ILensOracleManager(curIndexPrice * symbol.alpha() / liquidity;
            // } else if (symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationOption"))) {
            //     int256 timeValue;
            //     int256 delta;
            //     (timeValue, delta, ) = symbolsLens.everlastingOptionPricingLens.getEverlastingTimeValueAndDelta(
            //         curIndexPrice, symbol.strikePrice(), curVolatility, symbol.fundingPeriod() * ONE / 31536000
            //     );
            //     int256 intrinsicValue = symbol.isCall() ?
            //                             (curIndexPrice - symbol.strikePrice()).max(0) :
            //                             (symbol.strikePrice() - curIndexPrice).max(0);
            //     K = curIndexPrice ** 2 / (intrinsicValue + timeValue) * delta.abs() * symbol.alpha() / liquidity / ONE;
            // } else if (symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationPower"))) {
            //     int256 hT = curVolatility ** 2 / ONE * symbol.power().utoi() * (symbol.power().utoi() - 1) / 2 * symbol.fundingPeriod() / 31536000;
            //     int256 powerPrice = _exp(curIndexPrice, symbol.power());
            //     int256 theoreticalPrice = powerPrice * ONE / (ONE - hT);
            //     K = symbol.power().utoi() * theoreticalPrice * symbol.alpha() / liquidity;
            // }

            // int256 tradeCost = DpmmLinearPricing.calculateCost(symbol.indexPrice(), K, symbol.netVolume(), tradeVolume);
            // int256 tradeFee = tradeCost.abs() * symbol.feeRatio() / ONE;
            // int tradeRealizedCost;
            // if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            //     int256 absVolume = p.volume.abs();
            //     int256 absTradeVolume = tradeVolume.abs();
            //     if (absVolume <= absTradeVolume) {
            //         tradeRealizedCost = tradeCost * absVolume / absTradeVolume + p.cost;
            //     } else {
            //         tradeRealizedCost = p.cost * absTradeVolume / absVolume + tradeCost;
            //     }
            // }

            int256 diff;
            unchecked { diff = symbol.cumulativeFundingPerVolume() - p.cumulativeFundingPerVolume; }

            int256 curIndexPrice;
            if(symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationFutures"))){
                curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.symbolId()).utoi();
            } else {
                // curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.priceId()).utoi();
                ISymbolsLens.PriceAndVolatility[] memory pvs;
                ISymbolsLens.SymbolInfo memory symbolInfo = symbolsLens.getSymbolInfo(pool_,symbol.symbol(),pvs);
                curIndexPrice = symbolInfo.theoreticalPrice;
            }
            int256 notional = p.volume * curIndexPrice / ONE;

            info.amountB0 = pool.userAmountB0(vaultId);
            int256 traderpnl = notional - p.cost;

            info.positions[i].margin = info.positions[i].vaultLiquidity.utoi() + info.amountB0 + traderpnl;
            info.positions[i].marginUsed = traderpnl < 0 ? traderpnl.abs() : int256(0);
            if (info.positions[i].volume != 0){
                info.positions[i].liquidationPrice = estimateLiquidationPrice(pool_,account_,symbol.symbol(),0);
            }
        }
    }


    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    // function estimateMaxVolume(address pool_, address account_, string memory symbolName, bool isLong) public view returns (int256 maxVolume) {
    //     int256 negative;
    //      if (isLong){
    //         negative = 1;
    //      }else{
    //         negative = -1;
    //      }
    //     bytes32 vaultId = keccak256(abi.encodePacked(account_, symbolName));
    //     ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
    //     ILensSymbol symbol = ILensSymbol(manager.symbols(keccak256(abi.encodePacked(symbolName))));
    //     ILensPool pool = ILensPool(pool_);
    //     ILensSymbol.Position memory p = symbol.positions(account_);
    //     TradeInfo memory tradeInfo;
    //     if(symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationFutures"))){
    //         tradeInfo.curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.symbolId()).utoi();
    //     }
    //     else {
    //         tradeInfo.curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.priceId()).utoi();
    //     }
        
    //     tradeInfo.vaultLiquidity = ILensVault(pool.userVault(vaultId)).getVaultLiquidity().utoi();
    //     if (tradeInfo.vaultLiquidity==0){
    //         return 0;
    //     }
    //     tradeInfo.amountB0 = pool.userAmountB0(vaultId);
    //     tradeInfo.K = tradeInfo.curIndexPrice * symbol.alpha() / (pool.getLiquidity().utoi() + pool.lpsPnl());
    //     tradeInfo.cumulativeFundingPerVolume = symbol.cumulativeFundingPerVolume();
    //     tradeInfo.diff = tradeInfo.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume;
    //     tradeInfo.funding = p.volume * tradeInfo.diff / ONE;
    //     tradeInfo.cost = p.cost;
    //     tradeInfo.volume = p.volume;
    //     tradeInfo.feeRatio = symbol.feeRatio();
    //     tradeInfo.maxLeverage = symbol.maxLeverage();
    //     tradeInfo.netVolume = symbol.netVolume();
    //     tradeInfo.marginUsed = tradeInfo.curIndexPrice*p.volume/ONE-tradeInfo.cost;
    //     if (tradeInfo.marginUsed>0){
    //         tradeInfo.marginUsed = 0;
    //     }
    //     int256 n=1;
    //     if (!isLong){
    //         n = -1;
    //     }
    //     tradeInfo.a = - tradeInfo.maxLeverage*tradeInfo.curIndexPrice/ONE*tradeInfo.K/ONE*(tradeInfo.feeRatio+ONE)/2/ONE;
    //     tradeInfo.b = (-tradeInfo.maxLeverage*tradeInfo.feeRatio/ONE*tradeInfo.curIndexPrice/ONE*(tradeInfo.K*tradeInfo.netVolume*n/ONE+ONE)/ONE-tradeInfo.curIndexPrice*(tradeInfo.maxLeverage*tradeInfo.netVolume*n/ONE*tradeInfo.K/ONE+ONE)/ONE)*negative;
    //     tradeInfo.c = tradeInfo.maxLeverage*(tradeInfo.vaultLiquidity+tradeInfo.amountB0-tradeInfo.funding+tradeInfo.curIndexPrice/ONE*p.volume-p.cost)/ONE - p.volume.abs()*tradeInfo.curIndexPrice/ONE;

    //     int256 b24ac = tradeInfo.b**2-4*tradeInfo.a*tradeInfo.c;
    //     tradeInfo.maxVolume = (-tradeInfo.b-negative*sqrt(b24ac.itou()).utoi())*ONE/(2*tradeInfo.a);
    //     return tradeInfo.maxVolume;
    // }
    function estimateMaxVolume(address pool_, address account_, string memory symbolName, bool isLong) public view returns (int256 maxVolume) {
        bytes32 vaultId = keccak256(abi.encodePacked(account_, symbolName));
        ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
        ILensSymbol symbol = ILensSymbol(manager.symbols(keccak256(abi.encodePacked(symbolName))));
        ILensPool pool = ILensPool(pool_);
        ILensSymbol.Position memory p = symbol.positions(account_);
        TradeInfo memory tradeInfo;
        if(symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationFutures"))){
            tradeInfo.curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.symbolId()).utoi();
        }
        else {
            tradeInfo.curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.priceId()).utoi();
        }
        
        tradeInfo.vaultLiquidity = ILensVault(pool.userVault(vaultId)).getVaultLiquidity().utoi();
        if (tradeInfo.vaultLiquidity==0){
            return 0;
        }
        tradeInfo.amountB0 = pool.userAmountB0(vaultId);
        tradeInfo.cumulativeFundingPerVolume = symbol.cumulativeFundingPerVolume();
        tradeInfo.diff = tradeInfo.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume;
        tradeInfo.funding = p.volume * tradeInfo.diff / ONE;
        tradeInfo.cost = p.cost;
        tradeInfo.volume = p.volume;
        tradeInfo.maxLeverage = symbol.maxLeverage();
        tradeInfo.marginRequiredRatio = symbol.marginRequiredRatio();
        tradeInfo.marginUsed = tradeInfo.curIndexPrice*p.volume/ONE-tradeInfo.cost;
        if (tradeInfo.marginUsed>0){
            tradeInfo.marginUsed = 0;
        }
        tradeInfo.availableMargin = tradeInfo.vaultLiquidity+tradeInfo.amountB0-tradeInfo.funding+tradeInfo.marginUsed;
        tradeInfo.maxVolume = (tradeInfo.availableMargin*tradeInfo.maxLeverage/ONE*tradeInfo.marginRequiredRatio/ONE-tradeInfo.cost)*ONE/tradeInfo.curIndexPrice;
        return tradeInfo.maxVolume;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library EverlastingOptionPricingLens {

    uint128 private constant TWO127 = 0x80000000000000000000000000000000;   // 2^127
    uint128 private constant TWO128_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // 2^128 - 1
    int128  private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256  private constant ONE = 10**18;
    uint256 private constant UONE = 10**18;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= 2**255 - 1);
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }

    function int256To128(int256 a) internal pure returns (int128) {
        require(a >= -2**127);
        require(a <= 2**127 - 1);
        return int128(a);
    }

    /*
     * Return index of most significant non-zero bit in given non-zero 256-bit
     * unsigned integer value.
     *
     * @param x value to get index of most significant non-zero bit in
     * @return index of most significant non-zero bit in given number
     */
    function mostSignificantBit (uint256 x) internal pure returns (uint8 r) {
        require (x > 0);

        if (x >= 0x100000000000000000000000000000000) {x >>= 128; r += 128;}
        if (x >= 0x10000000000000000) {x >>= 64; r += 64;}
        if (x >= 0x100000000) {x >>= 32; r += 32;}
        if (x >= 0x10000) {x >>= 16; r += 16;}
        if (x >= 0x100) {x >>= 8; r += 8;}
        if (x >= 0x10) {x >>= 4; r += 4;}
        if (x >= 0x4) {x >>= 2; r += 2;}
        if (x >= 0x2) r += 1; // No need to shift x anymore
    }

    /*
     * Calculate log_2 (x / 2^128) * 2^128.
     *
     * @param x parameter value
     * @return log_2 (x / 2^128) * 2^128
     */
    function _log_2 (uint256 x) internal pure returns (int256) {
        require (x > 0);

        uint8 msb = mostSignificantBit (x);

        if (msb > 128) x >>= msb - 128;
        else if (msb < 128) x <<= 128 - msb;

        x &= TWO128_1;

        int256 result = (int256 (uint256(msb)) - 128) << 128; // Integer part of log_2

        int256 bit = int256(uint256(TWO127));
        for (uint8 i = 0; i < 128 && x > 0; i++) {
            x = (x << 1) + ((x * x + TWO127) >> 128);
            if (x > TWO128_1) {
                result |= bit;
                x = (x >> 1) - TWO127;
            }
            bit >>= 1;
        }

        return result;
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function _exp_2 (int128 x) internal pure returns (int128) {
        unchecked {
            require (x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0)
                result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
            if (x & 0x4000000000000000 > 0)
                result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
            if (x & 0x2000000000000000 > 0)
                result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
            if (x & 0x1000000000000000 > 0)
                result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
            if (x & 0x800000000000000 > 0)
                result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
            if (x & 0x400000000000000 > 0)
                result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
            if (x & 0x200000000000000 > 0)
                result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
            if (x & 0x100000000000000 > 0)
                result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
            if (x & 0x80000000000000 > 0)
                result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
            if (x & 0x40000000000000 > 0)
                result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
            if (x & 0x20000000000000 > 0)
                result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
            if (x & 0x10000000000000 > 0)
                result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
            if (x & 0x8000000000000 > 0)
                result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
            if (x & 0x4000000000000 > 0)
                result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
            if (x & 0x2000000000000 > 0)
                result = result * 0x1000162E525EE054754457D5995292026 >> 128;
            if (x & 0x1000000000000 > 0)
                result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
            if (x & 0x800000000000 > 0)
                result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
            if (x & 0x400000000000 > 0)
                result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
            if (x & 0x200000000000 > 0)
                result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
            if (x & 0x100000000000 > 0)
                result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
            if (x & 0x80000000000 > 0)
                result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
            if (x & 0x40000000000 > 0)
                result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
            if (x & 0x20000000000 > 0)
                result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
            if (x & 0x10000000000 > 0)
                result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
            if (x & 0x8000000000 > 0)
                result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
            if (x & 0x4000000000 > 0)
                result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
            if (x & 0x2000000000 > 0)
                result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
            if (x & 0x1000000000 > 0)
                result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
            if (x & 0x800000000 > 0)
                result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
            if (x & 0x400000000 > 0)
                result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
            if (x & 0x200000000 > 0)
                result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
            if (x & 0x100000000 > 0)
                result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
            if (x & 0x80000000 > 0)
                result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
            if (x & 0x40000000 > 0)
                result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
            if (x & 0x20000000 > 0)
                result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
            if (x & 0x10000000 > 0)
                result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
            if (x & 0x8000000 > 0)
                result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
            if (x & 0x4000000 > 0)
                result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
            if (x & 0x2000000 > 0)
                result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
            if (x & 0x1000000 > 0)
                result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
            if (x & 0x800000 > 0)
                result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
            if (x & 0x400000 > 0)
                result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
            if (x & 0x200000 > 0)
                result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
            if (x & 0x100000 > 0)
                result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
            if (x & 0x80000 > 0)
                result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
            if (x & 0x40000 > 0)
                result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
            if (x & 0x20000 > 0)
                result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
            if (x & 0x10000 > 0)
                result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
            if (x & 0x8000 > 0)
                result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
            if (x & 0x4000 > 0)
                result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
            if (x & 0x2000 > 0)
                result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
            if (x & 0x1000 > 0)
                result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
            if (x & 0x800 > 0)
                result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
            if (x & 0x400 > 0)
                result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
            if (x & 0x200 > 0)
                result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
            if (x & 0x100 > 0)
                result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
            if (x & 0x80 > 0)
                result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
            if (x & 0x40 > 0)
                result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
            if (x & 0x20 > 0)
                result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
            if (x & 0x10 > 0)
                result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
            if (x & 0x8 > 0)
                result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
            if (x & 0x4 > 0)
                result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
            if (x & 0x2 > 0)
                result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
            if (x & 0x1 > 0)
                result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

            result >>= uint256 (int256 (63 - (x >> 64)));
            require (result <= uint256 (int256 (MAX_64x64)));

            return int128 (int256 (result));
        }
    }

    // x in 18 decimals, y in 18 decimals
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        x *= UONE;
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // calculate x^y, x, y and return in 18 decimals
    function exp(uint256 x, int256 y) internal pure returns (int256) {
        int256 log2x = _log_2((x << 128) / UONE) * ONE >> 128;
        int256 p = log2x * y / ONE;
        return _exp_2(int256To128((p << 64) / ONE)) * ONE >> 64;
    }

    function getEverlastingTimeValue(int256 S, int256 K, int256 V, int256 T)
    external pure returns (int256 timeValue, int256 u)
    {
        int256 u2 = ONE * 8 * ONE / V * ONE / V * ONE / T + ONE;
        u = utoi(sqrt(itou(u2)));

        uint256 x = itou(S * ONE / K);
        if (S > K) {
            timeValue = K * exp(x, (ONE - u) / 2) / u;
        } else if (S == K) {
            timeValue = K * ONE / u;
        } else {
            timeValue = K * exp(x, (ONE + u) / 2) / u;
        }
    }

    function getEverlastingTimeValueAndDelta(int256 S, int256 K, int256 V, int256 T)
    external pure returns (int256 timeValue, int256 delta, int256 u)
    {
        int256 u2 = ONE * 8 * ONE / V * ONE / V * ONE / T + ONE;
        u = utoi(sqrt(itou(u2)));

        uint256 x = itou(S * ONE / K);
        if (S > K) {
            timeValue = K * exp(x, (ONE - u) / 2) / u;
            delta = (ONE - u) * timeValue / S / 2;
        } else if (S == K) {
            timeValue = K * ONE / u;
            delta = 0;
        } else {
            timeValue = K * exp(x, (ONE + u) / 2) / u;
            delta = (ONE + u) * timeValue / S / 2;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';
import '../library/DpmmLinearPricing.sol';

interface ISymbolsLens {

    struct SymbolInfo {
        string category;
        string symbol;
        address symbolAddress;
        address implementation;
        address manager;
        address oracleManager;
        bytes32 symbolId;
        int256 feeRatio;
        int256 alpha;
        int256 fundingPeriod;
        int256 minTradeVolume;
        int256 minInitialMarginRatio;
        int256 initialMarginRatio;
        int256 maintenanceMarginRatio;
        int256 pricePercentThreshold;
        uint256 timeThreshold;
        bool isCloseOnly;
        bytes32 priceId;
        bytes32 volatilityId;
        int256 feeRatioITM;
        int256 feeRatioOTM;
        int256 strikePrice;
        bool isCall;

        int256 netVolume;
        int256 netCost;
        int256 indexPrice;
        uint256 fundingTimestamp;
        int256 cumulativeFundingPerVolume;
        int256 tradersPnl;
        int256 initialMarginRequired;
        uint256 nPositionHolders;

        int256 curIndexPrice;
        int256 curVolatility;
        int256 curCumulativeFundingPerVolume;
        int256 K;
        int256 markPrice;
        int256 funding;
        int256 timeValue;
        int256 delta;
        int256 u;

        int256 power;
        int256 hT;
        int256 powerPrice;
        int256 theoreticalPrice;
    }

    struct PriceAndVolatility {
        string symbol;
        int256 indexPrice;
        int256 volatility;
    }

    function getSymbolInfo(address pool_, string calldata symbolName_, PriceAndVolatility[] memory pvs) external view returns (SymbolInfo memory info);

    function getSymbolsInfo(address pool_, PriceAndVolatility[] memory pvs) external view returns (SymbolInfo[] memory infos);

}

contract SymbolsLens is ISymbolsLens, NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;

    IEverlastingOptionPricingLens public immutable everlastingOptionPricingLens;

    constructor (address everlastingOptionPricingLens_) NameVersion('SymbolsLens', '3.0.2') {
        everlastingOptionPricingLens = IEverlastingOptionPricingLens(everlastingOptionPricingLens_);
    }

    function getSymbolInfoByAddress(address pool_, address symbolAddress_, PriceAndVolatility[] memory pvs) internal view returns (SymbolInfo memory info) {
        ILensSymbol s = ILensSymbol(symbolAddress_);

        info.symbol = s.symbol();
        info.symbolAddress = address(s);
        info.implementation = s.implementation();
        info.manager = s.manager();
        info.oracleManager = s.oracleManager();
        info.symbolId = s.symbolId();
        info.alpha = s.alpha();
        info.fundingPeriod = s.fundingPeriod();
        info.minTradeVolume = s.minTradeVolume();
        info.initialMarginRatio = s.initialMarginRatio();
        info.maintenanceMarginRatio = s.maintenanceMarginRatio();
        info.pricePercentThreshold = s.pricePercentThreshold();
        info.timeThreshold = s.timeThreshold();
        info.isCloseOnly = s.isCloseOnly();

        info.netVolume = s.netVolume();
        info.netCost = s.netCost();
        info.indexPrice = s.indexPrice();
        info.fundingTimestamp = s.fundingTimestamp();
        info.cumulativeFundingPerVolume = s.cumulativeFundingPerVolume();
        info.tradersPnl = s.tradersPnl();
        info.initialMarginRequired = s.initialMarginRequired();
        info.nPositionHolders = s.nPositionHolders();

        int256 liquidity = ILensPool(pool_).getLiquidity().utoi() + ILensPool(pool_).lpsPnl() + 1;
        if (s.nameId() == keccak256(abi.encodePacked('SymbolImplementationFutures'))) {
            info.category = 'futures';
            info.feeRatio = s.feeRatio();
            info.curIndexPrice = ILensOracleManager(info.oracleManager).value(info.symbolId).utoi();
            for (uint256 j = 0; j < pvs.length; j++) {
                if (info.symbolId == keccak256(abi.encodePacked(pvs[j].symbol))) {
                    if (pvs[j].indexPrice != 0) info.curIndexPrice = pvs[j].indexPrice;
                    break;
                }
            }
            info.K = info.curIndexPrice * info.alpha / liquidity;
            info.markPrice = DpmmLinearPricing.calculateMarkPrice(info.curIndexPrice, info.K, info.netVolume);
            int256 diff = (info.markPrice - info.curIndexPrice) * (block.timestamp - info.fundingTimestamp).utoi() / info.fundingPeriod;
            info.funding = info.netVolume * diff / ONE;
            unchecked { info.curCumulativeFundingPerVolume = info.cumulativeFundingPerVolume + diff; }

        } else if (s.nameId() == keccak256(abi.encodePacked('SymbolImplementationOption'))) {
            info.category = 'option';
            info.minInitialMarginRatio = s.minInitialMarginRatio();
            info.priceId = s.priceId();
            info.volatilityId = s.volatilityId();
            info.feeRatioITM = s.feeRatioITM();
            info.feeRatioOTM = s.feeRatioOTM();
            info.strikePrice = s.strikePrice();
            info.isCall = s.isCall();
            info.curIndexPrice = ILensOracleManager(info.oracleManager).value(info.priceId).utoi();
            info.curVolatility = ILensOracleManager(info.oracleManager).value(info.volatilityId).utoi();
            for (uint256 j = 0; j < pvs.length; j++) {
                if (info.priceId == keccak256(abi.encodePacked(pvs[j].symbol))) {
                    if (pvs[j].indexPrice != 0) info.curIndexPrice = pvs[j].indexPrice;
                    if (pvs[j].volatility != 0) info.curVolatility = pvs[j].volatility;
                    break;
                }
            }
            int256 intrinsicValue = info.isCall ?
                                    (info.curIndexPrice - info.strikePrice).max(0) :
                                    (info.strikePrice - info.curIndexPrice).max(0);
            (info.timeValue, info.delta, info.u) = everlastingOptionPricingLens.getEverlastingTimeValueAndDelta(
                info.curIndexPrice, info.strikePrice, info.curVolatility, info.fundingPeriod * ONE / 31536000
            );
            if (intrinsicValue > 0) {
                if (info.isCall) info.delta += ONE;
                else info.delta -= ONE;
            } else if (info.curIndexPrice == info.strikePrice) {
                if (info.isCall) info.delta = ONE / 2;
                else info.delta = -ONE / 2;
            }
            info.theoreticalPrice = intrinsicValue + info.timeValue;
            info.K = info.curIndexPrice ** 2 / (intrinsicValue + info.timeValue) * info.delta.abs() * info.alpha / liquidity / ONE;
            info.markPrice = DpmmLinearPricing.calculateMarkPrice(
                intrinsicValue + info.timeValue, info.K, info.netVolume
            );
            int256 diff = (info.markPrice - intrinsicValue) * (block.timestamp - info.fundingTimestamp).utoi() / info.fundingPeriod;
            info.funding = info.netVolume * diff / ONE;
            unchecked { info.curCumulativeFundingPerVolume = info.cumulativeFundingPerVolume + diff; }
            
        } else if (s.nameId() == keccak256(abi.encodePacked('SymbolImplementationPower'))) {
            info.category = 'power';
            info.power = s.power().utoi();
            info.feeRatio = s.feeRatio();
            info.priceId = s.priceId();
            info.volatilityId = s.volatilityId();
            info.curIndexPrice = ILensOracleManager(info.oracleManager).value(info.priceId).utoi();
            info.curVolatility = ILensOracleManager(info.oracleManager).value(info.volatilityId).utoi();
            for (uint256 j = 0; j < pvs.length; j++) {
                if (info.priceId == keccak256(abi.encodePacked(pvs[j].symbol))) {
                    if (pvs[j].indexPrice != 0) info.curIndexPrice = pvs[j].indexPrice;
                    if (pvs[j].volatility != 0) info.curVolatility = pvs[j].volatility;
                    break;
                }
            }
            info.hT = info.curVolatility ** 2 / ONE * info.power * (info.power - 1) / 2 * info.fundingPeriod / 31536000;
            info.powerPrice = _exp(info.curIndexPrice, s.power());
            info.theoreticalPrice = info.powerPrice * ONE / (ONE - info.hT);
            info.K = info.power * info.theoreticalPrice * info.alpha / liquidity;
            info.markPrice = DpmmLinearPricing.calculateMarkPrice(
                info.theoreticalPrice, info.K, info.netVolume
            );
            int256 diff = (info.markPrice - info.powerPrice) * (block.timestamp - info.fundingTimestamp).utoi() / info.fundingPeriod;
            info.funding = info.netVolume * diff / ONE;
            unchecked { info.curCumulativeFundingPerVolume = info.cumulativeFundingPerVolume + diff; }
        }
    }

    function getSymbolInfo(address pool_, string calldata symbolName, PriceAndVolatility[] memory pvs) public view returns (SymbolInfo memory info) {
        ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));
        address symbolAddress = manager.symbols(symbolId);
        if (symbolAddress == address(0))
            return info;
        info = getSymbolInfoByAddress(pool_, symbolAddress, pvs);
    }

    function getSymbolsInfo(address pool_, PriceAndVolatility[] memory pvs) public view returns (SymbolInfo[] memory infos) {
        ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
        uint256 length = manager.getSymbolsLength();
        infos = new SymbolInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            address symbolAddress = manager.indexedSymbols(i);
            infos[i] = getSymbolInfoByAddress(pool_, symbolAddress, pvs);
        }
    }

    function _exp(int256 base, uint256 exp) internal pure returns (int256) {
        int256 res = ONE;
        for (uint256 i = 0; i < exp; i++) {
            res = res * base / ONE;
        }
        return res;
    }

}

interface ILensPool {
    struct PoolLpInfo {
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
    }
    struct PoolTdInfo {
        address vault;
        int256 amountB0;
    }
    function implementation() external view returns (address);
    function protocolFeeCollector() external view returns (address);
    function vaultImplementation() external view returns (address);
    function tokenB0() external view returns (address);
    function tokenWETH() external view returns (address);
    function vTokenB0() external view returns (address);
    function vTokenETH() external view returns (address);
    function lToken() external view returns (address);
    function pToken() external view returns (address);
    function oracleManager() external view returns (address);
    function swapper() external view returns (address);
    function symbolManager() external view returns (address);
    function reserveRatioB0() external view returns (uint256);
    function minRatioB0() external view returns (int256);
    function poolInitialMarginMultiplier() external view returns (int256);
    function protocolFeeCollectRatio() external view returns (int256);
    function minLiquidationReward() external view returns (int256);
    function maxLiquidationReward() external view returns (int256);
    function liquidationRewardCutRatio() external view returns (int256);
    function liquidity() external view returns (int256);
    function lpsPnl() external view returns (int256);
    function cumulativePnlPerLiquidity() external view returns (int256);
    function protocolFeeAccrued() external view returns (int256);
    function markets(address underlying_) external view returns (address);
    function lpInfos(uint256 lTokenId) external view returns (PoolLpInfo memory);
    function tdInfos(uint256 pTokenId) external view returns (PoolTdInfo memory);
    function userVault(bytes32 vaultId) external view returns (address);
    function userAmountB0(bytes32 vaultId) external view returns (int256);
    function getLiquidity() external view returns (uint256);
    function lpTokenAddress() external view returns (address);
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256 index) external view returns (address);
    function whitelistedTokens(address token) external view returns (bool);
    function getTokenPrice(address token) external view returns (uint256);
    function getTokenPriceId(address token) external view returns (bytes32);
}

interface ILensSymbolManager {
    function implementation() external view returns (address);
    function initialMarginRequired() external view returns (int256);
    function getSymbolsLength() external view returns (uint256);
    function indexedSymbols(uint256 index) external view returns (address);
    function getActiveSymbols(uint256 pTokenId) external view returns (address[] memory);
    function symbols(bytes32 symbolId) external view returns (address);
}

interface ILensSymbol {
    function nameId() external view returns (bytes32);
    function symbol() external view returns (string memory);
    function implementation() external view returns (address);
    function manager() external view returns (address);
    function oracleManager() external view returns (address);
    function symbolId() external view returns (bytes32);
    function feeRatio() external view returns (int256);
    function alpha() external view returns (int256);
    function fundingPeriod() external view returns (int256);
    function minTradeVolume() external view returns (int256);
    function minInitialMarginRatio() external view returns (int256);
    function initialMarginRatio() external view returns (int256);
    function maintenanceMarginRatio() external view returns (int256);
    function pricePercentThreshold() external view returns (int256);
    function timeThreshold() external view returns (uint256);
    function isCloseOnly() external view returns (bool);
    function priceId() external view returns (bytes32);
    function volatilityId() external view returns (bytes32);
    function feeRatioITM() external view returns (int256);
    function feeRatioOTM() external view returns (int256);
    function strikePrice() external view returns (int256);
    function isCall() external view returns (bool);
    function netVolume() external view returns (int256);
    function netCost() external view returns (int256);
    function indexPrice() external view returns (int256);
    function fundingTimestamp() external view returns (uint256);
    function cumulativeFundingPerVolume() external view returns (int256);
    function tradersPnl() external view returns (int256);
    function initialMarginRequired() external view returns (int256);
    function nPositionHolders() external view returns (uint256);
    struct Position {
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }
    function positions(address pTokenId) external view returns (Position memory);
    function power() external view returns (uint256);
    function maxLeverage() external view returns (int256);
    function marginRequiredRatio() external view returns (int256);
}

interface ILensVault {
    function comptroller() external view returns (address);
    function getVaultLiquidity() external view returns (uint256);
    function getVaultLiquidityToken(address token) external view returns (uint256);
    function getVaultLiquidityTokenVolume(address token) external view returns (uint256);
    function getMarketsIn() external view returns (address[] memory);
}

interface ILensVToken {
    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function underlying() external view returns (address);
    function exchangeRateStored() external view returns (uint256);
}

interface ILensComptroller {
    function getAllMarkets() external view returns (address[] memory);
    function oracle() external view returns (address);
}

interface ILensOracle {
    function getUnderlyingPrice(address vToken) external view returns (uint256);
}

interface ILensERC20 {
    function symbol() external view returns (string memory);
}

interface ILensOracleManager {
    function value(bytes32 symbolId) external view returns (uint256);
}

interface ILensDToken {
    function getTokenIdOf(address account) external view returns (uint256);
}

interface IEverlastingOptionPricingLens {
    function getEverlastingTimeValueAndDelta(int256 S, int256 K, int256 V, int256 T)
    external pure returns (int256 timeValue, int256 delta, int256 u);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library DpmmLinearPricing {

    int256 constant ONE = 1e18;

    function calculateMarkPrice(
        int256 indexPrice,
        int256 K,
        int256 tradersNetVolume
    ) internal pure returns (int256)
    {
        return indexPrice * (ONE + K * tradersNetVolume / ONE) / ONE;
    }

    function calculateCost(
        int256 indexPrice,
        int256 K,
        int256 tradersNetVolume,
        int256 tradeVolume
    ) internal pure returns (int256)
    {
        int256 r = ((tradersNetVolume + tradeVolume) ** 2 - tradersNetVolume ** 2) / ONE * K / ONE / 2 + tradeVolume;
        return indexPrice * r / ONE;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library EverlastingOptionPricing {

    uint128 private constant TWO127 = 0x80000000000000000000000000000000;   // 2^127
    uint128 private constant TWO128_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // 2^128 - 1
    int128  private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256  private constant ONE = 10**18;
    uint256 private constant UONE = 10**18;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= 2**255 - 1);
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }

    function int256To128(int256 a) internal pure returns (int128) {
        require(a >= -2**127);
        require(a <= 2**127 - 1);
        return int128(a);
    }

    /*
     * Return index of most significant non-zero bit in given non-zero 256-bit
     * unsigned integer value.
     *
     * @param x value to get index of most significant non-zero bit in
     * @return index of most significant non-zero bit in given number
     */
    function mostSignificantBit (uint256 x) internal pure returns (uint8 r) {
        require (x > 0);

        if (x >= 0x100000000000000000000000000000000) {x >>= 128; r += 128;}
        if (x >= 0x10000000000000000) {x >>= 64; r += 64;}
        if (x >= 0x100000000) {x >>= 32; r += 32;}
        if (x >= 0x10000) {x >>= 16; r += 16;}
        if (x >= 0x100) {x >>= 8; r += 8;}
        if (x >= 0x10) {x >>= 4; r += 4;}
        if (x >= 0x4) {x >>= 2; r += 2;}
        if (x >= 0x2) r += 1; // No need to shift x anymore
    }

    /*
     * Calculate log_2 (x / 2^128) * 2^128.
     *
     * @param x parameter value
     * @return log_2 (x / 2^128) * 2^128
     */
    function _log_2 (uint256 x) internal pure returns (int256) {
        require (x > 0);

        uint8 msb = mostSignificantBit (x);

        if (msb > 128) x >>= msb - 128;
        else if (msb < 128) x <<= 128 - msb;

        x &= TWO128_1;

        int256 result = (int256 (uint256(msb)) - 128) << 128; // Integer part of log_2

        int256 bit = int256(uint256(TWO127));
        for (uint8 i = 0; i < 128 && x > 0; i++) {
            x = (x << 1) + ((x * x + TWO127) >> 128);
            if (x > TWO128_1) {
                result |= bit;
                x = (x >> 1) - TWO127;
            }
            bit >>= 1;
        }

        return result;
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function _exp_2 (int128 x) internal pure returns (int128) {
        unchecked {
            require (x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0)
                result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
            if (x & 0x4000000000000000 > 0)
                result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
            if (x & 0x2000000000000000 > 0)
                result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
            if (x & 0x1000000000000000 > 0)
                result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
            if (x & 0x800000000000000 > 0)
                result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
            if (x & 0x400000000000000 > 0)
                result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
            if (x & 0x200000000000000 > 0)
                result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
            if (x & 0x100000000000000 > 0)
                result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
            if (x & 0x80000000000000 > 0)
                result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
            if (x & 0x40000000000000 > 0)
                result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
            if (x & 0x20000000000000 > 0)
                result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
            if (x & 0x10000000000000 > 0)
                result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
            if (x & 0x8000000000000 > 0)
                result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
            if (x & 0x4000000000000 > 0)
                result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
            if (x & 0x2000000000000 > 0)
                result = result * 0x1000162E525EE054754457D5995292026 >> 128;
            if (x & 0x1000000000000 > 0)
                result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
            if (x & 0x800000000000 > 0)
                result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
            if (x & 0x400000000000 > 0)
                result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
            if (x & 0x200000000000 > 0)
                result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
            if (x & 0x100000000000 > 0)
                result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
            if (x & 0x80000000000 > 0)
                result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
            if (x & 0x40000000000 > 0)
                result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
            if (x & 0x20000000000 > 0)
                result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
            if (x & 0x10000000000 > 0)
                result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
            if (x & 0x8000000000 > 0)
                result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
            if (x & 0x4000000000 > 0)
                result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
            if (x & 0x2000000000 > 0)
                result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
            if (x & 0x1000000000 > 0)
                result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
            if (x & 0x800000000 > 0)
                result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
            if (x & 0x400000000 > 0)
                result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
            if (x & 0x200000000 > 0)
                result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
            if (x & 0x100000000 > 0)
                result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
            if (x & 0x80000000 > 0)
                result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
            if (x & 0x40000000 > 0)
                result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
            if (x & 0x20000000 > 0)
                result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
            if (x & 0x10000000 > 0)
                result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
            if (x & 0x8000000 > 0)
                result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
            if (x & 0x4000000 > 0)
                result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
            if (x & 0x2000000 > 0)
                result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
            if (x & 0x1000000 > 0)
                result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
            if (x & 0x800000 > 0)
                result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
            if (x & 0x400000 > 0)
                result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
            if (x & 0x200000 > 0)
                result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
            if (x & 0x100000 > 0)
                result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
            if (x & 0x80000 > 0)
                result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
            if (x & 0x40000 > 0)
                result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
            if (x & 0x20000 > 0)
                result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
            if (x & 0x10000 > 0)
                result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
            if (x & 0x8000 > 0)
                result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
            if (x & 0x4000 > 0)
                result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
            if (x & 0x2000 > 0)
                result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
            if (x & 0x1000 > 0)
                result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
            if (x & 0x800 > 0)
                result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
            if (x & 0x400 > 0)
                result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
            if (x & 0x200 > 0)
                result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
            if (x & 0x100 > 0)
                result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
            if (x & 0x80 > 0)
                result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
            if (x & 0x40 > 0)
                result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
            if (x & 0x20 > 0)
                result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
            if (x & 0x10 > 0)
                result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
            if (x & 0x8 > 0)
                result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
            if (x & 0x4 > 0)
                result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
            if (x & 0x2 > 0)
                result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
            if (x & 0x1 > 0)
                result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

            result >>= uint256 (int256 (63 - (x >> 64)));
            require (result <= uint256 (int256 (MAX_64x64)));

            return int128 (int256 (result));
        }
    }

    // x in 18 decimals, y in 18 decimals
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        x *= UONE;
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // calculate x^y, x, y and return in 18 decimals
    function exp(uint256 x, int256 y) internal pure returns (int256) {
        int256 log2x = _log_2((x << 128) / UONE) * ONE >> 128;
        int256 p = log2x * y / ONE;
        return _exp_2(int256To128((p << 64) / ONE)) * ONE >> 64;
    }

    function getEverlastingTimeValue(int256 S, int256 K, int256 V, int256 T)
    internal pure returns (int256 timeValue, int256 u)
    {
        int256 u2 = ONE * 8 * ONE / V * ONE / V * ONE / T + ONE;
        u = utoi(sqrt(itou(u2)));

        uint256 x = itou(S * ONE / K);
        if (S > K) {
            timeValue = K * exp(x, (ONE - u) / 2) / u;
        } else if (S == K) {
            timeValue = K * ONE / u;
        } else {
            timeValue = K * exp(x, (ONE + u) / 2) / u;
        }
    }

    function getEverlastingTimeValueAndDelta(int256 S, int256 K, int256 V, int256 T)
    internal pure returns (int256 timeValue, int256 delta, int256 u)
    {
        int256 u2 = ONE * 8 * ONE / V * ONE / V * ONE / T + ONE;
        u = utoi(sqrt(itou(u2)));

        uint256 x = itou(S * ONE / K);
        if (S > K) {
            timeValue = K * exp(x, (ONE - u) / 2) / u;
            delta = (ONE - u) * timeValue / S / 2;
        } else if (S == K) {
            timeValue = K * ONE / u;
            delta = 0;
        } else {
            timeValue = K * exp(x, (ONE + u) / 2) / u;
            delta = (ONE + u) * timeValue / S / 2;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import './SafeMath.sol';
import "hardhat/console.sol";
library FuturesPricing {
    using SafeMath for uint256;
    using SafeMath for int256;
    int256 constant ONE = 1e18;

    function calculateMarkPrice(
        int256 indexPrice,
        int256 liquidity,
        int256 netVolume, // index price * net volume / 10 ** decimals
        int256 tradersVolume,
        int256 beta,
        int256 alpha,
        int256 decimals
    ) internal pure returns (int256)
    {
        // return indexPrice * (ONE + K * tradersVolume / ONE) / ONE;
        int256 bestPrice = calBestPrice(indexPrice, netVolume, liquidity, alpha, beta, tradersVolume, decimals);
        int256 baseAvgPrice = calBaseAveragePrice(indexPrice, netVolume, liquidity, tradersVolume, beta);
        // console.log("PRICE: ", bestPrice.itou(), baseAvgPrice.itou());
        return tradersVolume > 0 ? bestPrice.max(baseAvgPrice) : bestPrice.min(baseAvgPrice);
        // return bestPrice;
    }

    function calBestPrice(
        int256 indexPrice, int256 netVolume, int256 liquidity, int256 alpha, int256 beta, int256 tradersVolume, int256 decimals
    ) internal pure returns (int256) {
        int256 mid = tradersVolume > 0 ? ONE - alpha/ 2: ONE + alpha / 2;
        int256 end = ONE - beta * netVolume * indexPrice / liquidity / calDecimals(decimals);
        
        return indexPrice * mid * end / ONE / ONE;
    }

    function calBaseAveragePrice(
        int256 indexPrice, int256 netVolume, int256 liquidity, int256 tradersVolume, int256 beta
    ) internal pure returns (int256) {
        return (ONE - (beta * (2*netVolume-tradersVolume) * indexPrice / (2*liquidity)) / ONE) * indexPrice / ONE;
    }

    function calDecimals(int decimals) internal pure returns (int256) {
        uint256 percision = 10 ** decimals.itou();
        return percision.utoi();

    }



    function calculateMarkPrice(
        int256 indexPrice,
        int256 K,
        int256 tradersNetVolume
    ) internal pure returns (int256)
    {
        return indexPrice * (ONE + K * tradersNetVolume / ONE) / ONE;
    }


    // uint256 pi, uint256 mc, int256 piNet, uint256 beta, uint256 delta, 

    function calculateCost(
        int256 indexPrice,
        int256 K,
        int256 tradersNetVolume,
        int256 tradeVolume
    ) internal pure returns (int256)
    {
        int256 r = ((tradersNetVolume + tradeVolume) ** 2 - tradersNetVolume ** 2) / ONE * K / ONE / 2 + tradeVolume;
        return indexPrice * r / ONE;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../token/IERC20.sol";
import "./Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2 ** 255 - 1;
    int256  constant IMIN = -2 ** 255;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'SafeMath.utoi: overflow');
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'SafeMath.itou: underflow');
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'SafeMath.abs: overflow');
        return a >= 0 ? a : -a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

     // rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * 10**decimals2 / 10**decimals1;
    }

    // rescale towards zero
    // b: rescaled value in decimals2
    // c: the remainder
    function rescaleDown(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        c = a - rescale(b, decimals2, decimals1);
    }

    // rescale towards infinity
    // b: rescaled value in decimals2
    // c: the excessive
    function rescaleUp(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        uint256 d = rescale(b, decimals2, decimals1);
        if (d != a) {
            b += 1;
            c = rescale(b, decimals2, decimals1) - a;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import '../utils/Admin.sol';
import '../library/SafeMath.sol';
import '../library/SafeERC20.sol';
import '../pool/IPool.sol';
import '../token/IWETH.sol';
import "hardhat/console.sol";

contract Router is Admin {
    
    bool internal _mutex;
    modifier _reentryLock_() {
        require(!_mutex, 'Router: reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;


    address public weth;
    address public pool;
    address public alp;

    constructor(address _pool, address _weth, address _alp) public {
        pool = _pool;
        weth = _weth;
        alp = _alp;
    }


    function addLiquidity(address token, uint256 amount, uint256 minLp, IPool.OracleSignature[] memory oracleSignatures) external payable _reentryLock_ {
        require(amount > 0, "Router.addLiquidity: invalid amount");
        address underlying;
        uint256 addAmount;
        if(token != address(0)) {
            underlying = token;
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            underlying = weth;
            IWETH(underlying).deposit{value: msg.value}();
            require(amount == msg.value, "Router.addLiquidity: msg.value");
        }

        IERC20(underlying).approve(pool, amount);
            //address underlying, uint256 amount, uint256 minLp, address to, OracleSignature[] memory oracleSignatures
       uint256 amountOut = IPool(pool).addLiquidity(underlying, amount, oracleSignatures);
       require(amountOut >= minLp, "Router.addLiquidity: invalid amount out");
       IERC20(alp).safeTransfer(msg.sender, amountOut);
    }

    function removeLiquidity(address token, uint256 amount, uint256 minOut, IPool.OracleSignature[] memory oracleSignatures) external _reentryLock_{
        require(amount > 0, "RewardRouter: invalid _alpAmount");

        address account = msg.sender;
        IERC20(alp).safeTransferFrom(account, address(this), amount);
        IERC20(alp).approve(pool, amount);
        if(token != address(0)) {
            uint256 amountOut = IPool(pool).removeLiquidity(token, amount, oracleSignatures);
            require(amountOut >= minOut, "Router.removeLiquidity: invalid amount out");
            IERC20(token).safeTransfer(account, amountOut);
        } else {
            uint256 amountOut = IPool(pool).removeLiquidity(weth, amount, oracleSignatures);
            require(amountOut >= minOut, "Router.removeLiquidity: invalid amount out");
            IWETH(weth).withdraw(amountOut);
            (bool success, ) = payable(account).call{value: amountOut}('');
            require(success, 'PoolImplementation.transfer: send ETH fail');
        }
    }
    // function addMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external  _reentryLock_
    function addMargin(address token, uint256 amount, string memory symbolName, IPool.OracleSignature[] memory oracleSignatures) external payable _reentryLock_ {
        require(amount > 0, "Router.addLiquidity: invalid amount");
        address underlying;
        uint256 addAmount;
        if(token != address(0)) {
            underlying = token;
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            underlying = weth;
            IWETH(underlying).deposit{value: msg.value}();
            require(amount == msg.value, "Router.addLiquidity: msg.value");
        }

        IERC20(underlying).approve(pool, amount);
            //address underlying, uint256 amount, uint256 minLp, address to, OracleSignature[] memory oracleSignatures
        IPool(pool).addMargin(address(this), underlying, symbolName, amount, oracleSignatures);
    }

    function removeMargin(address token, uint256 amount, string memory symbolName, IPool.OracleSignature[] memory oracleSignatures) external _reentryLock_{
        require(amount > 0, "RewardRouter: invalid _alpAmount");


        address account = msg.sender;
        if(token != address(0)) {
            IPool(pool).removeMargin(address(this), token, symbolName, amount, oracleSignatures);
            IERC20(token).safeTransfer(account, amount);
        } else {
            IPool(pool).removeMargin(address(this), weth, symbolName, amount, oracleSignatures);
            IWETH(weth).withdraw(amount);
            (bool success, ) = payable(account).call{value: amount}('');
            require(success, 'PoolImplementation.transfer: send ETH fail');
        }
    }

    function transfer(address token, uint256 amount, string memory fromSymbolName, string memory toSymbolName, IPool.OracleSignature[] memory oracleSignatures) external payable _reentryLock_{
        require(amount > 0, "Router.transfer: invalid amount");
        address account = msg.sender;
        if(token != address(0)) {
            IPool(pool).removeMargin(account, token, fromSymbolName, amount, oracleSignatures);
            IERC20(token).safeTransfer(account, amount);

            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(token).approve(pool, amount);
            IPool(pool).addMargin(address(this), token, toSymbolName, amount, oracleSignatures);
        } else {
            IPool(pool).removeMargin(account, weth, fromSymbolName, amount, oracleSignatures);
            IWETH(weth).withdraw(amount);
            (bool success, ) = payable(account).call{value: amount}('');
            require(success, 'PoolImplementation.transfer: send ETH fail');

            IWETH(weth).deposit{value: msg.value}();
            require(amount == msg.value, "Router.transfer: msg.value");
            IERC20(weth).approve(pool, amount);
            IPool(pool).addMargin(address(this), weth, toSymbolName, amount, oracleSignatures);
        }
    }

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';

interface IOracle is INameVersion {

    function symbol() external view returns (string memory);

    function symbolId() external view returns (bytes32);

    function timestamp() external view returns (uint256);

    function value() external view returns (uint256);

    function getValue() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IOracleManager is INameVersion, IAdmin {

    event NewOracle(bytes32 indexed symbolId, address indexed oracle);

    event NewTokenOracle(address indexed token, address indexed oracle);

    // function getOracle(bytes32 symbolId) external view returns (address);

    function getOracle(string memory symbol) external view returns (address);

    function setOracle(address oracleAddress) external;

    function delOracle(bytes32 symbolId) external;

    function delOracle(string memory symbol) external;

    function value(bytes32 symbolId) external view returns (uint256);

    function getValue(bytes32 symbolId) external view returns (uint256);

    function updateValue(
        bytes32 symbolId,
        uint256 timestamp_,
        uint256 value_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool);

    function getTokenPrice(address token) external view returns (uint256);
    function setTokenOracle(address token, address oracleAddress) external;
    function delTokenOracle(address token) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';

interface IOracleOffChain is IOracle {

    event NewValue(uint256 indexed timestamp, uint256 indexed value);

    function signer() external view returns (address);

    function delayAllowance() external view returns (uint256);

    function updateValue(
        uint256 timestamp,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';
import '../library/SafeMath.sol';
import '../utils/NameVersion.sol';

contract OracleChainlink is IOracle, NameVersion {

    using SafeMath for int256;

    string  public symbol;
    bytes32 public immutable symbolId;

    IChainlinkFeed public immutable feed;
    uint256 public immutable feedDecimals;

    constructor (string memory symbol_, address feed_) NameVersion('OracleChainlink', '3.0.2') {
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));
        feed = IChainlinkFeed(feed_);
        feedDecimals = IChainlinkFeed(feed_).decimals();
    }

    function timestamp() external view returns (uint256) {
        (uint256 updatedAt, ) = _getLatestRoundData();
        return updatedAt;
    }

    function value() public view returns (uint256 val) {
        (, int256 answer) = _getLatestRoundData();
        val = answer.itou();
        if (feedDecimals != 18) {
            val *= 10 ** (18 - feedDecimals);
        }
    }

    function getValue() external view returns (uint256 val) {
        val = value();
    }

    function _getLatestRoundData() internal view returns (uint256, int256) {
        (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();
        require(answeredInRound >= roundId, 'OracleChainlink._getLatestRoundData: stale');
        require(updatedAt != 0, 'OracleChainlink._getLatestRoundData: incomplete round');
        require(answer > 0, 'OracleChainlink._getLatestRoundData: answer <= 0');
        return (updatedAt, answer);
    }

}

interface IChainlinkFeed {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';
import './IOracleOffChain.sol';
import './IOracleManager.sol';
import '../utils/NameVersion.sol';
import '../utils/Admin.sol';

contract OracleManager is IOracleManager, NameVersion, Admin {

    // symbolId => oracleAddress
    mapping (bytes32 => address) _oracles;

    mapping (address => address) _tokenOralcle;

    constructor () NameVersion('OracleManager', '3.0.1') {}

    // function getOracle(bytes32 symbolId) external view returns (address) {
    //     return _oracles[symbolId];
    // }

    function getOracle(string memory symbol) external view returns (address) {
        return _oracles[keccak256(abi.encodePacked(symbol))];
    }

    function setOracle(address oracleAddress) external _onlyAdmin_ {
        IOracle oracle = IOracle(oracleAddress);
        bytes32 symbolId = oracle.symbolId();
        _oracles[symbolId] = oracleAddress;
        emit NewOracle(symbolId, oracleAddress);
    }

    function delOracle(bytes32 symbolId) external _onlyAdmin_ {
        delete _oracles[symbolId];
        emit NewOracle(symbolId, address(0));
    }

    function delOracle(string memory symbol) external _onlyAdmin_ {
        bytes32 symbolId = keccak256(abi.encodePacked(symbol));
        delete _oracles[symbolId];
        emit NewOracle(symbolId, address(0));
    }

    function value(bytes32 symbolId) public view returns (uint256) {
        address oracle = _oracles[symbolId];
        require(oracle != address(0), 'OracleManager.value: no oracle');
        return IOracle(oracle).value();
    }

    function getValue(bytes32 symbolId) public view returns (uint256) {
        address oracle = _oracles[symbolId];
        require(oracle != address(0), 'OracleManager.getValue: no oracle');
        return IOracle(oracle).getValue();
    }

    function updateValue(
        bytes32 symbolId,
        uint256 timestamp_,
        uint256 value_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    ) public returns (bool) {
        address oracle = _oracles[symbolId];
        require(oracle != address(0), 'OracleManager.updateValue: no oracle');
        return IOracleOffChain(oracle).updateValue(timestamp_, value_, v_, r_, s_);
    }


    function setTokenOracle(address token, address oracleAddress) external _onlyAdmin_ {
        _tokenOralcle[token] = oracleAddress;
        getTokenPrice(token); // validate oracle
        emit NewTokenOracle(token,  oracleAddress);
    }

    function delTokenOracle(address token) external _onlyAdmin_ {
        delete _tokenOralcle[token];
        emit NewTokenOracle(token,  address(0));
    }

    function getTokenPrice(address token) public view returns (uint256) {
        address oracle = _tokenOralcle[token];
        require(oracle != address(0), 'OracleManager.getTokenPrice: token no oracle');
        return IOracle(oracle).getValue();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracleOffChain.sol';
import '../utils/NameVersion.sol';

contract OracleOffChain is IOracleOffChain, NameVersion {

    string  public symbol;
    bytes32 public immutable symbolId;
    address public immutable signer;
    uint256 public immutable delayAllowance;

    uint256 public timestamp;
    uint256 public value;

    constructor (string memory symbol_, address signer_, uint256 delayAllowance_) NameVersion('OracleOffChain', '3.0.1') {
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));
        signer = signer_;
        delayAllowance = delayAllowance_;
    }

    function getValue() external view returns (uint256 val) {
        if (block.timestamp >= timestamp + delayAllowance) {
            revert(string(abi.encodePacked(
                bytes('OracleOffChain.getValue: '), bytes(symbol), bytes(' expired')
            )));
        }
        require((val = value) != 0, 'OracleOffChain.getValue: 0');
    }

    function updateValue(
        uint256 timestamp_,
        uint256 value_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool)
    {
        uint256 lastTimestamp = timestamp;
        if (timestamp_ > lastTimestamp) {
            if (v_ == 27 || v_ == 28) {
                bytes32 message = keccak256(abi.encodePacked(symbolId, timestamp_, value_));
                bytes32 hash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', message));
                address signatory = ecrecover(hash, v_, r_, s_);
                if (signatory == signer) {
                    timestamp = timestamp_;
                    value = value_;
                    emit NewValue(timestamp_, value_);
                    return true;
                }
            }
        }
        return false;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';
import '../token/IERC20.sol';
import '../utils/NameVersion.sol';

contract OracleWoo is IOracle, NameVersion {

    string  public symbol;
    bytes32 public immutable symbolId;

    IWooracleV1 public immutable feed;
    uint256 public immutable baseDecimals;
    uint256 public immutable quoteDecimals;

    constructor (string memory symbol_, address feed_) NameVersion('OracleWoo', '3.0.1') {
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));
        feed = IWooracleV1(feed_);
        baseDecimals = IERC20(IWooracleV1(feed_)._BASE_TOKEN_()).decimals();
        quoteDecimals = IERC20(IWooracleV1(feed_)._QUOTE_TOKEN_()).decimals();
    }

    function timestamp() external pure returns (uint256) {
        revert('OracleWoo.timestamp: no timestamp');
    }

    function value() public view returns (uint256 val) {
        val = feed._I_();
        if (baseDecimals != quoteDecimals) {
            val = val * (10 ** baseDecimals) / (10 ** quoteDecimals);
        }
    }

    function getValue() external view returns (uint256 val) {
        require((val = value()) != 0, 'OracleWoo.getValue: 0');
    }

}

interface IWooracleV1 {
    function _BASE_TOKEN_() external view returns (address);
    function _QUOTE_TOKEN_() external view returns (address);
    function _I_() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../library/SafeMath.sol";
import "../token/IERC20.sol";
import "../library/SafeERC20.sol";
import "../symbol/ISymbolManager.sol";
import "../symbol/ISymbol.sol";
import "../pool/IPool.sol";
import "../lens/SymbolsLens.sol";

// import "../libraries/utils/ReentrancyGuard.sol";

// import "./interfaces/IRouter.sol";
// import "./interfaces/IVault.sol";
// import "./interfaces/IOrderBook.sol";

contract OrderBook {
    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;
    // using Address for address payable;

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, 'Pool: reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public constant USDA_PRECISION = 1e18;

    //string memory symbolName,
    // int256 tradeVolume,
    // uint256 _triggerPrice,
    // bool _triggerAboveThreshold
    struct TradeOrder {
        address account;
        string symbolName;
        int256 tradeVolume;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
        int256 priceLimit;
    }

    event CreateTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        int256 priceLimit
    );

    event UpdateTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        int256 priceLimit
    );

    event CancelTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        int256 priceLimit
    );

    event ExecuteTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 curentPrice
    );




    mapping (address => mapping(uint256 => TradeOrder)) public tradeOrders;
    mapping (address => uint256) public tradeOrdersIndex;

    address public gov;
    address public pool;
    address public symbolManager;
    uint256 public minExecutionFee;

    ISymbolsLens immutable symbolsLens;

    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateGov(address gov);

    modifier onlyGov() {
        require(msg.sender == gov, "OrderBook: forbidden");
        _;
    }

    constructor(
        address _pool,
        address _symbolManager,
        uint256 _minExecutionFee,
        address _symbolLens
    ) {
        gov = msg.sender;
        minExecutionFee = _minExecutionFee;
        symbolManager = _symbolManager;
        pool = _pool;
        // symbolLens = _symbolLens;
        symbolsLens = ISymbolsLens(_symbolLens);
    }

    // receive() external payable {
    //     require(msg.sender == weth, "OrderBook: invalid sender");
    // }
    

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyGov {
        minExecutionFee = _minExecutionFee;

        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;

        emit UpdateGov(_gov);
    }

    function cancelMultiple(
        uint256[] memory _tradeOrderIndexes
    ) external {
        for (uint256 i = 0; i < _tradeOrderIndexes.length; i++) {
            cancelTradeOrder(_tradeOrderIndexes[i]);
        }
    }
    
    function validatePositionOrderPrice(
        string memory symbol,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        bool _raise
    ) public view returns (uint256, bool) {
        // uint256 UMAX = 2 ** 255 - 1;
        uint256 currentPrice;
        // if(_triggerAboveThreshold) {
        //     return (0, true);
        // }
        // return (UMAX, true);
        ISymbolsLens.PriceAndVolatility[] memory pvs;
        ISymbolsLens.SymbolInfo memory info = symbolsLens.getSymbolInfo(pool, symbol, pvs);
        string memory futures = "futures";
        if (keccak256(abi.encodePacked(info.category)) == keccak256(abi.encodePacked(futures))) {
            currentPrice = info.curIndexPrice.itou();
        } else {
            currentPrice = info.theoreticalPrice.itou();
        }
        // uint256 currentPrice = IVault(vault).getMarketPrice(_indexToken, _sizeDelta, _maximizePrice);
        bool isPriceValid = _triggerAboveThreshold ? currentPrice > _triggerPrice : currentPrice < _triggerPrice;
        if (_raise) {
            require(isPriceValid, "OrderBook: invalid price for execution");
        }
        return (currentPrice, isPriceValid);
    }

    function createTradeOrder(
        string memory _symbolName,
        int256 _tradeVolume,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        int256 _priceLimit
    ) external payable _reentryLock_ {
        // always need this call because of mandatory executionFee user has to transfer in ETH
        // msg.value is execution fee
        require(msg.value >= minExecutionFee, "OrderBook: insufficient execution fee");
        bytes32 symbolId = keccak256(abi.encodePacked(_symbolName));
        address symbol = ISymbolManager(symbolManager).symbols(symbolId);
        require(symbol != address(0), 'OrderBook.createTradeOrder: invalid trade symbol');
        int256 minTradeVolume = ISymbol(symbol).minTradeVolume();
        require(
            _tradeVolume != 0 && _tradeVolume % minTradeVolume == 0,
            'OrderBook.createTradeOrder: invalid tradeVolume'
        );

        _createTradeOrder(
            msg.sender,
            _symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            _priceLimit,
            msg.value
        );
    }

    function _createTradeOrder(
        address _account,
        string memory _symbolName,
        int256 _tradeVolume,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        int256 _priceLimit,
        uint256 _executionFee
    ) private {
        uint256 _orderIndex = tradeOrdersIndex[_account];
        TradeOrder memory order = TradeOrder(
            _account,
            _symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            _priceLimit
        );
        tradeOrdersIndex[_account] = _orderIndex + 1;
        tradeOrders[_account][_orderIndex] = order;

        emit CreateTradeOrder(
            _account,
            _orderIndex,
            _symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            _priceLimit
        );
    }

    function getTradeOrder(address _account, uint256 _orderIndex) public view returns (
        string memory symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        int256 priceLimit
    ) {
        TradeOrder memory order = tradeOrders[_account][_orderIndex];
        return (
            order.symbolName,
            order.tradeVolume,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            order.priceLimit
        );
    }

    function updateTradeOrder(uint256 _orderIndex, int256 _tradeVolume, uint256 _triggerPrice, bool _triggerAboveThreshold, int256 _priceLimit) external  {
        TradeOrder storage order = tradeOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        order.triggerPrice = _triggerPrice;
        order.triggerAboveThreshold = _triggerAboveThreshold;
        order.tradeVolume = _tradeVolume;
        order.priceLimit = _priceLimit;

        emit UpdateTradeOrder(
            msg.sender,
            _orderIndex,
            order.symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            _priceLimit
        );
    }


    function cancelTradeOrder(uint256 _orderIndex) public _reentryLock_ {
        TradeOrder memory order = tradeOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        delete tradeOrders[msg.sender][_orderIndex];

        // if (order.purchaseToken == weth) {
        //     _transferOutETH(order.executionFee.add(order.purchaseTokenAmount), msg.sender);
        // } else {
            // IERC20(order.purchaseToken).safeTransfer(msg.sender, order.purchaseTokenAmount);
            // _transferOutETH(order.executionFee, msg.sender);
        // }

        _transferOutETH(order.executionFee, payable(msg.sender));

        emit CancelTradeOrder(
            order.account,
            _orderIndex,
            order.symbolName,
            order.tradeVolume,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            order.priceLimit
        );
    }


    function executeTradeOrder(address _address, uint256 _orderIndex, address payable _feeReceiver) external _reentryLock_ {
        TradeOrder memory order = tradeOrders[_address][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        // increase long should use max price
        // increase short should use min price
        (uint256 currentPrice, ) = validatePositionOrderPrice(
            order.symbolName,
            order.triggerPrice,
            order.triggerAboveThreshold,
            true
        );

        delete tradeOrders[_address][_orderIndex];
        IPool.OracleSignature[] memory oracleSignatures;
        IPool(pool).trade(order.account, order.symbolName, order.tradeVolume, order.priceLimit, oracleSignatures);

        // IERC20(order.purchaseToken).safeTransfer(vault, order.purchaseTokenAmount);

        // if (order.purchaseToken != order.collateralToken) {
        //     address[] memory path = new address[](2);
        //     path[0] = order.purchaseToken;
        //     path[1] = order.collateralToken;

        //     uint256 amountOut = _swap(path, 0, address(this));
        //     IERC20(order.collateralToken).safeTransfer(vault, amountOut);
        // }

        // IRouter(router).pluginIncreasePosition(order.account, order.collateralToken, order.indexToken, order.sizeDelta, order.isLong);

        // pay executor
        _transferOutETH(order.executionFee, _feeReceiver);

        emit ExecuteTradeOrder(
            order.account,
            _orderIndex,
            order.symbolName,
            order.tradeVolume,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            currentPrice
        );
    }

    // function _transferInETH() private {
    //     if (msg.value != 0) {
    //         IWETH(weth).deposit{value: msg.value}();
    //     }
    // }

    function _transferOutETH(uint256 _amountOut, address payable _receiver) private {
        // IWETH(weth).withdraw(_amountOut);

        (bool success, ) = _receiver.call{value: _amountOut}('');
        require(success, 'OrderBook.transfer: send ETH fail');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IPool is INameVersion, IAdmin {

    function implementation() external view returns (address);

    function protocolFeeCollector() external view returns (address);

    function liquidity() external view returns (int256);

    function lpsPnl() external view returns (int256);

    function cumulativePnlPerLiquidity() external view returns (int256);

    function protocolFeeAccrued() external view returns (int256);

    function setImplementation(address newImplementation) external;

    function addMarket(address token, address market) external;

    function getMarket(address token) external view returns (address);

    function changeSwapper(address swapper) external;

    function approveSwapper(address underlying) external;

    function collectProtocolFee() external;

    function claimVenusLp(address account) external;

    function claimVenusTrader(address account) external;

    struct OracleSignature {
        bytes32 oracleSymbolId;
        uint256 timestamp;
        uint256 value;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function addLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external returns (uint256);

    function removeLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external returns (uint256);

    function addMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function removeMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function trade(address account, string memory symbolName, int256 tradeVolume, int256 priceLimit, OracleSignature[] memory oracleSignatures) external;

    function liquidate(uint256 pTokenId, OracleSignature[] memory oracleSignatures) external;

    function transfer(address account, address underlying, string memory fromSymbolName, string memory toSymbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function addWhitelistedTokens(address _token) external;
    function removeWhitelistedTokens(address _token) external;
    function allWhitelistedTokens(uint256 index) external view returns (address);
    function allWhitelistedTokensLength() external view returns (uint256);
    function whitelistedTokens(address) external view returns (bool);
    function tokenPriceId(address) external view returns (bytes32);

    function getLiquidity() external view returns (uint256);

    function getTokenPrice(address token) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IPoolPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;

    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);
    function getDexPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function setTokenConfig(
        address _token,
        uint256 _decimals,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IPool.sol';
import './PoolStorage.sol';

contract Pool is PoolStorage {

    function setImplementation(address newImplementation) external _onlyAdmin_ {
        require(
            IPool(newImplementation).nameId() == keccak256(abi.encodePacked('PoolImplementation')),
            'Pool.setImplementation: not pool implementations'
        );
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

    function setProtocolFeeCollector(address newProtocolFeeCollector) external _onlyAdmin_ {
        protocolFeeCollector = newProtocolFeeCollector;
        emit NewProtocolFeeCollector(newProtocolFeeCollector);
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {

    }

    function _delegate() internal {
        address imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../token/IERC20.sol';
import '../token/IDToken.sol';
import '../token/IWETH.sol';
import '../vault/IVToken.sol';
import '../vault/IVault.sol';
import '../oracle/IOracleManager.sol';
import '../swapper/ISwapper.sol';
import '../symbol/ISymbolManager.sol';
import './PoolStorage.sol';
import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';
import '../library/SafeERC20.sol';
import '../token/IMintableToken.sol';
import '../token/IWETH.sol';

contract PoolImplementation is PoolStorage, NameVersion {

    event CollectProtocolFee(address indexed collector, uint256 amount);

    event AddMarket(address indexed market);

    // event AddLiquidity(
    //     uint256 indexed lTokenId,
    //     address indexed underlying,
    //     uint256 amount,
    //     int256 newLiquidity
    // );

    event AddLiquidity(
        address token,
        uint256 amount,
        int256 liquidity,
        uint256 lpSupply,
        uint256 usdAmount,
        uint256 mintAmount
    );

    event RemoveLiquidity(
        address token,
        uint256 lpAmount,
        int256 liquidity,
        uint256 lpSupply,
        uint256 usdAmount,
        uint256 amountOut
    );

    // event RemoveLiquidity(
    //     uint256 indexed lTokenId,
    //     address indexed underlying,
    //     uint256 amount,
    //     int256 newLiquidity
    // );

    event AddMargin(
        address indexed account,
        string sumbol,
        address indexed underlying,
        uint256 amount,
        int256 newMargin
    );

    event RemoveMargin(
        address indexed account,
        string sumbol,
        address indexed underlying,
        uint256 amount,
        int256 newMargin
    );

    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    int256 constant ONE = 1e18;
    uint256 constant UONE = 1e18;
    uint256 constant UMAX = type(uint256).max / UONE;

    address public immutable vaultTemplate;

    address public immutable vaultImplementation;

    address public immutable tokenB0;

    address public immutable tokenWETH;

    // address public immutable vTokenB0;

    // address public immutable vTokenETH;

    // IDToken public immutable lToken;

    // IDToken public immutable pToken;

    IOracleManager public immutable oracleManager;

    ISwapper public swapper;

    ISymbolManager public immutable symbolManager;

    uint256 public immutable reserveRatioB0;

    int256 public immutable minRatioB0;

    int256 public immutable poolInitialMarginMultiplier;

    int256 public immutable protocolFeeCollectRatio;

    int256 public immutable minLiquidationReward;

    int256 public immutable maxLiquidationReward;

    int256 public immutable liquidationRewardCutRatio;

    address[] public allWhitelistedTokens;
    mapping (address => bool) public whitelistedTokens;
    mapping (address => bytes32) public tokenPriceId;
    mapping (address => bool) public isPoolManager;

    uint256 public constant mintFeeBasisPoints = 30; // 0.2%
    uint256 public constant burnFeeBasisPoints = 30; // 0.3%
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address public immutable lpTokenAddress;
    address public immutable lpVault;

    modifier onlyManager() {
        require(isPoolManager[msg.sender] , 'Pool: reentry');
        _;
    }

    constructor (
        address[8] memory addresses_,
        uint256[7] memory parameters_
    ) NameVersion('PoolImplementation', '3.0.2')
    {
        vaultTemplate = addresses_[0];
        vaultImplementation = addresses_[1];
        tokenB0 = addresses_[2];
        tokenWETH = addresses_[3];
        // vTokenB0 = addresses_[4];
        // vTokenETH = addresses_[5];
        // lToken = IDToken(addresses_[6]);
        // pToken = IDToken(addresses_[7]);
        oracleManager = IOracleManager(addresses_[4]);
        swapper = ISwapper(addresses_[5]);
        symbolManager = ISymbolManager(addresses_[6]);
        
        lpTokenAddress = addresses_[7];

        reserveRatioB0 = parameters_[0];
        minRatioB0 = parameters_[1].utoi();
        poolInitialMarginMultiplier = parameters_[2].utoi();
        protocolFeeCollectRatio = parameters_[3].utoi();
        minLiquidationReward = parameters_[4].utoi();
        maxLiquidationReward = parameters_[5].utoi();
        liquidationRewardCutRatio = parameters_[6].utoi();

        lpVault = _clone(vaultTemplate);

        require(
            IERC20(tokenB0).decimals() == 18 && IERC20(tokenWETH).decimals() == 18,
            'PoolImplementation.constant: only token of decimals 18'
        );
    }

    function getMarket(address token) external view returns(address) {
        return markets[token];
    }

    function getUserVault(address account, string memory symbolName) external view returns(address) {
        bytes32 vaultId = keccak256(abi.encodePacked(account, symbolName));
        return userVault[vaultId];
    }

    function addMarket(address token, address market) external _onlyAdmin_ {
        // underlying is the underlying token of Venus market
        // address underlying = IVToken(market).underlying();
        require(
            IERC20(token).decimals() == 18,
            'PoolImplementation.addMarket: only token of decimals 18'
        );
        // require(
        //     IVToken(market).isVToken(),
        //     'PoolImplementation.addMarket: invalid vToken'
        // );
        // require(
        //     IVToken(market).comptroller() == IVault(vaultImplementation).comptroller(),
        //     'PoolImplementation.addMarket: wrong comptroller'
        // );
        // require(
        //     swapper.isSupportedToken(underlying),
        //     'PoolImplementation.addMarket: no swapper support'
        // );
        require(
            markets[token] == address(0),
            'PoolImplementation.addMarket: replace not allowed'
        );
        markets[token] = market;
        approveSwapper(token);

        emit AddMarket(market);
    }

    function addWhitelistedTokens(address token, string memory priceSumbolId) external _onlyAdmin_ {
        require(
            !whitelistedTokens[token], 
            "PoolImplementation.addWhitelistedTokens: already in whitelisted"
        );
        allWhitelistedTokens.push(token);
        whitelistedTokens[token] = true;
        tokenPriceId[token] = keccak256(abi.encodePacked(priceSumbolId));
        getTokenPrice(token);
    }

    function removeWhitelistedTokens(address token) external _onlyAdmin_ {
        require(
            whitelistedTokens[token], 
            "PoolImplementation.addWhitelistedTokens: token is not in whitelisted"
        );
        uint256 length = allWhitelistedTokens.length;

        for(uint256 i=0; i < length ; i++) {
            if(allWhitelistedTokens[i] == token) {
                allWhitelistedTokens[i] = allWhitelistedTokens[length-1];
                allWhitelistedTokens.pop();
                whitelistedTokens[token] = false;
                break;
            }
        }
        tokenPriceId[token] = 0;
    }

    function allWhitelistedTokensLength() external view  returns (uint256) {
        return allWhitelistedTokens.length;
    }

    function getTokenPrice(address token) public view returns (uint256) {
        bytes32 priceId = tokenPriceId[token];
        require(priceId !=0, "PoolImplementation.getTokenPrice: invalid price id");
        return oracleManager.getValue(priceId);
    }

    function getTokenPriceId(address token) public view returns (bytes32) {
        bytes32 priceId = tokenPriceId[token];
        require(priceId !=0, "PoolImplementation.getTokenPriceId: invalid price id");
        return priceId;
    }

    function approvePoolManager(address manager) public _onlyAdmin_ {
        uint256 length = allWhitelistedTokens.length;
        for(uint256 i=0; i < length; i++) {
            address token = allWhitelistedTokens[i];

            require( token != address(0) , "PoolImplementation.approvePoolManager: token is not in whitelisted");
            require( whitelistedTokens[token] , "PoolImplementation.approvePoolManager: token is not in whitelisted");
            uint256 allowance = IERC20(token).allowance(address(this), address(manager));
            if (allowance != type(uint256).max) {
                if (allowance != 0) {
                    IERC20(token).safeApprove(address(manager), 0);
                }
                IERC20(token).safeApprove(address(manager), type(uint256).max);
            }   
        }
        isPoolManager[manager] = true;
    }

    function approveSwapper(address underlying) public _onlyAdmin_ {
        uint256 allowance = IERC20(underlying).allowance(address(this), address(swapper));
        if (allowance != type(uint256).max) {
            if (allowance != 0) {
                IERC20(underlying).safeApprove(address(swapper), 0);
            }
            IERC20(underlying).safeApprove(address(swapper), type(uint256).max);
        }
    }
    

    function collectProtocolFee() external _onlyAdmin_ {
        require(protocolFeeCollector != address(0), 'PoolImplementation.collectProtocolFee: collector not set');
        uint256 amount = protocolFeeAccrued.itou();
        protocolFeeAccrued = 0;
        IERC20(tokenB0).safeTransfer(protocolFeeCollector, amount);
        emit CollectProtocolFee(protocolFeeCollector, amount);
    }

    // function claimVenusLp(address account) external {
    //     uint256 lTokenId = lToken.getTokenIdOf(account);
    //     if (lTokenId != 0) {
    //         IVault(lpInfos[lTokenId].vault).claimVenus(account);
    //     }
    // }

    // function claimVenusTrader(address account) external {
    //     uint256 pTokenId = pToken.getTokenIdOf(account);
    //     if (pTokenId != 0) {
    //         // IVault(tdInfos[pTokenId].vault).claimVenus(account);
    //     }
    // }

    //================================================================================

    // function addLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external payable _reentryLock_
    // {
    //     _updateOracles(oracleSignatures);

    //     if (underlying == address(0)) amount = msg.value;

    //     Data memory data = _initializeData(underlying);
    //     _getLpInfo(data, true);

    //     ISymbolManager.SettlementOnAddLiquidity memory s =
    //     symbolManager.settleSymbolsOnAddLiquidity(data.liquidity + data.lpsPnl);

    //     int256 undistributedPnl = s.funding - s.deltaTradersPnl;
    //     if (undistributedPnl != 0) {
    //         data.lpsPnl += undistributedPnl;
    //         data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;
    //     }

    //     // _settleLp(data);
    //     _transferIn(data, amount);

    //     int256 newLiquidity = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;
    //     data.liquidity += newLiquidity - data.lpLiquidity;
    //     data.lpLiquidity = newLiquidity;

    //     require(
    //         IERC20(tokenB0).balanceOf(address(this)).utoi() * ONE >= data.liquidity * minRatioB0,
    //         'PoolImplementation.addLiquidity: insufficient B0'
    //     );

    //     liquidity = data.liquidity;
    //     lpsPnl = data.lpsPnl;
    //     cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

    //     LpInfo storage info = lpInfos[data.tokenId];
    //     info.vault = data.vault;
    //     info.amountB0 = data.amountB0;
    //     info.liquidity = data.lpLiquidity;
    //     info.cumulativePnlPerLiquidity = data.lpCumulativePnlPerLiquidity;

    //     emit AddLiquidity(data.tokenId, underlying, amount, newLiquidity);
    // }

    function getTokenToUsd(address token, uint256 amount) public view returns (uint256) {
        uint256 price = getTokenPrice(token);
        uint256 deccimals = IERC20(token).decimals();
        return  amount * price / 10**deccimals;
    }

    function getUsdToToken(address token, uint256 amountUsd) public view returns (uint256) {
        uint256 price = getTokenPrice(token);
        uint256 deccimals = IERC20(token).decimals();
        return  amountUsd * 10 ** deccimals / price ;
    }

    function changeSwapper(address _swapper) external _onlyAdmin_ {
        swapper = ISwapper(_swapper);
    }

    function addLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_ returns (uint256)
    {
        _updateOracles(oracleSignatures);
        require(whitelistedTokens[underlying], "PoolImplementation: token not in whitelisted");
        Data memory data = _initializeData(msg.sender);
        // _getLpInfo(data, true);

        ISymbolManager.SettlementOnAddLiquidity memory s =
        symbolManager.settleSymbolsOnAddLiquidity(data.liquidity + data.lpsPnl);
        // {
        //     int256 undistributedPnl = s.funding - s.deltaTradersPnl;
        //     if (undistributedPnl != 0) {
        //         data.lpsPnl += undistributedPnl;
        //         // data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;
        //     }
        // }

        data.lpsPnl += s.funding - s.deltaTradersPnl;
        

        uint256 feeAmount = amount * mintFeeBasisPoints / BASIS_POINTS_DIVISOR;

        uint256 amountUsd = getTokenToUsd(underlying, amount-feeAmount);

        int256 availableLiquidity = data.liquidity + data.lpsPnl; 
        uint256 lpSupply = IERC20(lpTokenAddress).totalSupply();
        uint256 mintAmount = availableLiquidity == 0 ? amountUsd : amountUsd * lpSupply / availableLiquidity.itou();
        IMintableToken(lpTokenAddress).mint(msg.sender, mintAmount);

        // uint256 amountOut = _mintLiquidity(data, msg.sender, amountUsd);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(underlying).safeTransfer(lpVault, amount-feeAmount);
        // IVault(lpVault).supply(underlying, amount-feeAmount);
        IERC20(underlying).safeTransfer(protocolFeeCollector, feeAmount);
        // require(mintAmount >= minLp, "PoolImplementation.addLiquidity: invalid amount out");
        lpsPnl = data.lpsPnl;
        // emit AddLiquidity(data.tokenId, underlying, amount, newLiquidity);
        emit AddLiquidity(underlying, amount, availableLiquidity, lpSupply, amountUsd, mintAmount);
        return mintAmount;
    }

    // function addLiquidityV2(address token, uint256 amount, uint256 minLp) external payable _reentryLock_ {

    //     if(token == address(0)) {
    //         IWETH(tokenWETH).deposit{value: msg.value}();
    //         token = tokenWETH;
    //         amount = msg.value;
    //     }
    //     require(whitelistedTokens[token], "PoolImplementation: token not in whitelisted");
    //     uint256 price = getTokenPrice(token);
       
    //     uint256 deccimals = IERC20(token).decimals();

    //     uint256 feeAmount = amount * mintFeeBasisPoints / BASIS_POINTS_DIVISOR;

    //     uint256 amountUsd = (amount-feeAmount) * price / 10**deccimals;
    //     uint256 amountOut = _mintLiquidity(data, msg.sender, amountUsd);
    //     IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    //     _transfer(token, protocolFeeCollector, feeAmount);
    //     require(amountOut >= minLp, "PoolImplementation.addLiquidity: invalid amount out");
    // }

    // function removeLiquidityV2(address tokenOut, uint256 lpAmount, uint256 minAmountOut) external _reentryLock_ { 

    //     require(whitelistedTokens[tokenOut], "PoolImplementation: token not in whitelisted");
    //     // IERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), lpAmount);
    //     uint256 amountOutUsd = _burnLiquidity(msg.sender, lpAmount);
    //     uint256 price = getTokenPrice(tokenOut);
    //     uint256 deccimals = IERC20(tokenOut).decimals();

    //     uint256 tokenOutAmount = amountOutUsd * 10 ** deccimals / price ;
    //     uint256 feeAmount = tokenOutAmount * burnFeeBasisPoints / BASIS_POINTS_DIVISOR;
    //     require(tokenOutAmount-feeAmount > minAmountOut, "PoolImplementation.removeLiquidity: invalid amount out");
    //     require(tokenOutAmount-feeAmount > 0, "PoolImplementation.removeLiquidity: invalid amount out2");
    //     _transfer(tokenOut, msg.sender, tokenOutAmount-feeAmount);
    //     _transfer(tokenOut, protocolFeeCollector, feeAmount);

    // }

    function removeLiquidity(address underlying, uint256 lpAmount, OracleSignature[] memory oracleSignatures) external _reentryLock_ returns (uint256)
    {
        _updateOracles(oracleSignatures);

        Data memory data = _initializeData(msg.sender);

        require(whitelistedTokens[underlying], "PoolImplementation: token not in whitelisted");
        
        int256 availableLiquidity = data.liquidity + data.lpsPnl;
        uint256 lpSupply = IERC20(lpTokenAddress).totalSupply();
        IMintableToken(lpTokenAddress).burn(msg.sender, lpAmount);
        uint256 amountOutUsd = lpAmount *  availableLiquidity.itou() / lpSupply;
        ISymbolManager.SettlementOnRemoveLiquidity memory s =
        symbolManager.settleSymbolsOnRemoveLiquidity(data.liquidity + data.lpsPnl, amountOutUsd.utoi());

        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.removeLiquidityPenalty;
        data.lpsPnl += undistributedPnl;

        uint256 tokenOutAmount = getUsdToToken(underlying, amountOutUsd) ;
        uint256 feeAmount = tokenOutAmount * burnFeeBasisPoints / BASIS_POINTS_DIVISOR;
        // require(tokenOutAmount-feeAmount > minAmountOut, "PoolImplementation.removeLiquidity: invalid amount out");
        require(tokenOutAmount-feeAmount > 0, "PoolImplementation.removeLiquidity: invalid amount out2");
        require(
            data.liquidity * ONE >= s.initialMarginRequired * poolInitialMarginMultiplier,
            'PoolImplementation.removeLiquidity: pool insufficient liquidity'
        );

        IVault v = IVault(lpVault);
        // v.withdraw(underlying, tokenOutAmount);
        v.transfer(underlying,  msg.sender, tokenOutAmount-feeAmount);
        v.transfer(underlying, protocolFeeCollector, feeAmount);
        // _transfer(underlying, protocolFeeCollector, feeAmount);

        lpsPnl = data.lpsPnl;
        

        // emit RemoveLiquidity(data.tokenId, underlying, lpAmount, newLiquidity);
        emit RemoveLiquidity(underlying, lpAmount, availableLiquidity, lpSupply, amountOutUsd, tokenOutAmount-feeAmount);
        return tokenOutAmount-feeAmount;
    }

    // function _mintLiquidity(Data memory data, address to, uint256 amountUsd) private returns (uint256) {
    //     int256 availableLiquidity = (data.liquidity + data.lpsPnl); 
    //     uint256 lpSupply = IERC20(lpTokenAddress).totalSupply();
    //     uint256 mintAmount = availableLiquidity == 0 ? amountUsd : amountUsd * lpSupply / availableLiquidity.itou();
    //     IMintableToken(lpTokenAddress).mint(to, mintAmount);
    //     return mintAmount;
    // }

    // function _burnLiquidity(address from, uint256 lpAmount) private returns (uint256) {
    //     uint256 aum = IVault(lpVault).getVaultLiquidity();
    //     uint256 lpSupply = IERC20(lpTokenAddress).totalSupply();
    //     IMintableToken(lpTokenAddress).burn(from, lpAmount);
    //     return lpAmount *  aum / lpSupply;
    // }

    // function _collectMintFee(address token, uint256 amount) private {
        

    // }

    function getLiquidity() public view returns (uint256) {
        return IVault(lpVault).getVaultLiquidity();
    }



    // function removeLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_
    // {
    //     _updateOracles(oracleSignatures);

    //     Data memory data = _initializeData(underlying);
    //     _getLpInfo(data, false);

    //     int256 removedLiquidity;
    //     (uint256 vTokenBalance, uint256 underlyingBalance) = IVault(data.vault).getBalances(data.market);
    //     if (underlying == tokenB0) {
    //         int256 available = underlyingBalance.utoi() + data.amountB0;
    //         if (available > 0) {
    //             removedLiquidity = amount >= available.itou() ? available : amount.utoi();
    //         }
    //     } else if (underlyingBalance > 0) {
    //         uint256 redeemAmount = amount >= underlyingBalance ?
    //                                vTokenBalance :
    //                                vTokenBalance * amount / underlyingBalance;
    //         uint256 bl1 = IVault(data.vault).getVaultLiquidity();
    //         uint256 bl2 = IVault(data.vault).getHypotheticalVaultLiquidity(data.market, redeemAmount);
    //         removedLiquidity = (bl1 - bl2).utoi();
    //     }

    //     ISymbolManager.SettlementOnRemoveLiquidity memory s =
    //     symbolManager.settleSymbolsOnRemoveLiquidity(data.liquidity + data.lpsPnl, removedLiquidity);

    //     int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.removeLiquidityPenalty;
    //     data.lpsPnl += undistributedPnl;
    //     data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;
    //     data.amountB0 -= s.removeLiquidityPenalty;

    //     _settleLp(data);
    //     uint256 newVaultLiquidity = _transferOut(data, amount, vTokenBalance, underlyingBalance);

    //     int256 newLiquidity = newVaultLiquidity.utoi() + data.amountB0;
    //     data.liquidity += newLiquidity - data.lpLiquidity;
    //     data.lpLiquidity = newLiquidity;

    //     require(
    //         data.liquidity * ONE >= s.initialMarginRequired * poolInitialMarginMultiplier,
    //         'PoolImplementation.removeLiquidity: pool insufficient liquidity'
    //     );

    //     liquidity = data.liquidity;
    //     lpsPnl = data.lpsPnl;
    //     cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

    //     LpInfo storage info = lpInfos[data.tokenId];
    //     info.amountB0 = data.amountB0;
    //     info.liquidity = data.lpLiquidity;
    //     info.cumulativePnlPerLiquidity = data.lpCumulativePnlPerLiquidity;

    //     emit RemoveLiquidity(data.tokenId, underlying, amount, newLiquidity);
    // }

    function addMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external  _reentryLock_
    {
        _updateOracles(oracleSignatures);

        require(msg.sender == account || isPoolManager[msg.sender],  "PoolImplementation: only manager");

        Data memory data;
        data.underlying = underlying;
        // data.market = _getMarket(underlying);
        data.account = account;
        // bytes32 symbolId = keccak256(abi.encodePacked(symbolName));
        _getTdInfo(data, symbolName, true);
        _transferIn(data, amount);

        int256 newMargin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        // TdInfo storage info = tdInfos[data.tokenId];
        // info.vault = data.vault;
        // info.amountB0 = data.amountB0;
        bytes32 vaultId = keccak256(abi.encodePacked(data.account, symbolName));
        userAmountB0[vaultId] = data.amountB0;

        emit AddMargin(data.account, symbolName, underlying, amount, newMargin);
    }

    function removeMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        _updateOracles(oracleSignatures);

        // if user not call the contract directly, he/she must call it by pool manager/router
        require(msg.sender == account || isPoolManager[msg.sender],  "PoolImplementation: only manager");

        Data memory data = _initializeData(underlying, account);
        _getTdInfo(data, symbolName, false);
        
        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));
        ISymbolManager.SettlementOnRemoveMargin memory s =
        symbolManager.settleSymbolsOnRemoveMargin(data.account, symbolId, data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl;
        data.lpsPnl += undistributedPnl;
        // data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        data.amountB0 -= s.traderFunding;

        // (uint256 vTokenBalance, uint256 underlyingBalance) = IVault(data.vault).getBalances(data.market);
        // IVault(data.vault).withdraw(data.underlying, amount);

        uint256 newVaultLiquidity = _transferOut(data, amount);
        // IVault(data.vault).transfer(data.underlying, msg.sender, amount);
        // uint256 newVaultLiquidity = IVault(data.vault).getVaultLiquidity();

        require(
            newVaultLiquidity.utoi() + data.amountB0 + s.traderPnl >= s.traderInitialMarginRequired,
            'PoolImplementation.removeMargin: insufficient margin'
        );

        lpsPnl = data.lpsPnl;
        // cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        bytes32 vaultId = keccak256(abi.encodePacked(data.account, symbolName));
        userAmountB0[vaultId] = data.amountB0;
        // tdInfos[data.tokenId].amountB0 = data.amountB0;

        emit RemoveMargin(data.account, symbolName, underlying, amount, newVaultLiquidity.utoi() + data.amountB0);
    }

    function trade(address account, string memory symbolName, int256 tradeVolume, int256 priceLimit, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        
        _updateOracles(oracleSignatures);

        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));

        Data memory data = _initializeData(account);
        _getTdInfo(data, symbolName, false);

        ISymbolManager.SettlementOnTrade memory s =
        symbolManager.settleSymbolsOnTrade(data.account, symbolId, tradeVolume, data.liquidity + data.lpsPnl, priceLimit);

        int256 collect = s.tradeFee * protocolFeeCollectRatio / ONE;
        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.tradeFee - collect + s.tradeRealizedCost;
        data.lpsPnl += undistributedPnl;
        // data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        data.amountB0 -= s.traderFunding + s.tradeFee + s.tradeRealizedCost;
        int256 margin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;
        int256 availableMargin = s.traderPnl < 0 ? margin + s.traderPnl : margin;
        // require(
        //     (data.liquidity + data.lpsPnl) * ONE >= s.initialMarginRequired * poolInitialMarginMultiplier,
        //     'PoolImplementation.trade: pool insufficient liquidity'
        // );
        // check margin is enough to use as collateral
        require(
            availableMargin > s.marginRequired,
            // Strings.toString(availableMargin.abs().itou())
            'PoolImplementation.trade: insufficient margin'
        );

        lpsPnl = data.lpsPnl;
        // cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;
        protocolFeeAccrued += collect;

        bytes32 vaultId = keccak256(abi.encodePacked(data.account, symbolName));
        userAmountB0[vaultId] = data.amountB0;
        // tdInfos[data.tokenId].amountB0 = data.amountB0;
    }

    function liquidate(address account, string memory symbolName, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        _updateOracles(oracleSignatures);

        // require(
        //     pToken.exists(pTokenId),
        //     'PoolImplementation.liquidate: nonexistent pTokenId'
        // );

        Data memory data = _initializeData(account);
        
        // data.vault = tdInfos[pTokenId].vault;
        // data.amountB0 = tdInfos[pTokenId].amountB0;
        _getTdInfo(data, symbolName, false);
        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));
        bytes32 vaultId = keccak256(abi.encodePacked(data.account, symbolName));
        data.vault = userVault[vaultId];

        ISymbolManager.SettlementOnLiquidate memory s =
        symbolManager.settleSymbolsOnLiquidate(account, symbolId, data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.traderRealizedCost;

        data.amountB0 -= s.traderFunding;
        int256 margin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;
        int256 availableMargin = s.traderPnl < 0 ? margin + s.traderPnl : margin;
        require(
            s.traderMaintenanceMarginRequired > 0,
            'PoolImplementation.liquidate: no position'
        );
        require(
            availableMargin < 0,
            'PoolImplementation.liquidate: cannot liquidate'
        );

        data.amountB0 -= s.traderRealizedCost;

        IVault v = IVault(data.vault);
        // address[] memory inMarkets = v.getMarketsIn();
        uint256 length = allWhitelistedTokens.length;

        for (uint256 i = 0; i < length; i++) {
            // address market = inMarkets[i];
            // uint256 balance = IVToken(market).balanceOf(data.vault);
            address token = allWhitelistedTokens[i];
            uint256 balance;
            if( token == address(0)){
                balance = IWETH(token).balanceOf(data.vault);
            }else{
                balance = IERC20(token).balanceOf(data.vault);
            }

            if (balance > 0) {
                // address underlying = _getUnderlying(market);
                // v.redeem(market, balance);
                balance = v.transferAll(token, address(this));
                if (token == address(0)) {
                    (uint256 resultB0, ) = swapper.swapExactETHForB0{value: balance}();
                    data.amountB0 += resultB0.utoi();
                } else if (token == tokenB0) {
                    data.amountB0 += balance.utoi();
                } else {
                    IERC20(token).safeTransfer(address(swapper),balance);
                    (uint256 resultB0, ) = swapper.swapExactBXForB0(token, balance);
                    data.amountB0 += resultB0.utoi();
                }
            }
        }

        int256 reward;
        if (data.amountB0 <= minLiquidationReward) {
            reward = minLiquidationReward;
        } else {
            reward = (data.amountB0 - minLiquidationReward) * liquidationRewardCutRatio / ONE + minLiquidationReward;
            reward = reward.min(maxLiquidationReward);
        }

        undistributedPnl += data.amountB0 - reward;
        data.lpsPnl += undistributedPnl;
        // data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        _transfer(tokenB0, msg.sender, reward.itou());

        lpsPnl = data.lpsPnl;
        // cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        // tdInfos[pTokenId].amountB0 = 0;
    }

    function transfer(address account, address underlying, string memory fromSymbolName, string memory toSymbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        _updateOracles(oracleSignatures);
        // if user not call the contract directly, he/she must call it by pool manager/router
        require(msg.sender == account || isPoolManager[msg.sender],  "PoolImplementation: only manager");

        Data memory data = _initializeData(underlying, account);
        bytes32 symbolId = keccak256(abi.encodePacked(fromSymbolName));
        _getTdInfo(data, fromSymbolName, false);
        ISymbolManager.SettlementOnRemoveMargin memory s =
        symbolManager.settleSymbolsOnRemoveMargin(data.account, symbolId, data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl;
        data.lpsPnl += undistributedPnl;
        data.amountB0 -= s.traderFunding;

        IVault(data.vault).transfer(data.underlying, msg.sender, amount);
        uint256 newVaultLiquidity = IVault(data.vault).getVaultLiquidity();
        require(
            newVaultLiquidity.utoi() + data.amountB0 + s.traderPnl >= s.traderInitialMarginRequired,
            'PoolImplementation.transfer: insufficient margin'
        );

        lpsPnl = data.lpsPnl;
        emit RemoveMargin(data.account, fromSymbolName, underlying, amount, newVaultLiquidity.utoi() + data.amountB0);

        Data memory _data;
        _data.underlying = underlying;
        _data.account = account;
        _getTdInfo(_data, toSymbolName, true);
        _transferIn(_data, amount);
        int256 newMargin = IVault(_data.vault).getVaultLiquidity().utoi() + _data.amountB0;

        emit AddMargin(data.account, toSymbolName, underlying, amount, newMargin);
    }

    //================================================================================

    struct OracleSignature {
        bytes32 oracleSymbolId;
        uint256 timestamp;
        uint256 value;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function _updateOracles(OracleSignature[] memory oracleSignatures) internal {
        for (uint256 i = 0; i < oracleSignatures.length; i++) {
            OracleSignature memory signature = oracleSignatures[i];
            oracleManager.updateValue(
                signature.oracleSymbolId,
                signature.timestamp,
                signature.value,
                signature.v,
                signature.r,
                signature.s
            );
        }
    }

    struct Data {
        int256 liquidity;
        int256 lpsPnl;
        int256 cumulativePnlPerLiquidity;

        address underlying;
        address market;

        address account;
        uint256 tokenId;
        address vault;
        int256 amountB0;
        int256 lpLiquidity;
        int256 lpCumulativePnlPerLiquidity;
    }

    function _initializeData(address account) internal view returns (Data memory data) {
        data.liquidity = IVault(lpVault).getVaultLiquidity().utoi();
        data.lpsPnl = lpsPnl;
        // data.cumulativePnlPerLiquidity = cumulativePnlPerLiquidity;
        data.account = account;
    }

    function _initializeData(address underlying, address account) internal view returns (Data memory data) {
        data = _initializeData(account);
        data.underlying = underlying;
        // data.market = _getMarket(underlying);
    }

    // function _getMarket(address underlying) internal view returns (address market) {
    //     if (underlying == address(0)) {
    //         market = vTokenETH;
    //     } else if (underlying == tokenB0) {
    //         market = vTokenB0;
    //     } else {
    //         market = markets[underlying];
    //         require(
    //             market != address(0),
    //             'PoolImplementation.getMarket: unsupported market'
    //         );
    //     }
    // }

    // function _getUnderlying(address market) internal view returns (address underlying) {
    //     if (market == vTokenB0) {
    //         underlying = tokenB0;
    //     } else if (market == vTokenETH) {
    //         underlying = address(0);
    //     } else {
    //         underlying = IVToken(market).underlying();
    //     }
    // }

    // function _getLpInfo(Data memory data, bool createOnDemand) internal {
    //     data.tokenId = lToken.getTokenIdOf(data.account);
    //     if (data.tokenId == 0) {
    //         require(createOnDemand, 'PoolImplementation.getLpInfo: not LP');
    //         data.tokenId = lToken.mint(data.account);
    //         data.vault = _clone(vaultTemplate);
    //     } else {
    //         LpInfo storage info = lpInfos[data.tokenId];
    //         data.vault = info.vault;
    //         data.amountB0 = info.amountB0;
    //         data.lpLiquidity = info.liquidity;
    //         // data.lpCumulativePnlPerLiquidity = info.cumulativePnlPerLiquidity;
    //     }
    // }

    function _getTdInfo(Data memory data, string memory symbolName, bool createOnDemand) internal {
        // data.tokenId = pToken.getTokenIdOf(data.account);
        bytes32 vaultId = keccak256(abi.encodePacked(data.account, symbolName));
        address uVault = userVault[vaultId];
        if (uVault == address(0)) {
            require(createOnDemand, 'PoolImplementation.getTdInfo: not trader');
            // data.tokenId = pToken.mint(data.account);
            data.vault = _clone(vaultTemplate);
            userVault[vaultId] = data.vault;
        } else {
            // TdInfo storage info = tdInfos[data.tokenId];
            data.vault = uVault;
            data.amountB0 = userAmountB0[vaultId];
        }
    }

    function _clone(address source) internal returns (address target) {
        bytes20 sourceBytes = bytes20(source);
        assembly {
            let c := mload(0x40)
            mstore(c, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(c, 0x14), sourceBytes)
            mstore(add(c, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            target := create(0, c, 0x37)
        }
    }

    function _settleLp(Data memory data) internal pure {
        int256 diff;
        unchecked { diff = data.cumulativePnlPerLiquidity - data.lpCumulativePnlPerLiquidity; }
        int256 pnl = diff * data.lpLiquidity / ONE;

        data.amountB0 += pnl;
        data.lpsPnl -= pnl;
        data.lpCumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;
    }

    function _transfer(address underlying, address to, uint256 amount) internal {
        if (underlying == address(0)) {
            (bool success, ) = payable(to).call{value: amount}('');
            require(success, 'PoolImplementation.transfer: send ETH fail');
        } else {
            IERC20(underlying).safeTransfer(to, amount);
        }
    }

    function _transferIn(Data memory data, uint256 amount) internal {
        IVault v = IVault(data.vault);

        // if (!v.isInMarket(data.market)) {
        //     v.enterMarket(data.market);
        // }

        // if (data.underlying == address(0)) { // ETH
        //     v.mint{value: amount}();
        // }
        // else if (data.underlying == tokenB0) {
        //     uint256 reserve = amount * reserveRatioB0 / UONE;
        //     uint256 deposit = amount - reserve;

        //     IERC20(data.underlying).safeTransferFrom(data.account, address(this), amount);
        //     IERC20(data.underlying).safeTransfer(data.vault, deposit);

        //     v.mint(data.market, deposit);
        //     data.amountB0 += reserve.utoi();
        // }
        // else {
        IERC20(data.underlying).safeTransferFrom(data.account, address(this), amount);
        IERC20(data.underlying).safeTransfer(data.vault, amount);
        // v.supply(data.underlying, amount);
        // }
    }

    function _transferOut(Data memory data, uint256 amount) internal returns (uint256 newVaultLiquidity) {
        IVault v = IVault(data.vault);
        newVaultLiquidity = v.getVaultLiquidity();

        if(amount <= newVaultLiquidity) { // all from vault
            v.transfer(data.underlying, data.account, amount);
        } else { 
            uint256 underlyingBalance = data.underlying == address(0) ?
                                        data.vault.balance :
                                        IERC20(data.underlying).balanceOf(data.vault);
                                        
            if(data.amountB0 < 0) {
                (uint256 owe, uint256 excessive) = (-data.amountB0).itou().rescaleUp(18, IERC20(tokenB0).decimals()); // amountB0 is in decimals18
                v.transfer(data.underlying, data.account, underlyingBalance);

                if(data.underlying == address(0)) {
                    (uint256 resultB0, uint256 resultBX) = swapper.swapETHForExactB0{value: underlyingBalance}(owe);
                    data.amountB0 += resultB0.utoi();
                    underlyingBalance -= resultBX;
                } else if (data.underlying == tokenB0) {
                    if (underlyingBalance >= owe) {
                        data.amountB0 = excessive.utoi(); 
                        underlyingBalance -= owe;
                    } else {
                        data.amountB0 += underlyingBalance.utoi();
                        underlyingBalance = 0;
                    }
                } else {
                    (uint256 resultB0, uint256 resultBX) = swapper.swapBXForExactB0(data.underlying, owe, underlyingBalance);
                    data.amountB0 += resultB0.utoi(); 
                    underlyingBalance -= resultBX;
                }

                if(underlyingBalance > 0) {
                    _transfer(data.underlying, data.account, underlyingBalance);
                }
            } else {
                v.transfer(data.underlying, data.account, underlyingBalance); // all vault + amountB0 from lp
                if (data.underlying == tokenB0 && data.amountB0 > 0 && amount > underlyingBalance) {
                    uint256 own = data.amountB0.itou(); 
                    uint256 resultBX = own.min(amount - underlyingBalance);
                    _transfer(tokenB0, data.account, resultBX);
                    data.amountB0 -= resultBX.utoi();
                }
            }
        }
    }

    // function _transferOut(Data memory data, uint256 amount, uint256 vTokenBalance, uint256 underlyingBalance)
    // internal returns (uint256 newVaultLiquidity)
    // {
    //     IVault v = IVault(data.vault);

    //     if (underlyingBalance > 0) {
    //         if (amount >= underlyingBalance) {
    //             v.redeem(data.market, vTokenBalance);
    //         } else {
    //             v.redeemUnderlying(data.market, amount);
    //         }

    //         underlyingBalance = data.underlying == address(0) ?
    //                             data.vault.balance :
    //                             IERC20(data.underlying).balanceOf(data.vault);

    //         if (data.amountB0 < 0) {
    //             uint256 owe = (-data.amountB0).itou();
    //             v.transfer(data.underlying, address(this), underlyingBalance);

    //             if (data.underlying == address(0)) {
    //                 (uint256 resultB0, uint256 resultBX) = swapper.swapETHForExactB0{value: underlyingBalance}(owe);
    //                 data.amountB0 += resultB0.utoi();
    //                 underlyingBalance -= resultBX;
    //             }
    //             else if (data.underlying == tokenB0) {
    //                 if (underlyingBalance >= owe) {
    //                     data.amountB0 = 0;
    //                     underlyingBalance -= owe;
    //                 } else {
    //                     data.amountB0 += underlyingBalance.utoi();
    //                     underlyingBalance = 0;
    //                 }
    //             }
    //             else {
    //                 (uint256 resultB0, uint256 resultBX) = swapper.swapBXForExactB0(
    //                     data.underlying, owe, underlyingBalance
    //                 );
    //                 data.amountB0 += resultB0.utoi();
    //                 underlyingBalance -= resultBX;
    //             }

    //             if (underlyingBalance > 0) {
    //                 _transfer(data.underlying, data.account, underlyingBalance);
    //             }
    //         }
    //         else {
    //             v.transfer(data.underlying, data.account, underlyingBalance);
    //         }
    //     }

    //     newVaultLiquidity = v.getVaultLiquidity();

    //     if (newVaultLiquidity == 0 && amount >= UMAX && data.amountB0 > 0) {
    //         uint256 own = data.amountB0.itou();
    //         uint256 resultBX;

    //         if (data.underlying == address(0)) {
    //             (, resultBX) = swapper.swapExactB0ForETH(own);
    //         } else if (data.underlying == tokenB0) {
    //             resultBX = own;
    //         } else {
    //             (, resultBX) = swapper.swapExactB0ForBX(data.underlying, own);
    //         }

    //         _transfer(data.underlying, data.account, resultBX);
    //         data.amountB0 = 0;
    //     }

    //     if (data.underlying == tokenB0 && data.amountB0 > 0 && amount > underlyingBalance) {
    //         uint256 own = data.amountB0.itou();
    //         uint256 resultBX = own.min(amount - underlyingBalance);
    //         _transfer(tokenB0, data.account, resultBX);
    //         data.amountB0 -= resultBX.utoi();
    //     }
    // }

}

import '../token/IERC20.sol';
import '../library/SafeMath.sol';
import '../library/SafeERC20.sol';
import './IPool.sol';
import '../swapper/IUniswapV2Factory.sol';
import '../swapper/IUniswapV2Router02.sol';
import '../utils/Admin.sol';
import '../oracle/IOracleManager.sol';

pragma solidity >=0.8.0 <0.9.0;

contract PoolManager is Admin  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 constant ONE = 1e18;
    uint256 constant BASIS_POINTS_DIVISOR = 1e6;


    IUniswapV2Factory public immutable factory;

    IUniswapV2Router02 public immutable router;

    IOracleManager public immutable oracleManager;
    
    address public immutable pool;

    // address public immutable tokenB0;

    address public immutable weth;

    uint256 public immutable maxSlippageRatio;

    // fromToken => toToken => path
    mapping (address => mapping (address => address[])) public paths;

    // tokenBX => oracle symbolId
    mapping (address => bytes32) public oracleSymbolIds;

    constructor (
        address pool_,
        address factory_,
        address router_,
        address oracleManager_,
        uint256 maxSlippageRatio_,
        address weth_
    ) {
        factory = IUniswapV2Factory(factory_);
        router = IUniswapV2Router02(router_);
        oracleManager = IOracleManager(oracleManager_);
        pool = pool_;
        maxSlippageRatio = maxSlippageRatio_;
        weth = weth_;
    }

    function setTokenConfig(address token, address[] calldata pathToETH, string memory symbol) external _onlyAdmin_ {
        uint256 length = pathToETH.length;

        require(length >= 2, 'Swapper.setPath: invalid path length');
        require(pathToETH[0] == token, 'Swapper.setPath: path should begin with token');
        require(pathToETH[length-1] == weth, 'Swapper.setPath: path should begin with WETH');
        for (uint256 i = 1; i < length; i++) {
            require(factory.getPair(pathToETH[i-1], pathToETH[i]) != address(0), 'Swapper.setPath: path broken');
        }

        address[] memory revertedPath = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            revertedPath[length-i-1] = pathToETH[i];
        }

        paths[weth][token] = pathToETH;
        paths[token][weth] = revertedPath;

        IERC20(token).safeApprove(address(router), type(uint256).max);

        bytes32 symbolId = keccak256(abi.encodePacked(symbol));
        require(oracleManager.value(symbolId) != 0, 'Swapper: no oralce price');
        oracleSymbolIds[token] = symbolId;
    }

    function adjustTokensRatio(uint256[] calldata ratios) external _onlyAdmin_ {
        uint256 length = IPool(pool).allWhitelistedTokensLength();
        require(length ==  ratios.length, "PoolManager: Invalid ratios length");

        uint256 ratiosSum = 0;
        for(uint256 i=0 ; i < length; i++) {
            ratiosSum += ratios[i];
        }
        require(ratiosSum == BASIS_POINTS_DIVISOR, "PoolManager: Invalid ratios sum");
        uint256 wethPrice = getTokenPrice(weth);
        for(uint256 i=0 ; i < length; i++) {
            address token = IPool(pool).allWhitelistedTokens(i);
            if(token == weth) { continue;}
            uint256 amount = IERC20(token).balanceOf(pool);

            uint256 tokenPrice = getTokenPrice(token);
            uint256 minAmount = amount * tokenPrice / wethPrice * (BASIS_POINTS_DIVISOR - maxSlippageRatio) / BASIS_POINTS_DIVISOR;

            IERC20(token).safeTransferFrom(pool, address(this), amount);
            router.swapExactTokensForTokens(
                amount,
                minAmount,
                paths[token][weth],
                address(this),
                block.timestamp + 3600
            );
        }
        uint256 totalWeth = IERC20(weth).balanceOf(pool);
        for(uint256 i=0 ; i < length; i++) {
            address token = IPool(pool).allWhitelistedTokens(i);
            if(token == weth) { continue;}
            uint256 amount = totalWeth * ratios[i] / BASIS_POINTS_DIVISOR;

            uint256 tokenPrice = getTokenPrice(token);
            uint256 minAmount = amount * wethPrice / tokenPrice * (BASIS_POINTS_DIVISOR - maxSlippageRatio) / BASIS_POINTS_DIVISOR;

            router.swapExactTokensForTokens(
                amount,
                minAmount,
                paths[weth][token],
                pool,
                block.timestamp + 3600
            );
        }
    }

    function _calAmountOutMin(address token,uint256 amount, uint256 wethPrice) internal {
        

        
    }

    function getTokenPrice(address token) public view returns (uint256) {
        return oracleManager.value(oracleSymbolIds[token]);
    }


    function _swapExactTokensForTokens(address token1, address token2, uint256 amount1, uint256 amount2)
    internal returns (uint256 result1, uint256 result2)
    {
        if (amount1 == 0) return (0, 0);

        uint256[] memory res;
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
        router.swapExactTokensForTokens(
            amount1,
            amount2,
            paths[token1][token2],
            msg.sender,
            block.timestamp + 3600
        );
    }
}

// // SPDX-License-Identifier: MIT



// import "./IPoolPriceFeed.sol";
// import "../oracle/interfaces/IPriceFeed.sol";
// import "../oracle/interfaces/ISecondaryPriceFeed.sol";
// import "../oracle/interfaces/IChainlinkFlags.sol";
// import "../amm/interfaces/IPancakePair.sol";

// pragma solidity >=0.8.0 <0.9.0;

// contract VaultPriceFeed is IVaultPriceFeed {
//     using SafeMath for uint256;

//     uint256 public constant PRICE_PRECISION = 10 ** 30;
//     uint256 public constant ONE_USD = PRICE_PRECISION;
//     uint256 public constant BASIS_POINTS_DIVISOR = 10000;
//     uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
//     uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;
//     uint256 public constant MAX_ADJUSTMENT_BASIS_POINTS = 20;

//     // Identifier of the Sequencer offline flag on the Flags contract
//     address constant private FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));

//     address public gov;
//     address public chainlinkFlags;

//     bool public isAmmEnabled = true;
//     bool public isSecondaryPriceEnabled = true;
//     bool public useV2Pricing = false;
//     bool public favorPrimaryPrice = false;
//     uint256 public priceSampleSpace = 3;
//     uint256 public maxStrictPriceDeviation = 0;
//     address public secondaryPriceFeed;
//     uint256 public spreadThresholdBasisPoints = 30;

//     address public btc;
//     address public eth;
//     address public bnb;
//     address public bnbBusd;
//     address public ethBnb;
//     address public btcBnb;

//     mapping (address => address) public priceFeeds;
//     mapping (address => uint256) public priceDecimals;
//     mapping (address => uint256) public spreadBasisPoints;
//     // Chainlink can return prices for stablecoins
//     // that differs from 1 USD by a larger percentage than stableSwapFeeBasisPoints
//     // we use strictStableTokens to cap the price to 1 USD
//     // this allows us to configure stablecoins like DAI as being a stableToken
//     // while not being a strictStableToken
//     mapping (address => bool) public strictStableTokens;

//     mapping (address => uint256) public override adjustmentBasisPoints;
//     mapping (address => bool) public override isAdjustmentAdditive;
//     mapping (address => uint256) public lastAdjustmentTimings;

    

//     modifier onlyGov() {
//         require(msg.sender == gov, "VaultPriceFeed: forbidden");
//         _;
//     }

//     constructor() public {
//         gov = msg.sender;
//     }

//     function setGov(address _gov) external onlyGov {
//         gov = _gov;
//     }

//     function setChainlinkFlags(address _chainlinkFlags) external onlyGov {
//         chainlinkFlags = _chainlinkFlags;
//     }

//     function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external override onlyGov {
//         require(
//             lastAdjustmentTimings[_token].add(MAX_ADJUSTMENT_INTERVAL) < block.timestamp,
//             "VaultPriceFeed: adjustment frequency exceeded"
//         );
//         require(_adjustmentBps <= MAX_ADJUSTMENT_BASIS_POINTS, "invalid _adjustmentBps");
//         isAdjustmentAdditive[_token] = _isAdditive;
//         adjustmentBasisPoints[_token] = _adjustmentBps;
//         lastAdjustmentTimings[_token] = block.timestamp;
//     }

//     function setUseV2Pricing(bool _useV2Pricing) external override onlyGov {
//         useV2Pricing = _useV2Pricing;
//     }

//     function setIsAmmEnabled(bool _isEnabled) external override onlyGov {
//         isAmmEnabled = _isEnabled;
//     }

//     function setIsSecondaryPriceEnabled(bool _isEnabled) external override onlyGov {
//         isSecondaryPriceEnabled = _isEnabled;
//     }

//     function setSecondaryPriceFeed(address _secondaryPriceFeed) external onlyGov {
//         secondaryPriceFeed = _secondaryPriceFeed;
//     }

//     function setTokens(address _btc, address _eth, address _bnb) external onlyGov {
//         btc = _btc;
//         eth = _eth;
//         bnb = _bnb;
//     }

//     function setPairs(address _bnbBusd, address _ethBnb, address _btcBnb) external onlyGov {
//         bnbBusd = _bnbBusd;
//         ethBnb = _ethBnb;
//         btcBnb = _btcBnb;
//     }

//     function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external override onlyGov {
//         require(_spreadBasisPoints <= MAX_SPREAD_BASIS_POINTS, "VaultPriceFeed: invalid _spreadBasisPoints");
//         spreadBasisPoints[_token] = _spreadBasisPoints;
//     }

//     function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external override onlyGov {
//         spreadThresholdBasisPoints = _spreadThresholdBasisPoints;
//     }

//     function setFavorPrimaryPrice(bool _favorPrimaryPrice) external override onlyGov {
//         favorPrimaryPrice = _favorPrimaryPrice;
//     }

//     function setPriceSampleSpace(uint256 _priceSampleSpace) external override onlyGov {
//         require(_priceSampleSpace > 0, "VaultPriceFeed: invalid _priceSampleSpace");
//         priceSampleSpace = _priceSampleSpace;
//     }

//     function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external override onlyGov {
//         maxStrictPriceDeviation = _maxStrictPriceDeviation;
//     }

//     function setTokenConfig(
//         address _token,
//         address _priceFeed,
//         uint256 _priceDecimals,
//         bool _isStrictStable
//     ) external override onlyGov {
//         priceFeeds[_token] = _priceFeed;
//         priceDecimals[_token] = _priceDecimals;
//         strictStableTokens[_token] = _isStrictStable;
//     }

//     function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool /* _useSwapPricing */) public override view returns (uint256) {
//         uint256 price = useV2Pricing ? getPriceV2(_token, _maximise, _includeAmmPrice) : getPriceV1(_token, _maximise, _includeAmmPrice);

//         uint256 adjustmentBps = adjustmentBasisPoints[_token];
//         if (adjustmentBps > 0) {
//             bool isAdditive = isAdjustmentAdditive[_token];
//             if (isAdditive) {
//                 price = price.mul(BASIS_POINTS_DIVISOR.add(adjustmentBps)).div(BASIS_POINTS_DIVISOR);
//             } else {
//                 price = price.mul(BASIS_POINTS_DIVISOR.sub(adjustmentBps)).div(BASIS_POINTS_DIVISOR);
//             }
//         }

//         return price;
//     }

//     function getPriceV1(address _token, bool _maximise, bool _includeAmmPrice) public view returns (uint256) {
//         uint256 price = getPrimaryPrice(_token, _maximise);

//         if (_includeAmmPrice && isAmmEnabled) {
//             uint256 ammPrice = getAmmPrice(_token);
//             if (ammPrice > 0) {
//                 if (_maximise && ammPrice > price) {
//                     price = ammPrice;
//                 }
//                 if (!_maximise && ammPrice < price) {
//                     price = ammPrice;
//                 }
//             }
//         }

//         if (isSecondaryPriceEnabled) {
//             price = getSecondaryPrice(_token, price, _maximise);
//         }

//         if (strictStableTokens[_token]) {
//             uint256 delta = price > ONE_USD ? price.sub(ONE_USD) : ONE_USD.sub(price);
//             if (delta <= maxStrictPriceDeviation) {
//                 return ONE_USD;
//             }

//             // if _maximise and price is e.g. 1.02, return 1.02
//             if (_maximise && price > ONE_USD) {
//                 return price;
//             }

//             // if !_maximise and price is e.g. 0.98, return 0.98
//             if (!_maximise && price < ONE_USD) {
//                 return price;
//             }

//             return ONE_USD;
//         }

//         uint256 _spreadBasisPoints = spreadBasisPoints[_token];

//         if (_maximise) {
//             return price.mul(BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
//         }

//         return price.mul(BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
//     }

//     function getPriceV2(address _token, bool _maximise, bool _includeAmmPrice) public view returns (uint256) {
//         uint256 price = getPrimaryPrice(_token, _maximise);

//         if (_includeAmmPrice && isAmmEnabled) {
//             price = getAmmPriceV2(_token, _maximise, price);
//         }

//         if (isSecondaryPriceEnabled) {
//             price = getSecondaryPrice(_token, price, _maximise);
//         }

//         if (strictStableTokens[_token]) {
//             uint256 delta = price > ONE_USD ? price.sub(ONE_USD) : ONE_USD.sub(price);
//             if (delta <= maxStrictPriceDeviation) {
//                 return ONE_USD;
//             }

//             // if _maximise and price is e.g. 1.02, return 1.02
//             if (_maximise && price > ONE_USD) {
//                 return price;
//             }

//             // if !_maximise and price is e.g. 0.98, return 0.98
//             if (!_maximise && price < ONE_USD) {
//                 return price;
//             }

//             return ONE_USD;
//         }

//         uint256 _spreadBasisPoints = spreadBasisPoints[_token];

//         if (_maximise) {
//             return price.mul(BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
//         }

//         return price.mul(BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
//     }

//     function getAmmPriceV2(address _token, bool _maximise, uint256 _primaryPrice) public view returns (uint256) {
//         uint256 ammPrice = getAmmPrice(_token);
//         if (ammPrice == 0) {
//             return _primaryPrice;
//         }

//         uint256 diff = ammPrice > _primaryPrice ? ammPrice.sub(_primaryPrice) : _primaryPrice.sub(ammPrice);
//         if (diff.mul(BASIS_POINTS_DIVISOR) < _primaryPrice.mul(spreadThresholdBasisPoints)) {
//             if (favorPrimaryPrice) {
//                 return _primaryPrice;
//             }
//             return ammPrice;
//         }

//         if (_maximise && ammPrice > _primaryPrice) {
//             return ammPrice;
//         }

//         if (!_maximise && ammPrice < _primaryPrice) {
//             return ammPrice;
//         }

//         return _primaryPrice;
//     }

//     function getPrimaryPrice(address _token, bool _maximise) public override view returns (uint256) {
//         address priceFeedAddress = priceFeeds[_token];
//         require(priceFeedAddress != address(0), "VaultPriceFeed: invalid price feed");

//         if (chainlinkFlags != address(0)) {
//             bool isRaised = IChainlinkFlags(chainlinkFlags).getFlag(FLAG_ARBITRUM_SEQ_OFFLINE);
//             if (isRaised) {
//                     // If flag is raised we shouldn't perform any critical operations
//                 revert("Chainlink feeds are not being updated");
//             }
//         }

//         IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

//         uint256 price = 0;
//         uint80 roundId = priceFeed.latestRound();

//         for (uint80 i = 0; i < priceSampleSpace; i++) {
//             if (roundId <= i) { break; }
//             uint256 p;

//             if (i == 0) {
//                 int256 _p = priceFeed.latestAnswer();
//                 require(_p > 0, "VaultPriceFeed: invalid price");
//                 p = uint256(_p);
//             } else {
//                 (, int256 _p, , ,) = priceFeed.getRoundData(roundId - i);
//                 require(_p > 0, "VaultPriceFeed: invalid price");
//                 p = uint256(_p);
//             }

//             if (price == 0) {
//                 price = p;
//                 continue;
//             }

//             if (_maximise && p > price) {
//                 price = p;
//                 continue;
//             }

//             if (!_maximise && p < price) {
//                 price = p;
//             }
//         }

//         require(price > 0, "VaultPriceFeed: could not fetch price");
//         // normalise price precision
//         uint256 _priceDecimals = priceDecimals[_token];
//         return price.mul(PRICE_PRECISION).div(10 ** _priceDecimals);
//     }

//     function getSecondaryPrice(address _token, uint256 _referencePrice, bool _maximise) public view returns (uint256) {
//         if (secondaryPriceFeed == address(0)) { return _referencePrice; }
//         return ISecondaryPriceFeed(secondaryPriceFeed).getPrice(_token, _referencePrice, _maximise);
//     }

//     function getAmmPrice(address _token) public override view returns (uint256) {
//         if (_token == bnb) {
//             // for bnbBusd, reserve0: BNB, reserve1: BUSD
//             return getPairPrice(bnbBusd, true);
//         }

//         if (_token == eth) {
//             uint256 price0 = getPairPrice(bnbBusd, true);
//             // for ethBnb, reserve0: ETH, reserve1: BNB
//             uint256 price1 = getPairPrice(ethBnb, true);
//             // this calculation could overflow if (price0 / 10**30) * (price1 / 10**30) is more than 10**17
//             return price0.mul(price1).div(PRICE_PRECISION);
//         }

//         if (_token == btc) {
//             uint256 price0 = getPairPrice(bnbBusd, true);
//             // for btcBnb, reserve0: BTC, reserve1: BNB
//             uint256 price1 = getPairPrice(btcBnb, true);
//             // this calculation could overflow if (price0 / 10**30) * (price1 / 10**30) is more than 10**17
//             return price0.mul(price1).div(PRICE_PRECISION);
//         }

//         return 0;
//     }

//     // if divByReserve0: calculate price as reserve1 / reserve0
//     // if !divByReserve1: calculate price as reserve0 / reserve1
//     function getPairPrice(address _pair, bool _divByReserve0) public view returns (uint256) {
//         (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_pair).getReserves();
//         if (_divByReserve0) {
//             if (reserve0 == 0) { return 0; }
//             return reserve1.mul(PRICE_PRECISION).div(reserve0);
//         }
//         if (reserve1 == 0) { return 0; }
//         return reserve0.mul(PRICE_PRECISION).div(reserve1);
//     }
// }

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract PoolStorage is Admin {

    // admin will be truned in to Timelock after deployment

    event NewImplementation(address newImplementation);

    event NewProtocolFeeCollector(address newProtocolFeeCollector);

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, 'Pool: reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    address public implementation;

    address public protocolFeeCollector;

    // underlying => vToken, supported markets
    mapping (address => address) public markets;

    struct LpInfo {
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
    }


    
    
    // lTokenId => LpInfo
    mapping (uint256 => LpInfo) public lpInfos;

    struct TdInfo {
        address vault;
        int256 amountB0;
    }

    // pTokenId => TdInfo
    // mapping (uint256 => TdInfo) public tdInfos;
    mapping (bytes32 => address) public userVault;
    mapping (bytes32 => int256) public userAmountB0; // vaultId => amountB0

    int256 public liquidity;

    int256 public lpsPnl;

    int256 public cumulativePnlPerLiquidity;

    int256 public protocolFeeAccrued;
    
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/IAdmin.sol';
import '../utils/INameVersion.sol';
import './IUniswapV3Factory.sol';
import './IUniswapV3Router.sol';
import '../oracle/IOracleManager.sol';

interface ISwapper is IAdmin, INameVersion {

    function factory() external view returns (IUniswapV3Factory);

    function router() external view returns (ISwapRouter);

    function oracleManager() external view returns (IOracleManager);

    function tokenB0() external view returns (address);

    function tokenWETH() external view returns (address);

    function maxSlippageRatio() external view returns (uint256);

    function oracleSymbolIds(address tokenBX) external view returns (bytes32);

    function setPath(string memory priceSymbol, address[] calldata path, uint24 fee) external;

    function getPath(address tokenBX) external view returns (address[] memory);

    function isSupportedToken(address tokenBX) external view returns (bool);

    function getTokenPrice(address tokenBX) external view returns (uint256);

    function swapExactB0ForBX(address tokenBX, uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactBXForB0(address tokenBX, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactBX(address tokenBX, uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapBXForExactB0(address tokenBX, uint256 amountB0, uint256 maxAmountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactB0ForETH(uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactETHForB0()
    external payable returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactETH(uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapETHForExactB0(uint256 amountB0)
    external payable returns (uint256 resultB0, uint256 resultBX);

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISwapper.sol';
import '../token/IERC20.sol';
import './IUniswapV3Factory.sol';
import './IUniswapV3Router.sol';
import '../oracle/IOracleManager.sol';
import '../utils/Admin.sol';
import '../utils/NameVersion.sol';
import '../library/SafeERC20.sol';
import './TransferHelper.sol';

contract Swapper is ISwapper, Admin, NameVersion {

    using SafeERC20 for IERC20;

    uint256 constant ONE = 1e18;

    IUniswapV3Factory public immutable factory;

    ISwapRouter public immutable router;

    IOracleManager public immutable oracleManager;

    address public immutable tokenB0;

    address public immutable tokenWETH;

    uint256 public immutable maxSlippageRatio;

    // fromToken => toToken => path
    mapping (address => mapping (address => address[])) public paths;
    // fromToken => toToken => fees
    mapping (address => mapping (address => uint24)) public fees;

    // tokenBX => oracle symbolId
    mapping (address => bytes32) public oracleSymbolIds;

    constructor (
        address factory_,
        address router_,
        address oracleManager_,
        address tokenB0_,
        address tokenWETH_,
        uint24 uniswapFee_,
        uint256 maxSlippageRatio_,
        string memory nativePriceSymbol // BNBUSD for BSC, ETHUSD for Ethereum
    ) NameVersion('Swapper', '3.0.1')
    {
        factory = IUniswapV3Factory(factory_);
        router = ISwapRouter(router_);
        oracleManager = IOracleManager(oracleManager_);
        tokenB0 = tokenB0_;
        tokenWETH = tokenWETH_;
        maxSlippageRatio = maxSlippageRatio_;

        require(
            factory.getPool(tokenB0_, tokenWETH_, uniswapFee_) != address(0),
            'Swapper.constructor: no native path'
        );
        require(
            IERC20(tokenB0_).decimals() == 18 && IERC20(tokenWETH_).decimals() == 18,
            'Swapper.constructor: only token of decimals 18'
        );

        address[] memory path = new address[](2);

        (path[0], path[1]) = (tokenB0_, tokenWETH_);
        paths[tokenB0_][tokenWETH_] = path;

        (path[0], path[1]) = (tokenWETH_, tokenB0_);
        paths[tokenWETH_][tokenB0_] = path;

        bytes32 symbolId = keccak256(abi.encodePacked(nativePriceSymbol));
        require(oracleManager.value(symbolId) != 0, 'Swapper.constructor: no native price');
        oracleSymbolIds[tokenWETH_] = symbolId;

        IERC20(tokenB0_).safeApprove(router_, type(uint256).max);
    }

    function setPath(string memory priceSymbol, address[] calldata path, uint24 fee) external _onlyAdmin_ {
        uint256 length = path.length;

        require(length == 2, 'Swapper.setPath: invalid path length');
        require(path[0] == tokenB0, 'Swapper.setPath: path should begin with tokenB0');
        for (uint256 i = 1; i < length; i++) {
            // require(factory.getPair(path[i-1], path[i]) != address(0), 'Swapper.setPath: path broken');
            require(factory.getPool(path[i-1], path[i], fee) != address(0), 'Swapper.setPath: no pool');
        }

        address[] memory revertedPath = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            revertedPath[length-i-1] = path[i];
        }

        address tokenBX = path[length-1];
        paths[tokenB0][tokenBX] = path;
        fees[tokenB0][tokenBX] = fee;
        paths[tokenBX][tokenB0] = revertedPath;
        fees[tokenBX][tokenB0] = fee;

        require(
            IERC20(tokenBX).decimals() == 18,
            'Swapper.setPath: only token of decimals 18'
        );

        bytes32 symbolId = keccak256(abi.encodePacked(priceSymbol));
        require(oracleManager.value(symbolId) != 0, 'Swapper.setPath: no price');
        oracleSymbolIds[tokenBX] = symbolId;

        IERC20(tokenBX).safeApprove(address(router), type(uint256).max);
    }

    function getPath(address tokenBX) external view returns (address[] memory) {
        return paths[tokenB0][tokenBX];
    }

    function isSupportedToken(address tokenBX) external view returns (bool) {
        address[] storage path1 = paths[tokenB0][tokenBX];
        address[] storage path2 = paths[tokenBX][tokenB0];
        return path1.length >= 2 && path2.length >= 2;
    }

    function getTokenPrice(address tokenBX) public view returns (uint256) {
        return oracleManager.value(oracleSymbolIds[tokenBX]);
    }

    receive() external payable {}

    //================================================================================

    function swapExactB0ForBX(address tokenBX, uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenBX);
        uint256 minAmountBX = amountB0 * (ONE - maxSlippageRatio) / price;
        (resultB0, resultBX) = _swapExactTokensForTokens(tokenB0, tokenBX, amountB0, minAmountBX);
    }
    //
    function swapExactBXForB0(address tokenBX, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenBX);
        uint256 minAmountB0 = amountBX * price / ONE * (ONE - maxSlippageRatio) / ONE;
        (resultBX, resultB0) = _swapExactTokensForTokens(tokenBX, tokenB0, amountBX, minAmountB0);
    }

    function swapB0ForExactBX(address tokenBX, uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenBX);
        uint256 maxB0 = amountBX * price / ONE * (ONE + maxSlippageRatio) / ONE;
        if (maxAmountB0 >= maxB0) {
            (resultB0, resultBX) = _swapTokensForExactTokens(tokenB0, tokenBX, maxB0, amountBX);
        } else {
            uint256 minAmountBX = maxAmountB0 * (ONE - maxSlippageRatio) / price;
            (resultB0, resultBX) = _swapExactTokensForTokens(tokenB0, tokenBX, maxAmountB0, minAmountBX);
        }
    }
    //
    function swapBXForExactB0(address tokenBX, uint256 amountB0, uint256 maxAmountBX)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenBX);
        uint256 maxBX = amountB0 * (ONE + maxSlippageRatio) / price;
        if (maxAmountBX >= maxBX) {
            (resultBX, resultB0) = _swapTokensForExactTokens(tokenBX, tokenB0, maxBX, amountB0);
        } else {
            uint256 minAmountB0 = maxAmountBX * price / ONE * (ONE - maxSlippageRatio) / ONE;
            (resultBX, resultB0) = _swapExactTokensForTokens(tokenBX, tokenB0, maxAmountBX, minAmountB0);
        }
    }

    function swapExactB0ForETH(uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenWETH);
        uint256 minAmountBX = amountB0 * (ONE - maxSlippageRatio) / price;
        (resultB0, resultBX) = _swapExactTokensForTokens(tokenB0, tokenWETH, amountB0, minAmountBX);
    }
    //
    function swapExactETHForB0()
    external payable returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenWETH);
        uint256 amountBX = msg.value;
        uint256 minAmountB0 = amountBX * price / ONE * (ONE - maxSlippageRatio) / ONE;
        (resultBX, resultB0) = _swapExactTokensForTokens(tokenWETH, tokenB0, amountBX, minAmountB0);
    }

    function swapB0ForExactETH(uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenWETH);
        uint256 maxB0 = amountBX * price / ONE * (ONE + maxSlippageRatio) / ONE;
        if (maxAmountB0 >= maxB0) {
            (resultB0, resultBX) = _swapTokensForExactTokens(tokenB0, tokenWETH, maxB0, amountBX);
        } else {
            uint256 minAmountBX = maxAmountB0 * (ONE - maxSlippageRatio) / price;
            (resultB0, resultBX) = _swapExactTokensForTokens(tokenB0, tokenWETH, maxAmountB0, minAmountBX);
        }
    }
    //
    function swapETHForExactB0(uint256 amountB0)
    external payable returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenWETH);
        uint256 maxAmountBX = msg.value;
        uint256 maxBX = amountB0 * (ONE + maxSlippageRatio) / price;
        if (maxAmountBX >= maxBX) {
            (resultBX, resultB0) = _swapTokensForExactTokens(tokenWETH, tokenB0, maxBX, amountB0);
        } else {
            uint256 minAmountB0 = maxAmountBX * price / ONE * (ONE - maxSlippageRatio) / ONE;
            (resultBX, resultB0) = _swapExactTokensForTokens(tokenWETH, tokenB0, maxAmountBX, minAmountB0);
        }
    }

    //================================================================================

    function _swapExactTokensForTokens(address token1, address token2, uint256 amount1, uint256 amount2)
    internal returns (uint256 result1, uint256 result2)
    {
        if (amount1 == 0) return (0, 0);

        uint256[] memory res;
        uint256 amountOut;
        if (token1 == tokenWETH) {
            // res = router.swapExactETHForTokens{value: amount1}(
            //     amount2,
            //     paths[token1][token2],
            //     msg.sender,
            //     block.timestamp + 3600
            // );
            ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: fees[token1][token2],
                recipient: msg.sender,
                deadline: block.timestamp+3600,
                amountIn: amount1,
                amountOutMinimum: amount2,
                sqrtPriceLimitX96: 0
            });
            amountOut = router.exactInputSingle{value:amount1}(params);
        } else if (token2 == tokenWETH) {
            // IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
            // res = router.swapExactTokensForETH(
            //     amount1,
            //     amount2,
            //     paths[token1][token2],
            //     msg.sender,
            //     block.timestamp + 3600
            // );
            TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amount1);
            TransferHelper.safeApprove(token1, address(router), amount1);
            ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: fees[token1][token2],
                recipient: msg.sender,
                deadline: block.timestamp+3600,
                amountIn: amount1,
                amountOutMinimum: amount2,
                sqrtPriceLimitX96: 0
            });
            amountOut = router.exactInputSingle(params);
        } else {
            // IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
            TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amount1);
            TransferHelper.safeApprove(token1, address(router), amount1);
            ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: fees[token1][token2],
                recipient: msg.sender,
                deadline: block.timestamp+3600,
                amountIn: amount1,
                amountOutMinimum: amount2,
                sqrtPriceLimitX96: 0
            });
            amountOut = router.exactInputSingle(params);
        }
        //     res = router.swapExactTokensForTokens(
        //         amount1,
        //         amount2,
        //         paths[token1][token2],
        //         msg.sender,
        //         block.timestamp + 3600
        //     );
        // }

        // result1 = res[0];
        // result2 = res[res.length - 1];
        result1 = amount1;
        result2 = amountOut;
    }

    function _swapTokensForExactTokens(address token1, address token2, uint256 amount1, uint256 amount2)
    internal returns (uint256 result1, uint256 result2)
    {
        if (amount1 == 0 || amount2 == 0) {
            if (amount1 > 0 && token1 == tokenWETH) {
                _sendETH(msg.sender, amount1);
            }
            return (0, 0);
        }

        uint256[] memory res;
        uint256 amountIn;
        if (token1 == tokenWETH) {
            // res = router.swapETHForExactTokens{value: amount1}(
            //     amount2,
            //     paths[token1][token2],
            //     msg.sender,
            //     block.timestamp + 3600
            // );
            ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: fees[token1][token2],
                recipient: msg.sender,
                deadline: block.timestamp+3600,
                amountOut: amount2,
                amountInMaximum: amount1,
                sqrtPriceLimitX96: 0
            });
            amountIn = router.exactOutputSingle{value:amount1}(params);
        } else if (token2 == tokenWETH) {
            // IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
            // res = router.swapTokensForExactETH(
            //     amount2,
            //     amount1,
            //     paths[token1][token2],
            //     msg.sender,
            //     block.timestamp + 3600
            // );
            TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amount1);
            TransferHelper.safeApprove(token1, address(router), amount1);
            ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: fees[token1][token2],
                recipient: msg.sender,
                deadline: block.timestamp+3600,
                amountOut: amount2,
                amountInMaximum: amount1,
                sqrtPriceLimitX96: 0
            });
            amountIn = router.exactOutputSingle(params);
        } else {
            // IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
            TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amount1);
            TransferHelper.safeApprove(token1, address(router), amount1);
            ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: fees[token1][token2],
                recipient: msg.sender,
                deadline: block.timestamp+3600,
                amountOut: amount2,
                amountInMaximum: amount1,
                sqrtPriceLimitX96: 0
            });
            amountIn = router.exactOutputSingle(params);
            // res = router.swapTokensForExactTokens(
            //     amount2,
            //     amount1,
            //     paths[token1][token2],
            //     msg.sender,
            //     block.timestamp + 3600
            // );
        }

        // result1 = res[0];
        // result2 = res[res.length - 1];
        result1 = amountIn;
        result2 = amount2;

        if (token1 == tokenWETH) {
            _sendETH(msg.sender, address(this).balance);
        } else {
            IERC20(token1).safeTransfer(msg.sender, IERC20(token1).balanceOf(address(this)));
        }
    }

    function _sendETH(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}('');
        require(success, 'Swapper._sendETH: fail');
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../token/IERC20.sol';

// interface IERC20 {
//     /**
//      * @dev Returns the amount of tokens in existence.
//      */
//     function totalSupply() external view returns (uint256);

//     /**
//      * @dev Returns the amount of tokens owned by `account`.
//      */
//     function balanceOf(address account) external view returns (uint256);

//     /**
//      * @dev Moves `amount` tokens from the caller's account to `recipient`.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Returns the remaining number of tokens that `spender` will be
//      * allowed to spend on behalf of `owner` through {transferFrom}. This is
//      * zero by default.
//      *
//      * This value changes when {approve} or {transferFrom} are called.
//      */
//     function allowance(address owner, address spender) external view returns (uint256);

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * IMPORTANT: Beware that changing an allowance with this method brings the risk
//      * that someone may use both the old and the new allowance by unfortunate
//      * transaction ordering. One possible solution to mitigate this race
//      * condition is to first reduce the spender's allowance to 0 and set the
//      * desired value afterwards:
//      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//      *
//      * Emits an {Approval} event.
//      */
//     function approve(address spender, uint256 amount) external returns (bool);

//     /**
//      * @dev Moves `amount` tokens from `sender` to `recipient` using the
//      * allowance mechanism. `amount` is then deducted from the caller's
//      * allowance.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Emitted when `value` tokens are moved from one account (`from`) to
//      * another (`to`).
//      *
//      * Note that `value` may be zero.
//      */
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     /**
//      * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//      * a call to {approve}. `value` is the new allowance.
//      */
//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISymbol {

    struct SettlementOnAddLiquidity {
        bool settled;
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
    }

    struct SettlementOnRemoveLiquidity {
        bool settled;
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 removeLiquidityPenalty;
    }

    struct SettlementOnTraderWithPosition {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
    }

    struct SettlementOnTrade {
        int256 funding;
        int256 deltaTradersPnl;
        // int256 deltaInitialMarginRequired;
        int256 indexPrice;
        int256 traderFunding;
        int256 traderPnl;
        // int256 traderInitialMarginRequired;
        int256 tradeCost;
        int256 tradeFee;
        int256 tradeRealizedCost;
        int256 positionChangeStatus; // 1: new open (enter), -1: total close (exit), 0: others (not change)
        int256 marginRequired;
    }

    struct SettlementOnLiquidate {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 indexPrice;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderMaintenanceMarginRequired;
        int256 tradeVolume;
        int256 tradeCost;
        int256 tradeRealizedCost;
        int256 marginRequired;
    }

    struct Position {
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }

    function implementation() external view returns (address);

    function symbol() external view returns (string memory);

    function netVolume() external view returns (int256);

    function netCost() external view returns (int256);

    function indexPrice() external view returns (int256);

    function fundingTimestamp() external view returns (uint256);

    function cumulativeFundingPerVolume() external view returns (int256);

    function tradersPnl() external view returns (int256);

    function initialMarginRequired() external view returns (int256);

    function nPositionHolders() external view returns (uint256);

    function positions(uint256 pTokenId) external view returns (Position memory);

    function setImplementation(address newImplementation) external;

    function manager() external view returns (address);

    function oracleManager() external view returns (address);

    function symbolId() external view returns (bytes32);

    function feeRatio() external view returns (int256);             // futures only

    function alpha() external view returns (int256);

    function fundingPeriod() external view returns (int256);

    function minTradeVolume() external view returns (int256);

    function initialMarginRatio() external view returns (int256);

    function maintenanceMarginRatio() external view returns (int256);

    function pricePercentThreshold() external view returns (int256);

    function timeThreshold() external view returns (uint256);

    function isCloseOnly() external view returns (bool);

    function priceId() external view returns (bytes32);              // option only

    function volatilityId() external view returns (bytes32);         // option only

    function feeRatioITM() external view returns (int256);           // option only

    function feeRatioOTM() external view returns (int256);           // option only

    function strikePrice() external view returns (int256);           // option only

    function minInitialMarginRatio() external view returns (int256); // option only

    function isCall() external view returns (bool);                  // option only

    function hasPosition(address pTokenId) external view returns (bool);

    function settleOnAddLiquidity(int256 liquidity)
    external returns (ISymbol.SettlementOnAddLiquidity memory s);

    function settleOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external returns (ISymbol.SettlementOnRemoveLiquidity memory s);

    function settleOnTraderWithPosition(address pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnTraderWithPosition memory s);

    function settleOnTrade(address pTokenId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external returns (ISymbol.SettlementOnTrade memory s);

    function settleOnLiquidate(address pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnLiquidate memory s);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISymbolManager {

    struct SettlementOnAddLiquidity {
        int256 funding;
        int256 deltaTradersPnl;
    }

    struct SettlementOnRemoveLiquidity {
        int256 funding;
        int256 deltaTradersPnl;
        int256 initialMarginRequired;
        int256 removeLiquidityPenalty;
    }

    struct SettlementOnRemoveMargin {
        int256 funding;
        int256 deltaTradersPnl;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
    }

    struct SettlementOnTrade {
        int256 funding;
        int256 deltaTradersPnl;
        // int256 initialMarginRequired;
        int256 traderFunding;
        int256 traderPnl;
        // int256 traderInitialMarginRequired;
        int256 tradeFee;
        int256 tradeRealizedCost;
        int256 marginRequired;
    }

    struct SettlementOnLiquidate {
        int256 funding;
        int256 deltaTradersPnl;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderMaintenanceMarginRequired;
        int256 traderRealizedCost;
        int256 marginRequired;
    }

    function implementation() external view returns (address);

    function initialMarginRequired() external view returns (int256);

    function pool() external view returns (address);

    function getActiveSymbols(address pTokenId) external view returns (address[] memory);

    function getSymbolsLength() external view returns (uint256);

    function addSymbol(address symbol) external;

    function removeSymbol(bytes32 symbolId) external;

    function symbols(bytes32 symbolId) external view returns (address);

    function settleSymbolsOnAddLiquidity(int256 liquidity)
    external returns (SettlementOnAddLiquidity memory ss);

    function settleSymbolsOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external returns (SettlementOnRemoveLiquidity memory ss);

    function settleSymbolsOnRemoveMargin(address pTokenId, bytes32 symbolId, int256 liquidity)
    external returns (SettlementOnRemoveMargin memory ss);

    function settleSymbolsOnTrade(address pTokenId, bytes32 symbolId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external returns (SettlementOnTrade memory ss);

    function settleSymbolsOnLiquidate(address pTokenId, bytes32 symbolId, int256 liquidity)
    external returns (SettlementOnLiquidate memory ss);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISymbol.sol';
import './SymbolStorage.sol';

contract Symbol is SymbolStorage {

    constructor (string memory symbol_) {
        symbol = symbol_;
    }

    function setImplementation(address newImplementation) external _onlyAdmin_ {
        address oldImplementation = implementation;
        if (oldImplementation != address(0)) {
            require(
                ISymbol(oldImplementation).manager() == ISymbol(newImplementation).manager(),
                'Symbol.setImplementation: wrong manager'
            );
            require(
                ISymbol(oldImplementation).symbolId() == ISymbol(newImplementation).symbolId(),
                'Symbol.setImplementation: wrong symbolId'
            );
        }
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

    fallback() external {
        address imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISymbol.sol';
import './SymbolStorage.sol';
import '../oracle/IOracleManager.sol';
import '../library/SafeMath.sol';
import '../library/DpmmLinearPricing.sol';
import '../utils/NameVersion.sol';

contract SymbolImplementationFutures is SymbolStorage, NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;

    address public immutable manager;

    address public immutable oracleManager;

    bytes32 public immutable symbolId;

    int256 public immutable feeRatio;

    int256 public immutable alpha;

    int256 public immutable fundingPeriod; // in seconds

    int256 public immutable minTradeVolume;

    int256 public immutable initialMarginRatio;

    int256 public immutable maintenanceMarginRatio;

    int256 public immutable pricePercentThreshold; // max price percent change to force settlement

    uint256 public immutable timeThreshold; // max time delay in seconds to force settlement

    int256 public immutable startingPriceShiftLimit; // Max price shift in percentage allowed before trade/liquidation

    bool   public immutable isCloseOnly;

    int256 public immutable maxLeverage;

    int256 public immutable marginRequiredRatio;

    modifier _onlyManager_() {
        require(msg.sender == manager, 'SymbolImplementationFutures: only manager');
        _;
    }

    constructor (
        address manager_,
        address oracleManager_,
        string memory symbol_,
        int256[11] memory parameters_,
        bool isCloseOnly_
    ) NameVersion('SymbolImplementationFutures', '3.0.2')
    {
        manager = manager_;
        oracleManager = oracleManager_;
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));

        feeRatio = parameters_[0];
        alpha = parameters_[1];
        fundingPeriod = parameters_[2];
        minTradeVolume = parameters_[3];
        initialMarginRatio = parameters_[4];
        maintenanceMarginRatio = parameters_[5];
        pricePercentThreshold = parameters_[6];
        timeThreshold = parameters_[7].itou();
        startingPriceShiftLimit = parameters_[8];
        maxLeverage = parameters_[9];
        marginRequiredRatio = parameters_[10];
        isCloseOnly = isCloseOnly_;

        require(
            IOracleManager(oracleManager_).value(symbolId) != 0,
            'SymbolImplementationFutures.constructor: no price oralce'
        );
    }

    function hasPosition(address pTokenId) external view returns (bool) {
        return positions[pTokenId].volume != 0;
    }

    //================================================================================

    function settleOnAddLiquidity(int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnAddLiquidity memory s)
    {
        Data memory data;

        if (_getNetVolumeAndCostWithSkip(data)) return s;
        if (_getTimestampAndPriceWithSkip(data)) return s;
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.settled = true;
        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
    }

    function settleOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnRemoveLiquidity memory s)
    {
        Data memory data;

        if (_getNetVolumeAndCostWithSkip(data)) return s;
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.settled = true;
        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.removeLiquidityPenalty = _getRemoveLiquidityPenalty(data, liquidity - removedLiquidity);

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
    }

    function settleOnTraderWithPosition(address pTokenId, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnTraderWithPosition memory s)
    {
        Data memory data;
        Position memory p = positions[pTokenId];
        if(p.volume == 0) return s;

        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        // Position memory p = positions[pTokenId];

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        int256 notional = p.volume * data.curIndexPrice / ONE;
        s.traderPnl = notional - p.cost;
        s.traderInitialMarginRequired = notional.abs() * initialMarginRatio / ONE;

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;

        positions[pTokenId].cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
    }

    // priceLimit: the average trade price cannot exceeds priceLimit
    // for long, averageTradePrice <= priceLimit; for short, averageTradePrice >= priceLimit
    function settleOnTrade(address pTokenId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external _onlyManager_ returns (ISymbol.SettlementOnTrade memory s)
    {
        _updateLastNetVolume();

        require(
            tradeVolume != 0 && tradeVolume % minTradeVolume == 0,
            'SymbolImplementationFutures.settleOnTrade: invalid tradeVolume'
        );

        Data memory data;
        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);

        Position memory p = positions[pTokenId];

        if (isCloseOnly) {
            require(
                (p.volume > 0 && tradeVolume < 0 && p.volume + tradeVolume >= 0) ||
                (p.volume < 0 && tradeVolume > 0 && p.volume + tradeVolume <= 0),
                'SymbolImplementationFutures.settleOnTrade: close only'
            );
        }

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.tradeCost = DpmmLinearPricing.calculateCost(
            data.curIndexPrice,
            data.K,
            data.netVolume,
            tradeVolume
        );
        s.tradeFee = s.tradeCost.abs() * feeRatio / ONE;

        // check slippage
        int256 averageTradePrice = s.tradeCost * ONE / tradeVolume;
        require(
            (tradeVolume > 0 && averageTradePrice <= priceLimit) ||
            (tradeVolume < 0 && averageTradePrice >= priceLimit),
            'SymbolImplementationFutures.settleOnTrade: slippage exceeds allowance'
        );

        if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = p.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                s.tradeRealizedCost = s.tradeCost * absVolume / absTradeVolume + p.cost;
            } else {
                s.tradeRealizedCost = p.cost * absTradeVolume / absVolume + s.tradeCost;
            }
        }

        // // same direction
        // if ((p.volume >= 0 && tradeVolume >= 0) || (p.volume <= 0 && tradeVolume <= 0)) {
        //     p.collateral += amountIn;
        // } else if ((p.volume >= 0 && tradeVolume + p.volume >= 0) || (p.volume <= 0 && tradeVolume + p.volume <= 0)){ 
        //     // opposite direction but not exceed position volume
        //     p.collateral += 0;
        // } else {
        //     // opposite direction and exceed position volume
        //     p.collateral = amountIn;
        // }
        // // pass collateral data from position struct to returning variable back to manager
        // s.collateral = p.collateral;

        data.netVolume += tradeVolume;
        data.netCost += s.tradeCost - s.tradeRealizedCost;
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        p.volume += tradeVolume;
        p.cost += s.tradeCost - s.tradeRealizedCost;
        p.cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        // s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.indexPrice = data.curIndexPrice;

        int256 notional = p.volume * data.curIndexPrice / ONE;
        s.traderPnl = notional - p.cost;
        // s.traderInitialMarginRequired = notional.abs() * initialMarginRatio / ONE;
        // int256 traderMaintenanceMarginRequired = notional.abs() * maintenanceMarginRatio / ONE;
        // s.marginRequired = notional.abs() / maxLeverage * ONE;
        s.marginRequired = p.cost.abs() / maxLeverage * ONE / marginRequiredRatio * ONE;

        if (p.volume == 0) {
            s.positionChangeStatus = -1;
            nPositionHolders--;
        } else if (p.volume - tradeVolume == 0) {
            s.positionChangeStatus = 1;
            nPositionHolders++;
        }

        netVolume = data.netVolume;
        netCost = data.netCost;
        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;

        positions[pTokenId] = p;
    }

    function settleOnLiquidate(address pTokenId, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnLiquidate memory s)
    {
        _updateLastNetVolume();

        Data memory data;

        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);

        Position memory p = positions[pTokenId];

        // check price shift
        int256 netVolumeShiftAllowance = startingPriceShiftLimit * ONE / data.K;
        require(
            (p.volume >= 0 && data.netVolume + netVolumeShiftAllowance >= lastNetVolume) ||
            (p.volume <= 0 && data.netVolume <= lastNetVolume + netVolumeShiftAllowance),
            'SymbolImplementationFutures.settleOnLiquidate: slippage exceeds allowance'
        );

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.tradeVolume = -p.volume;
        s.tradeCost = DpmmLinearPricing.calculateCost(
            data.curIndexPrice,
            data.K,
            data.netVolume,
            -p.volume
        );
        s.tradeRealizedCost = s.tradeCost + p.cost;

        data.netVolume -= p.volume;
        data.netCost -= p.cost;
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.indexPrice = data.curIndexPrice;

        int256 notional = p.volume * data.curIndexPrice / ONE;
        s.traderPnl = notional - p.cost;
        s.traderMaintenanceMarginRequired = notional.abs() * maintenanceMarginRatio / ONE;
        s.marginRequired = notional / maxLeverage * ONE;
        netVolume = data.netVolume;
        netCost = data.netCost;
        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
        if (p.volume != 0) {
            nPositionHolders--;
        }

        delete positions[pTokenId];
    }

    //================================================================================

    struct Data {
        uint256 preTimestamp;
        uint256 curTimestamp;
        int256 preIndexPrice;
        int256 curIndexPrice;
        int256 netVolume;
        int256 netCost;
        int256 cumulativeFundingPerVolume;
        int256 K;
        int256 tradersPnl;
        int256 initialMarginRequired;
        int256 funding;
    }

    function _getNetVolumeAndCost(Data memory data) internal view {
        data.netVolume = netVolume;
        data.netCost = netCost;
    }

    function _getNetVolumeAndCostWithSkip(Data memory data) internal view returns (bool) {
        data.netVolume = netVolume;
        if (data.netVolume == 0) {
            return true;
        }
        data.netCost = netCost;
        return false;
    }

    function _getTimestampAndPrice(Data memory data) internal view {
        data.preTimestamp = fundingTimestamp;
        data.curTimestamp = block.timestamp;
        data.curIndexPrice = IOracleManager(oracleManager).getValue(symbolId).utoi();
    }

    function _getTimestampAndPriceWithSkip(Data memory data) internal view returns (bool) {
        _getTimestampAndPrice(data);
        data.preIndexPrice = indexPrice;
        return (
            data.curTimestamp < data.preTimestamp + timeThreshold &&
            (data.curIndexPrice - data.preIndexPrice).abs() * ONE < data.preIndexPrice * pricePercentThreshold
        );
    }

    function _calculateK(int256 indexPrice, int256 liquidity) internal view returns (int256) {
        require(liquidity != 0, 'SymbolImplementationFutures._calculateK: liquidity is zero');
        return indexPrice * alpha / liquidity;
    }

    function _getFunding(Data memory data, int256 liquidity) internal view {
        data.cumulativeFundingPerVolume = cumulativeFundingPerVolume;
        data.K = _calculateK(data.curIndexPrice, liquidity);

        int256 markPrice = DpmmLinearPricing.calculateMarkPrice(data.curIndexPrice, data.K, data.netVolume);
        int256 diff = (markPrice - data.curIndexPrice) * (data.curTimestamp - data.preTimestamp).utoi() / fundingPeriod;
        data.funding = data.netVolume * diff / ONE;
        unchecked { data.cumulativeFundingPerVolume += diff; }
    }

    function _getTradersPnl(Data memory data) internal pure {
        data.tradersPnl = -DpmmLinearPricing.calculateCost(data.curIndexPrice, data.K, data.netVolume, -data.netVolume) - data.netCost;
    }

    function _getInitialMarginRequired(Data memory data) internal view {
        data.initialMarginRequired = data.netVolume.abs() * data.curIndexPrice / ONE * initialMarginRatio / ONE;
    }

    function _getRemoveLiquidityPenalty(Data memory data, int256 newLiquidity)
    internal view returns (int256)
    {
        int256 newK = _calculateK(data.curIndexPrice, newLiquidity);
        int256 newPnl = -DpmmLinearPricing.calculateCost(data.curIndexPrice, newK, data.netVolume, -data.netVolume) - data.netCost;
        return newPnl - data.tradersPnl;
    }

    // update lastNetVolume if this is the first transaction in current block
    function _updateLastNetVolume() internal {
        if (block.number > lastNetVolumeBlock) {
            lastNetVolume = netVolume;
            lastNetVolumeBlock = block.number;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISymbol.sol';
import './SymbolStorage.sol';
import '../oracle/IOracleManager.sol';
import '../library/SafeMath.sol';
import '../library/DpmmLinearPricing.sol';
import '../utils/NameVersion.sol';
import '../library/FuturesPricing.sol';

contract SymbolImplementationFuturesV2 is SymbolStorage, NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;

    address public immutable manager;

    address public immutable oracleManager;

    bytes32 public immutable symbolId;

    int256 public immutable feeRatio;

    int256 public immutable alpha;

    int256 public immutable fundingPeriod; // in seconds

    int256 public immutable minTradeVolume;

    int256 public immutable initialMarginRatio;

    int256 public immutable maintenanceMarginRatio;

    int256 public immutable pricePercentThreshold; // max price percent change to force settlement

    uint256 public immutable timeThreshold; // max time delay in seconds to force settlement

    int256 public immutable startingPriceShiftLimit; // Max price shift in percentage allowed before trade/liquidation

    bool   public immutable isCloseOnly;

    int256 public immutable decimals;

    int256 public immutable maxLeverage;

    int256 public immutable marginRequiredRatio;


    int256 public immutable openBetaBasisPoints = 7500000000000000;
    int256 public immutable closeBetaBasisPoints = 5200000000000000;
    int256 public immutable alphaBasisPoints = 2000000000000000;
    

    modifier _onlyManager_() {
        require(msg.sender == manager, 'SymbolImplementationFutures: only manager');
        _;
    }

    constructor (
        address manager_,
        address oracleManager_,
        string memory symbol_,
        int256[12] memory parameters_,
        bool isCloseOnly_
    ) NameVersion('SymbolImplementationFutures', '3.0.2')
    {
        manager = manager_;
        oracleManager = oracleManager_;
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));

        feeRatio = parameters_[0];
        alpha = parameters_[1];
        fundingPeriod = parameters_[2];
        minTradeVolume = parameters_[3];
        initialMarginRatio = parameters_[4];
        maintenanceMarginRatio = parameters_[5];
        pricePercentThreshold = parameters_[6];
        timeThreshold = parameters_[7].itou();
        startingPriceShiftLimit = parameters_[8];
        decimals = parameters_[9];
        maxLeverage = parameters_[10];
        marginRequiredRatio = parameters_[10];
        isCloseOnly = isCloseOnly_;

        require(
            IOracleManager(oracleManager_).value(symbolId) != 0,
            'SymbolImplementationFutures.constructor: no price oralce'
        );
    }

    function hasPosition(address pTokenId) external view returns (bool) {
        return positions[pTokenId].volume != 0;
    }

    //================================================================================

    function settleOnAddLiquidity(int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnAddLiquidity memory s)
    {
        Data memory data;

        if (_getNetVolumeAndCostWithSkip(data)) return s;
        if (_getTimestampAndPriceWithSkip(data)) return s;
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.settled = true;
        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
    }

    function settleOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnRemoveLiquidity memory s)
    {
        Data memory data;

        if (_getNetVolumeAndCostWithSkip(data)) return s;
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.settled = true;
        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.removeLiquidityPenalty = _getRemoveLiquidityPenalty(data, liquidity - removedLiquidity);

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
    }

    function settleOnTraderWithPosition(address pTokenId, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnTraderWithPosition memory s)
    {
        Data memory data;
        Position memory p = positions[pTokenId];
        if(p.volume == 0) return s;
        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        // Position memory p = positions[pTokenId];

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        int256 notional = p.volume * data.curIndexPrice / ONE;
        s.traderPnl = notional - p.cost;
        s.traderInitialMarginRequired = notional.abs() * initialMarginRatio / ONE;

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;

        positions[pTokenId].cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
    }

    // priceLimit: the average trade price cannot exceeds priceLimit
    // for long, averageTradePrice <= priceLimit; for short, averageTradePrice >= priceLimit
    function settleOnTrade(address pTokenId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external _onlyManager_ returns (ISymbol.SettlementOnTrade memory s)
    {
        _updateLastNetVolume();

        require(
            tradeVolume != 0 && tradeVolume % minTradeVolume == 0,
            'SymbolImplementationFutures.settleOnTrade: invalid tradeVolume'
        );

        Data memory data;
        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);

        Position memory p = positions[pTokenId];

        if (isCloseOnly) {
            require(
                (p.volume > 0 && tradeVolume < 0 && p.volume + tradeVolume >= 0) ||
                (p.volume < 0 && tradeVolume > 0 && p.volume + tradeVolume <= 0),
                'SymbolImplementationFutures.settleOnTrade: close only'
            );
        }

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.tradeCost = DpmmLinearPricing.calculateCost(
            data.curIndexPrice,
            data.K,
            data.netVolume,
            tradeVolume
        );
        s.tradeFee = s.tradeCost.abs() * feeRatio / ONE;

        // check slippage
        int256 averageTradePrice = s.tradeCost * ONE / tradeVolume;
        require(
            (tradeVolume > 0 && averageTradePrice <= priceLimit) ||
            (tradeVolume < 0 && averageTradePrice >= priceLimit),
            'SymbolImplementationFutures.settleOnTrade: slippage exceeds allowance'
        );

        if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = p.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                s.tradeRealizedCost = s.tradeCost * absVolume / absTradeVolume + p.cost;
            } else {
                s.tradeRealizedCost = p.cost * absTradeVolume / absVolume + s.tradeCost;
            }
        }

        data.netVolume += tradeVolume;
        data.netCost += s.tradeCost - s.tradeRealizedCost;
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        p.volume += tradeVolume;
        p.cost += s.tradeCost - s.tradeRealizedCost;
        p.cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        // s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.indexPrice = data.curIndexPrice;

        int256 notional = p.volume * data.curIndexPrice / ONE;
        s.traderPnl = notional - p.cost;
        // s.traderInitialMarginRequired = notional.abs() * initialMarginRatio / ONE;
        s.marginRequired = p.cost.abs() / maxLeverage * ONE / marginRequiredRatio * ONE;

        if (p.volume == 0) {
            s.positionChangeStatus = -1;
            nPositionHolders--;
        } else if (p.volume - tradeVolume == 0) {
            s.positionChangeStatus = 1;
            nPositionHolders++;
        }

        netVolume = data.netVolume;
        netCost = data.netCost;
        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;

        positions[pTokenId] = p;
    }

    function settleOnLiquidate(address pTokenId, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnLiquidate memory s)
    {
        _updateLastNetVolume();

        Data memory data;

        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);

        Position memory p = positions[pTokenId];

        // check price shift
        int256 netVolumeShiftAllowance = startingPriceShiftLimit * ONE / data.K;
        require(
            (p.volume >= 0 && data.netVolume + netVolumeShiftAllowance >= lastNetVolume) ||
            (p.volume <= 0 && data.netVolume <= lastNetVolume + netVolumeShiftAllowance),
            'SymbolImplementationFutures.settleOnLiquidate: slippage exceeds allowance'
        );

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.tradeVolume = -p.volume;
        s.tradeCost = DpmmLinearPricing.calculateCost(
            data.curIndexPrice,
            data.K,
            data.netVolume,
            -p.volume
        );
        s.tradeRealizedCost = s.tradeCost + p.cost;

        data.netVolume -= p.volume;
        data.netCost -= p.cost;
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.indexPrice = data.curIndexPrice;

        int256 notional = p.volume * data.curIndexPrice / ONE;
        s.traderPnl = notional - p.cost;
        s.traderMaintenanceMarginRequired = notional.abs() * maintenanceMarginRatio / ONE;

        netVolume = data.netVolume;
        netCost = data.netCost;
        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
        if (p.volume != 0) {
            nPositionHolders--;
        }

        delete positions[pTokenId];
    }

    //================================================================================

    struct Data {
        uint256 preTimestamp;
        uint256 curTimestamp;
        int256 preIndexPrice;
        int256 curIndexPrice;
        int256 netVolume;
        int256 netCost;
        int256 cumulativeFundingPerVolume;
        int256 K;
        int256 tradersPnl;
        int256 initialMarginRequired;
        int256 funding;
    }

    function _getNetVolumeAndCost(Data memory data) internal view {
        data.netVolume = netVolume;
        data.netCost = netCost;
    }

    function _getNetVolumeAndCostWithSkip(Data memory data) internal view returns (bool) {
        data.netVolume = netVolume;
        if (data.netVolume == 0) {
            return true;
        }
        data.netCost = netCost;
        return false;
    }

    function _getTimestampAndPrice(Data memory data) internal view {
        data.preTimestamp = fundingTimestamp;
        data.curTimestamp = block.timestamp;
        data.curIndexPrice = IOracleManager(oracleManager).getValue(symbolId).utoi();
    }

    function _getTimestampAndPriceWithSkip(Data memory data) internal view returns (bool) {
        _getTimestampAndPrice(data);
        data.preIndexPrice = indexPrice;
        return (
            data.curTimestamp < data.preTimestamp + timeThreshold &&
            (data.curIndexPrice - data.preIndexPrice).abs() * ONE < data.preIndexPrice * pricePercentThreshold
        );
    }

    function _calculateK(int256 indexPrice, int256 liquidity) internal view returns (int256) {
        return indexPrice * alpha / liquidity;
    }

    function _getFunding(Data memory data, int256 liquidity) internal view {
        data.cumulativeFundingPerVolume = cumulativeFundingPerVolume;
        data.K = _calculateK(data.curIndexPrice, liquidity);

        int256 markPrice = DpmmLinearPricing.calculateMarkPrice(data.curIndexPrice, data.K, data.netVolume);

    //     (
    //     int256 indexPrice,
    //     int256 liquidity,
    //     int256 netVolume, // index price * net volume / 10 ** decimals
    //     int256 tradersVolume,
    //     int256 beta,
    //     int256 alpha,
    //     int256 decimals
    // )
        // int256 markPrice = FuturesPricing.calculateMarkPrice(data.curIndexPrice, data.liquidity, data.netVolume, data.);
        int256 diff = (markPrice - data.curIndexPrice) * (data.curTimestamp - data.preTimestamp).utoi() / fundingPeriod;
        data.funding = data.netVolume * diff / ONE;
        unchecked { data.cumulativeFundingPerVolume += diff; }
    }

    function _getTradersPnl(Data memory data) internal pure {
        data.tradersPnl = -DpmmLinearPricing.calculateCost(data.curIndexPrice, data.K, data.netVolume, -data.netVolume) - data.netCost;
    }

    function _getInitialMarginRequired(Data memory data) internal view {
        data.initialMarginRequired = data.netVolume.abs() * data.curIndexPrice / ONE * initialMarginRatio / ONE;
    }

    function _getRemoveLiquidityPenalty(Data memory data, int256 newLiquidity)
    internal view returns (int256)
    {
        int256 newK = _calculateK(data.curIndexPrice, newLiquidity);
        int256 newPnl = -DpmmLinearPricing.calculateCost(data.curIndexPrice, newK, data.netVolume, -data.netVolume) - data.netCost;
        return newPnl - data.tradersPnl;
    }

    // update lastNetVolume if this is the first transaction in current block
    function _updateLastNetVolume() internal {
        if (block.number > lastNetVolumeBlock) {
            lastNetVolume = netVolume;
            lastNetVolumeBlock = block.number;
        }
    }

    // function getPiNetUsd(int256 _price) public view returns (int256) {
    //     return netVolume * _price / 10 ** decimals;
    // }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISymbol.sol';
import './SymbolStorage.sol';
import '../oracle/IOracleManager.sol';
import '../library/SafeMath.sol';
import '../library/DpmmLinearPricing.sol';
import '../library/EverlastingOptionPricing.sol';
import '../utils/NameVersion.sol';

contract SymbolImplementationOption is SymbolStorage, NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;

    address public immutable manager;

    address public immutable oracleManager;

    bytes32 public immutable symbolId;

    bytes32 public immutable  priceId; // used to get indexPrice from oracleManager

    bytes32 public immutable volatilityId; // used to get volatility from oracleManager

    int256 public immutable feeRatioITM;

    int256 public immutable feeRatioOTM;

    int256 public immutable strikePrice;

    int256 public immutable alpha;

    int256 public immutable fundingPeriod; // in seconds (without 1e18 base)

    int256 public immutable minTradeVolume;

    int256 public immutable minInitialMarginRatio;

    int256 public immutable initialMarginRatio;

    int256 public immutable maintenanceMarginRatio;

    int256 public immutable pricePercentThreshold; // max price percent change to force settlement

    uint256 public immutable timeThreshold; // max time delay in seconds (without 1e18 base) to force settlement

    int256 public immutable startingPriceShiftLimit; // Max price shift in percentage allowed before trade/liquidation

    bool   public immutable isCall;

    bool   public immutable isCloseOnly;

    int256 public immutable maxLeverage;

    int256 public immutable marginRequiredRatio;

    modifier _onlyManager_() {
        require(msg.sender == manager, 'SymbolImplementationOption: only manager');
        _;
    }

    constructor (
        address manager_,
        address oracleManager_,
        string[3] memory symbols_,
        int256[14] memory parameters_,
        bool[2] memory boolParameters_
    ) NameVersion('SymbolImplementationOption', '3.0.2')
    {
        manager = manager_;
        oracleManager = oracleManager_;

        symbol = symbols_[0];
        symbolId = keccak256(abi.encodePacked(symbols_[0]));
        priceId = keccak256(abi.encodePacked(symbols_[1]));
        volatilityId = keccak256(abi.encodePacked(symbols_[2]));

        feeRatioITM = parameters_[0];
        feeRatioOTM = parameters_[1];
        strikePrice = parameters_[2];
        alpha = parameters_[3];
        fundingPeriod = parameters_[4];
        minTradeVolume = parameters_[5];
        minInitialMarginRatio = parameters_[6];
        initialMarginRatio = parameters_[7];
        maintenanceMarginRatio = parameters_[8];
        pricePercentThreshold = parameters_[9];
        timeThreshold = parameters_[10].itou();
        startingPriceShiftLimit = parameters_[11];
        maxLeverage = parameters_[12];
        marginRequiredRatio = parameters_[13];

        isCall = boolParameters_[0];
        isCloseOnly = boolParameters_[1];

        require(
            IOracleManager(oracleManager).value(priceId) != 0,
            'SymbolImplementationOption.constructor: no price oracle'
        );
        require(
            IOracleManager(oracleManager).value(volatilityId) != 0,
            'SymbolImplementationOption.constructor: no volatility oracle'
        );
    }

    function hasPosition(address pTokenId) external view returns (bool) {
        return positions[pTokenId].volume != 0;
    }

    //================================================================================

    function settleOnAddLiquidity(int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnAddLiquidity memory s)
    {
        Data memory data;

        if (_getNetVolumeAndCostWithSkip(data)) return s;
        if (_getTimestampAndPriceWithSkip(data)) return s;
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.settled = true;
        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
    }

    function settleOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnRemoveLiquidity memory s)
    {
        Data memory data;

        if (_getNetVolumeAndCostWithSkip(data)) return s;
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.settled = true;
        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.removeLiquidityPenalty = _getRemoveLiquidityPenalty(data, liquidity - removedLiquidity);

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
    }

    function settleOnTraderWithPosition(address pTokenId, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnTraderWithPosition memory s)
    {
        Data memory data;
        Position memory p = positions[pTokenId];
        if(p.volume == 0) return s;
        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        // Position memory p = positions[pTokenId];

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.traderPnl = p.volume * data.theoreticalPrice / ONE - p.cost;
        s.traderInitialMarginRequired = p.volume.abs() * data.initialMarginPerVolume / ONE;

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;

        positions[pTokenId].cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
    }

    // priceLimit: the average trade price cannot exceeds priceLimit
    // for long, averageTradePrice <= priceLimit; for short, averageTradePrice >= priceLimit
    function settleOnTrade(address pTokenId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external _onlyManager_ returns (ISymbol.SettlementOnTrade memory s)
    {
        _updateLastNetVolume();

        require(
            tradeVolume != 0 && tradeVolume % minTradeVolume == 0,
            'SymbolImplementationOption.settleOnTrade: invalid tradeVolume'
        );

        Data memory data;
        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);

        Position memory p = positions[pTokenId];

        if (isCloseOnly) {
            require(
                (p.volume > 0 && tradeVolume < 0 && p.volume + tradeVolume >= 0) ||
                (p.volume < 0 && tradeVolume > 0 && p.volume + tradeVolume <= 0),
                'SymbolImplementationOption.settleOnTrade: close only'
            );
        }

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.tradeCost = DpmmLinearPricing.calculateCost(
            data.theoreticalPrice,
            data.K,
            data.netVolume,
            tradeVolume
        );

        if (data.intrinsicValue > 0) {
            s.tradeFee = data.curIndexPrice * tradeVolume.abs() / ONE * feeRatioITM / ONE;
        } else {
            s.tradeFee = s.tradeCost.abs() * feeRatioOTM / ONE;
        }

        // check slippage
        int256 averageTradePrice = s.tradeCost * ONE / tradeVolume;
        require(
            (tradeVolume > 0 && averageTradePrice <= priceLimit) ||
            (tradeVolume < 0 && averageTradePrice >= priceLimit),
            'SymbolImplementationOption.settleOnTrade: slippage exceeds allowance'
        );

        if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = p.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                s.tradeRealizedCost = s.tradeCost * absVolume / absTradeVolume + p.cost;
            } else {
                s.tradeRealizedCost = p.cost * absTradeVolume / absVolume + s.tradeCost;
            }
        }

        // if ((p.volume >= 0 && tradeVolume + p.volume >= 0) || (p.volume <= 0 && tradeVolume + p.volume <= 0)) {
        //     p.collateral += amountIn;
        // } else {
        //     p.collateral = amountIn;
        // }
        // // pass collateral data from position struct to returning variable back to manager
        // s.collateral = p.collateral;

        data.netVolume += tradeVolume;
        data.netCost += s.tradeCost - s.tradeRealizedCost;
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        p.volume += tradeVolume;
        p.cost += s.tradeCost - s.tradeRealizedCost;
        p.cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        // s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.indexPrice = data.curIndexPrice;

        s.traderPnl = p.volume * data.theoreticalPrice / ONE - p.cost;
        // s.marginRequired = p.volume.abs() * data.theoreticalPrice / maxLeverage;
        s.marginRequired = p.cost.abs() / maxLeverage * ONE / marginRequiredRatio * ONE;
        // s.traderInitialMarginRequired = p.volume.abs() * data.initialMarginPerVolume / ONE;
        
        // NOTSURE check amountIn is larger than maintenance margin
        // require(
        //     p.collateral.utoi() >= data.maintenanceMarginPerVolume / ONE * p.volume.abs(),
        //     Strings.toString(data.maintenanceMarginPerVolume.itou())
        //     // 'SymbolImplementationOption.settleOnTrade: amountIn less than maintenanceMarginRequired'
        // );

        if (p.volume == 0) {
            s.positionChangeStatus = -1;
            nPositionHolders--;
        } else if (p.volume - tradeVolume == 0) {
            s.positionChangeStatus = 1;
            nPositionHolders++;
        }

        netVolume = data.netVolume;
        netCost = data.netCost;
        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;

        positions[pTokenId] = p;
    }

    function settleOnLiquidate(address pTokenId, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnLiquidate memory s)
    {
        _updateLastNetVolume();

        Data memory data;

        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);

        Position memory p = positions[pTokenId];

        // check price shift
        int256 netVolumeShiftAllowance = startingPriceShiftLimit * ONE / data.K;
        require(
            (p.volume >= 0 && data.netVolume + netVolumeShiftAllowance >= lastNetVolume) ||
            (p.volume <= 0 && data.netVolume <= lastNetVolume + netVolumeShiftAllowance),
            'SymbolImplementationOption.settleOnLiquidate: slippage exceeds allowance'
        );

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.tradeVolume = -p.volume;
        s.tradeCost = DpmmLinearPricing.calculateCost(
            data.theoreticalPrice,
            data.K,
            data.netVolume,
            -p.volume
        );
        s.tradeRealizedCost = s.tradeCost + p.cost;

        data.netVolume -= p.volume;
        data.netCost -= p.cost;
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.indexPrice = data.curIndexPrice;

        s.traderPnl = p.volume * data.theoreticalPrice / ONE - p.cost;
        s.traderMaintenanceMarginRequired = p.volume.abs() * data.maintenanceMarginPerVolume / ONE;

        netVolume = data.netVolume;
        netCost = data.netCost;
        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
        if (p.volume != 0) {
            nPositionHolders--;
        }

        delete positions[pTokenId];
    }

    //================================================================================

    struct Data {
        uint256 preTimestamp;
        uint256 curTimestamp;
        int256 preIndexPrice;
        int256 curIndexPrice;
        int256 netVolume;
        int256 netCost;
        int256 cumulativeFundingPerVolume;
        int256 K;
        int256 tradersPnl;
        int256 initialMarginRequired;
        int256 funding;

        int256 intrinsicValue;
        int256 timeValue;
        int256 delta;
        int256 u;
        int256 theoreticalPrice;
        int256 initialMarginPerVolume;
        int256 maintenanceMarginPerVolume;
    }

    function _getNetVolumeAndCost(Data memory data) internal view {
        data.netVolume = netVolume;
        data.netCost = netCost;
    }

    function _getNetVolumeAndCostWithSkip(Data memory data) internal view returns (bool) {
        data.netVolume = netVolume;
        if (data.netVolume == 0) {
            return true;
        }
        data.netCost = netCost;
        return false;
    }

    function _getTimestampAndPrice(Data memory data) internal view {
        data.preTimestamp = fundingTimestamp;
        data.curTimestamp = block.timestamp;
        data.curIndexPrice = IOracleManager(oracleManager).getValue(priceId).utoi();
    }

    function _getTimestampAndPriceWithSkip(Data memory data) internal view returns (bool) {
        _getTimestampAndPrice(data);
        data.preIndexPrice = indexPrice;
        return (
            data.curTimestamp < data.preTimestamp + timeThreshold &&
            (data.curIndexPrice - data.preIndexPrice).abs() * ONE < data.preIndexPrice * pricePercentThreshold
        );
    }

    function _calculateK(int256 indexPrice, int256 theoreticalPrice, int256 delta, int256 liquidity)
    internal view returns (int256)
    {
        require(theoreticalPrice!=0, 'SymbolImplementationOption._calculateK: theoreticalPrice is zero');
        return indexPrice ** 2 / theoreticalPrice * delta.abs() * alpha / liquidity / ONE;
    }

    function _getFunding(Data memory data, int256 liquidity) internal view {
        data.cumulativeFundingPerVolume = cumulativeFundingPerVolume;

        int256 volatility = IOracleManager(oracleManager).getValue(volatilityId).utoi();
        data.intrinsicValue = isCall ?
                              (data.curIndexPrice - strikePrice).max(0) :
                              (strikePrice - data.curIndexPrice).max(0);
        (data.timeValue, data.delta, data.u) = EverlastingOptionPricing.getEverlastingTimeValueAndDelta(
            data.curIndexPrice, strikePrice, volatility, fundingPeriod * ONE / 31536000
        );
        data.theoreticalPrice = data.intrinsicValue + data.timeValue;

        if (data.intrinsicValue > 0) {
            if (isCall) data.delta += ONE;
            else data.delta -= ONE;
        } else if (data.curIndexPrice == strikePrice) {
            if (isCall) data.delta = ONE / 2;
            else data.delta = -ONE / 2;
        }

        data.K = _calculateK(data.curIndexPrice, data.theoreticalPrice, data.delta, liquidity);

        int256 markPrice = DpmmLinearPricing.calculateMarkPrice(
            data.theoreticalPrice, data.K, data.netVolume
        );
        int256 diff = (markPrice - data.intrinsicValue) * (data.curTimestamp - data.preTimestamp).utoi() / fundingPeriod;

        data.funding = data.netVolume * diff / ONE;
        unchecked { data.cumulativeFundingPerVolume += diff; }
    }

    function _getTradersPnl(Data memory data) internal pure {
        data.tradersPnl = -DpmmLinearPricing.calculateCost(data.theoreticalPrice, data.K, data.netVolume, -data.netVolume) - data.netCost;
    }

    function _getInitialMarginRequired(Data memory data) internal view {
        int256 deltaPart = data.delta * (isCall ? data.curIndexPrice : -data.curIndexPrice) / ONE * maintenanceMarginRatio / ONE;
        int256 gammaPart = (data.u * data.u / ONE - ONE) * data.timeValue / ONE / 8 * maintenanceMarginRatio / ONE * maintenanceMarginRatio / ONE;
        data.maintenanceMarginPerVolume = deltaPart + gammaPart;
        data.initialMarginPerVolume = (data.curIndexPrice * minInitialMarginRatio / ONE).max(
            data.maintenanceMarginPerVolume * initialMarginRatio / maintenanceMarginRatio
        );
        data.initialMarginRequired = data.netVolume.abs() * data.initialMarginPerVolume / ONE;
    }

    function _getRemoveLiquidityPenalty(Data memory data, int256 newLiquidity)
    internal view returns (int256)
    {
        int256 newK = _calculateK(data.curIndexPrice, data.theoreticalPrice, data.delta, newLiquidity);
        int256 newPnl = -DpmmLinearPricing.calculateCost(data.theoreticalPrice, newK, data.netVolume, -data.netVolume) - data.netCost;
        return newPnl - data.tradersPnl;
    }

    // update lastNetVolume if this is the first transaction in current block
    function _updateLastNetVolume() internal {
        if (block.number > lastNetVolumeBlock) {
            lastNetVolume = netVolume;
            lastNetVolumeBlock = block.number;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISymbol.sol';
import './SymbolStorage.sol';
import '../oracle/IOracleManager.sol';
import '../library/SafeMath.sol';
import '../library/DpmmLinearPricing.sol';
import '../utils/NameVersion.sol';

contract SymbolImplementationPower is SymbolStorage, NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;

    uint256 public constant power = 2;

    address public immutable manager;

    address public immutable oracleManager;

    bytes32 public immutable symbolId;

    bytes32 public immutable priceId; // used to get indexPrice from oracleManager

    bytes32 public immutable volatilityId; // used to get volatility from oracleManager

    int256 public immutable feeRatio;

    int256 public immutable alpha;

    int256 public immutable fundingPeriod; // in seconds (without 1e18 base)

    int256 public immutable minTradeVolume;

    int256 public immutable initialMarginRatio;

    int256 public immutable maintenanceMarginRatio;

    int256 public immutable pricePercentThreshold; // max price percent change to force settlement

    uint256 public immutable timeThreshold; // max time delay in seconds (without 1e18 base) to force settlement

    int256 public immutable startingPriceShiftLimit; // Max price shift in percentage allowed before trade/liquidation

    bool   public immutable isCloseOnly;

    int256 public immutable maxLeverage;

    int256 public immutable marginRequiredRatio;

    modifier _onlyManager_() {
        require(msg.sender == manager, 'SymbolImplementationPower: only manager');
        _;
    }

    constructor (
        address manager_,
        address oracleManager_,
        string[3] memory symbols_,
        int256[11] memory parameters_,
        bool isCloseOnly_
    ) NameVersion('SymbolImplementationPower', '3.0.2')
    {
        manager = manager_;
        oracleManager = oracleManager_;

        symbol = symbols_[0];
        symbolId = keccak256(abi.encodePacked(symbols_[0]));
        priceId = keccak256(abi.encodePacked(symbols_[1]));
        volatilityId = keccak256(abi.encodePacked(symbols_[2]));

        feeRatio = parameters_[0];
        alpha = parameters_[1];
        fundingPeriod = parameters_[2];
        minTradeVolume = parameters_[3];
        initialMarginRatio = parameters_[4];
        maintenanceMarginRatio = parameters_[5];
        pricePercentThreshold = parameters_[6];
        timeThreshold = parameters_[7].itou();
        startingPriceShiftLimit = parameters_[8];
        maxLeverage = parameters_[9];
        marginRequiredRatio = parameters_[10];
        isCloseOnly = isCloseOnly_;

        require(
            IOracleManager(oracleManager).value(priceId) != 0,
            'SymbolImplementationPower.constructor: no price oracle'
        );
        require(
            IOracleManager(oracleManager).value(volatilityId) != 0,
            'SymbolImplementationPower.constructor: no volatility oracle'
        );
    }

    function hasPosition(address pTokenId) external view returns (bool) {
        return positions[pTokenId].volume != 0;
    }

    //================================================================================

    function settleOnAddLiquidity(int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnAddLiquidity memory s)
    {
        Data memory data;

        if (_getNetVolumeAndCostWithSkip(data)) return s;
        if (_getTimestampAndPriceWithSkip(data)) return s;
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.settled = true;
        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
    }

    function settleOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnRemoveLiquidity memory s)
    {
        Data memory data;

        if (_getNetVolumeAndCostWithSkip(data)) return s;
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.settled = true;
        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.removeLiquidityPenalty = _getRemoveLiquidityPenalty(data, liquidity - removedLiquidity);

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
    }

    function settleOnTraderWithPosition(address pTokenId, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnTraderWithPosition memory s)
    {
        Data memory data;
        Position memory p = positions[pTokenId];
        if(p.volume == 0) return s;
        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        // Position memory p = positions[pTokenId];

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.traderPnl = p.volume * data.theoreticalPrice / ONE - p.cost;
        s.traderInitialMarginRequired = p.volume.abs() * data.initialMarginPerVolume / ONE;

        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;

        positions[pTokenId].cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
    }

    // priceLimit: the average trade price cannot exceeds priceLimit
    // for long, averageTradePrice <= priceLimit; for short, averageTradePrice >= priceLimit
    function settleOnTrade(address pTokenId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external _onlyManager_ returns (ISymbol.SettlementOnTrade memory s)
    {
        _updateLastNetVolume();

        require(
            tradeVolume != 0 && tradeVolume % minTradeVolume == 0,
            'SymbolImplementationPower.settleOnTrade: invalid tradeVolume'
        );

        Data memory data;
        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);

        Position memory p = positions[pTokenId];

        if (isCloseOnly) {
            require(
                (p.volume > 0 && tradeVolume < 0 && p.volume + tradeVolume >= 0) ||
                (p.volume < 0 && tradeVolume > 0 && p.volume + tradeVolume <= 0),
                'SymbolImplementationPower.settleOnTrade: close only'
            );
        }

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.tradeCost = DpmmLinearPricing.calculateCost(
            data.theoreticalPrice,
            data.K,
            data.netVolume,
            tradeVolume
        );
        s.tradeFee = s.tradeCost.abs() * feeRatio / ONE;

        // check slippage
        int256 averageTradePrice = s.tradeCost * ONE / tradeVolume;
        require(
            (tradeVolume > 0 && averageTradePrice <= priceLimit) ||
            (tradeVolume < 0 && averageTradePrice >= priceLimit),
            'SymbolImplementationPower.settleOnTrade: slippage exceeds allowance'
        );

        if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = p.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                s.tradeRealizedCost = s.tradeCost * absVolume / absTradeVolume + p.cost;
            } else {
                s.tradeRealizedCost = p.cost * absTradeVolume / absVolume + s.tradeCost;
            }
        }

        data.netVolume += tradeVolume;
        data.netCost += s.tradeCost - s.tradeRealizedCost;
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        p.volume += tradeVolume;
        p.cost += s.tradeCost - s.tradeRealizedCost;
        p.cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        // s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.indexPrice = data.curIndexPrice;

        s.traderPnl = p.volume * data.theoreticalPrice / ONE - p.cost;
        s.marginRequired = p.cost.abs() / maxLeverage * ONE / marginRequiredRatio * ONE;
        // s.traderInitialMarginRequired = p.volume.abs() * data.initialMarginPerVolume / ONE;

        // NOTSURE check amountIn is larger than maintenance margin
        // require(
        //     amountIn.utoi() >= data.maintenanceMarginPerVolume / ONE * tradeVolume.abs(),
        //     'SymbolImplementationPower.settleOnTrade: amountIn less than maintenanceMarginRequired'
        // );

        if (p.volume == 0) {
            s.positionChangeStatus = -1;
            nPositionHolders--;
        } else if (p.volume - tradeVolume == 0) {
            s.positionChangeStatus = 1;
            nPositionHolders++;
        }

        netVolume = data.netVolume;
        netCost = data.netCost;
        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;

        positions[pTokenId] = p;
    }

    function settleOnLiquidate(address pTokenId, int256 liquidity)
    external _onlyManager_ returns (ISymbol.SettlementOnLiquidate memory s)
    {
        _updateLastNetVolume();

        Data memory data;

        _getNetVolumeAndCost(data);
        _getTimestampAndPrice(data);
        _getFunding(data, liquidity);

        Position memory p = positions[pTokenId];

        // check price shift
        int256 netVolumeShiftAllowance = startingPriceShiftLimit * ONE / data.K;
        require(
            (p.volume >= 0 && data.netVolume + netVolumeShiftAllowance >= lastNetVolume) ||
            (p.volume <= 0 && data.netVolume <= lastNetVolume + netVolumeShiftAllowance),
            'SymbolImplementationPower.settleOnLiquidate: slippage exceeds allowance'
        );

        int256 diff;
        unchecked { diff = data.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume; }
        s.traderFunding = p.volume * diff / ONE;

        s.tradeVolume = -p.volume;
        s.tradeCost = DpmmLinearPricing.calculateCost(
            data.theoreticalPrice,
            data.K,
            data.netVolume,
            -p.volume
        );
        s.tradeRealizedCost = s.tradeCost + p.cost;

        data.netVolume -= p.volume;
        data.netCost -= p.cost;
        _getTradersPnl(data);
        _getInitialMarginRequired(data);

        s.funding = data.funding;
        s.deltaTradersPnl = data.tradersPnl - tradersPnl;
        s.deltaInitialMarginRequired = data.initialMarginRequired - initialMarginRequired;
        s.indexPrice = data.curIndexPrice;

        s.traderPnl = p.volume * data.theoreticalPrice / ONE - p.cost;
        s.traderMaintenanceMarginRequired = p.volume.abs() * data.maintenanceMarginPerVolume / ONE;

        netVolume = data.netVolume;
        netCost = data.netCost;
        indexPrice = data.curIndexPrice;
        fundingTimestamp = data.curTimestamp;
        cumulativeFundingPerVolume = data.cumulativeFundingPerVolume;
        tradersPnl = data.tradersPnl;
        initialMarginRequired = data.initialMarginRequired;
        if (p.volume != 0) {
            nPositionHolders--;
        }

        delete positions[pTokenId];
    }

    //================================================================================

    struct Data {
        uint256 preTimestamp;
        uint256 curTimestamp;
        int256 preIndexPrice;
        int256 curIndexPrice;
        int256 netVolume;
        int256 netCost;
        int256 cumulativeFundingPerVolume;
        int256 K;
        int256 tradersPnl;
        int256 initialMarginRequired;
        int256 funding;

        int256 powerPrice; // S**p
        int256 theoreticalPrice; // S**p / (1 - hT)
        int256 initialMarginPerVolume;
        int256 maintenanceMarginPerVolume;
    }

    function _getNetVolumeAndCost(Data memory data) internal view {
        data.netVolume = netVolume;
        data.netCost = netCost;
    }

    function _getNetVolumeAndCostWithSkip(Data memory data) internal view returns (bool) {
        data.netVolume = netVolume;
        if (data.netVolume == 0) {
            return true;
        }
        data.netCost = netCost;
        return false;
    }

    function _getTimestampAndPrice(Data memory data) internal view {
        data.preTimestamp = fundingTimestamp;
        data.curTimestamp = block.timestamp;
        data.curIndexPrice = IOracleManager(oracleManager).getValue(priceId).utoi();
    }

    function _getTimestampAndPriceWithSkip(Data memory data) internal view returns (bool) {
        _getTimestampAndPrice(data);
        data.preIndexPrice = indexPrice;
        return (
            data.curTimestamp < data.preTimestamp + timeThreshold &&
            (data.curIndexPrice - data.preIndexPrice).abs() * ONE < data.preIndexPrice * pricePercentThreshold
        );
    }

    function _calculateK(int256 theoreticalPrice, int256 liquidity) internal view returns (int256) {
        return int256(power) * theoreticalPrice * alpha / liquidity;
    }

    function _getFunding(Data memory data, int256 liquidity) internal view {
        data.cumulativeFundingPerVolume = cumulativeFundingPerVolume;

        int256 volatility = IOracleManager(oracleManager).getValue(volatilityId).utoi();
        int256 oneHT = ONE - volatility ** 2 / ONE * fundingPeriod / 31536000; // 1 - hT

        data.powerPrice = data.curIndexPrice ** 2 / ONE;
        data.theoreticalPrice = data.powerPrice * ONE / oneHT;

        data.K = _calculateK(data.theoreticalPrice, liquidity);

        int256 markPrice = DpmmLinearPricing.calculateMarkPrice(
            data.theoreticalPrice, data.K, data.netVolume
        );
        int256 diff = (markPrice - data.powerPrice) * (data.curTimestamp - data.preTimestamp).utoi() / fundingPeriod;

        data.funding = data.netVolume * diff / ONE;
        unchecked { data.cumulativeFundingPerVolume += diff; }
    }

    function _getTradersPnl(Data memory data) internal pure {
        data.tradersPnl = -DpmmLinearPricing.calculateCost(data.theoreticalPrice, data.K, data.netVolume, -data.netVolume) - data.netCost;
    }

    function _getInitialMarginRequired(Data memory data) internal view {
        data.maintenanceMarginPerVolume = data.theoreticalPrice * maintenanceMarginRatio / ONE;
        data.initialMarginPerVolume = data.maintenanceMarginPerVolume * initialMarginRatio / maintenanceMarginRatio;
        data.initialMarginRequired = data.netVolume.abs() * data.initialMarginPerVolume / ONE;
    }

    function _getRemoveLiquidityPenalty(Data memory data, int256 newLiquidity)
    internal view returns (int256)
    {
        int256 newK = _calculateK(data.theoreticalPrice, newLiquidity);
        int256 newPnl = -DpmmLinearPricing.calculateCost(data.theoreticalPrice, newK, data.netVolume, -data.netVolume) - data.netCost;
        return newPnl - data.tradersPnl;
    }

    // update lastNetVolume if this is the first transaction in current block
    function _updateLastNetVolume() internal {
        if (block.number > lastNetVolumeBlock) {
            lastNetVolume = netVolume;
            lastNetVolumeBlock = block.number;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISymbolManager.sol';
import './SymbolManagerStorage.sol';

contract SymbolManager is SymbolManagerStorage {

    function setImplementation(address newImplementation) external _onlyAdmin_ {
        address oldImplementation = implementation;
        if (oldImplementation != address(0)) {
            require(
                ISymbolManager(oldImplementation).pool() == ISymbolManager(newImplementation).pool(),
                'SymbolManager.setImplementation: wrong pool'
            );
        }
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

    fallback() external {
        address imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISymbol.sol';
import './ISymbolManager.sol';
import './SymbolManagerStorage.sol';
import '../utils/NameVersion.sol';

contract SymbolManagerImplementation is SymbolManagerStorage, NameVersion {

    event AddSymbol(bytes32 indexed symbolId, address indexed symbol);

    event RemoveSymbol(bytes32 indexed symbolId, address indexed symbol);

    event Trade(
        address indexed pTokenId,
        bytes32 indexed symbolId,
        int256 indexPrice,
        int256 tradeVolume,
        int256 tradeCost,
        int256 tradeFee
    );

    address public immutable pool;

    modifier _onlyPool_() {
        require(msg.sender == pool, 'SymbolManagerImplementation: only pool');
        _;
    }

    constructor (address pool_) NameVersion('SymbolManagerImplementation', '3.0.2') {
        pool = pool_;
    }

    function getActiveSymbols(address pTokenId) external view returns (address[] memory) {
        return activeSymbols[pTokenId];
    }

    function getSymbolsLength() external view returns (uint256) {
        return indexedSymbols.length;
    }

    function addSymbol(address symbol) external _onlyAdmin_ {
        bytes32 symbolId = ISymbol(symbol).symbolId();
        require(
            symbols[symbolId] == address(0),
            'SymbolManagerImplementation.addSymbol: symbol exists'
        );
        require(
            ISymbol(symbol).manager() == address(this),
            'SymbolManagerImplementation.addSymbol: wrong manager'
        );

        symbols[symbolId] = symbol;
        indexedSymbols.push(symbol);

        emit AddSymbol(symbolId, symbol);
    }

    function removeSymbol(bytes32 symbolId) external _onlyAdmin_ {
        address symbol = symbols[symbolId];
        require(
            symbol != address(0),
            'SymbolManagerImplementation.removeSymbol: symbol not exists'
        );
        require(
            ISymbol(symbol).nPositionHolders() == 0,
            'SymbolManagerImplementation.removeSymbol: symbol has positions'
        );

        delete symbols[symbolId];

        uint256 length = indexedSymbols.length;
        for (uint256 i = 0; i < length; i++) {
            if (indexedSymbols[i] == symbol) {
                indexedSymbols[i] = indexedSymbols[length-1];
                break;
            }
        }
        indexedSymbols.pop();

        emit RemoveSymbol(symbolId, symbol);
    }

    //================================================================================

    function settleSymbolsOnAddLiquidity(int256 liquidity)
    external _onlyPool_ returns (ISymbolManager.SettlementOnAddLiquidity memory ss)
    {
        if (liquidity == 0) return ss;

        int256 deltaInitialMarginRequired;
        uint256 length = indexedSymbols.length;

        for (uint256 i = 0; i < length; i++) {
            ISymbol.SettlementOnAddLiquidity memory s =
            ISymbol(indexedSymbols[i]).settleOnAddLiquidity(liquidity);

            if (s.settled) {
                ss.funding += s.funding;
                ss.deltaTradersPnl += s.deltaTradersPnl;

                deltaInitialMarginRequired += s.deltaInitialMarginRequired;
            }
        }

        initialMarginRequired += deltaInitialMarginRequired;
    }

    function settleSymbolsOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external _onlyPool_ returns (ISymbolManager.SettlementOnRemoveLiquidity memory ss)
    {
        int256 deltaInitialMarginRequired;
        uint256 length = indexedSymbols.length;

        for (uint256 i = 0; i < length; i++) {
            ISymbol.SettlementOnRemoveLiquidity memory s =
            ISymbol(indexedSymbols[i]).settleOnRemoveLiquidity(liquidity, removedLiquidity);

            if (s.settled) {
                ss.funding += s.funding;
                ss.deltaTradersPnl += s.deltaTradersPnl;
                ss.removeLiquidityPenalty += s.removeLiquidityPenalty;

                deltaInitialMarginRequired += s.deltaInitialMarginRequired;
            }
        }

        initialMarginRequired += deltaInitialMarginRequired;
        ss.initialMarginRequired = initialMarginRequired;
    }

    function settleSymbolsOnRemoveMargin(address pTokenId, bytes32 symbolId, int256 liquidity)
    external _onlyPool_ returns (ISymbolManager.SettlementOnRemoveMargin memory ss)
    {
        int256 deltaInitialMarginRequired;
        // uint256 length = activeSymbols[pTokenId].length;

        // for (uint256 i = 0; i < length; i++) {
        //     ISymbol.SettlementOnTraderWithPosition memory s =
        //     ISymbol(activeSymbols[pTokenId][i]).settleOnTraderWithPosition(pTokenId, liquidity);

        //     ss.funding += s.funding;
        //     ss.deltaTradersPnl += s.deltaTradersPnl;
        //     deltaInitialMarginRequired += s.deltaInitialMarginRequired;

        //     ss.traderFunding += s.traderFunding;
        //     ss.traderPnl += s.traderPnl;
        //     ss.traderInitialMarginRequired += s.traderInitialMarginRequired;
        // }
        address symbol = symbols[symbolId];
        ISymbol.SettlementOnTraderWithPosition memory s =
        ISymbol(symbol).settleOnTraderWithPosition(pTokenId, liquidity);

        ss.funding += s.funding;
        ss.deltaTradersPnl += s.deltaTradersPnl;
        deltaInitialMarginRequired += s.deltaInitialMarginRequired;

        ss.traderFunding += s.traderFunding;
        ss.traderPnl += s.traderPnl;
        ss.traderInitialMarginRequired += s.traderInitialMarginRequired;

        initialMarginRequired += deltaInitialMarginRequired;
    }

    function settleSymbolsOnTrade(address pTokenId, bytes32 symbolId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external _onlyPool_ returns (ISymbolManager.SettlementOnTrade memory ss)
    {
        address tradeSymbol = symbols[symbolId];
        require(
            tradeSymbol != address(0),
            'SymbolManagerImplementation.settleSymbolsOnTrade: invalid symbol'
        );

        int256 deltaInitialMarginRequired;
        // uint256 length = activeSymbols[pTokenId].length;

        // uint256 index = type(uint256).max;
        // for (uint256 i = 0; i < length; i++) {
        //     address symbol = activeSymbols[pTokenId][i];
        //     if (symbol != tradeSymbol) {
        //         ISymbol.SettlementOnTraderWithPosition memory s1 =
        //         ISymbol(symbol).settleOnTraderWithPosition(pTokenId, liquidity);

        //         ss.funding += s1.funding;
        //         ss.deltaTradersPnl += s1.deltaTradersPnl;
        //         deltaInitialMarginRequired += s1.deltaInitialMarginRequired;

        //         ss.traderFunding += s1.traderFunding;
        //         ss.traderPnl += s1.traderPnl;
        //         ss.traderInitialMarginRequired += s1.traderInitialMarginRequired;
        //     } else {
        //         index = i;
        //     }
        // }

        ISymbol.SettlementOnTrade memory s2 = ISymbol(tradeSymbol).settleOnTrade(pTokenId, tradeVolume, liquidity, priceLimit);
        ss.funding += s2.funding;
        ss.deltaTradersPnl += s2.deltaTradersPnl;
        // deltaInitialMarginRequired += s2.deltaInitialMarginRequired;

        ss.traderFunding += s2.traderFunding;
        ss.traderPnl += s2.traderPnl;
        // ss.traderInitialMarginRequired += s2.traderInitialMarginRequired;
        // ss.collateral += s2.collateral;

        ss.tradeFee = s2.tradeFee;
        ss.tradeRealizedCost = s2.tradeRealizedCost;
        ss.marginRequired = s2.marginRequired;
        // initialMarginRequired += deltaInitialMarginRequired;
        // ss.initialMarginRequired = initialMarginRequired;

        // if (index == type(uint256).max && s2.positionChangeStatus == 1) {
        //     activeSymbols[pTokenId].push(tradeSymbol);
        // } else if (index != type(uint256).max && s2.positionChangeStatus == -1) {
        //     activeSymbols[pTokenId][index] = activeSymbols[pTokenId][length-1];
        //     activeSymbols[pTokenId].pop();
        // }

        emit Trade(pTokenId, symbolId, s2.indexPrice, tradeVolume, s2.tradeCost, s2.tradeFee);
    }

    function settleSymbolsOnLiquidate(address pTokenId, bytes32 symbolId, int256 liquidity)
    external _onlyPool_ returns (ISymbolManager.SettlementOnLiquidate memory ss)
    {
        int256 deltaInitialMarginRequired;
        // uint256 length = activeSymbols[pTokenId].length;

        // for (uint256 i = 0; i < length; i++) {
        //     address symbol = activeSymbols[pTokenId][i];
        //     ISymbol.SettlementOnLiquidate memory s = ISymbol(symbol).settleOnLiquidate(pTokenId, liquidity);

        //     ss.funding += s.funding;
        //     ss.deltaTradersPnl += s.deltaTradersPnl;
        //     deltaInitialMarginRequired += s.deltaInitialMarginRequired;

        //     ss.traderFunding += s.traderFunding;
        //     ss.traderPnl += s.traderPnl;
        //     ss.traderMaintenanceMarginRequired += s.traderMaintenanceMarginRequired;

        //     ss.traderRealizedCost += s.tradeRealizedCost;

        //     emit Trade(pTokenId, ISymbol(symbol).symbolId(), s.indexPrice, s.tradeVolume, s.tradeCost, -1);
        // }

        address symbol = symbols[symbolId];
        ISymbol.SettlementOnLiquidate memory s = ISymbol(symbol).settleOnLiquidate(pTokenId, liquidity);

        ss.funding += s.funding;
        ss.deltaTradersPnl += s.deltaTradersPnl;
        deltaInitialMarginRequired += s.deltaInitialMarginRequired;

        ss.traderFunding += s.traderFunding;
        ss.traderPnl += s.traderPnl;
        ss.traderMaintenanceMarginRequired += s.traderMaintenanceMarginRequired;
        ss.marginRequired = s.marginRequired;
        ss.traderRealizedCost += s.tradeRealizedCost;

        emit Trade(pTokenId, ISymbol(symbol).symbolId(), s.indexPrice, s.tradeVolume, s.tradeCost, -1);

        initialMarginRequired += deltaInitialMarginRequired;

        // delete activeSymbols[pTokenId];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract SymbolManagerStorage is Admin {

    // admin will be truned in to Timelock after deployment

    event NewImplementation(address newImplementation);

    address public implementation;

    // symbolId => symbol
    mapping (bytes32 => address) public symbols;

    // indexed symbols for looping
    address[] public indexedSymbols;

    // pTokenId => active symbols array for specific pTokenId (with position)
    mapping (address => address[]) public activeSymbols;

    // total initial margin required for all symbols
    int256 public initialMarginRequired;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract SymbolStorage is Admin {

    // admin will be truned in to Timelock after deployment

    event NewImplementation(address newImplementation);

    address public implementation;

    string public symbol;

    int256 public netVolume;

    int256 public netCost;

    int256 public indexPrice;

    uint256 public fundingTimestamp;

    int256 public cumulativeFundingPerVolume;

    int256 public tradersPnl;

    int256 public initialMarginRequired;

    uint256 public nPositionHolders;

    struct Position {
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }

    // pTokenId => Position
    mapping (address => Position) public positions;

    // The recorded net volume at the beginning of current block
    // which only update once in one block and cannot be manipulated in one block
    int256 public lastNetVolume;

    // The block number in which lastNetVolume updated
    uint256 public lastNetVolumeBlock;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import '../../library/FuturesPricing.sol';

contract TestPricingLib {

function calculateMarkPrice(
        int256 indexPrice,
        int256 liquidity,
        int256 netVolume, // index price * net volume / 10 ** decimals
        int256 tradersVolume,
        int256 beta,
        int256 alpha,
        int256 decimals
    ) external view returns (int256)
    {
        return FuturesPricing.calculateMarkPrice(indexPrice, liquidity, netVolume, tradersVolume, beta, alpha, decimals);
    }


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
interface IKeep {
    function supply(address asset, uint256 amount, address onBehalfOf) external;
    function withdraw(address asset, uint256, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "./IKeep.sol";
import '../../library/SafeERC20.sol';
import '../../token/IERC20.sol';
import '../../token/IMintableToken.sol';
import "hardhat/console.sol";

contract Keep is IKeep {

    address public admin;
    using SafeERC20 for IERC20;
   


    mapping (address => address) public kTokens;

    function setKToken(address token, address kToken) external _onlyAdmin_ {
        kTokens[token] = kToken;
    }

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
    }

    function supply(address asset, uint256 amount, address onBehalfOf) external {
        address kToken = kTokens[asset];
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IMintableToken(kToken).mint(onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external {
        address kToken = kTokens[asset];
        require(IERC20(kToken).balanceOf(msg.sender) > amount, "Not enought balanace");
        IMintableToken(kToken).burn(msg.sender, amount);
        IERC20(asset).transfer(to, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import 'hardhat/console.sol';

library Log {

    function log(string memory name) internal view {
        console.log('\n==================== %s ====================', name);
    }

    function log(string memory value, string memory name) internal view {
        console.log('%s: %s', name, value);
    }

    function log(uint256 value, string memory name) internal view {
        console.log('%s: %s', name, value);
    }

    function log(int256 value, string memory name) internal view {
        if (value >= 0) console.log('%s: %s', name, uint256(value));
        else console.log('%s: -%s', name, uint256(-value));
    }

    function log(address value, string memory name) internal view {
        console.log('%s: %s', name, value);
    }

    function log(bool value, string memory name) internal view {
        console.log('%s: %s', name, value);
    }

    function log(bytes32 value, string memory name) internal view {
        console.log('%s:', name);
        console.logBytes32(value);
    }

    function log(bytes memory value, string memory name) internal view {
        console.log('%s:', name);
        console.logBytes(value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IPriceFeed.sol";

contract PriceFeed is IPriceFeed {
    int256 public answer;
    uint80 public roundId;
    string public override description = "PriceFeed";
    address public override aggregator;

    uint256 public decimals;

    address public gov;

    mapping (uint80 => int256) public answers;
    mapping (address => bool) public isAdmin;

    constructor() public {
        gov = msg.sender;
        isAdmin[msg.sender] = true;
    }

    function setAdmin(address _account, bool _isAdmin) public {
        require(msg.sender == gov, "PriceFeed: forbidden");
        isAdmin[_account] = _isAdmin;
    }

    function latestAnswer() public override view returns (int256) {
        return answer;
    }

    function latestRound() public override view returns (uint80) {
        return roundId;
    }

    function setLatestAnswer(int256 _answer) public {
        require(isAdmin[gov], "PriceFeed: forbidden");
        roundId = roundId + 1;
        answer = _answer;
        answers[roundId] = _answer;
    }

    // returns roundId, answer, startedAt, updatedAt, answeredInRound
    function getRoundData(uint80 _roundId) public override view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (_roundId, answers[_roundId], 0, 0, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IPriceFeed {
    function description() external view returns (string memory);
    function aggregator() external view returns (address);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/NameVersion.sol';

contract TestOracle is NameVersion {

    string public symbol;

    bytes32 public symbolId;

    uint256 public value;

    constructor (string memory symbol_) NameVersion('Oracle', '3.0.1') {
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));
    }

    function getValue() external view returns (uint256) {
        return value;
    }

    function setValue(uint256 newValue) external {
        value = newValue;
    }

}



// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#flash
/// @notice Any contract that calls IUniswapV3PoolActions#flash must implement this interface
interface IUniswapV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
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

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

/// @title An interface for a contract that is capable of deploying Uniswap V3 Pools
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
interface IUniswapV3PoolDeployer {
    /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    /// Returns factory The factory address
    /// Returns token0 The first token of the pool by address sort order
    /// Returns token1 The second token of the pool by address sort order
    /// Returns fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// Returns tickSpacing The minimum number of ticks between initialized ticks
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing
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
pragma solidity >=0.5.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

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

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for liquidity
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
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
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './BitMath.sol';

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick % 256));
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    /// @param tickSpacing The spacing between usable ticks
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        require(tick % tickSpacing == 0); // ensure that the tick is spaced
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(int8(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                : (compressed - int24(int8(bitPos))) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(int8(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                : (compressed + 1 + int24(int8((type(uint8).max - bitPos)))) * tickSpacing;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '../interfaces/IERC20Minimal.sol';

/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Calls transfer on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Interface for verifying contract-based account signatures
/// @notice Interface that verifies provided signature for the data
/// @dev Interface defined by EIP-1271
interface IERC1271 {
    /// @notice Returns whether the provided signature is valid for the provided data
    /// @dev MUST return the bytes4 magic value 0x1626ba7e when function passes.
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5).
    /// MUST allow external calls.
    /// @param hash Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    /// @return magicValue The bytes4 magic value 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Interface for permit
/// @notice Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
    /// @notice Approve the spender to spend some tokens via the holder signature
    /// @dev This is the permit interface used by DAI and CHAI
    /// @param holder The address of the token holder, the token owner
    /// @param spender The address of the token spender
    /// @param nonce The holder's nonce, increases at each call to permit
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
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
pragma solidity >=0.7.5;

import './IPeripheryPayments.sol';

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPaymentsWithFee is IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;
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

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Function for getting the current chain ID
library ChainId {
    /// @dev Gets the current chain ID
    /// @return chainId The current chain ID
    function get() internal view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
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
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IDToken.sol';
import './ERC721.sol';
import '../utils/NameVersion.sol';

contract DToken is IDToken, ERC721, NameVersion {

    address public immutable pool;

    string  public name;

    string  public symbol;

    uint256 public totalMinted;

    modifier _onlyPool_() {
        require(msg.sender == pool, 'DToken: only pool');
        _;
    }

    constructor (string memory name_, string memory symbol_, address pool_) NameVersion('DToken', '3.0.1') {
        name = name_;
        symbol = symbol_;
        pool = pool_;
    }

    function exists(address owner) external view returns (bool) {
        return _exists(owner);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // tokenId existence unchecked
    function getOwnerOf(uint256 tokenId) external view returns (address) {
        return _tokenIdOwner[tokenId];
    }

    // owner existence unchecked
    function getTokenIdOf(address owner) external view returns (uint256) {
        return _ownerTokenId[owner];
    }

    function mint(address owner) external _onlyPool_ returns (uint256) {
        require(!_exists(owner), 'DToken.mint: existent owner');

        uint256 tokenId = ++totalMinted;
        _ownerTokenId[owner] = tokenId;
        _tokenIdOwner[tokenId] = owner;

        emit Transfer(address(0), owner, tokenId);
        return tokenId;
    }

    function burn(uint256 tokenId) external _onlyPool_ {
        address owner = _tokenIdOwner[tokenId];
        require(owner != address(0), 'DToken.burn: nonexistent tokenId');

        delete _ownerTokenId[owner];
        delete _tokenIdOwner[tokenId];
        delete _tokenIdOperator[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC165.sol';

abstract contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC721Receiver.sol';
import './IERC721.sol';
import '../library/Address.sol';
import './ERC165.sol';

/**
 * @dev ERC721 Non-Fungible Token Implementation
 *
 * Exert uniqueness of owner: one owner can only have one token
 */
contract ERC721 is IERC721, ERC165 {

    using Address for address;

    /*
     * Equals to `bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'))`
     * which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
     */
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x081812fc ^ 0xe985e9c5 ^
     *        0x095ea7b3 ^ 0xa22cb465 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    // Mapping from owner address to tokenId
    // tokenId starts from 1, 0 is reserved for nonexistent token
    // One owner can only own one token in this contract
    mapping (address => uint256) _ownerTokenId;

    // Mapping from tokenId to owner
    mapping (uint256 => address) _tokenIdOwner;

    // Mapping from tokenId to approved operator
    mapping (uint256 => address) _tokenIdOperator;

    // Mapping from owner to operator for all approval
    mapping (address => mapping (address => bool)) _ownerOperator;

    constructor () {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _ownerTokenId[owner] != 0 ? 1 : 0;
    }

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        require(
            (owner = _tokenIdOwner[tokenId]) != address(0),
            'ERC721.ownerOf: nonexistent tokenId'
        );
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), 'ERC721.getApproved: nonexistent tokenId');
        return _tokenIdOperator[tokenId];
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        require(_exists(owner), 'ERC721.isApprovedForAll: nonexistent owner');
        return _ownerOperator[owner][operator];
    }

    function approve(address operator, uint256 tokenId) external {
        address owner = msg.sender;
        require(owner == ownerOf(tokenId), 'ERC721.approve: caller not owner');
        _tokenIdOperator[tokenId] = operator;
        emit Approval(owner, operator, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        address owner = msg.sender;
        require(_exists(owner), 'ERC721.setApprovalForAll: nonexistent owner');
        _ownerOperator[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        _validateTransfer(msg.sender, from, to, tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        _validateTransfer(msg.sender, from, to, tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

    //================================================================================

    function _exists(address owner) internal view returns (bool) {
        return _ownerTokenId[owner] != 0;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenIdOwner[tokenId] != address(0);
    }

    function _validateTransfer(address operator, address from, address to, uint256 tokenId) internal view {
        require(
            from == ownerOf(tokenId),
            'ERC721._validateTransfer: not owned token'
        );
        require(
            to != address(0) && !_exists(to),
            'ERC721._validateTransfer: to address _exists or 0'
        );
        require(
            operator == from || _tokenIdOperator[tokenId] == operator || _ownerOperator[from][operator],
            'ERC721._validateTransfer: not owner nor approved'
        );
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        // clear previous ownership and approvals
        delete _ownerTokenId[from];
        delete _tokenIdOperator[tokenId];

        // set up new owner
        _ownerTokenId[to] = tokenId;
        _tokenIdOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            data
        ), 'ERC721: transfer to non ERC721Receiver implementer');
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC721.sol';
import '../utils/INameVersion.sol';

interface IDToken is IERC721, INameVersion {

    function pool() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalMinted() external view returns (uint256);

    function exists(address owner) external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function getTokenIdOf(address owner) external view returns (uint256);

    function mint(address owner) external returns (uint256);

    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC165.sol";

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function approve(address operator, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IMintableToken {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

pragma solidity ^0.8.0;
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;


import "./ERC20.sol";
import "./IMintableToken.sol";

contract MintableToken is ERC20, IMintableToken {

    mapping (address => bool) public override isMinter;
    address public gov;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) public ERC20(_name, _symbol) {
        gov = msg.sender;
        _mint(msg.sender, _initialSupply);
    }

    modifier onlyGov() {
        require(msg.sender == gov, "BaseToken: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
    

    modifier onlyMinter() {
        require(isMinter[msg.sender], "MintableToken: forbidden");
        _;
    }

    function setMinter(address _minter, bool _isActive) external override onlyGov {
        isMinter[_minter] = _isActive;
    }

    function mint(address _account, uint256 _amount) external override onlyMinter {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyMinter {
        address spender = _msgSender();
        // _spendAllowance(_account, spender, _amount);
        _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./INameVersion.sol";

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './NameVersion.sol';

contract Timelock is NameVersion {

    event NewAdmin(address indexed newAdmin);

    event NewPendingAdmin(address indexed newPendingAdmin);

    event NewDelay(uint256 indexed newDelay);

    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string  signature,
        bytes   data,
        uint256 eta
    );

    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string  signature,
        bytes   data,
        uint256 eta
    );

    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string  signature,
        bytes   data,
        uint256 eta
    );

    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 2 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public pendingAdmin;
    address public admin;
    uint256 public delay;

    // txHash => isActive
    mapping (bytes32 => bool) public queuedTransactions;

    constructor (address admin_, uint256 delay_) NameVersion('Timelock', '3.0.1') {
        require(delay_ >= MINIMUM_DELAY && delay_ <= MAXIMUM_DELAY, 'Timelock.constructor: invalid delay');
        admin = admin_;
        delay = delay_;
    }

    function setPendingAdmin(address newPendingAdmin) external {
        require(msg.sender == address(this), 'Timelock.setPendingAdmin: only Timelock');
        pendingAdmin = newPendingAdmin;
        emit NewPendingAdmin(newPendingAdmin);
    }

    function acceptPendingAdmin() external {
        require(msg.sender == pendingAdmin, 'Timelock.acceptPendingAdmin: only pendingAdmin');
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit NewAdmin(admin);
        emit NewPendingAdmin(pendingAdmin);
    }

    function setDelay(uint256 newDelay) external {
        require(msg.sender == address(this), 'Timelock.setDelay: only Timelock');
        require(newDelay >= MINIMUM_DELAY && newDelay <= MAXIMUM_DELAY, 'Timelock.setDelay: invalid newDelay');
        delay = newDelay;
        emit NewDelay(newDelay);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external returns (bytes32)
    {
        require(msg.sender == admin, 'Timelock.queueTransaction: only admin');
        require(eta >= block.timestamp + delay, 'Timelock.queueTransaction: invalid eta');

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external
    {
        require(msg.sender == admin, 'Timelock.cancelTransaction: only admin');

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external payable returns (bytes memory)
    {
        require(msg.sender == admin, 'Timelock.executeTransaction: only admin');

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], 'Timelock.executeTransaction: not queued');
        require(block.timestamp >= eta, 'Timelock.executeTransaction: time locked');
        require(block.timestamp <= eta + GRACE_PERIOD, 'Timelock.executeTransaction: staled');

        queuedTransactions[txHash] = false;

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, 'Timelock.executeTransaction: execution reverted');

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);
        return returnData;
    }

    receive() external payable {}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IComptroller {

    function isComptroller() external view returns (bool);

    function checkMembership(address account, address vToken) external view returns (bool);

    function getAssetsIn(address account) external view returns (address[] memory);

    function getAccountLiquidity(address account) external view returns (uint256 error, uint256 liquidity, uint256 shortfall);

    function getHypotheticalAccountLiquidity(address account, address vTokenModify, uint256 redeemTokens, uint256 borrowAmount)
    external view returns (uint256 error, uint256 liquidity, uint256 shortfall);

    function enterMarkets(address[] memory vTokens) external returns (uint256[] memory errors);

    function exitMarket(address vToken) external returns (uint256 error);

    function getXVSAddress() external view returns (address);

    function claimVenus(address account) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';

interface IVault is INameVersion {

    function pool() external view returns (address);

    // function comptroller() external view returns (address);

    // function vTokenETH() external view returns (address);

    // function tokenXVS() external view returns (address);

    function vaultLiquidityMultiplier() external view returns (uint256);

    function getVaultLiquidity() external view  returns (uint256);

    // function getHypotheticalVaultLiquidity(address vTokenModify, uint256 redeemVTokens) external view returns (uint256);

    // function isInMarket(address vToken) external view returns (bool);

    // function getMarketsIn() external view returns (address[] memory);

    // function getBalances(address vToken) external view returns (uint256 vTokenBalance, uint256 underlyingBalance);

    // function enterMarket(address vToken) external;

    // function exitMarket(address vToken) external;

    // function mint() external payable;

    // function mint(address vToken, uint256 amount) external;

    // function redeem(address vToken, uint256 amount) external;

    // function redeemAll(address vToken) external;

    // function redeemUnderlying(address vToken, uint256 amount) external;

    function transfer(address underlying, address to, uint256 amount) external;

    function transferAll(address underlying, address to) external returns (uint256);

    // function claimVenus(address account) external;

    // function supply(address token, uint256 amount) external;
    // function withdraw(address token, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IVToken {

    function isVToken() external view returns (bool);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function comptroller() external view returns (address);

    function underlying() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function mint() external payable;

    function mint(uint256 amount) external returns (uint256 error);

    function redeem(uint256 amount) external returns (uint256 error);

    function redeemUnderlying(uint256 amount) external returns (uint256 error);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Vault {

    address public immutable pool;

    constructor (address pool_) {
        pool = pool_;
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {

    }

    function _delegate() internal {
        address imp = IPool(pool).vaultImplementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}

interface IPool {
    function vaultImplementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IVToken.sol';
import './IComptroller.sol';
import '../token/IERC20.sol';
import '../library/SafeERC20.sol';
import '../utils/NameVersion.sol';
import '../test/keep/IKeep.sol';
import '../pool/IPool.sol';
contract VaultImplementation is NameVersion {

    using SafeERC20 for IERC20;

    uint256 constant ONE = 1e18;

    address public immutable pool;

    // address public immutable comptroller;

    // address public immutable vTokenETH;

    // address public immutable tokenXVS;

    uint256 public immutable vaultLiquidityMultiplier;

    // address public immutable lending;

    modifier _onlyPool_() {
        require(msg.sender == pool, 'VaultImplementation: only pool');
        _;
    }

    constructor (
        address pool_,
        // address comptroller_,
        // address vTokenETH_,
        uint256 vaultLiquidityMultiplier_
        // address lending_
    ) NameVersion('VaultImplementation', '3.0.1') {
        pool = pool_;
        // comptroller = comptroller_;
        // vTokenETH = vTokenETH_;
        vaultLiquidityMultiplier = vaultLiquidityMultiplier_;
        // tokenXVS = IComptroller(comptroller_).getXVSAddress();
        // lending = lending_;

        // require(
        //     IComptroller(comptroller_).isComptroller(),
        //     'VaultImplementation.constructor: not comptroller'
        // );
        // require(
        //     IVToken(vTokenETH_).isVToken(),
        //     'VaultImplementation.constructor: not vToken'
        // );
        // require(
        //     keccak256(abi.encodePacked(IVToken(vTokenETH_).symbol())) == keccak256(abi.encodePacked('vBNB')),
        //     'VaultImplementation.constructor: not vBNB'
        // );
    }

    function getVaultLiquidity() external view returns (uint256) {

        // (uint256 err, uint256 liquidity, uint256 shortfall) = IComptroller(comptroller).getAccountLiquidity(address(this));
        // require(err == 0 && shortfall == 0, 'VaultImplementation.getVaultLiquidity: error');
        // return liquidity * vaultLiquidityMultiplier / ONE;
        IPool poolContract = IPool(pool);
        uint256 length = poolContract.allWhitelistedTokensLength();
        uint256 liquidity = 0;

        for (uint256 i = 0; i < length; i++) {
            address token = poolContract.allWhitelistedTokens(i);
            bool isWhitelisted = poolContract.whitelistedTokens(token);
            if (!isWhitelisted) {
                continue;
            }

            uint256 price = poolContract.getTokenPrice(token);
            // address market = poolContract.getMarket(token);
            uint256 amount = IERC20(token).balanceOf(address(this));
            uint256 decimals = IERC20(token).decimals();
            liquidity += amount * price / 10 ** decimals;
        }
        return liquidity;

    }

    function getVaultLiquidityToken(address token) external view returns (uint256) {
        IPool poolContract = IPool(pool);
        bool isWhitelisted = poolContract.whitelistedTokens(token);
        require(isWhitelisted, 'VaultImplementation.getVaultLiquidityToken: not whitelisted');
        uint256 price = poolContract.getTokenPrice(token);
        uint256 amount = IERC20(token).balanceOf(address(this));
        uint256 decimals = IERC20(token).decimals();
        return amount * price / 10 ** decimals;
        // return amount;
    }

    function getVaultLiquidityTokenVolume(address token) external view returns (uint256) {
        IPool poolContract = IPool(pool);
        bool isWhitelisted = poolContract.whitelistedTokens(token);
        require(isWhitelisted, 'VaultImplementation.getVaultLiquidityToken: not whitelisted');
        // uint256 price = poolContract.getTokenPrice(token);
        uint256 amount = IERC20(token).balanceOf(address(this));
        // uint256 decimals = IERC20(token).decimals();
        // return amount * price / 10 ** decimals;
        return amount;
    }

    // function getVaultLiquidity() external view returns (uint256) {

    // }

    // function getHypotheticalVaultLiquidity(address vTokenModify, uint256 redeemVTokens)
    // external view returns (uint256)
    // {
    //     (uint256 err, uint256 liquidity, uint256 shortfall) =
    //     IComptroller(comptroller).getHypotheticalAccountLiquidity(address(this), vTokenModify, redeemVTokens, 0);
    //     require(err == 0 && shortfall == 0, 'VaultImplementation.getHypotheticalVaultLiquidity: error');
    //     return liquidity * vaultLiquidityMultiplier / ONE;
    // }

    // function isInMarket(address vToken) public view returns (bool) {
    //     return IComptroller(comptroller).checkMembership(address(this), vToken);
    // }

    // function getMarketsIn() external view returns (address[] memory) {
    //     return IComptroller(comptroller).getAssetsIn(address(this));
    // }

    // function getBalances(address vToken) external view returns (uint256 vTokenBalance, uint256 underlyingBalance) {
    //     vTokenBalance = IVToken(vToken).balanceOf(address(this));
    //     if (vTokenBalance != 0) {
    //         uint256 exchangeRate = IVToken(vToken).exchangeRateStored();
    //         underlyingBalance = vTokenBalance * exchangeRate / ONE;
    //     }
    // }

    // function enterMarket(address vToken) external _onlyPool_ {
    //     if (vToken != vTokenETH) {
    //         IERC20 underlying = IERC20(IVToken(vToken).underlying());
    //         uint256 allowance = underlying.allowance(address(this), vToken);
    //         if (allowance != type(uint256).max) {
    //             if (allowance != 0) {
    //                 underlying.safeApprove(vToken, 0);
    //             }
    //             underlying.safeApprove(vToken, type(uint256).max);
    //         }
    //     }
    //     address[] memory markets = new address[](1);
    //     markets[0] = vToken;
    //     uint256[] memory res = IComptroller(comptroller).enterMarkets(markets);
    //     require(res[0] == 0, 'VaultImplementation.enterMarket: error');
    // }

    // function exitMarket(address vToken) external _onlyPool_ {
    //     if (vToken != vTokenETH) {
    //         IERC20 underlying = IERC20(IVToken(vToken).underlying());
    //         uint256 allowance = underlying.allowance(address(this), vToken);
    //         if (allowance != 0) {
    //             underlying.safeApprove(vToken, 0);
    //         }
    //     }
    //     require(
    //         IComptroller(comptroller).exitMarket(vToken) == 0,
    //         'VaultImplementation.exitMarket: error'
    //     );
    // }

    // function mint() external payable _onlyPool_ {
    //     IVToken(vTokenETH).mint{value: msg.value}();
    // }

    // function mint(address vToken, uint256 amount) external _onlyPool_ {
    //     require(IVToken(vToken).mint(amount) == 0, 'VaultImplementation.mint: error');
    // }

    // function supply(address token, uint256 amount) external _onlyPool_ {
    //     IERC20(token).safeApprove(lending, amount);
    //     IKeep(lending).supply(token, amount, address(this));
    // }

    // function withdraw(address token, uint256 amount) external _onlyPool_ {
    //     IKeep(lending).withdraw(token, amount, address(this));
    // }

    // function redeem(address vToken, uint256 amount) public _onlyPool_ {
    //     require(IVToken(vToken).redeem(amount) == 0, 'VaultImplementation.redeem: error');
    // }

    // function redeemAll(address vToken) external _onlyPool_ {
    //     uint256 balance = IVToken(vToken).balanceOf(address(this));
    //     if (balance != 0) {
    //         redeem(vToken, balance);
    //     }
    // }

    // function redeemUnderlying(address vToken, uint256 amount) external _onlyPool_ {
    //     require(
    //         IVToken(vToken).redeemUnderlying(amount) == 0,
    //         'VaultImplementation.redeemUnderlying: error'
    //     );
    // }

    function transfer(address underlying, address to, uint256 amount) public _onlyPool_ {
        if (underlying == address(0)) {
            (bool success, ) = payable(to).call{value: amount}('');
            require(success, 'VaultImplementation.transfer: send ETH fail');
        } else {
            IERC20(underlying).safeTransfer(to, amount);
        }
    }

    function transferAll(address underlying, address to) external _onlyPool_ returns (uint256) {
        uint256 amount = underlying == address(0) ?
                         address(this).balance :
                         IERC20(underlying).balanceOf(address(this));
        transfer(underlying, to, amount);
        return amount;
    }

    // function claimVenus(address account) external _onlyPool_ {
    //     IComptroller(comptroller).claimVenus(address(this));
    //     uint256 balance = IERC20(tokenXVS).balanceOf(address(this));
    //     if (balance != 0) {
    //         IERC20(tokenXVS).safeTransfer(account, balance);
    //     }
    // }

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}