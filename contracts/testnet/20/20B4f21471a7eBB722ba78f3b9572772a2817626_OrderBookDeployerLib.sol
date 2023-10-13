// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title Minimal ERC20 interface for lighter
/// @notice Contains a subset of the full ERC20 interface that is used in lighter
interface IERC20Minimal {
    /// @notice Returns the balance of the account provided
    /// @param account The account to get the balance of
    /// @return balance The balance of the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers given amount of tokens from caller to the recipient
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return success Returns true for a successful transfer, false for unsuccessful
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Transfers given amount of tokens from the sender to the recipient
    /// @param sender The sender of the transfer
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return success Returns true for a successful transfer, false for unsuccessful
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /// @return decimals Returns the decimals of the token
    function decimals() external returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @title Callback for IOrderBook#flashLoan
/// @notice Any contract that calls IOrderBook#flashLoan must implement this interface
interface ILighterV2FlashCallback {
    /// @notice Called from `msg.sender` after transferring flashLoan to the recipient from IOrderBook#flashLoan
    /// @dev In the implementation you must repay the pool the assets sent by flashLoan.
    /// The caller of this method must be checked to be an order book deployed by the Factory
    /// @param callbackData Data passed through by the caller via the IOrderBook#flashLoan call
    function flashLoanCallback(bytes calldata callbackData) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./external/IERC20Minimal.sol";

/// @title Callback for IOrderBook#swapExactSingle and IOrderBook#createOrder
/// @notice Any contract that calls IOrderBook#swapExactSingle and IOrderBook#createOrder must implement this interface with one exception
/// @dev If orderType is PerformanceLimitOrder, then no need to implement this interface
/// @dev PerformanceLimitOrder handles payments with pre-deposited funds by market-makers
interface ILighterV2TransferCallback {
    /// @notice Called by order book after transferring received assets from IOrderBook#swapExactInput or IOrderBook#swapExactOutput for payments
    /// @dev In the implementation order creator must pay the order book the assets for the order
    /// The caller of this method must be checked to be an order book deployed by the Factory
    /// @param callbackData Data passed through by the caller via the IOrderBook#swapExactSingle or IOrderBook#swapExactOutput call
    function lighterV2TransferCallback(
        uint256 debitTokenAmount,
        IERC20Minimal debitToken,
        bytes calldata callbackData
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "../libraries/LinkedList.sol";
import "./external/IERC20Minimal.sol";

/// @title Order Book Interface
/// @notice Order book implements spot trading endpoints and storage for two assets which conform to the IERC20Minimal specification.
interface IOrderBook {
    /// @notice Limit Order type.
    enum OrderType {
        LimitOrder, // Limit order
        PerformanceLimitOrder, // Limit order that uses claimable balances
        FoKOrder, // Fill or Kill limit order
        IoCOrder // Immediate or Cancel limit order
    }

    /// @notice Struct to use for storing limit orders
    struct LimitOrder {
        uint32 perfMode_creatorId; // lowest bit for perfMode, remaining 31 bits for creatorId
        uint32 prev; // id of the previous order in the list
        uint32 next; // id of the next order in the list
        uint32 ownerId; // id of the owner of the order
        uint64 amount0Base; // amount0Base of the order
        uint64 priceBase; // priceBase of the order
    }

    /// @notice Struct to use returning the paginated orders
    struct OrderQueryItem {
        bool isAsk; // true if the paginated orders are ask orders, false if bid orders
        uint32[] ids; // order ids of returned orders
        address[] owners; // owner addresses of returned orders
        uint256[] amount0s; // amount0s of returned orders (amount0Base * sizeTick)
        uint256[] prices; // prices of returned orders (priceBase * priceTick)
    }

    /// @notice Emitted when a limit order gets created
    /// @param owner The address of the order owner
    /// @param id The id of the order
    /// @param amount0Base The amount of token0 in the limit order in terms of number of sizeTicks
    /// @param priceBase The price of the token0 in terms of price ticks
    /// @param isAsk Whether the order is an ask order
    /// @param orderType type of the order
    event CreateOrder(
        address indexed owner,
        uint32 indexed id,
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        OrderType orderType
    );

    /// @notice Emitted when a limit order gets canceled
    /// @param id The id of the canceled order
    event CancelLimitOrder(uint32 indexed id);

    /// @notice Emitted when a taker initiates a swap (market order)
    /// @param sender The address that initiated the swap
    /// @param recipient The address that received the tokens from the swap
    /// @param isExactInput Whether the input amount is exact or output amount is exact
    /// @param isAsk Whether the order is an ask order
    /// @param swapAmount0 The amount of token0 that was swapped
    /// @param swapAmount1 The amount of token1 that was swapped
    event SwapExactAmount(
        address indexed sender,
        address indexed recipient,
        bool isExactInput,
        bool isAsk,
        uint256 swapAmount0,
        uint256 swapAmount1
    );

    /// @notice Emitted when a maker gets filled by a taker
    /// @param askId The id of the ask order
    /// @param bidId The id of the bid order
    /// @param askOwner The address of the ask order owner
    /// @param bidOwner The address of the bid order owner
    /// @param amount0 The amount of token0 that was swapped
    /// @param amount1 The amount of token1 that was swapped
    event Swap(
        uint32 indexed askId,
        uint32 indexed bidId,
        address askOwner,
        address bidOwner,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when flashLoan is called
    /// @param sender The address that initiated the flashLoan, and that received the callback
    /// @param recipient The address that received the tokens from flash loan
    /// @param amount0 The amount of token0 that was flash loaned
    /// @param amount1 The amount of token1 that was flash loaned
    event FlashLoan(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1);

    /// @notice Emitted when user claimable balance is increased due to deposit or order operations
    event ClaimableBalanceIncrease(address indexed owner, uint256 amountDelta, bool isToken0);

    /// @notice Emitted when user claimable balance is decreased due to withdraw or order operations
    event ClaimableBalanceDecrease(address indexed owner, uint256 amountDelta, bool isToken0);

    /// @notice Creates a limit order.
    /// @param amount0Base The amount of token0 in the limit order in terms of number of sizeTicks.
    /// amount0 is calculated by multiplying amount0Base by sizeTick.
    /// @param priceBase The price of the token0 in terms of price ticks.
    /// amount1 is calculated by multiplying priceBase by sizeTick and priceMultiplier and dividing by priceDivider.
    /// @param isAsk Whether the order is an ask order
    /// @param owner The address which will receive the funds and that can
    /// cancel this order. When called by a router, it'll be populated
    /// with msg.sender. Smart wallets should use msg.sender directly.
    /// @param hintId Hint on where to insert the order in the order book.
    /// Can be calculated with suggestHintId function, is not used for FoK and IoC orders.
    /// @param orderType type of the order, if FoK or IoC remaining order will not be added for future matches.
    /// @param callbackData data to be passed to callback
    /// @return id The id of the order
    function createOrder(
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        address owner,
        uint32 hintId,
        OrderType orderType,
        bytes memory callbackData
    ) external returns (uint32);

    /// @notice Cancels an outstanding limit order. Refunds the remaining tokens in the order to the owner
    /// @param id The id of the order to cancel
    /// @param owner The address of the order sender
    /// @return isCanceled Whether the order was successfully canceled or not
    function cancelLimitOrder(uint32 id, address owner) external returns (bool);

    /// @notice Swaps exact input or output amount of token0 or token1 for the other token
    /// @param isAsk Whether the order is an ask order, if true sender pays token0 and receives token1
    /// @param isExactInput Whether the input amount is exact or output amount is exact
    /// @param exactAmount exact token amount to swap (can be token0 or token1 based on isAsk and isExactInput)
    /// @param expectedAmount expected token amount to receive (can be token0 or token1 based on isAsk and isExactInput).
    /// if isExactInput is true, then expectedAmount is the minimum amount to receive.
    /// if isExactInput is false, then expectedAmount is the maximum amount to pay
    /// @param recipient The address which will receive the output
    /// @param callbackData data to be passed to callback
    function swapExactSingle(
        bool isAsk,
        bool isExactInput,
        uint256 exactAmount,
        uint256 expectedAmount,
        address recipient,
        bytes memory callbackData
    ) external returns (uint256, uint256);

    /// @notice Flash loans token0 and token1 to the recipient, sender receives the callback
    /// @param recipient The address which will receive the token0 and token1
    /// @param amount0 The amount of token0 to flash loan
    /// @param amount1 The amount of token1 to flash loan
    /// @param callbackData data to be passed to callback
    function flashLoan(address recipient, uint256 amount0, uint256 amount1, bytes calldata callbackData) external;

    /// @notice Deposits token0 or token1 from user to the order book and marks it as claimable
    /// to be used for performance limit orders for gas efficient limit order creations.
    /// @param amountToDeposit Amount to deposit
    /// @param isToken0 Whether the deposit is token0 or token1
    /// @param callbackData Byte data to send to callback
    function depositToken(uint256 amountToDeposit, bool isToken0, bytes memory callbackData) external;

    /// @notice Withdraws deposited or swapped token0 or token1 to the owner.
    /// @param amountToClaim Amount to withdraw
    /// @param isToken0 Whether the claimable token is token0 or token1
    function claimToken(uint256 amountToClaim, bool isToken0) external;

    /// @notice Finds the order id where the new order should be inserted to the right of
    /// Meant to be used off-chain to find the hintId for limit order creation functions
    /// @param priceBase basePrice derived from amount0Base and amount1Base
    /// @param isAsk Whether the new order is an ask order
    /// @return hintId The id of the order where the new order
    /// should be inserted to the right of
    function suggestHintId(uint64 priceBase, bool isAsk) external view returns (uint32);

    /// @notice Returns the amount of token0 and token1 to traded between two limit orders
    /// @param takerOrderAmount0Base The amount0Base of the taker order
    /// @param takerOrderPriceBase The priceBase of the taker order
    /// @param makerOrderAmount0Base The amount0Base of the maker order
    /// @param makerOrderPriceBase The priceBase of the maker order
    /// @param isTakerAsk True if taker order is an ask
    /// @return amount0BaseReturn The amount0Base to be traded
    /// @return amount1BaseReturn The amount1Base to be traded
    function getLimitOrderSwapAmounts(
        uint64 takerOrderAmount0Base,
        uint64 takerOrderPriceBase,
        uint64 makerOrderAmount0Base,
        uint64 makerOrderPriceBase,
        bool isTakerAsk
    ) external pure returns (uint64, uint128);

    /// @notice Returns the amount of token0 and token1 to traded between maker and swapper
    /// @param amount0 Exact token0 amount taker wants to trade
    /// @param isAsk True if swapper is an ask
    /// @param makerAmount0Base The amount0Base of the maker order
    /// @param makerPriceBase The priceBase of the maker order
    /// @return swapAmount0 The amount of token0 to be swapped
    /// @return swapAmount1 The amount of token1 to be swapped
    /// @return amount0BaseDelta Maker order baseAmount0 change
    /// @return fullTakerFill True if swapper can be fully filled by maker order
    function getSwapAmountsForToken0(
        uint256 amount0,
        bool isAsk,
        uint64 makerAmount0Base,
        uint64 makerPriceBase
    ) external view returns (uint256, uint256, uint64, bool);

    /// @notice Returns the amount of token0 and token1 to traded between maker and swapper
    /// @param amount1 Exact token1 amount taker wants to trade
    /// @param isAsk True if swapper is an ask
    /// @param makerAmount0Base The amount0Base of the maker order
    /// @param makerPriceBase The priceBase of the maker order
    /// @return swapAmount0 The amount of token0 to be swapped
    /// @return swapAmount1 The amount of token1 to be swapped
    /// @return amount0BaseDelta Maker order baseAmount0 change
    /// @return fullTakerFill True if swapper can be fully filled by maker order
    function getSwapAmountsForToken1(
        uint256 amount1,
        bool isAsk,
        uint64 makerAmount0Base,
        uint64 makerPriceBase
    ) external view returns (uint256, uint256, uint64, bool);

    /// @notice Returns price sorted limit orders with pagination
    /// @param startOrderId orderId from where the pagination should start (not inclusive)
    /// @dev caller can pass 0 to start from the top of the book
    /// @param isAsk Whether to return ask or bid orders
    /// @param limit Number number of orders to return in the page
    /// @return orderData The paginated order data
    function getPaginatedOrders(
        uint32 startOrderId,
        bool isAsk,
        uint32 limit
    ) external view returns (OrderQueryItem memory orderData);

    /// @notice Returns the limit order of the given index
    /// @param isAsk Whether the order is an ask order
    /// @param id The id of the order
    /// @return order The limit order
    function getLimitOrder(bool isAsk, uint32 id) external view returns (LimitOrder memory);

    /// @notice Returns whether an order is active or not
    /// @param id The id of the order
    /// @return isActive True if the order is active, false otherwise
    function isOrderActive(uint32 id) external view returns (bool);

    /// @notice Returns whether an order is an ask order or not, fails if order is not active
    /// @param id The id of the order
    /// @return isAsk True if the order is an ask order, false otherwise
    function isAskOrder(uint32 id) external view returns (bool);

    /// @notice Returns the constant for Log value of TickThreshold
    /// @return LOG10_TICK_THRESHOLD threshold for Log value of TickThreshold
    function LOG10_TICK_THRESHOLD() external view returns (uint8);

    /// @notice Returns the constant for threshold value of orderId
    /// @return ORDER_ID_THRESHOLD threshold for threshold value of orderId
    function ORDER_ID_THRESHOLD() external view returns (uint32);

    /// @notice Returns the constant for threshold value of creatorId
    /// @return CREATOR_ID_THRESHOLD threshold for threshold value of creatorId
    function CREATOR_ID_THRESHOLD() external view returns (uint32);

    /// @notice The token0 (base token)
    /// @return token0 The token0 (base token) contract
    function token0() external view returns (IERC20Minimal);

    /// @notice The token1 (quote token)
    /// @return token1 The token1 (quote token) contract
    function token1() external view returns (IERC20Minimal);

    /// @notice Id of the order book
    /// @return orderBookId The unique identifier of an order book
    function orderBookId() external view returns (uint8);

    /// @notice The sizeTick of the order book
    /// @return sizeTick The sizeTick of the order book
    function sizeTick() external view returns (uint128);

    /// @notice The priceTick of the order book
    /// @return priceTick The priceTick of the order book
    function priceTick() external view returns (uint128);

    /// @notice The priceMultiplier of the order book
    /// @return priceMultiplier The priceMultiplier of the order book
    function priceMultiplier() external view returns (uint128);

    /// @notice The priceDivider of the order book
    /// @return priceDivider The priceMultiplier of the order book
    function priceDivider() external view returns (uint128);

    /// @notice Returns the id of the next order Id to create
    /// @return orderIdCounter id of the next order
    function orderIdCounter() external view returns (uint32);

    /// @notice minToken0BaseAmount minimum token0Base amount for limit order
    /// @return minToken0BaseAmount minToken0BaseAmount of the order book
    function minToken0BaseAmount() external view returns (uint64);

    /// @notice minToken1BaseAmount minimum token1Base amount (token0Base * priceBase) for limit order
    /// @return minToken1BaseAmount minToken1BaseAmount of the order book
    function minToken1BaseAmount() external view returns (uint128);

    /// @notice Claimable token0 amount for given address
    /// @return claimableToken0Balance Claimable token0 amount for given address
    function claimableToken0Balance(address owner) external view returns (uint256);

    /// @notice Claimable token1 amount for given address
    /// @return claimableToken1Balance Claimable token1 amount for given address
    function claimableToken1Balance(address owner) external view returns (uint256);

    /// @notice id of an order-owner
    /// @return addressToOwnerId id of an order-owner
    function addressToOwnerId(address owner) external view returns (uint32);

    /// @notice address for given creatorId
    /// @return addressToCreatorId address for given creatorId
    function addressToCreatorId(address creatorAddress) external view returns (uint32);

    /// @notice id of a creatorAddress
    /// @return creatorIdToAddress id of a creatorAddress
    function creatorIdToAddress(uint32 creatorId) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @title Errors
/// @notice Library containing errors that Lighter V2 Core functions may revert with
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                      LIGHTER-V2-FACTORY
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the factory owner for setOwner or createOrderBook
    error LighterV2Factory_CallerNotOwner();

    /// @notice Thrown when zero address is passed when setting the owner
    error LighterV2Factory_OwnerCannotBeZero();

    /*//////////////////////////////////////////////////////////////////////////
                                      LIGHTER-V2-CREATE-ORDER-BOOK
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when token0 and token1 are identical or zero in order book creation
    error LighterV2CreateOrderBook_InvalidTokenPair();

    /// @notice Thrown when an order book already exists with given token0 and token1 in order book creation
    error LighterV2CreateOrderBook_OrderBookAlreadyExists();

    /// @notice Thrown when order book capacity is already reached in order book creation
    error LighterV2CreateOrderBook_OrderBookIdExceedsLimit();

    /// @notice Thrown when invalid combination of logSizeTick and logPriceTick is given in order book creation
    error LighterV2CreateOrderBook_InvalidTickCombination();

    /// @notice Thrown when invalid combination of minToken0BaseAmount and minToken1BaseAmount given in order book creation
    error LighterV2CreateOrderBook_InvalidMinAmount();

    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-V2-ORDER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when invalid hintId is given in limit order creation
    error LighterV2Order_InvalidHintId();

    /// @notice Thrown when given price is too small in order creation
    error LighterV2Order_PriceTooSmall();

    /// @notice Thrown when given price is too big in order creation
    error LighterV2Order_PriceTooBig();

    /// @notice Thrown when token0 or token1 amount is too small in limit order creation
    error LighterV2Order_AmountTooSmall();

    /// @notice Thrown when order capacity is already reached in order creation
    error LighterV2Order_OrderIdExceedsLimit();

    /// @notice Thrown when creator capacity is already reached in order creation
    error LighterV2Order_CreatorIdExceedsLimit();

    /// @notice Thrown when tokens sent callback is insufficient in order creation or swap
    error LighterV2Order_InsufficentCallbackTransfer();

    /// @notice Thrown when claimable balance is insufficient in order creation
    error LighterV2Order_InsufficientClaimableBalance();

    /// @notice Thrown when FillOrKill order is not fully filled
    error LighterV2Order_FoKNotFilled();

    /// @notice Thrown when contract balance decrease is larger than the transfered amount
    error LighterV2Base_ContractBalanceDoesNotMatchSentAmount();

    /// @notice Thrown when caller is not the order creator or owner in order cancelation
    error LighterV2Owner_CallerCannotCancel();

    /// @notice Thrown when caller tries to erase head or tail orders in order linked list
    error LighterV2Order_CannotEraseHeadOrTailOrders();

    /// @notice Thrown when caller tries to cancel an order that is not active
    error LighterV2Order_CannotCancelInactiveOrders();

    /// @notice Thrown when caller asks for order side for a inactive or non-existent order
    error LighterV2Order_OrderDoesNotExist();

    /// @notice Thrown when caller tries to query an order book page starting from an inactive order
    error LighterV2Order_CannotQueryFromInactiveOrder();

    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-SWAP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when order book does not have enough liquidity to fill the swap
    error LighterV2Swap_NotEnoughLiquidity();

    /// @notice Thrown when swapper receives less than the minimum amount of tokens expected
    error LighterV2Swap_NotEnoughOutput();

    /// @notice Thrown when swapper needs to pay more than the maximum amount of tokens they are willing to pay
    error LighterV2Swap_TooMuchRequested();

    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-V2-VAULT
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when caller tries to withdraw more than their balance or withdraw zero
    error LighterV2Vault_InvalidClaimAmount();

    /// @notice Thrown when caller does not tranfer enough tokens to the vault when depositing
    error LighterV2Vault_InsufficentCallbackTransfer();
    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-V2-FLASH-LOAN
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when caller does not tranfer enough tokens to repay for the flash loan
    error LighterV2FlashLoan_InsufficentCallbackTransfer();

    /*//////////////////////////////////////////////////////////////////////////
                                  LIGHTER-V2-TOKEN-TRANSFER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when token transfer from order book fails
    error LighterV2TokenTransfer_Failed();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./Errors.sol";
import "../interfaces/IOrderBook.sol";

/// @title LinkedList
/// @notice Struct to use for storing sorted linked lists of ask and bid orders
struct LinkedList {
    mapping(uint32 => IOrderBook.LimitOrder) asks;
    mapping(uint32 => IOrderBook.LimitOrder) bids;
}

/// @title LinkedListLib
/// @notice Implements a sorted linked list of limit orders and provides necessary functions for order management
/// @dev Head is represented by order id 0, tail is represented by order id 1
library LinkedListLib {
    /// @notice Inserts an order into the respective linked list and keeps sorted order
    /// @param orderId id of the order to insert
    /// @param isAsk true if the order is an ask order, false if the order is a bid order
    /// @param hintId hint id of the order where the new order should be inserted to the right of
    function insert(LinkedList storage self, uint32 orderId, bool isAsk, uint32 hintId) internal {
        mapping(uint32 => IOrderBook.LimitOrder) storage orders = isAsk ? self.asks : self.bids;
        IOrderBook.LimitOrder storage order = orders[orderId];

        if (orders[hintId].next == 0) {
            revert Errors.LighterV2Order_InvalidHintId();
        }

        while (orders[hintId].ownerId == 0) {
            hintId = orders[hintId].next;
        }

        // After the search, hintId will be where the new order should be inserted to the right of
        IOrderBook.LimitOrder memory hintOrder = orders[hintId];
        while (hintId != 1) {
            IOrderBook.LimitOrder memory nextOrder = orders[hintOrder.next];
            if (isAsk ? (order.priceBase < nextOrder.priceBase) : (order.priceBase > nextOrder.priceBase)) break;
            hintId = hintOrder.next;
            hintOrder = nextOrder;
        }
        while (hintId != 0) {
            if (isAsk ? (order.priceBase >= hintOrder.priceBase) : (order.priceBase <= hintOrder.priceBase)) break;
            hintId = hintOrder.prev;
            hintOrder = orders[hintId];
        }

        order.prev = hintId;
        order.next = orders[hintId].next;
        orders[order.prev].next = orderId;
        orders[order.next].prev = orderId;
    }

    /// @notice Removes given order id from the respective linked list
    /// @dev Updates the respective linked list but does not delete the order, sets the ownerId to 0 instead
    /// @param orderId The order id to remove
    /// @param isAsk true if the order is an ask order, false if the order is a bid order
    function erase(LinkedList storage self, uint32 orderId, bool isAsk) internal {
        if (orderId <= 1) {
            revert Errors.LighterV2Order_CannotEraseHeadOrTailOrders();
        }

        mapping(uint32 => IOrderBook.LimitOrder) storage orders = isAsk ? self.asks : self.bids;

        if (orders[orderId].ownerId == 0) {
            revert Errors.LighterV2Order_CannotCancelInactiveOrders();
        }
        IOrderBook.LimitOrder storage order = orders[orderId];
        order.ownerId = 0;

        uint32 prev = order.prev;
        uint32 next = order.next;
        orders[prev].next = next;
        orders[next].prev = prev;
    }

    /// @notice Returns a struct that represents order page with given parameters
    /// @param startOrderId The order id to start the pagination from (not inclusive)
    /// @param isAsk true if the paginated orders are ask orders, false if bid orders
    /// @param limit The number of orders to return
    /// @param ownerIdToAddress Mapping from owner id to owner address
    /// @param sizeTick The size tick of the order book
    /// @param priceTick The price tick of the order book
    function getPaginatedOrders(
        LinkedList storage self,
        uint32 startOrderId,
        bool isAsk,
        uint32 limit,
        mapping(uint32 => address) storage ownerIdToAddress,
        uint128 sizeTick,
        uint128 priceTick
    ) public view returns (IOrderBook.OrderQueryItem memory paginatedOrders) {
        mapping(uint32 => IOrderBook.LimitOrder) storage orders = isAsk ? self.asks : self.bids;

        if (orders[startOrderId].ownerId == 0) {
            revert Errors.LighterV2Order_CannotQueryFromInactiveOrder();
        }
        uint32 i = 0;
        paginatedOrders.ids = new uint32[](limit);
        paginatedOrders.owners = new address[](limit);
        paginatedOrders.amount0s = new uint256[](limit);
        paginatedOrders.prices = new uint256[](limit);
        for (uint32 pointer = orders[startOrderId].next; pointer != 1 && i < limit; pointer = orders[pointer].next) {
            IOrderBook.LimitOrder memory order = orders[pointer];
            paginatedOrders.ids[i] = pointer;
            paginatedOrders.owners[i] = ownerIdToAddress[order.ownerId];
            paginatedOrders.amount0s[i] = uint256(order.amount0Base) * sizeTick;
            paginatedOrders.prices[i] = order.priceBase * priceTick;
            unchecked {
                ++i;
            }
        }
        paginatedOrders.isAsk = isAsk;
    }

    /// @notice Finds the order id where the order with given price should be inserted to the right of
    /// @param priceBase The priceBase to suggest the hintId for
    /// @return hintId The order id where the order with given price should be inserted to the right of
    function suggestHintId(LinkedList storage self, uint64 priceBase, bool isAsk) public view returns (uint32) {
        mapping(uint32 => IOrderBook.LimitOrder) storage orders = isAsk ? self.asks : self.bids;
        uint32 hintOrderId = 0;
        IOrderBook.LimitOrder memory hintOrder = orders[hintOrderId];
        while (hintOrderId != 1) {
            IOrderBook.LimitOrder memory nextOrder = orders[hintOrder.next];
            if (isAsk ? (priceBase < nextOrder.priceBase) : (priceBase > nextOrder.priceBase)) break;
            hintOrderId = hintOrder.next;
            hintOrder = nextOrder;
        }
        return hintOrderId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;
import "../OrderBook.sol";

/// @title OrderBookDeployLib
/// @notice Deploys a new order book and initializes it with given arguments
library OrderBookDeployerLib {
    /// @notice Deploys a new order book and initializes it with given arguments
    /// @param orderBookId Id of the order book
    /// @param token0 address of token0 (base token)
    /// @param token1 address of token1 (quote token)
    /// @param logSizeTick log10 of sizeTick
    /// @param logPriceTick log10 of priceTick
    /// @param minToken0BaseAmount minimum token0 base amount for limit order creations
    /// @param minToken1BaseAmount minimum token1 base amount for limit order creations
    /// @return orderBookAddress address of the deployed order book
    function deployOrderBook(
        uint8 orderBookId,
        address token0,
        address token1,
        uint8 logSizeTick,
        uint8 logPriceTick,
        uint64 minToken0BaseAmount,
        uint128 minToken1BaseAmount
    ) external returns (address) {
        return
            address(
                new OrderBook(
                    orderBookId,
                    token0,
                    token1,
                    logSizeTick,
                    logPriceTick,
                    minToken0BaseAmount,
                    minToken1BaseAmount
                )
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IOrderBook.sol";
import "./interfaces/ILighterV2FlashCallback.sol";
import "./interfaces/ILighterV2TransferCallback.sol";

import "./libraries/LinkedList.sol";
import "./libraries/Errors.sol";
import {IERC20Minimal} from "./interfaces/external/IERC20Minimal.sol";

/**
 * @title Order Book
 * @notice Contract representing an order book for trading token pairs. It manages
 * the creation and interaction of orders, and tracks various parameters related
 * to order management.
 * @notice OrderBook can handle different types of orders and order-life-cycle management
 * @notice User can swap tokens in the order book via direct call on orderBook or via router
 * @dev for direct order book interaction of order-creation and token-swap, ensure the caller
 *      has implemented the callback interface to handle payments
 */
contract OrderBook is IOrderBook, ReentrancyGuard {
    /// @dev Limits the value for size and price ticks
    uint8 public constant LOG10_TICK_THRESHOLD = 38;

    /// @dev Limits the total number of orders that can be created
    uint32 public constant ORDER_ID_THRESHOLD = (1 << 32) - 1;

    /// @dev Limits the unique number of creators, which are smart contracts
    /// that call the order book and implements the callback interfaces
    uint32 public constant CREATOR_ID_THRESHOLD = (1 << 31) - 1;

    uint64 public constant MAX_PRICE = type(uint64).max;

    // Using the LinkedListLib for order management
    using LinkedListLib for LinkedList;

    /// @notice The ERC20 token used as token0 in the trading pair
    IERC20Minimal public immutable token0;

    /// @notice The ERC20 token used as token1 in the trading pair
    IERC20Minimal public immutable token1;

    /// @notice The id of the order book
    uint8 public immutable orderBookId;

    /// @notice The minimum base token0 amount required for an order to be valid
    uint64 public immutable minToken0BaseAmount;

    /// @notice The minimum base token1 amount required for an order to be valid (token0Base * priceBase)
    uint128 public immutable minToken1BaseAmount;

    /// @notice The step size for token0 amounts
    uint128 public immutable sizeTick;

    /// @notice The step size for unit token0 price
    uint128 public immutable priceTick;

    /// @notice The multiplier used for calculating the amount1 from priceBase and amount0Base
    uint128 public immutable priceMultiplier;

    /// @notice The divider used for calculating the amount1 from priceBase and amount0Base
    uint128 public immutable priceDivider;

    /// @dev The id of the next order to be created, also used for setting ownerId and creatorId for gas efficiency
    uint32 public orderIdCounter;

    /// @notice The data structure used for storing the active orders
    /// @dev If an ask order, book needs to store at least amount0Base * sizeTick amount of token0. If a bid order,
    /// book needs to store at least amount0Base * priceMultiplier * sizeTick / priceDivider amount of token1
    LinkedList private _orders;

    /// @notice Mapping from address to claimable token0 balance
    mapping(address => uint256) public claimableToken0Balance;

    /// @notice Mapping from address to claimable token1 balance
    mapping(address => uint256) public claimableToken1Balance;

    /// @notice Mapping from ownerId to address
    mapping(uint32 => address) public ownerIdToAddress;

    /// @notice Mapping from address to ownerId
    mapping(address => uint32) public addressToOwnerId;

    /// @notice Mapping from address to creatorId
    mapping(address => uint32) public addressToCreatorId;

    /// @notice Mapping from creatorId to address
    mapping(uint32 => address) public creatorIdToAddress;

    /// @notice A struct containing variables used for order matching.
    struct MatchOrderLocalVars {
        uint32 index; // id of the maker order being matched
        address makerAddress; // owner address of the maker order
        uint256 filledAmount0; // Amount of token0 already filled in the taker order
        uint256 filledAmount1; // Amount of token1 already filled in the taker order
        uint256 amount; // Exact amount of tokens to be sent or received in a swap
        uint64 makerAmount0BaseChange; // Maker order amont0Base change
        uint256 swapAmount0; // Amount of token0 to be swaped with maker order
        uint256 swapAmount1; // Amount of token1 to be swaped with maker order
        uint64 swapAmount0Base; // Base amount of token0 to be swaped with maker order
        uint128 swapAmount1Base; // Base amount of token1 to be swaped with maker order
        bool atLeastOneFullSwap; // Flag indicating if taker took at least one maker order fully
        bool fullTakerFill; // Flag indicating if taker order is fully filled
        uint32 swapCount; // Count of swaps performed
        uint32 swapCapacity; // Capacity swaps array
        SwapData[] swaps; // Array of swap data
    }

    /// @notice A struct containing payment-related data for order and swap operations.
    struct PaymentData {
        bool isAsk; // Flag indicating if the taker order is an ask order
        bool isPerfMode; // Flag indicating if the taker order is a performance limit order
        address recipient; // Recipient address for payments
        uint256 filledAmount0; // Total amount of token0 in the swaps
        uint256 filledAmount1; // Total amount of token1 in the swaps
        uint256 remainingLimitOrderAmount; // Amount taker needs to pay for unmatched part of their limit order
        uint32 swapCount; // Count of swaps performed
        SwapData[] swaps; // Array of swap data
        bytes callbackData; // Additional callback data for payment.
    }

    /// @dev Struct that holds swap data during matching
    struct SwapData {
        address makerAddress; // Address of the owner of the matched order
        uint256 swapAmount; // Amount of tokens matched in the order
        bool isPerfMode; // Flag indicating if the order is in performance mode
    }

    /// @notice Contract constructor
    /// @param _orderBookId The id of the order book
    /// @param _token0Address The base token address
    /// @param _token1Address The quote token address
    /// @param _logSizeTick log10 of base token tick, size of the base token
    /// should be multiples of 10**logSizeTick for limit orders
    /// @param _logPriceTick log10 of price tick, price of unit base token
    /// should be multiples of 10**logPriceTick for limit orders
    /// @param _minToken0BaseAmount minimum token0Base amount for limit orders
    /// @param _minToken1BaseAmount minimum token1Base amount (token0Base * priceBase) for limit orders
    /// @dev Initializes the contract and linked lists with provided parameters
    constructor(
        uint8 _orderBookId,
        address _token0Address,
        address _token1Address,
        uint8 _logSizeTick,
        uint8 _logPriceTick,
        uint64 _minToken0BaseAmount,
        uint128 _minToken1BaseAmount
    ) {
        token0 = IERC20Minimal(_token0Address);
        token1 = IERC20Minimal(_token1Address);
        orderBookId = _orderBookId;
        uint8 token0Decimals = token0.decimals();

        if (_logSizeTick >= LOG10_TICK_THRESHOLD || _logPriceTick >= LOG10_TICK_THRESHOLD) {
            revert Errors.LighterV2CreateOrderBook_InvalidTickCombination();
        }

        sizeTick = uint128(10 ** _logSizeTick);
        priceTick = uint128(10 ** _logPriceTick);
        uint128 priceMultiplierCheck = 1;
        uint128 priceDividerCheck = 1;
        if (_logSizeTick + _logPriceTick >= token0Decimals) {
            if (_logSizeTick + _logPriceTick - token0Decimals >= LOG10_TICK_THRESHOLD) {
                revert Errors.LighterV2CreateOrderBook_InvalidTickCombination();
            }
            priceMultiplierCheck = uint128(10 ** (_logSizeTick + _logPriceTick - token0Decimals));
        } else {
            if (token0Decimals - _logSizeTick - _logPriceTick >= LOG10_TICK_THRESHOLD) {
                revert Errors.LighterV2CreateOrderBook_InvalidTickCombination();
            }
            priceDividerCheck = uint128(10 ** (token0Decimals - _logPriceTick - _logSizeTick));
        }

        priceMultiplier = priceMultiplierCheck;
        priceDivider = priceDividerCheck;

        if (_minToken0BaseAmount == 0 || _minToken1BaseAmount == 0) {
            revert Errors.LighterV2CreateOrderBook_InvalidMinAmount();
        }
        minToken0BaseAmount = _minToken0BaseAmount;
        minToken1BaseAmount = _minToken1BaseAmount;

        // Create the head node for asks linked list, this node can not be deleted
        _orders.asks[0] = LimitOrder({
            prev: 0,
            next: 1,
            perfMode_creatorId: 0,
            ownerId: 1,
            amount0Base: 0,
            priceBase: 0
        });
        // Create the tail node for asks linked list, this node can not be deleted
        _orders.asks[1] = LimitOrder({
            prev: 0,
            next: 1,
            perfMode_creatorId: 0,
            ownerId: 1,
            amount0Base: 0,
            priceBase: MAX_PRICE
        });
        // Create the head node for bids linked list, this node can not be deleted
        _orders.bids[0] = LimitOrder({
            prev: 0,
            next: 1,
            perfMode_creatorId: 0,
            ownerId: 1,
            amount0Base: 0,
            priceBase: MAX_PRICE
        });
        // Create the tail node for bids linked list, this node can not be deleted
        _orders.bids[1] = LimitOrder({
            prev: 0,
            next: 1,
            perfMode_creatorId: 0,
            ownerId: 1,
            amount0Base: 0,
            priceBase: 0
        });
        // Id 0 and 1 are used for heads and tails. Next order should start from id 2
        orderIdCounter = 2;
    }

    /// @inheritdoc IOrderBook
    function createOrder(
        uint64 amount0Base,
        uint64 priceBase,
        bool isAsk,
        address owner,
        uint32 hintId,
        OrderType orderType,
        bytes memory callbackData
    ) external override nonReentrant returns (uint32 newOrderId) {
        newOrderId = orderIdCounter;

        // For every order type, the amount0Base needs to be at least 1
        if (amount0Base == 0) {
            revert Errors.LighterV2Order_AmountTooSmall();
        }

        // priceBase needs to be at least priceDivider
        // this guarantees that any increase of amount0Base will increase amount1 by at least 1
        // as priceDivider is guaranteed to be at least 1, an error is always thrown if priceBase = 0,
        // which is reserved for the dummy order with id 0
        if (priceBase < priceDivider) {
            revert Errors.LighterV2Order_PriceTooSmall();
        }

        // do not allow orders with the max price, as the price is reserved for the big dummy order.
        // this is required so no order is inserted after the dummy order with id 1
        if (priceBase == MAX_PRICE) {
            revert Errors.LighterV2Order_PriceTooBig();
        }

        if (orderType == OrderType.LimitOrder || orderType == OrderType.PerformanceLimitOrder) {
            if (hintId >= newOrderId) {
                revert Errors.LighterV2Order_InvalidHintId();
            }
            if ((amount0Base < minToken0BaseAmount || priceBase * amount0Base < minToken1BaseAmount)) {
                revert Errors.LighterV2Order_AmountTooSmall();
            }
        }

        LimitOrder memory newOrder;

        {
            if (newOrderId >= ORDER_ID_THRESHOLD) {
                revert Errors.LighterV2Order_OrderIdExceedsLimit();
            }

            orderIdCounter = newOrderId + 1;

            newOrder = LimitOrder({
                perfMode_creatorId: 0, // Only set if order needs to be inserted into the order book
                prev: 0, // Only set if order needs to be inserted into the order book
                next: 0, // Only set if order needs to be inserted into the order book
                ownerId: 0, // Only set if order needs to be inserted into the order book
                amount0Base: amount0Base,
                priceBase: priceBase
            });

            emit CreateOrder(owner, newOrderId, amount0Base, priceBase, isAsk, orderType);
        }

        (uint256 filledAmount0, uint256 filledAmount1, uint32 swapCount, SwapData[] memory swaps) = _matchOrder(
            newOrder,
            newOrderId,
            owner,
            isAsk
        );
        // Short circuit payments if Fill or Kill order is not fully filled and needs to be killed
        if (orderType == OrderType.FoKOrder && newOrder.amount0Base > 0) {
            revert Errors.LighterV2Order_FoKNotFilled();
        }

        // Computes the amount caller needs to pay for remaning part of their limit order
        uint256 remainingLimitOrderAmount = 0;
        if (
            (orderType == OrderType.LimitOrder || orderType == OrderType.PerformanceLimitOrder) &&
            newOrder.amount0Base > 0
        ) {
            remainingLimitOrderAmount = (isAsk)
                ? (uint256(newOrder.amount0Base) * sizeTick)
                : (uint256(newOrder.amount0Base) * newOrder.priceBase * priceMultiplier) / priceDivider;
        }

        // Handle token transfers between makers and takers and for remainingLimitOrderAmount
        if (
            filledAmount0 > 0 ||
            filledAmount1 > 0 ||
            orderType == OrderType.LimitOrder ||
            orderType == OrderType.PerformanceLimitOrder
        ) {
            _handlePayments(
                PaymentData(
                    isAsk,
                    orderType == OrderType.PerformanceLimitOrder,
                    owner,
                    filledAmount0,
                    filledAmount1,
                    remainingLimitOrderAmount,
                    swapCount,
                    swaps,
                    callbackData
                )
            );
        }

        // If the order is not fully filled, set remaining value in newOrder and insert it into respective order book
        if (remainingLimitOrderAmount > 0) {
            // Get the ownerId if exists, otherwise set the ownerId using the from address
            newOrder.ownerId = addressToOwnerId[owner];
            if (newOrder.ownerId == 0) {
                newOrder.ownerId = newOrderId;
                addressToOwnerId[owner] = newOrder.ownerId;
                ownerIdToAddress[newOrderId] = owner;
            }

            // creatorId can only be non-zero if msg.sender different from the owner and order is a limit order
            if (msg.sender != owner) {
                newOrder.perfMode_creatorId = addressToCreatorId[msg.sender];
                if (newOrder.perfMode_creatorId == 0) {
                    // LimitOrder stores 31 bits for the creator id, only allow setting a non-zero creator id if it's below the limit
                    if (newOrderId >= CREATOR_ID_THRESHOLD) {
                        revert Errors.LighterV2Order_CreatorIdExceedsLimit();
                    }
                    newOrder.perfMode_creatorId = newOrderId;
                    addressToCreatorId[msg.sender] = newOrder.perfMode_creatorId;
                    creatorIdToAddress[newOrder.perfMode_creatorId] = msg.sender;
                }
                newOrder.perfMode_creatorId <<= 1;
            }

            if (orderType == OrderType.PerformanceLimitOrder) {
                newOrder.perfMode_creatorId = newOrder.perfMode_creatorId | 1;
            }

            if (isAsk) {
                _orders.asks[newOrderId] = newOrder;
                _orders.insert(newOrderId, isAsk, hintId);
            } else {
                _orders.bids[newOrderId] = newOrder;
                _orders.insert(newOrderId, isAsk, hintId);
            }
        }
    }

    /// @inheritdoc IOrderBook
    function cancelLimitOrder(uint32 id, address owner) external override nonReentrant returns (bool) {
        if (!isOrderActive(id)) {
            return false;
        }

        LimitOrder memory order;

        bool isAsk = isAskOrder(id);
        if (isAsk) {
            order = _orders.asks[id];
        } else {
            order = _orders.bids[id];
        }

        address _owner = ownerIdToAddress[order.ownerId];
        uint32 creatorId = (order.perfMode_creatorId >> 1);
        address creator = _owner;
        if (creatorId != 0) {
            creator = creatorIdToAddress[creatorId];
        }

        // only the creator or the owner can cancel the order
        if ((owner != _owner) || (msg.sender != creator && msg.sender != _owner)) {
            revert Errors.LighterV2Owner_CallerCannotCancel();
        }

        emit CancelLimitOrder(id);

        if (isAsk) {
            uint256 amount0 = uint256(order.amount0Base) * sizeTick;
            bool success = false;
            if ((order.perfMode_creatorId & 1) == 0) {
                success = _sendToken(token0, _owner, amount0);
            }
            if (!success) {
                claimableToken0Balance[_owner] += amount0;
                if ((order.perfMode_creatorId & 1) == 0) {
                    emit ClaimableBalanceIncrease(_owner, amount0, true);
                }
            }
            _orders.erase(id, isAsk);
        } else {
            uint256 amount1 = ((uint256(order.amount0Base) * order.priceBase) * priceMultiplier) / priceDivider;
            bool success = false;
            if ((order.perfMode_creatorId & 1) == 0) {
                success = _sendToken(token1, _owner, amount1);
            }
            if (!success) {
                claimableToken1Balance[_owner] += amount1;
                if ((order.perfMode_creatorId & 1) == 0) {
                    emit ClaimableBalanceIncrease(_owner, amount1, false);
                }
            }
            _orders.erase(id, isAsk);
        }
        return true;
    }

    /// @inheritdoc IOrderBook
    function swapExactSingle(
        bool isAsk,
        bool isExactInput,
        uint256 exactAmount,
        uint256 expectedAmount,
        address recipient,
        bytes memory callbackData
    ) external override nonReentrant returns (uint256, uint256) {
        (uint256 filledAmount0, uint256 filledAmount1, uint32 swapCount, SwapData[] memory swaps) = _matchSwapOrder(
            isAsk,
            isExactInput,
            exactAmount,
            expectedAmount,
            recipient
        );

        _handlePayments(
            PaymentData(isAsk, false, recipient, filledAmount0, filledAmount1, 0, swapCount, swaps, callbackData)
        );

        emit SwapExactAmount(msg.sender, recipient, isExactInput, isAsk, filledAmount0, filledAmount1);

        return (filledAmount0, filledAmount1);
    }

    /// @inheritdoc IOrderBook
    function flashLoan(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata callbackData
    ) external override nonReentrant {
        uint256 orderBookToken0BalanceBeforeLoan = token0.balanceOf(address(this));
        uint256 orderBookToken1BalanceBeforeLoan = token1.balanceOf(address(this));

        if (amount0 > 0 && !_sendToken(token0, recipient, amount0)) {
            revert Errors.LighterV2TokenTransfer_Failed();
        }

        if (amount1 > 0 && !_sendToken(token1, recipient, amount1)) {
            revert Errors.LighterV2TokenTransfer_Failed();
        }

        ILighterV2FlashCallback(msg.sender).flashLoanCallback(callbackData);

        if (token0.balanceOf(address(this)) < orderBookToken0BalanceBeforeLoan) {
            revert Errors.LighterV2FlashLoan_InsufficentCallbackTransfer();
        }

        if (token1.balanceOf(address(this)) < orderBookToken1BalanceBeforeLoan) {
            revert Errors.LighterV2FlashLoan_InsufficentCallbackTransfer();
        }

        emit FlashLoan(msg.sender, recipient, amount0, amount1);
    }

    /// @inheritdoc IOrderBook
    function depositToken(
        uint256 amountToDeposit,
        bool isToken0,
        bytes memory callbackData
    ) external override nonReentrant {
        address owner = msg.sender;
        IERC20Minimal token = isToken0 ? token0 : token1;
        uint256 balanceBefore = token.balanceOf(address(this));

        ILighterV2TransferCallback(owner).lighterV2TransferCallback(amountToDeposit, token, callbackData);

        if (token.balanceOf(address(this)) < balanceBefore + amountToDeposit) {
            revert Errors.LighterV2Vault_InsufficentCallbackTransfer();
        }
        if (isToken0) {
            claimableToken0Balance[owner] += amountToDeposit;
        } else {
            claimableToken1Balance[owner] += amountToDeposit;
        }
        emit ClaimableBalanceIncrease(owner, amountToDeposit, isToken0);
    }

    /// @inheritdoc IOrderBook
    function claimToken(uint256 amountToClaim, bool isToken0) external override nonReentrant {
        address owner = msg.sender;
        uint256 amount = isToken0 ? claimableToken0Balance[owner] : claimableToken1Balance[owner];
        if (amountToClaim > 0 && amountToClaim <= amount) {
            if (isToken0) {
                claimableToken0Balance[owner] -= amountToClaim;
                if (!_sendToken(token0, owner, amountToClaim)) {
                    revert Errors.LighterV2TokenTransfer_Failed();
                }
            } else {
                claimableToken1Balance[owner] -= amountToClaim;
                if (!_sendToken(token1, owner, amountToClaim)) {
                    revert Errors.LighterV2TokenTransfer_Failed();
                }
            }
            emit ClaimableBalanceDecrease(owner, amountToClaim, isToken0);
        } else {
            revert Errors.LighterV2Vault_InvalidClaimAmount();
        }
    }

    /// @dev Matches the given limit order against the available maker orders.
    /// @param order The taker order to be matched
    /// @param orderId The id of the taker order
    /// @param isAsk Indicates whether the taker order is an ask order or not
    /// @return filledAmount0 The total amount of token0 swapped in matching
    /// @return filledAmount1 The total amount of token1 swapped in matching
    /// @return swapCount The count of swaps performed
    /// @return swaps The array that contains data of swaps performed
    function _matchOrder(
        LimitOrder memory order,
        uint32 orderId,
        address owner,
        bool isAsk
    ) internal returns (uint256, uint256, uint32, SwapData[] memory) {
        MatchOrderLocalVars memory matchOrderLocalVars;

        mapping(uint32 => LimitOrder) storage makerOrders = isAsk ? _orders.bids : _orders.asks;

        matchOrderLocalVars.index = makerOrders[0].next;

        while (matchOrderLocalVars.index != 1 && order.amount0Base > 0) {
            LimitOrder storage bestOrder = makerOrders[matchOrderLocalVars.index];
            matchOrderLocalVars.makerAddress = ownerIdToAddress[bestOrder.ownerId];
            (matchOrderLocalVars.swapAmount0Base, matchOrderLocalVars.swapAmount1Base) = getLimitOrderSwapAmounts(
                order.amount0Base,
                order.priceBase,
                bestOrder.amount0Base,
                bestOrder.priceBase,
                isAsk
            );

            if (matchOrderLocalVars.swapAmount0Base == 0 || matchOrderLocalVars.swapAmount1Base == 0) break;

            matchOrderLocalVars.swapAmount0 = uint256(matchOrderLocalVars.swapAmount0Base) * sizeTick;
            matchOrderLocalVars.swapAmount1 =
                (uint256(matchOrderLocalVars.swapAmount1Base) * priceMultiplier) /
                priceDivider;

            if (isAsk) {
                emit Swap(
                    orderId,
                    matchOrderLocalVars.index,
                    owner,
                    matchOrderLocalVars.makerAddress,
                    matchOrderLocalVars.swapAmount0,
                    matchOrderLocalVars.swapAmount1
                );
            } else {
                emit Swap(
                    matchOrderLocalVars.index,
                    orderId,
                    matchOrderLocalVars.makerAddress,
                    owner,
                    matchOrderLocalVars.swapAmount0,
                    matchOrderLocalVars.swapAmount1
                );
            }

            matchOrderLocalVars.filledAmount0 = matchOrderLocalVars.filledAmount0 + matchOrderLocalVars.swapAmount0;
            matchOrderLocalVars.filledAmount1 = matchOrderLocalVars.filledAmount1 + matchOrderLocalVars.swapAmount1;

            // if there are not enough free slots in the matchOrderLocalVars.matchedOrders, increase size to accommodate
            if (matchOrderLocalVars.swapCount == matchOrderLocalVars.swapCapacity) {
                // initial capacity will be 4, and we'll double afterwards
                uint32 newCapacity = 4;
                if (matchOrderLocalVars.swapCapacity != 0) {
                    newCapacity = matchOrderLocalVars.swapCapacity * 2;
                }

                SwapData[] memory newSwaps = new SwapData[](newCapacity);
                for (uint32 i = 0; i < matchOrderLocalVars.swapCapacity; i += 1) {
                    newSwaps[i] = matchOrderLocalVars.swaps[i];
                }

                matchOrderLocalVars.swaps = newSwaps;
                matchOrderLocalVars.swapCapacity = newCapacity;
            }

            matchOrderLocalVars.swaps[matchOrderLocalVars.swapCount++] = SwapData({
                makerAddress: matchOrderLocalVars.makerAddress,
                isPerfMode: (bestOrder.perfMode_creatorId & 1 == 1),
                swapAmount: isAsk ? matchOrderLocalVars.swapAmount0 : matchOrderLocalVars.swapAmount1
            });

            order.amount0Base = order.amount0Base - matchOrderLocalVars.swapAmount0Base;

            if (bestOrder.amount0Base == matchOrderLocalVars.swapAmount0Base) {
                // Remove the best bid from the order book if it is fully filled
                matchOrderLocalVars.atLeastOneFullSwap = true;
                bestOrder.ownerId = 0;
            } else {
                // Update the best bid if it is partially filled
                bestOrder.amount0Base = bestOrder.amount0Base - matchOrderLocalVars.swapAmount0Base;
                break;
            }

            matchOrderLocalVars.index = bestOrder.next;
        }
        if (matchOrderLocalVars.atLeastOneFullSwap) {
            makerOrders[matchOrderLocalVars.index].prev = 0;
            makerOrders[0].next = matchOrderLocalVars.index;
        }

        return (
            matchOrderLocalVars.filledAmount0,
            matchOrderLocalVars.filledAmount1,
            matchOrderLocalVars.swapCount,
            matchOrderLocalVars.swaps
        );
    }

    /// @dev Matches the given swap request (market order) against the available maker orders.
    /// @param isAsk Indicates whether the swap request is an ask order or not
    /// @param isExactInput Indicates whether the swapper indicated exact input or output
    /// @param exactAmount The exact amount swapper wants to receive or send depending on isExactInput
    /// @param thresholdAmount The minimum amount to be received or maximum amount to be sent
    /// @param recipient The recipient address for swaps
    /// @return filledAmount0 The total amount of token0 swapped in matching
    /// @return filledAmount1 The total amount of token1 swapped in matching
    /// @return swapCount The count of swaps performed
    /// @return swaps The array that contains data of swaps performed
    function _matchSwapOrder(
        bool isAsk,
        bool isExactInput,
        uint256 exactAmount,
        uint256 thresholdAmount,
        address recipient
    ) internal returns (uint256, uint256, uint32, SwapData[] memory) {
        MatchOrderLocalVars memory matchOrderLocalVars;
        mapping(uint32 => LimitOrder) storage makerOrders = isAsk ? _orders.bids : _orders.asks;
        matchOrderLocalVars.amount = exactAmount;
        matchOrderLocalVars.index = makerOrders[0].next;
        matchOrderLocalVars.fullTakerFill = exactAmount == 0;

        while (matchOrderLocalVars.index != 1 && !matchOrderLocalVars.fullTakerFill) {
            LimitOrder storage bestMatch = makerOrders[matchOrderLocalVars.index];

            (
                matchOrderLocalVars.swapAmount0,
                matchOrderLocalVars.swapAmount1,
                matchOrderLocalVars.makerAmount0BaseChange,
                matchOrderLocalVars.fullTakerFill
            ) = (isExactInput && isAsk) || (!isExactInput && !isAsk)
                ? getSwapAmountsForToken0(matchOrderLocalVars.amount, isAsk, bestMatch.amount0Base, bestMatch.priceBase)
                : getSwapAmountsForToken1(
                    matchOrderLocalVars.amount,
                    isAsk,
                    bestMatch.amount0Base,
                    bestMatch.priceBase
                );

            // If the swap amount is 0, break the loop since next orders guaranteed to have 0 as well
            if (matchOrderLocalVars.swapAmount0 == 0 || matchOrderLocalVars.swapAmount1 == 0) break;

            if (isAsk) {
                emit Swap(
                    0, // emit 0 id for swap requests (market order)
                    matchOrderLocalVars.index,
                    recipient,
                    ownerIdToAddress[bestMatch.ownerId],
                    matchOrderLocalVars.swapAmount0,
                    matchOrderLocalVars.swapAmount1
                );
            } else {
                emit Swap(
                    matchOrderLocalVars.index,
                    0, // emit 0 id for swap requests (market order)
                    ownerIdToAddress[bestMatch.ownerId],
                    recipient,
                    matchOrderLocalVars.swapAmount0,
                    matchOrderLocalVars.swapAmount1
                );
            }

            matchOrderLocalVars.filledAmount0 += matchOrderLocalVars.swapAmount0;
            matchOrderLocalVars.filledAmount1 += matchOrderLocalVars.swapAmount1;

            // if there are not enough free slots in the matchOrderLocalVars.swaps, increase size to accommodate
            if (matchOrderLocalVars.swapCount == matchOrderLocalVars.swapCapacity) {
                // initial capacity will be 4, and we'll double afterwards
                uint32 newCapacity = 4;
                if (matchOrderLocalVars.swapCapacity != 0) {
                    newCapacity = matchOrderLocalVars.swapCapacity * 2;
                }

                SwapData[] memory newSwaps = new SwapData[](newCapacity);
                for (uint32 i = 0; i < matchOrderLocalVars.swapCapacity; i += 1) {
                    newSwaps[i] = matchOrderLocalVars.swaps[i];
                }

                matchOrderLocalVars.swaps = newSwaps;
                matchOrderLocalVars.swapCapacity = newCapacity;
            }

            matchOrderLocalVars.swaps[matchOrderLocalVars.swapCount++] = SwapData({
                makerAddress: ownerIdToAddress[bestMatch.ownerId],
                isPerfMode: (bestMatch.perfMode_creatorId & 1 == 1),
                swapAmount: isAsk ? matchOrderLocalVars.swapAmount0 : matchOrderLocalVars.swapAmount1
            });

            if (bestMatch.amount0Base == matchOrderLocalVars.makerAmount0BaseChange) {
                // Remove the best bid from the order book if it is fully filled
                matchOrderLocalVars.atLeastOneFullSwap = true;
                bestMatch.ownerId = 0;
            } else {
                // Update the best bid if it is partially filled
                bestMatch.amount0Base -= matchOrderLocalVars.makerAmount0BaseChange;
                break;
            }

            matchOrderLocalVars.index = bestMatch.next;
            if (matchOrderLocalVars.fullTakerFill) {
                // Break before updating the amount, if taker specifies exactOutput taker will receive largest
                // amount of output tokens they can buy with same input needed for exactOutput. Amount can be
                // negative if taker is receiving slightly more than exactOutput (depending on the ticks).
                break;
            }

            if ((isAsk && isExactInput) || (!isAsk && !isExactInput)) {
                matchOrderLocalVars.amount -= matchOrderLocalVars.swapAmount0;
            } else {
                matchOrderLocalVars.amount -= matchOrderLocalVars.swapAmount1;
            }
        }

        if (matchOrderLocalVars.atLeastOneFullSwap) {
            makerOrders[matchOrderLocalVars.index].prev = 0;
            makerOrders[0].next = matchOrderLocalVars.index;
        }

        if (!matchOrderLocalVars.fullTakerFill) {
            revert Errors.LighterV2Swap_NotEnoughLiquidity();
        }

        if (
            isExactInput &&
            ((isAsk && matchOrderLocalVars.filledAmount1 < thresholdAmount) ||
                (!isAsk && matchOrderLocalVars.filledAmount0 < thresholdAmount))
        ) {
            revert Errors.LighterV2Swap_NotEnoughOutput();
        } else if (
            !isExactInput &&
            ((isAsk && matchOrderLocalVars.filledAmount0 > thresholdAmount) ||
                (!isAsk && matchOrderLocalVars.filledAmount1 > thresholdAmount))
        ) {
            revert Errors.LighterV2Swap_TooMuchRequested();
        }

        return (
            matchOrderLocalVars.filledAmount0,
            matchOrderLocalVars.filledAmount1,
            matchOrderLocalVars.swapCount,
            matchOrderLocalVars.swaps
        );
    }

    /// @dev Handles the payment logic for a matched order.
    /// @param paymentData The payment data containing information about the swaps and payments
    function _handlePayments(PaymentData memory paymentData) internal {
        // Determine debit and credit tokens based on the order type
        IERC20Minimal debitToken = paymentData.isAsk ? token0 : token1;
        IERC20Minimal creditToken = paymentData.isAsk ? token1 : token0;

        uint256 debitTokenAmount = (paymentData.isAsk ? paymentData.filledAmount0 : paymentData.filledAmount1) +
            paymentData.remainingLimitOrderAmount;
        uint256 creditTokenAmount = paymentData.isAsk ? paymentData.filledAmount1 : paymentData.filledAmount0;

        if (creditTokenAmount > 0) {
            if (paymentData.isPerfMode) {
                if (paymentData.isAsk) {
                    claimableToken1Balance[paymentData.recipient] += creditTokenAmount;
                } else {
                    claimableToken0Balance[paymentData.recipient] += creditTokenAmount;
                }
                // Omit emitting ClaimableBalanceIncrease for gas savings, can be inferred from swap events
            } else {
                if (!_sendToken(creditToken, paymentData.recipient, creditTokenAmount)) {
                    revert Errors.LighterV2TokenTransfer_Failed();
                }
            }
        }

        if (paymentData.isPerfMode) {
            if (paymentData.isAsk) {
                if (claimableToken0Balance[msg.sender] < debitTokenAmount) {
                    revert Errors.LighterV2Order_InsufficientClaimableBalance();
                }
                claimableToken0Balance[msg.sender] -= debitTokenAmount;
            } else {
                if (claimableToken1Balance[msg.sender] < debitTokenAmount) {
                    revert Errors.LighterV2Order_InsufficientClaimableBalance();
                }
                claimableToken1Balance[msg.sender] -= debitTokenAmount;
            }
            // Omit emitting ClaimableBalanceDecrease for gas savings, can be inferred from swap and order creation events
        } else {
            uint256 debitTokenBalanceBeforeDebit = debitToken.balanceOf(address(this));

            ILighterV2TransferCallback(msg.sender).lighterV2TransferCallback(
                debitTokenAmount,
                debitToken,
                paymentData.callbackData
            );

            if (debitToken.balanceOf(address(this)) < (debitTokenBalanceBeforeDebit + debitTokenAmount)) {
                revert Errors.LighterV2Order_InsufficentCallbackTransfer();
            }
        }

        // Loop through swaps and transfer tokens to the maker order owners
        for (uint32 swapIndex; swapIndex < paymentData.swapCount; ++swapIndex) {
            SwapData memory swapData = paymentData.swaps[swapIndex];
            if (swapData.isPerfMode) {
                if (paymentData.isAsk) {
                    claimableToken0Balance[swapData.makerAddress] += swapData.swapAmount;
                } else {
                    claimableToken1Balance[swapData.makerAddress] += swapData.swapAmount;
                }
                // omit emitting ClaimableBalanceIncrease for gas savings, can be inferred from swap events
            } else {
                bool success = _sendToken(debitToken, swapData.makerAddress, swapData.swapAmount);
                if (!success) {
                    // if transfer to maker fails, mark the amount as claimable for maker
                    if (paymentData.isAsk) {
                        claimableToken0Balance[swapData.makerAddress] += swapData.swapAmount;
                    } else {
                        claimableToken1Balance[swapData.makerAddress] += swapData.swapAmount;
                    }
                    emit ClaimableBalanceIncrease(swapData.makerAddress, swapData.swapAmount, paymentData.isAsk);
                }
            }
        }
    }

    /// @notice Transfer tokens from the order book to the user
    /// @param tokenToTransfer The token to transfer
    /// @param to The address to transfer to
    /// @param amount The amount to transfer
    /// @return success Whether the transfer was successful or not
    function _sendToken(IERC20Minimal tokenToTransfer, address to, uint256 amount) internal returns (bool) {
        uint256 orderBookBalanceBefore = tokenToTransfer.balanceOf(address(this));
        bool success = false;
        try tokenToTransfer.transfer(to, amount) returns (bool ret) {
            success = ret;
        } catch {
            success = false;
        }

        uint256 sentAmount = success ? amount : 0;
        if (tokenToTransfer.balanceOf(address(this)) + sentAmount < orderBookBalanceBefore) {
            revert Errors.LighterV2Base_ContractBalanceDoesNotMatchSentAmount();
        }
        return success;
    }

    /// @inheritdoc IOrderBook
    function suggestHintId(uint64 priceBase, bool isAsk) external view override returns (uint32) {
        return _orders.suggestHintId(priceBase, isAsk);
    }

    /// @inheritdoc IOrderBook
    function getLimitOrderSwapAmounts(
        uint64 takerOrderAmount0Base,
        uint64 takerOrderPriceBase,
        uint64 makerOrderAmount0Base,
        uint64 makerOrderPriceBase,
        bool isTakerAsk
    ) public pure override returns (uint64 amount0BaseReturn, uint128 amount1BaseReturn) {
        // If the takerOrder is an ask, and the makerOrder price is at least
        // the takerOrder's price, then the takerOrder can be filled
        // If the takerOrder is a bid, and the makerOrder price is at most
        // the takerOrder's price, then the takerOrder can be filled
        if (
            (isTakerAsk && makerOrderPriceBase >= takerOrderPriceBase) ||
            (!isTakerAsk && takerOrderPriceBase >= makerOrderPriceBase)
        ) {
            if (takerOrderAmount0Base < makerOrderAmount0Base) {
                amount0BaseReturn = takerOrderAmount0Base;
            } else {
                amount0BaseReturn = makerOrderAmount0Base;
            }
            return (amount0BaseReturn, uint128(amount0BaseReturn * makerOrderPriceBase));
        }

        return (0, 0);
    }

    /// @inheritdoc IOrderBook
    function getSwapAmountsForToken0(
        uint256 amount0,
        bool isAsk,
        uint64 makerAmount0Base,
        uint64 makerPriceBase
    )
        public
        view
        override
        returns (uint256 swapAmount0, uint256 swapAmount1, uint64 amount0BaseDelta, bool fullTakerFill)
    {
        uint256 amount0BaseToTake;
        if (isAsk) {
            amount0BaseToTake = amount0 / sizeTick;
        } else {
            amount0BaseToTake = Math.ceilDiv(amount0, sizeTick);
        }
        if (amount0BaseToTake > makerAmount0Base) {
            amount0BaseToTake = makerAmount0Base;
            fullTakerFill = false;
        } else {
            fullTakerFill = true;
        }
        amount0BaseDelta = uint64(amount0BaseToTake);
        swapAmount0 = uint256(amount0BaseDelta) * sizeTick;
        swapAmount1 = (uint256(amount0BaseDelta) * makerPriceBase * priceMultiplier) / priceDivider;
    }

    /// @inheritdoc IOrderBook
    function getSwapAmountsForToken1(
        uint256 amount1,
        bool isAsk,
        uint64 makerAmount0Base,
        uint64 makerPriceBase
    )
        public
        view
        override
        returns (uint256 swapAmount0, uint256 swapAmount1, uint64 amount0BaseDelta, bool fullTakerFill)
    {
        uint256 amount0BaseToTake = Math.mulDiv(amount1, priceDivider, makerPriceBase * priceMultiplier);
        if (isAsk) {
            swapAmount1 = (amount0BaseToTake * makerPriceBase * priceMultiplier) / priceDivider;
            if (swapAmount1 < amount1) {
                amount0BaseToTake += 1;
            }
        }
        if (amount0BaseToTake > makerAmount0Base) {
            amount0BaseToTake = makerAmount0Base;
            fullTakerFill = false;
        } else {
            fullTakerFill = true;
        }
        amount0BaseDelta = uint64(amount0BaseToTake);
        swapAmount1 = (uint256(amount0BaseDelta) * makerPriceBase * priceMultiplier) / priceDivider;
        swapAmount0 = uint256(amount0BaseDelta) * sizeTick;
    }

    /// @inheritdoc IOrderBook
    function getPaginatedOrders(
        uint32 startOrderId,
        bool isAsk,
        uint32 limit
    ) external view override returns (OrderQueryItem memory) {
        return _orders.getPaginatedOrders(startOrderId, isAsk, limit, ownerIdToAddress, sizeTick, priceTick);
    }

    /// @inheritdoc IOrderBook
    function getLimitOrder(bool isAsk, uint32 id) external view override returns (LimitOrder memory) {
        return isAsk ? _orders.asks[id] : _orders.bids[id];
    }

    /// @inheritdoc IOrderBook
    function isOrderActive(uint32 id) public view override returns (bool) {
        return _orders.asks[id].ownerId != 0 || _orders.bids[id].ownerId != 0;
    }

    /// @inheritdoc IOrderBook
    function isAskOrder(uint32 id) public view override returns (bool) {
        if (!isOrderActive(id)) {
            revert Errors.LighterV2Order_OrderDoesNotExist();
        }

        return _orders.asks[id].ownerId > 1;
    }
}