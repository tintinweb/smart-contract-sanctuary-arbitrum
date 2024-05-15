/**
 *Submitted for verification at Arbiscan.io on 2024-05-15
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// lib/openzeppelin-contracts/contracts/utils/math/Math.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

// lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// src/interfaces/CommonErrors.sol

/**
 * @notice Used when an array has invalid length.
 */
error InvalidArrayLength();

/**
 * @notice Used when group of smart vaults or strategies do not have same asset group.
 */
error NotSameAssetGroup();

/**
 * @notice Used when configuring an address with a zero address.
 */
error ConfigurationAddressZero();

/**
 * @notice Used when constructor or intializer parameters are invalid.
 */
error InvalidConfiguration();

/**
 * @notice Used when fetched exchange rate is out of slippage range.
 */
error ExchangeRateOutOfSlippages();

/**
 * @notice Used when an invalid strategy is provided.
 * @param address_ Address of the invalid strategy.
 */
error InvalidStrategy(address address_);

/**
 * @notice Used when doing low-level call on an address that is not a contract.
 * @param address_ Address of the contract
 */
error AddressNotContract(address address_);

/**
 * @notice Used when invoking an only view execution and tx.origin is not address zero.
 * @param address_ Address of the tx.origin
 */
error OnlyViewExecution(address address_);

// src/interfaces/ISwapper.sol

/* ========== STRUCTS ========== */

/**
 * @notice Information needed to make a swap of assets.
 * @custom:member swapTarget Contract executing the swap.
 * @custom:member token Token to be swapped.
 * @custom:member swapCallData Calldata describing the swap itself.
 */
struct SwapInfo {
    address swapTarget;
    address token;
    bytes swapCallData;
}

/* ========== ERRORS ========== */

/**
 * @notice Used when trying to do a swap via an exchange that is not allowed to execute a swap.
 * @param exchange Exchange used.
 */
error ExchangeNotAllowed(address exchange);

/**
 * @notice Used when trying to execute a swap but are not authorized.
 * @param caller Caller of the swap method.
 */
error NotSwapper(address caller);

/* ========== INTERFACES ========== */

interface ISwapper {
    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when the exchange allowlist is updated.
     * @param exchange Exchange that was updated.
     * @param isAllowed Whether the exchange is allowed to be used in a swap or not after the update.
     */
    event ExchangeAllowlistUpdated(address indexed exchange, bool isAllowed);

    event Swapped(
        address indexed receiver, address[] tokensIn, address[] tokensOut, uint256[] amountsIn, uint256[] amountsOut
    );

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Performs a swap of tokens with external contracts.
     * - deposit tokens into the swapper contract
     * - swapper will swap tokens based on swap info provided
     * - swapper will return unswapped tokens to the receiver
     * @param tokensIn Addresses of tokens available for the swap.
     * @param swapInfo Information needed to perform the swap.
     * @param tokensOut Addresses of tokens to swap to.
     * @param receiver Receiver of unswapped tokens.
     * @return amountsOut Amounts of `tokensOut` sent from the swapper to the receiver.
     */
    function swap(
        address[] calldata tokensIn,
        SwapInfo[] calldata swapInfo,
        address[] calldata tokensOut,
        address receiver
    ) external returns (uint256[] memory amountsOut);

    /**
     * @notice Updates list of exchanges that can be used in a swap.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SPOOL_ADMIN
     *   - exchanges and allowed arrays need to be of same length
     * @param exchanges Addresses of exchanges.
     * @param allowed Whether an exchange is allowed to be used in a swap.
     */
    function updateExchangeAllowlist(address[] calldata exchanges, bool[] calldata allowed) external;

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Checks if an exchange is allowed to be used in a swap.
     * @param exchange Exchange to check.
     * @return isAllowed True if the exchange is allowed to be used in a swap, false otherwise.
     */
    function isExchangeAllowed(address exchange) external view returns (bool isAllowed);
}

// src/interfaces/IUsdPriceFeedManager.sol

/// @dev Number of decimals used for USD values.
uint256 constant USD_DECIMALS = 18;

/**
 * @notice Emitted when asset is invalid.
 * @param asset Invalid asset.
 */
error InvalidAsset(address asset);

/**
 * @notice Emitted when price returned by price aggregator is negative or zero.
 * @param price Actual price returned by price aggregator.
 */
error NonPositivePrice(int256 price);

/**
 * @notice Emitted when pricing data returned by price aggregator is not from the current
 * round or the round hasn't finished.
 */
error StalePriceData();

interface IUsdPriceFeedManager {
    /**
     * @notice Gets number of decimals for an asset.
     * @param asset Address of the asset.
     * @return assetDecimals Number of decimals for the asset.
     */
    function assetDecimals(address asset) external view returns (uint256 assetDecimals);

    /**
     * @notice Gets number of decimals for USD.
     * @return usdDecimals Number of decimals for USD.
     */
    function usdDecimals() external view returns (uint256 usdDecimals);

    /**
     * @notice Calculates asset value in USD using current price.
     * @param asset Address of asset.
     * @param assetAmount Amount of asset in asset decimals.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsd(address asset, uint256 assetAmount) external view returns (uint256 usdValue);

    /**
     * @notice Calculates USD value in asset using current price.
     * @param asset Address of asset.
     * @param usdAmount Amount of USD in USD decimals.
     * @return assetValue Value in asset in asset decimals.
     */
    function usdToAsset(address asset, uint256 usdAmount) external view returns (uint256 assetValue);

    /**
     * @notice Calculates asset value in USD using provided price.
     * @param asset Address of asset.
     * @param assetAmount Amount of asset in asset decimals.
     * @param price Price of asset in USD.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsdCustomPrice(address asset, uint256 assetAmount, uint256 price)
        external
        view
        returns (uint256 usdValue);

    /**
     * @notice Calculates assets value in USD using provided prices.
     * @param assets Addresses of assets.
     * @param assetAmounts Amounts of assets in asset decimals.
     * @param prices Prices of asset in USD.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsdCustomPriceBulk(
        address[] calldata assets,
        uint256[] calldata assetAmounts,
        uint256[] calldata prices
    ) external view returns (uint256 usdValue);

    /**
     * @notice Calculates USD value in asset using provided price.
     * @param asset Address of asset.
     * @param usdAmount Amount of USD in USD decimals.
     * @param price Price of asset in USD.
     * @return assetValue Value in asset in asset decimals.
     */
    function usdToAssetCustomPrice(address asset, uint256 usdAmount, uint256 price)
        external
        view
        returns (uint256 assetValue);
}

// src/libraries/ArrayMapping.sol

library ArrayMappingUint256 {
    /**
     * @notice Map mapping(uint256 => uint256)) values to an array.
     */
    function toArray(mapping(uint256 => uint256) storage _self, uint256 length)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory arrayOut = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            arrayOut[i] = _self[i];
        }
        return arrayOut;
    }

    /**
     * @notice Set array values to mapping slots.
     */
    function setValues(mapping(uint256 => uint256) storage _self, uint256[] calldata values) external {
        for (uint256 i; i < values.length; ++i) {
            _self[i] = values[i];
        }
    }
}

library ArrayMappingAddress {
    /**
     * @notice Map mapping(uint256 => address)) values to an array.
     */
    function toArray(mapping(uint256 => address) storage _self, uint256 length)
        external
        view
        returns (address[] memory)
    {
        address[] memory arrayOut = new address[](length);
        for (uint256 i; i < length; ++i) {
            arrayOut[i] = _self[i];
        }
        return arrayOut;
    }

    /**
     * @notice Set array values to mapping slots.
     */
    function setValues(mapping(uint256 => address) storage _self, address[] calldata values) external {
        for (uint256 i; i < values.length; ++i) {
            _self[i] = values[i];
        }
    }
}

// src/libraries/uint16a16Lib.sol

type uint16a16 is uint256;

/**
 * @notice This library enables packing of sixteen uint16 elements into one uint256 word.
 */
