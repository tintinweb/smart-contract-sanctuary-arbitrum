// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library SafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x + y) >= x);
        }
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x - y) <= x);
        }
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @param message The error msg
    /// @return z The difference of x and y
    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        unchecked {
            require((z = x - y) <= x, message);
        }
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require(x == 0 || (z = x * y) / x == y);
        }
    }

    /// @notice Returns x / y, reverts if overflows - no specific check, solidity reverts on division by 0
    /// @param x The numerator
    /// @param y The denominator
    /// @return z The product of x and y
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
            uint256 twos = (0 - denominator) & denominator;
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
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

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
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

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

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
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

            tick = tickLow == tickHi ? tickLow : (getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow);

            
            
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import "../../../dependencies/@openzeppelin/contracts/token/ERC721/IERC721.sol";

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
pragma solidity >=0.7.5;
pragma abicoder v2;

import "../../../dependencies/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../../../dependencies/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./IPoolInitializer.sol";
import "./IERC721Permit.sol";
import "./IPeripheryPayments.sol";
import "./IPeripheryImmutableState.sol";
import "../libraries/PoolAddress.sol";

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
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(
        uint256 indexed tokenId,
        address recipient,
        uint256 amount0,
        uint256 amount1
    );

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
    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
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
pragma solidity >=0.5.0 <0.9.0;

import "../../../dependencies/uniswap-v3-core/libraries/FullMath.sol";
import "../../../dependencies/uniswap-v3-core/libraries/TickMath.sol";
import "../../../dependencies/uniswap-v3-core/interfaces/IUniswapV3Pool.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, "BP");

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        ) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[
                1
            ] - secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(
            tickCumulativesDelta / int56(uint56(secondsAgo))
        );
        // Always round to negative infinity
        if (
            tickCumulativesDelta < 0 &&
            (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)
        ) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(
            secondsAgoX160 /
                (uint192(secondsPerLiquidityCumulativesDelta) << 32)
        );
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(
                sqrtRatioX96,
                sqrtRatioX96,
                1 << 64
            );
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool)
        internal
        view
        returns (uint32 secondsAgo)
    {
        (
            ,
            ,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,

        ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, "NI");

        (uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(
            pool
        ).observations((observationIndex + 1) % observationCardinality);

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        unchecked {
            secondsAgo = uint32(block.timestamp) - observationTimestamp;
        }
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool)
        internal
        view
        returns (int24, uint128)
    {
        (
            ,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,

        ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, "NEO");

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (
            uint32 observationTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,

        ) = IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) +
            observationCardinality -
            1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, "ONI");

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24(
            (tickCumulative - int56(uint56(prevTickCumulative))) /
                int56(uint56(delta))
        );
        uint128 liquidity = uint128(
            (uint192(delta) * type(uint160).max) /
                (uint192(
                    secondsPerLiquidityCumulativeX128 -
                        prevSecondsPerLiquidityCumulativeX128
                ) << 32)
        );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(
        WeightedTickData[] memory weightedTickData
    ) internal pure returns (int24 weightedArithmeticMeanTick) {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator +=
                weightedTickData[i].tick *
                int256(uint256(weightedTickData[i].weight));
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0))
            weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, "DL");
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i]
                ? syntheticTick += ticks[i - 1]
                : syntheticTick -= ticks[i - 1];
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xa598dd2fba360510c5a8f02f44423a4468e902df5857dbce3ca162a43a3a31ff;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../../dependencies/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import '../../uniswap-v3-core/interfaces/IUniswapV3Factory.sol';
import '../../uniswap-v3-core/interfaces/IUniswapV3Pool.sol';
import '../../uniswap-v3-core/interfaces/IERC20Minimal.sol';

import '../../uniswap-v3-periphery/interfaces/INonfungiblePositionManager.sol';
import '../../uniswap-v3-periphery/interfaces/IMulticall.sol';

/// @title Uniswap V3 Staker Interface
/// @notice Allows staking nonfungible liquidity tokens in exchange for reward tokens
interface IUniswapV3Staker is IERC721Receiver, IMulticall {
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param refundee The address which receives any remaining reward tokens when the incentive is ended
    struct IncentiveKey {
        IERC20Minimal rewardToken;
        IUniswapV3Pool pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
    }

    /// @notice The Uniswap V3 Factory
    function factory() external view returns (IUniswapV3Factory);

    /// @notice The nonfungible position manager with which this staking contract is compatible
    function nonfungiblePositionManager() external view returns (INonfungiblePositionManager);

    /// @notice The max duration of an incentive in seconds
    function maxIncentiveDuration() external view returns (uint256);

    /// @notice The max amount of seconds into the future the incentive startTime can be set
    function maxIncentiveStartLeadTime() external view returns (uint256);

    /// @notice Represents a staking incentive
    /// @param incentiveId The ID of the incentive computed from its parameters
    /// @return totalRewardUnclaimed The amount of reward token not yet claimed by users
    /// @return totalSecondsClaimedX128 Total liquidity-seconds claimed, represented as a UQ32.128
    /// @return numberOfStakes The count of deposits that are currently staked for the incentive
    function incentives(bytes32 incentiveId)
        external
        view
        returns (
            uint256 totalRewardUnclaimed,
            uint160 totalSecondsClaimedX128,
            uint96 numberOfStakes
        );

    /// @notice Returns information about a deposited NFT
    /// @return owner The owner of the deposited NFT
    /// @return numberOfStakes Counter of how many incentives for which the liquidity is staked
    /// @return tickLower The lower tick of the range
    /// @return tickUpper The upper tick of the range
    function deposits(uint256 tokenId)
        external
        view
        returns (
            address owner,
            uint48 numberOfStakes,
            int24 tickLower,
            int24 tickUpper
        );

    /// @notice Returns information about a staked liquidity NFT
    /// @param tokenId The ID of the staked token
    /// @param incentiveId The ID of the incentive for which the token is staked
    /// @return secondsPerLiquidityInsideInitialX128 secondsPerLiquidity represented as a UQ32.128
    /// @return liquidity The amount of liquidity in the NFT as of the last time the rewards were computed
    function stakes(uint256 tokenId, bytes32 incentiveId)
        external
        view
        returns (uint160 secondsPerLiquidityInsideInitialX128, uint128 liquidity);

    /// @notice Returns amounts of reward tokens owed to a given address according to the last time all stakes were updated
    /// @param rewardToken The token for which to check rewards
    /// @param owner The owner for which the rewards owed are checked
    /// @return rewardsOwed The amount of the reward token claimable by the owner
    function rewards(IERC20Minimal rewardToken, address owner) external view returns (uint256 rewardsOwed);

    /// @notice Creates a new liquidity mining incentive program
    /// @param key Details of the incentive to create
    /// @param reward The amount of reward tokens to be distributed
    function createIncentive(IncentiveKey memory key, uint256 reward) external;

    /// @notice Ends an incentive after the incentive end time has passed and all stakes have been withdrawn
    /// @param key Details of the incentive to end
    /// @return refund The remaining reward tokens when the incentive is ended
    function endIncentive(IncentiveKey memory key) external returns (uint256 refund);

    /// @notice Transfers ownership of a deposit from the sender to the given recipient
    /// @param tokenId The ID of the token (and the deposit) to transfer
    /// @param to The new owner of the deposit
    function transferDeposit(uint256 tokenId, address to) external;

    /// @notice Withdraws a Uniswap V3 LP token `tokenId` from this contract to the recipient `to`
    /// @param tokenId The unique identifier of an Uniswap V3 LP token
    /// @param to The address where the LP token will be sent
    /// @param data An optional data array that will be passed along to the `to` address via the NFT safeTransferFrom
    function withdrawToken(
        uint256 tokenId,
        address to,
        bytes memory data
    ) external;

    /// @notice Stakes a Uniswap V3 LP token
    /// @param key The key of the incentive for which to stake the NFT
    /// @param tokenId The ID of the token to stake
    function stakeToken(IncentiveKey memory key, uint256 tokenId) external;

    /// @notice Unstakes a Uniswap V3 LP token
    /// @param key The key of the incentive for which to unstake the NFT
    /// @param tokenId The ID of the token to unstake
    function unstakeToken(IncentiveKey memory key, uint256 tokenId) external;

    /// @notice Transfers `amountRequested` of accrued `rewardToken` rewards from the contract to the recipient `to`
    /// @param rewardToken The token being distributed as a reward
    /// @param to The address where claimed rewards will be sent to
    /// @param amountRequested The amount of reward tokens to claim. Claims entire reward amount if set to 0.
    /// @return reward The amount of reward tokens claimed
    function claimReward(
        IERC20Minimal rewardToken,
        address to,
        uint256 amountRequested
    ) external returns (uint256 reward);

    /// @notice Calculates the reward amount that will be received for the given stake
    /// @param key The key of the incentive
    /// @param tokenId The ID of the token
    /// @return reward The reward accrued to the NFT for the given incentive thus far
    function getRewardInfo(IncentiveKey memory key, uint256 tokenId)
        external
        returns (uint256 reward, uint160 secondsInsideX128);

    /// @notice Event emitted when a liquidity mining incentive has been created
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param refundee The address which receives any remaining reward tokens after the end time
    /// @param reward The amount of reward tokens to be distributed
    event IncentiveCreated(
        IERC20Minimal indexed rewardToken,
        IUniswapV3Pool indexed pool,
        uint256 startTime,
        uint256 endTime,
        address refundee,
        uint256 reward
    );

    /// @notice Event that can be emitted when a liquidity mining incentive has ended
    /// @param incentiveId The incentive which is ending
    /// @param refund The amount of reward tokens refunded
    event IncentiveEnded(bytes32 indexed incentiveId, uint256 refund);

    /// @notice Emitted when ownership of a deposit changes
    /// @param tokenId The ID of the deposit (and token) that is being transferred
    /// @param oldOwner The owner before the deposit was transferred
    /// @param newOwner The owner after the deposit was transferred
    event DepositTransferred(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);

    /// @notice Event emitted when a Uniswap V3 LP token has been staked
    /// @param tokenId The unique identifier of an Uniswap V3 LP token
    /// @param liquidity The amount of liquidity staked
    /// @param incentiveId The incentive in which the token is staking
    event TokenStaked(uint256 indexed tokenId, bytes32 indexed incentiveId, uint128 liquidity);

    /// @notice Event emitted when a Uniswap V3 LP token has been unstaked
    /// @param tokenId The unique identifier of an Uniswap V3 LP token
    /// @param incentiveId The incentive in which the token is staking
    event TokenUnstaked(uint256 indexed tokenId, bytes32 indexed incentiveId);

