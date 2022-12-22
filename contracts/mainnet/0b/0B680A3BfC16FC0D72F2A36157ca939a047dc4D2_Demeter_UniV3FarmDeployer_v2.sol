/**
 *Submitted for verification at Arbiscan on 2022-12-22
*/

// File: @openzeppelin/contracts/proxy/Clones.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// File: @uniswap/v3-core/contracts/libraries/FixedPoint128.sol


pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// File: @uniswap/v3-periphery/contracts/libraries/PositionKey.sol


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

// File: contracts/uniswapV3/libraries/PoolAddress.sol


pragma solidity 0.8.10;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

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
    function computeAddress(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(key.token0, key.token1, key.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolEvents.sol


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

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolOwnerActions.sol


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

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol


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

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolDerivedState.sol


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

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol


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

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol


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

// File: @uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol


pragma solidity >=0.5.0;







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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/uniswapV3/interfaces/UniswapV3.sol


pragma solidity 0.8.10;


struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
}

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.

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

interface INFPM is IPoolInitializer, IERC721 {
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

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

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

    function factory() external view returns (address);
}

interface IUniswapV3Factory {
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
}

interface IUniswapV3TickSpacing {
    function tickSpacing() external view returns (int24);
}

// File: contracts/uniswapV3/libraries/PositionValue.sol


pragma solidity 0.8.10;






/// @title Returns information about the token value held in a Uniswap V3 NFT
library PositionValue {
    struct FeeParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 positionFeeGrowthInside0LastX128;
        uint256 positionFeeGrowthInside1LastX128;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }

    /// @notice Calculates the total fees owed to the token owner
    /// @param positionManager The Uniswap V3 NonfungiblePositionManager
    /// @param tokenId The tokenId of the token for which to get the total fees owed
    /// @return amount0 The amount of fees owed in token0
    /// @return amount1 The amount of fees owed in token1
    function fees(INFPM positionManager, uint256 tokenId)
        internal
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 positionFeeGrowthInside0LastX128,
            uint256 positionFeeGrowthInside1LastX128,
            uint256 tokensOwed0,
            uint256 tokensOwed1
        ) = positionManager.positions(tokenId);

        return
            _fees(
                positionManager,
                FeeParams({
                    token0: token0,
                    token1: token1,
                    fee: fee,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    liquidity: liquidity,
                    positionFeeGrowthInside0LastX128: positionFeeGrowthInside0LastX128,
                    positionFeeGrowthInside1LastX128: positionFeeGrowthInside1LastX128,
                    tokensOwed0: tokensOwed0,
                    tokensOwed1: tokensOwed1
                })
            );
    }

    function _fees(
        INFPM positionManager,
        FeeParams memory feeParams
    ) private view returns (uint256 amount0, uint256 amount1) {
        (
            uint256 poolFeeGrowthInside0LastX128,
            uint256 poolFeeGrowthInside1LastX128
        ) = _getFeeGrowthInside(
                IUniswapV3Pool(
                    PoolAddress.computeAddress(
                        positionManager.factory(),
                        PoolAddress.PoolKey({
                            token0: feeParams.token0,
                            token1: feeParams.token1,
                            fee: feeParams.fee
                        })
                    )
                ),
                feeParams.tickLower,
                feeParams.tickUpper
            );

        amount0 =
            (((poolFeeGrowthInside0LastX128 -
                feeParams.positionFeeGrowthInside0LastX128) *
                feeParams.liquidity) / FixedPoint128.Q128) +
            feeParams.tokensOwed0;

        amount1 =
            (((poolFeeGrowthInside1LastX128 -
                feeParams.positionFeeGrowthInside1LastX128) *
                feeParams.liquidity) / FixedPoint128.Q128) +
            feeParams.tokensOwed1;
    }

    function _getFeeGrowthInside(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper
    )
        private
        view
        returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
    {
        (, int24 tickCurrent, , , , , ) = pool.slot0();
        (
            ,
            ,
            uint256 lowerFeeGrowthOutside0X128,
            uint256 lowerFeeGrowthOutside1X128,
            ,
            ,
            ,

        ) = pool.ticks(tickLower);
        (
            ,
            ,
            uint256 upperFeeGrowthOutside0X128,
            uint256 upperFeeGrowthOutside1X128,
            ,
            ,
            ,

        ) = pool.ticks(tickUpper);

        if (tickCurrent < tickLower) {
            feeGrowthInside0X128 =
                lowerFeeGrowthOutside0X128 -
                upperFeeGrowthOutside0X128;
            feeGrowthInside1X128 =
                lowerFeeGrowthOutside1X128 -
                upperFeeGrowthOutside1X128;
        } else if (tickCurrent < tickUpper) {
            uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
            uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
            feeGrowthInside0X128 =
                feeGrowthGlobal0X128 -
                lowerFeeGrowthOutside0X128 -
                upperFeeGrowthOutside0X128;
            feeGrowthInside1X128 =
                feeGrowthGlobal1X128 -
                lowerFeeGrowthOutside1X128 -
                upperFeeGrowthOutside1X128;
        } else {
            feeGrowthInside0X128 =
                upperFeeGrowthOutside0X128 -
                lowerFeeGrowthOutside0X128;
            feeGrowthInside1X128 =
                upperFeeGrowthOutside1X128 -
                lowerFeeGrowthOutside1X128;
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/uniswapV3/Demeter_UniV3Farm_v2.sol


pragma solidity <=0.8.10;

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@&....(@@@@@@@@@@@@@..../@@@@@@@@@//
//@@@@@@........../@@@@@@@........../@@@@@@//
//@@@@@............(@@@@@............(@@@@@//
//@@@@@([email protected]@@@@(...........&@@@@@//
//@@@@@@@...........&@@@@@@[email protected]@@@@@@//
//@@@@@@@@@@@@@@%..../@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@......(&@@@@@@@@@@@@//
//@@@@@@#[email protected]@@@@@#[email protected]@@@@@@//
//@@@@@/...........%@@@@@............%@@@@@//
//@@@@@............#@@@@@............%@@@@@//
//@@@@@@..........#@@@@@@@/.........#@@@@@@//
//@@@@@@@@@&/.(@@@@@@@@@@@@@@&/.(&@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//








// Defines the Uniswap pool init data for constructor.
// tokenA - Address of tokenA
// tokenB - Address of tokenB
// feeTier - Fee tier for the Uniswap pool
// tickLowerAllowed - Lower bound of the tick range for farm
// tickUpperAllowed - Upper bound of the tick range for farm
struct UniswapPoolData {
    address tokenA;
    address tokenB;
    uint24 feeTier;
    int24 tickLowerAllowed;
    int24 tickUpperAllowed;
}

// Defines the reward data for constructor.
// token - Address of the token
// tknManager - Authority to update rewardToken related Params.
struct RewardTokenData {
    address token;
    address tknManager;
}

contract Demeter_UniV3Farm_v2 is
    Ownable,
    ReentrancyGuard,
    Initializable,
    IERC721Receiver
{
    using SafeERC20 for IERC20;

    // Defines the reward funds for the farm
    // totalLiquidity - amount of liquidity sharing the rewards in the fund
    // rewardsPerSec - the emission rate of the fund
    // accRewardPerShare - the accumulated reward per share
    struct RewardFund {
        uint256 totalLiquidity;
        uint256[] rewardsPerSec;
        uint256[] accRewardPerShare;
    }

    // Keeps track of a deposit's share in a reward fund.
    // fund id - id of the subscribed reward fund
    // rewardDebt - rewards claimed for a deposit corresponding to
    //              latest accRewardPerShare value of the budget
    // rewardClaimed - rewards claimed for a deposit from the reward fund
    struct Subscription {
        uint8 fundId;
        uint256[] rewardDebt;
        uint256[] rewardClaimed;
    }

    // Deposit information
    // locked - determines if the deposit is locked or not
    // liquidity - amount of liquidity in the deposit
    // tokenId - maps to uniswap NFT token id
    // startTime - time of deposit
    // expiryDate - expiry time (if deposit is locked)
    // totalRewardsClaimed - total rewards claimed for the deposit
    struct Deposit {
        uint256 liquidity;
        uint256 tokenId;
        uint256 startTime;
        uint256 expiryDate;
        uint256 cooldownPeriod;
        uint256[] totalRewardsClaimed;
    }

    // Reward token related information
    // tknManager Address that manages the rewardToken.
    // accRewardBal The rewards accrued but pending to be claimed.
    struct RewardData {
        address tknManager;
        uint8 id;
        uint256 accRewardBal;
    }

    // constants
    address public constant SPA = 0x5575552988A3A80504bBaeB1311674fCFd40aD4B;
    address public constant SPA_TOKEN_MANAGER =
        0x6d5240f086637fb408c7F727010A10cf57D51B62;
    address public constant NFPM = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant UNIV3_FACTORY =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
    uint8 public constant COMMON_FUND_ID = 0;
    uint8 public constant LOCKUP_FUND_ID = 1;
    uint256 public constant PREC = 1e18;
    uint256 public constant MIN_COOLDOWN_PERIOD = 1; // In days
    uint256 public constant MAX_COOLDOWN_PERIOD = 30; // In days
    uint256 public constant MAX_NUM_REWARDS = 4;

    // Global Params
    bool public isPaused;
    bool public isClosed;

    // UniswapV3 params
    int24 public tickLowerAllowed;
    int24 public tickUpperAllowed;
    address public uniswapPool;

    uint256 public cooldownPeriod;
    uint256 public lastFundUpdateTime;
    uint256 public farmStartTime;

    // Reward info
    RewardFund[] public rewardFunds;
    address[] public rewardTokens;
    mapping(address => RewardData) public rewardData;
    mapping(address => Deposit[]) public deposits;
    mapping(uint256 => Subscription[]) public subscriptions;

    event Deposited(
        address indexed account,
        bool locked,
        uint256 tokenId,
        uint256 liquidity
    );
    event CooldownInitiated(
        address indexed account,
        uint256 tokenId,
        uint256 expiryDate
    );
    event DepositWithdrawn(
        address indexed account,
        uint256 tokenId,
        uint256 startTime,
        uint256 liquidity,
        uint256[] totalRewardsClaimed
    );
    event RewardsClaimed(
        address indexed account,
        uint8 fundId,
        uint256 tokenId,
        uint256 liquidity,
        uint256 fundLiquidity,
        uint256[] rewardAmount
    );
    event PoolUnsubscribed(
        address indexed account,
        uint8 fundId,
        uint256 depositId,
        uint256 startTime,
        uint256[] totalRewardsClaimed
    );
    event FarmStartTimeUpdated(uint256 newStartTime);
    event CooldownPeriodUpdated(
        uint256 oldCooldownPeriod,
        uint256 newCooldownPeriod
    );
    event RewardRateUpdated(
        address rwdToken,
        uint256[] oldRewardRate,
        uint256[] newRewardRate
    );
    event RewardAdded(address rwdToken, uint256 amount);
    event FarmClosed();
    event RecoveredERC20(address token, uint256 amount);
    event PoolFeeCollected(
        address indexed recipient,
        uint256 amt0Recv,
        uint256 amt1Recv
    );
    event FundsRecovered(
        address indexed account,
        address rwdToken,
        uint256 amount
    );
    event TokenManagerUpdated(
        address rwdToken,
        address oldTokenManager,
        address newTokenManager
    );
    event RewardTokenAdded(address rwdToken, address rwdTokenManager);
    event FarmPaused(bool paused);

    // Disallow initialization of a implementation contract
    constructor() {
        _disableInitializers();
    }

    /// @notice constructor
    /// @param _farmStartTime - time of farm start
    /// @param _cooldownPeriod - cooldown period for locked deposits in days
    /// @dev _cooldownPeriod = 0 Disables lockup functionality for the farm.
    /// @param _uniswapPoolData - init data for UniswapV3 pool
    /// @param _rwdTokenData - init data for reward tokens
    function initialize(
        uint256 _farmStartTime,
        uint256 _cooldownPeriod,
        UniswapPoolData memory _uniswapPoolData,
        RewardTokenData[] memory _rwdTokenData
    ) external initializer {
        require(_farmStartTime >= block.timestamp, "Invalid farm startTime");
        _transferOwnership(msg.sender);
        // Initialize farm global params
        lastFundUpdateTime = _farmStartTime;
        farmStartTime = _farmStartTime;
        isPaused = false;
        isClosed = false;

        // initialize uniswap related data
        uniswapPool = IUniswapV3Factory(UNIV3_FACTORY).getPool(
            _uniswapPoolData.tokenB,
            _uniswapPoolData.tokenA,
            _uniswapPoolData.feeTier
        );
        require(uniswapPool != address(0), "Invalid uniswap pool config");
        _validateTickRange(
            _uniswapPoolData.tickLowerAllowed,
            _uniswapPoolData.tickUpperAllowed
        );
        tickLowerAllowed = _uniswapPoolData.tickLowerAllowed;
        tickUpperAllowed = _uniswapPoolData.tickUpperAllowed;

        // Check for lockup functionality
        // @dev If _cooldownPeriod is 0, then the lockup functionality is disabled for
        // the farm.
        uint8 numFunds = 1;
        if (_cooldownPeriod > 0) {
            _isValidCooldownPeriod(_cooldownPeriod);
            cooldownPeriod = _cooldownPeriod;
            numFunds = 2;
        }
        _setupFarm(numFunds, _rwdTokenData);
    }

    /// @notice Function is called when user transfers the NFT to the contract.
    /// @param _from The address of the owner.
    /// @param _tokenId nft Id generated by uniswap v3.
    /// @param _data The data should be the lockup flag (bool).
    function onERC721Received(
        address, // unused variable. not named
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        _farmNotPaused();
        require(msg.sender == NFPM, "onERC721Received: not a univ3 nft");

        require(_data.length > 0, "onERC721Received: no data");

        bool lockup = abi.decode(_data, (bool));
        if (cooldownPeriod == 0) {
            require(!lockup, "Lockup functionality is disabled");
        }

        // update the reward funds
        _updateFarmRewardData();

        // Validate the position and get the liquidity
        uint256 liquidity = _getLiquidity(_tokenId);

        // Prepare data to be stored.
        Deposit memory userDeposit = Deposit({
            cooldownPeriod: 0,
            tokenId: _tokenId,
            startTime: block.timestamp,
            expiryDate: 0,
            totalRewardsClaimed: new uint256[](rewardTokens.length),
            liquidity: liquidity
        });
        // Add common fund subscription to the user's deposit
        _subscribeRewardFund(COMMON_FUND_ID, _tokenId, liquidity);

        if (lockup) {
            // Add lockup fund subscription to the user's deposit
            userDeposit.cooldownPeriod = cooldownPeriod;
            _subscribeRewardFund(LOCKUP_FUND_ID, _tokenId, liquidity);
        }

        // @dev Add the deposit to the user's deposit list
        deposits[_from].push(userDeposit);

        emit Deposited(_from, lockup, _tokenId, liquidity);
        return this.onERC721Received.selector;
    }

    /// @notice Function to lock a staked deposit
    /// @param _depositId The id of the deposit to be locked
    /// @dev _depositId is corresponding to the user's deposit
    function initiateCooldown(uint256 _depositId) external nonReentrant {
        _farmNotPaused();
        address account = msg.sender;
        _isValidDeposit(account, _depositId);
        Deposit storage userDeposit = deposits[account][_depositId];

        // validate if the deposit is in locked state
        require(userDeposit.cooldownPeriod > 0, "Can not initiate cooldown");

        // update the deposit expiry time & lock status
        userDeposit.expiryDate =
            block.timestamp +
            (userDeposit.cooldownPeriod * 1 days);
        userDeposit.cooldownPeriod = 0;

        // claim the pending rewards for the user
        _claimRewards(account, _depositId);

        // Unsubscribe the deposit from the lockup reward fund
        _unsubscribeRewardFund(LOCKUP_FUND_ID, account, _depositId);

        emit CooldownInitiated(
            account,
            userDeposit.tokenId,
            userDeposit.expiryDate
        );
    }

    /// @notice Function to withdraw a deposit from the farm.
    /// @param _depositId The id of the deposit to be withdrawn
    function withdraw(uint256 _depositId) external nonReentrant {
        address account = msg.sender;
        _isValidDeposit(account, _depositId);
        Deposit memory userDeposit = deposits[account][_depositId];

        // Check for the withdrawal criteria
        // Note: If farm is paused, skip the cooldown check
        if (!isPaused) {
            require(
                userDeposit.cooldownPeriod == 0,
                "Please initiate cooldown"
            );
            if (userDeposit.expiryDate > 0) {
                // Cooldown is initiated for the user
                require(
                    userDeposit.expiryDate <= block.timestamp,
                    "Deposit is in cooldown"
                );
            }
        }

        // Compute the user's unclaimed rewards
        _claimRewards(account, _depositId);

        // Store the total rewards earned
        uint256[] memory totalRewards = deposits[account][_depositId]
            .totalRewardsClaimed;

        // unsubscribe the user from the common reward fund
        _unsubscribeRewardFund(COMMON_FUND_ID, account, _depositId);

        if (subscriptions[userDeposit.tokenId].length > 0) {
            // To handle a lockup withdraw without cooldown (during farmPause)
            _unsubscribeRewardFund(LOCKUP_FUND_ID, account, _depositId);
        }

        // Update the user's deposit list
        deposits[account][_depositId] = deposits[account][
            deposits[account].length - 1
        ];
        deposits[account].pop();

        // Transfer the nft back to the user.
        INFPM(NFPM).safeTransferFrom(
            address(this),
            account,
            userDeposit.tokenId
        );

        emit DepositWithdrawn(
            account,
            userDeposit.tokenId,
            userDeposit.startTime,
            userDeposit.liquidity,
            totalRewards
        );
    }

    /// @notice Claim rewards for the user.
    /// @param _account The user's address
    /// @param _depositId The id of the deposit
    /// @dev Anyone can call this function to claim rewards for the user
    function claimRewards(address _account, uint256 _depositId)
        external
        nonReentrant
    {
        _farmNotClosed();
        _isValidDeposit(_account, _depositId);
        _claimRewards(_account, _depositId);
    }

    /// @notice Claim rewards for the user.
    /// @param _depositId The id of the deposit
    function claimRewards(uint256 _depositId) external nonReentrant {
        _farmNotClosed();
        address account = msg.sender;
        _isValidDeposit(account, _depositId);
        _claimRewards(account, _depositId);
    }

    /// @notice Claim uniswap pool fee for a deposit.
    /// @dev Only the deposit owner can claim the fee.
    /// @param _depositId Id of the deposit
    function claimUniswapFee(uint256 _depositId) external nonReentrant {
        _farmNotClosed();
        address account = msg.sender;
        _isValidDeposit(account, _depositId);
        Deposit memory userDeposit = deposits[account][_depositId];
        INFPM pm = INFPM(NFPM);
        (uint256 amt0, uint256 amt1) = PositionValue.fees(
            pm,
            userDeposit.tokenId
        );
        require(amt0 > 0 || amt1 > 0, "No fee to claim");
        (uint256 amt0Recv, uint256 amt1Recv) = pm.collect(
            CollectParams({
                tokenId: userDeposit.tokenId,
                recipient: account,
                amount0Max: uint128(amt0),
                amount1Max: uint128(amt1)
            })
        );
        emit PoolFeeCollected(account, amt0Recv, amt1Recv);
    }

    /// @notice Add rewards to the farm.
    /// @param _rwdToken the reward token's address.
    /// @param _amount the amount of reward tokens to add.
    function addRewards(address _rwdToken, uint256 _amount)
        external
        nonReentrant
    {
        _farmNotClosed();
        require(
            rewardData[_rwdToken].tknManager != address(0),
            "Invalid reward token"
        );
        _updateFarmRewardData();
        IERC20(_rwdToken).safeTransferFrom(msg.sender, address(this), _amount);
        emit RewardAdded(_rwdToken, _amount);
    }

    // --------------------- Admin  Functions ---------------------
    /// @notice Update the cooldown period
    /// @param _newCooldownPeriod The new cooldown period (in days)
    function updateCooldownPeriod(uint256 _newCooldownPeriod)
        external
        onlyOwner
    {
        _farmNotClosed();
        require(cooldownPeriod != 0, "Farm does not support lockup");
        _isValidCooldownPeriod(_newCooldownPeriod);
        emit CooldownPeriodUpdated(cooldownPeriod, _newCooldownPeriod);
        cooldownPeriod = _newCooldownPeriod;
    }

    /// @notice Update the farm start time.
    /// @dev Can be updated only before the farm start
    ///      New start time should be in future.
    /// @param _newStartTime The new farm start time.
    function updateFarmStartTime(uint256 _newStartTime) external onlyOwner {
        require(block.timestamp < farmStartTime, "Farm already started");
        require(_newStartTime >= block.timestamp, "Time < now");
        farmStartTime = _newStartTime;
        lastFundUpdateTime = _newStartTime;

        emit FarmStartTimeUpdated(_newStartTime);
    }

    /// @notice Pause / UnPause the deposit
    function farmPauseSwitch(bool _isPaused) external onlyOwner {
        _farmNotClosed();
        require(isPaused != _isPaused, "Farm already in required state");
        _updateFarmRewardData();
        isPaused = _isPaused;
        emit FarmPaused(isPaused);
    }

    /// @notice Recover rewardToken from the farm in case of EMERGENCY
    /// @dev Shuts down the farm completely
    function closeFarm() external onlyOwner nonReentrant {
        _updateFarmRewardData();
        isPaused = true;
        isClosed = true;
        uint256 numRewards = rewardTokens.length;
        for (uint8 iRwd = 0; iRwd < numRewards; ) {
            _recoverRewardFunds(rewardTokens[iRwd], type(uint256).max);
            _setRewardRate(
                rewardTokens[iRwd],
                new uint256[](rewardFunds.length)
            );
            unchecked {
                ++iRwd;
            }
        }
        emit FarmClosed();
    }

    /// @notice Recover erc20 tokens other than the reward Tokens.
    /// @param _token Address of token to be recovered
    function recoverERC20(address _token) external onlyOwner nonReentrant {
        require(
            rewardData[_token].tknManager == address(0),
            "Can't withdraw rewardToken"
        );

        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "Can't withdraw 0 amount");

        IERC20(_token).safeTransfer(owner(), balance);
        emit RecoveredERC20(_token, balance);
    }

    // --------------------- Token Manager Functions ---------------------
    /// @notice Get the remaining balance out of the  farm
    /// @param _rwdToken The reward token's address
    /// @param _amount The amount of the reward token to be withdrawn
    /// @dev Function recovers minOf(_amount, rewardsLeft)
    function recoverRewardFunds(address _rwdToken, uint256 _amount)
        external
        nonReentrant
    {
        _isTokenManager(_rwdToken);
        _updateFarmRewardData();
        _recoverRewardFunds(_rwdToken, _amount);
    }

    /// @notice Function to update reward params for a fund.
    /// @param _rwdToken The reward token's address
    /// @param _newRewardRates The new reward rate for the fund (includes the precision)
    function setRewardRate(address _rwdToken, uint256[] memory _newRewardRates)
        external
    {
        _farmNotClosed();
        _isTokenManager(_rwdToken);
        _updateFarmRewardData();
        _setRewardRate(_rwdToken, _newRewardRates);
    }

    /// @notice Transfer the tokenManagerRole to other user.
    /// @dev Only the existing tokenManager for a reward can call this function.
    /// @param _rwdToken The reward token's address.
    /// @param _newTknManager Address of the new token manager.
    function updateTokenManager(address _rwdToken, address _newTknManager)
        external
    {
        _farmNotClosed();
        _isTokenManager(_rwdToken);
        _isNonZeroAddr(_newTknManager);
        rewardData[_rwdToken].tknManager = _newTknManager;
        emit TokenManagerUpdated(_rwdToken, msg.sender, _newTknManager);
    }

    /// @notice Function to compute the total accrued rewards for a deposit
    /// @param _account The user's address
    /// @param _depositId The id of the deposit
    /// @return rewards The total accrued rewards for the deposit (uint256[])
    function computeRewards(address _account, uint256 _depositId)
        external
        view
        returns (uint256[] memory rewards)
    {
        _isValidDeposit(_account, _depositId);
        Deposit memory userDeposit = deposits[_account][_depositId];
        Subscription[] memory depositSubs = subscriptions[userDeposit.tokenId];
        RewardFund[] memory funds = rewardFunds;
        uint256 numRewards = rewardTokens.length;
        rewards = new uint256[](numRewards);

        uint256 time = 0;
        // In case the reward is not updated
        if (block.timestamp > lastFundUpdateTime) {
            time = block.timestamp - lastFundUpdateTime;
        }

        // Update the two reward funds.
        for (uint8 iSub = 0; iSub < depositSubs.length; ) {
            uint8 fundId = depositSubs[iSub].fundId;
            for (uint8 iRwd = 0; iRwd < numRewards; ) {
                if (funds[fundId].totalLiquidity > 0 && !isPaused) {
                    uint256 accRewards = _getAccRewards(iRwd, fundId, time);
                    // update the accRewardPerShare for delta time.
                    funds[fundId].accRewardPerShare[iRwd] +=
                        (accRewards * PREC) /
                        funds[fundId].totalLiquidity;
                }
                rewards[iRwd] +=
                    ((userDeposit.liquidity *
                        funds[fundId].accRewardPerShare[iRwd]) / PREC) -
                    depositSubs[iSub].rewardDebt[iRwd];
                unchecked {
                    ++iRwd;
                }
            }
            unchecked {
                ++iSub;
            }
        }
        return rewards;
    }

    /// @notice Get the accrued uniswap fee for a deposit.
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function computeUniswapFee(uint256 _tokenId)
        external
        view
        returns (uint256 amount0, uint256 amount1)
    {
        // Validate token.
        _getLiquidity(_tokenId);
        return PositionValue.fees(INFPM(NFPM), _tokenId);
    }

    /// @notice get number of deposits for an account
    /// @param _account The user's address
    function getNumDeposits(address _account) external view returns (uint256) {
        return deposits[_account].length;
    }

    /// @notice get deposit info for an account
    /// @notice _account The user's address
    /// @notice _depositId The id of the deposit
    function getDeposit(address _account, uint256 _depositId)
        external
        view
        returns (Deposit memory)
    {
        return deposits[_account][_depositId];
    }

    /// @notice get number of deposits for an account
    /// @param _tokenId The token's id
    function getNumSubscriptions(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return subscriptions[_tokenId].length;
    }

    /// @notice get subscription stats for a deposit.
    /// @param _tokenId The token's id
    /// @param _subscriptionId The subscription's id
    function getSubscriptionInfo(uint256 _tokenId, uint256 _subscriptionId)
        external
        view
        returns (Subscription memory)
    {
        require(
            _subscriptionId < subscriptions[_tokenId].length,
            "Subscription does not exist"
        );
        return subscriptions[_tokenId][_subscriptionId];
    }

    /// @notice get reward rates for a rewardToken.
    /// @param _rwdToken The reward token's address
    /// @return The reward rates for the reward token (uint256[])
    function getRewardRates(address _rwdToken)
        external
        view
        returns (uint256[] memory)
    {
        uint256 numFunds = rewardFunds.length;
        uint256[] memory rates = new uint256[](numFunds);
        uint8 id = rewardData[_rwdToken].id;
        for (uint8 iFund = 0; iFund < numFunds; ) {
            rates[iFund] = rewardFunds[iFund].rewardsPerSec[id];
            unchecked {
                ++iFund;
            }
        }
        return rates;
    }

    /// @notice Get list of reward tokens.
    /// @return The list of reward tokens.
    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
    }

    /// @notice get farm reward fund info.
    /// @param _fundId The fund's id
    function getRewardFundInfo(uint8 _fundId)
        external
        view
        returns (RewardFund memory)
    {
        require(_fundId < rewardFunds.length, "Reward fund does not exist");
        return rewardFunds[_fundId];
    }

    /// @notice Get the remaining reward balance for the farm.
    /// @param _rwdToken The reward token's address
    function getRewardBalance(address _rwdToken) public view returns (uint256) {
        uint256 rwdId = rewardData[_rwdToken].id;
        require(rewardTokens[rwdId] == _rwdToken, "Invalid _rwdToken");

        uint256 numFunds = rewardFunds.length;
        uint256 rewardsAcc = rewardData[_rwdToken].accRewardBal;
        uint256 supply = IERC20(_rwdToken).balanceOf(address(this));
        if (block.timestamp > lastFundUpdateTime) {
            uint256 time = block.timestamp - lastFundUpdateTime;
            // Compute the accrued reward balance for time
            for (uint8 iFund = 0; iFund < numFunds; ) {
                if (rewardFunds[iFund].totalLiquidity > 0) {
                    rewardsAcc +=
                        rewardFunds[iFund].rewardsPerSec[rwdId] *
                        time;
                }
                unchecked {
                    ++iFund;
                }
            }
        }
        if (rewardsAcc >= supply) {
            return 0;
        }
        return (supply - rewardsAcc);
    }

    /// @notice Claim rewards for the user.
    /// @param _account The user's address
    /// @param _depositId The id of the deposit
    /// @dev NOTE: any function calling this private
    ///     function should be marked as non-reentrant
    function _claimRewards(address _account, uint256 _depositId) private {
        _updateFarmRewardData();

        Deposit storage userDeposit = deposits[_account][_depositId];
        Subscription[] storage depositSubs = subscriptions[userDeposit.tokenId];

        uint256 numRewards = rewardTokens.length;
        uint256 numSubs = depositSubs.length;
        uint256[] memory totalRewards = new uint256[](numRewards);
        // Compute the rewards for each subscription.
        for (uint8 iSub = 0; iSub < numSubs; ) {
            uint8 fundId = depositSubs[iSub].fundId;
            uint256[] memory rewards = new uint256[](numRewards);
            for (uint256 iRwd = 0; iRwd < numRewards; ) {
                // rewards = (liquidity * accRewardPerShare) / PREC - rewardDebt
                uint256 accRewards = (userDeposit.liquidity *
                    rewardFunds[fundId].accRewardPerShare[iRwd]) / PREC;
                rewards[iRwd] = accRewards - depositSubs[iSub].rewardDebt[iRwd];
                depositSubs[iSub].rewardClaimed[iRwd] += rewards[iRwd];
                totalRewards[iRwd] += rewards[iRwd];

                // Update userRewardDebt for the subscriptions
                // rewardDebt = liquidity * accRewardPerShare
                depositSubs[iSub].rewardDebt[iRwd] = accRewards;
                unchecked {
                    ++iRwd;
                }
            }

            emit RewardsClaimed(
                _account,
                fundId,
                userDeposit.tokenId,
                userDeposit.liquidity,
                rewardFunds[fundId].totalLiquidity,
                rewards
            );
            unchecked {
                ++iSub;
            }
        }

        // Transfer the claimed rewards to the User if any.
        for (uint8 iRwd = 0; iRwd < numRewards; ) {
            if (totalRewards[iRwd] > 0) {
                rewardData[rewardTokens[iRwd]].accRewardBal -= totalRewards[
                    iRwd
                ];
                // Update the total rewards earned for the deposit
                userDeposit.totalRewardsClaimed[iRwd] += totalRewards[iRwd];
                IERC20(rewardTokens[iRwd]).safeTransfer(
                    _account,
                    totalRewards[iRwd]
                );
            }
            unchecked {
                ++iRwd;
            }
        }
    }

    /// @notice Get the remaining balance out of the  farm
    /// @param _rwdToken The reward token's address
    /// @param _amount The amount of the reward token to be withdrawn
    /// @dev Function recovers minOf(_amount, rewardsLeft)
    /// @dev In case of partial withdraw of funds, the reward rate has to be set manually again.
    function _recoverRewardFunds(address _rwdToken, uint256 _amount) private {
        address emergencyRet = rewardData[_rwdToken].tknManager;
        uint256 rewardsLeft = getRewardBalance(_rwdToken);
        uint256 amountToRecover = _amount;
        if (_amount >= rewardsLeft) {
            amountToRecover = rewardsLeft;
        }
        if (amountToRecover > 0) {
            IERC20(_rwdToken).safeTransfer(emergencyRet, amountToRecover);
            emit FundsRecovered(emergencyRet, _rwdToken, amountToRecover);
        }
    }

    /// @notice Function to update reward params for a fund.
    /// @param _rwdToken The reward token's address
    /// @param _newRewardRates The new reward rate for the fund (includes the precision)
    function _setRewardRate(address _rwdToken, uint256[] memory _newRewardRates)
        private
    {
        uint8 id = rewardData[_rwdToken].id;
        uint256 numFunds = rewardFunds.length;
        require(
            _newRewardRates.length == numFunds,
            "Invalid reward rates length"
        );
        uint256[] memory oldRewardRates = new uint256[](numFunds);
        // Update the reward rate
        for (uint8 iFund = 0; iFund < numFunds; ) {
            oldRewardRates[iFund] = rewardFunds[iFund].rewardsPerSec[id];
            rewardFunds[iFund].rewardsPerSec[id] = _newRewardRates[iFund];
            unchecked {
                ++iFund;
            }
        }
        emit RewardRateUpdated(_rwdToken, oldRewardRates, _newRewardRates);
    }

    /// @notice Add subscription to the reward fund for a deposit
    /// @param _tokenId The tokenId of the deposit
    /// @param _fundId The reward fund id
    /// @param _liquidity The liquidity of the deposit
    function _subscribeRewardFund(
        uint8 _fundId,
        uint256 _tokenId,
        uint256 _liquidity
    ) private {
        require(_fundId < rewardFunds.length, "Invalid fund id");
        // Subscribe to the reward fund
        uint256 numRewards = rewardTokens.length;
        subscriptions[_tokenId].push(
            Subscription({
                fundId: _fundId,
                rewardDebt: new uint256[](numRewards),
                rewardClaimed: new uint256[](numRewards)
            })
        );
        uint256 subId = subscriptions[_tokenId].length - 1;

        // initialize user's reward debt
        for (uint8 iRwd = 0; iRwd < numRewards; ) {
            subscriptions[_tokenId][subId].rewardDebt[iRwd] =
                (_liquidity * rewardFunds[_fundId].accRewardPerShare[iRwd]) /
                PREC;
            unchecked {
                ++iRwd;
            }
        }
        // Update the totalLiquidity for the fund
        rewardFunds[_fundId].totalLiquidity += _liquidity;
    }

    /// @notice Unsubscribe a reward fund from a deposit
    /// @param _fundId The reward fund id
    /// @param _account The user's address
    /// @param _depositId The deposit id corresponding to the user
    /// @dev The rewards claimed from the reward fund is persisted in the event
    function _unsubscribeRewardFund(
        uint8 _fundId,
        address _account,
        uint256 _depositId
    ) private {
        require(_fundId < rewardFunds.length, "Invalid fund id");
        Deposit memory userDeposit = deposits[_account][_depositId];
        uint256 numRewards = rewardTokens.length;

        // Unsubscribe from the reward fund
        Subscription[] storage depositSubs = subscriptions[userDeposit.tokenId];
        uint256 numSubs = depositSubs.length;
        for (uint256 iSub = 0; iSub < numSubs; ) {
            if (depositSubs[iSub].fundId == _fundId) {
                // Persist the reward information
                uint256[] memory rewardClaimed = new uint256[](numRewards);

                for (uint8 iRwd = 0; iRwd < numRewards; ) {
                    rewardClaimed[iRwd] = depositSubs[iSub].rewardClaimed[iRwd];
                    unchecked {
                        ++iRwd;
                    }
                }

                // Delete the subscription from the list
                depositSubs[iSub] = depositSubs[numSubs - 1];
                depositSubs.pop();

                // Remove the liquidity from the reward fund
                rewardFunds[_fundId].totalLiquidity -= userDeposit.liquidity;

                emit PoolUnsubscribed(
                    _account,
                    _fundId,
                    userDeposit.tokenId,
                    userDeposit.startTime,
                    rewardClaimed
                );

                break;
            }
            unchecked {
                ++iSub;
            }
        }
    }

    /// @notice Function to update the FarmRewardData for all funds
    function _updateFarmRewardData() private {
        if (block.timestamp > lastFundUpdateTime) {
            // if farm is paused don't accrue any rewards.
            // only update the lastFundUpdateTime.
            if (!isPaused) {
                uint256 time = block.timestamp - lastFundUpdateTime;
                uint256 numRewards = rewardTokens.length;
                // Update the reward funds.
                for (uint8 iFund = 0; iFund < rewardFunds.length; ) {
                    RewardFund memory fund = rewardFunds[iFund];
                    if (fund.totalLiquidity > 0) {
                        for (uint8 iRwd = 0; iRwd < numRewards; ) {
                            // Get the accrued rewards for the time.
                            uint256 accRewards = _getAccRewards(
                                iRwd,
                                iFund,
                                time
                            );
                            rewardData[rewardTokens[iRwd]]
                                .accRewardBal += accRewards;
                            fund.accRewardPerShare[iRwd] +=
                                (accRewards * PREC) /
                                fund.totalLiquidity;

                            unchecked {
                                ++iRwd;
                            }
                        }
                    }
                    rewardFunds[iFund] = fund;
                    unchecked {
                        ++iFund;
                    }
                }
            }
            lastFundUpdateTime = block.timestamp;
        }
    }

    /// @notice Function to setup the reward funds during construction.
    /// @param _numFunds - Number of reward funds to setup.
    /// @param _rwdTokenData - Reward data for each reward token.
    function _setupFarm(uint8 _numFunds, RewardTokenData[] memory _rwdTokenData)
        private
    {
        // Setup reward related information.
        uint256 numRewards = _rwdTokenData.length;
        require(numRewards <= MAX_NUM_REWARDS - 1, "Invalid reward data");

        // Initialize fund storage
        for (uint8 i = 0; i < _numFunds; ) {
            RewardFund memory _rewardFund = RewardFund({
                totalLiquidity: 0,
                rewardsPerSec: new uint256[](numRewards + 1),
                accRewardPerShare: new uint256[](numRewards + 1)
            });
            rewardFunds.push(_rewardFund);
            unchecked {
                ++i;
            }
        }

        // Add SPA as default reward token in the farm
        _addRewardData(SPA, SPA_TOKEN_MANAGER);

        // Initialize reward Data
        for (uint8 iRwd = 0; iRwd < numRewards; ) {
            _addRewardData(
                _rwdTokenData[iRwd].token,
                _rwdTokenData[iRwd].tknManager
            );
            unchecked {
                ++iRwd;
            }
        }
    }

    /// @notice Adds new reward token to the farm
    /// @param _token Address of the reward token to be added.
    /// @param _tknManager Address of the reward token Manager.
    function _addRewardData(address _token, address _tknManager) private {
        // Validate if addresses are correct
        _isNonZeroAddr(_token);
        _isNonZeroAddr(_tknManager);

        require(
            rewardData[_token].tknManager == address(0),
            "Reward token already added"
        );

        rewardData[_token] = RewardData({
            id: uint8(rewardTokens.length),
            tknManager: _tknManager,
            accRewardBal: 0
        });

        // Add reward token in the list
        rewardTokens.push(_token);

        emit RewardTokenAdded(_token, _tknManager);
    }

    /// @notice Computes the accrued reward for a given fund id and time interval.
    /// @param _rwdId Id of the reward token.
    /// @param _fundId Id of the reward fund.
    /// @param _time Time interval for the reward computation.
    function _getAccRewards(
        uint8 _rwdId,
        uint8 _fundId,
        uint256 _time
    ) private view returns (uint256) {
        RewardFund memory fund = rewardFunds[_fundId];
        if (fund.rewardsPerSec[_rwdId] == 0) {
            return 0;
        }
        address rwdToken = rewardTokens[_rwdId];
        uint256 rwdSupply = IERC20(rwdToken).balanceOf(address(this));
        uint256 rwdAccrued = rewardData[rwdToken].accRewardBal;

        uint256 rwdBal = 0;
        // Calculate the available reward funds in the farm.
        if (rwdSupply > rwdAccrued) {
            rwdBal = rwdSupply - rwdAccrued;
        }
        // Calculate the rewards accrued in time.
        uint256 accRewards = fund.rewardsPerSec[_rwdId] * _time;
        // Cap the reward with the available balance.
        if (accRewards > rwdBal) {
            accRewards = rwdBal;
        }
        return accRewards;
    }

    /// @notice Validate the position for the pool and get Liquidity
    /// @param _tokenId The tokenId of the position
    /// @dev the position must adhere to the price ranges
    /// @dev Only allow specific pool token to be staked.
    function _getLiquidity(uint256 _tokenId) private view returns (uint256) {
        /// @dev Get the info of the required token
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = INFPM(NFPM).positions(_tokenId);

        /// @dev Check if the token belongs to correct pool
        require(
            uniswapPool ==
                IUniswapV3Factory(UNIV3_FACTORY).getPool(token0, token1, fee),
            "Incorrect pool token"
        );

        /// @dev Check if the token adheres to the tick range
        require(
            tickLower == tickLowerAllowed && tickUpper == tickUpperAllowed,
            "Incorrect tick range"
        );

        return uint256(liquidity);
    }

    function _validateTickRange(int24 _tickLower, int24 _tickUpper)
        private
        view
    {
        int24 spacing = IUniswapV3TickSpacing(uniswapPool).tickSpacing();
        require(
            _tickLower < _tickUpper &&
                _tickLower >= -887272 &&
                _tickLower % spacing == 0 &&
                _tickUpper <= 887272 &&
                _tickUpper % spacing == 0,
            "Invalid tick range"
        );
    }

    /// @notice Validate the deposit for account
    function _isValidDeposit(address _account, uint256 _depositId)
        private
        view
    {
        require(
            _depositId < deposits[_account].length,
            "Deposit does not exist"
        );
    }

    function _isValidCooldownPeriod(uint256 _cooldownPeriod) private view {
        require(
            _cooldownPeriod >= MIN_COOLDOWN_PERIOD &&
                _cooldownPeriod <= MAX_COOLDOWN_PERIOD,
            "Invalid cooldown period"
        );
    }

    /// @notice Validate if farm is not closed
    function _farmNotClosed() private view {
        require(!isClosed, "Farm closed");
    }

    /// @notice Validate if farm is not paused
    function _farmNotPaused() private view {
        require(!isPaused, "Farm paused");
    }

    /// @notice Validate the caller is the token Manager.
    function _isTokenManager(address _rwdToken) private view {
        require(
            msg.sender == rewardData[_rwdToken].tknManager,
            "Not the token manager"
        );
    }

    /// @notice Validate address
    function _isNonZeroAddr(address _addr) private pure {
        require(_addr != address(0), "Invalid address");
    }
}

// File: contracts/BaseFarmDeployer.sol

pragma solidity 0.8.10;



abstract contract BaseFarmDeployer is Ownable {
    address public constant SPA = 0x5575552988A3A80504bBaeB1311674fCFd40aD4B;
    address public constant USDs = 0xD74f5255D557944cf7Dd0E45FF521520002D5748;
    address public factory;
    // Stores the address of farmImplementation.
    address public farmImplementation;

    event FarmCreated(address farm, address creator, address indexed admin);
    event FeeCollected(
        address indexed creator,
        address token,
        uint256 amount,
        bool indexed claimable
    );

    /// @notice A function to calculate fees based on the tokens
    /// @param tokenA One token of the pool
    /// @param tokenB Other token of the pool
    /// @dev return feeReceiver, feeToken, feeAmount, bool claimable
    function calculateFees(address tokenA, address tokenB)
        external
        view
        virtual
        returns (
            address feeReceiver,
            address feeToken,
            uint256 feeAmount,
            bool claimable
        );

    /// @notice A function to collect fees from the creator of the farm
    /// @param tokenA One token of the pool
    /// @param tokenB Other token of the pool
    /// @dev Transfer fees from msg.sender to feeReceiver from FarmFactory in this function
    function _collectFee(address tokenA, address tokenB) internal virtual;

    /// @notice Validate address
    function _isNonZeroAddr(address _addr) internal pure {
        require(_addr != address(0), "Invalid address");
    }
}

// File: contracts/interfaces/IFarmFactory.sol

pragma solidity 0.8.10;

interface IFarmFactory {
    function registerFarm(address farm, address creator) external;

    function getFeeParams()
        external
        view
        returns (
            address feeFeceiver,
            address feeToken,
            uint256 feeAmount
        );
}

// File: contracts/uniswapV3/Demeter_UniV3FarmDeployer_v2.sol

pragma solidity 0.8.10;






contract Demeter_UniV3FarmDeployer_v2 is BaseFarmDeployer, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // farmAdmin - Address to which ownership of farm is transferred to post deployment
    // farmStartTime - Time after which the rewards start accruing for the deposits in the farm.
    // cooldownPeriod -  cooldown period for locked deposits (in days)
    //                   make cooldownPeriod = 0 for disabling lockup functionality of the farm.
    // uniswapPoolData - Init data for UniswapV3 pool.
    //                  (tokenA, tokenB, feeTier, tickLower, tickUpper)
    // rewardTokenData - [(rewardTokenAddress, tknManagerAddress), ... ]
    struct FarmData {
        address farmAdmin;
        uint256 farmStartTime;
        uint256 cooldownPeriod;
        UniswapPoolData uniswapPoolData;
        RewardTokenData[] rewardData;
    }

    string public constant DEPLOYER_NAME = "Demeter_UniV3FarmDeployer_v2";
    uint256 public discountedFee;
    // List of deployers for which fee won't be charged.
    mapping(address => bool) public isPrivilegedDeployer;

    event PrivilegeUpdated(address deployer, bool privilege);
    event DiscountedFeeUpdated(
        uint256 oldDiscountedFee,
        uint256 newDiscountedFee
    );

    constructor(address _factory) {
        _isNonZeroAddr(_factory);
        factory = _factory;
        discountedFee = 100e18; // 100 USDs
        farmImplementation = address(new Demeter_UniV3Farm_v2());
    }

    /// @notice Deploys a new UniswapV3 farm.
    /// @param _data data for deployment.
    function createFarm(FarmData memory _data)
        external
        nonReentrant
        returns (address)
    {
        _isNonZeroAddr(_data.farmAdmin);
        Demeter_UniV3Farm_v2 farmInstance = Demeter_UniV3Farm_v2(
            Clones.clone(farmImplementation)
        );
        farmInstance.initialize(
            _data.farmStartTime,
            _data.cooldownPeriod,
            _data.uniswapPoolData,
            _data.rewardData
        );
        farmInstance.transferOwnership(_data.farmAdmin);
        address farm = address(farmInstance);
        // Calculate and collect fee if required
        _collectFee(_data.uniswapPoolData.tokenA, _data.uniswapPoolData.tokenB);
        IFarmFactory(factory).registerFarm(farm, msg.sender);
        emit FarmCreated(farm, msg.sender, _data.farmAdmin);
        return farm;
    }

    /// @notice A function to add/ remove privileged deployer
    /// @param _deployer Deployer(address) to add to privileged deployers list
    /// @param _privilege Privilege(bool) whether true or false
    /// @dev to be only called by owner
    function updatePrivilege(address _deployer, bool _privilege)
        external
        onlyOwner
    {
        require(
            isPrivilegedDeployer[_deployer] != _privilege,
            "Privilege is same as desired"
        );
        isPrivilegedDeployer[_deployer] = _privilege;
        emit PrivilegeUpdated(_deployer, _privilege);
    }

    /// @notice An external function to update discountOnSpaUSDsFarms
    /// @param _discountedFee New desired discount on Spa/ USDs farms
    /// @dev _discountedFee cannot be more than 100
    function updateDiscountedFee(uint256 _discountedFee) external onlyOwner {
        emit DiscountedFeeUpdated(discountedFee, _discountedFee);
        discountedFee = _discountedFee;
    }

    /// @notice A public view function to calculate fees
    /// @param _tokenA address of token A
    /// @param _tokenB address of token B
    /// @notice Order does not matter
    /// @return Fees to be paid in feeToken set in FarmFactory (mostly USDs)
    function calculateFees(address _tokenA, address _tokenB)
        external
        view
        override
        returns (
            address,
            address,
            uint256,
            bool
        )
    {
        _isNonZeroAddr(_tokenA);
        _isNonZeroAddr(_tokenB);
        require(_tokenA != _tokenB, "Invalid token pair");
        return _calculateFees(_tokenA, _tokenB);
    }

    /// @notice Collect fee and transfer it to feeReceiver.
    /// @dev Function fetches all the fee params from farmFactory.
    function _collectFee(address _tokenA, address _tokenB) internal override {
        (
            address feeReceiver,
            address feeToken,
            uint256 feeAmount,
            bool claimable
        ) = _calculateFees(_tokenA, _tokenB);
        if (feeAmount > 0) {
            IERC20(feeToken).safeTransferFrom(
                msg.sender,
                feeReceiver,
                feeAmount
            );
            emit FeeCollected(msg.sender, feeToken, feeAmount, claimable);
        }
    }

    /// @notice An internal function to calculate fees
    /// @notice and return feeReceiver, feeToken, feeAmount and claimable
    function _calculateFees(address _tokenA, address _tokenB)
        internal
        view
        returns (
            address,
            address,
            uint256,
            bool
        )
    {
        (
            address feeReceiver,
            address feeToken,
            uint256 feeAmount
        ) = IFarmFactory(factory).getFeeParams();
        if (isPrivilegedDeployer[msg.sender]) {
            // No fees for privileged deployers
            feeAmount = 0;
            return (feeReceiver, feeToken, feeAmount, false);
        }
        if (!_validateToken(_tokenA) && !_validateToken(_tokenB)) {
            // No discount because neither of the token is SPA or USDs
            return (feeReceiver, feeToken, feeAmount, false);
        } else {
            // DiscountedFee if either of the token is SPA or USDs
            // This fees is claimable
            return (feeReceiver, feeToken, discountedFee, true);
        }
    }

    /// @notice Validate if a token is either SPA | USDs.
    /// @param _token Address of the desired token.
    function _validateToken(address _token) private pure returns (bool) {
        return _token == SPA || _token == USDs;
    }
}