library uint16a16Lib {
    /// @notice Number of bits per stored element.
    uint256 constant bits = 16;

    /// @notice Maximal number of elements stored.
    uint256 constant elements = 16;

    // must ensure that bits * elements <= 256

    /// @notice Range covered by stored element.
    uint256 constant range = 1 << bits;

    /// @notice Maximal value of stored element.
    uint256 constant max = range - 1;

    /**
     * @notice Gets element from packed array.
     * @param va Packed array.
     * @param index Index of element to get.
     * @return element Element of va stored in index index.
     */
    function get(uint16a16 va, uint256 index) internal pure returns (uint256) {
        require(index < elements);
        return (uint16a16.unwrap(va) >> (bits * index)) & max;
    }

    /**
     * @notice Sets element to packed array.
     * @param va Packed array.
     * @param index Index under which to store the element
     * @param ev Element to store.
     * @return va Packed array with stored element.
     */
    function set(uint16a16 va, uint256 index, uint256 ev) internal pure returns (uint16a16) {
        require(index < elements);
        require(ev < range);
        index *= bits;
        return uint16a16.wrap((uint16a16.unwrap(va) & ~(max << index)) | (ev << index));
    }

    /**
     * @notice Sets elements to packed array.
     * Elements are stored continuously from index 0 onwards.
     * @param va Packed array.
     * @param ev Elements to store.
     * @return va Packed array with stored elements.
     */
    function set(uint16a16 va, uint256[] memory ev) internal pure returns (uint16a16) {
        for (uint256 i; i < ev.length; ++i) {
            va = set(va, i, ev[i]);
        }

        return va;
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// src/interfaces/IAssetGroupRegistry.sol

/* ========== ERRORS ========== */

/**
 * @notice Used when invalid ID for asset group is provided.
 * @param assetGroupId Invalid ID for asset group.
 */
error InvalidAssetGroup(uint256 assetGroupId);

/**
 * @notice Used when no assets are provided for an asset group.
 */
error NoAssetsProvided();

/**
 * @notice Used when token is not allowed to be used as an asset.
 * @param token Address of the token that is not allowed.
 */
error TokenNotAllowed(address token);

/**
 * @notice Used when asset group already exists.
 * @param assetGroupId ID of the already existing asset group.
 */
error AssetGroupAlreadyExists(uint256 assetGroupId);

/**
 * @notice Used when given array is unsorted.
 */
error UnsortedArray();

/* ========== INTERFACES ========== */

interface IAssetGroupRegistry {
    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when token is allowed to be used as an asset.
     * @param token Address of newly allowed token.
     */
    event TokenAllowed(address indexed token);

    /**
     * @notice Emitted when asset group is registered.
     * @param assetGroupId ID of the newly registered asset group.
     */
    event AssetGroupRegistered(uint256 indexed assetGroupId);

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Checks if token is allowed to be used as an asset.
     * @param token Address of token to check.
     * @return isAllowed True if token is allowed, false otherwise.
     */
    function isTokenAllowed(address token) external view returns (bool isAllowed);

    /**
     * @notice Gets number of registered asset groups.
     * @return count Number of registered asset groups.
     */
    function numberOfAssetGroups() external view returns (uint256 count);

    /**
     * @notice Gets asset group by its ID.
     * @dev Requirements:
     * - must provide a valid ID for the asset group
     * @return assets Array of assets in the asset group.
     */
    function listAssetGroup(uint256 assetGroupId) external view returns (address[] memory assets);

    /**
     * @notice Gets asset group length.
     * @dev Requirements:
     * - must provide a valid ID for the asset group
     * @return length
     */
    function assetGroupLength(uint256 assetGroupId) external view returns (uint256 length);

    /**
     * @notice Validates that provided ID represents an asset group.
     * @dev Function reverts when ID does not represent an asset group.
     * @param assetGroupId ID to validate.
     */
    function validateAssetGroup(uint256 assetGroupId) external view;

    /**
     * @notice Checks if asset group composed of assets already exists.
     * Will revert if provided assets cannot form an asset group.
     * @param assets Assets composing the asset group.
     * @return Asset group ID if such asset group exists, 0 otherwise.
     */
    function checkAssetGroupExists(address[] calldata assets) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Allows a token to be used as an asset.
     * @dev Requirements:
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param token Address of token to be allowed.
     */
    function allowToken(address token) external;

    /**
     * @notice Allows tokens to be used as assets.
     * @dev Requirements:
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param tokens Addresses of tokens to be allowed.
     */
    function allowTokenBatch(address[] calldata tokens) external;

    /**
     * @notice Registers a new asset group.
     * @dev Requirements:
     * - must provide at least one asset
     * - all assets must be allowed
     * - assets must be sorted
     * - such asset group should not exist yet
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param assets Array of assets in the asset group.
     * @return id Sequential ID assigned to the asset group.
     */
    function registerAssetGroup(address[] calldata assets) external returns (uint256 id);
}

// src/interfaces/IMasterWallet.sol

interface IMasterWallet {
    /**
     * @notice Transfers amount of token to the recipient.
     * @dev Requirements:
     * - caller must have role ROLE_MASTER_WALLET_MANAGER
     * @param token Token to transfer.
     * @param recipient Target of the transfer.
     * @param amount Amount to transfer.
     */
    function transfer(IERC20 token, address recipient, uint256 amount) external;
}

// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// src/interfaces/IStrategy.sol

/**
 * @notice Struct holding information how to swap the assets.
 * @custom:member slippage minumum output amount
 * @custom:member path swap path, first byte represents an action (e.g. Uniswap V2 custom swap), rest is swap specific path
 */
struct SwapData {
    uint256 slippage; // min amount out
    bytes path; // 1st byte is action, then path
}

/**
 * @notice Parameters for calling do hard work on strategy.
 * @custom:member swapInfo Information for swapping assets before depositing into the protocol.
 * @custom:member swapInfo Information for swapping rewards before depositing them back into the protocol.
 * @custom:member slippages Slippages used to constrain depositing and withdrawing from the protocol.
 * @custom:member assetGroup Asset group of the strategy.
 * @custom:member exchangeRates Exchange rates for assets.
 * @custom:member withdrawnShares Strategy shares withdrawn by smart vault.
 * @custom:member masterWallet Master wallet.
 * @custom:member priceFeedManager Price feed manager.
 * @custom:member baseYield Base yield value, manual input for specific strategies.
 * @custom:member platformFees Platform fees info.
 */
struct StrategyDhwParameterBag {
    SwapInfo[] swapInfo;
    SwapInfo[] compoundSwapInfo;
    uint256[] slippages;
    address[] assetGroup;
    uint256[] exchangeRates;
    uint256 withdrawnShares;
    address masterWallet;
    IUsdPriceFeedManager priceFeedManager;
    int256 baseYield;
    PlatformFees platformFees;
}

/**
 * @notice Information about results of the do hard work.
 * @custom:member sharesMinted Amount of strategy shares minted.
 * @custom:member assetsWithdrawn Amount of assets withdrawn.
 * @custom:member yieldPercentage Yield percentage from the previous DHW.
 * @custom:member valueAtDhw Value of the strategy at the end of DHW.
 * @custom:member totalSstsAtDhw Total SSTs at the end of DHW.
 */
struct DhwInfo {
    uint256 sharesMinted;
    uint256[] assetsWithdrawn;
    int256 yieldPercentage;
    uint256 valueAtDhw;
    uint256 totalSstsAtDhw;
}

/**
 * @notice Used when ghost strategy is called.
 */
error IsGhostStrategy();

/**
 * @notice Used when user is not allowed to redeem fast.
 * @param user User that tried to redeem fast.
 */
error NotFastRedeemer(address user);

/**
 * @notice Used when asset group ID is not correctly initialized.
 */
error InvalidAssetGroupIdInitialization();

interface IStrategy is IERC20Upgradeable {
    /* ========== EVENTS ========== */

    event Deposited(
        uint256 mintedShares, uint256 usdWorthDeposited, uint256[] assetsBeforeSwap, uint256[] assetsDeposited
    );

    event Withdrawn(uint256 withdrawnShares, uint256 usdWorthWithdrawn, uint256[] withdrawnAssets);

    event PlatformFeesCollected(address indexed strategy, uint256 sharesMinted);

    event Slippages(bool isDeposit, uint256 slippage, bytes data);

    event BeforeDepositCheckSlippages(uint256[] amounts);

    event BeforeRedeemalCheckSlippages(uint256 ssts);

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Gets strategy name.
     * @return name Name of the strategy.
     */
    function strategyName() external view returns (string memory name);

    /**
     * @notice Gets required ratio between underlying assets.
     * @return ratio Required asset ratio for the strategy.
     */
    function assetRatio() external view returns (uint256[] memory ratio);

    /**
     * @notice Gets asset group used by the strategy.
     * @return id ID of the asset group.
     */
    function assetGroupId() external view returns (uint256 id);

    /**
     * @notice Gets underlying assets for the strategy.
     * @return assets Addresses of the underlying assets.
     */
    function assets() external view returns (address[] memory assets);

    /**
     * @notice Gets underlying asset amounts for the strategy.
     * @return amounts Amounts of the underlying assets.
     */
    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Performs slippages check before depositing.
     * @param amounts Amounts to be deposited.
     * @param slippages Slippages to check against.
     */
    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) external;

    /**
     * @dev Performs slippages check before redeemal.
     * @param ssts Amount of strategy tokens to be redeemed.
     * @param slippages Slippages to check against.
     */
    function beforeRedeemalCheck(uint256 ssts, uint256[] calldata slippages) external;

    /**
     * @notice Does hard work:
     * - compounds rewards
     * - deposits into the protocol
     * - withdraws from the protocol
     * @dev Requirements:
     * - caller must have role ROLE_STRATEGY_REGISTRY
     * @param dhwParams Parameters for the do hard work.
     * @return info Information about do the performed hard work.
     */
    function doHardWork(StrategyDhwParameterBag calldata dhwParams) external returns (DhwInfo memory info);

    /**
     * @notice Claims strategy shares after do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault claiming shares.
     * @param amount Amount of strategy shares to claim.
     */
    function claimShares(address smartVault, uint256 amount) external;

    /**
     * @notice Releases shares back to strategy.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault releasing shares.
     * @param amount Amount of strategy shares to release.
     */
    function releaseShares(address smartVault, uint256 amount) external;

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @dev Requirements:
     * - caller must have either role ROLE_SMART_VAULT_MANAGER or role ROLE_STRATEGY_REGISTRY
     * @param shares Amount of shares to redeem.
     * @param masterWallet Address of the master wallet.
     * @param assetGroup Asset group of the strategy.
     * @param slippages Slippages to guard redeeming.
     * @return assetsWithdrawn Amount of assets withdrawn.
     */
    function redeemFast(
        uint256 shares,
        address masterWallet,
        address[] calldata assetGroup,
        uint256[] calldata slippages
    ) external returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @param shares Amount of shares to redeem.
     * @param redeemer Address of he redeemer, owner of SSTs.
     * @param assetGroup Asset group of the strategy.
     * @param slippages Slippages to guard redeeming.
     * @return assetsWithdrawn Amount of assets withdrawn.
     */
    function redeemShares(uint256 shares, address redeemer, address[] calldata assetGroup, uint256[] calldata slippages)
        external
        returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Instantly deposits into the protocol.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param assetGroup Asset group of the strategy.
     * @param exchangeRates Asset to USD exchange rates.
     * @param priceFeedManager Price feed manager contract.
     * @param slippages Slippages to guard depositing.
     * @param swapInfo Information for swapping assets before depositing into the protocol.
     * @return sstsMinted Amount of SSTs minted.
     */
    function depositFast(
        address[] calldata assetGroup,
        uint256[] calldata exchangeRates,
        IUsdPriceFeedManager priceFeedManager,
        uint256[] calldata slippages,
        SwapInfo[] calldata swapInfo
    ) external returns (uint256 sstsMinted);

    /**
     * @notice Instantly withdraws assets, bypassing shares mechanism.
     * Transfers withdrawn assets to the emergency withdrawal wallet.
     * @dev Requirements:
     * - caller must have role ROLE_STRATEGY_REGISTRY
     * @param slippages Slippages to guard redeeming.
     * @param recipient Recipient address
     */
    function emergencyWithdraw(uint256[] calldata slippages, address recipient) external;

    /**
     * @notice Gets USD worth of the strategy.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param exchangeRates Asset to USD exchange rates.
     * @param priceFeedManager Price feed manager contract.
     */
    function getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        external
        returns (uint256 usdWorth);

    /**
     * @notice Gets protocol rewards.
     * @dev Requirements:
     * - can only be called in view-execution mode.
     * @return tokens Addresses of reward tokens.
     * @return amounts Amount of reward tokens available.
     */
    function getProtocolRewards() external returns (address[] memory tokens, uint256[] memory amounts);
}

// src/interfaces/IStrategyRegistry.sol

/* ========== ERRORS ========== */

/**
 * @notice Used when trying to register an already registered strategy.
 * @param address_ Address of already registered strategy.
 */
error StrategyAlreadyRegistered(address address_);

/**
 * @notice Used when DHW was not run yet for a strategy index.
 * @param strategy Address of the strategy.
 * @param strategyIndex Index of the strategy.
 */
error DhwNotRunYetForIndex(address strategy, uint256 strategyIndex);

/**
 * @notice Used when provided token list is invalid.
 */
error InvalidTokenList();

/**
 * @notice Used when ghost strategy is used.
 */
error GhostStrategyUsed();

/**
 * @notice Used when syncing vault that is already fully synced.
 */
error NothingToSync();

/**
 * @notice Used when system tries to configure a too large ecosystem fee.
 * @param ecosystemFeePct Requested ecosystem fee.
 */
error EcosystemFeeTooLarge(uint256 ecosystemFeePct);

/**
 * @notice Used when system tries to configure a too large treasury fee.
 * @param treasuryFeePct Requested treasury fee.
 */
error TreasuryFeeTooLarge(uint256 treasuryFeePct);

/**
 * @notice Used when user tries to re-add a strategy that was previously removed from the system.
 * @param strategy Strategy address
 */
error StrategyPreviouslyRemoved(address strategy);

/**
 * @notice Represents change of state for a strategy during a DHW.
 * @custom:member exchangeRates Exchange rates between assets and USD.
 * @custom:member assetsDeposited Amount of assets deposited into the strategy.
 * @custom:member sharesMinted Amount of strategy shares minted.
 * @custom:member totalSSTs Amount of strategy shares at the end of the DHW.
 * @custom:member totalStrategyValue Total strategy value at the end of the DHW.
 * @custom:member dhwYields DHW yield percentage from the previous DHW.
 */
struct StrategyAtIndex {
    uint256[] exchangeRates;
    uint256[] assetsDeposited;
    uint256 sharesMinted;
    uint256 totalSSTs;
    uint256 totalStrategyValue;
    int256 dhwYields;
}

/**
 * @notice Parameters for calling do hard work.
 * @custom:member strategies Strategies to do-hard-worked upon, grouped by their asset group.
 * @custom:member swapInfo Information for swapping assets before depositing into protocol. SwapInfo[] per each strategy.
 * @custom:member compoundSwapInfo Information for swapping rewards before depositing them back into the protocol. SwapInfo[] per each strategy.
 * @custom:member strategySlippages Slippages used to constrain depositing into and withdrawing from the protocol. uint256[] per strategy.
 * @custom:member baseYields Base yield percentage the strategy created in the DHW period (applicable only for some strategies).
 * @custom:member tokens List of all asset tokens involved in the do hard work.
 * @custom:member exchangeRateSlippages Slippages used to constrain exchange rates for asset tokens. uint256[2] for each token.
 * @custom:member validUntil Sets the maximum timestamp the user is willing to wait to start executing 'do hard work'.
 */
struct DoHardWorkParameterBag {
    address[][] strategies;
    SwapInfo[][][] swapInfo;
    SwapInfo[][][] compoundSwapInfo;
    uint256[][][] strategySlippages;
    int256[][] baseYields;
    address[] tokens;
    uint256[2][] exchangeRateSlippages;
    uint256 validUntil;
}

/**
 * @notice Parameters for calling redeem fast.
 * @custom:member strategies Addresses of strategies.
 * @custom:member strategyShares Amount of shares to redeem.
 * @custom:member assetGroup Asset group of the smart vault.
 * @custom:member slippages Slippages to guard withdrawal.
 */
struct RedeemFastParameterBag {
    address[] strategies;
    uint256[] strategyShares;
    address[] assetGroup;
    uint256[][] withdrawalSlippages;
}

/**
 * @notice Group of platform fees.
 * @custom:member ecosystemFeeReciever Receiver of the ecosystem fees.
 * @custom:member ecosystemFeePct Ecosystem fees. Expressed in FULL_PERCENT.
 * @custom:member treasuryFeeReciever Receiver of the treasury fees.
 * @custom:member treasuryFeePct Treasury fees. Expressed in FULL_PERCENT.
 */
struct PlatformFees {
    address ecosystemFeeReceiver;
    uint96 ecosystemFeePct;
    address treasuryFeeReceiver;
    uint96 treasuryFeePct;
}

/* ========== INTERFACES ========== */

interface IStrategyRegistry {
    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Returns address of emergency withdrawal wallet.
     * @return emergencyWithdrawalWallet Address of the emergency withdrawal wallet.
     */
    function emergencyWithdrawalWallet() external view returns (address emergencyWithdrawalWallet);

    /**
     * @notice Returns current do-hard-work indexes for strategies.
     * @param strategies Strategies.
     * @return dhwIndexes Current do-hard-work indexes for strategies.
     */
    function currentIndex(address[] calldata strategies) external view returns (uint256[] memory dhwIndexes);

    /**
     * @notice Returns current strategy APYs.
     * @param strategies Strategies.
     */
    function strategyAPYs(address[] calldata strategies) external view returns (int256[] memory apys);

    /**
     * @notice Returns assets deposited into a do-hard-work index for a strategy.
     * @param strategy Strategy.
     * @param dhwIndex Do-hard-work index.
     * @return assets Assets deposited into the do-hard-work index for the strategy.
     */
    function depositedAssets(address strategy, uint256 dhwIndex) external view returns (uint256[] memory assets);

    /**
     * @notice Returns shares redeemed in a do-hard-work index for a strategy.
     * @param strategy Strategy.
     * @param dhwIndex Do-hard-work index.
     * @return shares Shares redeemed in a do-hard-work index for the strategy.
     */
    function sharesRedeemed(address strategy, uint256 dhwIndex) external view returns (uint256 shares);

    /**
     * @notice Gets timestamps when do-hard-works were performed.
     * @param strategies Strategies.
     * @param dhwIndexes Do-hard-work indexes.
     * @return timestamps Timestamp for each pair of strategies and do-hard-work indexes.
     */
    function dhwTimestamps(address[] calldata strategies, uint16a16 dhwIndexes)
        external
        view
        returns (uint256[] memory timestamps);

    function getDhwYield(address[] calldata strategies, uint16a16 dhwIndexes)
        external
        view
        returns (int256[] memory yields);

    /**
     * @notice Returns state of strategies at do-hard-work indexes.
     * @param strategies Strategies.
     * @param dhwIndexes Do-hard-work indexes.
     * @return states State of each strategy at corresponding do-hard-work index.
     */
    function strategyAtIndexBatch(address[] calldata strategies, uint16a16 dhwIndexes, uint256 assetGroupLength)
        external
        view
        returns (StrategyAtIndex[] memory states);

    /**
     * @notice Gets required asset ratio for strategy at last DHW.
     * @param strategy Address of the strategy.
     * @return assetRatio Asset ratio.
     */
    function assetRatioAtLastDhw(address strategy) external view returns (uint256[] memory assetRatio);

    /**
     * @notice Gets set platform fees.
     * @return fees Set platform fees.
     */
    function platformFees() external view returns (PlatformFees memory fees);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Registers a strategy into the system.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param strategy Address of strategy to register.
     * @param apy Apy of the strategy at the time of the registration.
     */
    function registerStrategy(address strategy, int256 apy) external;

    /**
     * @notice Removes strategy from the system.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategy Strategy to remove.
     */
    function removeStrategy(address strategy) external;

    /**
     * @notice Sets ecosystem fee.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param ecosystemFeePct Ecosystem fee to set. Expressed in terms of FULL_PERCENT.
     */
    function setEcosystemFee(uint96 ecosystemFeePct) external;

    /**
     * @notice Sets receiver of the ecosystem fees.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param ecosystemFeeReceiver Receiver to set.
     */
    function setEcosystemFeeReceiver(address ecosystemFeeReceiver) external;

    /**
     * @notice Sets treasury fee.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param treasuryFeePct Treasury fee to set. Expressed in terms of FULL_PERCENT.
     */
    function setTreasuryFee(uint96 treasuryFeePct) external;

    /**
     * @notice Sets treasury fee receiver.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param treasuryFeeReceiver Receiver to set.
     */
    function setTreasuryFeeReceiver(address treasuryFeeReceiver) external;

    /**
     * @notice Does hard work on multiple strategies.
     * @dev Requirements:
     * - caller must have role ROLE_DO_HARD_WORKER
     * @param dhwParams Parameters for do hard work.
     */
    function doHardWork(DoHardWorkParameterBag calldata dhwParams) external;

    /**
     * @notice Adds deposits to strategies to be processed at next do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategies Strategies to which to add deposit.
     * @param amounts Amounts of assets to add to each strategy.
     * @return strategyIndexes Current do-hard-work indexes for the strategies.
     */
    function addDeposits(address[] calldata strategies, uint256[][] calldata amounts)
        external
        returns (uint16a16 strategyIndexes);

    /**
     * @notice Adds withdrawals to strategies to be processed at next do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategies Strategies to which to add withdrawal.
     * @param strategyShares Amounts of strategy shares to add to each strategy.
     * @return strategyIndexes Current do-hard-work indexes for the strategies.
     */
    function addWithdrawals(address[] calldata strategies, uint256[] calldata strategyShares)
        external
        returns (uint16a16 strategyIndexes);

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param redeemFastParams Parameters for fast redeem.
     * @return withdrawnAssets Amount of assets withdrawn.
     */
    function redeemFast(RedeemFastParameterBag calldata redeemFastParams)
        external
        returns (uint256[] memory withdrawnAssets);

    /**
     * @notice Claims withdrawals from the strategies.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * - DHWs must be run for withdrawal indexes.
     * @param strategies Addresses if strategies from which to claim withdrawal.
     * @param dhwIndexes Indexes of strategies when withdrawal was made.
     * @param strategyShares Amount of strategy shares that was withdrawn.
     * @return assetsWithdrawn Amount of assets withdrawn from strategies.
     */
    function claimWithdrawals(address[] calldata strategies, uint16a16 dhwIndexes, uint256[] calldata strategyShares)
        external
        returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Redeems strategy shares.
     * Used by recipients of platform fees.
     * @param strategies Strategies from which to redeem.
     * @param shares Amount of shares to redeem from each strategy.
     * @param withdrawalSlippages Slippages to guard redeemal process.
     */
    function redeemStrategyShares(
        address[] calldata strategies,
        uint256[] calldata shares,
        uint256[][] calldata withdrawalSlippages
    ) external;

    /**
     * @notice Strategy was registered
     * @param strategy Strategy address
     */
    event StrategyRegistered(address indexed strategy);

    /**
     * @notice Strategy was removed
     * @param strategy Strategy address
     */
    event StrategyRemoved(address indexed strategy);

    /**
     * @notice Strategy DHW was executed
     * @param strategy Strategy address
     * @param dhwIndex DHW index
     * @param dhwInfo DHW info
     */
    event StrategyDhw(address indexed strategy, uint256 dhwIndex, DhwInfo dhwInfo);

    /**
     * @notice Ecosystem fee configuration was changed
     * @param feePct Fee percentage value
     */
    event EcosystemFeeSet(uint256 feePct);

    /**
     * @notice Ecosystem fee receiver was changed
     * @param ecosystemFeeReceiver Receiver address
     */
    event EcosystemFeeReceiverSet(address indexed ecosystemFeeReceiver);

    /**
     * @notice Treasury fee configuration was changed
     * @param feePct Fee percentage value
     */
    event TreasuryFeeSet(uint256 feePct);

    /**
     * @notice Treasury fee receiver was changed
     * @param treasuryFeeReceiver Receiver address
     */
    event TreasuryFeeReceiverSet(address indexed treasuryFeeReceiver);

    /**
     * @notice Emergency withdrawal wallet changed
     * @param wallet Emergency withdrawal wallet address
     */
    event EmergencyWithdrawalWalletSet(address indexed wallet);

    /**
     * @notice Strategy shares have been redeemed
     * @param strategy Strategy address
     * @param owner Address that owns the shares
     * @param recipient Address that received the withdrawn funds
     * @param shares Amount of shares that were redeemed
     * @param assetsWithdrawn Amounts of withdrawn assets
     */
    event StrategySharesRedeemed(
        address indexed strategy,
        address indexed owner,
        address indexed recipient,
        uint256 shares,
        uint256[] assetsWithdrawn
    );

    /**
     * @notice Strategy shares were fast redeemed
     * @param strategy Strategy address
     * @param shares Amount of shares redeemed
     * @param assetsWithdrawn Amounts of withdrawn assets
     */
    event StrategySharesFastRedeemed(address indexed strategy, uint256 shares, uint256[] assetsWithdrawn);

    /**
     * @notice Strategy APY value was updated
     * @param strategy Strategy address
     * @param apy New APY value
     */
    event StrategyApyUpdated(address indexed strategy, int256 apy);
}

interface IEmergencyWithdrawal {
    /**
     * @notice Emitted when a strategy is emergency withdrawn from.
     * @param strategy Strategy that was emergency withdrawn from.
     */
    event StrategyEmergencyWithdrawn(address indexed strategy);

    /**
     * @notice Set a new address that will receive assets withdrawn if emergency withdrawal is executed.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param wallet Address to set as the emergency withdrawal wallet.
     */
    function setEmergencyWithdrawalWallet(address wallet) external;

    /**
     * @notice Instantly withdraws assets from a strategy, bypassing shares mechanism.
     * @dev Requirements:
     * - caller must have role ROLE_EMERGENCY_WITHDRAWAL_EXECUTOR
     * @param strategies Addresses of strategies.
     * @param withdrawalSlippages Slippages to guard withdrawal.
     * @param removeStrategies Whether to remove strategies from the system after withdrawal.
     */
    function emergencyWithdraw(
        address[] calldata strategies,
        uint256[][] calldata withdrawalSlippages,
        bool removeStrategies
    ) external;
}

// src/libraries/SpoolUtils.sol

/**
 * @title Spool utility functions.
 * @notice This library gathers various utility functions.
 */
library SpoolUtils {
    /**
     * @notice Gets asset ratios for strategies as recorded at their last DHW.
     * Asset ratios are ordered according to each strategies asset group.
     * @param strategies_ Addresses of strategies.
     * @param strategyRegistry_ Strategy registry.
     * @return strategyRatios Required asset ratio for strategies.
     */
    function getStrategyRatiosAtLastDhw(address[] calldata strategies_, IStrategyRegistry strategyRegistry_)
        public
        view
        returns (uint256[][] memory)
    {
        uint256[][] memory strategyRatios = new uint256[][](strategies_.length);

        for (uint256 i; i < strategies_.length; ++i) {
            strategyRatios[i] = strategyRegistry_.assetRatioAtLastDhw(strategies_[i]);
        }

        return strategyRatios;
    }

    /**
     * @notice Gets USD exchange rates for tokens.
     * The exchange rate is represented as a USD price for one token.
     * @param tokens_ Addresses of tokens.
     * @param priceFeedManager_ USD price feed mananger.
     * @return exchangeRates Exchange rates for tokens.
     */
    function getExchangeRates(address[] calldata tokens_, IUsdPriceFeedManager priceFeedManager_)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory exchangeRates = new uint256[](tokens_.length);
        for (uint256 i; i < tokens_.length; ++i) {
            exchangeRates[i] =
                priceFeedManager_.assetToUsd(tokens_[i], 10 ** priceFeedManager_.assetDecimals(tokens_[i]));
        }

        return exchangeRates;
    }

    /**
     * @dev Gets revert message when a low-level call reverts, so that it can
     * be bubbled-up to caller.
     * @param returnData_ Data returned from reverted low-level call.
     * @return revertMsg Original revert message if available, or default message otherwise.
     */
    function getRevertMsg(bytes memory returnData_) public pure returns (string memory) {
        // if the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData_.length < 68) {
            return "SpoolUtils::_getRevertMsg: Transaction reverted silently.";
        }

        assembly {
            // slice the sig hash
            returnData_ := add(returnData_, 0x04)
        }

        return abi.decode(returnData_, (string)); // all that remains is the revert string
    }
}

