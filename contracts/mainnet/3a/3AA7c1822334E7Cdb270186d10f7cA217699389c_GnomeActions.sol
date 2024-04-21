// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
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

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

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
pragma solidity >=0.8.0;

import {IUniswapV3FlashCallback} from "./interfaces/uniswap/IUniswapV3FlashCallback.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {PeripheryImmutableState} from "./Utils/PeripheryImmutableState.sol";
import {PoolAddress} from "./Utils/PoolAddress.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {TickMath} from "./Utils/TickMath.sol";
import {FullMath, LiquidityAmounts} from "./Utils/LiquidityAmounts.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Flashloan contract implementation
/// @notice contract using the Uniswap V3 flash function
interface IGNOME {
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function getID(address gnome) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function increaseHP(uint256 tokenId, uint256 _HP) external;
    function increaseXP(uint256 tokenId, uint256 _XP) external;
    function increaseGnomeActivityAmount(string memory activity, uint256 tokenId, uint256 _amount) external;
    function increaseGnomeBoopAmount(uint256 tokenId, uint256 _boopAmount) external;
    function setBoopTimeStamp(uint256 tokenId, uint256 _lastAtackTimeStamp) external;
    function decreaseHP(uint256 tokenId, uint256 _HP) external;
    function canGetBooped(uint256 tokenId) external returns (bool);
    function useGameRewards(address fren, address to, uint256 itemPrice) external;
    function getTokenUserName(uint256 tokenId) external view returns (string memory);
    function getXP(uint256 tokenId) external view returns (uint256);
    function getHP(uint256 tokenId) external view returns (uint256);
    function currentHP(uint256 tokenId) external view returns (uint256);
    function setMeditateTimeStamp(uint256 tokenId, uint256 _meditateTimeStamp) external;
    function isMeditating(uint256 tokenId) external view returns (bool);
    function decreaseXP(uint256 tokenId, uint256 _XP) external;
    function increaseETHSpentAmount(uint256 tokenId, uint256 _ethAmount) external;
    function increaseGnomeSpentAmount(uint256 tokenId, uint256 _gnomeAmount) external;
    function getIsSleeping(uint256 tokenId) external view returns (bool);
    function wakeUpGnome(uint256 tokenId) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
}

interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract GnomeActions is IUniswapV3FlashCallback, Ownable {
    IUniswapV3Pool public pool;
    IGNOME public gnome;
    struct FlashCallbackData {
        address token;
        uint256 amount;
        address payer;
    }
    struct Call {
        address to;
        bytes data;
    }
    uint24 public flashPoolFee = 1000; //  flash from the 0.05% fee of pool
    address private GNOME;
    ISwapRouter public constant swapRouter = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    address WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    mapping(address => uint256) public boopAmountGnome;
    mapping(address => uint256) public boopAmountETH;
    mapping(address => uint256) public activityAmountGnome;
    mapping(address => uint256) public activityAmountETH;
    mapping(address => uint256) public lastBoop;
    uint24 multiplier = 1;
    uint256 priceMultiplier = 100;
    uint256 margin = 100;
    uint256 pricePerBoopETH = 0.01 ether;
    uint256 pricePerBoopGNOME = 420 ether;
    uint256 pricePerFlashBoop = 42000 ether;
    uint256 boopOdds = 40;
    uint256 boopWin = 10;
    uint256 boopLoose = 1;
    uint256 boopHP = 3;
    uint256 meditationTime = 1 hours;
    uint256 boopCoolDown = 30 minutes;
    uint256 public mul = 1;
    uint256 public div = 1;
    uint32 _twapInterval = 100;
    uint256 loopMultiplier = 10;

    mapping(string => uint256) public activityPriceETH;
    mapping(string => uint256) public activityPriceGnome;
    mapping(string => uint256) public activityHP;
    event Boop(address indexed from, string booperName, string boopedName, bool isETH, bool boopResult);
    event MultiBoop(
        address indexed from,
        string booperName,
        string boopedName,
        bool isETH,
        uint256 totalAmount,
        uint256 successfullBoopAmount,
        uint256 volume
    );
    event Activity(address indexed from, string gnomeName, string activity, uint256 newHP);
    event MultiActivity(
        address indexed from,
        string activity,
        string gnomeName,
        bool isETH,
        uint256 totalAmount,
        uint256 newHP,
        uint256 volume
    );

    constructor(address _gnome, address _gnomePlayer) Ownable(msg.sender) {
        //pool = IUniswapV3Pool(0x4762A162bB535b736b83d49a87B3e1AE3267c80c);
        gnome = IGNOME(_gnomePlayer);
        GNOME = _gnome;
        activityPriceGnome["mushroom"] = 420 ether;
        activityPriceGnome["rice"] = 420 ether;
        activityPriceGnome["pea"] = 420 ether;
        activityPriceGnome["banana"] = 69 ether;
        activityPriceGnome["dance"] = 420 ether;
        activityPriceGnome["meditate"] = 420 ether;
        activityPriceGnome["wakeup"] = 4200 ether;
        activityPriceETH["mushroom"] = 0.00069 ether;
        activityPriceETH["rice"] = 0.00069 ether;
        activityPriceETH["pea"] = 0.00069 ether;
        activityPriceETH["banana"] = 0.00042 ether;
        activityPriceETH["dance"] = 0.00069 ether;
        activityPriceETH["meditate"] = 0.00420 ether;
        activityPriceETH["wakeup"] = 0.01 ether;
        activityHP["mushroom"] = 10;
        activityHP["rice"] = 20;
        activityHP["pea"] = 30;
        activityHP["banana"] = 1;
        activityHP["dance"] = 15;
        activityHP["meditate"] = 20;
        activityHP["wakeup"] = 0;
        IGNOME(_gnome).approve(address(swapRouter), type(uint256).max);
    }

    function setPool(address _pool) public onlyOwner {
        pool = IUniswapV3Pool(_pool);
    }

    function gnomeAction(string memory activity) external {
        uint256 tokenId = gnome.getID(msg.sender);
        if (keccak256(abi.encodePacked(activity)) != keccak256(abi.encodePacked("wakeup")))
            require(!gnome.getIsSleeping(tokenId), "You need to wake up your Gnome First!");
        require(
            !gnome.isMeditating(tokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );
        require(tokenId > 0, "User Not SignedUp");
        require(activityPriceGnome[activity] > 0, "Gnomes can't eat that");

        address feedToken = GNOME;
        uint256 amount = activityPriceGnome[activity];

        address otherToken = feedToken == WETH9 ? GNOME : WETH9;
        (address token0, address token1) = feedToken < otherToken ? (feedToken, otherToken) : (otherToken, feedToken);
        uint256 amount0 = feedToken == token0 ? amount : 0;
        uint256 amount1 = feedToken == token1 ? amount : 0;

        FlashCallbackData memory callbackData = FlashCallbackData({token: feedToken, amount: amount, payer: tx.origin});
        IUniswapV3Pool(pool).flash(address(this), amount0, amount1, abi.encode(callbackData, pool));

        gnome.increaseHP(tokenId, activityHP[activity]);
        gnome.increaseGnomeActivityAmount(activity, tokenId, 1);

        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("meditate")))
            gnome.setMeditateTimeStamp(tokenId, block.timestamp + meditationTime);

        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("wakeup"))) gnome.wakeUpGnome(tokenId);

        emit Activity(msg.sender, gnome.getTokenUserName(tokenId), activity, gnome.currentHP(tokenId));
    }

    function setBoopOdds(uint256 _odds, uint256 _boopWin, uint256 _boopLoose) public onlyOwner {
        boopOdds = _odds;
        boopWin = _boopWin;
        boopLoose = _boopLoose;
    }

    function setBoopPrice(uint256 _boopOdds, uint256 _pricePerBoopETH, uint256 _pricePerBoopGNOME) public onlyOwner {
        boopOdds = _boopOdds;
        pricePerBoopETH = _pricePerBoopETH;
        pricePerBoopGNOME = _pricePerBoopGNOME;
    }

    function setBoopHP(uint256 _boopHP) public onlyOwner {
        boopHP = _boopHP;
    }

    function setLoopMultiplier(uint256 _loopMultiplier) public onlyOwner {
        loopMultiplier = _loopMultiplier;
    }

    function currentBoopPrice(bool isFlash, bool isETH) public view returns (uint256) {
        uint256 timeSinceLastBoop = block.timestamp - lastBoop[msg.sender];
        uint256 basePrice = isFlash ? pricePerFlashBoop : isETH ? pricePerBoopETH : pricePerBoopGNOME;
        uint256 startPrice = basePrice * priceMultiplier;

        // Check if it's within the cooldown period to adjust the price
        if (timeSinceLastBoop < boopCoolDown) {
            uint256 priceDecreasePerSecond = (startPrice - basePrice) / boopCoolDown;
            uint256 priceDecrease = timeSinceLastBoop * priceDecreasePerSecond;
            uint256 currentPrice = startPrice - priceDecrease;
            return currentPrice;
        } else {
            return basePrice; // After cooldown, return to base price
        }
    }

    function boopResult(uint256 booperGnome, uint256 boopedGnome, uint256 i) internal returns (bool) {
        uint256 booperGnomeXP = gnome.getXP(booperGnome);
        uint256 boopedGnomeXP = gnome.getXP(boopedGnome);
        // Generate a random number using block.timestamp
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp * i, booperGnome, boopedGnome)));

        // Convert the random number into a boolean
        bool result = (randomNumber % 100) < boopOdds;
        if (result) {
            gnome.increaseXP(booperGnome, (boopedGnomeXP * boopWin) / 100);
            gnome.decreaseHP(boopedGnome, boopHP);

            gnome.setBoopTimeStamp(boopedGnome, block.timestamp);
            if (boopedGnomeXP > 10000) {
                uint256 amount = (booperGnomeXP * boopWin) / 100;
                gnome.decreaseXP(boopedGnome, amount > boopedGnomeXP ? boopedGnomeXP : amount);
            }
        } else {
            if (booperGnomeXP > 10000) {
                uint256 amount = (booperGnomeXP * boopLoose) / 100;
                gnome.decreaseXP(booperGnome, amount > booperGnomeXP ? booperGnomeXP : amount);
            }
        }

        return result;
    }

    function boopGnome(uint256 boopedTokenId) public {
        uint256 booperTokenId = gnome.getID(msg.sender);
        uint256 booperGnomeXP = gnome.getXP(booperTokenId);
        uint256 boopedGnomeXP = gnome.getXP(boopedTokenId);
        require(booperTokenId > 0, "User Not SignedUp");
        require(booperTokenId != boopedGnomeXP, "you can't Boop yourself");
        require(boopedGnomeXP >= booperGnomeXP, "You Can only Boop players with moreXP than you");
        require(
            !gnome.isMeditating(booperTokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );

        require(!gnome.getIsSleeping(booperTokenId), "You need to wake up your Gnome First!");
        require(gnome.canGetBooped(boopedTokenId), "Gnome has been booped rencently or has a shield try again later");

        uint256 boopAmount = currentBoopPrice(true, false);
        address boopToken = GNOME;
        address otherToken = boopToken == WETH9 ? GNOME : WETH9;
        (address token0, address token1) = boopToken < otherToken ? (boopToken, otherToken) : (otherToken, boopToken);
        uint256 amount0 = boopToken == token0 ? boopAmount : 0;
        uint256 amount1 = boopToken == token1 ? boopAmount : 0;
        bool result = boopResult(booperTokenId, boopedTokenId, 1);
        FlashCallbackData memory callbackData = FlashCallbackData({
            token: boopToken,
            amount: boopAmount,
            payer: tx.origin
        });
        IUniswapV3Pool(pool).flash(address(this), amount0, amount1, abi.encode(callbackData, pool));
        emit Boop(
            msg.sender,
            gnome.getTokenUserName(booperTokenId),
            gnome.getTokenUserName(boopedTokenId),
            false,
            result
        );
        lastBoop[msg.sender] = block.timestamp;
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external override {
        (FlashCallbackData memory callback, address flashPool) = abi.decode(data, (FlashCallbackData, address));
        require(msg.sender == address(pool), "Only Pool can call!");

        address feedToken = callback.token;
        uint256 amount = callback.amount;
        uint256 fee = fee0 > 0 ? fee0 : fee1;
        // start trade
        uint256 amountOwed = amount + fee;
        getFeeFromGnome(feedToken, multiplier * fee, callback.payer);

        IWETH(feedToken).transfer(flashPool, amountOwed);
    }

    function setMulDiv(uint256 _mul, uint256 _div) external onlyOwner {
        mul = _mul;
        div = _div;
    }

    function buyGnome(
        uint256 slip,
        bool isWETH,
        bool slipOn
    ) public payable returns (uint amountGnome, uint amountWeth) {
        if (!isWETH) {
            // Wrap ETH to WETH
            IWETH(WETH9).deposit{value: msg.value}();
            assert(IWETH(WETH9).transfer(address(this), msg.value));
        }

        uint amountToSwap = msg.value;
        uint amountOutMinimum;
        // Approve the router to spend WETH
        IWETH(WETH9).approve(address(swapRouter), msg.value);
        if (slipOn) {
            // Estimate the amount of GNOME to be received
            uint expectedAmountGnome = getExpectedAmountGnome(amountToSwap);

            // Calculate the minimum amount after slippage
            amountOutMinimum = (expectedAmountGnome * (10000 - slip)) / 10000;
        }
        // Set up swap parameters with amountOutMinimum based on slippage tolerance
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: GNOME,
            fee: 10000, // Assuming a 0.1% pool fee
            recipient: msg.sender,
            amountIn: amountToSwap,
            amountOutMinimum: slipOn ? amountOutMinimum : 0,
            sqrtPriceLimitX96: 0
        });

        // Perform the swap
        amountGnome = swapRouter.exactInputSingle(params);
    }

    function getExpectedAmountGnome(uint amountWeth) public view returns (uint expectedAmountGnome) {
        uint price = gnomePrice(address(pool), _twapInterval); // Get the current price of GNOME in terms of WETH
        // Assuming the price is the amount of WETH needed to buy 1 GNOME,
        // and both tokens have the same decimals (e.g., 18),
        // you can calculate the expected amount of GNOME as follows:
        expectedAmountGnome = (amountWeth * (10 ** 18)) / price;
        return expectedAmountGnome;
    }

    function multiActionWeth(string memory activity) public payable returns (uint amountGnome, uint amountWeth) {
        require(activityPriceETH[activity] > 0, "Gnomes can't do that yet");

        uint256 tokenId = gnome.getID(msg.sender);
        require(
            !gnome.isMeditating(tokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );
        if (keccak256(abi.encodePacked(activity)) != keccak256(abi.encodePacked("wakeup"))) {
            require(!gnome.getIsSleeping(tokenId), "You need to wake up your Gnome First!");
        }
        require(msg.value >= activityPriceETH[activity], "You Need to send more ETH");
        IWETH(WETH9).deposit{value: msg.value}();
        assert(IWETH(WETH9).transfer(address(this), msg.value));

        amountWeth = msg.value;
        gnome.increaseETHSpentAmount(tokenId, amountWeth);
        uint amount = amountWeth / activityPriceETH[activity];
        gnome.increaseHP(tokenId, amount * activityHP[activity]);
        gnome.increaseGnomeActivityAmount(activity, tokenId, amount);
        uint256 volGenerated;
        // Approve the router to spend WETH
        IWETH(WETH9).approve(address(swapRouter), type(uint256).max);
        IWETH(GNOME).approve(address(swapRouter), type(uint256).max);
        activityAmountETH[msg.sender] += msg.value;
        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("meditate")))
            gnome.setMeditateTimeStamp(tokenId, block.timestamp + amount * meditationTime);
        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("wakeup"))) {
            gnome.wakeUpGnome(tokenId);
        }
        // Set up swap parameters
        for (uint256 i = 0; i < amount; i++) {
            // Buy
            for (uint256 j = 0; j < loopMultiplier; j++) {
                volGenerated += amountWeth;
                ISwapRouter.ExactInputSingleParams memory paramsBuy = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH9,
                    tokenOut: GNOME,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: amountWeth,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountGnome = swapRouter.exactInputSingle(paramsBuy);

                // Sell

                ISwapRouter.ExactInputSingleParams memory paramsSell = ISwapRouter.ExactInputSingleParams({
                    tokenIn: GNOME,
                    tokenOut: WETH9,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: (amountGnome * margin) / 100,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountWeth = swapRouter.exactInputSingle(paramsSell);
            }
        }

        emit MultiActivity(
            msg.sender,
            activity,
            gnome.getTokenUserName(tokenId),
            true,
            amount,
            gnome.currentHP(tokenId),
            volGenerated
        );
    }

    function multiActionGnome(string memory activity, uint amount) public returns (uint amountGnome, uint amountWeth) {
        require(activityPriceGnome[activity] > 0, "Gnomes can't do that yet");
        uint256 tokenId = gnome.getID(msg.sender);
        require(
            !gnome.isMeditating(tokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );
        if (keccak256(abi.encodePacked(activity)) != keccak256(abi.encodePacked("wakeup")))
            require(!gnome.getIsSleeping(tokenId), "You need to wake up your Gnome First!");
        uint256 _gnomeAmount = activityPriceGnome[activity] * amount;

        IGNOME(GNOME).transferFrom(msg.sender, address(this), _gnomeAmount);
        gnome.increaseHP(tokenId, amount * activityHP[activity]);
        gnome.increaseGnomeActivityAmount(activity, tokenId, amount);
        gnome.increaseGnomeSpentAmount(tokenId, _gnomeAmount);
        uint256 volGenerated;
        // Approve the router to spend WETH

        activityAmountGnome[msg.sender] += activityPriceGnome[activity] * amount;
        IWETH(GNOME).approve(address(swapRouter), type(uint256).max);
        IWETH(WETH9).approve(address(swapRouter), type(uint256).max);
        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("meditate")))
            gnome.setMeditateTimeStamp(tokenId, block.timestamp + amount * meditationTime);

        if (keccak256(abi.encodePacked(activity)) == keccak256(abi.encodePacked("wakeup"))) gnome.wakeUpGnome(tokenId);
        // Set up swap parameters
        for (uint256 i = 0; i < amount; i++) {
            for (uint256 j = 0; j < loopMultiplier; j++) {
                volGenerated += (_gnomeAmount * margin) / 100;
                ISwapRouter.ExactInputSingleParams memory paramsSell = ISwapRouter.ExactInputSingleParams({
                    tokenIn: GNOME,
                    tokenOut: WETH9,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: (activityPriceGnome[activity] * amount * margin) / 100,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountWeth = swapRouter.exactInputSingle(paramsSell);

                ISwapRouter.ExactInputSingleParams memory paramsBuy = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH9,
                    tokenOut: GNOME,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: amountWeth,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                _gnomeAmount = swapRouter.exactInputSingle(paramsBuy);
            }
        }
        emit MultiActivity(
            msg.sender,
            activity,
            gnome.getTokenUserName(tokenId),
            false,
            amount,
            gnome.currentHP(tokenId),
            volGenerated
        );
    }

    function multiBoopWeth(uint256 boopedTokenId) public payable returns (uint amountGnome, uint amountWeth) {
        uint256 booperTokenId = gnome.getID(msg.sender);
        uint256 booperGnomeXP = gnome.getXP(booperTokenId);
        uint256 boopedGnomeXP = gnome.getXP(boopedTokenId);
        require(booperTokenId > 0, "User Not SignedUp");
        require(booperTokenId != boopedGnomeXP, "you can't Boop yourself");
        require(boopedGnomeXP > booperGnomeXP, "You Can only Boop players with moreXP than you");
        require(!gnome.getIsSleeping(booperTokenId), "You need to wake up your Gnome First!");
        require(msg.value >= currentBoopPrice(false, true), "You Need to send more ETH");
        require(
            !gnome.isMeditating(booperTokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );
        require(
            gnome.canGetBooped(boopedTokenId),
            "Gnome has been booped rencently, has a shield or its Meditating try again later"
        );

        IWETH(WETH9).deposit{value: msg.value}();
        assert(IWETH(WETH9).transfer(address(this), msg.value));
        gnome.increaseETHSpentAmount(booperTokenId, msg.value);
        uint amountWeth = msg.value;
        activityAmountETH[msg.sender] += msg.value;
        uint boopAmount = amountWeth / currentBoopPrice(false, true);
        uint256 boopedAmount;
        uint256 volGenerated;

        // Approve the router to spend WETH
        IWETH(WETH9).approve(address(swapRouter), type(uint256).max);
        IWETH(GNOME).approve(address(swapRouter), type(uint256).max);
        boopAmountETH[msg.sender] = msg.value;

        // Set up swap parameters
        for (uint256 i = 0; i < boopAmount; i++) {
            // Buy
            for (uint256 j = 0; j < loopMultiplier; j++) {
                volGenerated += amountWeth;
                ISwapRouter.ExactInputSingleParams memory paramsBuy = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH9,
                    tokenOut: GNOME,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: amountWeth,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountGnome = swapRouter.exactInputSingle(paramsBuy);

                // Sell

                ISwapRouter.ExactInputSingleParams memory paramsSell = ISwapRouter.ExactInputSingleParams({
                    tokenIn: GNOME,
                    tokenOut: WETH9,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: (amountGnome * margin) / 100,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountWeth = swapRouter.exactInputSingle(paramsSell);
            }

            bool result = boopResult(booperTokenId, boopedTokenId, i);
            if (result) {
                boopedAmount++;
            }
        }
        emit MultiBoop(
            msg.sender,
            gnome.getTokenUserName(booperTokenId),
            gnome.getTokenUserName(boopedTokenId),
            true,
            boopAmount,
            boopedAmount,
            volGenerated
        );
    }

    function multiBoopGnome(
        uint256 boopedTokenId,
        uint256 _gnomeAmount
    ) public returns (uint amountGnome, uint amountWeth) {
        uint256 booperTokenId = gnome.getID(msg.sender);
        IGNOME(GNOME).transferFrom(msg.sender, address(this), _gnomeAmount);
        require(booperTokenId > 0, "User Not SignedUp");
        require(
            !gnome.isMeditating(booperTokenId),
            "Meditating Gnomes must focus on the astral mission they can't indulge in such activities"
        );
        require(!gnome.getIsSleeping(booperTokenId), "You need to wake up your Gnome First!");
        require(gnome.canGetBooped(boopedTokenId), "Gnome has been booped rencently or has a shield try again later");
        gnome.increaseGnomeSpentAmount(booperTokenId, _gnomeAmount);
        uint boopAmount = _gnomeAmount / currentBoopPrice(false, false);
        uint256 boopedAmount;
        uint256 volume;
        activityAmountGnome[msg.sender] += _gnomeAmount;
        // Approve the router to spend WETH

        boopAmountGnome[msg.sender] = _gnomeAmount;
        IWETH(GNOME).approve(address(swapRouter), type(uint256).max);
        IWETH(WETH9).approve(address(swapRouter), type(uint256).max);
        // Set up swap parameters
        for (uint256 i = 0; i < boopAmount; i++) {
            for (uint256 j = 0; j < loopMultiplier; j++) {
                volume += (_gnomeAmount * margin) / 100;
                ISwapRouter.ExactInputSingleParams memory paramsSell = ISwapRouter.ExactInputSingleParams({
                    tokenIn: GNOME,
                    tokenOut: WETH9,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: (_gnomeAmount * margin) / 100,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                amountWeth = swapRouter.exactInputSingle(paramsSell);

                ISwapRouter.ExactInputSingleParams memory paramsBuy = ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH9,
                    tokenOut: GNOME,
                    fee: 10000, // Assuming a 0.1% pool fee
                    recipient: address(this),
                    amountIn: amountWeth,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                _gnomeAmount = swapRouter.exactInputSingle(paramsBuy);
            }
            bool result = boopResult(booperTokenId, boopedTokenId, 1);
            if (result) {
                boopedAmount++;
            }
        }
        emit MultiBoop(
            msg.sender,
            gnome.getTokenUserName(booperTokenId),
            gnome.getTokenUserName(boopedTokenId),
            false,
            boopAmount,
            boopedAmount,
            volume
        );
    }

    function getFeeFromGnome(address token, uint256 amount, address fren) internal {
        IGNOME(token).transferFrom(fren, address(this), amount);
        activityAmountGnome[fren] += amount;
        uint256 booperTokenId = gnome.getID(fren);
        gnome.increaseGnomeSpentAmount(booperTokenId, amount);
    }

    function changeFlashPoolFee(uint24 poolFee) public onlyOwner {
        flashPoolFee = poolFee;
    }

    function setGameContract(address _gameAddress) public onlyOwner {
        gnome = IGNOME(_gameAddress);
    }

    function setMultiplier(uint24 _multiplier, uint256 _priceMultiplier) public onlyOwner {
        multiplier = _multiplier;
        priceMultiplier = _priceMultiplier;
    }

    function setMargin(uint24 _margin) public onlyOwner {
        margin = _margin;
    }

    function setActionPrice(string memory action, uint256 _priceETH, uint256 _priceGnome) public onlyOwner {
        activityPriceGnome[action] = _priceGnome;
        activityPriceETH[action] = _priceETH;
    }

    function frensFundus() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IGNOME(token).balanceOf(address(this));
        IGNOME(token).transfer(msg.sender, balance);
    }

    function gnomePrice(address uniswapV3Pool, uint32 twapInterval) public view returns (uint256 price) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );
            price = (amount1 * mul) / (amount0 * div);
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(twapInterval)))
            );

            uint256 amount0 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                FixedPoint96.Q96,
                sqrtPriceX96
            );

            uint256 amount1 = FullMath.mulDiv(
                IUniswapV3Pool(uniswapV3Pool).liquidity(),
                sqrtPriceX96,
                FixedPoint96.Q96
            );

            price = (amount1 * mul) / (amount0 * div);
        }
    }

    function setTwap(uint32 twapInterval) public onlyOwner {
        _twapInterval = twapInterval;
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // EDIT for 0.8 compatibility:
            // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
            uint256 twos = denominator & (~denominator + 1);

            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

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

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import { FullMath } from "./FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate =
            FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount0,
                    intermediate,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return
            toUint128(
                FullMath.mulDiv(
                    amount1,
                    FixedPoint96.Q96,
                    sqrtRatioBX96 - sqrtRatioAX96
                )
            );
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 =
                getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 =
                getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                liquidity,
                sqrtRatioBX96 - sqrtRatioAX96,
                FixedPoint96.Q96
            );
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(
                sqrtRatioX96,
                sqrtRatioBX96,
                liquidity
            );
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioX96,
                liquidity
            );
        } else {
            amount1 = getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;


/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState {
    address public immutable factory;
    address public immutable WETH9;

    constructor(address _factory, address _WETH9) {
        factory = _factory;
        WETH9 = _WETH9;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
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
            )
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

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
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        uint256 absTick =
            tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

        // EDIT: 0.8 compatibility
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio =
            absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96)
        internal
        pure
        returns (int24 tick)
    {
        // second inequality must be < because the price can never reach the price at the max tick
        require(
            sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO,
            "R"
        );
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

        int24 tickLow =
            int24(
                (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
            );
        int24 tickHi =
            int24(
                (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
            );

        tick = tickLow == tickHi
            ? tickLow
            : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}