    /// @notice Event emitted when a reward token has been claimed
    /// @param to The address where claimed rewards were sent to
    /// @param reward The amount of reward tokens claimed
    event RewardClaimed(address indexed to, uint256 reward);
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

import {IGuildAddressesProvider} from "./IGuildAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title ICovenantPriceOracle
 * @author Covenant Labs
 * @notice Defines the basic interface for a Covenant price oracle.
 **/
interface ICovenantPriceOracle {
    /**
     * @notice Returns the GuildAddressesProvider
     * @return The address of the GuildAddressesProvider contract
     */
    function ADDRESSES_PROVIDER() external view returns (IGuildAddressesProvider);

    /**
     * @notice Returns the base currency address for the price oracle
     * @return The base currency address.
     **/
    function BASE_CURRENCY() external view returns (address);

    /**
     * @notice Sets the price source for each asset
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources for each asset
     **/
    function setAssetPriceSources(address[] memory assets, address[] memory sources) external;

    /**
     * @notice Validate oracle's guild price resolution, money and addressProvider config
     * @dev Validates address_provider + money match with guild setup, and ensure zToken + collaterals resolve their price
     **/
    function validateAddressProviderAndGuildPriceResolution(address guildAddressProvider) external view;

    /**
     * @notice Validate asset price resolution
     * @param asset The address of the asset to resolve price (across all price contexts)
     **/
    function validateAssetPriceResolution(address asset) external view;

    /**
     * @notice Gets the asset price source
     * @param asset The address of the asset
     * @return The price source of the asset
     */
    function getPriceSourceOfAsset(address asset) external view returns (address);

    /**
     * @notice Gets the asset price in the base currency
     * @param asset The address of the asset
     * @param context The context for the price
     * @return The price of the asset in the oracle base currency
     **/
    function getAssetPrice(address asset, DataTypes.PriceContext context) external view returns (uint256);

    /**
     * @notice Sets the lookback times for a given price context
     * @param context The context for the price
     * @param startLookbackTime The start lookback time
     * @param endLookbackTime The end lookback time
     **/
    function setContextLookbackTime(
        DataTypes.PriceContext context,
        uint32 startLookbackTime,
        uint32 endLookbackTime
    ) external;

    /**
     * @notice Gets the lookback times for a given price context
     * @param context The context for the price
     **/
    function getContextLookbackTime(DataTypes.PriceContext context) external view returns (uint32, uint32);
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

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IAssetToken} from "./IAssetToken.sol";

/**
 * @title IFeeReceiver
 * @author Amorphous
 * @notice Defines the basic interface for a Fee Receiver
 **/
interface IFeeReceiver {
    /**
     * @notice Deposits Fees into a Fee Receiver service
     * @dev The function can only be called from the Guild and signals that the guild has sent zTokens
     * @param asset zToken that was deposited
     * @param amount zToken amount that Guild has already sent
     **/
    function depositFromGuild(IAssetToken asset, uint256 amount) external;
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

/**
 * @title IGuildAddressesProviderRegistry
 * @author Amorphous (cloned from AAVE core v3 commit d5fafce)
 * @notice Defines the basic interface for an Guild Addresses Provider Registry.
 **/
interface IGuildAddressesProviderRegistry {
    /**
     * @dev Emitted when a new AddressesProvider is registered.
     * @param addressesProvider The address of the registered GuildAddressesProvider
     * @param id The id of the registered GuildAddressesProvider
     */
    event AddressesProviderRegistered(address indexed addressesProvider, uint256 indexed id);

    /**
     * @dev Emitted when an AddressesProvider is unregistered.
     * @param addressesProvider The address of the unregistered GuildAddressesProvider
     * @param id The id of the unregistered GuildAddressesProvider
     */
    event AddressesProviderUnregistered(address indexed addressesProvider, uint256 indexed id);

    /**
     * @notice Returns the list of registered addresses providers
     * @return The list of addresses providers
     **/
    function getAddressesProvidersList() external view returns (address[] memory);

    /**
     * @notice Returns the id of a registered GuildAddressesProvider
     * @param addressesProvider The address of the GuildAddressesProvider
     * @return The id of the GuildAddressesProvider or 0 if is not registered
     */
    function getAddressesProviderIdByAddress(address addressesProvider) external view returns (uint256);

    /**
     * @notice Returns the address of a registered GuildAddressesProvider
     * @param id The id of the market
     * @return The address of the GuildAddressesProvider with the given id or zero address if it is not registered
     */
    function getAddressesProviderAddressById(uint256 id) external view returns (address);

    /**
     * @notice Registers an addresses provider
     * @dev The GuildAddressesProvider must not already be registered in the registry
     * @dev The id must not be used by an already registered GuildAddressesProvider
     * @param provider The address of the new GuildAddressesProvider
     * @param id The id for the new GuildAddressesProvider, referring to the market it belongs to
     **/
    function registerAddressesProvider(address provider, uint256 id) external;

    /**
     * @notice Removes an addresses provider from the list of registered addresses providers
     * @param provider The GuildAddressesProvider address
     **/
    function unregisterAddressesProvider(address provider) external;
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

/**
 * @title IOracleProxy
 * @author Amorphous
 * @notice Defines the basic interface for a Covenant price oracle proxy.
 **/
interface IOracleProxy {
    /**
     * @notice Returns the token0 currency
     * @return The address of the token0 contract
     **/
    function TOKEN0() external view returns (address);

    /**
     * @notice Returns the token1 currency
     * @return The address of the token1 contract
     **/
    function TOKEN1() external view returns (address);

    /**
     * @notice Returns the base currency given the asset
     * @param asset is the address of the asset
     * @return The address of the base currency given the asset adress
     **/
    function getBaseCurrency(address asset) external view returns (address);

    /**
     * @notice Gets the avg tick of asset price vs base currency price
     * @return The avg price tick of the asset in base currency
     **/
    function getAvgTick(
        address asset,
        uint32 beginLookbackTime,
        uint32 endLookbackTime
    ) external view returns (int24);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {IOracleProxy} from "./IOracleProxy.sol";

/**
 * @title IUniswapV3OracleProxy
 * @author Covenant Labs
 * @notice Defines the interface for the Covenant uni v3 oracle proxy
 **/
interface IUniswapV3OracleProxy is IOracleProxy {
    /**
     * @notice Returns the uni v3 pool address
     * @return The uni v3 pool source for the oracle proxy ticks
     **/
    function ORACLE_SOURCE() external view returns (address);

    /**
     * @notice Increases the cardinality of the oracle source
     * @param minCardinality is the new minimum cardinality for the uni v3 pool
     **/
    function increaseDexCardinality(uint16 minCardinality) external;