// src/libraries/ReallocationLib.sol

/* ========== ERRORS ========== */

/**
 * @notice Used when strategies provided for reallocation are invalid.
 */
error InvalidStrategies();

/* ========== STRUCTS ========== */

/**
 * @notice Parameters for reallocation.
 * @custom:member assetGroupRegistry Asset group registry contract.
 * @custom:member priceFeedManager Price feed manager contract.
 * @custom:member masterWallet Master wallet contract.
 * @custom:member assetGroupId ID of the asset group used by strategies being reallocated.
 * @custom:member swapInfo Information for swapping assets before depositing into the protocol.
 * @custom:member depositSlippages Slippages used to constrain depositing into the protocol.
 * @custom:member withdrawalSlippages Slippages used to contrain withdrawal from the protocol.
 * @custom:member exchangeRateSlippages Slippages used to constratrain exchange rates for asset tokens.
 */
struct ReallocationParameterBag {
    IAssetGroupRegistry assetGroupRegistry;
    IUsdPriceFeedManager priceFeedManager;
    IMasterWallet masterWallet;
    uint256 assetGroupId;
    SwapInfo[][] swapInfo;
    uint256[][] depositSlippages;
    uint256[][] withdrawalSlippages;
    uint256[2][] exchangeRateSlippages;
}

