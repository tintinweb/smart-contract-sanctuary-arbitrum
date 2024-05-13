// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import './Proxy.sol';
import '../contracts/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view override returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        //solium-disable-next-line
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param newImplementation Address of the new implementation.
     */
    function _setImplementation(address newImplementation) internal {
        require(
            Address.isContract(newImplementation),
            'Cannot set a proxy implementation to a non-contract address'
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        //solium-disable-next-line
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
     * @dev Contract initializer.
     * @param _logic Address of the initial implementation.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    function initialize(address _logic, bytes memory _data) public payable {
        require(_implementation() == address(0));
        assert(
            IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
        );
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
    /**
     * @dev Fallback function.
     * Will run if no other function in the contract matches the call data.
     * Implemented entirely in `_fallback`.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @return The Address of the implementation.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn't return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param implementation Address to delegate.
     */
    function _delegate(address implementation) internal {
        //solium-disable-next-line
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Function that is run as the first thing in the fallback function.
     * Can be redefined in derived contracts to add functionality.
     * Redefinitions must call super._willFallback().
     */
    function _willFallback() internal virtual {}

    /**
     * @dev fallback implementation.
     * Extracted to enable manual triggering.
     */
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
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

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

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
    IUniswapV3PoolErrors,
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

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
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
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
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
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
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
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
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
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {IGuildAddressesProvider} from "./IGuildAddressesProvider.sol";

/**
 * @title IACLManager
 * @author Amorphous (cloned from AAVE core v3 commit d5fafce)
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
    /**
     * @notice Returns the contract address of the GuildAddressesProvider
     * @return The address of the GuildAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IGuildAddressesProvider);

    /**
     * @notice Returns the identifier of the GuildAdmin role
     * @return The id of the GuildAdmin role
     */
    function GUILD_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the EmergencyAdmin role
     * @return The id of the EmergencyAdmin role
     */
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the RiskAdmin role
     * @return The id of the RiskAdmin role
     */
    function RISK_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Set the role as admin of a specific role.
     * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
     * @param role The role to be managed by the admin role
     * @param adminRole The admin role
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new admin as GuildAdmin
     * @param admin The address of the new admin
     */
    function addGuildAdmin(address admin) external;

    /**
     * @notice Removes an admin as GuildAdmin
     * @param admin The address of the admin to remove
     */
    function removeGuildAdmin(address admin) external;

    /**
     * @notice Returns true if the address is GuildAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is GuildAdmin, false otherwise
     */
    function isGuildAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as EmergencyAdmin
     * @param admin The address of the new admin
     */
    function addEmergencyAdmin(address admin) external;

    /**
     * @notice Removes an admin as EmergencyAdmin
     * @param admin The address of the admin to remove
     */
    function removeEmergencyAdmin(address admin) external;

    /**
     * @notice Returns true if the address is EmergencyAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is EmergencyAdmin, false otherwise
     */
    function isEmergencyAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as RiskAdmin
     * @param admin The address of the new admin
     */
    function addRiskAdmin(address admin) external;

    /**
     * @notice Removes an admin as RiskAdmin
     * @param admin The address of the admin to remove
     */
    function removeRiskAdmin(address admin) external;

    /**
     * @notice Returns true if the address is RiskAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is RiskAdmin, false otherwise
     */
    function isRiskAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IGuild} from "./IGuild.sol";
import {INotionalERC20} from "./INotionalERC20.sol";
import {IInitializableAssetToken} from "./IInitializableAssetToken.sol";

interface IAssetToken is IERC20, INotionalERC20, IInitializableAssetToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function updateNotionalFactor(uint256 multFactor) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

/**
 * @title ICreditDelegation
 * @author Amorphous, inspired by AAVE v3
 * @notice Defines the basic interface for a token supporting credit delegation.
 **/
interface ICreditDelegation {
    /**
     * @dev Emitted on `approveDelegation` and `borrowAllowance
     * @param fromUser The address of the delegator
     * @param toUser The address of the delegatee
     * @param amount The amount being delegated
     */
    event BorrowAllowanceDelegated(address indexed fromUser, address indexed toUser, uint256 amount);

    /**
     * @notice Increases the allowance of delegatee to mint _msgSender() tokens
     * @param delegatee The delegatee allowed to mint on behalf of _msgSender()
     * @param addedValue The amount being added to the allowance
     **/
    function increaseDelegation(address delegatee, uint256 addedValue) external;

    /**
     * @notice Decreases the borrow allowance of a user on the specific debt token.
     * @param delegatee The address receiving the delegated borrowing power
     * @param amount The amount to subtract from the current allowance
     */
    function decreaseDelegation(address delegatee, uint256 amount) external;

    /**
     * @notice Delegates borrowing power to a user on the specific debt token.
     * Delegation will still respect the liquidation constraints (even if delegated, a
     * delegatee cannot force a delegator HF to go below 1)
     * @param delegatee The address receiving the delegated borrowing power
     * @param amount The maximum amount being delegated.
     **/
    function approveDelegation(address delegatee, uint256 amount) external;

    /**
     * @notice Returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return The current allowance of `toUser`
     **/
    function borrowAllowance(address fromUser, address toUser) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {IGuildAddressesProvider} from "./IGuildAddressesProvider.sol";
import {IAssetToken} from "./IAssetToken.sol";
import {ILiabilityToken} from "./ILiabilityToken.sol";
import {IGuildAddressesProvider} from "./IGuildAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";

/**
 * @title IGuild
 * @author Amorphous
 * @notice Defines the basic interface for a Guild.
 **/
interface IGuild {
    /**
     * @dev Emitted on deposit()
     * @param collateral The address of the collateral asset
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit
     * @param amount The amount supplied
     **/
    event Deposit(address indexed collateral, address user, address indexed onBehalfOf, uint256 amount);

    /**
     * @dev Emitted on withdraw()
     * @param collateral The address of the collateral asset
     * @param user The address initiating the withdrawal
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(address indexed collateral, address indexed user, address indexed to, uint256 amount);

    /**
     * @notice Returns the GuildAddressesProvider connected to this contract
     * @return The address of the GuildAddressesProvider
     **/
    function ADDRESSES_PROVIDER() external view returns (IGuildAddressesProvider);

    /**
     * @notice Refinances perpetual debt.
     * @dev Makes uniswap DEX call, and calculates TWAP price vs last time refinance was called.
     * Uses TWAP price to calculate interest rate in that period.
     **/
    function refinance() external;

    /**
     * @notice Supplies an `amount` of collateral into the Guild.
     * @param asset The address of the ERC20 asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that receives the collateral 'credit', same as msg.sender if the user
     *   wants it to account to their own wallet, or a different address if the beneficiary is someone else
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external;

    /**
     * @notice Withdraw an `amount` of underlying asset from the Guild.
     * @param asset The addres of the ERC20 asset to withdraw
     * @param amount The amount to be withdraw (in WADs if that's the collateral's precision)
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Initializes a perpetual debt.
     * @param assetTokenProxyAddress The proxy address of the underlying asset token contract (zToken)
     * @param liabilityTokenProxyAddress The proxy address of the underlying liability token contract (dToken)
     * @param moneyAddress The address of the money token on which the debt is denominated in
     * @param duration The duration, in seconds, of the perpetual debt
     * @param notionalPriceLimitMax Maximum price used for refinance purposes
     * @param notionalPriceLimitMin Minimum price used for refinance purposes
     * @param dexFactory Uniswap v3 Factory address
     * @param dexFee Uniswap v3 pool fee (to identify pool used for refinance oracle purposes)
     **/
    function initPerpetualDebt(
        address assetTokenProxyAddress,
        address liabilityTokenProxyAddress,
        address moneyAddress,
        uint256 duration,
        uint256 notionalPriceLimitMax,
        uint256 notionalPriceLimitMin,
        address dexFactory,
        uint24 dexFee
    ) external;

    /**
     * @notice Initializes a collateral, activating it, and configuring it's parameters
     * @dev Only callable by the GuildConfigurator contract
     * @param asset The address of the ERC20 collateral
     **/
    function initCollateral(address asset) external;

    /**
     * @notice Drop a collateral
     * @dev Only callable by the GuildConfigurator contract
     * @param asset The address of the ERC20 to drop as an acceptable collateral
     **/
    function dropCollateral(address asset) external;

    /**
     * @notice Sets the configuration bitmap of the collateral as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the ERC20 collateral
     * @param configuration The new configuration bitmap
     **/
    function setConfiguration(address asset, DataTypes.CollateralConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the collateral
     * @param asset The address of the ERC20 collateral
     * @return The configuration of the collateral
     **/
    function getCollateralConfiguration(address asset)
        external
        view
        returns (DataTypes.CollateralConfigurationMap memory);

    /**
     * @notice Returns the collateral balance of a user in the Guild
     * @param user The address of the user
     * @param asset The address of the collateral asset
     * @return The collateral amount deposited in the Guild
     **/
    function getCollateralBalanceOf(address user, address asset) external view returns (uint256);

    /**
     * @notice Returns the total collateral balance in the Guild
     * @param asset The address of the collateral asset
     * @return The total collateral amount deposited in the Guild
     **/
    function getCollateralTotalBalance(address asset) external view returns (uint256);

    /**
     * @notice Returns the list of all initialized collaterals
     * @dev It does not include dropped collaterals
     * @return The addresses of the initialized collaterals
     **/
    function getCollateralsList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying collateral by collateral id as stored in the DataTypes.CollateralData struct
     * @param id The id of the collateral as stored in the DataTypes.CollateralData struct
     * @return The address of the collateral associated with id
     **/
    function getCollateralAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the maximum number of collaterals supported by this Guild
     * @return The maximum number of collaterals supported
     */
    function maxNumberCollaterals() external view returns (uint16);

    /**
     * @notice Sets the configuration bitmap of the perpetual debt
     * @dev Only callable by the GuildConfigurator contract
     * @param configuration The new configuration bitmap
     **/
    function setPerpDebtConfiguration(DataTypes.PerpDebtConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the perpetual debt
     * @return The configuration of the perpetual debt
     **/
    function getPerpDebtConfiguration() external view returns (DataTypes.PerpDebtConfigurationMap memory);

    /**
     * @dev Emitted on borrow() when debt needs to be opened
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The zToken amount borrowed out
     * @param amountNotional The notional amount borrowed out (in Notional)
     **/
    event Borrow(address indexed user, address indexed onBehalfOf, uint256 amount, uint256 amountNotional);

    /**
     * @dev Emitted on repay()
     * @param user The address of the account whose zTokens are used to pay back the debt
     * @param onBehalfOf The address that will be getting the debt paid back
     * @param amount The zToken amount repaid
     * @param amountNotional The notional amount repaid (in Notional)
     **/
    event Repay(address indexed user, address indexed onBehalfOf, uint256 amount, uint256 amountNotional);

    /**
     * @dev Emitted on swapMoneyForZToken()
     * @param user The address of the account who is swapping money for ZToken (at 1:1 faceprice)
     * @param moneyIn The money amount swapped
     * @param zTokenOut The zToken amount received (including swap fees paid)
     **/
    event MoneyForZTokenSwap(address indexed user, uint256 moneyIn, uint256 zTokenOut);

    /**
     * @dev Emitted on swapZTokenForMoney()
     * @param user The address of the user who is swapping zToken for money (at 1:1 faceprice)
     * @param zTokenIn The zToken amount swapped
     * @param moneyOut The money amount received (including disribution fees)
     **/
    event ZTokenForMoneySwap(address indexed user, uint256 zTokenIn, uint256 moneyOut);

    /**
     * @notice Get money token
     **/
    function getMoney() external view returns (IERC20);

    /**
     * @notice Get asset token
     **/
    function getAsset() external view returns (IAssetToken);

    /**
     * @notice get liability token
     **/
    function getLiability() external view returns (ILiabilityToken);

    /**
     * @notice get perpetual debt data
     **/
    function getPerpetualDebt() external view returns (DataTypes.PerpetualDebtData memory);

    /**
     * @notice get DEX address from which the Guild derives refinance prices
     **/
    function getDex() external view returns (address);

    /**
     * @notice Updates notional price limits used during refinancing.
     * @dev Perpetual debt interest rates are proportional to 1/notionalPrice.
     * @param priceMin Minimum notional price to use for refinancing.
     * @param priceMax Maximum notional price to use for refinancing.
     **/
    function setPerpDebtNotionalPriceLimits(uint256 priceMax, uint256 priceMin) external;

    /**
     * @notice Updates the protocol service fee address where service fees are deposited
     * @param newAddress new protocol service fee address
     **/
    function setProtocolServiceFeeAddress(address newAddress) external;

    /**
     * @notice Updates the protocol mint fee address where mint fees are deposited
     * @param newAddress new protocol mint fee address
     **/
    function setProtocolMintFeeAddress(address newAddress) external;

    /**
     * @notice Updates the protocol distribution fee address where distribution fees are deposited
     * @param newAddress new protocol distribution fee address
     **/
    function setProtocolDistributionFeeAddress(address newAddress) external;

    /**
     * @notice Updates the protocol swap fee address where distribution fees are deposited
     * @param newAddress new protocol swap fee address
     **/
    function setProtocolSwapFeeAddress(address newAddress) external;

    /**
     * @notice Allows users to borrow a specific `amount` of the zTokens, provided that the borrower
     * already supplied enough collateral.
     * @param amount The zToken amount to be borrowed
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance to msg.sender
     **/
    function borrow(uint256 amount, address onBehalfOf) external;

    /**
     * @notice Payback specific borrowed `amount`, which in turn burns the equivalent amount of dTokens
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param amount The zToken amount to be paid back
     * @return The final notional amount repaid
     **/
    function repay(uint256 amount, address onBehalfOf) external returns (uint256);

    /**
     * @notice Return structure for getUserAccountData function
     * @return totalCollateralInBaseCurrency The total collateral of the user in the base currency used by the price feed with a BORROW context
     * @return totalDebtNotionalInBaseCurrency The total debt of the user in the base currency used by the price feed with a BORROW context
     * @return availableBorrowsInBaseCurrency The borrowing power left of the user in the base currency used by the price feed
     * @return totalCollateralInBaseCurrencyForLiquidationTrigger The total collateral of the user in the base currency used by the price feed with a LIQUIDATION_TRIGGER context
     * @return currentLiquidationThreshold The liquidation threshold of the user with a price feed in the Liquidation Trigger Context
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     * @return totalDebt The total base debt of the user in the native dToken decimal unit
     * @return availableBorrowsInZTokens The total zTokens that can be minted given borrowing capacity
     * @return availableNotionalBorrows The total notional that can be minted given borrowing capacity
     * @return zTokensToRepayDebt The total zTokens required to repay the accounts totalDebtNotional (in native zToken decimal unit)
     **/
    struct UserAccountDataStruct {
        uint256 totalCollateralInBaseCurrency;
        uint256 totalDebtNotionalInBaseCurrency;
        uint256 availableBorrowsInBaseCurrency;
        uint256 totalCollateralInBaseCurrencyForLiquidationTrigger;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        uint256 totalDebt;
        uint256 availableBorrowsInZTokens;
        uint256 availableNotionalBorrows;
        uint256 zTokensToRepayDebt;
    }

    /**
     * @notice Returns the user account data across all the collaterals
     * @param user The address of the user
     * @return userData User variables as per UserAccountDataStruct structure
     **/
    function getUserAccountData(address user) external view returns (UserAccountDataStruct memory userData);

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtNotionalToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset`in their wallet plus a bonus to cover market risk
     * @param collateralAsset The address of the collateral asset, to receive as result of the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt base amount the liquidator wants to cover (in dToken units)
     **/
    function liquidationCall(
        address collateralAsset,
        address user,
        uint256 debtToCover
    ) external;

    /**
     * @notice Executes validation of deposit() function, and reverts with same validation logic
     * @dev does not update on-chain state
     * @param asset The address of the ERC20 asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that receives the collateral 'credit', same as msg.sender if the user
     *   wants it to account to their own wallet, or a different address if the beneficiary is someone else
     **/
    function validateDeposit(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external view;

    /**
     * @notice Executes validation of withdraw() function, and reverts with same validation logic
     * @dev does not update on-chain state
     * @param asset The address of the ERC20 asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that receives the collateral 'withdrawal', same as msg.sender if the user
     *   wants it to account to their own wallet, or a different address if the beneficiary is someone else
     **/
    function validateWithdraw(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external view;

    /**
     * @notice Executes validation of borrow() function, and reverts with same validation logic
     * @param amount The zToken amount to be borrowed
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance to msg.sender
     **/
    function validateBorrow(uint256 amount, address onBehalfOf) external view;

    /**
     * @notice Executes validation of repay() function, and reverts with same validation logic
     * @param amount The zToken amount  to be paid back
     **/
    function validateRepay(uint256 amount) external view;

    /**
     * @notice Executes money for zToken swap at price = Notional Factor
     * @param moneyIn The money amount to swap in
     **/
    function swapMoneyForZToken(uint256 moneyIn) external returns (uint256);

    /**
     * @notice Executes zToken for money swap at price = Notional Factor
     * @param zTokenIn The money amount to swap in
     **/
    function swapZTokenForMoney(uint256 zTokenIn) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

/**
 * @title IGuildAddressesProvider
 * @author Amorphous (cloned from AAVE core v3 commit d5fafce)
 * @notice Defines the basic interface for a Guild Addresses Provider.
 **/
interface IGuildAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldGuildId The old id of the market
     * @param newGuildId The new id of the market
     */
    event GuildIdSet(string indexed oldGuildId, string indexed newGuildId);

    /**
     * @dev Emitted when the Guild is updated.
     * @param oldAddress The old address of the Guild
     * @param newAddress The new address of the Guild
     */
    event GuildUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the Guild configurator is updated.
     * @param oldAddress The old address of the GuildConfigurator
     * @param newAddress The new address of the GuildConfigurator
     */
    event GuildConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the Guild data provider is updated.
     * @param oldAddress The old address of the GuildDataProvider
     * @param newAddress The new address of the GuildDataProvider
     */
    event GuildDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the GuildRoleManager is updated.
     * @param oldAddress The old address of the GuildRoleManager
     * @param newAddress The new address of the GuildRoleManager
     */
    event GuildRoleManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice Returns the id of the Aave market to which this contract points to.
     * @return The market id
     **/
    function getGuildId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific GuildAddressesProvider.
     * @dev This can be used to create an onchain registry of GuildAddressesProviders to
     * identify and validate multiple Guilds.
     * @param newGuildId The market id
     */
    function setGuildId(string calldata newGuildId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Guild proxy.
     * @return The Guild proxy address
     **/
    function getGuild() external view returns (address);

    /**
     * @notice Updates the implementation of the Guild, or creates a proxy
     * setting the new `Guild` implementation when the function is called for the first time.
     * @param newGuildImpl The new Guild implementation
     **/
    function setGuildImpl(address newGuildImpl) external;

    /**
     * @notice Returns the address of the GuildConfigurator proxy.
     * @return The GuildConfigurator proxy address
     **/
    function getGuildConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the GuildConfigurator, or creates a proxy
     * setting the new `GuildConfigurator` implementation when the function is called for the first time.
     * @param newGuildConfiguratorImpl The new GuildConfigurator implementation
     **/
    function setGuildConfiguratorImpl(address newGuildConfiguratorImpl) external;

    /**
     * @notice Returns the address of the GuildRoleManager proxy.
     * @return The GuildRoleManager proxy address
     **/
    function getGuildRoleManager() external view returns (address);

    /**
     * @notice Updates the implementation of the GuildRoleManager, or creates a proxy
     * setting the new `GuildRoleManager` implementation when the function is called for the first time.
     * @param newGuildRoleManagerImpl The new GuildRoleManager implementation
     **/
    function setGuildRoleManagerImpl(address newGuildRoleManagerImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     */
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     **/
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getGuildDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     **/
    function setGuildDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;
import {ConfiguratorInputTypes} from "../protocol/libraries/types/ConfiguratorInputTypes.sol";

/**
 * @title IGuildConfigurator
 * @author Amorphous
 * @notice Defines the basic interface for a Guild configurator.
 **/
interface IGuildConfigurator {
    /**
     * @dev Emitted when a collateral is initialized (added to list of accepted collaterals)
     * @param asset The address of the collateral asset
     **/
    event CollateralInitialized(address indexed asset);

    /**
     * @dev Emitted when a collateral is initialized.
     * @param assetToken The address of the associated assetToken contract
     * @param liabilityToken The address of the associated liability token
     * @param moneyToken The address of the associated money token
     * @param duration The perpetual debt duration
     * @param dexFee The dex fee
     **/
    event PerpetualDebtInitialized(
        address indexed assetToken,
        address liabilityToken,
        address moneyToken,
        uint256 duration,
        uint24 dexFee
    );

    /**
     * @dev Emitted when an AssetToken (zToken) implementation is upgraded.
     * @param guildAddress The address of the guild associated with the zToken
     * @param assetProxy The zToken proxy address
     * @param implementation The new zToken implementation
     **/
    event AssetTokenUpgraded(address indexed guildAddress, address indexed assetProxy, address indexed implementation);

    /**
     * @dev Emitted when a LiabilityToken (dToken) implementation is upgraded.
     * @param guildAddress  The address of the guild associated with the dToken
     * @param liabilityProxy The dToken proxy address
     * @param implementation The new dToken implementation
     **/
    event LiabilityTokenUpgraded(
        address indexed guildAddress,
        address indexed liabilityProxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the collateralization risk parameters for the specified collateral are updated.
     * @param asset The address of the underlying collateral asset
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset
     * @param nonMTMLiquidation flag that specifies whether collateral liquidations use MarkToMarket valuations or not
     **/
    event CollateralConfigurationChanged(
        address indexed asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        bool nonMTMLiquidation
    );

    /**
     * @dev Emitted when a collateral is activated or deactivated
     * @param asset The address of the collateral asset
     * @param active True if collateral is active, false otherwise
     **/
    event CollateralActive(address indexed asset, bool active);

    /**
     * @dev Emitted when a collateral is frozen or unfrozen
     * @param asset The address of the collateral asset
     * @param frozen True if collateral is frozen, false otherwise
     **/
    event CollateralFrozen(address indexed asset, bool frozen);

    /**
     * @dev Emitted when a collateral is paused or unpaused
     * @param asset The address of the collateral asset
     * @param paused True if collateral is paused, false otherwise
     **/
    event CollateralPaused(address indexed asset, bool paused);

    /**
     * @dev Emitted when a collateral is dropped.
     * @param asset The address of the collateral asset
     **/
    event CollateralDropped(address indexed asset);

    /**
     * @dev Emitted when the guild supply cap of a collateral is updated.
     * @param asset The address of the underlying collateral asset
     * @param oldSupplyCap The old supply cap
     * @param newSupplyCap The new supply cap
     **/
    event SupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);

    /**
     * @dev Emitted when the user (wallet level) supply cap of a collateral is updated.
     * @param asset The address of the underlying collateral asset
     * @param oldSupplyCap The old supply cap
     * @param newSupplyCap The new supply cap
     **/
    event UserSupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);

    /**
     * @dev Emitted when the protocol distribution fee of the perpetual debt is updated.
     * @param oldFee The old protocol distribution fee, expressed in bps
     * @param newFee The new protocol distribution fee, expressed in bps
     **/
    event ProtocolDistributionFeeChanged(uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when the protocol service fee of the perpetual debt is updated.
     * @param oldFee The old protocol service fee, expressed in bps
     * @param newFee The new protocol service fee, expressed in bps
     **/
    event ProtocolServiceFeeChanged(uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when the protocol mint fee of the perpetual debt is updated.
     * @param oldFee The old protocol mint fee, expressed in bps
     * @param newFee The new protocol mint fee, expressed in bps
     **/
    event ProtocolMintFeeChanged(uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when the protocol swap fee of the perpetual debt is updated.
     * @param oldFee The old protocol swap fee, expressed in bps
     * @param newFee The new protocol swap fee, expressed in bps
     **/
    event ProtocolSwapFeeChanged(uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when the protocol distribution fee address is updated
     * @param oldAddress The old address that received protocol distribution fees
     * @param newAddress The new address that received protocol distribution fees
     **/
    event ProtocolDistributionFeeAddressChanged(address oldAddress, address newAddress);

    /**
     * @dev Emitted when the protocol service fee address is updated
     * @param oldAddress The old address that received protocol service fees
     * @param newAddress The new address that received protocol service fees
     **/
    event ProtocolServiceFeeAddressChanged(address oldAddress, address newAddress);

    /**
     * @dev Emitted when the protocol mint fee address is updated
     * @param oldAddress The old address that received protocol mint fees
     * @param newAddress The new address that received protocol mint fees
     **/
    event ProtocolMintFeeAddressChanged(address oldAddress, address newAddress);

    /**
     * @dev Emitted when the protocol swap fee address is updated
     * @param oldAddress The old address that received protocol swap fees
     * @param newAddress The new address that received protocol swap fees
     **/
    event ProtocolSwapFeeAddressChanged(address oldAddress, address newAddress);

    /**
     * @dev Emitted when the perpetual debt is paused or unpaused
     * @param paused True if perpetual debt is paused, false otherwise
     **/
    event PerpDebtPaused(bool paused);

    /**
     * @dev Emitted when the perpetual debt is frozen or unfrozen
     * @param frozen True if perpetual debt is frozen, false otherwise
     **/
    event PerpDebtFrozen(bool frozen);

    /**
     * @dev Emitted when the mint cap of a perpetual debt is updated.
     * @param oldMintCap The old mint cap
     * @param newMintCap The new mint cap
     **/
    event MintCapChanged(uint256 oldMintCap, uint256 newMintCap);

    /**
     * @dev Emitted when the perpetual debt refinance limits are changed
     * @param priceMin Minimum notional price to use for refinancing.
     * @param priceMax Maximum notional price to use for refinancing.
     **/
    event PerpDebtLimitsChanged(uint256 priceMax, uint256 priceMin);

    /**
     * @notice Initializes multiple collaterals.
     * @param input The array of initialization parameters
     **/
    function initCollaterals(ConfiguratorInputTypes.InitCollateralInput[] calldata input) external;

    /**
     * @notice Drops a collateral entirely.
     * @param asset The address of the collateral to drop
     **/
    function dropCollateral(address asset) external;

    /**
     * @notice Activate or deactivate a collateral
     * @param asset The address of the collateral asset
     * @param active True if the collateral needs to be active, false otherwise
     **/
    function setCollateralActive(address asset, bool active) external;

    /**
     * @notice Freeze or unfreeze the collateral
     * @param asset Coolateral to freeze or unfreeze
     * @param frozen True if the collateral needs to be frozen, false otherwise
     **/
    function setCollateralFrozen(address asset, bool frozen) external;

    /**
     * @notice Pause or unpause the collateral
     * @param asset Coolateral to pause or unpause
     * @param paused True if the collateral needs to be paused, false otherwise
     **/
    function setCollateralPause(address asset, bool paused) external;

    /**
     * @notice Updates the supply cap of a collateral.
     * @param asset The address of the collateral asset
     * @param newSupplyCap The new supply cap of the collateral
     * @dev a cap of 0 indicates no cap
     **/
    function setSupplyCap(address asset, uint256 newSupplyCap) external;

    /**
     * @notice Updates the user (wallet level) supply cap of a collateral.
     * @param asset The address of the collateral asset
     * @param newSupplyCap The new supply cap of the collateral
     * @dev a cap of 0 indicates no cap
     **/
    function setUserSupplyCap(address asset, uint256 newSupplyCap) external;

    /**
     * @notice Updates the protocol distribution fee of the perpetual debt.
     * @param newFee The new protocol distribution fee of the perpetual debt, expressed in bps
     **/
    function setProtocolDistributionFee(uint256 newFee) external;

    /**
     * @notice Updates the protocol service fee of the perpetual debt.
     * @param newFee The new protocol service fee of the perpetual debt, expressed in bps
     **/
    function setProtocolServiceFee(uint256 newFee) external;

    /**
     * @notice Updates the protocol mint fee of the perpetual debt.
     * @param newFee The new protocol mint fee of the perpetual debt, expressed in bps
     **/
    function setProtocolMintFee(uint256 newFee) external;

    /**
     * @notice Updates the protocol swap fee of the perpetual debt.
     * @param newFee The new protocol sawp fee of the perpetual debt, expressed in bps
     **/
    function setProtocolSwapFee(uint256 newFee) external;

    /**
     * @notice Updates the protocol distribution fee address where distribution fees are deposited
     * @param newAddress new protocol distribution fee address
     **/
    function setProtocolDistributionFeeAddress(address newAddress) external;

    /**
     * @notice Updates the protocol service fee address where service fees are deposited
     * @param newAddress new protocol service fee address
     **/
    function setProtocolServiceFeeAddress(address newAddress) external;

    /**
     * @notice Updates the protocol mint fee address where service fees are deposited
     * @param newAddress new protocol mint fee address
     **/
    function setProtocolMintFeeAddress(address newAddress) external;

    /**
     * @notice Updates the protocol swap fee address where service fees are deposited
     * @param newAddress new protocol swap fee address
     **/
    function setProtocolSwapFeeAddress(address newAddress) external;

    /**
     * @notice Initializes Guild perpetual debt structure
     * @param input The array of initialization parameters
     **/
    function initPerpetualDebt(ConfiguratorInputTypes.InitPerpetualDebtInput calldata input) external;

    /**
     * @notice Updates the perpetual debt mint cap.
     * @param newMintCap The new mint cap of the perpetual debt
     * @dev a cap of 0 indicates no cap
     **/
    function setMintCap(uint256 newMintCap) external;

    /**
     * @notice Freeze or unfreeze the perpetual debt
     * @param frozen True if the perpetual debt needs to be frozen, false otherwise
     **/
    function setPerpDebtFrozen(bool frozen) external;

    /**
     * @notice Pause or unpause the perpetual debt
     * @param paused True if the perpetual debt needs to be paused, false otherwise
     **/
    function setPerpDebtPause(bool paused) external;

    /**
     * @notice Configures the collateralization parameters per collateral in a Guild
     * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
     * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
     * @param asset The address of the collateral being configured
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset
     * @param nonMTMLiquidation The flag indicating whether collateral liquidations use MarkToMarket valuations or not
     **/
    function configureGuildCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        bool nonMTMLiquidation
    ) external;

    /**
     * @dev Updates the zToken implementation for the Guild.
     * @param input The AssetToken (zTokenb) update parameters
     **/
    function updateAssetToken(ConfiguratorInputTypes.UpdateAssetTokenInput calldata input) external;

    /**
     * @notice Updates the dToken token implementation for the Guild.
     * @param input The liabilityToken update parameters
     **/
    function updateLiabilityToken(ConfiguratorInputTypes.UpdateLiabilityTokenInput calldata input) external;

    /**
     * @notice Pauses or unpauses all the protocol collaterals and perpetual debts. In the paused state all the protocol interactions
     * are suspended.
     * @param paused True if protocol needs to be paused, false otherwise
     **/
    function setGuildPause(bool paused) external;

    /**
     * @notice Updates notional price limits used during refinancing.
     * @dev Perpetual debt interest rates are proportional to 1/notionalPrice.
     * @param priceMin Minimum notional price to use for refinancing.
     * @param priceMax Maximum notional price to use for refinancing.
     **/
    function setPerpDebtNotionalPriceLimits(uint256 priceMax, uint256 priceMin) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {IGuild} from "./IGuild.sol";

/**
 * @title IInitializableAssetToken
 * @author Amorphous
 * @notice Interface for the initialize function on zToken
 **/
interface IInitializableAssetToken {
    /**
     * @dev Emitted when an aToken is initialized
     * @param guild The address of the associated guild
     * @param zTokenDecimals The decimals of the underlying
     * @param zTokenName The name of the zToken
     * @param zTokenSymbol The symbol of the zToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed guild,
        uint8 zTokenDecimals,
        string zTokenName,
        string zTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the zToken
     * @param guild The guild contract that is initializing this contract
     * @param zTokenDecimals The decimals of the zToken, same as the underlying asset's
     * @param zTokenName The name of the zToken
     * @param zTokenSymbol The symbol of the zToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IGuild guild,
        uint8 zTokenDecimals,
        string calldata zTokenName,
        string calldata zTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {IGuild} from "./IGuild.sol";

/**
 * @title IInitializableLiabilityToken
 * @author Amorphous
 * @notice Interface for the initialize function on dToken
 **/
interface IInitializableLiabilityToken {
    /**
     * @dev Emitted when an aToken is initialized
     * @param guild The address of the associated guild
     * @param dTokenDecimals The decimals of the underlying
     * @param dTokenName The name of the dToken
     * @param dTokenSymbol The symbol of the dToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed guild,
        uint8 dTokenDecimals,
        string dTokenName,
        string dTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the dToken
     * @param guild The guild contract that is initializing this contract
     * @param dTokenDecimals The decimals of the zToken, same as the underlying asset's
     * @param dTokenName The name of the zToken
     * @param dTokenSymbol The symbol of the zToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IGuild guild,
        uint8 dTokenDecimals,
        string calldata dTokenName,
        string calldata dTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {INotionalERC20} from "./INotionalERC20.sol";
import {IInitializableLiabilityToken} from "./IInitializableLiabilityToken.sol";
import {ICreditDelegation} from "./ICreditDelegation.sol";

interface ILiabilityToken is IERC20, INotionalERC20, IInitializableLiabilityToken, ICreditDelegation {
    /**
     * @dev Emitted when new stable debt is minted
     * @param user The address of the user who triggered the minting
     * @param onBehalfOf The recipient of stable debt tokens
     * @param amount The amount minted
     **/
    event Mint(address indexed user, address indexed onBehalfOf, uint256 amount);

    /**
     * @notice Mints liability token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount
    ) external;

    function burn(address account, uint256 amount) external;

    function updateNotionalFactor(uint256 multFactor) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";

/**
 * @dev Implementation of notional rebase functionality.
 *
 * Forms the basis of a notional ERC20 token, where the ERC20 interface is non-rebasing,
 * (ie, the quantities tracked by the ERC20 token are normalized), and here we create
 * functions that access the full 'rebased' quantities as a 'Notional' amount
 *
 **/
interface INotionalERC20 is IERC20 {
    event UpdateNotionalFactor(uint256 _value);

    function getNotionalFactor() external view returns (uint256); // @dev gets the Notional factor [ray]

    function totalNotionalSupply() external view returns (uint256);

    function balanceNotionalOf(address account) external view returns (uint256);

    function notionalToBase(uint256 amount) external view returns (uint256);

    function baseToNotional(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {VersionedInitializable} from "../libraries/upgradeability/VersionedInitializable.sol";
import {IGuildAddressesProvider} from "../../interfaces/IGuildAddressesProvider.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {ConfiguratorInputTypes} from "../libraries/types/ConfiguratorInputTypes.sol";
import {ConfiguratorLogic} from "../libraries/logic/ConfiguratorLogic.sol";
import {CollateralConfiguration} from "../libraries/configuration/CollateralConfiguration.sol";
import {PerpetualDebtConfiguration} from "../libraries/configuration/PerpetualDebtConfiguration.sol";
import {IGuildConfigurator} from "../../interfaces/IGuildConfigurator.sol";
import {IGuild} from "../../interfaces/IGuild.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";

/**
 * @title GuildConfigurator
 * @author Covenant Labs, inspired by AAVEv3
 * @dev Implements the configuration methods for the Covenant protocol
 **/
contract GuildConfigurator is VersionedInitializable, IGuildConfigurator {
    using PercentageMath for uint256;
    using CollateralConfiguration for DataTypes.CollateralConfigurationMap;
    using PerpetualDebtConfiguration for DataTypes.PerpDebtConfigurationMap;

    IGuildAddressesProvider internal _addressesProvider;
    IGuild internal _guild;

    /**
     * @dev Only guild admin can call functions marked by this modifier.
     **/
    modifier onlyGuildAdmin() {
        _onlyGuildAdmin();
        _;
    }

    /**
     * @dev Only emergency admin can call functions marked by this modifier.
     **/
    modifier onlyEmergencyAdmin() {
        _onlyEmergencyAdmin();
        _;
    }

    /**
     * @dev Only emergency or pool admin can call functions marked by this modifier.
     **/
    modifier onlyEmergencyOrGuildAdmin() {
        _onlyGuildOrEmergencyAdmin();
        _;
    }

    /**
     * @dev Only risk or Guild admin can call functions marked by this modifier.
     **/
    modifier onlyRiskOrGuildAdmins() {
        _onlyRiskOrGuildAdmins();
        _;
    }

    function _onlyGuildAdmin() internal view virtual {
        IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
        require(aclManager.isGuildAdmin(msg.sender), Errors.CALLER_NOT_GUILD_ADMIN);
    }

    function _onlyEmergencyAdmin() internal view {
        IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
        require(aclManager.isEmergencyAdmin(msg.sender), Errors.CALLER_NOT_EMERGENCY_ADMIN);
    }

    function _onlyGuildOrEmergencyAdmin() internal view {
        IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
        require(
            aclManager.isGuildAdmin(msg.sender) || aclManager.isEmergencyAdmin(msg.sender),
            Errors.CALLER_NOT_GUILD_OR_EMERGENCY_ADMIN
        );
    }

    function _onlyRiskOrGuildAdmins() internal view virtual {
        IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
        require(
            aclManager.isRiskAdmin(msg.sender) || aclManager.isGuildAdmin(msg.sender),
            Errors.CALLER_NOT_RISK_OR_GUILD_ADMIN
        );
    }

    uint256 public constant CONFIGURATOR_REVISION = 0x2;

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return CONFIGURATOR_REVISION;
    }

    /**
     * @dev Constructor
     */
    constructor() {}

    function initialize(IGuildAddressesProvider provider) public initializer {
        _addressesProvider = provider;
        _guild = IGuild(_addressesProvider.getGuild());
    }

    /// @inheritdoc IGuildConfigurator
    function initPerpetualDebt(ConfiguratorInputTypes.InitPerpetualDebtInput calldata input)
        external
        override
        onlyGuildAdmin
    {
        ConfiguratorLogic.executeInitPerpetualDebt(_guild, input);
    }

    /// @inheritdoc IGuildConfigurator
    function updateAssetToken(ConfiguratorInputTypes.UpdateAssetTokenInput calldata input)
        external
        override
        onlyGuildAdmin
    {
        ConfiguratorLogic.executeUpdateAssetToken(_guild, input);
    }

    /// @inheritdoc IGuildConfigurator
    function updateLiabilityToken(ConfiguratorInputTypes.UpdateLiabilityTokenInput calldata input)
        external
        override
        onlyGuildAdmin
    {
        ConfiguratorLogic.executeUpdateLiabilityToken(_guild, input);
    }

    /// @inheritdoc IGuildConfigurator
    function initCollaterals(ConfiguratorInputTypes.InitCollateralInput[] calldata input)
        external
        override
        onlyGuildAdmin
    {
        IGuild cachedGuild = _guild;
        for (uint256 i = 0; i < input.length; i++) {
            ConfiguratorLogic.executeInitCollateral(cachedGuild, input[i]);
        }
    }

    /// @inheritdoc IGuildConfigurator
    function dropCollateral(address asset) external override onlyGuildAdmin {
        emit CollateralDropped(asset);
        _guild.dropCollateral(asset);
    }

    /// @inheritdoc IGuildConfigurator
    // @dev - WARNING, if setting nonMTMLiquidation to True on a live Guild, existing debt will remain MTM
    // (till borrower has taken out a new loan after this flag has been set)
    function configureGuildCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        bool nonMTMLiquidation
    ) external override onlyRiskOrGuildAdmins {
        //validation of the parameters: the LTV can
        //only be lower or equal than the liquidation threshold
        //(otherwise a loan against the asset would cause instantaneous liquidation)
        require(ltv <= liquidationThreshold, Errors.INVALID_COLLATERAL_PARAMS);

        DataTypes.CollateralConfigurationMap memory currentConfig = _guild.getCollateralConfiguration(asset);

        if (liquidationThreshold != 0) {
            //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
            //collateral than needed to cover the debt
            require(liquidationBonus > PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_COLLATERAL_PARAMS);

            //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
            //a loan is taken there is enough collateral available to cover the liquidation bonus
            require(
                liquidationThreshold.percentMul(liquidationBonus) <= PercentageMath.PERCENTAGE_FACTOR,
                Errors.INVALID_COLLATERAL_PARAMS
            );
        } else {
            require(liquidationBonus == 0, Errors.INVALID_COLLATERAL_PARAMS);
            //if the liquidation threshold is being set to 0,
            // the collateral is being disabled as collateral.
        }

        currentConfig.setLtv(ltv);
        currentConfig.setLiquidationThreshold(liquidationThreshold);
        currentConfig.setLiquidationBonus(liquidationBonus);
        currentConfig.setNonMTMLiquidationFlag(nonMTMLiquidation);

        emit CollateralConfigurationChanged(asset, ltv, liquidationThreshold, liquidationBonus, nonMTMLiquidation);

        _guild.setConfiguration(asset, currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setCollateralActive(address asset, bool active) external override onlyGuildAdmin {
        DataTypes.CollateralConfigurationMap memory currentConfig = _guild.getCollateralConfiguration(asset);
        currentConfig.setActive(active);
        emit CollateralActive(asset, active);
        _guild.setConfiguration(asset, currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setCollateralFrozen(address asset, bool freeze) external override onlyGuildAdmin {
        DataTypes.CollateralConfigurationMap memory currentConfig = _guild.getCollateralConfiguration(asset);
        currentConfig.setFrozen(freeze);
        emit CollateralFrozen(asset, freeze);
        _guild.setConfiguration(asset, currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setCollateralPause(address asset, bool paused) public override onlyEmergencyOrGuildAdmin {
        DataTypes.CollateralConfigurationMap memory currentConfig = _guild.getCollateralConfiguration(asset);
        currentConfig.setPaused(paused);
        emit CollateralPaused(asset, paused);
        _guild.setConfiguration(asset, currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setSupplyCap(address asset, uint256 newSupplyCap) external override onlyRiskOrGuildAdmins {
        DataTypes.CollateralConfigurationMap memory currentConfig = _guild.getCollateralConfiguration(asset);
        uint256 oldSupplyCap = currentConfig.getSupplyCap();
        currentConfig.setSupplyCap(newSupplyCap);
        emit SupplyCapChanged(asset, oldSupplyCap, newSupplyCap);
        _guild.setConfiguration(asset, currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setUserSupplyCap(address asset, uint256 newSupplyCap) external override onlyRiskOrGuildAdmins {
        DataTypes.CollateralConfigurationMap memory currentConfig = _guild.getCollateralConfiguration(asset);
        uint256 oldSupplyCap = currentConfig.getUserSupplyCap();
        currentConfig.setUserSupplyCap(newSupplyCap);
        emit UserSupplyCapChanged(asset, oldSupplyCap, newSupplyCap);
        _guild.setConfiguration(asset, currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setProtocolDistributionFee(uint256 newFee) external override onlyRiskOrGuildAdmins {
        require(newFee <= PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_PROTOCOL_DISTRIBUTION_FEE);
        DataTypes.PerpDebtConfigurationMap memory currentConfig = _guild.getPerpDebtConfiguration();
        uint256 oldFee = currentConfig.getProtocolServiceFee();
        currentConfig.setProtocolDistributionFee(newFee);
        emit ProtocolDistributionFeeChanged(oldFee, newFee);
        _guild.setPerpDebtConfiguration(currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setProtocolServiceFee(uint256 newFee) external override onlyRiskOrGuildAdmins {
        require(newFee <= PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_PROTOCOL_SERVICE_FEE);
        DataTypes.PerpDebtConfigurationMap memory currentConfig = _guild.getPerpDebtConfiguration();
        uint256 oldFee = currentConfig.getProtocolServiceFee();
        currentConfig.setProtocolServiceFee(newFee);
        emit ProtocolServiceFeeChanged(oldFee, newFee);
        _guild.setPerpDebtConfiguration(currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setProtocolMintFee(uint256 newFee) external override onlyRiskOrGuildAdmins {
        require(newFee <= PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_PROTOCOL_MINT_FEE);
        DataTypes.PerpDebtConfigurationMap memory currentConfig = _guild.getPerpDebtConfiguration();
        uint256 oldFee = currentConfig.getProtocolMintFee();
        currentConfig.setProtocolMintFee(newFee);
        emit ProtocolMintFeeChanged(oldFee, newFee);
        _guild.setPerpDebtConfiguration(currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setProtocolSwapFee(uint256 newFee) external override onlyRiskOrGuildAdmins {
        require(newFee <= PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_PROTOCOL_SWAP_FEE);
        DataTypes.PerpDebtConfigurationMap memory currentConfig = _guild.getPerpDebtConfiguration();
        uint256 oldFee = currentConfig.getProtocolSwapFee();
        currentConfig.setProtocolSwapFee(newFee);
        emit ProtocolSwapFeeChanged(oldFee, newFee);
        _guild.setPerpDebtConfiguration(currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setProtocolDistributionFeeAddress(address newAddress) external override onlyRiskOrGuildAdmins {
        address oldAddress = _guild.getPerpetualDebt().protocolDistributionFeeAddress;
        emit ProtocolDistributionFeeAddressChanged(oldAddress, newAddress);
        _guild.setProtocolDistributionFeeAddress(newAddress);
    }

    /// @inheritdoc IGuildConfigurator
    function setProtocolServiceFeeAddress(address newAddress) external override onlyRiskOrGuildAdmins {
        address oldAddress = _guild.getPerpetualDebt().protocolServiceFeeAddress;
        emit ProtocolServiceFeeAddressChanged(oldAddress, newAddress);
        _guild.setProtocolServiceFeeAddress(newAddress);
    }

    /// @inheritdoc IGuildConfigurator
    function setProtocolMintFeeAddress(address newAddress) external override onlyRiskOrGuildAdmins {
        address oldAddress = _guild.getPerpetualDebt().protocolMintFeeAddress;
        emit ProtocolMintFeeAddressChanged(oldAddress, newAddress);
        _guild.setProtocolMintFeeAddress(newAddress);
    }

    /// @inheritdoc IGuildConfigurator
    function setProtocolSwapFeeAddress(address newAddress) external override onlyRiskOrGuildAdmins {
        address oldAddress = _guild.getPerpetualDebt().protocolSwapFeeAddress;
        emit ProtocolSwapFeeAddressChanged(oldAddress, newAddress);
        _guild.setProtocolSwapFeeAddress(newAddress);
    }

    /// @inheritdoc IGuildConfigurator
    function setPerpDebtPause(bool paused) public override onlyEmergencyOrGuildAdmin {
        DataTypes.PerpDebtConfigurationMap memory currentConfig = _guild.getPerpDebtConfiguration();
        currentConfig.setPaused(paused);
        emit PerpDebtPaused(paused);
        // @dev - calling refinance updates interest till paused, and rolls forward till unpaused
        _guild.refinance();
        _guild.setPerpDebtConfiguration(currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setPerpDebtFrozen(bool frozen) external override onlyGuildAdmin {
        DataTypes.PerpDebtConfigurationMap memory currentConfig = _guild.getPerpDebtConfiguration();
        currentConfig.setFrozen(frozen);
        emit PerpDebtFrozen(frozen);
        // @dev - calling refinance updates interest till frozen, and rolls forward till unfrozen
        _guild.refinance();
        _guild.setPerpDebtConfiguration(currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setMintCap(uint256 newMintCap) external override onlyRiskOrGuildAdmins {
        DataTypes.PerpDebtConfigurationMap memory currentConfig = _guild.getPerpDebtConfiguration();
        uint256 oldMintCap = currentConfig.getMintCap();
        currentConfig.setMintCap(newMintCap);
        emit MintCapChanged(oldMintCap, newMintCap);
        _guild.setPerpDebtConfiguration(currentConfig);
    }

    /// @inheritdoc IGuildConfigurator
    function setGuildPause(bool paused) external override onlyEmergencyAdmin {
        //Pause collaterals
        address[] memory collaterals = _guild.getCollateralsList();
        for (uint256 i = 0; i < collaterals.length; i++) {
            if (collaterals[i] != address(0)) {
                setCollateralPause(collaterals[i], paused);
            }
        }

        //Pause perpetual debt
        setPerpDebtPause(paused);
    }

    /// @inheritdoc IGuildConfigurator
    function setPerpDebtNotionalPriceLimits(uint256 priceMax, uint256 priceMin) external override onlyGuildAdmin {
        emit PerpDebtLimitsChanged(priceMax, priceMin);
        _guild.setPerpDebtNotionalPriceLimits(priceMax, priceMin);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

//bit 0-15: LTV
//bit 16-31: Liq. threshold
//bit 32-47: Liq. bonus
//bit 48-55: Decimals
//bit 56: collateral is active
//bit 57-115: reserved
//bit 116-151: supply cap in whole tokens, supplyCap == 0 => no cap
//bit 152-167: liquidation protocol fee
//bit 168-255: reserved

/**
 * @title CollateralConfiguration library
 * @author Amorphous, inspired by AAVE v3
 * @notice Handles the collateral configuration (not storage optimized)
 */
library CollateralConfiguration {
    uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant NON_MTM_LIQUIDATION_MASK =       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant USER_SUPPLY_CAP_MASK =           0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 internal constant COLLATERAL_DECIMALS_START_BIT_POSITION = 48;
    uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 internal constant IS_NON_MTM_LIQUIDATION_START_BIT_POSITION = 58;
    uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;

    uint256 internal constant USER_SUPPLY_CAP_START_BIT_POSITION = 80;
    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;

    uint256 internal constant MAX_VALID_LTV = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 internal constant MAX_VALID_DECIMALS = 255;
    uint256 internal constant MAX_VALID_USER_SUPPLY_CAP = 68719476735;
    uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;

    uint16 public constant MAX_COLLATERALS_COUNT = 128;

    /**
     * @notice Sets the Loan to Value of the collateral
     * @param self The collateral configuration
     * @param ltv The new ltv
     **/
    function setLtv(DataTypes.CollateralConfigurationMap memory self, uint256 ltv) internal pure {
        require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @notice Gets the Loan to Value of the collateral
     * @param self The collateral configuration
     * @return The loan to value
     **/
    function getLtv(DataTypes.CollateralConfigurationMap memory self) internal pure returns (uint256) {
        return self.data & ~LTV_MASK;
    }

    /**
     * @notice Sets the liquidation threshold of the collateral
     * @param self The collateral configuration
     * @param threshold The new liquidation threshold
     **/
    function setLiquidationThreshold(DataTypes.CollateralConfigurationMap memory self, uint256 threshold)
        internal
        pure
    {
        require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);

        self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation threshold of the collateral
     * @param self The collateral configuration
     * @return The liquidation threshold
     **/
    function getLiquidationThreshold(DataTypes.CollateralConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation bonus of the collateral
     * @param self The collateral configuration
     * @param bonus The new liquidation bonus
     **/
    function setLiquidationBonus(DataTypes.CollateralConfigurationMap memory self, uint256 bonus) internal pure {
        require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

        self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation bonus of the collateral
     * @param self The collateral configuration
     * @return The liquidation bonus
     **/
    function getLiquidationBonus(DataTypes.CollateralConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the decimals of the underlying asset of the collateral
     * @param self The collateral configuration
     * @param decimals The decimals
     **/
    function setDecimals(DataTypes.CollateralConfigurationMap memory self, uint256 decimals) internal pure {
        require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

        self.data = (self.data & DECIMALS_MASK) | (decimals << COLLATERAL_DECIMALS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the decimals of the underlying asset of the collateral
     * @param self The collateral configuration
     * @return The decimals of the asset
     **/
    function getDecimals(DataTypes.CollateralConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~DECIMALS_MASK) >> COLLATERAL_DECIMALS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the active state of the collateral
     * @param self The collateral configuration
     * @param active The active state
     **/
    function setActive(DataTypes.CollateralConfigurationMap memory self, bool active) internal pure {
        self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @notice Gets the active state of the collateral
     * @param self The collateral configuration
     * @return The active state
     **/
    function getActive(DataTypes.CollateralConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @notice Sets the frozen state of the collateral
     * @param self The collateral configuration
     * @param frozen The frozen state
     **/
    function setFrozen(DataTypes.CollateralConfigurationMap memory self, bool frozen) internal pure {
        self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @notice Gets the frozen state of the collateral
     * @param self The collateral configuration
     * @return The frozen state
     **/
    function getFrozen(DataTypes.CollateralConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @notice Sets whether the last collateral price during debt mint should be used for liquidations
     * @param self The collateral configuration
     * @param useLastMintPrice whether to use last collateral price during debt mint for liquidations
     **/
    function setNonMTMLiquidationFlag(DataTypes.CollateralConfigurationMap memory self, bool useLastMintPrice)
        internal
        pure
    {
        self.data =
            (self.data & NON_MTM_LIQUIDATION_MASK) |
            (uint256(useLastMintPrice ? 1 : 0) << IS_NON_MTM_LIQUIDATION_START_BIT_POSITION);
    }

    /**
     * @notice Gets whether the last collateral price during debt mint should be used for liquidations
     * @param self The collateral configuration
     * @return The Non-MTM state
     **/
    function getNonMTMLiquidationFlag(DataTypes.CollateralConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~NON_MTM_LIQUIDATION_MASK) != 0;
    }

    /**
     * @notice Sets the paused state of the collateral
     * @param self The collateral configuration
     * @param paused The paused state
     **/
    function setPaused(DataTypes.CollateralConfigurationMap memory self, bool paused) internal pure {
        self.data = (self.data & PAUSED_MASK) | (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the paused state of the collateral
     * @param self The collateral configuration
     * @return The paused state
     **/
    function getPaused(DataTypes.CollateralConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~PAUSED_MASK) != 0;
    }

    /**
     * @notice Sets the supply cap of the collateral
     * @param self The collateral configuration
     * @param supplyCap The supply cap
     * @dev supplyCap at guild level encoded with 0 decimal places (e.g, 1 -> 1 token in collateral's own unit)
     **/
    function setSupplyCap(DataTypes.CollateralConfigurationMap memory self, uint256 supplyCap) internal pure {
        require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

        self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the supply cap of the collateral
     * @param self The collateral configuration
     * @return The supply cap
     * @dev supplyCap at guild level encoded with 0 decimal places (e.g, 1 -> 1 token in collateral's own unit)
     **/
    function getSupplyCap(DataTypes.CollateralConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the user supply cap of the collateral (wallet level)
     * @param self The collateral configuration
     * @param supplyCap The supply cap
     * @dev supplyCap at user level encoded with 2 decimal places (e.g, 100 -> 1 token in collateral's own unit)
     **/
    function setUserSupplyCap(DataTypes.CollateralConfigurationMap memory self, uint256 supplyCap) internal pure {
        require(supplyCap <= MAX_VALID_USER_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

        self.data = (self.data & USER_SUPPLY_CAP_MASK) | (supplyCap << USER_SUPPLY_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the user supply cap of the collateral (wallet level)
     * @param self The collateral configuration
     * @return The supply cap
     * @dev supplyCap at user level encoded with 2 decimal places (e.g, 100 -> 1 token in collateral's own unit)
     **/
    function getUserSupplyCap(DataTypes.CollateralConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~USER_SUPPLY_CAP_MASK) >> USER_SUPPLY_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Gets the configuration flags of the collateral
     * @param self The collateral configuration
     * @return The state flag representing active
     * @return The state flag representing frozen
     * @return The state flag representing paused
     **/
    function getFlags(DataTypes.CollateralConfigurationMap memory self)
        internal
        pure
        returns (
            bool,
            bool,
            bool
        )
    {
        uint256 dataLocal = self.data;

        return ((dataLocal & ~ACTIVE_MASK) != 0, (dataLocal & ~FROZEN_MASK) != 0, (dataLocal & ~PAUSED_MASK) != 0);
    }

    /**
     * @notice Gets the configuration parameters of the collateral from storage
     * @param self The collateral configuration
     * @return The state param representing ltv
     * @return The state param representing liquidation threshold
     * @return The state param representing liquidation bonus
     * @return The state param representing collateral decimals
     * @return The state param representing whether liquidations use collateral price from last debt mint
     **/
    function getParams(DataTypes.CollateralConfigurationMap memory self)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        uint256 dataLocal = self.data;

        return (
            dataLocal & ~LTV_MASK,
            (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
            (dataLocal & ~DECIMALS_MASK) >> COLLATERAL_DECIMALS_START_BIT_POSITION,
            (dataLocal & ~NON_MTM_LIQUIDATION_MASK) != 0
        );
    }

    /**
     * @notice Gets the caps parameters of the collateral from storage
     * @param self The collateral configuration
     * @return The state param representing supply cap.
     * @return The state param representing user supply cap.
     **/
    function getCaps(DataTypes.CollateralConfigurationMap memory self) internal pure returns (uint256, uint256) {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION,
            (dataLocal & ~USER_SUPPLY_CAP_MASK) >> USER_SUPPLY_CAP_START_BIT_POSITION
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

//bit 0: perpetual debt is paused (no mint, no burn/distribute, no liquidate, no refinance)
//bit 1: perpetual debt is frozen (no mint, yes burn/distribute, yes liquidate, yes refinance)
//bit 2-37: mint cap in whole tokens, mintCap ==0 => no cap
//bit 38-255: unused

/**
 * @title Perpetual Debt Configuration library
 * @author Covenant Labs, inspired by AAVE v3
 * @notice Handles the perpetual debt configuration (not storage optimized)
 */
library PerpetualDebtConfiguration {
    uint256 internal constant PAUSED_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE; // prettier-ignore
    uint256 internal constant FROZEN_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD; // prettier-ignore
    uint256 internal constant MINT_CAP_MASK =               0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC000000003; // prettier-ignore
    uint256 internal constant PROTOCOL_SERVICE_FEE_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PROTOCOL_MINT_FEE_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PROTOCOL_DIST_FEE_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PROTOCOL_SWAP_FEE_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the PAUSED flag, the start bit is 0, hence no bitshifting is needed
    uint256 internal constant IS_FROZEN_MASK_START_BIT_POSITION = 1;
    uint256 internal constant MINT_CAP_START_BIT_POSITION = 2;
    uint256 internal constant PROTOCOL_SERVICE_FEE_START_BIT_POSITION = 48;
    uint256 internal constant PROTOCOL_MINT_FEE_START_BIT_POSITION = 64;
    uint256 internal constant PROTOCOL_DIST_FEE_START_BIT_POSITION = 80;
    uint256 internal constant PROTOCOL_SWAP_FEE_START_BIT_POSITION = 96;

    uint256 internal constant MAX_VALID_MINT_CAP = 68719476735;
    uint256 internal constant MAX_VALID_PROTOCOL_SERVICE_FEE = 65535;
    uint256 internal constant MAX_VALID_PROTOCOL_MINT_FEE = 65535;
    uint256 internal constant MAX_VALID_PROTOCOL_DIST_FEE = 65535;
    uint256 internal constant MAX_VALID_PROTOCOL_SWAP_FEE = 65535;

    /**
     * @notice Sets the paused state of the perpetual debt
     * @param self The perpetual debt configuration
     * @param paused The paused state
     **/
    function setPaused(DataTypes.PerpDebtConfigurationMap memory self, bool paused) internal pure {
        self.data = (self.data & PAUSED_MASK) | (uint256(paused ? 1 : 0));
    }

    /**
     * @notice Gets the paused state of the perpetual debt
     * @param self The perpetual debt configuration
     * @return The paused state
     **/
    function getPaused(DataTypes.PerpDebtConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~PAUSED_MASK) != 0;
    }

    /**
     * @notice Sets the active state of the perpetual debt
     * @param self The perpetual debt configuration
     * @param frozen The active state
     **/
    function setFrozen(DataTypes.PerpDebtConfigurationMap memory self, bool frozen) internal pure {
        self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_MASK_START_BIT_POSITION);
    }

    /**
     * @notice Gets the fozen state of the perpetual debt
     * @param self The perpetual debt configuration
     * @return The frozen state
     **/
    function getFrozen(DataTypes.PerpDebtConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @notice Sets the supply cap of the perpetual debt
     * @param self The perpetual debt configuration
     * @param mintCap The mint cap
     **/
    function setMintCap(DataTypes.PerpDebtConfigurationMap memory self, uint256 mintCap) internal pure {
        require(mintCap <= MAX_VALID_MINT_CAP, Errors.INVALID_MINT_CAP);

        self.data = (self.data & MINT_CAP_MASK) | (mintCap << MINT_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the mint cap of the perpetual debt
     * @param self The perpetual debt configuration
     * @return The mint cap
     **/
    function getMintCap(DataTypes.PerpDebtConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~MINT_CAP_MASK) >> MINT_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the protocol service fee of the perpetual debt
     * @param self The perpetual debt configuration
     * @param protocolServiceFee The protocol service fee
     **/
    function setProtocolServiceFee(DataTypes.PerpDebtConfigurationMap memory self, uint256 protocolServiceFee)
        internal
        pure
    {
        require(protocolServiceFee <= MAX_VALID_PROTOCOL_SERVICE_FEE, Errors.INVALID_PROTOCOL_SERVICE_FEE);

        self.data =
            (self.data & PROTOCOL_SERVICE_FEE_MASK) |
            (protocolServiceFee << PROTOCOL_SERVICE_FEE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the protocol service fee
     * @param self The perpetual debt configuration
     * @return The protocol service fee
     **/
    function getProtocolServiceFee(DataTypes.PerpDebtConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~PROTOCOL_SERVICE_FEE_MASK) >> PROTOCOL_SERVICE_FEE_START_BIT_POSITION;
    }

    /**
     * @notice Sets the protocol mint fee of the perpetual debt
     * @param self The perpetual debt configuration
     * @param protocolMintFee The protocol mint fee
     **/
    function setProtocolMintFee(DataTypes.PerpDebtConfigurationMap memory self, uint256 protocolMintFee) internal pure {
        require(protocolMintFee <= MAX_VALID_PROTOCOL_MINT_FEE, Errors.INVALID_PROTOCOL_MINT_FEE);

        self.data = (self.data & PROTOCOL_MINT_FEE_MASK) | (protocolMintFee << PROTOCOL_MINT_FEE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the protocol mint fee
     * @param self The perpetual debt configuration
     * @return The protocol mint fee
     **/
    function getProtocolMintFee(DataTypes.PerpDebtConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~PROTOCOL_MINT_FEE_MASK) >> PROTOCOL_MINT_FEE_START_BIT_POSITION;
    }

    /**
     * @notice Sets the protocol distribution fee of the perpetual debt
     * @param self The perpetual debt configuration
     * @param protocolDistFee The protocol distribution fee
     **/
    function setProtocolDistributionFee(DataTypes.PerpDebtConfigurationMap memory self, uint256 protocolDistFee)
        internal
        pure
    {
        require(protocolDistFee <= MAX_VALID_PROTOCOL_DIST_FEE, Errors.INVALID_PROTOCOL_DISTRIBUTION_FEE);

        self.data = (self.data & PROTOCOL_DIST_FEE_MASK) | (protocolDistFee << PROTOCOL_DIST_FEE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the protocol distribution fee of the perpetual debt
     * @param self The perpetual debt configuration
     * @return The protocol distribution fee
     **/
    function getProtocolDistributionFee(DataTypes.PerpDebtConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return (self.data & ~PROTOCOL_DIST_FEE_MASK) >> PROTOCOL_DIST_FEE_START_BIT_POSITION;
    }

    /**
     * @notice Sets the protocol swap fee of the perpetual debt
     * @param self The perpetual debt configuration
     * @param protocolSwapFee The protocol swap fee
     **/
    function setProtocolSwapFee(DataTypes.PerpDebtConfigurationMap memory self, uint256 protocolSwapFee) internal pure {
        require(protocolSwapFee <= MAX_VALID_PROTOCOL_SWAP_FEE, Errors.INVALID_PROTOCOL_SWAP_FEE);

        self.data = (self.data & PROTOCOL_SWAP_FEE_MASK) | (protocolSwapFee << PROTOCOL_SWAP_FEE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the protocol swap fee of the perpetual debt
     * @param self The perpetual debt configuration
     * @return The protocol swap fee
     **/
    function getProtocolSwapFee(DataTypes.PerpDebtConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~PROTOCOL_SWAP_FEE_MASK) >> PROTOCOL_SWAP_FEE_START_BIT_POSITION;
    }

    /**
     * @notice Gets the configuration flags of the perpetual debt
     * @param self The perpetual debt configuration
     * @return The state flag representing frozen
     * @return The state flag representing paused
     **/
    function getFlags(DataTypes.PerpDebtConfigurationMap memory self) internal pure returns (bool, bool) {
        uint256 dataLocal = self.data;

        return ((dataLocal & ~FROZEN_MASK) != 0, (dataLocal & ~PAUSED_MASK) != 0);
    }

    /**
     * @notice Gets the caps parameters of the perpetual debt from storage
     * @param self The perpetual debt configuration
     * @return The state param representing mint cap.
     **/
    function getCaps(DataTypes.PerpDebtConfigurationMap memory self) internal pure returns (uint256) {
        uint256 dataLocal = self.data;

        return ((dataLocal & ~MINT_CAP_MASK) >> MINT_CAP_START_BIT_POSITION);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @title Errors library
 * @author Covenant Labs
 * @notice Defines the error messages emitted by the different contracts of the Covenant protocol
 */
library Errors {
    string public constant LOCKED = "0"; // 'Guild is locked'
    string public constant NOT_CONTRACT = "1"; // 'Address is not a contract'
    string public constant AMOUNT_NEED_TO_BE_GREATER = "2"; // 'A greater amount needed for action'
    string public constant TRANSFER_FAIL = "3"; // 'Failed to transfer'
    string public constant NOT_APPROVED = "4"; // 'Not approved'
    string public constant NOT_ENOUGH_BALANCE = "5"; // 'Not enough balance'
    string public constant ASSET_NEEDS_TO_BE_APPROVED = "6"; // 'Asset needs to be whitelisted'
    string public constant OPERATION_NOT_SUPPORTED = "7"; // 'Operation not supported'
    string public constant OPERATION_NOT_AUTHORIZED = "8"; // 'Operation not authorized, not enough permissions for the operation'
    string public constant REFINANCE_INVALID_TIMESTAMP = "9"; // 'The current block has a timestamp that is older vs that last refinance'
    string public constant NOT_ENOUGH_COLLATERAL = "10"; // 'Not enough collateral'
    string public constant AMOUNT_NEED_TO_MORE_THAN_ZERO = "11"; // '"Your asset amount must be greater then you are trying to deposit"'
    string public constant CANNOT_BURN_MORE_THAN_CURRENT_DEBT = "12"; // "Amount exceeds current debt level"
    string public constant UNHEALTHY_POSITION = "13"; // Users position is currently higher than liquidation threshold
    string public constant CANNOT_LIQUIDATE_HEALTHY = "14"; // Cannot liqudate healthy users position
    string public constant WITHDRAWAL_AMOUNT_EXCEEDS_AVAILABLE = "15"; // Amount exceeds max withdrawable amount
    string public constant HELPER_INSUFFICIENT_FUNDS = "16"; // Internal error, insufficient funds to place on dex as requested
    string public constant AMOUNT_NEEDS_TO_EQUAL_COLLATERAL_VALUE = "17"; // Amount needs to be the same to exchange money for collateral
    string public constant AMOUNT_NEEDS_TO_LOWER_THAN_DEBT = "18"; // Amount needs to be lower than current debt level
    string public constant NOT_ENOUGH_Z_TOKENS = "19"; // "Not enough zTokens in account"
    string public constant PRICE_LIMIT_OUT_OF_BOUNDS = "20"; // "PerpetualDebt.sol - price limit initialization out of bounds"
    string public constant PRICE_LIMIT_ERROR = "21"; // "PerpetualDebt.sol - price limit min larger than max"
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "22"; // "ACLManager.sol - cannot set a 0x0 address as admin"
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "23"; // "GuildAddressesProviderRegistry.sol - cannot set ID 0"
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "24"; // 'GuildAddressesProviderRegistry.sol - Guild addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER = "25"; // 'The address of the guild addresses provider is invalid'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "26"; // 'GuildAddressesProviderRegistry.sol - Reserve has already been added to collateral list'
    string public constant CALLER_NOT_GUILD_ADMIN = "27"; // 'The caller of the function is not a guild admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "28"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_GUILD_OR_EMERGENCY_ADMIN = "29"; // 'The caller of the function is not a guild or emergency admin'
    string public constant CALLER_NOT_RISK_OR_GUILD_ADMIN = "30"; // 'The caller of the function is not a risk or guild admin'
    string public constant TRANSFER_INVALID_SENDER = "31"; // 'ERC20: Cannot send from address 0'
    string public constant TRANSFER_INVALID_RECEIVER = "32"; // 'ERC20: Cannot send to address 0'
    string public constant CALLER_MUST_BE_GUILD = "33"; // 'The caller of the function must be the guild'
    string public constant GUILD_ADDRESSES_DO_NOT_MATCH = "34"; // 'Incorrect Guild address when initializing token'
    string public constant PERPETUAL_DEBT_ALREADY_INITIALIZED = "35"; // 'Perpetual Debt structure already initialized'
    string public constant DEX_ORACLE_ALREADY_INITIALIZED = "36"; // 'Dex Oracle structure already initialized'
    string public constant DEX_ORACLE_POOL_NOT_INITIALIZED = "37"; // 'Dex pool should be initialized before Dex oracle'
    string public constant CALLER_NOT_GUILD_CONFIGURATOR = "38"; // 'The caller of the function is not the guild configurator contract'
    string public constant COLLATERAL_ALREADY_ADDED = "39"; // 'Collateral has already been added to collateral list'
    string public constant NO_MORE_COLLATERALS_ALLOWED = "40"; // 'Maximum amount of collaterals in the guild reached'
    string public constant INVALID_LTV = "41"; // 'Invalid ltv parameter for the collateral'
    string public constant INVALID_LIQ_THRESHOLD = "42"; // 'Invalid liquidity threshold parameter for the collateral'
    string public constant INVALID_LIQ_BONUS = "43"; // 'Invalid liquidity bonus parameter for the collateral'
    string public constant INVALID_DECIMALS = "44"; // 'Invalid decimals parameter of the underlying asset of the collateral'
    string public constant INVALID_SUPPLY_CAP = "45"; // 'Invalid supply cap for the collateral'
    string public constant INVALID_PROTOCOL_DISTRIBUTION_FEE = "46"; // 'Invalid protocol distribution fee for the perpetual debt'
    string public constant ZERO_ADDRESS_NOT_VALID = "47"; // 'Zero address not valid'
    string public constant COLLATERAL_NOT_LISTED = "48"; // 'Collateral is not listed (not initialized or has been dropped)'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "49"; // 'The collateral balance is 0'
    string public constant LTV_VALIDATION_FAILED = "50"; // 'Ltv validation failed'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "51"; // 'Health factor is lower than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "52"; // 'There is not enough collateral to cover a new borrow'
    string public constant INVALID_COLLATERAL_PARAMS = "53"; //'Invalid risk parameters for the collateral'
    string public constant INVALID_AMOUNT = "54"; // 'Amount must be greater than 0'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "55"; //'User cannot withdraw more than the available balance'
    string public constant COLLATERAL_INACTIVE = "56"; //'Action requires an active collateral'
    string public constant SUPPLY_CAP_EXCEEDED = "57"; // 'Supply cap is exceeded'
    string public constant ACL_MANAGER_NOT_SET = "58"; // 'The ACL Manager has not been set for the addresses provider'
    string public constant ARRAY_SIZE_MISMATCH = "59"; // 'The arrays are of different sizes'
    string public constant DEX_POOL_DOES_NOT_CONTAIN_ASSET_PAIR = "60"; // 'The dex pool does not contain pricing info for token pair'
    string public constant ASSET_NOT_TRACKED_IN_ORACLE = "61"; // 'The asset is not tracked by the pricing oracle'
    string public constant INVALID_MINT_CAP = "62"; //  'Invalid mint cap for the perpetual debt'
    string public constant DEBT_PAUSED = "63"; //  'Action requires a non-paused debt'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "64"; // 'Action requires health factor to be below liquidation threshold'
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = "65"; // 'The collateral chosen cannot be liquidated'
    string public constant USER_HAS_NO_DEBT = "66"; // 'User has no debt to be liquidated'
    string public constant INSUFFICIENT_CREDIT_DELEGATION = "67"; //  'Insufficient credit delegation to 3rd party borrower'
    string public constant INSUFFICIENT_TOKENIN_FOR_TARGET_TOKENOUT = "68"; //  'Insufficient tokenIn to swap for target tokenOut value'
    string public constant COLLATERAL_FROZEN = "69"; // 'Action cannot be performed because the collateral is frozen'
    string public constant COLLATERAL_PAUSED = "70"; // 'Action cannot be performed because the collateral is paused'
    string public constant PERPETUAL_DEBT_FROZEN = "71"; // 'Action cannot be performed because the perpetual debt is frozen'
    string public constant PERPETUAL_DEBT_PAUSED = "72"; // 'Action cannot be performed because the perpetual debt is paused'
    string public constant TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE = "73"; // 'Account does not have sufficient allowance to transfer on behalf of other account'
    string public constant NEGATIVE_ALLOWANCE_NOT_ALLOWED = "74"; // 'Cannot allocate negative value for allowances'
    string public constant INSUFFICIENT_BALANCE_TO_BURN = "75"; // 'Cannot burn more than amount in balance'
    string public constant TRANSFER_EXCEEDS_BALANCE = "76"; // 'ERC20: Transfer amount exceeds balance'
    string public constant PERPETUAL_DEBT_CAP_EXCEEDED = "77"; // 'Perpetual debt cap is exceeded'
    string public constant NEGATIVE_DELEGATION_NOT_ALLOWED = "78"; // 'Cannot allocate negative value for delegation allowances'
    string public constant ORACLE_LOOKBACKPERIOD_IS_ZERO = "79"; // 'Collateral oracle should have lookback period greater than 0'
    string public constant ORACLE_CARDINALITY_IS_ZERO = "80"; // 'Collateral oracle should have pool cardinality greater than 0'
    string public constant ORACLE_CARDINALITY_MONOTONICALLY_INCREASES = "81"; // The cardinality of the oracle is monotonically increasing and cannot bet lowered
    string public constant ORACLE_ASSET_MISMATCH = "82"; // Asset in oracle does not match proxy asset address
    string public constant ORACLE_BASE_CURRENCY_MISMATCH = "83"; // Base currency in oracle does not match proxy base currency address
    string public constant NO_ORACLE_PROXY_PRICE_SOURCE = "84"; // Oracle proxy does not have a price source
    string public constant CANNOT_BE_ZERO = "85"; // The value cannot be 0
    string public constant REQUIRES_OVERRIDE = "86"; // Function requires override
    string public constant GUILD_MISMATCH = "87"; // Function requires override
    string public constant ORACLE_PROXY_TOKENS_NOT_SET_PROPERLY = "88"; // Function requires override
    string public constant POSITIVE_COLLATERAL_BALANCE = "89"; // Cannot only perform action if guild balance is positive
    string public constant INVALID_ROLE = "90"; // Role exceeds MAX_LIMIT
    string public constant MAX_NUM_ROLES_EXCEEDED = "91"; // Role can't exceed MAX_NUM_OF_ROLES
    string public constant INVALID_PROTOCOL_SERVICE_FEE = "92"; // Protocol service fee larger than max allowed
    string public constant INVALID_PROTOCOL_MINT_FEE = "93"; // Protocol mint fee larger than max allowed
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "94"; // PriceOracleSentinel check failed
    string public constant LOOKBACK_PERIOD_IS_NOT_ZERO = "95"; // lookback period must be 0
    string public constant LOOKBACK_PERIOD_END_LT_START = "96"; // lookbackPeriodEnd can't be less than lookbackPeriodStart
    string public constant PRICE_CANNOT_BE_ZERO = "97"; // Oracle price cannot be zero
    string public constant INVALID_PROTOCOL_SWAP_FEE = "98"; // Protocol swap fee larger than max allowed
    string public constant COLLATERAL_CANNOT_COVER_EXISTING_BORROW = "99"; // 'Collateral remaining after withdrawal would not cover existing borrow'
    string public constant CALLER_NOT_GUILD_OR_GUILD_ADMIN = "A0"; // 'The caller of the function is not the guild or guild admin'
    string public constant NOT_ENOUGH_MONEY_IN_GUILD_TO_SWAP = "A1"; // 'There is not enough money in the Guild treasury for a successfull swap and debt burn'
    string public constant MONEY_DOES_NOT_MATCH = "A2"; // 'Guild or Oracle cannot be initialized with a Money token that differs from the other.
    string public constant ORACLE_ADDRESS_CANNOT_BE_ZERO = "A3"; // 'A valid address needs to be used when updating the Oracle
    string public constant ORACLE_NOT_SET = "A4"; // 'An oracle has not been registered with guildAddressProvider

    string public constant OWNABLE_ONLY_OWNER = "Ownable: caller is not the owner";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IGuild} from "../../../interfaces/IGuild.sol";
import {IInitializableAssetToken} from "../../../interfaces/IInitializableAssetToken.sol";
import {IInitializableLiabilityToken} from "../../../interfaces/IInitializableLiabilityToken.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from "../upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
import {IERC20Detailed} from "../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ConfiguratorInputTypes} from "../types/ConfiguratorInputTypes.sol";
import {IUniswapV3Factory} from "../../../dependencies/uniswap-v3-core/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "../../../dependencies/uniswap-v3-core/interfaces/IUniswapV3Pool.sol";
import {FixedPoint96} from "../../../dependencies/uniswap-v3-core/libraries/FixedPoint96.sol";
import {CollateralConfiguration} from "../configuration/CollateralConfiguration.sol";

/**
 * @title ConfiguratorLogic library
 * @author Covenant Labs, inspired by AAVEv3
 * @notice Implements the functions to initialize PerpetualDebt and update assetTokens and liabilityTokens
 */
library ConfiguratorLogic {
    using CollateralConfiguration for DataTypes.CollateralConfigurationMap;

    uint8 internal constant PERP_DEBT_DECIMALS = 18;
    uint256 internal constant SQRT10Q96 = 0x3298B075B4B6A90D67DB40000;

    // See `IGuildConfigurator` for descriptions
    event PerpetualDebtInitialized(
        address indexed assetToken,
        address liabilityToken,
        address moneyToken,
        uint256 duration,
        uint24 dexFee
    );

    event CollateralInitialized(address indexed asset);

    event AssetTokenUpgraded(address indexed guildAddress, address indexed assetProxy, address indexed implementation);

    event LiabilityTokenUpgraded(
        address indexed guildAddress,
        address indexed liabilityProxy,
        address indexed implementation
    );

    /**
     * @notice Initialize a collateral asset by including it in the set of accepted collateral and configuring it
     * @dev Emits the `CollateralInitialized` event
     * @param guild The Guild in which the collateral will be initialized
     * @param input The needed parameters for the initialization
     */

    function executeInitCollateral(IGuild guild, ConfiguratorInputTypes.InitCollateralInput calldata input) internal {
        guild.initCollateral(input.asset);

        DataTypes.CollateralConfigurationMap memory currentConfig = DataTypes.CollateralConfigurationMap(0);

        currentConfig.setDecimals(input.assetDecimals);
        currentConfig.setActive(true);

        guild.setConfiguration(input.asset, currentConfig);

        emit CollateralInitialized(input.asset);
    }

    /**
     * @notice Initialize a perpetual debt by creating and initializing the assetToken and liability token
     * @dev Emits the `PerpetualDebtInitialized` event
     * @dev Hardcodes ERC20 decimals to 18
     * @param guild The Guild in which the perpetual debt will be initialized
     * @param input The needed parameters for the initialization
     */
    function executeInitPerpetualDebt(IGuild guild, ConfiguratorInputTypes.InitPerpetualDebtInput calldata input)
        internal
    {
        address assetTokenProxyAddress = _initTokenWithProxy(
            input.assetTokenImpl,
            abi.encodeWithSelector(
                IInitializableAssetToken.initialize.selector,
                guild,
                PERP_DEBT_DECIMALS,
                input.assetTokenName,
                input.assetTokenSymbol,
                input.params
            )
        );

        address liabilityTokenProxyAddress = _initTokenWithProxy(
            input.liabilityTokenImpl,
            abi.encodeWithSelector(
                IInitializableLiabilityToken.initialize.selector,
                guild,
                PERP_DEBT_DECIMALS,
                input.liabilityTokenName,
                input.liabilityTokenSymbol,
                input.params
            )
        );

        //init DEX pool
        address poolAddress = IUniswapV3Factory(input.dexFactory).createPool(
            assetTokenProxyAddress,
            input.moneyToken,
            input.dexFee
        );

        //Initialized pool to a price of 1 (in terms of money)
        //@dev Uniswap encodes prices as token1/token0 (in sqrtQ96 notation)
        uint160 sqrtOneQ96 = _getSqrtQ96OnePrice(assetTokenProxyAddress, input.moneyToken, PERP_DEBT_DECIMALS);

        IUniswapV3Pool(poolAddress).initialize(sqrtOneQ96);

        //Init guild perpetual debt
        guild.initPerpetualDebt(
            assetTokenProxyAddress,
            liabilityTokenProxyAddress,
            input.moneyToken,
            input.duration,
            input.notionalPriceLimitMax,
            input.notionalPriceLimitMin,
            input.dexFactory,
            input.dexFee
        );

        emit PerpetualDebtInitialized(
            assetTokenProxyAddress,
            liabilityTokenProxyAddress,
            input.moneyToken,
            input.duration,
            input.dexFee
        );
    }

    /**
     * @notice Updates the assetToken implementation and initializes it
     * @dev Emits the `AssetTokenUpgraded` event
     * @param cachedGuild The Guild containing the assetToken
     * @param input The parameters needed for the initialize call
     */
    function executeUpdateAssetToken(IGuild cachedGuild, ConfiguratorInputTypes.UpdateAssetTokenInput calldata input)
        internal
    {
        address assetTokenProxyAddress = address(cachedGuild.getAsset());

        bytes memory encodedCall = abi.encodeWithSelector(
            IInitializableAssetToken.initialize.selector,
            cachedGuild,
            PERP_DEBT_DECIMALS,
            input.name,
            input.symbol,
            input.params
        );

        _upgradeTokenImplementation(assetTokenProxyAddress, input.implementation, encodedCall);

        emit AssetTokenUpgraded(address(cachedGuild), assetTokenProxyAddress, input.implementation);
    }

    /**
     * @notice Updates the liability debt token implementation and initializes it
     * @dev Emits the `LiabilityTokenUpgraded` event
     * @param cachedGuild The Guild containing the collateral with the liability token
     * @param input The parameters needed for the initialize call
     */
    function executeUpdateLiabilityToken(
        IGuild cachedGuild,
        ConfiguratorInputTypes.UpdateLiabilityTokenInput calldata input
    ) internal {
        address liabilityTokenProxyAddress = address(cachedGuild.getLiability());

        bytes memory encodedCall = abi.encodeWithSelector(
            IInitializableAssetToken.initialize.selector,
            cachedGuild,
            PERP_DEBT_DECIMALS,
            input.name,
            input.symbol,
            input.params
        );

        _upgradeTokenImplementation(liabilityTokenProxyAddress, input.implementation, encodedCall);

        emit LiabilityTokenUpgraded(address(cachedGuild), liabilityTokenProxyAddress, input.implementation);
    }

    /**
     * @notice Creates a new proxy and initializes the implementation
     * @param implementation The address of the implementation
     * @param initParams The parameters that is passed to the implementation to initialize
     * @return The address of initialized proxy
     */
    function _initTokenWithProxy(address implementation, bytes memory initParams) internal returns (address) {
        InitializableImmutableAdminUpgradeabilityProxy proxy = new InitializableImmutableAdminUpgradeabilityProxy(
            address(this)
        );

        proxy.initialize(implementation, initParams);

        return address(proxy);
    }

    /**
     * @notice Upgrades the implementation and makes call to the proxy
     * @dev The call is used to initialize the new implementation.
     * @param proxyAddress The address of the proxy
     * @param implementation The address of the new implementation
     * @param  initParams The parameters to the call after the upgrade
     */
    function _upgradeTokenImplementation(
        address proxyAddress,
        address implementation,
        bytes memory initParams
    ) internal {
        InitializableImmutableAdminUpgradeabilityProxy proxy = InitializableImmutableAdminUpgradeabilityProxy(
            payable(proxyAddress)
        );

        proxy.upgradeToAndCall(implementation, initParams);
    }

    /**
     * @notice returns uniswap sqrtRatioQ96 value, for a price of 1, depending on token decimal units
     */
    function _getSqrtQ96OnePrice(
        address assetToken,
        address moneyToken,
        uint8 assetDecimals
    ) internal view returns (uint160 sqrtOneQ96) {
        bool moneyIsToken0 = moneyToken < assetToken;
        int8 moneyDecimals = int8(uint8(IERC20Detailed(moneyToken).decimals()));

        //uniswap encodes prices as sqrt(token1/token0) in Q96 notation.
        int8 decimalDiff = moneyIsToken0 ? int8(assetDecimals) - moneyDecimals : moneyDecimals - int8(assetDecimals);

        if (decimalDiff >= 0) {
            sqrtOneQ96 = uint160(
                ((decimalDiff % 2) == 0 ? FixedPoint96.Q96 : SQRT10Q96) * (10**(uint8(decimalDiff) >> 1))
            );
        } else {
            decimalDiff = -decimalDiff;
            sqrtOneQ96 = uint160(
                ((decimalDiff % 2) == 0 ? FixedPoint96.Q96 : SQRT10Q96) / (10**(uint8(decimalDiff) >> 1))
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// Notice: license change Jan 27, 2023
pragma solidity 0.8.17;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    // Half percentage factor (50.00%)
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

    /**
     * @notice Executes a percentage multiplication
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentmul percentage
     **/
    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if iszero(or(iszero(percentage), iszero(gt(value, div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage))))) {
                revert(0, 0)
            }

            result := div(add(mul(value, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /**
     * @notice Executes a percentage division
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentdiv percentage
     **/
    function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
        assembly {
            if or(
                iszero(percentage),
                iszero(iszero(gt(value, div(sub(not(0), div(percentage, 2)), PERCENTAGE_FACTOR))))
            ) {
                revert(0, 0)
            }

            result := div(add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library ConfiguratorInputTypes {
    struct InitCollateralInput {
        address asset;
        uint8 assetDecimals;
    }

    struct InitPerpetualDebtInput {
        address assetTokenImpl;
        address liabilityTokenImpl;
        address moneyToken;
        string assetTokenName;
        string assetTokenSymbol;
        string liabilityTokenName;
        string liabilityTokenSymbol;
        uint256 duration;
        uint256 notionalPriceLimitMax;
        uint256 notionalPriceLimitMin;
        address dexFactory;
        uint24 dexFee;
        bytes params;
    }

    struct UpdateAssetTokenInput {
        string name;
        string symbol;
        address implementation;
        bytes params;
    }

    struct UpdateLiabilityTokenInput {
        string name;
        string symbol;
        address implementation;
        bytes params;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {ILiabilityToken} from "../../../interfaces/ILiabilityToken.sol";
import {IAssetToken} from "../../../interfaces/IAssetToken.sol";

library DataTypes {
    //@dev Uniswap requires the address of token0 < token1.
    //@dev All oracle prices by uniswap are given as a ratio of token0/token1.
    struct DexPoolData {
        address token0;
        address token1;
        uint24 fee;
        bool moneyIsToken0; //indicates whether token0 is the money token
        address poolAddress;
    }

    struct DexOracleData {
        address dexFactory; // Uniswap v3 factory
        DexPoolData dex; // Dex pool details
        uint256 currentPrice;
        uint256 twapPrice;
        uint256 lastTWAPObservationTime; // Timestamp of last oracle consult for TWAP price
        uint256 lastCurrentObservationTime; // Timestamp of last oracle consult for current price
        int56 lastTWAPTickCumulative; //For Uniswap v3.0 TWAP calculation
        uint256 lastTWAPTimeDelta; //recording of last time delta
    }

    struct PerpetualDebtData {
        //stores the perpetual debt configuration
        PerpDebtConfigurationMap configuration;
        //Token addresses
        IAssetToken zToken;
        ILiabilityToken dToken;
        IERC20 money;
        uint256 beta; //beta multiplier, indicating duration of debt instrument
        DexOracleData dexOracle; //Dex Oracle
        uint256 lastRefinance; //last refinance block number
        //Price limit variables when refinancing
        uint256 notionalPriceMax; //[ray]
        uint256 notionalPriceMin; //[ray]
        //protocol fees
        address protocolServiceFeeAddress; //protocol service fee address (address in which to mint debt service fee)
        address protocolMintFeeAddress; //protocol mint fee address (address in which to mint debt mint fee)
        address protocolDistributionFeeAddress; //protocol distribution fee address (address in which to mint debt service fee)
        address protocolSwapFeeAddress; //protocol swap fee address (address in which to mint debt service fee)
    }

    struct CollateralData {
        //stores the collateral configuration
        CollateralConfigurationMap configuration;
        //the id of the collateral. Represents the position in the list of the active ERC20 collaterals
        uint16 id;
        //map of user balances (for a given collateral)
        mapping(address => uint256) balances;
        //total collateral balance held by the Guild
        uint256 totalBalance;
        //map of user collateral prices at the time debt was last minted
        //@dev - only used if collateral configured as non-MTM
        mapping(address => uint256) lastMintPrice;
    }

    struct GuildTreasuryData {
        //stores the amount of money owned by the Guild Treasury
        uint256 moneyAmount;
    }

    struct CollateralConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: collateral is active
        //bit 57: collateral is frozen
        //bit 58: is non-MTM liquidation (collateral liquidation uses last mint price)
        //bit 59: unused
        //bit 60: collateral is paused
        //bit 61-115: unused
        //bit 81-151: user supply cap in 1/100 tokens, usersupplyCap == 0 => no cap
        //bit 116-151: supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-255: unused

        uint256 data;
    }

    struct PerpDebtConfigurationMap {
        //bit 0: perpetual debt is paused (no mint, no burn/distribute, no liquidate, no refinance)
        //bit 1: perpetual debt is frozen (no mint, yes burn/distribute, yes liquidate, no refinance)
        //bit 2-37: mint cap in whole tokens, borrowCap ==0 => no cap
        //bit 38-47: unused
        //bit 48-63: protocol service fee (bps)
        //bit 64-79: protocol mint fee (bps)
        //bit 80-95: protocol distribution fee (bps)
        //bit 96-111: protocol swap fee (bps)
        //bit 112-255: unused

        uint256 data;
    }

    struct ExecuteDepositParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint256 collateralsCount;
        address oracle;
        address oracleSentinel;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 collateralsCount;
        address oracle;
        address oracleSentinel;
    }

    struct ExecuteNonMTMStateUpdate {
        uint256 collateralsCount;
        address oracle;
        address oracleSentinel;
    }

    struct ExecuteSupplyParams {
        address collateral;
        uint256 amount;
        address user;
    }

    struct ExecuteBorrowParams {
        address user;
        address onBehalfOf;
        uint256 amount;
        uint256 collateralsCount;
        address oracle;
        address oracleSentinel;
    }

    struct ExecuteRepayParams {
        address onBehalfOf;
        uint256 amount;
    }

    struct GetUserAccountDataParams {
        uint256 collateralsCount;
        address user;
        address oracle;
    }

    struct ExecuteInitPerpetualDebtParams {
        address assetTokenAddress;
        address liabilityTokenAddress;
        address moneyAddress;
        uint256 duration;
        uint256 notionalPriceLimitMax;
        uint256 notionalPriceLimitMin;
        address dexFactory;
        uint24 dexFee;
        address oracle;
    }

    struct CalculateUserAccountDataParams {
        uint256 collateralsCount;
        address user;
        address oracle;
        PriceContext priceContext;
    }

    struct ValidateBorrowParams {
        address user;
        uint256 amount;
        uint256 collateralsCount;
        address oracle;
        address oracleSentinel;
    }

    struct ValidateBorrowLocalVars {
        uint256 currentLtv;
        uint256 collateralNeededInBaseCurrency;
        uint256 userCollateralInBaseCurrency;
        uint256 userDebtInBaseCurrency;
        uint256 availableLiquidity;
        uint256 healthFactor;
        uint256 totalDebt;
        uint256 totalSupplyVariableDebt;
        uint256 reserveDecimals;
        uint256 borrowCap;
        uint256 amountInBaseCurrency;
        address eModePriceSource;
        address siloedBorrowingAddress;
    }

    struct ExecuteLiquidationCallParams {
        uint256 collateralsCount;
        uint256 debtToCover;
        address collateralAsset;
        address user;
        address priceOracle;
        address oracleSentinel;
    }

    struct ValidateLiquidationCallParams {
        uint256 totalDebt;
        uint256 healthFactor;
        address oracleSentinel;
    }

    struct ProxyStep {
        address assetToken;
        address baseToken;
        address proxySource;
    }

    struct PriceSourceData {
        address tokenA;
        address tokenB;
        address priceSource;
    }

    enum Roles {
        DEPOSITOR,
        WITHDRAWER,
        BORROWER,
        REPAYER
    }

    struct UserRolesData {
        // An array of mappings of user -> roles
        mapping(address => uint256) roles;
    }

    //@dev - not more than 255 price contexts to be used (8 bit encoding)
    enum PriceContext {
        BORROW,
        LIQUIDATION_TRIGGER,
        LIQUIDATION,
        FRONTEND
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

import {BaseUpgradeabilityProxy} from "../../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol";

/**
 * @title BaseImmutableAdminUpgradeabilityProxy
 * @author Aave, inspired by the OpenZeppelin upgradeability proxy pattern
 * @notice This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * @dev The admin role is stored in an immutable, which helps saving transactions costs
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
    address internal immutable _ADMIN;

    /**
     * @dev Constructor.
     * @param adminAddress The address of the admin
     */
    constructor(address adminAddress) {
        _ADMIN = adminAddress;
    }

    modifier ifAdmin() {
        if (msg.sender == _ADMIN) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @notice Return the admin address
     * @return The address of the proxy admin.
     */
    function admin() external ifAdmin returns (address) {
        return _ADMIN;
    }

    /**
     * @notice Return the implementation address
     * @return The address of the implementation.
     */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @notice Upgrade the backing implementation of the proxy.
     * @dev Only the admin can call this function.
     * @param newImplementation The address of the new implementation.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @notice Upgrade the backing implementation of the proxy and call a function
     * on the new implementation.
     * @dev This is useful to initialize the proxied contract.
     * @param newImplementation The address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @notice Only fall back when the sender is not the admin.
     */
    function _willFallback() internal virtual override {
        require(msg.sender != _ADMIN, "Cant call fallback fxn from proxy admin");
        super._willFallback();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

import {InitializableUpgradeabilityProxy} from "../../../dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol";
import {Proxy} from "../../../dependencies/openzeppelin/upgradeability/Proxy.sol";
import {BaseImmutableAdminUpgradeabilityProxy} from "./BaseImmutableAdminUpgradeabilityProxy.sol";

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @author Aave
 * @dev Extends BaseAdminUpgradeabilityProxy with an initializer function
 */
contract InitializableImmutableAdminUpgradeabilityProxy is
    BaseImmutableAdminUpgradeabilityProxy,
    InitializableUpgradeabilityProxy
{
    /**
     * @dev Constructor.
     * @param admin The address of the admin
     */
    constructor(address admin) BaseImmutableAdminUpgradeabilityProxy(admin) {
        // Intentionally left blank
    }

    /// @inheritdoc BaseImmutableAdminUpgradeabilityProxy
    function _willFallback() internal override(BaseImmutableAdminUpgradeabilityProxy, Proxy) {
        BaseImmutableAdminUpgradeabilityProxy._willFallback();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing || isConstructor() || revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /**
     * @notice Returns the revision number of the contract
     * @dev Needs to be defined in the inherited class as a constant.
     * @return The revision number
     **/
    function getRevision() internal pure virtual returns (uint256);

    /**
     * @notice Returns true if and only if the function is running in the constructor
     * @return True if the function is running in the constructor
     **/
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}