    /**
     * @notice Returns the cardinality of the oracle source
     * @return The minimum cardinality of the uni v3 pool
     **/
    function getDexCardinality() external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IGuildAddressesProviderRegistry} from "../interfaces/IGuildAddressesProviderRegistry.sol";
import {IGuildAddressesProvider} from "../interfaces/IGuildAddressesProvider.sol";
import {IGuild} from "../interfaces/IGuild.sol";
import {ICovenantPriceOracle} from "../interfaces/ICovenantPriceOracle.sol";
import {IERC20Minimal} from "../dependencies/uniswap-v3-core/interfaces/IERC20Minimal.sol";
import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IAssetToken} from "../interfaces/IAssetToken.sol";
import {IUniswapV3Pool} from "../dependencies/uniswap-v3-core/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3PoolState} from "../dependencies/uniswap-v3-core/interfaces/pool/IUniswapV3PoolState.sol";
import {IUniswapV3Factory} from "../dependencies/uniswap-v3-core/interfaces/IUniswapV3Factory.sol";
import {INonfungiblePositionManager} from "../dependencies/uniswap-v3-periphery/interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Staker} from "../dependencies/uniswap-v3-staker/interfaces/IUniswapV3Staker.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {PerpetualDebtLogic} from "../protocol/libraries/logic/PerpetualDebtLogic.sol";
import {CollateralConfiguration} from "../protocol/libraries/configuration/CollateralConfiguration.sol";
import {PerpetualDebtConfiguration} from "../protocol/libraries/configuration/PerpetualDebtConfiguration.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/SafeMath.sol";
import {PercentageMath} from "../protocol/libraries/math/PercentageMath.sol";
import {WadRayMath} from "../protocol/libraries/math/WadRayMath.sol";
import {DebtMath} from "../protocol/libraries/math/DebtMath.sol";

contract DataProvider {
    using PerpetualDebtLogic for DataTypes.PerpetualDebtData;
    using CollateralConfiguration for DataTypes.CollateralConfigurationMap;
    using PerpetualDebtConfiguration for DataTypes.PerpDebtConfigurationMap;
    using SafeMath for uint256;
    using PercentageMath for uint256;
    using WadRayMath for uint256;

    uint256 internal constant QUOTE_TIME_BUFFER = 900;

    struct GuildDetails {
        address guildAddressesProvider;
        address guild;
        string guildName;
        MoneyTokenDetails moneyTokenDetails;
        DebtTokenDetails debtTokenDetails;
        PriceToRateConversionInfo priceInfo;
        CollateralDetails collateralDetails;
        DexPoolLiquidity dexPoolLiquidity;
        FeeInfo feeInfo;
    }

    struct MoneyTokenDetails {
        address moneyToken;
        string symbol;
        uint8 decimals;
    }

    struct DebtTokenDetails {
        address zToken;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        uint8 debtNotionalDecimals;
        uint256 totalDebtNotional;
    }

    struct CollateralDetails {
        uint256 totalCollateralValue;
        uint8 totalCollateralValueDecimals;
        Collaterals[] collaterals;
    }

    struct Collaterals {
        address asset;
        string symbol;
        uint256 balance;
        uint8 decimals;
        uint256 value;
        bool nonMTM;
    }

    struct DexPoolLiquidity {
        address poolAddress;
        uint24 fee;
        bool moneyIsToken0;
        uint256 moneyTokenLiquidity;
        uint256 zTokenLiquidity;
    }

    struct FeeInfo {
        uint256 protocolServiceFee;
        uint8 protocolServiceFeeDecimals;
    }

    struct NonMTMDetails {
        uint256 debtLiquidationThreshold;
        uint8 liquidationThresholdDecimals;
    }

    struct PriceToRateConversionInfo {
        uint8 spotPriceDecimals;
        uint256 spotPrice;
        uint256 notionalSpotPrice;
        uint8 notionalPriceDecimals;
        uint256 notionalPriceLimitMin;
        uint256 notionalPriceLimitMax;
        uint256 duration;
    }

    struct AccountDebtInfo {
        address guild;
        address zToken;
        address account;
        uint256 healthFactor;
        uint8 healthFactorDecimals;
        uint256 availableBorrowsInZTokens;
        uint256 zTokensToRepayDebt;
        uint256 zTokenWalletBalance;
        uint8 zTokenDecimals;
        AccountCollateralBalances[] collateralBalances;
    }

    struct AccountCollateralBalances {
        address token;
        uint256 guildBalance;
        uint256 walletBalance;
        uint256 maxCollateralWithdrawAmount;
        uint8 collateralDecimals;
    }

    struct LpPositionEventInfo {
        string id;
        uint256 tokenId;
        address owner;
        bool staked;
        LpIncentiveEventInfo[] positionIncentives;
    }

    struct LpIncentiveEventInfo {
        string id;
        bool staked;
        address rewardToken;
        address pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
        uint256 reward;
    }

    struct LpPositionDetails {
        uint256 tokenId;
        address owner;
        bool staked;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        address poolAddress;
        uint160 sqrtPriceX96;
        int24 tick;
        LpIncentiveDetails[] lpIncentivesDetails;
    }

    struct LpIncentiveDetails {
        string id;
        bool staked;
        address rewardToken;
        address pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
        uint256 reward;
        string rewardTokenSymbol;
        uint8 rewardTokenDecimals;
        uint256 unclaimedRewardAmount;
    }

    struct LpRewardTokenDetails {
        address tokenAddress;
        string symbol;
        uint8 decimals;
        uint256 unclaimedAmount;
    }

    struct BasicTokenDetails {
        address tokenAddress;
        string symbol;
        uint8 decimals;
    }

    /**
     * @notice Returns registered guilds details after calling refinance()
     * @return guildDetails The details defined in the GuildDetails struct for registered guilds
     **/
    function getGuildsData(address addressesProviderRegistry) external returns (GuildDetails[] memory guildDetails) {
        IGuildAddressesProviderRegistry _addressesProviderRegistry = IGuildAddressesProviderRegistry(
            addressesProviderRegistry
        );
        address[] memory guildAddressesProviders = _addressesProviderRegistry.getAddressesProvidersList();
        guildDetails = new GuildDetails[](guildAddressesProviders.length);
        for (uint256 i = 0; i < guildAddressesProviders.length; i++) {
            guildDetails[i] = this.getRefinancedGuildDetails(guildAddressesProviders[i]);
        }
    }

    /**
     * @notice Returns guild details after calling refinance()
     * @return guildDetails The guild details defined in DataStructs
     **/
    function getRefinancedGuildDetails(address addressesProvider) external returns (GuildDetails memory guildDetails) {
        // set guild addresses provider
        guildDetails.guildAddressesProvider = addressesProvider;

        // fetch guild
        IGuild guild = _getGuild(addressesProvider);
        guildDetails.guild = address(guild);
        guildDetails.guildName = IGuildAddressesProvider(addressesProvider).getGuildId();

        // update the notional factor
        guild.refinance();

        // fetch the guild perpetual debt data
        DataTypes.PerpetualDebtData memory localPerpetualDebt = guild.getPerpetualDebt();

        // fetch money token details
        address moneyToken = address(localPerpetualDebt.money);
        string memory moneyTokenSymbol = IERC20Detailed(address(localPerpetualDebt.money)).symbol();
        uint8 moneyTokenDecimals = IERC20Detailed(address(localPerpetualDebt.money)).decimals();
        // set money token details
        guildDetails.moneyTokenDetails.moneyToken = moneyToken;
        guildDetails.moneyTokenDetails.symbol = moneyTokenSymbol;
        guildDetails.moneyTokenDetails.decimals = moneyTokenDecimals;

        // fetch zToken details
        // ERC20 details
        guildDetails.debtTokenDetails.zToken = address(localPerpetualDebt.zToken);
        guildDetails.debtTokenDetails.symbol = IERC20Detailed(address(localPerpetualDebt.zToken)).symbol();
        guildDetails.debtTokenDetails.decimals = IERC20Detailed(address(localPerpetualDebt.zToken)).decimals();
        guildDetails.debtTokenDetails.totalSupply = localPerpetualDebt.zToken.totalSupply();
        // Notional factor details
        guildDetails.debtTokenDetails.totalDebtNotional = localPerpetualDebt.zToken.totalNotionalSupply();
        guildDetails.debtTokenDetails.debtNotionalDecimals = guildDetails.debtTokenDetails.decimals;

        // fetch price conversion info
        guildDetails.priceInfo.spotPriceDecimals = guildDetails.moneyTokenDetails.decimals;
        guildDetails.priceInfo.spotPrice = _getSpotPrice(addressesProvider, address(localPerpetualDebt.zToken));
        guildDetails.priceInfo.notionalSpotPrice = localPerpetualDebt.getNotionalPriceGivenAssetPrice(
            guildDetails.priceInfo.spotPrice
        );
        // Price limit details
        guildDetails.priceInfo.notionalPriceDecimals = 27;
        guildDetails.priceInfo.notionalPriceLimitMin = localPerpetualDebt.notionalPriceMin;
        guildDetails.priceInfo.notionalPriceLimitMax = localPerpetualDebt.notionalPriceMax;
        // Duration details
        guildDetails.priceInfo.duration = WadRayMath.ray() / localPerpetualDebt.beta;

        // fetch collateral value & collateral details
        guildDetails.collateralDetails.totalCollateralValue = 0;
        guildDetails.collateralDetails.totalCollateralValueDecimals = guildDetails.moneyTokenDetails.decimals;

        address[] memory collateralsList = guild.getCollateralsList();
        guildDetails.collateralDetails.collaterals = new Collaterals[](collateralsList.length + 1);

        // factor in guild money balance into total collateral value
        uint256 moneyTokenGuildBalance = localPerpetualDebt.money.balanceOf(address(guild));
        guildDetails.collateralDetails.totalCollateralValue += moneyTokenGuildBalance;

        // factor in guild money balance into collateral details list
        guildDetails.collateralDetails.collaterals[0].asset = moneyToken;
        guildDetails.collateralDetails.collaterals[0].symbol = moneyTokenSymbol;
        guildDetails.collateralDetails.collaterals[0].balance = moneyTokenGuildBalance;
        guildDetails.collateralDetails.collaterals[0].decimals = moneyTokenDecimals;
        guildDetails.collateralDetails.collaterals[0].value = moneyTokenGuildBalance;
        guildDetails.collateralDetails.collaterals[0].nonMTM = false;

        for (uint256 i = 0; i < collateralsList.length; i++) {
            uint256 collateralGuildBalance = guild.getCollateralTotalBalance(collateralsList[i]);
            uint8 collateralDecimals = IERC20Detailed(collateralsList[i]).decimals();
            // set collateral details
            guildDetails.collateralDetails.collaterals[i + 1].asset = collateralsList[i];
            guildDetails.collateralDetails.collaterals[i + 1].symbol = IERC20Detailed(collateralsList[i]).symbol();
            guildDetails.collateralDetails.collaterals[i + 1].balance = collateralGuildBalance;
            guildDetails.collateralDetails.collaterals[i + 1].decimals = collateralDecimals;

            uint256 collateralPrice = _getSpotPrice(addressesProvider, collateralsList[i]);
            uint256 collateralValue = (collateralGuildBalance * collateralPrice) / (10 ** collateralDecimals);

            guildDetails.collateralDetails.collaterals[i + 1].value = collateralValue;
            guildDetails.collateralDetails.totalCollateralValue += collateralValue;

            DataTypes.CollateralConfigurationMap memory collateralConfiguration = guild.getCollateralConfiguration(
                collateralsList[i]
            );
            guildDetails.collateralDetails.collaterals[i + 1].nonMTM = collateralConfiguration
                .getNonMTMLiquidationFlag();
        }

        // fetch guild zToken/money pool address
        guildDetails.dexPoolLiquidity = _getDexPoolLiquidity(localPerpetualDebt);

        // fetch fee details (for off-chain APY calculation)
        DataTypes.PerpDebtConfigurationMap memory perpDebtConfig = guild.getPerpDebtConfiguration();
        guildDetails.feeInfo.protocolServiceFee = perpDebtConfig.getProtocolServiceFee();
        guildDetails.feeInfo.protocolServiceFeeDecimals = 4;
    }

    /**
     * @notice Returns non MTM threshold for the user after calling refinance()
     * @return nonMTMDetails The liquidation threshold details for the user defined in NontMTMDetails struct
     **/
    function getUserNonMTMLiquidationThreshold(
        address user,
        address addressesProvider
    ) external returns (NonMTMDetails memory nonMTMDetails) {
        // fetch guild
        IGuild guild = _getGuild(addressesProvider);

        // update the notional factor
        guild.refinance();

        // fetch money token decimals
        DataTypes.PerpetualDebtData memory localPerpetualDebt = guild.getPerpetualDebt();
        uint8 moneyTokenDecimals = IERC20Detailed(address(localPerpetualDebt.money)).decimals();

        // set liquidation threshold decimals
        nonMTMDetails.liquidationThresholdDecimals = moneyTokenDecimals;

        IGuild.UserAccountDataStruct memory userAccountData = guild.getUserAccountData(user);
        nonMTMDetails.debtLiquidationThreshold =
            (userAccountData.totalCollateralInBaseCurrencyForLiquidationTrigger *
                userAccountData.currentLiquidationThreshold) /
            10000;
    }

    /**
     * @notice Returns a price range given a rate range
     * @return conversionDetails The zToken/money token DEX price at a given refinanced rate
     **/
    function getRateToPriceConversionInfo(
        address addressesProvider
    ) external returns (PriceToRateConversionInfo memory conversionDetails) {
        // fetch guild
        IGuild guild = _getGuild(addressesProvider);

        // update the notional factor
        guild.refinance();

        // get spot price
        DataTypes.PerpetualDebtData memory localPerpetualDebt = guild.getPerpetualDebt();

        // get price decimals
        conversionDetails.spotPriceDecimals = IERC20Detailed(address(localPerpetualDebt.money)).decimals();

        // get spot price
        conversionDetails.spotPrice = _getSpotPrice(addressesProvider, address(localPerpetualDebt.zToken));

        // get debt notional spot price
        conversionDetails.notionalSpotPrice = localPerpetualDebt.getNotionalPriceGivenAssetPrice(
            conversionDetails.spotPrice
        );

        // get notional price limits
        conversionDetails.notionalPriceDecimals = 27;
        conversionDetails.notionalPriceLimitMin = localPerpetualDebt.notionalPriceMin;
        conversionDetails.notionalPriceLimitMax = localPerpetualDebt.notionalPriceMax;

        // get duration (in seconds)
        conversionDetails.duration = WadRayMath.ray() / localPerpetualDebt.beta;
    }

    function getGuildsAccountDebtInfo(
        address addressesProviderRegistry,
        address account
    ) external returns (AccountDebtInfo[] memory accountDebtInfos) {
        IGuildAddressesProviderRegistry _addressesProviderRegistry = IGuildAddressesProviderRegistry(
            addressesProviderRegistry
        );
        address[] memory guildAddressesProviders = _addressesProviderRegistry.getAddressesProvidersList();
        accountDebtInfos = new AccountDebtInfo[](guildAddressesProviders.length);
        for (uint256 i = 0; i < guildAddressesProviders.length; i++) {
            accountDebtInfos[i] = this.getGuildAccountDebtInfo(guildAddressesProviders[i], account);
        }
    }

    function getGuildAccountDebtInfo(
        address addressesProvider,
        address account
    ) external returns (AccountDebtInfo memory accountDebtInfo) {
        // fetch guild
        IGuild guild = _getGuild(addressesProvider);

        // update the notional factor
        guild.refinance();

        // get user account data
        IGuild.UserAccountDataStruct memory userAccountData = guild.getUserAccountData(account);

        // get asset token
        IAssetToken zToken = guild.getAsset();

        // return relevant debt info
        accountDebtInfo.account = account;
        accountDebtInfo.guild = address(guild);
        accountDebtInfo.zToken = address(zToken);
        accountDebtInfo.healthFactor = userAccountData.healthFactor;
        accountDebtInfo.healthFactorDecimals = 18;
        accountDebtInfo.availableBorrowsInZTokens = userAccountData.availableBorrowsInZTokens.rayDiv(
            _quoteBufferFactor(guild)
        );
        accountDebtInfo.zTokensToRepayDebt = userAccountData.zTokensToRepayDebt;
        accountDebtInfo.zTokenWalletBalance = zToken.balanceOf(account);
        accountDebtInfo.zTokenDecimals = IERC20Detailed(address(zToken)).decimals();

        // return relevant collateral token details
        address[] memory collaterals = guild.getCollateralsList();
        accountDebtInfo.collateralBalances = new AccountCollateralBalances[](collaterals.length);

        for (uint256 i = 0; i < collaterals.length; i++) {
            accountDebtInfo.collateralBalances[i].token = collaterals[i];
            accountDebtInfo.collateralBalances[i].guildBalance = guild.getCollateralBalanceOf(account, collaterals[i]);
            accountDebtInfo.collateralBalances[i].walletBalance = IERC20Detailed(collaterals[i]).balanceOf(account);
            accountDebtInfo.collateralBalances[i].maxCollateralWithdrawAmount = _getMaxCollateralWithdrawalAmount(
                guild,
                collaterals[i],
                account,
                userAccountData
            );
            accountDebtInfo.collateralBalances[i].collateralDecimals = IERC20Detailed(collaterals[i]).decimals();
        }
    }

    function getAccountLpPositionsDetails(
        LpPositionEventInfo[] calldata lpPositionsEventInfo,
        LpIncentiveEventInfo[] calldata activeLpIncentives,
        address nonFungiblePositionManager,
        address uniV3Factory,
        address uniV3Staker
    ) external returns (LpPositionDetails[] memory lpPositionDetails) {
        lpPositionDetails = new LpPositionDetails[](lpPositionsEventInfo.length);
        for (uint256 i = 0; i < lpPositionsEventInfo.length; i++) {
            lpPositionDetails[i] = _getAccoutLpPositionDetails(
                lpPositionsEventInfo[i],
                activeLpIncentives,
                nonFungiblePositionManager,
                uniV3Factory,
                uniV3Staker
            );
        }
    }

    function _getAccoutLpPositionDetails(
        LpPositionEventInfo calldata lpPositionEventInfo,
        LpIncentiveEventInfo[] calldata activeLpIncentives,
        address nonFungiblePositionManager,
        address uniV3Factory,
        address uniV3Staker
    ) internal returns (LpPositionDetails memory lpPositionDetails) {
        // set basic position info
        lpPositionDetails.tokenId = lpPositionEventInfo.tokenId;
        lpPositionDetails.owner = lpPositionEventInfo.owner;
        lpPositionDetails.staked = lpPositionEventInfo.staked;

        // get position info
        (
            ,
            ,
            lpPositionDetails.token0,
            lpPositionDetails.token1,
            lpPositionDetails.fee,
            lpPositionDetails.tickLower,
            lpPositionDetails.tickUpper,
            lpPositionDetails.liquidity,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(nonFungiblePositionManager).positions(lpPositionEventInfo.tokenId);

        // get position pool address
        lpPositionDetails.poolAddress = IUniswapV3Factory(uniV3Factory).getPool(
            lpPositionDetails.token0,
            lpPositionDetails.token1,
            lpPositionDetails.fee
        );

        // get pool slot0 & liquidity state
        IUniswapV3PoolState pool = IUniswapV3PoolState(lpPositionDetails.poolAddress);
        (lpPositionDetails.sqrtPriceX96, lpPositionDetails.tick, , , , , ) = pool.slot0();

        // get incentives info
        lpPositionDetails.lpIncentivesDetails = new LpIncentiveDetails[](
            lpPositionEventInfo.positionIncentives.length + activeLpIncentives.length
        );

        for (uint256 i = 0; i < lpPositionEventInfo.positionIncentives.length; i++) {
            LpIncentiveEventInfo memory positionIncentive = lpPositionEventInfo.positionIncentives[i];
            lpPositionDetails.lpIncentivesDetails[i].id = positionIncentive.id;
            lpPositionDetails.lpIncentivesDetails[i].staked = positionIncentive.staked;
            lpPositionDetails.lpIncentivesDetails[i].rewardToken = positionIncentive.rewardToken;
            lpPositionDetails.lpIncentivesDetails[i].pool = positionIncentive.pool;
            lpPositionDetails.lpIncentivesDetails[i].startTime = positionIncentive.startTime;
            lpPositionDetails.lpIncentivesDetails[i].endTime = positionIncentive.endTime;
            lpPositionDetails.lpIncentivesDetails[i].refundee = positionIncentive.refundee;
            lpPositionDetails.lpIncentivesDetails[i].reward = positionIncentive.reward;
            lpPositionDetails.lpIncentivesDetails[i].rewardTokenSymbol = IERC20Detailed(positionIncentive.rewardToken)
                .symbol();
            lpPositionDetails.lpIncentivesDetails[i].rewardTokenDecimals = IERC20Detailed(positionIncentive.rewardToken)
                .decimals();
            IUniswapV3Staker.IncentiveKey memory key = IUniswapV3Staker.IncentiveKey({
                rewardToken: IERC20Minimal(positionIncentive.rewardToken),
                pool: IUniswapV3Pool(positionIncentive.pool),
                startTime: positionIncentive.startTime,
                endTime: positionIncentive.endTime,
                refundee: positionIncentive.refundee
            });

            //check if tokenId is actually registered in staker
            (, uint128 liquidity) = IUniswapV3Staker(uniV3Staker).stakes(
                lpPositionEventInfo.tokenId,
                keccak256(abi.encode(key))
            );
            if (liquidity > 0) {
                (uint256 reward, ) = IUniswapV3Staker(uniV3Staker).getRewardInfo(key, lpPositionEventInfo.tokenId);
                lpPositionDetails.lpIncentivesDetails[i].unclaimedRewardAmount = reward;
            } else {
                lpPositionDetails.lpIncentivesDetails[i].unclaimedRewardAmount = 0;
            }
        }

        // associated all active incentives to this position (even if not yet staked)
        for (uint256 i = 0; i < activeLpIncentives.length; i++) {
            LpIncentiveEventInfo memory positionIncentive = activeLpIncentives[i];
            if (positionIncentive.pool == lpPositionDetails.poolAddress) {
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .id = positionIncentive.id;
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .staked = positionIncentive.staked;
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .rewardToken = positionIncentive.rewardToken;
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .pool = positionIncentive.pool;
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .startTime = positionIncentive.startTime;
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .endTime = positionIncentive.endTime;
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .refundee = positionIncentive.refundee;
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .reward = positionIncentive.reward;
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .rewardTokenSymbol = IERC20Detailed(positionIncentive.rewardToken).symbol();
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .rewardTokenDecimals = IERC20Detailed(positionIncentive.rewardToken).decimals();
                lpPositionDetails
                    .lpIncentivesDetails[lpPositionEventInfo.positionIncentives.length + i]
                    .unclaimedRewardAmount = 0;
            }
        }
    }

    function getAccountRewardTokensDetails(
        address account,
        address[] calldata rewardTokens,
        address uniV3Staker
    ) external view returns (LpRewardTokenDetails[] memory lpRewardTokenDetails) {
        lpRewardTokenDetails = new LpRewardTokenDetails[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            lpRewardTokenDetails[i] = _getAccountRewardTokenDetails(account, rewardTokens[i], uniV3Staker);
        }
    }

    function _getAccountRewardTokenDetails(
        address account,
        address rewardToken,
        address uniV3Staker
    ) internal view returns (LpRewardTokenDetails memory lpRewardTokenDetails) {
        lpRewardTokenDetails.tokenAddress = rewardToken;
        lpRewardTokenDetails.symbol = IERC20Detailed(rewardToken).symbol();
        lpRewardTokenDetails.decimals = IERC20Detailed(rewardToken).decimals();
        lpRewardTokenDetails.unclaimedAmount = IUniswapV3Staker(uniV3Staker).rewards(
            IERC20Minimal(rewardToken),
            account
        );
    }

    function getBasicTokenDetails(
        address[] calldata tokens
    ) external view returns (BasicTokenDetails[] memory basicTokenDetails) {
        basicTokenDetails = new BasicTokenDetails[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            basicTokenDetails[i].tokenAddress = tokens[i];
            basicTokenDetails[i].symbol = IERC20Detailed(tokens[i]).symbol();
            basicTokenDetails[i].decimals = IERC20Detailed(tokens[i]).decimals();
        }
    }

    /**
     * @notice Returns the DEX pool information
     * @return dexPoolLiquidity The uni v3 pool liquidity info in DexPoolLiquidity struct
     **/
    function _getDexPoolLiquidity(
        DataTypes.PerpetualDebtData memory localPerpetualDebt
    ) internal view returns (DexPoolLiquidity memory dexPoolLiquidity) {
        address dexPoolAddress = localPerpetualDebt.dexOracle.dex.poolAddress;

        // set pool address & fee
        dexPoolLiquidity.poolAddress = dexPoolAddress;
        dexPoolLiquidity.fee = localPerpetualDebt.dexOracle.dex.fee;

        // check if moneyIsToken0
        bool moneyIsToken0 = localPerpetualDebt.dexOracle.dex.moneyIsToken0;
        dexPoolLiquidity.moneyIsToken0 = moneyIsToken0;

        // get money amount in external Dex Pool
        dexPoolLiquidity.moneyTokenLiquidity = localPerpetualDebt.money.balanceOf(dexPoolAddress);

        // get zToken amount in external Dex Pool
        dexPoolLiquidity.zTokenLiquidity = localPerpetualDebt.zToken.balanceOf(dexPoolAddress);

        // Correct for LP fees
        (uint128 token0amount, uint128 token1amount) = IUniswapV3PoolState(dexPoolAddress).protocolFees();
        dexPoolLiquidity.moneyTokenLiquidity -= moneyIsToken0 ? uint256(token0amount) : uint256(token1amount);
        dexPoolLiquidity.zTokenLiquidity -= moneyIsToken0 ? uint256(token1amount) : uint256(token0amount);
    }

    function _getGuild(address addressesProvider) internal view returns (IGuild) {
        return IGuild(IGuildAddressesProvider(addressesProvider).getGuild());
    }

    function _getSpotPrice(address addressesProvider, address asset) internal view returns (uint256) {
        return
            ICovenantPriceOracle(IGuildAddressesProvider(addressesProvider).getPriceOracle()).getAssetPrice(
                asset,
                DataTypes.PriceContext.FRONTEND
            );
    }

    function _getLiquidationTriggerPrice(address addressesProvider, address asset) internal view returns (uint256) {
        return
            ICovenantPriceOracle(IGuildAddressesProvider(addressesProvider).getPriceOracle()).getAssetPrice(
                asset,
                DataTypes.PriceContext.LIQUIDATION_TRIGGER
            );
    }

    function _getMaxCollateralWithdrawalAmount(
        IGuild guild,
        address asset,
        address user,
        IGuild.UserAccountDataStruct memory userAccountData
    ) internal view returns (uint256 maxCollateralWithdraw) {
        //calculate how much collateral value user can withdraw
        //apply a time buffer (to ensure quote is valid for QUOTE_TIME_BUFFER seconds)
        uint256 totalCollateralNeededInBaseCurrency = (userAccountData.ltv > 0)
            ? userAccountData.totalDebtNotionalInBaseCurrency.percentDiv(userAccountData.ltv).rayMul(
                _quoteBufferFactor(guild)
            )
            : 0; //needed for underwritting purposes....
        uint256 availableCollateralWithdrawalsInBaseCurrency = (userAccountData.totalCollateralInBaseCurrency >
            totalCollateralNeededInBaseCurrency)
            ? userAccountData.totalCollateralInBaseCurrency - totalCollateralNeededInBaseCurrency
            : 0;

        //get collateral price in money units
        uint256 assetPrice = ICovenantPriceOracle(IGuildAddressesProvider(guild.ADDRESSES_PROVIDER()).getPriceOracle())
            .getAssetPrice(asset, DataTypes.PriceContext.BORROW);

        //convert available collatearl withdrawal to its own decimal unit
        uint256 collateralUnits = 10 ** IERC20Detailed(asset).decimals();
        uint256 availableCollateralWithdrawals = availableCollateralWithdrawalsInBaseCurrency.mul(collateralUnits).div(
            assetPrice
        );

        //get how much collateral user has in guild
        maxCollateralWithdraw = guild.getCollateralBalanceOf(user, asset);

        //return lower of both
        if (maxCollateralWithdraw > availableCollateralWithdrawals) {
            maxCollateralWithdraw = availableCollateralWithdrawals;
        }

        return maxCollateralWithdraw;
    }

    function _quoteBufferFactor(IGuild guild) internal view returns (uint256 bufferFactor) {
        DataTypes.PerpetualDebtData memory localPerpetualDebt = guild.getPerpetualDebt();
        uint256 spotPrice = _getSpotPrice(address(guild.ADDRESSES_PROVIDER()), address(localPerpetualDebt.zToken));
        uint256 notionalPrice = localPerpetualDebt.getNotionalPriceGivenAssetPrice(spotPrice);
        uint256 perpDebtBeta = guild.getPerpetualDebt().beta;

        //Get estimated rate per second (in RAY)
        int256 logRate = DebtMath.calculateApproxRate(perpDebtBeta, notionalPrice);
        //Get estimated factor
        bufferFactor = DebtMath.calculateApproxNotionalUpdate(logRate, QUOTE_TIME_BUFFER);
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

import {OracleLibrary} from "../../../dependencies/uniswap-v3-periphery/libraries/OracleLibrary.sol";
import {IUniswapV3Factory} from "../../../dependencies/uniswap-v3-core/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "../../../dependencies/uniswap-v3-core/interfaces/IUniswapV3Pool.sol";
import {IERC20Detailed} from "../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {TickMath} from "../../../dependencies/uniswap-v3-core/libraries/TickMath.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {X96Math} from "../math/X96Math.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";

/**
 * @title Uniswap v3 Dex Oracle Logic library
 * @author Covenant Labs
 * @notice Implements the logic to read current prices from Uniswap V3 Dexs for internal Guild purposes
 * @dev prices are returned with RAY decimal units (vs uniswap convention of quote token decimal units)
 */

library DexOracleLogic {
    using WadRayMath for uint256;

    /**
     * @notice Initializes a DexOracle structure
     * @param dexOracle The dexOracle object
     * @param assetTokenAddress The address of the underlying asset token contract (zToken)
     * @param moneyAddress The address of the money token on which the debt is denominated in
     * @param fee The fee of the pool
     **/
    function init(
        DataTypes.DexOracleData storage dexOracle,
        address dexFactory,
        address assetTokenAddress,
        address moneyAddress,
        uint24 fee
    ) internal {
        require(dexOracle.dex.token0 == address(0), Errors.DEX_ORACLE_ALREADY_INITIALIZED);
        dexOracle.dexFactory = dexFactory;

        //initialize pool info
        dexOracle.dex.token0 = assetTokenAddress;
        dexOracle.dex.token1 = moneyAddress;
        dexOracle.dex.fee = fee;

        //keep track on whether token0 is the money token
        dexOracle.dex.moneyIsToken0 = (dexOracle.dex.token1 < dexOracle.dex.token0);
        if (dexOracle.dex.moneyIsToken0)
            (dexOracle.dex.token0, dexOracle.dex.token1) = (dexOracle.dex.token1, dexOracle.dex.token0);

        //initialize the oracle historical price.  Assumes the dex pool has already be created, otherwise reverts
        address poolAddress = IUniswapV3Factory(dexFactory).getPool(
            dexOracle.dex.token0,
            dexOracle.dex.token1,
            dexOracle.dex.fee
        );
        require(poolAddress != address(0), Errors.DEX_ORACLE_POOL_NOT_INITIALIZED);
        dexOracle.dex.poolAddress = poolAddress;

        //perform initial oracle consult, to intialize TWAP trackers
        uint32[] memory secondsAgos = new uint32[](1);
        secondsAgos[0] = 0; //get current values
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(poolAddress).observe(secondsAgos);
        dexOracle.lastTWAPTickCumulative = tickCumulatives[0];
        dexOracle.lastTWAPObservationTime = block.timestamp;
    }

    //@Notice - does not require DEX cardinality greater than 1.  Variables are tracked internally
    //@Notice - relies on code found in @uniswap/v3-core/libraries/OracleLibrary.sol
    //@Notice - price returned with 27 DECIMAL precision (instead of money precision)
    //@dev - Given current implementation of UniswapV3 observe function, the TWAP below is resistant to flash loans
    //@dev - The reason for this is, Uniswap records only one observation per block, which happens the first time a tick is crossed
    //@dev - With a flash loan, multiple ticks are crossed - but these extreme values do not affect the function below.
    //@dev - The TWAP IS AFFECTED by price manipulation ACROSS blocks.
    //(ie, between the first recording in a block, and the first recording in the next block)
    function updateTwapPrice(DataTypes.DexOracleData storage dexOracle)
        internal
        returns (uint256 assetPrice_, uint256 elapsedTime_)
    {
        uint160 sqrtPriceX96;
        int56 currentTickCumulative;
        uint256 currentObservationTime = block.timestamp;
        bool updateTWAP = (currentObservationTime > dexOracle.lastTWAPObservationTime);

        //get sqrtPrice and elapsedTime
        if (updateTWAP) {
            elapsedTime_ = currentObservationTime - dexOracle.lastTWAPObservationTime;

            //get current cumulators
            uint32[] memory secondsAgos = new uint32[](1);
            secondsAgos[0] = 0; //get current values
            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(dexOracle.dex.poolAddress).observe(secondsAgos);
            currentTickCumulative = tickCumulatives[0];

            //calculate TWAP tick since last observation (extracted from Uniswap core v3 OracleLibrary)
            int56 tickCumulativesDelta = currentTickCumulative - dexOracle.lastTWAPTickCumulative;

            int24 arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(elapsedTime_)));
            // Always round to negative infinity
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(elapsedTime_)) != 0))
                arithmeticMeanTick--;

            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);