/**
 * @dev Parameters for calculateReallocation.
 * @custom:member smartVault Smart vault.
 * @custom:member strategyMapping Mapping between smart vault's strategies and provided strategies.
 * @custom:member totalSharesToRedeem How must shares each strategy needs to redeem. Will be updated.
 * @custom:member strategyValues Current USD value of each strategy.
 */
struct CalculateReallocationParams {
    address smartVault;
    uint256[] strategyMapping;
    uint256[] totalSharesToRedeem;
    uint256[] strategyValues;
}

// *Ghost strategies:*
// Ghost strategy should not be provided among the set of strategies, even if
// some smart vault is using it.
// Ghost strategies only need to be handled in one point of the library, i.e.,
// in the `mapStrategies`. There it index uint256 max, event though that is not
// used anywhere else in the code. Other parts of the code skip the ghost
// strategy either because its allocation does not change (it is always 0), or
// because it is not provided in the set of all strategies.

library ReallocationLib {
    using uint16a16Lib for uint16a16;
    using ArrayMappingUint256 for mapping(uint256 => uint256);
    using ArrayMappingAddress for mapping(uint256 => address);

    /**
     * @notice Reallocates smart vaults.
     * @param smartVaults Smart vaults to reallocate.
     * @param strategies Set of strategies involved in the reallocation. Should not include ghost strategy.
     * @param ghostStrategy Address of ghost strategy.
     * @param reallocationParams Bag with reallocation parameters.
     * @param _smartVaultStrategies Strategies per smart vault.
     * @param _smartVaultAllocations Allocations per smart vault.
     */
    function reallocate(
        address[] calldata smartVaults,
        address[] calldata strategies,
        address ghostStrategy,
        ReallocationParameterBag calldata reallocationParams,
        mapping(address => address[]) storage _smartVaultStrategies,
        mapping(address => uint16a16) storage _smartVaultAllocations
    ) external {
        // Validate provided strategies and create a per smart vault strategy mapping.
        uint256[][] memory strategyMapping =
            _mapStrategies(smartVaults, strategies, ghostStrategy, _smartVaultStrategies);

        // Get current value of strategies.
        (uint256[] memory strategyValues, address[] memory assetGroup, uint256[] memory exchangeRates) =
            _valuateStrategies(strategies, reallocationParams);

        // Calculate reallocations needed for smart vaults.
        // - will hold value to move between strategies of smart vaults
        uint256[][][] memory reallocations = new uint256[][][](smartVaults.length);
        // - will hold total shares to redeem by each strategy
        uint256[] memory totalSharesToRedeem = new uint256[](strategies.length);
        for (uint256 i; i < smartVaults.length; ++i) {
            address smartVault = smartVaults[i];
            reallocations[i] = _calculateReallocation(
                CalculateReallocationParams({
                    smartVault: smartVault,
                    strategyMapping: strategyMapping[i],
                    totalSharesToRedeem: totalSharesToRedeem,
                    strategyValues: strategyValues
                }),
                _smartVaultStrategies[smartVault],
                _smartVaultAllocations
            );
        }

        // Build the strategy-to-strategy reallocation table.
        uint256[][][] memory reallocationTable =
            _buildReallocationTable(strategyMapping, strategies.length, reallocations, totalSharesToRedeem);

        // Do the actual reallocation with withdrawals from and deposits into the underlying protocols.
        _doReallocation(strategies, reallocationParams, assetGroup, exchangeRates, reallocationTable);

        // Smart vaults claim strategy shares.
        _claimShares(smartVaults, strategies, strategyMapping, reallocationTable, reallocations);
    }

    /**
     * @dev Creates a mapping between strategies of smart vaults and provided strategies.
     * Also validates that provided strategies form a set of smart vaults' strategies.
     * @param smartVaults Smart vaults to reallocate.
     * @param strategies Set of strategies involved in the reallocation.
     * @param ghostStrategy Address of ghost strategy.
     * @param _smartVaultStrategies Strategies per smart vault.
     * @return Mapping between smart vault's strategies and provided strategies:
     * - first index runs over smart vaults
     * - second index runs over strategies of the smart vault.
     * - value represents a position of smart vault's strategy in the provided `strategies` array.
     *   A uint256 max represents a ghost strategy, although it is not needed anywhere.
     */
    function _mapStrategies(
        address[] calldata smartVaults,
        address[] calldata strategies,
        address ghostStrategy,
        mapping(address => address[]) storage _smartVaultStrategies
    ) private view returns (uint256[][] memory) {
        // We want to validate that the provided strategies represent a set of all the
        // strategies used by the smart vaults being reallocated. At the same time we
        // also build a mapping between strategies as listed on each smart vault and
        // the provided strategies.

        bool[] memory strategyMatched = new bool[](strategies.length);
        uint256[][] memory strategyMapping = new uint256[][](smartVaults.length);

        // Build a mapping for each smart vault and validate that all strategies are
        // present in the provided list.
        for (uint256 i; i < smartVaults.length; ++i) {
            // Get strategies for this smart vault.
            address[] storage smartVaultStrategies = _smartVaultStrategies[smartVaults[i]];
            uint256 smartVaultStrategiesLength = smartVaultStrategies.length;
            // Mapping from this smart vault's strategies to provided strategies.
            strategyMapping[i] = new uint256[](smartVaultStrategiesLength);

            // Loop over smart vault's strategies.
            for (uint256 j; j < smartVaultStrategiesLength; ++j) {
                address strategy = smartVaultStrategies[j];
                // handle ghost strategies
                if (strategy == ghostStrategy) {
                    strategyMapping[i][j] = type(uint256).max;
                    continue;
                }

                bool found = false;

                // Try to find the strategy in the provided list of strategies.
                for (uint256 k; k < strategies.length; ++k) {
                    if (strategies[k] == strategy) {
                        // Match found.
                        found = true;
                        strategyMatched[k] = true;
                        // Add entry to the strategy mapping.
                        strategyMapping[i][j] = k;

                        break;
                    }
                }

                if (!found) {
                    // If a smart vault's strategy was not found in the provided list
                    // of strategies, this means that the provided list is invalid.
                    revert InvalidStrategies();
                }
            }
        }

        // Validate that each strategy in the provided list was matched at least once.
        for (uint256 i; i < strategyMatched.length; ++i) {
            if (!strategyMatched[i]) {
                // If a strategy was not matched, this means that it is not used by any
                // smart vault and should not be included in the list.
                revert InvalidStrategies();
            }
        }

        return strategyMapping;
    }

    /**
     * @dev Get current value of strategies.
     * @param strategies Set of strategies involved in the reallocation.
     * @param reallocationParams Bag with reallocation parameters.
     * @return strategyValues USD value of each strategy.
     * @return assetGroup Address of tokens in asset group.
     * @return exchangeRates USD exchange rate for tokens in asset group.
     */
    function _valuateStrategies(address[] calldata strategies, ReallocationParameterBag calldata reallocationParams)
        private
        returns (uint256[] memory strategyValues, address[] memory assetGroup, uint256[] memory exchangeRates)
    {
        // Get asset group and corresponding exchange rates.
        assetGroup = reallocationParams.assetGroupRegistry.listAssetGroup(reallocationParams.assetGroupId);

        if (assetGroup.length != reallocationParams.exchangeRateSlippages.length) {
            revert InvalidArrayLength();
        }

        exchangeRates = SpoolUtils.getExchangeRates(assetGroup, reallocationParams.priceFeedManager);
        unchecked {
            for (uint256 i; i < assetGroup.length; ++i) {
                if (
                    exchangeRates[i] < reallocationParams.exchangeRateSlippages[i][0]
                        || exchangeRates[i] > reallocationParams.exchangeRateSlippages[i][1]
                ) {
                    revert ExchangeRateOutOfSlippages();
                }
            }
        }

        // Get value of each strategy.
        strategyValues = new uint256[](strategies.length);
        unchecked {
            for (uint256 i; i < strategyValues.length; ++i) {
                strategyValues[i] =
                    IStrategy(strategies[i]).getUsdWorth(exchangeRates, reallocationParams.priceFeedManager);
            }
        }

        return (strategyValues, assetGroup, exchangeRates);
    }

    /**
     * @dev Calculates reallocation needed per smart vault.
     * Also updates the `totalSharesToRedeem`.
     * @param params Parameters for calculate reallocation.
     * @param smartVaultStrategies Strategies of the smart vault.
     * @param _smartVaultAllocations Allocations per smart vault.
     * @return Reallocation of the smart vault:
     * - first index is 0 or 1
     * - 0:
     *   - second index runs over smart vault's strategies
     *   - value is USD value that needs to be withdrawn from the strategy
     * - 1:
     *   - second index runs over smart vault's strategies + extra field
     *   - value is USD value that needs to be deposited into the strategy
     *   - extra field gathers total value that needs to be deposited by the smart vault
     */
    function _calculateReallocation(
        CalculateReallocationParams memory params,
        address[] storage smartVaultStrategies,
        mapping(address => uint16a16) storage _smartVaultAllocations
    ) private returns (uint256[][] memory) {
        // Store length of strategies array to not read storage every time.
        uint256 smartVaultStrategiesLength = smartVaultStrategies.length;

        // Initialize array for this smart vault.
        uint256[][] memory reallocation = new uint256[][](2);
        reallocation[0] = new uint256[](smartVaultStrategiesLength); // values to redeem
        reallocation[1] = new uint256[](smartVaultStrategiesLength + 1); // values to deposit | total value to deposit

        // Get smart vaults total USD value.
        uint256 totalUsdValue;
        {
            uint256 totalSupply;
            for (uint256 i; i < smartVaultStrategiesLength; ++i) {
                totalSupply = IStrategy(smartVaultStrategies[i]).totalSupply();
                if (totalSupply > 0) {
                    totalUsdValue += params.strategyValues[params.strategyMapping[i]]
                        * IStrategy(smartVaultStrategies[i]).balanceOf(params.smartVault) / totalSupply;
                }
            }
        }

        // Get sum total of target allocation.
        uint256 totalTargetAllocation;
        for (uint256 i; i < smartVaultStrategiesLength; ++i) {
            totalTargetAllocation += _smartVaultAllocations[params.smartVault].get(i);
        }

        // Compare target and current allocation.
        for (uint256 i; i < smartVaultStrategiesLength; ++i) {
            uint256 targetValue = _smartVaultAllocations[params.smartVault].get(i);
            targetValue = targetValue * totalUsdValue / totalTargetAllocation;
            // Get current allocation.
            uint256 currentValue;
            {
                uint256 totalSupply = IStrategy(smartVaultStrategies[i]).totalSupply();
                if (totalSupply > 0) {
                    currentValue = params.strategyValues[params.strategyMapping[i]]
                        * IStrategy(smartVaultStrategies[i]).balanceOf(params.smartVault) / totalSupply;
                }
            }

            if (targetValue > currentValue) {
                // This strategy needs deposit.
                reallocation[1][i] = targetValue - currentValue;
                reallocation[1][smartVaultStrategiesLength] += targetValue - currentValue;
            } else if (targetValue < currentValue) {
                // This strategy needs withdrawal.

                // Relese strategy shares.
                uint256 sharesToRedeem = IStrategy(smartVaultStrategies[i]).balanceOf(params.smartVault);
                sharesToRedeem = sharesToRedeem * (currentValue - targetValue) / currentValue;
                IStrategy(smartVaultStrategies[i]).releaseShares(params.smartVault, sharesToRedeem);

                // Recalculate value to withdraw based on released shares.
                reallocation[0][i] = params.strategyValues[params.strategyMapping[i]] * sharesToRedeem
                    / IStrategy(smartVaultStrategies[i]).totalSupply();

                // Update total shares to redeem for strategy.
                params.totalSharesToRedeem[params.strategyMapping[i]] += sharesToRedeem;
            }
        }

        return reallocation;
    }

    /**
     * @dev Builds reallocation table from smart vaults' reallocations.
     * @param strategyMapping Mapping between smart vault's strategies and provided strategies.
     * @param numStrategies Number of all strategies involved in the reallocation.
     * @param reallocations Reallocations needed by each smart vaults.
     * @param totalSharesToRedeem How must shares each strategy needs to redeem.
     * @return Reallocation table:
     * - first index runs over all strategies i
     * - second index runs over all strategies j
     * - third index is 0, 1 or 2
     *   - 0:
     *      - value of off-diagonal elements represent USD value that should be withdrawn by strategy i and deposited into strategy j
     *      - value of diagonal elements represents total shares to redeem by strategy i
     *   - 1: value is not used yet
     *     - will be used to represent amount of matched shares from strategy j that are distributed to strategy i
     *   - 2: value is not used yet
     *     - will be used to represent amount of unmatched shares from strategy j that are distributed to strategy i
     */
    function _buildReallocationTable(
        uint256[][] memory strategyMapping,
        uint256 numStrategies,
        uint256[][][] memory reallocations,
        uint256[] memory totalSharesToRedeem
    ) private pure returns (uint256[][][] memory) {
        // We want to build a reallocation table which specifies how to redistribute
        // funds from one strategy to another.

        // Reallocation table is numStrategies x numStrategies big.
        // A value of cell (i, j) V_ij specifies the value V that needs to be withdrawn
        // from strategy i and deposited into strategy j.
        uint256[][][] memory reallocationTable = new uint256[][][](numStrategies);
        for (uint256 i; i < numStrategies; ++i) {
            reallocationTable[i] = new uint256[][](numStrategies);

            for (uint256 j; j < numStrategies; ++j) {
                reallocationTable[i][j] = new uint256[](3);
            }
        }

        // Loop over smart vaults.
        for (uint256 i; i < reallocations.length; ++i) {
            // Calculate witdrawals and deposits needed to allign with new allocation.
            uint256 strategiesLength = reallocations[i][0].length;

            // Find strategies that need withdrawal.
            for (uint256 j; j < strategiesLength; ++j) {
                if (reallocations[i][0][j] == 0) {
                    continue;
                }

                uint256[] memory values = new uint256[](2);
                values[0] = reallocations[i][0][j];
                values[1] = reallocations[i][1][strategiesLength];

                // Find strategies that need deposit.
                for (uint256 k; k < strategiesLength; ++k) {
                    if (reallocations[i][1][k] == 0) {
                        continue;
                    }

                    // Find value from j that should move to strategy k.
                    uint256 valueToDeposit = values[0] * reallocations[i][1][k] / values[1];
                    reallocationTable[strategyMapping[i][j]][strategyMapping[i][k]][0] += valueToDeposit;

                    values[0] -= valueToDeposit; // dust-less calculation.
                    values[1] -= reallocations[i][1][k];
                }
            }
        }

        // Loop over strategies.
        for (uint256 i; i < numStrategies; ++i) {
            // Set diagonal item to total shares the strategy should redeem.
            reallocationTable[i][i][0] = totalSharesToRedeem[i];
        }

        return reallocationTable;
    }

    /**
     * @dev Does the actual reallocation by withdrawing from and depositing into strategies.
     * Also populates the reallocation table.
     * @param strategies Set of strategies involved in the reallocation.
     * @param reallocationParams Bag with reallocation parameters.
     * @param assetGroup Addresses of tokens in asset group.
     * @param exchangeRates Exchange rate of tokens.
     * @param reallocationTable Reallocation table.
     */
    function _doReallocation(
        address[] calldata strategies,
        ReallocationParameterBag calldata reallocationParams,
        address[] memory assetGroup,
        uint256[] memory exchangeRates,
        uint256[][][] memory reallocationTable
    ) private {
        // Will store how much assets each strategy has to deposit.
        uint256[][] memory toDeposit = new uint256[][](strategies.length);
        for (uint256 i; i < strategies.length; ++i) {
            toDeposit[i] = new uint256[](assetGroup.length + 1);
            // toDeposit[0..strategies.length-1]: amount of assets to deposit into strategy i
            // toDeposit[strategies.length]: is there something to deposit
        }

        // Distribute matched shares and withdraw unamatched ones.
        for (uint256 i; i < strategies.length; ++i) {
            // Calculate amount of shares to distribute and amount of shares to redeem.
            uint256 sharesToRedeem;
            uint256 totalUnmatchedWithdrawals;

            {
                if (reallocationTable[i][i][0] == 0) {
                    IStrategy(strategies[i]).beforeRedeemalCheck(0, reallocationParams.withdrawalSlippages[i]);

                    // There is nothing to withdraw from strategy i.
                    continue;
                }

                uint256[2] memory totals;
                // totals[0] -> total withdrawals
                // totals[1] -> total matched withdrawals

                for (uint256 j; j < strategies.length; ++j) {
                    if (j == i) {
                        // Strategy does not reallocate to itself.
                        continue;
                    }

                    totals[0] += reallocationTable[i][j][0];

                    // Take smaller for matched withdrawals.
                    if (reallocationTable[i][j][0] > reallocationTable[j][i][0]) {
                        totals[1] += reallocationTable[j][i][0];
                    } else {
                        totals[1] += reallocationTable[i][j][0];
                    }
                }

                // Unmatched withdrawals are difference between total and matched withdrawals.
                totalUnmatchedWithdrawals = totals[0] - totals[1];

                // Calculate amount of shares to redeem and to distribute.
                uint256 sharesToDistribute = // first store here total amount of shares that should have been withdrawn
                 reallocationTable[i][i][0];

                IStrategy(strategies[i]).beforeRedeemalCheck(
                    sharesToDistribute, reallocationParams.withdrawalSlippages[i]
                );

                sharesToRedeem = sharesToDistribute * totalUnmatchedWithdrawals / totals[0];
                sharesToDistribute -= sharesToRedeem;

                // Distribute matched shares to matched strategies.
                if (sharesToDistribute > 0) {
                    for (uint256 j; j < strategies.length; ++j) {
                        if (j == i) {
                            // Strategy does not reallocate to itself.
                            continue;
                        }

                        uint256 matched;

                        // Take smaller for matched withdrawals.
                        if (reallocationTable[i][j][0] > reallocationTable[j][i][0]) {
                            matched = reallocationTable[j][i][0];
                        } else {
                            matched = reallocationTable[i][j][0];
                        }

                        if (matched == 0) {
                            continue;
                        }

                        // Give shares to strategy j.
                        reallocationTable[j][i][1] = sharesToDistribute * matched / totals[1];

                        sharesToDistribute -= reallocationTable[j][i][1]; // dust-less calculation
                        totals[1] -= matched;
                    }
                }
            }

            if (sharesToRedeem == 0) {
                // There is nothing to withdraw for strategy i.
                continue;
            }

            // Withdraw assets from underlying protocol.
            uint256[] memory withdrawnAssets = IStrategy(strategies[i]).redeemFast(
                sharesToRedeem,
                address(reallocationParams.masterWallet),
                assetGroup,
                reallocationParams.withdrawalSlippages[i]
            );

            // Distribute withdrawn assets to strategies according to reallocation table.
            for (uint256 j; j < strategies.length; ++j) {
                if (reallocationTable[i][j][0] <= reallocationTable[j][i][0]) {
                    // Diagonal values will be equal, no need to check for i == j.
                    // Nothing to deposit into strategy j.
                    continue;
                }

                for (uint256 k; k < assetGroup.length; ++k) {
                    // Find out how much of asset k should go to strategy j.
                    uint256 depositAmount = withdrawnAssets[k]
                        * (reallocationTable[i][j][0] - reallocationTable[j][i][0]) / totalUnmatchedWithdrawals;
                    toDeposit[j][k] += depositAmount;
                    // Mark that there is something to deposit for strategy j.
                    toDeposit[j][assetGroup.length] += 1;

                    // Use this table to temporarily store value deposited from strategy i to strategy j.
                    reallocationTable[i][j][2] += reallocationParams.priceFeedManager.assetToUsdCustomPrice(
                        assetGroup[k], depositAmount, exchangeRates[k]
                    );

                    withdrawnAssets[k] -= depositAmount; // dust-less calculation
                }
                totalUnmatchedWithdrawals -= (reallocationTable[i][j][0] - reallocationTable[j][i][0]); // dust-less calculation
            }
        }

        // Deposit assets into the underlying protocols.
        for (uint256 i; i < strategies.length; ++i) {
            IStrategy(strategies[i]).beforeDepositCheck(toDeposit[i], reallocationParams.depositSlippages[i]);

            if (toDeposit[i][assetGroup.length] == 0) {
                // There is nothing to deposit for this strategy.
                continue;
            }

            // Transfer assets from master wallet to the strategy for the deposit.
            for (uint256 j; j < assetGroup.length; ++j) {
                reallocationParams.masterWallet.transfer(IERC20(assetGroup[j]), strategies[i], toDeposit[i][j]);
            }

            // Do the deposit.
            uint256 mintedSsts = IStrategy(strategies[i]).depositFast(
                assetGroup,
                exchangeRates,
                reallocationParams.priceFeedManager,
                reallocationParams.depositSlippages[i],
                reallocationParams.swapInfo[i]
            );

            // Figure total value of assets gathered to be deposited.
            uint256 totalDepositedValue =
                reallocationParams.priceFeedManager.assetToUsdCustomPriceBulk(assetGroup, toDeposit[i], exchangeRates);

            // Distribute the minted shares to strategies that deposited into this strategy.
            for (uint256 j; j < strategies.length; ++j) {
                if (reallocationTable[j][i][2] == 0) {
                    // Diagonal element will be 0, no need to check i == j.
                    // No shares to give to strategy j.
                    continue;
                }

                // Calculate amount of shares to give to strategy j.
                uint256 shares = mintedSsts * reallocationTable[j][i][2] / totalDepositedValue;

                mintedSsts -= shares; // dust-less calculation
                totalDepositedValue -= reallocationTable[j][i][2]; // dust-less calculation

                // Overwrite this table with amount of given shares.
                reallocationTable[j][i][2] = shares;
            }
        }
    }

    /**
     * @dev Smart vaults claim strategy shares.
     * @param smartVaults Smart vaults involved in the reallocation.
     * @param strategies Set of strategies involved in the reallocation.
     * @param strategyMapping Mapping between smart vaults' strategies and set of all strategies.
     * @param reallocationTable Filled in reallocation table.
     * @param reallocations Realllocations needed by the smart vaults.
     */
    function _claimShares(
        address[] calldata smartVaults,
        address[] calldata strategies,
        uint256[][] memory strategyMapping,
        uint256[][][] memory reallocationTable,
        uint256[][][] memory reallocations
    ) private {
        // Loop over smart vaults.
        for (uint256 i; i < smartVaults.length; ++i) {
            // Number of strategies for this smart vault.
            uint256 smartVaultStrategiesLength = strategyMapping[i].length;

            // Will store amount of shares to claim from each strategy,
            // plus two temporary variables used in the calculation.
            uint256[] memory toClaim = new uint256[](smartVaultStrategiesLength+2);

            // Find strategies that needed withdrawal.
            for (uint256 j; j < smartVaultStrategiesLength; ++j) {
                if (reallocations[i][0][j] == 0) {
                    // Strategy didn't need any withdrawal.
                    continue;
                }

                // Merging two uints into an array due to stack depth.
                uint256[] memory values = new uint256[](2);
                values[0] = reallocations[i][0][j]; // value to withdraw from strategy
                values[1] = reallocations[i][1][smartVaultStrategiesLength]; // total value to deposit

                // Find strategiest that needed deposit.
                for (uint256 k; k < smartVaultStrategiesLength; ++k) {
                    if (reallocations[i][1][k] == 0) {
                        // Strategy k had no deposits planned.
                        continue;
                    }

                    // Find value that should have moved from strategy j to k.
                    uint256 valueToDeposit = values[0] * reallocations[i][1][k] / values[1];

                    // Figure out amount strategy shares to claim:
                    // - matched shares
                    toClaim[smartVaultStrategiesLength] = reallocationTable[strategyMapping[i][j]][strategyMapping[i][k]][1]
                        * valueToDeposit / reallocationTable[strategyMapping[i][j]][strategyMapping[i][k]][0];
                    // - unmatched
                    toClaim[smartVaultStrategiesLength + 1] = reallocationTable[strategyMapping[i][j]][strategyMapping[i][k]][2]
                        * valueToDeposit / reallocationTable[strategyMapping[i][j]][strategyMapping[i][k]][0];

                    reallocationTable[strategyMapping[i][j]][strategyMapping[i][k]][0] -= valueToDeposit; // dust-less calculation - reallocation level
                    reallocationTable[strategyMapping[i][j]][strategyMapping[i][k]][1] -=
                        toClaim[smartVaultStrategiesLength];
                    reallocationTable[strategyMapping[i][j]][strategyMapping[i][k]][2] -=
                        toClaim[smartVaultStrategiesLength + 1];

                    values[0] -= valueToDeposit; // dust-less calculation - smart vault level
                    values[1] -= reallocations[i][1][k];

                    // Total amount of strategy k shares to claim by this smart vault.
                    toClaim[k] += toClaim[smartVaultStrategiesLength] + toClaim[smartVaultStrategiesLength + 1];
                }
            }

            // Claim strategy shares.
            for (uint256 j; j < smartVaultStrategiesLength; ++j) {
                if (toClaim[j] == 0) {
                    // No shares to claim for strategy j.
                    continue;
                }

                IStrategy(strategies[strategyMapping[i][j]]).claimShares(smartVaults[i], toClaim[j]);
            }
        }
    }
}