            //convert to price with correct units
            assetPrice_ = _getPriceFromSqrtX96(dexOracle.dex, sqrtPriceX96);

            //save new observations
            dexOracle.lastTWAPTickCumulative = currentTickCumulative;
            dexOracle.lastTWAPObservationTime = currentObservationTime;
            dexOracle.twapPrice = assetPrice_;
            dexOracle.lastTWAPTimeDelta = elapsedTime_;
        } else {
            elapsedTime_ = 0;
            assetPrice_ = dexOracle.twapPrice;
        }

        return (assetPrice_, elapsedTime_);
    }

    //@Dev - price returned with RAY 27 DECIMAL precision (instead of money precision)
    function _getPriceFromSqrtX96(DataTypes.DexPoolData storage dex, uint160 sqrtRatioX96)
        internal
        view
        returns (uint256 price_)
    {
        uint256 baseDecimals = 27;
        if (dex.moneyIsToken0) {
            price_ = X96Math.getPriceFromSqrtX96(dex.token0, dex.token1, sqrtRatioX96);
            baseDecimals -= IERC20Detailed(dex.token0).decimals();
        } else {
            price_ = X96Math.getPriceFromSqrtX96(dex.token1, dex.token0, sqrtRatioX96);
            baseDecimals -= IERC20Detailed(dex.token1).decimals();
        }
        price_ *= 10**baseDecimals;
        return price_;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {ILiabilityToken} from "../../../interfaces/ILiabilityToken.sol";
import {IAssetToken} from "../../../interfaces/IAssetToken.sol";
import {IFeeReceiver} from "../../../interfaces/IFeeReceiver.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {DebtMath} from "../math/DebtMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";
import {DexOracleLogic} from "./DexOracleLogic.sol";
import {PerpetualDebtConfiguration} from "../configuration/PerpetualDebtConfiguration.sol";
import {UniswapV3OracleProxy} from "../../oracle/proxies/UniswapV3OracleProxy.sol";
import {ICovenantPriceOracle} from "../../../interfaces/ICovenantPriceOracle.sol";

/**
 * @title Perpetual Debt Logic library
 * @author Covenant Labs
 * @notice Implements the logic to update the perpetual debt state
 */

library PerpetualDebtLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using DexOracleLogic for DataTypes.DexOracleData;
    using PerpetualDebtConfiguration for DataTypes.PerpDebtConfigurationMap;

    // Number of seconds in a year (given 365.25 days)
    uint256 internal constant ONE_YEAR = 31557600;

    event Refinance(uint256 refinanceBlockNumber, uint256 elapsedTime, uint256 rate, uint256 refinanceMultiplier);

    //TODO add descriptions in Iguild
    event Mint(address indexed user, address indexed onBehalfOf, uint256 assetAmount, uint256 liabilityAmount);
    event Burn(address indexed user, address indexed onBehalfOf, uint256 assetAmount, uint256 liabilityAmount);
    event BurnAndDistribute(
        address indexed assetUser,
        address indexed liabilityUser,
        uint256 assetAmount,
        uint256 liabilityAmount
    );

    /**
     * @notice Initializes a perpetual debt.
     * @param params inititialization structure, which includes:
     * perpDebt The perpetual debt object
     * assetTokenAddress The address of the underlying asset token contract (zToken)
     * liabilityTokenAddress The address of the underlying liability token contract (dToken)
     * moneyAddress The address of the money token on which the debt is denominated in
     * duration The duration, in seconds, of the perpetual debt
     * notionalPriceLimitMax Maximum price used for refinance purposes
     * notionalPriceLimitMin Minimum price used for refinance purposes
     * dexFactory Uniswap v3 factory address
     * dexFee Uniswap v3 pool fee (to identify pool used for refinance oracle purposes)
     **/
    function init(DataTypes.PerpetualDebtData storage perpDebt, DataTypes.ExecuteInitPerpetualDebtParams memory params)
        internal
    {
        require(address(perpDebt.zToken) == address(0), Errors.PERPETUAL_DEBT_ALREADY_INITIALIZED);

        // Set perpetual debt info
        // @dev - Note, that FeeAddresses are not initialized
        perpDebt.zToken = IAssetToken(params.assetTokenAddress);
        perpDebt.dToken = ILiabilityToken(params.liabilityTokenAddress);
        perpDebt.money = IERC20(params.moneyAddress);
        perpDebt.beta = WadRayMath.ray() / params.duration;
        perpDebt.lastRefinance = block.number;

        updateNotionalPriceLimit(perpDebt, params.notionalPriceLimitMax, params.notionalPriceLimitMin);

        //Init Uniswap DEX + internal (refinance) oracle
        perpDebt.dexOracle.init(params.dexFactory, params.assetTokenAddress, params.moneyAddress, params.dexFee);
        perpDebt.dexOracle.updateTwapPrice();

        //Init external (pricing) oracle
        //Create a zToken price proxy, and add to external CovenantOracle
        //for pricing purposes across price contexts
        address zTokenOracleProxy = address(
            new UniswapV3OracleProxy(
                params.assetTokenAddress,
                params.moneyAddress,
                perpDebt.dexOracle.dex.poolAddress,
                1
            )
        );
        // add zToken and verify oracle money matches
        // @dev - these checks are done within setAssetPriceSources
        address[] memory sources = new address[](1);
        sources[0] = zTokenOracleProxy;
        address[] memory assets = new address[](1);
        assets[0] = params.assetTokenAddress;
        ICovenantPriceOracle(params.oracle).setAssetPriceSources(assets, sources);
    }

    /**
     * @notice Updates notional price limit
     * @param notionalPriceLimitMax Maximum price used for refinance purposes
     * @param notionalPriceLimitMin Minimum price used for refinance purposes
     **/
    function updateNotionalPriceLimit(
        DataTypes.PerpetualDebtData storage perpDebt,
        uint256 notionalPriceLimitMax,
        uint256 notionalPriceLimitMin
    ) internal {
        require(notionalPriceLimitMax < 2 * WadRayMath.ray(), Errors.PRICE_LIMIT_OUT_OF_BOUNDS);
        require(notionalPriceLimitMin <= notionalPriceLimitMax, Errors.PRICE_LIMIT_ERROR);
        perpDebt.notionalPriceMax = notionalPriceLimitMax; //[ray]
        perpDebt.notionalPriceMin = notionalPriceLimitMin; //[ray]
    }

    /**
     * @notice Updates the protocol service fee address where service fees are deposited
     * @param newAddress new protocol service fee address
     * @dev if address == 0, then no fees are deposited
     **/
    function updateProtocolServiceFeeAddress(DataTypes.PerpetualDebtData storage perpDebt, address newAddress)
        internal
    {
        perpDebt.protocolServiceFeeAddress = newAddress;
        //@dev - checks newAddress can accept deposits from Guild (reverts otherwise) - except if address = 0
        if (address(newAddress) != address(0)) IFeeReceiver(newAddress).depositFromGuild(perpDebt.zToken, 0);
    }

    /**
     * @notice Updates the protocol mint fee address where mint fees are deposited
     * @param newAddress new protocol mint fee address
     * @dev if address == 0, then no fees are deposited
     **/
    function updateProtocolMintFeeAddress(DataTypes.PerpetualDebtData storage perpDebt, address newAddress) internal {
        perpDebt.protocolMintFeeAddress = newAddress;
        //@dev - checks newAddress can accept deposits from Guild (reverts otherwise) - except if address = 0
        if (address(newAddress) != address(0)) IFeeReceiver(newAddress).depositFromGuild(perpDebt.zToken, 0);
    }

    /**
     * @notice Updates the protocol distribution fee address where distribution fees are deposited
     * @param newAddress new protocol distribution fee address
     * @dev if address == 0, then no fees are deposited
     **/
    function updateProtocolDistributionFeeAddress(DataTypes.PerpetualDebtData storage perpDebt, address newAddress)
        internal
    {
        perpDebt.protocolDistributionFeeAddress = newAddress;
        //@dev - checks newAddress can accept deposits from Guild (reverts otherwise) - except if address = 0
        if (address(newAddress) != address(0)) IFeeReceiver(newAddress).depositFromGuild(perpDebt.zToken, 0);
    }

    /**
     * @notice Updates the protocol swap fee address where swap fees are deposited
     * @param newAddress new protocol swap fee address
     * @dev if address == 0, then no fees are deposited
     **/
    function updateProtocolSwapFeeAddress(DataTypes.PerpetualDebtData storage perpDebt, address newAddress) internal {
        perpDebt.protocolSwapFeeAddress = newAddress;
        //@dev - checks newAddress can accept deposits from Guild (reverts otherwise) - except if address = 0
        if (address(newAddress) != address(0)) IFeeReceiver(newAddress).depositFromGuild(perpDebt.zToken, 0);
    }

    function getMoney(DataTypes.PerpetualDebtData storage perpDebt) internal view returns (IERC20) {
        return perpDebt.money;
    }

    function getAsset(DataTypes.PerpetualDebtData storage perpDebt) internal view returns (IAssetToken) {
        return perpDebt.zToken;
    }

    function getLiability(DataTypes.PerpetualDebtData storage perpDebt) internal view returns (ILiabilityToken) {
        return perpDebt.dToken;
    }

    function getAssetGivenLiability(DataTypes.PerpetualDebtData storage perpDebt, uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 assetFactor = perpDebt.zToken.getNotionalFactor();
        uint256 liabilityFactor = perpDebt.dToken.getNotionalFactor();

        return amount.rayMul(liabilityFactor.rayDiv(assetFactor));
    }

    function getLiabilityGivenAsset(DataTypes.PerpetualDebtData storage perpDebt, uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 assetFactor = perpDebt.zToken.getNotionalFactor();
        uint256 liabilityFactor = perpDebt.dToken.getNotionalFactor();

        return amount.rayMul(assetFactor.rayDiv(liabilityFactor));
    }

    function getNotionalPriceGivenAssetPrice(DataTypes.PerpetualDebtData memory perpDebt, uint256 zPrice)
        internal
        view
        returns (uint256 notionalPrice)
    {
        return zPrice.rayDiv(perpDebt.zToken.getNotionalFactor());
    }

    //@DEV meant to be run only offchain.  Checks current DEX price each time
    //returns estimate APY given current zPrice
    //apy_ in 10000 units.  ie, 10000 = 0% return in a year.
    function getAPYgivenAssetPrice(DataTypes.PerpetualDebtData memory perpDebt, uint256 zPrice)
        internal
        view
        returns (uint256 apy_)
    {
        //convert to Notional Price (RAY)
        uint256 notionalPrice = zPrice.rayDiv(perpDebt.zToken.getNotionalFactor());

        //Get estimated rate per second (in RAY)
        int256 logRate = DebtMath.calculateApproxRate(perpDebt.beta, notionalPrice);
        uint256 rate = DebtMath.calculateApproxNotionalUpdate(logRate, 1);

        apy_ = rate.rayPow(ONE_YEAR); //calculate 1 year compounding
        apy_ = (apy_ * 10000) / (WadRayMath.ray()); //convert to percent decimal precision

        return apy_;
    }

    struct ExecuteRefinanceLocalVars {
        DataTypes.PerpDebtConfigurationMap localPerpDebtConfig;
        IAssetToken zToken;
        uint256 zPrice;
        uint256 zNotionalFactor;
        uint256 elapsedTime;
        bool perpDebtFrozen;
        bool perpDebtPaused;
        uint256 notionalPrice;
        int256 rate;
        uint256 updateZMultiplier;
        uint256 updateDMultiplier;
        address protocolServiceFeeAddress;
        uint256 protocolServiceFee;
        uint256 periodGrowth;
        uint256 periodFee;
        uint256 zProtocolFee;
    }

    function refinance(DataTypes.PerpetualDebtData storage perpDebt) internal {
        if (block.number > perpDebt.lastRefinance) {
            ExecuteRefinanceLocalVars memory vars;

            //pass to memory
            vars.localPerpDebtConfig = perpDebt.configuration;

            //calculate TWAP Price since last update (needs to be done in same block as refinance below)
            (vars.zPrice, vars.elapsedTime) = perpDebt.dexOracle.updateTwapPrice();

            //check if debt is paused or frozen
            (vars.perpDebtFrozen, vars.perpDebtPaused) = vars.localPerpDebtConfig.getFlags();

            //Don't refinance debt if it is frozen or paused
            //@dev - note that even if the debt is frozen or paused, updateTwapPrice() is still called
            //This is done to discard all price history while the debt is frozen  or paused
            //Once the debt is unfrozen/unpaused, then interest will start accruing with the price as of that moment
            if (!(vars.perpDebtFrozen || vars.perpDebtPaused)) {
                vars.zToken = perpDebt.zToken;
                vars.zNotionalFactor = vars.zToken.getNotionalFactor();

                //convert to Notional Price (with limits)
                //@dev do this before converting zPrice to a Notional Price to catch overflow errors
                if (vars.zPrice > perpDebt.notionalPriceMax.rayMul(vars.zNotionalFactor)) {
                    vars.notionalPrice = perpDebt.notionalPriceMax;
                } else {
                    if (vars.zPrice < perpDebt.notionalPriceMin.rayMul(vars.zNotionalFactor)) {
                        vars.notionalPrice = perpDebt.notionalPriceMin;
                    } else {
                        //convert to Notional Price (within limits already applied)
                        vars.notionalPrice = vars.zPrice.rayDiv(vars.zNotionalFactor);
                    }
                }

                // calculate accrual rate for zTokens
                vars.rate = DebtMath.calculateApproxRate(perpDebt.beta, vars.notionalPrice);
                vars.updateZMultiplier = DebtMath.calculateApproxNotionalUpdate(vars.rate, vars.elapsedTime);

                // calculate accrual rate for dTokens
                // @Dev - This implementation makes dTokens accrue interest faster than
                // zTokens (if debtServiceFee>0).  The notional difference is owned by the Guild.
                vars.updateDMultiplier = vars.updateZMultiplier;
                vars.protocolServiceFeeAddress = perpDebt.protocolServiceFeeAddress;
                // if interest rate is negative, then fee is zero
                if ((vars.updateZMultiplier > WadRayMath.ray()) && (vars.protocolServiceFeeAddress != address(0))) {
                    vars.protocolServiceFee = vars.localPerpDebtConfig.getProtocolServiceFee();
                    if (vars.protocolServiceFee > 0) {
                        // @dev ProtocolServiceFees are proportional to the interest accrued
                        // so, if the zToken interest in a period can be depicted as (1+x)
                        // then, once fees d are added, the interest will be =(1+x)(1+xd).
                        // In section below, x = periodGrowth, d = protocolServiceFee, xd = periodFee
                        // After sections below, the following will be true
                        // dTokenNotionalAfter = dTokenNotionalBefore * (1+x) * (1+xd)
                        // userZTokenNotionalAfter = dTokenNotionalBefore * (1+x)
                        // additional protocol dTokenNotional = dTokenNotionalBefore * (1+x) * xd  (the fee)

                        // calculate additional amount of zTokens for the treasury (factor xd above)
                        vars.periodGrowth = (vars.updateZMultiplier - WadRayMath.ray());
                        vars.periodFee = vars.periodGrowth.percentMul(vars.protocolServiceFee);
                        vars.zProtocolFee = (vars.zToken.totalSupply()).rayMul(vars.periodFee);

                        vars.zToken.mint(vars.protocolServiceFeeAddress, vars.zProtocolFee);
                        IFeeReceiver(vars.protocolServiceFeeAddress).depositFromGuild(vars.zToken, vars.zProtocolFee);

                        // calculate additional growth on borrower debt to account for protocol fee
                        vars.updateDMultiplier = vars.updateDMultiplier.rayMul(WadRayMath.ray() + vars.periodFee);
                    }
                }

                //update assets and liabilities notional multipliers
                perpDebt.zToken.updateNotionalFactor(vars.updateZMultiplier);
                perpDebt.dToken.updateNotionalFactor(vars.updateDMultiplier);

                //emit message
                emit Refinance(
                    block.number,
                    vars.elapsedTime,
                    uint256(int256(WadRayMath.ray()) + vars.rate),
                    vars.updateZMultiplier
                );
            }

            //update last refinance block number
            perpDebt.lastRefinance = block.number;
        }
    }

    /**
     * @dev Mint perpetual debt
     * @dev Function takes zToken amount to be minted as input parameter, and will mint an equivalent amount of dTokens
     * @dev such that zToken notional minted == dToken notional minted (ie, notionals are conserved)
     * @param user address of user that is minting zTokens (and who will own the asset)
     * @param onBehalfOf address of user that is minting dTokens (and who will own liability)
     * @param amount [wad] base amount of zTokens being minted to the user
     **/
    function mint(
        DataTypes.PerpetualDebtData storage perpDebt,
        address user,
        address onBehalfOf,
        uint256 amount
    ) internal {
        mintCore(
            perpDebt,
            user,
            onBehalfOf,
            amount,
            perpDebt.configuration.getProtocolMintFee(),
            perpDebt.protocolMintFeeAddress
        );
    }

    /**
     * @dev Mint perpetual debt during a
     * @dev Function takes zToken amount to be minted as input parameter, and will mint an equivalent amount of dTokens
     * @dev such that zToken notional minted == dToken notional minted (ie, notionals are conserved)
     * @param user address of user that is minting zTokens (and who will own the asset)
     * @param onBehalfOf address of user that is minting dTokens (and who will own liability)
     * @param amount [wad] base amount of zTokens being minted to the user
     **/
    function swapMint(
        DataTypes.PerpetualDebtData storage perpDebt,
        address user,
        address onBehalfOf,
        uint256 amount
    ) internal {
        mintCore(
            perpDebt,
            user,
            onBehalfOf,
            amount,
            perpDebt.configuration.getProtocolSwapFee(),
            perpDebt.protocolSwapFeeAddress
        );
    }

    /**
     * @dev Mint perpetual debt (with fee specified)
     * @dev Function takes zToken amount to be minted as input parameter, and will mint an equivalent amount of dTokens
     * @dev such that zToken notional minted == dToken notional minted (ie, notionals are conserved)
     * @param user address of user that is minting zTokens (and who will own the asset)
     * @param onBehalfOf address of user that is minting dTokens (and who will own liability)
     * @param amount [wad] base amount of zTokens being minted to the user
     * @param mintFee protocol mint fee
     * @param mintFeeAddress protocol mint fee address
     **/
    function mintCore(
        DataTypes.PerpetualDebtData storage perpDebt,
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 mintFee,
        address mintFeeAddress
    ) private {
        // mint zTokens
        if ((mintFeeAddress != address(0)) && (mintFee > 0)) {
            //allocates protocolMintFee BPS of zTokens minted to the treasury
            uint256 protocolMintAmount = amount.percentMul(mintFee);
            //fails if protocolMintAmount > amount
            IAssetToken zToken = perpDebt.zToken;
            zToken.mint(user, amount - protocolMintAmount);
            zToken.mint(mintFeeAddress, protocolMintAmount);
            IFeeReceiver(mintFeeAddress).depositFromGuild(zToken, protocolMintAmount);
        } else {
            perpDebt.zToken.mint(user, amount);
        }

        // mint dTokens
        // @dev conserve notional amounouts, using zToken decimal space
        uint256 dMintAmount = getLiabilityGivenAsset(perpDebt, amount);

        perpDebt.dToken.mint(user, onBehalfOf, dMintAmount);
        emit Mint(user, onBehalfOf, amount, dMintAmount);
    }

    /**
     * @dev Burn perpetual debt
     * @dev Function takes zToken amount to be burned as input parameter, and will burn an equivalent amount of dTokens
     * @dev such that zToken notional minted == dToken notional burned (ie, notionals are conserved)
     * @param user address of user that is burning zTokens (equal notional of asset and liabilities are burned)
     * @param onBehalfOf address of user that is burning dTokens (equal notional of asset and liabilities are burned)
     * @param amount [wad] notional amount of zTokens being burned by user.  User has to have right amount of asset and liability in wallet for a successfull burn
     **/
    function burn(
        DataTypes.PerpetualDebtData storage perpDebt,
        address user,
        address onBehalfOf,
        uint256 amount
    ) internal {
        // @dev - burn according to lowest precision space
        uint256 assetFactor = perpDebt.zToken.getNotionalFactor();
        uint256 liabilityFactor = perpDebt.dToken.getNotionalFactor();
        uint256 dBurnAmount;

        uint256 assetToLiabilityFactor = assetFactor.rayDiv(liabilityFactor);

        // Calculate amount of dToken that will be burned (without leaving dust)
        if (assetToLiabilityFactor <= WadRayMath.ray()) {
            dBurnAmount = amount.rayMul(assetToLiabilityFactor);
        } else {
            //execute burn in asset space, and then move result to debt base
            //@dev this corrects rounding errors given assets have a smaller decimal precision vs debt when assetToLiabilityFactor > RAY
            uint256 accountDebtBalance = perpDebt.dToken.balanceOf(onBehalfOf);
            uint256 accountZTokenEquivalence = accountDebtBalance.rayDiv(assetToLiabilityFactor);
            require(accountZTokenEquivalence >= amount, Errors.INSUFFICIENT_BALANCE_TO_BURN);

            //calculate burn amount in asset space
            uint256 newAccountDebtBalance = (accountZTokenEquivalence - amount).rayMul(assetToLiabilityFactor);
            dBurnAmount = accountDebtBalance - newAccountDebtBalance;
        }

        // Burn calculated ammounts
        perpDebt.zToken.burn(user, amount);
        perpDebt.dToken.burn(onBehalfOf, dBurnAmount);

        emit Burn(user, onBehalfOf, amount, dBurnAmount);
    }

    /**
     * @dev burn liabilityUser liabilities (dTokens), using assetUser's assets (zTokens).
     * @dev if assets cannot cover liabilities, then deficit is distributed to all remaining assets
     * @dev if asset surplus remains, then surplus is distributed to all remaining assets
     * @dev Notional equivalence between assets and liabilities is maintained
     * @param assetUser address of user paying zTokens to burn and distribute
     * @param liabilityUser address of user whose liabilities are burned (onBehalfOf)
     * @param assetAmount [wad] base amount of asset from assetUser removed from assetUser's wallet
     * @param liabilityAmount [wad] base amount of liabilities burned from liabilityUser's wallet
     **/
    function burnAndDistribute(
        DataTypes.PerpetualDebtData storage perpDebt,
        address assetUser,
        address liabilityUser,
        uint256 assetAmount,
        uint256 liabilityAmount
    ) internal {
        // Calculate amounts to burn
        IAssetToken zToken = perpDebt.zToken;
        ILiabilityToken dToken = perpDebt.dToken;
        uint256 maxLiabilityBurnAmount = dToken.balanceOf(liabilityUser);
        uint256 liabilityAmountNotional = dToken.baseToNotional(liabilityAmount);
        uint256 assetAmountNotional = zToken.baseToNotional(assetAmount);

        // Don't burn more than max debt
        if (maxLiabilityBurnAmount < liabilityAmount) liabilityAmount = maxLiabilityBurnAmount;

        //Burn asset & liability
        zToken.burn(assetUser, assetAmount);
        dToken.burn(liabilityUser, liabilityAmount);

        // If there is a positive distribution, check if there is a distribution fee and calculate amount to be charged in zTokens
        // @dev distribution fee charged on % of positive distribution
        // @dev Fee is minted directly to protocolAddress.
        if (assetAmountNotional > liabilityAmountNotional) {
            address protocolDistributionFeeAddress = perpDebt.protocolDistributionFeeAddress;
            if (protocolDistributionFeeAddress != address(0)) {
                uint256 protocolDistributionFee = perpDebt.configuration.getProtocolDistributionFee();
                if (protocolDistributionFee > 0) {
                    uint256 assetFeeAmount = zToken.notionalToBase(
                        (assetAmountNotional - liabilityAmountNotional).percentMul(protocolDistributionFee)
                    );
                    if (assetFeeAmount > 0) {
                        zToken.mint(protocolDistributionFeeAddress, assetFeeAmount);
                        IFeeReceiver(protocolDistributionFeeAddress).depositFromGuild(zToken, assetFeeAmount);
                    }
                }
            }
        }

        //Distribute surplus or deficit to ensure asset / liability notionals match
        //@dev distributeFactor in RAY
        uint256 zTokenTotalNotional = zToken.totalNotionalSupply();
        uint256 dTokenTotalNotional = dToken.totalNotionalSupply();
        if (zTokenTotalNotional > 0 && dTokenTotalNotional > 0) {
            uint256 distributeFactor = dTokenTotalNotional.wadToRay().wadDiv(zTokenTotalNotional);
            zToken.updateNotionalFactor(distributeFactor);
        }

        emit BurnAndDistribute(assetUser, liabilityUser, assetAmountNotional, liabilityAmountNotional);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {WadRayMath} from "./WadRayMath.sol";

/**
 * @title DebtMath library
 * @author Covenant Labs
 * @notice Provides approximations for Perpetual Debt calculations
 */
library DebtMath {
    using WadRayMath for uint256;

    //returns approximation of rate = -beta * ln(price)
    //Taylor expansion as per whitepaper
    function calculateApproxRate(uint256 _beta, uint256 _price) internal pure returns (int256 rate_) {
        //separate calculation depending on whether (1-_price) is positive or negative
        if (_price <= WadRayMath.ray()) {
            uint256 rate1 = WadRayMath.ray() - _price;
            uint256 rate2 = rate1.rayMul(rate1);
            uint256 rate3 = rate2.rayMul(rate1);
            uint256 rate4 = rate2.rayMul(rate2);
            uint256 rate5 = rate3.rayMul(rate2);
            uint256 rate6 = rate3.rayMul(rate3);

            rate1 = rate1 + rate2 / 2 + rate3 / 3 + rate4 / 4 + rate5 / 5 + rate6 / 6;
            rate_ = int256(rate1.rayMul(_beta));
        } else {
            uint256 rate1 = _price - WadRayMath.ray();
            uint256 rate2 = rate1.rayMul(rate1);
            uint256 rate3 = rate2.rayMul(rate1);
            uint256 rate4 = rate2.rayMul(rate2);
            uint256 rate5 = rate3.rayMul(rate2);
            uint256 rate6 = rate3.rayMul(rate3);

            rate1 = rate1 - rate2 / 2 + rate3 / 3 - rate4 / 4 + rate5 / 5 - rate6 / 6;
            rate_ = -int256(rate1.rayMul(_beta));
        }
    }

    //Taylor expansion to calculate compounding rate update as per whitepaper
    function calculateApproxNotionalUpdate(int256 _rate, uint256 _timeDelta)
        internal
        pure
        returns (uint256 updateMultiplier_)
    {
        _rate = _rate * int256(_timeDelta);
        if (_rate >= 0) {
            uint256 rate1 = uint256(_rate);
            uint256 rate2 = rate1.rayMul(rate1) / 2;
            uint256 rate3 = rate2.rayMul(rate1) / 3;
            updateMultiplier_ = WadRayMath.ray() + rate1 + rate2 + rate3;
        } else {
            uint256 rate1 = uint256(-_rate);
            uint256 rate2 = rate1.rayMul(rate1) / 2;
            uint256 rate3 = rate2.rayMul(rate1) / 3;
            updateMultiplier_ = WadRayMath.ray() - rate1 + rate2 - rate3;
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

// SPDX-License-Identifier: MIT
// Notice: license change Jan 27, 2023
pragma solidity 0.8.17;

/**
 * @title WadRayMath library
 * @author Aave (not rayPow)
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) {
        return RAY;
    }

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return HALF_RAY;
    }

    function halfWad() internal pure returns (uint256) {
        return HALF_WAD;
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
                revert(0, 0)
            }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     */
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
                b := add(b, 1)
            }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     */
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
                revert(0, 0)
            }
        }
    }

    /**
     * @dev Calculates x to the power of n (x^n)
     * @dev Power calculated through a loop of binary powers.  Not optimized.
     * @param x ray
     * @param n unsigned integer
     * @return z x^n
     **/
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC20Detailed} from "../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {FullMath} from "../../../dependencies/uniswap-v3-core/libraries/FullMath.sol";

/**
 * @title X96Math library
 * @author Covenant Labs
 * @notice Math conversion for sqrt X96 ratios used by Uniswap
 */
library X96Math {
    //@Dev - asset price returned in money units (with money Decimal places)
    function getPriceFromSqrtX96(
        address moneyToken,
        address assetToken,
        uint160 sqrtRatioX96
    ) internal view returns (uint256 price_) {
        uint256 baseDecimals = IERC20Detailed(assetToken).decimals();
        uint256 baseAmount = 10**baseDecimals;
        return quoteFromSqrtPriceX96(baseAmount, sqrtRatioX96, assetToken, moneyToken);
    }

    //@dev code from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/OracleLibrary.sol, getQuoteaTick function
    // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
    function quoteFromSqrtPriceX96(
        uint256 baseAmount,
        uint160 sqrtPriceX96,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        if (sqrtPriceX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtPriceX96) * sqrtPriceX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
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
    //@dev WARNING - No additional variables can be added to preserve upgradeability of GuildStorage
    struct DexPoolData {
        address token0;
        address token1;
        uint24 fee;
        bool moneyIsToken0; //indicates whether token0 is the money token
        address poolAddress;
        // @dev WARNING - No additional variables can be added to preserve upgradeability of GuildStorage
    }

    // @dev WARNING - No additional variables can be added to preserve upgradeability of GuildStorage
    struct DexOracleData {
        address dexFactory; // Uniswap v3 factory
        DexPoolData dex; // Dex pool details
        uint256 currentPrice;
        uint256 twapPrice;
        uint256 lastTWAPObservationTime; // Timestamp of last oracle consult for TWAP price
        uint256 lastCurrentObservationTime; // Timestamp of last oracle consult for current price
        int56 lastTWAPTickCumulative; //For Uniswap v3.0 TWAP calculation
        uint256 lastTWAPTimeDelta; //recording of last time delta
        // @dev WARNING - No additional variables can be added to preserve upgradeability of GuildStorage
    }

    //@dev WARNING - No additional variables can be added to preserve upgradeability of GuildStorage
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
        //@dev WARNING - no additional variables can be added to preserve upgradeability
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
        // @dev WARNING - No additional variables can be added to preserve upgradeability of GuildStorage
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
        // @dev WARNING - No additional variables can be added to preserve upgradeability of GuildStorage
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IOracleProxy} from "../../../interfaces/IOracleProxy.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

/**
 * @title OracleProxy v1.1
 * @author Covenant Labs
 * @notice Implements the shared logic for oracle proxies
 **/

abstract contract OracleProxyCommon is IOracleProxy {
    address public immutable TOKEN0;
    address public immutable TOKEN1;

    /**
     * @notice Initializes a OracleProxy structure
     * @param tokenA The address of tokenA
     * @param tokenB The address of tokenB
     **/
    constructor(address tokenA, address tokenB) {
        // Set values
        TOKEN0 = (tokenA < tokenB) ? tokenA : tokenB;
        TOKEN1 = (tokenA < tokenB) ? tokenB : tokenA;
    }

    /// @inheritdoc IOracleProxy
    function getBaseCurrency(address asset) external view returns (address) {
        require(asset == TOKEN0 || asset == TOKEN1, Errors.ORACLE_ASSET_MISMATCH);
        if (asset == TOKEN0) {
            return TOKEN1;
        } else {
            return TOKEN0;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {OracleProxyCommon} from "./OracleProxyCommon.sol";
import {IOracleProxy} from "../../../interfaces/IOracleProxy.sol";
import {IUniswapV3OracleProxy} from "../../../interfaces/IUniswapV3OracleProxy.sol";
import {OracleLibrary} from "../../../dependencies/uniswap-v3-periphery/libraries/OracleLibrary.sol";
import {IUniswapV3Pool} from "../../../dependencies/uniswap-v3-core/interfaces/IUniswapV3Pool.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

/**
 * @title UniswapV3OracleProxy v1.1
 * @author Covenant Labs
 * @notice Implements the logic to read twap prices from Uniswap V3 Dexs
 **/

contract UniswapV3OracleProxy is OracleProxyCommon, IUniswapV3OracleProxy {
    address public immutable ORACLE_SOURCE;

    uint16 private _minCardinality;

    /**
     * @notice Initializes a CovenantPriceOracle structure
     * @param tokenA The address of one token in the oracle pair
     * @param tokenB The address of the other token in the oracle pair
     * @param oracleSource The address of the oracle price source
     * @param minCardinality The cardinality for dex observations
     **/
    constructor(
        address tokenA,
        address tokenB,
        address oracleSource,
        uint16 minCardinality
    ) OracleProxyCommon(tokenA, tokenB) {
        // Steps: Check to make sure dex is correct + Adjust cardinality
        address token0_ = IUniswapV3Pool(oracleSource).token0();
        address token1_ = IUniswapV3Pool(oracleSource).token1();
        require(
            (token0_ == tokenA && token1_ == tokenB) || (token1_ == tokenA && token0_ == tokenB),
            Errors.DEX_POOL_DOES_NOT_CONTAIN_ASSET_PAIR
        );

        // Adjust cardinality for dex pool
        require(minCardinality > 0, Errors.ORACLE_CARDINALITY_IS_ZERO);
        IUniswapV3Pool(oracleSource).increaseObservationCardinalityNext(minCardinality);

        // Set values
        ORACLE_SOURCE = oracleSource;
        _minCardinality = minCardinality;
    }

    /// @inheritdoc IOracleProxy
    function getAvgTick(
        address asset,
        uint32,
        uint32 endLookbackTime
    ) external view override returns (int24 avgTick_) {
        // Make sure the oracle contains the asset
        require((asset == TOKEN0 || asset == TOKEN1), Errors.ORACLE_ASSET_MISMATCH);

        // Check farthest lookback period for pool
        uint32 _secondsAgo = OracleLibrary.getOldestObservationSecondsAgo(ORACLE_SOURCE);
        if (endLookbackTime > 0 && _secondsAgo > 0) {
            if (_secondsAgo > endLookbackTime) {
                _secondsAgo = endLookbackTime;
            }
            (avgTick_, ) = OracleLibrary.consult(ORACLE_SOURCE, _secondsAgo);
        } else {
            //@dev - slot0.tick is less precise than slot0.sqrtPriceX96
            //@dev - however, given we have to convert to tick precision, this is good enough
            //and equivalent to floor(prictToTick(sqrtPriceX96))
            (, avgTick_, , , , , ) = IUniswapV3Pool(ORACLE_SOURCE).slot0();
        }

        // check the tokens for address sort order, and ensure in right order
        // so that cumulative tick can be added together
        address baseCurrency_ = (TOKEN0 == asset) ? TOKEN1 : TOKEN0;
        if (baseCurrency_ < asset) avgTick_ = -avgTick_;
    }

    /// @inheritdoc IUniswapV3OracleProxy
    function increaseDexCardinality(uint16 minCardinality) external override {
        require(minCardinality > _minCardinality, Errors.ORACLE_CARDINALITY_MONOTONICALLY_INCREASES);
        _minCardinality = minCardinality;
        IUniswapV3Pool(ORACLE_SOURCE).increaseObservationCardinalityNext(minCardinality);
    }

    /// @inheritdoc IUniswapV3OracleProxy
    function getDexCardinality() external view override returns (uint16) {
        return _minCardinality;
    }
}